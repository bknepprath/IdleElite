import argparse
import json
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DATABASE_PATH = PROJECT_ROOT / "docs" / "activity-database.json"

TARGET_LADDERS = {
    "fight": [1, 2, 3, 4, 6, 8, 10, 13, 16, 19, 23, 27, 31, 36, 41, 46, 52, 58, 64, 69, 73, 76, 78, 79, 80],
    "thieving": [1, 2, 3, 5, 7, 9, 12, 15, 18, 22, 26, 30, 35, 40, 45, 51, 57, 62, 67, 71, 74, 76, 78, 79, 80],
    "build": [1, 2, 4, 6, 8, 11, 14, 17, 21, 25, 29, 34, 39, 44, 49, 55, 60, 65, 70, 73, 75, 77, 78, 79, 80],
    "woodcutting": [1, 3, 4, 6, 8, 10, 13, 16, 20, 24, 28, 33, 38, 43, 49, 54, 60, 66, 70, 73, 75, 77, 78, 79, 80],
}

def rounded(value):
    return int(round(value))


def success_for(skill_id, unlock, index):
    pressure = unlock * 0.38
    step_drop = (index // 6) * 1.6
    skill_offset = {"fight": -1.5, "thieving": -2.5, "build": 1.0, "woodcutting": 0.5}.get(skill_id, 0.0)
    wobble = 1.2 if index % 5 in (0, 1) else -0.8 if index % 5 == 3 else 0.0
    return round(max(54.0, min(98.0, 98.0 - pressure - step_drop + skill_offset + wobble)), 1)


def seconds_for(skill_id, unlock, index):
    base = {"fight": 1.0, "thieving": 0.9, "build": 1.35, "woodcutting": 1.15}.get(skill_id, 1.0)
    slope = {"fight": 0.092, "thieving": 0.084, "build": 0.138, "woodcutting": 0.112}.get(skill_id, 0.095)
    milestone = 0.26 * sum(1 for level in (20, 40, 60, 75) if unlock >= level)
    rhythm = [0.00, 0.08, -0.04, 0.12, 0.00, 0.16][index % 6]
    return round(max(0.85, base + unlock * slope + milestone + rhythm), 2)


def stamina_for(skill_id, unlock, index):
    skill_bonus = 1 if skill_id in ("fight", "build") and unlock >= 30 else 0
    rhythm = 1 if index % 7 == 5 else 0
    return max(1, min(12, 1 + unlock // 10 + unlock // 35 + skill_bonus + rhythm))


def retune_action(skill_id, action, index, count, unlock):
    action["unlock"] = unlock
    if "requirements" in action:
        action["requirements"] = [{"skill": skill_id, "level": unlock}]
    if "sort_unlock" in action:
        action["sort_unlock"] = unlock
    action["stamina"] = stamina_for(skill_id, unlock, index)
    action["seconds"] = seconds_for(skill_id, unlock, index)
    action["success"] = success_for(skill_id, unlock, index)


def retune_database(data):
    changed = []
    for skill in data.get("skills", []):
        skill_id = str(skill.get("id", ""))
        if skill_id not in TARGET_LADDERS:
            continue
        actions = [
            action for action in skill.get("actions", [])
            if str(action.get("kind", action.get("type", "activity"))) == "activity"
            and not action.get("combo_tags", [])
        ]
        ladder = TARGET_LADDERS[skill_id]
        if len(actions) != len(ladder):
            raise ValueError(f"{skill_id} has {len(actions)} activity actions, expected {len(ladder)}")
        last_stamina = 0
        last_seconds = 0.0
        last_success = 100.0
        for index, (action, unlock) in enumerate(zip(actions, ladder)):
            before = {key: action.get(key) for key in ("unlock", "xp", "stamina", "seconds", "success")}
            retune_action(skill_id, action, index, len(actions), unlock)
            action["stamina"] = max(int(action["stamina"]), last_stamina)
            action["seconds"] = round(max(float(action["seconds"]), last_seconds), 2)
            action["success"] = round(min(float(action["success"]), last_success), 1)
            last_stamina = int(action["stamina"])
            last_seconds = float(action["seconds"])
            last_success = float(action["success"])
            after = {key: action.get(key) for key in ("unlock", "xp", "stamina", "seconds", "success")}
            if before != after:
                changed.append((skill_id, str(action.get("id", "")), before, after))
    return changed


def main():
    parser = argparse.ArgumentParser(description="Spread mono skill activity modules to level 80.")
    parser.add_argument("--dry-run", action="store_true", help="Print the planned changes without writing the database.")
    args = parser.parse_args()

    data = json.loads(DATABASE_PATH.read_text(encoding="utf-8"))
    changed = retune_database(data)

    print(f"retuned-actions={len(changed)}")
    for skill_id, action_id, before, after in changed:
        print(f"{skill_id}:{action_id} {before} -> {after}")

    if not args.dry_run:
        DATABASE_PATH.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
