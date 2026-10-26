extends "res://scripts/tests/ham_feedback_capture.gd"


func _run() -> void:
	create_timer(150.0).timeout.connect(func(): quit(1))
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "140")
	capture_dir = "res://outputs/verification/tier-banners-oct25"
	root.size = Vector2i(1080, 1920)
	root.title = "Idle Elite | Tier banner verification"
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	for _frame in range(2400):
		await process_frame
		if game.startup_initialized and not game._boot_warmup_runtime().active:
			break
	check(game.startup_initialized and not game._boot_warmup_runtime().active, "Real main scene must boot")
	if not game.startup_initialized:
		quit(1)
		return
	AudioServer.set_bus_mute(0, true)
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	game.auto_unlock_lockpads_enabled = false
	game._action_runtime().activity_start_count = 10
	for skill in game.skill_defs:
		game.skills[skill.id] = {"xp": SkillState.xp_for_level(99), "level": 99}
	for definition in game._project_runtime().definitions.values():
		var work := {}
		for step in definition.project.steps:
			work[str(step.id)] = int(step.target)
		game._project_runtime().work[str(definition.project.id)] = work
	for skill in game.skill_defs:
		for action in game.actions_by_skill[skill.id]:
			game._activity_unlock_runtime()._mark_action_manually_unlocked(skill.id, str(action.id))
	game._test_state_runtime()._clear_activity_unlock_ceremony_test_state()
	game._save_runtime().fishing_help_seen = true
	game._hub_surface().hub_tutorial_tip_seen = true
	game._tutorial_overlay_surface()._dismiss_blocking_tip()
	game._halloween_runtime().launch_greeting_claimed = true
	game._halloween_runtime().dismiss_launch_greeting()
	var events = game._temporary_event_runtime()
	events.temporary_event_active.clear()
	events.temporary_event_next_roll_unix = game._unix_now() + 86400
	SkillState.invalidate_stat_caches(game)
	AchievementState.mark_completed_seen_ids(AchievementState.milestones(game, false), game._save_runtime().achievement_toast_seen_ids, [])
	game._achievement_toast_surface().achievement_toast_queue.clear()
	game._achievement_toast_surface().achievement_toast_queue_ids.clear()
	_check_catalog_boundaries()
	if DisplayServer.get_name() != "headless":
		DirAccess.make_dir_recursive_absolute(capture_dir)
		await _check_real_thieving_list()
	print("tier-banner-events-ok failures=", failures)
	quit(0 if failures.is_empty() else 1)


func _banner_tiers(entries: Array) -> Array:
	var tiers := []
	for entry in entries:
		if str(entry.get("kind", "")) == "tier_banner":
			tiers.append(int(entry.tier))
	return tiers


func _check_catalog_boundaries() -> void:
	var detail = game._skill_detail_surface()
	for skill in game.skill_defs:
		var skill_id := str(skill.id)
		var entries: Array = detail._visible_detail_entries_for_skill(skill_id)
		var baseline := _banner_tiers(entries)
		var expected := []
		for action in AchievementState.playable_actions_for_medal_buffs(game, skill_id):
			var tier := AchievementState.action_tier(game, action)
			if not expected.has(tier):
				expected.append(tier)
		expected.sort()
		var actual := baseline.duplicate()
		actual.sort()
		check(actual == expected, "%s must show each permanent mastery tier once: %s vs %s" % [skill_id, actual, expected])
		if skill_id == "thieving":
			check(baseline.has(8) and not baseline.has(9), "Thieving must show Tier 8 without a Tier 9")
		var permanent := []
		for entry in entries:
			if str(entry.get("kind", "")) not in ["tier_banner", "beta_notice"]:
				permanent.append(entry)
		for event_level in [1, 9, 10, 11, 75, 80, 81, 90, 99]:
			var with_event: Array = permanent.duplicate(true)
			with_event.append({"kind": "action", "action": {"id": "test-xp-opportunity", "kind": "event_activity", "unlock": event_level, "sort_unlock": event_level}})
			with_event = game.module_ui_runtime.sort_detail_entries(with_event, skill_id, Callable(detail, "_detail_entry_level_sort_value"), Callable(game._activity_unlock_runtime(), "_action_unlock_requirements"))
			check(_banner_tiers(detail._insert_tier_banners(skill_id, with_event)) == baseline, "%s level-%s XP event must not change banners" % [skill_id, event_level])
		# A hidden activity must not expose its tier's footer early.
		var medal_actions: Array = AchievementState.playable_actions_for_medal_buffs(game, skill_id)
		if not medal_actions.is_empty():
			var hidden_action: Dictionary = medal_actions.back()
			var partial := []
			for entry in permanent:
				if str(entry.get("action", {}).get("id", "")) != str(hidden_action.id):
					partial.append(entry)
			check(not _banner_tiers(detail._insert_tier_banners(skill_id, partial)).has(AchievementState.action_tier(game, hidden_action)), "%s must not show a partially revealed tier footer" % skill_id)
	check(detail._insert_tier_banners("thieving", []).is_empty(), "Empty lists must not produce banners")
	check(_banner_tiers(detail._insert_tier_banners("thieving", [{"kind": "action", "action": {"kind": "event_activity", "unlock": 99}}])).is_empty(), "Event-only lists must not produce banners")


