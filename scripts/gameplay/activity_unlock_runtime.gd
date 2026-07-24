extends RefCounted

const ModuleUiRuntime = preload("res://scripts/module_ui/runtime.gd")
const ActivityLockRig = preload("res://scripts/ui/activity_lock_rig.gd")
const FishingState = preload("res://scripts/fishing/state.gd")

const LOCKED_ACTIVITY_PREVIEW_XP_THRESHOLD := 16

var host
var manual_activity_unlocks := {}
var manual_activity_requirement_unlocks := {}
var manual_activity_unlocks_trust_checked := false
var manual_activity_unlocks_trusted := true
var pending_activity_unlock_ceremony := {}


func _init(host_ref) -> void:
	host = host_ref


func merge_ready_ids(existing_ids: Variant, incoming_ids: Array) -> Array:
	var merged := []
	if typeof(existing_ids) == TYPE_ARRAY:
		for raw_action_id in existing_ids:
			var action_id := str(raw_action_id)
			if not action_id.is_empty() and not merged.has(action_id):
				merged.append(action_id)
	for raw_action_id in incoming_ids:
		var action_id := str(raw_action_id)
		if not action_id.is_empty() and not merged.has(action_id):
			merged.append(action_id)
	return merged


func pending_readiness_pages() -> Dictionary:
	var pages := {}
	if pending_activity_unlock_ceremony.is_empty():
		return pages
	var raw_pages = pending_activity_unlock_ceremony.get("pages", {})
	if typeof(raw_pages) == TYPE_DICTIONARY:
		var source_pages := raw_pages as Dictionary
		for raw_skill_id in source_pages.keys():
			var skill_id := str(raw_skill_id)
			var raw_entry = source_pages.get(raw_skill_id, {})
			if skill_id.is_empty() or typeof(raw_entry) != TYPE_DICTIONARY:
				continue
			var entry := raw_entry as Dictionary
			var ready_ids := entry.get("ready", []) as Array
			if not ready_ids.is_empty():
				pages[skill_id] = entry
		return pages
	var legacy_skill_id := str(pending_activity_unlock_ceremony.get("skill_id", ""))
	if not legacy_skill_id.is_empty():
		pages[legacy_skill_id] = pending_activity_unlock_ceremony
	return pages


func pending_readiness_for_skill(skill_id: String) -> Dictionary:
	if skill_id.is_empty():
		return {}
	var pages := pending_readiness_pages()
	var raw_entry = pages.get(skill_id, {})
	if typeof(raw_entry) == TYPE_DICTIONARY:
		return raw_entry as Dictionary
	return {}


func has_pending_readiness_for_skill(skill_id: String) -> bool:
	return not pending_readiness_for_skill(skill_id).is_empty()


func clear_pending_readiness_for_skill(skill_id: String) -> void:
	if skill_id.is_empty() or pending_activity_unlock_ceremony.is_empty():
		return
	var pages := pending_readiness_pages()
	pages.erase(skill_id)
	set_pending_readiness_pages(pages)


func clear_pending_readiness_action(skill_id: String, action_id: String) -> void:
	if skill_id.is_empty() or action_id.is_empty() or pending_activity_unlock_ceremony.is_empty():
		return
	var pages := pending_readiness_pages()
	var entry := pages.get(skill_id, {}) as Dictionary
	if entry.is_empty():
		return
	var ready_ids := []
	for raw_action_id in entry.get("ready", []) as Array:
		var ready_id := str(raw_action_id)
		if not ready_id.is_empty() and ready_id != action_id:
			ready_ids.append(ready_id)
	if ready_ids.is_empty():
		pages.erase(skill_id)
	else:
		entry["ready"] = ready_ids
		entry["applied"] = false
		pages[skill_id] = entry
	set_pending_readiness_pages(pages)


func mark_pending_readiness_applied(skill_id: String) -> void:
	if skill_id.is_empty() or pending_activity_unlock_ceremony.is_empty():
		return
	var pages := pending_readiness_pages()
	var entry := pages.get(skill_id, {}) as Dictionary
	if entry.is_empty():
		return
	entry["applied"] = true
	pages[skill_id] = entry
	set_pending_readiness_pages(pages)


func pending_readiness_action_ids(skill_id: String) -> Array:
	var entry := pending_readiness_for_skill(skill_id)
	if entry.is_empty():
		return []
	var ready_ids := entry.get("ready", []) as Array
	if ready_ids.is_empty():
		ready_ids = entry.get("unlocked", []) as Array
	return ready_ids


func set_pending_readiness_pages(pages: Dictionary) -> void:
	pending_activity_unlock_ceremony = {} if pages.is_empty() else {"pages": pages}


