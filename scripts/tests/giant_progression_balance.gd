extends SceneTree

const Stage := preload("res://scripts/ui/blue_guy_chicken_brawl_stage.gd")
const STEP := 0.05
const SAMPLES := 60


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
	stage.call("setup_action", scene.call("_action_data", "fight", "fight-giants") as Dictionary)
	var unlock := _run_level(stage, 74)
	_run_level(stage, 87)
	var high := _run_level(stage, 99)
	var balanced := unlock[0] + unlock[1] >= 50 and unlock[6] == 0
	balanced = balanced and high[0] + high[1] + high[2] == 0 and high[6] >= 2 and high[6] <= 15
	stage.queue_free()
	scene.queue_free()
	await process_frame
	quit(0 if balanced else 1)


func _run_level(stage: Control, level: int) -> Array[int]:
	stage.call("setup_fighting_level", level)
	var outcomes: Array[int] = [0, 0, 0, 0, 0, 0, 0]
	for sample in range(SAMPLES):
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
	print("giants-progression level=%d deaths=%s clears=%d/%d" % [level, str(outcomes.slice(0, 6)), outcomes[6], SAMPLES])
	return outcomes
