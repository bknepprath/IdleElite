extends "res://scripts/tests/ham_feedback_capture.gd"

func _run() -> void:
	create_timer(160).timeout.connect(func(): quit(1))
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "120")
	capture_dir = "res://.codex-tmp/brian-notes-oct22"
	DirAccess.make_dir_recursive_absolute(capture_dir)
	root.size = Vector2i(1080, 1920)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	for i in range(1600):
		await settle(0.02)
		if game.startup_initialized and not game._boot_warmup_runtime().active: break
	check(game.startup_initialized, "Real main scene boots")
	game._audio_director().music_muted = true
	game._audio_director().sfx_muted = true
	game._audio_director()._apply_audio_bus_volumes()
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	game.auto_unlock_lockpads_enabled = false
	game._action_runtime().activity_start_count = 10
	game._save_runtime().fishing_help_seen = true
	for id in game.skills:
		game.skills[id].xp = SkillState.xp_for_level(40)
		game.skills[id].level = 40
		for action in game.actions_by_skill[id]:
			game._activity_unlock_runtime()._mark_action_manually_unlocked(id, str(action.id))
	for definition in game._project_runtime().definitions.values():
		var work := {}
		for step in definition.project.steps: work[str(step.id)] = int(step.target)
		if definition.project.has("cost"): work.materials = 1
		game._project_runtime().work[str(definition.project.id)] = work
	game._test_state_runtime()._clear_activity_unlock_ceremony_test_state()
	game.material_runtime.set_amount("scrapwood", 100)
	game.material_runtime.set_amount("berries", 100)
	game.material_runtime.set_amount("softwood", 100)
	for action in game.actions_by_skill.woodcutting:
		game.mastery[game._action_key("woodcutting", action.id)] = {"xp":MasteryState.xp_for_level(3), "level":3}
	AchievementState.mark_completed_seen_ids(AchievementState.milestones(game, false), game._save_runtime().achievement_toast_seen_ids, [])
	game._achievement_toast_surface().achievement_toast_queue.clear()
	game._achievement_toast_surface().achievement_toast_queue_ids.clear()
	game.current_screen = "menu"
	game._navigation_shell()._render_screen()
	await settle(1.0)
	await capture("menu")
	if OS.get_environment("IDLE_ELITE_NOTES_TIER_ONLY") == "1":
		await open_notes_skill("woodcutting")
		await inspect_notes_tier(3, "tier-target-4")
		await inspect_notes_tier(2, "tier-target-3")
		print("brian-notes-oct22 failures=", failures)
		game.queue_free()
		await process_frame
		quit(0 if failures.is_empty() else 1)
		return
	if OS.get_environment("IDLE_ELITE_NOTES_WISDOM_ONLY") == "1":
		game._activity_unlock_runtime().manual_activity_unlocks.erase("build:frame-a-treehouse-platform")
		game.material_runtime.wisdom_by_skill["build"] = 12
		await open_notes_skill("build")
		var wisdom_card := await notes_card("frame-a-treehouse-platform")
		if not wisdom_card.is_empty():
			await align_notes_card(wisdom_card)
			await capture("wisdom-current")
			await click((wisdom_card.wisdom_panel.get_child(0) as Control).get_global_rect().get_center(), true)
			await settle(0.7)
			await align_notes_card(wisdom_card)
			await capture("wisdom-current-help")
		print("brian-notes-wisdom failures=",failures)
		game.queue_free()
		await process_frame
		quit(0 if failures.is_empty() else 1)
		return
	await open_notes_skill("fishing")
	var rat: Dictionary = game._action_data("fishing", "fight-rat-king")
	var runtime = game._action_runtime()
	var stats := []
	for tool in ["hands", "net", "line", "boat", "star_rod"]:
		game.fishing_runtime.equipped_tool_id = tool
		runtime.invalidate_stat_cache()
		stats.append([runtime._success_chance("fishing",rat),runtime._action_cycle_seconds("fishing",rat)])
		check(not runtime._fishing_batch_soak_active("fishing",rat), "Rat King is not a fishing haul: " + tool)
	for stat in stats: check(stat == stats[0], "Rat King stats independent of tool: " + str(stats))
	var combo_xp := []
	var combo_fish := []
	for tool in ["hands", "net", "line", "boat", "star_rod", "mirror"]:
		game.fishing_runtime.equipped_tool_id = tool
		combo_xp.append(game.fishing_runtime.flat_xp_reward(game, rat, "fishing"))
		seed(2210)
		combo_fish.append(game.fishing_runtime.roll_fish_count(game, rat))
	for value in combo_xp: check(value == combo_xp[0], "Rat King XP independent of tool")
	for value in combo_fish: check(value > 0 and value == combo_fish[0], "Rat King retains tool-independent catch reward")
	game.fishing_runtime.equipped_tool_id = "net"
	runtime.invalidate_stat_cache()
	var card := await notes_card("fight-rat-king")
	if not card.is_empty():
		await click((card.stat_boxes.success as Control).get_global_rect().get_center(), true)
		await settle(0.7)
		await align_notes_card(card)
		await capture("rat-king-success")
		check(not str(card.bonus_panel.bonuses.text).contains("Drag net"), "Rat King excludes drag-net help")
		await inspect_notes_collapse("fight-rat-king")
	await open_notes_skill("woodcutting")
	card = await notes_card("firepit")
	if not card.is_empty():
		await align_notes_card(card)
		await capture("firepit-off")
		await click((card.toggle as Control).get_global_rect().get_center(), true)
		await settle(0.12)
		await capture("firepit-transition")
		await settle(1.5)
		await align_notes_card(card)
		await capture("firepit-on")
		var outer: Control = card.firepit_entry_root
		var entry: Control = card.entry
		check(entry.custom_minimum_size.y + 0.5 >= outer.custom_minimum_size.y, "Firepit slot includes fuel holder")
		var lazy: Dictionary = game._skill_detail_surface()._detail_lazy_entry_for_track_id("firepit")
		check(float(lazy.height) + 0.5 >= outer.custom_minimum_size.y, "Firepit lazy plan includes fuel holder")
		print("NOTES_FIREPIT entry=",entry.custom_minimum_size.y," outer=",outer.custom_minimum_size.y," plan=",lazy.height)
		await inspect_notes_collapse("firepit")
	card = await notes_card("snap-a-twig-with-purpose")
	if not card.is_empty():
		await click((card.medal as Control).get_global_rect().get_center(), true)
		await settle(0.8)
		await align_notes_card(card)
		await capture("neighboring-activities")
		print("NOTES_MEDAL ",card.bonus_panel.medal_rows.get_children().size())
	await inspect_notes_tier()
	await inspect_notes_berry()
	await open_notes_skill("fight")
	card = await notes_card("fight-guys")
	if not card.is_empty():
		await align_notes_card(card)
		await capture("guys-cover")
	await inspect_notes_profile()
	print("brian-notes-oct22 failures=", failures)
	var result := FileAccess.open(capture_dir + "/result.json",FileAccess.WRITE)
	result.store_string(JSON.stringify({"failures":failures,"rat_stats":stats}))
	result.close()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func open_notes_skill(id: String) -> void:
	game.running_skill_id = ""
	game.running_action_id = ""
	if game.current_screen not in ["skill", "menu"]:
		await click(game.skills_tab.get_global_rect().get_center(), true)
		await settle(0.7)
	if game.current_screen != "menu":
		await click(game._navigation_shell().skills_utility_tab.get_global_rect().get_center(), true)
		await settle(0.7)
	check(game.current_screen == "menu", "Menu reached through actual navigation")
	if game.current_screen != "menu": return
	var button: Control = game.skill_cards[id].button
	game.content_scroll.scroll_vertical += int(button.get_global_rect().get_center().y - 950)
	await settle(0.5)
	print("NOTES_MENU target=",id," rect=",button.get_global_rect()," viewport=",root.get_visible_rect())
	await click(button.get_global_rect().get_center(), true)
	await settle(1.0)
	check(game.current_screen == "skill" and game.selected_skill_id == id, "Menu opens " + id)

