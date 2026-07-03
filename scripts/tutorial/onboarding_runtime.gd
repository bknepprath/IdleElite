extends RefCounted

var host

var tutorial_active := false
var tutorial_step := 0
var tutorial_step_changed_msec := -100000
var tutorial_gate_latch_only_until_swipe := false

var activity_start_tip_seen := false
var skill_swipe_tip_seen := false
var onboarding_explore_tip_seen := false
var onboarding_tutorial_complete := false
var onboarding_explore_tip_sequence_running := false
var passive_module_tip_seen := false
var silver_opportunity_tip_seen := false
var silver_opportunity_tip_action_key := ""
var stamina_gauge_tip_seen := false
var onboarding_starter_action_completion_count := 0
var onboarding_header_reveal_after_progress := false
var onboarding_swipe_tip_eligible := false
var onboarding_swipe_navigation_unlocked := false
var onboarding_swipe_tip_sequence_running := false
var onboarding_fight_summary_revealed := false
var onboarding_fight_auto_run_message_shown := false
var onboarding_fight_stamina_revealed := false
var onboarding_fight_action_stats_revealed := false
var onboarding_fight_action_stats_fade_running := false
var onboarding_stamina_tip_sequence_running := false
var onboarding_header_sequence_token := 0
var onboarding_header_sequence_running := false
var onboarding_header_sequence_started_msec := 0
var onboarding_stamina_tip_sequence_started_msec := 0
var onboarding_auto_run_sequence_running := false
var lock_click_tip_seen := false


func _init(host_ref) -> void:
	host = host_ref


func _start_tutorial() -> void:
	host._ensure_tutorial_overlay()
	host._settings_surface()._disarm_reset_data_confirmation()
	host.top_level_nav_locked_until_msec = 0
	if host.post_onboarding_bottom_chrome_fade_tween != null and host.post_onboarding_bottom_chrome_fade_tween.is_valid():
		host.post_onboarding_bottom_chrome_fade_tween.kill()
	host.post_onboarding_bottom_chrome_fade_tween = null
	host._reset_navigation_render_state()
	host.selected_skill_id = host.TUTORIAL_STARTER_SKILL_ID
	host.current_screen = "skill"
	host._prepare_selected_skill_for_render(false)
	onboarding_tutorial_complete = false
	onboarding_swipe_tip_eligible = false
	onboarding_swipe_navigation_unlocked = false
	host._navigation_shell()._sync_bottom_nav_visibility()
	host._navigation_shell()._sync_module_utility_row_visibility()
	if host.settings_overlay != null:
		host._set_canvas_item_visible_if_changed(host.settings_overlay, false)
	host._profile_chat_overlay_surface()._hide_profile_overlay()
	if host.achievements_overlay != null:
		host._set_canvas_item_visible_if_changed(host.achievements_overlay, false)
	if host.offline_summary_overlay != null:
		host._set_canvas_item_visible_if_changed(host.offline_summary_overlay, false)
	if host.chat_overlay != null:
		host._set_canvas_item_visible_if_changed(host.chat_overlay, false)
	activity_start_tip_seen = false
	stamina_gauge_tip_seen = false
	skill_swipe_tip_seen = false
	onboarding_explore_tip_seen = false
	host._tutorial_overlay_surface()._fade_tip_group("activity_start_tip_notes")
	host._tutorial_overlay_surface()._fade_tip_group("stamina_cost_tip_notes")
	host._tutorial_overlay_surface()._fade_tip_group("skill_swipe_tip_notes", false, true)
	host._tutorial_overlay_surface()._fade_tip_group("onboarding_explore_tip_notes", false, true)
	if host.stamina_gauge_tip_root != null and is_instance_valid(host.stamina_gauge_tip_root):
		host.stamina_gauge_tip_root.queue_free()
	host.stamina_gauge_tip_root = null
	onboarding_fight_summary_revealed = false
	onboarding_fight_auto_run_message_shown = false
	onboarding_fight_stamina_revealed = false
	onboarding_fight_action_stats_revealed = false
	onboarding_fight_action_stats_fade_running = false
	tutorial_active = true
	tutorial_step = 1
	host._render_screen(false, 0)
	host._button_press_runtime().play_default_button_sfx()
	host._tutorial_overlay_surface()._update_tutorial_overlay()
	host.save_game()


