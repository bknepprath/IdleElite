class_name ActivityCardDepth
extends Control

const DEFAULT_RADIUS := 66.0
const FAST_DEPTH_SHAPE_ENABLED := true

var depth_offset := Vector2(36.0, 40.0)
var face_offset := Vector2.ZERO
var radius := DEFAULT_RADIUS
var back_color := Color("#a45f25")
var side_color := Color("#8f521f")
var bottom_color := Color("#c8792c")
var lip_color := Color("#171615")
var highlight_color := Color(1.0, 0.73, 0.36, 0.22)
var shadow_color := Color(0.06, 0.045, 0.03, 0.32)
var segment_theme_colors: Array[Color] = []

func set_face_offset(next_offset: Vector2) -> void:
	var clamped_offset := Vector2(
		clampf(next_offset.x, 0.0, maxf(0.0, depth_offset.x)),
		clampf(next_offset.y, 0.0, maxf(0.0, depth_offset.y))
	)
	if face_offset.is_equal_approx(clamped_offset):
		return
	face_offset = clamped_offset
	queue_redraw()

func set_segment_theme_colors(next_colors: Array) -> void:
	var normalized: Array[Color] = []
	for raw_color in next_colors:
		if raw_color is Color:
			normalized.append(raw_color as Color)
	if _color_arrays_equal(segment_theme_colors, normalized):
		return
	segment_theme_colors = normalized
	queue_redraw()

func _color_arrays_equal(current: Array[Color], next: Array[Color]) -> bool:
	if current.size() != next.size():
		return false
	for index in range(current.size()):
		if not (current[index] as Color).is_equal_approx(next[index] as Color):
			return false
	return true

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	if size.x <= depth_offset.x + 2.0 or size.y <= depth_offset.y + 2.0:
		return
	var face_size := Vector2(size.x - depth_offset.x, size.y - depth_offset.y)
	var front := Vector2(
		clampf(face_offset.x, 0.0, depth_offset.x),
		clampf(face_offset.y, 0.0, depth_offset.y)
	)
	var back := depth_offset
	if FAST_DEPTH_SHAPE_ENABLED:
		_draw_fast_depth(face_size, front, back)
		return
	_draw_soft_floor_shadow(face_size, back)
	_draw_back_plate(face_size, back)
	var perimeter := _rounded_rect_points(Rect2(Vector2.ZERO, face_size), 18)
	_draw_extruded_faces(perimeter, front, back, face_size)
	_draw_back_plate_outline(face_size, back)
	_draw_extruded_outline(perimeter, front, back, face_size)

func _draw_fast_depth(face_size: Vector2, front: Vector2, back: Vector2) -> void:
	_draw_soft_floor_shadow(face_size, back)
	_draw_fast_back_plate(face_size, back)
	_draw_depth_corner_connectors(face_size, front, back)
	_draw_rounded_rect_outline(Rect2(back, face_size), lip_color, 7.0)

func _draw_depth_corner_connectors(face_size: Vector2, front: Vector2, back: Vector2) -> void:
	var width := 7.0
	var points := _depth_corner_connector_points(face_size, front, back, width)
	if points.size() != 4:
		return
	draw_line(points[0], points[1], lip_color, width, true)
	draw_line(points[2], points[3], lip_color, width, true)

