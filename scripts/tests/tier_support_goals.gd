extends SceneTree

const AchievementState := preload("res://scripts/achievements/state.gd")

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var database = JSON.parse_string(FileAccess.get_file_as_string("res://docs/activity-database.json"))
	_expect(database is Dictionary, "activity database should parse")
	var documented_goals: Array = (database as Dictionary).get("global_rules", {}).get("tier_support_goals", [])
	_expect(documented_goals.size() == AchievementState.TIER_SUPPORT_GOALS.size(), "documented and runtime goal counts should match")
	for index in mini(documented_goals.size(), AchievementState.TIER_SUPPORT_GOALS.size()):
		var documented := documented_goals[index] as Dictionary
		var runtime := AchievementState.TIER_SUPPORT_GOALS[index] as Dictionary
		_expect(int(documented.get("medal_level", 0)) == int(runtime.get("medal_level", -1)), "medal levels should match")
		_expect(str(documented.get("stat", "")) == str(runtime.get("stat", "")), "reward stats should match")
		_expect(is_equal_approx(float(documented.get("amount", 0.0)), float(runtime.get("amount", -1.0))), "reward amounts should match")

	for action_count in range(1, 11):
		var medal_tiers := []
		medal_tiers.resize(20)
		medal_tiers.fill(0)
		var goals := AchievementState.tier_support_goals_from_counts({"actions": action_count, "tiers": medal_tiers}, 2)
		_expect(goals.size() == 3, "each tier should have three support goals")
		for raw_goal in goals:
			var goal := raw_goal as Dictionary
			_expect(int(goal.get("possible", 0)) == action_count, "goal target should equal the tier activity count")
			_expect(not bool(goal.get("completed", true)), "an unearned goal should remain incomplete")

		for medal_index in range(3):
			medal_tiers[medal_index] = action_count
		goals = AchievementState.tier_support_goals_from_counts({"actions": action_count, "tiers": medal_tiers}, 2)
		for raw_goal in goals:
			_expect(bool((raw_goal as Dictionary).get("completed", false)), "every goal should be attainable for every tier size")

	print("tier-support-goals-ok")
	quit(1 if failed else 0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