func _queue_activity_unlock_readiness(trigger_skill_id: String, old_level: int, new_level: int, ready_by_skill: Dictionary) -> void:
	if ready_by_skill.is_empty() or not host.startup_initialized:
		return
	if trigger_skill_id == host.TUTORIAL_STARTER_SKILL_ID and old_level < 2 and new_level >= 2:
		host._tutorial_overlay_surface().fade_out_onboarding_level_up_tip(host.ACTIVITY_PREVIEW_FADE_IN_SECONDS)
	ready_by_skill = _auto_unlock_nonvisible_ready_lockpads(ready_by_skill)
	if ready_by_skill.is_empty():
		return
	var pages := pending_readiness_pages()
	for raw_owner_skill_id in ready_by_skill.keys():
		var owner_skill_id := str(raw_owner_skill_id)
		if owner_skill_id.is_empty():
			continue
		var incoming_ready_ids := ready_by_skill.get(raw_owner_skill_id, []) as Array
		if incoming_ready_ids.is_empty():
			continue
		var entry := pages.get(owner_skill_id, {}) as Dictionary
		var merged_ready_ids := merge_ready_ids(entry.get("ready", []), incoming_ready_ids)
		if merged_ready_ids.is_empty():
			continue
		pages[owner_skill_id] = {
			"skill_id": owner_skill_id,
			"trigger_skill_id": trigger_skill_id,
			"old_level": old_level,
			"new_level": new_level,
			"ready": merged_ready_ids,
			"preview": str(entry.get("preview", "")),
		}
	if pages.is_empty():
		return
	set_pending_readiness_pages(pages)
	host._activity_unlock_ceremony_surface().detail_refresh_done = false
	host._activity_unlock_ceremony_surface().center_scroll_target = -1
	if host.auto_unlock_lockpads_enabled and not host._onboarding_runtime()._onboarding_path_active():
		call_deferred("_auto_unlock_pending_lockpads")
	if host.current_screen == "skill" and has_pending_readiness_for_skill(host.selected_skill_id):
		host.call_deferred("_update_ui", 0.0, false)


func _auto_unlock_nonvisible_ready_lockpads(ready_by_skill: Dictionary) -> Dictionary:
	if not host.auto_unlock_lockpads_enabled:
		return ready_by_skill
	if host._onboarding_runtime()._onboarding_path_active():
		return ready_by_skill
	var visible_ready_by_skill := {}
	for raw_owner_skill_id in ready_by_skill.keys():
		var owner_skill_id := str(raw_owner_skill_id)
		if owner_skill_id.is_empty():
			continue
		var incoming_ready_ids := ready_by_skill.get(raw_owner_skill_id, []) as Array
		var visible_ready_ids := []
		for raw_action_id in incoming_ready_ids:
			var action_id := str(raw_action_id)
			if action_id.is_empty():
				continue
			if host.current_screen == "skill" and owner_skill_id == host.selected_skill_id:
				visible_ready_ids.append(action_id)
			else:
				if not _auto_finalize_ready_lockpad(owner_skill_id, action_id):
					_auto_unlock_ready_requirement_lockpads_nonvisible(owner_skill_id, action_id)
		if not visible_ready_ids.is_empty():
			visible_ready_by_skill[owner_skill_id] = visible_ready_ids
	return visible_ready_by_skill


func _ready_lockpads_for_current_state() -> Dictionary:
	var ready_by_skill := {}
	for raw_owner_skill_id in host.actions_by_skill.keys():
		var owner_skill_id := str(raw_owner_skill_id)
		if owner_skill_id.is_empty():
			continue
		for raw_action in host.actions_by_skill.get(owner_skill_id, []) as Array:
			var action := raw_action as Dictionary
			var action_id := str(action.get("id", ""))
			if action_id.is_empty() or _is_action_unlocked(owner_skill_id, action):
				continue
			if not _can_unlock_action(owner_skill_id, action) and _first_ready_action_requirement_lock_index(owner_skill_id, action) < 0:
				continue
			var owner_ready_ids := ready_by_skill.get(owner_skill_id, []) as Array
			if not owner_ready_ids.has(action_id):
				owner_ready_ids.append(action_id)
			ready_by_skill[owner_skill_id] = owner_ready_ids
	return ready_by_skill


func _auto_unlock_retroactive_lockpads() -> void:
	if not host.auto_unlock_lockpads_enabled:
		return
	if host._onboarding_runtime()._onboarding_path_active():
		return
	var ready_by_skill := _ready_lockpads_for_current_state()
	if ready_by_skill.is_empty():
		return
	_queue_activity_unlock_readiness("", 0, 0, ready_by_skill)
	_auto_unlock_pending_lockpads()


func _run_startup_auto_unlock_lockpads() -> void:
	if not host.startup_initialized or not host.auto_unlock_lockpads_enabled:
		return
	if host._onboarding_runtime()._onboarding_path_active():
		return
	_auto_unlock_retroactive_lockpads()
	_auto_unlock_pending_lockpads()


func _auto_unlock_visible_pending_lockpads(skill_id: String) -> void:
	if not host.auto_unlock_lockpads_enabled:
		return
	if host._onboarding_runtime()._onboarding_path_active():
		return
	if host.current_screen != "skill" or skill_id != host.selected_skill_id:
		return
	if host._activity_unlock_ceremony_surface().ceremony_count > 0:
		return
	if host._fishing_rework_active_for_skill(skill_id):
		if _auto_unlock_visible_fishing_location_lockpad():
			return
	var readiness_action_ids := pending_readiness_action_ids(skill_id)
	if readiness_action_ids.is_empty():
		return
	for raw_action_id in readiness_action_ids:
		var action_id := str(raw_action_id)
		if action_id.is_empty():
			continue
		var action: Dictionary = host._action_data(skill_id, action_id)
		if action.is_empty():
			clear_pending_readiness_action(skill_id, action_id)
			continue
		if _is_action_unlocked(skill_id, action):
			clear_pending_readiness_action(skill_id, action_id)
			continue
		if not _can_unlock_action(skill_id, action):
			continue
		var card: Dictionary = host._skill_detail_surface()._resolve_activity_unlock_card(skill_id, action_id)
		if card.is_empty():
			if _auto_finalize_ready_lockpad(skill_id, action_id):
				clear_pending_readiness_action(skill_id, action_id)
				host.call_deferred("_refresh_skill_detail_after_activity_unlock_ceremony")
				return
			if _auto_unlock_ready_requirement_lockpads_nonvisible(skill_id, action_id):
				clear_pending_readiness_action(skill_id, action_id)
				host.call_deferred("_refresh_skill_detail_after_activity_unlock_ceremony")
				return
			continue
		if bool(card.get("unlock_ceremony_pending", false)) or bool(card.get("unlock_ceremony_active", false)):
			return
		if _auto_unlock_visible_activity_requirement_lock(card, skill_id, action):
			return
		if not _can_unlock_action(skill_id, action):
			clear_pending_readiness_action(skill_id, action_id)
			continue
		if bool(card.get("is_fishing_method", false)):
			host._fishing_ui_surface()._on_fishing_method_lock_pressed(skill_id, action_id)
		else:
			host._audio_director()._play_padlock_cluster_sfx()
			host._skill_detail_surface()._on_activity_lock_clicked(skill_id, action_id, null)
		return


