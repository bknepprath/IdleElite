extends Control

const ROOT := "res://assets/content/production/"
const RoundedTextureRect = preload("res://scripts/ui/rounded_texture_rect.gd")
var host
var card: Dictionary
var variant := ""
var phase := 0.0
var clock_seconds := 0.0
var running := false
var textures: Dictionary = {}
var count_label: Label
var ingredient_row: HBoxContainer
var controls: HBoxContainer
var buttons: Array[Button] = []
var actor: Control
var status_elapsed := 0.0
var ingredient_signature := ""
var inventory_material := ""
var regular_layout := false
var compact_inventory_icon: TextureRect

static func attach(owner, record: Dictionary, body: Dictionary) -> void:
	var presentation: Dictionary = record.action.get("presentation", {})
	if presentation.is_empty() or is_instance_valid(record.get("blue_guy_chicken_stage")): return
	if str(presentation.get("stage","")) == "rockslide":
		preload("res://scripts/ui/rockslide_stage.gd").attach(owner,record,body)
		return
	if str(presentation.get("stage","")) == "tree-grove":
		preload("res://scripts/ui/grove_stage.gd").attach(owner,record,body)
		return
	if str(presentation.get("stage","")) == "slingshot-range":
		preload("res://scripts/ui/slingshot_range_stage.gd").attach(owner,record,body)
		return
	var stage = load("res://scripts/production/converter_stage.gd" if str(presentation.get("layout", "")) == "activity" else "res://scripts/production/stage.gd").new()
	stage.host = owner
	stage.card = record
	stage.variant = str(presentation.get("stage", "workbench"))
	stage.name = "ProductionActionStage"
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.z_index = 225
	record.pop.add_child(stage)
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if str(presentation.get("layout",""))=="compact":
		stage.regular_layout = true
		stage.setup_controls()
		record["production_stage"] = stage
		return
	if str(presentation.get("layout", "")) == "activity":
		stage.regular_layout = true
		stage.setup_converter(body)
		record["production_stage"] = stage
		return
	stage.offset_top = 120
	stage.anchor_bottom = 0
	stage.offset_bottom = float(presentation.get("height",520))-164
	for sibling in record.pop.get_parent().get_children():
		if sibling.name in ["NormalActivityCardBackFace","NormalActivityCardPrismConnectors"]: sibling.visible=false
	if is_instance_valid(record.progress): record.progress.visible=false
	record.bg.offset_bottom=0
	if record.bg is RoundedTextureRect:
		record.bg.crop_left=.15
		record.bg.crop_right=.15
	if is_instance_valid(record.border): record.border.offset_bottom=0
	if stage.variant in ["physical","harvest","sneak"] or bool(presentation.get("open",false)):
		record.bg.visible = false
		for sibling in record.pop.get_parent().get_children():
			if sibling.name in ["NormalActivityCardBackFace","NormalActivityCardPrismConnectors"]: sibling.visible=false
		for child in record.pop.get_children():
			if child.get_script() == preload("res://scripts/ui/activity_card_border.gd"): child.visible=false
		if is_instance_valid(record.shade): record.shade.visible=false
	(body.margin as Control).visible = false
	var copy: VBoxContainer = body.copy
	copy.reparent(record.pop)
	copy.z_index = 240
	copy.position = Vector2(26, float(presentation.get("height", 520))-110)
	if bool(presentation.get("building", false)):
		copy.position.y -= 64.0
		stage.offset_bottom -= 64.0
	copy.size.x = 880
	record.stat_row.custom_minimum_size.y = 80
	for old_panel in record.stat_row.get_children(): old_panel.hide()
	var visible_stats := ["xp", "time"] if bool(presentation.get("building", false)) else ["xp","time","stamina","success"]
	for kind in visible_stats:
		var box: Control = record.stat_boxes[kind]
		box.reparent(record.stat_row)
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.custom_minimum_size = Vector2(0,80)
		if box.has_meta("normal_activity_stat_symbol"):
			box.get_meta("normal_activity_stat_symbol").custom_minimum_size = Vector2(64,64)
	record.stat_row.add_theme_constant_override("separation",16)
	for name in ["xp","time","stamina","success"]:
		if is_instance_valid(record.get(name)): record[name].add_theme_font_size_override("font_size",48)
	for child in copy.get_children():
		if child != record.stat_row: child.visible = false
	record.title.add_theme_font_size_override("font_size", 60)
	if record.title.get_parent() is MarginContainer:
		record.title.get_parent().offset_bottom = 104
	if is_instance_valid(record.medal):
		record.medal.reparent(record.pop)
		record.medal.position = Vector2(22,106)
		record.medal.size = Vector2(76,76)
		record.medal.z_index = 270
	# Keep the portrait's square outline under its hidden original parent;
	# the open stage uses a compact mastery arc beside its medal instead.
	if variant_for_action(record.action) in ["action","illustrated"] and is_instance_valid(record.art):
		record.art.reparent(stage)
		record.art.visible = true
		record.art.position = Vector2(180,0)
		record.art.size = Vector2(550,320)
		record.art.set_deferred("size",Vector2(550,320))
		record.art.custom_minimum_size = Vector2.ZERO
		if record.art.has_method("set_mask_material_enabled"): record.art.set_mask_material_enabled(false)
		if record.art is TextureRect: record.art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		stage.actor = record.art
	stage.setup_controls()
	record["production_stage"] = stage