func notes_card(id: String) -> Dictionary:
	await game._skill_detail_surface()._scroll_to_activity_card(id, false, true)
	await settle(0.8)
	var card: Dictionary = game.action_cards.get(game._action_key(game.selected_skill_id,id),{})
	check(not card.is_empty(), "Production card mounted: " + id)
	return card

func align_notes_card(card: Dictionary) -> void:
	var control: Control = card.get("firepit_entry_root", card.root)
	var scroll: ScrollContainer = game.detail_actions_scroll
	scroll.scroll_vertical += int(control.get_global_rect().position.y - 455)
	scroll.set("drag_scroll_position", float(scroll.scroll_vertical))
	await settle(0.4)

func inspect_notes_tier(tier := 3, capture_name := "tier-rewards") -> void:
	var detail = game._skill_detail_surface()
	var key: String = detail._tier_banner_key("woodcutting", tier)
	await detail._scroll_to_activity_card(key, false, true)
	await settle(0.6)
	var lazy: Dictionary = detail._detail_lazy_entry_for_track_id(key)
	if lazy.is_empty():
		check(false, "Tier banner mounted")
		return
	var slot: Control = lazy.stack_host
	game.detail_actions_scroll.scroll_vertical += int(slot.get_global_rect().position.y - 455)
	await settle(0.6)
	var button: Button = null
	for candidate in slot.find_children("*", "Button", true, false):
		if candidate.has_meta("tier_banner_plaque_hit"): button = candidate
	check(button != null, "Tier banner has real click target")
	if button == null: return
	await click(button.get_global_rect().get_center(), true)
	await settle(0.8)
	check(detail.expanded_tier_banner_key == key, "Tier menu opened by touch")
	lazy = detail._detail_lazy_entry_for_track_id(key)
	slot = lazy.stack_host
	game.detail_actions_scroll.scroll_vertical += int(slot.get_global_rect().position.y - 420)
	await settle(0.5)
	await capture(capture_name)

