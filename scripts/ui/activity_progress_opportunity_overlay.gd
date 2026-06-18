class_name ActivityProgressOpportunityOverlay
extends Control

const WINDOW_VERTICAL_OUTSET := 22.0
const WINDOW_RADIUS := 18.0
const WINDOW_OUTLINE_GROW := 3.0
const WINDOW_STROKE_INSET := 5.0
const WINDOW_STROKE_WIDTH := 12.0
const WINDOW_HOLE_INSET := WINDOW_STROKE_INSET + WINDOW_STROKE_WIDTH

var progress_rail: Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	if progress_rail == null or not is_instance_valid(progress_rail):
		return
	var rect: Rect2 = progress_rail.call("_activity_progress_track_rect")
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	rect.position.y += WINDOW_VERTICAL_OUTSET
	_draw_opportunity_windows(rect)
	_draw_opportunity_feedback_windows(rect)

func _draw_opportunity_windows(rect: Rect2) -> void:
	var windows := progress_rail.get("opportunity_windows") as Array
	var alpha := float(progress_rail.get("opportunity_alpha"))
	if windows.is_empty() or alpha <= 0.01 or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	if not str(progress_rail.get("opportunity_feedback_mode")).is_empty():
		return
	var active := bool(progress_rail.get("opportunity_active"))
	var unavailable_blend := float(progress_rail.get("opportunity_unavailable_blend"))
	for raw_window in windows:
		var window := raw_window as Vector2
		var start := clampf(window.x, 0.0, 1.0)
		var finish := clampf(window.y, start, 1.0)
		if finish - start <= 0.001:
			continue
		var outline := Color("#15120b")
		outline.a = lerpf(0.95 if active else 0.78, 0.72, unavailable_blend) * alpha
		var stroke := Color("#ffd84a").lerp(Color("#8b8982"), unavailable_blend)
		stroke.a = lerpf(1.0 if active else 0.86, 0.74, unavailable_blend) * alpha
		_draw_opportunity_window_strokes(rect, start, finish, outline, stroke, Vector2.ZERO)

func _draw_opportunity_feedback_windows(rect: Rect2) -> void:
	var feedback_mode := str(progress_rail.get("opportunity_feedback_mode"))
	if feedback_mode.is_empty() or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var live_window := bool(progress_rail.get("opportunity_feedback_live_window"))
	var windows := progress_rail.get("opportunity_windows") as Array
	var feedback_windows := progress_rail.get("opportunity_feedback_windows") as Array
	var draw_windows := windows if live_window and not windows.is_empty() else feedback_windows
	if draw_windows.is_empty():
		return
	var elapsed := float(progress_rail.get("opportunity_feedback_elapsed"))
	var duration := float(progress_rail.get("opportunity_feedback_duration"))
	var direction := float(progress_rail.get("opportunity_feedback_direction"))
	var t := clampf(elapsed / maxf(0.001, duration), 0.0, 1.0)
	var feedback_alpha := 1.0
	var offset := Vector2.ZERO
	var stroke := Color("#47f06c") if feedback_mode == "success" else Color("#ff4040")
	if feedback_mode == "success":
		var shake_wave := sin(t * PI * 7.0) * (1.0 - t) * direction
		offset = Vector2(shake_wave * 10.0, absf(shake_wave) * 3.0)
		stroke = Color("#47f06c").lerp(Color("#ffd84a"), smoothstep(0.45, 1.0, t))
	else:
		var shake_wave := sin(t * PI * 8.0) * (1.0 - t) * direction
		offset = Vector2(shake_wave * 11.0, absf(shake_wave) * 2.0)
		stroke = Color("#ff4040").lerp(Color("#8b8982"), smoothstep(0.32, 1.0, t))
	var outline := Color("#15120b")
	outline.a = 0.96 * feedback_alpha
	stroke.a = feedback_alpha
	for raw_window in draw_windows:
		var window := raw_window as Vector2
		var start := clampf(window.x, 0.0, 1.0)
		var finish := clampf(window.y, start, 1.0)
		if finish - start <= 0.001:
			continue
		_draw_opportunity_window_strokes(rect, start, finish, outline, stroke, offset)

func _draw_opportunity_window_strokes(rect: Rect2, start: float, finish: float, outline: Color, stroke: Color, offset: Vector2) -> void:
	var min_marker_pct := 2.0 / maxf(1.0, rect.size.x)
	var marker_width_pct := maxf(min_marker_pct, finish - start)
	var marker_start := start
	var marker_finish := start + marker_width_pct
	if marker_finish > 1.0:
		marker_finish = 1.0
		marker_start = maxf(0.0, marker_finish - marker_width_pct)
	var grow_pct := WINDOW_OUTLINE_GROW / maxf(1.0, rect.size.x)
	_draw_opportunity_window_ring(
		rect,
		outline,
		marker_start - grow_pct,
		marker_finish + grow_pct,
		0.0,
		marker_start,
		marker_finish,
		WINDOW_STROKE_INSET,
		offset,
		WINDOW_VERTICAL_OUTSET
	)
	_draw_opportunity_window_ring(
		rect,
		stroke,
		marker_start,
		marker_finish,
		WINDOW_STROKE_INSET,
		marker_start,
		marker_finish,
		WINDOW_HOLE_INSET,
		offset,
		WINDOW_VERTICAL_OUTSET
	)

