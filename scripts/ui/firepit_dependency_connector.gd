class_name FirepitDependencyConnector
extends Control


var line_color := Color("#171615")
var line_width := 10.0
var start_y := 0.0
var end_y := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func configure(next_start_y: float, next_end_y: float, next_width := 10.0, next_color := Color("#171615")) -> void:
	start_y = next_start_y
	end_y = next_end_y
	line_width = next_width
	line_color = next_color
	queue_redraw()


func _draw() -> void:
	if size.x <= 1.0 or absf(end_y - start_y) <= 1.0:
		return
	var x := size.x * 0.5
	var start := Vector2(x, start_y)
	var finish := Vector2(x, end_y)
	draw_line(start, finish, line_color, line_width, true)
	draw_circle(start, line_width * 0.5, line_color)
	draw_circle(finish, line_width * 0.5, line_color)
