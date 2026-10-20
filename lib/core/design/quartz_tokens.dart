// Quartz 设计 token（与 luci-theme-quartz / design/ia-v2-preview.html 同源）。
//
// 这里只放"值"：颜色、字号、间距、圆角、高度、动效。页面和组件不得再写
// 一次性颜色/字号；新增视觉规格先落到本文件，再被 UI kit 引用。
import 'package:flutter/material.dart';

/// 语义色板。深浅两套，字段一一对应。
@immutable
class QuartzTokens extends ThemeExtension<QuartzTokens> {
  const QuartzTokens({
    required this.brightness,
    required this.bg,
    required this.panel,
    required this.well,
    required this.raised,
    required this.chrome,
    required this.tabChrome,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.muted,
    required this.faint,
    required this.hover,
    required this.segTrack,
    required this.barTrack,
    required this.scrim,
    required this.panelAlpha,
    required this.blurSigma,
    required this.accent,
    required this.ok,
    required this.warn,
    required this.err,
  });

  final Brightness brightness;
  final Color bg;
  final Color panel;
  final Color well;
  final Color raised;
  final Color chrome;
  final Color tabChrome;
  final Color border;
  final Color borderStrong;
  final Color text;
  final Color muted;
  final Color faint;
  final Color hover;
  final Color segTrack;
  final Color barTrack;
  final Color scrim;

  /// 面板/ chrome 不透明度（0.5–1.0）与背景模糊强度（0–40px）。
  final double panelAlpha;
  final double blurSigma;
  final Color accent;
  final Color ok;
  final Color warn;
  final Color err;

  bool get isDark => brightness == Brightness.dark;

  static const dark = QuartzTokens(
    brightness: Brightness.dark,
    bg: Color(0xFF1C1C1E),
    panel: Color(0xFF2C2C2E),
    well: Color(0xFF1C1C1E),
    raised: Color(0xFF3A3A3C),
    chrome: Color(0xCC1C1C1E),
    tabChrome: Color(0x9E1C1C1E),
    border: Color(0x14FFFFFF),
    borderStrong: Color(0x1FFFFFFF),
    text: Color(0xD9FFFFFF),
    muted: Color(0x8CFFFFFF),
    faint: Color(0x4DFFFFFF),
    hover: Color(0x0AFFFFFF),
    segTrack: Color(0xFF1C1C1E),
    barTrack: Color(0xFF1C1C1E),
    scrim: Color(0x73000000),
    panelAlpha: 1.0,
    blurSigma: 20.0,
    accent: Color(0xFF007AFF),
    ok: Color(0xFF34C759),
    warn: Color(0xFFFF9500),
    err: Color(0xFFFF3B30),
  );

  static const light = QuartzTokens(
    brightness: Brightness.light,
    bg: Color(0xFFECECF0),
    panel: Color(0xFFFFFFFF),
    well: Color(0xFFF2F2F7),
    raised: Color(0xFFFFFFFF),
    chrome: Color(0xB8F2F2F7),
    tabChrome: Color(0xA8FFFFFF),
    border: Color(0x14000000),
    borderStrong: Color(0x1F000000),
    text: Color(0xD9000000),
    muted: Color(0x8C000000),
    faint: Color(0x4D000000),
    hover: Color(0x0A000000),
    segTrack: Color(0xFFE6E6EB),
    barTrack: Color(0xFFE4E4E9),
    scrim: Color(0x73000000),
    panelAlpha: 1.0,
    blurSigma: 20.0,
    accent: Color(0xFF007AFF),
    ok: Color(0xFF34C759),
    warn: Color(0xFFFF9500),
    err: Color(0xFFFF3B30),
  );

  static QuartzTokens of(BuildContext context) =>
      Theme.of(context).extension<QuartzTokens>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  @override
  QuartzTokens copyWith({
    Brightness? brightness,
    Color? bg,
    Color? panel,
    Color? well,
    Color? raised,
    Color? chrome,
    Color? tabChrome,
    Color? border,
    Color? borderStrong,
    Color? text,
    Color? muted,
    Color? faint,
    Color? hover,
    Color? segTrack,
    Color? barTrack,
    Color? scrim,
    double? panelAlpha,
    double? blurSigma,
    Color? accent,
    Color? ok,
    Color? warn,
    Color? err,
  }) {
    return QuartzTokens(
      brightness: brightness ?? this.brightness,
      bg: bg ?? this.bg,
      panel: panel ?? this.panel,
      well: well ?? this.well,
      raised: raised ?? this.raised,
      chrome: chrome ?? this.chrome,
      tabChrome: tabChrome ?? this.tabChrome,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      faint: faint ?? this.faint,
      hover: hover ?? this.hover,
      segTrack: segTrack ?? this.segTrack,
      barTrack: barTrack ?? this.barTrack,
      scrim: scrim ?? this.scrim,
      panelAlpha: panelAlpha ?? this.panelAlpha,
      blurSigma: blurSigma ?? this.blurSigma,
      accent: accent ?? this.accent,
      ok: ok ?? this.ok,
      warn: warn ?? this.warn,
      err: err ?? this.err,
    );
  }

