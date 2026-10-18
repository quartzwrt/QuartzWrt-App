// 路由器 tab 首页渲染（分组入口 / 已实现 chip / 在线设备数）。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quartzwrt_app/api/models.dart';
import 'package:quartzwrt_app/features/router/router_page.dart';
import 'package:quartzwrt_app/l10n/app_localizations.dart';
import 'package:quartzwrt_app/state/app_state.dart' as st;

class _FakeSnapshot extends st.SnapshotController {
  @override
  st.SnapshotState build() => st.SnapshotState(
        kind: st.SnapKind.ok,
        data: Snapshot({
          'host': {'hostname': 'router', 'model': 'FNet3399', 'release': 'QuartzWrt test'},
          'clients': {'total': 2, 'items': []},
        }),
      );
}

class _NoRouter extends st.ActiveRouterNotifier {
  @override
  PairedRouter? build() => null;
}

void main() {
  testWidgets('router page groups entries and marks implemented pages', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('zh')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          st.snapshotProvider.overrideWith(_FakeSnapshot.new),
          st.activeRouterProvider.overrideWith(_NoRouter.new),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: const RouterPage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('路由器'), findsWidgets);
    expect(find.text('FNet3399 · QuartzWrt test'), findsOneWidget);
    expect(find.text('接口'), findsOneWidget);
    expect(find.text('无线'), findsOneWidget);
    expect(find.text('DHCP 与 DNS'), findsOneWidget);
    expect(find.text('启动项'), findsOneWidget);
    expect(find.text('防火墙'), findsOneWidget);
    expect(find.text('待后续版本'), findsWidgets);
    expect(find.text('可用'), findsWidgets);
    expect(find.text('2 在线'), findsOneWidget);
  });
}
