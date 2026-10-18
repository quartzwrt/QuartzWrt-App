// LuCI rpcd 对象的页面级读/动作（经 app-api `action` 的 `luci.*` 转发条目）。
//
// 目前用到：启动项（getInitList / setInitAction）与时区列表（getTimezones）。
// 与网页端同源；不暴露任意 luci 方法（条目在 app-api `internal/ubusfwd` 逐条注册）。
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/token_manager.dart';
import '../state/app_state.dart';
import 'config.dart';
import 'envelope.dart';

class LuciResult {
  const LuciResult(this.ok, {this.data, this.error});

  final bool ok;
  final dynamic data;
  final ApiError? error;

  Map<String, dynamic> get map => data is Map<String, dynamic> ? data as Map<String, dynamic> : const {};

  String get message => apiErrorText(error);
}

class LuciClient {
  const LuciClient(this._tm);

  final TokenManager _tm;

  Future<LuciResult> _call(String id, [Map<String, String> args = const {}]) async {
    final r = await _tm.call('action', {'action': id, 'args': args});
    if (!r.ok) return LuciResult(false, error: r.error);
    // 信封 data = `{action, result:{data}}`（与 qmodem 转发条目同形）。
    final result = r.data['result'];
    if (result is Map<String, dynamic>) return LuciResult(true, data: result['data']);
    return const LuciResult(true, data: null);
  }

  Future<LuciResult> initList() => _call('luci.init_list');

  Future<LuciResult> initAction(String name, String action) =>
      _call('luci.init_action', {'name': name, 'action': action});

  Future<LuciResult> timezones() => _call('luci.timezones');
}

final luciClientProvider = Provider<LuciClient?>((ref) {
  final tm = ref.watch(tokenManagerProvider);
  return tm == null ? null : LuciClient(tm);
});
