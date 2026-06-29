extends Control

var texture: Texture2D


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	if texture == null or size.x <= 1.0 or size.y <= 1.0:
		return
	draw_texture_rect(texture, Rect2(Vector2.ZERO, size), false)
