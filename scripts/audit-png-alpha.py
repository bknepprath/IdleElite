#!/usr/bin/env python3
"""Quick PNG alpha/fringe audit for chroma cleanup discussion."""
import struct
import sys
import zlib
from pathlib import Path


def read_png(path: Path) -> dict:
    if not path.exists():
        return {"error": "missing"}
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        return {"error": "not png"}
    pos = 8
    width = height = bit_depth = color_type = None
    idat = b""
    while pos < len(data):
        ln = struct.unpack(">I", data[pos : pos + 4])[0]
        typ = data[pos + 4 : pos + 8]
        chunk = data[pos + 8 : pos + 8 + ln]
        pos += 12 + ln
        if typ == b"IHDR":
            width, height, bit_depth, color_type, *_ = struct.unpack(">IIBBBBB", chunk[:13])
        elif typ == b"IDAT":
            idat += chunk
        elif typ == b"IEND":
            break
    has_alpha = color_type in (4, 6)
    if not has_alpha:
        return {"path": path.name, "size": (width, height), "has_alpha": False}
    raw = zlib.decompress(idat)
    bpp = 4 if color_type == 6 else 2
    stride = width * bpp + 1
    total = width * height
    a0 = a255 = semi = 0
    mag_opaque = green_opaque = black_opaque = 0
    mag_hidden = green_hidden = 0
    mag_semi = green_semi = 0
    for y in range(height):
        row_start = y * stride + 1
        for x in range(width):
            i = row_start + x * bpp
            if color_type == 6:
                r, g, b, a = raw[i], raw[i + 1], raw[i + 2], raw[i + 3]
            else:
                g, a = raw[i], raw[i + 1]
                r = b = g
            is_mag = r > 200 and b > 200 and g < 80
            is_green = g > 200 and r < 80 and b < 80
            if a < 16:
                a0 += 1
                if is_mag:
                    mag_hidden += 1
                if is_green:
                    green_hidden += 1
            elif a > 240:
                a255 += 1
                if r < 40 and g < 40 and b < 40:
                    black_opaque += 1
                if is_mag:
                    mag_opaque += 1
                if is_green:
                    green_opaque += 1
            else:
                semi += 1
                if is_mag:
                    mag_semi += 1
                if is_green:
                    green_semi += 1
    return {
        "path": path.name,
        "size": (width, height),
        "has_alpha": True,
        "alpha0_pct": round(100 * a0 / total, 1),
        "opaque_pct": round(100 * a255 / total, 1),
        "semi_pct": round(100 * semi / total, 1),
        "mag_opaque": mag_opaque,
        "green_opaque": green_opaque,
        "black_opaque": black_opaque,
        "mag_semi": mag_semi,
        "green_semi": green_semi,
        "mag_hidden": mag_hidden,
        "green_hidden": green_hidden,
        "total": total,
    }


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    files = [
        "assets/content/hub/hub-decor-sheet.png",
        "assets/content/hub/hub-tree-sheet.png",
        "assets/content/hub/hub-barn-tiers.png",
        "assets/content/hub/hub-garden-tiers.png",
        "assets/content/hub/hub-fish-pond-tiers.png",
        "assets/content/hub/hub-mission-sign-tiers.png",
        "assets/content/hub/hub-trophy-platform.png",
        "assets/content/hub/hub-build-cloud-solid-sheet.png",
        "assets/content/thieving/trophies/thieving-trophy-sheet.png",
        "assets/content/fishing/tools/fishing-tool-icons-sheet.png",
        "assets/content/ui/mastery-medals-20.png",
        "assets/content/characters/stick-hero.png",
        "assets/content/logo/idle-elite-logo-cutout.png",
        "assets/content/fishing/catch-icons/00-minnow-cutout.png",
        "assets/content/fishing/ui/fish-currency-cutout.png",
    ]
    for rel in files:
        r = read_png(root / rel)
        if r.get("error"):
            print(f"{rel}: {r['error']}")
            continue
        if not r.get("has_alpha"):
            print(f"{r['path']}: NO ALPHA channel {r['size']}")
            continue
        print(
            f"{r['path']}: {r['size'][0]}x{r['size'][1]} "
            f"alpha0={r['alpha0_pct']}% semi={r['semi_pct']}% "
            f"mag_op={r['mag_opaque']} mag_semi={r['mag_semi']} "
            f"green_op={r['green_opaque']} green_semi={r['green_semi']} "
            f"mag_hid={r['mag_hidden']} green_hid={r['green_hidden']}"
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
