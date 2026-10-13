// E2E 客户端（宿主）：用**生产引擎**（native/tailnet）走完整链路——
// tsnet 登录本地 headscale → 本地 CONNECT 代理 → 经 tailnet 拨 mock 路由器 :443
// → TLS + 真 API 请求；并验证 Stop/Start 后的登录持久化（无需重新登录）。
//
// 用法: go run ./e2e/client -dir /tmp/qt-e2e-client -target 100.64.0.1
package main

import (
	"bytes"
	"crypto/tls"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"time"

	qt "github.com/quartzwrt/QuartzWrt-App/native/tailnet"
)

var (
	flagDir    = flag.String("dir", "/tmp/qt-e2e-client", "引擎状态目录（需预先放 config.json：control_url/auth_key）")
	flagTarget = flag.String("target", "", "mock 路由器的 tailnet IP（v4）")
	flagPort   = flag.Int("port", 443, "mock 路由器 tailnet 端口")
)

var failed bool

func check(name string, ok bool, detail string) {
	status := "PASS"
	if !ok {
		status = "FAIL"
		failed = true
	}
	fmt.Printf("%s  %s%s\n", status, name, detail)
}

func main() {
	flag.Parse()
	if *flagTarget == "" {
		fmt.Println("需要 -target <mock tailnet IP>")
		os.Exit(2)
	}
	if err := os.MkdirAll(*flagDir, 0o700); err != nil {
		panic(err)
	}

	// ① 启动引擎（config.json 指向 headscale + preauth key → 应直接 Running）
	if err := qt.Start(*flagDir, "quartz-e2e-client"); err != nil {
		check("engine start", false, err.Error())
		os.Exit(1)
	}
	defer qt.Stop()
	check("engine start", true, "")

	ip := waitRunning(60 * time.Second)
	check("node joined tailnet (Running)", ip != "", "ip="+ip+" state="+qt.State())
	if ip == "" {
		fmt.Println(qt.Logs())
		os.Exit(1)
	}

	// ② 经本地 CONNECT 代理访问 mock 路由器（TLS 端到端）
	proxy := qt.ProxyAddr()
	check("proxy listening", proxy != "", proxy)
	res := callThroughProxy(proxy, *flagTarget, *flagPort, "info", nil)
	check("info via proxy over tailnet", res["name"] == "quartz-mock", fmt.Sprint(res))

	tok := callThroughProxy(proxy, *flagTarget, *flagPort, "login", map[string]any{"username": "root", "password": "quartz", "device_name": "e2e"})
	check("login ok", tok["ok"] == true, fmt.Sprint(tok))
	at, _ := tok["access_token"].(string)
	st := callThroughProxy(proxy, *flagTarget, *flagPort, "status", map[string]any{"access_token": at})
	snap, _ := st["snapshot"].(map[string]any)
	check("status snapshot via proxy", snap != nil && snap["v"] == float64(1), fmt.Sprint(st)[:min(120, len(fmt.Sprint(st)))])

	// ③ 重启持久化：Stop → Start → 无需登录直接 Running
	_ = qt.Stop()
	if err := qt.Start(*flagDir, "quartz-e2e-client"); err != nil {
		check("restart", false, err.Error())
	} else {
		ip2 := waitRunning(25 * time.Second)
		check("relogin-free restart (state persisted)", ip2 != "" && qt.LoginURL() == "", "ip="+ip2+" state="+qt.State())
		// 重启后对端数据路径需要一拍重建（wireguard/DERP）——等价 App 下一轮轮询的重试。
		var res2 map[string]any
		for i := 0; i < 8; i++ {
			res2 = callThroughProxy(qt.ProxyAddr(), *flagTarget, *flagPort, "info", nil)
			if res2["name"] == "quartz-mock" {
				break
			}
			time.Sleep(2 * time.Second)
		}
		check("info after restart (with retry)", res2["name"] == "quartz-mock", "")
	}

	if failed {
		os.Exit(1)
	}
	fmt.Println("ALL PASS")
}

func waitRunning(timeout time.Duration) string {
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		if qt.State() == "Running" {
			return qt.SelfIP()
		}
		if u := qt.LoginURL(); u != "" {
			fmt.Println("NEEDS_LOGIN:", u)
		}
		time.Sleep(500 * time.Millisecond)
	}
	return ""
}

func callThroughProxy(proxy, host string, port int, method string, args map[string]any) map[string]any {
	if args == nil {
		args = map[string]any{}
	}
	pu, _ := url.Parse("http://" + proxy)
	client := &http.Client{
		Timeout: 15 * time.Second,
		Transport: &http.Transport{
			Proxy:           http.ProxyURL(pu),
			TLSClientConfig: &tls.Config{InsecureSkipVerify: true}, // E2E 传输验证；App 侧走证书 pin
		},
	}
	body, _ := json.Marshal(map[string]any{
		"jsonrpc": "2.0", "id": 1, "method": "call",
		"params": []any{"00000000000000000000000000000000", "quartz-app-api", method, args},
	})
	resp, err := client.Post(fmt.Sprintf("https://%s:%d/ubus", host, port), "application/json", bytes.NewReader(body))
	if err != nil {
		fmt.Println("proxy call error:", err)
		return map[string]any{}
	}
	defer resp.Body.Close()
	raw, _ := io.ReadAll(resp.Body)
	var out struct {
		Result []json.RawMessage `json:"result"`
	}
	if err := json.Unmarshal(raw, &out); err != nil || len(out.Result) < 2 {
		fmt.Println("bad reply:", string(raw))
		return map[string]any{}
	}
	var payload map[string]any
	_ = json.Unmarshal(out.Result[1], &payload)
	return payload
}