  @override
  QuartzTokens lerp(ThemeExtension<QuartzTokens>? other, double t) {
    if (other is! QuartzTokens) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return QuartzTokens(
      brightness: t < .5 ? brightness : other.brightness,
      bg: c(bg, other.bg),
      panel: c(panel, other.panel),
      well: c(well, other.well),
      raised: c(raised, other.raised),
      chrome: c(chrome, other.chrome),
      tabChrome: c(tabChrome, other.tabChrome),
      border: c(border, other.border),
      borderStrong: c(borderStrong, other.borderStrong),
      text: c(text, other.text),
      muted: c(muted, other.muted),
      faint: c(faint, other.faint),
      hover: c(hover, other.hover),
      segTrack: c(segTrack, other.segTrack),
      barTrack: c(barTrack, other.barTrack),
      scrim: c(scrim, other.scrim),
      panelAlpha: t < .5 ? panelAlpha : other.panelAlpha,
      blurSigma: t < .5 ? blurSigma : other.blurSigma,
      accent: c(accent, other.accent),
      ok: c(ok, other.ok),
      warn: c(warn, other.warn),
      err: c(err, other.err),
    );
  }
}

/// 字号/字重/字距（设计稿：13.5 body、12.5 sub、11.5 caption、22 标题、25 大数字）。
abstract final class QuartzType {
  static const screenTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: .1,
    height: 1.2,
  );
  static const heroTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );
  static const body = TextStyle(fontSize: 13.5, height: 1.45);
  static const bodyStrong = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    height: 1.45,
  );
  static const sub = TextStyle(fontSize: 12.5, height: 1.5);
  static const subStrong = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );
  static const caption = TextStyle(fontSize: 12, height: 1.45);
  static const tiny = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  static const label = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    letterSpacing: .35,
    height: 1.3,
  );
  static const button = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );
  static const buttonSmall = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );
  static const metric = TextStyle(
    fontSize: 25,
    fontWeight: FontWeight.w700,
    height: 1.1,
  );
  static const metricM = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    height: 1.15,
  );
  static const metricS = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
}

/// 间距、圆角、高度、动效。
abstract final class QuartzSpace {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const s = 6.0;
  static const m = 8.0;
  static const l = 10.0;
  static const xl = 12.0;
  static const xxl = 14.0;
  static const page = 16.0;
  static const xxxl = 18.0;
}

abstract final class QuartzRadii {
  static const sm = 8.0;
  static const md = 12.0;
  static const field = 8.0;
  static const button = 8.0;
  static const sheet = 20.0;
  static const pill = 999.0;
}

abstract final class QuartzSizes {
  static const header = 48.0;
  static const tabBar = 62.0;
  static const row = 44.0;
  static const button = 40.0;
  static const iconTile = 34.0;
  static const iconTileCompact = 32.0;
  static const toggleW = 44.0;
  static const toggleH = 26.0;
  static const toggleKnob = 20.0;
  static const tap = 44.0;
}

abstract final class QuartzMotion {
  static const fast = Duration(milliseconds: 120);
  static const normal = Duration(milliseconds: 180);
  static const sheet = Duration(milliseconds: 240);
  static const page = Duration(milliseconds: 220);
  static const pulse = Duration(milliseconds: 1400);
}

/// 常用组合（不改语义，只减少重复）。
abstract final class QuartzEffects {
  static const tabShadow = BoxShadow(
    color: Color(0x6B000000),
    blurRadius: 30,
    offset: Offset(0, 10),
  );
  static const knobShadow = BoxShadow(
    color: Color(0x4D000000),
    blurRadius: 3,
    offset: Offset(0, 1),
  );
  static const segShadow = BoxShadow(
    color: Color(0x2E000000),
    blurRadius: 3,
    offset: Offset(0, 1),
  );
}
