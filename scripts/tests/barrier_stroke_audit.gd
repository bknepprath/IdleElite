extends "res://scripts/tests/full_width_barriers.gd"

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
		["build", "repair-small-shack", "plans"],
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
		check(panel.fracture.cover.size.x >= panel.size.x, "Cover uses full activity width: " + material)
		await capture_responsive("materials-" + material + "-" + owner)
		if owner == "woodcutting":
			await click(panel.blockers[resource].get_global_rect().get_center())
			await wait_layout()
			await capture_responsive("materials-resin-source")
			panel = await show_project(owner, pid)
		if material in ["timber", "iron", "silver"]:
			var before_stage: int = panel.damage_state
			for step in action.unlock_project.steps: projects.work[pid][str(step.id)] = int(step.target * 0.72)
			projects.changed.emit(pid)
			await settle(0.12)
			await capture_responsive("materials-" + material + "-cracking")
			check(panel.damage_state > before_stage and not panel.fracture.chips.is_empty(), "Damage emits bounded falling chips")
			await settle(0.75)
			await capture_responsive("materials-" + material + "-settled")
			check(panel.fracture.chips.is_empty() and not panel.fracture.is_processing(), "Chip effect stops and releases state")
		if true:
			root.size = Vector2i(1080,1920)
			await settle(1.5)
			game._navigation_shell()._select_skill(owner)
			await wait_layout()
			await show_project(owner, pid)
			await capture_responsive("materials-" + material + "-portrait")
			root.size = Vector2i(1920,1080)
			await wait_layout()
	# Cross-skill producers supply the same resource, but unrelated activities do not.
	projects.clear()
	# Reveal Door by satisfying earlier Building projects; retain its unmet rivets.
	projects.work["build-repair-small-shack"] = {"step-1": 8}
	projects.record_success("build", "hammer-nails", 1)
	projects.record_success("fight", "wrestle-stuck-gate-latch", 1)
	check(projects.amount("build-install-door-that-mostly-opens", "step-1") == 2, "Rivets from two skills feed the same blocker")
	projects.record_success("build", "saw-planks", 1)
	check(projects.amount("build-install-door-that-mostly-opens", "step-1") == 2, "Activity families no longer all produce one owner-skill token")


func review_pool() -> void:
	pass
