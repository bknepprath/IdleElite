#!/usr/bin/env python3
"""Lv1 fishing opener on Beach: novice dip, 1 fish = 1 currency."""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
JSON_PATH = ROOT / "docs" / "activity-database.json"

NOVICE_OPENER = {
    "id": "dip-a-tidepool-minnow",
    "tier": 1,
    "name": "Dip For A Shallow Minnow",
    "unlock": 1,
    "stamina": 1,
    "seconds": 3.2,
    "xp": 3,
    "success": 92,
    "rewards": {"xp": 3, "fish_min": 1, "fish_max": 1},
    "costs": {"stamina": 1},
    "art": "docs/assets/fishing/actions/01-scoop-pond-minnows.png",
    "background": "docs/assets/fishing/backgrounds/00-tide-pool-shallows.png",
    "area": "beach",
    "archetype": "novice",
}

data = json.loads(JSON_PATH.read_text(encoding="utf-8"))
fishing = next(s for s in data["skills"] if s["id"] == "fishing")

actions = [a for a in fishing["actions"] if a["id"] != "dip-a-tidepool-minnow"]
for action in actions:
    if action["id"] == "drag-net-through-creek":
        action["unlock"] = 4
        action["tier"] = 4
    if action["id"] == "skim-a-starlight-minnow":
        action["archetype"] = "steady"
        xp_val = int(action.get("rewards", {}).get("xp", action.get("xp", 48)))
        action["rewards"] = {"xp": xp_val}

actions.insert(0, NOVICE_OPENER.copy())
fishing["actions"] = actions

# Sort by unlock for clean audit
fishing["actions"].sort(key=lambda a: (int(a.get("unlock", 0)), int(a.get("tier", 0)), a.get("id", "")))

JSON_PATH.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print("Lv1 opener: dip-a-tidepool-minnow on beach; drag-net -> unlock 4")
