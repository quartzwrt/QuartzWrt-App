// 配置面客户端（W6.10「路由器 tab」；app-api `config.*` 方法族）。
//
// 契约（交接文档 W6.10-ROUTER-TAB-HANDOFF §4）：
// - read：value 三种形状（全量 `{section:{option:value}}` / 单节 `{option:value}` /
//   单选项标量；敏感项为 `"__masked__"`）；
// - write：**暂存**（返回 changes），必须 apply 才落盘；
// - apply：`{rollback:true,timeout:90}` 武装回滚窗口，未 confirm 自动回滚；
// - confirm：保留；rollback：立即回滚（**不是 revert**——revert 只丢弃暂存，
//   apply 后调用不会撤销已生效配置，VM 实测）。
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/token_manager.dart';
import '../state/app_state.dart';
import 'envelope.dart';

class ConfigReadResult {
  const ConfigReadResult(this.ok, {this.value, this.error});

  final bool ok;
  final dynamic value;
  final ApiError? error;

  Map<String, dynamic> get map =>
      value is Map<String, dynamic> ? value as Map<String, dynamic> : const {};

  String get message => apiErrorText(error);
}

/// `config.*` 调用（认证由 TokenManager 注入 access_token）。
class ConfigClient {
  const ConfigClient(this._tm);

  final TokenManager _tm;

  Future<ConfigReadResult> read(
    String config, {
    String? section,
    String? option,
  }) async {
    final r = await _tm.call('config.read', {
      'config': config,
      if (section != null && section.isNotEmpty) 'section': section,
      if (option != null && option.isNotEmpty) 'option': option,
    });
    if (!r.ok) return ConfigReadResult(false, error: r.error);
    return ConfigReadResult(true, value: r.data['value']);
  }

  Future<ApiResult> write(
    String config,
    String section,
    String option,
    dynamic value,
  ) => _tm.call('config.write', {
    'config': config,
    'section': section,
    'option': option,
    'value': value,
  });

  Future<ApiResult> changes(String config) =>
      _tm.call('config.changes', {'config': config});

  /// 丢弃**暂存**改动（仅在 apply 之前可用；apply 后请用 [rollback]）。
  Future<ApiResult> revert(String config) =>
      _tm.call('config.revert', {'config': config});

  Future<ApiResult> apply({bool rollback = true, int timeout = 90}) =>
      _tm.call('config.apply', {'rollback': rollback, 'timeout': timeout});

  Future<ApiResult> confirm() => _tm.call('config.confirm');

  /// 立即回滚已 apply 但未 confirm 的改动。
  Future<ApiResult> rollback() => _tm.call('config.rollback');

  /// 新增 section（暂存；values 只收注册字段；W6.11 静态租约等）。
  Future<ApiResult> add(
    String config,
    String sectionType,
    Map<String, dynamic> values,
  ) => _tm.call('config.add', {
    'config': config,
    'section_type': sectionType,
    'values': values,
  });

  /// 删除可删除类型的 section（暂存；如 dhcp host）。
  Future<ApiResult> delete(String config, String section) =>
      _tm.call('config.delete', {'config': config, 'section': section});
}

/// 取错误里最有信息量的一段（detail 优先于 message）。
String apiErrorText(ApiError? err) {
  if (err == null) return 'unknown';
  final detail = (err.detail != null && err.detail!.isNotEmpty)
      ? err.detail!
      : err.message;
  return detail.isEmpty ? err.code : detail;
}

final configClientProvider = Provider<ConfigClient?>((ref) {
  final tm = ref.watch(tokenManagerProvider);
  return tm == null ? null : ConfigClient(tm);
});
