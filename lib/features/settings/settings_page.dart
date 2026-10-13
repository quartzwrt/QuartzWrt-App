// 设置页（UI-DESIGN ⑥，定案）：系统设置（路由器/设备控制）+ 应用设置（本机）。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/endpoint.dart';
import '../../core/theme.dart';
import '../../core/version.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../widgets/quartz.dart';
import '../actions/actions.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    final router = ref.watch(activeRouterProvider);
    final snap = ref.watch(snapshotProvider).data;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final remoteActive = ref.watch(endpointProvider)?.kind == EndpointKind.remote;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700))),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          SectionLabel(l10n.sysSettingsGroup),
          if (router == null)
            QuartzCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.discoverNone, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: () => context.go('/discover'),
                    child: Text(l10n.addRouterEntry),
                  ),
                ],
              ),
            )
          else ...[
            QuartzCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    title: Row(
                      children: [
                        StatusDot(DotKind.ok),
                        Expanded(
                          child: Text(router.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    subtitle: Text(remoteActive ? l10n.pairedRemote : l10n.pairedLan),
                    trailing: Text(
                      _shortFp(router.fingerprint),
                      style: const TextStyle(fontSize: 12, fontFeatures: [FontFeature.tabularFigures()]),
                    ),
                  ),
                  const Divider(height: 1, indent: 14, endIndent: 14),
                  ListTile(
                    title: Text(l10n.remoteEntry),
                    subtitle: router.hasRemote
                        ? Text('${router.remoteHost}:${router.remotePort ?? 443}')
                        : null,
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => context.push('/settings/remote'),
                  ),
                  const Divider(height: 1, indent: 14, endIndent: 14),
                  ListTile(
                    title: Text(l10n.pairedDevicesEntry),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => context.push('/settings/devices'),
                  ),
                  const Divider(height: 1, indent: 14, endIndent: 14),
                  ListTile(
                    title: Text(l10n.addRouterEntry),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => context.go('/discover'),
                  ),
                  const Divider(height: 1, indent: 14, endIndent: 14),
                  ListTile(
                    title: Text(l10n.removeRouterBtn, style: const TextStyle(color: QuartzColors.err)),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => _removeRouter(context, ref, router.id, router.name),
                  ),
                ],
              ),
            ),
            QuartzCard(
              title: l10n.deviceControlTitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => _reboot(context, ref, router.name),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.rebootRouter,
                              style: const TextStyle(color: QuartzColors.err, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text('›', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: .45))),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _restartService(context, ref, snap),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(child: Text(l10n.restartService)),
                          Text('›', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: .45))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SectionLabel(l10n.appSettingsGroup),
          QuartzCard(
            title: l10n.appearanceTitle,
            child: SegmentBar<ThemeMode>(
              values: const [ThemeMode.system, ThemeMode.dark, ThemeMode.light],
              selected: themeMode,
              labelOf: (m) => switch (m) {
                ThemeMode.system => l10n.followSystem,
                ThemeMode.dark => l10n.modeDark,
                ThemeMode.light => l10n.modeLight,
              },
              onChanged: (m) => ref.read(themeModeProvider.notifier).set(m),
            ),
          ),
          QuartzCard(
            title: l10n.languageTitle,
            child: SegmentBar<String>(
              values: const ['zh', 'en'],
              // 未显式选择（跟随系统）时，按生效语言回显（走查抓到的显示不一致）
              selected: (locale?.languageCode ?? Localizations.localeOf(context).languageCode) == 'en' ? 'en' : 'zh',
              labelOf: (v) => v == 'zh' ? '中文' : 'English',
              onChanged: (v) => ref.read(localeProvider.notifier).set(Locale(v)),
            ),
          ),
          QuartzCard(
            title: l10n.aboutTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KvRow(l10n.appVersionLabel, '$kAppVersion ($kAppBuild)', first: true),
                KvRow(l10n.apiLabel, 'quartz-app-api v1'),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static String _shortFp(String fp) =>
      fp.length >= 12 ? '${fp.substring(0, 8)} … ${fp.substring(fp.length - 4)} ✓' : fp;

  Future<void> _reboot(BuildContext context, WidgetRef ref, String name) async {
    final l10n = AppL10n.of(context);
    final tm = ref.read(tokenManagerProvider);
    if (tm == null) return;
    final ok = await showConfirmSheet(
      context,
      title: l10n.rebootConfirmTitle,
      body: l10n.rebootConfirmBody(name),
      confirmLabel: l10n.rebootRouter,
      cancelLabel: l10n.cancel,
      danger: true,
    );
    if (!ok) return;
    final r = await runAction(tm, const ActionSpec(id: 'system.reboot', label: 'reboot'));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(r.ok ? l10n.actionDone : l10n.actionFailed(r.message))),
    );
  }

  Future<void> _restartService(BuildContext context, WidgetRef ref, dynamic snap) async {
    final l10n = AppL10n.of(context);
    final tm = ref.read(tokenManagerProvider);
    if (tm == null) return;
    final entries = (snap?.serviceEntries ?? const []);
    if ((entries as List).isEmpty) return;
    final picked = await showModalBottomSheet<(String, String)>(
      context: context,
      backgroundColor:
          Theme.of(context).brightness == Brightness.dark ? QuartzColors.darkRaised : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Text(l10n.restartService, style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 6),
            for (final e in entries)
              ListTile(
                title: Text(e.$1),
                subtitle: Text(e.$2['running'] == true ? l10n.running : l10n.stopped2),
                onTap: () => Navigator.of(ctx).pop((e.$1, e.$2['running'] == true ? l10n.running : l10n.stopped2)),
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
    if (picked == null || !context.mounted) return;
    final ok = await showConfirmSheet(
      context,
      title: '${l10n.actionRestart} · ${picked.$1}',
      confirmLabel: l10n.confirm,
      cancelLabel: l10n.cancel,
    );
    if (!ok) return;
    final r = await runAction(
      tm,
      serviceAction(op: 'restart', label: l10n.actionRestart, name: picked.$1),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(r.ok ? l10n.actionDone : l10n.actionFailed(r.message))),
    );
    ref.read(snapshotProvider.notifier).refreshNow();
  }

  Future<void> _removeRouter(BuildContext context, WidgetRef ref, String id, String name) async {
    final l10n = AppL10n.of(context);
    final ok = await showConfirmSheet(
      context,
      title: l10n.removeRouterTitle,
      body: l10n.removeRouterBody,
      confirmLabel: l10n.removeRouterBtn,
      cancelLabel: l10n.cancel,
      danger: true,
    );
    if (!ok) return;
    final tm = ref.read(tokenManagerProvider);
    await tm?.logout();
    await ref.read(registryProvider).remove(id);
    ref.invalidate(activeRouterProvider);
    if (!context.mounted) return;
    context.go('/discover');
  }
}
