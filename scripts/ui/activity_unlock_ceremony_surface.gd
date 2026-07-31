extends RefCounted

const ActivityCardStyles = preload("res://scripts/ui/activity_card_styles.gd")
const ActivityLockRig = preload("res://scripts/ui/activity_lock_rig.gd")

const CHAIN_FALL_SECONDS = 1.15
const CHAIN_FADE_SECONDS = 0.85
const MOTION_START_DELAY = 0.48
const NEXT_PREVIEW_FADE_DELAY = 0.68
const SPACER_SETTLE_SECONDS = 1.18
const NEXT_PREVIEW_SETTLE_OFFSET = 12.0

var host
var ceremony_count = 0
var preview_after_ceremony_id = ""
var preview_staged_action_ids = {}
var preview_played_action_ids = {}
var heist_preview_after_ceremony_id = ""
var center_scroll_target = -1
var detail_refresh_done = false
var visual_scroll_tween: Tween
var ceremony_action_key = ""
var locked_preview_reveal_pending = false
var locked_preview_reveal_skill_ids = {}
var locked_preview_fade_play_pending = false
var locked_preview_played_action_keys = {}


func _init(host_node) -> void:
	host = host_node


func cancel_transients_for_navigation() -> void:
	for raw_card in host.action_cards.values():
		if typeof(raw_card) != TYPE_DICTIONARY:
			continue
		var card = raw_card as Dictionary
		host._app_lifecycle_runtime()._kill_card_tween(card, "preview_fade_tween")
		host._activity_unlock_runtime()._finalize_manual_activity_unlock_for_card(card)
		card["unlock_ceremony_finalized"] = true
		card["unlock_ceremony_pending"] = false
		card["unlock_ceremony_active"] = false
		card["unlock_ready_pending"] = false
	host._activity_unlock_runtime().clear_pending_readiness_for_skill(host.selected_skill_id)
	ceremony_count = 0
	ceremony_action_key = ""
	set_preview_after_ceremony("")
	clear_preview_reveal_guards()
	heist_preview_after_ceremony_id = ""
	center_scroll_target = -1
	detail_refresh_done = true
	if host._skill_detail_surface().detail_unlock_scroll_spacer_tween != null and host._skill_detail_surface().detail_unlock_scroll_spacer_tween.is_valid():
		host._skill_detail_surface().detail_unlock_scroll_spacer_tween.kill()
		host._skill_detail_surface().detail_unlock_scroll_spacer_tween = null
	host._skill_detail_surface().detail_unlock_scroll_spacer_heights.clear()
	clear_visual_scroll_tween()


func clear_visual_scroll_tween() -> void:
	if visual_scroll_tween != null and visual_scroll_tween.is_valid():
		visual_scroll_tween.kill()
	visual_scroll_tween = null


func set_preview_after_ceremony(action_id: String) -> void:
	var normalized = str(action_id)
	if not normalized.is_empty() and preview_after_ceremony_id != normalized:
		clear_preview_reveal_guards()
	preview_after_ceremony_id = normalized
	if (
		host.current_screen == "skill"
		and host._fishing_rework_active_for_skill(host.selected_skill_id)
		and not normalized.is_empty()
	):
		host._skill_detail_surface()._ensure_detail_lazy_entry_mounted(normalized)


func clear_preview_reveal_guards() -> void:
	preview_staged_action_ids.clear()
	preview_played_action_ids.clear()
	locked_preview_reveal_pending = false
	locked_preview_reveal_skill_ids.clear()
	locked_preview_fade_play_pending = false
	locked_preview_played_action_keys.clear()


func queue_locked_preview_reveal_if_needed(_previously_available: bool) -> void:
	pass


func queue_locked_preview_reveal() -> void:
	locked_preview_reveal_skill_ids.clear()
	var first_locked_id = host._onboarding_runtime()._tutorial_current_locked_preview_action_id(host.selected_skill_id) if not host.selected_skill_id.is_empty() else ""
	var preview_key = host._action_key(host.selected_skill_id, first_locked_id) if not first_locked_id.is_empty() else ""
	if not preview_key.is_empty() and not bool(locked_preview_played_action_keys.get(preview_key, false)):
		locked_preview_reveal_skill_ids[host.selected_skill_id] = true
	locked_preview_reveal_pending = not locked_preview_reveal_skill_ids.is_empty()
	if locked_preview_reveal_pending:
		locked_preview_fade_play_pending = true
		host._skill_swipe_activity_surface()._clear_skill_swipe_preview()


func prestage_preview_card(action_id: String, delay = 0.12) -> void:
	if host.current_screen != "skill" or action_id.is_empty():
		return
	if host._fishing_rework_active_for_skill(host.selected_skill_id):
		if preview_after_ceremony_id == action_id:
			if not host._fishing_ui_surface().fishing_unlock_preview_fade_marker_ids.has(action_id):
				host._fishing_ui_surface().fishing_unlock_preview_fade_marker_ids.append(action_id)
			stage_preview_for_action_id(action_id, false)
		return
	if delay > 0.0:
		await host.get_tree().create_timer(delay).timeout
	if host.current_screen != "skill":
		return
	if preview_after_ceremony_id != action_id:
		return
	activity_preview_card_for_action_id(action_id, true)


func stage_preview_once(action_id: String, card: Dictionary, collapse_height = true) -> bool:
	if action_id.is_empty() or card.is_empty():
		return false
	if bool(preview_staged_action_ids.get(action_id, false)):
		return false
	preview_staged_action_ids[action_id] = true
	stage_preview_enter(card, collapse_height)
	return true


func claim_preview_play(action_id: String) -> bool:
	if action_id.is_empty():
		return true
	if bool(preview_played_action_ids.get(action_id, false)):
		return false
	preview_played_action_ids[action_id] = true
	return true