static func variant_for_action(action: Dictionary) -> String:
	return str(action.get("presentation", {}).get("stage", ""))

func tex(id: String) -> Texture2D:
	if not textures.has(id):
		var path: String = host.material_runtime.icon_path(id) if host.material_runtime.has_definition(id) else ROOT+id+".png"
		textures[id] = host.visual_texture_cache._texture_or_visual_fallback(path)
	return textures[id] as Texture2D

func label(text: String, font_size := 48) -> Label:
	var result: Label = host._label(text,font_size,Color.WHITE,HORIZONTAL_ALIGNMENT_LEFT)
	result.add_theme_constant_override("outline_size",10)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result

func button(text: String, callback: Callable, row: HBoxContainer) -> Button:
	var result := Button.new()
	result.text = text
	result.add_to_group("production_controls")
	allow_keyboard_activation(result)
	result.custom_minimum_size = Vector2(124,76)
	result.add_theme_font_override("font",host.app_bold_font)
	result.add_theme_font_size_override("font_size",48)
	for name in ["normal","hover","pressed","disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#f6e7bc") if name != "pressed" else Color("#8bc57b")
		if name=="disabled": style.bg_color=Color("#dbc9a0")
		style.border_color = Color.BLACK
		style.set_border_width_all(5)
		style.set_corner_radius_all(20)
		result.add_theme_stylebox_override(name,style)
	result.add_theme_color_override("font_color",Color("#181817"))
	result.add_theme_color_override("font_disabled_color",Color("#7d7158"))
	result.pressed.connect(func():
		if OS.get_environment("IDLE_ELITE_PRODUCTION_INPUT_TRACE")=="1": print("PROD_CALLBACK ",text," token=",result.get_meta("production_valid_tap",false))
		if not consume_activation(result): return
		if not host._activity_unlock_runtime()._is_action_unlocked(str(card.skill_id),card.action): return
		callback.call()
		host._mark_save_dirty("production control")
		host._action_runtime().invalidate_stat_cache()
		refresh_controls()
	)
	row.add_child(result)
	host.button_press_runtime.attach_button_depress_animation(result)
	buttons.append(result)
	return result

func allow_keyboard_activation(control: BaseButton) -> void:
	control.gui_input.connect(func(event):
		if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE,KEY_ENTER,KEY_KP_ENTER]: control.set_meta("production_valid_tap",true)
	)

func consume_activation(control: BaseButton) -> bool:
	if not bool(control.get_meta("production_valid_tap",false)): return false
	control.set_meta("production_valid_tap",false)
	return true

func setup_controls() -> void:
	ingredient_row = HBoxContainer.new()
	ingredient_row.position = Vector2(120,size.y-62)
	ingredient_row.add_theme_constant_override("separation",10)
	ingredient_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ingredient_row)
	if regular_layout:
		compact_inventory_icon=TextureRect.new()
		compact_inventory_icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		compact_inventory_icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		compact_inventory_icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
		compact_inventory_icon.size=Vector2(60,60)
		add_child(compact_inventory_icon)
	count_label = label("")
	count_label.position = Vector2(size.x-145,0)
	add_child(count_label)
	controls = HBoxContainer.new()
	controls.add_theme_constant_override("separation",8)
	controls.z_index = 310
	add_child(controls)
	var production = host._production_runtime()
	var id := str(card.action_id)
	if id == "loot-beehive":
		button("Store",func(): production.state.bottling = not bool(production.state.bottling),controls)
		button("Use",func(): production.open_honey(),controls)
	elif id == "assemble-spyglass":
		button("Scout",func(): scout_next(),controls)
		button("Bait",func(): toggle_scout_bait(),controls)
	elif id == "mix-fishing-bait":
		button("Scout",func(): scout_next(),controls)
		button("Bait",func(): toggle_scout_bait(),controls)
	elif id == "weave-selective-net":
		button("Select",func(): production.state.selective_net = not bool(production.state.selective_net),controls)
	elif not production.recipe(card.action).is_empty() and id != "explore-dark-passage":
		button("+1",func(): production.enqueue(id),controls)
	elif id == "repair-waterwheel":
		button("Clear",func(): await open_activity("fight","fight-the-current"),controls)
		button("Glass",func(): production.enqueue("melt-sand"),controls)
		button("Bottle",func(): production.enqueue("shape-bottles"),controls)
	refresh_controls()
	layout_controls()

