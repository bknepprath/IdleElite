extends RefCounted

const SaveStateFiles = preload("res://scripts/save_state/files.gd")
const SaveStateNormalizers = preload("res://scripts/save_state/normalizers.gd")
const LeaderboardProfile = preload("res://scripts/online/leaderboard_profile.gd")
const ProfileChatOverlaySurface = preload("res://scripts/ui/profile_chat_overlay_surface.gd")
const BuildableModules = preload("res://scripts/gameplay/buildable_modules.gd")
const AchievementState = preload("res://scripts/achievements/state.gd")
const MasteryState = preload("res://scripts/progression/mastery_state.gd")
const SkillState = preload("res://scripts/progression/skill_state.gd")
const TipState = preload("res://scripts/tutorial/tip_state.gd")

var host
var pending_post_load_saved_at := -1
var pending_save_restore_data := {}
var pending_save_has_achievement_toast_seen_ids := false
var achievement_toast_seen_ids := {}
var save_repaired_this_boot := false
var boot_post_load_simulation_scheduled := false


func _init(host_ref) -> void:
	host = host_ref


func _init_state() -> void:
	host._invalidate_stat_caches()
	host.skills.clear()
	host.mastery.clear()
	host.stamina.clear()
	host.stamina_bank.clear()
	host.honey_stamina_seconds_remaining = 0.0
	host.canceled_action_progress_by_key.clear()
	host.auto_eat_fish_after_spend_due_msec_by_skill.clear()
	host.material_runtime.legacy_softwood_amount = 0
	host.material_runtime.wallet.clear()
	host.fish_currency = 0.0
	host.fish_currency_ever_earned = false
	host.auto_eat_fish_enabled_by_skill.clear()
	host.auto_unlock_lockpads_enabled = false
	host.nav_symbol_seen_ids.clear()
	host.offline_progress_cap_notifications_enabled = false
	host.module_ui_runtime.reset()
	host._navigation_shell().module_utility_collapsed = false
	host.god_mode_enabled = false
	host.god_mode_save_tainted = false
	host.fishing_runtime.reset()
	host.fishing_tool_wallet_open = false
	host.passive_modules.clear()
	host.convergence_modules.clear()
	host._temporary_event_runtime().reset()
	host.thieving_state.reset()
	host._hub_runtime().hub_modules.clear()
	host._hub_runtime().hub_selected_module_id = "pond"
	host._hub_surface().hub_module_positions.clear()
	host._hub_surface().hub_decor_layout.clear()
	host._hub_runtime().hub_missions.clear()
	host._hub_runtime().hub_mission_cooldown_until_unix = 0
	host._hub_surface().hub_tutorial_tip_seen = false
	host._hub_surface().hub_tutorial_host = null
	host._hub_surface().hub_tutorial_tip_root = null
	host._hub_surface().hub_tutorial_info_button = null
	host._hub_surface()._kill_hub_tutorial_tip_tween()
	host.manual_activity_unlocks.clear()
	host.manual_activity_requirement_unlocks.clear()
	host._activity_unlock_runtime()._invalidate_manual_activity_unlock_trust()
	host.plank_boost_enabled = false
	host.activity_crit_seen = false
	host.activity_mega_crit_seen = false
	achievement_toast_seen_ids.clear()
	host.activity_start_tip_seen = false
	host.activity_start_count = 0
	host.activity_completion_count = 0
	host.guaranteed_success_action_completions = 0
	host.onboarding_starter_action_completion_count = 0
	host.onboarding_first_module_center_release_pending = false
	host.onboarding_first_module_center_released = false
	host.onboarding_header_reveal_after_progress = false
	host.onboarding_swipe_tip_eligible = false
	host.onboarding_swipe_navigation_unlocked = false
	host.onboarding_swipe_tip_sequence_running = false
	host.skill_swipe_tip_seen = false
	host.onboarding_explore_tip_seen = false
	host.onboarding_tutorial_complete = false
	host.onboarding_explore_tip_sequence_running = false
	host.stamina_gauge_tip_seen = false
	host.lock_click_tip_seen = false
	host.passive_module_tip_seen = false
	host.silver_opportunity_tip_seen = false
	host.silver_opportunity_tip_action_key = ""
	host.stamina_gauge_pre_tip_hold_seconds = 0.0
	host.show_stamina_decimal = false
	host.offline_progress_cap_notifications_enabled = false
	host.stamina_gauge_tip_root = null
	host.onboarding_fight_summary_revealed = false
	host.onboarding_fight_auto_run_message_shown = false
	host.onboarding_fight_stamina_revealed = false
	host.onboarding_fight_action_stats_revealed = false
	host.onboarding_fight_action_stats_fade_running = false
	host.onboarding_header_sequence_running = false
	host.onboarding_auto_run_sequence_running = false
	host.onboarding_stamina_tip_sequence_running = false
	host.onboarding_header_sequence_started_msec = 0
	host.onboarding_stamina_tip_sequence_started_msec = 0
	host.onboarding_mastery_tip_root = null
	host.onboarding_medal_tip_root = null
	host.onboarding_swipe_overlay_tip_root = null
	host.onboarding_level_up_tip_root = null
	host.onboarding_mastery_tip_dismissed = false
	host.onboarding_medal_tip_shown = false
	host.tutorial_gate_latch_only_until_swipe = false
	host.pending_activity_unlock_ceremony = {}
	host.activity_unlock_ceremony_count = 0
	host.activity_unlock_ceremony_action_key = ""
	host.activity_unlock_preview_after_ceremony_id = ""
	host.activity_unlock_heist_preview_after_ceremony_id = ""
	host.activity_unlock_center_scroll_target = -1
	host.activity_unlock_detail_refresh_done = false
	host.locked_activity_preview_reveal_pending = false
	host.locked_activity_preview_reveal_skill_ids.clear()
	host.locked_activity_preview_fade_play_pending = false
	host.locked_activity_preview_played_action_keys.clear()
	host._onboarding_runtime()._cancel_onboarding_header_sequence()
	host.activity_start_highlight_token += 1
	host.activity_start_highlight_pending = false
	host.activity_start_highlight_active = false
	host.activity_start_highlight_border = null
	host.activity_start_highlight_card_key = ""
	host.activity_start_highlight_fade_tween = null
	host._restore_activity_start_highlight_frame_clip()
	host.leaderboard_last_submitted_score = 0
	host.leaderboard_last_submitted_total_xp = 0
	host.leaderboard_last_submitted_scores_by_category.clear()
	host.leaderboard_last_submit_unix = 0
	host.leaderboard_repair_publish_version = 0
	host.leaderboard_display_name = LeaderboardProfile.make_guest_display_name(host.PROFILE_GUEST_NAME_PREFIX)
	host.leaderboard_name_key = ""
	host.leaderboard_avatar_index = 0
	host.leaderboard_profile_claimed = false
	host.leaderboard_name_claim_verified = false
	host.leaderboard_player_id = LeaderboardProfile.make_player_id()
	host.leaderboard_auth_id_token = ""
	host.leaderboard_auth_refresh_token = ""
	host.leaderboard_auth_expires_unix = 0
	host.leaderboard_auth_retry_after_unix = 0
	host.leaderboard_auth_provider = "anonymous"
	host.leaderboard_rows_by_category.clear()
	host.leaderboard_fetch_unix_by_category.clear()
	host.leaderboard_fetch_retry_unix_by_category.clear()
	host.leaderboard_pending_repair_publish_version = 0
	host.leaderboard_status_message = ""
	host.google_auth_in_flight = false
	host.google_auth_status_message = ""
	host.cloud_save_fetch_in_flight = false
	host.cloud_save_upload_in_flight = false
	host.cloud_save_dirty = false
	host.cloud_save_last_upload_unix = 0
	host.cloud_save_last_fetch_unix = 0
	host.cloud_save_remote_checked = false
	host.cloud_save_last_remote_summary.clear()
	host.cloud_save_last_remote_payload.clear()
	host.cloud_save_status_message = ""
	host.chat_rows.clear()
	host.chat_stream_retry_unix = 0
	host.chat_last_send_unix = 0
	host.chat_last_opened_created_at = 0
	host.chat_last_opened_message_id = ""
	host.chat_status_message = ""
	host.chat_send_stage = ""
	host.chat_pending_send_payload.clear()
	host.last_passive_process_unix = host._unix_now()
	host.ad_bonus_seconds_remaining = 0.0
	for def in host.skill_defs:
		var skill_id = str(def["id"])
		host.skills[skill_id] = {"xp": 0, "level": 1}
		host.stamina[skill_id] = float(host.BASE_MAX_STAMINA)
		host.stamina_bank[skill_id] = 0.0
	host._invalidate_stat_caches()


