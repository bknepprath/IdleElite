class_name ActivityLockNumber
extends Control


var text := "1"
var font: Font
var font_size := 250
var outline_size := 46

func set_text(next_text: String) -> void:
	text = next_text
	queue_redraw()

func _draw() -> void:
	var active_font := font if font != null else ThemeDB.fallback_font
	var fitted := font_size
	var max_width := size.x * 0.86
	while fitted > 72 and active_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted).x > max_width:
		fitted -= 4
	var text_size := active_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted)
	var baseline := size.y * 0.5 + (active_font.get_ascent(fitted) - active_font.get_descent(fitted)) * 0.5
	var text_position := Vector2((size.x - text_size.x) * 0.5, baseline)
	for x in range(-outline_size, outline_size + 1, 3):
		for y in range(-outline_size, outline_size + 1, 3):
			if x == 0 and y == 0:
				continue
			var offset := Vector2(x, y)
			if offset.length() <= float(outline_size) + 0.25:
				draw_string(active_font, text_position + offset, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted, Color("#171615"))
	draw_string(active_font, text_position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted, Color.WHITE)


