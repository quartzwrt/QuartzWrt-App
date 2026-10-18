// 路由器 tab（IA v2 定案 D1′：原「网络」→「路由器」）。
//
// 路由器侧全量入口（网页端 Network + System）：分组 → 入口行 → 页面。
// **只列已实现页可点**（先例：蜂窝首页 6 格）；未实现的 W6.11 项显示「待后续版本」，
// 不做假入口（IA v2 D2′：无 API 的插件才走网页端深链，v1 先不铺深链）。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../widgets/quartz.dart';

class RouterPage extends ConsumerWidget {
  const RouterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    final st = ref.watch(snapshotProvider);
    final snap = st.data;
    final router = ref.watch(activeRouterProvider);
    final host = snap?.host ?? const <String, dynamic>{};
    final hostname = (host['hostname'] as String?)?.trim() ?? '';
    final model = (host['model'] as String?)?.trim() ?? '';
    final release = (host['release'] as String?)?.trim() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navRouter, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: l10n.refresh,
            onPressed: () => ref.read(snapshotProvider.notifier).refreshNow(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.read(snapshotProvider.notifier).refreshNow(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _identityCard(context, l10n, theme, router?.name ?? hostname, model, release, snap?.clientsTotal),
            if (st.kind == SnapKind.degraded && snap != null)
              InfoBanner(title: l10n.bannerConnectionLost, body: l10n.bannerConnectionLostBody),
            SectionLabel(l10n.routerGroupNetwork),
            QuartzCard(
              child: _entryGroup(context, [
                _Entry(
                  icon: Icons.lan_outlined,
                  title: l10n.routerEntryInterfaces,
                  subtitle: l10n.routerEntryInterfacesSub,
                  route: '/router/interfaces',
                ),
                _Entry(
                  icon: Icons.wifi_outlined,
                  title: l10n.routerEntryWireless,
                  subtitle: l10n.routerEntryWirelessSub,
                  route: '/router/wireless',
                ),
                _Entry(
                  icon: Icons.dns_outlined,
                  title: l10n.routerEntryDhcp,
                  subtitle: l10n.routerEntryDhcpSub,
                  route: '/router/dhcp',
                ),
                _Entry(
                  icon: Icons.alt_route_outlined,
                  title: l10n.routerEntryRoutes,
                  subtitle: l10n.routerEntryRoutesSub,
                  route: '/router/routes',
                ),
              ]),
            ),
            SectionLabel(l10n.routerGroupSecurity),
            QuartzCard(
              child: _entryGroup(context, [
                _Entry(
                  icon: Icons.shield_outlined,
                  title: l10n.routerEntryFirewall,
                  subtitle: l10n.routerEntryFirewallSub,
                ),
              ]),
            ),
            SectionLabel(l10n.routerGroupSystem),
            QuartzCard(
              child: _entryGroup(context, [
                _Entry(
                  icon: Icons.settings_suggest_outlined,
                  title: l10n.routerEntrySystem,
                  subtitle: l10n.routerEntrySystemSub,
                  route: '/router/system',
                ),
                _Entry(
                  icon: Icons.admin_panel_settings_outlined,
                  title: l10n.routerEntryAdmin,
                  subtitle: l10n.routerEntryAdminSub,
                  route: '/router/admin',
                ),
                _Entry(
                  icon: Icons.play_circle_outline,
                  title: l10n.routerEntryInit,
                  subtitle: l10n.routerEntryInitSub,
                  route: '/router/init',
                ),
              ]),
            ),
            SectionLabel(l10n.routerGroupLan),
            QuartzCard(
              child: _entryGroup(context, [
                _Entry(
                  icon: Icons.devices_outlined,
                  title: l10n.clientsCardTitle,
                  subtitle: l10n.routerEntryClientsSub(snap?.clientsTotal ?? 0),
                  route: '/router/clients',
                ),
              ]),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.routerMoreHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: .4)),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _identityCard(
    BuildContext context,
    AppL10n l10n,
    ThemeData theme,
    String name,
    String model,
    String release,
    int? clients,
  ) {
    final title = name.isEmpty ? l10n.navRouter : name;
    return QuartzCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: QuartzColors.accent.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(QuartzRadii.md),
            ),
            child: const Icon(Icons.router_outlined, color: QuartzColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  [if (model.isNotEmpty) model, if (release.isNotEmpty) release].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: .5),
                  ),
                ),
              ],
            ),
          ),
          if (clients != null)
            Text(
              l10n.clientsOnlineHeader(clients),
              style: const TextStyle(color: QuartzColors.accent, fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }

  Widget _entryGroup(BuildContext context, List<_Entry> entries) {
    return Column(
      children: [
        for (final (i, e) in entries.indexed)
          _EntryTile(entry: e, first: i == 0),
      ],
    );
  }
}

class _Entry {
  const _Entry({required this.icon, required this.title, required this.subtitle, this.route});

  final IconData icon;
  final String title;
  final String subtitle;
  final String? route;

  bool get ready => route != null;
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry, required this.first});

  final _Entry entry;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: .45);
    final danger = theme.brightness == Brightness.dark ? const Color(0x14FFFFFF) : const Color(0x11000000);
    final ready = entry.ready;
    return InkWell(
      onTap: ready ? () => context.push(entry.route!) : null,
      child: Container(
        decoration: first ? null : BoxDecoration(border: Border(top: BorderSide(color: danger))),
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: ready
                    ? QuartzColors.accent.withValues(alpha: .12)
                    : theme.colorScheme.onSurface.withValues(alpha: .05),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(entry.icon, size: 19, color: ready ? QuartzColors.accent : muted),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ready ? null : muted,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    entry.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: muted, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: ready ? QuartzColors.ok.withValues(alpha: .12) : theme.colorScheme.onSurface.withValues(alpha: .06),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                ready ? l10n.routerChipReady : l10n.routerChipSoon,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: ready ? QuartzColors.ok : muted,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 17, color: ready ? muted : muted.withValues(alpha: .35)),
          ],
        ),
      ),
    );
  }
}
