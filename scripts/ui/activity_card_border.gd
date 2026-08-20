extends Control


const FAST_ARC_SEGMENTS := 8

var border_color := Color("#171615")
var border_width := 6.0
var radius := 33.0
var anti_aliasing := true
var bottom_shape := "round"
var bottom_cutout_color := Color("#f8f1e5")
var wide_u_bottom_rise := 29.0
var wide_u_shoulder_ratio := 0.285

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	if bottom_shape != "wide_u":
		var style := StyleBoxFlat.new()
		style.bg_color = Color.TRANSPARENT
		style.border_color = border_color
		style.set_border_width_all(int(round(border_width)))
		style.set_corner_radius_all(int(round(radius)))
		style.anti_aliasing = anti_aliasing
		style.anti_aliasing_size = 1.5
		draw_style_box(style, Rect2(Vector2.ZERO, size))
		return
	var stroke_width := border_width
	var half := stroke_width * 0.5
	var left := half
	var right := maxf(half, size.x - half)
	var top := half
	var bottom := maxf(half, size.y - half)
	var r := maxf(0.0, minf(radius, minf(size.x, size.y) * 0.5 - half))
	var points := PackedVector2Array()
	points.append(Vector2(left + r, top))
	points.append(Vector2(right - r, top))
	_append_arc_points(points, Vector2(right - r, top + r), r, -PI * 0.5, 0.0)
	if bottom_shape == "wide_u":
		var side_y := maxf(top + r, bottom - wide_u_bottom_rise)
		var shoulder := clampf(wide_u_shoulder_ratio, 0.0, 0.49)
		var curve_left := lerpf(left, right, shoulder)
		var curve_right := lerpf(left, right, 1.0 - shoulder)
		points.append(Vector2(right, side_y - r))
		_append_arc_points(points, Vector2(right - r, side_y - r), r, 0.0, PI * 0.5)
		points.append(Vector2(curve_right, side_y))
		var curve := PackedVector2Array()
		for i in range(1, 34):
			var t := float(i) / 34.0
			var curve_weight := sin(t * PI)
			curve.append(Vector2(lerpf(curve_right, curve_left, t), lerpf(side_y, bottom, curve_weight * curve_weight)))
		curve.append(Vector2(curve_left, side_y))
		for point in curve:
			points.append(point)
		points.append(Vector2(left + r, side_y))
		_append_arc_points(points, Vector2(left + r, side_y - r), r, PI * 0.5, PI)
	else:
		points.append(Vector2(right, bottom - r))
		_append_arc_points(points, Vector2(right - r, bottom - r), r, 0.0, PI * 0.5)
		points.append(Vector2(left + r, bottom))
		_append_arc_points(points, Vector2(left + r, bottom - r), r, PI * 0.5, PI)
	points.append(Vector2(left, top + r))
	_append_arc_points(points, Vector2(left + r, top + r), r, PI, PI * 1.5)
	if not points.is_empty():
		points.append(points[0])
		draw_polyline(points, border_color, stroke_width, true)

func _append_arc_points(points: PackedVector2Array, center: Vector2, arc_radius: float, start_angle: float, end_angle: float) -> void:
	for i in range(1, FAST_ARC_SEGMENTS + 1):
		var t := float(i) / float(FAST_ARC_SEGMENTS)
		var angle := lerpf(start_angle, end_angle, t)
		points.append(center + Vector2(cos(angle), sin(angle)) * arc_radius)
