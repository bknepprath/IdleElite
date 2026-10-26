extends "res://scripts/tests/first_session_input.gd"

func shot(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	check(picture.get_size() == Vector2i(1920, 1080), "Raw game viewport must be 1920x1080")
	DirAccess.make_dir_recursive_absolute("res://.codex-tmp/focus-reveal")
	picture.save_png("res://.codex-tmp/focus-reveal/" + label + ".png")

func reveal_amount(target: Control) -> float:
	if not target.has_meta("activity_reveal_cover"): return 1.0
	var cover = target.get_meta("activity_reveal_cover").get_ref()
	return cover.revealed if is_instance_valid(cover) else 1.0

func _run() -> void:
	create_timer(120).timeout.connect(func(): quit(1))
	OS.set_environment("IDLE_ELITE_DESKTOP", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "110")
	AudioServer.set_bus_mute(0, true)
	root.size = Vector2i(1920, 1080)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	for frame in range(1600):
		await settle(0.02)
		if game.startup_initialized and not game._boot_warmup_runtime().active: break
	await settle(0.5)
	check(game.startup_initialized, "Main scene boots")
	await shot("opening")
	var target: Control = game._tutorial_overlay_surface()._tutorial_target_control()
	await click(target.get_global_rect().get_center(), true)
	check(game.running_action_id == "push-ups", "Actual tutorial input starts Push-Ups")
	game._action_runtime()._stop_running_action("fight", "push-ups")
	game._tutorial_overlay_surface()._dismiss_blocking_tip()
	game._onboarding_runtime().onboarding_starter_action_completion_count = 1
	for i in range(100):
		await process_frame
		if game.desktop_layout.intro_stage == 1: break
	await shot("activity-before")
	await settle(0.17)
	await shot("activity-transition")
	await settle(0.6)
	await shot("activity-settled")
	game._onboarding_runtime().onboarding_starter_action_completion_count = 2
	for i in range(300):
		await process_frame
		if game.desktop_layout.columns.size() == 3 and not game.desktop_layout.rendering: break
	check(game.skills.fight.level == 1, "Other skills appear before Fighting level two")
	await shot("neighbors-before")
	await settle(0.17)
	var desktop = game.desktop_layout
	print("REVEAL first=", reveal_amount(desktop.columns[0].page), " second=", reveal_amount(desktop.columns[2].page), " time=", desktop.intro_reveal_elapsed)
	check(reveal_amount(desktop.columns[0].page) > 0 and reveal_amount(desktop.columns[0].page) < 1, "Fishing has a short intermediate reveal")
	check(reveal_amount(desktop.columns[2].page) == 0, "Thieving remains staggered")
	check(desktop.columns[0].page.modulate.a == 1, "Nested card layers stay opaque")
	# Hidden columns cannot start an activity through production input routing.
	var hidden_press := InputEventScreenTouch.new()
	hidden_press.pressed = true
	hidden_press.position = desktop.columns[2].page.get_global_rect().position + Vector2(100, 500)
	root.push_input(hidden_press, true)
	check(game.running_skill_id != "thieving", "Unrevealed skills cannot receive a tap")
	hidden_press.pressed = false
	root.push_input(hidden_press, true)
	await shot("neighbors-transition")
	await settle(1.04)
	await shot("thieving-transition")
	await settle(0.7)
	await shot("neighbors-settled")
	for column in desktop.columns:
		check(not column.page.has_meta("activity_reveal_cover"), "Finished reveals leave no cover")
		var bounds: Rect2 = column.page.get_global_rect()
		check(bounds.position.x >= -1 and bounds.end.x <= game.size.x + 1, "Every column fits inside the screen")
		if column.skill_id == "fight": check(absf(bounds.get_center().x - game.size.x * 0.5) < 2, "Fighting remains centered")
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	game._tutorial_overlay_surface()._dismiss_blocking_tip()
	var life = game._app_lifecycle_runtime()
	var summary = game._achievement_overlay_surface()
	game._action_runtime()._start_action("fight", "push-ups", false, false)
	for enabled in [false, true]:
		game.offline_progress_enabled = enabled
		var xp_before := int(game.skills.fight.xp)
		game.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		check(life.suspended_at_unix == -1, "Focus loss must not suspend desktop simulation")
		check(game._save_runtime().suspend_saved_at_unix == -1, "Focus checkpoint must not mark offline time")
		await settle(3.0)
		check(int(game.skills.fight.xp) > xp_before, "Training continues while unfocused, offline setting=" + str(enabled))
		var before_return := int(game.skills.fight.xp)
		var audio = game._audio_director()
		var music_position := -1.0
		if not audio.music_players.is_empty(): music_position = audio.music_players[0].get_playback_position()
		game.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
		await process_frame
		if music_position > 0.5: check(audio.music_players[0].get_playback_position() >= music_position, "Focus return keeps the current music position")
		check(int(game.skills.fight.xp) == before_return, "Focus return must not award duplicate offline XP")
		check(not (is_instance_valid(summary.offline_summary_overlay) and summary.offline_summary_overlay.visible), "Focus return must not open Welcome Back")
	var before_gap_xp := int(game.skills.fight.xp)
	# Measured processing gaps still consume time, without a modal for brief gaps.
	game._ad_bonus_runtime().seconds_remaining = 600
	life.last_process_unix_time = game._unix_now() - 12
	life.last_process_monotonic_msec = Time.get_ticks_msec() - 12000
	check(life.recover_suspended_process(), "A real process gap still resumes offline")
	check(int(game.skills.fight.xp) > before_gap_xp, "Real process gaps still award activity XP")
	check(game._ad_bonus_runtime().seconds_remaining <= 588, "Real gaps consume boost time")
	check(not (is_instance_valid(summary.offline_summary_overlay) and summary.offline_summary_overlay.visible), "Brief gaps do not interrupt play with Welcome Back")
	var boost_after: float = game._ad_bonus_runtime().seconds_remaining
	life._resume_from_app_suspend()
	check(game._ad_bonus_runtime().seconds_remaining == boost_after, "Duplicate resume never credits the same interval")
	game._action_runtime()._stop_running_action("fight", "push-ups")
	# A real platform pause remains distinct from a window focus notification.
	game.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(life.suspended_at_unix >= 0, "Platform pause records suspension")
	game.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	await settle(0.3)
	check(life.suspended_at_unix == -1, "Platform resume clears suspension")
	await shot("after-focus-cycles")
	game._action_runtime()._start_action("woodcutting", str(game.actions_by_skill.woodcutting[0].id), false, false)
	var before_long_gap := int(game.skills.woodcutting.xp)
	life.suspended_at_unix = game._unix_now() - 120
	life._resume_from_app_suspend()
	check(int(game.skills.woodcutting.xp) > before_long_gap, "Long offline absence still awards activity XP")
	check(is_instance_valid(summary.offline_summary_overlay) and summary.offline_summary_overlay.visible, "A genuine two-minute absence retains Welcome Back")
	var after_long_gap := int(game.skills.woodcutting.xp)
	life._resume_from_app_suspend()
	check(int(game.skills.woodcutting.xp) == after_long_gap, "Long offline interval is consumed only once")
	await settle(0.3)
	print("FOCUS_REVEAL failures=", JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
