extends "res://scripts/tests/wisdom_feedback.gd"

func _run() -> void:
	create_timer(170).timeout.connect(func(): quit(1))
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "120")
	capture_dir = "res://.codex-tmp/detail-refresh-stability"
	DirAccess.make_dir_recursive_absolute(capture_dir)
	root.size = Vector2i(1080, 1920)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	for i in range(1600):
		await settle(0.02)
		if game.startup_initialized and not game._boot_warmup_runtime().active:
			break
	check(game.startup_initialized, "Main scene boots")
	game._audio_director().music_muted = true
	game._audio_director().sfx_muted = true
	game._audio_director()._apply_audio_bus_volumes()
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	game.auto_unlock_lockpads_enabled = false
	game.skills.thieving.level = 25
	game.skills.thieving.xp = SkillState.xp_for_level(25)
	game.thieving_state.trophies["complimentary_spoon"] = {"stolen": true, "cooldown_until_unix": 0}
	game._action_runtime().activity_start_count = 10
	game._test_state_runtime()._clear_activity_unlock_ceremony_test_state()
	game.current_screen = "menu"
	game._navigation_shell()._render_screen()
	await settle(1.0)
	var button: Control = game.skill_cards.thieving.button
	game.content_scroll.scroll_vertical += int(button.get_global_rect().get_center().y - 850)
	await settle(0.4)
	await click(button.get_global_rect().get_center(), true)
	await settle(3.0)
	check(game.current_screen == "skill" and game.selected_skill_id == "thieving", "Thieving reached through menu")
	var detail = game._skill_detail_surface()
	print("refresh-fixture ids=", detail.detail_rendered_action_ids, " all_mounted=", detail._detail_lazy_all_mounted())
	check(detail.detail_rendered_action_ids.has("tier:thieving:1"), "Fixture includes the tier-one banner")
	check(detail._detail_lazy_all_mounted(), "Fixture exercises the refresh check after all entries mount")
	check(not game._activity_unlock_runtime()._is_action_unlocked("thieving", game._action_data("thieving", "sneak-past-tip-jar")), "Level-two activity remains locked")
	await detail._scroll_to_activity_card("sneak-past-tip-jar", false, true)
	await settle(0.8)
	var initial_stack_id: int = detail._detail_actions_stack().get_instance_id()
	var initial_card_id: int = detail.detail_action_card_nodes["sneak-past-tip-jar"].get_instance_id()
	var banner: Control = _tier_banner(detail)
	check(banner != null, "Tier banner is mounted")
	var initial_banner_id: int = banner.get_instance_id()
	await capture("thieving-before")
	for i in range(12):
		await settle(0.25)
		check(detail._detail_actions_stack().get_instance_id() == initial_stack_id, "Idle Thieving keeps its page instance at sample %s" % i)
		check(not detail._skill_detail_needs_action_list_refresh(), "Unchanged Thieving needs no refresh at sample %s" % i)
		check(detail.detail_action_card_nodes["sneak-past-tip-jar"].get_instance_id() == initial_card_id, "Lock card is not recreated at sample %s" % i)
		check(_tier_banner(detail).get_instance_id() == initial_banner_id, "Tier banner is not recreated at sample %s" % i)
		if i == 1:
			await capture("thieving-during")
	await capture("thieving-settled")
	# A genuine progression change must still invalidate the list.
	game._activity_unlock_runtime()._mark_action_manually_unlocked("thieving", "sneak-past-tip-jar")
	check(detail._skill_detail_needs_action_list_refresh(), "Unlocking an activity still requests the next preview")
	await settle(2.0)
	check(detail.detail_rendered_action_ids.has("pocket-couch-coins"), "Next activity appears after unlocking")
	check(not detail._skill_detail_needs_action_list_refresh(), "List settles after a genuine unlock")
	# Exercise the incremental preview path used by lock ceremonies, including tier boundaries.
	for i in range(12):
		var unlocks = game._activity_unlock_runtime()
		var locked_id: String = unlocks._first_locked_action_id("thieving")
		if locked_id.is_empty():
			break
		unlocks._mark_action_manually_unlocked("thieving", locked_id)
		var next_id: String = unlocks._first_locked_action_id("thieving")
		check(detail._ensure_activity_unlock_preview_lazy_entry(next_id), "Insert next preview after " + locked_id)
		_check_list_order(detail, "insert " + next_id)
		await settle(0.15)
		await detail._detail_lazy_refresh_after_page_ready()
		_check_list_order(detail, "rebind " + next_id)
		if not failures.is_empty():
			break
	await settle(1.0)
	var footer := _navigation_footer(detail)
	check(footer != null, "Navigation remains after the complete unlock sequence")
	if footer != null:
		detail.detail_actions_scroll.scroll_vertical += int(footer.get_global_rect().get_center().y - 1200.0)
		detail.detail_actions_scroll.drag_scroll_position = float(detail.detail_actions_scroll.scroll_vertical)
		await settle(1.0)
		_check_list_order(detail, "scrolled to navigation")
		await capture("thieving-navigation-after-unlocks")
	print("detail-refresh-stability failures=", failures)
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func _tier_banner(detail) -> Control:
	for entry in detail.detail_lazy_plan:
		if entry.get("track_id", "") != "tier:thieving:1":
			continue
		var slot: Control = entry.get("stack_host")
		for child in slot.get_children():
			if child is Control and child.has_meta("detail_lazy_tier_banner"):
				return child
	return null

func _check_list_order(detail, context: String) -> void:
	var stack: VBoxContainer = detail._detail_actions_stack()
	var footer := _navigation_footer(detail)
	check(footer != null, context + ": navigation footer exists")
	var previous_index := -1
	for entry in detail.detail_lazy_plan:
		var slot: Control = entry.get("stack_host")
		check(is_instance_valid(slot) and slot.get_parent() == stack, context + ": every planned entry has its own slot: " + str(entry.track_id))
		if not is_instance_valid(slot):
			continue
		check(slot != footer, context + ": navigation is not an activity slot")
		check(slot.get_index() > previous_index, context + ": rendered order matches plan: " + str(entry.track_id))
		if footer != null:
			check(slot.get_index() < footer.get_index(), context + ": all entries precede navigation: " + str(entry.track_id))
		previous_index = slot.get_index()
	if footer != null:
		for child in stack.get_children():
			if child is Control and child.get_index() > footer.get_index():
				check(child.name == "DetailActionsBottomSpacer", context + ": no activities, banners or empty slots follow navigation")

func _navigation_footer(detail) -> Control:
	for child in detail._detail_actions_stack().get_children():
		if child.name == "PageSwitchModule" or child.get_meta("page_switch_module_entry", false):
			return child
	return null