func _finish_tutorial() -> void:
	tutorial_active = false
	if host.tutorial_overlay != null:
		host._set_canvas_item_visible_if_changed(host.tutorial_overlay, false)
	host._tutorial_overlay_surface()._hide_tutorial_target_indicator()
	_graduate_onboarding_tutorial()
	host._navigation_shell()._sync_bottom_nav_visibility()
	host._navigation_shell()._sync_module_utility_row_visibility()
	host._button_press_runtime().play_default_button_sfx()


func _activate_tutorial_target() -> void:
	if host.screen_render_in_progress:
		host.call_deferred("_activate_tutorial_target")
		return
	match tutorial_step:
		0:
			var skill_id: String = host._tutorial_overlay_surface()._tutorial_target_skill_id()
			if not skill_id.is_empty():
				_set_tutorial_step(1)
				host._select_skill(skill_id)
		1:
			var action_id: String = host._tutorial_overlay_surface()._tutorial_target_action_id()
			if not action_id.is_empty():
				host._start_action_from_card_tap(host.selected_skill_id, action_id)
		2:
			_on_tutorial_action_button_pressed()


func _tutorial_check_progress() -> void:
	if not tutorial_active:
		return
	if tutorial_step == 0 and host.current_screen == "skill":
		_set_tutorial_step(1)
		host._force_tutorial_skill_scroll_to_top()
	elif tutorial_step == 1 and host.current_screen == "skill":
		host._force_tutorial_skill_scroll_to_top()
	elif tutorial_step == 1 and host.current_screen == "menu":
		host._force_tutorial_skill_scroll_to_top()


func _tutorial_on_action_started() -> void:
	if tutorial_active and tutorial_step == 1:
		_complete_tutorial_target_intro()


func _complete_tutorial_target_intro() -> void:
	tutorial_active = false
	tutorial_step = 1
	if host.tutorial_overlay != null:
		host._set_canvas_item_visible_if_changed(host.tutorial_overlay, false)
	host._tutorial_overlay_surface()._hide_tutorial_target_indicator()
	host._navigation_shell()._sync_bottom_nav_visibility()
	host._navigation_shell()._sync_module_utility_row_visibility()
	host.save_game()


func _on_tutorial_action_button_pressed() -> void:
	if tutorial_active and tutorial_step == 2:
		_set_tutorial_step(3)
	elif tutorial_active and tutorial_step == 3:
		_set_tutorial_step(4)
	elif tutorial_active and tutorial_step == 4 and Time.get_ticks_msec() - tutorial_step_changed_msec < 220:
		return
	else:
		_finish_tutorial()


func _set_tutorial_step(step: int) -> void:
	tutorial_step = clampi(step, 0, 4)
	tutorial_step_changed_msec = Time.get_ticks_msec()
	host._tutorial_overlay_surface()._update_tutorial_overlay()
	host.save_game()


func _graduate_onboarding_tutorial() -> void:
	if onboarding_tutorial_complete:
		return
	onboarding_tutorial_complete = true
	onboarding_explore_tip_seen = true
	host._navigation_shell().module_utility_collapsed = true
	host._tutorial_overlay_surface()._fade_tip_group("onboarding_explore_tip_notes", false, true)
	host._tutorial_overlay_surface()._fade_tip_group("skill_swipe_tip_notes", false, true)
	host.save_game()
	host._navigation_shell()._sync_bottom_nav_visibility()
	host._navigation_shell()._sync_module_utility_row_visibility()
	host._sync_skill_detail_back_arrow_visibility()
	host._navigation_shell().call_deferred("_sync_bottom_nav_visibility")
	host._navigation_shell().call_deferred("_sync_module_utility_row_visibility")
	host.call_deferred("_sync_skill_detail_back_arrow_visibility")
	host.call_deferred("_fade_in_post_onboarding_bottom_chrome")
	if host.auto_unlock_lockpads_enabled:
		host.call_deferred("_run_startup_auto_unlock_lockpads")


func _mark_skill_swipe_tip_seen() -> void:
	if skill_swipe_tip_seen:
		return
	skill_swipe_tip_seen = true
	host.save_game()


func _mark_stamina_gauge_tip_seen() -> void:
	if stamina_gauge_tip_seen:
		return
	stamina_gauge_tip_seen = true
	host.save_game()
	call_deferred("_maybe_trigger_onboarding_swipe_tip_at_zero_stamina", host.TUTORIAL_STARTER_SKILL_ID)


