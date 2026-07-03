class_name ActionArtUi

const ActionArtTextureRect = preload("res://scripts/ui/action_art_texture_rect.gd")
const ActionArtAnimationRect = preload("res://scripts/ui/action_art_animation_rect.gd")

const EVENT_HOURGLASS_BADGE := "res://assets/content/ui/event-hourglass-badge.png"
const ACTION_ART_PANEL_SIZE := Vector2(410, 410)
const ACTION_ART_SIZE := Vector2(427.2, 427.2)
const ACTION_ART_OFFSET := Vector2(-8.6, -8.6)
const ACTION_ART_CORNER_ICON_SIZE := Vector2(172, 172)
const ACTION_ART_CORNER_ICON_EDGE_OVERLAP := 60.0
const ACTION_ART_CORNER_ICON_LIST_STEP := 104.0
const ACTION_ART_CORNER_ICON_STROKE_PIXELS := 14.0

static func image(action: Dictionary, texture_or_fallback: Callable, visual_fallback: Callable, headless: bool) -> ActionArtTextureRect:
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
	var art_size := display_size(action)
	node.custom_minimum_size = art_size
	node.size = art_size
	node.position = display_offset(action)
	node.radius = 56.0
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.z_index = 1
	return node


static func add_corner_badges(art_panel: Control, resource_icon_paths: Array, special_type_icon_path: String, texture_or_fallback: Callable) -> void:
	if art_panel == null or not is_instance_valid(art_panel):
		return
	art_panel.clip_contents = false
	for index in resource_icon_paths.size():
		art_panel.add_child(corner_badge(str(resource_icon_paths[index]), false, index, texture_or_fallback))
	if not special_type_icon_path.is_empty():
		art_panel.add_child(corner_badge(special_type_icon_path, true, 0, texture_or_fallback))


static func corner_badge(icon_path: String, align_right: bool, index: int, texture_or_fallback: Callable) -> Control:
	var host := Control.new()
	host.custom_minimum_size = ACTION_ART_CORNER_ICON_SIZE
	host.size = ACTION_ART_CORNER_ICON_SIZE
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.z_index = 30 + index
	var x := ACTION_ART_PANEL_SIZE.x - ACTION_ART_CORNER_ICON_SIZE.x + ACTION_ART_CORNER_ICON_EDGE_OVERLAP if align_right else -ACTION_ART_CORNER_ICON_EDGE_OVERLAP + ACTION_ART_CORNER_ICON_LIST_STEP * index
	host.position = Vector2(x, ACTION_ART_PANEL_SIZE.y - ACTION_ART_CORNER_ICON_SIZE.y + ACTION_ART_CORNER_ICON_EDGE_OVERLAP)

	var stroke := TextureRect.new()
	stroke.texture = texture_or_fallback.call(icon_path)
	stroke.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stroke.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	stroke.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	stroke.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stroke.size = ACTION_ART_CORNER_ICON_SIZE + Vector2(ACTION_ART_CORNER_ICON_STROKE_PIXELS, ACTION_ART_CORNER_ICON_STROKE_PIXELS)
	stroke.position = Vector2(-ACTION_ART_CORNER_ICON_STROKE_PIXELS, -ACTION_ART_CORNER_ICON_STROKE_PIXELS) * 0.5
	stroke.modulate = Color(0.05, 0.035, 0.02, 0.9)
	stroke.z_index = 0
	host.add_child(stroke)

	var icon := TextureRect.new()
	icon.texture = texture_or_fallback.call(icon_path)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = ACTION_ART_CORNER_ICON_SIZE
	icon.size = ACTION_ART_CORNER_ICON_SIZE
	icon.z_index = 1
	host.add_child(icon)
	return host


static func resource_icon_paths(action: Dictionary, action_mat_reward_defs: Callable, mat_icon_path: Callable, temporary_event_log_reward_mat_id: Callable) -> Array:
	var icon_paths := []
	var mat_rewards := action_mat_reward_defs.call(action) as Array
	for raw_reward in mat_rewards:
		var reward := raw_reward as Dictionary
		var icon_path := str(mat_icon_path.call(str(reward.get("id", ""))))
		if not icon_path.is_empty() and not icon_paths.has(icon_path):
			icon_paths.append(icon_path)
	if not icon_paths.is_empty():
		return icon_paths
	var raw_resource_rewards = action.get("resource_rewards", {})
	if typeof(raw_resource_rewards) != TYPE_DICTIONARY:
		return icon_paths
	var resource_rewards := raw_resource_rewards as Dictionary
	if int(resource_rewards.get("logs_max", resource_rewards.get("logs_min", resource_rewards.get("logs", 0)))) > 0:
		icon_paths.append(str(mat_icon_path.call(str(temporary_event_log_reward_mat_id.call()))))
	return icon_paths


static func special_type_icon_path(action: Dictionary, is_event_action: Callable) -> String:
	if bool(is_event_action.call(action)):
		return EVENT_HOURGLASS_BADGE
	return ""


static func display_size(action: Dictionary) -> Vector2:
	return ACTION_ART_SIZE


static func display_offset(action: Dictionary) -> Vector2:
	return ACTION_ART_OFFSET


static func border_overlay(style: StyleBox) -> Panel:
	var border := Panel.new()
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.z_index = 20
	border.add_theme_stylebox_override("panel", style)
	return border


static func needs_texture_mask(path: String) -> bool:
	return path.to_lower().contains("/backgrounds/")
