extends RefCounted

const ActivityCardStyles = preload("res://scripts/ui/activity_card_styles.gd")

var host


func _init(host_ref) -> void:
	host = host_ref


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
	if _runtime_save_is_safe():
		host.save_game()
	host._crash_report_runtime().write_session_marker("clean")
	host._clear_detail_lazy_cached_roots()
	host._skill_swipe_activity_surface()._free_global_swipe_real_card_cache()
	host.pending_skill_detail_refresh_request.clear()
	host.startup_initialized = false
	host.deferred_skill_validation_pending = false
	host.boot_warmup_cancel_requested = true
	host.boot_warmup_active = false
	host.boot_warmup_game_revealed = false
	host.boot_warmup_show_msec = 0
	host.boot_warmup_hide_requested = false
	host._online_runtime()._chat_stream_disconnect(false)
	host._kill_transient_tweens_in_subtree(host)
	_kill_shutdown_global_tweens()
	_kill_action_card_shutdown_tweens()
	host._skill_swipe_activity_surface()._cancel_preview_prewarm()
	host._skill_swipe_activity_surface().preview_module_reveal_token += 1
	host.boot_warmup_layer = null
	host.boot_warmup_overlay = null
	host.boot_warmup_background = null
	host.boot_warmup_splash = null
	host.boot_warmup_shade = null
	host.boot_warmup_footer = null
	host.boot_warmup_label = null
	host.boot_warmup_progress = null
	host.boot_warmup_runtime = null
	host.lazy_overlays_built.clear()
	host.home_page_built = false
	host.pending_post_load_saved_at = -1
	host.pending_save_restore_data = {}
	host._save_runtime().pending_save_has_achievement_toast_seen_ids = false
	host.save_repaired_this_boot = false
	host.leaderboard_http_built = false
	host.online_runtime = null
	if host.audio_director != null and is_instance_valid(host.audio_director):
		host.audio_director.reset_runtime_caches()
	host.audio_director = null
	host.action_stop_hold_layer = null
	host.action_stop_hold_circle = null
	host._achievement_toast_surface().reset_for_shutdown()
	if host.settings_surface != null:
		host.settings_surface._clear_notification_settings_notice_immediate()
	host.settings_surface = null
	host.tutorial_layer = null
	host.tutorial_overlay = null
	host._performance_runtime().clear_monitor_reference()
	host.performance_runtime = null
	host.chat_overlay_layer = null
	host.chat_overlay = null
	host.chat_overlay_body = null
	host.chat_overlay_scroll = null
	host.chat_overlay_list = null
	host.chat_overlay_notice = null
	host.chat_overlay_row_nodes.clear()
	host.chat_overlay_row_signatures.clear()
	host.chat_overlay_shell_ready = false
	host.chat_profile_button = null
	host.chat_stream_poll_timer = null
	host._profile_chat_overlay_surface()._reset_profile_overlay_refs()
	host.fishing_collection_canvas = null
	host.fishing_tool_wallet_canvas = null
	host.fishing_tool_wallet_layer = null
	host.fishing_tool_wallet_popup = null
	host.home_page = null
	host.skills_page = null
	host.nav_bar = null
	host.content_scroll = null
	host.home_scroll = null
	host.skills_content = null
	host.texture_cache.clear()
	host.atlas_texture_cache.clear()
	host.AchievementPresentation.clear_cache()
	host.paper_button_style_textures.clear()
	ActivityCardStyles.clear_cache()
	host.summary_style_cache = null
	host._skill_swipe_activity_surface()._clear_light_preview_style_cache()
	host.thieving_heist_feather_shader = null
	host.mastery_medal_dot_texture = null
	host.thieving_action_jail_material = null
	host.app_font = null
	host.app_bold_font = null
	if DisplayServer.get_name() == "headless" and host.is_inside_tree():
		host.get_tree().quit()


func _runtime_save_is_safe() -> bool:
	return host.startup_initialized or host.loaded_save_this_boot


func _mobile_lifecycle_uses_focus_resume() -> bool:
	return OS.get_name() == "Android" or OS.get_name() == "iOS"


