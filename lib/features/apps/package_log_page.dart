// 操作记录（UI-DESIGN ⑫）：软件包升级/卸载/刷新执行结果（含失败原因）。
// 数据面 = WP-5 `packages` scope=history（结构化近 30 条，最新在前）。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/envelope.dart';
import '../../api/packages.dart';
import '../../core/theme.dart';
import '../../format.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../widgets/quartz.dart';

class PackageLogPage extends ConsumerStatefulWidget {
  const PackageLogPage({super.key});

  @override
  ConsumerState<PackageLogPage> createState() => _PackageLogPageState();
}

class _PackageLogPageState extends ConsumerState<PackageLogPage> {
  Future<ApiResult>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final tm = ref.read(tokenManagerProvider);
    setState(() {
      _future = tm == null
          ? Future.value(ApiResult.fail(0, const ApiError('no_router', '')))
          : tm.call('packages', {'scope': 'history'});
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => context.pop()),
        title: Text(l10n.opLogTitle),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _load),
        ],
      ),
      body: FutureBuilder<ApiResult>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final r = snap.data;
          if (r?.ok != true) {
            final missing = r?.error?.code == 'bad_request';
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                QuartzCard(
                  title: missing ? l10n.packagesApiMissingTitle : l10n.unavailable,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        missing ? l10n.packagesApiMissingBody : (r?.error?.message ?? ''),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: .55),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(onPressed: _load, child: Text(l10n.retry)),
                    ],
                  ),
                ),
              ],
            );
          }
          final ops = PackagesPage.fromPayload(r!.data).ops;
          if (ops.isEmpty) {
            return Center(child: Text(l10n.opLogEmpty));
          }
          return RefreshIndicator(
            onRefresh: () async => _load(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final op in ops)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _OpCard(op: op),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.opLogRetain,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: .45),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OpCard extends StatelessWidget {
  const _OpCard({required this.op});

  final PackageOp op;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    final (unit, n) = relativeTime(op.ts);
    final when = op.ts <= 0
        ? ''
        : switch (unit) {
            'now' => l10n.lastSeenNow,
            'min' => l10n.lastSeenMin(n),
            'hour' => l10n.lastSeenHour(n),
            _ => l10n.lastSeenDay(n),
          };
    final title = switch (op.op) {
      'refresh' => l10n.opReindex,
      'upgrade' => l10n.pkgUpgrade,
      'remove' => l10n.pkgRemove,
      _ => op.action,
    };
    return QuartzCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusDot(op.ok ? DotKind.ok : DotKind.err),
              Expanded(
                child: Text(
                  op.target.isEmpty ? title : '$title · ${op.target}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                when,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: .45),
                ),
              ),
            ],
          ),
          if (op.output.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _tail(op.output),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: op.ok
                    ? theme.colorScheme.onSurface.withValues(alpha: .5)
                    : QuartzColors.err.withValues(alpha: .85),
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            l10n.opLogMeta(op.ok ? l10n.opResultOk : l10n.opResultFail, '${(op.durationMs / 1000).toStringAsFixed(1)}s'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: .4),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  /// apk 输出取尾部一行摘要（去掉 URL 类噪音行）。
  static String _tail(String output) {
    final lines = output.trim().split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return '';
    for (final l in lines.reversed) {
      final t = l.trim();
      if (t.startsWith('[') || t.startsWith('WARNING:')) continue;
      return t;
    }
    return lines.last.trim();
  }
}
