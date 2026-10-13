// Package tailnet —— QuartzWrt App「内嵌 tailscale」spike 的 gomobile 封装
// （产物为 AAR，供 Flutter 侧经 MethodChannel/JNI 调用）。
//
// 设计（详见 ../RESULTS.md）：
//   - tsnet 以 **userspace 网络栈** 在 App 进程内起一个 tailnet 节点——不建
//     TUN、不要 VpnService、不接管整机流量，只服务本 App 自己的连接；
//   - 同时在 127.0.0.1 起一个 HTTP CONNECT 代理：Dart 侧仅需把目标 HttpClient
//     指向该代理（Dio: `httpClientAdapter` 的 `findProxy`），即可经 tailnet 访问
//     路由器 100.x / MagicDNS 地址；证书 pin 仍由 Dart 侧端到端校验；
//   - 登录走交互式 URL（AuthURL，浏览器完成），不依赖 Tailscale 移动端 App。
package tailnet

import (
	"context"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"sync"
	"time"

	"tailscale.com/tsnet"
)

var (
	mu       sync.Mutex
	srv      *tsnet.Server
	proxySrv *http.Server
	proxyLis net.Listener
	loginURL string
	lastErr  string
)

// Start 启动 tailnet 节点与本地 CONNECT 代理，返回代理地址（127.0.0.1:port）。
// 登录状态经 LoginURL()/State() 轮询（gomobile 绑定限「至多一值+error」，故
// 不合并返回登录 URL）。
func Start(stateDir, hostname string) (proxyAddr string, err error) {
	mu.Lock()
	defer mu.Unlock()
	if proxySrv != nil {
		return "", errors.New("already started")
	}

	srv = &tsnet.Server{Hostname: hostname, Dir: stateDir}
	go func() { _, _ = srv.Up(context.Background()) }()

	lc, err := srv.LocalClient()
	if err != nil {
		return "", err
	}
	deadline := time.Now().Add(3 * time.Second)
	for time.Now().Before(deadline) {
		if st, err := lc.StatusWithoutPeers(context.Background()); err == nil && st != nil {
			if st.AuthURL != "" {
				loginURL = st.AuthURL
				break
			}
			if st.BackendState == "Running" {
				break
			}
		}
		time.Sleep(200 * time.Millisecond)
	}

	lis, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		return "", err
	}
	proxyLis = lis
	proxySrv = &http.Server{Handler: http.HandlerFunc(handleConnect)}
	go func() { _ = proxySrv.Serve(lis) }()
	return lis.Addr().String(), nil
}

// LoginURL 最近一次观察到的登录 URL（为空=尚未生成或已登录）。
func LoginURL() string {
	mu.Lock()
	defer mu.Unlock()
	return loginURL
}

// State 节点后端状态（NeedsLogin / Running / …）。
func State() string {
	mu.Lock()
	s := srv
	mu.Unlock()
	if s == nil {
		return "stopped"
	}
	lc, err := s.LocalClient()
	if err != nil {
		return "error: " + err.Error()
	}
	st, err := lc.StatusWithoutPeers(context.Background())
	if err != nil {
		return "error: " + err.Error()
	}
	return st.BackendState
}

// LastError 最近一次连接失败信息（排障用）。
func LastError() string {
	mu.Lock()
	defer mu.Unlock()
	return lastErr
}

// Stop 停止代理与节点。
func Stop() error {
	mu.Lock()
	defer mu.Unlock()
	if proxySrv != nil {
		_ = proxySrv.Close()
		proxySrv = nil
	}
	if srv != nil {
		err := srv.Close()
		srv = nil
		return err
	}
	return nil
}

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
