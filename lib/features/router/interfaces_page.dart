// 路由器 · 接口（W6.10）：network.lan / network.wan 的注册表字段。
//
// 注册表（app-api `internal/uciconf/registry.go`）按节完整声明；本页只渲染已注册
// 字段，协议切换时隐藏不相关字段（可见性由 proto 驱动，IA v2 §14 结构性结论 1）。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/config.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/quartz.dart';
import 'config_common.dart';

class InterfacesPage extends ConsumerStatefulWidget {
  const InterfacesPage({super.key});

  @override
  ConsumerState<InterfacesPage> createState() => _InterfacesPageState();
}

class _InterfacesPageState extends ConsumerState<InterfacesPage> {
  bool _loading = true;
  String _error = '';
  Map<String, Map<String, dynamic>> _sections = const {};
  int _epoch = 0;

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
      _epoch++;
    });
  }

  List<String> get _ordered {
    final keys = _sections.keys.toList();
    keys.sort((a, b) {
      int rank(String k) => k == 'lan' ? 0 : (k == 'wan' ? 1 : 2);
      final d = rank(a) - rank(b);
      return d != 0 ? d : a.compareTo(b);
    });
    return keys;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.routerEntryInterfaces, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
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
                  if (!_loading && _error.isEmpty && _sections.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          l10n.configSectionUnavailable,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: .5),
                          ),
                        ),
                      ),
                    ),
                  for (final section in _ordered) ...[
                    ConfigGroupEditor(
                      key: ValueKey('$section-$_epoch'),
                      config: 'network',
                      section: section,
                      title: _title(l10n, section),
                      subtitle: _subtitle(l10n, section),
                      fields: _fields(l10n, section),
                      initial: _sections[section]!,
                      onSaved: _load,
                    ),
                    const SizedBox(height: 4),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
    );
  }

  String _title(AppL10n l10n, String section) => switch (section) {
        'lan' => 'LAN · ${l10n.routerEntryInterfaces}',
        'wan' => 'WAN · ${l10n.routerEntryInterfaces}',
        _ => section,
      };

  String _subtitle(AppL10n l10n, String section) {
    final proto = '${_sections[section]?['proto'] ?? ''}';
    final label = _protoLabel(l10n, proto);
    return label.isEmpty ? '' : '${l10n.interfaceProto}: $label';
  }

  String _protoLabel(AppL10n l10n, String proto) => switch (proto) {
        'static' => l10n.interfaceStatic,
        'dhcp' => l10n.interfaceDhcpClient,
        'pppoe' => l10n.interfacePppoe,
        'none' => l10n.interfaceNone,
        _ => proto,
      };

  List<ConfigField> _fields(AppL10n l10n, String section) {
    final choices = section == 'wan'
        ? [
            ConfigChoice('dhcp', l10n.interfaceDhcpClient),
            ConfigChoice('static', l10n.interfaceStatic),
            ConfigChoice('pppoe', l10n.interfacePppoe),
            ConfigChoice('none', l10n.interfaceNone),
          ]
        : [
            ConfigChoice('static', l10n.interfaceStatic),
            ConfigChoice('dhcp', l10n.interfaceDhcpClient),
            ConfigChoice('none', l10n.interfaceNone),
          ];
    bool staticOnly(Map<String, dynamic> v) => '${v['proto'] ?? 'static'}' == 'static';
    bool pppoeOnly(Map<String, dynamic> v) => '${v['proto'] ?? ''}' == 'pppoe';
    return [
      ConfigField('proto', l10n.interfaceProto, kind: ConfigFieldKind.choice, choices: choices),
      ConfigField('device', l10n.interfaceDevice, hint: 'eth0 / eth1'),
      ConfigField('disabled', l10n.interfaceDisabled, kind: ConfigFieldKind.boolean, dangerous: true),
      if (section == 'wan')
        ConfigField('auto', l10n.interfaceAuto, kind: ConfigFieldKind.boolean),
      ConfigField('ipaddr', l10n.interfaceIpaddr, dangerous: true, visibleWhen: staticOnly),
      ConfigField('netmask', l10n.interfaceNetmask, dangerous: true, visibleWhen: staticOnly),
      ConfigField('gateway', l10n.interfaceGateway, dangerous: true, visibleWhen: staticOnly),
      ConfigField('dns', l10n.interfaceDns, kind: ConfigFieldKind.list, hint: l10n.interfaceDnsHint,
          visibleWhen: (v) => staticOnly(v) || pppoeOnly(v)),
      ConfigField('ip6addr', l10n.interfaceIp6addr, kind: ConfigFieldKind.list,
          hint: l10n.interfaceIp6Hint, visibleWhen: staticOnly),
      ConfigField('ip6assign', l10n.interfaceIp6assign, kind: ConfigFieldKind.integer,
          visibleWhen: staticOnly),
      if (section == 'wan') ...[
        ConfigField('username', l10n.interfaceUsername, visibleWhen: pppoeOnly),
        ConfigField('password', l10n.interfacePassword, kind: ConfigFieldKind.secret,
            sensitive: true, visibleWhen: pppoeOnly),
      ],
    ];
  }
}
