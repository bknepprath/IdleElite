extends SceneTree
const Unlock = preload("res://scripts/gameplay/activity_unlock_runtime.gd")
const SkillState = preload("res://scripts/progression/skill_state.gd")
class ProgressHost:
	extends Node
	var actions_by_skill := {"fight": [{"id": "first", "unlock": 1}, {"id": "previous", "unlock": 50}, {"id": "target", "unlock": 56}, {"id": "same-level", "unlock": 56}], "build": [{"id": "first", "unlock": 1}]}
	var skills := {"fight": {"xp": 0}, "build": {"xp": 0}}
func _init() -> void:
	var host := ProgressHost.new()
	var runtime := Unlock.new(host)
	var start := SkillState.xp_for_level(50)
	var target := SkillState.xp_for_level(56)
	host.skills.fight.xp = start
	assert(runtime._level_requirement_progress("fight", 56) == 0.0)
	host.skills.fight.xp = (start + target) / 2.0
	assert(is_equal_approx(runtime._level_requirement_progress("fight", 56), 0.5))
	host.skills.fight.xp = target
	assert(runtime._level_requirement_progress("fight", 56) == 1.0)
	host.skills.fight.xp = 0
	assert(runtime._level_requirement_progress("fight", 56) == 0.0)
	host.skills.fight.xp = target * 2
	assert(runtime._level_requirement_progress("fight", 56) == 1.0)
	host.skills.build.xp = 11
	assert(runtime._level_requirement_progress("build", 2) == 0.5)
	assert(runtime._level_requirement_progress("build", 1) == 1.0)
	host.free()
	print("unlock-progress-interval: PASS")
	quit()
