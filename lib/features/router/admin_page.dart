// 路由器 · 管理权（W6.11）：root 密码 + SSH（dropbear）。
//
// 密码改走 `luci.set_password` 动作（busybox passwd 写 /etc/shadow），
// 不经过 UCI 配置面，也不进入 90s 回滚安全网；App 侧二次确认 + 风险文案。
// SSH 字段走 `config.*`（dropbear 注册表），保存后需重启 dropbear 才生效。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/config.dart';
import '../../api/luci.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/quartz.dart';
import 'config_common.dart';

class AdminPage extends ConsumerStatefulWidget {
  const AdminPage({super.key});

  @override
  ConsumerState<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends ConsumerState<AdminPage> {
  bool _loading = true;
  bool _busy = false;
  bool _pwBusy = false;
  String _error = '';
  String _sshSection = '@dropbear[0]';
  Map<String, dynamic> _ssh = const {};
  bool _hasSsh = false;
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pw.dispose();
    _pw2.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final client = ref.read(configClientProvider);
    if (client == null) return;
    setState(() {
      _loading = true;
      _error = '';
    });
    final r = await client.read('dropbear');
    if (!mounted) return;
    if (!r.ok) {
      setState(() {
        _loading = false;
        _error = configErrorText(AppL10n.of(context), r.error);
      });
      return;
    }
    String section = '@dropbear[0]';
    Map<String, dynamic> values = const {};
    if (r.map.isNotEmpty) {
      section = r.map.keys.firstWhere((k) => k.contains('dropbear'), orElse: () => r.map.keys.first);
      final v = r.map[section];
      if (v is Map<String, dynamic>) values = v;
    }
    setState(() {
      _sshSection = section;
      _ssh = values;
      _hasSsh = r.map.isNotEmpty;
      _loading = false;
    });
  }

  List<ConfigField> _sshFields(AppL10n l10n) => [
        ConfigField('enable', l10n.adminSshEnable, kind: ConfigFieldKind.boolean,
            hint: l10n.adminSshEnableHint),
        ConfigField('Interface', l10n.adminSshInterface, hint: l10n.adminSshInterfaceHint),
        ConfigField('Port', l10n.adminSshPort, kind: ConfigFieldKind.integer, min: 1, max: 65535),
        ConfigField('PasswordAuth', l10n.adminPasswordAuth, kind: ConfigFieldKind.choice, choices: [
          ConfigChoice('on', l10n.adminOn),
          ConfigChoice('off', l10n.adminOff),
        ]),
        ConfigField('RootPasswordAuth', l10n.adminRootPasswordAuth, kind: ConfigFieldKind.choice, choices: [
          ConfigChoice('on', l10n.adminOn),
          ConfigChoice('off', l10n.adminOff),
        ]),
        ConfigField('GatewayPorts', l10n.adminGatewayPorts, kind: ConfigFieldKind.choice, choices: [
          ConfigChoice('on', l10n.adminOn),
          ConfigChoice('off', l10n.adminOff),
        ]),
      ];

  Future<void> _changePassword() async {
    final l10n = AppL10n.of(context);
    final p1 = _pw.text;
    final p2 = _pw2.text;
    if (p1.length < 6) {
      showConfigSnack(context, l10n.adminPasswordTooShort);
      return;
    }
    if (p1 != p2) {
      showConfigSnack(context, l10n.adminPasswordMismatch);
      return;
    }
    final ok = await showConfirmSheet(
      context,
      title: l10n.adminPasswordTitle,
      body: l10n.adminPasswordWarning,
      confirmLabel: l10n.confirm,
      cancelLabel: l10n.cancel,
      danger: true,
    );
    if (!ok) return;
    final luci = ref.read(luciClientProvider);
    if (luci == null) return;
    setState(() => _pwBusy = true);
    final r = await luci.setPassword('root', p1);
    if (!mounted) return;
    setState(() => _pwBusy = false);
    if (!r.ok) {
      showConfigSnack(context, configErrorText(l10n, r.error));
      return;
    }
    if (r.map['result'] != true) {
      showConfigSnack(context, l10n.adminPasswordFailed);
      return;
    }
    _pw.clear();
    _pw2.clear();
    showConfigSnack(context, l10n.adminPasswordChanged);
  }

  Future<void> _restartSsh() async {
    final l10n = AppL10n.of(context);
    final ok = await showConfirmSheet(
      context,
      title: l10n.adminSshRestart,
      body: l10n.adminSshRestartWarning,
      confirmLabel: l10n.confirm,
      cancelLabel: l10n.cancel,
      danger: true,
    );
    if (!ok) return;
    final luci = ref.read(luciClientProvider);
    if (luci == null) return;
    setState(() => _busy = true);
    final r = await luci.initAction('dropbear', 'restart');
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.ok) {
      showConfigSnack(context, l10n.adminSshRestarted);
    } else {
      showConfigSnack(context, configErrorText(l10n, r.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: .5);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.routerEntryAdmin, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
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
                  title: l10n.adminPasswordTitle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.adminPasswordHint,
                          style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _pw,
                        obscureText: _obscure,
                        enabled: !_pwBusy,
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: l10n.adminNewPassword,
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            tooltip: _obscure ? l10n.adminShowPassword : l10n.adminHidePassword,
                            onPressed: () => setState(() => _obscure = !_obscure),
                            icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _pw2,
                        obscureText: _obscure,
                        enabled: !_pwBusy,
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: l10n.adminConfirmPassword,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _pwBusy ? null : _changePassword,
                          child: Text(_pwBusy ? l10n.configSaving : l10n.adminChangePassword),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                if (!_hasSsh)
                  QuartzCard(
                    title: l10n.adminSshTitle,
                    child: Text(l10n.adminSshUnavailable,
                        style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                  )
                else ...[
                  ConfigGroupEditor(
                    config: 'dropbear',
                    section: _sshSection,
                    title: l10n.adminSshTitle,
                    subtitle: l10n.adminSshHint,
                    fields: _sshFields(l10n),
                    initial: _ssh,
                    onSaved: _load,
                  ),
                  const SizedBox(height: 4),
                  QuartzCard(
                    title: l10n.adminSshService,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.adminSshRestartHint,
                            style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _busy ? null : _restartSsh,
                            icon: const Icon(Icons.restart_alt, size: 18),
                            label: Text(l10n.adminSshRestart),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(l10n.adminNote,
                    style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                const SizedBox(height: 16),
              ],
            ),
    );
  }
}
