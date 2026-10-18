// 路由器 · 防火墙（W6.11）：defaults / zone / forwarding / rule / redirect。
//
// 读 = config.read firewall；改 = config.write/add/delete → apply(rollback,90s) →
// 确认条。字段面与 app-api `firewall` 注册表一致；未注册的高级原语仍走网页端。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/config.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/quartz.dart';
import 'config_common.dart';

enum _FwKind { defaults, zone, forwarding, rule, redirect }

class FirewallPage extends ConsumerStatefulWidget {
  const FirewallPage({super.key});

  @override
  ConsumerState<FirewallPage> createState() => _FirewallPageState();
}

class _FirewallPageState extends ConsumerState<FirewallPage> {
  bool _loading = true;
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
    final r = await client.read('firewall');
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

  _FwKind _kindOf(String key, Map<String, dynamic> v) {
    if (key.contains('defaults')) return _FwKind.defaults;
    if (key.contains('zone')) return _FwKind.zone;
    if (key.contains('redirect')) return _FwKind.redirect;
    if (key.contains('forward')) return _FwKind.forwarding;
    if (key.contains('rule')) return _FwKind.rule;
    // 命名节回退：按字段形状推断
    if (v.containsKey('src_dport') || (v.containsKey('dest_ip') && v.containsKey('dest_port'))) {
      return _FwKind.redirect;
    }
    if (v.containsKey('src') && v.containsKey('dest') && !v.containsKey('proto') &&
        !v.containsKey('dest_port') && !v.containsKey('target')) {
      return _FwKind.forwarding;
    }
    if (v.containsKey('target') || v.containsKey('proto') || v.containsKey('dest_port')) {
      return _FwKind.rule;
    }
    if (v.containsKey('input') && v.containsKey('output') && v.containsKey('forward') &&
        !v.containsKey('name')) {
      return _FwKind.defaults;
    }
    return _FwKind.zone;
  }

  List<String> _keys(_FwKind kind) {
    final keys = <String>[];
    for (final e in _sections.entries) {
      if (_kindOf(e.key, e.value) == kind) keys.add(e.key);
    }
    keys.sort((a, b) => a.compareTo(b));
    return keys;
  }