func inspect_notes_berry() -> void:
	var card := await notes_card("prune-orchard-row")
	if card.is_empty(): return
	game._material_collection_surface().toggle_berry_prep_for_action("woodcutting", "prune-orchard-row")
	await click((card.button as Control).get_global_rect().get_center(), true)
	await settle(0.5)
	await align_notes_card(card)
	game.action_progress = 0.0
	await capture("berry-before")
	var before: float = game.material_runtime.amount("berries")
	game._action_runtime().guaranteed_success_action_completions = 0
	game.action_progress = 1.0
	game._action_runtime()._process_action(0.0)
	var flyers := 0
	for child in game.get_children():
		if child.has_meta("mat_flyer_tween"): flyers += 1
	check(flyers == 2, "Berry completion shows two item flyers: %s" % flyers)
	check(is_equal_approx(game.material_runtime.amount("berries"), before + 1.0), "Berry spends one and awards two")
	await settle(0.48)
	await capture("berry-transition")
	await settle(0.9)
	await capture("berry-settled")
	game._action_runtime()._stop_running_action("woodcutting", "prune-orchard-row")
	await settle(0.4)

func inspect_notes_profile() -> void:
	game.leaderboard_profile.avatar_index = 0
	var surface = game._profile_chat_overlay_surface()
	await click(surface.chat_strip_control().get_global_rect().get_center(), true)
	await settle(0.6)
	check(surface.chat_profile_button != null, "Chat profile button exists")
	if surface.chat_profile_button == null: return
	await click(surface.chat_profile_button.get_global_rect().get_center(), true)
	await settle(0.6)
	check(surface.profile_overlay != null and surface.profile_overlay.visible, "Profile opened through chat")
	await capture("default-blue-bust")

func inspect_notes_collapse(id: String) -> void:
	var detail = game._skill_detail_surface()
	var key: String = game._action_key(game.selected_skill_id, id)
	var card: Dictionary = game.action_cards.get(key, {})
	check(not card.get("module_action_zones", {}).has("collapse"), "No minimize corner: " + id)
	var module_key: String = str(card.pop.get_meta("module_ui_key", ""))
	game.module_ui_runtime.collapsed[module_key] = true
	check(not detail._module_ui_is_collapsed(module_key), "Stale minimize flag cannot hide activity: " + id)
	var corner: Vector2 = (card.pop as Control).get_global_rect().position + Vector2((card.pop as Control).size.x - 40, 40)
	var hit: Dictionary = detail._module_action_circle_at_direct_position(corner)
	check(str(hit.get("kind", "")) != "collapse", "Top-right does not intercept taps: " + id)
	await click(corner, true)
	await settle(0.3)
	check(detail._module_collapse_badge(card.pop) == null, "Top-right creates no minus badge: " + id)
	await capture(id + "-no-minimize")
	game.module_ui_runtime.collapsed.clear()

