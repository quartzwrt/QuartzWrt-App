// 背景层：本机壁纸（可选）+ scrim；无壁纸时使用 96×96 石英噪点。
import 'dart:io';

import 'package:flutter/material.dart';

import 'quartz_tokens.dart';

class QuartzSurface extends StatelessWidget {
  const QuartzSurface({super.key, required this.child, this.wallpaperPath});

  final Widget child;
  final String? wallpaperPath;

  @override
  Widget build(BuildContext context) {
    final t = QuartzTokens.of(context);
    final noise = t.isDark
        ? 'assets/background/noise-dark.png'
        : 'assets/background/noise-light.png';
    final path = wallpaperPath;
    final hasWallpaper =
        path != null && path.isNotEmpty && File(path).existsSync();
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: t.bg),
        if (hasWallpaper)
          Image.file(
            File(path),
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => _noise(noise),
          )
        else
          _noise(noise),
        if (hasWallpaper)
          ColoredBox(
            color: t.isDark ? const Color(0x73000000) : const Color(0x8CF2F2F7),
          ),
        child,
      ],
    );
  }

  Widget _noise(String asset) => IgnorePointer(
    child: Image.asset(
      asset,
      repeat: ImageRepeat.repeat,
      fit: BoxFit.none,
      alignment: Alignment.topLeft,
      filterQuality: FilterQuality.low,
    ),
  );
}
