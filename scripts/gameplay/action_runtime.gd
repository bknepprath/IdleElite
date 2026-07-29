extends RefCounted

const BuildableModules = preload("res://scripts/gameplay/buildable_modules.gd")
const RecoveryModules = preload("res://scripts/gameplay/recovery_modules.gd")
const AchievementState = preload("res://scripts/achievements/state.gd")
const MasteryState = preload("res://scripts/progression/mastery_state.gd")
const SkillState = preload("res://scripts/progression/skill_state.gd")
const FishingState = preload("res://scripts/fishing/state.gd")
const GameFormatting = preload("res://scripts/core/formatting.gd")
const PassiveModulesRuntime = preload("res://scripts/gameplay/passive_modules_runtime.gd")
const RegenCircle = preload("res://scripts/ui/regen_circle.gd")

const OFFLINE_XP_MULT := 0.30
const OFFLINE_ACTIVE_BATCH_MIN_CYCLES := 12
const OFFLINE_ACTIVE_BATCH_MAX_CYCLES := 512
const OFFLINE_CONVERGENCE_BATCH_MIN_CYCLES := 12
const OFFLINE_CONVERGENCE_BATCH_MAX_CYCLES := 512
const ACTIVITY_STREAK_BONUS_STEP := 5
const ACTIVITY_NORMAL_CRIT_CHANCE := 0.01
const ACTIVITY_STREAK_CRIT_CHANCE := 0.10
const ACTIVITY_CRIT_XP_MULT := 3
const AUTO_EAT_FISH_AFTER_SPEND_VISUAL_DELAY_MSEC := 180
const GUARANTEED_SUCCESS_ACTION_COMPLETIONS := 7
const ACTION_OPPORTUNITY_MIN_MEDAL_LEVEL := 2
const ACTION_OPPORTUNITY_SILVER_WINDOW := Vector2(0.52, 0.73)
const ACTION_OPPORTUNITY_GOLD_MIN_MEDAL_LEVEL := 3
const ACTION_OPPORTUNITY_GOLD_WIDTH := 0.19
const ACTION_OPPORTUNITY_GOLD_SWAY := 0.028
const ACTION_OPPORTUNITY_GOLD_MOVE_SECONDS := 1.35
const ACTION_OPPORTUNITY_GOLD_PAUSE_SECONDS := 0.7
const ACTION_OPPORTUNITY_PLATINUM_MIN_MEDAL_LEVEL := 4
const ACTION_OPPORTUNITY_PLATINUM_WINDOW := Vector2(0.10, 0.50)
const ACTION_OPPORTUNITY_TRIPLE_CLICK_MAX_STACKS := 3
const ACTION_OPPORTUNITY_TRIPLE_CLICK_SPEED_PER_STACK := 0.12
const ACTION_OPPORTUNITY_SAPPHIRE_MIN_MEDAL_LEVEL := 5
const ACTION_OPPORTUNITY_SAPPHIRE_LEFT_STOP := 0.05
const ACTION_OPPORTUNITY_SAPPHIRE_SLIDE_SECONDS := 2.2
const ACTION_OPPORTUNITY_EMERALD_MIN_MEDAL_LEVEL := 6
const ACTION_OPPORTUNITY_EMERALD_MAX_WINDOW := Vector2(0.30, 0.70)
const ACTION_OPPORTUNITY_EMERALD_MIN_WINDOW := Vector2(0.42, 0.58)
const ACTION_OPPORTUNITY_EMERALD_SHRINK_PER_SUCCESS := 0.015
const ACTION_OPPORTUNITY_EMERALD_SHRINK_SECONDS := 0.42
const ACTION_OPPORTUNITY_RUBY_MIN_MEDAL_LEVEL := 7
const ACTION_OPPORTUNITY_RUBY_WINDOW_WIDTH := 0.26
const ACTION_OPPORTUNITY_RUBY_START_LEFT := 0.37
const ACTION_OPPORTUNITY_RUBY_STEP := 0.03
const ACTION_OPPORTUNITY_RUBY_MOVE_SECONDS := 0.42
const ACTION_OPPORTUNITY_DIAMOND_MIN_MEDAL_LEVEL := 8
const ACTION_OPPORTUNITY_DIAMOND_WIDTH := 0.19
const ACTION_OPPORTUNITY_DIAMOND_SWAY := 0.052
const ACTION_OPPORTUNITY_DIAMOND_MOVE_SECONDS := ACTION_OPPORTUNITY_GOLD_MOVE_SECONDS * 0.8
const ACTION_OPPORTUNITY_DIAMOND_PAUSE_SECONDS := ACTION_OPPORTUNITY_GOLD_PAUSE_SECONDS * 0.8
const ACTION_OPPORTUNITY_DIRECT_PROGRESS := 0.025
const ACTION_OPPORTUNITY_BOOST_SECONDS := 1.25
const ACTION_OPPORTUNITY_BOOST_MULT := 1.65
const ACTION_OPPORTUNITY_REGEN_SECONDS := 3.0
const ACTION_OPPORTUNITY_REGEN_MULT := 2.5
const ACTION_OPPORTUNITY_DUPLICATE_TAP_MSEC := 90
const ACTION_OPPORTUNITY_FORGIVENESS_IDEAL_SECONDS := 0.48
const ACTION_OPPORTUNITY_FORGIVENESS_MIN_SECONDS := 0.18
const ACTION_OPPORTUNITY_FORGIVENESS_MAX_EXTRA_WIDTH := 1.05
const ACTION_OPPORTUNITY_MISS_EXPAND_PER_SIDE := 0.005
const ACTION_OPPORTUNITY_MISS_EXPAND_SECONDS := 0.36
const STAMINA_GAUGE_REGEN_BOOST_MULT := 3.0
const STAMINA_GAUGE_REGEN_EASE_SPEED := 7.5
const STAMINA_GAUGE_HOLD_BOOST_SECONDS := 0.24

var host
var stamina_gauge_regen_multiplier := 1.0
var stamina_gauge_regen_target_multiplier := 1.0
var stamina_gauge_boost_skill_id := ""
var stamina_gauge_pending_click := false
var stamina_gauge_pending_skill_id := ""
var stamina_gauge_pending_hold_seconds := 0.0
var stamina_gauge_press_active := false
var stamina_gauge_press_source: RegenCircle
var action_opportunity_consumed := false
var action_opportunity_missed := false
var action_opportunity_boost_seconds := 0.0
var action_opportunity_boost_duration := 0.0
var action_opportunity_regen_skill_id := ""
var action_opportunity_regen_seconds := 0.0
var action_opportunity_cycle_elapsed := 0.0
var action_opportunity_triple_click_stacks := 0
var action_opportunity_emerald_shrink_steps := 0
var action_opportunity_emerald_window := ACTION_OPPORTUNITY_EMERALD_MAX_WINDOW
var action_opportunity_emerald_start_window := ACTION_OPPORTUNITY_EMERALD_MAX_WINDOW
var action_opportunity_emerald_target_window := ACTION_OPPORTUNITY_EMERALD_MAX_WINDOW
var action_opportunity_emerald_transition_elapsed := ACTION_OPPORTUNITY_EMERALD_SHRINK_SECONDS
var action_opportunity_ruby_left := ACTION_OPPORTUNITY_RUBY_START_LEFT
var action_opportunity_ruby_start_left := ACTION_OPPORTUNITY_RUBY_START_LEFT
var action_opportunity_ruby_target_left := ACTION_OPPORTUNITY_RUBY_START_LEFT
var action_opportunity_ruby_transition_elapsed := ACTION_OPPORTUNITY_RUBY_MOVE_SECONDS
var action_opportunity_miss_expand_per_side := 0.0
var action_opportunity_miss_expand_start := 0.0
var action_opportunity_miss_expand_target := 0.0
var action_opportunity_miss_expand_elapsed := ACTION_OPPORTUNITY_MISS_EXPAND_SECONDS
var action_opportunity_persistent_windows: Array[Vector2] = []
var action_opportunity_persistent_key := ""
var last_action_opportunity_tap_key := ""
var last_action_opportunity_tap_msec := 0
var auto_eat_fish_after_spend_due_msec_by_skill := {}
var action_progress_speed_key := ""
var action_progress_speed_mult_current := 1.0
var activity_streak_action_key := ""
var activity_streak_count := 0
var activity_start_count := 0
var activity_completion_count := 0
var guaranteed_success_action_completions := 0
var consecutive_activity_crit_count := 0
var stat_cache_version := 0
var action_stat_value_cache := {}


func _init(host_ref) -> void:
	host = host_ref


func _on_stamina_gauge_input(event: InputEvent, skill_id: String = "", source: RegenCircle = null) -> void:
	if host._stamina_gauge_event_hits_auto_eat_toggle(event):
		_cancel_pending_stamina_gauge_click()
		host.get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		host.button_press_runtime._suppress_stamina_gauge_parent_button(source)
		if event.pressed:
			_begin_stamina_gauge_click_or_hold(skill_id, source)
		else:
			_finish_stamina_gauge_click_or_hold(skill_id, source)
		host.get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		host.button_press_runtime._suppress_stamina_gauge_parent_button(source)
		if event.pressed:
			_begin_stamina_gauge_click_or_hold(skill_id, source)
		else:
			_finish_stamina_gauge_click_or_hold(skill_id, source)
		host.get_viewport().set_input_as_handled()


func _cancel_pending_stamina_gauge_click() -> void:
	stamina_gauge_pending_click = false
	stamina_gauge_pending_skill_id = ""
	stamina_gauge_pending_hold_seconds = 0.0
	stamina_gauge_press_source = null


func _is_stamina_gauge_release_event(event: InputEvent) -> bool:
	if not stamina_gauge_press_active and not stamina_gauge_pending_click:
		return false
	if event is InputEventMouseButton:
		return event.button_index == MOUSE_BUTTON_LEFT and not event.pressed
	if event is InputEventScreenTouch:
		return not event.pressed
	return false


func _begin_stamina_gauge_click_or_hold(skill_id: String = "", source: RegenCircle = null) -> void:
	var target_skill_id: String = skill_id if not skill_id.is_empty() else host.selected_skill_id
	if target_skill_id.is_empty() or not _stamina_gauge_interaction_screen_active():
		return
	host._skill_swipe_activity_surface()._cancel_skill_swipe_feedback(false)
	stamina_gauge_pending_click = true
	stamina_gauge_pending_skill_id = target_skill_id
	stamina_gauge_pending_hold_seconds = 0.0
	stamina_gauge_press_source = source


func _stamina_gauge_interaction_screen_active() -> bool:
	return host.current_screen == "skill" or host.current_screen == "menu" or host.current_screen == "pinned" or host.current_screen == "queue"


func _finish_stamina_gauge_click_or_hold(skill_id: String = "", source: RegenCircle = null) -> void:
	if stamina_gauge_pending_click:
		var target_skill_id := stamina_gauge_pending_skill_id
		var target_source := stamina_gauge_press_source if stamina_gauge_press_source != null else source
		stamina_gauge_pending_click = false
		stamina_gauge_pending_skill_id = ""
		stamina_gauge_pending_hold_seconds = 0.0
		stamina_gauge_press_source = null
		_try_eat_fish_for_stamina(target_skill_id if not target_skill_id.is_empty() else skill_id, target_source)
		return
	_set_stamina_gauge_pressed(false, skill_id, source)


func _set_stamina_gauge_pressed(pressed: bool, skill_id: String = "", source: RegenCircle = null) -> void:
	if pressed:
		var boost_skill_id: String = skill_id if not skill_id.is_empty() else host.selected_skill_id
		if boost_skill_id.is_empty() or (host.current_screen != "skill" and host.current_screen != "menu"):
			return
		stamina_gauge_press_active = true
		stamina_gauge_boost_skill_id = boost_skill_id
		stamina_gauge_press_source = source
		stamina_gauge_regen_target_multiplier = STAMINA_GAUGE_REGEN_BOOST_MULT
		host._skill_swipe_activity_surface()._cancel_skill_swipe_feedback(false)
		host._reward_feedback_surface()._pop_stamina_gauge(source)
	else:
		stamina_gauge_pending_click = false
		stamina_gauge_pending_skill_id = ""
		stamina_gauge_pending_hold_seconds = 0.0
		stamina_gauge_press_active = false
		stamina_gauge_press_source = null
		host.stamina_gauge_pre_tip_hold_seconds = 0.0
		stamina_gauge_regen_target_multiplier = 1.0


func _cancel_stamina_gauge_boost_for_navigation() -> void:
	stamina_gauge_pending_click = false
	stamina_gauge_pending_skill_id = ""
	stamina_gauge_pending_hold_seconds = 0.0
	stamina_gauge_press_active = false
	stamina_gauge_boost_skill_id = ""
	stamina_gauge_press_source = null
	host.stamina_gauge_pre_tip_hold_seconds = 0.0
	stamina_gauge_regen_multiplier = 1.0
	stamina_gauge_regen_target_multiplier = 1.0
	host._reward_feedback_surface()._clear_stamina_gauge_pop_tween()


func _release_current_stamina_gauge_press_state() -> void:
	stamina_gauge_pending_click = false
	stamina_gauge_pending_skill_id = ""
	stamina_gauge_pending_hold_seconds = 0.0
	stamina_gauge_press_active = false
	stamina_gauge_press_source = null


