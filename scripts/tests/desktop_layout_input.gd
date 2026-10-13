extends "res://scripts/tests/first_session_input.gd"

# Data-only fixture: all rows still use the production leaderboard renderer.
class LayoutLeaderboardState extends "res://scripts/leaderboard/state.gd":
	func rows_for_category(selected_category: String) -> Array:
		return rows_by_category.get(valid_category_id(selected_category), [])

# This suite judges UI/input, not OS lifecycle. A user switching windows must not
# suspend its deterministic fixture mid-gesture. Lifecycle has its own suite.
func _process(_delta: float) -> bool:
	if is_instance_valid(game) and game.startup_initialized:
		game._app_lifecycle_runtime().suspended_at_unix = -1
	return false

func capture_desktop(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	game._tutorial_overlay_surface()._dismiss_blocking_tip()
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(image.get_size() == root.size, "Capture must equal the actual window dimensions")
	image.save_png("res://.codex-tmp/desktop-motion/" + label + ".png")

func capture_motion(label: String, opening: bool) -> void:
	var times := [0.025, 0.12, 0.34] if opening else [0.025, 0.11, 0.28]
	var previous := 0.0
	for i in range(times.size()):
		await settle(times[i] - previous)
		await capture_desktop(label + "-" + str(i))
		previous = times[i]

func _run() -> void:
	create_timer(150).timeout.connect(func(): quit(1))
	OS.set_environment("IDLE_ELITE_DESKTOP", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "100")
	AudioServer.set_bus_mute(0, true)
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	for i in range(1600):
		await settle(0.02)
		if game.startup_initialized and not game._boot_warmup_runtime().active: break
	check(game.startup_initialized, "Production scene boots")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	game.offline_progress_enabled = false
	game.activity_crit_seen = true
	game.activity_mega_crit_seen = true
	game._save_runtime().fishing_help_seen = true
	game._onboarding_runtime().activity_start_tip_seen = true
	game._tutorial_overlay_surface()._fade_tip_group("activity_start_tip_notes")
	game._tutorial_overlay_surface()._dismiss_blocking_tip()
	for skill_id in game.skills:
		game.skills[skill_id].xp = 1500
		preload("res://scripts/progression/skill_state.gd").recalculate_level(game, skill_id)
	game.leaderboard_state = LayoutLeaderboardState.new(game)
	var example_rows: Array = []
	for i in range(8):
		example_rows.append({"player_id": "layout-test-" + str(i), "name": "Test player " + str(i + 1), "avatar_index": i + 1, "score": 240 - i * 10, "total_xp": 800000 - i * 25000, "score_text": "Lv %s  |  %sK XP" % [240 - i * 10, 800 - i * 25]})
	game.leaderboard_state.rows_by_category[game.leaderboard_state.category_id] = example_rows
	game.leaderboard_state.fetch_unix_by_category[game.leaderboard_state.category_id] = int(Time.get_unix_time_from_system())
	game._online_runtime().chat_rows = [
		{"message_id": "layout-test-1", "sender_id": "layout-test-1", "name": "Test player 1", "avatar_index": 1, "text": "Testing the chat panel at desktop width.", "created_at": int(Time.get_unix_time_from_system())},
		{"message_id": "layout-test-2", "sender_id": "layout-test-2", "name": "Test player 2", "avatar_index": 2, "text": "This longer test message checks wrapping and spacing while the mission panel is open beside the hub.", "created_at": int(Time.get_unix_time_from_system())}
	]
	game.desktop_layout.skill_slots.assign(["woodcutting", "fishing", "fight"])
	game.selected_skill_id = "woodcutting"
	game.current_screen = "skill"
	await game._navigation_shell()._render_screen()
	await settle(8)
	var desktop = game.desktop_layout
	print("DESKTOP_STATE canvas=", game.size, " window=", root.size, " columns=", desktop.columns.size())
	check(desktop.enabled(), "Desktop layout enabled")
	check(desktop.columns.size() == 3, "Three production skill pages")
	for column in desktop.columns:
		print("COLUMN ", column.skill_id, " rect=", column.page.get_global_rect(), " scroll=", column.context.detail_actions_scroll.get_global_rect())
	await capture_desktop("skills-1280x720")
	if OS.get_environment("IDLE_ELITE_CAROUSEL_ONLY") == "1":
		await drag_carousel(-1, "debug-carousel")
		check(desktop.skill_slots == ["fishing", "fight", "thieving"], "Short carousel test advances one skill")
		print("CAROUSEL_SHORT failures=", JSON.stringify(failures))
		game._app_lifecycle_runtime()._prepare_for_shutdown()
		game.queue_free()
		await process_frame
		quit(0 if failures.is_empty() else 1)
		return
	for target in [["woodcutting", "gather-fallen-branches"], ["fight", "push-ups"], ["fishing", "practice-pool"]]:
		var key := str(target[0]) + ":" + str(target[1])
		var card: Dictionary = game.action_cards.get(key, {})
		check(not card.is_empty(), "Action mounted: " + key)
		if not card.is_empty():
			await click(card.button.get_global_rect().get_center())
			check(game.running_skill_id == target[0] and game.running_action_id == target[1], "Click starts the correct activity in " + str(target[0]))
			await hold_to_stop(card.button.get_global_rect().get_center(), target[0] == "fishing")
			check(game.running_action_id.is_empty(), "Existing stop gesture works in " + str(target[0]))
	game._action_runtime()._start_action("woodcutting", "gather-fallen-branches", false, false)
	var first_scroll = desktop.columns[0].context.detail_actions_scroll
	var second_scroll = desktop.columns[1].context.detail_actions_scroll
	first_scroll.scroll_vertical = 160
	first_scroll.drag_scroll_position = 160
	await settle(0.3)
	check(second_scroll.scroll_vertical == 0, "Independent column scrolling")
	var header_position: Vector2 = desktop.columns[0].picker.global_position
	var wheel := InputEventMouseButton.new()
	wheel.position = first_scroll.get_global_rect().get_center()
	wheel.global_position = wheel.position
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	root.push_input(wheel, true)
	await settle(0.5)
	check(first_scroll.scroll_vertical > 160 and second_scroll.scroll_vertical == 0, "Wheel scroll affects only the hovered column")
	check(desktop.columns[0].picker.global_position == header_position, "Skill header remains fixed while scrolling")
	first_scroll.velocity = 0.0
	first_scroll.scroll_vertical = 160
	first_scroll.drag_scroll_position = 160
	capture_motion("chat-open", true)
	await click(desktop.ribbon_buttons.chat.get_global_rect().get_center())
	await settle(2)
	check(desktop.columns.size() == 2 and desktop.social_tab == "chat", "Chat opens alongside two pages")
	await capture_desktop("chat-1280x720")
	var fishing_card: Dictionary = game.action_cards["fishing:practice-pool"]
	await click(fishing_card.button.get_global_rect().get_center())
	check(game.running_skill_id == "fishing", "Activity input remains live beside docked chat")
	await click(fishing_card.button.get_global_rect().get_center())
	await click(desktop.social_panel.get_node("SocialTabs").get_child(1).get_global_rect().get_center())
	await settle(1)
	await capture_desktop("scores-1280x720")
	capture_motion("social-close", false)
	await click(desktop.social_panel.get_node("SocialTabs").get_child(2).get_global_rect().get_center())
	await settle(1)
	check(desktop.columns.size() == 3, "Closing social restores third page")
	check(abs(desktop.columns[0].context.detail_actions_scroll.scroll_vertical - 160) < 3, "Social toggle retains page scroll")
	root.size = Vector2i(1000, 600)
	await settle(3)
	check(desktop.columns.size() == 2, "Smaller desktop reduces page count")
	root.size = Vector2i(1920, 1080)
	await settle(2)
	await capture_desktop("skills-1920x1080")
	for module_id in game._hub_runtime().HUB_MODULE_ORDER:
		game._hub_runtime().ensure_module_state(module_id)["level"] = 2
	await click(desktop.ribbon_buttons.hub.get_global_rect().get_center())
	await settle(2)
	check(game.current_screen == "hub", "Hub reached through production navigation")
	await click(Vector2(100, 500))
	await settle(1)
	await capture_desktop("hub-1920x1080")
	var hub = game._hub_surface()
	await physical_press(hub.hub_module_buttons.pond.get_global_rect().get_center(), 0.08)
	await settle(1)
	check(hub.hub_detail_open, "Building click opens the left inspector")
	await click(desktop.ribbon_buttons.chat.get_global_rect().get_center())
	await settle(2)
	check(hub.hub_detail_panel.get_global_rect().end.x < game.size.x * 0.34, "Inspector stays in the left third")
	await capture_desktop("hub-inspector-chat-1920x1080")
	capture_motion("mission-switch", true)
	await physical_press(hub.hub_module_buttons.mission.get_global_rect().get_center(), 0.08)
	await settle(1)
	check(game._hub_runtime().hub_selected_module_id == "mission", "Switch the inspected building without closing chat")
	check(hub.hub_detail_panel.get_global_rect().end.x < game.size.x * 0.34, "Mission board fits the left inspector")
	await capture_desktop("mission-inspector-chat-1920x1080")
	await click(hub.hub_mission_view_buttons[1].get_global_rect().get_center())
	await settle(0.5)
	check(hub.hub_mission_upgrade_view, "Mission upgrade tab works")
	await capture_desktop("mission-upgrade-1920x1080")
	await click(hub.hub_mission_view_buttons[0].get_global_rect().get_center())
	await settle(0.5)
	check(not hub.hub_mission_upgrade_view, "Mission list tab works")
	capture_motion("inspector-close", false)
	await click(desktop.hub_inspector.get_node("CloseInspector").get_global_rect().get_center())
	await settle(1)
	check(not hub.hub_detail_open, "Inspector close restores hub space")
	await click(desktop.ribbon_buttons.skill.get_global_rect().get_center())
	await settle(1)
	check(game.current_screen == "skill" and desktop.columns.size() == 2, "Ribbon navigation remains live beside docked chat")
	await click(desktop.ribbon_buttons.chat.get_global_rect().get_center())
	await settle(1)
	var canonical: Vector2 = hub._hub_default_module_center("pond")
	check(hub._hub_from_display(hub._hub_to_display(canonical)).distance_to(canonical) < 0.01, "Wide hub coordinates round-trip without changing mobile saves")
	for screen in ["skill", "settings", "shop", "skill"]:
		desktop.navigate(screen)
		await settle(0.5)
	check(desktop.columns.size() == 3, "Returning from other pages restores columns")
	game._skill_swipe_activity_surface()._cancel_skill_swipe_feedback(false)
	check(desktop.carousel_frame.position.x == 0, "Mobile swipe cleanup cannot recenter the desktop strip")
	await drag_carousel(-1, "carousel-left")
	check(desktop.skill_slots == ["fishing", "fight", "thieving"], "Left drag advances the whole strip")
	await drag_carousel(1, "carousel-right")
	check(desktop.skill_slots == ["woodcutting", "fishing", "fight"], "Right drag wraps back")
	check(abs(desktop.columns[0].context.detail_actions_scroll.scroll_vertical - 160) < 3, "Rotating away and back keeps vertical position")
	var pages: Array = desktop.all_columns.map(func(column): return column.page.get_instance_id())
	for i in range(5): await drag_carousel(-1)
	check(desktop.skill_slots == ["woodcutting", "fishing", "fight"], "Five drags complete one cycle")
	check(pages == desktop.all_columns.map(func(column): return column.page.get_instance_id()), "Repeated rotation reuses the same five pages")
	await drag_carousel(-1, "", 0.1)
	check(desktop.skill_slots[0] == "woodcutting", "Short drag settles back without rotating")
	await drag_carousel(-1)
	await drag_carousel(-1)
	check(desktop.skill_slots == ["fight", "thieving", "build"], "Dragging reaches all five skills")
	var running_before: String = game.running_skill_id + ":" + game.running_action_id
	var card_start: Vector2 = game.action_cards["thieving:borrow-cookie-permanently"].button.get_global_rect().get_center()
	await drag_carousel(-1, "", 0.7, card_start)
	check(game.running_skill_id + ":" + game.running_action_id == running_before, "Dragging an activity card does not change the running action")
	await drag_carousel(1)
	await drag_carousel(-1, "", 0.7, Vector2(80, 120))
	check(desktop.skill_slots[0] == "thieving", "Release outside the viewport commits and settles")
	await drag_carousel(1)
	# Losing focus midway through a drag must restore a complete three-column view.
	desktop.carousel_tracking = true
	desktop.carousel_dragging = true
	desktop.carousel_frame.position.x = -200
	game._app_lifecycle_runtime()._cancel_interrupted_pointer()
	check(not desktop.carousel_dragging and desktop.carousel_frame.position.x == 0, "Focus loss cancels an interrupted drag")
	await capture_desktop("fight-thieving-1920x1080")
	game._settings_surface().toggle_dark_mode_enabled()
	await settle(1)
	await capture_desktop("skills-dark-1920x1080")
	await click(desktop.ribbon_buttons.scores.get_global_rect().get_center())
	await settle(1)
	await capture_desktop("scores-dark-1920x1080")
	await click(desktop.ribbon_buttons.chat.get_global_rect().get_center())
	await settle(1)
	await capture_desktop("chat-dark-1920x1080")
	await click(desktop.ribbon_buttons.chat.get_global_rect().get_center())
	game._settings_surface().toggle_dark_mode_enabled()
	await settle(1)
	await click(desktop.ribbon_buttons.scores.get_global_rect().get_center())
	await settle(1)
	await capture_desktop("scores-1920x1080")
	game._settings_surface().toggle_dark_mode_enabled()
	await settle(1)
	check(desktop.social_dark_mode, "Open panel follows dark-mode changes")
	await capture_desktop("scores-dark-1920x1080")
	# Rapid social requests resolve to the final choice.
	desktop.set_social("chat")
	await settle(0.03)
	desktop.set_social("scores")
	await settle(0.03)
	desktop.set_social("")
	await settle(1.2)
	check(desktop.social_tab.is_empty() and not desktop.social_transition, "Rapid toggles settle on the final request")
	var preferences: Dictionary = game._save_runtime()._save_payload(int(Time.get_unix_time_from_system())).desktop_layout
	var restored = preload("res://scripts/ui/desktop_layout.gd").new(game)
	restored.restore_preferences(JSON.parse_string(JSON.stringify(preferences)))
	check(restored.skill_slots == desktop.skill_slots, "Save round trip restores column order")
	check(restored.scroll_positions == desktop.scroll_positions, "Save round trip restores per-skill scroll positions")
	restored.restore_preferences({"skills": ["invalid", "fight", "fight", 9], "scroll": {"fight": "invalid"}, "focused": "invalid"})
	check(restored.skill_slots.size() == 3 and restored.skill_slots[0] == "fight", "Invalid layout values recover safely")
	restored.restore_preferences(null)
	check(restored.skill_slots.is_empty(), "Older saves without desktop preferences use defaults")
	print("DESKTOP_LAYOUT failures=", JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func hold_to_stop(point: Vector2, fishing: bool) -> void:
	if fishing:
		await click(point)
		return
	await physical_press(point, 1.0)

func physical_press(point: Vector2, seconds: float) -> void:
	for down in [true, false]:
		# Viewport.push_input drives the production UI but does not update Input's
		# physical button state. Set that state outside all controls before routing.
		var state_event := InputEventMouseButton.new()
		state_event.position = Vector2(-100, -100)
		state_event.global_position = state_event.position
		state_event.button_index = MOUSE_BUTTON_LEFT
		state_event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		state_event.pressed = down
		Input.parse_input_event(state_event)
		var event := state_event.duplicate() as InputEventMouseButton
		event.position = point
		event.global_position = point
		root.push_input(event, true)
		await settle(seconds if down else 0.2)

func drag_carousel(direction: int, capture_label := "", fraction := 0.7, origin := Vector2.INF) -> void:
	var desktop = game.desktop_layout
	var start: Vector2 = desktop.columns[1].picker.get_global_rect().get_center() if origin == Vector2.INF else origin
	if not capture_label.is_empty(): await capture_desktop(capture_label + "-before")
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.pressed = true
	press.position = start
	press.global_position = start
	var physical := press.duplicate() as InputEventMouseButton
	physical.position = Vector2(-100, -100)
	physical.global_position = physical.position
	Input.parse_input_event(physical)
	Input.flush_buffered_events()
	root.push_input(press, true)
	await process_frame
	var distance: float = direction * (desktop.column_width + desktop.GAP) * fraction
	var previous := start
	for i in range(1, 9):
		var motion := InputEventMouseMotion.new()
		motion.position = start + Vector2(distance * i / 8.0, 0)
		motion.global_position = motion.position
		motion.relative = motion.position - previous
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		root.push_input(motion, true)
		previous = motion.position
		await settle(0.02)
		if i == 4 and not capture_label.is_empty(): await capture_desktop(capture_label + "-transition")
	print("CAROUSEL_RELEASE slots=", desktop.skill_slots, " drag=", desktop.carousel_dragging, " offset=", desktop.carousel_frame.position.x)
	var release := press.duplicate() as InputEventMouseButton
	release.pressed = false
	release.button_mask = 0
	release.position = previous
	release.global_position = previous
	root.push_input(release, true)
	physical.pressed = false
	physical.button_mask = 0
	Input.parse_input_event(physical)
	Input.flush_buffered_events()
	await settle(0.4)
	check(not desktop.carousel_dragging and not desktop.carousel_settling, "Carousel settles after release")
	if not capture_label.is_empty(): await capture_desktop(capture_label + "-settled")

