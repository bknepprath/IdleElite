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
	var action: Dictionary = game._action_data("fishing", "practice-pool")
	expect(not action.is_empty(), "Practice Pool must load from database")
	expect(not game._activity_unlock_runtime()._is_action_unlocked("fishing", action), "Practice Pool must be locked at level 1")
	game.skills.fishing.xp = SkillState.xp_for_level(2)
	game.skills.fishing.level = 2
	game._activity_unlock_runtime()._mark_action_manually_unlocked("fishing", "practice-pool")
	expect(game._activity_unlock_runtime()._is_action_unlocked("fishing", action), "Practice Pool must unlock at level 2")
	expect(game.fishing_runtime.action_should_render_standalone(game, "fishing", action), "Practice Pool must use normal activity UI")
	game.fishing_runtime.fish_currency = 12.0
	game.stamina.fishing = 0.0
	for tool in ["hands", "net", "line", "reinforced_rod", "star_rod", "boat", "mirror"]:
		game.fishing_runtime.equipped_tool_id = tool
		runtime.invalidate_stat_cache()
		expect(is_equal_approx(runtime._action_cycle_seconds("fishing", action), 3.0), "Training must ignore tool speed: " + tool)
		expect(runtime._effective_stamina("fishing", action) == 0.0, "Training must remain stamina-free")
		expect(runtime._success_chance("fishing", action) == 100.0, "Training must ignore catch tool success: " + tool)
		expect(game.fishing_runtime.roll_fish_count(game, action, tool) == 0, "Training must not catch fish: " + tool)
		expect(game.fishing_runtime.flat_xp_reward(game, action, "fishing") == 3, "Training must ignore tool XP multiplier: " + tool)
		var xp_before: int = game.skills.fishing.xp
		var result: Dictionary = runtime._grant_offline_action_completion("fishing", "practice-pool", action, true)
		expect(int(result.xp) > 0 and game.skills.fishing.xp > xp_before, "Offline training must award XP: " + tool)
		expect(float(result.fish) == 0.0 and game.fishing_runtime.fish_currency == 12.0, "Offline training must not award fish: " + tool)
		game.running_skill_id = "fishing"
		game.running_action_id = "practice-pool"
		game.action_progress = 0.0
		xp_before = game.skills.fishing.xp
		runtime._process_action(3.1)
		expect(game.skills.fishing.xp > xp_before, "Live training must award XP: " + tool)
		expect(game.fishing_runtime.fish_currency == 12.0 and game.stamina.fishing == 0.0, "Live training must not change fish or stamina: " + tool)
		expect(game.fishing_runtime.net_stored_fish == 0 and game.fishing_runtime.boat_stored_fish == 0, "Training must not fill tool storage")
	var queue = game._activity_queue_runtime()
	queue.activity_queue = ["action:fishing:practice-pool", "action:fishing:shallows"]
	queue.activity_queue_running = true
	queue.activity_queue_index = 0
	queue.activity_queue_attempt_key = "action:fishing:practice-pool"
	queue.fishing_attempt_completed = false
	game.running_skill_id = "fishing"
	game.running_action_id = "practice-pool"
	game.action_progress = 0.0
	runtime._process_action(3.1)
	expect(queue.fishing_attempt_completed, "Training must complete its queue attempt")
	queue._process_activity_queue_runtime()
	expect(game.running_action_id == "shallows", "Fishing queue must advance after training")
	queue._stop_activity_queue_runtime(true)
	queue.activity_queue.clear()
	game.running_skill_id = ""
	game.running_action_id = ""
	game.fishing_runtime.equipped_tool_id = "hands"
	runtime.invalidate_stat_cache()
	var training_rate: float = 3.0 / 3.0
	var shallows: Dictionary = game._action_data("fishing", "shallows")
	var catch_rate: float = float(game.fishing_runtime.flat_xp_reward(game, shallows, "fishing")) * runtime._success_chance("fishing", shallows) / 100.0 / runtime._action_cycle_seconds("fishing", shallows)
	expect(training_rate > catch_rate, "Practice XP must exceed starter catch XP")
	for pair in [["fight", "kick-mud-off-boot"], ["build", "hammer-nails"], ["thieving", "sneak-past-tip-jar"]]:
		var other: Dictionary = game._action_data(pair[0], pair[1])
		expect(not other.is_empty(), "Comparison activity must exist: " + str(pair))
		var rate: float = float(runtime._effective_xp(other, pair[0])) * runtime._success_chance(pair[0], other) / 100.0 / runtime._action_cycle_seconds(pair[0], other)
		expect(training_rate < rate, "Training must remain slower than stamina activity: " + str(pair))
		print("feedback-rate ", pair, " xp/min=", rate * 60.0)
	print("feedback-rate training=60/min shallows=", catch_rate * 60.0)
	game.skills.thieving.level = 20
	game.skills.thieving.xp = SkillState.xp_for_level(20)
	game._activity_unlock_runtime()._mark_action_manually_unlocked("thieving", "count-the-coins")
	var recovery: Dictionary = game._action_data("thieving", "count-the-coins")
	expect(RecoveryModules.has_recovery(recovery), "Count The Coins must remain recovery")
	var legacy := {"skill_id":"thieving", "action_id":"count-the-coins", "target":133, "remaining":100, "assigned_unix":123}
	var migrated: Dictionary = hub.normalized_mission(legacy)
	expect(migrated.target == 34 and migrated.remaining == 25, "Existing recovery assignments must shrink by 75%, rounded up")
	expect(hub.normalized_mission(migrated) == migrated, "Recovery migration must be idempotent")
	hub.restore_missions([migrated])
	var saved: Array = hub.missions_for_save()
	hub.restore_missions(saved)
	expect(hub.hub_missions == saved, "Saving/reloading must not shrink again")
	var normal := {"skill_id":"fight", "action_id":"push-ups", "target":133, "remaining":100}
	var normalized: Dictionary = hub.normalized_mission(normal)
	expect(normalized.target == 133 and normalized.remaining == 100, "Normal missions must retain their counts")
	expect(HubRuntime.mission_target_for_action(recovery, 1) == 1, "Recovery targets must remain positive")
	for skill in game.skill_defs:
		for candidate in game.actions_by_skill[skill.id]:
			if RecoveryModules.has_recovery(candidate):
				expect(HubRuntime.mission_target_for_action(candidate, 100) == 25, "All recovery actions need the reduction")
	# Force a new recovery roll by excluding every other eligible assignment.
	game.skills.build.level = 10
	game.skills.build.xp = SkillState.xp_for_level(10)
	hub.hub_modules.mission = {"level": 1, "building": false}
	hub.hub_missions.clear()
	for choice in hub.mission_eligible_actions({}):
		if choice.action_id != "count-the-coins":
			hub.hub_missions.append(choice)
	var rolled: Dictionary = hub.roll_mission()
	expect(rolled.get("action_id") == "count-the-coins", "Recovery mission must be eligible")
	expect(int(rolled.get("target", 0)) >= ceili(hub.mission_rep_min() * 0.25) and int(rolled.get("target", 0)) <= ceili(hub.mission_rep_max() * 0.25), "New recovery mission must use reduced range")
	expect(hub.normalized_mission(rolled).target == rolled.target, "New missions must not migrate twice")
	var save = game._save_runtime()
	save.fishing_help_seen = true
	var payload: Dictionary = save._save_payload(game._unix_now())
	expect(payload.get("fishing_help_seen", false), "Help acknowledgement must be saved")
	save._restore_boot_visible_tip_flags_from_save({})
	expect(not save.fishing_help_seen, "Old saves must receive fishing help")
	save._restore_boot_visible_tip_flags_from_save(payload)
	expect(save.fishing_help_seen, "Acknowledged help must remain seen after reload")
	print("feedback-balance failures=", failures)
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
