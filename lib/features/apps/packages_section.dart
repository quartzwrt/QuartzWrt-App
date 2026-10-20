// 软件包管理子段（UI-DESIGN ⑤b，定案）：可升级 / 已安装 / 全部（搜索）。
//
// 数据面 = WP-5 `packages` 方法（分页，scope=upgradable|installed|available）；
// 动作 = `packages.refresh`（刷新索引）/ `packages.upgrade`（单包/全部）/
// `packages.remove`（卸载，危险动作 → 底部确认层）。安装新包 v1 后置。
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/envelope.dart';
import '../../api/packages.dart';
import '../../core/theme.dart';
import '../../format.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../widgets/quartz.dart';

enum PkgView { upgradable, installed, all }

class PackagesSection extends ConsumerStatefulWidget {
  const PackagesSection({super.key});

  @override
  ConsumerState<PackagesSection> createState() => _PackagesSectionState();
}

class _PackagesSectionState extends ConsumerState<PackagesSection> {
  PkgView _view = PkgView.upgradable;
  final _searchCtl = TextEditingController();
  Timer? _debounce;

  PackagesPage? _data;
  bool _busy = false; // 首屏 / 换视图加载
  bool _loadingMore = false; // 追加下一页
  bool _acting = false; // 动作执行中（刷新/升级/卸载）
  String? _error; // 非「API 缺失」类错误
  bool _apiMissing = false; // 路由器未提供 packages 方法（降级说明卡）
  String _query = '';
  int _upgradableTotal = 0;

  static const _perPage = 24;

  String get _scope => switch (_view) {
    PkgView.upgradable => 'upgradable',
    PkgView.installed => 'installed',
    PkgView.all => 'available',
  };

