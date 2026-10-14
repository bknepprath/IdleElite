extends "res://scripts/tests/first_session_input.gd"
const SkillState = preload("res://scripts/progression/skill_state.gd")
func _run() -> void:
	capture_dir = "res://.codex-tmp/release-audit"
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	for i in range(1200):
		await settle(0.02)
		if game.startup_initialized and not game._boot_warmup_runtime().active:
			break
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	for skill_id in ["woodcutting", "fight"]:
		game._navigation_shell()._select_skill(skill_id)
		await settle(1.5)
		var zones = game.find_children("*", "Control", true, false)
		for zone in zones:
			if str(zone.get_meta("module_action_kind", "")) == "pin" and zone.is_visible_in_tree() and zone.get_global_rect().get_center().y > 430 and zone.get_global_rect().get_center().y < 1300:
				print("PIN_TARGET ", zone.get_global_rect(), " ", zone.get_meta("module_ui_key"))
				await capture("pin-before-" + skill_id)
				await click(zone.get_global_rect().get_center())
				await settle(1.0)
				await capture("pin-settled-" + skill_id)
				break
	print("PIN_ORDER ", game.module_ui_runtime.pinned_order)
	await click(game._navigation_shell().pinned_utility_tab.get_global_rect().get_center())
	await settle(1.5)
	await capture("pin-page")
	check(game.module_ui_runtime.pinned_order.size() == 2, "Two native pin taps must pin both activities")
	var badge = game._skill_detail_surface()._visible_module_pin_badge_for_key("action:fight:push-ups")
	check(badge != null, "Pinned activity must expose its unpin button")
	if badge != null:
		var seam = game._skill_detail_surface()._module_pin_entry_seam(badge)
		var clip = game._skill_detail_surface()._module_pin_badge_clip_host(badge)
		check(seam != null and clip != null, "Pin must expose entry seam and clipping boundary")
		if seam != null and clip != null:
			for point in seam.points:
				check(absf((seam.global_transform * point).y - clip.get_global_rect().end.y) < 1.0, "Pin seam must meet the needle clipping boundary")
		await click(badge.get_global_rect().get_center(), true)
		await settle(1.0)
		check(not game.module_ui_runtime.pinned_order.has("action:fight:push-ups"), "Touch on pin must remove activity")
		check(game._skill_detail_surface()._visible_module_pin_badges_for_key("action:fight:push-ups").is_empty(), "Unpinned card must disappear from the pinned page")
		await capture("pin-removed")
	print("PIN_NATIVE failures=", failures)
	game.queue_free()
	await settle(0.5)
	quit(0 if failures.is_empty() else 1)

