extends "res://scripts/tests/desktop_discovery.gd"

func reveal_amount(control: Control) -> float:
	if not control.is_visible_in_tree(): return 0.0
	var cover = control.get_meta("activity_reveal_cover") if control.has_meta("activity_reveal_cover") else null
	if cover is WeakRef: cover = cover.get_ref()
	var amount := float(cover.revealed) if is_instance_valid(cover) else 1.0
	var ancestor: Node = control
	while ancestor is CanvasItem:
		amount *= ancestor.modulate.a
		ancestor = ancestor.get_parent()
	return amount

func _run() -> void:
	create_timer(110).timeout.connect(func(): quit(1))
	OS.set_environment("IDLE_ELITE_DESKTOP", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "100")
	AudioServer.set_bus_mute(0, true)
	root.borderless = true
	root.position = Vector2i.ZERO
	root.size = Vector2i(1920, 1080)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	for frame in range(1600):
		await settle(0.02)
		if game.startup_initialized and not game._boot_warmup_runtime().active: break
	game.activity_crit_seen = true
	game.activity_mega_crit_seen = true
	await click(game._tutorial_overlay_surface()._tutorial_target_control().get_global_rect().get_center())
	await settle(5)
	game.auto_unlock_lockpads_enabled = true
	game.skills.fight.xp = SkillState.xp_for_level(2) - 1
	SkillState.recalculate_level(game, "fight", false)
	await capture_desktop("unlock-audit-before")
	var last := {}
	var regressions := []
	var started := Time.get_ticks_msec()
	var capture_index := 0
	while Time.get_ticks_msec() - started < 8000:
		await RenderingServer.frame_post_draw
		for key in game.action_cards:
			var card: Dictionary = game.action_cards[key]
			if not str(key).begins_with("fight:"): continue
			var control: Control = card.get("root")
			if not is_instance_valid(control): continue
			var amount := reveal_amount(control)
			var entry := {"id":control.get_instance_id(), "amount":amount, "height":control.custom_minimum_size.y}
			if last.has(key):
				if amount < float(last[key].amount) - 0.08:
					regressions.append(str(key))
					print("REVEAL_REGRESSION ",key," ",last[key]," -> ",entry)
				if last[key].id != entry.id: print("REPLACED ",key)
			else: print("FIRST_SEEN ",key," ",entry)
			last[key] = entry
		if game.action_cards.has("fight:wrestle-stuck-gate-latch") and capture_index < 3:
			var card: Dictionary = game.action_cards["fight:wrestle-stuck-gate-latch"]
			var amount := reveal_amount(card.root)
			if (capture_index == 0 and amount < 0.1) or (capture_index == 1 and amount > 0.35) or (capture_index == 2 and amount >= 0.99):
				await capture_desktop("unlock-audit-" + str(capture_index))
				capture_index += 1
	print("REVEAL_AUDIT regressions=",regressions)
	await capture_desktop("unlock-audit-settled")
	var ceremony = game._activity_unlock_ceremony_surface()
	var preview_id := "wrestle-stuck-gate-latch"
	var preview: Dictionary = game.action_cards["fight:" + preview_id]
	ceremony.set_preview_after_ceremony(preview_id)
	ceremony.preview_staged_action_ids[preview_id] = true
	ceremony.preview_played_action_ids[preview_id] = true
	var previous_alpha: float = preview.root.modulate.a
	ceremony.stage_preview_for_action_id(preview_id, false)
	ceremony.play_next_locked_preview_fade()
	check(is_equal_approx(preview.root.modulate.a, previous_alpha), "Repeated ceremony callbacks never re-hide an entered card")
	await check_ribbon_and_tips()
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	print("REVEAL_TIPS failures=", JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)

