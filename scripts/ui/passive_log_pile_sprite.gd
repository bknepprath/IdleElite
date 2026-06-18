class_name PassiveLogPileSprite
extends Control


var texture: Texture2D
var icon_size := Vector2(48, 48)
var log_slots: Array = []
var log_rotations: Array = []
var visible_logs := 0
var shadow_rect := Rect2()
var shadow_color := Color(0.10, 0.07, 0.04, 0.20)

func configure(
	next_texture: Texture2D,
	next_icon_size: Vector2,
	next_log_slots: Array,
	next_log_rotations: Array,
	next_visible_logs: int,
	next_shadow_rect: Rect2
) -> void:
	texture = next_texture
	icon_size = next_icon_size
	log_slots = next_log_slots
	log_rotations = next_log_rotations
	visible_logs = next_visible_logs
	shadow_rect = next_shadow_rect
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw() -> void:
	_draw_shadow()
	if texture == null:
		return
	var count := mini(visible_logs, log_slots.size())
	for i in range(count):
		var base_position := log_slots[i] as Vector2
		var rotation := deg_to_rad(float(log_rotations[i])) if i < log_rotations.size() else 0.0
		draw_set_transform(base_position + icon_size * 0.5, rotation, Vector2.ONE)
		draw_texture_rect(texture, Rect2(-icon_size * 0.5, icon_size), false, Color.WHITE)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_shadow() -> void:
	if shadow_rect.size.x <= 1.0 or shadow_rect.size.y <= 1.0:
		return
	var center := shadow_rect.position + shadow_rect.size * 0.5
	var radius_x := shadow_rect.size.x * 0.5
	var radius_y := shadow_rect.size.y * 0.5
	var line_count := maxi(10, int(ceil(shadow_rect.size.y)))
	for i in range(line_count):
		var t := float(i) / maxf(1.0, float(line_count - 1))
		var y := lerpf(-radius_y, radius_y, t)
		var normalized_y := y / maxf(1.0, radius_y)
		var width := radius_x * sqrt(maxf(0.0, 1.0 - normalized_y * normalized_y))
		var center_weight := 1.0 - absf(normalized_y)
		var alpha := shadow_color.a * pow(center_weight, 2.15)
		var color := Color(shadow_color.r, shadow_color.g, shadow_color.b, alpha)
		draw_line(Vector2(center.x - width, center.y + y), Vector2(center.x + width, center.y + y), color, 2.0, true)
