// 路由器 · LED 配置（W6.11）：system 配置的 @led 节 + 当前 sysfs LED 列表。
import 'package:flutter/material.dart';

import '../../core/theme.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/config.dart';
import '../../api/luci.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/quartz.dart';
import 'config_common.dart';

class LedPage extends ConsumerStatefulWidget {
  const LedPage({super.key});

  @override
  ConsumerState<LedPage> createState() => _LedPageState();
}

class _LedPageState extends ConsumerState<LedPage> {
  bool _loading = true;
  String _error = '';
  Map<String, Map<String, dynamic>> _sections = const {};
  Map<String, dynamic> _available = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final client = ref.read(configClientProvider);
    final luci = ref.read(luciClientProvider);
    if (client == null) return;
    setState(() {
      _loading = true;
      _error = '';
    });
    final r = await client.read('system');
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
      if (v is Map<String, dynamic> && _isLed(e.key, v)) sections[e.key] = v;
    }
    var available = <String, dynamic>{};
    if (luci != null) {
      final l = await luci.leds();
      if (!mounted) return;
      if (l.ok) {
        // getLEDs 返回裸对象（不是 {result:…}）；兼容两种形态。
        final raw = l.map['result'];
        available = raw is Map<String, dynamic> ? raw : l.map;
      }
    }
    setState(() {
      _sections = sections;
      _available = available;
      _loading = false;
    });
  }

  bool _isLed(String key, Map<String, dynamic> v) =>
      key.contains('led') || v.containsKey('sysfs') || v.containsKey('trigger');

  List<String> get _keys {
    final out = _sections.keys.toList()..sort();
    return out;
  }

  String _s(Map<String, dynamic> v, String k) => '${v[k] ?? ''}';
  String _or(String v, String fallback) => v.isEmpty ? fallback : v;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: .5);
    final keys = _keys;
    return Scaffold(
      appBar: QzAppBar(
        title: Text(
          l10n.routerEntryLed,
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
                  QuartzCard(
                    title: l10n.ledsAvailable,
                    child: _available.isEmpty
                        ? Text(
                            l10n.ledsEmptyAvailable,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: muted,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final (i, e) in _available.entries.indexed)
                                _availableRow(e.key, e.value, first: i == 0),
                            ],
                          ),
                  ),
                  const SizedBox(height: 4),
                  QuartzCard(
                    title: l10n.ledsConfigured,
                    trailing: QzLegacyIconButton(
                      tooltip: l10n.ledsAdd,
                      onPressed: _loading ? null : _add,
                      icon: const Icon(Icons.add, size: 20),
                    ),
                    child: keys.isEmpty
                        ? Text(
                            l10n.ledsEmpty,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: muted,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final (i, key) in keys.indexed)
                                _configRow(
                                  key,
                                  _sections[key] ?? const {},
                                  first: i == 0,
                                ),
                            ],
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 12, 4, 20),
                    child: Text(
                      l10n.ledsHint,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _availableRow(String name, dynamic raw, {required bool first}) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: .5);
    final divider = QuartzTokens.of(context).border;
    final v = raw is Map ? raw : const {};
    final active = '${v['active_trigger'] ?? ''}';
    final triggers = v['triggers'];
    final count = triggers is List ? triggers.length : 0;
    return Container(
      decoration: first
          ? null
          : BoxDecoration(
              border: Border(top: BorderSide(color: divider)),
            ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            active.isEmpty ? '$count triggers' : '$active · $count',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _configRow(String key, Map<String, dynamic> v, {required bool first}) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: .5);
    final divider = QuartzTokens.of(context).border;
    final title = _or(_s(v, 'name'), _or(_s(v, 'sysfs'), key));
    final sub = [
      if (_s(v, 'sysfs').isNotEmpty) _s(v, 'sysfs'),
      if (_s(v, 'trigger').isNotEmpty) _s(v, 'trigger'),
      if (v.containsKey('default') && !configBool(v['default']))
        l10n.firewallDisabled,
    ].join(' · ');
    return Container(
      decoration: first
          ? null
          : BoxDecoration(
              border: Border(top: BorderSide(color: divider)),
            ),
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: QzPressable(
        highlight: true,
        borderRadius: BorderRadius.circular(8),
        onTap: () => _edit(key, v),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (sub.isNotEmpty)
                      Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: muted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            QzLegacyIconButton(
              tooltip: l10n.firewallEdit,
              onPressed: () => _edit(key, v),
              icon: Icon(Icons.edit_outlined, size: 19, color: muted),
            ),
            QzLegacyIconButton(
              tooltip: l10n.firewallDelete,
              onPressed: () => _delete(key, title),
              icon: Icon(Icons.delete_outline, size: 19, color: muted),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(String key, Map<String, dynamic> v) async {
    final saved = await _sheet(
      title: _or(_s(v, 'name'), key),
      section: key,
      initial: v,
    );
    if (saved == true && mounted) _load();
  }

  Future<void> _add() async {
    final l10n = AppL10n.of(context);
    final saved = await _sheet(
      title: l10n.ledsAdd,
      section: null,
      initial: {'default': true},
    );
    if (saved == true && mounted) _load();
  }

  Future<bool?> _sheet({
    required String title,
    required String? section,
    required Map<String, dynamic> initial,
  }) {
    final l10n = AppL10n.of(context);
    return showQzSheet<bool>(
      context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => FractionallySizedBox(
        heightFactor: .92,
        child: ConfigSectionSheet(
          title: title,
          config: 'system',
          section: section,
          addType: 'led',
          fields: _fields(l10n),
          initial: initial,
        ),
      ),
    );
  }

  Future<void> _delete(String key, String title) async {
    final l10n = AppL10n.of(context);
    final outcome = await applyConfigMutation(
      context,
      ref,
      config: 'system',
      danger: true,
      dangerBody: l10n.ledsDeleteBody(title),
      mutate: (client) => client.delete('system', key),
    );
    if (outcome != null && mounted) _load();
  }

  List<ConfigField> _fields(AppL10n l10n) => [
    ConfigField('name', l10n.ledsName),
    ConfigField('sysfs', l10n.ledsSysfs),
    ConfigField('trigger', l10n.ledsTrigger),
    ConfigField('default', l10n.ledsDefault, kind: ConfigFieldKind.boolean),
    ConfigField('dev', l10n.ledsDev),
    ConfigField(
      'interval',
      l10n.ledsInterval,
      kind: ConfigFieldKind.integer,
      min: 0,
      max: 10000,
    ),
    ConfigField(
      'delayon',
      l10n.ledsDelayOn,
      kind: ConfigFieldKind.integer,
      min: 0,
      max: 10000,
    ),
    ConfigField(
      'delayoff',
      l10n.ledsDelayOff,
      kind: ConfigFieldKind.integer,
      min: 0,
      max: 10000,
    ),
  ];
}
