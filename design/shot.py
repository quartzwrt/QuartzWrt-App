#!/usr/bin/env python3
"""QuartzWrt-App 设计预览截图（评审用）。

用法: python3 design/shot.py            # 全页 + 关键屏特写 → design/shots/
依赖: playwright（chromium 已装，WP-2 工具链同源）
"""
import pathlib
import sys

from playwright.sync_api import sync_playwright

ROOT = pathlib.Path(__file__).resolve().parent.parent
PAGE = (ROOT / "design" / "preview.html").as_uri()
OUT = ROOT / "design" / "shots"
OUT.mkdir(parents=True, exist_ok=True)

CASES = {
    "overview-dark": 2,     # 序号（从 0 起）：③ 概览
    "pairing-dark": 1,      # ② 配对
    "network-dark": 3,      # ④ 网络
    "apps-dark": 4,         # ⑤ 应用
    "settings-dark": 5,     # ⑥ 设置（系统设置+应用设置）
    "light-overview": 7,    # ⑧ 浅色概览
    "degraded-dark": 8,     # ⑨ 降级态
    "extended-overview": 9, # ⑩ 扩展示例（通用卡+Docker 条件卡+泛化行）
    "service-detail": 10,   # ⑪ 应用详情
}


def main() -> int:
    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page(
            viewport={"width": 1440, "height": 1200}, device_scale_factor=2
        )
        page.goto(PAGE)
        page.wait_for_timeout(400)
        full = OUT / "preview-full.png"
        page.screenshot(path=str(full), full_page=True)
        print(f"full page -> {full}")

        cases = page.locator("figure.case")
        n = cases.count()
        for name, idx in CASES.items():
            if idx >= n:
                continue
            path = OUT / f"phone-{name}.png"
            cases.nth(idx).locator(".phone").screenshot(path=str(path))
            print(f"phone {idx} -> {path}")
        browser.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
