class_name OrganicLeaderboardBorder
extends Control


var border_color := Color("#77c9ff")
var paper_color := Color("#f8f1e5")

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	if size.x <= 220.0 or size.y <= 320.0:
		return
	draw_rect(Rect2(Vector2.ZERO, size), border_color)
	var paper_shape := _inner_paper_shape()
	draw_polygon(paper_shape, PackedColorArray([paper_color]))
	var paper_edge := PackedVector2Array(paper_shape)
	if not paper_edge.is_empty():
		paper_edge.append(paper_edge[0])
		draw_polyline(paper_edge, paper_color, 86.0, true)

func _inner_paper_shape() -> PackedVector2Array:
	var points := []
	var left_top_side := Vector2(104.0, 520.0)
	var top_left := Vector2(238.0, 270.0)
	var top_mid := Vector2(size.x * 0.50, 246.0)
	var top_right := Vector2(size.x - 214.0, 270.0)
	var right_top_side := Vector2(size.x - 104.0, 520.0)
	var right_mid := Vector2(size.x - 96.0, size.y * 0.48)
	var right_bottom := Vector2(size.x - 112.0, size.y + 180.0)
	var left_bottom := Vector2(112.0, size.y + 180.0)
	var left_mid := Vector2(104.0, size.y * 0.48)
	points.append(left_top_side)
	_append_leaderboard_curve(points, left_top_side, Vector2(108.0, 382.0), Vector2(126.0, 300.0), top_left, 96)
	_append_leaderboard_curve(points, top_left, Vector2(344.0, 216.0), Vector2(size.x * 0.34, 244.0), top_mid, 112)
	_append_leaderboard_curve(points, top_mid, Vector2(size.x * 0.66, 244.0), Vector2(size.x - 330.0, 216.0), top_right, 112)
	_append_leaderboard_curve(points, top_right, Vector2(size.x - 118.0, 300.0), Vector2(size.x - 108.0, 382.0), right_top_side, 96)
	_append_leaderboard_curve(points, right_top_side, Vector2(size.x - 78.0, size.y * 0.30), Vector2(size.x - 118.0, size.y * 0.36), right_mid, 128)
	_append_leaderboard_curve(points, right_mid, Vector2(size.x - 72.0, size.y * 0.64), Vector2(size.x - 112.0, size.y * 0.86), right_bottom, 128)
	points.append(left_bottom)
	_append_leaderboard_curve(points, left_bottom, Vector2(112.0, size.y * 0.86), Vector2(72.0, size.y * 0.64), left_mid, 128)
	_append_leaderboard_curve(points, left_mid, Vector2(118.0, size.y * 0.36), Vector2(78.0, size.y * 0.30), left_top_side, 128)
	return PackedVector2Array(points)

func _append_leaderboard_curve(points: Array, p0: Vector2, c1: Vector2, c2: Vector2, p3: Vector2, steps: int) -> void:
	for i in range(1, steps + 1):
		var t := float(i) / float(steps)
		var inv := 1.0 - t
		points.append(inv * inv * inv * p0 + 3.0 * inv * inv * t * c1 + 3.0 * inv * t * t * c2 + t * t * t * p3)
