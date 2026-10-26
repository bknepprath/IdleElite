extends "res://scripts/tests/first_session_input.gd"

const AdBonus = preload("res://scripts/monetization/ad_bonus.gd")

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Version capture requires --visible-game")
		quit(1)
		return
	create_timer(90).timeout.connect(func(): quit(1))
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES","1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS","1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE","1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS","80")
	capture_dir = "res://outputs/verification/version-0.7.2"
	DirAccess.make_dir_recursive_absolute(capture_dir)
	root.content_scale_size = Vector2i(1080,1920)
	root.size = Vector2i(1080,1920)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE","0")
	game._audio_director().music_muted = true
	game._audio_director().sfx_muted = true
	game._audio_director()._apply_audio_bus_volumes()
	var boot = game._boot_warmup_runtime()
	await RenderingServer.frame_post_draw
	check(is_instance_valid(boot.splash) and boot.overlay.is_visible_in_tree() and boot.overlay.modulate.a > 0.99,"Capture must show the actual startup overlay")
	if is_instance_valid(boot.splash):
		var loading_version: Label = boot.splash.stack.get_child(1)
		check(loading_version.text == "0.7.2" and loading_version.is_visible_in_tree(),"Loading screen must display 0.7.2")
		var shot := root.get_texture().get_image()
		check(shot.get_size() == Vector2i(1080,1920),"Raw loading capture dimensions")
		shot.save_png(capture_dir + "/loading.png")
	for _frame in range(1600):
		await settle(0.02)
		if game.startup_initialized and not boot.active:
			break
	check(game.startup_initialized,"Production main scene must finish boot")
	await settle(1.0)
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	await click(game.settings_tab.get_global_rect().get_center(),true)
	await settle(0.8)
	check(game.current_screen == "settings","Settings must open through its real navigation button")
	var settings_version: Label
	for label in game.find_children("*","Label",true,false):
		if label.text == "Version 0.7.2" and label.is_visible_in_tree():
			settings_version = label
			break
	check(settings_version != null,"Settings must visibly display Version 0.7.2")
	if settings_version != null:
		check(settings_version.get_global_rect().end.y < 1710,"Settings version must fit above navigation")
	await capture("settings")
	check(AdBonus.AD_LIVE_UNIT_ANDROID_REWARDED == "ca-app-pub-4125359195200512/8284370963","New publisher's live rewarded unit must remain configured")
	check(AdBonus.AD_TEST_UNIT_ANDROID_REWARDED == "ca-app-pub-3940256099942544/5224354917","Debug test unit must remain separate")
	print("version-072 failures=",failures)
	game.queue_free()
	await settle(0.5)
	quit(0 if failures.is_empty() else 1)

