#!/usr/bin/env python3
"""Seeded first-hour model for Idle Elite's early relationship plan."""

from __future__ import annotations

import argparse
import json
import math
import random
import statistics
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Iterable


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DATABASE_PATH = PROJECT_ROOT / "docs" / "activity-database.json"
SKILL_ORDER = ("fight", "build", "woodcutting", "fishing", "thieving")
ALL_SKILLS = ("fight", "thieving", "build", "woodcutting", "fishing")
COMBO_ORDER = (
    "fight:wrestle-stuck-gate-latch",
    "build:saw-planks",
    "woodcutting:split-firewood",
    "build:study-blueprint",
)
HANDS_SUCCESS = {
    "shallows": 0.82,
    "rocks": 0.74,
    "dock-edge": 0.60,
    "piling-line": 0.42,
    "river-bend": 0.15,
    "rapids": 0.08,
}
COMBO_CANDIDATES = {
    "fight:wrestle-stuck-gate-latch": {
        "seconds": 2.4,
        "stamina": 2.0,
        "xp_rewards": {"fight": 4, "build": 3},
    },
    "build:saw-planks": {
        "seconds": 2.2,
        "stamina": 2.0,
        "xp_rewards": {"build": 4, "woodcutting": 3},
    },
    "woodcutting:split-firewood": {
        "seconds": 2.8,
        "stamina": 2.0,
        "xp_rewards": {"woodcutting": 4, "fishing": 4},
    },
    "build:study-blueprint": {
        "seconds": 3.3,
        "stamina": 2.0,
        "xp_rewards": {"build": 5, "thieving": 6},
    },
}


@dataclass(frozen=True)
class Scenario:
    name: str
    candidate_relationships: bool
    firepit_target: str
    firepit_rate_per_minute: float
    pond_bonus: float
    pond_refill: float
    milestone_berries: bool
    fish_bridge: bool
    berry_policy: str = "use"
    protect_pond_fish: bool = True
    early_recovery_target: str = "authored"
    first_berry_target: str = "latch"
    fish_stamina: float = 1.0
    milestone_berry_limit: int = 3
    route_policy: str = "guided"
    pond_bonus_mode: str = "fixed"
    pond_berry_use_requirement: int = 0
    use_candidate_combos: bool | None = None


SCENARIOS = {
    "guided-current": Scenario(
        "guided-current", False, "woodcutting", 2.0, 0.01, 0.0, False, False
    ),
    "candidate-pond-1": Scenario(
        "candidate-pond-1", True, "non_woodcutting", 1.0, 0.01, 0.0, True, True
    ),
    "candidate-pond-5": Scenario(
        "candidate-pond-5", True, "non_woodcutting", 1.0, 0.05, 0.0, True, True
    ),
    "candidate-pond-5-refill": Scenario(
        "candidate-pond-5-refill", True, "non_woodcutting", 1.0, 0.05, 5.0, True, True
    ),
    "candidate-hoard": Scenario(
        "candidate-hoard", True, "non_woodcutting", 1.0, 0.05, 5.0, True, True, "hoard"
    ),
    "candidate-no-fish-bridge": Scenario(
        "candidate-no-fish-bridge", True, "non_woodcutting", 1.0, 0.05, 5.0, True, False
    ),
    "candidate-unprotected-fish": Scenario(
        "candidate-unprotected-fish", True, "non_woodcutting", 1.0, 0.05, 5.0, True, True, "use", False
    ),
    "candidate-lowest-recovery": Scenario(
        "candidate-lowest-recovery",
        True,
        "non_woodcutting",
        1.0,
        0.05,
        5.0,
        True,
        False,
        early_recovery_target="lowest",
    ),
    "candidate-berry-hammer": Scenario(
        "candidate-berry-hammer",
        True,
        "non_woodcutting",
        1.0,
        0.05,
        5.0,
        True,
        True,
        first_berry_target="hammer",
        pond_bonus_mode="relationship_floor",
        pond_berry_use_requirement=2,
        use_candidate_combos=False,
    ),
    "candidate-berry-shallows": Scenario(
        "candidate-berry-shallows",
        True,
        "non_woodcutting",
        1.0,
        0.05,
        5.0,
        True,
        True,
        first_berry_target="shallows",
        pond_bonus_mode="relationship_floor",
        pond_berry_use_requirement=2,
        use_candidate_combos=False,
    ),
    "candidate-fish-2-stamina": Scenario(
        "candidate-fish-2-stamina",
        True,
        "non_woodcutting",
        1.0,
        0.05,
        5.0,
        True,
        True,
        fish_stamina=2.0,
        pond_bonus_mode="relationship_floor",
        pond_berry_use_requirement=2,
        use_candidate_combos=False,
    ),
    "candidate-firepit-current": Scenario(
        "candidate-firepit-current",
        True,
        "woodcutting",
        2.0,
        0.01,
        5.0,
        True,
        True,
        pond_bonus_mode="relationship_floor",
        pond_berry_use_requirement=2,
        use_candidate_combos=False,
    ),
    "candidate-firepit-all": Scenario(
        "candidate-firepit-all",
        True,
        "all",
        1.0,
        0.01,
        5.0,
        True,
        True,
        pond_bonus_mode="relationship_floor",
        pond_berry_use_requirement=2,
        use_candidate_combos=False,
    ),
    "candidate-pond-3-refill": Scenario(
        "candidate-pond-3-refill", True, "non_woodcutting", 1.0, 0.05, 3.0, True, True
    ),
    "candidate-pond-10-refill": Scenario(
        "candidate-pond-10-refill", True, "non_woodcutting", 1.0, 0.05, 10.0, True, True
    ),
    "candidate-current-combos": Scenario(
        "candidate-current-combos", False, "non_woodcutting", 1.0, 0.05, 5.0, True, True
    ),
    "candidate-one-berry": Scenario(
        "candidate-one-berry",
        True,
        "non_woodcutting",
        1.0,
        0.05,
        5.0,
        True,
        True,
        milestone_berry_limit=1,
        pond_bonus_mode="relationship_floor",
        use_candidate_combos=False,
    ),
    "candidate-two-berries": Scenario(
        "candidate-two-berries",
        True,
        "non_woodcutting",
        1.0,
        0.05,
        5.0,
        True,
        True,
        milestone_berry_limit=2,
        pond_bonus_mode="relationship_floor",
        use_candidate_combos=False,
    ),
    "candidate-pond-rush": Scenario(
        "candidate-pond-rush",
        True,
        "non_woodcutting",
        1.0,
        0.05,
        5.0,
        True,
        True,
        route_policy="pond_rush",
    ),
    "candidate-linked-pond": Scenario(
        "candidate-linked-pond",
        True,
        "non_woodcutting",
        1.0,
        0.01,
        5.0,
        True,
        True,
        pond_bonus_mode="relationship_floor",
    ),
    "candidate-linked-pond-rush": Scenario(
        "candidate-linked-pond-rush",
        True,
        "non_woodcutting",
        1.0,
        0.01,
        5.0,
        True,
        True,
        route_policy="pond_rush",
        pond_bonus_mode="relationship_floor",
    ),
    "candidate-use-gated-third": Scenario(
        "candidate-use-gated-third",
        True,
        "non_woodcutting",
        1.0,
        0.01,
        5.0,
        True,
        True,
        pond_bonus_mode="relationship_floor",
        pond_berry_use_requirement=2,
        use_candidate_combos=False,
    ),
    "candidate-use-gated-third-hoard": Scenario(
        "candidate-use-gated-third-hoard",
        True,
        "non_woodcutting",
        1.0,
        0.01,
        5.0,
        True,
        True,
        berry_policy="hoard",
        pond_bonus_mode="relationship_floor",
        pond_berry_use_requirement=2,
        use_candidate_combos=False,
    ),
    "candidate-use-gated-third-rush": Scenario(
        "candidate-use-gated-third-rush",
        True,
        "non_woodcutting",
        1.0,
        0.01,
        5.0,
        True,
        True,
        route_policy="pond_rush",
        pond_bonus_mode="relationship_floor",
        pond_berry_use_requirement=2,
        use_candidate_combos=False,
    ),
    "candidate-use-gated-third-no-fish": Scenario(
        "candidate-use-gated-third-no-fish",
        True,
        "non_woodcutting",
        1.0,
        0.01,
        5.0,
        True,
        False,
        pond_bonus_mode="relationship_floor",
        pond_berry_use_requirement=2,
        use_candidate_combos=False,
    ),
}


