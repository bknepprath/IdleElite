class_name ThemeStyles
extends RefCounted

const ActivityCardDepth = preload("res://scripts/ui/activity_card_depth.gd")
const ActivityProgressRail = preload("res://scripts/ui/activity_progress_rail.gd")
const PassiveModuleStyles = preload("res://scripts/ui/passive_module_styles.gd")
const CleanProgressBar = preload("res://scripts/ui/clean_progress_bar.gd")

const SKILL_THEME_COLORS := {
	"fight": Color("#e84d4d"),
	"thieving": Color("#8956bc"),
	"build": Color("#237cd5"),
	"woodcutting": Color("#6ea937"),
	"fishing": Color("#2dc0b9")
}


static func skill_theme_color(skill_id: String, fallback_color: Color) -> Color:
	return SKILL_THEME_COLORS.get(skill_id, fallback_color)


static func skill_paper_button_color(skill_id: String, dark_mode_enabled: bool, light_mix: float, dark_darken: float, dark_panel: Color, dark_panel_mix: float, fallback_color: Color) -> Color:
	var base := skill_theme_color(skill_id, fallback_color)
	if dark_mode_enabled:
		return base.darkened(dark_darken).lerp(dark_panel, dark_panel_mix)
	return base.lerp(Color.WHITE, light_mix)


static func load_app_fonts(font_path := "res://assets/fonts/Fredoka.ttf", embolden := 0.9) -> Dictionary:
	var fonts := {
		"font": null,
		"bold_font": null
	}
	if not ResourceLoader.exists(font_path):
		return fonts
	var loaded_font := load(font_path) as Font
	if loaded_font == null:
		return fonts
	fonts["font"] = loaded_font
	var bold := FontVariation.new()
	bold.base_font = loaded_font
	bold.variation_embolden = embolden
	fonts["bold_font"] = bold
	return fonts


static func label(text: String, font_size: int, color: Color, align: HorizontalAlignment, app_font: Font, app_bold_font: Font, dark_mode_enabled: bool, color_ink: Color, color_dark_ink: Color, color_muted: Color, color_dark_muted: Color, color_line: Color, color_dark_line: Color) -> Label:
	var node := Label.new()
	node.text = text
	node.horizontal_alignment = align
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", text_color(color, dark_mode_enabled, color_ink, color_dark_ink, color_muted, color_dark_muted, color_line, color_dark_line))
	if app_bold_font != null:
		node.add_theme_font_override("font", app_bold_font)
	elif app_font != null:
		node.add_theme_font_override("font", app_font)
	return node


static func paper_color(dark_mode_enabled: bool, color_paper: Color, color_dark_paper: Color) -> Color:
	return color_dark_paper if dark_mode_enabled else color_paper


static func ink_color(dark_mode_enabled: bool, color_ink: Color, color_dark_ink: Color) -> Color:
	return color_dark_ink if dark_mode_enabled else color_ink


static func text_color(color: Color, dark_mode_enabled: bool, color_ink: Color, color_dark_ink: Color, color_muted: Color, color_dark_muted: Color, color_line: Color, color_dark_line: Color) -> Color:
	if not dark_mode_enabled:
		return color
	if color_close(color, color_ink):
		return color_dark_ink
	if color_close(color, color_muted):
		return color_dark_muted
	if color_close(color, color_line):
		return color_dark_line
	return color


static func menu_button(text: String, app_font: Font, app_bold_font: Font, color_ink: Color, color_blue: Color, disabled_fill: Color, outline_size: int, paper_style: Callable, press_attach: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 220)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 72)
	if app_bold_font != null:
		button.add_theme_font_override("font", app_bold_font)
	elif app_font != null:
		button.add_theme_font_override("font", app_font)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("#efe8dc"))
	button.add_theme_color_override("font_outline_color", color_ink)
	button.add_theme_constant_override("outline_size", outline_size)
	button.add_theme_stylebox_override("normal", paper_style.call(color_blue, 48))
	button.add_theme_stylebox_override("hover", paper_style.call(color_blue, 48))
	button.add_theme_stylebox_override("pressed", paper_style.call(color_blue.darkened(0.10), 48, 72, true))
	button.add_theme_stylebox_override("disabled", paper_style.call(disabled_fill, 48, 72, false, true))
	press_attach.call(button, 0.97)
	return button


