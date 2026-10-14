extends "res://scripts/tests/wisdom_feedback.gd"

func _run() -> void:
	create_timer(285).timeout.connect(func(): quit(1))
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	capture_dir = "res://.codex-tmp/activity-title-spacing"
	DirAccess.make_dir_recursive_absolute(capture_dir)
	root.size = Vector2i(1080, 1920)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	for i in range(1600):
		await settle(0.02)
		if game.startup_initialized and not game._boot_warmup_runtime().active:
			break
	check(game.startup_initialized, "Real main scene boots")
	game._audio_director().music_muted = true
	game._audio_director().sfx_muted = true
	game._audio_director()._apply_audio_bus_volumes()
	game._test_state_runtime()._apply_art_review_test_unlock_all_state()
	game._test_state_runtime()._clear_activity_unlock_ceremony_test_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	game._save_runtime().fishing_help_seen = true
	game._action_runtime().activity_start_count = 10
	AchievementState.mark_completed_seen_ids(AchievementState.milestones(game, false), game._save_runtime().achievement_toast_seen_ids, [])
	game._achievement_toast_surface().achievement_toast_queue.clear()
	game._achievement_toast_surface().achievement_toast_queue_ids.clear()
	for toast in game._achievement_toast_surface().achievement_toasts:
		if is_instance_valid(toast):
			toast.queue_free()
	game._achievement_toast_surface().achievement_toasts.clear()
	game.current_screen = "menu"
	game._navigation_shell()._render_screen()
	await settle(1.0)
	var measurements: Array = []
	var captured: Dictionary = {}
	for skill_id in ["fishing", "build", "woodcutting", "thieving", "fight"]:
		await open_skill_menu()
		var skill_button: Control = game.skill_cards[skill_id].button
		game.content_scroll.scroll_vertical += int(skill_button.get_global_rect().get_center().y - 850)
		await settle(0.3)
		await click(skill_button.get_global_rect().get_center())
		await settle(0.8)
		check(game.current_screen == "skill" and game.selected_skill_id == skill_id, "Skill reached through menu: " + skill_id)
		for action in game.actions_by_skill[skill_id]:
			var action_id := str(action.id)
			await game._skill_detail_surface()._scroll_to_activity_card(action_id, false, true)
			await settle(0.12)
			var card: Dictionary = game.action_cards.get(skill_id + ":" + action_id, {})
			var title: Label = card.get("title") as Label
			var stats: Control = card.get("stat_row") as Control
			if not is_instance_valid(title) or not is_instance_valid(stats) or not title.is_visible_in_tree() or not stats.is_visible_in_tree():
				continue
			var title_rect := title.get_global_rect()
			if not title_rect.intersects(Rect2(0, 408, 1080, 990)):
				continue
			var gap := stats.get_global_rect().position.y - title_rect.end.y
			var rail: Control = card.get("progress") as Control
			var rail_gap := rail.get_global_rect().position.y - stats.get_global_rect().end.y if is_instance_valid(rail) else 999.0
			var build_cover: Control = card.get("build_overlay") as Control
			var stats_covered := is_instance_valid(build_cover) and build_cover.is_visible_in_tree()
			measurements.append({"skill":skill_id, "action":action_id, "title":title.text, "font_size":title.get_theme_font_size("font_size"), "title_to_stats":gap, "stats_to_progress":rail_gap, "stats_covered_by_build_cost":stats_covered})
			check(gap >= 12.0, "Title clears stats: %s/%s gap=%s" % [skill_id, action_id, gap])
			if not stats_covered:
				check(rail_gap >= 12.0, "Stats clear progress: %s/%s gap=%s" % [skill_id, action_id, rail_gap])
			if action_id == "practice-pool" or not captured.has(skill_id):
				await capture(action_id if action_id == "practice-pool" else "spacing-" + skill_id)
				captured[skill_id] = true
			elif not (action.get("recovery", {}) as Dictionary).is_empty() and not captured.has(skill_id + "-recovery"):
				await capture("spacing-" + skill_id + "-recovery")
				captured[skill_id + "-recovery"] = true
			elif gap < 12.0 or (not stats_covered and rail_gap < 12.0):
				await capture("spacing-" + skill_id + "-" + action_id)
		print("title-spacing skill=", skill_id, " checked_so_far=", measurements.size())
	var report := FileAccess.open(capture_dir + "/measurements.json", FileAccess.WRITE)
	report.store_string(JSON.stringify(measurements, "\t"))
	report.close()
	check(measurements.size() >= 50, "Audit covers standard cards across skills")
	check(captured.has("fishing"), "Fishing spacing captured")
	print("title-spacing checked=", measurements.size(), " failures=", failures)
	await settle(1.0)
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
