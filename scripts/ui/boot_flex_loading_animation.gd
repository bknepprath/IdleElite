class_name BootFlexLoadingAnimation
extends Control


const LOOP_SECONDS := 2.75
const BUBBLE_TEXT := "I must become an idle elitist!"

var elapsed := 0.0
var bubble_label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble_label = Label.new()
	bubble_label.text = BUBBLE_TEXT
	bubble_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bubble_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble_label.add_theme_font_size_override("font_size", 44)
	bubble_label.add_theme_color_override("font_color", Color("#182023"))
	bubble_label.add_theme_color_override("font_outline_color", Color.WHITE)
	bubble_label.add_theme_constant_override("outline_size", 6)
	bubble_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bubble_label)
	set_process(true)


func restart() -> void:
	elapsed = 0.0
	_update_bubble_label(0.0, 0.0)
	queue_redraw()


func _process(delta: float) -> void:
	elapsed = fmod(elapsed + delta, LOOP_SECONDS)
	queue_redraw()


func _draw() -> void:
	var t := elapsed / LOOP_SECONDS
	var pose := _pose_for_time(t)
	_draw_speed_bubble(t)
	_draw_speed_streaks(t)
	_draw_blue_guy(pose, t)
	_update_bubble_label(t, _bubble_pop(t))


func _pose_for_time(t: float) -> Dictionary:
	var points := [
		{"t": 0.00, "head_y": 0.0, "head_scale": 1.0, "torso_lean": 0.0, "torso_squash": 1.0, "arm_l": -0.82, "arm_r": -2.32, "fore_l": -1.05, "fore_r": -2.10, "leg_l": 1.86, "leg_r": 1.28, "mouth": 0.0, "eyes": 0.0},
		{"t": 0.18, "head_y": 18.0, "head_scale": 0.94, "torso_lean": -0.14, "torso_squash": 0.88, "arm_l": -1.52, "arm_r": -1.62, "fore_l": -1.90, "fore_r": -1.18, "leg_l": 1.70, "leg_r": 1.42, "mouth": 0.35, "eyes": 0.35},
		{"t": 0.29, "head_y": -12.0, "head_scale": 1.05, "torso_lean": 0.12, "torso_squash": 1.08, "arm_l": -0.10, "arm_r": -3.03, "fore_l": -0.88, "fore_r": -2.24, "leg_l": 1.98, "leg_r": 1.16, "mouth": 0.62, "eyes": 0.75},
		{"t": 0.39, "head_y": 2.0, "head_scale": 1.0, "torso_lean": 0.0, "torso_squash": 1.0, "arm_l": -0.72, "arm_r": -2.42, "fore_l": 0.48, "fore_r": 2.66, "leg_l": 1.88, "leg_r": 1.24, "mouth": 1.0, "eyes": 1.0},
		{"t": 0.72, "head_y": 0.0, "head_scale": 1.0, "torso_lean": 0.0, "torso_squash": 1.0, "arm_l": -0.72, "arm_r": -2.42, "fore_l": 0.48, "fore_r": 2.66, "leg_l": 1.88, "leg_r": 1.24, "mouth": 1.0, "eyes": 1.0},
		{"t": 1.00, "head_y": 0.0, "head_scale": 1.0, "torso_lean": 0.0, "torso_squash": 1.0, "arm_l": -0.82, "arm_r": -2.32, "fore_l": -1.05, "fore_r": -2.10, "leg_l": 1.86, "leg_r": 1.28, "mouth": 0.0, "eyes": 0.0}
	]
	for i in range(points.size() - 1):
		var a := points[i] as Dictionary
		var b := points[i + 1] as Dictionary
		if t >= float(a["t"]) and t <= float(b["t"]):
			var span := maxf(0.001, float(b["t"]) - float(a["t"]))
			var amount := _ease((t - float(a["t"])) / span)
			return _lerp_pose(a, b, amount)
	return points[0] as Dictionary


func _lerp_pose(a: Dictionary, b: Dictionary, amount: float) -> Dictionary:
	var out := {}
	for key in a.keys():
		if key == "t":
			continue
		out[key] = lerpf(float(a[key]), float(b[key]), amount)
	return out


func _ease(t: float) -> float:
	var clamped := clampf(t, 0.0, 1.0)
	return clamped * clamped * (3.0 - 2.0 * clamped)


