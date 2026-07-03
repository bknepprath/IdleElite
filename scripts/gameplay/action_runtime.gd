extends RefCounted

const BuildableModules = preload("res://scripts/gameplay/buildable_modules.gd")
const RecoveryModules = preload("res://scripts/gameplay/recovery_modules.gd")
const AchievementState = preload("res://scripts/achievements/state.gd")
const MasteryState = preload("res://scripts/progression/mastery_state.gd")
const FishingState = preload("res://scripts/fishing/state.gd")
const GameFormatting = preload("res://scripts/core/formatting.gd")

var host
var action_progress_speed_key := ""
var action_progress_speed_mult_current := 1.0
var stat_cache_version := 0
var action_stat_value_cache := {}


func _init(host_ref) -> void:
	host = host_ref


static func uses_diamond_arena(action: Dictionary) -> bool:
	var combat: Variant = action.get("combat", {})
	if typeof(combat) != TYPE_DICTIONARY:
		return false
	return str((combat as Dictionary).get("arena_shape", "")).to_lower() == "diamond"


func _action_opportunity_frame_work_needed() -> bool:
	return (
		host.action_opportunity_boost_seconds > 0.0
		or host.action_opportunity_miss_expand_elapsed < host.ACTION_OPPORTUNITY_MISS_EXPAND_SECONDS
		or host.action_opportunity_emerald_transition_elapsed < host.ACTION_OPPORTUNITY_EMERALD_SHRINK_SECONDS
		or host.action_opportunity_ruby_transition_elapsed < host.ACTION_OPPORTUNITY_RUBY_MOVE_SECONDS
	)


func _action_opportunity_windows(skill_id: String, action_id: String) -> Array[Vector2]:
	return _action_opportunity_pattern_windows(skill_id, action_id)


func _action_opportunity_pattern_windows(skill_id: String, action_id: String) -> Array[Vector2]:
	var windows := _action_opportunity_raw_pattern_windows(skill_id, action_id)
	windows = _action_opportunity_apply_miss_expansion(windows)
	return _action_opportunity_apply_speed_forgiveness(skill_id, action_id, windows)


func _action_opportunity_raw_pattern_windows(skill_id: String, action_id: String) -> Array[Vector2]:
	var medal_level: int = int(MasteryState.level(host.mastery, host._action_key(skill_id, action_id)))
	if medal_level < host.ACTION_OPPORTUNITY_MIN_MEDAL_LEVEL:
		return []
	if (
		_action_opportunity_uses_persistent_window(skill_id, action_id)
		and host.action_opportunity_persistent_key == host._action_key(skill_id, action_id)
		and not host.action_opportunity_persistent_windows.is_empty()
	):
		return host.action_opportunity_persistent_windows.duplicate()
	if medal_level >= host.ACTION_OPPORTUNITY_DIAMOND_MIN_MEDAL_LEVEL:
		return [_action_opportunity_diamond_window()]
	if medal_level >= host.ACTION_OPPORTUNITY_RUBY_MIN_MEDAL_LEVEL:
		return [_action_opportunity_ruby_window()]
	if medal_level >= host.ACTION_OPPORTUNITY_EMERALD_MIN_MEDAL_LEVEL:
		return [_action_opportunity_emerald_window()]
	if medal_level >= host.ACTION_OPPORTUNITY_SAPPHIRE_MIN_MEDAL_LEVEL:
		return [_action_opportunity_sapphire_window()]
	if medal_level >= host.ACTION_OPPORTUNITY_PLATINUM_MIN_MEDAL_LEVEL:
		return [host.ACTION_OPPORTUNITY_PLATINUM_WINDOW]
	if medal_level >= host.ACTION_OPPORTUNITY_GOLD_MIN_MEDAL_LEVEL:
		return [_action_opportunity_gold_window()]
	return [host.ACTION_OPPORTUNITY_SILVER_WINDOW]


func _action_opportunity_apply_speed_forgiveness(skill_id: String, action_id: String, windows: Array[Vector2]) -> Array[Vector2]:
	if windows.is_empty():
		return []
	var effective_cycle_seconds := _action_opportunity_effective_cycle_seconds(skill_id, action_id)
	if effective_cycle_seconds <= 0.0:
		return windows.duplicate()
	var adjusted: Array[Vector2] = []
	for raw_window in windows:
		var window := raw_window as Vector2
		var width := clampf(window.y - window.x, 0.0, 1.0)
		if width <= 0.001:
			continue
		var window_seconds := width * effective_cycle_seconds
		var cramped := inverse_lerp(
			host.ACTION_OPPORTUNITY_FORGIVENESS_IDEAL_SECONDS,
			host.ACTION_OPPORTUNITY_FORGIVENESS_MIN_SECONDS,
			window_seconds
		)
		var forgiveness := smoothstep(0.0, 1.0, clampf(cramped, 0.0, 1.0))
		if forgiveness <= 0.001:
			adjusted.append(window)
			continue
		var next_width := clampf(
			width * (1.0 + host.ACTION_OPPORTUNITY_FORGIVENESS_MAX_EXTRA_WIDTH * forgiveness),
			width,
			1.0
		)
		adjusted.append(_action_opportunity_resize_window(window, next_width))
	return adjusted


func _action_opportunity_apply_miss_expansion(windows: Array[Vector2]) -> Array[Vector2]:
	if windows.is_empty() or host.action_opportunity_miss_expand_per_side <= 0.0001:
		return windows.duplicate()
	var adjusted: Array[Vector2] = []
	for raw_window in windows:
		var window := raw_window as Vector2
		var width := clampf(window.y - window.x, 0.0, 1.0)
		if width <= 0.001:
			continue
		var next_width := clampf(width + host.action_opportunity_miss_expand_per_side * 2.0, width, 1.0)
		adjusted.append(_action_opportunity_resize_window(window, next_width))
	return adjusted


func _action_opportunity_effective_cycle_seconds(skill_id: String, action_id: String) -> float:
	if host.running_skill_id != skill_id or host.running_action_id != action_id:
		return 0.0
	var action: Dictionary = host._action_data(skill_id, action_id)
	if action.is_empty():
		return 0.0
	var speed_mult := maxf(0.01, maxf(1.0, action_progress_speed_mult_current))
	return _action_cycle_seconds(skill_id, action) / speed_mult


func _action_opportunity_resize_window(window: Vector2, next_width: float) -> Vector2:
	var width := clampf(next_width, 0.0, 1.0)
	var current_width := clampf(window.y - window.x, 0.0, 1.0)
	var center := (window.x + window.y) * 0.5
	if window.x <= 0.001:
		return Vector2(0.0, width)
	if window.y >= 0.999:
		return Vector2(1.0 - width, 1.0)
	var left := clampf(center - width * 0.5, 0.0, 1.0 - width)
	var right := left + width
	if current_width >= 0.999:
		return Vector2(0.0, 1.0)
	return Vector2(left, right)


func _action_opportunity_sapphire_window() -> Vector2:
	var width: float = host.ACTION_OPPORTUNITY_SILVER_WINDOW.y - host.ACTION_OPPORTUNITY_SILVER_WINDOW.x
	var start_left: float = 1.0 - width
	var stop_left: float = host.ACTION_OPPORTUNITY_SAPPHIRE_LEFT_STOP
	var slide_t := smoothstep(0.0, 1.0, clampf(host.action_opportunity_cycle_elapsed / host.ACTION_OPPORTUNITY_SAPPHIRE_SLIDE_SECONDS, 0.0, 1.0))
	var left := lerpf(start_left, stop_left, slide_t)
	return Vector2(left, left + width)


func _action_opportunity_emerald_window() -> Vector2:
	return host.action_opportunity_emerald_window


func _action_opportunity_ruby_window() -> Vector2:
	var left := clampf(host.action_opportunity_ruby_left, 0.0, 1.0 - host.ACTION_OPPORTUNITY_RUBY_WINDOW_WIDTH)
	return Vector2(left, left + host.ACTION_OPPORTUNITY_RUBY_WINDOW_WIDTH)


func _action_opportunity_emerald_target_window() -> Vector2:
	var left := clampf(
		host.ACTION_OPPORTUNITY_EMERALD_MAX_WINDOW.x + float(host.action_opportunity_emerald_shrink_steps) * host.ACTION_OPPORTUNITY_EMERALD_SHRINK_PER_SUCCESS,
		host.ACTION_OPPORTUNITY_EMERALD_MAX_WINDOW.x,
		host.ACTION_OPPORTUNITY_EMERALD_MIN_WINDOW.x
	)
	var right := clampf(
		host.ACTION_OPPORTUNITY_EMERALD_MAX_WINDOW.y - float(host.action_opportunity_emerald_shrink_steps) * host.ACTION_OPPORTUNITY_EMERALD_SHRINK_PER_SUCCESS,
		host.ACTION_OPPORTUNITY_EMERALD_MIN_WINDOW.y,
		host.ACTION_OPPORTUNITY_EMERALD_MAX_WINDOW.y
	)
	return Vector2(left, right)


func _process_action_opportunity_window_animation(delta: float) -> void:
	if host.action_opportunity_miss_expand_elapsed < host.ACTION_OPPORTUNITY_MISS_EXPAND_SECONDS:
		host.action_opportunity_miss_expand_elapsed = minf(
			host.ACTION_OPPORTUNITY_MISS_EXPAND_SECONDS,
			host.action_opportunity_miss_expand_elapsed + delta
		)
		var miss_t := clampf(host.action_opportunity_miss_expand_elapsed / host.ACTION_OPPORTUNITY_MISS_EXPAND_SECONDS, 0.0, 1.0)
		var miss_eased := 1.0 - pow(1.0 - miss_t, 3.0)
		host.action_opportunity_miss_expand_per_side = lerpf(host.action_opportunity_miss_expand_start, host.action_opportunity_miss_expand_target, miss_eased)
		if miss_t >= 1.0:
			host.action_opportunity_miss_expand_per_side = host.action_opportunity_miss_expand_target
	if host.action_opportunity_emerald_transition_elapsed < host.ACTION_OPPORTUNITY_EMERALD_SHRINK_SECONDS:
		host.action_opportunity_emerald_transition_elapsed = minf(
			host.ACTION_OPPORTUNITY_EMERALD_SHRINK_SECONDS,
			host.action_opportunity_emerald_transition_elapsed + delta
		)
		var t := clampf(host.action_opportunity_emerald_transition_elapsed / host.ACTION_OPPORTUNITY_EMERALD_SHRINK_SECONDS, 0.0, 1.0)
		var eased := 1.0 - pow(1.0 - t, 3.0)
		host.action_opportunity_emerald_window = host.action_opportunity_emerald_start_window.lerp(host.action_opportunity_emerald_target_window, eased)
		if t >= 1.0:
			host.action_opportunity_emerald_window = host.action_opportunity_emerald_target_window
	if host.action_opportunity_ruby_transition_elapsed < host.ACTION_OPPORTUNITY_RUBY_MOVE_SECONDS:
		host.action_opportunity_ruby_transition_elapsed = minf(
			host.ACTION_OPPORTUNITY_RUBY_MOVE_SECONDS,
			host.action_opportunity_ruby_transition_elapsed + delta
		)
		var ruby_t := clampf(host.action_opportunity_ruby_transition_elapsed / host.ACTION_OPPORTUNITY_RUBY_MOVE_SECONDS, 0.0, 1.0)
		var ruby_eased := 1.0 - pow(1.0 - ruby_t, 3.0)
		host.action_opportunity_ruby_left = lerpf(host.action_opportunity_ruby_start_left, host.action_opportunity_ruby_target_left, ruby_eased)
		if ruby_t >= 1.0:
			host.action_opportunity_ruby_left = host.action_opportunity_ruby_target_left


