#!/usr/bin/env python3
"""生成 Quartz App 的线稿图标资产。

设计稿 `design/ia-v2-preview.html` 里的内联 SVG 是唯一视觉来源；本脚本把
其中 24x24 的图标抽出来，去掉尺寸/class，统一成 vendor-neutral SVG，再补
少量同风格（24 viewBox / stroke 1.8 / round）的动作图标。

用法: python3 tool/gen_ui_icons.py
输出: assets/icons/*.svg
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
PREVIEW = ROOT / "design" / "ia-v2-preview.html"
OUT = ROOT / "assets" / "icons"

# name -> 唯一 path 片段（从 preview 里抽取）
EXTRACT = {
    "interfaces": "M9 3H5a2 2 0 0 0-2 2v14",
    "wifi": "M2 9a15 15 0 0 1 20 0",
    "dhcp": "M7 7.5h.01M7 16.5h.01",
    "route": "M15.5 5H9a3 3 0 0 0 0 6h6",
    "firewall": "M12 3l7 3v6c0 4.5",
    "system": "M12 7v5l3.5 2",
    "admin": "M14.5 13.5 20 19",
    "init": "M5 12h14",
    "clients": 'rect x="7" y="2" width="10" height="20"',
    "nav_overview": "M3 12h4l2.5-6 4 12L16 12h5",
    "nav_router": 'rect x="3" y="4" width="18" height="6.6"',
    "nav_apps": 'rect x="3.5" y="3.5" width="7" height="7"',
    "nav_cellular": "M4 20V9M9.3 20V5",
    "nav_settings": "M12 2v3M12 19v3M2 12h3M19 12h3M4.9 4.9",
    "warning": "M10.3 3.9 2.4 18",
    "lan": 'rect x="2" y="5" width="20" height="13"',
    "display": 'rect x="3" y="4" width="18" height="12"',
    "info": "M12 8h.01M12 11v5",
    "list": "M4 7h16M4 12h16M4 17h10",
    "check_up": "M3 17l5-5 3.5 3.5L21 6",
    "briefcase": 'rect x="3" y="8" width="18" height="12"',
    "plus_circle": "M12 3v18M3 12h18",
    "globe": "M3 12h18M12 3c2.8",
    "signal": "M12 20h.01",
    "sim": "M9 3v5h6V3",
    "sms": "M4 5h16v11H8l-4 4V5Z",
    "sms_forward": "M4 7h13M14 4l3 3-3 3",
    "at": "M8 6l-5 6 5 6",
    "advanced": "M12 2v3M12 19v3M2 12h3M19 12h3M5 5l2 2",
    "network_config": 'rect x="2" y="13.5" width="20" height="8"',
    "router_antenna": 'rect x="2" y="14" width="20" height="8"',
}

# name -> 内部 SVG（同风格手绘）
DRAW = {
    "chevron_right": '<path d="M9 5l7 7-7 7"/>',
    "chevron_left": '<path d="M15 5l-7 7 7 7"/>',
    "chevron_down": '<path d="M6 9l6 6 6-6"/>',
    "refresh": '<path d="M20 12a8 8 0 1 1-2.3-5.7"/><path d="M20 4v5h-5"/>',
    "sync": '<path d="M20 12a8 8 0 1 1-2.3-5.7"/><path d="M20 4v5h-5"/>',
    "edit": '<path d="M4 20h4L18 10a2.8 2.8 0 0 0-4-4L4 16v4Z"/><path d="M13.5 6.5l4 4"/>',
    "delete": '<path d="M4 7h16"/><path d="M9 7V5h6v2"/><path d="M6 7l1 13h10l1-13"/><path d="M10 11v6M14 11v6"/>',
    "search": '<circle cx="11" cy="11" r="6"/><path d="M20 20l-4-4"/>',
    "check": '<path d="M5 12l4.5 4.5L19 7"/>',
    "close": '<path d="M6 6l12 12M18 6L6 18"/>',
    "eye": '<path d="M2 12s3.5-6 10-6 10 6 10 6-3.5 6-10 6S2 12 2 12Z"/><circle cx="12" cy="12" r="2.5"/>',
    "eye_off": '<path d="M3 3l18 18"/><path d="M10.5 6.2A11 11 0 0 1 12 6c6.5 0 10 6 10 6a17 17 0 0 1-3.1 3.8M6.2 7.4A17 17 0 0 0 2 12s3.5 6 10 6a10 10 0 0 0 3.5-.6"/><path d="M9.9 9.9a3 3 0 0 0 4.2 4.2"/>',
    "play": '<path d="M8 5l11 7-11 7V5Z"/>',
    "pause": '<path d="M9 5v14M15 5v14"/>',
    "restart": '<path d="M20 12a8 8 0 1 1-2.3-5.7"/><path d="M20 4v5h-5"/>',
    "add": '<path d="M12 5v14M5 12h14"/>',
    "minus": '<path d="M5 12h14"/>',
    "cloud": '<path d="M7 18h10a4 4 0 0 0 .5-8A6 6 0 0 0 6 10.5 3.5 3.5 0 0 0 7 18Z"/>',
    "link": '<path d="M10 14a4 4 0 0 1 0-5.7l2.3-2.3a4 4 0 0 1 5.7 5.7L16 13.6"/><path d="M14 10a4 4 0 0 1 0 5.7l-2.3 2.3a4 4 0 0 1-5.7-5.7L8 10.4"/>',
    "copy": '<rect x="8" y="8" width="12" height="12" rx="2"/><path d="M16 8V6a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h2"/>',
    "external": '<path d="M14 4h6v6"/><path d="M20 4l-9 9"/><path d="M10 6H6a2 2 0 0 0-2 2v10a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-4"/>',
    "tune": '<path d="M4 6h16M4 12h16M4 18h16"/><circle cx="9" cy="6" r="2"/><circle cx="15" cy="12" r="2"/><circle cx="7" cy="18" r="2"/>',
    "terminal": '<rect x="3" y="4" width="18" height="16" rx="2"/><path d="M7 9l3 3-3 3M13 15h4"/>',
    "shield": '<path d="M12 3l7 3v6c0 4.5-3 7.5-7 9-4-1.5-7-4.5-7-9V6l7-3Z"/>',
    "clock": '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3.5 2"/>',
    "more": '<circle cx="5" cy="12" r="1" fill="currentColor" stroke="none"/><circle cx="12" cy="12" r="1" fill="currentColor" stroke="none"/><circle cx="19" cy="12" r="1" fill="currentColor" stroke="none"/>',
    "arrow_right": '<path d="M5 12h14"/><path d="M12 5l7 7-7 7"/>',
    "download": '<path d="M12 4v12M7 11l5 5 5-5"/><path d="M5 20h14"/>',
    "upload": '<path d="M12 20V8M7 13l5-5 5 5"/><path d="M5 4h14"/>',
    "power": '<path d="M12 3v9"/><path d="M7.5 6.5a7 7 0 1 0 9 0"/>',
    "package": '<path d="M12 3l8 4.5v9L12 21l-8-4.5v-9L12 3Z"/><path d="M4 7.5l8 4.5 8-4.5M12 12v9"/>',
    "lock": '<rect x="5" y="10" width="14" height="10" rx="2"/><path d="M8 10V8a4 4 0 0 1 8 0v2"/>',
    "memory": '<rect x="3" y="6" width="18" height="12" rx="2"/><path d="M7 10v4M11 10v4M15 10v4M19 10v4"/>',
    "thermometer": '<path d="M14 14.8V5a2 2 0 1 0-4 0v9.8a4 4 0 1 0 4 0Z"/>',
    "cpu": '<rect x="7" y="7" width="10" height="10" rx="2"/><path d="M9 3v4M15 3v4M9 17v4M15 17v4M3 9h4M3 15h4M17 9h4M17 15h4"/>',
    "traffic": '<path d="M4 18V9M9 18V5M14 18v-6M19 18V3"/>',
    "home": '<path d="M4 11l8-7 8 7"/><path d="M6 10v10h12V10"/>',
    "user": '<circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/>',
    "help": '<circle cx="12" cy="12" r="9"/><path d="M9.5 9a2.5 2.5 0 1 1 3.5 2.3c-.7.4-1 .9-1 1.7v.5"/><path d="M12 17h.01"/>',
    "filter": '<path d="M4 5h16l-6 7v6l-4 2v-8L4 5Z"/>',
    "sort": '<path d="M8 5v14M5 8l3-3 3 3M16 19V5M13 16l3 3 3-3"/>',
    "switch": '<path d="M4 8h11a4 4 0 0 1 0 8H9"/><path d="M7 5L4 8l3 3M17 13l3 3-3 3"/>',
    "dot": '<circle cx="12" cy="12" r="4" fill="currentColor" stroke="none"/>',
    "folder": '<path d="M3 6h7l2 2h9v12H3V6Z"/>',
    "file": '<path d="M6 3h8l4 4v14H6V3Z"/><path d="M14 3v4h4"/>',
    "wifi_off": '<path d="M3 3l18 18"/><path d="M2 9a15 15 0 0 1 5-3.2M12 9a15 15 0 0 1 10 0M5.5 12.5a10 10 0 0 1 4.2-2.3M15 16a5 5 0 0 0-6 0"/><circle cx="12" cy="19.5" r=".8" fill="currentColor" stroke="none"/>',
    "ethernet": '<rect x="3" y="5" width="18" height="14" rx="2"/><path d="M7 9h2v2H7zM11 9h2v2h-2zM15 9h2v2h-2zM9 13h6v3H9z"/>',
    "usb": '<path d="M12 21V5"/><path d="M12 5l-2-2M12 5l2-2"/><path d="M8 12h8"/><circle cx="8" cy="12" r="1.5"/><circle cx="16" cy="12" r="1.5"/>',
    "sd": '<path d="M6 3h9l3 3v15H6V3Z"/><path d="M9 7h2M13 7h1M9 10h2M13 10h1"/>',
    "bluetooth": '<path d="M8 7l8 10-4 3V4l4 3-8 10"/>',
    "gps": '<circle cx="12" cy="12" r="3"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3"/>',
    "bell": '<path d="M6 9a6 6 0 0 1 12 0c0 6 2 7 2 7H4s2-1 2-7Z"/><path d="M10 20a2 2 0 0 0 4 0"/>',
    "calendar": '<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 10h18M8 3v4M16 3v4"/>',
    "database": '<ellipse cx="12" cy="5" rx="8" ry="3"/><path d="M4 5v14c0 1.7 3.6 3 8 3s8-1.3 8-3V5"/><path d="M4 12c0 1.7 3.6 3 8 3s8-1.3 8-3"/>',
    "server": '<rect x="3" y="4" width="18" height="6" rx="2"/><rect x="3" y="14" width="18" height="6" rx="2"/><path d="M7 7h.01M7 17h.01"/>',
    "sliders": '<path d="M4 6h16M4 12h16M4 18h16"/><circle cx="9" cy="6" r="2"/><circle cx="15" cy="12" r="2"/><circle cx="7" cy="18" r="2"/>',
    "key": '<circle cx="8" cy="15" r="4"/><path d="M11 12l8-8M16 7l2 2M18 5l2 2"/>',
    "folder_open": '<path d="M3 7h7l2 2h9v10H3V7Z"/><path d="M3 11h18"/>',
    "upload_cloud": '<path d="M7 18h10a4 4 0 0 0 .5-8A6 6 0 0 0 6 10.5 3.5 3.5 0 0 0 7 18Z"/><path d="M12 16v-5M9.5 13.5 12 11l2.5 2.5"/>',
    "download_cloud": '<path d="M7 18h10a4 4 0 0 0 .5-8A6 6 0 0 0 6 10.5 3.5 3.5 0 0 0 7 18Z"/><path d="M12 11v5M9.5 13.5 12 16l2.5-2.5"/>',
    "route_alt": '<circle cx="6" cy="19" r="2.5"/><circle cx="18" cy="5" r="2.5"/><path d="M15.5 5H9a3 3 0 0 0 0 6h6a3 3 0 0 1 0 6H8.5"/>',
    "spark": '<path d="M3 12h3l2-5 3 10 2-5h8"/>',
    "gem": '<path d="M12 2 L20 6.6 V17.4 L12 22 L4 17.4 V6.6 Z"/><path d="M4 6.6 L12 11.6 L20 6.6"/><path d="M12 11.6 V22" opacity=".45"/>',
}

WRAP = ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
        'stroke="currentColor" stroke-width="1.8" stroke-linecap="round" '
        'stroke-linejoin="round">{}</svg>\n')


def normalize(body: str) -> str:
    body = re.sub(r'\s+', ' ', body)
    # 只清理 <svg> 开标签上的 width/height/class，不能动内部 <rect> 的尺寸。
    m = re.search(r'<svg\b[^>]*>', body)
    if not m:
        return body
    tag = m.group(0)
    tag = re.sub(r'\s(class|width|height)="[^"]*"', '', tag)
    if 'viewBox=' not in tag:
        tag = tag.replace('<svg', '<svg viewBox="0 0 24 24"', 1)
    if 'xmlns=' not in tag:
        tag = tag.replace('<svg', '<svg xmlns="http://www.w3.org/2000/svg"', 1)
    return body.replace(m.group(0), tag, 1)


def main() -> int:
    src = PREVIEW.read_text()
    raw = [m.group(0) for m in re.finditer(r'<svg.*?</svg>', src, re.S)]
    OUT.mkdir(parents=True, exist_ok=True)
    used = set()
    for name, sig in EXTRACT.items():
        hit = next((s for s in raw if 'viewBox="0 0 24 24"' in s and sig in s), None)
        if hit is None:
            print(f"WARN: preview icon not found: {name} ({sig})", file=sys.stderr)
            continue
        body = normalize(hit)
        (OUT / f"{name}.svg").write_text(body if body.endswith("\n") else body + "\n")
        used.add(name)
    for name, inner in DRAW.items():
        (OUT / f"{name}.svg").write_text(WRAP.format(inner))
        used.add(name)
    print(f"wrote {len(used)} icons to {OUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
