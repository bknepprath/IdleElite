extends Panel

const AxeTexture := preload("res://assets/content/woodcutting/groves/axe-upgrade.png")
const Formatting := preload("res://scripts/core/formatting.gd")
const INK := Color("#171615")
const PARTS := {
	"handle": [Vector2(208, 140), Vector2(255, 157), Vector2(197, 316), Vector2(144, 296)],
	"head": [Vector2(289, 48), Vector2(415, 73), Vector2(394, 155), Vector2(353, 221), Vector2(327, 157), Vector2(275, 108)],
	"grip": [Vector2(145, 296), Vector2(196, 323), Vector2(155, 445), Vector2(98, 412)],
	"sharpening": [Vector2(407, 75), Vector2(431, 77), Vector2(426, 144), Vector2(397, 207), Vector2(350, 246), Vector2(342, 222), Vector2(383, 171)],
	"gem": [Vector2(249, 72), Vector2(262, 108), Vector2(233, 134), Vector2(220, 97)],
}
const PART_ANCHORS := {"handle": Vector2(192, 240), "head": Vector2(336, 111), "grip": Vector2(146, 372), "sharpening": Vector2(400, 169), "gem": Vector2(241, 103)}
const EFFECTS := {"handle": "Speed +12%", "head": "Max logs +1", "grip": "Accuracy +2%", "sharpening": "Min logs +1", "gem": "XP +10%"}

const PART_ORDER := ["gem", "sharpening", "grip", "head", "handle"]

class AxePartButton extends Button:
	var polygon := PackedVector2Array()
	var selected := false
	var hit_polygon := PackedVector2Array()
	var excluded_polygons: Array[PackedVector2Array] = []
	func _has_point(point: Vector2) -> bool:
		var local := point / size * 512.0
		for excluded in excluded_polygons:
			if Geometry2D.is_point_in_polygon(local, excluded): return false
		return Geometry2D.is_point_in_polygon(local, hit_polygon if not hit_polygon.is_empty() else polygon)
	func contains_screen_point(point: Vector2) -> bool:
		return _has_point(get_global_transform_with_canvas().affine_inverse() * point)
	func _draw() -> void:
		if not selected and not is_hovered() and not has_focus(): return
		var points := PackedVector2Array()
		var uvs := PackedVector2Array()
		for point in polygon:
			points.append(point / 512.0 * size)
			uvs.append(point / 512.0)
		# Sampling the actual sprite keeps the highlight inside its alpha mask.
		draw_polygon(points, PackedColorArray([Color(0.5, 1.0, 0.3, 0.85)]), uvs, AxeTexture)

var stage
var selected_kind := "handle"
var part_buttons: Dictionary = {}
var title_label: Label
var level_label: Label
var effect_label: Label
var cost_label: Label
var material_label: Label
var inventory_label: Label
var requirement_label: Label
var cost_icon: TextureRect
var purchase_button: Button
var close_button: Button
var art_rect := Rect2()

func setup(owner_stage) -> void:
	stage = owner_stage
	name = "AxeComponents"
	z_index = 400
	add_to_group("production_output_menus")
	set_meta("converter", self)
	var face := StyleBoxFlat.new()
	face.bg_color = Color("#fff0cc")
	face.border_color = INK
	face.set_border_width_all(5)
	face.set_corner_radius_all(20)
	add_theme_stylebox_override("panel", face)
	close_button = stage.make_button("CloseAxeShop", close_output_menu)
	close_button.text = "×"
	close_button.tooltip_text = "Close"
	add_child(close_button)
	# Each piece has its own shape and keyboard focus, including the blade edge.
	for kind in PART_ORDER:
		var button := AxePartButton.new()
		button.name = "Axe" + str(kind).capitalize()
		button.polygon = PackedVector2Array(PARTS[kind])
		if kind == "handle":
			button.hit_polygon = PackedVector2Array([Vector2(241,20),Vector2(270,15),Vector2(292,36),Vector2(287,63),Vector2(155,448),Vector2(129,483),Vector2(89,474),Vector2(82,448)])
			button.excluded_polygons = [PackedVector2Array(PARTS.grip), PackedVector2Array(PARTS.gem)]
		button.tooltip_text = str(kind).capitalize()
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		stage.configure_button(button, func(): select_part(kind))
		stage.host._apply_empty_button_style(button)
		button.mouse_entered.connect(button.queue_redraw)
		button.mouse_exited.connect(button.queue_redraw)
		button.focus_entered.connect(button.queue_redraw)
		button.focus_exited.connect(button.queue_redraw)
		add_child(button)
		part_buttons[kind] = button
	title_label = detail_label(60)
	level_label = detail_label(48)
	effect_label = detail_label(52)
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cost_label = detail_label(52)
	material_label = detail_label(52)
	inventory_label = detail_label(52)
	inventory_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	requirement_label = detail_label(52)
	cost_icon = TextureRect.new()
	cost_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cost_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cost_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cost_icon)
	purchase_button = stage.make_button("UpgradeAxePart", purchase_selected)
	purchase_button.text = "Upgrade"
	add_child(purchase_button)
	resized.connect(layout_controls)
	layout_controls()
	refresh()

