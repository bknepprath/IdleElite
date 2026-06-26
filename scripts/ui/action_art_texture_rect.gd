class_name ActionArtTextureRect
extends TextureRect


static var shared_mask_shader: Shader

var use_mask_material := false
var radius := 56.0
var mask_shader_params_initialized := false
var mask_shader_params_size := Vector2(-1.0, -1.0)
var mask_shader_params_radius := -1.0
var paint_effect_enabled := false
var paint_effect_progress := 0.0
var paint_effect_color := Color.WHITE
var paint_effect_from_color := Color.WHITE
var paint_effect_color_secondary := Color.WHITE
var paint_effect_color_shadow := Color.WHITE
var paint_effect_color_accent := Color.WHITE
var paint_effect_detail_mode := 0

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

func set_paint_recolor_effect(enabled: bool) -> void:
	if paint_effect_enabled == enabled:
		return
	paint_effect_enabled = enabled
	if paint_effect_enabled:
		use_mask_material = true
		_ensure_mask_material()
	_update_paint_effect_params()

func set_paint_recolor_state(progress: float, color: Color) -> void:
	paint_effect_progress = clampf(progress, 0.0, 1.0)
	paint_effect_color = color
	_update_paint_effect_params()

func set_paint_recolor_transition_state(progress: float, from_color: Color, to_color: Color) -> void:
	paint_effect_progress = clampf(progress, 0.0, 1.0)
	paint_effect_from_color = from_color
	paint_effect_color = to_color
	_update_paint_effect_params()

func set_paint_recolor_palette(colors: Array[Color]) -> void:
	if not colors.is_empty():
		paint_effect_color = colors[0]
	if colors.size() >= 2:
		paint_effect_color_secondary = colors[1]
	else:
		paint_effect_color_secondary = paint_effect_color
	if colors.size() >= 3:
		paint_effect_color_shadow = colors[2]
	else:
		paint_effect_color_shadow = paint_effect_color_secondary
	if colors.size() >= 4:
		paint_effect_color_accent = colors[3]
	else:
		paint_effect_color_accent = paint_effect_color_shadow
	_update_paint_effect_params()

func set_paint_recolor_detail_mode(detail_mode: int) -> void:
	paint_effect_detail_mode = detail_mode
	_update_paint_effect_params()

func _ensure_mask_material() -> void:
	if material != null:
		return
	if shared_mask_shader == null:
		shared_mask_shader = Shader.new()
		shared_mask_shader.code = """
shader_type canvas_item;

uniform vec2 control_size = vec2(1.0, 1.0);
uniform float radius_px = 56.0;
uniform bool paint_recolor_enabled = false;
uniform float paint_progress = 0.0;
uniform vec4 paint_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 paint_from_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 paint_color_secondary = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 paint_color_shadow = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 paint_color_accent = vec4(1.0, 1.0, 1.0, 1.0);
uniform int paint_detail_mode = 0;

float camo_noise(vec2 p) {
	return fract(sin(dot(p, vec2(41.23, 19.87))) * 43758.5453);
}

void fragment() {
	vec2 p = UV * control_size;
	vec2 half_size = control_size * 0.5;
	float r = min(radius_px, min(half_size.x, half_size.y));
	vec2 q = abs(p - half_size) - (half_size - vec2(r));
	float distance = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
	float alpha = 1.0 - smoothstep(0.0, 1.0, distance);
	vec4 color = texture(TEXTURE, UV) * COLOR;
	if (paint_recolor_enabled) {
		float blue_dominance = color.b - max(color.r, color.g);
		float saturated_blue = smoothstep(0.015, 0.18, blue_dominance) * smoothstep(0.20, 0.48, color.b);
		float stroke_axis = UV.y * 0.86 + UV.x * 0.30;
		float bristle = sin(UV.x * 42.0 + UV.y * 11.0) * 0.030 + sin(UV.x * 91.0 - UV.y * 25.0) * 0.014;
		float stroke_edge = paint_progress * 1.30 - 0.10 + bristle;
		float stroke = smoothstep(stroke_axis - 0.085, stroke_axis + 0.055, stroke_edge);
		float dry_gap = smoothstep(0.66, 0.98, sin(UV.x * 64.0 + UV.y * 37.0 + paint_progress * 5.0) * 0.5 + 0.5);
		float mask = saturated_blue * clamp(stroke - dry_gap * 0.12 * (1.0 - stroke), 0.0, 1.0);
		float floor_band = smoothstep(0.48, 0.78, UV.y);
		float side_band = smoothstep(0.60, 0.86, UV.x) * smoothstep(0.30, 0.62, UV.y);
		float noise_a = camo_noise(floor(UV * vec2(10.0, 14.0)));
		float noise_b = camo_noise(floor((UV + vec2(0.13, 0.31)) * vec2(16.0, 11.0)));
		vec3 target = mix(paint_color.rgb, paint_color_secondary.rgb, floor_band);
		target = mix(target, paint_color_shadow.rgb, side_band * 0.55);
		target = mix(target, paint_color_accent.rgb, smoothstep(0.55, 0.88, noise_a) * 0.24);
		target = mix(target, paint_color_secondary.rgb, smoothstep(0.62, 0.94, noise_b) * floor_band * 0.28);
		float detail = 0.0;
		if (paint_detail_mode < 0) {
			target = paint_color.rgb;
		} else if (paint_detail_mode == 0) {
			detail = smoothstep(0.020, 0.000, abs(fract(UV.y * 7.0 + UV.x * 1.4) - 0.5));
		} else if (paint_detail_mode == 1) {
			detail = smoothstep(0.62, 0.90, noise_a);
		} else if (paint_detail_mode == 2) {
			detail = max(
				smoothstep(0.018, 0.000, abs(fract(UV.y * 8.0) - 0.5)),
				smoothstep(0.018, 0.000, abs(fract(UV.x * 5.0 + floor(UV.y * 8.0) * 0.5) - 0.5))
			);
		} else if (paint_detail_mode == 3) {
			detail = smoothstep(0.97, 0.995, noise_a);
		} else if (paint_detail_mode == 4) {
			detail = smoothstep(0.018, 0.000, abs(fract(UV.y * 6.0 + UV.x * 0.7) - 0.5));
		} else {
			detail = max(
				smoothstep(0.018, 0.000, abs(fract(UV.x * 6.0) - 0.5)),
				smoothstep(0.018, 0.000, abs(fract(UV.y * 6.0) - 0.5))
			);
		}
		target = mix(target, paint_color_accent.rgb, detail * smoothstep(0.52, 0.86, paint_progress) * 0.46);
		vec3 base = mix(color.rgb, paint_from_color.rgb, saturated_blue * 0.985);
		color.rgb = mix(base, target, mask * 0.985);
	}
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
	_update_paint_effect_params()

func _update_paint_effect_params() -> void:
	var shader_material := material as ShaderMaterial
	if shader_material == null:
		return
	shader_material.set_shader_parameter("paint_recolor_enabled", paint_effect_enabled)
	shader_material.set_shader_parameter("paint_progress", paint_effect_progress)
	shader_material.set_shader_parameter("paint_color", paint_effect_color)
	shader_material.set_shader_parameter("paint_from_color", paint_effect_from_color)
	shader_material.set_shader_parameter("paint_color_secondary", paint_effect_color_secondary)
	shader_material.set_shader_parameter("paint_color_shadow", paint_effect_color_shadow)
	shader_material.set_shader_parameter("paint_color_accent", paint_effect_color_accent)
	shader_material.set_shader_parameter("paint_detail_mode", paint_effect_detail_mode)
