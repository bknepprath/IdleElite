#!/usr/bin/env python3
"""Remove sonar/negotiate/finale; novice space opener with 1:1 fish yield."""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
JSON_PATH = ROOT / "docs" / "activity-database.json"

REMOVE_IDS = {
    "use-sonar-in-the-farm-pond",
    "negotiate-with-the-oceans-manager",
    "catch-the-fishing-mechanic-itself",
}

data = json.loads(JSON_PATH.read_text(encoding="utf-8"))
fishing = next(s for s in data["skills"] if s["id"] == "fishing")

new_actions = []
for action in fishing["actions"]:
    aid = action["id"]
    if aid in REMOVE_IDS:
        continue
    if aid == "angle-in-cosmic-dream-sea":
        action = {
            **action,
            "id": "skim-a-starlight-minnow",
            "tier": 22,
            "name": "Skim A Starlight Minnow",
            "unlock": 36,
            "stamina": 6,
            "seconds": 8.2,
            "xp": 48,
            "success": 84,
            "rewards": {"xp": 48, "fish_min": 1, "fish_max": 1},
            "costs": {"stamina": 6},
            "art": "assets/content/fishing/actions/22-angle-in-cosmic-dream-sea.png",
            "background": "assets/content/fishing/backgrounds/11-cosmic-dream-sea.png",
            "area": "space",
            "archetype": "steady",
        }
    new_actions.append(action)

fishing["actions"] = new_actions
JSON_PATH.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print(f"Fishing actions: {len(new_actions)} (removed {len(REMOVE_IDS)}, skim-a-starlight-minnow ready)")
