extends "res://scripts/tests/first_session_input.gd"

func reveal(control: Control) -> void:
	var detail = game._skill_detail_surface()
	var delta_y := control.get_global_rect().get_center().y - 820.0
	await detail._restore_detail_actions_scroll(maxi(0, detail.detail_actions_scroll.scroll_vertical + int(delta_y)))
	await settle(0.5)

func action_button(skill: String, action_id: String) -> Control:
	await game._skill_detail_surface()._scroll_to_activity_card(action_id, false)
	await settle(0.6)
	var card: Dictionary = game.action_cards.get(game._action_key(skill, action_id), {})
	return card.get("button") as Control

func _run() -> void:
	capture_dir = "res://.codex-tmp/three-minute-audit/high"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(1200):
		await settle(0.02)
		if game.startup_initialized and not game._boot_warmup_runtime().active: break
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._test_state_runtime()._god_mode_max_skills_state()
	game._test_state_runtime()._god_mode_unlock_actions_state()
	game._test_state_runtime()._god_mode_unlock_fishing_tools_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	game._navigation_shell()._select_skill("woodcutting")
	await settle(1.0)
	var button := await action_button("woodcutting", "prune-orchard-row")
	check(button != null, "Berry gathering card exists")
	await click(button.get_global_rect().get_center(), true)
	check(game.running_action_id == "prune-orchard-row", "Native berry gathering starts")
	var start := Time.get_ticks_msec()
	while game.material_runtime.amount("berries") < 3.0 and Time.get_ticks_msec() - start < 45000:
		await settle(1.0)
	print("BERRY_COLLECTED amount=", game.material_runtime.amount("berries"))
	check(game.material_runtime.amount("berries") >= 3.0, "Collect actual berries from completed actions")
	var berry_button: Control
	for candidate in get_nodes_in_group("berry_prep_buttons"):
		if candidate.is_visible_in_tree(): berry_button = candidate; break
	check(berry_button != null, "Collected berries expose native prep button")
	if berry_button != null:
		await reveal(berry_button)
		await capture("berries-collected")
		await click(berry_button.get_global_rect().get_center(), true)
		var surface = game._material_collection_surface()
		check(surface.berry_mode_enabled, "Native berry button enters assignment mode")
		button = await action_button("woodcutting", "gather-fallen-branches")
		await click(button.get_global_rect().get_center(), true)
		check(game.material_runtime.berry_prep_matches("woodcutting", "gather-fallen-branches", Callable(game, "_action_data"), Callable(game, "_action_key")), "Assign berries to a different task")
		await capture("berries-assigned")
		var leave: Button = surface._berry_mode_leave_button()
		await click(leave.get_global_rect().get_center(), true)
		check(not surface.berry_mode_enabled, "Native leave mode works")
		var berries_before: float = game.material_runtime.amount("berries")
		var xp_before: int = game.skills.woodcutting.xp
		await click(button.get_global_rect().get_center(), true)
		check(game.running_action_id == "gather-fallen-branches", "Assigned task starts normally")
		start = Time.get_ticks_msec()
		while game.material_runtime.amount("berries") >= berries_before and Time.get_ticks_msec() - start < 20000:
			await settle(0.1)
		print("BERRY_USED before=", berries_before, " after=", game.material_runtime.amount("berries"), " xp_delta=", game.skills.woodcutting.xp-xp_before, " result=", game.last_result)
		check(game.material_runtime.amount("berries") < berries_before, "Different task consumes collected berries")
		check(game.skills.woodcutting.xp - xp_before == 2, "Berry doubles base 1 XP reward")
		await capture("berries-used")
	game._navigation_shell()._select_skill("fishing")
	await settle(1.0)
	var fishing = game._fishing_ui_surface()
	var detail = game._skill_detail_surface()
	var areas: Array = fishing.render_area_modules("fishing").duplicate(true)
	var tested := 0
	for area in areas:
		var ids: Array = fishing.area_module_method_ids("fishing", area)
		for id in ids:
			for entry in detail.detail_lazy_plan:
				if entry.get("kind") == "fishing_area" and entry.get("area_def", {}) == area:
					await detail._restore_detail_actions_scroll(int(entry.y))
					break
			await settle(0.7)
			var card: Dictionary = fishing._fishing_method_card_for_action("fishing", str(id))
			check(not card.is_empty(), "Fishing location mounted: " + str(id))
			if card.is_empty(): continue
			var target: Control = card.get("method_button")
			await reveal(target)
			await click(target.get_global_rect().get_center(), true)
			await settle(0.5)
			print("FISHING_TAP expected=", id, " running=", game.running_action_id, " result=", game.last_result)
			check(game.running_skill_id == "fishing" and game.running_action_id == str(id), "Fishing native location starts: " + str(id))
			tested += 1
			await settle(3.0)
			await capture("fishing-" + str(id))
	print("FISHING_LOCATIONS_TESTED ", tested)
	print("HIGH_AUDIT failures=", failures)
	game.queue_free()
	await settle(1.0)
	quit(0 if failures.is_empty() else 1)


