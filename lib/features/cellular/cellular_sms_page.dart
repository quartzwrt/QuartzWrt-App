// 蜂窝 · 短信（W6.13）：列表（结构化消息，与网页端同源 `qmodem.sms.list`）+ 发送 +
// 标记已读 + 删除 + 存储用量。
//
// 隐私纪律（设计稿 §5.1）：消息只在内存态，退出即清；不落盘、不上传。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/cellular.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/quartz.dart';
import 'qmodem_client.dart';

class CellularSmsPage extends ConsumerStatefulWidget {
  const CellularSmsPage({super.key, required this.section});

  final String section;

  @override
  ConsumerState<CellularSmsPage> createState() => _CellularSmsPageState();
}

class _CellularSmsPageState extends ConsumerState<CellularSmsPage> {
  bool _loaded = false;
  bool _busy = false;
  String _error = '';
  List<CellularSmsMessage> _msgs = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool sync = false}) async {
    final client = ref.read(qmodemClientProvider);
    if (client == null) return;
    if (sync) await client.call('qmodem.sms_sync', section: widget.section);
    final r = await client.call('qmodem.sms_list', section: widget.section, args: {'limit': '100'});
    final list = r.ok ? CellularSmsMessage.listFrom(r.map) : <CellularSmsMessage>[];
    if (!mounted) return;
    setState(() {
      _loaded = true;
      _msgs = list;
      _error = r.ok ? '' : r.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final unread = _msgs.where((m) => m.received && !m.read).length;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cellularEntrySms, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(onPressed: _busy ? null : () => _compose(), icon: const Icon(Icons.edit_outlined)),
          IconButton(onPressed: _busy ? null : () => _load(sync: true), icon: const Icon(Icons.sync)),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _load(sync: true),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  InfoBanner(title: l10n.cellularSmsPrivacyTitle, body: l10n.cellularSmsPrivacyBody),
                  if (_error.isNotEmpty) InfoBanner(title: l10n.actionFailed(_error), body: l10n.cellularSettingsHint),
                  if (_msgs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(28),
                      child: Center(child: Text(l10n.cellularSmsEmpty, style: const TextStyle(fontSize: 13))),
                    )
                  else ...[
                    SectionLabel(l10n.cellularSmsCount('${_msgs.length}', '$unread')),
                    QuartzCard(
                      child: Column(
                        children: [
                          for (final (i, m) in _msgs.indexed)
                            _row(context, l10n, m, first: i == 0, last: i == _msgs.length - 1),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _row(BuildContext context, AppL10n l10n, CellularSmsMessage m, {required bool first, required bool last}) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      child: InkWell(
        onTap: () => m.received && !m.read ? _markRead(m) : _showDetail(m),
        onLongPress: () => _delete(m),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            border: last ? null : Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: .5))),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (m.received && !m.read)
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 7),
                  child: Container(width: 7, height: 7, decoration: const BoxDecoration(shape: BoxShape.circle, color: QuartzColors.accent)),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          m.peer.isEmpty ? l10n.unknownValue : m.peer,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 6),
                        if (!m.received)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              border: Border.all(color: theme.dividerColor),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(l10n.cellularSmsSentTag, style: const TextStyle(fontSize: 10)),
                          ),
                        const Spacer(),
                        Text(_ts(m.timestampMs), style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: .45))),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      m.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: theme.colorScheme.onSurface.withValues(alpha: .75)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ts(int ms) {
    if (ms <= 0) return '';
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '${d.month}-${d.day.toString().padLeft(2, '0')}';
  }

  void _showDetail(CellularSmsMessage m) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.peer.isEmpty ? AppL10n.of(ctx).unknownValue : m.peer),
        content: SingleChildScrollView(child: SelectableText(m.content)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppL10n.of(ctx).close)),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _delete(m);
            },
            child: Text(AppL10n.of(ctx).deleteAction, style: const TextStyle(color: QuartzColors.err)),
          ),
        ],
      ),
    );
  }

  Future<void> _markRead(CellularSmsMessage m) async {
    final client = ref.read(qmodemClientProvider);
    if (client == null) return;
    final r = await client.call('qmodem.sms_mark_read', section: widget.section, args: {'id': m.id});
    if (!mounted) return;
    if (r.ok) {
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppL10n.of(context).actionFailed(r.message))));
    }
  }

  Future<void> _delete(CellularSmsMessage m) async {
    final l10n = AppL10n.of(context);
    final client = ref.read(qmodemClientProvider);
    if (client == null) return;
    final ok = await showConfirmSheet(
      context,
      title: l10n.cellularSmsDeleteConfirm,
      body: l10n.cellularSmsDeleteBody,
      confirmLabel: l10n.confirm,
      cancelLabel: l10n.cancel,
      danger: true,
    );
    if (!ok) return;
    setState(() => _busy = true);
    final r = await client.call('qmodem.sms_delete', section: widget.section, args: {'id': m.id, 'index': m.index});
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(r.ok ? l10n.actionDone : l10n.actionFailed(r.message))),
    );
    await _load();
  }

  Future<void> _compose() async {
    final l10n = AppL10n.of(context);
    final client = ref.read(qmodemClientProvider);
    if (client == null) return;
    final recipient = TextEditingController();
    final content = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            Text(l10n.cellularSmsCompose, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
              child: TextField(
                controller: recipient,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: l10n.cellularSmsRecipient, border: const OutlineInputBorder(), isDense: true),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
              child: TextField(
                controller: content,
                maxLines: 3,
                maxLength: 480,
                decoration: InputDecoration(labelText: l10n.cellularSmsContent, border: const OutlineInputBorder(), isDense: true),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l10n.cellularSmsSendAction),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final to = recipient.text.trim();
    final text = content.text.trim();
    if (to.isEmpty || text.isEmpty) return;
    setState(() => _busy = true);
    final r = await client.call('qmodem.sms_send', section: widget.section, args: {'recipient': to, 'content': text});
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(r.ok ? l10n.actionDone : l10n.actionFailed(r.message))),
    );
    await _load(sync: true);
  }
}
