extends "res://scripts/tests/first_session_input.gd"
const SkillState = preload("res://scripts/progression/skill_state.gd")

func shot(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	check(picture.get_size() == root.size, "Raw viewport dimensions")
	DirAccess.make_dir_recursive_absolute("res://.codex-tmp/progress-motion")
	picture.save_png("res://.codex-tmp/progress-motion/" + label + ".png")

func tap(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	for down in [true, false]:
		var e := InputEventScreenTouch.new()
		e.position = point
		e.pressed = down
		root.push_input(e, true)
		await process_frame

func _run() -> void:
	create_timer(130).timeout.connect(func(): quit(1))
	OS.set_environment("IDLE_ELITE_DESKTOP", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "120")
	AudioServer.set_bus_mute(0, true)
	root.size = Vector2i(1920, 1080)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	for frame in range(1600):
		await settle(0.02)
		if game.startup_initialized and not game._boot_warmup_runtime().active: break
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	game._tutorial_overlay_surface()._dismiss_blocking_tip()
	game.auto_unlock_lockpads_enabled = false
	game.desktop_layout.restore_preferences({})
	game.desktop_layout.rotate_slots("fishing")
	game.selected_skill_id = "fight"
	game.skills.fight.xp = 11
	SkillState.recalculate_level(game, "fight", false)
	await game._navigation_shell()._render_screen()
	await settle(2)
	var next_card: Dictionary = game.action_cards["fight:kick-mud-off-boot"]
	var cluster = next_card.lock_overlay.group
	check(is_equal_approx(cluster.rigs[0].unlock_progress.target_value, 50.0), "Level-two padlock matches 11/22 XP")
	await shot("lock-half-desktop")
	var combo := {"id": "test-combo", "unlock": 2, "requirements": [{"skill": "fight", "level": 2}, {"skill": "thieving", "level": 2}]}
	var combo_states: Array = game._activity_unlock_runtime()._action_requirement_states("fight", combo)
	check(combo_states[0].xp_progress == 0.5 and combo_states[1].xp_progress == 0.0, "Combo locks track each required skill independently")
	var first: Dictionary = game.action_cards["fight:push-ups"]
	var cookie_id := str(game.actions_by_skill.thieving[0].id)
	var second: Dictionary = game.action_cards["thieving:" + cookie_id]
	await tap(first.button)
	check(game.running_action_id == "push-ups", "Start Fighting through actual UI")
	game.action_progress = 0.55
	game._update_ui(0.0, true)
	await shot("switch-before")
	await tap(second.button)
	check(game.running_skill_id == "thieving", "Switch to Thieving through actual UI")
	var previous: float = first.progress.value
	var changes := 0
	var max_step := 0.0
	var deadline := Time.get_ticks_msec() + 1000
	var captured := false
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var value: float = first.progress.value
		if value < previous - 0.001: changes += 1
		max_step = maxf(max_step, previous - value)
		check(value <= previous + 0.05, "Stopped bar never jumps upward")
		previous = value
		if not captured and value < 38:
			await shot("switch-transition")
			captured = true
	print("DRAIN changes=", changes, " max_step=", max_step)
	check(changes >= 20, "Stopped bar updates every render frame, not twice a second")
	check(max_step < 5.0, "Stopped bar has no chunky drain jumps")
	await settle(1.5)
	check(first.progress.value == 0, "Drain reaches zero and stops")
	await shot("switch-settled")
	game.stamina.thieving = 0.0
	SkillState.host_sync_stamina_bank("thieving", game)
	game.action_progress = 0.1
	game._update_ui(0.0, true)
	# Move the pointer back over Fighting while Thieving trains tired.
	var motion := InputEventMouseMotion.new()
	motion.position = first.root.get_global_rect().get_center()
	root.push_input(motion, true)
	await process_frame
	check(game.selected_skill_id == "fight", "Another desktop column has focus")
	await shot("tired-before")
	previous = second.progress.value
	changes = 0
	deadline = Time.get_ticks_msec() + 900
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var value: float = second.progress.value
		if value > previous + 0.001: changes += 1
		previous = value
	print("TIRED changes=", changes)
	check(changes >= 20, "Unfocused tired activity animates every frame")
	await shot("tired-transition")
	game._action_runtime()._stop_running_action("thieving", cookie_id)
	await settle(2)
	await shot("tired-settled")
	# The progress control stays inside the original padlock on portrait too.
	root.size = Vector2i(1080, 1920)
	await settle(1.5)
	game._navigation_shell()._select_skill("fight")
	await settle(1)
	await shot("lock-half-portrait")
	game.skills.fight.xp = SkillState.xp_for_level(2)
	SkillState.recalculate_level(game, "fight", false)
	game._update_ui(0.0, true)
	await settle(0.7)
	await shot("lock-complete-portrait")
	var states: Array = game._activity_unlock_runtime()._action_requirement_states("fight", game._action_data("fight", "kick-mud-off-boot"))
	check(states[0].xp_progress == 1.0 and states[0].met, "XP requirement reaches exactly 100 percent")
	print("PROGRESS_MOTION failures=", JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
