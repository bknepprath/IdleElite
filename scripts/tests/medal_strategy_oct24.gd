extends SceneTree

const SkillState = preload("res://scripts/progression/skill_state.gd")
const MasteryState = preload("res://scripts/progression/mastery_state.gd")
const AchievementState = preload("res://scripts/achievements/state.gd")
var failures: Array[String] = []
var profiles: Array = []
var saturation: Array = []

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
	game._hub_runtime().hub_modules.barn = {"level": 0, "building": false}
	var runtime = game._action_runtime()
	var starters := {
		"fight": ["push-ups", "kick-mud-off-boot", "wrestle-stuck-gate-latch"],
		"build": ["stack-bricks", "hammer-nails", "patch-fence"],
		"thieving": ["borrow-cookie-permanently", "sneak-past-tip-jar", "pocket-couch-coins"],
		"woodcutting": ["gather-fallen-branches", "snap-a-twig-with-purpose", "split-firewood"],
		"fishing": ["shallows", "practice-pool", "rocks"]
	}
	game.fishing_runtime.equipped_tool_id = "hands"
	for skill_id in starters:
		for levels in [[0,0,0], [1,1,0], [1,1,1], [2,2,0], [2,2,2], [2,3,2]]:
			game.mastery.clear()
			for i in 3:
				game.mastery[skill_id + ":" + starters[skill_id][i]] = {"level":levels[i], "xp":MasteryState.xp_for_level(levels[i])}
			SkillState.invalidate_stat_caches(game)
			var rates := []
			for id in starters[skill_id]:
				rates.append(runtime._success_chance(skill_id, game._action_data(skill_id, id)))
			profiles.append({"skill":skill_id,"medals":levels,"rates":rates})
			if levels == [0,0,0]:
				check(rates.min() >= 95.0, "Opening activities remain reliable: " + skill_id)
			if levels == [1,1,0]:
				check(rates[0] == 100.0 and rates[1] < 100.0 and rates[2] < 100.0, "Two Bronze medals finish only the first action: " + skill_id)
			if levels == [2,2,0]:
				check(rates[1] == 100.0, "Silver on first and second completes second: " + skill_id)
			if levels == [2,2,2]:
				check(rates[2] >= 99.4 and rates[2] < 100.0, "Third stays close with Silver: " + skill_id)
			if levels == [2,3,2]:
				check(rates[2] == 100.0, "Nearby Gold completes the third: " + skill_id)
		print("EARLY_MEDALS ", skill_id, " ", JSON.stringify(profiles.slice(profiles.size()-6)))
	# Even Bronze on every activity must leave later progression to pursue.
	for skill_id in starters:
		game.mastery.clear()
		var actions: Array = AchievementState.playable_actions_for_medal_buffs(game, skill_id)
		for action in actions:
			game.mastery[skill_id + ":" + str(action.id)] = {"level":1,"xp":MasteryState.xp_for_level(1)}
		SkillState.invalidate_stat_caches(game)
		var capped := 0
		var later := 0
		var later_uncapped := 0
		for action in actions:
			var chance: float = runtime._success_chance(skill_id, action)
			if chance == 100.0: capped += 1
			if int(action.unlock) >= 15:
				later += 1
				if chance < 100.0: later_uncapped += 1
		check(later_uncapped > later / 2, "Most later activities still need mastery beyond Bronze: " + skill_id)
		saturation.append({"skill":skill_id,"all_bronze_capped":capped,"actions":actions.size(),"later_uncapped":later_uncapped,"later":later})
	print("MEDAL_SATURATION ", JSON.stringify(saturation))
	# A couple of starter medals cannot propagate across the entire skill.
	game.mastery.clear()
	game.mastery["fight:push-ups"] = {"level":1,"xp":MasteryState.xp_for_level(1)}
	game.mastery["fight:kick-mud-off-boot"] = {"level":1,"xp":MasteryState.xp_for_level(1)}
	SkillState.invalidate_stat_caches(game)
	check(AchievementState.activity_medal_accuracy_bonus(game,"fight",game._action_data("fight","square-up-with-rake")) == 0.0, "Starter support has bounded reach")
	# The existing tier reward remains exactly five points, measured on its own.
	game.mastery.clear()
	for action in AchievementState.playable_actions_for_medal_buffs(game,"build"):
		if AchievementState.action_tier(game,action) == 1:
			game.mastery["build:"+str(action.id)] = {"level":1,"xp":MasteryState.xp_for_level(1)}
	SkillState.invalidate_stat_caches(game)
	check(AchievementState.activity_tier_accuracy_bonus(game,"build",game._action_data("build","build-bridge-over-tiny-puddle")) == 5.0, "Prior tier Bronze still grants five accuracy points")
	var baseline: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://scripts/tests/fixtures/medal-strategy-before-2026-10-24.json"))
	game.mastery.clear()
	SkillState.invalidate_stat_caches(game)
	for old: Dictionary in baseline.building_before:
		var action: Dictionary = game._action_data("build", old.id)
		check(is_equal_approx(action.seconds, old.seconds*2) and action.stamina == old.stamina*2 and action.xp == old.xp*2, "Building cadence doubles: " + str(old.id))
		check(is_equal_approx(action.xp/action.seconds, float(old.xp)/old.seconds), "Base XP/sec preserved: " + str(old.id))
		check(is_equal_approx(float(action.stamina)/action.seconds, float(old.stamina)/old.seconds), "Stamina/sec preserved: " + str(old.id))
		check(is_equal_approx(MasteryState.xp_reward(action)/action.seconds, float(old.get("mastery_xp_per_completion",1))/old.seconds), "Mastery/sec preserved: " + str(old.id))
		if old.has("unlock_drop"):
			check(action.unlock_drop.amount == old.unlock_drop.amount*2, "Resource output doubles: " + str(old.id))
		if old.has("wisdom_reward"):
			check(action.wisdom_reward == old.wisdom_reward*2, "Wisdom output doubles: " + str(old.id))
		for skill in old.get("xp_rewards", {}):
			check(action.xp_rewards[skill] == old.xp_rewards[skill]*2, "Cross-skill XP doubles: " + str(old.id))
	check(game._action_data("build","sharpen-the-pencil").stamina == -4, "Resting remains unchanged")
	DirAccess.make_dir_recursive_absolute("res://outputs/verification/medal-strategy-oct24")
	var output := FileAccess.open("res://outputs/verification/medal-strategy-oct24/runtime-profiles.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"failures":failures,"profiles":profiles,"saturation":saturation},"  "))
	output.close()
	print("MEDAL_STRATEGY failures=",JSON.stringify(failures))
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