func reset_data(feedback_button: Button = null) -> void:
	_clear_pending_save_restore_work()
	host._reset_navigation_render_state()
	host._reset_skill_swipe_frame_layout()
	host.screen_render_in_progress = false
	host.screen_render_target_key = ""
	host.pending_screen_render_request.clear()
	host.pending_skill_detail_refresh_request.clear()
	host._settings_surface()._clear_reset_data_buttons_for_rebuild()
	_init_state()
	host._navigation_shell()._reset_page_control_refs()
	host.running_skill_id = ""
	host.running_action_id = ""
	host.action_progress = 0.0
	host.event_running_skill_id = ""
	host.event_running_action_id = ""
	host.event_action_progress = 0.0
	host.canceled_action_progress_by_key.clear()
	host.selected_skill_id = host.TUTORIAL_STARTER_SKILL_ID
	if host.settings_overlay != null:
		host._set_canvas_item_visible_if_changed(host.settings_overlay, false)
		host._profile_chat_overlay_surface()._hide_profile_overlay()
	if host.achievements_overlay != null:
		host._set_canvas_item_visible_if_changed(host.achievements_overlay, false)
	if host.offline_summary_overlay != null:
		host._set_canvas_item_visible_if_changed(host.offline_summary_overlay, false)
	if host.chat_overlay != null:
		host._set_canvas_item_visible_if_changed(host.chat_overlay, false)
	host._prepare_selected_skill_for_render(false)
	host.last_result = "Data wiped."
	host._last_rendered_screen_key = ""
	host.save_reset_generation = maxi(host.save_reset_generation + 1, host._unix_now_msec())
	host.allow_next_save_progress_regression = true
	save_game()
	host._onboarding_runtime()._start_tutorial()
	host._update_ui(0.0, true)
	var feedback_button_id := feedback_button.get_instance_id() if feedback_button != null and is_instance_valid(feedback_button) else 0
	host._settings_surface().call_deferred("_play_reset_data_wiped_feedback_by_id", feedback_button_id)



func _mark_save_dirty(reason = "") -> void:
	host.save_dirty = true
	if not reason.is_empty():
		host.save_dirty_reason = reason



func save_game() -> void:
	if OS.get_environment("IDLE_ELITE_DISABLE_SAVE_WRITES") == "1":
		host.save_dirty = false
		host.save_dirty_reason = ""
		return
	var now = host._unix_now()
	var payload = _save_payload(now)
	if not _save_payload_can_replace_existing_save(payload):
		host.save_dirty = true
		host.save_dirty_reason = "progress regression blocked"
		host.last_result = "Save protected: progress regression blocked."
		push_warning(
			"Idle Elite blocked a save that would reduce progress at %s" % ProjectSettings.globalize_path(host.SAVE_PATH)
		)
		return
	if host.allow_next_save_progress_regression:
		host.allow_next_save_progress_regression = false
	if not _write_save_payload_atomically(payload):
		host.save_dirty = true
		host.save_dirty_reason = "save file write failed"
		host.last_result = "Save failed."
		push_warning(
			"Idle Elite save failed at %s" % ProjectSettings.globalize_path(host.SAVE_PATH)
		)
		return
	_sync_web_userfs_after_save()
	if host._online_runtime()._cloud_save_account_ready():
		host.cloud_save_dirty = true
		host._online_runtime().upload_cloud_save()
	host.save_dirty = false
	host.save_dirty_reason = ""
	host.allow_next_save_progress_regression = false



func _write_save_payload_atomically(payload: Dictionary) -> bool:
	if not SaveStateFiles.write_payload_atomically(payload, host.SAVE_PATH, host.SAVE_TEMP_PATH, host.SAVE_BACKUP_PATH):
		return false
	host.last_save_unix_time = int(payload.get("saved_at", host._unix_now()))
	host.last_save_monotonic_msec = Time.get_ticks_msec()
	return true



func _save_payload_can_replace_existing_save(next_payload: Dictionary) -> bool:
	if host.allow_next_save_progress_regression:
		return true
	var existing = SaveStateFiles.best_dictionary_from_paths([host.SAVE_PATH, host.SAVE_TEMP_PATH, host.SAVE_BACKUP_PATH], host.skill_defs)
	if _save_reset_generation(next_payload) > _save_reset_generation(existing):
		return true
	return not _save_payload_regresses_progress(existing, next_payload)



func _save_payload_regresses_progress(existing_payload: Dictionary, next_payload: Dictionary) -> bool:
	return SaveStateNormalizers.payload_regresses_progress(existing_payload, next_payload, host.skill_defs)



func _save_reset_generation(data: Dictionary) -> int:
	return SaveStateNormalizers.save_reset_generation(data)



func _save_total_skill_xp_evidence(data: Dictionary) -> int:
	return SaveStateNormalizers.total_skill_xp_evidence(data, host.skill_defs)



func _sync_web_userfs_after_save() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.force_fs_sync()


func _running_action_id_for_save() -> String:
	if host.running_skill_id.is_empty() or host.running_action_id.is_empty():
		return ""
	var action: Dictionary = host._action_data(host.running_skill_id, host.running_action_id)
	if action.is_empty():
		return ""
	return str(action.get("id", ModuleUiRuntime.canonical_action_id(host.running_skill_id, host.running_action_id, host.FISHING_ACTION_ID_ALIASES)))


func _event_running_action_id_for_save() -> String:
	if host.event_running_skill_id.is_empty() or host.event_running_action_id.is_empty():
		return ""
	var action: Dictionary = host._action_data(host.event_running_skill_id, host.event_running_action_id)
	if action.is_empty() or not host._is_event_action(action):
		return ""
	return str(action.get("id", host.event_running_action_id))


func _selected_skill_id_for_save() -> String:
	if SkillState.has_skill_id(host.skill_defs, host.selected_skill_id):
		return host.selected_skill_id
	return _default_skill_id_for_save()


func _running_skill_id_for_save() -> String:
	var action_id := _running_action_id_for_save()
	if action_id.is_empty() or not SkillState.has_skill_id(host.skill_defs, host.running_skill_id):
		return ""
	return host.running_skill_id


func _event_running_skill_id_for_save() -> String:
	var action_id := _event_running_action_id_for_save()
	if action_id.is_empty() or not SkillState.has_skill_id(host.skill_defs, host.event_running_skill_id):
		return ""
	return host.event_running_skill_id


func _default_skill_id_for_save() -> String:
	if SkillState.has_skill_id(host.skill_defs, "fight"):
		return "fight"
	if not host.skill_defs.is_empty():
		return str((host.skill_defs[0] as Dictionary).get("id", ""))
	return ""


func _action_progress_for_save() -> float:
	return _normalized_action_progress(host.action_progress)


func _event_action_progress_for_save() -> float:
	return _normalized_action_progress(host.event_action_progress)


func _normalized_action_progress(value: Variant) -> float:
	return clampf(float(value), 0.0, 0.999)


func _action_key_for_save(key: String) -> String:
	return host._canonical_action_key(key)



