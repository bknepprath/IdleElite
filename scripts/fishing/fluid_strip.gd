extends Control

const STRIP_EXPANDED_HEIGHT := 88.0
const STRIP_IDLE_HEIGHT := 0.0
const STRIP_VISIBLE_HEIGHT := 0.5
const EXPAND_SPEED := 14.0
const STRIP_EDGE_INSET := 6.0
const STRIP_BOTTOM_RADIUS := 66.0
const STRIP_BOTTOM_INSET := 0.0
const STRIP_TOP_LIP_HEIGHT := 7.0
const STRIP_INK := Color("#171615")

const FLUIDS := {
	"water": {"fluid": Color("#3db8d9"), "deep": Color("#2a8fb8"), "scroll_speed": 1.0},
	"sewer": {"fluid": Color("#6dc96e"), "deep": Color("#3f8f45"), "scroll_speed": 1.0},
	"lava": {"fluid": Color("#ff9a48"), "deep": Color("#d84a18"), "scroll_speed": 1.0},
	"space": {"fluid": Color("#4331a8"), "deep": Color("#17113f"), "scroll_speed": 0.65},
	"deep_water": {"fluid": Color("#123766"), "deep": Color("#071a36"), "scroll_speed": 0.85},
	"storm": {"fluid": Color("#17202c"), "deep": Color("#05080d"), "scroll_speed": 1.15},
	"ice": {"fluid": Color("#c9f6ff"), "deep": Color("#7fd5ee"), "scroll_speed": 0.0},
}

var _top_lip: ColorRect
var _underlay: ColorRect
var _fill: ColorRect
var _material: ShaderMaterial
var _underlay_material: ShaderMaterial
var _running := false
var _target_height := 0.0
var _current_height := 0.0
var _foam_phase := 0.0
var _fluid_kind := "water"
var _wave_speed := 1.0
var _last_mask_size := Vector2.ZERO
var _last_mask_height := -1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_current_height = STRIP_IDLE_HEIGHT
	_target_height = STRIP_IDLE_HEIGHT
	_apply_layout_height(_current_height)
	_setup_fill()
	_sync_shader_uniforms()
	_sync_strip_visibility()
	set_process(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_sync_mask_uniforms()
		_layout_top_lip()


func _setup_fill() -> void:
	_top_lip = ColorRect.new()
	_top_lip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_lip.color = STRIP_INK
	add_child(_top_lip)

	_underlay = ColorRect.new()
	_underlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_underlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_underlay_material = ShaderMaterial.new()
	_underlay_material.shader = preload("res://scripts/fishing/fluid_strip_underlay.gdshader")
	_underlay.material = _underlay_material
	_underlay.color = Color(1, 1, 1, 1)
	add_child(_underlay)

	_fill = ColorRect.new()
	_fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_material = ShaderMaterial.new()
	_material.shader = preload("res://scripts/fishing/fluid_strip.gdshader")
	_fill.material = _material
	_fill.color = Color.WHITE
	add_child(_fill)
	_apply_fluid_colors()
	_sync_mask_uniforms()
	_layout_top_lip()


func set_fluid_kind(kind: String) -> void:
	_fluid_kind = kind if FLUIDS.has(kind) else "water"
	_wave_speed = float(_fluid_table()["scroll_speed"])
	_apply_fluid_colors()
	_sync_shader_uniforms()


func set_running(running: bool) -> void:
	_running = running
	_target_height = STRIP_EXPANDED_HEIGHT if running else STRIP_IDLE_HEIGHT
	if _fluid_kind == "ice":
		_current_height = _target_height
		_apply_layout_height(_current_height)
		_sync_mask_uniforms()
	if running:
		set_process(true)
	_sync_strip_visibility()


func _apply_layout_height(height: float) -> void:
	var h := maxf(0.0, height)
	offset_left = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	offset_top = -h


func _layout_top_lip() -> void:
	if _top_lip == null or not is_instance_valid(_top_lip):
		return
	var lip_h := minf(STRIP_TOP_LIP_HEIGHT, maxf(0.0, size.y))
	_top_lip.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_top_lip.offset_top = 0.0
	_top_lip.offset_bottom = lip_h
	_top_lip.offset_left = STRIP_EDGE_INSET
	_top_lip.offset_right = -STRIP_EDGE_INSET
	_top_lip.visible = lip_h > STRIP_VISIBLE_HEIGHT


func _sync_mask_uniforms() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	if _last_mask_size == size and absf(_last_mask_height - _current_height) <= 0.25:
		return
	_last_mask_size = size
	_last_mask_height = _current_height
	for shader_material in [_material, _underlay_material]:
		if shader_material == null:
			continue
		shader_material.set_shader_parameter("strip_size", size)
		shader_material.set_shader_parameter("corner_radius", STRIP_BOTTOM_RADIUS)
		shader_material.set_shader_parameter("edge_inset", STRIP_EDGE_INSET)
		shader_material.set_shader_parameter("bottom_inset", STRIP_BOTTOM_INSET)


func is_animating_visible() -> bool:
	return _running or _current_height > STRIP_VISIBLE_HEIGHT or _target_height > STRIP_VISIBLE_HEIGHT


func _fluid_table() -> Dictionary:
	return FLUIDS.get(_fluid_kind, FLUIDS["water"]) as Dictionary


func _apply_fluid_colors() -> void:
	var table := _fluid_table()
	var surface_color: Color = table["fluid"]
	var deep_color: Color = table["deep"]
	if _underlay != null:
		_underlay.color = deep_color
	if _underlay_material != null:
		_underlay_material.set_shader_parameter("fill_color", deep_color)
	if _material == null:
		if _fill != null:
			_fill.color = surface_color
		return
	_material.set_shader_parameter("fluid_color", surface_color)
	_material.set_shader_parameter("fluid_deep", deep_color)
	_sync_mask_uniforms()


func _sync_shader_uniforms() -> void:
	if _material == null:
		return
	_material.set_shader_parameter("foam_scroll", _foam_phase)


func _process(delta: float) -> void:
	if not _running and absf(_current_height - _target_height) <= 0.01:
		set_process(false)
		return
	if _material != null and _running:
		_foam_phase += delta * _wave_speed
		_material.set_shader_parameter("foam_scroll", _foam_phase)
	_current_height = lerpf(_current_height, _target_height, 1.0 - exp(-EXPAND_SPEED * maxf(delta, 0.001)))
	_apply_layout_height(_current_height)
	_sync_mask_uniforms()
	_sync_strip_visibility()
	if not _running and absf(_current_height - _target_height) <= 0.01:
		_current_height = _target_height
		_apply_layout_height(_current_height)
		set_process(false)


func _sync_strip_visibility() -> void:
	var show_fill := _current_height > STRIP_VISIBLE_HEIGHT
	visible = show_fill or _running
	if _top_lip != null:
		_top_lip.visible = show_fill and size.y > STRIP_TOP_LIP_HEIGHT
	if _underlay != null:
		_underlay.visible = show_fill
	if _fill != null:
		_fill.visible = show_fill