func _process_stamina_gauge_regen_boost(delta: float) -> void:
	if delta <= 0.0:
		return
	if (
		not stamina_gauge_pending_click
		and not stamina_gauge_press_active
		and stamina_gauge_regen_target_multiplier <= 1.0
		and absf(stamina_gauge_regen_multiplier - 1.0) <= 0.001
	):
		stamina_gauge_regen_multiplier = 1.0
		stamina_gauge_boost_skill_id = ""
		return
	if stamina_gauge_pending_click and not _stamina_gauge_interaction_screen_active():
		_set_stamina_gauge_pressed(false)
	if stamina_gauge_pending_click:
		stamina_gauge_pending_hold_seconds += delta
		if stamina_gauge_pending_hold_seconds >= STAMINA_GAUGE_HOLD_BOOST_SECONDS:
			var boost_skill_id := stamina_gauge_pending_skill_id
			var boost_source := stamina_gauge_press_source
			stamina_gauge_pending_click = false
			stamina_gauge_pending_skill_id = ""
			stamina_gauge_pending_hold_seconds = 0.0
			_set_stamina_gauge_pressed(true, boost_skill_id, boost_source)
	if stamina_gauge_press_active and host.current_screen != "skill" and host.current_screen != "menu":
		_set_stamina_gauge_pressed(false)
	var target := clampf(stamina_gauge_regen_target_multiplier, 1.0, STAMINA_GAUGE_REGEN_BOOST_MULT)
	var weight := 1.0 - exp(-STAMINA_GAUGE_REGEN_EASE_SPEED * delta)
	stamina_gauge_regen_multiplier = lerpf(stamina_gauge_regen_multiplier, target, weight)
	if absf(stamina_gauge_regen_multiplier - target) <= 0.001:
		stamina_gauge_regen_multiplier = target
		if not stamina_gauge_press_active and target <= 1.0:
			stamina_gauge_boost_skill_id = ""


func _stamina_gauge_regen_multiplier_for_skill(skill_id: String) -> float:
	return stamina_gauge_regen_multiplier if skill_id == stamina_gauge_boost_skill_id else 1.0


func _apply_stamina_regen_seconds(seconds: float, allow_gauge_boost := false) -> void:
	_apply_stamina_regen_seconds_except(seconds, allow_gauge_boost, "")


func _apply_stamina_regen_seconds_except(seconds: float, allow_gauge_boost := false, excluded_skill_id := "") -> void:
	if seconds <= 0.0:
		return
	var honey_result := SkillState.honey_adjusted_stamina_regen_seconds(
		seconds,
		host.skill_defs,
		host.stamina,
		func(skill_id: String) -> int: return SkillState.max_stamina(host, skill_id),
		excluded_skill_id,
		host.honey_stamina_seconds_remaining,
		Callable(self, "_honey_can_consume_for_stamina"),
		func() -> bool: return host.material_runtime.spend_amount("honey", 1.0)
	)
	host.honey_stamina_seconds_remaining = float(honey_result["honey_seconds_remaining"])
	var honey_adjusted_seconds := float(honey_result["seconds"])
	for def in host.skill_defs:
		var skill_id := str(def["id"])
		if skill_id == excluded_skill_id:
			continue
		var max_stamina: int = SkillState.max_stamina(host, skill_id)
		if SkillState.host_stamina_value(skill_id, host) >= float(max_stamina):
			host.stamina_bank[skill_id] = 0.0
			continue
		var regen_delta: float = honey_adjusted_seconds * (1.0 + host._hub_surface()._hub_pond_regen_bonus())
		regen_delta *= 1.0 + host._passive_modules_runtime().firepit_stamina_regen_bonus(skill_id, host._unix_now())
		if allow_gauge_boost:
			regen_delta *= _stamina_gauge_regen_multiplier_for_skill(skill_id)
		if allow_gauge_boost and skill_id == action_opportunity_regen_skill_id and action_opportunity_regen_seconds > 0.0:
			regen_delta *= ACTION_OPPORTUNITY_REGEN_MULT
		var next_bank: float = clampf(float(host.stamina_bank.get(skill_id, 0.0)), 0.0, host.STAMINA_REGEN_SECONDS) + regen_delta
		var recovered_stamina := int(floor(next_bank / host.STAMINA_REGEN_SECONDS))
		var next_stamina: float = SkillState.host_stamina_value(skill_id, host)
		if recovered_stamina > 0:
			next_stamina = minf(float(max_stamina), next_stamina + float(recovered_stamina))
		host.stamina[skill_id] = next_stamina
		host.stamina_bank[skill_id] = 0.0 if next_stamina >= float(max_stamina) - 0.0001 else fmod(next_bank, host.STAMINA_REGEN_SECONDS)
		SkillState.host_sync_stamina_bank(skill_id, host)


func _honey_can_consume_for_stamina() -> bool:
	return host.material_runtime.amount("honey") >= 1.0


func player_has_stamina_honey() -> bool:
	return host.honey_stamina_seconds_remaining > 0.0001 or _honey_can_consume_for_stamina()


func _try_eat_fish_for_stamina(skill_id: String = "", source: RegenCircle = null) -> void:
	var target_skill_id: String = skill_id if not skill_id.is_empty() else host.selected_skill_id
	var target: RegenCircle = host._reward_feedback_surface()._visible_stamina_gauge_for_skill(target_skill_id, source)
	if target_skill_id.is_empty() or not _stamina_gauge_interaction_screen_active():
		return
	host._skill_swipe_activity_surface()._cancel_skill_swipe_feedback(false)
	if SkillState.host_stamina_value(target_skill_id, host) >= float(SkillState.max_stamina(host, target_skill_id)) - 0.0001:
		host._reward_feedback_surface()._float_stamina_full(target)
		host._reward_feedback_surface()._play_stamina_gauge_eat_fail(target)
		return
	if host.fishing_runtime.fish_currency < 1.0:
		host._reward_feedback_surface()._float_stamina_need_fish(target)
		host._reward_feedback_surface()._play_stamina_gauge_eat_fail(target)
		return
	host.fishing_runtime.fish_currency = maxf(0.0, host.fishing_runtime.fish_currency - 1.0)
	host.stamina[target_skill_id] = minf(float(SkillState.max_stamina(host, target_skill_id)), SkillState.host_stamina_value(target_skill_id, host) + 1.0)
	SkillState.host_sync_stamina_bank(target_skill_id, host)
	host._reward_feedback_surface()._pop_stamina_gauge(target)
	host._fishing_ui_surface()._float_eaten_fish_icon(target_skill_id, target)
	host._audio_director()._play_fish_eat_blip()
	host._update_ui(0.0, true)
	host.save_game()


func reset_activity_counts() -> void:
	activity_start_count = 0
	activity_completion_count = 0
	guaranteed_success_action_completions = 0


func record_activity_start() -> void:
	activity_start_count += 1


func record_activity_completion() -> void:
	activity_completion_count += 1


func guaranteed_success_limit() -> int:
	return GUARANTEED_SUCCESS_ACTION_COMPLETIONS


func record_successful_activity_completion(action_key: String) -> int:
	if activity_streak_action_key == action_key:
		activity_streak_count += 1
	else:
		activity_streak_action_key = action_key
		activity_streak_count = 1
	return ((activity_streak_count - 1) % ACTIVITY_STREAK_BONUS_STEP) + 1


func reset_activity_completion_streak() -> void:
	activity_streak_action_key = ""
	activity_streak_count = 0


func reset_consecutive_activity_crits() -> void:
	consecutive_activity_crit_count = 0


static func uses_diamond_arena(action: Dictionary) -> bool:
	var combat: Variant = action.get("combat", {})
	if typeof(combat) != TYPE_DICTIONARY:
		return false
	return str((combat as Dictionary).get("arena_shape", "")).to_lower() == "diamond"


func _action_xp_reward_parts_for_display(skill_id: String, action: Dictionary) -> Array:
	var rewards := _effective_xp_reward_map(action, skill_id)
	var parts := []
	for reward_skill_id in _ordered_xp_reward_skill_ids(skill_id, rewards):
		var amount := maxi(0, int(rewards.get(reward_skill_id, 0)))
		if amount <= 0:
			continue
		parts.append({
			"skill": reward_skill_id,
			"amount": amount,
			"theme_color": ThemeStyles.skill_theme_color(reward_skill_id, host.COLOR_BLUE)
		})
	if parts.is_empty():
		parts.append({
			"skill": skill_id,
			"amount": _effective_xp(action, skill_id),
			"theme_color": ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE)
		})
	return parts


func _base_xp_reward_parts_for_display(skill_id: String, action: Dictionary) -> Array:
	var rewards := _base_xp_reward_map(action, skill_id)
	var parts := []
	for reward_skill_id in _ordered_xp_reward_skill_ids(skill_id, rewards):
		var amount := maxi(0, int(rewards.get(reward_skill_id, 0)))
		if amount <= 0:
			continue
		parts.append({
			"skill": reward_skill_id,
			"amount": amount,
			"theme_color": ThemeStyles.skill_theme_color(reward_skill_id, host.COLOR_BLUE)
		})
	if parts.is_empty():
		parts.append({
			"skill": skill_id,
			"amount": maxi(1, int(action.get("xp", 1))),
			"theme_color": ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE)
		})
	return parts


func _xp_reward_result_phrase(reward_map: Dictionary, owner_skill_id := "") -> String:
	var packed := PackedStringArray()
	var ordered_skill_ids := _ordered_xp_reward_skill_ids(owner_skill_id, reward_map)
	var visible_count := 0
	for raw_skill_id in ordered_skill_ids:
		if int(reward_map.get(str(raw_skill_id), 0)) > 0:
			visible_count += 1
	for raw_skill_id in ordered_skill_ids:
		var skill_id := str(raw_skill_id)
		var amount := maxi(0, int(reward_map.get(skill_id, 0)))
		if amount <= 0:
			continue
		if visible_count > 1:
			packed.append("+%s %s XP" % [GameFormatting.info_chip_number(float(amount)), SkillState.skill_name(host.skill_defs, skill_id)])
		else:
			packed.append("+%s XP" % GameFormatting.info_chip_number(float(amount)))
	if packed.is_empty():
		packed.append("+0 XP")
	return ", ".join(packed)


func _xp_reward_result_sentence(reward_map: Dictionary, owner_skill_id: String, action_name: String) -> String:
	return "%s from %s." % [_xp_reward_result_phrase(reward_map, owner_skill_id), action_name]


func _ordered_xp_reward_skill_ids(owner_skill_id: String, rewards: Dictionary) -> Array:
	var ordered := []
	if rewards.has(owner_skill_id):
		ordered.append(owner_skill_id)
	for raw_def in host.skill_defs:
		var skill_def := raw_def as Dictionary
		var skill_id := str(skill_def.get("id", ""))
		if skill_id.is_empty() or skill_id == owner_skill_id or not rewards.has(skill_id):
			continue
		ordered.append(skill_id)
	for raw_skill_id in rewards.keys():
		var skill_id := str(raw_skill_id)
		if not skill_id.is_empty() and not ordered.has(skill_id):
			ordered.append(skill_id)
	return ordered


func _action_xp_reward_total(parts: Array) -> int:
	var total := 0
	for raw_part in parts:
		if typeof(raw_part) != TYPE_DICTIONARY:
			continue
		total += maxi(0, int((raw_part as Dictionary).get("amount", 0)))
	return maxi(1, total)


func _distribute_xp_reward_map_to_total(template: Dictionary, owner_skill_id: String, target_total: int) -> Dictionary:
	var template_total := _reward_map_total(template)
	if template_total <= 0:
		var empty_template_rewards := {}
		if not owner_skill_id.is_empty():
			empty_template_rewards[owner_skill_id] = maxi(1, target_total)
		return empty_template_rewards
	var rewards := {}
	var ordered_skill_ids := _ordered_xp_reward_skill_ids(owner_skill_id, template)
	var assigned := 0
	for raw_skill_id in ordered_skill_ids:
		var reward_skill_id := str(raw_skill_id)
		var template_amount := maxi(0, int(template.get(reward_skill_id, 0)))
		if reward_skill_id.is_empty() or template_amount <= 0:
			continue
		var amount := maxi(1, int(floor(float(maxi(1, target_total)) * float(template_amount) / float(template_total))))
		rewards[reward_skill_id] = amount
		assigned += amount
	if rewards.is_empty():
		var missing_split_rewards := {}
		if not owner_skill_id.is_empty():
			missing_split_rewards[owner_skill_id] = maxi(1, target_total)
		return missing_split_rewards
	var remainder := maxi(1, target_total) - assigned
	var remainder_skill := owner_skill_id if rewards.has(owner_skill_id) else str(ordered_skill_ids[0])
	rewards[remainder_skill] = maxi(1, int(rewards.get(remainder_skill, 0)) + remainder)
	return rewards


func _effective_xp(action: Dictionary, skill_id := "", force_plank_bonus := false) -> int:
	var cache_key := _action_stat_value_cache_key("xp:%s" % force_plank_bonus, skill_id, action)
	if action_stat_value_cache.has(cache_key):
		return int(action_stat_value_cache[cache_key])
	var value := _effective_xp_reward_amount(action, skill_id, skill_id, maxi(1, int(action.get("xp", 1))), force_plank_bonus)
	action_stat_value_cache[cache_key] = value
	return value


func _effective_xp_reward_map(action: Dictionary, owner_skill_id := "", force_plank_bonus := false) -> Dictionary:
	var rewards := {}
	var base_rewards := _base_xp_reward_map(action, owner_skill_id)
	for raw_skill_id in base_rewards.keys():
		var reward_skill_id := str(raw_skill_id)
		var base_amount := maxi(0, int(base_rewards.get(raw_skill_id, 0)))
		if reward_skill_id.is_empty() or base_amount <= 0:
			continue
		rewards[reward_skill_id] = _effective_xp_reward_amount(action, owner_skill_id, reward_skill_id, base_amount, force_plank_bonus)
	if rewards.is_empty():
		rewards[owner_skill_id] = _effective_xp(action, owner_skill_id, force_plank_bonus)
	return _cap_xp_reward_map_total(action, owner_skill_id, rewards)


