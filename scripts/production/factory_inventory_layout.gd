extends Control

const BOX_SIZE := Vector2(280,244)
const CONNECTOR := 16.0
const ROOM := 260.0
const TOTAL_ROOM := ROOM*2.0
const FLYER_SIZE := Vector2(112,112)
const INPUT_HOP_START := .06
const INPUT_HOP_END := .30
const CONVERSION_START := .58
var stage
var top_clip: Control
var bottom_clip: Control
var output_connector: Control
var boxes: Dictionary={}
var top_items: Array[Control]=[]
var ingredient_flyers: Array[TextureRect]=[]
var target_open := false
var openness := 0.0
var fit_pending := false

static func applies(action: Dictionary) -> bool:
	var presentation: Dictionary=action.get("presentation",{})
	return presentation.get("layout","")=="activity" and bool(presentation.get("building",false)) and not str(action.get("production",{}).get("recipe","")).is_empty()

func setup(owner) -> void:
	stage=owner
	name="FactoryInventories"
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	top_clip=clip_layer("FactoryInputInventories")
	bottom_clip=clip_layer("FactoryOutputInventory")
	var recipe: Dictionary=stage.host._production_runtime().recipe(stage.card.action)
	for id in recipe.inputs:
		var key:=str(id)
		var box:=inventory_box(key,top_clip,func(): stage.open_material_source(key))
		top_items.append(box)
		var line:=connector(key)
		top_clip.add_child(line)
		box.set_meta("connector_id",line.get_instance_id())
		var flyer: TextureRect=stage.flying_input if ingredient_flyers.is_empty() else stage.image_control(FLYER_SIZE)
		if not ingredient_flyers.is_empty():
			flyer.z_index=500
			stage.add_child(flyer)
		flyer.texture=stage.tex(key)
		flyer.hide()
		ingredient_flyers.append(flyer)
	var output:=str(recipe.outputs.keys()[0])
	var output_box:=inventory_box(output,bottom_clip,stage.toggle_output_menu)
	output_box.position.y=CONNECTOR
	output_connector=connector(output)
	# Keep the connector unbroken through the rear V recess, outside the clip.
	output_connector.z_index=-1
	add_child(output_connector)
	layout()
	sync(stage.host.running_skill_id==str(stage.card.skill_id) and stage.host.running_action_id==str(stage.card.action_id),true)
	refresh()

func clip_layer(node_name: String) -> Control:
	var clip:=Control.new()
	clip.name=node_name
	clip.clip_contents=true
	clip.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(clip)
	return clip

func inventory_box(id: String,parent: Control,callback: Callable) -> Control:
	var box: Control=stage.host._material_collection_surface()._mat_collection_module(id,"","",true)
	box.name="FactoryInventory"+id.capitalize()
	parent.add_child(box)
	boxes[id]=box
	var hit: Button=stage.item_button("Inventory"+id,callback)
	hit.disabled=bool(stage.card.get("preview_only",false))
	if hit.disabled:
		hit.mouse_filter=Control.MOUSE_FILTER_IGNORE
		hit.remove_from_group("production_controls")
	hit.reparent(box)
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hit.tooltip_text=stage.host.material_runtime.display_name(id)
	return box

func connector(id: String) -> ColorRect:
	var line:=ColorRect.new()
	line.name="InventoryConnector"
	line.size=Vector2(6,CONNECTOR)
	line.color=stage.host.material_runtime.color(id).darkened(.35)
	line.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return line

func set_target(active: bool) -> void:
	if active and not target_open: fit_pending=true
	target_open=active

func sync(active: bool,instant := false) -> void:
	set_target(active)
	if instant:
		openness=1.0 if active else 0.0
		apply_room()

func advance(delta: float,active: bool) -> void:
	set_target(active)
	var next:=move_toward(openness,1.0 if active else 0.0,delta/.24)
	if next!=openness:
		openness=next
		apply_room()
	elif not is_equal_approx(stage.card.root.position.y,ROOM*openness): apply_room()
	if fit_pending and openness>=.999:
		fit_pending=false
		fit_group_into_view()

func fit_group_into_view() -> void:
	if stage.host.current_screen!="skill" or stage.host.selected_skill_id!=str(stage.card.skill_id): return
	var scroll: ScrollContainer=stage.host.detail_actions_scroll
	if not is_instance_valid(scroll): return
	var top: float=stage.card.root.global_position.y-ROOM
	var height: float=stage.card.root.custom_minimum_size.y+TOTAL_ROOM
	var minimum: float=scroll.global_position.y+8
	var maximum: float=stage.host._current_canvas_size().y-stage.host._reward_feedback_surface()._reward_float_reserved_bottom()-8-height
	var desired:=clampf(top,minimum,maxf(minimum,maximum))
	scroll.scroll_vertical+=roundi(top-desired)
	scroll.set("drag_scroll_position",float(scroll.scroll_vertical))

func apply_room() -> void:
	stage.card.factory_inventory_top_room=ROOM*openness
	stage.card.mat_room=TOTAL_ROOM*openness
	stage.card.root.position.y=ROOM*openness
	stage.host._skill_detail_surface()._apply_activity_slot_height(stage.card)
	layout()

