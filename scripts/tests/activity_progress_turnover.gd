extends SceneTree

func _init() -> void:
	var script = load("res://scripts/ui/skill_swipe_activity_surface.gd")
	var surface = script.new(null)
	var failed := false
	failed = failed or not is_equal_approx(surface._action_progress_turnover_value(0.0, 25.0, 82.0, 60.0, 3.0), 82.0)
	failed = failed or not is_equal_approx(surface._action_progress_turnover_value(0.21, 25.0, 82.0, 60.0, 3.0), 0.0)
	failed = failed or not is_equal_approx(surface._action_progress_turnover_value(0.40, 25.0, 82.0, 60.0, 3.0), 22.0)
	var near_handoff: float = float(surface._action_progress_turnover_value(0.3999, 25.0, 82.0, 60.0, 3.0))
	failed = failed or absf((22.0 - near_handoff) / 0.0001 - 60.0) >= 1.0
	if failed:
		push_error("activity progress turnover continuity failed")
		quit(1)
		return
	print("activity-progress-turnover-ok")
	quit()
