// W6.2 端到端冒烟（对真实路由器 / VM）：
//   dart run tool/e2e_vm.dart [host] [port] [password]
// 验证：TOFU 指纹捕获 → login 双令牌 → 严格 pin 客户端 status → 错误密码拒绝 →
// 软件包面（WP-5 packages：installed/upgradable/history/available）→ logout 清理。
// 仅依赖纯 Dart 层（api/pairing；不触 Flutter）。
import 'dart:io';

import 'package:quartzwrt_app/api/models.dart';
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
  final histOps = hist.ok ? PackagesPage.fromPayload(hist.data).ops : const <PackageOp>[];
  check('packages history readable (ok=${hist.ok}, items=${histOps.length})', hist.ok);
  // 形态断言（旧固件统一包条目/新固件显式字段两种形态都必须解析出 action 与 ts）
  if (histOps.isNotEmpty) {
    final o = histOps.first;
    check('history item shape parses (action=${o.action.isNotEmpty}, op=${o.op}, ts>0=${o.ts > 0})',
        o.action.isNotEmpty && o.op.isNotEmpty && o.ts > 0);
  }

  final srch = await c.packages(accessToken: tok, scope: 'available', query: 'tail', perPage: 100);
  final names = srch.ok ? PackagesPage.fromPayload(srch.data).items.map((p) => p.name).toList() : const <String>[];
  check('packages available search "tail" hits tailscale (${names.length} matches)',
      srch.ok && names.any((n) => n.contains('tailscale')));

  // ---- 蜂窝面（W6.12；读走快照 §3.9，页面级读/动作走 WP-5 转发项）----
  // VM 无 5G 模组（x86 镜像不预装 qmodem）→ 断言「空态契约」：节存在、
  // available=false（App 据此隐藏蜂窝 tab），且模型层能正确解析。
  final cellRaw = snapMap['cellular'];
  check('snapshot.cellular 存在（§3.9 节）', cellRaw is Map<String, dynamic>);
  final cell = Snapshot.parse(snapMap)?.cellular;
  check(
    'cellular 空态：available=false 且 shown=false（tab 隐藏）',
    cell != null && cell.available == false && cell.shown == false,
  );
  final dial = await c.action(
      accessToken: tok, action: 'qmodem.dial', args: {'config_section': 'modem1'});
  check(
    'qmodem 条目链路可达（未装 qmodem → data_unavailable，非 forbidden；${dial.error?.code}）',
    dial.error?.code == 'data_unavailable',
  );
  final unreg = await c.action(accessToken: tok, action: 'qmodem.scan_all');
  check('qmodem 未注册条目被拒（${unreg.error?.code}）', unreg.error?.code == 'forbidden_action');

  // ---- bandix 面（WP-8 P2；读走快照 §3.7，配置读/动作走 WP-5 转发项；只读+负例）----
  final bx = snapMap['bandix'];
  if (bx is Map<String, dynamic> && bx['available'] == true) {
    final top = bx['top'] is List ? bx['top'] as List : const [];
    check(
      'snapshot.bandix shape (devices=${bx['devices']}, online=${bx['online']}, top=${top.length})',
      bx['devices'] is int && bx['online'] is int && bx['wan'] is Map,
    );
    if (top.isNotEmpty && top.first is Map) {
      final t0 = top.first as Map;
      check('bandix top item shape (mac/ip/pct)',
          t0['mac'] is String && t0['pct'] is num && (t0['rx_b'] is num || t0['tx_b'] is num));
    }
  } else {
    stdout.writeln('SKIP  snapshot.bandix 不可用（未装/未开 traffic）——跳过形态断言');
  }

  final lim = await c.action(accessToken: tok, action: 'bandix.limits');
  final limData = lim.ok ? lim.data['result'] : null;
  final limInner = limData is Map ? limData['data'] : null;
  final wl = limInner is Map ? limInner['whitelist'] : null;
  check(
    'action bandix.limits（读条目；whitelist.enabled=${wl is Map ? wl['enabled'] : '-'}）',
    lim.ok && wl is Map,
  );

  final badMac = await c.action(
      accessToken: tok, action: 'bandix.whitelist_delete', args: {'mac': 'not-a-mac'});
  check('bandix 负例：非法 MAC 被拒（${badMac.error?.code}）', badMac.error?.code == 'bad_request');

  final unknown = await c.action(accessToken: tok, action: 'bandix.installUpdate');
  check('bandix 负例：未注册动作被拒（${unknown.error?.code}）', unknown.error?.code == 'forbidden_action');

  final lo = await c.logout(deviceId: out.router.deviceId, refreshToken: out.tokens.refreshToken);
  check('cleanup logout', lo.ok);

  stdout.writeln(failures == 0 ? '\nALL PASS' : '\nFAILURES: $failures');
  exit(failures == 0 ? 0 : 1);
}
