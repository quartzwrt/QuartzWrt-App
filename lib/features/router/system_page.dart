// 路由器 · 系统（W6.10）：hostname/description/时区/日志/串口登录。
//
// 数据面 = `config.read system`（注册表 @system）；时区列表走 `luci.timezones`
// （与网页端同一份 /etc/TZ 映射）。保存 = write → apply(rollback,90s) → 确认条。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/config.dart';
import '../../api/luci.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/quartz.dart';
import 'config_common.dart';

class SystemPage extends ConsumerStatefulWidget {
  const SystemPage({super.key});

  @override
  ConsumerState<SystemPage> createState() => _SystemPageState();
}

class _SystemPageState extends ConsumerState<SystemPage> {
  bool _loading = true;
  bool _busy = false;
  String _error = '';
  String _section = '@system[0]';
  Map<String, dynamic> _original = const {};
  final Map<String, TextEditingController> _text = {};
  bool _ttyLogin = false;
  String _logProto = 'udp';
  String _zoneName = '';
  String _tzString = '';
  Map<String, String> _zones = const {};

  static const _textOptions = [
    'hostname',
    'description',
    'log_size',
    'log_ip',
    'log_port',
    'conloglevel',
    'cronloglevel',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final client = ref.read(configClientProvider);
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
    final map = r.map;
    String section = '@system[0]';
    Map<String, dynamic> values = const {};
    if (map.isNotEmpty) {
      section = map.keys.firstWhere((k) => k.contains('system'), orElse: () => map.keys.first);
      final v = map[section];
      if (v is Map<String, dynamic>) values = v;
    }
    _original = Map.of(values);
    _section = section;
    _ttyLogin = configBool(values['ttylogin']);
    _logProto = '${values['log_proto'] ?? 'udp'}';
    _zoneName = '${values['zonename'] ?? ''}';
    _tzString = '${values['timezone'] ?? ''}';
    for (final k in _textOptions) {
      _text[k]?.dispose();
      _text[k] = TextEditingController(text: configValueText(values[k]));
    }
    setState(() {
      _loading = false;
      _error = '';
    });
    _loadZones();
  }

  Future<void> _loadZones() async {
    final luci = ref.read(luciClientProvider);
    if (luci == null) return;
    final r = await luci.timezones();
    if (!mounted) return;
    if (!r.ok) return;
    final zones = <String, String>{};
    for (final e in r.map.entries) {
      final v = e.value;
      if (v is Map && v['tzstring'] is String) {
        zones[e.key] = v['tzstring'] as String;
      }
    }
    if (zones.isEmpty) return;
    setState(() => _zones = zones);
  }

  bool _textDirty(String option) {
    final cur = _text[option]?.text.trim() ?? '';
    final orig = configValueText(_original[option]).trim();
    return cur != orig;
  }

  bool get _dirty =>
      _textDirty('hostname') ||
      _textDirty('description') ||
      _textDirty('log_size') ||
      _textDirty('log_ip') ||
      _textDirty('log_port') ||
      _textDirty('conloglevel') ||
      _textDirty('cronloglevel') ||
      _ttyLogin != configBool(_original['ttylogin']) ||
      _logProto != '${_original['log_proto'] ?? 'udp'}' ||
      (_zoneName.isNotEmpty && _zoneName != '${_original['zonename'] ?? ''}');

  List<ConfigEdit> _edits() {
    final out = <ConfigEdit>[];
    void text(String option) {
      if (!_textDirty(option)) return;
      final raw = _text[option]!.text.trim();
      switch (option) {
        case 'log_size':
        case 'log_port':
        case 'conloglevel':
        case 'cronloglevel':
          final n = int.tryParse(raw);
          if (n == null) return;
          out.add(ConfigEdit('system', _section, option, n));
        default:
          out.add(ConfigEdit('system', _section, option, raw));
      }
    }

    text('hostname');
    text('description');
    text('log_size');
    text('log_ip');
    text('log_port');
    text('conloglevel');
    text('cronloglevel');
    if (_ttyLogin != configBool(_original['ttylogin'])) {
      out.add(ConfigEdit('system', _section, 'ttylogin', _ttyLogin));
    }
    if (_logProto != '${_original['log_proto'] ?? 'udp'}') {
      out.add(ConfigEdit('system', _section, 'log_proto', _logProto));
    }
    if (_zoneName.isNotEmpty && _zoneName != '${_original['zonename'] ?? ''}') {
      out.add(ConfigEdit('system', _section, 'zonename', _zoneName));
      if (_tzString.isNotEmpty) out.add(ConfigEdit('system', _section, 'timezone', _tzString));
    }
    return out;
  }

  Future<void> _save() async {
    final edits = _edits();
    if (edits.isEmpty) {
      showConfigSnack(context, AppL10n.of(context).configNoChanges);
      return;
    }
    setState(() => _busy = true);
    final outcome = await applyConfigEdits(context, ref, edits: edits);
    if (!mounted) return;
    setState(() => _busy = false);
    if (outcome != null) _load();
  }

