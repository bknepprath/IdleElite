extends "res://scripts/tests/desktop_discovery.gd"
const Desktop = preload("res://scripts/ui/desktop_layout.gd")

func wait_layout() -> void:
	await settle(0.4)
	for frame in range(1800):
		await process_frame
		if not game.desktop_layout.rendering and not game._navigation_shell().screen_render_in_progress and game.desktop_layout.last_window_size == root.size and game.desktop_layout.columns.size() == game.desktop_layout.page_count(): break
	await settle(0.35)

func _run() -> void:
	create_timer(180).timeout.connect(func(): quit(1))
	for usable in [Rect2i(0, 0, 1366, 728), Rect2i(-1920, 0, 1920, 1040), Rect2i(0, 0, 800, 560), Rect2i(1920, 0, 3840, 2080)]:
		var fit := Desktop.fitted_window_rect(usable, Vector2i(1600, 900), Vector2i(16, 48))
		check(usable.encloses(Rect2i(fit.position, fit.size + Vector2i(16, 48))), "Initial window including border fits usable monitor: " + str(usable))
	OS.set_environment("IDLE_ELITE_DESKTOP", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "175")
	AudioServer.set_bus_mute(0, true)
	Desktop.fit_startup_window(root)
	await settle(0.15)
	var usable := DisplayServer.screen_get_usable_rect(root.current_screen)
	check(usable.encloses(Rect2i(root.get_position_with_decorations(), root.get_size_with_decorations())), "Actual initial decorated window fits monitor work area")
	print("WINDOW_FIT usable=", usable, " decorated=", Rect2i(root.get_position_with_decorations(), root.get_size_with_decorations()))
	root.borderless = true
	root.position = Vector2i.ZERO
	root.size = Vector2i(1920, 1080)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	for frame in range(1600):
		await settle(0.02)
		if game.startup_initialized and not game._boot_warmup_runtime().active: break
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	game._tutorial_overlay_surface()._dismiss_blocking_tip()
	game.activity_crit_seen = true
	game.activity_mega_crit_seen = true
	game.desktop_layout.restore_preferences({})
	game.desktop_layout.rotate_slots("fight")
	game.selected_skill_id = "fight"
	await game._navigation_shell()._render_screen()
	await wait_layout()
	await click(game.action_cards["fight:push-ups"].button.get_global_rect().get_center())
	# 1680x1050 is a 16:10 screen: three pages would be 979 each, fewer than the
	# narrowest page allowed, so it shows two wider pages, as 1500x1000 (3:2) does.
	# At 3840x2160 the pixel cap alone would make a page 910 wide.
	var cases := [[800,600,1],[1000,600,2],[1280,720,2],[1366,768,2],[1500,1000,2],[1680,1050,2],[1920,1080,3],[2560,1440,3],[3440,1440,3],[3840,2160,3]]
	for dimensions in cases:
		root.size = Vector2i(dimensions[0], dimensions[1])
		await wait_layout()
		check(root.size == Vector2i(dimensions[0], dimensions[1]), "Exact requested viewport")
		var desktop = game.desktop_layout
		check(desktop.columns.size() == dimensions[2], "Readable column count: " + str(root.size))
		check(game.running_action_id == "push-ups", "Resizing preserves running activity")
		var scale: float = desktop.canvas_pixel_scale()
		for column in desktop.columns:
			var rect: Rect2 = column.page.get_global_rect()
			check(rect.position.x >= -1 and rect.end.x <= desktop.gameplay_width() + 1, "Full columns inside viewport")
			check(rect.size.x >= Desktop.MIN_COLUMN_CANVAS - 0.5, "A page is never narrower than its header and cards need: " + str(root.size))
			# The cap limits how far a page grows. It gives way where it would make a page narrower than the narrowest allowed.
			check(rect.size.x * scale <= maxf(Desktop.MAX_COLUMN_PIXELS, Desktop.MIN_COLUMN_CANVAS * scale) + 1, "Activity width has a pixel enlargement cap")
			check_header(column)
		for column in desktop.all_columns: check_header(column)
		for key in desktop.ribbon_buttons:
			check(Rect2(Vector2.ZERO, game.size).encloses(desktop.ribbon_buttons[key].get_global_rect()), "Ribbon fits: " + key)
		print("RESPONSIVE size=",root.size," columns=",desktop.columns.size()," canvas=",game.size," column_px=",desktop.column_width * scale)
		await capture_responsive("skills-" + str(root.size.x) + "x" + str(root.size.y))
		if dimensions[0] in [800,1280,1920,3840]:
			await click(desktop.ribbon_buttons.chat.get_global_rect().get_center())
			await wait_layout()
			check(desktop.social_tab == "chat", "Chat opens at " + str(root.size))
			for column in desktop.columns:
				check(column.page.get_global_rect().end.x <= desktop.gameplay_width() + 1, "Chat does not crop gameplay")
				check_header(column)
			for toast in game._achievement_toast_surface().achievement_toasts:
				if is_instance_valid(toast):
					check(toast.get_global_rect().end.x <= desktop.gameplay_width(), "Achievement stays beside chat after resize")
			await capture_responsive("chat-" + str(root.size.x))
			await click(desktop.ribbon_buttons.chat.get_global_rect().get_center())
			await wait_layout()
	root.mode = Window.MODE_FULLSCREEN
	await wait_layout()
	check(game.running_action_id == "push-ups", "Fullscreen preserves training")
	for column in game.desktop_layout.columns: check_header(column)
	await capture_responsive("fullscreen")
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1366,768)
	await wait_layout()
	await click(game.desktop_layout.ribbon_buttons.settings.get_global_rect().get_center())
	await settle(1)
	check(game.current_screen == "settings", "Settings stays reachable on laptop")
	await capture_responsive("settings-1366x768")
	print("DESKTOP_RESPONSIVE failures=", JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func check_header(column: Dictionary) -> void:
	var gauge: Control = column.context.detail_fish_circle if is_instance_valid(column.context.detail_fish_circle) else column.context.detail_regen_circle
	check(column.page.get_global_rect().grow(1).encloses(gauge.get_global_rect()), "Full header gauge inside column: " + str(root.size) + " " + str(column.skill_id))

func capture_responsive(label: String) -> void:
	game._tutorial_overlay_surface()._dismiss_blocking_tip()
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	check(picture.get_size() == root.size, "Unmodified raw viewport capture dimensions")
	DirAccess.make_dir_recursive_absolute("res://.codex-tmp/desktop-responsive")
	picture.save_png("res://.codex-tmp/desktop-responsive/" + label + ".png")
