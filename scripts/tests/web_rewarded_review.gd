extends Node

var game: Node

func _ready() -> void:
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	AudioServer.set_bus_mute(0, true)
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("run")

func run() -> void:
	while not get_tree().root.has_node("Main"):
		await get_tree().process_frame
	game = get_tree().root.get_node("Main")
	while not game.startup_initialized or game._boot_warmup_runtime().active:
		await get_tree().process_frame
	game.god_mode_save_tainted = true
	game._audio_director().music_muted = true
	game._audio_director().sfx_muted = true
	game._audio_director()._apply_audio_bus_volumes()
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	for skill in game.skill_defs:
		for action in game.actions_by_skill[skill.id]:
			if preload("res://scripts/progression/mastery_state.gd").action_has_mastery(game, action):
				game.mastery[str(skill.id) + ":" + str(action.id)] = {"xp": preload("res://scripts/progression/mastery_state.gd").xp_for_level(3), "level": 3}
	game._tutorial_overlay_surface()._dismiss_blocking_tip()
	game._halloween_runtime().launch_greeting_claimed = true
	game._halloween_runtime().dismiss_launch_greeting()
	game._ad_bonus_runtime().seconds_remaining = 0.0
	game.current_screen = "menu"
	game._navigation_shell()._render_screen()
	await get_tree().create_timer(1.0).timeout
	var point: Vector2 = game._navigation_shell().shop_tab.get_global_rect().get_center()
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		event.position = point
		get_tree().root.push_input(event, true)
		await get_tree().process_frame
	while is_instance_valid(game):
		await get_tree().create_timer(0.5, true).timeout
		var ads = game._ad_bonus_runtime()
		var state := {"screen": game.current_screen, "seconds": ads.seconds_remaining, "loading": ads.ad_loading, "showing": ads.ad_showing, "paused": get_tree().paused, "muted": AudioServer.is_bus_mute(0)}
		JavaScriptBridge.eval("document.body.dataset.adReview = " + JSON.stringify(JSON.stringify(state)), true)