func apply_pending_readiness() -> void:
	if host._activity_unlock_runtime().pending_readiness_pages().is_empty():
		return
	var pending_entry = host._activity_unlock_runtime().pending_readiness_for_skill(host.selected_skill_id)
	if pending_entry.is_empty():
		return
	if bool(pending_entry.get("applied", false)):
		return
	var readiness_action_ids = host._activity_unlock_runtime().pending_readiness_action_ids(host.selected_skill_id)
	host._onboarding_runtime()._release_onboarding_first_module_centering_for_level_two_unlock(host.selected_skill_id, readiness_action_ids)
	for raw_action_id in readiness_action_ids:
		var action_id = str(raw_action_id)
		var key = host._action_key(host.selected_skill_id, action_id)
		var card = {}
		if host.action_cards.has(key):
			card = host.action_cards[key] as Dictionary
		elif host._fishing_rework_active_for_skill(host.selected_skill_id):
			card = host._fishing_ui_surface()._fishing_method_card_for_action(host.selected_skill_id, action_id)
		if card.is_empty():
			continue
		var action = host._action_data(host.selected_skill_id, action_id)
		if action.is_empty():
			continue
		if host._activity_unlock_runtime()._is_action_unlocked(host.selected_skill_id, action):
			host._activity_unlock_runtime().clear_pending_readiness_action(host.selected_skill_id, action_id)
			host._mark_save_dirty("activity unlock cleanup")
			continue
		card["unlock_ceremony_pending"] = false
		card["unlock_ceremony_active"] = false
		card["unlock_ceremony_finalized"] = false
		card["unlock_ready_pending"] = true
		card.erase("lock_overlay_sync_key")
		if bool(card.get("locked_preview_hidden", false)):
			reveal_locked_activity_card_in_place(card, host.selected_skill_id, action)
		if bool(card.get("passive", false)):
			host._passive_firepit_surface()._update_passive_card_static_state(card, host.selected_skill_id, action, host._activity_unlock_runtime()._is_action_unlocked(host.selected_skill_id, action))
		elif not bool(card.get("is_fishing_method", false)):
			host._skill_swipe_activity_surface()._update_action_card_static_state(card, host.selected_skill_id, action, host._activity_unlock_runtime()._is_action_unlocked(host.selected_skill_id, action))
		else:
			card["unlock_ceremony_pending"] = false
			card["unlock_ready_pending"] = true
	var preview_id = str(pending_entry.get("preview", ""))
	set_preview_after_ceremony(preview_id)
	if not preview_id.is_empty():
		prestage_preview_card(preview_id)
	host._activity_unlock_runtime().mark_pending_readiness_applied(host.selected_skill_id)
	detail_refresh_done = false
	if host.auto_unlock_lockpads_enabled:
		host._activity_unlock_runtime().call_deferred("_auto_unlock_visible_pending_lockpads", host.selected_skill_id)


func play_ceremony(card: Dictionary, lock_rig: Control = null) -> void:
	card["unlock_ceremony_pending"] = false
	card["unlock_ready_pending"] = false
	card["unlock_ceremony_active"] = true
	card["unlock_ceremony_finalized"] = false
	ceremony_count += 1
	var ceremony_action_id = str(card.get("action_id", ""))
	if ceremony_action_id.is_empty():
		var ceremony_action = card.get("action", {}) as Dictionary
		ceremony_action_id = str(ceremony_action.get("id", ""))
	var ceremony_skill_id = str(card.get("skill_id", host.selected_skill_id))
	if not ceremony_action_id.is_empty():
		ceremony_action_key = host._action_key(ceremony_skill_id, ceremony_action_id)
	host._skill_detail_surface()._prepare_activity_unlock_ceremony_overlay(card, lock_rig)
	var root = host._app_lifecycle_runtime().valid_control_ref(card.get("root"))
	if root != null:
		card["unlock_ceremony_original_z_index"] = root.z_index
		card["unlock_ceremony_original_clip"] = root.clip_contents
		root.z_index = 90
		root.clip_contents = false
	var overlay = card.get("lock_overlay", {}) as Dictionary
	var overlay_root = host._app_lifecycle_runtime().valid_control_ref(overlay.get("root"))
	var group = host._app_lifecycle_runtime().valid_control_ref(lock_rig) if lock_rig != null else host._app_lifecycle_runtime().valid_control_ref(overlay.get("group"))
	if group == null and overlay.has("group"):
		group = host._app_lifecycle_runtime().valid_control_ref(overlay.get("group"))
	card["unlock_ceremony_lock_rig"] = group
	card["unlock_ceremony_overlay_root"] = overlay_root
	var button = host._app_lifecycle_runtime().valid_button_ref(card.get("button"))
	var shade = host._app_lifecycle_runtime().valid_canvas_item_ref(ActivityCardStyles.ensure_activity_card_shade(card, 0.50))
	if _tutorial_level_two_unlock_should_use_fast_reveal(ceremony_skill_id, ceremony_action_id):
		_play_tutorial_level_two_fast_unlock_ceremony(card, group, overlay_root, shade, button)
		return
	if overlay_root == null or group == null:
		if root != null and is_instance_valid(root):
			root.z_index = int(card.get("unlock_ceremony_original_z_index", 0))
			root.clip_contents = bool(card.get("unlock_ceremony_original_clip", false))
		card.erase("unlock_ceremony_original_z_index")
		card.erase("unlock_ceremony_original_clip")
		card.erase("unlock_ceremony_lock_rig")
		card.erase("unlock_ceremony_overlay_root")
		card["unlock_ceremony_active"] = false
		ceremony_count = maxi(0, ceremony_count - 1)
		ceremony_action_key = ""
		if button != null:
			button.disabled = false
		return
	if button != null:
		button.disabled = true
	start_ceremony_motion(card)


func _tutorial_level_two_unlock_should_use_fast_reveal(skill_id: String, action_id: String) -> bool:
	return (
		host._onboarding_runtime()._tutorial_gate_latch_sequence_active()
		and skill_id == host.TUTORIAL_STARTER_SKILL_ID
		and action_id == host.TUTORIAL_LEVEL_TWO_ACTION_ID
	)


