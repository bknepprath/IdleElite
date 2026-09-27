extends RefCounted

const CleanProgressBar = preload("res://scripts/ui/clean_progress_bar.gd")
const ActivityProgressRail = preload("res://scripts/ui/activity_progress_rail.gd")
const ActivityCardStyles = preload("res://scripts/ui/activity_card_styles.gd")
const GameFormatting = preload("res://scripts/core/formatting.gd")
const AchievementState = preload("res://scripts/achievements/state.gd")
const MasteryState = preload("res://scripts/progression/mastery_state.gd")
const RegenCircle = preload("res://scripts/ui/regen_circle.gd")
const SkillState = preload("res://scripts/progression/skill_state.gd")
const NavigationShell = preload("res://scripts/ui/navigation_shell.gd")
const ProfileChatOverlaySurface = preload("res://scripts/ui/profile_chat_overlay_surface.gd")

const ACTIVITY_CRIT_OVERLAY_GROUP := "activity_crit_overlay"
const REWARD_FLOAT_Z := 3460
const SKILL_REWARD_FLOAT_GROUP := "skill_reward_float"
const SKILL_REWARD_FLOAT_MULTI_DELAY_SECONDS := 0.20
const SKILL_REWARD_FLOAT_MULTI_SPACING_X := 38.0
const SKILL_REWARD_FLOAT_MULTI_STACK_Y := 15.0
const STAMINA_NEED_FISH_FLOAT_GROUP := "stamina_need_fish_float"
const TIRED_ACTIVITY_FLOAT_TEXT := "Tired!\n20% speed"
const EVENT_NEED_STAMINA_FLOAT_TEXT := "Need\n%s STAM"
const TIRED_ACTIVITY_FLOAT_COLOR := Color("#fff2a8")
const ACTIVITY_CRIT_FEEDBACK_SECONDS := 1.68
const ACTIVITY_CRIT_SHAKE_PIXELS := 8.5
const ACTIVITY_CRIT_LIFT_PIXELS := 3.5
const ACTIVITY_CRIT_CARD_SCALE_PEAK := 1.035
const ACTIVITY_CRIT_ART_BURST_SCALE := 1.52
const ACTIVITY_CRIT_TEXT_COLOR := Color("#ffd95a")
const ACTIVITY_CRIT_TEXT_SIZE := Vector2(380, 90)
const ACTIVITY_MEGA_CRIT_FEEDBACK_SECONDS := 5.04
const ACTIVITY_MEGA_CRIT_SHAKE_MULT := 0.28
const ACTIVITY_MEGA_CRIT_LIFT_MULT := 2.0
const ACTIVITY_MEGA_CRIT_CARD_SCALE_PEAK := 1.012
const ACTIVITY_MEGA_CRIT_ART_BURST_SCALE := 2.05
const ACTIVITY_MEGA_CRIT_TEXT_COLOR := Color("#fff052")
const ACTIVITY_MEGA_CRIT_TEXT_SIZE := Vector2(470, 110)
const ACTIVITY_MEGA_CRIT_HIGHLIGHT_BLEED := 10.0
const ACTIVITY_MEGA_CRIT_ART_DRIFT_PIXELS := 46.0
const BONUS_EMPHASIS_FLOAT_COLOR := Color("#33f17a")
const BONUS_EMPHASIS_FLASH_COLOR := Color("#3dff8d")
const BONUS_EMPHASIS_SECONDS := 0.54
const BONUS_EMPHASIS_CASCADE_SECONDS := 2.0

var host
var action_crit_tweens = {}


func _init(host_ref) -> void:
	host = host_ref


func _reward_float_reserved_bottom() -> float:
	var reserved := float(NavigationShell.BOTTOM_NAV_HEIGHT)
	if host._profile_chat_overlay_surface()._global_chat_allowed() and host._profile_chat_overlay_surface()._chat_strip_visible_on_current_screen():
		reserved += float(ProfileChatOverlaySurface.CHAT_STRIP_HEIGHT)
		reserved += host._navigation_shell()._module_utility_row_reserved_height_for_screen()
	return minf(reserved, maxf(0.0, host._current_canvas_size().y - 120.0))


func _clamp_reward_holder_position(parent: Control, desired_position: Vector2, holder_size: Vector2, margin := 24.0) -> Vector2:
	if parent == null or not is_instance_valid(parent) or not parent.is_inside_tree():
		return desired_position
	var canvas_size: Vector2 = host._current_canvas_size()
	var visible_rect := Rect2(
		Vector2(margin, margin),
		Vector2(
			maxf(1.0, canvas_size.x - margin * 2.0),
			maxf(1.0, canvas_size.y - _reward_float_reserved_bottom() - margin * 2.0)
		)
	)
	var to_parent := parent.get_global_transform_with_canvas().affine_inverse()
	var local_a := to_parent * visible_rect.position
	var local_b := to_parent * visible_rect.end
	var local_rect := Rect2(
		Vector2(minf(local_a.x, local_b.x), minf(local_a.y, local_b.y)),
		Vector2(absf(local_b.x - local_a.x), absf(local_b.y - local_a.y))
	)
	return Vector2(
		clampf(desired_position.x, local_rect.position.x, maxf(local_rect.position.x, local_rect.end.x - holder_size.x)),
		clampf(desired_position.y, local_rect.position.y, maxf(local_rect.position.y, local_rect.end.y - holder_size.y))
	)


func _flash_bonus_control(anchor: Control, delay := 0.0) -> void:
	if anchor == null or not is_instance_valid(anchor):
		return
	if delay > 0.0:
		var anchor_id := anchor.get_instance_id()
		var delayed_tween: Tween = host.create_tween()
		delayed_tween.tween_interval(delay)
		delayed_tween.tween_callback(_flash_bonus_control_bound.bind(anchor_id))
		return
	var flash := Panel.new()
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.z_index = 96
	flash.add_theme_stylebox_override("panel", ActivityCardStyles.bonus_emphasis(BONUS_EMPHASIS_FLASH_COLOR))
	anchor.add_child(flash)
	flash.modulate = Color(1, 1, 1, 0.96)
	var tween: Tween = host.create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, BONUS_EMPHASIS_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(host._app_lifecycle_runtime()._queue_free_instance_id.bind(flash.get_instance_id()))


func _flash_bonus_control_bound(anchor_id: int) -> void:
	var anchor: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(anchor_id))
	if anchor == null:
		return
	_flash_bonus_control(anchor, 0.0)


func _flash_action_bonus_bottom(card: Dictionary, delay := 0.0) -> void:
	var pop := card.get("pop") as Control
	var rail := card.get("progress") as Control
	if pop == null or rail == null or not is_instance_valid(pop) or not is_instance_valid(rail):
		return
	if not pop.is_inside_tree() or not rail.is_inside_tree():
		return
	if delay > 0.0:
		var card_key: String = _action_card_key_from_card(card)
		if card_key.is_empty():
			return
		var delayed_tween: Tween = host.create_tween()
		delayed_tween.tween_interval(delay)
		delayed_tween.tween_callback(_flash_action_bonus_bottom_by_key.bind(card_key))
		return
	var overlay := Panel.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 230
	overlay.add_theme_stylebox_override("panel", ActivityCardStyles.bonus_bottom_highlight(BONUS_EMPHASIS_FLASH_COLOR))
	var rail_rect := rail.get_global_rect()
	overlay.position = rail_rect.position - pop.global_position
	overlay.size = rail_rect.size
	pop.add_child(overlay)
	overlay.modulate = Color(1, 1, 1, 0.92)
	var tween: Tween = host.create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, BONUS_EMPHASIS_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(host._app_lifecycle_runtime()._queue_free_instance_id.bind(overlay.get_instance_id()))


func _flash_action_bonus_bottom_by_key(card_key: String) -> void:
	if not host.action_cards.has(card_key):
		return
	_flash_action_bonus_bottom(host.action_cards[card_key] as Dictionary, 0.0)


func _append_visible_stamina_bonus_entries(entries: Array, amount: int, skill_id := "") -> void:
	if amount <= 0:
		return
	var text := "+%s MAX" % amount
	if host.current_screen == "menu":
		for raw_skill_id in host.skill_cards.keys():
			var card_skill_id := str(raw_skill_id)
			if not skill_id.is_empty() and card_skill_id != skill_id:
				continue
			var card := host.skill_cards[raw_skill_id] as Dictionary
			_append_bonus_emphasis_entry(entries, {
				"kind": "stamina",
				"anchor": _skill_menu_card_side_gauge(card),
				"text": text,
				"font_size": 48,
				"start_offset": Vector2(0, -27),
				"rise": Vector2(0, -75)
			})
	elif host.current_screen == "skill" and (skill_id.is_empty() or skill_id == host.selected_skill_id):
		_append_bonus_emphasis_entry(entries, {
			"kind": "stamina",
			"anchor": host._skill_detail_surface().detail_regen_circle,
			"text": text,
			"font_size": 48,
			"start_offset": Vector2(0, -35),
			"rise": Vector2(0, -85)
		})


func _capture_visible_bonus_snapshot_if_needed(skill_id: String, action_id: String, action: Dictionary) -> Dictionary:
	if _action_completion_could_change_visible_bonuses(skill_id, action_id, action):
		return _capture_visible_bonus_snapshot()
	return {}


