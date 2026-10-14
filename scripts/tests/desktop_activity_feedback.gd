extends "res://scripts/tests/desktop_layout_input.gd"

const SkillState = preload("res://scripts/progression/skill_state.gd")

func _process(delta: float) -> bool:
	super._process(delta)
	# Freezing simulation for rendered samples is not a real process suspension.
	if is_instance_valid(game) and game.startup_initialized and not game.is_processing():
		game._app_lifecycle_runtime().last_process_unix_time = game._unix_now()
		game._app_lifecycle_runtime().last_process_monotonic_msec = Time.get_ticks_msec()
	return false

func _run() -> void:
	create_timer(140).timeout.connect(func(): quit(1))
	OS.set_environment("IDLE_ELITE_DESKTOP", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "100")
	AudioServer.set_bus_mute(0, true)
	root.size = Vector2i(1920, 1080)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	for frame in range(1500):
		await settle(0.02)
		if game.startup_initialized and not game._boot_warmup_runtime().active: break
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._dismiss_blocking_tip()
	game._save_runtime().fishing_help_seen = true
	game.offline_progress_enabled = false
	game.auto_unlock_lockpads_enabled = false
	for id in game.skills:
		game.skills[id].xp = SkillState.xp_for_level(3)
		SkillState.recalculate_level(game, id, false)
		game.stamina[id] = 30
	for entry in [["fight", "kick-mud-off-boot"], ["thieving", "sneak-past-tip-jar"]]:
		game._activity_unlock_runtime()._mark_action_manually_unlocked(entry[0], entry[1])
	game.desktop_layout.rotate_slots("fishing")
	game.selected_skill_id = "fight"
	await game._navigation_shell()._render_screen()
	await settle(6)
	game.set_process(false)
	for entry in [["fight", "kick-mud-off-boot"], ["thieving", "sneak-past-tip-jar"]]:
		await check_progress(entry[0], entry[1])
	if OS.get_environment("IDLE_ELITE_PROGRESS_REPRO_ONLY") != "1":
		game.set_process(true)
		game.fishing_runtime.net_collected = true
		game.fishing_runtime.equipped_tool_id = "net"
		game.running_skill_id = ""
		game.running_action_id = ""
		game.desktop_layout.rotate_slots("fishing")
		game.desktop_layout.focus_column(0)
		await game._navigation_shell()._render_screen()
		await settle(2.5)
		var fishing = game._fishing_ui_surface()
		var method: Dictionary = fishing._fishing_method_card_for_action("fishing", "shallows")
		check(not method.is_empty(), "Shallows mounted in production desktop")
		if not method.is_empty():
			await click(method.method_image_hit_control.get_global_rect().get_center())
			check(game.running_action_id == "shallows", "Actual fishing location click starts fishing")
			await settle(0.8)
			await capture_desktop("fishing-net")
			check_fishing_layout(fishing._fishing_area_card_for_action("fishing", "shallows"))
			for progress in [0.15, 0.5, 0.85]:
				game.set_process(false)
				game.action_progress = progress
				game._update_ui(0.016, true)
				await capture_desktop("fishing-motion-" + str(progress))
			game.set_process(true)
			root.size = Vector2i(1080, 1920)
			await settle(1.5)
			game._navigation_shell()._select_skill("fishing")
			await settle(2)
			method = fishing._fishing_method_card_for_action("fishing", "shallows")
			if game.running_action_id != "shallows":
				await click(method.method_image_hit_control.get_global_rect().get_center())
			await settle(0.5)
			check(game.selected_skill_id == "fishing", "Portrait fishing reached")
			await capture_desktop("fishing-portrait")
			check_fishing_layout(fishing._fishing_area_card_for_action("fishing", "shallows"))
	print("DESKTOP_ACTIVITY_FEEDBACK failures=", JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func check_progress(skill: String, action: String) -> void:
	var card: Dictionary = game.action_cards.get(skill + ":" + action, {})
	check(not card.is_empty(), action + " mounted")
	if card.is_empty(): return
	await click(card.button.get_global_rect().get_center(), true)
	check(game.running_action_id == action, action + " starts through UI")
	var surface = game._skill_swipe_activity_surface()
	# Reproduce a cycle reset followed by an instant refresh, as on resume.
	game.action_progress = 0.96
	surface._update_action_card_run_feedback(card, skill, true, 0.016, true)
	game.action_progress = 0.01
	surface._update_action_card_run_feedback(card, skill, true, 0.016, false)
	game.action_progress = 0.50
	surface._update_action_card_run_feedback(card, skill, true, 0.0, true)
	var before := float(card.progress.value)
	await capture_desktop(action + "-before")
	game.action_progress = 0.51
	surface._update_action_card_run_feedback(card, skill, true, 0.016, false)
	var after := float(card.progress.value)
	print("PROGRESS_RESUME ", action, " before=", before, " after=", after)
	check(absf(before - 50.0) < 0.01, action + " instant refresh clears stale drain")
	check(after >= before, action + " increasing cycle never moves backward after refresh")
	await capture_desktop(action + "-transition")
	for frame in range(20):
		game.action_progress = 0.52 + frame * 0.02
		surface._update_action_card_run_feedback(card, skill, true, 0.016, false)
	await capture_desktop(action + "-settled")
	game.running_skill_id = ""
	game.running_action_id = ""

func check_fishing_layout(card: Dictionary) -> void:
	check(not card.is_empty(), "Fishing area remains mounted")
	if card.is_empty(): return
	check(card.active_tool_art.is_visible_in_tree() and card.stat_column.is_visible_in_tree(), "Fishing animation and stats are visible in capture")
	# Compare visible pixels, not the transparent corners of the authored draw box.
	# This is test-only geometry; it never changes animation scale or layout.
	var texture: Texture2D = card.active_tool_art.texture
	var pixels := texture.get_image()
	var source_size := Vector2(pixels.get_size())
	var draw_size: Vector2 = card.active_tool_art.size
	var draw_scale := minf(draw_size.x / source_size.x, draw_size.y / source_size.y)
	var used := Rect2(pixels.get_used_rect())
	var local_art := Rect2((draw_size - source_size * draw_scale) * 0.5 + used.position * draw_scale, used.size * draw_scale)
	var art: Rect2 = card.active_tool_art.get_global_transform() * local_art
	art = art.intersection(card.active_tool_layer.get_global_rect())
	var stats: Rect2 = card.stat_column.get_global_rect()
	var methods: Rect2 = card.method_row.get_global_rect()
	print("FISHING_LAYOUT art=", art, " methods=", methods, " stats=", stats)
	for column in card.method_row.get_children():
		for tile in column.get_children():
			if tile is Panel:
				check(not art.intersects(tile.get_global_rect().grow(10)), "Fishing tool clears visible location tile")
	check(not art.intersects(stats), "Fishing tool clears XP and fish boxes")
	check(stats.end.x <= game.size.x, "Fishing stats fit entirely inside viewport")
	check(card.stat_column.size.x < 256, "Fishing stat boxes use less width")
	check(card.area_xp.get_theme_font_size("font_size") >= 48, "Fishing stats retain mobile readability")

func capture_desktop(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	check(picture.get_size() == root.size, "Raw viewport capture dimensions")
	DirAccess.make_dir_recursive_absolute("res://.codex-tmp/desktop-feedback")
	picture.save_png("res://.codex-tmp/desktop-feedback/" + label + ".png")
