// bandix 设置类对话框（WP-6 L2 富化行的动作条目；WP-5「ubus 转发项」链路）。
//
// 当前值来源：`action bandix.limits`（唯一读条目——限速/白名单/配额配置状态不在
// daemon 快照内）；写动作经 `bandix.*` 转发项（app-api DESIGN §5.1）。
// 单位：契约 Byte/s；界面按 KB/s（=1024）换算显示（bridge DESIGN §1.6 同口径）。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/token_manager.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/quartz.dart';
import '../../state/app_state.dart';

/// 取当前限速/白名单/配额聚合（失败 → null，调用方降级展示）。
Future<Map<String, dynamic>?> fetchBandixLimits(TokenManager tm) async {
  final r = await tm.call('action', {'action': 'bandix.limits'});
  if (!r.ok) return null;
  final res = r.data['result'];
  if (res is! Map<String, dynamic>) return null;
  final d = res['data'];
  return d is Map<String, dynamic> ? d : <String, dynamic>{};
}

/// 执行一条 bandix 转发动作；返回 null = 成功，否则错误文本。
Future<String?> runBandixAction(
  TokenManager tm,
  String action,
  Map<String, dynamic> args,
) async {
  final r = await tm.call('action', {'action': action, 'args': args});
  if (r.ok) return null;
  final err = r.error;
  final detail = err?.detail;
  if (detail != null && detail.isNotEmpty) return detail;
  return err?.message ?? 'failed';
}

void _snack(BuildContext context, AppL10n l10n, String? err) {
  showQzToast(context, err == null ? l10n.actionDone : l10n.actionFailed(err));
}

/// 限速默认值对话框（wan_rx/wan_tx，KB/s 显示；0 = 不限）。
Future<void> showBandixLimitSheet(BuildContext context, WidgetRef ref) async {
  final l10n = AppL10n.of(context);
  final tm = ref.read(tokenManagerProvider);
  if (tm == null) return;
  final limits = await fetchBandixLimits(tm);
  if (!context.mounted) return;
  final wl =
      (limits?['whitelist'] as Map<String, dynamic>?) ??
      const <String, dynamic>{};
  final rxCtrl = TextEditingController(
    text:
        '${((wl['default_wan_rx_rate_limit'] as num?)?.toInt() ?? 0) ~/ 1024}',
  );
  final txCtrl = TextEditingController(
    text:
        '${((wl['default_wan_tx_rate_limit'] as num?)?.toInt() ?? 0) ~/ 1024}',
  );
  var busy = false;
  String? error;

  await showQzSheet<void>(
    context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 18,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.bandixLimitTitle,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.bandixLimitBody,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(ctx).colorScheme.onSurface
                    .withValues(alpha: .55),
              ),
            ),
            if (limits == null) ...[
              const SizedBox(height: 10),
              Text(
                l10n.bandixLimitsUnavailable,
                style: TextStyle(fontSize: 12.5, color: QuartzColors.warn),
              ),
            ],
            const SizedBox(height: 12),
            QzField(
              controller: rxCtrl,
              label: l10n.bandixLimitRx,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            QzField(
              controller: txCtrl,
              label: l10n.bandixLimitTx,
              keyboardType: TextInputType.number,
            ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(
                error!,
                style: TextStyle(fontSize: 12.5, color: QuartzColors.err),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: QzLegacyButton(
                    kind: QzButtonKind.plain,
                    onPressed: busy ? null : () => Navigator.of(ctx).pop(),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: QzLegacyButton(
                    onPressed: busy
                        ? null
                        : () async {
                            final rx = int.tryParse(rxCtrl.text.trim());
                            final tx = int.tryParse(txCtrl.text.trim());
                            if (rx == null || tx == null || rx < 0 || tx < 0) {
                              setSheet(() => error = l10n.bandixInvalidNumber);
                              return;
                            }
                            setSheet(() {
                              busy = true;
                              error = null;
                            });
                            final err = await runBandixAction(
                              tm,
                              'bandix.limit_default_set',
                              {
                                'wan_rx_rate_limit': rx * 1024,
                                'wan_tx_rate_limit': tx * 1024,
                              },
                            );
                            if (!ctx.mounted) return;
                            Navigator.of(ctx).pop();
                            _snack(context, l10n, err);
                          },
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// 白名单对话框：开关 + 列表（删除）+ 添加（MAC）。
Future<void> showBandixWhitelistSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final l10n = AppL10n.of(context);
  final tm = ref.read(tokenManagerProvider);
  if (tm == null) return;
  final macCtrl = TextEditingController();

  await showQzSheet<void>(
    context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) {
        var busy = false;
        var loaded = false;
        bool enabled = false;
        var macs = <String>[];
        String? error;

        Future<void> reload() async {
          final limits = await fetchBandixLimits(tm);
          final wl =
              (limits?['whitelist'] as Map<String, dynamic>?) ??
              const <String, dynamic>{};
          final list =
              (wl['macs'] as List?)?.whereType<String>().toList() ?? <String>[];
          setSheet(() {
            enabled = wl['enabled'] == true;
            macs = list;
            loaded = true;
            if (limits == null) error = l10n.bandixLimitsUnavailable;
          });
        }

        Future<void> act(String action, Map<String, dynamic> args) async {
          setSheet(() {
            busy = true;
            error = null;
          });
          final err = await runBandixAction(tm, action, args);
          await reload();
          setSheet(() {
            busy = false;
            error = err;
          });
        }

        if (!loaded) {
          loaded = true;
          reload();
        }

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 18,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.bandixWhitelistTitle,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.bandixWhitelistBody,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(ctx).colorScheme.onSurface
                      .withValues(alpha: .55),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.bandixWhitelistEnabled,
                      style: QuartzType.body.copyWith(
                        color: QuartzTokens.of(ctx).text,
                      ),
                    ),
                  ),
                  QzToggle(
                    value: enabled,
                    semanticLabel: l10n.bandixWhitelistEnabled,
                    onChanged: busy
                        ? null
                        : (v) => act('bandix.whitelist_enabled', {
                            'enabled': v ? 1 : 0,
                          }),
                  ),
                ],
              ),
              for (final mac in macs)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        mac,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    ),
                    QzLegacyIconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: busy
                          ? null
                          : () => act('bandix.whitelist_delete', {'mac': mac}),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: QzField(
                      controller: macCtrl,
                      label: 'MAC',
                      hint: 'aa:bb:cc:dd:ee:ff',
                    ),
                  ),
                  const SizedBox(width: 10),
                  QzLegacyButton.tonal(
                    onPressed: busy
                        ? null
                        : () {
                            final mac = macCtrl.text.trim();
                            if (mac.isEmpty) return;
                            macCtrl.clear();
                            act('bandix.whitelist_add', {'mac': mac});
                          },
                    child: Text(l10n.bandixAdd),
                  ),
                ],
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(
                  error!,
                  style: TextStyle(fontSize: 12.5, color: QuartzColors.err),
                ),
              ],
            ],
          ),
        );
      },
    ),
  );
}

