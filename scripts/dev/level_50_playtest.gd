extends SceneTree

const SkillState = preload("res://scripts/progression/skill_state.gd")
var game: Node
var capture_key_down := false

func _process(_delta: float) -> bool:
	AudioServer.set_bus_mute(0,true)
	var down:=Input.is_physical_key_pressed(KEY_F12)
	if down and not capture_key_down: capture_current_view()
	capture_key_down=down
	return false

func capture_current_view() -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://outputs/verification/level-50-playtest/desktop.png")

func _init() -> void:
	call_deferred("start")

func start() -> void:
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_DESKTOP", "1")
	AudioServer.set_bus_mute(0, true)
	preload("res://scripts/ui/desktop_layout.gd").fit_startup_window(root)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for attempt in 1500:
		await create_timer(.02).timeout
		if game.startup_initialized and not game._boot_warmup_runtime().active: break
	if not game.startup_initialized:
		push_error("Level 50 playtest could not boot")
		quit(1)
		return
	if OS.get_environment("IDLE_ELITE_RESUME_PLAYTEST")=="1":
		root.title="Idle Elite | Level 50 playtest"
		game._halloween_runtime().dismiss_launch_greeting()
		print("LEVEL_50_PLAYTEST_RESUMED muted=",AudioServer.is_bus_mute(0))
		return
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	game._tutorial_overlay_surface()._dismiss_blocking_tip()
	game._onboarding_runtime().activity_start_tip_seen = true
	for skill in game.skills:
		game.skills[skill].xp = SkillState.xp_for_level(50)
		SkillState.recalculate_level(game,skill,false)
		game.stamina[skill] = 100
		for action in game.actions_by_skill[skill]:
			if int(action.unlock)>50: continue
			game._activity_unlock_runtime()._mark_action_manually_unlocked(str(skill),str(action.id))
	game._test_state_runtime()._clear_activity_unlock_ceremony_test_state()
	for material in game.material_runtime.material_defs:
		game.material_runtime.set_amount(str(material),1000)
	game.fishing_runtime.fish_currency = 1000
	game.auto_unlock_lockpads_enabled = false
	game.current_screen = "menu"
	await game._navigation_shell()._render_screen()
	game._mark_save_dirty("level 50 playtest setup")
	game._halloween_runtime().dismiss_launch_greeting()
	AudioServer.set_bus_mute(0,true)
	root.title = "Idle Elite | Level 50 playtest"
	await create_timer(1).timeout
	await click(game.skill_cards.woodcutting.button.get_global_rect().get_center())
	await create_timer(1).timeout
	if game.current_screen=="skill":
		await game._skill_detail_surface()._scroll_to_activity_card("grove-birch",false,true)
	await create_timer(.8).timeout
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://outputs/verification/level-50-playtest")
	root.get_texture().get_image().save_png("res://outputs/verification/level-50-playtest/desktop.png")
	print("LEVEL_50_PLAYTEST_READY skills=",JSON.stringify(game.skills)," muted=",AudioServer.is_bus_mute(0))

func click(point: Vector2) -> void:
	point *= Vector2(root.size)/game.size
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion,true)
	await process_frame
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event,true)
		await create_timer(.06).timeout