func _action_completion_could_change_visible_bonuses(skill_id: String, action_id: String, action: Dictionary) -> bool:
	if skill_id.is_empty() or action_id.is_empty() or action.is_empty():
		return false
	var potential_rewards := _max_action_completion_xp_reward_map(skill_id, action)
	for raw_reward_skill_id in potential_rewards.keys():
		var reward_skill_id := str(raw_reward_skill_id)
		var potential_xp := int(potential_rewards.get(raw_reward_skill_id, 0))
		if potential_xp > 0 and _would_skill_xp_level_up(reward_skill_id, potential_xp):
			return true
	var mastery_reward: float = MasteryState.reward_for_action(host, skill_id, action_id, action)
	if MasteryState.would_reward_level_up(host.mastery, host._action_key(skill_id, action_id), mastery_reward, host.MASTERY_MAX_LEVEL):
		return true
	return false


func _max_action_completion_xp_reward_map(skill_id: String, action: Dictionary) -> Dictionary:
	if host._fishing_rework_active_for_skill(skill_id) and not host._is_event_action(action):
		return {skill_id: host.fishing_runtime.flat_xp_reward(host, action, skill_id)}
	var force_plank_bonus: bool = host._passive_modules_runtime().plank_bonus_applies(skill_id)
	return host._action_runtime()._completion_xp_reward_map(action, skill_id, force_plank_bonus, false, true, false)


func _would_skill_xp_level_up(skill_id: String, amount: int) -> bool:
	if amount <= 0 or not host.skills.has(skill_id):
		return false
	var current_level: int = SkillState.host_skill_level(host, skill_id)
	if current_level >= 99:
		return false
	var xp_total := int(host.skills.get(skill_id, {}).get("xp", 0))
	return xp_total + amount >= SkillState.xp_for_level(current_level + 1)


func _capture_visible_bonus_snapshot() -> Dictionary:
	var action_stats := {}
	var max_stamina_by_skill := {}
	for def in host.skill_defs:
		var skill_id := str(def["id"])
		max_stamina_by_skill[skill_id] = SkillState.max_stamina(host, skill_id)
	for raw_key in host.action_cards.keys():
		var key := str(raw_key)
		var card := host.action_cards[key] as Dictionary
		if not _action_card_can_show_bonus_emphasis(card, key):
			continue
		var parts := key.split(":")
		if parts.size() < 2:
			continue
		var skill_id := str(parts[0])
		var action_id := str(parts[1])
		var action: Dictionary = host._action_data(skill_id, action_id)
		if action.is_empty():
			continue
		if host._passive_modules_runtime().is_passive_action(action):
			continue
		action_stats[key] = {
			"xp": host._action_runtime()._effective_xp(action, skill_id),
			"stamina": host._action_runtime()._effective_stamina(skill_id, action),
			"seconds": host._action_runtime()._action_cycle_seconds(skill_id, action),
			"base_seconds": maxf(0.1, float(action.get("seconds", 1.0))),
			"success": host._action_runtime()._success_chance(skill_id, action)
		}
	return {
		"max_stamina": SkillState.max_stamina(host),
		"max_stamina_by_skill": max_stamina_by_skill,
		"global_buff_lines": AchievementState.global_medal_buff_lines(host),
		"actions": action_stats
	}


func _emphasize_visible_bonus_changes(before: Dictionary) -> void:
	if before.is_empty():
		return
	var entries := []
	var old_max_stamina_by_skill := before.get("max_stamina_by_skill", {}) as Dictionary
	for def in host.skill_defs:
		var skill_id := str(def["id"])
		var old_max_stamina := int(old_max_stamina_by_skill.get(skill_id, before.get("max_stamina", SkillState.max_stamina(host, skill_id))))
		var new_max_stamina: int = SkillState.max_stamina(host, skill_id)
		if new_max_stamina > old_max_stamina:
			_append_visible_stamina_bonus_entries(entries, new_max_stamina - old_max_stamina, skill_id)
	var old_global_buff_lines := str(before.get("global_buff_lines", AchievementState.global_medal_buff_lines(host)))
	if old_global_buff_lines != AchievementState.global_medal_buff_lines(host):
		_append_bonus_emphasis_entry(entries, {
			"kind": "global_buff",
			"anchor": host._achievement_overlay_surface().global_buff_anchor()
		})
	var old_actions := before.get("actions", {}) as Dictionary
	for raw_key in host.action_cards.keys():
		var key := str(raw_key)
		if not old_actions.has(key):
			continue
		var card := host.action_cards[key] as Dictionary
		if not _action_card_can_show_bonus_emphasis(card, key):
			continue
		var parts := key.split(":")
		if parts.size() < 2:
			continue
		var skill_id := str(parts[0])
		var action_id := str(parts[1])
		var action: Dictionary = host._action_data(skill_id, action_id)
		if action.is_empty():
			continue
		if host._passive_modules_runtime().is_passive_action(action):
			continue
		var old_stats := old_actions[key] as Dictionary
		var old_xp := int(old_stats.get("xp", host._action_runtime()._effective_xp(action, skill_id)))
		var new_xp: int = host._action_runtime()._effective_xp(action, skill_id)
		if new_xp > old_xp:
			_append_action_stat_bonus_entry(entries, card, key, "xp", "+%s XP" % (new_xp - old_xp))
		var old_stamina := float(old_stats.get("stamina", host._action_runtime()._effective_stamina(skill_id, action)))
		var new_stamina: float = host._action_runtime()._effective_stamina(skill_id, action)
		if new_stamina + 0.0001 < old_stamina:
			_append_action_stat_bonus_entry(entries, card, key, "stamina", "-%s STAM" % GameFormatting.stamina_cost_detail(old_stamina - new_stamina))
		var old_seconds := float(old_stats.get("seconds", host._action_runtime()._action_cycle_seconds(skill_id, action)))
		var new_seconds: float = host._action_runtime()._action_cycle_seconds(skill_id, action)
		if new_seconds + 0.001 < old_seconds:
			var base_seconds := maxf(0.1, float(old_stats.get("base_seconds", action.get("seconds", 1.0))))
			var reduction_pct: float = (old_seconds - new_seconds) / base_seconds * 100.0
			_append_action_stat_bonus_entry(entries, card, key, "time", GameFormatting.bonus_percent_delta(-reduction_pct))
		var old_success := float(old_stats.get("success", host._action_runtime()._success_chance(skill_id, action)))
		var new_success: float = host._action_runtime()._success_chance(skill_id, action)
		if new_success > old_success + 0.001:
			_append_action_stat_bonus_entry(entries, card, key, "success", GameFormatting.bonus_percent_delta(new_success - old_success))
	_play_visible_bonus_emphasis_entries(entries)


func _emphasize_visible_bonus_changes_deferred(before: Dictionary) -> void:
	if before.is_empty():
		return
	Callable(self, "_emphasize_visible_bonus_changes").call_deferred(before)


func _append_action_stat_bonus_entry(entries: Array, card: Dictionary, card_key: String, stat_kind: String, text: String) -> void:
	if not _action_card_can_show_bonus_emphasis(card, card_key):
		return
	var boxes := card.get("stat_boxes", {}) as Dictionary
	_append_bonus_emphasis_entry(entries, {
		"kind": "action_stat",
		"anchor": boxes.get(stat_kind) as Control,
		"card": card,
		"card_key": card_key,
		"stat_kind": stat_kind,
		"text": text
	})


func _action_card_can_show_bonus_emphasis(card: Dictionary, card_key := "") -> bool:
	if card.is_empty() or bool(card.get("preview_only", false)):
		return false
	var resolved_key := card_key
	if resolved_key.is_empty():
		resolved_key = _action_card_key_from_card(card)
	var root: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("root"))
	if root != null and (not root.visible or root.is_queued_for_deletion()):
		return false
	if host.current_screen == "skill":
		return _action_card_module_visible_in_detail_scroll(card, resolved_key)
	return root == null or root.is_visible_in_tree()


func _action_card_module_visible_in_detail_scroll(card: Dictionary, card_key: String) -> bool:
	if host._skill_detail_surface().detail_actions_scroll == null or not is_instance_valid(host._skill_detail_surface().detail_actions_scroll) or not host._skill_detail_surface().detail_actions_scroll.is_visible_in_tree():
		return false
	var skill_id := str(card.get("skill_id", ""))
	if skill_id.is_empty() and not card_key.is_empty():
		var key_parts := card_key.split(":")
		if key_parts.size() >= 2:
			skill_id = str(key_parts[0])
	if skill_id != host.selected_skill_id:
		return false
	var stack_host: Control = _action_card_detail_stack_host(card, card_key)
	if stack_host == null:
		return false
	return _detail_stack_host_visible_in_current_view(stack_host)


func _action_card_detail_stack_host(card: Dictionary, card_key: String) -> Control:
	var stack := host._skill_detail_surface()._resolve_detail_lazy_stack() as Control
	if stack == null or not is_instance_valid(stack):
		return null
	var entry: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("entry"))
	if entry != null:
		var entry_host: Control = host._skill_detail_surface()._detail_stack_child_for_control(entry, stack)
		return entry_host if entry_host != null else entry
	var root: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("root"))
	if root != null:
		var root_host: Control = host._skill_detail_surface()._detail_stack_child_for_control(root, stack)
		return root_host if root_host != null else root
	if not card_key.is_empty() and host._skill_detail_surface().detail_action_card_nodes.has(card_key):
		var keyed_host: Control = host._app_lifecycle_runtime().valid_control_ref(host._skill_detail_surface().detail_action_card_nodes.get(card_key))
		if keyed_host != null:
			return keyed_host
	var action_id := str(card.get("action_id", ""))
	if action_id.is_empty() and not card_key.is_empty():
		var key_parts := card_key.split(":")
		if key_parts.size() >= 2:
			action_id = str(key_parts[1])
	if not action_id.is_empty() and host._skill_detail_surface().detail_action_card_nodes.has(action_id):
		var action_host: Control = host._app_lifecycle_runtime().valid_control_ref(host._skill_detail_surface().detail_action_card_nodes.get(action_id))
		if action_host != null:
			return action_host
	return null


