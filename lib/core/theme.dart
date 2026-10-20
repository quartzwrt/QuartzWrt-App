// Quartz 主题：显式 ColorScheme + 显式 TextTheme，不再从 Material 3 种子色派生。
//
// 设计值来自 design/ia-v2-preview.html（与 WP-2 主题同源）。Material 仅保留
// 基础设施（MaterialApp / Scaffold / Navigator / Overlay / 文本编辑），
// 可见组件由 lib/widgets/quartz 下的 Quartz UI kit 提供。
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'design/quartz_tokens.dart';

export 'design/quartz_tokens.dart';

/// 兼容旧引用：语义色别名（新代码请直接用 [QuartzTokens]）。
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

ThemeData buildQuartzTheme(
  Brightness brightness, {
  double panelAlpha = 1,
  double blurSigma = 20,
}) {
  final t =
      (brightness == Brightness.dark ? QuartzTokens.dark : QuartzTokens.light)
          .copyWith(panelAlpha: panelAlpha, blurSigma: blurSigma);
  final scheme = ColorScheme(
    brightness: brightness,
    primary: t.accent,
    onPrimary: Colors.white,
    primaryContainer: t.accent.withValues(alpha: .16),
    onPrimaryContainer: t.accent,
    secondary: t.accent,
    onSecondary: Colors.white,
    secondaryContainer: t.accent.withValues(alpha: .16),
    onSecondaryContainer: t.accent,
    tertiary: t.ok,
    onTertiary: Colors.white,
    error: t.err,
    onError: Colors.white,
    surface: t.panel,
    onSurface: t.text,
    surfaceDim: t.bg,
    surfaceBright: t.panel,
    surfaceContainerLowest: t.panel,
    surfaceContainerLow: t.panel,
    surfaceContainer: t.panel,
    surfaceContainerHigh: t.raised,
    surfaceContainerHighest: t.raised,
    onSurfaceVariant: t.muted,
    outline: t.borderStrong,
    outlineVariant: t.border,
    shadow: Colors.black,
    scrim: t.scrim,
    inverseSurface: t.raised,
    onInverseSurface: t.text,
    inversePrimary: t.accent,
    surfaceTint: Colors.transparent,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: Colors.transparent,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: t.hover,
    focusColor: t.hover,
    dividerColor: t.border,
    textTheme: _textTheme(t),
    primaryTextTheme: _textTheme(t),
    iconTheme: IconThemeData(color: t.muted, size: 18),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 44,
      titleSpacing: 18,
      leadingWidth: 44,
      centerTitle: false,
      backgroundColor: t.bg,
      foregroundColor: t.text,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: QuartzType.screenTitle.copyWith(color: t.text),
      iconTheme: IconThemeData(color: t.muted, size: 20),
      actionsIconTheme: IconThemeData(color: t.muted, size: 20),
    ),
    cardTheme: CardThemeData(
      color: t.panel,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(QuartzRadii.md),
        side: BorderSide(color: t.border),
      ),
    ),
    dividerTheme: DividerThemeData(color: t.border, thickness: 1, space: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: t.raised,
      contentTextStyle: QuartzType.body.copyWith(color: t.text),
      actionTextColor: t.accent,
      elevation: 0,
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(QuartzRadii.md),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: t.raised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(QuartzRadii.sheet),
      ),
      titleTextStyle: QuartzType.heroTitle.copyWith(color: t.text),
      contentTextStyle: QuartzType.body.copyWith(color: t.muted),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: t.raised,
      modalBackgroundColor: t.raised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      showDragHandle: false,
      modalBarrierColor: t.scrim,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(QuartzRadii.sheet),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      fillColor: Colors.transparent,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(QuartzRadii.field),
        borderSide: BorderSide(color: t.borderStrong),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(QuartzRadii.field),
        borderSide: BorderSide(color: t.borderStrong),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(QuartzRadii.field),
        borderSide: BorderSide(color: t.accent),
      ),
      hintStyle: QuartzType.body.copyWith(color: t.faint),
      labelStyle: QuartzType.sub.copyWith(color: t.muted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, QuartzSizes.button),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        elevation: 0,
        backgroundColor: t.accent,
        foregroundColor: Colors.white,
        textStyle: QuartzType.button,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(QuartzRadii.button),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, QuartzSizes.button),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        foregroundColor: t.text,
        side: BorderSide(color: t.borderStrong),
        textStyle: QuartzType.button,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(QuartzRadii.button),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, QuartzSizes.tap),
        foregroundColor: t.accent,
        textStyle: QuartzType.buttonSmall,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(QuartzRadii.sm),
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(
          Size(QuartzSizes.tap, QuartzSizes.tap),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: WidgetStatePropertyAll(t.muted),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(QuartzRadii.sm),
          ),
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return t.faint;
        return Colors.white;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return t.well;
        return states.contains(WidgetState.selected) ? t.ok : t.well;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? Colors.transparent
            : t.borderStrong;
      }),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: t.accent,
      circularTrackColor: Colors.transparent,
      linearTrackColor: t.barTrack,
      linearMinHeight: 6,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: t.well,
      selectedColor: t.accent.withValues(alpha: .16),
      disabledColor: t.well,
      side: BorderSide(color: t.borderStrong),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(QuartzRadii.pill),
      ),
      labelStyle: QuartzType.tiny.copyWith(color: t.muted),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      elevation: 0,
      pressElevation: 0,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: t.raised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      textStyle: QuartzType.body.copyWith(color: t.text),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(QuartzRadii.md),
        side: BorderSide(color: t.borderStrong),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: t.accent,
      selectionColor: t.accent.withValues(alpha: .24),
      selectionHandleColor: t.accent,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      },
    ),
    extensions: [t],
  );
}

TextTheme _textTheme(QuartzTokens t) {
  TextStyle s(TextStyle base, [Color? color]) => base.copyWith(
    color: color ?? t.text,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  return TextTheme(
    displayLarge: s(QuartzType.metric),
    displayMedium: s(QuartzType.screenTitle),
    displaySmall: s(QuartzType.heroTitle),
    headlineLarge: s(QuartzType.metric),
    headlineMedium: s(QuartzType.metricM),
    headlineSmall: s(QuartzType.metric.copyWith(fontSize: 24)),
    titleLarge: s(QuartzType.screenTitle),
    titleMedium: s(QuartzType.heroTitle),
    titleSmall: s(QuartzType.bodyStrong),
    bodyLarge: s(QuartzType.body),
    bodyMedium: s(QuartzType.body),
    bodySmall: s(QuartzType.sub, t.muted),
    labelLarge: s(QuartzType.button),
    labelMedium: s(QuartzType.label, t.muted),
    labelSmall: s(QuartzType.caption, t.muted),
  );
}
