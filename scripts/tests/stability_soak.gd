extends SceneTree

var game: Node
var samples: Array = []

func _init() -> void:
	call_deferred("run")

func run() -> void:
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "2000")
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	var boot_deadline := Time.get_ticks_msec() + 90000
	while Time.get_ticks_msec() < boot_deadline:
		await process_frame
		if game.startup_initialized and not game._boot_warmup_runtime().active:
			break
	if not game.startup_initialized:
		push_error("Soak boot failed")
		quit(1)
		return
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._test_state_runtime()._god_mode_max_skills_state()
	game._test_state_runtime()._god_mode_unlock_actions_state()
	game._action_runtime()._start_action("woodcutting", str(game.actions_by_skill.woodcutting[0].id), false, false)
	Engine.max_fps = 60
	var started := Time.get_ticks_msec()
	var next_route := started
	var next_sample := started
	var route_index := 0
	var frame_times: Array[int] = []
	var previous := Time.get_ticks_usec()
	while Time.get_ticks_msec() - started < 1800000:
		await process_frame
		var now := Time.get_ticks_usec()
		frame_times.append(now - previous)
		previous = now
		if Time.get_ticks_msec() >= next_sample:
			frame_times.sort()
			var sample := {"elapsed_seconds": (Time.get_ticks_msec() - started) / 1000.0, "nodes": get_node_count(), "objects": Performance.get_monitor(Performance.OBJECT_COUNT), "orphan_nodes": Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), "memory_bytes": OS.get_static_memory_usage(), "tweens": get_processed_tweens().size(), "p99_frame_us": frame_times[mini(frame_times.size() - 1, int(frame_times.size() * 0.99))], "max_frame_us": frame_times[-1]}
			samples.append(sample)
			print("STABILITY_SOAK ", JSON.stringify(sample))
			var file := FileAccess.open("res://.codex-tmp/stability-soak.json", FileAccess.WRITE)
			file.store_string(JSON.stringify(samples, "\t"))
			file.close()
			frame_times.clear()
			next_sample += 60000
		if Time.get_ticks_msec() >= next_route:
			var routes := ["menu", "hub", "shop", "achievements", "settings", "skill"]
			game.current_screen = routes[route_index % routes.size()]
			game.selected_skill_id = ["fight", "woodcutting", "fishing", "build", "thieving"][route_index % 5]
			await game._navigation_shell()._render_screen(false, -1, false)
			route_index += 1
			next_route += 10000
	print("stability-soak: PASS (1800 seconds; offline CPU/node lifetime diagnostic)")
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	quit(0)
