// W6.5：远程识别徽标（HeroCard）与远程引导页（RemotePage）。
import 'package:flutter/material.dart' hide SnapshotController;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quartzwrt_app/api/models.dart';
import 'package:quartzwrt_app/features/overview/cards.dart';
import 'package:quartzwrt_app/widgets/quartz/quartz_controls.dart';
import 'package:quartzwrt_app/widgets/quartz/quartz_icons.dart';
import 'package:quartzwrt_app/features/settings/remote_page.dart';
import 'package:quartzwrt_app/l10n/app_localizations.dart';
import 'package:quartzwrt_app/native/tailnet.dart';
import 'package:quartzwrt_app/state/app_state.dart';
import 'package:quartzwrt_app/state/tailnet_state.dart';
import 'package:quartzwrt_app/storage/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeEngine implements TailnetEngineApi {
  bool started = false;
  String? ifaces;
  String backend = 'NeedsLogin';
  String login = 'https://login.example/a/42';

  @override
  bool setInterfaces(String json) {
    ifaces = json;
    return true;
  }

  @override
  bool start(String stateDir, String hostname) {
    started = true;
    return true;
  }

  @override
  void stop() => started = false;

  @override
  String proxyAddr() => started && backend == 'Running' ? '127.0.0.1:4567' : '';

  @override
  String loginUrl() => started ? login : '';

  @override
  String state() => started ? backend : 'Stopped';

  @override
  String selfIp() => started && backend == 'Running' ? '100.9.9.9' : '';

  @override
  String lastError() => '';

  @override
  String logs() => '';

  @override
  String version() => 'fake';
}

class _FixedSnap extends SnapshotController {
  _FixedSnap(this.fixed);

  final SnapshotState fixed;

  @override
  SnapshotState build() => fixed;
}

PairedRouter _router({String? remoteHost}) => PairedRouter(
  id: 'dev1',
  name: 'quartzwrt-vm',
  model: 'QEMU x86_64',
  host: '10.0.2.2',
  port: 8443,
  fingerprint:
      '9d79d120'
          'ab' *
      28,
  deviceId: 'dev1',
  addedAt: 1,
  remoteHost: remoteHost,
  remotePort: remoteHost == null ? null : 443,
);

