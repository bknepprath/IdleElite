class_name ActivityProgressRail
extends Control

const ActivityProgressOpportunityOverlay = preload("res://scripts/ui/activity_progress_opportunity_overlay.gd")

const OPPORTUNITY_WINDOW_VERTICAL_OUTSET := 22.0
const OPPORTUNITY_WINDOW_OVERLAY_Z := 80
const ROUNDED_FILL_ROWS := 18
var value := 0.0
var opportunity_windows: Array[Vector2] = []
var opportunity_active := false
var opportunity_alpha := 0.0
var opportunity_target_alpha := 0.0
var opportunity_unavailable_blend := 0.0
var opportunity_unavailable_target_alpha := 0.0
var opportunity_feedback_windows: Array[Vector2] = []
var opportunity_feedback_mode := ""
var opportunity_feedback_elapsed := 0.0
var opportunity_feedback_duration := 0.0
var opportunity_feedback_direction := 1.0
var opportunity_feedback_live_window := false
var easing_speed := 24.0
var fill_color := Color("#35d86d")
var empty_color := Color("#fff1c8")
var fill_segments: Array[Color] = []
var empty_segments: Array[Color] = []
var opportunity_color := Color("#fff2a8")
var opportunity_active_color := Color("#ffffff")
var top_lip_color := Color("#171615")
var top_lip_height := 7.0
var bottom_radius := 66.0
var edge_inset := 6.0
var bottom_inset := 0.0
var corner_guard := 0.0
var bottom_shape := "round"
var wide_u_bottom_rise := 58.0
var opportunity_overlay: ActivityProgressOpportunityOverlay

