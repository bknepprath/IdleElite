extends "res://scripts/tests/desktop_responsive.gd"

func _run() -> void:
	create_timer(260).timeout.connect(func(): quit(1))
	OS.set_environment("IDLE_ELITE_DESKTOP", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "255")
	AudioServer.set_bus_mute(0, true)
	Desktop.fit_startup_window(root)
	await settle(0.15)
	var usable := DisplayServer.screen_get_usable_rect(root.current_screen)
	check(usable.encloses(Rect2i(root.get_position_with_decorations(), root.get_size_with_decorations())), "Actual initial decorated window fits monitor work area")
	print("WINDOW_FIT usable=", usable, " decorated=", Rect2i(root.get_position_with_decorations(), root.get_size_with_decorations()))
	root.borderless = true
	# The corner of the monitor the test was started on: the primary one, at 0,0,
	# unless --position or --screen put the window elsewhere.
	root.position = DisplayServer.screen_get_position(root.current_screen)
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
	game._save_runtime().achievement_toast_seen_ids["activity-crit"] = true
	game._save_runtime().achievement_toast_seen_ids["activity-mega-crit"] = true
	game.activity_crit_seen = true
	game.activity_mega_crit_seen = true
	game.desktop_layout.restore_preferences({})
	game.desktop_layout.rotate_slots("fight")
	game.selected_skill_id = "fight"
	await game._navigation_shell()._render_screen()
	await wait_layout()
	var runtime = game._activity_unlock_runtime()
	var projects = game._project_runtime()
	game.auto_unlock_lockpads_enabled = false
	for skill in game.skills:
		game.skills[skill].xp = SkillState.xp_for_level(5) + 15
		SkillState.recalculate_level(game, skill, false)
		for action in game.actions_by_skill[skill]:
			if int(action.unlock) < 6: runtime._mark_action_manually_unlocked(skill, str(action.id))
	projects.clear()
	var shack: Dictionary = game._action_data("build", "repair-small-shack")
	var bridge: Dictionary = game._action_data("build", "build-bridge-over-tiny-puddle")
	var best: Dictionary = projects.best_source("plans")
	check(not best.is_empty() and str(best.action.id) == "split-firewood", "Best Plans producer can belong to another skill")
	projects.record_success("build", "patch-fence", 3)
	check(projects.amount("build-repair-small-shack", "step-1") == 6, "Three Building completions award six resource units")
	var partial: Dictionary = projects.for_save()
	projects.restore({"activity_projects": partial})
	check(projects.amount("build-repair-small-shack", "step-1") == 6, "Resource progress survives restore")
	projects.record_success("build", "saw-planks", 1)
	check(projects.complete(shack), "Higher yield completes the first blocker")
	check(projects.amount("build-roof-the-roofless", "step-1") == 0, "Surplus cannot prefill an unrevealed blocker")
	check(preload("res://scripts/progression/project_runtime.gd").regresses(projects.for_save(), partial), "Cloud rejects losing resource progress")
	game.material_runtime.set_amount("softwood", 8)
	check(not projects.commit(bridge) and game.material_runtime.amount("softwood") == 8, "Unlock blockers never spend inventory")
	projects.restore({"activity_projects": {"version": 1, "work": {"build-build-bridge-over-tiny-puddle": {"step-1": 12, "materials": 1}}}})
	check(projects.amount("build-build-bridge-over-tiny-puddle", "step-1") == 12 and projects.amount("build-build-bridge-over-tiny-puddle", "materials") == 1, "Legacy work and payment credit survive migration")
	projects.clear()
	var source: Dictionary = game._action_data("build", "patch-fence").duplicate(true)
	source.success = 100.0
	game._action_runtime()._grant_offline_action_completion("build", "patch-fence", source)
	check(projects.amount("build-repair-small-shack", "step-1") == 2, "Offline completion awards its doubled resource yield exactly once")
	projects.clear()
	projects.record_success("build", "saw-planks", 50)
	var total := 0
	for entry in projects.resource_targets.plans: total += projects.amount(str(entry.project), str(entry.step.id))
	check(total == 8, "Batch rewards stop when revealed demand is filled")
	projects.restore({"activity_projects": {"work": {"build-repair-small-shack": {"step-1": -12}, "unknown": {"step-1": 999}}}})
	check(projects.amount("build-repair-small-shack", "step-1") == 0 and not projects.work.has("unknown"), "Malformed counters remain bounded")
	projects.clear()
	game.desktop_layout.rotate_slots("thieving")
	game.selected_skill_id = "build"
	await game._navigation_shell()._render_screen()
	await wait_layout()
	var panel = await show_project()
	check(is_instance_valid(panel) and panel.blockers.has("plans"), "Compact resource blocker mounts")
	if is_instance_valid(panel):
		await capture_responsive("resources-blocker-before")
		projects.record_success("build", "saw-planks", 1)
		await settle(0.12)
		await capture_responsive("resources-blocker-transition")
		await settle(0.45)
		check(is_equal_approx(panel.blockers.plans.progress.target_value, 50.0), "Curved blocker reflects resource units without count text")
		await capture_responsive("resources-blocker-half")
		await double_click(panel.blockers.plans.get_global_rect().get_center())
		await wait_layout()
		await settle(0.6)
		# The source can be mounted below the viewport in a neighboring desktop
		# column. Bring the real source into view before testing a physical tap.
		for index in range(game.desktop_layout.columns.size()):
			if game.desktop_layout.columns[index].skill_id == str(best.skill):
				game.desktop_layout.focus_column(index)
		await game._skill_detail_surface()._scroll_to_activity_card(str(best.action.id), false, true)
		await wait_layout()
		var card: Dictionary = game.action_cards.get(game._action_key(str(best.skill), str(best.action.id)), {})
		check(not card.is_empty(), "Actual blocker click reaches best source")
		if not card.is_empty():
			check(card.art_panel.has_node("UnlockResourceBadge"), "Portrait has dedicated unlock drop badge")
			await capture_responsive("resources-source-desktop")
			await physical_press(card.art_panel.get_global_rect().get_center(), 0.12)
			check(game.running_action_id == str(best.action.id), "Source starts through actual UI")
			for frame in range(400):
				await settle(0.02)
				if projects.amount("build-repair-small-shack", "step-1") > 4: break
			await settle(0.25)
			await capture_responsive("resources-transfer")
			check(projects.amount("build-repair-small-shack", "step-1") > 4, "Training feeds the blocker")
			game._action_runtime()._stop_running_action(str(best.skill), str(best.action.id))
			await settle(0.55)
			await capture_responsive("resources-transfer-settled")
	projects.work["build-repair-small-shack"] = {"step-1": 4}
	game.skills.build.xp = SkillState.xp_for_level(5) + 15
	SkillState.recalculate_level(game, "build", false)
	root.size = Vector2i(1080,1920)
	await settle(1.5)
	game._navigation_shell()._select_skill("build")
	await wait_layout()
	panel = await show_project()
	await capture_responsive("resources-blocker-portrait")
	if is_instance_valid(panel):
		await double_click(panel.blockers.plans.get_global_rect().get_center())
		await wait_layout()
		await capture_responsive("resources-source-portrait")
		panel = await show_project()
		projects.record_success("build", "saw-planks", 2)
		await settle(0.4)
		await capture_responsive("resources-clear-transition")
		await settle(1.2)
		game._navigation_shell()._select_skill("build")
		await wait_layout()
		game._skill_detail_surface()._scroll_to_activity_card("repair-small-shack", true, true)
		await settle(0.6)
		check(not runtime._is_action_unlocked("build", shack), "Cleared resource blocker preserves level gate")
		check(not game.action_cards.get("build:repair-small-shack", {}).get("lock_overlay", {}).is_empty(), "Standard level padlock replaces cleared barrier")
		await capture_responsive("resources-level-padlock")
		var saved: Dictionary = projects.for_save()
		projects.restore({"activity_projects": saved})
		check(projects.complete(shack), "Cleared barrier remains cleared on reload")
	root.size = Vector2i(1920,1080)
	await settle(1)
	game.skills.fight.xp = SkillState.xp_for_level(8)
	SkillState.recalculate_level(game, "fight", false)
	for a in game.actions_by_skill.fight:
		if int(a.unlock) < 9: runtime._mark_action_manually_unlocked("fight", str(a.id))
	game.desktop_layout.rotate_slots("fishing")
	game.selected_skill_id = "fight"
	await game._navigation_shell()._render_screen()
	await wait_layout()
	panel = await show_project("fight", "fight-outmuscle-angry-wheelbarrow")
	check(is_instance_valid(panel), "Stone resource blocker mounts")
	if is_instance_valid(panel):
		projects.record_success("fight", "kick-mud-off-boot", 6)
		await settle(0.5)
		await capture_responsive("resources-stone-desktop")
		root.size = Vector2i(1080,1920)
		await settle(1.5)
		game._navigation_shell()._select_skill("fight")
		await wait_layout()
		await show_project("fight", "fight-outmuscle-angry-wheelbarrow")
		await capture_responsive("resources-stone-portrait")
	# Fishing projects display their resource types without a Wisdom blocker.
	root.size = Vector2i(1920,1080)
	await settle(1)
	for skill in game.skills:
		game.skills[skill].xp = SkillState.xp_for_level(75)
		SkillState.recalculate_level(game, skill, false)
	for entry in projects.definitions.values():
		var row := {}
		for step in entry.project.steps: row[str(step.id)] = int(step.target)
		projects.work[str(entry.project.id)] = row
	for skill in game.skills:
		for a in game.actions_by_skill[skill]:
			if int(a.unlock) < 75 and str(a.id) != "chum-line": runtime._mark_action_manually_unlocked(skill, str(a.id))
	projects.work["fishing-chum-line"] = {"step-1": 120, "step-2": 40}
	game.material_runtime.wisdom_by_skill.fishing = 0
	game.desktop_layout.rotate_slots("woodcutting")
	game.selected_skill_id = "fishing"
	await game._navigation_shell()._render_screen()
	await wait_layout()
	panel = await show_project("fishing", "fishing-chum-line")
	check(is_instance_valid(panel) and panel.blockers.size() == 2 and not panel.blockers.has("wisdom"), "Fishing retains resource blockers without Wisdom")
	await capture_responsive("resources-multiple-desktop")
	await review_materials()
	await review_resource_visibility()

	# Save through the production serializer/loader, including v1 counter migration.
	game.set_process(false)
	projects.restore({"activity_projects": partial})
	var saved_payload: Dictionary = JSON.parse_string(JSON.stringify(game._save_runtime()._save_payload(game._unix_now())))
	projects.clear()
	game._save_runtime()._load_game_core(saved_payload)
	check(projects.amount("build-repair-small-shack", "step-1") == 6, "Production save round-trip preserves resource progress")
	print("PROJECT_RESOURCES failures=", JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func show_project(owner := "build", project_id := "build-repair-small-shack"):
	if game.desktop_layout.enabled():
		for index in range(game.desktop_layout.columns.size()):
			if game.desktop_layout.columns[index].skill_id == owner: game.desktop_layout.focus_column(index)
	var detail = game._skill_detail_surface()
	for entry in detail.detail_lazy_plan:
		if str(entry.get("track_id", "")) == "project:" + project_id:
			var target: float = detail._detail_lazy_entry_rect_for_viewport(entry).position.y
			detail.detail_actions_scroll.scroll_to_vertical(int(target), 0.0)
			detail._sync_detail_lazy_visible_cards(true, 30)
			break
	await settle(0.6)
	for item in get_nodes_in_group("activity_project_panels"):
		if item.skill_id == owner and item.project.id == project_id and item.is_visible_in_tree(): return item
	return null


func click_without_settle(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)
	await process_frame
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)
		await process_frame

