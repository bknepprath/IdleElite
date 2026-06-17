class_name HubMoveIcon
extends Control


func _draw() -> void:
	var center := size * 0.5
	var length := minf(size.x, size.y) * 0.34
	for direction in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var normal: Vector2 = direction.normalized()
		var tip: Vector2 = center + normal * length
		var base: Vector2 = center + normal * (length * 0.36)
		_draw_arrow(base, tip, normal, 12.0, Color.BLACK)
		_draw_arrow(base, tip, normal, 7.0, Color.WHITE)

func _draw_arrow(base: Vector2, tip: Vector2, normal: Vector2, width: float, color: Color) -> void:
	draw_line(base, tip, color, width, true)
	var side := Vector2(-normal.y, normal.x)
	var head_back := tip - normal * 28.0
	draw_line(tip, head_back + side * 18.0, color, width, true)
	draw_line(tip, head_back - side * 18.0, color, width, true)
