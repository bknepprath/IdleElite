extends RefCounted

const TEMPORARY_EVENT_ENTRY_EXPAND_SECONDS := 0.62
const TEMPORARY_EVENT_ENTRY_FADE_SECONDS := 0.42
const TEMPORARY_EVENT_ENTRY_FADE_DELAY_SECONDS := 0.06

var host


func _init(host_ref) -> void:
	host = host_ref


func _detail_lazy_find_temporary_event_plan_index(plan: Array, event_id: String) -> int:
	if event_id.is_empty():
		return -1
	for index in range(plan.size()):
		var lazy_entry := plan[index] as Dictionary
		if str(lazy_entry.get("track_id", "")) != event_id:
			continue
		if str(lazy_entry.get("kind", "")) != "action":
			continue
		var entry := lazy_entry.get("entry", {}) as Dictionary
		var action := entry.get("action", {}) as Dictionary
		if host._is_event_action(action):
			return index
	return -1


func _set_temporary_event_entry_height(entry_host: Control, height: float) -> void:
	if entry_host == null or not is_instance_valid(entry_host) or entry_host.is_queued_for_deletion():
		return
	var clamped_height := maxf(0.0, height)
	var next_minimum_size := entry_host.custom_minimum_size
	if absf(next_minimum_size.y - clamped_height) > 0.5:
		next_minimum_size.y = clamped_height
		entry_host.custom_minimum_size = next_minimum_size
	if absf(entry_host.size.y - clamped_height) > 0.5:
		entry_host.size.y = clamped_height
	entry_host.update_minimum_size()


func _set_temporary_event_entry_height_safe(height: float, host_id: int) -> void:
	var entry_host: Control = host._valid_control_ref(instance_from_id(host_id))
	_set_temporary_event_entry_height(entry_host, height)


func _finish_temporary_event_entry_reveal(host_id: int, fade_target_id: int, target_height: float) -> void:
	var entry_host: Control = host._valid_control_ref(instance_from_id(host_id))
	if entry_host != null and not entry_host.is_queued_for_deletion():
		_set_temporary_event_entry_height(entry_host, target_height)
		entry_host.clip_contents = false
		if entry_host.has_meta("temporary_event_entry_tween"):
			entry_host.remove_meta("temporary_event_entry_tween")
	var fade_target: Control = host._valid_control_ref(instance_from_id(fade_target_id))
	if fade_target != null and not fade_target.is_queued_for_deletion():
		fade_target.modulate.a = 1.0
	host.call_deferred("_sync_detail_actions_scroll_limit_deferred")


