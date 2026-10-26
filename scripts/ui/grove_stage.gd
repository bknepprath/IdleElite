extends Control

const HeaderStats = preload("res://scripts/ui/activity_header_stats.gd")

const TREES = preload("res://assets/content/woodcutting/groves/trees.png")
const STUMPS = preload("res://assets/content/woodcutting/groves/stumps.png")
const WALK = preload("res://assets/content/woodcutting/groves/walk-grounded.png")
const CHOP = preload("res://assets/content/woodcutting/groves/chop-grounded.png")
const AXE = preload("res://assets/content/icons/skill-symbols/woodcutting.png")
const XP = preload("res://assets/content/ui/infochip-symbol-xp-outlined.png")
const STAMINA = preload("res://assets/content/ui/infochip-symbol-stamina-outlined.png")
const GameFormatting = preload("res://scripts/core/formatting.gd")
const Geometry = preload("res://scripts/gameplay/grove_geometry.gd")
const FLOOR = preload("res://assets/content/fight/prototype/arena-floor.png")
const SHRUB_BORDER = preload("res://assets/content/woodcutting/groves/shrub-border.png")
const AXE_BADGE_SHADOW = preload("res://assets/content/woodcutting/groves/axe-badge-shadow.tres")
const GOLD_LEAVES = preload("res://assets/content/woodcutting/groves/gold-leaves.svg")
const GOLD_LEAF_DRAW_SIZE := 36.0
# Authored on each tree's shared 512px canvas, inside foliage and clear of ink.
const GOLD_LEAF_POINTS := [
	[Vector2(164,118),Vector2(343,164),Vector2(140,236)],
	[Vector2(252,104),Vector2(201,205),Vector2(333,305)],
	[Vector2(164,118),Vector2(343,164),Vector2(148,251)],
	[Vector2(164,118),Vector2(343,164),Vector2(148,251)],
	[Vector2(229,110),Vector2(390,180),Vector2(85,218)],
	[Vector2(240,120),Vector2(387,178),Vector2(110,215)]
]
const HERO_SIDE := Geometry.HERO_SIDE
const HERO_FRAME_SIZE := Geometry.HERO_FRAME_SIZE
const HERO_GROUND := Geometry.HERO_GROUND
const HERO_OCCLUSION_HEIGHT := 61.0
const TREE_SIDE := Geometry.TREE_SIDE
const INK := Color("#171615")
const AXE_LEVEL_OUTLINE_SIZE := 18
const AXE_BADGE_DRAW_SIZE := Vector2(228,228)
const AXE_BADGE_DRAW_OFFSET := Vector2(-132,-86)
static var shrub_layers: Array[Dictionary] = []
var host
var card: Dictionary
var regular_layout := false
var clock_seconds := 0.0
var axe_button: Button
var shop: Panel
var refresh_seconds := 0.0
var arena_widgets: Array[Control] = []
var arena_buttons: Array[Button] = []

static func attach(owner,record: Dictionary,body: Dictionary) -> void:
	var stage=load("res://scripts/ui/grove_stage.gd").new()
	stage.host=owner
	stage.card=record
	stage.name="TreeGroveStage"
	stage.mouse_filter=Control.MOUSE_FILTER_IGNORE
	stage.z_index=225
	record.pop.add_child(stage)
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.offset_bottom=record.bg.offset_bottom
	stage.clip_contents=true
	(body.margin as Control).hide()
	record.bg.hide()
	record.progress.hide()
	record.title.hide()
	for sibling in record.pop.get_parent().get_children():
		if sibling.name in ["NormalActivityCardBackFace","NormalActivityCardPrismConnectors"]: sibling.hide()
	for child in record.pop.get_children():
		if child.get_script()==preload("res://scripts/ui/activity_card_border.gd"): child.hide()
	if is_instance_valid(record.depth): record.depth.hide()
	if is_instance_valid(record.medal):
		record.medal.hide()
	record["production_stage"]=stage
	record["grove_stage"]=stage
	stage.setup_controls()

