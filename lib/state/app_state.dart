// 应用状态（Riverpod）：路由器注册表 / 活动路由器 / 客户端与令牌 / 快照轮询 / 外观。
//
// 轮询策略（DESIGN §3）：前台可见 5s；应用退后台停取；回前台立即补一次。
// 降级语义（契约 §5 + WP-5 信封）：连接失败/采集器未运行/需重新配对 → 明确状态，
// 不白屏；有旧数据时保留展示 + 横幅。
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/client.dart';
import '../api/models.dart';
import '../auth/pairing.dart';
import '../auth/token_manager.dart';
import '../discovery/mdns.dart';
import '../storage/store.dart';

/// 启动时由 main 覆盖。
final prefsProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('prefsProvider must be overridden'),
);

final registryProvider = Provider<RouterRegistry>(
  (ref) => RouterRegistry(ref.watch(prefsProvider)),
);

final tokenStoreProvider = Provider<TokenStore>((_) => SecureTokenStore());

/// mDNS 发现函数（可注入——widget 测试用固定结果覆盖）。
final discoverProvider =
    Provider<Future<List<DiscoveredRouter>> Function()>((_) => discoverRouters);

/// 活动路由器（null = 未配对）。
class ActiveRouterNotifier extends Notifier<PairedRouter?> {
  @override
  PairedRouter? build() => ref.watch(registryProvider).active;

  Future<void> select(String id) async {
    await ref.read(registryProvider).setActive(id);
    state = ref.read(registryProvider).byId(id);
  }

  void reload() => state = ref.read(registryProvider).active;
}

final activeRouterProvider =
    NotifierProvider<ActiveRouterNotifier, PairedRouter?>(ActiveRouterNotifier.new);

/// 活动路由器的 API 客户端（严格 pin）。
final apiClientProvider = Provider<QuartzApiClient?>((ref) {
  final r = ref.watch(activeRouterProvider);
  return r == null ? null : clientFor(r);
});

/// 令牌管理（单飞刷新；每次 active 路由器变化重建）。
final tokenManagerProvider = Provider<TokenManager?>((ref) {
  final r = ref.watch(activeRouterProvider);
  final c = ref.watch(apiClientProvider);
  if (r == null || c == null) return null;
  return TokenManager(c, ref.watch(tokenStoreProvider), routerId: r.id);
});

/// 应用前后台可见性（驱动轮询启停）。
class AppVisibleNotifier extends Notifier<bool> {
  late final AppLifecycleListener _listener;

  @override
  bool build() {
    _listener = AppLifecycleListener(
      onStateChange: (s) {
        final visible = s == AppLifecycleState.resumed;
        if (visible != state) state = visible;
      },
    );
    ref.onDispose(_listener.dispose);
    return true; // 冷启默认可见；首帧后由生命周期修正
  }
}

final appVisibleProvider = NotifierProvider<AppVisibleNotifier, bool>(AppVisibleNotifier.new);

/// 快照轮询状态。
enum SnapKind { loading, ok, degraded, unavailable, needRepair }

class SnapshotState {
  const SnapshotState({
    this.kind = SnapKind.loading,
    this.data,
    this.errorCode,
    this.errorMessage,
    this.lastOkAt,
  });

  final SnapKind kind;
  final Snapshot? data;
  final String? errorCode;
  final String? errorMessage;
  final DateTime? lastOkAt;

  SnapshotState copyWith({
    SnapKind? kind,
    Snapshot? data,
    String? errorCode,
    String? errorMessage,
    DateTime? lastOkAt,
    bool clearError = false,
  }) =>
      SnapshotState(
        kind: kind ?? this.kind,
        data: clearError ? data : (data ?? this.data),
        errorCode: clearError ? null : (errorCode ?? this.errorCode),
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        lastOkAt: lastOkAt ?? this.lastOkAt,
      );
}

const kPollInterval = Duration(seconds: 5);

class SnapshotController extends Notifier<SnapshotState> {
  Timer? _timer;
  bool _busy = false;

  @override
  SnapshotState build() {
    ref.onDispose(() => _timer?.cancel());
    // 可见性/路由器变化 → 重排轮询
    ref.listen(appVisibleProvider, (_, visible) {
      if (visible) {
        _pollNow();
        _scheduleNext();
      } else {
        _timer?.cancel();
      }
    });
    ref.listen(activeRouterProvider, (_, _) {
      state = const SnapshotState();
      _restart();
    });
    _restart();
    return const SnapshotState();
  }

  void _restart() {
    _timer?.cancel();
    _pollNow();
    _scheduleNext();
  }

  void _scheduleNext() {
    _timer?.cancel();
    if (!ref.read(appVisibleProvider)) return;
    _timer = Timer(kPollInterval, () {
      _pollNow();
      _scheduleNext();
    });
  }

  /// 立即取一次（下拉刷新也用这个）。
  Future<void> refreshNow() => _pollNow();

  Future<void> _pollNow() async {
    if (_busy) return;
    _busy = true;
    final tm = ref.read(tokenManagerProvider);
    try {
      if (tm == null) {
        state = const SnapshotState(kind: SnapKind.needRepair, errorCode: 'no_router');
        return;
      }
      final r = await tm.call('status');
      if (r.ok) {
        final snap = Snapshot.parse(r.data['snapshot']);
        if (snap == null) {
          state = SnapshotState(
            kind: SnapKind.degraded,
            data: state.data,
            errorCode: 'corrupt',
          );
        } else {
          state = SnapshotState(kind: SnapKind.ok, data: snap, lastOkAt: DateTime.now());
        }
        return;
      }
      final code = r.error?.code ?? 'transport';
      final kind = switch (code) {
        'device_revoked' || 'token_invalid' => SnapKind.needRepair,
        'data_unavailable' => SnapKind.unavailable,
        _ => state.data == null ? SnapKind.unavailable : SnapKind.degraded,
      };
      state = SnapshotState(
        kind: kind,
        data: state.data,
        errorCode: code,
        errorMessage: r.error?.message,
        lastOkAt: state.lastOkAt,
      );
    } on ApiAuthException catch (e) {
      state = SnapshotState(kind: SnapKind.needRepair, errorCode: e.code);
    } on ApiException catch (e) {
      state = SnapshotState(
        kind: state.data == null ? SnapKind.unavailable : SnapKind.degraded,
        data: state.data,
        errorCode: e.error.code,
        lastOkAt: state.lastOkAt,
      );
    } finally {
      _busy = false;
    }
  }
}

final snapshotProvider =
    NotifierProvider<SnapshotController, SnapshotState>(SnapshotController.new);

// ---- 外观（应用设置；持久化） ----

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _k = 'qz.theme_mode';

  @override
  ThemeMode build() {
    final v = ref.watch(prefsProvider).getString(_k);
    return switch (v) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
  }

  Future<void> set(ThemeMode m) async {
    await ref.read(prefsProvider).setString(_k, switch (m) {
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
    });
    state = m;
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class LocaleNotifier extends Notifier<Locale?> {
  static const _k = 'qz.locale';

  @override
  Locale? build() {
    final v = ref.watch(prefsProvider).getString(_k);
    return (v == null || v.isEmpty) ? null : Locale(v);
  }

  Future<void> set(Locale? l) async {
    final p = ref.read(prefsProvider);
    if (l == null) {
      await p.remove(_k);
    } else {
      await p.setString(_k, l.languageCode);
    }
    state = l;
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);
