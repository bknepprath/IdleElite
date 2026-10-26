extends "res://scripts/production/stage.gd"

const FLYER_BOX := Vector2(96, 96)
var input_panel: Panel
var output_panel: Control
var input_icon: TextureRect
var input_count: Label
var output_count: Label
var input_hit: Button
var output_hit: Button
var output_menu: PanelContainer
var stat_strip: HBoxContainer
var flying_input: TextureRect
var flying_output: TextureRect
var harvest_icon: TextureRect
var harvest_age := 10.0
var input_id := ""
var output_id := ""
var transfer_active := false
var menu_choice: Button
var output_icon: TextureRect
var input_items: Array[Dictionary] = []
var scout_target_label: Label
var factory_inventory: Control
var output_menu_configuration := ""

func setup_converter(body: Dictionary) -> void:
	regular_layout = true
	(body.margin as Control).hide()
	output_panel = card.art_panel
	output_panel.reparent(self)
	output_panel.custom_minimum_size = Vector2(200, 200)
	output_panel.size = Vector2(200, 200)
	output_panel.z_index = 1
	card.art.hide()
	output_icon = image_control(Vector2(164,164))
	output_icon.position = Vector2(18,18)
	output_icon.z_index = 3
	output_panel.add_child(output_icon)
	card["art_replaced"]=true
	card["reward_art"]=output_icon
	input_panel = Panel.new()
	input_panel.size = Vector2(200, 200)
	input_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	input_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	add_child(input_panel)
	var frame := output_panel.get_node_or_null("ActionArtRaisedFace")
	if frame != null: input_panel.add_child(frame.duplicate())
	input_icon = image_control(Vector2(164, 164))
	input_icon.position = Vector2(18, 18)
	input_icon.z_index = 2
	input_panel.add_child(input_icon)
	input_count = label("", 52)
	output_count = label("", 52)
	for count in [input_count, output_count]:
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	make_quantity_badge(input_count,input_panel)
	make_quantity_badge(output_count,output_panel)
	stat_strip = HBoxContainer.new()
	stat_strip.name = "ProductionTimeAndXP"
	stat_strip.alignment = BoxContainer.ALIGNMENT_CENTER
	stat_strip.add_theme_constant_override("separation", 24)
	stat_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stat_strip)
	for kind in ["xp", "time"]:
		var box: Control = card.stat_boxes[kind]
		box.reparent(stat_strip)
		box.custom_minimum_size = Vector2.ZERO
		box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		card[kind].add_theme_font_size_override("font_size", 52)
		var symbol: Control = box.get_meta("normal_activity_stat_symbol", null)
		if symbol != null: preload("res://scripts/ui/activity_header_stats.gd").fit_symbol(symbol,52)
	input_hit = item_button("ProductionInput", func(): open_material_source(input_id))
	output_hit = item_button("ProductionOutput", toggle_output_menu)
	var inputs: Dictionary = host._production_runtime().recipe(card.action).get("inputs",{})
	if inputs.size()>1:
		input_icon.hide()
		input_count.hide()
		quantity_badge(input_count).hide()
		input_hit.hide()
		input_panel.size.x = 300
		for id in inputs:
			var icon := image_control(Vector2(86,100))
			icon.z_index=2
			icon.texture = tex(str(id))
			input_panel.add_child(icon)
			var count := label(str(int(inputs[id])),52)
			count.z_index=3
			count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			make_quantity_badge(count,input_panel)
			var hit := item_button("Ingredient"+str(id),func(): open_material_source(str(id)))
			input_items.append({"id":str(id),"icon":icon,"count":count,"hit":hit})
	var all_hits: Array=[input_hit,output_hit]
	for item in input_items: all_hits.append(item.hit)
	for item in all_hits:
		item.disabled = bool(card.get("preview_only", false))
		if item.disabled:
			item.mouse_filter = Control.MOUSE_FILTER_IGNORE
			item.remove_from_group("production_controls")
	for index in range(3):
		var flyer := image_control(FLYER_BOX)
		flyer.z_index = 500
		flyer.visible = false
		add_child(flyer)
		if index == 0: flying_input = flyer
		elif index == 1: flying_output = flyer
		else: harvest_icon = flyer
	host._production_runtime().recipe_completed.connect(_on_recipe_completed)
	if preload("res://scripts/production/factory_inventory_layout.gd").applies(card.action):
		factory_inventory=load("res://scripts/production/factory_inventory_layout.gd").new()
		card.root.add_child(factory_inventory)
		factory_inventory.setup(self)
	refresh_controls()
	layout_controls()

