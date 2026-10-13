// Mock 路由器（E2E 验证用）：同时监听
//
//	① 宿主 LAN 口（供模拟器「按地址添加」配对，TOFU 捕获证书 pin）
//	② tailnet 口（经 tsnet 加入本地 headscale；:443，同一张证书）
//
// 实现 quartz-app-api 的最小方法子集（info/login/refresh/logout/status/devices）。
//
// 用法（headscale 已就绪；preauth key 见 -authkey）：
//
//	go run ./e2e/mockrouter -control http://<host>:8080 -authkey <key> -lan :4450 -dir /tmp/mock
package main

import (
	"context"
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/tls"
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/json"
	"encoding/pem"
	"flag"
	"fmt"
	"log"
	"math/big"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"tailscale.com/tsnet"
)

var (
	selfIP      string
	flagControl = flag.String("control", "", "headscale URL，如 http://172.23.77.234:8080")
	flagAuthKey = flag.String("authkey", "", "preauth key")
	flagLAN     = flag.String("lan", "0.0.0.0:4450", "宿主 LAN 监听地址（模拟器经 10.0.2.2 访问）")
	flagDir     = flag.String("dir", "/tmp/qt-mock-router", "状态目录（证书 + tsnet 状态）")
	flagHost    = flag.String("hostname", "quartz-mock", "tailnet 主机名")
)

func main() {
	flag.Parse()
	if err := os.MkdirAll(*flagDir, 0o700); err != nil {
		log.Fatal(err)
	}

	cert, err := loadOrCreateCert(*flagDir)
	if err != nil {
		log.Fatal(err)
	}
	tlsCfg := &tls.Config{Certificates: []tls.Certificate{cert}, MinVersion: tls.VersionTLS12}

	// ① LAN 口
	ln, err := net.Listen("tcp", *flagLAN)
	if err != nil {
		log.Fatalf("lan listen: %v", err)
	}
	go func() {
		log.Printf("LAN  https://%s/ubus", ln.Addr().String())
		_ = http.Serve(tls.NewListener(ln, tlsCfg), http.HandlerFunc(handle))
	}()

	// ② tailnet 口（tsnet → headscale）
	s := &tsnet.Server{
		Hostname:   *flagHost,
		Dir:        filepath.Join(*flagDir, "tsnet"),
		ControlURL: *flagControl,
		AuthKey:    *flagAuthKey,
		Logf:       func(f string, a ...any) { log.Printf("tsnet: "+f, a...) },
	}
	defer s.Close()
	tln, err := s.Listen("tcp", ":443")
	if err != nil {
		log.Fatalf("tsnet listen: %v", err)
	}
	ip := "?"
	if st, err := s.LocalClient(); err == nil {
		for i := 0; i < 60; i++ {
			sst, err := st.StatusWithoutPeers(context.Background())
			if err == nil && sst.BackendState == "Running" {
				for _, a := range sst.TailscaleIPs {
					if a.Is4() {
						ip = a.String()
					}
				}
				break
			}
			time.Sleep(time.Second)
		}
	}
	selfIP = ip
	log.Printf("TAILNET https://%s:443/ubus（hostname=%s）", ip, *flagHost)
	fmt.Printf("MOCK_READY lang=%s tailnet_ip=%s\n", ln.Addr().String(), ip)
	_ = http.Serve(tls.NewListener(tln, tlsCfg), http.HandlerFunc(handle))
}

// ---- 最小 quartz-app-api ----

type rpcReq struct {
	JSONRPC string            `json:"jsonrpc"`
	ID      int               `json:"id"`
	Method  string            `json:"method"`
	Params  []json.RawMessage `json:"params"`
}

func handle(w http.ResponseWriter, r *http.Request) {
	var req rpcReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || len(req.Params) < 3 {
		http.Error(w, "bad request", http.StatusBadRequest)
		return
	}
	var method string
	_ = json.Unmarshal(req.Params[2], &method)
	var args map[string]any
	if len(req.Params) > 3 {
		_ = json.Unmarshal(req.Params[3], &args)
	}

	var payload map[string]any
	switch method {
	case "info":
		payload = map[string]any{
			"api": 1, "ok": true, "auth": []string{"password"}, "password_set": true,
			"features": []string{"status", "actions", "devices", "mdns"},
			"name":     "quartz-mock", "model": "Mock Router", "kernel": "6.6.0-mock",
			"release": "QuartzWrt 0.9.0 (mock)",
		}
	case "login":
		if args["password"] != "quartz" {
			payload = errPayload("invalid_credentials", "wrong password")
			break
		}
		payload = tokens()
	case "refresh":
		payload = tokens()
	case "logout":
		payload = map[string]any{"ok": true}
	case "status":
		if !authed(args) {
			payload = errPayload("token_expired", "expired")
			break
		}
		payload = map[string]any{"ok": true, "api": 1, "snapshot": snapshot()}
	case "devices":
		if !authed(args) {
			payload = errPayload("token_expired", "expired")
			break
		}
		payload = map[string]any{"ok": true, "api": 1, "devices": []map[string]any{
			{"device_id": "mock-dev", "name": "quartz-e2e", "created": time.Now().Unix(), "last_seen": time.Now().Unix(), "revoked": false, "current": true},
		}}
	default:
		payload = errPayload("bad_request", "unknown method "+method)
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{
		"jsonrpc": "2.0", "id": req.ID, "result": []any{0, payload},
	})
}

