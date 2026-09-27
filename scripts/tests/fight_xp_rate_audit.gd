extends SceneTree

const Stage := preload("res://scripts/ui/blue_guy_chicken_brawl_stage.gd")
const STEP := 0.05
var sample_seconds := 180.0
const SAMPLES := 16
const FIGHT_IDS := [
	"fight-chickens",
	"fight-goblins",
	"fight-r.o.u.s.es",
	"fight-guys",
	"fight-werewolves",
	"fight-cave-trolls",
	"fight-giants",
	"fight-vampires",
	"fight-dragons",
]
const PLUS_FIVE_RATE_TARGETS := [5322.0, 8225.0, 9126.0, 9388.0, 9388.0, 10606.0, 14840.0, 15193.0, 15193.0]
const OCCASIONAL_UNLOCK_KILL_FIGHTS := [
	"fight-r.o.u.s.es",
	"fight-werewolves",
	"fight-cave-trolls",
	"fight-giants",
]

var failures: Array[String] = []
var previous_level_rate := 0.0
var previous_reward_events := 0
var sample_xp := 0
var sample_reward_events := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if not OS.get_environment("IDLE_ELITE_COMBAT_SAMPLE_SECONDS").is_empty():
		sample_seconds = maxf(180.0, float(OS.get_environment("IDLE_ELITE_COMBAT_SAMPLE_SECONDS")))
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	var scene := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	scene.get("activity_data_catalog").call("load_action_data", scene)
	scene.call("_save_runtime").call("_init_state")
	for fight_id in FIGHT_IDS:
		var action := scene.call("_action_data", "fight", fight_id) as Dictionary
		var unlock := int(action.get("unlock", 1))
		var midpoint := int(ceil((float(unlock) + 99.0) * 0.5))
		previous_level_rate = 0.0
		previous_reward_events = 0
		var audited_levels := []
		var levels := [unlock, mini(99, unlock + 5), midpoint, 99]
		levels.sort()
		for level in levels:
			if audited_levels.has(level):
				continue
			audited_levels.append(level)
			_run_fight(action, level)
	scene.free()
	print("fight-xp-rate-audit-ok" if failures.is_empty() else "fight-xp-rate-audit-failed")
	quit(0 if failures.is_empty() else 1)


func _run_fight(action: Dictionary, level: int) -> void:
	var stage := Stage.new()
	root.add_child(stage)
	stage.set_process(false)
	stage.set("arena_shape", "diamond")
	stage.call("setup_action", action)
	stage.call("setup_fighting_level", level)
	stage.chicken_killed.connect(_on_xp)
	var total_xp := 0
	var total_reward_events := 0
	var total_player_kos := 0
	var total_clears := 0
	for sample in range(SAMPLES):
		seed(str(action.get("id", "")).hash() + sample + 2000)
		sample_xp = 0
		sample_reward_events = 0
		stage.call("set_active_fight", false)
		stage.set("kill_xp_fraction", 0.0)
		stage.set("elapsed_seconds", 0.0)
		stage.call("set_active_fight", true)
		var was_ko := false
		var was_clear := false
		for _frame in range(int(sample_seconds / STEP)):
			stage.set("elapsed_seconds", float(stage.get("elapsed_seconds")) + STEP)
			stage.call("_step_visual_fx", STEP)
			var frozen := float(stage.get("hit_stop_timer")) > 0.0
			stage.set("hit_stop_timer", maxf(0.0, float(stage.get("hit_stop_timer")) - STEP))
			stage.call("_step_fight", 0.0 if frozen else STEP)
			var is_ko := float(stage.get("hero_ko_timer")) > 0.0
			var is_clear := float(stage.get("area_clear_restart_timer")) > 0.0
			if is_ko and not was_ko:
				total_player_kos += 1
			if is_clear and not was_clear:
				total_clears += 1
			was_ko = is_ko
			was_clear = is_clear
		total_xp += sample_xp
		total_reward_events += sample_reward_events
	var hours := float(SAMPLES) * sample_seconds / 3600.0
	var xp_per_hour := float(total_xp) / hours
	var reward_events_per_hour := float(total_reward_events) / hours
	var unlock_level := int(action.get("unlock", 1))
	var fight_id := str(action.get("id", ""))
	if level == unlock_level and fight_id in OCCASIONAL_UNLOCK_KILL_FIGHTS:
		check(reward_events_per_hour <= 10.0, "%s should get only occasional unlock-level kills" % fight_id)
	check(level == unlock_level or xp_per_hour > 0.0, "%s must award XP at level %d" % [fight_id, level])
	# Unlock kills may be absent. Sampled progression allows 15% random variation.
	if total_reward_events >= 16 and previous_reward_events >= 16:
		check(xp_per_hour >= previous_level_rate * 0.85, "%s XP must not fall as Fighting improves" % fight_id)
	previous_level_rate = xp_per_hour
	previous_reward_events = total_reward_events
	if level == mini(99, unlock_level + 5):
		check(reward_events_per_hour >= 30.0, "%s must have regular kills by unlock plus five" % fight_id)
		var floor_rate := float(PLUS_FIVE_RATE_TARGETS[FIGHT_IDS.find(fight_id)])
		check(xp_per_hour >= floor_rate * 0.70 and xp_per_hour <= floor_rate * 1.30, "%s unlock-plus-five reward rate is outside its training band" % fight_id)
	print("FIGHT_AUDIT|%s|%s|%d|%d|%.1f|%.2f|%.2f|%.2f|%d" % [
		str(action.get("id", "")),
		str(action.get("name", "")),
		int(action.get("unlock", 1)),
		level,
		xp_per_hour,
		float(total_player_kos) / hours,
		float(total_clears) / hours,
		reward_events_per_hour,
		int(stage.get("planned_kill_count")),
	])
	stage.free()


func _on_xp(amount: int) -> void:
	sample_xp += maxi(0, amount)
	sample_reward_events += 1


func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
