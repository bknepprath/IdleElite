class_name DiamondArenaFrame
extends Control

var fill_color := Color(0.16, 0.08, 0.08, 0.16)
var border_color := Color("#171615")
var accent_color := Color("#ffe56b")
var ui_plate_color := Color("#8e1115")
var border_width := 12.0
var accent_width := 5.0
var inset := 12.0
var side_inset := 16.0


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	if size.x <= 4.0 or size.y <= 4.0:
		return
	var diamond := _rounded_diamond_points(_diamond_points(), 72.0, 10)
	var top := diamond[0]
	var closed := PackedVector2Array(diamond)
	closed.append(top)
	draw_polyline(closed, border_color, border_width, true)


func _diamond_points(extra_inset := 0.0) -> PackedVector2Array:
	var safe_inset := maxf(0.0, inset + extra_inset)
	var safe_side_inset := maxf(0.0, side_inset + extra_inset)
	var center := size * 0.5
	return PackedVector2Array([
		Vector2(center.x, safe_inset),
		Vector2(size.x - safe_side_inset, center.y),
		Vector2(center.x, size.y - safe_inset),
		Vector2(safe_side_inset, center.y),
	])


func _rounded_diamond_points(points: PackedVector2Array, corner_radius: float, segments: int) -> PackedVector2Array:
	var rounded := PackedVector2Array()
	if points.size() < 4:
		return points
	var safe_segments := maxi(2, segments)
	for i in range(points.size()):
		var previous := points[(i - 1 + points.size()) % points.size()]
		var corner := points[i]
		var next := points[(i + 1) % points.size()]
		var cut := minf(corner_radius, minf(corner.distance_to(previous), corner.distance_to(next)) * 0.34)
		var start := corner.move_toward(previous, cut)
		var finish := corner.move_toward(next, cut)
		for step in range(safe_segments + 1):
			var t := float(step) / float(safe_segments)
			var a := start.lerp(corner, t)
			var b := corner.lerp(finish, t)
			rounded.append(a.lerp(b, t))
	return rounded