func _play_tutorial_level_two_fast_unlock_ceremony(card: Dictionary, group: Control, overlay_root: Control, shade: CanvasItem, button: Button) -> void:
	if button != null and is_instance_valid(button):
		button.disabled = true
	if overlay_root != null and is_instance_valid(overlay_root):
		overlay_root.visible = true
		overlay_root.modulate = Color.WHITE
	if group != null and is_instance_valid(group):
		group.visible = true
		group.modulate = Color.WHITE
	if shade != null and is_instance_valid(shade):
		shade.visible = true
		shade.modulate = Color(1, 1, 1, 0.50)
	var fade_duration = host._skill_detail_surface().DETAIL_LAZY_FADE_IN_SECONDS
	var tween = host.create_tween()
	tween.set_parallel(true)
	if group != null and is_instance_valid(group):
		tween.tween_property(group, "modulate:a", 0.0, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if shade != null and is_instance_valid(shade):
		tween.tween_property(shade, "modulate:a", 0.0, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	await host.get_tree().create_timer(fade_duration).timeout
	if bool(card.get("unlock_ceremony_finalized", false)):
		return
	finish_ceremony_safe(card, overlay_root, shade, button, true)
	await run_post_ceremony_preview(card)
	var preview_id = preview_after_ceremony_id
	if heist_preview_after_ceremony_id.is_empty() and not preview_id.is_empty():
		host._skill_detail_surface().call_deferred("_stage_unlock_preview_after_lock_click", preview_id)


func start_ceremony_motion(card: Dictionary) -> void:
	var group = host._app_lifecycle_runtime().valid_control_ref(card.get("unlock_ceremony_lock_rig"))
	var overlay_root = host._app_lifecycle_runtime().valid_control_ref(card.get("unlock_ceremony_overlay_root"))
	var shade = host._app_lifecycle_runtime().valid_canvas_item_ref(ActivityCardStyles.ensure_activity_card_shade(card, 0.50))
	var button = host._app_lifecycle_runtime().valid_button_ref(card.get("button"))
	if group == null or not is_instance_valid(group):
		var overlay = card.get("lock_overlay", {}) as Dictionary
		group = host._app_lifecycle_runtime().valid_control_ref(overlay.get("group"))
	if overlay_root == null or not is_instance_valid(overlay_root):
		var overlay = card.get("lock_overlay", {}) as Dictionary
		overlay_root = host._app_lifecycle_runtime().valid_control_ref(overlay.get("root"))
	_start_ceremony_motion_after_delay(
		card,
		host._app_lifecycle_runtime().weak_object_ref(group),
		host._app_lifecycle_runtime().weak_object_ref(overlay_root),
		host._app_lifecycle_runtime().weak_object_ref(shade),
		host._app_lifecycle_runtime().weak_object_ref(button)
	)


func _start_ceremony_motion_after_delay(card: Dictionary, group_ref: WeakRef, overlay_root_ref: WeakRef, shade_ref: WeakRef, button_ref: WeakRef) -> void:
	await host.get_tree().create_timer(MOTION_START_DELAY).timeout
	if bool(card.get("unlock_ceremony_finalized", false)):
		return
	var group = host._app_lifecycle_runtime().valid_control_ref(host._app_lifecycle_runtime().weak_ref_value(group_ref))
	var overlay_root = host._app_lifecycle_runtime().valid_control_ref(host._app_lifecycle_runtime().weak_ref_value(overlay_root_ref))
	var shade = host._app_lifecycle_runtime().valid_canvas_item_ref(host._app_lifecycle_runtime().weak_ref_value(shade_ref))
	var button = host._app_lifecycle_runtime().valid_button_ref(host._app_lifecycle_runtime().weak_ref_value(button_ref))
	if host.current_screen != "skill":
		finish_ceremony_safe(card, overlay_root, shade, button, false)
		return
	if group == null or not is_instance_valid(group) or group.is_queued_for_deletion():
		var overlay = card.get("lock_overlay", {}) as Dictionary
		group = host._app_lifecycle_runtime().valid_control_ref(overlay.get("group"))
	if group == null or not is_instance_valid(group) or group.is_queued_for_deletion():
		finish_ceremony_safe(card, overlay_root, shade, button, true)
		return
	if overlay_root == null or not is_instance_valid(overlay_root):
		var overlay = card.get("lock_overlay", {}) as Dictionary
		overlay_root = host._app_lifecycle_runtime().valid_control_ref(overlay.get("root"))
	if overlay_root != null and is_instance_valid(overlay_root):
		overlay_root.visible = true
		overlay_root.modulate = Color.WHITE
	group.modulate = Color.WHITE
	group.visible = true
	group.set_process(true)
	if group.has_method("play_unlock_drop_animation"):
		var lock_rig_ref = host._app_lifecycle_runtime().weak_object_ref(group)
		var lock_rig = group
		await host.get_tree().process_frame
		lock_rig = host._app_lifecycle_runtime().valid_control_ref(host._app_lifecycle_runtime().weak_ref_value(lock_rig_ref))
		if lock_rig == null or lock_rig.is_queued_for_deletion():
			finish_ceremony_safe(card, overlay_root, shade, button, true)
			return
		await host.get_tree().process_frame
		lock_rig = host._app_lifecycle_runtime().valid_control_ref(host._app_lifecycle_runtime().weak_ref_value(lock_rig_ref))
		if lock_rig == null or lock_rig.is_queued_for_deletion():
			finish_ceremony_safe(card, overlay_root, shade, button, true)
			return
		lock_rig.call("_layout_base")
		if lock_rig.size.y <= 1.0:
			lock_rig.call_deferred("_layout_base")
			await host.get_tree().process_frame
			lock_rig = host._app_lifecycle_runtime().valid_control_ref(host._app_lifecycle_runtime().weak_ref_value(lock_rig_ref))
			if lock_rig == null or lock_rig.is_queued_for_deletion():
				finish_ceremony_safe(card, overlay_root, shade, button, true)
				return
			lock_rig.call("_layout_base")
		host._audio_director()._play_chain_fall_sfx_sequence(lock_rig)
		lock_rig.call("play_unlock_drop_animation")
		await host.get_tree().create_timer(ActivityLockRig.UNLOCK_DROP_SECONDS + 0.05).timeout
	else:
		host._audio_director()._play_chain_fall_sfx_sequence(group)
	if bool(card.get("unlock_ceremony_finalized", false)):
		return
	group = host._app_lifecycle_runtime().valid_control_ref(host._app_lifecycle_runtime().weak_ref_value(group_ref))
	if group == null or group.is_queued_for_deletion():
		finish_ceremony_safe(card, overlay_root, shade, button, true)
		return
	shade = host._app_lifecycle_runtime().valid_canvas_item_ref(host._app_lifecycle_runtime().weak_ref_value(shade_ref))
	if shade != null and is_instance_valid(shade):
		shade.visible = true
	var fade_tween = host.create_tween()
	fade_tween.tween_property(group, "modulate:a", 0.0, CHAIN_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if shade != null and is_instance_valid(shade):
		fade_tween.parallel().tween_property(shade, "modulate:a", 0.0, CHAIN_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await host.get_tree().create_timer(CHAIN_FADE_SECONDS + 0.05).timeout
	if bool(card.get("unlock_ceremony_finalized", false)):
		return
	finish_ceremony_safe(card, overlay_root, shade, button, true)
	await run_post_ceremony_preview(card)
	var preview_id = preview_after_ceremony_id
	if heist_preview_after_ceremony_id.is_empty() and not preview_id.is_empty():
		host._skill_detail_surface().call_deferred("_stage_unlock_preview_after_lock_click", preview_id)


func run_post_ceremony_preview(card: Dictionary):
	if host.current_screen != "skill":
		return
	if bool(card.get("unlock_ceremony_finalized", false)) == false:
		return
	if not heist_preview_after_ceremony_id.is_empty():
		return
	if preview_after_ceremony_id.is_empty():
		return
	if play_next_locked_preview_fade():
		return
	var preview_id = preview_after_ceremony_id
	if preview_id.is_empty():
		return
	var preview_card = activity_preview_card_for_action_id(preview_id, true)
	if preview_card.is_empty():
		return
	if not bool(preview_card.get("unlock_next_preview_pending", false)):
		return
	preview_card.erase("unlock_next_preview_pending")
	if not claim_preview_play(preview_id):
		return
	host._skill_swipe_activity_surface()._play_activity_preview_fade_in(preview_card)


func finish_ceremony_safe(card: Dictionary, overlay_root_value: Variant, shade_value: Variant, button_value: Variant, refresh_detail: bool) -> void:
	if card.is_empty():
		return
	var overlay_root = host._app_lifecycle_runtime().valid_control_ref(overlay_root_value)
	if overlay_root == null:
		var overlay = card.get("lock_overlay", {}) as Dictionary
		overlay_root = host._app_lifecycle_runtime().valid_control_ref(overlay.get("root"))
	var shade = host._app_lifecycle_runtime().valid_canvas_item_ref(shade_value)
	if shade == null:
		shade = host._app_lifecycle_runtime().valid_canvas_item_ref(card.get("shade"))
	var button = host._app_lifecycle_runtime().valid_button_ref(button_value)
	if button == null:
		button = host._app_lifecycle_runtime().valid_button_ref(card.get("button"))
	finish_ceremony(card, overlay_root, shade, button, refresh_detail)


func finish_ceremony(card: Dictionary, overlay_root: Control, shade: CanvasItem, button: Button, refresh_detail: bool) -> void:
	if bool(card.get("unlock_ceremony_finalized", false)):
		return
	var pending_skill_id = str(card.get("manual_unlock_pending_skill_id", card.get("skill_id", host.selected_skill_id)))
	var pending_action_id = str(card.get("manual_unlock_pending_action_id", card.get("action_id", "")))
	if pending_action_id.is_empty():
		var pending_action = card.get("action", {}) as Dictionary
		pending_action_id = str(pending_action.get("id", ""))
	host._activity_unlock_runtime().clear_pending_readiness_action(pending_skill_id, pending_action_id)
	card["unlock_ceremony_finalized"] = true
	card["requirement_lock_dismiss_active"] = false
	var lock_rig = host._app_lifecycle_runtime().state_object_ref(card.get("unlock_ceremony_lock_rig"))
	if lock_rig != null:
		if lock_rig.has_method("set_lock_state"):
			lock_rig.call("set_lock_state", "gone")
	host._activity_unlock_runtime()._finalize_manual_activity_unlock_for_card(card)
	card.erase("unlock_ceremony_lock_rig")
	card.erase("unlock_ceremony_overlay_root")
	ceremony_action_key = ""
	var root = host._app_lifecycle_runtime().valid_control_ref(card.get("root"))
	if root != null:
		root.z_index = int(card.get("unlock_ceremony_original_z_index", 0))
		root.clip_contents = bool(card.get("unlock_ceremony_original_clip", false))
	card.erase("unlock_ceremony_original_z_index")
	card.erase("unlock_ceremony_original_clip")
	if overlay_root != null and is_instance_valid(overlay_root):
		overlay_root.visible = false
	var overlay = card.get("lock_overlay", {}) as Dictionary
	if not overlay.is_empty():
		host._skill_detail_surface()._set_activity_lock_overlay_active(overlay, false)
	if shade != null and is_instance_valid(shade):
		shade.visible = false
		shade.modulate = Color.WHITE
	card["unlock_ceremony_active"] = false
	if button != null and is_instance_valid(button):
		button.disabled = false
	ceremony_count = maxi(0, ceremony_count - 1)
	call_deferred("finish_card_static_state_deferred", card)
	host._activity_unlock_runtime()._schedule_auto_unlock_pending_lockpads()
	if refresh_detail and ceremony_count <= 0 and not detail_refresh_done:
		host.call_deferred("_refresh_skill_detail_after_activity_unlock_ceremony")


func finish_card_static_state_deferred(card: Dictionary) -> void:
	await host.get_tree().process_frame
	if card.is_empty():
		return
	var root = host._app_lifecycle_runtime().valid_control_ref(card.get("root"))
	if root == null or root.is_queued_for_deletion():
		return
	var skill_id = str(card.get("skill_id", host.selected_skill_id))
	var action = card.get("action", {}) as Dictionary
	if action.is_empty() and not skill_id.is_empty():
		var action_id = str(card.get("action_id", ""))
		if action_id.is_empty() and card.has("action"):
			action_id = str((card.get("action", {}) as Dictionary).get("id", ""))
		if not action_id.is_empty():
			action = host._action_data(skill_id, action_id)
	if action.is_empty():
		return
	var unlocked = host._activity_unlock_runtime()._is_action_unlocked(skill_id, action)
	if bool(card.get("passive", false)):
		host._passive_firepit_surface()._update_passive_card_static_state(card, skill_id, action, unlocked)
	elif not bool(card.get("is_fishing_method", false)):
		host._skill_swipe_activity_surface()._update_action_card_static_state(card, skill_id, action, unlocked)


func finish_activity_preview_fade_in(card_key: String, root_id: int, pop_id: int, lock_rig_id: int, expand_from_zero: bool, target_height: float, skill_id: String, action_id: String) -> void:
	var card = host.action_cards.get(card_key, {}) as Dictionary
	if card.is_empty():
		return
	var callback_root = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(root_id))
	if callback_root == null or callback_root.is_queued_for_deletion():
		card.erase("unlock_next_preview_smooth")
		card.erase("stable_preview_fade")
		card.erase("preview_fade_tween")
		card["fade_in_pending"] = false
		return
	host._app_lifecycle_runtime().set_canvas_item_modulate_if_changed(callback_root, Color.WHITE)
	if expand_from_zero:
		host._app_lifecycle_runtime().set_control_minimum_height(callback_root, target_height)
		callback_root.clip_contents = bool(card.get("preview_enter_original_clip", false))
		card.erase("preview_enter_target_height")
		card.erase("preview_enter_entry_target_height")
		card.erase("preview_enter_original_clip")
		set_activity_preview_entry_height(card, callback_root, target_height)
	var callback_pop = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(pop_id)) if pop_id != 0 else null
	if callback_pop != null and not callback_pop.is_queued_for_deletion():
		set_preview_pop_vertical_offset(callback_pop, 0.0)
	card.erase("unlock_next_preview_smooth")
	card.erase("stable_preview_fade")
	card.erase("preview_fade_tween")
	card["fade_in_pending"] = false
	if not skill_id.is_empty() and not action_id.is_empty():
		call_deferred("finish_activity_preview_card_after_fade_deferred", card_key, skill_id, action_id, lock_rig_id)


func finish_activity_preview_card_after_fade_deferred(card_key: String, skill_id: String, action_id: String, lock_rig_id: int) -> void:
	await host.get_tree().process_frame
	var card = host.action_cards.get(card_key, {}) as Dictionary
	var action = host._action_data(skill_id, action_id)
	if card.is_empty() or skill_id.is_empty() or action.is_empty():
		return
	var root = host._app_lifecycle_runtime().valid_control_ref(card.get("root"))
	if root == null or root.is_queued_for_deletion():
		return
	var callback_lock_rig = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(lock_rig_id)) if lock_rig_id != 0 else null
	if callback_lock_rig != null:
		host._app_lifecycle_runtime().set_canvas_item_modulate_if_changed(callback_lock_rig, Color.WHITE)
	var final_unlocked = host._activity_unlock_runtime()._is_action_unlocked(skill_id, action)
	if final_unlocked:
		host._skill_detail_surface()._sync_activity_lock_overlay(card, action, true)
	else:
		finish_locked_preview_overlay_without_resync(card, action)
	if skill_id == host.TUTORIAL_STARTER_SKILL_ID and action_id == host.TUTORIAL_GATE_LATCH_ACTION_ID:
		host._tutorial_overlay_surface().call_deferred("_show_skill_swipe_tip_note_if_needed")


func finish_locked_preview_overlay_without_resync(card: Dictionary, action: Dictionary) -> void:
	var overlay = card.get("lock_overlay", {}) as Dictionary
	if overlay.is_empty():
		return
	var overlay_root = host._app_lifecycle_runtime().valid_control_ref(overlay.get("root"))
	if overlay_root != null:
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(overlay_root, true)
	var rig = host._app_lifecycle_runtime().state_object_ref(overlay.get("group"))
	if rig != null:
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(rig, true)
		host._app_lifecycle_runtime().set_canvas_item_modulate_if_changed(rig, Color.WHITE)
		rig.set_process(true)
		if rig.has_method("set_unlock_level"):
			rig.call("set_unlock_level", int(action.get("unlock", 1)))
	card["lock_overlay_sync_key"] = "%s:%s:%s" % [true, false, int(action.get("unlock", 1))]


func set_preview_pop_vertical_offset(pop: Control, offset_y: float) -> void:
	if pop == null or not is_instance_valid(pop):
		return
	if pop.anchor_top == 0.0 and pop.anchor_bottom == 1.0:
		pop.offset_top = offset_y
		pop.offset_bottom = ActivityCardStyles.activity_card_pop_base_bottom_offset(pop) + offset_y
		ActivityCardStyles.set_activity_card_depth_face_offset_from_pop(pop, Vector2(pop.offset_left - host.ACTION_CARD_POP_GUTTER, offset_y), host.ACTION_CARD_POP_GUTTER, host.ACTION_CARD_3D_DEPTH_OFFSET.y)
	else:
		pop.position.y = offset_y


func set_preview_pop_vertical_offset_safe(offset_y: float, pop_id: int) -> void:
	var pop = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(pop_id))
	if pop == null or pop.is_queued_for_deletion():
		return
	set_preview_pop_vertical_offset(pop, offset_y)


