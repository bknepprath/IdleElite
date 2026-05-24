extends Control

class RegenCircle:
	extends Control

	var value := 0.0
	var target_value := 0.0
	var displayed_current := 0.0
	var target_current := 0.0
	var current := 0
	var maximum := 1
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
		draw_arc(center, ring_radius, -PI * 0.5, -PI * 0.5 + TAU * value, 128, Color("#36b8e8"), ring_width, true)
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
			draw_circle(center, radius, Color("#36b8e8"))
			return
		var fill_top := center.y + radius - radius * 2.0 * pct
		var fill_bottom := center.y + radius
		var step := maxf(1.0, radius / 64.0)
		var y := fill_top
		while y <= fill_bottom:
			var dy := y - center.y
			var chord := sqrt(maxf(0.0, radius * radius - dy * dy))
			draw_line(Vector2(center.x - chord, y), Vector2(center.x + chord, y), Color("#36b8e8"), step + 1.0, true)
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
		if fill_width > 1.0:
			var fill := Rect2(inner.position, Vector2(fill_width, inner.size.y))
			_draw_round_rect(fill, fill_color, maxf(0.0, inner.size.y * 0.5))
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
	var track_color := Color("#fff1c8")
	var border_color := Color("#171615")
	var border_width := 10.0

	func set_value(next_value: float) -> void:
		value = clampf(next_value, 0.0, 100.0)
		queue_redraw()

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var radius := size.y * 0.5
		_draw_round_rect(rect, track_color, radius)
		var inner := rect.grow(-border_width)
		var fill_width := inner.size.x * value / 100.0
		if fill_width > 1.0:
			var fill := Rect2(inner.position, Vector2(fill_width, inner.size.y))
			_draw_round_rect(fill, fill_color, maxf(0.0, inner.size.y * 0.5))
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

void fragment() {
	vec2 p = UV * control_size;
	vec2 half_size = control_size * 0.5;
	float r = min(radius_px, min(half_size.x, half_size.y));
	vec2 q = abs(p - half_size) - (half_size - vec2(r));
	float distance = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
	float alpha = 1.0 - smoothstep(0.0, 2.0, distance);
	vec4 tint = COLOR;
	COLOR = texture(TEXTURE, UV) * tint;
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


class MobileScrollContainer:
	extends ScrollContainer

	const DRAG_DEADZONE := 18.0

	var drag_tracking := false
	var drag_scrolling := false
	var drag_start := Vector2.ZERO
	var drag_last := Vector2.ZERO
	var velocity := 0.0
	var scroll_tween: Tween

	func _ready() -> void:
		set_process(true)
		scroll_deadzone = int(DRAG_DEADZONE)

	func _input(event: InputEvent) -> void:
		if not is_visible_in_tree():
			return
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if _contains_global_point(event.global_position):
					_cancel_scroll_tween()
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
			return
		if event is InputEventMouseMotion and drag_tracking:
			var distance: float = event.global_position.distance_to(drag_start)
			if distance >= DRAG_DEADZONE:
				drag_scrolling = true
			if drag_scrolling:
				var delta_y: float = event.global_position.y - drag_last.y
				scroll_vertical = clampi(scroll_vertical - int(round(delta_y)), 0, _max_scroll_vertical())
				velocity = -delta_y * 60.0
				drag_last = event.global_position
				get_viewport().set_input_as_handled()

	func _process(delta: float) -> void:
		if drag_tracking or absf(velocity) < 4.0:
			return
		scroll_vertical = clampi(scroll_vertical + int(round(velocity * delta)), 0, _max_scroll_vertical())
		velocity = lerpf(velocity, 0.0, 1.0 - exp(-9.0 * delta))

	func _contains_global_point(point: Vector2) -> bool:
		return Rect2(global_position, size).has_point(point)

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


const SAVE_PATH := "user://idle_elite_save.json"
const ACTIVITY_DATABASE_PATH := "res://docs/activity-database.json"
const MASTERY_MEDALS_TEXTURE := "res://docs/assets/ui/mastery-medals-20.png"
const BASE_MAX_STAMINA := 30
const STAMINA_REGEN_SECONDS := 12.0
const MAX_OFFLINE_SECONDS := 8 * 60 * 60
const MASTERY_MAX_LEVEL := 10
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
const ACTION_CARD_HEIGHT := 840

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
var home_page: Control
var skills_page: Control
var nav_bar: PanelContainer
var content_scroll: ScrollContainer
var skills_content: Control
var home_total_label: Label
var home_skill_labels := {}
var hero_message: Label
var achievement_total_label: Label
var achievement_total_bar: CleanProgressBar
var achievement_buff_label: Label
var achievement_skill_count_labels := {}
var achievement_skill_bars := {}
var achievement_medal_slot_panels := {}
var achievement_medal_slot_icons := {}
var skills_tab: Button
var hero_tab: Button
var skill_cards := {}
var action_cards := {}
var detail_xp_label: Label
var detail_xp_bar: CleanProgressBar
var detail_stamina_bar: CleanProgressBar
var detail_regen_circle: RegenCircle
var detail_actions_scroll: MobileScrollContainer
var detail_action_card_nodes := {}
var settings_overlay: Control
var mute_button: Button
var click_player: AudioStreamPlayer
var success_player: AudioStreamPlayer
var failure_player: AudioStreamPlayer
var level_player: AudioStreamPlayer


func _ready() -> void:
	_load_font()
	_load_action_data()
	_init_state()
	_build_audio()
	_build_ui()
	load_game()
	_validate_state()
	_render_screen()
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


func _build_home_page() -> void:
	achievement_skill_count_labels.clear()
	achievement_skill_bars.clear()
	achievement_medal_slot_panels.clear()
	achievement_medal_slot_icons.clear()
	achievement_total_label = null
	achievement_total_bar = null
	achievement_buff_label = null
	hero_message = null
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", PAGE_PAD)
	margin.add_theme_constant_override("margin_right", PAGE_PAD)
	margin.add_theme_constant_override("margin_top", 96)
	margin.add_theme_constant_override("margin_bottom", 0)
	home_page.add_child(margin)
	
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 34)
	margin.add_child(stack)
	
	var logo := TextureRect.new()
	logo.texture = _texture("res://docs/assets/logo/idle-elite-logo-chroma.png")
	logo.custom_minimum_size = Vector2(0, 645)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.material = _chroma_material(Color("#00ff00"))
	stack.add_child(logo)
	
	stack.add_child(_make_level_snapshot())
	
	var hero_panel := PanelContainer.new()
	hero_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
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


