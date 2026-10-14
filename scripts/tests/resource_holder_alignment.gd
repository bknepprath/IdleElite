extends "res://scripts/tests/full_width_barriers.gd"

func review_materials() -> void:
	var projects = game._project_runtime()
	var locks = game._activity_unlock_runtime()
	for skill in game.skills:
		game.skills[skill].xp = SkillState.xp_for_level(8)
		SkillState.recalculate_level(game, skill, false)
		for action in game.actions_by_skill[skill]:
			if int(action.unlock) < 6: locks._mark_action_manually_unlocked(skill, str(action.id))
	projects.work["build-repair-small-shack"] = {"step-1": 3}
	locks.manual_activity_unlocks.erase("build:repair-small-shack")
	game.built_modules.erase("build:repair-small-shack")
	game.selected_skill_id = "build"
	game.desktop_layout.rotate_slots("build")
	for dimensions in [Vector2i(1920, 1080), Vector2i(1080, 1920)]:
		root.size = dimensions
		await game._navigation_shell()._render_screen()
		await wait_layout()
		var panel = await show_project("build", "build-repair-small-shack")
		check(is_instance_valid(panel), "Shack holder visible in production scene")
		await capture_responsive("holder-centered-" + str(dimensions.x))

func review_pool() -> void:
	pass
