// App 外观（本机）：模式 / 不透明度 / 模糊 / 壁纸。
// 与网页端 /etc/config/quartz 无写关系；壁纸只落 App 私有目录。
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../state/appearance.dart';
import '../../widgets/quartz.dart';

class AppearancePage extends ConsumerWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final t = QuartzTokens.of(context);
    final a = ref.watch(appearanceProvider);
    final mode = ref.watch(themeModeProvider);
    final path = a.wallpaperPath;

    return Scaffold(
      appBar: QzAppBar(titleText: l10n.appearanceTitle),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _preview(context, ref, l10n, a, path),
          QuartzCard(
            title: l10n.appearanceMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                QzSegmented<ThemeMode>(
                  values: const [
                    ThemeMode.system,
                    ThemeMode.dark,
                    ThemeMode.light,
                  ],
                  selected: mode,
                  labelOf: (m) => switch (m) {
                    ThemeMode.system => l10n.followSystem,
                    ThemeMode.dark => l10n.modeDark,
                    ThemeMode.light => l10n.modeLight,
                  },
                  onChanged: (m) => ref.read(themeModeProvider.notifier).set(m),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.appearanceModeHint,
                  style: QuartzType.caption.copyWith(color: t.faint),
                ),
              ],
            ),
          ),
          QuartzCard(
            title: l10n.appearanceMaterial,
            trailing: Text(
              l10n.appearancePreview,
              style: QuartzType.caption.copyWith(color: t.faint),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sliderHead(
                  context,
                  l10n.appearanceOpacity,
                  '${(a.opacity * 100).round()}%',
                ),
                QzSlider(
                  value: a.opacity * 100,
                  min: 50,
                  max: 100,
                  onChanged: (v) =>
                      ref.read(appearanceProvider.notifier).setOpacity(v / 100),
                ),
                Text(
                  l10n.appearanceOpacityHint,
                  style: QuartzType.caption.copyWith(color: t.faint),
                ),
                const SizedBox(height: 12),
                _sliderHead(
                  context,
                  l10n.appearanceBlur,
                  '${a.blur.round()} px',
                ),
                QzSlider(
                  value: a.blur,
                  min: 0,
                  max: 40,
                  onChanged: (v) =>
                      ref.read(appearanceProvider.notifier).setBlur(v),
                ),
                Text(
                  l10n.appearanceBlurHint,
                  style: QuartzType.caption.copyWith(color: t.faint),
                ),
              ],
            ),
          ),
          QuartzCard(
            title: l10n.appearanceWallpaper,
            trailing: Text(
              l10n.appearanceLocal,
              style: QuartzType.caption.copyWith(color: t.faint),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _thumb(context, path),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            path == null
                                ? l10n.appearanceDefaultNoise
                                : 'quartz-wallpaper',
                            style: QuartzType.bodyStrong.copyWith(
                              color: t.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            path == null
                                ? l10n.appearanceWallpaperEmpty
                                : _fileMeta(path),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: t.muted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              QzButton(
                                label: path == null
                                    ? l10n.appearanceChooseWallpaper
                                    : l10n.appearanceChangeWallpaper,
                                kind: QzButtonKind.plain,
                                size: QzButtonSize.small,
                                onPressed: () => _pick(context, ref, l10n),
                              ),
                              if (path != null) ...[
                                const SizedBox(width: 7),
                                QzButton(
                                  label: l10n.appearanceRemoveWallpaper,
                                  kind: QzButtonKind.danger,
                                  size: QzButtonSize.small,
                                  onPressed: () =>
                                      _remove(context, ref, l10n, path),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.appearanceWallpaperHint,
                  style: QuartzType.caption.copyWith(color: t.faint),
                ),
              ],
            ),
          ),
          QuartzCard(
            child: QzButton(
              label: l10n.appearanceReset,
              kind: QzButtonKind.plain,
              expand: true,
              onPressed: () => _reset(context, ref, l10n, path),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 8, 12),
            child: Text(
              l10n.appearanceLocalOnly,
              textAlign: TextAlign.center,
              style: QuartzType.caption.copyWith(color: t.faint),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sliderHead(BuildContext context, String label, String value) {
    final t = QuartzTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: QuartzType.body.copyWith(color: t.text)),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: t.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _preview(
    BuildContext context,
    WidgetRef ref,
    AppL10n l10n,
    AppearanceState a,
    String? path,
  ) {
    final t = QuartzTokens.of(context);
    final noise = t.isDark
        ? 'assets/background/noise-dark.png'
        : 'assets/background/noise-light.png';
    final hasWall = path != null && File(path).existsSync();
    return QuartzCard(
      padding: const EdgeInsets.all(9),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: t.well,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: t.borderStrong),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 132,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [t.raised.withValues(alpha: .55), t.well],
                        ),
                      ),
                    ),
                    if (hasWall)
                      Image.file(
                        File(path),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Image.asset(
                          noise,
                          repeat: ImageRepeat.repeat,
                          fit: BoxFit.none,
                        ),
                      )
                    else
                      Image.asset(
                        noise,
                        repeat: ImageRepeat.repeat,
                        fit: BoxFit.none,
                      ),
                    if (hasWall)
                      ColoredBox(
                        color: t.isDark
                            ? const Color(0x73000000)
                            : const Color(0x8CF2F2F7),
                      ),
                    if (!hasWall)
                      Positioned(
                        left: 12,
                        bottom: 10,
                        child: Text(
                          l10n.appearanceDefaultNoise,
                          style: QuartzType.caption.copyWith(color: t.faint),
                        ),
                      ),
                    Positioned(
                      right: 12,
                      top: 14,
                      width: 220,
                      child: QzPanel(
                        padding: const EdgeInsets.all(10),
                        borderRadius: BorderRadius.circular(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                StatusDot(
                                  DotKind.ok,
                                  margin: const EdgeInsets.only(right: 6),
                                ),
                                Expanded(
                                  child: Text(
                                    'QuartzWrt-FNet',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: t.text,
                                    ),
                                  ),
                                ),
                                Text(
                                  '5G CPE',
                                  style: TextStyle(fontSize: 9, color: t.faint),
                                ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            _previewRow(context, 'WAN', '100.64.7.23'),
                            _previewRow(context, 'CPU', '8%'),
                            const SizedBox(height: 7),
                            QzBar(pct: .42, height: 4),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Text(
                l10n.appearancePreview,
                style: QuartzType.caption.copyWith(color: t.faint),
              ),
              const Spacer(),
              Text(
                '${(a.opacity * 100).round()}% · ${a.blur.round()}px',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10.5,
                  color: t.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _previewRow(BuildContext context, String k, String v) {
    final t = QuartzTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Text(k, style: TextStyle(fontSize: 9.5, color: t.muted)),
          const Spacer(),
          Text(
            v,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: t.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumb(BuildContext context, String? path) {
    final t = QuartzTokens.of(context);
    final noise = t.isDark
        ? 'assets/background/noise-dark.png'
        : 'assets/background/noise-light.png';
    final hasWall = path != null && File(path).existsSync();
    return Container(
      width: 112,
      height: 64,
      decoration: BoxDecoration(
        color: t.well,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.borderStrong),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: hasWall
            ? Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Image.asset(
                  noise,
                  repeat: ImageRepeat.repeat,
                  fit: BoxFit.none,
                ),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    noise,
                    repeat: ImageRepeat.repeat,
                    fit: BoxFit.none,
                  ),
                  Center(
                    child: QzIcon(QzIcons.spark, size: 18, color: t.faint),
                  ),
                ],
              ),
      ),
    );
  }

  String _fileMeta(String path) {
    try {
      final f = File(path);
      final bytes = f.lengthSync();
      final mb = bytes / (1024 * 1024);
      return '${mb.toStringAsFixed(1)} MB · JPEG';
    } catch (_) {
      return '—';
    }
  }

  static const _maxWallpaperBytes = 2 * 1024 * 1024;

  Future<void> _pick(BuildContext context, WidgetRef ref, AppL10n l10n) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        imageQuality: 90,
      );
      if (picked == null) return;
      if (await picked.length() > _maxWallpaperBytes) {
        if (context.mounted) {
          showQzToast(
            context,
            l10n.appearanceWallpaperTooLarge,
            kind: QzToastKind.err,
          );
        }
        return;
      }
      final dir = await getApplicationDocumentsDirectory();
      final dest = File('${dir.path}/quartz-wallpaper.jpg');
      await File(picked.path).copy(dest.path);
      // 文件路径不变时 Flutter 的图片缓存会继续返回旧图，换图后必须显式失效。
      await FileImage(dest).evict();
      await ref.read(appearanceProvider.notifier).setWallpaperPath(dest.path);
    } catch (e) {
      if (context.mounted) {
        showQzToast(
          context,
          l10n.appearanceWallpaperFailed(e.toString()),
          kind: QzToastKind.err,
        );
      }
    }
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    AppL10n l10n,
    String path,
  ) async {
    try {
      final f = File(path);
      if (f.existsSync()) await f.delete();
    } catch (_) {}
    await ref.read(appearanceProvider.notifier).setWallpaperPath(null);
    if (context.mounted) {
      showQzToast(context, l10n.appearanceWallpaperEmpty, kind: QzToastKind.ok);
    }
  }

  Future<void> _reset(
    BuildContext context,
    WidgetRef ref,
    AppL10n l10n,
    String? path,
  ) async {
    if (path != null) {
      try {
        final f = File(path);
        if (f.existsSync()) await f.delete();
      } catch (_) {}
    }
    await ref.read(themeModeProvider.notifier).set(ThemeMode.system);
    await ref.read(appearanceProvider.notifier).reset();
    if (context.mounted) {
      showQzToast(context, l10n.appearanceResetDone, kind: QzToastKind.ok);
    }
  }
}