  @override
  void initState() {
    super.initState();
    _load();
    _loadUpgradableTotal();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _loadUpgradableTotal() async {
    final tm = ref.read(tokenManagerProvider);
    if (tm == null) return;
    final r = await tm.call('packages', {
      'scope': 'upgradable',
      'page': 1,
      'per_page': 1,
    });
    if (!mounted || !r.ok) return;
    setState(() => _upgradableTotal = PackagesPage.fromPayload(r.data).total);
  }

  Future<void> _load({bool more = false}) async {
    final tm = ref.read(tokenManagerProvider);
    if (tm == null) {
      setState(() => _apiMissing = true);
      return;
    }
    setState(() {
      if (more) {
        _loadingMore = true;
      } else {
        _busy = true;
        _error = null;
      }
    });
    final page = more ? (_data?.page ?? 0) + 1 : 1;
    final r = await tm.call('packages', {
      'scope': _scope,
      if (_view == PkgView.all && _query.isNotEmpty) 'query': _query,
      'page': page,
      'per_page': _perPage,
    });
    if (!mounted) return;
    setState(() {
      _busy = false;
      _loadingMore = false;
      if (r.ok) {
        _apiMissing = false;
        final pg = PackagesPage.fromPayload(r.data);
        _data = more ? (_data ?? pg).appended(pg) : pg;
      } else if (r.error?.code == 'bad_request') {
        _apiMissing = true; // 方法不存在（旧固件）
        _data = null;
      } else {
        _error = r.error?.detail?.isNotEmpty == true
            ? r.error!.detail!
            : (r.error?.message ?? '');
      }
    });
  }

  void _switchView(PkgView v) {
    if (v == _view) return;
    setState(() {
      _view = v;
      _data = null;
      _error = null;
    });
    if (v != PkgView.all || _query.isNotEmpty) _load();
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _query = q.trim();
      setState(() => _data = null);
      if (_query.isEmpty) {
        setState(() {}); // 空查询 → 提示词，不加载
        return;
      }
      _load();
    });
  }

  // ---- 动作 ----

  Future<void> _runAction(String action, {String? name}) async {
    final tm = ref.read(tokenManagerProvider);
    if (tm == null || _acting) return;
    setState(() => _acting = true);
    final r = await tm.call('action', {
      'action': action,
      'args': {'name': ?name},
    });
    if (!mounted) return;
    final l10n = AppL10n.of(context);
    var msg = r.ok ? l10n.actionDone : l10n.actionFailed(_errText(r));
    if (r.ok && action == 'packages.refresh') {
      final ms = (r.data['result'] as Map?)?['duration_ms'];
      msg = l10n.pkgRefreshDone(((ms as num?)?.toInt() ?? 0) ~/ 1000);
    }
    if (r.ok && action == 'packages.upgrade' && name != null) {
      msg = l10n.pkgUpgraded(name);
    }
    if (r.ok && action == 'packages.remove') msg = l10n.pkgRemoved(name ?? '');
    showQzToast(context, msg);
    setState(() => _acting = false);
    _load();
    _loadUpgradableTotal();
  }

  String _errText(ApiResult r) {
    final e = r.error;
    if (e == null) return '';
    return e.detail?.isNotEmpty == true ? e.detail! : e.message;
  }

  Future<void> _refreshIndex() => _runAction('packages.refresh');

  Future<void> _upgradeAll() async {
    final l10n = AppL10n.of(context);
    final n = _data?.total ?? _upgradableTotal;
    final ok = await showConfirmSheet(
      context,
      title: l10n.pkgUpgradeAllConfirmTitle,
      body: l10n.pkgUpgradeAllConfirmBody(n),
      confirmLabel: l10n.confirm,
      cancelLabel: l10n.cancel,
    );
    if (!ok || !mounted) return;
    await _runAction('packages.upgrade');
  }

  Future<void> _upgradeOne(String name) =>
      _runAction('packages.upgrade', name: name);

  Future<void> _remove(String name) async {
    final l10n = AppL10n.of(context);
    final ok = await showConfirmSheet(
      context,
      title: l10n.pkgRemoveConfirmTitle(name),
      body: l10n.pkgRemoveConfirmBody,
      confirmLabel: l10n.pkgRemove,
      cancelLabel: l10n.cancel,
      danger: true,
    );
    if (!ok || !mounted) return;
    await _runAction('packages.remove', name: name);
  }

  /// 已安装包行：动作底部层（升级/卸载）。
  Future<void> _installedActions(PackageItem p) async {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    await showQzSheet<void>(
      context,
      backgroundColor: dark ? QuartzColors.darkRaised : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                p.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                [
                  p.version,
                  if (p.installedSize > 0) formatBytes(p.installedSize),
                  if (p.origin.isNotEmpty) p.origin,
                ].join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: .5),
                ),
              ),
              const SizedBox(height: 12),
              if (p.upgradable)
                QzListRow(
                  first: true,
                  title: l10n.pkgUpgradeTo(
                    p.targetVersion.isNotEmpty
                        ? p.targetVersion
                        : p.installedVersion,
                  ),
                  trailing: const QzIcon(QzIcons.download, size: 18),
                  showChevron: false,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 10,
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _upgradeOne(p.name);
                  },
                ),
              QzListRow(
                first: !p.upgradable,
                title: l10n.pkgRemove,
                danger: true,
                trailing: const QzIcon(
                  QzIcons.delete,
                  size: 18,
                  color: QuartzColors.err,
                ),
                showChevron: false,
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 10,
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _remove(p.name);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 未安装包行（搜索视图）：安装 v1 后置说明。
  void _notInstalledNote(PackageItem p) {
    final l10n = AppL10n.of(context);
    showQzSheet<void>(
      context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                [
                  p.version,
                  if (p.fileSize > 0) formatBytes(p.fileSize),
                ].join(' · '),
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                  color: Theme.of(ctx).colorScheme.onSurface
                      .withValues(alpha: .5),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.installNewBody,
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- 渲染 ----

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    if (_apiMissing) return _missingApi(l10n);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: QzTabs<PkgView>(
            values: const [PkgView.upgradable, PkgView.installed, PkgView.all],
            selected: _view,
            labelOf: (v) => switch (v) {
              PkgView.upgradable =>
                _upgradableTotal > 0
                    ? l10n.pkgViewUpgradableN(_upgradableTotal)
                    : l10n.pkgViewUpgradable,
              PkgView.installed => l10n.pkgViewInstalled,
              PkgView.all => l10n.pkgViewAll,
            },
            onChanged: _switchView,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              if (_view == PkgView.upgradable && (_data?.total ?? 0) > 0)
                QzLegacyButton.tonal(
                  onPressed: _acting ? null : _upgradeAll,
                  child: _acting
                      ? const _MiniSpinner()
                      : Text(l10n.upgradeAllBtn(_data?.total ?? 0)),
                ),
              const Spacer(),
              QzLegacyButton.icon(
                kind: QzButtonKind.ghost,
                onPressed: _acting ? null : _refreshIndex,
                icon: _acting
                    ? const _MiniSpinner()
                    : const Icon(Icons.refresh, size: 18),
                label: Text(l10n.opReindex),
              ),
            ],
          ),
        ),
        if (_view == PkgView.all)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: QzField(
              controller: _searchCtl,
              hint: l10n.pkgSearchHint,
              prefix: const QzIcon(QzIcons.search, size: 18),
              onChanged: _onSearchChanged,
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: QuartzCard(
              title: l10n.unavailable,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_error!, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  QzLegacyButton(
                    kind: QzButtonKind.plain,
                    onPressed: () => _load(),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          ),
        Expanded(child: _list(l10n)),
      ],
    );
  }

  Widget _missingApi(AppL10n l10n) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
        const SizedBox(height: 8),
        QzLegacyButton(
          kind: QzButtonKind.plain,
          onPressed: () => _load(),
          child: Text(l10n.retry),
        ),
      ],
    );
  }

  Widget _list(AppL10n l10n) {
    if (_view == PkgView.all && _query.isEmpty) {
      return _hint(l10n.pkgSearchPrompt);
    }
    if (_busy && _data == null) {
      return const Center(child: QzSpinner(size: 22));
    }
    final items = _data?.items ?? const <PackageItem>[];
    if (items.isEmpty) {
      return _hint(switch (_view) {
        PkgView.upgradable => l10n.pkgEmptyUpgradable,
        PkgView.installed => l10n.pkgEmptyInstalled,
        PkgView.all => l10n.pkgSearchNone,
      });
    }
    final data = _data!;
    return QzRefresh(
      onRefresh: () => _load(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        itemCount: items.length + 1,
        itemBuilder: (context, i) {
          if (i == items.length) return _footer(l10n, data, items.length);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _row(l10n, items[i]),
          );
        },
      ),
    );
  }

  Widget _hint(String text) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(24),
    children: [
      Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface
                .withValues(alpha: .55),
            height: 1.6,
          ),
        ),
      ),
    ],
  );

  Widget _footer(AppL10n l10n, PackagesPage data, int shown) {
    if (!data.hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Text(
            l10n.pkgShownOf(shown, data.total),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface
                  .withValues(alpha: .4),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: _loadingMore
            ? const _MiniSpinner()
            : QzLegacyButton(
                kind: QzButtonKind.plain,
                onPressed: () => _load(more: true),
                child: Text(l10n.pkgLoadMore(shown, data.total)),
              ),
      ),
    );
  }

  Widget _row(AppL10n l10n, PackageItem p) {
    final theme = Theme.of(context);
    final sub = switch (_view) {
      PkgView.upgradable => [
        '${p.installedVersion} → ${p.version}',
        if (p.fileSize > 0) formatBytes(p.fileSize),
      ].join(' · '),
      PkgView.installed => [
        p.version,
        if (p.installedSize > 0) formatBytes(p.installedSize),
      ].join(' · '),
      PkgView.all => [
        p.version,
        if (p.fileSize > 0) formatBytes(p.fileSize),
      ].join(' · '),
    };
    return QuartzCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        p.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (_view == PkgView.all && p.installed) ...[
                      const SizedBox(width: 6),
                      _chip(
                        l10n.pkgBadgeInstalled,
                        p.upgradable ? QuartzColors.warn : QuartzColors.ok,
                      ),
                    ],
                    if (_view == PkgView.installed && p.upgradable) ...[
                      const SizedBox(width: 6),
                      _chip(l10n.pkgBadgeUpgrade, QuartzColors.warn),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: .55),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          if (_view == PkgView.upgradable)
            QzLegacyButton(
              kind: QzButtonKind.ghost,
              onPressed: _acting ? null : () => _upgradeOne(p.name),
              child: Text(l10n.pkgUpgrade),
            )
          else
            QzLegacyIconButton(
              icon: const QzIcon(QzIcons.chevronRight, size: 18),
              onPressed: () => _view == PkgView.installed || p.installed
                  ? _installedActions(p)
                  : _notInstalledNote(p),
            ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color.withValues(alpha: .4)),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
    ),
  );
}

class _MiniSpinner extends StatelessWidget {
  const _MiniSpinner();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 16,
    height: 16,
    child: QzSpinner(size: 16, stroke: 2),
  );
}
