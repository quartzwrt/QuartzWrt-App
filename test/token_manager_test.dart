import 'package:flutter_test/flutter_test.dart';
import 'package:quartzwrt_app/api/client.dart';
import 'package:quartzwrt_app/api/envelope.dart';
import 'package:quartzwrt_app/api/models.dart';
import 'package:quartzwrt_app/auth/token_manager.dart';
import 'package:quartzwrt_app/storage/store.dart';

/// 可编程假传输：按方法返回脚本化结果，记录调用序。
class FakeTransport implements ApiTransport {
  final List<String> calls = [];
  final Map<String, List<ApiResult>> script = {};

  void enqueue(String method, ApiResult r) => (script[method] ??= []).add(r);

  @override
  Future<ApiResult> call(String method, [Map<String, dynamic>? args]) async {
    calls.add(method);
    final q = script[method];
    if (q == null || q.isEmpty) {
      return ApiResult.fail(0, ApiError('transport', 'no script for $method'));
    }
    return q.removeAt(0);
  }
}

ApiResult ok(Map<String, dynamic> data) => ApiResult.ok(1, data);
ApiResult fail(String code) => ApiResult.fail(1, ApiError(code, code));

Map<String, dynamic> tokensPayload({String access = 'a1', String refresh = 'r1'}) => {
      'access_token': access,
      'access_exp': 9999999999,
      'refresh_token': refresh,
      'refresh_exp': 9999999999,
      'device_id': 'dev1',
    };

void main() {
  test('single-flight: concurrent ensureAccess triggers exactly one refresh', () async {
    final t = FakeTransport();
    t.enqueue('refresh', ok(tokensPayload()));
    final store = MemoryTokenStore();
    await store.writeRefresh('dev1', 'r0');

    final tm = TokenManager(() => t, store, routerId: 'dev1');
    final results = await Future.wait([tm.ensureAccess(), tm.ensureAccess(), tm.ensureAccess()]);

    expect(results, ['a1', 'a1', 'a1']);
    expect(t.calls.where((c) => c == 'refresh').length, 1);
    // 旋转后的新 refresh 已持久化
    expect(await store.readRefresh('dev1'), 'r1');
  });

  test('expired access is refreshed (with pre-expiry margin)', () async {
    final t = FakeTransport();
    final store = MemoryTokenStore();
    await store.writeRefresh('dev1', 'r0');
    var nowSec = 1000;
    final tm = TokenManager(
      () => t,
      store,
      routerId: 'dev1',
      now: () => DateTime.fromMillisecondsSinceEpoch(nowSec * 1000),
    );
    // 手工注入一个马上过期的 access（exp=1010，margin=30 → 立即视为过期）
    await tm.seed(
      const Tokens(
        accessToken: 'old',
        accessExp: 1010,
        refreshToken: 'r0',
        refreshExp: 0,
        deviceId: 'dev1',
      ),
      'r0',
    );
    t.enqueue('refresh', ok(tokensPayload(access: 'new')));
    expect(await tm.ensureAccess(), 'new');
    expect(t.calls, ['refresh']);
  });

  test('token_expired → refresh once and replay', () async {
    final t = FakeTransport();
    final store = MemoryTokenStore();
    await store.writeRefresh('dev1', 'r0');
    final tm = TokenManager(() => t, store, routerId: 'dev1');
    t.enqueue('refresh', ok(tokensPayload(access: 'a1')));
    t.enqueue('status', fail('token_expired'));
    t.enqueue('refresh', ok(tokensPayload(access: 'a2', refresh: 'r2')));
    t.enqueue('status', ok({'snapshot': {'v': 1}}));

    final r = await tm.call('status');
    expect(r.ok, isTrue);
    expect(t.calls, ['refresh', 'status', 'refresh', 'status']);
    expect(await store.readRefresh('dev1'), 'r2');
  });

  test('device_revoked → ApiAuthException + local credentials cleared', () async {
    final t = FakeTransport();
    final store = MemoryTokenStore();
    await store.writeRefresh('dev1', 'r0');
    final tm = TokenManager(() => t, store, routerId: 'dev1');
    t.enqueue('refresh', fail('device_revoked'));

    await expectLater(tm.ensureAccess(), throwsA(isA<ApiAuthException>()));
    expect(await store.readRefresh('dev1'), isNull);
  });

  test('transport error is not fatal to credentials', () async {
    final t = FakeTransport();
    final store = MemoryTokenStore();
    await store.writeRefresh('dev1', 'r0');
    final tm = TokenManager(() => t, store, routerId: 'dev1');
    t.enqueue('refresh', fail('timeout'));

    await expectLater(tm.ensureAccess(), throwsA(isA<ApiException>()));
    expect(await store.readRefresh('dev1'), 'r0'); // 保留，可重试
  });

  test('logout clears local state even when the call fails', () async {
    final t = FakeTransport();
    final store = MemoryTokenStore();
    await store.writeRefresh('dev1', 'r0');
    final tm = TokenManager(() => t, store, routerId: 'dev1');
    t.enqueue('refresh', ok(tokensPayload()));
    await tm.ensureAccess();

    t.enqueue('logout', fail('timeout'));
    await tm.logout();
    expect(await store.readRefresh('dev1'), isNull);
  });
}
