// 路由器 · 无线（W6.10）：wireless 的无线电（wifi-device）与接口（wifi-iface）。
//
// 注册表按 device/iface 两段声明（IA v2 §14 结构性结论 2：无线电与接口分开）；
// 读面无类型字段，按已注册键的形状归类。敏感项 `key` 读面为 `__masked__`，
// 未修改时绝不回写（回写掩码会被后端拒绝——这是有意的安全语义）。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/config.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/quartz.dart';
import 'config_common.dart';

class WirelessPage extends ConsumerStatefulWidget {
  const WirelessPage({super.key});

  @override
  ConsumerState<WirelessPage> createState() => _WirelessPageState();
}

class _WirelessPageState extends ConsumerState<WirelessPage> {
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
    final r = await client.read('wireless');
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

  bool _isIface(Map<String, dynamic> v) =>
      v.containsKey('ssid') || v.containsKey('encryption') || v.containsKey('mode') || v.containsKey('network');

  List<String> get _ordered {
    final keys = _sections.keys.toList();
    keys.sort((a, b) {
      final ia = _isIface(_sections[a]!);
      final ib = _isIface(_sections[b]!);
      if (ia != ib) return ia ? 1 : -1;
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
        title: Text(l10n.routerEntryWireless, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
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
                          l10n.wirelessEmpty,
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
                      config: 'wireless',
                      section: section,
                      title: '${_isIface(_sections[section]!) ? l10n.wirelessIface : l10n.wirelessDevice} · $section',
                      subtitle: _subtitle(l10n, _sections[section]!),
                      fields: _fields(l10n, _isIface(_sections[section]!)),
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

  String _subtitle(AppL10n l10n, Map<String, dynamic> v) {
    if (_isIface(v)) {
      final mode = '${v['mode'] ?? ''}';
      final enc = '${v['encryption'] ?? ''}';
      return [
        if (mode.isNotEmpty) '${l10n.wirelessMode}: $mode',
        if (enc.isNotEmpty) '${l10n.wirelessEncryption}: $enc',
      ].join(' · ');
    }
    final band = '${v['band'] ?? ''}';
    final channel = '${v['channel'] ?? ''}';
    return [
      if (band.isNotEmpty) '${l10n.wirelessBand}: $band',
      if (channel.isNotEmpty) '${l10n.wirelessChannel}: $channel',
    ].join(' · ');
  }

  List<ConfigField> _fields(AppL10n l10n, bool iface) {
    if (!iface) {
      return [
        ConfigField('disabled', l10n.interfaceDisabled, kind: ConfigFieldKind.boolean, dangerous: true),
        ConfigField('band', l10n.wirelessBand, kind: ConfigFieldKind.choice, choices: [
          ConfigChoice('2g', '2.4 GHz'),
          ConfigChoice('5g', '5 GHz'),
          ConfigChoice('6g', '6 GHz'),
        ]),
        ConfigField('channel', l10n.wirelessChannel, hint: 'auto / 1 / 6 / 36 …', dangerous: true),
        ConfigField('htmode', l10n.wirelessHtmode, kind: ConfigFieldKind.choice, choices: [
          for (final h in ['HT20', 'HT40', 'VHT20', 'VHT40', 'VHT80', 'VHT160', 'HE20', 'HE40', 'HE80', 'HE160', 'NOHT'])
            ConfigChoice(h, h),
        ]),
        ConfigField('txpower', l10n.wirelessTxpower, kind: ConfigFieldKind.integer),
        ConfigField('country', l10n.wirelessCountry, hint: 'CN / US / …'),
        ConfigField('cell_density', l10n.wirelessCellDensity, kind: ConfigFieldKind.choice, choices: [
          for (var i = 0; i <= 4; i++) ConfigChoice('$i', '$i'),
        ]),
        ConfigField('distance', l10n.wirelessDistance, kind: ConfigFieldKind.integer),
      ];
    }
    return [
      ConfigField('disabled', l10n.interfaceDisabled, kind: ConfigFieldKind.boolean, dangerous: true),
      ConfigField('mode', l10n.wirelessMode, kind: ConfigFieldKind.choice, choices: [
        ConfigChoice('ap', 'AP'),
        ConfigChoice('sta', 'STA'),
        ConfigChoice('mesh', 'Mesh'),
        ConfigChoice('adhoc', 'Ad-Hoc'),
        ConfigChoice('monitor', 'Monitor'),
      ]),
      ConfigField('ssid', l10n.wirelessSsid, dangerous: true),
      ConfigField('encryption', l10n.wirelessEncryption, kind: ConfigFieldKind.choice, choices: [
        for (final e in ['none', 'psk', 'psk2', 'psk-mixed', 'sae', 'sae-mixed', 'wpa', 'wpa2', 'wpa-mixed'])
          ConfigChoice(e, e),
      ]),
      ConfigField('key', l10n.wirelessKey, kind: ConfigFieldKind.secret, sensitive: true, dangerous: true),
      ConfigField('network', l10n.wirelessNetwork, kind: ConfigFieldKind.list, hint: 'lan'),
      ConfigField('hidden', l10n.wirelessHidden, kind: ConfigFieldKind.boolean),
      ConfigField('isolate', l10n.wirelessIsolate, kind: ConfigFieldKind.boolean),
      ConfigField('wmm', l10n.wirelessWmm, kind: ConfigFieldKind.boolean),
    ];
  }
}
