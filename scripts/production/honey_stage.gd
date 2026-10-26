extends "res://scripts/production/stage.gd"

const TOP_ROOM := 260.0
const BOTTOM_ROOM := 340.0
const OUTPUT_SIZE := Vector2(380,244)
var input_root: Control
var input_box: Control
var bottle_toggle: Button
var use_toggle: Button
var lower_root: Control
var lower_boxes: Dictionary
var input_line: ColorRect
var output_lines: Dictionary = {}
var open_amount := 0.0
var target_open := false
var access := false
var fit_pending := false
var badge_id := ""
var resource_badge: Control

static func attach_honey(owner, record: Dictionary) -> void:
	var stage = load("res://scripts/production/honey_stage.gd").new()
	stage.host = owner
	stage.card = record
	stage.name = "HoneyInventories"
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.regular_layout = true
	record.root.add_child(stage)
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	record.production_stage = stage
	stage.setup_honey()

func setup_honey() -> void:
	var surface = host._material_collection_surface()
	lower_root = card.mat_collection.root
	lower_root.reparent(self)
	lower_root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	lower_boxes = card.mat_collection.modules
	for child in lower_root.get_children():
		if child is ColorRect: child.queue_free()
	for id in lower_boxes:
		var box: Control = lower_boxes[id]
		box.custom_minimum_size = OUTPUT_SIZE
		box.size = OUTPUT_SIZE
		var icon: TextureRect = instance_from_id(int(box.get_meta("icon_id")))
		icon.custom_minimum_size = Vector2(80,80)
		output_lines[id] = make_line(lower_root)
	input_root = Control.new()
	input_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(input_root)
	input_box = surface._mat_collection_module("empty-bottle", "", "", true)
	input_box.custom_minimum_size = Vector2(330,244)
	input_box.size = input_box.custom_minimum_size
	input_root.add_child(input_box)
	var title: Label = instance_from_id(int(input_box.get_meta("name_label_id")))
	title.text = "Bottles"
	input_line = make_line(input_root)
	var bottle_row := HBoxContainer.new()
	bottle_row.position = Vector2(344,84)
	bottle_row.size = Vector2(306,76)
	input_root.add_child(bottle_row)
	bottle_toggle = button("Bottle: Off", func(): host._production_runtime().state.bottling = not host._production_runtime().state.bottling, bottle_row)
	bottle_toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var use_row := HBoxContainer.new()
	use_row.position = Vector2(0,264)
	use_row.size = Vector2(380,76)
	lower_root.add_child(use_row)
	use_toggle = button("Use: Off", func(): host._production_runtime().state.use_bottled_honey = not host._production_runtime().state.use_bottled_honey, use_row)
	use_toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	use_toggle.set_meta("honey_row", use_row)
	for toggle in [bottle_toggle, use_toggle]:
		toggle.toggle_mode = true
		for state_name in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
			toggle.add_theme_color_override(state_name, Color("#181817"))
	for child in card.art_panel.get_children():
		if child is Control and child.z_index == 30:
			resource_badge = child
			break
	sync_honey_inventory(host.running_skill_id == card.skill_id and host.running_action_id == card.action_id, true)

func make_line(parent: Control) -> ColorRect:
	var line := ColorRect.new()
	line.color = host.material_runtime.color("honey").darkened(.35)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.z_index = -1
	parent.add_child(line)
	return line

func sync_honey_inventory(active: bool, instant := false) -> void:
	var next_access: bool = host._production_runtime().bottles_available()
	if next_access != access: fit_pending = true
	access = next_access
	var next_open := active or access
	if next_open and not target_open: fit_pending = true
	target_open = next_open
	if instant: open_amount = 1.0 if target_open else 0.0
	refresh_controls()
	apply_honey_layout()

