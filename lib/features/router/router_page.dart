// 路由器 tab（IA v2 定案 D1′：原「网络」→「路由器」）。
//
// 分组入口页：顶栏右侧显示路由器名；行 = 中性图标块 + 标题/副标题 +
// 能力档位 chip（原生 / 通用表单）+ chevron，对齐 design/ia-v2-preview.html。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../widgets/quartz.dart';

enum _Capability { native, generic }

class _Entry {
  const _Entry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.capability,
  });

  final String icon;
  final String title;
  final String subtitle;
  final String route;
  final _Capability capability;
}

class RouterPage extends ConsumerWidget {
  const RouterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final t = QuartzTokens.of(context);
    final st = ref.watch(snapshotProvider);
    final snap = st.data;
    final router = ref.watch(activeRouterProvider);
    final host = snap?.host ?? const <String, dynamic>{};
    final hostname = (host['hostname'] as String?)?.trim() ?? '';
    final title = (router?.name ?? hostname).trim();

    final network = <_Entry>[
      _Entry(
        icon: QzIcons.interfaces,
        title: l10n.routerEntryInterfaces,
        subtitle: l10n.routerEntryInterfacesSub,
        route: '/router/interfaces',
        capability: _Capability.native,
      ),
      _Entry(
        icon: QzIcons.wifi,
        title: l10n.routerEntryWireless,
        subtitle: l10n.routerEntryWirelessSub,
        route: '/router/wireless',
        capability: _Capability.native,
      ),
      _Entry(
        icon: QzIcons.dhcp,
        title: l10n.routerEntryDhcp,
        subtitle: l10n.routerEntryDhcpSub,
        route: '/router/dhcp',
        capability: _Capability.generic,
      ),
      _Entry(
        icon: QzIcons.route,
        title: l10n.routerEntryRoutes,
        subtitle: l10n.routerEntryRoutesSub,
        route: '/router/routes',
        capability: _Capability.generic,
      ),
    ];
    final security = <_Entry>[
      _Entry(
        icon: QzIcons.firewall,
        title: l10n.routerEntryFirewall,
        subtitle: l10n.routerEntryFirewallSub,
        route: '/router/firewall',
        capability: _Capability.generic,
      ),
    ];
    final system = <_Entry>[
      _Entry(
        icon: QzIcons.system,
        title: l10n.routerEntrySystem,
        subtitle: l10n.routerEntrySystemSub,
        route: '/router/system',
        capability: _Capability.generic,
      ),
      _Entry(
        icon: QzIcons.admin,
        title: l10n.routerEntryAdmin,
        subtitle: l10n.routerEntryAdminSub,
        route: '/router/admin',
        capability: _Capability.generic,
      ),
      _Entry(
        icon: QzIcons.init,
        title: l10n.routerEntryInit,
        subtitle: l10n.routerEntryInitSub,
        route: '/router/init',
        capability: _Capability.native,
      ),
    ];
    final advanced = <_Entry>[
      _Entry(
        icon: QzIcons.memory,
        title: l10n.routerEntryMounts,
        subtitle: l10n.routerEntryMountsSub,
        route: '/router/mounts',
        capability: _Capability.generic,
      ),
      _Entry(
        icon: QzIcons.calendar,
        title: l10n.routerEntryCron,
        subtitle: l10n.routerEntryCronSub,
        route: '/router/cron',
        capability: _Capability.generic,
      ),
      _Entry(
        icon: QzIcons.advanced,
        title: l10n.routerEntryLed,
        subtitle: l10n.routerEntryLedSub,
        route: '/router/led',
        capability: _Capability.generic,
      ),
    ];
    final lan = <_Entry>[
      _Entry(
        icon: QzIcons.clients,
        title: l10n.clientsCardTitle,
        subtitle: l10n.routerEntryClientsSub(snap?.clientsTotal ?? 0),
        route: '/router/clients',
        capability: _Capability.native,
      ),
    ];

    return Scaffold(
      appBar: QzAppBar(
        titleText: l10n.navRouter,
        trailingText: title.isEmpty ? null : title,
      ),
      body: QzRefresh(
        onRefresh: () => ref.read(snapshotProvider.notifier).refreshNow(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (st.kind == SnapKind.degraded && snap != null)
              InfoBanner(
                title: l10n.bannerConnectionLost,
                body: l10n.bannerConnectionLostBody,
              ),
            const SizedBox(height: 2),
            QzSectionLabel(l10n.routerGroupNetwork),
            _group(context, l10n, network),
            QzSectionLabel(l10n.routerGroupSecurity),
            _group(context, l10n, security),
            QzSectionLabel(l10n.routerGroupSystem),
            _group(context, l10n, system),
            QzSectionLabel(l10n.routerGroupAdvanced),
            _group(context, l10n, advanced),
            QzSectionLabel(l10n.routerGroupLan),
            _group(context, l10n, lan),
            const SizedBox(height: 10),
            Text(
              l10n.routerMoreHint,
              textAlign: TextAlign.center,
              style: QuartzType.caption.copyWith(color: t.faint),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _group(BuildContext context, AppL10n l10n, List<_Entry> entries) {
    return QzListGroup(
      children: [
        for (final (i, e) in entries.indexed)
          QzListRow(
            first: i == 0,
            compact: true,
            title: e.title,
            subtitle: e.subtitle,
            chip: e.capability == _Capability.native
                ? l10n.routerChipNative
                : l10n.routerChipGeneric,
            chipKind: e.capability == _Capability.native
                ? QzChipKind.native
                : QzChipKind.generic,
            onTap: () => context.push(e.route),
          ),
      ],
    );
  }
}
