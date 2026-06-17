class_name ActivityCardBorder
extends Control


const FAST_ARC_SEGMENTS := 8

var border_color := Color("#171615")
var border_width := 8.0
var radius := 66.0

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	var half := border_width * 0.5
	var left := half
	var right := maxf(half, size.x - half)
	var top := half
	var bottom := maxf(half, size.y - half)
	var r := maxf(0.0, minf(radius, minf(size.x, size.y) * 0.5 - half))
	var points := PackedVector2Array()
	points.append(Vector2(left + r, top))
	points.append(Vector2(right - r, top))
	_append_arc_points(points, Vector2(right - r, top + r), r, -PI * 0.5, 0.0)
	points.append(Vector2(right, bottom - r))
	_append_arc_points(points, Vector2(right - r, bottom - r), r, 0.0, PI * 0.5)
	points.append(Vector2(left + r, bottom))
	_append_arc_points(points, Vector2(left + r, bottom - r), r, PI * 0.5, PI)
	points.append(Vector2(left, top + r))
	_append_arc_points(points, Vector2(left + r, top + r), r, PI, PI * 1.5)
	if not points.is_empty():
		points.append(points[0])
		draw_polyline(points, border_color, border_width, true)

func _append_arc_points(points: PackedVector2Array, center: Vector2, arc_radius: float, start_angle: float, end_angle: float) -> void:
	for i in range(1, FAST_ARC_SEGMENTS + 1):
		var t := float(i) / float(FAST_ARC_SEGMENTS)
		var angle := lerpf(start_angle, end_angle, t)
		points.append(center + Vector2(cos(angle), sin(angle)) * arc_radius)
