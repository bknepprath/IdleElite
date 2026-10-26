extends Control

const NOTCH_DEPTH := 64.0
const NOTCH_HALF_WIDTH := 64.0
const RADIUS := 33.0
const PROGRESS_BAND_HEIGHT := 44.0

var face_bottom_inset := 0.0
var back_plate := false
var fill_color := Color("#73552a")
var front: Control
var last_front_position := Vector2.INF

static func outline(rect: Rect2, inset := 0.0) -> PackedVector2Array:
	var box := rect.grow(-inset)
	var r := maxf(0.0, minf(RADIUS - inset, box.size.y * 0.5))
	var points := PackedVector2Array()
	var centres := [Vector2(box.end.x-r, box.position.y+r), Vector2(box.end.x-r, box.end.y-r), Vector2(box.position.x+r, box.end.y-r), Vector2(box.position.x+r, box.position.y+r)]
	for corner in range(4):
		if corner == 2:
			var centre := box.get_center().x
			points.append(Vector2(centre + NOTCH_HALF_WIDTH, box.end.y))
			points.append(Vector2(centre, box.end.y - NOTCH_DEPTH))
			points.append(Vector2(centre - NOTCH_HALF_WIDTH, box.end.y))
		for step in range(13):
			var angle := -PI * 0.5 + corner * PI * 0.5 + step * PI / 24.0
			points.append(centres[corner] + Vector2(cos(angle), sin(angle)) * r)
	points.append(points[0])
	return points

static func apply(record: Dictionary) -> void:
	if not bool(record.action.get("presentation", {}).get("building", false)): return
	var face: Control = record.pop
	if face.get_script() != null: return
	face.set_script(load("res://scripts/ui/production_building_shape.gd"))
	for child in face.get_children():
		if child.get_script() != null and child.get_script().resource_path == "res://scripts/ui/activity_card_border.gd":
			child.bottom_shape = "production_v"
			child.visible = true
			face.face_bottom_inset = maxf(0.0, -child.offset_bottom)
			child.queue_redraw()
	if is_instance_valid(record.get("bg")):
		record.bg.bottom_shape = "production_v"
		record.bg.offset_bottom = -face.face_bottom_inset
		record.bg.fast_flat_render_enabled = false
		record.bg._ensure_mask_material()
		record.bg.queue_redraw()
	if is_instance_valid(record.get("progress")):
		record.progress.bottom_shape = "production_v"
		record.progress.offset_top = record.progress.offset_bottom - NOTCH_DEPTH - PROGRESS_BAND_HEIGHT*sqrt(2.0) - 6.0
		record.progress.show()
		record.progress.queue_redraw()
	# Replace the rectangular rear plate as well, so the hole stays open all
	# the way through the card's depth instead of revealing a rectangular base.
	for sibling in face.get_parent().get_children():
		if sibling.name == "NormalActivityCardPrismConnectors": sibling.hide()
		if sibling.name != "NormalActivityCardBackFace": continue
		sibling.hide()
		var rear = load("res://scripts/ui/production_building_shape.gd").new()
		rear.name = "ProductionBuildingBackFace"
		rear.back_plate = true
		rear.front = face
		var style: StyleBoxFlat = sibling.get_theme_stylebox("panel")
		rear.fill_color = style.bg_color
		rear.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rear.z_index = sibling.z_index
		face.get_parent().add_child(rear)
		rear.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		rear.offset_left = sibling.offset_left
		rear.offset_right = sibling.offset_right
		rear.offset_top = sibling.offset_top
		rear.offset_bottom = sibling.offset_bottom
	face.queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED: queue_redraw()

func _ready() -> void:
	set_process(back_plate)

func _process(_delta: float) -> void:
	if is_instance_valid(front) and front.is_visible_in_tree() and front.global_position != last_front_position:
		last_front_position = front.global_position
		queue_redraw()

func _has_point(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point, outline(Rect2(Vector2.ZERO, Vector2(size.x, maxf(1, size.y-face_bottom_inset)))))

func _draw() -> void:
	if not back_plate:
		return
	var points := outline(Rect2(Vector2.ZERO, size))
	draw_colored_polygon(points, fill_color)
	draw_polyline(outline(Rect2(Vector2.ZERO, size), 3.0), Color("#171615"), 6.0, true)
	if is_instance_valid(front):
		var face_origin := get_global_transform().affine_inverse() * front.global_position
		var face_bottom: float = face_origin.y + front.size.y - front.face_bottom_inset
		var centre := size.x * 0.5
		for offset in [-NOTCH_HALF_WIDTH, 0.0, NOTCH_HALF_WIDTH]:
			var cut := NOTCH_DEPTH if offset == 0.0 else 0.0
			draw_line(Vector2(centre+offset, face_bottom-cut), Vector2(centre+offset, size.y-cut), Color("#171615"), 6, true)