func _save_payload(now: int) -> Dictionary:
	var payload := {
		"save_schema_version": host.SAVE_SCHEMA_VERSION,
		"save_reset_generation": host.save_reset_generation,
		"skills": host.SkillState.skills_for_save(host.skill_defs, host.skills),
		"mastery": MasteryState.for_save(host.mastery, Callable(host, "_canonical_action_key"), host.MASTERY_MAX_LEVEL),
		"stamina": host.SkillState.stamina_for_save(host.skill_defs, host.stamina, Callable(host, "_max_stamina")),
		"stamina_bank": host.SkillState.stamina_bank_for_save(host.skill_defs, host.stamina, host.stamina_bank, Callable(host, "_max_stamina")),
		"honey_stamina_seconds_remaining": clampf(host.honey_stamina_seconds_remaining, 0.0, host.HONEY_STAMINA_SECONDS_PER_CONSUMPTION),
		"blue_guy_health": host._fighting_runtime().blue_guy_health_value(),
		"blue_guy_health_bank": 0.0 if host._fighting_runtime().blue_guy_health_full() else clampf(host.blue_guy_health_bank, 0.0, host.BLUE_GUY_HEALTH_REGEN_SECONDS),
		"mats": host.material_runtime.save_wallet(),
		"log_currency": maxi(0, host.material_runtime.legacy_softwood_amount),
		"fish_currency": maxf(0.0, host.fish_currency),
		"fish_currency_ever_earned": host.fish_currency_ever_earned or host.fish_currency > 0.0,
		"auto_eat_fish_enabled": not host._auto_eat_fish_enabled_by_skill_for_save().is_empty(),
		"auto_eat_fish_enabled_by_skill": host._auto_eat_fish_enabled_by_skill_for_save(),
		"passive_modules": host._passive_modules_runtime().for_save(),
		"convergence_modules": host._convergence_runtime()._convergence_modules_for_save(),
		"built_modules": BuildableModules.normalized_for_save(host.built_modules, Callable(host, "_action_data")),
		"completed_bosses": host._fighting_runtime().completed_bosses_for_save(),
		"temporary_events": host._temporary_event_runtime()._temporary_events_for_save(),
		"thieving_trophies": host.thieving_state.trophies_for_save(),
		"thieving_action_jails": host.thieving_state.action_jails_for_save(now, func(skill_id: String, action_id: String) -> String: return ModuleUiRuntime.canonical_action_id(skill_id, action_id, host.FISHING_ACTION_ID_ALIASES), Callable(host, "_action_data")),
		"hub_modules": host._hub_runtime().modules_for_save(),
		"hub_selected_module_id": host._hub_runtime().selected_module_id_for_save(),
		"hub_module_positions": host._hub_surface()._hub_module_positions_for_save(),
		"hub_decor_layout": host._hub_surface()._normalized_hub_decor_layout(host._hub_surface().hub_decor_layout),
		"hub_missions": host._hub_runtime().missions_for_save(),
		"hub_mission_cooldown_until_unix": maxi(0, host._hub_runtime().hub_mission_cooldown_until_unix),
		"hub_tutorial_tip_seen": host._hub_surface().hub_tutorial_tip_seen,
		"manual_activity_unlocks": host._activity_unlock_runtime()._manual_activity_unlocks_for_save(),
		"manual_activity_requirement_unlocks": host._activity_unlock_runtime()._manual_activity_requirement_unlocks_for_save(),
		"berry_prep": host.material_runtime.berry_prep_for_save(Callable(host, "_action_data")),
		"plank_boost_enabled": bool(host.plank_boost_enabled),
		"activity_crit_seen": host.activity_crit_seen,
		"activity_mega_crit_seen": host.activity_mega_crit_seen,
		"achievement_toast_seen_ids": AchievementState.normalized_seen_ids(achievement_toast_seen_ids),
		"ad_bonus_seconds_remaining": clampf(host.ad_bonus_seconds_remaining, 0.0, float(host.AD_BONUS_MAX_SECONDS)),
		"shop_rate_prompt_dismissed": host.shop_rate_prompt_dismissed,
		"selected_skill_id": _selected_skill_id_for_save(),
		"running_skill_id": _running_skill_id_for_save(),
		"running_action_id": _running_action_id_for_save(),
		"action_progress": _action_progress_for_save(),
		"event_running_skill_id": _event_running_skill_id_for_save(),
		"event_running_action_id": _event_running_action_id_for_save(),
		"event_action_progress": _event_action_progress_for_save(),
		"activity_queue": host._activity_queue_runtime()._activity_queue_for_save(),
		"module_ui_pinned_order": host.module_ui_runtime.pinned_order_for_save(Callable(host, "_module_ui_key_allows_pin_or_collapse")),
		"module_ui_pin_color_paths": host.module_ui_runtime.pin_color_paths_for_save(host.MODULE_PIN_COLOR_TEXTURES, Callable(host, "_module_ui_key_allows_pin_or_collapse")),
		"module_ui_collapsed": host.module_ui_runtime.collapsed_for_save(Callable(host, "_module_ui_key_allows_pin_or_collapse")),
		"module_ui_collapse_save_version": host.MODULE_UI_COLLAPSE_SAVE_VERSION,
		"module_ui_sort_mode": host.module_ui_runtime.sort_mode_for_save(),
		"module_ui_combo_first": host.module_ui_runtime.combo_first,
		"module_ui_collection_first": host.module_ui_runtime.collection_first,
		"audio_settings_version": host.AudioDirector.AUDIO_SETTINGS_VERSION,
		"music_volume": clampf(host._audio_director().music_volume, 0.0, 1.0),
		"sfx_volume": clampf(host._audio_director().sfx_volume, 0.0, 1.0),
		"music_muted": host._audio_director().music_muted,
		"sfx_muted": host._audio_director().sfx_muted,
		"show_stamina_decimal": host.show_stamina_decimal,
		"offline_progress_cap_notifications_enabled": host.offline_progress_cap_notifications_enabled,
		"dark_mode_enabled": host.dark_mode_enabled,
		"offline_progress_enabled": host.offline_progress_enabled,
		"auto_unlock_lockpads_enabled": host.auto_unlock_lockpads_enabled,
		"nav_symbol_seen_ids": host._navigation_shell()._nav_symbol_seen_ids_for_save(),
		"god_mode_enabled": host.god_mode_enabled and host._test_state_runtime()._god_mode_available(),
		"god_mode_save_tainted": host.god_mode_save_tainted,
		"activity_start_tip_seen": host.activity_start_tip_seen,
		"activity_start_count": maxi(0, host.activity_start_count),
		"activity_completion_count": maxi(0, host.activity_completion_count),
		"guaranteed_success_action_completions": clampi(host.guaranteed_success_action_completions, 0, host.GUARANTEED_SUCCESS_ACTION_COMPLETIONS),
		"onboarding_starter_action_completion_count": maxi(0, host.onboarding_starter_action_completion_count),
		"onboarding_first_module_center_released": host.onboarding_first_module_center_released,
		"onboarding_header_reveal_after_progress": host.onboarding_header_reveal_after_progress,
		"onboarding_swipe_tip_eligible": host.onboarding_swipe_tip_eligible,
		"onboarding_swipe_navigation_unlocked": host.onboarding_swipe_navigation_unlocked,
		"skill_swipe_tip_seen": host.skill_swipe_tip_seen,
		"onboarding_explore_tip_seen": host.onboarding_explore_tip_seen,
		"onboarding_tutorial_complete": host.onboarding_tutorial_complete,
		"tutorial_active": host.tutorial_active,
		"tutorial_step": host.tutorial_step,
		"tutorial_gate_latch_only_until_swipe": host.tutorial_gate_latch_only_until_swipe and not host.onboarding_tutorial_complete and not host.skill_swipe_tip_seen,
		"stamina_gauge_tip_seen": host.stamina_gauge_tip_seen,
		"onboarding_fight_summary_revealed": host.onboarding_fight_summary_revealed,
		"onboarding_fight_auto_run_message_shown": host.onboarding_fight_auto_run_message_shown,
		"onboarding_fight_stamina_revealed": host.onboarding_fight_stamina_revealed,
		"onboarding_fight_action_stats_revealed": host.onboarding_fight_action_stats_revealed,
		"onboarding_medal_tip_shown": host.onboarding_medal_tip_shown,
		"lock_click_tip_seen": host.lock_click_tip_seen,
		"passive_module_tip_seen": host.passive_module_tip_seen,
		"silver_opportunity_tip_seen": host.silver_opportunity_tip_seen,
		"silver_opportunity_tip_action_key": _action_key_for_save(host.silver_opportunity_tip_action_key),
		"detail_pull_recent_tip_texts": TipState.normalized_recent_tip_texts(host.detail_pull_recent_tip_texts, host.DETAIL_PULL_TIP_TEXTS),
		"stamina_gauge_pre_tip_hold_seconds": clampf(host.stamina_gauge_pre_tip_hold_seconds, 0.0, host.STAMINA_TIP_DISCOVERY_HOLD_SECONDS),
		"music_start_chance_unlocked": host._audio_director().music_start_chance_unlocked,
		"flow_heat": clampf(host._audio_director().flow_heat, 0.0, 36.0),
		"flow_active_action_seconds": maxf(0.0, host._audio_director().flow_active_action_seconds),
		"leaderboard_last_submitted_score": maxi(0, int(host.leaderboard_last_submitted_score)),
		"leaderboard_last_submitted_total_xp": maxi(0, int(host.leaderboard_last_submitted_total_xp)),
		"leaderboard_last_submitted_scores_by_category": host._leaderboard_state().last_submitted_scores_for_save(),
		"leaderboard_last_submit_unix": maxi(0, int(host.leaderboard_last_submit_unix)),
		"leaderboard_repair_publish_version": clampi(int(host.leaderboard_repair_publish_version), 0, host.LEADERBOARD_REPAIR_PUBLISH_VERSION),
		"leaderboard_display_name": LeaderboardProfile.display_name_for_save(host, host.PROFILE_DISPLAY_NAME_MAX_CHARS),
		"leaderboard_name_key": LeaderboardProfile.name_key_for_save(host, host.PROFILE_GUEST_NAME_PREFIX, host.PROFILE_DISPLAY_NAME_MAX_CHARS, host.PROFILE_NAME_KEY_MAX_CHARS),
		"leaderboard_avatar_index": LeaderboardProfile.avatar_index_for_save(host, ProfileChatOverlaySurface.PROFILE_AVATAR_COUNT),
		"leaderboard_profile_claimed": LeaderboardProfile.profile_claimed_for_save(host, host.PROFILE_GUEST_NAME_PREFIX, host.PROFILE_DISPLAY_NAME_MAX_CHARS, host.PROFILE_NAME_KEY_MAX_CHARS),
		"leaderboard_name_claim_verified": LeaderboardProfile.name_claim_verified_for_save(host, host.PROFILE_GUEST_NAME_PREFIX, host.PROFILE_DISPLAY_NAME_MAX_CHARS, host.PROFILE_NAME_KEY_MAX_CHARS),
		"leaderboard_player_id": LeaderboardProfile.player_id_for_save(host),
		"leaderboard_auth_provider": LeaderboardProfile.auth_provider_for_save_host(host),
		"leaderboard_auth_refresh_token": LeaderboardProfile.auth_refresh_token_for_save(host),
		"leaderboard_auth_retry_after_unix": maxi(0, int(host.leaderboard_auth_retry_after_unix)),
		"leaderboard_fetch_retry_unix_by_category": host._leaderboard_state().fetch_retry_unix_by_category_for_save(),
		# Chat rows are not saved; the realtime stream is reopened only while the skills chat strip is visible.
		"chat_last_send_unix": maxi(0, int(host.chat_last_send_unix)),
		"chat_stream_retry_unix": host.ChatState.retry_unix_for_save(host.chat_stream_retry_unix, now, host.CHAT_STREAM_RETRY_INTERVAL_SECONDS),
		"chat_stream_next_connect_unix": host.ChatState.next_connect_unix_for_save(host.chat_stream_retry_unix, host.chat_stream_next_connect_unix, now, host.CHAT_STREAM_RETRY_INTERVAL_SECONDS),
		"chat_last_opened_created_at": maxi(0, int(host.chat_last_opened_created_at)),
		"chat_last_opened_message_id": host.ChatState.normalized_message_id(host.chat_last_opened_message_id),
		"last_result": host.last_result,
		"saved_at": now
	}
	payload.merge(host.fishing_runtime.save_payload(
		host.FISHING_NET_HAUL_THRESHOLD,
		host.FISHING_BOAT_HAUL_THRESHOLD,
		Callable(host.fishing_runtime, "tool_is_unlocked"),
		Callable(host.fishing_runtime, "area_metadata_loaded"),
		Callable(host.fishing_runtime, "location_id_valid").bind(host.FISHING_LOCATION_DEFS)
	), true)
	return payload



