extends "res://scripts/tests/ham_oct21_capture.gd"

const HeistState = preload("res://scripts/thieving/state.gd")

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Hub trophy visual checks require --visible-game")
		quit(1)
		return
	create_timer(150).timeout.connect(func(): quit(1))
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "140")
	capture_dir = "res://outputs/verification/hub-trophy-table"
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
	for index in range(HeistState.HEIST_DEFS.size()):
		if game.current_screen == "hub":
			await click(game._navigation_shell().hub_tab.get_global_rect().get_center())
			await settle(0.8)
		check(game.current_screen != "hub","Hub must close through its navigation button")
		game.thieving_state.trophies.clear()
		for tier in range(index + 1):
			game.thieving_state.trophies[str(HeistState.HEIST_DEFS[tier].id)] = {"stolen":true,"cooldown_until_unix":0}
		await click(game._navigation_shell().hub_tab.get_global_rect().get_center())
		await settle(1.1)
		check(game.current_screen == "hub","Must reach the player hub through the actual bottom tab")
		var hub = game._hub_surface()
		var button: Control = hub.hub_module_buttons.trophy
		var table: TextureRect = button.get_node("HubTrophyTable")
		var trophy: TextureRect = button.get_node("HubDisplayedTrophy")
		var atlas := trophy.texture as AtlasTexture
		var sheet_image := atlas.atlas.get_image()
		if sheet_image.is_compressed():
			sheet_image.decompress()
		var source_image := sheet_image.get_region(Rect2i(atlas.region))
		var opaque := Rect2(source_image.get_used_rect())
		var scale_2d := trophy.size / Vector2(source_image.get_size())
		var visible := Rect2(trophy.global_position + opaque.position * scale_2d,opaque.size * scale_2d)
		var table_scale := minf(table.size.x / 1403.0,table.size.y / 1121.0)
		var table_offset := (table.size - Vector2(1403,1121) * table_scale) * 0.5
		# Independently authored top-face limits in the table's source PNG.
		var lower_third_top := table.global_position.y + table_offset.y + (306.0 + (624.0-306.0)*2.0/3.0) * table_scale
		var lower_third_end := table.global_position.y + table_offset.y + 624.0 * table_scale
		check(visible.end.y >= lower_third_top and visible.end.y <= lower_third_end,"Trophy bottom must rest in the tabletop's lower third")
		var width_fraction := visible.size.x / (1037.0 * table_scale)
		check(width_fraction >= 0.65 and width_fraction <= 0.9,"Visible trophy width must fit the actual table")
		check(visible.size.y >= 100.0,"Trophy must be large enough at phone size")
		check(button.get_global_rect().has_point(visible.get_center()),"Trophy center must remain tappable")
		var heist_id := str(HeistState.HEIST_DEFS[index].id)
		print("hub-trophy ",heist_id," visible=",visible," tabletop_bottom_third=",lower_third_top,"..",lower_third_end," width_fraction=",width_fraction)
		await capture(heist_id)
		await click(visible.get_center(),true)
		await settle(0.7)
		check(hub.hub_detail_open and game._hub_runtime().hub_selected_module_id == "trophy","Tapping the actual displayed trophy must open its hub details")
		await click(Vector2(540,1300))
		await settle(0.7)
		check(not hub.hub_detail_open,"Trophy details must dismiss normally")
	print("hub-trophy-table failures=",failures)
	game.queue_free()
	await settle(0.5)
	quit(0 if failures.is_empty() else 1)