Widget _host(
  Widget child, {
  required SharedPreferences prefs,
  SnapshotState? snap,
  TailnetEngineApi? engine,
}) => ProviderScope(
  overrides: [
    prefsProvider.overrideWithValue(prefs),
    if (snap != null) snapshotProvider.overrideWith(() => _FixedSnap(snap)),
    tailnetEngineProvider.overrideWithValue(engine),
    tailnetDirProvider.overrideWithValue(() async => '/tmp/qt-test-tailnet'),
    tailnetInterfacesProvider.overrideWithValue(
      () async => '[{"name":"wlan0","index":2,"addrs":["192.168.1.5"]}]',
    ),
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

Snapshot _snapWithTailscale() => Snapshot({
  'v': 1,
  'services': {
    'tailscale': {'running': true, 'ip': '100.118.170.8'},
  },
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('hero badge: LAN vs remote', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: const [
          AppL10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppL10n.supportedLocales,
        home: Scaffold(
          body: Column(
            children: [
              HeroCard(snapshot: null, fallbackName: 'r'),
              HeroCard(snapshot: null, fallbackName: 'r', remote: true),
            ],
          ),
        ),
      ),
    );
    expect(find.text('r'), findsNWidgets(2));
    expect(find.text('WAN'), findsNWidgets(2));
    expect(
      find.byWidgetPredicate((w) => w is QzIcon && w.name == QzIcons.cloud),
      findsOneWidget,
    ); // 仅远程带云标
  });

  testWidgets('remote page shows real tailscale status from snapshot', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final reg = RouterRegistry(prefs);
    await reg.upsert(_router());
    await reg.setActive('dev1');

    await tester.pumpWidget(
      _host(
        const RemotePage(),
        prefs: prefs,
        snap: SnapshotState(kind: SnapKind.ok, data: _snapWithTailscale()),
      ),
    );
    await tester.pump();

    expect(find.text('路由器端 · Tailscale'), findsOneWidget);
    expect(find.text('运行中'), findsWidgets);
    expect(find.text('100.118.170.8'), findsOneWidget);
    expect(find.text('使用此地址添加远程连接'), findsOneWidget);
    expect(
      find.text('未设置——在家经局域网直连；外出后在本页添加 tailnet 地址即可远程管理。'),
      findsOneWidget,
    );
  });

  testWidgets('remote page: not detected + guide when tailscale absent', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final reg = RouterRegistry(prefs);
    await reg.upsert(_router());
    await reg.setActive('dev1');

    await tester.pumpWidget(
      _host(
        const RemotePage(),
        prefs: prefs,
        snap: SnapshotState(
          kind: SnapKind.ok,
          data: Snapshot({'v': 1, 'services': {}}),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('未安装'), findsOneWidget);
    expect(find.textContaining('未检测到 Tailscale'), findsOneWidget);
    expect(find.text('使用此地址添加远程连接'), findsNothing);
  });

  testWidgets('tap use-this-address opens sheet prefilled with tailnet IP', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final reg = RouterRegistry(prefs);
    await reg.upsert(_router());
    await reg.setActive('dev1');

    await tester.pumpWidget(
      _host(
        const RemotePage(),
        prefs: prefs,
        snap: SnapshotState(kind: SnapKind.ok, data: _snapWithTailscale()),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('使用此地址添加远程连接'));
    await tester.pumpAndSettle();

    expect(find.text('100.118.170.8'), findsWidgets); // 页内 + 表单预填
    expect(find.text('测试并保存'), findsOneWidget);
  });

  testWidgets('embedded card: unavailable build shows explicit fallback text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 3600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final reg = RouterRegistry(prefs);
    await reg.upsert(_router());
    await reg.setActive('dev1');

    await tester.pumpWidget(
      _host(
        const RemotePage(),
        prefs: prefs,
        snap: SnapshotState(kind: SnapKind.ok, data: _snapWithTailscale()),
        engine: null,
      ),
    );
    await tester.pump();

    expect(find.text('内嵌直连（实验）'), findsOneWidget);
    expect(find.textContaining('此构建未包含内嵌引擎'), findsOneWidget);
  });

  testWidgets('embedded card: enable → needsLogin with login button', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 3600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final reg = RouterRegistry(prefs);
    await reg.upsert(_router());
    await reg.setActive('dev1');
    final engine = _FakeEngine();

    await tester.pumpWidget(
      _host(
        const RemotePage(),
        prefs: prefs,
        snap: SnapshotState(kind: SnapKind.ok, data: _snapWithTailscale()),
        engine: engine,
      ),
    );
    await tester.pump();
    expect(find.text('开启内嵌直连'), findsOneWidget);

    await tester.tap(find.byType(QzToggle));
    await tester.pump(const Duration(milliseconds: 100));

    expect(engine.started, isTrue);
    expect(find.text('等待登录'), findsOneWidget);
    expect(find.text('登录 Tailscale'), findsOneWidget);
    expect(find.text('复制链接'), findsOneWidget);
  });

  testWidgets(
    'remote page shows saved remote address with in-use badge when active',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final reg = RouterRegistry(prefs);
      await reg.upsert(_router(remoteHost: '100.118.170.8'));
      await reg.setActive('dev1');

      await tester.pumpWidget(
        _host(
          const RemotePage(),
          prefs: prefs,
          snap: SnapshotState(kind: SnapKind.ok, data: _snapWithTailscale()),
        ),
      );
      await tester.pump();

      expect(find.text('100.118.170.8:443'), findsOneWidget);
      expect(find.text('移除'), findsOneWidget);
    },
  );
}