func _ready() -> void:
	set_process(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_opportunity_overlay()
		_queue_opportunity_overlay_redraw()

func _process(delta: float) -> void:
	var weight := 1.0 - exp(-8.0 * delta)
	opportunity_alpha = lerpf(opportunity_alpha, opportunity_target_alpha, weight)
	if absf(opportunity_alpha - opportunity_target_alpha) <= 0.01:
		opportunity_alpha = opportunity_target_alpha
	opportunity_unavailable_blend = lerpf(opportunity_unavailable_blend, opportunity_unavailable_target_alpha, weight)
	if absf(opportunity_unavailable_blend - opportunity_unavailable_target_alpha) <= 0.01:
		opportunity_unavailable_blend = opportunity_unavailable_target_alpha
	if not opportunity_feedback_mode.is_empty():
		opportunity_feedback_elapsed += delta
		if opportunity_feedback_elapsed >= opportunity_feedback_duration:
			opportunity_feedback_mode = ""
			opportunity_feedback_windows.clear()
	_queue_opportunity_overlay_redraw()
	if opportunity_alpha == opportunity_target_alpha and opportunity_unavailable_blend == opportunity_unavailable_target_alpha and opportunity_feedback_mode.is_empty():
		set_process(false)

func set_value(next_value: float) -> void:
	var clamped := clampf(next_value, 0.0, 100.0)
	if absf(value - clamped) <= 0.001:
		return
	value = clamped
	queue_redraw()
	_queue_opportunity_overlay_redraw()

func set_color_segments(next_fill_segments: Array, next_empty_segments: Array = []) -> void:
	var normalized_fill := _normalized_color_segments(next_fill_segments)
	var normalized_empty := _normalized_color_segments(next_empty_segments)
	if _color_segments_equal(fill_segments, normalized_fill) and _color_segments_equal(empty_segments, normalized_empty):
		return
	fill_segments = normalized_fill
	empty_segments = normalized_empty
	queue_redraw()
	_queue_opportunity_overlay_redraw()

func set_opportunity_windows(next_windows: Array[Vector2], active := false, should_show := true, unavailable := false) -> void:
	var next_target_alpha := 1.0 if should_show and not next_windows.is_empty() else 0.0
	var next_unavailable_target := 1.0 if unavailable and should_show and not next_windows.is_empty() else 0.0
	if active == opportunity_active and absf(opportunity_target_alpha - next_target_alpha) <= 0.001 and absf(opportunity_unavailable_target_alpha - next_unavailable_target) <= 0.001 and _opportunity_windows_equal(next_windows):
		return
	opportunity_windows = next_windows.duplicate()
	opportunity_active = active
	opportunity_target_alpha = next_target_alpha
	opportunity_unavailable_target_alpha = next_unavailable_target
	if next_target_alpha > 0.0 or opportunity_alpha > 0.01:
		_ensure_opportunity_overlay()
	if opportunity_alpha != opportunity_target_alpha or opportunity_unavailable_blend != opportunity_unavailable_target_alpha:
		set_process(true)
	_queue_opportunity_overlay_redraw()

func _opportunity_windows_equal(next_windows: Array[Vector2]) -> bool:
	if opportunity_windows.size() != next_windows.size():
		return false
	for i in range(opportunity_windows.size()):
		var current_window := opportunity_windows[i] as Vector2
		var next_window := next_windows[i] as Vector2
		if not current_window.is_equal_approx(next_window):
			return false
	return true

func play_opportunity_feedback(success: bool, windows: Array[Vector2], live_window := false) -> void:
	opportunity_feedback_windows = windows.duplicate()
	if live_window and not windows.is_empty():
		opportunity_windows = windows.duplicate()
	if opportunity_feedback_windows.is_empty():
		opportunity_feedback_windows = opportunity_windows.duplicate()
	if opportunity_feedback_windows.is_empty():
		return
	opportunity_feedback_mode = "success" if success else "miss"
	opportunity_feedback_elapsed = 0.0
	opportunity_feedback_duration = 0.42 if success else 0.72
	opportunity_feedback_direction = -1.0 if randf() < 0.5 else 1.0
	opportunity_feedback_live_window = live_window
	_ensure_opportunity_overlay()
	set_process(true)
	_queue_opportunity_overlay_redraw()

func get_opportunity_feedback_global_position(progress_pct := -1.0) -> Vector2:
	var inset := minf(edge_inset, minf(size.x, size.y) * 0.25)
	var lower_inset := minf(bottom_inset, maxf(0.0, size.y - top_lip_height))
	var track_rect := Rect2(Vector2(inset, top_lip_height), Vector2(maxf(0.0, size.x - inset * 2.0), maxf(0.0, size.y - top_lip_height - inset - lower_inset)))
	var center_pct := 0.5
	if not opportunity_windows.is_empty():
		var chosen := opportunity_windows[0] as Vector2
		if progress_pct >= 0.0:
			for raw_window in opportunity_windows:
				var window := raw_window as Vector2
				if progress_pct >= window.x and progress_pct <= window.y:
					chosen = window
					break
		center_pct = clampf((chosen.x + chosen.y) * 0.5, 0.0, 1.0)
	var local_point := Vector2(track_rect.position.x + track_rect.size.x * center_pct, track_rect.position.y + track_rect.size.y * 0.5)
	return get_global_transform_with_canvas() * local_point

func has_opportunity_progress(progress_pct: float) -> bool:
	if opportunity_windows.is_empty() or opportunity_target_alpha <= 0.0 or opportunity_unavailable_target_alpha > 0.5:
		return false
	var checked_progress := clampf(progress_pct, 0.0, 1.0)
	for raw_window in opportunity_windows:
		var window := raw_window as Vector2
		var start := clampf(window.x, 0.0, 1.0)
		var finish := clampf(window.y, start, 1.0)
		if finish - start <= 0.001:
			continue
		if checked_progress >= start and checked_progress <= finish:
			return true
	return false

func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	if bottom_shape == "wide_u":
		_draw_wide_u_progress()
		return
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, top_lip_height)), top_lip_color)
	var track_rect := _activity_progress_track_rect()
	if empty_segments.is_empty():
		_draw_bottom_round_fill(track_rect, empty_color, 1.0)
	else:
		_draw_bottom_round_segments(track_rect, empty_segments, 1.0)
	var fill_pct := value / 100.0
	if fill_segments.is_empty():
		_draw_bottom_round_fill(track_rect, fill_color, fill_pct)
	else:
		_draw_bottom_round_segments(track_rect, fill_segments, fill_pct)