func make_button(node_name: String,callback: Callable) -> Button:
	var b:=Button.new()
	b.name=node_name
	configure_button(b,callback)
	return b

func configure_button(b: Button,callback: Callable) -> void:
	b.add_to_group("production_controls")
	b.gui_input.connect(func(event):
		if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE,KEY_ENTER,KEY_KP_ENTER]: b.set_meta("production_valid_tap",true)
	)
	b.pressed.connect(func():
		if not bool(b.get_meta("production_valid_tap",false)): return
		b.set_meta("production_valid_tap",false)
		callback.call()
	)
	b.add_theme_font_size_override("font_size",48)
	b.add_theme_font_override("font",host.app_bold_font)
	for color_name in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		b.add_theme_color_override(color_name,INK)
	b.add_theme_color_override("font_disabled_color",Color("#625b50"))
	for state_name in ["normal","hover","pressed","disabled","focus"]:
		var face:=StyleBoxFlat.new()
		face.bg_color=Color("#d2aa6b") if state_name=="pressed" else (Color("#b6ac98") if state_name=="disabled" else Color("#f4dba4"))
		face.border_color=INK
		face.set_border_width_all(3)
		face.set_corner_radius_all(10)
		b.add_theme_stylebox_override(state_name,face)

func setup_controls() -> void:
	if shrub_layers.is_empty():
		for layer in preload("res://assets/content/woodcutting/groves/shrub-layers.gd").SHRUBS:
			var polygons: Array[PackedVector2Array] = []
			for polygon in layer.polygons:
				var uvs:=PackedVector2Array()
				for point in polygon: uvs.append(point)
				polygons.append(uvs)
			shrub_layers.append({"id":layer.id,"ground_uv":layer.ground_uv,"polygons":polygons})
	axe_button=make_button("AxeShop",func(): shop.visible=not shop.visible;refresh_shop())
	host._apply_empty_button_style(axe_button)
	axe_button.tooltip_text="Axe upgrades"
	add_child(axe_button)
	shop=load("res://scripts/ui/axe_upgrade_shop.gd").new()
	add_child(shop)
	shop.setup(self)
	shop.hide()
	for kind in host._grove_runtime().ARENA_KINDS:
		var widget=load("res://scripts/ui/arena_upgrade_button.gd").new()
		add_child(widget)
		widget.setup(self,{"capacity":"Trees","regrowth":"Rate","rarity":"Luck"}[kind],func(): host._grove_runtime().buy_arena_upgrade(str(card.action_id),kind);refresh_arena())
		arena_widgets.append(widget)
		arena_buttons.append(widget.button)
	refresh_arena()
	layout_arena_controls()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED: layout_arena_controls()

func layout_arena_controls() -> void:
	if not is_instance_valid(axe_button) or not is_instance_valid(shop): return
	axe_button.position=Vector2(size.x-192,160)
	axe_button.size=Vector2(148,148)
	shop.position=Vector2(24,16)
	shop.size=Vector2(size.x-48,size.y-24)
	for index in arena_widgets.size():
		arena_widgets[index].position=Vector2(24+index*(size.x-48)/3.0,size.y-158)
		arena_widgets[index].size=Vector2((size.x-80)/3.0,142)
		arena_widgets[index].layout_controls()

func refresh_arena() -> void:
	var r=host._grove_runtime()
	var id: String=card.action_id
	for index in arena_widgets.size():
		var kind: String=r.ARENA_KINDS[index]
		var value:=str(r.tree_capacity(id)) if kind=="capacity" else (str(roundi(r.regrowth_seconds(id)))+"s" if kind=="regrowth" else str(roundi(r.rare_chance(id)))+"%")
		var help_text: String={"capacity":"Maximum trees in this arena","regrowth":"Time until a tree regrows","rarity":"Gold leaves: +25%, +75%, +200% logs"}[kind]
		if kind=="regrowth": help_text="Regrowth: %.1fs"%r.regrowth_seconds(id)
		arena_widgets[index].refresh(value,r.arena_upgrade_cost(id,kind),help_text)