func _autosave_if_needed() -> void:
	if host.save_dirty or _autosave_has_live_state_changes():
		host.save_game()



func _autosave_has_live_state_changes() -> bool:
	if not host.startup_initialized:
		return false
	if not host.running_skill_id.is_empty():
		return true
	if not host.thieving_action_jails.is_empty():
		return true
	if host.ad_bonus_seconds_remaining > 0.0:
		return true
	for raw_module_id in host.HUB_MODULE_ORDER:
		if host._hub_surface()._hub_module_building(str(raw_module_id)):
			return true
	for raw_module_id in host.convergence_modules.keys():
		if host._convergence_runtime()._convergence_is_building(str(raw_module_id)):
			return true
	for raw_skill_id in host.skills.keys():
		var skill_id = str(raw_skill_id)
		if host._stamina_value(skill_id) < float(host._max_stamina(skill_id)) - 0.0001:
			return true
	if host._fighting_runtime().blue_guy_health_value() < float(host.BLUE_GUY_HEALTH_MAX) - 0.0001:
		return true
	if host.offline_progress_enabled:
		for raw_action in host.actions_by_skill.get("woodcutting", []):
			var action = raw_action as Dictionary
			if not host._is_passive_action(action):
				continue
			var module_id = str(action.get("id", host.WOODCUTTING_LOG_MODULE_ID))
			if host._passive_modules_runtime().is_passive_module_unlocked(module_id):
				return true
	return false



func _trusted_offline_seconds(saved_at_unix_time: int, now_unix_time: int) -> int:
	var wall_elapsed = now_unix_time - saved_at_unix_time
	if wall_elapsed <= 0:
		return 0
	return int(clamp(wall_elapsed, 0, host._hub_surface()._hub_offline_cap_seconds()))



func _apply_offline_progress(saved_at_unix_time: int) -> int:
	var now = host._unix_now()
	host.last_save_unix_time = now
	var offline = _trusted_offline_seconds(saved_at_unix_time, now)
	if offline <= 0:
		return 0
	if not host.offline_progress_enabled:
		host.ad_bonus_seconds_remaining = maxf(0.0, host.ad_bonus_seconds_remaining - float(offline))
		return 0
	var active_result = host._action_runtime()._apply_offline_active_action(float(offline))
	if not bool(active_result.get("handled", false)):
		host._apply_stamina_regen_seconds(float(offline), false)
		host._fighting_runtime().apply_blue_guy_health_regen_seconds(float(offline))
	host.ad_bonus_seconds_remaining = maxf(0.0, host.ad_bonus_seconds_remaining - float(offline))
	host._set_offline_result_text(float(offline), active_result)
	host._achievement_overlay_surface()._maybe_show_offline_summary(float(offline), active_result)
	return offline



func load_game() -> void:
	host.loaded_save_this_boot = false
	pending_save_restore_data = {}
	pending_save_has_achievement_toast_seen_ids = false
	var boot_save = _boot_save_dictionary()
	var save_data = boot_save.get("data", {}) as Dictionary
	if save_data.is_empty():
		_start_new_save_file()
		return
	var recovered_save = bool(boot_save.get("recovered", false))
	var save_needed_repair = _repair_save_for_regular_play(save_data)
	save_repaired_this_boot = recovered_save or save_needed_repair
	_load_game_core(save_data)
	pending_save_has_achievement_toast_seen_ids = save_data.has("achievement_toast_seen_ids")
	pending_save_restore_data = save_data
	host.loaded_save_this_boot = true
	_restore_boot_render_save_fields(save_data)
	if not host._onboarding_runtime()._onboarding_path_active() and not host.running_skill_id.is_empty() and host.skills.has(host.running_skill_id) and not host._action_data(host.running_skill_id, host.running_action_id).is_empty():
		host.selected_skill_id = host.running_skill_id


func _clear_pending_save_restore_work() -> void:
	pending_save_restore_data = {}
	pending_save_has_achievement_toast_seen_ids = false
	pending_post_load_saved_at = -1
	boot_post_load_simulation_scheduled = false
	save_repaired_this_boot = false


func _load_game_secondary_restore() -> void:
	if pending_save_restore_data.is_empty():
		return
	var restored_save := pending_save_restore_data
	pending_save_restore_data = {}
	achievement_toast_seen_ids = AchievementState.normalized_seen_ids(restored_save.get("achievement_toast_seen_ids", {}))
	if not pending_save_has_achievement_toast_seen_ids:
		AchievementState.mark_completed_seen_ids(AchievementState.milestones(host, false), achievement_toast_seen_ids, ["activity-crit", "activity-mega-crit"])
	pending_save_has_achievement_toast_seen_ids = false
	_restore_thieving_trophies_from_save(restored_save)
	_restore_activity_crit_metadata_from_save(restored_save)
	if not _save_needs_fishing_restore(restored_save):
		host.fish_currency = maxf(0.0, float(restored_save.get("fish_currency", host.fish_currency)))
		host.fish_currency_ever_earned = bool(restored_save.get("fish_currency_ever_earned", host.fish_currency_ever_earned or host.fish_currency > 0.0))
		host._restore_auto_eat_fish_enabled_from_save(restored_save)
		host._restore_fishing_state_from_save(restored_save)
	host._passive_modules_runtime().restore_from_save(restored_save, true)
	if host.convergence_modules.is_empty():
		host._convergence_runtime()._restore_convergence_modules_from_save(restored_save)
	host._hub_runtime().restore_modules(restored_save.get("hub_modules", {}))
	host._hub_runtime().restore_selected_module_id(restored_save)
	host._hub_surface()._restore_hub_module_positions(restored_save.get("hub_module_positions", {}))
	host._hub_surface()._restore_hub_decor_layout(restored_save.get("hub_decor_layout", []))
	host._hub_runtime().restore_missions(restored_save.get("hub_missions", []))
	host._hub_runtime().restore_mission_cooldown(restored_save)
	_restore_boot_visible_tip_flags_from_save(restored_save)
	host.plank_boost_enabled = SaveStateNormalizers.bool_value(restored_save, "plank_boost_enabled")
	host._ad_bonus_runtime().restore_seconds_from_save(restored_save)
	host.activity_start_count = SaveStateNormalizers.nonnegative_int(restored_save, "activity_start_count")
	host.activity_completion_count = SaveStateNormalizers.nonnegative_int(restored_save, "activity_completion_count")
	host.guaranteed_success_action_completions = SaveStateNormalizers.clamped_int(restored_save, "guaranteed_success_action_completions", 0, host.GUARANTEED_SUCCESS_ACTION_COMPLETIONS, host.activity_completion_count)
	_restore_onboarding_progression_from_save(restored_save)
	host._restore_tip_metadata_from_save(restored_save)
	host.stamina_gauge_pre_tip_hold_seconds = SaveStateNormalizers.clamped_float(restored_save, "stamina_gauge_pre_tip_hold_seconds", 0.0, host.STAMINA_TIP_DISCOVERY_HOLD_SECONDS)
	host._audio_director().restore_music_flow_state(restored_save)
	host._leaderboard_state().restore_submission_metadata_from_save(restored_save)
	LeaderboardProfile.restore_profile_metadata_from_save(host, restored_save, host.PROFILE_GUEST_NAME_PREFIX, host.PROFILE_DISPLAY_NAME_MAX_CHARS, host.PROFILE_NAME_KEY_MAX_CHARS, ProfileChatOverlaySurface.PROFILE_AVATAR_COUNT)
	LeaderboardProfile.restore_auth_metadata_from_save(host, restored_save)
	host._leaderboard_state().restore_fetch_metadata_from_save(restored_save)
	host.chat_last_send_unix = maxi(0, int(restored_save.get("chat_last_send_unix", 0)))
	var restored_chat_retry: Dictionary = host.ChatState.restored_retry_metadata(restored_save, host._unix_now(), host.CHAT_STREAM_RETRY_INTERVAL_SECONDS)
	host.chat_stream_retry_unix = int(restored_chat_retry.get("retry_unix", 0))
	host.chat_stream_next_connect_unix = int(restored_chat_retry.get("next_connect_unix", 0))
	host.chat_last_opened_created_at = maxi(0, int(restored_save.get("chat_last_opened_created_at", 0)))
	host.chat_last_opened_message_id = host.ChatState.normalized_message_id(restored_save.get("chat_last_opened_message_id", ""))
	_apply_legacy_clock_guard_leaderboard_forgiveness(restored_save)
	host._navigation_shell()._refresh_shop_nav_unlock_state()
	if save_repaired_this_boot:
		save_repaired_this_boot = false
		host.last_result = "Save repaired. Progress will save normally."
		save_game()


