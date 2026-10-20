// App 本机外观偏好：不透明度 / 模糊 / 壁纸路径。
//
// 与网页端 /etc/config/quartz 无写关系；这些值只保存在 SharedPreferences，
// 壁纸文件也只落 App 私有目录。主题模式仍沿用 ThemeModeNotifier。
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_state.dart';

class AppearanceState {
  const AppearanceState({
    this.opacity = 1.0,
    this.blur = 20.0,
    this.wallpaperPath,
  });

  final double opacity; // 0.5–1.0
  final double blur; // 0–40
  final String? wallpaperPath;

  AppearanceState copyWith({
    double? opacity,
    double? blur,
    String? wallpaperPath,
    bool clearWallpaper = false,
  }) => AppearanceState(
    opacity: opacity ?? this.opacity,
    blur: blur ?? this.blur,
    wallpaperPath: clearWallpaper
        ? null
        : (wallpaperPath ?? this.wallpaperPath),
  );
}

class AppearanceNotifier extends Notifier<AppearanceState> {
  static const _kOpacity = 'qz.panel_opacity';
  static const _kBlur = 'qz.blur';
  static const _kWallpaper = 'qz.wallpaper_path';

  @override
  AppearanceState build() {
    final p = ref.watch(prefsProvider);
    return AppearanceState(
      opacity: (p.getDouble(_kOpacity) ?? 1.0).clamp(.5, 1.0),
      blur: (p.getDouble(_kBlur) ?? 20.0).clamp(0, 40),
      wallpaperPath: p.getString(_kWallpaper),
    );
  }

  Future<void> setOpacity(double v) async {
    final next = v.clamp(.5, 1.0).toDouble();
    state = state.copyWith(opacity: next);
    await ref.read(prefsProvider).setDouble(_kOpacity, next);
  }

  Future<void> setBlur(double v) async {
    final next = v.clamp(0, 40).toDouble();
    state = state.copyWith(blur: next);
    await ref.read(prefsProvider).setDouble(_kBlur, next);
  }

  Future<void> setWallpaperPath(String? path) async {
    state = state.copyWith(wallpaperPath: path, clearWallpaper: path == null);
    final p = ref.read(prefsProvider);
    if (path == null) {
      await p.remove(_kWallpaper);
    } else {
      await p.setString(_kWallpaper, path);
    }
  }

  Future<void> reset() async {
    state = const AppearanceState();
    final p = ref.read(prefsProvider);
    await p.remove(_kOpacity);
    await p.remove(_kBlur);
    await p.remove(_kWallpaper);
  }
}

final appearanceProvider =
    NotifierProvider<AppearanceNotifier, AppearanceState>(
      AppearanceNotifier.new,
    );