func _advance_emerald_action_opportunity_window() -> void:
	var max_steps := int(round((host.ACTION_OPPORTUNITY_EMERALD_MIN_WINDOW.x - host.ACTION_OPPORTUNITY_EMERALD_MAX_WINDOW.x) / host.ACTION_OPPORTUNITY_EMERALD_SHRINK_PER_SUCCESS))
	host.action_opportunity_emerald_shrink_steps = mini(host.action_opportunity_emerald_shrink_steps + 1, max_steps)
	host.action_opportunity_emerald_start_window = host.action_opportunity_emerald_window
	host.action_opportunity_emerald_target_window = _action_opportunity_emerald_target_window()
	host.action_opportunity_emerald_transition_elapsed = 0.0


func _advance_ruby_action_opportunity_window() -> void:
	var max_left: float = 1.0 - host.ACTION_OPPORTUNITY_RUBY_WINDOW_WIDTH
	var current_left := clampf(host.action_opportunity_ruby_target_left, 0.0, max_left)
	var direction := -1.0 if randf() < 0.5 else 1.0
	host.action_opportunity_ruby_start_left = clampf(host.action_opportunity_ruby_left, 0.0, max_left)
	host.action_opportunity_ruby_target_left = clampf(current_left + host.ACTION_OPPORTUNITY_RUBY_STEP * direction, 0.0, max_left)
	host.action_opportunity_ruby_transition_elapsed = 0.0


func _bump_action_opportunity_miss_expansion() -> void:
	host.action_opportunity_miss_expand_start = host.action_opportunity_miss_expand_per_side
	host.action_opportunity_miss_expand_target = clampf(host.action_opportunity_miss_expand_target + host.ACTION_OPPORTUNITY_MISS_EXPAND_PER_SIDE, 0.0, 0.5)
	host.action_opportunity_miss_expand_elapsed = 0.0


func _reset_action_opportunity_miss_expansion(smooth := true) -> void:
	host.action_opportunity_miss_expand_start = host.action_opportunity_miss_expand_per_side
	host.action_opportunity_miss_expand_target = 0.0
	host.action_opportunity_miss_expand_elapsed = 0.0 if smooth else host.ACTION_OPPORTUNITY_MISS_EXPAND_SECONDS
	if not smooth:
		host.action_opportunity_miss_expand_per_side = 0.0


func _reset_emerald_action_opportunity_window() -> void:
	host.action_opportunity_emerald_shrink_steps = 0
	host.action_opportunity_emerald_window = host.ACTION_OPPORTUNITY_EMERALD_MAX_WINDOW
	host.action_opportunity_emerald_start_window = host.ACTION_OPPORTUNITY_EMERALD_MAX_WINDOW
	host.action_opportunity_emerald_target_window = host.ACTION_OPPORTUNITY_EMERALD_MAX_WINDOW
	host.action_opportunity_emerald_transition_elapsed = host.ACTION_OPPORTUNITY_EMERALD_SHRINK_SECONDS


func _reset_ruby_action_opportunity_window() -> void:
	host.action_opportunity_ruby_left = host.ACTION_OPPORTUNITY_RUBY_START_LEFT
	host.action_opportunity_ruby_start_left = host.ACTION_OPPORTUNITY_RUBY_START_LEFT
	host.action_opportunity_ruby_target_left = host.ACTION_OPPORTUNITY_RUBY_START_LEFT
	host.action_opportunity_ruby_transition_elapsed = host.ACTION_OPPORTUNITY_RUBY_MOVE_SECONDS


func _action_opportunity_gold_window() -> Vector2:
	var silver_center: float = (host.ACTION_OPPORTUNITY_SILVER_WINDOW.x + host.ACTION_OPPORTUNITY_SILVER_WINDOW.y) * 0.5
	var offset := _action_opportunity_sway_offset(
		host.ACTION_OPPORTUNITY_GOLD_SWAY,
		host.ACTION_OPPORTUNITY_GOLD_MOVE_SECONDS,
		host.ACTION_OPPORTUNITY_GOLD_PAUSE_SECONDS
	)
	var half_width: float = host.ACTION_OPPORTUNITY_GOLD_WIDTH * 0.5
	var center := clampf(silver_center + offset, half_width, 1.0 - half_width)
	return Vector2(center - half_width, center + half_width)


func _action_opportunity_diamond_window() -> Vector2:
	var silver_center: float = (host.ACTION_OPPORTUNITY_SILVER_WINDOW.x + host.ACTION_OPPORTUNITY_SILVER_WINDOW.y) * 0.5
	var offset := _action_opportunity_sway_offset(
		host.ACTION_OPPORTUNITY_DIAMOND_SWAY,
		host.ACTION_OPPORTUNITY_DIAMOND_MOVE_SECONDS,
		host.ACTION_OPPORTUNITY_DIAMOND_PAUSE_SECONDS
	)
	var half_width: float = host.ACTION_OPPORTUNITY_DIAMOND_WIDTH * 0.5
	var center := clampf(silver_center + offset, half_width, 1.0 - half_width)
	return Vector2(center - half_width, center + half_width)


func _action_opportunity_sway_offset(sway: float, move: float, pause: float) -> float:
	var total := pause * 2.0 + move * 2.0
	var phase := fposmod(float(Time.get_ticks_msec()) / 1000.0, total)
	if phase < pause:
		return -sway
	phase -= pause
	if phase < move:
		return lerpf(-sway, sway, smoothstep(0.0, 1.0, phase / move))
	phase -= move
	if phase < pause:
		return sway
	phase -= pause
	return lerpf(sway, -sway, smoothstep(0.0, 1.0, phase / move))


func _action_opportunity_active(skill_id: String, action_id: String, progress := -1.0) -> bool:
	if host.action_opportunity_missed:
		return false
	if host.action_opportunity_consumed and not _action_opportunity_uses_triple_click(skill_id, action_id):
		return false
	var checked_progress: float = host.action_progress if progress < 0.0 else progress
	for window in _action_opportunity_windows(skill_id, action_id):
		if checked_progress >= window.x and checked_progress <= window.y:
			return true
	return false


func _action_opportunity_uses_triple_click(skill_id: String, action_id: String) -> bool:
	var medal_level: int = int(MasteryState.level(host.mastery, host._action_key(skill_id, action_id)))
	return (
		medal_level >= host.ACTION_OPPORTUNITY_PLATINUM_MIN_MEDAL_LEVEL
		and medal_level < host.ACTION_OPPORTUNITY_SAPPHIRE_MIN_MEDAL_LEVEL
	)


func _action_opportunity_uses_looping_window(skill_id: String, action_id: String) -> bool:
	var medal_level: int = int(MasteryState.level(host.mastery, host._action_key(skill_id, action_id)))
	return (
		medal_level >= host.ACTION_OPPORTUNITY_GOLD_MIN_MEDAL_LEVEL
		and medal_level < host.ACTION_OPPORTUNITY_PLATINUM_MIN_MEDAL_LEVEL
	) or medal_level >= host.ACTION_OPPORTUNITY_DIAMOND_MIN_MEDAL_LEVEL


func _action_opportunity_uses_persistent_window(skill_id: String, action_id: String) -> bool:
	var medal_level: int = int(MasteryState.level(host.mastery, host._action_key(skill_id, action_id)))
	return (
		medal_level >= host.ACTION_OPPORTUNITY_SAPPHIRE_MIN_MEDAL_LEVEL
		and medal_level < host.ACTION_OPPORTUNITY_EMERALD_MIN_MEDAL_LEVEL
	)


func _action_opportunity_uses_shrinking_window(skill_id: String, action_id: String) -> bool:
	var medal_level: int = int(MasteryState.level(host.mastery, host._action_key(skill_id, action_id)))
	return (
		medal_level >= host.ACTION_OPPORTUNITY_EMERALD_MIN_MEDAL_LEVEL
		and medal_level < host.ACTION_OPPORTUNITY_RUBY_MIN_MEDAL_LEVEL
	)


func _action_opportunity_uses_step_window(skill_id: String, action_id: String) -> bool:
	var medal_level: int = int(MasteryState.level(host.mastery, host._action_key(skill_id, action_id)))
	return (
		medal_level >= host.ACTION_OPPORTUNITY_RUBY_MIN_MEDAL_LEVEL
		and medal_level < host.ACTION_OPPORTUNITY_DIAMOND_MIN_MEDAL_LEVEL
	)


func _action_opportunity_persistent_window_reached_wait_point(skill_id: String, action_id: String) -> bool:
	if not _action_opportunity_uses_persistent_window(skill_id, action_id):
		return false
	return host.action_opportunity_cycle_elapsed >= host.ACTION_OPPORTUNITY_SAPPHIRE_SLIDE_SECONDS


func _try_action_opportunity_click(skill_id: String, action_id: String, _press_position: Vector2) -> bool:
	if host.running_skill_id != skill_id or host.running_action_id != action_id:
		return false
	if host.action_opportunity_missed:
		return false
	if host.action_opportunity_consumed and not _action_opportunity_uses_triple_click(skill_id, action_id):
		return _action_opportunity_progress_hit_test(skill_id, action_id)
	if not _action_opportunity_progress_hit_test(skill_id, action_id):
		return false
	var feedback_windows := _action_opportunity_pattern_windows(skill_id, action_id)
	var opportunity_key: String = host._action_key(skill_id, action_id)
	var now := Time.get_ticks_msec()
	if (
		host.last_action_opportunity_tap_key == opportunity_key
		and now - host.last_action_opportunity_tap_msec < host.ACTION_OPPORTUNITY_DUPLICATE_TAP_MSEC
	):
		return true
	host.last_action_opportunity_tap_key = opportunity_key
	host.last_action_opportunity_tap_msec = now
	if _action_opportunity_uses_triple_click(skill_id, action_id):
		var triple_success := _try_triple_click_action_opportunity_click(skill_id, action_id)
		if triple_success:
			host._complete_silver_opportunity_tip_for_action(skill_id, action_id)
		return triple_success
	host.action_opportunity_persistent_windows.clear()
	host.action_opportunity_persistent_key = ""
	if _action_opportunity_uses_shrinking_window(skill_id, action_id):
		_advance_emerald_action_opportunity_window()
	if _action_opportunity_uses_step_window(skill_id, action_id):
		_advance_ruby_action_opportunity_window()
	_reset_action_opportunity_miss_expansion(false)
	host._reward_feedback_surface()._play_action_opportunity_window_feedback(skill_id, action_id, true, feedback_windows)
	host.action_opportunity_consumed = true
	host.action_opportunity_boost_seconds = host.ACTION_OPPORTUNITY_BOOST_SECONDS
	host.action_opportunity_boost_duration = host.ACTION_OPPORTUNITY_BOOST_SECONDS
	_start_action_opportunity_regen(skill_id)
	host.action_progress = clampf(host.action_progress + host.ACTION_OPPORTUNITY_DIRECT_PROGRESS, 0.0, 0.999)
	host._reward_feedback_surface()._float_action_opportunity_feedback(skill_id, action_id)
	host._set_result("Opportunity hit: %s sped up. Stamina regen surged." % str(host._action_data(skill_id, action_id).get("name", "Activity")))
	host._complete_silver_opportunity_tip_for_action(skill_id, action_id)
	return true