func _detail_stack_host_visible_in_current_view(stack_host: Control) -> bool:
	if stack_host == null or not is_instance_valid(stack_host) or not stack_host.visible or not stack_host.is_visible_in_tree() or stack_host.is_queued_for_deletion():
		return false
	var stack := host._skill_detail_surface()._resolve_detail_lazy_stack() as Control
	if stack == null or not is_instance_valid(stack):
		return false
	var rect: Rect2 = host._skill_detail_surface()._detail_control_rect_in_stack(stack_host, stack)
	if rect.size.y <= 1.0:
		return false
	var view_top: float = host._skill_detail_surface()._detail_lazy_scroll_y()
	var view_bottom: float = view_top + host._skill_detail_surface()._detail_lazy_viewport_height()
	var visible_height := minf(rect.position.y + rect.size.y, view_bottom) - maxf(rect.position.y, view_top)
	return visible_height > 1.0


func _append_bonus_emphasis_entry(entries: Array, entry: Dictionary) -> void:
	var anchor := entry.get("anchor") as Control
	if not _is_bonus_emphasis_anchor_visible(anchor):
		return
	var rect := anchor.get_global_rect()
	entry["screen_y"] = rect.position.y
	entry["screen_x"] = rect.position.x
	entries.append(entry)


func _is_bonus_emphasis_anchor_visible(anchor: Control) -> bool:
	if anchor == null or not is_instance_valid(anchor) or not anchor.is_visible_in_tree():
		return false
	var rect := anchor.get_global_rect()
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		return false
	var visible_rect := _bonus_emphasis_visible_rect_for_anchor(anchor)
	if visible_rect.size.x <= 1.0 or visible_rect.size.y <= 1.0 or not rect.intersects(visible_rect):
		return false
	if _bonus_emphasis_rect_intersects_visible_overlay(rect):
		return false
	var clipped := rect.intersection(visible_rect)
	var visible_area := clipped.size.x * clipped.size.y
	var full_area := rect.size.x * rect.size.y
	return full_area > 0.0 and visible_area / full_area >= 0.82


func _bonus_emphasis_visible_rect_for_anchor(_anchor: Control) -> Rect2:
	var visible_rect := Rect2(Vector2.ZERO, host._current_canvas_size())
	if host.current_screen == "skill" and host._skill_detail_surface().detail_actions_scroll != null and is_instance_valid(host._skill_detail_surface().detail_actions_scroll) and host._skill_detail_surface().detail_actions_scroll.is_visible_in_tree():
		visible_rect = visible_rect.intersection(host._skill_detail_surface().detail_actions_scroll.get_global_rect())
	elif host.skills_page != null and is_instance_valid(host.skills_page) and host.skills_page.is_visible_in_tree():
		visible_rect = visible_rect.intersection(host.skills_page.get_global_rect())
	var chat_rect := _visible_control_global_rect(host._profile_chat_overlay_surface().chat_strip_control())
	if chat_rect.size.x > 1.0 and chat_rect.size.y > 1.0:
		var chat_cropped_end_y := minf(visible_rect.end.y, chat_rect.position.y)
		visible_rect.size.y = maxf(0.0, chat_cropped_end_y - visible_rect.position.y)
	var nav_rect := _visible_control_global_rect(host._navigation_shell().nav_bar)
	if nav_rect.size.x > 1.0 and nav_rect.size.y > 1.0:
		var nav_cropped_end_y := minf(visible_rect.end.y, nav_rect.position.y)
		visible_rect.size.y = maxf(0.0, nav_cropped_end_y - visible_rect.position.y)
	return visible_rect


func _bonus_emphasis_rect_intersects_visible_overlay(rect: Rect2) -> bool:
	var chat_rect := _visible_control_global_rect(host._profile_chat_overlay_surface().chat_strip_control())
	if chat_rect.size.x > 1.0 and chat_rect.size.y > 1.0 and rect.intersects(chat_rect):
		return true
	var nav_rect := _visible_control_global_rect(host._navigation_shell().nav_bar)
	if nav_rect.size.x > 1.0 and nav_rect.size.y > 1.0 and rect.intersects(nav_rect):
		return true
	return false


func _visible_control_global_rect(control: Control) -> Rect2:
	if control == null or not is_instance_valid(control) or not control.is_visible_in_tree():
		return Rect2()
	return control.get_global_rect()


func _play_visible_bonus_emphasis_entries(entries: Array) -> void:
	if entries.is_empty():
		return
	entries.sort_custom(Callable(self, "_sort_bonus_emphasis_entries"))
	var highlighted_card_delays := {}
	var entry_count := entries.size()
	for i in range(entry_count):
		var entry := entries[i] as Dictionary
		var delay := 0.0 if entry_count <= 1 else lerpf(0.0, BONUS_EMPHASIS_CASCADE_SECONDS, float(i) / float(entry_count - 1))
		_play_bonus_emphasis_entry(entry, delay, i)
		var card_key := str(entry.get("card_key", ""))
		if not card_key.is_empty() and not highlighted_card_delays.has(card_key):
			highlighted_card_delays[card_key] = delay
	for key in highlighted_card_delays.keys():
		if host.action_cards.has(key):
			_flash_action_bonus_bottom(host.action_cards[key] as Dictionary, float(highlighted_card_delays[key]))


func _sort_bonus_emphasis_entries(a: Dictionary, b: Dictionary) -> bool:
	var ay := float(a.get("screen_y", 0.0))
	var by := float(b.get("screen_y", 0.0))
	if absf(ay - by) > 1.0:
		return ay < by
	return float(a.get("screen_x", 0.0)) < float(b.get("screen_x", 0.0))


func _play_bonus_emphasis_entry(entry: Dictionary, delay: float, sequence_index := 0) -> void:
	var kind := str(entry.get("kind", ""))
	if kind == "action_stat":
		_emphasize_action_stat_bonus(entry.get("card", {}) as Dictionary, str(entry.get("stat_kind", "")), str(entry.get("text", "")), delay, sequence_index, str(entry.get("card_key", "")))
	elif kind == "stamina":
		var anchor := entry.get("anchor") as Control
		_flash_bonus_control(anchor, delay)
		_float_reward(host, anchor, str(entry.get("text", "")), int(entry.get("font_size", 66)), BONUS_EMPHASIS_FLOAT_COLOR, entry.get("start_offset", Vector2.ZERO), entry.get("rise", Vector2(0, -75)), delay)
	elif kind == "global_buff":
		_emphasize_global_buff_label(delay)


func _emphasize_action_stat_bonus(card: Dictionary, stat_kind: String, text: String, delay := 0.0, sequence_index := 0, card_key := "") -> void:
	if not _action_card_can_show_bonus_emphasis(card, card_key):
		return
	if delay > 0.0:
		var delayed_card_key := card_key
		if delayed_card_key.is_empty():
			delayed_card_key = _action_card_key_from_card(card)
		if delayed_card_key.is_empty():
			return
		var delayed_tween: Tween = host.create_tween()
		delayed_tween.tween_interval(delay)
		delayed_tween.tween_callback(_emphasize_action_stat_bonus_by_key.bind(delayed_card_key, stat_kind, text, sequence_index))
		return
	var boxes := card.get("stat_boxes", {}) as Dictionary
	var box := boxes.get(stat_kind) as Control
	if not _is_bonus_emphasis_anchor_visible(box):
		return
	if box.has_meta("normal_activity_stat_symbol"):
		host._skill_detail_surface()._wiggle_normal_activity_stat_symbol(box)
	else:
		_flash_bonus_control(box)
	_float_reward(host, box, text, 48, BONUS_EMPHASIS_FLOAT_COLOR, Vector2(0, -29), Vector2(0, -77), 0.0)
	host._audio_director()._play_info_chip_upgrade_sfx(sequence_index)


func _emphasize_action_stat_bonus_by_key(card_key: String, stat_kind: String, text: String, sequence_index := 0) -> void:
	if not host.action_cards.has(card_key):
		return
	var card := host.action_cards[card_key] as Dictionary
	if not _action_card_can_show_bonus_emphasis(card, card_key):
		return
	_emphasize_action_stat_bonus(card, stat_kind, text, 0.0, sequence_index, card_key)


func _action_card_key_from_card(card: Dictionary) -> String:
	var card_key := str(card.get("key", ""))
	if not card_key.is_empty():
		return card_key
	var skill_id := str(card.get("skill_id", ""))
	var action_id := str(card.get("action_id", ""))
	if skill_id.is_empty() or action_id.is_empty():
		return ""
	return host._action_key(skill_id, action_id)


func _emphasize_global_buff_label(delay := 0.0) -> void:
	var buff_label: Label = host._achievement_overlay_surface().global_buff_anchor()
	if buff_label == null or not is_instance_valid(buff_label) or not buff_label.is_visible_in_tree():
		return
	_flash_bonus_control(buff_label, delay)
	_float_reward(host, buff_label, "BUFF UP", 48, BONUS_EMPHASIS_FLOAT_COLOR, Vector2(0, -23), Vector2(0, -69), delay)