func _cap_xp_reward_map_total(action: Dictionary, owner_skill_id: String, reward_map: Dictionary) -> Dictionary:
	var cap: int = _xp_reward_cap_for_action(action)
	if cap <= 0:
		return reward_map
	var total := _reward_map_total(reward_map)
	if total <= cap:
		return reward_map
	return _distribute_xp_reward_map_to_total(reward_map, owner_skill_id, cap)


func _xp_reward_cap_for_action(action: Dictionary) -> int:
	var cap := int(action.get("xp_reward_cap", 0))
	if cap > 0:
		return cap
	var event_meta = action.get("event", {})
	if typeof(event_meta) == TYPE_DICTIONARY:
		return maxi(0, int((event_meta as Dictionary).get("xp_reward_cap", 0)))
	return 0


func _completion_xp_reward_map(action: Dictionary, owner_skill_id: String, force_plank_bonus: bool, xp_crit: bool, mega_crit: bool, streak_bonus: bool) -> Dictionary:
	var rewards := _effective_xp_reward_map(action, owner_skill_id, force_plank_bonus)
	var multiplier := _completion_xp_multiplier(xp_crit, mega_crit, streak_bonus)
	if multiplier <= 1:
		return rewards
	for raw_skill_id in rewards.keys():
		var skill_id := str(raw_skill_id)
		rewards[skill_id] = maxi(1, int(rewards.get(raw_skill_id, 0)) * multiplier)
	return rewards


func _fishing_completion_xp_reward_map(action: Dictionary, owner_skill_id: String) -> Dictionary:
	var rewards := _effective_xp_reward_map(action, owner_skill_id, false)
	rewards[owner_skill_id] = host.fishing_runtime.flat_xp_reward(host, action, owner_skill_id)
	return rewards


func _apply_xp_reward_map(owner_skill_id: String, reward_map: Dictionary) -> Array:
	var affected_skill_ids := []
	for reward_skill_id in _ordered_xp_reward_skill_ids(owner_skill_id, reward_map):
		var amount := maxi(0, int(reward_map.get(reward_skill_id, 0)))
		if amount <= 0 or not host.skills.has(reward_skill_id):
			continue
		host.skills[reward_skill_id]["xp"] = int(host.skills[reward_skill_id].get("xp", 0)) + amount
		if not affected_skill_ids.has(reward_skill_id):
			affected_skill_ids.append(reward_skill_id)
	return affected_skill_ids


func _skill_levels_for_reward_map(owner_skill_id: String, reward_map: Dictionary) -> Dictionary:
	var levels := {}
	for reward_skill_id in _ordered_xp_reward_skill_ids(owner_skill_id, reward_map):
		if host.skills.has(reward_skill_id):
			levels[reward_skill_id] = SkillState.host_skill_level(host, reward_skill_id)
	return levels


func _reward_map_total(reward_map: Dictionary) -> int:
	var total := 0
	for amount in reward_map.values():
		total += maxi(0, int(amount))
	return total


func _any_reward_skill_leveled_up(affected_skill_ids: Array, old_levels: Dictionary) -> bool:
	for raw_skill_id in affected_skill_ids:
		var skill_id := str(raw_skill_id)
		if not host.skills.has(skill_id):
			continue
		if SkillState.host_skill_level(host, skill_id) > int(old_levels.get(skill_id, SkillState.host_skill_level(host, skill_id))):
			return true
	return false


func _completion_xp_multiplier(xp_crit: bool, mega_crit: bool, streak_bonus: bool) -> int:
	if mega_crit:
		return 9
	if xp_crit:
		return ACTIVITY_CRIT_XP_MULT
	if streak_bonus:
		return 2
	return 1


func _base_xp_reward_map(action: Dictionary, owner_skill_id := "") -> Dictionary:
	var rewards := {}
	var raw_rewards = action.get("xp_rewards", {})
	if typeof(raw_rewards) == TYPE_DICTIONARY:
		for raw_skill_id in (raw_rewards as Dictionary).keys():
			var reward_skill_id := str(raw_skill_id).strip_edges()
			var amount := maxi(0, int((raw_rewards as Dictionary).get(raw_skill_id, 0)))
			if amount > 0:
				amount = host._temporary_event_runtime()._temporary_event_scaled_reward_amount(action, amount)
			if not reward_skill_id.is_empty() and amount > 0:
				rewards[reward_skill_id] = amount
	if rewards.is_empty():
		rewards[owner_skill_id] = host._temporary_event_runtime()._temporary_event_scaled_reward_amount(action, maxi(1, int(action.get("xp", 1))))
	return rewards


func _effective_xp_reward_amount(action: Dictionary, owner_skill_id: String, reward_skill_id: String, base_amount: int, force_plank_bonus := false) -> int:
	var xp_bonus: float = AchievementState.global_reward_bonus(host, "xp_mult", reward_skill_id) + host._ad_bonus_runtime().xp_multiplier()
	if reward_skill_id == owner_skill_id and (force_plank_bonus or host._passive_modules_runtime().plank_bonus_applies(owner_skill_id)):
		xp_bonus += PassiveModulesRuntime.PLANK_BUILD_XP_MULT
	if reward_skill_id == owner_skill_id and host._hub_runtime().mission_bonus_applies(owner_skill_id, action):
		xp_bonus += host._hub_runtime().mission_xp_bonus()
	return maxi(1, int(round(float(maxi(1, base_amount)) * (1.0 + xp_bonus))))


func _action_opportunity_frame_work_needed() -> bool:
	return (
		action_opportunity_boost_seconds > 0.0
		or action_opportunity_miss_expand_elapsed < ACTION_OPPORTUNITY_MISS_EXPAND_SECONDS
		or action_opportunity_emerald_transition_elapsed < ACTION_OPPORTUNITY_EMERALD_SHRINK_SECONDS
		or action_opportunity_ruby_transition_elapsed < ACTION_OPPORTUNITY_RUBY_MOVE_SECONDS
	)


func _action_opportunity_windows(skill_id: String, action_id: String) -> Array[Vector2]:
	return _action_opportunity_pattern_windows(skill_id, action_id)


func _action_opportunity_pattern_windows(skill_id: String, action_id: String) -> Array[Vector2]:
	var windows := _action_opportunity_raw_pattern_windows(skill_id, action_id)
	windows = _action_opportunity_apply_miss_expansion(windows)
	return _action_opportunity_apply_speed_forgiveness(skill_id, action_id, windows)


func _action_opportunity_raw_pattern_windows(skill_id: String, action_id: String) -> Array[Vector2]:
	var medal_level: int = int(MasteryState.level(host.mastery, host._action_key(skill_id, action_id)))
	if medal_level < ACTION_OPPORTUNITY_MIN_MEDAL_LEVEL:
		return []
	if (
		_action_opportunity_uses_persistent_window(skill_id, action_id)
		and action_opportunity_persistent_key == host._action_key(skill_id, action_id)
		and not action_opportunity_persistent_windows.is_empty()
	):
		return action_opportunity_persistent_windows.duplicate()
	if medal_level >= ACTION_OPPORTUNITY_DIAMOND_MIN_MEDAL_LEVEL:
		return [_action_opportunity_diamond_window()]
	if medal_level >= ACTION_OPPORTUNITY_RUBY_MIN_MEDAL_LEVEL:
		return [_action_opportunity_ruby_window()]
	if medal_level >= ACTION_OPPORTUNITY_EMERALD_MIN_MEDAL_LEVEL:
		return [_action_opportunity_emerald_window()]
	if medal_level >= ACTION_OPPORTUNITY_SAPPHIRE_MIN_MEDAL_LEVEL:
		return [_action_opportunity_sapphire_window()]
	if medal_level >= ACTION_OPPORTUNITY_PLATINUM_MIN_MEDAL_LEVEL:
		return [ACTION_OPPORTUNITY_PLATINUM_WINDOW]
	if medal_level >= ACTION_OPPORTUNITY_GOLD_MIN_MEDAL_LEVEL:
		return [_action_opportunity_gold_window()]
	return [ACTION_OPPORTUNITY_SILVER_WINDOW]


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
			ACTION_OPPORTUNITY_FORGIVENESS_IDEAL_SECONDS,
			ACTION_OPPORTUNITY_FORGIVENESS_MIN_SECONDS,
			window_seconds
		)
		var forgiveness := smoothstep(0.0, 1.0, clampf(cramped, 0.0, 1.0))
		if forgiveness <= 0.001:
			adjusted.append(window)
			continue
		var next_width := clampf(
			width * (1.0 + ACTION_OPPORTUNITY_FORGIVENESS_MAX_EXTRA_WIDTH * forgiveness),
			width,
			1.0
		)
		adjusted.append(_action_opportunity_resize_window(window, next_width))
	return adjusted


func _action_opportunity_apply_miss_expansion(windows: Array[Vector2]) -> Array[Vector2]:
	if windows.is_empty() or action_opportunity_miss_expand_per_side <= 0.0001:
		return windows.duplicate()
	var adjusted: Array[Vector2] = []
	for raw_window in windows:
		var window := raw_window as Vector2
		var width := clampf(window.y - window.x, 0.0, 1.0)
		if width <= 0.001:
			continue
		var next_width := clampf(width + action_opportunity_miss_expand_per_side * 2.0, width, 1.0)
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
	var width: float = ACTION_OPPORTUNITY_SILVER_WINDOW.y - ACTION_OPPORTUNITY_SILVER_WINDOW.x
	var start_left: float = 1.0 - width
	var stop_left: float = ACTION_OPPORTUNITY_SAPPHIRE_LEFT_STOP
	var slide_t := smoothstep(0.0, 1.0, clampf(action_opportunity_cycle_elapsed / ACTION_OPPORTUNITY_SAPPHIRE_SLIDE_SECONDS, 0.0, 1.0))
	var left := lerpf(start_left, stop_left, slide_t)
	return Vector2(left, left + width)


func _action_opportunity_emerald_window() -> Vector2:
	return action_opportunity_emerald_window


func _action_opportunity_ruby_window() -> Vector2:
	var left := clampf(action_opportunity_ruby_left, 0.0, 1.0 - ACTION_OPPORTUNITY_RUBY_WINDOW_WIDTH)
	return Vector2(left, left + ACTION_OPPORTUNITY_RUBY_WINDOW_WIDTH)


func _action_opportunity_emerald_target_window() -> Vector2:
	var left := clampf(
		ACTION_OPPORTUNITY_EMERALD_MAX_WINDOW.x + float(action_opportunity_emerald_shrink_steps) * ACTION_OPPORTUNITY_EMERALD_SHRINK_PER_SUCCESS,
		ACTION_OPPORTUNITY_EMERALD_MAX_WINDOW.x,
		ACTION_OPPORTUNITY_EMERALD_MIN_WINDOW.x
	)
	var right := clampf(
		ACTION_OPPORTUNITY_EMERALD_MAX_WINDOW.y - float(action_opportunity_emerald_shrink_steps) * ACTION_OPPORTUNITY_EMERALD_SHRINK_PER_SUCCESS,
		ACTION_OPPORTUNITY_EMERALD_MIN_WINDOW.y,
		ACTION_OPPORTUNITY_EMERALD_MAX_WINDOW.y
	)
	return Vector2(left, right)


func _process_action_opportunity_window_animation(delta: float) -> void:
	if action_opportunity_miss_expand_elapsed < ACTION_OPPORTUNITY_MISS_EXPAND_SECONDS:
		action_opportunity_miss_expand_elapsed = minf(
			ACTION_OPPORTUNITY_MISS_EXPAND_SECONDS,
			action_opportunity_miss_expand_elapsed + delta
		)
		var miss_t := clampf(action_opportunity_miss_expand_elapsed / ACTION_OPPORTUNITY_MISS_EXPAND_SECONDS, 0.0, 1.0)
		var miss_eased := 1.0 - pow(1.0 - miss_t, 3.0)
		action_opportunity_miss_expand_per_side = lerpf(action_opportunity_miss_expand_start, action_opportunity_miss_expand_target, miss_eased)
		if miss_t >= 1.0:
			action_opportunity_miss_expand_per_side = action_opportunity_miss_expand_target
	if action_opportunity_emerald_transition_elapsed < ACTION_OPPORTUNITY_EMERALD_SHRINK_SECONDS:
		action_opportunity_emerald_transition_elapsed = minf(
			ACTION_OPPORTUNITY_EMERALD_SHRINK_SECONDS,
			action_opportunity_emerald_transition_elapsed + delta
		)
		var t := clampf(action_opportunity_emerald_transition_elapsed / ACTION_OPPORTUNITY_EMERALD_SHRINK_SECONDS, 0.0, 1.0)
		var eased := 1.0 - pow(1.0 - t, 3.0)
		action_opportunity_emerald_window = action_opportunity_emerald_start_window.lerp(action_opportunity_emerald_target_window, eased)
		if t >= 1.0:
			action_opportunity_emerald_window = action_opportunity_emerald_target_window
	if action_opportunity_ruby_transition_elapsed < ACTION_OPPORTUNITY_RUBY_MOVE_SECONDS:
		action_opportunity_ruby_transition_elapsed = minf(
			ACTION_OPPORTUNITY_RUBY_MOVE_SECONDS,
			action_opportunity_ruby_transition_elapsed + delta
		)
		var ruby_t := clampf(action_opportunity_ruby_transition_elapsed / ACTION_OPPORTUNITY_RUBY_MOVE_SECONDS, 0.0, 1.0)
		var ruby_eased := 1.0 - pow(1.0 - ruby_t, 3.0)
		action_opportunity_ruby_left = lerpf(action_opportunity_ruby_start_left, action_opportunity_ruby_target_left, ruby_eased)
		if ruby_t >= 1.0:
			action_opportunity_ruby_left = action_opportunity_ruby_target_left


