extends SceneTree

const SkillState = preload("res://scripts/progression/skill_state.gd")
const RecoveryModules = preload("res://scripts/gameplay/recovery_modules.gd")
const HubRuntime = preload("res://scripts/gameplay/hub_runtime.gd")
var failures: Array[String] = []

func _init() -> void:
	call_deferred("run")

func expect(ok: bool, message: String) -> void:
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
	game.auto_unlock_lockpads_enabled = false
	var runtime = game._action_runtime()
	var hub = game._hub_runtime()
	var detail = game._skill_detail_surface()
	audit_fresh_progression()
	audit_hub_purchases(game)
	audit_medal_counts(game)
	audit_medal_buff_lookup_work()
	audit_module_group_detection(detail)
	audit_deferred_stat_refresh(game)
	var small_action: Dictionary = game._action_data("build", "sit-on-the-toolbox")
	game._ad_bonus_runtime().seconds_remaining = 3600
	SkillState.invalidate_stat_caches(game)
	var xp_details: Dictionary = detail._activity_stat_bonus_details("build", small_action, "xp")
	expect(xp_details.original == xp_details.current, "Small XP bonus displays the actual rounded reward")
	expect("XP is rounded to whole numbers." in xp_details.bonuses, "An unchanged small XP reward explains rounding")
	var large_action := small_action.duplicate(true)
	large_action.xp = 100
	large_action.erase("xp_rewards")
	var large_xp: Dictionary = detail._activity_stat_bonus_details("build", large_action, "xp")
	expect(large_xp.original != large_xp.current, "Larger rewards show the awarded XP increase")
	expect(not "XP is rounded to whole numbers." in large_xp.bonuses, "Rounding note is omitted when the increase is visible")
	expect(detail._format_xp_reward_parts([{"skill":"build", "amount":1234}], true) == "+1234 Building", "Expanded XP shows exact whole rewards")
	var time_details: Dictionary = detail._activity_stat_bonus_details("build", small_action, "time")
	expect("Ad bonus: 10% less time" in time_details.bonuses, "Time bonuses explain the actual duration reduction")
	game._ad_bonus_runtime().seconds_remaining = 0
	SkillState.invalidate_stat_caches(game)
	xp_details = detail._activity_stat_bonus_details("build", small_action, "xp")
	expect(not "XP is rounded to whole numbers." in xp_details.bonuses, "No rounding note without an active bonus")
	for pair in [["woodcutting", 16], ["fight", 14], ["fishing", 12]]:
		game.skills[pair[0]].level = pair[1]
		game.skills[pair[0]].xp = SkillState.xp_for_level(pair[1])
	game.skills.build.level = 1
	for id in ["woodcutting_totem", "fighting_display", "pond"]:
		expect(hub.module_next_level_unlocked(id), "Upgrade must use its own skill: " + id)
	game.material_runtime.set_amount("softwood", 500)
	game.material_runtime.set_amount("hardwood", 500)
	for id in ["woodcutting_totem", "fighting_display"]:
		var before: float = game.material_runtime.amount("softwood")
		expect(not hub.upgrade_module(id).get("blocked", false), "Upgrade must start: " + id)
		expect(hub.module_level(id) == 0 and hub.module_building(id), "Bonus waits for build completion")
		var after: float = game.material_runtime.amount("softwood")
		expect(after < before, "Upgrade spends material once")
		hub.upgrade_module(id)
		expect(game.material_runtime.amount("softwood") == after, "Repeated build press must not spend again")
		hub.hub_modules[id].build_started_unix_msec -= 16000
		hub.complete_ready_builds()
		expect(hub.module_level(id) == 1, "Build grants tier one")
		expect(hub.module_wood_currency_for_level(id, 1) == "hardwood", "Tier two uses hardwood")
	var saved: Dictionary = hub.modules_for_save()
	expect(hub.normalized_modules(saved) == saved, "New module levels survive save normalization")
	expect(is_equal_approx(hub.wood_collection_multiplier(), 1.1), "Totem gives ten percent")
	var base_wood: float = game.material_runtime.buffed_log_collection_amount_for_host("hardwood", 10.0, game)
	hub.hub_modules.woodcutting_totem.level = 0
	var plain_wood: float = game.material_runtime.buffed_log_collection_amount_for_host("hardwood", 10.0, game)
	expect(is_equal_approx(base_wood, plain_wood * 1.1), "Totem actually increases wood rewards")
	hub.hub_modules.fighting_display.level = 4
	var arena = game._fighting_runtime()
	game.running_skill_id = "fight"
	game.running_action_id = "fight-chickens"
	hub.hub_modules.mission = {"level": 1, "building": false}
	game._activity_unlock_runtime()._mark_action_manually_unlocked("fight", "fight-chickens")
	hub.restore_missions([{"skill_id":"fight", "action_id":"fight-chickens", "target":100, "remaining":100}])
	var stage := Control.new()
	stage.set_meta("combat_action_id", "fight-chickens")
	root.add_child(stage)
	var before_xp: int = game.skills.fight.xp
	for i in range(10):
		arena.on_blue_guy_chicken_brawl_chicken_killed(1, stage)
	expect(hub.hub_missions[0].remaining == 90, "Ten low-XP enemy kills count as ten mission units")
	expect(game.skills.fight.xp == before_xp + 12, "Fighting display retains fractional per-kill XP")
	stage.set_meta("combat_action_id", "fight-goblins")
	arena.on_blue_guy_chicken_brawl_chicken_killed(10, stage)
	expect(hub.hub_missions[0].remaining == 90, "Stale stage must not count")
	stage.queue_free()
	game.running_skill_id = ""
	game.running_action_id = ""
	var action: Dictionary = game._action_data("woodcutting", "clear-dense-grove").duplicate(true)
	action.success = 100
	action.mat_rewards = [{"id":"softwood", "amount":2, "chance":1.0}]
	game.material_runtime.set_amount("berries", 1)
	game.material_runtime.berry_prep = {"targets":{"woodcutting:clear-dense-grove":true}}
	var wood_before: float = game.material_runtime.amount("softwood")
	before_xp = game.skills.fight.xp
	var result: Dictionary = runtime._grant_offline_action_completion("woodcutting", "clear-dense-grove", action)
	expect(result.success, "Deterministic offline completion must succeed")
	expect(game.material_runtime.amount("berries") == 0, "Offline success consumes one berry")
	var wood_gained: float = game.material_runtime.amount("softwood") - wood_before
	var expected_wood: float = game.material_runtime.buffed_log_collection_amount_for_host("softwood", 4.0, game)
	expect(is_equal_approx(wood_gained, expected_wood), "Offline berry success doubles material loot")
	expect(game.skills.fight.xp > before_xp, "Offline combo awards secondary skill XP")
	wood_before = game.material_runtime.amount("softwood")
	runtime._grant_offline_action_completion("woodcutting", "clear-dense-grove", action)
	expect(is_equal_approx(game.material_runtime.amount("softwood") - wood_before, expected_wood * 0.5), "Depleted berries resume normal loot")
	game.material_runtime.set_amount("berries", 7)
	game.skills.woodcutting.level = 40
	game.skills.woodcutting.xp = SkillState.xp_for_level(40)
	SkillState.invalidate_stat_caches(game)
	game.running_skill_id = "woodcutting"
	game.running_action_id = "clear-dense-grove"
	game.action_progress = 0.4
	game._activity_unlock_runtime()._mark_action_manually_unlocked("woodcutting", "clear-dense-grove")
	hub.hub_modules.woodcutting_totem.level = 1
	expect(not hub.upgrade_module("woodcutting_totem").get("blocked", false), "Second-tier build starts before restart")
	var saved_wallet: Dictionary = game.material_runtime.save_wallet().duplicate(true)
	var payload: Dictionary = JSON.parse_string(JSON.stringify(game._save_runtime()._save_payload(game._unix_now())))
	var restored = load("res://scenes/main.tscn").instantiate()
	root.add_child(restored)
	restored.activity_data_catalog.load_action_data(restored)
	var restored_save = restored._save_runtime()
	restored_save._init_state()
	restored_save._load_game_core(payload)
	restored_save.pending_save_restore_data = payload
	restored_save._load_game_secondary_restore()
	expect(restored.material_runtime.save_wallet() == saved_wallet, "Save restore preserves materials and berries")
	expect(restored._hub_runtime().module_level("fighting_display") == 4, "Completed hub upgrade survives full save restore")
	expect(restored._hub_runtime().module_building("woodcutting_totem"), "In-progress hub build survives full save restore")
	expect(restored._hub_runtime().hub_missions[0].remaining == 90, "Mission progress survives full save restore")
	expect(restored.material_runtime.berry_prep_for_save(Callable(restored, "_action_data")) == game.material_runtime.berry_prep_for_save(Callable(game, "_action_data")), "Berry selections survive full save restore")
	expect(restored.running_skill_id == "woodcutting" and restored.running_action_id == "clear-dense-grove", "Active activity survives full save restore")
	expect(is_equal_approx(restored.action_progress, 0.4), "Partial action progress survives full save restore")
	restored._hub_runtime().hub_modules.woodcutting_totem.build_started_unix_msec -= 16000
	restored._hub_runtime().complete_ready_builds()
	expect(restored._hub_runtime().module_level("woodcutting_totem") == 2, "Restored build completes at its intended tier")
	expect(restored.material_runtime.save_wallet() == saved_wallet, "Restored build does not charge materials twice")
	var restored_action: Dictionary = restored._action_data("woodcutting", "clear-dense-grove")
	restored_action.success = 100
	restored_action.mat_rewards = [{"id":"softwood", "amount":2, "chance":1.0}]
	restored._hub_runtime().restore_missions([{"skill_id":"woodcutting", "action_id":"clear-dense-grove", "target":100, "remaining":100}])
	SkillState.invalidate_stat_caches(restored)
	var restored_runtime = restored._action_runtime()
	var restored_xp_before: int = restored.skills.fight.xp
	var offline_summary: Dictionary = restored_runtime._apply_offline_active_action(20.0)
	var offline_successes := int(offline_summary.get("successes", 0))
	expect(offline_successes > 0, "Restored activity progresses through offline time")
	expect(restored.skills.fight.xp > restored_xp_before, "Offline elapsed-time path awards secondary XP")
	expect(not restored._hub_runtime().hub_missions.is_empty() and restored._hub_runtime().hub_missions[0].remaining == 100 - offline_successes, "Offline elapsed-time path advances mission progress once per success")
	expect(restored.material_runtime.amount("berries") == maxf(0, 7 - offline_successes), "Offline elapsed-time path consumes one berry per success")
	var wallet_after_offline: Dictionary = restored.material_runtime.save_wallet().duplicate(true)
	restored_xp_before = restored.skills.fight.xp
	restored_runtime._apply_offline_active_action(0.0)
	expect(restored.material_runtime.save_wallet() == wallet_after_offline and restored.skills.fight.xp == restored_xp_before, "No elapsed time grants no duplicate rewards")
	restored.queue_free()
	print("ham-feedback failures=", failures)
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)


