#!/usr/bin/env python3
"""Normalize fishing areas to the current player-facing location model."""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
JSON_PATH = ROOT / "docs" / "activity-database.json"

ACTION_AREA = {
    "beach-shallows": "beach",
    "beach-rocks": "beach",
    "pier-dock-edge": "pier",
    "pier-piling-line": "pier",
    "river-bend": "river",
    "river-rapids": "river",
    "sewers-drain-gate": "sewers",
    "sewers-tunnel-pool": "sewers",
    "reef-pot": "reef",
    "winter-lake-ice-hole": "winter_lake",
    "sea-rowboat": "sea",
    "reef-cage": "reef",
    "sea-open-water": "sea",
    "reef-night-reef": "reef",
    "stormy-sea-ripple": "stormy_sea",
    "sea-chum-line": "sea",
    "reef-pearl-bed": "reef",
    "stormy-sea-storm-line": "stormy_sea",
    "deep-sea-wreck-drop": "deep_sea",
    "deep-sea-abyss": "deep_sea",
    "deep-sea-trench": "deep_sea",
    "space-starlight": "space",
    "space-reflection": "space",
}

AREAS = [
    {
        "id": "beach",
        "name": "Beach",
        "fluid": "water",
        "background": "docs/assets/fishing/backgrounds/00-tide-pool-shallows.png",
    },
    {
        "id": "pier",
        "name": "Pier",
        "fluid": "water",
        "background": "docs/assets/fishing/backgrounds/01-pond-dock.png",
    },
    {
        "id": "river",
        "name": "River",
        "fluid": "water",
        "background": "docs/assets/fishing/backgrounds/02-river-bend.png",
    },
    {
        "id": "sewers",
        "name": "Sewers",
        "fluid": "sewer",
        "background": "docs/assets/fishing/backgrounds/sewer-pipe-outlet.png",
    },
    {
        "id": "winter_lake",
        "name": "Winter Lake",
        "fluid": "water",
        "background": "docs/assets/fishing/backgrounds/04-frozen-lake.png",
    },
    {
        "id": "reef",
        "name": "Reef",
        "fluid": "water",
        "background": "docs/assets/fishing/backgrounds/05-coral-reef-shallows.png",
    },
    {
        "id": "sea",
        "name": "Sea",
        "fluid": "water",
        "background": "docs/assets/fishing/backgrounds/07-rowboat-offshore.png",
    },
    {
        "id": "deep_sea",
        "name": "Deep Sea",
        "fluid": "water",
        "background": "docs/assets/fishing/backgrounds/09-deep-sea-abyss.png",
    },
    {
        "id": "stormy_sea",
        "name": "Stormy Sea",
        "fluid": "water",
        "background": "docs/assets/fishing/backgrounds/10-storm-ocean.png",
    },
    {
        "id": "space",
        "name": "Space Fishing",
        "fluid": "water",
        "background": "docs/assets/fishing/backgrounds/11-cosmic-dream-sea.png",
    },
]

data = json.loads(JSON_PATH.read_text(encoding="utf-8"))
fishing = next(s for s in data["skills"] if s["id"] == "fishing")

for action in fishing["actions"]:
    aid = action["id"]
    if aid not in ACTION_AREA:
        raise SystemExit(f"Missing area mapping for {aid}")
    action["area"] = ACTION_AREA[aid]
    action["background"] = next(a["background"] for a in AREAS if a["id"] == action["area"])

fishing["areas"] = AREAS
JSON_PATH.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print(f"Updated {JSON_PATH} — {len(AREAS)} fishing areas, {len(ACTION_AREA)} actions tagged")
print("Run: python scripts/fix-fishing-action-order.py && python scripts/sync-activity-database-js.py")
