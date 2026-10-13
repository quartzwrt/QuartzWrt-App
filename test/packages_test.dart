// WP-6 软件包管理面：模型解析（契约容忍）+ 软件包子段/操作记录页 widget 测。
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quartzwrt_app/api/client.dart';
import 'package:quartzwrt_app/api/envelope.dart';
import 'package:quartzwrt_app/api/models.dart';
import 'package:quartzwrt_app/api/packages.dart';
import 'package:quartzwrt_app/auth/token_manager.dart';
import 'package:quartzwrt_app/features/apps/package_log_page.dart';
import 'package:quartzwrt_app/features/apps/packages_section.dart';
import 'package:quartzwrt_app/l10n/app_localizations.dart';
import 'package:quartzwrt_app/state/app_state.dart';
import 'package:quartzwrt_app/storage/store.dart';

// ---- 模型解析 ----

void main() {
  _dioClassifyTests();

  group('PackageItem 解析（契约容忍）', () {
    test('完整字段', () {
      final it = PackageItem.fromJson({
        'name': 'ttyd',
        'version': '1.7.8-r1',
        'installed_version': '1.7.7-r1',
        'description': 'terminal over web',
        'arch': 'x86_64',
        'license': 'MIT',
        'origin': 'feeds/packages/ttyd',
        'installed_size': 620768,
        'file_size': 408255,
        'installed': true,
        'upgradable': true,
      });
      expect(it.name, 'ttyd');
      expect(it.installedVersion, '1.7.7-r1');
      expect(it.installedSize, 620768);
      expect(it.upgradable, isTrue);
    });

    test('缺字段/类型异常不抛（降级默认值）', () {
      final it = PackageItem.fromJson({'name': 'nano', 'installed_size': 'x'});
      expect(it.version, '');
      expect(it.installedSize, 0);
      expect(it.installed, isFalse);
    });
  });

  group('PackagesPage 解析', () {
    test('包 scope → PackageItem；分页元信息', () {
      final pg = PackagesPage.fromPayload({
        'scope': 'installed',
        'page': 2,
        'per_page': 24,
        'total': 343,
        'pages': 15,
        'items': [
          {'name': 'a', 'version': '1'},
          'not-a-map', // 杂项容忍
          {'name': 'b', 'version': '2', 'upgradable': true, 'target_version': '3'},
        ],
      });
      expect(pg.scope, 'installed');
      expect(pg.page, 2);
      expect(pg.hasMore, isTrue);
      expect(pg.items.length, 2);
      expect(pg.items[1].targetVersion, '3');
      expect(pg.ops, isEmpty);
    });

    test('history scope → PackageOp（显式字段：action/ok/耗时）', () {
      final pg = PackagesPage.fromPayload({
        'scope': 'history',
        'items': [
          {'ts': 100, 'action': 'packages.remove', 'target': 'no-such', 'ok': false, 'output': 'ERROR: No such package', 'duration_ms': 78},
          {'ts': 200, 'action': 'packages.upgrade', 'target': 'ttyd', 'ok': true, 'output': '(1/1) Upgrading', 'duration_ms': 1234},
        ],
      });
      final ops = pg.ops;
      expect(ops.length, 2);
      expect(ops[0].op, 'remove');
      expect(ops[0].ok, isFalse);
      expect(ops[0].ts, 100);
      expect(ops[1].op, 'upgrade');
      expect(ops[1].durationMs, 1234);
      expect(pg.items, isEmpty);
    });

    test('history 旧固件形态回退（统一包条目映射）', () {
      final pg = PackagesPage.fromPayload({
        'scope': 'history',
        'items': [
          {'name': 'packages.remove', 'version': 'no-such', 'description': 'ERROR: No such package', 'file_size': 78, 'installed': false},
          {'name': 'packages.refresh', 'version': '', 'description': 'OK: 10456 distinct packages available', 'file_size': 2764, 'installed': true},
        ],
      });
      final ops = pg.ops;
      expect(ops.length, 2);
      expect(ops[0].op, 'remove');
      expect(ops[0].target, 'no-such');
      expect(ops[0].ok, isFalse);
      expect(ops[0].output, contains('No such package'));
      expect(ops[1].op, 'refresh');
      expect(ops[1].ok, isTrue);
      expect(ops[1].durationMs, 2764);
    });

    test('appended 累积下一页', () {
      PackageItem it(int i) => PackageItem(name: 'p$i', version: '1');
      final a = PackagesPage(scope: 'installed', page: 1, perPage: 24, total: 30, pages: 2, raw: [it(1)]);
      final b = PackagesPage(scope: 'installed', page: 2, perPage: 24, total: 30, pages: 2, raw: [it(2)]);
      final c = a.appended(b);
      expect(c.raw.length, 2);
      expect(c.page, 2);
      expect(c.hasMore, isFalse);
    });

    test('空/畸形 items 不抛', () {
      final pg = PackagesPage.fromPayload({'scope': 'installed'});
      expect(pg.items, isEmpty);
      expect(pg.pages, 0);
      final pg2 = PackagesPage.fromPayload({'scope': 'installed', 'items': 'oops'});
      expect(pg2.items, isEmpty);
    });
  });

  // ---- widget 测 ----

  group('Software packages section', () {
    testWidgets('可升级视图：版本 diff + 单包升级 + 全部升级', (tester) async {
      final calls = <Map<String, dynamic>>[];
      final t = _ScriptedTransport((method, args) {
        calls.add({'method': method, ...?args});
        if (method == 'packages' && args?['scope'] == 'upgradable') {
          final per = (args?['per_page'] as int?) ?? 24;
          if (per == 1) {
            return _ok({'scope': 'upgradable', 'page': 1, 'per_page': 1, 'total': 2, 'pages': 2, 'items': const []});
          }
          return _ok({
            'scope': 'upgradable',
            'page': 1,
            'per_page': 24,
            'total': 2,
            'pages': 1,
            'items': [
              {'name': 'ttyd', 'version': '1.7.8-r1', 'installed_version': '1.7.7-r1', 'file_size': 408255, 'installed': true, 'upgradable': true},
              {'name': 'bash', 'version': '5.4-r1', 'installed_version': '5.3-r4', 'file_size': 505000, 'installed': true, 'upgradable': true},
            ],
          });
        }
        if (method == 'action') {
          return _ok({
            'action': args?['action'],
            'result': {'stdout': 'ok', 'duration_ms': 120},
          });
        }
        return ApiResult.fail(1, const ApiError('bad_request', 'unknown scope'));
      });
      await tester.pumpWidget(_host(PackagesSection(), t));
      await tester.pumpAndSettle();

      expect(find.text('可升级 (2)'), findsOneWidget);
      expect(find.textContaining('1.7.7-r1 → 1.7.8-r1'), findsOneWidget);
      expect(find.text('全部升级（2）'), findsOneWidget);
      expect(find.text('升级'), findsNWidgets(2));

      // 单包升级
      await tester.tap(find.text('升级').first);
      await tester.pumpAndSettle();
      final upgradeCall = calls.lastWhere((c) => c['method'] == 'action');
      expect(upgradeCall['action'], 'packages.upgrade');
      expect((upgradeCall['args'] as Map)['name'], 'ttyd');
      expect(find.textContaining('已升级 ttyd'), findsOneWidget);

      // 全部升级（确认层 → 确认）
      await tester.tap(find.text('全部升级（2）'));
      await tester.pumpAndSettle();
      expect(find.text('全部升级？'), findsOneWidget);
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();
      final allCall = calls.lastWhere((c) => c['method'] == 'action');
      expect(allCall['action'], 'packages.upgrade');
      expect(allCall['args'], isEmpty);
    });

    testWidgets('可升级为空 → 全部最新提示', (tester) async {
      final t = _ScriptedTransport((method, args) {
        if (method == 'packages') {
          if (args?['scope'] == 'upgradable') {
            return _ok({'scope': 'upgradable', 'page': 1, 'per_page': 1, 'total': 0, 'pages': 0, 'items': const []});
          }
          return ApiResult.fail(1, const ApiError('bad_request', 'unknown method'));
        }
        return ApiResult.fail(1, const ApiError('transport', 'x'));
      });
      await tester.pumpWidget(_host(PackagesSection(), t));
      await tester.pumpAndSettle();
      expect(find.text('可升级'), findsOneWidget); // 无计数后缀
      expect(find.text('全部软件包均为最新。'), findsOneWidget);
    });

    testWidgets('旧固件（无 packages 方法）→ 降级说明卡', (tester) async {
      final t2 = _ScriptedTransport((method, args) => ApiResult.fail(1, const ApiError('bad_request', 'unknown method')));
      await tester.pumpWidget(_host(PackagesSection(), t2));
      await tester.pumpAndSettle();
      expect(find.text('软件包管理暂不可用'), findsOneWidget);
    });

    testWidgets('搜索视图：空查询提示 → 结果带已安装徽标', (tester) async {
      final t = _ScriptedTransport((method, args) {
        if (method == 'packages' && args?['scope'] == 'upgradable') {
          return _ok({'scope': 'upgradable', 'page': 1, 'per_page': 1, 'total': 0, 'pages': 0, 'items': const []});
        }
        if (method == 'packages' && args?['scope'] == 'installed') {
          return _ok({'scope': 'installed', 'page': 1, 'per_page': 24, 'total': 0, 'pages': 0, 'items': const []});
        }
        if (method == 'packages' && args?['scope'] == 'available') {
          return _ok({
            'scope': 'available',
            'page': 1,
            'per_page': 24,
            'total': 1,
            'pages': 1,
            'items': [
              {'name': 'tailscale', 'version': '1.98.3-r1', 'file_size': 4000000, 'installed': true, 'installed_version': '1.98.3-r1'},
            ],
          });
        }
        return ApiResult.fail(1, const ApiError('transport', 'x'));
      });
      await tester.pumpWidget(_host(PackagesSection(), t));
      await tester.pumpAndSettle();
      await tester.tap(find.text('全部'));
      await tester.pumpAndSettle();
      expect(find.textContaining('输入名称搜索软件包'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'tail');
      await tester.pump(const Duration(milliseconds: 500)); // 防抖
      await tester.pumpAndSettle();
      expect(find.text('tailscale'), findsOneWidget);
      expect(find.text('已安装'), findsWidgets); // 徽标
    });

    testWidgets('操作记录页：成功/失败两类渲染', (tester) async {
      final t = _ScriptedTransport((method, args) {
        if (method == 'packages' && args?['scope'] == 'history') {
          return _ok({
            'scope': 'history',
            'items': [
              {'ts': 100, 'action': 'packages.remove', 'target': 'no-such', 'ok': false, 'output': 'ERROR: No such package: no-such', 'duration_ms': 78},
              {'ts': 200, 'action': 'packages.refresh', 'ok': true, 'output': 'OK: 10456 distinct packages available', 'duration_ms': 2764},
            ],
          });
        }
        return ApiResult.fail(1, const ApiError('transport', 'x'));
      });
      await tester.pumpWidget(_host(const PackageLogPage(), t));
      await tester.pumpAndSettle();
      expect(find.text('操作记录'), findsOneWidget);
      expect(find.textContaining('卸载 · no-such'), findsOneWidget);
      expect(find.textContaining('刷新软件源'), findsOneWidget);
      expect(find.textContaining('失败'), findsWidgets);
      expect(find.textContaining('成功'), findsWidgets);
      expect(find.textContaining('No such package'), findsOneWidget);
    });
  });
}

// ---- 测试基建 ----

ApiResult _ok(Map<String, dynamic> data) => ApiResult.ok(1, data);

class _ScriptedTransport implements ApiTransport {
  _ScriptedTransport(this.onCall);

  final ApiResult Function(String method, Map<String, dynamic>? args) onCall;

  @override
  Future<ApiResult> call(String method, [Map<String, dynamic>? args]) async => onCall(method, args);
}

Widget _host(Widget child, ApiTransport transport) {
  final tm = TokenManager(() => transport, MemoryTokenStore(), routerId: 'dev1');
  tm.seed(
    const Tokens(accessToken: 'a1', accessExp: 9999999999, refreshToken: 'r1', refreshExp: 9999999999, deviceId: 'dev1'),
    'r1',
  );
  return ProviderScope(
    overrides: [tokenManagerProvider.overrideWithValue(tm)],
    child: MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: const [
        AppL10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppL10n.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

// ---- 错误分类（重刷固件换证书 → 需重新配对；VM 实测：Dio 未必给 badCertificate 类型）----

void _dioClassifyTests() {
  test('classifyDioError：底层 HandshakeException → bad_certificate', () {
    final e = DioException(
      requestOptions: RequestOptions(path: '/ubus'),
      type: DioExceptionType.unknown,
      error: const HandshakeException('CERTIFICATE_VERIFY_FAILED'),
    );
    expect(classifyDioError(e), 'bad_certificate');
  });

  test('classifyDioError：超时/拒连/未知的归一化', () {
    DioException mk(DioExceptionType t) => DioException(requestOptions: RequestOptions(path: '/ubus'), type: t);
    expect(classifyDioError(mk(DioExceptionType.receiveTimeout)), 'timeout');
    expect(classifyDioError(mk(DioExceptionType.connectionError)), 'connection_refused');
    expect(classifyDioError(mk(DioExceptionType.badCertificate)), 'bad_certificate');
    expect(classifyDioError(mk(DioExceptionType.unknown)), 'transport');
  });
}