func detail_label(font_size: int) -> Label:
	var label: Label = stage.host._label_on_light_panel("", font_size, INK, HORIZONTAL_ALIGNMENT_LEFT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func select_part(kind: String) -> void:
	selected_kind = kind
	refresh()

func close_output_menu() -> void:
	hide()

func purchase_selected() -> void:
	stage.host._grove_runtime().buy_upgrade(selected_kind)
	refresh()

func layout_controls() -> void:
	if not is_instance_valid(purchase_button): return
	var art_side := minf(size.x * 0.70, size.y - 90)
	art_rect = Rect2((size.x * 0.56 - art_side) * 0.5, 80, art_side, art_side)
	for button in part_buttons.values():
		button.position = art_rect.position
		button.size = art_rect.size
	var left := size.x * 0.56
	var width := size.x - left - 24
	close_button.position = Vector2(size.x - 90, 14)
	close_button.size = Vector2(70, 70)
	title_label.position = Vector2(28, 12)
	level_label.position = Vector2(left, 100)
	effect_label.position = Vector2(left, 174)
	effect_label.size = Vector2(width, 70)
	cost_icon.position = Vector2(left, 310)
	cost_icon.size = Vector2(60, 60)
	cost_label.position = Vector2(left + 76, 305)
	material_label.position = Vector2(left, 375)
	inventory_label.position = Vector2(left, 445)
	inventory_label.size = Vector2(width, 128)
	requirement_label.position = Vector2(left, 240)
	purchase_button.position = Vector2(left, size.y - 96)
	purchase_button.size = Vector2(width, 76)
	queue_redraw()

func refresh() -> void:
	var runtime = stage.host._grove_runtime()
	var level := int(runtime.upgrades[selected_kind])
	var cost: Dictionary = runtime.upgrade_cost(selected_kind)
	title_label.text = selected_kind.capitalize()
	level_label.text = "Level %d → %d" % [level, level + 1] if not cost.is_empty() else "Level %d" % level
	effect_label.text = EFFECTS[selected_kind] if not cost.is_empty() else "Maximum level"
	cost_label.text = str(cost.get("amount", ""))
	cost_icon.visible = not cost.is_empty()
	material_label.text = stage.host.material_runtime.display_name(str(cost.id)) if not cost.is_empty() else ""
	inventory_label.text = "Owned " + Formatting.compact_inventory_number(stage.host.material_runtime.amount(str(cost.id))) if not cost.is_empty() else ""
	if not cost.is_empty(): cost_icon.texture = stage.host.visual_texture_cache._texture_or_visual_fallback(stage.host.material_runtime.icon_path(str(cost.id)))
	var available: bool = runtime.upgrade_available(selected_kind)
	var affordable: bool = not cost.is_empty() and stage.host.material_runtime.amount(str(cost.id)) >= float(cost.amount)
	var unlocked: bool = stage.host._activity_unlock_runtime()._is_action_unlocked("woodcutting", stage.host._action_data("woodcutting", runtime.IDS[0]))
	purchase_button.disabled = not unlocked or not available or not affordable
	purchase_button.text = "Max level" if cost.is_empty() else "Upgrade"
	requirement_label.text = "Head required" if not available and not cost.is_empty() else ("Need materials" if not affordable and not cost.is_empty() else "")
	for kind in part_buttons:
		part_buttons[kind].selected = kind == selected_kind
		part_buttons[kind].queue_redraw()
	layout_controls()
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(stage): return
	draw_texture_rect(AxeTexture, art_rect, false)
	# The complete sprite was generated by editing the original game axe.
	# All five components remain in one authored canvas; masks only route input.
	draw_set_transform(art_rect.position, 0, art_rect.size / 512.0)
	# Small part markers remain legible without adding a list beside the axe.
	for kind in PART_ANCHORS:
		var point: Vector2 = PART_ANCHORS[kind]
		if kind == "gem": continue
		draw_circle(point, 12, INK)
		draw_circle(point, 7, Color("#85bf3d") if kind == selected_kind else Color("#fff0cc"))
	draw_set_transform(Vector2.ZERO)
