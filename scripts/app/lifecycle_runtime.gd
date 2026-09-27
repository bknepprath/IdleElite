extends RefCounted

const ActivityCardStyles = preload("res://scripts/ui/activity_card_styles.gd")
const AchievementPresentation = preload("res://scripts/achievements/presentation.gd")
const NavigationShell = preload("res://scripts/ui/navigation_shell.gd")
const PROCESS_SUSPENSION_MIN_MSEC := 5000
const LIFECYCLE_SAVE_DEBOUNCE_MSEC := 1500

var host
var lazy_overlays_built := {}
var last_process_unix_time := 0
var last_process_monotonic_msec := -1
var last_lifecycle_save_monotonic_msec := -1
var last_lifecycle_save_succeeded := false
var last_lifecycle_save_was_deferred := false


func _init(host_ref) -> void:
	host = host_ref


func lazy_overlay_built(key: String) -> bool:
	return bool(lazy_overlays_built.get(key, false))


func mark_lazy_overlay_built(key: String) -> void:
	lazy_overlays_built[key] = true


func clear_lazy_overlay_registry() -> void:
	lazy_overlays_built.clear()


func state_object_ref(value) -> Object:
	if value == null:
		return null
	if typeof(value) != TYPE_OBJECT or not is_instance_valid(value):
		return null
	return value


func valid_control_ref(value) -> Control:
	var object := state_object_ref(value)
	if object == null:
		return null
	return object as Control


func valid_texture_button_ref(value) -> TextureButton:
	var control := valid_control_ref(value)
	if control == null:
		return null
	return control as TextureButton


func valid_node_ref(value) -> Node:
	var object := state_object_ref(value)
	if object == null:
		return null
	return object as Node


func valid_canvas_item_ref(value) -> CanvasItem:
	var object := state_object_ref(value)
	if object == null:
		return null
	return object as CanvasItem


func valid_texture_rect_ref(value) -> TextureRect:
	var control := valid_control_ref(value)
	if control == null:
		return null
	return control as TextureRect


func valid_texture_progress_ref(value) -> TextureProgressBar:
	var control := valid_control_ref(value)
	if control == null:
		return null
	return control as TextureProgressBar


func valid_label_ref(value) -> Label:
	var control := valid_control_ref(value)
	if control == null:
		return null
	return control as Label


func valid_base_button_ref(value) -> BaseButton:
	var object := state_object_ref(value)
	if object == null:
		return null
	return object as BaseButton


func valid_button_ref(value) -> Button:
	var control := valid_control_ref(value)
	if control == null:
		return null
	return control as Button


func meta_vector2(node: Object, meta_name, fallback: Vector2 = Vector2.ZERO) -> Vector2:
	if node == null or not is_instance_valid(node) or not node.has_meta(meta_name):
		return fallback
	var value = node.get_meta(meta_name)
	if value is Vector2:
		return value
	return fallback


func weak_object_ref(value) -> WeakRef:
	var object := state_object_ref(value)
	if object == null:
		return null
	return weakref(object)


func weak_ref_value(weak_ref: WeakRef) -> Variant:
	if weak_ref == null:
		return null
	return weak_ref.get_ref()


func control_effectively_visible(control: Control, minimum_alpha := 0.05) -> bool:
	if control == null or not is_instance_valid(control) or not control.is_visible_in_tree():
		return false
	var alpha := 1.0
	var current: Node = control
	while current != null:
		if current is CanvasItem:
			var canvas_item := current as CanvasItem
			alpha *= canvas_item.modulate.a * canvas_item.self_modulate.a
			if alpha <= minimum_alpha:
				return false
		current = current.get_parent()
	return true


func set_label_text_if_changed(label: Label, next_text: String) -> void:
	if label != null and is_instance_valid(label) and not label.is_queued_for_deletion() and label.text != next_text:
		label.text = next_text


func set_button_text_if_changed(button: Button, next_text: String) -> void:
	if button != null and is_instance_valid(button) and not button.is_queued_for_deletion() and button.text != next_text:
		button.text = next_text


func colors_close_enough(current: Color, next: Color) -> bool:
	return (
		absf(current.r - next.r) <= 0.001
		and absf(current.g - next.g) <= 0.001
		and absf(current.b - next.b) <= 0.001
		and absf(current.a - next.a) <= 0.001
	)


func set_canvas_item_visible_if_changed(item: CanvasItem, should_show: bool) -> void:
	if item != null and is_instance_valid(item) and not item.is_queued_for_deletion() and item.visible != should_show:
		item.visible = should_show


