extends Control

class ActivityProgressOpportunityOverlay:
	extends Control

	const WINDOW_VERTICAL_OUTSET := 11.0
	const WINDOW_INK_WIDTH := 6
	const WINDOW_COLOR_WIDTH := 6
	# Corner radius as a share of the frame's shorter side. 0.5 is a full pill;
	# a little under it leaves a short straight edge, so the frame reads as a
	# rounded rectangle.
	const WINDOW_CORNER_SHARE := 0.36
	var window_ink := StyleBoxFlat.new()
	var window_color := StyleBoxFlat.new()

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
		var stroke: Color
		if feedback_mode == "success":
			# A hit flashes green and fades out; only a miss turns red and shakes.
			stroke = Color("#35d86d")
			feedback_alpha = 1.0 - smoothstep(0.55, 1.0, t)
		else:
			var shake_wave := sin(t * PI * 8.0) * (1.0 - t) * direction
			offset = Vector2(shake_wave * 5.5, absf(shake_wave))
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
		if progress_rail.get("bottom_shape") == "production_v":
			var points: PackedVector2Array = progress_rail.call("_production_opportunity_outline", start, finish)
			points=points.duplicate()
			for index in range(points.size()): points[index] += offset + Vector2(0, WINDOW_VERTICAL_OUTSET)
			if not points.is_empty():
				points.append(points[0])
				draw_polyline(points, outline, 18.0, true)
				draw_polyline(points, stroke, 6.0, true)
			return
		# Rounded, antialiased frames use the same six-pixel ink as the mastery bar.
		# The timing interval remains exact: styling never changes the hit window.
		var frame := Rect2(Vector2(rect.position.x + rect.size.x * start, rect.position.y - WINDOW_VERTICAL_OUTSET) + offset,
			Vector2(rect.size.x * (finish - start), rect.size.y + WINDOW_VERTICAL_OUTSET * 2.0))
		var radius := int(minf(frame.size.x, frame.size.y) * WINDOW_CORNER_SHARE)
		window_ink.draw_center = false
		window_ink.border_color = outline
		window_ink.set_border_width_all(WINDOW_INK_WIDTH * 2 + WINDOW_COLOR_WIDTH)
		window_ink.set_corner_radius_all(radius)
		window_ink.corner_detail = 12
		window_ink.anti_aliasing = true
		draw_style_box(window_ink, frame)
		window_color.draw_center = false
		window_color.border_color = stroke
		window_color.set_border_width_all(WINDOW_COLOR_WIDTH)
		window_color.set_corner_radius_all(maxi(0, radius - WINDOW_INK_WIDTH))
		window_color.corner_detail = 12
		window_color.anti_aliasing = true
		draw_style_box(window_color, frame.grow(-WINDOW_INK_WIDTH))

const OPPORTUNITY_WINDOW_VERTICAL_OUTSET := 11.0
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
var top_lip_color := Color("#171615")
var top_lip_height := 3.5
var bottom_radius := 33.0
var edge_inset := 3.0
var bottom_inset := 0.0
var bottom_shape := "round"
var wide_u_bottom_rise := 29.0
var wide_u_shoulder_ratio := 0.285
var opportunity_overlay: ActivityProgressOpportunityOverlay
var contour_cache_key: Array = []
var contour_path := PackedVector2Array()
var contour_distances := PackedFloat32Array()
var contour_bands: Dictionary = {}
var window_outline_key: Array = []
var window_outline := PackedVector2Array()

# Visual rounding does not change the numeric click interval. The frame is a
# constant-width rounded ribbon along filleted bends, with inset semicircle caps.
const OPPORTUNITY_BEND_RADIUS := 36.0
const OPPORTUNITY_HALF_WIDTH := 25.0