func _mark_onboarding_swipe_navigation_unlocked() -> void:
	if onboarding_swipe_navigation_unlocked:
		return
	onboarding_swipe_navigation_unlocked = true
	host.save_game()


func _onboarding_swipe_intro_complete() -> bool:
	return stamina_gauge_tip_seen and onboarding_fight_action_stats_revealed


func _onboarding_fight_header_sequence_active() -> bool:
	return (
		_onboarding_path_active()
		and host.selected_skill_id == host.TUTORIAL_STARTER_SKILL_ID
		and host._skill_detail_shows_tutorial_tips()
	)


func _onboarding_auto_run_message_resumable() -> bool:
	return (
		_onboarding_fight_header_sequence_active()
		and not onboarding_fight_auto_run_message_shown
		and onboarding_starter_action_completion_count >= host.ONBOARDING_AUTO_RUN_MESSAGE_COMPLETION_THRESHOLD
	)


func _onboarding_header_reveal_sequence_resumable() -> bool:
	if tutorial_active:
		return false
	if not _onboarding_fight_header_sequence_active() or onboarding_fight_stamina_revealed:
		return false
	if not onboarding_fight_summary_revealed:
		return (
			onboarding_header_reveal_after_progress
			or onboarding_starter_action_completion_count >= 3
		)
	return not onboarding_fight_stamina_revealed


func _maybe_trigger_onboarding_header_reveal_from_progress() -> void:
	if not onboarding_header_reveal_after_progress:
		return
	if onboarding_fight_summary_revealed or onboarding_header_sequence_running:
		return
	if not _onboarding_fight_header_sequence_active():
		onboarding_header_reveal_after_progress = false
		return
	if host.running_skill_id != host.TUTORIAL_STARTER_SKILL_ID or host.running_action_id != host.TUTORIAL_STARTER_ACTION_ID:
		return
	if host.action_progress < host.ONBOARDING_HEADER_REVEAL_PROGRESS_FRACTION:
		return
	onboarding_header_reveal_after_progress = false
	call_deferred("_run_onboarding_header_reveal_sequence")


func _cancel_onboarding_header_sequence() -> void:
	onboarding_header_sequence_token += 1
	onboarding_header_sequence_running = false
	onboarding_header_sequence_started_msec = 0
	onboarding_auto_run_sequence_running = false
	onboarding_stamina_tip_sequence_running = false
	onboarding_stamina_tip_sequence_started_msec = 0
	host._tutorial_overlay_surface()._clear_onboarding_auto_run_message(true)
	host._tutorial_overlay_surface()._fade_tip_group("onboarding_auto_run_tip_notes")


func _run_onboarding_auto_run_message_sequence() -> void:
	if not _onboarding_fight_header_sequence_active() or onboarding_fight_auto_run_message_shown:
		return
	if onboarding_auto_run_sequence_running:
		return
	onboarding_auto_run_sequence_running = true
	var token := onboarding_header_sequence_token
	await host._tutorial_overlay_surface()._show_onboarding_auto_run_message(token)
	if token != onboarding_header_sequence_token:
		onboarding_auto_run_sequence_running = false
		return
	await host.get_tree().create_timer(host.ONBOARDING_AUTO_RUN_MESSAGE_LINGER_SECONDS).timeout
	if token != onboarding_header_sequence_token:
		onboarding_auto_run_sequence_running = false
		return
	host._tutorial_overlay_surface()._clear_onboarding_auto_run_message(false)
	await host.get_tree().create_timer(host.ONBOARDING_HEADER_FADE_SECONDS).timeout
	if token != onboarding_header_sequence_token:
		onboarding_auto_run_sequence_running = false
		return
	onboarding_fight_auto_run_message_shown = true
	host.save_game()
	onboarding_auto_run_sequence_running = false


