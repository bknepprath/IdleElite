extends Control


var side := ""
var ink_color := Color("#171615")
var side_fill_color := Color("#8f521f")
var bottom_fill_color := Color("#c8792c")
var stroke_width := 7.0
var radius := 66.0
var diagonal_radius := 32.0
var diagonal_width := 96.0
var arrow_edge_width := 76.0
var arrow_corner_radius := 26.0
var depth_offset := Vector2.ZERO
var face_offset := Vector2.ZERO
var face_gutter := 0.0
var face_bottom_inset := 0.0
var draw_fill := true
var draw_strokes := true

func set_face_offset(next_offset: Vector2) -> void:
	var clamped_offset := Vector2(
		clampf(next_offset.x, 0.0, maxf(0.0, depth_offset.x)),
		clampf(next_offset.y, 0.0, maxf(0.0, depth_offset.y))
	)
	if face_offset.is_equal_approx(clamped_offset):
		return
	face_offset = clamped_offset
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	var face_size := _connector_face_size()
	if face_size.x <= 1.0 or face_size.y <= 1.0:
		return
	var travel := depth_offset - face_offset
	if travel.length_squared() <= 0.25:
		return
	var points := _connector_points()
	if points.size() != 2:
		return
	if draw_fill:
		_draw_side_faces(travel)
	if draw_strokes:
		_draw_side_face_outlines(travel)
		_draw_connector_stroke(points[0], travel)
		_draw_connector_stroke(points[1], travel)

func _connector_points() -> PackedVector2Array:
	if side.is_empty():
		return _rounded_rect_connector_points()
	var shape_points := _diagonal_shape_points()
	if shape_points.size() < 3:
		return PackedVector2Array()
	return _diagonal_connector_points(shape_points)

func _diagonal_connector_points(_points: PackedVector2Array) -> PackedVector2Array:
	var origin := _connector_face_origin()
	var top_right := _extreme_shape_point(_points, Vector2(1.0, -1.0))
	var bottom_left := _extreme_shape_point(_points, Vector2(-1.0, 1.0))
	return PackedVector2Array([
		origin + top_right,
		origin + bottom_left,
	])

func _draw_connector_stroke(start: Vector2, travel: Vector2) -> void:
	var direction := travel.normalized() if travel.length_squared() > 0.01 else Vector2.ZERO
	draw_line(start - direction * 1.5, start + travel + direction * 2.0, ink_color, stroke_width, true)

func _diagonal_corner_inset(current: Vector2, previous: Vector2, next: Vector2) -> float:
	var incoming := previous - current
	var outgoing := next - current
	if incoming.length_squared() <= 0.01 or outgoing.length_squared() <= 0.01:
		return 0.0
	var max_radius := minf(incoming.length(), outgoing.length()) * 0.46
	return clampf(diagonal_radius, 0.0, max_radius)

func _rounded_rect_connector_points() -> PackedVector2Array:
	var origin := _connector_face_origin()
	var face_size := _connector_face_size()
	if face_size.x <= stroke_width or face_size.y <= stroke_width:
		return PackedVector2Array()
	var half := stroke_width * 0.5
	var corner_bias := maxf(half, minf(radius * 0.18, minf(face_size.x, face_size.y) * 0.08))
	var top_right := origin + Vector2(face_size.x - corner_bias, corner_bias)
	var bottom_left := origin + Vector2(corner_bias, face_size.y - corner_bias)
	return PackedVector2Array([top_right, bottom_left])

func _diagonal_shape_points() -> PackedVector2Array:
	var face_size := _connector_face_size()
	var w := face_size.x
	var h := face_size.y
	var arrow := minf(arrow_edge_width, w * 0.34)
	var vertices := PackedVector2Array()
	if side == "right":
		vertices.append(Vector2(0.0, h * 0.5))
		vertices.append(Vector2(arrow, 0.0))
		vertices.append(Vector2(w, 0.0))
		vertices.append(Vector2(w, h))
		vertices.append(Vector2(arrow, h))
	else:
		vertices.append(Vector2(0.0, 0.0))
		vertices.append(Vector2(w - arrow, 0.0))
		vertices.append(Vector2(w, h * 0.5))
		vertices.append(Vector2(w - arrow, h))
		vertices.append(Vector2(0.0, h))
	return _rounded_polygon(vertices)

