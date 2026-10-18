// 路由器 · 计划任务（W6.11）：/etc/crontabs/root 文本编辑 + cron reload。
//
// 内容是可执行的 cron 行；保存前二次确认。app-api 固定路径并校验大小/控制字符。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/cron.dart';
import '../../api/luci.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/quartz.dart';
import 'config_common.dart';

class CronPage extends ConsumerStatefulWidget {
  const CronPage({super.key});

  @override
  ConsumerState<CronPage> createState() => _CronPageState();
}

class _CronPageState extends ConsumerState<CronPage> {
  bool _loading = true;
  bool _busy = false;
  String _error = '';
  String _path = '';
  final _text = TextEditingController();
  String _original = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final client = ref.read(cronClientProvider);
    if (client == null) return;
    setState(() {
      _loading = true;
      _error = '';
    });
    final r = await client.read();
    if (!mounted) return;
    if (!r.ok) {
      setState(() {
        _loading = false;
        _error = configErrorText(AppL10n.of(context), r.error);
      });
      return;
    }
    _original = r.content;
    _text.text = r.content;
    setState(() {
      _path = r.path;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final l10n = AppL10n.of(context);
    final content = _text.text;
    if (content == _original) {
      showConfigSnack(context, l10n.configNoChanges);
      return;
    }
    final ok = await showConfirmSheet(
      context,
      title: l10n.cronSave,
      body: l10n.cronDanger,
      confirmLabel: l10n.confirm,
      cancelLabel: l10n.cancel,
      danger: true,
    );
    if (!ok) return;
    final client = ref.read(cronClientProvider);
    final luci = ref.read(luciClientProvider);
    if (client == null) return;
    setState(() => _busy = true);
    final w = await client.write(content);
    if (!mounted) return;
    if (!w.ok) {
      setState(() => _busy = false);
      showConfigSnack(context, configErrorText(l10n, w.error));
      return;
    }
    var reloaded = true;
    if (luci != null) {
      final r = await luci.initAction('cron', 'reload');
      reloaded = r.ok;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    showConfigSnack(context, reloaded ? l10n.cronSaved : l10n.cronReloadFailed);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: .5);
    final lines = _text.text.isEmpty ? 0 : _text.text.split('\n').where((l) => l.trim().isNotEmpty).length;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.routerEntryCron, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: l10n.refresh,
            onPressed: _loading || _busy ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
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
                  title: l10n.routerEntryCron,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_path.isNotEmpty) ...[
                        Text(_path, style: theme.textTheme.bodySmall?.copyWith(color: muted, fontFamily: 'monospace')),
                        const SizedBox(height: 4),
                      ],
                      Text(l10n.cronHint, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _text,
                        enabled: !_busy,
                        minLines: 12,
                        maxLines: 24,
                        keyboardType: TextInputType.multiline,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5, height: 1.4),
                        decoration: InputDecoration(
                          isDense: true,
                          border: const OutlineInputBorder(),
                          hintText: '* * * * * /usr/bin/logger hello',
                          hintStyle: TextStyle(color: muted, fontSize: 12),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 6),
                      Text(l10n.cronLines(lines), style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: muted)),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _busy || _text.text == _original ? null : _save,
                          child: Text(_busy ? l10n.configSaving : l10n.cronSave),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
