extends "res://scripts/tests/action_art_oct22.gd"

func audit_action_art() -> void:
	var expected := ["stack-bricks", "hammer-nails", "gather-sand", "saw-planks", "patch-fence", "study-blueprint", "repair-small-shack", "sharpen-the-pencil", "melt-sand", "install-door-that-mostly-opens", "shape-bottles", "build-bridge-over-tiny-puddle"]
	var actual: Array = []
	for action in game.actions_by_skill.build: actual.append(str(action.id))
	check(actual.slice(0, expected.size()) == expected, "Loaded Building progression matches the requested order")
	var unlocks = game._activity_unlock_runtime()
	var levels := {"gather-sand":3,"saw-planks":4,"patch-fence":5,"study-blueprint":6,"repair-small-shack":7,"melt-sand":9,"install-door-that-mostly-opens":10,"shape-bottles":11}
	for id in levels:
		var action: Dictionary = game._action_data("build", id)
		game.skills.build.level = levels[id] - 1
		game.skills.build.xp = SkillState.xp_for_level(levels[id] - 1)
		check(not unlocks._action_requirements_met("build", action), "Building level gate holds below the new level: " + id)
		game.skills.build.level = levels[id]
		game.skills.build.xp = SkillState.xp_for_level(levels[id])
		check(unlocks._action_requirements_met("build", action), "Building requirement opens at the new level: " + id)
	game.skills.build.level = 99
	game.skills.build.xp = SkillState.xp_for_level(99)
	game.skills.fishing.level = 3
	game.skills.fishing.xp = SkillState.xp_for_level(3)
	check(not unlocks._action_requirements_met("build", game._action_data("build", "gather-sand")), "Gather Sand keeps its Fishing level four requirement")
	game.skills.fishing.level = 99
	game.skills.fishing.xp = SkillState.xp_for_level(99)
	for id in game.material_runtime.material_defs: game.material_runtime.set_amount(str(id), 1000)
	for action in game.actions_by_skill.build:
		if not action.get("build", {}).is_empty(): game.built_modules[game._action_key("build", str(action.id))] = true
	SkillState.invalidate_stat_caches(game)
	await open_notes_skill("build")
	var entries: Array = game._skill_detail_surface()._visible_detail_entries_for_skill("build")
	var display: Array = []
	for entry in entries:
		if entry.kind == "action": display.append(str(entry.action.id))
		elif entry.kind == "tier_banner": display.append("tier:" + str(entry.tier))
	var banner_index: int = display.find("tier:1")
	check(banner_index > 0 and display[banner_index - 1] == "install-door-that-mostly-opens" and display[banner_index + 1] == "shape-bottles", "Shape Bottles is the first activity below the Tier 1 banner")
	for id in ["gather-sand", "patch-fence", "sharpen-the-pencil", "melt-sand"]:
		var card := await notes_card(id)
		await align_notes_card(card)
		await capture(id + "-order")
	var detail = game._skill_detail_surface()
	var key: String = detail._tier_banner_key("build", 1)
	await detail._scroll_to_activity_card(key, false, true)
	await settle(.5)
	var lazy: Dictionary = detail._detail_lazy_entry_for_track_id(key)
	check(not lazy.is_empty(), "Tier 1 banner is mounted in the actual production page")
	if not lazy.is_empty():
		game.detail_actions_scroll.scroll_vertical += int(lazy.stack_host.get_global_rect().position.y - 455)
		await settle(.6)
		await capture("tier-one-shape-bottles")
	var report := FileAccess.open(capture_dir + "/result.json", FileAccess.WRITE)
	report.store_string(JSON.stringify({"failures":failures,"loaded_order":actual,"display_order":display}))
	report.close()
	print("BUILDING_ORDER failures=", JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	quit(0 if failures.is_empty() else 1)
