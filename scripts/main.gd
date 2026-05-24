extends Control

class RegenCircle:
	extends Control

	var value := 0.0
	var target_value := 0.0
	var displayed_current := 0.0
	var target_current := 0.0
	var current := 0
	var maximum := 1
	var theme_color := Color("#36b8e8")
	var value_initialized := false
	var stamina_initialized := false

	func _ready() -> void:
		set_process(true)

	func set_value(next_value: float, instant := false) -> void:
		var clamped_value := clampf(next_value, 0.0, 1.0)
		var wrapped_to_next_refill := value_initialized and clamped_value < target_value - 0.18
		target_value = clamped_value
		if instant or not value_initialized or wrapped_to_next_refill:
			value = target_value
			value_initialized = true
		queue_redraw()

	func set_theme_color(next_color: Color) -> void:
		theme_color = next_color
		queue_redraw()

	func set_stamina(next_current: int, next_maximum: int, instant := false) -> void:
		current = maxi(0, next_current)
		maximum = maxi(1, next_maximum)
		target_current = clampf(float(current), 0.0, float(maximum))
		if instant or not stamina_initialized:
			displayed_current = target_current
			stamina_initialized = true
		queue_redraw()

	func _process(delta: float) -> void:
		var next_value := _ease_to(value, target_value, 8.0, delta)
		var next_current := _ease_to(displayed_current, target_current, 9.0, delta)
		if absf(next_value - value) > 0.0005 or absf(next_current - displayed_current) > 0.01:
			value = next_value
			displayed_current = next_current
			queue_redraw()
		else:
			var needs_final_redraw := absf(value - target_value) > 0.0 or absf(displayed_current - target_current) > 0.0
			value = target_value
			displayed_current = target_current
			if needs_final_redraw:
				queue_redraw()

	func _ease_to(from: float, to: float, speed: float, delta: float) -> float:
		if delta <= 0.0:
			return from
		return lerpf(from, to, 1.0 - exp(-speed * delta))

	func _draw() -> void:
		var center := size * 0.5
		var scale := minf(size.x, size.y) / 552.0
		var outer_radius := minf(size.x, size.y) * 0.5
		var outer_border := 18.0 * scale
		var ring_width := 60.0 * scale
		var ring_radius := outer_radius - outer_border - ring_width * 0.5
		var black_radius := outer_radius - 48.0 * scale
		var inner_radius := 186.0 * scale
		var inner_border := 18.0 * scale
		draw_circle(center, outer_radius, Color("#171615"))
		draw_circle(center, outer_radius - outer_border, Color("#fff2a8"))
		draw_arc(center, ring_radius, -PI * 0.5, -PI * 0.5 + TAU * value, 128, theme_color, ring_width, true)
		draw_circle(center, black_radius, Color("#171615"))
		draw_circle(center, inner_radius + inner_border, Color("#171615"))
		draw_circle(center, inner_radius, Color("#fffaf0"))
		_draw_inner_fill(center, inner_radius)
		_draw_center_text(center)

	func _draw_inner_fill(center: Vector2, radius: float) -> void:
		var pct := clampf(displayed_current / float(maximum), 0.0, 1.0)
		if pct <= 0.0:
			return
		if pct >= 0.995:
			draw_circle(center, radius, theme_color)
			return
		var fill_top := center.y + radius - radius * 2.0 * pct
		var fill_bottom := center.y + radius
		var step := maxf(1.0, radius / 64.0)
		var y := fill_top
		while y <= fill_bottom:
			var dy := y - center.y
			var chord := sqrt(maxf(0.0, radius * radius - dy * dy))
			draw_line(Vector2(center.x - chord, y), Vector2(center.x + chord, y), theme_color, step + 1.0, true)
			y += step

	func _draw_center_text(center: Vector2) -> void:
		var font := ThemeDB.fallback_font
		var large := maxi(32, int(minf(size.x, size.y) * 0.155))
		var shown_current := clampi(int(round(displayed_current)), 0, maximum)
		var text := "Tired!" if shown_current <= 0 else "%s/%s" % [shown_current, maximum]
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, large)
		var text_pos := center + Vector2(-text_size.x * 0.5, text_size.y * 0.32)
		_draw_stroked_text(font, text, text_pos, large)

	func _draw_stroked_text(font: Font, text: String, position: Vector2, font_size: int) -> void:
		for offset in [
			Vector2(-3, -3), Vector2(0, -3), Vector2(3, -3),
			Vector2(-3, 0), Vector2(3, 0),
			Vector2(-3, 3), Vector2(0, 3), Vector2(3, 3)
		]:
			draw_string(font, position + offset, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#171615"))
		draw_string(font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)


class CleanProgressBar:
	extends Control

	var value := 0.0
	var fill_color := Color.WHITE
	var track_color := Color("#fff1c8")
	var border_color := Color("#171615")
	var border_width := 9.0

	func set_value(next_value: float) -> void:
		value = clampf(next_value, 0.0, 100.0)
		queue_redraw()

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var radius := size.y * 0.5
		_draw_round_rect(rect, track_color, radius)
		var inner := rect.grow(-border_width)
		_draw_round_rect(inner, track_color, maxf(0.0, radius - border_width))
		var fill_width := inner.size.x * value / 100.0
		if fill_width > 0.0:
			var fill := Rect2(inner.position, Vector2(fill_width, inner.size.y))
			if fill_width >= inner.size.x - 0.5:
				_draw_round_rect(inner, fill_color, maxf(0.0, radius - border_width))
			else:
				draw_rect(fill, fill_color)
		_draw_round_outline(rect, border_color, radius, border_width)

	func _draw_round_rect(rect: Rect2, color: Color, radius: float) -> void:
		var center_y := rect.position.y + rect.size.y * 0.5
		var clamped_radius := minf(radius, rect.size.x * 0.5)
		draw_rect(Rect2(rect.position + Vector2(clamped_radius, 0), Vector2(maxf(0.0, rect.size.x - clamped_radius * 2.0), rect.size.y)), color)
		draw_circle(Vector2(rect.position.x + clamped_radius, center_y), clamped_radius, color)
		draw_circle(Vector2(rect.end.x - clamped_radius, center_y), clamped_radius, color)

	func _draw_round_outline(rect: Rect2, color: Color, radius: float, width: float) -> void:
		var half_width := width * 0.5
		var y_top := rect.position.y + half_width
		var y_bottom := rect.end.y - half_width
		var x_left := rect.position.x + radius
		var x_right := rect.end.x - radius
		draw_line(Vector2(x_left, y_top), Vector2(x_right, y_top), color, width, true)
		draw_line(Vector2(x_left, y_bottom), Vector2(x_right, y_bottom), color, width, true)
		draw_arc(Vector2(x_left, rect.position.y + radius), radius - half_width, PI, PI * 1.5, 32, color, width, true)
		draw_arc(Vector2(x_right, rect.position.y + radius), radius - half_width, PI * 1.5, TAU, 32, color, width, true)
		draw_arc(Vector2(x_left, rect.end.y - radius), radius - half_width, PI * 0.5, PI, 32, color, width, true)
		draw_arc(Vector2(x_right, rect.end.y - radius), radius - half_width, 0.0, PI * 0.5, 32, color, width, true)


class ActivityProgressRail:
	extends Control

	var value := 0.0
	var fill_color := Color("#35d86d")
	var empty_color := Color("#fff1c8")
	var top_lip_color := Color("#171615")
	var top_lip_height := 16.0
	var bottom_radius := 66.0

	func set_value(next_value: float) -> void:
		value = clampf(next_value, 0.0, 100.0)
		queue_redraw()

	func _draw() -> void:
		if size.x <= 1.0 or size.y <= 1.0:
			return
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, top_lip_height)), top_lip_color)
		var track_rect := Rect2(Vector2(0, top_lip_height), Vector2(size.x, maxf(0.0, size.y - top_lip_height)))
		_draw_bottom_round_fill(track_rect, empty_color, 1.0)
		_draw_bottom_round_fill(track_rect, fill_color, value / 100.0)

	func _draw_bottom_round_fill(rect: Rect2, color: Color, fill_pct: float) -> void:
		var pct := clampf(fill_pct, 0.0, 1.0)
		if pct <= 0.0 or rect.size.y <= 0.0:
			return
		var radius := minf(bottom_radius, minf(rect.size.x * 0.5, rect.size.y))
		var fill_right := rect.position.x + rect.size.x * pct
		var bottom := rect.end.y
		var arc_start := bottom - radius
		var center_y := arc_start
		var y := rect.position.y
		while y <= bottom:
			var left_bound := rect.position.x
			var right_bound := rect.end.x
			if y > arc_start and radius > 0.0:
				var dy := y - center_y
				var chord := sqrt(maxf(0.0, radius * radius - dy * dy))
				left_bound = rect.position.x + radius - chord
				right_bound = rect.end.x - radius + chord
			var line_right := minf(right_bound, fill_right)
			if line_right > left_bound:
				draw_line(Vector2(left_bound, y), Vector2(line_right, y), color, 2.0, false)
			y += 2.0


class AchievementMedalSlotStrip:
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
					shadow.size = Vector2(icon_size, icon_size)
					shadow.position = center - shadow.size * 0.5 + Vector2(7, 9)
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


class ActivityCardBorder:
	extends Control

	var border_color := Color("#171615")
	var border_width := 16.0
	var radius := 66.0

	func _draw() -> void:
		var half := border_width * 0.5
		var left := half
		var right := maxf(half, size.x - half)
		var top := half
		var bottom := maxf(half, size.y - half)
		var r := minf(radius, minf(size.x, size.y) * 0.5 - half)
		draw_line(Vector2(left + r, top), Vector2(right - r, top), border_color, border_width, true)
		draw_line(Vector2(left + r, bottom), Vector2(right - r, bottom), border_color, border_width, true)
		draw_line(Vector2(left, top + r), Vector2(left, bottom - r), border_color, border_width, true)
		draw_line(Vector2(right, top + r), Vector2(right, bottom - r), border_color, border_width, true)
		draw_arc(Vector2(left + r, top + r), r, PI, PI * 1.5, 24, border_color, border_width, true)
		draw_arc(Vector2(right - r, top + r), r, PI * 1.5, PI * 2.0, 24, border_color, border_width, true)
		draw_arc(Vector2(right - r, bottom - r), r, 0.0, PI * 0.5, 24, border_color, border_width, true)
		draw_arc(Vector2(left + r, bottom - r), r, PI * 0.5, PI, 24, border_color, border_width, true)


class RoundedTextureRect:
	extends TextureRect

	var radius := 66.0
	var crop_left := 0.0
	var crop_right := 0.0

	func _ready() -> void:
		_ensure_mask_material()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			_update_mask_params()

	func _ensure_mask_material() -> void:
		if material == null:
			var shader := Shader.new()
			shader.code = """
shader_type canvas_item;

uniform vec2 control_size = vec2(1.0, 1.0);
uniform float radius_px = 64.0;
uniform float crop_left = 0.0;
uniform float crop_right = 0.0;

void fragment() {
	vec2 p = UV * control_size;
	vec2 half_size = control_size * 0.5;
	float r = min(radius_px, min(half_size.x, half_size.y));
	vec2 q = abs(p - half_size) - (half_size - vec2(r));
	float distance = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
	float alpha = 1.0 - smoothstep(0.0, 2.0, distance);
	vec4 tint = COLOR;
	float crop_width = max(0.001, 1.0 - crop_left - crop_right);
	vec2 source_uv = vec2(crop_left + UV.x * crop_width, UV.y);
	COLOR = texture(TEXTURE, source_uv) * tint;
	COLOR.a *= alpha;
}
"""
			var shader_material := ShaderMaterial.new()
			shader_material.shader = shader
			material = shader_material
		_update_mask_params()

	func _update_mask_params() -> void:
		var shader_material := material as ShaderMaterial
		if shader_material == null:
			return
		shader_material.set_shader_parameter("control_size", size)
		shader_material.set_shader_parameter("radius_px", radius)
		shader_material.set_shader_parameter("crop_left", crop_left)
		shader_material.set_shader_parameter("crop_right", crop_right)


