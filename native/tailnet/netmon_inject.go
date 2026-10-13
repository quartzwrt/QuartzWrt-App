// Android 平台适配：应用 UID 被禁 netlink（`netlinkrib: permission denied`，
// tailscale issue #2293/#8126），tsnet.Up 过程中枚举本机接口会失败。
//
// 解法（与官方 Android 客户端同路）：向 netmon **注册接口获取器**——
// Dart 侧用 dart:io（getifaddrs，不受 netlink 限制）取 {name,index,addrs}，
// 经 TailnetSetInterfaces 注入；MTU/MAC/状态在 Go 侧从 sysfs 补齐
// （/sys/class/net/*），前缀长度从 /proc/net/route（v4）与 /proc/net/if_inet6（v6）
// 推导（均不依赖 netlink）。
package tailnet

import (
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"math/bits"
	"net"
	"os"
	"strconv"
	"strings"

	"tailscale.com/net/netmon"
)

type ifaceSpec struct {
	Name  string   `json:"name"`
	Index int      `json:"index"`
	Addrs []string `json:"addrs"` // 纯地址（无前缀）；前缀由 Go 侧推导
}

var (
	ifaceSpecs         []ifaceSpec
	ifGetterRegistered bool
)

// SetInterfaces 注入本机接口表（JSON: [{"name","index","addrs":["1.2.3.4",…]},…]）。
// Android 上必须在 Start 之前调用一次；此后可随时更新（网络变化）。
func SetInterfaces(jsonStr string) error {
	var specs []ifaceSpec
	if err := json.Unmarshal([]byte(jsonStr), &specs); err != nil {
		return fmt.Errorf("bad interface json: %w", err)
	}
	mu.Lock()
	ifaceSpecs = specs
	mu.Unlock()
	logf("interfaces injected: %d", len(specs))
	return nil
}

// registerInterfaceGetter 惰性注册 netmon 获取器（Start 前调用；幂等）。
func registerInterfaceGetter() {
	mu.Lock()
	have := len(ifaceSpecs) > 0
	done := ifGetterRegistered
	mu.Unlock()
	if !have || done {
		return
	}
	netmon.RegisterInterfaceGetter(func() ([]netmon.Interface, error) {
		mu.Lock()
		specs := append([]ifaceSpec(nil), ifaceSpecs...)
		mu.Unlock()
		if len(specs) == 0 {
			return nil, errors.New("tailnet: no interfaces injected")
		}
		return buildInterfaces(specs), nil
	})
	ifGetterRegistered = true
	logf("netmon interface getter registered")
}

func buildInterfaces(specs []ifaceSpec) []netmon.Interface {
	v4plen := readRouteMasks()
	v6plen := readIPv6PrefixLens()
	out := make([]netmon.Interface, 0, len(specs))
	for _, sp := range specs {
		ifi := &net.Interface{Index: sp.Index, Name: sp.Name}
		if b, err := os.ReadFile("/sys/class/net/" + sp.Name + "/mtu"); err == nil {
			if n, e := strconv.Atoi(strings.TrimSpace(string(b))); e == nil {
				ifi.MTU = n
			}
		}
		if b, err := os.ReadFile("/sys/class/net/" + sp.Name + "/address"); err == nil {
			if hw, e := net.ParseMAC(strings.TrimSpace(string(b))); e == nil {
				ifi.HardwareAddr = hw
			}
		}
		// Android SELinux 禁读 /sys/class/net（avc denied）：sysfs 只作桌面端增强，
		// 是否 up 以「Dart 报来的接口带地址」兜底（带地址的接口必然 up）。
		up := len(sp.Addrs) > 0
		if b, err := os.ReadFile("/sys/class/net/" + sp.Name + "/operstate"); err == nil {
			up = strings.TrimSpace(string(b)) == "up" || up
		}
		if sp.Name == "lo" {
			ifi.Flags |= net.FlagLoopback
		}
		if up {
			ifi.Flags |= net.FlagUp | net.FlagRunning
		}
		if len(ifi.HardwareAddr) > 0 {
			ifi.Flags |= net.FlagBroadcast
		}

		var addrs []net.Addr
		for _, a := range sp.Addrs {
			ip := net.ParseIP(strings.TrimSpace(a))
			if ip == nil {
				continue
			}
			if v4 := ip.To4(); v4 != nil {
				plen := v4plen[sp.Name][v4.String()]
				if plen == 0 {
					plen = 32
				}
				addrs = append(addrs, &net.IPNet{IP: v4, Mask: net.CIDRMask(plen, 32)})
			} else {
				plen := v6plen[sp.Name][ip.String()]
				if plen == 0 {
					plen = 128
				}
				addrs = append(addrs, &net.IPNet{IP: ip, Mask: net.CIDRMask(plen, 128)})
			}
		}
		out = append(out, netmon.Interface{Interface: ifi, AltAddrs: addrs})
	}
	return out
}

// readRouteMasks 解析 /proc/net/route：iface → (网络地址 → 前缀长)。
func readRouteMasks() map[string]map[string]int {
	out := map[string]map[string]int{}
	b, err := os.ReadFile("/proc/net/route")
	if err != nil {
		return out
	}
	for i, line := range strings.Split(string(b), "\n") {
		if i == 0 || strings.TrimSpace(line) == "" {
			continue
		}
		f := strings.Fields(line)
		if len(f) < 8 {
			continue
		}
		iface, destHex, maskHex := f[0], f[1], f[7]
		dest, err1 := hexLE32(destHex)
		mask, err2 := hexLE32(maskHex)
		if err1 != nil || err2 != nil || mask == 0 {
			continue
		}
		plen := bits.OnesCount32(mask)
		netaddr := dest & mask
		if out[iface] == nil {
			out[iface] = map[string]int{}
		}
		out[iface][fmt.Sprintf("%d.%d.%d.%d", byte(netaddr>>24), byte(netaddr>>16), byte(netaddr>>8), byte(netaddr))] = plen
	}
	return out
}

// hexLE32 解析 /proc/net/route 的小端十六进制 32 位。
func hexLE32(s string) (uint32, error) {
	v, err := strconv.ParseUint(strings.TrimSpace(s), 16, 32)
	if err != nil {
		return 0, err
	}
	return uint32(v&0xff)<<24 | uint32(v>>8&0xff)<<16 | uint32(v>>16&0xff)<<8 | uint32(v>>24&0xff), nil
}

// readIPv6PrefixLens 解析 /proc/net/if_inet6：iface → (地址 → 前缀长)。
func readIPv6PrefixLens() map[string]map[string]int {
	out := map[string]map[string]int{}
	b, err := os.ReadFile("/proc/net/if_inet6")
	if err != nil {
		return out
	}
	for _, line := range strings.Split(string(b), "\n") {
		f := strings.Fields(line)
		if len(f) < 6 {
			continue
		}
		raw, err := hex.DecodeString(f[0])
		if err != nil || len(raw) != 16 {
			continue
		}
		plen, err := strconv.ParseInt(f[2], 16, 32)
		if err != nil {
			continue
		}
		iface := f[5]
		if out[iface] == nil {
			out[iface] = map[string]int{}
		}
		out[iface][net.IP(raw).String()] = int(plen)
	}
	return out
}