func _advance_emerald_action_opportunity_window() -> void:
	var max_steps := int(round((ACTION_OPPORTUNITY_EMERALD_MIN_WINDOW.x - ACTION_OPPORTUNITY_EMERALD_MAX_WINDOW.x) / ACTION_OPPORTUNITY_EMERALD_SHRINK_PER_SUCCESS))
	action_opportunity_emerald_shrink_steps = mini(action_opportunity_emerald_shrink_steps + 1, max_steps)
	action_opportunity_emerald_start_window = action_opportunity_emerald_window
	action_opportunity_emerald_target_window = _action_opportunity_emerald_target_window()
	action_opportunity_emerald_transition_elapsed = 0.0


func _advance_ruby_action_opportunity_window() -> void:
	var max_left: float = 1.0 - ACTION_OPPORTUNITY_RUBY_WINDOW_WIDTH
	var current_left := clampf(action_opportunity_ruby_target_left, 0.0, max_left)
	var direction := -1.0 if randf() < 0.5 else 1.0
	action_opportunity_ruby_start_left = clampf(action_opportunity_ruby_left, 0.0, max_left)
	action_opportunity_ruby_target_left = clampf(current_left + ACTION_OPPORTUNITY_RUBY_STEP * direction, 0.0, max_left)
	action_opportunity_ruby_transition_elapsed = 0.0


func _bump_action_opportunity_miss_expansion() -> void:
	action_opportunity_miss_expand_start = action_opportunity_miss_expand_per_side
	action_opportunity_miss_expand_target = clampf(action_opportunity_miss_expand_target + ACTION_OPPORTUNITY_MISS_EXPAND_PER_SIDE, 0.0, 0.5)
	action_opportunity_miss_expand_elapsed = 0.0


func _reset_action_opportunity_miss_expansion(smooth := true) -> void:
	action_opportunity_miss_expand_start = action_opportunity_miss_expand_per_side
	action_opportunity_miss_expand_target = 0.0
	action_opportunity_miss_expand_elapsed = 0.0 if smooth else ACTION_OPPORTUNITY_MISS_EXPAND_SECONDS
	if not smooth:
		action_opportunity_miss_expand_per_side = 0.0


func _reset_emerald_action_opportunity_window() -> void:
	action_opportunity_emerald_shrink_steps = 0
	action_opportunity_emerald_window = ACTION_OPPORTUNITY_EMERALD_MAX_WINDOW
	action_opportunity_emerald_start_window = ACTION_OPPORTUNITY_EMERALD_MAX_WINDOW
	action_opportunity_emerald_target_window = ACTION_OPPORTUNITY_EMERALD_MAX_WINDOW
	action_opportunity_emerald_transition_elapsed = ACTION_OPPORTUNITY_EMERALD_SHRINK_SECONDS


func _reset_ruby_action_opportunity_window() -> void:
	action_opportunity_ruby_left = ACTION_OPPORTUNITY_RUBY_START_LEFT
	action_opportunity_ruby_start_left = ACTION_OPPORTUNITY_RUBY_START_LEFT
	action_opportunity_ruby_target_left = ACTION_OPPORTUNITY_RUBY_START_LEFT
	action_opportunity_ruby_transition_elapsed = ACTION_OPPORTUNITY_RUBY_MOVE_SECONDS


func _action_opportunity_gold_window() -> Vector2:
	var silver_center: float = (ACTION_OPPORTUNITY_SILVER_WINDOW.x + ACTION_OPPORTUNITY_SILVER_WINDOW.y) * 0.5
	var offset := _action_opportunity_sway_offset(
		ACTION_OPPORTUNITY_GOLD_SWAY,
		ACTION_OPPORTUNITY_GOLD_MOVE_SECONDS,
		ACTION_OPPORTUNITY_GOLD_PAUSE_SECONDS
	)
	var half_width: float = ACTION_OPPORTUNITY_GOLD_WIDTH * 0.5
	var center := clampf(silver_center + offset, half_width, 1.0 - half_width)
	return Vector2(center - half_width, center + half_width)


func _action_opportunity_diamond_window() -> Vector2:
	var silver_center: float = (ACTION_OPPORTUNITY_SILVER_WINDOW.x + ACTION_OPPORTUNITY_SILVER_WINDOW.y) * 0.5
	var offset := _action_opportunity_sway_offset(
		ACTION_OPPORTUNITY_DIAMOND_SWAY,
		ACTION_OPPORTUNITY_DIAMOND_MOVE_SECONDS,
		ACTION_OPPORTUNITY_DIAMOND_PAUSE_SECONDS
	)
	var half_width: float = ACTION_OPPORTUNITY_DIAMOND_WIDTH * 0.5
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
	if action_opportunity_missed:
		return false
	if action_opportunity_consumed and not _action_opportunity_uses_triple_click(skill_id, action_id):
		return false
	var checked_progress: float = host.action_progress if progress < 0.0 else progress
	for window in _action_opportunity_windows(skill_id, action_id):
		if checked_progress >= window.x and checked_progress <= window.y:
			return true
	return false


func _action_opportunity_uses_triple_click(skill_id: String, action_id: String) -> bool:
	var medal_level: int = int(MasteryState.level(host.mastery, host._action_key(skill_id, action_id)))
	return (
		medal_level >= ACTION_OPPORTUNITY_PLATINUM_MIN_MEDAL_LEVEL
		and medal_level < ACTION_OPPORTUNITY_SAPPHIRE_MIN_MEDAL_LEVEL
	)


func _action_opportunity_uses_looping_window(skill_id: String, action_id: String) -> bool:
	var medal_level: int = int(MasteryState.level(host.mastery, host._action_key(skill_id, action_id)))
	return (
		medal_level >= ACTION_OPPORTUNITY_GOLD_MIN_MEDAL_LEVEL
		and medal_level < ACTION_OPPORTUNITY_PLATINUM_MIN_MEDAL_LEVEL
	) or medal_level >= ACTION_OPPORTUNITY_DIAMOND_MIN_MEDAL_LEVEL


func _action_opportunity_uses_persistent_window(skill_id: String, action_id: String) -> bool:
	var medal_level: int = int(MasteryState.level(host.mastery, host._action_key(skill_id, action_id)))
	return (
		medal_level >= ACTION_OPPORTUNITY_SAPPHIRE_MIN_MEDAL_LEVEL
		and medal_level < ACTION_OPPORTUNITY_EMERALD_MIN_MEDAL_LEVEL
	)


func _action_opportunity_uses_shrinking_window(skill_id: String, action_id: String) -> bool:
	var medal_level: int = int(MasteryState.level(host.mastery, host._action_key(skill_id, action_id)))
	return (
		medal_level >= ACTION_OPPORTUNITY_EMERALD_MIN_MEDAL_LEVEL
		and medal_level < ACTION_OPPORTUNITY_RUBY_MIN_MEDAL_LEVEL
	)


func _action_opportunity_uses_step_window(skill_id: String, action_id: String) -> bool:
	var medal_level: int = int(MasteryState.level(host.mastery, host._action_key(skill_id, action_id)))
	return (
		medal_level >= ACTION_OPPORTUNITY_RUBY_MIN_MEDAL_LEVEL
		and medal_level < ACTION_OPPORTUNITY_DIAMOND_MIN_MEDAL_LEVEL
	)


func _action_opportunity_persistent_window_reached_wait_point(skill_id: String, action_id: String) -> bool:
	if not _action_opportunity_uses_persistent_window(skill_id, action_id):
		return false
	return action_opportunity_cycle_elapsed >= ACTION_OPPORTUNITY_SAPPHIRE_SLIDE_SECONDS


func _try_action_opportunity_click(skill_id: String, action_id: String, _press_position: Vector2) -> bool:
	if host.running_skill_id != skill_id or host.running_action_id != action_id:
		return false
	if action_opportunity_missed:
		return false
	if action_opportunity_consumed and not _action_opportunity_uses_triple_click(skill_id, action_id):
		return _action_opportunity_progress_hit_test(skill_id, action_id)
	if not _action_opportunity_progress_hit_test(skill_id, action_id):
		return false
	var feedback_windows := _action_opportunity_pattern_windows(skill_id, action_id)
	var opportunity_key: String = host._action_key(skill_id, action_id)
	var now := Time.get_ticks_msec()
	if (
		last_action_opportunity_tap_key == opportunity_key
		and now - last_action_opportunity_tap_msec < ACTION_OPPORTUNITY_DUPLICATE_TAP_MSEC
	):
		return true
	last_action_opportunity_tap_key = opportunity_key
	last_action_opportunity_tap_msec = now
	if _action_opportunity_uses_triple_click(skill_id, action_id):
		var triple_success := _try_triple_click_action_opportunity_click(skill_id, action_id)
		if triple_success:
			host._onboarding_runtime()._complete_silver_opportunity_tip_for_action(skill_id, action_id)
		return triple_success
	action_opportunity_persistent_windows.clear()
	action_opportunity_persistent_key = ""
	if _action_opportunity_uses_shrinking_window(skill_id, action_id):
		_advance_emerald_action_opportunity_window()
	if _action_opportunity_uses_step_window(skill_id, action_id):
		_advance_ruby_action_opportunity_window()
	_reset_action_opportunity_miss_expansion(false)
	host._reward_feedback_surface()._play_action_opportunity_window_feedback(skill_id, action_id, true, feedback_windows)
	action_opportunity_consumed = true
	action_opportunity_boost_seconds = ACTION_OPPORTUNITY_BOOST_SECONDS
	action_opportunity_boost_duration = ACTION_OPPORTUNITY_BOOST_SECONDS
	_start_action_opportunity_regen(skill_id)
	host.action_progress = clampf(host.action_progress + ACTION_OPPORTUNITY_DIRECT_PROGRESS, 0.0, 0.999)
	host._reward_feedback_surface()._float_action_opportunity_feedback(skill_id, action_id)
	host._reward_feedback_surface()._set_result("Opportunity hit: %s sped up. Stamina regen surged." % str(host._action_data(skill_id, action_id).get("name", "Activity")))
	host._onboarding_runtime()._complete_silver_opportunity_tip_for_action(skill_id, action_id)
	return true


func _try_triple_click_action_opportunity_click(skill_id: String, action_id: String) -> bool:
	var feedback_windows := _action_opportunity_pattern_windows(skill_id, action_id)
	_reset_action_opportunity_miss_expansion(false)
	host._reward_feedback_surface()._play_action_opportunity_window_feedback(skill_id, action_id, true, feedback_windows)
	if action_opportunity_triple_click_stacks < ACTION_OPPORTUNITY_TRIPLE_CLICK_MAX_STACKS:
		action_opportunity_triple_click_stacks += 1
	var text := "nice!"
	if action_opportunity_triple_click_stacks == 2:
		text = "awesome!"
	elif action_opportunity_triple_click_stacks >= ACTION_OPPORTUNITY_TRIPLE_CLICK_MAX_STACKS:
		text = "max!"
	host._reward_feedback_surface()._float_action_opportunity_feedback(skill_id, action_id, text)
	host._reward_feedback_surface()._set_result("Opportunity hit: %s speed stack %s/%s." % [
		str(host._action_data(skill_id, action_id).get("name", "Activity")),
		action_opportunity_triple_click_stacks,
		ACTION_OPPORTUNITY_TRIPLE_CLICK_MAX_STACKS
	])
	return true


func _miss_action_opportunity_click(skill_id: String, action_id: String, _press_position: Vector2) -> bool:
	if host.running_skill_id != skill_id or host.running_action_id != action_id:
		return false
	if action_opportunity_consumed or action_opportunity_missed:
		return false
	var feedback_windows := _action_opportunity_pattern_windows(skill_id, action_id)
	if feedback_windows.is_empty():
		return false
	if not host._reward_feedback_surface()._action_opportunity_window_is_visible(skill_id, action_id):
		return false
	if _action_opportunity_progress_hit_test(skill_id, action_id):
		return false
	action_opportunity_persistent_windows.clear()
	action_opportunity_persistent_key = ""
	_bump_action_opportunity_miss_expansion()
	host._reward_feedback_surface()._play_action_opportunity_window_feedback(skill_id, action_id, false, feedback_windows)
	if _action_opportunity_uses_shrinking_window(skill_id, action_id):
		_reset_emerald_action_opportunity_window()
	action_opportunity_missed = true
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
	action_opportunity_regen_skill_id = skill_id
	action_opportunity_regen_seconds = ACTION_OPPORTUNITY_REGEN_SECONDS


func _process_action_opportunity_regen(delta: float) -> void:
	if action_opportunity_regen_seconds <= 0.0:
		action_opportunity_regen_seconds = 0.0
		action_opportunity_regen_skill_id = ""
		return
	if action_opportunity_regen_skill_id.is_empty() or host.running_skill_id != action_opportunity_regen_skill_id:
		action_opportunity_regen_seconds = 0.0
		action_opportunity_regen_skill_id = ""
		return
	action_opportunity_regen_seconds = maxf(0.0, action_opportunity_regen_seconds - delta)
	if action_opportunity_regen_seconds <= 0.0:
		action_opportunity_regen_skill_id = ""


func _process_action_opportunity_boost(delta: float) -> void:
	if action_opportunity_boost_seconds <= 0.0:
		action_opportunity_boost_seconds = 0.0
		action_opportunity_boost_duration = 0.0
		return
	action_opportunity_boost_seconds = maxf(0.0, action_opportunity_boost_seconds - delta)
	if action_opportunity_boost_seconds <= 0.0:
		action_opportunity_boost_duration = 0.0