func refresh_shop() -> void:
	if is_instance_valid(shop) and shop.visible: shop.refresh()

func _process(delta: float) -> void:
	if not is_instance_valid(host) or host.app_bold_font==null: return
	if not is_visible_in_tree() or not get_global_rect().intersects(get_viewport_rect()): return
	clock_seconds+=delta
	host._grove_runtime().field_sizes[str(card.action_id)]=field_rect().size
	layout_arena_controls()
	refresh_seconds+=delta
	if refresh_seconds>.3:
		refresh_seconds=0
		refresh_shop()
		refresh_arena()
	queue_redraw()

func text_at(value: String,point: Vector2,font_size:=48,color:=Color.WHITE,outline_size: int=-1) -> void:
	if host.app_bold_font==null: return
	var stroke:=roundi(font_size*.22) if outline_size<0 else outline_size
	draw_string_outline(host.app_bold_font,point,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,stroke,Color(INK,color.a))
	draw_string(host.app_bold_font,point,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func field_rect() -> Rect2:
	return Rect2(30,206,size.x-60,size.y-406)

func world_point(x: float, depth: float) -> Vector2:
	var field:=field_rect()
	var vertical:=lerpf(-.38,.65,clampf((depth-.32)/.59,0,1))
	var width_at_depth:=Geometry.horizontal_projection(depth)
	return field.get_center()+Vector2((x-450.0)/450.0*field.size.x*.5*width_at_depth,vertical*field.size.y*.5)

func world_scale(depth: float) -> float:
	var field:=field_rect()
	return minf(field.size.x/900.0,field.size.y/360.0)*host._grove_runtime().depth_scale(depth)

func draw_arena() -> void:
	var field:=field_rect()
	var points:=PackedVector2Array()
	var shadow_points:=PackedVector2Array()
	var uvs:=PackedVector2Array()
	for index in 128:
		var unit:=Vector2.from_angle(TAU*float(index)/128.0)
		var point:=field.get_center()+unit*field.size*.5
		points.append(point)
		shadow_points.append(point+Vector2(0,30))
		uvs.append(unit*.5+Vector2(.5,.5))
	draw_colored_polygon(shadow_points,Color("#426325"))
	shadow_points.append(shadow_points[0])
	draw_polyline(shadow_points,INK,6,true)
	draw_polygon(points,PackedColorArray([Color.WHITE]),uvs,FLOOR)
	points.append(points[0])
	draw_polyline(points,INK,6,true)

func shrub_rect() -> Rect2:
	var field:=field_rect()
	return Rect2(field.position+Vector2(-12,-94),field.size+Vector2(24,88))

func shrub_ground_point(layer: Dictionary) -> Vector2:
	var box:=shrub_rect()
	return box.position+(layer.ground_uv as Vector2)*box.size

func draw_shrub(layer: Dictionary) -> void:
	draw_set_transform(Vector2.ZERO)
	var box:=shrub_rect()
	for uvs in layer.polygons:
		var points:=PackedVector2Array()
		for uv in uvs: points.append(box.position+uv*box.size)
		draw_polygon(points,PackedColorArray([Color.WHITE]),uvs,SHRUB_BORDER)

func arena_draw_order(state: Dictionary) -> Array[Dictionary]:
	var draw_order: Array[Dictionary]=[]
	for layer in shrub_layers:
		draw_order.append({"shrub":layer,"depth":shrub_ground_point(layer).y,"order":draw_order.size()})
	for tree in state.trees:
		draw_order.append({"tree":tree,"depth":world_point(float(tree.x),float(tree.y)).y,"order":draw_order.size()})
	draw_order.append({"hero":true,"depth":world_point(float(state.x),float(state.y)).y,"order":draw_order.size()})
	draw_order.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		return float(a.depth)<float(b.depth) if float(a.depth)!=float(b.depth) else int(a.order)<int(b.order))
	return draw_order