func _build_achievements(parent: PanelContainer) -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_right", 42)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_bottom", 34)
	parent.add_child(margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 26)
	margin.add_child(stack)

	var summary := PanelContainer.new()
	summary.custom_minimum_size = Vector2(0, 230)
	summary.add_theme_stylebox_override("panel", _achievement_card_style(Color("#fffdf8"), 44, 28))
	stack.add_child(summary)
	var summary_row := HBoxContainer.new()
	summary_row.alignment = BoxContainer.ALIGNMENT_CENTER
	summary_row.add_theme_constant_override("separation", 34)
	summary.add_child(summary_row)

	var medal_icon := TextureRect.new()
	medal_icon.texture = _mastery_medal_texture(1)
	medal_icon.custom_minimum_size = Vector2(132, 132)
	medal_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	medal_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	medal_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	summary_row.add_child(medal_icon)

	var summary_copy := VBoxContainer.new()
	summary_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_copy.add_theme_constant_override("separation", 12)
	summary_row.add_child(summary_copy)
	summary_copy.add_child(_label("Achievements", 86, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT))
	achievement_total_label = _label("", 52, COLOR_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	summary_copy.add_child(achievement_total_label)
	achievement_buff_label = _label("", 42, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	achievement_buff_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_copy.add_child(achievement_buff_label)
	achievement_total_bar = _progress(Color("#f4bf35"), 38)
	summary_copy.add_child(achievement_total_bar)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 26)
	grid.add_theme_constant_override("v_separation", 26)
	stack.add_child(grid)

	for def in skill_defs:
		var skill_id := str(def["id"])
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 330)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", _achievement_card_style(COLOR_PANEL, 34, 24))
		grid.add_child(card)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 24)
		card.add_child(row)

		var icon := _image("res://docs/assets/icons/%s.png" % skill_id, Vector2(124, 124))
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(icon)

		var copy := VBoxContainer.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		copy.add_theme_constant_override("separation", 10)
		row.add_child(copy)
		copy.add_child(_label(_skill_name(skill_id), 54, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT))
		var count_label := _label("", 42, COLOR_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
		copy.add_child(count_label)
		achievement_skill_count_labels[skill_id] = count_label
		var bar := _progress(Color("#f4bf35"), 30)
		copy.add_child(bar)
		achievement_skill_bars[skill_id] = bar

		var medal_grid := GridContainer.new()
		medal_grid.columns = 10
		medal_grid.add_theme_constant_override("h_separation", 8)
		medal_grid.add_theme_constant_override("v_separation", 8)
		copy.add_child(medal_grid)

		var slot_panels := []
		var slot_icons := []
		for action in actions_by_skill.get(skill_id, []):
			var slot := PanelContainer.new()
			slot.custom_minimum_size = Vector2(44, 44)
			slot.add_theme_stylebox_override("panel", _achievement_slot_style())
			medal_grid.add_child(slot)
			var slot_icon := TextureRect.new()
			slot_icon.custom_minimum_size = Vector2(38, 38)
			slot_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			slot_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			slot_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(slot_icon)
			slot_panels.append(slot)
			slot_icons.append(slot_icon)
		achievement_medal_slot_panels[skill_id] = slot_panels
		achievement_medal_slot_icons[skill_id] = slot_icons

	hero_message = _label(last_result.to_upper(), 38, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	hero_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(hero_message)


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
	margin.add_theme_constant_override("margin_left", PAGE_PAD)
	margin.add_theme_constant_override("margin_right", PAGE_PAD)
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
	row.add_theme_constant_override("separation", 220)
	row.clip_contents = true
	row.custom_minimum_size = Vector2(0, BOTTOM_NAV_HEIGHT - BOTTOM_NAV_SAFE_PAD)
	nav_bar.add_child(row)
	skills_tab = _nav_button("res://docs/assets/ui/total-lv-bargraph.png")
	skills_tab.pressed.connect(_show_skills)
	row.add_child(skills_tab)
	hero_tab = _nav_button("res://docs/assets/ui/motivation-star.png")
	hero_tab.pressed.connect(_show_home)
	row.add_child(hero_tab)


func _build_settings_overlay() -> void:
	settings_overlay = ColorRect.new()
	settings_overlay.color = Color(0, 0, 0, 0.34)
	settings_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_overlay.visible = false
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
	var reset := _menu_button("Reset Data")
	reset.add_theme_stylebox_override("normal", _panel_style(Color("#ffe2e2"), 12, 48))
	reset.pressed.connect(_reset_data)
	stack.add_child(reset)
	var close := _menu_button("Close")
	close.pressed.connect(_close_settings)
	stack.add_child(close)


func _render_screen() -> void:
	if skills_content == null:
		return
	_clear(skills_content)
	skill_cards.clear()
	action_cards.clear()
	
	if current_screen == "skill":
		_render_skill_detail()
	else:
		content_scroll = MobileScrollContainer.new()
		content_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
		content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		skills_content.add_child(content_scroll)
		var stack := VBoxContainer.new()
		stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stack.add_theme_constant_override("separation", 52)
		content_scroll.add_child(stack)
		_render_skill_menu(stack)
	_update_page_visibility()


func _render_skill_menu(stack: VBoxContainer) -> void:
	stack.add_child(_label("Skills", 132, COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER))
	for def in skill_defs:
		var skill_id := str(def["id"])
		var button := Button.new()
		button.text = ""
		button.custom_minimum_size = Vector2(0, 500)
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_stylebox_override("normal", _panel_style(COLOR_PANEL, 12, CARD_RADIUS))
		button.add_theme_stylebox_override("hover", _panel_style(COLOR_GOLD, 12, CARD_RADIUS))
		button.add_theme_stylebox_override("pressed", _panel_style(COLOR_GOLD.darkened(0.08), 12, CARD_RADIUS))
		button.pressed.connect(_select_skill.bind(skill_id))
		stack.add_child(button)
		
		var margin := MarginContainer.new()
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin.add_theme_constant_override("margin_left", 72)
		margin.add_theme_constant_override("margin_right", 72)
		margin.add_theme_constant_override("margin_top", 58)
		margin.add_theme_constant_override("margin_bottom", 58)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(margin)
		
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 62)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(row)
		row.add_child(_image("res://docs/assets/icons/%s.png" % skill_id, Vector2(300, 300)))
		var copy := VBoxContainer.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		copy.add_theme_constant_override("separation", 28)
		copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(copy)
		var title := _label("", 108, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
		copy.add_child(title)
		var meta := _label("", 54, COLOR_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
		copy.add_child(meta)
		var xp_bar := _progress(COLOR_GREEN, 58)
		copy.add_child(xp_bar)
		var stamina_bar := _progress(COLOR_BLUE, 58)
		copy.add_child(stamina_bar)
		skill_cards[skill_id] = {"title": title, "meta": meta, "xp": xp_bar, "stamina": stamina_bar}


func _render_skill_detail() -> void:
	var page := VBoxContainer.new()
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.add_theme_constant_override("separation", 0)
	skills_content.add_child(page)

	var header := PanelContainer.new()
	header.custom_minimum_size = Vector2(0, 760)
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
	detail_xp_bar = _progress(COLOR_GREEN, 78, float(xp["pct"]))
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
	page.add_child(divider)

	var actions_scroll := MobileScrollContainer.new()
	detail_actions_scroll = actions_scroll
	detail_action_card_nodes.clear()
	actions_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	actions_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	actions_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	page.add_child(actions_scroll)
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 56)
	actions_scroll.add_child(stack)
	var scroll_top_spacer := Control.new()
	scroll_top_spacer.custom_minimum_size = Vector2(0, 12)
	stack.add_child(scroll_top_spacer)
	
	for action in actions_by_skill.get(selected_skill_id, []):
		var action_id := str(action["id"])
		var card_root := Control.new()
		card_root.custom_minimum_size = Vector2(0, ACTION_CARD_HEIGHT)
		card_root.clip_contents = true
		stack.add_child(card_root)
		detail_action_card_nodes[action_id] = card_root
		
		var bg := RoundedTextureRect.new()
		bg.texture = _texture(str(action["bg"]))
		bg.modulate = Color.WHITE
		bg.radius = 66.0
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.z_index = 150
		card_root.add_child(bg)
		
		var shade := Panel.new()
		shade.add_theme_stylebox_override("panel", _activity_shade_style(0.58))
		shade.set_anchors_preset(Control.PRESET_FULL_RECT)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shade.z_index = 151
		card_root.add_child(shade)
		
		var margin := MarginContainer.new()
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin.add_theme_constant_override("margin_left", 54)
		margin.add_theme_constant_override("margin_right", 54)
		margin.add_theme_constant_override("margin_top", 56)
		margin.add_theme_constant_override("margin_bottom", 108)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.z_index = 200
		card_root.add_child(margin)
		
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 56)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(row)

		var art_panel := Panel.new()
		art_panel.custom_minimum_size = Vector2(410, 410)
		art_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		art_panel.add_theme_stylebox_override("panel", _action_art_style())
		art_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(art_panel)
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
		name.add_theme_constant_override("outline_size", 16)
		name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
		progress.fill_color = COLOR_GREEN
		progress.anchor_left = 0.0
		progress.anchor_right = 1.0
		progress.anchor_top = 1.0
		progress.anchor_bottom = 1.0
		progress.offset_left = 54
		progress.offset_right = -54
		progress.offset_top = -112
		progress.offset_bottom = -48
		progress.z_index = 210
		progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_root.add_child(progress)

		var border := ActivityCardBorder.new()
		border.set_anchors_preset(Control.PRESET_FULL_RECT)
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		border.z_index = 220
		card_root.add_child(border)

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
		card_root.add_child(button)
		action_cards[_action_key(selected_skill_id, action_id)] = {
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
	call_deferred("_scroll_to_latest_unlocked_activity", false)


func _update_page_visibility() -> void:
	home_page.visible = current_screen == "home"
	skills_page.visible = current_screen != "home"
	_apply_nav_style(hero_tab, current_screen == "home")
	_apply_nav_style(skills_tab, current_screen == "menu" or current_screen == "skill")


func _update_ui(delta: float, instant := false) -> void:
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
		_set_bar(card["xp"], float(xp["pct"]), delta, instant)
		_set_bar(card["stamina"], float(_stamina(str(skill_id))) / float(_max_stamina()) * 100.0, delta, instant)
	if current_screen == "skill":
		var detail_xp := _xp_progress(selected_skill_id)
		if detail_xp_label != null:
			detail_xp_label.text = "Lv %s - XP %s / %s" % [_skill_level(selected_skill_id), int(detail_xp["current"]), int(detail_xp["needed"])]
		if detail_xp_bar != null:
			_set_bar(detail_xp_bar, float(detail_xp["pct"]), delta, instant)
		if detail_regen_circle != null:
			var circle_value := 1.0
			if _stamina(selected_skill_id) < _max_stamina():
				circle_value = float(stamina_bank.get(selected_skill_id, 0.0)) / STAMINA_REGEN_SECONDS
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
		(card["time"] as Label).text = "%ss\nTIME" % _format_seconds(_effective_seconds(action))
		(card["success"] as Label).text = "%s%%\nRATE" % int(_success_chance(skill_id, action))
		var status := card["status"] as Label
		status.text = ""
		var medal := card["medal"] as TextureRect
		var mastery_level := _mastery_level(skill_id, action_id)
		medal.visible = mastery_level > 0
		medal.texture = _mastery_medal_texture(mastery_level) if mastery_level > 0 else null
		medal.modulate = Color.WHITE
		_set_bar(card["mastery"], _mastery_progress_pct(skill_id, action_id), delta, instant)
		_set_bar(card["progress"], action_progress * 100.0 if running else 0.0, delta, instant)
	if mute_button != null:
		mute_button.text = "Unmute" if is_muted else "Mute"


func _update_achievements_ui(delta: float, instant: bool) -> void:
	if achievement_total_label == null:
		return
	var total_earned := 0
	var total_possible := 0
	for def in skill_defs:
		var skill_id := str(def["id"])
		var actions: Array = actions_by_skill.get(skill_id, [])
		var earned := 0
		for action in actions:
			if _mastery_level(skill_id, str(action["id"])) > 0:
				earned += 1
		total_earned += earned
		total_possible += actions.size()
		if achievement_skill_count_labels.has(skill_id):
			var count_label := achievement_skill_count_labels[skill_id] as Label
			count_label.text = "%s / %s medals" % [earned, actions.size()]
		if achievement_skill_bars.has(skill_id):
			var pct := 0.0 if actions.is_empty() else float(earned) / float(actions.size()) * 100.0
			_set_bar(achievement_skill_bars[skill_id], pct, delta, instant)
		_update_achievement_medal_slots(skill_id, actions)
	achievement_total_label.text = "%s / %s medals collected" % [total_earned, total_possible]
	if achievement_buff_label != null:
		achievement_buff_label.text = _global_medal_buff_text()
	if achievement_total_bar != null:
		var total_pct := 0.0 if total_possible <= 0 else float(total_earned) / float(total_possible) * 100.0
		_set_bar(achievement_total_bar, total_pct, delta, instant)


func _update_achievement_medal_slots(skill_id: String, actions: Array) -> void:
	var panels: Array = achievement_medal_slot_panels.get(skill_id, [])
	var icons: Array = achievement_medal_slot_icons.get(skill_id, [])
	for i in range(mini(actions.size(), icons.size())):
		var action := actions[i] as Dictionary
		var level := _mastery_level(skill_id, str(action["id"]))
		var icon := icons[i] as TextureRect
		if icon != null:
			icon.texture = _mastery_medal_texture(level) if level > 0 else null
		var panel := panels[i] as PanelContainer
		if panel != null:
			panel.modulate = Color.WHITE if level > 0 else Color(1, 1, 1, 0.72)


func _on_stamina_gauge_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_scroll_to_latest_unlocked_activity(true)
		get_viewport().set_input_as_handled()


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
	action_progress += delta / _effective_seconds(action)
	if action_progress < 1.0:
		return
	action_progress = 0.0
	stamina[running_skill_id] = _stamina(running_skill_id) - cost
	var success := randf() * 100.0 <= _success_chance(running_skill_id, action)
	if success:
		var xp_reward := _effective_xp(action)
		var mastery_reward := _mastery_xp_reward(action)
		var old_mastery_level := _mastery_level(running_skill_id, running_action_id)
		var tiers_unlocked_before := {}
		for tier in range(1, MASTERY_MAX_LEVEL + 1):
			tiers_unlocked_before[tier] = _global_medal_tier_unlocked(tier)
		skills[running_skill_id]["xp"] = int(skills[running_skill_id]["xp"]) + xp_reward
		_add_mastery_xp(running_skill_id, running_action_id, mastery_reward)
		_recalculate_level(running_skill_id)
		last_result = "+%s XP from %s." % [xp_reward, action["name"]]
		var new_global_buffs := _new_global_medal_buff_messages(old_mastery_level, _mastery_level(running_skill_id, running_action_id), tiers_unlocked_before)
		if not new_global_buffs.is_empty():
			last_result += " " + " ".join(new_global_buffs)
		_play_action_feedback(_action_key(running_skill_id, running_action_id), true, xp_reward, mastery_reward)
		_play(success_player)
	else:
		last_result = "Failed %s." % action["name"]
		_play_action_feedback(_action_key(running_skill_id, running_action_id), false, 0, 0)
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
		return
	selected_skill_id = skill_id
	running_skill_id = skill_id
	running_action_id = action_id
	action_progress = 0.0
	_set_result("%s started." % action["name"])


func _select_skill(skill_id: String) -> void:
	selected_skill_id = skill_id
	current_screen = "skill"
	_play(click_player)
	_render_screen()


func _show_home() -> void:
	current_screen = "home"
	_play(click_player)
	_render_screen()


func _show_skills() -> void:
	current_screen = "menu"
	_play(click_player)
	_render_screen()


func _back_to_skills() -> void:
	current_screen = "menu"
	_play(click_player)
	_render_screen()


func _open_settings() -> void:
	settings_overlay.visible = true
	_play(click_player)


func _close_settings() -> void:
	settings_overlay.visible = false
	_play(click_player)


func _toggle_mute() -> void:
	is_muted = not is_muted
	AudioServer.set_bus_mute(0, is_muted)
	_update_ui(0.0, true)


func _reset_data() -> void:
	_init_state()
	running_skill_id = ""
	running_action_id = ""
	action_progress = 0.0
	current_screen = "home"
	last_result = "Progress reset."
	save_game()
	_close_settings()
	_render_screen()
	_update_ui(0.0, true)


func _set_result(text: String) -> void:
	last_result = text
	if hero_message != null:
		hero_message.text = text.to_upper()
	_play(click_player)


func _play_action_feedback(key: String, success: bool, xp_amount: int, mastery_amount: int) -> void:
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


func _float_mastery_bar(parent: Control, anchor: Control, mastery_amount: int) -> void:
	if mastery_amount <= 0:
		return
	_float_reward(parent, anchor, "+%s" % mastery_amount, 70, Color("#ffd95a"), Vector2(0, -84), Vector2(0, -88), 0.08, true)


func _float_reward(parent: Control, anchor: Control, text: String, font_size: int, color: Color, start_offset: Vector2, rise: Vector2, delay: float, at_right_end := false) -> void:
	if anchor == null:
		return
	var label := _label(text, font_size, color, HORIZONTAL_ALIGNMENT_CENTER)
	label.z_index = 4096
	label.z_as_relative = false
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.custom_minimum_size = Vector2(560, 130)
	label.add_theme_color_override("font_outline_color", COLOR_INK)
	label.add_theme_constant_override("outline_size", 12)
	parent.add_child(label)
	var local_pos := anchor.global_position - parent.global_position
	var anchor_x := anchor.size.x * 0.5 - label.custom_minimum_size.x * 0.5
	if at_right_end:
		anchor_x = anchor.size.x - label.custom_minimum_size.x * 0.5 - 16.0
	label.position = local_pos + Vector2(
		anchor_x,
		anchor.size.y * 0.18 - label.custom_minimum_size.y * 0.5
	) + start_offset
	label.modulate = Color(1, 1, 1, 0)
	label.scale = Vector2(0.82, 0.82)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + rise, 1.25).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2.ONE, 0.18).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 1.0, 0.08).set_delay(delay)
	tween.tween_property(label, "modulate:a", 0.0, 0.85).set_delay(delay + 0.55)
	tween.chain().tween_callback(label.queue_free)


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
	var data = JSON.parse_string(file.get_as_text())
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


