extends Control

const PHASE_CALM := Color("#9ad4e8")
const PHASE_BITE := Color("#fff2a8")
const PHASE_SUCCESS := Color("#8ee4a8")
const PHASE_FAIL := Color("#e8b0b0")
const TRACK_COLOR := Color("#fff1c8")

var archetype := "steady"
var raw_progress := 0.0
var reveal_phase := "" # "", "success", "fail"
var jitter_phase := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_archetype(next_archetype: String) -> void:
	archetype = next_archetype if next_archetype else "steady"
	queue_redraw()


func set_attempt(progress: float, running: bool, reveal_kind := "") -> void:
	raw_progress = clampf(progress, 0.0, 1.0)
	reveal_phase = reveal_kind if not running else ""
	if running:
		jitter_phase += 0.17
	queue_redraw()


func _draw() -> void:
	if size.x <= 2.0 or size.y <= 2.0:
		return
	var radius := size.y * 0.5
	_draw_round_rect(Rect2(Vector2.ZERO, size), TRACK_COLOR, radius)
	var inner := Rect2(Vector2(4, 4), size - Vector2(8, 8))
	var inner_radius := maxf(0.0, radius - 4.0)
	var display_pct := _display_percent(raw_progress)
	var fill_color := _fill_color(raw_progress)
	var fill_width := inner.size.x * display_pct / 100.0
	if fill_width > 0.5:
		_draw_partial_round_fill(inner, fill_width, fill_color, inner_radius)
	_draw_round_outline(Rect2(Vector2.ZERO, size), Color("#171615"), radius, 4.0)


func _phase(progress: float) -> String:
	var spec := _archetype_spec(archetype)
	var calm_end: float = spec.get("calm_end", 0.55)
	var bite_end: float = spec.get("bite_end", 0.88)
	if not reveal_phase.is_empty():
		return reveal_phase
	if progress < calm_end:
		return "calm"
	if progress < bite_end:
		return "bite"
	return "reveal"


func _fill_color(progress: float) -> Color:
	if reveal_phase == "success":
		return PHASE_SUCCESS
	if reveal_phase == "fail":
		return PHASE_FAIL
	match _phase(progress):
		"bite":
			return PHASE_BITE
		"reveal":
			return PHASE_SUCCESS
		_:
			return PHASE_CALM


func _display_percent(progress: float) -> float:
	var spec := _archetype_spec(archetype)
	var mode: String = spec.get("bar_mode", "smooth")
	var pct := progress * 100.0
	match mode:
		"steps":
			var steps := int(spec.get("steps", 5))
			var stepped := float(ceili(progress * float(steps))) / float(steps)
			return stepped * 100.0
		"late_surge":
			if progress < 0.72:
				return (progress / 0.72) * 68.0
			return 68.0 + ((progress - 0.72) / 0.28) * 32.0
		"jitter":
			var wobble := sin(jitter_phase * 4.2) * 4.0 + sin(jitter_phase * 9.5) * 2.5
			return clampf(pct + wobble, 0.0, 100.0)
		"pulse":
			var ping := maxf(0.0, sin(jitter_phase * 2.4) * 0.5 + 0.5)
			return clampf(pct * 0.55 + ping * 18.0, 0.0, 100.0)
		"breathe":
			var breath := 1.0 + sin(jitter_phase * 1.35) * 0.06
			return clampf(pct * breath, 0.0, 100.0)
		"stall":
			if progress < 0.58:
				return (progress / 0.58) * 48.0
			if progress < 0.66:
				return 48.0
			return 48.0 + ((progress - 0.66) / 0.34) * 52.0
		_:
			return pct


static func _archetype_spec(archetype_id: String) -> Dictionary:
	match archetype_id:
		"novice":
			return {"calm_end": 0.62, "bite_end": 0.90, "bar_mode": "smooth"}
		"volume":
			return {"calm_end": 0.42, "bite_end": 0.82, "bar_mode": "steps", "steps": 5}
		"commit":
			return {"calm_end": 0.72, "bite_end": 0.92, "bar_mode": "late_surge"}
		"chaos":
			return {"calm_end": 0.48, "bite_end": 0.85, "bar_mode": "jitter"}
		"risk":
			return {"calm_end": 0.50, "bite_end": 0.90, "bar_mode": "smooth"}
		_:
			return {"calm_end": 0.55, "bite_end": 0.88, "bar_mode": "smooth"}


func _draw_round_rect(rect: Rect2, color: Color, radius: float) -> void:
	var center_y := rect.position.y + rect.size.y * 0.5
	var clamped_radius := minf(radius, rect.size.x * 0.5)
	draw_rect(
		Rect2(rect.position + Vector2(clamped_radius, 0), Vector2(maxf(0.0, rect.size.x - clamped_radius * 2.0), rect.size.y)),
		color
	)
	draw_circle(Vector2(rect.position.x + clamped_radius, center_y), clamped_radius, color)
	draw_circle(Vector2(rect.end.x - clamped_radius, center_y), clamped_radius, color)


func _draw_partial_round_fill(rect: Rect2, fill_width: float, color: Color, radius: float) -> void:
	var clamped_width := clampf(fill_width, 0.0, rect.size.x)
	if clamped_width <= 0.0 or rect.size.y <= 0.0:
		return
	var clamped_radius := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var cap_center := Vector2(rect.position.x + clamped_radius, rect.position.y + rect.size.y * 0.5)
	var fill_right := rect.position.x + clamped_width
	if clamped_width > clamped_radius:
		draw_rect(
			Rect2(Vector2(rect.position.x + clamped_radius, rect.position.y), Vector2(clamped_width - clamped_radius, rect.size.y)),
			color
		)
	var step := maxf(1.0, rect.size.y / 48.0)
	var y := rect.position.y
	while y < rect.end.y:
		var slice_height := minf(step, rect.end.y - y)
		var dy := y + slice_height * 0.5 - cap_center.y
		var cap_chord := sqrt(maxf(0.0, clamped_radius * clamped_radius - dy * dy))
		var left_x := cap_center.x - cap_chord
		var right_x := minf(fill_right, cap_center.x + cap_chord)
		if right_x > left_x:
			draw_rect(Rect2(Vector2(left_x, y), Vector2(right_x - left_x, slice_height)), color)
		y += step


func _draw_round_outline(rect: Rect2, color: Color, radius: float, width: float) -> void:
	var half_width := width * 0.5
	var y_top := rect.position.y + half_width
	var y_bottom := rect.end.y - half_width
	var x_left := rect.position.x + radius
	var x_right := rect.end.x - radius
	draw_line(Vector2(x_left, y_top), Vector2(x_right, y_top), color, width, true)
	draw_line(Vector2(x_left, y_bottom), Vector2(x_right, y_bottom), color, width, true)
	draw_arc(Vector2(x_left, rect.position.y + radius), radius - half_width, PI, PI * 1.5, 24, color, width, true)
	draw_arc(Vector2(x_right, rect.position.y + radius), radius - half_width, PI * 1.5, TAU, 24, color, width, true)
	draw_arc(Vector2(x_left, rect.end.y - radius), radius - half_width, PI * 0.5, PI, 24, color, width, true)
	draw_arc(Vector2(x_right, rect.end.y - radius), radius - half_width, 0.0, PI * 0.5, 24, color, width, true)
