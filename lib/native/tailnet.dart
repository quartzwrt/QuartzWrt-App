// 内嵌 tailnet 引擎的 Dart 侧封装（FFI → libtailnet.so；native/tailnet/ 构建）。
//
// 引擎在 App 进程内以 tsnet（userspace）起一个 tailnet 节点 + 127.0.0.1 CONNECT
// 代理；本层负责：动态库探测（缺失优雅降级）、生命周期、状态读取。
// 数据结构与状态机在 [TailnetState]/[TailnetPhase]；轮询与持久化在 state 层。
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

/// 引擎可用性/生命周期状态。
enum TailnetPhase {
  /// 此构建未打包 libtailnet.so（如未跑 scripts/build-native.sh 的构建）。
  unavailable,
  stopped,
  starting,

  /// 等待用户在浏览器完成 tailnet 登录（loginUrl 非空）。
  needsLogin,
  running,
  error,
}

class TailnetState {
  const TailnetState({
    required this.phase,
    this.enabled = false,
    this.loginUrl = '',
    this.selfIp = '',
    this.proxyAddr = '',
    this.message = '',
    this.logs = '',
  });

  final TailnetPhase phase;

  /// 用户开关（持久化偏好；phase 反映引擎实况）。
  final bool enabled;
  final String loginUrl;
  final String selfIp;

  /// 本地 CONNECT 代理地址（仅 running 时有效）。
  final String proxyAddr;
  final String message;

  /// 引擎最近日志（末若干行；排障展示用）。
  final String logs;

  bool get available => phase != TailnetPhase.unavailable;
  bool get active =>
      phase == TailnetPhase.starting ||
      phase == TailnetPhase.needsLogin ||
      phase == TailnetPhase.running;

  static const unavailableState = TailnetState(phase: TailnetPhase.unavailable);
}

/// 引擎接口（测试注入假实现）。
abstract interface class TailnetEngineApi {
  /// Android：Start 前注入本机接口表（netlink 被禁时供 netmon 使用）。
  bool setInterfaces(String json);
  bool start(String stateDir, String hostname);
  void stop();
  String proxyAddr();
  String loginUrl();
  String state();
  String selfIp();
  String lastError();
  String logs();
  String version();
}

/// libtailnet.so 的真实实现。
class FfiTailnetEngine implements TailnetEngineApi {
  FfiTailnetEngine._(this._lib);

  final DynamicLibrary _lib;

  /// 尝试加载动态库；失败（未打包/平台不支持）返回 null。
  static FfiTailnetEngine? open() {
    try {
      return FfiTailnetEngine._(DynamicLibrary.open('libtailnet.so'));
    } on Object {
      return null;
    }
  }

  late final _setIfaces = _lib
      .lookupFunction<
        Int32 Function(Pointer<Utf8>),
        int Function(Pointer<Utf8>)
      >('TailnetSetInterfaces');
  late final _start = _lib
      .lookupFunction<
        Int32 Function(Pointer<Utf8>, Pointer<Utf8>),
        int Function(Pointer<Utf8>, Pointer<Utf8>)
      >('TailnetStart');
  late final _stop = _lib.lookupFunction<Void Function(), void Function()>(
    'TailnetStop',
  );
  late final _proxy = _str('TailnetProxyAddr');
  late final _login = _str('TailnetLoginURL');
  late final _state = _str('TailnetState');
  late final _selfIp = _str('TailnetSelfIP');
  late final _lastError = _str('TailnetLastError');
  late final _logs = _str('TailnetLogs');
  late final _version = _str('TailnetVersion');

  String Function() _str(String name) {
    final f = _lib
        .lookupFunction<Pointer<Utf8> Function(), Pointer<Utf8> Function()>(
          name,
        );
    return () {
      final p = f();
      if (p == nullptr) return '';
      return p.toDartString();
    };
  }

  @override
  bool setInterfaces(String json) {
    final j = json.toNativeUtf8();
    try {
      return _setIfaces(j) == 0;
    } finally {
      malloc.free(j);
    }
  }

  @override
  bool start(String stateDir, String hostname) {
    final d = stateDir.toNativeUtf8();
    final h = hostname.toNativeUtf8();
    try {
      return _start(d, h) == 0;
    } finally {
      malloc.free(d);
      malloc.free(h);
    }
  }

  @override
  void stop() => _stop();

  @override
  String proxyAddr() => _proxy();

  @override
  String loginUrl() => _login();

  @override
  String state() => _state();

  @override
  String selfIp() => _selfIp();

  @override
  String lastError() => _lastError();

  @override
  String logs() => _logs();

  @override
  String version() => _version();
}

/// 由引擎原始串映射状态（[TailnetEngineApi] 之外的纯函数，便于测试）。
TailnetState deriveState({
  required bool enabled,
  required String backendState,
  required String loginUrl,
  required String selfIp,
  required String proxyAddr,
  required String lastError,
  String logs = '',
}) {
  if (!enabled) {
    return TailnetState(
      phase: backendState.isEmpty || backendState == 'Stopped'
          ? TailnetPhase.stopped
          : TailnetPhase.error,
      message: lastError,
    );
  }
  final phase = switch (backendState) {
    'Running' => TailnetPhase.running,
    'NeedsLogin' => TailnetPhase.needsLogin,
    'Starting' || 'Stopped' || '' => TailnetPhase.starting,
    _ =>
      backendState.startsWith('Error')
          ? TailnetPhase.error
          : TailnetPhase.starting,
  };
  return TailnetState(
    phase: phase,
    enabled: true,
    loginUrl: loginUrl,
    selfIp: selfIp,
    proxyAddr: phase == TailnetPhase.running ? proxyAddr : '',
    message: lastError,
    logs: logs,
  );
}

/// 采集本机接口表（dart:io 走 getifaddrs，Android 应用可用；Go 侧补齐
/// MTU/MAC/状态与前缀长度）。仅取 name/index/地址（去 zone 与前缀）。
Future<String> collectInterfacesJson() async {
  final list = await NetworkInterface.list(
    includeLinkLocal: true,
    type: InternetAddressType.any,
  );
  final out = <Map<String, Object>>[];
  for (final ni in list) {
    out.add({
      'name': ni.name,
      'index': ni.index,
      'addrs': ni.addresses.map((a) => a.address.split('%').first).toList(),
    });
  }
  return jsonEncode(out);
}
