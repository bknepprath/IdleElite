extends RefCounted

const CENTER_DECIMAL_SUFFIX_SCALE := 0.5
const CENTER_DECIMAL_SUFFIX_ALPHA := 0.6

static func load_font(readout_font: Font) -> Font:
	if ResourceLoader.exists("res://assets/fonts/Fredoka.ttf"):
		var loaded := load("res://assets/fonts/Fredoka.ttf")
		if loaded is Font:
			var bold := FontVariation.new()
			bold.base_font = loaded
			bold.variation_embolden = 1.05
			readout_font = bold
	if readout_font == null:
		readout_font = ThemeDB.fallback_font
	return readout_font

static func draw_number(canvas: CanvasItem, font: Font, main_text: String, suffix_text: String, center: Vector2, font_size: int, fill_color: Color, stroke_size: int) -> void:
	var main_size := font.get_string_size(main_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var main_baseline := center.y + (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	var main_position := Vector2(center.x - main_size.x * 0.5, main_baseline)
	canvas.draw_string_outline(font, main_position, main_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, stroke_size, Color("#171615"))
	canvas.draw_string(font, main_position, main_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, fill_color)
	if suffix_text.is_empty():
		return
	var suffix_size := maxi(24, int(round(float(font_size) * CENTER_DECIMAL_SUFFIX_SCALE)))
	var suffix_stroke := maxi(6, int(round(float(stroke_size) * CENTER_DECIMAL_SUFFIX_SCALE)))
	var suffix_gap := maxf(4.0, float(font_size) * 0.075)
	var suffix_baseline := center.y + (font.get_ascent(suffix_size) - font.get_descent(suffix_size)) * 0.5
	var suffix_position := Vector2(main_position.x + main_size.x + suffix_gap, suffix_baseline)
	var suffix_fill := fill_color
	suffix_fill.a *= CENTER_DECIMAL_SUFFIX_ALPHA
	var suffix_outline := Color("#171615", CENTER_DECIMAL_SUFFIX_ALPHA)
	canvas.draw_string_outline(font, suffix_position, suffix_text, HORIZONTAL_ALIGNMENT_LEFT, -1, suffix_size, suffix_stroke, suffix_outline)
	canvas.draw_string(font, suffix_position, suffix_text, HORIZONTAL_ALIGNMENT_LEFT, -1, suffix_size, suffix_fill)

