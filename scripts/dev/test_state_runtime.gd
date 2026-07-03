class_name TestStateRuntime
extends RefCounted

const GOD_MODE_RESOURCE_GRANT := 1000000
const MasteryState = preload("res://scripts/progression/mastery_state.gd")
const SkillState = preload("res://scripts/progression/skill_state.gd")

var host


func _init(host_ref = null) -> void:
	host = host_ref


func _clear_running_activity_for_test_mode() -> void:
	host.running_skill_id = ""
	host.running_action_id = ""
	host.action_progress = 0.0
	host.action_progress_speed_key = ""
	host.action_progress_speed_mult_current = 1.0
	host.action_stop_hold_skill_id = ""
	host.action_stop_hold_action_id = ""
	host.last_action_card_tap_key = ""
	host.last_action_card_tap_msec = 0
	host._clear_skill_swipe_button_suppression()
	if host.detail_actions_scroll != null and is_instance_valid(host.detail_actions_scroll):
		host.detail_actions_scroll.prepare_child_tap()


func _clear_activity_unlock_ceremony_test_state() -> void:
	host.pending_activity_unlock_ceremony = {}
	host.activity_unlock_ceremony_count = 0
	host.activity_unlock_ceremony_action_key = ""
	host.activity_unlock_detail_refresh_done = true
	host.activity_unlock_center_scroll_target = -1
	host._set_activity_unlock_preview_after_ceremony("")
	host.activity_unlock_heist_preview_after_ceremony_id = ""
	host._clear_activity_unlock_preview_reveal_guards()
	for raw_card in host.action_cards.values():
		if typeof(raw_card) != TYPE_DICTIONARY:
			continue
		var card := raw_card as Dictionary
		card["unlock_ceremony_pending"] = false
		card["unlock_ceremony_active"] = false
		card["unlock_ceremony_finalized"] = false
		card["unlock_ready_pending"] = false
		card.erase("lock_overlay_sync_key")


func _mark_god_mode_save_tainted(reason := "god mode") -> void:
	host.god_mode_save_tainted = true
	host.leaderboard_status_message = "Test save: leaderboard publishing paused."
	host._mark_save_dirty(reason)


func _god_mode_available() -> bool:
	return false


func _god_mode_active() -> bool:
	return host.god_mode_enabled and _god_mode_available()


func _god_mode_toggle_text() -> String:
	return "God Mode: %s" % ("ON" if _god_mode_active() else "OFF")


func _god_mode_status_text() -> String:
	if host.god_mode_save_tainted:
		return "Test save"
	return "Debug build"


func _headless_validation_mode() -> bool:
	return DisplayServer.get_name() == "headless" and not _headless_boot_smoke_mode()


func _headless_boot_smoke_mode() -> bool:
	return OS.get_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE") == "1"


