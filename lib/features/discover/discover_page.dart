// 发现与配对（UI-DESIGN ①②）。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/pairing.dart';
import '../../core/theme.dart';
import '../../discovery/mdns.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/error_text.dart';
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
    final ok = await showQzSheet<bool>(
      context,
      builder: (ctx) {
        final t = QuartzTokens.of(ctx);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.addByAddressTitle,
              textAlign: TextAlign.center,
              style: QuartzType.heroTitle.copyWith(color: t.text),
            ),
            const SizedBox(height: 12),
            QzField(
              controller: hostCtrl,
              label: l10n.hostLabel,
              hint: '192.168.1.1',
              autofocus: true,
            ),
            const SizedBox(height: 10),
            QzField(
              controller: portCtrl,
              label: l10n.portLabel,
              hint: '443',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: QzButton(
                    label: l10n.cancel,
                    kind: QzButtonKind.plain,
                    onPressed: () => Navigator.of(ctx).pop(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: QzButton(
                    label: l10n.confirm,
                    onPressed: () => Navigator.of(ctx).pop(true),
                  ),
                ),
              ],
            ),
          ],
        );
      },
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
    final passwordCtrl = TextEditingController();
    final deviceName = _deviceName();
    var busy = false;
    String? error;

    await showQzSheet<void>(
      context,
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
              await ref
                  .read(tokenStoreProvider)
                  .writeRefresh(outcome.router.id, outcome.tokens.refreshToken);
              ref.invalidate(activeRouterProvider);
              nav.pop();
              routerR.go('/overview');
            } on PairException catch (e) {
              setSheet(() {
                busy = false;
                error = pairErrorText(l10n, e);
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

          final t = QuartzTokens.of(ctx);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.pairTitle(d.name),
                textAlign: TextAlign.center,
                style: QuartzType.heroTitle.copyWith(color: t.text),
              ),
              const SizedBox(height: 12),
              KvRow(
                l10n.certFingerprint,
                d.verifiable ? _shortFp(d.fingerprint) : l10n.badgeUnverified,
                first: true,
                valueColor: d.verifiable ? null : t.warn,
              ),
              if (d.release.isNotEmpty) KvRow(l10n.firmwareLabel, d.release),
              const SizedBox(height: 12),
              QzField(
                controller: passwordCtrl,
                label: l10n.routerPassword,
                hint: l10n.routerPassword,
                obscure: true,
                autofocus: true,
                enabled: !busy,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.routerPasswordHint,
                textAlign: TextAlign.center,
                style: QuartzType.caption.copyWith(color: t.muted),
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: QuartzType.caption.copyWith(color: t.err),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: QzButton(
                      label: l10n.cancel,
                      kind: QzButtonKind.plain,
                      onPressed: busy ? null : () => Navigator.of(ctx).pop(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: QzButton(
                      label: busy ? l10n.pairing : l10n.pairButton,
                      onPressed: busy ? null : doPair,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  String _deviceName() {
    // v1：设备名取平台简单标识（后续可用 device_info 增强）。
    return 'Quartz App';
  }

  String _shortFp(String fp) => fp.length >= 12
      ? '${fp.substring(0, 8)} … ${fp.substring(fp.length - 4)}'
      : fp;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final t = QuartzTokens.of(context);
    final registry = ref.watch(registryProvider);
    final canBack = registry.list().isNotEmpty;

    return Scaffold(
      appBar: QzAppBar(
        titleText: l10n.discoverTitle,
        automaticallyImplyLeading: false,
        leading: canBack
            ? QzIconButton(
                icon: QzIcons.chevronLeft,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onTap: () => context.go('/overview'),
              )
            : const SizedBox(width: 8),
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
                    child: QzSpinner(size: 16, stroke: 2),
                  ),
                Text(
                  l10n.discoverScanning,
                  style: QuartzType.caption.copyWith(color: t.faint),
                ),
              ],
            ),
          ),
          if (_found.isNotEmpty)
            QzListGroup(
              children: [
                for (final (i, d) in _found.indexed)
                  QzListRow(
                    first: i == 0,
                    icon: QzIcons.routerAntenna,
                    title: d.name,
                    subtitle: [
                      d.model,
                      d.release,
                    ].where((s) => s.isNotEmpty).join(' · '),
                    chip: d.verifiable
                        ? l10n.badgeVerifiable
                        : l10n.badgeUnverified,
                    chipKind: d.verifiable
                        ? QzChipKind.native
                        : QzChipKind.warn,
                    showChevron: false,
                    trailing: Text(
                      '${d.host}:${d.port}',
                      style: QuartzType.caption.copyWith(
                        color: t.faint,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    onTap: () => _pair(d),
                  ),
              ],
            ),
          if (!_scanning && _found.isEmpty) QzEmpty(l10n.discoverNone),
          const SizedBox(height: 8),
          QzButton(
            label: l10n.addByAddress,
            kind: QzButtonKind.plain,
            icon: QzIcons.add,
            expand: true,
            onPressed: _addByAddress,
          ),
          const SizedBox(height: 10),
          Center(
            child: QzButton(
              label: l10n.refresh,
              kind: QzButtonKind.ghost,
              icon: QzIcons.refresh,
              onPressed: _scan,
            ),
          ),
        ],
      ),
    );
  }
}