func _activity_progress_track_rect() -> Rect2:
	var inset := minf(edge_inset, minf(size.x, size.y) * 0.25)
	var lower_inset := minf(bottom_inset, maxf(0.0, size.y - top_lip_height))
	var track_rect := Rect2(Vector2(inset, top_lip_height), Vector2(maxf(0.0, size.x - inset * 2.0), maxf(0.0, size.y - top_lip_height - inset - lower_inset)))
	track_rect.position.y = top_lip_height
	return track_rect

func _ensure_opportunity_overlay() -> void:
	if opportunity_overlay != null and is_instance_valid(opportunity_overlay):
		_layout_opportunity_overlay()
		return
	opportunity_overlay = ActivityProgressOpportunityOverlay.new()
	opportunity_overlay.progress_rail = self
	opportunity_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	opportunity_overlay.z_index = OPPORTUNITY_WINDOW_OVERLAY_Z
	opportunity_overlay.z_as_relative = true
	add_child(opportunity_overlay)
	_layout_opportunity_overlay()

func _layout_opportunity_overlay() -> void:
	if opportunity_overlay == null or not is_instance_valid(opportunity_overlay):
		return
	opportunity_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	opportunity_overlay.offset_left = 0.0
	opportunity_overlay.offset_right = 0.0
	opportunity_overlay.offset_top = -OPPORTUNITY_WINDOW_VERTICAL_OUTSET
	opportunity_overlay.offset_bottom = OPPORTUNITY_WINDOW_VERTICAL_OUTSET

func _opportunity_overlay_needed() -> bool:
	return opportunity_alpha > 0.01 or opportunity_target_alpha > 0.01 or not opportunity_feedback_mode.is_empty() or not opportunity_feedback_windows.is_empty()

func _queue_opportunity_overlay_redraw() -> void:
	if opportunity_overlay == null or not is_instance_valid(opportunity_overlay):
		if _opportunity_overlay_needed():
			_ensure_opportunity_overlay()
		else:
			return
	opportunity_overlay.visible = _opportunity_overlay_needed()
	opportunity_overlay.queue_redraw()

func _draw_bottom_round_fill(rect: Rect2, color: Color, fill_pct: float) -> void:
	var pct := clampf(fill_pct, 0.0, 1.0)
	if pct <= 0.0 or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	_draw_bottom_round_segment(rect, color, 0.0, pct)

func _draw_bottom_round_segments(rect: Rect2, colors: Array[Color], fill_pct: float) -> void:
	var pct := clampf(fill_pct, 0.0, 1.0)
	if pct <= 0.0 or colors.is_empty() or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var count := colors.size()
	for index in range(count):
		var start := float(index) / float(count)
		var finish := float(index + 1) / float(count)
		var visible_finish := minf(finish, pct)
		if visible_finish <= start:
			continue
		_draw_bottom_round_segment(
			rect,
			colors[index] as Color,
			start,
			visible_finish
		)

