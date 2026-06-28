class_name FishingToolWalletOverlay
extends Control

const COLOR_GOLD := Color("#fff2a8")
const COLOR_MUTED := Color("#6e6658")

var wallet_panel_size := Vector2.ZERO
var tool_button_rects: Array = []
var wallet_tool_ids: Array = []
var wallet_tool_icons: Array = []
var tool_unlocked_states: Array = []
var equipped_tool_id := ""

func configure(next_wallet_panel_size: Vector2, next_tool_button_rects: Array, next_wallet_tool_ids: Array, next_wallet_tool_icons: Array, next_tool_unlocked_states: Array, next_equipped_tool_id: String) -> void:
	wallet_panel_size = next_wallet_panel_size
	tool_button_rects = []
	wallet_tool_ids = []
	wallet_tool_icons = []
	tool_unlocked_states = []
	var count := mini(next_tool_button_rects.size(), mini(next_wallet_tool_ids.size(), next_tool_unlocked_states.size()))
	for index in range(count):
		var raw_rect = next_tool_button_rects[index]
		if not (raw_rect is Rect2):
			continue
		tool_button_rects.append(raw_rect as Rect2)
		wallet_tool_ids.append(str(next_wallet_tool_ids[index]))
		wallet_tool_icons.append(next_wallet_tool_icons[index] if index < next_wallet_tool_icons.size() else null)
		tool_unlocked_states.append(bool(next_tool_unlocked_states[index]))
	equipped_tool_id = next_equipped_tool_id
	_rebuild_visuals()
	queue_redraw()

func button_index_at(global_point: Vector2) -> int:
	var point: Vector2 = get_global_transform_with_canvas().affine_inverse() * global_point
	for index in range(tool_button_rects.size()):
		var rect := _tool_button_rect(index)
		if rect.has_point(point):
			return index
	return -1

func button_center_global(index: int) -> Vector2:
	if index < 0 or index >= tool_button_rects.size():
		return Vector2.ZERO
	var rect := _tool_button_rect(index)
	return get_global_transform_with_canvas() * rect.get_center()

func _draw() -> void:
	pass

func _rebuild_visuals() -> void:
	for child in get_children():
		child.queue_free()
	var background := Panel.new()
	background.name = "WalletVisiblePill"
	background.position = Vector2.ZERO
	background.size = wallet_panel_size
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_theme_stylebox_override("panel", _wallet_style(Color("#fff6df"), Color("#171615"), 10.0, wallet_panel_size.x * 0.5))
	add_child(background)
	for index in range(tool_button_rects.size()):
		var rect := _tool_button_rect(index)
		var tool_id := str(wallet_tool_ids[index]) if index < wallet_tool_ids.size() else ""
		var unlocked := bool(tool_unlocked_states[index]) if index < tool_unlocked_states.size() else false
		var equipped := tool_id == equipped_tool_id
		var fill := Color("#32c5bd") if equipped else (Color("#fffdf8") if unlocked else Color("#cfcac0"))
		var border := COLOR_GOLD if equipped else (Color("#171615") if unlocked else COLOR_MUTED)
		var circle := Panel.new()
		circle.name = "WalletVisibleGear%s" % str(index)
		circle.position = rect.position
		circle.size = rect.size
		circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		circle.add_theme_stylebox_override("panel", _wallet_style(fill, border, 8.0 if equipped else 5.0, rect.size.x * 0.5))
		add_child(circle)
		var tool_icon: Texture2D = null
		if index < wallet_tool_icons.size() and wallet_tool_icons[index] is Texture2D:
			tool_icon = wallet_tool_icons[index] as Texture2D
		if tool_icon != null:
			var icon_rect := _fit_texture_rect(tool_icon, Rect2(Vector2.ZERO, rect.size).grow(-18.0))
			var texture_rect := TextureRect.new()
			texture_rect.texture = tool_icon
			texture_rect.position = icon_rect.position
			texture_rect.size = icon_rect.size
			texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			texture_rect.modulate = Color.WHITE if unlocked else Color(1, 1, 1, 0.42)
			texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			circle.add_child(texture_rect)

func _tool_button_rect(index: int) -> Rect2:
	if index < 0 or index >= tool_button_rects.size():
		return Rect2()
	var raw_rect = tool_button_rects[index]
	if raw_rect is Rect2:
		return raw_rect as Rect2
	return Rect2()

func _wallet_style(fill: Color, border: Color, border_width: float, radius: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = int(border_width)
	style.border_width_top = int(border_width)
	style.border_width_right = int(border_width)
	style.border_width_bottom = int(border_width)
	var corner := int(radius)
	style.corner_radius_top_left = corner
	style.corner_radius_top_right = corner
	style.corner_radius_bottom_left = corner
	style.corner_radius_bottom_right = corner
	style.shadow_color = Color(0, 0, 0, 0.22)
	style.shadow_size = 10
	style.shadow_offset = Vector2(4, 6)
	return style

func _fit_texture_rect(texture: Texture2D, bounds: Rect2) -> Rect2:
	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return bounds
	var fit_scale := minf(bounds.size.x / texture_size.x, bounds.size.y / texture_size.y)
	var draw_size := texture_size * fit_scale
	return Rect2(bounds.position + (bounds.size - draw_size) * 0.5, draw_size)