func _clear_action_crit_tweens() -> void:
	var had_crit_tweens = not action_crit_tweens.is_empty()
	for tween in action_crit_tweens.values():
		host._app_lifecycle_runtime()._kill_tween_value(tween)
	action_crit_tweens.clear()
	var group_nodes = []
	if host.is_inside_tree():
		var tree = host.get_tree()
		group_nodes = tree.get_nodes_in_group(ACTIVITY_CRIT_OVERLAY_GROUP)
		for node in group_nodes:
			if node != null and is_instance_valid(node):
				var canvas_item = node as CanvasItem
				if canvas_item != null:
					canvas_item.visible = false
				(node as Node).queue_free()
	if not had_crit_tweens and group_nodes.is_empty():
		return
	for node in host.find_children("ActivityCritHighlight", "Control", true, false):
		if node != null and is_instance_valid(node):
			(node as Control).visible = false
			(node as Control).queue_free()
	for node in host.find_children("ActivityCritText", "Control", true, false):
		if node != null and is_instance_valid(node):
			(node as Control).visible = false
			(node as Control).queue_free()

func _set_result(text: String, play_sfx = true) -> void:
	host.last_result = text
	if host.hero_message != null:
		host.hero_message.text = text.to_upper()
	if play_sfx:
		host.button_press_runtime.play_default_button_sfx()