func review_materials() -> void:
	# Leave source/target production scenes intact; fixtures only establish access and work.
	var projects = game._project_runtime()
	var runtime = game._activity_unlock_runtime()
	for skill in game.skills:
		game.skills[skill].xp = SkillState.xp_for_level(100)
		SkillState.recalculate_level(game, skill, false)
	for skill in game.skills: game.material_runtime.wisdom_by_skill[skill] = 1000
	game.material_runtime.wisdom_by_skill.fishing = 150
	var examples := [
		["thieving", "crack-snack-safe", "coins"],
		["woodcutting", "fell-skinny-pine", "trail-marks"],
		["build", "construct-fishing-pier", "plans"],
		["build", "assemble-windmill", "rivets"],
		["build", "raise-guild-hall", "plans"],
		["fight", "defeat-stubborn-tractor", "grit"],
		["fishing", "chum-line", "lures"],
		["build", "build-builder-building", "plans"]]
	for example in examples:
		var owner: String = example[0]
		var aid: String = example[1]
		var resource: String = example[2]
		var action: Dictionary = game._action_data(owner, aid)
		var pid := str(action.unlock_project.id)
		for entry in projects.definitions.values():
			var row := {}
			for step in entry.project.steps: row[str(step.id)] = int(step.target)
			projects.work[str(entry.project.id)] = row
		for skill in game.skills:
			for a in game.actions_by_skill[skill]:
				if int(a.unlock) < int(action.unlock): runtime._mark_action_manually_unlocked(skill, str(a.id))
		projects.work[pid] = {}
		for step in action.unlock_project.steps: projects.work[pid][str(step.id)] = int(step.target * 0.4)
		runtime.manual_activity_unlocks.erase(game._action_key(owner, aid))
		game.built_modules.erase(game._action_key(owner, aid))
		game.selected_skill_id = owner
		game.desktop_layout.rotate_slots(owner)
		await game._navigation_shell()._render_screen()
		await wait_layout()
		var panel = await show_project(owner, pid)
		check(is_instance_valid(panel), "Material example mounts: " + aid)
		if not is_instance_valid(panel):
			print("MISSING_MATERIAL next_locked=", runtime._first_locked_action_id(owner), " plan=", game._skill_detail_surface().detail_lazy_plan.map(func(e): return e.get("track_id", "")))
			continue
		var material: String = panel.barrier_material
		await capture_responsive("materials-" + material + "-" + owner)
		if owner == "woodcutting":
			await double_click(panel.blockers[resource].get_global_rect().get_center())
			await wait_layout()
			await capture_responsive("materials-resin-source")
			panel = await show_project(owner, pid)
		if material in ["iron", "silver"]:
			var before_stage: int = panel.damage_state
			for step in action.unlock_project.steps: projects.work[pid][str(step.id)] = int(step.target * 0.72)
			projects.changed.emit(pid)
			await settle(0.12)
			await capture_responsive("materials-" + material + "-cracking")
			check(panel.damage_state > before_stage and not panel.fracture.chips.is_empty(), "Damage emits bounded falling chips")
			await settle(0.75)
			await capture_responsive("materials-" + material + "-settled")
			check(panel.fracture.chips.is_empty() and not panel.fracture.is_processing(), "Chip effect stops and releases state")
		if material == "obsidian":
			root.size = Vector2i(1080,1920)
			await settle(1.5)
			game._navigation_shell()._select_skill(owner)
			await wait_layout()
			await show_project(owner, pid)
			await capture_responsive("materials-obsidian-portrait")
	# Cross-skill producers supply the same resource, but unrelated activities do not.
	projects.clear()
	# Reveal Door by satisfying earlier Building projects; retain its unmet rivets.
	projects.work["build-repair-small-shack"] = {"step-1": 8}
	projects.record_success("build", "hammer-nails", 1)
	projects.record_success("fight", "wrestle-stuck-gate-latch", 1)
	check(projects.amount("build-install-door-that-mostly-opens", "step-1") == 3, "Building and Fighting award two and one Rivets to the same blocker")
	projects.record_success("build", "saw-planks", 1)
	check(projects.amount("build-install-door-that-mostly-opens", "step-1") == 3, "Activity families no longer all produce one owner-skill token")