func _draw() -> void:
	if not is_instance_valid(host) or host.app_bold_font==null or size.x<100: return
	var r=host._grove_runtime()
	var id: String=card.action_id
	var state: Dictionary=r.state(id)
	draw_arena()
	# Every shrub, tree and worker shares the same projected floor-depth sort.
	for item in arena_draw_order(state):
		if item.has("shrub"): draw_shrub(item.shrub)
		elif item.has("hero"): draw_worker(state,id)
		else: draw_tree(item.tree,int(r.rules(r.source_id(id,item.tree)).get("index",0)),state)
	draw_set_transform(Vector2.ZERO)
	draw_harvests(id)
	if float(state.miss_age)<.5:
		text_at("Miss",world_point(float(state.x),float(state.y))+Vector2(-40,-125-float(state.miss_age)*20),48,Color(1,1,1,1-float(state.miss_age)*2))
	draw_header(state,id)
	var center:=Vector2(size.x-118,234)
	draw_texture_rect(AXE_BADGE_SHADOW,Rect2(center+Vector2(0,10)-Vector2(96,96),Vector2(192,192)),false)
	draw_circle(center,70,Color("#f4dda8"))
	draw_zoomed_axe(center)
	draw_arc(center,70,0,TAU,96,INK,8,true)
	draw_arc(center,70,-PI*.5,-PI*.5+TAU*r.level_progress(),96,Color("#77ae37"),8,true)
	draw_curved_level("Lv "+str(r.axe_level()),center)


func top_stats(state: Dictionary,id: String) -> Array[Dictionary]:
	var r=host._grove_runtime()
	var selected: Dictionary=state.trees[int(state.target)]
	var material: String=r.tree_material(id,selected)
	var logs: Texture2D=host.visual_texture_cache._texture_or_visual_fallback(host.material_runtime.icon_path(material))
	var xp: Dictionary=r.tree_xp_rewards(id,selected)
	var stamina: float=host._action_runtime()._effective_stamina("woodcutting",card.action)
	var cost:=str(int(stamina)) if is_equal_approx(stamina,roundf(stamina)) else str(snappedf(stamina,.01))
	var values: Array[Dictionary]=[
		{"icon":logs,"text":GameFormatting.compact_inventory_number(host.material_runtime.amount(material)),"icon_width":48.0},
		{"icon":XP,"text":str(xp.get("woodcutting",1)),"icon_width":58.0},
		{"icon":STAMINA,"text":cost,"icon_width":40.0}]
	return HeaderStats.layout(values,host.app_bold_font,48,size.x-30,94)

func draw_icon_fitted(texture: Texture2D,box: Rect2,tint:=Color.WHITE) -> void:
	var extent:=texture.get_size()
	var scale:=minf(box.size.x/extent.x,box.size.y/extent.y)
	var draw_size:=extent*scale
	draw_texture_rect(texture,Rect2(box.get_center()-draw_size*.5,draw_size),false,tint)

func draw_harvests(id: String) -> void:
	for burst in host._grove_runtime().harvest_bursts:
		if str(burst.id)!=id: continue
		var origin:=world_point(float(burst.x),float(burst.y))-Vector2(0,35)
		var texture_log: Texture2D=host.visual_texture_cache._texture_or_visual_fallback(host.material_runtime.icon_path(str(burst.material)))
		# One sprite for each awarded unit, with independent staggered lifetimes.
		for index in int(burst.amount):
			var age: float=float(burst.age)-float(index)*.025
			if age<0 or age>=1.2: continue
			var t:=age/1.2
			var ease:=1-pow(1-t,3)
			var lane:=float(index%7)-3.0
			var point:=origin+Vector2(lane*44*ease,-(85+float(index%3)*18+float(index/7)*14)*ease)
			point.x=clampf(point.x,field_rect().position.x+24,field_rect().end.x-24)
			point.y=maxf(field_rect().position.y+24,point.y)
			draw_icon_fitted(texture_log,Rect2(point-Vector2(24,24),Vector2(48,48)),Color(1,1,1,1-smoothstep(.6,1,t)))

