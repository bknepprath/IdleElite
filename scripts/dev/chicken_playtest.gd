extends SceneTree

const SkillState := preload("res://scripts/progression/skill_state.gd")

const LEVEL_LABELS := ["UNLOCK", "+25", "HIGH"]

var scene: Node
var action_id := "fight-chickens"
var opponent_label := "CHICKEN"
var levels := [5, 50, 99]
var selected_level := 5
var title_label: Label
var level_buttons := {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "600")
	action_id = OS.get_environment("IDLE_ELITE_FIGHT_PLAYTEST_ACTION_ID") if not OS.get_environment("IDLE_ELITE_FIGHT_PLAYTEST_ACTION_ID").is_empty() else action_id
	opponent_label = OS.get_environment("IDLE_ELITE_FIGHT_PLAYTEST_LABEL") if not OS.get_environment("IDLE_ELITE_FIGHT_PLAYTEST_LABEL").is_empty() else opponent_label
	var unlock_level := maxi(1, OS.get_environment("IDLE_ELITE_FIGHT_PLAYTEST_UNLOCK_LEVEL").to_int())
	levels[0] = unlock_level
	levels[1] = _middle_level_for_unlock(unlock_level)
	assert(_middle_level_for_unlock(47) == 72 and _middle_level_for_unlock(74) == 87 and _middle_level_for_unlock(90) == 95)
	selected_level = clampi(OS.get_environment("IDLE_ELITE_CHICKEN_PLAYTEST_LEVEL").to_int(), unlock_level, 99)
	if not levels.has(selected_level):
		selected_level = unlock_level
	var capture_path := OS.get_environment("IDLE_ELITE_CHICKEN_PLAYTEST_CAPTURE_PATH")
	if not capture_path.is_empty():
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
		root.content_scale_size = Vector2i(2160, 3840)
		root.size = Vector2i(1080, 1920)
		DisplayServer.window_set_size(root.size)

	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("main scene did not load")
		return
	scene = packed.instantiate()
	root.add_child(scene)
	if not await _wait_for_boot_ready():
		_fail("main scene did not become ready")
		return

	_prepare_isolated_fight()
	await scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	for _frame in range(12):
		await process_frame
	var detail_surface: Object = scene.call("_skill_detail_surface")
	detail_surface.call("_ensure_detail_lazy_entry_mounted", action_id)
	await detail_surface.call("_scroll_to_activity_card", action_id, false, true)
	for _frame in range(12):
		await process_frame
	_build_level_controls()
	_apply_level(selected_level)

	if capture_path.is_empty() and OS.get_environment("IDLE_ELITE_CHICKEN_PLAYTEST_VALIDATE_INPUT") == "1":
		await _show_giant_boulder_break()
		if not _assert_giant_hold_stops_fight():
			return
		print("giant-boulder-input-ok")
		quit(0)
		return
	if capture_path.is_empty():
		return
	var capture_state := OS.get_environment("IDLE_ELITE_CHICKEN_PLAYTEST_CAPTURE_STATE")
	if capture_state == "KOSequence":
		await _capture_hero_ko_sequence(capture_path)
		return
	if capture_state == "RouseRollSequence":
		await _capture_rouses_roll_sequence(capture_path)
		return
	if capture_state == "KORetreat":
		await _show_ko_retreat()
	elif capture_state == "Opening":
		await _wait_for_opening_single()
	elif capture_state == "SpawnWindowEnd":
		await _wait_for_spawn_window_end()
	elif capture_state == "PostEndRestart":
		await _show_post_end_restart()
	elif capture_state == "MegaCrit":
		await _show_mega_crit_feedback()
	elif capture_state == "KO":
		await _wait_for_knocked_out()
	elif capture_state == "Damaged":
		await _wait_for_damaged_chicken()
	elif capture_state == "WerewolfTransform":
		await _wait_for_werewolf_transform()
	elif capture_state == "WerewolfScratch":
		await _show_werewolf_scratch()
	elif capture_state == "WaveReady":
		await _show_wave_ready()
	elif capture_state == "GoblinHit":
		await _show_goblin_hit()
	elif capture_state == "Defeated":
		await _show_defeated_variants()
	elif capture_state == "DeathAirborne":
		await _show_defeated_variants(0.19)
	elif capture_state == "DeathBounce":
		await _show_defeated_variants(0.505)
	elif capture_state == "DeathRest":
		await _show_defeated_variants(1.50)
	elif capture_state == "DeathFade":
		await _show_defeated_variants(2.09)
	elif capture_state == "DeathComparison":
		await _show_death_power_comparison()
	elif capture_state == "DeathAngles":
		await _show_defeated_variants(0.19, [Vector2.RIGHT, Vector2.UP, Vector2(1.0, -1.0).normalized()])
	elif capture_state == "VariantAttacks":
		await _show_variant_attack_frames()
	elif capture_state == "VariantStates":
		await _show_variant_state_frames()
	elif capture_state == "Crowd":
		await _show_crowded_chickens()
	elif capture_state == "ShieldDropRest":
		await _show_goblin_shield_drop()
	elif capture_state == "PunchStack":
		await _show_goblin_punch_stack()
	elif capture_state == "GuysFlee":
		await _wait_for_guys_flee()
	elif capture_state == "GiantWalk":
		await _show_giant_walk()
	elif capture_state == "GiantPair":
		await _show_giant_pair()
	elif capture_state == "GiantToss":
		await _show_giant_toss()
	elif capture_state == "GiantStomp":
		await _show_giant_stomp()
	elif capture_state == "GiantBoulder":
		await _show_giant_boulder()
	elif capture_state == "GiantBoulderBreak":
		await _show_giant_boulder_break()
	elif capture_state == "GiantBoulderDrop":
		await _show_giant_boulder_drop()
	elif capture_state == "GiantProgression":
		await _show_giant_progression()
	elif capture_state == "GiantLayer":
		await _show_giant_layer()
	elif capture_state == "CaveTrollPound":
		await _show_cave_troll_pound()
	elif capture_state == "DragonMeleeAim":
		await _show_dragon_melee_aim()
	elif capture_state == "DragonBoundary":
		await _show_dragon_boundary_escape()
	elif capture_state == "DragonBreath":
		await _show_dragon_breath()
	elif capture_state == "DragonPounce":
		await _show_dragon_pounce()
	elif capture_state == "VampireSpecials":
		await _show_vampire_specials()
	elif capture_state == "VampireGiant":
		await _show_vampire_giant()
	elif capture_state == "LowHP":
		await _show_low_hp_state()
	elif capture_state == "HeroGuard":
		await _show_hero_pose(0.0, false)
	elif capture_state == "HeroPunch":
		await _show_hero_pose(0.16, false)
	elif capture_state == "HeroUppercut":
		await _show_hero_pose(0.17, true)
	elif capture_state == "Strike":
		await _wait_for_attack_phase("strike")
	elif capture_state == "AttackFrame3":
		await _show_attack_frame_three()
	else:
		await _wait_for_attack_phase("windup")
	await RenderingServer.frame_post_draw
	var texture := root.get_texture()
	if texture == null:
		_fail("capture texture was missing")
		return
	var image := texture.get_image()
	if image == null or image.is_empty():
		_fail("capture image was empty")
		return
	var result := image.save_png(capture_path)
	if result != OK:
		_fail("could not save playtest capture")
		return
	if capture_state == "GiantBoulderBreak" and not _assert_giant_hold_stops_fight():
		return
	print("chicken-playtest-capture-ok path=%s level=%d" % [capture_path, selected_level])
	quit(0)


