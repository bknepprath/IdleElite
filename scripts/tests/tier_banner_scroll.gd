extends SceneTree

const BOOT_TIMEOUT_FRAMES := 720

var failures: Array[String] = []
var tier_hit_count := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "14")
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("main scene did not load")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	if not await _wait_for_boot_ready(scene):
		_fail("boot did not become ready")
		return

	var detail_surface: Object = scene.call("_skill_detail_surface") as Object
	var original_screen := str(scene.get("current_screen"))
	var original_scroll = detail_surface.get("detail_actions_scroll")
	var scroll := MobileScrollContainer.new()
	root.add_child(scroll)
	scene.set("current_screen", "skill")
	detail_surface.set("detail_actions_scroll", scroll)
	var button: Button = detail_surface.call(
		"_tier_banner_hit_button",
		Vector2.ZERO,
		Vector2(600.0, 600.0),
		Callable(self, "_record_tier_hit"),
		"tier_banner_scroll_test"
	) as Button
	root.add_child(button)

	scroll.child_click_suppressed = true
	button.emit_signal("button_down")
	button.emit_signal("pressed")
	_expect(tier_hit_count == 0, "a completed page drag activated the tier banner close button")

	scroll.child_click_suppressed = false
	scroll.drag_scrolling = true
	button.emit_signal("button_down")
	button.emit_signal("pressed")
	_expect(tier_hit_count == 0, "an active page drag activated the tier banner close button")

	scroll.drag_scrolling = false
	scroll.velocity = 240.0
	button.emit_signal("button_down")
	button.emit_signal("pressed")
	_expect(tier_hit_count == 0, "scroll inertia activated the tier banner close button")

	scroll.velocity = 0.0
	button.emit_signal("button_down")
	button.emit_signal("pressed")
	_expect(tier_hit_count == 1, "a clean tier banner tap did not activate the close button")

	button.emit_signal("button_down")
	button.call("_cancel_on_scroll", 120.0)
	# Scroll suppression can clear before a delayed button release arrives.
	scroll.child_click_suppressed = false
	scroll.drag_scrolling = false
	scroll.velocity = 0.0
	button.emit_signal("pressed")
	_expect(tier_hit_count == 1, "a delayed release after scrolling toggled the tier banner")

	button.emit_signal("button_down")
	button.emit_signal("pressed")
	_expect(tier_hit_count == 2, "a fresh tap after a cancelled drag did not toggle the banner")

	button.emit_signal("button_down")
	var touch_drag := InputEventScreenDrag.new()
	touch_drag.relative = Vector2(0.0, 80.0)
	button.call("_input", touch_drag)
	button.emit_signal("pressed")
	_expect(tier_hit_count == 2, "a touch drag toggled the tier banner after scrolling stopped")

	detail_surface.set("detail_actions_scroll", original_scroll)
	scene.set("current_screen", original_screen)
	button.queue_free()
	scroll.queue_free()
	if failures.is_empty():
		print("tier-banner-scroll-ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _record_tier_hit() -> void:
	tier_hit_count += 1


func _wait_for_boot_ready(scene: Node) -> bool:
	for _frame in range(BOOT_TIMEOUT_FRAMES):
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


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
