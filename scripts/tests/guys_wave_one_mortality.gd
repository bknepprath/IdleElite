extends SceneTree

const Stage := preload("res://scripts/ui/blue_guy_chicken_brawl_stage.gd")
const STEP := 0.05
const SAMPLES := 100


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	var scene := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	scene.get("activity_data_catalog").call("load_action_data", scene)
	scene.call("_save_runtime").call("_init_state")
	var stage := Stage.new()
	root.add_child(stage)
	stage.set_process(false)
	stage.call("setup_action", scene.call("_action_data", "fight", "fight-guys") as Dictionary)
	stage.call("setup_fighting_level", 32)
	var deaths := 0
	for sample in range(SAMPLES):
		seed(32000 + sample)
		stage.call("set_active_fight", false)
		stage.set("elapsed_seconds", 0.0)
		stage.call("set_active_fight", true)
		for _frame in range(4000):
			stage.set("elapsed_seconds", float(stage.get("elapsed_seconds")) + STEP)
			stage.call("_step_visual_fx", STEP)
			var frozen := float(stage.get("hit_stop_timer")) > 0.0
			stage.set("hit_stop_timer", maxf(0.0, float(stage.get("hit_stop_timer")) - STEP))
			stage.call("_step_fight", 0.0 if frozen else STEP)
			if float(stage.get("hero_ko_timer")) > 0.0 or int(stage.get("wave_index")) > 0:
				break
		if float(stage.get("hero_ko_timer")) > 0.0:
			deaths += 1
	print("guys-wave-one-mortality deaths=%d/%d rate=%.1f%%" % [deaths, SAMPLES, float(deaths)])
	var level_50 := _run_progression(stage, 50, 50)
	var level_62 := _run_progression(stage, 62, 50)
	var level_50_reached_wave_3 := 50 - int(level_50[0]) - int(level_50[1])
	var progression_ok := level_50_reached_wave_3 >= 40 and int(level_50[6]) == 0 and int(level_62[6]) >= 1 and int(level_62[6]) <= 15
	stage.queue_free()
	scene.queue_free()
	await process_frame
	quit(0 if deaths >= 90 and deaths <= 99 and progression_ok else 1)


func _run_progression(stage: Control, level: int, samples: int) -> Array[int]:
	stage.call("setup_fighting_level", level)
	var outcomes: Array[int] = [0, 0, 0, 0, 0, 0, 0]
	for sample in range(samples):
		seed(level * 1000 + sample)
		stage.call("set_active_fight", false)
		stage.set("elapsed_seconds", 0.0)
		stage.call("set_active_fight", true)
		for _frame in range(20000):
			stage.set("elapsed_seconds", float(stage.get("elapsed_seconds")) + STEP)
			stage.call("_step_visual_fx", STEP)
			var frozen := float(stage.get("hit_stop_timer")) > 0.0
			stage.set("hit_stop_timer", maxf(0.0, float(stage.get("hit_stop_timer")) - STEP))
			stage.call("_step_fight", 0.0 if frozen else STEP)
			if float(stage.get("hero_ko_timer")) > 0.0:
				outcomes[clampi(int(stage.get("wave_index")), 0, 5)] += 1
				break
			if float(stage.get("area_clear_restart_timer")) > 0.0:
				outcomes[6] += 1
				break
	print("guys-progression level=%d deaths=%s clears=%d/%d" % [level, str(outcomes.slice(0, 6)), outcomes[6], samples])
	return outcomes
