extends RefCounted

static var symbol_clip_shader: Shader

class SkillIconBadgeMask:
	extends Control

	var fill_style: StyleBoxFlat

	func _ready() -> void:
		clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func _draw() -> void:
		if fill_style == null or size.x <= 1.0 or size.y <= 1.0:
			return
		draw_style_box(fill_style, Rect2(Vector2.ZERO, size))

class SkillIconSymbolDraw:
	extends Control

	var texture: Texture2D

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func _draw() -> void:
		if texture == null or size.x <= 1.0 or size.y <= 1.0:
			return
		draw_texture_rect(texture, Rect2(Vector2.ZERO, size), false)


static func icon_path(skill_id: String) -> String:
	return "res://assets/content/icons/skill-symbols/%s.png" % skill_id


static func menu_icon_badge(host, skill_id: String, theme_color: Color) -> Control:
	return icon_badge(host, skill_id, theme_color, host.SKILL_MENU_ICON_BADGE_SIZE, symbol_size(skill_id, host.SKILL_MENU_ICON_SYMBOL_SIZE))


static func achievement_icon_badge(host, skill_id: String, badge_size: Vector2) -> Control:
	var symbol_base_size: Vector2 = host.SKILL_MENU_ICON_SYMBOL_SIZE * (badge_size.x / maxf(1.0, host.SKILL_MENU_ICON_BADGE_SIZE.x))
	return icon_badge(host, skill_id, ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE), badge_size, symbol_size(skill_id, symbol_base_size))


static func detail_icon(host, skill_id: String) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = host.SKILL_DETAIL_ICON_SIZE
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var detail_symbol_base_size: Vector2 = host.SKILL_MENU_ICON_SYMBOL_SIZE * (host.SKILL_DETAIL_ICON_SIZE.x / maxf(1.0, host.SKILL_MENU_ICON_BADGE_SIZE.x))
	var icon := icon_badge(host, skill_id, ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE), host.SKILL_DETAIL_ICON_SIZE, symbol_size(skill_id, detail_symbol_base_size))
	icon.position.y = host.SKILL_DETAIL_ICON_Y_OFFSET
	holder.add_child(icon)
	return holder


static func symbol_control(host, skill_id: String) -> Control:
	if skill_id == "fishing":
		var drawn_symbol := SkillIconSymbolDraw.new()
		drawn_symbol.texture = host.visual_texture_cache._texture_or_visual_fallback(icon_path(skill_id))
		return drawn_symbol
	var texture_symbol := TextureRect.new()
	texture_symbol.texture = host.visual_texture_cache._texture_or_visual_fallback(icon_path(skill_id))
	texture_symbol.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_symbol.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return texture_symbol


static func icon_badge(host, skill_id: String, theme_color: Color, badge_size: Vector2, icon_symbol_size: Vector2) -> Control:
	var badge := Control.new()
	badge.custom_minimum_size = badge_size
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.clip_contents = true
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var mask := SkillIconBadgeMask.new()
	mask.set_anchors_preset(Control.PRESET_FULL_RECT)
	mask.fill_style = fill_style(theme_color, badge_size)
	mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(mask)

	var symbol := symbol_control(host, skill_id)
	symbol.custom_minimum_size = icon_symbol_size
	symbol.size = icon_symbol_size
	symbol.position = symbol_position(skill_id, badge_size, icon_symbol_size, host.SKILL_MENU_ICON_BADGE_SIZE)
	symbol.pivot_offset = icon_symbol_size * 0.5
	symbol.rotation = symbol_rotation(skill_id)
	symbol.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	symbol.material = symbol_clip_material(badge_size, icon_symbol_size, symbol.position, symbol.rotation)
	symbol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mask.add_child(symbol)

	var border := Panel.new()
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	border.add_theme_stylebox_override("panel", border_style(host, badge_size))
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(border)
	return badge


static func fill_style(theme_color: Color, badge_size: Vector2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color(theme_color)
	style.border_color = Color.TRANSPARENT
	style.set_border_width_all(0)
	style.set_corner_radius_all(int(round(minf(badge_size.x, badge_size.y) * 0.16)))
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style


static func border_style(host, badge_size: Vector2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = host.COLOR_INK
	style.set_border_width_all(10)
	style.set_corner_radius_all(int(round(minf(badge_size.x, badge_size.y) * 0.16)))
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style


static func fill_color(theme_color: Color) -> Color:
	return theme_color


static func symbol_clip_material(badge_size: Vector2, icon_symbol_size: Vector2, icon_symbol_position: Vector2, icon_symbol_rotation: float) -> ShaderMaterial:
	if symbol_clip_shader == null:
		var shader := Shader.new()
		shader.code = """
shader_type canvas_item;

uniform vec2 badge_size = vec2(1.0, 1.0);
uniform vec2 symbol_size = vec2(1.0, 1.0);
uniform vec2 symbol_position = vec2(0.0, 0.0);
uniform float symbol_rotation = 0.0;
uniform float corner_radius = 1.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 local_point = UV * symbol_size;
	vec2 symbol_pivot = symbol_size * 0.5;
	vec2 pivot_delta = local_point - symbol_pivot;
	float c = cos(symbol_rotation);
	float s = sin(symbol_rotation);
	vec2 rotated_point = vec2(
		pivot_delta.x * c - pivot_delta.y * s,
		pivot_delta.x * s + pivot_delta.y * c
	) + symbol_pivot;
	vec2 badge_point = rotated_point + symbol_position;
	vec2 half_badge = badge_size * 0.5;
	vec2 rounded_half = half_badge - vec2(corner_radius);
	vec2 q = abs(badge_point - half_badge) - rounded_half;
	float distance_from_round_rect = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - corner_radius;
	if (distance_from_round_rect > 0.0) {
		discard;
	}
	COLOR = tex;
}
"""
		symbol_clip_shader = shader
	var material := ShaderMaterial.new()
	material.shader = symbol_clip_shader
	material.set_shader_parameter("badge_size", badge_size)
	material.set_shader_parameter("symbol_size", icon_symbol_size)
	material.set_shader_parameter("symbol_position", icon_symbol_position)
	material.set_shader_parameter("symbol_rotation", icon_symbol_rotation)
	material.set_shader_parameter("corner_radius", minf(badge_size.x, badge_size.y) * 0.16)
	return material


static func symbol_position(skill_id: String, badge_size: Vector2, icon_symbol_size: Vector2, menu_badge_size: Vector2) -> Vector2:
	var icon_position := (badge_size - icon_symbol_size) * 0.5
	var offset_scale := badge_size.x / maxf(1.0, menu_badge_size.x)
	match skill_id:
		"woodcutting":
			icon_position += Vector2(-49, 88) * offset_scale
		"fishing":
			icon_position += Vector2(24, -34) * offset_scale
		"build":
			icon_position += Vector2(10, 64) * offset_scale
		"thieving":
			icon_position += Vector2(8, 0) * offset_scale
		"fight":
			icon_position += Vector2(26, 40) * offset_scale
	return icon_position


static func symbol_rotation(skill_id: String) -> float:
	match skill_id:
		"fishing":
			return deg_to_rad(-8.0)
		_:
			return 0.0


static func symbol_size(skill_id: String, base_size: Vector2) -> Vector2:
	match skill_id:
		"build":
			return base_size * 1.42
		"woodcutting":
			return base_size * 1.70
		"fishing":
			return base_size * 1.16
		"thieving":
			return base_size * 1.18
		"fight":
			return base_size * 1.22
		_:
			return base_size
