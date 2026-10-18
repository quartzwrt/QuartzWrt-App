// 蜂窝 · 高级（W6.14）：模组重启（软/硬，按 `reboot_caps` 能力协商）+ USB 拨号模式
// （危险：会重枚举 USB 数据通道）+ IMEI（敏感，风险自担）+ 统计/日志清理。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../widgets/quartz.dart';
import 'qmodem_client.dart';

class CellularAdvancedPage extends ConsumerStatefulWidget {
  const CellularAdvancedPage({super.key, required this.section});

  final String section;

  @override
  ConsumerState<CellularAdvancedPage> createState() => _CellularAdvancedPageState();
}

class _CellularAdvancedPageState extends ConsumerState<CellularAdvancedPage> {
  bool _loaded = false;
  bool _busy = false;
  bool _softReboot = true;
  bool _hardReboot = false;
  List<String> _disabled = const [];
  String _usbMode = '';
  String _imeiInput = '';
  String _stats = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final client = ref.read(qmodemClientProvider);
    if (client == null) return;
    final caps = await client.call('qmodem.reboot_caps', section: widget.section);
    final disabled = await client.call('qmodem.disabled_features', section: widget.section);
    final mode = await client.call('qmodem.usb_mode', section: widget.section);
    final snap = ref.read(snapshotProvider).data?.cellular;
    final m = snap?.modems.where((x) => x.id == widget.section).firstOrNull;
    if (!mounted) return;
    setState(() {
      _loaded = true;
      _softReboot = caps.map['soft'] != null && caps.map['soft'] != false;
      _hardReboot = caps.map['hard'] == true || caps.map['hard'] == '1';
      _disabled = [
        for (final f in (disabled.data as List? ?? const []))
          if (f is String) f,
      ];
      _usbMode = (mode.map['mode'] as String?) ?? (m?.settings?.usbMode ?? '');
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final snap = ref.watch(snapshotProvider).data?.cellular;
    final m = snap?.modems.where((x) => x.id == widget.section).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cellularAdvanced, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                QuartzCard(
                  title: l10n.cellularModule,
                  child: Column(
                    children: [
                      KvRow(l10n.model, m?.model.isNotEmpty == true ? m!.model : widget.section, first: true),
                      KvRow(l10n.cellularFirmware, m?.firmware.isNotEmpty == true ? m!.firmware : l10n.unknownValue),
                      KvRow(l10n.cellularTemp, m?.tempC == null ? l10n.unknownValue : '${m!.tempC!.toStringAsFixed(1)} °C'),
                      KvRow(l10n.cellularUsbMode, _usbMode.isEmpty ? l10n.unknownValue : _usbMode),
                    ],
                  ),
                ),
                QuartzCard(
                  title: l10n.cellularUsbModeSection,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InfoBanner(title: l10n.cellularUsbModeWarningTitle, body: l10n.cellularUsbModeWarningBody),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final mode in const ['qmi', 'ecm', 'mbim', 'rndis', 'ncm'])
                            ChoiceChip(
                              label: Text(mode),
                              selected: _usbMode == mode,
                              onSelected: _busy ? null : (v) => setState(() => _usbMode = mode),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _button(l10n.cellularUsbModeApply, danger: true, enabled: _usbMode.isNotEmpty && !_busy, onTap: () => _setUsbMode()),
                    ],
                  ),
                ),
                QuartzCard(
                  title: l10n.cellularReboot,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_softReboot && !_hardReboot)
                        Text(l10n.cellularRebootUnsupported, style: const TextStyle(fontSize: 13))
                      else ...[
                        if (_softReboot)
                          _button(l10n.cellularRebootSoft, danger: true, enabled: !_busy, onTap: () => _reboot(hard: false)),
                        if (_hardReboot) ...[
                          const SizedBox(height: 8),
                          _button(l10n.cellularRebootHard, danger: true, enabled: !_busy, onTap: () => _reboot(hard: true)),
                        ],
                      ],
                    ],
                  ),
                ),
                QuartzCard(
                  title: l10n.cellularImeiSection,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InfoBanner(title: l10n.cellularImeiWarningTitle, body: l10n.cellularImeiWarningBody),
                      TextField(
                        keyboardType: TextInputType.number,
                        maxLength: 15,
                        decoration: InputDecoration(
                          labelText: l10n.cellularImeiInput,
                          border: const OutlineInputBorder(),
                          isDense: true,
                          counterText: '',
                        ),
                        onChanged: (v) => _imeiInput = v.trim(),
                      ),
                      const SizedBox(height: 8),
                      _button(
                        l10n.cellularImeiApply,
                        danger: true,
                        enabled: _imeiInput.length == 15 && !_busy,
                        onTap: () => _setImei(),
                      ),
                    ],
                  ),
                ),
                QuartzCard(
                  title: l10n.cellularMaintenance,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_disabled.isNotEmpty) ...[
                        Text(l10n.cellularDisabledFeatures(_disabled.join(' · ')), style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 10),
                      ],
                      _button(l10n.cellularSaveStats, enabled: !_busy, onTap: () => _simple('qmodem.save_stats', l10n.cellularSaveStats)),
                      const SizedBox(height: 8),
                      _button(l10n.cellularClearStats, danger: true, enabled: !_busy, onTap: () => _simple('qmodem.clear_stats', l10n.cellularClearStats, danger: true)),
                      const SizedBox(height: 8),
                      _button(l10n.cellularClearDialLog, danger: true, enabled: !_busy, onTap: () => _simple('qmodem.clear_dial_log', l10n.cellularClearDialLog, danger: true)),
                      if (_stats.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(_stats, style: const TextStyle(fontSize: 12)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _button(String label, {bool danger = false, required bool enabled, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: enabled ? onTap : null,
        style: FilledButton.styleFrom(backgroundColor: danger ? QuartzColors.err.withValues(alpha: .9) : null),
        child: Text(label),
      ),
    );
  }

  Future<bool> _confirm(String title, String body) async {
    final l10n = AppL10n.of(context);
    return showConfirmSheet(
      context,
      title: title,
      body: body,
      confirmLabel: l10n.confirm,
      cancelLabel: l10n.cancel,
      danger: true,
    );
  }

  Future<void> _setUsbMode() async {
    final l10n = AppL10n.of(context);
    if (!await _confirm(l10n.cellularUsbModeApply, l10n.cellularUsbModeWarningBody)) return;
    await _call('qmodem.set_usb_mode', args: {'mode': _usbMode});
  }

  Future<void> _reboot({required bool hard}) async {
    final l10n = AppL10n.of(context);
    if (!await _confirm(hard ? l10n.cellularRebootHard : l10n.cellularRebootSoft, l10n.cellularRebootWarning)) return;
    await _call('qmodem.reboot', args: {'params': '{"method":"${hard ? 'hard' : 'soft'}"}'});
  }

  Future<void> _setImei() async {
    final l10n = AppL10n.of(context);
    if (!await _confirm(l10n.cellularImeiApply, l10n.cellularImeiWarningBody)) return;
    await _call('qmodem.set_imei', args: {'imei': _imeiInput});
  }

  Future<void> _simple(String id, String label, {bool danger = false}) async {
    final l10n = AppL10n.of(context);
    if (danger && !await _confirm(label, l10n.cellularDangerWarning)) return;
    await _call(id);
  }

  Future<void> _call(String id, {Map<String, String> args = const {}}) async {
    final l10n = AppL10n.of(context);
    final client = ref.read(qmodemClientProvider);
    if (client == null) return;
    setState(() {
      _busy = true;
      _stats = '';
    });
    final r = await client.call(id, section: widget.section, args: args);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _stats = r.ok ? l10n.actionDone : l10n.actionFailed(r.message);
    });
    if (r.ok) {
      await _load();
      ref.read(snapshotProvider.notifier).refreshNow();
    }
  }
}
