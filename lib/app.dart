// 应用入口与路由（go_router；DESIGN §2.2 / UI-DESIGN 定案 IA）。
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme.dart';
import 'features/apps/app_detail_page.dart';
import 'features/apps/apps_page.dart';
import 'features/apps/package_log_page.dart';
import 'features/discover/discover_page.dart';
import 'features/network/clients_page.dart';
import 'features/network/network_page.dart';
import 'features/overview/overview_page.dart';
import 'features/settings/devices_page.dart';
import 'features/settings/settings_page.dart';
import 'features/shell/shell.dart';
import 'l10n/app_localizations.dart';
import 'state/app_state.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final registry = ref.watch(registryProvider);
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final hasRouter = registry.active != null;
      final path = state.uri.path;
      if (path == '/') return hasRouter ? '/overview' : '/discover';
      if (!hasRouter && path != '/discover') return '/discover';
      return null;
    },
    routes: [
      GoRoute(path: '/discover', builder: (_, _) => const DiscoverPage()),
      ShellRoute(
        builder: (context, state, child) =>
            ShellScaffold(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/overview', builder: (_, _) => const OverviewPage()),
          GoRoute(path: '/network', builder: (_, _) => const NetworkPage()),
          GoRoute(path: '/apps', builder: (_, _) => const AppsPage()),
          GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
        ],
      ),
      GoRoute(path: '/network/clients', builder: (_, _) => const ClientsPage()),
      GoRoute(
        path: '/apps/detail/:id',
        builder: (_, state) => AppDetailPage(appId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/apps/log', builder: (_, _) => const PackageLogPage()),
      GoRoute(path: '/settings/devices', builder: (_, _) => const DevicesPage()),
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