func audit_hub_purchases(game: Node) -> void:
	var hub = game._hub_runtime()
	var saved_skills: Dictionary = game.skills.duplicate(true)
	var saved_modules: Dictionary = hub.hub_modules.duplicate(true)
	var saved_fish: float = game.fishing_runtime.fish_currency
	for id in HubRuntime.HUB_MODULE_ORDER:
		var definition: Dictionary = HubRuntime.HUB_MODULE_DEFS[id]
		var skill: String = hub.module_skill(id)
		for level in range(HubRuntime.HUB_MODULE_MAX_LEVEL):
			hub.hub_modules[id] = {"level":level, "building":false}
			var required: int = hub.module_next_unlock_level(id)
			game.skills[skill].level = required - 1
			game.material_runtime.set_amount("softwood", 10000)
			game.material_runtime.set_amount("hardwood", 10000)
			game.fishing_runtime.fish_currency = 10000
			var wallet: Dictionary = game.material_runtime.save_wallet().duplicate(true)
			expect(hub.upgrade_module(id).get("blocked", false), "Locked upgrade rejects purchase: %s/%s" % [id,level])
			expect(wallet == game.material_runtime.save_wallet() and game.fishing_runtime.fish_currency == 10000, "Locked upgrade spends nothing")
			game.skills[skill].level = required
			if id == "garden":
				game.fishing_runtime.fish_currency = 0
				expect(hub.upgrade_module(id).get("blocked", false), "Garden requires both currencies")
				expect(wallet == game.material_runtime.save_wallet(), "Missing fish must not consume garden wood")
				game.fishing_runtime.fish_currency = 10000
			var result: Dictionary = hub.upgrade_module(id)
			expect(not result.is_empty() and not result.get("blocked", false), "Eligible upgrade starts: %s/%s" % [id,level])
			var currency: String = hub.module_wood_currency_for_level(id, level)
			var cost: int = definition.costs[level]
			var fish_cost: int = cost if id == "pond" else (int(definition.fish_costs[level]) if id == "garden" else 0)
			expect(game.fishing_runtime.fish_currency == 10000 - fish_cost, "Upgrade charges exact fish cost")
			if id != "pond":
				expect(game.material_runtime.amount(currency) == 10000 - cost, "Upgrade charges exact wood cost")
			wallet = game.material_runtime.save_wallet().duplicate(true)
			for tap in range(20):
				hub.upgrade_module(id)
			expect(wallet == game.material_runtime.save_wallet() and game.fishing_runtime.fish_currency == 10000 - fish_cost, "Rapid upgrade taps cannot charge twice")
			expect(hub.module_level(id) == level, "Upgrade bonus waits until construction completes")
			hub.hub_modules[id].build_started_unix_msec -= 16000
			hub.complete_ready_builds()
			hub.complete_ready_builds()
			expect(hub.module_level(id) == level + 1, "Construction completes exactly once")
		var wallet: Dictionary = game.material_runtime.save_wallet().duplicate(true)
		expect(hub.upgrade_module(id).is_empty(), "Maximum tier cannot be purchased again")
		expect(wallet == game.material_runtime.save_wallet(), "Maximum tier spends nothing")
	game.skills = saved_skills
	hub.hub_modules = saved_modules
	# The caller installs its own wallet fixture immediately after this audit.
	game.material_runtime.set_amount("softwood", 0)
	game.material_runtime.set_amount("hardwood", 0)
	game.fishing_runtime.fish_currency = saved_fish
	SkillState.invalidate_stat_caches(game)