  String _s(Map<String, dynamic> v, String k) {
    final x = v[k];
    if (x == null) return '';
    if (x is List) return x.map((e) => '$e').join(' ');
    return '$x';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    final defaults = _keys(_FwKind.defaults);
    final zones = _keys(_FwKind.zone);
    final forwards = _keys(_FwKind.forwarding);
    final rules = _keys(_FwKind.rule);
    final redirects = _keys(_FwKind.redirect);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.routerEntryFirewall, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: l10n.refresh,
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (_error.isNotEmpty) ...[
                    InfoBanner(title: l10n.configLoadFailedTitle, body: _error),
                    const SizedBox(height: 4),
                  ],
                  if (defaults.isNotEmpty)
                    ConfigGroupEditor(
                      config: 'firewall',
                      section: defaults.first,
                      title: l10n.firewallDefaults,
                      fields: _defaultsFields(l10n),
                      initial: _sections[defaults.first] ?? const {},
                      onSaved: _load,
                    ),
                  const SizedBox(height: 4),
                  _sectionCard(
                    l10n,
                    kind: _FwKind.zone,
                    title: l10n.firewallZones,
                    keys: zones,
                    empty: l10n.firewallEmptyZones,
                    addLabel: l10n.firewallAddZone,
                    deletable: false,
                  ),
                  const SizedBox(height: 4),
                  _sectionCard(
                    l10n,
                    kind: _FwKind.forwarding,
                    title: l10n.firewallForwards,
                    keys: forwards,
                    empty: l10n.firewallEmptyForwards,
                    addLabel: l10n.firewallAddForward,
                    deletable: true,
                  ),
                  const SizedBox(height: 4),
                  _sectionCard(
                    l10n,
                    kind: _FwKind.rule,
                    title: l10n.firewallRules,
                    keys: rules,
                    empty: l10n.firewallEmptyRules,
                    addLabel: l10n.firewallAddRule,
                    deletable: true,
                  ),
                  const SizedBox(height: 4),
                  _sectionCard(
                    l10n,
                    kind: _FwKind.redirect,
                    title: l10n.firewallRedirects,
                    keys: redirects,
                    empty: l10n.firewallEmptyRedirects,
                    addLabel: l10n.firewallAddRedirect,
                    deletable: true,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 12, 4, 20),
                    child: Text(
                      l10n.firewallHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: .45),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionCard(
    AppL10n l10n, {
    required _FwKind kind,
    required String title,
    required List<String> keys,
    required String empty,
    required String addLabel,
    required bool deletable,
  }) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: .5);
    return QuartzCard(
      title: title,
      trailing: IconButton(
        tooltip: addLabel,
        onPressed: _loading ? null : () => _add(kind),
        icon: const Icon(Icons.add, size: 20),
      ),
      child: keys.isEmpty
          ? Text(empty, style: theme.textTheme.bodySmall?.copyWith(color: muted))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, key) in keys.indexed)
                  _row(key, _sections[key] ?? const {}, kind: kind, first: i == 0, deletable: deletable),
              ],
            ),
    );
  }

  Widget _row(String key, Map<String, dynamic> v, {required _FwKind kind, required bool first, required bool deletable}) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: .5);
    final divider = theme.brightness == Brightness.dark ? const Color(0x14FFFFFF) : const Color(0x11000000);
    final (title, sub) = _summary(kind, key, v);
    return Container(
      decoration: first ? null : BoxDecoration(border: Border(top: BorderSide(color: divider))),
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _edit(kind, key, v),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    if (sub.isNotEmpty)
                      Text(sub, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: muted)),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: l10n.firewallEdit,
              onPressed: () => _edit(kind, key, v),
              icon: Icon(Icons.edit_outlined, size: 19, color: muted),
            ),
            if (deletable)
              IconButton(
                tooltip: l10n.firewallDelete,
                onPressed: () => _delete(key, title),
                icon: Icon(Icons.delete_outline, size: 19, color: muted),
              ),
          ],
        ),
      ),
    );
  }

  (String, String) _summary(_FwKind kind, String key, Map<String, dynamic> v) {
    final l10n = AppL10n.of(context);
    switch (kind) {
      case _FwKind.defaults:
        return (l10n.firewallDefaults, '');
      case _FwKind.zone:
        final name = _s(v, 'name');
        final net = _s(v, 'network');
        final pol = '${_s(v, 'input')}/${_s(v, 'output')}/${_s(v, 'forward')}';
        final masq = configBool(v['masq']) ? ' · ${l10n.firewallMasq}' : '';
        return (name.isEmpty ? key : name, [if (net.isNotEmpty) net, pol, if (masq.isNotEmpty) masq.substring(3)].join(' · '));
      case _FwKind.forwarding:
        return ('${_s(v, 'src')} → ${_s(v, 'dest')}',
            configBool(v['enabled']) || !v.containsKey('enabled') ? '' : l10n.firewallDisabled);
      case _FwKind.rule:
        final name = _s(v, 'name');
        final title = name.isEmpty ? '${_s(v, 'src')} → ${_s(v, 'dest')}' : name;
        final parts = [
          if (_s(v, 'proto').isNotEmpty) _s(v, 'proto'),
          if (_s(v, 'dest_port').isNotEmpty) '${l10n.firewallDestPort} ${_s(v, 'dest_port')}',
          if (_s(v, 'target').isNotEmpty) _s(v, 'target'),
          if (v.containsKey('enabled') && !configBool(v['enabled'])) l10n.firewallDisabled,
        ];
        return (title, parts.join(' · '));
      case _FwKind.redirect:
        final name = _s(v, 'name');
        final src = '${_s(v, 'src')}${_s(v, 'src_dport').isNotEmpty ? ':${_s(v, 'src_dport')}' : ''}';
        final dest = '${_s(v, 'dest_ip')}${_s(v, 'dest_port').isNotEmpty ? ':${_s(v, 'dest_port')}' : ''}';
        final title = name.isEmpty ? '$src → $dest' : name;
        final parts = [
          if (_s(v, 'proto').isNotEmpty) _s(v, 'proto'),
          if (_s(v, 'target').isNotEmpty) _s(v, 'target'),
          if (v.containsKey('enabled') && !configBool(v['enabled'])) l10n.firewallDisabled,
        ];
        return (title, parts.join(' · '));
    }
  }

  Future<void> _edit(_FwKind kind, String key, Map<String, dynamic> v) async {
    final l10n = AppL10n.of(context);
    final fields = _fields(l10n, kind);
    final danger = kind == _FwKind.zone;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E2024) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => FractionallySizedBox(
        heightFactor: .92,
        child: ConfigSectionSheet(
          title: _summary(kind, key, v).$1,
          config: 'firewall',
          section: key,
          addType: _typeName(kind),
          fields: fields,
          initial: v,
          danger: danger,
          dangerBody: danger ? l10n.firewallZoneWarning : null,
        ),
      ),
    );
    if (saved == true && mounted) _load();
  }

  Future<void> _add(_FwKind kind) async {
    final l10n = AppL10n.of(context);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E2024) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => FractionallySizedBox(
        heightFactor: .92,
        child: ConfigSectionSheet(
          title: _addTitle(l10n, kind),
          config: 'firewall',
          section: null,
          addType: _typeName(kind),
          fields: _fields(l10n, kind),
          initial: _addDefaults(kind),
          danger: kind == _FwKind.zone,
          dangerBody: kind == _FwKind.zone ? l10n.firewallZoneWarning : null,
        ),
      ),
    );
    if (saved == true && mounted) _load();
  }

  String _typeName(_FwKind kind) => switch (kind) {
        _FwKind.zone => 'zone',
        _FwKind.forwarding => 'forwarding',
        _FwKind.rule => 'rule',
        _FwKind.redirect => 'redirect',
        _FwKind.defaults => 'defaults',
      };

  String _addTitle(AppL10n l10n, _FwKind kind) => switch (kind) {
        _FwKind.zone => l10n.firewallAddZone,
        _FwKind.forwarding => l10n.firewallAddForward,
        _FwKind.rule => l10n.firewallAddRule,
        _FwKind.redirect => l10n.firewallAddRedirect,
        _FwKind.defaults => l10n.firewallDefaults,
      };

  Map<String, dynamic> _addDefaults(_FwKind kind) => switch (kind) {
        _FwKind.zone => {'input': 'ACCEPT', 'output': 'ACCEPT', 'forward': 'ACCEPT', 'enabled': true},
        _FwKind.forwarding => {'enabled': true},
        _FwKind.rule => {'target': 'ACCEPT', 'proto': 'tcp', 'family': 'any', 'enabled': true},
        _FwKind.redirect => {'target': 'DNAT', 'proto': 'tcp', 'family': 'ipv4', 'enabled': true},
        _FwKind.defaults => const {},
      };

  Future<void> _delete(String key, String title) async {
    final l10n = AppL10n.of(context);
    final outcome = await applyConfigMutation(
      context,
      ref,
      config: 'firewall',
      danger: true,
      dangerBody: l10n.firewallDeleteBody(title),
      mutate: (client) => client.delete('firewall', key),
    );
    if (outcome != null && mounted) _load();
  }

  // ---- 字段面（与 app-api firewall 注册表一致） ----

  List<ConfigField> _fields(AppL10n l10n, _FwKind kind) => switch (kind) {
        _FwKind.defaults => _defaultsFields(l10n),
        _FwKind.zone => _zoneFields(l10n),
        _FwKind.forwarding => _forwardingFields(l10n),
        _FwKind.rule => _ruleFields(l10n),
        _FwKind.redirect => _redirectFields(l10n),
      };

  List<ConfigField> _defaultsFields(AppL10n l10n) => [
        _policy(l10n.firewallInput, 'input'),
        _policy(l10n.firewallOutput, 'output'),
        _policy(l10n.firewallForward, 'forward'),
        ConfigField('syn_flood', l10n.firewallSynFlood, kind: ConfigFieldKind.boolean),
        ConfigField('fullcone', l10n.firewallFullcone, kind: ConfigFieldKind.boolean),
        ConfigField('flow_offloading', l10n.firewallFlowOffloading, kind: ConfigFieldKind.boolean),
        ConfigField('flow_offloading_hw', l10n.firewallFlowOffloadingHw, kind: ConfigFieldKind.boolean),
      ];

  List<ConfigField> _zoneFields(AppL10n l10n) => [
        ConfigField('name', l10n.firewallName, dangerous: true),
        ConfigField('network', l10n.firewallNetwork, kind: ConfigFieldKind.list, dangerous: true),
        ConfigField('device', l10n.firewallDevice),
        _policy(l10n.firewallInput, 'input'),
        _policy(l10n.firewallOutput, 'output'),
        _policy(l10n.firewallForward, 'forward'),
        ConfigField('masq', l10n.firewallMasq, kind: ConfigFieldKind.boolean),
        ConfigField('mtu_fix', l10n.firewallMtuFix, kind: ConfigFieldKind.boolean),
        ConfigField('enabled', l10n.firewallEnabled, kind: ConfigFieldKind.boolean),
        ConfigField('log', l10n.firewallLog, kind: ConfigFieldKind.boolean),
        _family(l10n),
      ];

  List<ConfigField> _forwardingFields(AppL10n l10n) => [
        ConfigField('src', l10n.firewallSrc, dangerous: true),
        ConfigField('dest', l10n.firewallDest, dangerous: true),
        ConfigField('enabled', l10n.firewallEnabled, kind: ConfigFieldKind.boolean),
      ];

  List<ConfigField> _ruleFields(AppL10n l10n) => [
        ConfigField('name', l10n.firewallName),
        ConfigField('enabled', l10n.firewallEnabled, kind: ConfigFieldKind.boolean),
        ConfigField('src', l10n.firewallSrc),
        ConfigField('dest', l10n.firewallDest),
        ConfigField('proto', l10n.firewallProto, kind: ConfigFieldKind.list),
        ConfigField('src_ip', l10n.firewallSrcIp),
        ConfigField('dest_ip', l10n.firewallDestIp),
        ConfigField('src_port', l10n.firewallSrcPort),
        ConfigField('dest_port', l10n.firewallDestPort),
        ConfigField('target', l10n.firewallTarget, kind: ConfigFieldKind.choice, choices: [
          ConfigChoice('ACCEPT', l10n.firewallAccept),
          ConfigChoice('REJECT', l10n.firewallReject),
          ConfigChoice('DROP', l10n.firewallDrop),
          ConfigChoice('MARK', l10n.firewallMark),
        ]),
        _family(l10n),
        ConfigField('log', l10n.firewallLog, kind: ConfigFieldKind.boolean),
      ];

  List<ConfigField> _redirectFields(AppL10n l10n) => [
        ConfigField('name', l10n.firewallName),
        ConfigField('enabled', l10n.firewallEnabled, kind: ConfigFieldKind.boolean),
        ConfigField('src', l10n.firewallSrc, dangerous: true),
        ConfigField('src_dport', l10n.firewallDport),
        ConfigField('dest', l10n.firewallDest, dangerous: true),
        ConfigField('dest_ip', l10n.firewallDestIp),
        ConfigField('dest_port', l10n.firewallDestPort),
        ConfigField('proto', l10n.firewallProto, kind: ConfigFieldKind.list),
        ConfigField('target', l10n.firewallTarget, kind: ConfigFieldKind.choice, choices: [
          ConfigChoice('DNAT', l10n.firewallDnat),
          ConfigChoice('SNAT', l10n.firewallSnat),
          ConfigChoice('ACCEPT', l10n.firewallAccept),
          ConfigChoice('REJECT', l10n.firewallReject),
          ConfigChoice('DROP', l10n.firewallDrop),
        ]),
        _family(l10n),
        ConfigField('reflection', l10n.firewallReflection, kind: ConfigFieldKind.boolean),
      ];

  ConfigField _policy(String label, String option) => ConfigField(option, label,
      kind: ConfigFieldKind.choice,
      choices: [
        ConfigChoice('ACCEPT', AppL10n.of(context).firewallAccept),
        ConfigChoice('REJECT', AppL10n.of(context).firewallReject),
        ConfigChoice('DROP', AppL10n.of(context).firewallDrop),
      ]);

  ConfigField _family(AppL10n l10n) => ConfigField('family', l10n.firewallFamily,
      kind: ConfigFieldKind.choice,
      choices: [
        ConfigChoice('any', l10n.firewallAny),
        ConfigChoice('ipv4', l10n.firewallIpv4),
        ConfigChoice('ipv6', l10n.firewallIpv6),
      ]);
}