func check_ribbon_and_tips() -> void:
	game._action_runtime()._stop_running_action(game.running_skill_id, game.running_action_id)
	game._tutorial_overlay_surface()._dismiss_blocking_tip()
	var desktop = game.desktop_layout
	var button: Button = desktop.ribbon_buttons.hub
	check(button.get_meta("nav_locked", false), "Hub remains locked at Building level one")
	check(button.is_visible_in_tree() and button.modulate.a > 0.3, "Locked ribbon icon remains visible")
	await click(button.get_global_rect().get_center())
	await settle(0.15)
	check(game.current_screen == "skill", "Locked ribbon cannot navigate")
	check(game.get_node_or_null("LockedRequirementFloat") != null, "Tap explains actual unlock requirement")
	await capture_desktop("ribbon-locked-requirement")
	await settle(3.5)
	check(desktop.intro_feature_eligible("queue"), "Empty queue is eligible without a circular prerequisite")
	desktop.intro_feature_cooldown = 0.0
	await settle(0.9)
	check(desktop.ribbon_feature_available("queue"), "Queue actually unlocks after its introduction interval")
	await click(desktop.ribbon_buttons.queue.get_global_rect().get_center())
	await settle(0.7)
	check(game.current_screen == "queue", "Unlocked queue opens through ribbon")
	await click(desktop.ribbon_buttons.skill.get_global_rect().get_center())
	await settle(0.7)
	await capture_desktop("drag-hint-before")
	capture_hint_fade()
	await drag_carousel(-1, "tip-audit")
	await settle(0.5)
	check(not desktop.skill_navigation.hint.visible, "Discovered drag hint finishes fading")
	await capture_desktop("drag-hint-settled")
	# Reach Building through production carousel navigation.
	for step in range(5):
		if desktop.skill_slots[1] == "build": break
		await click_navigation(1)
		await settle(0.35)
	var column: Dictionary = desktop.columns[1]
	var move := InputEventMouseMotion.new()
	move.position = column.picker.get_global_rect().get_center()
	root.push_input(move, true)
	await settle(0.5)
	await check_pull_tips("desktop")
	root.size = Vector2i(1080, 1920)
	await settle(2)
	game._navigation_shell()._select_skill("build")
	await settle(2)
	await check_pull_tips("portrait")

func capture_hint_fade() -> void:
	while not game.desktop_layout.carousel_discovered: await process_frame
	await settle(0.13)
	check(game.desktop_layout.skill_navigation.hint.modulate.a > 0.0 and game.desktop_layout.skill_navigation.hint.modulate.a < 1.0, "Drag hint has a visible fade transition")
	await capture_desktop("drag-hint-transition")

func check_pull_tips(label: String) -> void:
	var detail = game._skill_detail_surface()
	var texts = detail.DETAIL_PULL_TIP_TEXTS
	# Exclude all but the reported tip for deterministic selection; UI still opens it.
	detail.detail_pull_recent_tip_texts.assign(texts)
	detail.detail_pull_recent_tip_texts.erase("tip: high-level sort puts newer activities first.")
	var scroll = detail.detail_actions_scroll
	print("TIP_CONTEXT ", label, " ", game.selected_skill_id, " scroll=", scroll)
	if not is_instance_valid(scroll):
		check(false, "Production scroll exists")
		return
	scroll.scroll_vertical = 0
	var start: Vector2 = scroll.get_global_rect().position + Vector2(scroll.size.x * 0.65, 180)
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = start
	touch.pressed = true
	root.push_input(touch, true)
	for i in range(25):
		var drag := InputEventScreenDrag.new()
		drag.index = 0
		drag.relative = Vector2(0, 35)
		drag.position = start + Vector2(0, 35 * (i + 1))
		root.push_input(drag, true)
		await settle(0.015)
	await settle(0.08)
	var tip: Label = detail.detail_pull_tip_label
	check(tip.is_visible_in_tree(), label + " actual pull reveals tip")
	await capture_desktop("pull-tip-" + label)
	var original := tip.text
	for text in texts:
		tip.text = detail._detail_pull_tip_display_text(text)
		await process_frame
		var needed := tip.get_theme_font("font").get_multiline_string_size(tip.text, HORIZONTAL_ALIGNMENT_CENTER, tip.size.x, tip.get_theme_font_size("font_size"))
		check(needed.y <= tip.size.y, label + " complete tip fits: " + text)
		check(tip.get_visible_line_count() == tip.get_line_count(), label + " tip has no hidden lines")
	tip.text = original
	touch.position = start + Vector2(0, 875)
	touch.pressed = false
	root.push_input(touch, true)
	await settle(0.6)
