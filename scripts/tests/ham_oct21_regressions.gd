extends SceneTree

const SkillState = preload("res://scripts/progression/skill_state.gd")
const MasteryState = preload("res://scripts/progression/mastery_state.gd")
const AchievementState = preload("res://scripts/achievements/state.gd")
const RecoveryModules = preload("res://scripts/gameplay/recovery_modules.gd")
const GameFormatting = preload("res://scripts/core/formatting.gd")
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
	game.set_process(false)
	game.activity_data_catalog.load_action_data(game)
	game._save_runtime()._init_state()
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._audio_director().music_muted = true
	game._audio_director().sfx_muted = true
	game.auto_unlock_lockpads_enabled = false
	for skill in game.skill_defs:
		game.skills[skill.id] = {"xp": SkillState.xp_for_level(99), "level": 99}
		for action in game.actions_by_skill[skill.id]:
			game._activity_unlock_runtime()._mark_action_manually_unlocked(skill.id, action.id)
	game.fishing_runtime.fish_currency = 0.0
	game.material_runtime.set_amount("candy", 0)
	var runtime = game._action_runtime()
	var hub = game._hub_runtime()
	hub.hub_modules.mission = {"level":4,"building":false}
	SkillState.invalidate_stat_caches(game)
	var tested_recovery := 0
	for skill in game.skill_defs:
		for action in game.actions_by_skill[skill.id]:
			if not RecoveryModules.has_recovery(action):
				continue
			for mission in [false, true]:
				for other in game.skill_defs:
					game.stamina[other.id] = float(SkillState.max_stamina(game, other.id))
					game.stamina_bank[other.id] = 0.0
				game.stamina[skill.id] = 1.0
				hub.hub_missions = [{"skill_id":skill.id,"action_id":action.id,"target":2,"remaining":2,"rep_balance_version":1}] if mission else []
				hub.hub_mission_cooldowns.clear()
				hub.hub_mission_cooldown_until_unix = 0
				runtime.invalidate_stat_cache()
				game.running_skill_id = skill.id
				game.running_action_id = action.id
				game.action_progress = 0.0
				runtime._process_action(runtime._action_cycle_seconds(skill.id, action) + 0.01)
				var expected := 1.0 + float(action.recovery.stamina)
				check(is_equal_approx(float(game.stamina[skill.id]), expected), "Live recovery with mission=%s: %s" % [mission, action.id])
				if mission:
					check(hub.hub_missions.size() == 1 and int(hub.hub_missions[0].remaining) == 1, "Recovery must advance its mission exactly once: " + str(action.id))
				game.stamina[skill.id] = 1.0
				runtime._grant_offline_action_completion(skill.id, action.id, action)
				check(is_equal_approx(float(game.stamina[skill.id]), expected), "Offline recovery with mission=%s: %s" % [mission, action.id])
				tested_recovery += 1
	game.running_skill_id = ""
	game.running_action_id = ""
	# Independent deadlines: a second completion cannot postpone the first slot.
	hub.hub_missions = [
		{"skill_id":"fight","action_id":"push-ups","target":1,"remaining":1,"rep_balance_version":1},
		{"skill_id":"build","action_id":"hammer-nails","target":1,"remaining":1,"rep_balance_version":1}]
	hub.hub_mission_cooldowns = [game._unix_now() + 30]
	hub._sync_mission_cooldown_summary()
	var first_deadline: int = hub.hub_mission_cooldown_until_unix
	hub.record_mission_action_completion("fight", "push-ups")
	check(hub.hub_mission_cooldown_until_unix == first_deadline, "Finishing another mission must preserve the first deadline")
	check(hub.hub_mission_cooldowns.size() == 2, "Each completed mission must retain its own timer")
	var payload: Dictionary = game._save_runtime()._save_payload(game._unix_now())
	var before: Array = hub.hub_mission_cooldowns.duplicate()
	hub.restore_mission_cooldown(payload)
	check(hub.hub_mission_cooldowns == before, "All independent deadlines must survive save/restore")
	hub.hub_mission_cooldowns = [game._unix_now() - 1, game._unix_now() + 60]
	hub._sync_mission_cooldown_summary()
	hub.sync_missions()
	check(hub.hub_missions.size() == 3 and hub.hub_mission_cooldowns.size() == 1, "Only the expired slot and genuinely empty slots refill")
	hub.hub_missions.resize(2)
	hub.hub_mission_cooldowns.clear()
	hub.hub_mission_cooldown_until_unix = game._unix_now() + 60
	hub.sync_missions()
	check(hub.hub_mission_cooldowns.size() == 2, "Legacy shared cooldown must migrate without resetting its deadline")
	hub.hub_missions = [{"skill_id":"fight","action_id":"push-ups","target":1,"remaining":1,"rep_balance_version":1}]
	hub.hub_mission_cooldowns.clear()
	hub.hub_mission_cooldown_until_unix = game._unix_now() + 15
	var legacy_deadline: int = hub.hub_mission_cooldown_until_unix
	hub.record_mission_action_completion("fight","push-ups")
	check(hub.hub_mission_cooldown_until_unix == legacy_deadline and hub.hub_mission_cooldowns.size() == 4, "A completion before the first sync must preserve old-save waiting slots")
	# All Thieving actions retain the old formula at several medal/hub states.
	for medal_level in [0, 3, 10, 20]:
		for barn_level in [0, 4]:
			game.mastery.clear()
			hub.hub_modules.barn = {"level":barn_level,"building":false}
			for action in game.actions_by_skill.thieving:
				if MasteryState.action_has_mastery(game, action):
					game.mastery["thieving:" + str(action.id)] = {"xp":MasteryState.xp_for_level(medal_level),"level":medal_level}
			SkillState.invalidate_stat_caches(game)
			for action in game.actions_by_skill.thieving:
				if game._convergence_runtime()._is_convergence_action(action):
					continue
				var old_nominal := clampf(float(action.get("success",90)) + AchievementState.global_reward_bonus(game,"success_bonus","thieving") + AchievementState.activity_medal_rate_bonus(game,"thieving",action),5,100)
				var old_chance := clampf(old_nominal + (100-old_nominal)*game._hub_surface()._hub_barn_failure_factor() + hub.trophy_success_bonus()*100,5,100)
				check(is_equal_approx(runtime._success_chance("thieving",action),old_chance), "Thieving rate changed: " + str(action.id))
	check(GameFormatting.compact_inventory_number(999999.0) == "999K", "Fish count must not advertise an unaffordable million")
	check(GameFormatting.compact_inventory_number(1000000.0) == "1M", "An actual million fish must display as one million")
	check(GameFormatting.compact_inventory_number(999.9) == "999", "Fish count must not cross a thousand early")
	check(GameFormatting.compact_inventory_number(0.25) == "0.25", "Fractional fish must remain readable")
	# High base chances are no longer compressed by a hidden global curve.
	game.mastery.clear()
	hub.hub_modules.barn = {"level": 0, "building": false}
	var probe: Dictionary = game._action_data("build", "stack-bricks").duplicate(true)
	for nominal in [50.0, 90.0, 95.0, 100.0]:
		probe["id"] = "success-base-probe"
		probe["success"] = nominal
		SkillState.invalidate_stat_caches(game)
		check(is_equal_approx(runtime._success_chance("build", probe), nominal), "High base success is not compressed: " + str(nominal))
	print("ham-oct21-regressions recovery_cases=", tested_recovery, " failures=", failures)
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