func _global_level() -> int:
	var total := 0
	for skill_id in skills.keys():
		total += _skill_level(str(skill_id))
	return total


func _max_stamina() -> int:
	return BASE_MAX_STAMINA + int(floor(float(_global_level()) / 10.0)) + int(round(_global_medal_bonus("max_stamina")))


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
	var xp_total := int(mastery.get(key, {}).get("xp", 0))
	var start := _mastery_xp_for_level(level)
	var end := _mastery_xp_for_level(level + 1)
	var needed := maxi(1, end - start)
	return clampf(float(xp_total - start) / float(needed) * 100.0, 0.0, 100.0)


func _mastery_medal_texture(level: int) -> Texture2D:
	var sheet := _texture(MASTERY_MEDALS_TEXTURE)
	if sheet == null:
		return null
	var index := clampi(maxi(level, 1) - 1, 0, MASTERY_MAX_LEVEL - 1)
	if mastery_medal_textures.has(index):
		return mastery_medal_textures[index]
	var columns := 5
	var rows := 4
	var cell := Vector2(float(sheet.get_width()) / float(columns), float(sheet.get_height()) / float(rows))
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(Vector2(float(index % columns) * cell.x, float(index / columns) * cell.y), cell)
	mastery_medal_textures[index] = atlas
	return atlas


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
	var active_tiers := []
	for level in range(1, MASTERY_MAX_LEVEL + 1):
		if _global_medal_tier_unlocked(level):
			active_tiers.append(MASTERY_MEDAL_NAMES[level - 1])
	if active_tiers.is_empty():
		return "Global buffs unlock from your first Bronze, Silver, Gold, and higher medals."
	var parts := []
	var stamina_bonus := int(round(_global_medal_bonus("max_stamina")))
	var xp_bonus := int(round(_global_medal_bonus("xp_mult") * 100.0))
	var speed_bonus := int(round(_global_medal_bonus("speed_mult") * 100.0))
	var success_bonus := int(round(_global_medal_bonus("success_bonus")))
	if stamina_bonus > 0:
		parts.append("+%s max stamina" % stamina_bonus)
	if xp_bonus > 0:
		parts.append("+%s%% XP" % xp_bonus)
	if speed_bonus > 0:
		parts.append("+%s%% speed" % speed_bonus)
	if success_bonus > 0:
		parts.append("+%s%% success" % success_bonus)
	return "%s first-medal buffs: %s" % [", ".join(active_tiers), ", ".join(parts)]


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


