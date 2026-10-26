extends Control

const SlingshotAnimation = preload("res://scripts/ui/slingshot_animation.gd")
const HeaderStats = preload("res://scripts/ui/activity_header_stats.gd")
const BACKGROUND = preload("res://assets/content/fight/slingshot-range/range-background.png")
const STONE = preload("res://assets/content/fight/slingshot-range/pebble.png")
const STAKE = preload("res://assets/content/fight/slingshot-range/distance-stake.png")
const FLAG = preload("res://assets/content/fight/slingshot-range/record-flag.png")
const DUST = preload("res://assets/content/fight/slingshot-range/landing-dust.png")
const XP = preload("res://assets/content/ui/infochip-symbol-xp-outlined.png")
const STAMINA = preload("res://assets/content/ui/infochip-symbol-stamina-outlined.png")
const INK := Color("#171615")
const HERO_SIDE := 210.0
const HERO_X := 140.0
const DUST_CELL := Vector2(384,288)

var host
var card: Dictionary
var regular_layout := false
var camera_offset := 0.0
var camera_initialized := false
var shooter_button: Button
var flag_target := -1.0
var flag_from := 0.0
var flag_age := 1.0
const FLAG_POP_SECONDS := .65
var title_font: FontVariation
var range_background: Texture2D=BACKGROUND

static func attach(owner,record: Dictionary,body: Dictionary) -> void:
	var stage = load("res://scripts/ui/slingshot_range_stage.gd").new()
	stage.host=owner
	stage.card=record
	stage.mouse_filter=Control.MOUSE_FILTER_IGNORE
	stage.z_index=225
	record.pop.add_child(stage)
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.offset_bottom=record.bg.offset_bottom
	stage.clip_contents=true
	(body.margin as Control).hide()
	record.bg.aspect_mode=2
	record.bg.sample_zoom=1.35
	record.bg.corner_mask_mode=0
	record.bg.show()
	record.title.hide()
	if is_instance_valid(record.get("medal")): record.medal.hide()
	record.progress.hide()
	record["production_stage"]=stage
	record["slingshot_range_stage"]=stage
	stage.setup_controls()

func setup_controls() -> void:
	card.bg.texture=range_background
	title_font=FontVariation.new()
	title_font.base_font=host.app_bold_font
	title_font.variation_opentype={"wdth":75,"wght":700}
	title_font.variation_embolden=.6
	shooter_button=Button.new()
	shooter_button.name="SlingshotRelease"
	host._apply_empty_button_style(shooter_button)
	shooter_button.add_to_group("production_controls")
	shooter_button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	shooter_button.gui_input.connect(func(event):
		if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE,KEY_ENTER,KEY_KP_ENTER]: shooter_button.set_meta("production_valid_tap",true))
	shooter_button.pressed.connect(func():
		if not bool(shooter_button.get_meta("production_valid_tap",false)): return
		shooter_button.set_meta("production_valid_tap",false)
		var runtime=host._slingshot_range_runtime()
		if not runtime.active(): host._action_runtime()._start_action_from_card_tap("fight",str(card.action.id)))
	add_child(shooter_button)
	if bool(card.get("preview",false)):
		shooter_button.disabled=true
		shooter_button.remove_from_group("production_controls")
	layout_controls()

func floor_y() -> float:
	return size.y*.755

func pixels_per_meter() -> float:
	return float(card.action.slingshot_range.get("pixels_per_meter",6))

func hero_ground() -> Vector2:
	return Vector2(HERO_X,floor_y())

func launch_point() -> Vector2:
	return SlingshotAnimation.muzzle(hero_ground(),HERO_SIDE)

func landing_point() -> Vector2:
	return Vector2(launch_point().x+host._slingshot_range_runtime().distance*pixels_per_meter(),floor_y())

