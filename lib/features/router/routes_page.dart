// 路由器 · 静态路由（W6.11）：network 配置的 route/rule 节。
//
// 增删走 config.add/delete（暂存）→ apply → 90s 确认条；列表读 config.read network。
import 'package:flutter/material.dart';

import '../../core/theme.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/config.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/quartz.dart';
import 'config_common.dart';

class RoutesPage extends ConsumerStatefulWidget {
  const RoutesPage({super.key});

  @override
  ConsumerState<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends ConsumerState<RoutesPage> {
  bool _loading = true;
  bool _busy = false;
  String _error = '';
  Map<String, Map<String, dynamic>> _sections = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final client = ref.read(configClientProvider);
    if (client == null) return;
    setState(() {
      _loading = true;
      _error = '';
    });
    final r = await client.read('network');
    if (!mounted) return;
    if (!r.ok) {
      setState(() {
        _loading = false;
        _error = configErrorText(AppL10n.of(context), r.error);
      });
      return;
    }
    final sections = <String, Map<String, dynamic>>{};
    for (final e in r.map.entries) {
      final v = e.value;
      if (v is Map<String, dynamic>) sections[e.key] = v;
    }
    setState(() {
      _sections = sections;
      _loading = false;
    });
  }

  bool _isRoute(Map<String, dynamic> v) =>
      v.containsKey('target') || v.containsKey('netmask');

  bool _isRule(Map<String, dynamic> v) =>
      v.containsKey('src') ||
      v.containsKey('dest') ||
      v.containsKey('lookup') ||
      v.containsKey('priority');