class MobileScrollContainer:
	extends ScrollContainer

	const DRAG_DEADZONE := 18.0
	const PULL_RESISTANCE_MAX := 210.0
	const PULL_SNAP_SECONDS := 0.34

	var drag_tracking := false
	var drag_scrolling := false
	var drag_start := Vector2.ZERO
	var drag_last := Vector2.ZERO
	var velocity := 0.0
	var pull_resistance_enabled := false
	var pull_raw_offset := 0.0
	var pull_offset := 0.0
	var scroll_tween: Tween
	var pull_tween: Tween

	func _ready() -> void:
		set_process(true)
		scroll_deadzone = int(DRAG_DEADZONE)

	func set_pull_resistance_enabled(enabled: bool) -> void:
		pull_resistance_enabled = enabled
		if not enabled:
			_set_pull_raw_offset(0.0)
			_cancel_pull_tween()

	func _input(event: InputEvent) -> void:
		if not is_visible_in_tree():
			return
		if _modal_blocks_this_scroll():
			drag_tracking = false
			drag_scrolling = false
			velocity = 0.0
			_cancel_scroll_tween()
			return
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if _contains_global_point(event.global_position):
					_cancel_scroll_tween()
					_cancel_pull_tween()
					drag_tracking = true
					drag_scrolling = false
					drag_start = event.global_position
					drag_last = event.global_position
					velocity = 0.0
			elif drag_tracking:
				if drag_scrolling:
					get_viewport().set_input_as_handled()
				drag_tracking = false
				drag_scrolling = false
				_snap_pull_offset()
			return
		if event is InputEventMouseMotion and drag_tracking:
			var distance: float = event.global_position.distance_to(drag_start)
			var drag_offset: Vector2 = event.global_position - drag_start
			if distance >= DRAG_DEADZONE and absf(drag_offset.y) > absf(drag_offset.x) * 1.15:
				drag_scrolling = true
			if drag_scrolling:
				var delta_y: float = event.global_position.y - drag_last.y
				if pull_resistance_enabled and (pull_raw_offset > 0.0 or (scroll_vertical <= 0 and delta_y > 0.0)):
					_set_pull_raw_offset(maxf(0.0, pull_raw_offset + delta_y))
					velocity = 0.0
				else:
					scroll_vertical = clampi(scroll_vertical - int(round(delta_y)), 0, _max_scroll_vertical())
					velocity = -delta_y * 60.0
				drag_last = event.global_position
				get_viewport().set_input_as_handled()
		if event is InputEventScreenTouch:
			if event.pressed:
				if _contains_global_point(event.position):
					_cancel_scroll_tween()
					_cancel_pull_tween()
					drag_tracking = true
					drag_scrolling = false
					drag_start = event.position
					drag_last = event.position
					velocity = 0.0
			elif drag_tracking:
				if drag_scrolling:
					get_viewport().set_input_as_handled()
				drag_tracking = false
				drag_scrolling = false
				_snap_pull_offset()
			return
		if event is InputEventScreenDrag and drag_tracking:
			var distance: float = event.position.distance_to(drag_start)
			var drag_offset: Vector2 = event.position - drag_start
			if distance >= DRAG_DEADZONE and absf(drag_offset.y) > absf(drag_offset.x) * 1.15:
				drag_scrolling = true
			if drag_scrolling:
				var delta_y: float = event.position.y - drag_last.y
				if pull_resistance_enabled and (pull_raw_offset > 0.0 or (scroll_vertical <= 0 and delta_y > 0.0)):
					_set_pull_raw_offset(maxf(0.0, pull_raw_offset + delta_y))
					velocity = 0.0
				else:
					scroll_vertical = clampi(scroll_vertical - int(round(delta_y)), 0, _max_scroll_vertical())
					velocity = -delta_y * 60.0
				drag_last = event.position
				get_viewport().set_input_as_handled()

	func _process(delta: float) -> void:
		if _modal_blocks_this_scroll():
			velocity = 0.0
			return
		if drag_tracking or pull_offset > 0.0 or absf(velocity) < 4.0:
			return
		scroll_vertical = clampi(scroll_vertical + int(round(velocity * delta)), 0, _max_scroll_vertical())
		velocity = lerpf(velocity, 0.0, 1.0 - exp(-9.0 * delta))

	func _contains_global_point(point: Vector2) -> bool:
		return Rect2(global_position, size).has_point(point)

	func _modal_blocks_this_scroll() -> bool:
		var tree := get_tree()
		if tree == null:
			return false
		for node in tree.get_nodes_in_group("modal_overlay"):
			var modal := node as Control
			if modal != null and modal.visible and modal.is_visible_in_tree() and not _is_descendant_of(modal):
				return true
		return false

	func _is_descendant_of(node: Node) -> bool:
		var current: Node = self
		while current != null:
			if current == node:
				return true
			current = current.get_parent()
		return false

	func _max_scroll_vertical() -> int:
		var scroll_bar := get_v_scroll_bar()
		if scroll_bar != null:
			return maxi(0, int(ceil(scroll_bar.max_value - scroll_bar.page)))
		var max_scroll: float = 0.0
		for child in get_children():
			if child is Control:
				var control := child as Control
				max_scroll = maxf(max_scroll, control.position.y + control.size.y)
		return maxi(0, int(ceil(max_scroll - size.y)))

	func scroll_to_vertical(target: int, duration := 0.26) -> void:
		_cancel_scroll_tween()
		velocity = 0.0
		var clamped_target := clampi(target, 0, _max_scroll_vertical())
		if duration <= 0.0:
			scroll_vertical = clamped_target
			return
		scroll_tween = create_tween()
		scroll_tween.tween_property(self, "scroll_vertical", clamped_target, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	func _cancel_scroll_tween() -> void:
		if scroll_tween != null and scroll_tween.is_valid():
			scroll_tween.kill()
		scroll_tween = null

	func _set_pull_raw_offset(next_raw_offset: float) -> void:
		pull_raw_offset = maxf(0.0, next_raw_offset)
		pull_offset = PULL_RESISTANCE_MAX * (1.0 - exp(-pull_raw_offset / PULL_RESISTANCE_MAX))
		position.y = pull_offset

	func _snap_pull_offset() -> void:
		if pull_offset <= 0.0:
			_set_pull_raw_offset(0.0)
			return
		_cancel_pull_tween()
		velocity = 0.0
		pull_raw_offset = 0.0
		pull_tween = create_tween()
		pull_tween.tween_property(self, "position:y", 0.0, PULL_SNAP_SECONDS).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
		pull_tween.finished.connect(func():
			pull_offset = 0.0
			pull_raw_offset = 0.0
			pull_tween = null
		)

	func _cancel_pull_tween() -> void:
		if pull_tween != null and pull_tween.is_valid():
			pull_tween.kill()
			pull_offset = maxf(0.0, position.y)
			var pull_pct := clampf(pull_offset / PULL_RESISTANCE_MAX, 0.0, 0.98)
			pull_raw_offset = -PULL_RESISTANCE_MAX * log(1.0 - pull_pct)
		pull_tween = null


const SAVE_PATH := "user://idle_elite_save.json"
const ACTIVITY_DATABASE_PATH := "res://docs/activity-database.json"
const MASTERY_MEDALS_TEXTURE := "res://docs/assets/ui/mastery-medals-20.png"
const ACHIEVEMENT_TOTAL_LEVEL_ART := "res://docs/assets/achievements/achievement-total-level.png"
const ACHIEVEMENT_CREDIT_ART := "res://docs/assets/achievements/achievement-credit.png"
const ACHIEVEMENT_CUMULATIVE_MEDALS_ART := "res://docs/assets/achievements/achievement-cumulative-medals.png"
const BASE_MAX_STAMINA := 30
const STAMINA_REGEN_SECONDS := 12.0
const MAX_OFFLINE_SECONDS := 8 * 60 * 60
const MASTERY_MAX_LEVEL := 10
const ACHIEVEMENT_MEDAL_ART_COUNT := 20
const ACHIEVEMENT_MEDAL_SLOT_COUNT := 25
const ACHIEVEMENT_MEDAL_SLOT_SIZE := Vector2(62, 62)
const ACHIEVEMENT_MEDAL_SLOT_STEP := 36.0
const TOTAL_LEVEL_ACHIEVEMENT_TARGETS := [25, 50, 100, 150, 250, 375, 495]
const MASTERY_MEDAL_NAMES := [
	"Bronze",
	"Silver",
	"Gold",
	"Platinum",
	"Sapphire",
	"Emerald",
	"Ruby",
	"Diamond",
	"Demonic",
	"Heavenly"
]
const GLOBAL_MEDAL_BUFFS := [
	{"level": 1, "stat": "max_stamina", "amount": 1.0},
	{"level": 2, "stat": "xp_mult", "amount": 0.02},
	{"level": 3, "stat": "speed_mult", "amount": 0.02},
	{"level": 4, "stat": "success_bonus", "amount": 1.0},
	{"level": 5, "stat": "max_stamina", "amount": 1.0},
	{"level": 6, "stat": "xp_mult", "amount": 0.03},
	{"level": 7, "stat": "speed_mult", "amount": 0.03},
	{"level": 8, "stat": "success_bonus", "amount": 1.0},
	{"level": 9, "stat": "max_stamina", "amount": 2.0},
	{"level": 10, "stat": "xp_mult", "amount": 0.05}
]
const BASE_CANVAS := Vector2(2160, 3840)
const BOTTOM_NAV_HEIGHT := 420
const BOTTOM_NAV_SAFE_PAD := 96
const PAGE_PAD := 96
const CARD_RADIUS := 64
const ACTION_CARD_HEIGHT := 720
const ACTION_CARD_POP_GUTTER := 44
const SKILL_MENU_CARD_SIDE_INSET := 36
const SKILL_MENU_COPY_WIDTH := 820
const SKILL_SWIPE_THRESHOLD := 230.0
const SKILL_SWIPE_FEEDBACK_DEADZONE := 46.0
const SKILL_SWIPE_MAX_DRAG := 1120.0
const SKILL_SWIPE_PAGE_GAP := 82.0
const SKILL_SWIPE_SETTLE_SECONDS := 0.46
const SKILL_SWIPE_CANCEL_SECONDS := 0.22
const MODAL_OVERLAY_Z := 4096
const ACHIEVEMENTS_MODAL_SIZE := Vector2(1760, 3000)
const ACHIEVEMENTS_MODAL_SCROLL_HEIGHT := 2220.0
const GLOBAL_BUFFS_MODAL_MIN_HEIGHT := 1440.0
const GLOBAL_BUFFS_MODAL_BASE_HEIGHT := 1260.0
const GLOBAL_BUFFS_MODAL_ROW_HEIGHT := 120.0
const GLOBAL_BUFFS_MODAL_MAX_HEIGHT := 2740.0
const GLOBAL_BUFFS_MODAL_SCROLL_CHROME := 760.0

const COLOR_INK := Color("#171615")
const COLOR_PAPER := Color("#f8f1e5")
const COLOR_PANEL := Color("#fffdf8")
const COLOR_LINE := Color("#d9cfbc")
const COLOR_MUTED := Color("#6e6658")
const COLOR_GOLD := Color("#fff2a8")
const COLOR_GREEN := Color("#35d86d")
const COLOR_BLUE := Color("#3aa0ff")
const COLOR_NAV := Color("#444a5b")
const COLOR_RED := Color("#e84d4d")
const SKILL_THEME_COLORS := {
	"fight": Color("#36b8e8"),
	"thieving": Color("#8956bc"),
	"build": Color("#237cd5"),
	"woodcutting": Color("#6ea937"),
	"fishing": Color("#2dc0b9")
}

const SKILL_DEFS := [
	{"id": "fight", "name": "Fight", "verb": "Fighting", "time_scale": 0.88, "xp_scale": 1.00, "success_start": 95.0},
	{"id": "thieving", "name": "Thieving", "verb": "Sneaking", "time_scale": 0.72, "xp_scale": 1.00, "success_start": 96.0},
	{"id": "build", "name": "Build", "verb": "Building", "time_scale": 1.28, "xp_scale": 1.00, "success_start": 86.0},
	{"id": "woodcutting", "name": "Woodcutting", "verb": "Chopping", "time_scale": 1.08, "xp_scale": 1.00, "success_start": 90.0},
	{"id": "fishing", "name": "Fishing", "verb": "Fishing", "time_scale": 1.58, "xp_scale": 1.72, "success_start": 90.0},
]

const UNLOCK_LEVELS := [
	1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
	12, 14, 16, 18, 20, 22, 24, 26, 28, 30,
	33, 36, 40, 45, 50
]

const ACTION_FILES := {
	"fight": [
		"01-shove-wobbly-hay-bale.png",
		"02-kick-mud-off-boot.png",
		"03-wrestle-stuck-gate-latch.png",
		"04-box-suspicious-feed-sack.png",
		"05-duel-leaning-fence-post.png",
		"06-outmuscle-angry-wheelbarrow.png"
	],
	"thieving": [
		"01-pocket-a-penny-nobody-wanted.png",
		"02-borrow-a-cookie-permanently.png",
		"03-sneak-past-tip-jar-eye-contact.png",
		"04-lift-loose-coins-from-couch-cushions.png",
		"05-distract-fruit-stand-with-jazz-hands.png",
		"06-steal-a-wallet-from-a-mannequin.png"
	],
	"build": [
		"01-stack-two-rocks-confidently.png",
		"02-hammer-a-loose-fence-nail.png",
		"03-patch-leaky-bucket-with-hope.png",
		"04-build-a-wobbly-stool.png",
		"05-repair-squeaky-barn-door.png",
		"06-assemble-judgmental-birdhouse.png"
	],
	"woodcutting": [
		"01-gather-fallen-branches.png",
		"02-snap-a-twig-with-purpose.png",
		"03-trim-overconfident-shrub.png",
		"04-chop-softwood-tree.png",
		"05-split-firewood.png",
		"06-fell-skinny-pine.png"
	],
	"fishing": [
		"01-scoop-pond-minnows.png",
		"02-dangle-string-from-dock.png",
		"03-cast-bamboo-rod.png",
		"04-drag-net-through-creek.png",
		"05-set-tiny-crab-pot.png",
		"06-fly-fish-at-river-bend.png"
	]
}

var skills := {}
var skill_defs := []
var actions_by_skill := {}
var selected_skill_id := "fight"
var current_screen := "home"
var running_skill_id := ""
var running_action_id := ""
var action_progress := 0.0
var mastery := {}
var stamina := {}
var stamina_bank := {}
var last_result := "Pick a skill and start training."
var is_muted := false

var app_font: Font
var app_bold_font: Font
var mastery_medal_textures := {}
var mastery_medal_silhouette_textures := {}
var mastery_medal_dot_texture: Texture2D
var home_page: Control
var skills_page: Control
var nav_bar: PanelContainer
var content_scroll: ScrollContainer
var skills_content: Control
var home_total_label: Label
var home_skill_labels := {}
var hero_message: Label
var achievement_total_label: Label
var achievement_elite_label: Label
var achievement_total_bar: CleanProgressBar
var achievement_buff_label: Label
var achievement_total_level_label: Label
var achievement_best_art_frame: PanelContainer
var achievement_best_art: TextureRect
var achievement_best_name_label: Label
var achievement_best_medal: TextureRect
var achievement_skill_count_labels := {}
var achievement_skill_bars := {}
var achievement_skill_level_labels := {}
var achievement_skill_tier_name_labels := {}
var achievement_skill_tier_count_labels := {}
var achievement_skill_tier_bars := {}
var achievement_medal_slot_panels := {}
var achievement_medal_slot_icons := {}
var skills_tab: Button
var hero_tab: Button
var settings_tab: Button
var skill_cards := {}
var action_cards := {}
var action_pop_tweens := {}
var detail_xp_label: Label
var detail_xp_bar: CleanProgressBar
var detail_stamina_bar: CleanProgressBar
var detail_regen_circle: RegenCircle
var detail_actions_scroll: MobileScrollContainer
var detail_action_card_nodes := {}
var detail_rendered_action_ids := []
var skill_swipe_tracking := false
var skill_swipe_horizontal := false
var skill_swipe_start := Vector2.ZERO
var skill_swipe_last := Vector2.ZERO
var skill_swipe_tween: Tween
var skill_swipe_frame: Control
var skill_swipe_page: Control
var skill_swipe_preview_page: Control
var skill_swipe_preview_offset := 0
var skill_swipe_animating := false
var settings_overlay: Control
var achievements_overlay: Control
var achievements_panel: PanelContainer
var achievements_scroll: ScrollContainer
var achievements_list_stack: VBoxContainer
var achievements_tab_buttons := {}
var achievements_hide_completed: CheckBox
var achievements_modal_tab := "achievements"
var mute_button: Button
var click_player: AudioStreamPlayer
var success_player: AudioStreamPlayer
var failure_player: AudioStreamPlayer
var level_player: AudioStreamPlayer
var medal_player: AudioStreamPlayer
var audio_unlocked_by_input := false


func _ready() -> void:
	_load_font()
	_load_action_data()
	_init_state()
	_build_audio()
	_build_ui()
	load_game()
	_validate_state()
	_render_screen(current_screen == "skill")
	_update_ui(0.0, true)
	var timer := Timer.new()
	timer.wait_time = 10.0
	timer.autostart = true
	timer.timeout.connect(save_game)
	add_child(timer)


func _process(delta: float) -> void:
	_regen_stamina(delta)
	_process_action(delta)
	_update_ui(delta)


func _input(event: InputEvent) -> void:
	_note_player_input(event)
	var overlay_open := (settings_overlay != null and settings_overlay.visible) or (achievements_overlay != null and achievements_overlay.visible)
	if current_screen != "skill" or overlay_open:
		_cancel_skill_swipe_feedback()
		return
	if skill_swipe_animating:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if skills_page != null and Rect2(skills_page.global_position, skills_page.size).has_point(event.global_position):
				skill_swipe_tracking = true
				skill_swipe_horizontal = false
				skill_swipe_start = event.global_position
				skill_swipe_last = event.global_position
		elif skill_swipe_tracking:
			_finish_skill_swipe(event.global_position)
		return
	if event is InputEventMouseMotion and skill_swipe_tracking:
		_update_skill_swipe_feedback(event.global_position)
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			skill_swipe_tracking = true
			skill_swipe_horizontal = false
			skill_swipe_start = event.position
			skill_swipe_last = event.position
		elif skill_swipe_tracking:
			_finish_skill_swipe(event.position)
		return
	if event is InputEventScreenDrag and skill_swipe_tracking:
		_update_skill_swipe_feedback(event.position)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save_game()


func _build_ui() -> void:
	var root := ColorRect.new()
	root.color = COLOR_PAPER
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	
	home_page = Control.new()
	home_page.set_anchors_preset(Control.PRESET_FULL_RECT)
	home_page.offset_bottom = -BOTTOM_NAV_HEIGHT
	add_child(home_page)
	_build_home_page()
	
	skills_page = Control.new()
	skills_page.set_anchors_preset(Control.PRESET_FULL_RECT)
	skills_page.offset_bottom = -BOTTOM_NAV_HEIGHT
	add_child(skills_page)
	_build_skills_page()
	
	_build_nav_bar()
	_build_settings_overlay()
	_build_achievements_overlay()


func _build_home_page() -> void:
	achievement_skill_count_labels.clear()
	achievement_skill_bars.clear()
	achievement_skill_level_labels.clear()
	achievement_skill_tier_name_labels.clear()
	achievement_skill_tier_count_labels.clear()
	achievement_skill_tier_bars.clear()
	achievement_medal_slot_panels.clear()
	achievement_medal_slot_icons.clear()
	achievement_total_label = null
	achievement_elite_label = null
	achievement_total_bar = null
	achievement_buff_label = null
	achievement_total_level_label = null
	achievement_best_art_frame = null
	achievement_best_art = null
	achievement_best_name_label = null
	achievement_best_medal = null
	hero_message = null
	var scroll := MobileScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	home_page.add_child(scroll)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", PAGE_PAD)
	margin.add_theme_constant_override("margin_right", PAGE_PAD)
	margin.add_theme_constant_override("margin_top", 96)
	margin.add_theme_constant_override("margin_bottom", BOTTOM_NAV_SAFE_PAD + 190)
	scroll.add_child(margin)
	
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 10)
	margin.add_child(stack)
	
	var logo := TextureRect.new()
	logo.texture = _texture("res://docs/assets/logo/idle-elite-logo-chroma.png")
	logo.custom_minimum_size = Vector2(0, 560)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.material = _chroma_material(Color("#00ff00"))
	stack.add_child(logo)

	stack.add_child(_build_elite_summary())
	
	var hero_panel := PanelContainer.new()
	hero_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_panel.add_theme_stylebox_override("panel", _panel_style(Color(1, 0.96, 0.78, 0.35), 0, 0))
	stack.add_child(hero_panel)
	_build_achievements(hero_panel)


func _make_level_snapshot() -> Control:
	home_skill_labels.clear()
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 36)
	
	var total_row := HBoxContainer.new()
	total_row.alignment = BoxContainer.ALIGNMENT_CENTER
	total_row.add_theme_constant_override("separation", 34)
	stack.add_child(total_row)
	total_row.add_child(_image("res://docs/assets/ui/total-lv-bargraph.png", Vector2(150, 150)))
	home_total_label = _label("", 108, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	total_row.add_child(home_total_label)
	
	var rows := VBoxContainer.new()
	rows.alignment = BoxContainer.ALIGNMENT_CENTER
	rows.add_theme_constant_override("separation", 22)
	stack.add_child(rows)
	for def in skill_defs:
		var skill_id := str(def["id"])
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(720, 185)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 38)
		rows.add_child(row)
		row.add_child(_image("res://docs/assets/icons/%s.png" % skill_id, Vector2(144, 144)))
		var value := _label("", 78, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
		value.custom_minimum_size = Vector2(520, 0)
		row.add_child(value)
		home_skill_labels[skill_id] = value
	return stack


func _build_elite_summary() -> Control:
	var row := VBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	var copy := VBoxContainer.new()
	copy.custom_minimum_size = Vector2(860, 0)
	copy.add_theme_constant_override("separation", 12)
	row.add_child(copy)
	achievement_elite_label = _label("", 112, Color("#f4bf35"), HORIZONTAL_ALIGNMENT_CENTER)
	achievement_elite_label.add_theme_color_override("font_outline_color", COLOR_INK)
	achievement_elite_label.add_theme_constant_override("outline_size", 12)
	copy.add_child(achievement_elite_label)
	achievement_total_bar = _progress(Color("#f4bf35"), 58)
	copy.add_child(achievement_total_bar)
	return row


func _build_achievements(parent: PanelContainer) -> void:
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_bottom", 120)
	parent.add_child(margin)

	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 30)
	margin.add_child(stack)

	var achievements_button := Button.new()
	achievements_button.text = ""
	achievements_button.custom_minimum_size = Vector2(1680, 210)
	achievements_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	achievements_button.focus_mode = Control.FOCUS_NONE
	achievements_button.add_theme_stylebox_override("normal", _achievement_card_style(Color("#fffdf8"), 42, 28))
	achievements_button.add_theme_stylebox_override("hover", _achievement_card_style(COLOR_GOLD, 42, 28))
	achievements_button.add_theme_stylebox_override("pressed", _achievement_card_style(COLOR_GOLD.darkened(0.08), 42, 28))
	achievements_button.pressed.connect(_open_achievements_overlay)
	stack.add_child(achievements_button)
	var achievement_button_margin := MarginContainer.new()
	achievement_button_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	achievement_button_margin.add_theme_constant_override("margin_left", 38)
	achievement_button_margin.add_theme_constant_override("margin_right", 38)
	achievement_button_margin.add_theme_constant_override("margin_top", 20)
	achievement_button_margin.add_theme_constant_override("margin_bottom", 20)
	achievement_button_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	achievements_button.add_child(achievement_button_margin)
	var achievement_title_row := HBoxContainer.new()
	achievement_title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	achievement_title_row.add_theme_constant_override("separation", 28)
	achievement_title_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	achievement_button_margin.add_child(achievement_title_row)
	achievement_title_row.add_child(_image("res://docs/assets/ui/motivation-star.png", Vector2(100, 100)))
	achievement_title_row.add_child(_label("Achievements", 104, COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER))

	var best_card := PanelContainer.new()
	best_card.custom_minimum_size = Vector2(1680, 290)
	best_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	best_card.add_theme_stylebox_override("panel", _achievement_card_style(Color("#fffdf8"), 42, 26))
	stack.add_child(best_card)
	var best_margin := MarginContainer.new()
	best_margin.add_theme_constant_override("margin_left", 34)
	best_margin.add_theme_constant_override("margin_right", 34)
	best_margin.add_theme_constant_override("margin_top", 22)
	best_margin.add_theme_constant_override("margin_bottom", 22)
	best_card.add_child(best_margin)
	var best_copy := VBoxContainer.new()
	best_copy.alignment = BoxContainer.ALIGNMENT_CENTER
	best_copy.add_theme_constant_override("separation", 10)
	best_margin.add_child(best_copy)
	best_copy.add_child(_label("Most impressive activity:", 52, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var best_row := HBoxContainer.new()
	best_row.alignment = BoxContainer.ALIGNMENT_CENTER
	best_row.add_theme_constant_override("separation", 18)
	best_copy.add_child(best_row)
	achievement_best_art_frame = PanelContainer.new()
	achievement_best_art_frame.custom_minimum_size = Vector2(174, 174)
	achievement_best_art_frame.add_theme_stylebox_override("panel", _featured_activity_art_style())
	best_row.add_child(achievement_best_art_frame)
	achievement_best_art = _image("", Vector2(146, 146))
	achievement_best_art_frame.add_child(achievement_best_art)
	achievement_best_name_label = _label("Earn a medal to feature an activity", 66, COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	achievement_best_name_label.custom_minimum_size = Vector2(610, 0)
	achievement_best_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	best_row.add_child(achievement_best_name_label)
	achievement_best_medal = _image_from_texture(null, Vector2(140, 140))
	best_row.add_child(achievement_best_medal)

	var total_margin := MarginContainer.new()
	total_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	total_margin.add_theme_constant_override("margin_top", 42)
	stack.add_child(total_margin)
	var total_section := HBoxContainer.new()
	total_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	total_section.alignment = BoxContainer.ALIGNMENT_CENTER
	total_section.add_theme_constant_override("separation", 40)
	total_margin.add_child(total_section)
	total_section.add_child(_image("res://docs/assets/ui/total-lv-bargraph.png", Vector2(210, 210)))
	achievement_total_level_label = _label("", 122, COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	total_section.add_child(achievement_total_level_label)

	for def in skill_defs:
		var skill_id := str(def["id"])
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 470)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", _achievement_card_style(COLOR_PANEL, 46, 38))
		stack.add_child(card)

		var skill_stack := VBoxContainer.new()
		skill_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		skill_stack.add_theme_constant_override("separation", 22)
		card.add_child(skill_stack)

		var header := HBoxContainer.new()
		header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.alignment = BoxContainer.ALIGNMENT_CENTER
		header.add_theme_constant_override("separation", 34)
		skill_stack.add_child(header)
		var icon := _image("res://docs/assets/icons/%s.png" % skill_id, Vector2(178, 178))
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		header.add_child(icon)

		var level_label := _label("", 112, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
		level_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		header.add_child(level_label)
		achievement_skill_level_labels[skill_id] = level_label

		var actions: Array = actions_by_skill.get(skill_id, [])
		var slot_strip := _achievement_medal_slot_strip(skill_id, actions)
		skill_stack.add_child(slot_strip["root"])
		achievement_skill_tier_name_labels[skill_id] = []
		achievement_skill_tier_count_labels[skill_id] = []
		achievement_medal_slot_panels[skill_id] = [slot_strip["panels"]]
		achievement_medal_slot_icons[skill_id] = [slot_strip["icons"]]

	var bottom_spacer := Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 70)
	stack.add_child(bottom_spacer)


func _build_hero(parent: PanelContainer) -> void:
	var scene := Control.new()
	scene.clip_contents = true
	parent.add_child(scene)

	var stage := Control.new()
	stage.anchor_right = 1.0
	stage.anchor_bottom = 0.0
	stage.offset_bottom = 1530
	scene.add_child(stage)
	
	var hero := TextureRect.new()
	hero.texture = _texture("res://docs/assets/characters/stick-hero.png")
	hero.anchor_left = 0.03
	hero.anchor_right = 0.80
	hero.anchor_top = 0.30
	hero.anchor_bottom = 1.48
	hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero.material = _hero_chroma_material()
	stage.add_child(hero)
	
	var bubble := Control.new()
	bubble.anchor_left = 0.02
	bubble.anchor_right = 0.82
	bubble.anchor_top = 0.12
	bubble.anchor_bottom = 0.40
	stage.add_child(bubble)
	var bubble_art := TextureRect.new()
	bubble_art.texture = _texture("res://docs/assets/ui/speech-bubble-down.png")
	bubble_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	bubble_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bubble_art.stretch_mode = TextureRect.STRETCH_SCALE
	bubble.add_child(bubble_art)
	hero_message = _label("I MUST BECOME AN IDLE ELITIST!", 72, COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	hero_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hero_message.anchor_left = 0.08
	hero_message.anchor_right = 0.92
	hero_message.anchor_top = 0.08
	hero_message.anchor_bottom = 0.68
	hero_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.add_child(hero_message)
	
	var tools := VBoxContainer.new()
	tools.anchor_left = 0.80
	tools.anchor_right = 1.0
	tools.anchor_top = 0.16
	tools.anchor_bottom = 0.64
	tools.alignment = BoxContainer.ALIGNMENT_CENTER
	tools.add_theme_constant_override("separation", 58)
	stage.add_child(tools)
	var ad := _icon_button("res://docs/assets/ui/ad-simple.png")
	ad.pressed.connect(func(): _set_result("Rewarded ads are enabled in Android builds."))
	tools.add_child(ad)
	var settings := _icon_button("res://docs/assets/ui/settings-gear-simple.png")
	settings.pressed.connect(_open_settings)
	tools.add_child(settings)
	var discord := _icon_button("res://docs/assets/ui/discord-simple.png")
	discord.pressed.connect(func(): _set_result("Discord button tapped."))
	tools.add_child(discord)


func _build_skills_page() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 0)
	margin.add_theme_constant_override("margin_right", 0)
	margin.add_theme_constant_override("margin_top", 96)
	margin.add_theme_constant_override("margin_bottom", 72)
	skills_page.add_child(margin)
	
	skills_content = Control.new()
	skills_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_child(skills_content)


func _build_nav_bar() -> void:
	nav_bar = PanelContainer.new()
	nav_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	nav_bar.offset_top = -BOTTOM_NAV_HEIGHT
	nav_bar.clip_contents = true
	nav_bar.add_theme_stylebox_override("panel", _nav_style())
	add_child(nav_bar)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 160)
	row.clip_contents = true
	row.custom_minimum_size = Vector2(0, BOTTOM_NAV_HEIGHT - BOTTOM_NAV_SAFE_PAD)
	nav_bar.add_child(row)
	skills_tab = _nav_button("res://docs/assets/ui/total-lv-bargraph.png")
	skills_tab.pressed.connect(_show_skills)
	row.add_child(skills_tab)
	hero_tab = _nav_button("res://docs/assets/ui/motivation-star.png")
	hero_tab.pressed.connect(_show_home)
	row.add_child(hero_tab)
	settings_tab = _nav_button("res://docs/assets/ui/settings-gear-simple.png")
	settings_tab.pressed.connect(_show_settings)
	row.add_child(settings_tab)


func _build_settings_overlay() -> void:
	settings_overlay = ColorRect.new()
	settings_overlay.color = Color(0, 0, 0, 0.34)
	settings_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_overlay.z_index = MODAL_OVERLAY_Z
	settings_overlay.z_as_relative = false
	settings_overlay.visible = false
	settings_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	settings_overlay.add_to_group("modal_overlay")
	add_child(settings_overlay)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1300, 0)
	panel.add_theme_stylebox_override("panel", _panel_style(COLOR_PANEL, 16, CARD_RADIUS))
	center.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 46)
	panel.add_child(stack)
	stack.add_child(_label("Settings", 124, COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER))
	mute_button = _menu_button("")
	mute_button.pressed.connect(_toggle_mute)
	stack.add_child(mute_button)
	var ad := _menu_button("Ad")
	ad.pressed.connect(_settings_ad_pressed)
	stack.add_child(ad)
	var discord := _menu_button("Discord")
	discord.pressed.connect(_settings_discord_pressed)
	stack.add_child(discord)
	var reset := _menu_button("Reset Data")
	reset.add_theme_stylebox_override("normal", _panel_style(Color("#ffe2e2"), 12, 48))
	reset.pressed.connect(_reset_data)
	stack.add_child(reset)
	var close := _menu_button("Close")
	close.pressed.connect(_close_settings)
	stack.add_child(close)


