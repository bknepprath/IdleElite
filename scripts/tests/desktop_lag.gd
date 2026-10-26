extends "res://scripts/tests/desktop_responsive.gd"

var metrics: Array = []

func _run() -> void:
	create_timer(160).timeout.connect(func(): quit(1))
	OS.set_environment("IDLE_ELITE_DESKTOP", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "150")
	AudioServer.set_bus_mute(0, true)
	root.borderless = true
	root.position = Vector2i.ZERO
	root.size = Vector2i(1920, 1080)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	while not game.startup_initialized or game._boot_warmup_runtime().active: await process_frame
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._test_state_runtime()._god_mode_max_skills_state()
	game._test_state_runtime()._god_mode_unlock_actions_state()
	for achievement in preload("res://scripts/achievements/state.gd").milestones(game, false):
		game._save_runtime().achievement_toast_seen_ids[str(achievement.id)] = true
	game._tutorial_overlay_surface()._dismiss_blocking_tip()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	game.activity_crit_seen = true
	game.activity_mega_crit_seen = true
	game.auto_unlock_lockpads_enabled = false
	game.desktop_layout.restore_preferences({})
	game.desktop_layout.rotate_slots("woodcutting")
	game.selected_skill_id = "fishing"
	await game._navigation_shell()._render_screen()
	await wait_layout()
	await settle(2)
	Engine.max_fps = 120
	var fish: Dictionary = game._fishing_ui_surface()._fishing_method_card_for_action("fishing", "shallows")
	check(not fish.is_empty(), "Fishing activity is mounted in the real desktop scene")
	if not fish.is_empty() and is_instance_valid(fish.get("method_button")):
		await click(fish.method_button.get_global_rect().get_center())
	check(game.running_skill_id == "fishing", "Actual location click starts fishing")
	await settle(1)
	await capture_lag("before")
	await measure("idle", 4.0)
	await measure("scroll", 8.0)
	await settle(0.8)
	await capture_lag("settled")
	await click_navigation(1)
	await measure("navigation", 3.0)
	await click_navigation(-1)
	await measure("return", 3.0)
	await settle(0.4)
	check(game.desktop_layout.columns.size() == 3, "All three desktop columns remain mounted")
	var output := FileAccess.open("res://.codex-tmp/desktop-lag/metrics.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(metrics, "\t"))
	output.close()
	print("desktop-lag-audit-ok" if failures.is_empty() else "desktop-lag-audit-failed")
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)

func capture_lag(label: String) -> void:
	DirAccess.make_dir_recursive_absolute("res://.codex-tmp/desktop-lag")
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	check(picture.get_size() == Vector2i(1920, 1080), "Unmodified viewport capture is 1920x1080")
	picture.save_png("res://.codex-tmp/desktop-lag/" + label + ".png")

func measure(label: String, seconds: float) -> void:
	var started := Time.get_ticks_usec()
	var previous := started
	var next_wheel := 0.0
	var wall: Array[int] = []
	var captured := false
	while float(Time.get_ticks_usec() - started) < seconds * 1000000:
		await process_frame
		var now := Time.get_ticks_usec()
		wall.append(now - previous)
		previous = now
		var elapsed := float(now - started) / 1000000.0
		if label == "scroll" and elapsed >= next_wheel:
			var column: Dictionary = game.desktop_layout.columns[1]
			var scroll = column.context.detail_actions_scroll
			var event := InputEventMouseButton.new()
			event.position = scroll.get_global_rect().get_center()
			event.global_position = event.position
			event.button_index = MOUSE_BUTTON_WHEEL_DOWN if elapsed < seconds * 0.5 else MOUSE_BUTTON_WHEEL_UP
			event.pressed = true
			event.factor = 1.0
			root.push_input(event, true)
			next_wheel += 0.09
			if not captured and elapsed > 2.0:
				await capture_lag("scrolling")
				previous = Time.get_ticks_usec()
				captured = true
	wall.sort()
	var sample := {"stage": label, "frames": wall.size(), "wall_p50_us": wall[wall.size() / 2], "wall_p99_us": wall[mini(wall.size()-1, int(wall.size()*0.99))], "wall_max_us": wall[-1], "nodes": get_node_count(), "objects": Performance.get_monitor(Performance.OBJECT_COUNT)}
	metrics.append(sample)
	print("DESKTOP_LAG ", JSON.stringify(sample))
