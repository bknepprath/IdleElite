extends SceneTree

const SkillState = preload("res://scripts/progression/skill_state.gd")
const MasteryState = preload("res://scripts/progression/mastery_state.gd")
const RecoveryModules = preload("res://scripts/gameplay/recovery_modules.gd")
const FishingState = preload("res://scripts/fishing/state.gd")
var failures: Array[String] = []

func _init() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func run() -> void:
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.activity_data_catalog.load_action_data(game)
	game._save_runtime()._init_state()
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	var baseline: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://outputs/verification/success-base-oct22/base-rate-changes.json"))
	var before := {}
	for row: Dictionary in baseline.activity_rates:
		before[str(row.skill) + ":" + str(row.action)] = float(row.before)
		if int(row.unlock) <= 10: check(row.before == row.after, "Opening base rate preserved: " + str(row.action))
	var fish = game.fishing_runtime
	fish.net_collected = true
	fish.rod_collected = true
	fish.reinforced_rod_collected = true
	fish.star_rod_collected = true
	fish.boat_built = true
	fish.mirror_collected = true
	for skill: Dictionary in game.skill_defs:
		game.skills[skill.id] = {"xp": SkillState.xp_for_level(99), "level": 99}
		for action: Dictionary in game.actions_by_skill[skill.id]:
			game._activity_unlock_runtime()._mark_action_manually_unlocked(skill.id, action.id)
	var runtime = game._action_runtime()
	var profiles := []
	for setup in [["fresh", 0, 0], ["three_medals_barn2", 3, 2], ["ten_medals_barn4", 10, 4], ["twenty_medals_barn4", 20, 4]]:
		game.mastery.clear()
		game._hub_runtime().hub_modules.barn = {"level": int(setup[2]), "building": false}
		for skill: Dictionary in game.skill_defs:
			for action: Dictionary in game.actions_by_skill[skill.id]:
				if MasteryState.action_has_mastery(game, action):
					game.mastery[str(skill.id) + ":" + str(action.id)] = {"xp": MasteryState.xp_for_level(int(setup[1])), "level": int(setup[1])}
		SkillState.invalidate_stat_caches(game)
		var rows := []
		var summaries := {}
		for skill: Dictionary in game.skill_defs:
			var summary := {"later_activities": 0, "before_100": 0, "after_100": 0}
			for action: Dictionary in game.actions_by_skill[skill.id]:
				var key := str(skill.id) + ":" + str(action.id)
				if not before.has(key): continue
				if RecoveryModules.has_recovery(action) or game._passive_modules_runtime().is_passive_action(action) or game._convergence_runtime()._is_convergence_action(action) or action.has("boss"): continue
				var compatible: Array = FishingState.compatible_tool_ids(str(action.id)) if str(skill.id) == "fishing" else []
				if str(skill.id) == "fishing" and not fish.action_should_render_standalone(game, "fishing", action):
					fish.equipped_tool_id = "star_rod" if compatible.has("star_rod") else ("boat" if compatible.has("boat") else ("mirror" if compatible.has("mirror") else "hands"))
				var updated := float(action.success)
				action.success = float(before[key])
				SkillState.invalidate_stat_caches(game)
				var old_rate: float = runtime._success_chance(str(skill.id), action)
				action.success = updated
				SkillState.invalidate_stat_caches(game)
				var new_rate: float = runtime._success_chance(str(skill.id), action)
				check(new_rate <= old_rate + 0.001, "No hidden success increase: " + key)
				check(new_rate >= 5.0 and new_rate <= 100.0, "Chance remains a valid probability: " + key)
				if int(action.unlock) > 10:
					summary.later_activities += 1
					if old_rate >= 99.999: summary.before_100 += 1
					if new_rate >= 99.999: summary.after_100 += 1
				rows.append({"skill": skill.id, "action": action.id, "unlock": action.unlock, "base": updated, "before_effective": old_rate, "after_effective": new_rate})
			check(summary.after_100 < summary.later_activities, "Later activities retain accuracy headroom: " + str(skill.id) + " " + str(setup[0]))
			summaries[str(skill.id)] = summary
		profiles.append({"profile": setup[0], "medals": setup[1], "barn": setup[2], "summaries": summaries, "activities": rows})
		print("SUCCESS_BASE_PROFILE ", setup[0], " ", JSON.stringify(summaries))
	var tier_rewards := []
	game._hub_runtime().hub_modules.barn = {"level": 0, "building": false}
	for skill: Dictionary in game.skill_defs:
		var playable: Array = AchievementState.playable_actions_for_medal_buffs(game, str(skill.id))
		for target_tier in range(2, 11):
			var sources := playable.filter(func(action): return AchievementState.action_tier(game, action) == target_tier - 1)
			var targets := playable.filter(func(action): return AchievementState.action_tier(game, action) == target_tier)
			if sources.is_empty() or targets.is_empty(): continue
			game.mastery.clear()
			SkillState.invalidate_stat_caches(game)
			var unassisted := {}
			for action: Dictionary in targets:
				if str(skill.id) == "fishing" and not fish.action_should_render_standalone(game, "fishing", action):
					var tools: Array = FishingState.compatible_tool_ids(str(action.id))
					fish.equipped_tool_id = "star_rod" if tools.has("star_rod") else ("boat" if tools.has("boat") else ("mirror" if tools.has("mirror") else "hands"))
				SkillState.invalidate_stat_caches(game)
				unassisted[str(action.id)] = runtime._success_chance(str(skill.id), action)
			for action: Dictionary in sources:
				var mastery_id: String = AchievementState._mastery_action_id_for_action(game, str(skill.id), action)
				game.mastery[str(skill.id) + ":" + mastery_id] = {"xp": MasteryState.xp_for_level(1), "level": 1}
			SkillState.invalidate_stat_caches(game)
			check(AchievementState.activity_tier_accuracy_bonus(game, str(skill.id), targets[0]) == 5.0, "Previous tier's Bronze reward reaches the next tier: " + str(skill.id) + " T" + str(target_tier))
			for action: Dictionary in targets:
				if str(skill.id) == "fishing" and not fish.action_should_render_standalone(game, "fishing", action):
					var tools: Array = FishingState.compatible_tool_ids(str(action.id))
					fish.equipped_tool_id = "star_rod" if tools.has("star_rod") else ("boat" if tools.has("boat") else ("mirror" if tools.has("mirror") else "hands"))
				SkillState.invalidate_stat_caches(game)
				var supported: float = runtime._success_chance(str(skill.id), action)
				var prior := float(unassisted[str(action.id)])
				check(is_equal_approx(supported, minf(100.0, prior + 5.0)), "Bronze support improves every next-tier activity additively: " + str(action.id))
				tier_rewards.append({"skill": skill.id, "tier": target_tier, "action": action.id, "before_support": prior, "after_support": supported})
	var out := FileAccess.open("res://outputs/verification/success-base-oct22/runtime-profiles.json", FileAccess.WRITE)
	out.store_string(JSON.stringify({"failures": failures, "profiles": profiles, "tier_rewards": tier_rewards}, "  "))
	out.close()
	print("success-base-oct22 failures=", JSON.stringify(failures))
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