func _notification(what: int) -> void:
	if what==NOTIFICATION_RESIZED: layout_controls()

func layout_controls() -> void:
	if regular_layout:
		if is_instance_valid(ingredient_row): ingredient_row.position = Vector2(32, 294)
		if is_instance_valid(controls): controls.position = Vector2(32, 356)
		if is_instance_valid(count_label):
			count_label.visible = str(card.action_id) in ["loot-beehive","repair-waterwheel","fight-the-current"]
			count_label.position = Vector2(592,356) if str(card.action_id)!="fight-the-current" else Vector2(32,294)
		if is_instance_valid(compact_inventory_icon):
			compact_inventory_icon.position=Vector2(520,356)
			compact_inventory_icon.visible=not inventory_material.is_empty() and str(card.action_id)=="loot-beehive"
			if compact_inventory_icon.visible: compact_inventory_icon.texture=tex(inventory_material)
		return
	if is_instance_valid(ingredient_row): ingredient_row.position=Vector2(110,size.y-28)
	if is_instance_valid(controls): controls.position=Vector2(maxf(520,size.x-controls.get_combined_minimum_size().x-28),size.y-28)
	if is_instance_valid(count_label): count_label.position=Vector2(size.x-145,0)

func scout_action() -> String:
	var ids: Array = host._production_runtime().rules.get("scouting", {}).keys()
	if ids.is_empty(): return ""
	return str(ids[int(host._production_runtime().state.scout_index) % ids.size()])

func scout_next() -> void:
	var production = host._production_runtime()
	if host.material_runtime.amount("spyglass") < 1: return
	production.state.scout_index = int(production.state.scout_index) + 1
	host._mark_save_dirty("scouting target")
	# The resource and location are shown together before choosing bait.
	refresh_controls()

func toggle_scout_bait() -> void:
	var id := scout_action()
	host._production_runtime().toggle_bait(id)
	if host.material_runtime.amount("spyglass") >= 1:
		host._production_runtime().navigate_to_action("fishing",id)

func add_ingredient(id: String, amount: float, output := false) -> void:
	var picture := TextureButton.new()
	picture.texture_normal = host.visual_texture_cache._texture_or_visual_fallback(host.material_runtime.icon_path(id))
	picture.ignore_texture_size = true
	picture.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	picture.custom_minimum_size = Vector2(58,58)
	picture.add_to_group("production_controls")
	allow_keyboard_activation(picture)
	picture.pressed.connect(func():
		if consume_activation(picture): await open_material_source(id)
	)
	ingredient_row.add_child(picture)
	var count := label(str(int(amount)))
	if not output and host.material_runtime.amount(id) < amount: count.modulate = Color("#ffb29c")
	ingredient_row.add_child(count)