static func surface_color(color: Color, dark_mode_enabled: bool, color_paper: Color, color_dark_paper: Color, color_panel: Color, color_dark_panel: Color, color_line: Color, color_dark_line: Color, color_dark_panel_alt: Color) -> Color:
	if not dark_mode_enabled or color.a <= 0.0:
		return color
	if color_close(color, color_paper):
		return color_dark_paper
	if color_close(color, color_panel):
		return color_dark_panel
	if color_close(color, color_line):
		return color_dark_line
	if color.r >= 0.86 and color.g >= 0.82 and color.b >= 0.76:
		var lightness := (color.r + color.g + color.b) / 3.0
		return color_dark_panel_alt if lightness < 0.94 else color_dark_panel
	return color


static func outline_color(outline_color: Color, fill_color: Color, dark_mode_enabled: bool, color_ink: Color, color_dark_line: Color, color_paper: Color, color_dark_paper: Color, color_panel: Color, color_dark_panel: Color, color_line: Color, color_dark_panel_alt: Color) -> Color:
	if not dark_mode_enabled:
		return outline_color
	if color_close(outline_color, color_ink) and surface_color(fill_color, dark_mode_enabled, color_paper, color_dark_paper, color_panel, color_dark_panel, color_line, color_dark_line, color_dark_panel_alt) != fill_color:
		return color_dark_line
	return outline_color


static func color_close(a: Color, b: Color, tolerance := 0.018) -> bool:
	return (
		absf(a.r - b.r) <= tolerance
		and absf(a.g - b.g) <= tolerance
		and absf(a.b - b.b) <= tolerance
		and absf(a.a - b.a) <= tolerance
	)


static func apply_empty_button_style(button: Button) -> void:
	if button == null:
		return
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


static func progress_empty_color(theme_color: Color, color_ink: Color) -> Color:
	return theme_color.darkened(0.55).lerp(color_ink, 0.02)


static func progress_fill_color(theme_color: Color) -> Color:
	return theme_color.lightened(0.08)


static func progress_bar(fill: Color, height: int, value := 0.0) -> CleanProgressBar:
	var bar := CleanProgressBar.new()
	bar.fill_color = fill
	bar.custom_minimum_size = Vector2(0, height)
	bar.set_value(value)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return bar


static func skill_detail_xp_bar(skill_id: String, value := 0.0, fallback_color := Color("#237cd5"), color_ink := Color("#171615"), height := 62, width := 710) -> CleanProgressBar:
	var theme_color := skill_theme_color(skill_id, fallback_color)
	var bar := progress_bar(theme_color, height, value)
	bar.custom_minimum_size.x = width
	bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bar.border_width = 7.0
	apply_xp_progress_bar_theme(bar, theme_color, color_ink)
	return bar


static func set_progress_bar_value(bar, target: float, delta: float, instant: bool) -> void:
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
	elif progress is PassiveModuleStyles.SerpentineProgressBar:
		current_value = float((progress as PassiveModuleStyles.SerpentineProgressBar).value)
	if instant:
		if absf(current_value - target) > 0.001:
			progress.call("set_value", target)
	else:
		if absf(current_value - target) <= 0.01:
			if absf(current_value - target) > 0.001:
				progress.call("set_value", target)
			return
		var step_delta := minf(delta, 0.1)
		var speed := 12.0
		if progress is CleanProgressBar:
			speed = float((progress as CleanProgressBar).easing_speed)
		elif progress is ActivityProgressRail:
			speed = float((progress as ActivityProgressRail).easing_speed)
			if target < current_value:
				speed = 5.5
		elif progress is PassiveModuleStyles.SerpentineProgressBar:
			speed = float((progress as PassiveModuleStyles.SerpentineProgressBar).easing_speed)
			if target < current_value:
				speed = 5.5
		progress.call("set_value", lerpf(current_value, target, 1.0 - exp(-speed * step_delta)))


static func activity_card_fill_color(theme_color: Color) -> Color:
	return theme_color.darkened(0.18)


static func apply_activity_progress_rail_theme(bar: ActivityProgressRail, theme_color: Color, color_ink: Color) -> void:
	if bar == null:
		return
	bar.set_color_segments([], [])
	var fill := progress_fill_color(theme_color)
	var empty := progress_empty_color(theme_color, color_ink)
	if bar.fill_color == fill and bar.empty_color == empty:
		return
	bar.fill_color = fill
	bar.empty_color = empty
	bar.queue_redraw()
	bar._queue_opportunity_overlay_redraw()


static func apply_activity_progress_rail_action_theme(bar: ActivityProgressRail, theme_color: Color, segment_theme_colors: Array[Color], color_ink: Color) -> void:
	if bar == null:
		return
	if segment_theme_colors.size() <= 1:
		apply_activity_progress_rail_theme(bar, theme_color, color_ink)
		return
	var fill_colors: Array[Color] = []
	var empty_colors: Array[Color] = []
	for segment_color in segment_theme_colors:
		fill_colors.append(progress_fill_color(segment_color))
		empty_colors.append(progress_empty_color(segment_color, color_ink))
	bar.fill_color = fill_colors[0]
	bar.empty_color = empty_colors[0]
	bar.set_color_segments(fill_colors, empty_colors)


