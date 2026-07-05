extends Control


static var shared_mask_shader: Shader
static var shared_fallback_texture: Texture2D

var mask_material: ShaderMaterial
var fast_flat_render_enabled := false
var texture: Texture2D = null:
	set(value):
		texture = value if value != null else _fallback_texture()
		_update_mask_params()
		queue_redraw()
var radius := 66.0
var crop_left := 0.0
var crop_right := 0.0
var crop_top := 0.0
var crop_bottom := 0.0
var art_height := 0.0
var feather_height := 150.0
var mask_inset := 6.0
var corner_mask_mode := 0
var bottom_shape := "round"
var wide_u_bottom_rise := 58.0
var fallback_color := Color("#3aa0ff")
var aspect_mode := 0
var sample_zoom := 1.0
var sample_offset_px := Vector2.ZERO
var mask_shader_params_initialized := false
var mask_shader_params_texture: Texture2D
var mask_shader_params_size := Vector2(-1.0, -1.0)
var mask_shader_params_radius := -1.0
var mask_shader_params_crop_left := -1.0
var mask_shader_params_crop_right := -1.0
var mask_shader_params_crop_top := -1.0
var mask_shader_params_crop_bottom := -1.0
var mask_shader_params_feather_height := -1.0
var mask_shader_params_art_height := -1.0
var mask_shader_params_inset := -1.0
var mask_shader_params_corner_mode := -1
var mask_shader_params_bottom_shape := -1
var mask_shader_params_wide_u_bottom_rise := -1.0
var mask_shader_params_aspect_mode := -1
var mask_shader_params_fallback_color := Color(0, 0, 0, 0)
var mask_shader_params_sample_zoom := -1.0
var mask_shader_params_sample_offset_px := Vector2.INF

func _ready() -> void:
	_ensure_mask_material()