func refresh_controls() -> void:
	if not is_instance_valid(count_label): return
	var production = host._production_runtime()
	var mats = host.material_runtime
	var id := str(card.action_id)
	var definition: Dictionary = production.recipe(card.action)
	if id=="repair-waterwheel": definition={"inputs":production.rules.waterwheel.cost} if not production.state.wheel_built else {}
	var signature := str(definition)
	if id=="repair-waterwheel":
		for job in production.state.queue: signature+=str(job.key)
	if id=="loot-beehive": signature+=str(mats.amount("empty-bottle"))+str(production.state.partial_honey)
	if id in ["assemble-spyglass","mix-fishing-bait"]: signature+=str(production.state.scout_index)+str(mats.amount("spyglass")>=1)
	for material in definition.get("inputs", {}): signature += str(mats.amount(str(material)) >= float(definition.inputs[material]))
	if signature != ingredient_signature:
		ingredient_signature = signature
		for child in ingredient_row.get_children():
			ingredient_row.remove_child(child)
			child.queue_free()
		if id=="repair-waterwheel" and production.state.wheel_built:
			for job in production.state.queue.slice(0,3):
				for material in production.rules.recipes[job.id].get("outputs",{}): add_ingredient(str(material),production.rules.recipes[job.id].outputs[material],true)
		elif id=="loot-beehive":
			add_ingredient("empty-bottle",mats.amount("empty-bottle"),true)
			add_ingredient("honey",int(production.state.partial_honey),true)
			ingredient_row.add_child(label("/ 6"))
		elif id in ["assemble-spyglass","mix-fishing-bait"] and mats.amount("spyglass")>=1:
			var target := scout_action()
			ingredient_row.add_child(label(str(host._action_data("fishing",target).get("name",target))+" →"))
			add_ingredient(production.scouting_target(target),1,true)
		else:
			for material in definition.get("inputs", {}): add_ingredient(str(material),float(definition.inputs[material]))
		if not definition.get("outputs",{}).is_empty() and not (id in ["assemble-spyglass","mix-fishing-bait"] and mats.amount("spyglass")>=1):
			ingredient_row.add_child(label("→"))
			for material in definition.get("outputs", {}): add_ingredient(str(material),float(definition.outputs[material]),true)
	count_label.text = ""
	inventory_material=""
	if id == "loot-beehive":
		inventory_material="honey-bottle"
		count_label.text = str(int(mats.amount("bottled-honey")))
		buttons[0].modulate = Color("#91e593") if production.state.bottling else Color.WHITE
		buttons[1].disabled = mats.amount("bottled-honey") < 1
	elif id in ["assemble-spyglass","mix-fishing-bait"] and mats.amount("spyglass") >= 1:
		var target := scout_action()
		inventory_material="spyglass" if id=="assemble-spyglass" else "bait"
		count_label.text=str(int(mats.amount(inventory_material)))
		if buttons.size()>1: buttons[1].modulate = Color("#91e593") if production.state.bait_locations.get(target,false) else Color.WHITE
	elif id in ["fight-the-current","repair-waterwheel"]:
		count_label.text = "%s / 8" % int(production.state.wheel_clearance if id=="fight-the-current" else production.state.wheel_progress)
		if id=="repair-waterwheel" and production.state.wheel_built: count_label.text = "%s / 12" % production.state.queue.size()
		if id=="repair-waterwheel":
			buttons[0].visible=not production.state.wheel_built and int(production.state.wheel_clearance)<8
			buttons[1].visible=production.state.wheel_built
			buttons[2].visible=production.state.wheel_built
	elif id == "weave-selective-net" and mats.amount("precision-net")>=1:
		buttons[0].modulate = Color("#91e593") if production.state.selective_net else Color.WHITE
	elif not definition.is_empty():
		for material in definition.get("outputs", {}):
			inventory_material=str(material)
			count_label.text=str(int(mats.amount(str(material))))
			break
	elif not card.action.get("mat_rewards", []).is_empty():
		for reward in card.action.mat_rewards:
			inventory_material=str(reward.id)
			count_label.text=str(int(mats.amount(str(reward.id))))
			break
	if not definition.is_empty() and buttons.size()==1 and buttons[0].text=="+1":
		buttons[0].visible = bool(production.state.wheel_built) and int(definition.get("limit",0))==0
	if id in ["assemble-spyglass","mix-fishing-bait"]:
		for control in buttons: control.disabled=mats.amount("spyglass")<1
	layout_controls()
	queue_redraw()

func open_activity(skill: String, id: String) -> void:
	host._production_runtime().navigate_to_action(skill,id)

func open_material_source(material: String) -> void:
	var best := {}
	var best_rate := -1.0
	for skill in host.actions_by_skill:
		for action in host.actions_by_skill[skill]:
			var amount := float(host._production_runtime().recipe(action).get("outputs", {}).get(material,0))
			for reward in action.get("mat_rewards", []):
				if str(reward.get("id",""))==material: amount += float(reward.get("amount",reward.get("max",0)))
			if amount<=0: continue
			var rate: float = amount/maxf(.1,float(action.seconds))
			if not host._activity_unlock_runtime()._is_action_unlocked(str(skill),action): rate *= .001
			if rate>best_rate: best={"skill":skill,"id":str(action.id)}; best_rate=rate
	if best.is_empty(): return
	host._production_runtime().navigate_to_action(str(best.skill),str(best.id))