func layout_controls() -> void:
	if not is_instance_valid(shooter_button): return
	shooter_button.position=Vector2(HERO_X-camera_offset-90,floor_y()-190)
	shooter_button.size=Vector2(220,212)
	shooter_button.visible=shooter_button.position.x+shooter_button.size.x>24

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	var runtime=host._slingshot_range_runtime()
	update_flag(delta,runtime.best_distance)
	var desired:=0.0
	if runtime.phase=="flying": desired=maxf(0,projectile_point().x-size.x*.68)
	elif runtime.reward_seconds>.45: desired=maxf(0,landing_point().x-size.x*.68)
	if not camera_initialized:
		camera_offset=desired
		camera_initialized=true
	camera_offset=lerpf(camera_offset,desired,1-exp(-delta*(7 if runtime.phase=="flying" else 4.5)))
	# The terrain scrolls more slowly than the foreground pegs and shooter.
	var background_offset:=Vector2(-minf(camera_offset*.2,size.x*.16),0)
	if not card.bg.sample_offset_px.is_equal_approx(background_offset):
		card.bg.sample_offset_px=background_offset
		card.bg.queue_redraw()
	layout_controls()
	queue_redraw()

func text(value: String,point: Vector2,color:=Color.WHITE,font_size:=52,font: Font=null) -> void:
	if font==null: font=host.app_bold_font
	draw_string_outline(font,point,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,14,Color(INK,color.a))
	draw_string(font,point,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func animation_frame() -> int:
	var runtime=host._slingshot_range_runtime()
	if runtime.release_seconds>0:
		return SlingshotAnimation.frame_index(0,1.0-runtime.release_seconds/runtime.release_duration())
	if runtime.phase=="flying": return 7
	return SlingshotAnimation.frame_index(runtime.draw_progress()) if runtime.active() else 0

func top_stats() -> Array[Dictionary]:
	var stamina: float=host._action_runtime()._effective_stamina("fight",card.action)
	var label:=str(int(stamina)) if is_equal_approx(stamina,roundf(stamina)) else str(snappedf(stamina,.01))
	var values: Array[Dictionary]=[{"icon":STAMINA,"text":label}]
	return HeaderStats.layout(values,host.app_bold_font,52,size.x-24,76)

func update_flag(delta: float,best: float) -> void:
	if flag_target<0:
		flag_target=best
		flag_from=best
		flag_age=FLAG_POP_SECONDS
	elif best>flag_target:
		flag_from=flag_meters()
		flag_target=best
		flag_age=0
	flag_age=minf(FLAG_POP_SECONDS,flag_age+delta)

func flag_meters() -> float:
	var t:=clampf(flag_age/.42,0,1)
	return lerpf(flag_from,flag_target,1-pow(1-t,3))

func flag_scale() -> float:
	var t:=clampf(flag_age/FLAG_POP_SECONDS,0,1)
	if t<.57:
		return lerpf(0,1.18,1-pow(1-t/.57,3))
	return lerpf(1.18,1,smoothstep(.57,1,t))

func projectile_point(progress:=-1.0) -> Vector2:
	var runtime=host._slingshot_range_runtime()
	var t: float=clampf(runtime.age/runtime.flight_seconds,0,1) if progress<0 else progress
	var height:=minf(174,72+runtime.distance*.62)
	return launch_point().lerp(landing_point(),t)-Vector2(0,4*height*t*(1-t))

func draw_marker(meters: float,record:=false) -> void:
	var x:=launch_point().x+meters*pixels_per_meter()-camera_offset
	if x<55 or x>size.x-55: return
	var scale:=flag_scale() if record else 1.0
	var draw_size:=Vector2(92,108)*scale
	# Keep the pole base planted while the new record rises and settles.
	draw_texture_rect(FLAG if record else STAKE,Rect2(Vector2(x-draw_size.x*.5,floor_y()+6-draw_size.y),draw_size),false)
	var label:="%s m"%str(snappedf(host._slingshot_range_runtime().best_distance,.1)) if record else "%d m"%roundi(meters)
	var width: float=host.app_bold_font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,48).x
	text(label,Vector2(clampf(x-width*.5,16,size.x-width-16),floor_y()+64),Color("#ffe25b") if record else Color.WHITE,48)