func draw_header(state: Dictionary,id: String) -> void:
	var values:=top_stats(state,id)
	var title: String=card.action.name
	var available_width: float=float(values[0].position.x)-48
	if host.app_bold_font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,60).x>available_width:
		var split:=title.rfind(" ")
		text_at(title.substr(0,split),Vector2(28,66),60)
		text_at(title.substr(split+1),Vector2(28,128),60)
	else: text_at(title,Vector2(28,94),60)
	for item in values:
		var point: Vector2=item.position
		draw_icon_fitted(item.icon,Rect2(point+Vector2(0,-48),item.icon_size))
		text_at(item.text,point+Vector2(float(item.icon_width)+HeaderStats.ICON_GAP,0),48)

func draw_zoomed_axe(center: Vector2) -> void:
	# A fixed authored crop, like the skill logo, clipped to the ring interior.
	var points:=PackedVector2Array()
	var uvs:=PackedVector2Array()
	for index in 96:
		var point:=Vector2.from_angle(TAU*float(index)/96.0)*66.0
		points.append(center+point)
		uvs.append((point-AXE_BADGE_DRAW_OFFSET)/AXE_BADGE_DRAW_SIZE)
	draw_polygon(points,PackedColorArray([Color.WHITE]),uvs,AXE)

func draw_curved_level(value: String,center: Vector2) -> void:
	var font: Font=host.app_bold_font
	if font==null: return
	var width:=font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,48).x
	var cursor: float=-width*.5
	for index in value.length():
		var character:=value.substr(index,1)
		var advance:=font.get_string_size(character,HORIZONTAL_ALIGNMENT_LEFT,-1,48).x
		# A shallow circular baseline keeps the compact label legible.
		var angle: float=(cursor+advance*.5)/145.0
		var point:=center+Vector2(sin(angle)*145.0,-83.0+cos(angle)*145.0)
		draw_set_transform(point,-angle)
		text_at(character,Vector2(-advance*.5,0),48,Color.WHITE,AXE_LEVEL_OUTLINE_SIZE)
		cursor=font.get_string_size(value.substr(0,index+1),HORIZONTAL_ALIGNMENT_LEFT,-1,48).x-width*.5
	draw_set_transform(Vector2.ZERO)

func draw_worker(state: Dictionary,id: String) -> void:
	var r=host._grove_runtime()
	var alpha: float=r.worker_opacity(id)
	if alpha<=0: return
	var active: bool=r.applies(host.running_skill_id,host.running_action_id) and host.running_action_id==id
	var frame:=int(float(state.age)*10)%8 if state.phase=="walking" and active and not r.worker_entering(id) else 0
	var texture: Texture2D=WALK
	if state.phase in ["chopping","falling"] and not r.worker_entering(id):
		texture=CHOP
		var phase: float=float(state.age)/r.swing_seconds(id)
		frame=0 if phase<.5 else (1 if phase<.72 else 2)
		if state.phase=="falling": frame=2
	var point:=world_point(float(state.x),float(state.y))
	var scale:=world_scale(float(state.y))
	draw_set_transform(point,0,Vector2(scale,scale*.3))
	draw_circle(Vector2.ZERO,29,Color(0,0,0,.18*alpha))
	draw_set_transform(point,0,Vector2(scale*float(state.direction),scale))
	# Shared foot-based canvas preserves original pixels per world unit in
	# both states; head movement never changes the ground anchor.
	var pixels_per_unit:=HERO_SIDE/HERO_FRAME_SIZE
	draw_texture_rect_region(texture,Rect2(-HERO_GROUND*pixels_per_unit,Vector2.ONE*HERO_SIDE),Rect2(frame*HERO_FRAME_SIZE,0,HERO_FRAME_SIZE,HERO_FRAME_SIZE),Color(1,1,1,alpha))
	draw_set_transform(Vector2.ZERO)