@dataclass
class SkillState:
    xp: float = 0.0
    level: int = 1
    stamina: float = 30.0
    completions: int = 0


@dataclass(frozen=True)
class Choice:
    task: str
    key: str


@dataclass
class RunResult:
    scenario: str
    seed: int
    times: dict[str, float | None]
    total_dead_seconds: float
    longest_dead_seconds: float
    switches: int
    switches_first_15: int
    switches_before_pond: int
    max_switches_30: int
    levels: dict[str, int]
    stamina: dict[str, float]
    berries: int
    pending_berries: int
    deferred_berry_milestones: int
    prepared_target: str
    prepared_funding: str
    berry_uses: int
    fish: float
    scrapwood: float
    firepit_starts: int
    fence_built: bool
    pond_refill_total: float
    pond_refill_skill_count: int
    fish_eaten: int
    fish_eaten_at_pond: int | None
    recovery_uses: int
    recovery_stamina: float
    levels_at_pond: dict[str, int]
    relationships_at_pond: int
    pond_bonus_at_completion: float
    pond_bonus_at_end: float
    events: list[tuple[float, str, str]] = field(default_factory=list)


def load_database() -> tuple[dict[str, Any], dict[str, dict[str, Any]]]:
    if not DATABASE_PATH.exists():
        raise FileNotFoundError(f"Activity database was not found at {DATABASE_PATH}")
    database = json.loads(DATABASE_PATH.read_text(encoding="utf-8"))
    actions: dict[str, dict[str, Any]] = {}
    for skill in database["skills"]:
        owner = str(skill["id"])
        for raw in skill["actions"]:
            action = dict(raw)
            action["owner"] = owner
            actions[f"{owner}:{action['id']}"] = action
    return database, actions


DATABASE, ACTIONS = load_database()
BASE_MAX_STAMINA = float(DATABASE["global_rules"]["base_max_stamina"])
REGEN_SECONDS = float(DATABASE["global_rules"]["stamina_regen_seconds"])
ACTIONS_BY_SKILL = {
    skill_id: tuple(key for key, action in ACTIONS.items() if action["owner"] == skill_id)
    for skill_id in ALL_SKILLS
}


def skill_xp_for_level(level: int) -> int:
    if level <= 1:
        return 0
    stretch = 1.0
    if level > 10:
        progress = min(1.0, max(0.0, (level - 10) / 89.0))
        stretch += 3.0 * progress**2
    return round(22.0 * (level - 1) ** 2.08 * stretch)


def skill_level_for_xp(xp: float) -> int:
    level = 1
    while level < 99 and xp >= skill_xp_for_level(level + 1):
        level += 1
    return level


def percentile(values: list[float], probability: float) -> float:
    if not values:
        return math.nan
    ordered = sorted(values)
    index = (len(ordered) - 1) * probability
    lower = math.floor(index)
    upper = math.ceil(index)
    if lower == upper:
        return ordered[lower]
    return ordered[lower] + (ordered[upper] - ordered[lower]) * (index - lower)


def clock(seconds: float | None) -> str:
    if seconds is None or not math.isfinite(seconds):
        return "-"
    whole = int(round(seconds))
    return f"{whole // 60:02d}:{whole % 60:02d}"


