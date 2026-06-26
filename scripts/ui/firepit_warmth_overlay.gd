class_name FirepitWarmthOverlay
extends Control

var cutout_center := Vector2.ZERO
var base_radius := 520.0
var feather_radius := 260.0
var flicker_radius := 46.0
var darkness := 0.46
var unlit_darkness := 0.42
var glow_alpha := 0.16
var active := false
var cover_visible := false
var corner_radius := 66.0

var _time := 0.0


func set_active(is_active: bool) -> void:
	set_cover(is_active, is_active)


func set_cover(is_visible: bool, is_fire_lit: bool) -> void:
	cover_visible = is_visible
	active = is_fire_lit
	visible = cover_visible
	set_process(cover_visible and active)
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(active)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	if not cover_visible:
		return
	if not active:
		_draw_rounded_cover(Color(0.03, 0.022, 0.014, unlit_darkness))
		return
	var flicker := sin(_time * 4.8) * 0.52 + sin(_time * 9.7 + 1.4) * 0.31 + sin(_time * 15.3 + 0.6) * 0.17
	var radius := base_radius + flicker * flicker_radius
	var feather := feather_radius + sin(_time * 3.3 + 0.8) * 24.0
	var outer_radius := radius + feather
	var center := cutout_center
	_draw_rounded_cover(Color(0.03, 0.022, 0.014, darkness))
	var steps := 72
	for step in range(steps):
		var t := float(step) / float(maxi(1, steps - 1))
		var circle_radius := lerpf(outer_radius, radius * 0.22, t)
		var alpha := glow_alpha * pow(t, 1.18) * 0.28
		var glow_color := Color(1.0, 0.50 + 0.22 * t, 0.16, alpha)
		draw_circle(center, circle_radius, glow_color)


func _draw_rounded_cover(color: Color) -> void:
	if color.a <= 0.0 or size.x <= 1.0 or size.y <= 1.0:
		return
	var r := minf(corner_radius, minf(size.x, size.y) * 0.5)
	if r <= 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), color)
		return
	var step := 1.0
	var y := 0.0
	while y < size.y:
		var sample_y := y + step * 0.5
		var inset := 0.0
		if sample_y < r:
			var dy_top := sample_y - r
			inset = r - sqrt(maxf(0.0, r * r - dy_top * dy_top))
		elif sample_y > size.y - r:
			var dy_bottom := sample_y - (size.y - r)
			inset = r - sqrt(maxf(0.0, r * r - dy_bottom * dy_bottom))
		draw_rect(Rect2(Vector2(inset, y), Vector2(maxf(0.0, size.x - inset * 2.0), step)), color)
		y += step


func _draw_outer_cover(center: Vector2, outer_radius: float, cover_color: Color) -> void:
	var left := maxf(0.0, center.x - outer_radius)
	var right := minf(size.x, center.x + outer_radius)
	var top := maxf(0.0, center.y - outer_radius)
	var bottom := minf(size.y, center.y + outer_radius)
	if left > 0.0:
		draw_rect(Rect2(Vector2.ZERO, Vector2(left, size.y)), cover_color)
	if right < size.x:
		draw_rect(Rect2(Vector2(right, 0.0), Vector2(size.x - right, size.y)), cover_color)
	if top > 0.0 and right > left:
		draw_rect(Rect2(Vector2(left, 0.0), Vector2(right - left, top)), cover_color)
	if bottom < size.y and right > left:
		draw_rect(Rect2(Vector2(left, bottom), Vector2(right - left, size.y - bottom)), cover_color)


func _draw_feather(center: Vector2, radius: float, feather: float) -> void:
	var steps := 18
	var segments := 96
	for step in range(steps):
		var inner_radius := radius + feather * (float(step) / float(steps))
		var outer_radius := radius + feather * (float(step + 1) / float(steps))
		var alpha_t := pow(float(step + 1) / float(steps), 1.55)
		var ring_color := Color(0.03, 0.022, 0.014, darkness * alpha_t)
		var points: PackedVector2Array = []
		for segment in range(segments + 1):
			var angle := TAU * float(segment) / float(segments)
			points.append(center + Vector2(cos(angle), sin(angle)) * outer_radius)
		for segment in range(segments, -1, -1):
			var angle := TAU * float(segment) / float(segments)
			points.append(center + Vector2(cos(angle), sin(angle)) * inner_radius)
		draw_colored_polygon(points, ring_color)