func _auto_unlock_visible_fishing_location_lockpad() -> bool:
	if host.fishing_auto_unlock_waiting_for_detail_refresh:
		return true
	if not host._activity_unlock_ceremony_surface().preview_after_ceremony_id.is_empty():
		return true
	var action_id := _fishing_next_visible_auto_unlock_action_id()
	if action_id.is_empty():
		return false
	var action: Dictionary = host._action_data("fishing", action_id)
	if action.is_empty() or _is_action_unlocked("fishing", action) or not _can_unlock_action("fishing", action):
		return false
	var card: Dictionary = host._skill_detail_surface()._resolve_activity_unlock_card("fishing", action_id)
	if card.is_empty():
		return false
	if bool(card.get("unlock_ceremony_pending", false)) or bool(card.get("unlock_ceremony_active", false)):
		return true
	host.fishing_auto_unlock_waiting_for_detail_refresh = true
	host._fishing_ui_surface()._on_fishing_method_lock_pressed("fishing", action_id)
	return true


func _fishing_next_visible_auto_unlock_action_id() -> String:
	if host.selected_skill_id != "fishing":
		return ""
	var best_action_id := ""
	var best_unlock := 999999
	var best_render_order := 999999
	var render_order := 0
	for raw_area in host.fishing_runtime.area_definitions:
		var area_def := raw_area as Dictionary
		if not host.fishing_runtime.area_uses_location_tiles(area_def, FishingState.FISHING_LOCATION_DEFS):
			continue
		var area_id := str(area_def.get("id", ""))
		for raw_location in host.fishing_runtime.locations_for_area(area_id, FishingState.FISHING_LOCATION_DEFS):
			var location := raw_location as Dictionary
			if host.fishing_runtime.location_is_unlocked(host, area_id, location, FishingState.FISHING_LOCATION_DEFS, FishingState.FISHING_TOOL_LOCATION_ACTIONS):
				render_order += 1
				continue
			if not host.fishing_runtime.location_should_show(host, area_id, location, FishingState.FISHING_LOCATION_DEFS, FishingState.FISHING_TOOL_LOCATION_ACTIONS):
				render_order += 1
				continue
			var action_id: String = host.fishing_runtime.location_action_id(area_id, str(location.get("id", "")), FishingState.FISHING_TOOL_LOCATION_ACTIONS)
			if action_id.is_empty():
				render_order += 1
				continue
			var action: Dictionary = host._action_data("fishing", action_id)
			if action.is_empty() or not _can_unlock_action("fishing", action):
				render_order += 1
				continue
			var unlock_level := int(action.get("unlock", location.get("unlock", 1)))
			if unlock_level < best_unlock or (unlock_level == best_unlock and render_order < best_render_order):
				best_unlock = unlock_level
				best_render_order = render_order
				best_action_id = action_id
			render_order += 1
	return best_action_id


func _auto_unlock_pending_lockpads() -> void:
	if not host.auto_unlock_lockpads_enabled:
		return
	if host._onboarding_runtime()._onboarding_path_active():
		return
	var pages := pending_readiness_pages()
	for raw_skill_id in pages.keys():
		var skill_id := str(raw_skill_id)
		if skill_id.is_empty():
			continue
		if host.current_screen == "skill" and skill_id == host.selected_skill_id:
			continue
		var entry := pages.get(raw_skill_id, {}) as Dictionary
		for raw_action_id in entry.get("ready", []) as Array:
			var action_id := str(raw_action_id)
			if action_id.is_empty():
				continue
			var action: Dictionary = host._action_data(skill_id, action_id)
			if action.is_empty() or _is_action_unlocked(skill_id, action):
				clear_pending_readiness_action(skill_id, action_id)
				continue
			if _auto_finalize_ready_lockpad(skill_id, action_id) or _auto_unlock_ready_requirement_lockpads_nonvisible(skill_id, action_id):
				clear_pending_readiness_action(skill_id, action_id)
	if host.current_screen == "skill":
		_auto_unlock_visible_pending_lockpads(host.selected_skill_id)
		if host._activity_unlock_ceremony_surface().ceremony_count <= 0:
			_auto_cleanup_visible_pending_lockpads(host.selected_skill_id)
			_auto_unlock_visible_pending_lockpads(host.selected_skill_id)


