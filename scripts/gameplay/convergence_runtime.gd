extends RefCounted

const SaveStateNormalizers = preload("res://scripts/save_state/normalizers.gd")
const AchievementState = preload("res://scripts/achievements/state.gd")
const GameFormatting = preload("res://scripts/core/formatting.gd")

const CONVERGENCE_MODULE_KIND := "convergence_module"
const CONVERGENCE_DEFAULT_MODULE_ID := "five-fold-shrine-1"
const CONVERGENCE_SKILL_ORDER := ["fight", "thieving", "build", "woodcutting", "fishing"]

var host
var convergence_state_dirty := true
var convergence_modules := {}


func _init(host_node) -> void:
	host = host_node


func _is_convergence_action(action: Dictionary) -> bool:
	return str(action.get("kind", "activity")) == CONVERGENCE_MODULE_KIND


func _convergence_config(action: Dictionary) -> Dictionary:
	return action.get("convergence", {}) as Dictionary


func _convergence_requires_build(action: Dictionary) -> bool:
	var config := _convergence_config(action)
	return bool(config.get("build_required", true))


func _convergence_bar_pattern(action: Dictionary) -> String:
	var config := _convergence_config(action)
	return str(config.get("bar_pattern", "loops"))


func _ensure_convergence_state(module_id: String) -> Dictionary:
	if module_id.is_empty():
		module_id = CONVERGENCE_DEFAULT_MODULE_ID
	var action: Dictionary = host._action_data("build", module_id)
	var requires_build := true
	if not action.is_empty() and _is_convergence_action(action):
		requires_build = _convergence_requires_build(action)
	if not convergence_modules.has(module_id) or typeof(convergence_modules[module_id]) != TYPE_DICTIONARY:
		convergence_modules[module_id] = {
			"built": not requires_build,
			"building": false,
			"build_started_unix": 0,
			"completions": 0
		}
	var state := convergence_modules[module_id] as Dictionary
	state["built"] = bool(state.get("built", false))
	state["building"] = bool(state.get("building", false))
	state["build_started_unix"] = maxi(0, int(state.get("build_started_unix", 0)))
	state["completions"] = maxi(0, int(state.get("completions", 0)))
	if not requires_build:
		state["built"] = true
		state["building"] = false
		state["build_started_unix"] = 0
	elif bool(state.get("building", false)) and _convergence_build_remaining(module_id) <= 0:
		state["built"] = true
		state["building"] = false
	convergence_modules[module_id] = state
	return state


func _process_convergence_modules() -> void:
	if not convergence_state_dirty:
		return
	convergence_state_dirty = false
	for raw_module_id in host.convergence_action_ids:
		_ensure_convergence_state(str(raw_module_id))


func _convergence_build_seconds(action: Dictionary) -> int:
	var config := _convergence_config(action)
	return maxi(1, int(config.get("build_seconds", 300)))


func _convergence_log_cost(action: Dictionary) -> int:
	var config := _convergence_config(action)
	var fallback := 100
	var costs = action.get("costs", {})
	if typeof(costs) == TYPE_DICTIONARY:
		fallback = int((costs as Dictionary).get("logs", fallback))
	return maxi(0, int(config.get("log_cost", fallback)))


func _convergence_build_remaining(module_id: String) -> int:
	var action: Dictionary = host._action_data("build", module_id)
	var state := convergence_modules.get(module_id, {}) as Dictionary
	if action.is_empty() or state.is_empty() or not bool(state.get("building", false)):
		return 0
	var finish_unix := int(state.get("build_started_unix", 0)) + _convergence_build_seconds(action)
	return maxi(0, finish_unix - host._unix_now())


func _convergence_is_built(module_id: String) -> bool:
	return bool(_ensure_convergence_state(module_id).get("built", false))


func _convergence_is_building(module_id: String) -> bool:
	return bool(_ensure_convergence_state(module_id).get("building", false))


func _start_convergence_build(module_id: String) -> bool:
	var action: Dictionary = host._action_data("build", module_id)
	if action.is_empty() or not host._activity_unlock_runtime()._is_action_unlocked("build", action):
		return false
	if not _convergence_requires_build(action):
		var ready_state := _ensure_convergence_state(module_id)
		ready_state["built"] = true
		ready_state["building"] = false
		convergence_modules[module_id] = ready_state
		return true
	var state := _ensure_convergence_state(module_id)
	if bool(state.get("built", false)):
		return true
	if bool(state.get("building", false)):
		host._reward_feedback_surface()._set_result("%s building: %s left." % [str(action.get("name", "Shrine")), GameFormatting.countdown(_convergence_build_remaining(module_id))])
		return false
	var cost := _convergence_log_cost(action)
	if host.material_runtime.amount("softwood") < float(cost):
		host._reward_feedback_surface()._set_result("%s needs %s Softwood." % [str(action.get("name", "Shrine")), cost])
		return false
	host.material_runtime.spend_amount("softwood", float(cost))
	state["building"] = true
	state["built"] = false
	state["build_started_unix"] = host._unix_now()
	convergence_modules[module_id] = state
	host._reward_feedback_surface()._set_result("%s construction started. %s left." % [str(action.get("name", "Shrine")), GameFormatting.countdown(_convergence_build_seconds(action))])
	host.save_game()
	return false


