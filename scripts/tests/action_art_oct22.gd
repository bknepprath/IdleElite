extends "res://scripts/tests/brian_notes_evening_oct22.gd"

var art_results: Array = []

func _run() -> void:
	if OS.get_environment("IDLE_ELITE_ART_DEMO") != "1":
		create_timer(1500).timeout.connect(func(): quit(1))
	else:
		OS.set_environment("IDLE_ELITE_DESKTOP", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "220")
	AudioServer.set_bus_mute(0, true)
	capture_dir = OS.get_environment("IDLE_ELITE_ART_AUDIT_OUTPUT")
	if capture_dir.is_empty(): capture_dir = "res://outputs/verification/action-art-oct22"
	DirAccess.make_dir_recursive_absolute(capture_dir)
	root.size = Vector2i(1080, 1920)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	for i in range(1600):
		await settle(0.02)
		if game.startup_initialized and not game._boot_warmup_runtime().active: break
	check(game.startup_initialized, "Production main scene boots")
	game._audio_director().music_muted = true
	game._audio_director().sfx_muted = true
	game._audio_director()._apply_audio_bus_volumes()
	AudioServer.set_bus_mute(0, true)
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
	if game._halloween_runtime().greeting_visible():
		await click(Vector2(540,950),true)
		await settle(.3)
	if OS.get_environment("IDLE_ELITE_ART_DEMO") == "1":
		await show_art_desktop_demo()
		return
	if OS.get_environment("IDLE_ELITE_ART_PREVIEW_AUDIT") == "1":
		await audit_art_swipe_preview()
		return
	await audit_action_art()