func _depth_corner_connector_points(face_size: Vector2, front: Vector2, back: Vector2, width: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	if face_size.x <= width or face_size.y <= width:
		return points
	var half := width * 0.5
	var r := maxf(0.0, minf(radius, minf(face_size.x, face_size.y) * 0.5 - half))
	var diagonal := sqrt(0.5)
	var top_right_unit := Vector2(diagonal, -diagonal)
	var bottom_left_unit := Vector2(-diagonal, diagonal)
	var front_left := front.x + half
	var front_right := front.x + face_size.x - half
	var front_top := front.y + half
	var front_bottom := front.y + face_size.y - half
	var back_left := back.x + half
	var back_right := back.x + face_size.x - half
	var back_top := back.y + half
	var back_bottom := back.y + face_size.y - half
	var front_top_right := Vector2(front_right - r, front_top + r) + top_right_unit * r
	var back_top_right := Vector2(back_right - r, back_top + r) + top_right_unit * r
	var front_bottom_left := Vector2(front_left + r, front_bottom - r) + bottom_left_unit * r
	var back_bottom_left := Vector2(back_left + r, back_bottom - r) + bottom_left_unit * r
	points.append(front_top_right)
	points.append(back_top_right)
	points.append(front_bottom_left)
	points.append(back_bottom_left)
	return points

func _draw_fast_back_plate(face_size: Vector2, back: Vector2) -> void:
	var rect := Rect2(back, face_size)
	if segment_theme_colors.size() > 1:
		_draw_fast_segmented_back_plate(rect)
		return
	_draw_fast_round_rect(rect, back_color, radius)

func _draw_fast_segmented_back_plate(rect: Rect2) -> void:
	var count := segment_theme_colors.size()
	if count <= 1:
		_draw_fast_round_rect(rect, back_color, radius)
		return
	_draw_fast_round_rect(rect, _segment_depth_back_color(segment_theme_colors[0] as Color), radius)
	var segment_width := rect.size.x / float(count)
	var front_left := rect.position.x - maxf(0.0, depth_offset.x)
	for index in range(1, count):
		var color := _segment_depth_back_color(segment_theme_colors[index] as Color)
		var start_x := front_left + segment_width * float(index)
		var finish_x := front_left + segment_width * float(index + 1)
		if index == count - 1:
			finish_x = rect.end.x
		_draw_fast_round_rect_depth_segment(rect, start_x, finish_x, color, radius)

func _draw_fast_round_rect_depth_segment(full_rect: Rect2, start_x: float, finish_x: float, color: Color, corner_radius: float) -> void:
	var r := _fast_round_rect_radius(full_rect, corner_radius)
	var row_count := maxi(18, mini(72, int(ceil(full_rect.size.y / 3.0))))
	var row_height := full_rect.size.y / float(row_count)
	var corner_center_top := full_rect.position.y + r
	var corner_center_bottom := full_rect.end.y - r
	var depth_slant := maxf(0.0, depth_offset.x)
	var visible_depth_top := full_rect.end.y - maxf(1.0, depth_offset.y)
	for row in range(row_count):
		var y := full_rect.position.y + (float(row) + 0.5) * row_height
		var vertical_t := clampf((y - visible_depth_top) / maxf(1.0, depth_offset.y), 0.0, 1.0)
		var slant_offset := depth_slant * vertical_t
		var left_clip := full_rect.position.x
		var right_clip := full_rect.end.x
		if r > 0.0:
			if y < corner_center_top:
				var dy_top := y - corner_center_top
				var inset_top := r - sqrt(maxf(0.0, r * r - dy_top * dy_top))
				left_clip += inset_top
				right_clip -= inset_top
			elif y > corner_center_bottom:
				var dy_bottom := y - corner_center_bottom
				var inset_bottom := r - sqrt(maxf(0.0, r * r - dy_bottom * dy_bottom))
				left_clip += inset_bottom
				right_clip -= inset_bottom
		var line_left := maxf(left_clip, start_x + slant_offset)
		var line_right := minf(right_clip, finish_x + slant_offset)
		if line_right <= line_left:
			continue
		draw_line(Vector2(line_left, y), Vector2(line_right, y), color, row_height + 1.0, false)

func _draw_fast_round_rect_clipped(full_rect: Rect2, clip_rect: Rect2, color: Color, corner_radius: float) -> void:
	var r := _fast_round_rect_radius(full_rect, corner_radius)
	var row_count := maxi(18, mini(72, int(ceil(full_rect.size.y / 3.0))))
	var row_height := full_rect.size.y / float(row_count)
	var corner_center_top := full_rect.position.y + r
	var corner_center_bottom := full_rect.end.y - r
	for row in range(row_count):
		var y := full_rect.position.y + (float(row) + 0.5) * row_height
		var left_clip := full_rect.position.x
		var right_clip := full_rect.end.x
		if r > 0.0:
			if y < corner_center_top:
				var dy_top := y - corner_center_top
				var inset_top := r - sqrt(maxf(0.0, r * r - dy_top * dy_top))
				left_clip += inset_top
				right_clip -= inset_top
			elif y > corner_center_bottom:
				var dy_bottom := y - corner_center_bottom
				var inset_bottom := r - sqrt(maxf(0.0, r * r - dy_bottom * dy_bottom))
				left_clip += inset_bottom
				right_clip -= inset_bottom
		var line_left := maxf(left_clip, clip_rect.position.x)
		var line_right := minf(right_clip, clip_rect.end.x)
		if line_right <= line_left:
			continue
		draw_line(Vector2(line_left, y), Vector2(line_right, y), color, row_height + 1.0, false)

func _segment_depth_back_color(theme_color: Color) -> Color:
	return theme_color.darkened(0.36)

func _draw_fast_round_rect(rect: Rect2, color: Color, corner_radius: float) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var r := _fast_round_rect_radius(rect, corner_radius)
	if r <= 0.5:
		draw_rect(rect, color)
		return
	draw_rect(Rect2(rect.position + Vector2(r, 0.0), Vector2(maxf(0.0, rect.size.x - r * 2.0), rect.size.y)), color)
	draw_rect(Rect2(rect.position + Vector2(0.0, r), Vector2(rect.size.x, maxf(0.0, rect.size.y - r * 2.0))), color)
	draw_circle(rect.position + Vector2(r, r), r, color)
	draw_circle(rect.position + Vector2(rect.size.x - r, r), r, color)
	draw_circle(rect.position + Vector2(rect.size.x - r, rect.size.y - r), r, color)
	draw_circle(rect.position + Vector2(r, rect.size.y - r), r, color)

func _fast_round_rect_radius(rect: Rect2, corner_radius: float) -> float:
	return maxf(0.0, minf(corner_radius, minf(rect.size.x, rect.size.y) * 0.5))

func _draw_back_plate(face_size: Vector2, back: Vector2) -> void:
	var style := _rounded_body_style(back_color, lip_color, 0, face_size)
	draw_style_box(style, Rect2(back, face_size))

func _draw_back_plate_outline(face_size: Vector2, back: Vector2) -> void:
	_draw_rounded_rect_outline(Rect2(back, face_size), lip_color, 7.0)

func _draw_extruded_faces(perimeter: PackedVector2Array, front: Vector2, back: Vector2, face_size: Vector2) -> void:
	var travel := back - front
	if travel.length_squared() <= 1.0 or perimeter.size() < 2:
		return
	for i in range(perimeter.size()):
		var p0 := perimeter[i]
		var p1 := perimeter[(i + 1) % perimeter.size()]
		var normal := _edge_outward_normal(p0, p1)
		if not _depth_edge_visible(normal, travel, p0, p1, face_size):
			continue
		var face := PackedVector2Array([
			front + p0,
			front + p1,
			_depth_back_point(p1, front, back, face_size),
			_depth_back_point(p0, front, back, face_size),
		])
		draw_polygon(face, PackedColorArray([_depth_face_color(normal)]))

func _draw_extruded_outline(perimeter: PackedVector2Array, front: Vector2, back: Vector2, face_size: Vector2) -> void:
	var travel := back - front
	if travel.length_squared() <= 1.0 or perimeter.size() < 2:
		return
	var visible := []
	for i in range(perimeter.size()):
		var p0 := perimeter[i]
		var p1 := perimeter[(i + 1) % perimeter.size()]
		visible.append(_depth_edge_visible(_edge_outward_normal(p0, p1), travel, p0, p1, face_size))
	var current_path := PackedVector2Array()
	for i in range(perimeter.size()):
		var p0 := perimeter[i]
		var p1 := perimeter[(i + 1) % perimeter.size()]
		if bool(visible[i]):
			if current_path.is_empty():
				current_path.append(_depth_back_point(p0, front, back, face_size))
				var prev_index := (i - 1 + perimeter.size()) % perimeter.size()
				if not bool(visible[prev_index]):
					_draw_depth_cap_line(p0, front, back, face_size)
			current_path.append(_depth_back_point(p1, front, back, face_size))
			var next_index := (i + 1) % perimeter.size()
			if not bool(visible[next_index]):
				_draw_visible_outline_path(current_path)
				current_path = PackedVector2Array()
				_draw_depth_cap_line(p1, front, back, face_size)
		elif not current_path.is_empty():
			_draw_visible_outline_path(current_path)
			current_path = PackedVector2Array()
	if not current_path.is_empty():
		_draw_visible_outline_path(current_path)

func _draw_visible_outline_path(path: PackedVector2Array) -> void:
	if path.size() < 2:
		return
	draw_polyline(path, lip_color, 7.0, true)

func _draw_depth_cap_line(point: Vector2, front: Vector2, back: Vector2, face_size: Vector2) -> void:
	if not _depth_cap_should_draw(point, face_size):
		return
	draw_line(front + point, _depth_back_point(point, front, back, face_size), lip_color, 7.0, true)

func _edge_outward_normal(p0: Vector2, p1: Vector2) -> Vector2:
	var edge := p1 - p0
	if edge.length_squared() <= 0.001:
		return Vector2.ZERO
	return Vector2(edge.y, -edge.x).normalized()

func _depth_edge_visible(normal: Vector2, travel: Vector2, _p0: Vector2, _p1: Vector2, _face_size: Vector2) -> bool:
	if normal.length_squared() <= 0.001 or normal.dot(travel) <= 0.15:
		return false
	return normal.x > 0.08 or normal.y > 0.56

func _depth_cap_should_draw(point: Vector2, face_size: Vector2) -> bool:
	return point.x >= face_size.x - radius * 0.68 or point.y <= radius * 0.68

func _depth_back_point(point: Vector2, _front: Vector2, back: Vector2, _face_size: Vector2) -> Vector2:
	return back + point

func _depth_face_color(normal: Vector2) -> Color:
	var positive_x := maxf(0.0, normal.x)
	var positive_y := maxf(0.0, normal.y)
	var bottom_weight := positive_y / maxf(0.001, positive_x + positive_y)
	return side_color.lerp(bottom_color, bottom_weight)

func _rounded_rect_points(rect: Rect2, corner_segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var left := rect.position.x
	var right := rect.position.x + rect.size.x
	var top := rect.position.y
	var bottom := rect.position.y + rect.size.y
	_append_unique_point(points, Vector2(left + r, top))
	_append_unique_point(points, Vector2(right - r, top))
	_append_arc_points(points, Vector2(right - r, top + r), r, -PI * 0.5, 0.0, corner_segments)
	_append_unique_point(points, Vector2(right, bottom - r))
	_append_arc_points(points, Vector2(right - r, bottom - r), r, 0.0, PI * 0.5, corner_segments)
	_append_unique_point(points, Vector2(left + r, bottom))
	_append_arc_points(points, Vector2(left + r, bottom - r), r, PI * 0.5, PI, corner_segments)
	_append_unique_point(points, Vector2(left, top + r))
	_append_arc_points(points, Vector2(left + r, top + r), r, PI, PI * 1.5, corner_segments)
	return points

func _append_arc_points(points: PackedVector2Array, center: Vector2, arc_radius: float, start_angle: float, end_angle: float, segments: int) -> void:
	var safe_segments := maxi(1, segments)
	for i in range(safe_segments + 1):
		var t := float(i) / float(safe_segments)
		var angle := lerpf(start_angle, end_angle, t)
		_append_unique_point(points, center + Vector2(cos(angle), sin(angle)) * arc_radius)

func _append_unique_point(points: PackedVector2Array, point: Vector2) -> void:
	if not points.is_empty() and points[points.size() - 1].distance_squared_to(point) <= 0.01:
		return
	points.append(point)

func _rounded_body_style(fill: Color, border: Color, border_width: int, face_size: Vector2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	if border_width > 0:
		style.set_border_width_all(border_width)
	var corner := int(round(minf(radius, minf(face_size.x, face_size.y) * 0.5)))
	style.set_corner_radius_all(corner)
	return style

func _draw_polygon_outline(points: PackedVector2Array, color: Color, width: float) -> void:
	if points.size() < 2:
		return
	var closed := PackedVector2Array(points)
	closed.append(points[0])
	draw_polyline(closed, color, width, true)

func _draw_rounded_rect_outline(rect: Rect2, color: Color, width: float) -> void:
	var half := width * 0.5
	var left := rect.position.x + half
	var right := rect.position.x + rect.size.x - half
	var top := rect.position.y + half
	var bottom := rect.position.y + rect.size.y - half
	var r := maxf(0.0, minf(radius, minf(rect.size.x, rect.size.y) * 0.5 - half))
	draw_line(Vector2(left + r, top), Vector2(right - r, top), color, width, true)
	draw_line(Vector2(left + r, bottom), Vector2(right - r, bottom), color, width, true)
	draw_line(Vector2(left, top + r), Vector2(left, bottom - r), color, width, true)
	draw_line(Vector2(right, top + r), Vector2(right, bottom - r), color, width, true)
	draw_arc(Vector2(left + r, top + r), r, PI, PI * 1.5, 8, color, width, true)
	draw_arc(Vector2(right - r, top + r), r, PI * 1.5, PI * 2.0, 8, color, width, true)
	draw_arc(Vector2(right - r, bottom - r), r, 0.0, PI * 0.5, 8, color, width, true)
	draw_arc(Vector2(left + r, bottom - r), r, PI * 0.5, PI, 8, color, width, true)

func _draw_soft_floor_shadow(face_size: Vector2, back: Vector2) -> void:
	var r := minf(radius, minf(face_size.x, face_size.y) * 0.5)
	var left := back.x + r * 0.58
	var right := back.x + face_size.x - r * 0.48
	var start_y := back.y + face_size.y - 5.0
	for i in range(4):
		var t := float(i) / 3.0
		var alpha := shadow_color.a * pow(1.0 - t, 1.8)
		draw_line(
			Vector2(left + t * 16.0, start_y + t * 7.0),
			Vector2(right - t * 22.0, start_y + t * 7.0),
			Color(shadow_color.r, shadow_color.g, shadow_color.b, alpha),
			3.0,
			true
		)