func _play_action_feedback(key: String, success: bool, xp_amount: int, mastery_amount: float, xp_crit = false, mega_crit = false, xp_reward_map: Dictionary = {}, fish_reward_amount = 0.0) -> void:
	if not _skill_action_reward_feedback_visible():
		return
	var card = _reward_feedback_card_for_key(key)
	if card.is_empty():
		return
	var art_panel = host._app_lifecycle_runtime().valid_control_ref(card.get("art_panel"))
	var mastery_bar = host._app_lifecycle_runtime().valid_control_ref(card.get("mastery"))
	if art_panel == null:
		host._skill_detail_surface()._discard_action_card_key(key)
		return
	art_panel.pivot_offset = art_panel.size * 0.5
	if success:
		if xp_crit:
			_play_activity_crit_feedback(key, card, mega_crit)
		art_panel.modulate = Color.WHITE
		art_panel.scale = Vector2.ONE
		var pop = host.create_tween()
		pop.set_parallel(true)
		pop.tween_property(art_panel, "scale", Vector2(1.12, 1.12), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop.tween_property(art_panel, "modulate", Color.WHITE, 0.28)
		pop.chain().tween_property(art_panel, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if xp_reward_map.is_empty():
			_float_xp(host, art_panel, xp_amount)
		else:
			_float_xp_rewards(host, art_panel, xp_reward_map, _skill_id_from_action_key(key))
		if fish_reward_amount > 0.0:
			host._fishing_ui_surface()._float_fish_reward(host, art_panel, fish_reward_amount)
		_float_mastery_bar(host, mastery_bar, mastery_amount, _card_mastery_progress_percent(card))
	else:
		_flash_art_glow(art_panel, Color("#ff4f4f"))
		art_panel.modulate = Color("#ff8d8d")
		art_panel.rotation_degrees = 0.0
		var shake = host.create_tween()
		shake.tween_property(art_panel, "rotation_degrees", -5.0, 0.05)
		shake.tween_property(art_panel, "rotation_degrees", 5.0, 0.05)
		shake.tween_property(art_panel, "rotation_degrees", -4.0, 0.05)
		shake.tween_property(art_panel, "rotation_degrees", 3.0, 0.05)
		shake.tween_property(art_panel, "rotation_degrees", 0.0, 0.06)
		shake.parallel().tween_property(art_panel, "modulate", Color.WHITE, 0.26)
		_float_mastery_bar(host, mastery_bar, mastery_amount, _card_mastery_progress_percent(card))

func _play_action_mastery_feedback(key: String, mastery_amount: float) -> void:
	if mastery_amount <= 0.0:
		return
	if not _skill_action_reward_feedback_visible():
		return
	var card = _reward_feedback_card_for_key(key)
	if card.is_empty():
		return
	var mastery_bar = host._app_lifecycle_runtime().valid_control_ref(card.get("mastery"))
	if mastery_bar == null:
		return
	_float_mastery_bar(host, mastery_bar, mastery_amount, _card_mastery_progress_percent(card))

func _reward_feedback_card_for_key(key: String) -> Dictionary:
	var parts = key.split(":")
	if parts.size() >= 2 and host.current_screen == "menu":
		var visible_card = _visible_action_feedback_card(str(parts[0]), str(parts[1]))
		if not visible_card.is_empty():
			return visible_card
	if parts.size() >= 2 and host._fishing_rework_active_for_skill(str(parts[0])):
		var fishing_card = host._fishing_ui_surface()._fishing_method_card_for_action(str(parts[0]), str(parts[1]))
		if not fishing_card.is_empty() and _reward_feedback_card_has_live_target(fishing_card):
			return fishing_card
	if parts.size() >= 2:
		var default_visible_card = _visible_action_feedback_card(str(parts[0]), str(parts[1]))
		if not default_visible_card.is_empty():
			return default_visible_card
	if host.action_cards.has(key):
		var card = host.action_cards[key]
		if typeof(card) == TYPE_DICTIONARY:
			var card_dict = card as Dictionary
			if _reward_feedback_card_has_live_target(card_dict):
				return card_dict
			host._skill_detail_surface()._discard_action_card_key(key)
	return {}

func _visible_action_feedback_card(skill_id: String, action_id: String) -> Dictionary:
	if skill_id.is_empty() or action_id.is_empty():
		return {}
	if host.current_screen == "pinned":
		var pinned_key = host._navigation_shell()._pinned_page_card_key(ModuleUiRuntime.action_for_record(skill_id, host._action_data(skill_id, action_id), host.FISHING_ACTION_ID_ALIASES))
		var pinned_card = _live_action_card_for_key(pinned_key)
		if not pinned_card.is_empty():
			return pinned_card
	if host.current_screen == "queue":
		var queue_key = host._navigation_shell()._queue_page_card_key(ModuleUiRuntime.action_for_record(skill_id, host._action_data(skill_id, action_id), host.FISHING_ACTION_ID_ALIASES))
		var queue_card = _live_action_card_for_key(queue_key)
		if not queue_card.is_empty():
			return queue_card
	if host.current_screen == "menu":
		if host._fishing_rework_active_for_skill(skill_id):
			var fishing_method_card = host._fishing_ui_surface()._fishing_method_card_for_action(skill_id, action_id)
			if not fishing_method_card.is_empty() and _reward_feedback_card_has_live_target(fishing_method_card):
				return fishing_method_card
		var menu_key = host._navigation_shell()._skill_menu_active_drawer_card_key(skill_id, action_id)
		var menu_card = _live_action_card_for_key(menu_key)
		if not menu_card.is_empty():
			return menu_card
	return _live_action_card_for_key(host._action_key(skill_id, action_id))

func _live_action_card_for_key(card_key: String) -> Dictionary:
	if card_key.is_empty() or not host.action_cards.has(card_key):
		return {}
	var card = host.action_cards[card_key]
	if typeof(card) != TYPE_DICTIONARY:
		return {}
	var card_dict = card as Dictionary
	if _reward_feedback_card_has_live_target(card_dict):
		return card_dict
	host._skill_detail_surface()._discard_action_card_key(card_key)
	return {}

func _reward_feedback_card_has_live_target(card: Dictionary) -> bool:
	if card.is_empty():
		return false
	if host._skill_detail_surface()._action_card_has_live_anchor(card):
		return true
	if host._app_lifecycle_runtime().valid_control_ref(card.get("art_panel")) != null:
		return true
	if host._app_lifecycle_runtime().valid_control_ref(card.get("mastery")) != null:
		return true
	if host._app_lifecycle_runtime().valid_control_ref(card.get("progress")) != null:
		return true
	return false

func _skill_menu_card_side_gauge(card: Dictionary) -> Control:
	var fish_gauge := host._app_lifecycle_runtime().valid_control_ref(card.get("fish")) as Control
	if fish_gauge != null:
		return fish_gauge
	var health_gauge := host._app_lifecycle_runtime().valid_control_ref(card.get("health")) as Control
	if health_gauge != null:
		return health_gauge
	var stamina_gauge := host._app_lifecycle_runtime().valid_control_ref(card.get("stamina")) as Control
	if stamina_gauge != null:
		return stamina_gauge
	return null

func _skill_action_reward_feedback_visible() -> bool:
	return (host.current_screen == "skill" or host.current_screen == "menu" or host.current_screen == "pinned" or host.current_screen == "queue") and not host._input_routing_shell()._any_modal_overlay_visible()

func _clear_skill_reward_floats() -> void:
	for raw_node in host.get_tree().get_nodes_in_group(SKILL_REWARD_FLOAT_GROUP):
		var node = raw_node as Node
		if node == null or not is_instance_valid(node):
			continue
		host._app_lifecycle_runtime()._kill_meta_tween(node, "reward_float_tween")
		node.queue_free()

func _play_activity_crit_feedback(key: String, card: Dictionary, mega_crit = false) -> void:
	var pop_card = host._app_lifecycle_runtime().valid_control_ref(card.get("pop"))
	if pop_card == null:
		return
	if action_crit_tweens.has(key):
		host._app_lifecycle_runtime()._kill_tween_value(action_crit_tweens[key])
		if pop_card.has_meta("activity_crit_start_position"):
			pop_card.position = pop_card.get_meta("activity_crit_start_position")
		if pop_card.has_meta("activity_crit_start_scale"):
			pop_card.scale = pop_card.get_meta("activity_crit_start_scale")
	var old_highlight = host._app_lifecycle_runtime().state_object_ref(pop_card.get_meta("activity_crit_highlight_node")) as CanvasItem if pop_card.has_meta("activity_crit_highlight_node") else null
	if old_highlight == null:
		old_highlight = pop_card.get_node_or_null("ActivityCritHighlight")
	if old_highlight != null:
		_hide_and_queue_free_activity_crit_node(old_highlight)
		if pop_card.has_meta("activity_crit_highlight_node"):
			pop_card.remove_meta("activity_crit_highlight_node")
	var old_art_burst = host._app_lifecycle_runtime().state_object_ref(pop_card.get_meta("activity_crit_art_burst_node")) as TextureRect if pop_card.has_meta("activity_crit_art_burst_node") else null
	if old_art_burst == null:
		old_art_burst = pop_card.get_node_or_null("ActivityCritArtBurst")
	if old_art_burst != null:
		_hide_and_queue_free_activity_crit_node(old_art_burst)
		if pop_card.has_meta("activity_crit_art_burst_node"):
			pop_card.remove_meta("activity_crit_art_burst_node")
	var old_crit_text = host._app_lifecycle_runtime().valid_control_ref(pop_card.get_meta("activity_crit_text_node")) if pop_card.has_meta("activity_crit_text_node") else null
	if old_crit_text == null:
		old_crit_text = pop_card.get_node_or_null("ActivityCritText")
	if old_crit_text != null:
		_hide_and_queue_free_activity_crit_node(old_crit_text, "activity_crit_text_tween")
		if pop_card.has_meta("activity_crit_text_node"):
			pop_card.remove_meta("activity_crit_text_node")
	pop_card.pivot_offset = pop_card.size * 0.5
	pop_card.rotation_degrees = 0.0
	var start_position = pop_card.position
	var start_scale = pop_card.scale
	pop_card.set_meta("activity_crit_start_position", start_position)
	pop_card.set_meta("activity_crit_start_scale", start_scale)
	var highlight = Panel.new()
	var highlight_bleed = ACTIVITY_MEGA_CRIT_HIGHLIGHT_BLEED if mega_crit else 0.0
	highlight.name = "ActivityCritHighlight"
	highlight.size = pop_card.size + Vector2(highlight_bleed * 2.0, highlight_bleed * 2.0)
	highlight.pivot_offset = highlight.size * 0.5
	highlight.position = pop_card.global_position - Vector2(highlight_bleed, highlight_bleed)
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight.z_index = 560
	highlight.set_meta("activity_crit_highlight_bleed", highlight_bleed)
	var action := card.get("action", {}) as Dictionary
	var is_diamond_fight_card := str((action.get("combat", {}) as Dictionary).get("arena_shape", "")) == "diamond"
	highlight.add_theme_stylebox_override("panel", StyleBoxEmpty.new() if is_diamond_fight_card else ActivityCardStyles.crit_glow(mega_crit))
	highlight.add_to_group(ACTIVITY_CRIT_OVERLAY_GROUP)
	host.add_child(highlight)
	pop_card.set_meta("activity_crit_highlight_node", highlight)
	highlight.modulate = Color(1, 1, 1, 1.0)
	var art_burst: TextureRect = null
	if not is_diamond_fight_card:
		art_burst = _activity_crit_art_burst(card, pop_card, mega_crit)
	_activity_crit_text_burst(pop_card, mega_crit)
	var tween = host.create_tween()
	action_crit_tweens[key] = tween
	var feedback_seconds = ACTIVITY_MEGA_CRIT_FEEDBACK_SECONDS if mega_crit else ACTIVITY_CRIT_FEEDBACK_SECONDS
	var pop_card_id = pop_card.get_instance_id()
	var highlight_id = highlight.get_instance_id()
	var art_burst_id = art_burst.get_instance_id() if art_burst != null else 0
	tween.tween_method(_apply_activity_crit_feedback_frame_bound.bind(pop_card_id, start_position, start_scale, highlight_id, art_burst_id, mega_crit), 0.0, 1.0, feedback_seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_finish_activity_crit_feedback.bind(key, pop_card_id, start_position, start_scale, highlight_id, art_burst_id))

func _finish_activity_crit_feedback(key: String, pop_card_id: int, start_position: Vector2, start_scale: Vector2, highlight_id: int, art_burst_id: int) -> void:
	var callback_pop_card = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(pop_card_id))
	if callback_pop_card != null:
		callback_pop_card.position = start_position
		callback_pop_card.scale = start_scale
		callback_pop_card.remove_meta("activity_crit_start_position")
		callback_pop_card.remove_meta("activity_crit_start_scale")
		if callback_pop_card.has_meta("activity_crit_highlight_node"):
			callback_pop_card.remove_meta("activity_crit_highlight_node")
		if callback_pop_card.has_meta("activity_crit_art_burst_node"):
			callback_pop_card.remove_meta("activity_crit_art_burst_node")
	var callback_highlight = host._app_lifecycle_runtime().valid_canvas_item_ref(instance_from_id(highlight_id))
	if callback_highlight != null:
		_hide_and_queue_free_activity_crit_node(callback_highlight)
	var callback_art_burst = host._app_lifecycle_runtime().valid_texture_rect_ref(instance_from_id(art_burst_id)) if art_burst_id != 0 else null
	if callback_art_burst != null:
		_hide_and_queue_free_activity_crit_node(callback_art_burst)
	action_crit_tweens.erase(key)

func _activity_crit_art_burst(card: Dictionary, pop_card: Control, mega_crit = false) -> TextureRect:
	var art = host._app_lifecycle_runtime().state_object_ref(card.get("art")) as TextureRect
	if art == null or art.texture == null:
		return null
	var burst = TextureRect.new()
	burst.name = "ActivityCritArtBurst"
	burst.texture = art.texture
	burst.expand_mode = art.expand_mode
	burst.stretch_mode = art.stretch_mode
	burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	burst.z_index = 580
	var art_size = art.size
	if art_size.x <= 1.0 or art_size.y <= 1.0:
		art_size = art.custom_minimum_size
	burst.size = art_size
	burst.custom_minimum_size = art_size
	var local_position = art.global_position - pop_card.global_position
	burst.position = pop_card.global_position + local_position
	burst.pivot_offset = art_size * 0.5
	burst.scale = Vector2.ONE
	burst.modulate = Color(1.0, 1.0, 1.0, 1.0)
	var drift = Vector2(randf_range(-ACTIVITY_MEGA_CRIT_ART_DRIFT_PIXELS, ACTIVITY_MEGA_CRIT_ART_DRIFT_PIXELS), randf_range(-ACTIVITY_MEGA_CRIT_ART_DRIFT_PIXELS, ACTIVITY_MEGA_CRIT_ART_DRIFT_PIXELS)) if mega_crit else Vector2.ZERO
	burst.set_meta("activity_crit_art_local_position", local_position)
	burst.set_meta("activity_crit_art_drift", drift)
	burst.add_to_group(ACTIVITY_CRIT_OVERLAY_GROUP)
	host.add_child(burst)
	pop_card.set_meta("activity_crit_art_burst_node", burst)
	return burst

func _activity_crit_text_burst(pop_card: Control, mega_crit = false) -> Control:
	var holder = Control.new()
	holder.name = "ActivityCritText"
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.z_index = 620
	var text_size = ACTIVITY_MEGA_CRIT_TEXT_SIZE if mega_crit else ACTIVITY_CRIT_TEXT_SIZE
	holder.size = text_size
	holder.pivot_offset = text_size * 0.5
	var spawn_jitter = Vector2(randf_range(-17.0, 17.0), randf_range(-9.0, 9.0)) if mega_crit else Vector2(randf_range(-8.0, 8.0), randf_range(-4.0, 4.0))
	var start_position = pop_card.global_position + Vector2((pop_card.size.x - text_size.x) * 0.5, -text_size.y * 0.42) + spawn_jitter
	start_position = _clamp_reward_holder_position(host, start_position, text_size)
	holder.position = start_position
	holder.scale = Vector2(0.68, 0.68) if mega_crit else Vector2(0.78, 0.78)
	holder.rotation_degrees = randf_range(-8.0, 8.0) if mega_crit else randf_range(-3.5, 3.5)
	holder.modulate = Color(1, 1, 1, 0)
	holder.add_to_group(ACTIVITY_CRIT_OVERLAY_GROUP)
	host.add_child(holder)
	pop_card.set_meta("activity_crit_text_node", holder)
	var label_text = "MEGA CRIT!!!!" if mega_crit else "CRIT!!"
	var label_size = 52 if mega_crit else 64
	var label_color = ACTIVITY_MEGA_CRIT_TEXT_COLOR if mega_crit else ACTIVITY_CRIT_TEXT_COLOR
	var label = host._label(label_text, label_size, label_color, HORIZONTAL_ALIGNMENT_CENTER)
	label.size = text_size
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_outline_color", Color("#3b2300") if mega_crit else Color("#171615"))
	label.add_theme_constant_override("outline_size", 17 if mega_crit else 13)
	if host.app_bold_font != null:
		label.add_theme_font_override("font", host.app_bold_font)
	holder.add_child(label)
	var tween = host.create_tween()
	holder.set_meta("activity_crit_text_tween", tween)
	tween.set_parallel(true)
	var float_pixels = 155.0 if mega_crit else 115.0
	var float_seconds = 6.15 if mega_crit else 2.05
	var pop_seconds = 0.54 if mega_crit else 0.18
	var fade_in_seconds = 0.12 if mega_crit else 0.08
	var fade_delay = 4.50 if mega_crit else 1.50
	var fade_seconds = 1.65 if mega_crit else 0.55
	var peak_scale = Vector2(1.24, 1.24) if mega_crit else Vector2(1.08, 1.08)
	var quake_seconds = 0.48 if mega_crit else 0.18
	var quake_portion = clampf(quake_seconds / maxf(0.01, float_seconds), 0.02, 0.35)
	var start_rotation = holder.rotation_degrees
	var settle_rotation = randf_range(-5.5, 5.5) if mega_crit else randf_range(-1.5, 1.5)
	var motion_seed = randf() * 100.0
	var holder_id = holder.get_instance_id()
	tween.tween_method(_apply_activity_crit_text_frame.bind(holder_id, start_position, float_pixels, mega_crit, quake_portion, start_rotation, settle_rotation, motion_seed), 0.0, 1.0, float_seconds).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(holder, "scale", peak_scale, pop_seconds).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(holder, "modulate:a", 1.0, fade_in_seconds)
	tween.tween_property(holder, "modulate:a", 0.0, fade_seconds).set_delay(fade_delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(_finish_activity_crit_text_burst.bind(pop_card.get_instance_id(), holder_id))
	return holder

func _finish_activity_crit_text_burst(pop_card_id: int, holder_id: int) -> void:
	var callback_pop_card = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(pop_card_id))
	var callback_holder = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(holder_id))
	if callback_pop_card != null and callback_pop_card.get_meta("activity_crit_text_node", null) == callback_holder:
		callback_pop_card.remove_meta("activity_crit_text_node")
	if callback_holder != null:
		_hide_and_queue_free_activity_crit_node(callback_holder, "activity_crit_text_tween")