func _try_triple_click_action_opportunity_click(skill_id: String, action_id: String) -> bool:
	var feedback_windows := _action_opportunity_pattern_windows(skill_id, action_id)
	_reset_action_opportunity_miss_expansion(false)
	host._reward_feedback_surface()._play_action_opportunity_window_feedback(skill_id, action_id, true, feedback_windows)
	if host.action_opportunity_triple_click_stacks < host.ACTION_OPPORTUNITY_TRIPLE_CLICK_MAX_STACKS:
		host.action_opportunity_triple_click_stacks += 1
	var text := "nice!"
	if host.action_opportunity_triple_click_stacks == 2:
		text = "awesome!"
	elif host.action_opportunity_triple_click_stacks >= host.ACTION_OPPORTUNITY_TRIPLE_CLICK_MAX_STACKS:
		text = "max!"
	host._reward_feedback_surface()._float_action_opportunity_feedback(skill_id, action_id, text)
	host._set_result("Opportunity hit: %s speed stack %s/%s." % [
		str(host._action_data(skill_id, action_id).get("name", "Activity")),
		host.action_opportunity_triple_click_stacks,
		host.ACTION_OPPORTUNITY_TRIPLE_CLICK_MAX_STACKS
	])
	return true


func _miss_action_opportunity_click(skill_id: String, action_id: String, _press_position: Vector2) -> bool:
	if host.running_skill_id != skill_id or host.running_action_id != action_id:
		return false
	if host.action_opportunity_consumed or host.action_opportunity_missed:
		return false
	var feedback_windows := _action_opportunity_pattern_windows(skill_id, action_id)
	if feedback_windows.is_empty():
		return false
	if not host._reward_feedback_surface()._action_opportunity_window_is_visible(skill_id, action_id):
		return false
	if _action_opportunity_progress_hit_test(skill_id, action_id):
		return false
	host.action_opportunity_persistent_windows.clear()
	host.action_opportunity_persistent_key = ""
	_bump_action_opportunity_miss_expansion()
	host._reward_feedback_surface()._play_action_opportunity_window_feedback(skill_id, action_id, false, feedback_windows)
	if _action_opportunity_uses_shrinking_window(skill_id, action_id):
		_reset_emerald_action_opportunity_window()
	host.action_opportunity_missed = true
	host._reward_feedback_surface()._float_action_opportunity_feedback(skill_id, action_id, "miss!", host.COLOR_RED.lightened(0.10))
	return true


func _action_opportunity_progress_hit_test(skill_id: String, action_id: String) -> bool:
	var checked_progress: float = clampf(host.action_progress, 0.0, 1.0)
	for window in _action_opportunity_windows(skill_id, action_id):
		if checked_progress >= window.x and checked_progress <= window.y:
			return true
	var rail: Variant = host._reward_feedback_surface()._visible_action_opportunity_rail(skill_id, action_id)
	if rail == null or not is_instance_valid(rail):
		return false
	return rail.has_opportunity_progress(host.action_progress)


func _start_action_opportunity_regen(skill_id: String) -> void:
	host.action_opportunity_regen_skill_id = skill_id
	host.action_opportunity_regen_seconds = host.ACTION_OPPORTUNITY_REGEN_SECONDS


func _process_action_opportunity_regen(delta: float) -> void:
	if host.action_opportunity_regen_seconds <= 0.0:
		host.action_opportunity_regen_seconds = 0.0
		host.action_opportunity_regen_skill_id = ""
		return
	if host.action_opportunity_regen_skill_id.is_empty() or host.running_skill_id != host.action_opportunity_regen_skill_id:
		host.action_opportunity_regen_seconds = 0.0
		host.action_opportunity_regen_skill_id = ""
		return
	host.action_opportunity_regen_seconds = maxf(0.0, host.action_opportunity_regen_seconds - delta)
	if host.action_opportunity_regen_seconds <= 0.0:
		host.action_opportunity_regen_skill_id = ""


func _process_action_opportunity_boost(delta: float) -> void:
	if host.action_opportunity_boost_seconds <= 0.0:
		host.action_opportunity_boost_seconds = 0.0
		host.action_opportunity_boost_duration = 0.0
		return
	host.action_opportunity_boost_seconds = maxf(0.0, host.action_opportunity_boost_seconds - delta)
	if host.action_opportunity_boost_seconds <= 0.0:
		host.action_opportunity_boost_duration = 0.0


func _action_opportunity_speed_bonus() -> float:
	var bonus: float = float(host.action_opportunity_triple_click_stacks) * host.ACTION_OPPORTUNITY_TRIPLE_CLICK_SPEED_PER_STACK
	if host.action_opportunity_boost_seconds > 0.0 and host.action_opportunity_boost_duration > 0.0:
		var t := clampf(host.action_opportunity_boost_seconds / host.action_opportunity_boost_duration, 0.0, 1.0)
		bonus += host.ACTION_OPPORTUNITY_BOOST_MULT * t * t
	return bonus


func _complete_action_opportunity_cycle_without_click() -> bool:
	if host.action_opportunity_missed or host.action_opportunity_consumed:
		_reset_action_opportunity_state(false)
		return true
	if not host.running_skill_id.is_empty() and not host.running_action_id.is_empty():
		if _action_opportunity_uses_triple_click(host.running_skill_id, host.running_action_id):
			_reset_action_opportunity_state(false)
			return true
		if _action_opportunity_uses_persistent_window(host.running_skill_id, host.running_action_id):
			if _action_opportunity_persistent_window_reached_wait_point(host.running_skill_id, host.running_action_id):
				var width: float = host.ACTION_OPPORTUNITY_SILVER_WINDOW.y - host.ACTION_OPPORTUNITY_SILVER_WINDOW.x
				host.action_opportunity_persistent_windows = [Vector2(host.ACTION_OPPORTUNITY_SAPPHIRE_LEFT_STOP, host.ACTION_OPPORTUNITY_SAPPHIRE_LEFT_STOP + width)]
				host.action_opportunity_persistent_key = host._action_key(host.running_skill_id, host.running_action_id)
				host.last_action_opportunity_tap_key = ""
				host.last_action_opportunity_tap_msec = 0
				return true
			host.action_opportunity_persistent_windows.clear()
			host.action_opportunity_persistent_key = ""
			host.last_action_opportunity_tap_key = ""
			host.last_action_opportunity_tap_msec = 0
			return false
		elif _action_opportunity_uses_looping_window(host.running_skill_id, host.running_action_id):
			host.action_opportunity_persistent_windows.clear()
			host.action_opportunity_persistent_key = ""
		elif host.action_opportunity_persistent_windows.is_empty():
			var windows := _action_opportunity_raw_pattern_windows(host.running_skill_id, host.running_action_id)
			if not windows.is_empty():
				host.action_opportunity_persistent_windows = windows.duplicate()
				host.action_opportunity_persistent_key = host._action_key(host.running_skill_id, host.running_action_id)
	host.last_action_opportunity_tap_key = ""
	host.last_action_opportunity_tap_msec = 0
	return true


func _activity_crit_chance(streak_bonus: bool) -> float:
	var base_chance: float = host.ACTIVITY_STREAK_CRIT_CHANCE if streak_bonus else host.ACTIVITY_NORMAL_CRIT_CHANCE
	var bonus_mult := AchievementState.reward_bonus(AchievementState.milestones(host), "crit_chance_mult")
	return clampf(base_chance * (1.0 + bonus_mult), 0.0, 1.0)


func invalidate_stat_cache() -> void:
	stat_cache_version += 1
	action_stat_value_cache.clear()


func _effective_stamina(skill_id: String, action: Dictionary) -> float:
	if host._convergence_runtime()._is_convergence_action(action):
		return 0.0
	if host._is_fishing_event_action(skill_id, action):
		return 0.0
	if host._fishing_rework_active_for_skill(skill_id) and not host._is_event_action(action):
		return 0.0
	var cache_key := _action_stat_value_cache_key("stamina", skill_id, action)
	if action_stat_value_cache.has(cache_key):
		return float(action_stat_value_cache[cache_key])
	var base_stamina := int(action.get("stamina", 1))
	if base_stamina <= 0:
		action_stat_value_cache[cache_key] = float(base_stamina)
		return float(base_stamina)
	var medal_reduction: float = AchievementState.activity_medal_stamina_cost_reduction(host, skill_id, action)
	var mission_reduction: float = host._hub_runtime().mission_stamina_reduction() if host._hub_runtime().mission_bonus_applies(skill_id, action) else 0.0
	var value := maxf(0.01, float(base_stamina) * (1.0 - clampf(medal_reduction + mission_reduction, 0.0, 0.92)))
	action_stat_value_cache[cache_key] = value
	return value


func _active_action_stamina_cost() -> float:
	if host.running_skill_id.is_empty() or host.running_action_id.is_empty():
		return 0.0
	var action: Dictionary = host._action_data(host.running_skill_id, host.running_action_id)
	return 0.0 if action.is_empty() else _effective_stamina(host.running_skill_id, action)


func _effective_seconds(skill_id: String, action: Dictionary) -> float:
	var base_seconds := maxf(0.1, float(action.get("seconds", 1.0)))
	var speed_bonus: float = clampf(AchievementState.global_reward_bonus(host, "speed_mult", skill_id) + host._ad_bonus_runtime().speed_multiplier(), 0.0, 0.75)
	var medal_time_reduction: float = AchievementState.activity_medal_time_reduction(host, skill_id, action)
	var mission_time_reduction: float = host._hub_runtime().mission_time_reduction() if host._hub_runtime().mission_bonus_applies(skill_id, action) else 0.0
	var total_reduction := clampf(speed_bonus + medal_time_reduction + mission_time_reduction, 0.0, 0.9)
	return maxf(0.1, base_seconds * (1.0 - total_reduction))


func _apply_medal_time_reduction_to_seconds(skill_id: String, action: Dictionary, seconds: float) -> float:
	return maxf(0.1, maxf(0.1, seconds) * (1.0 - AchievementState.activity_medal_time_reduction(host, skill_id, action)))


func _fishing_net_soak_active(skill_id: String) -> bool:
	return host._fishing_rework_active_for_skill(skill_id) and host.equipped_fishing_tool_id == "net"


func _fishing_boat_soak_active(skill_id: String) -> bool:
	return host._fishing_rework_active_for_skill(skill_id) and host.equipped_fishing_tool_id == "boat"


func _fishing_batch_soak_active(skill_id: String) -> bool:
	return _fishing_net_soak_active(skill_id) or _fishing_boat_soak_active(skill_id)


func _fishing_net_tick_seconds(action: Dictionary) -> float:
	var base_seconds := maxf(0.55, float(action.get("seconds", 1.0)) * 0.30)
	return clampf(base_seconds, 0.55, 4.2)


func _fishing_boat_tick_seconds(action: Dictionary) -> float:
	return clampf(maxf(1.0, float(action.get("seconds", 1.0))), 1.0, 6.0)


