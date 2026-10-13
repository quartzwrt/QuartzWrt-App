// Quartz 视觉 token 的 Flutter 映射（与 WP-2 主题同源，DESIGN §8）。
// 值取自 luci-theme-quartz/root/www/luci-static/quartz/cascade.css：
//   浅色：bg-base #ececf0 / panel #fff / accent #007aff / ok #34c759 / warn #ff9500 / err #ff3b30
//   暗色：bg-base #1c1c1e / panel #2c2c2e / raised #3a3a3c（暗色为参考稿原生）
import 'package:flutter/material.dart';

/// Quartz 色板（语义色，双模共用一组语义名）。
abstract final class QuartzColors {
  static const accent = Color(0xFF007AFF);
  static const ok = Color(0xFF34C759);
  static const warn = Color(0xFFFF9500);
  static const err = Color(0xFFFF3B30);

  static const lightBgBase = Color(0xFFECECF0);
  static const lightPanel = Color(0xFFFFFFFF);
  static const darkBgBase = Color(0xFF1C1C1E);
  static const darkPanel = Color(0xFF2C2C2E);
  static const darkRaised = Color(0xFF3A3A3C);
}

/// Quartz 圆角（DESIGN：圆角 ≤12px）。
abstract final class QuartzRadii {
  static const sm = 8.0;
  static const md = 12.0;
}

ThemeData buildQuartzTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: QuartzColors.accent,
    brightness: brightness,
  ).copyWith(
    primary: QuartzColors.accent,
    error: QuartzColors.err,
    surface: dark ? QuartzColors.darkPanel : QuartzColors.lightPanel,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? QuartzColors.darkBgBase : QuartzColors.lightBgBase,
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? QuartzColors.darkBgBase : QuartzColors.lightBgBase,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: dark ? QuartzColors.darkPanel : QuartzColors.lightPanel,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(QuartzRadii.md),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(QuartzRadii.sm),
        ),
      ),
    ),
  );
}