func _auto_unlock_visible_activity_requirement_lock(card: Dictionary, skill_id: String, action: Dictionary) -> bool:
	if card.is_empty() or bool(card.get("is_fishing_method", false)):
		return false
	var action_id := str(action.get("id", ""))
	if action_id.is_empty() or _action_unlock_requirements(skill_id, action).size() <= 1:
		return false
	var requirement_index := _first_ready_action_requirement_lock_index(skill_id, action)
	if requirement_index < 0:
		return false
	var overlay := card.get("lock_overlay", {}) as Dictionary
	var group: Control = host._app_lifecycle_runtime().valid_control_ref(overlay.get("group"))
	if group == null:
		card.erase("lock_overlay_sync_key")
		host._skill_detail_surface()._sync_activity_lock_overlay(card, action, false)
		overlay = card.get("lock_overlay", {}) as Dictionary
		group = host._app_lifecycle_runtime().valid_control_ref(overlay.get("group"))
	if group == null or not group.has_method("play_requirement_unlock_drop_animation"):
		return false
	if group.has_method("consume_unlock_click"):
		group.call("consume_unlock_click")
	host._activity_unlock_ceremony_surface().detail_refresh_done = false
	host._activity_unlock_ceremony_surface().center_scroll_target = -1
	var final_requirement_unlock: bool = host._skill_detail_surface()._action_requirement_unlocks_complete_after(skill_id, action, requirement_index)
	if final_requirement_unlock:
		clear_pending_readiness_action(skill_id, action_id)
		var preview_after_unlock: String = host._onboarding_runtime()._tutorial_preview_after_manual_unlock(skill_id, action_id)
		host._activity_unlock_ceremony_surface().set_preview_after_ceremony(preview_after_unlock)
		host._activity_unlock_ceremony_surface().heist_preview_after_ceremony_id = host.thieving_state.heist_revealed_by_action_unlock(skill_id, action)
		if host._activity_unlock_ceremony_surface().heist_preview_after_ceremony_id.is_empty() and not host._activity_unlock_ceremony_surface().preview_after_ceremony_id.is_empty():
			host._activity_unlock_ceremony_surface().prestage_preview_card(host._activity_unlock_ceremony_surface().preview_after_ceremony_id)
	host._audio_director()._play_padlock_cluster_sfx()
	host._skill_detail_surface()._play_activity_requirement_lock_dismissal(card, skill_id, action, requirement_index, group, final_requirement_unlock)
	if not final_requirement_unlock:
		if _first_ready_action_requirement_lock_index(skill_id, action) < 0 and not _can_unlock_action(skill_id, action):
			clear_pending_readiness_action(skill_id, action_id)
		else:
			_schedule_auto_unlock_pending_lockpads_after_delay(ActivityLockRig.UNLOCK_DROP_SECONDS + 0.08)
	return true


func _auto_cleanup_visible_pending_lockpads(skill_id: String) -> void:
	if skill_id.is_empty() or pending_readiness_pages().is_empty():
		return
	for raw_action_id in pending_readiness_action_ids(skill_id).duplicate():
		var action_id := str(raw_action_id)
		if action_id.is_empty():
			continue
		var action: Dictionary = host._action_data(skill_id, action_id)
		if action.is_empty() or _is_action_unlocked(skill_id, action):
			clear_pending_readiness_action(skill_id, action_id)
			continue
		if _can_unlock_action(skill_id, action):
			continue
		if _first_ready_action_requirement_lock_index(skill_id, action) >= 0:
			_auto_unlock_ready_requirement_lockpads_nonvisible(skill_id, action_id)
		clear_pending_readiness_action(skill_id, action_id)


func _schedule_auto_unlock_pending_lockpads_after_delay(delay_seconds: float) -> void:
	await host.get_tree().create_timer(maxf(0.0, delay_seconds)).timeout
	_schedule_auto_unlock_pending_lockpads()


func _schedule_auto_unlock_pending_lockpads() -> void:
	if not host.auto_unlock_lockpads_enabled or pending_readiness_pages().is_empty():
		return
	if host._onboarding_runtime()._onboarding_path_active():
		return
	call_deferred("_auto_unlock_pending_lockpads")


func _auto_finalize_ready_lockpad(skill_id: String, action_id: String) -> bool:
	var action: Dictionary = host._action_data(skill_id, action_id)
	if action.is_empty() or _is_action_unlocked(skill_id, action) or not _can_unlock_action(skill_id, action):
		return false
	if host.current_screen == "skill" and host.selected_skill_id == skill_id and host._fishing_rework_active_for_skill(skill_id):
		var preview_after_unlock: String = host.fishing_runtime.first_locked_location_action_after_manual_unlock(host, action_id, "", host.fishing_runtime.FISHING_LOCATION_DEFS, host.fishing_runtime.FISHING_TOOL_LOCATION_ACTIONS)
		if not preview_after_unlock.is_empty():
			host._activity_unlock_ceremony_surface().clear_preview_reveal_guards()
		host._activity_unlock_ceremony_surface().set_preview_after_ceremony(preview_after_unlock)
		if not preview_after_unlock.is_empty():
			host._activity_unlock_ceremony_surface().prestage_preview_card(preview_after_unlock)
	var finalized := _finalize_manual_activity_unlock(skill_id, action_id, _auto_unlock_lockpad_save_reason(skill_id))
	if finalized:
		host._request_current_skill_detail_unlock_refresh(skill_id)
	return finalized


func _auto_unlock_lockpad_save_reason(skill_id: String) -> String:
	return "fishing method unlock" if host._fishing_rework_active_for_skill(skill_id) else "activity unlock"


func _first_ready_action_requirement_lock_index(skill_id: String, action: Dictionary) -> int:
	if _action_unlock_requirements(skill_id, action).size() <= 1:
		return -1
	var states := _action_requirement_states(skill_id, action)
	for index in range(states.size()):
		var state := states[index] as Dictionary
		if bool(state.get("met", false)) and not bool(state.get("dismissed", false)):
			return index
	return -1