func audit_fresh_progression() -> void:
	for pair in [["fight", "push-ups"], ["build", "stack-bricks"], ["thieving", "borrow-cookie-permanently"], ["woodcutting", "gather-fallen-branches"], ["fishing", "shallows"]]:
		var fresh = load("res://scenes/main.tscn").instantiate()
		root.add_child(fresh)
		fresh.activity_data_catalog.load_action_data(fresh)
		fresh._save_runtime()._init_state()
		fresh._test_state_runtime()._god_mode_unlock_onboarding_state()
		var skill: String = pair[0]
		var action_id: String = pair[1]
		var action: Dictionary = fresh._action_data(skill, action_id)
		expect(fresh._activity_unlock_runtime()._is_action_unlocked(skill, action), "Starter activity is available: " + skill)
		fresh.running_skill_id = skill
		fresh.running_action_id = action_id
		seed(20261007)
		var result: Dictionary = fresh._action_runtime()._apply_offline_active_action(120.0)
		expect(int(fresh.skills[skill].xp) >= SkillState.xp_for_level(2), "Starter reaches the first level within two simulated minutes: " + skill)
		print("fresh-progression skill=", skill, " xp_after_120s=", fresh.skills[skill].xp, " completions=", result.get("successes", 0))
		fresh.free()


