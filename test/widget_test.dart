import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quartzwrt_app/main.dart';

void main() {
  testWidgets('home renders not-connected state (en)', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const QuartzApp());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.router_outlined), findsOneWidget);
    expect(find.text('No router connected'), findsOneWidget);
    expect(find.text('Scan network'), findsOneWidget);
    expect(find.text('Add by address'), findsOneWidget);
  });

  testWidgets('home renders zh strings', (tester) async {
    // MaterialApp 的默认 locale 解析走 platformDispatcher.locales——须同时置 localesTestValue
    tester.platformDispatcher.localesTestValue = const [Locale('zh')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const QuartzApp());
    await tester.pumpAndSettle();

    expect(find.text('未连接路由器'), findsOneWidget);
    expect(find.text('扫描局域网'), findsOneWidget);
  });
}