func _auto_unlock_ready_requirement_lockpads_nonvisible(skill_id: String, action_id: String) -> bool:
	var action: Dictionary = host._action_data(skill_id, action_id)
	if action.is_empty() or _is_action_unlocked(skill_id, action):
		return false
	var changed := false
	while true:
		var requirement_index := _first_ready_action_requirement_lock_index(skill_id, action)
		if requirement_index < 0:
			break
		var final_requirement_unlock: bool = host._skill_detail_surface()._action_requirement_unlocks_complete_after(skill_id, action, requirement_index)
		if _mark_activity_requirement_manually_unlocked(skill_id, action, requirement_index):
			changed = true
		if final_requirement_unlock:
			_finalize_manual_activity_unlock(skill_id, action_id, _auto_unlock_lockpad_save_reason(skill_id))
			return true
	if changed:
		host._mark_save_dirty("activity requirement unlock")
	return changed


func _ready_actions_for_level_gain(skill_id: String, old_level: int, new_level: int) -> Dictionary:
	var ready_by_skill := {}
	if new_level <= old_level:
		return ready_by_skill
	for raw_owner_skill_id in host.actions_by_skill.keys():
		var owner_skill_id := str(raw_owner_skill_id)
		for raw_action in host.actions_by_skill.get(owner_skill_id, []):
			var action := raw_action as Dictionary
			if action.is_empty():
				continue
			var action_id := str(action.get("id", ""))
			if action_id.is_empty():
				continue
			if _is_action_unlocked(owner_skill_id, action):
				continue
			if not _action_requirements_crossed_by_level_gain(skill_id, owner_skill_id, action, old_level, new_level):
				continue
			if not _can_unlock_action(owner_skill_id, action):
				continue
			var owner_ready_ids := ready_by_skill.get(owner_skill_id, []) as Array
			if not owner_ready_ids.has(action_id):
				owner_ready_ids.append(action_id)
			ready_by_skill[owner_skill_id] = owner_ready_ids
	return ready_by_skill


func _action_requirements_crossed_by_level_gain(skill_id: String, owner_skill_id: String, action: Dictionary, old_level: int, new_level: int) -> bool:
	if new_level <= old_level:
		return false
	for raw_requirement in _action_unlock_requirements(owner_skill_id, action):
		if typeof(raw_requirement) != TYPE_DICTIONARY:
			continue
		var requirement := raw_requirement as Dictionary
		if str(requirement.get("skill", "")) != skill_id:
			continue
		var requirement_level := int(requirement.get("level", 1))
		if requirement_level > old_level and requirement_level <= new_level:
			return true
	return false


func _action_has_pending_unlock_readiness(action_id: String) -> bool:
	if action_id.is_empty() or not pending_readiness_action_ids(host.selected_skill_id).has(action_id):
		return false
	var action: Dictionary = host._action_data(host.selected_skill_id, action_id)
	if not action.is_empty() and _is_action_unlocked(host.selected_skill_id, action):
		clear_pending_readiness_action(host.selected_skill_id, action_id)
		host._mark_save_dirty("activity unlock cleanup")
		return false
	return true


func _action_matches_pending_unlock_preview(action_id: String) -> bool:
	var entry := pending_readiness_for_skill(host.selected_skill_id)
	return not entry.is_empty() and str(entry.get("preview", "")) == action_id


func _is_action_unlocked(skill_id: String, action: Dictionary) -> bool:
	if host._is_event_action(action):
		var event_action_id := str(action.get("id", ""))
		return not event_action_id.is_empty() and host._temporary_event_runtime()._temporary_event_is_active(event_action_id)
	if not host._fighting_runtime().action_boss_requirements_met(action):
		return false
	var requirements := _action_unlock_requirements(skill_id, action)
	if _action_requirements_max_level(requirements) <= 1:
		return _action_requirements_met_from_requirements(requirements)
	if host._fighting_runtime().action_uses_rooster_punch_out_stage(action):
		return _action_requirements_met_from_requirements(requirements)
	var action_id := str(action.get("id", ""))
	if action_id.is_empty():
		return false
	if host._passive_modules_runtime().is_passive_action(action):
		return _manual_activity_unlock_flag_is_trusted(skill_id, action_id) and _can_unlock_action(skill_id, action)
	return _manual_activity_unlock_flag_is_trusted(skill_id, action_id) and _can_unlock_action(skill_id, action)


func _visible_actions_for_skill(skill_id: String) -> Array:
	var visible_actions := []
	var mono_lock_blocker_seen := false
	for action in host.actions_by_skill.get(skill_id, []):
		var action_data := action as Dictionary
		if action_data.is_empty():
			continue
		if host._onboarding_runtime()._tutorial_should_defer_action_until_skill_swipe(skill_id, action_data):
			if not ModuleUiRuntime.action_is_combo_module(skill_id, action_data, Callable(self, "_action_unlock_requirements")):
				mono_lock_blocker_seen = true
			continue
		if not _is_action_unlocked(skill_id, action_data):
			if mono_lock_blocker_seen:
				continue
			if not ModuleUiRuntime.action_is_combo_module(skill_id, action_data, Callable(self, "_action_unlock_requirements")):
				mono_lock_blocker_seen = true
		visible_actions.append(action)
	return visible_actions


func _locked_activity_preview_available() -> bool:
	for raw_skill_id in host.skills.keys():
		var skill_id := str(raw_skill_id)
		if int(host.skills.get(skill_id, {}).get("xp", 0)) >= LOCKED_ACTIVITY_PREVIEW_XP_THRESHOLD:
			return true
	return false


func _first_locked_action_id(skill_id: String) -> String:
	for action in host.actions_by_skill.get(skill_id, []):
		var action_data := action as Dictionary
		if not _is_action_unlocked(skill_id, action_data) and _action_blocks_owner_skill_progression(skill_id, action_data):
			return str(action.get("id", ""))
	return ""