func set_canvas_item_modulate_if_changed(item: CanvasItem, next_modulate: Color) -> void:
	if item != null and is_instance_valid(item) and not item.is_queued_for_deletion() and not colors_close_enough(item.modulate, next_modulate):
		item.modulate = next_modulate


func set_canvas_item_alpha_if_changed(item: CanvasItem, next_alpha: float) -> void:
	if item == null or not is_instance_valid(item) or item.is_queued_for_deletion():
		return
	var clamped_alpha := clampf(next_alpha, 0.0, 1.0)
	if absf(item.modulate.a - clamped_alpha) <= 0.001:
		return
	var next_modulate := item.modulate
	next_modulate.a = clamped_alpha
	item.modulate = next_modulate


func set_base_button_disabled_if_changed(button: BaseButton, should_disable: bool) -> void:
	if button != null and is_instance_valid(button) and not button.is_queued_for_deletion() and button.disabled != should_disable:
		button.disabled = should_disable


func set_canvas_item_alpha_safe(alpha: float, canvas_item_id: int) -> void:
	var canvas_item := valid_canvas_item_ref(instance_from_id(canvas_item_id))
	if canvas_item == null or canvas_item.is_queued_for_deletion():
		return
	set_canvas_item_alpha_if_changed(canvas_item, alpha)


func set_control_minimum_height_safe(height: float, control_id: int) -> void:
	var control := valid_control_ref(instance_from_id(control_id))
	if control == null or control.is_queued_for_deletion():
		return
	set_control_minimum_height(control, height)


func set_control_minimum_height(control: Control, height: float) -> void:
	if control == null or not is_instance_valid(control) or control.is_queued_for_deletion():
		return
	var clamped_height := maxf(0.0, height)
	var next_minimum_size := control.custom_minimum_size
	var changed := absf(next_minimum_size.y - clamped_height) > 0.5
	if changed:
		next_minimum_size.y = clamped_height
		control.custom_minimum_size = next_minimum_size
	if clamped_height <= 1.0 or control.size.y < clamped_height:
		control.size.y = clamped_height
		changed = true
	if changed:
		control.update_minimum_size()


func process_background_maintenance(delta: float) -> void:
	host.background_maintenance_elapsed += maxf(0.0, delta)
	if host.background_maintenance_pending_delta <= 0.0:
		if host.background_maintenance_elapsed < host.BACKGROUND_MAINTENANCE_INTERVAL_SECONDS:
			return
		host.background_maintenance_pending_delta = host.background_maintenance_elapsed
		host.background_maintenance_elapsed = 0.0
		host.background_maintenance_step_index = 0
	var step_index: int = host.background_maintenance_step_index % host.BACKGROUND_MAINTENANCE_STEP_COUNT
	process_background_maintenance_step(step_index, host.background_maintenance_pending_delta)
	host.background_maintenance_step_index = step_index + 1
	if host.background_maintenance_step_index >= host.BACKGROUND_MAINTENANCE_STEP_COUNT:
		host.background_maintenance_step_index = 0
		host.background_maintenance_pending_delta = 0.0


func process_background_maintenance_step(step_index: int, maintenance_delta: float) -> void:
	match step_index:
		0:
			host._crash_report_runtime().process_session_heartbeat(maintenance_delta)
		1:
			host._ad_bonus_runtime().process(maintenance_delta)
		2:
			host._passive_modules_runtime().process_passive_modules(host._unix_now())
		3:
			host._convergence_runtime()._process_convergence_modules()
		4:
			host._hub_surface()._process_hub_modules(maintenance_delta)
		5:
			host._thieving_surface()._process_thieving_action_jails()
		6:
			host._online_runtime().process(maintenance_delta)


static func process_suspension_seconds(previous_unix: int, now_unix: int, previous_msec: int, now_msec: int) -> int:
	var wall_elapsed := maxi(0, now_unix - previous_unix)
	if previous_unix <= 0 or previous_msec < 0:
		return 0
	if wall_elapsed < PROCESS_SUSPENSION_MIN_MSEC / 1000 and now_msec - previous_msec < PROCESS_SUSPENSION_MIN_MSEC:
		return 0
	return wall_elapsed


func recover_suspended_process() -> bool:
	var now_unix: int = host._unix_now()
	var now_msec: int = Time.get_ticks_msec()
	var offline_seconds: int = process_suspension_seconds(last_process_unix_time, now_unix, last_process_monotonic_msec, now_msec)
	last_process_unix_time = now_unix
	last_process_monotonic_msec = now_msec
	if offline_seconds <= 0:
		return false
	_resume_from_app_suspend(now_unix - offline_seconds)
	return true


