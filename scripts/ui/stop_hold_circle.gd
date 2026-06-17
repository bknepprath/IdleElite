class_name StopHoldCircle
extends Control


var progress := 0.0
var unload_progress := 0.0
var unloading := false
var theme_color := Color("#3aa0ff")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_progress(next_progress: float, next_unload := 0.0, is_unloading := false) -> void:
	progress = clampf(next_progress, 0.0, 1.0)
	unload_progress = clampf(next_unload, 0.0, 1.0)
	unloading = is_unloading
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.39
	var width := maxf(10.0, radius * 0.24)
	var shadow := Color(0.08, 0.07, 0.06, 0.42 * modulate.a)
	var fill := theme_color
	fill.a = (0.96 if not unloading else 0.78) * modulate.a
	draw_arc(center + Vector2(0, 3), radius, 0.0, TAU, 40, shadow, width + 5.0, true)
	var visible_progress := clampf(progress - unload_progress, 0.0, 1.0)
	if visible_progress > 0.001:
		draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * visible_progress, 40, fill, width, true)