func _first_locked_action_id_after_manual_unlock(skill_id: String, unlocked_action_id: String) -> String:
	var passed_unlocked_action := false
	for action in host.actions_by_skill.get(skill_id, []):
		var action_data := action as Dictionary
		var action_id := str(action_data.get("id", ""))
		if action_id == unlocked_action_id:
			passed_unlocked_action = true
			continue
		if not passed_unlocked_action:
			continue
		if host._onboarding_runtime()._tutorial_should_defer_action_until_skill_swipe(skill_id, action_data):
			continue
		if not _is_action_unlocked(skill_id, action_data):
			return action_id
	for action in host.actions_by_skill.get(skill_id, []):
		var action_data := action as Dictionary
		var action_id := str(action_data.get("id", ""))
		if action_id == unlocked_action_id:
			continue
		if not _is_action_unlocked(skill_id, action_data) and _action_blocks_owner_skill_progression(skill_id, action_data):
			return action_id
	return ""


func _preview_after_manual_activity_unlock(skill_id: String, unlocked_action_id: String) -> String:
	var preview_id: String = host._onboarding_runtime()._tutorial_preview_after_manual_unlock(skill_id, unlocked_action_id)
	return preview_id if not preview_id.is_empty() else _first_locked_action_id_after_manual_unlock(skill_id, unlocked_action_id)


func _action_blocks_owner_skill_progression(skill_id: String, action: Dictionary) -> bool:
	if action.is_empty():
		return false
	if ModuleUiRuntime.action_is_combo_module(skill_id, action, Callable(self, "_action_unlock_requirements")):
		return false
	var requirements := _action_unlock_requirements(skill_id, action)
	var has_owner_requirement := false
	for raw_requirement in requirements:
		if typeof(raw_requirement) != TYPE_DICTIONARY:
			continue
		var requirement := raw_requirement as Dictionary
		if str(requirement.get("skill", skill_id)) != skill_id:
			continue
		has_owner_requirement = true
		if not _requirement_met(requirement):
			return true
	if not has_owner_requirement:
		return false
	if _action_requirements_met_from_requirements(requirements):
		return not _is_action_unlocked(skill_id, action)
	return false


func _manual_activity_unlock_flag_is_trusted(skill_id: String, action_id: String) -> bool:
	if not bool(manual_activity_unlocks.get(host._action_key(skill_id, action_id), false)):
		return false
	return _manual_activity_unlocks_are_trusted()


func _manual_activity_unlocks_are_trusted() -> bool:
	if manual_activity_unlocks_trust_checked:
		return manual_activity_unlocks_trusted
	manual_activity_unlocks_trust_checked = true
	manual_activity_unlocks_trusted = not _manual_activity_unlocks_have_bulk_corruption()
	return manual_activity_unlocks_trusted


func _invalidate_manual_activity_unlock_trust() -> void:
	manual_activity_unlocks_trust_checked = false
	manual_activity_unlocks_trusted = true


func _manual_activity_unlocks_have_bulk_corruption() -> bool:
	var manual_count := 0
	var impossible_count := 0
	for raw_key in manual_activity_unlocks.keys():
		if not bool(manual_activity_unlocks.get(raw_key, false)):
			continue
		manual_count += 1
		var action_ref: Dictionary = host._save_runtime()._action_ref_from_key(_canonical_manual_activity_unlock_key(str(raw_key)))
		if action_ref.is_empty():
			continue
		var skill_id := str(action_ref.get("skill_id", ""))
		var action := action_ref.get("action", {}) as Dictionary
		if not _action_requirements_met(skill_id, action):
			impossible_count += 1
	if manual_count < 50:
		return false
	return impossible_count >= maxi(12, int(float(manual_count) * 0.45))


func _repair_runtime_manual_activity_unlock_trust() -> void:
	if _manual_activity_unlocks_are_trusted():
		return
	var repaired := {}
	for raw_key in manual_activity_unlocks.keys():
		if not bool(manual_activity_unlocks.get(raw_key, false)):
			continue
		var key := _canonical_manual_activity_unlock_key(str(raw_key))
		if key.is_empty():
			continue
		var action_ref: Dictionary = host._save_runtime()._action_ref_from_key(key)
		if action_ref.is_empty():
			continue
		var skill_id := str(action_ref.get("skill_id", ""))
		var action := action_ref.get("action", {}) as Dictionary
		if _action_requirements_met(skill_id, action):
			repaired[key] = true
	manual_activity_unlocks = repaired
	manual_activity_unlocks_trust_checked = true
	manual_activity_unlocks_trusted = true


func _action_unlock_requirements(owner_skill_id: String, action: Dictionary) -> Array:
	var normalized := []
	var raw_requirements = action.get("requirements", [])
	if typeof(raw_requirements) == TYPE_ARRAY:
		for raw_requirement in raw_requirements:
			if typeof(raw_requirement) != TYPE_DICTIONARY:
				continue
			var requirement := raw_requirement as Dictionary
			var requirement_skill := str(requirement.get("skill", requirement.get("skill_id", owner_skill_id))).strip_edges()
			if requirement_skill.is_empty():
				requirement_skill = owner_skill_id
			normalized.append({
				"skill": requirement_skill,
				"level": maxi(1, int(requirement.get("level", requirement.get("unlock", action.get("unlock", 1)))))
			})
	if normalized.is_empty():
		normalized.append({
			"skill": owner_skill_id,
			"level": maxi(1, int(action.get("unlock", 1)))
		})
	return normalized


func _requirement_met(requirement: Dictionary) -> bool:
	var skill_id := str(requirement.get("skill", ""))
	if skill_id.is_empty():
		return false
	return SkillState.host_skill_level(host, skill_id) >= int(requirement.get("level", 1))