func handle_notification(what: int) -> void:
	if what == host.NOTIFICATION_WM_GO_BACK_REQUEST:
		host._input_routing_shell()._handle_system_back_request()
	elif what == host.NOTIFICATION_WM_CLOSE_REQUEST:
		_save_for_app_suspend()
		_prepare_for_shutdown()
	elif what == host.NOTIFICATION_APPLICATION_FOCUS_OUT:
		_save_for_app_suspend()
	elif what == host.NOTIFICATION_APPLICATION_FOCUS_IN:
		if _app_lifecycle_uses_focus_resume():
			_resume_from_app_suspend()
		else:
			host._crash_report_runtime().write_session_marker("running")
	elif what == host.NOTIFICATION_APPLICATION_PAUSED:
		_save_for_app_suspend()
	elif what == host.NOTIFICATION_APPLICATION_RESUMED:
		_resume_from_app_suspend()
	elif what == host.NOTIFICATION_PREDELETE:
		_prepare_for_shutdown()


func _prepare_for_shutdown() -> void:
	if host.shutdown_cleanup_started:
		return
	host.shutdown_cleanup_started = true
	_write_lifecycle_save_marker(_persist_for_lifecycle())
	host._skill_detail_surface()._clear_detail_lazy_cached_roots()
	host._skill_swipe_activity_surface()._free_global_swipe_real_card_cache()
	host._navigation_shell().pending_skill_detail_refresh_request.clear()
	host.startup_initialized = false
	host.deferred_skill_validation_pending = false
	host._boot_warmup_runtime().reset_for_shutdown()
	if host.online_runtime != null and is_instance_valid(host.online_runtime):
		host.online_runtime._chat_stream_disconnect(false)
	_kill_transient_tweens_in_subtree(host)
	_kill_shutdown_global_tweens()
	_kill_action_card_shutdown_tweens()
	if host.achievement_overlay_surface != null:
		host.achievement_overlay_surface.invalidate_home_page()
	host._skill_swipe_activity_surface()._cancel_preview_prewarm()
	host._skill_swipe_activity_surface().preview_module_reveal_token += 1
	host.app_boot_warmup_runtime = null
	clear_lazy_overlay_registry()
	host._save_runtime().pending_post_load_saved_at = -1
	host._save_runtime().pending_save_restore_data = {}
	host._save_runtime().pending_save_has_achievement_toast_seen_ids = false
	host._save_runtime().save_repaired_this_boot = false
	if host.online_runtime != null and is_instance_valid(host.online_runtime):
		host.online_runtime.chat_stream_poll_timer = null
		host.online_runtime.leaderboard_http_built = false
	host.online_runtime = null
	if host.audio_director != null and is_instance_valid(host.audio_director):
		host.audio_director.reset_runtime_caches()
	host.audio_director = null
	var stop_hold_layer: Node = host.get_node_or_null("ActionStopHoldLayer")
	if stop_hold_layer != null:
		stop_hold_layer.queue_free()
	host._achievement_toast_surface().reset_for_shutdown()
	if host.settings_surface != null:
		host.settings_surface._clear_notification_settings_notice_immediate()
	host.settings_surface = null
	host.tutorial_layer = null
	host.tutorial_overlay = null
	host._performance_runtime().clear_monitor_reference()
	host.performance_runtime = null
	host._profile_chat_overlay_surface().reset_chat_overlay_refs()
	host._profile_chat_overlay_surface()._reset_profile_overlay_refs()
	host._fishing_ui_surface().clear_fishing_collection_canvas_cache()
	host._fishing_ui_surface().reset_wallet_refs_for_shutdown()
	host.home_page = null
	host.skills_page = null
	host._navigation_shell().nav_bar = null
	host.content_scroll = null
	if host.achievement_overlay_surface != null:
		host.achievement_overlay_surface.reset_home_scroll_ref()
	host.skills_content = null
	host.visual_texture_cache.texture_cache.clear()
	host.visual_texture_cache.atlas_texture_cache.clear()
	AchievementPresentation.clear_cache()
	host.paper_button_style_textures.clear()
	ActivityCardStyles.clear_cache()
	host.summary_style_cache = null
	host._skill_swipe_activity_surface()._clear_light_preview_style_cache()
	host._thieving_surface().clear_visual_caches()
	host.mastery_medal_dot_texture = null
	host.app_font = null
	host.app_bold_font = null
	if DisplayServer.get_name() == "headless" and host.is_inside_tree():
		host.get_tree().quit()


