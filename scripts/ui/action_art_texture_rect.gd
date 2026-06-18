class_name ActionArtTextureRect
extends TextureRect


static var shared_mask_shader: Shader

var use_mask_material := false
var radius := 56.0
var mask_shader_params_initialized := false
var mask_shader_params_size := Vector2(-1.0, -1.0)
var mask_shader_params_radius := -1.0

func _init() -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func _ready() -> void:
	if use_mask_material:
		_ensure_mask_material()

func _notification(what: int) -> void:
	if use_mask_material and what == NOTIFICATION_RESIZED:
		_update_mask_params()

func set_mask_material_enabled(enabled: bool) -> void:
	if use_mask_material == enabled:
		return
	use_mask_material = enabled
	mask_shader_params_initialized = false
	if not use_mask_material:
		material = null
		return
	_ensure_mask_material()

func _ensure_mask_material() -> void:
	if material != null:
		return
	if shared_mask_shader == null:
		shared_mask_shader = Shader.new()
		shared_mask_shader.code = """
shader_type canvas_item;

uniform vec2 control_size = vec2(1.0, 1.0);
uniform float radius_px = 56.0;

void fragment() {
	vec2 p = UV * control_size;
	vec2 half_size = control_size * 0.5;
	float r = min(radius_px, min(half_size.x, half_size.y));
	vec2 q = abs(p - half_size) - (half_size - vec2(r));
	float distance = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
	float alpha = 1.0 - smoothstep(0.0, 1.0, distance);
	vec4 color = texture(TEXTURE, UV) * COLOR;
	color.a *= alpha;
	COLOR = color;
}
"""
	var shader_material := ShaderMaterial.new()
	shader_material.shader = shared_mask_shader
	material = shader_material
	_update_mask_params()

func _update_mask_params() -> void:
	var shader_material := material as ShaderMaterial
	if shader_material == null:
		return
	if (
		mask_shader_params_initialized
		and mask_shader_params_size.is_equal_approx(size)
		and absf(mask_shader_params_radius - radius) <= 0.001
	):
		return
	shader_material.set_shader_parameter("control_size", size)
	shader_material.set_shader_parameter("radius_px", radius)
	mask_shader_params_initialized = true
	mask_shader_params_size = size
	mask_shader_params_radius = radius
