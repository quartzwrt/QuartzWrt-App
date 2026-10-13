// QuartzWrt App —— 内嵌 tailnet 引擎的 c-shared 导出层。
//
// 构建（见 native/tailnet/README.md；scripts/build-native.sh 已封装）：
//
//	GOOS=android GOARCH=arm64 CGO_ENABLED=1 CC=<ndk>/…/aarch64-linux-android24-clang \
//	  go build -buildmode=c-shared -trimpath -ldflags="-s -w" -o libtailnet.so ./csdk
//
// C ABI（字符串返回值指向 Go 侧持有内存，内容变更前保持有效；Dart 侧须立即拷贝）：
//
//	int         TailnetSetInterfaces(const char* json);                   // Android：Start 前注入接口表
//	int         TailnetStart(const char* stateDir, const char* hostname); // 0=ok
//	const char* TailnetProxyAddr();
//	const char* TailnetLoginURL();
//	const char* TailnetState();
//	const char* TailnetSelfIP();
//	const char* TailnetLastError();
//	const char* TailnetLogs();
//	const char* TailnetVersion();
//	void        TailnetStop();
package main

/*
#include <stdlib.h>
*/
import "C"

import (
	"sync"
	"unsafe"

	"github.com/quartzwrt/QuartzWrt-App/native/tailnet"
)

func main() {}

var (
	strMu sync.Mutex
	cache = map[string]*C.char{}
)

// cstr 按 key 缓存 C 字符串（内容不变复用；变更时替换并释放旧值——无泄漏增长）。
func cstr(key, val string) *C.char {
	strMu.Lock()
	defer strMu.Unlock()
	if old := cache[key]; old != nil {
		if C.GoString(old) == val {
			return old
		}
		C.free(unsafe.Pointer(old)) // #nosec G103 —— 自有 CString，键控释放
	}
	p := C.CString(val)
	cache[key] = p
	return p
}

//export TailnetStart
func TailnetStart(stateDir, hostname *C.char) C.int {
	if err := tailnet.Start(C.GoString(stateDir), C.GoString(hostname)); err != nil {
		return 1
	}
	return 0
}

//export TailnetSetInterfaces
func TailnetSetInterfaces(ifaceJSON *C.char) C.int {
	if err := tailnet.SetInterfaces(C.GoString(ifaceJSON)); err != nil {
		return 1
	}
	return 0
}

//export TailnetProxyAddr
func TailnetProxyAddr() *C.char { return cstr("proxy", tailnet.ProxyAddr()) }

//export TailnetLoginURL
func TailnetLoginURL() *C.char { return cstr("login", tailnet.LoginURL()) }

//export TailnetState
func TailnetState() *C.char { return cstr("state", tailnet.State()) }

//export TailnetSelfIP
func TailnetSelfIP() *C.char { return cstr("selfip", tailnet.SelfIP()) }

//export TailnetLastError
func TailnetLastError() *C.char { return cstr("err", tailnet.LastError()) }

//export TailnetLogs
func TailnetLogs() *C.char { return cstr("logs", tailnet.Logs()) }

//export TailnetVersion
func TailnetVersion() *C.char { return cstr("ver", tailnet.Version) }

//export TailnetStop
func TailnetStop() { _ = tailnet.Stop() }