func image_control(draw_box: Vector2) -> TextureRect:
	var picture := TextureRect.new()
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.size = draw_box
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return picture

func make_quantity_badge(count: Label, parent: Control) -> void:
	var plate := PanelContainer.new()
	plate.name = "RecipeQuantity"
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.z_index = 6
	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.set_corner_radius_all(12)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	plate.add_theme_stylebox_override("panel",style)
	parent.add_child(plate)
	count.add_theme_font_size_override("font_size",48)
	count.add_theme_constant_override("outline_size",8)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count.set_meta("quantity_badge_id",plate.get_instance_id())
	plate.add_child(count)

func quantity_badge(count: Label) -> PanelContainer:
	return instance_from_id(int(count.get_meta("quantity_badge_id"))) as PanelContainer

func layout_quantity_badge(count: Label, bounds: Rect2, inset: float) -> void:
	var plate := quantity_badge(count)
	plate.size = Vector2(maxf(64,count.get_minimum_size().x+20),70)
	plate.position = bounds.end-plate.size-Vector2(inset,inset)

func item_button(node_name: String, callback: Callable) -> Button:
	var hit := Button.new()
	hit.name = node_name
	hit.flat = true
	hit.size = Vector2(200, 200)
	hit.add_to_group("production_controls")
	host._apply_empty_button_style(hit)
	allow_keyboard_activation(hit)
	hit.pressed.connect(func():
		if consume_activation(hit): callback.call()
	)
	add_child(hit)
	return hit

func refresh_controls() -> void:
	card.art.hide()
	var definition: Dictionary = host._production_runtime().recipe(card.action)
	var inputs: Dictionary = definition.get("inputs", {})
	var outputs: Dictionary = definition.get("outputs", {})
	if inputs.is_empty() or outputs.is_empty(): return
	input_id = str(inputs.keys()[0])
	output_id = str(outputs.keys()[0])
	input_icon.texture = tex(input_id)
	output_icon.texture = tex(output_id)
	input_count.text = str(int(inputs[input_id]))
	output_count.text = str(int(outputs[output_id]))
	input_count.modulate = Color.WHITE if host._production_runtime().available_inputs(inputs) or host._production_runtime().state.escrow.has(str(card.action_id)) else Color("#ffb29c")
	for item in input_items:
		item.count.modulate = Color.WHITE if host.material_runtime.amount(item.id)>=float(inputs[item.id]) or host._production_runtime().state.escrow.has(str(card.action_id)) else Color("#ffb29c")
	if is_instance_valid(factory_inventory): factory_inventory.refresh()

func refresh_equipment_controls() -> void:
	for control in buttons:
		if control.text in ["Scout","Bait"]: control.disabled=host.material_runtime.amount("spyglass")<1
		elif control.text=="Select": control.disabled=host.material_runtime.amount("precision-net")<1
	if is_instance_valid(scout_target_label):
		var target:=scout_action()
		scout_target_label.text=str(host._action_data("fishing",target).get("name",target))

func layout_controls() -> void:
	if not is_instance_valid(input_panel): return
	if is_instance_valid(factory_inventory):
		factory_inventory.layout()
		return
	_layout_recipe_boxes()

