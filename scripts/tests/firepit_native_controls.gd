extends "res://scripts/tests/first_session_input.gd"
const SkillState = preload("res://scripts/progression/skill_state.gd")
func _run() -> void:
	capture_dir = "res://.codex-tmp/firepit-audit"
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(1200):
		await settle(0.02)
		if game.startup_initialized and not game._boot_warmup_runtime().active:
			break
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	game.skills["woodcutting"]["xp"] = SkillState.xp_for_level(3)
	SkillState.recalculate_level(game, "woodcutting", false)
	game._activity_unlock_runtime().sync_manual_activity_unlocks_from_levels()
	game._activity_unlock_runtime()._mark_action_manually_unlocked("woodcutting", "firepit")
	game.material_runtime.set_amount("scrapwood", 6.0)
	game._navigation_shell()._select_skill("woodcutting")
	await settle(1.0)
	await game._skill_detail_surface()._restore_detail_actions_scroll(400)
	await settle(0.5)
	await capture("firepit-idle")
	var found := false
	for key in game.action_cards:
		var card = game.action_cards[key]
		if not card.get("firepit", false):
			continue
		found = true
		check(card.get("button") == null, "Firepit must not acquire a full-card activity overlay")
		await click(card.toggle.get_global_rect().get_center(), true)
		await settle(2.0)
		await capture("firepit-started")
		check(game._passive_modules_runtime().firepit_active(game._unix_now()), "Touch must ignite the firepit")
		check(game.material_runtime.amount("scrapwood") == 5.0, "Ignition must consume exactly one Scrapwood")
		await click(card.toggle.get_global_rect().get_center())
		check(game._passive_modules_runtime().firepit_active(game._unix_now()), "Short click must not extinguish the fire")
		var point: Vector2 = card.toggle.get_global_rect().get_center()
		var down := InputEventMouseButton.new()
		down.position = point
		down.global_position = point
		down.button_index = MOUSE_BUTTON_LEFT
		down.pressed = true
		root.push_input(down, true)
		await settle(2.0)
		var up = down.duplicate()
		up.pressed = false
		root.push_input(up, true)
		await settle(1.0)
		check(not game._passive_modules_runtime().firepit_active(game._unix_now()), "Completed hold and release must leave the fire extinguished")
		await capture("firepit-extinguished")
		game.material_runtime.set_amount("scrapwood", 0.0)
		await settle(0.5)
		check(not card.toggle.disabled, "Empty firepit must accept a tap for fuel requirement feedback")
		await click(card.toggle.get_global_rect().get_center(), true)
		check(not game._passive_modules_runtime().firepit_active(game._unix_now()), "Firepit must not light without fuel")
		break
	check(found, "Firepit must be present in the production Woodcutting page")
	print("FIREPIT_NATIVE failures=", failures)
	game.queue_free()
	await settle(0.5)
	quit(0 if failures.is_empty() else 1)