func _action_cycle_seconds(skill_id: String, action: Dictionary) -> float:
	if host._convergence_runtime()._is_convergence_action(action):
		return host._convergence_runtime()._convergence_total_cycle_seconds(action)
	var cache_key := _action_stat_value_cache_key("seconds", skill_id, action)
	if action_stat_value_cache.has(cache_key):
		return float(action_stat_value_cache[cache_key])
	var value := 0.0
	if _fishing_net_soak_active(skill_id):
		value = _apply_mission_time_reduction(skill_id, action, _apply_medal_time_reduction_to_seconds(skill_id, action, _fishing_net_tick_seconds(action)))
	elif _fishing_boat_soak_active(skill_id):
		value = _apply_mission_time_reduction(skill_id, action, _apply_medal_time_reduction_to_seconds(skill_id, action, _fishing_boat_tick_seconds(action)))
	elif host._fishing_rework_active_for_skill(skill_id) and not host._is_event_action(action):
		value = _apply_mission_time_reduction(skill_id, action, _apply_medal_time_reduction_to_seconds(skill_id, action, maxf(0.1, float(action.get("seconds", 1.0))) * host.fishing_runtime.tool_time_multiplier()))
	else:
		value = _effective_seconds(skill_id, action)
	action_stat_value_cache[cache_key] = value
	return value


func _apply_mission_time_reduction(skill_id: String, action: Dictionary, seconds: float) -> float:
	if not host._hub_runtime().mission_bonus_applies(skill_id, action):
		return seconds
	return maxf(0.1, maxf(0.1, seconds) * (1.0 - host._hub_runtime().mission_time_reduction()))


func _action_progress_speed_multiplier(skill_id: String, action: Dictionary, has_stamina_for_action: bool) -> float:
	if host._convergence_runtime()._is_convergence_action(action):
		return 1.0
	if _fishing_batch_soak_active(skill_id):
		return 1.0
	return 1.0 if has_stamina_for_action else host.LOW_STAMINA_ACTION_SPEED_MULT


func _smoothed_action_progress_speed_multiplier(action_key: String, target: float, delta: float) -> float:
	var clamped_target := maxf(0.0, target)
	if action_progress_speed_key != action_key:
		action_progress_speed_key = action_key
		action_progress_speed_mult_current = clamped_target
		return action_progress_speed_mult_current
	var weight := 1.0 - exp(-host.ACTION_PROGRESS_SPEED_EASE * delta)
	action_progress_speed_mult_current = lerpf(action_progress_speed_mult_current, clamped_target, weight)
	if absf(action_progress_speed_mult_current - clamped_target) <= 0.002:
		action_progress_speed_mult_current = clamped_target
	return action_progress_speed_mult_current


func _action_stat_value_cache_key(kind: String, skill_id: String, action: Dictionary) -> String:
	var active_event = action.get("active_event", {})
	var event_spawn_level := 0
	if typeof(active_event) == TYPE_DICTIONARY:
		event_spawn_level = int((active_event as Dictionary).get("spawn_level", 0))
	return "%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s" % [
		kind,
		skill_id,
		str(action.get("id", "")),
		str(event_spawn_level),
		stat_cache_version,
		host.ad_bonus_seconds_remaining > 0.0,
		host.equipped_fishing_tool_id,
		host.plank_boost_enabled,
		host.material_runtime.amount("softwood") >= 1.0,
		hash(host._hub_runtime().hub_modules),
		hash(host._hub_runtime().hub_missions),
		hash(host.selected_fishing_locations)
	]


func _success_chance(skill_id: String, action: Dictionary) -> float:
	if host._convergence_runtime()._is_convergence_action(action):
		return 100.0
	var cache_key := _action_stat_value_cache_key("success", skill_id, action)
	if action_stat_value_cache.has(cache_key):
		return float(action_stat_value_cache[cache_key])
	var value := 100.0
	if host._fishing_rework_active_for_skill(skill_id) and not host._is_event_action(action):
		value = clampf(host._fishing_attempt_success_chance(str(action.get("id", ""))) + AchievementState.activity_medal_accuracy_bonus(host, skill_id, action), 5.0, 100.0)
	else:
		var base_success := float(action.get("success", 90.0))
		var medal_success := AchievementState.global_reward_bonus(host, "success_bonus", skill_id) + AchievementState.activity_medal_rate_bonus(host, skill_id, action)
		var success_before_barn := clampf(base_success + medal_success, 5.0, 100.0)
		var barn_bonus: float = (100.0 - success_before_barn) * host._hub_surface()._hub_barn_failure_factor()
		value = clampf(success_before_barn + barn_bonus + host._hub_runtime().trophy_success_bonus() * 100.0, 5.0, 100.0)
	action_stat_value_cache[cache_key] = value
	return value


func _roll_action_success(skill_id: String, action: Dictionary) -> bool:
	if _consume_guaranteed_success_action_completion(skill_id, action):
		return true
	return randf() * 100.0 <= _success_chance(skill_id, action)


func _consume_guaranteed_success_action_completion(skill_id: String, action: Dictionary) -> bool:
	if skill_id.is_empty() or action.is_empty() or host._is_passive_action(action) or host._convergence_runtime()._is_convergence_action(action):
		return false
	if host.guaranteed_success_action_completions >= host.GUARANTEED_SUCCESS_ACTION_COMPLETIONS:
		return false
	host.guaranteed_success_action_completions += 1
	host._mark_save_dirty("starter guaranteed success")
	return true


func _reset_action_opportunity_state(clear_boost := true) -> void:
	host.action_opportunity_consumed = false
	host.action_opportunity_missed = false
	host.action_opportunity_cycle_elapsed = 0.0
	host.action_opportunity_triple_click_stacks = 0
	host.action_opportunity_persistent_windows.clear()
	host.action_opportunity_persistent_key = ""
	host.last_action_opportunity_tap_key = ""
	host.last_action_opportunity_tap_msec = 0
	if clear_boost:
		_reset_action_opportunity_miss_expansion(false)
		_reset_emerald_action_opportunity_window()
		_reset_ruby_action_opportunity_window()
		host.action_opportunity_boost_seconds = 0.0
		host.action_opportunity_boost_duration = 0.0
		host.action_opportunity_regen_skill_id = ""
		host.action_opportunity_regen_seconds = 0.0
		action_progress_speed_key = ""
		action_progress_speed_mult_current = 1.0



func _process_canceled_action_progress(delta: float) -> void:
	if host.canceled_action_progress_by_key.is_empty():
		return
	var active_key = host._action_key(host.running_skill_id, host.running_action_id) if not host.running_skill_id.is_empty() and not host.running_action_id.is_empty() else ""
	var keys_to_clear = []
	for raw_action_key in host.canceled_action_progress_by_key.keys():
		var action_key = str(raw_action_key)
		if action_key == active_key:
			keys_to_clear.append(action_key)
			continue
		var progress = clampf(float(host.canceled_action_progress_by_key.get(action_key, 0.0)), 0.0, 0.999)
		progress = move_toward(progress, 0.0, host.ACTION_CANCELED_PROGRESS_DECAY_PER_SECOND * maxf(0.0, delta))
		if progress <= 0.001:
			keys_to_clear.append(action_key)
		else:
			host.canceled_action_progress_by_key[action_key] = progress
	for action_key in keys_to_clear:
		host.canceled_action_progress_by_key.erase(action_key)


func _remember_canceled_action_progress(skill_id: String, action_id: String, progress: float) -> void:
	if skill_id.is_empty() or action_id.is_empty():
		return
	var clamped_progress := clampf(progress, 0.0, 0.999)
	var action_key: String = host._action_key(skill_id, action_id)
	if clamped_progress <= 0.001:
		host.canceled_action_progress_by_key.erase(action_key)
	else:
		host.canceled_action_progress_by_key[action_key] = clamped_progress


func _canceled_action_progress(skill_id: String, action_id: String) -> float:
	if skill_id.is_empty() or action_id.is_empty():
		return 0.0
	return clampf(float(host.canceled_action_progress_by_key.get(host._action_key(skill_id, action_id), 0.0)), 0.0, 0.999)


func _consume_canceled_action_progress(skill_id: String, action_id: String) -> float:
	var action_key: String = host._action_key(skill_id, action_id)
	var progress := clampf(float(host.canceled_action_progress_by_key.get(action_key, 0.0)), 0.0, 0.999)
	host.canceled_action_progress_by_key.erase(action_key)
	return progress


func _stop_running_action(skill_id: String, action_id: String) -> bool:
	if host.running_skill_id != skill_id or host.running_action_id != action_id:
		return false
	var action: Dictionary = host._action_data(skill_id, action_id)
	if action.is_empty():
		return false
	var stop_action_key: String = host._action_key(skill_id, action_id)
	_remember_canceled_action_progress(skill_id, action_id, host.action_progress)
	host._clear_auto_eat_fish_after_spend_delay(skill_id)
	host.running_skill_id = ""
	host.running_action_id = ""
	host.action_progress = 0.0
	host.tired_activity_zero_float_action_key = ""
	host.fishing_net_set_in_water = false
	host.fishing_boat_set_in_water = false
	host.fishing_rod_set_in_water = false
	host.fishing_rod_haul_visual_seconds = 0.0
	_reset_action_opportunity_state()
	host._audio_director()._nudge_music_flow_down(0.4)
	host._set_result("%s stopped." % action["name"])
	host._audio_director()._play_click_sfx()
	host._pop_activity_button(stop_action_key)
	host._material_collection_surface()._sync_visible_mat_collection_for_action(skill_id, action_id, false)
	host._update_ui(0.0, false)
	return true


func _action_mat_reward_defs(action: Dictionary) -> Array:
	var rewards = action.get("mat_rewards", [])
	var normalized = []
	if typeof(rewards) == TYPE_ARRAY:
		for raw_reward in rewards as Array:
			if typeof(raw_reward) != TYPE_DICTIONARY:
				continue
			var reward = raw_reward as Dictionary
			var mat_id = host.material_runtime.normalize_id(str(reward.get("id", reward.get("mat", ""))))
			if host.material_runtime.has_definition(mat_id):
				var next_reward = reward.duplicate(true)
				next_reward["id"] = mat_id
				normalized.append(next_reward)
	elif typeof(rewards) == TYPE_DICTIONARY:
		for raw_mat_id in (rewards as Dictionary).keys():
			var mat_id = host.material_runtime.normalize_id(str(raw_mat_id))
			if not host.material_runtime.has_definition(mat_id):
				continue
			var amount_value = float((rewards as Dictionary).get(raw_mat_id, 0.0))
			normalized.append({"id": mat_id, "min": amount_value, "max": amount_value})
	return normalized


func _action_has_mat_rewards(action: Dictionary) -> bool:
	return not _action_mat_reward_defs(action).is_empty()


func _roll_action_mat_rewards(action: Dictionary) -> Array:
	var rolled = []
	for raw_reward in _action_mat_reward_defs(action):
		var reward = raw_reward as Dictionary
		var mat_id = str(reward.get("id", ""))
		var chance = clampf(float(reward.get("chance", 1.0)), 0.0, 1.0)
		if randf() > chance:
			rolled.append({"id": mat_id, "amount": 0.0})
			continue
		var min_amount = maxf(0.0, float(reward.get("min", reward.get("amount", 0.0))))
		var max_amount = maxf(min_amount, float(reward.get("max", reward.get("amount", min_amount))))
		var amount = randf_range(min_amount, max_amount)
		if bool(reward.get("whole", false)):
			amount = floor(amount + 0.0001)
		if bool(reward.get("allow_zero", true)) and min_amount <= 0.0 and max_amount > 0.0 and randf() < float(reward.get("zero_chance", 0.0)):
			amount = 0.0
		rolled.append({"id": mat_id, "amount": maxf(0.0, amount)})
	return rolled


