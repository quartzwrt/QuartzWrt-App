// 局域网发现（DESIGN §3）：mDNS 浏览 `_quartz-app._tcp.local`（umdns 宣告）。
// TXT 段（WP-5 §6.3）：v/path/name/fp/rel——multicast_dns 将各段以换行拼接，
// 逐行 `k=v` 解析即可（无歧义）。
import 'package:multicast_dns/multicast_dns.dart';

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
    await c.start();
  }
  final found = <DiscoveredRouter>[];
  final seen = <String>{};
  const sub = Duration(seconds: 2);
  try {
    await for (final PtrResourceRecord ptr
        in c.lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(kQuartzService), timeout: timeout)) {
      final fqdn = ptr.domainName;
      if (!seen.add(fqdn)) continue;

      final txt = <String, String>{};
      await for (final TxtResourceRecord t
          in c.lookup<TxtResourceRecord>(ResourceRecordQuery.text(fqdn), timeout: sub)) {
        txt.addAll(parseTxt(t.text));
        break;
      }

      String? target;
      var port = 443;
      await for (final SrvResourceRecord s
          in c.lookup<SrvResourceRecord>(ResourceRecordQuery.service(fqdn), timeout: sub)) {
        target = s.target;
        port = s.port;
        break;
      }
      if (target == null) continue;

      String? host;
      await for (final IPAddressResourceRecord a
          in c.lookup<IPAddressResourceRecord>(ResourceRecordQuery.addressIPv4(target), timeout: sub)) {
        host = a.address.address;
        break;
      }
      host ??= target.replaceAll(RegExp(r'\.$'), '');

      found.add(DiscoveredRouter(
        name: txt['name']?.isNotEmpty == true ? txt['name']! : fqdn.split('.').first,
        model: txt['model'] ?? '',
        release: txt['rel'] ?? '',
        host: host,
        port: port,
        fingerprint: txt['fp'] ?? '',
      ));
    }
  } finally {
    if (own) c.stop();
  }
  return found;
}