func _prepare_isolated_fight() -> void:
	scene.call("_test_state_runtime").call("_god_mode_unlock_onboarding_state")
	scene.call("_tutorial_overlay_surface").call("_update_tutorial_overlay")
	var boot_warmup: Object = scene.call("_boot_warmup_runtime")
	boot_warmup.call("_dismiss_boot_splash_for_play")
	boot_warmup.call("_finish_overlay_hide")
	scene.call("_achievement_overlay_surface").call("hide_offline_summary_immediate")
	_set_fighting_level(selected_level)
	scene.call("_activity_unlock_runtime").call("sync_manual_activity_unlocks_from_levels")
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", "fight")
	if not bool(scene.call("_action_runtime").call("_start_action", "fight", action_id, true, false)):
		_fail("%s could not start" % action_id)


func _set_fighting_level(level: int) -> void:
	var fight := (scene.get("skills") as Dictionary).get("fight", {}) as Dictionary
	fight["level"] = level
	fight["xp"] = SkillState.xp_for_level(level)
	(scene.get("skills") as Dictionary)["fight"] = fight
	SkillState.invalidate_stat_caches(scene)
	(scene.get("stamina") as Dictionary)["fight"] = float(SkillState.max_stamina(scene, "fight"))
	(scene.get("stamina_bank") as Dictionary)["fight"] = 0.0


func _apply_level(level: int) -> void:
	selected_level = level
	_set_fighting_level(level)
	scene.call("_update_ui", 0.0, false)
	var stage := _chicken_stage()
	if stage != null:
		stage.call("setup_fighting_level", level)
		stage.call("set_active_fight", false)
		stage.call("set_active_fight", true)
	title_label.text = "%s TEST - LV %d" % [opponent_label, level]
	for raw_level in level_buttons:
		(level_buttons[raw_level] as Button).disabled = int(raw_level) == level


func _chicken_stage() -> Control:
	var key := str(scene.call("_action_key", "fight", action_id))
	var card := (scene.get("action_cards") as Dictionary).get(key, {}) as Dictionary
	return card.get("blue_guy_chicken_stage") as Control


func _build_level_controls() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 500
	scene.add_child(layer)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.offset_left = 60.0
	panel.offset_top = 36.0
	panel.offset_right = -60.0
	panel.offset_bottom = 330.0
	panel.add_theme_stylebox_override("panel", _style(Color("#202532ee"), Color("#171615"), 6))
	layer.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 20)
	panel.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 14)
	margin.add_child(stack)

	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 60)
	title_label.add_theme_color_override("font_color", Color("#fffaf0"))
	stack.add_child(title_label)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	stack.add_child(row)
	for index in range(levels.size()):
		var level := int(levels[index])
		var button := Button.new()
		var level_label: String = "MIDPOINT" if index == 1 and level != int(levels[0]) + 25 else LEVEL_LABELS[index]
		button.text = "%s  LV %d" % [level_label, level]
		button.custom_minimum_size.y = 126.0
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 52)
		button.add_theme_color_override("font_color", Color("#171615"))
		button.add_theme_color_override("font_disabled_color", Color("#171615"))
		button.add_theme_stylebox_override("normal", _style(Color("#4fc3ff"), Color("#171615"), 5))
		button.add_theme_stylebox_override("hover", _style(Color("#78d2ff"), Color("#171615"), 5))
		button.add_theme_stylebox_override("pressed", _style(Color("#35a9e8"), Color("#171615"), 5))
		button.add_theme_stylebox_override("disabled", _style(Color("#48dd6c"), Color("#171615"), 5))
		button.pressed.connect(Callable(self, "_apply_level").bind(level))
		row.add_child(button)
		level_buttons[level] = button


func _middle_level_for_unlock(unlock_level: int) -> int:
	return unlock_level + 25 if unlock_level + 25 < 99 else ceili((unlock_level + 99) * 0.5)


