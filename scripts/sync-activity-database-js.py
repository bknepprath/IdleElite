#!/usr/bin/env python3
"""Sync activity-database-data.js from activity-database.json."""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
JSON_PATH = ROOT / "docs" / "activity-database.json"
JS_PATH = ROOT / "docs" / "activity-database-data.js"

data = json.loads(JSON_PATH.read_text(encoding="utf-8"))
dumped = json.dumps(data, indent=2, ensure_ascii=False)
JS_PATH.write_text(
    "// Generated from activity-database.json for file:// HTML previews.\n"
    "// Edit activity-database.json first, then run: python scripts/sync-activity-database-js.py\n"
    f"globalThis.IDLE_ELITE_ACTIVITY_DATABASE = {dumped};\n",
    encoding="utf-8",
)
print(f"Synced {JS_PATH.relative_to(ROOT)}")