func audit_action_art() -> void:
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/activity-database.json"))
	var only := OS.get_environment("IDLE_ELITE_ART_AUDIT_ONLY")
	var skill_filter := OS.get_environment("IDLE_ELITE_ART_AUDIT_SKILL")
	var requested_ids := OS.get_environment("IDLE_ELITE_ART_AUDIT_IDS").split(",",false)
	var skills_to_review: Array = source.skills.duplicate()
	if not requested_ids.is_empty(): skills_to_review.reverse()
	for skill in skills_to_review:
		var skill_id := str(skill.id)
		if not skill_filter.is_empty() and skill_filter != skill_id: continue
		if not only.is_empty() and not only.begins_with(skill_id + "/"): continue
		if not requested_ids.is_empty():
			var has_requested_action := false
			for action in skill.actions:
				if str(action.id) in requested_ids: has_requested_action = true; break
			if not has_requested_action: continue
		await open_notes_skill(skill_id)
		for action in skill.actions:
			var id := str(action.id)
			if not requested_ids.is_empty() and id not in requested_ids: continue
			if not only.is_empty() and only != skill_id + "/" + id: continue
			if not bool(action.get("enabled", true)):
				art_results.append({"skill":skill_id,"id":id,"status":"disabled-source-reviewed"})
				continue
			await capture_action_art(skill_id, id, action)
	if only.is_empty():
		var events = game._temporary_event_runtime()
		for definition in events.event_module_defs:
			if not requested_ids.is_empty() and str(definition.id) not in requested_ids: continue
			if not skill_filter.is_empty() and skill_filter != str(definition.page): continue
			var now := int(Time.get_unix_time_from_system())
			events.temporary_event_active.clear()
			events.temporary_event_active[str(definition.id)] = events._temporary_event_spawn_entry(definition,now,now)
			events._mark_temporary_event_state_changed("action art audit fixture")
			await open_notes_skill(str(definition.page))
			await capture_action_art(str(definition.page),str(definition.id),definition)
	var expected := 1 if not only.is_empty() else 178
	if not skill_filter.is_empty():
		expected = 0
		for skill in source.skills:
			if str(skill.id) == skill_filter: expected += skill.actions.size()
		for event in source.event_modules:
			if str(event.page) == skill_filter: expected += 1
	if not requested_ids.is_empty(): expected = requested_ids.size()
	check(art_results.size() == expected, "Every requested action is accounted for")
	var suffix := "-" + skill_filter if not skill_filter.is_empty() else ""
	if not requested_ids.is_empty(): suffix = "-clearance"
	var output := FileAccess.open(capture_dir + "/manifest" + suffix + ".json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"viewport":[1080,1920],"actions":art_results,"failures":failures},"  "))
	print("ACTION_ART_AUDIT failures=",JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func capture_action_art(skill_id: String, id: String, source: Dictionary) -> void:
	var label := skill_id + "--" + id
	if skill_id == "fishing" and not game._fishing_ui_surface().render_area_module_for_action(skill_id, id).is_empty():
		await show_location(id, "")
		await capture(label)
		art_results.append({"skill":skill_id,"id":id,"file":label+".png","renderer":"fishing-location"})
		return
	var card := await notes_card(id)
	if card.is_empty():
		art_results.append({"skill":skill_id,"id":id,"status":"missing-card"})
		return
	await align_notes_card(card)
	var art: Control = card.get("art")
	var panel: Control = card.get("art_panel")
	var result := {"skill":skill_id,"id":id,"file":label+".png","framing":source.get("art_framing",{}),"renderer":"special-stage"}
	if is_instance_valid(art) and art.is_visible_in_tree():
		result.renderer = "portrait"
		result.art_rect = [art.global_position.x,art.global_position.y,art.size.x,art.size.y]
		if is_instance_valid(panel):
			check(panel.get_global_rect().grow(0.1).encloses(art.get_global_rect()), "Art stays inside portrait: " + label)
		if "framing_zoom" in art:
			check(is_equal_approx(art.framing_zoom,float(source.get("art_framing",{}).get("zoom",1.0))), "Authored zoom reaches production: " + label)
			check(art.use_mask_material, "Portrait is masked: " + label)
	await capture(label)
	if source.has("art_animation"):
		await click((panel as Control).get_global_rect().get_center(),true)
		await settle(0.12)
		await capture(label + "--transition")
		await settle(0.5)
		await capture(label + "--settled")
		game._action_runtime()._stop_running_action(skill_id,id)
		await settle(0.1)
	art_results.append(result)
	print("ART_CAPTURE ",label," ",result.renderer)

func show_art_desktop_demo() -> void:
	var skill := OS.get_environment("IDLE_ELITE_ART_DEMO_SKILL")
	var id := OS.get_environment("IDLE_ELITE_ART_DEMO_ACTION")
	if skill.is_empty(): skill = "fight"
	if id.is_empty(): id = "kick-mud-off-boot"
	await open_notes_skill(skill)
	var card := await notes_card(id)
	await align_notes_card(card)
	await capture(id + "-final-portrait")
	root.size = Vector2i(1920,1080)
	await settle(3)
	await game._skill_detail_surface()._scroll_to_activity_card(id,false,true)
	await settle(1.0)
	await capture_demo(id + "-final-desktop")
	print("ACTION_ART_DEMO_READY failures=",JSON.stringify(failures))

func audit_art_swipe_preview() -> void:
	await open_notes_skill("fight")
	await align_notes_card(await notes_card("kick-mud-off-boot"))
	await capture("art-swipe-before")
	var down := InputEventScreenTouch.new()
	down.position = Vector2(1020,900)
	down.pressed = true
	root.push_input(down,true)
	await process_frame
	for index in range(1,21):
		var drag := InputEventScreenDrag.new()
		drag.position = Vector2(1020-index*50,900)
		drag.relative = Vector2(-50,0)
		drag.velocity = Vector2(-1200,0)
		root.push_input(drag,true)
		await process_frame
	for index in range(20): await process_frame
	await capture("art-swipe-transition")
	var surface = game._skill_swipe_activity_surface()
	check(surface.skill_swipe_tracking, "Real swipe remains held for preview inspection")
	var preview_art_count := 0
	# Production light previews mount real cached cards outside action_cards.
	# Inspect the attached incoming page hierarchy that the screenshot shows.
	for node in surface.skill_swipe_frame.find_children("*","",true,false):
		if not node is TextureRect or not "framing_zoom" in node: continue
		var art := node as Control
		if not art.is_visible_in_tree() or not art.get_global_rect().intersects(Rect2(0,408,1080,1190)): continue
		preview_art_count += 1
		check(art.use_mask_material,"Visible swipe art retains mask")
		check((art.get_parent() as Control).get_global_rect().grow(0.1).encloses(art.get_global_rect()),"Visible swipe art stays in its portrait")
	check(preview_art_count > 0,"Actual swipe exposes production preview portraits")
	var up := InputEventScreenTouch.new()
	up.position = Vector2(20,900)
	root.push_input(up,true)
	await settle(3)
	await capture("art-swipe-settled")
	check(game.selected_skill_id != "fight","Actual swipe reaches neighbouring skill")
	print("ART_PREVIEW_AUDIT visible_preview_art=",preview_art_count," failures=",JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