func _production_opportunity_outline(start: float, finish: float) -> PackedVector2Array:
	_ensure_contour_path()
	var key: Array=[contour_cache_key,start,finish]
	if window_outline_key==key: return window_outline
	window_outline_key=key
	window_outline=PackedVector2Array()
	var total: float=contour_distances[-1]
	var span:=maxf(0,(finish-start)*total)
	if span<.001: return window_outline
	var radius:=minf(OPPORTUNITY_HALF_WIDTH,span*.49)
	var left:=start+radius/total
	var right:=finish-radius/total
	var upper:=PackedVector2Array()
	var lower:=PackedVector2Array()
	var steps:=maxi(1,ceili((right-left)*total/2))
	for step in range(steps+1):
		var section:=_window_contour_section(lerpf(left,right,float(step)/steps))
		var normal:=Vector2(section[1].y,-section[1].x)*radius
		upper.append(section[0]+normal)
		lower.append(section[0]-normal)
	window_outline.append_array(upper)
	var end_section:=_window_contour_section(right)
	var end_angle:=end_section[1].angle()-PI*.5
	for step in range(1,33):
		var angle:=end_angle+PI*float(step)/32
		window_outline.append(end_section[0]+Vector2(cos(angle),sin(angle))*radius)
	for index in range(lower.size()-2,-1,-1): window_outline.append(lower[index])
	var start_section:=_window_contour_section(left)
	var start_angle:=start_section[1].angle()+PI*.5
	for step in range(1,32):
		var angle:=start_angle+PI*float(step)/32
		window_outline.append(start_section[0]+Vector2(cos(angle),sin(angle))*radius)
	# Keep the rounded ribbon centred on the authored sharp V. A smooth
	# vertical bend adjustment contains its tip without introducing a cusp.
	var half_notch:=absf(contour_path[2].x-contour_path[1].x)
	for index in window_outline.size():
		var relative_x: float=(window_outline[index].x-size.x*.5)/half_notch
		if absf(relative_x)<1:
			window_outline[index].y-=OPPORTUNITY_BEND_RADIUS*(sqrt(2.0)-1.0)*(.5+.5*cos(PI*relative_x))
	return window_outline

