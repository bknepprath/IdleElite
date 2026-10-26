extends "res://scripts/tests/desktop_layout_input.gd"

func _run() -> void:
	create_timer(150).timeout.connect(func(): quit(1))
	OS.set_environment("IDLE_ELITE_DESKTOP", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "100")
	AudioServer.set_bus_mute(0, true)
	root.borderless = true
	root.size = Vector2i(1920, 1080)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	var boot_captured := false
	for frame in range(1500):
		await settle(0.02)
		var boot = game._boot_warmup_runtime()
		if not boot_captured and is_instance_valid(boot.overlay) and boot.overlay.is_visible_in_tree():
			await capture_desktop("boot")
			boot_captured = true
		if game.startup_initialized and not game._boot_warmup_runtime().active: break
	await settle(1)
	check_opening("cold-start")
	await capture_desktop("cold-start")
	var target: Control = game._tutorial_overlay_surface()._tutorial_target_control()
	check(is_instance_valid(target), "Starter target exists")
	if is_instance_valid(target):
		await click(target.get_global_rect().get_center())
		check(game.running_action_id == "push-ups", "Push-Ups starts through actual input")
	await settle(0.2)
	check(not game._onboarding_runtime().tutorial_active, "First click graduates the opening")
	check_fighting_centered("after-first-action")
	await capture_desktop("after-first-action")
	game._action_runtime()._stop_running_action("fight", "push-ups")
	game._tutorial_overlay_surface()._dismiss_blocking_tip()
	game._onboarding_runtime().onboarding_starter_action_completion_count = 1
	await settle(0.3)
	check(game.desktop_layout.intro_stage == 1, "First completion begins basic UI fade")
	await capture_desktop("controls-transition")
	game._onboarding_runtime().onboarding_starter_action_completion_count = 2
	for frame in range(300):
		await process_frame
		if game.desktop_layout.columns.size() == 3 and not game.desktop_layout.rendering: break
	check(int(game.skills.fight.level) == 1, "Neighbors start while Fighting is still level one")
	check_columns(3, "neighbor reveal")
	check_fighting_centered("neighbor reveal")
	await capture_desktop("neighbors-before")
	await settle(0.17)
	check(reveal_amount(game.desktop_layout.columns[0].page) > 0.0 and reveal_amount(game.desktop_layout.columns[0].page) < 1.0, "Fishing fades briefly through intermediate opacity")
	check(reveal_amount(game.desktop_layout.columns[2].page) == 0.0, "Thieving waits for its staggered entrance")
	var preview: Dictionary = game.action_cards.get("fight:" + game.TUTORIAL_LEVEL_TWO_ACTION_ID, {})
	check(not preview.is_empty() and preview.root.modulate.a == 1.0, "Second Fighting module has solid nested layers")
	await capture_desktop("neighbors-transition")
	await settle(1.04)
	await capture_desktop("thieving-transition")
	await settle(0.7)
	check(not game.desktop_layout.ribbon_buttons.settings.disabled, "Settings fades in during level one")
	check(game.desktop_layout.ribbon_buttons.hub.get_meta("nav_locked", false), "Later features are visible but locked")
	check_fighting_centered("neighbors settled")
	await capture_desktop("neighbors-settled")
	var stored: Dictionary = game.desktop_layout.saved_preferences()
	game.desktop_layout.restore_preferences(stored)
	check(game.desktop_layout.intro_stage == 2, "Onboarding stage survives save preferences roundtrip")
	# Trigger the real level-two reconciliation and capture the new module fade.
	await capture_desktop("level-two-before")
	game.skills.fight.xp = preload("res://scripts/progression/skill_state.gd").xp_for_level(2)
	preload("res://scripts/progression/skill_state.gd").recalculate_level(game, "fight", false)
	game._update_ui(0.0, true)
	await settle(0.2)
	await capture_desktop("level-two-transition")
	await settle(1)
	await capture_desktop("level-two-settled")
	game.skills.thieving.xp = 1
	await settle(2.2)
	check(game.desktop_layout.intro_stage == 3, "Exploring finishes the initial skill introduction")
	check(game.desktop_layout.ribbon_buttons.hub.get_meta("nav_locked", false), "Exploring does not unlock Hub")
	check(game.desktop_layout.intro_features.is_empty(), "First XP in another skill does not reveal the ribbon")
	await capture_desktop("features-settled")
	game.skills.build.xp = preload("res://scripts/progression/skill_state.gd").xp_for_level(3)
	game.skills.fight.xp = preload("res://scripts/progression/skill_state.gd").xp_for_level(25)
	preload("res://scripts/progression/skill_state.gd").recalculate_level(game, "build", false)
	preload("res://scripts/progression/skill_state.gd").recalculate_level(game, "fight", false)
	game.desktop_layout.intro_features.append("queue")
	game.desktop_layout.intro_feature_cooldown = 0.0
	await settle(0.6)
	check(game.desktop_layout.intro_features == ["queue", "hub"], "Only one eligible feature is introduced")
	await capture_desktop("hub-reveal-transition")
	await settle(5)
	check(not game.desktop_layout.ribbon_buttons.hub.get_meta("nav_locked", false), "Hub unlocks after its Building milestone")
	check(game.desktop_layout.ribbon_buttons.home.get_meta("nav_locked", false) and game.desktop_layout.ribbon_buttons.scores.get_meta("nav_locked", false), "Other eligible buttons wait their turn")
	await capture_desktop("hub-reveal-settled")
	check(game.desktop_layout.intro_feature_cooldown > 23.0, "Reveals remain at least thirty active seconds apart")
	stored = game.desktop_layout.saved_preferences()
	game.desktop_layout.restore_preferences({})
	check(game.desktop_layout.intro_stage == 3, "Legacy saves keep full desktop access")
	game.desktop_layout.restore_preferences(stored)
	check(game.desktop_layout.intro_features == ["queue", "hub"], "Individual revealed features survive save roundtrip")
	# Dismiss later onboarding tips to exercise the normal carousel and settings.
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	game._tutorial_overlay_surface()._dismiss_blocking_tip()
	await settle(0.5)
	await drag_carousel(-1, "drag")
	check_columns(3, "drag settled")
	for dimensions in [Vector2i(1280, 720), Vector2i(1000, 600), Vector2i(1920, 1080)]:
		root.size = dimensions
		await settle(1.3)
		check_columns(2 if dimensions.x < 1920 else 3, str(dimensions))
		await capture_desktop("resized-" + str(dimensions.x))
	# Reproduce the report from an existing desktop session through Settings.
	await click(game.desktop_layout.ribbon_buttons.settings.get_global_rect().get_center())
	await settle(0.8)
	var settings = game._settings_surface()
	check(game.current_screen == "settings", "Settings opens through bottom ribbon")
	check(not settings.reset_data_buttons.is_empty(), "Reset button exists")
	if not settings.reset_data_buttons.is_empty():
		var button: Button = settings.reset_data_buttons[0]
		var ancestor: Node = button.get_parent()
		while ancestor != null:
			if ancestor is ScrollContainer: ancestor.ensure_control_visible(button)
			ancestor = ancestor.get_parent()
		await settle(0.4)
		await click(button.get_global_rect().get_center())
		check(button.text == settings.RESET_DATA_CONFIRM_TEXT, "Reset confirmation armed through UI")
		await settle(settings.RESET_DATA_CONFIRM_MIN_SECONDS + 0.2)
		await click(button.get_global_rect().get_center())
		await settle(1.5)
		check_opening("after-reset")
		await capture_desktop("after-reset")
	print("DESKTOP_OPENING failures=", JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func check_opening(label: String) -> void:
	check(game._onboarding_runtime().tutorial_active, label + " tutorial active")
	check(game.selected_skill_id == "fight", label + " focuses Fighting")
	check_columns(1, label)
	check_fighting_centered(label)
	check(game.desktop_layout.intro_stage == 0, label + " begins gradual onboarding")
	check(not game.desktop_layout.toolbar.visible, label + " no premature ribbon")
	var surface = game._tutorial_overlay_surface()
	var target: Control = surface._tutorial_target_control()
	var text: Label = surface.tutorial_instruction_label
	check(text.is_visible_in_tree(), label + " instruction visible")
	if is_instance_valid(target):
		check(absf(text.get_global_rect().get_center().x - target.get_global_rect().get_center().x) < 2, label + " instruction centered under activity")
		check(text.get_global_rect().position.y >= target.get_global_rect().end.y, label + " instruction below activity")
	var header = game._skill_detail_surface().detail_header_left_block
	check(is_instance_valid(header) and header.is_visible_in_tree(), label + " Fighting header visible")
	check(not surface.tutorial_arrow.is_visible_in_tree(), label + " header has no arrow overlay")

func check_fighting_centered(label: String) -> void:
	for column in game.desktop_layout.columns:
		if column.skill_id == "fight":
			check(absf(column.page.get_global_rect().get_center().x - game.size.x * 0.5) < 2, label + " Fighting remains centered")


func check_columns(expected: int, label: String) -> void:
	var desktop = game.desktop_layout
	check(desktop.columns.size() == expected, label + " column count")
	var visible := 0
	for column in desktop.all_columns:
		if not column.page.is_visible_in_tree(): continue
		visible += 1
		var bounds: Rect2 = column.page.get_global_rect()
		check(bounds.position.x >= -1 and bounds.end.x <= game.size.x + 1, label + " column fully inside window: " + str(column.skill_id))
	check(visible == expected, label + " no neighboring page peeks into margins")

func capture_desktop(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	check(picture.get_size() == root.size, "Raw viewport capture dimensions")
	DirAccess.make_dir_recursive_absolute("res://.codex-tmp/desktop-opening")
	picture.save_png("res://.codex-tmp/desktop-opening/" + label + ".png")

func reveal_amount(target: Control) -> float:
	if not target.has_meta("activity_reveal_cover"): return 1.0
	var cover = target.get_meta("activity_reveal_cover").get_ref()
	return cover.revealed if is_instance_valid(cover) else 1.0