func activity_preview_entry_control(card: Dictionary, root: Control) -> Control:
	var entry = host._app_lifecycle_runtime().valid_control_ref(card.get("entry"))
	if entry == null or entry == root:
		return null
	return entry


func activity_preview_entry_height(card: Dictionary, root: Control, fallback_height: float) -> float:
	var entry = activity_preview_entry_control(card, root)
	if entry == null:
		return fallback_height
	var entry_height = maxf(entry.custom_minimum_size.y, entry.size.y)
	return entry_height if entry_height > 1.0 else fallback_height


func set_activity_preview_entry_height(card: Dictionary, root: Control, height: float) -> void:
	var entry = activity_preview_entry_control(card, root)
	if entry == null:
		return
	host._app_lifecycle_runtime().set_control_minimum_height(entry, height)


func sync_hidden_locked_activity_preview_layouts() -> void:
	if host._onboarding_runtime().tutorial_active:
		return
	if host.action_cards.is_empty():
		return
	for raw_card in host.action_cards.values():
		var card = raw_card as Dictionary
		if card == null or not bool(card.get("locked_preview_hidden", false)):
			continue
		var root = host._app_lifecycle_runtime().valid_control_ref(card.get("root"))
		if root == null or not root.is_inside_tree():
			continue
		host._app_lifecycle_runtime().set_control_minimum_height(root, 0.0)
		set_activity_preview_entry_height(card, root, 0.0)
		root.visible = true
		root.modulate = Color(1, 1, 1, 0)
		root.clip_contents = true


