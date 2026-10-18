// 蜂窝（qmodem）动作与页面级读：经 app-api `action` 方法的 `qmodem.*` 转发条目
// （W6.12 设计稿 §3；app-api 侧逐条注册 + 两档校验）。
//
// 读面规则：概览/摘要走快照（§3.9），**页面级读**（AT 端口与预置命令、设置回显、
// 能力声明）走 `action` 的读条目——返回值在 `result.data`。
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/token_manager.dart';
import '../../state/app_state.dart';

/// 一条 qmodem 读条目的结果（成功时为已解析 JSON，失败为错误文案）。
class QmodemReadResult {
  const QmodemReadResult(this.ok, {this.data, this.message = ''});

  final bool ok;
  final dynamic data;
  final String message;

  Map<String, dynamic> get map => data is Map<String, dynamic> ? data as Map<String, dynamic> : const {};
}

/// 调用一条转发条目（写或读）：统一 `{action, args}` 信封。
///
/// - [section]：模组 uci section（`qmodem.<section>`）；无参条目（tty_ports）可不传
/// - [args]：条目声明的其他字段（如 `params` 的 JSON 字符串）
class QmodemClient {
  const QmodemClient(this._tm);

  final TokenManager _tm;

  Future<QmodemReadResult> call(String id, {String? section, Map<String, String> args = const {}}) async {
    final payload = <String, dynamic>{...args};
    if (section != null && section.isNotEmpty) payload['config_section'] = section;
    final r = await _tm.call('action', {'action': id, 'args': payload});
    if (!r.ok) {
      final err = r.error;
      final detail = (err?.detail?.isNotEmpty ?? false) ? err!.detail! : (err?.message ?? '');
      return QmodemReadResult(false, message: detail.isEmpty ? (err?.code ?? 'unknown') : detail);
    }
    // 信封 data = `{action, result:{data}}`（app-api §4.2）
    final result = r.data['result'];
    if (result is Map<String, dynamic>) return QmodemReadResult(true, data: result['data']);
    return const QmodemReadResult(true, data: null);
  }
}

/// 当前令牌管理器（未配对时为 null）。
final qmodemClientProvider = Provider<QmodemClient?>((ref) {
  final tm = ref.watch(tokenManagerProvider);
  return tm == null ? null : QmodemClient(tm);
});