  List<String> _keys(bool route) {
    final keys = _sections.keys.where((k) {
      final v = _sections[k]!;
      return route ? _isRoute(v) : (_isRule(v) && !_isRoute(v));
    }).toList();
    keys.sort((a, b) => a.compareTo(b));
    return keys;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    final routes = _keys(true);
    final rules = _keys(false);
    return Scaffold(
      appBar: QzAppBar(
        title: Text(
          l10n.routerEntryRoutes,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        actions: [
          QzLegacyIconButton(
            tooltip: l10n.refresh,
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: QzSpinner(size: 22))
          : QzRefresh(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (_error.isNotEmpty) ...[
                    InfoBanner(title: l10n.configLoadFailedTitle, body: _error),
                    const SizedBox(height: 4),
                  ],
                  _card(
                    context,
                    l10n,
                    title: l10n.routesStatic,
                    empty: l10n.routesNone,
                    entries: routes,
                    route: true,
                  ),
                  const SizedBox(height: 4),
                  _card(
                    context,
                    l10n,
                    title: l10n.routesRules,
                    empty: l10n.routesNone,
                    entries: rules,
                    route: false,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 12, 4, 20),
                    child: Text(
                      l10n.routesHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: .45,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _card(
    BuildContext context,
    AppL10n l10n, {
    required String title,
    required String empty,
    required List<String> entries,
    required bool route,
  }) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: .5);
    return QuartzCard(
      title: title,
      trailing: QzLegacyIconButton(
        tooltip: route ? l10n.routesAddRoute : l10n.routesAddRule,
        onPressed: _busy ? null : () => _add(l10n, route),
        icon: const Icon(Icons.add, size: 20),
      ),
      child: entries.isEmpty
          ? Text(
              empty,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, section) in entries.indexed)
                  _row(context, l10n, section, route: route, first: i == 0),
              ],
            ),
    );
  }

  Widget _row(
    BuildContext context,
    AppL10n l10n,
    String section, {
    required bool route,
    required bool first,
  }) {
    final theme = Theme.of(context);
    final v = _sections[section] ?? const <String, dynamic>{};
    final muted = theme.colorScheme.onSurface.withValues(alpha: .5);
    final divider = QuartzTokens.of(context).border;
    final title = route
        ? '${_s(v, 'target')}${_s(v, 'netmask').isNotEmpty ? '/${_s(v, 'netmask')}' : ''}'
        : [
            if (_s(v, 'src').isNotEmpty)
              '${l10n.routesRuleSrc} ${_s(v, 'src')}',
            if (_s(v, 'dest').isNotEmpty)
              '${l10n.routesRuleDest} ${_s(v, 'dest')}',
          ].join(' · ').ifEmpty(_s(v, 'lookup').ifEmpty(section));
    final sub = route
        ? [
            if (_s(v, 'gateway').isNotEmpty)
              '${l10n.routesGateway} ${_s(v, 'gateway')}',
            if (_s(v, 'interface').isNotEmpty)
              '${l10n.routesInterface} ${_s(v, 'interface')}',
            if (_s(v, 'metric').isNotEmpty)
              '${l10n.routesMetric} ${_s(v, 'metric')}',
          ].join(' · ')
        : [
            if (_s(v, 'in').isNotEmpty) '${l10n.routesRuleIn} ${_s(v, 'in')}',
            if (_s(v, 'lookup').isNotEmpty)
              '${l10n.routesRuleLookup} ${_s(v, 'lookup')}',
            if (_s(v, 'priority').isNotEmpty)
              '${l10n.routesRulePriority} ${_s(v, 'priority')}',
          ].join(' · ');
    return Container(
      decoration: first
          ? null
          : BoxDecoration(
              border: Border(top: BorderSide(color: divider)),
            ),
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (sub.isNotEmpty)
                  Text(
                    sub,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: muted,
                    ),
                  ),
              ],
            ),
          ),
          QzLegacyIconButton(
            tooltip: l10n.routesDelete,
            onPressed: _busy ? null : () => _delete(l10n, section, title),
            icon: Icon(Icons.delete_outline, size: 19, color: muted),
          ),
        ],
      ),
    );
  }

  String _s(Map<String, dynamic> v, String k) => '${v[k] ?? ''}';

  Future<void> _add(AppL10n l10n, bool route) async {
    final fields = route
        ? [
            ('target', l10n.routesTarget, true),
            ('netmask', l10n.routesNetmask, false),
            ('gateway', l10n.routesGateway, false),
            ('interface', l10n.routesInterface, false),
            ('metric', l10n.routesMetric, false),
          ]
        : [
            ('in', l10n.routesRuleIn, false),
            ('src', l10n.routesRuleSrc, false),
            ('dest', l10n.routesRuleDest, false),
            ('lookup', l10n.routesRuleLookup, false),
            ('priority', l10n.routesRulePriority, false),
          ];
    final result = await _inputDialog(
      route ? l10n.routesAddRoute : l10n.routesAddRule,
      fields,
      l10n.routesHint,
    );
    if (result == null || !mounted) return;
    setState(() => _busy = true);
    final outcome = await applyConfigMutation(
      context,
      ref,
      config: 'network',
      mutate: (client) =>
          client.add('network', route ? 'route' : 'rule', result),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (outcome != null) _load();
  }

  Future<void> _delete(AppL10n l10n, String section, String title) async {
    final ok = await showConfirmSheet(
      context,
      title: '${l10n.routesDelete} · $title',
      body: l10n.routesDeleteBody,
      confirmLabel: l10n.confirm,
      cancelLabel: l10n.cancel,
      danger: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    final outcome = await applyConfigMutation(
      context,
      ref,
      config: 'network',
      mutate: (client) => client.delete('network', section),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (outcome != null) _load();
  }

  Future<Map<String, dynamic>?> _inputDialog(
    String title,
    List<(String, String, bool)> fields,
    String hint,
  ) async {
    final controllers = <String, TextEditingController>{
      for (final f in fields) f.$1: TextEditingController(),
    };
    final result = await showQzSheet<Map<String, String>>(
      context,
      builder: (ctx) {
        final l10n = AppL10n.of(ctx);
        final t = QuartzTokens.of(ctx);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: QuartzType.heroTitle.copyWith(color: t.text),
            ),
            const SizedBox(height: 12),
            for (final f in fields) ...[
              QzField(
                controller: controllers[f.$1],
                label: f.$2,
                keyboardType: f.$1 == 'metric' || f.$1 == 'priority'
                    ? TextInputType.number
                    : TextInputType.text,
              ),
              const SizedBox(height: 10),
            ],
            Text(hint, style: QuartzType.caption.copyWith(color: t.muted)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: QzButton(
                    label: l10n.cancel,
                    kind: QzButtonKind.plain,
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: QzButton(
                    label: l10n.save,
                    onPressed: () {
                      final values = <String, String>{};
                      for (final f in fields) {
                        final v = controllers[f.$1]!.text.trim();
                        if (f.$3 && v.isEmpty) {
                          showQzToast(ctx, l10n.routesRequiredField(f.$2));
                          return;
                        }
                        if (v.isNotEmpty) values[f.$1] = v;
                      }
                      Navigator.of(ctx).pop(values);
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
    for (final c in controllers.values) {
      c.dispose();
    }
    if (result == null) return null;
    return <String, dynamic>{
      for (final e in result.entries)
        e.key: (e.key == 'metric' || e.key == 'priority')
            ? int.tryParse(e.value) ?? e.value
            : e.value,
    };
  }
}

extension _StrExt on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