func _draw() -> void:
	if size.x < 1.0 or size.y < 1.0:
		return
	if fast_flat_render_enabled:
		_draw_fast_flat_texture()
		return
	_update_mask_params()
	draw_rect(Rect2(Vector2.ZERO, size), Color.WHITE)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _ensure_mask_material() -> void:
	if fast_flat_render_enabled:
		return
	if material == null:
		if shared_mask_shader == null:
			shared_mask_shader = Shader.new()
			shared_mask_shader.code = """
shader_type canvas_item;

uniform sampler2D bg_texture;
uniform vec2 control_size = vec2(1.0, 1.0);
uniform float radius_px = 64.0;
uniform float crop_left = 0.0;
uniform float crop_right = 0.0;
uniform float crop_top = 0.0;
uniform float crop_bottom = 0.0;
uniform float feather_px = 150.0;
uniform float art_height_px = 0.0;
uniform float mask_inset_px = 0.0;
uniform int corner_mask_mode = 0;
uniform int bottom_shape = 0;
uniform float wide_u_bottom_rise_px = 58.0;
uniform int aspect_mode = 0;
uniform vec4 fallback_color : source_color = vec4(0.2, 0.55, 0.9, 1.0);
uniform float sample_zoom = 1.0;
uniform vec2 sample_offset_px = vec2(0.0, 0.0);

void fragment() {
	vec2 p = UV * control_size;
	float inset = clamp(mask_inset_px, 0.0, min(control_size.x, control_size.y) * 0.45);
	vec2 mask_size = max(vec2(1.0), control_size - vec2(inset * 2.0));
	vec2 mask_p = p - vec2(inset);
	vec2 half_size = mask_size * 0.5;
	float r;
	if (corner_mask_mode == 1) {
		r = min(radius_px, min(half_size.x, half_size.y));
	} else {
		r = min(max(0.0, radius_px - inset), min(half_size.x, half_size.y));
	}
	vec2 q = abs(mask_p - half_size) - (half_size - vec2(r));
	float distance = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
	float alpha = 1.0 - smoothstep(0.0, corner_mask_mode == 1 ? 1.0 : 2.0, distance);
	if (bottom_shape == 1) {
		float side_y = max(0.0, control_size.y - wide_u_bottom_rise_px);
		float x_pct = clamp(p.x / max(1.0, control_size.x), 0.0, 1.0);
		float corner_r = min(radius_px * 0.62, control_size.x * 0.14);
		float curve_x = clamp((p.x - corner_r) / max(1.0, control_size.x - corner_r * 2.0), 0.0, 1.0);
		float curve_y = mix(side_y, control_size.y, sin(curve_x * 3.14159265));
		if (p.x < corner_r && p.y > side_y - corner_r) {
			vec2 corner_center = vec2(corner_r, side_y - corner_r);
			curve_y = side_y - corner_r + sqrt(max(0.0, corner_r * corner_r - pow(p.x - corner_center.x, 2.0)));
		}
		if (p.x > control_size.x - corner_r && p.y > side_y - corner_r) {
			vec2 corner_center = vec2(control_size.x - corner_r, side_y - corner_r);
			curve_y = side_y - corner_r + sqrt(max(0.0, corner_r * corner_r - pow(p.x - corner_center.x, 2.0)));
		}
		alpha *= 1.0 - smoothstep(curve_y - 1.0, curve_y + 1.0, p.y);
	}
	vec4 fill_color = vec4(fallback_color.rgb, 1.0);
	vec4 color;

	vec2 tex_size = vec2(textureSize(bg_texture, 0));
	if (aspect_mode == 2) {
		if (tex_size.x < 1.0 || tex_size.y < 1.0) {
			color = fill_color;
		} else {
			float control_aspect = control_size.x / max(control_size.y, 1.0);
			float tex_aspect = tex_size.x / tex_size.y;
			vec2 source_uv = UV;
			if (control_aspect > tex_aspect) {
				source_uv.x = 0.5 + (UV.x - 0.5) * (control_aspect / tex_aspect);
			} else {
				source_uv.y = 0.5 + (UV.y - 0.5) * (tex_aspect / control_aspect);
			}
			float zoom = max(1.0, sample_zoom);
			source_uv = vec2(0.5) + (source_uv - vec2(0.5)) / zoom - sample_offset_px / max(vec2(1.0), control_size) / zoom;
			bool in_bounds = (source_uv.x >= 0.0 && source_uv.x <= 1.0 && source_uv.y >= 0.0 && source_uv.y <= 1.0);
			source_uv = clamp(source_uv, vec2(0.0), vec2(1.0));
			vec4 art_sample = texture(bg_texture, source_uv);
			color = in_bounds ? (art_sample.a > 0.01 ? vec4(art_sample.rgb, 1.0) : fill_color) : fill_color;
		}
	} else {
		if (tex_size.x < 1.0 || tex_size.y < 1.0) {
			color = fill_color;
		} else {
			float crop_width = max(0.001, 1.0 - crop_left - crop_right);
			float crop_height = max(0.001, 1.0 - crop_top - crop_bottom);
			float u = UV.x;
			float v_raw;
			float art_top;
			float art_bottom;
			float eff_w = tex_size.x * crop_width;
			float eff_h = tex_size.y * crop_height;
			float scale = control_size.x / max(1.0, eff_w);
			float natural_h = eff_h * scale;
			float offset_y = (natural_h - control_size.y) * 0.5;
			v_raw = (p.y + offset_y) / max(1.0, natural_h);
			if (natural_h >= control_size.y) {
				art_top = 0.0;
				art_bottom = control_size.y;
			} else {
				art_top = (control_size.y - natural_h) * 0.5;
				art_bottom = art_top + natural_h;
			}
			bool in_bounds = (v_raw >= 0.0 && v_raw <= 1.0);
			float v = clamp(v_raw, 0.0, 1.0);
			vec2 source_uv = vec2(crop_left + u * crop_width, crop_top + v * crop_height);
			vec4 art_sample = texture(bg_texture, source_uv);
			float top_fade = 1.0;
			float bottom_fade = 1.0;
			if (feather_px > 0.5) {
				float top_feather_weight = (art_height_px < 1.0) ? 1.0 : smoothstep(art_height_px, art_height_px + feather_px, control_size.y);
				top_fade = mix(1.0, smoothstep(art_top, min(art_top + feather_px, art_bottom), p.y), top_feather_weight);
				bottom_fade = 1.0 - smoothstep(max(art_top, art_bottom - feather_px), art_bottom, p.y);
			}
			float art_mix = in_bounds ? (art_sample.a * top_fade * bottom_fade) : 0.0;
			color = mix(fill_color, vec4(art_sample.rgb, 1.0), art_mix);
		}
	}
	color.a = alpha;
	COLOR = color;
}
"""
		if mask_material == null:
			var shader_material := ShaderMaterial.new()
			shader_material.shader = shared_mask_shader
			mask_material = shader_material
		material = mask_material
	_update_mask_params()


