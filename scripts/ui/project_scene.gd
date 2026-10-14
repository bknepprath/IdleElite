extends Control

var fraction := 0.0:
	set(value):
		if is_equal_approx(fraction, value): return
		fraction = clampf(value, 0.0, 1.0)
		queue_redraw()
var kind := "build"
const INK := Color("#171615")
const WOOD := Color("#c98c43")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	resized.connect(queue_redraw)

func plank(rect: Rect2, color := WOOD) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = INK
	box.set_border_width_all(7)
	box.set_corner_radius_all(12)
	draw_style_box(box, rect)

func line(a: Vector2, b: Vector2, color: Color, width: float) -> void:
	draw_line(a, b, INK, width + 12, true)
	draw_line(a, b, color, width, true)

func _draw() -> void:
	if size.x < 1 or size.y < 1: return
	draw_set_transform(Vector2.ZERO, 0.0, size / Vector2(1000, 240))
	var stage := int(floor(fraction * 5.0 + 0.001))
	match kind:
		"bridge":
			draw_rect(Rect2(0, 140, 1000, 100), Color("#2dc0b9"))
			draw_circle(Vector2(55, 250), 210, Color("#9dba60"))
			draw_circle(Vector2(950, 250), 210, Color("#9dba60"))
			line(Vector2(210, 190), Vector2(790, 190), Color("#90612e"), 24)
			for i in range(5):
				var x := 235.0 + i * 105.0
				if i < stage: plank(Rect2(x, 135, 105, 48))
				else: draw_dashed_line(Vector2(x, 158), Vector2(x + 85, 158), INK.lightened(0.55), 5, 14)
			for x in [205, 790]: plank(Rect2(x, 80, 28, 135))
		"lock":
			draw_arc(Vector2(500, 92), 76, PI, TAU, 32, INK, 38, true)
			draw_arc(Vector2(500, 92), 76, PI, TAU, 32, Color("#929da8"), 24, true)
			plank(Rect2(335, 80, 330, 140), Color("#ccaa53"))
			for i in range(5):
				var x := 371.0 + i * 58
				plank(Rect2(x, 111, 28, 79), Color("#664a36"))
				draw_circle(Vector2(x + 14, 120 if i < stage else 180), 18, INK)
				draw_circle(Vector2(x + 14, 120 if i < stage else 180), 11, Color("#80be58") if i < stage else Color("#ffdf58"))
		"grove":
			draw_rect(Rect2(0, 185, 1000, 55), Color("#92b956"))
			line(Vector2(170, 224), Vector2(870, 224), Color("#c5a477"), 20)
			for i in range(5):
				var x := 210.0 + 140 * i
				plank(Rect2(x - 15, 185, 48, 30))
				if i >= stage:
					plank(Rect2(x, 100, 25, 103))
					draw_circle(Vector2(x + 10, 83), 64, INK)
					draw_circle(Vector2(x + 10, 83), 56, Color("#63923c"))
		"barrier":
			plank(Rect2(245, 28, 35, 210), Color("#90612e"))
			plank(Rect2(728, 28, 35, 210), Color("#90612e"))
			for i in range(5):
				if i >= stage: plank(Rect2(205, 28 + i * 40, 595, 34))
		_:
			draw_rect(Rect2(0, 215, 1000, 25), Color("#92b956"))
			plank(Rect2(310, 205, 390, 28), Color("#8b969d"))
			for i in range(4):
				var x := 330.0 + i * 105
				if i < stage: plank(Rect2(x, 84, 30, 128))
				else: draw_dashed_line(Vector2(x + 15, 90), Vector2(x + 15, 199), INK.lightened(0.6), 5, 14)
			if stage >= 3: plank(Rect2(326, 105, 350, 35))
			if stage >= 4: plank(Rect2(326, 159, 350, 35))
			if stage >= 5:
				line(Vector2(290, 97), Vector2(500, 20), Color("#c15a48"), 28)
				line(Vector2(500, 20), Vector2(720, 97), Color("#c15a48"), 28)