func _action_requirement_states(owner_skill_id: String, action: Dictionary) -> Array:
	var states := []
	for raw_requirement in _action_unlock_requirements(owner_skill_id, action):
		if typeof(raw_requirement) != TYPE_DICTIONARY:
			continue
		var requirement := raw_requirement as Dictionary
		var requirement_skill := str(requirement.get("skill", ""))
		var required_level := maxi(1, int(requirement.get("level", 1)))
		var current_level = SkillState.host_skill_level(host, requirement_skill) if not requirement_skill.is_empty() else 0
		var requirement_index := states.size()
		states.append({
			"skill": requirement_skill,
			"level": required_level,
			"current_level": current_level,
			"met": current_level >= required_level,
			"dismissed": _action_requirement_manually_unlocked(owner_skill_id, action, requirement_index)
		})
	return states


func _action_requirements_met(owner_skill_id: String, action: Dictionary) -> bool:
	return _action_requirements_met_from_requirements(_action_unlock_requirements(owner_skill_id, action))


func _action_requirements_met_from_requirements(requirements: Array) -> bool:
	if requirements.is_empty():
		return true
	for raw_requirement in requirements:
		if typeof(raw_requirement) != TYPE_DICTIONARY:
			return false
		if not _requirement_met(raw_requirement as Dictionary):
			return false
	return true


func _action_requirements_max_level(requirements: Array) -> int:
	var max_level := 1
	for raw_requirement in requirements:
		if typeof(raw_requirement) != TYPE_DICTIONARY:
			continue
		max_level = maxi(max_level, int((raw_requirement as Dictionary).get("level", 1)))
	return max_level


func _action_lock_cluster_state(owner_skill_id: String, action: Dictionary) -> Dictionary:
	var states := _action_requirement_states(owner_skill_id, action)
	var ready_count := 0
	var unmet := []
	for raw_state in states:
		if typeof(raw_state) != TYPE_DICTIONARY:
			continue
		var state := raw_state as Dictionary
		if bool(state.get("met", false)):
			ready_count += 1
		else:
			unmet.append(state)
	return {
		"requirements": states,
		"unmet": unmet,
		"ready_count": ready_count,
		"total": states.size(),
		"all_met": unmet.is_empty(),
		"max_level": _action_requirements_max_level(states)
	}


func _can_unlock_action(skill_id: String, action: Dictionary) -> bool:
	return _action_requirements_met(skill_id, action) and host._fighting_runtime().action_boss_requirements_met(action)


func sync_manual_activity_unlocks_from_levels() -> void:
	_sync_manual_activity_unlocks_from_levels_matching(false)


func sync_legacy_manual_activity_unlocks_from_levels() -> void:
	_sync_manual_activity_unlocks_from_levels_matching(true)


func _sync_manual_activity_unlocks_from_levels_matching(legacy_single_skill_only: bool) -> void:
	for raw_skill_id in host.skills.keys():
		var skill_id := str(raw_skill_id)
		for raw_action in host.actions_by_skill.get(skill_id, []):
			var action := raw_action as Dictionary
			var action_id := str(action.get("id", ""))
			if action_id.is_empty() or int(action.get("unlock", 1)) <= 1:
				continue
			if host._passive_modules_runtime().is_passive_action(action):
				continue
			if legacy_single_skill_only and not _action_uses_legacy_single_skill_requirement(skill_id, action):
				continue
			if _can_unlock_action(skill_id, action):
				_mark_action_manually_unlocked(skill_id, action_id)


func _action_uses_legacy_single_skill_requirement(skill_id: String, action: Dictionary) -> bool:
	var requirements := _action_unlock_requirements(skill_id, action)
	if requirements.size() != 1:
		return false
	var requirement := requirements[0] as Dictionary
	return (
		str(requirement.get("skill", skill_id)) == skill_id
		and int(requirement.get("level", action.get("unlock", 1))) == int(action.get("unlock", 1))
	)


func _mark_action_manually_unlocked(skill_id: String, action_id: String) -> void:
	var key := _canonical_manual_activity_unlock_key(host._action_key(skill_id, action_id))
	if not key.is_empty():
		_repair_runtime_manual_activity_unlock_trust()
		manual_activity_unlocks[key] = true
		_clear_activity_requirement_manual_unlocks(skill_id, action_id)
		manual_activity_unlocks_trust_checked = true
		manual_activity_unlocks_trusted = true


func _queue_manual_activity_unlock_for_ceremony(card: Dictionary, skill_id: String, action_id: String) -> void:
	if card.is_empty() or skill_id.is_empty() or action_id.is_empty():
		return
	card["manual_unlock_pending_skill_id"] = skill_id
	card["manual_unlock_pending_action_id"] = action_id


func _finalize_manual_activity_unlock(skill_id: String, action_id: String, save_reason := "activity unlock") -> bool:
	if skill_id.is_empty() or action_id.is_empty():
		return false
	_mark_action_manually_unlocked(skill_id, action_id)
	if host.current_screen == "skill" and host._fishing_rework_active_for_skill(skill_id) and host.selected_skill_id == skill_id:
		host._fishing_ui_surface()._queue_fishing_unlock_visible_mount(action_id)
		host._skill_detail_surface()._ensure_detail_lazy_entry_mounted(action_id)
		var next_fishing_preview_id: String = host.fishing_runtime.first_locked_location_action_after_manual_unlock(host, action_id, "", host.fishing_runtime.FISHING_LOCATION_DEFS, host.fishing_runtime.FISHING_TOOL_LOCATION_ACTIONS)
		if not next_fishing_preview_id.is_empty():
			host._skill_detail_surface()._ensure_detail_lazy_entry_mounted(next_fishing_preview_id)
	host._passive_modules_runtime().sync_passive_module_unlocks(host._unix_now())
	host._mark_save_dirty(save_reason)
	return true


