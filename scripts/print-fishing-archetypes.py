import json
from pathlib import Path

data = json.loads(Path("docs/activity-database.json").read_text(encoding="utf-8"))
f = next(s for s in data["skills"] if s["id"] == "fishing")
by_arch = {}
for a in f["actions"]:
    arch = a.get("archetype") or "steady"
    by_arch.setdefault(arch, []).append(a)
for arch in ["novice", "steady", "volume", "commit", "chaos", "risk"]:
    print("===", arch, len(by_arch.get(arch, [])))
    for a in sorted(by_arch.get(arch, []), key=lambda x: (x["unlock"], x["id"])):
        y = a.get("rewards", {})
        fish = ""
        if "fish_min" in y:
            fish = " fish %s-%s" % (y["fish_min"], y["fish_max"])
        print("  Lv%2d %s | %s%s" % (a["unlock"], a["id"], a["name"][:42], fish))