func _schedule_boot_post_load_simulation() -> void:
	if boot_post_load_simulation_scheduled or pending_post_load_saved_at < 0:
		return
	boot_post_load_simulation_scheduled = true
	call_deferred("_apply_boot_post_load_simulation_after_cards")


func _save_needs_fishing_restore(data: Dictionary) -> bool:
	var selected := str(data.get("selected_skill_id", host.selected_skill_id))
	var running := str(data.get("running_skill_id", ""))
	return selected == "fishing" or running == "fishing"


func _legacy_clock_guard_was_saved(data: Dictionary) -> bool:
	return bool(data.get("offline_clock_guard_tainted", false)) or int(data.get("offline_clock_guard_last_rejected_unix", 0)) > 0


func _apply_legacy_clock_guard_leaderboard_forgiveness(data: Dictionary) -> void:
	if not _legacy_clock_guard_was_saved(data):
		return
	host.leaderboard_last_submitted_score = 0
	host.leaderboard_last_submitted_total_xp = 0
	host.leaderboard_last_submitted_scores_by_category.clear()
	host.leaderboard_last_submit_unix = 0
	host.leaderboard_fetch_retry_unix_by_category.clear()
	host.leaderboard_auth_retry_after_unix = 0
	host.chat_last_send_unix = 0
	host.chat_stream_retry_unix = 0
	host.chat_stream_next_connect_unix = 0
	var old_result := str(host.last_result)
	if old_result.to_lower().find("clock") >= 0:
		host.last_result = ""
	host.leaderboard_status_message = ""
	host.chat_status_message = ""
	_mark_save_dirty("legacy clock guard forgiven")


func _apply_boot_post_load_simulation_after_cards() -> void:
	var wait_started_msec := Time.get_ticks_msec()
	while (
		host.is_inside_tree()
		and pending_post_load_saved_at >= 0
		and (host.boot_detail_render_in_progress or host.boot_detail_scroll_locked or not host.boot_detail_render_queue.is_empty())
	):
		if Time.get_ticks_msec() - wait_started_msec >= 5000:
			break
		await host.get_tree().process_frame
	if not host.is_inside_tree():
		return
	boot_post_load_simulation_scheduled = false
	_apply_post_load_simulation()


func _apply_post_load_simulation() -> void:
	if pending_post_load_saved_at < 0:
		return
	var saved_at := pending_post_load_saved_at
	pending_post_load_saved_at = -1
	_apply_offline_progress(saved_at)
	var now: int = host._unix_now()
	host._passive_modules_runtime().sync_passive_module_unlocks(now)
	if host.offline_progress_enabled:
		host._passive_modules_runtime().apply_passive_module_production(now)
	else:
		host._passive_modules_runtime().reset_passive_module_timestamps(now)
	host.last_passive_process_unix = now
	host._ensure_all_thieving_trophy_state()
	host._hub_surface()._validate_hub_module_positions()
	host._hub_runtime().sync_missions()
	host._hub_runtime().sync_trophy_level_from_thieving()
	if not host._audio_director().music_start_chance_unlocked and host._audio_director()._saved_music_groove_floor() >= host._audio_director().MUSIC_BASE_ACTION_THRESHOLD:
		host._audio_director().music_start_chance_unlocked = true
	host._audio_director()._maybe_start_music_cycle_on_launch()
	host._invalidate_stat_caches()
	host._update_ui(0.0, true)



func _boot_save_dictionary() -> Dictionary:
	if FileAccess.file_exists(host.SAVE_PATH):
		var save_data = SaveStateFiles.load_dictionary(host.SAVE_PATH)
		var recovery_data = _recovery_save_dictionary()
		if SaveStateFiles.should_replace_best_save(save_data, recovery_data, host.skill_defs):
			return {"data": recovery_data, "recovered": true}
		if not save_data.is_empty():
			return {"data": save_data, "recovered": false}
	var recovered_save = _recovery_save_dictionary()
	if not recovered_save.is_empty():
		return {"data": recovered_save, "recovered": true}
	var legacy_save = _legacy_desktop_save_for_recovery({})
	return {"data": legacy_save, "recovered": not legacy_save.is_empty()}



func _start_new_save_file() -> void:
	host.selected_skill_id = "fight"
	host.current_screen = "skill"
	host.last_save_unix_time = host._unix_now()
	host.save_game()



func _recovery_save_dictionary() -> Dictionary:
	var best_save = SaveStateFiles.best_dictionary_from_paths([host.SAVE_TEMP_PATH, host.SAVE_BACKUP_PATH], host.skill_defs)
	if not best_save.is_empty():
		push_warning("Idle Elite recovered save progress from backup storage.")
	return best_save



func _legacy_desktop_save_for_recovery(current_data: Dictionary) -> Dictionary:
	for path in _legacy_desktop_save_paths():
		if not FileAccess.file_exists(path):
			continue
		var legacy_data = SaveStateFiles.load_dictionary(path)
		if _save_should_use_legacy_desktop_recovery(current_data, legacy_data):
			return _prepare_legacy_desktop_save_for_recovery(legacy_data)
	return {}



func _legacy_desktop_save_paths() -> Array:
	if OS.has_feature("web"):
		return []
	var user_dir = ProjectSettings.globalize_path("user://")
	while user_dir.ends_with("/") or user_dir.ends_with("\\"):
		user_dir = user_dir.substr(0, user_dir.length() - 1)
	if user_dir.is_empty():
		return []
	var app_userdata_dir = user_dir.get_base_dir()
	if app_userdata_dir.is_empty() or app_userdata_dir == user_dir:
		return []
	return [
		app_userdata_dir.path_join("Idle Elite").path_join("idle_elite_save.json"),
		app_userdata_dir.path_join("Idle Slop").path_join("idle_elite_save.json"),
	]



func _save_should_use_legacy_desktop_recovery(current_data: Dictionary, legacy_data: Dictionary) -> bool:
	if legacy_data.is_empty() or not SaveStateNormalizers.has_known_skill_progress(legacy_data, host.skill_defs):
		return false
	if _save_has_unmarked_maxed_skills(legacy_data):
		return false
	return not SaveStateNormalizers.has_known_skill_progress(current_data, host.skill_defs)



func _prepare_legacy_desktop_save_for_recovery(data: Dictionary) -> Dictionary:
	var prepared = data.duplicate(true)
	_normalize_legacy_desktop_skill_levels(prepared)
	return prepared



func _normalize_legacy_desktop_skill_levels(data: Dictionary) -> void:
	var loaded_skills = data.get("skills", {})
	if typeof(loaded_skills) != TYPE_DICTIONARY:
		return
	var source = loaded_skills as Dictionary
	for raw_def in host.skill_defs:
		var skill_def = raw_def as Dictionary
		var skill_id = str(skill_def.get("id", ""))
		if skill_id.is_empty() or not source.has(skill_id):
			continue
		var skill_state = source.get(skill_id, {})
		if typeof(skill_state) != TYPE_DICTIONARY:
			continue
		var state = skill_state as Dictionary
		var saved_level = clampi(int(state.get("level", 1)), 1, host.GOD_MODE_TARGET_LEVEL)
		if saved_level >= host.GOD_MODE_TARGET_LEVEL:
			continue
		state["xp"] = SkillState.xp_for_level(saved_level)
		state["level"] = saved_level
		source[skill_id] = state
	data["skills"] = source



