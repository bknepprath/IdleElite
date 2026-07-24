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
	stage.call("setup_action", scene.call("_action_data", "fight", "fight-dragons") as Dictionary)
	stage.call("setup_fighting_level", 98)
	var one_kill_fights := 0
	for sample in range(SAMPLES):
		seed(98000 + sample)
		stage.call("set_active_fight", false)
		stage.set("elapsed_seconds", 0.0)
		stage.set("ko_count", 0)
		stage.call("set_active_fight", true)
		for _frame in range(20000):
			stage.set("elapsed_seconds", float(stage.get("elapsed_seconds")) + STEP)
			stage.call("_step_visual_fx", STEP)
			var frozen := float(stage.get("hit_stop_timer")) > 0.0
			stage.set("hit_stop_timer", maxf(0.0, float(stage.get("hit_stop_timer")) - STEP))
			stage.call("_step_fight", 0.0 if frozen else STEP)
			if int(stage.get("ko_count")) > 0:
				one_kill_fights += 1
				break
			if float(stage.get("hero_ko_timer")) > 0.0:
				break
	print("dragon-one-kill level=98 fights=%d/%d rate=%.1f%%" % [
		one_kill_fights,
		SAMPLES,
		100.0 * float(one_kill_fights) / float(SAMPLES),
	])
	assert(one_kill_fights >= 8 and one_kill_fights <= 12)
	stage.free()
	scene.free()
	quit(0)
