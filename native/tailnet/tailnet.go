// Package tailnet —— QuartzWrt App「内嵌直连」引擎（tsnet userspace 节点 + 本地代理）。
//
// 设计（见 dev/spike/tailscale/RESULTS.md 与 docs/DESIGN.md §7）：
//   - tsnet 以 **userspace 网络栈** 在 App 进程内起一个 tailnet 节点——不建 TUN、
//     无需 VpnService、不接管整机流量，只服务本 App 自己的连接；
//   - 同时在 127.0.0.1 起一个 HTTP CONNECT 代理：Dart 侧把目标 HttpClient 的
//     findProxy 指向它，即可经 tailnet 访问路由器（100.x / MagicDNS）；TLS 与
//     证书 pin 仍由 Dart 侧端到端完成（代理只转发字节流）；
//   - 登录：默认交互式 URL（浏览器完成）；测试/无人值守可用 config.json 的
//     auth_key（见 Config）。
//
// 线程模型：全部导出函数可跨线程调用（内部互斥锁 + 单实例）。
package tailnet

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/netip"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"tailscale.com/tsnet"
)

// Version —— 引擎版本串（Dart 侧「关于/诊断」展示用）。
const Version = "qt-tailnet 1.0 (tsnet)"

// Config —— 可选测试钩子（$stateDir/config.json，App UI 不写；供本地 headscale
// 联调与真机排障）。生产路径下该文件不存在，走官方控制面。
type Config struct {
	ControlURL string `json:"control_url,omitempty"` // 如 http://172.23.77.234:8080
	AuthKey    string `json:"auth_key,omitempty"`    // preauth key / auth key
	Hostname   string `json:"hostname,omitempty"`    // 覆盖默认主机名
}

var (
	mu       sync.Mutex
	srv      *tsnet.Server
	proxySrv *http.Server
	proxyLis net.Listener
	stateDir string
	loginURL string
	lastErr  string
	logRing  = make([]string, 0, 32)
)

func logf(format string, args ...any) {
	line := fmt.Sprintf(format, args...)
	mu.Lock()
	logRing = append(logRing, line)
	if len(logRing) > 32 {
		logRing = logRing[len(logRing)-32:]
	}
	mu.Unlock()
}

// Start 启动 tailnet 节点与本地 CONNECT 代理。重复调用幂等（已启动返回 nil）。
// 返回代理地址（127.0.0.1:port）；登录态经 LoginURL()/State() 查询。
func Start(dir, hostname string) error {
	mu.Lock()
	if srv != nil {
		mu.Unlock()
		return nil
	}
	mu.Unlock()

	registerInterfaceGetter() // Android：netlink 被禁时由注入的接口表供 netmon 使用
	prepareEnv(dir)           // Android 无 /tmp：给 logpolicy 备可写状态/缓存目录（否则 panic）
	cfg := loadConfig(dir)
	if cfg.Hostname != "" {
		hostname = cfg.Hostname
	}
	if hostname == "" {
		hostname = "quartz-app"
	}

	s := &tsnet.Server{
		Hostname:   hostname,
		Dir:        dir,
		ControlURL: cfg.ControlURL,
		AuthKey:    cfg.AuthKey,
		Logf:       logf,
	}

	ctx := context.Background()
	go func() {
		if _, err := s.Up(ctx); err != nil {
			mu.Lock()
			lastErr = err.Error()
			mu.Unlock()
			logf("tsnet up: %v", err)
		}
	}()

	// 短窗观察登录态（3s）：未登录时把 AuthURL 尽早带给 UI；有 auth key 时通常直接进 Running。
	lc, err := s.LocalClient()
	if err != nil {
		_ = s.Close()
		return err
	}
	deadline := time.Now().Add(3 * time.Second)
	for time.Now().Before(deadline) {
		if st, err := lc.StatusWithoutPeers(ctx); err == nil && st != nil {
			if st.AuthURL != "" || st.BackendState == "Running" {
				mu.Lock()
				loginURL = st.AuthURL
				mu.Unlock()
				break
			}
		}
		time.Sleep(200 * time.Millisecond)
	}

	lis, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		_ = s.Close()
		return err
	}
	ps := &http.Server{Handler: http.HandlerFunc(handleConnect)}

	mu.Lock()
	srv = s
	stateDir = dir
	proxyLis = lis
	proxySrv = ps
	lastErr = ""
	mu.Unlock()

	go func() { _ = ps.Serve(lis) }()
	logf("proxy listening on %s", lis.Addr().String())
	return nil
}

// ProxyAddr 本地 CONNECT 代理地址（未启动 = ""）。
func ProxyAddr() string {
	mu.Lock()
	defer mu.Unlock()
	if proxyLis == nil {
		return ""
	}
	return proxyLis.Addr().String()
}

// LoginURL 最近一次观察到的交互式登录 URL（已登录/未生成 = ""）。
func LoginURL() string {
	// 顺手刷新：登录 URL 可能在 Start 的 3s 观察窗之后才出现。
	if st := status(); st != nil && st.AuthURL != "" {
		mu.Lock()
		loginURL = st.AuthURL
		mu.Unlock()
	}
	mu.Lock()
	defer mu.Unlock()
	return loginURL
}