func _build_achievements_overlay() -> void:
	achievements_overlay = ColorRect.new()
	achievements_overlay.color = Color(0, 0, 0, 0.42)
	achievements_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	achievements_overlay.z_index = MODAL_OVERLAY_Z
	achievements_overlay.z_as_relative = false
	achievements_overlay.visible = false
	achievements_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	achievements_overlay.add_to_group("modal_overlay")
	add_child(achievements_overlay)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	achievements_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = ACHIEVEMENTS_MODAL_SIZE
	panel.add_theme_stylebox_override("panel", _panel_style(COLOR_PANEL, 16, CARD_RADIUS))
	center.add_child(panel)
	achievements_panel = panel
	var outer := MarginContainer.new()
	outer.add_theme_constant_override("margin_left", 54)
	outer.add_theme_constant_override("margin_right", 54)
	outer.add_theme_constant_override("margin_top", 46)
	outer.add_theme_constant_override("margin_bottom", 46)
	panel.add_child(outer)
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 28)
	outer.add_child(stack)

	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 24)
	stack.add_child(header)
	var title := _label("Achievements", 112, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := _menu_button("Close")
	close.custom_minimum_size = Vector2(340, 160)
	close.pressed.connect(_close_achievements_overlay)
	header.add_child(close)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 24)
	stack.add_child(tabs)
	achievements_tab_buttons.clear()
	var achievements_tab := _menu_button("Achievements")
	achievements_tab.pressed.connect(_set_achievements_modal_tab.bind("achievements"))
	tabs.add_child(achievements_tab)
	achievements_tab_buttons["achievements"] = achievements_tab
	var buffs_tab := _menu_button("Global Buffs")
	buffs_tab.pressed.connect(_set_achievements_modal_tab.bind("buffs"))
	tabs.add_child(buffs_tab)
	achievements_tab_buttons["buffs"] = buffs_tab

	achievements_hide_completed = CheckBox.new()
	achievements_hide_completed.text = "Hide completed achievements"
	achievements_hide_completed.button_pressed = false
	achievements_hide_completed.add_theme_font_size_override("font_size", 52)
	achievements_hide_completed.add_theme_color_override("font_color", COLOR_INK)
	achievements_hide_completed.add_theme_color_override("font_hover_color", COLOR_INK)
	achievements_hide_completed.add_theme_color_override("font_hover_pressed_color", COLOR_INK)
	achievements_hide_completed.add_theme_color_override("font_pressed_color", COLOR_INK)
	achievements_hide_completed.add_theme_color_override("font_focus_color", COLOR_INK)
	achievements_hide_completed.add_theme_color_override("font_disabled_color", COLOR_INK)
	if app_bold_font != null:
		achievements_hide_completed.add_theme_font_override("font", app_bold_font)
	elif app_font != null:
		achievements_hide_completed.add_theme_font_override("font", app_font)
	achievements_hide_completed.toggled.connect(func(_pressed: bool): _rebuild_achievements_overlay())
	stack.add_child(achievements_hide_completed)

	var scroll := MobileScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, ACHIEVEMENTS_MODAL_SCROLL_HEIGHT)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	stack.add_child(scroll)
	achievements_scroll = scroll
	achievements_list_stack = VBoxContainer.new()
	achievements_list_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	achievements_list_stack.add_theme_constant_override("separation", 24)
	scroll.add_child(achievements_list_stack)


func _render_screen(scroll_latest_activity := false, restore_detail_scroll := -1) -> void:
	if skills_content == null:
		return
	_kill_skill_swipe_tween()
	skills_content.position = Vector2.ZERO
	if skill_swipe_page != null and is_instance_valid(skill_swipe_page):
		skill_swipe_page.position = Vector2.ZERO
	if skill_swipe_preview_page != null and is_instance_valid(skill_swipe_preview_page):
		skill_swipe_preview_page.position = Vector2.ZERO
	skill_swipe_frame = null
	skill_swipe_page = null
	skill_swipe_preview_page = null
	skill_swipe_preview_offset = 0
	skill_swipe_animating = false
	_clear(skills_content)
	skill_cards.clear()
	_clear_action_pop_tweens()
	action_cards.clear()
	
	if current_screen == "skill":
		_render_skill_detail(scroll_latest_activity, restore_detail_scroll)
	elif current_screen == "settings":
		_render_settings_page()
	else:
		content_scroll = MobileScrollContainer.new()
		content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		content_scroll.set_pull_resistance_enabled(true)
		_add_centered_skill_column(content_scroll)
		var stack := VBoxContainer.new()
		stack.custom_minimum_size.x = _skill_content_width()
		stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stack.add_theme_constant_override("separation", 52)
		content_scroll.add_child(stack)
		_render_skill_menu(stack)
	_update_page_visibility()


func _skill_content_width() -> float:
	return BASE_CANVAS.x - PAGE_PAD * 2.0


func _add_centered_skill_column(control: Control) -> void:
	var content_width := _skill_content_width()
	control.anchor_left = 0.5
	control.anchor_right = 0.5
	control.anchor_top = 0.0
	control.anchor_bottom = 1.0
	control.offset_left = -content_width * 0.5
	control.offset_right = content_width * 0.5
	control.offset_top = 0.0
	control.offset_bottom = 0.0
	control.custom_minimum_size.x = content_width
	skills_content.add_child(control)


func _render_settings_page() -> void:
	content_scroll = MobileScrollContainer.new()
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_add_centered_skill_column(content_scroll)
	var stack := VBoxContainer.new()
	stack.custom_minimum_size.x = _skill_content_width()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 36)
	content_scroll.add_child(stack)
	var top_spacer := Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 106)
	stack.add_child(top_spacer)
	stack.add_child(_label("Settings", 132, COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER))
	mute_button = _settings_page_button("", "", 940, 128, 236)
	mute_button.pressed.connect(_toggle_mute)
	stack.add_child(mute_button)
	var ad := _settings_page_button("Ad for +10% XP", "res://docs/assets/ui/ad-reward.png", 1320, 318, 370)
	ad.add_theme_stylebox_override("normal", _panel_style(Color("#fff5c7"), 14, 54))
	ad.add_theme_stylebox_override("hover", _panel_style(COLOR_GOLD, 14, 54))
	ad.add_theme_stylebox_override("pressed", _panel_style(COLOR_GOLD.darkened(0.08), 14, 54))
	ad.pressed.connect(_settings_ad_pressed)
	stack.add_child(ad)
	var discord := _settings_page_button("Contact the dev", "res://docs/assets/ui/discord-simple.png", 1320, 220, 286)
	discord.add_theme_stylebox_override("normal", _panel_style(Color("#eaf6ff"), 14, 54))
	discord.add_theme_stylebox_override("hover", _panel_style(Color("#d9efff"), 14, 54))
	discord.add_theme_stylebox_override("pressed", _panel_style(Color("#c3e4ff"), 14, 54))
	discord.pressed.connect(_settings_discord_pressed)
	stack.add_child(discord)
	var reset := _settings_page_button("Hard Reset", "", 940, 128, 236)
	reset.add_theme_stylebox_override("normal", _panel_style(Color("#ffb8b8"), 14, 48))
	reset.add_theme_stylebox_override("hover", _panel_style(Color("#ff9f9f"), 14, 48))
	reset.add_theme_stylebox_override("pressed", _panel_style(Color("#ff8080"), 14, 48))
	reset.pressed.connect(_reset_data)
	stack.add_child(reset)
	var bottom_spacer := Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 220)
	stack.add_child(bottom_spacer)