func _runtime_save_is_safe() -> bool:
	return host.save_restore_complete


func _mobile_lifecycle_uses_focus_resume() -> bool:
	return OS.get_name() == "Android" or OS.get_name() == "iOS"


func _app_lifecycle_uses_focus_resume() -> bool:
	return _mobile_lifecycle_uses_focus_resume() or OS.get_name() == "Web" or OS.has_feature("web")


func _save_for_app_suspend() -> void:
	if host.shutdown_cleanup_started:
		return
	host._clear_page_transient_input_state(true)
	host._audio_director()._pause_music_for_app_suspend()
	_write_lifecycle_save_marker(_persist_for_lifecycle())


func _persist_for_lifecycle() -> int:
	if host._save_runtime().save_writes_blocked:
		last_lifecycle_save_was_deferred = false
		last_lifecycle_save_succeeded = false
		return -1
	if not _runtime_save_is_safe():
		last_lifecycle_save_was_deferred = true
		last_lifecycle_save_succeeded = false
		return 0
	var now_msec := Time.get_ticks_msec()
	if last_lifecycle_save_succeeded and last_lifecycle_save_monotonic_msec >= 0 and now_msec - last_lifecycle_save_monotonic_msec <= LIFECYCLE_SAVE_DEBOUNCE_MSEC:
		return 1
	last_lifecycle_save_monotonic_msec = now_msec
	last_lifecycle_save_was_deferred = false
	last_lifecycle_save_succeeded = host.save_game()
	return 1 if last_lifecycle_save_succeeded else -1


func _write_lifecycle_save_marker(outcome: int) -> void:
	if outcome > 0:
		host._crash_report_runtime().write_session_marker("clean")
	elif outcome == 0:
		host._crash_report_runtime().write_session_marker("clean_save_deferred")
	else:
		host._crash_report_runtime().write_session_marker("save_failed")


func _resume_from_app_suspend(offline_from_unix := -1) -> void:
	last_process_unix_time = host._unix_now()
	last_process_monotonic_msec = Time.get_ticks_msec()
	last_lifecycle_save_monotonic_msec = -1
	last_lifecycle_save_succeeded = false
	last_lifecycle_save_was_deferred = false
	host._crash_report_runtime().write_session_marker("running")
	host._performance_runtime()._record_battery_governor_activity()
	host._navigation_shell()._clear_page_switch_input_state(true)
	if not host.startup_initialized:
		host.app_resume_repair_pending = true
		host._audio_director()._restart_music_after_app_resume()
		return
	if not _runtime_save_is_safe():
		host._audio_director()._restart_music_after_app_resume()
		return
	var now: int = host._unix_now()
	var saved_at: int = host._save_runtime().last_save_unix_time if offline_from_unix < 0 else offline_from_unix
	var offline_progressed: bool = host._save_runtime()._apply_offline_progress(saved_at) > 0
	if host.offline_progress_enabled:
		host._passive_modules_runtime().apply_passive_module_production(now)
		host._passive_modules_runtime().apply_firepit_fuel(now)
	else:
		host._passive_modules_runtime().reset_passive_module_timestamps(now)
	if offline_progressed:
		host._update_ui(0.0, true)
		host.save_game()
	call_deferred("_repair_after_app_resume")
	host._audio_director()._restart_music_after_app_resume()


func _repair_after_app_resume():
	if not host.is_inside_tree():
		return
	if not host.startup_initialized:
		host.app_resume_repair_pending = true
		return
	if host._boot_warmup_runtime().active or host.boot_detail_render_in_progress or host._navigation_shell().screen_render_in_progress:
		host.app_resume_repair_pending = true
		call_deferred("_repair_after_app_resume")
		return
	host.app_resume_repair_pending = false
	if host.home_page == null or host.skills_page == null:
		return
	if host.current_screen != "home" and host.skills_content != null and host.skills_content.get_child_count() == 0:
		await host._navigation_shell()._render_screen(false, -1, false)
	elif host.current_screen == "skill":
		var stack := host._detail_actions_stack() as Control
		if stack == null or not host._skill_detail_stack_is_presentable(stack):
			host._skill_swipe_activity_surface()._force_skill_detail_reveal_mount_under_cover()
			stack = host._detail_actions_stack() as Control
			if stack == null or not host._skill_detail_stack_is_presentable(stack):
				await host._skill_detail_surface()._refresh_visible_skill_detail_action_list(-1, host.selected_skill_id, true, true)
	host._navigation_shell()._update_page_visibility()
	host._update_ui(0.0, true)
	_queue_resume_redraw(host)


