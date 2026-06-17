class_name ShopAdStackLight
extends Control


var fill := 0.0

func set_fill(next_fill: float) -> void:
	var clamped := clampf(next_fill, 0.0, 1.0)
	if absf(fill - clamped) < 0.001:
		return
	fill = clamped
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	if size.x <= 8.0 or size.y <= 8.0:
		return
	var side := minf(size.x, size.y)
	var outer := Rect2((size - Vector2(side, side)) * 0.5, Vector2(side, side))
	var glow_alpha := fill * 0.34
	if glow_alpha > 0.0:
		_draw_round_rect(outer.grow(5.0), 20.0, Color(1.0, 0.77, 0.16, glow_alpha))
	_draw_round_rect(outer, 14.0, Color("#171615"))
	var stroke := maxf(7.0, side * 0.14)
	var inner := outer.grow(-stroke)
	var body_color := Color("#cfe5ee").lerp(Color("#ffd84a"), fill)
	_draw_round_rect(inner, 8.0, body_color)
	var top_face := Rect2(inner.position, Vector2(inner.size.x, inner.size.y * 0.24))
	draw_rect(top_face, Color(1.0, 1.0, 1.0, 0.20 + fill * 0.16))
	var side_face := Rect2(inner.position + Vector2(inner.size.x * 0.76, 0.0), Vector2(inner.size.x * 0.24, inner.size.y))
	draw_rect(side_face, Color(0.0, 0.0, 0.0, 0.09 + fill * 0.08))
	var bottom_face := Rect2(inner.position + Vector2(0.0, inner.size.y * 0.78), Vector2(inner.size.x, inner.size.y * 0.22))
	draw_rect(bottom_face, Color(0.0, 0.0, 0.0, 0.11 + fill * 0.08))
	var shine := Rect2(inner.position + Vector2(inner.size.x * 0.14, inner.size.y * 0.12), Vector2(inner.size.x * 0.42, maxf(8.0, inner.size.y * 0.16)))
	draw_rect(shine, Color(1.0, 1.0, 1.0, 0.32 + fill * 0.18))
	var glint_color := Color(1.0, 1.0, 1.0, 0.32 + fill * 0.28)
	draw_line(
		inner.position + Vector2(inner.size.x * 0.72, inner.size.y * 0.20),
		inner.position + Vector2(inner.size.x * 0.82, inner.size.y * 0.07),
		glint_color,
		4.0,
		true
	)
	draw_line(
		inner.position + Vector2(inner.size.x * 0.78, inner.size.y * 0.26),
		inner.position + Vector2(inner.size.x * 0.89, inner.size.y * 0.15),
		glint_color,
		3.0,
		true
	)

func _draw_round_rect(rect: Rect2, radius: float, color: Color) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	draw_rect(Rect2(rect.position + Vector2(r, 0.0), Vector2(maxf(0.0, rect.size.x - r * 2.0), rect.size.y)), color)
	draw_rect(Rect2(rect.position + Vector2(0.0, r), Vector2(rect.size.x, maxf(0.0, rect.size.y - r * 2.0))), color)
	draw_circle(rect.position + Vector2(r, r), r, color)
	draw_circle(rect.position + Vector2(rect.size.x - r, r), r, color)
	draw_circle(rect.position + Vector2(rect.size.x - r, rect.size.y - r), r, color)
	draw_circle(rect.position + Vector2(r, rect.size.y - r), r, color)
