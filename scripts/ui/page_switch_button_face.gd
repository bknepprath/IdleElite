extends Control


var side := ""
var fill_color := Color("#32c5bd")
var ink_color := Color("#171615")
var stroke_width := 10.0
var radius := 66.0
var diagonal_radius := 32.0
var diagonal_width := 96.0
var arrow_edge_width := 76.0
var arrow_corner_radius := 26.0
var draw_fill := true
var draw_stroke := true
var draw_depth_connectors := false
var depth_offset := Vector2.ZERO
var face_offset := Vector2.ZERO

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
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var points := _shape_points()
	if points.size() < 3:
		return
	if draw_fill:
		draw_polygon(points, PackedColorArray([fill_color]))
	if draw_depth_connectors:
		_draw_depth_connectors(points)
	if draw_stroke:
		var closed := PackedVector2Array(points)
		closed.append(points[0])
		draw_polyline(closed, ink_color, stroke_width, true)

func _draw_depth_connectors(points: PackedVector2Array) -> void:
	var connector_offset := face_offset - depth_offset
	if connector_offset.length_squared() <= 0.25:
		return
	var width := maxf(3.0, stroke_width * 0.72)
	var top_right := _extreme_shape_point(points, 1.0)
	var bottom_left := _extreme_shape_point(points, -1.0)
	draw_line(top_right + connector_offset, top_right, ink_color, width, true)
	draw_line(bottom_left + connector_offset, bottom_left, ink_color, width, true)

func _extreme_shape_point(points: PackedVector2Array, direction: float) -> Vector2:
	var best := points[0]
	var best_score := direction * (best.x - best.y)
	for point in points:
		var score := direction * (point.x - point.y)
		if score > best_score:
			best = point
			best_score = score
	return best

func _shape_points() -> PackedVector2Array:
	var w := size.x
	var h := size.y
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

func _append_unique_shape_point(points: PackedVector2Array, point: Vector2) -> void:
	if points.is_empty() or points[points.size() - 1].distance_squared_to(point) > 0.01:
		points.append(point)