func _layout_recipe_boxes() -> void:
	input_panel.position = Vector2(38, 118)
	output_panel.position = Vector2(size.x-238, 118)
	input_hit.position = input_panel.position
	for index in input_items.size():
		var item: Dictionary = input_items[index]
		var offset := (300.0-input_items.size()*96.0)*.5+index*96.0
		item.icon.position = Vector2(offset+5,30)
		layout_quantity_badge(item.count,Rect2(offset,16,96,180),6)
		item.hit.position = input_panel.position+Vector2(offset,0)
		item.hit.size = Vector2(96,200)
	output_hit.position = output_panel.position
	layout_quantity_badge(input_count,Rect2(Vector2.ZERO,input_panel.size),14)
	layout_quantity_badge(output_count,Rect2(Vector2.ZERO,output_panel.size),14)
	stat_strip.size = stat_strip.get_combined_minimum_size()
	stat_strip.position = Vector2(size.x-28-stat_strip.size.x,0)
	if is_instance_valid(card.medal):
		if card.medal.get_parent()!=output_panel: card.medal.reparent(output_panel)
		card.medal.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		card.medal.size=Vector2(76,76)
		card.medal.position=Vector2(-38,-38)
		card.medal_destination=card.medal.position
	if is_instance_valid(output_menu): output_menu.position = Vector2(size.x-470,92)

func output_has_queue() -> bool:
	return bool(host._production_runtime().state.wheel_built) and host._production_runtime().supports_queue(str(card.action_id))

func output_has_equipment() -> bool:
	if str(card.action_id) in ["assemble-spyglass","mix-fishing-bait"]:
		return host.material_runtime.amount("spyglass")>=1
	return str(card.action_id)=="weave-selective-net" and host.material_runtime.amount("precision-net")>=1

func has_output_options() -> bool:
	return output_has_queue() or output_has_equipment()

func toggle_output_menu() -> void:
	if not has_output_options():
		select_output()
		return
	if is_instance_valid(output_menu) and output_menu.visible:
		close_output_menu()
		return
	var configuration:=str(output_has_queue())+":"+str(output_has_equipment())
	if is_instance_valid(output_menu) and configuration!=output_menu_configuration:
		for index in range(buttons.size()-1,-1,-1):
			if not is_instance_valid(buttons[index]) or output_menu.is_ancestor_of(buttons[index]): buttons.remove_at(index)
		remove_child(output_menu)
		output_menu.queue_free()
		output_menu=null
	if not is_instance_valid(output_menu):
		output_menu_configuration=configuration
		output_menu = PanelContainer.new()
		output_menu.name = "ProductionOutputMenu"
		output_menu.z_index = 1000
		output_menu.z_as_relative = false
		output_menu.mouse_filter = Control.MOUSE_FILTER_STOP
		output_menu.add_to_group("production_output_menus")
		output_menu.set_meta("converter", self)
		output_menu.add_theme_stylebox_override("panel", host._surface_style(Color("#f6e7bc"), 24, 12, true))
		add_child(output_menu)
		var stack := VBoxContainer.new()
		output_menu.add_child(stack)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		stack.add_child(row)
		var picture := image_control(Vector2(80, 80))
		picture.texture = tex(output_id)
		picture.custom_minimum_size = Vector2(80, 80)
		row.add_child(picture)
		# Each factory currently has one authored output recipe.
		var material_name := str(host.material_runtime.material_defs.get(output_id, {}).get("name", "Wooden Parts"))
		menu_choice = button(material_name, select_output, row)
		menu_choice.name = "ProductionOutputChoice"
		menu_choice.custom_minimum_size = Vector2(320, 96)
		if output_has_queue():
			var queue_row := HBoxContainer.new()
			stack.add_child(queue_row)
			button("+1", func(): host._production_runtime().enqueue(str(card.action_id)), queue_row)
		if output_has_equipment() and str(card.action_id) in ["assemble-spyglass","mix-fishing-bait"]:
			scout_target_label=label("",48)
			scout_target_label.custom_minimum_size=Vector2(390,60)
			scout_target_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			stack.add_child(scout_target_label)
			var equipment := HBoxContainer.new()
			stack.add_child(equipment)
			button("Scout",scout_next,equipment)
			button("Bait",toggle_scout_bait,equipment)
		elif output_has_equipment() and str(card.action_id)=="weave-selective-net":
			var equipment := HBoxContainer.new()
			stack.add_child(equipment)
			button("Select",toggle_selective_net,equipment)
	refresh_equipment_controls()
	output_menu.show()
	layout_controls()

