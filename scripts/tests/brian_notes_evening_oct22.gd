extends "res://scripts/tests/fishing_tool_balance.gd"

func _run() -> void:
	if OS.get_environment("IDLE_ELITE_FISHING_DEMO") != "1":
		create_timer(230).timeout.connect(func(): quit(1))
	else:
		OS.set_environment("IDLE_ELITE_DESKTOP", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0" if OS.get_environment("IDLE_ELITE_FISHING_DEMO") == "1" else "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "220")
	AudioServer.set_bus_mute(0, true)
	capture_dir = "res://outputs/verification/brian-notes-evening-oct22"
	DirAccess.make_dir_recursive_absolute(capture_dir)
	root.size = Vector2i(1080, 1920)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	for i in range(1600):
		await settle(0.02)
		if game.startup_initialized and not game._boot_warmup_runtime().active: break
	check(game.startup_initialized, "Production main scene boots")
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	game._tutorial_overlay_surface()._dismiss_blocking_tip()
	game.auto_unlock_lockpads_enabled = false
	game.activity_crit_seen = true
	game.activity_mega_crit_seen = true
	game._save_runtime().fishing_help_seen = false
	for id in game.skills:
		game.skills[id].xp = SkillState.xp_for_level(99)
		game.skills[id].level = 99
		for action in game.actions_by_skill[id]:
			game._activity_unlock_runtime()._mark_action_manually_unlocked(id, str(action.id))
			game.mastery[game._action_key(id, str(action.id))] = {"xp": MasteryState.xp_for_level(3), "level": 3}
	for definition in game._project_runtime().definitions.values():
		var work := {}
		for step in definition.project.steps: work[str(step.id)] = int(step.target)
		game._project_runtime().work[str(definition.project.id)] = work
	game._test_state_runtime()._clear_activity_unlock_ceremony_test_state()
	AchievementState.mark_completed_seen_ids(AchievementState.milestones(game, false), game._save_runtime().achievement_toast_seen_ids, [])
	game._achievement_toast_surface().achievement_toast_queue.clear()
	var fish = game.fishing_runtime
	fish.net_collected = true
	fish.rod_collected = true
	fish.reinforced_rod_collected = true
	fish.star_rod_collected = true
	fish.boat_built = true
	fish.mirror_collected = true
	game.current_screen = "menu"
	game._navigation_shell()._render_screen()
	await settle(0.8)
	await open_notes_skill("fishing")
	await settle(1)
	if OS.get_environment("IDLE_ELITE_FISHING_COMPACT_AUDIT") == "1":
		await audit_compact_interaction()
		print("FISHING_COMPACT failures=", JSON.stringify(failures))
		game._app_lifecycle_runtime()._prepare_for_shutdown()
		game.queue_free()
		await process_frame
		quit(0 if failures.is_empty() else 1)
		return
	if OS.get_environment("IDLE_ELITE_FISHING_PALETTE_AUDIT") == "1":
		await audit_palette_interactions()
		print("FISHING_PALETTE failures=", JSON.stringify(failures))
		game._app_lifecycle_runtime()._prepare_for_shutdown()
		game.queue_free()
		await process_frame
		quit(0 if failures.is_empty() else 1)
		return
	if OS.get_environment("IDLE_ELITE_FISHING_DEMO") == "1":
		await run_desktop_demo()
		return
	for button in get_nodes_in_group("skill_header_info_buttons"):
		if button.get_meta("fishing_help", false) and button.is_visible_in_tree():
			check(not button.get_meta("info_popover").visible, "Fishing information stays closed without a tap")
	check(fish.recommended_location_tool("rocks") == "hands", "Rocks defaults to hands")
	var method := await show_location("river-bend", "river-before")
	await click((method.tool_selector as Control).get_global_rect().get_center(), true)
	await settle(0.25)
	var popup: Control = game._fishing_ui_surface().fishing_tool_wallet_popup
	check(popup.find_children("*", "Label", true, false).is_empty(), "Tool pill contains no words")
	for button in popup.find_children("*", "Button", true, false):
		check(popup.get_global_rect().encloses(button.get_global_rect()), "Tool touch target stays inside pill")
		if button.get_meta("tool_selected", false): check(button.get_theme_stylebox("normal").bg_color.g > 0.7, "Selected tool is green")
	await capture("tool-pill-open")
	game._fishing_ui_surface()._clear_fishing_tool_circle_menu()
	await select_module_tool("river-bend", "star_rod")
	method = await show_location("river-bend", "river-rod-before")
	await click((method.method_image_hit_control as Control).get_global_rect().get_center(), true)
	await settle(0.1)
	await capture("rod-entry")
	await settle(0.35)
	await capture("rod-cast")
	await settle(1)
	await capture("rod-waiting")
	game._action_runtime()._stop_running_action("fishing", "river-bend")
	await select_module_tool("river-bend", "net")
	method = await show_location("river-bend", "river-net-before")
	await click((method.method_image_hit_control as Control).get_global_rect().get_center(), true)
	await settle(0.35)
	await capture("net-dip")
	await settle(0.9)
	var net_area: Dictionary = game._fishing_ui_surface()._fishing_area_card_for_action("fishing", "river-bend")
	seed_both_sides(net_area.active_tool_layer)
	fish.net_haul_visual_seconds = FishingState.FISHING_NET_HAUL_VISUAL_SECONDS
	for target in [0.15, 0.5, 0.85]:
		for frame in range(90):
			await process_frame
			if net_area.active_tool_layer.splash_visual_progress >= target and net_area.active_tool_layer.splash_age < net_area.active_tool_layer.splash_lifetime: break
		check(net_area.active_tool_layer.splash_age < net_area.active_tool_layer.splash_lifetime, "Splash remains alive for its animation frame")
		await capture("net-splash-" + str(int(target * 100)))
	await settle(2.2)
	await capture("net-settled")
	game._action_runtime()._stop_running_action("fishing", "river-bend")
	var training := await notes_card("practice-pool")
	await align_notes_card(training)
	await capture("practice-pool")
	await inspect_locked_mastery()
	await inspect_navigation_chat_edge()
	await inspect_combo("fight", "wrestle-stuck-gate-latch", "combo")
	await open_notes_skill("thieving")
	var jailed := await notes_card("borrow-cookie-permanently")
	await align_notes_card(jailed)
	game._thieving_surface()._jail_thieving_action("borrow-cookie-permanently", false, 60)
	await settle(0.5)
	await capture("jail-tap-before")
	var overlay: Control = jailed.jail_overlay
	check(overlay.get_node_or_null("JailTapHint") != null, "Jail shows a tap cue")
	await settle(0.25)
	await capture("jail-tap-transition")
	await click(overlay.get_global_rect().get_center(), true)
	await settle(0.3)
	await capture("jail-tap-after")
	check(game._thieving_surface()._thieving_action_jail_remaining("borrow-cookie-permanently") < 60, "Jail still responds to taps")
	print("EVENING_NOTES failures=", JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func inspect_combo(skill: String, id: String, label: String) -> void:
	await open_notes_skill(skill)
	var card := await notes_card(id)
	await align_notes_card(card)
	var details = game._skill_detail_surface()
	await capture(label + "-closed")
	var medal_help: Control = (card.root as Control).find_child("MedalInformationButton", true, false)
	check(medal_help != null, "Actual medal help button exists")
	if medal_help == null: return
	await click(medal_help.get_global_rect().get_center(), true)
	await settle(0.5)
	await align_notes_card(card)
	await capture(label + "-expanded")
	await click(medal_help.get_global_rect().get_center(), true)
	for stage in ["closing-start", "closing-middle", "closing-end"]:
		await settle(0.10)
		await capture(label + "-" + stage)
		check(absf((card.root as Control).size.y - (card.root as Control).custom_minimum_size.y) < 1.0, "Rendered card follows collapsing layout")
	await settle(0.5)
	await capture(label + "-settled")

func inspect_locked_mastery() -> void:
	var unlocks = game._activity_unlock_runtime()
	var key: String = game._action_key("fishing", "rapids")
	unlocks.manual_activity_unlocks.erase(key)
	game.mastery.erase(key)
	game._navigation_shell()._render_screen(false)
	await settle(0.5)
	await show_location("river-bend", "locked-outline")
	var method: Dictionary = game._fishing_ui_surface()._fishing_method_card_for_action("fishing", "rapids")
	check(not unlocks._is_action_unlocked("fishing", method.action), "Rapids is locked in the fixture")
	check((method.mastery_ring as Control).is_visible_in_tree(), "Locked location retains empty mastery outline")
	unlocks._mark_action_manually_unlocked("fishing", "rapids")

func inspect_navigation_chat_edge() -> void:
	await open_notes_skill("fight")
	var scroll = game._skill_detail_surface().detail_actions_scroll
	for index in range(10):
		scroll.scroll_vertical = scroll.get_max_scroll_vertical()
		await settle(0.1)
	var chat: Control = game._profile_chat_overlay_surface().chat_strip_control()
	for raw in get_nodes_in_group("page_switch_buttons"):
		var button := raw as Button
		if not button.is_visible_in_tree() or button.get_meta("page_switch_owner_skill_id", "") != "fight": continue
		var target := str(button.get_meta("page_switch_target_skill_id", ""))
		var shift: float = button.get_global_rect().end.y - chat.get_global_rect().position.y
		scroll.scroll_vertical += int(shift)
		await settle(0.2)
		var point := Vector2(button.get_global_rect().get_center().x, chat.get_global_rect().position.y - 2.0)
		check(button.get_global_rect().has_point(point), "Navigation button meets visible Chat edge")
		await capture("navigation-chat-edge")
		await click(point, true)
		await settle(1.2)
		check(game.selected_skill_id == target, "Navigation responds two pixels above Chat")
		return
	check(false, "Visible navigation button found")

func seed_both_sides(stage: Control) -> void:
	var probe := RandomNumberGenerator.new()
	for value in range(1, 100):
		probe.seed = value
		if probe.randi_range(1, 3) != 3: continue
		var depths := []
		for index in range(2):
			probe.randi_range(0, 1)
			probe.randf_range(-0.025, 0.025)
			depths.append(probe.randi_range(0, 1))
		if depths[0] == depths[1]: continue
		stage.splash_random.seed = value
		return

func run_desktop_demo() -> void:
	var method := await show_location("river-bend", "")
	await select_module_tool("river-bend", "net")
	method = game._fishing_ui_surface()._fishing_method_card_for_action("fishing", "river-bend")
	await click((method.method_image_hit_control as Control).get_global_rect().get_center(), true)
	await settle(0.8)
	if OS.get_environment("IDLE_ELITE_FISHING_RECORDING") == "1":
		await record_fishing_animation()
	root.size = Vector2i(1920, 1080)
	await settle(2)
	await game._skill_detail_surface()._scroll_to_activity_card("river-bend", false, true)
	await settle(0.8)
	var area: Dictionary = game._fishing_ui_surface()._fishing_area_card_for_action("fishing", "river-bend")
	seed_both_sides(area.active_tool_layer)
	await capture_demo("desktop-before")
	game.fishing_runtime.net_stored_fish = FishingState.FISHING_NET_HAUL_THRESHOLD - 1
	game.action_progress = 0.9999
	for target in [0.15, 0.5, 0.85]:
		for frame in range(180):
			await process_frame
			if area.active_tool_layer.splash_visual_progress >= target and area.active_tool_layer.splash_age < area.active_tool_layer.splash_lifetime: break
		await capture_demo("desktop-splash-" + str(int(target * 100)))
	await settle(2.2)
	await capture_demo("desktop-settled")
	print("FISHING_DEMO_READY failures=", JSON.stringify(failures))

func capture_demo(label: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	check(img.get_size() == Vector2i(1920, 1080), "Desktop capture is raw 1920x1080")
	img.save_png(capture_dir + "/" + label + ".png")

func audit_palette_interactions() -> void:
	var cases := [["drain-gate", "net", "sewer"], ["deep-trench", "boat", "deep_water"], ["storm-ripple", "boat", "storm"], ["reflection", "mirror", "space"], ["shallows", "hands", "water"], ["river-bend", "line", "water"], ["ice-hole", "net", "ice"]]
	for entry in cases:
		var action_id: String = entry[0]
		var tool: String = entry[1]
		var kind: String = entry[2]
		if tool == "line":
			game.fishing_runtime.reinforced_rod_collected = false
			game.fishing_runtime.star_rod_collected = false
			game._action_runtime().invalidate_stat_cache()
			game._navigation_shell()._render_screen(false)
			await settle(0.3)
		await show_location(action_id, "")
		await select_module_tool(action_id, tool)
		var method: Dictionary = game._fishing_ui_surface()._fishing_method_card_for_action("fishing", action_id)
		await click((method.method_image_hit_control as Control).get_global_rect().get_center(), true)
		await settle(0.35)
		game.action_progress = 0.55
		await settle(0.3)
		var area: Dictionary = game._fishing_ui_surface()._fishing_area_card_for_action("fishing", action_id)
		var stage = area.active_tool_layer
		var expected: Color = preload("res://scripts/fishing/fluid_strip.gd").palette_for(kind).fluid
		check(stage.fluid_kind == kind, "Area chooses its correct fluid: " + action_id)
		check(stage.splash_material.get_shader_parameter("water_color") == expected, "Splash matches area water: " + action_id)
		check(stage.pool_material.get_shader_parameter("water_color") == expected, "Contact pool matches area water: " + action_id)
		await capture("palette-" + kind + "-" + tool + "-before")
		seed_both_sides(stage)
		match tool:
			"net": game.fishing_runtime.net_haul_visual_seconds = FishingState.FISHING_NET_HAUL_VISUAL_SECONDS
			"boat": game.fishing_runtime.boat_haul_visual_seconds = FishingState.FISHING_BOAT_HAUL_VISUAL_SECONDS
			"line": game.fishing_runtime.rod_haul_visual_seconds = FishingState.FISHING_ROD_HAUL_VISUAL_SECONDS
			_: game.action_progress = 0.86
		await settle(0.25)
		await capture("palette-" + kind + "-" + tool + "-splash")
		await settle(1.3)
		await capture("palette-" + kind + "-" + tool + "-settled")
		game._action_runtime()._stop_running_action("fishing", action_id)
		await settle(0.15)

func record_fishing_animation() -> void:
	var frame_dir := "res://.codex-tmp/evening-fishing-recording"
	DirAccess.make_dir_recursive_absolute(frame_dir)
	var times: Array[int] = []
	var files: Array[String] = []
	for frame in range(60):
		if frame in [6, 26, 46]:
			game.fishing_runtime.net_stored_fish = FishingState.FISHING_NET_HAUL_THRESHOLD - 1
			game.action_progress = 0.9999
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		check(img.get_size() == Vector2i(1080, 1920), "Recording retains the raw portrait viewport")
		var path := ProjectSettings.globalize_path(frame_dir + "/frame-%03d.png" % frame)
		times.append(Time.get_ticks_msec())
		files.append(path)
		img.save_png(path)
		await create_timer(0.075).timeout
	var manifest := FileAccess.open(frame_dir + "/frames.txt", FileAccess.WRITE)
	for frame in range(files.size()):
		manifest.store_line("file '" + files[frame].replace("\\", "/") + "'")
		manifest.store_line("duration %.4f" % (float(times[frame + 1] - times[frame]) / 1000.0 if frame + 1 < times.size() else 0.0833))
	manifest.close()
	print("FISHING_RECORDING_READY frames=", files.size())

func audit_compact_interaction() -> void:
	var method := await show_location("river-bend", "compact-idle")
	await select_module_tool("river-bend", "net")
	method = game._fishing_ui_surface()._fishing_method_card_for_action("fishing", "river-bend")
	await click((method.method_image_hit_control as Control).get_global_rect().get_center(), true)
	game.action_progress = 0.6
	await settle(1.0)
	var area: Dictionary = game._fishing_ui_surface()._fishing_area_card_for_action("fishing", "river-bend")
	check(area.active_tool_layer.immersion_depth() > 2.0, "Net visibly dips into the center pool")
	check(is_equal_approx((area.root as Control).size.y, 312.0), "Module uses the compact 312px height")
	await capture("compact-net-contact")
	method = game._fishing_ui_surface()._fishing_method_card_for_action("fishing", "river-bend")
	await click((method.tool_selector as Control).get_global_rect().get_center(), true)
	await settle(0.3)
	method = game._fishing_ui_surface()._fishing_method_card_for_action("fishing", "river-bend")
	area = game._fishing_ui_surface()._fishing_area_card_for_action("fishing", "river-bend")
	check((method.rate_panel as Control).is_visible_in_tree(), "Center preview appears while choosing")
	check(area.active_tool_layer.modulate.a < 0.01, "Rate preview replaces the active animation")
	check((area.catch_burst as Control).modulate.a < 0.01, "Catch effects cannot obscure rate estimates")
	await capture("compact-rates-open")
	var target: Button
	for button in game._fishing_ui_surface().fishing_tool_wallet_popup.find_children("*", "Button", true, false):
		if str(button.get_meta("tool_id", "")) == "star_rod": target = button
	check(target != null, "Rod is selectable through the actual tool pill")
	if target == null: return
	var old_food := str(method.rate_food.text)
	await click(target.get_global_rect().get_center(), true)
	await settle(0.10)
	method = game._fishing_ui_surface()._fishing_method_card_for_action("fishing", "river-bend")
	check(str(method.rate_food.text) != old_food, "Center rates immediately reflect the selected rod")
	await capture("compact-rates-selected")
	for frame in range(160):
		await process_frame
		area = game._fishing_ui_surface()._fishing_area_card_for_action("fishing", "river-bend")
		if area.active_tool_layer.modulate.a > 0.02 and area.active_tool_layer.modulate.a < 0.98: break
	check(area.active_tool_layer.modulate.a > 0.02 and area.active_tool_layer.modulate.a < 0.98, "Rate-to-animation transition has a visible fade")
	await capture("compact-rates-fading")
	await settle(0.45)
	area = game._fishing_ui_surface()._fishing_area_card_for_action("fishing", "river-bend")
	method = game._fishing_ui_surface()._fishing_method_card_for_action("fishing", "river-bend")
	check(not (method.rate_panel as Control).is_visible_in_tree(), "Chosen rates fade away")
	check(area.active_tool_layer.modulate.a > 0.99, "Active rod animation returns")
	check(area.active_tool_layer.art.scale.x < area.active_tool_layer.layout_scale * 0.83, "Animated rod uses the slimmer authored scale")
	await capture("compact-rod-settled")
	game._action_runtime()._stop_running_action("fishing", "river-bend")
	await show_location("shallows", "")
	await select_module_tool("shallows", "hands")
	method = game._fishing_ui_surface()._fishing_method_card_for_action("fishing", "shallows")
	await click((method.method_image_hit_control as Control).get_global_rect().get_center(), true)
	game.action_progress = 0.53
	await settle(0.7)
	area = game._fishing_ui_surface()._fishing_area_card_for_action("fishing", "shallows")
	check(area.active_tool_layer.immersion_depth() > 2.0 and area.active_tool_layer.immersion_depth() <= 5.05, "Hands dip shallowly inside the center pool")
	await capture("compact-hands-contact")
	game._action_runtime()._stop_running_action("fishing", "shallows")
	game.mastery.clear()
	game._hub_runtime().hub_modules.barn = {"level": 0, "building": false}
	SkillState.invalidate_stat_caches(game)
	await open_notes_skill("build")
	for example in [["stack-bricks", 98.0, "base-early-preserved"], ["frame-a-treehouse-platform", 82.0, "base-treehouse"], ["pour-questionable-foundation", 72.0, "base-foundation"]]:
		var card := await notes_card(str(example[0]))
		await align_notes_card(card)
		await settle(0.4)
		check(is_equal_approx(game._action_runtime()._success_chance("build", card.action), float(example[1])), "Concrete base rate renders through production: " + str(example[0]))
		await capture(str(example[2]))
