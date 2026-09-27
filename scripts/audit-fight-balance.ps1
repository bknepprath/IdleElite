# Fight economy audit: runs the production combat stage headless for every
# animated fight at several Fighting levels and compares XP/hour with the best
# regular Fighting activity (including stamina recovery time).
# Read-only: prints a table; changes nothing.
param(
    [int]$SimSeconds = 600,
    [int]$Seeds = 3
)
$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\fight-balance-audit"
$testScript = Join-Path $testDir "fight_balance_audit.gd"
New-Item -ItemType Directory -Force -Path $testDir | Out-Null

@"
extends SceneTree

const SIM_SECONDS := $SimSeconds
const SEEDS := $Seeds
const STEP := 1.0 / 30.0
const STAGE_SCRIPT := "res://scripts/ui/blue_guy_chicken_brawl_stage.gd"
const BASE_RECOVERY_SECONDS_PER_STAMINA := 12.0
const PUNCH_STAMINA_CHANCE := 0.05


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var database: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/activity-database.json"))
	var fight: Dictionary = {}
	for skill in database["skills"]:
		if str(skill["id"]) == "fight":
			fight = skill
	var actions: Array = fight["actions"]
	# Diamond arena stage inside a 610 px combat card (skill_detail_surface.gd).
	var stage_size := Vector2(940, 506)
	print("FIGHT_AUDIT stage_size=%s sim_seconds=%s seeds=%s" % [stage_size, SIM_SECONDS, SEEDS])
	for action in actions:
		if not (action as Dictionary).has("combat"):
			continue
		var unlock := int(action["unlock"])
		var levels := [unlock, mini(99, unlock + 5), int(round((unlock + 99) * 0.5)), 99]
		var seen := {}
		for level in levels:
			if seen.has(level):
				continue
			seen[level] = true
			var totals := {"xp": 0, "kills": 0, "punches": 0, "kos": 0}
			for seed_index in range(SEEDS):
				seed(1000 * level + seed_index + unlock)
				var result := await _simulate(action, level, stage_size)
				for key in totals.keys():
					totals[key] += result[key]
			var hours := float(SIM_SECONDS * SEEDS) / 3600.0
			var xp_hour := float(totals["xp"]) / hours
			var stamina_drain_hour := (float(totals["punches"]) * PUNCH_STAMINA_CHANCE + float(totals["kos"])) / hours
			var training := _best_training_xp_hour(actions, level)
			print("FIGHT_AUDIT id=%s unlock=%s level=%s xp_hour=%d training_xp_hour=%d ratio=%.2f kills_hour=%d kos_hour=%d stamina_drain_hour=%d" % [
				action["id"], unlock, level, xp_hour, training, xp_hour / maxf(1.0, training),
				float(totals["kills"]) / hours, float(totals["kos"]) / hours, stamina_drain_hour
			])
	print("FIGHT_AUDIT done")
	quit(0)


func _simulate(action: Dictionary, level: int, stage_size: Vector2) -> Dictionary:
	var stage: Control = load(STAGE_SCRIPT).new()
	stage.set("arena_shape", "diamond")
	stage.size = stage_size
	stage.custom_minimum_size = stage_size
	root.add_child(stage)
	var result := {"xp": 0, "kills": 0, "punches": 0, "kos": 0}
	stage.chicken_killed.connect(func(amount: int):
		result["xp"] += amount
		result["kills"] += 1)
	stage.punch_landed.connect(func(_shield: bool): result["punches"] += 1)
	stage.knocked_out.connect(func(): result["kos"] += 1)
	stage.setup_action(action)
	stage.setup_fighting_level(level)
	stage.setup_blue_guy_health(30, 30, 1.0)
	stage.set_active_fight(true)
	stage.set_process(false)
	var steps := int(SIM_SECONDS / STEP)
	for _i in range(steps):
		stage._process(STEP)
	stage.queue_free()
	await process_frame
	return result


# Best regular (non-animated) Fighting activity unlocked at this level:
# XP x success x 3600 / (seconds + stamina cost x recovery seconds per stamina).
func _best_training_xp_hour(actions: Array, level: int) -> float:
	var recovery := BASE_RECOVERY_SECONDS_PER_STAMINA
	for action in actions:
		var cost := _stamina_cost(action)
		if cost < 0.0 and int(action["unlock"]) <= level:
			recovery = minf(recovery, float(action["seconds"]) / absf(cost))
	var best := 0.0
	for action in actions:
		if action.has("combat") or not bool(action.get("enabled", true)) or int(action["unlock"]) > level:
			continue
		var cost := _stamina_cost(action)
		if cost <= 0.0:
			continue
		var xp := float((action.get("rewards", {}) as Dictionary).get("xp", action.get("xp", 0)))
		var rate := xp * float(action["success"]) / 100.0 * 3600.0 / (float(action["seconds"]) + cost * recovery)
		best = maxf(best, rate)
	return best


# Same precedence as scripts/activity_data/catalog.gd: the top-level stamina
# field is what the game charges; costs.stamina is only a fallback.
func _stamina_cost(action: Dictionary) -> float:
	return float(action.get("stamina", (action.get("costs", {}) as Dictionary).get("stamina", 1)))


"@ | Set-Content -LiteralPath $testScript -Encoding UTF8

$previousUserData = $env:IDLE_ELITE_TEST_USER_DATA_DIR
$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
try {
    $env:IDLE_ELITE_TEST_USER_DATA_DIR = Join-Path ([IO.Path]::GetTempPath()) ("idle-elite-fight-audit-" + [guid]::NewGuid().ToString("N"))
    $env:GODOT_RUN_TIMEOUT_SECONDS = "1800"
    $output = & $runner --headless --path $projectRoot --script "res://.codex-tmp/fight-balance-audit/fight_balance_audit.gd" 2>&1
    $output | Where-Object { "$_" -match "FIGHT_AUDIT|SCRIPT ERROR" } | ForEach-Object { Write-Output $_ }
} finally {
    $env:IDLE_ELITE_TEST_USER_DATA_DIR = $previousUserData
    $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
}
