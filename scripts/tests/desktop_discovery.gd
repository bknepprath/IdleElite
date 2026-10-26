extends "res://scripts/tests/desktop_layout_input.gd"
const SkillState = preload("res://scripts/progression/skill_state.gd")

func click_navigation(direction: int) -> void:
	var nav = game.desktop_layout.skill_navigation
	var motion := InputEventMouseMotion.new()
	motion.position = nav.corner_rect(0 if direction < 0 else 1).get_center()
	motion.global_position = motion.position
	root.push_input(motion, true)
	await settle(0.45)
	await click((nav.previous if direction < 0 else nav.next).get_global_rect().get_center())

func capture_desktop(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	check(picture.get_size() == root.size, "Raw viewport dimensions")
	DirAccess.make_dir_recursive_absolute("res://.codex-tmp/desktop-discovery")
	picture.save_png("res://.codex-tmp/desktop-discovery/" + label + ".png")

func sample_frames(label: String, seconds: float) -> void:
	var elapsed := Time.get_ticks_msec()
	var previous := Time.get_ticks_usec()
	var samples: Array[int] = []
	while Time.get_ticks_msec() - elapsed < seconds * 1000:
		await process_frame
		var now := Time.get_ticks_usec()
		samples.append(now - previous)
		previous = now
	samples.sort()
	print("FRAME_SAMPLE ", label, " count=", samples.size(), " p99_ms=", samples[int(samples.size() * 0.99)] / 1000.0, " max_ms=", samples[-1] / 1000.0)

func _run() -> void:
	create_timer(150).timeout.connect(func(): quit(1))
	OS.set_environment("IDLE_ELITE_DESKTOP", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "140")
	AudioServer.set_bus_mute(0, true)
	root.size = Vector2i(1920, 1080)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	for frame in range(1600):
		await settle(0.02)
		if game.startup_initialized and not game._boot_warmup_runtime().active: break
	check(not game.desktop_layout.skill_navigation.visible, "No navigation in centered opening")
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	game._tutorial_overlay_surface()._dismiss_blocking_tip()
	game.desktop_layout.restore_preferences({})
	game.desktop_layout.rotate_slots("fishing")
	game.selected_skill_id = "fight"
	game.auto_unlock_lockpads_enabled = true
	await game._navigation_shell()._render_screen()
	await settle(2)
	await capture_desktop("navigation-before")
	var desktop = game.desktop_layout
	check(desktop.skill_navigation.visible, "Navigator after neighbors reveal")
	await click_navigation(1)
	await settle(0.3)
	check(desktop.skill_slots == ["fight", "thieving", "build"], "Next moves whole carousel one skill")
	print("NAV_BEFORE_PREV slots=", desktop.skill_slots, " disabled=", desktop.skill_navigation.previous.disabled, " settling=", desktop.carousel_settling, " modal=", game._input_routing_shell()._any_modal_overlay_visible())
	await click_navigation(-1)
	await settle(0.3)
	print("NAV_AFTER_PREV slots=", desktop.skill_slots)
	await capture_desktop("navigation-buttons")
	check(desktop.skill_slots == ["fishing", "fight", "thieving"], "Previous restores all three")
	await drag_carousel(-1, "navigation")
	check(desktop.carousel_discovered, "Actual drag dismisses hint")
	await click_navigation(-1)
	await settle(1)
	var original_frame: int = desktop.carousel_frame.get_instance_id()
	var original_first: int = game.action_cards["fight:push-ups"].root.get_instance_id()
	game.skills.fight.xp = SkillState.xp_for_level(2) - 1
	SkillState.recalculate_level(game, "fight", false)
	await click(game.action_cards["fight:push-ups"].button.get_global_rect().get_center())
	await sample_frames("level-two-unlock", 30.0)
	check(desktop.carousel_frame.get_instance_id() == original_frame, "Unlock retains carousel and neighboring animations")
	check(game.action_cards["fight:push-ups"].root.get_instance_id() == original_first, "Unlock retains existing activity nodes")
	print("RETAINED_FRAME=", is_instance_valid(desktop.carousel_frame) and desktop.carousel_frame.get_instance_id() == original_frame, " RETAINED_CARD=", game.action_cards["fight:push-ups"].root.get_instance_id() == original_first)
	await capture_desktop("unlock-settled")
	await firepit_checks()
	check_medal_cache_invalidation()
	print("DISCOVERY failures=", JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func firepit_checks() -> void:
	game._action_runtime()._stop_running_action(game.running_skill_id, game.running_action_id)
	game._tutorial_overlay_surface()._dismiss_blocking_tip()
	var desktop = game.desktop_layout
	# Navigate to Woodcutting through the production shared buttons.
	for step in range(5):
		if desktop.skill_slots[0] == "woodcutting": break
		await click_navigation(-1)
		await settle(0.4)
	check(desktop.skill_slots[0] == "woodcutting", "Buttons wrap to Woodcutting")
	var motion := InputEventMouseMotion.new()
	motion.position = desktop.columns[0].picker.get_global_rect().get_center()
	root.push_input(motion, true)
	await settle(0.5)
	game.skills.woodcutting.xp = 11
	SkillState.recalculate_level(game, "woodcutting", false)
	game._update_ui(0.0, true)
	await settle(0.7)
	var card: Dictionary = game.action_cards.get("woodcutting:firepit", {})
	check(not card.is_empty(), "Firepit mounted in real Woodcutting column")
	if card.is_empty(): return
	await capture_desktop("firepit-locked")
	check(not card.pop.clip_contents and not card.root.clip_contents, "Chains extend over outside of module")
	check(absf(card.art_root.position.x + card.art_root.size.x * 0.5 - card.pop.size.x * 0.5) < 1.0, "Firepit is horizontally centered")
	game.skills.woodcutting.xp = SkillState.xp_for_level(2)
	SkillState.recalculate_level(game, "woodcutting", true)
	game.material_runtime.set_amount("scrapwood", 60.0)
	await settle(0.2)
	await capture_desktop("firepit-unlock-transition")
	await settle(2.8)
	game._activity_unlock_runtime()._mark_action_manually_unlocked("woodcutting", "firepit")
	game._update_ui(0.0, true)
	await settle(0.3)
	await capture_desktop("firepit-before")
	# Capture the real reveal while a native button tap lights the fire.
	capture_firepit_transition()
	await click(card.toggle.get_global_rect().get_center(), true)
	await settle(1.5)
	check(game._passive_modules_runtime().firepit_active(game._unix_now()), "Actual Firepit tap starts fire")
	var stable_y: float = card.root.position.y
	check(stable_y > 390, "Fuel feeder settles fully open")
	for step in range(12):
		var hover := InputEventMouseMotion.new()
		hover.position = desktop.columns[step % desktop.columns.size()].picker.get_global_rect().get_center()
		root.push_input(hover, true)
		game._update_ui(0.0, true)
		await settle(0.12)
		check(is_equal_approx(card.root.position.y, stable_y), "Focus and refresh never reopen or contract feeder")
	var wheel := InputEventMouseButton.new()
	wheel.position = card.toggle.get_global_rect().get_center()
	wheel.global_position = wheel.position
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	root.push_input(wheel, true)
	await settle(1.0)
	await capture_desktop("firepit-settled")
	root.size = Vector2i(1080, 1920)
	await settle(1.5)
	game._navigation_shell()._select_skill("fight")
	await settle(1.0)
	await capture_desktop("padlock-portrait")
	check(not desktop.skill_navigation.visible, "Desktop navigator hidden in portrait")

func capture_firepit_transition() -> void:
	await settle(0.2)
	await capture_desktop("firepit-transition")

func check_medal_cache_invalidation() -> void:
	var achievements = preload("res://scripts/achievements/state.gd")
	var mastery = preload("res://scripts/progression/mastery_state.gd")
	game.set_process(false)
	var saved: Dictionary = game.mastery.duplicate(true)
	game.mastery.clear()
	SkillState.invalidate_stat_caches(game)
	check(achievements.skill_medal_counts(game, "fight").earned == 0, "Initial medal cache is empty")
	check(achievements.tier_medal_counts(game, "fight", 1).earned == 0, "Initial tier cache is empty")
	mastery.add_host_xp(game, "fight", "push-ups", mastery.xp_for_level(3))
	check(achievements.skill_medal_counts(game, "fight").earned == 3, "New medal invalidates skill totals")
	check(achievements.tier_medal_counts(game, "fight", 1).earned == 3, "New medal invalidates tier totals")
	check(achievements.global_medal_tier_unlocked(game, 3), "Earned medal grants global tier")
	check(not achievements.global_medal_tier_unlocked(game, 4), "Higher unearned tier stays locked")
	game.mastery.clear()
	var arenas := 0
	for action in game.actions_by_skill.fight:
		if str(action.get("combat", {}).get("arena_shape", "")) == "diamond":
			game.mastery["fight:" + str(action.id)] = {"level": 10, "xp": mastery.xp_for_level(10)}
			arenas += 1
	SkillState.invalidate_stat_caches(game)
	check(arenas > 0 and not achievements.global_medal_tier_unlocked(game, 1), "Legacy arena medals grant no global buff")
	check(achievements.skill_medal_counts(game, "fight").earned == 0, "Arena medals excluded after cache invalidation")
	game.mastery = saved
	SkillState.invalidate_stat_caches(game)