func _run_onboarding_header_reveal_sequence() -> void:
	if not _onboarding_fight_header_sequence_active() or onboarding_fight_stamina_revealed:
		return
	if onboarding_header_sequence_running:
		return
	onboarding_header_sequence_running = true
	onboarding_header_sequence_started_msec = Time.get_ticks_msec()
	var token := onboarding_header_sequence_token
	host._tutorial_overlay_surface()._apply_onboarding_fight_header_visibility()
	if not onboarding_fight_summary_revealed:
		if host.detail_header_left_block != null and is_instance_valid(host.detail_header_left_block):
			host.detail_header_left_block.modulate.a = 0.0
			await host._tutorial_overlay_surface()._fade_onboarding_header_control(host.detail_header_left_block, 1.0, host.ONBOARDING_SUMMARY_FADE_SECONDS)
		if token != onboarding_header_sequence_token:
			onboarding_header_sequence_running = false
			onboarding_header_sequence_started_msec = 0
			return
		onboarding_fight_summary_revealed = true
		onboarding_header_reveal_after_progress = false
		host.save_game()
		host._tutorial_overlay_surface()._apply_onboarding_fight_header_visibility()
	if not onboarding_fight_stamina_revealed:
		await host.get_tree().create_timer(host.ONBOARDING_STAMINA_GAUGE_DELAY_BEFORE_FADE_SECONDS).timeout
		if token != onboarding_header_sequence_token:
			onboarding_header_sequence_running = false
			onboarding_header_sequence_started_msec = 0
			return
		if host.detail_header_body != null and is_instance_valid(host.detail_header_body):
			if host.get_tree().get_nodes_in_group("stamina_cost_tip_notes").is_empty():
				host._tutorial_overlay_surface()._add_stamina_cost_tip(host.detail_header_body, false)
		if host.stamina_gauge_tip_root != null and is_instance_valid(host.stamina_gauge_tip_root):
			host.stamina_gauge_tip_root.modulate.a = 0.0
		if host.detail_regen_circle != null and is_instance_valid(host.detail_regen_circle):
			host.detail_regen_circle.modulate = Color.WHITE
			host.detail_regen_circle.mouse_filter = Control.MOUSE_FILTER_STOP
		var gauge_fade: Tween = host.create_tween()
		gauge_fade.set_parallel(true)
		var regen_fade_target: CanvasItem = host._tutorial_overlay_surface()._detail_regen_circle_fade_target()
		if regen_fade_target != null:
			regen_fade_target.modulate.a = 0.0
			gauge_fade.tween_property(regen_fade_target, "modulate:a", 1.0, host.ONBOARDING_STAMINA_GAUGE_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if host.stamina_gauge_tip_root != null and is_instance_valid(host.stamina_gauge_tip_root):
			gauge_fade.tween_property(host.stamina_gauge_tip_root, "modulate:a", 1.0, host.ONBOARDING_STAMINA_GAUGE_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		var gauge_wait_duration: float = host.ONBOARDING_STAMINA_GAUGE_FADE_SECONDS
		if host.detail_regen_circle != null and is_instance_valid(host.detail_regen_circle):
			var fill_target: float = host._stamina_regen_fraction(host.selected_skill_id)
			var fill_start := 3.0 / float(maxi(1, host._max_stamina(host.selected_skill_id)))
			host.detail_regen_circle.intro_fill_lock = true
			host.detail_regen_circle.set_value(fill_start, true)
			const FILL_DELAY := 0.2
			const FILL_DURATION := 0.9
			gauge_wait_duration = maxf(gauge_wait_duration, FILL_DELAY + FILL_DURATION)
			gauge_fade.tween_property(host.detail_regen_circle, "value", fill_target, FILL_DURATION).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT).set_delay(FILL_DELAY)
			gauge_fade.tween_callback(host._tutorial_overlay_surface()._finish_onboarding_regen_intro_fill.bind(host.detail_regen_circle.get_instance_id(), fill_target)).set_delay(FILL_DELAY + FILL_DURATION)
		await host.get_tree().create_timer(gauge_wait_duration).timeout
		if token != onboarding_header_sequence_token:
			onboarding_header_sequence_running = false
			onboarding_header_sequence_started_msec = 0
			return
		onboarding_fight_stamina_revealed = true
		host.save_game()
		host._tutorial_overlay_surface()._apply_onboarding_fight_header_visibility()
		await _run_onboarding_stamina_tip_sequence(token, true)
	onboarding_header_sequence_running = false
	onboarding_header_sequence_started_msec = 0
	host._tutorial_overlay_surface()._apply_onboarding_fight_header_visibility()


func _run_onboarding_stamina_tip_sequence(token: int = -1, skip_fade_in := false):
	if not _onboarding_fight_header_sequence_active() or stamina_gauge_tip_seen:
		return
	if onboarding_stamina_tip_sequence_running:
		return
	onboarding_stamina_tip_sequence_running = true
	onboarding_stamina_tip_sequence_started_msec = Time.get_ticks_msec()
	if token < 0:
		token = onboarding_header_sequence_token
	if host.detail_header_body == null or not is_instance_valid(host.detail_header_body):
		onboarding_stamina_tip_sequence_running = false
		onboarding_stamina_tip_sequence_started_msec = 0
		return
	if not skip_fade_in:
		if host.get_tree().get_nodes_in_group("stamina_cost_tip_notes").is_empty():
			host._tutorial_overlay_surface()._add_stamina_cost_tip(host.detail_header_body, false)
			if host.stamina_gauge_tip_root != null and is_instance_valid(host.stamina_gauge_tip_root):
				host.stamina_gauge_tip_root.modulate.a = 0.0
				await host._tutorial_overlay_surface()._fade_onboarding_header_control(host.stamina_gauge_tip_root, 1.0, host.ONBOARDING_STAMINA_GAUGE_FADE_SECONDS)
		else:
			if host.stamina_gauge_tip_root == null or not is_instance_valid(host.stamina_gauge_tip_root):
				for node in host.get_tree().get_nodes_in_group("stamina_cost_tip_notes"):
					host.stamina_gauge_tip_root = node as Control
					break
	elif host.stamina_gauge_tip_root == null or not is_instance_valid(host.stamina_gauge_tip_root):
		for node in host.get_tree().get_nodes_in_group("stamina_cost_tip_notes"):
			host.stamina_gauge_tip_root = node as Control
			break
	if token != onboarding_header_sequence_token:
		onboarding_stamina_tip_sequence_running = false
		onboarding_stamina_tip_sequence_started_msec = 0
		return
	await host.get_tree().create_timer(host.ONBOARDING_STAMINA_TIP_LINGER_SECONDS).timeout
	if token != onboarding_header_sequence_token:
		onboarding_stamina_tip_sequence_running = false
		onboarding_stamina_tip_sequence_started_msec = 0
		return
	if host.stamina_gauge_tip_root != null and is_instance_valid(host.stamina_gauge_tip_root):
		await host._tutorial_overlay_surface()._fade_onboarding_header_control(host.stamina_gauge_tip_root, 0.0, host.TUTORIAL_TIP_FADE_OUT_SECONDS)
		host.stamina_gauge_tip_root.queue_free()
		host.stamina_gauge_tip_root = null
	else:
		host._tutorial_overlay_surface()._fade_tip_group("stamina_cost_tip_notes")
	if token != onboarding_header_sequence_token:
		onboarding_stamina_tip_sequence_running = false
		onboarding_stamina_tip_sequence_started_msec = 0
		return
	_mark_stamina_gauge_tip_seen()
	await host._tutorial_overlay_surface()._fade_onboarding_fight_action_stats_in(token)
	onboarding_stamina_tip_sequence_running = false
	onboarding_stamina_tip_sequence_started_msec = 0


func _resume_onboarding_stamina_mastery_sequence_if_needed() -> void:
	if not _onboarding_fight_header_sequence_active():
		return
	if tutorial_active or stamina_gauge_tip_seen or onboarding_fight_action_stats_revealed:
		return
	if _recover_stalled_onboarding_stamina_mastery_sequence_if_needed():
		return
	if onboarding_header_sequence_running or onboarding_stamina_tip_sequence_running:
		return
	if not onboarding_fight_stamina_revealed:
		return
	call_deferred("_run_onboarding_stamina_tip_sequence", onboarding_header_sequence_token, true)


func _recover_stalled_onboarding_stamina_mastery_sequence_if_needed() -> bool:
	if not onboarding_fight_stamina_revealed:
		return false
	if not onboarding_header_sequence_running and not onboarding_stamina_tip_sequence_running:
		return false
	var now_msec := Time.get_ticks_msec()
	var oldest_started_msec := 0
	if onboarding_header_sequence_started_msec > 0:
		oldest_started_msec = onboarding_header_sequence_started_msec
	if onboarding_stamina_tip_sequence_started_msec > 0:
		oldest_started_msec = (
			onboarding_stamina_tip_sequence_started_msec
			if oldest_started_msec <= 0
			else mini(oldest_started_msec, onboarding_stamina_tip_sequence_started_msec)
		)
	if oldest_started_msec <= 0:
		return false
	if now_msec - oldest_started_msec < 6500:
		return false
	onboarding_header_sequence_token += 1
	onboarding_header_sequence_running = false
	onboarding_header_sequence_started_msec = 0
	onboarding_stamina_tip_sequence_running = false
	onboarding_stamina_tip_sequence_started_msec = 0
	if host.stamina_gauge_tip_root != null and is_instance_valid(host.stamina_gauge_tip_root):
		host.stamina_gauge_tip_root.queue_free()
	host.stamina_gauge_tip_root = null
	_mark_stamina_gauge_tip_seen()
	host._tutorial_overlay_surface().call_deferred("_fade_onboarding_fight_action_stats_in", onboarding_header_sequence_token)
	return true


func _onboarding_combo_swipe_tip_context_ready() -> bool:
	if not _onboarding_path_active():
		return true
	if host.selected_skill_id != host.TUTORIAL_STARTER_SKILL_ID:
		return false
	if not tutorial_gate_latch_only_until_swipe:
		return false
	if host.activity_unlock_ceremony_count > 0 or host.locked_activity_preview_fade_play_pending:
		return false
	var card: Dictionary = host._card_for_action_id(host.TUTORIAL_STARTER_SKILL_ID, host.TUTORIAL_GATE_LATCH_ACTION_ID)
	if card.is_empty() or host._activity_preview_reveal_animation_pending(card):
		return false
	var root: Control = host._valid_control_ref(card.get("root"))
	if root == null or not root.is_visible_in_tree() or root.modulate.a < 0.96:
		return false
	var action_card_host: Control = host._valid_control_ref(host.detail_action_card_nodes.get(host.TUTORIAL_GATE_LATCH_ACTION_ID))
	return action_card_host != null and action_card_host.is_visible_in_tree()


func _onboarding_fight_stamina_depleted() -> bool:
	return host._stamina_value(host.TUTORIAL_STARTER_SKILL_ID) < host.ONBOARDING_SWIPE_STAMINA_THRESHOLD


func _onboarding_swipe_prompt_due() -> bool:
	return (
		onboarding_swipe_tip_eligible
		or _onboarding_fight_stamina_depleted()
		or tutorial_gate_latch_only_until_swipe
	)


func _ensure_onboarding_swipe_unlocked(from_user_attempt := false) -> bool:
	if not _onboarding_path_active():
		return true
	if host.selected_skill_id != host.TUTORIAL_STARTER_SKILL_ID:
		return false
	if not _onboarding_swipe_intro_complete():
		return false
	if (
		onboarding_swipe_navigation_unlocked
		and from_user_attempt
		and not skill_swipe_tip_seen
		and not host._skill_swipe_tip_present()
	):
		if not onboarding_swipe_tip_eligible:
			onboarding_swipe_tip_eligible = true
			host.save_game()
		if not onboarding_swipe_tip_sequence_running:
			host.call_deferred("_run_onboarding_swipe_tip_sequence")
		return false
	if onboarding_swipe_navigation_unlocked:
		return true
	if not _onboarding_swipe_prompt_due():
		return false
	if not onboarding_swipe_tip_eligible:
		onboarding_swipe_tip_eligible = true
		host.save_game()
	_mark_onboarding_swipe_navigation_unlocked()
	if (
		not skill_swipe_tip_seen
		and host.selected_skill_id == host.TUTORIAL_STARTER_SKILL_ID
		and not onboarding_swipe_tip_sequence_running
	):
		host.call_deferred("_run_onboarding_swipe_tip_sequence")
	if from_user_attempt and not skill_swipe_tip_seen and not host._skill_swipe_tip_present():
		return false
	return true


func _onboarding_swipe_tip_sequence_resumable() -> bool:
	return (
		_onboarding_path_active()
		and host.selected_skill_id == host.TUTORIAL_STARTER_SKILL_ID
		and _onboarding_swipe_intro_complete()
		and _onboarding_combo_swipe_tip_context_ready()
		and _onboarding_swipe_prompt_due()
		and not skill_swipe_tip_seen
	)


func _maybe_trigger_onboarding_swipe_tip_at_zero_stamina(skill_id: String) -> void:
	if skill_id != host.TUTORIAL_STARTER_SKILL_ID:
		return
	if not _onboarding_path_active():
		return
	if not _onboarding_swipe_intro_complete():
		return
	if not _onboarding_combo_swipe_tip_context_ready():
		return
	if not _onboarding_swipe_prompt_due():
		return
	if not onboarding_swipe_tip_eligible:
		onboarding_swipe_tip_eligible = true
		host.save_game()
	if not onboarding_swipe_navigation_unlocked:
		_mark_onboarding_swipe_navigation_unlocked()
	if skill_swipe_tip_seen or onboarding_swipe_tip_sequence_running:
		return
	if host.selected_skill_id != host.TUTORIAL_STARTER_SKILL_ID:
		return
	host.call_deferred("_run_onboarding_swipe_tip_sequence")


func _mark_lock_click_tip_seen() -> bool:
	if lock_click_tip_seen:
		return false
	var had_tip: bool = host._tutorial_overlay_surface()._fade_tip_group("lock_click_tip_notes", false, true)
	if not had_tip:
		return false
	lock_click_tip_seen = true
	host.lock_click_tip_collapse_until_msec = Time.get_ticks_msec() + int(ceil(host.TUTORIAL_TIP_FADE_OUT_SECONDS * 1000.0))
	host.save_game()
	return true


func _record_activity_start_for_tips() -> void:
	host.activity_start_count += 1
	if not activity_start_tip_seen:
		activity_start_tip_seen = true
		host._tutorial_overlay_surface()._fade_tip_group("activity_start_tip_notes")
		if host.activity_start_highlight_pending:
			host.activity_start_highlight_pending = false
			host.activity_start_highlight_token += 1
	if _onboarding_path_active() and not tutorial_active and onboarding_explore_tip_seen:
		_graduate_onboarding_tutorial()
	host.save_game()


func _onboarding_mastery_rewards_allowed(skill_id: String) -> bool:
	if skill_id != host.TUTORIAL_STARTER_SKILL_ID:
		return true
	if not _onboarding_path_active():
		return true
	return onboarding_fight_action_stats_revealed


func _onboarding_mastery_feedback_allowed(anchor: Control) -> bool:
	if anchor == null or not is_instance_valid(anchor):
		return false
	if anchor.modulate.a <= 0.01:
		return false
	return true


func _onboarding_path_active() -> bool:
	return not onboarding_tutorial_complete


func _activity_crits_allowed() -> bool:
	return not _onboarding_path_active()


func _onboarding_skill_accessible(skill_id: String) -> bool:
	if not _onboarding_path_active():
		return true
	if skill_id == host.TUTORIAL_STARTER_SKILL_ID:
		return true
	return onboarding_swipe_navigation_unlocked


func _onboarding_swipe_to_other_skills_allowed() -> bool:
	return (
		_onboarding_path_active()
		and onboarding_swipe_navigation_unlocked
		and (
			skill_swipe_tip_seen
			or host._skill_swipe_tip_present()
		)
	)


func _onboarding_blocks_skill_swipe() -> bool:
	if not _onboarding_path_active():
		return false
	if (
		host.selected_skill_id == host.TUTORIAL_STARTER_SKILL_ID
		and not skill_swipe_tip_seen
		and _onboarding_swipe_intro_complete()
		and (
			onboarding_swipe_navigation_unlocked
			or onboarding_swipe_tip_eligible
			or _onboarding_fight_stamina_depleted()
		)
		and not host._skill_swipe_tip_present()
	):
		return true
	return not _onboarding_swipe_to_other_skills_allowed()


func _swipe_offset_accessible(offset: int) -> bool:
	if offset == 0:
		return false
	var target_skill_id: String = host._skill_swipe_activity_surface()._skill_id_for_swipe_offset(offset)
	if target_skill_id.is_empty():
		return false
	if not _onboarding_skill_accessible(target_skill_id):
		return false
	if _onboarding_path_active() and not _onboarding_swipe_to_other_skills_allowed():
		return false
	return true


func _show_onboarding_skill_locked_message(source: Control = null) -> void:
	var message := "Finish the %s intro first." % host._skill_name(host.TUTORIAL_STARTER_SKILL_ID)
	host._set_result(message, false)
	if source != null and is_instance_valid(source) and source.is_visible_in_tree():
		host._reward_feedback_surface()._float_reward(host, source, message, 52, Color.WHITE, Vector2(0, -24), Vector2(0, -120), 0.0)


func _record_activity_completion_for_tips(skill_id: String = "", action_id: String = "") -> void:
	host.activity_completion_count += 1
	var save_immediately := false
	var is_starter_completion: bool = (
		skill_id == host.TUTORIAL_STARTER_SKILL_ID
		and action_id == host.TUTORIAL_STARTER_ACTION_ID
	)
	if is_starter_completion:
		save_immediately = true
		onboarding_starter_action_completion_count += 1
		if onboarding_starter_action_completion_count == 1 and not host.onboarding_first_module_center_released:
			host.onboarding_first_module_center_release_pending = true
	if _onboarding_fight_header_sequence_active() and is_starter_completion:
		if (
			onboarding_starter_action_completion_count >= host.ONBOARDING_AUTO_RUN_MESSAGE_COMPLETION_THRESHOLD
			and not onboarding_fight_auto_run_message_shown
		):
			call_deferred("_run_onboarding_auto_run_message_sequence")
		if (
			onboarding_starter_action_completion_count >= 2
			and not onboarding_fight_summary_revealed
		):
			onboarding_header_reveal_after_progress = true
		if (
			onboarding_starter_action_completion_count >= 3
			and not onboarding_fight_summary_revealed
		):
			onboarding_header_reveal_after_progress = false
			call_deferred("_run_onboarding_header_reveal_sequence")
	if save_immediately:
		host.save_game()
	else:
		host._mark_save_dirty("activity completion")


func _skill_swipe_tip_available() -> bool:
	return (
		not skill_swipe_tip_seen
		and activity_start_tip_seen
		and stamina_gauge_tip_seen
		and _onboarding_combo_swipe_tip_context_ready()
		and _onboarding_swipe_prompt_due()
	)


func _maybe_show_onboarding_explore_tip() -> void:
	if onboarding_tutorial_complete:
		return
	if not _onboarding_path_active():
		return
	if not onboarding_swipe_navigation_unlocked:
		return
	if host.selected_skill_id == host.TUTORIAL_STARTER_SKILL_ID:
		return
	if not skill_swipe_tip_seen:
		return
	host._remove_onboarding_level_up_tip()
	host.call_deferred("_run_onboarding_explore_tip_sequence")


func _tutorial_starter_only_detail_active(skill_id: String) -> bool:
	return (
		tutorial_active
		and host.current_screen == "skill"
		and skill_id == host.TUTORIAL_STARTER_SKILL_ID
		and host.selected_skill_id == host.TUTORIAL_STARTER_SKILL_ID
		and tutorial_step <= 1
	)


func _tutorial_should_defer_action_until_skill_swipe(skill_id: String, action: Dictionary) -> bool:
	return (
		tutorial_gate_latch_only_until_swipe
		and skill_id == host.TUTORIAL_STARTER_SKILL_ID
		and str(action.get("id", "")) == host.TUTORIAL_DEFERRED_AFTER_GATE_ACTION_ID
	)


func _tutorial_gate_latch_sequence_active() -> bool:
	return tutorial_active or _onboarding_path_active()


func _tutorial_preview_after_manual_unlock(skill_id: String, action_id: String) -> String:
	if _tutorial_gate_latch_sequence_active() and skill_id == host.TUTORIAL_STARTER_SKILL_ID and action_id == host.TUTORIAL_LEVEL_TWO_ACTION_ID:
		tutorial_gate_latch_only_until_swipe = true
		return host.TUTORIAL_GATE_LATCH_ACTION_ID
	if host._fishing_rework_active_for_skill(skill_id):
		var fishing_preview_id: String = host._fishing_preview_after_manual_unlock(action_id)
		if not fishing_preview_id.is_empty():
			return fishing_preview_id
	return host._first_locked_action_id_after_manual_unlock(skill_id, action_id)


func _tutorial_current_locked_preview_action_id(skill_id: String) -> String:
	if tutorial_gate_latch_only_until_swipe and skill_id == host.TUTORIAL_STARTER_SKILL_ID:
		return host.TUTORIAL_GATE_LATCH_ACTION_ID
	return host._first_locked_action_id(skill_id)


func _clear_tutorial_gate_latch_only_after_skill_swipe(refresh_current_page := true) -> void:
	if not tutorial_gate_latch_only_until_swipe:
		return
	tutorial_gate_latch_only_until_swipe = false
	host.activity_unlock_detail_refresh_done = false
	if refresh_current_page and host.current_screen == "skill":
		host.call_deferred("_refresh_skill_detail_after_activity_unlock_ceremony")
