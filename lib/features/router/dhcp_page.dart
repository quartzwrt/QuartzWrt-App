// 路由器 · DHCP 与 DNS（W6.10）：dhcp 配置的 dnsmasq 段与 dhcp 段。
//
// 静态租约（config host 增删）尚未注册（W6.11）；本页只做已注册字段。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/config.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/quartz.dart';
import 'config_common.dart';

class DhcpPage extends ConsumerStatefulWidget {
  const DhcpPage({super.key});

  @override
  ConsumerState<DhcpPage> createState() => _DhcpPageState();
}

class _DhcpPageState extends ConsumerState<DhcpPage> {
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
    final r = await client.read('dhcp');
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

  bool _isDnsmasq(String name, Map<String, dynamic> v) {
    if (name.contains('dnsmasq')) return true;
    return v.containsKey('domainneeded') ||
        v.containsKey('boguspriv') ||
        v.containsKey('authoritative') ||
        v.containsKey('rebind_protection') ||
        v.containsKey('cachesize') ||
        v.containsKey('logqueries');
  }

  List<String> get _ordered {
    final keys = _sections.keys.toList();
    keys.sort((a, b) {
      final da = _isDnsmasq(a, _sections[a]!);
      final db = _isDnsmasq(b, _sections[b]!);
      if (da != db) return da ? -1 : 1;
      return a.compareTo(b);
    });
    return keys;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.routerEntryDhcp, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
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
                          l10n.dhcpEmpty,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: .5),
                          ),
                        ),
                      ),
                    ),
                  for (final section in _ordered) ...[
                    ConfigGroupEditor(
                      key: ValueKey('$section-$_epoch'),
                      config: 'dhcp',
                      section: section,
                      title: _isDnsmasq(section, _sections[section]!)
                          ? l10n.dhcpDnsmasq
                          : '${l10n.dhcpServer} · $section',
                      subtitle: _isDnsmasq(section, _sections[section]!) ? section : l10n.dhcpServerHint,
                      fields: _fields(l10n, _isDnsmasq(section, _sections[section]!)),
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

  List<ConfigField> _fields(AppL10n l10n, bool dnsmasq) {
    if (dnsmasq) {
      return [
        ConfigField('domain', l10n.dhcpDomain),
        ConfigField('local', l10n.dhcpLocal),
        ConfigField('domainneeded', l10n.dhcpDomainNeeded, kind: ConfigFieldKind.boolean),
        ConfigField('boguspriv', l10n.dhcpBogusPriv, kind: ConfigFieldKind.boolean),
        ConfigField('authoritative', l10n.dhcpAuthoritative, kind: ConfigFieldKind.boolean),
        ConfigField('localservice', l10n.dhcpLocalService, kind: ConfigFieldKind.boolean),
        ConfigField('rebind_protection', l10n.dhcpRebindProtection, kind: ConfigFieldKind.boolean),
        ConfigField('expandhosts', l10n.dhcpExpandHosts, kind: ConfigFieldKind.boolean),
        ConfigField('cachesize', l10n.dhcpCacheSize, kind: ConfigFieldKind.integer),
        ConfigField('logqueries', l10n.dhcpLogQueries, kind: ConfigFieldKind.boolean),
      ];
    }
    return [
      ConfigField('start', l10n.dhcpStart, kind: ConfigFieldKind.integer, dangerous: true),
      ConfigField('limit', l10n.dhcpLimit, kind: ConfigFieldKind.integer, dangerous: true),
      ConfigField('leasetime', l10n.dhcpLeasetime, hint: '12h / 30m / infinite'),
      ConfigField('ignore', l10n.dhcpIgnore, kind: ConfigFieldKind.boolean, dangerous: true),
      ConfigField('dynamicdhcp', l10n.dhcpDynamicDhcp, kind: ConfigFieldKind.boolean),
      ConfigField('force', l10n.dhcpForce, kind: ConfigFieldKind.boolean),
      ConfigField('ra', l10n.dhcpRa, kind: ConfigFieldKind.choice, choices: [
        ConfigChoice('disabled', l10n.initDisable),
        ConfigChoice('server', 'Server'),
        ConfigChoice('relay', 'Relay'),
        ConfigChoice('hybrid', 'Hybrid'),
      ]),
      ConfigField('ra_management', l10n.dhcpRaManagement, kind: ConfigFieldKind.choice, choices: [
        ConfigChoice('0', '0'),
        ConfigChoice('1', '1'),
        ConfigChoice('2', '2'),
      ]),
      ConfigField('dhcpv6', l10n.dhcpDhcpv6, kind: ConfigFieldKind.choice, choices: [
        ConfigChoice('disabled', l10n.initDisable),
        ConfigChoice('server', 'Server'),
        ConfigChoice('relay', 'Relay'),
        ConfigChoice('hybrid', 'Hybrid'),
      ]),
      ConfigField('master', l10n.dhcpMaster, kind: ConfigFieldKind.boolean),
      ConfigField('dns_service', l10n.dhcpDnsService, kind: ConfigFieldKind.boolean),
    ];
  }
}