// State 后端状态：Stopped / NeedsLogin / Starting / Running / Error: ...
func State() string {
	if s := status(); s != nil {
		return s.BackendState
	}
	mu.Lock()
	defer mu.Unlock()
	if lastErr != "" {
		return "Error: " + lastErr
	}
	return "Stopped"
}

// SelfIP 本节点 tailnet IPv4（Running 后有值；否则 ""）。
func SelfIP() string {
	if s := status(); s != nil {
		for _, ip := range s.TailscaleIPs {
			if ip.Is4() {
				return ip.String()
			}
		}
	}
	return ""
}

// LastError 最近一次内部错误串（排障；无 = ""）。
func LastError() string {
	mu.Lock()
	defer mu.Unlock()
	return lastErr
}

// Logs 最近日志（末 32 行，换行连接；排障用）。
func Logs() string {
	mu.Lock()
	defer mu.Unlock()
	return strings.Join(logRing, "\n")
}

// Stop 停止代理与节点（保留磁盘状态；再次 Start 快速恢复）。
func Stop() error {
	mu.Lock()
	ps, s := proxySrv, srv
	proxySrv, proxyLis, srv = nil, nil, nil
	loginURL, lastErr = "", ""
	mu.Unlock()
	if ps != nil {
		_ = ps.Close()
	}
	if s != nil {
		return s.Close()
	}
	return nil
}

// ---- 内部 ----

func status() *ipnStatus {
	mu.Lock()
	s := srv
	mu.Unlock()
	if s == nil {
		return nil
	}
	lc, err := s.LocalClient()
	if err != nil {
		return nil
	}
	st, err := lc.StatusWithoutPeers(context.Background())
	if err != nil || st == nil {
		return nil
	}
	return &ipnStatus{BackendState: st.BackendState, AuthURL: st.AuthURL, TailscaleIPs: st.TailscaleIPs}
}

// ipnStatus —— StatusWithoutPeers 的最小投影（避免把 ipnstate 泄漏进 API 面）。
type ipnStatus struct {
	BackendState string
	AuthURL      string
	TailscaleIPs []netip.Addr
}

func loadConfig(dir string) Config {
	var cfg Config
	b, err := os.ReadFile(filepath.Join(dir, "config.json"))
	if err != nil {
		return cfg
	}
	if err := json.Unmarshal(b, &cfg); err != nil {
		logf("config.json invalid: %v", err)
		return Config{}
	}
	return cfg
}

// handleConnect —— 最小 HTTP CONNECT 代理（仅 CONNECT；出站一律走 tsnet）。
func handleConnect(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodConnect {
		http.Error(w, "CONNECT only", http.StatusMethodNotAllowed)
		return
	}
	mu.Lock()
	s := srv
	mu.Unlock()
	if s == nil {
		http.Error(w, "tailnet not started", http.StatusServiceUnavailable)
		return
	}
	ctx, cancel := context.WithTimeout(r.Context(), 10*time.Second)
	defer cancel()
	dst, err := s.Dial(ctx, "tcp", r.Host)
	if err != nil {
		mu.Lock()
		lastErr = fmt.Sprintf("dial %s: %v", r.Host, err)
		mu.Unlock()
		logf("proxy dial %s failed: %v", r.Host, err)
		http.Error(w, "dial failed: "+err.Error(), http.StatusBadGateway)
		return
	}
	defer dst.Close()

	hj, ok := w.(http.Hijacker)
	if !ok {
		http.Error(w, "hijack unsupported", http.StatusInternalServerError)
		return
	}
	conn, _, err := hj.Hijack()
	if err != nil {
		return
	}
	defer conn.Close()
	_, _ = conn.Write([]byte("HTTP/1.1 200 Connection Established\r\n\r\n"))
	done := make(chan struct{}, 2)
	go func() { _, _ = io.Copy(dst, conn); done <- struct{}{} }()
	go func() { _, _ = io.Copy(conn, dst); done <- struct{}{} }()
	<-done
}

// prepareEnv 准备引擎依赖的可写目录（Android 应用无 /tmp、HOME 亦不可靠）：
// logpolicy 的日志状态选址依次尝试 systemd/state 目录 → UserCacheDir → cwd → 临时目录，
// 前两者在 Android 不可用、cwd 为 "/"、临时目录因 /tmp 不存在创建失败 → 直接 panic。
// 这里把 TMPDIR/XDG_CACHE_HOME 指到状态目录下（已存在时不动，桌面端无副作用）。
func prepareEnv(dir string) {
	if os.Getenv("TMPDIR") == "" {
		tmp := filepath.Join(dir, "tmp")
		if os.MkdirAll(tmp, 0o700) == nil {
			_ = os.Setenv("TMPDIR", tmp)
		}
	}
	if os.Getenv("XDG_CACHE_HOME") == "" {
		cache := filepath.Join(dir, "cache")
		if os.MkdirAll(cache, 0o700) == nil {
			_ = os.Setenv("XDG_CACHE_HOME", cache)
		}
	}
}