func _hide_and_queue_free_activity_crit_node(node: Node, tween_meta = "") -> void:
	if node == null or not is_instance_valid(node) or node.is_queued_for_deletion():
		return
	if not tween_meta.is_empty():
		host._app_lifecycle_runtime()._kill_meta_tween(node, tween_meta)
	if node is CanvasItem:
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(node as CanvasItem, false)
	node.queue_free()

func _apply_activity_crit_text_frame(progress: float, holder_id: int, start_position: Vector2, float_pixels: float, mega_crit: bool, quake_portion: float, start_rotation: float, settle_rotation: float, motion_seed: float) -> void:
	var holder = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(holder_id))
	if holder == null:
		return
	if progress < quake_portion:
		var quake_progress = clampf(progress / maxf(0.001, quake_portion), 0.0, 1.0)
		var quake_damping = pow(1.0 - quake_progress, 0.72)
		var quake_strength = (54.0 if mega_crit else 20.0) * quake_damping
		var quake_x = sin((quake_progress * 18.0 + motion_seed) * TAU) + sin((quake_progress * 43.0 + motion_seed * 0.31) * TAU) * 0.42
		var quake_y = cos((quake_progress * 23.0 + motion_seed * 0.67) * TAU) + sin((quake_progress * 37.0 + motion_seed * 0.19) * TAU) * 0.34
		holder.position = start_position + Vector2(quake_x, quake_y) * quake_strength
		holder.rotation_degrees = start_rotation + sin((quake_progress * 12.0 + motion_seed) * TAU) * (11.0 if mega_crit else 4.0) * quake_damping
		return
	var float_progress = clampf((progress - quake_portion) / maxf(0.001, 1.0 - quake_portion), 0.0, 1.0)
	var float_ease = 1.0 - pow(1.0 - float_progress, 3.0)
	var wobble = sin((float_progress * 2.4 + motion_seed * 0.13) * TAU) * (22.0 if mega_crit else 7.0) * pow(1.0 - float_progress, 1.45)
	holder.position = start_position + Vector2(wobble, -float_pixels * float_ease)
	var rotation_wobble = sin((float_progress * 1.8 + motion_seed * 0.29) * TAU) * (2.6 if mega_crit else 0.9) * (1.0 - float_progress)
	holder.rotation_degrees = lerpf(start_rotation * 0.22, settle_rotation, float_ease) + rotation_wobble

func _apply_activity_crit_feedback_frame_bound(progress: float, pop_card_id: int, start_position: Vector2, start_scale: Vector2, highlight_id: int, art_burst_id: int, mega_crit = false) -> void:
	var pop_card = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(pop_card_id))
	var highlight = host._app_lifecycle_runtime().valid_canvas_item_ref(instance_from_id(highlight_id))
	var art_burst = host._app_lifecycle_runtime().valid_texture_rect_ref(instance_from_id(art_burst_id)) if art_burst_id != 0 else null
	_apply_activity_crit_feedback_frame(progress, pop_card, start_position, start_scale, highlight, art_burst, mega_crit)

func _apply_activity_crit_feedback_frame(progress: float, pop_card: Control, start_position: Vector2, start_scale: Vector2, highlight: CanvasItem, art_burst: TextureRect, mega_crit = false) -> void:
	if pop_card == null or highlight == null or not is_instance_valid(pop_card) or not is_instance_valid(highlight):
		return
	var damping = 1.0 - progress
	var fast_start = pow(progress, 0.46)
	var shake_mult = ACTIVITY_MEGA_CRIT_SHAKE_MULT if mega_crit else 1.0
	var lift_mult = ACTIVITY_MEGA_CRIT_LIFT_MULT if mega_crit else 1.0
	var shake_wave = sin(fast_start * PI * (12.5 if mega_crit else 9.5)) * pow(damping, 1.08)
	var lift_wave = absf(sin(fast_start * PI * (5.0 if mega_crit else 4.0))) * pow(damping, 1.18)
	pop_card.position = start_position + Vector2(shake_wave * ACTIVITY_CRIT_SHAKE_PIXELS * shake_mult, -lift_wave * ACTIVITY_CRIT_LIFT_PIXELS * lift_mult)
	var scale_peak_progress = clampf(progress / 0.18, 0.0, 1.0)
	var scale_settle_progress = clampf((progress - 0.18) / 0.82, 0.0, 1.0)
	var card_scale_peak = ACTIVITY_MEGA_CRIT_CARD_SCALE_PEAK if mega_crit else ACTIVITY_CRIT_CARD_SCALE_PEAK
	var peak_scale = lerpf(1.0, card_scale_peak, 1.0 - pow(1.0 - scale_peak_progress, 2.4))
	var settle_scale = lerpf(card_scale_peak, 1.0, 1.0 - pow(1.0 - scale_settle_progress, 2.1))
	var current_card_scale = peak_scale if progress < 0.18 else settle_scale
	pop_card.scale = start_scale * current_card_scale
	if highlight is Control:
		var highlight_control = highlight as Control
		var highlight_bleed = float(highlight_control.get_meta("activity_crit_highlight_bleed", 0.0))
		highlight_control.position = pop_card.global_position - Vector2(highlight_bleed, highlight_bleed)
		highlight_control.scale = pop_card.scale
	var fade_progress = clampf((progress - 0.21) / 0.79, 0.0, 1.0)
	var fill_fade_progress = fade_progress
	var flash_pulse = sin(clampf(progress / 0.52, 0.0, 1.0) * PI)
	var linger_pulse = sin(clampf((progress - 0.34) / 0.52, 0.0, 1.0) * PI) * (0.54 if mega_crit else 0.34)
	var glow_alpha = clampf(lerpf(1.0, 0.0, fade_progress) + flash_pulse * (0.38 if mega_crit else 0.22) + linger_pulse, 0.0, 1.0)
	highlight.modulate.a = minf(glow_alpha, lerpf(1.0, 0.42, fill_fade_progress)) if mega_crit else glow_alpha
	if art_burst != null and is_instance_valid(art_burst):
		var art_local_variant = art_burst.get_meta("activity_crit_art_local_position", art_burst.position - pop_card.global_position)
		var art_local_position: Vector2 = art_local_variant if art_local_variant is Vector2 else art_burst.position - pop_card.global_position
		var art_drift_variant = art_burst.get_meta("activity_crit_art_drift", Vector2.ZERO)
		var art_drift: Vector2 = art_drift_variant if art_drift_variant is Vector2 else Vector2.ZERO
		var art_drift_progress = clampf(progress / 0.58, 0.0, 1.0)
		art_burst.position = pop_card.global_position + art_local_position + art_drift * (1.0 - pow(1.0 - art_drift_progress, 2.2))
		var peak_progress = clampf(progress / 0.22, 0.0, 1.0)
		var art_settle_progress = clampf((progress - 0.22) / 0.78, 0.0, 1.0)
		var art_burst_scale = ACTIVITY_MEGA_CRIT_ART_BURST_SCALE if mega_crit else ACTIVITY_CRIT_ART_BURST_SCALE
		var burst_scale = lerpf(1.0, art_burst_scale, 1.0 - pow(1.0 - peak_progress, 2.2))
		var art_settle_scale = lerpf(art_burst_scale, 1.0, 1.0 - pow(1.0 - art_settle_progress, 2.8))
		var current_scale = burst_scale if progress < 0.22 else art_settle_scale
		art_burst.scale = Vector2(current_scale, current_scale)
		art_burst.rotation_degrees = sin(fast_start * PI * (4.6 if mega_crit else 3.0)) * (15.0 if mega_crit else 8.5) * pow(damping, 0.85)
		var burst_color = Color(1.0, 0.93, 0.24, lerpf(1.0, 0.0, fade_progress)) if mega_crit else Color(0.78, 0.92, 1.0, lerpf(1.0, 0.0, fade_progress))
		art_burst.modulate = burst_color

