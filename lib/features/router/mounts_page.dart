// 路由器 · 挂载点（W6.11）：fstab 配置 + 当前挂载（luci.getMountPoints）。
//
// 配置编辑/增删走 config.*（fstab global/mount/swap），当前挂载为只读运行时视图。
import 'package:flutter/material.dart';

import '../../core/theme.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/config.dart';
import '../../api/luci.dart';
import '../../format.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/quartz.dart';
import 'config_common.dart';

class MountsPage extends ConsumerStatefulWidget {
  const MountsPage({super.key});

  @override
  ConsumerState<MountsPage> createState() => _MountsPageState();
}

class _MountsPageState extends ConsumerState<MountsPage> {
  bool _loading = true;
  String _error = '';
  Map<String, Map<String, dynamic>> _sections = const {};
  List<Map<String, dynamic>> _current = const [];

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
    final r = await client.read('fstab');
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
    var current = <Map<String, dynamic>>[];
    if (luci != null) {
      final m = await luci.mounts();
      if (!mounted) return;
      final list = m.map['result'];
      if (m.ok && list is List) {
        current = [
          for (final x in list)
            if (x is Map) Map<String, dynamic>.from(x),
        ];
      }
    }
    setState(() {
      _sections = sections;
      _current = current;
      _loading = false;
    });
  }

  bool _isGlobal(String key, Map<String, dynamic> v) =>
      key.contains('global') ||
      v.containsKey('auto_mount') ||
      v.containsKey('anon_mount');
  bool _isSwap(String key, Map<String, dynamic> v) =>
      key.contains('swap') ||
      (v.containsKey('device') && !v.containsKey('target'));

  List<String> _keys(bool swap) {
    final out = <String>[];
    for (final e in _sections.entries) {
      if (_isGlobal(e.key, e.value)) continue;
      if (_isSwap(e.key, e.value) == swap) out.add(e.key);
    }
    out.sort((a, b) => a.compareTo(b));
    return out;
  }

  String _s(Map<String, dynamic> v, String k) => '${v[k] ?? ''}';
  String _or(String v, String fallback) => v.isEmpty ? fallback : v;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    final globalKey = _sections.keys.cast<String?>().firstWhere(
      (k) => _isGlobal(k!, _sections[k]!),
      orElse: () => null,
    );
    final mounts = _keys(false);
    final swaps = _keys(true);
    return Scaffold(
      appBar: QzAppBar(
        title: Text(
          l10n.routerEntryMounts,
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
                  _currentCard(l10n),
                  const SizedBox(height: 4),
                  _configCard(
                    l10n,
                    title: l10n.mountsConfigured,
                    empty: l10n.mountsEmptyMounts,
                    addLabel: l10n.mountsAddMount,
                    keys: mounts,
                    swap: false,
                  ),
                  const SizedBox(height: 4),
                  _configCard(
                    l10n,
                    title: l10n.mountsSwaps,
                    empty: l10n.mountsEmptySwaps,
                    addLabel: l10n.mountsAddSwap,
                    keys: swaps,
                    swap: true,
                  ),
                  const SizedBox(height: 4),
                  if (globalKey != null)
                    ConfigGroupEditor(
                      config: 'fstab',
                      section: globalKey,
                      title: l10n.mountsGlobal,
                      fields: _globalFields(l10n),
                      initial: _sections[globalKey] ?? const {},
                      onSaved: _load,
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 12, 4, 20),
                    child: Text(
                      l10n.mountsHint,
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

  Widget _currentCard(AppL10n l10n) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: .5);
    return QuartzCard(
      title: l10n.mountsCurrent,
      child: _current.isEmpty
          ? Text(
              l10n.mountsEmptyCurrent,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, m) in _current.indexed)
                  _currentRow(l10n, m, first: i == 0),
              ],
            ),
    );
  }

  Widget _currentRow(
    AppL10n l10n,
    Map<String, dynamic> m, {
    required bool first,
  }) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: .5);
    final divider = QuartzTokens.of(context).border;
    final total = (m['size'] as num?)?.toInt() ?? 0;
    final avail = (m['avail'] as num?)?.toInt() ?? 0;
    final used = (total - avail).clamp(0, total);
    final device = '${m['device'] ?? ''}';
    final mount = '${m['mount'] ?? ''}';
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mount,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  device,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
          if (total > 0)
            Text(
              l10n.mountsUsage(formatBytes(used), formatBytes(total)),
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: muted,
              ),
            ),
        ],
      ),
    );
  }

  Widget _configCard(
    AppL10n l10n, {
    required String title,
    required String empty,
    required String addLabel,
    required List<String> keys,
    required bool swap,
  }) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: .5);
    return QuartzCard(
      title: title,
      trailing: QzLegacyIconButton(
        tooltip: addLabel,
        onPressed: _loading ? null : () => _add(swap),
        icon: const Icon(Icons.add, size: 20),
      ),
      child: keys.isEmpty
          ? Text(
              empty,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, key) in keys.indexed)
                  _configRow(
                    l10n,
                    key,
                    _sections[key] ?? const {},
                    swap: swap,
                    first: i == 0,
                  ),
              ],
            ),
    );
  }

  Widget _configRow(
    AppL10n l10n,
    String key,
    Map<String, dynamic> v, {
    required bool swap,
    required bool first,
  }) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: .5);
    final divider = QuartzTokens.of(context).border;
    final title = swap
        ? _or(_s(v, 'device'), key)
        : '${_or(_s(v, 'target'), key)} ← ${_or(_s(v, 'device'), _or(_s(v, 'uuid'), _s(v, 'label')))}';
    final sub = swap
        ? (configBool(v['enabled']) || !v.containsKey('enabled')
              ? l10n.mountsEnabled
              : l10n.firewallDisabled)
        : [
            if (_s(v, 'fstype').isNotEmpty) _s(v, 'fstype'),
            if (_s(v, 'options').isNotEmpty) _s(v, 'options'),
            if (v.containsKey('enabled') && !configBool(v['enabled']))
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
        onTap: () => _edit(key, v, swap: swap),
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
              onPressed: () => _edit(key, v, swap: swap),
              icon: Icon(Icons.edit_outlined, size: 19, color: muted),
            ),
            QzLegacyIconButton(
              tooltip: l10n.firewallDelete,
              onPressed: () => _delete(key, title, swap: swap),
              icon: Icon(Icons.delete_outline, size: 19, color: muted),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(
    String key,
    Map<String, dynamic> v, {
    required bool swap,
  }) async {
    final saved = await _sheet(
      title: swap ? _s(v, 'device') : _s(v, 'target'),
      section: key,
      swap: swap,
      initial: v.containsKey('enabled') ? v : {...v, 'enabled': true},
    );
    if (saved == true && mounted) _load();
  }

  Future<void> _add(bool swap) async {
    final l10n = AppL10n.of(context);
    final saved = await _sheet(
      title: swap ? l10n.mountsAddSwap : l10n.mountsAddMount,
      section: null,
      swap: swap,
      initial: swap ? {'enabled': true} : {'enabled': true, 'fstype': 'auto'},
    );
    if (saved == true && mounted) _load();
  }

  Future<bool?> _sheet({
    required String title,
    required String? section,
    required bool swap,
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
          config: 'fstab',
          section: section,
          addType: swap ? 'swap' : 'mount',
          fields: swap ? _swapFields(l10n) : _mountFields(l10n),
          initial: initial,
          danger: !swap,
          dangerBody: !swap ? l10n.mountsHint : null,
        ),
      ),
    );
  }

  Future<void> _delete(String key, String title, {required bool swap}) async {
    final l10n = AppL10n.of(context);
    final outcome = await applyConfigMutation(
      context,
      ref,
      config: 'fstab',
      danger: true,
      dangerBody: l10n.mountsDeleteBody(title),
      mutate: (client) => client.delete('fstab', key),
    );
    if (outcome != null && mounted) _load();
  }

  List<ConfigField> _globalFields(AppL10n l10n) => [
    ConfigField(
      'anon_swap',
      l10n.mountsGlobalAnonSwap,
      kind: ConfigFieldKind.boolean,
    ),
    ConfigField(
      'anon_mount',
      l10n.mountsGlobalAnonMount,
      kind: ConfigFieldKind.boolean,
    ),
    ConfigField(
      'auto_swap',
      l10n.mountsGlobalAutoSwap,
      kind: ConfigFieldKind.boolean,
    ),
    ConfigField(
      'auto_mount',
      l10n.mountsGlobalAutoMount,
      kind: ConfigFieldKind.boolean,
    ),
    ConfigField(
      'check_fs',
      l10n.mountsGlobalCheckFsck,
      kind: ConfigFieldKind.boolean,
    ),
    ConfigField(
      'delay_root',
      l10n.mountsGlobalDelayRoot,
      kind: ConfigFieldKind.integer,
      min: 0,
      max: 120,
    ),
  ];

  List<ConfigField> _mountFields(AppL10n l10n) => [
    ConfigField('target', l10n.mountsTarget, dangerous: true),
    ConfigField('device', l10n.mountsDevice),
    ConfigField('fstype', l10n.mountsFstype),
    ConfigField('options', l10n.mountsOptions),
    ConfigField('uuid', l10n.mountsUuid),
    ConfigField('label', l10n.mountsLabel),
    ConfigField('enabled', l10n.mountsEnabled, kind: ConfigFieldKind.boolean),
    ConfigField('enabled_fsck', l10n.mountsFsck, kind: ConfigFieldKind.boolean),
  ];

  List<ConfigField> _swapFields(AppL10n l10n) => [
    ConfigField('device', l10n.mountsDevice, dangerous: true),
    ConfigField('enabled', l10n.mountsEnabled, kind: ConfigFieldKind.boolean),
  ];
}
