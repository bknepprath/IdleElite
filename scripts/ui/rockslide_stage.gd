extends Control

const HeaderStats = preload("res://scripts/ui/activity_header_stats.gd")

const SkillState = preload("res://scripts/progression/skill_state.gd")
const HILL = preload("res://assets/content/fight/rockslide/hillside.png")
const SlingshotAnimation = preload("res://scripts/ui/slingshot_animation.gd")
const ROCK = preload("res://assets/content/fight/rockslide/rock-damage.png")
const RUNNER = preload("res://assets/content/fight/rockslide/runner-damage.png")
const ARMORED = preload("res://assets/content/fight/rockslide/armored-damage.png")
const RockContactHulls = preload("res://assets/content/fight/rockslide/rock-contact-hulls.gd")
const SAND = preload("res://assets/content/production/sand.png")
const XP = preload("res://assets/content/ui/infochip-symbol-xp-outlined.png")
const STAMINA = preload("res://assets/content/ui/infochip-symbol-stamina-outlined.png")
const Formatting = preload("res://scripts/core/formatting.gd")
const KO_FRAMES = [preload("res://assets/content/fight/prototype/blue-guy-ko-01.png"),preload("res://assets/content/fight/prototype/blue-guy-ko-02.png"),preload("res://assets/content/fight/prototype/blue-guy-ko-03.png"),preload("res://assets/content/fight/prototype/blue-guy-ko-04.png"),preload("res://assets/content/fight/prototype/blue-guy-ko-05.png"),preload("res://assets/content/fight/prototype/blue-guy-ko-06.png")]
const KO_CANVAS := Vector2(640,640)
const KO_GROUND := Vector2(320,540)
const KO_SIDE := 280.0
const KO_FALL_SECONDS := .5
const KO_STAND_SECONDS := .5
const INK := Color("#171615")
const DESIGN_SIZE := Vector2(900,450)
const HERO_SIDE := 200.0
const HERO_GROUND_PADDING := 10.0

var host
var card: Dictionary
var regular_layout := false
var buttons: Array[Button] = []
var price_labels: Array[Label] = []
var price_icons: Array[TextureRect] = []
var elapsed := 0.0
var refresh_seconds := 0.0
var upgrade_styles: Array[StyleBoxFlat] = []
var button_bases: Array[Panel] = []
var resource_buttons: Array[Button] = []
var reward_resource_button: Button
var resource_name_label: Label
var resource_name_seconds := 0.0

class UpgradeButton extends Button:
	var resource_rect:=Rect2()
	func _has_point(point: Vector2) -> bool:
		return Rect2(Vector2.ZERO,size).has_point(point) and not resource_rect.has_point(point)
	func contains_screen_point(point: Vector2) -> bool:
		return _has_point(get_global_transform_with_canvas().affine_inverse()*point)

func make_resource_button(node_name: String,callback: Callable) -> Button:
	var button:=Button.new()
	button.name=node_name
	host._apply_empty_button_style(button)
	button.add_to_group("production_controls")
	button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	button.gui_input.connect(func(event):
		if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE,KEY_ENTER,KEY_KP_ENTER]: button.set_meta("production_valid_tap",true))
	button.pressed.connect(func():
		if not bool(button.get_meta("production_valid_tap",false)): return
		button.set_meta("production_valid_tap",false)
		callback.call())
	return button

func show_resource_name(material_id: String,control: Control) -> void:
	resource_name_label.text=host.material_runtime.display_name(material_id)
	var text_width: float=host.app_bold_font.get_string_size(resource_name_label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,52).x+32
	resource_name_label.size=Vector2(minf(size.x-32,text_width),70)
	var center:=get_global_transform_with_canvas().affine_inverse()*control.get_global_rect().get_center()
	var popup_y: float=center.y-108
	if center.y>size.y*.6: popup_y=minf(popup_y,size.y-330)
	resource_name_label.position=Vector2(clampf(center.x-resource_name_label.size.x*.5,16,size.x-resource_name_label.size.x-16),maxf(88,popup_y))
	resource_name_seconds=1.8
	resource_name_label.show()

