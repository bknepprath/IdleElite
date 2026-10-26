extends "res://scripts/tests/action_art_oct22.gd"

func audit_action_art() -> void:
	var unlocks = game._activity_unlock_runtime()
	var projects = game._project_runtime()
	projects.clear()
	unlocks.manual_activity_unlocks.clear()
	unlocks._invalidate_manual_activity_unlock_trust()
	for skill_id in game.skills:
		game.skills[skill_id].xp = SkillState.xp_for_level(13)
		game.skills[skill_id].level = 13
		for action in game.actions_by_skill[skill_id]:
			if int(action.unlock) <= 13 and (action.get("grove", {}) as Dictionary).is_empty():
				unlocks._mark_action_manually_unlocked(skill_id, str(action.id))
	var ids: Array = []
	for action in unlocks._visible_actions_for_skill("woodcutting"):
		ids.append(str(action.id))
	print("WOODCUTTING_LEGACY_VISIBLE ", JSON.stringify(ids))
	check(ids.has("prune-orchard-row"), "Existing berry activity remains visible")
	check(ids.has("grove-birch"), "Unclaimed first grove remains visible")
	check(ids.has("fell-skinny-pine"), "Next ordinary activity remains visible past an unclaimed grove")
	check(not ids.has("chop-knotty-maple"), "Later ordinary activities retain sequential reveal")
	check(not ids.has("grove-pine"), "Later groves retain sequential reveal")
	check(projects.revealed_projects().has("woodcutting-fell-skinny-pine"), "Next Pine resource blocker is revealed")
	projects.refresh_availability()
	check(projects.needed_resources.has("trail-marks"), "Resin sources remain available for the next unlock")
	await open_notes_skill("woodcutting")
	var berries := await notes_card("prune-orchard-row")
	if not berries.is_empty():
		await align_notes_card(berries)
		await capture("berries-and-next-unlock")
	if ids.has("fell-skinny-pine"):
		await projects.open_project("woodcutting", "woodcutting-fell-skinny-pine")
		await settle(.8)
		await capture("pine-resource-blocker")
		await verify_pine_unlock(unlocks, projects)
	# A new player still sees only the existing first ordinary lock, not a
	# premature level-eight grove preview.
	unlocks.manual_activity_unlocks.clear()
	unlocks._invalidate_manual_activity_unlock_trust()
	game.skills.woodcutting.xp = 0
	game.skills.woodcutting.level = 1
	var starter_ids: Array = []
	for action in unlocks._visible_actions_for_skill("woodcutting"):
		starter_ids.append(str(action.id))
	check(not starter_ids.has("grove-birch"), "Early progression does not reveal groves prematurely")
	print("WOODCUTTING_PROGRESSION failures=", JSON.stringify(failures))
	var result := FileAccess.open(capture_dir + "/result.json", FileAccess.WRITE)
	result.store_string(JSON.stringify({"failures":failures,"visible":ids}))
	result.close()
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	quit(0 if failures.is_empty() else 1)

func verify_pine_unlock(unlocks, projects) -> void:
	var pine: Dictionary = game._action_data("woodcutting", "fell-skinny-pine")
	check(not unlocks._can_unlock_action("woodcutting", pine), "Pine keeps its resource and level requirements")
	projects.record_success("woodcutting", "trim-overconfident-shrub", 1000)
	check(projects.complete(pine), "Existing Resin-producing activity can complete the Pine blocker")
	check(not unlocks._can_unlock_action("woodcutting", pine), "Resin alone does not bypass level fifteen")
	game.skills.woodcutting.xp = SkillState.xp_for_level(15)
	SkillState.recalculate_level(game, "woodcutting")
	await settle(1.2)
	check(unlocks._can_unlock_action("woodcutting", pine), "Live level gain makes the Pine lock ready without reopening the page")
	var card := await notes_card("fell-skinny-pine")
	if card.is_empty(): return
	await align_notes_card(card)
	var lock_group = card.get("lock_overlay", {}).get("group")
	check(is_instance_valid(lock_group), "Pine's real lock control mounts after resources clear")
	if not is_instance_valid(lock_group): return
	var rig = lock_group.rigs[0]
	var lock_point: Vector2 = rig.padlock.get_global_transform_with_canvas() * (rig.padlock.size * Vector2(.5,.72))
	await click(lock_point, true)
	await settle(4)
	check(unlocks._is_action_unlocked("woodcutting", pine), "Actual lock tap unlocks Pine at level fifteen")
	var visible: Array = []
	for action in unlocks._visible_actions_for_skill("woodcutting"):
		visible.append(str(action.id))
	check(visible.has("chop-knotty-maple"), "Unlocking Pine reveals the following level-sixteen activity")
	await capture("pine-unlocked")