func prepare_locked_activity_preview_fade(card: Dictionary, skill_id: String, action: Dictionary) -> void:
	if not locked_preview_reveal_pending:
		return
	if not bool(locked_preview_reveal_skill_ids.get(skill_id, false)):
		return
	if host._activity_unlock_runtime()._is_action_unlocked(skill_id, action):
		return
	var action_id = str(action.get("id", ""))
	if action_id != host._onboarding_runtime()._tutorial_current_locked_preview_action_id(skill_id):
		card["locked_preview_fade_in_pending"] = false
		card.erase("locked_preview_reveal_skill_id")
		card.erase("locked_preview_reveal_action_id")
		return
	var preview_key = host._action_key(skill_id, action_id)
	if bool(locked_preview_played_action_keys.get(preview_key, false)):
		locked_preview_reveal_skill_ids.erase(skill_id)
		return
	if bool(card.get("locked_preview_fade_in_pending", false)) or card.get("preview_fade_tween") != null:
		return
	locked_preview_reveal_skill_ids.erase(skill_id)
	card["unlock_next_preview_smooth"] = true
	var stable_tutorial_fade = _should_use_stable_tutorial_locked_preview_fade(skill_id, action_id)
	card["stable_preview_fade"] = stable_tutorial_fade
	stage_preview_enter(card, _should_expand_locked_activity_preview_reveal(skill_id, action_id) and not stable_tutorial_fade)
	card["locked_preview_fade_in_pending"] = true
	card["locked_preview_reveal_skill_id"] = skill_id
	card["locked_preview_reveal_action_id"] = action_id
	locked_preview_fade_play_pending = true


