extends "res://scripts/tests/desktop_responsive.gd"

func _run() -> void:
	create_timer(70).timeout.connect(func(): quit(1))
	OS.set_environment("IDLE_ELITE_DESKTOP", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "65")
	AudioServer.set_bus_mute(0, true)
	root.borderless = true
	root.size = Vector2i(1920, 1080)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	while not game.startup_initialized or game._boot_warmup_runtime().active: await process_frame
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._dismiss_blocking_tip()
	game.desktop_layout.restore_preferences({})
	for skill in game.skills:
		game.skills[skill].xp = 1500
		SkillState.recalculate_level(game, skill, false)
	await game._navigation_shell()._render_screen()
	await settle(1.0)
	await click(game.desktop_layout.ribbon_buttons.chat.get_global_rect().get_center())
	await settle(1.0)
	var surface = game._profile_chat_overlay_surface()
	var button: Button = surface.chat_profile_button
	check(is_instance_valid(button), "Profile button is present in the actual chat panel")
	if not is_instance_valid(button):
		print("MODAL_MOTION failures=", JSON.stringify(failures))
		quit(1)
		return
	var ancestor := button.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer: ancestor.ensure_control_visible(button)
		ancestor = ancestor.get_parent()
	await settle(0.3)
	await click(button.get_global_rect().get_center())
	await settle(0.5)
	var overlay: Control = surface.profile_overlay
	check(is_instance_valid(overlay) and overlay.is_visible_in_tree(), "Actual click opens the production profile modal")
	await capture_responsive("modal-motion-before")
	var lifecycle = game._app_lifecycle_runtime()
	# Rapid close/reopen/close requests exercise the shared production visibility
	# path after reaching this modal through its actual button.
	lifecycle.set_canvas_item_visible_if_changed(overlay, false)
	await settle(0.05)
	lifecycle.set_canvas_item_visible_if_changed(overlay, true)
	await settle(0.05)
	lifecycle.set_canvas_item_visible_if_changed(overlay, false)
	var previous_alpha := overlay.modulate.a
	var close_started := Time.get_ticks_msec()
	var premature_hide := 0
	var alpha_reversals := 0
	var transition_saved := false
	while overlay.visible:
		await process_frame
		await RenderingServer.frame_post_draw
		if overlay.visible:
			if overlay.modulate.a > previous_alpha + 0.001: alpha_reversals += 1
			previous_alpha = overlay.modulate.a
			if not transition_saved and previous_alpha < 0.65:
				root.get_texture().get_image().save_png("res://.codex-tmp/desktop-responsive/modal-motion-transition.png")
				transition_saved = true
		elif Time.get_ticks_msec() - close_started < int(game.desktop_layout.CLOSE_SECONDS * 1000) - 30:
			premature_hide += 1
	check(premature_hide == 0, "An interrupted close cannot hide a newer animation early")
	check(alpha_reversals == 0, "Closing opacity decreases without a reset")
	check(transition_saved, "Closing animation has a rendered intermediate frame")
	await capture_responsive("modal-motion-settled")
	# The next open must remain visible after every canceled close would have ended.
	lifecycle.set_canvas_item_visible_if_changed(overlay, true)
	await settle(0.45)
	check(overlay.visible and overlay.modulate.a > 0.99, "Reopening remains visible after canceled closes")
	print("MODAL_MOTION ", JSON.stringify({"premature_hide":premature_hide,"alpha_reversals":alpha_reversals}), " failures=", JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