static func attach(owner, record: Dictionary, body: Dictionary) -> void:
	var stage = load("res://scripts/ui/rockslide_stage.gd").new()
	stage.host = owner
	stage.card = record
	stage.name = "RockslideStage"
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.z_index = 225
	record.pop.add_child(stage)
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.offset_bottom = record.bg.offset_bottom
	stage.clip_contents = true
	(body.margin as Control).hide()
	record.bg.texture=HILL
	record.bg.aspect_mode=3
	record.bg.corner_mask_mode=0
	record.bg.show()
	record.title.hide()
	if is_instance_valid(record.medal):
		record.medal.hide()
	record.progress.hide()
	record["production_stage"] = stage
	record["rockslide_stage"] = stage
	stage.setup_controls()

func label(text: String, font_size := 48) -> Label:
	var value: Label = host._label(text,font_size,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER)
	value.add_theme_font_override("font",host.app_bold_font)
	value.add_theme_color_override("font_outline_color",INK)
	value.add_theme_constant_override("outline_size",14)
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return value

func setup_controls() -> void:
	resource_name_label=label("",52)
	resource_name_label.z_index=20
	resource_name_label.hide()
	add_child(resource_name_label)
	for index in 3:
		var kind: String = ["power","speed","volley"][index]
		var control := UpgradeButton.new()
		control.name = "Slingshot"+kind.capitalize()
		control.add_to_group("production_controls")
		control.focus_mode = Control.FOCUS_ALL
		control.button_down.connect(func(): control.set_meta("rockslide_pressed",true))
		control.button_up.connect(func(): control.set_meta("rockslide_pressed",false))
		control.custom_minimum_size = Vector2(270,128)
		control.size = Vector2(270,128)
		var base:=Panel.new()
		base.name=control.name+"Depth"
		base.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var back_style:=StyleBoxFlat.new()
		back_style.bg_color=Color("#3c701f")
		back_style.border_color=INK
		back_style.set_border_width_all(5)
		back_style.set_corner_radius_all(18)
		base.add_theme_stylebox_override("panel",back_style)
		add_child(base)
		button_bases.append(base)
		for state in ["normal","hover","pressed","disabled","focus"]:
			var style := StyleBoxFlat.new()
			style.bg_color = Color("#84c742") if state!="pressed" else Color("#65a52d")
			style.border_color = INK
			style.set_border_width_all(5)
			style.set_corner_radius_all(18)
			if state=="disabled": style.bg_color = Color("#e3ddd2")
			if state=="hover": style.bg_color = Color("#a0e258")
			if state=="normal": upgrade_styles.append(style)
			control.add_theme_stylebox_override(state,style)
		var title := label(kind.capitalize())
		title.name = "UpgradeName"
		title.position = Vector2(14,4)
		title.size = Vector2(150,58)
		title.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
		control.add_child(title)
		var effect := label("")
		effect.name = "UpgradeEffect"
		effect.position = Vector2(156,4)
		effect.size = Vector2(98,58)
		effect.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		control.add_child(effect)
		var icon := TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.position = Vector2(65,67)
		icon.size = Vector2(54,54)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		control.add_child(icon)
		price_icons.append(icon)
		var price := label("10")
		price.position = Vector2(128,63)
		price.size = Vector2(120,58)
		price.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		control.add_child(price)
		price_labels.append(price)
		var resource_button:=make_resource_button("ResourceName"+kind.capitalize(),func():
			var cost: Dictionary=host._rockslide_runtime().upgrade_cost(kind)
			if not cost.is_empty(): show_resource_name(str(cost.id),resource_buttons[index]))
		control.add_child(resource_button)
		resource_buttons.append(resource_button)
		control.gui_input.connect(func(event):
			if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE,KEY_ENTER,KEY_KP_ENTER]: control.set_meta("production_valid_tap",true)
		)
		control.pressed.connect(func():
			if not bool(control.get_meta("production_valid_tap",false)): return
			control.set_meta("production_valid_tap",false)
			host._rockslide_runtime().buy_upgrade(kind)
			refresh_controls()
		)
		add_child(control)
		buttons.append(control)
	reward_resource_button=make_resource_button("SandResourceName",func(): show_resource_name(str(card.action.mat_rewards[0].id),reward_resource_button))
	add_child(reward_resource_button)
	refresh_controls()