func _draw_fast_flat_texture() -> void:
	var current_texture := _mask_texture()
	if current_texture == null:
		draw_rect(Rect2(Vector2.ZERO, size), fallback_color)
		return
	var texture_size := current_texture.get_size()
	if texture_size.x < 1.0 or texture_size.y < 1.0:
		draw_rect(Rect2(Vector2.ZERO, size), fallback_color)
		return
	var source_rect := Rect2(Vector2.ZERO, texture_size)
	if aspect_mode == 2:
		var control_aspect := size.x / maxf(size.y, 1.0)
		var texture_aspect := texture_size.x / maxf(texture_size.y, 1.0)
		if control_aspect > texture_aspect:
			var source_height := texture_size.x / control_aspect
			source_rect.position.y = (texture_size.y - source_height) * 0.5
			source_rect.size.y = source_height
		else:
			var source_width := texture_size.y * control_aspect
			source_rect.position.x = (texture_size.x - source_width) * 0.5
			source_rect.size.x = source_width
		var zoom := maxf(1.0, sample_zoom)
		if zoom > 1.0:
			var zoomed_size := source_rect.size / zoom
			source_rect.position += (source_rect.size - zoomed_size) * 0.5
			source_rect.size = zoomed_size
		var safe_control_size := Vector2(maxf(size.x, 1.0), maxf(size.y, 1.0))
		source_rect.position += sample_offset_px * texture_size / safe_control_size
	else:
		source_rect.position.x = texture_size.x * crop_left
		source_rect.position.y = texture_size.y * crop_top
		source_rect.size.x = texture_size.x * maxf(0.001, 1.0 - crop_left - crop_right)
		source_rect.size.y = texture_size.y * maxf(0.001, 1.0 - crop_top - crop_bottom)
	source_rect.position.x = clampf(source_rect.position.x, 0.0, maxf(0.0, texture_size.x - 1.0))
	source_rect.position.y = clampf(source_rect.position.y, 0.0, maxf(0.0, texture_size.y - 1.0))
	source_rect.size.x = clampf(source_rect.size.x, 1.0, texture_size.x - source_rect.position.x)
	source_rect.size.y = clampf(source_rect.size.y, 1.0, texture_size.y - source_rect.position.y)
	draw_texture_rect_region(current_texture, Rect2(Vector2.ZERO, size), source_rect, Color.WHITE)