func _action_opportunity_speed_bonus() -> float:
	var bonus: float = float(action_opportunity_triple_click_stacks) * ACTION_OPPORTUNITY_TRIPLE_CLICK_SPEED_PER_STACK
	if action_opportunity_boost_seconds > 0.0 and action_opportunity_boost_duration > 0.0:
		var t := clampf(action_opportunity_boost_seconds / action_opportunity_boost_duration, 0.0, 1.0)
		bonus += ACTION_OPPORTUNITY_BOOST_MULT * t * t
	return bonus


func _complete_action_opportunity_cycle_without_click() -> bool:
	if action_opportunity_missed or action_opportunity_consumed:
		_reset_action_opportunity_state(false)
		return true
	if not host.running_skill_id.is_empty() and not host.running_action_id.is_empty():
		if _action_opportunity_uses_triple_click(host.running_skill_id, host.running_action_id):
			_reset_action_opportunity_state(false)
			return true
		if _action_opportunity_uses_persistent_window(host.running_skill_id, host.running_action_id):
			if _action_opportunity_persistent_window_reached_wait_point(host.running_skill_id, host.running_action_id):
				var width: float = ACTION_OPPORTUNITY_SILVER_WINDOW.y - ACTION_OPPORTUNITY_SILVER_WINDOW.x
				action_opportunity_persistent_windows = [Vector2(ACTION_OPPORTUNITY_SAPPHIRE_LEFT_STOP, ACTION_OPPORTUNITY_SAPPHIRE_LEFT_STOP + width)]
				action_opportunity_persistent_key = host._action_key(host.running_skill_id, host.running_action_id)
				last_action_opportunity_tap_key = ""
				last_action_opportunity_tap_msec = 0
				return true
			action_opportunity_persistent_windows.clear()
			action_opportunity_persistent_key = ""
			last_action_opportunity_tap_key = ""
			last_action_opportunity_tap_msec = 0
			return false
		elif _action_opportunity_uses_looping_window(host.running_skill_id, host.running_action_id):
			action_opportunity_persistent_windows.clear()
			action_opportunity_persistent_key = ""
		elif action_opportunity_persistent_windows.is_empty():
			var windows := _action_opportunity_raw_pattern_windows(host.running_skill_id, host.running_action_id)
			if not windows.is_empty():
				action_opportunity_persistent_windows = windows.duplicate()
				action_opportunity_persistent_key = host._action_key(host.running_skill_id, host.running_action_id)
	last_action_opportunity_tap_key = ""
	last_action_opportunity_tap_msec = 0
	return true


func _activity_crit_chance(streak_bonus: bool) -> float:
	var base_chance: float = ACTIVITY_STREAK_CRIT_CHANCE if streak_bonus else ACTIVITY_NORMAL_CRIT_CHANCE
	var bonus_mult := AchievementState.reward_bonus(AchievementState.milestones(host), "crit_chance_mult")
	return clampf(base_chance * (1.0 + bonus_mult), 0.0, 1.0)


func invalidate_stat_cache() -> void:
	stat_cache_version += 1
	action_stat_value_cache.clear()


func _effective_stamina(skill_id: String, action: Dictionary) -> float:
	if host._convergence_runtime()._is_convergence_action(action):
		return 0.0
	if _is_fishing_event_action(skill_id, action):
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
	var tier_reduction: float = AchievementState.activity_tier_stamina_cost_reduction(host, skill_id, action)
	var mission_reduction: float = host._hub_runtime().mission_stamina_reduction() if host._hub_runtime().mission_bonus_applies(skill_id, action) else 0.0
	var value := maxf(0.01, float(base_stamina) * (1.0 - clampf(medal_reduction + tier_reduction + mission_reduction, 0.0, 0.92)))
	if AchievementState.action_tier(host, action) >= 2:
		value = maxf(value, maxf(0.7, float(base_stamina) * 0.12))
	action_stat_value_cache[cache_key] = value
	return value


func _active_action_stamina_cost() -> float:
	if host.running_skill_id.is_empty() or host.running_action_id.is_empty():
		return 0.0
	var action: Dictionary = host._action_data(host.running_skill_id, host.running_action_id)
	return 0.0 if action.is_empty() else _effective_stamina(host.running_skill_id, action)


func _is_fishing_event_action(skill_id: String, action: Dictionary) -> bool:
	return skill_id == "fishing" and host._is_event_action(action)


func _effective_seconds(skill_id: String, action: Dictionary) -> float:
	var base_seconds := maxf(0.1, float(action.get("seconds", 1.0)))
	var speed_bonus: float = clampf(AchievementState.global_reward_bonus(host, "speed_mult", skill_id) + host._ad_bonus_runtime().speed_multiplier(), 0.0, 0.75)
	var medal_time_reduction: float = AchievementState.activity_medal_time_reduction(host, skill_id, action)
	var tier_time_reduction: float = AchievementState.activity_tier_time_reduction(host, skill_id, action)
	var mission_time_reduction: float = host._hub_runtime().mission_time_reduction() if host._hub_runtime().mission_bonus_applies(skill_id, action) else 0.0
	var total_reduction := clampf(speed_bonus + medal_time_reduction + tier_time_reduction + mission_time_reduction, 0.0, 0.82)
	return maxf(0.1, base_seconds * (1.0 - total_reduction))


func _apply_medal_time_reduction_to_seconds(skill_id: String, action: Dictionary, seconds: float) -> float:
	return maxf(0.1, maxf(0.1, seconds) * (1.0 - clampf(AchievementState.activity_medal_time_reduction(host, skill_id, action) + AchievementState.activity_tier_time_reduction(host, skill_id, action), 0.0, 0.82)))


func _fishing_net_soak_active(skill_id: String) -> bool:
	return host._fishing_rework_active_for_skill(skill_id) and host.fishing_runtime.equipped_tool_id == "net"


func _fishing_boat_soak_active(skill_id: String) -> bool:
	return host._fishing_rework_active_for_skill(skill_id) and host.fishing_runtime.equipped_tool_id == "boat"


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
		host._ad_bonus_runtime().seconds_remaining > 0.0,
		host.fishing_runtime.equipped_tool_id,
		host.plank_boost_enabled,
		host.material_runtime.amount("softwood") >= 1.0,
		hash(host._hub_runtime().hub_modules),
		hash(host._hub_runtime().hub_missions),
		hash(host.fishing_runtime.selected_locations)
	]


func _success_chance(skill_id: String, action: Dictionary) -> float:
	if host._convergence_runtime()._is_convergence_action(action):
		return 100.0
	var cache_key := _action_stat_value_cache_key("success", skill_id, action)
	if action_stat_value_cache.has(cache_key):
		return float(action_stat_value_cache[cache_key])
	var value := 100.0
	if host._fishing_rework_active_for_skill(skill_id) and not host._is_event_action(action):
		value = clampf(host.fishing_runtime.attempt_success_chance(host, str(action.get("id", ""))) + AchievementState.activity_medal_accuracy_bonus(host, skill_id, action) + AchievementState.activity_tier_accuracy_bonus(host, skill_id, action), 5.0, 100.0)
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
	if skill_id.is_empty() or action.is_empty() or host._passive_modules_runtime().is_passive_action(action) or host._convergence_runtime()._is_convergence_action(action):
		return false
	if guaranteed_success_action_completions >= GUARANTEED_SUCCESS_ACTION_COMPLETIONS:
		return false
	guaranteed_success_action_completions += 1
	host._mark_save_dirty("starter guaranteed success")
	return true


func _reset_action_opportunity_state(clear_boost := true) -> void:
	action_opportunity_consumed = false
	action_opportunity_missed = false
	action_opportunity_cycle_elapsed = 0.0
	action_opportunity_triple_click_stacks = 0
	action_opportunity_persistent_windows.clear()
	action_opportunity_persistent_key = ""
	last_action_opportunity_tap_key = ""
	last_action_opportunity_tap_msec = 0
	if clear_boost:
		_reset_action_opportunity_miss_expansion(false)
		_reset_emerald_action_opportunity_window()
		_reset_ruby_action_opportunity_window()
		action_opportunity_boost_seconds = 0.0
		action_opportunity_boost_duration = 0.0
		action_opportunity_regen_skill_id = ""
		action_opportunity_regen_seconds = 0.0
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


func _auto_eat_fish_for_action(skill_id: String, stamina_cost: float, source: RegenCircle = null, show_fail := false) -> bool:
	_clear_auto_eat_fish_after_spend_delay(skill_id)
	if stamina_cost <= 0.0:
		return true
	if not host.fishing_runtime.auto_eat_fish_enabled_for_skill(host, skill_id) or skill_id.is_empty() or host._fishing_rework_active_for_skill(skill_id):
		return SkillState.host_stamina_value(skill_id, host) + 0.0001 >= stamina_cost
	if SkillState.host_stamina_value(skill_id, host) + 0.0001 >= stamina_cost:
		return true
	var maximum := float(SkillState.max_stamina(host, skill_id))
	if maximum <= 0.0 or stamina_cost > maximum + 0.0001:
		return false
	var current_stamina: float = SkillState.host_stamina_value(skill_id, host)
	var stamina_room := maxi(0, int(ceil(maximum - current_stamina - 0.0001)))
	var needed_fish := maxi(0, int(ceil(stamina_cost - current_stamina - 0.0001)))
	var available_fish := maxi(0, int(floor(host.fishing_runtime.fish_currency)))
	var fish_to_eat := mini(needed_fish, mini(stamina_room, available_fish))
	if fish_to_eat <= 0:
		if show_fail:
			host._reward_feedback_surface()._float_stamina_need_fish(source)
			host._reward_feedback_surface()._play_stamina_gauge_eat_fail(source)
		return SkillState.host_stamina_value(skill_id, host) + 0.0001 >= stamina_cost
	host.fishing_runtime.fish_currency = maxf(0.0, host.fishing_runtime.fish_currency - float(fish_to_eat))
	host.stamina[skill_id] = minf(maximum, current_stamina + float(fish_to_eat))
	SkillState.host_sync_stamina_bank(skill_id, host)
	var target: RegenCircle = host._reward_feedback_surface()._visible_stamina_gauge_for_skill(skill_id, source)
	host._reward_feedback_surface()._pop_stamina_gauge(target)
	host._play_staggered_eaten_fish_icons(skill_id, target.get_instance_id() if target != null and is_instance_valid(target) else 0, fish_to_eat)
	host._update_ui(0.0, true)
	return SkillState.host_stamina_value(skill_id, host) + 0.0001 >= stamina_cost


func _schedule_auto_eat_fish_after_spend_delay(skill_id: String, stamina_cost: float) -> void:
	if skill_id.is_empty() or stamina_cost <= 0.0 or host._fishing_rework_active_for_skill(skill_id):
		return
	if not host.fishing_runtime.auto_eat_fish_enabled_for_skill(host, skill_id):
		return
	if SkillState.host_stamina_value(skill_id, host) + 0.0001 >= stamina_cost:
		_clear_auto_eat_fish_after_spend_delay(skill_id)
		return
	if not _auto_eat_fish_can_cover_action(skill_id, stamina_cost):
		_clear_auto_eat_fish_after_spend_delay(skill_id)
		return
	auto_eat_fish_after_spend_due_msec_by_skill[skill_id] = Time.get_ticks_msec() + AUTO_EAT_FISH_AFTER_SPEND_VISUAL_DELAY_MSEC


func _clear_auto_eat_fish_after_spend_delay(skill_id: String) -> void:
	if skill_id.is_empty():
		return
	auto_eat_fish_after_spend_due_msec_by_skill.erase(skill_id)


func _auto_eat_fish_after_spend_delay_active(skill_id: String) -> bool:
	return not skill_id.is_empty() and auto_eat_fish_after_spend_due_msec_by_skill.has(skill_id)


func _auto_eat_fish_after_spend_delay_due(skill_id: String) -> bool:
	if not _auto_eat_fish_after_spend_delay_active(skill_id):
		return false
	return Time.get_ticks_msec() >= int(auto_eat_fish_after_spend_due_msec_by_skill.get(skill_id, 0))


func _auto_eat_fish_can_cover_action(skill_id: String, stamina_cost: float) -> bool:
	if not host.fishing_runtime.auto_eat_fish_enabled_for_skill(host, skill_id) or skill_id.is_empty() or host._fishing_rework_active_for_skill(skill_id):
		return false
	if stamina_cost <= 0.0 or SkillState.host_stamina_value(skill_id, host) + 0.0001 >= stamina_cost:
		return true
	var maximum := float(SkillState.max_stamina(host, skill_id))
	if maximum <= 0.0 or stamina_cost > maximum + 0.0001:
		return false
	var current_stamina: float = SkillState.host_stamina_value(skill_id, host)
	var stamina_room := maxi(0, int(ceil(maximum - current_stamina - 0.0001)))
	var needed_fish := maxi(0, int(ceil(stamina_cost - current_stamina - 0.0001)))
	var available_fish := maxi(0, int(floor(host.fishing_runtime.fish_currency)))
	return mini(needed_fish, mini(stamina_room, available_fish)) >= needed_fish


func _low_stamina_training_text(action: Dictionary) -> String:
	return "%s is training tired at 20%% speed." % str(action.get("name", "Activity"))


