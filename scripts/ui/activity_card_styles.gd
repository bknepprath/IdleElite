extends RefCounted

const ActivityCardDepth = preload("res://scripts/ui/activity_card_depth.gd")
const PrismConnectorOverlay = preload("res://scripts/ui/prism_connector_overlay.gd")

static var activity_shade_style_cache := {}
static var action_art_style_cache: StyleBoxFlat
static var action_art_border_style_cache: StyleBoxFlat


static func cached_shade(alpha: float) -> StyleBoxFlat:
	var key := int(round(alpha * 1000.0))
	if activity_shade_style_cache.has(key):
		return activity_shade_style_cache[key] as StyleBoxFlat
	var style := shade(alpha)
	activity_shade_style_cache[key] = style
	return style


static func cached_action_art(surface_style: Callable) -> StyleBoxFlat:
	if action_art_style_cache != null:
		return action_art_style_cache
	action_art_style_cache = action_art(surface_style)
	return action_art_style_cache


static func cached_action_art_border(surface_style: Callable) -> StyleBoxFlat:
	if action_art_border_style_cache != null:
		return action_art_border_style_cache
	action_art_border_style_cache = action_art_border(cached_action_art(surface_style))
	return action_art_border_style_cache


static func clear_cache() -> void:
	activity_shade_style_cache.clear()
	action_art_style_cache = null
	action_art_border_style_cache = null


static func featured_art(surface_style: Callable, line_color: Color) -> StyleBoxFlat:
	var style := surface_style.call(Color("#fffaf0"), 24, 8, true) as StyleBoxFlat
	style.border_color = line_color
	style.set_border_width_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


static func shade(alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.5, 0.5, 0.5, alpha)
	style.set_corner_radius_all(66)
	return style


static func action_card_background_edge_underlay(fill_color: Color, radius: float) -> Panel:
	var underlay := Panel.new()
	underlay.anchor_left = 0.0
	underlay.anchor_right = 1.0
	underlay.anchor_top = 0.0
	underlay.anchor_bottom = 1.0
	underlay.offset_left = -3.0
	underlay.offset_right = 3.0
	underlay.offset_top = -3.0
	underlay.offset_bottom = 3.0
	underlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	underlay.z_index = 149
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = Color.TRANSPARENT
	style.set_border_width_all(0)
	style.set_corner_radius_all(int(round(radius + 3.0)))
	style.anti_aliasing = true
	underlay.add_theme_stylebox_override("panel", style)
	return underlay


static func activity_card_depth_layer(theme_color: Color, depth_offset: Vector2, radius: float, gutter: float) -> ActivityCardDepth:
	var depth := ActivityCardDepth.new()
	depth.depth_offset = depth_offset
	depth.radius = radius
	depth.back_color = theme_color.darkened(0.36)
	depth.side_color = theme_color.darkened(0.48)
	depth.bottom_color = theme_color.darkened(0.24)
	depth.draw_back_plate_bottom_outline = true
	var highlight := theme_color.lightened(0.42)
	highlight.a = 0.24
	depth.highlight_color = highlight
	var themed_shadow := theme_color.darkened(0.72)
	themed_shadow.a = 0.28
	depth.shadow_color = themed_shadow
	depth.anchor_left = 0.0
	depth.anchor_right = 1.0
	depth.anchor_top = 0.0
	depth.anchor_bottom = 1.0
	depth.offset_left = gutter
	depth.offset_right = -gutter + depth_offset.x
	depth.offset_top = 0.0
	depth.offset_bottom = 0.0
	depth.mouse_filter = Control.MOUSE_FILTER_IGNORE
	depth.z_index = 0
	return depth


static func prism_connector_overlay(depth_offset: Vector2, radius: float, side: String, stroke_width: float, ink_color: Color) -> PrismConnectorOverlay:
	var connector := PrismConnectorOverlay.new()
	connector.side = side
	connector.depth_offset = depth_offset
	connector.radius = radius
	connector.diagonal_radius = 32.0
	connector.stroke_width = stroke_width
	connector.ink_color = ink_color
	connector.set_anchors_preset(Control.PRESET_FULL_RECT)
	connector.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return connector