func _update_mask_params() -> void:
	var shader_material := material as ShaderMaterial
	if shader_material == null:
		return
	var current_texture := _mask_texture()
	if current_texture == null:
		return
	if _mask_shader_params_unchanged():
		return
	var texture_changed := not mask_shader_params_initialized or mask_shader_params_texture != current_texture
	if texture_changed:
		shader_material.set_shader_parameter("bg_texture", current_texture)
	shader_material.set_shader_parameter("control_size", size)
	shader_material.set_shader_parameter("radius_px", radius)
	shader_material.set_shader_parameter("crop_left", crop_left)
	shader_material.set_shader_parameter("crop_right", crop_right)
	shader_material.set_shader_parameter("crop_top", crop_top)
	shader_material.set_shader_parameter("crop_bottom", crop_bottom)
	shader_material.set_shader_parameter("feather_px", feather_height)
	shader_material.set_shader_parameter("art_height_px", art_height)
	shader_material.set_shader_parameter("mask_inset_px", mask_inset)
	shader_material.set_shader_parameter("corner_mask_mode", corner_mask_mode)
	shader_material.set_shader_parameter("bottom_shape", 1 if bottom_shape == "wide_u" else 0)
	shader_material.set_shader_parameter("wide_u_bottom_rise_px", wide_u_bottom_rise)
	shader_material.set_shader_parameter("aspect_mode", aspect_mode)
	shader_material.set_shader_parameter("fallback_color", fallback_color)
	shader_material.set_shader_parameter("sample_zoom", sample_zoom)
	shader_material.set_shader_parameter("sample_offset_px", sample_offset_px)
	_store_mask_shader_params(current_texture)

func _mask_shader_params_unchanged() -> bool:
	return (
		mask_shader_params_initialized
		and mask_shader_params_texture == _mask_texture()
		and mask_shader_params_size.is_equal_approx(size)
		and absf(mask_shader_params_radius - radius) <= 0.001
		and absf(mask_shader_params_crop_left - crop_left) <= 0.001
		and absf(mask_shader_params_crop_right - crop_right) <= 0.001
		and absf(mask_shader_params_crop_top - crop_top) <= 0.001
		and absf(mask_shader_params_crop_bottom - crop_bottom) <= 0.001
		and absf(mask_shader_params_feather_height - feather_height) <= 0.001
		and absf(mask_shader_params_art_height - art_height) <= 0.001
		and absf(mask_shader_params_inset - mask_inset) <= 0.001
		and mask_shader_params_corner_mode == corner_mask_mode
		and mask_shader_params_bottom_shape == (1 if bottom_shape == "wide_u" else 0)
		and absf(mask_shader_params_wide_u_bottom_rise - wide_u_bottom_rise) <= 0.001
		and mask_shader_params_aspect_mode == aspect_mode
		and mask_shader_params_fallback_color.is_equal_approx(fallback_color)
		and absf(mask_shader_params_sample_zoom - sample_zoom) <= 0.001
		and mask_shader_params_sample_offset_px.is_equal_approx(sample_offset_px)
	)

func _mask_texture() -> Texture2D:
	return texture if texture != null else _fallback_texture()

func _store_mask_shader_params(current_texture: Texture2D) -> void:
	mask_shader_params_initialized = true
	mask_shader_params_texture = current_texture
	mask_shader_params_size = size
	mask_shader_params_radius = radius
	mask_shader_params_crop_left = crop_left
	mask_shader_params_crop_right = crop_right
	mask_shader_params_crop_top = crop_top
	mask_shader_params_crop_bottom = crop_bottom
	mask_shader_params_feather_height = feather_height
	mask_shader_params_art_height = art_height
	mask_shader_params_inset = mask_inset
	mask_shader_params_corner_mode = corner_mask_mode
	mask_shader_params_bottom_shape = 1 if bottom_shape == "wide_u" else 0
	mask_shader_params_wide_u_bottom_rise = wide_u_bottom_rise
	mask_shader_params_aspect_mode = aspect_mode
	mask_shader_params_fallback_color = fallback_color
	mask_shader_params_sample_zoom = sample_zoom
	mask_shader_params_sample_offset_px = sample_offset_px

static func _fallback_texture() -> Texture2D:
	if shared_fallback_texture != null:
		return shared_fallback_texture
	if DisplayServer.get_name() == "headless":
		var placeholder := PlaceholderTexture2D.new()
		placeholder.size = Vector2(8, 8)
		shared_fallback_texture = placeholder
		return shared_fallback_texture
	var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color(1.0, 1.0, 1.0, 0.0))
	shared_fallback_texture = ImageTexture.create_from_image(image)
	return shared_fallback_texture