func _mastery_xp_reward(action: Dictionary) -> int:
	return 1


func _add_mastery_xp(skill_id: String, action_id: String, amount: int) -> void:
	var key := _action_key(skill_id, action_id)
	if not mastery.has(key):
		mastery[key] = {"xp": 0, "level": 0}
	mastery[key]["xp"] = int(mastery[key].get("xp", 0)) + amount
	_recalculate_mastery(key)


func _recalculate_mastery(key: String) -> void:
	if not mastery.has(key):
		return
	var xp_total := int(mastery[key].get("xp", 0))
	var level := 0
	while level < MASTERY_MAX_LEVEL and xp_total >= _mastery_xp_for_level(level + 1):
		level += 1
	mastery[key]["level"] = level


func _effective_stamina(action: Dictionary) -> int:
	return maxi(1, int(action.get("stamina", 1)))


func _effective_seconds(action: Dictionary) -> float:
	var base_seconds := maxf(0.1, float(action.get("seconds", 1.0)))
	var speed_bonus := clampf(_global_medal_bonus("speed_mult"), 0.0, 0.75)
	return maxf(0.1, base_seconds * (1.0 - speed_bonus))


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
	button.custom_minimum_size = Vector2(280, 280)
	button.clip_contents = true
	button.focus_mode = Control.FOCUS_NONE
	button.icon = _texture(path)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 190)
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


func _action_stat_label(text: String) -> Label:
	var label := _label(text, 60, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	label.add_theme_color_override("font_outline_color", COLOR_INK)
	label.add_theme_constant_override("outline_size", 11)
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
	var border := 18 if active else 0
	style.border_width_left = border
	style.border_width_right = border
	style.border_width_top = border
	style.border_width_bottom = border
	style.corner_radius_top_left = 52
	style.corner_radius_top_right = 52
	style.corner_radius_bottom_left = 52
	style.corner_radius_bottom_right = 52
	style.content_margin_left = 34
	style.content_margin_right = 34
	style.content_margin_top = 28
	style.content_margin_bottom = 28
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


func _sfx(path: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = load(path)
	add_child(player)
	return player


func _play(player: AudioStreamPlayer) -> void:
	if player != null and not is_muted:
		player.stop()
		player.play()


func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
