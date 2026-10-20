// 已配对设备（devices / revoke；WP-5 §4.1）。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/envelope.dart';
import '../../core/theme.dart';
import '../../format.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../widgets/quartz.dart';

class DevicesPage extends ConsumerStatefulWidget {
  const DevicesPage({super.key});

  @override
  ConsumerState<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends ConsumerState<DevicesPage> {
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
          : tm.call('devices');
    });
  }

  Future<void> _revoke(String deviceId) async {
    final l10n = AppL10n.of(context);
    final tm = ref.read(tokenManagerProvider);
    if (tm == null) return;
    final ok = await showConfirmSheet(
      context,
      title: l10n.revokeConfirmTitle,
      body: l10n.revokeConfirmBody,
      confirmLabel: l10n.revokeBtn,
      cancelLabel: l10n.cancel,
      danger: true,
    );
    if (!ok) return;
    final r = await tm.call('revoke', {'device_id': deviceId});
    if (!mounted) return;
    showQzToast(
      context,
      r.ok ? l10n.actionDone : l10n.actionFailed(r.error?.message ?? ''),
      kind: r.ok ? QzToastKind.ok : QzToastKind.err,
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: QzAppBar(
        leading: QzLegacyIconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.devicesPageTitle),
      ),
      body: FutureBuilder<ApiResult>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: QzSpinner(size: 22));
          }
          final r = snap.data;
          if (r?.ok != true) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.actionFailed(r?.error?.message ?? ''),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            );
          }
          final list =
              (r!.data['devices'] as List?)
                  ?.whereType<Map<String, dynamic>>()
                  .toList() ??
              const <Map<String, dynamic>>[];
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = list[i];
              final current = d['current'] == true;
              final revoked = d['revoked'] == true;
              final (unit, n) = relativeTime((d['last_seen'] as int?) ?? 0);
              final seen = switch (unit) {
                'now' => l10n.lastSeenNow,
                'min' => l10n.lastSeenMin(n),
                'hour' => l10n.lastSeenHour(n),
                _ => l10n.lastSeenDay(n),
              };
              return QuartzCard(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                (d['name'] as String?) ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (current) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: QuartzColors.ok.withValues(
                                      alpha: .12,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    l10n.devicesCurrentBadge,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: QuartzColors.ok,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                              if (revoked) ...[
                                const SizedBox(width: 8),
                                Text(
                                  l10n.devicesRevokedBadge,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: .45),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            seen,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: .5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!current && !revoked)
                      QzLegacyButton(
                        kind: QzButtonKind.ghost,
                        onPressed: () =>
                            _revoke((d['device_id'] as String?) ?? ''),
                        child: Text(
                          l10n.revokeBtn,
                          style: const TextStyle(color: QuartzColors.err),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
