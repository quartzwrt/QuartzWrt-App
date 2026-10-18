// 路由器 · 启动项（W6.10）：`luci.getInitList` / `luci.setInitAction`。
//
// 与网页端启动项页同源（`/usr/share/rpcd/ucode/luci`；方法经 app-api `luci.*`
// 转发条目逐条注册）。enable/disable 改 rc.d 链接，start/stop/restart 调 init 脚本。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/luci.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/quartz.dart';
import 'config_common.dart';

class InitPage extends ConsumerStatefulWidget {
  const InitPage({super.key});

  @override
  ConsumerState<InitPage> createState() => _InitPageState();
}

class _InitEntry {
  const _InitEntry(this.name, this.index, this.stop, this.enabled);

  final String name;
  final int index;
  final int? stop;
  final bool enabled;
}

class _InitPageState extends ConsumerState<InitPage> {
  bool _loading = true;
  String _error = '';
  String _query = '';
  List<_InitEntry> _entries = const [];
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final luci = ref.read(luciClientProvider);
    if (luci == null) return;
    setState(() {
      _loading = true;
      _error = '';
    });
    final r = await luci.initList();
    if (!mounted) return;
    if (!r.ok) {
      setState(() {
        _loading = false;
        _error = configErrorText(AppL10n.of(context), r.error);
      });
      return;
    }
    final list = <_InitEntry>[];
    for (final e in r.map.entries) {
      final v = e.value;
      if (v is! Map) continue;
      list.add(_InitEntry(
        e.key,
        (v['index'] as num?)?.toInt() ?? 0,
        (v['stop'] as num?)?.toInt(),
        v['enabled'] == true,
      ));
    }
    list.sort((a, b) => a.name.compareTo(b.name));
    setState(() {
      _entries = list;
      _loading = false;
    });
  }

  Future<void> _run(_InitEntry e, String action) async {
    final l10n = AppL10n.of(context);
    if (action == 'stop' || action == 'restart' || action == 'disable') {
      final ok = await showConfirmSheet(
        context,
        title: '${_actionLabel(l10n, action)} · ${e.name}',
        body: action == 'disable' ? l10n.initToggleWarning : l10n.initStopWarning,
        confirmLabel: l10n.confirm,
        cancelLabel: l10n.cancel,
        danger: action == 'stop' || action == 'restart',
      );
      if (!ok) return;
    }
    final luci = ref.read(luciClientProvider);
    if (luci == null) return;
    setState(() => _busy.add(e.name));
    final r = await luci.initAction(e.name, action);
    if (!mounted) return;
    setState(() => _busy.remove(e.name));
    if (r.ok) {
      showConfigSnack(context, l10n.initActionDone(_actionLabel(l10n, action), e.name));
      _load();
    } else {
      showConfigSnack(context, configErrorText(l10n, r.error));
    }
  }

  String _actionLabel(AppL10n l10n, String action) => switch (action) {
        'enable' => l10n.initEnable,
        'disable' => l10n.initDisable,
        'start' => l10n.initStart,
        'stop' => l10n.initStop,
        'restart' => l10n.initRestart,
        _ => action,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    final q = _query.trim().toLowerCase();
    final list = q.isEmpty ? _entries : _entries.where((e) => e.name.toLowerCase().contains(q)).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.routerEntryInit, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
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
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextField(
                      decoration: InputDecoration(
                        isDense: true,
                        prefixIcon: const Icon(Icons.search, size: 19),
                        hintText: l10n.initSearch,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  if (list.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          l10n.initEmpty,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: .5),
                          ),
                        ),
                      ),
                    )
                  else
                    QuartzCard(
                      child: Column(
                        children: [
                          for (final (i, e) in list.indexed) _row(context, l10n, e, first: i == 0),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _row(BuildContext context, AppL10n l10n, _InitEntry e, {required bool first}) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: .45);
    final busy = _busy.contains(e.name);
    final divider = theme.brightness == Brightness.dark ? const Color(0x14FFFFFF) : const Color(0x11000000);
    return Container(
      decoration: first ? null : BoxDecoration(border: Border(top: BorderSide(color: divider))),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          StatusDot(e.enabled ? DotKind.ok : DotKind.off, margin: const EdgeInsets.only(right: 4, left: 2)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: e.enabled ? null : muted,
                  ),
                ),
                Text(
                  [
                    l10n.initIndex(e.index),
                    if (e.stop != null) l10n.initStopIndex(e.stop!),
                    e.enabled ? l10n.initEnabled : l10n.initDisabled,
                  ].join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.5, color: muted),
                ),
              ],
            ),
          ),
          if (busy)
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          else ...[
            Switch.adaptive(
              value: e.enabled,
              onChanged: (v) => _run(e, v ? 'enable' : 'disable'),
            ),
            PopupMenuButton<String>(
              tooltip: '',
              icon: Icon(Icons.more_horiz, size: 20, color: muted),
              onSelected: (v) => _run(e, v),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'start', child: Text(l10n.initStart)),
                PopupMenuItem(value: 'restart', child: Text(l10n.initRestart)),
                PopupMenuItem(value: 'stop', child: Text(l10n.initStop)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
