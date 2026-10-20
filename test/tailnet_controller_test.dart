// 内嵌直连（tsnet）控制器：状态派生 / 开关持久化 / 自动启动 / 代理供给。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quartzwrt_app/native/tailnet.dart';
import 'package:quartzwrt_app/state/app_state.dart';
import 'package:quartzwrt_app/state/tailnet_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeEngine implements TailnetEngineApi {
  bool started = false;
  int startCalls = 0;
  int stopCalls = 0;
  bool startResult = true;
  String? ifaces;
  String backend = 'Stopped';
  String login = '';
  String ip = '';
  String proxy = '127.0.0.1:4567';
  String err = '';

  @override
  bool setInterfaces(String json) {
    ifaces = json;
    return true;
  }

  @override
  bool start(String stateDir, String hostname) {
    startCalls++;
    if (startResult) started = true;
    return startResult;
  }

  @override
  void stop() {
    stopCalls++;
    started = false;
  }

  @override
  String proxyAddr() => started ? proxy : '';

  @override
  String loginUrl() => started ? login : '';

  @override
  String state() => started ? backend : 'Stopped';

  @override
  String selfIp() => started ? ip : '';

  @override
  String lastError() => err;

  @override
  String logs() => '';

  @override
  String version() => 'fake';
}

Future<ProviderContainer> _container(
  _FakeEngine? engine, {
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [
      prefsProvider.overrideWithValue(sp),
      tailnetEngineProvider.overrideWithValue(engine),
      tailnetDirProvider.overrideWithValue(() async => '/tmp/qt-test-tailnet'),
      tailnetInterfacesProvider.overrideWithValue(
        () async => '[{"name":"wlan0","index":2,"addrs":["192.168.1.5"]}]',
      ),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

Future<void> _prefs(List<Future<void>> fs) async {
  for (final f in fs) {
    await f;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('deriveState', () {
    TailnetState d(
      String backend, {
      String login = '',
      String ip = '',
      String proxy = 'p',
      String err = '',
    }) => deriveState(
      enabled: true,
      backendState: backend,
      loginUrl: login,
      selfIp: ip,
      proxyAddr: proxy,
      lastError: err,
    );

    test('backend → phase mapping', () {
      expect(d('Running', ip: '100.1.1.1').phase, TailnetPhase.running);
      expect(
        d('NeedsLogin', login: 'https://x').phase,
        TailnetPhase.needsLogin,
      );
      expect(d('Starting').phase, TailnetPhase.starting);
      expect(d('Error: boom', err: 'boom').phase, TailnetPhase.error);
    });

    test('proxy only exposed when running', () {
      expect(d('Running', ip: '100.1.1.1').proxyAddr, 'p');
      expect(d('NeedsLogin').proxyAddr, '');
      expect(d('Starting').proxyAddr, '');
    });

    test('disabled → stopped', () {
      final st = deriveState(
        enabled: false,
        backendState: '',
        loginUrl: '',
        selfIp: '',
        proxyAddr: '',
        lastError: '',
      );
      expect(st.phase, TailnetPhase.stopped);
      expect(st.enabled, isFalse);
    });
  });

  test('engine unavailable → unavailable phase', () async {
    final c = await _container(null);
    expect(c.read(tailnetProvider).phase, TailnetPhase.unavailable);
    expect(c.read(tailnetProvider).available, isFalse);
  });

  test(
    'enable → start, needsLogin surfaces URL; running exposes proxy',
    () async {
      final engine = _FakeEngine()
        ..backend = 'NeedsLogin'
        ..login = 'https://login.example/a/1';
      final c = await _container(engine);
      await _prefs([c.read(tailnetProvider.notifier).enable()]);
      expect(engine.startCalls, 1);
      expect(engine.ifaces, contains('wlan0')); // 接口表先于 start 注入（Android 必需）
      var st = c.read(tailnetProvider);
      expect(st.phase, TailnetPhase.needsLogin);
      expect(st.loginUrl, 'https://login.example/a/1');
      expect(st.enabled, isTrue);

      engine.backend = 'Running';
      engine.ip = '100.9.9.9';
      c.read(tailnetProvider.notifier).refreshNow();
      st = c.read(tailnetProvider);
      expect(st.phase, TailnetPhase.running);
      expect(st.selfIp, '100.9.9.9');
      expect(st.proxyAddr, '127.0.0.1:4567');

      await c.read(tailnetProvider.notifier).disable();
      expect(engine.stopCalls, 1);
      expect(c.read(tailnetProvider).phase, TailnetPhase.stopped);
      expect(c.read(tailnetProvider).enabled, isFalse);
    },
  );

  test('enabled pref → auto start on build', () async {
    final engine = _FakeEngine()..backend = 'Running';
    final c = await _container(engine, prefs: {kTailnetEnabledKey: true});
    c.read(tailnetProvider); // 触发 build（其中自动启动）
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(engine.startCalls, 1);
    expect(c.read(tailnetProvider).phase, TailnetPhase.running);
  });

  test('start failure → error phase with message', () async {
    final engine = _FakeEngine()
      ..startResult = false
      ..err = 'boom';
    final c = await _container(engine);
    await _prefs([c.read(tailnetProvider.notifier).enable()]);
    final st = c.read(tailnetProvider);
    expect(st.phase, TailnetPhase.error);
    expect(st.message, 'boom');
  });
}