func _render_skill_menu(stack: VBoxContainer) -> void:
	var total_level_header := MarginContainer.new()
	total_level_header.add_theme_constant_override("margin_top", 42)
	total_level_header.add_theme_constant_override("margin_bottom", 12)
	stack.add_child(total_level_header)
	var total_row := HBoxContainer.new()
	total_row.alignment = BoxContainer.ALIGNMENT_CENTER
	total_row.add_theme_constant_override("separation", 22)
	total_level_header.add_child(total_row)
	var total_icon := _image("res://docs/assets/ui/total-lv-bargraph.png", Vector2(118, 118))
	total_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	total_row.add_child(total_icon)
	total_row.add_child(_label("Total Lv %s" % _global_level(), 154, COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER))
	for def in skill_defs:
		var skill_id := str(def["id"])
		var theme_color := _skill_theme_color(skill_id)
		var card_slot := Control.new()
		card_slot.custom_minimum_size = Vector2(0, 480)
		card_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stack.add_child(card_slot)

		var button := Button.new()
		button.text = ""
		button.anchor_left = 0.0
		button.anchor_right = 1.0
		button.anchor_top = 0.0
		button.anchor_bottom = 1.0
		button.offset_left = SKILL_MENU_CARD_SIDE_INSET
		button.offset_right = -SKILL_MENU_CARD_SIDE_INSET
		button.offset_top = 0.0
		button.offset_bottom = 0.0
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_stylebox_override("normal", _panel_style(COLOR_PANEL, 8, CARD_RADIUS))
		button.add_theme_stylebox_override("hover", _panel_style(COLOR_GOLD, 8, CARD_RADIUS))
		button.add_theme_stylebox_override("pressed", _panel_style(COLOR_GOLD.darkened(0.08), 8, CARD_RADIUS))
		button.pressed.connect(_select_skill.bind(skill_id))
		card_slot.add_child(button)
		
		var margin := MarginContainer.new()
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin.add_theme_constant_override("margin_left", 54)
		margin.add_theme_constant_override("margin_right", 54)
		margin.add_theme_constant_override("margin_top", 36)
		margin.add_theme_constant_override("margin_bottom", 36)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(margin)
		
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 44)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(row)
		row.add_child(_image("res://docs/assets/icons/%s.png" % skill_id, Vector2(258, 258)))
		var copy := VBoxContainer.new()
		copy.custom_minimum_size.x = SKILL_MENU_COPY_WIDTH
		copy.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		copy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		copy.add_theme_constant_override("separation", 28)
		copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(copy)
		var title := _label("", 102, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
		copy.add_child(title)
		var meta := _label("", 52, COLOR_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
		copy.add_child(meta)
		var xp_bar := _progress(theme_color, 46)
		xp_bar.custom_minimum_size.x = 580
		xp_bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		copy.add_child(xp_bar)
		var stamina_gauge := RegenCircle.new()
		stamina_gauge.custom_minimum_size = Vector2(366, 366)
		stamina_gauge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		stamina_gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stamina_gauge.set_theme_color(theme_color)
		row.add_child(stamina_gauge)
		skill_cards[skill_id] = {"title": title, "meta": meta, "xp": xp_bar, "stamina": stamina_gauge}


func _render_skill_detail(scroll_latest_activity := false, restore_detail_scroll := -1) -> void:
	var content_width := _skill_content_width()
	var frame := Control.new()
	skill_swipe_frame = frame
	_add_centered_skill_column(frame)

	var page := VBoxContainer.new()
	skill_swipe_page = page
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.custom_minimum_size.x = content_width
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 0)
	page.z_index = 20
	frame.add_child(page)

	var header := PanelContainer.new()
	header.custom_minimum_size = Vector2(0, 760)
	header.custom_minimum_size.x = content_width
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_stylebox_override("panel", _summary_style())
	page.add_child(header)
	var header_margin := MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 66)
	header_margin.add_theme_constant_override("margin_right", 46)
	header_margin.add_theme_constant_override("margin_top", 88)
	header_margin.add_theme_constant_override("margin_bottom", 74)
	header.add_child(header_margin)
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 66)
	header_margin.add_child(header_row)

	var left_block := HBoxContainer.new()
	left_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_block.alignment = BoxContainer.ALIGNMENT_CENTER
	left_block.add_theme_constant_override("separation", 58)
	header_row.add_child(left_block)
	var summary_icon_panel := PanelContainer.new()
	summary_icon_panel.custom_minimum_size = Vector2(344, 344)
	summary_icon_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	summary_icon_panel.add_theme_stylebox_override("panel", _summary_icon_style())
	summary_icon_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_block.add_child(summary_icon_panel)
	summary_icon_panel.add_child(_image("res://docs/assets/icons/%s.png" % selected_skill_id, Vector2(304, 304)))
	var title_stack := VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	title_stack.add_theme_constant_override("separation", 22)
	left_block.add_child(title_stack)
	var title := _label(_skill_name(selected_skill_id), 132, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	title_stack.add_child(title)
	var xp := _xp_progress(selected_skill_id)
	detail_xp_label = _label("", 66, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	title_stack.add_child(detail_xp_label)
	detail_xp_bar = _progress(_skill_theme_color(selected_skill_id), 78, float(xp["pct"]))
	title_stack.add_child(detail_xp_bar)

	detail_regen_circle = RegenCircle.new()
	detail_regen_circle.custom_minimum_size = Vector2(552, 552)
	detail_regen_circle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	detail_regen_circle.mouse_filter = Control.MOUSE_FILTER_STOP
	detail_regen_circle.gui_input.connect(_on_stamina_gauge_input)
	header_row.add_child(detail_regen_circle)
	detail_stamina_bar = null

	var divider := ColorRect.new()
	divider.color = COLOR_INK
	divider.custom_minimum_size = Vector2(0, 24)
	divider.custom_minimum_size.x = content_width
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_child(divider)

	var actions_scroll := MobileScrollContainer.new()
	detail_actions_scroll = actions_scroll
	detail_action_card_nodes.clear()
	detail_rendered_action_ids.clear()
	actions_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	actions_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	actions_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	page.add_child(actions_scroll)
	var stack := VBoxContainer.new()
	stack.custom_minimum_size.x = content_width
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 56)
	actions_scroll.add_child(stack)
	var scroll_top_spacer := Control.new()
	scroll_top_spacer.custom_minimum_size = Vector2(0, 12)
	stack.add_child(scroll_top_spacer)
	
	for action in _visible_actions_for_skill(selected_skill_id):
		var action_id := str(action["id"])
		detail_rendered_action_ids.append(action_id)
		var card_root := Control.new()
		card_root.custom_minimum_size = Vector2(0, ACTION_CARD_HEIGHT)
		card_root.custom_minimum_size.x = content_width
		card_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_root.clip_contents = false
		stack.add_child(card_root)
		detail_action_card_nodes[action_id] = card_root

		var pop_card := Control.new()
		pop_card.anchor_left = 0.0
		pop_card.anchor_right = 1.0
		pop_card.anchor_top = 0.0
		pop_card.anchor_bottom = 1.0
		pop_card.offset_left = ACTION_CARD_POP_GUTTER
		pop_card.offset_right = -ACTION_CARD_POP_GUTTER
		pop_card.offset_top = 0.0
		pop_card.offset_bottom = 0.0
		pop_card.clip_contents = false
		card_root.add_child(pop_card)
		
		var bg := RoundedTextureRect.new()
		bg.texture = _texture(str(action["bg"]))
		bg.modulate = Color.WHITE
		bg.radius = 66.0
		bg.crop_left = 0.025 if selected_skill_id == "fishing" else 0.0
		bg.crop_right = 0.015 if selected_skill_id == "fishing" else 0.0
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.z_index = 150
		pop_card.add_child(bg)
		
		var shade := Panel.new()
		shade.add_theme_stylebox_override("panel", _activity_shade_style(0.58))
		shade.set_anchors_preset(Control.PRESET_FULL_RECT)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shade.z_index = 151
		pop_card.add_child(shade)
		
		var margin := MarginContainer.new()
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin.add_theme_constant_override("margin_left", 54)
		margin.add_theme_constant_override("margin_right", 54)
		margin.add_theme_constant_override("margin_top", 46)
		margin.add_theme_constant_override("margin_bottom", 126)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.z_index = 200
		pop_card.add_child(margin)
		
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 56)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(row)

		var art_slot := MarginContainer.new()
		art_slot.add_theme_constant_override("margin_top", 42)
		art_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(art_slot)
		var art_panel := Panel.new()
		art_panel.custom_minimum_size = Vector2(410, 410)
		art_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		art_panel.add_theme_stylebox_override("panel", _action_art_style())
		art_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art_slot.add_child(art_panel)
		var art := _image(str(action["art"]), Vector2(356, 356))
		art.position = Vector2(27, 27)
		art_panel.add_child(art)

		var copy := VBoxContainer.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		copy.add_theme_constant_override("separation", 38)
		copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(copy)
		var name := _label(str(action["name"]), 82, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		name.add_theme_color_override("font_outline_color", COLOR_INK)
		name.add_theme_constant_override("outline_size", 34)
		name.autowrap_mode = TextServer.AUTOWRAP_OFF
		name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		copy.add_child(name)

		var stat_row := HBoxContainer.new()
		stat_row.add_theme_constant_override("separation", 28)
		stat_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		copy.add_child(stat_row)
		var xp_label := _action_stat_label("")
		stat_row.add_child(_action_stat_box(xp_label))
		var stamina_label := _action_stat_label("")
		stat_row.add_child(_action_stat_box(stamina_label))
		var time_label := _action_stat_label("")
		stat_row.add_child(_action_stat_box(time_label))
		var success_label := _action_stat_label("")
		stat_row.add_child(_action_stat_box(success_label))

		var medal := TextureRect.new()
		medal.anchor_left = 0.0
		medal.anchor_right = 0.0
		medal.anchor_top = 0.0
		medal.anchor_bottom = 0.0
		medal.offset_left = 300
		medal.offset_right = 490
		medal.offset_top = -62
		medal.offset_bottom = 128
		medal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		medal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		medal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		medal.z_index = 21
		art_panel.add_child(medal)
		var mastery_progress := _progress(Color("#f4bf35"), 56)
		mastery_progress.z_index = 20
		copy.add_child(mastery_progress)

		var status := _label("", 42, COLOR_RED, HORIZONTAL_ALIGNMENT_LEFT)
		status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		var progress := ActivityProgressRail.new()
		progress.fill_color = _skill_theme_color(selected_skill_id)
		progress.anchor_left = 0.0
		progress.anchor_right = 1.0
		progress.anchor_top = 1.0
		progress.anchor_bottom = 1.0
		progress.offset_left = 0
		progress.offset_right = 0
		progress.offset_top = -126
		progress.offset_bottom = 0
		progress.z_index = 152
		progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pop_card.add_child(progress)

		var border := ActivityCardBorder.new()
		border.set_anchors_preset(Control.PRESET_FULL_RECT)
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		border.z_index = 220
		pop_card.add_child(border)

		var button := Button.new()
		button.text = ""
		button.modulate = Color(1, 1, 1, 0)
		button.focus_mode = Control.FOCUS_NONE
		button.flat = true
		button.set_anchors_preset(Control.PRESET_FULL_RECT)
		button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		button.z_index = 230
		button.pressed.connect(_start_action.bind(selected_skill_id, action_id))
		pop_card.add_child(button)
		action_cards[_action_key(selected_skill_id, action_id)] = {
			"root": card_root,
			"pop": pop_card,
			"button": button,
			"bg": bg,
			"shade": shade,
			"art_panel": art_panel,
			"xp": xp_label,
			"stamina": stamina_label,
			"time": time_label,
			"success": success_label,
			"status": status,
			"medal": medal,
			"mastery": mastery_progress,
			"progress": progress
		}

	var scroll_bottom_spacer := Control.new()
	scroll_bottom_spacer.custom_minimum_size = Vector2(0, 180)
	stack.add_child(scroll_bottom_spacer)
	if restore_detail_scroll >= 0:
		call_deferred("_restore_detail_actions_scroll", restore_detail_scroll)
	elif scroll_latest_activity:
		call_deferred("_scroll_to_latest_unlocked_activity", false)


func _update_page_visibility() -> void:
	home_page.visible = current_screen == "home"
	skills_page.visible = current_screen != "home"
	_apply_nav_style(hero_tab, current_screen == "home")
	_apply_nav_style(skills_tab, current_screen == "menu" or current_screen == "skill")
	_apply_nav_style(settings_tab, current_screen == "settings")


func _update_ui(delta: float, instant := false) -> void:
	if _skill_detail_needs_action_list_refresh():
		_render_screen(false, detail_actions_scroll.scroll_vertical if detail_actions_scroll != null else -1)
	if home_total_label != null:
		home_total_label.text = "Total Lv %s" % _global_level()
	for skill_id in home_skill_labels.keys():
		(home_skill_labels[skill_id] as Label).text = "%s Lvl %s" % [_skill_name(str(skill_id)), _skill_level(str(skill_id))]
	_update_achievements_ui(delta, instant)
	for skill_id in skill_cards.keys():
		var xp := _xp_progress(str(skill_id))
		var card: Dictionary = skill_cards[skill_id]
		(card["title"] as Label).text = "%s" % _skill_name(str(skill_id))
		(card["meta"] as Label).text = "Lv %s  XP %s / %s%s" % [
			_skill_level(str(skill_id)),
			int(xp["current"]),
			int(xp["needed"]),
			"  Training" if running_skill_id == str(skill_id) else ""
		]
		(card["xp"] as CleanProgressBar).fill_color = _skill_theme_color(str(skill_id))
		_set_bar(card["xp"], float(xp["pct"]), delta, instant)
		var stamina_gauge := card["stamina"] as RegenCircle
		if stamina_gauge != null:
			var circle_value := 1.0
			if _stamina(str(skill_id)) < _max_stamina():
				circle_value = float(stamina_bank.get(str(skill_id), 0.0)) / STAMINA_REGEN_SECONDS
			stamina_gauge.set_theme_color(_skill_theme_color(str(skill_id)))
			stamina_gauge.set_stamina(_stamina(str(skill_id)), _max_stamina(), instant)
			stamina_gauge.set_value(_regen_ring_ease(circle_value), instant)
	if current_screen == "skill":
		var detail_xp := _xp_progress(selected_skill_id)
		if detail_xp_label != null:
			detail_xp_label.text = "Lv %s - XP %s / %s" % [_skill_level(selected_skill_id), int(detail_xp["current"]), int(detail_xp["needed"])]
		if detail_xp_bar != null:
			detail_xp_bar.fill_color = _skill_theme_color(selected_skill_id)
			_set_bar(detail_xp_bar, float(detail_xp["pct"]), delta, instant)
		if detail_regen_circle != null:
			var circle_value := 1.0
			if _stamina(selected_skill_id) < _max_stamina():
				circle_value = float(stamina_bank.get(selected_skill_id, 0.0)) / STAMINA_REGEN_SECONDS
			detail_regen_circle.set_theme_color(_skill_theme_color(selected_skill_id))
			detail_regen_circle.set_stamina(_stamina(selected_skill_id), _max_stamina(), instant)
			detail_regen_circle.set_value(_regen_ring_ease(circle_value), instant)
	for key in action_cards.keys():
		var parts := str(key).split(":")
		var skill_id := parts[0]
		var action_id := parts[1]
		var action := _action_data(skill_id, action_id)
		var unlocked := _skill_level(skill_id) >= int(action.get("unlock", 1))
		var running := running_skill_id == skill_id and running_action_id == action_id
		var card: Dictionary = action_cards[key]
		(card["button"] as Button).disabled = not unlocked
		(card["button"] as Button).modulate = Color(1, 1, 1, 0)
		(card["bg"] as CanvasItem).modulate = Color.WHITE
		var shade := card["shade"] as Panel
		shade.visible = not unlocked
		shade.add_theme_stylebox_override("panel", _activity_shade_style(0.58))
		(card["art_panel"] as CanvasItem).modulate = Color.WHITE if unlocked else Color(1, 1, 1, 0.62)
		(card["xp"] as Label).text = "+%s\nXP" % _effective_xp(action)
		(card["stamina"] as Label).text = "%s\nSTAM" % _effective_stamina(action)
		(card["time"] as Label).text = "%ss\nTIME" % _format_seconds(_effective_seconds(skill_id, action))
		(card["success"] as Label).text = "%s%%\nRATE" % int(_success_chance(skill_id, action))
		var status := card["status"] as Label
		status.text = ""
		var medal := card["medal"] as TextureRect
		var mastery_level := _mastery_level(skill_id, action_id)
		medal.visible = mastery_level > 0
		medal.texture = _mastery_medal_texture(mastery_level) if mastery_level > 0 else null
		medal.modulate = Color.WHITE
		_set_bar(card["mastery"], _mastery_progress_pct(skill_id, action_id), delta, instant)
		(card["progress"] as ActivityProgressRail).fill_color = _skill_theme_color(skill_id)
		_set_bar(card["progress"], action_progress * 100.0 if running else 0.0, delta, instant)
	if mute_button != null:
		mute_button.text = "Unmute" if is_muted else "Mute"


func _update_achievements_ui(delta: float, instant: bool) -> void:
	if achievement_elite_label == null and achievement_total_bar == null and achievement_total_level_label == null:
		return
	var totals := _all_medal_counts()
	var total_earned := int(totals["earned"])
	var total_possible := int(totals["possible"])
	for def in skill_defs:
		var skill_id := str(def["id"])
		if achievement_skill_level_labels.has(skill_id):
			var level_label := achievement_skill_level_labels[skill_id] as Label
			level_label.text = "%s Lv %s" % [_skill_name(skill_id), _skill_level(skill_id)]
		_update_achievement_medal_slots(skill_id, actions_by_skill.get(skill_id, []))
	if achievement_elite_label != null:
		var elite_pct := 0.0 if total_possible <= 0 else float(total_earned) / float(total_possible) * 100.0
		achievement_elite_label.text = "%s%% Elite" % int(round(elite_pct))
	if achievement_total_level_label != null:
		achievement_total_level_label.text = "Total Lv %s" % _global_level()
	if achievement_buff_label != null:
		achievement_buff_label.text = _global_medal_buff_lines()
	if achievement_total_bar != null:
		var total_pct := 0.0 if total_possible <= 0 else float(total_earned) / float(total_possible) * 100.0
		_set_bar(achievement_total_bar, total_pct, delta, instant)
	_update_most_impressive_activity()


func _update_most_impressive_activity() -> void:
	if achievement_best_name_label == null:
		return
	var best := _most_impressive_activity()
	if best.is_empty():
		if achievement_best_art_frame != null:
			achievement_best_art_frame.visible = false
		if achievement_best_art != null:
			achievement_best_art.visible = false
		if achievement_best_medal != null:
			achievement_best_medal.visible = false
		achievement_best_name_label.text = "Earn a medal to feature an activity"
		return
	if achievement_best_art_frame != null:
		achievement_best_art_frame.visible = true
	if achievement_best_art != null:
		achievement_best_art.visible = true
		achievement_best_art.texture = _texture(str(best.get("art", "")))
	if achievement_best_medal != null:
		achievement_best_medal.visible = true
		achievement_best_medal.texture = _mastery_medal_texture(int(best.get("level", 1)))
	achievement_best_name_label.text = str(best.get("name", ""))


func _update_achievement_medal_slots(skill_id: String, actions: Array) -> void:
	var panel_rows: Array = achievement_medal_slot_panels.get(skill_id, [])
	var icon_rows: Array = achievement_medal_slot_icons.get(skill_id, [])
	if icon_rows.is_empty():
		return
	var panels: Array = panel_rows[0] if not panel_rows.is_empty() else []
	var icons: Array = icon_rows[0]
	var skill_level := _skill_level(skill_id)
	for slot_index in range(mini(ACHIEVEMENT_MEDAL_SLOT_COUNT, icons.size())):
		var has_action := slot_index < actions.size()
		var accessible := false
		var mastery_level := 0
		if has_action:
			var action := actions[slot_index] as Dictionary
			accessible = skill_level >= int(action.get("unlock", 1))
			mastery_level = _mastery_level(skill_id, str(action["id"]))
		var icon := icons[slot_index] as TextureRect
		if icon != null:
			icon.material = null
			var shadow := panels[slot_index] as TextureRect if slot_index < panels.size() else null
			if mastery_level > 0:
				icon.texture = _mastery_medal_texture(mastery_level)
				if shadow != null:
					shadow.visible = false
			elif accessible:
				icon.texture = _mastery_medal_silhouette_texture(1, Color("#555555"))
				if shadow != null:
					shadow.visible = true
					shadow.texture = _mastery_medal_silhouette_texture(1, Color(0, 0, 0, 0.62))
			else:
				icon.texture = _mastery_medal_dot_texture()
				if shadow != null:
					shadow.visible = false
			icon.modulate = Color.WHITE


func _skill_medal_counts(skill_id: String) -> Dictionary:
	var actions: Array = actions_by_skill.get(skill_id, [])
	var tiers := []
	for _i in range(MASTERY_MAX_LEVEL):
		tiers.append(0)
	var cumulative := 0
	for action in actions:
		var level := _mastery_level(skill_id, str(action["id"]))
		cumulative += level
		for tier in range(1, MASTERY_MAX_LEVEL + 1):
			if level >= tier:
				tiers[tier - 1] = int(tiers[tier - 1]) + 1
	return {
		"actions": actions.size(),
		"earned": cumulative,
		"possible": actions.size() * MASTERY_MAX_LEVEL,
		"tiers": tiers
	}


func _all_medal_counts() -> Dictionary:
	var earned := 0
	var possible := 0
	for def in skill_defs:
		var counts := _skill_medal_counts(str(def["id"]))
		earned += int(counts["earned"])
		possible += int(counts["possible"])
	return {"earned": earned, "possible": possible}


func _all_medal_tier_counts() -> Array:
	var totals := []
	for _i in range(MASTERY_MAX_LEVEL):
		totals.append(0)
	for def in skill_defs:
		var counts := _skill_medal_counts(str(def["id"]))
		var tiers: Array = counts["tiers"]
		for i in range(mini(MASTERY_MAX_LEVEL, tiers.size())):
			totals[i] = int(totals[i]) + int(tiers[i])
	return totals


func _most_impressive_activity() -> Dictionary:
	var best := {}
	var best_score := -1.0
	var best_level := 0
	for def in skill_defs:
		var skill_id := str(def["id"])
		var actions: Array = actions_by_skill.get(skill_id, [])
		for action in actions:
			var action_id := str(action.get("id", ""))
			var level := _mastery_level(skill_id, action_id)
			if level <= 0:
				continue
			var seconds_required := float(action.get("seconds", 1.0)) * float(_mastery_xp_for_level(level))
			if seconds_required > best_score or (is_equal_approx(seconds_required, best_score) and level > best_level):
				best_score = seconds_required
				best_level = level
				best = {
					"skill_id": skill_id,
					"action_id": action_id,
					"name": str(action.get("name", "")),
					"art": str(action.get("art", "")),
					"level": level,
					"medal": str(MASTERY_MEDAL_NAMES[clampi(level, 1, MASTERY_MAX_LEVEL) - 1]),
					"seconds_required": seconds_required
				}
	return best


func _total_activity_count() -> int:
	var total := 0
	for def in skill_defs:
		total += int(actions_by_skill.get(str(def["id"]), []).size())
	return total


func _max_total_level() -> int:
	return skill_defs.size() * 99


func _skill_level_milestone_medal(target: int) -> int:
	match target:
		10:
			return 2
		25:
			return 5
		50:
			return 10
		75:
			return 15
		99:
			return 20
	return clampi(int(ceil(float(target) / 99.0 * float(ACHIEVEMENT_MEDAL_ART_COUNT))), 1, ACHIEVEMENT_MEDAL_ART_COUNT)


func _total_level_milestone_medal(target: int, max_total: int) -> int:
	if max_total <= 0:
		return 1
	var scaled := int(ceil(float(target) / float(max_total) * float(MASTERY_MAX_LEVEL)))
	return clampi(scaled, 1, MASTERY_MAX_LEVEL)


func _achievement_milestones() -> Array:
	var milestones := []
	var total_counts := _all_medal_counts()
	var cumulative := int(total_counts["earned"])
	var cumulative_possible := int(total_counts["possible"])
	var tier_counts := _all_medal_tier_counts()
	var activity_count := _total_activity_count()
	var total_level := _global_level()
	var max_total_level := _max_total_level()
	for def in skill_defs:
		var skill_id := str(def["id"])
		var skill_level := _skill_level(skill_id)
		var skill_name := _skill_name(skill_id)
		for target in _skill_level_achievement_targets():
			milestones.append({
				"id": "skill-level-%s-%s" % [skill_id, target],
				"chain_key": "skill-level-%s" % skill_id,
				"kind": "skill_level",
				"skill_id": skill_id,
				"title": "%s Level %s" % [skill_name, target],
				"subtitle": "%s Lv %s of %s" % [skill_name, mini(skill_level, int(target)), target],
				"reward": _skill_level_achievement_reward_text(skill_name, int(target)),
				"reward_stat": "skill_timer_reduction",
				"reward_skill_id": skill_id,
				"reward_amount": _skill_level_achievement_timer_reward(int(target)),
				"current": skill_level,
				"target": int(target),
				"completed": skill_level >= int(target),
				"medal_level": _skill_level_milestone_medal(int(target)),
				"accent": "#" + _skill_theme_color(skill_id).to_html(false)
			})
	for target in TOTAL_LEVEL_ACHIEVEMENT_TARGETS:
		if max_total_level < int(target) and total_level < int(target):
			continue
		milestones.append({
			"id": "total-level-%s" % target,
			"chain_key": "total-level",
			"kind": "total_level",
			"title": "Total Level %s" % target,
			"subtitle": "Total Lv %s of %s" % [mini(total_level, int(target)), target],
			"reward": _total_level_achievement_reward_text(int(target)),
			"reward_stat": "max_stamina",
			"reward_amount": _total_level_achievement_stamina_reward(int(target)),
			"current": total_level,
			"target": int(target),
			"completed": total_level >= int(target),
			"medal_level": _total_level_milestone_medal(int(target), max_total_level),
			"accent": "#f4bf35"
			})
	for def in skill_defs:
		var skill_id := str(def["id"])
		var skill_name := _skill_name(skill_id)
		var actions: Array = actions_by_skill.get(skill_id, [])
		for target in _medal_stamina_achievement_targets():
			for action in actions:
				var action_id := str(action.get("id", ""))
				var action_name := str(action.get("name", ""))
				var medal_level := _mastery_level(skill_id, action_id)
				var medal_name := str(MASTERY_MEDAL_NAMES[int(target) - 1])
				milestones.append({
					"id": "action-medal-%s-%s-%s" % [skill_id, action_id, target],
					"chain_key": "action-medal-%s" % skill_id,
					"kind": "action_medal",
					"skill_id": skill_id,
					"action_id": action_id,
					"art": str(action.get("art", "")),
					"title": "%s %s Medal" % [action_name, medal_name],
					"subtitle": "%s %s medal %s of %s" % [skill_name, medal_name, mini(medal_level, int(target)), target],
					"reward": "Reward: +1 max stamina",
					"reward_stat": "max_stamina",
					"reward_amount": 1,
					"current": medal_level,
					"target": int(target),
					"completed": medal_level >= int(target),
					"medal_level": int(target),
					"accent": "#" + _skill_theme_color(skill_id).to_html(false)
				})
	for tier in range(1, MASTERY_MAX_LEVEL + 1):
		var count := int(tier_counts[tier - 1])
		var tier_name := str(MASTERY_MEDAL_NAMES[tier - 1])
		var reward := "Reward: %s" % _global_medal_tier_bonus_text(tier)
		milestones.append({
			"id": "first-tier-%s" % tier,
			"chain_key": "tier-%s" % tier,
			"kind": "tier_count",
			"tier": tier,
			"title": "First %s Medal" % tier_name,
			"subtitle": "%s of 1 %s medals" % [mini(count, 1), tier_name],
			"reward": reward,
			"current": count,
			"target": 1,
			"completed": count >= 1,
			"medal_level": tier,
			"accent": "#f4bf35"
		})
		for target in [10, 25, 50, 100]:
			if activity_count < target and count < target:
				continue
			milestones.append({
				"id": "tier-%s-count-%s" % [tier, target],
				"chain_key": "tier-%s" % tier,
				"kind": "tier_count",
				"tier": tier,
				"title": "%s %s Medals" % [target, tier_name],
				"subtitle": "%s of %s %s medals" % [mini(count, target), target, tier_name],
				"reward": _tier_count_achievement_reward_text(tier_name, int(target)),
				"reward_stat": "max_stamina",
				"reward_amount": _tier_count_achievement_stamina_reward(int(target)),
				"current": count,
				"target": int(target),
				"completed": count >= target,
				"medal_level": tier,
				"accent": "#f4bf35"
			})
	for target in [10, 25, 50, 100, 250, 500, 1000]:
		if cumulative_possible < target and cumulative < target:
			continue
		milestones.append({
			"id": "cumulative-%s" % target,
			"chain_key": "cumulative-medals",
			"kind": "cumulative_medals",
			"title": "%s Cumulative Medals" % target,
			"subtitle": "%s of %s total medal tiers" % [mini(cumulative, target), target],
			"reward": _cumulative_medal_achievement_reward_text(int(target)),
			"reward_stat": "max_stamina",
			"reward_amount": _cumulative_medal_achievement_stamina_reward(int(target)),
			"current": cumulative,
			"target": int(target),
			"completed": cumulative >= target,
			"medal_level": 1,
			"accent": "#f4bf35"
		})
	return milestones


func _completed_achievement_ids() -> Dictionary:
	var completed := {}
	for achievement in _achievement_milestones():
		if bool(achievement.get("completed", false)):
			completed[str(achievement.get("id", ""))] = true
	return completed


func _newly_completed_achievements(before: Dictionary) -> Array:
	var unlocked := []
	for achievement in _achievement_milestones():
		var id := str(achievement.get("id", ""))
		if id.is_empty() or not bool(achievement.get("completed", false)):
			continue
		if not bool(before.get(id, false)):
			unlocked.append(achievement)
	return unlocked


func _visible_achievement_milestones(hide_completed: bool) -> Array:
	var chain_order := []
	var chains := {}
	for achievement in _achievement_milestones():
		var chain_key := str(achievement.get("chain_key", achievement.get("id", "")))
		if chain_key.is_empty():
			continue
		if not chains.has(chain_key):
			chains[chain_key] = []
			chain_order.append(chain_key)
		(chains[chain_key] as Array).append(achievement)
	var visible := []
	for chain_key in chain_order:
		var chain: Array = chains[chain_key]
		var next_achievement := {}
		for achievement in chain:
			if not bool(achievement.get("completed", false)):
				next_achievement = achievement
				break
		if next_achievement.is_empty():
			if hide_completed:
				continue
			next_achievement = chain[chain.size() - 1]
		visible.append(next_achievement)
	return visible


func _medal_stamina_achievement_targets() -> Array:
	var targets := []
	for level in range(2, MASTERY_MAX_LEVEL + 1, 2):
		targets.append(level)
	return targets


func _skill_level_achievement_targets() -> Array:
	var targets := []
	for level in range(2, 100):
		targets.append(level)
	return targets


func _skill_level_achievement_timer_reward(_target: int) -> float:
	return 0.01


func _skill_level_timer_reduction(skill_id: String) -> float:
	return maxf(0.0, float(_skill_level(skill_id) - 1) * _skill_level_achievement_timer_reward(2))


func _total_level_achievement_stamina_reward(target: int) -> int:
	if target >= 250:
		return 4
	if target >= 100:
		return 3
	if target >= 50:
		return 2
	return 1


func _tier_count_achievement_stamina_reward(target: int) -> int:
	if target >= 100:
		return 4
	if target >= 50:
		return 3
	if target >= 25:
		return 2
	return 1


func _cumulative_medal_achievement_stamina_reward(target: int) -> int:
	if target >= 500:
		return 5
	if target >= 100:
		return 3
	if target >= 25:
		return 2
	return 1


func _stamina_reward_text(amount: int) -> String:
	return "+%s max stamina" % maxi(1, amount)


func _skill_level_achievement_reward_text(skill_name: String, target: int) -> String:
	return "Reward: +%s%% %s activity timer reduction" % [
		int(round(_skill_level_achievement_timer_reward(target) * 100.0)),
		skill_name
	]


func _total_level_achievement_reward_text(target: int) -> String:
	return "Reward: %s" % _stamina_reward_text(_total_level_achievement_stamina_reward(target))


func _tier_count_achievement_reward_text(_tier_name: String, target: int) -> String:
	return "Reward: %s" % _stamina_reward_text(_tier_count_achievement_stamina_reward(target))


func _cumulative_medal_achievement_reward_text(target: int) -> String:
	return "Reward: %s" % _stamina_reward_text(_cumulative_medal_achievement_stamina_reward(target))


func _achievement_reward_bonus(stat: String, skill_id := "") -> float:
	var total := 0.0
	for achievement in _achievement_milestones():
		if not bool(achievement.get("completed", false)) or str(achievement.get("reward_stat", "")) != stat:
			continue
		var reward_skill_id := str(achievement.get("reward_skill_id", ""))
		if not skill_id.is_empty() and not reward_skill_id.is_empty() and reward_skill_id != skill_id:
			continue
		if skill_id.is_empty() and not reward_skill_id.is_empty():
			continue
		total += float(achievement.get("reward_amount", 0.0))
	return total


func _global_medal_buff_lines() -> String:
	var lines := _active_global_buff_lines()
	if lines.is_empty():
		return "Earn your first Bronze medal to unlock the first global buff."
	return "\n".join(lines)


func _active_global_buff_lines() -> Array:
	var lines := []
	var stamina_bonus := int(round(_global_medal_bonus("max_stamina")))
	var xp_bonus := int(round(_global_medal_bonus("xp_mult") * 100.0))
	var speed_bonus := int(round(_global_medal_bonus("speed_mult") * 100.0))
	var success_bonus := int(round(_global_medal_bonus("success_bonus")))
	if stamina_bonus > 0:
		lines.append("+%s max stamina" % stamina_bonus)
	if xp_bonus > 0:
		lines.append("+%s%% XP" % xp_bonus)
	if speed_bonus > 0:
		lines.append("+%s%% speed" % speed_bonus)
	if success_bonus > 0:
		lines.append("+%s%% success" % success_bonus)
	return lines


func _on_stamina_gauge_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_scroll_to_latest_unlocked_activity(true)
		get_viewport().set_input_as_handled()


func _visible_actions_for_skill(skill_id: String) -> Array:
	var visible_actions := []
	var showed_locked_preview := false
	var skill_level := _skill_level(skill_id)
	for action in actions_by_skill.get(skill_id, []):
		var unlocked := skill_level >= int(action.get("unlock", 1))
		if not unlocked:
			if showed_locked_preview:
				continue
			showed_locked_preview = true
		visible_actions.append(action)
	return visible_actions


func _skill_detail_needs_action_list_refresh() -> bool:
	if current_screen != "skill":
		return false
	var expected_action_ids := []
	for action in _visible_actions_for_skill(selected_skill_id):
		expected_action_ids.append(str(action["id"]))
	if expected_action_ids.size() != detail_rendered_action_ids.size():
		return true
	for i in range(expected_action_ids.size()):
		if str(expected_action_ids[i]) != str(detail_rendered_action_ids[i]):
			return true
	return false


func _latest_unlocked_action_id(skill_id: String) -> String:
	var latest_id := ""
	for action in actions_by_skill.get(skill_id, []):
		if _skill_level(skill_id) >= int(action.get("unlock", 1)):
			latest_id = str(action["id"])
	return latest_id


func _scroll_to_latest_unlocked_activity(animated := true) -> void:
	if current_screen != "skill" or detail_actions_scroll == null:
		return
	var action_id := _latest_unlocked_action_id(selected_skill_id)
	if action_id.is_empty() or not detail_action_card_nodes.has(action_id):
		return
	await get_tree().process_frame
	if detail_actions_scroll == null or not detail_action_card_nodes.has(action_id):
		return
	var card := detail_action_card_nodes[action_id] as Control
	if card == null:
		return
	var target := maxi(0, int(round(card.position.y - 18.0)))
	detail_actions_scroll.scroll_to_vertical(target, 0.24 if animated else 0.0)


func _restore_detail_actions_scroll(target: int) -> void:
	if current_screen != "skill" or detail_actions_scroll == null:
		return
	await get_tree().process_frame
	if detail_actions_scroll == null:
		return
	detail_actions_scroll.scroll_to_vertical(target, 0.0)


func _update_skill_swipe_feedback(position: Vector2) -> void:
	skill_swipe_last = position
	var delta := position - skill_swipe_start
	var abs_x := absf(delta.x)
	var abs_y := absf(delta.y)
	if not skill_swipe_horizontal:
		if abs_x < SKILL_SWIPE_FEEDBACK_DEADZONE:
			return
		if abs_x < abs_y * 1.25:
			return
		skill_swipe_horizontal = true
	var target := _skill_swipe_visual_target()
	if target == null:
		return
	var offset := 1 if delta.x < 0.0 else -1
	_ensure_skill_swipe_preview(offset)
	var direction := 1.0 if delta.x > 0.0 else -1.0
	var visual_distance := _skill_swipe_visual_distance(abs_x)
	_set_skill_swipe_positions(offset, direction * visual_distance)


func _skill_swipe_visual_target() -> Control:
	if skill_swipe_page != null and is_instance_valid(skill_swipe_page):
		return skill_swipe_page
	return null


func _skill_swipe_visual_distance(abs_x: float) -> float:
	var drag_distance := clampf(abs_x - SKILL_SWIPE_FEEDBACK_DEADZONE, 0.0, SKILL_SWIPE_MAX_DRAG)
	return minf(SKILL_SWIPE_MAX_DRAG, drag_distance * 0.92)


func _skill_swipe_page_span() -> float:
	return _skill_content_width() + SKILL_SWIPE_PAGE_GAP


func _set_skill_swipe_positions(offset: int, current_x: float) -> void:
	var target := _skill_swipe_visual_target()
	if target != null:
		target.position.x = current_x
	if skill_swipe_preview_page != null and is_instance_valid(skill_swipe_preview_page):
		skill_swipe_preview_page.position.x = current_x + signi(offset) * _skill_swipe_page_span()


func _kill_skill_swipe_tween() -> void:
	if skill_swipe_tween != null and skill_swipe_tween.is_valid():
		skill_swipe_tween.kill()
	skill_swipe_tween = null
	skill_swipe_animating = false


func _clear_skill_swipe_preview() -> void:
	if skill_swipe_preview_page != null and is_instance_valid(skill_swipe_preview_page):
		skill_swipe_preview_page.queue_free()
	skill_swipe_preview_page = null
	skill_swipe_preview_offset = 0


func _cancel_skill_swipe_feedback(animated := true) -> void:
	skill_swipe_tracking = false
	skill_swipe_horizontal = false
	var target := _skill_swipe_visual_target()
	if target == null:
		_clear_skill_swipe_preview()
		return
	_kill_skill_swipe_tween()
	if animated and absf(target.position.x) > 1.0:
		skill_swipe_animating = true
		skill_swipe_tween = create_tween()
		skill_swipe_tween.set_parallel(true)
		skill_swipe_tween.tween_property(target, "position:x", 0.0, SKILL_SWIPE_CANCEL_SECONDS).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
		if skill_swipe_preview_page != null and is_instance_valid(skill_swipe_preview_page):
			var preview_exit := signi(skill_swipe_preview_offset) * _skill_swipe_page_span()
			skill_swipe_tween.tween_property(skill_swipe_preview_page, "position:x", preview_exit, SKILL_SWIPE_CANCEL_SECONDS).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
		skill_swipe_tween.finished.connect(func():
			skill_swipe_animating = false
			_clear_skill_swipe_preview()
		)
	else:
		target.position.x = 0.0
		_clear_skill_swipe_preview()


func _finish_skill_swipe(end_position: Vector2) -> void:
	var delta: Vector2 = end_position - skill_swipe_start
	skill_swipe_tracking = false
	if absf(delta.x) < SKILL_SWIPE_THRESHOLD or absf(delta.x) < absf(delta.y) * 1.35:
		_cancel_skill_swipe_feedback(true)
		return
	_update_skill_swipe_feedback(end_position)
	_commit_skill_swipe(1 if delta.x < 0.0 else -1)


func _commit_skill_swipe(offset: int) -> void:
	skill_swipe_horizontal = false
	var target := _skill_swipe_visual_target()
	if target == null:
		_navigate_skill_page(offset)
		return
	_kill_skill_swipe_tween()
	var entry_x := target.position.x + signi(offset) * _skill_swipe_page_span()
	if skill_swipe_preview_page != null and is_instance_valid(skill_swipe_preview_page):
		entry_x = skill_swipe_preview_page.position.x
	_clear_skill_swipe_preview()
	_navigate_skill_page(offset, entry_x)


func _navigate_skill_page(offset: int, entry_x := 0.0) -> void:
	var current_index := _skill_index(selected_skill_id)
	if current_index < 0:
		return
	var skill_count := skill_defs.size()
	if skill_count <= 0:
		return
	var next_index := (current_index + offset) % skill_count
	if next_index < 0:
		next_index += skill_count
	var next_skill_id := str(skill_defs[next_index]["id"])
	selected_skill_id = next_skill_id
	current_screen = "skill"
	_play(click_player)
	_render_screen(true)
	_update_ui(0.0, true)
	var target := _skill_swipe_visual_target()
	if target != null:
		if absf(entry_x) > 1.0:
			target.position.x = entry_x
			_kill_skill_swipe_tween()
			skill_swipe_animating = true
			skill_swipe_tween = create_tween()
			skill_swipe_tween.tween_property(target, "position:x", 0.0, SKILL_SWIPE_SETTLE_SECONDS).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
			skill_swipe_tween.finished.connect(func(): skill_swipe_animating = false)
		else:
			_kill_skill_swipe_tween()
			target.position.x = 0.0


func _ensure_skill_swipe_preview(offset: int) -> void:
	if skill_swipe_frame == null or not is_instance_valid(skill_swipe_frame):
		return
	if skill_swipe_preview_page != null and is_instance_valid(skill_swipe_preview_page) and skill_swipe_preview_offset == offset:
		return
	_clear_skill_swipe_preview()
	var current_index := _skill_index(selected_skill_id)
	if current_index < 0 or skill_defs.is_empty():
		return
	var next_index := (current_index + offset) % skill_defs.size()
	if next_index < 0:
		next_index += skill_defs.size()
	var next_skill_id := str(skill_defs[next_index]["id"])
	skill_swipe_preview_page = _build_skill_swipe_preview_page(next_skill_id)
	skill_swipe_preview_offset = offset
	skill_swipe_preview_page.position.x = signi(offset) * _skill_swipe_page_span()
	skill_swipe_frame.add_child(skill_swipe_preview_page)


func _build_skill_swipe_preview_page(skill_id: String) -> Control:
	var content_width := _skill_content_width()
	var page := VBoxContainer.new()
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.custom_minimum_size.x = content_width
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 0)
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.z_index = 10

	var header := PanelContainer.new()
	header.custom_minimum_size = Vector2(0, 760)
	header.custom_minimum_size.x = content_width
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_stylebox_override("panel", _summary_style())
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(header)

	var header_margin := MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 66)
	header_margin.add_theme_constant_override("margin_right", 46)
	header_margin.add_theme_constant_override("margin_top", 88)
	header_margin.add_theme_constant_override("margin_bottom", 74)
	header_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(header_margin)

	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 66)
	header_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_margin.add_child(header_row)

	var left_block := HBoxContainer.new()
	left_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_block.alignment = BoxContainer.ALIGNMENT_CENTER
	left_block.add_theme_constant_override("separation", 58)
	left_block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_row.add_child(left_block)

	var summary_icon_panel := PanelContainer.new()
	summary_icon_panel.custom_minimum_size = Vector2(344, 344)
	summary_icon_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	summary_icon_panel.add_theme_stylebox_override("panel", _summary_icon_style())
	summary_icon_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_block.add_child(summary_icon_panel)
	summary_icon_panel.add_child(_image("res://docs/assets/icons/%s.png" % skill_id, Vector2(304, 304)))

	var title_stack := VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	title_stack.add_theme_constant_override("separation", 22)
	title_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_block.add_child(title_stack)
	title_stack.add_child(_label(_skill_name(skill_id), 132, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT))
	var xp := _xp_progress(skill_id)
	title_stack.add_child(_label("Lv %s - XP %s / %s" % [_skill_level(skill_id), int(xp["current"]), int(xp["needed"])], 66, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT))
	title_stack.add_child(_progress(_skill_theme_color(skill_id), 78, float(xp["pct"])))

	var regen_circle := RegenCircle.new()
	regen_circle.custom_minimum_size = Vector2(552, 552)
	regen_circle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	regen_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	regen_circle.set_theme_color(_skill_theme_color(skill_id))
	regen_circle.set_stamina(_stamina(skill_id), _max_stamina(), true)
	header_row.add_child(regen_circle)

	var divider := ColorRect.new()
	divider.color = COLOR_INK
	divider.custom_minimum_size = Vector2(0, 24)
	divider.custom_minimum_size.x = content_width
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(divider)

	var preview_stack := VBoxContainer.new()
	preview_stack.custom_minimum_size.x = content_width
	preview_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_stack.add_theme_constant_override("separation", 56)
	preview_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(preview_stack)

	var top_spacer := Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 12)
	top_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_stack.add_child(top_spacer)

	var shown := 0
	for action in _visible_actions_for_skill(skill_id):
		if shown >= 3:
			break
		preview_stack.add_child(_skill_swipe_preview_action_card(skill_id, action, content_width))
		shown += 1
	return page