func _stop_running_action(skill_id: String, action_id: String) -> bool:
	if host.running_skill_id != skill_id or host.running_action_id != action_id:
		return false
	var action: Dictionary = host._action_data(skill_id, action_id)
	if action.is_empty():
		return false
	var stop_action_key: String = host._action_key(skill_id, action_id)
	_remember_canceled_action_progress(skill_id, action_id, host.action_progress)
	_clear_auto_eat_fish_after_spend_delay(skill_id)
	host.running_skill_id = ""
	host.running_action_id = ""
	host.action_progress = 0.0
	host.tired_activity_zero_float_action_key = ""
	host.fishing_runtime.net_set_in_water = false
	host.fishing_runtime.boat_set_in_water = false
	host.fishing_runtime.rod_set_in_water = false
	host.fishing_runtime.rod_haul_visual_seconds = 0.0
	_reset_action_opportunity_state()
	host._audio_director()._nudge_music_flow_down(0.4)
	host._reward_feedback_surface()._set_result("%s stopped." % action["name"])
	host._audio_director()._play_click_sfx()
	host._skill_swipe_activity_surface()._pop_activity_button(stop_action_key)
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
		_clear_auto_eat_fish_after_spend_delay(host.running_skill_id)
		host.running_skill_id = ""
		host.running_action_id = ""
		host.action_progress = 0.0
		host.tired_activity_zero_float_action_key = ""
		host.fishing_runtime.net_set_in_water = false
		host.fishing_runtime.boat_set_in_water = false
		host.fishing_runtime.rod_set_in_water = false
		host.fishing_runtime.rod_haul_visual_seconds = 0.0
		_reset_action_opportunity_state()
		return
	var active_key = host._action_key(host.running_skill_id, host.running_action_id)
	if host._fighting_runtime().action_is_free_fighting_proto(host.running_skill_id, host.running_action_id):
		host.action_progress = 0.0
		action_opportunity_cycle_elapsed = 0.0
		host.tired_activity_zero_float_action_key = ""
		return
	if host._fighting_runtime().is_boss_fight_action(action):
		host.action_progress = 0.0
		action_opportunity_cycle_elapsed = 0.0
		host.tired_activity_zero_float_action_key = ""
		return
	var fishing_rework_attempt = host._fishing_rework_active_for_skill(host.running_skill_id) and not host._is_event_action(action)
	var cost = _effective_stamina(host.running_skill_id, action)
	if not fishing_rework_attempt and not host._activity_queue_runtime().activity_queue_running:
		if _auto_eat_fish_after_spend_delay_due(host.running_skill_id):
			_auto_eat_fish_for_action(host.running_skill_id, cost, host._skill_detail_surface().detail_regen_circle, false)
		elif not _auto_eat_fish_after_spend_delay_active(host.running_skill_id):
			_auto_eat_fish_for_action(host.running_skill_id, cost, host._skill_detail_surface().detail_regen_circle, false)
	var has_stamina_for_action = true if fishing_rework_attempt else SkillState.host_stamina_value(host.running_skill_id, host) + 0.0001 >= cost
	if (
		not has_stamina_for_action
		and _auto_eat_fish_after_spend_delay_active(host.running_skill_id)
		and _auto_eat_fish_can_cover_action(host.running_skill_id, cost)
	):
		has_stamina_for_action = true
	if host._is_event_action(action) and not has_stamina_for_action:
		host._reward_feedback_surface()._set_result(host._temporary_event_runtime()._event_needs_stamina_text(host.running_skill_id, action))
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
	action_opportunity_cycle_elapsed += delta
	if not fishing_rework_attempt and not has_stamina_for_action:
		var low_stamina_message = _low_stamina_training_text(action)
		if host.last_result != low_stamina_message:
			host.last_result = low_stamina_message
			host._audio_director()._nudge_music_flow_down(0.4)
		if SkillState.host_stamina_int(host.running_skill_id, host) <= 0 and host.tired_activity_zero_float_action_key != active_key:
			host.tired_activity_zero_float_action_key = active_key
			host._reward_feedback_surface()._float_tired_activity_feedback(active_key)
	else:
		host.tired_activity_zero_float_action_key = ""
	host.action_progress += delta / _action_cycle_seconds(host.running_skill_id, action) * speed_mult
	if host.action_progress < 1.0:
		return
	var bonus_snapshot_before = host._reward_feedback_surface()._capture_visible_bonus_snapshot_if_needed(host.running_skill_id, host.running_action_id, action)
	host.action_progress = 0.0
	if _complete_action_opportunity_cycle_without_click():
		action_opportunity_cycle_elapsed = 0.0
	if host._convergence_runtime()._is_convergence_action(action):
		host._convergence_runtime()._complete_convergence_cycle(host.running_action_id)
		host._onboarding_runtime()._record_activity_completion_for_tips(host.running_skill_id, host.running_action_id)
		host._update_ui(0.0, false)
		return
	if fishing_rework_attempt:
		host.fishing_runtime.complete_action_attempt(host, action, active_key, bonus_snapshot_before)
		return
	if not host._activity_queue_runtime().activity_queue_running and SkillState.host_stamina_value(host.running_skill_id, host) + 0.0001 < cost:
		_auto_eat_fish_for_action(host.running_skill_id, cost, host._skill_detail_surface().detail_regen_circle, false)
	if SkillState.spend_action_stamina(host.stamina, host.stamina_bank, host.running_skill_id, cost, Callable(SkillState, "host_max_stamina").bind(host)):
		if not host._activity_queue_runtime().activity_queue_running:
			_schedule_auto_eat_fish_after_spend_delay(host.running_skill_id, cost)
		if host.running_skill_id == host.TUTORIAL_STARTER_SKILL_ID:
			host._onboarding_runtime()._maybe_trigger_onboarding_swipe_tip_at_zero_stamina(host.TUTORIAL_STARTER_SKILL_ID)
	if host._is_event_action(action):
		host._temporary_event_runtime()._complete_temporary_event_action_attempt(host.running_skill_id, host.running_action_id, action, active_key, cost, bonus_snapshot_before)
		return
	var reward_key = active_key
	var old_mastery_level = MasteryState.level(host.mastery, host._action_key(host.running_skill_id, host.running_action_id))
	var mastery_reward = MasteryState.reward_for_action(host, host.running_skill_id, host.running_action_id, action)
	var tiers_unlocked_before = {}
	for tier in range(1, host.MASTERY_MAX_LEVEL + 1):
		tiers_unlocked_before[tier] = AchievementState.global_medal_tier_unlocked(host, tier)
	var completed_achievements_before = AchievementState.completed_ids(AchievementState.milestones(host, false))
	var old_skill_level = SkillState.host_skill_level(host, host.running_skill_id)
	var locked_preview_available_before = host._activity_unlock_runtime()._locked_activity_preview_available()
	var success = _roll_action_success(host.running_skill_id, action)
	var completed_skill_id = host.running_skill_id
	var completed_action_id = host.running_action_id
	host._fishing_ui_surface()._play_fishing_attempt_reveal(host.running_skill_id, host.running_action_id, success)
	if success:
		var streak_step = record_successful_activity_completion(reward_key)
		var streak_bonus = streak_step == ACTIVITY_STREAK_BONUS_STEP
		var crits_allowed = host._onboarding_runtime()._activity_crits_allowed()
		var crit_chance = _activity_crit_chance(streak_bonus) if crits_allowed else 0.0
		var xp_crit = crits_allowed and randf() < crit_chance
		if xp_crit:
			consecutive_activity_crit_count += 1
		else:
			reset_consecutive_activity_crits()
		var mega_crit = crits_allowed and consecutive_activity_crit_count >= 2
		if xp_crit:
			host.activity_crit_seen = true
		if mega_crit:
			host.activity_mega_crit_seen = true
		var plank_bonus_used = host._passive_modules_runtime().plank_bonus_applies(host.running_skill_id)
		var xp_reward_map = _completion_xp_reward_map(action, host.running_skill_id, plank_bonus_used, xp_crit, mega_crit, streak_bonus)
		var berry_prep_result = host.material_runtime.consume_berry_prep_bonus(host.running_skill_id, host.running_action_id, xp_reward_map, Callable(host, "_action_data"), Callable(host, "_action_key"))
		host._material_collection_surface().play_berry_prep_badge_feedback(host.running_skill_id, host.running_action_id, not berry_prep_result.is_empty(), host.material_runtime.berry_prep_matches(host.running_skill_id, host.running_action_id, Callable(host, "_action_data"), Callable(host, "_action_key")) and host.material_runtime.amount("berries") < 1.0)
		var old_reward_skill_levels = _skill_levels_for_reward_map(host.running_skill_id, xp_reward_map)
		var affected_reward_skill_ids = _apply_xp_reward_map(host.running_skill_id, xp_reward_map)
		var xp_reward = _reward_map_total(xp_reward_map)
		if mastery_reward > 0.0:
			MasteryState.add_host_xp(host, host.running_skill_id, host.running_action_id, mastery_reward)
		var new_mastery_level = MasteryState.level(host.mastery, host._action_key(host.running_skill_id, host.running_action_id))
		host._onboarding_runtime()._register_silver_opportunity_tip_anchor(host.running_skill_id, host.running_action_id, old_mastery_level, new_mastery_level)
		for raw_reward_skill_id in affected_reward_skill_ids:
			SkillState.recalculate_level(host, str(raw_reward_skill_id))
		host._activity_unlock_ceremony_surface().queue_locked_preview_reveal_if_needed(locked_preview_available_before)
		var new_skill_level = SkillState.host_skill_level(host, host.running_skill_id)
		var any_reward_skill_level_up = _any_reward_skill_leveled_up(affected_reward_skill_ids, old_reward_skill_levels)
		host._passive_modules_runtime().sync_passive_module_unlocks(host._unix_now())
		if plank_bonus_used:
			host.material_runtime.spend_amount("softwood", 1.0)
		var recovery_result = RecoveryModules.apply(host.running_skill_id, action, host.skill_defs, host.stamina, Callable(SkillState, "host_stamina_value").bind(host), Callable(SkillState, "host_max_stamina").bind(host), func(skill_id: String, amount: float) -> float: return SkillState.restore_action_stamina(host.stamina, host.stamina_bank, skill_id, amount, Callable(SkillState, "host_max_stamina").bind(host)))
		var recovery_skill_name := func(skill_id: String) -> String:
			return SkillState.skill_name(host.skill_defs, skill_id)
		var recovery_text = RecoveryModules.result_text(recovery_result, recovery_skill_name, Callable(GameFormatting, "stamina_cost_detail"))
		var berry_prep_text = host.material_runtime.berry_prep_result_text(berry_prep_result)
		var awarded_mats = _award_action_mat_rewards(action, 2.0 if not berry_prep_result.is_empty() else 1.0)
		var mat_result_text = _mat_reward_result_text(awarded_mats)
		var boss_clear_text = host._fighting_runtime().complete_boss_if_needed(action)
		if not boss_clear_text.is_empty():
			host._activity_unlock_runtime()._queue_activity_unlock_readiness(host.running_skill_id, 0, SkillState.host_skill_level(host, host.running_skill_id), host._activity_unlock_runtime()._ready_lockpads_for_current_state())
		host.last_result = _xp_reward_result_sentence(xp_reward_map, host.running_skill_id, str(action["name"]))
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
		host._audio_director()._play_activity_success_sound(streak_step, new_mastery_level > old_mastery_level, streak_bonus, xp_crit, mega_crit, consecutive_activity_crit_count)
		host._audio_director()._record_music_flow_action(true, streak_step, streak_bonus, new_mastery_level > old_mastery_level, any_reward_skill_level_up or new_skill_level > old_skill_level, cost)
		host._tutorial_overlay_surface().maybe_show_onboarding_medal_tip(old_mastery_level, new_mastery_level, host.running_skill_id, host.running_action_id)
		host._onboarding_runtime()._tutorial_on_action_succeeded(completed_skill_id, completed_action_id)
	else:
		reset_consecutive_activity_crits()
		reset_activity_completion_streak()
		var failure_mastery_reward = 0.0 if MasteryState.would_reward_level_up(host.mastery, host._action_key(host.running_skill_id, host.running_action_id), mastery_reward, host.MASTERY_MAX_LEVEL) else mastery_reward
		if failure_mastery_reward > 0:
			MasteryState.add_host_xp(host, host.running_skill_id, host.running_action_id, failure_mastery_reward)
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
		host._tutorial_overlay_surface().maybe_show_onboarding_medal_tip(old_mastery_level, failure_mastery_level, host.running_skill_id, host.running_action_id)
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
	host._reward_feedback_surface()._emphasize_visible_bonus_changes_deferred(bonus_snapshot_before)


func _process_temporary_event_action(delta: float) -> void:
	var temporary_events = host._temporary_event_runtime()
	if temporary_events.event_running_skill_id.is_empty() or temporary_events.event_running_action_id.is_empty():
		return
	var action = host._action_data(temporary_events.event_running_skill_id, temporary_events.event_running_action_id)
	if action.is_empty() or not host._activity_unlock_runtime()._is_action_unlocked(temporary_events.event_running_skill_id, action):
		temporary_events._stop_temporary_event_action_with_feedback(
			temporary_events.event_running_skill_id,
			temporary_events.event_running_action_id,
			"Event stopped: it ended.",
			"Stopped\nEvent ended",
			Color("#ff9f7a")
		)
		return
	var event_key = host._action_key(temporary_events.event_running_skill_id, temporary_events.event_running_action_id)
	var cost = _effective_stamina(temporary_events.event_running_skill_id, action)
	var has_stamina_for_action = SkillState.host_stamina_value(temporary_events.event_running_skill_id, host) + 0.0001 >= cost
	if not has_stamina_for_action:
		var cost_text = GameFormatting.stamina_cost_detail(cost)
		temporary_events._stop_temporary_event_action_with_feedback(
			temporary_events.event_running_skill_id,
			temporary_events.event_running_action_id,
			"Event stopped: %s" % temporary_events._event_needs_stamina_text(temporary_events.event_running_skill_id, action),
			"Stopped\nNeed %s STAM" % cost_text,
			Color("#ffd95a")
		)
		return
	var speed_mult = _action_progress_speed_multiplier(temporary_events.event_running_skill_id, action, has_stamina_for_action)
	temporary_events.event_action_progress += delta / _action_cycle_seconds(temporary_events.event_running_skill_id, action) * speed_mult
	if temporary_events.event_action_progress < 1.0:
		return
	var completed_skill_id = temporary_events.event_running_skill_id
	var completed_action_id = temporary_events.event_running_action_id
	var bonus_snapshot_before = host._reward_feedback_surface()._capture_visible_bonus_snapshot_if_needed(completed_skill_id, completed_action_id, action)
	temporary_events.event_action_progress = 0.0
	if SkillState.spend_action_stamina(host.stamina, host.stamina_bank, completed_skill_id, cost, Callable(SkillState, "host_max_stamina").bind(host)):
		_schedule_auto_eat_fish_after_spend_delay(completed_skill_id, cost)
	temporary_events._complete_temporary_event_action_attempt(completed_skill_id, completed_action_id, action, event_key, cost, bonus_snapshot_before)