static func activity_card_shade_layer(pop_card: Control, alpha := 0.50) -> Panel:
	if pop_card == null:
		return null
	var shade_panel := Panel.new()
	shade_panel.add_theme_stylebox_override("panel", cached_shade(alpha))
	shade_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade_panel.visible = false
	shade_panel.z_index = 224
	pop_card.add_child(shade_panel)
	return shade_panel


static func ensure_activity_card_shade(card: Dictionary, alpha := 0.50) -> Panel:
	var existing_panel := card.get("shade") as Panel
	if existing_panel != null and is_instance_valid(existing_panel):
		return existing_panel
	var pop_card := card.get("pop") as Control
	if pop_card == null or not is_instance_valid(pop_card):
		return null
	var shade_panel := activity_card_shade_layer(pop_card, alpha)
	card["shade"] = shade_panel
	return shade_panel


static func action_art(surface_style: Callable) -> StyleBoxFlat:
	var style := surface_style.call(Color.WHITE, 56, 16, true) as StyleBoxFlat
	style.border_color = Color("#eee2ce")
	style.set_border_width_all(5)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style


static func action_art_border(action_art_style: StyleBoxFlat) -> StyleBoxFlat:
	var style := action_art_style.duplicate() as StyleBoxFlat
	style.draw_center = false
	return style


static func art_glow(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.28)
	style.border_color = Color(color.r, color.g, color.b, 0.95)
	style.set_border_width_all(24)
	style.set_corner_radius_all(56)
	return style


static func bonus_emphasis(flash_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(flash_color.r, flash_color.g, flash_color.b, 0.20)
	style.border_color = Color(flash_color.r, flash_color.g, flash_color.b, 0.88)
	style.set_border_width_all(18)
	style.set_corner_radius_all(38)
	style.shadow_color = Color(flash_color.r, flash_color.g, flash_color.b, 0.42)
	style.shadow_size = 18
	style.shadow_offset = Vector2.ZERO
	return style


static func bonus_bottom_highlight(flash_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(flash_color.r, flash_color.g, flash_color.b, 0.28)
	style.border_color = Color(flash_color.r, flash_color.g, flash_color.b, 0.95)
	style.set_border_width_all(14)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(flash_color.r, flash_color.g, flash_color.b, 0.34)
	style.shadow_size = 16
	style.shadow_offset = Vector2.ZERO
	return style


static func tutorial_target_ring() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.89, 0.24, 0.0)
	style.draw_center = false
	style.border_color = Color("#ffd94d")
	style.set_border_width_all(12)
	style.set_corner_radius_all(54)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.24)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 8)
	return style


static func crit_glow(mega_crit := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var fill := Color("#fff052") if mega_crit else Color("#67b8ff")
	var border := Color("#ffbf1f") if mega_crit else Color("#1f9dff")
	style.draw_center = true
	style.bg_color = Color(fill.r, fill.g, fill.b, 0.34 if mega_crit else 0.31)
	style.border_color = Color(border.r, border.g, border.b, 1.0 if mega_crit else 0.96)
	style.set_border_width_all(68 if mega_crit else 46)
	style.shadow_color = Color(1.0, 0.70, 0.0, 0.82) if mega_crit else Color(0.10, 0.58, 1.0, 0.62)
	style.shadow_size = 68 if mega_crit else 42
	style.shadow_offset = Vector2.ZERO
	style.set_corner_radius_all(82 if mega_crit else 66)
	return style


static func button_face(fill: Color, radius: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color.TRANSPARENT
	style.set_border_width_all(0)
	style.set_corner_radius_all(int(round(radius)))
	style.anti_aliasing = true
	style.anti_aliasing_size = 1.25
	return style
