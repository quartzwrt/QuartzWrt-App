// QuartzWrt App —— 工程骨架（W6.1）。
//
// 规范: docs/DESIGN.md v1.0（定案）
// 分层: api（transport+envelope）/ discovery / data / features（DESIGN §2.2）
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(const QuartzApp());
}

class QuartzApp extends StatelessWidget {
  const QuartzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppL10n.of(context).appTitle,
      theme: buildQuartzTheme(Brightness.light),
      darkTheme: buildQuartzTheme(Brightness.dark),
      localizationsDelegates: const [
        AppL10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppL10n.supportedLocales,
      home: const HomeScreen(),
    );
  }
}

/// 未连接态首页（W6.2 接入发现/配对后替换为路由器列表）。
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.router_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(l10n.notConnectedTitle, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                l10n.notConnectedBody,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: null, // W6.2: 接入 mDNS 发现
                icon: const Icon(Icons.wifi_find_outlined),
                label: Text(l10n.actionScan),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: null, // W6.2: 手动地址录入
                icon: const Icon(Icons.add_outlined),
                label: Text(l10n.actionAddByAddress),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