func _start_action(skill_id: String, action_id: String, select_page = true, respect_input_guards = true, from_activity_queue = false) -> bool:
	host._settings_surface()._disarm_reset_data_confirmation()
	if respect_input_guards:
		if host._skill_swipe_activity_surface()._skill_swipe_suppresses_button_action():
			return false
		var active_scroll = host._skill_detail_surface()._active_action_scroll_container()
		if active_scroll != null and active_scroll.is_child_click_suppressed():
			return false
	var action = host._action_data(skill_id, action_id)
	if action.is_empty():
		return false
	if BuildableModules.is_buildable(action) and not BuildableModules.is_built(host.built_modules, skill_id, action, Callable(host, "_action_key")):
		_attempt_buildable_action(skill_id, action)
		return false
	if not host._activity_unlock_runtime()._is_action_unlocked(skill_id, action):
		return false
	if host._is_event_action(action):
		return host._temporary_event_runtime()._start_temporary_event_action(skill_id, action_id, action, select_page)
	if not from_activity_queue and host._activity_queue_runtime().activity_queue_running:
		host._activity_queue_runtime()._stop_activity_queue_runtime(false)
	host._audio_director()._unlock_audio_for_gameplay()
	host._audio_director()._play_activity_tap_sfx()
	if skill_id == "thieving" and host._thieving_surface()._thieving_action_is_jailed(action_id):
		host._reward_feedback_surface()._set_result("%s is jailed: %s." % [str(action.get("name", "Activity")), GameFormatting.countdown(host._thieving_surface()._thieving_action_jail_remaining(action_id))])
		return false
	if host._passive_modules_runtime().is_passive_action(action):
		host._passive_modules_runtime().collect_passive_module(action_id, host._unix_now())
		return true
	if host._convergence_runtime()._is_convergence_action(action) and not host._convergence_runtime()._convergence_is_built(action_id):
		host._convergence_runtime()._start_convergence_build(action_id)
		var convergence_refresh_scroll = host._skill_detail_surface().detail_actions_scroll.scroll_vertical if host._skill_detail_surface().detail_actions_scroll != null else -1
		host._navigation_shell()._render_screen(false, convergence_refresh_scroll)
		host._update_ui(0.0, true)
		return false
	if host.running_skill_id == skill_id and host.running_action_id == action_id:
		host._reward_feedback_surface()._set_result("Tap %s to stop." % action["name"])
		host._skill_swipe_activity_surface()._pop_activity_button(host._action_key(skill_id, action_id))
		return false
	if not host.running_skill_id.is_empty() and not host.running_action_id.is_empty():
		_remember_canceled_action_progress(host.running_skill_id, host.running_action_id, host.action_progress)
	host._thieving_surface()._cancel_thieving_action_jail_resumes_for_started_action(skill_id, action_id)
	var action_key = host._action_key(skill_id, action_id)
	var stamina_cost = _effective_stamina(skill_id, action)
	if host._fighting_runtime().action_is_free_fighting_proto(skill_id, action_id):
		stamina_cost = 0.0
	var rooster_required_stamina = host._fighting_runtime().rooster_required_stamina(stamina_cost)
	if host._fighting_runtime().action_uses_rooster_punch_out_stage(action) and SkillState.host_stamina_value(skill_id, host) + 0.0001 < rooster_required_stamina:
		host._reward_feedback_surface()._set_result("%s requires %s stamina." % [action["name"], GameFormatting.stamina_cost_detail(rooster_required_stamina)])
		host._reward_feedback_surface()._float_tired_activity_feedback(action_key)
		host._update_ui(0.0, false)
		return false
	if host._is_event_action(action) and not _auto_eat_fish_for_action(skill_id, stamina_cost, host._skill_detail_surface().detail_regen_circle, true):
		host._reward_feedback_surface()._set_result(host._temporary_event_runtime()._event_needs_stamina_text(skill_id, action))
		host._reward_feedback_surface()._float_event_need_stamina_feedback(action_key, stamina_cost)
		return false
	if select_page:
		host.selected_skill_id = skill_id
	host.running_skill_id = skill_id
	host.running_action_id = action_id
	host.action_progress = _consume_canceled_action_progress(skill_id, action_id)
	action_opportunity_cycle_elapsed = 0.0
	_reset_emerald_action_opportunity_window()
	_reset_ruby_action_opportunity_window()
	_reset_action_opportunity_state()
	host.tired_activity_zero_float_action_key = ""
	host.fishing_runtime.net_set_in_water = false
	host.fishing_runtime.boat_set_in_water = false
	host.fishing_runtime.rod_set_in_water = false
	host.fishing_runtime.rod_haul_visual_seconds = 0.0
	if host._audio_director().music_cycle_active:
		host._audio_director()._record_music_flow_start()
	host._skill_swipe_activity_surface()._pop_activity_button(action_key)
	host._material_collection_surface()._sync_visible_mat_collection_for_action(skill_id, action_id, true)
	if host._fishing_rework_active_for_skill(skill_id) and not host._is_event_action(action):
		var tool_warning = host.fishing_runtime.tool_warning_text(action_id)
		if tool_warning.is_empty():
			host._reward_feedback_surface()._set_result("%s started." % action["name"])
		else:
			host._reward_feedback_surface()._set_result("%s started. %s: %s is a poor fit here." % [action["name"], tool_warning, host._fishing_ui_surface()._fishing_tool_label(host.fishing_runtime.equipped_tool_id)])
	elif (not from_activity_queue) and not _auto_eat_fish_for_action(skill_id, stamina_cost, host._skill_detail_surface().detail_regen_circle, false):
		host._reward_feedback_surface()._set_result(_low_stamina_training_text(action))
		host._reward_feedback_surface()._float_tired_activity_feedback(action_key)
		if SkillState.host_stamina_int(skill_id, host) <= 0:
			host.tired_activity_zero_float_action_key = action_key
	elif from_activity_queue and SkillState.host_stamina_value(skill_id, host) + 0.0001 < stamina_cost:
		host._reward_feedback_surface()._set_result(_low_stamina_training_text(action))
	else:
		host._reward_feedback_surface()._set_result("%s started." % action["name"])
	host._onboarding_runtime()._record_activity_start_for_tips()
	host._tutorial_overlay_surface().fade_out_onboarding_explore_tip()
	host._onboarding_runtime()._tutorial_on_action_started()
	return true


func _attempt_buildable_action(skill_id: String, action: Dictionary) -> bool:
	if not BuildableModules.is_buildable(action):
		return false
	var module_key := BuildableModules.key(skill_id, action, Callable(host, "_action_key"))
	if module_key.is_empty():
		return false
	if BuildableModules.is_built(host.built_modules, skill_id, action, Callable(host, "_action_key")):
		return true
	var need_text := "Need %s to %s %s." % [
		BuildableModules.cost_text(action, Callable(host.material_runtime, "amount_text_for_host").bind(host), Callable(host.material_runtime, "display_name")),
		BuildableModules.label(action).to_lower(),
		str(action.get("name", "module"))
	]
	if not BuildableModules.can_pay(action, Callable(host.material_runtime, "amount")):
		host._reward_feedback_surface()._set_result(need_text)
		return false
	if not BuildableModules.spend(action, Callable(host.material_runtime, "amount"), Callable(host.material_runtime, "spend_amount")):
		host._reward_feedback_surface()._set_result(need_text)
		return false
	var reward_xp := BuildableModules.xp_reward(action)
	if reward_xp > 0 and host.skills.has("build"):
		host.skills["build"]["xp"] = int(host.skills["build"].get("xp", 0)) + reward_xp
		SkillState.recalculate_level(host, "build")
	host.built_modules[module_key] = true
	host._reward_feedback_surface()._set_result("%s built: +%s Building XP." % [str(action.get("name", "Module")), reward_xp])
	host._mark_save_dirty("module built")
	host.save_game()
	var refresh_scroll: int = host._skill_detail_surface().detail_actions_scroll.scroll_vertical if host._skill_detail_surface().detail_actions_scroll != null else -1
	if host._skill_detail_surface()._play_buildable_module_built_animation(skill_id, action, refresh_scroll):
		return true
	host._navigation_shell()._render_screen(false, refresh_scroll)
	host._update_ui(0.0, true)
	return true


func _start_action_from_card_tap(skill_id: String, action_id: String, visual_card_key = "") -> bool:
	if host._material_collection_surface().berry_mode_card_tap_handled(skill_id, action_id):
		return false
	var key = host._action_key(skill_id, action_id)
	var now = Time.get_ticks_msec()
	if host._skill_detail_surface().last_action_card_tap_key == key and now - host._skill_detail_surface().last_action_card_tap_msec < host.ACTION_CARD_DUPLICATE_TAP_MSEC:
		return false
	if host.running_skill_id == skill_id and host.running_action_id == action_id:
		host._skill_detail_surface().last_action_card_tap_key = key
		host._skill_detail_surface().last_action_card_tap_msec = now
		return _stop_running_action(skill_id, action_id)
	host._tutorial_overlay_surface()._on_activity_start_tutorial_card_tapped(skill_id, action_id)
	if _start_action(skill_id, action_id, true, false):
		host._skill_detail_surface().last_action_card_tap_key = key
		host._skill_detail_surface().last_action_card_tap_msec = now
		if not visual_card_key.is_empty() and visual_card_key != key:
			host._skill_swipe_activity_surface()._pop_activity_button(visual_card_key)
		var action: Dictionary = host._action_data(skill_id, action_id)
		if host._fighting_runtime().is_boss_fight_action(action):
			if host._fighting_runtime().action_uses_rooster_punch_out_stage(action):
				var card_key: String = str(visual_card_key) if not str(visual_card_key).is_empty() else str(key)
				host._fighting_runtime().sync_rooster_punch_out_stage_active(host.action_cards.get(card_key, {}), skill_id, action_id, true)
			host._update_ui(0.0, false)
		return true
	return false