func _draw_bottom_round_segment(rect: Rect2, color: Color, start_pct: float, finish_pct: float, offset_x := 0.0) -> void:
	var start := clampf(start_pct, 0.0, 1.0)
	var finish := clampf(finish_pct, 0.0, 1.0)
	if finish <= start or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var row_count := _rounded_fill_row_count(rect)
	var row_height := rect.size.y / float(row_count)
	var raw_start_x := rect.position.x + rect.size.x * start + offset_x
	var raw_finish_x := rect.position.x + rect.size.x * finish + offset_x
	var radius := minf(bottom_radius, rect.size.x * 0.5)
	var corner_center_y := rect.end.y - radius
	for i in range(row_count):
		var y := rect.position.y + (float(i) + 0.5) * row_height
		var row_progress := clampf((y - rect.position.y) / maxf(1.0, rect.size.y), 0.0, 1.0)
		var u_side_trim := rect.size.x * 0.18 * maxf(0.0, row_progress - 0.50) / 0.50 if bottom_shape == "wide_u" else 0.0
		var left_clip := rect.position.x
		var right_clip := rect.end.x
		if radius > 0.0 and y >= corner_center_y:
			var dy := y - corner_center_y
			var corner_inset := radius - sqrt(maxf(0.0, radius * radius - dy * dy))
			left_clip += corner_inset
			right_clip -= corner_inset
		left_clip += u_side_trim
		right_clip -= u_side_trim
		var line_left := maxf(left_clip, raw_start_x)
		var line_right := minf(right_clip, raw_finish_x)
		if line_right <= line_left:
			continue
		draw_line(Vector2(line_left, y), Vector2(line_right, y), color, row_height + 1.0, false)

func _draw_wide_u_progress() -> void:
	var fill_pct := clampf(value / 100.0, 0.0, 1.0)
	var width := maxf(72.0, minf(size.y * 0.90, 88.0))
	var outline_width := width + 12.0
	_draw_wide_u_progress_segment(top_lip_color, 0.0, 1.0, outline_width)
	_draw_wide_u_progress_segment(empty_color, 0.0, 1.0, width)
	if fill_pct > 0.0:
		_draw_wide_u_progress_segment(fill_color, 0.0, fill_pct, width)

func _draw_wide_u_progress_segment(color: Color, start_pct: float, finish_pct: float, stroke_width: float) -> void:
	var start := clampf(start_pct, 0.0, 1.0)
	var finish := clampf(finish_pct, 0.0, 1.0)
	if finish <= start:
		return
	var points := PackedVector2Array()
	var steps := maxi(8, int(ceil((finish - start) * 34.0)))
	for index in range(steps + 1):
		var pct := lerpf(start, finish, float(index) / float(steps))
		points.append(_wide_u_progress_point(pct, stroke_width))
	if points.size() >= 2:
		draw_polyline(points, color, stroke_width, false)

func _wide_u_progress_point(pct: float, stroke_width: float) -> Vector2:
	var half_stroke := stroke_width * 0.5
	var x := lerpf(0.0, size.x, clampf(pct, 0.0, 1.0))
	var bottom_y := maxf(stroke_width * 0.52 + 8.0, size.y - stroke_width * 0.50)
	var side_y := maxf(stroke_width * 0.52, bottom_y - wide_u_bottom_rise)
	var y := lerpf(side_y, bottom_y, sin(clampf(pct, 0.0, 1.0) * PI))
	return Vector2(x, y)

func _rounded_fill_row_count(rect: Rect2) -> int:
	return maxi(6, mini(ROUNDED_FILL_ROWS, int(ceil(rect.size.y / 4.0))))

func _normalized_color_segments(colors: Array) -> Array[Color]:
	var normalized: Array[Color] = []
	for raw_color in colors:
		if raw_color is Color:
			normalized.append(raw_color as Color)
	return normalized

func _color_segments_equal(current: Array[Color], next: Array[Color]) -> bool:
	if current.size() != next.size():
		return false
	for index in range(current.size()):
		if not (current[index] as Color).is_equal_approx(next[index] as Color):
			return false
	return true

func _bottom_round_row_clip(rect: Rect2, y: float) -> Vector2:
	var left_clip := rect.position.x
	var right_clip := rect.end.x
	var radius := minf(bottom_radius, rect.size.x * 0.5)
	var corner_center_y := rect.end.y - radius
	if radius > 0.0 and y >= corner_center_y:
		var dy := y - corner_center_y
		var corner_inset := radius - sqrt(maxf(0.0, radius * radius - dy * dy))
		left_clip += corner_inset
		right_clip -= corner_inset
	return Vector2(left_clip, right_clip)