func _skill_swipe_preview_action_card(skill_id: String, action: Dictionary, content_width: float) -> Control:
	var card_root := Control.new()
	card_root.custom_minimum_size = Vector2(content_width, ACTION_CARD_HEIGHT)
	card_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_root.clip_contents = false
	card_root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var pop_card := Control.new()
	pop_card.anchor_left = 0.0
	pop_card.anchor_right = 1.0
	pop_card.anchor_top = 0.0
	pop_card.anchor_bottom = 1.0
	pop_card.offset_left = ACTION_CARD_POP_GUTTER
	pop_card.offset_right = -ACTION_CARD_POP_GUTTER
	pop_card.offset_top = 0.0
	pop_card.offset_bottom = 0.0
	pop_card.clip_contents = false
	pop_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_root.add_child(pop_card)

	var bg := RoundedTextureRect.new()
	bg.texture = _texture(str(action["bg"]))
	bg.modulate = Color.WHITE
	bg.radius = 66.0
	bg.crop_left = 0.025 if skill_id == "fishing" else 0.0
	bg.crop_right = 0.015 if skill_id == "fishing" else 0.0
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.z_index = 150
	pop_card.add_child(bg)

	var shade := Panel.new()
	shade.add_theme_stylebox_override("panel", _activity_shade_style(0.58))
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.z_index = 151
	pop_card.add_child(shade)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 54)
	margin.add_theme_constant_override("margin_right", 54)
	margin.add_theme_constant_override("margin_top", 46)
	margin.add_theme_constant_override("margin_bottom", 126)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.z_index = 200
	pop_card.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 56)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)

	var art_slot := MarginContainer.new()
	art_slot.add_theme_constant_override("margin_top", 42)
	art_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(art_slot)
	var art_panel := Panel.new()
	art_panel.custom_minimum_size = Vector2(410, 410)
	art_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	art_panel.add_theme_stylebox_override("panel", _action_art_style())
	art_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_slot.add_child(art_panel)
	var art := _image(str(action["art"]), Vector2(356, 356))
	art.position = Vector2(27, 27)
	art_panel.add_child(art)

	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 38)
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(copy)

	var name := _label(str(action["name"]), 82, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	name.add_theme_color_override("font_outline_color", COLOR_INK)
	name.add_theme_constant_override("outline_size", 34)
	name.autowrap_mode = TextServer.AUTOWRAP_OFF
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	copy.add_child(name)

	var stat_row := HBoxContainer.new()
	stat_row.add_theme_constant_override("separation", 28)
	stat_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(stat_row)
	stat_row.add_child(_action_stat_box(_action_stat_label("%s\nXP" % _effective_xp(action))))
	stat_row.add_child(_action_stat_box(_action_stat_label("%s\nSTM" % _effective_stamina(action))))
	stat_row.add_child(_action_stat_box(_action_stat_label("%ss\nTIME" % _format_seconds(_effective_seconds(skill_id, action)))))
	stat_row.add_child(_action_stat_box(_action_stat_label("%s%%\nRATE" % int(_success_chance(skill_id, action)))))

	var progress := ActivityProgressRail.new()
	progress.fill_color = _skill_theme_color(skill_id)
	progress.anchor_left = 0.0
	progress.anchor_right = 1.0
	progress.anchor_top = 1.0
	progress.anchor_bottom = 1.0
	progress.offset_left = 0
	progress.offset_right = 0
	progress.offset_top = -126
	progress.offset_bottom = 0
	progress.z_index = 152
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pop_card.add_child(progress)

	var border := ActivityCardBorder.new()
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.z_index = 220
	pop_card.add_child(border)
	return card_root


func _skill_index(skill_id: String) -> int:
	for i in range(skill_defs.size()):
		if str(skill_defs[i]["id"]) == skill_id:
			return i
	return -1


func _process_action(delta: float) -> void:
	if running_skill_id.is_empty():
		return
	var action := _action_data(running_skill_id, running_action_id)
	if action.is_empty():
		running_skill_id = ""
		running_action_id = ""
		action_progress = 0.0
		return
	var cost := _effective_stamina(action)
	if _stamina(running_skill_id) < cost:
		last_result = "Out of stamina."
		running_skill_id = ""
		running_action_id = ""
		action_progress = 0.0
		_update_ui(0.0, false)
		return
	action_progress += delta / _effective_seconds(running_skill_id, action)
	if action_progress < 1.0:
		return
	action_progress = 0.0
	stamina[running_skill_id] = _stamina(running_skill_id) - cost
	var reward_key := _action_key(running_skill_id, running_action_id)
	var old_mastery_level := _mastery_level(running_skill_id, running_action_id)
	var mastery_reward := _mastery_xp_reward(action)
	var tiers_unlocked_before := {}
	for tier in range(1, MASTERY_MAX_LEVEL + 1):
		tiers_unlocked_before[tier] = _global_medal_tier_unlocked(tier)
	var completed_achievements_before := _completed_achievement_ids()
	var success := randf() * 100.0 <= _success_chance(running_skill_id, action)
	if success:
		var xp_reward := _effective_xp(action)
		skills[running_skill_id]["xp"] = int(skills[running_skill_id]["xp"]) + xp_reward
		_add_mastery_xp(running_skill_id, running_action_id, mastery_reward)
		var new_mastery_level := _mastery_level(running_skill_id, running_action_id)
		_recalculate_level(running_skill_id)
		last_result = "+%s XP from %s." % [xp_reward, action["name"]]
		var new_global_buffs := _new_global_medal_buff_messages(old_mastery_level, new_mastery_level, tiers_unlocked_before)
		if not new_global_buffs.is_empty():
			last_result += " " + " ".join(new_global_buffs)
		_play_action_feedback(reward_key, true, xp_reward, mastery_reward)
		for achievement in _newly_completed_achievements(completed_achievements_before):
			_show_achievement_unlocked(achievement)
		_play(medal_player if new_mastery_level > old_mastery_level else success_player)
	else:
		var failure_mastery_reward := 0.0 if _would_mastery_reward_medal_up(running_skill_id, running_action_id, mastery_reward) else mastery_reward
		if failure_mastery_reward > 0:
			_add_mastery_xp(running_skill_id, running_action_id, failure_mastery_reward)
		var failure_mastery_level := _mastery_level(running_skill_id, running_action_id)
		last_result = "Failed %s. +%s mastery." % [action["name"], failure_mastery_reward]
		if failure_mastery_reward <= 0:
			last_result += " Next medal needs a success."
		var failure_global_buffs := _new_global_medal_buff_messages(old_mastery_level, failure_mastery_level, tiers_unlocked_before)
		if not failure_global_buffs.is_empty():
			last_result += " " + " ".join(failure_global_buffs)
		_play_action_feedback(reward_key, false, 0, failure_mastery_reward)
		for achievement in _newly_completed_achievements(completed_achievements_before):
			_show_achievement_unlocked(achievement)
		_play(failure_player)
	if _stamina(running_skill_id) < cost:
		running_skill_id = ""
		running_action_id = ""
	_update_ui(0.0, false)


func _regen_stamina(delta: float) -> void:
	var max_stamina := _max_stamina()
	for def in skill_defs:
		var skill_id := str(def["id"])
		if _stamina(skill_id) >= max_stamina:
			stamina_bank[skill_id] = 0.0
			continue
		stamina_bank[skill_id] = float(stamina_bank.get(skill_id, 0.0)) + delta
		if float(stamina_bank[skill_id]) >= STAMINA_REGEN_SECONDS:
			var gained := int(floor(float(stamina_bank[skill_id]) / STAMINA_REGEN_SECONDS))
			stamina[skill_id] = mini(max_stamina, _stamina(skill_id) + gained)
			stamina_bank[skill_id] = fmod(float(stamina_bank[skill_id]), STAMINA_REGEN_SECONDS)


func _regen_ring_ease(raw_value: float) -> float:
	var t := clampf(raw_value, 0.0, 1.0)
	if t <= 0.0 or t >= 1.0:
		return t
	if t < 0.9:
		var u := t / 0.9
		return 0.9 * pow(u, 1.7)
	var finish := (t - 0.9) / 0.1
	return 0.9 + 0.1 * (1.0 - pow(1.0 - finish, 2.4))


func _start_action(skill_id: String, action_id: String) -> void:
	var action := _action_data(skill_id, action_id)
	if action.is_empty() or _skill_level(skill_id) < int(action["unlock"]):
		return
	if running_skill_id == skill_id and running_action_id == action_id:
		running_skill_id = ""
		running_action_id = ""
		action_progress = 0.0
		_set_result("%s stopped." % action["name"])
		_update_ui(0.0, false)
		return
	if _stamina(skill_id) < _effective_stamina(action):
		_set_result("Not enough stamina.")
		_play(failure_player)
		return
	selected_skill_id = skill_id
	running_skill_id = skill_id
	running_action_id = action_id
	action_progress = 0.0
	_pop_activity_button(_action_key(skill_id, action_id))
	_set_result("%s started." % action["name"])


func _pop_activity_button(action_key: String) -> void:
	if not action_cards.has(action_key):
		return
	var card := action_cards[action_key].get("pop") as Control
	if card == null:
		return
	if action_pop_tweens.has(action_key):
		var existing := action_pop_tweens[action_key] as Tween
		if existing != null and existing.is_valid():
			existing.kill()
	card.scale = Vector2.ONE
	card.pivot_offset = card.size * 0.5
	var tween := create_tween()
	action_pop_tweens[action_key] = tween
	tween.tween_property(card, "scale", Vector2(1.035, 1.035), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "scale", Vector2(0.985, 0.985), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(card, "scale", Vector2.ONE, 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func(): action_pop_tweens.erase(action_key))


func _clear_action_pop_tweens() -> void:
	for tween in action_pop_tweens.values():
		if tween != null and (tween as Tween).is_valid():
			(tween as Tween).kill()
	action_pop_tweens.clear()


func _select_skill(skill_id: String) -> void:
	selected_skill_id = skill_id
	current_screen = "skill"
	_play(click_player)
	_render_screen(true)


func _show_home() -> void:
	current_screen = "home"
	_play(click_player)
	_render_screen()


func _show_skills() -> void:
	current_screen = "menu"
	_play(click_player)
	_render_screen()


func _show_settings() -> void:
	current_screen = "settings"
	_play(click_player)
	_render_screen()


func _back_to_skills() -> void:
	current_screen = "menu"
	_play(click_player)
	_render_screen()


func _open_settings() -> void:
	_show_settings()


func _close_settings() -> void:
	_show_home()


func _open_achievements_overlay() -> void:
	achievements_modal_tab = "achievements"
	if achievements_overlay != null:
		achievements_overlay.visible = true
	_rebuild_achievements_overlay()
	_play(click_player)


func _close_achievements_overlay() -> void:
	if achievements_overlay != null:
		achievements_overlay.visible = false
	_play(click_player)


func _set_achievements_modal_tab(tab: String) -> void:
	achievements_modal_tab = tab
	_rebuild_achievements_overlay()
	_play(click_player)


func _rebuild_achievements_overlay() -> void:
	if achievements_list_stack == null:
		return
	_clear(achievements_list_stack)
	var active_buffs := _active_global_buff_lines() if achievements_modal_tab == "buffs" else []
	_apply_achievements_modal_layout(active_buffs.size())
	for key in achievements_tab_buttons.keys():
		var button := achievements_tab_buttons[key] as Button
		if button != null:
			button.add_theme_stylebox_override("normal", _panel_style(COLOR_GOLD if str(key) == achievements_modal_tab else COLOR_PANEL, 12, 48))
	if achievements_hide_completed != null:
		achievements_hide_completed.visible = achievements_modal_tab == "achievements"
	if achievements_modal_tab == "buffs":
		_rebuild_global_buffs_tab(active_buffs)
	else:
		_rebuild_achievement_log_tab()


func _apply_achievements_modal_layout(buff_count: int) -> void:
	if achievements_panel == null or achievements_scroll == null:
		return
	if achievements_modal_tab != "buffs":
		achievements_panel.custom_minimum_size = ACHIEVEMENTS_MODAL_SIZE
		achievements_scroll.custom_minimum_size = Vector2(0, ACHIEVEMENTS_MODAL_SCROLL_HEIGHT)
		return
	var visible_rows := maxi(1, buff_count)
	var modal_height := clampf(
		GLOBAL_BUFFS_MODAL_BASE_HEIGHT + float(visible_rows) * GLOBAL_BUFFS_MODAL_ROW_HEIGHT,
		GLOBAL_BUFFS_MODAL_MIN_HEIGHT,
		GLOBAL_BUFFS_MODAL_MAX_HEIGHT
	)
	achievements_panel.custom_minimum_size = Vector2(ACHIEVEMENTS_MODAL_SIZE.x, modal_height)
	achievements_scroll.custom_minimum_size = Vector2(0, maxf(520.0, modal_height - GLOBAL_BUFFS_MODAL_SCROLL_CHROME))


func _rebuild_achievement_log_tab() -> void:
	var hide_completed := achievements_hide_completed != null and achievements_hide_completed.button_pressed
	var any_visible := false
	for achievement in _visible_achievement_milestones(hide_completed):
		var completed := bool(achievement["completed"])
		any_visible = true
		achievements_list_stack.add_child(_achievement_log_card(achievement))
	if not any_visible:
		achievements_list_stack.add_child(_label("Everything visible here is complete.", 64, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER))


func _rebuild_global_buffs_tab(buffs: Array) -> void:
	if buffs.is_empty():
		achievements_list_stack.add_child(_label("No global buffs earned yet.", 64, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER))
		return
	achievements_list_stack.add_child(_label("Active Global Buffs", 70, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT))
	achievements_list_stack.add_child(_label("All earned medal bonuses combined.", 44, COLOR_MUTED, HORIZONTAL_ALIGNMENT_LEFT))
	for buff_text in buffs:
		achievements_list_stack.add_child(_global_buff_list_row(str(buff_text)))


func _global_buff_list_row(text: String) -> Control:
	var row := MarginContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("margin_left", 10)
	row.add_theme_constant_override("margin_right", 10)
	row.add_theme_constant_override("margin_top", 2)
	row.add_theme_constant_override("margin_bottom", 2)
	var label := _label("- %s" % text, 52, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(label)
	return row


func _achievement_art(achievement: Dictionary) -> Control:
	var art := Control.new()
	art.custom_minimum_size = Vector2(178, 144)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	match str(achievement.get("kind", "")):
		"skill_level":
			var skill_id := str(achievement.get("skill_id", ""))
			_add_achievement_art_image(art, _texture(_skill_icon_path(skill_id)), Vector2(17, 0), Vector2(144, 144), 1)
		"action_medal":
			_add_achievement_art_image(art, _texture(str(achievement.get("art", ""))), Vector2(0, 6), Vector2(132, 132), 1)
			_add_achievement_art_image(art, _achievement_medal_texture(int(achievement.get("medal_level", 1))), Vector2(96, 58), Vector2(86, 86), 2)
		"total_level":
			_add_achievement_art_image(art, _texture(ACHIEVEMENT_TOTAL_LEVEL_ART), Vector2(16, 0), Vector2(144, 144), 1)
		"tier_count":
			var tier := int(achievement.get("tier", achievement.get("medal_level", 1)))
			_add_achievement_art_image(art, _achievement_medal_texture(tier), Vector2(17, 0), Vector2(144, 144), 1)
		"cumulative_medals":
			_add_achievement_art_image(art, _texture(ACHIEVEMENT_CUMULATIVE_MEDALS_ART), Vector2(17, 0), Vector2(144, 144), 1)
		_:
			_add_achievement_art_image(art, _texture(ACHIEVEMENT_CREDIT_ART), Vector2(12, 0), Vector2(154, 144), 1)
	return art


func _add_achievement_art_image(parent: Control, texture: Texture2D, position: Vector2, size: Vector2, z_index: int) -> void:
	var image := _image_from_texture(texture, size)
	image.position = position
	image.size = size
	image.z_index = z_index
	parent.add_child(image)


func _skill_icon_path(skill_id: String) -> String:
	return "res://docs/assets/icons/%s.png" % skill_id


func _same_tier_achievement_medal_count(target: int) -> int:
	if target <= 1:
		return 1
	if target <= 10:
		return 3
	if target <= 25:
		return 5
	if target <= 50:
		return 7
	return 9


func _cumulative_achievement_medal_levels(target: int) -> Array:
	var count := 3
	if target >= 1000:
		count = 10
	elif target >= 500:
		count = 8
	elif target >= 250:
		count = 7
	elif target >= 100:
		count = 6
	elif target >= 50:
		count = 5
	elif target >= 25:
		count = 4
	var levels := []
	for i in range(count):
		levels.append((i % MASTERY_MAX_LEVEL) + 1)
	return levels


func _populate_achievement_medal_cluster(parent: Control, levels: Array) -> void:
	var count := levels.size()
	var positions := _achievement_medal_cluster_positions(count)
	var medal_size := 144.0
	if count >= 9:
		medal_size = 64.0
	elif count >= 7:
		medal_size = 72.0
	elif count >= 5:
		medal_size = 82.0
	elif count >= 3:
		medal_size = 92.0
	for i in range(count):
		var center: Vector2 = positions[i] if i < positions.size() else Vector2(89, 72)
		var icon_size := Vector2(medal_size, medal_size)
		_add_achievement_art_image(parent, _achievement_medal_texture(int(levels[i])), center - icon_size * 0.5, icon_size, i + 1)


func _achievement_medal_cluster_positions(count: int) -> Array:
	if count <= 1:
		return [Vector2(89, 72)]
	if count <= 3:
		return [Vector2(56, 84), Vector2(89, 50), Vector2(122, 84)]
	if count <= 5:
		return [Vector2(45, 86), Vector2(72, 52), Vector2(106, 52), Vector2(133, 86), Vector2(89, 104)]
	if count <= 7:
		return [Vector2(42, 86), Vector2(64, 54), Vector2(92, 43), Vector2(120, 54), Vector2(142, 86), Vector2(73, 110), Vector2(111, 110)]
	if count <= 8:
		return [Vector2(36, 88), Vector2(58, 56), Vector2(84, 42), Vector2(112, 42), Vector2(138, 56), Vector2(158, 88), Vector2(72, 112), Vector2(116, 112)]
	return [Vector2(30, 88), Vector2(50, 60), Vector2(72, 42), Vector2(98, 38), Vector2(124, 42), Vector2(146, 60), Vector2(164, 88), Vector2(65, 112), Vector2(98, 118), Vector2(131, 112)]


func _achievement_progress_pct(achievement: Dictionary) -> float:
	var target := maxi(1, int(achievement.get("target", 1)))
	var current := clampi(int(achievement.get("current", 0)), 0, target)
	return clampf(float(current) / float(target) * 100.0, 0.0, 100.0)


func _achievement_log_card(achievement: Dictionary) -> Control:
	var completed := bool(achievement.get("completed", false))
	var accent := Color(str(achievement.get("accent", "#f4bf35")))
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _achievement_card_style(Color("#fffdf8") if completed else Color("#fff6e1"), 34, 28))
	card.modulate = Color.WHITE if completed else Color(1, 1, 1, 0.78)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 18)
	card.add_child(stack)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	stack.add_child(row)
	row.add_child(_achievement_art(achievement))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 8)
	row.add_child(copy)
	var title_label := _label(str(achievement.get("title", "")), 54, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(title_label)
	var subtitle_label := _label(str(achievement.get("subtitle", "")), 44, accent if completed else COLOR_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(subtitle_label)
	var reward_label := _label(str(achievement.get("reward", "")), 40, COLOR_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(reward_label)
	stack.add_child(_progress(accent, 28, _achievement_progress_pct(achievement)))
	return card


func _toggle_mute() -> void:
	is_muted = not is_muted
	AudioServer.set_bus_mute(0, is_muted)
	_update_ui(0.0, true)


func _settings_ad_pressed() -> void:
	_set_result("Rewarded ads are enabled in Android builds.")
	_play(click_player)


func _settings_discord_pressed() -> void:
	_set_result("Discord button tapped.")
	_play(click_player)


func _reset_data() -> void:
	_init_state()
	running_skill_id = ""
	running_action_id = ""
	action_progress = 0.0
	current_screen = "home"
	last_result = "Progress reset."
	save_game()
	_render_screen()
	_update_ui(0.0, true)


func _set_result(text: String) -> void:
	last_result = text
	if hero_message != null:
		hero_message.text = text.to_upper()
	_play(click_player)


func _play_action_feedback(key: String, success: bool, xp_amount: int, mastery_amount: float) -> void:
	if not action_cards.has(key):
		return
	var card: Dictionary = action_cards[key]
	var button := card.get("button") as Button
	var art_panel := card.get("art_panel") as Control
	var mastery_bar := card.get("mastery") as Control
	if button == null or art_panel == null:
		return
	art_panel.pivot_offset = art_panel.size * 0.5
	if success:
		_flash_art_glow(art_panel, Color("#35d86d"))
		art_panel.modulate = Color("#93ff9e")
		art_panel.scale = Vector2.ONE
		var pop := create_tween()
		pop.set_parallel(true)
		pop.tween_property(art_panel, "scale", Vector2(1.12, 1.12), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop.tween_property(art_panel, "modulate", Color.WHITE, 0.28)
		pop.chain().tween_property(art_panel, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_float_xp(self, art_panel, xp_amount)
		_float_mastery_bar(self, mastery_bar, mastery_amount)
	else:
		_flash_art_glow(art_panel, Color("#ff4f4f"))
		art_panel.modulate = Color("#ff8d8d")
		art_panel.rotation_degrees = 0.0
		var shake := create_tween()
		shake.tween_property(art_panel, "rotation_degrees", -5.0, 0.05)
		shake.tween_property(art_panel, "rotation_degrees", 5.0, 0.05)
		shake.tween_property(art_panel, "rotation_degrees", -4.0, 0.05)
		shake.tween_property(art_panel, "rotation_degrees", 3.0, 0.05)
		shake.tween_property(art_panel, "rotation_degrees", 0.0, 0.06)
		shake.parallel().tween_property(art_panel, "modulate", Color.WHITE, 0.26)
		_float_mastery_bar(self, mastery_bar, mastery_amount)


func _flash_art_glow(anchor: Control, color: Color) -> void:
	var glow := Panel.new()
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.z_index = 80
	glow.add_theme_stylebox_override("panel", _art_glow_style(color))
	anchor.add_child(glow)
	glow.modulate = Color(1, 1, 1, 0.95)
	var tween := create_tween()
	tween.tween_property(glow, "modulate:a", 0.0, 0.48).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(glow.queue_free)


func _float_xp(parent: Control, anchor: Control, xp_amount: int) -> void:
	if xp_amount <= 0:
		return
	_float_reward(parent, anchor, "+%s XP" % xp_amount, 92, Color("#2ff06d"), Vector2(0, -86), Vector2(0, -230), 0.0)


func _float_mastery_bar(parent: Control, anchor: Control, mastery_amount: float) -> void:
	if mastery_amount <= 0:
		return
	_float_reward(parent, anchor, "+%s" % mastery_amount, 70, Color("#ffd95a"), Vector2(0, -84), Vector2(0, -88), 0.08, true)


func _float_reward(parent: Control, anchor: Control, text: String, font_size: int, color: Color, start_offset: Vector2, rise: Vector2, delay: float, at_right_end := false) -> void:
	if anchor == null:
		return
	var reward_size := Vector2(560, 130)
	var holder := Control.new()
	holder.z_index = 4096
	holder.z_as_relative = false
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.size = reward_size
	parent.add_child(holder)
	var shadow := _label(text, font_size, Color("#171615"), HORIZONTAL_ALIGNMENT_CENTER)
	shadow.size = reward_size
	shadow.position = Vector2(6, 7)
	shadow.modulate = Color(1, 1, 1, 0.58)
	holder.add_child(shadow)
	var label := _label(text, font_size, color, HORIZONTAL_ALIGNMENT_CENTER)
	label.size = reward_size
	holder.add_child(label)
	var local_pos := anchor.global_position - parent.global_position
	var anchor_x := anchor.size.x * 0.5 - reward_size.x * 0.5
	if at_right_end:
		anchor_x = anchor.size.x - reward_size.x * 0.5 - 16.0
	holder.position = local_pos + Vector2(
		anchor_x,
		anchor.size.y * 0.18 - reward_size.y * 0.5
	) + start_offset
	holder.modulate = Color(1, 1, 1, 0)
	holder.scale = Vector2(0.82, 0.82)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(holder, "position", holder.position + rise, 1.25).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(holder, "scale", Vector2.ONE, 0.18).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(holder, "modulate:a", 1.0, 0.08).set_delay(delay)
	tween.tween_property(holder, "modulate:a", 0.0, 0.85).set_delay(delay + 0.55)
	tween.chain().tween_callback(holder.queue_free)


func _show_achievement_unlocked(achievement: Dictionary) -> void:
	var presentation_size := Vector2(1500, 360)
	var banner_data := achievement.duplicate()
	banner_data["completed"] = true
	var banner := Control.new()
	banner.z_index = 8192
	banner.z_as_relative = false
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.custom_minimum_size = presentation_size
	banner.size = presentation_size
	add_child(banner)
	var card := _achievement_log_card(banner_data)
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.size = presentation_size
	banner.add_child(card)

	var target_position := Vector2(
		(size.x - presentation_size.x) * 0.5,
		size.y - BOTTOM_NAV_HEIGHT - presentation_size.y - 36.0
	)
	target_position.y = maxf(32.0, target_position.y)
	banner.position = target_position + Vector2(0, 90)
	banner.modulate = Color(1, 1, 1, 0)
	banner.scale = Vector2(0.92, 0.92)
	banner.pivot_offset = presentation_size * 0.5

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(banner, "position", target_position, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(banner, "modulate:a", 1.0, 0.12)
	tween.tween_property(banner, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(banner, "scale", Vector2(1.03, 1.03), 0.14).set_delay(0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(banner, "scale", Vector2.ONE, 0.16).set_delay(0.48).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(banner, "position", target_position + Vector2(0, 110), 0.24).set_delay(2.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(banner, "modulate:a", 0.0, 0.16).set_delay(2.32)
	tween.chain().tween_callback(banner.queue_free)


func _load_action_data() -> void:
	actions_by_skill.clear()
	skill_defs.clear()
	if _load_activity_database():
		return
	skill_defs.assign(SKILL_DEFS)
	for raw_def in SKILL_DEFS:
		var skill := raw_def as Dictionary
		var skill_id := str(skill["id"])
		var actions := []
		var dir_path := "res://docs/assets/%s/actions" % skill_id
		var files := PackedStringArray()
		var dir := DirAccess.open(dir_path)
		if dir != null:
			files = dir.get_files()
			files.sort()
		if files.is_empty():
			files = PackedStringArray(ACTION_FILES.get(skill_id, []))
		for file_name in files:
			if not file_name.ends_with(".png"):
				continue
			var number := int(file_name.substr(0, 2))
			if number <= 0 or number > UNLOCK_LEVELS.size():
				continue
			var index := number - 1
			var action_name := _title_from_asset(file_name)
			var stamina_cost := 1 + int(floor(float(index) / 3.0))
			var seconds := (1.0 + float(stamina_cost) * 0.75 + float(UNLOCK_LEVELS[index]) * 0.06) * float(skill["time_scale"])
			var xp := maxi(1, int(round(pow(float(index + 1), 1.35) * float(skill["xp_scale"]))))
			actions.append({
				"id": _slug(action_name),
				"name": action_name,
				"unlock": UNLOCK_LEVELS[index],
				"seconds": seconds,
				"xp": xp,
				"stamina": stamina_cost,
				"success": maxf(20.0, float(skill["success_start"]) - float(index) * 2.0),
				"art": "%s/%s" % [dir_path, file_name],
				"bg": _background_for_action(skill_id, index)
			})
		actions_by_skill[skill_id] = actions


func _load_activity_database() -> bool:
	if not FileAccess.file_exists(ACTIVITY_DATABASE_PATH):
		return false
	var file := FileAccess.open(ACTIVITY_DATABASE_PATH, FileAccess.READ)
	if file == null:
		return false
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return false
	var loaded_skills = data.get("skills", [])
	if typeof(loaded_skills) != TYPE_ARRAY or loaded_skills.is_empty():
		return false
	for raw_skill in loaded_skills:
		if typeof(raw_skill) != TYPE_DICTIONARY:
			continue
		var skill := raw_skill as Dictionary
		var skill_id := str(skill.get("id", ""))
		if skill_id.is_empty():
			continue
		skill_defs.append({
			"id": skill_id,
			"name": str(skill.get("name", skill_id.capitalize())),
			"verb": str(skill.get("verb", "Training"))
		})
		var loaded_actions = skill.get("actions", [])
		var actions := []
		if typeof(loaded_actions) == TYPE_ARRAY:
			for raw_action in loaded_actions:
				if typeof(raw_action) != TYPE_DICTIONARY:
					continue
				var action := raw_action as Dictionary
				var action_id := str(action.get("id", ""))
				if action_id.is_empty():
					action_id = _slug(str(action.get("name", "Action")))
				actions.append({
					"id": action_id,
					"name": str(action.get("name", action_id.capitalize())),
					"unlock": int(action.get("unlock", 1)),
					"seconds": float(action.get("seconds", 1.0)),
					"xp": int(action.get("xp", action.get("rewards", {}).get("xp", 1))),
					"stamina": int(action.get("stamina", action.get("costs", {}).get("stamina", 1))),
					"success": float(action.get("success", 90.0)),
					"art": _res_path(str(action.get("art", ""))),
					"bg": _res_path(str(action.get("background", action.get("bg", ""))))
				})
		actions_by_skill[skill_id] = actions
	return not skill_defs.is_empty()


func _background_for_action(skill_id: String, index: int) -> String:
	var bg_dir := "res://docs/assets/%s/backgrounds" % skill_id
	var dir := DirAccess.open(bg_dir)
	if dir == null:
		return "res://docs/assets/%s/actions/01-placeholder.png" % skill_id
	var files := dir.get_files()
	files.sort()
	var wanted := clampi(int(floor(float(index) / 5.0)) + 1, 1, 5)
	if skill_id == "fishing":
		wanted = clampi(int(floor(float(index) / 2.0)), 0, 11)
	for file_name in files:
		if file_name.ends_with(".png") and int(file_name.substr(0, 2)) == wanted:
			return "%s/%s" % [bg_dir, file_name]
	for file_name in files:
		if file_name.ends_with(".png"):
			return "%s/%s" % [bg_dir, file_name]
	return ""


func _init_state() -> void:
	skills.clear()
	mastery.clear()
	stamina.clear()
	stamina_bank.clear()
	for def in skill_defs:
		var skill_id := str(def["id"])
		skills[skill_id] = {"xp": 0, "level": 1}
		stamina[skill_id] = BASE_MAX_STAMINA
		stamina_bank[skill_id] = 0.0
		for action in actions_by_skill.get(skill_id, []):
			mastery[_action_key(skill_id, str(action["id"]))] = {"xp": 0, "level": 0}


func _validate_state() -> void:
	for def in skill_defs:
		var skill_id := str(def["id"])
		if not skills.has(skill_id):
			skills[skill_id] = {"xp": 0, "level": 1}
		if not stamina.has(skill_id):
			stamina[skill_id] = _max_stamina()
		if not stamina_bank.has(skill_id):
			stamina_bank[skill_id] = 0.0
		for action in actions_by_skill.get(skill_id, []):
			var key := _action_key(skill_id, str(action["id"]))
			if not mastery.has(key):
				mastery[key] = {"xp": 0, "level": 0}
			_recalculate_mastery(key)
		_recalculate_level(skill_id)
	if not skills.has(selected_skill_id):
		selected_skill_id = "fight"


func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"skills": skills,
		"mastery": mastery,
		"stamina": stamina,
		"stamina_bank": stamina_bank,
		"selected_skill_id": selected_skill_id,
		"running_skill_id": running_skill_id,
		"running_action_id": running_action_id,
		"action_progress": action_progress,
		"is_muted": is_muted,
		"last_result": last_result,
		"saved_at": Time.get_unix_time_from_system()
	}))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var raw := file.get_buffer(file.get_length()).get_string_from_utf8()
	var json := JSON.new()
	if json.parse(raw) != OK:
		return
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		return
	var loaded_skills = data.get("skills", {})
	if typeof(loaded_skills) == TYPE_DICTIONARY:
		for skill_id in loaded_skills.keys():
			if skills.has(skill_id) and typeof(loaded_skills[skill_id]) == TYPE_DICTIONARY:
				skills[skill_id]["xp"] = int(loaded_skills[skill_id].get("xp", 0))
	var loaded_mastery = data.get("mastery", {})
	if typeof(loaded_mastery) == TYPE_DICTIONARY:
		for key in loaded_mastery.keys():
			if mastery.has(key) and typeof(loaded_mastery[key]) == TYPE_DICTIONARY:
				mastery[key]["xp"] = int(loaded_mastery[key].get("xp", 0))
				_recalculate_mastery(str(key))
	var loaded_stamina = data.get("stamina", {})
	if typeof(loaded_stamina) == TYPE_DICTIONARY:
		for skill_id in loaded_stamina.keys():
			if stamina.has(skill_id):
				stamina[skill_id] = clampi(int(loaded_stamina[skill_id]), 0, _max_stamina())
	var loaded_bank = data.get("stamina_bank", {})
	if typeof(loaded_bank) == TYPE_DICTIONARY:
		for skill_id in loaded_bank.keys():
			if stamina_bank.has(skill_id):
				stamina_bank[skill_id] = float(loaded_bank[skill_id])
	selected_skill_id = str(data.get("selected_skill_id", selected_skill_id))
	running_skill_id = str(data.get("running_skill_id", ""))
	running_action_id = str(data.get("running_action_id", ""))
	action_progress = float(data.get("action_progress", 0.0))
	is_muted = bool(data.get("is_muted", false))
	last_result = str(data.get("last_result", last_result))
	AudioServer.set_bus_mute(0, is_muted)
	var offline := int(clamp(Time.get_unix_time_from_system() - int(data.get("saved_at", Time.get_unix_time_from_system())), 0, MAX_OFFLINE_SECONDS))
	if offline > 0:
		for skill_id in stamina.keys():
			stamina[skill_id] = mini(_max_stamina(), _stamina(str(skill_id)) + int(floor(float(offline) / STAMINA_REGEN_SECONDS)))


func _skill_level(skill_id: String) -> int:
	return int(skills.get(skill_id, {}).get("level", 1))


func _skill_name(skill_id: String) -> String:
	for def in skill_defs:
		if str(def["id"]) == skill_id:
			return str(def["name"])
	return skill_id.capitalize()


func _skill_theme_color(skill_id: String) -> Color:
	return SKILL_THEME_COLORS.get(skill_id, COLOR_BLUE)


func _global_level() -> int:
	var total := 0
	for skill_id in skills.keys():
		total += _skill_level(str(skill_id))
	return total


func _max_stamina() -> int:
	return BASE_MAX_STAMINA + int(floor(float(_global_level()) / 10.0)) + int(round(_global_medal_bonus("max_stamina"))) + int(round(_achievement_reward_bonus("max_stamina")))


func _stamina(skill_id: String) -> int:
	return clampi(int(stamina.get(skill_id, _max_stamina())), 0, _max_stamina())


func _xp_for_level(level: int) -> int:
	if level <= 1:
		return 0
	return int(round(22.0 * pow(float(level - 1), 2.08)))


func _xp_progress(skill_id: String) -> Dictionary:
	var level := _skill_level(skill_id)
	var xp_total := int(skills.get(skill_id, {}).get("xp", 0))
	var start := _xp_for_level(level)
	var end := _xp_for_level(level + 1)
	var current := xp_total - start
	var needed := maxi(1, end - start)
	return {"current": current, "needed": needed, "pct": clampf(float(current) / float(needed) * 100.0, 0.0, 100.0)}


func _recalculate_level(skill_id: String) -> void:
	var xp_total := int(skills[skill_id]["xp"])
	var old_level := int(skills[skill_id].get("level", 1))
	var level := 1
	while level < 99 and xp_total >= _xp_for_level(level + 1):
		level += 1
	skills[skill_id]["level"] = level
	if level > old_level:
		_play(level_player)


func _mastery_xp_for_level(level: int) -> int:
	if level <= 0:
		return 0
	return int(round(18.0 * pow(float(level), 2.05)))


func _mastery_level(skill_id: String, action_id: String) -> int:
	return int(mastery.get(_action_key(skill_id, action_id), {}).get("level", 0))


func _mastery_progress_pct(skill_id: String, action_id: String) -> float:
	var key := _action_key(skill_id, action_id)
	var level := _mastery_level(skill_id, action_id)
	if level >= MASTERY_MAX_LEVEL:
		return 100.0
	var xp_total := float(mastery.get(key, {}).get("xp", 0))
	var start := _mastery_xp_for_level(level)
	var end := _mastery_xp_for_level(level + 1)
	var needed := maxi(1, end - start)
	return clampf(float(xp_total - start) / float(needed) * 100.0, 0.0, 100.0)


func _would_mastery_reward_medal_up(skill_id: String, action_id: String, amount: float) -> bool:
	if amount <= 0.0:
		return false
	var level := _mastery_level(skill_id, action_id)
	if level >= MASTERY_MAX_LEVEL:
		return false
	var xp_total := float(mastery.get(_action_key(skill_id, action_id), {}).get("xp", 0))
	return xp_total + amount >= float(_mastery_xp_for_level(level + 1))


func _mastery_medal_texture(level: int) -> Texture2D:
	var sheet := _texture(MASTERY_MEDALS_TEXTURE)
	if sheet == null:
		return null
	var index := clampi(maxi(level, 1) - 1, 0, MASTERY_MAX_LEVEL - 1)
	if mastery_medal_textures.has(index):
		return mastery_medal_textures[index]
	var region := _mastery_medal_region(index, Vector2i(sheet.get_width(), sheet.get_height()))
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(Vector2(region.position), Vector2(region.size))
	mastery_medal_textures[index] = atlas
	return atlas


func _achievement_medal_texture(level: int) -> Texture2D:
	var sheet := _texture(MASTERY_MEDALS_TEXTURE)
	if sheet == null:
		return null
	var index := clampi(maxi(level, 1) - 1, 0, ACHIEVEMENT_MEDAL_ART_COUNT - 1)
	var key := "achievement:%s" % index
	if mastery_medal_textures.has(key):
		return mastery_medal_textures[key]
	var region := _mastery_medal_region(index, Vector2i(sheet.get_width(), sheet.get_height()))
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(Vector2(region.position), Vector2(region.size))
	mastery_medal_textures[key] = atlas
	return atlas


func _mastery_medal_region(index: int, sheet_size: Vector2i) -> Rect2i:
	var regions := [
		Rect2i(0, 19, 278, 278),
		Rect2i(267, 19, 278, 278),
		Rect2i(536, 19, 278, 278),
		Rect2i(804, 19, 278, 278),
		Rect2i(1073, 18, 278, 278),
		Rect2i(2, 296, 279, 279),
		Rect2i(266, 296, 279, 279),
		Rect2i(534, 296, 279, 279),
		Rect2i(841, 280, 280, 280),
		Rect2i(1121, 280, 280, 280),
		Rect2i(0, 574, 282, 282),
		Rect2i(267, 574, 282, 282),
		Rect2i(536, 574, 282, 282),
		Rect2i(804, 574, 282, 282),
		Rect2i(1068, 574, 297, 282),
		Rect2i(0, 842, 282, 280),
		Rect2i(267, 842, 282, 280),
		Rect2i(536, 842, 282, 280),
		Rect2i(804, 842, 282, 280),
		Rect2i(1068, 842, 297, 280)
	]
	if index >= 0 and index < regions.size():
		var region := regions[index] as Rect2i
		var max_position := Vector2i(maxi(0, sheet_size.x - region.size.x), maxi(0, sheet_size.y - region.size.y))
		region.position.x = clampi(region.position.x, 0, max_position.x)
		region.position.y = clampi(region.position.y, 0, max_position.y)
		region.size.x = mini(region.size.x, sheet_size.x - region.position.x)
		region.size.y = mini(region.size.y, sheet_size.y - region.position.y)
		return region
	var columns := 5
	var rows := 4
	var cell := Vector2i(sheet_size.x / columns, sheet_size.y / rows)
	return Rect2i(Vector2i((index % columns) * cell.x, int(floor(float(index) / float(columns))) * cell.y), cell)


func _mastery_medal_silhouette_texture(level: int, color: Color) -> Texture2D:
	var index := clampi(maxi(level, 1) - 1, 0, MASTERY_MAX_LEVEL - 1)
	var key := "%s:%s" % [index, color.to_html(true)]
	if mastery_medal_silhouette_textures.has(key):
		return mastery_medal_silhouette_textures[key]
	var sheet := _texture(MASTERY_MEDALS_TEXTURE)
	if sheet == null:
		return null
	var sheet_image := sheet.get_image()
	if sheet_image == null or sheet_image.is_empty():
		return null
	var region := _mastery_medal_region(index, Vector2i(sheet_image.get_width(), sheet_image.get_height()))
	var image := sheet_image.get_region(region)
	image.convert(Image.FORMAT_RGBA8)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var source := image.get_pixel(x, y)
			image.set_pixel(x, y, Color(color.r, color.g, color.b, source.a * color.a))
	var texture := ImageTexture.create_from_image(image)
	mastery_medal_silhouette_textures[key] = texture
	return texture


func _mastery_medal_dot_texture() -> Texture2D:
	if mastery_medal_dot_texture != null:
		return mastery_medal_dot_texture
	var size := 128
	var radius := 13.0
	var center := Vector2(float(size) * 0.5, float(size) * 0.5)
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for y in range(size):
		for x in range(size):
			var point := Vector2(float(x) + 0.5, float(y) + 0.5)
			if point.distance_to(center) <= radius:
				image.set_pixel(x, y, Color("#171615"))
	mastery_medal_dot_texture = ImageTexture.create_from_image(image)
	return mastery_medal_dot_texture


func _global_medal_tier_unlocked(level: int) -> bool:
	for key in mastery.keys():
		var entry = mastery[key]
		if typeof(entry) == TYPE_DICTIONARY and int(entry.get("level", 0)) >= level:
			return true
	return false


func _global_medal_bonus(stat: String) -> float:
	var total := 0.0
	for buff in GLOBAL_MEDAL_BUFFS:
		if str(buff.get("stat", "")) == stat and _global_medal_tier_unlocked(int(buff.get("level", 0))):
			total += float(buff.get("amount", 0.0))
	return total


func _global_medal_buff_text() -> String:
	var lines := _active_global_buff_lines()
	if lines.is_empty():
		return "Global buffs unlock from your first Bronze, Silver, Gold, and higher medals."
	return "Global buffs: %s" % ", ".join(lines)


func _new_global_medal_buff_messages(old_level: int, new_level: int, tiers_unlocked_before: Dictionary) -> Array:
	var messages := []
	for tier in range(old_level + 1, new_level + 1):
		if tier >= 1 and tier <= MASTERY_MAX_LEVEL and not bool(tiers_unlocked_before.get(tier, false)):
			messages.append("%s global buff unlocked: %s." % [MASTERY_MEDAL_NAMES[tier - 1], _global_medal_tier_bonus_text(tier)])
	return messages


func _global_medal_tier_bonus_text(level: int) -> String:
	for buff in GLOBAL_MEDAL_BUFFS:
		if int(buff.get("level", 0)) != level:
			continue
		var stat := str(buff.get("stat", ""))
		var amount := float(buff.get("amount", 0.0))
		if stat == "max_stamina":
			return "+%s max stamina" % int(round(amount))
		if stat == "xp_mult":
			return "+%s%% XP" % int(round(amount * 100.0))
		if stat == "speed_mult":
			return "+%s%% speed" % int(round(amount * 100.0))
		if stat == "success_bonus":
			return "+%s%% success" % int(round(amount))
	return "global power"


func _mastery_xp_reward(action: Dictionary) -> float:
	return 1.0


func _add_mastery_xp(skill_id: String, action_id: String, amount: float) -> void:
	var key := _action_key(skill_id, action_id)
	if not mastery.has(key):
		mastery[key] = {"xp": 0, "level": 0}
	mastery[key]["xp"] = float(mastery[key].get("xp", 0)) + amount
	_recalculate_mastery(key)


func _recalculate_mastery(key: String) -> void:
	if not mastery.has(key):
		return
	var xp_total := float(mastery[key].get("xp", 0))
	var level := 0
	while level < MASTERY_MAX_LEVEL and xp_total >= _mastery_xp_for_level(level + 1):
		level += 1
	mastery[key]["level"] = level


func _effective_stamina(action: Dictionary) -> int:
	return maxi(1, int(action.get("stamina", 1)))


func _effective_seconds(skill_id: String, action: Dictionary) -> float:
	var base_seconds := maxf(0.1, float(action.get("seconds", 1.0)))
	var speed_bonus := clampf(_global_medal_bonus("speed_mult"), 0.0, 0.75)
	var skill_timer_reduction := clampf(_skill_level_timer_reduction(skill_id), 0.0, 0.85)
	var total_reduction := clampf(speed_bonus + skill_timer_reduction, 0.0, 0.9)
	return maxf(0.1, base_seconds * (1.0 - total_reduction))


func _effective_xp(action: Dictionary) -> int:
	var xp_bonus := _global_medal_bonus("xp_mult")
	return maxi(1, int(round(float(action.get("xp", 1)) * (1.0 + xp_bonus))))


func _action_data(skill_id: String, action_id: String) -> Dictionary:
	for action in actions_by_skill.get(skill_id, []):
		if str(action["id"]) == action_id:
			return action
	return {}


func _action_key(skill_id: String, action_id: String) -> String:
	return "%s:%s" % [skill_id, action_id]


func _success_chance(skill_id: String, action: Dictionary) -> float:
	return clampf(float(action.get("success", 90.0)) + _global_medal_bonus("success_bonus"), 5.0, 99.0)


func _res_path(path: String) -> String:
	if path.is_empty() or path.begins_with("res://"):
		return path
	return "res://%s" % path


func _title_from_asset(file_name: String) -> String:
	var base := file_name.get_basename()
	if base.length() > 3 and base.substr(2, 1) == "-":
		base = base.substr(3)
	var words := base.replace("-s-", "'s-").split("-")
	for i in range(words.size()):
		words[i] = str(words[i]).capitalize()
	return " ".join(words)


func _slug(text: String) -> String:
	return text.to_lower().replace("'", "").replace(",", "").replace(" ", "-")


func _format_seconds(seconds: float) -> String:
	return "%.1f" % seconds if seconds < 10.0 else "%.0f" % seconds


func _format_percent(value: float) -> String:
	return "%.1f" % (value * 100.0)


func _load_font() -> void:
	if ResourceLoader.exists("res://assets/fonts/Fredoka.ttf"):
		app_font = load("res://assets/fonts/Fredoka.ttf")
		var bold := FontVariation.new()
		bold.base_font = app_font
		bold.variation_embolden = 0.9
		app_bold_font = bold


func _label(text: String, font_size: int, color: Color, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if app_bold_font != null:
		label.add_theme_font_override("font", app_bold_font)
	elif app_font != null:
		label.add_theme_font_override("font", app_font)
	return label


func _image(path: String, minimum_size: Vector2) -> TextureRect:
	var image := TextureRect.new()
	image.texture = _texture(path)
	image.custom_minimum_size = minimum_size
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image


func _image_from_texture(texture: Texture2D, minimum_size: Vector2) -> TextureRect:
	var image := TextureRect.new()
	image.texture = texture
	image.custom_minimum_size = minimum_size
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image


func _inset_full_rect(control: Control, inset: int) -> void:
	control.offset_left = inset
	control.offset_top = inset
	control.offset_right = -inset
	control.offset_bottom = -inset


func _icon_button(path: String) -> TextureButton:
	var button := TextureButton.new()
	button.custom_minimum_size = Vector2(300, 300)
	button.texture_normal = _texture(path)
	button.texture_hover = button.texture_normal
	button.texture_pressed = button.texture_normal
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	return button


func _nav_button(path: String) -> Button:
	var button := Button.new()
	button.text = ""
	button.custom_minimum_size = Vector2(268, 268)
	button.clip_contents = true
	button.focus_mode = Control.FOCUS_NONE
	button.icon = _texture(path)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 184)
	return button


func _menu_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 220)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 72)
	if app_bold_font != null:
		button.add_theme_font_override("font", app_bold_font)
	elif app_font != null:
		button.add_theme_font_override("font", app_font)
	button.add_theme_color_override("font_color", COLOR_INK)
	button.add_theme_color_override("font_hover_color", COLOR_INK)
	button.add_theme_color_override("font_pressed_color", COLOR_INK)
	button.add_theme_stylebox_override("normal", _panel_style(COLOR_PANEL, 12, 48))
	button.add_theme_stylebox_override("hover", _panel_style(COLOR_GOLD, 12, 48))
	button.add_theme_stylebox_override("pressed", _panel_style(COLOR_GOLD.darkened(0.08), 12, 48))
	button.add_theme_stylebox_override("disabled", _panel_style(Color("#fffaf0"), 12, 48))
	return button


func _settings_page_button(text: String, icon_path := "", min_width := 900, icon_max_width := 128, min_height := 250) -> Button:
	var button := _menu_button(text if icon_path.is_empty() else "")
	button.custom_minimum_size = Vector2(min_width, min_height)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 70)
	button.add_theme_stylebox_override("normal", _panel_style(COLOR_PANEL, 14, 54))
	button.add_theme_stylebox_override("hover", _panel_style(COLOR_GOLD, 14, 54))
	button.add_theme_stylebox_override("pressed", _panel_style(COLOR_GOLD.darkened(0.08), 14, 54))
	if not icon_path.is_empty():
		var content := MarginContainer.new()
		content.set_anchors_preset(Control.PRESET_FULL_RECT)
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_theme_constant_override("margin_left", 54)
		content.add_theme_constant_override("margin_right", 68)
		content.add_theme_constant_override("margin_top", 18)
		content.add_theme_constant_override("margin_bottom", 18)
		button.add_child(content)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 38)
		content.add_child(row)
		var icon_holder := CenterContainer.new()
		icon_holder.custom_minimum_size = Vector2(icon_max_width, icon_max_width)
		icon_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon_holder)
		var icon := TextureRect.new()
		icon.texture = _texture(icon_path)
		icon.custom_minimum_size = Vector2(icon_max_width, icon_max_width)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_holder.add_child(icon)
		var label := _label(text, 70, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(label)
	return button


func _action_stat_label(text: String) -> Label:
	var label := _label(text, 60, COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _action_stat_box(label: Label) -> PanelContainer:
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(300, 222)
	box.add_theme_stylebox_override("panel", _stat_box_style())
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(label)
	return box


func _progress(fill: Color, height: int, value := 0.0) -> CleanProgressBar:
	var bar := CleanProgressBar.new()
	bar.fill_color = fill
	bar.custom_minimum_size = Vector2(0, height)
	bar.set_value(value)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return bar


func _achievement_medal_slot_strip(skill_id: String, actions: Array) -> Dictionary:
	var strip := AchievementMedalSlotStrip.new()
	strip.slot_count = ACHIEVEMENT_MEDAL_SLOT_COUNT
	strip.slot_size = ACHIEVEMENT_MEDAL_SLOT_SIZE * 2.7
	strip.custom_minimum_size = Vector2(0, 170)
	strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panels := []
	var icons := []
	for i in range(ACHIEVEMENT_MEDAL_SLOT_COUNT):
		var shadow := _image_from_texture(_mastery_medal_silhouette_texture(1, Color(0, 0, 0, 0.70)), strip.slot_size)
		shadow.z_index = ACHIEVEMENT_MEDAL_SLOT_COUNT - i
		var icon := _image_from_texture(_mastery_medal_silhouette_texture(1, Color(0, 0, 0, 0.58)), strip.slot_size)
		icon.z_index = ACHIEVEMENT_MEDAL_SLOT_COUNT - i + ACHIEVEMENT_MEDAL_SLOT_COUNT
		if i < actions.size():
			var action := actions[i] as Dictionary
			icon.tooltip_text = "%s: %s" % [_skill_name(skill_id), str(action.get("name", ""))]
			shadow.tooltip_text = icon.tooltip_text
		strip.add_slot_icon(icon, shadow)
		panels.append(shadow)
		icons.append(icon)
	return {"root": strip, "panels": panels, "icons": icons}


func _set_bar(bar, target: float, delta: float, instant: bool) -> void:
	if bar == null:
		return
	var progress := bar as Control
	if progress == null:
		return
	var current_value := 0.0
	if progress is CleanProgressBar:
		current_value = float((progress as CleanProgressBar).value)
	elif progress is ActivityProgressRail:
		current_value = float((progress as ActivityProgressRail).value)
	if instant:
		progress.call("set_value", target)
	else:
		var step_delta := maxf(delta, 1.0 / 60.0)
		var speed := 12.0
		if progress is ActivityProgressRail and target < current_value:
			speed = 5.5
		progress.call("set_value", lerpf(current_value, target, 1.0 - exp(-speed * step_delta)))


func _panel_style(color: Color, border: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = COLOR_INK
	style.border_width_left = border
	style.border_width_right = border
	style.border_width_top = border
	style.border_width_bottom = border
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 72
	style.content_margin_right = 72
	style.content_margin_top = 58
	style.content_margin_bottom = 58
	return style


func _summary_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PAPER
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style


func _summary_icon_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PANEL
	style.border_color = COLOR_INK
	style.border_width_left = 16
	style.border_width_right = 16
	style.border_width_top = 16
	style.border_width_bottom = 16
	style.corner_radius_top_left = 44
	style.corner_radius_top_right = 44
	style.corner_radius_bottom_left = 44
	style.corner_radius_bottom_right = 44
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	return style


func _achievement_card_style(color: Color, radius: int, margin: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = COLOR_INK
	style.border_width_left = 8
	style.border_width_right = 8
	style.border_width_top = 8
	style.border_width_bottom = 8
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	return style


func _achievement_slot_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fff6d6")
	style.border_color = Color("#d2c3a0")
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 3
	style.content_margin_right = 3
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	return style


func _featured_activity_art_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fffaf0")
	style.border_color = COLOR_INK
	style.border_width_left = 6
	style.border_width_right = 6
	style.border_width_top = 6
	style.border_width_bottom = 6
	style.corner_radius_top_left = 24
	style.corner_radius_top_right = 24
	style.corner_radius_bottom_left = 24
	style.corner_radius_bottom_right = 24
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _activity_shade_style(alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.992, 0.972, alpha)
	style.corner_radius_top_left = 66
	style.corner_radius_top_right = 66
	style.corner_radius_bottom_left = 66
	style.corner_radius_bottom_right = 66
	return style


func _action_card_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.0)
	style.draw_center = false
	style.border_color = COLOR_INK
	style.border_width_left = 16
	style.border_width_right = 16
	style.border_width_top = 16
	style.border_width_bottom = 16
	style.corner_radius_top_left = 66
	style.corner_radius_top_right = 66
	style.corner_radius_bottom_left = 66
	style.corner_radius_bottom_right = 66
	style.shadow_color = Color(0.09, 0.08, 0.07, 0.72)
	style.shadow_size = 0
	style.shadow_offset = Vector2(0, 16)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style


func _action_art_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.border_color = COLOR_INK
	style.border_width_left = 12
	style.border_width_right = 12
	style.border_width_top = 12
	style.border_width_bottom = 12
	style.corner_radius_top_left = 56
	style.corner_radius_top_right = 56
	style.corner_radius_bottom_left = 56
	style.corner_radius_bottom_right = 56
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style


func _art_glow_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.28)
	style.border_color = Color(color.r, color.g, color.b, 0.95)
	style.border_width_left = 24
	style.border_width_right = 24
	style.border_width_top = 24
	style.border_width_bottom = 24
	style.corner_radius_top_left = 56
	style.corner_radius_top_right = 56
	style.corner_radius_bottom_left = 56
	style.corner_radius_bottom_right = 56
	return style


func _stat_box_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.border_color = COLOR_INK
	style.border_width_left = 16
	style.border_width_right = 16
	style.border_width_top = 16
	style.border_width_bottom = 16
	style.corner_radius_top_left = 38
	style.corner_radius_top_right = 38
	style.corner_radius_bottom_left = 38
	style.corner_radius_bottom_right = 38
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _nav_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_NAV
	style.content_margin_left = 96
	style.content_margin_right = 96
	style.content_margin_top = 36
	style.content_margin_bottom = BOTTOM_NAV_SAFE_PAD
	return style


func _progress_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = COLOR_INK
	style.border_width_left = 9
	style.border_width_right = 9
	style.border_width_top = 9
	style.border_width_bottom = 9
	style.corner_radius_top_left = 999
	style.corner_radius_top_right = 999
	style.corner_radius_bottom_left = 999
	style.corner_radius_bottom_right = 999
	return style


func _apply_nav_style(button: Button, active: bool) -> void:
	button.add_theme_stylebox_override("normal", _nav_tab_style(active))
	button.add_theme_stylebox_override("hover", _nav_tab_style(true))
	button.add_theme_stylebox_override("pressed", _nav_tab_style(true))


func _nav_tab_style(active: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = COLOR_GOLD
	var border := 16 if active else 0
	style.border_width_left = border
	style.border_width_right = border
	style.border_width_top = border
	style.border_width_bottom = border
	style.corner_radius_top_left = 46
	style.corner_radius_top_right = 46
	style.corner_radius_bottom_left = 46
	style.corner_radius_bottom_right = 46
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	return style


func _texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		var loaded = load(path)
		if loaded is Texture2D:
			return loaded
	var image := Image.new()
	if image.load(path) != OK:
		return null
	return ImageTexture.create_from_image(image)


func _chroma_material(chroma: Color) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform vec4 chroma_key : source_color = vec4(0.0, 1.0, 0.0, 1.0);
void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float distance_from_key = distance(color.rgb, chroma_key.rgb);
	if (distance_from_key < 0.30) {
		color.a = 0.0;
	}
	COLOR = color;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("chroma_key", chroma)
	return material


func _hero_chroma_material() -> ShaderMaterial:
	return _chroma_material(Color("#ffffff"))


func _build_audio() -> void:
	click_player = _sfx("res://assets/sfx/click.wav")
	success_player = _sfx("res://assets/sfx/action_success_ding.wav")
	failure_player = _sfx("res://assets/sfx/warm_reject.wav")
	level_player = _sfx("res://assets/sfx/level_up_jingle.wav")
	medal_player = _sfx("res://assets/sfx/xp_spark.wav")


func _sfx(path: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = load(path)
	add_child(player)
	return player


func _play(player: AudioStreamPlayer) -> void:
	if player != null and audio_unlocked_by_input and not is_muted:
		player.stop()
		player.play()


func _note_player_input(event: InputEvent) -> void:
	if audio_unlocked_by_input:
		return
	if event is InputEventMouseButton and event.pressed:
		audio_unlocked_by_input = true
	elif event is InputEventScreenTouch and event.pressed:
		audio_unlocked_by_input = true
	elif event is InputEventKey and event.pressed and not event.echo:
		audio_unlocked_by_input = true


func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