func draw_tree(tree: Dictionary,index: int,worker: Dictionary) -> void:
	var stump_alpha: float=host._grove_runtime().stump_opacity(str(card.action_id),tree)
	if tree.phase=="stump" and stump_alpha<=0: return
	var point:=world_point(float(tree.x),float(tree.y))
	var scale:=world_scale(float(tree.y))
	var region:=Rect2((index%3)*512,(index/3)*512,512,512)
	# The final grove's rare mature Ironwood has one authored 1.08x state size.
	var side: float=Geometry.tree_side(bool(tree.get("bountiful",false)),host._grove_runtime().tree_multiplier(str(card.action_id),tree)>1)
	var top: float=-side*490/512
	var alpha:=clampf(float(tree.get("spawn_age",1))/.45,0,1)
	var worker_point:=world_point(float(worker.x),float(worker.y))-Vector2(0,HERO_OCCLUSION_HEIGHT*world_scale(float(worker.y)))
	var crown:=Rect2(point+Vector2(-side*.5,top)*scale,Vector2(side,side*.85)*scale)
	if float(tree.y)>float(worker.y) and crown.has_point(worker_point): alpha*=lerpf(1,.45,host._grove_runtime().worker_opacity(str(card.action_id)))
	draw_set_transform(point,0,Vector2(scale,scale*.3))
	draw_circle(Vector2.ZERO,42,Color(0,0,0,.14*alpha*(stump_alpha if tree.phase=="stump" else 1.0)))
	draw_set_transform(point,0,Vector2(scale,scale))
	if tree.phase in ["stump","falling"]:
		draw_texture_rect_region(STUMPS,Rect2(-side*.5,top,side,side),region,Color(1,1,1,stump_alpha))
	if tree.phase=="stump":
		draw_set_transform(Vector2.ZERO)
		return
	var rotation:=sin(float(tree.hit)*48)*float(tree.hit)*.09
	if tree.phase=="falling":
		var t:=clampf(float(tree.age)/1.1,0,1)
		rotation=float(tree.fall_direction)*pow(t,1.8)*1.35
		alpha*=1-smoothstep(.55,1.0,t)
		var cut:=445.0 if index==1 else 405.0
		var height: float=side*cut/512
		region.size.y=cut
		draw_set_transform(point+Vector2(0,(top+height)*scale),rotation,Vector2(scale,scale))
		draw_texture_rect_region(TREES,Rect2(-side*.5,-height,side,height),region,Color(1,1,1,alpha))
		draw_gold_leaves(tree,index,side,-height,alpha)
	else:
		draw_set_transform(point,rotation,Vector2(scale,scale))
		var tint:=Color(1.12,1.06,.78,alpha) if bool(tree.get("bountiful",false)) else Color(1,1,1,alpha)
		draw_texture_rect_region(TREES,Rect2(-side*.5,top,side,side),region,tint)
		draw_gold_leaves(tree,index,side,top,alpha)
	draw_set_transform(Vector2.ZERO)

func draw_gold_leaves(tree: Dictionary,index: int,side: float,top: float,alpha: float) -> void:
	var count: int=host._grove_runtime().tree_gold_leaf_count(str(card.action_id),tree)
	# Persistent leaves share the canopy transform and remain countable until
	# the tree fades. No outline or separate sparkle is drawn around them.
	for leaf_index in count:
		draw_texture_rect_region(GOLD_LEAVES,gold_leaf_rect(index,leaf_index,side,top),Rect2((leaf_index%2)*256,0,256,256),Color(1,1,1,alpha))

func gold_leaf_rect(index: int,leaf_index: int,side: float,top: float) -> Rect2:
	var anchor: Vector2=GOLD_LEAF_POINTS[index][leaf_index]/512.0
	var point:=Vector2((anchor.x-.5)*side,top+anchor.y*side)
	return Rect2(point-Vector2.ONE*GOLD_LEAF_DRAW_SIZE*.5,Vector2.ONE*GOLD_LEAF_DRAW_SIZE)
