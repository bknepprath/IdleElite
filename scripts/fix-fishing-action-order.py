#!/usr/bin/env python3
"""Sort fishing actions and normalize area backgrounds/reward ranges."""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
JSON_PATH = ROOT / "docs" / "activity-database.json"

data = json.loads(JSON_PATH.read_text(encoding="utf-8"))
fishing = next(s for s in data["skills"] if s["id"] == "fishing")
area_bg = {a["id"]: a["background"] for a in fishing.get("areas", [])}

FISH_RANGES = {
    "shallows": (1, 1),
    "rocks": (1, 2),
    "dock-edge": (1, 1),
    "piling-line": (1, 2),
    "river-bend": (1, 2),
    "rapids": (2, 4),
    "drain-gate": (1, 3),
    "tunnel-pool": (1, 3),
    "reef-pot": (2, 3),
    "ice-hole": (2, 4),
    "rowboat": (2, 4),
    "reef-cage": (3, 5),
    "open-water": (4, 7),
    "night-reef": (3, 5),
    "storm-ripple": (1, 2),
    "chum-line": (2, 6),
    "pearl-bed": (1, 3),
    "storm-line": (1, 3),
    "wreck-drop": (3, 6),
    "abyss": (1, 2),
    "deep-trench": (4, 8),
    "starlight": (2, 5),
    "reflection": (5, 10),
}

for action in fishing["actions"]:
    area_id = action.get("area")
    if area_id in area_bg:
        action["background"] = area_bg[area_id]
    action_id = action.get("id", "")
    if action_id in FISH_RANGES:
        fish_min, fish_max = FISH_RANGES[action_id]
        rewards = action.setdefault("rewards", {})
        rewards["xp"] = action.get("xp", rewards.get("xp", 1))
        rewards["fish_min"] = fish_min
        rewards["fish_max"] = fish_max

fishing["actions"].sort(key=lambda a: (int(a.get("unlock", 0)), int(a.get("tier", 0)), a.get("id", "")))

JSON_PATH.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print(f"Sorted {len(fishing['actions'])} fishing actions, synced backgrounds, and normalized fish rewards.")