func _apply_offline_active_action(offline_seconds: float) -> Dictionary:
	if offline_seconds <= 0.0 or host.running_skill_id.is_empty() or host.running_action_id.is_empty():
		return {"handled": false}
	var action = host._action_data(host.running_skill_id, host.running_action_id)
	if action.is_empty() or host._passive_modules_runtime().is_passive_action(action):
		host.running_skill_id = ""
		host.running_action_id = ""
		host.action_progress = 0.0
		return {"handled": false}
	if not host._activity_unlock_runtime()._is_action_unlocked(host.running_skill_id, action):
		host.action_progress = 0.0
		return {"handled": false}
	if host._convergence_runtime()._is_convergence_action(action):
		return _apply_offline_convergence_action(offline_seconds, host.running_action_id, action)
	var skill_id = host.running_skill_id
	var action_id = host.running_action_id
	var mastery_action_id = host.fishing_runtime.mastery_action_id(action_id, FishingState.FISHING_TOOL_LOCATION_ACTIONS, Callable(host._fishing_ui_surface(), "_fishing_location_thumbnail_path")) if host._fishing_rework_active_for_skill(skill_id) and not host._is_event_action(action) else action_id
	var old_skill_level = SkillState.host_skill_level(host, skill_id)
	var old_global_level = SkillState.global_level(host.skills)
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
			and remaining >= cycle_seconds * float(OFFLINE_ACTIVE_BATCH_MIN_CYCLES)
		):
			var batch_cycles = mini(
				int(floor(remaining / cycle_seconds)),
				OFFLINE_ACTIVE_BATCH_MAX_CYCLES
			)
			if batch_cycles >= OFFLINE_ACTIVE_BATCH_MIN_CYCLES:
				var batch_result = _grant_offline_action_completion_batch(skill_id, action_id, action, batch_cycles)
				var batch_seconds = float(batch_cycles) * cycle_seconds
				_apply_stamina_regen_seconds_except(batch_seconds, false, skill_id)
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
		var stamina_ready = true if fishing_rework_attempt else SkillState.host_stamina_value(skill_id, host) + 0.0001 >= cost
		var speed_mult = _action_progress_speed_multiplier(skill_id, action, stamina_ready)
		var seconds_to_complete = maxf(0.001, action_seconds * (1.0 - progress) / speed_mult)
		var seconds_until_ready = INF
		if not stamina_ready and cost <= SkillState.max_stamina(host, skill_id):
			seconds_until_ready = _seconds_until_stamina_cost(skill_id, cost)
		var step = minf(remaining, minf(seconds_to_complete, seconds_until_ready))
		if remaining < seconds_to_complete:
			_apply_stamina_regen_seconds(step, false)
			host.action_progress = clampf(progress + step / action_seconds * speed_mult, 0.0, 0.999)
			remaining -= step
			if is_equal_approx(step, seconds_until_ready):
				continue
			break
		_apply_stamina_regen_seconds(step, false)
		remaining -= step
		if step < seconds_to_complete and is_equal_approx(step, seconds_until_ready):
			host.action_progress = clampf(progress + step / action_seconds * speed_mult, 0.0, 0.999)
			continue
		host.action_progress = 0.0
		if not fishing_rework_attempt:
			SkillState.spend_action_stamina(host.stamina, host.stamina_bank, skill_id, cost, Callable(SkillState, "host_max_stamina").bind(host))
		var completion = _grant_offline_action_completion(skill_id, action_id, action)
		completions += 1
		if bool(completion.get("success", false)):
			successes += 1
		xp_total += int(completion.get("xp", 0))
		mastery_total += float(completion.get("mastery", 0.0))
		fish_total += float(completion.get("fish", 0.0))
		logs_spent += int(completion.get("logs_spent", 0))
	var new_skill_level = SkillState.host_skill_level(host, skill_id)
	var new_global_level = SkillState.global_level(host.skills)
	var new_mastery_level = MasteryState.level(host.mastery, host._action_key(skill_id, mastery_action_id))
	return {
		"handled": true,
		"skill_id": skill_id,
		"skill_name": SkillState.skill_name(host.skill_defs, skill_id),
		"action_id": action_id,
		"action_name": str(action.get("name", "activity")),
		"action_art": host._fishing_ui_surface()._player_facing_action_art_path(skill_id, action),
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
	var stamina_ready = fishing_rework or SkillState.host_stamina_value(skill_id, host) + 0.0001 >= cost
	var speed_mult = _action_progress_speed_multiplier(skill_id, action, stamina_ready)
	var complete_seconds = maxf(0.001, action_seconds * (1.0 - clampf(progress, 0.0, 0.999)) / speed_mult)
	if fishing_rework or cost <= 0.0 or cost > SkillState.max_stamina(host, skill_id):
		return complete_seconds
	var regen_bonus = (1.0 + host._hub_surface()._hub_pond_regen_bonus()) * SkillState.honey_stamina_regen_multiplier(player_has_stamina_honey())
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
	var locked_preview_available_before = host._activity_unlock_runtime()._locked_activity_preview_available()
	for _i in range(count):
		var completion = _grant_offline_action_completion(skill_id, action_id, action, true)
		if bool(completion.get("success", false)):
			successes += 1
		xp_total += int(completion.get("xp", 0))
		mastery_total += float(completion.get("mastery", 0.0))
		fish_total += float(completion.get("fish", 0.0))
		logs_spent += int(completion.get("logs_spent", 0))
	SkillState.recalculate_level(host, skill_id)
	host._passive_modules_runtime().sync_passive_module_unlocks(host._unix_now())
	host._activity_unlock_ceremony_surface().queue_locked_preview_reveal_if_needed(locked_preview_available_before)
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
		old_levels[str(raw_skill_id)] = SkillState.host_skill_level(host, str(raw_skill_id))
	var cycle_seconds = host._convergence_runtime()._convergence_total_cycle_seconds(action)
	var remaining = maxf(0.0, offline_seconds)
	var completions = 0
	var xp_total = 0
	while remaining > 0.001:
		if remaining >= cycle_seconds * float(OFFLINE_CONVERGENCE_BATCH_MIN_CYCLES):
			var batch_cycles = mini(
				int(floor(remaining / cycle_seconds)),
				OFFLINE_CONVERGENCE_BATCH_MAX_CYCLES
			)
			if batch_cycles >= OFFLINE_CONVERGENCE_BATCH_MIN_CYCLES:
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
			SkillState.recalculate_level(host, skill_id)
		var state = host._convergence_runtime()._ensure_convergence_state(module_id)
		state["completions"] = int(state.get("completions", 0)) + 1
		host.convergence_modules[module_id] = state
		completions += 1
		xp_total += xp_reward * host._convergence_runtime()._convergence_skill_order(action).size()
	var completed_achievements = AchievementState.newly_completed(AchievementState.milestones(host, false), completed_achievements_before)
	return {
		"handled": true,
		"skill_id": "build",
		"skill_name": SkillState.skill_name(host.skill_defs, "build"),
		"action_id": module_id,
		"action_name": str(action.get("name", "Five-Fold Shrine")),
		"action_art": host._fishing_ui_surface()._player_facing_action_art_path("build", action),
		"completions": completions,
		"successes": completions,
		"xp": xp_total,
		"mastery": 0.0,
		"logs_spent": 0,
		"old_skill_level": int(old_levels.get("build", SkillState.host_skill_level(host, "build"))),
		"new_skill_level": SkillState.host_skill_level(host, "build"),
		"old_global_level": 0,
		"new_global_level": SkillState.global_level(host.skills),
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
		SkillState.recalculate_level(host, str(raw_skill_id))
	var state = host._convergence_runtime()._ensure_convergence_state(module_id)
	state["completions"] = int(state.get("completions", 0)) + count
	host.convergence_modules[module_id] = state
	return {"completions": count, "xp": xp_total}


func _seconds_until_stamina_cost(skill_id: String, cost: float) -> float:
	if SkillState.host_stamina_value(skill_id, host) + 0.0001 >= cost:
		return 0.0
	var missing = cost - SkillState.host_stamina_value(skill_id, host)
	var regen_bonus = (1.0 + host._hub_surface()._hub_pond_regen_bonus()) * SkillState.honey_stamina_regen_multiplier(player_has_stamina_honey())
	return maxf(0.0, missing * host.STAMINA_REGEN_SECONDS / regen_bonus)


func _grant_offline_action_completion(skill_id: String, action_id: String, action: Dictionary, defer_recalc = false) -> Dictionary:
	if host._fishing_rework_active_for_skill(skill_id) and not host._is_event_action(action):
		return _grant_offline_fishing_action_completion(skill_id, action_id, action, defer_recalc)
	var mastery_reward = _offline_mastery_reward(skill_id, action_id, action)
	var success = _roll_action_success(skill_id, action)
	var xp_reward = 0
	var mastery_gained = 0.0
	var logs_spent = 0
	var old_skill_level = SkillState.host_skill_level(host, skill_id)
	var old_mastery_level = MasteryState.level(host.mastery, host._action_key(skill_id, action_id))
	var locked_preview_available_before = host._activity_unlock_runtime()._locked_activity_preview_available()
	if success:
		var plank_bonus_used = host._passive_modules_runtime().plank_bonus_applies(skill_id)
		xp_reward = _offline_xp_reward(action, skill_id, plank_bonus_used)
		var berry_prep_reward_map = {}
		berry_prep_reward_map[skill_id] = xp_reward
		var berry_prep_result = host.material_runtime.consume_berry_prep_bonus(skill_id, action_id, berry_prep_reward_map, Callable(host, "_action_data"), Callable(host, "_action_key"))
		host._material_collection_surface().play_berry_prep_badge_feedback(skill_id, action_id, not berry_prep_result.is_empty(), host.material_runtime.berry_prep_matches(skill_id, action_id, Callable(host, "_action_data"), Callable(host, "_action_key")) and host.material_runtime.amount("berries") < 1.0)
		xp_reward += maxi(0, int(berry_prep_result.get("bonus_xp", 0)))
		host.skills[skill_id]["xp"] = int(host.skills[skill_id]["xp"]) + xp_reward
		if mastery_reward > 0.0:
			MasteryState.add_host_xp(host, skill_id, action_id, mastery_reward)
			mastery_gained = mastery_reward
			host._onboarding_runtime()._register_silver_opportunity_tip_anchor(skill_id, action_id, old_mastery_level, MasteryState.level(host.mastery, host._action_key(skill_id, action_id)))
		if plank_bonus_used:
			host.material_runtime.spend_amount("softwood", 1.0)
			logs_spent = 1
		host._hub_runtime().record_mission_action_completion(skill_id, action_id)
		if not defer_recalc:
			SkillState.recalculate_level(host, skill_id)
			host._activity_unlock_ceremony_surface().queue_locked_preview_reveal_if_needed(locked_preview_available_before)
			host._passive_modules_runtime().sync_passive_module_unlocks(host._unix_now())
	elif not host._fishing_rework_active_for_skill(skill_id):
		var failure_mastery_reward = 0.0 if MasteryState.would_reward_level_up(host.mastery, host._action_key(skill_id, action_id), mastery_reward, host.MASTERY_MAX_LEVEL) else mastery_reward
		if failure_mastery_reward > 0.0:
			MasteryState.add_host_xp(host, skill_id, action_id, failure_mastery_reward)
			mastery_gained = failure_mastery_reward
	if not defer_recalc and SkillState.host_skill_level(host, skill_id) > old_skill_level:
		SkillState.invalidate_stat_caches(host)
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
	var mastery_action_id = host.fishing_runtime.mastery_action_id(action_id, FishingState.FISHING_TOOL_LOCATION_ACTIONS, Callable(host, "_fishing_location_thumbnail_path"))
	var old_skill_level = SkillState.host_skill_level(host, skill_id)
	var locked_preview_available_before = host._activity_unlock_runtime()._locked_activity_preview_available()
	var direct_fish_currency_reward = FishingState.has_direct_fish_currency_reward(action)
	var netting = host.fishing_runtime.equipped_tool_id == "net" and not direct_fish_currency_reward
	var boating = host.fishing_runtime.equipped_tool_id == "boat" and not direct_fish_currency_reward
	var rodding = FishingState.is_rod(host.fishing_runtime.equipped_tool_id)
	if success:
		if rodding:
			host.fishing_runtime.rod_set_in_water = false
		xp_reward = _offline_fishing_xp_reward(action, skill_id)
		host.skills[skill_id]["xp"] = int(host.skills[skill_id]["xp"]) + xp_reward
		var direct_fish_currency_amount = FishingState.roll_direct_fish_currency(action) if direct_fish_currency_reward else 0.0
		var fish_count = 0 if direct_fish_currency_reward else host.fishing_runtime.roll_fish_count(host, action, host.fishing_runtime.equipped_tool_id)
		var haul_count = fish_count
		if netting:
			haul_count = _record_offline_fishing_net_success(fish_count, xp_reward)
		elif boating:
			haul_count = _record_offline_fishing_boat_success(fish_count, xp_reward)
		if direct_fish_currency_reward:
			fish_gained = direct_fish_currency_amount
			host.fishing_runtime.award_fish_currency(host, fish_gained)
		elif haul_count > 0:
			fish_gained = FishingState.tool_food_value_for_catches(host.fishing_runtime.equipped_tool_id, action_id, haul_count)
			host.fishing_runtime.award_fish_currency(host, fish_gained)
		var net_fill_without_harvest = netting and haul_count <= 0
		var mastery_reward = _offline_fishing_mastery_reward(skill_id, action_id, net_fill_without_harvest)
		if mastery_reward > 0.0:
			MasteryState.add_host_xp(host, skill_id, mastery_action_id, mastery_reward)
			mastery_gained = mastery_reward
			if net_fill_without_harvest:
				host.fishing_runtime.record_mastery_stored("net", mastery_reward)
			elif boating and haul_count <= 0:
				host.fishing_runtime.record_mastery_stored("boat", mastery_reward)
		host._hub_runtime().record_mission_action_completion(skill_id, action_id)
		if not defer_recalc:
			SkillState.recalculate_level(host, skill_id)
			host._activity_unlock_ceremony_surface().queue_locked_preview_reveal_if_needed(locked_preview_available_before)
			host._passive_modules_runtime().sync_passive_module_unlocks(host._unix_now())
	else:
		host.fishing_runtime.mark_missed(host.fishing_runtime.equipped_tool_id)
	if not defer_recalc and SkillState.host_skill_level(host, skill_id) > old_skill_level:
		SkillState.invalidate_stat_caches(host)
	return {
		"success": success,
		"xp": xp_reward,
		"mastery": mastery_gained,
		"fish": fish_gained,
		"logs_spent": 0
	}


func _record_offline_fishing_net_success(fish_count: int, xp_reward: int) -> int:
	return int(host.fishing_runtime.record_batch_success("net", fish_count, xp_reward, FishingState.FISHING_NET_HAUL_THRESHOLD, FishingState.FISHING_NET_HAUL_VISUAL_SECONDS).get("haul_count", 0))


func _record_offline_fishing_boat_success(fish_count: int, xp_reward: int) -> int:
	return int(host.fishing_runtime.record_batch_success("boat", fish_count, xp_reward, FishingState.FISHING_BOAT_HAUL_THRESHOLD, FishingState.FISHING_BOAT_HAUL_VISUAL_SECONDS).get("haul_count", 0))


func _offline_xp_reward(action: Dictionary, skill_id: String, force_plank_bonus = false) -> int:
	if _fishing_net_soak_active(skill_id):
		return maxi(1, int(round(float(FishingState.net_xp_reward(host, action)) * OFFLINE_XP_MULT)))
	return maxi(1, int(round(float(_effective_xp(action, skill_id, force_plank_bonus)) * OFFLINE_XP_MULT)))


func _offline_fishing_xp_reward(action: Dictionary, skill_id: String) -> int:
	var xp_reward = host.fishing_runtime.flat_xp_reward(host, action, skill_id)
	if xp_reward <= 0:
		return 0
	return maxi(1, int(round(float(xp_reward) * OFFLINE_XP_MULT)))


func _offline_mastery_reward(skill_id: String, action_id: String, action: Dictionary) -> float:
	return maxf(0.0, MasteryState.reward_for_action(host, skill_id, action_id, action) * OFFLINE_XP_MULT)


func _offline_fishing_mastery_reward(skill_id: String, action_id: String, net_fill_without_harvest = false) -> float:
	var mastery_reward = FishingState.mastery_reward(host, skill_id, action_id)
	if net_fill_without_harvest:
		mastery_reward *= FishingState.FISHING_NET_FILL_MASTERY_MULT
	return maxf(0.0, mastery_reward * OFFLINE_XP_MULT)


func _offline_unlocked_actions(_skill_id: String, _old_level: int, _new_level: int) -> Array:
	return []
