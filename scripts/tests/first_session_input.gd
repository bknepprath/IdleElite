extends SceneTree

var game: Node
var failures: Array[String] = []
var capture_dir := "res://.codex-tmp/input-fix-validation"

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func settle(seconds := 0.3) -> void:
	await create_timer(seconds).timeout

func click(point: Vector2, touch := false) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)
	await process_frame
	for down in [true, false]:
		var event: InputEvent
		if touch:
			var e := InputEventScreenTouch.new()
			e.position = point
			e.index = 0
			e.pressed = down
			event = e
		else:
			var e := InputEventMouseButton.new()
			e.position = point
			e.global_position = point
			e.button_index = MOUSE_BUTTON_LEFT
			e.pressed = down
			event = e
		root.push_input(event, true)
		await settle(0.06)
	await settle()

# Two taps in quick succession. A locked frame's requirement explains itself on
# one tap and goes to its source on the second.
func double_click(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)
	await process_frame
	for press in range(2):
		for down in [true, false]:
			var event := InputEventMouseButton.new()
			event.position = point
			event.global_position = point
			event.button_index = MOUSE_BUTTON_LEFT
			event.pressed = down
			root.push_input(event, true)
			await settle(0.06)
	await settle()

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	check(img.get_width() == 1080 and img.get_height() == 1920, "Raw capture must be 1080x1920")
	img.save_png(capture_dir + "/" + label + ".png")

func _run() -> void:
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	for i in range(1200):
		await settle(0.02)
		if game.startup_initialized and not game._boot_warmup_runtime().active:
			break
	await settle(1.0)
	check(game.auto_unlock_lockpads_enabled, "Fresh save must default auto unlock ON")
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	# Only onboarding is completed; skills and activity unlocks remain fresh.
	await settle()
	game._navigation_shell()._select_skill("fishing")
	await settle(2.0)
	var fishing = game._fishing_ui_surface()
	var routing = game._input_routing_shell()
	var detail = game._skill_detail_surface()
	print("INPUT_TEST fishing=", game.selected_skill_id, " candidates=", fishing._fishing_method_button_hit_candidates().size())
	var hits: Array = fishing._fishing_method_button_hit_candidates()
	await capture("test-initial")
	check(not hits.is_empty(), "Fresh Shallows must be mounted")
	if hits.is_empty():
		quit(1)
		return
	var card: Dictionary = {}
	for hit in hits:
		if str(hit.method_card.get("location_id", "")).contains("shallows"):
			card = hit.method_card
	check(not card.is_empty(), "Shallows location missing")
	var target: Control = card.get("method_image_hit_control")
	var action_id := str(card.action_id)
	for window_size in [Vector2i(627,1115), Vector2i(540,960), Vector2i(800,1200)]:
		root.size = window_size
		await settle(0.5)
		for touch in [false, true]:
			for fraction in [Vector2(0.25,0.25), Vector2(0.5,0.5), Vector2(0.75,0.75)]:
				card = fishing._fishing_method_card_for_action("fishing", action_id)
				target = card.get("method_image_hit_control")
				var point: Vector2 = target.get_global_rect().position + target.size * fraction
				check(routing._activity_input_position_candidates(point).size() == 1, "Pointer must have one viewport position")
				check(routing._page_switch_button_control_at_position(point) == null, "Shallows tap must not hit navigation")
				game.running_skill_id = ""
				game.running_action_id = ""
				await click(point, touch)
				check(game.running_skill_id == "fishing" and game.running_action_id == action_id, "Shallows failed: %s touch=%s point=%s running=%s:%s" % [window_size,touch,point,game.running_skill_id,game.running_action_id])
	game.running_skill_id = ""
	game.running_action_id = ""
	card = fishing._fishing_method_card_for_action("fishing", action_id)
	target = card.get("method_image_hit_control")
	var start := target.get_global_rect().get_center()
	var down := InputEventScreenTouch.new()
	down.position = start
	down.pressed = true
	root.push_input(down, true)
	await process_frame
	var drag := InputEventScreenDrag.new()
	drag.position = start + Vector2(0, 180)
	drag.relative = Vector2(0, 180)
	root.push_input(drag, true)
	await process_frame
	var up := InputEventScreenTouch.new()
	up.position = drag.position
	root.push_input(up, true)
	await settle(0.5)
	check(game.running_action_id.is_empty(), "Dragging off Shallows must not start fishing")
	await detail._restore_detail_actions_scroll(0)
	await settle()
	card = fishing._fishing_method_card_for_action("fishing", action_id)
	target = card.get("method_image_hit_control")
	await click(target.get_global_rect().get_center(), true)
	check(game.running_action_id == action_id, "Shallows must accept the next tap after a drag")
	game._navigation_shell()._select_skill("fight")
	await settle(1.0)
	check(detail._has_only_one_unlocked_activity("fight"), "Fresh Fighting must have one unlocked activity")
	await detail._scroll_to_latest_unlocked_activity(false)
	check(detail.detail_actions_scroll.scroll_vertical == 0, "A page with one unlocked activity must start at the top")
	root.size = Vector2i(627,1115)
	await settle(0.5)
	await capture("shallows-running")
	print("INPUT_TEST failures=", failures)
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