func _process(delta: float) -> void:
	if not is_visible_in_tree() or not get_global_rect().intersects(get_viewport_rect()): return
	clock_seconds += delta
	running = host.running_skill_id == str(card.skill_id) and host.running_action_id == str(card.action_id)
	phase = float(host.action_progress) if running else 0.0
	if variant=="wheel" and host._production_runtime().state.wheel_built and not host._production_runtime().state.queue.is_empty():
		var job: Dictionary=host._production_runtime().state.queue[0]
		phase=float(job.elapsed)/maxf(1,float(host._action_data("build",str(job.id)).seconds))
	if is_instance_valid(actor):
		var ground: float=float(card.action.presentation.get("ground_anchor",[.5,.95])[1])*320.0
		actor.position=Vector2((size.x-550)*.5+(sin(phase*TAU)*18 if running else 0),size.y+40-ground+(sin(phase*TAU*2)*-6 if running else 0))
		actor.pivot_offset=Vector2(275,ground)
		actor.rotation=sin(phase*TAU)*.025 if running else 0
	status_elapsed += delta
	if status_elapsed > 0.3:
		status_elapsed = 0
		refresh_controls()
	if running or variant in ["wheel","current","hive","explore"]: queue_redraw()

func sprite(id: String, rect: Rect2, rotation_angle := 0.0) -> void:
	var texture := tex(id)
	if texture == null: return
	if rotation_angle != 0:
		draw_set_transform(rect.get_center(),rotation_angle)
		draw_texture_rect(texture,Rect2(-rect.size*0.5,rect.size),false)
		draw_set_transform(Vector2.ZERO)
	else: draw_texture_rect(texture,rect,false)