func _convergence_skill_order(action: Dictionary) -> Array:
	var config := _convergence_config(action)
	var order = config.get("skill_order", CONVERGENCE_SKILL_ORDER)
	if typeof(order) == TYPE_ARRAY and (order as Array).size() >= 5:
		return (order as Array).slice(0, 5)
	return CONVERGENCE_SKILL_ORDER.duplicate()


func _convergence_segment_progress(action: Dictionary, progress: float) -> Array:
	var values := []
	var remaining := clampf(progress, 0.0, 1.0) * _convergence_total_cycle_seconds(action)
	for raw_skill_id in _convergence_skill_order(action):
		var segment_seconds := _convergence_segment_seconds(str(raw_skill_id), action)
		values.append(clampf(remaining / segment_seconds, 0.0, 1.0))
		remaining -= segment_seconds
	return values


func _convergence_total_cycle_seconds(action: Dictionary) -> float:
	var total := 0.0
	for raw_skill_id in _convergence_skill_order(action):
		total += _convergence_segment_seconds(str(raw_skill_id), action)
	return maxf(1.0, total)


func _convergence_segment_seconds(skill_id: String, action: Dictionary) -> float:
	var config := _convergence_config(action)
	var level_10_seconds := maxf(1.0, float(config.get("segment_level_10_seconds", 20.0)))
	var level := maxf(1.0, float(SkillState.host_skill_level(host, skill_id)))
	return maxf(3.0, level_10_seconds * 10.0 / level)


func _convergence_current_xp(module_id: String) -> int:
	var action: Dictionary = host._action_data("build", module_id)
	var config := _convergence_config(action)
	var min_xp := maxi(1, int(config.get("xp_min", 1)))
	var max_xp := maxi(min_xp, int(config.get("xp_max", 15)))
	var curve := maxf(0.001, float(config.get("xp_curve", 0.09)))
	var completions := int(_ensure_convergence_state(module_id).get("completions", 0))
	var reward := float(max_xp) - float(max_xp - min_xp) * exp(-curve * float(completions))
	return clampi(int(round(reward)), min_xp, max_xp)


func _complete_convergence_cycle(module_id: String) -> int:
	var action: Dictionary = host._action_data("build", module_id)
	if action.is_empty():
		return 0
	var old_levels := {}
	var completed_achievements_before: Dictionary = AchievementState.completed_public_ids_fast(host)
	for raw_skill_id in _convergence_skill_order(action):
		old_levels[str(raw_skill_id)] = SkillState.host_skill_level(host, str(raw_skill_id))
	var xp_reward := _convergence_current_xp(module_id)
	for raw_skill_id in _convergence_skill_order(action):
		var skill_id := str(raw_skill_id)
		if not host.skills.has(skill_id):
			continue
		host.skills[skill_id]["xp"] = int(host.skills[skill_id].get("xp", 0)) + xp_reward
		SkillState.recalculate_level(host, skill_id)
	var state := _ensure_convergence_state(module_id)
	state["completions"] = int(state.get("completions", 0)) + 1
	convergence_modules[module_id] = state
	host._passive_modules_runtime().sync_passive_module_unlocks(host._unix_now())
	host.last_result = "%s complete: +%s XP to every skill." % [str(action.get("name", "Shrine")), xp_reward]
	for achievement in AchievementState.newly_completed_fast(host, completed_achievements_before):
		host._achievement_toast_surface().show_unlocked(achievement)
	var leveled := false
	for raw_skill_id in _convergence_skill_order(action):
		var skill_id := str(raw_skill_id)
		if SkillState.host_skill_level(host, skill_id) > int(old_levels.get(skill_id, 1)):
			leveled = true
			break
	host._reward_feedback_surface()._play_action_feedback(host._action_key("build", module_id), true, xp_reward, 0.0, false, false)
	host._audio_director()._play_activity_success_sound(1, leveled, false, false, false, 0)
	host._audio_director()._record_music_flow_action(true, 1, false, false, leveled, 0.0)
	host.save_game()
	return xp_reward


func _restore_convergence_modules_from_save(data: Dictionary) -> void:
	convergence_modules = _normalized_convergence_modules(data.get("convergence_modules", {}))


func _convergence_modules_for_save() -> Dictionary:
	return _normalized_convergence_modules(convergence_modules)


func _normalized_convergence_modules(loaded_modules: Variant) -> Dictionary:
	return SaveStateNormalizers.normalized_convergence_modules(loaded_modules, Callable(host, "_action_data"), Callable(self, "_is_convergence_action"))
