extends Control

var hand: Texture2D
var elapsed := 0.0

func _init() -> void:
	name = "JailTapHint"
	custom_minimum_size = Vector2(112, 126)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 8

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	if hand == null: return
	var phase := fposmod(elapsed, 1.7) / 1.7
	var press := sin(clampf(phase / 0.32, 0.0, 1.0) * PI)
	var origin := Vector2(43, 22)
	if phase < 0.5:
		draw_arc(origin, 9.0 + phase * 55.0, 0, TAU, 32, Color(1, 1, 1, (1.0 - phase * 2.0) * 0.8), 4.0, true)
	draw_texture_rect(hand, Rect2(Vector2(0, 10.0 - press * 10.0), Vector2(96, 112)), false)