func _window_contour_section(progress: float) -> PackedVector2Array:
	_ensure_contour_path()
	var distance:=clampf(progress,0,1)*contour_distances[-1]
	if not contour_bands.has("window_bends"):
		var bends: Array=[]
		for joint in range(1,contour_path.size()-1):
			var before:=contour_path[joint]-contour_path[joint-1]
			var after:=contour_path[joint+1]-contour_path[joint]
			var incoming:=before.normalized()
			var outgoing:=after.normalized()
			var turn:=absf(incoming.angle_to(outgoing))
			if turn<.001: continue
			var tangent:=minf(OPPORTUNITY_BEND_RADIUS*tan(turn*.5),minf(before.length(),after.length())*.45)
			var radius:=tangent/tan(turn*.5)
			var center:=contour_path[joint]+(-incoming+outgoing).normalized()*radius/cos(turn*.5)
			var entry:=contour_path[joint]-incoming*tangent
			var exit:=contour_path[joint]+outgoing*tangent
			var angle:=(entry-center).angle()
			bends.append({"start":contour_distances[joint]-tangent,"end":contour_distances[joint]+tangent,"center":center,"radius":radius,"angle":angle,"sweep":wrapf((exit-center).angle()-angle,-PI,PI)})
		contour_bands["window_bends"]=bends
	for bend in contour_bands["window_bends"]:
		if distance<float(bend.start) or distance>float(bend.end): continue
		var t:=inverse_lerp(float(bend.start),float(bend.end),distance)
		var angle: float=bend.angle+bend.sweep*t
		return PackedVector2Array([bend.center+Vector2(cos(angle),sin(angle))*float(bend.radius),Vector2(-sin(angle),cos(angle))*signf(float(bend.sweep))])
	for index in range(1,contour_path.size()):
		if distance>contour_distances[index] and index<contour_path.size()-1: continue
		var from:=contour_path[index-1]
		var to:=contour_path[index]
		var t:=inverse_lerp(contour_distances[index-1],contour_distances[index],distance)
		return PackedVector2Array([from.lerp(to,t),(to-from).normalized()])
	return PackedVector2Array([Vector2.ZERO,Vector2.RIGHT])

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
	if bottom_shape == "production_v":
		local_point = _contour_section(center_pct)[0]
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
	if bottom_shape == "production_v":
		_draw_production_progress()
		return
	if top_lip_height > 0.5 and bottom_radius > 0.5:
		_draw_bottom_round_style(Rect2(Vector2.ZERO, size), top_lip_color, bottom_radius)
	else:
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, top_lip_height)), top_lip_color)
	var track_rect := _activity_progress_track_rect()
	if top_lip_height <= 0.5:
		var radius := minf(track_rect.size.y * 0.5, bottom_radius)
		draw_rect(Rect2(track_rect.position + Vector2(radius, 0.0), Vector2(maxf(0.0, track_rect.size.x - radius * 2.0), track_rect.size.y)), top_lip_color)
		draw_circle(track_rect.position + Vector2(radius, radius), radius, top_lip_color)
		draw_circle(track_rect.position + Vector2(track_rect.size.x - radius, radius), radius, top_lip_color)
		var inner := track_rect.grow(-edge_inset)
		var inner_radius := minf(inner.size.y * 0.5, maxf(1.0, radius - edge_inset))
		draw_rect(Rect2(inner.position + Vector2(inner_radius, 0.0), Vector2(maxf(0.0, inner.size.x - inner_radius * 2.0), inner.size.y)), empty_color)
		draw_circle(inner.position + Vector2(inner_radius, inner_radius), inner_radius, empty_color)
		draw_circle(inner.position + Vector2(inner.size.x - inner_radius, inner_radius), inner_radius, empty_color)
		var fill_width := inner.size.x * clampf(value / 100.0, 0.0, 1.0)
		if fill_width > 0.0:
			var fill_rect := Rect2(inner.position, Vector2(fill_width, inner.size.y))
			_draw_round_fill(fill_rect, fill_color, 1.0)
		return
	if empty_segments.is_empty():
		_draw_bottom_round_style(track_rect, empty_color, maxf(0.0, bottom_radius - edge_inset))
	else:
		_draw_bottom_round_segments(track_rect, empty_segments, 1.0)
	var fill_pct := value / 100.0
	if fill_segments.is_empty():
		if fill_pct >= 0.999:
			_draw_bottom_round_style(track_rect, fill_color, maxf(0.0, bottom_radius - edge_inset))
		else:
			_draw_bottom_round_fill(track_rect, fill_color, fill_pct)
	else:
		_draw_bottom_round_segments(track_rect, fill_segments, fill_pct)


func _draw_production_progress() -> void:
	_draw_production_segment(top_lip_color, 0.0, 1.0, 0.0)
	var empty: Array = empty_segments if not empty_segments.is_empty() else [empty_color]
	var fills: Array = fill_segments if not fill_segments.is_empty() else [fill_color]
	for index in range(empty.size()):
		_draw_production_segment(empty[index], float(index)/empty.size(), float(index+1)/empty.size(), edge_inset)
	var progress := clampf(value/100.0, 0.0, 1.0)
	for index in range(fills.size()):
		var start := float(index)/fills.size()
		var finish := minf(progress, float(index+1)/fills.size())
		if finish > start: _draw_production_segment(fills[index], start, finish, edge_inset)

func _draw_production_segment(color: Color, start: float, finish: float, inset: float) -> void:
	var polygon := _production_band_polygon(start, finish, inset)
	if polygon.size() < 3: return
	draw_colored_polygon(polygon, color)
	polygon.append(polygon[0])
	draw_polyline(polygon, color, 1.0, true)

func _production_band_polygon(start: float, finish: float, inset := 0.0) -> PackedVector2Array:
	_ensure_contour_path()
	if not contour_bands.has(inset):
		contour_bands[inset] = _production_full_band_polygon(inset)
	return _contour_interval_polygon(contour_bands[inset], start, finish)