func _should_use_stable_tutorial_locked_preview_fade(skill_id: String, action_id: String) -> bool:
	return (
		host._onboarding_runtime()._onboarding_path_active()
		and skill_id == host.TUTORIAL_STARTER_SKILL_ID
		and action_id == host.TUTORIAL_LEVEL_TWO_ACTION_ID
	)


func _should_expand_locked_activity_preview_reveal(skill_id: String, action_id: String) -> bool:
	return (
		host._onboarding_runtime()._onboarding_path_active()
		and skill_id == host.TUTORIAL_STARTER_SKILL_ID
		and action_id == host.TUTORIAL_LEVEL_TWO_ACTION_ID
	)


func play_pending_locked_activity_preview_reveals() -> void:
	for raw_card in host.action_cards.values():
		var card = raw_card as Dictionary
		_prepare_pending_locked_activity_preview_card(card)
		play_locked_preview_reveal(card)
	for raw_state in host._skill_swipe_activity_surface()._preview_state_values():
		var state = raw_state as Dictionary
		if state == null:
			continue
		var preview_cards = state.get("action_cards", []) as Array
		for raw_card in preview_cards:
			var card = raw_card as Dictionary
			_prepare_pending_locked_activity_preview_card(card)
			play_locked_preview_reveal(card)
	locked_preview_fade_play_pending = false
	locked_preview_reveal_pending = not locked_preview_reveal_skill_ids.is_empty()


func _prepare_pending_locked_activity_preview_card(card: Dictionary) -> void:
	if card == null:
		return
	var skill_id = str(card.get("skill_id", ""))
	var action = card.get("action", {}) as Dictionary
	if skill_id.is_empty() or action.is_empty():
		return
	prepare_locked_activity_preview_fade(card, skill_id, action)


func activity_preview_reveal_animation_pending(card: Dictionary) -> bool:
	if card.is_empty():
		return false
	var preview_fade_tween = card.get("preview_fade_tween", null)
	return (
		(
			preview_fade_tween != null
			and is_instance_valid(preview_fade_tween)
			and preview_fade_tween is Tween
			and preview_fade_tween.is_valid()
		)
		or bool(card.get("fade_in_pending", false))
		or bool(card.get("unlock_next_preview_pending", false))
		or bool(card.get("locked_preview_fade_in_pending", false))
	)


func stage_preview_enter(card: Dictionary, collapse_height = true) -> void:
	var root = card.get("root") as Control
	if root == null or not is_instance_valid(root) or root.is_queued_for_deletion():
		return
	host._skill_detail_surface()._preserve_detail_scroll_after_height_change_if_above_view(root)
	var target_height = float(card.get("locked_preview_target_height", root.custom_minimum_size.y))
	if target_height <= 0.0:
		target_height = root.size.y
	if target_height <= 0.0:
		target_height = ActivityCardStyles.preview_root_height(card, host._passive_firepit_surface()._passive_action_card_height(card.get("action", {}) as Dictionary), ActivityCardStyles.root_height(false, host.ACTION_CARD_HEIGHT, host.ACTION_CARD_EXPANDED_HEIGHT, host.ACTION_CARD_3D_DEPTH_OFFSET.y))
	var entry_target_height = float(card.get("locked_preview_entry_target_height", activity_preview_entry_height(card, root, target_height)))
	if collapse_height:
		card["preview_enter_target_height"] = target_height
		card["preview_enter_entry_target_height"] = entry_target_height
	else:
		card.erase("preview_enter_target_height")
		card.erase("preview_enter_entry_target_height")
	var original_clip = bool(card.get("locked_preview_original_clip", root.clip_contents))
	card["preview_enter_original_clip"] = original_clip
	card["locked_preview_hidden"] = false
	card.erase("locked_preview_target_height")
	card.erase("locked_preview_entry_target_height")
	card.erase("locked_preview_original_clip")
	host._app_lifecycle_runtime().set_control_minimum_height(root, 0.0 if collapse_height else target_height)
	set_activity_preview_entry_height(card, root, 0.0 if collapse_height else entry_target_height)
	host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(root, true)
	host._app_lifecycle_runtime().set_canvas_item_modulate_if_changed(root, Color(1, 1, 1, 0))
	root.clip_contents = true if collapse_height else original_clip
	var pop = card.get("pop") as Control
	if pop != null:
		set_preview_pop_vertical_offset(pop, NEXT_PREVIEW_SETTLE_OFFSET if bool(card.get("unlock_next_preview_smooth", false)) and not collapse_height else 34.0)


