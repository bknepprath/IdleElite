extends "res://scripts/tests/startup_ribbon.gd"

func _run() -> void:
	create_timer(120).timeout.connect(func(): quit(1))
	run_label = OS.get_environment("IDLE_ELITE_AUDIT_LABEL")
	if run_label.is_empty(): run_label = "returning-baseline"
	capture_dir = "res://.codex-tmp/audit-2026-10-14/" + run_label
	DirAccess.make_dir_recursive_absolute(capture_dir)
	OS.set_environment("IDLE_ELITE_DESKTOP", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	AudioServer.set_bus_mute(0, true)
	root.borderless = true
	root.size = Vector2i(1920,1080)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	while not game.startup_initialized or not game.desktop_layout.ready or game.desktop_layout.rendering:
		await process_frame
	await settle(1)
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game.desktop_layout.restore_preferences({})
	game.desktop_layout.rotate_slots("woodcutting")
	game.desktop_layout.focused_index = 0
	game.selected_skill_id = "woodcutting"
	for id in game.skills:
		game.skills[id].xp = preload("res://scripts/progression/skill_state.gd").xp_for_level(35)
		preload("res://scripts/progression/skill_state.gd").recalculate_level(game, id, false)
	game._test_state_runtime()._god_mode_unlock_actions_state()
	await game._navigation_shell()._render_screen()
	await settle(1)
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "0")
	check(game.save_game(), "Isolated returning-player fixture is saved")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	await process_frame
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	var settled_frames := 0
	var first_mounted := false
	var ribbon_disappearances := 0
	for frame in range(3000):
		await process_frame
		await RenderingServer.frame_post_draw
		var boot = game._boot_warmup_runtime()
		var covered: bool = is_instance_valid(boot.overlay) and boot.overlay.visible and boot.overlay.modulate.a >= 0.999
		var desktop = game.desktop_layout
		var mounted: bool = desktop.ready and not desktop.rendering and not game._navigation_shell().screen_render_in_progress and desktop.columns.size() == desktop.page_count()
		if not covered and game.startup_initialized:
			if not mounted:
				exposed_incomplete += 1
				if exposed_incomplete == 1: save_frame("returning-incomplete")
			var nav = game._navigation_shell()
			if is_instance_valid(nav.nav_bar) and nav.nav_bar.is_visible_in_tree(): premature_ribbon += 1
			var showing: bool = is_instance_valid(desktop.toolbar) and desktop.toolbar.is_visible_in_tree()
			if first_mounted and not showing: ribbon_disappearances += 1
			first_mounted = first_mounted or showing
		if not boot.active and mounted:
			settled_frames += 1
			if settled_frames == 1: save_frame("returning-revealed")
			if settled_frames >= 60: break
	check(not game._onboarding_runtime().tutorial_active, "Returning fixture restored")
	check(exposed_incomplete == 0, "Returning boot never exposes partially constructed columns")
	check(premature_ribbon == 0, "Returning boot never flashes the portrait ribbon")
	check(ribbon_disappearances == 0, "Returning ribbon remains visible after first reveal")
	await capture("returning-settled")
	print("STARTUP_RETURNING ", JSON.stringify({"exposed_incomplete_frames": exposed_incomplete, "portrait_ribbon_frames": premature_ribbon, "ribbon_disappearances": ribbon_disappearances, "failures": failures}))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
