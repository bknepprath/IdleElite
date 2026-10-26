extends "res://scripts/ui/clean_progress_bar.gd"

var target_value := 0.0

func setup(_font: Font) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	border_color = Color("#171615")
	border_width = 5.0
	track_color = Color("#253038")
	fill_color = Color("#ffd84a")
	set_progress(0.0)
	set_process(false)

func set_progress(amount: float) -> void:
	target_value = clampf(amount * 100.0, 0.0, 100.0)
	if not value_initialized:
		set_value(target_value)
	else:
		set_process(absf(value - target_value) > 0.01)

func _process(delta: float) -> void:
	set_value(lerpf(value, target_value, 1.0 - exp(-14.0 * delta)))
	if absf(value - target_value) <= 0.01:
		set_value(target_value)
		set_process(false)

func _draw() -> void:
	if size.x <= 20.0: return
	var points := PackedVector2Array()
	for index in range(33):
		var t := float(index) / 32.0
		points.append(Vector2(10.0 + (size.x - 20.0) * t, 8.0 + sin(t * PI) * 6.0))
	_draw_rounded_path(points, border_color, 20.0)
	_draw_rounded_path(points, track_color, 10.0)
	var fraction := clampf(value / 100.0, 0.0, 1.0)
	if fraction <= 0.001: return
	var filled := PackedVector2Array()
	var steps := maxi(1, int(ceil(32.0 * fraction)))
	for index in range(steps + 1):
		var t := fraction * float(index) / float(steps)
		filled.append(Vector2(10.0 + (size.x - 20.0) * t, 8.0 + sin(t * PI) * 6.0))
	_draw_rounded_path(filled, fill_color, 10.0)

func _draw_rounded_path(points: PackedVector2Array, color: Color, width: float) -> void:
	draw_polyline(points, color, width, true)
	draw_circle(points[0], width * 0.5, color, true, -1, true)
	draw_circle(points[-1], width * 0.5, color, true, -1, true)