func sync_locked_preview_presence(card: Dictionary, skill_id: String, action: Dictionary) -> void:
	var root = card.get("root") as Control
	if root == null or not is_instance_valid(root) or root.is_queued_for_deletion():
		return
	if activity_preview_reveal_animation_pending(card):
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(root, true)
		return
	var unlocked = host._activity_unlock_runtime()._is_action_unlocked(skill_id, action)
	var action_id = str(action.get("id", ""))
	var waiting_for_unlock_fade = not unlocked and action_id == preview_after_ceremony_id
	if waiting_for_unlock_fade and bool(card.get("locked_preview_hidden", false)):
		reveal_locked_activity_card_in_place(card, skill_id, action)
	if bool(card.get("locked_preview_hidden", false)):
		card["locked_preview_hidden"] = false
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(root, true)
		var restored_height = float(card.get("locked_preview_target_height", ActivityCardStyles.preview_root_height(card, host._passive_firepit_surface()._passive_action_card_height(card.get("action", {}) as Dictionary), ActivityCardStyles.root_height(false, host.ACTION_CARD_HEIGHT, host.ACTION_CARD_EXPANDED_HEIGHT, host.ACTION_CARD_3D_DEPTH_OFFSET.y))))
		host._app_lifecycle_runtime().set_control_minimum_height(root, restored_height)
		set_activity_preview_entry_height(card, root, float(card.get("locked_preview_entry_target_height", restored_height)))
		host._app_lifecycle_runtime().set_canvas_item_modulate_if_changed(root, Color.WHITE)
		root.clip_contents = bool(card.get("locked_preview_original_clip", card.get("preview_enter_original_clip", false)))
		card.erase("locked_preview_target_height")
		card.erase("locked_preview_entry_target_height")
		card.erase("locked_preview_original_clip")


func play_locked_preview_reveal(card: Dictionary) -> void:
	if card == null or not bool(card.get("locked_preview_fade_in_pending", false)):
		return
	card["locked_preview_fade_in_pending"] = false
	var skill_id = str(card.get("locked_preview_reveal_skill_id", ""))
	var action_id = str(card.get("locked_preview_reveal_action_id", ""))
	if not skill_id.is_empty():
		locked_preview_reveal_skill_ids.erase(skill_id)
		card.erase("locked_preview_reveal_skill_id")
	card.erase("locked_preview_reveal_action_id")
	if not skill_id.is_empty() and not action_id.is_empty():
		var preview_key = host._action_key(skill_id, action_id)
		if bool(locked_preview_played_action_keys.get(preview_key, false)):
			return
		locked_preview_played_action_keys[preview_key] = true
	if host._onboarding_runtime()._should_release_onboarding_first_module_centering_for_locked_preview(skill_id, action_id):
		host._onboarding_runtime().onboarding_first_module_center_release_pending = true
		host._onboarding_runtime()._release_onboarding_first_module_centering()
	host._skill_swipe_activity_surface()._play_activity_preview_fade_in(card)


func reveal_locked_activity_card_in_place(card: Dictionary, skill_id: String, action: Dictionary) -> void:
	var root = card.get("root") as Control
	if root == null or not is_instance_valid(root):
		return
	if activity_preview_reveal_animation_pending(card):
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(root, true)
		return
	host._skill_detail_surface()._preserve_detail_scroll_after_height_change_if_above_view(root)
	card["locked_preview_hidden"] = false
	card.erase("locked_preview_target_height")
	card.erase("locked_preview_original_clip")
	card.erase("preview_enter_target_height")
	card.erase("preview_enter_original_clip")
	card.erase("unlock_next_preview_pending")
	card.erase("unlock_next_preview_smooth")
	card.erase("fade_in_pending")
	host._app_lifecycle_runtime()._kill_card_tween(card, "preview_fade_tween")
	var target_height = ActivityCardStyles.preview_root_height(card, host._passive_firepit_surface()._passive_action_card_height(card.get("action", {}) as Dictionary), ActivityCardStyles.root_height(false, host.ACTION_CARD_HEIGHT, host.ACTION_CARD_EXPANDED_HEIGHT, host.ACTION_CARD_3D_DEPTH_OFFSET.y))
	if root.custom_minimum_size.y > 1.0:
		target_height = root.custom_minimum_size.y
	elif root.size.y > 1.0:
		target_height = root.size.y
	var minimum_size = root.custom_minimum_size
	minimum_size.y = target_height
	root.custom_minimum_size = minimum_size
	host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(root, true)
	host._app_lifecycle_runtime().set_canvas_item_modulate_if_changed(root, Color.WHITE)
	root.clip_contents = false
	var pop = card.get("pop") as Control
	if pop != null and is_instance_valid(pop):
		set_preview_pop_vertical_offset(pop, 0.0)
	if not action.is_empty():
		host._skill_detail_surface()._sync_activity_lock_overlay(card, action, host._activity_unlock_runtime()._is_action_unlocked(skill_id, action))
		if bool(card.get("passive", false)):
			host._passive_firepit_surface()._update_passive_card_static_state(card, skill_id, action, host._activity_unlock_runtime()._is_action_unlocked(skill_id, action))
		elif not bool(card.get("is_fishing_method", false)) and not bool(card.get("is_fishing_area", false)):
			host._skill_swipe_activity_surface()._update_action_card_static_state(card, skill_id, action, host._activity_unlock_runtime()._is_action_unlocked(skill_id, action))


func apply_skill_detail_refresh_in_place(preview_id: String) -> bool:
	host._skill_detail_surface()._hold_skill_detail_layout_refresh(0.35)
	if host._fishing_rework_active_for_skill(host.selected_skill_id):
		return false
	for raw_key in host.action_cards.keys():
		var card = host.action_cards[raw_key] as Dictionary
		if card == null:
			continue
		var skill_id = str(card.get("skill_id", host.selected_skill_id))
		if skill_id != host.selected_skill_id:
			continue
		var action = card.get("action", {}) as Dictionary
		if action.is_empty():
			continue
		if bool(card.get("passive", false)):
			host._passive_firepit_surface()._update_passive_card_static_state(card, skill_id, action, host._activity_unlock_runtime()._is_action_unlocked(skill_id, action))
		elif bool(card.get("is_fishing_method", false)) or bool(card.get("is_fishing_area", false)):
			continue
		else:
			host._skill_swipe_activity_surface()._update_action_card_static_state(card, skill_id, action, host._activity_unlock_runtime()._is_action_unlocked(skill_id, action))
	if preview_id.is_empty():
		return true
	if play_preview_in_place(preview_id):
		return true
	return false


func play_preview_in_place(preview_id: String) -> bool:
	var preview_card = activity_preview_card_for_action_id(preview_id, true)
	if preview_card.is_empty() and host._skill_detail_surface()._ensure_activity_unlock_preview_lazy_entry(preview_id):
		preview_card = activity_preview_card_for_action_id(preview_id, true)
	if preview_card.is_empty():
		return false
	var preview_action = preview_card.get("action", {}) as Dictionary
	if preview_action.is_empty():
		preview_action = host._action_data(host.selected_skill_id, preview_id)
	if preview_action.is_empty():
		return false
	preview_card["unlock_next_preview_smooth"] = true
	if not bool(preview_staged_action_ids.get(preview_id, false)):
		stage_preview_once(preview_id, preview_card, false)
	if not claim_preview_play(preview_id):
		reveal_locked_activity_card_in_place(preview_card, host.selected_skill_id, preview_action)
		Callable(host._skill_detail_surface(), "_sync_detail_actions_scroll_limit_deferred").call_deferred()
		return true
	host._skill_swipe_activity_surface()._play_activity_preview_fade_in(preview_card)
	Callable(host._skill_detail_surface(), "_sync_detail_actions_scroll_limit_deferred").call_deferred()
	return true


