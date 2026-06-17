class_name AchievementMedalSlotStrip
extends Control


var slot_count := 25
var slot_size := Vector2(58, 58)
var icons := []
var shadows := []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layout_icons()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_icons()
		queue_redraw()

func add_slot_icon(icon: TextureRect, shadow: TextureRect = null) -> void:
	if shadow != null:
		shadows.append(shadow)
		add_child(shadow)
	icons.append(icon)
	add_child(icon)
	_layout_icons()

func _layout_icons() -> void:
	if icons.is_empty():
		return
	var icon_size := minf(slot_size.x, maxf(1.0, size.y * 0.92))
	for i in range(icons.size()):
		var center := _slot_center(i, icon_size)
		if i < shadows.size():
			var shadow := shadows[i] as TextureRect
			if shadow != null:
				var outline := bool(shadow.get_meta("achievement_medal_outline", false))
				var shadow_size := icon_size
				shadow.size = Vector2(shadow_size, shadow_size)
				shadow.position = center - shadow.size * 0.5
				if not outline:
					shadow.position += Vector2(7, 9)
		var icon := icons[i] as TextureRect
		if icon == null:
			continue
		icon.size = Vector2(icon_size, icon_size)
		icon.position = center - icon.size * 0.5

func _slot_center(index: int, icon_size: float) -> Vector2:
	var count := maxi(1, slot_count)
	var left := icon_size * 0.5
	var right := maxf(left, size.x - icon_size * 0.5)
	var x := (left + right) * 0.5
	if count > 1:
		x = lerpf(left, right, float(index) / float(count - 1))
	return Vector2(x, size.y * 0.52)