func _repair_save_for_regular_play(data: Dictionary) -> bool:
	var repaired = _repair_manual_activity_unlock_corruption(data)
	if _repair_onboarding_progress_mismatch(data):
		repaired = true
	if _repair_onboarding_gate_latch_checkpoint(data):
		repaired = true
	if _repair_impossible_thieving_trophies(data):
		repaired = true
	if bool(data.get("god_mode_save_tainted", false)) or bool(data.get("god_mode_enabled", false)):
		data["god_mode_enabled"] = false
		data["god_mode_save_tainted"] = false
		repaired = true
	if _save_has_unmarked_maxed_skills(data):
		_repair_maxed_skill_progression(data)
		data.erase("manual_activity_unlocks")
		data.erase("manual_activity_requirement_unlocks")
		repaired = true
	return repaired



func _repair_impossible_thieving_trophies(data: Dictionary) -> bool:
	var loaded_trophies = data.get("thieving_trophies", {})
	if typeof(loaded_trophies) != TYPE_DICTIONARY:
		return false
	var trophies = loaded_trophies as Dictionary
	var thieving_level = _saved_skill_level_for_repair(data, "thieving")
	var repaired = false
	for raw_heist in host.THIEVING_HEIST_DEFS:
		var heist = raw_heist as Dictionary
		var heist_id = str(heist.get("id", ""))
		if heist_id.is_empty() or not trophies.has(heist_id):
			continue
		var raw_state = trophies.get(heist_id, {})
		var stolen = false
		if typeof(raw_state) == TYPE_DICTIONARY:
			stolen = bool((raw_state as Dictionary).get("stolen", false))
		elif typeof(raw_state) == TYPE_BOOL:
			stolen = bool(raw_state)
		if not stolen or thieving_level >= int(heist.get("unlock", 1)):
			continue
		if typeof(raw_state) == TYPE_DICTIONARY:
			var state = (raw_state as Dictionary).duplicate(true)
			state["stolen"] = false
			state["cooldown_until_unix"] = 0
			trophies[heist_id] = state
		else:
			trophies[heist_id] = {"stolen": false, "cooldown_until_unix": 0}
		repaired = true
	if repaired:
		data["thieving_trophies"] = trophies
	return repaired



func _saved_skill_level_for_repair(data: Dictionary, skill_id: String) -> int:
	var loaded_skills = data.get("skills", {})
	if typeof(loaded_skills) != TYPE_DICTIONARY:
		return 1
	var skill_state = (loaded_skills as Dictionary).get(skill_id, {})
	if typeof(skill_state) != TYPE_DICTIONARY:
		return 1
	var state = skill_state as Dictionary
	if state.has("xp"):
		return SkillState.skill_level_for_xp(maxi(0, int(state.get("xp", 0))))
	return clampi(int(state.get("level", 1)), 1, host.GOD_MODE_TARGET_LEVEL)



func _repair_onboarding_progress_mismatch(data: Dictionary) -> bool:
	if bool(data.get("onboarding_tutorial_complete", false)):
		return false
	if not SaveStateNormalizers.has_progress_beyond_onboarding(data, host.skill_defs, host.TUTORIAL_STARTER_SKILL_ID):
		return false
	SaveStateNormalizers.mark_onboarding_complete(data)
	return true



func _repair_onboarding_gate_latch_checkpoint(data: Dictionary) -> bool:
	if not _save_should_restore_tutorial_gate_latch(data):
		return false
	var repaired = false
	if bool(data.get("tutorial_active", false)):
		data["tutorial_active"] = false
		repaired = true
	if not bool(data.get("tutorial_gate_latch_only_until_swipe", false)):
		data["tutorial_gate_latch_only_until_swipe"] = true
		repaired = true
	return repaired



func _save_should_restore_tutorial_gate_latch(data: Dictionary) -> bool:
	if bool(data.get("onboarding_tutorial_complete", false)):
		return false
	if bool(data.get("skill_swipe_tip_seen", false)):
		return false
	return _save_starter_level_two_unlocked(data)



func _save_starter_level_two_unlocked(data: Dictionary) -> bool:
	var level_two_key = host._action_key(host.TUTORIAL_STARTER_SKILL_ID, host.TUTORIAL_LEVEL_TWO_ACTION_ID)
	var raw_manual = data.get("manual_activity_unlocks", {})
	if typeof(raw_manual) == TYPE_DICTIONARY:
		var manual = raw_manual as Dictionary
		return bool(manual.get(level_two_key, false))
	var level_two_action = host._action_data(host.TUTORIAL_STARTER_SKILL_ID, host.TUTORIAL_LEVEL_TWO_ACTION_ID)
	return not level_two_action.is_empty() and _save_action_requirements_met(data, host.TUTORIAL_STARTER_SKILL_ID, level_two_action)



func _repair_manual_activity_unlock_corruption(data: Dictionary) -> bool:
	var raw_manual = data.get("manual_activity_unlocks", {})
	if typeof(raw_manual) != TYPE_DICTIONARY:
		return false
	var manual = raw_manual as Dictionary
	if manual.is_empty():
		return false
	var valid = {}
	var impossible_count = 0
	var manual_count = 0
	for raw_key in manual.keys():
		if not bool(manual.get(raw_key, false)):
			continue
		var key = host._activity_unlock_runtime()._canonical_manual_activity_unlock_key(str(raw_key))
		if key.is_empty():
			continue
		manual_count += 1
		var action_ref = _action_ref_from_key(key)
		if action_ref.is_empty():
			valid[key] = true
			continue
		var skill_id = str(action_ref.get("skill_id", ""))
		var action = action_ref.get("action", {}) as Dictionary
		if _save_action_requirements_met(data, skill_id, action):
			valid[key] = true
		else:
			impossible_count += 1
	if manual_count <= 0:
		return false
	var bulk_corruption = manual_count >= 50 and impossible_count >= maxi(12, int(float(manual_count) * 0.45))
	if bulk_corruption:
		data["manual_activity_unlocks"] = {}
		return true
	if impossible_count <= 0:
		return false
	data["manual_activity_unlocks"] = valid
	return true



func _action_ref_from_key(key: String) -> Dictionary:
	var parts = key.split(":", false, 2)
	if parts.size() < 2:
		return {}
	var skill_id = str(parts[0])
	var action_id = str(parts[1])
	if skill_id.is_empty() or action_id.is_empty():
		return {}
	for raw_action in host.actions_by_skill.get(skill_id, []):
		var action = raw_action as Dictionary
		if str(action.get("id", "")) == action_id:
			return {
				"skill_id": skill_id,
				"action": action
			}
	return {}



func _save_action_requirements_met(data: Dictionary, skill_id: String, action: Dictionary) -> bool:
	if action.is_empty():
		return false
	for raw_requirement in host._activity_unlock_runtime()._action_unlock_requirements(skill_id, action):
		if typeof(raw_requirement) != TYPE_DICTIONARY:
			return false
		var requirement = raw_requirement as Dictionary
		var requirement_skill = str(requirement.get("skill", skill_id))
		if _save_skill_level(data, requirement_skill) < int(requirement.get("level", 1)):
			return false
	return true



func _save_skill_level(data: Dictionary, skill_id: String) -> int:
	var loaded_skills = data.get("skills", {})
	if typeof(loaded_skills) != TYPE_DICTIONARY:
		return 1
	var skill_state = (loaded_skills as Dictionary).get(skill_id, {})
	if typeof(skill_state) != TYPE_DICTIONARY:
		return 1
	var state = skill_state as Dictionary
	var xp = maxi(0, int(state.get("xp", 0)))
	return maxi(1, maxi(int(state.get("level", 1)), SkillState.skill_level_for_xp(xp)))



func _repair_maxed_skill_progression(data: Dictionary) -> void:
	var loaded_skills = data.get("skills", {})
	if typeof(loaded_skills) != TYPE_DICTIONARY:
		return
	var source = loaded_skills as Dictionary
	var target_xp = SkillState.xp_for_level(host.GOD_MODE_TARGET_LEVEL)
	for raw_def in host.skill_defs:
		var skill_def = raw_def as Dictionary
		var skill_id = str(skill_def.get("id", ""))
		if skill_id.is_empty() or not source.has(skill_id):
			continue
		var skill_state = source.get(skill_id, {})
		if typeof(skill_state) != TYPE_DICTIONARY:
			continue
		var state = skill_state as Dictionary
		var xp = maxi(0, int(state.get("xp", 0)))
		var level = maxi(int(state.get("level", 0)), SkillState.skill_level_for_xp(xp))
		if level < host.GOD_MODE_TARGET_LEVEL and xp < target_xp:
			continue
		var repaired_xp = _estimated_repaired_skill_xp(data, skill_id)
		state["xp"] = repaired_xp
		state["level"] = SkillState.skill_level_for_xp(repaired_xp)
		source[skill_id] = state
	data["skills"] = source