func _flash_art_glow(anchor: Control, color: Color) -> void:
	var glow = Panel.new()
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.z_index = 80
	glow.add_theme_stylebox_override("panel", ActivityCardStyles.art_glow(color))
	anchor.add_child(glow)
	glow.modulate = Color(1, 1, 1, 0.95)
	var tween = host.create_tween()
	tween.tween_property(glow, "modulate:a", 0.0, 0.48).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(host._app_lifecycle_runtime()._queue_free_instance_id.bind(glow.get_instance_id()))

func _float_xp(parent: Control, anchor: Control, xp_amount: int) -> void:
	if xp_amount <= 0:
		return
	_float_reward(parent, anchor, "+%s XP" % xp_amount, 48, Color("#2ff06d"), Vector2(0, -43), Vector2(0, -115), 0.0, false, -1.0, SKILL_REWARD_FLOAT_GROUP)

func _float_xp_rewards(parent: Control, anchor: Control, reward_map: Dictionary, owner_skill_id = "") -> void:
	if reward_map.is_empty():
		return
	var ordered_skill_ids = host._action_runtime()._ordered_xp_reward_skill_ids(owner_skill_id, reward_map)
	var visible_count = 0
	for raw_skill_id in ordered_skill_ids:
		if int(reward_map.get(str(raw_skill_id), 0)) > 0:
			visible_count += 1
	if visible_count <= 0:
		return
	var visible_index = 0
	for raw_skill_id in ordered_skill_ids:
		var skill_id = str(raw_skill_id)
		var amount = maxi(0, int(reward_map.get(skill_id, 0)))
		if amount <= 0:
			continue
		var multi_reward = visible_count > 1
		var amount_text = GameFormatting.info_chip_number(float(amount))
		var text = "+%s XP" % amount_text
		var color = ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE).lerp(Color.WHITE, 0.12)
		var centered_index = float(visible_index) - float(visible_count - 1) * 0.5
		var side_offset = 0.0
		var lane_y = 0.0
		var delay = 0.0
		if multi_reward:
			side_offset = centered_index * SKILL_REWARD_FLOAT_MULTI_SPACING_X
			lane_y = float(visible_index) * SKILL_REWARD_FLOAT_MULTI_STACK_Y
			delay = float(visible_index) * SKILL_REWARD_FLOAT_MULTI_DELAY_SECONDS
		var start_offset = Vector2(side_offset, -43.0 - lane_y)
		var rise_offset = Vector2(side_offset * 0.16, -115.0 - lane_y * 0.9)
		_float_reward(parent, anchor, text, 48, color, start_offset, rise_offset, delay, false, -1.0, SKILL_REWARD_FLOAT_GROUP)
		visible_index += 1

func _skill_id_from_action_key(key: String) -> String:
	var parts = key.split(":")
	if parts.size() > 0:
		return str(parts[0])
	return host.selected_skill_id

func _float_mastery_bar(_parent: Control, _anchor: Control, _mastery_amount: float, _progress_pct = -1.0) -> void:
	pass

func _card_mastery_progress_percent(card: Dictionary) -> float:
	var skill_id = str(card.get("skill_id", ""))
	var action_id = str(card.get("mastery_action_id", card.get("action_id", "")))
	if skill_id.is_empty() or action_id.is_empty():
		return -1.0
	return MasteryState.progress_pct(host.mastery, host._action_key(skill_id, action_id), host.MASTERY_MAX_LEVEL)

func _float_tired_activity_feedback(action_key: String) -> void:
	_float_action_card_warning_feedback(action_key, TIRED_ACTIVITY_FLOAT_TEXT, TIRED_ACTIVITY_FLOAT_COLOR)

func _float_event_need_stamina_feedback(action_key: String, stamina_cost: float) -> void:
	var cost_text = GameFormatting.stamina_cost_detail(stamina_cost)
	_float_action_card_warning_feedback(action_key, EVENT_NEED_STAMINA_FLOAT_TEXT % cost_text, Color("#ffd95a"))

func _float_stamina_need_fish(source: Control = null) -> void:
	_float_stamina_gauge_feedback(source, "need fish!", Color("#ffd95a"))

func _float_stamina_full(source: Control = null) -> void:
	_float_stamina_gauge_feedback(source, "full", Color("#9ff7ff"))

func _float_stamina_gauge_feedback(source: Control, text: String, color: Color) -> void:
	var target: Control = source if source != null else host._skill_detail_surface().detail_regen_circle
	if target == null or not is_instance_valid(target) or not target.is_inside_tree():
		return
	_float_reward(
		host,
		target,
		text,
		58,
		color,
		Vector2(0, -24),
		Vector2(0, -75),
		0.0,
		false,
		-1.0,
		STAMINA_NEED_FISH_FLOAT_GROUP
	)

func _play_stamina_gauge_eat_fail(source: RegenCircle = null) -> void:
	var target: Control = source if source != null else host._skill_detail_surface().detail_regen_circle
	if target != null and is_instance_valid(target):
		_play_stamina_gauge_fail_shake(target)
	host._audio_director()._play_failure_sfx()

func _play_stamina_gauge_fail_shake(target: Control) -> void:
	if target == null or not is_instance_valid(target) or not target.has_method("play_fail_shake"):
		return
	target.call("play_fail_shake")

func _pop_stamina_gauge(source: RegenCircle = null) -> void:
	var target: RegenCircle = source if source != null else host._skill_detail_surface().detail_regen_circle
	if target == null or not is_instance_valid(target):
		return
	_clear_stamina_gauge_pop_tween()
	target.play_pop()

func _visible_stamina_gauge_for_skill(skill_id: String, fallback: RegenCircle = null) -> RegenCircle:
	if fallback != null and is_instance_valid(fallback) and fallback.is_inside_tree() and fallback.is_visible_in_tree():
		return fallback
	if host.current_screen == "menu" and host.skill_cards.has(skill_id):
		var card := host.skill_cards.get(skill_id, {}) as Dictionary
		var menu_gauge := card.get("stamina") as RegenCircle
		if menu_gauge != null and is_instance_valid(menu_gauge) and menu_gauge.is_inside_tree():
			return menu_gauge
	if host.current_screen == "skill" and host.selected_skill_id == skill_id and host._skill_detail_surface().detail_regen_circle != null and is_instance_valid(host._skill_detail_surface().detail_regen_circle):
		return host._skill_detail_surface().detail_regen_circle
	var navigation_shell = host._navigation_shell()
	if (host.current_screen == "pinned" or host.current_screen == "queue") and navigation_shell.pinned_active_shelf_skill_id == skill_id and navigation_shell.pinned_active_shelf_regen_circle != null and is_instance_valid(navigation_shell.pinned_active_shelf_regen_circle):
		return navigation_shell.pinned_active_shelf_regen_circle
	if (host.current_screen == "pinned" or host.current_screen == "queue") and navigation_shell.pinned_active_shelf_stamina_gauges.has(skill_id):
		var pinned_strip_gauge := navigation_shell.pinned_active_shelf_stamina_gauges.get(skill_id, null) as RegenCircle
		if pinned_strip_gauge != null and is_instance_valid(pinned_strip_gauge) and pinned_strip_gauge.is_inside_tree() and pinned_strip_gauge.is_visible_in_tree():
			return pinned_strip_gauge
	return host._skill_detail_surface().detail_regen_circle if host._skill_detail_surface().detail_regen_circle != null and is_instance_valid(host._skill_detail_surface().detail_regen_circle) else null

func _clear_stamina_gauge_pop_tween() -> void:
	if host._skill_detail_surface().detail_regen_circle != null and is_instance_valid(host._skill_detail_surface().detail_regen_circle):
		host._skill_detail_surface().detail_regen_circle.clear_pop_tween()
	if host._action_runtime().stamina_gauge_press_source != null and is_instance_valid(host._action_runtime().stamina_gauge_press_source):
		host._action_runtime().stamina_gauge_press_source.clear_pop_tween()
	var navigation_shell = host._navigation_shell()
	if navigation_shell.pinned_active_shelf_regen_circle != null and is_instance_valid(navigation_shell.pinned_active_shelf_regen_circle):
		navigation_shell.pinned_active_shelf_regen_circle.clear_pop_tween()
	for raw_gauge in navigation_shell.pinned_active_shelf_stamina_gauges.values():
		var pinned_strip_gauge := raw_gauge as RegenCircle
		if pinned_strip_gauge != null and is_instance_valid(pinned_strip_gauge):
			pinned_strip_gauge.clear_pop_tween()
	for raw_card in host.skill_cards.values():
		var card := raw_card as Dictionary
		var menu_gauge := card.get("stamina") as RegenCircle
		if menu_gauge != null and is_instance_valid(menu_gauge):
			menu_gauge.clear_pop_tween()