func _check_real_thieving_list() -> void:
	game.current_screen = "menu"
	game._navigation_shell()._render_screen()
	await settle(1.0)
	game.content_scroll.scroll_vertical = 0
	await settle(0.4)
	var skill_button: Control = game.skill_cards.thieving.button
	root.grab_focus()
	await click(skill_button.get_global_rect().get_center(), true)
	await settle(1.2)
	check(game.current_screen == "skill" and game.selected_skill_id == "thieving", "Thieving must open through the real skill button")
	if game.current_screen != "skill" or game.selected_skill_id != "thieving":
		return
	var detail = game._skill_detail_surface()
	await _show_tier_eight()
	await capture("thieving-tier-8-no-event")
	var banner_host: Control = detail._detail_lazy_entry_for_track_id("tier:thieving:8").get("stack_host")
	check(is_instance_valid(banner_host), "Final tier must be mounted")
	if not is_instance_valid(banner_host):
		return
	var banner_id := banner_host.get_instance_id()
	var events = game._temporary_event_runtime()
	var event_def := {}
	for candidate in events.event_module_defs:
		if str(candidate.get("page", "")) == "thieving":
			event_def = candidate
			break
	check(not event_def.is_empty(), "Real Thieving XP event definition must exist")
	if event_def.is_empty():
		return
	var event_id := str(event_def.id)
	var event_state := {"spawn_level": 98, "expires_unix": game._unix_now() + 600, "completed": false}
	events.temporary_event_active[event_id] = event_state
	check(game._temporary_event_surface()._animate_temporary_event_entry_if_visible(event_def, event_id), "Real XP event must insert into the current list")
	await settle(1.2)
	check(detail._detail_lazy_entry_for_track_id("tier:thieving:8").get("stack_host") == banner_host, "Event insertion must retain the existing Tier 8 control")
	check(banner_host.get_instance_id() == banner_id, "Tier 8 must not be recreated by the event")
	check(not detail.detail_rendered_action_ids.has("tier:thieving:9"), "No Tier 9 may be mounted")
	await _show_tier_eight(700.0)
	await capture("thieving-tier-8-with-event")
	var hit := _tier_eight_hit()
	check(hit != null, "Tier 8 must remain tappable")
	if hit != null:
		await click(hit.get_global_rect().get_center(), true)
		await settle(1.0)
		await _show_tier_eight(420.0)
		check(detail.expanded_tier_banner_key == "tier:thieving:8", "Tier 8 rewards must expand through a real tap")
		await capture("thieving-tier-8-rewards")
	events.temporary_event_active.clear()
	await game._temporary_event_surface()._refresh_skill_detail_after_temporary_event_despawn("thieving")
	await settle(1.0)
	check(_banner_tiers(detail._visible_detail_entries_for_skill("thieving")).has(8), "Tier 8 must survive XP event removal")


func _tier_eight_hit() -> Control:
	var entry: Dictionary = game._skill_detail_surface()._detail_lazy_entry_for_track_id("tier:thieving:8")
	var entry_host: Control = entry.get("stack_host")
	if not is_instance_valid(entry_host):
		return null
	for button in entry_host.find_children("*", "Button", true, false):
		if button.has_meta("tier_banner_plaque_hit") and button.is_visible_in_tree():
			if int(button.get_parent().get_child(0).get("tier")) == 8:
				return button
	return null


func _show_tier_eight(target_y := 850.0) -> void:
	var detail = game._skill_detail_surface()
	var entry: Dictionary = detail._detail_lazy_entry_for_track_id("tier:thieving:8")
	check(not entry.is_empty(), "Tier 8 must be present in the production list")
	if entry.is_empty():
		return
	detail._ensure_detail_lazy_entry_mounted("tier:thieving:8")
	await settle(0.4)
	var entry_host: Control = entry.get("stack_host")
	check(is_instance_valid(entry_host), "Tier 8 must have a production layout slot")
	if is_instance_valid(entry_host):
		detail.detail_actions_scroll.scroll_vertical += roundi(entry_host.get_global_rect().position.y - target_y)
		detail.detail_actions_scroll.drag_scroll_position = float(detail.detail_actions_scroll.scroll_vertical)
		await settle(0.7)
		check(entry_host.get_global_rect().position.y >= 300 and entry_host.get_global_rect().position.y <= 1100, "Tier 8 must be visible in the raw viewport")