func _process(delta: float) -> void:
	if not is_instance_valid(host) or not is_instance_valid(card.root): return
	var active: bool = host.running_skill_id == card.skill_id and host.running_action_id == card.action_id
	sync_honey_inventory(active)
	open_amount = move_toward(open_amount, 1.0 if target_open else 0.0, delta/.28)
	apply_honey_layout()
	if fit_pending and open_amount >= .999:
		fit_pending = false
		fit_into_view()

func refresh_controls() -> void:
	var production = host._production_runtime()
	bottle_toggle.text = "Bottle: On" if production.state.bottling else "Bottle: Off"
	use_toggle.text = "Use: On" if production.state.use_bottled_honey else "Use: Off"
	bottle_toggle.set_pressed_no_signal(bool(production.state.bottling))
	use_toggle.set_pressed_no_signal(bool(production.state.use_bottled_honey))
	bottle_toggle.modulate = Color("#a9e996") if production.state.bottling else Color.WHITE
	use_toggle.modulate = Color("#a9e996") if production.state.use_bottled_honey else Color.WHITE
	var surface = host._material_collection_surface()
	for box in [input_box, lower_boxes.honey, lower_boxes["bottled-honey"]]:
		var count: Label = instance_from_id(int(box.get_meta("amount_label_id")))
		count.text = surface._box_amount_text(str(box.get_meta("mat_id")))
	var output_id: String = production.honey_output_id()
	if output_id != badge_id and is_instance_valid(resource_badge):
		badge_id = output_id
		for child in resource_badge.get_children():
			if child is TextureRect: child.texture = tex(output_id)

func apply_honey_layout() -> void:
	var width: float = card.root.size.x
	var top: float = TOP_ROOM * open_amount if access else 0.0
	var bottom: float = (BOTTOM_ROOM if access else 280.0) * open_amount
	card.factory_inventory_top_room = top
	card.mat_room = top + bottom
	card.root.position.y = top
	host._skill_detail_surface()._apply_activity_slot_height(card)
	input_root.position = Vector2((width-650)*.5, -top)
	input_root.visible = access and open_amount > 0
	input_root.modulate.a = open_amount
	input_line.position = Vector2(162,244)
	input_line.size = Vector2(6,16)
	lower_root.position = Vector2(0,card.root.custom_minimum_size.y)
	lower_root.size = Vector2(width,bottom)
	lower_root.visible = open_amount > 0
	lower_root.modulate.a = open_amount
	lower_root.scale = Vector2.ONE
	card.mat_collection.visible = target_open
	var total: float = OUTPUT_SIZE.x*2+24 if access else OUTPUT_SIZE.x
	var index := 0
	for id in ["honey","bottled-honey"]:
		var box: Control = lower_boxes[id]
		box.visible = access or id == "honey"
		box.position = Vector2((width-total)*.5+index*(OUTPUT_SIZE.x+24),16)
		var line: ColorRect = output_lines[id]
		line.visible = box.visible
		line.position = Vector2(box.position.x+OUTPUT_SIZE.x*.5-3,0)
		line.size = Vector2(6,18)
		index += 1
	var use_row: Control = use_toggle.get_meta("honey_row")
	use_row.position.x = lower_boxes["bottled-honey"].position.x
	use_row.visible = access

func fit_into_view() -> void:
	if host.current_screen != "skill" or host.selected_skill_id != card.skill_id: return
	var scroll: ScrollContainer = host.detail_actions_scroll
	var top: float = card.root.global_position.y - float(card.factory_inventory_top_room)
	var height: float = card.root.custom_minimum_size.y + float(card.mat_room)
	var minimum: float = scroll.global_position.y + 8
	var maximum: float = host._current_canvas_size().y - host._reward_feedback_surface()._reward_float_reserved_bottom() - 8 - height
	var desired := clampf(top, minimum, maxf(minimum, maximum))
	scroll.scroll_vertical += roundi(top-desired)
	scroll.set("drag_scroll_position",float(scroll.scroll_vertical))