  Future<void> _pickZone() async {
    if (_zones.isEmpty) {
      await _loadZones();
      if (!mounted || _zones.isEmpty) return;
    }
    final picked = await showTimezonePicker(context, _zones, _zoneName);
    if (picked == null || !mounted) return;
    setState(() {
      _zoneName = picked;
      _tzString = _zones[picked] ?? _tzString;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.routerEntrySystem, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (_error.isNotEmpty) ...[
                  InfoBanner(title: l10n.configLoadFailedTitle, body: _error),
                  const SizedBox(height: 4),
                ],
                QuartzCard(
                  title: l10n.systemGeneral,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConfigFieldTile(
                        field: ConfigField('hostname', l10n.systemHostname),
                        value: _original['hostname'],
                        controller: _text['hostname'],
                        enabled: !_busy,
                        onChanged: (_) => setState(() {}),
                      ),
                      ConfigFieldTile(
                        field: ConfigField('description', l10n.systemDescription),
                        value: _original['description'],
                        controller: _text['description'],
                        enabled: !_busy,
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
                QuartzCard(
                  title: l10n.systemTimezone,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(QuartzRadii.sm),
                        onTap: _busy ? null : _pickZone,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _zoneName.isEmpty ? l10n.configUnset : _zoneName,
                                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    if (_tzString.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        _tzString,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurface.withValues(alpha: .45),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Text(l10n.configChoose, style: const TextStyle(color: QuartzColors.accent, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 2),
                              const Icon(Icons.chevron_right, size: 18, color: QuartzColors.accent),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        l10n.systemTimezoneHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: .45),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                QuartzCard(
                  title: l10n.systemLogging,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConfigFieldTile(
                        field: ConfigField('log_size', l10n.systemLogSize, kind: ConfigFieldKind.integer),
                        value: _original['log_size'],
                        controller: _text['log_size'],
                        enabled: !_busy,
                        onChanged: (_) => setState(() {}),
                      ),
                      ConfigFieldTile(
                        field: ConfigField(
                          'log_proto',
                          l10n.systemLogProto,
                          kind: ConfigFieldKind.choice,
                          choices: [
                            ConfigChoice('udp', 'UDP'),
                            ConfigChoice('tcp', 'TCP'),
                          ],
                        ),
                        value: _logProto,
                        controller: null,
                        enabled: !_busy,
                        onChanged: (v) => setState(() => _logProto = '$v'),
                      ),
                      ConfigFieldTile(
                        field: ConfigField('log_ip', l10n.systemLogIp, hint: l10n.systemLogIpHint),
                        value: _original['log_ip'],
                        controller: _text['log_ip'],
                        enabled: !_busy,
                        onChanged: (_) => setState(() {}),
                      ),
                      ConfigFieldTile(
                        field: ConfigField('log_port', l10n.systemLogPort, kind: ConfigFieldKind.integer),
                        value: _original['log_port'],
                        controller: _text['log_port'],
                        enabled: !_busy,
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
                QuartzCard(
                  title: l10n.systemAdvanced,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConfigFieldTile(
                        field: ConfigField('conloglevel', l10n.systemConsoleLogLevel, kind: ConfigFieldKind.integer),
                        value: _original['conloglevel'],
                        controller: _text['conloglevel'],
                        enabled: !_busy,
                        onChanged: (_) => setState(() {}),
                      ),
                      ConfigFieldTile(
                        field: ConfigField('cronloglevel', l10n.systemCronLogLevel, kind: ConfigFieldKind.integer),
                        value: _original['cronloglevel'],
                        controller: _text['cronloglevel'],
                        enabled: !_busy,
                        onChanged: (_) => setState(() {}),
                      ),
                      ConfigFieldTile(
                        field: ConfigField('ttylogin', l10n.systemTtyLogin, kind: ConfigFieldKind.boolean),
                        value: _ttyLogin,
                        controller: null,
                        enabled: !_busy,
                        onChanged: (v) => setState(() => _ttyLogin = configBool(v)),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy || !_dirty ? null : _save,
                    child: Text(_busy ? l10n.configSaving : l10n.save),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }
}

/// 时区选择器（带搜索；数据源 `luci.timezones`）。
Future<String?> showTimezonePicker(BuildContext context, Map<String, String> zones, String current) async {
  final l10n = AppL10n.of(context);
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).brightness == Brightness.dark ? QuartzColors.darkRaised : Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => _TimezoneSheet(zones: zones, current: current, l10n: l10n),
  );
}

class _TimezoneSheet extends StatefulWidget {
  const _TimezoneSheet({required this.zones, required this.current, required this.l10n});

  final Map<String, String> zones;
  final String current;
  final AppL10n l10n;

  @override
  State<_TimezoneSheet> createState() => _TimezoneSheetState();
}

class _TimezoneSheetState extends State<_TimezoneSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final all = widget.zones.keys.toList()..sort();
    final q = _query.trim().toLowerCase();
    final list = q.isEmpty ? all : all.where((z) => z.toLowerCase().contains(q) || widget.zones[z]!.toLowerCase().contains(q)).toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .78,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text(widget.l10n.systemTimezonePicker, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: TextField(
                autofocus: false,
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search, size: 19),
                  hintText: widget.l10n.systemTimezoneSearch,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final z = list[i];
                  final selected = z == widget.current;
                  return ListTile(
                    dense: true,
                    title: Text(z, style: const TextStyle(fontSize: 13.5)),
                    subtitle: Text(widget.zones[z]!, style: const TextStyle(fontSize: 11)),
                    trailing: selected ? const Icon(Icons.check, size: 18, color: QuartzColors.accent) : null,
                    onTap: () => Navigator.of(context).pop(z),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