func _app_lifecycle_uses_focus_resume() -> bool:
	return _mobile_lifecycle_uses_focus_resume() or OS.get_name() == "Web" or OS.has_feature("web")


func _save_for_app_suspend() -> void:
	host._clear_page_switch_input_state(true)
	host._audio_director()._pause_music_for_app_suspend()
	if _runtime_save_is_safe():
		host.save_game()
	host._crash_report_runtime().write_session_marker("clean")


func _resume_from_app_suspend() -> void:
	host._crash_report_runtime().write_session_marker("running")
	host._performance_runtime()._record_battery_governor_activity()
	host._clear_page_switch_input_state(true)
	if not host.startup_initialized:
		host.app_resume_repair_pending = true
		host._audio_director()._restart_music_after_app_resume()
		return
	if not _runtime_save_is_safe():
		host._audio_director()._restart_music_after_app_resume()
		return
	var now: int = host._unix_now()
	var offline_progressed: bool = host._save_runtime()._apply_offline_progress(host.last_save_unix_time) > 0
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
	if host.boot_warmup_active or host.boot_detail_render_in_progress or host.screen_render_in_progress:
		host.app_resume_repair_pending = true
		call_deferred("_repair_after_app_resume")
		return
	host.app_resume_repair_pending = false
	if host.home_page == null or host.skills_page == null:
		return
	if host.current_screen != "home" and host.skills_content != null and host.skills_content.get_child_count() == 0:
		await host._render_screen(false, -1, false)
	elif host.current_screen == "skill":
		var stack := host._detail_actions_stack() as Control
		if stack == null or not host._skill_detail_stack_is_presentable(stack):
			host._force_skill_detail_reveal_mount_under_cover()
			stack = host._detail_actions_stack() as Control
			if stack == null or not host._skill_detail_stack_is_presentable(stack):
				await host._refresh_visible_skill_detail_action_list(-1, host.selected_skill_id, true, true)
	host._update_page_visibility()
	host._update_ui(0.0, true)
	_queue_resume_redraw(host)


func _queue_resume_redraw(node: Node) -> void:
	if node is CanvasItem:
		(node as CanvasItem).queue_redraw()
	for child in node.get_children():
		_queue_resume_redraw(child)


func _kill_shutdown_global_tweens() -> void:
	host._clear_action_pop_tweens()
	host._reward_feedback_surface()._clear_action_crit_tweens()
	host._clear_stamina_gauge_pop_tween()
	host._clear_activity_unlock_visual_scroll_tween()
	host._kill_skill_swipe_tween()
	if host.detail_unlock_scroll_spacer_tween != null and host.detail_unlock_scroll_spacer_tween.is_valid():
		host.detail_unlock_scroll_spacer_tween.kill()
	host.detail_unlock_scroll_spacer_tween = null
	var nav: NavigationShell = host._navigation_shell()
	if nav.hero_nav_fade_tween != null and nav.hero_nav_fade_tween.is_valid():
		nav.hero_nav_fade_tween.kill()
	nav.hero_nav_fade_tween = null
	if nav.hub_nav_fade_tween != null and nav.hub_nav_fade_tween.is_valid():
		nav.hub_nav_fade_tween.kill()
	nav.hub_nav_fade_tween = null
	if nav.shop_nav_fade_tween != null and nav.shop_nav_fade_tween.is_valid():
		nav.shop_nav_fade_tween.kill()
	nav.shop_nav_fade_tween = null
	if host.fishing_tool_wallet_pop_tween != null and host.fishing_tool_wallet_pop_tween.is_valid():
		host.fishing_tool_wallet_pop_tween.kill()
	host.fishing_tool_wallet_pop_tween = null
	host._button_press_runtime().clear_all_nav_pop_tweens()


func _kill_action_card_shutdown_tweens() -> void:
	for raw_card in host.action_cards.values():
		var card := raw_card as Dictionary
		host._clear_action_card_medal_tap_ceremony(card)
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


func _kill_tween_value(tween) -> void:
	if tween != null and is_instance_valid(tween) and tween is Tween and tween.is_valid():
		tween.kill()
