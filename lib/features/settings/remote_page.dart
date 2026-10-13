// 远程访问引导页（W6.5，DESIGN §7 / UI-DESIGN ⑬）。
//
// 数据面：路由器端 Tailscale 状态取自快照 `services.tailscale`（daemon 内置
// 探针：running + ip extras）——有真数据直接展示，无则给安装引导。
// 动作面：添加/测试/移除远程端点（probeEndpoint 严格 pin 校验，只调 info），
// 保存后即切换当前端点；FailoverTransport 之后负责自动切换。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/endpoint.dart';
import '../../api/models.dart';
import '../../auth/pairing.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/error_text.dart';
import '../../state/app_state.dart';
import '../../widgets/quartz.dart';

class RemotePage extends ConsumerWidget {
  const RemotePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final router = ref.watch(activeRouterProvider);
    final snap = ref.watch(snapshotProvider).data;
    final endpoint = ref.watch(endpointProvider);

    final tsRaw = snap?.services?['tailscale'];
    final ts = tsRaw is Map<String, dynamic>
        ? tsRaw
        : (tsRaw == true ? <String, dynamic>{'running': true} : null);
    final tsRunning = ts?['running'] == true;
    final tsIp = (ts?['ip'] as String?)?.trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.remotePageTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (router == null)
            QuartzCard(child: Text(l10n.discoverNone, style: Theme.of(context).textTheme.bodySmall))
          else ...[
            QuartzCard(
              title: l10n.remoteRouterStatusTitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KvRow(
                    l10n.appDetailStatusTitle,
                    tsRunning ? l10n.running : (ts == null ? l10n.notInstalled : l10n.stopped2),
                    first: true,
                    valueMono: false,
                    valueColor: tsRunning ? QuartzColors.ok : null,
                  ),
                  if (tsRunning && tsIp != null && tsIp.isNotEmpty)
                    KvRow(l10n.remoteTsIpLabel, tsIp, valueMono: true),
                  if (!tsRunning) ...[
                    const SizedBox(height: 6),
                    Text(
                      l10n.remoteNotDetected,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .55),
                            height: 1.45,
                          ),
                    ),
                  ],
                  if (tsRunning && tsIp != null && tsIp.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: () => _addRemote(context, ref, prefillHost: tsIp),
                      child: Text(l10n.remoteUseThisAddr),
                    ),
                  ],
                ],
              ),
            ),
            QuartzCard(
              title: l10n.remoteStepsTitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _step(context, 1, l10n.remoteStep1),
                  _step(context, 2, l10n.remoteStep2),
                  _step(context, 3, l10n.remoteStep3),
                  _step(context, 4, l10n.remoteStep4),
                ],
              ),
            ),
            QuartzCard(
              title: l10n.remoteAddrTitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!router.hasRemote)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        l10n.remoteAddrNone,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .55),
                              height: 1.45,
                            ),
                      ),
                    )
                  else ...[
                    KvRow(
                      '${router.remoteHost}:${router.remotePort ?? 443}',
                      endpoint?.kind == EndpointKind.remote ? l10n.remoteInUse : '',
                      first: true,
                      valueMono: false,
                      valueColor: QuartzColors.ok,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => _testRemote(context, ref, router),
                          child: Text(l10n.remoteTestBtn),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => _addRemote(context, ref, prefillHost: router.remoteHost),
                          child: Text(l10n.remoteEditBtn),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _removeRemote(context, ref, router),
                            style: OutlinedButton.styleFrom(foregroundColor: QuartzColors.err),
                            child: Text(l10n.remoteRemoveShort),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (!router.hasRemote)
                    FilledButton(
                      onPressed: () => _addRemote(context, ref),
                      child: Text(l10n.remoteAddBtn),
                    ),
                ],
              ),
            ),
            QuartzCard(
              title: l10n.remoteAutoTitle,
              child: Text(
                l10n.remoteAutoBody,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .65),
                      height: 1.5,
                    ),
              ),
            ),
            QuartzCard(
              title: l10n.remoteSecurityTitle,
              child: Text(
                l10n.remoteSecurityBody,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .65),
                      height: 1.5,
                    ),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static Widget _step(BuildContext context, int n, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 1),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: QuartzColors.accent.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$n',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: QuartzColors.accent),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: theme.textTheme.bodySmall?.copyWith(height: 1.5)),
          ),
        ],
      ),
    );
  }

  // ---- 添加/修改：测试并保存（严格 pin 的 info 探测） ----

  Future<void> _addRemote(BuildContext context, WidgetRef ref, {String? prefillHost}) async {
    final l10n = AppL10n.of(context);
    final router = ref.read(activeRouterProvider);
    if (router == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hostCtrl = TextEditingController(text: prefillHost ?? router.remoteHost ?? '');
    final portCtrl = TextEditingController(text: '${router.remotePort ?? 443}');
    var busy = false;
    String? error;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? QuartzColors.darkRaised : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          Future<void> testAndSave() async {
            final host = hostCtrl.text.trim();
            final port = int.tryParse(portCtrl.text.trim()) ?? 443;
            if (host.isEmpty) {
              setSheet(() => error = l10n.remoteHostRequired);
              return;
            }
            setSheet(() {
              busy = true;
              error = null;
            });
            try {
              await probeEndpoint(router, host: host, port: port);
              final registry = ref.read(registryProvider);
              await registry.setRemote(router.id, host, port);
              ref.read(activeRouterProvider.notifier).reload();
              ref.read(endpointProvider.notifier).switchTo(
                    Endpoint(host: host, port: port, kind: EndpointKind.remote),
                  );
              if (ctx.mounted) Navigator.of(ctx).pop(true);
            } on PairException catch (e) {
              setSheet(() {
                busy = false;
                error = pairErrorText(l10n, e);
              });
            } catch (_) {
              setSheet(() {
                busy = false;
                error = l10n.errConnect;
              });
            }
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(18, 10, 18, 24 + MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4.5,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: .35),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Text(
                  l10n.remoteAddBtn,
                  textAlign: TextAlign.center,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: hostCtrl,
                  autofocus: true,
                  enabled: !busy,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: l10n.remoteHostLabel,
                    hintText: '100.101.102.103',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: portCtrl,
                  enabled: !busy,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: l10n.portLabel,
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: QuartzColors.err)),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: busy ? null : () => Navigator.of(ctx).pop(false),
                        child: Text(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: busy ? null : testAndSave,
                        child: Text(busy ? l10n.remoteTesting : l10n.remoteTestSave),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.remoteTestOk)));
      ref.read(snapshotProvider.notifier).refreshNow();
    }
  }

  Future<void> _testRemote(BuildContext context, WidgetRef ref, PairedRouter router) async {
    final l10n = AppL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await probeEndpoint(router, host: router.remoteHost!, port: router.remotePort ?? 443);
      messenger.showSnackBar(SnackBar(content: Text(l10n.remoteTestOk)));
    } on PairException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.remoteTestFail(pairErrorText(l10n, e)))));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.remoteTestFail(l10n.errConnect))));
    }
  }

  Future<void> _removeRemote(BuildContext context, WidgetRef ref, PairedRouter router) async {
    final l10n = AppL10n.of(context);
    final ok = await showConfirmSheet(
      context,
      title: l10n.remoteRemoveTitle,
      body: l10n.remoteRemoveBody,
      confirmLabel: l10n.remoteRemoveBtn,
      cancelLabel: l10n.cancel,
      danger: true,
    );
    if (!ok || !context.mounted) return;
    await ref.read(registryProvider).clearRemote(router.id);
    ref.read(activeRouterProvider.notifier).reload();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.remoteRemoved)));
  }
}