func refresh_controls() -> void:
	if not is_instance_valid(host) or host.app_bold_font==null: return
	var runtime = host._rockslide_runtime()
	for index in buttons.size():
		var kind: String = ["power","speed","volley"][index]
		var button:=buttons[index] as UpgradeButton
		var resting_position:=Vector2(24+float(index)*(size.x-48)/3.0,size.y-158)
		button.position = resting_position+Vector2(0,10 if bool(button.get_meta("rockslide_pressed",false)) and not button.disabled else 0)
		button.size.x = (size.x-80)/3.0
		button_bases[index].position=resting_position+Vector2(0,14)
		button_bases[index].size=button.size
		var title := button.get_node("UpgradeName") as Label
		title.size.x = button.size.x-124
		var effect := button.get_node("UpgradeEffect") as Label
		effect.position.x=button.size.x-108
		effect.size.x=94
		var current_value := str(runtime.shot_damage()) if kind=="power" else (str(snappedf(1.0/runtime.shot_interval(),.1)) if kind=="speed" else str(runtime.volley_size()))
		var next_value := str(runtime.shot_damage()+1) if kind=="power" else (str(snappedf(1.0/runtime.shot_interval_at_level(int(runtime.upgrades.speed)+1),.1)) if kind=="speed" else str(runtime.volley_size()+1))
		var cost: Dictionary = runtime.upgrade_cost(kind)
		effect.text = current_value
		button.tooltip_text = ("Damage per shot" if kind=="power" else ("Shots per second" if kind=="speed" else "Projectiles per shot"))+": "+current_value+(" → "+next_value if not cost.is_empty() else "")
		price_icons[index].visible = not cost.is_empty()
		price_labels[index].text = str(int(cost.amount)) if not cost.is_empty() else "Max"
		button.disabled = cost.is_empty() or host.material_runtime.amount(str(cost.id))<float(cost.amount)
		if not cost.is_empty(): price_icons[index].texture = host.visual_texture_cache._texture_or_visual_fallback(host.material_runtime.icon_path(str(cost.id)))
		var hit_rect:=Rect2(Vector2(12,66),Vector2(button.size.x-24,62))
		button.resource_rect=hit_rect if not cost.is_empty() else Rect2()
		resource_buttons[index].position=hit_rect.position
		resource_buttons[index].size=hit_rect.size
		resource_buttons[index].visible=not cost.is_empty()
		resource_buttons[index].tooltip_text=host.material_runtime.display_name(str(cost.id)) if not cost.is_empty() else ""
		center_upgrade_contents(index)
	var sand: Dictionary=top_stats()[2]
	reward_resource_button.position=sand.position+Vector2(-8,-60)
	reward_resource_button.size=Vector2(maxf(72,float(sand.width)+16),72)
	reward_resource_button.tooltip_text=host.material_runtime.display_name(str(card.action.mat_rewards[0].id))

