// W6.2 端到端冒烟（对真实路由器 / VM）：
//   dart run tool/e2e_vm.dart [host] [port] [password]
// 验证：TOFU 指纹捕获 → login 双令牌 → 严格 pin 客户端 status → 错误密码拒绝 →
// 软件包面（WP-5 packages：installed/upgradable/history/available）→ logout 清理。
// 仅依赖纯 Dart 层（api/pairing；不触 Flutter）。
import 'dart:io';

import 'package:quartzwrt_app/api/packages.dart';
import 'package:quartzwrt_app/auth/pairing.dart';

Future<void> main(List<String> args) async {
  final host = args.isNotEmpty ? args[0] : '127.0.0.1';
  final port = args.length > 1 ? int.parse(args[1]) : 8443;
  final password = args.length > 2 ? args[2] : 'quartz';
  var failures = 0;

  void check(String name, bool ok) {
    stdout.writeln('${ok ? 'PASS' : 'FAIL'}  $name');
    if (!ok) failures++;
  }

  stdout.writeln('== pairing $host:$port ==');
  final PairOutcome out;
  try {
    out = await pairRouter(
      host: host,
      port: port,
      password: password,
      deviceName: 'e2e-cli',
    );
  } on PairException catch (e) {
    check('pair ($host:$port): ${e.code} ${e.message}', false);
    exit(1);
  }
  check('pair ok · name=${out.router.name}', out.router.name.isNotEmpty);
  check('fingerprint captured (64 hex)', RegExp(r'^[0-9a-f]{64}$').hasMatch(out.router.fingerprint));
  check('tokens issued', out.tokens.accessToken.isNotEmpty && out.tokens.refreshToken.isNotEmpty);

  final c = clientFor(out.router); // 严格 pin 客户端
  final st = await c.status(accessToken: out.tokens.accessToken);
  final snap = st.data['snapshot'];
  final snapMap = snap is Map<String, dynamic> ? snap : const <String, dynamic>{};
  final hostSec = snapMap['host'];
  final hostname = hostSec is Map ? (hostSec['hostname'] ?? '') : '';
  check('status via strict-pin client (v=${snapMap['v']} host=$hostname)',
      st.ok && snapMap['v'] == 1 && '$hostname'.isNotEmpty);

  try {
    await pairRouter(host: host, port: port, password: 'definitely-wrong-$port', deviceName: 'e2e-bad');
    check('wrong password rejected', false);
  } on PairException catch (e) {
    check('wrong password rejected (${e.code})', e.code == 'invalid_credentials');
  }

  // ---- 软件包面（WP-5 packages 扩展；只读 scope，不改路由器状态）----
  final tok = out.tokens.accessToken;

  final inst = await c.packages(accessToken: tok, scope: 'installed', page: 1, perPage: 5);
  final instPage = inst.ok ? PackagesPage.fromPayload(inst.data) : null;
  check(
    'packages installed (total=${instPage?.total}, first=${instPage?.items.isEmpty ?? true ? '-' : instPage!.items.first.name})',
    inst.ok && (instPage?.total ?? 0) > 50 && (instPage?.items.isNotEmpty ?? false),
  );

  final up = await c.packages(accessToken: tok, scope: 'upgradable', perPage: 5);
  check('packages upgradable readable (ok=${up.ok}, total=${up.ok ? PackagesPage.fromPayload(up.data).total : '-'})', up.ok);

  final hist = await c.packages(accessToken: tok, scope: 'history');
  check('packages history readable (ok=${hist.ok}, items=${hist.ok ? PackagesPage.fromPayload(hist.data).ops.length : '-'})', hist.ok);

  final srch = await c.packages(accessToken: tok, scope: 'available', query: 'tail', perPage: 100);
  final names = srch.ok ? PackagesPage.fromPayload(srch.data).items.map((p) => p.name).toList() : const <String>[];
  check('packages available search "tail" hits tailscale (${names.length} matches)',
      srch.ok && names.any((n) => n.contains('tailscale')));

  final lo = await c.logout(deviceId: out.router.deviceId, refreshToken: out.tokens.refreshToken);
  check('cleanup logout', lo.ok);

  stdout.writeln(failures == 0 ? '\nALL PASS' : '\nFAILURES: $failures');
  exit(failures == 0 ? 0 : 1);
}
