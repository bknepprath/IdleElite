extends Control

const INK := Color("#171615")
var host
var button: Button
var base: Panel
var title_label: Label
var value_label: Label
var price_label: Label
var price_icon: TextureRect
var normal_style: StyleBoxFlat
var held := false
var face_color := Color.WHITE

func setup(stage,title: String,callback: Callable) -> void:
	host=stage.host
	face_color=preload("res://scripts/ui/theme_styles.gd").skill_theme_color("woodcutting",host.COLOR_BLUE)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	base=Panel.new()
	base.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var back:=StyleBoxFlat.new()
	back.bg_color=face_color.darkened(.42)
	back.border_color=INK
	back.set_border_width_all(6)
	back.set_corner_radius_all(18)
	base.add_theme_stylebox_override("panel",back)
	add_child(base)
	button=stage.make_button(title,callback)
	button.button_down.connect(func(): held=true)
	button.button_up.connect(func(): held=false)
	for state in ["normal","hover","pressed","disabled","focus"]:
		var style:=StyleBoxFlat.new()
		style.bg_color=face_color.lerp(Color("#bbb9af"),.6) if state=="disabled" else face_color
		if state=="hover": style.bg_color=face_color.lightened(.12)
		if state=="pressed": style.bg_color=face_color.darkened(.12)
		style.border_color=INK
		style.set_border_width_all(6)
		style.set_corner_radius_all(18)
		button.add_theme_stylebox_override(state,style)
		if state=="normal": normal_style=style
	add_child(button)
	title_label=make_label(title,HORIZONTAL_ALIGNMENT_LEFT)
	value_label=make_label("",HORIZONTAL_ALIGNMENT_RIGHT)
	price_label=make_label("",HORIZONTAL_ALIGNMENT_LEFT)
	price_icon=TextureRect.new()
	price_icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	price_icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	price_icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
	button.add_child(price_icon)
	layout_controls()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED: layout_controls()

func make_label(value: String,alignment: HorizontalAlignment) -> Label:
	var node: Label=host._label(value,48,Color.WHITE,alignment)
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	node.add_theme_font_override("font",host.app_bold_font)
	node.add_theme_color_override("font_outline_color",INK)
	node.add_theme_constant_override("outline_size",14)
	button.add_child(node)
	return node

func refresh(value: String,cost: Dictionary,tooltip: String) -> void:
	value_label.text=value
	price_label.text=str(cost.get("amount","Max"))
	price_icon.visible=not cost.is_empty()
	price_icon.texture=host.visual_texture_cache._texture_or_visual_fallback(host.material_runtime.icon_path(str(cost.id))) if not cost.is_empty() else null
	button.disabled=cost.is_empty() or host.material_runtime.amount(str(cost.id))<float(cost.amount)
	button.tooltip_text=tooltip
	layout_controls()

func _process(_delta: float) -> void:
	layout_controls()

func layout_controls() -> void:
	if not is_instance_valid(button) or not is_instance_valid(price_icon): return
	base.position=Vector2(0,14)
	base.size=Vector2(size.x,128)
	button.position=Vector2(0,10 if held and not button.disabled else 0)
	button.size=Vector2(size.x,128)
	normal_style.bg_color=face_color.darkened(.12) if held and not button.disabled else face_color
	var font: Font=host.app_bold_font
	if font==null: return
	var title_width:=font.get_string_size(title_label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,48).x+4
	var value_width:=font.get_string_size(value_label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,48).x+4
	var first_left: float=(size.x-title_width-value_width-12)*.5
	title_label.position=Vector2(first_left,4)
	title_label.size=Vector2(title_width,58)
	value_label.position=Vector2(first_left+title_width+12,4)
	value_label.size=Vector2(value_width,58)
	var price_width:=font.get_string_size(price_label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,48).x+4
	var second_left: float=(size.x-price_width-(66 if price_icon.visible else 0))*.5
	price_icon.position=Vector2(second_left,67)
	price_icon.size=Vector2(54,54)
	price_label.position=Vector2(second_left+(66 if price_icon.visible else 0),63)
	price_label.size=Vector2(price_width,58)
