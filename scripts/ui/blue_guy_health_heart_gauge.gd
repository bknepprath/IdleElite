extends Control


const HEART_POINTS := 96
const ARC_SEGMENTS := 40

var current := 0
var maximum := 30
var target_displayed := 30.0
var displayed := 30.0
var regen_fraction := 1.0
var initialized := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)

func set_health(next_current: int, next_maximum: int, instant := false, next_regen_fraction := 1.0) -> void:
	var max_value := maxi(1, next_maximum)
	var current_value := clampi(next_current, 0, max_value)
	var fractional_current := clampf(float(current_value) + (clampf(next_regen_fraction, 0.0, 1.0) if current_value < max_value else 0.0), 0.0, float(max_value))
	if initialized and current == current_value and maximum == max_value and absf(target_displayed - fractional_current) <= 0.01 and absf(regen_fraction - next_regen_fraction) <= 0.01:
		return
	current = current_value
	maximum = max_value
	target_displayed = fractional_current
	regen_fraction = clampf(next_regen_fraction, 0.0, 1.0)
	if instant or not initialized:
		displayed = target_displayed
		initialized = true
	queue_redraw()
	set_process(not instant and absf(displayed - target_displayed) > 0.01)

func _process(delta: float) -> void:
	displayed = lerpf(displayed, target_displayed, 1.0 - exp(-9.0 * maxf(0.0, delta)))
	queue_redraw()
	if absf(displayed - target_displayed) <= 0.01:
		displayed = target_displayed
		set_process(false)

func _draw() -> void:
	var draw_scale := minf(size.x, size.y) / 552.0
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.36
	var pct := clampf(displayed / float(maximum), 0.0, 1.0)
	var heart := _heart_points(center + Vector2(0.0, 18.0) * draw_scale, radius)
	draw_colored_polygon(heart, Color("#341317"))
	var fill_scale := 0.40 + pct * 0.60
	var fill_color := Color("#ef4054").lerp(Color("#ff7382"), pct * 0.35)
	draw_colored_polygon(_heart_points(center + Vector2(0.0, 18.0) * draw_scale, radius * fill_scale), fill_color)
	_draw_heart_outline(heart, Color("#171615"), maxf(6.0, 10.0 * draw_scale))
	if current < maximum:
		draw_arc(center, radius * 1.18, -PI * 0.5, -PI * 0.5 + TAU * regen_fraction, ARC_SEGMENTS, Color("#2bd775"), maxf(14.0, 20.0 * draw_scale), true)
	var font := get_theme_default_font()
	if font == null:
		return
	var number_text := "%d/%d" % [current, maximum]
	var label_text := "HP"
	var number_size := int(clampf(size.y * 0.19, 48.0, 82.0))
	var label_size := int(clampf(size.y * 0.12, 34.0, 54.0))
	_draw_center_text(font, number_text, center + Vector2(0.0, -8.0) * draw_scale, number_size, Color("#fffaf0"), Color("#171615"), int(maxf(8.0, number_size * 0.18)))
	_draw_center_text(font, label_text, center + Vector2(0.0, 62.0) * draw_scale, label_size, Color("#fffaf0"), Color("#171615"), int(maxf(6.0, label_size * 0.18)))

func _heart_points(center: Vector2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(HEART_POINTS):
		var t := TAU * float(i) / float(HEART_POINTS)
		var x := 16.0 * pow(sin(t), 3.0)
		var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		points.append(center + Vector2(x / 17.0, y / 17.0) * radius)
	return points

func _draw_heart_outline(points: PackedVector2Array, color: Color, width: float) -> void:
	for i in range(points.size()):
		draw_line(points[i], points[(i + 1) % points.size()], color, width, true)

func _draw_center_text(font: Font, text: String, center: Vector2, font_size: int, fill: Color, outline: Color, outline_size: int) -> void:
	var measured := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	var baseline := center.y + (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	var position := Vector2(center.x - measured.x * 0.5, baseline)
	draw_string_outline(font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, outline_size, outline)
	draw_string(font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, fill)