func _float_action_card_warning_feedback(action_key: String, text: String, color: Color) -> void:
	if not host.action_cards.has(action_key):
		return
	var card = host.action_cards[action_key] as Dictionary
	var progress = host._app_lifecycle_runtime().valid_control_ref(card.get("progress"))
	if progress == null or not progress.is_inside_tree():
		return
	var reward_size = Vector2(210, 84)
	var holder = Control.new()
	holder.z_index = REWARD_FLOAT_Z
	holder.z_as_relative = false
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.size = reward_size
	host.add_child(holder)
	var shadow = host._label(text, 58, host.COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	shadow.size = reward_size
	shadow.position = Vector2(3, 3.5)
	shadow.add_theme_constant_override("line_spacing", -6)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(shadow)
	var label = host._label(text, 58, color, HORIZONTAL_ALIGNMENT_CENTER)
	label.size = reward_size
	label.add_theme_constant_override("line_spacing", -6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(label)
	var local_pos = progress.global_position - host.global_position
	var left_bar_anchor = minf(110.0, maxf(64.0, progress.size.x * 0.12))
	holder.position = _clamp_reward_holder_position(
		host,
		local_pos + Vector2(left_bar_anchor - reward_size.x * 0.5, -reward_size.y * 0.5 - 22.0),
		reward_size
	)
	holder.modulate = Color(1, 1, 1, 0)
	holder.scale = Vector2(0.78, 0.78)
	var tween = host.create_tween()
	tween.set_parallel(true)
	tween.tween_property(holder, "position", holder.position + Vector2(0, -78), 1.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(holder, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(holder, "modulate:a", 1.0, 0.08)
	tween.tween_property(holder, "modulate:a", 0.0, 0.72).set_delay(0.50)
	tween.chain().tween_callback(host._app_lifecycle_runtime()._queue_free_instance_id.bind(holder.get_instance_id()))

func _show_visible_skill_level_up_float(skill_id: String) -> void:
	var xp_bar = _skill_level_up_float_bar(skill_id)
	if xp_bar == null:
		return
	_float_reward(
		host,
		xp_bar,
		tr("LEVEL UP!"),
		60,
		Color("#ffd238"),
		Vector2(0, -21),
		Vector2(0, -63),
		0.0,
		true,
		-1.0,
		SKILL_REWARD_FLOAT_GROUP
	)

func _skill_level_up_float_bar_visible(skill_id: String) -> bool:
	return _skill_level_up_float_bar(skill_id) != null

func _skill_level_up_float_bar(skill_id: String) -> CleanProgressBar:
	if (
		not host.startup_initialized
		or host.boot_detail_render_in_progress
		or host._navigation_shell().screen_render_in_progress
	):
		return null
	if host.current_screen == "skill":
		if host.selected_skill_id != skill_id or host._skill_swipe_activity_surface()._action_cards_hidden_by_transition_cover():
			return null
		return host._skill_detail_surface().detail_xp_bar if _level_up_float_bar_is_visible(host._skill_detail_surface().detail_xp_bar) else null
	if host.current_screen == "pinned":
		if (
			host._navigation_shell().pinned_active_shelf_skill_id != skill_id
			or host._navigation_shell().pinned_active_shelf_transition_active
			or host._skill_swipe_activity_surface()._action_cards_hidden_by_transition_cover()
		):
			return null
		var navigation_shell = host._navigation_shell()
		return navigation_shell.pinned_active_shelf_xp_bar if _level_up_float_bar_is_visible(navigation_shell.pinned_active_shelf_xp_bar) else null
	return null

func _level_up_float_bar_is_visible(xp_bar: CleanProgressBar) -> bool:
	return (
		xp_bar != null
		and is_instance_valid(xp_bar)
		and xp_bar.is_visible_in_tree()
		and xp_bar.size.x > 1.0
		and xp_bar.size.y > 1.0
	)

func _action_opportunity_window_is_visible(skill_id: String, action_id: String) -> bool:
	var rail = _visible_action_opportunity_rail(skill_id, action_id)
	if rail == null or not is_instance_valid(rail):
		return false
	return not rail.opportunity_windows.is_empty() and rail.opportunity_target_alpha > 0.0

func _play_action_opportunity_window_feedback(skill_id: String, action_id: String, success: bool, clicked_windows: Array[Vector2] = []) -> void:
	var rail = _visible_action_opportunity_rail(skill_id, action_id)
	if rail == null or not is_instance_valid(rail):
		return
	var feedback_windows := clicked_windows.duplicate()
	if feedback_windows.is_empty():
		feedback_windows = host._action_runtime()._action_opportunity_pattern_windows(skill_id, action_id)
	rail.play_opportunity_feedback(
		success,
		feedback_windows,
		false
	)
	host._audio_director()._play_action_opportunity_sfx(success)

func _float_action_opportunity_feedback(skill_id: String, action_id: String, text := "nice!", color := Color.TRANSPARENT) -> void:
	var rail = _visible_action_opportunity_rail(skill_id, action_id)
	if rail == null or not is_instance_valid(rail) or rail.is_queued_for_deletion() or not rail.is_inside_tree():
		return
	var reward_size := Vector2(150, 46)
	var holder := Control.new()
	holder.z_index = REWARD_FLOAT_Z
	holder.z_as_relative = false
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.size = reward_size
	host.add_child(holder)
	var text_color: Color = ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE).lightened(0.32) if color == Color.TRANSPARENT else color
	var shadow = host._label(text, 56, Color("#171615"), HORIZONTAL_ALIGNMENT_CENTER)
	shadow.size = reward_size
	shadow.position = Vector2(2, 2.5)
	shadow.modulate = Color(1, 1, 1, 0.52)
	holder.add_child(shadow)
	var label = host._label(text, 56, text_color, HORIZONTAL_ALIGNMENT_CENTER)
	label.size = reward_size
	holder.add_child(label)
	var start_center: Vector2 = host.get_global_transform_with_canvas().affine_inverse() * rail.get_opportunity_feedback_global_position(host.action_progress)
	start_center += Vector2(0, -29)
	holder.position = _clamp_reward_holder_position(host, start_center - reward_size * 0.5, reward_size)
	_start_reward_float_tween(holder, Vector2(0, -66), 0.0)

func _visible_action_opportunity_rail(skill_id: String, action_id: String) -> ActivityProgressRail:
	var card := _visible_action_feedback_card(skill_id, action_id)
	if card.is_empty():
		return null
	return card.get("progress") as ActivityProgressRail

func _float_reward(parent: Control, anchor: Control, text: String, font_size: int, color: Color, start_offset: Vector2, rise: Vector2, delay: float, at_right_end = false, anchor_x_override = -1.0, group_name = "") -> void:
	if (
		parent == null
		or anchor == null
		or not is_instance_valid(parent)
		or not is_instance_valid(anchor)
		or parent.is_queued_for_deletion()
		or anchor.is_queued_for_deletion()
	):
		return
	var reward_size = Vector2(280, 65)
	var holder = Control.new()
	holder.z_index = REWARD_FLOAT_Z
	holder.z_as_relative = false
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.size = reward_size
	if not group_name.is_empty():
		holder.add_to_group(group_name)
	var is_skill_reward_float = group_name == SKILL_REWARD_FLOAT_GROUP
	parent.add_child(holder)
	var shadow = host._label(text, font_size, Color("#171615"), HORIZONTAL_ALIGNMENT_CENTER)
	shadow.size = reward_size
	shadow.position = Vector2(1.5, 2) if is_skill_reward_float else Vector2(3, 3.5)
	shadow.modulate = Color(1, 1, 1, 0.34 if is_skill_reward_float else 0.58)
	holder.add_child(shadow)
	var label = host._label(text, font_size, color, HORIZONTAL_ALIGNMENT_CENTER)
	label.size = reward_size
	if is_skill_reward_float:
		label.add_theme_color_override("font_outline_color", host.COLOR_INK)
		label.add_theme_constant_override("outline_size", maxi(10, int(round(float(font_size) * 0.16))))
	holder.add_child(label)
	var local_pos = anchor.global_position - parent.global_position
	var anchor_x = anchor.size.x * 0.5 - reward_size.x * 0.5
	if anchor_x_override >= 0.0:
		anchor_x = clampf(anchor_x_override, 0.0, anchor.size.x) - reward_size.x * 0.5
	if at_right_end:
		anchor_x = anchor.size.x - reward_size.x * 0.5 - 16.0
	var desired_position = local_pos + Vector2(
		anchor_x,
		anchor.size.y * 0.18 - reward_size.y * 0.5
	) + start_offset
	holder.position = _clamp_reward_holder_position(parent, desired_position, reward_size)
	_start_reward_float_tween(holder, rise, delay)

func _start_reward_float_tween(holder: Control, rise: Vector2, delay: float) -> void:
	if holder == null or not is_instance_valid(holder) or holder.is_queued_for_deletion():
		return
	host._app_lifecycle_runtime().set_canvas_item_modulate_if_changed(holder, Color(1, 1, 1, 0))
	holder.scale = Vector2(0.82, 0.82)
	var tween = host.create_tween()
	tween.set_parallel(true)
	tween.tween_property(holder, "position", holder.position + rise, 1.25).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(holder, "scale", Vector2.ONE, 0.18).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(holder, "modulate:a", 1.0, 0.08).set_delay(delay)
	tween.tween_property(holder, "modulate:a", 0.0, 0.85).set_delay(delay + 0.55)
	holder.set_meta("reward_float_tween", tween)
	tween.chain().tween_callback(host._app_lifecycle_runtime()._queue_free_instance_id.bind(holder.get_instance_id()))