func center_upgrade_contents(index: int) -> void:
	if not is_instance_valid(host) or host.app_bold_font==null: return
	var button:=buttons[index]
	var title:=button.get_node("UpgradeName") as Label
	var effect:=button.get_node("UpgradeEffect") as Label
	var font: Font=host.app_bold_font
	var title_width:=font.get_string_size(title.text,HORIZONTAL_ALIGNMENT_LEFT,-1,48).x+4
	var value_width:=font.get_string_size(effect.text,HORIZONTAL_ALIGNMENT_LEFT,-1,48).x+4
	var left: float=(button.size.x-title_width-value_width-18)*.5
	title.position=Vector2(left,4)
	title.size=Vector2(title_width,58)
	effect.position=Vector2(left+title_width+18,4)
	effect.size=Vector2(value_width,58)
	var price_width:=font.get_string_size(price_labels[index].text,HORIZONTAL_ALIGNMENT_LEFT,-1,48).x+4
	var has_icon:=price_icons[index].visible
	var price_left: float=(button.size.x-price_width-(66 if has_icon else 0))*.5
	price_icons[index].position=Vector2(price_left,67)
	price_labels[index].position=Vector2(price_left+(66 if has_icon else 0),63)
	price_labels[index].size=Vector2(price_width,58)

func _process(delta: float) -> void:
	if not is_instance_valid(host) or host.app_bold_font==null: return
	if not is_visible_in_tree() or not get_global_rect().intersects(get_viewport_rect()): return
	elapsed += delta
	resource_name_seconds=maxf(0,resource_name_seconds-delta)
	resource_name_label.visible=resource_name_seconds>0
	for index in upgrade_styles.size():
		var kind: String = ["power","speed","volley"][index]
		var held: bool=bool(buttons[index].get_meta("rockslide_pressed",false)) and not buttons[index].disabled
		upgrade_styles[index].bg_color = Color("#65a52d") if held else Color("#84c742").lerp(Color("#b7ef75"),clampf(float(host._rockslide_runtime().purchase_seconds[kind])/.75,0,1))
		buttons[index].position.y=size.y-158+(10 if held else 0)
	refresh_seconds += delta
	if refresh_seconds>.25:
		refresh_seconds = 0.0
		refresh_controls()
	queue_redraw()