func audit_medal_counts(game: Node) -> void:
	var saved_mastery: Dictionary = game.mastery.duplicate(true)
	for fixture in ["empty", "mixed", "maximum"]:
		game.mastery.clear()
		var index := 0
		for skill in game.actions_by_skill:
			for action in game.actions_by_skill[skill]:
				var level: int = 0 if fixture == "empty" else (game.MASTERY_MAX_LEVEL if fixture == "maximum" else index % (game.MASTERY_MAX_LEVEL + 1))
				game.mastery[game._action_key(skill, action.id)] = {"level":level, "xp":MasteryState.xp_for_level(level)}
				index += 1
		for skill in game.actions_by_skill:
			var actions: Array = AchievementState.mastery_actions_for_skill(game, skill)
			var counts: Dictionary = AchievementState.skill_medal_counts(game, skill)
			var earned := 0
			for action in actions:
				earned += AchievementState._mastery_level_for_action(game, skill, action)
			expect(counts.earned == earned, "Medal total remains exact: " + fixture + "/" + skill)
			for tier in range(1, game.MASTERY_MAX_LEVEL + 1):
				var expected := 0
				for action in actions:
					if AchievementState._mastery_level_for_action(game, skill, action) >= tier:
						expected += 1
				expect(counts.tiers[tier - 1] == expected, "Medal tier count remains exact: %s/%s/%s" % [fixture, skill, tier])
		var fast: Dictionary = AchievementState.completed_public_ids_fast(game)
		var full := {}
		for achievement in AchievementState.milestones(game, false):
			if AchievementState.is_completed_public(achievement):
				full[achievement.id] = true
		expect(fast == full, "Completion achievement checks match the complete achievement list: " + fixture)
		SkillState.invalidate_stat_caches(game)
		var reward_milestones: Array = AchievementState.milestones(game, false)
		for stat in ["xp_mult", "success_bonus", "max_stamina", "speed_mult", "crit_chance_mult", "unknown_stat"]:
			for skill in ["", "build", "woodcutting", "thieving", "fight", "fishing"]:
				var expected_reward: float = AchievementState.global_medal_bonus(game, stat) + AchievementState.reward_bonus(reward_milestones, stat, skill)
				expect(is_equal_approx(AchievementState.global_reward_bonus(game, stat, skill), expected_reward), "Cached rewards match full calculation: %s/%s/%s" % [fixture, stat, skill])
	game.mastery = saved_mastery
	SkillState.invalidate_stat_caches(game)