func _play_temporary_event_entry_reveal(entry_host: Control, fade_target: Control, target_height: float) -> void:
	if entry_host == null or not is_instance_valid(entry_host):
		return
	host._kill_meta_tween(entry_host, "temporary_event_entry_tween")
	entry_host.clip_contents = true
	_set_temporary_event_entry_height(entry_host, 0.0)
	if fade_target != null and is_instance_valid(fade_target):
		fade_target.modulate.a = 0.0
	var fade_target_id := fade_target.get_instance_id() if fade_target != null and is_instance_valid(fade_target) else 0
	var host_id := entry_host.get_instance_id()
	var tween: Tween = host.create_tween()
	entry_host.set_meta("temporary_event_entry_tween", tween)
	tween.set_parallel(true)
	tween.tween_method(
		_set_temporary_event_entry_height_safe.bind(host_id),
		0.0,
		target_height,
		TEMPORARY_EVENT_ENTRY_EXPAND_SECONDS
	).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	if fade_target != null and is_instance_valid(fade_target):
		tween.tween_property(
			fade_target,
			"modulate:a",
			1.0,
			TEMPORARY_EVENT_ENTRY_FADE_SECONDS
		).set_delay(TEMPORARY_EVENT_ENTRY_FADE_DELAY_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	tween.tween_callback(_finish_temporary_event_entry_reveal.bind(host_id, fade_target_id, target_height))


func _detail_lazy_insert_animated_temporary_event_entry(
	stack: VBoxContainer,
	skill_id: String,
	event_entry: Dictionary,
	plan_index: int,
	content_width: float,
	actions_width: float
) -> bool:
	host._detail_lazy_create_slot_for_entry(stack, skill_id, event_entry, content_width, actions_width)
	var entry_host: Control = host._valid_control_ref(event_entry.get("stack_host"))
	if entry_host == null or not is_instance_valid(entry_host):
		return false
	var insert_index: int = host._detail_lazy_stack_insert_index_for_plan_index(stack, plan_index)
	stack.move_child(entry_host, clampi(insert_index, 0, maxi(0, stack.get_child_count() - 1)))
	var target_height := maxf(1.0, float(event_entry.get("height", host._activity_card_root_height())))
	entry_host.clip_contents = true
	_set_temporary_event_entry_height(entry_host, 0.0)
	if not host._skill_detail_surface()._detail_lazy_mount_item(event_entry, skill_id, content_width, actions_width, false):
		host._detail_lazy_remove_unmounted_inserted_host(event_entry)
		return false
	entry_host = host._valid_control_ref(event_entry.get("stack_host"))
	if entry_host == null or not is_instance_valid(entry_host):
		return false
	var fade_target: Control = host._detail_lazy_primary_child_control(entry_host)
	_play_temporary_event_entry_reveal(entry_host, fade_target, target_height)
	return true


func _animate_temporary_event_entry_if_visible(event_def: Dictionary, event_id: String) -> bool:
	var skill_id := str(event_def.get("page", ""))
	if event_id.is_empty() or skill_id.is_empty():
		return false
	if host.current_screen != "skill" or host.selected_skill_id != skill_id:
		return false
	if host.screen_render_in_progress or host.boot_detail_render_in_progress or host._skill_swipe_navigation_blocks_detail_refresh():
		return false
	if host.skill_swipe_pending_full_finalize or host._skill_swipe_handoff_cover_is_opaque_cream_transition():
		return false
	if host.detail_actions_scroll == null or not is_instance_valid(host.detail_actions_scroll):
		return false
	var stack: VBoxContainer = host.detail_lazy_stack
	if stack == null or not is_instance_valid(stack):
		stack = host._detail_actions_stack() as VBoxContainer
	if stack == null or not is_instance_valid(stack):
		return false
	if host.detail_lazy_plan.is_empty() or not host._skill_detail_stack_has_visible_modules(stack):
		return false
	if host.detail_rendered_action_ids.has(event_id) or host.detail_action_card_nodes.has(event_id):
		return true
	var plan_data: Dictionary = host._detail_lazy_plan_and_signature_for_skill(skill_id)
	var new_plan := plan_data.get("plan", []) as Array
	var new_signature := plan_data.get("signature", []) as Array
	var event_index := _detail_lazy_find_temporary_event_plan_index(new_plan, event_id)
	if event_index < 0:
		return false
	var old_entries_by_track_id: Dictionary = host._detail_lazy_runtime_entries_by_track_id(host.detail_lazy_plan)
	for raw_new_entry in new_plan:
		var new_entry := raw_new_entry as Dictionary
		var track_id := str(new_entry.get("track_id", ""))
		if track_id == event_id or not old_entries_by_track_id.has(track_id):
			continue
		host._detail_lazy_copy_runtime_entry_state(new_entry, old_entries_by_track_id[track_id] as Dictionary)
	var event_entry := new_plan[event_index] as Dictionary
	var content_width: float = host._skill_content_width()
	var actions_width: float = content_width
	var layout_snapshot: Dictionary = host._capture_detail_module_layout_snapshot()
	if not _detail_lazy_insert_animated_temporary_event_entry(stack, skill_id, event_entry, event_index, content_width, actions_width):
		return false
	host._detail_lazy_reorder_existing_hosts_for_plan(stack, new_plan, event_id)
	host.detail_lazy_stack = stack
	host.detail_lazy_plan = new_plan
	host.detail_rendered_action_ids = new_signature
	host.detail_lazy_last_scroll = host._detail_lazy_scroll_y()
	host._hold_skill_detail_layout_refresh(
		TEMPORARY_EVENT_ENTRY_EXPAND_SECONDS
		+ TEMPORARY_EVENT_ENTRY_FADE_DELAY_SECONDS
		+ TEMPORARY_EVENT_ENTRY_FADE_SECONDS
		+ 0.16
	)
	host._sync_current_skill_strip_detail_refs()
	if not layout_snapshot.is_empty():
		host._skill_detail_surface().call_deferred("_play_detail_module_layout_transition", layout_snapshot)
	host.call_deferred("_sync_detail_actions_scroll_limit_deferred")
	return true


func _play_temporary_event_completion_exit(skill_id: String, action_id: String, xp_reward: int) -> void:
	var action_key: String = host._action_key(skill_id, action_id)
	var card := host.action_cards.get(action_key, {}) as Dictionary
	var root: Control = host._valid_control_ref(card.get("root"))
	var pop: Control = host._valid_control_ref(card.get("pop"))
	var art_panel: Control = host._valid_control_ref(card.get("art_panel"))
	if root == null or not root.is_inside_tree():
		call_deferred("_refresh_skill_detail_after_temporary_event_despawn", skill_id)
		return
	_float_temporary_event_completion_popup(skill_id, action_id, xp_reward)
	host._hold_skill_detail_layout_refresh(2.55)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.clip_contents = true
	var restore_scroll: int = host.detail_actions_scroll.scroll_vertical if host.detail_actions_scroll != null else -1
	var start_height := maxf(root.custom_minimum_size.y, root.size.y)
	var tint_target: Control = pop if pop != null else root
	if tint_target != null:
		tint_target.pivot_offset = tint_target.size * 0.5
		host._set_canvas_item_modulate_if_changed(tint_target, Color("#9cff9e"))
	if art_panel != null:
		host._reward_feedback_surface()._flash_art_glow(art_panel, Color("#35d86d"))
	var tween: Tween = host.create_tween()
	tween.set_parallel(true)
	if tint_target != null:
		tween.tween_property(tint_target, "scale", Vector2(1.035, 1.035), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(tint_target, "modulate", Color.WHITE, 0.68).set_delay(0.28)
	tween.tween_property(root, "modulate:a", 1.0, 0.01)
	tween.chain().tween_interval(0.74)
	if tint_target != null:
		tween.tween_property(tint_target, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(root, "modulate:a", 0.0, 0.60).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(root, "custom_minimum_size:y", 0.0, 0.56).from(start_height).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	tween.chain().tween_callback(_finish_temporary_event_completion_exit.bind(action_key, restore_scroll))


func _float_temporary_event_completion_popup(skill_id: String, action_id: String, xp_reward: int) -> void:
	var action_key: String = host._action_key(skill_id, action_id)
	var reward_text := "+%s XP" % GameFormatting.compact_number(float(xp_reward), 4) if xp_reward > 0 else "Reward!"
	host._reward_feedback_surface()._float_action_card_warning_feedback(action_key, "Complete!\n%s" % reward_text, Color("#35d86d"))


func _finish_temporary_event_completion_exit(card_key: String, restore_scroll: int) -> void:
	var card := host.action_cards.get(card_key, {}) as Dictionary
	var root: Control = host._valid_control_ref(card.get("root"))
	if root != null:
		root.visible = false
		root.custom_minimum_size = Vector2(root.custom_minimum_size.x, 0.0)
	_refresh_skill_detail_after_temporary_event_despawn(host._reward_feedback_surface()._skill_id_from_action_key(card_key), restore_scroll)


func _refresh_skill_detail_after_temporary_event_despawn(skill_id: String, restore_scroll := -1) -> void:
	if host.current_screen != "skill" or host.selected_skill_id != skill_id:
		host._update_ui(0.0, false)
		return
	var event_refresh_scroll: int = restore_scroll if restore_scroll >= 0 else (host.detail_actions_scroll.scroll_vertical if host.detail_actions_scroll != null else -1)
	await host._refresh_visible_skill_detail_action_list(event_refresh_scroll, skill_id, true)