func _estimated_repaired_skill_xp(data: Dictionary, skill_id: String) -> int:
	var evidence_xp = 0
	var mastery_data = data.get("mastery", {})
	if typeof(mastery_data) == TYPE_DICTIONARY:
		var mastery_source = mastery_data as Dictionary
		for raw_key in mastery_source.keys():
			var key = str(raw_key)
			if not key.begins_with("%s:" % skill_id):
				continue
			var entry = mastery_source.get(raw_key, {})
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			var mastery_entry = entry as Dictionary
			if int(mastery_entry.get("level", 0)) >= host.MASTERY_MAX_LEVEL:
				continue
			evidence_xp += maxi(0, int(mastery_entry.get("xp", 0)))
	if skill_id == host.TUTORIAL_STARTER_SKILL_ID:
		evidence_xp = maxi(evidence_xp, _save_activity_completion_evidence(data))
	return clampi(evidence_xp, 0, SkillState.xp_for_level(20))



func _save_has_unmarked_maxed_skills(data: Dictionary) -> bool:
	var loaded_skills = data.get("skills", {})
	if typeof(loaded_skills) != TYPE_DICTIONARY:
		return false
	var source = loaded_skills as Dictionary
	var target_xp = SkillState.xp_for_level(host.GOD_MODE_TARGET_LEVEL)
	var known_skill_count = 0
	var maxed_skill_count = 0
	var exact_god_mode_xp_count = 0
	for raw_def in host.skill_defs:
		var skill_def = raw_def as Dictionary
		var skill_id = str(skill_def.get("id", ""))
		if skill_id.is_empty() or not source.has(skill_id):
			continue
		var skill_state = source.get(skill_id, {})
		if typeof(skill_state) != TYPE_DICTIONARY:
			continue
		var state = skill_state as Dictionary
		var xp = maxi(0, int(state.get("xp", 0)))
		var level = maxi(int(state.get("level", 0)), SkillState.skill_level_for_xp(xp))
		known_skill_count += 1
		if level >= host.GOD_MODE_TARGET_LEVEL or xp >= target_xp:
			maxed_skill_count += 1
		if xp == target_xp:
			exact_god_mode_xp_count += 1
	if known_skill_count < 3 or maxed_skill_count < known_skill_count:
		return false
	if exact_god_mode_xp_count >= known_skill_count:
		return true
	return _save_activity_completion_evidence(data) < host.UNMARKED_MAXED_SAVE_COMPLETION_LIMIT



func _save_activity_completion_evidence(data: Dictionary) -> int:
	return maxi(
		maxi(0, int(data.get("activity_completion_count", 0))),
		maxi(0, int(data.get("onboarding_starter_action_completion_count", 0)))
	)



func _restore_thieving_trophies_from_save(data: Dictionary) -> void:
	host.thieving_state.restore_trophies(data.get("thieving_trophies", {}), true)



func _restore_activity_crit_metadata_from_save(data: Dictionary) -> void:
	host.activity_crit_seen = bool(data.get("activity_crit_seen", false))
	host.activity_mega_crit_seen = bool(data.get("activity_mega_crit_seen", false))
	if host.activity_mega_crit_seen:
		host.activity_crit_seen = true



func _restore_boot_visible_tip_flags_from_save(data: Dictionary) -> void:
	host.activity_start_tip_seen = bool(data.get("activity_start_tip_seen", false))
	host._hub_surface().hub_tutorial_tip_seen = bool(data.get("hub_tutorial_tip_seen", false))



func _restore_boot_render_save_fields(data: Dictionary) -> void:
	_restore_thieving_trophies_from_save(data)
	_restore_boot_visible_tip_flags_from_save(data)
	host.skill_swipe_tip_seen = bool(data.get("skill_swipe_tip_seen", false))
	host.onboarding_explore_tip_seen = bool(data.get("onboarding_explore_tip_seen", false))
	host.onboarding_tutorial_complete = bool(data.get("onboarding_tutorial_complete", false))
	host.stamina_gauge_tip_seen = bool(data.get("stamina_gauge_tip_seen", false))
	host.onboarding_fight_summary_revealed = bool(data.get("onboarding_fight_summary_revealed", false))
	host.onboarding_fight_auto_run_message_shown = bool(data.get("onboarding_fight_auto_run_message_shown", false))
	host.onboarding_fight_stamina_revealed = bool(data.get("onboarding_fight_stamina_revealed", false))
	host.onboarding_fight_action_stats_revealed = bool(data.get("onboarding_fight_action_stats_revealed", false))
	_restore_tutorial_state_from_save(data)
	_apply_onboarding_restored_completion_implications()
	_restore_tutorial_gate_latch_from_save(data)
	host._restore_tip_metadata_from_save(data)



func _onboarding_restored_completion_seen() -> bool:
	return host.stamina_gauge_tip_seen or host.skill_swipe_tip_seen or host.onboarding_explore_tip_seen or host.onboarding_tutorial_complete



func _apply_onboarding_restored_completion_implications() -> void:
	if _onboarding_restored_completion_seen():
		host.onboarding_fight_summary_revealed = true
		host.onboarding_fight_auto_run_message_shown = true
		host.onboarding_fight_stamina_revealed = true
		host.onboarding_fight_action_stats_revealed = true
	if host.onboarding_tutorial_complete or host.skill_swipe_tip_seen:
		host.onboarding_swipe_tip_eligible = true
		host.onboarding_swipe_navigation_unlocked = true



func _restore_tutorial_state_from_save(data: Dictionary) -> void:
	if host.onboarding_tutorial_complete:
		host.tutorial_active = false
		host.tutorial_step = 4
		return
	if data.has("tutorial_active"):
		host.tutorial_active = bool(data.get("tutorial_active", false))
		if host.tutorial_active and _onboarding_restored_completion_seen():
			host.tutorial_active = false
	else:
		host.tutorial_active = not _onboarding_restored_completion_seen()
	if host.tutorial_active:
		host.tutorial_step = clampi(int(data.get("tutorial_step", 1)), 1, 4)
		host.selected_skill_id = host.TUTORIAL_STARTER_SKILL_ID
		host.current_screen = "skill"
		host.onboarding_fight_summary_revealed = false
		host.onboarding_fight_auto_run_message_shown = false
		host.onboarding_fight_stamina_revealed = false
		host.onboarding_fight_action_stats_revealed = false
	else:
		host.tutorial_step = clampi(int(data.get("tutorial_step", 0)), 0, 4)



func _restore_tutorial_gate_latch_from_save(data: Dictionary) -> void:
	host.tutorial_gate_latch_only_until_swipe = _save_should_restore_tutorial_gate_latch(data)



func _restore_onboarding_progression_from_save(data: Dictionary) -> void:
	host.onboarding_starter_action_completion_count = maxi(0, int(data.get("onboarding_starter_action_completion_count", 0)))
	host.onboarding_first_module_center_released = bool(data.get(
		"onboarding_first_module_center_released",
		host.onboarding_starter_action_completion_count > 0 or int((host.skills.get(host.TUTORIAL_STARTER_SKILL_ID, {}) as Dictionary).get("xp", 0)) >= host.LOCKED_ACTIVITY_PREVIEW_XP_THRESHOLD
	))
	if host.onboarding_first_module_center_released:
		host.onboarding_first_module_center_release_pending = false
	host.onboarding_header_reveal_after_progress = bool(data.get("onboarding_header_reveal_after_progress", false))
	host.onboarding_swipe_tip_eligible = bool(data.get("onboarding_swipe_tip_eligible", false))
	host.onboarding_swipe_navigation_unlocked = bool(data.get("onboarding_swipe_navigation_unlocked", false))
	host.skill_swipe_tip_seen = bool(data.get("skill_swipe_tip_seen", false))
	host.onboarding_explore_tip_seen = bool(data.get("onboarding_explore_tip_seen", false))
	host.onboarding_tutorial_complete = bool(data.get("onboarding_tutorial_complete", false))
	host.stamina_gauge_tip_seen = bool(data.get("stamina_gauge_tip_seen", false))
	host.onboarding_fight_summary_revealed = bool(data.get("onboarding_fight_summary_revealed", false))
	var saved_auto_run_message_shown = bool(data.get("onboarding_fight_auto_run_message_shown", false))
	host.onboarding_fight_auto_run_message_shown = saved_auto_run_message_shown
	host.onboarding_fight_stamina_revealed = bool(data.get("onboarding_fight_stamina_revealed", false))
	host.onboarding_fight_action_stats_revealed = bool(data.get("onboarding_fight_action_stats_revealed", false))
	_restore_tutorial_state_from_save(data)
	host.onboarding_medal_tip_shown = bool(data.get("onboarding_medal_tip_shown", false))
	if host.onboarding_medal_tip_shown:
		host.onboarding_mastery_tip_dismissed = true
	if host.onboarding_starter_action_completion_count == 0 and saved_auto_run_message_shown:
		host.onboarding_starter_action_completion_count = 1
	if (
		not host.onboarding_header_reveal_after_progress
		and not host.onboarding_fight_summary_revealed
		and host.onboarding_starter_action_completion_count >= 2
	):
		host.onboarding_header_reveal_after_progress = true
	var completion_seen = _onboarding_restored_completion_seen()
	_apply_onboarding_restored_completion_implications()
	if not completion_seen:
		if host.onboarding_fight_action_stats_revealed:
			host.onboarding_fight_auto_run_message_shown = true
			host.onboarding_fight_stamina_revealed = true
		elif host.onboarding_fight_stamina_revealed:
			host.onboarding_fight_auto_run_message_shown = true
	if not (host.onboarding_tutorial_complete or host.skill_swipe_tip_seen):
		if host.onboarding_swipe_navigation_unlocked:
			host.onboarding_swipe_tip_eligible = true
		elif (
			host.stamina_gauge_tip_seen
			and host.onboarding_fight_action_stats_revealed
			and host._onboarding_runtime()._onboarding_fight_stamina_depleted()
		):
			host.onboarding_swipe_tip_eligible = true
			host.onboarding_swipe_navigation_unlocked = true
	_restore_tutorial_gate_latch_from_save(data)



