#!/usr/bin/env python3
"""生成 Android 启动图标位图（W6.6 打磨）。

设计稿：QuartzWrt 品牌切面宝石（WP-2 logo `logo.svg`，方案 B）+ 品牌蓝底
（#007AFF，theme.dart accent）；自适应图标走 vector（mipmap-anydpi-v26 +
drawable/ic_launcher_foreground.xml），本脚本只出 API<26 的遗留位图与启动屏宝石。

用法: python3 design/gen_icons.py
输出: android/app/src/main/res/mipmap-*/ic_launcher{,_round}.png
      android/app/src/main/res/mipmap-*/launch_gem.png
依赖: playwright（chromium 已装；与 design/shot.py 同源工具链）
"""
import pathlib

from playwright.sync_api import sync_playwright

ROOT = pathlib.Path(__file__).resolve().parent.parent
RES = ROOT / "android" / "app" / "src" / "main" / "res"
DENS = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}

ACCENT = "#007AFF"
GEM = """
<svg viewBox="0 0 24 24" fill="none" stroke="{color}" stroke-width="1.6"
     stroke-linejoin="round" width="{size}" height="{size}" aria-hidden="true">
  <path d="M12 2 L20 6.6 V17.4 L12 22 L4 17.4 V6.6 Z"/>
  <path d="M4 6.6 L12 11.6 L20 6.6"/>
  <path d="M12 11.6 V22" opacity=".45"/>
</svg>
"""


def page_html(kind: str, size: int) -> str:
    """kind: square（遗留方图标，圆角蓝底）/ round（圆形）/ gem（透明底蓝宝石）。"""
    inner = size * 0.62  # 宝石占比（对齐自适应图标前景比例）
    gem = GEM.format(color="#FFFFFF" if kind != "gem" else ACCENT, size=inner)
    if kind == "square":
        bg = f'<div class="plate" style="border-radius:{size * 0.22:.0f}px"></div>'
    elif kind == "round":
        bg = '<div class="plate" style="border-radius:50%"></div>'
    else:
        bg = ""
    return f"""<!doctype html><meta charset="utf-8"><style>
  html,body{{margin:0;padding:0;background:transparent}}
  #c{{position:relative;width:{size}px;height:{size}px;display:flex;
      align-items:center;justify-content:center}}
  .plate{{position:absolute;inset:0;background:{ACCENT}}}
  svg{{position:relative}}
</style><div id="c">{bg}{gem}</div>"""


def main() -> int:
    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page(device_scale_factor=1)
        for dens, size in DENS.items():
            out = RES / f"mipmap-{dens}"
            out.mkdir(parents=True, exist_ok=True)
            for kind, name in (("square", "ic_launcher.png"), ("round", "ic_launcher_round.png"), ("gem", "launch_gem.png")):
                page.set_viewport_size({"width": size, "height": size})
                page.set_content(page_html(kind, size))
                page.locator("#c").screenshot(path=str(out / name), omit_background=(kind == "gem"))
            print(f"  {dens}: {size}px ×3")
        browser.close()
    print(f"icons → {RES}/mipmap-*/")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