func _run_headless_boot_smoke() -> void:
	var smoke_seconds := clampf(float(OS.get_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS")), 1.0, 600.0)
	await host.get_tree().create_timer(smoke_seconds).timeout
	host.get_tree().quit()


func _god_mode_max_skills_state() -> void:
	for raw_skill_id in host.skills.keys():
		var skill_id := str(raw_skill_id)
		if not host.skills.has(skill_id):
			continue
		host.skills[skill_id]["xp"] = maxi(int(host.skills[skill_id].get("xp", 0)), SkillState.xp_for_level(host.GOD_MODE_TARGET_LEVEL))
		host._recalculate_level(skill_id, false)
	host._invalidate_stat_caches()


func _god_mode_unlock_actions_state() -> void:
	var now: int = host._unix_now()
	for raw_skill_id in host.skills.keys():
		var skill_id := str(raw_skill_id)
		for raw_action in host.actions_by_skill.get(skill_id, []):
			var action := raw_action as Dictionary
			var action_id := str(action.get("id", ""))
			if action_id.is_empty():
				continue
			if host._convergence_runtime()._is_convergence_action(action):
				var convergence_state: Dictionary = host._convergence_runtime()._ensure_convergence_state(action_id)
				convergence_state["built"] = true
				convergence_state["building"] = false
				convergence_state["build_started_unix"] = 0
				host.convergence_modules[action_id] = convergence_state
			elif host._is_passive_action(action):
				host._passive_modules_runtime().ensure_passive_module_state(action_id, now)
				host._activity_unlock_runtime()._mark_action_manually_unlocked(skill_id, action_id)
			else:
				host._activity_unlock_runtime()._mark_action_manually_unlocked(skill_id, action_id)
	host._sync_manual_activity_unlocks_from_levels()


func _apply_art_review_test_unlock_all_state() -> void:
	_god_mode_max_skills_state()
	_god_mode_unlock_actions_state()
	_god_mode_unlock_fishing_tools_state()
	_god_mode_unlock_thieving_trophies_state()
	_god_mode_unlock_onboarding_state()
	_god_mode_max_hub_state()
	_god_mode_max_medals_state()
	_god_mode_clear_timers_state()
	_activate_all_temporary_events_for_art_review_test()
	host.material_runtime.set_amount("softwood", maxf(host.material_runtime.amount("softwood"), float(GOD_MODE_RESOURCE_GRANT)))
	host.material_runtime.set_amount("hardwood", maxf(host.material_runtime.amount("hardwood"), float(GOD_MODE_RESOURCE_GRANT)))
	host.fish_currency = maxf(host.fish_currency, float(GOD_MODE_RESOURCE_GRANT))
	if host.fish_currency > 0.0:
		host.fish_currency_ever_earned = true
	for raw_skill_id in host.stamina.keys():
		var skill_id := str(raw_skill_id)
		host.stamina[skill_id] = float(host._max_stamina(skill_id))
		host.stamina_bank[skill_id] = 0.0
	host._invalidate_stat_caches()


func _god_mode_unlock_fishing_tools_state() -> void:
	host.fishing_net_collected = true
	host.fishing_net_collect_pending = false
	host.fishing_rod_collected = true
	host.fishing_reinforced_rod_collected = true
	host.fishing_star_rod_collected = true
	host.fishing_boat_built = true
	host.fishing_mirror_collected = true
	if not host.fishing_runtime.tool_is_unlocked(host.equipped_fishing_tool_id):
		host.equipped_fishing_tool_id = "star_rod"
	for raw_area in host.fishing_runtime.area_definitions:
		var area := raw_area as Dictionary
		var area_id := str(area.get("id", ""))
		var locations: Array = host._fishing_locations_for_area(area_id)
		if area_id.is_empty() or locations.is_empty():
			continue
		var location := locations[0] as Dictionary
		host.selected_fishing_locations[area_id] = str(location.get("id", ""))


func _god_mode_unlock_thieving_trophies_state() -> void:
	for raw_heist in host.THIEVING_HEIST_DEFS:
		var heist := raw_heist as Dictionary
		var heist_id := str(heist.get("id", ""))
		if heist_id.is_empty():
			continue
		host.thieving_trophies[heist_id] = {"stolen": true, "cooldown_until_unix": 0}
	host.pending_thieving_trophy_reward_float.clear()
	host._hub_runtime().sync_trophy_level_from_thieving()


func _god_mode_unlock_onboarding_state() -> void:
	host.activity_start_tip_seen = true
	host.stamina_gauge_tip_seen = true
	host.lock_click_tip_seen = true
	host.passive_module_tip_seen = true
	host.silver_opportunity_tip_seen = true
	host.silver_opportunity_tip_action_key = ""
	host.skill_swipe_tip_seen = true
	host.onboarding_explore_tip_seen = true
	host.onboarding_tutorial_complete = true
	host.onboarding_swipe_tip_eligible = true
	host.onboarding_swipe_navigation_unlocked = true
	host.onboarding_fight_summary_revealed = true
	host.onboarding_fight_auto_run_message_shown = true
	host.onboarding_fight_stamina_revealed = true
	host.onboarding_fight_action_stats_revealed = true
	host.onboarding_medal_tip_shown = true
	host.onboarding_mastery_tip_dismissed = true


func _god_mode_max_hub_state() -> void:
	for raw_module_id in host.HUB_MODULE_DEFS.keys():
		var module_id := str(raw_module_id)
		var state: Dictionary = host._hub_surface()._ensure_hub_module_state(module_id)
		state["level"] = host.HUB_MODULE_MAX_LEVEL
		state["building"] = false
		state["build_started_unix_msec"] = 0
		host._hub_runtime().hub_modules[module_id] = state


func _god_mode_max_medals_state() -> void:
	for raw_skill_id in host.skills.keys():
		var skill_id := str(raw_skill_id)
		for raw_action in host.actions_by_skill.get(skill_id, []):
			var action := raw_action as Dictionary
			if host._is_passive_action(action) or host._convergence_runtime()._is_convergence_action(action):
				continue
			var action_id := str(action.get("id", ""))
			if action_id.is_empty():
				continue
			var key: String = host._action_key(skill_id, action_id)
			host.mastery[key] = {"xp": MasteryState.xp_for_level(host.MASTERY_MAX_LEVEL), "level": host.MASTERY_MAX_LEVEL}
			host._recalculate_mastery(key)


func _god_mode_clear_timers_state() -> void:
	host.thieving_action_jails.clear()
	for raw_trophy_id in host.thieving_trophies.keys():
		var trophy_id := str(raw_trophy_id)
		var state: Dictionary = host.thieving_state.ensure_trophy_state(trophy_id)
		state["cooldown_until_unix"] = 0
		host.thieving_trophies[trophy_id] = state
	for raw_module_id in host._hub_runtime().hub_modules.keys():
		var module_id := str(raw_module_id)
		var state: Dictionary = host._hub_surface()._ensure_hub_module_state(module_id)
		if bool(state.get("building", false)):
			state["level"] = mini(host.HUB_MODULE_MAX_LEVEL, int(state.get("level", 0)) + 1)
		state["building"] = false
		state["build_started_unix_msec"] = 0
		host._hub_runtime().hub_modules[module_id] = state
	for raw_module_id in host.convergence_modules.keys():
		var module_id := str(raw_module_id)
		var state: Dictionary = host._convergence_runtime()._ensure_convergence_state(module_id)
		state["built"] = true
		state["building"] = false
		state["build_started_unix"] = 0
		host.convergence_modules[module_id] = state
	host._hub_runtime().hub_mission_cooldown_until_unix = 0


func _activate_all_temporary_events_for_art_review_test() -> void:
	host._temporary_event_runtime()._activate_all_temporary_events_for_art_review_test()
