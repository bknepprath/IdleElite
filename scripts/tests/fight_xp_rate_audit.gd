extends SceneTree

const Stage := preload("res://scripts/ui/blue_guy_chicken_brawl_stage.gd")
const STEP := 0.05
const SAMPLE_SECONDS := 180.0
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
const PAR_RATE_TARGETS := {
	"fight-chickens": 19289.6,
	"fight-goblins": 25122.3,
	"fight-r.o.u.s.es": 33217.5,
	"fight-guys": 39840.0,
	"fight-werewolves": 36896.3,
	"fight-cave-trolls": 41699.6,
	"fight-giants": 65007.6,
	"fight-vampires": 439110.0,
	"fight-dragons": 439110.0,
}
const OCCASIONAL_UNLOCK_KILL_FIGHTS := [
	"fight-r.o.u.s.es",
	"fight-werewolves",
	"fight-cave-trolls",
	"fight-giants",
]

var sample_xp := 0
var sample_reward_events := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
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
		var audited_levels := []
		for level in [unlock, mini(99, unlock + 8), midpoint, 99]:
			if audited_levels.has(level):
				continue
			audited_levels.append(level)
			_run_fight(action, level)
	scene.free()
	print("fight-xp-rate-audit-ok")
	quit(0)


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
		seed(str(action.get("id", "")).hash() + sample)
		sample_xp = 0
		sample_reward_events = 0
		stage.call("set_active_fight", false)
		stage.set("elapsed_seconds", 0.0)
		stage.call("set_active_fight", true)
		var was_ko := false
		var was_clear := false
		for _frame in range(int(SAMPLE_SECONDS / STEP)):
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
	var hours := float(SAMPLES) * SAMPLE_SECONDS / 3600.0
	var xp_per_hour := float(total_xp) / hours
	var reward_events_per_hour := float(total_reward_events) / hours
	var unlock_level := int(action.get("unlock", 1))
	var fight_id := str(action.get("id", ""))
	if level == unlock_level and fight_id in OCCASIONAL_UNLOCK_KILL_FIGHTS:
		assert(reward_events_per_hour > 0.0 and reward_events_per_hour <= 10.0, "%s should get only occasional unlock-level kills" % fight_id)
	if level == mini(99, unlock_level + 8):
		var target_rate := float(PAR_RATE_TARGETS.get(fight_id, 0.0))
		assert(target_rate > 0.0 and absf(xp_per_hour - target_rate) / target_rate <= 0.10, "%s must reach its comparable skilling rate near +8" % fight_id)
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
