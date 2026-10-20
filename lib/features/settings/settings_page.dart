// 设置页（UI-DESIGN ⑥，定案）：系统设置（路由器/设备控制）+ 应用设置（本机）。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/endpoint.dart';
import '../../core/theme.dart';
import '../../core/version.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../state/appearance.dart';
import '../../widgets/quartz.dart';
import '../actions/actions.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final t = QuartzTokens.of(context);
    final router = ref.watch(activeRouterProvider);
    final snap = ref.watch(snapshotProvider).data;
    final themeMode = ref.watch(themeModeProvider);
    final appearance = ref.watch(appearanceProvider);
    final locale = ref.watch(localeProvider);
    final remoteActive =
        ref.watch(endpointProvider)?.kind == EndpointKind.remote;

    return Scaffold(
      appBar: QzAppBar(titleText: l10n.settingsTitle),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          QzSectionLabel(l10n.sysSettingsGroup),
          if (router == null)
            QuartzCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.discoverNone,
                    style: QuartzType.body.copyWith(color: t.muted),
                  ),
                  const SizedBox(height: 10),
                  QzButton(
                    label: l10n.addRouterEntry,
                    onPressed: () => context.go('/discover'),
                    expand: true,
                  ),
                ],
              ),
            )
          else ...[
            QzListGroup(
              children: [
                QzListRow(
                  first: true,
                  showChevron: false,
                  leading: StatusDot(DotKind.ok),
                  title: router.name,
                  subtitle: remoteActive ? l10n.pairedRemote : l10n.pairedLan,
                  trailing: Text(
                    _shortFp(router.fingerprint),
                    style: QuartzType.caption.copyWith(
                      color: t.faint,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                QzListRow(
                  title: l10n.remoteEntry,
                  subtitle: router.hasRemote
                      ? '${router.remoteHost}:${router.remotePort ?? 443}'
                      : null,
                  onTap: () => context.push('/settings/remote'),
                ),
                QzListRow(
                  title: l10n.pairedDevicesEntry,
                  onTap: () => context.push('/settings/devices'),
                ),
                QzListRow(
                  title: l10n.addRouterEntry,
                  onTap: () => context.go('/discover'),
                ),
                QzListRow(
                  title: l10n.removeRouterBtn,
                  danger: true,
                  onTap: () =>
                      _removeRouter(context, ref, router.id, router.name),
                ),
              ],
            ),
            QzSectionLabel(l10n.deviceControlTitle),
            QzListGroup(
              children: [
                QzListRow(
                  first: true,
                  title: l10n.rebootRouter,
                  danger: true,
                  onTap: () => _reboot(context, ref, router.name),
                ),
                QzListRow(
                  title: l10n.restartService,
                  onTap: () => _restartService(context, ref, snap),
                ),
              ],
            ),
          ],
          QzSectionLabel(l10n.appSettingsGroup),
          QzListGroup(
            children: [
              QzListRow(
                first: true,
                title: l10n.appearanceTitle,
                subtitle:
                    '${switch (themeMode) {
                      ThemeMode.system => l10n.followSystem,
                      ThemeMode.dark => l10n.modeDark,
                      ThemeMode.light => l10n.modeLight,
                    }} · ${(appearance.opacity * 100).round()}% · ${appearance.blur.round()}px',
                onTap: () => context.push('/settings/appearance'),
              ),
            ],
          ),
          QuartzCard(
            title: l10n.languageTitle,
            child: QzSegmented<String>(
              values: const ['zh', 'en'],
              // 未显式选择（跟随系统）时，按生效语言回显（走查抓到的显示不一致）
              selected:
                  (locale?.languageCode ??
                          Localizations.localeOf(context).languageCode) ==
                      'en'
                  ? 'en'
                  : 'zh',
              labelOf: (v) => v == 'zh' ? '中文' : 'English',
              onChanged: (v) =>
                  ref.read(localeProvider.notifier).set(Locale(v)),
            ),
          ),
          QuartzCard(
            title: l10n.aboutTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KvRow(
                  l10n.appVersionLabel,
                  '$kAppVersion ($kAppBuild)',
                  first: true,
                ),
                KvRow(l10n.apiLabel, 'quartz-app-api v1'),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static String _shortFp(String fp) => fp.length >= 12
      ? '${fp.substring(0, 8)} … ${fp.substring(fp.length - 4)} ✓'
      : fp;

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
    final r = await runAction(
      tm,
      const ActionSpec(id: 'system.reboot', label: 'reboot'),
    );
    if (!context.mounted) return;
    showQzToast(
      context,
      r.ok ? l10n.actionDone : l10n.actionFailed(r.message),
      kind: r.ok ? QzToastKind.ok : QzToastKind.err,
    );
  }

  Future<void> _restartService(
    BuildContext context,
    WidgetRef ref,
    dynamic snap,
  ) async {
    final l10n = AppL10n.of(context);
    final t = QuartzTokens.of(context);
    final tm = ref.read(tokenManagerProvider);
    if (tm == null) return;
    final entries = (snap?.serviceEntries ?? const []);
    if ((entries as List).isEmpty) return;
    final picked = await showQzSheet<(String, String)>(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.restartService,
            textAlign: TextAlign.center,
            style: QuartzType.heroTitle.copyWith(color: t.text),
          ),
          const SizedBox(height: 8),
          for (final (i, e) in entries.indexed)
            QzListRow(
              first: i == 0,
              title: e.$1,
              subtitle: e.$2['running'] == true ? l10n.running : l10n.stopped2,
              showChevron: false,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              onTap: () => Navigator.of(ctx).pop((
                e.$1,
                e.$2['running'] == true ? l10n.running : l10n.stopped2,
              )),
            ),
          const SizedBox(height: 10),
          QzButton(
            label: l10n.cancel,
            kind: QzButtonKind.plain,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
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
    showQzToast(
      context,
      r.ok ? l10n.actionDone : l10n.actionFailed(r.message),
      kind: r.ok ? QzToastKind.ok : QzToastKind.err,
    );
    ref.read(snapshotProvider.notifier).refreshNow();
  }

  Future<void> _removeRouter(
    BuildContext context,
    WidgetRef ref,
    String id,
    String name,
  ) async {
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