func _draw_blue_guy(pose: Dictionary, t: float) -> void:
	var scale_factor := minf(size.x / 980.0, size.y / 920.0)
	var origin := Vector2(size.x * 0.50, size.y * 0.57)
	var head_radius := 126.0 * scale_factor * float(pose["head_scale"])
	var neck := origin + Vector2(0.0, -86.0 * scale_factor + float(pose["head_y"]) * scale_factor)
	var head_center := neck + Vector2(0.0, -136.0 * scale_factor)
	var hip := origin + Vector2(float(pose["torso_lean"]) * 95.0, 198.0 * float(pose["torso_squash"])) * scale_factor
	var shoulder := neck + Vector2(float(pose["torso_lean"]) * 26.0, 26.0) * scale_factor
	var left_shoulder := shoulder + Vector2(-66.0, 32.0) * scale_factor
	var right_shoulder := shoulder + Vector2(66.0, 32.0) * scale_factor
	var left_hand := _draw_arm(left_shoulder, float(pose["arm_l"]), float(pose["fore_l"]), scale_factor)
	var right_hand := _draw_arm(right_shoulder, float(pose["arm_r"]), float(pose["fore_r"]), scale_factor)

	_draw_limb(neck, hip, 7.0 * scale_factor)
	_draw_limb(hip, hip + Vector2(cos(float(pose["leg_l"])), sin(float(pose["leg_l"]))) * 166.0 * scale_factor, 6.0 * scale_factor)
	_draw_limb(hip, hip + Vector2(cos(float(pose["leg_r"])), sin(float(pose["leg_r"]))) * 166.0 * scale_factor, 6.0 * scale_factor)
	_draw_fist(left_hand, scale_factor)
	_draw_fist(right_hand, scale_factor)
	_draw_head(head_center, head_radius, float(pose["mouth"]), float(pose["eyes"]), t)


func _draw_arm(shoulder: Vector2, upper_angle: float, fore_angle: float, scale_factor: float) -> Vector2:
	var elbow := shoulder + Vector2(cos(upper_angle), sin(upper_angle)) * 122.0 * scale_factor
	var hand := elbow + Vector2(cos(fore_angle), sin(fore_angle)) * 96.0 * scale_factor
	_draw_limb(shoulder, elbow, 6.0 * scale_factor)
	_draw_limb(elbow, hand, 6.0 * scale_factor)
	return hand


func _draw_limb(a: Vector2, b: Vector2, width: float) -> void:
	draw_line(a + Vector2(0, width * 0.45), b + Vector2(0, width * 0.45), Color(0, 0, 0, 0.18), width + 2.0, true)
	draw_line(a, b, Color("#f8fbff"), width, true)
	draw_line(a, b, Color("#171615"), maxf(2.0, width * 0.30), true)


func _draw_fist(center: Vector2, scale_factor: float) -> void:
	draw_circle(center + Vector2(2.0, 5.0) * scale_factor, 28.0 * scale_factor, Color(0, 0, 0, 0.20))
	draw_circle(center, 25.0 * scale_factor, Color("#d6c0b1"))
	draw_circle(center + Vector2(-7.0, -7.0) * scale_factor, 10.0 * scale_factor, Color("#f1ded1"))
	draw_arc(center, 25.0 * scale_factor, 0.15, PI * 1.15, 14, Color("#171615"), 3.0 * scale_factor, true)


func _draw_head(center: Vector2, radius: float, mouth: float, eyes: float, t: float) -> void:
	draw_circle(center + Vector2(7.0, 11.0), radius, Color(0, 0, 0, 0.24))
	draw_circle(center, radius, Color("#1d6ccf"))
	draw_circle(center + Vector2(radius * 0.22, -radius * 0.10), radius * 0.86, Color("#164f9a"))
	draw_circle(center + Vector2(-radius * 0.28, -radius * 0.22), radius * 0.42, Color("#9fd7ff"))
	draw_circle(center + Vector2(-radius * 0.44, -radius * 0.34), radius * 0.14, Color(1, 1, 1, 0.72))
	draw_arc(center, radius, -0.20, PI * 1.22, 28, Color("#171615"), 4.0, true)
	var blink := minf(1.0, eyes + maxf(0.0, sin((t - 0.37) * TAU * 5.0)) * 0.12)
	_draw_eye(center + Vector2(-42.0, -36.0), -1.0, blink)
	_draw_eye(center + Vector2(42.0, -36.0), 1.0, blink)
	if mouth > 0.05:
		_draw_mouth(center + Vector2(2.0, 34.0), mouth)


func _draw_eye(center: Vector2, side: float, squeeze: float) -> void:
	var span := lerpf(24.0, 38.0, squeeze)
	var lift := lerpf(7.0, 0.0, squeeze)
	draw_line(center + Vector2(-span * 0.5, -lift * side), center + Vector2(span * 0.5, lift * side), Color("#171615"), 3.5, true)


func _draw_mouth(center: Vector2, amount: float) -> void:
	var rx := lerpf(18.0, 42.0, amount)
	var ry := lerpf(15.0, 48.0, amount)
	draw_colored_polygon(_ellipse_points(center, Vector2(rx, ry), 28), Color("#c9403e"))
	draw_polyline(_ellipse_points(center, Vector2(rx, ry), 28), Color("#171615"), 3.0, true)


