// 内嵌直连（tsnet）状态管理：开关持久化 / 自动启动 / 状态轮询 / 代理地址供给。
//
// 设计（docs/DESIGN.md §7 内嵌直连）：默认关闭；开启后节点常驻（随 App 生命周期），
// 远程端点优先经本地 CONNECT 代理连接（免手机端 Tailscale 客户端），失败回退直连。
import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../native/tailnet.dart';
import 'app_state.dart';

/// 引擎实例（缺失 = 此构建未打包；UI 显式降级）。
final tailnetEngineProvider = Provider<TailnetEngineApi?>(
  (ref) => FfiTailnetEngine.open(),
);

/// 状态目录提供者（单测注入临时目录——path_provider 在测试环境不可用）。
final tailnetDirProvider = Provider<Future<String> Function()>(
  (_) => defaultTailnetDir,
);

/// 接口表采集（单测注入固定 JSON；真机走 dart:io getifaddrs）。
final tailnetInterfacesProvider = Provider<Future<String> Function()>(
  (_) => collectInterfacesJson,
);

Future<String> defaultTailnetDir() async {
  final base = await getApplicationSupportDirectory();
  final dir = Directory('${base.path}/tailnet');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir.path;
}

const kTailnetEnabledKey = 'qz.tailnet.enabled';

class TailnetController extends Notifier<TailnetState> {
  static const pollInterval = Duration(seconds: 3);
  Timer? _timer;
  bool _enabled = false;
  bool _starting = false;

  @override
  TailnetState build() {
    final engine = ref.watch(tailnetEngineProvider);
    _enabled = ref.watch(prefsProvider).getBool(kTailnetEnabledKey) ?? false;
    ref.onDispose(() => _timer?.cancel());
    ref.listen(appVisibleProvider, (_, visible) {
      if (visible && _enabled) _refresh();
    });
    if (engine == null) return TailnetState.unavailableState;
    if (_enabled) {
      unawaited(_start());
    }
    return TailnetState(
      phase: _enabled ? TailnetPhase.starting : TailnetPhase.stopped,
      enabled: _enabled,
    );
  }

  /// 开启内嵌直连（持久化；自动启动节点）。
  Future<void> enable() async {
    if (_enabled) return;
    _enabled = true;
    await ref.read(prefsProvider).setBool(kTailnetEnabledKey, true);
    await _start();
  }

  /// 关闭（停节点与代理；磁盘状态保留，重新开启快速恢复）。
  Future<void> disable() async {
    if (!_enabled) return;
    _enabled = false;
    await ref.read(prefsProvider).setBool(kTailnetEnabledKey, false);
    _timer?.cancel();
    _timer = null;
    ref.read(tailnetEngineProvider)?.stop();
    state = TailnetState(
      phase: ref.read(tailnetEngineProvider) == null
          ? TailnetPhase.unavailable
          : TailnetPhase.stopped,
    );
  }

  /// 立即刷新一次状态（UI 下拉/进入页面）。
  void refreshNow() => _refresh();

  Future<void> _start() async {
    final engine = ref.read(tailnetEngineProvider);
    if (engine == null || _starting) return;
    _starting = true;
    state = const TailnetState(phase: TailnetPhase.starting, enabled: true);
    try {
      final dir = await ref.read(tailnetDirProvider)();
      // Android 禁 netlink：先把接口表交给引擎（netmon 获取器），再启动节点。
      try {
        engine.setInterfaces(await ref.read(tailnetInterfacesProvider)());
      } on Exception {
        // 采集失败不阻断：非 Android 平台引擎可自行枚举。
      }
      final ok = engine.start(dir, 'quartz-app');
      if (!ok) {
        state = TailnetState(
          phase: TailnetPhase.error,
          enabled: true,
          message: engine.lastError(),
        );
        return;
      }
      _refresh();
      _schedule();
    } finally {
      _starting = false;
    }
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer.periodic(pollInterval, (_) => _refresh());
  }

  void _refresh() {
    final engine = ref.read(tailnetEngineProvider);
    if (engine == null || !_enabled) return;
    final logs = engine.logs();
    state = deriveState(
      enabled: true,
      backendState: engine.state(),
      loginUrl: engine.loginUrl(),
      selfIp: engine.selfIp(),
      proxyAddr: engine.proxyAddr(),
      lastError: engine.lastError(),
      logs: logs.length > 2000 ? logs.substring(logs.length - 2000) : logs,
    );
  }
}

final tailnetProvider = NotifierProvider<TailnetController, TailnetState>(
  TailnetController.new,
);

/// 远程端点可用的本地代理地址（空串 = 不可用/未开启/未连接）。
String tailnetProxyFor(Ref ref) => proxyOf(ref.read(tailnetProvider));

/// 从状态取代理地址（widget 侧用 ref.read(tailnetProvider) 后调用）。
String proxyOf(TailnetState st) =>
    st.phase == TailnetPhase.running ? st.proxyAddr : '';