func review_resource_visibility() -> void:
	var projects = game._project_runtime()
	var unlocks = game._activity_unlock_runtime()
	root.size = Vector2i(1920,1080)
	await settle(1)
	for entry in projects.definitions.values():
		var row := {}
		for step in entry.project.steps: row[str(step.id)] = int(step.target)
		projects.work[str(entry.project.id)] = row
	for owner in game.skills:
		game.material_runtime.wisdom_by_skill[owner] = 1000
		for action in game.actions_by_skill[owner]: unlocks._mark_action_manually_unlocked(owner, str(action.id))
	var pid := "woodcutting-fell-skinny-pine"
	projects.work[pid] = {"step-1": 8}
	unlocks.manual_activity_unlocks.erase(game._action_key("woodcutting", "fell-skinny-pine"))
	projects.refresh_availability()
	check(projects.needed_resources.has("trail-marks"), "Revealed Pine requires Resin")
	game.selected_skill_id = "woodcutting"
	game.desktop_layout.rotate_slots("woodcutting")
	await game._navigation_shell()._render_screen()
	await wait_layout()
	var panel = await show_project("woodcutting", pid)
	check(is_instance_valid(panel), "Relevant resin blocker is reachable")
	if not is_instance_valid(panel): return
	var best: Dictionary = projects.best_source("trail-marks")
	await double_click(panel.blockers["trail-marks"].get_global_rect().get_center())
	await wait_layout()
	var key: String = game._action_key(str(best.skill), str(best.action.id))
	var card: Dictionary = game.action_cards.get(key, {})
	check(not card.is_empty(), "Resin blocker opens actual best producer")
	if card.is_empty(): return
	# The fastest producer has no stored drop. Check both corners on Fell Oak Tree.
	await projects.open_source("woodcutting", "fell-oak-tree")
	await wait_layout()
	best = {"skill": "woodcutting", "action": game._action_data("woodcutting", "fell-oak-tree")}
	key = "woodcutting:fell-oak-tree"
	card = game.action_cards.get(key, {})
	check(not card.is_empty(), "Inventory and unlock resource example is mounted")
	if card.is_empty(): return
	var badge: Control = card.art_panel.get_node("UnlockResourceBadge")
	check(badge.visible and badge.position.x > 0 and badge.position.y < 0, "Required unlock resource occupies top-right")
	var inventory_badge: Control
	for child in card.art_panel.get_children():
		if child is Control and child.z_index == 30: inventory_badge = child
	check(is_instance_valid(inventory_badge) and inventory_badge.position.x < 0 and inventory_badge.position.y > 0, "Stored inventory drop remains bottom-left")
	# Show the revised hands in another real desktop column in the same captures.
	for i in range(game.desktop_layout.columns.size()):
		if str(game.desktop_layout.columns[i].skill_id) == "fight":
			game.desktop_layout.focus_column(i)
			await game._skill_detail_surface()._scroll_to_activity_card("wrap-hands", true, true)
			await settle(0.8)
	for i in range(game.desktop_layout.columns.size()):
		if str(game.desktop_layout.columns[i].skill_id) == "woodcutting": game.desktop_layout.focus_column(i)
	await capture_responsive("resource-demand-visible")
	projects.record_success(str(best.skill), str(best.action.id), 1000)
	await settle(0.15)
	check(badge.visible and badge.modulate.a > 0.0 and badge.modulate.a < 1.0 and not projects.needed_resources.has("trail-marks"), "Last needed Resin fades rather than disappearing in one frame")
	await capture_responsive("resource-demand-fading")
	await settle(0.75)
	check(not badge.visible, "Unused resource hides after fade completes")
	await capture_responsive("resource-demand-filled")
	var saved: Dictionary = projects.for_save()
	projects.record_success(str(best.skill), str(best.action.id), 1000)
	check(projects.for_save() == saved, "No demand means no stored or awarded unlock resources")
	check(is_instance_valid(inventory_badge) and inventory_badge.visible, "Inventory icon remains after unlock resource disappears")
	projects.work[pid] = {"step-1": 8}
	projects.refresh_availability()
	await settle(0.2)
	check(badge.visible, "New demand restores mounted source badge without navigation")
	await capture_responsive("resource-demand-returned")

func review_wrap_hands() -> void:
	game._navigation_shell()._select_skill("fight")
	await wait_layout()
	await game._skill_detail_surface()._scroll_to_activity_card("wrap-hands", true, true)
	await settle(1)
	await capture_responsive("wrap-hands-revised")