class FirstHourSimulation:
    def __init__(
        self,
        scenario: Scenario,
        seed: int,
        duration: float,
        step: float = 0.5,
        fish_spend_cap: int | None = None,
        mastery_contract: str = "runtime",
    ):
        self.scenario = scenario
        self.seed = seed
        self.duration = duration
        self.step = step
        self.rng = random.Random(seed)
        self.time = 0.0
        self.skills = {skill_id: SkillState(stamina=BASE_MAX_STAMINA) for skill_id in ALL_SKILLS}
        self.materials = {"scrapwood": 0.0, "honey": 0.0, "berries": 0.0}
        self.fish = 0.0
        self.fish_eaten = 0
        self.fish_eaten_at_pond: int | None = None
        self.recovery_uses = 0
        self.recovery_stamina = 0.0
        self.levels_at_pond: dict[str, int] = {}
        self.relationships_at_pond = 0
        self.pond_bonus_at_completion = 0.0
        self.fish_spend_cap = fish_spend_cap
        self.mastery_contract = mastery_contract
        self.unlocked: set[str] = set()
        self.completed_relationship_actions: set[str] = set()
        self.built_modules: set[str] = set()
        self.claimed_berry_milestones: set[str] = set()
        self.deferred_berry_milestones: set[str] = set()
        self.berry_inventory = 0
        self.pending_berries = 0
        self.prepared_target = ""
        self.prepared_funding = ""
        self.berry_uses = 0
        self.progress: dict[str, float] = {}
        self.active: Choice | None = None
        self.last_task = ""
        self.last_action_key = ""
        self.last_skill = ""
        self.events: list[tuple[float, str, str]] = []
        self.switch_times: list[float] = []
        self.attempts = 0
        self.streak_key = ""
        self.streak_count = 0
        self.mastery_xp: dict[str, int] = {}
        self.bronze_actions: set[str] = set()
        self.global_bronze = False
        self.firepit_active = False
        self.firepit_started_at = 0.0
        self.firepit_burn_progress = 0.0
        self.firepit_cooling_bonus = 0.0
        self.firepit_starts = 0
        self.firepit_ever_started = False
        self.pond_build_started: float | None = None
        self.pond_complete = False
        self.pond_refill_total = 0.0
        self.pond_refill_skill_count = 0
        self.honey_seconds = 0.0
        self.dead_total = 0.0
        self.dead_current = 0.0
        self.dead_longest = 0.0
        self.tired_training_total = 0.0
        self.times: dict[str, float | None] = {
            "promise": None,
            "all_skills_2": None,
            "first_berry": None,
            "first_berry_use": None,
            "firepit": None,
            "first_combo": None,
            "pond_started": None,
            "pond": None,
            "fence": None,
            "honey": None,
            "first_recovery_unlock": None,
            "first_recovery_use": None,
        }
        self.refresh_unlocks(initial=True)
        if scenario.candidate_relationships:
            self.times["promise"] = 0.0
            self.event("relationship", "Pond promise visible: Building 5 + 8 Fish; all-skill stamina payoff")

    def event(self, category: str, message: str) -> None:
        self.events.append((self.time, category, message))

    def action(self, key: str) -> dict[str, Any]:
        return ACTIONS[key]

    def requirements(self, action: dict[str, Any]) -> list[tuple[str, int]]:
        raw_requirements = action.get("requirements") or []
        if raw_requirements:
            return [(str(item["skill"]), int(item["level"])) for item in raw_requirements]
        return [(str(action["owner"]), int(action.get("unlock", 1)))]

    def requirements_met(self, action: dict[str, Any]) -> bool:
        return all(self.skills[skill].level >= level for skill, level in self.requirements(action))

    def is_relationship_action(self, action: dict[str, Any]) -> bool:
        return len(self.requirements(action)) >= 2 or bool(action.get("build")) or str(action.get("kind", "")) == "passive_item_collect"

    def refresh_unlocks(self, initial: bool = False) -> None:
        for key, action in ACTIONS.items():
            if key in self.unlocked or not self.requirements_met(action):
                continue
            self.unlocked.add(key)
            if not initial and action.get("recovery") and self.times["first_recovery_unlock"] is None:
                self.times["first_recovery_unlock"] = self.time
                self.event("unlock", f"first recovery action unlocked: {action['name']}")
            if not initial and self.is_relationship_action(action):
                requirements = ", ".join(f"{skill} {level}" for skill, level in self.requirements(action))
                self.event("unlock", f"{action['name']} manually unlocked ({requirements})")

    def effective_seconds(self, key: str) -> float:
        if self.uses_candidate_combo_values() and key in COMBO_CANDIDATES:
            return float(COMBO_CANDIDATES[key]["seconds"])
        return float(self.action(key).get("seconds", 1.0))

    def uses_candidate_combo_values(self) -> bool:
        if self.scenario.use_candidate_combos is not None:
            return self.scenario.use_candidate_combos
        return self.scenario.candidate_relationships

    def action_cost(self, key: str) -> float:
        action = self.action(key)
        if action["owner"] == "fishing":
            return 0.0
        if self.uses_candidate_combo_values() and key in COMBO_CANDIDATES:
            return float(COMBO_CANDIDATES[key]["stamina"])
        return max(0.0, float(action.get("stamina", 1.0)))

    def authored_xp_map(self, key: str) -> dict[str, int]:
        action = self.action(key)
        if self.uses_candidate_combo_values() and key in COMBO_CANDIDATES:
            return dict(COMBO_CANDIDATES[key]["xp_rewards"])
        raw = action.get("xp_rewards") or {}
        if raw:
            return {str(skill): int(amount) for skill, amount in raw.items() if int(amount) > 0}
        return {str(action["owner"]): max(1, int(action.get("xp", 1)))}

    def success_chance(self, key: str) -> float:
        action = self.action(key)
        if action["owner"] == "fishing":
            return HANDS_SUCCESS.get(str(action["id"]), float(action.get("success", 90.0)) / 100.0)
        return min(1.0, max(0.05, float(action.get("success", 90.0)) / 100.0))

    def max_stamina(self, skill_id: str) -> float:
        global_levels = sum(state.level for state in self.skills.values())
        global_level_bonus = math.floor(global_levels / 10)
        global_medal_bonus = 1 if self.global_bronze else 0
        skill_bronzes = sum(1 for key in self.bronze_actions if key.startswith(f"{skill_id}:"))
        skill_medal_bonus = math.floor(skill_bronzes / 3)
        return BASE_MAX_STAMINA + global_level_bonus + global_medal_bonus + skill_medal_bonus

    def firepit_bonus(self, skill_id: str) -> float:
        if self.scenario.firepit_target == "woodcutting" and skill_id != "woodcutting":
            return 0.0
        if self.scenario.firepit_target == "non_woodcutting" and skill_id == "woodcutting":
            return 0.0
        if self.firepit_active:
            tier = min(15, int((self.time - self.firepit_started_at) // 60.0) + 1)
            return tier * 0.04
        return max(0.0, self.firepit_cooling_bonus)

    def pond_regen_bonus(self) -> float:
        if not self.pond_complete:
            return 0.0
        if self.scenario.pond_bonus_mode == "relationship_floor":
            relationship_floor = 0.01 * (1 + min(4, len(self.completed_relationship_actions)))
            return max(self.scenario.pond_bonus, relationship_floor)
        return self.scenario.pond_bonus

    def update_passive_systems(self, delta: float) -> None:
        if self.firepit_active:
            burn = min(self.materials["scrapwood"], delta * self.scenario.firepit_rate_per_minute / 60.0)
            self.materials["scrapwood"] -= burn
            previous_whole = math.floor(self.firepit_burn_progress + 1e-9)
            self.firepit_burn_progress += burn
            newly_whole = math.floor(self.firepit_burn_progress + 1e-9) - previous_whole
            if newly_whole > 0:
                self.add_xp({"woodcutting": 2 * newly_whole}, "Firepit burn")
            requested = delta * self.scenario.firepit_rate_per_minute / 60.0
            if burn + 1e-9 < requested:
                self.firepit_cooling_bonus = self.firepit_bonus_for_elapsed()
                self.firepit_active = False
                self.firepit_burn_progress = 0.0
                self.event("firepit", "Firepit ran out of Scrapwood")
        elif self.firepit_cooling_bonus > 0.0:
            self.firepit_cooling_bonus = max(0.0, self.firepit_cooling_bonus - delta / 500.0)

        any_missing = any(self.skills[skill].stamina + 1e-9 < self.max_stamina(skill) for skill in ALL_SKILLS)
        if any_missing and self.honey_seconds <= 1e-9 and self.materials["honey"] >= 1.0:
            self.materials["honey"] -= 1.0
            self.honey_seconds = 10.0
            self.event("resource", "spent 1 Honey; ten seconds of doubled stamina regeneration")
        honey_multiplier = 2.0 if self.honey_seconds > 1e-9 else 1.0
        if self.honey_seconds > 0.0:
            self.honey_seconds = max(0.0, self.honey_seconds - delta)
        pond_multiplier = 1.0 + self.pond_regen_bonus()
        for skill_id, state in self.skills.items():
            regen_multiplier = honey_multiplier * pond_multiplier * (1.0 + self.firepit_bonus(skill_id))
            state.stamina = min(self.max_stamina(skill_id), state.stamina + delta * regen_multiplier / REGEN_SECONDS)

    def firepit_bonus_for_elapsed(self) -> float:
        tier = min(15, int((self.time - self.firepit_started_at) // 60.0) + 1)
        return tier * 0.04

    def try_system_actions(self) -> None:
        if (
            not self.firepit_active
            and not self.pond_complete
            and self.skills["woodcutting"].level >= 2
            and self.materials["scrapwood"] >= 2.0
        ):
            self.materials["scrapwood"] -= 1.0
            self.firepit_active = True
            self.firepit_started_at = self.time
            self.firepit_burn_progress = 0.0
            self.firepit_cooling_bonus = 0.0
            self.firepit_starts += 1
            self.firepit_ever_started = True
            if self.times["firepit"] is None:
                self.times["firepit"] = self.time
            self.add_xp({"woodcutting": 2}, "Firepit ignition")
            target = "Woodcutting" if self.scenario.firepit_target == "woodcutting" else "Fighting, Thieving, Building, and Fishing"
            self.event("resource", f"spent 1 Scrapwood to light Firepit; recovery target: {target}")

        if (
            self.pond_build_started is None
            and not self.pond_complete
            and self.skills["build"].level >= 5
            and self.fish >= 8.0
        ):
            self.fish -= 8.0
            self.pond_build_started = self.time
            self.times["pond_started"] = self.time
            self.event("resource", "spent 8 Fish; Pond construction started")

        if self.pond_build_started is not None and not self.pond_complete and self.time >= self.pond_build_started + 15.0:
            self.pond_complete = True
            self.levels_at_pond = {skill: state.level for skill, state in self.skills.items()}
            self.relationships_at_pond = len(self.completed_relationship_actions)
            self.pond_bonus_at_completion = self.pond_regen_bonus()
            self.fish_eaten_at_pond = self.fish_eaten
            self.dead_current = 0.0
            self.times["pond"] = self.time
            before = {skill: self.skills[skill].stamina for skill in ALL_SKILLS}
            if self.scenario.pond_refill > 0.0:
                for skill in ALL_SKILLS:
                    state = self.skills[skill]
                    state.stamina = min(self.max_stamina(skill), state.stamina + self.scenario.pond_refill)
                self.pond_refill_total = sum(self.skills[skill].stamina - before[skill] for skill in ALL_SKILLS)
                self.pond_refill_skill_count = sum(
                    self.skills[skill].stamina > before[skill] + 1e-9 for skill in ALL_SKILLS
                )
            self.event(
                "pond",
                f"Pond restored: +{self.pond_bonus_at_completion * 100:.0f}% all-skill regeneration; "
                f"immediate refill {self.pond_refill_total:.1f} across {self.pond_refill_skill_count} gauges",
            )
            self.award_berry("pond-restored")

        fence_key = "fight:duel-fence-post"
        if (
            self.pond_complete
            and fence_key in self.unlocked
            and fence_key not in self.built_modules
            and self.materials["scrapwood"] >= 3.0
        ):
            self.materials["scrapwood"] -= 3.0
            self.built_modules.add(fence_key)
            self.times["fence"] = self.time
            self.event("resource", "spent 3 Scrapwood to build Duel Fence Post; awarded 60 Building XP")
            self.add_xp({"build": 60}, "Duel Fence Post build")

    def add_xp(self, rewards: dict[str, int], source: str) -> None:
        old_levels = {skill: self.skills[skill].level for skill in rewards}
        for skill_id, amount in rewards.items():
            if skill_id in self.skills and amount > 0:
                self.skills[skill_id].xp += amount
                self.skills[skill_id].level = skill_level_for_xp(self.skills[skill_id].xp)
        any_level_changed = False
        for skill_id, old_level in old_levels.items():
            new_level = self.skills[skill_id].level
            any_level_changed = any_level_changed or new_level != old_level
            for level in range(old_level + 1, new_level + 1):
                self.event("level", f"{skill_id} reached level {level} ({source})")
        if any_level_changed:
            self.refresh_unlocks()
        self.check_all_skills_two()

    def check_all_skills_two(self) -> None:
        if self.times["all_skills_2"] is not None or not all(self.skills[skill].level >= 2 for skill in ALL_SKILLS):
            return
        self.times["all_skills_2"] = self.time
        self.event("relationship", "all five skills reached level 2")
        self.award_berry("all-skills-level-2")

    def award_berry(self, milestone_id: str) -> None:
        if (
            milestone_id == "pond-restored"
            and self.scenario.pond_berry_use_requirement > 0
            and self.berry_uses < self.scenario.pond_berry_use_requirement
        ):
            if milestone_id not in self.deferred_berry_milestones:
                self.deferred_berry_milestones.add(milestone_id)
                self.event(
                    "treat",
                    f"Pond Berry ready after {self.scenario.pond_berry_use_requirement} milestone Berry uses; current {self.berry_uses}",
                )
            return
        if (
            not self.scenario.milestone_berries
            or milestone_id in self.claimed_berry_milestones
            or len(self.claimed_berry_milestones) >= self.scenario.milestone_berry_limit
        ):
            return
        self.claimed_berry_milestones.add(milestone_id)
        if self.berry_inventory < 2:
            self.berry_inventory += 1
            disposition = f"inventory {self.berry_inventory}/2"
        else:
            self.pending_berries += 1
            disposition = f"pending applications {self.pending_berries}"
        self.materials["berries"] = float(self.berry_inventory)
        if self.times["first_berry"] is None:
            self.times["first_berry"] = self.time
        self.event("treat", f"Berry awarded for {milestone_id}; {disposition}")
        self.prepare_next_berry(milestone_id)

    def release_deferred_berry_milestones(self) -> None:
        if (
            "pond-restored" in self.deferred_berry_milestones
            and self.berry_uses >= self.scenario.pond_berry_use_requirement
        ):
            self.deferred_berry_milestones.remove("pond-restored")
            self.award_berry("pond-restored")

    def berry_eligible(self, key: str) -> bool:
        action = self.action(key)
        if str(action.get("kind", "")) == "passive_item_collect":
            return False
        if action.get("build") or action.get("recovery") or action.get("boss") or action.get("combat"):
            return False
        if any(str(reward.get("id", reward.get("mat", ""))) == "berries" for reward in action.get("mat_rewards") or []):
            return False
        return any(amount > 0 for amount in self.authored_xp_map(key).values())

    def prepare_next_berry(self, milestone_id: str) -> None:
        if self.scenario.berry_policy != "use" or self.prepared_target:
            return
        if self.pending_berries <= 0 and self.berry_inventory <= 0:
            return
        target = ""
        reason = ""
        if milestone_id == "all-skills-level-2":
            target_options = {
                "latch": ("fight:wrestle-stuck-gate-latch", "first two-skill payoff"),
                "hammer": ("build:hammer-nails", "Building 3 opens the Hub"),
                "shallows": ("fishing:shallows", "Fish fund Pond and non-Fishing stamina"),
            }
            target, reason = target_options[self.scenario.first_berry_target]
        for key in COMBO_ORDER:
            if target:
                break
            if key not in self.completed_relationship_actions and self.berry_eligible(key):
                target = key
                reason = f"unfinished relationship: {self.action(key)['name']}"
                break
        if not target:
            if self.skills["fight"].level < 6:
                target = self.best_level_action("fight")
                reason = "Duel Fence Post requires Fighting 6"
            elif self.materials.get("scrapwood", 0.0) < 3.0:
                target = self.best_scrapwood_action()
                reason = "Duel Fence Post requires 3 Scrapwood"
            elif self.skills["woodcutting"].level < 10:
                target = self.best_level_action("woodcutting")
                reason = "Honey requires Woodcutting 10"
            else:
                target = self.best_level_action("thieving")
                reason = "Honey requires Thieving 12"
            target = target or "fishing:shallows"
        self.prepared_target = target
        self.prepared_funding = "pending" if self.pending_berries > 0 else "inventory"
        action = self.action(target)
        remaining = [f"{skill} {level}" for skill, level in self.requirements(action) if self.skills[skill].level < level]
        suffix = f"; remaining: {', '.join(remaining)}" if remaining else ""
        self.event(
            "treat",
            f"Berry prepared for {action['name']} ({self.prepared_funding}){suffix}; next shared target: {reason}",
        )

    def consume_prepared_berry(self, key: str) -> bool:
        if key != self.prepared_target or not self.berry_eligible(key):
            return False
        if self.prepared_funding == "pending":
            if self.pending_berries <= 0:
                return False
            self.pending_berries -= 1
        else:
            if self.berry_inventory <= 0:
                return False
            self.berry_inventory -= 1
        self.materials["berries"] = float(self.berry_inventory)
        self.berry_uses += 1
        if self.times["first_berry_use"] is None:
            self.times["first_berry_use"] = self.time
        action_name = str(self.action(key)["name"])
        self.event("resource", f"spent 1 Berry on {action_name}; authored XP and eligible resources doubled")
        self.prepared_target = ""
        self.prepared_funding = ""
        self.release_deferred_berry_milestones()
        return True

    def roll_materials(self, action: dict[str, Any], berry_used: bool) -> dict[str, float]:
        rolled: dict[str, float] = {}
        for reward in action.get("mat_rewards") or []:
            mat_id = str(reward.get("id", reward.get("mat", "")))
            chance = min(1.0, max(0.0, float(reward.get("chance", 1.0))))
            amount = 0.0
            if self.rng.random() <= chance:
                minimum = max(0.0, float(reward.get("min", reward.get("amount", 0.0))))
                maximum = max(minimum, float(reward.get("max", reward.get("amount", minimum))))
                amount = self.rng.uniform(minimum, maximum)
                if bool(reward.get("whole", False)):
                    amount = math.floor(amount + 0.0001)
                if (
                    bool(reward.get("allow_zero", True))
                    and minimum <= 0.0 < maximum
                    and self.rng.random() < float(reward.get("zero_chance", 0.0))
                ):
                    amount = 0.0
            if berry_used and mat_id != "berries":
                amount *= 2.0
            rolled[mat_id] = rolled.get(mat_id, 0.0) + amount
        return rolled

    def update_mastery(self, key: str, success: bool) -> None:
        before = self.mastery_xp.get(key, 0)
        if self.mastery_contract == "database":
            reward = 7 + math.ceil(self.effective_seconds(key) * 1.5) if success else 0
        else:
            reward = 1 if success or before + 1 < 18 else 0
        if reward > 0:
            self.mastery_xp[key] = before + reward
        after = self.mastery_xp.get(key, before)
        if before < 18 <= after and key not in self.bronze_actions:
            self.bronze_actions.add(key)
            self.event("mastery", f"{self.action(key)['name']} earned Bronze mastery")
            if not self.global_bronze:
                self.global_bronze = True
                self.event("relationship", "first global Bronze buff unlocked: +1 max stamina for every skill")

    def complete_action(self, choice: Choice) -> None:
        key = choice.key
        action = self.action(key)
        owner = str(action["owner"])
        cost = self.action_cost(key)
        if self.skills[owner].stamina + 1e-9 >= cost:
            self.skills[owner].stamina = max(0.0, self.skills[owner].stamina - cost)
        self.skills[owner].completions += 1
        self.attempts += 1
        success = self.attempts <= 7 or self.rng.random() <= self.success_chance(key)
        self.update_mastery(key, success)
        if not success:
            self.streak_key = ""
            self.streak_count = 0
            return

        if self.streak_key == key:
            self.streak_count += 1
        else:
            self.streak_key = key
            self.streak_count = 1
        streak_multiplier = 1
        if owner != "fishing" and self.streak_count % 5 == 0:
            streak_multiplier = 2
        authored = self.authored_xp_map(key)
        rewards = {skill: amount * streak_multiplier for skill, amount in authored.items()}
        berry_used = self.consume_prepared_berry(key)
        if berry_used:
            for skill, amount in authored.items():
                rewards[skill] = rewards.get(skill, 0) + amount
        self.add_xp(rewards, str(action["name"]))

        recovery = action.get("recovery") or {}
        if recovery:
            target = owner
            target_mode = str(recovery.get("target", "self"))
            if self.scenario.early_recovery_target == "lowest" and int(action.get("unlock", 1)) <= 8:
                target_mode = "lowest"
            if target_mode == "lowest":
                target = min(ALL_SKILLS, key=lambda skill: self.skills[skill].stamina / max(1.0, self.max_stamina(skill)))
            before = self.skills[target].stamina
            self.skills[target].stamina = min(self.max_stamina(target), before + float(recovery.get("stamina", 0.0)))
            restored = self.skills[target].stamina - before
            if restored > 1e-9:
                self.recovery_uses += 1
                self.recovery_stamina += restored
                if self.times["first_recovery_use"] is None:
                    self.times["first_recovery_use"] = self.time
                    self.event("recovery", f"first recovery use: {action['name']} restored {restored:.1f} {target} stamina")

        for mat_id, amount in self.roll_materials(action, berry_used).items():
            if amount <= 0.0:
                continue
            self.materials[mat_id] = self.materials.get(mat_id, 0.0) + amount
            if mat_id == "honey" and self.times["honey"] is None:
                self.times["honey"] = self.time
                self.event("relationship", f"Honey acquired from {action['name']}")

        if owner == "fishing":
            fish_reward = 1.0 * (2.0 if berry_used else 1.0)
            self.fish += fish_reward

        if len([amount for amount in authored.values() if amount > 0]) >= 2:
            first_combo = self.times["first_combo"] is None
            self.completed_relationship_actions.add(key)
            if first_combo:
                self.times["first_combo"] = self.time
                split = " + ".join(f"{amount} {skill} XP" for skill, amount in authored.items())
                self.event("relationship", f"first two-skill activity completed: {action['name']} ({split})")
                self.award_berry("first-two-skill-activity")

    def action_is_basic(self, key: str) -> bool:
        action = self.action(key)
        if key not in self.unlocked:
            return False
        if str(action.get("kind", "")) == "passive_item_collect":
            return False
        if action.get("build") or action.get("recovery") or action.get("boss") or action.get("combat"):
            return False
        if len([amount for amount in self.authored_xp_map(key).values() if amount > 0]) >= 2:
            return False
        return True

    def best_level_action(self, skill_id: str) -> str:
        candidates = [
            key
            for key in ACTIONS_BY_SKILL[skill_id]
            if self.action_is_basic(key)
        ]
        if not candidates:
            return ""
        return max(
            candidates,
            key=lambda key: (
                sum(self.authored_xp_map(key).values()) * self.success_chance(key) / self.effective_seconds(key),
                int(self.action(key).get("unlock", 1)),
            ),
        )

    def best_scrapwood_action(self) -> str:
        candidates: list[tuple[float, str]] = []
        for key in ACTIONS_BY_SKILL["woodcutting"]:
            action = self.action(key)
            if key not in self.unlocked or action["owner"] != "woodcutting":
                continue
            rewards = action.get("mat_rewards") or []
            expected = 0.0
            for reward in rewards:
                if str(reward.get("id", "")) != "scrapwood":
                    continue
                minimum = float(reward.get("min", reward.get("amount", 0.0)))
                maximum = float(reward.get("max", reward.get("amount", minimum)))
                expected += (minimum + maximum) * 0.5 * float(reward.get("chance", 1.0))
                if minimum <= 0.0:
                    expected *= 1.0 - float(reward.get("zero_chance", 0.0))
            if expected > 0.0 and not action.get("recovery"):
                candidates.append((expected * self.success_chance(key) / self.effective_seconds(key), key))
        return max(candidates)[1] if candidates else self.best_level_action("woodcutting")

    def recovery_action(self, skill_id: str) -> str:
        candidates = [
            key
            for key in ACTIONS_BY_SKILL[skill_id]
            if key in self.unlocked and self.action(key).get("recovery")
        ]
        if not candidates:
            return ""
        return max(candidates, key=lambda key: float((self.action(key).get("recovery") or {}).get("stamina", 0.0)))

    def level_task(self, skill_id: str, level: int) -> tuple[str, str] | None:
        if self.skills[skill_id].level >= level:
            return None
        key = self.best_level_action(skill_id)
        return (f"level:{skill_id}:{level}", key) if key else None

    def route_candidates(self) -> list[Choice]:
        candidates: list[Choice] = []
        if self.scenario.route_policy == "pond_rush" and not self.pond_complete:
            for task in (
                self.level_task("fishing", 3),
                self.level_task("build", 5),
                ("resource:pond-fish", self.best_level_action("fishing")) if self.fish < 8.0 else None,
            ):
                if task and task[1]:
                    candidates.append(Choice(*task))
            return candidates
        if not all(self.skills[skill].level >= 2 for skill in ALL_SKILLS):
            for skill in SKILL_ORDER:
                task = self.level_task(skill, 2)
                if task:
                    candidates.append(Choice(*task))
            return candidates

        if self.prepared_target and self.prepared_target in self.unlocked and self.requirements_met(self.action(self.prepared_target)):
            candidates.append(Choice(f"prepared:{self.prepared_target}", self.prepared_target))

        prefix_tasks: list[tuple[str, str] | None] = [
            self.level_task("fight", 3),
            ("relationship:latch", COMBO_ORDER[0]) if COMBO_ORDER[0] not in self.completed_relationship_actions and COMBO_ORDER[0] in self.unlocked else None,
            ("resource:firepit", self.best_scrapwood_action()) if not self.firepit_ever_started else None,
        ]
        if self.scenario.fish_bridge:
            prefix_tasks.append(self.level_task("fishing", 3))
        ordered_tasks: list[tuple[str, str] | None] = prefix_tasks + [
            self.level_task("build", 4),
            ("relationship:saw", COMBO_ORDER[1]) if COMBO_ORDER[1] not in self.completed_relationship_actions and COMBO_ORDER[1] in self.unlocked else None,
        ]
        if not self.scenario.fish_bridge:
            ordered_tasks.append(self.level_task("fishing", 3))
        ordered_tasks += [
            self.level_task("woodcutting", 4),
            ("relationship:split", COMBO_ORDER[2]) if COMBO_ORDER[2] not in self.completed_relationship_actions and COMBO_ORDER[2] in self.unlocked else None,
            self.level_task("thieving", 4),
            self.level_task("build", 5),
            ("relationship:study", COMBO_ORDER[3]) if COMBO_ORDER[3] not in self.completed_relationship_actions and COMBO_ORDER[3] in self.unlocked else None,
            ("resource:pond-fish", self.best_level_action("fishing")) if self.pond_build_started is None and not self.pond_complete and self.fish < 8.0 else None,
        ]
        for task in ordered_tasks:
            if task and task[1]:
                candidates.append(Choice(*task))

        if self.pond_complete:
            fence_key = "fight:duel-fence-post"
            if fence_key not in self.built_modules:
                task = self.level_task("fight", 6)
                if task:
                    candidates.append(Choice(*task))
                elif self.materials["scrapwood"] < 3.0:
                    candidates.append(Choice("resource:fence-scrapwood", self.best_scrapwood_action()))
            if self.times["honey"] is None:
                for task in (self.level_task("woodcutting", 10), self.level_task("thieving", 12)):
                    if task:
                        candidates.append(Choice(*task))
                honey_key = "thieving:loot-beehive"
                if honey_key in self.unlocked:
                    candidates.append(Choice("relationship:honey", honey_key))

        if not self.pond_complete and self.pond_build_started is not None and not candidates:
            hold_key = self.best_level_action(self.last_skill) if self.last_skill else ""
            if hold_key:
                candidates.append(Choice("pond:building", hold_key))

        if not candidates:
            lowest = min(ALL_SKILLS, key=lambda skill: (self.skills[skill].level, self.skills[skill].xp, skill))
            target = self.skills[lowest].level + 1
            task = self.level_task(lowest, target)
            if task:
                candidates.append(Choice(*task))
        unique: list[Choice] = []
        seen: set[tuple[str, str]] = set()
        for choice in candidates:
            marker = (choice.task, choice.key)
            if marker not in seen:
                unique.append(choice)
                seen.add(marker)
        return unique

    def affordable(self, choice: Choice) -> bool:
        action = self.action(choice.key)
        return self.skills[str(action["owner"])].stamina + 1e-9 >= self.action_cost(choice.key)

    def feed_surplus_fish_for(self, choice: Choice) -> bool:
        if not self.scenario.fish_bridge or self.affordable(choice):
            return self.affordable(choice)
        owner = str(self.action(choice.key)["owner"])
        if owner == "fishing":
            return True
        reserve = (
            8.0
            if self.scenario.protect_pond_fish
            and self.pond_build_started is None
            and not self.pond_complete
            else 0.0
        )
        available = max(0, math.floor(self.fish - reserve + 1e-9))
        if self.fish_spend_cap is not None:
            available = min(available, max(0, self.fish_spend_cap - self.fish_eaten))
        missing_stamina = max(0.0, self.action_cost(choice.key) - self.skills[owner].stamina - 1e-9)
        needed = max(0, math.ceil(missing_stamina / self.scenario.fish_stamina))
        if needed <= 0 or available < needed:
            return False
        self.fish -= float(needed)
        if reserve > 0.0 and self.fish < reserve - 1e-9:
            raise AssertionError("Fish bridge spent the protected Pond reserve")
        self.fish_eaten += needed
        restored = min(
            self.max_stamina(owner) - self.skills[owner].stamina,
            float(needed) * self.scenario.fish_stamina,
        )
        self.skills[owner].stamina += restored
        reserve_text = "; 8 Fish remain reserved for Pond" if reserve > 0.0 else ""
        spend_label = "surplus Fish" if self.scenario.protect_pond_fish else "Fish"
        self.event("resource", f"spent {needed} {spend_label}; restored {restored:.1f} {owner} stamina{reserve_text}")
        return self.affordable(choice)

    def choose(self) -> Choice:
        candidates = self.route_candidates()
        if self.last_task:
            for choice in candidates:
                same_task = choice.task == self.last_task
                same_skill = str(self.action(choice.key)["owner"]) == self.last_skill
                if same_task and same_skill:
                    self.feed_surplus_fish_for(choice)
                    return choice
        if candidates:
            primary = candidates[0]
            owner = str(self.action(primary.key)["owner"])
            self.feed_surplus_fish_for(primary)
            recovery = self.recovery_action(owner) if not self.affordable(primary) else ""
            if recovery:
                return Choice(f"recovery:{owner}", recovery)
            return primary
        raise RuntimeError("No guided action was available")

    def begin_choice(self, choice: Choice) -> None:
        owner = str(self.action(choice.key)["owner"])
        if not self.last_skill:
            self.event("start", f"started {owner}/{self.action(choice.key)['name']} ({choice.task})")
        elif owner != self.last_skill:
            self.switch_times.append(self.time)
            self.event("switch", f"switched {self.last_skill} -> {owner}: {self.action(choice.key)['name']} ({choice.task})")
        self.last_skill = owner
        self.last_task = choice.task
        self.last_action_key = choice.key
        self.active = choice

    def update_dead_time(self, delta: float) -> None:
        if self.active is not None and self.affordable(self.active):
            self.dead_current = 0.0
            return
        self.tired_training_total += delta
        if self.pond_complete:
            self.dead_current = 0.0
            return
        self.dead_total += delta
        self.dead_current += delta
        self.dead_longest = max(self.dead_longest, self.dead_current)

    def run(self) -> RunResult:
        while self.time < self.duration - 1e-9:
            self.try_system_actions()
            if self.active is None:
                self.begin_choice(self.choose())
            delta = min(self.step, self.duration - self.time)
            self.update_dead_time(delta)
            self.update_passive_systems(delta)
            choice = self.active
            assert choice is not None
            owner = str(self.action(choice.key)["owner"])
            has_stamina = self.skills[owner].stamina + 1e-9 >= self.action_cost(choice.key)
            speed = 1.0 if has_stamina else 0.20
            self.progress[choice.key] = self.progress.get(choice.key, 0.0) + delta * speed / self.effective_seconds(choice.key)
            self.time += delta
            if self.progress[choice.key] + 1e-9 < 1.0:
                continue
            self.progress[choice.key] = 0.0
            self.complete_action(choice)
            self.active = None

        self.try_system_actions()
        max_switches_30 = 0
        for index, start in enumerate(self.switch_times):
            count = 0
            for candidate in self.switch_times[index:]:
                if candidate - start <= 30.0 + 1e-9:
                    count += 1
                else:
                    break
            max_switches_30 = max(max_switches_30, count)
        pond_time = self.times["pond"] if self.times["pond"] is not None else self.duration
        return RunResult(
            scenario=self.scenario.name,
            seed=self.seed,
            times=dict(self.times),
            total_dead_seconds=self.dead_total,
            longest_dead_seconds=self.dead_longest,
            switches=len(self.switch_times),
            switches_first_15=sum(1 for value in self.switch_times if value <= 900.0),
            switches_before_pond=sum(1 for value in self.switch_times if value <= float(pond_time)),
            max_switches_30=max_switches_30,
            levels={skill: state.level for skill, state in self.skills.items()},
            stamina={skill: state.stamina for skill, state in self.skills.items()},
            berries=self.berry_inventory,
            pending_berries=self.pending_berries,
            deferred_berry_milestones=len(self.deferred_berry_milestones),
            prepared_target=self.prepared_target,
            prepared_funding=self.prepared_funding,
            berry_uses=self.berry_uses,
            fish=self.fish,
            scrapwood=self.materials["scrapwood"],
            firepit_starts=self.firepit_starts,
            fence_built="fight:duel-fence-post" in self.built_modules,
            pond_refill_total=self.pond_refill_total,
            pond_refill_skill_count=self.pond_refill_skill_count,
            fish_eaten=self.fish_eaten,
            fish_eaten_at_pond=self.fish_eaten_at_pond,
            recovery_uses=self.recovery_uses,
            recovery_stamina=self.recovery_stamina,
            levels_at_pond=dict(self.levels_at_pond),
            relationships_at_pond=self.relationships_at_pond,
            pond_bonus_at_completion=self.pond_bonus_at_completion,
            pond_bonus_at_end=self.pond_regen_bonus(),
            events=list(self.events),
        )


def numeric_times(results: Iterable[RunResult], metric: str) -> list[float]:
    return [float(result.times[metric]) for result in results if result.times[metric] is not None]


def range_text(values: list[float]) -> str:
    if not values:
        return "-"
    return f"{clock(statistics.median(values))} ({clock(percentile(values, 0.10))}-{clock(percentile(values, 0.90))})"


def percentage(numerator: int, denominator: int) -> str:
    return f"{100.0 * numerator / max(1, denominator):.0f}%"


def print_summary(scenario: Scenario, results: list[RunResult]) -> None:
    pond_times = numeric_times(results, "pond")
    all_two = numeric_times(results, "all_skills_2")
    firepit = numeric_times(results, "firepit")
    combo = numeric_times(results, "first_combo")
    berry_use = numeric_times(results, "first_berry_use")
    fence = numeric_times(results, "fence")
    honey = numeric_times(results, "honey")
    recovery_unlock = numeric_times(results, "first_recovery_unlock")
    recovery_use = numeric_times(results, "first_recovery_use")
    refill_counts = [float(result.pond_refill_skill_count) for result in results]
    refill_totals = [float(result.pond_refill_total) for result in results]
    fish_eaten_at_pond = [
        float(result.fish_eaten_at_pond)
        for result in results
        if result.fish_eaten_at_pond is not None
    ]
    skills_two_at_pond = [
        float(sum(1 for level in result.levels_at_pond.values() if level >= 2))
        for result in results
        if result.levels_at_pond
    ]
    relationships_at_pond = [
        float(result.relationships_at_pond)
        for result in results
        if result.levels_at_pond
    ]
    pond_bonus_at_completion = [
        result.pond_bonus_at_completion * 100.0
        for result in results
        if result.levels_at_pond
    ]
    pond_bonus_at_end = [result.pond_bonus_at_end * 100.0 for result in results]
    print(scenario.name)
    print(f"  runs: {len(results)}")
    print(f"  all skills level 2 median (P10-P90): {range_text(all_two)}")
    print(f"  first Firepit median (P10-P90): {range_text(firepit)}")
    print(f"  first two-skill completion median (P10-P90): {range_text(combo)}")
    print(f"  first Berry use median (P10-P90): {range_text(berry_use)}")
    print(f"  Pond completion median (P10-P90): {range_text(pond_times)}")
    print(f"  Duel Fence Post build median (P10-P90): {range_text(fence)}")
    print(f"  Honey acquisition median (P10-P90): {range_text(honey)}")
    print(f"  first recovery unlock median (P10-P90): {range_text(recovery_unlock)}")
    print(f"  first recovery use median (P10-P90): {range_text(recovery_use)}")
    if skills_two_at_pond:
        print(
            "  state at Pond: median skills at level 2+ {skills:.0f}/5; completed two-skill actions {relationships:.0f}/4".format(
                skills=statistics.median(skills_two_at_pond),
                relationships=statistics.median(relationships_at_pond),
            )
        )
        print(
            "  Pond bonus: median {completion:.0f}% at completion; {end:.0f}% at end".format(
                completion=statistics.median(pond_bonus_at_completion),
                end=statistics.median(pond_bonus_at_end),
            )
        )
    if scenario.pond_refill > 0.0:
        print(
            "  Pond refill median (P10-P90): {total:.1f} stamina ({total_p10:.1f}-{total_p90:.1f}); "
            "{count:.0f} gauges ({count_p10:.0f}-{count_p90:.0f})".format(
                total=statistics.median(refill_totals),
                total_p10=percentile(refill_totals, 0.10),
                total_p90=percentile(refill_totals, 0.90),
                count=statistics.median(refill_counts),
                count_p10=percentile(refill_counts, 0.10),
                count_p90=percentile(refill_counts, 0.90),
            )
        )
    print(
        "  target rates: automated Pond 12-20m {machine_pond}; observational Pond 20-35m {human_pond}; "
        "longest dead interval <=60s {dead}; 8-12 switches before Pond {prepond_switches}; "
        "6-12 switches first 15m {switches}; <=3 switches/30s {switch_window}".format(
            machine_pond=percentage(sum(720.0 <= value <= 1200.0 for value in pond_times), len(results)),
            human_pond=percentage(sum(1200.0 <= value <= 2100.0 for value in pond_times), len(results)),
            dead=percentage(sum(result.longest_dead_seconds <= 60.0 for result in results), len(results)),
            prepond_switches=percentage(sum(8 <= result.switches_before_pond <= 12 for result in results), len(results)),
            switches=percentage(sum(6 <= result.switches_first_15 <= 12 for result in results), len(results)),
            switch_window=percentage(sum(result.max_switches_30 <= 3 for result in results), len(results)),
        )
    )
    print(
        "  median state: switches first 15m {switches:.0f}; switches before Pond {prepond:.0f}; max switches/30s {window:.0f}; pre-Pond dead {dead}; longest pre-Pond dead {longest}; Fish eaten by Pond {fish}; Berry uses {uses:.0f}; Firepit starts {firepit_starts:.0f}; recovery uses {recovery_uses:.0f}; recovery stamina {recovery_stamina:.1f}".format(
            switches=statistics.median(result.switches_first_15 for result in results),
            prepond=statistics.median(result.switches_before_pond for result in results),
            window=statistics.median(result.max_switches_30 for result in results),
            dead=clock(statistics.median(result.total_dead_seconds for result in results)),
            longest=clock(statistics.median(result.longest_dead_seconds for result in results)),
            fish=f"{statistics.median(fish_eaten_at_pond):.0f}" if fish_eaten_at_pond else "-",
            uses=statistics.median(result.berry_uses for result in results),
            firepit_starts=statistics.median(result.firepit_starts for result in results),
            recovery_uses=statistics.median(result.recovery_uses for result in results),
            recovery_stamina=statistics.median(result.recovery_stamina for result in results),
        )
    )
    representative = results[0]
    stamina = "; ".join(f"{skill} {representative.stamina[skill]:.1f}" for skill in ALL_SKILLS)
    levels = "; ".join(f"{skill} {representative.levels[skill]}" for skill in ALL_SKILLS)
    prepared = representative.prepared_target or "none"
    if representative.prepared_funding:
        prepared += f" ({representative.prepared_funding})"
    print(f"  seed {representative.seed} final levels: {levels}")
    print(f"  seed {representative.seed} unused stamina: {stamina}")
    print(
        f"  seed {representative.seed} resources: Fish {representative.fish:.1f}; Fish eaten {representative.fish_eaten}; Scrapwood {representative.scrapwood:.2f}; "
        f"Berries {representative.berries}/2; pending {representative.pending_berries}; deferred milestones {representative.deferred_berry_milestones}; prepared {prepared}; "
        f"Firepit starts {representative.firepit_starts}; fence built {representative.fence_built}; "
        f"Pond refill {representative.pond_refill_total:.1f} across {representative.pond_refill_skill_count} gauges"
    )


def print_trace(result: RunResult) -> None:
    print(f"  trace for seed {result.seed}")
    for seconds, category, message in result.events:
        print(f"    {clock(seconds)}  {category:<12} {message}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scenario", choices=("all", *SCENARIOS.keys()), default="all")
    parser.add_argument("--runs", type=int, default=100)
    parser.add_argument("--seed", type=int, default=41010)
    parser.add_argument("--duration", type=float, default=3600.0)
    parser.add_argument("--step", type=float, default=0.5)
    parser.add_argument("--trace", action="store_true", help="Print every recorded event for the first seed in each selected scenario.")
    parser.add_argument("--check-determinism", action="store_true")
    parser.add_argument(
        "--fish-spend-cap",
        type=int,
        help="Sensitivity override: cap the total Fish that surplus auto-eat may spend in each run.",
    )
    parser.add_argument(
        "--mastery-contract",
        choices=("runtime", "database"),
        default="runtime",
        help="Use current one-point runtime mastery or the activity-database success formula.",
    )
    return parser.parse_args()


def result_signature(result: RunResult) -> tuple[Any, ...]:
    return (
        result.times,
        result.levels,
        result.stamina,
        result.berries,
        result.pending_berries,
        result.deferred_berry_milestones,
        result.berry_uses,
        result.fish_eaten,
        result.fish_eaten_at_pond,
        result.fish,
        result.scrapwood,
        result.recovery_uses,
        result.recovery_stamina,
        result.levels_at_pond,
        result.relationships_at_pond,
        result.pond_bonus_at_completion,
        result.pond_bonus_at_end,
        result.events,
    )


def main() -> int:
    args = parse_args()
    if args.runs < 1:
        raise ValueError("--runs must be at least 1")
    if args.duration <= 0.0 or args.step <= 0.0:
        raise ValueError("--duration and --step must be positive")
    if args.fish_spend_cap is not None and args.fish_spend_cap < 0:
        raise ValueError("--fish-spend-cap must be zero or greater")
    selected = list(SCENARIOS.values()) if args.scenario == "all" else [SCENARIOS[args.scenario]]
    print("First-hour relationship simulator")
    print(f"Duration: {clock(args.duration)}; runs per scenario: {args.runs}; first seed: {args.seed}; step: {args.step:.2f}s")
    if args.fish_spend_cap is not None:
        print(f"Sensitivity override: surplus auto-eat may spend at most {args.fish_spend_cap} Fish per run.")
    print(f"Mastery contract: {args.mastery_contract}.")
    print(
        "Modeled: requirements and immediate manual unlocks, runtime stamina and Bare Hands Fishing, optional Pond Fish protection and auto-eat, "
        "first seven guaranteed successes, fifth-repeat XP, random materials, buildables, recovery, Firepit, Pond, candidate Berries, Honey, "
        "Bronze mastery, and the first global medal buff."
    )
    print(
        "Not modeled: UI interaction time, onboarding gates, crits, ads, tool acquisition, bosses, action-opportunity clicks, later mastery tiers, missions, and offline progress."
    )
    if args.mastery_contract == "runtime":
        print(
            "Repository drift: runtime mastery awards 1 per attempt but prevents a failed attempt from crossing a medal, while docs/activity-database.json declares 7 + ceil(base_seconds * 1.5) on success; this model uses runtime behavior."
        )
    else:
        print(
            "Sensitivity override: mastery follows docs/activity-database.json instead of current runtime."
        )
    print()
    for scenario in selected:
        results = [
            FirstHourSimulation(
                scenario,
                args.seed + index,
                args.duration,
                args.step,
                args.fish_spend_cap,
                args.mastery_contract,
            ).run()
            for index in range(args.runs)
        ]
        if args.check_determinism:
            repeat = FirstHourSimulation(
                scenario,
                args.seed,
                args.duration,
                args.step,
                args.fish_spend_cap,
                args.mastery_contract,
            ).run()
            if result_signature(results[0]) != result_signature(repeat):
                raise AssertionError(f"Non-deterministic result for {scenario.name} seed {args.seed}")
        for result in results:
            if not 0 <= result.berries <= 2:
                raise AssertionError(f"Berry capacity violated in {scenario.name} seed {result.seed}")
            if result.pending_berries < 0:
                raise AssertionError(f"Negative pending Berry count in {scenario.name} seed {result.seed}")
        print_summary(scenario, results)
        if args.trace:
            print_trace(results[0])
        print()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
