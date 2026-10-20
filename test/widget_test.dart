import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quartzwrt_app/app.dart';
import 'package:quartzwrt_app/discovery/mdns.dart';
import 'package:quartzwrt_app/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpApp(WidgetTester tester, Locale locale) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        // mDNS 在测试环境不可用：注入固定发现结果
        discoverProvider.overrideWithValue(
          () async => const <DiscoveredRouter>[],
        ),
      ],
      child: const QuartzApp(),
    ),
  );
  // 避免 pumpAndSettle（扫描指示器为无限动画）
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  testWidgets('unpaired start shows discover page (en)', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await pumpApp(tester, const Locale('en'));
    expect(find.text('Connect a router'), findsOneWidget);
    expect(find.text('Add by address…'), findsOneWidget);
  });

  testWidgets('unpaired start shows discover page (zh)', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('zh')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await pumpApp(tester, const Locale('zh'));
    expect(find.text('连接路由器'), findsOneWidget);
    expect(find.text('按地址添加…'), findsOneWidget);
  });
}