func draw_stone(point: Vector2,rotation: float,alpha:=1.0) -> void:
	draw_set_transform(point,rotation)
	draw_texture_rect(STONE,Rect2(-36,-42,72,84),false,Color(1,1,1,alpha))
	draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	if not is_instance_valid(host) or host.app_bold_font==null: return
	var runtime=host._slingshot_range_runtime()
	var best: float=runtime.best_distance
	if best<=0 or absf(best-25)>32: draw_marker(25)
	var first:=maxi(1,floori(camera_offset/pixels_per_meter()/50))
	for step in range(first,first+6):
		if best<=0 or absf(best-step*50)>32: draw_marker(step*50)
	if best>0: draw_marker(flag_meters(),true)
	var ground:=hero_ground()-Vector2(camera_offset,0)
	draw_set_transform(ground,0,Vector2(1,.22))
	draw_circle(Vector2.ZERO,32,Color(0,0,0,.18))
	draw_set_transform(Vector2.ZERO)
	SlingshotAnimation.draw_pose(self,ground,HERO_SIDE,animation_frame())
	if runtime.phase=="flying":
		var t: float=clampf(runtime.age/runtime.flight_seconds,0,1)
		for i in range(3,0,-1):
			if t>.025*i: draw_stone(projectile_point(t-.025*i)-Vector2(camera_offset,0),t*12,.12*(4-i))
		var point:=projectile_point()-Vector2(camera_offset,0)
		draw_set_transform(Vector2(point.x,floor_y()),0,Vector2(1,.22))
		draw_circle(Vector2.ZERO,14,Color(0,0,0,.15))
		draw_set_transform(Vector2.ZERO)
		draw_stone(point,t*12)
	elif runtime.reward_seconds>0:
		var elapsed: float=1.2-runtime.reward_seconds
		var t:=clampf(elapsed/.7,0,1)
		var finish:=landing_point()-Vector2(camera_offset,0)
		var bounce:=absf(sin(t*TAU))*20*(1-t)
		draw_stone(finish+Vector2(t*14,-bounce),t*4,1-clampf((elapsed-.65)/.55,0,1))
		if t<1:
			var frame:=mini(2,int(t*3))
			draw_texture_rect_region(DUST,Rect2(finish+Vector2(-90,-85),Vector2(180,135)),Rect2(Vector2(frame*DUST_CELL.x,0),DUST_CELL),Color(1,1,1,1-t))
		var reward:=Vector2(clampf(finish.x-60,280,size.x-210),floor_y()-120-elapsed*24)
		var alpha:=minf(1,runtime.reward_seconds*2)
		draw_texture_rect(HeaderStats.compact_texture(XP),Rect2(reward,Vector2(71,48)),false,Color(1,1,1,alpha))
		text("+%d"%runtime.earned_xp,reward+Vector2(75,45),Color(1,.87,.2,alpha))
	text(str(card.action.name),Vector2(24,76),Color.WHITE,60,title_font)
	for item in top_stats():
		var point: Vector2=item.position
		draw_texture_rect(item.icon,Rect2(point+Vector2(0,-52),item.icon_size),false)
		text(item.text,point+Vector2(float(item.icon_width)+HeaderStats.ICON_GAP,0))

	if runtime.release_feedback_seconds>0:
		var elapsed: float=.85-runtime.release_feedback_seconds
		var point:=ground+Vector2(60,-100-elapsed*28)
		var alpha:=minf(1,runtime.release_feedback_seconds*3)
		var icon:=HeaderStats.compact_texture(STAMINA)
		draw_texture_rect(icon,Rect2(point,Vector2(34,48)),false,Color(1,1,1,alpha))
		var cost: float=runtime.last_stamina_cost
		var label:=str(int(cost)) if is_equal_approx(cost,roundf(cost)) else str(snappedf(cost,.01))
		text("-"+label,point+Vector2(38,45),Color(1,1,1,alpha),48)
