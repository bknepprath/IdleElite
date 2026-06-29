class_name ActionArtUi

const ActionArtTextureRect = preload("res://scripts/ui/action_art_texture_rect.gd")
const ActionArtAnimationRect = preload("res://scripts/ui/action_art_animation_rect.gd")


static func image(action: Dictionary, art_size: Vector2, art_offset: Vector2, texture_or_fallback: Callable, visual_fallback: Callable, headless: bool) -> ActionArtTextureRect:
	var path := str(action.get("art", ""))
	var animation := action.get("art_animation", {}) as Dictionary
	var node: ActionArtTextureRect = ActionArtAnimationRect.new() if not animation.is_empty() else ActionArtTextureRect.new()
	if headless:
		node.texture = visual_fallback.call()
		node.set_mask_material_enabled(false)
	else:
		node.texture = texture_or_fallback.call(path)
		node.set_mask_material_enabled(needs_texture_mask(path))
		if node is ActionArtAnimationRect:
			var animated_node := node as ActionArtAnimationRect
			var cell_size := Vector2(
				float(animation.get("cell_width", 256.0)),
				float(animation.get("cell_height", 256.0))
			)
			animated_node.configure_animation(
				texture_or_fallback.call(str(animation.get("atlas", ""))),
				int(animation.get("frame_count", 1)),
				cell_size,
				animation.get("sequence", []) as Array,
				animation.get("durations", []) as Array,
				str(animation.get("sync", "")),
				animation.get("effects", {})
			)
	node.custom_minimum_size = art_size
	node.size = art_size
	node.position = art_offset
	node.radius = 56.0
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.z_index = 1
	return node


static func add_corner_badges(art_panel: Control, resource_icon_paths: Array, special_type_icon_path: String, panel_size: Vector2, icon_size: Vector2, edge_overlap: float, list_step: float, stroke_pixels: float, texture_or_fallback: Callable) -> void:
	if art_panel == null or not is_instance_valid(art_panel):
		return
	art_panel.clip_contents = false
	for index in resource_icon_paths.size():
		art_panel.add_child(corner_badge(str(resource_icon_paths[index]), false, index, panel_size, icon_size, edge_overlap, list_step, stroke_pixels, texture_or_fallback))
	if not special_type_icon_path.is_empty():
		art_panel.add_child(corner_badge(special_type_icon_path, true, 0, panel_size, icon_size, edge_overlap, list_step, stroke_pixels, texture_or_fallback))


static func corner_badge(icon_path: String, align_right: bool, index: int, panel_size: Vector2, icon_size: Vector2, edge_overlap: float, list_step: float, stroke_pixels: float, texture_or_fallback: Callable) -> Control:
	var host := Control.new()
	host.custom_minimum_size = icon_size
	host.size = icon_size
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.z_index = 30 + index
	var x := panel_size.x - icon_size.x + edge_overlap if align_right else -edge_overlap + list_step * index
	host.position = Vector2(x, panel_size.y - icon_size.y + edge_overlap)

	var stroke := TextureRect.new()
	stroke.texture = texture_or_fallback.call(icon_path)
	stroke.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stroke.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	stroke.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	stroke.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stroke.size = icon_size + Vector2(stroke_pixels, stroke_pixels)
	stroke.position = Vector2(-stroke_pixels, -stroke_pixels) * 0.5
	stroke.modulate = Color(0.05, 0.035, 0.02, 0.9)
	stroke.z_index = 0
	host.add_child(stroke)

	var icon := TextureRect.new()
	icon.texture = texture_or_fallback.call(icon_path)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = icon_size
	icon.size = icon_size
	icon.z_index = 1
	host.add_child(icon)
	return host


static func border_overlay(style: StyleBox) -> Panel:
	var border := Panel.new()
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.z_index = 20
	border.add_theme_stylebox_override("panel", style)
	return border


static func needs_texture_mask(path: String) -> bool:
	return path.to_lower().contains("/backgrounds/")
