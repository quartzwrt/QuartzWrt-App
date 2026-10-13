// 动作能力注册表（DESIGN §4.2）——页面只渲染注册表，不写死单项。
//
// 现有动作 = WP-5 白名单（service.start/stop/restart、system.reboot、
// docker.container.*）。WP-5/WP-8 新增动作 → 此处加一条 [ActionSpec]。
import 'package:flutter/material.dart';

import '../../api/envelope.dart';
import '../../auth/token_manager.dart';

/// 动作执行结果（UI 反馈用）。
class ActionResult {
  const ActionResult(this.ok, this.message);

  final bool ok;
  final String message;
}

class ActionSpec {
  const ActionSpec({
    required this.id,
    required this.label,
    this.danger = false,
    this.confirmTitle,
    this.confirmBody,
    this.argsOf,
  });

  final String id;
  final String label;
  final bool danger;
  final String? Function(BuildContext)? confirmTitle;
  final String? Function(BuildContext)? confirmBody;

  /// 参数构造（如 service 的 name）。
  final Map<String, dynamic> Function()? argsOf;
}

/// 启动一个服务（参数 name）。
ActionSpec serviceAction({
  required String op, // start|stop|restart
  required String label,
  required String name,
  bool danger = false,
  String? Function(BuildContext)? confirmTitle,
  String? Function(BuildContext)? confirmBody,
}) =>
    ActionSpec(
      id: 'service.$op',
      label: label,
      danger: danger,
      confirmTitle: confirmTitle,
      confirmBody: confirmBody,
      argsOf: () => {'name': name},
    );

/// 执行（确认层由调用方按 [ActionSpec.danger]/confirm 文案先行展示）。
Future<ActionResult> runAction(TokenManager tm, ActionSpec spec) async {
  final r = await tm.call('action', {'action': spec.id, 'args': spec.argsOf?.call() ?? const {}});
  if (r.ok) {
    return ActionResult(true, spec.label);
  }
  final err = r.error ?? const ApiError('unknown', '');
  final detail = err.detail?.isNotEmpty == true ? err.detail! : err.message;
  return ActionResult(false, detail.isEmpty ? err.code : detail);
}
