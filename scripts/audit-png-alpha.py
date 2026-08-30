#!/usr/bin/env python3
"""Quick PNG alpha/fringe audit for chroma cleanup discussion."""
import sys
from pathlib import Path

from PIL import Image


def read_png(path: Path) -> dict:
    if not path.exists():
        return {"error": "missing"}
    try:
        with Image.open(path) as image:
            if image.format != "PNG":
                return {"error": "not png"}
            size = image.size
            has_alpha = "A" in image.getbands() or "transparency" in image.info
            if not has_alpha:
                return {"path": path.name, "size": size, "has_alpha": False}
            pixels = image.convert("RGBA").get_flattened_data()
            counts = {
                "alpha0": 0,
                "alpha255": 0,
                "semi": 0,
                "mag_opaque": 0,
                "green_opaque": 0,
                "black_opaque": 0,
                "mag_hidden": 0,
                "green_hidden": 0,
                "mag_semi": 0,
                "green_semi": 0,
            }
            for red, green, blue, alpha in pixels:
                is_magenta = red > 200 and blue > 200 and green < 80
                is_green = green > 200 and red < 80 and blue < 80
                if alpha < 16:
                    counts["alpha0"] += 1
                    counts["mag_hidden"] += is_magenta
                    counts["green_hidden"] += is_green
                elif alpha > 240:
                    counts["alpha255"] += 1
                    counts["black_opaque"] += red < 40 and green < 40 and blue < 40
                    counts["mag_opaque"] += is_magenta
                    counts["green_opaque"] += is_green
                else:
                    counts["semi"] += 1
                    counts["mag_semi"] += is_magenta
                    counts["green_semi"] += is_green
    except OSError:
        return {"error": "not png"}

    total = size[0] * size[1]
    return {
        "path": path.name,
        "size": size,
        "has_alpha": True,
        "alpha0_pct": round(100 * counts["alpha0"] / total, 1),
        "opaque_pct": round(100 * counts["alpha255"] / total, 1),
        "semi_pct": round(100 * counts["semi"] / total, 1),
        **{key: value for key, value in counts.items() if key not in {"alpha0", "alpha255", "semi"}},
        "total": total,
    }

def main() -> int:
    root = Path(__file__).resolve().parents[1]
    files = sys.argv[1:]
    if not files:
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
            "assets/content/ui/mastery-medals/mastery-medal-01-bronze.png",
            "assets/content/characters/stick-hero.png",
            "assets/content/logo/idle-elite-logo-cutout.png",
            "assets/content/fishing/catch-icons/00-minnow-cutout.png",
            "assets/content/icons/resources/fish-currency-icon.png",
        ]
    failed = False
    for rel in files:
        r = read_png(root / rel)
        if r.get("error"):
            print(f"{rel}: {r['error']}")
            failed = True
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
    return int(failed)


if __name__ == "__main__":
    sys.exit(main())