func _draw_opportunity_window_ring(rect: Rect2, color: Color, outer_start_pct: float, outer_finish_pct: float, outer_inset_px: float, inner_start_pct: float, inner_finish_pct: float, inner_inset_px: float, offset: Vector2, vertical_outset_px := 0.0) -> void:
	var draw_rect := Rect2(
		Vector2(rect.position.x, rect.position.y - maxf(0.0, vertical_outset_px)),
		Vector2(rect.size.x, rect.size.y + maxf(0.0, vertical_outset_px) * 2.0)
	)
	var row_count := int(progress_rail.call("_rounded_fill_row_count", draw_rect))
	if row_count <= 0:
		return
	var row_height := draw_rect.size.y / float(row_count)
	for i in range(row_count):
		var y := draw_rect.position.y + (float(i) + 0.5) * row_height
		var outer_bounds := _opportunity_window_row_bounds(rect, outer_start_pct, outer_finish_pct, outer_inset_px, offset, draw_rect, y)
		if outer_bounds.y <= outer_bounds.x:
			continue
		var inner_bounds := _opportunity_window_row_bounds(rect, inner_start_pct, inner_finish_pct, inner_inset_px, offset, draw_rect, y)
		if inner_bounds.y <= inner_bounds.x:
			draw_line(Vector2(outer_bounds.x, y), Vector2(outer_bounds.y, y), color, row_height + 1.0, false)
			continue
		var left_right := minf(inner_bounds.x, outer_bounds.y)
		if left_right > outer_bounds.x:
			draw_line(Vector2(outer_bounds.x, y), Vector2(left_right, y), color, row_height + 1.0, false)
		var right_left := maxf(inner_bounds.y, outer_bounds.x)
		if outer_bounds.y > right_left:
			draw_line(Vector2(right_left, y), Vector2(outer_bounds.y, y), color, row_height + 1.0, false)

func _opportunity_window_row_bounds(rect: Rect2, start_pct: float, finish_pct: float, inset_px: float, offset: Vector2, draw_rect: Rect2, y: float) -> Vector2:
	var start := clampf(start_pct, 0.0, 1.0)
	var finish := clampf(finish_pct, 0.0, 1.0)
	if finish <= start or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return Vector2(1.0, 0.0)
	var line_left := rect.position.x + rect.size.x * start + offset.x + inset_px
	var line_right := rect.position.x + rect.size.x * finish + offset.x - inset_px
	var shape_top := draw_rect.position.y + offset.y + inset_px
	var shape_bottom := draw_rect.end.y + offset.y - inset_px
	if line_right <= line_left or shape_bottom <= shape_top or y < shape_top or y > shape_bottom:
		return Vector2(1.0, 0.0)
	var inset_radius := maxf(0.0, WINDOW_RADIUS - inset_px)
	var shape_radius := minf(inset_radius, minf(line_right - line_left, shape_bottom - shape_top) * 0.5)
	var window_inset := 0.0
	if shape_radius > 0.0 and y < shape_top + shape_radius:
		var top_dy := shape_top + shape_radius - y
		window_inset = shape_radius - sqrt(maxf(0.0, shape_radius * shape_radius - top_dy * top_dy))
	elif shape_radius > 0.0 and y > shape_bottom - shape_radius:
		var bottom_dy := y - (shape_bottom - shape_radius)
		window_inset = shape_radius - sqrt(maxf(0.0, shape_radius * shape_radius - bottom_dy * bottom_dy))
	return Vector2(line_left + window_inset, line_right - window_inset)

func _draw_opportunity_window_shape(rect: Rect2, color: Color, start_pct: float, finish_pct: float, inset_px: float, offset: Vector2, vertical_outset_px := 0.0, clip_to_track := true) -> void:
	var start := clampf(start_pct, 0.0, 1.0)
	var finish := clampf(finish_pct, 0.0, 1.0)
	if finish <= start or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var draw_rect := Rect2(
		Vector2(rect.position.x, rect.position.y - maxf(0.0, vertical_outset_px)),
		Vector2(rect.size.x, rect.size.y + maxf(0.0, vertical_outset_px) * 2.0)
	)
	var line_left := rect.position.x + rect.size.x * start + offset.x + inset_px
	var line_right := rect.position.x + rect.size.x * finish + offset.x - inset_px
	var shape_top := draw_rect.position.y + offset.y + inset_px
	var shape_bottom := draw_rect.end.y + offset.y - inset_px
	if line_right <= line_left or shape_bottom <= shape_top:
		return
	var inset_radius := maxf(0.0, WINDOW_RADIUS - inset_px)
	var shape_radius := minf(inset_radius, minf(line_right - line_left, shape_bottom - shape_top) * 0.5)
	var row_count := int(progress_rail.call("_rounded_fill_row_count", draw_rect))
	var row_height := draw_rect.size.y / float(row_count)
	for i in range(row_count):
		var y := draw_rect.position.y + (float(i) + 0.5) * row_height
		if y < shape_top or y > shape_bottom:
			continue
		var window_inset := 0.0
		if shape_radius > 0.0 and y < shape_top + shape_radius:
			var top_dy := shape_top + shape_radius - y
			window_inset = shape_radius - sqrt(maxf(0.0, shape_radius * shape_radius - top_dy * top_dy))
		elif shape_radius > 0.0 and y > shape_bottom - shape_radius:
			var bottom_dy := y - (shape_bottom - shape_radius)
			window_inset = shape_radius - sqrt(maxf(0.0, shape_radius * shape_radius - bottom_dy * bottom_dy))
		var clip: Vector2 = progress_rail.call("_bottom_round_row_clip", rect, y) if clip_to_track else Vector2(rect.position.x, rect.end.x)
		var row_left := maxf(clip.x, line_left + window_inset)
		var row_right := minf(clip.y, line_right - window_inset)
		if row_right <= row_left:
			continue
		draw_line(
			Vector2(row_left, y),
			Vector2(row_right, y),
			color,
			row_height + 1.0,
			false
		)

