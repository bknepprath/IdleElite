extends "res://scripts/tests/desktop_layout_input.gd"

func _run() -> void:
	create_timer(90).timeout.connect(func(): quit(1))
	var desktop := OS.get_environment("IDLE_ELITE_STROKE_DESKTOP") == "1"
	OS.set_environment("IDLE_ELITE_DESKTOP", "1" if desktop else "0")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "100")
	AudioServer.set_bus_mute(0, true)
	root.size = Vector2i(1920, 1080) if desktop else Vector2i(1080, 1920)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	for i in range(1600):
		await settle(0.02)
		if game.startup_initialized and not game._boot_warmup_runtime().active: break
	check(game.startup_initialized, "Production scene boots")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	game._tutorial_overlay_surface()._dismiss_blocking_tip()
	game._onboarding_runtime().activity_start_tip_seen = true
	game.offline_progress_enabled = false
	for skill_id in game.skills:
		game.skills[skill_id].xp = 1500
		preload("res://scripts/progression/skill_state.gd").recalculate_level(game, skill_id)
	var achievements = preload("res://scripts/achievements/state.gd")
	achievements.mark_completed_seen_ids(achievements.milestones(game, false), game._save_runtime().achievement_toast_seen_ids, [])
	var toasts = game._achievement_toast_surface()
	toasts.achievement_toast_queue.clear()
	toasts.achievement_toast_queue_ids.clear()
	for toast in toasts.achievement_toasts:
		if is_instance_valid(toast): toast.queue_free()
	toasts.achievement_toasts.clear()

	game.leaderboard_profile.display_name = "Portrait test"
	await game._navigation_shell()._render_screen()
	await settle(2)
	var surface = game._profile_chat_overlay_surface()
	if desktop:
		await click(game.desktop_layout.ribbon_buttons.chat.get_global_rect().get_center())
	else:
		var strip: Control = surface.chat_strip_control()
		check(strip != null and strip.is_visible_in_tree(), "Chat strip visible")
		await click(strip.get_global_rect().get_center(), true)
	await settle(1)
	check(surface.chat_profile_button != null and surface.chat_profile_button.is_visible_in_tree(), "Profile entry visible")
	await click(surface.chat_profile_button.get_global_rect().get_center(), not desktop)
	await settle(1)
	var avatar_button := find_avatar_button(surface.profile_overlay)
	check(avatar_button != null, "Current avatar visible")
	if avatar_button == null:
		quit(1)
		return
	await click(avatar_button.get_global_rect().get_center(), not desktop)
	await settle(1)
	check(surface.profile_avatar_picker_open, "Picker opened through avatar")
	check(surface.profile_avatar_buttons.size() == preload("res://scripts/ui/profile_portrait_catalog.gd").COUNT, "All catalogue portraits selectable")
	await capture_portraits("desktop" if desktop else "mobile")
	for position in range(5):
		var expected: int = preload("res://scripts/ui/profile_portrait_catalog.gd").FEATURED_IDS[position]
		await click(surface.profile_avatar_buttons[position].get_global_rect().get_center(), not desktop)
		await settle(0.35)
		check(game.leaderboard_profile.avatar_index == expected, "New portrait selection " + str(expected))
		avatar_button = find_avatar_button(surface.profile_overlay)
		await click(avatar_button.get_global_rect().get_center(), not desktop)
		await settle(0.35)
	print("PROFILE_PORTRAITS failures=", JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func find_avatar_button(node: Node) -> Button:
	if node is Button and node.custom_minimum_size == Vector2(155,155):
		return node
	for child in node.get_children():
		var found := find_avatar_button(child)
		if found != null: return found
	return null

func find_button(node: Node, title: String) -> Button:
	if (node is Label or node is Button) and node.text == title:
		var parent := node
		while parent != null:
			if parent is Button: return parent
			parent = parent.get_parent()
	for child in node.get_children():
		var found := find_button(child, title)
		if found != null: return found
	return null

func capture_portraits(label: String) -> void:
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	check(picture.get_size() == root.size, "Raw viewport dimensions")
	picture.save_png("res://.codex-tmp/profile-portraits-v070/" + label + "-v2.png")
	print("CAPTURE ", label, " ", picture.get_size())