func _award_action_mat_rewards(action: Dictionary, multiplier := 1.0) -> Array:
	var awarded = []
	for raw_roll in _roll_action_mat_rewards(action):
		var roll = raw_roll as Dictionary
		var mat_id = str(roll.get("id", ""))
		var amount = host.material_runtime.buffed_log_collection_amount_for_host(mat_id, float(roll.get("amount", 0.0)) * maxf(0.0, multiplier), host)
		if amount > 0.0001:
			host.material_runtime.add_amount(mat_id, amount)
		awarded.append({"id": mat_id, "amount": amount})
	return awarded


func _mat_reward_result_text(awarded_mats: Array) -> String:
	var parts = []
	for raw_reward in awarded_mats:
		if typeof(raw_reward) != TYPE_DICTIONARY:
			continue
		var reward = raw_reward as Dictionary
		var mat_id = str(reward.get("id", ""))
		var amount = maxf(0.0, float(reward.get("amount", 0.0)))
		if amount <= 0.0001:
			continue
		parts.append("+%s %s" % [host.material_runtime.amount_text_for_host(mat_id, amount, host), host.material_runtime.display_name(mat_id)])
	if parts.is_empty():
		return ""
	return ", ".join(parts)


func _process_action(delta: float) -> void:
	_process_canceled_action_progress(delta)
	host._activity_queue_runtime()._process_activity_queue_runtime()
	_process_temporary_event_action(delta)
	if host.running_skill_id.is_empty():
		if _action_opportunity_frame_work_needed():
			_process_action_opportunity_boost(delta)
			_process_action_opportunity_window_animation(delta)
		return
	_process_action_opportunity_boost(delta)
	_process_action_opportunity_window_animation(delta)
	var action = host._action_data(host.running_skill_id, host.running_action_id)
	if action.is_empty():
		host._clear_auto_eat_fish_after_spend_delay(host.running_skill_id)
		host.running_skill_id = ""
		host.running_action_id = ""
		host.action_progress = 0.0
		host.tired_activity_zero_float_action_key = ""
		host.fishing_net_set_in_water = false
		host.fishing_boat_set_in_water = false
		host.fishing_rod_set_in_water = false
		host.fishing_rod_haul_visual_seconds = 0.0
		_reset_action_opportunity_state()
		return
	var active_key = host._action_key(host.running_skill_id, host.running_action_id)
	if host._fighting_runtime().action_is_free_fighting_proto(host.running_skill_id, host.running_action_id):
		host.action_progress = 0.0
		host.action_opportunity_cycle_elapsed = 0.0
		host.tired_activity_zero_float_action_key = ""
		return
	var fishing_rework_attempt = host._fishing_rework_active_for_skill(host.running_skill_id) and not host._is_event_action(action)
	var cost = _effective_stamina(host.running_skill_id, action)
	if not fishing_rework_attempt and not host.activity_queue_running:
		if host._auto_eat_fish_after_spend_delay_due(host.running_skill_id):
			host._auto_eat_fish_for_action(host.running_skill_id, cost, host.detail_regen_circle, false)
		elif not host._auto_eat_fish_after_spend_delay_active(host.running_skill_id):
			host._auto_eat_fish_for_action(host.running_skill_id, cost, host.detail_regen_circle, false)
	var has_stamina_for_action = true if fishing_rework_attempt else host._stamina_value(host.running_skill_id) + 0.0001 >= cost
	if (
		not has_stamina_for_action
		and host._auto_eat_fish_after_spend_delay_active(host.running_skill_id)
		and host._auto_eat_fish_can_cover_action(host.running_skill_id, cost)
	):
		has_stamina_for_action = true
	if host._is_event_action(action) and not has_stamina_for_action:
		host._set_result(host._temporary_event_runtime()._event_needs_stamina_text(host.running_skill_id, action))
		host._reward_feedback_surface()._float_event_need_stamina_feedback(active_key, cost)
		host.running_skill_id = ""
		host.running_action_id = ""
		host.action_progress = 0.0
		host.tired_activity_zero_float_action_key = ""
		_reset_action_opportunity_state()
		host._update_ui(0.0, false)
		return
	var base_speed_mult = _smoothed_action_progress_speed_multiplier(active_key, _action_progress_speed_multiplier(host.running_skill_id, action, has_stamina_for_action), delta)
	var speed_mult = base_speed_mult + _action_opportunity_speed_bonus()
	host.action_opportunity_cycle_elapsed += delta
	if not fishing_rework_attempt and not has_stamina_for_action:
		var low_stamina_message = host._low_stamina_training_text(action)
		if host.last_result != low_stamina_message:
			host.last_result = low_stamina_message
			host._audio_director()._nudge_music_flow_down(0.4)
		if host._stamina(host.running_skill_id) <= 0 and host.tired_activity_zero_float_action_key != active_key:
			host.tired_activity_zero_float_action_key = active_key
			host._reward_feedback_surface()._float_tired_activity_feedback(active_key)
	else:
		host.tired_activity_zero_float_action_key = ""
	host.action_progress += delta / _action_cycle_seconds(host.running_skill_id, action) * speed_mult
	if host.action_progress < 1.0:
		return
	var bonus_snapshot_before = host._capture_visible_bonus_snapshot_if_needed(host.running_skill_id, host.running_action_id, action)
	host.action_progress = 0.0
	if _complete_action_opportunity_cycle_without_click():
		host.action_opportunity_cycle_elapsed = 0.0
	if host._convergence_runtime()._is_convergence_action(action):
		host._convergence_runtime()._complete_convergence_cycle(host.running_action_id)
		host._onboarding_runtime()._record_activity_completion_for_tips(host.running_skill_id, host.running_action_id)
		host._update_ui(0.0, false)
		return
	if fishing_rework_attempt:
		host._complete_fishing_action_attempt(action, active_key, bonus_snapshot_before)
		return
	if not host.activity_queue_running and host._stamina_value(host.running_skill_id) + 0.0001 < cost:
		host._auto_eat_fish_for_action(host.running_skill_id, cost, host.detail_regen_circle, false)
	if host._spend_action_stamina(host.running_skill_id, cost):
		if not host.activity_queue_running:
			host._schedule_auto_eat_fish_after_spend_delay(host.running_skill_id, cost)
		if host.running_skill_id == host.TUTORIAL_STARTER_SKILL_ID:
			host._onboarding_runtime()._maybe_trigger_onboarding_swipe_tip_at_zero_stamina(host.TUTORIAL_STARTER_SKILL_ID)
	if host._is_event_action(action):
		host._temporary_event_runtime()._complete_temporary_event_action_attempt(host.running_skill_id, host.running_action_id, action, active_key, cost, bonus_snapshot_before)
		return
	var reward_key = active_key
	var old_mastery_level = MasteryState.level(host.mastery, host._action_key(host.running_skill_id, host.running_action_id))
	var mastery_reward = host._mastery_reward_for_action(host.running_skill_id, host.running_action_id, action)
	var tiers_unlocked_before = {}
	for tier in range(1, host.MASTERY_MAX_LEVEL + 1):
		tiers_unlocked_before[tier] = AchievementState.global_medal_tier_unlocked(host, tier)
	var completed_achievements_before = AchievementState.completed_ids(AchievementState.milestones(host, false))
	var old_skill_level = host._skill_level(host.running_skill_id)
	var locked_preview_available_before = host._locked_activity_preview_available()
	var success = _roll_action_success(host.running_skill_id, action)
	var completed_skill_id = host.running_skill_id
	var completed_action_id = host.running_action_id
	host._play_fishing_attempt_reveal(host.running_skill_id, host.running_action_id, success)
	if success:
		var streak_step = host._record_successful_activity_completion(reward_key)
		var streak_bonus = streak_step == host.ACTIVITY_STREAK_BONUS_STEP
		var crits_allowed = host._onboarding_runtime()._activity_crits_allowed()
		var crit_chance = _activity_crit_chance(streak_bonus) if crits_allowed else 0.0
		var xp_crit = crits_allowed and randf() < crit_chance
		if xp_crit:
			host.consecutive_activity_crit_count += 1
		else:
			host.consecutive_activity_crit_count = 0
		var mega_crit = crits_allowed and host.consecutive_activity_crit_count >= 2
		if xp_crit:
			host.activity_crit_seen = true
		if mega_crit:
			host.activity_mega_crit_seen = true
		var plank_bonus_used = host._plank_bonus_applies(host.running_skill_id)
		var xp_reward_map = host._completion_xp_reward_map(action, host.running_skill_id, plank_bonus_used, xp_crit, mega_crit, streak_bonus)
		var berry_prep_result = host.material_runtime.consume_berry_prep_bonus(host.running_skill_id, host.running_action_id, xp_reward_map, Callable(host, "_action_data"), Callable(host, "_action_key"))
		host._material_collection_surface().play_berry_prep_badge_feedback(host.running_skill_id, host.running_action_id, not berry_prep_result.is_empty(), host.material_runtime.berry_prep_matches(host.running_skill_id, host.running_action_id, Callable(host, "_action_data"), Callable(host, "_action_key")) and host.material_runtime.amount("berries") < 1.0)
		var old_reward_skill_levels = host._skill_levels_for_reward_map(host.running_skill_id, xp_reward_map)
		var affected_reward_skill_ids = host._apply_xp_reward_map(host.running_skill_id, xp_reward_map)
		var xp_reward = host._reward_map_total(xp_reward_map)
		if mastery_reward > 0.0:
			host._add_mastery_xp(host.running_skill_id, host.running_action_id, mastery_reward)
		var new_mastery_level = MasteryState.level(host.mastery, host._action_key(host.running_skill_id, host.running_action_id))
		host._register_silver_opportunity_tip_anchor(host.running_skill_id, host.running_action_id, old_mastery_level, new_mastery_level)
		for raw_reward_skill_id in affected_reward_skill_ids:
			host._recalculate_level(str(raw_reward_skill_id))
		host._queue_locked_activity_preview_reveal_if_needed(locked_preview_available_before)
		var new_skill_level = host._skill_level(host.running_skill_id)
		var any_reward_skill_level_up = host._any_reward_skill_leveled_up(affected_reward_skill_ids, old_reward_skill_levels)
		host._passive_modules_runtime().sync_passive_module_unlocks(host._unix_now())
		if plank_bonus_used:
			host.material_runtime.spend_amount("softwood", 1.0)
		var recovery_result = RecoveryModules.apply(host.running_skill_id, action, host.skill_defs, host.stamina, Callable(host, "_stamina_value"), Callable(host, "_max_stamina"), Callable(host, "_restore_action_stamina"))
		var recovery_text = RecoveryModules.result_text(recovery_result, Callable(host, "_skill_name"), Callable(GameFormatting, "stamina_cost_detail"))
		var berry_prep_text = host.material_runtime.berry_prep_result_text(berry_prep_result)
		var awarded_mats = _award_action_mat_rewards(action, 2.0 if not berry_prep_result.is_empty() else 1.0)
		var mat_result_text = _mat_reward_result_text(awarded_mats)
		var boss_clear_text = host._fighting_runtime().complete_boss_if_needed(action)
		if not boss_clear_text.is_empty():
			host._queue_activity_unlock_readiness(host.running_skill_id, 0, host._skill_level(host.running_skill_id), host._ready_lockpads_for_current_state())
		host.last_result = host._xp_reward_result_sentence(xp_reward_map, host.running_skill_id, str(action["name"]))
		if plank_bonus_used:
			host.last_result += " Plank boost used 1 Softwood."
		if not berry_prep_text.is_empty():
			host.last_result += " %s" % berry_prep_text
		if not mat_result_text.is_empty():
			host.last_result += " %s." % mat_result_text
		if not recovery_text.is_empty():
			host.last_result += " %s" % recovery_text
		if not boss_clear_text.is_empty():
			host.last_result += " %s" % boss_clear_text
		if mega_crit:
			host.last_result += " MEGA CRIT!!!! 9x XP."
		elif xp_crit:
			host.last_result += " Critical success: triple XP."
		elif streak_bonus:
			host.last_result += " Fifth repeat: double XP."
		if host._hub_runtime().record_mission_action_completion(host.running_skill_id, host.running_action_id):
			host.last_result += " Mission progress."
		var new_global_buffs = AchievementState.new_global_medal_buff_messages(host, old_mastery_level, new_mastery_level, tiers_unlocked_before)
		if not new_global_buffs.is_empty():
			host.last_result += " " + " ".join(new_global_buffs)
		host._reward_feedback_surface()._play_action_feedback(reward_key, true, xp_reward, mastery_reward, xp_crit, mega_crit, xp_reward_map)
		host._material_collection_surface()._play_mat_collection_feedback(reward_key, awarded_mats)
		if plank_bonus_used:
			host._passive_firepit_surface()._play_build_log_spend_feedback(reward_key)
		for achievement in AchievementState.newly_completed(AchievementState.milestones(host, false), completed_achievements_before):
			host._achievement_toast_surface().show_unlocked(achievement)
		host._audio_director()._play_activity_success_sound(streak_step, new_mastery_level > old_mastery_level, streak_bonus, xp_crit, mega_crit, host.consecutive_activity_crit_count)
		host._audio_director()._record_music_flow_action(true, streak_step, streak_bonus, new_mastery_level > old_mastery_level, any_reward_skill_level_up or new_skill_level > old_skill_level, cost)
		host._maybe_show_onboarding_medal_tip(old_mastery_level, new_mastery_level, host.running_skill_id, host.running_action_id)
	else:
		host.consecutive_activity_crit_count = 0
		host._reset_activity_completion_streak()
		var failure_mastery_reward = 0.0 if MasteryState.would_reward_level_up(host.mastery, host._action_key(host.running_skill_id, host.running_action_id), mastery_reward, host.MASTERY_MAX_LEVEL) else mastery_reward
		if failure_mastery_reward > 0:
			host._add_mastery_xp(host.running_skill_id, host.running_action_id, failure_mastery_reward)
		var failure_mastery_level = MasteryState.level(host.mastery, host._action_key(host.running_skill_id, host.running_action_id))
		host.last_result = "Failed %s." % action["name"]
		if MasteryState.is_maxed(host.mastery, host._action_key(host.running_skill_id, host.running_action_id), host.MASTERY_MAX_LEVEL):
			host.last_result += " Mastery maxed."
		else:
			host.last_result += " +%s mastery." % failure_mastery_reward
		if failure_mastery_reward <= 0 and not MasteryState.is_maxed(host.mastery, host._action_key(host.running_skill_id, host.running_action_id), host.MASTERY_MAX_LEVEL):
			host.last_result += " Next medal needs a success."
		var failure_global_buffs = AchievementState.new_global_medal_buff_messages(host, old_mastery_level, failure_mastery_level, tiers_unlocked_before)
		if not failure_global_buffs.is_empty():
			host.last_result += " " + " ".join(failure_global_buffs)
		host._reward_feedback_surface()._play_action_feedback(reward_key, false, 0, failure_mastery_reward)
		for achievement in AchievementState.newly_completed(AchievementState.milestones(host, false), completed_achievements_before):
			host._achievement_toast_surface().show_unlocked(achievement)
		host._audio_director()._play_failure_sfx()
		host._audio_director()._record_music_flow_action(false, 0, false, failure_mastery_level > old_mastery_level, false, cost)
		host._maybe_show_onboarding_medal_tip(old_mastery_level, failure_mastery_level, host.running_skill_id, host.running_action_id)
		if host.running_skill_id == "thieving":
			var failed_thieving_action_id = host.running_action_id
			var jail_seconds = host._thieving_surface()._thieving_action_jail_seconds(action)
			if jail_seconds > 0:
				host.last_result += " Jailed for %s." % GameFormatting.countdown(jail_seconds)
				host.running_skill_id = ""
				host.running_action_id = ""
				host.action_progress = 0.0
				_reset_action_opportunity_state()
				host._thieving_surface()._jail_thieving_action(failed_thieving_action_id, true, jail_seconds)
			else:
				host.last_result += " No jail time."
	host._onboarding_runtime()._record_activity_completion_for_tips(completed_skill_id, completed_action_id)
	host._onboarding_runtime()._maybe_trigger_onboarding_swipe_tip_at_zero_stamina(completed_skill_id)
	host._update_ui(0.0, false)
	host._emphasize_visible_bonus_changes_deferred(bonus_snapshot_before)