func toggle_selective_net() -> void:
	if host.material_runtime.amount("precision-net")<1: return
	host._production_runtime().state.selective_net = not host._production_runtime().state.selective_net
	host._mark_save_dirty("selective net")

func close_output_menu() -> void:
	if is_instance_valid(output_menu): output_menu.hide()

func select_output() -> void:
	close_output_menu()
	if host.running_skill_id != str(card.skill_id) or host.running_action_id != str(card.action_id):
		host._action_runtime()._start_action_from_card_tap(str(card.skill_id), str(card.action_id))

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	if host._input_routing_shell()._any_modal_overlay_visible(): close_output_menu()
	running = host.running_skill_id == str(card.skill_id) and host.running_action_id == str(card.action_id)
	if is_instance_valid(factory_inventory): factory_inventory.advance(delta,running or (is_instance_valid(output_menu) and output_menu.visible))
	phase = float(host.action_progress) if running else 0.0
	if is_instance_valid(factory_inventory):
		factory_inventory.draw_cycle(phase,running)
	elif running and phase >= 0.65:
		transfer_active = true
		_draw_transfer(clampf((phase-0.65)/0.35, 0.0, 1.0))
	elif transfer_active:
		transfer_active = false
		flying_input.hide()
		flying_output.hide()
	if harvest_age < 0.95:
		harvest_age += delta
		var t := clampf(harvest_age/0.95, 0.0, 1.0)
		if is_instance_valid(factory_inventory): factory_inventory.draw_harvest(t)
		else:
			var rise := 56.0*(1.0-pow(1.0-t, 3.0))
			harvest_icon.position = output_panel.position+output_panel.size*0.5-FLYER_BOX*0.5-Vector2(0, rise)
			harvest_icon.modulate.a = 1.0-smoothstep(0.3, 1.0, t)
			harvest_icon.visible = t < 1.0
	status_elapsed += delta
	if status_elapsed > 0.15:
		status_elapsed = 0.0
		refresh_controls()
		layout_controls()
		refresh_equipment_controls()

func _draw_transfer(t: float) -> void:
	if is_instance_valid(factory_inventory):
		factory_inventory.draw_transfer(t)
		return
	var start := input_panel.position+input_panel.size*0.5
	var finish := output_panel.position+output_panel.size*0.5
	var middle := (start+finish)*0.5-Vector2(0, 120)
	var point := start*(1-t)*(1-t)+middle*2.0*(1-t)*t+finish*t*t
	var morph := smoothstep(0.55, 0.85, t)
	flying_input.texture = tex(input_id)
	flying_output.texture = tex(output_id)
	for flyer in [flying_input, flying_output]:
		flyer.position = point-FLYER_BOX*0.5
		flyer.pivot_offset = FLYER_BOX*0.5
		flyer.rotation = sin(t*PI)*0.25
		flyer.show()
	flying_input.modulate.a = 1.0-morph
	flying_output.modulate.a = morph

func _on_recipe_completed(action_id: String, _outputs: Dictionary) -> void:
	if action_id != str(card.action_id) or not is_visible_in_tree(): return
	transfer_active = false
	flying_input.hide()
	flying_output.hide()
	harvest_age = 0.0
	harvest_icon.texture = tex(output_id)
	harvest_icon.modulate.a = 1.0
	harvest_icon.show()

func _draw() -> void:
	pass

func sync_factory_inventory(active: bool,instant: bool) -> void:
	if is_instance_valid(factory_inventory): factory_inventory.sync(active or (is_instance_valid(output_menu) and output_menu.visible),instant)