/// 主机名绑定对话框：从在线设备快选 MAC + 主机名输入（空 = 清除绑定）。
Future<void> showBandixHostnameSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final l10n = AppL10n.of(context);
  final tm = ref.read(tokenManagerProvider);
  if (tm == null) return;
  final snap = ref.read(snapshotProvider).data;
  final macCtrl = TextEditingController();
  final hostCtrl = TextEditingController();
  var busy = false;
  String? error;

  await showQzSheet<void>(
    context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 18,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.bandixHostnameTitle,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.bandixHostnameBody,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(ctx).colorScheme.onSurface
                    .withValues(alpha: .55),
              ),
            ),
            const SizedBox(height: 8),
            if (snap != null && snap.clientItems.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final item in snap.clientItems.take(8))
                    QzPressable(
                      onTap: () =>
                          macCtrl.text = (item['mac'] as String?) ?? '',
                      borderRadius: BorderRadius.circular(QuartzRadii.sm),
                      child: QzChip(
                        (item['host'] as String?)?.isNotEmpty == true
                            ? item['host'] as String
                            : (item['ip'] as String?) ?? '—',
                        kind: QzChipKind.muted,
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 10),
            QzField(
              controller: macCtrl,
              label: 'MAC',
              hint: 'aa:bb:cc:dd:ee:ff',
            ),
            const SizedBox(height: 10),
            QzField(
              controller: hostCtrl,
              label: l10n.bandixHostnameField,
              hint: l10n.bandixHostnameHint,
            ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(
                error!,
                style: TextStyle(fontSize: 12.5, color: QuartzColors.err),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: QzLegacyButton(
                    kind: QzButtonKind.plain,
                    onPressed: busy ? null : () => Navigator.of(ctx).pop(),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: QzLegacyButton(
                    onPressed: busy
                        ? null
                        : () async {
                            final mac = macCtrl.text.trim();
                            if (mac.isEmpty) {
                              setSheet(() => error = l10n.bandixMacRequired);
                              return;
                            }
                            setSheet(() {
                              busy = true;
                              error = null;
                            });
                            final err = await runBandixAction(
                              tm,
                              'bandix.hostname_set',
                              {'mac': mac, 'hostname': hostCtrl.text.trim()},
                            );
                            if (!ctx.mounted) return;
                            Navigator.of(ctx).pop();
                            _snack(context, l10n, err);
                          },
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