func _process_temporary_event_action(delta: float) -> void:
	if host.event_running_skill_id.is_empty() or host.event_running_action_id.is_empty():
		return
	var action = host._action_data(host.event_running_skill_id, host.event_running_action_id)
	if action.is_empty() or not host._is_action_unlocked(host.event_running_skill_id, action):
		host._temporary_event_runtime()._stop_temporary_event_action_with_feedback(
			host.event_running_skill_id,
			host.event_running_action_id,
			"Event stopped: it ended.",
			"Stopped\nEvent ended",
			Color("#ff9f7a")
		)
		return
	var event_key = host._action_key(host.event_running_skill_id, host.event_running_action_id)
	var cost = _effective_stamina(host.event_running_skill_id, action)
	var has_stamina_for_action = host._stamina_value(host.event_running_skill_id) + 0.0001 >= cost
	if not has_stamina_for_action:
		var cost_text = GameFormatting.stamina_cost_detail(cost)
		host._temporary_event_runtime()._stop_temporary_event_action_with_feedback(
			host.event_running_skill_id,
			host.event_running_action_id,
			"Event stopped: %s" % host._temporary_event_runtime()._event_needs_stamina_text(host.event_running_skill_id, action),
			"Stopped\nNeed %s STAM" % cost_text,
			Color("#ffd95a")
		)
		return
	var speed_mult = _action_progress_speed_multiplier(host.event_running_skill_id, action, has_stamina_for_action)
	host.event_action_progress += delta / _action_cycle_seconds(host.event_running_skill_id, action) * speed_mult
	if host.event_action_progress < 1.0:
		return
	var completed_skill_id = host.event_running_skill_id
	var completed_action_id = host.event_running_action_id
	var bonus_snapshot_before = host._capture_visible_bonus_snapshot_if_needed(completed_skill_id, completed_action_id, action)
	host.event_action_progress = 0.0
	if host._spend_action_stamina(completed_skill_id, cost):
		host._schedule_auto_eat_fish_after_spend_delay(completed_skill_id, cost)
	host._temporary_event_runtime()._complete_temporary_event_action_attempt(completed_skill_id, completed_action_id, action, event_key, cost, bonus_snapshot_before)


func _start_action(skill_id: String, action_id: String, select_page = true, respect_input_guards = true, from_activity_queue = false) -> bool:
	host._settings_surface()._disarm_reset_data_confirmation()
	if respect_input_guards:
		if host._skill_swipe_suppresses_button_action():
			return false
		var active_scroll = host._active_action_scroll_container()
		if active_scroll != null and active_scroll.is_child_click_suppressed():
			return false
	var action = host._action_data(skill_id, action_id)
	if action.is_empty():
		return false
	if BuildableModules.is_buildable(action) and not BuildableModules.is_built(host.built_modules, skill_id, action, Callable(host, "_action_key")):
		BuildableModules.attempt_build(host, skill_id, action)
		return false
	if not host._is_action_unlocked(skill_id, action):
		return false
	if host._is_event_action(action):
		return host._temporary_event_runtime()._start_temporary_event_action(skill_id, action_id, action, select_page)
	if not from_activity_queue and host.activity_queue_running:
		host._activity_queue_runtime()._stop_activity_queue_runtime(false)
	host._audio_director()._unlock_audio_for_gameplay()
	host._audio_director()._play_activity_tap_sfx()
	if skill_id == "thieving" and host._thieving_surface()._thieving_action_is_jailed(action_id):
		host._set_result("%s is jailed: %s." % [str(action.get("name", "Activity")), GameFormatting.countdown(host._thieving_surface()._thieving_action_jail_remaining(action_id))])
		return false
	if host._is_passive_action(action):
		host._passive_modules_runtime().collect_passive_module(action_id, host._unix_now())
		return true
	if host._convergence_runtime()._is_convergence_action(action) and not host._convergence_runtime()._convergence_is_built(action_id):
		host._convergence_runtime()._start_convergence_build(action_id)
		var convergence_refresh_scroll = host.detail_actions_scroll.scroll_vertical if host.detail_actions_scroll != null else -1
		host._render_screen(false, convergence_refresh_scroll)
		host._update_ui(0.0, true)
		return false
	if host.running_skill_id == skill_id and host.running_action_id == action_id:
		host._set_result("Hold %s to stop." % action["name"])
		host._pop_activity_button(host._action_key(skill_id, action_id))
		return false
	if not host.running_skill_id.is_empty() and not host.running_action_id.is_empty():
		_remember_canceled_action_progress(host.running_skill_id, host.running_action_id, host.action_progress)
	host._thieving_surface()._cancel_thieving_action_jail_resumes_for_started_action(skill_id, action_id)
	var action_key = host._action_key(skill_id, action_id)
	var stamina_cost = _effective_stamina(skill_id, action)
	if host._fighting_runtime().action_is_free_fighting_proto(skill_id, action_id):
		stamina_cost = 0.0
	if host._is_event_action(action) and not host._auto_eat_fish_for_action(skill_id, stamina_cost, host.detail_regen_circle, true):
		host._set_result(host._temporary_event_runtime()._event_needs_stamina_text(skill_id, action))
		host._reward_feedback_surface()._float_event_need_stamina_feedback(action_key, stamina_cost)
		return false
	if select_page:
		host.selected_skill_id = skill_id
	host.running_skill_id = skill_id
	host.running_action_id = action_id
	host.action_progress = _consume_canceled_action_progress(skill_id, action_id)
	host.action_opportunity_cycle_elapsed = 0.0
	_reset_emerald_action_opportunity_window()
	_reset_ruby_action_opportunity_window()
	_reset_action_opportunity_state()
	host.tired_activity_zero_float_action_key = ""
	host.fishing_net_set_in_water = false
	host.fishing_boat_set_in_water = false
	host.fishing_rod_set_in_water = false
	host.fishing_rod_haul_visual_seconds = 0.0
	if host._audio_director().music_cycle_active:
		host._audio_director()._record_music_flow_start()
	host._pop_activity_button(action_key)
	host._material_collection_surface()._sync_visible_mat_collection_for_action(skill_id, action_id, true)
	if host._fishing_rework_active_for_skill(skill_id) and not host._is_event_action(action):
		var tool_warning = host.fishing_runtime.tool_warning_text(action_id)
		if tool_warning.is_empty():
			host._set_result("%s started." % action["name"])
		else:
			host._set_result("%s started. %s: %s is a poor fit here." % [action["name"], tool_warning, host._fishing_tool_label(host.equipped_fishing_tool_id)])
	elif (not from_activity_queue) and not host._auto_eat_fish_for_action(skill_id, stamina_cost, host.detail_regen_circle, false):
		host._set_result(host._low_stamina_training_text(action))
		host._reward_feedback_surface()._float_tired_activity_feedback(action_key)
		if host._stamina(skill_id) <= 0:
			host.tired_activity_zero_float_action_key = action_key
	elif from_activity_queue and host._stamina_value(skill_id) + 0.0001 < stamina_cost:
		host._set_result(host._low_stamina_training_text(action))
	else:
		host._set_result("%s started." % action["name"])
	host._onboarding_runtime()._record_activity_start_for_tips()
	host._fade_out_onboarding_explore_tip()
	host._onboarding_runtime()._tutorial_on_action_started()
	return true