func _load_game_core(data: Dictionary) -> void:
	host.save_reset_generation = _save_reset_generation(data)
	host.selected_skill_id = str(data.get("selected_skill_id", host.selected_skill_id))
	host.running_skill_id = str(data.get("running_skill_id", ""))
	host.running_action_id = ModuleUiRuntime.canonical_action_id(host.running_skill_id, str(data.get("running_action_id", "")), host.FISHING_ACTION_ID_ALIASES)
	host.action_progress = _normalized_action_progress(data.get("action_progress", 0.0))
	host.event_running_skill_id = str(data.get("event_running_skill_id", ""))
	host.event_running_action_id = str(data.get("event_running_action_id", ""))
	host.event_action_progress = _normalized_action_progress(data.get("event_action_progress", 0.0))
	var loaded_skills = data.get("skills", {})
	if typeof(loaded_skills) == TYPE_DICTIONARY:
		for skill_id in loaded_skills.keys():
			if host.skills.has(skill_id) and typeof(loaded_skills[skill_id]) == TYPE_DICTIONARY:
				host.skills[skill_id]["xp"] = int(loaded_skills[skill_id].get("xp", 0))
	var has_manual_activity_unlocks = data.has("manual_activity_unlocks")
	host._activity_unlock_runtime()._restore_manual_activity_unlocks(data.get("manual_activity_unlocks", {}))
	host._activity_unlock_runtime()._restore_manual_activity_requirement_unlocks(data.get("manual_activity_requirement_unlocks", {}))
	host.built_modules = BuildableModules.restored_from_save(data.get("built_modules", {}), Callable(host, "_action_data"))
	host._temporary_event_runtime()._restore_temporary_events_from_save(data.get("temporary_events", {}))
	var restored_running_action = host._action_data(host.running_skill_id, host.running_action_id)
	if not restored_running_action.is_empty() and BuildableModules.is_buildable(restored_running_action) and not BuildableModules.is_built(host.built_modules, host.running_skill_id, restored_running_action, Callable(host, "_action_key")):
		host.running_skill_id = ""
		host.running_action_id = ""
		host.action_progress = 0.0
	if not restored_running_action.is_empty() and host._is_event_action(restored_running_action):
		if host.event_running_skill_id.is_empty():
			host.event_running_skill_id = host.running_skill_id
			host.event_running_action_id = host.running_action_id
			host.event_action_progress = host.action_progress
		host.running_skill_id = ""
		host.running_action_id = ""
		host.action_progress = 0.0
	if not host.event_running_skill_id.is_empty():
		host.event_running_action_id = str(host._action_data(host.event_running_skill_id, host.event_running_action_id).get("id", host.event_running_action_id))
		if host.event_running_action_id.is_empty() or not host._is_event_action(host._action_data(host.event_running_skill_id, host.event_running_action_id)):
			host.event_running_skill_id = ""
			host.event_running_action_id = ""
			host.event_action_progress = 0.0
	host.thieving_state.restore_action_jails(data.get("thieving_action_jails", {}), host._unix_now(), func(skill_id: String, action_id: String) -> String: return ModuleUiRuntime.canonical_action_id(skill_id, action_id, host.FISHING_ACTION_ID_ALIASES), Callable(host, "_action_data"))
	if host.running_skill_id == "thieving" and host._thieving_surface()._thieving_action_is_jailed(host.running_action_id):
		host.running_skill_id = ""
		host.running_action_id = ""
		host.action_progress = 0.0
	host.mastery = MasteryState.restored_from_save(data.get("mastery", {}), Callable(host, "_canonical_action_key"), host.MASTERY_MAX_LEVEL)
	for skill_id in host.skills.keys():
		host._recalculate_level(str(skill_id), false)
	if not has_manual_activity_unlocks:
		host._sync_legacy_manual_activity_unlocks_from_levels()
	var loaded_stamina = data.get("stamina", {})
	if typeof(loaded_stamina) == TYPE_DICTIONARY:
		for skill_id in loaded_stamina.keys():
			if host.stamina.has(skill_id):
				host.stamina[skill_id] = clampf(float(loaded_stamina[skill_id]), 0.0, float(host._max_stamina(str(skill_id))))
	var loaded_bank = data.get("stamina_bank", {})
	if typeof(loaded_bank) == TYPE_DICTIONARY:
		for skill_id in loaded_bank.keys():
			if host.stamina_bank.has(skill_id):
				host.stamina_bank[skill_id] = float(loaded_bank[skill_id])
				host._sync_stamina_bank(str(skill_id))
	host.honey_stamina_seconds_remaining = clampf(
		float(data.get("honey_stamina_seconds_remaining", 0.0)),
		0.0,
		host.HONEY_STAMINA_SECONDS_PER_CONSUMPTION
	)
	host.blue_guy_health = clampf(float(data.get("blue_guy_health", host.BLUE_GUY_HEALTH_MAX)), 0.0, float(host.BLUE_GUY_HEALTH_MAX))
	host.blue_guy_health_bank = clampf(float(data.get("blue_guy_health_bank", 0.0)), 0.0, host.BLUE_GUY_HEALTH_REGEN_SECONDS)
	if host._fighting_runtime().blue_guy_health_full():
		host.blue_guy_health_bank = 0.0
	host.material_runtime.legacy_softwood_amount = maxi(0, int(data.get("log_currency", host.material_runtime.legacy_softwood_amount)))
	host.material_runtime.restore_wallet(data)
	if _save_needs_fishing_restore(data):
		host._restore_fishing_state_from_save(data)
	host.offline_progress_enabled = bool(data.get("offline_progress_enabled", true))
	host.auto_unlock_lockpads_enabled = bool(data.get("auto_unlock_lockpads_enabled", false))
	host._navigation_shell()._restore_nav_symbol_seen_ids(data.get("nav_symbol_seen_ids", {}))
	if host.module_ui_runtime.restore_from_save(
		data,
		host.MODULE_PIN_COLOR_TEXTURES,
		host.MODULE_PIN_ICON_TEXTURE,
		Callable(host, "_module_ui_key_allows_pin_or_collapse")
	):
		host._mark_save_dirty("module collapse migration")
	host._activity_queue_runtime()._restore_activity_queue_from_save(data)
	host._fighting_runtime().restore_completed_bosses_from_save(data.get("completed_bosses", {}))
	host.material_runtime.restore_berry_prep(data.get("berry_prep", {}), Callable(host, "_action_data"), Callable(host, "_action_key"))
	host.shop_rate_prompt_dismissed = bool(data.get("shop_rate_prompt_dismissed", false))
	host.god_mode_enabled = bool(data.get("god_mode_enabled", false)) and host._test_state_runtime()._god_mode_available()
	host.god_mode_save_tainted = bool(data.get("god_mode_save_tainted", false))
	host.guaranteed_success_action_completions = SaveStateNormalizers.clamped_int(data, "guaranteed_success_action_completions", 0, host.GUARANTEED_SUCCESS_ACTION_COMPLETIONS, data.get("activity_completion_count", 0))
	host._audio_director().apply_settings_from_save(data)
	host._audio_director().music_muted = bool(data.get("music_muted", false))
	host._audio_director().sfx_muted = bool(data.get("sfx_muted", false))
	host.show_stamina_decimal = bool(data.get("show_stamina_decimal", false))
	host.offline_progress_cap_notifications_enabled = bool(data.get(
		"offline_progress_cap_notifications_enabled",
		data.get("notifications_enabled", false)
	))
	host.dark_mode_enabled = bool(data.get("dark_mode_enabled", false))
	host.last_result = str(data.get("last_result", host.last_result))
	host._audio_director()._apply_audio_bus_volumes()
	host._settings_surface().apply_dark_mode_visual()
	pending_post_load_saved_at = int(data.get("saved_at", host._unix_now()))
	host.last_save_unix_time = pending_post_load_saved_at
	host.last_save_monotonic_msec = -1
	host._passive_modules_runtime().restore_from_save(data)
	if host.selected_skill_id == "build" or host.running_skill_id == "build":
		host._convergence_runtime()._restore_convergence_modules_from_save(data)
