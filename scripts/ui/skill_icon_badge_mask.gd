extends Control

var fill_style: StyleBoxFlat


func _ready() -> void:
	clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	if fill_style == null or size.x <= 1.0 or size.y <= 1.0:
		return
	draw_style_box(fill_style, Rect2(Vector2.ZERO, size))