func _start_action_from_card_tap(skill_id: String, action_id: String, visual_card_key = "") -> bool:
	var key = host._action_key(skill_id, action_id)
	var now = Time.get_ticks_msec()
	if host.last_action_card_tap_key == key and now - host.last_action_card_tap_msec < host.ACTION_CARD_DUPLICATE_TAP_MSEC:
		return false
	host._on_activity_start_tutorial_card_tapped(skill_id, action_id)
	if _start_action(skill_id, action_id, true, false):
		host.last_action_card_tap_key = key
		host.last_action_card_tap_msec = now
		if not visual_card_key.is_empty() and visual_card_key != key:
			host._pop_activity_button(visual_card_key)
		return true
	return false

func _apply_offline_active_action(offline_seconds: float) -> Dictionary:
	if offline_seconds <= 0.0 or host.running_skill_id.is_empty() or host.running_action_id.is_empty():
		return {"handled": false}
	var action = host._action_data(host.running_skill_id, host.running_action_id)
	if action.is_empty() or host._is_passive_action(action):
		host.running_skill_id = ""
		host.running_action_id = ""
		host.action_progress = 0.0
		return {"handled": false}
	if not host._is_action_unlocked(host.running_skill_id, action):
		host.action_progress = 0.0
		return {"handled": false}
	if host._convergence_runtime()._is_convergence_action(action):
		return _apply_offline_convergence_action(offline_seconds, host.running_action_id, action)
	var skill_id = host.running_skill_id
	var action_id = host.running_action_id
	var mastery_action_id = host._fishing_mastery_action_id(action_id) if host._fishing_rework_active_for_skill(skill_id) and not host._is_event_action(action) else action_id
	var old_skill_level = host._skill_level(skill_id)
	var old_global_level = host._global_level()
	var old_mastery_level = MasteryState.level(host.mastery, host._action_key(skill_id, mastery_action_id))
	var completed_achievements_before = AchievementState.completed_ids(AchievementState.milestones(host, false))
	var remaining = offline_seconds
	var completions = 0
	var successes = 0
	var xp_total = 0
	var mastery_total = 0.0
	var fish_total = 0.0
	var logs_spent = 0
	var fishing_rework_attempt = host._fishing_rework_active_for_skill(skill_id) and not host._is_event_action(action)
	while remaining > 0.001:
		var cycle_seconds = _offline_active_cycle_seconds(skill_id, action, host.action_progress, fishing_rework_attempt)
		if (
			cycle_seconds > 0.0
			and remaining >= cycle_seconds * float(host.OFFLINE_ACTIVE_BATCH_MIN_CYCLES)
		):
			var batch_cycles = mini(
				int(floor(remaining / cycle_seconds)),
				host.OFFLINE_ACTIVE_BATCH_MAX_CYCLES
			)
			if batch_cycles >= host.OFFLINE_ACTIVE_BATCH_MIN_CYCLES:
				var batch_result = _grant_offline_action_completion_batch(skill_id, action_id, action, batch_cycles)
				var batch_seconds = float(batch_cycles) * cycle_seconds
				host._apply_stamina_regen_seconds_except(batch_seconds, false, skill_id)
				completions += int(batch_result.get("completions", 0))
				successes += int(batch_result.get("successes", 0))
				xp_total += int(batch_result.get("xp", 0))
				mastery_total += float(batch_result.get("mastery", 0.0))
				fish_total += float(batch_result.get("fish", 0.0))
				logs_spent += int(batch_result.get("logs_spent", 0))
				remaining -= batch_seconds
				host.action_progress = 0.0
				continue
		var cost = _effective_stamina(skill_id, action)
		var action_seconds = _action_cycle_seconds(skill_id, action)
		var progress = clampf(host.action_progress, 0.0, 0.999)
		var stamina_ready = true if fishing_rework_attempt else host._stamina_value(skill_id) + 0.0001 >= cost
		var speed_mult = _action_progress_speed_multiplier(skill_id, action, stamina_ready)
		var seconds_to_complete = maxf(0.001, action_seconds * (1.0 - progress) / speed_mult)
		var seconds_until_ready = INF
		if not stamina_ready and cost <= host._max_stamina(skill_id):
			seconds_until_ready = _seconds_until_stamina_cost(skill_id, cost)
		var step = minf(remaining, minf(seconds_to_complete, seconds_until_ready))
		if remaining < seconds_to_complete:
			host._apply_stamina_regen_seconds(step, false)
			host.action_progress = clampf(progress + step / action_seconds * speed_mult, 0.0, 0.999)
			remaining -= step
			if is_equal_approx(step, seconds_until_ready):
				continue
			break
		host._apply_stamina_regen_seconds(step, false)
		remaining -= step
		if step < seconds_to_complete and is_equal_approx(step, seconds_until_ready):
			host.action_progress = clampf(progress + step / action_seconds * speed_mult, 0.0, 0.999)
			continue
		host.action_progress = 0.0
		if not fishing_rework_attempt:
			host._spend_action_stamina(skill_id, cost)
		var completion = _grant_offline_action_completion(skill_id, action_id, action)
		completions += 1
		if bool(completion.get("success", false)):
			successes += 1
		xp_total += int(completion.get("xp", 0))
		mastery_total += float(completion.get("mastery", 0.0))
		fish_total += float(completion.get("fish", 0.0))
		logs_spent += int(completion.get("logs_spent", 0))
	var new_skill_level = host._skill_level(skill_id)
	var new_global_level = host._global_level()
	var new_mastery_level = MasteryState.level(host.mastery, host._action_key(skill_id, mastery_action_id))
	return {
		"handled": true,
		"skill_id": skill_id,
		"skill_name": host._skill_name(skill_id),
		"action_id": action_id,
		"action_name": str(action.get("name", "activity")),
		"action_art": host._player_facing_action_art_path(skill_id, action),
		"completions": completions,
		"successes": successes,
		"xp": xp_total,
		"mastery": mastery_total,
		"fish": fish_total,
		"logs_spent": logs_spent,
		"old_skill_level": old_skill_level,
		"new_skill_level": new_skill_level,
		"old_global_level": old_global_level,
		"new_global_level": new_global_level,
		"old_mastery_level": old_mastery_level,
		"new_mastery_level": new_mastery_level,
		"unlocked_actions": _offline_unlocked_actions(skill_id, old_skill_level, new_skill_level),
		"achievements": AchievementState.newly_completed(AchievementState.milestones(host, false), completed_achievements_before)
	}


func _offline_active_cycle_seconds(skill_id: String, action: Dictionary, progress: float, fishing_rework: bool) -> float:
	var cost = _effective_stamina(skill_id, action)
	var action_seconds = _action_cycle_seconds(skill_id, action)
	var stamina_ready = fishing_rework or host._stamina_value(skill_id) + 0.0001 >= cost
	var speed_mult = _action_progress_speed_multiplier(skill_id, action, stamina_ready)
	var complete_seconds = maxf(0.001, action_seconds * (1.0 - clampf(progress, 0.0, 0.999)) / speed_mult)
	if fishing_rework or cost <= 0.0 or cost > host._max_stamina(skill_id):
		return complete_seconds
	var regen_bonus = (1.0 + host._hub_surface()._hub_pond_regen_bonus()) * host._honey_stamina_regen_multiplier()
	var regen_seconds = cost * host.STAMINA_REGEN_SECONDS / regen_bonus
	return maxf(complete_seconds, regen_seconds)


func _grant_offline_action_completion_batch(skill_id: String, action_id: String, action: Dictionary, count: int) -> Dictionary:
	if count <= 0:
		return {"completions": 0, "successes": 0, "xp": 0, "mastery": 0.0, "fish": 0.0, "logs_spent": 0}
	var successes = 0
	var xp_total = 0
	var mastery_total = 0.0
	var fish_total = 0.0
	var logs_spent = 0
	var locked_preview_available_before = host._locked_activity_preview_available()
	for _i in range(count):
		var completion = _grant_offline_action_completion(skill_id, action_id, action, true)
		if bool(completion.get("success", false)):
			successes += 1
		xp_total += int(completion.get("xp", 0))
		mastery_total += float(completion.get("mastery", 0.0))
		fish_total += float(completion.get("fish", 0.0))
		logs_spent += int(completion.get("logs_spent", 0))
	host._recalculate_level(skill_id)
	host._passive_modules_runtime().sync_passive_module_unlocks(host._unix_now())
	host._queue_locked_activity_preview_reveal_if_needed(locked_preview_available_before)
	return {
		"completions": count,
		"successes": successes,
		"xp": xp_total,
		"mastery": mastery_total,
		"fish": fish_total,
		"logs_spent": logs_spent
	}


func _apply_offline_convergence_action(offline_seconds: float, module_id: String, action: Dictionary) -> Dictionary:
	if not host._convergence_runtime()._convergence_is_built(module_id):
		host.running_skill_id = ""
		host.running_action_id = ""
		host.action_progress = 0.0
		return {"handled": false}
	var old_levels = {}
	var completed_achievements_before = AchievementState.completed_ids(AchievementState.milestones(host, false))
	for raw_skill_id in host._convergence_runtime()._convergence_skill_order(action):
		old_levels[str(raw_skill_id)] = host._skill_level(str(raw_skill_id))
	var cycle_seconds = host._convergence_runtime()._convergence_total_cycle_seconds(action)
	var remaining = maxf(0.0, offline_seconds)
	var completions = 0
	var xp_total = 0
	while remaining > 0.001:
		if remaining >= cycle_seconds * float(host.OFFLINE_CONVERGENCE_BATCH_MIN_CYCLES):
			var batch_cycles = mini(
				int(floor(remaining / cycle_seconds)),
				host.OFFLINE_CONVERGENCE_BATCH_MAX_CYCLES
			)
			if batch_cycles >= host.OFFLINE_CONVERGENCE_BATCH_MIN_CYCLES:
				var batch_result = _grant_offline_convergence_completion_batch(module_id, action, batch_cycles)
				completions += int(batch_result.get("completions", 0))
				xp_total += int(batch_result.get("xp", 0))
				remaining -= batch_cycles * cycle_seconds
				host.action_progress = 0.0
				continue
		var progress = clampf(host.action_progress, 0.0, 0.999)
		var seconds_to_complete = maxf(0.001, cycle_seconds * (1.0 - progress))
		if remaining < seconds_to_complete:
			host.action_progress = clampf(progress + remaining / cycle_seconds, 0.0, 0.999)
			remaining = 0.0
			break
		remaining -= seconds_to_complete
		host.action_progress = 0.0
		var xp_reward = host._convergence_runtime()._convergence_current_xp(module_id)
		for raw_skill_id in host._convergence_runtime()._convergence_skill_order(action):
			var skill_id = str(raw_skill_id)
			if not host.skills.has(skill_id):
				continue
			host.skills[skill_id]["xp"] = int(host.skills[skill_id].get("xp", 0)) + xp_reward
			host._recalculate_level(skill_id)
		var state = host._convergence_runtime()._ensure_convergence_state(module_id)
		state["completions"] = int(state.get("completions", 0)) + 1
		host.convergence_modules[module_id] = state
		completions += 1
		xp_total += xp_reward * host._convergence_runtime()._convergence_skill_order(action).size()
	var completed_achievements = AchievementState.newly_completed(AchievementState.milestones(host, false), completed_achievements_before)
	return {
		"handled": true,
		"skill_id": "build",
		"skill_name": host._skill_name("build"),
		"action_id": module_id,
		"action_name": str(action.get("name", "Five-Fold Shrine")),
		"action_art": host._player_facing_action_art_path("build", action),
		"completions": completions,
		"successes": completions,
		"xp": xp_total,
		"mastery": 0.0,
		"logs_spent": 0,
		"old_skill_level": int(old_levels.get("build", host._skill_level("build"))),
		"new_skill_level": host._skill_level("build"),
		"old_global_level": 0,
		"new_global_level": host._global_level(),
		"old_mastery_level": 0,
		"new_mastery_level": 0,
		"unlocked_actions": [],
		"achievements": completed_achievements,
		"convergence": true
	}