func _queue_resume_redraw(node: Node) -> void:
	if node is CanvasItem:
		(node as CanvasItem).queue_redraw()
	for child in node.get_children():
		_queue_resume_redraw(child)


func _kill_transient_tweens_in_subtree(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	if node is Control:
		host._skill_detail_surface()._kill_detail_lazy_reveal_tween(node as Control)
	_kill_meta_tween(node, "depress_tween")
	if node is Button:
		host._settings_surface()._kill_reset_data_feedback_tween(node as Button)
	else:
		_kill_meta_tween(node, "reset_feedback_tween")
	_kill_meta_tween(node, "bonus_tween")
	_kill_meta_tween(node, "bonus_content_tween")
	_kill_meta_tween(node, "medal_ceremony_tween")
	_kill_meta_tween(node, "medal_outgoing_tween")
	_kill_meta_tween(node, "medal_tap_pop_tween")
	_kill_meta_tween(node, "medal_tap_effect_tween")
	_kill_meta_tween(node, "mastery_bar_tween")
	_kill_meta_tween(node, "activity_crit_text_tween")
	_kill_meta_tween(node, "hub_decor_pop_tween")
	_kill_meta_tween(node, "mat_flyer_tween")
	_kill_meta_tween(node, "mat_pulse_tween")
	for child in node.get_children():
		_kill_transient_tweens_in_subtree(child)


func _clear_children(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	for child in node.get_children():
		_kill_transient_tweens_in_subtree(child)
		node.remove_child(child)
		child.queue_free()


func _kill_shutdown_global_tweens() -> void:
	host._skill_swipe_activity_surface()._clear_action_pop_tweens()
	host._reward_feedback_surface()._clear_action_crit_tweens()
	host._reward_feedback_surface()._clear_stamina_gauge_pop_tween()
	host._activity_unlock_ceremony_surface().clear_visual_scroll_tween()
	host._skill_swipe_activity_surface()._kill_skill_swipe_tween()
	_kill_tween_value(host._skill_detail_surface().detail_unlock_scroll_spacer_tween)
	host._skill_detail_surface().detail_unlock_scroll_spacer_tween = null
	var nav: NavigationShell = host._navigation_shell()
	_kill_tween_value(nav.hero_nav_fade_tween)
	nav.hero_nav_fade_tween = null
	_kill_tween_value(nav.hub_nav_fade_tween)
	nav.hub_nav_fade_tween = null
	_kill_tween_value(nav.shop_nav_fade_tween)
	nav.shop_nav_fade_tween = null
	host._fishing_ui_surface().kill_wallet_pop_tween()
	host.button_press_runtime.clear_all_nav_pop_tweens()


func _kill_action_card_shutdown_tweens() -> void:
	for raw_card in host.action_cards.values():
		var card := raw_card as Dictionary
		host._skill_swipe_activity_surface()._clear_action_card_medal_tap_ceremony(card)
		_kill_card_tween(card, "preview_fade_tween")
		_kill_card_tween(card, "medal_ceremony_tween")
		_kill_card_tween(card, "medal_outgoing_tween")
		_kill_card_tween(card, "bonus_tween")
		_kill_card_tween(card, "bonus_content_tween")
		_kill_card_tween(card, "stat_fade_tween")
		_kill_card_tween(card, "depth_press_tween")


func _kill_card_tween(card: Dictionary, key: String) -> void:
	var tween = card.get(key, null)
	_kill_tween_value(tween)
	card.erase(key)


func _queue_free_instance_id(instance_id: int) -> void:
	var node: Node = valid_node_ref(instance_from_id(instance_id))
	if node != null:
		node.queue_free()


func _remove_meta_from_instance_id(instance_id: int, meta_name: StringName) -> void:
	var node: Node = valid_node_ref(instance_from_id(instance_id))
	if node != null and node.has_meta(meta_name):
		node.remove_meta(meta_name)


func _kill_meta_tween(node: Node, meta_name: String) -> void:
	if node == null or not is_instance_valid(node) or not node.has_meta(meta_name):
		return
	var tween = node.get_meta(meta_name)
	_kill_tween_value(tween)
	node.remove_meta(meta_name)


func _hide_control_bound(control_id: int) -> void:
	var control: Control = valid_control_ref(instance_from_id(control_id))
	if control != null:
		set_canvas_item_visible_if_changed(control, false)


func _kill_tween_value(tween) -> void:
	if tween != null and is_instance_valid(tween) and tween is Tween and tween.is_valid():
		tween.kill()
