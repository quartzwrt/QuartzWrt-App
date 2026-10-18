// WP-6 L2/L3：bandix 富化行 / 详情扩展卡 / 流量明细页（数据面 = 快照 §3.7）。
import 'package:flutter/material.dart' hide SnapshotController;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quartzwrt_app/api/models.dart';
import 'package:quartzwrt_app/features/bandix/bandix_page.dart';
import 'package:quartzwrt_app/features/bandix/bandix_panel.dart';
import 'package:quartzwrt_app/features/registry.dart';
import 'package:quartzwrt_app/l10n/app_localizations.dart';
import 'package:quartzwrt_app/l10n/app_localizations_zh.dart';
import 'package:quartzwrt_app/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FixedSnap extends SnapshotController {
  _FixedSnap(this.fixed);

  final SnapshotState fixed;

  @override
  SnapshotState build() => fixed;
}

Snapshot _snapFull() => Snapshot({
      'v': 1,
      'ts': 1760000000,
      'services': {
        'bandix': {'running': true, 'core': '0.12.11'},
      },
      'bandix': {
        'available': true,
        'devices': 12,
        'online': 9,
        'wan': {'rx_bps': 3481600, 'tx_bps': 522240},
        'limits': {
          'default_rx_bps': 131072,
          'default_tx_bps': 0,
          'whitelist_enabled': true,
          'whitelist_count': 1,
          'schedule_count': 3,
          'quota_count': 1,
        },
        'top': [
          {'mac': '00:11:32:7d:55:60', 'host': 'NAS', 'ip': '192.168.1.10', 'rx_b': 823456789, 'tx_b': 123456789, 'pct': 38.6, 'rx_r': 1250000, 'tx_r': 240000, 'q': true},
          {'mac': 'aa:bb:cc:dd:ee:ff', 'host': 'laptop', 'ip': '192.168.1.20', 'rx_b': 456789012, 'tx_b': 78901234, 'pct': 21.9, 'rx_r': 410000, 'tx_r': 96000, 'sch': 1},
        ],
        'conn': {'total': 128, 'tcp': 96, 'udp': 32},
        'dns': {'queries': 45231},
      },
    });

Widget _host(Widget child, {SnapshotState? snap}) => ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(_prefs()),
        if (snap != null) snapshotProvider.overrideWith(() => _FixedSnap(snap)),
      ],
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: const [
          AppL10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppL10n.supportedLocales,
        home: child,
      ),
    );

late SharedPreferences _prefsInstance;
SharedPreferences _prefs() => _prefsInstance;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _prefsInstance = await SharedPreferences.getInstance();
  });

  test('模型：bandix 节容忍解析（缺失/未启用/字段类型异常）', () {
    final none = Snapshot({'v': 1});
    expect(none.bandix, isNull);
    expect(none.bandixAvailable, isFalse);
    expect(none.bandixTop, isEmpty);

    final off = Snapshot({
      'v': 1,
      'bandix': {'available': false},
    });
    expect(off.bandixAvailable, isFalse);

    final weird = Snapshot({
      'v': 1,
      'bandix': {
        'available': true,
        'top': [
          'bad',
          {'mac': 'aa:bb:cc:dd:ee:ff', 'rx_b': 1},
        ],
      },
    });
    expect(weird.bandixAvailable, isTrue);
    expect(weird.bandixTop, hasLength(1));
    expect(weird.bandixTop.first['mac'], 'aa:bb:cc:dd:ee:ff');
  });

  test('注册表：bandix 富化行文本（可用时含在线/总数；不可用时 null）', () {
    final spec = serviceRowFor('bandix');
    expect(spec, isNotNull);
    final l10n = AppL10nZh();
    expect(spec!.enrich!(l10n, const {'running': true}, _snapFull()), '在线 9/12');
    expect(spec.enrich!(l10n, const {'running': true}, Snapshot({'v': 1})), isNull);
  });

  testWidgets('详情扩展卡：数值/动作行齐全；未启用时显示说明', (tester) async {
    await tester.pumpWidget(_host(const Scaffold(body: SingleChildScrollView(child: BandixPanel())), snap: SnapshotState(kind: SnapKind.ok, data: _snapFull())));
    await tester.pumpAndSettle();
    expect(find.text('在线设备'), findsOneWidget);
    expect(find.text('9 / 12'), findsOneWidget);
    expect(find.text('流量明细'), findsOneWidget);
    expect(find.text('默认限速'), findsWidgets);   // 总体限速行 + 动作入口同名
    expect(find.text('限速白名单'), findsOneWidget);
    expect(find.text('主机名绑定'), findsOneWidget);
    // 总体限速策略值（默认限速 128 KB/s · 白名单 开 · 规则 3 · 配额 1 · 设备 1）
    expect(find.textContaining('128 KB/s'), findsOneWidget);
    expect(find.textContaining('规则 3'), findsOneWidget);
    // 原 WAN 速率行已删（与概览网络卡重复）
    expect(find.text('WAN 速率'), findsNothing);
    expect(find.textContaining('↓'), findsWidgets);

  });

  testWidgets('详情扩展卡：未启用/缺失时显示说明', (tester) async {
    await tester.pumpWidget(_host(const Scaffold(body: SingleChildScrollView(child: BandixPanel())),
        snap: SnapshotState(kind: SnapKind.ok, data: Snapshot({'v': 1}))));
    await tester.pumpAndSettle();
    expect(find.textContaining('暂不可用'), findsOneWidget);
  });

  testWidgets('流量明细页：摘要 + Top 表；下拉刷新句柄可用', (tester) async {
    await tester.pumpWidget(_host(const BandixPage(), snap: SnapshotState(kind: SnapKind.ok, data: _snapFull())));
    await tester.pumpAndSettle();
    expect(find.text('流量明细'), findsWidgets);
    expect(find.text('9 / 12'), findsOneWidget);
    expect(find.text('NAS'), findsOneWidget);
    expect(find.text('laptop'), findsOneWidget);
    expect(find.text('设备流量 Top'), findsOneWidget);
    // 设备速率与限速策略徽标
    expect(find.textContaining('↓ 1.19 MB/s'), findsOneWidget);   // NAS 设备侧 WAN 速率（App 用 B/s 口径）
    expect(find.text('配额'), findsWidgets);                       // NAS 有配额
    expect(find.textContaining('限速 1'), findsOneWidget);         // laptop 1 条时段规则
    // 累计行保留，占比随行显示（同一行文本）
    expect(find.textContaining('累计'), findsWidgets);
    expect(find.textContaining('38.6%'), findsOneWidget);
    // 汇总卡的 下行/上行 行已删（改用总体限速）
    expect(find.text('默认限速'), findsWidgets);
    expect(find.textContaining('规则 3'), findsOneWidget);
  });

  testWidgets('流量明细页：不可用态说明（无崩溃）', (tester) async {
    await tester.pumpWidget(_host(const BandixPage(), snap: SnapshotState(kind: SnapKind.ok, data: Snapshot({'v': 1}))));
    await tester.pumpAndSettle();
    expect(find.textContaining('暂不可用'), findsOneWidget);
  });
}