func _grant_offline_convergence_completion_batch(module_id: String, action: Dictionary, count: int) -> Dictionary:
	if count <= 0:
		return {"completions": 0, "xp": 0}
	var xp_reward = host._convergence_runtime()._convergence_current_xp(module_id)
	var skill_order = host._convergence_runtime()._convergence_skill_order(action)
	var xp_total = 0
	for _i in range(count):
		for raw_skill_id in skill_order:
			var skill_id = str(raw_skill_id)
			if not host.skills.has(skill_id):
				continue
			host.skills[skill_id]["xp"] = int(host.skills[skill_id].get("xp", 0)) + xp_reward
		xp_total += xp_reward * skill_order.size()
	for raw_skill_id in skill_order:
		host._recalculate_level(str(raw_skill_id))
	var state = host._convergence_runtime()._ensure_convergence_state(module_id)
	state["completions"] = int(state.get("completions", 0)) + count
	host.convergence_modules[module_id] = state
	return {"completions": count, "xp": xp_total}


func _seconds_until_stamina_cost(skill_id: String, cost: float) -> float:
	if host._stamina_value(skill_id) + 0.0001 >= cost:
		return 0.0
	var missing = cost - host._stamina_value(skill_id)
	var regen_bonus = (1.0 + host._hub_surface()._hub_pond_regen_bonus()) * host._honey_stamina_regen_multiplier()
	return maxf(0.0, missing * host.STAMINA_REGEN_SECONDS / regen_bonus)


func _grant_offline_action_completion(skill_id: String, action_id: String, action: Dictionary, defer_recalc = false) -> Dictionary:
	if host._fishing_rework_active_for_skill(skill_id) and not host._is_event_action(action):
		return _grant_offline_fishing_action_completion(skill_id, action_id, action, defer_recalc)
	var mastery_reward = _offline_mastery_reward(skill_id, action_id, action)
	var success = _roll_action_success(skill_id, action)
	var xp_reward = 0
	var mastery_gained = 0.0
	var logs_spent = 0
	var old_skill_level = host._skill_level(skill_id)
	var old_mastery_level = MasteryState.level(host.mastery, host._action_key(skill_id, action_id))
	var locked_preview_available_before = host._locked_activity_preview_available()
	if success:
		var plank_bonus_used = host._plank_bonus_applies(skill_id)
		xp_reward = _offline_xp_reward(action, skill_id, plank_bonus_used)
		var berry_prep_reward_map = {}
		berry_prep_reward_map[skill_id] = xp_reward
		var berry_prep_result = host.material_runtime.consume_berry_prep_bonus(skill_id, action_id, berry_prep_reward_map, Callable(host, "_action_data"), Callable(host, "_action_key"))
		host._material_collection_surface().play_berry_prep_badge_feedback(skill_id, action_id, not berry_prep_result.is_empty(), host.material_runtime.berry_prep_matches(skill_id, action_id, Callable(host, "_action_data"), Callable(host, "_action_key")) and host.material_runtime.amount("berries") < 1.0)
		xp_reward += maxi(0, int(berry_prep_result.get("bonus_xp", 0)))
		host.skills[skill_id]["xp"] = int(host.skills[skill_id]["xp"]) + xp_reward
		if mastery_reward > 0.0:
			host._add_mastery_xp(skill_id, action_id, mastery_reward)
			mastery_gained = mastery_reward
			host._register_silver_opportunity_tip_anchor(skill_id, action_id, old_mastery_level, MasteryState.level(host.mastery, host._action_key(skill_id, action_id)))
		if plank_bonus_used:
			host.material_runtime.spend_amount("softwood", 1.0)
			logs_spent = 1
		host._hub_runtime().record_mission_action_completion(skill_id, action_id)
		if not defer_recalc:
			host._recalculate_level(skill_id)
			host._queue_locked_activity_preview_reveal_if_needed(locked_preview_available_before)
			host._passive_modules_runtime().sync_passive_module_unlocks(host._unix_now())
	elif not host._fishing_rework_active_for_skill(skill_id):
		var failure_mastery_reward = 0.0 if MasteryState.would_reward_level_up(host.mastery, host._action_key(skill_id, action_id), mastery_reward, host.MASTERY_MAX_LEVEL) else mastery_reward
		if failure_mastery_reward > 0.0:
			host._add_mastery_xp(skill_id, action_id, failure_mastery_reward)
			mastery_gained = failure_mastery_reward
	if not defer_recalc and host._skill_level(skill_id) > old_skill_level:
		host._invalidate_stat_caches()
	return {
		"success": success,
		"xp": xp_reward,
		"mastery": mastery_gained,
		"fish": 0.0,
		"logs_spent": logs_spent
	}


func _grant_offline_fishing_action_completion(skill_id: String, action_id: String, action: Dictionary, defer_recalc = false) -> Dictionary:
	var success = _roll_action_success(skill_id, action)
	var xp_reward = 0
	var mastery_gained = 0.0
	var fish_gained = 0.0
	var mastery_action_id = host._fishing_mastery_action_id(action_id)
	var old_skill_level = host._skill_level(skill_id)
	var locked_preview_available_before = host._locked_activity_preview_available()
	var direct_fish_currency_reward = FishingState.has_direct_fish_currency_reward(action)
	var netting = host.equipped_fishing_tool_id == "net" and not direct_fish_currency_reward
	var boating = host.equipped_fishing_tool_id == "boat" and not direct_fish_currency_reward
	var rodding = FishingState.is_rod(host.equipped_fishing_tool_id)
	if success:
		if rodding:
			host.fishing_rod_set_in_water = false
		xp_reward = _offline_fishing_xp_reward(action, skill_id)
		host.skills[skill_id]["xp"] = int(host.skills[skill_id]["xp"]) + xp_reward
		var direct_fish_currency_amount = FishingState.roll_direct_fish_currency(action) if direct_fish_currency_reward else 0.0
		var fish_count = 0 if direct_fish_currency_reward else host.fishing_runtime.roll_fish_count(host, action, host.equipped_fishing_tool_id)
		var haul_count = fish_count
		if netting:
			haul_count = _record_offline_fishing_net_success(fish_count, xp_reward)
		elif boating:
			haul_count = _record_offline_fishing_boat_success(fish_count, xp_reward)
		if direct_fish_currency_reward:
			fish_gained = direct_fish_currency_amount
			host._award_fish_currency(fish_gained)
		elif haul_count > 0:
			fish_gained = FishingState.tool_food_value_for_catches(host.equipped_fishing_tool_id, action_id, haul_count)
			host._award_fish_currency(fish_gained)
		var net_fill_without_harvest = netting and haul_count <= 0
		var mastery_reward = _offline_fishing_mastery_reward(skill_id, action_id, net_fill_without_harvest)
		if mastery_reward > 0.0:
			host._add_mastery_xp(skill_id, mastery_action_id, mastery_reward)
			mastery_gained = mastery_reward
			if net_fill_without_harvest:
				host.fishing_runtime.record_mastery_stored("net", mastery_reward)
			elif boating and haul_count <= 0:
				host.fishing_runtime.record_mastery_stored("boat", mastery_reward)
		host._hub_runtime().record_mission_action_completion(skill_id, action_id)
		if not defer_recalc:
			host._recalculate_level(skill_id)
			host._queue_locked_activity_preview_reveal_if_needed(locked_preview_available_before)
			host._passive_modules_runtime().sync_passive_module_unlocks(host._unix_now())
	else:
		host.fishing_runtime.mark_missed(host.equipped_fishing_tool_id)
	if not defer_recalc and host._skill_level(skill_id) > old_skill_level:
		host._invalidate_stat_caches()
	return {
		"success": success,
		"xp": xp_reward,
		"mastery": mastery_gained,
		"fish": fish_gained,
		"logs_spent": 0
	}


func _record_offline_fishing_net_success(fish_count: int, xp_reward: int) -> int:
	return int(host.fishing_runtime.record_batch_success("net", fish_count, xp_reward, host.FISHING_NET_HAUL_THRESHOLD, host.FISHING_NET_HAUL_VISUAL_SECONDS).get("haul_count", 0))


func _record_offline_fishing_boat_success(fish_count: int, xp_reward: int) -> int:
	return int(host.fishing_runtime.record_batch_success("boat", fish_count, xp_reward, host.FISHING_BOAT_HAUL_THRESHOLD, host.FISHING_BOAT_HAUL_VISUAL_SECONDS).get("haul_count", 0))


func _offline_xp_reward(action: Dictionary, skill_id: String, force_plank_bonus = false) -> int:
	if _fishing_net_soak_active(skill_id):
		return maxi(1, int(round(float(FishingState.net_xp_reward(host, action)) * host.OFFLINE_XP_MULT)))
	return maxi(1, int(round(float(host._effective_xp(action, skill_id, force_plank_bonus)) * host.OFFLINE_XP_MULT)))


func _offline_fishing_xp_reward(action: Dictionary, skill_id: String) -> int:
	var xp_reward = host._fishing_flat_xp_reward(action, skill_id)
	if xp_reward <= 0:
		return 0
	return maxi(1, int(round(float(xp_reward) * host.OFFLINE_XP_MULT)))


func _offline_mastery_reward(skill_id: String, action_id: String, action: Dictionary) -> float:
	return maxf(0.0, host._mastery_reward_for_action(skill_id, action_id, action) * host.OFFLINE_XP_MULT)


func _offline_fishing_mastery_reward(skill_id: String, action_id: String, net_fill_without_harvest = false) -> float:
	var mastery_reward = FishingState.mastery_reward(host, skill_id, action_id)
	if net_fill_without_harvest:
		mastery_reward *= host.FISHING_NET_FILL_MASTERY_MULT
	return maxf(0.0, mastery_reward * host.OFFLINE_XP_MULT)


func _offline_unlocked_actions(_skill_id: String, _old_level: int, _new_level: int) -> Array:
	return []