func _style(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(28)
	return style


func _wait_for_boot_ready() -> bool:
	for _frame in range(720):
		await process_frame
		var queue := scene.get("boot_detail_render_queue") as Array
		if (
			bool(scene.get("startup_initialized"))
			and not bool(scene.get("boot_detail_render_in_progress"))
			and not bool(scene.get("boot_detail_scroll_locked"))
			and not bool(scene.call("_navigation_shell").get("screen_render_in_progress"))
			and (queue == null or queue.is_empty())
		):
			return true
	return false


func _wait_for_attack_phase(phase: String) -> void:
	for _frame in range(600):
		await process_frame
		var stage := _chicken_stage()
		if stage == null or float(stage.get("hero_ko_timer")) > 0.0:
			continue
		for raw_actor in stage.get("chickens") as Array:
			if str((raw_actor as Dictionary).get("attack_phase", "")) == phase:
				return


func _wait_for_opening_single() -> void:
	for _frame in range(120):
		await process_frame
		var stage := _chicken_stage()
		if stage != null and int(stage.get("wave_spawned_count")) == 1 and (stage.get("chickens") as Array).size() == 1:
			return


func _wait_for_spawn_window_end() -> void:
	for _frame in range(900):
		await process_frame
		var stage := _chicken_stage()
		if stage == null or int(stage.get("wave_index")) != 0:
			continue
		if float(stage.get("wave_elapsed_current")) >= float(stage.get("wave_spawn_phase_duration_current")) - 0.12:
			stage.set_process(false)
			stage.queue_redraw()
			print("fight-spawn-window-capture-ok spawned=%d" % int(stage.get("wave_spawned_count")))
			await process_frame
			return
	_fail("wave-one spawn window did not reach its capture point")


func _show_post_end_restart() -> void:
	var stage := _chicken_stage()
	if stage == null:
		_fail("post-End-Wave stage was missing")
		return
	stage.set_process(false)
	stage.call("_start_end_wave")
	stage.set("wave_spawn_remaining", 0)
	(stage.get("chickens") as Array).clear()
	stage.call("_complete_end_wave")
	stage.call("_step_area_clear_restart", 2.0)
	stage.call("_step_fight", 0.0)
	stage.queue_redraw()
	await process_frame


func _wait_for_damaged_chicken() -> void:
	for _frame in range(600):
		await process_frame
		var stage := _chicken_stage()
		if stage == null:
			continue
		for raw_actor in stage.get("chickens") as Array:
			var actor := raw_actor as Dictionary
			if float(actor.get("hp", 0.0)) > 0.0 and float(actor.get("hp", 0.0)) < float(actor.get("max_hp", 0.0)):
				return


func _wait_for_werewolf_transform() -> void:
	for _frame in range(600):
		await process_frame
		var stage := _chicken_stage()
		if stage == null:
			continue
		for raw_actor in stage.get("chickens") as Array:
			var actor := raw_actor as Dictionary
			var transform_timer := float(actor.get("transform_timer", 0.0))
			if bool(actor.get("werewolf_transformed", false)) and transform_timer > 0.25 and transform_timer < 0.55:
				return
	_fail("natural Werewolf transformation was not reached")


func _show_werewolf_scratch() -> void:
	var stage := _chicken_stage()
	if stage == null:
		_fail("Werewolf claw stage was missing")
		return
	stage.set_process(false)
	var actors := stage.get("chickens") as Array
	if actors.is_empty():
		stage.call("_spawn_chicken", 0)
		actors = stage.get("chickens") as Array
	var actor := actors[0] as Dictionary
	var hero_position := stage.get("hero_pos") as Vector2
	actor["werewolf_transformed"] = true
	actor["transform_timer"] = 0.0
	actor["attack_phase"] = "strike"
	actor["signature_t"] = 0.62
	actor["attack_timer"] = 0.18
	actor["roll_dir"] = Vector2.LEFT
	actor["face_right"] = false
	actor["pos"] = hero_position + Vector2(0.12, 0.01)
	actor["render_pos"] = actor["pos"]
	actor["render_sim_pos"] = actor["pos"]
	actor["damage"] = float(stage.call("_hero_max_hp"))
	stage.set("hero_hp", float(stage.call("_hero_max_hp")))
	stage.set("hero_hurt_cooldown", 0.0)
	stage.call("_apply_enemy_contact_damage", actor)
	var effects := stage.get("active_effects") as Array
	if effects.is_empty():
		_fail("Werewolf claw effect was not queued")
		return
	(effects[-1] as Dictionary)["life"] = 0.07
	stage.queue_redraw()
	await process_frame


func _show_wave_ready() -> void:
	var stage := _chicken_stage()
	if stage == null:
		_fail("Wave-ready stage was missing")
		return
	stage.set_process(false)
	stage.set("wave_index", 0)
	stage.set("wave_spawn_total", 2)
	stage.set("wave_spawned_count", 2)
	stage.set("wave_spawn_remaining", 0)
	var spawn_duration := float(stage.call("_wave_spawn_phase_duration_for_current_wave"))
	var wave_duration := spawn_duration + float(stage.call("_wave_rest_duration_for_wave"))
	stage.set("wave_spawn_phase_duration_current", spawn_duration)
	stage.set("wave_duration_current", wave_duration)
	stage.set("wave_elapsed_current", spawn_duration + 1.0)
	stage.set("displayed_wave_progress", (spawn_duration + 1.0) / wave_duration)
	stage.queue_redraw()
	await process_frame


func _show_goblin_hit() -> void:
	var stage := _chicken_stage()
	if stage == null:
		_fail("Goblin-hit stage was missing")
		return
	stage.set_process(false)
	var actors := stage.get("chickens") as Array
	if actors.is_empty():
		stage.call("_spawn_chicken", 0)
		actors = stage.get("chickens") as Array
	var actor := actors[0] as Dictionary
	var hero_position := stage.get("hero_pos") as Vector2
	actor["attack_phase"] = "strike"
	actor["attack_timer"] = 0.08
	actor["roll_dir"] = Vector2.LEFT
	actor["face_right"] = false
	actor["pos"] = hero_position + Vector2(0.12, 0.01)
	actor["render_pos"] = actor["pos"]
	actor["render_sim_pos"] = actor["pos"]
	actor["damage"] = 14.0
	stage.set("hero_hp", float(stage.call("_hero_max_hp")))
	stage.set("hero_hurt_cooldown", 0.0)
	stage.call("_apply_enemy_contact_damage", actor)
	stage.queue_redraw()
	await process_frame


func _wait_for_guys_flee() -> void:
	for _frame in range(900):
		await process_frame
		var stage := _chicken_stage()
		if stage == null:
			continue
		for raw_actor in stage.get("chickens") as Array:
			if float((raw_actor as Dictionary).get("punch_flee_timer", 0.0)) > 0.0:
				for _settle_frame in range(12):
					await process_frame
				return
	_fail("natural Guys punch near-miss was not reached")


func _show_defeated_variants(dead_timer := 0.01, knock_directions: Array = []) -> void:
	var stage := _chicken_stage()
	if stage == null:
		_fail("chicken stage was missing for defeated-state capture")
		return
	stage.set_process(false)
	var actors := stage.get("chickens") as Array
	while actors.size() < 3:
		stage.call("_spawn_chicken", actors.size())
		actors = stage.get("chickens") as Array
	actors.resize(3)
	var variants := ["white", "gray", "black"]
	var positions := [Vector2(0.27, 0.36), Vector2(0.73, 0.36), Vector2(0.50, 0.72)]
	for index in range(actors.size()):
		var actor := actors[index] as Dictionary
		actor["variant"] = variants[index]
		actor["pos"] = positions[index]
		actor["hp"] = 0.0
		actor["max_hp"] = maxf(1.0, float(actor.get("max_hp", 1.0)))
		actor["dead_timer"] = dead_timer
		actor["attack_phase"] = ""
		actor["hit_flash"] = 0.0
		actor["uppercut_pop"] = 0.0
		actor["face_right"] = true
		if index < knock_directions.size():
			actor["uppercut_knock_dir"] = knock_directions[index]
			actor["death_bounce_scale"] = 1.0
		actors[index] = actor
	stage.set("chickens", actors)
	stage.queue_redraw()
	for _frame in range(3):
		await process_frame


func _show_crowded_chickens() -> void:
	var stage := _chicken_stage()
	if stage == null:
		_fail("chicken stage was missing for crowd capture")
		return
	stage.set_process(false)
	var actors := stage.get("chickens") as Array
	while actors.size() < 7:
		stage.call("_spawn_chicken", actors.size())
		actors = stage.get("chickens") as Array
	actors.resize(7)
	for index in range(actors.size()):
		var actor := actors[index] as Dictionary
		actor["variant"] = ["white", "gray", "black"][index % 3]
		actor["pos"] = stage.get("hero_pos")
		actor["hp"] = float(actor.get("max_hp", 1.0))
		actor["dead_timer"] = 0.0
		actor["attack_phase"] = ""
		actors[index] = actor
	var defeated := actors[6] as Dictionary
	defeated["hp"] = 0.0
	defeated["dead_timer"] = 0.01
	defeated["pos"] = (stage.get("hero_pos") as Vector2) + Vector2(0.24, 0.02)
	actors[6] = defeated
	stage.set("chickens", actors)
	stage.queue_redraw()
	for _frame in range(3):
		await process_frame


func _show_goblin_shield_drop() -> void:
	var stage := _chicken_stage()
	if stage == null:
		_fail("fight stage was missing for shield-drop capture")
		return
	stage.set_process(false)
	var actors := stage.get("chickens") as Array
	while actors.is_empty():
		stage.call("_spawn_chicken", actors.size())
		actors = stage.get("chickens") as Array
	actors.resize(1)
	var actor := actors[0] as Dictionary
	actor["pos"] = Vector2(0.38, 0.58)
	actor["hp"] = float(actor.get("max_hp", 1.0))
	actor["shield_up"] = false
	actor["shield_fall_timer"] = 1.05
	actor["shield_fall_direction"] = Vector2(0.42, 1.0).normalized()
	actor["shield_fall_rotation"] = 1.9
	actor["shield_drop_pos"] = Vector2(0.52, 0.52)
	actor["shield_drop_face_right"] = true
	actor["attack_phase"] = ""
	actor["hit_flash"] = 0.0
	actors[0] = actor
	stage.set("chickens", actors)
	stage.queue_redraw()
	for _frame in range(3):
		await process_frame


func _show_goblin_punch_stack() -> void:
	var stage := _chicken_stage()
	if stage == null:
		_fail("fight stage was missing for Goblin punch-stack capture")
		return
	stage.set_process(false)
	stage.set("hero_pos", Vector2(0.50, 0.55))
	stage.set("hero_uppercut_cd", 999.0)
	var actors := stage.get("chickens") as Array
	while actors.size() < 4:
		stage.call("_spawn_chicken", actors.size())
		actors = stage.get("chickens") as Array
	actors.resize(4)
	var positions := [Vector2(0.62, 0.52), Vector2(0.63, 0.60), Vector2(0.85, 0.30), Vector2(0.36, 0.55)]
	for index in range(actors.size()):
		var actor := actors[index] as Dictionary
		actor["pos"] = positions[index]
		actor["render_pos"] = positions[index]
		actor["hp"] = 1000.0
		actor["max_hp"] = 1000.0
		actor["shield_up"] = false
		actor["dead_timer"] = 0.0
		actor["hit_flash"] = 0.0
		actor["attack_phase"] = ""
		actors[index] = actor
	stage.set("chickens", actors)
	if not bool(stage.call("_start_hero_attack")):
		_fail("Goblin punch-stack capture did not land")
		return
	stage.queue_redraw()
	for _frame in range(3):
		await process_frame


func _show_attack_frame_three() -> void:
	var stage := _chicken_stage()
	if stage == null:
		_fail("fight stage was missing for attack-frame capture")
		return
	stage.set_process(false)
	var actors := stage.get("chickens") as Array
	while actors.is_empty():
		stage.call("_spawn_chicken", actors.size())
		actors = stage.get("chickens") as Array
	actors.resize(1)
	var actor := actors[0] as Dictionary
	actor["pos"] = Vector2(0.38, 0.58)
	actor["render_pos"] = actor["pos"]
	actor["hp"] = float(actor.get("max_hp", 1.0))
	actor["attack_phase"] = "strike"
	actor["signature_t"] = 0.5
	actor["hit_flash"] = 0.0
	actor["stagger_timer"] = 0.0
	actor["uppercut_pop"] = 0.0
	actor["uppercut_knock_timer"] = 0.0
	actor["lunge_timer"] = 0.0
	actors[0] = actor
	stage.set("chickens", actors)
	stage.queue_redraw()
	for _frame in range(3):
		await process_frame


func _show_death_power_comparison() -> void:
	var stage := _chicken_stage()
	if stage == null:
		_fail("chicken stage was missing for death-force comparison")
		return
	stage.set_process(false)
	var actors := stage.get("chickens") as Array
	while actors.size() < 2:
		stage.call("_spawn_chicken", actors.size())
		actors = stage.get("chickens") as Array
	actors.resize(2)
	for index in range(actors.size()):
		var actor := actors[index] as Dictionary
		actor["variant"] = "gray" if index == 0 else "black"
		actor["pos"] = Vector2(0.36 if index == 0 else 0.64, 0.68)
		actor["hp"] = 0.0
		actor["dead_timer"] = 0.19
		actor["death_bounce_scale"] = 1.0 / 3.0 if index == 0 else 1.0
		actor["attack_phase"] = ""
		actor["hit_flash"] = 0.0
		actor["uppercut_pop"] = 0.0
		actor["uppercut_knock_timer"] = 0.0
		actor["face_right"] = true
		actors[index] = actor
	stage.set("chickens", actors)
	stage.queue_redraw()
	for _frame in range(3):
		await process_frame


func _show_variant_attack_frames() -> void:
	var stage := _chicken_stage()
	if stage == null:
		_fail("chicken stage was missing for variant-attack capture")
		return
	stage.set_process(false)
	var actors := stage.get("chickens") as Array
	while actors.size() < 8:
		stage.call("_spawn_chicken", actors.size())
		actors = stage.get("chickens") as Array
	actors.resize(8)
	var positions := [
		Vector2(0.20, 0.34), Vector2(0.60, 0.34), Vector2(0.20, 0.72), Vector2(0.60, 0.72),
		Vector2(0.40, 0.34), Vector2(0.80, 0.34), Vector2(0.40, 0.72), Vector2(0.80, 0.72),
	]
	var phases := ["windup", "windup", "strike", "recovery"]
	var signatures := [0.25, 0.75, 0.50, 0.50]
	for index in range(actors.size()):
		var actor := actors[index] as Dictionary
		actor["variant"] = "gray" if index < 4 else "black"
		actor["pos"] = positions[index]
		actor["hp"] = float(actor.get("max_hp", 1.0))
		actor["dead_timer"] = 0.0
		actor["attack_phase"] = phases[index % 4]
		actor["signature_t"] = signatures[index % 4]
		if str(stage.get("enemy_id")) == "cave-trolls":
			actor["cave_troll_attack_kind"] = "club" if index < 4 else "pound"
		actor["hit_flash"] = 0.0
		actor["stagger_timer"] = 0.0
		actor["uppercut_pop"] = 0.0
		actor["uppercut_knock_timer"] = 0.0
		actor["lunge_timer"] = 0.0
		actor["face_right"] = true
		actors[index] = actor
	stage.set("chickens", actors)
	stage.queue_redraw()
	for _frame in range(3):
		await process_frame


func _show_variant_state_frames() -> void:
	var stage := _chicken_stage()
	if stage == null:
		_fail("chicken stage was missing for variant-state capture")
		return
	stage.set_process(false)
	var actors := stage.get("chickens") as Array
	while actors.size() < 6:
		stage.call("_spawn_chicken", actors.size())
		actors = stage.get("chickens") as Array
	actors.resize(6)
	var positions := [
		Vector2(0.34, 0.36), Vector2(0.50, 0.36), Vector2(0.66, 0.36),
		Vector2(0.34, 0.76), Vector2(0.50, 0.76), Vector2(0.66, 0.76),
	]
	for index in range(actors.size()):
		var actor := actors[index] as Dictionary
		var state := index % 3
		actor["variant"] = "gray" if index < 3 else "black"
		actor["pos"] = positions[index]
		actor["hp"] = 0.0 if state == 2 else float(actor.get("max_hp", 1.0))
		actor["dead_timer"] = 0.80 if state == 2 else 0.0
		actor["attack_phase"] = "stagger" if state == 1 else ""
		actor["hit_flash"] = 0.25 if state == 0 else 0.0
		actor["stagger_timer"] = 1.0 if state == 1 else 0.0
		actor["uppercut_pop"] = 0.0
		actor["uppercut_knock_timer"] = 0.0
		actor["lunge_timer"] = 0.0
		actor["face_right"] = true
		actors[index] = actor
	stage.set("chickens", actors)
	stage.queue_redraw()
	for _frame in range(3):
		await process_frame


func _show_low_hp_state() -> void:
	var stage := _chicken_stage()
	if stage == null:
		_fail("chicken stage was missing for low-HP capture")
		return
	stage.set_process(false)
	stage.set("hero_hp", float(stage.call("_hero_max_hp")) * 0.1)
	stage.queue_redraw()
	for _frame in range(3):
		await process_frame


func _show_hero_pose(attack_timer: float, uppercut: bool) -> void:
	var stage := _chicken_stage()
	if stage == null:
		_fail("chicken stage was missing for hero-pose capture")
		return
	stage.set_process(false)
	stage.set("chickens", [])
	stage.set("hero_pos", Vector2(0.50, 0.56))
	stage.set("hero_ko_timer", 0.0)
	stage.set("hero_flip_timer", 0.0)
	stage.set("hero_facing", 1)
	stage.set("hero_attack_dir", Vector2.RIGHT)
	stage.set("hero_attack_is_uppercut", uppercut)
	stage.set("hero_attack_timer", attack_timer)
	stage.queue_redraw()
	for _frame in range(3):
		await process_frame


func _show_giant_walk() -> void:
	var stage := _chicken_stage()
	if stage == null:
		_fail("fight stage was missing for Giant walk capture")
		return
	stage.set_process(false)
	stage.set("elapsed_seconds", 0.0)
	stage.set("hero_pos", Vector2(0.50, 0.78))
	stage.set("chickens", [])
	stage.call("_spawn_chicken", 0)
	var actors := stage.get("chickens") as Array
	var source := actors[0] as Dictionary
	actors.clear()
	var positions := [Vector2(0.28, 0.57), Vector2(0.50, 0.57), Vector2(0.72, 0.57)]
	var frame_ids := [6, 17, 19]
	for index in range(positions.size()):
		var giant := source.duplicate(true)
		giant["id"] = frame_ids[index]
		giant["pos"] = positions[index]
		giant["render_pos"] = positions[index]
		giant["hp"] = maxf(1.0, float(giant.get("max_hp", 1.0)))
		giant["dead_timer"] = 0.0
		giant["ko_retreat_alpha"] = 1.0
		giant["attack_phase"] = ""
		giant["hit_flash"] = 0.0
		giant["stagger_timer"] = 0.0
		giant["knock_timer"] = 0.0
		giant["uppercut_pop"] = 0.0
		giant["face_right"] = true
		actors.append(giant)
	stage.set("chickens", actors)
	stage.queue_redraw()
	for _frame in range(3):
		await process_frame


func _show_giant_toss() -> void:
	var stage := _chicken_stage()
	if stage == null:
		_fail("fight stage was missing for Giant toss capture")
		return
	stage.set_process(false)
	stage.set("hero_pos", Vector2(0.50, 0.55))
	var actors := stage.get("chickens") as Array
	while actors.is_empty():
		stage.call("_spawn_chicken", 0)
		actors = stage.get("chickens") as Array
	var giant := actors[0] as Dictionary
	giant["pos"] = Vector2(0.30, 0.55)
	giant["attack_phase"] = "windup"
	giant["attack_timer"] = 0.70
	giant["attack_duration"] = 0.70
	giant["giant_attack_kind"] = "toss"
	giant["face_right"] = true
	giant["grabbed_hero"] = false
	stage.call("_step_chicken", giant, 0.58)
	giant["render_pos"] = giant["pos"]
	giant["attack_phase"] = "strike"
	giant["signature_t"] = 0.52
	actors = [giant]
	stage.set("chickens", actors)
	stage.queue_redraw()
	for _frame in range(3):
		await process_frame


func _show_giant_pair() -> void:
	var stage := _chicken_stage()
	if stage == null:
		_fail("fight stage was missing for Giant pair capture")
		return
	stage.set_process(false)
	var actors := stage.get("chickens") as Array
	actors.clear()
	stage.set("wave_index", 2)
	while actors.size() < 2:
		stage.call("_spawn_chicken", actors.size())
		actors = stage.get("chickens") as Array
	actors.resize(2)
	var positions := [Vector2(0.34, 0.55), Vector2(0.66, 0.55)]
	for index in range(2):
		var giant := actors[index] as Dictionary
		giant["pos"] = positions[index]
		giant["render_pos"] = positions[index]
		giant["hp"] = float(giant.get("max_hp", 1.0))
		giant["attack_phase"] = ""
		giant["face_right"] = index == 0
		actors[index] = giant
	stage.set("chickens", actors)
	stage.queue_redraw()
	for _frame in range(3):
		await process_frame


func _show_giant_stomp() -> void:
	var stage := _chicken_stage()
	if stage == null:
		_fail("fight stage was missing for Giant stomp capture")
		return
	stage.set_process(false)
	stage.set("hero_pos", Vector2(0.52, 0.55))
	var actors := stage.get("chickens") as Array
	while actors.is_empty():
		stage.call("_spawn_chicken", 0)
		actors = stage.get("chickens") as Array
	var giant := actors[0] as Dictionary
	giant["pos"] = Vector2(0.32, 0.55)
	giant["render_pos"] = giant["pos"]
	giant["roll_dir"] = Vector2.RIGHT
	giant["attack_phase"] = "strike"
	giant["signature_t"] = 0.10
	giant["giant_attack_kind"] = "stomp"
	giant["slam_impacted"] = false
	giant["attack_damage_done"] = false
	actors = [giant]
	stage.set("chickens", actors)
	stage.call("_step_enemy_strike", giant, giant["pos"] as Vector2, Vector2.RIGHT, 0.016)
	stage.call("_step_hero_bump", 0.17)
	stage.call("_step_visual_fx", 0.16)
	stage.queue_redraw()
	for _frame in range(3):
		await process_frame


func _show_giant_boulder() -> void:
	var stage := _chicken_stage()
	if stage == null:
		_fail("fight stage was missing for Giant boulder capture")
		return
	stage.set_process(false)
	stage.set("hero_pos", Vector2(0.50, 0.55))
	stage.set("hero_attack_cd", 999.0)
	stage.call("_reset_giant_boulders")
	var actors := stage.get("chickens") as Array
	while actors.is_empty():
		stage.call("_spawn_chicken", 0)
		actors = stage.get("chickens") as Array
	var giant := actors[0] as Dictionary
	giant["pos"] = Vector2(0.27, 0.55)
	giant["render_pos"] = giant["pos"]
	giant["face_right"] = true
	giant["attack_phase"] = "strike"
	giant["giant_attack_kind"] = "boulder"
	giant["giant_boulder_index"] = 0
	giant["signature_t"] = 0.38
	actors = [giant]
	stage.set("chickens", actors)
	var boulders := stage.get("giant_boulders") as Array
	var boulder := boulders[0] as Dictionary
	boulder["state"] = "held"
	boulder["owner_id"] = int(giant.get("id", -1))
	boulders[0] = boulder
	stage.set("giant_boulders", boulders)
	stage.call("_throw_giant_boulder", giant)
	stage.call("_step_giant_boulders", 0.34)
	stage.queue_redraw()
	for _frame in range(3):
		await process_frame


func _show_giant_boulder_break() -> void:
	var stage := _chicken_stage()
	if stage == null:
		_fail("fight stage was missing for Giant boulder break capture")
		return
	stage.set_process(false)
	stage.set("hero_pos", Vector2(0.58, 0.70))
	stage.call("_reset_giant_boulders")
	var actors := stage.get("chickens") as Array
	while actors.is_empty():
		stage.call("_spawn_chicken", 0)
		actors = stage.get("chickens") as Array
	var giant := actors[0] as Dictionary
	giant["pos"] = Vector2(0.34, 0.53)
	giant["render_pos"] = giant["pos"]
	giant["render_sim_pos"] = giant["pos"]
	giant["attack_phase"] = "windup"
	giant["signature_t"] = 0.62
	giant["giant_attack_kind"] = "boulder"
	giant["giant_boulder_index"] = 0
	giant["face_right"] = true
	stage.set("chickens", [giant])
	var boulders := stage.get("giant_boulders") as Array
	var boulder := boulders[0] as Dictionary
	boulder["state"] = "held"
	boulder["owner_id"] = int(giant.get("id", -1))
	boulders[0] = boulder
	stage.set("giant_boulders", boulders)
	var held_center := stage.call("_held_giant_boulder_center", boulder) as Vector2
	var tap_position := stage.get_global_transform_with_canvas() * held_center
	var tap_down := InputEventScreenTouch.new()
	tap_down.index = 71
	tap_down.position = tap_position
	tap_down.pressed = true
	scene.call("_input", tap_down)
	var tap_up := InputEventScreenTouch.new()
	tap_up.index = 71
	tap_up.position = tap_position
	tap_up.pressed = false
	scene.call("_input", tap_up)
	if str(scene.get("running_action_id")) != action_id:
		_fail("Giant boulder tap stopped the active fight")
		return
	boulder = (stage.get("giant_boulders") as Array)[0] as Dictionary
	if str(boulder.get("state", "")) != "destroyed":
		_fail("Giant boulder tap did not reach the fight stage")
		return
	stage.call("_step_visual_fx", 0.10)
	stage.queue_redraw()
	for _frame in range(3):
		await process_frame


func _assert_giant_hold_stops_fight() -> bool:
	var stop_hold: Object = scene.call("_action_stop_hold")
	stop_hold.call("begin_action", "fight", action_id, Vector2(540.0, 900.0), 72)
	stop_hold.call("process_action", 0.17)
	stop_hold.call("process_action", 0.46)
	stop_hold.call("process_action", 0.19)
	if not str(scene.get("running_action_id")).is_empty():
		_fail("Holding the active Giant fight did not stop it")
		return false
	return true


func _show_giant_boulder_drop() -> void:
	var stage := _chicken_stage()
	if stage == null:
		_fail("fight stage was missing for Giant boulder-drop capture")
		return
	stage.set_process(false)
	stage.set("hero_pos", Vector2(0.58, 0.63))
	stage.set("hero_attack_is_uppercut", true)
	stage.set("hero_attack_dir", Vector2.LEFT)
	stage.set("hero_facing", -1)
	stage.set("hero_attack_timer", 0.17)
	stage.call("_reset_giant_boulders")
	var actors := stage.get("chickens") as Array
	while actors.is_empty():
		stage.call("_spawn_chicken", 0)
		actors = stage.get("chickens") as Array
	var giant := actors[0] as Dictionary
	giant["pos"] = Vector2(0.38, 0.53)
	giant["render_pos"] = giant["pos"]
	giant["render_sim_pos"] = giant["pos"]
	giant["face_right"] = true
	giant["attack_phase"] = "strike"
	giant["giant_attack_kind"] = "boulder"
	giant["giant_boulder_index"] = 0
	giant["interrupt_protected"] = true
	giant["uppercut_pop"] = 0.25
	giant["uppercut_knock_timer"] = 0.28
	stage.set("chickens", [giant])
	var boulders := stage.get("giant_boulders") as Array
	var boulder := boulders[0] as Dictionary
	boulder["state"] = "held"
	boulder["owner_id"] = int(giant.get("id", -1))
	boulders[0] = boulder
	stage.set("giant_boulders", boulders)
	stage.call("_stagger_enemy", giant, true)
	stage.queue_redraw()
	for _frame in range(3):
		await process_frame


func _show_giant_progression() -> void:
	var stage := _chicken_stage()
	if stage == null:
		_fail("fight stage was missing for Giant progression capture")
		return
	stage.set_process(false)
	seed(99000)
	stage.call("set_active_fight", false)
	stage.set("elapsed_seconds", 0.0)
	stage.call("set_active_fight", true)
	for _frame in range(20000):
		stage.set("elapsed_seconds", float(stage.get("elapsed_seconds")) + 0.05)
		stage.call("_step_visual_fx", 0.05)
		var frozen := float(stage.get("hit_stop_timer")) > 0.0
		stage.set("hit_stop_timer", maxf(0.0, float(stage.get("hit_stop_timer")) - 0.05))
		stage.call("_step_fight", 0.0 if frozen else 0.05)
		if int(stage.get("wave_index")) >= 4 or float(stage.get("hero_ko_timer")) > 0.0:
			break
	if int(stage.get("wave_index")) < 4:
		_fail("level-99 Giant capture did not reach wave 5")
		return
	stage.queue_redraw()
	for _frame in range(3):
		await process_frame


func _show_giant_layer() -> void:
	var stage := _chicken_stage()
	if stage == null:
		_fail("fight stage was missing for Giant layer capture")
		return
	stage.set_process(false)
	stage.set("hero_pos", Vector2(0.50, 0.72))
	stage.call("_reset_giant_boulders")
	var actors := stage.get("chickens") as Array
	while actors.is_empty():
		stage.call("_spawn_chicken", 0)
		actors = stage.get("chickens") as Array
	var giant := actors[0] as Dictionary
	giant["pos"] = Vector2(0.50, 0.10)
	giant["render_pos"] = giant["pos"]
	giant["render_sim_pos"] = giant["pos"]
	giant["attack_phase"] = ""
	giant["hit_flash"] = 0.0
	giant["stagger_timer"] = 0.0
	giant["uppercut_pop"] = 0.0
	giant["face_right"] = true
	stage.set("chickens", [giant])
	stage.queue_redraw()
	for _frame in range(3):
		await process_frame


func _show_vampire_specials() -> void:
	var stage := _chicken_stage()
	if stage == null:
		_fail("fight stage was missing for Vampire specials capture")
		return
	stage.set_process(false)
	stage.set("hero_pos", Vector2(0.52, 0.57))
	stage.set("hero_hp", float(stage.call("_hero_max_hp")))
	stage.set("hero_hurt_cooldown", 0.0)
	stage.set("vampire_bats", [])
	stage.set("smoke_puffs", [])
	stage.set("chickens", [])
	stage.call("_spawn_chicken", 0)
	var actors := stage.get("chickens") as Array
	var summoner := (actors[0] as Dictionary).duplicate(true)
	summoner["pos"] = Vector2(0.37, 0.47)
	summoner["render_pos"] = summoner["pos"]
	summoner["render_sim_pos"] = summoner["pos"]
	summoner["attack_phase"] = "strike"
	summoner["signature_t"] = 0.30
	summoner["vampire_attack_kind"] = "shockwave"
	summoner["effect_fired"] = true
	summoner["face_right"] = true
	summoner["hit_flash"] = 0.0
	summoner["stagger_timer"] = 0.0
	stage.set("chickens", [summoner])
	stage.call("_spawn_vampire_bats", summoner)
	var bats := stage.get("vampire_bats") as Array
	for i in range(bats.size()):
		var bat := bats[i] as Dictionary
		bat["pos"] = [Vector2(0.40, 0.43), Vector2(0.43, 0.51), Vector2(0.76, 0.43), Vector2(0.80, 0.51)][i]
		bats[i] = bat
	stage.set("vampire_bats", bats)
	stage.call("_spawn_vampire_shockwave", summoner)
	stage.call("_step_vampire_shockwaves", 0.80)
	bats = stage.get("vampire_bats") as Array
	for i in range(bats.size()):
		var bat := bats[i] as Dictionary
		bat["pos"] = Vector2(0.40, 0.46) if i == 0 else Vector2(0.80 + float(i) * 0.02, 0.46)
		bats[i] = bat
	stage.set("vampire_bats", bats)
	stage.set("vampire_shockwaves", [])
	stage.call("_spawn_vampire_shockwave", summoner)
	stage.call("_step_vampire_shockwaves", 0.80)
	bats = stage.get("vampire_bats") as Array
	for i in range(bats.size()):
		var bat := bats[i] as Dictionary
		bat["pos"] = (stage.get("hero_pos") as Vector2) + Vector2.from_angle(float(i) * TAU / float(bats.size())) * 0.18
		bats[i] = bat
	stage.set("vampire_bats", bats)
	stage.call("_update_floaters")
	stage.queue_redraw()
	for _frame in range(3):
		await process_frame


func _show_vampire_giant() -> void:
	var stage := _chicken_stage()
	if stage == null:
		_fail("fight stage was missing for Vampire giant capture")
		return
	stage.set_process(false)
	stage.set("hero_pos", Vector2(0.70, 0.60))
	var actors := stage.get("chickens") as Array
	if actors.is_empty():
		stage.call("_spawn_chicken", 0)
		actors = stage.get("chickens") as Array
	actors.resize(1)
	var giant := actors[0] as Dictionary
	giant["pos"] = Vector2(0.34, 0.55)
	giant["render_pos"] = giant["pos"]
	giant["render_sim_pos"] = giant["pos"]
	giant["vampire_giant_transformed"] = true
	giant["vampire_giant_buff_count"] = 1
	giant["transform_timer"] = 0.0
	giant["attack_phase"] = "strike"
	giant["vampire_attack_kind"] = "wing"
	giant["signature_t"] = 0.64
	giant["hit_flash"] = 0.0
	giant["stagger_timer"] = 0.0
	giant["face_right"] = true
	actors[0] = giant
	stage.set("chickens", actors)
	stage.queue_redraw()
	for _frame in range(3):
		await process_frame


func _show_cave_troll_pound() -> void:
	var stage := _chicken_stage()
	if stage == null:
		_fail("fight stage was missing for Cave Troll Pound capture")
		return
	stage.set_process(false)
	stage.set("hero_pos", Vector2(0.52, 0.55))
	var actors := stage.get("chickens") as Array
	while actors.is_empty():
		stage.call("_spawn_chicken", 0)
		actors = stage.get("chickens") as Array
	var troll := actors[0] as Dictionary
	troll["pos"] = Vector2(0.32, 0.55)
	troll["render_pos"] = troll["pos"]
	troll["roll_dir"] = Vector2.RIGHT
	troll["attack_phase"] = "strike"
	troll["signature_t"] = 0.70
	troll["cave_troll_attack_kind"] = "pound"
	troll["slam_impacted"] = false
	troll["attack_damage_done"] = false
	troll["face_right"] = true
	actors = [troll]
	stage.set("chickens", actors)
	stage.call("_step_enemy_strike", troll, troll["pos"] as Vector2, Vector2.RIGHT, 0.016)
	stage.call("_step_hero_bump", 0.17)
	stage.call("_step_visual_fx", 0.10)
	stage.queue_redraw()
	for _frame in range(3):
		await process_frame


func _show_dragon_breath() -> void:
	var stage := _chicken_stage()
	if stage == null:
		_fail("fight stage was missing for Dragon Breath capture")
		return
	stage.set_process(false)
	stage.set("hero_pos", Vector2(0.78, 0.55))
	stage.set("active_effects", [])
	var actors := stage.get("chickens") as Array
	while actors.is_empty():
		stage.call("_spawn_chicken", 0)
		actors = stage.get("chickens") as Array
	var dragon := actors[0] as Dictionary
	dragon["pos"] = Vector2(0.30, 0.55)
	dragon["render_pos"] = dragon["pos"]
	dragon["render_sim_pos"] = dragon["pos"]
	dragon["dragon_attack_kind"] = "breath"
	dragon["dragon_breath_aim"] = "straight"
	dragon["breath_dir"] = Vector2.RIGHT
	dragon["attack_phase"] = "strike"
	dragon["signature_t"] = 0.50
	dragon["dragon_breath_beat_timer"] = 0.0
	dragon["dragon_breath_emissions"] = 0
	dragon["attack_damage_done"] = true
	dragon["dragon_cycle_damage_done"] = true
	dragon["face_right"] = true
	stage.set("chickens", [dragon])
	for _beat in range(7):
		stage.call("_step_enemy_strike", dragon, dragon["pos"] as Vector2, Vector2.RIGHT, 0.18)
	stage.call("_step_visual_fx", 0.02)
	stage.queue_redraw()
	for _frame in range(3):
		await process_frame


func _show_dragon_pounce() -> void:
	var stage := _chicken_stage()
	if stage == null:
		_fail("fight stage was missing for Dragon Pounce capture")
		return
	stage.set_process(false)
	stage.set("hero_pos", Vector2(0.58, 0.55))
	stage.set("hero_hp", float(stage.call("_hero_max_hp")))
	stage.set("hero_hurt_cooldown", 0.0)
	stage.set("active_effects", [])
	var actors := stage.get("chickens") as Array
	while actors.is_empty():
		stage.call("_spawn_chicken", 0)
		actors = stage.get("chickens") as Array
	var dragon := actors[0] as Dictionary
	dragon["pos"] = Vector2(0.35, 0.55)
	dragon["render_pos"] = dragon["pos"]
	dragon["render_sim_pos"] = dragon["pos"]
	dragon["dragon_attack_kind"] = "pounce"
	dragon["attack_phase"] = ""
	dragon["slam_impacted"] = false
	dragon["attack_damage_done"] = false
	stage.call("_begin_enemy_attack", dragon, Vector2.RIGHT)
	dragon["attack_phase"] = "strike"
	dragon["signature_t"] = 0.70
	actors = [dragon]
	stage.set("chickens", actors)
	stage.call("_step_enemy_strike", dragon, dragon["pos"] as Vector2, Vector2.RIGHT, 0.016)
	stage.call("_step_hero_toss", 0.50)
	stage.call("_step_visual_fx", 0.08)
	stage.queue_redraw()
	for _frame in range(3):
		await process_frame


func _show_dragon_melee_aim() -> void:
	var stage := _chicken_stage()
	if stage == null:
		_fail("fight stage was missing for Dragon melee aim capture")
		return
	stage.set_process(false)
	stage.set("hero_pos", Vector2(0.50, 0.55))
	var actors := stage.get("chickens") as Array
	while actors.is_empty():
		stage.call("_spawn_chicken", 0)
		actors = stage.get("chickens") as Array
	var dragon := actors[0] as Dictionary
	dragon["pos"] = Vector2(0.50, 0.25)
	dragon["render_pos"] = dragon["pos"]
	dragon["render_sim_pos"] = dragon["pos"]
	dragon["dragon_attack_kind"] = "brawl"
	dragon["attack_phase"] = ""
	dragon["attack_cd"] = 0.0
	stage.set("chickens", [dragon])
	for _step in range(120):
		stage.call("_step_chicken", dragon, 0.05)
		if str(dragon.get("attack_phase", "")).is_empty():
			continue
		break
	dragon["render_pos"] = dragon["pos"]
	dragon["render_sim_pos"] = dragon["pos"]
	dragon["attack_phase"] = "strike"
	dragon["signature_t"] = 0.50
	dragon["attack_damage_done"] = false
	dragon["face_right"] = (stage.get("hero_pos") as Vector2).x > (dragon["pos"] as Vector2).x
	stage.call("_update_dragon_melee_aim", dragon, dragon["pos"])
	stage.queue_redraw()
	for _frame in range(3):
		await process_frame


func _show_dragon_boundary_escape() -> void:
	var stage := _chicken_stage()
	if stage == null:
		_fail("fight stage was missing for Dragon boundary capture")
		return
	stage.set_process(false)
	stage.set("hero_pos", Vector2(0.45, 0.55))
	var actors := stage.get("chickens") as Array
	while actors.is_empty():
		stage.call("_spawn_chicken", 0)
		actors = stage.get("chickens") as Array
	var dragon := actors[0] as Dictionary
	var boundary_pos := stage.call("_clamp_norm_to_arena", Vector2(0.0, 0.25)) as Vector2
	dragon["pos"] = boundary_pos
	dragon["render_pos"] = boundary_pos
	dragon["render_sim_pos"] = boundary_pos
	dragon["dragon_attack_kind"] = "brawl"
	dragon["dragon_brawl_side"] = -1.0
	dragon["attack_phase"] = ""
	dragon["attack_cd"] = 0.0
	stage.set("chickens", [dragon])
	stage.call("_step_chicken", dragon, 0.05)
	if (dragon.get("pos", boundary_pos) as Vector2).distance_squared_to(boundary_pos) <= 0.0000001:
		_fail("Dragon remained trapped at the boundary")
		return
	dragon["render_pos"] = dragon["pos"]
	dragon["render_sim_pos"] = dragon["pos"]
	stage.queue_redraw()
	for _frame in range(3):
		await process_frame


func _show_hero_ko_pose(elapsed_ko: float) -> void:
	var stage := _chicken_stage()
	if stage == null:
		_fail("chicken stage was missing for Blue Guy KO capture")
		return
	stage.set_process(false)
	stage.set("chickens", [])
	stage.set("hero_pos", Vector2(0.50, 0.56))
	stage.set("hero_ko_timer", 3.4 - elapsed_ko)
	stage.set("hero_flip_timer", 0.0)
	stage.set("hero_facing", 1)
	stage.set("hero_attack_timer", 0.0)
	stage.queue_redraw()
	for _frame in range(3):
		await process_frame


func _capture_hero_ko_sequence(capture_path: String) -> void:
	var elapsed_frames := [0.0, 0.15, 0.29, 0.43, 0.57, 0.84]
	var basename := capture_path.get_basename()
	for index in range(elapsed_frames.size()):
		await _show_hero_ko_pose(float(elapsed_frames[index]))
		await RenderingServer.frame_post_draw
		var texture := root.get_texture()
		if texture == null:
			_fail("Blue Guy KO sequence capture texture was missing")
			return
		var image := texture.get_image()
		if image == null or image.is_empty():
			_fail("Blue Guy KO sequence capture image was empty")
			return
		var frame_path := "%s-%02d.png" % [basename, index + 1]
		if image.save_png(frame_path) != OK:
			_fail("could not save Blue Guy KO sequence frame")
			return
	print("chicken-playtest-ko-sequence-ok path=%s frames=%d" % [basename, elapsed_frames.size()])
	quit(0)


func _capture_rouses_roll_sequence(capture_path: String) -> void:
	var stage := _chicken_stage()
	if stage == null:
		_fail("fight stage was missing for R.O.U.S.es roll capture")
		return
	var actors := stage.get("chickens") as Array
	while actors.is_empty():
		stage.call("_spawn_chicken", actors.size())
		actors = stage.get("chickens") as Array
	actors.resize(1)
	var actor := actors[0] as Dictionary
	var origin := Vector2(0.32, 0.55)
	stage.set("hero_pos", Vector2(0.50, 0.55))
	stage.set("hero_attack_cd", 999.0)
	stage.set("hero_uppercut_cd", 999.0)
	stage.set("hero_hurt_cooldown", 999.0)
	stage.set("wave_spawn_remaining", 0)
	stage.set("spawn_timer", 999.0)
	actor["pos"] = origin
	actor["render_pos"] = origin
	actor["render_sim_pos"] = origin
	actor["hp"] = maxf(1.0, float(actor.get("max_hp", 1.0)))
	actor["attack_cd"] = 999.0
	actor["stagger_timer"] = 0.0
	actor["hit_flash"] = 0.0
	stage.call("_begin_enemy_attack", actor, Vector2.RIGHT)
	actor["attack_phase"] = "windup"
	actor["attack_timer"] = 0.42
	actor["attack_duration"] = 0.42
	actors[0] = actor
	stage.set("chickens", actors)
	if not bool(stage.call("_start_hero_attack")) or str(actor.get("attack_phase", "")) != "windup":
		_fail("normal punch interrupted the protected R.O.U.S.es windup")
		return
	stage.set("hero_attack_cd", 999.0)
	var capture_frames := [0, 12, 25, 33, 50, 60, 75, 92]
	var basename := capture_path.get_basename()
	var capture_index := 0
	for frame in range(int(capture_frames[-1]) + 1):
		if frame == int(capture_frames[capture_index]):
			stage.queue_redraw()
			await RenderingServer.frame_post_draw
			var texture := root.get_texture()
			var image: Image = texture.get_image() if texture != null else null
			if image == null or image.is_empty() or image.save_png("%s-%02d.png" % [basename, capture_index + 1]) != OK:
				_fail("could not save R.O.U.S.es roll sequence frame")
				return
			capture_index += 1
			if capture_index >= capture_frames.size():
				break
		await process_frame
	print("chicken-playtest-rouses-roll-sequence-ok path=%s frames=%d" % [basename, capture_frames.size()])
	quit(0)


func _wait_for_knocked_out() -> void:
	for _frame in range(600):
		await process_frame
		var stage := _chicken_stage()
		if stage != null and float(stage.get("hero_ko_timer")) > 0.0:
			for _fall_frame in range(45):
				await process_frame
			return


func _show_ko_retreat() -> void:
	var stage := _chicken_stage()
	if stage == null:
		_fail("chicken stage was missing for KO-retreat capture")
		return
	stage.set_process(false)
	var actors := stage.get("chickens") as Array
	actors.clear()
	for lane in range(3):
		stage.call("_spawn_chicken", lane)
	var positions := [Vector2(0.32, 0.42), Vector2(0.68, 0.42), Vector2(0.50, 0.70)]
	for index in range(actors.size()):
		var actor := actors[index] as Dictionary
		actor["pos"] = positions[index]
		actor["render_pos"] = positions[index]
		actor["render_sim_pos"] = positions[index]
		actor["hp"] = actor.get("max_hp", 1.0)
		actor["werewolf_transformed"] = index != 1
		actor["transform_timer"] = 0.0
	stage.set("hero_hp", 0.0)
	stage.set("hero_ko_timer", 2.4)
	stage.call("_start_enemy_ko_retreats")
	for _retreat_step in range(8):
		stage.call("_step_enemy_ko_retreats", 0.05)
	stage.set("hero_ko_timer", 2.4)
	stage.queue_redraw()
	for _draw_frame in range(5):
		await process_frame


func _show_mega_crit_feedback() -> void:
	var stage := _chicken_stage()
	if stage != null:
		stage.call("set_active_fight", false)
	scene.call("_reward_feedback_surface").call("_clear_action_crit_tweens")
	for _frame in range(3):
		await process_frame
	var key := str(scene.call("_action_key", "fight", action_id))
	var cards := scene.get("action_cards") as Dictionary
	var card := cards.get(key, {}) as Dictionary
	if card.is_empty():
		_fail("%s card was missing for mega-crit capture" % action_id)
		return
	scene.call("_reward_feedback_surface").call("_play_activity_crit_feedback", key, card, true)
	for _frame in range(8):
		await process_frame


func _fail(message: String) -> void:
	push_error("Chicken playtest: %s" % message)
	quit(1)