func _finalize_manual_activity_unlock_for_card(card: Dictionary, save_reason := "activity unlock") -> bool:
	if card.is_empty():
		return false
	var skill_id := str(card.get("manual_unlock_pending_skill_id", ""))
	var action_id := str(card.get("manual_unlock_pending_action_id", ""))
	card.erase("manual_unlock_pending_skill_id")
	card.erase("manual_unlock_pending_action_id")
	return _finalize_manual_activity_unlock(skill_id, action_id, save_reason)


func _clear_activity_requirement_manual_unlocks(skill_id: String, action_id: String) -> void:
	if skill_id.is_empty() or action_id.is_empty() or manual_activity_requirement_unlocks.is_empty():
		return
	var prefix := "%s:%s:" % [skill_id, action_id]
	for raw_key in manual_activity_requirement_unlocks.keys():
		var key := str(raw_key)
		if key.begins_with(prefix):
			manual_activity_requirement_unlocks.erase(raw_key)


func _restore_manual_activity_unlocks(loaded_manual_unlocks: Variant) -> void:
	manual_activity_unlocks.clear()
	_invalidate_manual_activity_unlock_trust()
	if typeof(loaded_manual_unlocks) != TYPE_DICTIONARY:
		return
	for raw_key in (loaded_manual_unlocks as Dictionary).keys():
		if not bool((loaded_manual_unlocks as Dictionary).get(raw_key, false)):
			continue
		var key := _canonical_manual_activity_unlock_key(str(raw_key))
		if not key.is_empty():
			manual_activity_unlocks[key] = true
	_invalidate_manual_activity_unlock_trust()


func _manual_activity_unlocks_for_save() -> Dictionary:
	if not _manual_activity_unlocks_are_trusted():
		return {}
	var normalized := {}
	for raw_key in manual_activity_unlocks.keys():
		if not bool(manual_activity_unlocks.get(raw_key, false)):
			continue
		var key := _canonical_manual_activity_unlock_key(str(raw_key))
		if not key.is_empty():
			normalized[key] = true
	return normalized


func _manual_activity_requirement_unlocks_for_save() -> Dictionary:
	var normalized := {}
	for raw_key in manual_activity_requirement_unlocks.keys():
		if not bool(manual_activity_requirement_unlocks.get(raw_key, false)):
			continue
		var key := _canonical_manual_activity_requirement_unlock_key(str(raw_key))
		if not key.is_empty():
			normalized[key] = true
	return normalized


func _restore_manual_activity_requirement_unlocks(loaded_requirement_unlocks: Variant) -> void:
	manual_activity_requirement_unlocks.clear()
	if typeof(loaded_requirement_unlocks) != TYPE_DICTIONARY:
		return
	for raw_key in (loaded_requirement_unlocks as Dictionary).keys():
		if not bool((loaded_requirement_unlocks as Dictionary).get(raw_key, false)):
			continue
		var key := _canonical_manual_activity_requirement_unlock_key(str(raw_key))
		if not key.is_empty():
			manual_activity_requirement_unlocks[key] = true


func _mark_activity_requirement_manually_unlocked(skill_id: String, action: Dictionary, requirement_index: int) -> bool:
	var key := _action_requirement_unlock_key(skill_id, action, requirement_index)
	if key.is_empty():
		return false
	manual_activity_requirement_unlocks[key] = true
	return true


func _action_requirement_manually_unlocked(skill_id: String, action: Dictionary, requirement_index: int) -> bool:
	var key := _action_requirement_unlock_key(skill_id, action, requirement_index)
	return not key.is_empty() and bool(manual_activity_requirement_unlocks.get(key, false))


func _action_requirement_unlock_key(skill_id: String, action: Dictionary, requirement_index: int) -> String:
	if skill_id.is_empty() or action.is_empty() or requirement_index < 0:
		return ""
	var action_id := str(action.get("id", ""))
	if action_id.is_empty():
		return ""
	var requirements := _action_unlock_requirements(skill_id, action)
	if requirement_index >= requirements.size():
		return ""
	var requirement := requirements[requirement_index] as Dictionary
	var requirement_skill := str(requirement.get("skill", skill_id))
	var requirement_level := maxi(1, int(requirement.get("level", action.get("unlock", 1))))
	if requirement_skill.is_empty():
		return ""
	return "%s:%s:%s:%s" % [skill_id, action_id, requirement_skill, requirement_level]


func _canonical_manual_activity_requirement_unlock_key(key: String) -> String:
	var parts := key.split(":", false, 4)
	if parts.size() < 4:
		return ""
	var skill_id := str(parts[0])
	var action_id := str(parts[1])
	var requirement_skill := str(parts[2])
	var requirement_level := maxi(1, int(parts[3]))
	if skill_id.is_empty() or action_id.is_empty() or requirement_skill.is_empty():
		return ""
	var action = host._action_data(skill_id, action_id)
	if action.is_empty():
		return ""
	for index in range(_action_unlock_requirements(skill_id, action).size()):
		var requirement := (_action_unlock_requirements(skill_id, action)[index]) as Dictionary
		if str(requirement.get("skill", skill_id)) == requirement_skill and int(requirement.get("level", 1)) == requirement_level:
			return _action_requirement_unlock_key(skill_id, action, index)
	return ""


func _canonical_manual_activity_unlock_key(key: String) -> String:
	var separator := key.find(":")
	if separator < 0:
		return ""
	var skill_id := key.substr(0, separator)
	var action_id := key.substr(separator + 1)
	if skill_id.is_empty() or action_id.is_empty():
		return ""
	var action = host._action_data(skill_id, action_id)
	if action.is_empty():
		return ""
	return host._action_key(skill_id, str(action.get("id", action_id)))