func refresh_skill_detail_after_ceremony() -> void:
	if ceremony_count > 0:
		detail_refresh_done = false
		return
	if detail_refresh_done:
		return
	detail_refresh_done = true
	if host.current_screen != "skill":
		set_preview_after_ceremony("")
		heist_preview_after_ceremony_id = ""
		center_scroll_target = -1
		host.fishing_auto_unlock_waiting_for_detail_refresh = false
		return
	var preview_id = preview_after_ceremony_id
	var heist_preview_id = heist_preview_after_ceremony_id
	set_preview_after_ceremony("")
	heist_preview_after_ceremony_id = ""
	center_scroll_target = -1
	if not heist_preview_id.is_empty():
		var heist_refresh_scroll = host._skill_detail_surface().detail_actions_scroll.scroll_vertical if host._skill_detail_surface().detail_actions_scroll != null else -1
		await host._skill_detail_surface()._refresh_visible_skill_detail_action_list(heist_refresh_scroll, host.selected_skill_id)
		host.fishing_auto_unlock_waiting_for_detail_refresh = false
		if host.auto_unlock_lockpads_enabled:
			host._activity_unlock_runtime().call_deferred("_auto_unlock_pending_lockpads")
		return
	if apply_skill_detail_refresh_in_place(preview_id):
		host.fishing_auto_unlock_waiting_for_detail_refresh = false
		if host.auto_unlock_lockpads_enabled:
			host._activity_unlock_runtime().call_deferred("_auto_unlock_pending_lockpads")
		return
	var ceremony_refresh_scroll = host._skill_detail_surface().detail_actions_scroll.scroll_vertical if host._skill_detail_surface().detail_actions_scroll != null else -1
	await host._skill_detail_surface()._refresh_visible_skill_detail_action_list(ceremony_refresh_scroll, host.selected_skill_id)
	if host._fishing_rework_active_for_skill(host.selected_skill_id):
		host._fishing_ui_surface()._ensure_queued_fishing_unlock_entries_mounted()
	if not preview_id.is_empty():
		if not play_preview_in_place(preview_id):
			var preview_card = activity_preview_card_for_action_id(preview_id)
			if not preview_card.is_empty():
				var preview_action = preview_card.get("action", {}) as Dictionary
				if preview_action.is_empty():
					preview_action = host._action_data(host.selected_skill_id, preview_id)
				reveal_locked_activity_card_in_place(preview_card, host.selected_skill_id, preview_action)
	host.fishing_auto_unlock_waiting_for_detail_refresh = false
	if host.auto_unlock_lockpads_enabled:
		host._activity_unlock_runtime().call_deferred("_auto_unlock_pending_lockpads")


func activity_preview_card_for_action_id(action_id: String, ensure_lazy_mount = false) -> Dictionary:
	if action_id.is_empty():
		return {}
	if ensure_lazy_mount:
		host._skill_detail_surface()._ensure_detail_lazy_entry_mounted(action_id)
	var key = host._action_key(host.selected_skill_id, action_id)
	if host.action_cards.has(key):
		var card = host.action_cards[key] as Dictionary
		var root = host._app_lifecycle_runtime().valid_control_ref(card.get("root"))
		if card != null and root != null:
			return card
		host._skill_detail_surface()._discard_action_card_key(key)
	if host.selected_skill_id == "fishing":
		var area_card = host._fishing_ui_surface()._fishing_area_card_for_action(host.selected_skill_id, action_id)
		if not area_card.is_empty() and host._app_lifecycle_runtime().valid_control_ref(area_card.get("root")) != null:
			return area_card
	return {}


func stage_preview_for_action_id(action_id: String, collapse_height = true) -> bool:
	var card = activity_preview_card_for_action_id(action_id, true)
	if card.is_empty():
		return false
	if bool(card.get("unlock_next_preview_pending", false)):
		return true
	card["unlock_next_preview_smooth"] = true
	if not stage_preview_once(action_id, card, collapse_height):
		stage_preview_enter(card, collapse_height)
	card["fade_in_pending"] = true
	card["unlock_next_preview_pending"] = true
	return true


func stage_next_locked_preview(collapse_height = false) -> bool:
	var preview_id = preview_after_ceremony_id
	if preview_id.is_empty():
		return false
	if not stage_preview_for_action_id(preview_id, collapse_height):
		return false
	set_preview_after_ceremony("")
	detail_refresh_done = true
	return true


func fade_staged_next_locked_preview(action_id: String) -> void:
	await host.get_tree().create_timer(NEXT_PREVIEW_FADE_DELAY).timeout
	if host.current_screen != "skill" or action_id.is_empty():
		return
	var card = activity_preview_card_for_action_id(action_id)
	if card.is_empty():
		return
	if not bool(card.get("unlock_next_preview_pending", false)):
		return
	card.erase("unlock_next_preview_pending")
	if not claim_preview_play(action_id):
		return
	host._skill_swipe_activity_surface()._play_activity_preview_fade_in(card)


func play_next_locked_preview_fade(_collapse_height = false) -> bool:
	var preview_id = preview_after_ceremony_id
	if preview_id.is_empty():
		return false
	var card = activity_preview_card_for_action_id(preview_id, true)
	if card.is_empty():
		return false
	if not bool(card.get("unlock_next_preview_pending", false)):
		card["unlock_next_preview_smooth"] = true
		stage_preview_enter(card, false)
		card["fade_in_pending"] = true
	card.erase("unlock_next_preview_pending")
	if not claim_preview_play(preview_id):
		set_preview_after_ceremony("")
		return true
	host._skill_swipe_activity_surface()._play_activity_preview_fade_in(card)
	set_preview_after_ceremony("")
	center_scroll_target = -1
	detail_refresh_done = true
	Callable(host._skill_detail_surface(), "_sync_detail_actions_scroll_limit_deferred").call_deferred()
	return true
