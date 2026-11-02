// 局域网发现（DESIGN §3）：mDNS 浏览 `_quartz-app._tcp.local`（umdns 宣告）。
// TXT 段（WP-5 §6.3）：v/path/name/fp/rel——multicast_dns 将各段以换行拼接，
// 逐行 `k=v` 解析即可（无歧义）。
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:multicast_dns/multicast_dns.dart';

import 'multicast_lock.dart';

const kQuartzService = '_quartz-app._tcp.local';

/// 发现结果（TXT 可缺省字段；fingerprint 为空=未验证，走 TOFU）。
class DiscoveredRouter {
  const DiscoveredRouter({
    required this.name,
    required this.model,
    required this.release,
    required this.host,
    required this.port,
    required this.fingerprint,
  });

  final String name;
  final String model;
  final String release;
  final String host;
  final int port;
  final String fingerprint;

  bool get verifiable => fingerprint.isNotEmpty;
}

/// 解析 TXT 文本（换行分段的 k=v；容错：空行/无 `=` 行忽略，键小写）。
Map<String, String> parseTxt(String text) {
  final out = <String, String>{};
  for (final line in text.split('\n')) {
    final t = line.trim();
    if (t.isEmpty) continue;
    final i = t.indexOf('=');
    if (i <= 0) continue;
    out[t.substring(0, i).toLowerCase()] = t.substring(i + 1).trim();
  }
  return out;
}

/// 浏览局域网内的 QuartzWrt 路由器（[timeout] 为 PTR 等待窗口）。
Future<List<DiscoveredRouter>> discoverRouters({
  Duration timeout = const Duration(seconds: 4),
  MDnsClient? client,
}) async {
  final c = client ?? MDnsClient();
  final own = client == null;
  if (own) {
    // Android 真机：未持有 MulticastLock 时 Wi-Fi 栈会丢弃 mDNS 组播包。
    await MulticastLock.acquire();
    try {
      await c.start(
        // 手机上排除 rmnet/tun 等非 LAN 接口，避免把查询发到蜂窝/VPN 面。
        interfacesFactory: _isAndroid ? _lanInterfaces : null,
        onError: (Object e) => debugPrint('mDNS stream error: $e'),
      );
    } catch (_) {
      await MulticastLock.release();
      rethrow;
    }
  }
  final found = <DiscoveredRouter>[];
  final seen = <String>{};
  const sub = Duration(seconds: 2);
  try {
    await for (final PtrResourceRecord ptr in c.lookup<PtrResourceRecord>(
      ResourceRecordQuery.serverPointer(kQuartzService),
      timeout: timeout,
    )) {
      final fqdn = ptr.domainName;
      if (!seen.add(fqdn)) continue;

      final txt = <String, String>{};
      await for (final TxtResourceRecord t in c.lookup<TxtResourceRecord>(
        ResourceRecordQuery.text(fqdn),
        timeout: sub,
      )) {
        txt.addAll(parseTxt(t.text));
        break;
      }

      String? target;
      var port = 443;
      await for (final SrvResourceRecord s in c.lookup<SrvResourceRecord>(
        ResourceRecordQuery.service(fqdn),
        timeout: sub,
      )) {
        target = s.target;
        port = s.port;
        break;
      }
      if (target == null) continue;

      String? host;
      await for (final IPAddressResourceRecord a
          in c.lookup<IPAddressResourceRecord>(
            ResourceRecordQuery.addressIPv4(target),
            timeout: sub,
          )) {
        host = a.address.address;
        break;
      }
      host ??= target.replaceAll(RegExp(r'\.$'), '');

      found.add(
        DiscoveredRouter(
          name: txt['name']?.isNotEmpty == true
              ? txt['name']!
              : fqdn.split('.').first,
          model: txt['model'] ?? '',
          release: txt['rel'] ?? '',
          host: host,
          port: port,
          fingerprint: txt['fp'] ?? '',
        ),
      );
    }
  } finally {
    if (own) {
      try {
        c.stop();
      } catch (e) {
        debugPrint('mDNS stop failed: $e');
      }
      await MulticastLock.release();
    }
  }
  if (found.isEmpty) {
    debugPrint('mDNS: no $kQuartzService responders within ${timeout.inSeconds}s');
  }
  return found;
}

bool get _isAndroid =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Android 上优先只用真实 LAN 接口。
///
/// multicast_dns 默认对 `NetworkInterface.list()` 的每个接口 joinMulticast；
/// 某些设备在 rmnet/tun 等接口上 join 会抛错，导致整次发现直接失败。
Future<Iterable<NetworkInterface>> _lanInterfaces(
  InternetAddressType type,
) async {
  final all = await NetworkInterface.list(
    includeLinkLocal: true,
    type: type,
    includeLoopback: false,
  );
  final lan = all.where((i) => !_isWanLikeInterface(i.name)).toList();
  debugPrint(
    'mDNS interfaces: '
    '${lan.map((i) => '${i.name}[${i.addresses.map((a) => a.address).join(',')}]').join(' ')}',
  );
  return lan.isEmpty ? all : lan;
}

bool _isWanLikeInterface(String name) {
  final n = name.toLowerCase();
  const prefixes = [
    'rmnet',
    'dummy',
    'tun',
    'ppp',
    'clat',
    'v4-',
    'ip6tnl',
    'sit',
    'gre',
  ];
  return prefixes.any((p) => n.startsWith(p));
}