func authed(args map[string]any) bool {
	t, _ := args["access_token"].(string)
	return t != ""
}

func tokens() map[string]any {
	now := time.Now().Unix()
	return map[string]any{
		"ok": true, "api": 1,
		"access_token":  "mock-access-" + fmt.Sprint(now),
		"access_exp":    now + 900,
		"refresh_token": "mock-refresh-" + fmt.Sprint(now),
		"refresh_exp":   now + 86400,
		"device_id":     "mock-dev",
	}
}

func errPayload(code, msg string) map[string]any {
	return map[string]any{"ok": false, "api": 1, "error": map[string]any{"code": code, "message": msg}}
}

func snapshot() map[string]any {
	now := time.Now().Unix()
	return map[string]any{
		"v": 1, "ts": now, "interval": 5,
		"host": map[string]any{
			"hostname": "quartz-mock", "model": "Mock Router", "release": "QuartzWrt 0.9.0 (mock)",
			"kernel": "6.6.0-mock", "uptime": 12345,
		},
		"system": map[string]any{
			"cpu_pct": 3.5, "load": []float64{0.10, 0.20, 0.30}, "temp_c": 41.5,
			"mem":    map[string]any{"used": 200 * 1024 * 1024, "total": 1024 * 1024 * 1024, "pct": 20},
			"rootfs": map[string]any{"used": 100 * 1024 * 1024, "total": 991 * 1024 * 1024, "pct": 10},
		},
		"net": map[string]any{
			"wan":    map[string]any{"up": true, "ifname": "eth0", "proto": "dhcp", "ipv4": "192.168.9.2", "rx_bps": 4096, "tx_bps": 2048},
			"series": map[string]any{"step": 5, "rx": []int{1, 2, 3, 2, 1, 4, 6, 3}, "tx": []int{1, 1, 2, 2, 1, 1, 3, 2}},
		},
		"clients": map[string]any{"total": 1, "items": []map[string]any{
			{"host": "mock-laptop", "ip": "192.168.9.5", "mac": "aa:bb:cc:dd:ee:ff"},
		}},
		"services": map[string]any{
			"tailscale": map[string]any{"running": true, "ip": selfIP},
			"openclash": map[string]any{"running": false},
		},
	}
}

// ---- 自签证书（首次生成，持久复用——App 侧 TOFU 捕获的 pin 跨重启稳定） ----

func loadOrCreateCert(dir string) (tls.Certificate, error) {
	certPath := filepath.Join(dir, "mock.crt")
	keyPath := filepath.Join(dir, "mock.key")
	if _, err := os.Stat(certPath); err == nil {
		return tls.LoadX509KeyPair(certPath, keyPath)
	}
	key, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		return tls.Certificate{}, err
	}
	tpl := &x509.Certificate{
		SerialNumber: big.NewInt(1),
		Subject:      pkix.Name{CommonName: "quartz-mock"},
		NotBefore:    time.Now().Add(-time.Hour),
		NotAfter:     time.Now().AddDate(5, 0, 0),
		KeyUsage:     x509.KeyUsageDigitalSignature | x509.KeyUsageKeyEncipherment,
		ExtKeyUsage:  []x509.ExtKeyUsage{x509.ExtKeyUsageServerAuth},
		DNSNames:     []string{"quartz-mock", "localhost"},
		IPAddresses:  []net.IP{net.ParseIP("127.0.0.1")},
	}
	der, err := x509.CreateCertificate(rand.Reader, tpl, tpl, &key.PublicKey, key)
	if err != nil {
		return tls.Certificate{}, err
	}
	cf, _ := os.Create(certPath)
	_ = pem.Encode(cf, &pem.Block{Type: "CERTIFICATE", Bytes: der})
	_ = cf.Close()
	kb, _ := x509.MarshalECPrivateKey(key)
	kf, _ := os.Create(keyPath)
	_ = pem.Encode(kf, &pem.Block{Type: "EC PRIVATE KEY", Bytes: kb})
	_ = kf.Close()
	return tls.LoadX509KeyPair(certPath, keyPath)
}