func _draw_side_faces(travel: Vector2) -> void:
	var points := _diagonal_shape_points() if not side.is_empty() else _rounded_rect_shape_points()
	if points.size() < 3:
		return
	var origin := _connector_face_origin()
	for index in range(points.size()):
		var p0 := points[index]
		var p1 := points[(index + 1) % points.size()]
		var normal := _edge_outward_normal(p0, p1)
		if not _side_face_visible(normal, travel):
			continue
		var face := PackedVector2Array([
			origin + p0,
			origin + p1,
			origin + p1 + travel,
			origin + p0 + travel,
		])
		draw_polygon(face, PackedColorArray([_side_face_color(normal)]))

func _draw_side_face_outlines(travel: Vector2) -> void:
	var points := _diagonal_shape_points() if not side.is_empty() else _rounded_rect_shape_points()
	if points.size() < 3:
		return
	var origin := _connector_face_origin()
	var outline := PackedVector2Array()
	for index in range(points.size()):
		var p0 := points[index]
		var p1 := points[(index + 1) % points.size()]
		var normal := _edge_outward_normal(p0, p1)
		if not _side_face_visible(normal, travel):
			if outline.size() > 1:
				draw_polyline(outline, ink_color, stroke_width, true)
			outline = PackedVector2Array()
			continue
		var back_start := origin + p0 + travel
		var back_finish := origin + p1 + travel
		if outline.is_empty():
			outline.append(back_start)
		outline.append(back_finish)
	if outline.size() > 1:
		draw_polyline(outline, ink_color, stroke_width, true)

func _rounded_rect_shape_points() -> PackedVector2Array:
	var face_size := _connector_face_size()
	return _rounded_polygon(PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(face_size.x, 0.0),
		Vector2(face_size.x, face_size.y),
		Vector2(0.0, face_size.y),
	]))

func _edge_outward_normal(p0: Vector2, p1: Vector2) -> Vector2:
	var edge := p1 - p0
	if edge.length_squared() <= 0.001:
		return Vector2.ZERO
	return Vector2(edge.y, -edge.x).normalized()

func _side_face_visible(normal: Vector2, travel: Vector2) -> bool:
	if normal.length_squared() <= 0.001 or normal.dot(travel) <= 0.15:
		return false
	return normal.x > 0.08 or normal.y > 0.56

func _side_face_color(normal: Vector2) -> Color:
	var positive_x := maxf(0.0, normal.x)
	var positive_y := maxf(0.0, normal.y)
	var bottom_weight := positive_y / maxf(0.001, positive_x + positive_y)
	return side_fill_color.lerp(bottom_fill_color, bottom_weight)

func _connector_face_origin() -> Vector2:
	return Vector2(face_gutter, 0.0) + face_offset

func _connector_face_size() -> Vector2:
	return Vector2(
		maxf(0.0, size.x - face_gutter * 2.0),
		maxf(0.0, size.y - face_bottom_inset)
	)

func _rounded_polygon(vertices: PackedVector2Array) -> PackedVector2Array:
	var rounded := PackedVector2Array()
	var count := vertices.size()
	if count < 3:
		return rounded
	for index in range(count):
		var previous := vertices[(index - 1 + count) % count]
		var current := vertices[index]
		var next := vertices[(index + 1) % count]
		var incoming := previous - current
		var outgoing := next - current
		if incoming.length_squared() <= 0.01 or outgoing.length_squared() <= 0.01:
			_append_unique_shape_point(rounded, current)
			continue
		var corner_radius := _corner_radius(index)
		var max_radius := minf(incoming.length(), outgoing.length()) * 0.46
		var r := clampf(corner_radius, 0.0, max_radius)
		var start := current + incoming.normalized() * r
		var finish := current + outgoing.normalized() * r
		_append_unique_shape_point(rounded, start)
		for step in range(1, 8):
			var t := float(step) / 8.0
			var a := start.lerp(current, t)
			var b := current.lerp(finish, t)
			_append_unique_shape_point(rounded, a.lerp(b, t))
		_append_unique_shape_point(rounded, finish)
	return rounded

func _is_diagonal_corner(index: int) -> bool:
	if side == "right":
		return index == 2 or index == 3
	return index == 0 or index == 4

func _corner_radius(index: int) -> float:
	if not side.is_empty():
		return arrow_corner_radius
	if _is_diagonal_corner(index):
		return diagonal_radius
	return radius

func _extreme_shape_point(points: PackedVector2Array, direction: Vector2) -> Vector2:
	var best := points[0]
	var best_score := best.dot(direction)
	for point in points:
		var score := point.dot(direction)
		if score > best_score:
			best = point
			best_score = score
	return best

func _append_unique_shape_point(points: PackedVector2Array, point: Vector2) -> void:
	if points.is_empty() or points[points.size() - 1].distance_squared_to(point) > 0.01:
		points.append(point)
