// 路由器 · DHCP 与 DNS（W6.10）：dhcp 配置的 dnsmasq 段与 dhcp 段
// + 静态租约（W6.11，config host 增删；add/delete → apply/confirm）。
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

  bool _isHost(Map<String, dynamic> v) =>
      v.containsKey('mac') && (v.containsKey('name') || v.containsKey('ip'));

  List<String> get _hostSections {
    final keys = _sections.keys.where((k) => _isHost(_sections[k]!)).toList();
    keys.sort((a, b) {
      final na = (_sections[a]!['name'] as String?) ?? a;
      final nb = (_sections[b]!['name'] as String?) ?? b;
      return na.compareTo(nb);
    });
    return keys;
  }

  List<String> get _ordered {
    final keys = _sections.keys.where((k) => !_isHost(_sections[k]!)).toList();
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
                  _staticLeasesCard(context, l10n),
                  const SizedBox(height: 12),
                ],
              ),
            ),
    );
  }

  Widget _staticLeasesCard(BuildContext context, AppL10n l10n) {
    final theme = Theme.of(context);
    final hosts = _hostSections;
    return QuartzCard(
      title: l10n.dhcpStaticLeases,
      trailing: IconButton(
        tooltip: l10n.dhcpAddLease,
        onPressed: () => _addLease(l10n),
        icon: const Icon(Icons.add, size: 20),
      ),
      child: hosts.isEmpty
          ? Text(
              l10n.dhcpNoLeases,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: .5),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, section) in hosts.indexed)
                  _leaseRow(context, l10n, section, first: i == 0),
              ],
            ),
    );
  }

  Widget _leaseRow(BuildContext context, AppL10n l10n, String section, {required bool first}) {
    final theme = Theme.of(context);
    final v = _sections[section] ?? const <String, dynamic>{};
    final name = (v['name'] as String?)?.trim() ?? '';
    final mac = (v['mac'] as String?) ?? '';
    final ip = (v['ip'] as String?) ?? '';
    final muted = theme.colorScheme.onSurface.withValues(alpha: .5);
    final divider = theme.brightness == Brightness.dark ? const Color(0x14FFFFFF) : const Color(0x11000000);
    return Container(
      decoration: first ? null : BoxDecoration(border: Border(top: BorderSide(color: divider))),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.isEmpty ? mac : name,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 1),
                Text(
                  [mac, if (ip.isNotEmpty) ip].join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: muted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.dhcpDeleteLease,
            onPressed: () => _deleteLease(l10n, section, name),
            icon: Icon(Icons.delete_outline, size: 19, color: muted),
          ),
        ],
      ),
    );
  }

  Future<void> _addLease(AppL10n l10n) async {
    final name = TextEditingController();
    final mac = TextEditingController();
    final ip = TextEditingController();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.dhcpAddLease),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: InputDecoration(labelText: l10n.dhcpLeaseName),
              ),
              TextField(
                controller: mac,
                decoration: InputDecoration(labelText: l10n.dhcpLeaseMac),
                autocorrect: false,
              ),
              TextField(
                controller: ip,
                decoration: InputDecoration(labelText: l10n.dhcpLeaseIp),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 6),
              Text(l10n.dhcpLeaseHint,
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: .5),
                      )),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () {
              final m = mac.text.trim();
              if (!RegExp(r'^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$').hasMatch(m)) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(l10n.dhcpLeaseInvalidMac)));
                return;
              }
              final values = <String, String>{'name': name.text.trim(), 'mac': m, 'ip': ip.text.trim()};
              Navigator.of(ctx).pop(values);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    name.dispose();
    mac.dispose();
    ip.dispose();
    if (result == null || !mounted) return;
    final values = <String, dynamic>{'mac': result['mac']!};
    if ((result['name'] ?? '').isNotEmpty) values['name'] = result['name']!;
    if ((result['ip'] ?? '').isNotEmpty) values['ip'] = result['ip']!;
    final outcome = await applyConfigMutation(
      context,
      ref,
      config: 'dhcp',
      mutate: (client) => client.add('dhcp', 'host', values),
    );
    if (outcome != null) _load();
  }

  Future<void> _deleteLease(AppL10n l10n, String section, String name) async {
    final ok = await showConfirmSheet(
      context,
      title: '${l10n.dhcpDeleteLease} · ${name.isEmpty ? section : name}',
      body: l10n.dhcpDeleteLeaseBody,
      confirmLabel: l10n.confirm,
      cancelLabel: l10n.cancel,
      danger: true,
    );
    if (!ok || !mounted) return;
    final outcome = await applyConfigMutation(
      context,
      ref,
      config: 'dhcp',
      mutate: (client) => client.delete('dhcp', section),
    );
    if (outcome != null) _load();
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
