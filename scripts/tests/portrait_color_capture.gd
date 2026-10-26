extends "res://scripts/tests/ham_oct21_capture.gd"


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Portrait color comparison requires --visible-game")
		quit(1)
		return
	create_timer(150).timeout.connect(func(): quit(1))
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "140")
	capture_dir = "res://outputs/verification/portrait-color"
	DirAccess.make_dir_recursive_absolute(capture_dir)
	root.content_scale_size = Vector2i(1080,1920)
	root.size = Vector2i(1080,1920)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	for _frame in range(1600):
		await settle(0.02)
		if game.startup_initialized and not game._boot_warmup_runtime().active:
			break
	check(game.startup_initialized, "Production main scene must boot")
	game._audio_director().music_muted = true
	game._audio_director().sfx_muted = true
	game._audio_director()._apply_audio_bus_volumes()
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	game.auto_unlock_lockpads_enabled = false
	game._action_runtime().activity_start_count = 10
	for skill in game.skill_defs:
		game.skills[skill.id] = {"xp":SkillState.xp_for_level(99),"level":99}
		for action in game.actions_by_skill[skill.id]:
			game._activity_unlock_runtime()._mark_action_manually_unlocked(skill.id,str(action.id))
	game._test_state_runtime()._clear_activity_unlock_ceremony_test_state()
	game._save_runtime().fishing_help_seen = true
	game._hub_surface().hub_tutorial_tip_seen = true
	AchievementState.mark_completed_seen_ids(AchievementState.milestones(game,false),game._save_runtime().achievement_toast_seen_ids,[])
	game._achievement_toast_surface().achievement_toast_queue.clear()
	game._achievement_toast_surface().achievement_toast_queue_ids.clear()
	game.current_screen = "menu"
	game._navigation_shell()._render_screen()
	await settle(1.5)
	await choose_skill("fight")
	var detail = game._skill_detail_surface()
	await detail._scroll_to_activity_card("ice-the-bruises",false,true)
	await settle(1.5)
	var card: Dictionary = game.action_cards.get("fight:ice-the-bruises",{})
	check(not card.is_empty(),"Portrait must remain in production main scene")
	if not card.is_empty():
		var art: TextureRect = card.art
		var rect := art.get_global_rect()
		check(card.root.get_global_rect().position.y > 410 and card.root.get_global_rect().end.y < 1400,"Changed portrait must be unobscured")
		var source_image := art.texture.get_image()
		if source_image.is_compressed():
			source_image.decompress()
		await RenderingServer.frame_post_draw
		var screenshot := root.get_texture().get_image()
		check(screenshot.get_size() == Vector2i(1080,1920),"Raw screenshot dimensions")
		for uv in [Vector2(0.52,0.34),Vector2(0.50,0.78)]:
			var source_pixel := source_image.get_pixelv(Vector2i(uv * Vector2(source_image.get_size())))
			var expected := Color.WHITE.lerp(source_pixel,source_pixel.a)
			var actual := screenshot.get_pixelv(Vector2i(rect.position + uv * rect.size))
			var error := maxf(absf(expected.r-actual.r),maxf(absf(expected.g-actual.g),absf(expected.b-actual.b)))
			print("portrait-color uv=",uv," source=",source_pixel," rendered=",actual," error=",error)
			check(error < 0.06,"Masked portrait must preserve the source color, not multiply it twice")
		screenshot.save_png(capture_dir + "/ice-the-bruises.png")
	print("portrait-color failures=",failures)
	game.queue_free()
	await settle(0.5)
	quit(0 if failures.is_empty() else 1)
