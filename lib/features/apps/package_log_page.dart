// 操作记录（UI-DESIGN ⑫；数据面 = WP-5 `packages` scope=history，未实现时降级）。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/envelope.dart';
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
      ),
      body: FutureBuilder<ApiResult>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final r = snap.data;
          if (r?.ok != true) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                QuartzCard(
                  title: l10n.packagesApiMissingTitle,
                  child: Text(
                    l10n.packagesApiMissingBody,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: .55),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            );
          }
          final ops = (r!.data['ops'] as List?)?.whereType<Map<String, dynamic>>().toList() ??
              const <Map<String, dynamic>>[];
          if (ops.isEmpty) {
            return Center(child: Text(l10n.opLogEmpty));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final op in ops)
                QuartzCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              (op['title'] as String?) ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            (op['time'] as String?) ?? '',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: .5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          StatusDot(switch (op['status']) {
                            'ok' => DotKind.ok,
                            'partial' => DotKind.warn,
                            _ => DotKind.err,
                          }),
                          Expanded(
                            child: Text(
                              (op['detail'] as String?) ?? '',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: .6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
          );
        },
      ),
    );
  }
}