func audit_medal_buff_lookup_work() -> void:
	var actions: Array = []
	for i in range(50):
		actions.append({"id": "activity-%s" % i, "name": "Activity %s" % i})
	for fixture in [{"effect":"time", "lookups":3, "raw":0.042}, {"effect":"accuracy", "lookups":5, "raw":3.0}, {"effect":"stamina", "lookups":8, "raw":0.072}, {"effect":"xp", "lookups":0, "raw":0.0}]:
		var queried: Array[String] = []
		var contributions: Array = AchievementState._medal_buff_contributions(actions, 25, fixture.effect, func(id: String) -> int:
			queried.append(id)
			return 2
		, 20)
		var total := 0.0
		for contribution in contributions:
			total += float(contribution.amount)
		expect(is_equal_approx(total, fixture.raw), "Neighboring medals retain the exact contribution: " + fixture.effect)
		expect(queried.size() == fixture.lookups, "Only contributing neighbors require mastery lookups: " + fixture.effect)


func audit_module_group_detection(detail) -> void:
	var branch := Control.new()
	var wrapper := Control.new()
	var note := Control.new()
	branch.add_child(wrapper)
	wrapper.add_child(note)
	note.add_to_group("performance_test_tip")
	expect(detail._detail_control_has_any_group(branch, ["performance_test_tip"]), "Detached tutorial descendants are detected")
	root.add_child(branch)
	expect(detail._detail_control_has_any_group(branch, ["performance_test_tip"]), "Mounted tutorial descendants are detected")
	note.remove_from_group("performance_test_tip")
	expect(not detail._detail_control_has_any_group(branch, ["performance_test_tip"]), "Removed tutorial groups are reflected immediately")
	branch.add_to_group("performance_test_tip")
	expect(detail._detail_control_has_any_group(branch, ["performance_test_tip"]), "The control itself can carry a tutorial group")
	branch.remove_from_group("performance_test_tip")
	var outside := Control.new()
	root.add_child(outside)
	outside.add_to_group("performance_test_tip")
	expect(not detail._detail_control_has_any_group(branch, ["performance_test_tip"]), "Other modules' tips do not exclude this module")
	outside.free()
	var non_control := Node.new()
	branch.add_child(non_control)
	wrapper.remove_child(note)
	non_control.add_child(note)
	note.add_to_group("performance_test_tip")
	expect(not detail._detail_control_has_any_group(branch, ["performance_test_tip"]), "Non-Control branches retain their previous semantics")
	branch.free()


func audit_deferred_stat_refresh(game: Node) -> void:
	var performance = game._performance_runtime()
	var detail = game._skill_detail_surface()
	var previous_screen: String = game.current_screen
	var previous_skill: String = game.selected_skill_id
	var previous_mounted: bool = detail.detail_lazy_mounted_this_frame
	var previous_elapsed: float = performance.ui_static_refresh_elapsed
	game.current_screen = "skill"
	game.selected_skill_id = "fight"
	detail.detail_lazy_mounted_this_frame = true
	performance.request_ui_static_refresh()
	expect(not performance._consume_ui_static_refresh(0.016, false), "Queued stats do not compete with a card mount")
	detail.detail_lazy_mounted_this_frame = false
	expect(performance._consume_ui_static_refresh(0.016, false), "Queued stats refresh on the next frame without card work")
	expect(not performance._consume_ui_static_refresh(0.016, false), "The queued refresh is consumed once")
	detail.detail_lazy_mounted_this_frame = true
	expect(performance._consume_ui_static_refresh(0.0, true), "Explicit instant refreshes still happen immediately")
	game.current_screen = previous_screen
	game.selected_skill_id = previous_skill
	detail.detail_lazy_mounted_this_frame = previous_mounted
	performance.ui_static_refresh_elapsed = previous_elapsed
