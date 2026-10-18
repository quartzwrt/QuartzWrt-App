// 应用入口与路由（go_router；DESIGN §2.2 / UI-DESIGN 定案 IA）。
//
// 4–5 tab（蜂窝条件显示）用 StatefulShellRoute.indexedStack：切 tab 保留各页滚动位置与状态
// （W6.6 性能/体验打磨）；详情页走轻量上滑淡入过渡。
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme.dart';
import 'features/apps/app_detail_page.dart';
import 'features/apps/apps_page.dart';
import 'features/apps/package_log_page.dart';
import 'features/bandix/bandix_page.dart';
import 'features/cellular/cellular_at_page.dart';
import 'features/cellular/cellular_log_page.dart';
import 'features/cellular/cellular_network_page.dart';
import 'features/cellular/cellular_advanced_page.dart';
import 'features/cellular/cellular_page.dart';
import 'features/cellular/cellular_sim_page.dart';
import 'features/cellular/cellular_sms_page.dart';
import 'features/discover/discover_page.dart';
import 'features/network/clients_page.dart';
import 'features/overview/overview_page.dart';
import 'features/router/admin_page.dart';
import 'features/router/cron_page.dart';
import 'features/router/dhcp_page.dart';
import 'features/router/firewall_page.dart';
import 'features/router/init_page.dart';
import 'features/router/interfaces_page.dart';
import 'features/router/led_page.dart';
import 'features/router/mounts_page.dart';
import 'features/router/router_page.dart';
import 'features/router/routes_page.dart';
import 'features/router/system_page.dart';
import 'features/router/wireless_page.dart';
import 'features/settings/devices_page.dart';
import 'features/settings/remote_page.dart';
import 'features/settings/settings_page.dart';
import 'features/shell/shell.dart';
import 'l10n/app_localizations.dart';
import 'state/app_state.dart';

/// 详情页过渡：轻量上滑 + 淡入（tab 切换保持瞬时，避免拖沓）。
CustomTransitionPage<void> _fadeUpPage(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 160),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, .025), end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
      child: child,
    );

/// 当前蜂窝页操作的模组 section（单模组=第一个；多模组切换在页面内，v1 传首页选中）。
String _cellularSection(Ref ref) {
  final snap = ref.read(snapshotProvider).data?.cellular;
  final modems = snap?.modems ?? const [];
  return modems.isEmpty ? '' : modems.first.id;
}

final routerProvider = Provider<GoRouter>((ref) {
  final registry = ref.watch(registryProvider);
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final hasRouter = registry.active != null;
      final path = state.uri.path;
      // IA v2 D1′：tab 改名「网络 → 路由器」；旧深链保持兼容。
      if (path == '/network') return '/router';
      if (path == '/network/clients') return '/router/clients';
      if (path == '/') return hasRouter ? '/overview' : '/discover';
      if (!hasRouter && path != '/discover') return '/discover';
      return null;
    },
    routes: [
      GoRoute(path: '/discover', builder: (_, _) => const DiscoverPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => ShellScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/overview', builder: (_, _) => const OverviewPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/router', builder: (_, _) => const RouterPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/apps', builder: (_, _) => const AppsPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/cellular', builder: (_, _) => const CellularPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
          ]),
        ],
      ),
      GoRoute(path: '/router/clients', pageBuilder: (_, s) => _fadeUpPage(s, const ClientsPage())),
      GoRoute(path: '/router/interfaces', pageBuilder: (_, s) => _fadeUpPage(s, const InterfacesPage())),
      GoRoute(path: '/router/wireless', pageBuilder: (_, s) => _fadeUpPage(s, const WirelessPage())),
      GoRoute(path: '/router/dhcp', pageBuilder: (_, s) => _fadeUpPage(s, const DhcpPage())),
      GoRoute(path: '/router/routes', pageBuilder: (_, s) => _fadeUpPage(s, const RoutesPage())),
      GoRoute(path: '/router/system', pageBuilder: (_, s) => _fadeUpPage(s, const SystemPage())),
      GoRoute(path: '/router/admin', pageBuilder: (_, s) => _fadeUpPage(s, const AdminPage())),
      GoRoute(path: '/router/firewall', pageBuilder: (_, s) => _fadeUpPage(s, const FirewallPage())),
      GoRoute(path: '/router/mounts', pageBuilder: (_, s) => _fadeUpPage(s, const MountsPage())),
      GoRoute(path: '/router/led', pageBuilder: (_, s) => _fadeUpPage(s, const LedPage())),
      GoRoute(path: '/router/cron', pageBuilder: (_, s) => _fadeUpPage(s, const CronPage())),
      GoRoute(path: '/router/init', pageBuilder: (_, s) => _fadeUpPage(s, const InitPage())),
      GoRoute(
        path: '/apps/detail/:id',
        pageBuilder: (_, s) => _fadeUpPage(s, AppDetailPage(appId: s.pathParameters['id']!)),
      ),
      GoRoute(path: '/apps/log', pageBuilder: (_, s) => _fadeUpPage(s, const PackageLogPage())),
      GoRoute(path: '/apps/bandix', pageBuilder: (_, s) => _fadeUpPage(s, const BandixPage())),
      GoRoute(
        path: '/cellular/network',
        pageBuilder: (_, s) => _fadeUpPage(s, CellularNetworkPage(section: _cellularSection(ref))),
      ),
      GoRoute(
        path: '/cellular/at',
        pageBuilder: (_, s) => _fadeUpPage(s, CellularAtPage(section: _cellularSection(ref))),
      ),
      GoRoute(
        path: '/cellular/sim',
        pageBuilder: (_, s) => _fadeUpPage(s, CellularSimPage(section: _cellularSection(ref))),
      ),
      GoRoute(
        path: '/cellular/sms',
        pageBuilder: (_, s) => _fadeUpPage(s, CellularSmsPage(section: _cellularSection(ref))),
      ),
      GoRoute(
        path: '/cellular/advanced',
        pageBuilder: (_, s) => _fadeUpPage(s, CellularAdvancedPage(section: _cellularSection(ref))),
      ),
      GoRoute(
        path: '/cellular/log',
        pageBuilder: (_, s) => _fadeUpPage(s, CellularLogPage(section: _cellularSection(ref))),
      ),
      GoRoute(path: '/settings/devices', pageBuilder: (_, s) => _fadeUpPage(s, const DevicesPage())),
      GoRoute(path: '/settings/remote', pageBuilder: (_, s) => _fadeUpPage(s, const RemotePage())),
    ],
  );
});

class QuartzApp extends ConsumerWidget {
  const QuartzApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppL10n.of(context).appTitle,
      theme: buildQuartzTheme(Brightness.light),
      darkTheme: buildQuartzTheme(Brightness.dark),
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: const [
        AppL10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppL10n.supportedLocales,
      routerConfig: router,
    );
  }
}
