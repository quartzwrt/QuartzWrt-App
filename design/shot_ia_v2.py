#!/usr/bin/env python3
"""IA v2 讨论稿预览截图（评审用）。

用法: python3 design/shot_ia_v2.py        # 全页 + 各屏特写 → design/shots/ia-v2/
依赖: playwright（与 design/shot.py 同源工具链）
"""
import pathlib
import sys

from playwright.sync_api import sync_playwright

ROOT = pathlib.Path(__file__).resolve().parent.parent
PAGE = (ROOT / "design" / "ia-v2-preview.html").as_uri()
OUT = ROOT / "design" / "shots" / "ia-v2"
OUT.mkdir(parents=True, exist_ok=True)

# 逐图截屏：名字取 figure 的 data-shot 属性（HTML 侧维护，顺序无关）
FIGURES = True


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
        for i in range(cases.count()):
            case = cases.nth(i)
            name = case.get_attribute("data-shot") or f"fig-{i+1:02d}"
            # 宽图（dashboard 卡示意 / tab 对比）整块截，其余截手机框
            phone = case.locator(".phone")
            path = OUT / f"phone-{name}.png"
            if name in ("dashboard-cards", "tabs-compare") or phone.count() == 0:
                case.screenshot(path=str(path))
            else:
                phone.first.screenshot(path=str(path))
            print(f"{name} -> {path}")
        browser.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
