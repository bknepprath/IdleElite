class_name PassiveIconSprite
extends Control


var texture: Texture2D
var draw_size := Vector2(48, 48)
var draw_offset := Vector2.ZERO
var shadow_offset := Vector2.ZERO
var shadow_alpha := 0.0
var stroke_color := Color.TRANSPARENT
var stroke_width := 0.0

func configure(next_texture: Texture2D, next_size: Vector2, next_offset := Vector2.ZERO) -> void:
	texture = next_texture
	draw_size = next_size
	draw_offset = next_offset
	custom_minimum_size = draw_size + Vector2(absf(draw_offset.x), absf(draw_offset.y)) * 2.0
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw() -> void:
	if texture == null:
		return
	var rect := Rect2(draw_offset, draw_size)
	if shadow_alpha > 0.0:
		draw_texture_rect(texture, Rect2(draw_offset + shadow_offset, draw_size), false, Color(0, 0, 0, shadow_alpha))
	if stroke_width > 0.0 and stroke_color.a > 0.0:
		var stroke_offsets: Array[Vector2] = [
			Vector2(-stroke_width, 0),
			Vector2(stroke_width, 0),
			Vector2(0, -stroke_width),
			Vector2(0, stroke_width),
			Vector2(-stroke_width * 0.72, -stroke_width * 0.72),
			Vector2(stroke_width * 0.72, -stroke_width * 0.72),
			Vector2(-stroke_width * 0.72, stroke_width * 0.72),
			Vector2(stroke_width * 0.72, stroke_width * 0.72)
		]
		for offset in stroke_offsets:
			draw_texture_rect(texture, Rect2(draw_offset + offset, draw_size), false, stroke_color)
	draw_texture_rect(texture, rect, false, Color.WHITE)