static func sync_action_card_progress_rail_theme(card: Dictionary, bar: ActivityProgressRail, skill_id: String, action: Dictionary, requirements_callable: Callable, fallback_color: Color, color_ink: Color) -> void:
	if bar == null:
		return
	var theme_key := "%s|%s|%s" % [
		skill_id,
		str(action.get("id", "")),
		hash(action.get("requirements", []))
	]
	if str(card.get("progress_rail_theme_key", "")) == theme_key:
		return
	apply_activity_progress_rail_action_theme(bar, skill_theme_color(skill_id, fallback_color), combo_progress_segment_theme_colors(skill_id, action, requirements_callable, fallback_color), color_ink)
	card["progress_rail_theme_key"] = theme_key


static func combo_progress_segment_theme_colors(skill_id: String, action: Dictionary, requirements_callable: Callable, fallback_color: Color) -> Array[Color]:
	var colors: Array[Color] = []
	for raw_skill_id in combo_progress_segment_skill_ids(skill_id, action, requirements_callable):
		colors.append(skill_theme_color(str(raw_skill_id), fallback_color))
	return colors


static func apply_activity_card_depth_action_theme(depth: ActivityCardDepth, skill_id: String, action: Dictionary, requirements_callable: Callable, fallback_color: Color) -> void:
	if depth == null or not is_instance_valid(depth):
		return
	depth.set_segment_theme_colors(combo_progress_segment_theme_colors(skill_id, action, requirements_callable, fallback_color))


static func combo_progress_segment_skill_ids(skill_id: String, action: Dictionary, requirements_callable: Callable) -> Array:
	var segment_skill_ids := []
	for raw_requirement in requirements_callable.call(skill_id, action):
		if typeof(raw_requirement) != TYPE_DICTIONARY:
			continue
		var requirement := raw_requirement as Dictionary
		var requirement_skill := str(requirement.get("skill", skill_id)).strip_edges()
		if requirement_skill.is_empty():
			requirement_skill = skill_id
		segment_skill_ids.append(requirement_skill)
	return segment_skill_ids if segment_skill_ids.size() > 1 else []


static func apply_mastery_progress_bar_theme(bar: CleanProgressBar, theme_color: Color, color_ink: Color) -> void:
	if bar == null:
		return
	var track := theme_color.darkened(0.60).lerp(color_ink, 0.02)
	if bar.track_color == track:
		return
	bar.track_color = track
	bar.queue_redraw()


static func apply_xp_progress_bar_theme(bar: CleanProgressBar, theme_color: Color, color_ink: Color) -> void:
	if bar == null:
		return
	var fill := progress_fill_color(theme_color)
	var track := progress_empty_color(theme_color, color_ink)
	var depth_back := theme_color.darkened(0.50).lerp(color_ink, 0.03)
	var shadow := theme_color.darkened(0.76)
	shadow.a = 0.20
	if (
		bar.fill_color == fill
		and bar.track_color == track
		and bar.border_color == color_ink
		and bar.depth_enabled
		and bar.depth_back_color == depth_back
		and bar.depth_outline_color == color_ink
		and bar.depth_shadow_color == shadow
	):
		return
	bar.fill_color = fill
	bar.track_color = track
	bar.border_color = color_ink
	bar.depth_enabled = true
	bar.depth_back_color = depth_back
	bar.depth_outline_color = color_ink
	bar.depth_shadow_color = shadow
	bar.queue_redraw()


static func surface_style(color: Color, radius: int, margin := 28, elevated := false, dark_mode_enabled := false, passive_border := 0, color_paper := Color.WHITE, color_dark_paper := Color.BLACK, color_panel := Color.WHITE, color_dark_panel := Color.BLACK, color_line := Color.WHITE, color_dark_line := Color.BLACK, color_dark_panel_alt := Color.BLACK) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = surface_color(color, dark_mode_enabled, color_paper, color_dark_paper, color_panel, color_dark_panel, color_line, color_dark_line, color_dark_panel_alt)
	style.border_color = Color(0, 0, 0, 0)
	style.border_width_left = passive_border
	style.border_width_right = passive_border
	style.border_width_top = passive_border
	style.border_width_bottom = passive_border
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	if elevated:
		style.shadow_color = Color(0.0, 0.0, 0.0, 0.34 if dark_mode_enabled else 0.16)
		style.shadow_size = 12
		style.shadow_offset = Vector2(0, 8)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	return style
