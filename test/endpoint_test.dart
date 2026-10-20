// W6.5 远程链路：端点派生 + 失败切换传输。
import 'package:flutter_test/flutter_test.dart';
import 'package:quartzwrt_app/api/client.dart';
import 'package:quartzwrt_app/api/endpoint.dart';
import 'package:quartzwrt_app/api/envelope.dart';
import 'package:quartzwrt_app/api/models.dart';

PairedRouter _router({String? remoteHost, int? remotePort}) => PairedRouter(
  id: 'dev1',
  name: 'r',
  model: 'm',
  host: '192.168.1.1',
  port: 443,
  fingerprint: 'ab' * 32,
  deviceId: 'dev1',
  addedAt: 1,
  remoteHost: remoteHost,
  remotePort: remotePort,
);

const _okResult = ApiResult.ok(1, {'value': 'ok'});
const _refused = ApiResult.fail(0, ApiError('connection_refused', 'refused'));
const _denied = ApiResult.fail(1, ApiError('access_denied', 'denied'));

class _FakeTransport implements ApiTransport {
  _FakeTransport(this.result);

  final ApiResult result;
  int calls = 0;

  @override
  Future<ApiResult> call(String method, [Map<String, dynamic>? args]) async {
    calls++;
    return result;
  }
}

/// 按 (baseUrl, proxy) 取假传输；未登记的组合抛错（测试即断言不该被尝试）。
_FakeTransport _fake(Map<String, _FakeTransport> m, String key) =>
    m[key] ?? (throw StateError('unexpected attempt: $key'));