func text_at(text: String, point: Vector2, font_size := 48, color := Color.WHITE) -> void:
	if host.app_bold_font==null: return
	draw_string_outline(host.app_bold_font,point,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,roundi(font_size*.24),Color(INK,color.a))
	draw_string(host.app_bold_font,point,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func scene_scale() -> float:
	return size.x/DESIGN_SIZE.x

func project(point: Vector2) -> Vector2:
	var ground: float=host._rockslide_runtime().ground_y(point.x)
	return Vector2(point.x*scene_scale(),ground*size.y/DESIGN_SIZE.y+(point.y-ground)*scene_scale())

func muzzle_position() -> Vector2:
	return SlingshotAnimation.muzzle(hero_position(),HERO_SIDE*scene_scale())

func animation_frame() -> int:
	var runtime = host._rockslide_runtime()
	if runtime.release_seconds>0:
		return SlingshotAnimation.frame_index(0,1.0-runtime.release_seconds/runtime.release_duration())
	if not runtime.active() or runtime.rocks.is_empty(): return 0
	var draw_duration: float=runtime.shot_interval()-runtime.release_duration()
	return SlingshotAnimation.frame_index(1.0-clampf(runtime.shot_clock/draw_duration,0,1))

func top_stats() -> Array[Dictionary]:
	var xp: Dictionary=host._action_runtime()._effective_xp_reward_map(card.action,"fight")
	var values: Array[Dictionary]=[
		{"icon":XP,"text":str(xp.get("fight",18)),"icon_width":58.0},
		{"icon":STAMINA,"text":str(snappedf(host._action_runtime()._effective_stamina("fight",card.action),.01)),"icon_width":40.0},
		{"icon":SAND,"text":str(int(card.action.mat_rewards[0].amount)),"icon_width":54.0}]
	return HeaderStats.layout(values,host.app_bold_font,48,size.x-24,62)

func hero_position() -> Vector2:
	return project(Vector2(142,host._rockslide_runtime().ground_y(142)))+Vector2(0,HERO_GROUND_PADDING)*scene_scale()

func _draw() -> void:
	if not is_instance_valid(host) or host.app_bold_font==null or size.x<100: return
	var runtime = host._rockslide_runtime()
	var scale:=scene_scale()
	var hero_ground:=hero_position()
	if runtime.knocked_out():
		draw_knocked_out_hero(hero_ground,scale)
	else:
		SlingshotAnimation.draw_pose(self,hero_ground,HERO_SIDE*scale,animation_frame())
	if not runtime.active():
		draw_rock({"x":690.0,"radius":66.0,"lift":0.0,"rotation":-.25,"hp":4,"max_hp":4,"hit":0.0})
		text_at("Tap to start",Vector2(size.x*.35,260),48)
	if runtime.knocked_out():
		var message: String="Knocked out "+Formatting.countdown(ceili(runtime.knockout_remaining))
		var message_width: float=host.app_bold_font.get_string_size(message,HORIZONTAL_ALIGNMENT_LEFT,-1,52).x
		text_at(message,Vector2((size.x-message_width)*.5,190),52)
	for rock in runtime.rocks.values(): draw_rock(rock)
	for shot in runtime.shots:
		var start:=muzzle_position()
		var end: Vector2=rock_center(runtime.rocks[int(shot.target)]) if runtime.rocks.has(int(shot.target)) else project(shot.to)
		var t := clampf(float(shot.age)/float(shot.duration),0,1)
		var bend:=start.lerp(end,.5)+Vector2(0,(-26.0+float(shot.arc))*scale)
		var point:=start.lerp(bend,t).lerp(bend.lerp(end,t),t)
		var tangent:=(end-bend).normalized()
		draw_line(point-tangent*30*scale,point,Color(1,.91,.58,.65),8*scale,true)
		draw_circle(point,8*scale,INK)
		draw_circle(point,5*scale,Color("#f8dc79"))
	for effect in runtime.effects: draw_effect(effect)
	# Header and corner stats stay above the moving artwork.
	text_at(str(card.action.name),Vector2(24,72),60)
	for item in top_stats():
		var point: Vector2=item.position
		var icon_size: Vector2=item.icon_size
		draw_texture_rect(item.icon,Rect2(point+Vector2(0,-48),icon_size),false)
		text_at(item.text,point+Vector2(icon_size.x+HeaderStats.ICON_GAP,0),48)
	text_at("Wave %d" % runtime.wave(),Vector2(size.x-245,size.y-180),52,Color.WHITE.lerp(Color("#ffe167"),runtime.wave_seconds))

func draw_knocked_out_hero(ground: Vector2,scale: float) -> void:
	var runtime=host._rockslide_runtime()
	var age: float=runtime.knockout_seconds()-runtime.knockout_remaining
	var progress: float=clampf(age/KO_FALL_SECONDS,0,1)
	if runtime.knockout_remaining<KO_STAND_SECONDS:
		progress=clampf(runtime.knockout_remaining/KO_STAND_SECONDS,0,1)
	var frame:=mini(KO_FRAMES.size()-1,int(progress*KO_FRAMES.size()))
	# Existing fall poses share one authored canvas, scale and sole anchor.
	# Never normalize their size from per-frame transparent bounds.
	var pixels_per_unit:=KO_SIDE/KO_CANVAS.y*scale
	draw_texture_rect(KO_FRAMES[frame],Rect2(ground-KO_GROUND*pixels_per_unit,KO_CANVAS*pixels_per_unit),false)

func rock_visual_kind(rock: Dictionary) -> String:
	var kind: String=str(rock.get("kind","boulder"))
	if kind=="fragment": return "armored" if str(rock.get("parent_kind","boulder"))=="armored" else "boulder"
	return kind if kind in ["runner","armored"] else "boulder"

func rock_visual_state(rock: Dictionary) -> int:
	if bool(rock.get("small",false)) and rock_visual_kind(rock)=="boulder": return 3+int(rock.get("id",0))%2
	return 0 if int(rock.hp)==int(rock.max_hp) else (1 if float(rock.hp)/float(rock.max_hp)>.34 else 2)

func rock_center(rock: Dictionary) -> Vector2:
	var runtime=host._rockslide_runtime()
	var x: float=rock.x
	var scale:=scene_scale()
	var ground: Vector2=project(Vector2(x,runtime.ground_y(x)))
	var slope: float=(runtime.ground_y(x+.5)-runtime.ground_y(x-.5))*size.y/DESIGN_SIZE.y/scale
	var points: Array=RockContactHulls.HULLS[rock_visual_kind(rock)][rock_visual_state(rock)]
	var support: float=-INF
	var pixels_per_unit: float=float(rock.radius)*2.36/512.0*scale
	for point in points:
		var rotated: Vector2=point.rotated(float(rock.rotation))*pixels_per_unit
		support=maxf(support,rotated.y-slope*rotated.x)
	# A support point on the rotated authored silhouette touches the sloped
	# ground. Hull measurements affect position only, never sprite scale.
	return ground+Vector2(0,-support+1.5*scale+float(rock.lift)*scale)

func draw_rock(rock: Dictionary) -> void:
	var runtime = host._rockslide_runtime()
	var center:=rock_center(rock)
	var radius := float(rock.radius)
	var scale:=scene_scale()
	var ground:=project(Vector2(float(rock.x),runtime.ground_y(float(rock.x))))
	draw_set_transform(ground,-.258,Vector2(scale,scale*.22))
	draw_circle(Vector2.ZERO,radius*.8,Color(0,0,0,.17))
	draw_set_transform(center,float(rock.rotation),Vector2.ONE*scale)
	var shade := Color(1.3,1.3,1.3) if float(rock.hit)>0 else Color.WHITE
	var kind:=rock_visual_kind(rock)
	var texture: Texture2D=RUNNER if kind=="runner" else (ARMORED if kind=="armored" else ROCK)
	var state:=rock_visual_state(rock)
	var region:=Rect2((state%3)*512,(state/3)*512,512,512)
	draw_texture_rect_region(texture,Rect2(Vector2.ONE*(-radius*1.18),Vector2.ONE*radius*2.36),region,shade)
	draw_set_transform(Vector2.ZERO)

func draw_effect(effect: Dictionary) -> void:
	var t := float(effect.age)/float(effect.duration)
	var world_point: Vector2 = effect.position
	var point:=project(world_point)
	var scale:=scene_scale()
	var alpha := 1.0-t
	if str(effect.kind)=="land":
		for direction in [-1,1]:
			draw_circle(point+Vector2(direction*(10+t*28),-4-t*9)*scale,5*(1-t)*scale,Color(.95,.81,.56,alpha*.55))
	if str(effect.kind) in ["break","hit"]:
		for index in (7 if str(effect.kind)=="break" else 3):
			var direction := Vector2.from_angle(float(index)*2.4)
			var chip:=project(world_point+direction*(20+t*68)+Vector2(0,90*t*t))
			var extent := (7.0 if str(effect.kind)=="break" else 3.5)*scale
			draw_texture_rect_region(ROCK,Rect2(chip-Vector2.ONE*extent*2,Vector2.ONE*extent*4),Rect2(1024,512,512,512),Color(1,1,1,alpha))
		if str(effect.kind)=="break":
			draw_arc(point,(18+t*50)*scale,0,TAU,32,Color(1,.92,.68,alpha*.6),5*(1-t)*scale,true)
	if str(effect.kind)=="reward":
		point+=Vector2(0,-46*(1-pow(1-t,3)))
		draw_texture_rect(SAND,Rect2(point,Vector2(54,54)),false,Color(1,1,1,alpha))
		text_at("+1",point+Vector2(60,42),48,Color(1,1,1,alpha))
		text_at("+%d XP" % int(effect.amount),point+Vector2(-25,-15),48,Color(1,.88,.24,alpha))
	if str(effect.kind)=="escape":
		draw_arc(point,30+t*50,0,TAU,32,Color(1,.2,.1,alpha),6,true)
