// tsnet 探针（spike）：验证 userspace tailnet 节点可在无 VPN、无 Tailscale
// 移动端 App 的前提下启动，并产出交互式登录 URL（AuthURL）。
//
// 运行: go run ./probe
package main

import (
	"context"
	"fmt"
	"os"
	"time"

	"tailscale.com/tsnet"
)

func main() {
	dir, err := os.MkdirTemp("", "tsnet-spike-")
	if err != nil {
		panic(err)
	}
	defer os.RemoveAll(dir)

	s := &tsnet.Server{
		Hostname: "quartz-app-spike",
		Dir:      dir,
	}
	defer s.Close()

	ctx, cancel := context.WithTimeout(context.Background(), 90*time.Second)
	defer cancel()

	upErr := make(chan error, 1)
	go func() { _, err := s.Up(ctx); upErr <- err }()

	lc, err := s.LocalClient()
	if err != nil {
		panic(err)
	}

	deadline := time.Now().Add(75 * time.Second)
	for time.Now().Before(deadline) {
		st, err := lc.StatusWithoutPeers(ctx)
		if err == nil && st != nil {
			fmt.Printf("state=%s\n", st.BackendState)
			if st.AuthURL != "" {
				fmt.Printf("AUTH_URL=%s\n", st.AuthURL)
				fmt.Println("RESULT=LOGIN_URL_OK")
				return
			}
			switch st.BackendState {
			case "Running":
				fmt.Println("RESULT=ALREADY_LOGGED_IN")
				return
			}
		}
		select {
		case err := <-upErr:
			fmt.Printf("up returned: %v\n", err)
			fmt.Println("RESULT=UP_ERROR")
			return
		case <-time.After(time.Second):
		}
	}
	fmt.Println("RESULT=TIMEOUT")
}
