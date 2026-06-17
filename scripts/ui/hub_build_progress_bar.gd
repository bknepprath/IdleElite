class_name HubBuildProgressBar
extends Label


var remaining_seconds := -1
var total_seconds := 15.0

func _init() -> void:
	text = ""
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	autowrap_mode = TextServer.AUTOWRAP_OFF
	text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_color_override("font_color", Color.BLACK)
	add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0, 0.42))
	add_theme_constant_override("outline_size", 8)

func set_progress(next_value: float) -> void:
	set_countdown(maxi(0, ceili((1.0 - clampf(next_value, 0.0, 1.0)) * total_seconds)))

func set_total_seconds(seconds: float) -> void:
	total_seconds = maxf(0.001, seconds)

func set_countdown(seconds: int) -> void:
	var clamped := maxi(0, seconds)
	if remaining_seconds == clamped:
		return
	remaining_seconds = clamped
	text = "%ss" % remaining_seconds
