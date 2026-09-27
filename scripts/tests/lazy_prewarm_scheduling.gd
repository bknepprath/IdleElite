extends SceneTree

const SkillDetailSurface = preload("res://scripts/ui/skill_detail_surface.gd")

class TestHost extends RefCounted:
	var transitioning := false
	func _skill_swipe_loading_transition_active() -> bool:
		return transitioning

class SchedulingProbe extends SkillDetailSurface:
	var prewarm_calls := 0
	var mount_count := 0
	func _process_detail_lazy_window(_delta: float) -> int:
		return mount_count
	func _process_detail_lazy_adjacent_prewarm() -> bool:
		prewarm_calls += 1
		return true
	func _maybe_resume_fishing_detail_idle_warm_mount() -> void:
		pass
	func _process_detail_lazy_settle_warm_mount(_scrolling: bool) -> void:
		pass

func _init() -> void:
	var test_host := TestHost.new()
	var surface := SchedulingProbe.new(test_host)
	surface.detail_lazy_plan = [{}]
	surface._process_detail_lazy_runtime(1.0 / 60.0, true)
	if surface.prewarm_calls != 0:
		push_error("Offscreen preparation ran during scrolling")
		quit(1)
		return
	test_host.transitioning = true
	surface._process_detail_lazy_runtime(1.0 / 60.0, false)
	if surface.prewarm_calls != 0:
		push_error("Offscreen preparation ran during a swipe transition")
		quit(1)
		return
	test_host.transitioning = false
	surface.mount_count = 1
	surface._process_detail_lazy_runtime(1.0 / 60.0, false)
	if surface.prewarm_calls != 0:
		push_error("Offscreen preparation shared a visible card mount frame")
		quit(1)
		return
	surface.mount_count = 0
	surface._process_detail_lazy_runtime(1.0 / 60.0, false)
	if surface.prewarm_calls != 1:
		push_error("Offscreen preparation did not resume when settled")
		quit(1)
		return
	print("lazy-prewarm-scheduling-ok")
	quit(0)
