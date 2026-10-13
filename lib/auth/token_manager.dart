// 令牌生命周期管理（DESIGN §4，硬要求）：
//
// - access_token 仅内存；refresh_token 持久在安全存储（按路由器隔离）；
// - **单飞刷新队列**：并发调用只触发一次 refresh（WP-5 的旋转 + 复用检测
//   使并发刷新会自触发吊销——必须串行化）；
// - token_expired → 刷新一次并重放原调用；device_revoked/token_invalid →
//   清本地凭据并抛出 [ApiAuthException]（上层引导重新配对）。
import '../api/client.dart';
import '../api/envelope.dart';
import '../api/models.dart';
import '../storage/store.dart';

/// 认证类失败（需要用户重新配对）。
class ApiAuthException implements Exception {
  ApiAuthException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'ApiAuthException($code: $message)';
}

class TokenManager {
  TokenManager(
    this._t,
    this._store, {
    required this.routerId,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ApiTransport _t;
  final TokenStore _store;
  final String routerId;
  final DateTime Function() _now;

  String? _access;
  int _accessExp = 0; // epoch 秒
  Future<String>? _inflight;

  /// 刷新提前量（秒）：过期前 30s 视作需要刷新。
  static const int refreshMargin = 30;

  bool get hasSession => _access != null;

  /// 登录成功后注入令牌（refresh 持久化）。
  Future<void> seed(Tokens tokens, String refreshToken) async {
    _access = tokens.accessToken;
    _accessExp = tokens.accessExp;
    await _store.writeRefresh(routerId, refreshToken);
  }

  /// 用持久化的 refresh 恢复会话（App 冷启）。
  Future<bool> restore() async {
    if (await _store.readRefresh(routerId) == null) return false;
    try {
      await ensureAccess();
      return true;
    } on ApiAuthException {
      return false;
    } on ApiException {
      return false;
    }
  }

  /// 返回有效 access_token（必要时单飞刷新）。
  Future<String> ensureAccess() {
    final nowSec = _now().millisecondsSinceEpoch ~/ 1000;
    final cur = _access;
    if (cur != null && _accessExp - refreshMargin > nowSec) {
      return Future.value(cur);
    }
    return _refreshSingleFlight();
  }

  /// 带认证调用：注入 access；`token_expired` → 单飞刷新后重放一次。
  Future<ApiResult> call(String method, [Map<String, dynamic>? args]) async {
    final token = await ensureAccess();
    var r = await _t.call(method, {...?args, 'access_token': token});
    if (!r.ok && r.error?.code == 'token_expired') {
      final fresh = await _refreshSingleFlight(force: true);
      r = await _t.call(method, {...?args, 'access_token': fresh});
    }
    return r;
  }

  Future<String> _refreshSingleFlight({bool force = false}) {
    if (!force && _inflight != null) return _inflight!;
    if (force) _inflight = null;
    _inflight ??= _doRefresh().whenComplete(() => _inflight = null);
    return _inflight!;
  }

  Future<String> _doRefresh() async {
    final refresh = await _store.readRefresh(routerId);
    if (refresh == null || refresh.isEmpty) {
      throw ApiAuthException('no_session', 'not paired');
    }
    final r = await _t.call('refresh', {'device_id': routerId, 'refresh_token': refresh});
    if (!r.ok) {
      final code = r.error?.code ?? 'transport';
      final fatal = code == 'device_revoked' ||
          code == 'token_invalid' ||
          code == 'device_unknown';
      if (fatal) {
        await _store.clearRefresh(routerId);
        _access = null;
        _accessExp = 0;
      }
      throw fatal
          ? ApiAuthException(code, r.error?.message ?? '')
          : ApiException(r.error ?? const ApiError('unknown', ''));
    }
    final t = Tokens.fromPayload(r.data);
    if (t.accessToken.isEmpty || t.refreshToken.isEmpty) {
      throw ApiAuthException('token_invalid', 'malformed refresh response');
    }
    await seed(t, t.refreshToken); // 旋转：持久化新 refresh
    return t.accessToken;
  }

  /// 登出（成功后清本地凭据；失败也清——本地不再可用）。
  Future<void> logout() async {
    final refresh = await _store.readRefresh(routerId);
    if (refresh != null) {
      try {
        await _t.call('logout', {'device_id': routerId, 'refresh_token': refresh});
      } catch (_) {}
    }
    _access = null;
    _accessExp = 0;
    await _store.clearRefresh(routerId);
  }
}

/// 一般 API 失败（非认证类）。
class ApiException implements Exception {
  ApiException(this.error);

  final ApiError error;

  @override
  String toString() => 'ApiException(${error.code}: ${error.message})';
}
