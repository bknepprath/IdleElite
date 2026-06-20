class_name AchievementMedalSlotStrip
extends Control


var slot_count := 25
var slot_size := Vector2(58, 58)
var row_overlap := 0.48
var max_single_row_count := 11
var medal_icons := []
var medal_shadows := []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layout_icons()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_icons()
		queue_redraw()

func add_slot_icon(icon: TextureRect, shadow: TextureRect = null) -> void:
	if shadow != null:
		medal_shadows.append(shadow)
		add_child(shadow)
	medal_icons.append(icon)
	add_child(icon)
	_layout_icons()

func clear_slot_icons() -> void:
	medal_shadows.clear()
	medal_icons.clear()
	_layout_icons()

func _layout_icons() -> void:
	if medal_icons.is_empty():
		return
	var row_count := _row_count()
	var row_gap_ratio := maxf(0.20, 1.0 - clampf(row_overlap, 0.0, 0.80))
	var height_ratio := 1.0 + row_gap_ratio * float(row_count - 1)
	var icon_size := minf(slot_size.x, maxf(1.0, _layout_height() / height_ratio))
	for i in range(medal_icons.size()):
		var center := _slot_center(i, icon_size)
		var row_z := _slot_row(i) * 1000
		var slot_z := row_z + i * 2
		if i < medal_shadows.size():
			var shadow := medal_shadows[i] as TextureRect
			if shadow != null:
				var outline := bool(shadow.get_meta("achievement_medal_outline", false))
				var shadow_size := icon_size
				shadow.size = Vector2(shadow_size, shadow_size)
				shadow.position = center - shadow.size * 0.5
				shadow.z_index = slot_z
				if not outline:
					shadow.position += Vector2(7, 9)
		var icon := medal_icons[i] as TextureRect
		if icon == null:
			continue
		icon.size = Vector2(icon_size, icon_size)
		icon.position = center - icon.size * 0.5
		icon.z_index = slot_z + 1

func _slot_center(index: int, icon_size: float) -> Vector2:
	var count := maxi(1, slot_count)
	if count > 1:
		var top_row_count := _top_row_count(count)
		if index >= top_row_count:
			return _row_slot_center(index - top_row_count, count - top_row_count, icon_size, 1, top_row_count)
		return _row_slot_center(index, top_row_count, icon_size, 0, top_row_count)
	return Vector2(_layout_width() * 0.5, _layout_height() * 0.5)

func _row_slot_center(row_index: int, row_slot_count: int, icon_size: float, row: int, top_row_count: int) -> Vector2:
	var count := maxi(1, row_slot_count)
	var left := icon_size * 0.5
	var right := maxf(left, _layout_width() - icon_size * 0.5)
	var x := (left + right) * 0.5
	if count > 1:
		var available_width := maxf(0.0, right - left)
		var snug_step := icon_size * 0.72
		var total_snug_width := snug_step * float(count - 1)
		var row_left := (left + right) * 0.5 - total_snug_width * 0.5
		var row_right := row_left + total_snug_width
		if total_snug_width > available_width:
			row_left = left
			row_right = right
		if row == 1 and count < top_row_count and top_row_count > 1:
			var top_step := (row_right - row_left) / float(maxi(1, top_row_count - 1))
			row_left += top_step * 0.5
			row_right -= top_step * 0.5
		x = lerpf(row_left, row_right, float(row_index) / float(count - 1))
	var row_gap := icon_size * maxf(0.20, 1.0 - clampf(row_overlap, 0.0, 0.80))
	var total_height := icon_size + row_gap * float(_row_count() - 1)
	var top_y := (_layout_height() - total_height) * 0.5 + icon_size * 0.5
	return Vector2(x, top_y + row_gap * float(row))

func _row_count() -> int:
	var count := maxi(slot_count, medal_icons.size())
	if count <= max_single_row_count:
		return 1
	return 2

func _top_row_count(count: int) -> int:
	return int(ceil(float(count) / 2.0))

func _slot_row(index: int) -> int:
	if _row_count() <= 1:
		return 0
	return 1 if index >= _top_row_count(maxi(1, slot_count)) else 0

func _layout_width() -> float:
	return maxf(maxf(size.x, custom_minimum_size.x), slot_size.x)

func _layout_height() -> float:
	return maxf(maxf(size.y, custom_minimum_size.y), slot_size.y)
