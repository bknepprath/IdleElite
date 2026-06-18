class_name ActivityStartHighlightRing
extends Control


var glow_color := Color("#ffd84a")
var corner_radius := 66.0
var outer_pad := 34.0
var gap := 26.0
var ring_thickness := 18.0
var blur_spread := 22.0
var blur_layers := 12

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func set_glow_alpha(alpha: float) -> void:
	modulate.a = alpha
	queue_redraw()

func _draw() -> void:
	var inner := Rect2(
		outer_pad,
		outer_pad,
		maxf(1.0, size.x - outer_pad * 2.0),
		maxf(1.0, size.y - outer_pad * 2.0)
	)
	var max_ring_distance := gap + ring_thickness + blur_spread
	for layer_index in range(blur_layers):
		var t := float(layer_index) / float(maxi(blur_layers - 1, 1))
		var ring_distance := gap + t * (ring_thickness + blur_spread)
		ring_distance = minf(ring_distance, max_ring_distance)
		var alpha := pow(1.0 - t, 1.55) * 0.48 * modulate.a
		var layer_color := Color(glow_color.r, glow_color.g, glow_color.b, alpha)
		var width := maxf(2.5, (ring_thickness + blur_spread) / float(blur_layers) * 1.4)
		_draw_rounded_outline(inner.grow(ring_distance), corner_radius + ring_distance * 0.42, width, layer_color)

func _draw_rounded_outline(rect: Rect2, radius: float, width: float, color: Color) -> void:
	var half := width * 0.5
	var left := rect.position.x + half
	var right := rect.position.x + rect.size.x - half
	var top := rect.position.y + half
	var bottom := rect.position.y + rect.size.y - half
	if right <= left + radius * 2.0 or bottom <= top + radius * 2.0:
		return
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5 - half)
	draw_line(Vector2(left + r, top), Vector2(right - r, top), color, width, true)
	draw_line(Vector2(left + r, bottom), Vector2(right - r, bottom), color, width, true)
	draw_line(Vector2(left, top + r), Vector2(left, bottom - r), color, width, true)
	draw_line(Vector2(right, top + r), Vector2(right, bottom - r), color, width, true)
	draw_arc(Vector2(left + r, top + r), r, PI, PI * 1.5, 8, color, width, true)
	draw_arc(Vector2(right - r, top + r), r, PI * 1.5, PI * 2.0, 8, color, width, true)
	draw_arc(Vector2(right - r, bottom - r), r, 0.0, PI * 0.5, 8, color, width, true)
	draw_arc(Vector2(left + r, bottom - r), r, PI * 0.5, PI, 8, color, width, true)
