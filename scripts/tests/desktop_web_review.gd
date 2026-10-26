extends SceneTree

var game: Node

func _init() -> void:
	call_deferred("run")

func report(value: Dictionary) -> void:
	print("DESKTOP_WEB_REVIEW ", JSON.stringify(value))
	if OS.has_feature("web"):
		JavaScriptBridge.eval("document.getElementById('qa-status').textContent = " + JSON.stringify(JSON.stringify(value)) + ";", true)

func run() -> void:
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	AudioServer.set_bus_mute(0, true)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	while not game.startup_initialized or game._boot_warmup_runtime().active:
		await process_frame
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	game.god_mode_save_tainted = true
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._dismiss_blocking_tip()
	game._save_runtime().fishing_help_seen = true
	for id in game.skills:
		game.skills[id].xp = 1500
		preload("res://scripts/progression/skill_state.gd").recalculate_level(game, id)
	game.desktop_layout.skill_slots.assign(["woodcutting", "fishing", "build"])
	game.selected_skill_id = "woodcutting"
	game.current_screen = "skill"
	await game._navigation_shell()._render_screen()
	game._action_runtime()._start_action("woodcutting", "gather-fallen-branches", false, false)
	var start := Time.get_ticks_msec()
	var sample_at := start
	var frames: Array[float] = []
	var previous := start
	while is_instance_valid(game):
		await process_frame
		var now := Time.get_ticks_msec()
		frames.append(float(now - previous))
		previous = now
		if now >= sample_at:
			frames.sort()
			var elapsed := (now - start) / 1000.0
			report({"seconds": elapsed, "muted": AudioServer.is_bus_mute(0), "screen": game.current_screen, "columns": game.desktop_layout.columns.size(), "nodes": get_node_count(), "orphans": Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), "memory": OS.get_static_memory_usage(), "p99_ms": frames[mini(frames.size() - 1, int(frames.size() * 0.99))], "max_ms": frames[-1], "running": game.running_skill_id, "complete": elapsed >= 1800})
			frames.clear()
			sample_at += 60000
			if elapsed >= 1800: break