func _draw() -> void:
	if regular_layout: return
	if host == null or size.x < 50: return
	var w := size.x
	var mastery_key: String = host._action_key(str(card.skill_id),str(card.action_id))
	var mastery_fraction: float = preload("res://scripts/progression/mastery_state.gd").progress_pct(host.mastery,mastery_key,host.MASTERY_MAX_LEVEL)/100.0
	draw_arc(Vector2(64,26),46,-PI*.5,PI*1.5,48,Color("#191817"),6,true)
	if mastery_fraction>0:
		draw_arc(Vector2(64,26),46,-PI*.5,-PI*.5+TAU*mastery_fraction,48,Color("#efbd42"),5,true)
	var floor_y := size.y - 40
	if variant=="illustrated": floor_y=size.y+40
	var active := running
	var lift := sin(phase*PI)*12 if active else 0.0
	# A broad material stage replaces the old portrait box. Its floor differs
	# by task and remains separate from transient effects and character frames.
	var floor_color := Color("#9d744b") if variant in ["workbench","bottle","lens","parts","scout","candle","bait"] else Color("#6c9153")
	if variant in ["kiln","sand"]: floor_color = Color("#d2ae6d")
	if variant in ["explore","sneak"]: floor_color = Color("#746b84")
	var floor_left := (w-520)*.5 if variant=="illustrated" else 90.0
	var floor_width := 520.0 if variant=="illustrated" else w-180
	draw_style_box(floor_style(floor_color),Rect2(floor_left,floor_y-24,floor_width,28))
	if running or (variant=="wheel" and not host._production_runtime().state.queue.is_empty()): draw_line(Vector2(floor_left+16,floor_y-9),Vector2(floor_left+16+(floor_width-32)*phase,floor_y-9),Color("#ffe05c"),6,true)
	if not inventory_material.is_empty():
		var inventory_texture: Texture2D = tex(inventory_material)
		if inventory_texture!=null: draw_texture_rect(inventory_texture,Rect2(w-215,0,58,58),false)
	var pose := 0
	if active:
		var poses: Array = [0,1,2,3,1,0] if variant in ["sand","harvest","hive"] else [0,1,4,1,4,0]
		pose = int(poses[mini(5,int(phase*6))])
	if variant=="rest": pose=5
	var actor_box := Rect2(w*0.24,floor_y-225,240,240)
	if bool(card.action.get("presentation", {}).get("building", false)):
		# One fixed building pose box keeps every frame below the title while
		# retaining the same floor anchor after reserving space for the notch.
		actor_box = Rect2(w*0.24+19, floor_y-187, 202, 202)
	if variant in ["sneak","explore"]:
		actor_box.position.x += (sin(phase*TAU)*35 if active else 0)
		pose = 2 if active and phase<0.5 else 1
	if variant not in ["action","illustrated"]: sprite("worker-%s"%pose,actor_box)
	var prop_box := Rect2(w*0.43,floor_y-215-lift,240,240)
	match variant:
		"sand": sprite("sand",prop_box)
		"kiln":
			sprite("kiln",prop_box)
			if active:
				var center := prop_box.position + prop_box.size*Vector2(.36,.72)
				draw_colored_polygon(PackedVector2Array([center+Vector2(-25,20),center+Vector2(-20,-15),center+Vector2(-4,-45-sin(clock_seconds*9)*6),center+Vector2(5,-8),center+Vector2(22,-22),center+Vector2(28,20)]),Color("#ff9236"))
				draw_circle(center+Vector2(0,4),15,Color("#ffe77a"))
		"wheel","current":
			var moving: bool = active or (bool(host._production_runtime().state.wheel_built) and not host._production_runtime().state.queue.is_empty())
			sprite("wheel",prop_box,clock_seconds*0.55 if moving else -0.15)
			for i in 3:
				var points := PackedVector2Array()
				for j in 20: points.append(Vector2(w*0.43+j*22,floor_y-8+i*8+sin(j*.5+clock_seconds)*3))
				draw_polyline(points,Color("#66c8dd"),5,true)
		"hive":
			sprite("hive",prop_box)
			if str(card.action_id)=="loot-beehive":
				var bottle_box := Rect2(w*.76,floor_y-135,120,140)
				sprite("bottle",bottle_box)
				var fill: float = float(host._production_runtime().state.partial_honey)/6.0
				if fill>0:
					var source_size: Vector2 = tex("honey-bottle").get_size()
					draw_texture_rect_region(tex("honey-bottle"),Rect2(bottle_box.position+Vector2(0,bottle_box.size.y*(1-fill)),Vector2(bottle_box.size.x,bottle_box.size.y*fill)),Rect2(Vector2(0,source_size.y*(1-fill)),Vector2(source_size.x,source_size.y*fill)))
			for i in 3:
				var bee := prop_box.position+Vector2(35+sin(clock_seconds*1.7+i*2)*44,25+cos(clock_seconds*2+i)*20)
				draw_circle(bee,6,Color.BLACK)
				draw_circle(bee,4,Color("#ffc735"))
		"bottle": sprite("bottle",prop_box)
		"lens": sprite("lens",prop_box,phase*0.3 if active else 0)
		"parts": sprite("wooden-parts",prop_box,sin(phase*TAU)*.06 if active else 0)
		"candle": sprite("candle",prop_box)
		"bait": sprite("bait",prop_box)
		"lantern","explore":
			sprite("lantern",prop_box)
			if active and variant=="explore":
				draw_circle(prop_box.get_center(),55,Color(1,.87,.4,.16))
		"scout":
			if host.material_runtime.amount("spyglass")>=1 or (active and phase>.8):
				sprite("spyglass",prop_box,-sin(phase*TAU)*.12 if active else 0)
			else:
				var fitting := smoothstep(.12,.76,phase) if active else 0.0
				var eyepiece_position := Vector2(-85,145).lerp(Vector2(9,138),fitting)
				# The far lens fits behind the opaque tube; only the front glass faces us.
				if fitting < .65: sprite("lens",Rect2(prop_box.position+eyepiece_position,Vector2(30,40)))
				sprite("wooden-tube",prop_box)
				var lens_position := Vector2(-65,96).lerp(Vector2(157,58),fitting)+Vector2(0,-sin(fitting*PI)*50)
				sprite("lens",Rect2(prop_box.position+lens_position,Vector2(76,96)))
		"net": sprite("precision-net",prop_box)
		"physical": sprite("gate",prop_box,sin(phase*TAU)*0.06 if active else 0)
		"sneak": sprite("chest",prop_box)
		"harvest": sprite("tree",prop_box,sin(phase*TAU)*0.03 if active else 0)
		"workbench": sprite("gate",prop_box)
		"rest": sprite("sand",Rect2(w*.5,floor_y-110,180,180))
	if active and phase>.7 and variant not in ["wheel","current","scout","explore","illustrated"]:
		for i in 4:
			var particle := prop_box.get_center()+Vector2((i-1.5)*22,-(phase-.7)*150-i*7)
			draw_circle(particle,4,Color(1,.85,.45,(1-phase)*2))

func floor_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("#171615")
	style.set_border_width_all(4)
	style.set_corner_radius_all(12)
	return style
