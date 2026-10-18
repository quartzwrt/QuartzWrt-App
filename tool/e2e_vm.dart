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
  // 环境自适应：VM（x86）无 5G 模组 → 断言空态；真机（FNet3399）有模组 →
  // 断言 available/模组 + qmodem.at_cfg 的 `lang` 适配（quartz2）。
  final cellRaw = snapMap['cellular'];
  check('snapshot.cellular 存在（§3.9 节）', cellRaw is Map<String, dynamic>);
  final cell = Snapshot.parse(snapMap)?.cellular;
  if (cell != null && cell.available) {
    check(
      'cellular 真机：available=true、shown=${cell.shown}、modems=${cell.modems.length}',
      cell.shown && cell.modems.isNotEmpty,
    );
    final modem = cell.modems.first;
    final at = await c.action(
      accessToken: tok,
      action: 'qmodem.at_cfg',
      args: {'config_section': modem.id, 'lang': 'en'},
    );
    final atResult = at.data['result'];
    final atData = atResult is Map ? atResult['data'] : null;
    // 上游返回 `{at_cfg:{...}}`；兼容已解包的顶层形态
    final atMap = atData is Map ? atData : null;
    final atInner = atMap != null && atMap['at_cfg'] is Map ? atMap['at_cfg'] as Map : atMap;
    final cmds = atInner is Map ? atInner['cmds'] : null;
    check(
      'qmodem.at_cfg 真机 + lang=en（${at.error?.code ?? 'ok'}，cmds=${cmds is List ? cmds.length : '-'}）',
      at.ok && cmds is List && cmds.isNotEmpty,
    );
    final ports = await c.action(accessToken: tok, action: 'qmodem.tty_ports');
    check('qmodem.tty_ports 真机可达（${ports.error?.code ?? 'ok'}）', ports.ok);
  } else {
    check(
      'cellular 空态：available=false 且 shown=false（tab 隐藏）',
      cell != null && cell.available == false && cell.shown == false,
    );
    final ports = await c.action(accessToken: tok, action: 'qmodem.tty_ports');
    check(
      'qmodem 条目链路可达（未装 qmodem → data_unavailable；${ports.error?.code}）',
      ports.ok || ports.error?.code == 'data_unavailable',
    );
  }
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

  // ---- 路由器 tab（W6.10；配置面 + luci 启动项/时区；只读 + 负例）----
  final sysCfg = await c.call('config.read', {'access_token': tok, 'config': 'system'});
  final sysVal = sysCfg.data['value'];
  final sysMap = sysVal is Map<String, dynamic> ? sysVal : const <String, dynamic>{};
  String sysSection = '';
  Map<String, dynamic> sysValues = const {};
  for (final e in sysMap.entries) {
    if (e.key.contains('system') && e.value is Map<String, dynamic>) {
      sysSection = e.key;
      sysValues = e.value as Map<String, dynamic>;
      break;
    }
  }
  check(
    'config.read system（${sysSection.isEmpty ? '-' : sysSection} hostname=${sysValues['hostname'] ?? '-'}）',
    sysCfg.ok && sysSection.isNotEmpty && sysValues['hostname'] is String,
  );

  final initList = await c.action(accessToken: tok, action: 'luci.init_list');
  final initData = initList.data['result'];
  final initInner = initData is Map ? initData['data'] : null;
  final initMap = initInner is Map ? initInner : const {};
  check('luci.init_list（${initMap.length} 个启动项，含 cron/uhttpd）',
      initList.ok && initMap.containsKey('cron') && initMap.containsKey('uhttpd'));

  final tz = await c.action(accessToken: tok, action: 'luci.timezones');
  final tzData = tz.data['result'];
  final tzInner = tzData is Map ? tzData['data'] : null;
  final tzMap = tzInner is Map ? tzInner : const {};
  check('luci.timezones（${tzMap.length} 个时区，含 Asia/Shanghai）',
      tz.ok && tzMap.containsKey('Asia/Shanghai'));

  final badInit = await c.action(
    accessToken: tok,
    action: 'luci.init_action',
    args: {'name': '../etc/passwd', 'action': 'start'},
  );
  check('luci.init_action 负例：路径注入被拒（${badInit.error?.code}）',
      badInit.error?.code == 'bad_request');

  // ---- W6.11 管理权 / 防火墙（r12 注册表 + luci.set_password 转发条目）----
  final db = await c.call('config.read', {'access_token': tok, 'config': 'dropbear'});
  final dbVal = db.data['value'];
  final dbMap = dbVal is Map<String, dynamic> ? dbVal : const <String, dynamic>{};
  String dbSection = '';
  Map<String, dynamic> dbValues = const {};
  for (final e in dbMap.entries) {
    final v = e.value;
    if (v is Map<String, dynamic> &&
        (e.key.contains('dropbear') || v.containsKey('Port') || v.containsKey('PasswordAuth'))) {
      dbSection = e.key;
      dbValues = v;
      break;
    }
  }
  check(
    'config.read dropbear（${dbSection.isEmpty ? '-' : dbSection} Port=${dbValues['Port'] ?? '-'} PasswordAuth=${dbValues['PasswordAuth'] ?? '-'}）',
    db.ok && dbSection.isNotEmpty && dbValues['Port'] is String,
  );

  final fw = await c.call('config.read', {'access_token': tok, 'config': 'firewall'});
  final fwVal = fw.data['value'];
  final fwMap = fwVal is Map<String, dynamic> ? fwVal : const <String, dynamic>{};
  var hasFwZone = false, hasFwRule = false;
  for (final e in fwMap.entries) {
    if (e.key.contains('zone') && e.value is Map) hasFwZone = true;
    if (e.key.contains('rule') && e.value is Map) hasFwRule = true;
  }
  check('config.read firewall（${fwMap.length} 节，zone=$hasFwZone rule=$hasFwRule）',
      fw.ok && fwMap.isNotEmpty && hasFwZone);

  final badPw = await c.action(
    accessToken: tok,
    action: 'luci.set_password',
    args: {'username': 'root', 'password': ''},
  );
  check('luci.set_password 负例：空密码被拒（${badPw.error?.code}）',
      badPw.error?.code == 'bad_request');

  // ---- W6.11 挂载 / LED（fstab 注册表 + luci.mounts/leds 条目）----
  final fs = await c.call('config.read', {'access_token': tok, 'config': 'fstab'});
  final fsVal = fs.data['value'];
  final fsMap = fsVal is Map<String, dynamic> ? fsVal : const <String, dynamic>{};
  check('config.read fstab（${fsMap.length} 节，global=${fsMap.keys.any((k) => k.contains('global'))}）',
      fs.ok && fsMap.keys.any((k) => k.contains('global')));

  final mp = await c.action(accessToken: tok, action: 'luci.mounts');
  final mpResult = mp.data['result'];
  final mpData = mpResult is Map ? mpResult['data'] : null;
  final mpList = mpData is Map ? mpData['result'] : null;
  check('luci.mounts（${mpList is List ? mpList.length : '-'} 个挂载点）',
      mp.ok && mpList is List && mpList.isNotEmpty);

  final leds = await c.action(accessToken: tok, action: 'luci.leds');
  final ledResult = leds.data['result'];
  final ledData = ledResult is Map ? ledResult['data'] : null;
  final ledInner = ledData is Map ? ledData['result'] : null;
  final ledMap = ledInner is Map ? ledInner : ledData;
  check('luci.leds（${ledMap is Map ? ledMap.length : '-'} 个 LED）',
      leds.ok && ledMap is Map && ledMap.isNotEmpty);

  // ---- W6.11 计划任务（cron.read / cron.write；只读 + 负例，不改 crontab）----
  final cr = await c.call('cron.read', {'access_token': tok});
  check('cron.read（path=${cr.data['path'] ?? '-'}, exists=${cr.data['exists'] ?? '-'}）',
      cr.ok && cr.data['path'] == '/etc/crontabs/root');
  // 注意：NUL 会在 rpcd JSON 层被截断，无法作为负例；用 SOH(\u0001)。
  final badCron = await c.call('cron.write', {'access_token': tok, 'content': 'a\u0001b'});
  check('cron.write 负例：控制字符被拒（${badCron.error?.code}）',
      badCron.error?.code == 'bad_request');

  final lo = await c.logout(deviceId: out.router.deviceId, refreshToken: out.tokens.refreshToken);
  check('cleanup logout', lo.ok);

  stdout.writeln(failures == 0 ? '\nALL PASS' : '\nFAILURES: $failures');
  exit(failures == 0 ? 0 : 1);
}
