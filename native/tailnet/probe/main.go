// 本机联调探针：用生产引擎起一个 tailnet 节点，打印登录 URL / 状态 / 自身 IP。
//
// 用法: go run ./probe [stateDir]
//   - 默认控制面 = 官方；未登录时打印 AuthURL（浏览器完成登录即可）
//   - 指向本地 headscale：$stateDir/config.json 写 {"control_url":"http://127.0.0.1:8080","auth_key":"<preauth>"}
package main

import (
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/quartzwrt/QuartzWrt-App/native/tailnet"
)

func main() {
	dir := filepath.Join(os.TempDir(), "qt-tailnet-probe")
	if len(os.Args) > 1 {
		dir = os.Args[1]
	}
	if err := os.MkdirAll(dir, 0o700); err != nil {
		panic(err)
	}
	if err := tailnet.Start(dir, "quartz-app-probe"); err != nil {
		fmt.Println("start failed:", err)
		os.Exit(1)
	}
	defer tailnet.Stop()
	last := ""
	for i := 0; i < 60; i++ {
		state := tailnet.State()
		cur := fmt.Sprintf("state=%s ip=%s proxy=%s err=%s", state, tailnet.SelfIP(), tailnet.ProxyAddr(), tailnet.LastError())
		if cur != last {
			fmt.Println(cur)
			last = cur
		}
		if u := tailnet.LoginURL(); u != "" {
			fmt.Println("AUTH_URL=" + u)
		}
		if state == "Running" {
			fmt.Println("RESULT=ALREADY_LOGGED_IN")
			return
		}
		if i == 20 && tailnet.LoginURL() != "" {
			fmt.Println("RESULT=LOGIN_URL_OK")
			return
		}
		time.Sleep(time.Second)
	}
	fmt.Println("RESULT=TIMEOUT")
	fmt.Println(tailnet.Logs())
}
