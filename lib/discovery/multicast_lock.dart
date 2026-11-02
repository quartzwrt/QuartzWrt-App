// Android 真机 mDNS：仅声明 CHANGE_WIFI_MULTICAST_STATE 权限不够。
//
// Android 的 Wi-Fi 栈默认过滤掉目标不是本机的组播包，必须持有
// WifiManager.MulticastLock 才能收到 mDNS（224.0.0.251:5353）。
// 模拟器/有线环境与 VM 测试不暴露此问题，因此这里在每次扫描期间通过
// 原生通道持有锁；非 Android 平台与测试环境为 no-op。
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('quartz/multicast');

/// 扫描期间持有 Android Wi-Fi MulticastLock（引用计数，可并发扫描）。
class MulticastLock {
  MulticastLock._();

  static int _refs = 0;
  static bool _held = false;

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> acquire() async {
    if (!_supported) return;
    _refs++;
    if (_held) return;
    try {
      await _channel.invokeMethod<void>('acquire');
      _held = true;
    } on MissingPluginException {
      // 单元测试/未注册通道：无需锁。
    } on PlatformException catch (e) {
      debugPrint('MulticastLock.acquire failed: ${e.code} ${e.message}');
    }
  }

  static Future<void> release() async {
    if (!_supported) return;
    if (_refs == 0) return;
    _refs--;
    if (_refs > 0 || !_held) return;
    _held = false;
    try {
      await _channel.invokeMethod<void>('release');
    } on MissingPluginException {
      // ignore
    } on PlatformException catch (e) {
      debugPrint('MulticastLock.release failed: ${e.code} ${e.message}');
    }
  }
}
