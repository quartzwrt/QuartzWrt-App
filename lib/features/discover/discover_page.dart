// 发现与配对（UI-DESIGN ①②）。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/pairing.dart';
import '../../core/theme.dart';
import '../../discovery/mdns.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../widgets/quartz.dart';

class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  var _scanning = true;
  List<DiscoveredRouter> _found = const [];

  @override
  void initState() {
    super.initState();
    _scan();
  }

  Future<void> _scan() async {
    setState(() => _scanning = true);
    List<DiscoveredRouter> found;
    try {
      found = await ref.read(discoverProvider)();
    } catch (_) {
      found = const [];
    }
    if (!mounted) return;
    setState(() {
      _found = found;
      _scanning = false;
    });
  }

  Future<void> _addByAddress() async {
    final l10n = AppL10n.of(context);
    final hostCtrl = TextEditingController();
    final portCtrl = TextEditingController(text: '443');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addByAddressTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: hostCtrl,
              autofocus: true,
              decoration: InputDecoration(labelText: l10n.hostLabel, hintText: '192.168.1.1'),
            ),
            TextField(
              controller: portCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.portLabel),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.confirm)),
        ],
      ),
    );
    if (ok != true || hostCtrl.text.trim().isEmpty) return;
    if (!mounted) return;
    final port = int.tryParse(portCtrl.text.trim()) ?? 443;
    await _pair(
      DiscoveredRouter(
        name: hostCtrl.text.trim(),
        model: '',
        release: '',
        host: hostCtrl.text.trim(),
        port: port,
        fingerprint: '', // 手动地址：TOFU（无带外指纹）
      ),
    );
  }

  Future<void> _pair(DiscoveredRouter d) async {
    final l10n = AppL10n.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final passwordCtrl = TextEditingController();
    final deviceName = _deviceName();
    var busy = false;
    String? error;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? QuartzColors.darkRaised : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          Future<void> doPair() async {
            final nav = Navigator.of(ctx);
            final routerR = GoRouter.of(ctx);
            setSheet(() {
              busy = true;
              error = null;
            });
            try {
              final outcome = await pairRouter(
                host: d.host,
                port: d.port,
                password: passwordCtrl.text,
                deviceName: deviceName,
                expectedFingerprint: d.verifiable ? d.fingerprint : null,
              );
              if (!mounted) return;
              final registry = ref.read(registryProvider);
              await registry.upsert(outcome.router);
              await registry.setActive(outcome.router.id);
              await ref.read(tokenStoreProvider).writeRefresh(outcome.router.id, outcome.tokens.refreshToken);
              ref.invalidate(activeRouterProvider);
              nav.pop();
              routerR.go('/overview');
            } on PairException catch (e) {
              setSheet(() {
                busy = false;
                error = _mapPairError(l10n, e);
              });
            } catch (_) {
              // 兜底：任何未预期异常都必须解除 Pairing… 卡态（曾因注册表写入
              // 异常导致弹层永久卡住、无提示）。
              setSheet(() {
                busy = false;
                error = l10n.errConnect;
              });
            }
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(18, 10, 18, 24 + MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4.5,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: .35),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Text(
                  l10n.pairTitle(d.name),
                  textAlign: TextAlign.center,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                KvRow(
                  l10n.certFingerprint,
                  d.verifiable ? _shortFp(d.fingerprint) : l10n.badgeUnverified,
                  first: true,
                  valueColor: d.verifiable ? null : QuartzColors.warn,
                ),
                if (d.release.isNotEmpty) KvRow(l10n.firmwareLabel, d.release),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  autofocus: true,
                  enabled: !busy,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: l10n.routerPassword,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.routerPasswordHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: .55),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: QuartzColors.err)),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: busy ? null : () => Navigator.of(ctx).pop(),
                        child: Text(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: busy ? null : doPair,
                        child: Text(busy ? l10n.pairing : l10n.pairButton),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _deviceName() {
    // v1：设备名取平台简单标识（后续可用 device_info 增强）。
    return 'Quartz App';
  }

  String _mapPairError(AppL10n l10n, PairException e) => switch (e.code) {
        'invalid_credentials' => l10n.errInvalidCredentials,
        'rate_limited' => l10n.errRateLimited(300),
        'password_not_set' => l10n.errPasswordNotSet,
        'fingerprint_mismatch' => l10n.errFingerprintMismatch,
        'bad_certificate' => l10n.errBadCert,
        'timeout' => l10n.errTimeout,
        _ => l10n.errConnect,
      };

  String _shortFp(String fp) =>
      fp.length >= 12 ? '${fp.substring(0, 8)} … ${fp.substring(fp.length - 4)}' : fp;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    final registry = ref.watch(registryProvider);
    final canBack = registry.list().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            if (canBack)
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => context.go('/overview'),
              )
            else
              const SizedBox(width: 8),
            Text(l10n.discoverTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                if (_scanning)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                Text(
                  l10n.discoverScanning,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: .5),
                  ),
                ),
              ],
            ),
          ),
          for (final d in _found)
            QuartzCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.router_outlined),
                title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text([d.model, d.release].where((s) => s.isNotEmpty).join(' · ')),
                    Text(
                      d.verifiable ? '✓ ${l10n.badgeVerifiable}' : '⚠ ${l10n.badgeUnverified}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: d.verifiable ? QuartzColors.ok : QuartzColors.warn,
                      ),
                    ),
                  ],
                ),
                trailing: Text('${d.host}\n:${d.port}', textAlign: TextAlign.right, style: theme.textTheme.bodySmall),
                onTap: () => _pair(d),
              ),
            ),
          if (!_scanning && _found.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                l10n.discoverNone,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: .5),
                ),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _addByAddress, child: Text(l10n.addByAddress)),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: _scan,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l10n.refresh),
            ),
          ),
        ],
      ),
    );
  }
}