func _draw_speed_bubble(t: float) -> void:
	var pop := _bubble_pop(t)
	if pop <= 0.01:
		return
	var scale_factor := minf(size.x / 980.0, size.y / 920.0)
	var center := Vector2(size.x * 0.57, size.y * 0.23)
	var bubble_size := Vector2(530.0, 148.0) * scale_factor * pop
	var rect := Rect2(center - bubble_size * 0.5, bubble_size)
	var tail := PackedVector2Array([
		Vector2(center.x - 120.0 * scale_factor * pop, rect.end.y - 6.0 * scale_factor),
		Vector2(center.x - 52.0 * scale_factor * pop, rect.end.y + 72.0 * scale_factor * pop),
		Vector2(center.x - 8.0 * scale_factor * pop, rect.end.y - 12.0 * scale_factor)
	])
	draw_colored_polygon(tail, Color.WHITE)
	draw_polyline(tail, Color("#171615"), 5.0 * scale_factor, true)
	_draw_round_rect(rect, 34.0 * scale_factor * pop, Color.WHITE)
	_draw_round_rect_outline(rect, 34.0 * scale_factor * pop, Color("#171615"), 6.0 * scale_factor)


func _draw_speed_streaks(t: float) -> void:
	var pop := _bubble_pop(t)
	if pop <= 0.01:
		return
	var scale_factor := minf(size.x / 980.0, size.y / 920.0)
	var alpha := 0.58 * (1.0 - absf(pop - 0.8) * 0.35)
	for i in range(4):
		var y := size.y * 0.20 + float(i) * 34.0 * scale_factor
		var x := size.x * 0.22 - float(i % 2) * 32.0 * scale_factor
		draw_line(Vector2(x, y), Vector2(x + 126.0 * scale_factor, y - 20.0 * scale_factor), Color(1, 1, 1, alpha), 8.0 * scale_factor, true)
		var ink := Color("#171615")
		ink.a = alpha * 0.65
		draw_line(Vector2(x + 8.0 * scale_factor, y + 12.0 * scale_factor), Vector2(x + 88.0 * scale_factor, y - 2.0 * scale_factor), ink, 3.0 * scale_factor, true)


func _bubble_pop(t: float) -> float:
	if t < 0.38 or t > 0.76:
		return 0.0
	var in_amount := _ease((t - 0.38) / 0.08)
	var out_amount := 1.0 - _ease(maxf(0.0, (t - 0.70) / 0.06))
	var overshoot := 1.0 + sin(clampf((t - 0.38) / 0.14, 0.0, 1.0) * PI) * 0.12
	return clampf(minf(in_amount, out_amount) * overshoot, 0.0, 1.12)


func _update_bubble_label(t: float, pop: float) -> void:
	if bubble_label == null:
		return
	var scale_factor := minf(size.x / 980.0, size.y / 920.0)
	var center := Vector2(size.x * 0.57, size.y * 0.23)
	var label_size := Vector2(456.0, 112.0) * scale_factor
	bubble_label.size = label_size
	bubble_label.position = center - label_size * 0.5
	bubble_label.pivot_offset = label_size * 0.5
	bubble_label.scale = Vector2.ONE * maxf(0.01, pop)
	bubble_label.modulate.a = 1.0 if pop > 0.01 and t >= 0.38 and t <= 0.76 else 0.0


func _draw_round_rect(rect: Rect2, radius: float, color: Color) -> void:
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	draw_rect(Rect2(rect.position + Vector2(r, 0), Vector2(rect.size.x - r * 2.0, rect.size.y)), color)
	draw_rect(Rect2(rect.position + Vector2(0, r), Vector2(rect.size.x, rect.size.y - r * 2.0)), color)
	draw_circle(rect.position + Vector2(r, r), r, color)
	draw_circle(rect.position + Vector2(rect.size.x - r, r), r, color)
	draw_circle(rect.position + Vector2(rect.size.x - r, rect.size.y - r), r, color)
	draw_circle(rect.position + Vector2(r, rect.size.y - r), r, color)


func _draw_round_rect_outline(rect: Rect2, radius: float, color: Color, width: float) -> void:
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var left := rect.position.x
	var right := rect.end.x
	var top := rect.position.y
	var bottom := rect.end.y
	draw_line(Vector2(left + r, top), Vector2(right - r, top), color, width, true)
	draw_line(Vector2(left + r, bottom), Vector2(right - r, bottom), color, width, true)
	draw_line(Vector2(left, top + r), Vector2(left, bottom - r), color, width, true)
	draw_line(Vector2(right, top + r), Vector2(right, bottom - r), color, width, true)
	draw_arc(Vector2(left + r, top + r), r, PI, PI * 1.5, 16, color, width, true)
	draw_arc(Vector2(right - r, top + r), r, PI * 1.5, TAU, 16, color, width, true)
	draw_arc(Vector2(right - r, bottom - r), r, 0.0, PI * 0.5, 16, color, width, true)
	draw_arc(Vector2(left + r, bottom - r), r, PI * 0.5, PI, 16, color, width, true)


func _ellipse_points(center: Vector2, radius: Vector2, steps: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(steps + 1):
		var a := TAU * float(i) / float(steps)
		points.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	return points