func _production_full_band_polygon(inset: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var lower := PackedVector2Array()
	if size.x <= 1.0: return points
	var samples: Array[float] = [0.0, 1.0]
	var shape = preload("res://scripts/ui/production_building_shape.gd")
	var min_x := edge_inset+inset
	var max_x := size.x-edge_inset-inset
	var inner_half: float = shape.NOTCH_HALF_WIDTH+shape.PROGRESS_BAND_HEIGHT*(sqrt(2.0)-1.0)
	for position_x in [size.x*0.5-inner_half,size.x*0.5-shape.NOTCH_HALF_WIDTH, size.x*0.5, size.x*0.5+shape.NOTCH_HALF_WIDTH,size.x*0.5+inner_half]:
		var special: float = (position_x-min_x)/(max_x-min_x)
		if special > 0.0 and special < 1.0: samples.append(special)
	for index in range(1, 192): samples.append(float(index)/192.0)
	samples.sort()
	for pct in samples:
		var x := lerpf(min_x, max_x, pct)
		if not points.is_empty() and absf(points[points.size()-1].x-x) < 0.001: continue
		var bounds := _production_band_bounds(x, inset)
		points.append(Vector2(x, bounds.x))
		lower.append(Vector2(x, bounds.y))
	for index in range(lower.size()-1, -1, -1): points.append(lower[index])
	return points

func _production_band_bounds(x: float, inset := 0.0) -> Vector2:
	var shape = preload("res://scripts/ui/production_building_shape.gd")
	var bottom: float = size.y-edge_inset-shape.NOTCH_DEPTH*maxf(0.0, 1.0-absf(x-size.x*0.5)/shape.NOTCH_HALF_WIDTH)
	# Offset the angled edges along their normals, not vertically. A 44px
	# vertical band would read only 31px thick on the 45-degree notch.
	var inner_depth: float = shape.NOTCH_DEPTH+shape.PROGRESS_BAND_HEIGHT*(sqrt(2.0)-1.0)
	var top: float = size.y-edge_inset-shape.PROGRESS_BAND_HEIGHT-maxf(0.0,inner_depth-absf(x-size.x*.5))
	var radius := maxf(0.0, bottom_radius-edge_inset)
	var edge := minf(x-edge_inset, size.x-edge_inset-x)
	if edge < radius:
		bottom = minf(bottom, size.y-edge_inset-radius+sqrt(maxf(0.0,radius*radius-pow(radius-edge,2))))
	return Vector2(top+inset, bottom-inset)

func _draw_bottom_round_style(rect: Rect2, color: Color, radius: float) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_bottom_left = int(round(radius))
	style.corner_radius_bottom_right = int(round(radius))
	style.anti_aliasing = true
	style.anti_aliasing_size = 1.5
	draw_style_box(style, rect)

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

func _draw_round_fill(rect: Rect2, color: Color, fill_pct: float) -> void:
	var pct := clampf(fill_pct, 0.0, 1.0)
	if pct <= 0.0 or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	_draw_round_segment(rect, color, 0.0, pct)

func _draw_round_segment(rect: Rect2, color: Color, start_pct: float, finish_pct: float) -> void:
	var start := clampf(start_pct, 0.0, 1.0)
	var finish := clampf(finish_pct, 0.0, 1.0)
	if finish <= start or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var row_count := _rounded_fill_row_count(rect)
	var row_height := rect.size.y / float(row_count)
	var raw_start_x := rect.position.x + rect.size.x * start
	var raw_finish_x := rect.position.x + rect.size.x * finish
	var radius := minf(bottom_radius, minf(rect.size.x, rect.size.y) * 0.5)
	var top_center_y := rect.position.y + radius
	var bottom_center_y := rect.end.y - radius
	for i in range(row_count):
		var y := rect.position.y + (float(i) + 0.5) * row_height
		var left_clip := rect.position.x
		var right_clip := rect.end.x
		if radius > 0.0 and y < top_center_y:
			var top_dy := top_center_y - y
			var top_inset := radius - sqrt(maxf(0.0, radius * radius - top_dy * top_dy))
			left_clip += top_inset
			right_clip -= top_inset
		elif radius > 0.0 and y > bottom_center_y:
			var bottom_dy := y - bottom_center_y
			var bottom_inset := radius - sqrt(maxf(0.0, radius * radius - bottom_dy * bottom_dy))
			left_clip += bottom_inset
			right_clip -= bottom_inset
		var line_left := maxf(left_clip, raw_start_x)
		var line_right := minf(right_clip, raw_finish_x)
		if line_right <= line_left:
			continue
		draw_line(Vector2(line_left, y), Vector2(line_right, y), color, row_height + 1.0, false)

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
	var width := maxf(36.0, minf(size.y * 0.90, 44.0))
	var outline_width := width + edge_inset * 2.0
	_draw_wide_u_progress_segment(top_lip_color, 0.0, 1.0, outline_width)
	_draw_wide_u_progress_segment(empty_color, 0.0, 1.0, width)
	if fill_pct > 0.0:
		_draw_wide_u_progress_segment(fill_color, 0.0, fill_pct, width)

func _draw_wide_u_progress_segment(color: Color, start_pct: float, finish_pct: float, stroke_width: float) -> void:
	var polygon := _wide_u_band_polygon(start_pct, finish_pct, stroke_width)
	if polygon.size() >= 3:
		draw_colored_polygon(polygon, color)
		polygon.append(polygon[0])
		draw_polyline(polygon, color, 1.0, true)

func _wide_u_band_polygon(start_pct: float, finish_pct: float, stroke_width: float) -> PackedVector2Array:
	_ensure_contour_path()
	if not contour_bands.has(stroke_width):
		contour_bands[stroke_width] = _wide_u_full_band_polygon(stroke_width)
	return _contour_interval_polygon(contour_bands[stroke_width], start_pct, finish_pct)

func _wide_u_full_band_polygon(stroke_width: float) -> PackedVector2Array:
	var top_points := PackedVector2Array()
	var bottom_points := PackedVector2Array()
	var steps := 192
	for index in range(steps + 1):
		var pct := float(index) / float(steps)
		var bounds := _wide_u_progress_band_bounds(pct, stroke_width)
		var x := lerpf(0.0, size.x, pct)
		top_points.append(Vector2(x, bounds.x))
		bottom_points.append(Vector2(x, bounds.y))
	var polygon := PackedVector2Array(top_points)
	for index in range(bottom_points.size() - 1, -1, -1):
		polygon.append(bottom_points[index])
	return polygon

# Progress measures distance along the middle of the rail. The moving edge is
# a cross-section normal to that path, clipped against the original silhouette.
# The same mapping positions production timing windows and their feedback.
func _ensure_contour_path() -> void:
	var key: Array = [size, bottom_shape, edge_inset, bottom_radius, wide_u_bottom_rise, wide_u_shoulder_ratio]
	if key == contour_cache_key: return
	contour_cache_key = key
	contour_bands.clear()
	contour_path.clear()
	contour_distances.clear()
	if bottom_shape == "production_v":
		var shape = preload("res://scripts/ui/production_building_shape.gd")
		var half_band: float = shape.PROGRESS_BAND_HEIGHT * 0.5
		var centre_y: float = size.y - edge_inset - half_band
		var half_notch: float = shape.NOTCH_HALF_WIDTH + half_band * (sqrt(2.0)-1.0)
		contour_path = PackedVector2Array([
			Vector2(edge_inset, centre_y), Vector2(size.x*.5-half_notch, centre_y),
			Vector2(size.x*.5, centre_y-half_notch),
			Vector2(size.x*.5+half_notch, centre_y), Vector2(size.x-edge_inset, centre_y)])
	else:
		var width := maxf(36.0, minf(size.y * .90, 44.0)) + edge_inset*2.0
		for index in range(193):
			var pct := float(index)/192.0
			# Ignore the rounded end caps when defining travel direction.
			var upper := _wide_u_progress_band_bounds(pct, width).x
			contour_path.append(Vector2(size.x*pct, upper+width*.5))
	var distance := 0.0
	for index in range(contour_path.size()):
		if index > 0: distance += contour_path[index-1].distance_to(contour_path[index])
		contour_distances.append(distance)

func _contour_section(progress: float) -> PackedVector2Array:
	_ensure_contour_path()
	var distance := clampf(progress, 0.0, 1.0)*contour_distances[-1]
	for index in range(1, contour_path.size()):
		if distance > contour_distances[index] and index < contour_path.size()-1: continue
		var from := contour_path[index-1]
		var to := contour_path[index]
		var weight := (distance-contour_distances[index-1])/maxf(.001, contour_distances[index]-contour_distances[index-1])
		var direction := (to-from).normalized()
		if bottom_shape == "production_v":
			# Turn through sharp joints over half a band on either side, rather
			# than snapping the leading edge when it reaches a diamond corner.
			for joint in range(1, contour_path.size()-1):
				var delta := distance-contour_distances[joint]
				if absf(delta) > 22.0: continue
				var incoming := (contour_path[joint]-contour_path[joint-1]).normalized()
				var outgoing := (contour_path[joint+1]-contour_path[joint]).normalized()
				direction = incoming.lerp(outgoing, smoothstep(-22.0, 22.0, delta)).normalized()
				break
		return PackedVector2Array([from.lerp(to, weight), direction])
	return PackedVector2Array([Vector2.ZERO, Vector2.RIGHT])

func _contour_interval_polygon(polygon: PackedVector2Array, start: float, finish: float) -> PackedVector2Array:
	if finish <= start: return PackedVector2Array()
	var result := polygon
	if start > 0.0:
		var section := _contour_section(start)
		result = _clip_contour_polygon(result, section[0], -section[1])
	if finish < 1.0:
		var section := _contour_section(finish)
		result = _clip_contour_polygon(result, section[0], section[1])
	return result

func _clip_contour_polygon(polygon: PackedVector2Array, origin: Vector2, direction: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array()
	if polygon.is_empty(): return result
	var previous := polygon[-1]
	var previous_distance := (previous-origin).dot(direction)
	for point in polygon:
		var distance := (point-origin).dot(direction)
		if (distance <= 0.0) != (previous_distance <= 0.0):
			result.append(previous.lerp(point, previous_distance/(previous_distance-distance)))
		if distance <= 0.0: result.append(point)
		previous = point
		previous_distance = distance
	return result

func _wide_u_progress_band_bounds(pct: float, stroke_width: float) -> Vector2:
	var outer_width := maxf(36.0, minf(size.y * 0.90, 44.0)) + edge_inset * 2.0
	var layer_inset := maxf(0.0, (outer_width - stroke_width) * 0.5)
	var progress := clampf(pct, 0.0, 1.0)
	var x := lerpf(0.0, size.x, progress)
	var side_bottom := maxf(outer_width, size.y - wide_u_bottom_rise)
	var shoulder := clampf(wide_u_shoulder_ratio, 0.0, 0.49)
	var curve_progress := clampf((progress - shoulder) / maxf(0.01, 1.0 - shoulder * 2.0), 0.0, 1.0)
	var curve_weight := sin(curve_progress * PI)
	var base_bottom := lerpf(side_bottom, size.y, curve_weight * curve_weight)
	var rounded_bottom := base_bottom
	var corner_radius := minf(bottom_radius, size.x * 0.5)
	if x < corner_radius:
		var corner_x := x - corner_radius
		rounded_bottom = side_bottom - corner_radius + sqrt(maxf(0.0, corner_radius * corner_radius - corner_x * corner_x))
	elif x > size.x - corner_radius:
		var corner_x := x - (size.x - corner_radius)
		rounded_bottom = side_bottom - corner_radius + sqrt(maxf(0.0, corner_radius * corner_radius - corner_x * corner_x))
	return Vector2(base_bottom - outer_width + layer_inset, rounded_bottom - layer_inset)


func _wide_u_progress_point(pct: float, stroke_width: float) -> Vector2:
	var bounds := _wide_u_progress_band_bounds(pct, stroke_width)
	return Vector2(lerpf(0.0, size.x, clampf(pct, 0.0, 1.0)), (bounds.x + bounds.y) * 0.5)

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



