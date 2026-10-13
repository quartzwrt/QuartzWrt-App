// c-shared 打包探针（spike）：证明 tsnet 可经 NDK 交叉编译为 Android
// arm64 动态库（.so，Dart FFI / JNI 可直接加载）——不依赖 gomobile。
//
// 构建（在 dev/spike/tailscale 目录）：
//   CC=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android24-clang \
//   CGO_ENABLED=1 GOOS=android GOARCH=arm64 \
//   go build -buildmode=c-shared -o libtailnet.so ./cmdlib
package main

/*
#include <stdlib.h>
*/
import "C"

import (
	"unsafe"

	"github.com/quartzwrt/QuartzWrt-App/dev/spike/tailscale/androidlib"
)

func main() {}

//export TailnetStart
func TailnetStart(stateDir, hostname *C.char) *C.char {
	// 返回 "proxyAddr|err"（登录 URL 经 TailnetLoginURL() 轮询；
	// spike 简化：C.CString 不回收）
	addr, err := tailnet.Start(C.GoString(stateDir), C.GoString(hostname))
	msg := addr + "|"
	if err != nil {
		msg += err.Error()
	}
	return C.CString(msg)
}

//export TailnetLoginURL
func TailnetLoginURL() *C.char { return C.CString(tailnet.LoginURL()) }

//export TailnetState
func TailnetState() *C.char { return C.CString(tailnet.State()) }

//export TailnetLastError
func TailnetLastError() *C.char { return C.CString(tailnet.LastError()) }

//export TailnetStop
func TailnetStop() C.int {
	if err := tailnet.Stop(); err != nil {
		return 1
	}
	return 0
}

var _ = unsafe.Pointer(nil)