void main() {
  group('endpointsOf', () {
    test('local only', () {
      final eps = endpointsOf(_router());
      expect(eps.length, 1);
      expect(eps.first.kind, EndpointKind.local);
      expect(eps.first.baseUrl, 'https://192.168.1.1:443');
    });

    test('local + remote（远端在后，端口默认 443）', () {
      final eps = endpointsOf(_router(remoteHost: '100.1.2.3'));
      expect(eps.length, 2);
      expect(eps[0].kind, EndpointKind.local);
      expect(eps[1].kind, EndpointKind.remote);
      expect(eps[1].baseUrl, 'https://100.1.2.3:443');
    });

    test('empty remote host treated as absent', () {
      expect(endpointsOf(_router(remoteHost: '')).length, 1);
    });
  });

  group('isTransportFailure', () {
    test('transport-class codes trigger; app-level errors do not', () {
      expect(isTransportFailure(_refused), isTrue);
      expect(
        isTransportFailure(const ApiResult.fail(0, ApiError('timeout', ''))),
        isTrue,
      );
      expect(
        isTransportFailure(
          const ApiResult.fail(0, ApiError('bad_certificate', '')),
        ),
        isTrue,
      );
      expect(isTransportFailure(_denied), isFalse);
      expect(
        isTransportFailure(
          const ApiResult.fail(1, ApiError('token_expired', '')),
        ),
        isFalse,
      );
      expect(isTransportFailure(_okResult), isFalse);
    });
  });

  group('FailoverTransport', () {
    late List<Endpoint> eps;
    late Map<String, _FakeTransport> fakes;
    Endpoint? currentState;
    var switches = <Endpoint>[];
    String? Function(Endpoint)? proxyFor;

    String key(Endpoint e, String? proxy) => '${e.baseUrl}|${proxy ?? ''}';

    FailoverTransport build() => FailoverTransport(
      endpoints: eps,
      fingerprint: 'ab' * 32,
      current: () => currentState,
      onSwitch: (e) {
        currentState = e;
        switches.add(e);
      },
      clientFactory: (e, fp, proxy) => _fake(fakes, key(e, proxy)),
      proxyFor: proxyFor,
    );

    setUp(() {
      eps = endpointsOf(_router(remoteHost: '100.1.2.3'));
      fakes = {
        key(eps[0], null): _FakeTransport(_okResult),
        key(eps[1], null): _FakeTransport(_okResult),
      };
      currentState = eps[0];
      switches = [];
      proxyFor = null;
    });

    test('no endpoints → transport error', () async {
      eps = const [];
      final t = build();
      final r = await t.call('info');
      expect(r.ok, isFalse);
      expect(r.error?.code, 'transport');
    });

    test('current endpoint ok → no switch', () async {
      final t = build();
      final r = await t.call('status');
      expect(r.ok, isTrue);
      expect(fakes[key(eps[0], null)]!.calls, 1);
      expect(fakes[key(eps[1], null)]!.calls, 0);
      expect(switches, isEmpty);
    });

    test(
      'local transport-fail → remote retried once; success sticks',
      () async {
        fakes[key(eps[0], null)] = _FakeTransport(_refused);
        final t = build();
        final r = await t.call('status');
        expect(r.ok, isTrue);
        expect(fakes[key(eps[0], null)]!.calls, 1);
        expect(fakes[key(eps[1], null)]!.calls, 1);
        expect(switches.single.kind, EndpointKind.remote);

        // 固化后下一次调用直接走远程
        await t.call('status');
        expect(fakes[key(eps[1], null)]!.calls, 2);
      },
    );

    test('remote in use, fails → falls back to local', () async {
      currentState = eps[1];
      fakes[key(eps[1], null)] = _FakeTransport(_refused);
      final t = build();
      final r = await t.call('status');
      expect(r.ok, isTrue);
      expect(switches.single.kind, EndpointKind.local);
    });

    test('app-level error does NOT rotate', () async {
      fakes[key(eps[0], null)] = _FakeTransport(_denied);
      final t = build();
      final r = await t.call('status');
      expect(r.ok, isFalse);
      expect(r.error?.code, 'access_denied');
      expect(fakes[key(eps[1], null)]!.calls, 0);
      expect(switches, isEmpty);
    });

    test('both fail → returns alt failure, no switch', () async {
      fakes[key(eps[0], null)] = _FakeTransport(_refused);
      fakes[key(eps[1], null)] = _FakeTransport(
        const ApiResult.fail(0, ApiError('timeout', '')),
      );
      final t = build();
      final r = await t.call('status');
      expect(r.ok, isFalse);
      expect(r.error?.code, 'timeout');
      expect(switches, isEmpty);
    });

    test('single endpoint transport-fail → no rotation attempt', () async {
      eps = [eps[0]];
      fakes[key(eps[0], null)] = _FakeTransport(_refused);
      final t = build();
      final r = await t.call('status');
      expect(r.error?.code, 'connection_refused');
      expect(switches, isEmpty);
    });

    test(
      'remote via proxy: proxy first, sticks, no extra direct attempt',
      () async {
        proxyFor = (e) => e.kind == EndpointKind.remote ? '127.0.0.1:9' : '';
        fakes[key(eps[1], '127.0.0.1:9')] = _FakeTransport(_okResult);
        currentState = eps[1];
        final t = build();
        expect(t.attempts(), [
          (eps[1], '127.0.0.1:9'),
          (eps[1], null),
          (eps[0], null),
        ]);
        final r = await t.call('status');
        expect(r.ok, isTrue);
        expect(fakes[key(eps[1], '127.0.0.1:9')]!.calls, 1);
        expect(fakes[key(eps[1], null)]!.calls, 0); // 未走直连
        expect(switches, isEmpty);
      },
    );

    test(
      'proxy fails → direct retry succeeds (same endpoint, no switch)',
      () async {
        proxyFor = (e) => e.kind == EndpointKind.remote ? '127.0.0.1:9' : '';
        fakes[key(eps[1], '127.0.0.1:9')] = _FakeTransport(_refused);
        fakes[key(eps[1], null)] = _FakeTransport(_okResult);
        currentState = eps[1];
        final t = build();
        final r = await t.call('status');
        expect(r.ok, isTrue);
        expect(fakes[key(eps[1], null)]!.calls, 1);
        expect(switches, isEmpty);
      },
    );

    test('proxy and direct fail → falls back to local endpoint', () async {
      proxyFor = (e) => e.kind == EndpointKind.remote ? '127.0.0.1:9' : '';
      fakes[key(eps[1], '127.0.0.1:9')] = _FakeTransport(_refused);
      fakes[key(eps[1], null)] = _FakeTransport(_refused);
      currentState = eps[1];
      final t = build();
      final r = await t.call('status');
      expect(r.ok, isTrue);
      expect(switches.single.kind, EndpointKind.local);
    });

    test('local endpoint never uses proxy', () async {
      proxyFor = (e) => '127.0.0.1:9'; // 即便对所有端点都给代理
      currentState = eps[0];
      final t = build();
      expect(t.attempts().first, (eps[0], null));
    });

    test('stale current (not in list) → uses first', () async {
      currentState = const Endpoint(
        host: '10.0.0.9',
        port: 443,
        kind: EndpointKind.remote,
      );
      final t = build();
      final r = await t.call('status');
      expect(r.ok, isTrue);
      expect(fakes[key(eps[0], null)]!.calls, 1);
    });
  });
}