func layout() -> void:
	if not is_instance_valid(stage.input_panel): return
	var width: float=stage.card.root.size.x
	var room:=ROOM*openness
	top_clip.position=Vector2(0,-room)
	bottom_clip.position=Vector2(0,stage.card.root.custom_minimum_size.y)
	for clip in [top_clip,bottom_clip]:
		clip.size=Vector2(width,room)
		clip.visible=openness>0.0
		clip.modulate.a=openness
	var total:=float(top_items.size())*BOX_SIZE.x+maxi(0,top_items.size()-1)*28.0
	for index in top_items.size():
		var box: Control=top_items[index]
		box.position=Vector2((width-total)*.5+index*(BOX_SIZE.x+28),0)
		var line: Control=instance_from_id(int(box.get_meta("connector_id")))
		line.position=box.position+Vector2(BOX_SIZE.x*.5-3,BOX_SIZE.y)
	var output_box: Control=boxes[stage.output_id] if boxes.has(stage.output_id) else boxes.values().back()
	output_box.position=Vector2((width-BOX_SIZE.x)*.5,CONNECTOR)
	var connector_top: float=bottom_clip.position.y-preload("res://scripts/ui/production_building_shape.gd").NOTCH_DEPTH
	var rear: Control=stage.card.pop.get_parent().get_node_or_null("ProductionBuildingBackFace")
	if is_instance_valid(rear):
		var notch_tip:=Vector2(rear.size.x*.5,rear.size.y-preload("res://scripts/ui/production_building_shape.gd").NOTCH_DEPTH)
		connector_top=(get_global_transform().affine_inverse()*rear.get_global_transform()*notch_tip).y
	var connector_bottom: float=bottom_clip.position.y+minf(room,CONNECTOR+2.0)
	output_connector.position=Vector2(width*.5-3,connector_top-3.0)
	output_connector.size=Vector2(6,maxf(0.0,connector_bottom-output_connector.position.y))
	output_connector.visible=openness>0.0
	output_connector.modulate.a=openness
	stage._layout_recipe_boxes()

func refresh() -> void:
	var material=stage.host._material_collection_surface()
	for id in boxes:
		var count: Label=instance_from_id(int(boxes[id].get_meta("amount_label_id")))
		count.text=material._box_amount_text(str(id))
	layout()

func center_in_stage(control: Control) -> Vector2:
	return stage.get_global_transform().affine_inverse()*control.get_global_rect().get_center()

func inventory_icon(id: String) -> Control:
	return instance_from_id(int(boxes[id].get_meta("icon_id"))) as Control

func input_control(index: int) -> Control:
	return stage.input_icon if stage.input_items.is_empty() else stage.input_items[index].icon

static func hop_point(start: Vector2,finish: Vector2,t: float,lift: float) -> Vector2:
	return start.lerp(finish,t)-Vector2(0,4*lift*t*(1-t))

func stamp(flyer: TextureRect,point: Vector2,t: float,alpha := 1.0) -> void:
	flyer.size=FLYER_SIZE
	flyer.pivot_offset=FLYER_SIZE*.5
	flyer.position=point-FLYER_SIZE*.5
	flyer.scale=Vector2.ONE*(1+.12*sin(PI*t))
	flyer.rotation=sin(PI*t)*.22
	flyer.modulate.a=alpha
	flyer.show()

func draw_cycle(progress: float,active: bool) -> void:
	for flyer in ingredient_flyers: flyer.hide()
	stage.flying_output.hide()
	stage.output_icon.scale=Vector2.ONE
	for index in ingredient_flyers.size():
		var icon:=input_control(index)
		icon.pivot_offset=icon.size*.5
		icon.scale=Vector2.ONE
	if not active or openness<.98: return
	stage.transfer_active=false
	if progress>=INPUT_HOP_START and progress<INPUT_HOP_END:
		for index in ingredient_flyers.size():
			var t:=clampf(inverse_lerp(INPUT_HOP_START+index*.025,INPUT_HOP_END-.05+index*.025,progress),0,1)
			if t>=1: continue
			var id: String=top_items[index].get_meta("mat_id")
			var start:=center_in_stage(inventory_icon(id))
			var finish:=center_in_stage(input_control(index))
			stamp(ingredient_flyers[index],hop_point(start,finish,t,120),t,1-smoothstep(.86,1,t))
	elif progress>=CONVERSION_START:
		draw_transfer(clampf(inverse_lerp(CONVERSION_START,1,progress),0,1))
	for index in ingredient_flyers.size():
		var contact:=INPUT_HOP_END-.05+index*.025
		var t:=clampf((progress-contact)/.07,0,1)
		input_control(index).scale=Vector2.ONE*(1+.16*sin(PI*t))

func draw_transfer(t: float) -> void:
	stage.transfer_active=true
	var finish:=center_in_stage(stage.output_icon)
	var morph:=smoothstep(.55,.88,t)
	for index in ingredient_flyers.size():
		var start:=center_in_stage(input_control(index))
		stamp(ingredient_flyers[index],hop_point(start,finish,t,132+index*10),t,1-morph)
	var start:=center_in_stage(input_control(0))
	stage.flying_output.texture=stage.tex(stage.output_id)
	stamp(stage.flying_output,hop_point(start,finish,t,132),t,morph)

func draw_harvest(t: float) -> void:
	var start:=center_in_stage(stage.output_icon)
	var target:=inventory_icon(stage.output_id)
	var finish:=center_in_stage(target)
	stage.harvest_icon.size=FLYER_SIZE
	stamp(stage.harvest_icon,hop_point(start,finish,t,136),t,1-smoothstep(.86,1,t))
	stage.harvest_icon.visible=t<1 and openness>0
	stage.output_icon.pivot_offset=stage.output_icon.size*.5
	stage.output_icon.scale=Vector2.ONE*(1+.12*sin(PI*clampf(t/.22,0,1)))
	target.pivot_offset=target.size*.5
	target.scale=Vector2.ONE*(1+.15*sin(PI*clampf((t-.82)/.18,0,1)))
