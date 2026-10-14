extends SceneTree

var game: Node
var samples: Array = []

func _init() -> void:
	call_deferred("run")

func run() -> void:
	OS.set_environment("IDLE_ELITE_DESKTOP", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	AudioServer.set_bus_mute(0, true)
	root.size = Vector2i(1280, 720)
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
	game._tutorial_overlay_surface()._dismiss_blocking_tip()
	game.god_mode_save_tainted = true
	game.desktop_layout.skill_slots.assign(["woodcutting", "fishing", "build"])
	game.selected_skill_id = "woodcutting"
	game.current_screen = "skill"
	await game._navigation_shell()._render_screen()
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
			print("DESKTOP_SOAK ", JSON.stringify(sample))
			var file := FileAccess.open("res://.codex-tmp/desktop-v070/soak.json", FileAccess.WRITE)
			file.store_string(JSON.stringify(samples, "\t"))
			file.close()
			frame_times.clear()
			next_sample += 60000
			OS.delay_msec(1)
		if Time.get_ticks_msec() >= next_route:
			if route_index % 6 < 4:
				game.current_screen = "skill"
				await game.desktop_layout.set_social(["", "chat", "scores", ""][route_index % 6])
			else:
				await game.desktop_layout.set_social("")
				game.current_screen = "hub" if route_index % 6 == 4 else "settings"
				await game._navigation_shell()._render_screen()
			route_index += 1
			next_route += 15000
	print("desktop-soak: PASS (1800 seconds; offline CPU/node lifetime diagnostic)")
	var final_file := FileAccess.open("res://.codex-tmp/desktop-v070/soak-complete.txt", FileAccess.WRITE)
	final_file.store_string("PASS: 1800 seconds")
	final_file.close()
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	quit(0)
