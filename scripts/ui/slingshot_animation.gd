extends RefCounted

const SHEET = preload("res://assets/content/fight/rockslide/slingshot-cycle.png")
const CELL := Vector2(512,512)
# All poses share this authored canvas, planted feet and fork release point.
const GROUND := Vector2(220,470)
const MUZZLE := Vector2(390,242)

static func frame_index(charge: float, release_progress := -1.0) -> int:
	if release_progress >= 0.0:
		if release_progress < .24: return 4
		if release_progress < .49: return 5
		if release_progress < .76: return 6
		return 7
	if charge < .18: return 0
	if charge < .43: return 1
	if charge < .73: return 2
	return 3

static func draw_pose(surface: CanvasItem, ground: Vector2, side: float, frame: int) -> void:
	var scale := side/CELL.y
	var source := Rect2(Vector2(frame%4,frame/4)*CELL,CELL)
	surface.draw_texture_rect_region(SHEET,Rect2(ground-GROUND*scale,CELL*scale),source)

static func muzzle(ground: Vector2, side: float) -> Vector2:
	return ground+(MUZZLE-GROUND)*side/CELL.y
