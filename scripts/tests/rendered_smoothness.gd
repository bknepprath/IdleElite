extends SceneTree

var scene: Node
var times: Array[int] = []
var previous_frame_us := Time.get_ticks_usec()
var failures: Array[String] = []
var capture_dir := "res://.codex-tmp/rendered-smoothness"

func _init() -> void:
	call_deferred("run")

func frame(record := true) -> void:
	await process_frame
	var now := Time.get_ticks_usec()
	if record:
		times.append(now - previous_frame_us)
	previous_frame_us = now

func settle(count: int, record := false) -> void:
	for i in range(count):
		await frame(record)

func pointer(position: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.position = position
	event.global_position = position
	event.pressed = pressed
	Input.parse_input_event(event.xformed_by(root.get_final_transform()))

func drag(start: Vector2, end: Vector2, capture_label := "") -> void:
	if not capture_label.is_empty(): await capture(capture_label + "-before")
	var down := InputEventScreenTouch.new()
	down.index = 0
	down.position = start
	down.pressed = true
	root.push_input(down, true)
	await frame()
	for i in range(36):
		if i == 18 and not capture_label.is_empty(): await capture(capture_label + "-transition")
		var event := InputEventScreenDrag.new()
		event.index = 0
		event.position = start.lerp(end, float(i + 1) / 36.0)
		event.relative = (end - start) / 36.0
		event.velocity = (end - start) / 0.3
		root.push_input(event, true)
		await frame()
	var up := InputEventScreenTouch.new()
	up.index = 0
	up.position = end
	up.pressed = false
	root.push_input(up, true)
	await settle(120, true)
	if not capture_label.is_empty(): await capture(capture_label + "-settled")
func report(label: String) -> void:
	if times.is_empty():
		return
	if scene._skill_swipe_activity_surface()._skill_detail_has_visible_lazy_placeholders():
		failures.append("Incomplete visible content after %s" % label)
	times.sort()
	var over20 := 0
	var over50 := 0
	for time in times:
		if time > 20000: over20 += 1
		if time > 50000: over50 += 1
	print("RENDERED_SAMPLE label=%s skill=%s count=%s p50_us=%s p99_us=%s max_us=%s over20=%s over50=%s placeholders=%s" % [label, scene.selected_skill_id, times.size(), times[times.size()/2], times[mini(times.size()-1, int(times.size()*0.99))], times[-1], over20, over50, scene._skill_swipe_activity_surface()._skill_detail_has_visible_lazy_placeholders()])
	times.clear()

func capture(label: String) -> void:
	if OS.get_environment("IDLE_ELITE_RENDERED_CAPTURE") != "1":
		return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image.get_size() != Vector2i(1080, 1920):
		failures.append("Viewport capture has wrong dimensions: %s" % image.get_size())
		return
	image.save_png("%s/%s.png" % [capture_dir, label])
	await settle(8)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Rendered navigation test requires --visible-game")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(capture_dir)
	scene = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	for i in range(3600):
		await frame(false)
		if scene.startup_initialized and not scene.boot_detail_render_in_progress and not scene.boot_detail_scroll_locked and scene.boot_detail_render_queue.is_empty():
			break
	scene._test_state_runtime()._god_mode_unlock_onboarding_state()
	scene._test_state_runtime()._god_mode_max_skills_state()
	scene._test_state_runtime()._god_mode_unlock_actions_state()
	for achievement in preload("res://scripts/achievements/state.gd").milestones(scene, false):
		if bool(achievement.get("completed", false)):
			scene._achievement_toast_surface().seen_ids()[str(achievement.id)] = true
	scene.current_screen = "menu"
	scene._navigation_shell()._render_screen(false, -1, false)
	await settle(360)
	await capture("menu")
	pointer(Vector2(450, 680), true)
	await frame()
	pointer(Vector2(450, 680), false)
	await settle(240, true)
	report("open-thieving")
	if scene.current_screen != "skill" or scene.selected_skill_id != "thieving":
		push_error("UI click did not reach Thieving")
		quit(1)
		return
	for cycle in range(2):
		await drag(Vector2(640, 600), Vector2(640, 1320))
		report("thieving-scroll-up-%s" % cycle)
		await drag(Vector2(640, 1320), Vector2(640, 600))
		report("thieving-scroll-down-%s" % cycle)
	await capture("thieving-settled")
	for cycle in range(2):
		for expected in ["build", "woodcutting", "fishing", "fight", "thieving"]:
			await drag(Vector2(870, 900), Vector2(150, 900))
			report("swipe-%s-%s" % [cycle, expected])
			if scene.selected_skill_id != expected:
				failures.append("Swipe expected %s got %s" % [expected, scene.selected_skill_id])
			await capture("%s-%s" % [cycle, expected])
			if expected == "fishing" or expected == "fight":
				var before_scroll: float = scene._skill_detail_surface().detail_actions_scroll.scroll_vertical
				if before_scroll > 500.0:
					await drag(Vector2(950, 570), Vector2(950, 1320))
				else:
					await drag(Vector2(950, 1320), Vector2(950, 570))
				print("SCROLL_MOVEMENT skill=%s before=%s after=%s" % [expected, before_scroll, scene._skill_detail_surface().detail_actions_scroll.scroll_vertical])
				if absf(before_scroll - scene._skill_detail_surface().detail_actions_scroll.scroll_vertical) < 100.0:
					failures.append("Scroll gesture did not move %s" % expected)
				report("scroll-%s-%s" % [cycle, expected])
	if OS.get_environment("IDLE_ELITE_RENDERED_CAPTURE") == "1":
		await drag(Vector2(870, 900), Vector2(150, 900), "build-swipe")
	print("RENDERED_TEST_DONE failures=%s" % str(failures))
	quit(0 if failures.is_empty() else 1)


