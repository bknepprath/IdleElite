extends "res://scripts/tests/first_session_input.gd"

func _run() -> void:
	create_timer(170).timeout.connect(func(): quit(1))
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "120")
	capture_dir = "res://.codex-tmp/welcome-layout"
	DirAccess.make_dir_recursive_absolute(capture_dir)
	root.size = Vector2i(1080, 1920)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	for i in range(1600):
		await settle(0.02)
		if game.startup_initialized and not game._boot_warmup_runtime().active:
			break
	check(game.startup_initialized, "Main scene boots")
	game._audio_director().music_muted = true
	game._audio_director().sfx_muted = true
	game._audio_director()._apply_audio_bus_volumes()
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	await settle(1.0)
	var surface = game._achievement_overlay_surface()
	var action: Dictionary = game._action_data("woodcutting", "clear-the-infinite-lumberyard")
	var result := {
		"handled": true, "skill_id": "woodcutting", "skill_name": "Woodcutting",
		"action_name": action.name, "action_art": action.art, "xp": 12345678,
		"successes": 12000, "completions": 18000,
		"old_skill_level": 9, "new_skill_level": 99,
		"old_global_level": 99, "new_global_level": 120,
		"old_mastery_level": 0, "new_mastery_level": 5,
		"unlocked_actions": [{"art": action.art}, {"art": action.art}]
	}
	for scenario in ["full", "short", "full-again"]:
		var data: Dictionary = result.duplicate(true)
		if scenario == "short":
			data.merge({"action_name": "Oak", "xp": 35, "successes": 3, "completions": 5, "new_skill_level": 9, "new_global_level": 99, "new_mastery_level": 0, "unlocked_actions": []}, true)
		surface._maybe_show_offline_summary(28800.0, data)
		await settle(1.2)
		var panel: Control = surface.offline_summary_panel
		var frame: Control = surface.offline_summary_panel_frame
		var bounds := panel.get_global_rect()
		print("WELCOME ", scenario, " panel=", bounds, " frame=", frame.get_global_rect(), " minimum=", panel.get_combined_minimum_size())
		check(bounds.position.x >= 30 and bounds.end.x <= 1050, scenario + ": panel fits horizontally")
		check(bounds.position.y >= 40 and bounds.end.y <= 1880, scenario + ": panel fits vertically")
		check(bounds.size.is_equal_approx(frame.size), scenario + ": centering frame matches actual panel")
		check(absf(bounds.get_center().y - 960.0) <= 1.0, scenario + ": panel remains centered")
		check(bounds.size.y < (900.0 if scenario == "short" else 1400.0), scenario + ": no unnecessary height")
		check(bounds.encloses(surface.offline_summary_close_button.get_global_rect()), scenario + ": close button fits inside panel")
		await capture(scenario)
		var done: Control = surface.offline_summary_stack.get_child(surface.offline_summary_stack.get_child_count() - 1)
		check(bounds.encloses(done.get_global_rect()), scenario + ": bottom button stays inside panel")
		await click(done.get_global_rect().get_center())
		check(not surface.offline_summary_overlay.visible, scenario + ": bottom button closes welcome")
	# A later text measurement must update the centering frame too.
	surface._maybe_show_offline_summary(28800.0, result)
	await settle(0.4)
	var copy: VBoxContainer = surface.offline_summary_stack.get_child(1).get_child(0).get_child(1)
	var title: Label = copy.get_child(1)
	title.text = "Clear The Infinite Lumberyard\nClear The Infinite Lumberyard"
	await settle(0.4)
	check(surface.offline_summary_panel.get_global_rect().size.is_equal_approx(surface.offline_summary_panel_frame.size), "Late text wrapping refits the panel")
	check(surface.offline_summary_panel.get_global_rect().end.y < 1880, "Late text wrapping stays on screen")
	await click(surface.offline_summary_close_button.get_global_rect().get_center(), true)
	check(not surface.offline_summary_overlay.visible, "Close button works with touch")
	print("welcome-layout failures=", failures)
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
