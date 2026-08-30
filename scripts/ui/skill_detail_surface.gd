extends RefCounted

const BuildableModules = preload("res://scripts/gameplay/buildable_modules.gd")
const ActivityLockRig = preload("res://scripts/ui/activity_lock_rig.gd")
const ActivityUnlockCeremonySurface = preload("res://scripts/ui/activity_unlock_ceremony_surface.gd")
const ActivityLockCluster = preload("res://scripts/ui/activity_lock_cluster.gd")
const ActivityCardBorder = preload("res://scripts/ui/activity_card_border.gd")
const ActivityCardDepth = preload("res://scripts/ui/activity_card_depth.gd")
const ActivityCardStyles = preload("res://scripts/ui/activity_card_styles.gd")
const ActivityProgressRail = preload("res://scripts/ui/activity_progress_rail.gd")
const ActionArtUi = preload("res://scripts/ui/action_art_ui.gd")
const BlueGuyChickenBrawlStageClass = preload("res://scripts/ui/blue_guy_chicken_brawl_stage.gd")
const CleanProgressBar = preload("res://scripts/ui/clean_progress_bar.gd")
const ConvergenceMultiProgressBar = preload("res://scripts/ui/convergence_multi_progress_bar.gd")
const ConvergenceRuntime = preload("res://scripts/gameplay/convergence_runtime.gd")
const FishCircle = preload("res://scripts/ui/fish_circle.gd")
const FishingState = preload("res://scripts/fishing/state.gd")
const GameFormatting = preload("res://scripts/core/formatting.gd")
const MaterialRuntime = preload("res://scripts/materials/runtime.gd")
const MobileScrollContainer = preload("res://scripts/ui/mobile_scroll_container.gd")
const ModuleUiRuntime = preload("res://scripts/module_ui/runtime.gd")
const NavigationShell = preload("res://scripts/ui/navigation_shell.gd")
const OnboardingRuntime = preload("res://scripts/tutorial/onboarding_runtime.gd")
const ProfileChatOverlaySurface = preload("res://scripts/ui/profile_chat_overlay_surface.gd")
const MasteryState = preload("res://scripts/progression/mastery_state.gd")
const AchievementPresentation = preload("res://scripts/achievements/presentation.gd")
const PassiveFirepitSurface = preload("res://scripts/ui/passive_firepit_surface.gd")
const PassiveModulesRuntime = preload("res://scripts/gameplay/passive_modules_runtime.gd")
const PassiveModuleStyles = preload("res://scripts/ui/passive_module_styles.gd")
const PaperButtonStyles = preload("res://scripts/ui/paper_button_styles.gd")
const RegenCircle = preload("res://scripts/ui/regen_circle.gd")
const AchievementState = preload("res://scripts/achievements/state.gd")
const RoundedTextureRect = preload("res://scripts/ui/rounded_texture_rect.gd")
const RoosterPunchOutStage = preload("res://scripts/ui/rooster_punch_out_stage.gd")
const RecoveryModules = preload("res://scripts/gameplay/recovery_modules.gd")
const SkillIconBadge = preload("res://scripts/ui/skill_icon_badge.gd")
const SkillState = preload("res://scripts/progression/skill_state.gd")

const BETA_NOTICE_HEIGHT := 710.0

class _GradientShelf extends Control:
	var top_color := Color("#f6cfd0")
	var bottom_color := Color("#bd5f5a")

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func set_colors(next_top_color: Color, next_bottom_color: Color) -> void:
		top_color = next_top_color
		bottom_color = next_bottom_color
		queue_redraw()

	func _draw() -> void:
		if size.x <= 1.0 or size.y <= 1.0:
			return
		var line_count := maxi(1, int(ceil(size.y)))
		for i in range(line_count):
			var y := float(i)
			var t := y / maxf(1.0, size.y - 1.0)
			var bottom_weight := smoothstep(0.68, 1.0, t)
			var color := top_color.lerp(bottom_color, bottom_weight)
			draw_line(Vector2(0.0, y), Vector2(size.x, y), color, 1.0, false)


class _PageShelfShadow extends Control:
	var shadow_height := 54.0
	var shadow_color := Color(0.04, 0.035, 0.03, 0.18)
	var shadow_alpha := 1.0

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func set_shadow_alpha(next_alpha: float) -> void:
		var clamped := clampf(next_alpha, 0.0, 1.0)
		if absf(shadow_alpha - clamped) <= 0.001:
			return
		shadow_alpha = clamped
		queue_redraw()

	func _draw() -> void:
		if size.x <= 1.0 or size.y <= 1.0:
			return
		var lines := int(minf(28.0, size.y))
		var step_y := minf(shadow_height, size.y) / maxf(1.0, float(lines))
		var border_alpha := shadow_color.a * shadow_alpha * 0.92
		draw_line(Vector2(0.0, 0.0), Vector2(size.x, 0.0), Color(shadow_color.r, shadow_color.g, shadow_color.b, border_alpha), 3.0, false)
		for i in range(lines):
			var depth := float(i) / maxf(1.0, float(lines - 1))
			var core := 1.0 - smoothstep(0.0, 0.18, depth)
			var feather := pow(1.0 - depth, 2.05)
			var alpha := shadow_color.a * shadow_alpha * maxf(core * 0.50, feather * 0.46)
			var y := 2.0 + float(i) * step_y
			draw_line(Vector2(0.0, y), Vector2(size.x, y), Color(shadow_color.r, shadow_color.g, shadow_color.b, alpha), step_y + 2.0, false)


class _DiamondArenaFrame extends Control:
	var fill_color := Color(0.16, 0.08, 0.08, 0.16)
	var border_color := Color("#171615")
	var accent_color := Color("#ffe56b")
	var ui_plate_color := Color("#8e1115")
	var border_width := 12.0
	var accent_width := 5.0
	var inset := 12.0
	var side_inset := 16.0

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func _draw() -> void:
		if size.x <= 4.0 or size.y <= 4.0:
			return
		var diamond := _rounded_diamond_points(_diamond_points(), 72.0, 10)
		var top := diamond[0]
		var closed := PackedVector2Array(diamond)
		closed.append(top)
		draw_polyline(closed, border_color, border_width, true)

	func _diamond_points(extra_inset := 0.0) -> PackedVector2Array:
		var safe_inset := maxf(0.0, inset + extra_inset)
		var safe_side_inset := maxf(0.0, side_inset + extra_inset)
		var center := size * 0.5
		return PackedVector2Array([
			Vector2(center.x, safe_inset),
			Vector2(size.x - safe_side_inset, center.y),
			Vector2(center.x, size.y - safe_inset),
			Vector2(safe_side_inset, center.y),
		])

	func _rounded_diamond_points(points: PackedVector2Array, corner_radius: float, segments: int) -> PackedVector2Array:
		var rounded := PackedVector2Array()
		if points.size() < 4:
			return points
		var safe_segments := maxi(2, segments)
		for i in range(points.size()):
			var previous := points[(i - 1 + points.size()) % points.size()]
			var corner := points[i]
			var next := points[(i + 1) % points.size()]
			var cut := minf(corner_radius, minf(corner.distance_to(previous), corner.distance_to(next)) * 0.34)
			var start := corner.move_toward(previous, cut)
			var finish := corner.move_toward(next, cut)
			for step in range(safe_segments + 1):
				var t := float(step) / float(safe_segments)
				var a := start.lerp(corner, t)
				var b := corner.lerp(finish, t)
				rounded.append(a.lerp(b, t))
		return rounded


class ModuleActionCircleZone extends Control:
	func _has_point(point: Vector2) -> bool:
		var radius := minf(size.x, size.y) * 0.5
		return point.distance_to(size * 0.5) <= radius


class ModuleCollapseMinusGlyph extends Control:
	var line_color := Color("#171615")
	var line_width := 14.0

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func _draw() -> void:
		if size.x <= 1.0 or size.y <= 1.0:
			return
		var y := size.y * 0.5
		var inset := size.x * 0.26
		draw_line(Vector2(inset, y), Vector2(size.x - inset, y), line_color, line_width, true)
		draw_circle(Vector2(inset, y), line_width * 0.5, line_color)
		draw_circle(Vector2(size.x - inset, y), line_width * 0.5, line_color)


class TierPlaque extends TextureRect:
	var tier := 1:
		set(value):
			tier = clampi(value, 1, 22)
			_sync_texture()

	func _ready() -> void:
		expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_sync_texture()

	func _sync_texture() -> void:
		texture = load("res://assets/content/ui/tier-plaques/tier-plaque-%02d.png" % tier)


class BuildableModuleOverlay:
	static func build(parent: Control, title_text: String, meta_text: String, button_text: String, can_afford: bool, ink_color: Color, bold_font: Font, regular_font: Font, body_font_size: int, plank_textures: Array = [], cost: Dictionary = {}, cost_icon_paths: Dictionary = {}) -> Dictionary:
		if parent == null:
			return {}
		var overlay := rounded_panel(Color("#1d6f82", 0.88), 66, 66, 66, 66)
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.z_index = 239
		overlay.z_as_relative = false
		parent.add_child(overlay)

		var plank_layer: Control = null
		var plank_nodes := []
		if not plank_textures.is_empty():
			plank_layer = Control.new()
			plank_layer.name = "BuildRequiredPlankLayer"
			plank_layer.anchor_left = 0.0
			plank_layer.anchor_right = 1.0
			plank_layer.anchor_top = 0.5
			plank_layer.anchor_bottom = 0.5
			plank_layer.offset_left = 20
			plank_layer.offset_right = -20
			plank_layer.offset_top = -124
			plank_layer.offset_bottom = 314
			plank_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
			plank_layer.z_index = 700
			plank_layer.z_as_relative = false
			parent.add_child(plank_layer)

			var single_plank := plank_textures.size() == 1
			var layouts := [{"top": -26.0, "height": 490.0, "left": -18.0, "right": 18.0}] if single_plank else [
				{"top": 28.0, "height": 126.0, "left": 92.0, "right": -92.0},
				{"top": 156.0, "height": 168.0, "left": 54.0, "right": -54.0},
				{"top": 326.0, "height": 120.0, "left": 112.0, "right": -112.0}
			]
			for index in range(mini(plank_textures.size(), layouts.size())):
				var texture := plank_textures[index] as Texture2D
				if texture == null:
					continue
				var layout := layouts[index] as Dictionary
				var top := float(layout.get("top", 0.0))
				var height := float(layout.get("height", 120.0))
				var shadow := Panel.new()
				shadow.name = "BuildRequiredBoardShadow%02d" % [index + 1]
				shadow.anchor_left = 0.0
				shadow.anchor_right = 1.0
				shadow.offset_left = float(layout.get("left", 0.0)) + 24.0
				shadow.offset_right = float(layout.get("right", 0.0)) - 24.0
				shadow.offset_top = top + 28.0
				shadow.offset_bottom = top + height + 36.0
				var shadow_style := StyleBoxFlat.new()
				shadow_style.bg_color = Color(0, 0, 0, 0.01)
				shadow_style.corner_radius_top_left = 86
				shadow_style.corner_radius_top_right = 86
				shadow_style.corner_radius_bottom_left = 86
				shadow_style.corner_radius_bottom_right = 86
				shadow_style.shadow_color = Color(0, 0, 0, 0.24)
				shadow_style.shadow_size = 22
				shadow_style.shadow_offset = Vector2(0, 10)
				shadow.add_theme_stylebox_override("panel", shadow_style)
				shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
				shadow.z_index = index * 2
				plank_layer.add_child(shadow)
				var plank := TextureRect.new()
				plank.name = "BuildRequiredBoardPiece%02d" % [index + 1]
				plank.texture = texture
				plank.anchor_left = 0.0
				plank.anchor_right = 1.0
				plank.offset_left = float(layout.get("left", 0.0))
				plank.offset_right = float(layout.get("right", 0.0))
				plank.offset_top = top
				plank.offset_bottom = top + height
				plank.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				plank.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED if single_plank else TextureRect.STRETCH_KEEP_ASPECT_COVERED
				plank.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
				plank.mouse_filter = Control.MOUSE_FILTER_IGNORE
				plank.z_index = index * 2 + 1
				plank_layer.add_child(plank)
				plank_nodes.append(plank)

		var cta := PanelContainer.new()
		cta.custom_minimum_size = Vector2(1040, 300)
		cta.anchor_left = 0.5
		cta.anchor_right = 0.5
		cta.anchor_top = 0.5
		cta.anchor_bottom = 0.5
		cta.offset_left = -520
		cta.offset_right = 520
		cta.offset_top = -64
		cta.offset_bottom = 190
		cta.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cta.z_index = 730
		cta.z_as_relative = false
		cta.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		parent.add_child(cta)

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 28)
		margin.add_theme_constant_override("margin_right", 28)
		margin.add_theme_constant_override("margin_top", 18)
		margin.add_theme_constant_override("margin_bottom", 18)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cta.add_child(margin)

		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 24)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(row)

		var text_stack := VBoxContainer.new()
		text_stack.alignment = BoxContainer.ALIGNMENT_CENTER
		text_stack.add_theme_constant_override("separation", 2)
		text_stack.custom_minimum_size = Vector2(560, 204)
		text_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(text_stack)

		var meta: Label = null
		var cost_heading: Label = null
		var cost_rows := []
		if cost.is_empty():
			meta = label(meta_text, maxi(body_font_size, 82), Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, bold_font, regular_font)
			meta.add_theme_color_override("font_outline_color", ink_color)
			meta.add_theme_constant_override("outline_size", 30)
			meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			text_stack.add_child(meta)
		else:
			cost_heading = label("COST", maxi(body_font_size, 96), Color.BLACK, HORIZONTAL_ALIGNMENT_CENTER, bold_font, regular_font)
			cost_heading.add_theme_constant_override("outline_size", 0)
			cost_heading.add_theme_font_size_override("font_size", maxi(body_font_size, 96))
			text_stack.add_child(cost_heading)
			var underline := ColorRect.new()
			underline.color = Color.BLACK
			underline.custom_minimum_size = Vector2(300, 14)
			underline.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			underline.mouse_filter = Control.MOUSE_FILTER_IGNORE
			text_stack.add_child(underline)
			for raw_mat_id in cost.keys():
				var mat_id := str(raw_mat_id)
				var amount := float(cost.get(raw_mat_id, 0.0))
				if amount <= 0.0:
					continue
				var cost_row := HBoxContainer.new()
				cost_row.alignment = BoxContainer.ALIGNMENT_CENTER
				cost_row.add_theme_constant_override("separation", 28)
				cost_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
				text_stack.add_child(cost_row)
				var icon_path := str(cost_icon_paths.get(mat_id, ""))
				if not icon_path.is_empty():
					var icon := TextureRect.new()
					icon.name = "BuildCostIcon_%s" % mat_id
					icon.texture = load(icon_path) as Texture2D
					icon.custom_minimum_size = Vector2(134, 134)
					icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
					icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					icon.mouse_filter = Control.MOUSE_FILTER_STOP
					icon.pivot_offset = Vector2(67, 67)
					_wire_cost_icon_feedback(parent, icon, mat_id, bold_font, regular_font)
					cost_row.add_child(icon)
				var amount_text := "%d" % int(round(amount)) if is_equal_approx(amount, round(amount)) else str(amount)
				var amount_label := label(amount_text, maxi(body_font_size, 118), Color.BLACK, HORIZONTAL_ALIGNMENT_CENTER, bold_font, regular_font)
				amount_label.add_theme_constant_override("outline_size", 0)
				cost_row.add_child(amount_label)
				cost_rows.append(cost_row)

		return {
			"build_overlay": overlay,
			"build_progress_cover": null,
			"build_title_backing": null,
			"build_plank_layer": plank_layer,
			"build_plank_nodes": plank_nodes,
			"build_cta": cta,
			"build_title_row": null,
			"build_button_panel": null,
			"build_module_title": null,
			"build_cta_title": null,
			"build_cta_meta": meta,
			"build_cost_heading": cost_heading,
			"build_cost_rows": cost_rows,
		}

	static func label(text: String, font_size: int, color: Color, align: HorizontalAlignment, bold_font: Font, regular_font: Font) -> Label:
		var node := Label.new()
		node.text = text
		node.horizontal_alignment = align
		node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.add_theme_font_size_override("font_size", font_size)
		node.add_theme_color_override("font_color", color)
		if bold_font != null:
			node.add_theme_font_override("font", bold_font)
		elif regular_font != null:
			node.add_theme_font_override("font", regular_font)
		return node

	static func _wire_cost_icon_feedback(root: Control, icon: Control, mat_id: String, bold_font: Font, regular_font: Font) -> void:
		icon.gui_input.connect(Callable(BuildableModuleOverlay, "_on_cost_icon_gui_input").bind(root, icon, mat_id, bold_font, regular_font))

	static func _on_cost_icon_gui_input(event: InputEvent, root: Control, icon: Control, mat_id: String, bold_font: Font, regular_font: Font) -> void:
		var pressed := false
		if event is InputEventMouseButton:
			pressed = (event as InputEventMouseButton).pressed
		elif event is InputEventScreenTouch:
			pressed = (event as InputEventScreenTouch).pressed
		if not pressed:
			return
		icon.accept_event()
		_play_cost_icon_feedback(root, icon, _resource_display_name(mat_id), bold_font, regular_font)

	static func _play_cost_icon_feedback(root: Control, icon: Control, text: String, bold_font: Font, regular_font: Font) -> void:
		if root == null or icon == null or not is_instance_valid(root) or not is_instance_valid(icon):
			return
		var existing = icon.get_meta("build_cost_icon_tween", null)
		if existing is Tween and (existing as Tween).is_valid():
			(existing as Tween).kill()
		icon.scale = Vector2.ONE
		var tween := icon.create_tween()
		icon.set_meta("build_cost_icon_tween", tween)
		tween.tween_property(icon, "scale", Vector2(1.22, 1.22), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(icon, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		var popup := label(text, 58, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, bold_font, regular_font)
		popup.add_theme_color_override("font_outline_color", Color.BLACK)
		popup.add_theme_constant_override("outline_size", 12)
		popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
		popup.z_index = 900
		popup.z_as_relative = false
		popup.size = Vector2(360, 80)
		var root_to_canvas := root.get_global_transform_with_canvas().affine_inverse()
		var icon_center := icon.get_global_transform_with_canvas() * (icon.size * 0.5)
		popup.position = root_to_canvas * icon_center - Vector2(180, 116)
		root.add_child(popup)
		var start := popup.position
		var float_tween := popup.create_tween()
		float_tween.tween_property(popup, "position", start + Vector2(0, -84), 0.62).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		float_tween.parallel().tween_property(popup, "modulate:a", 0.0, 0.62).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		float_tween.finished.connect(Callable(BuildableModuleOverlay, "_finish_cost_icon_popup").bind(popup))

	static func _finish_cost_icon_popup(popup: Control) -> void:
		if popup != null and is_instance_valid(popup):
			popup.queue_free()

	static func _resource_display_name(mat_id: String) -> String:
		return mat_id.replace("_", " ").capitalize()

	static func rounded_panel(color: Color, top_left: int, top_right: int, bottom_left: int, bottom_right: int) -> Panel:
		var panel := Panel.new()
		var style := StyleBoxFlat.new()
		style.bg_color = color
		style.corner_radius_top_left = top_left
		style.corner_radius_top_right = top_right
		style.corner_radius_bottom_left = bottom_left
		style.corner_radius_bottom_right = bottom_right
		panel.add_theme_stylebox_override("panel", style)
		return panel

	static func cta_style(can_afford: bool, ink_color: Color, art_backed := false) -> StyleBoxFlat:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#2f8f58") if can_afford else Color("#9a6330")
		style.border_color = ink_color
		style.set_border_width_all(12)
		style.corner_radius_top_left = 34
		style.corner_radius_top_right = 34
		style.corner_radius_bottom_left = 34
		style.corner_radius_bottom_right = 34
		style.shadow_color = Color(0, 0, 0, 0.34)
		style.shadow_size = 10
		style.shadow_offset = Vector2(0, 8)
		if art_backed:
			style.bg_color = Color("#f2c33d") if can_afford else Color("#c08c2f")
		return style


class ConvergenceBuildOverlay:
	static func build(parent: Control, overlay_color: Color, ink_color: Color, bold_font: Font, regular_font: Font, body_font_size: int) -> Dictionary:
		if parent == null:
			return {}
		var overlay := ColorRect.new()
		overlay.color = overlay_color
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.z_index = 231
		parent.add_child(overlay)

		var overlay_label := label("", 86, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, bold_font, regular_font)
		overlay_label.add_theme_color_override("font_outline_color", ink_color)
		overlay_label.add_theme_constant_override("outline_size", 26)
		overlay_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		overlay_label.z_index = 232
		parent.add_child(overlay_label)

		var cta := PanelContainer.new()
		cta.custom_minimum_size = Vector2(620, 210)
		cta.anchor_left = 0.5
		cta.anchor_right = 0.5
		cta.anchor_top = 0.5
		cta.anchor_bottom = 0.5
		cta.offset_left = -310
		cta.offset_right = 310
		cta.offset_top = -105
		cta.offset_bottom = 105
		cta.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cta.z_index = 233
		cta.add_theme_stylebox_override("panel", cta_style(ink_color))
		parent.add_child(cta)

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 34)
		margin.add_theme_constant_override("margin_right", 34)
		margin.add_theme_constant_override("margin_top", 24)
		margin.add_theme_constant_override("margin_bottom", 24)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cta.add_child(margin)

		var stack := VBoxContainer.new()
		stack.alignment = BoxContainer.ALIGNMENT_CENTER
		stack.add_theme_constant_override("separation", 8)
		stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(stack)

		var title := label("BUILD SHRINE", 72, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, bold_font, regular_font)
		title.add_theme_color_override("font_outline_color", ink_color)
		title.add_theme_constant_override("outline_size", 18)
		stack.add_child(title)

		var meta := label("", body_font_size, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, bold_font, regular_font)
		meta.add_theme_color_override("font_outline_color", ink_color)
		meta.add_theme_constant_override("outline_size", 12)
		stack.add_child(meta)

		return {
			"convergence_overlay": overlay,
			"convergence_overlay_label": overlay_label,
			"convergence_build_cta": cta,
			"convergence_build_cta_title": title,
			"convergence_build_cta_meta": meta,
		}

	static func label(text: String, font_size: int, color: Color, align: HorizontalAlignment, bold_font: Font, regular_font: Font) -> Label:
		var node := Label.new()
		node.text = text
		node.horizontal_alignment = align
		node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.add_theme_font_size_override("font_size", font_size)
		node.add_theme_color_override("font_color", color)
		if bold_font != null:
			node.add_theme_font_override("font", bold_font)
		elif regular_font != null:
			node.add_theme_font_override("font", regular_font)
		return node

	static func cta_style(ink_color: Color) -> StyleBoxFlat:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#2f8f58")
		style.border_color = ink_color
		style.set_border_width_all(8)
		style.corner_radius_top_left = 34
		style.corner_radius_top_right = 34
		style.corner_radius_bottom_left = 34
		style.corner_radius_bottom_right = 34
		style.shadow_color = Color(0, 0, 0, 0.34)
		style.shadow_size = 10
		style.shadow_offset = Vector2(0, 8)
		return style

const RECOVERY_WIDE_U_BOTTOM_RISE := ActivityCardStyles.RECOVERY_WIDE_U_BOTTOM_RISE
const RECOVERY_WIDE_U_SHOULDER_RATIO := ActivityCardStyles.RECOVERY_WIDE_U_SHOULDER_RATIO
const NORMAL_ACTIVITY_PROGRESS_HEIGHT := 112.0
const CONVERGENCE_BAR_HEIGHT := 156
const CONVERGENCE_BUILD_OVERLAY_COLOR := Color(0.10, 0.08, 0.06, 0.58)
const CONVERGENCE_UNBUILT_CARD_TINT := Color(0.78, 0.70, 0.58, 1.0)
const MODULE_ACTION_ZONE_SIZE := Vector2(170, 170)
const MODULE_ACTION_ZONE_TOP_OFFSET := -52.0
const MODULE_ACTION_ZONE_OUTER_OFFSET := -42.0
const MODULE_COLLAPSE_ACTION_ZONE_SIZE := Vector2(174, 174)
const MODULE_COLLAPSE_ACTION_ZONE_TOP_OFFSET := -30.0
const MODULE_COLLAPSE_ACTION_ZONE_OUTER_OFFSET := -48.0
const MODULE_ACTION_ZONE_Z_INDEX := 920
const MODULE_COLLAPSE_BADGE_SIZE := Vector2(112, 112)
const MODULE_COLLAPSE_BADGE_POSITION := Vector2(-78, -58)
const MODULE_COLLAPSED_ROW_HEIGHT := 176.0
const MODULE_COLLAPSE_SQUEEZE_SECONDS := 0.34
const MODULE_COLLAPSED_TITLE_LIFT_Y := -24.0
const DETAIL_PULL_TIP_FONT_SIZE := 62
const DETAIL_PULL_TIP_HEIGHT := 188.0
const DETAIL_PULL_TIP_TRIGGER_OFFSET := 92.0
const DETAIL_PULL_TIP_FULL_OFFSET := 210.0
const DETAIL_LAZY_TIP_HEIGHT := 174.0
const DETAIL_LAZY_VIEWPORT_BUFFER_PX := 120.0
const FISHING_DETAIL_LAZY_VIEWPORT_BUFFER_PX := 120.0
const DETAIL_LAZY_BOOT_VIEWPORT_BUFFER_PX := 240.0
const DETAIL_LAZY_INITIAL_FORCE_MOUNT_COUNT := 2
const FISHING_DETAIL_LAZY_INITIAL_FORCE_MOUNT_COUNT := 4
const DETAIL_LAZY_BOOT_EAGER_COUNT := 2
const DETAIL_LAZY_BOOT_SLOT_BATCH_SIZE := 8
const BOOT_DETAIL_COMPLETE_BUDGET_PER_FRAME := 3
const DETAIL_LAZY_MOUNT_BUDGET_PER_FRAME := 1
const DETAIL_LAZY_UNMOUNT_ENABLED := true
const DETAIL_LAZY_UNMOUNT_BUFFER_PX := 180.0
const FISHING_DETAIL_LAZY_UNMOUNT_BUFFER_PX := 180.0
const DETAIL_LAZY_UNMOUNT_BUDGET_PER_FRAME := 2
const DETAIL_LAZY_SETTLE_WARM_MOUNT_ENABLED := false
const DETAIL_LAZY_SETTLE_WARM_MOUNT_BUDGET_PER_FRAME := 1
const FISHING_DETAIL_LAZY_SETTLE_WARM_MOUNT_BUDGET_PER_FRAME := 1
const DETAIL_LAZY_FADE_IN_SECONDS := 0.28
const DETAIL_LAZY_SLIDE_IN_OFFSET_Y := 24.0
const DETAIL_LAZY_SCALE_IN_AMOUNT := 0.985
const DETAIL_LAZY_STACK_SEPARATION := 56.0
const DETAIL_LAZY_WINDOW_SYNC_INTERVAL_SECONDS := 0.035
const ACTIVITY_JUMP_TOP_TEXTURE := "res://assets/content/ui/activity-jump-top-circle.png"
const ACTIVITY_JUMP_BOTTOM_TEXTURE := "res://assets/content/ui/activity-jump-bottom-circle.png"
const ACTIVITY_JUMP_ARROW_SIZE := Vector2(296, 296)
const ACTIVITY_JUMP_ARROW_EDGE_INSET := 28.0
const ACTIVITY_JUMP_ARROW_BOTTOM_EDGE_INSET := 690.0
const ACTIVITY_JUMP_ARROW_LINGER_SECONDS := 1.2
const ACTIVITY_JUMP_ARROW_FADE_IN_SECONDS := 0.10
const ACTIVITY_JUMP_ARROW_FADE_OUT_SECONDS := 0.22
const ACTIVITY_JUMP_ARROW_EDGE_EPSILON := 6
const ACTIVITY_JUMP_ARROW_MIN_MODULES := 4
const ACTIVITY_JUMP_ARROW_LANDING_PREFILL_BUFFER_PX := 420.0
const ACTIVITY_BACK_TEXTURE := "res://assets/content/ui/activity-back-arrow.png"
const ACTIVITY_BACK_BUTTON_SIZE := Vector2(460, 140)
const ACTIVITY_BACK_ARROW_SIZE := Vector2(250, 74)
const DETAIL_PULL_TIP_TEXTS := [
	"tip: tap the top right corner of an activity to collapse it.",
	"tip: tap the top left corner of an activity to pin it into the Pins page.",
	"tip: you can collapse activities by pressing the top right.",
	"tip: you can expand collapsed activities by clicking anywhere on them.",
	"tip: use the sort button to change how activities are ordered.",
	"tip: hold info chips to see what is changing an activity's stats.",
	"tip: XP, stamina, time, and rate chips can explain their bonuses.",
	"tip: info chips show details like badge boosts, mission boosts, and other stat changes.",
	"tip: tap earned medals to see their celebration animation again.",
	"tip: training a combo skill is great XP without spending that skill's stamina.",
	"tip: toggle the fish button at the top left of the stamina gauge to automatically eat fish.",
	"tip: pinned activities stay easy to reach from the Pins page.",
	"tip: high-level sort puts your newest challenges closer to the top.",
	"tip: low-level sort makes it easier to clean up older medals.",
	"tip: combo activities can train two skills at once.",
	"tip: rating the game five stars will make the dev very happy.",
	"tip: badge boosts are strongest next door and fade with distance.",
	"tip: badges on lower activities can make the next few activities cost less stamina and finish faster.",
	"tip: badges on higher activities can give earlier activities more success rate and lower stamina cost."
]

var host
var skill_detail_layout_refresh_hold_until_msec := 0
var detail_jump_top_button: TextureButton
var detail_jump_bottom_button: TextureButton
var detail_jump_top_hold := 0.0
var detail_jump_bottom_hold := 0.0
var detail_jump_top_hovered := false
var detail_jump_bottom_hovered := false
var detail_jump_press_direction := 0
var detail_jump_press_touch_index := -1
var detail_back_button: BaseButton
var detail_back_press_active := false
var detail_back_press_touch_index := -1
var detail_pull_tip_root: Control
var detail_pull_tip_label: Label
var detail_pull_tip_active := false
var detail_pull_tip_direction := 0
var detail_pull_recent_tip_texts: Array = []
var detail_texture_prewarm_skill_id := ""
var detail_texture_prewarm_request_queue: Array = []
var detail_texture_prewarm_pending := {}
var detail_rendered_action_ids := []
var detail_lazy_plan: Array = []
var detail_lazy_last_scroll := -1.0
var detail_lazy_window_sync_elapsed := 0.0
var detail_lazy_stack: VBoxContainer = null
var detail_lazy_mounted_this_frame := false
var detail_lazy_all_mounted_cache_frame := -1
var detail_lazy_all_mounted_cache_value := false
var detail_lazy_render_cull_last_scroll := -999999.0
var detail_lazy_render_cull_last_msec := 0
var detail_lazy_mount_trace_context := ""
var detail_lazy_settle_warm_mount_skill_id := ""
var detail_lazy_refresh_token := 0
var detail_lazy_cache_bin: Control = null
var detail_lazy_blank_repair_next_msec := 0
var expanded_activity_stat_key := ""
var expanded_activity_stat_kind := ""
var expanded_tier_banner_key := ""
var last_activity_stat_toggle_key := ""
var last_activity_stat_toggle_kind := ""
var last_activity_stat_toggle_msec := 0
var detail_shelf_shadow_overlay: Control
var detail_shelf_shadow_alpha := 0.0


func _module_collapsed_squeeze_height() -> float:
	return MODULE_COLLAPSED_ROW_HEIGHT


func _hold_skill_detail_layout_refresh(seconds := 0.12) -> void:
	skill_detail_layout_refresh_hold_until_msec = maxi(
		skill_detail_layout_refresh_hold_until_msec,
		Time.get_ticks_msec() + int(ceil(maxf(0.0, seconds) * 1000.0))
	)


func _hold_skill_detail_layout_refresh_after_navigation() -> void:
	_hold_skill_detail_layout_refresh(host.SKILL_SWIPE_SETTLE_SECONDS + 0.35)


func _skill_detail_layout_refresh_held() -> bool:
	return Time.get_ticks_msec() < skill_detail_layout_refresh_hold_until_msec


func _detail_card_texture_paths_for_skill(skill_id: String) -> Array:
	var paths := []
	var boot_warmup = host._boot_warmup_runtime()
	boot_warmup._add_boot_warmup_texture_path(paths, SkillIconBadge.icon_path(skill_id))
	if skill_id == "fishing":
		host._fishing_ui_surface()._add_fishing_detail_visual_texture_paths(paths)
	for raw_entry in _visible_detail_entries_for_skill(skill_id):
		var entry := raw_entry as Dictionary
		if str(entry.get("kind", "")) == "thieving_heist":
			for raw_path in host._thieving_surface().warmup_texture_paths():
				boot_warmup._add_boot_warmup_texture_path(paths, str(raw_path))
			continue
		var action := entry.get("action", {}) as Dictionary
		if action.is_empty():
			continue
		boot_warmup._add_boot_warmup_texture_path(paths, str(action.get("art", "")))
		boot_warmup._add_boot_warmup_texture_path(paths, str(action.get("bg", "")))
		if skill_id == "fishing":
			var action_id := str(action.get("id", ""))
			if FishingState.FISHING_ACTION_CATCH_TEXTURE_PATHS.has(action_id):
				boot_warmup._add_boot_warmup_texture_path(paths, FishingState.FISHING_ACTION_CATCH_TEXTURE_PATHS[action_id])
	return paths


func _queue_detail_card_texture_prewarm(skill_id: String) -> void:
	_prewarm_detail_card_style_resources()
	detail_texture_prewarm_skill_id = skill_id
	detail_texture_prewarm_pending.clear()
	detail_texture_prewarm_request_queue = host.visual_texture_cache._uncached_texture_paths(_detail_card_texture_paths_for_skill(skill_id))


func _queue_skill_detail_and_swipe_texture_prewarm(skill_id: String) -> void:
	_prewarm_detail_card_style_resources()
	if not host.SKILL_SWIPE_REAL_PREVIEW_TEXTURE_PREWARM_ENABLED:
		_queue_detail_card_texture_prewarm(skill_id)
		return
	var paths := []
	var boot_warmup = host._boot_warmup_runtime()
	for raw_path in _detail_card_texture_paths_for_skill(skill_id):
		boot_warmup._add_boot_warmup_texture_path(paths, str(raw_path))
	if host.selected_skill_id == skill_id:
		for offset in [-1, 1]:
			if not host._onboarding_runtime()._swipe_offset_accessible(offset):
				continue
			var preview_skill_id: String = host._skill_swipe_activity_surface()._skill_id_for_swipe_offset(offset)
			if preview_skill_id.is_empty() or preview_skill_id == skill_id:
				continue
			for raw_path in _detail_card_texture_paths_for_skill(preview_skill_id):
				boot_warmup._add_boot_warmup_texture_path(paths, str(raw_path))
	detail_texture_prewarm_skill_id = skill_id
	detail_texture_prewarm_pending.clear()
	detail_texture_prewarm_request_queue = host.visual_texture_cache._uncached_texture_paths(paths)


func _visible_action_entries_for_skill(skill_id: String) -> Array:
	var entries := []
	for raw_action in host._activity_unlock_runtime()._visible_actions_for_skill(skill_id):
		entries.append({"kind": "action", "action": raw_action as Dictionary})
	for raw_event_action in host._temporary_event_runtime()._active_event_actions_for_skill(skill_id):
		entries.append({"kind": "action", "action": raw_event_action as Dictionary})
	if entries.size() > 1:
		entries.sort_custom(func(left, right):
			if typeof(left) != TYPE_DICTIONARY:
				return false
			if typeof(right) != TYPE_DICTIONARY:
				return true
			var left_action := (left as Dictionary).get("action", {}) as Dictionary
			var right_action := (right as Dictionary).get("action", {}) as Dictionary
			return host.activity_data_catalog.activity_action_display_sort_less(left_action, right_action)
		)
	return entries


func _detail_entry_level_sort_value(entry: Dictionary, skill_id: String) -> int:
	match str(entry.get("kind", "action")):
		"thieving_heist":
			return maxi(1, int((entry.get("heist", {}) as Dictionary).get("unlock", 1)))
		"fishing_area":
			return host._fishing_ui_surface().render_module_unlock(entry.get("area_def", {}) as Dictionary)
		"fishing_offer":
			return host._fishing_ui_surface()._fishing_offer_unlock_level(str(entry.get("offer_id", "")))
		_:
			return host.activity_data_catalog.activity_action_display_sort_level(entry.get("action", {}) as Dictionary)


func _visible_detail_entries_for_skill(skill_id: String) -> Array:
	var entries := []
	var pending_heists: Array = host.thieving_state.visible_heists_for_render() if skill_id == "thieving" else []
	var heist_index := 0
	for raw_entry in _visible_action_entries_for_skill(skill_id):
		var entry := raw_entry as Dictionary
		var action := entry.get("action", {}) as Dictionary
		if host._onboarding_runtime()._tutorial_starter_only_detail_active(skill_id) and str(action.get("id", "")) != host.TUTORIAL_STARTER_ACTION_ID:
			continue
		var action_sort_unlock: int = host.activity_data_catalog.activity_action_display_sort_level(action)
		while heist_index < pending_heists.size() and int((pending_heists[heist_index] as Dictionary).get("unlock", 1)) <= action_sort_unlock:
			entries.append({"kind": "thieving_heist", "heist": pending_heists[heist_index]})
			heist_index += 1
		entries.append(entry)
	while heist_index < pending_heists.size():
		entries.append({"kind": "thieving_heist", "heist": pending_heists[heist_index]})
		heist_index += 1
	var sorted_entries: Array = host.module_ui_runtime.sort_detail_entries(
		entries,
		skill_id,
		Callable(self, "_detail_entry_level_sort_value"),
		Callable(host._activity_unlock_runtime(), "_action_unlock_requirements")
	)
	var rendered_entries := _insert_tier_banners(skill_id, sorted_entries)
	if skill_id != "fight" and _beta_notice_unlocked():
		rendered_entries.append({"kind": "beta_notice"})
	return rendered_entries


func _beta_notice_unlocked() -> bool:
	for raw_skill_id in host.actions_by_skill.keys():
		var skill_id := str(raw_skill_id)
		if skill_id == "fight":
			continue
		var final_action := {}
		for raw_action in host.actions_by_skill.get(skill_id, []):
			var action := raw_action as Dictionary
			if final_action.is_empty() or host.activity_data_catalog.activity_action_display_sort_level(action) > host.activity_data_catalog.activity_action_display_sort_level(final_action):
				final_action = action
		if final_action.is_empty() or not host._activity_unlock_runtime()._is_action_unlocked(skill_id, final_action):
			return false
	return true


func _insert_tier_banners(skill_id: String, sorted_entries: Array) -> Array:
	var entries := []
	var previous_tier := -1
	for raw_entry in sorted_entries:
		var entry := raw_entry as Dictionary
		var tier := AchievementState.action_tier(host, entry.get("action", {}) as Dictionary) if str(entry.get("kind", "action")) == "action" else _tier_for_detail_entry(entry, skill_id)
		if previous_tier > 0 and tier > previous_tier:
			for banner_tier in range(previous_tier, tier):
				entries.append({"kind": "tier_banner", "skill_id": skill_id, "tier": banner_tier})
		entries.append(entry)
		if tier > 0:
			previous_tier = tier
	return entries


func _tier_for_detail_entry(entry: Dictionary, skill_id: String) -> int:
	var level := _detail_entry_level_sort_value(entry, skill_id)
	if level <= 0:
		return -1
	return int(floor(float(level - 1) / float(AchievementState.ACTIVITY_TIER_SIZE))) + 1


func _prewarm_detail_card_style_resources() -> void:
	_stat_box_style(false, false)
	_stat_box_style(false, true)
	_stat_box_style(true, false)
	_stat_box_style(true, true)
	ActivityCardStyles.cached_action_art(Callable(host, "_surface_style"))
	ActivityCardStyles.cached_action_art_border(Callable(host, "_surface_style"))
	ActivityCardStyles.cached_shade(0.50)


func _build_detail_pull_tip_overlay(parent: Control) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var root := Control.new()
	detail_pull_tip_root = root
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.visible = false
	root.modulate.a = 0.0
	root.z_index = 76
	parent.add_child(root)

	var label: Label = host._label("", DETAIL_PULL_TIP_FONT_SIZE, Color("#4b3828"), HORIZONTAL_ALIGNMENT_CENTER)
	detail_pull_tip_label = label
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.max_lines_visible = 2
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_position_detail_pull_tip_label(true, DETAIL_PULL_TIP_FULL_OFFSET)
	label.add_theme_color_override("font_outline_color", Color("#fff4ce"))
	label.add_theme_constant_override("outline_size", 10)
	label.add_theme_constant_override("line_spacing", -8)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(label)


func _position_detail_pull_tip_label(at_top: bool, pull_amount: float) -> void:
	if detail_pull_tip_label == null or not is_instance_valid(detail_pull_tip_label):
		return
	detail_pull_tip_label.anchor_left = 0.0
	detail_pull_tip_label.anchor_right = 1.0
	detail_pull_tip_label.offset_left = host.ACTION_CARD_POP_GUTTER
	detail_pull_tip_label.offset_right = -host.ACTION_CARD_POP_GUTTER
	var centered_top: float = pull_amount * 0.5 - DETAIL_PULL_TIP_HEIGHT * 0.5
	if at_top:
		detail_pull_tip_label.anchor_top = 0.0
		detail_pull_tip_label.anchor_bottom = 0.0
		detail_pull_tip_label.offset_top = centered_top
		detail_pull_tip_label.offset_bottom = centered_top + DETAIL_PULL_TIP_HEIGHT
	else:
		detail_pull_tip_label.anchor_top = 1.0
		detail_pull_tip_label.anchor_bottom = 1.0
		detail_pull_tip_label.offset_top = -centered_top - DETAIL_PULL_TIP_HEIGHT
		detail_pull_tip_label.offset_bottom = -centered_top


func _next_detail_pull_tip_text() -> String:
	if DETAIL_PULL_TIP_TEXTS.is_empty():
		return "tip: keep exploring."
	var candidates: Array = []
	for raw_tip in DETAIL_PULL_TIP_TEXTS:
		var tip := str(raw_tip)
		if not detail_pull_recent_tip_texts.has(tip):
			candidates.append(tip)
	if candidates.is_empty():
		for raw_tip in DETAIL_PULL_TIP_TEXTS:
			candidates.append(str(raw_tip))
	var tip_index := randi() % candidates.size()
	return str(candidates[tip_index])


func _record_detail_pull_tip_seen(tip_text: String) -> void:
	var normalized_tip := str(tip_text).strip_edges()
	if normalized_tip.is_empty():
		return
	detail_pull_recent_tip_texts.erase(normalized_tip)
	detail_pull_recent_tip_texts.append(normalized_tip)
	while detail_pull_recent_tip_texts.size() > 3:
		detail_pull_recent_tip_texts.pop_front()
	host._mark_save_dirty("detail pull tip seen")


func _detail_pull_tip_display_text(tip_text: String) -> String:
	var text := str(tip_text).strip_edges()
	if text.length() <= 42 or text.find("\n") >= 0:
		return text
	var target := text.length() / 2
	var best_index := -1
	var best_distance := 100000
	for i in range(text.length()):
		if text[i] != " ":
			continue
		if i < 12 or i > text.length() - 12:
			continue
		var distance := absi(i - target)
		if distance < best_distance:
			best_distance = distance
			best_index = i
	if best_index < 0:
		return text
	return "%s\n%s" % [text.substr(0, best_index), text.substr(best_index + 1)]


func _on_detail_actions_pull_offset_changed(offset_y: float) -> void:
	if host._action_stop_hold().active() and absf(offset_y) >= host.ACTION_CARD_SCROLL_DRAG_VISUAL_DEADZONE:
		host._action_stop_hold().cancel_action()
	if detail_pull_tip_root == null or not is_instance_valid(detail_pull_tip_root):
		detail_pull_tip_active = false
		return
	if host.current_screen != "skill":
		detail_pull_tip_root.visible = false
		detail_pull_tip_root.modulate.a = 0.0
		detail_pull_tip_active = false
		detail_pull_tip_direction = 0
		return
	var pull_direction := 1 if offset_y > 0.0 else 0
	var pull_amount := absf(offset_y)
	var should_show: bool = pull_direction != 0 and pull_amount >= DETAIL_PULL_TIP_TRIGGER_OFFSET
	if (
		should_show
		and (not detail_pull_tip_active or detail_pull_tip_direction != pull_direction)
		and detail_pull_tip_label != null
		and is_instance_valid(detail_pull_tip_label)
	):
		var tip_text := _next_detail_pull_tip_text()
		host._app_lifecycle_runtime().set_label_text_if_changed(detail_pull_tip_label, _detail_pull_tip_display_text(tip_text))
		_record_detail_pull_tip_seen(tip_text)
	detail_pull_tip_active = should_show
	detail_pull_tip_direction = pull_direction if should_show else 0
	if not should_show:
		detail_pull_tip_root.visible = false
		detail_pull_tip_root.modulate.a = 0.0
		return
	_position_detail_pull_tip_label(true, pull_amount)
	var denominator := maxf(1.0, DETAIL_PULL_TIP_FULL_OFFSET - DETAIL_PULL_TIP_TRIGGER_OFFSET)
	detail_pull_tip_root.visible = true
	detail_pull_tip_root.modulate.a = clampf((pull_amount - DETAIL_PULL_TIP_TRIGGER_OFFSET) / denominator, 0.0, 1.0)


func _cancel_detail_card_texture_prewarm() -> void:
	detail_texture_prewarm_skill_id = ""
	detail_texture_prewarm_request_queue.clear()
	detail_texture_prewarm_pending.clear()


func _process_detail_card_texture_prewarm() -> void:
	if detail_texture_prewarm_skill_id.is_empty():
		return
	if host.current_screen != "skill":
		_cancel_detail_card_texture_prewarm()
		return
	if host._skill_swipe_activity_surface().skill_swipe_pending_full_finalize or host._skill_swipe_activity_surface().skill_swipe_defer_initial_lazy_mount or host._skill_swipe_activity_surface()._skill_swipe_handoff_cover_is_opaque_cream_transition():
		return
	_collect_completed_detail_texture_prewarm_requests()
	var requests_started := 0
	while requests_started < host.DETAIL_TEXTURE_PREWARM_REQUESTS_PER_FRAME and not detail_texture_prewarm_request_queue.is_empty():
		var path := str(detail_texture_prewarm_request_queue.pop_front())
		var normalized: String = host.visual_texture_cache._res_path(path)
		if normalized.is_empty() or host.visual_texture_cache.texture_cache.has(normalized) or detail_texture_prewarm_pending.has(normalized):
			continue
		if DisplayServer.get_name() == "headless":
			host.visual_texture_cache._texture(path)
			requests_started += 1
			continue
		if not ResourceLoader.exists(normalized):
			host.visual_texture_cache._texture(path)
			requests_started += 1
			continue
		var err := ResourceLoader.load_threaded_request(normalized, "Texture2D")
		if err == OK or err == ERR_BUSY:
			detail_texture_prewarm_pending[normalized] = true
		else:
			host.visual_texture_cache._texture(path)
		requests_started += 1
	if detail_texture_prewarm_request_queue.is_empty() and detail_texture_prewarm_pending.is_empty():
		detail_texture_prewarm_skill_id = ""


func _collect_completed_detail_texture_prewarm_requests() -> void:
	if detail_texture_prewarm_pending.is_empty():
		return
	var completed := []
	for raw_path in detail_texture_prewarm_pending.keys():
		var normalized := str(raw_path)
		var status := ResourceLoader.load_threaded_get_status(normalized)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var loaded := ResourceLoader.load_threaded_get(normalized)
			host.visual_texture_cache.texture_cache[normalized] = host.visual_texture_cache._visual_fallback_texture() if DisplayServer.get_name() == "headless" else (loaded if loaded is Texture2D else host.visual_texture_cache._visual_fallback_texture())
			completed.append(normalized)
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			host.visual_texture_cache.texture_cache[normalized] = host.visual_texture_cache._visual_fallback_texture()
			completed.append(normalized)
	for normalized in completed:
		detail_texture_prewarm_pending.erase(normalized)


func detail_card_texture_prewarm_idle() -> bool:
	return detail_texture_prewarm_request_queue.is_empty() and detail_texture_prewarm_pending.is_empty()


func detail_card_texture_prewarm_counts() -> Dictionary:
	return {
		"queue": detail_texture_prewarm_request_queue.size(),
		"pending": detail_texture_prewarm_pending.size()
	}


func _append_detail_eager_entry(stack: VBoxContainer, skill_id: String, entry_data: Dictionary, content_width: float, actions_width: float) -> void:
	if str(entry_data.get("kind", "")) == "beta_notice":
		_detail_eager_add_to_stack(stack, _detail_stack_entry(_build_beta_notice_board(content_width), content_width, actions_width))
		return
	if str(entry_data.get("kind", "")) == "thieving_heist":
		var heist := entry_data.get("heist", {}) as Dictionary
		var heist_id := str(heist.get("id", ""))
		var track_id := "heist:%s" % heist_id
		if detail_rendered_action_ids.has(track_id):
			return
		detail_rendered_action_ids.append(track_id)
		var heist_module_key := ModuleUiRuntime.thieving_heist(heist_id)
		var heist_root: Control = host._thieving_surface()._build_thieving_heist_card(heist, actions_width)
		heist_root = _apply_collapsed_module_squeeze(heist_root, heist_module_key, _module_ui_is_collapsed(heist_module_key))
		_detail_eager_add_to_stack(stack, heist_root)
		detail_action_card_nodes[track_id] = heist_root
		return
	var action := entry_data.get("action", {}) as Dictionary
	var action_id := str(action.get("id", ""))
	if action_id.is_empty() or detail_rendered_action_ids.has(action_id):
		return
	detail_rendered_action_ids.append(action_id)
	var action_module_key := ModuleUiRuntime.action_for_record(skill_id, action, host.FISHING_ACTION_ID_ALIASES)
	if host._passive_modules_runtime().is_passive_action(action):
		var passive_card: Dictionary = host._passive_firepit_surface()._build_passive_module_card(skill_id, action, content_width, true)
		passive_card["root"] = _apply_collapsed_module_squeeze(passive_card["root"] as Control, action_module_key, _module_ui_is_collapsed(action_module_key))
		var stack_entry := _detail_stack_entry(passive_card["root"] as Control, content_width, actions_width)
		_detail_eager_add_to_stack(stack, stack_entry)
		var card := passive_card["card"] as Dictionary
		card["entry"] = stack_entry
		_register_action_card(host._action_key(skill_id, action_id), card)
		_detail_lazy_finalize_action_card(card, skill_id, action, action_id)
		detail_action_card_nodes[action_id] = stack_entry
	else:
		var built := _build_detail_interactive_action_card(skill_id, action, content_width, actions_width)
		built["card_root"] = _apply_collapsed_module_squeeze(built["card_root"] as Control, action_module_key, _module_ui_is_collapsed(action_module_key))
		var stack_entry := _detail_stack_entry(built["card_root"] as Control, content_width, actions_width)
		_detail_eager_add_to_stack(stack, stack_entry)
		var card := built["card"] as Dictionary
		card["entry"] = stack_entry
		_register_action_card(host._action_key(skill_id, action_id), card)
		_detail_lazy_finalize_action_card(card, skill_id, action, action_id)
		detail_action_card_nodes[action_id] = stack_entry
	if not host._onboarding_runtime()._onboarding_path_active() and _should_show_lock_click_tip(skill_id, action):
		_detail_eager_add_to_stack(stack, _detail_stack_entry(host._tutorial_overlay_surface()._bottom_tutorial_tip_note(content_width, "Tap to unlock", "lock_click_tip_notes"), content_width, actions_width))
	if _should_show_passive_module_tip(skill_id, action):
		var passive_card_key: String = host._action_key(skill_id, action_id)
		var passive_card := host.action_cards.get(passive_card_key, {}) as Dictionary
		var passive_target: Control = host._app_lifecycle_runtime().valid_control_ref(passive_card.get("toggle"))
		_detail_eager_add_smooth_tutorial_tip(stack, host._tutorial_overlay_surface()._bottom_tutorial_tip_note(content_width, PassiveFirepitSurface.WOODCUTTING_FIREPIT_TIP_TEXT, "passive_module_tip_notes", passive_target), content_width, actions_width, "passive_module_tip_notes")
	if host._onboarding_runtime()._should_show_silver_opportunity_tip(skill_id, action):
		_detail_eager_add_smooth_tutorial_tip(stack, host._tutorial_overlay_surface()._bottom_tutorial_tip_note(content_width, OnboardingRuntime.SILVER_OPPORTUNITY_TIP_TEXT, "silver_opportunity_tip_notes"), content_width, actions_width, "silver_opportunity_tip_notes")


func _complete_boot_detail_cards_async() -> void:
	if boot_detail_render_queue.is_empty():
		boot_detail_scroll_locked = false
		return
	var stack: VBoxContainer = host._app_lifecycle_runtime().valid_control_ref(detail_lazy_stack) as VBoxContainer
	if stack == null:
		boot_detail_render_queue.clear()
		boot_detail_scroll_locked = false
		return
	host.boot_detail_completion_token += 1
	var token: int = host.boot_detail_completion_token
	var skill_id: String = selected_skill_id
	var content_width: float = host._skill_content_width()
	var actions_width: float = content_width
	while boot_detail_render_queue.size() > 0:
		if token != host.boot_detail_completion_token or current_screen != "skill":
			boot_detail_scroll_locked = false
			return
		for _i in range(BOOT_DETAIL_COMPLETE_BUDGET_PER_FRAME):
			if boot_detail_render_queue.is_empty():
				break
			if token != host.boot_detail_completion_token:
				boot_detail_scroll_locked = false
				return
			var entry_data := boot_detail_render_queue.pop_front() as Dictionary
			_append_detail_eager_entry(stack, skill_id, entry_data, content_width, actions_width)
		await host.get_tree().process_frame
	if token != host.boot_detail_completion_token or current_screen != "skill":
		boot_detail_scroll_locked = false
		return
	_append_detail_eager_trailing_tips(stack, content_width, actions_width)
	host._navigation_shell()._render_page_switch_module(stack, skill_id, content_width, actions_width)
	boot_detail_render_queue.clear()
	boot_detail_scroll_locked = false
	Callable(self, "_sync_detail_actions_scroll_limit_deferred").call_deferred()


func _render_detail_eager_card_list_async(stack: VBoxContainer, content_width: float, actions_width: float, max_main_entries: int = -1):
	detail_lazy_plan.clear()
	detail_lazy_last_scroll = -1.0
	detail_lazy_stack = stack
	boot_detail_render_queue.clear()
	var skill_id: String = selected_skill_id
	if max_main_entries < 0:
		detail_rendered_action_ids.clear()
		for entry in _visible_detail_entries_for_skill(skill_id):
			_append_detail_eager_entry(stack, skill_id, entry as Dictionary, content_width, actions_width)
			await host.get_tree().process_frame
		_append_detail_eager_trailing_tips(stack, content_width, actions_width)
		detail_lazy_stack = null
		return
	detail_rendered_action_ids.clear()
	var main_rendered := 0
	for entry in _visible_detail_entries_for_skill(skill_id):
		var entry_data := entry as Dictionary
		if main_rendered >= max_main_entries:
			boot_detail_render_queue.append(entry_data)
			continue
		_append_detail_eager_entry(stack, skill_id, entry_data, content_width, actions_width)
		main_rendered += 1
		await host.get_tree().process_frame


func _begin_detail_lazy_card_list_render(skill_id: String) -> void:
	_clear_detail_lazy_cache_bin()
	detail_rendered_action_ids.clear()
	detail_lazy_plan = _build_detail_lazy_plan(skill_id)
	host._skill_swipe_activity_surface()._apply_global_swipe_real_card_cache_to_lazy_plan(skill_id)


func _finish_detail_lazy_card_list_render() -> void:
	if OS.get_environment("IDLE_ELITE_TRACE_SWIPE_RENDER") == "1":
		print("SWIPE_RENDER_TRACE lazy_list skill=%s defer=%s cover=%s alpha=%.3f plan=%s" % [
			selected_skill_id,
			str(host._skill_swipe_activity_surface().skill_swipe_defer_initial_lazy_mount),
			str(host._skill_swipe_activity_surface()._skill_swipe_handoff_cover_is_cream_transition()),
			0.0 if host._skill_swipe_activity_surface().skill_swipe_handoff_cover == null or not is_instance_valid(host._skill_swipe_activity_surface().skill_swipe_handoff_cover) else host._skill_swipe_activity_surface().skill_swipe_handoff_cover.modulate.a,
			str(detail_lazy_plan.size())
		])
	if not host._skill_swipe_activity_surface().skill_swipe_defer_initial_lazy_mount:
		_detail_lazy_mount_initial_window_sync(true, _detail_lazy_initial_force_mount_count_for_skill(selected_skill_id))
	if not host._skill_swipe_loading_transition_active() and not host._skill_swipe_activity_surface()._skill_swipe_handoff_cover_is_cream_transition():
		_detail_lazy_mount_thieving_heists_sync(true)
	detail_lazy_last_scroll = _detail_lazy_scroll_y()
	if host._skill_swipe_activity_surface()._skill_swipe_handoff_cover_is_opaque_cream_transition():
		host._skill_swipe_activity_surface().skill_swipe_handoff_cover.set_meta("swipe_cover_last_lazy_mount_process_frame", Engine.get_process_frames())
	_cancel_detail_card_texture_prewarm()
	if not host._skill_swipe_activity_surface().skill_swipe_defer_initial_lazy_mount and not host._skill_swipe_activity_surface()._skill_swipe_handoff_cover_is_cream_transition():
		host._skill_swipe_activity_surface()._queue_skill_swipe_real_card_cache_prewarm(selected_skill_id)
	_queue_detail_lazy_settle_warm_mount(selected_skill_id)


func _render_detail_lazy_card_list(stack: VBoxContainer, content_width: float, actions_width: float) -> void:
	_begin_detail_lazy_card_list_render(selected_skill_id)
	_detail_lazy_create_slots(stack, selected_skill_id, content_width, actions_width)
	_finish_detail_lazy_card_list_render()


func _render_detail_lazy_card_list_batched(stack: VBoxContainer, content_width: float, actions_width: float, batch_size: int) -> bool:
	var skill_id: String = selected_skill_id
	_begin_detail_lazy_card_list_render(skill_id)
	var slots_created := await _detail_lazy_create_slots_batched(
		stack,
		skill_id,
		content_width,
		actions_width,
		batch_size
	)
	if not slots_created:
		return false
	_finish_detail_lazy_card_list_render()
	return true


func _process_detail_lazy_runtime(delta: float, detail_scroll_visual_work: bool) -> int:
	detail_lazy_mounted_this_frame = false
	var mounted_count := 0
	if detail_lazy_plan.size() > 0:
		mounted_count = _process_detail_lazy_window(delta)
	_maybe_resume_fishing_detail_idle_warm_mount()
	_process_detail_lazy_settle_warm_mount(detail_scroll_visual_work)
	return mounted_count


func _process_detail_lazy_window(delta: float) -> int:
	if detail_lazy_plan.is_empty() or detail_lazy_stack == null:
		return 0
	if host._fishing_ui_surface()._fishing_ablation_enabled("no_lazy") and host._fishing_rework_active_for_skill(selected_skill_id):
		return 0
	if host._skill_swipe_activity_surface().skill_swipe_finalized_lazy_mount_pending:
		return 0
	if host._skill_swipe_activity_surface().skill_swipe_pending_full_finalize:
		return 0
	if host._skill_swipe_activity_surface()._skill_swipe_handoff_cover_is_opaque_cream_transition():
		return 0
	if (
		host._fishing_rework_active_for_skill(selected_skill_id)
		and detail_lazy_settle_warm_mount_skill_id == selected_skill_id
		and not detail_scroll_visual_work_this_frame
	):
		return 0
	detail_lazy_window_sync_elapsed += maxf(0.0, delta)
	if not _detail_lazy_window_scan_due():
		return 0
	detail_lazy_window_sync_elapsed = 0.0
	var mounted_count := 0
	if _detail_lazy_should_sync_visible_window():
		mounted_count = _sync_detail_lazy_visible_cards(true, DETAIL_LAZY_MOUNT_BUDGET_PER_FRAME)
	if mounted_count > 0:
		detail_lazy_mounted_this_frame = true
		return mounted_count
	_prune_detail_lazy_far_cards(DETAIL_LAZY_UNMOUNT_BUDGET_PER_FRAME)
	return 0


func _detail_lazy_window_scan_due() -> bool:
	if detail_lazy_last_scroll < -0.5:
		return true
	if absf(_detail_lazy_scroll_y() - detail_lazy_last_scroll) > 8.0:
		return true
	if detail_lazy_window_sync_elapsed >= DETAIL_LAZY_WINDOW_SYNC_INTERVAL_SECONDS:
		return true
	if host.running_skill_id == selected_skill_id and not host.running_action_id.is_empty():
		var running_lazy_entry: Dictionary = _detail_lazy_entry_for_track_id(host.running_action_id)
		if not running_lazy_entry.is_empty() and not bool(running_lazy_entry.get("mounted", false)):
			return true
	return false


func _queue_detail_lazy_settle_warm_mount(skill_id: String) -> void:
	if not DETAIL_LAZY_SETTLE_WARM_MOUNT_ENABLED:
		return
	if current_screen != "skill" or skill_id.is_empty() or selected_skill_id != skill_id:
		return
	if host._skill_swipe_loading_transition_active() or host._skill_swipe_activity_surface()._skill_swipe_handoff_cover_is_cream_transition():
		return
	if detail_lazy_plan.is_empty() or host._app_lifecycle_runtime().valid_control_ref(detail_lazy_stack) == null:
		return
	_prewarm_detail_card_style_resources()
	detail_lazy_settle_warm_mount_skill_id = skill_id


func _cancel_detail_lazy_settle_warm_mount() -> void:
	detail_lazy_settle_warm_mount_skill_id = ""


func _maybe_resume_fishing_detail_idle_warm_mount() -> void:
	if current_screen != "skill" or not host._fishing_rework_active_for_skill(selected_skill_id):
		return
	if detail_lazy_settle_warm_mount_skill_id == selected_skill_id:
		return
	if detail_lazy_plan.is_empty() or host._app_lifecycle_runtime().valid_control_ref(detail_lazy_stack) == null:
		return
	if _detail_lazy_all_mounted():
		return
	if host._fishing_ui_surface()._fishing_detail_scroll_is_actively_moving():
		return
	_queue_detail_lazy_settle_warm_mount(selected_skill_id)


func _finish_detail_lazy_settle_warm_mount(skill_id: String, detail_scroll_visual_work: bool) -> void:
	detail_lazy_settle_warm_mount_skill_id = ""
	if current_screen == "skill" and selected_skill_id == skill_id:
		if not (host._fishing_rework_active_for_skill(selected_skill_id) and detail_scroll_visual_work):
			host._activity_unlock_ceremony_surface().sync_hidden_locked_activity_preview_layouts()
		_sync_detail_actions_scroll_limit()
		if host._fishing_rework_active_for_skill(selected_skill_id):
			host._fishing_ui_surface()._sync_fishing_detail_render_culling(true)


func _process_detail_lazy_settle_warm_mount(detail_scroll_visual_work: bool) -> void:
	var skill_id := detail_lazy_settle_warm_mount_skill_id
	if skill_id.is_empty():
		return
	if current_screen != "skill" or selected_skill_id != skill_id:
		detail_lazy_settle_warm_mount_skill_id = ""
		return
	if host._skill_swipe_loading_transition_active() or host._skill_swipe_activity_surface()._skill_swipe_handoff_cover_is_cream_transition():
		detail_lazy_settle_warm_mount_skill_id = ""
		return
	if detail_lazy_plan.is_empty() or host._app_lifecycle_runtime().valid_control_ref(detail_lazy_stack) == null:
		detail_lazy_settle_warm_mount_skill_id = ""
		return
	if host._fishing_rework_active_for_skill(skill_id) and host._fishing_ui_surface()._fishing_detail_scroll_is_actively_moving():
		return
	if detail_scroll_visual_work:
		if not host._fishing_rework_active_for_skill(skill_id) or host._fishing_ui_surface()._fishing_detail_scroll_is_actively_moving():
			return
	var cached_count := 0
	var warm_mount_budget := FISHING_DETAIL_LAZY_SETTLE_WARM_MOUNT_BUDGET_PER_FRAME if host._fishing_rework_active_for_skill(skill_id) else DETAIL_LAZY_SETTLE_WARM_MOUNT_BUDGET_PER_FRAME
	var content_width: float = host._skill_content_width()
	var actions_width: float = content_width
	var previous_mount_context := detail_lazy_mount_trace_context
	detail_lazy_mount_trace_context = "settle_warm_process"
	var reached_warm_mount_limit := false
	for raw_lazy_entry in detail_lazy_plan:
		if cached_count >= warm_mount_budget:
			break
		var lazy_entry := raw_lazy_entry as Dictionary
		var kind := str(lazy_entry.get("kind", ""))
		if not _detail_lazy_kind_is_module(kind):
			continue
		if bool(lazy_entry.get("mounted", false)):
			continue
		if not _detail_lazy_idle_warm_mount_can_mount(skill_id, lazy_entry):
			reached_warm_mount_limit = true
			break
		if lazy_entry.has("cached_root"):
			if host._fishing_rework_active_for_skill(skill_id):
				if _detail_lazy_mount_item(lazy_entry, skill_id, content_width, actions_width, false):
					cached_count += 1
			continue
		if host._fishing_rework_active_for_skill(skill_id):
			if _detail_lazy_mount_item(lazy_entry, skill_id, content_width, actions_width, false):
				cached_count += 1
			continue
		if _detail_lazy_build_cached_entry(lazy_entry, skill_id, content_width, actions_width):
			cached_count += 1
	detail_lazy_mount_trace_context = previous_mount_context
	if reached_warm_mount_limit:
		_finish_detail_lazy_settle_warm_mount(skill_id, detail_scroll_visual_work)
		return
	if cached_count > 0:
		return
	if host._fishing_rework_active_for_skill(skill_id) and not _detail_lazy_all_mounted():
		return
	_finish_detail_lazy_settle_warm_mount(skill_id, detail_scroll_visual_work)


var _on_detail_actions_user_scroll_direction:
	get: return host._on_detail_actions_user_scroll_direction
	set(value): host._on_detail_actions_user_scroll_direction = value

var a:
	get: return host.a
	set(value): host.a = value

var ACTION_CARD_FACE_BORDER_ENABLED:
	get: return host.ACTION_CARD_FACE_BORDER_ENABLED
	set(value): host.ACTION_CARD_FACE_BORDER_ENABLED = value

var ACTION_CARD_FACE_BORDER_Z_INDEX:
	get: return host.ACTION_CARD_FACE_BORDER_Z_INDEX
	set(value): host.ACTION_CARD_FACE_BORDER_Z_INDEX = value

var action_card_keys:
	get: return host.action_card_keys
	set(value): host.action_card_keys = value

var action_cards:
	get: return host.action_cards
	set(value): host.action_cards = value

var activity_start:
	get: return host.activity_start
	set(value): host.activity_start = value

var boot_detail_card_yield:
	get: return host.boot_detail_card_yield
	set(value): host.boot_detail_card_yield = value

var boot_detail_render_in_progress:
	get: return host.boot_detail_render_in_progress
	set(value): host.boot_detail_render_in_progress = value

var boot_detail_render_queue:
	get: return host.boot_detail_render_queue
	set(value): host.boot_detail_render_queue = value

var boot_detail_scroll_locked:
	get: return host.boot_detail_scroll_locked
	set(value): host.boot_detail_scroll_locked = value

var buildable_module_overlay:
	get: return host.buildable_module_overlay
	set(value): host.buildable_module_overlay = value

var cached:
	get: return host.cached
	set(value): host.cached = value

var children:
	get: return host.children
	set(value): host.children = value

var cleared:
	get: return host.cleared
	set(value): host.cleared = value

var COLOR_INK:
	get: return host.COLOR_INK
	set(value): host.COLOR_INK = value

var COLOR_MUTED:
	get: return host.COLOR_MUTED
	set(value): host.COLOR_MUTED = value

var context:
	get: return host.context
	set(value): host.context = value

var content_scroll:
	get: return host.content_scroll
	set(value): host.content_scroll = value

var COLOR_GOLD:
	get: return host.COLOR_GOLD
	set(value): host.COLOR_GOLD = value

var current_screen:
	get: return host.current_screen
	set(value): host.current_screen = value

var dark_mode_enabled:
	get: return host.dark_mode_enabled
	set(value): host.dark_mode_enabled = value

var detail_action_card_nodes := {}
var detail_actions_scroll: MobileScrollContainer
var detail_thieving_scroll_restore_allowed := false
var detail_actions_top_spacer: Control
var onboarding_first_module_spacer_tween: Tween
var detail_auto_eat_fish_button: TextureButton
var detail_blue_guy_health_gauge: Control
var detail_fish_circle: FishCircle
var detail_header_body: Control
var detail_header_left_block: Control

var detail_scroll_visual_work_this_frame := false
var detail_actions_scroll_limit_elapsed := 0.0
var detail_scroll_visual_work_hold_frames := 0
var detail_background_maintenance_last_scroll := -1.0
var action_card_press_key := ""
var action_card_press_position := Vector2.ZERO
var action_card_press_stat_kind := ""
var action_card_press_dragged := false
var action_card_press_visual_token := 0
var action_card_press_visual_pending_key := ""
var last_action_card_tap_key := ""
var last_action_card_tap_msec := 0
var detail_regen_circle: RegenCircle
var detail_regen_circle_fade_group: CanvasGroup
var detail_regen_circle_host: Control

var DETAIL_RESTORE_SCROLL_BOTTOM:
	get: return host.DETAIL_RESTORE_SCROLL_BOTTOM
	set(value): host.DETAIL_RESTORE_SCROLL_BOTTOM = value

var detail_stamina_bar: CleanProgressBar
var detail_unlock_scroll_spacer: Control
var detail_unlock_scroll_spacer_tween: Tween
var detail_unlock_auto_scroll_interrupted := false
var detail_unlock_scroll_spacer_heights := {}
var detail_xp_bar: CleanProgressBar
var detail_xp_label: Label
var detail_header_gauge_refresh_elapsed := 0.0
var passive_card_progress_refresh_elapsed := 0.0

var done:
	get: return host.done
	set(value): host.done = value

var fade:
	get: return host.fade
	set(value): host.fade = value

var fallback:
	get: return host.fallback
	set(value): host.fallback = value

var fish_circle:
	get: return host.fish_circle
	set(value): host.fish_circle = value


var keys:
	get: return host.keys
	set(value): host.keys = value


var lock:
	get: return host.lock
	set(value): host.lock = value

var missing_page:
	get: return host.missing_page
	set(value): host.missing_page = value

var missing_scroll:
	get: return host.missing_scroll
	set(value): host.missing_scroll = value

var missing_stack:
	get: return host.missing_stack
	set(value): host.missing_stack = value

var mobile_scroll_container:
	get: return host.mobile_scroll_container
	set(value): host.mobile_scroll_container = value

var MODULE_LIST_TRANSITION_MIN_MOVE:
	get: return host.MODULE_LIST_TRANSITION_MIN_MOVE
	set(value): host.MODULE_LIST_TRANSITION_MIN_MOVE = value

var MODULE_LIST_TRANSITION_NEW_OFFSET_Y:
	get: return host.MODULE_LIST_TRANSITION_NEW_OFFSET_Y
	set(value): host.MODULE_LIST_TRANSITION_NEW_OFFSET_Y = value

var MODULE_LIST_TRANSITION_NEW_SECONDS:
	get: return host.MODULE_LIST_TRANSITION_NEW_SECONDS
	set(value): host.MODULE_LIST_TRANSITION_NEW_SECONDS = value

var MODULE_LIST_TRANSITION_SECONDS:
	get: return host.MODULE_LIST_TRANSITION_SECONDS
	set(value): host.MODULE_LIST_TRANSITION_SECONDS = value

var module_ui:
	get: return host.module_ui
	set(value): host.module_ui = value

var module_ui_animating_collapse_key := ""
var module_ui_pending_pin_scroll_anchor := {}
var module_ui_pin_scroll_anchor_debug := ""
var module_ui_pin_refresh_cover_requested := false
var module_ui_refresh_token := 0

var onboarding_fight_stamina_revealed:
	get: return host._onboarding_runtime().onboarding_fight_stamina_revealed
	set(value): host._onboarding_runtime().onboarding_fight_stamina_revealed = value


var phase:
	get: return host.phase
	set(value): host.phase = value


var regen_circle:
	get: return host.regen_circle
	set(value): host.regen_circle = value

var replace_stack_failed:
	get: return host.replace_stack_failed
	set(value): host.replace_stack_failed = value

var resolved:
	get: return host.resolved
	set(value): host.resolved = value

var s:
	get: return host.s
	set(value): host.s = value

var scripts:
	get: return host.scripts
	set(value): host.scripts = value

var selected_skill_id:
	get: return host.selected_skill_id
	set(value): host.selected_skill_id = value

var skill:
	get: return host.skill
	set(value): host.skill = value

var SKILL_DETAIL_ACTIONS_DIVIDER_HEIGHT:
	get: return host.SKILL_DETAIL_ACTIONS_DIVIDER_HEIGHT
	set(value): host.SKILL_DETAIL_ACTIONS_DIVIDER_HEIGHT = value

var SKILL_DETAIL_HEADER_HEIGHT:
	get: return host.SKILL_DETAIL_HEADER_HEIGHT
	set(value): host.SKILL_DETAIL_HEADER_HEIGHT = value

var SKILL_DETAIL_HEADER_MARGIN_BOTTOM:
	get: return host.SKILL_DETAIL_HEADER_MARGIN_BOTTOM
	set(value): host.SKILL_DETAIL_HEADER_MARGIN_BOTTOM = value

var SKILL_DETAIL_LEFT_SEPARATION:
	get: return host.SKILL_DETAIL_LEFT_SEPARATION
	set(value): host.SKILL_DETAIL_LEFT_SEPARATION = value

var SKILL_DETAIL_TEXT_SEPARATION:
	get: return host.SKILL_DETAIL_TEXT_SEPARATION
	set(value): host.SKILL_DETAIL_TEXT_SEPARATION = value

var SKILL_DETAIL_XP_FONT_SIZE:
	get: return host.SKILL_DETAIL_XP_FONT_SIZE
	set(value): host.SKILL_DETAIL_XP_FONT_SIZE = value


func _skill_detail_shelf_style(skill_id: String, draw_bottom_border := true) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	if draw_bottom_border:
		style.bg_color = _skill_detail_shelf_color(skill_id)
	else:
		style.bg_color = Color.TRANSPARENT
		style.draw_center = false
	var border: Color = ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE).lerp(host._theme_paper_color(), 0.58)
	border.a = 0.82
	style.border_color = border
	style.border_width_bottom = 5 if draw_bottom_border else 0
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style


func _add_skill_detail_shelf_background(parent: Control, skill_id: String, content_width: float) -> Control:
	var background := _GradientShelf.new()
	background.name = "SkillDetailFullBleedShelfBackground"
	background.set_colors(_skill_detail_shelf_color(skill_id), _skill_detail_shelf_gradient_bottom_color(skill_id))
	background.anchor_left = 0.0
	background.anchor_right = 1.0
	background.anchor_top = 0.0
	background.anchor_bottom = 1.0
	var bleed: float = maxf(host.PAGE_PAD, (host._skill_column_host_width() - content_width) * 0.5) + host._skill_swipe_activity_surface()._skill_swipe_page_span()
	background.offset_left = -bleed
	background.offset_right = bleed
	background.offset_top = -host.SKILLS_PAGE_TOP_PAD
	background.offset_bottom = host.SKILL_DETAIL_ACTIONS_DIVIDER_HEIGHT
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.z_index = -20
	background.visible = true
	if host._skill_swipe_activity_surface()._skill_swipe_shelf_background_should_start_hidden():
		background.modulate.a = 0.0
		background.visible = false
	parent.add_child(background)
	return background


func _skill_detail_shelf_color(skill_id: String) -> Color:
	return host.COLOR_DARK_PANEL if host.dark_mode_enabled else Color("#f1e7d7")


func _skill_detail_shelf_gradient_bottom_color(skill_id: String) -> Color:
	return _skill_detail_shelf_color(skill_id).lerp(ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE).darkened(0.22), 0.18)


var skill_swipe:
	get: return host.skill_swipe
	set(value): host.skill_swipe = value

var skill_swipe_defer_initial_lazy_mount:
	get: return host._skill_swipe_activity_surface().skill_swipe_defer_initial_lazy_mount
	set(value): host._skill_swipe_activity_surface().skill_swipe_defer_initial_lazy_mount = value

var skill_swipe_drag_offset_x:
	get: return host._skill_swipe_activity_surface().skill_swipe_drag_offset_x
	set(value): host._skill_swipe_activity_surface().skill_swipe_drag_offset_x = value

var SKILL_SWIPE_FINALIZE_SLOT_BATCH_SIZE:
	get: return host.SKILL_SWIPE_FINALIZE_SLOT_BATCH_SIZE
	set(value): host.SKILL_SWIPE_FINALIZE_SLOT_BATCH_SIZE = value

var SKILL_SWIPE_FINALIZE_VISIBLE_MOUNT_LIMIT:
	get: return host.SKILL_SWIPE_FINALIZE_VISIBLE_MOUNT_LIMIT
	set(value): host.SKILL_SWIPE_FINALIZE_VISIBLE_MOUNT_LIMIT = value

var SKILL_SWIPE_PREVIEW_FREE_BATCH_SIZE:
	get: return host.SKILL_SWIPE_PREVIEW_FREE_BATCH_SIZE
	set(value): host.SKILL_SWIPE_PREVIEW_FREE_BATCH_SIZE = value

var skill_swipe_finalized_lazy_mount_pending:
	get: return host._skill_swipe_activity_surface().skill_swipe_finalized_lazy_mount_pending
	set(value): host._skill_swipe_activity_surface().skill_swipe_finalized_lazy_mount_pending = value

var skill_swipe_frame:
	get: return host._skill_swipe_activity_surface().skill_swipe_frame
	set(value): host._skill_swipe_activity_surface().skill_swipe_frame = value

var skill_swipe_gap_render_offset_x:
	get: return host._skill_swipe_activity_surface().skill_swipe_gap_render_offset_x
	set(value): host._skill_swipe_activity_surface().skill_swipe_gap_render_offset_x = value

var skill_swipe_lazy_finalize_token:
	get: return host._skill_swipe_activity_surface().skill_swipe_lazy_finalize_token
	set(value): host._skill_swipe_activity_surface().skill_swipe_lazy_finalize_token = value

var skill_swipe_page:
	get: return host._skill_swipe_activity_surface().skill_swipe_page
	set(value): host._skill_swipe_activity_surface().skill_swipe_page = value

var skill_swipe_pending_full_finalize:
	get: return host._skill_swipe_activity_surface().skill_swipe_pending_full_finalize
	set(value): host._skill_swipe_activity_surface().skill_swipe_pending_full_finalize = value

var skills_content:
	get: return host.skills_content
	set(value): host.skills_content = value

var slots:
	get: return host.slots
	set(value): host.slots = value

var slots_failed:
	get: return host.slots_failed
	set(value): host.slots_failed = value

var stamina_gauge_tip_seen:
	get: return host._onboarding_runtime().stamina_gauge_tip_seen
	set(value): host._onboarding_runtime().stamina_gauge_tip_seen = value

var track:
	get: return host.track
	set(value): host.track = value

var ui:
	get: return host.ui
	set(value): host.ui = value

var us:
	get: return host.us
	set(value): host.us = value



func _init(host_node) -> void:
	host = host_node


func onboarding_first_module_center_active(skill_id: String = "") -> bool:
	return false


func onboarding_first_module_top_spacer_height(skill_id: String = "") -> float:
	if skill_id.is_empty():
		skill_id = selected_skill_id
	if not onboarding_first_module_center_active(skill_id):
		return float(host.SKILL_DETAIL_ACTIONS_TOP_SPACER_HEIGHT)
	var visible_screen_height: float = host._current_canvas_size().y - host._navigation_shell()._bottom_ui_reserved_height_for_current_screen()
	if visible_screen_height <= 1.0:
		visible_screen_height = host.BASE_CANVAS.y - host._navigation_shell()._bottom_ui_reserved_height_for_current_screen()
	var actions_global_top: float = host.SKILLS_PAGE_TOP_PAD + host.SKILL_DETAIL_HEADER_HEIGHT + host.SKILL_DETAIL_ACTIONS_DIVIDER_HEIGHT
	var target_card_top: float = visible_screen_height * 0.5 - ActivityCardStyles.root_height(false, host.ACTION_CARD_HEIGHT, host.ACTION_CARD_EXPANDED_HEIGHT, host.ACTION_CARD_3D_DEPTH_OFFSET.y) * 0.5 - actions_global_top
	return maxf(float(host.SKILL_DETAIL_ACTIONS_TOP_SPACER_HEIGHT), target_card_top)


func sync_onboarding_first_module_top_spacer(instant := true) -> void:
	if detail_actions_top_spacer == null or not is_instance_valid(detail_actions_top_spacer):
		return
	var target_height := onboarding_first_module_top_spacer_height()
	if onboarding_first_module_spacer_tween != null and onboarding_first_module_spacer_tween.is_valid():
		onboarding_first_module_spacer_tween.kill()
	onboarding_first_module_spacer_tween = null
	if instant:
		_apply_onboarding_first_module_top_spacer_height(target_height)
		return
	var start_height := maxf(detail_actions_top_spacer.custom_minimum_size.y, detail_actions_top_spacer.size.y)
	if absf(start_height - target_height) <= 1.0:
		_apply_onboarding_first_module_top_spacer_height(target_height)
		return
	onboarding_first_module_spacer_tween = host.create_tween()
	onboarding_first_module_spacer_tween.tween_method(
		_apply_onboarding_first_module_top_spacer_height,
		start_height,
		target_height,
		host.ONBOARDING_FIRST_MODULE_CENTER_RELEASE_SECONDS
	).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	onboarding_first_module_spacer_tween.finished.connect(_finish_onboarding_first_module_spacer_tween)


func _apply_onboarding_first_module_top_spacer_height(height: float) -> void:
	if detail_actions_top_spacer == null or not is_instance_valid(detail_actions_top_spacer):
		return
	detail_actions_top_spacer.custom_minimum_size = Vector2(0, height)
	detail_actions_top_spacer.update_minimum_size()


func _finish_onboarding_first_module_spacer_tween() -> void:
	onboarding_first_module_spacer_tween = null
	_sync_detail_actions_scroll_limit()


func release_onboarding_first_module_centering() -> void:
	if detail_actions_top_spacer == null or not is_instance_valid(detail_actions_top_spacer):
		sync_onboarding_first_module_top_spacer(false)
		return
	var stack := _detail_actions_stack()
	if stack != null and is_instance_valid(stack):
		stack.position.y = 0.0
	sync_onboarding_first_module_top_spacer(false)


func _detail_scroll_visual_work_active() -> bool:
	if host.current_screen != "skill" or detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll):
		detail_background_maintenance_last_scroll = -1.0
		detail_scroll_visual_work_hold_frames = 0
		return false
	var scroll_y: float = _detail_lazy_scroll_y()
	var scroll_changed := detail_background_maintenance_last_scroll >= -0.5 and absf(scroll_y - detail_background_maintenance_last_scroll) > 0.5
	detail_background_maintenance_last_scroll = scroll_y
	var actively_scrolling := (
		scroll_changed
		or detail_actions_scroll.drag_scrolling
		or absf(detail_actions_scroll.velocity) >= 4.0
		or (detail_actions_scroll.scroll_tween != null and detail_actions_scroll.scroll_tween.is_valid())
	)
	if actively_scrolling:
		detail_scroll_visual_work_hold_frames = 8
		return true
	if host._fishing_rework_active_for_skill(host.selected_skill_id) and detail_scroll_visual_work_hold_frames > 0:
		detail_scroll_visual_work_hold_frames -= 1
		return true
	return false


func _active_action_scroll_container() -> MobileScrollContainer:
	if host.current_screen == "skill":
		return detail_actions_scroll
	if host.current_screen == "pinned" or host.current_screen == "queue":
		return host._app_lifecycle_runtime().valid_control_ref(host.content_scroll) as MobileScrollContainer
	return null


func _detail_actions_scroll_suppresses_child_click() -> bool:
	var active_scroll := _active_action_scroll_container()
	return (
		active_scroll != null
		and is_instance_valid(active_scroll)
		and active_scroll.is_child_click_suppressed()
	)


func _action_card_press_motion_is_scroll_drag(event_position: Vector2) -> bool:
	var drag_offset := event_position - action_card_press_position
	return (
		absf(drag_offset.y) >= host.ACTION_CARD_SCROLL_DRAG_VISUAL_DEADZONE
		and absf(drag_offset.y) > absf(drag_offset.x) * 1.15
	)


func _action_card_press_motion_is_skill_swipe(event_position: Vector2) -> bool:
	if host.current_screen != "skill":
		return false
	var drag_offset := event_position - action_card_press_position
	return (
		absf(drag_offset.x) >= host.ACTION_CARD_SCROLL_DRAG_VISUAL_DEADZONE
		and absf(drag_offset.x) > absf(drag_offset.y) * 1.15
	)


func _update_action_card_press_drag_state(event: InputEvent) -> void:
	if action_card_press_key.is_empty():
		return
	var event_position := Vector2.ZERO
	var has_position := false
	if event is InputEventMouseMotion:
		event_position = (event as InputEventMouseMotion).global_position
		has_position = true
	elif event is InputEventScreenDrag:
		event_position = (event as InputEventScreenDrag).position
		has_position = true
	if not has_position:
		return
	if _action_card_press_motion_is_skill_swipe(event_position):
		var press_position := action_card_press_position
		var touch_index: int = host._fishing_ui_surface()._motion_event_touch_index(event)
		action_card_press_dragged = true
		host._skill_swipe_activity_surface()._cancel_pending_action_card_3d_press()
		if action_card_press_stat_kind.is_empty():
			host._skill_swipe_activity_surface()._release_action_card_3d_press(action_card_press_key)
		if not host._skill_swipe_activity_surface().skill_swipe_tracking:
			host._skill_swipe_activity_surface()._begin_skill_swipe_tracking(press_position, touch_index)
		if host._skill_swipe_activity_surface().skill_swipe_tracking:
			host._skill_swipe_activity_surface()._update_skill_swipe_feedback(event_position)
		return
	if _detail_actions_scroll_suppresses_child_click() or _action_card_press_motion_is_scroll_drag(event_position):
		action_card_press_dragged = true
		host._skill_swipe_activity_surface()._cancel_pending_action_card_3d_press()
		if action_card_press_stat_kind.is_empty():
			host._skill_swipe_activity_surface()._release_action_card_3d_press(action_card_press_key)
		if _action_card_press_motion_is_scroll_drag(event_position):
			host._fishing_ui_surface()._handoff_fishing_vertical_scroll(action_card_press_position, event_position, host._fishing_ui_surface()._motion_event_touch_index(event))
		return
	if not action_card_press_stat_kind.is_empty() and event_position.distance_to(action_card_press_position) > host.ACTION_STAT_TAP_RELEASE_SLOP:
		action_card_press_dragged = true
		host._skill_swipe_activity_surface()._cancel_pending_action_card_3d_press()


func _register_action_card(key: String, card: Dictionary) -> void:
	if key.is_empty() or card.is_empty():
		return
	if bool(card.get("preview_only", false)):
		return
	host.action_cards[key] = card
	if not host.action_card_keys.has(key):
		host.action_card_keys.append(key)
	card["card_key"] = key
	if not card.has("skill_id") or str(card.get("skill_id", "")).is_empty():
		var separator := key.find(":")
		if separator > 0:
			card["skill_id"] = key.substr(0, separator)
	if not bool(card.get("is_fishing_area", false)) and (not card.has("action_id") or str(card.get("action_id", "")).is_empty()):
		var separator := key.find(":")
		if separator > 0 and not key.begins_with("thieving_heist:") and not key.begins_with("pinned_page:") and not key.begins_with("pinned_shelf:"):
			card["action_id"] = key.substr(separator + 1)


func _action_card_has_live_anchor(card: Dictionary) -> bool:
	if card.is_empty():
		return false
	if host._app_lifecycle_runtime().valid_control_ref(card.get("root")) != null:
		return true
	if host._app_lifecycle_runtime().valid_control_ref(card.get("pop")) != null:
		return true
	if host._app_lifecycle_runtime().valid_control_ref(card.get("button")) != null:
		return true
	if host._app_lifecycle_runtime().valid_control_ref(card.get("method_button")) != null:
		return true
	return false


func _prune_invalid_action_cards() -> void:
	if host.action_cards.is_empty():
		return
	for raw_key in host.action_cards.keys():
		var key := str(raw_key)
		var raw_card = host.action_cards.get(raw_key)
		if typeof(raw_card) != TYPE_DICTIONARY:
			_discard_action_card_key(key)
			continue
		var card := raw_card as Dictionary
		if not _action_card_has_live_anchor(card):
			_discard_action_card_key(key)


func _card_for_action_id(skill_id: String, action_id: String) -> Dictionary:
	if skill_id.is_empty() or action_id.is_empty():
		return {}
	var key: String = host._action_key(skill_id, action_id)
	if host.action_cards.has(key):
		return host.action_cards[key] as Dictionary
	return {}


func _discard_action_card_key(key: String) -> void:
	if key.is_empty():
		return
	host.action_cards.erase(key)
	host.action_card_keys.erase(key)


func _repair_detail_lazy_action_card_registration(track_id: String, skill_id: String) -> bool:
	var lazy_entry: Dictionary = _detail_lazy_entry_for_track_id(track_id)
	if lazy_entry.is_empty() or not bool(lazy_entry.get("mounted", false)):
		return false
	var kind: String = _detail_lazy_entry_kind(lazy_entry)
	if not _detail_lazy_kind_is_action_backed(kind):
		return false
	var card := lazy_entry.get("card", {}) as Dictionary
	if card.is_empty():
		return false
	var root: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("root"))
	if root == null or not root.is_inside_tree():
		return false
	_register_action_card(host._action_key(skill_id, track_id), card)
	return true


func _remount_detail_lazy_action_card(track_id: String, skill_id: String) -> bool:
	var lazy_entry: Dictionary = _detail_lazy_entry_for_track_id(track_id)
	if lazy_entry.is_empty():
		return false
	var kind: String = _detail_lazy_entry_kind(lazy_entry)
	if not _detail_lazy_kind_is_action_backed(kind):
		return false
	var stack_host: Control = host._app_lifecycle_runtime().valid_control_ref(lazy_entry.get("stack_host"))
	if stack_host == null or not stack_host.is_inside_tree():
		return false
	host._app_lifecycle_runtime()._kill_transient_tweens_in_subtree(stack_host)
	for child in stack_host.get_children():
		if child == null:
			continue
		stack_host.remove_child(child)
		child.queue_free()
	lazy_entry["mounted"] = false
	lazy_entry["placeholder"] = null
	lazy_entry.erase("card")
	return _detail_lazy_mount_item(lazy_entry, skill_id, host._skill_content_width(), host._skill_content_width(), false)


func _latest_unlocked_action_id(skill_id: String) -> String:
	var latest_id := ""
	for action in host.actions_by_skill.get(skill_id, []):
		if host._activity_unlock_runtime()._is_action_unlocked(skill_id, action as Dictionary):
			latest_id = str(action["id"])
	return latest_id


func _scroll_to_latest_unlocked_activity(animated := true):
	if host.current_screen != "skill" or detail_actions_scroll == null:
		return
	var action_id := _latest_unlocked_action_id(host.selected_skill_id)
	await _scroll_to_activity_card(action_id, animated, false)


func _scroll_to_resume_activity(animated := true) -> void:
	if host.current_screen != "skill" or detail_actions_scroll == null:
		return
	if host.running_skill_id == host.selected_skill_id and not host.running_action_id.is_empty():
		await _scroll_to_activity_card(host.running_action_id, animated, true)
		return
	await _scroll_to_latest_unlocked_activity(animated)


func _ensure_detail_lazy_entry_mounted(track_id: String) -> void:
	if track_id.is_empty() or detail_lazy_plan.is_empty():
		return
	for raw_lazy_entry in detail_lazy_plan:
		var lazy_entry := raw_lazy_entry as Dictionary
		if not _detail_lazy_entry_matches_track_id(lazy_entry, track_id):
			continue
		if bool(lazy_entry.get("mounted", false)):
			return
		var content_width: float = host._skill_content_width()
		_detail_lazy_mount_item(lazy_entry, host.selected_skill_id, content_width, content_width, false)
		return


func _scroll_to_activity_card(action_id: String, animated := true, centered := false):
	if host.current_screen != "skill" or detail_actions_scroll == null:
		return
	if action_id.is_empty():
		return
	_ensure_detail_lazy_entry_mounted(action_id)
	if not detail_action_card_nodes.has(action_id):
		return
	await host.get_tree().process_frame
	if detail_actions_scroll == null or not detail_action_card_nodes.has(action_id):
		return
	var card: Control = host._app_lifecycle_runtime().valid_control_ref(detail_action_card_nodes.get(action_id))
	if card == null or card.is_queued_for_deletion():
		return
	var target := _detail_actions_scroll_target_for_card(card, centered)
	if target < 0:
		return
	detail_actions_scroll.scroll_to_vertical(target, 0.24 if animated else 0.0)


func _detail_actions_scroll_target_for_action(action_id: String, centered := false) -> int:
	if host.current_screen != "skill" or detail_actions_scroll == null:
		return -1
	if action_id.is_empty():
		return -1
	_ensure_detail_lazy_entry_mounted(action_id)
	if not detail_action_card_nodes.has(action_id):
		return -1
	var card: Control = host._app_lifecycle_runtime().valid_control_ref(detail_action_card_nodes.get(action_id))
	if card == null or card.is_queued_for_deletion():
		return -1
	return _detail_actions_scroll_target_for_card(card, centered)


func _detail_actions_scroll_target_for_card(card: Control, centered := false) -> int:
	if card == null or not is_instance_valid(card) or card.is_queued_for_deletion() or detail_actions_scroll == null:
		return -1
	var target_y := card.position.y - 18.0
	if centered:
		var viewport_height := _detail_actions_scroll_viewport_height()
		target_y = card.position.y + card.size.y * 0.5 - viewport_height * 0.5
	_sync_detail_actions_scroll_limit()
	return clampi(int(round(target_y)), 0, detail_actions_scroll.get_max_scroll_vertical())


func _release_current_action_card_press_state() -> void:
	if action_card_press_key.is_empty() and action_card_press_stat_kind.is_empty() and not action_card_press_dragged:
		return
	host._skill_swipe_activity_surface()._release_action_card_3d_press(action_card_press_key)
	action_card_press_key = ""
	action_card_press_stat_kind = ""
	action_card_press_dragged = false


func _sync_action_stat_chip_title(value_label: Label, title_text: String) -> void:
	if value_label == null:
		return
	if not value_label.has_meta("stat_title_label"):
		return
	var title_label := value_label.get_meta("stat_title_label") as Label
	if title_label == null:
		return
	if str(value_label.get_meta("stat_title_text", "")) != title_text:
		value_label.set_meta("stat_title_text", title_text)
		host._app_lifecycle_runtime().set_label_text_if_changed(title_label, title_text)
	if bool(value_label.get_meta("normal_activity_stat_text", false)):
		title_label.visible = not bool(value_label.get_meta("normal_activity_stat_title_hidden", false)) and not title_text.is_empty()
		return
	if int(title_label.get_meta("stat_title_outline_size", -1)) != 0:
		title_label.set_meta("stat_title_outline_size", 0)
		title_label.add_theme_constant_override("outline_size", 0)


func _on_action_stat_box_gui_input(event: InputEvent, skill_id: String, action_id: String, stat_kind: String) -> void:
	var card := action_cards.get(host._action_key(skill_id, action_id), {}) as Dictionary
	if not _action_stat_box_accepts_input(card, stat_kind):
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_begin_activity_stat_hold(card, skill_id, action_id, stat_kind, mouse_event.global_position, -1)
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			_begin_activity_stat_hold(card, skill_id, action_id, stat_kind, touch_event.position, touch_event.index)


func _begin_activity_stat_hold(card: Dictionary, skill_id: String, action_id: String, stat_kind: String, pointer_position: Vector2, pointer_id: int) -> void:
	if card.is_empty() or stat_kind.is_empty():
		return
	var card_key := str(card.get("card_key", host._action_key(skill_id, action_id)))
	host._action_stop_hold().begin_info(skill_id, action_id, stat_kind, card_key, pointer_position, pointer_id)
	host.get_viewport().set_input_as_handled()


func _toggle_activity_stat_popup_for_card(card: Dictionary, skill_id: String, action_id: String, stat_kind: String) -> void:
	var action: Dictionary = host._action_data(skill_id, action_id)
	if action.is_empty() or card.is_empty():
		return
	if _tutorial_blocks_activity_info_chips():
		return
	if _action_info_chips_blocked_by_lock(card):
		return
	if _activity_stat_clicks_should_start_action() and host._activity_unlock_runtime()._is_action_unlocked(skill_id, action):
		host._action_runtime()._start_action_from_card_tap(skill_id, action_id)
		return
	var key := str(card.get("card_key", host._action_key(skill_id, action_id)))
	var now := Time.get_ticks_msec()
	if (
		last_activity_stat_toggle_key == key
		and last_activity_stat_toggle_kind == stat_kind
		and now - last_activity_stat_toggle_msec < host.ACTION_CARD_DUPLICATE_TAP_MSEC
	):
		return
	last_activity_stat_toggle_key = key
	last_activity_stat_toggle_kind = stat_kind
	last_activity_stat_toggle_msec = now
	if expanded_activity_stat_key == key and expanded_activity_stat_kind == stat_kind:
		expanded_activity_stat_key = ""
		expanded_activity_stat_kind = ""
	else:
		expanded_activity_stat_key = key
		expanded_activity_stat_kind = stat_kind
	host._skill_swipe_activity_surface()._cancel_skill_swipe_feedback(false)
	action_card_press_key = ""
	host._update_ui(0.0, false)
	host._skill_swipe_activity_surface()._press_activity_stat_box(key, stat_kind)


func _clear_activity_stat_popup() -> void:
	expanded_activity_stat_key = ""
	expanded_activity_stat_kind = ""


func _activity_stat_kind_from_positions(card: Dictionary, positions: Array[Vector2]) -> String:
	if _tutorial_blocks_activity_info_chips():
		return ""
	if _activity_stat_clicks_should_start_action():
		return ""
	if _action_info_chips_blocked_by_lock(card):
		return ""
	for event_position in positions:
		var stat_kind := _activity_stat_kind_at_position(card, event_position)
		if not stat_kind.is_empty():
			return stat_kind
	return ""


func _event_positions_inside_activity_stat_box(card: Dictionary, stat_kind: String, positions: Array[Vector2]) -> bool:
	if stat_kind.is_empty() or card.is_empty():
		return false
	if stat_kind == host.ACTION_CARD_MEDAL_PRESS_KIND:
		return host._skill_swipe_activity_surface()._action_card_medal_hit_from_positions(card, positions)
	if not _action_stat_box_accepts_input(card, stat_kind):
		return false
	var boxes := card.get("stat_boxes", {}) as Dictionary
	var box := boxes.get(stat_kind, null) as Control
	if box == null or not is_instance_valid(box) or not box.is_visible_in_tree():
		return false
	var rect := box.get_global_rect()
	for event_position in positions:
		if rect.has_point(event_position):
			return true
	return false


func _activity_stat_clicks_should_start_action() -> bool:
	return host._action_runtime().activity_start_count <= 0


func _activity_stat_kind_at_position(card: Dictionary, event_position: Vector2) -> String:
	if _tutorial_blocks_activity_info_chips():
		return ""
	if _activity_stat_clicks_should_start_action():
		return ""
	if _action_info_chips_blocked_by_lock(card):
		return ""
	var stat_row := card.get("stat_row", null) as Control
	if stat_row != null and is_instance_valid(stat_row) and stat_row.is_visible_in_tree() and stat_row.get_global_rect().has_point(event_position):
		var row_boxes := card.get("stat_boxes", {}) as Dictionary
		for kind in ["xp", "stamina", "time", "success"]:
			var row_box := row_boxes.get(kind) as Control
			if row_box != null and is_instance_valid(row_box) and _action_stat_box_accepts_input(card, kind) and row_box.get_global_rect().has_point(event_position):
				return kind
	var boxes := card.get("stat_boxes", {}) as Dictionary
	for kind in ["xp", "stamina", "time", "success"]:
		var box := boxes.get(kind) as Control
		if box != null and is_instance_valid(box) and _action_stat_box_accepts_input(card, kind) and box.get_global_rect().has_point(event_position):
			return kind
	return ""


func _tutorial_blocks_activity_info_chips() -> bool:
	return host._onboarding_runtime().tutorial_active


func _action_stat_box_accepts_input(card: Dictionary, stat_kind: String) -> bool:
	if card.is_empty() or stat_kind.is_empty():
		return false
	if _tutorial_blocks_activity_info_chips():
		return false
	if _action_info_chips_blocked_by_lock(card):
		return false
	var boxes := card.get("stat_boxes", {}) as Dictionary
	var box := boxes.get(stat_kind, null) as Control
	if box == null or not is_instance_valid(box):
		return false
	if not bool(box.get_meta("action_stat_box_interactive", false)):
		return false
	if box.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return false
	return host._app_lifecycle_runtime().control_effectively_visible(box)


func _action_info_chips_blocked_by_lock(card: Dictionary) -> bool:
	if card.is_empty():
		return true
	var skill_id := str(card.get("skill_id", ""))
	var action_id := str(card.get("action_id", ""))
	var action := card.get("action", {}) as Dictionary
	if action.is_empty() and not skill_id.is_empty() and not action_id.is_empty():
		action = host._action_data(skill_id, action_id)
	if skill_id.is_empty() or action.is_empty():
		return true
	var resolved_action_id := str(action.get("id", action_id))
	return (
		not host._activity_unlock_runtime()._is_action_unlocked(skill_id, action)
		or bool(card.get("unlock_ceremony_pending", false))
		or bool(card.get("unlock_ceremony_active", false))
		or bool(card.get("unlock_ready_pending", false))
		or host._activity_unlock_runtime()._action_has_pending_unlock_readiness(resolved_action_id)
	)


func _sync_action_stat_box_input_enabled(card: Dictionary, enabled: bool) -> void:
	var boxes := card.get("stat_boxes", {}) as Dictionary
	for kind in boxes.keys():
		var box := boxes[kind] as Control
		if box == null or not is_instance_valid(box):
			continue
		if not bool(box.get_meta("action_stat_box_interactive", false)):
			continue
		box.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE


func _action_stat_label(text: String) -> Label:
	var label := host._label(text, 120, COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER) as Label
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _action_stat_box(label: Label, interactive := false, skill_id := "", action_id := "", stat_kind := "") -> Control:
	var box: Control = PanelContainer.new()
	box.custom_minimum_size = Vector2(300, 222)
	box.mouse_filter = Control.MOUSE_FILTER_STOP if interactive and not stat_kind.is_empty() else Control.MOUSE_FILTER_IGNORE
	box.set_meta("action_stat_box", true)
	box.set_meta("action_stat_box_interactive", interactive and not stat_kind.is_empty())
	if stat_kind == "xp":
		box.add_to_group("berry_prep_xp_chip_boxes")
		box.set_meta("berry_prep_skill_id", skill_id)
		box.set_meta("berry_prep_action_id", action_id)
		box.set_meta("berry_prep_value_label_id", label.get_instance_id())
	if interactive and not stat_kind.is_empty():
		box.gui_input.connect(_on_action_stat_box_gui_input.bind(skill_id, action_id, stat_kind))
	_apply_action_stat_box_style(box, false)
	if stat_kind.is_empty():
		box.add_child(label)
		return box
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 0)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.z_index = 2
	box.add_child(stack)
	label.add_theme_font_size_override("font_size", 96)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.z_index = 10
	stack.add_child(label)
	var title_label := _action_stat_label(str(stat_kind).to_upper())
	title_label.add_theme_font_size_override("font_size", 96)
	title_label.add_theme_color_override("font_color", ThemeStyles.ink_color(host.dark_mode_enabled, host.COLOR_INK, host.COLOR_DARK_INK))
	title_label.add_theme_constant_override("outline_size", 0)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_label.z_index = 10
	stack.add_child(title_label)
	label.set_meta("stat_title_label", title_label)
	return box


func _compact_action_stat_box(box: Control, value_label: Label) -> void:
	if box == null or value_label == null:
		return
	box.custom_minimum_size = Vector2(214, 142)
	value_label.add_theme_font_size_override("font_size", 96)
	var title_label := (value_label.get_meta("stat_title_label") as Label) if value_label.has_meta("stat_title_label") else null
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", 96)


func _normal_activity_stat_item(value_label: Label, stat_kind: String, interactive := false, skill_id := "", action_id := "") -> Control:
	var item := PanelContainer.new()
	item.custom_minimum_size = Vector2(0, 160)
	item.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	item.mouse_filter = Control.MOUSE_FILTER_STOP if interactive and not stat_kind.is_empty() else Control.MOUSE_FILTER_IGNORE
	item.set_meta("action_stat_box", true)
	item.set_meta("action_stat_box_interactive", interactive and not stat_kind.is_empty())
	item.set_meta("normal_activity_stat_box", true)
	if interactive and not stat_kind.is_empty():
		item.gui_input.connect(_on_action_stat_box_gui_input.bind(skill_id, action_id, stat_kind))
	_apply_action_stat_box_style(item, false)
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.add_theme_constant_override("separation", -8 if stat_kind == "time" or stat_kind == "success" else 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_child(row)
	var symbol_path: String = str({
		"xp": "res://assets/content/ui/infochip-symbol-xp-outlined.png",
		"time": "res://assets/content/ui/infochip-symbol-time-outlined.png",
		"stamina": "res://assets/content/ui/infochip-symbol-stamina-outlined.png",
		"success": "res://assets/content/ui/infochip-symbol-rate-outlined.png",
	}.get(stat_kind, ""))
	var symbol := TextureRect.new()
	symbol.custom_minimum_size = Vector2(160, 160)
	symbol.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	symbol.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	symbol.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	symbol.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	symbol.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	symbol.texture = host.visual_texture_cache._texture_or_visual_fallback(symbol_path)
	symbol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(symbol)
	item.set_meta("normal_activity_stat_symbol", symbol)
	item.set_meta("normal_activity_stat_value_label", value_label)
	value_label.add_theme_font_size_override("font_size", 96)
	value_label.add_theme_color_override("font_color", Color.WHITE)
	value_label.add_theme_color_override("font_outline_color", COLOR_INK)
	value_label.add_theme_constant_override("outline_size", 32)
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	value_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	value_label.custom_minimum_size.y = 160
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	value_label.set_meta("normal_activity_stat_text", true)
	row.add_child(value_label)
	return item


func _wiggle_normal_activity_stat_symbol(box: Control) -> void:
	if box == null or not is_instance_valid(box) or not box.has_meta("normal_activity_stat_symbol"):
		return
	var symbol := box.get_meta("normal_activity_stat_symbol") as Control
	if symbol == null or not is_instance_valid(symbol) or not symbol.is_inside_tree():
		return
	host._app_lifecycle_runtime()._kill_meta_tween(symbol, "normal_activity_stat_wiggle_tween")
	symbol.pivot_offset = symbol.size * 0.5
	symbol.rotation = 0.0
	var value_label := box.get_meta("normal_activity_stat_value_label") as Control
	if value_label != null and is_instance_valid(value_label):
		value_label.pivot_offset = value_label.size * 0.5
		value_label.scale = Vector2.ONE
	var tween: Tween = host.create_tween()
	symbol.set_meta("normal_activity_stat_wiggle_tween", tween)
	tween.tween_property(symbol, "rotation", -0.075, 0.07).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if value_label != null and is_instance_valid(value_label):
		tween.parallel().tween_property(value_label, "scale", Vector2(1.08, 1.08), 0.07).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(symbol, "rotation", 0.065, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if value_label != null and is_instance_valid(value_label):
		tween.parallel().tween_property(value_label, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(symbol, "rotation", -0.035, 0.09).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(symbol, "rotation", 0.0, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_finish_normal_activity_stat_symbol_wiggle.bind(symbol.get_instance_id(), value_label.get_instance_id() if value_label != null else 0))


func _finish_normal_activity_stat_symbol_wiggle(symbol_id: int, value_label_id: int) -> void:
	var symbol: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(symbol_id))
	if symbol == null:
		return
	symbol.rotation = 0.0
	if symbol.has_meta("normal_activity_stat_wiggle_tween"):
		symbol.remove_meta("normal_activity_stat_wiggle_tween")
	if value_label_id > 0:
		var value_label: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(value_label_id))
		if value_label != null:
			value_label.scale = Vector2.ONE


func _normal_activity_stat_row_label() -> Label:
	var label := host._label("", 68, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT) as Label
	label.add_theme_color_override("font_outline_color", COLOR_INK)
	label.add_theme_constant_override("outline_size", 24)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _normal_activity_stat_panel(minimum_size: Vector2, outline_color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum_size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.z_index = 20
	var style := StyleBoxFlat.new()
	style.bg_color = outline_color
	style.border_color = COLOR_INK
	style.set_border_width_all(14)
	style.set_corner_radius_all(32)
	style.content_margin_left = 32
	style.content_margin_right = 32
	style.content_margin_top = 28
	style.content_margin_bottom = 14
	style.anti_aliasing = true
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _sync_normal_activity_stat_text(card: Dictionary, show_stamina_stat: bool, time_title: String) -> void:
	var xp_label := card.get("xp") as Label
	if xp_label != null and xp_label.text.begins_with("+"):
		host._app_lifecycle_runtime().set_label_text_if_changed(xp_label, xp_label.text.trim_prefix("+"))
	var top_label := card.get("normal_stat_top") as Label
	var bottom_label := card.get("normal_stat_bottom") as Label
	if top_label == null or bottom_label == null:
		return
	var stamina_label := card.get("stamina") as Label
	var time_label := card.get("time") as Label
	var success_label := card.get("success") as Label
	if xp_label == null or time_label == null or success_label == null:
		return
	var top_text := "%s XP  •  %s %s" % [xp_label.text, time_label.text, time_title]
	var normal_separator := "  •  "
	top_text = "%s XP%s%s %s" % [xp_label.text, normal_separator, time_label.text, time_title]
	var bottom_parts := []
	if show_stamina_stat and stamina_label != null and not stamina_label.text.is_empty():
		bottom_parts.append("%s STAM" % stamina_label.text)
	if not success_label.text.is_empty():
		bottom_parts.append("%s RATE" % success_label.text)
	var bottom_text := ""
	for part_index in range(bottom_parts.size()):
		if part_index > 0:
			bottom_text += "  •  "
		bottom_text += str(bottom_parts[part_index])
	bottom_text = ""
	for part_index in range(bottom_parts.size()):
		if part_index > 0:
			bottom_text += normal_separator
		bottom_text += str(bottom_parts[part_index])
	host._app_lifecycle_runtime().set_label_text_if_changed(top_label, top_text)
	host._app_lifecycle_runtime().set_label_text_if_changed(bottom_label, bottom_text)


func _sync_action_stat_chip_label_style(label: Label, buffed: bool, theme_color: Color, box: Control = null) -> void:
	if label == null:
		return
	if box == null:
		box = _action_stat_box_for_label(label)
	if box != null:
		box.set_meta("stat_box_buffed", buffed)
		box.set_meta("stat_box_theme_color", theme_color)
		_apply_action_stat_box_style(box, bool(box.get_meta("stat_box_style_active", false)))
	var style_key := "%s:%s:%s" % [buffed, theme_color.to_html(true), host.dark_mode_enabled]
	if str(label.get_meta("stat_chip_style_key", "")) == style_key:
		return
	label.set_meta("stat_chip_style_key", style_key)
	var title_label := (label.get_meta("stat_title_label") as Label) if label.has_meta("stat_title_label") else null
	if bool(label.get_meta("normal_activity_stat_text", false)):
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 32)
		if title_label != null:
			title_label.add_theme_color_override("font_color", Color("#ffd54a"))
			title_label.add_theme_color_override("font_outline_color", COLOR_INK)
			title_label.add_theme_constant_override("outline_size", 32)
		return
	if buffed:
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_constant_override("outline_size", 0)
		if title_label != null:
			title_label.add_theme_color_override("font_color", Color.WHITE)
			title_label.add_theme_constant_override("outline_size", 0)
	else:
		var ink_color := ThemeStyles.ink_color(host.dark_mode_enabled, host.COLOR_INK, host.COLOR_DARK_INK)
		label.add_theme_color_override("font_color", ink_color)
		label.add_theme_constant_override("outline_size", 0)
		if title_label != null:
			title_label.add_theme_color_override("font_color", ink_color)
			title_label.add_theme_constant_override("outline_size", 0)


func _action_stat_box_for_label(label: Label) -> Control:
	if label == null:
		return null
	var parent := label.get_parent()
	if parent is Control and bool((parent as Control).get_meta("action_stat_box", false)):
		return parent as Control
	if parent != null and parent.get_parent() is Control:
		var grandparent := parent.get_parent() as Control
		if bool(grandparent.get_meta("action_stat_box", false)):
			return grandparent
	return null


func _apply_action_stat_box_style(box: Control, active := false, pressed := false) -> void:
	var style_key := _action_stat_box_style_key(box, active, pressed)
	if str(box.get_meta("action_stat_box_style_key", "")) == style_key:
		return
	var style := _stat_box_style_for_box(box, active, pressed)
	if box is Button:
		var button := box as Button
		button.add_theme_stylebox_override("normal", _stat_box_style_for_box(box, active))
		button.add_theme_stylebox_override("hover", _stat_box_style_for_box(box, active))
		button.add_theme_stylebox_override("pressed", _stat_box_style_for_box(box, active, true))
		button.add_theme_stylebox_override("focus", host.empty_style_cache)
	elif box is PanelContainer:
		(box as PanelContainer).add_theme_stylebox_override("panel", style)
	elif box is Panel:
		(box as Panel).add_theme_stylebox_override("panel", style)
	box.set_meta("action_stat_box_style_key", style_key)


func _action_stat_box_style_key(box: Control, active := false, pressed := false) -> String:
	var normal_activity_stat_box := box != null and bool(box.get_meta("normal_activity_stat_box", false))
	var buffed := box != null and bool(box.get_meta("stat_box_buffed", false))
	var theme_variant = box.get_meta("stat_box_theme_color", host.COLOR_BLUE) if box != null else host.COLOR_BLUE
	var theme_color := theme_variant as Color
	return "%s:%s:%s:%s:%s" % [active, pressed, buffed, normal_activity_stat_box, theme_color.to_html(true)]


func _stat_box_style_for_box(box: Control, active := false, pressed := false) -> StyleBox:
	if box != null and bool(box.get_meta("normal_activity_stat_box", false)):
		return _normal_activity_stat_box_style(pressed)
	if box != null and bool(box.get_meta("stat_box_buffed", false)):
		var theme_variant = box.get_meta("stat_box_theme_color", host.COLOR_BLUE)
		var theme_color := theme_variant as Color
		return _stat_box_style(active, pressed, theme_color)
	return _stat_box_style(active, pressed)


func _normal_activity_stat_box_style(pressed := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color.TRANSPARENT
	style.set_border_width_all(0)
	style.set_corner_radius_all(0)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	style.anti_aliasing = true
	return style


func _stat_box_style(active := false, pressed := false, fill := Color.WHITE) -> StyleBoxTexture:
	var outline: Color = host.COLOR_BLUE if active else COLOR_INK
	return PaperButtonStyles.paper_button_style_with_shape(fill, 38, 18, pressed, false, outline, 5.5, host.paper_button_style_textures, host.dark_mode_enabled, ActivityCardStyles.ACTION_CARD_STROKE_WIDTH, Callable(host, "_theme_surface_color"), Callable(host, "_theme_outline_color"), Callable(host.visual_texture_cache, "_can_create_image_textures"), Callable(host.visual_texture_cache, "_create_image_texture"), Callable(host.visual_texture_cache, "_visual_fallback_texture"))


func _thieving_skill_info_button() -> Button:
	return _skill_header_info_button(
		"Thieving Failure",
		"In Thieving, failure means jail time.\nYour action resumes when the timer ends.\nA higher Thieving level reduces your jail timer."
	)


func _fishing_skill_info_button() -> Button:
	return _skill_header_info_button(
		"Fishing",
		"Fishing costs no stamina. Instead, you can collect fish to recover your stamina in other skills. Tap your stamina gauges to restore stamina."
	)


func _skill_header_info_button(title_text: String, body_text: String) -> Button:
	var button := Button.new()
	button.text = "i"
	button.tooltip_text = ""
	button.custom_minimum_size = Vector2(78, 78)
	button.size = button.custom_minimum_size
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.z_index = 12
	button.add_to_group("skill_header_info_buttons")
	button.add_theme_font_size_override("font_size", host.MIN_MOBILE_BODY_FONT_SIZE)
	_apply_info_symbol_button_text_color(button)
	button.add_theme_stylebox_override("normal", PassiveModuleStyles.round_button(host.COLOR_PANEL, COLOR_INK, Callable(host, "_surface_style"), Callable(host, "_theme_outline_color")))
	button.add_theme_stylebox_override("hover", PassiveModuleStyles.round_button(host.COLOR_PANEL.lightened(0.06), COLOR_INK, Callable(host, "_surface_style"), Callable(host, "_theme_outline_color")))
	button.add_theme_stylebox_override("pressed", PassiveModuleStyles.round_button(COLOR_GOLD.darkened(0.08), COLOR_INK, Callable(host, "_surface_style"), Callable(host, "_theme_outline_color")))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if host.app_bold_font != null:
		button.add_theme_font_override("font", host.app_bold_font)
	host.button_press_runtime.attach_button_depress_animation(button, 0.90)
	var popover := _skill_header_info_popover(title_text, body_text)
	button.add_child(popover)
	host._passive_firepit_surface()._prewarm_passive_info_popover(popover)
	button.pressed.connect(Callable(host._passive_firepit_surface(), "_toggle_passive_info_popover").bind(popover))
	return button


func _apply_info_symbol_button_text_color(button: Button) -> void:
	if button == null or not is_instance_valid(button):
		return
	var glyph_color := ThemeStyles.text_color(host.COLOR_INK, host.dark_mode_enabled, host.COLOR_INK, host.COLOR_DARK_INK, host.COLOR_MUTED, host.COLOR_DARK_MUTED, host.COLOR_LINE, host.COLOR_DARK_LINE)
	button.add_theme_color_override("font_color", glyph_color)
	button.add_theme_color_override("font_hover_color", glyph_color)
	button.add_theme_color_override("font_pressed_color", glyph_color)
	button.add_theme_color_override("font_disabled_color", glyph_color)


func _sync_info_symbol_button_text_colors() -> void:
	if not host.is_inside_tree():
		return
	for raw_button in host.get_tree().get_nodes_in_group("skill_header_info_buttons"):
		_apply_info_symbol_button_text_color(raw_button as Button)


func _hide_skill_header_info_on_outside_press(event: InputEvent) -> void:
	var event_position := Vector2.ZERO
	var pressed := false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_event := event as InputEventMouseButton
		event_position = mouse_event.global_position
		pressed = mouse_event.pressed
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		event_position = touch_event.position
		pressed = touch_event.pressed
	if not pressed:
		return
	var visible_popovers: Array[Control] = []
	for raw_popover in host.get_tree().get_nodes_in_group("skill_header_info_popovers"):
		var popover := raw_popover as Control
		if popover != null and is_instance_valid(popover) and popover.visible:
			visible_popovers.append(popover)
	if visible_popovers.is_empty():
		return
	for raw_button in host.get_tree().get_nodes_in_group("skill_header_info_buttons"):
		var button := raw_button as Control
		if button != null and is_instance_valid(button) and button.get_global_rect().grow(8.0).has_point(event_position):
			return
	for popover in visible_popovers:
		if popover.get_global_rect().grow(8.0).has_point(event_position):
			return
	for popover in visible_popovers:
		host._passive_firepit_surface()._hide_passive_info_popover(popover)


func _skill_header_info_popover(title_text: String, body_text: String) -> PanelContainer:
	var popover := PanelContainer.new()
	popover.position = Vector2(-520, 90)
	popover.custom_minimum_size = Vector2(980, 350)
	popover.size = popover.custom_minimum_size
	popover.visible = false
	popover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popover.z_index = 4095
	popover.z_as_relative = false
	popover.add_to_group("skill_header_info_popovers")
	popover.add_theme_stylebox_override("panel", PassiveModuleStyles.popup(host.COLOR_PANEL, COLOR_INK, Callable(host, "_surface_style")))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popover.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(stack)
	var title: Label = host._label(title_text, host.MIN_MOBILE_INFO_TITLE_FONT_SIZE, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(title)
	var body: Label = host._label(body_text, host.MIN_MOBILE_BODY_FONT_SIZE, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(920, 220)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(body)
	return popover


func _apply_recovery_progress_rail_shape(bar: ActivityProgressRail, action: Dictionary) -> void:
	if bar == null or not RecoveryModules.has_recovery(action):
		return
	bar.offset_top = -ActivityCardStyles.RECOVERY_WIDE_U_RAIL_HEIGHT
	bar.offset_bottom = -host.ACTION_PROGRESS_RAIL_INSET
	bar.bottom_radius = host.ACTION_CARD_FACE_RADIUS
	bar.bottom_shape = "wide_u"
	bar.wide_u_bottom_rise = RECOVERY_WIDE_U_BOTTOM_RISE
	bar.wide_u_shoulder_ratio = RECOVERY_WIDE_U_SHOULDER_RATIO
	bar.queue_redraw()
	bar._queue_opportunity_overlay_redraw()


func _apply_recovery_card_depth_shape(depth: ActivityCardDepth, action: Dictionary) -> void:
	if depth == null or not RecoveryModules.has_recovery(action):
		return
	depth.bottom_shape = "wide_u"
	depth.draw_lip_lines = true
	depth.wide_u_bottom_rise = RECOVERY_WIDE_U_BOTTOM_RISE
	depth.wide_u_shoulder_ratio = RECOVERY_WIDE_U_SHOULDER_RATIO
	depth.queue_redraw()


func _apply_recovery_card_background_shape(bg: Control, action: Dictionary) -> void:
	if bg == null or not RecoveryModules.has_recovery(action):
		return
	var rounded_bg := bg as RoundedTextureRect
	if rounded_bg == null:
		return
	rounded_bg.bottom_shape = "wide_u"
	rounded_bg.wide_u_bottom_rise = RECOVERY_WIDE_U_BOTTOM_RISE
	rounded_bg.wide_u_shoulder_ratio = RECOVERY_WIDE_U_SHOULDER_RATIO
	rounded_bg.queue_redraw()


func _skill_detail_bottom_scroll_pad(skill_id := "") -> float:
	var page_gap: float = host.THIEVING_SKILL_DETAIL_BOTTOM_SCROLL_PAD if skill_id == "thieving" else host.SKILL_DETAIL_BOTTOM_SCROLL_PAD
	return host._navigation_shell()._skills_content_bottom_inset_for_screen() + float(page_gap) + NavigationShell.PAGE_SWITCH_MODULE_HEIGHT + host.SKILL_DETAIL_BOTTOM_UI_CLEARANCE


func _detail_actions_bottom_scroll_pad(skill_id: String) -> float:
	var extra_pad := _detail_unlock_scroll_spacer_height(skill_id)
	if extra_pad > 0.0 and not _detail_unlock_extra_scroll_space_allowed(skill_id):
		extra_pad = 0.0
		detail_unlock_scroll_spacer_heights.erase(skill_id)
	return _skill_detail_bottom_scroll_pad(skill_id) + extra_pad


func _detail_unlock_extra_scroll_space_allowed(skill_id: String) -> bool:
	if current_screen != "skill" or skill_id.is_empty() or skill_id != selected_skill_id:
		return false
	return (
		host._activity_unlock_runtime().has_pending_readiness_for_skill(skill_id)
		or host._activity_unlock_ceremony_surface().ceremony_count > 0
		or not host._activity_unlock_ceremony_surface().preview_after_ceremony_id.is_empty()
		or not host._activity_unlock_ceremony_surface().heist_preview_after_ceremony_id.is_empty()
	)


func _sync_detail_actions_bottom_spacer() -> void:
	if detail_unlock_scroll_spacer == null or not is_instance_valid(detail_unlock_scroll_spacer):
		return
	var height := _detail_actions_bottom_scroll_pad(selected_skill_id)
	var next_visible := height > 1.0
	if (
		absf(detail_unlock_scroll_spacer.custom_minimum_size.y - height) <= 0.5
		and detail_unlock_scroll_spacer.visible == next_visible
	):
		return
	detail_unlock_scroll_spacer.custom_minimum_size = Vector2(0, height)
	detail_unlock_scroll_spacer.visible = next_visible
	detail_unlock_scroll_spacer.update_minimum_size()


func _set_detail_unlock_scroll_spacer_height(height: float) -> void:
	var normalized_height := maxf(0.0, height)
	var current_height := _detail_unlock_scroll_spacer_height(selected_skill_id)
	if absf(current_height - normalized_height) <= 0.5:
		return
	if selected_skill_id.is_empty():
		detail_unlock_scroll_spacer_heights.clear()
	elif normalized_height > 1.0:
		detail_unlock_scroll_spacer_heights[selected_skill_id] = normalized_height
	else:
		detail_unlock_scroll_spacer_heights.erase(selected_skill_id)
	_sync_detail_actions_bottom_spacer()


func _detail_unlock_scroll_spacer_height(skill_id: String) -> float:
	if skill_id.is_empty() or not detail_unlock_scroll_spacer_heights.has(skill_id):
		return 0.0
	return maxf(0.0, float(detail_unlock_scroll_spacer_heights.get(skill_id, 0.0)))


func _sync_detail_actions_scroll_limit_deferred() -> void:
	await host.get_tree().process_frame
	await host.get_tree().process_frame
	_sync_detail_actions_scroll_limit()


func _sync_detail_actions_scroll_limit() -> void:
	if current_screen != "skill":
		return
	if detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll):
		return
	host._activity_unlock_ceremony_surface().sync_hidden_locked_activity_preview_layouts()
	if boot_detail_scroll_locked:
		detail_actions_scroll.set_max_scroll_override(0)
		detail_actions_scroll.set_scroll_enabled_by_content(false)
		return
	var visible_content := _detail_authoritative_scrollable_module_bottom()
	if int(visible_content.get("count", 0)) <= 0:
		detail_actions_scroll.set_max_scroll_override(-1)
		detail_actions_scroll.set_scroll_enabled_by_content(true)
		return
	var viewport_height := _detail_actions_scroll_viewport_height()
	var real_content_bottom := float(visible_content.get("bottom", 0.0))
	var bottom_gap := maxf(0.0, _skill_detail_bottom_scroll_pad(selected_skill_id) - host._navigation_shell()._skills_content_bottom_inset_for_screen())
	if int(visible_content.get("count", 0)) <= 1 and _detail_has_hidden_locked_activity_preview():
		bottom_gap = 0.0
	else:
		var page_switch_bottom := _detail_stack_page_switch_bottom()
		if page_switch_bottom >= 0.0:
			real_content_bottom = maxf(real_content_bottom, page_switch_bottom)
		var page_gap: float = host.THIEVING_SKILL_DETAIL_BOTTOM_SCROLL_PAD if selected_skill_id == "thieving" else host.SKILL_DETAIL_BOTTOM_SCROLL_PAD
		bottom_gap = maxf(0.0, bottom_gap - NavigationShell.PAGE_SWITCH_MODULE_HEIGHT - float(page_gap) - 12.0)
	var max_scroll_to_content := maxi(0, int(ceil(real_content_bottom + bottom_gap - viewport_height)))
	detail_actions_scroll.set_max_scroll_override(max_scroll_to_content)
	detail_actions_scroll.set_scroll_enabled_by_content(true)
	if detail_actions_scroll.scroll_vertical > detail_actions_scroll.get_max_scroll_vertical():
		var clamped_scroll: int = detail_actions_scroll.get_max_scroll_vertical()
		detail_actions_scroll.drag_scroll_position = float(clamped_scroll)
		detail_actions_scroll.scroll_vertical = clamped_scroll


func _detail_actions_scroll_viewport_height() -> float:
	if detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll):
		return 0.0
	var viewport_height: float = detail_actions_scroll.size.y
	if viewport_height <= 1.0:
		viewport_height = detail_actions_scroll.custom_minimum_size.y
	var obscured_bottom: float = host._navigation_shell()._skills_content_bottom_inset_for_screen()
	if viewport_height > obscured_bottom + 1.0:
		viewport_height -= obscured_bottom
	if viewport_height <= 1.0:
		viewport_height = host._current_canvas_size().y - SKILL_DETAIL_HEADER_HEIGHT - SKILL_DETAIL_ACTIONS_DIVIDER_HEIGHT - host._navigation_shell()._bottom_ui_reserved_height_for_current_screen()
	return maxf(1.0, viewport_height)


func _detail_stack_page_switch_bottom() -> float:
	var stack := _detail_actions_stack()
	if stack == null or not is_instance_valid(stack):
		return -1.0
	for child in stack.get_children():
		var control := child as Control
		if control == null or not is_instance_valid(control):
			continue
		if control.name == "PageSwitchModule":
			return _detail_control_bottom_in_stack(control, stack)
	return -1.0


func _detail_authoritative_scrollable_module_bottom() -> Dictionary:
	var stack_bottom := _detail_stack_module_content_bottom()
	if detail_lazy_plan.is_empty() or _detail_lazy_all_mounted():
		if int(stack_bottom.get("count", 0)) > 0:
			return stack_bottom
	var lazy_bottom := _detail_lazy_plan_module_content_bottom()
	if int(lazy_bottom.get("count", 0)) > 0:
		if int(stack_bottom.get("count", 0)) > 0:
			return {
				"bottom": maxf(float(lazy_bottom.get("bottom", 0.0)), float(stack_bottom.get("bottom", 0.0))),
				"count": int(lazy_bottom.get("count", 0)) + int(stack_bottom.get("count", 0))
			}
		return lazy_bottom
	if int(stack_bottom.get("count", 0)) > 0:
		return stack_bottom
	var registry_bottom := _detail_actions_scrollable_content_bottom()
	if int(registry_bottom.get("count", 0)) > 0:
		return registry_bottom
	return {"bottom": 0.0, "count": 0}


func _detail_has_hidden_locked_activity_preview() -> bool:
	if action_cards.is_empty():
		return false
	for raw_card in action_cards.values():
		var card := raw_card as Dictionary
		if bool(card.get("locked_preview_hidden", false)):
			return true
	return false


func _detail_lazy_plan_module_content_bottom() -> Dictionary:
	if detail_lazy_plan.is_empty():
		return {"bottom": 0.0, "count": 0}
	var stack := _detail_actions_stack()
	if stack == null or not is_instance_valid(stack):
		return {"bottom": 0.0, "count": 0}
	var bottom := 0.0
	var count := 0
	var top_spacer_height := _detail_actions_top_spacer_height()
	var stack_separation := float(stack.get_theme_constant("separation"))
	for raw_lazy_entry in detail_lazy_plan:
		var lazy_entry := raw_lazy_entry as Dictionary
		var kind := str(lazy_entry.get("kind", ""))
		if not _detail_lazy_kind_is_module(kind):
			continue
		var action_key: String = host._action_key(selected_skill_id, str(lazy_entry.get("track_id", "")))
		var action_card := action_cards.get(action_key, {}) as Dictionary
		if bool(action_card.get("locked_preview_hidden", false)):
			continue
		var stack_host: Control = host._app_lifecycle_runtime().valid_control_ref(lazy_entry.get("stack_host"))
		var host_bottom := -1.0
		if stack_host != null and is_instance_valid(stack_host):
			host_bottom = _detail_control_bottom_in_stack(stack_host, stack)
		if stack_host != null and host_bottom < 0.0:
			continue
		if host_bottom < 0.0:
			host_bottom = top_spacer_height + stack_separation + float(lazy_entry.get("y", 0.0)) + float(lazy_entry.get("height", ActivityCardStyles.root_height(false, host.ACTION_CARD_HEIGHT, host.ACTION_CARD_EXPANDED_HEIGHT, host.ACTION_CARD_3D_DEPTH_OFFSET.y)))
		if host_bottom > 1.0:
			bottom = maxf(bottom, host_bottom)
			count += 1
	if count <= 0:
		return {"bottom": 0.0, "count": 0}
	return {"bottom": bottom, "count": count}


func _detail_stack_module_content_bottom() -> Dictionary:
	var stack := _detail_actions_stack()
	if stack == null or not is_instance_valid(stack):
		return {"bottom": 0.0, "count": 0}
	var bottom := 0.0
	var count := 0
	for child in stack.get_children():
		var control := child as Control
		if control == null or not is_instance_valid(control):
			continue
		if not _detail_stack_child_is_module_content(control):
			continue
		var child_bottom := _detail_control_bottom_in_stack(control, stack)
		if child_bottom < 0.0:
			continue
		bottom = maxf(bottom, child_bottom)
		count += 1
	if count <= 0:
		return {"bottom": 0.0, "count": 0}
	return {"bottom": bottom, "count": count}


func _detail_actions_top_spacer_height() -> float:
	if detail_actions_top_spacer != null and is_instance_valid(detail_actions_top_spacer):
		return maxf(detail_actions_top_spacer.size.y, detail_actions_top_spacer.custom_minimum_size.y)
	return float(host.SKILL_DETAIL_ACTIONS_TOP_SPACER_HEIGHT)


func _detail_stack_child_is_module_content(control: Control) -> bool:
	if control == null or not is_instance_valid(control):
		return false
	if control.name == "DetailActionsTopSpacer" or control.name == "DetailActionsBottomSpacer" or control.name == "PageSwitchModule":
		return false
	if not control.visible or control.is_queued_for_deletion() or control.modulate.a <= 0.01:
		return false
	if bool(control.get_meta("detail_lazy_placeholder", false)):
		return false
	if bool(control.get_meta("skill_swipe_preview_placeholder", false)):
		return false
	if _detail_control_has_any_group(control, ["activity_start_tip_notes", "skill_swipe_tip_notes", "onboarding_explore_tip_notes", "lock_click_tip_notes"]):
		return false
	if bool(control.get_meta("detail_stack_entry_wrapper", false)) and not _detail_lazy_slot_has_real_content(control):
		return false
	var height := maxf(control.size.y, control.custom_minimum_size.y)
	return height > 1.0


func _detail_control_has_any_group(control: Control, group_names: Array) -> bool:
	if control == null or not is_instance_valid(control):
		return false
	for raw_group in group_names:
		if control.is_in_group(str(raw_group)):
			return true
	for raw_child in control.get_children():
		var child := raw_child as Control
		if child != null and _detail_control_has_any_group(child, group_names):
			return true
	return false


func _detail_actions_scrollable_content_bottom() -> Dictionary:
	var stack := _detail_actions_stack()
	if stack == null or not is_instance_valid(stack):
		return {"bottom": 0.0, "count": 0}
	var bottom := 0.0
	var count := 0
	var measured_nodes := {}
	for raw_action_id in detail_rendered_action_ids:
		var action_id := str(raw_action_id)
		if not detail_action_card_nodes.has(action_id):
			continue
		var node: Control = host._app_lifecycle_runtime().valid_control_ref(detail_action_card_nodes.get(action_id))
		if node == null or not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var node_id: int = node.get_instance_id()
		if measured_nodes.has(node_id):
			continue
		measured_nodes[node_id] = true
		var node_bottom := _detail_card_node_bottom_in_stack(node, stack)
		if node_bottom < 0.0:
			continue
		bottom = maxf(bottom, node_bottom)
		count += 1
	for raw_node in detail_action_card_nodes.values():
		var extra_node: Control = host._app_lifecycle_runtime().valid_control_ref(raw_node)
		if extra_node == null or not is_instance_valid(extra_node) or extra_node.is_queued_for_deletion():
			continue
		var extra_node_id: int = extra_node.get_instance_id()
		if measured_nodes.has(extra_node_id):
			continue
		measured_nodes[extra_node_id] = true
		var node_bottom := _detail_card_node_bottom_in_stack(extra_node, stack)
		if node_bottom < 0.0:
			continue
		bottom = maxf(bottom, node_bottom)
		count += 1
	if _detail_unlock_extra_scroll_space_allowed(selected_skill_id):
		var spacer_bottom := _detail_unlock_scroll_spacer_bottom_in_stack(stack)
		if spacer_bottom >= 0.0:
			bottom = maxf(bottom, spacer_bottom)
	if count > 0:
		return {"bottom": bottom, "count": count}
	return {"bottom": 0.0, "count": 0}


func _detail_card_node_bottom_in_stack(node: Control, stack: Control) -> float:
	var stack_child := _detail_stack_child_for_control(node, stack)
	if stack_child == null:
		return -1.0
	if bool(stack_child.get_meta("detail_stack_entry_wrapper", false)):
		var content_bottom := _detail_slot_content_bottom_in_stack(stack_child, stack)
		if content_bottom >= 0.0:
			return content_bottom
	return _detail_control_bottom_in_stack(node, stack)


func _detail_slot_content_bottom_in_stack(slot: Control, stack: Control) -> float:
	if slot == null or stack == null or not is_instance_valid(slot) or not is_instance_valid(stack):
		return -1.0
	if slot.name == "DetailActionsTopSpacer" or slot.name == "DetailActionsBottomSpacer":
		return -1.0
	if bool(slot.get_meta("detail_lazy_placeholder", false)):
		return -1.0
	var bottom := -1.0
	for raw_child in slot.get_children():
		var child := raw_child as Control
		if child == null or not is_instance_valid(child):
			continue
		if not child.visible or child.is_queued_for_deletion():
			continue
		if bool(child.get_meta("detail_lazy_placeholder", false)):
			continue
		var child_bottom := _detail_control_bottom_in_stack(child, stack)
		if child_bottom >= 0.0:
			bottom = maxf(bottom, child_bottom)
	if bottom >= 0.0:
		return bottom
	return _detail_control_bottom_in_stack(slot, stack)


func _detail_control_bottom_in_stack(control: Control, stack: Control) -> float:
	if control == null or stack == null or not is_instance_valid(control) or not is_instance_valid(stack):
		return -1.0
	if not control.visible or control.is_queued_for_deletion():
		return -1.0
	var rect := _detail_control_rect_in_stack(control, stack)
	if rect.size.y <= 1.0:
		return -1.0
	return rect.position.y + rect.size.y


func _detail_control_rect_in_stack(control: Control, stack: Control) -> Rect2:
	var size_for_rect := control.size
	if size_for_rect.y <= 1.0:
		size_for_rect.y = control.custom_minimum_size.y
	if size_for_rect.x <= 1.0:
		size_for_rect.x = control.custom_minimum_size.x
	var position_in_stack := control.position
	var parent := control.get_parent() as Control
	while parent != null and is_instance_valid(parent):
		if parent == stack:
			return Rect2(position_in_stack, size_for_rect)
		position_in_stack += parent.position
		parent = parent.get_parent() as Control
	return Rect2(Vector2.ZERO, Vector2.ZERO)


func _detail_unlock_scroll_spacer_bottom_in_stack(stack: Control) -> float:
	if detail_unlock_scroll_spacer == null or not is_instance_valid(detail_unlock_scroll_spacer):
		return -1.0
	if not detail_unlock_scroll_spacer.visible:
		return -1.0
	var height := maxf(detail_unlock_scroll_spacer.size.y, detail_unlock_scroll_spacer.custom_minimum_size.y)
	if height <= 1.0:
		return -1.0
	return _detail_control_bottom_in_stack(detail_unlock_scroll_spacer, stack)


func _detail_stack_child_for_control(control: Control, stack: Control) -> Control:
	if control == null or stack == null or not is_instance_valid(control) or not is_instance_valid(stack):
		return null
	if control.get_parent() == stack:
		return control
	var parent := control.get_parent() as Control
	while parent != null and is_instance_valid(parent):
		if parent.get_parent() == stack:
			return parent
		parent = parent.get_parent() as Control
	return null


func _preserve_detail_scroll_after_height_change_if_above_view(control: Control) -> void:
	var context := _detail_scroll_height_change_preserve_context(control)
	if context.is_empty():
		return
	_preserve_detail_scroll_after_height_change_deferred(context)


func _detail_scroll_height_change_preserve_context(control: Control) -> Dictionary:
	if current_screen != "skill" or detail_actions_scroll == null or control == null:
		return {}
	if not is_instance_valid(detail_actions_scroll) or not is_instance_valid(control):
		return {}
	var stack := _detail_actions_stack()
	if stack == null or not is_instance_valid(stack):
		return {}
	var tracked := _detail_stack_child_for_control(control, stack)
	if tracked == null or not is_instance_valid(tracked):
		return {}
	var before_rect := _detail_control_rect_in_stack(tracked, stack)
	var before_scroll: int = detail_actions_scroll.scroll_vertical
	if before_rect.position.y >= float(before_scroll) - 2.0:
		return {}
	return {
		"tracked_id": tracked.get_instance_id(),
		"before_height": before_rect.size.y,
		"before_scroll": before_scroll,
		"last_scroll": before_scroll,
		"cancelled": false
	}


func _preserve_detail_scroll_after_height_change_deferred(context: Dictionary) -> void:
	await host.get_tree().process_frame
	_apply_detail_scroll_height_change_preserve_context(1.0, context)


func _apply_detail_scroll_height_change_preserve_context(_progress: float, context: Dictionary) -> void:
	if context.is_empty() or bool(context.get("cancelled", false)):
		return
	if current_screen != "skill" or detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll):
		return
	var last_scroll := int(context.get("last_scroll", context.get("before_scroll", 0)))
	if absi(detail_actions_scroll.scroll_vertical - last_scroll) > 4:
		context["cancelled"] = true
		return
	var tracked: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(int(context.get("tracked_id", 0))))
	var stack := _detail_actions_stack()
	if tracked == null or stack == null or not is_instance_valid(stack):
		return
	var after_rect := _detail_control_rect_in_stack(tracked, stack)
	var height_delta := after_rect.size.y - float(context.get("before_height", 0.0))
	if absf(height_delta) <= 0.5:
		return
	var before_scroll := int(context.get("before_scroll", 0))
	var target_scroll := clampi(before_scroll + int(round(height_delta)), 0, detail_actions_scroll.get_max_scroll_vertical())
	detail_actions_scroll.drag_scroll_position = float(target_scroll)
	detail_actions_scroll.scroll_vertical = target_scroll
	context["last_scroll"] = target_scroll


func _release_detail_unlock_extra_scroll_space() -> void:
	if detail_unlock_scroll_spacer == null or not is_instance_valid(detail_unlock_scroll_spacer):
		return
	if detail_unlock_scroll_spacer_tween != null and detail_unlock_scroll_spacer_tween.is_valid():
		detail_unlock_scroll_spacer_tween.kill()
	var base_pad := _skill_detail_bottom_scroll_pad(selected_skill_id)
	var start_height := maxf(detail_unlock_scroll_spacer.custom_minimum_size.y, _detail_actions_bottom_scroll_pad(selected_skill_id))
	var start_extra := maxf(0.0, start_height - base_pad)
	if start_extra <= 1.0:
		_set_detail_unlock_scroll_spacer_height(0.0)
		return
	detail_unlock_scroll_spacer_tween = host.create_tween()
	detail_unlock_scroll_spacer_tween.tween_interval(ActivityUnlockCeremonySurface.SPACER_SETTLE_SECONDS)
	detail_unlock_scroll_spacer_tween.finished.connect(_finish_detail_unlock_scroll_spacer_tween)


func _finish_detail_unlock_scroll_spacer_tween() -> void:
	_set_detail_unlock_scroll_spacer_height(0.0)
	detail_unlock_auto_scroll_interrupted = false
	detail_unlock_scroll_spacer_tween = null


func _visible_detail_regen_gauge_needs_header_refresh() -> bool:
	if current_screen != "skill" or host._fishing_rework_active_for_skill(selected_skill_id):
		return false
	if detail_regen_circle == null or not is_instance_valid(detail_regen_circle) or not detail_regen_circle.is_inside_tree():
		return false
	var maximum: float = float(SkillState.max_stamina(host, selected_skill_id))
	return SkillState.host_stamina_value(selected_skill_id, host) < float(maximum) - 0.0001


func _consume_detail_header_gauge_refresh(delta: float, instant: bool, static_refresh: bool, skill_frame_refresh: bool) -> bool:
	if instant or static_refresh:
		detail_header_gauge_refresh_elapsed = 0.0
		return true
	if not skill_frame_refresh or current_screen != "skill":
		return false
	detail_header_gauge_refresh_elapsed += maxf(0.0, delta)
	if detail_header_gauge_refresh_elapsed < host.DETAIL_HEADER_GAUGE_REFRESH_SECONDS:
		return false
	detail_header_gauge_refresh_elapsed = 0.0
	return true


func _consume_passive_card_progress_refresh(delta: float, instant: bool, static_refresh: bool, skill_frame_refresh: bool) -> bool:
	if instant or static_refresh:
		passive_card_progress_refresh_elapsed = 0.0
		return true
	if not skill_frame_refresh or current_screen != "skill":
		return false
	passive_card_progress_refresh_elapsed += maxf(0.0, delta)
	if passive_card_progress_refresh_elapsed < host.PASSIVE_CARD_PROGRESS_REFRESH_SECONDS:
		return false
	passive_card_progress_refresh_elapsed = 0.0
	return true


func _update_detail_header_gauges(static_refresh: bool, skill_frame_refresh: bool, detail_header_gauge_refresh: bool, delta: float, instant: bool) -> void:
	var detail_xp := SkillState.xp_progress(host.skills, selected_skill_id, SkillState.host_skill_level(host, selected_skill_id))
	if static_refresh and detail_xp_label != null:
		host._app_lifecycle_runtime().set_label_text_if_changed(detail_xp_label, SkillState.level_xp_text(host.skills, selected_skill_id, SkillState.host_skill_level(host, selected_skill_id)))
	if skill_frame_refresh and detail_xp_bar != null:
		if static_refresh:
			ThemeStyles.apply_xp_progress_bar_theme(detail_xp_bar, ThemeStyles.skill_theme_color(selected_skill_id, host.COLOR_BLUE), host.COLOR_INK)
		ThemeStyles.set_progress_bar_value(detail_xp_bar, float(detail_xp["pct"]), delta, instant)
	if detail_header_gauge_refresh and host._fishing_rework_active_for_skill(selected_skill_id):
		if detail_fish_circle != null:
			host._fishing_ui_surface()._set_fish_circle_for_skill(detail_fish_circle, selected_skill_id, instant)
	elif detail_header_gauge_refresh and detail_regen_circle != null:
		detail_regen_circle.sync_for_skill(host, selected_skill_id, instant)


func _clamp_detail_actions_scroll_to_content() -> void:
	if current_screen != "skill":
		return
	if detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll):
		return
	var max_scroll: int = detail_actions_scroll.get_max_scroll_vertical()
	if detail_actions_scroll.scroll_vertical <= max_scroll:
		detail_actions_scroll.drag_scroll_position = float(detail_actions_scroll.scroll_vertical)
		return
	detail_actions_scroll.drag_scroll_position = float(max_scroll)
	detail_actions_scroll.scroll_vertical = max_scroll


func _clamp_detail_actions_scroll_to_content_deferred() -> void:
	await host.get_tree().process_frame
	await host.get_tree().process_frame
	_clamp_detail_actions_scroll_to_content()


func _detail_actions_stack() -> Control:
	if detail_actions_scroll == null or detail_actions_scroll.get_child_count() <= 0:
		return null
	return detail_actions_scroll.get_child(0) as Control


func _resolve_detail_lazy_stack() -> VBoxContainer:
	if detail_lazy_stack != null and is_instance_valid(detail_lazy_stack):
		return detail_lazy_stack
	return _detail_actions_stack() as VBoxContainer


func _restore_detail_actions_scroll(target: int) -> void:
	if current_screen != "skill" or detail_actions_scroll == null:
		return
	await host.get_tree().process_frame
	if not module_ui_pending_pin_scroll_anchor.is_empty():
		return
	if detail_actions_scroll == null:
		return
	_sync_detail_actions_scroll_limit()
	detail_actions_scroll.scroll_to_vertical(mini(target, detail_actions_scroll.get_max_scroll_vertical()), 0.0)
	await host.get_tree().process_frame
	if not module_ui_pending_pin_scroll_anchor.is_empty():
		return
	if detail_actions_scroll != null:
		_sync_detail_actions_scroll_limit()
		detail_actions_scroll.scroll_to_vertical(mini(target, detail_actions_scroll.get_max_scroll_vertical()), 0.0)
	host._skill_swipe_activity_surface()._clear_skill_swipe_handoff_cover()


func _scroll_detail_actions_to_bottom_after_layout() -> void:
	if current_screen != "skill" or detail_actions_scroll == null:
		return
	await host.get_tree().process_frame
	await host.get_tree().process_frame
	if current_screen != "skill" or detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll):
		return
	_sync_detail_actions_scroll_limit()
	var max_scroll: int = detail_actions_scroll.get_max_scroll_vertical()
	detail_actions_scroll.drag_scroll_position = float(max_scroll)
	detail_actions_scroll.scroll_vertical = max_scroll
	detail_actions_scroll.scroll_to_vertical(max_scroll, 0.0)
	if host._navigation_shell()._page_switch_scroll_cover_active():
		host._skill_swipe_activity_surface()._force_skill_detail_reveal_mount_under_cover()
		host._navigation_shell()._fade_clear_page_switch_scroll_cover()
	elif host._skill_swipe_activity_surface()._skill_swipe_handoff_cover_is_opaque_cream_transition():
		host._skill_swipe_activity_surface()._force_skill_detail_reveal_mount_under_cover()
		host._fade_clear_skill_swipe_rebuild_cover()
	else:
		host._skill_swipe_activity_surface()._clear_skill_swipe_handoff_cover()


func _render_skill_detail(scroll_latest_activity = false, restore_detail_scroll = -1, async_action_cards = false, strip_index: int = -1):
	var strip_mode = strip_index >= 0
	var initial_drag_x = 0.0 if strip_mode else skill_swipe_gap_render_offset_x
	if not strip_mode:
		skill_swipe_drag_offset_x = initial_drag_x
	var content_width = host._skill_content_width()
	var actions_width = content_width
	if not _detail_unlock_extra_scroll_space_allowed(selected_skill_id):
		detail_unlock_scroll_spacer_heights.erase(selected_skill_id)
	if not strip_mode:
		var frame = Control.new()
		skill_swipe_frame = frame
		frame.clip_contents = false
		var frame_width = content_width
		host._skill_swipe_activity_surface()._apply_skill_column_layout(frame, frame_width, initial_drag_x)
		skills_content.add_child(frame)

	var page = VBoxContainer.new()
	skill_swipe_page = page
	if strip_mode:
		page.anchor_left = 0.0
		page.anchor_right = 0.0
		page.anchor_top = 0.0
		page.anchor_bottom = 1.0
		page.offset_left = float(strip_index) * content_width
		page.offset_right = float(strip_index) * content_width + content_width
		page.offset_top = 0.0
		page.offset_bottom = 0.0
		page.custom_minimum_size.x = content_width
	else:
		page.set_anchors_preset(Control.PRESET_FULL_RECT)
		page.custom_minimum_size.x = actions_width
		page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 0)
	page.z_index = 20
	skill_swipe_frame.add_child(page)

	var header = PanelContainer.new()
	header.custom_minimum_size = Vector2(0, SKILL_DETAIL_HEADER_HEIGHT)
	header.custom_minimum_size.x = content_width
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_stylebox_override("panel", _skill_detail_shelf_style(selected_skill_id, false))
	page.add_child(header)
	var header_body = Control.new()
	detail_header_body = header_body
	header_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	header.add_child(header_body)
	_add_skill_detail_shelf_background(header_body, selected_skill_id, content_width)
	var header_margin = MarginContainer.new()
	header_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	header_margin.add_theme_constant_override("margin_left", 66)
	header_margin.add_theme_constant_override("margin_right", 46)
	header_margin.add_theme_constant_override("margin_top", 88)
	header_margin.add_theme_constant_override("margin_bottom", SKILL_DETAIL_HEADER_MARGIN_BOTTOM)
	header_body.add_child(header_margin)
	var header_row = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 66)
	header_margin.add_child(header_row)

	var left_block = HBoxContainer.new()
	left_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_block.alignment = BoxContainer.ALIGNMENT_CENTER
	left_block.add_theme_constant_override("separation", SKILL_DETAIL_LEFT_SEPARATION)
	left_block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_row.add_child(left_block)
	detail_header_left_block = left_block
	var summary_icon = SkillIconBadge.detail_icon(host, selected_skill_id)
	left_block.add_child(summary_icon)
	var title_stack = VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	title_stack.add_theme_constant_override("separation", SKILL_DETAIL_TEXT_SEPARATION)
	title_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_block.add_child(title_stack)
	var title = host._label(SkillState.skill_name(host.skill_defs, selected_skill_id), SkillState.skill_detail_title_font_size(selected_skill_id, host.SKILL_DETAIL_TITLE_FONT_SIZE, host.SKILL_DETAIL_WOODCUTTING_TITLE_FONT_SIZE), COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if selected_skill_id in ["thieving", "fishing"]:
		var title_line = HBoxContainer.new()
		title_line.alignment = BoxContainer.ALIGNMENT_BEGIN
		title_line.add_theme_constant_override("separation", 22)
		title_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		title_stack.add_child(title_line)
		title_line.add_child(title)
		if selected_skill_id == "fishing":
			title_line.add_child(_fishing_skill_info_button())
		else:
			title_line.add_child(_thieving_skill_info_button())
	else:
		title_stack.add_child(title)
	var xp = SkillState.xp_progress(host.skills, selected_skill_id, SkillState.host_skill_level(host, selected_skill_id))
	detail_xp_label = host._label(SkillState.level_xp_text(host.skills, selected_skill_id, SkillState.host_skill_level(host, selected_skill_id)), SKILL_DETAIL_XP_FONT_SIZE, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	detail_xp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_stack.add_child(detail_xp_label)
	detail_xp_bar = ThemeStyles.skill_detail_xp_bar(selected_skill_id, float(xp["pct"]), host.COLOR_BLUE, host.COLOR_INK, host.SKILL_DETAIL_XP_BAR_HEIGHT, host.SKILL_DETAIL_XP_BAR_WIDTH)
	title_stack.add_child(detail_xp_bar)

	if boot_detail_card_yield:
		await host.get_tree().process_frame

	detail_stamina_bar = null
	if host._fishing_rework_active_for_skill(selected_skill_id):
		detail_regen_circle = null
		detail_regen_circle_host = null
		detail_regen_circle_fade_group = null
		detail_blue_guy_health_gauge = null
		detail_auto_eat_fish_button = null
		detail_fish_circle = FishCircle.new()
		detail_fish_circle.custom_minimum_size = Vector2(552, 552)
		detail_fish_circle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		detail_fish_circle.mouse_filter = Control.MOUSE_FILTER_PASS
		detail_fish_circle.z_index = 3000
		detail_fish_circle.z_as_relative = false
		header_row.add_child(detail_fish_circle)
		host._fishing_ui_surface()._attach_fishing_fish_circle_button(detail_fish_circle)
		host._fishing_ui_surface()._set_fish_circle_for_skill(detail_fish_circle, selected_skill_id, true)
	else:
		detail_fish_circle = null
		detail_blue_guy_health_gauge = null
		detail_regen_circle_host = Control.new()
		detail_regen_circle_host.custom_minimum_size = Vector2(552, 552)
		detail_regen_circle_host.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		detail_regen_circle_host.clip_contents = false
		detail_regen_circle_fade_group = CanvasGroup.new()
		detail_regen_circle = RegenCircle.new()
		detail_regen_circle.custom_minimum_size = Vector2(552, 552)
		detail_regen_circle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		detail_regen_circle.mouse_filter = Control.MOUSE_FILTER_STOP
		detail_regen_circle.modulate = Color.WHITE
		detail_regen_circle.set_dark_mode(dark_mode_enabled)
		detail_regen_circle.gui_input.connect(Callable(host._action_runtime(), "_on_stamina_gauge_input").bind("", detail_regen_circle))
		detail_regen_circle_fade_group.add_child(detail_regen_circle)
		detail_regen_circle_host.add_child(detail_regen_circle_fade_group)
		header_row.add_child(detail_regen_circle_host)
		detail_auto_eat_fish_button = host._fishing_ui_surface()._attach_auto_eat_fish_toggle(detail_regen_circle_host, selected_skill_id)
		detail_regen_circle.sync_for_skill(host, selected_skill_id, true)
	host._tutorial_overlay_surface()._apply_onboarding_fight_header_visibility()
	host._tutorial_overlay_surface()._apply_onboarding_fight_action_stats_visibility_all()
	_sync_skill_detail_back_arrow_visibility()
	if host._onboarding_runtime()._onboarding_auto_run_message_resumable():
		host._onboarding_runtime().call_deferred("_run_onboarding_auto_run_message_sequence")
	if host._onboarding_runtime()._onboarding_header_reveal_sequence_resumable():
		host._onboarding_runtime().call_deferred("_run_onboarding_header_reveal_sequence")
	elif onboarding_fight_stamina_revealed and not stamina_gauge_tip_seen and host._onboarding_runtime()._onboarding_fight_header_sequence_active():
		host._onboarding_runtime().call_deferred("_run_onboarding_stamina_tip_sequence")
	elif host._onboarding_runtime()._onboarding_swipe_tip_sequence_resumable():
		host._tutorial_overlay_surface().call_deferred("_run_onboarding_swipe_tip_sequence")
	elif host._fishing_rework_active_for_skill(selected_skill_id):
		host._onboarding_runtime()._dismiss_skill_detail_tutorial_tips()

	if boot_detail_card_yield:
		await host.get_tree().process_frame

	var divider = Control.new()
	divider.custom_minimum_size = Vector2(0, SKILL_DETAIL_ACTIONS_DIVIDER_HEIGHT)
	divider.custom_minimum_size.x = content_width
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_child(divider)

	var actions_clip = Control.new()
	actions_clip.custom_minimum_size.x = actions_width
	actions_clip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_clip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	actions_clip.clip_contents = true
	page.add_child(actions_clip)

	var actions_scroll = MobileScrollContainer.new()
	detail_actions_scroll = actions_scroll
	detail_pull_tip_root = null
	detail_pull_tip_label = null
	detail_pull_tip_active = false
	detail_pull_tip_direction = 0
	detail_action_card_nodes.clear()
	detail_rendered_action_ids.clear()
	actions_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	actions_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	actions_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	actions_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	actions_scroll.clip_contents = true
	actions_scroll.set_pull_resistance_enabled(true)
	actions_scroll.pull_offset_changed.connect(_on_detail_actions_pull_offset_changed)
	if not actions_scroll.user_scroll_direction.is_connected(_on_detail_actions_user_scroll_direction):
		actions_scroll.user_scroll_direction.connect(_on_detail_actions_user_scroll_direction)
	actions_clip.add_child(actions_scroll)
	_build_detail_pull_tip_overlay(actions_clip)
	var stack = VBoxContainer.new()
	stack.custom_minimum_size.x = actions_width
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 56)
	actions_scroll.add_child(stack)
	var scroll_top_spacer = Control.new()
	scroll_top_spacer.name = "DetailActionsTopSpacer"
	scroll_top_spacer.custom_minimum_size = Vector2(0, onboarding_first_module_top_spacer_height(selected_skill_id))
	stack.add_child(scroll_top_spacer)
	detail_actions_top_spacer = scroll_top_spacer

	detail_lazy_stack = stack
	if host._fishing_rework_active_for_skill(selected_skill_id):
		host._fishing_ui_surface().render_area_modules_into_stack(stack, content_width)
		if boot_detail_card_yield:
			await host.get_tree().process_frame
		if _activity_start_inline_tip_available(selected_skill_id):
			var start_note = host._tutorial_overlay_surface()._bottom_tutorial_tip_note(content_width, "Click an activity to start doing it.", "activity_start_tip_notes")
			_detail_eager_add_activity_start_tip_below_content(stack, start_note, content_width, actions_width)
			_fade_in_activity_start_tip_note(start_note)
		elif host._onboarding_runtime()._skill_swipe_tip_available():
			host._tutorial_overlay_surface().call_deferred("_run_onboarding_swipe_tip_sequence")
	else:
		if boot_detail_card_yield:
			var boot_lazy_slots_created = await _render_detail_lazy_card_list_batched(
				stack,
				content_width,
				actions_width,
				DETAIL_LAZY_BOOT_SLOT_BATCH_SIZE
			)
			if not boot_lazy_slots_created:
				return
		elif async_action_cards:
			await _render_detail_eager_card_list_async(stack, content_width, actions_width)
		else:
			if skill_swipe_defer_initial_lazy_mount:
				var lazy_slots_created = await _render_detail_lazy_card_list_batched(
					stack,
					content_width,
					actions_width,
					SKILL_SWIPE_FINALIZE_SLOT_BATCH_SIZE
				)
				if not lazy_slots_created:
					return
			else:
				_render_detail_lazy_card_list(stack, content_width, actions_width)
			_append_detail_eager_trailing_tips(stack, content_width, actions_width)
	if boot_detail_card_yield:
		boot_detail_render_in_progress = false
		if boot_detail_render_queue.is_empty():
			boot_detail_scroll_locked = false
			_append_detail_eager_trailing_tips(stack, content_width, actions_width)
		else:
			boot_detail_scroll_locked = true
			actions_scroll.set_max_scroll_override(0)
			actions_scroll.set_scroll_enabled_by_content(false)
			call_deferred("_complete_boot_detail_cards_async")
	if not (boot_detail_card_yield and not boot_detail_render_queue.is_empty()):
		host._navigation_shell()._render_page_switch_module(stack, selected_skill_id, content_width, actions_width)
	var scroll_bottom_spacer = Control.new()
	scroll_bottom_spacer.name = "DetailActionsBottomSpacer"
	var bottom_pad = _detail_actions_bottom_scroll_pad(selected_skill_id)
	scroll_bottom_spacer.custom_minimum_size = Vector2(0, bottom_pad)
	scroll_bottom_spacer.visible = bottom_pad > 1.0
	stack.add_child(scroll_bottom_spacer)
	detail_unlock_scroll_spacer = scroll_bottom_spacer
	if boot_detail_card_yield:
		host.call_deferred("_finish_boot_skill_detail_extras")
	else:
		_build_detail_jump_arrows(actions_clip)
		_add_skill_detail_shadow_overlay(_skill_detail_shadow_top_y())
	if not strip_mode:
		call_deferred("_sync_detail_actions_scroll_limit_deferred")
		if restore_detail_scroll == DETAIL_RESTORE_SCROLL_BOTTOM:
			actions_scroll.drag_scroll_position = 10000000.0
			actions_scroll.scroll_vertical = 10000000
			call_deferred("_scroll_detail_actions_to_bottom_after_layout")
		elif host._suppress_detail_auto_scroll_for_first_module():
			call_deferred("sync_onboarding_first_module_top_spacer", true)
		elif restore_detail_scroll >= 0:
			var detail_restore_scroll = _detail_restore_scroll_value(restore_detail_scroll)
			actions_scroll.drag_scroll_position = float(detail_restore_scroll)
			actions_scroll.scroll_vertical = detail_restore_scroll
			call_deferred("_restore_detail_actions_scroll", detail_restore_scroll)
		elif scroll_latest_activity:
			call_deferred("_scroll_to_resume_activity", false)
		host._skill_swipe_activity_surface().call_deferred("_ensure_skill_swipe_frame_centered")
		host._skill_swipe_activity_surface()._normalize_skill_detail_page_layout()


func _detail_restore_scroll_value(restore_detail_scroll: int) -> int:
	if host.selected_skill_id == "thieving" and not detail_thieving_scroll_restore_allowed:
		return 0
	return maxi(0, restore_detail_scroll)


func _refresh_visible_skill_detail_action_list(restore_detail_scroll: int = -1, expected_skill_id: String = "", allow_thieving_scroll_restore := false, suppress_layout_transition := false):
	if host.current_screen != "skill":
		return
	var target_skill_id: String = expected_skill_id if not expected_skill_id.is_empty() else host.selected_skill_id
	if target_skill_id.is_empty() or host.selected_skill_id != target_skill_id:
		return
	if host._skill_swipe_activity_surface()._skill_swipe_navigation_blocks_detail_refresh():
		return
	if host._navigation_shell().screen_render_in_progress:
		host._navigation_shell()._store_pending_skill_detail_refresh_request(restore_detail_scroll, target_skill_id, allow_thieving_scroll_restore, suppress_layout_transition)
		return
	var layout_snapshot: Dictionary = {} if suppress_layout_transition else _capture_detail_module_layout_snapshot()
	var effective_restore_scroll: int = restore_detail_scroll
	if effective_restore_scroll < 0 and detail_actions_scroll != null and is_instance_valid(detail_actions_scroll):
		if not module_ui_pending_pin_scroll_anchor.is_empty():
			effective_restore_scroll = -1
		else:
			effective_restore_scroll = int(round(detail_actions_scroll.drag_scroll_position))
	host._navigation_shell().last_rendered_screen_key = ""
	if layout_snapshot.is_empty():
		host._skill_swipe_activity_surface()._begin_skill_detail_refresh_cover()
	var prev_thieving_restore := detail_thieving_scroll_restore_allowed
	detail_thieving_scroll_restore_allowed = prev_thieving_restore or allow_thieving_scroll_restore
	await host._navigation_shell()._render_screen(false, effective_restore_scroll, false)
	detail_thieving_scroll_restore_allowed = prev_thieving_restore
	if host.current_screen != "skill" or host.selected_skill_id != target_skill_id:
		return
	host._update_ui(0.0, true)
	if not module_ui_pending_pin_scroll_anchor.is_empty():
		_sync_detail_lazy_visible_cards(true, -1)
		await _restore_module_ui_pin_scroll_anchor(target_skill_id)
		if host._skill_swipe_activity_surface().skill_detail_refresh_cover_active and not host._skill_swipe_activity_surface().skill_swipe_pending_full_finalize:
			host._skill_swipe_activity_surface()._clear_skill_swipe_handoff_cover_immediate()
	if not suppress_layout_transition and not layout_snapshot.is_empty():
		call_deferred("_play_detail_module_layout_transition", layout_snapshot)
	Callable(self, "_sync_detail_actions_scroll_limit_deferred").call_deferred()


func _skill_detail_needs_action_list_refresh() -> bool:
	if host._navigation_shell().screen_render_in_progress:
		return false
	if host.boot_detail_render_in_progress or host.boot_detail_scroll_locked or not host.boot_detail_render_queue.is_empty():
		return false
	if host.current_screen != "skill":
		return false
	if host._skill_swipe_activity_surface()._skill_swipe_navigation_blocks_detail_refresh():
		return false
	if _skill_detail_layout_refresh_held():
		return false
	if host._activity_unlock_runtime().has_pending_readiness_for_skill(host.selected_skill_id) or host._activity_unlock_ceremony_surface().ceremony_count > 0:
		return false
	if (
		not host._fishing_rework_active_for_skill(host.selected_skill_id)
		and detail_lazy_plan.size() > 0
		and not _detail_lazy_all_mounted()
	):
		return false
	var expected_action_ids: Array = []
	if host._fishing_rework_active_for_skill(host.selected_skill_id):
		expected_action_ids = host._fishing_ui_surface()._fishing_detail_render_signature()
	else:
		for entry in _visible_detail_entries_for_skill(host.selected_skill_id):
			var entry_data := entry as Dictionary
			if str(entry_data.get("kind", "")) == "thieving_heist":
				expected_action_ids.append("heist:%s" % str((entry_data.get("heist", {}) as Dictionary).get("id", "")))
			else:
				expected_action_ids.append(str((entry_data.get("action", {}) as Dictionary).get("id", "")))
	if expected_action_ids.size() != detail_rendered_action_ids.size():
		return true
	for i in range(expected_action_ids.size()):
		if str(expected_action_ids[i]) != str(detail_rendered_action_ids[i]):
			return true
	if host._fishing_rework_active_for_skill(host.selected_skill_id):
		for raw_key in host.action_cards.keys():
			if not str(raw_key).begins_with("fishing:"):
				continue
			var card := host.action_cards[raw_key] as Dictionary
			if card == null:
				continue
			if card.get("is_fishing_area") and not card.get("uses_static_background_only", false) and card.get("fluid_strip") == null:
				return true
	else:
		var stack := _detail_actions_stack()
		if stack == null or not is_instance_valid(stack) or not host._skill_swipe_activity_surface()._skill_detail_stack_has_visible_modules(stack):
			return true
		for raw_track_id in expected_action_ids:
			var track_id := str(raw_track_id)
			if track_id.is_empty():
				continue
			var node: Control = host._app_lifecycle_runtime().valid_control_ref(detail_action_card_nodes.get(track_id))
			if node == null or not node.is_inside_tree():
				if not track_id.begins_with("heist:") and _remount_detail_lazy_action_card(track_id, host.selected_skill_id):
					continue
				return true
			var card_key: String = host._thieving_surface()._thieving_heist_card_key(track_id.substr("heist:".length())) if track_id.begins_with("heist:") else host._action_key(host.selected_skill_id, track_id)
			if not host.action_cards.has(card_key):
				if not track_id.begins_with("heist:"):
					if _repair_detail_lazy_action_card_registration(track_id, host.selected_skill_id):
						continue
					if _remount_detail_lazy_action_card(track_id, host.selected_skill_id):
						continue
				return true
	return false


func _ensure_skill_detail_actions_clip_wrapper(page: Control, actions_scroll: MobileScrollContainer, actions_width: float) -> Control:
	if page == null or not is_instance_valid(page):
		return null
	if actions_scroll == null or not is_instance_valid(actions_scroll):
		return null
	var parent := actions_scroll.get_parent() as Control
	if parent == null or not is_instance_valid(parent):
		return null
	var clip := parent
	if parent == page and page is VBoxContainer:
		var insertion_index := actions_scroll.get_index()
		page.remove_child(actions_scroll)
		clip = Control.new()
		clip.name = "DetailActionsClip"
		page.add_child(clip)
		page.move_child(clip, insertion_index)
		clip.add_child(actions_scroll)
	clip.custom_minimum_size.x = actions_width
	clip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	clip.clip_contents = true
	actions_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	actions_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	actions_scroll.clip_contents = true
	return clip


func _build_detail_interactive_action_card(skill_id: String, action: Dictionary, content_width: float, _actions_width: float) -> Dictionary:
	var action_id = str(action.get("id", ""))
	var is_convergence_card = host._convergence_runtime()._is_convergence_action(action)
	var uses_blue_guy_chicken_brawl_stage = host._fighting_runtime().action_uses_blue_guy_chicken_brawl_stage(action)
	var shell = _detail_action_card_shell(skill_id, action, content_width, uses_blue_guy_chicken_brawl_stage)
	var card_root = shell.get("card_root") as Control
	var pop_card = shell.get("pop") as Control
	var depth = shell.get("depth") as ActivityCardDepth
	var bg = shell.get("bg") as Control
	var shade = shell.get("shade") as Panel
	var rooster_boss_stage = shell.get("rooster_boss_stage") as Control
	var blue_guy_chicken_stage = shell.get("blue_guy_chicken_stage") as Control
	var body = _detail_action_card_body(card_root, pop_card, skill_id, action, is_convergence_card, uses_blue_guy_chicken_brawl_stage)
	var art_panel = body.get("art_panel") as Panel
	var art = body.get("art") as Control
	var copy = body.get("copy") as VBoxContainer
	var action_name_label = body.get("title") as Label
	var title_build_button_panel = body.get("build_button_panel") as PanelContainer
	var title_build_cta_title = body.get("build_cta_title") as Label
	var stat_widgets = _detail_action_stat_widgets(copy, skill_id, action, action_id, is_convergence_card)
	var stat_row = stat_widgets.get("stat_row") as HBoxContainer
	var xp_label = stat_widgets.get("xp") as Label
	var stamina_label = stat_widgets.get("stamina") as Label
	var time_label = stat_widgets.get("time") as Label
	var success_label = stat_widgets.get("success") as Label
	var stat_boxes = stat_widgets.get("stat_boxes") as Dictionary
	var normal_stat_top = stat_widgets.get("normal_stat_top") as Label
	var normal_stat_bottom = stat_widgets.get("normal_stat_bottom") as Label
	var stat_hit_buttons = {}
	var recovery_label: Label = null
	var boss_label = _detail_action_boss_line(copy, action)

	var mastery_widgets = _detail_action_mastery_widgets(copy, art_panel, skill_id, action)
	var medal = mastery_widgets.get("medal") as TextureRect
	var mastery_progress = mastery_widgets.get("mastery") as CleanProgressBar
	var mastery_ring = mastery_widgets.get("mastery_ring") as Control
	if mastery_progress != null:
		mastery_progress.visible = false

	var bonus_panel = {}

	var status: Label = null

	var progress_widgets = _detail_action_progress_widgets(card_root, pop_card, skill_id, action, content_width, uses_blue_guy_chicken_brawl_stage)
	var progress = progress_widgets.get("progress") as ActivityProgressRail
	var convergence_progress = progress_widgets.get("convergence_progress") as ConvergenceMultiProgressBar
	var fluid_strip = progress_widgets.get("fluid_strip") as Control
	var mat_collection = progress_widgets.get("mat_collection") as Dictionary

	var convergence_widgets = _detail_action_convergence_overlay(pop_card, action)
	var convergence_overlay = convergence_widgets.get("convergence_overlay") as Control
	var convergence_overlay_label = convergence_widgets.get("convergence_overlay_label") as Label
	var convergence_build_cta = convergence_widgets.get("convergence_build_cta") as PanelContainer
	var convergence_build_cta_title = convergence_widgets.get("convergence_build_cta_title") as Label
	var convergence_build_cta_meta = convergence_widgets.get("convergence_build_cta_meta") as Label
	var buildable_widgets = _detail_action_buildable_overlay(pop_card, skill_id, action)
	var build_overlay = buildable_widgets.get("build_overlay") as Control
	var build_cta = buildable_widgets.get("build_cta") as PanelContainer
	var build_cta_title = title_build_cta_title if title_build_cta_title != null else buildable_widgets.get("build_cta_title") as Label
	var build_cta_meta = buildable_widgets.get("build_cta_meta") as Label
	var build_cost_heading = buildable_widgets.get("build_cost_heading") as Label
	var build_cost_rows = buildable_widgets.get("build_cost_rows", [])
	var build_module_title = action_name_label if build_overlay != null else buildable_widgets.get("build_module_title") as Label
	var build_progress_cover = buildable_widgets.get("build_progress_cover") as Control
	var build_button_panel = title_build_button_panel if title_build_button_panel != null else buildable_widgets.get("build_button_panel") as PanelContainer
	var build_plank_layer = buildable_widgets.get("build_plank_layer") as Control
	var build_plank_nodes = buildable_widgets.get("build_plank_nodes", [])

	var border: ActivityCardBorder = null
	if ACTION_CARD_FACE_BORDER_ENABLED and RecoveryModules.has_recovery(action) and not host._fighting_runtime().action_uses_diamond_combat_arena(action):
		border = ActivityCardBorder.new()
		border.set_anchors_preset(Control.PRESET_FULL_RECT)
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		border.z_index = ACTION_CARD_FACE_BORDER_Z_INDEX
		border.bottom_shape = "wide_u"
		border.wide_u_bottom_rise = RECOVERY_WIDE_U_BOTTOM_RISE
		border.wide_u_shoulder_ratio = RECOVERY_WIDE_U_SHOULDER_RATIO
		pop_card.add_child(border)
	var mission_badge = {}
	var lock_overlay = _activity_lock_overlay(pop_card, int(action.get("unlock", 1)), skill_id, _lock_requirements_for_overlay(skill_id, action)) if build_overlay == null and not host._activity_unlock_runtime()._is_action_unlocked(skill_id, action) else {}
	if not lock_overlay.is_empty():
		_connect_activity_lock_handler(lock_overlay, skill_id, action_id)

	var card = {
		"root": card_root,
		"entry": null,
		"skill_id": skill_id,
		"action_id": action_id,
		"action": action,
		"pop": pop_card,
		"button": null,
		"depth": depth,
		"bg": bg,
		"shade": shade,
		"art_panel": art_panel,
		"art": art,
		"title": action_name_label,
		"xp": xp_label,
		"stamina": stamina_label,
		"time": time_label,
		"success": success_label,
		"recovery_label": recovery_label,
		"boss_label": boss_label,
		"stat_row": stat_row,
		"normal_stat_top": normal_stat_top,
		"normal_stat_bottom": normal_stat_bottom,
		"stat_boxes": stat_boxes,
		"bonus_parent": copy,
		"stat_hit_buttons": stat_hit_buttons,
		"bonus_panel": bonus_panel,
		"status": status,
		"medal": medal,
		"mastery": mastery_progress,
		"mastery_ring": mastery_ring,
		"progress": progress,
		"mat_collection": mat_collection,
		"convergence_progress": convergence_progress,
		"convergence_overlay": convergence_overlay,
		"convergence_overlay_label": convergence_overlay_label,
		"convergence_build_cta": convergence_build_cta,
		"convergence_build_cta_title": convergence_build_cta_title,
		"convergence_build_cta_meta": convergence_build_cta_meta,
		"build_overlay": build_overlay,
		"build_progress_cover": build_progress_cover,
		"build_cta": build_cta,
		"build_button_panel": build_button_panel,
		"build_module_title": build_module_title,
		"build_cta_title": build_cta_title,
		"build_cta_meta": build_cta_meta,
		"build_cost_heading": build_cost_heading,
		"build_cost_rows": build_cost_rows,
		"build_plank_layer": build_plank_layer,
		"build_plank_nodes": build_plank_nodes,
		"fluid_strip": fluid_strip,
		"rooster_boss_stage": rooster_boss_stage,
		"blue_guy_chicken_stage": blue_guy_chicken_stage,
		"border": border,
		"mission_badge_parent": pop_card,
		"mission_badge": null,
		"mission_badge_label": null,
		"event_badge": null,
		"lock_overlay": lock_overlay,
		"medal_destination": Vector2(medal.offset_left, medal.offset_top) if medal != null else Vector2.ZERO
	}
	card["module_action_zones"] = _add_module_action_zones(pop_card, ModuleUiRuntime.action_for_record(skill_id, action, host.FISHING_ACTION_ID_ALIASES))
	return {
		"card_root": card_root,
		"card": card,
		"action_id": action_id
	}


func _build_beta_notice_board(content_width: float) -> Control:
	var root := Control.new()
	root.name = "BetaNoticeBoard"
	root.custom_minimum_size = Vector2(content_width, BETA_NOTICE_HEIGHT)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var board_width: float = content_width - float(host.ACTION_CARD_POP_GUTTER) * 2.0
	for x in [84.0, board_width - 124.0]:
		var support := Panel.new()
		support.position = Vector2(host.ACTION_CARD_POP_GUTTER + x, 12)
		support.size = Vector2(40, 686)
		support.mouse_filter = Control.MOUSE_FILTER_IGNORE
		support.add_theme_stylebox_override("panel", _beta_notice_wood_style(Color("#704420"), 8))
		root.add_child(support)

	for plank_index in range(4):
		var plank := Panel.new()
		plank.position = Vector2(host.ACTION_CARD_POP_GUTTER, 34 + plank_index * 162)
		plank.size = Vector2(board_width, 170)
		plank.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plank.add_theme_stylebox_override("panel", _beta_notice_wood_style(Color("#a96d35") if plank_index != 1 else Color("#b87a3d"), 18))
		root.add_child(plank)

	var title: Label = host._label("THIS GAME IS IN BETA", 120, Color("#24170d"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(host.ACTION_CARD_POP_GUTTER + 60, 52)
	title.size = Vector2(board_width - 120, 135)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(title)

	for line_data in [
		["There are no more activities to", 214.0],
		["unlock in this skill yet.", 376.0],
		["More coming soon.", 538.0],
	]:
		var line: Label = host._label(str(line_data[0]), 104, Color("#24170d"), HORIZONTAL_ALIGNMENT_CENTER)
		line.position = Vector2(host.ACTION_CARD_POP_GUTTER + 60, float(line_data[1]))
		line.size = Vector2(board_width - 120, 135)
		line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(line)
	return root


func _beta_notice_wood_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("#3b2614")
	style.set_border_width_all(8)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.12, 0.07, 0.03, 0.35)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 8)
	return style




func _module_action_zone(kind: String, module_key: String, left_side: bool) -> Control:
	var zone := ModuleActionCircleZone.new()
	zone.name = "Module%sActionZone" % kind.capitalize()
	var zone_size: Vector2 = MODULE_COLLAPSE_ACTION_ZONE_SIZE if kind == "collapse" else MODULE_ACTION_ZONE_SIZE
	var top_offset: float = MODULE_COLLAPSE_ACTION_ZONE_TOP_OFFSET if kind == "collapse" else MODULE_ACTION_ZONE_TOP_OFFSET
	var outer_offset: float = MODULE_COLLAPSE_ACTION_ZONE_OUTER_OFFSET if kind == "collapse" else MODULE_ACTION_ZONE_OUTER_OFFSET
	var offset_left: float = outer_offset if left_side else -zone_size.x - outer_offset
	if module_key.begins_with("fishing_area:"):
		zone_size = Vector2(96.0, 96.0)
		top_offset = -22.0
		offset_left = -18.0 if left_side else 18.0 - zone_size.x
	zone.anchor_left = 0.0 if left_side else 1.0
	zone.anchor_right = 0.0 if left_side else 1.0
	zone.anchor_top = 0.0
	zone.anchor_bottom = 0.0
	zone.offset_left = offset_left
	zone.offset_right = zone.offset_left + zone_size.x
	zone.offset_top = top_offset
	zone.offset_bottom = top_offset + zone_size.y
	zone.mouse_filter = Control.MOUSE_FILTER_STOP if kind == "collapse" else Control.MOUSE_FILTER_PASS
	zone.z_index = MODULE_ACTION_ZONE_Z_INDEX
	zone.set_meta("module_ui_key", module_key)
	zone.set_meta("module_action_kind", kind)
	zone.set_meta("module_action_circle_zone", true)
	return zone


func _add_module_action_zones(card_host: Control, module_key: String) -> Dictionary:
	var normalized_key: String = ModuleUiRuntime.normalize(module_key)
	if card_host == null or not is_instance_valid(card_host) or normalized_key.is_empty() or not _module_ui_key_allows_pin_or_collapse(normalized_key):
		return {}
	card_host.set_meta("module_ui_key", normalized_key)
	var existing := _module_action_zones_for_card(card_host)
	if not existing.is_empty():
		return existing
	var pin_zone := _module_action_zone("pin", normalized_key, true)
	var collapse_zone := _module_action_zone("collapse", normalized_key, false)
	pin_zone.gui_input.connect(Callable(self, "_on_module_pin_zone_gui_input").bind(normalized_key, card_host.get_instance_id()))
	collapse_zone.gui_input.connect(Callable(self, "_on_module_collapse_zone_gui_input").bind(normalized_key, card_host.get_instance_id()))
	card_host.add_child(pin_zone)
	card_host.add_child(collapse_zone)
	_sync_module_pin_badge(card_host, normalized_key)
	return {
		"pin": pin_zone,
		"collapse": collapse_zone
	}


func _sync_module_action_zones_for_card(card: Dictionary, module_key: String) -> void:
	if card.is_empty():
		return
	var normalized_key: String = ModuleUiRuntime.normalize(module_key)
	var raw_host = card.get("pop", null)
	var card_host: Control = host._app_lifecycle_runtime().valid_control_ref(raw_host)
	if card_host == null or normalized_key.is_empty():
		return
	if not _module_ui_key_allows_pin_or_collapse(normalized_key):
		_remove_module_action_zones_for_card(card_host)
		card.erase("module_action_zones")
		_hide_module_action_badges_for_locked_card(card_host, normalized_key)
		return
	var zones := card.get("module_action_zones", {}) as Dictionary
	if zones.is_empty():
		zones = _add_module_action_zones(card_host, normalized_key)
		card["module_action_zones"] = zones


func _module_action_zones_for_card(card_host: Control) -> Dictionary:
	var zones := {}
	var pin_zone := _module_action_zone_for_card(card_host, "pin")
	if pin_zone != null:
		zones["pin"] = pin_zone
	var collapse_zone := _module_action_zone_for_card(card_host, "collapse")
	if collapse_zone != null:
		zones["collapse"] = collapse_zone
	return zones


func _remove_module_action_zones_for_card(card_host: Control) -> void:
	if card_host == null or not is_instance_valid(card_host):
		return
	for child in card_host.get_children():
		var control := child as Control
		if control == null:
			continue
		if bool(control.get_meta("module_action_circle_zone", false)):
			control.queue_free()


func _hide_module_action_badges_for_locked_card(card_host: Control, module_key: String) -> void:
	var badge: TextureButton = _module_pin_badge(card_host)
	if badge != null:
		badge.visible = false
		badge.disabled = true
		host._app_lifecycle_runtime().set_canvas_item_alpha_if_changed(badge, 0.0)
	var collapse_badge: Button = _module_collapse_badge(card_host)
	if collapse_badge != null:
		collapse_badge.visible = false
		collapse_badge.disabled = true
		host._app_lifecycle_runtime().set_canvas_item_alpha_if_changed(collapse_badge, 0.0)


func _module_action_zone_event_inside_circle(card_host: Control, kind: String, event: InputEvent) -> bool:
	if card_host == null or not is_instance_valid(card_host):
		return false
	var zone := _module_action_zone_for_card(card_host, kind)
	if zone == null:
		return false
	var event_position := _module_action_zone_event_global_position(zone, event)
	if event_position == Vector2.INF:
		return false
	var rect := zone.get_global_rect()
	var center := rect.get_center()
	var radius := minf(rect.size.x, rect.size.y) * 0.5
	for candidate in host._input_routing_shell()._activity_input_position_candidates(event_position):
		if center.distance_to(candidate) <= radius:
			return true
	return false


func _module_action_zone_event_global_position(zone: Control, event: InputEvent) -> Vector2:
	if zone == null or not is_instance_valid(zone):
		return Vector2.INF
	if event is InputEventMouseButton:
		return zone.get_global_transform() * (event as InputEventMouseButton).position
	if event is InputEventScreenTouch:
		return zone.get_global_transform() * (event as InputEventScreenTouch).position
	return Vector2.INF


func _module_action_zone_for_card(card_host: Control, kind: String) -> Control:
	for child in card_host.get_children():
		var control := child as Control
		if control == null:
			continue
		if str(control.get_meta("module_action_kind", "")) == kind and bool(control.get_meta("module_action_circle_zone", false)):
			return control
	return null


func _module_action_zone_kind_at_position(card_host: Control, event_position: Vector2) -> String:
	if card_host == null or not is_instance_valid(card_host):
		return ""
	for child in card_host.get_children():
		var zone := child as Control
		if zone == null or not bool(zone.get_meta("module_action_circle_zone", false)):
			continue
		if not zone.visible or zone.is_queued_for_deletion():
			continue
		var kind := str(zone.get_meta("module_action_kind", ""))
		var rect := zone.get_global_rect()
		var center := rect.get_center()
		var radius := minf(rect.size.x, rect.size.y) * 0.5
		for candidate in host._input_routing_shell()._activity_input_position_candidates(event_position):
			if center.distance_to(candidate) <= radius:
				return kind
	return ""


func _module_action_badge_kind_at_position(card_host: Control, event_position: Vector2) -> String:
	var pin_badge: TextureButton = _module_pin_badge(card_host)
	if _module_pin_badge_contains_point(pin_badge, event_position):
		return "pin"
	var collapse_badge := _module_collapse_badge(card_host)
	if _visible_control_contains_point(collapse_badge, event_position):
		return "collapse"
	return ""


func _sync_visible_module_pin_badges() -> void:
	for raw_badge in host.get_tree().get_nodes_in_group("module_pin_badges"):
		var badge := raw_badge as TextureButton
		if badge == null or not is_instance_valid(badge) or badge.is_queued_for_deletion():
			continue
		var module_key := ModuleUiRuntime.normalize(badge.get_meta("module_pin_module_key", ""))
		if module_key.is_empty():
			continue
		host.module_ui_runtime.apply_pin_badge_texture(badge, module_key, ModuleUiRuntime.MODULE_PIN_COLOR_TEXTURES, ModuleUiRuntime.MODULE_PIN_ICON_TEXTURE, Callable(host.visual_texture_cache, "_texture_or_visual_fallback"))
		if host.module_ui_runtime.is_pinned(module_key, Callable(self, "_module_ui_key_allows_pin_or_collapse")):
			_place_module_pin_badge_settled(badge)
		else:
			_set_module_pin_badge_clip_enabled(badge, true)
			badge.visible = false
			badge.disabled = true
			badge.position = ModuleUiRuntime.MODULE_PIN_BADGE_SETTLED_POSITION
			badge.rotation_degrees = 0.0
			badge.scale = Vector2.ONE
			host._app_lifecycle_runtime().set_canvas_item_alpha_if_changed(badge, 0.0)


func _module_pin_badge(card_host: Control) -> TextureButton:
	if card_host == null or not is_instance_valid(card_host) or not card_host.has_meta("module_pin_badge_id"):
		return null
	return host._app_lifecycle_runtime().valid_texture_button_ref(instance_from_id(int(card_host.get_meta("module_pin_badge_id", 0))))


func _visible_module_pin_badge_for_key(module_key: String) -> TextureButton:
	var badges := _visible_module_pin_badges_for_key(module_key)
	return badges[0] as TextureButton if not badges.is_empty() else null


func _visible_module_pin_badges_for_key(module_key: String) -> Array:
	var badges := []
	var normalized_key: String = ModuleUiRuntime.normalize(module_key)
	if normalized_key.is_empty():
		return badges
	for raw_badge in host.get_tree().get_nodes_in_group("module_pin_badges"):
		var badge := raw_badge as TextureButton
		if badge == null or not is_instance_valid(badge) or badge.is_queued_for_deletion():
			continue
		if str(badge.get_meta("module_pin_module_key", "")) != normalized_key:
			continue
		if badge.visible and badge.is_inside_tree() and badge.is_visible_in_tree():
			badges.append(badge)
	return badges


func _module_pin_key_has_exiting_badge(module_key: String) -> bool:
	var normalized_key: String = ModuleUiRuntime.normalize(module_key)
	if normalized_key.is_empty():
		return false
	for raw_badge in host.get_tree().get_nodes_in_group("module_pin_badges"):
		var badge := raw_badge as TextureButton
		if badge == null or not is_instance_valid(badge) or badge.is_queued_for_deletion():
			continue
		if str(badge.get_meta("module_pin_module_key", "")) == normalized_key and badge.has_meta("module_pin_tween"):
			return true
	return false


func _module_pin_badge_owner_host(badge: TextureButton) -> Control:
	if badge == null or not is_instance_valid(badge) or badge.is_queued_for_deletion():
		return null
	var clip_host := badge.get_parent() as Control
	if clip_host == null or not is_instance_valid(clip_host):
		return null
	return clip_host.get_parent() as Control


func _module_pin_badge_clip_host(badge: TextureButton) -> Control:
	if badge == null or not is_instance_valid(badge):
		return null
	var parent := badge.get_parent() as Control
	if parent == null or not is_instance_valid(parent) or parent.name != "ModulePinClipBox":
		return null
	return parent


func _set_module_pin_badge_clip_enabled(raw_badge: Object, enabled: bool) -> void:
	var badge := raw_badge as TextureButton
	if badge == null:
		return
	var clip_host := _module_pin_badge_clip_host(badge)
	if clip_host == null:
		return
	clip_host.position = ModuleUiRuntime.MODULE_PIN_BADGE_CLIP_ORIGIN
	clip_host.size = ModuleUiRuntime.MODULE_PIN_BADGE_CLIP_SIZE
	clip_host.custom_minimum_size = ModuleUiRuntime.MODULE_PIN_BADGE_CLIP_SIZE
	clip_host.clip_contents = enabled
	clip_host.clip_children = CanvasItem.CLIP_CHILDREN_ONLY if enabled else CanvasItem.CLIP_CHILDREN_DISABLED


func _set_module_pin_badge_clip_enabled_by_id(badge_id: int, enabled: bool) -> void:
	var badge: TextureButton = host._app_lifecycle_runtime().valid_texture_button_ref(instance_from_id(badge_id))
	_set_module_pin_badge_clip_enabled(badge, enabled)


func _ensure_module_pin_badge(card_host: Control, module_key: String) -> TextureButton:
	var existing := _module_pin_badge(card_host)
	if existing != null and is_instance_valid(existing) and not existing.is_queued_for_deletion():
		existing.set_meta("module_pin_module_key", ModuleUiRuntime.normalize(module_key))
		existing.material = null
		host.module_ui_runtime.apply_pin_badge_texture(existing, module_key, ModuleUiRuntime.MODULE_PIN_COLOR_TEXTURES, ModuleUiRuntime.MODULE_PIN_ICON_TEXTURE, Callable(host.visual_texture_cache, "_texture_or_visual_fallback"))
		if not existing.is_in_group("module_pin_badges"):
			existing.add_to_group("module_pin_badges")
		return existing
	var clip_host := Control.new()
	clip_host.name = "ModulePinClipBox"
	clip_host.anchor_left = 0.0
	clip_host.anchor_right = 0.0
	clip_host.anchor_top = 0.0
	clip_host.anchor_bottom = 0.0
	clip_host.position = ModuleUiRuntime.MODULE_PIN_BADGE_CLIP_ORIGIN
	clip_host.size = ModuleUiRuntime.MODULE_PIN_BADGE_CLIP_SIZE
	clip_host.custom_minimum_size = ModuleUiRuntime.MODULE_PIN_BADGE_CLIP_SIZE
	clip_host.clip_contents = true
	clip_host.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	clip_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_host.z_index = ModuleUiRuntime.MODULE_PIN_BADGE_Z_INDEX
	card_host.add_child(clip_host)
	var badge := TextureButton.new()
	badge.name = "ModulePinConfirmBadge"
	host.module_ui_runtime.apply_pin_badge_texture(badge, module_key, ModuleUiRuntime.MODULE_PIN_COLOR_TEXTURES, ModuleUiRuntime.MODULE_PIN_ICON_TEXTURE, Callable(host.visual_texture_cache, "_texture_or_visual_fallback"))
	badge.ignore_texture_size = true
	badge.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT
	badge.anchor_left = 0.0
	badge.anchor_right = 0.0
	badge.anchor_top = 0.0
	badge.anchor_bottom = 0.0
	badge.position = ModuleUiRuntime.MODULE_PIN_BADGE_SETTLED_POSITION
	badge.size = ModuleUiRuntime.MODULE_PIN_BADGE_SIZE
	badge.custom_minimum_size = ModuleUiRuntime.MODULE_PIN_BADGE_SIZE
	badge.pivot_offset = ModuleUiRuntime.MODULE_PIN_BADGE_SIZE * 0.5
	badge.focus_mode = Control.FOCUS_NONE
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.z_index = 0
	badge.visible = false
	badge.modulate.a = 0.0
	badge.material = null
	badge.set_meta("module_pin_module_key", ModuleUiRuntime.normalize(module_key))
	badge.add_to_group("module_pin_badges")
	badge.pressed.connect(_on_module_pin_badge_pressed.bind(module_key, card_host.get_instance_id()))
	clip_host.add_child(badge)
	card_host.set_meta("module_pin_badge_id", badge.get_instance_id())
	return badge


func _sync_module_pin_badge(card_host: Control, module_key: String) -> void:
	if card_host == null or not is_instance_valid(card_host):
		return
	var badge := _ensure_module_pin_badge(card_host, module_key)
	if badge == null:
		return
	var pinned: bool = host.module_ui_runtime.is_pinned(module_key, Callable(self, "_module_ui_key_allows_pin_or_collapse"))
	if pinned:
		_place_module_pin_badge_settled(badge)
	else:
		_set_module_pin_badge_clip_enabled(badge, true)
		badge.visible = false
		badge.disabled = true
		badge.position = ModuleUiRuntime.MODULE_PIN_BADGE_SETTLED_POSITION
		badge.rotation_degrees = 0.0
		badge.scale = Vector2.ONE
		host._app_lifecycle_runtime().set_canvas_item_alpha_if_changed(badge, 0.0)


func _place_module_pin_badge_settled(badge: TextureButton) -> void:
	if badge == null or not is_instance_valid(badge):
		return
	if badge.has_meta("module_pin_preview_tween"):
		host._app_lifecycle_runtime()._kill_meta_tween(badge, "module_pin_preview_tween")
	var clip_host := _module_pin_badge_clip_host(badge)
	if clip_host != null:
		clip_host.visible = true
	var module_key := str(badge.get_meta("module_pin_module_key", ""))
	var clipped: bool = module_key.is_empty() or not _module_ui_is_collapsed(module_key)
	_set_module_pin_badge_clip_enabled(badge, clipped)
	badge.position = ModuleUiRuntime.MODULE_PIN_BADGE_SETTLED_POSITION
	badge.rotation_degrees = 0.0
	badge.scale = Vector2.ONE
	badge.visible = true
	badge.disabled = false
	host._app_lifecycle_runtime().set_canvas_item_alpha_if_changed(badge, 1.0)


func _play_module_pin_confirm_animation(badge: TextureButton, card_host: Control, module_key: String) -> void:
	if badge == null or not is_instance_valid(badge) or badge.is_queued_for_deletion():
		return
	if badge.has_meta("module_pin_tween"):
		host._app_lifecycle_runtime()._kill_meta_tween(badge, "module_pin_tween")
	if badge.has_meta("module_pin_preview_tween"):
		host._app_lifecycle_runtime()._kill_meta_tween(badge, "module_pin_preview_tween")
	_set_module_pin_badge_clip_enabled(badge, false)
	badge.visible = true
	badge.disabled = true
	var appear_position := ModuleUiRuntime.MODULE_PIN_BADGE_SETTLED_POSITION + ModuleUiRuntime.MODULE_PIN_CONFIRM_APPEAR_OFFSET
	var anticipation_position := ModuleUiRuntime.MODULE_PIN_BADGE_SETTLED_POSITION + ModuleUiRuntime.MODULE_PIN_CONFIRM_ANTICIPATION_OFFSET
	badge.position = appear_position
	badge.rotation_degrees = 0.0
	badge.scale = Vector2.ONE
	host._app_lifecycle_runtime().set_canvas_item_alpha_if_changed(badge, 1.0)
	var tween: Tween = host.create_tween()
	badge.set_meta("module_pin_tween", tween)
	var badge_id := badge.get_instance_id()
	tween.tween_method(_keep_module_pin_badge_disabled.bind(badge_id), 0.0, 1.0, ModuleUiRuntime.MODULE_PIN_CONFIRM_STILL_SECONDS)
	tween.parallel().tween_property(badge, "position", appear_position, ModuleUiRuntime.MODULE_PIN_CONFIRM_STILL_SECONDS)
	tween.parallel().tween_property(badge, "rotation_degrees", 0.0, ModuleUiRuntime.MODULE_PIN_CONFIRM_STILL_SECONDS)
	tween.parallel().tween_property(badge, "scale", Vector2.ONE, ModuleUiRuntime.MODULE_PIN_CONFIRM_STILL_SECONDS)

	tween.tween_method(_keep_module_pin_badge_disabled.bind(badge_id), 0.0, 1.0, ModuleUiRuntime.MODULE_PIN_CONFIRM_ANTICIPATION_SECONDS)
	tween.parallel().tween_property(badge, "position", anticipation_position, ModuleUiRuntime.MODULE_PIN_CONFIRM_ANTICIPATION_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(badge, "rotation_degrees", 0.0, ModuleUiRuntime.MODULE_PIN_CONFIRM_ANTICIPATION_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(badge, "scale", Vector2.ONE, ModuleUiRuntime.MODULE_PIN_CONFIRM_ANTICIPATION_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.tween_method(_keep_module_pin_badge_disabled.bind(badge_id), 0.0, 1.0, ModuleUiRuntime.MODULE_PIN_CONFIRM_TURNAROUND_SECONDS)
	tween.parallel().tween_property(badge, "position", anticipation_position, ModuleUiRuntime.MODULE_PIN_CONFIRM_TURNAROUND_SECONDS)
	tween.parallel().tween_property(badge, "rotation_degrees", 0.0, ModuleUiRuntime.MODULE_PIN_CONFIRM_TURNAROUND_SECONDS)
	tween.parallel().tween_property(badge, "scale", Vector2.ONE, ModuleUiRuntime.MODULE_PIN_CONFIRM_TURNAROUND_SECONDS)

	tween.tween_callback(_set_module_pin_badge_clip_enabled_by_id.bind(badge.get_instance_id(), true))
	tween.tween_method(_keep_module_pin_badge_disabled.bind(badge_id), 0.0, 1.0, ModuleUiRuntime.MODULE_PIN_CONFIRM_POKE_SECONDS)
	tween.parallel().tween_property(badge, "position", ModuleUiRuntime.MODULE_PIN_BADGE_SETTLED_POSITION, ModuleUiRuntime.MODULE_PIN_CONFIRM_POKE_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(badge, "rotation_degrees", 0.0, ModuleUiRuntime.MODULE_PIN_CONFIRM_POKE_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(badge, "scale", Vector2.ONE, ModuleUiRuntime.MODULE_PIN_CONFIRM_POKE_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	tween.tween_callback(host._audio_director()._play_module_pin_entry_sfx)
	tween.tween_callback(_finish_module_pin_confirm_animation.bind(badge.get_instance_id()))


func _finish_module_pin_confirm_animation(badge_id: int) -> void:
	var badge: TextureButton = host._app_lifecycle_runtime().valid_texture_button_ref(instance_from_id(badge_id))
	if badge == null or badge.is_queued_for_deletion():
		return
	if badge.has_meta("module_pin_tween"):
		badge.remove_meta("module_pin_tween")
	var module_key := str(badge.get_meta("module_pin_module_key", ""))
	_place_module_pin_badge_settled(badge)


func _play_module_pin_unpin_animation(badge: TextureButton, card_host: Control, module_key: String) -> void:
	if badge == null or not is_instance_valid(badge) or badge.is_queued_for_deletion():
		return
	if badge.has_meta("module_pin_tween"):
		host._app_lifecycle_runtime()._kill_meta_tween(badge, "module_pin_tween")
	if badge.has_meta("module_pin_preview_tween"):
		host._app_lifecycle_runtime()._kill_meta_tween(badge, "module_pin_preview_tween")
	_set_module_pin_badge_clip_enabled(badge, true)
	badge.visible = true
	badge.disabled = true
	badge.position = ModuleUiRuntime.MODULE_PIN_BADGE_SETTLED_POSITION
	badge.rotation_degrees = 0.0
	badge.scale = Vector2.ONE
	host._app_lifecycle_runtime().set_canvas_item_alpha_if_changed(badge, 1.0)
	host._audio_director()._play_module_pin_exit_sfx()
	var tween: Tween = host.create_tween()
	badge.set_meta("module_pin_tween", tween)
	Callable(self, "_disable_module_pin_badge_during_unpin").call_deferred(badge.get_instance_id())
	var badge_id := badge.get_instance_id()
	tween.set_parallel(true)
	tween.tween_method(_keep_module_pin_badge_disabled.bind(badge_id), 0.0, 1.0, 0.075)
	tween.tween_property(badge, "position", ModuleUiRuntime.MODULE_PIN_BADGE_SETTLED_POSITION + ModuleUiRuntime.MODULE_PIN_EXIT_LIFT_OFFSET, 0.075).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(badge, "rotation_degrees", 0.0, 0.075).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain()
	tween.tween_callback(_set_module_pin_badge_clip_enabled_by_id.bind(badge.get_instance_id(), false))
	tween.set_parallel(true)
	tween.tween_method(_keep_module_pin_badge_disabled.bind(badge_id), 0.0, 1.0, 0.195)
	tween.tween_property(badge, "position", ModuleUiRuntime.MODULE_PIN_BADGE_PULL_OUT_POSITION, 0.195).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(badge, "rotation_degrees", 0.0, 0.195).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(badge, "scale", Vector2(0.96, 0.96), 0.195).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(badge, "modulate:a", 0.0, 0.15).set_delay(0.045).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.set_parallel(false)
	tween.tween_callback(_finish_module_pin_unpin_animation.bind(badge.get_instance_id(), card_host.get_instance_id(), module_key))


func _keep_module_pin_badge_disabled(_progress: float, badge_id: int) -> void:
	var badge: TextureButton = host._app_lifecycle_runtime().valid_texture_button_ref(instance_from_id(badge_id))
	if badge == null or badge.is_queued_for_deletion():
		return
	if badge.has_meta("module_pin_tween"):
		badge.disabled = true


func _disable_module_pin_badge_during_unpin(badge_id: int) -> void:
	await host.get_tree().process_frame
	var badge: TextureButton = host._app_lifecycle_runtime().valid_texture_button_ref(instance_from_id(badge_id))
	if badge == null or badge.is_queued_for_deletion():
		return
	if badge.has_meta("module_pin_tween"):
		badge.disabled = true
	await host.get_tree().process_frame
	badge = host._app_lifecycle_runtime().valid_texture_button_ref(instance_from_id(badge_id))
	if badge == null or badge.is_queued_for_deletion():
		return
	if badge.has_meta("module_pin_tween"):
		badge.disabled = true


func _finish_module_pin_unpin_animation(badge_id: int, card_host_id: int, module_key: String) -> void:
	var badge: TextureButton = host._app_lifecycle_runtime().valid_texture_button_ref(instance_from_id(badge_id))
	if badge != null and not badge.is_queued_for_deletion():
		if badge.has_meta("module_pin_tween"):
			badge.remove_meta("module_pin_tween")
		badge.visible = false
		badge.disabled = true
		badge.position = ModuleUiRuntime.MODULE_PIN_BADGE_SETTLED_POSITION
		badge.rotation_degrees = 0.0
		badge.scale = Vector2.ONE
		host._app_lifecycle_runtime().set_canvas_item_alpha_if_changed(badge, 0.0)
		_set_module_pin_badge_clip_enabled(badge, true)


func _commit_module_pin_tap(module_key: String, card_host_id: int) -> void:
	var normalized_key: String = ModuleUiRuntime.normalize(module_key)
	if normalized_key.is_empty() or not _module_ui_key_allows_pin_or_collapse(normalized_key):
		return
	var card_host: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(card_host_id))
	if card_host == null or card_host.is_queued_for_deletion():
		return
	if _module_pin_badge_is_exiting(card_host):
		return
	if host.module_ui_runtime.is_pinned(normalized_key, Callable(self, "_module_ui_key_allows_pin_or_collapse")):
		_unpin_module_ui_key(normalized_key, card_host_id)
	else:
		_pin_module_ui_key(normalized_key, card_host_id)


func _on_module_pin_badge_pressed(module_key: String, card_host_id: int) -> void:
	_pin_module_ui_key(module_key, card_host_id)


func _pin_module_ui_key(module_key: String, card_host_id: int) -> void:
	var normalized_key: String = ModuleUiRuntime.normalize(module_key)
	if normalized_key.is_empty() or not _module_ui_key_allows_pin_or_collapse(normalized_key):
		return
	if _module_pin_key_has_exiting_badge(normalized_key):
		return
	if host.module_ui_runtime.is_pinned(normalized_key, Callable(self, "_module_ui_key_allows_pin_or_collapse")):
		_unpin_module_ui_key(normalized_key, card_host_id)
		return
	var card_host: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(card_host_id))
	host.module_ui_runtime.pin_module_key(normalized_key, host.selected_skill_id, ModuleUiRuntime.MODULE_PIN_COLOR_TEXTURES, ModuleUiRuntime.MODULE_PIN_ICON_TEXTURE)
	var played_confirm_animation := false
	if card_host != null and not card_host.is_queued_for_deletion():
		_sync_module_pin_badge(card_host, normalized_key)
		var badge := _module_pin_badge(card_host)
		if badge != null:
			_play_module_pin_confirm_animation(badge, card_host, normalized_key)
			played_confirm_animation = true
	host._mark_save_dirty("module pinned")
	host.save_game()
	_refresh_module_ui_after_pin_change(ModuleUiRuntime.MODULE_PIN_CONFIRM_ANIMATION_SECONDS if played_confirm_animation else 0.0)


func _unpin_module_ui_key(module_key: String, card_host_id: int) -> void:
	var normalized_key: String = ModuleUiRuntime.normalize(module_key)
	if normalized_key.is_empty():
		return
	if not _module_ui_key_allows_pin_or_collapse(normalized_key):
		host.module_ui_runtime.clear_pin_preview_token(normalized_key)
		return
	var card_host: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(card_host_id))
	host.module_ui_runtime.unpin_module_key(normalized_key, host.selected_skill_id)
	var played_unpin_animation := false
	if card_host != null and not card_host.is_queued_for_deletion():
		var badge := _module_pin_badge(card_host)
		var visible_badge := _visible_module_pin_badge_for_key(normalized_key)
		if visible_badge != null and (badge == null or not badge.visible or not badge.is_inside_tree() or not badge.is_visible_in_tree()):
			badge = visible_badge
			var badge_host := _module_pin_badge_owner_host(badge)
			if badge_host != null:
				card_host = badge_host
		if badge != null:
			_play_module_pin_unpin_animation(badge, card_host, normalized_key)
			played_unpin_animation = true
	for raw_badge in _visible_module_pin_badges_for_key(normalized_key):
		var visible_badge := raw_badge as TextureButton
		if visible_badge == null or not is_instance_valid(visible_badge) or visible_badge.has_meta("module_pin_tween"):
			continue
		var visible_badge_host := _module_pin_badge_owner_host(visible_badge)
		if visible_badge_host == null:
			visible_badge_host = card_host
		if visible_badge_host == null:
			continue
		_play_module_pin_unpin_animation(visible_badge, visible_badge_host, normalized_key)
		played_unpin_animation = true
	host._mark_save_dirty("module unpinned")
	host.save_game()
	_refresh_module_ui_after_pin_change(ModuleUiRuntime.MODULE_PIN_UNPIN_ANIMATION_SECONDS if played_unpin_animation else 0.0)



func _detail_lazy_module_ui_key(lazy_entry: Dictionary, skill_id: String) -> String:
	match str(lazy_entry.get("kind", "")):
		"heist":
			var heist := (lazy_entry.get("entry") as Dictionary).get("heist", {}) as Dictionary
			return ModuleUiRuntime.thieving_heist(str(heist.get("id", "")))
		"passive", "action":
			var action := (lazy_entry.get("entry") as Dictionary).get("action", {}) as Dictionary
			return ModuleUiRuntime.action_for_record(skill_id, action, host.FISHING_ACTION_ID_ALIASES)
		"fishing_area":
			return ModuleUiRuntime.fishing_area(host.fishing_runtime.area_module_key(skill_id, lazy_entry.get("area_def", {}) as Dictionary))
		"fishing_offer":
			return ModuleUiRuntime.fishing_offer(str(lazy_entry.get("offer_id", "")))
	return ""


func _module_root_full_height(root: Control) -> float:
	if root == null or not is_instance_valid(root):
		return ActivityCardStyles.root_height(false, host.ACTION_CARD_HEIGHT, host.ACTION_CARD_EXPANDED_HEIGHT, host.ACTION_CARD_3D_DEPTH_OFFSET.y)
	if root.has_meta("module_ui_full_height"):
		return maxf(1.0, float(root.get_meta("module_ui_full_height")))
	return maxf(1.0, maxf(root.custom_minimum_size.y, root.size.y))


func _set_module_root_layout_height(root: Control, height: float) -> void:
	if root == null or not is_instance_valid(root) or root.is_queued_for_deletion():
		return
	var clamped_height := maxf(1.0, height)
	root.custom_minimum_size = Vector2(root.custom_minimum_size.x, clamped_height)
	if root.size.y <= 1.0 or absf(root.size.y - clamped_height) > 0.5:
		root.size.y = clamped_height
	root.update_minimum_size()


func _find_named_control_descendant(root: Node, node_name: String) -> Control:
	if root == null or not is_instance_valid(root):
		return null
	if root.name == node_name and root is Control:
		return root as Control
	for child in root.get_children():
		var found := _find_named_control_descendant(child, node_name)
		if found != null:
			return found
	return null


func _find_module_card_face(root: Control, module_key: String) -> Control:
	if root == null or not is_instance_valid(root):
		return null
	var normalized_key: String = ModuleUiRuntime.normalize(module_key)
	for child in root.get_children():
		var child_control := child as Control
		if child_control == null:
			continue
		if ModuleUiRuntime.normalize(child_control.get_meta("module_ui_key", "")) == normalized_key:
			return child_control
		var found := _find_module_card_face(child_control, normalized_key)
		if found != null:
			return found
	return null


func _find_marked_module_title_label(root: Node) -> Label:
	if root == null or not is_instance_valid(root):
		return null
	var control := root as Control
	if control != null and control.has_meta("module_ui_title_label_id"):
		var title: Label = host._app_lifecycle_runtime().valid_label_ref(instance_from_id(int(control.get_meta("module_ui_title_label_id", 0))))
		if title != null:
			return title
	if root is Label and bool((root as Label).get_meta("module_ui_title_label", false)):
		return root as Label
	for child in root.get_children():
		var found := _find_marked_module_title_label(child)
		if found != null:
			return found
	return null


func _find_top_module_title_label(root: Node) -> Label:
	var best := {}
	_collect_top_module_title_label(root, best)
	return best.get("label", null) as Label


func _collect_top_module_title_label(root: Node, best: Dictionary) -> void:
	if root == null or not is_instance_valid(root):
		return
	if root is Label:
		var label := root as Label
		if not label.text.strip_edges().is_empty():
			var label_width := maxf(label.size.x, label.custom_minimum_size.x)
			if label_width > 160.0:
				var label_y := label.global_position.y if label.is_inside_tree() else label.position.y
				if label_y < float(best.get("y", INF)):
					best["label"] = label
					best["y"] = label_y
	for child in root.get_children():
		_collect_top_module_title_label(child, best)


func _module_title_label_for_lift(root: Control) -> Label:
	var title: Label = _find_marked_module_title_label(root)
	if title != null:
		return title
	return _find_top_module_title_label(root)


func _set_collapsed_module_title_lift(root: Control, collapsed: bool, instant := true) -> void:
	var title: Label = _module_title_label_for_lift(root)
	if title == null or not is_instance_valid(title):
		return
	if not title.has_meta("module_title_base_position"):
		title.set_meta("module_title_base_position", title.position)
	var base_position: Vector2 = host._app_lifecycle_runtime().meta_vector2(title, "module_title_base_position", title.position)
	var target_position: Vector2 = base_position + Vector2(0.0, MODULE_COLLAPSED_TITLE_LIFT_Y if collapsed else 0.0)
	host._app_lifecycle_runtime()._kill_meta_tween(title, "module_collapsed_title_tween")
	if instant:
		title.position = target_position
		return
	var tween: Tween = host.create_tween()
	title.set_meta("module_collapsed_title_tween", tween)
	tween.tween_property(title, "position", target_position, MODULE_COLLAPSE_SQUEEZE_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var title_id := title.get_instance_id()
	tween.finished.connect(_finish_collapsed_module_title_lift.bind(title_id, target_position))


func _finish_collapsed_module_title_lift(title_id: int, target_position: Vector2) -> void:
	var live_title: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(title_id))
	if live_title != null:
		live_title.position = target_position
		if live_title.has_meta("module_collapsed_title_tween"):
			live_title.remove_meta("module_collapsed_title_tween")


func _set_collapsed_module_visual_clipping(root: Control, module_key: String, collapsed: bool, title_instant := true) -> void:
	if root == null or not is_instance_valid(root):
		return
	_set_collapsed_module_title_lift(root, collapsed, title_instant)
	var card_face := _find_module_card_face(root, module_key)
	if card_face != null:
		if not card_face.has_meta("module_ui_original_face_clip_contents"):
			card_face.set_meta("module_ui_original_face_clip_contents", card_face.clip_contents)
		card_face.clip_contents = true if collapsed else bool(card_face.get_meta("module_ui_original_face_clip_contents", false))
	var clip_host := _find_named_control_descendant(root, "ModulePinClipBox")
	if clip_host == null:
		return
	if collapsed:
		if clip_host.get_parent() != root:
			var original_parent := clip_host.get_parent() as Control
			if original_parent != null and is_instance_valid(original_parent):
				clip_host.set_meta("module_pin_original_parent_id", original_parent.get_instance_id())
				clip_host.set_meta("module_pin_original_position", clip_host.position)
				var global_position := clip_host.global_position
				original_parent.remove_child(clip_host)
				root.add_child(clip_host)
				clip_host.global_position = global_position
		var badge := _module_pin_badge(root)
		if badge == null:
			for child in clip_host.get_children():
				if child is TextureButton:
					badge = child as TextureButton
					break
		if badge != null:
			_set_module_pin_badge_clip_enabled(badge, false)
		return
	var restored_badge: TextureButton = null
	for child in clip_host.get_children():
		if child is TextureButton:
			restored_badge = child as TextureButton
			break
	if clip_host.has_meta("module_pin_original_parent_id"):
		var parent: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(int(clip_host.get_meta("module_pin_original_parent_id"))))
		if parent != null and clip_host.get_parent() != parent:
			if clip_host.get_parent() != null:
				clip_host.get_parent().remove_child(clip_host)
			parent.add_child(clip_host)
			clip_host.position = host._app_lifecycle_runtime().meta_vector2(clip_host, "module_pin_original_position", clip_host.position)
		clip_host.remove_meta("module_pin_original_parent_id")
		if clip_host.has_meta("module_pin_original_position"):
			clip_host.remove_meta("module_pin_original_position")
	if restored_badge != null:
		_set_module_pin_badge_clip_enabled(restored_badge, true)


func _apply_collapsed_module_squeeze(root: Control, module_key: String, collapsed: bool) -> Control:
	var normalized_key: String = ModuleUiRuntime.normalize(module_key)
	if root == null or not is_instance_valid(root) or normalized_key.is_empty():
		return root
	if root.name == "CollapsedModuleSqueeze" and root.get_child_count() > 0:
		var inner_root := root.get_child(0) as Control
		if inner_root == null or not is_instance_valid(inner_root):
			return root
		root.remove_child(inner_root)
		root = inner_root
	if bool(root.get_meta("module_ui_collapsed_squeeze", false)):
		if collapsed:
			_set_module_root_layout_height(root, _module_collapsed_squeeze_height())
			root.clip_contents = false
			_set_collapsed_module_visual_clipping(root, normalized_key, true)
			return root
		root.set_meta("module_ui_collapsed_squeeze", false)
		root.remove_from_group("collapsed_module_rows")
		root.mouse_filter = int(root.get_meta("module_ui_original_mouse_filter", Control.MOUSE_FILTER_IGNORE))
		root.clip_contents = bool(root.get_meta("module_ui_original_clip_contents", false))
		_set_collapsed_module_visual_clipping(root, normalized_key, false)
		_set_module_root_layout_height(root, _module_root_full_height(root))
		return root
	if not root.has_meta("module_ui_full_height"):
		root.set_meta("module_ui_full_height", maxf(1.0, maxf(root.custom_minimum_size.y, root.size.y)))
	if not root.has_meta("module_ui_original_mouse_filter"):
		root.set_meta("module_ui_original_mouse_filter", int(root.mouse_filter))
	if not root.has_meta("module_ui_original_clip_contents"):
		root.set_meta("module_ui_original_clip_contents", root.clip_contents)
	root.set_meta("module_ui_key", normalized_key)
	if collapsed:
		_set_module_root_layout_height(root, _module_collapsed_squeeze_height())
		root.clip_contents = false
		root.mouse_filter = Control.MOUSE_FILTER_STOP
		root.set_meta("module_ui_collapsed_squeeze", true)
		_set_collapsed_module_visual_clipping(root, normalized_key, true)
		root.add_to_group("collapsed_module_rows")
		var row_input := _on_collapsed_module_row_gui_input.bind(normalized_key, root.get_instance_id())
		if not root.gui_input.is_connected(row_input):
			root.gui_input.connect(row_input)
		return root
	root.mouse_filter = int(root.get_meta("module_ui_original_mouse_filter", Control.MOUSE_FILTER_IGNORE))
	root.clip_contents = bool(root.get_meta("module_ui_original_clip_contents", false))
	root.set_meta("module_ui_collapsed_squeeze", false)
	root.remove_from_group("collapsed_module_rows")
	_set_collapsed_module_visual_clipping(root, normalized_key, false)
	_set_module_root_layout_height(root, _module_root_full_height(root))
	return root


func _apply_lazy_entry_module_squeeze(root: Control, lazy_entry: Dictionary, skill_id: String) -> Control:
	var module_key := _detail_lazy_module_ui_key(lazy_entry, skill_id)
	if module_key.is_empty():
		return root
	return _apply_collapsed_module_squeeze(root, module_key, _module_ui_is_collapsed(module_key))


func _play_collapsed_host_squeeze_if_needed(host: Control, child: Control, previous_height: float, target_height: float) -> void:
	if host == null or child == null or not is_instance_valid(host) or not is_instance_valid(child):
		return
	if not bool(child.get_meta("module_ui_collapsed_squeeze", false)):
		return
	var module_key := ModuleUiRuntime.normalize(child.get_meta("module_ui_key", ""))
	if module_key.is_empty() or module_key != module_ui_animating_collapse_key:
		return
	var start_height := maxf(previous_height, float(child.get_meta("module_ui_full_height", 0.0)))
	if start_height <= target_height + 8.0:
		if module_ui_animating_collapse_key == module_key:
			module_ui_animating_collapse_key = ""
		return
	_kill_module_list_transition_tween(host)
	var original_clip := host.clip_contents
	host.clip_contents = true
	_set_module_root_layout_height(host, start_height)
	child.size.y = start_height
	_set_collapsed_module_title_lift(child, false, true)
	_set_collapsed_module_title_lift(child, true, false)
	var tween: Tween = host.create_tween()
	host.set_meta("module_list_transition_tween", tween)
	var host_id := host.get_instance_id()
	var child_id := child.get_instance_id()
	tween.tween_method(_apply_collapsed_host_squeeze_height.bind(host_id, child_id), start_height, target_height, MODULE_COLLAPSE_SQUEEZE_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_finish_collapsed_host_squeeze_animation.bind(host_id, child_id, module_key, target_height, original_clip))


func _apply_collapsed_host_squeeze_height(value: float, host_id: int, child_id: int) -> void:
	var live_host: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(host_id))
	if live_host != null:
		_set_module_root_layout_height(live_host, value)
	var live_child: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(child_id))
	if live_child != null:
		live_child.size.y = value


func _finish_collapsed_host_squeeze_animation(host_id: int, child_id: int, module_key: String, target_height: float, original_clip: bool) -> void:
	var live_host: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(host_id))
	if live_host != null:
		_set_module_root_layout_height(live_host, target_height)
		live_host.clip_contents = original_clip
		if live_host.has_meta("module_list_transition_tween"):
			live_host.remove_meta("module_list_transition_tween")
	var live_child: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(child_id))
	if live_child != null:
		live_child.size.y = target_height
	if module_ui_animating_collapse_key == module_key:
		module_ui_animating_collapse_key = ""



func _route_direct_module_action_zone_input(event: InputEvent) -> bool:
	if (host.current_screen != "skill" and host.current_screen != "pinned" and host.current_screen != "queue" and host.current_screen != "menu") or host._input_routing_shell()._modal_blocks_background_input() or host._input_routing_shell()._any_modal_overlay_visible():
		return false
	if host.module_ui_runtime.update_pending_module_pin_press(event, host.PASSIVE_BUTTON_TAP_RELEASE_SLOP, host._skill_swipe_activity_surface().skill_swipe_tracking, Callable(self, "_commit_module_pin_tap")):
		return true
	if host.module_ui_runtime.pin_press_active() and host.module_ui_runtime.module_pin_press_event_belongs_to_active_press(event):
		host.module_ui_runtime.update_pending_module_pin_drag(event, host.PASSIVE_BUTTON_TAP_RELEASE_SLOP, host._skill_swipe_activity_surface().skill_swipe_tracking)
	if host.module_ui_runtime.update_pending_module_collapse_press(event, host.PASSIVE_BUTTON_TAP_RELEASE_SLOP, host._skill_swipe_activity_surface().skill_swipe_tracking, _detail_actions_scroll_suppresses_child_click(), Callable(self, "_commit_module_collapse_tap")):
		return true
	if host.module_ui_runtime.collapse_press_active() and host.module_ui_runtime.module_collapse_press_event_belongs_to_active_press(event):
		host.module_ui_runtime.update_pending_module_collapse_drag(event, host.PASSIVE_BUTTON_TAP_RELEASE_SLOP, host._skill_swipe_activity_surface().skill_swipe_tracking)
	if not host._input_routing_shell()._is_primary_press_event(event):
		return false
	var event_position := ModuleUiRuntime.press_event_position(event)
	if event_position == Vector2.INF or host._input_routing_shell()._position_inside_bottom_interactive_ui(event_position):
		return false
	var hit := _module_action_circle_at_direct_position(event_position)
	return _handle_module_action_zone_hit(hit, event, event_position)


func _route_module_action_zone_input(event: InputEvent) -> bool:
	if host.module_ui_runtime.update_pending_module_pin_press(event, host.PASSIVE_BUTTON_TAP_RELEASE_SLOP, host._skill_swipe_activity_surface().skill_swipe_tracking, Callable(self, "_commit_module_pin_tap")):
		return true
	if host.module_ui_runtime.pin_press_active() and host.module_ui_runtime.module_pin_press_event_belongs_to_active_press(event):
		host.module_ui_runtime.update_pending_module_pin_drag(event, host.PASSIVE_BUTTON_TAP_RELEASE_SLOP, host._skill_swipe_activity_surface().skill_swipe_tracking)
	if host.module_ui_runtime.update_pending_module_collapse_press(event, host.PASSIVE_BUTTON_TAP_RELEASE_SLOP, host._skill_swipe_activity_surface().skill_swipe_tracking, _detail_actions_scroll_suppresses_child_click(), Callable(self, "_commit_module_collapse_tap")):
		return true
	if host.module_ui_runtime.collapse_press_active() and host.module_ui_runtime.module_collapse_press_event_belongs_to_active_press(event):
		host.module_ui_runtime.update_pending_module_collapse_drag(event, host.PASSIVE_BUTTON_TAP_RELEASE_SLOP, host._skill_swipe_activity_surface().skill_swipe_tracking)
	if not host._input_routing_shell()._is_primary_press_event(event):
		return false
	var event_position := Vector2.ZERO
	if event is InputEventMouseButton:
		event_position = (event as InputEventMouseButton).global_position
	elif event is InputEventScreenTouch:
		event_position = (event as InputEventScreenTouch).position
	else:
		return false
	var hit := _module_action_circle_at_position(event_position)
	return _handle_module_action_zone_hit(hit, event, event_position)


func _handle_module_action_zone_hit(hit: Dictionary, event: InputEvent, event_position: Vector2) -> bool:
	if hit.is_empty():
		return false
	var card_host: Control = host._app_lifecycle_runtime().valid_control_ref(hit.get("host"))
	if card_host == null:
		return false
	var module_key := ModuleUiRuntime.normalize(hit.get("module_key", ""))
	if module_key.is_empty() or not _module_ui_key_allows_pin_or_collapse(module_key):
		return false
	var card_host_id: int = card_host.get_instance_id()
	match str(hit.get("kind", "")):
		"pin":
			if _module_pin_badge_is_exiting(card_host):
				return true
			host.module_ui_runtime.begin_module_pin_press(module_key, card_host_id, event_position, ModuleUiRuntime.press_touch_index_for_event(event), Callable(self, "_module_ui_key_allows_pin_or_collapse"))
			return true
		"collapse":
			if _module_ui_is_collapsed(module_key):
				_expand_module_ui_key(module_key)
				return true
			if host.module_ui_runtime.begin_module_collapse_press(module_key, card_host_id, event_position, ModuleUiRuntime.press_touch_index_for_event(event), Callable(self, "_module_ui_key_allows_pin_or_collapse")):
				if detail_actions_scroll != null and is_instance_valid(detail_actions_scroll):
					detail_actions_scroll.prepare_child_tap()
			return true
	return false


func _route_fishing_area_pin_corner_input(event: InputEvent) -> bool:
	if host.module_ui_runtime.update_pending_module_pin_press(event, host.PASSIVE_BUTTON_TAP_RELEASE_SLOP, host._skill_swipe_activity_surface().skill_swipe_tracking, Callable(self, "_commit_module_pin_tap")):
		return true
	if host.module_ui_runtime.pin_press_active() and host.module_ui_runtime.module_pin_press_event_belongs_to_active_press(event):
		host.module_ui_runtime.update_pending_module_pin_drag(event, host.PASSIVE_BUTTON_TAP_RELEASE_SLOP, host._skill_swipe_activity_surface().skill_swipe_tracking)
	if host.current_screen != "skill" and host.current_screen != "pinned" and host.current_screen != "queue":
		return false
	if host.current_screen == "skill" and host.selected_skill_id != "fishing":
		return false
	if not host._input_routing_shell()._is_primary_press_event(event):
		return false
	var event_position := Vector2.ZERO
	if event is InputEventMouseButton:
		event_position = (event as InputEventMouseButton).global_position
	elif event is InputEventScreenTouch:
		event_position = (event as InputEventScreenTouch).position
	else:
		return false
	if host._input_routing_shell()._position_inside_bottom_interactive_ui(event_position) or not host._input_routing_shell()._position_inside_detail_actions_viewport(event_position):
		return false
	var hit := _fishing_area_pin_corner_hit(event_position)
	if hit.is_empty():
		return false
	var card_host: Control = host._app_lifecycle_runtime().valid_control_ref(hit.get("host"))
	if card_host == null:
		return false
	var module_key := ModuleUiRuntime.normalize(hit.get("module_key", ""))
	if module_key.is_empty() or not _module_ui_key_allows_pin_or_collapse(module_key):
		return false
	if _module_pin_badge_is_exiting(card_host):
		return true
	host.module_ui_runtime.begin_module_pin_press(module_key, card_host.get_instance_id(), event_position, ModuleUiRuntime.press_touch_index_for_event(event), Callable(self, "_module_ui_key_allows_pin_or_collapse"))
	return true


func _fishing_area_pin_corner_hit(event_position: Vector2) -> Dictionary:
	if not host._input_routing_shell()._position_inside_detail_actions_viewport(event_position):
		return {}
	_prune_invalid_action_cards()
	var keys: Array = host.action_card_keys.duplicate()
	keys.reverse()
	for raw_key in keys:
		var key := str(raw_key)
		if not host.action_cards.has(key):
			continue
		var card := host.action_cards[key] as Dictionary
		if not bool(card.get("is_fishing_area", false)):
			continue
		var pop: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("pop", null))
		if pop == null or not pop.is_inside_tree() or not pop.is_visible_in_tree():
			continue
		var direct_kind := _module_action_zone_kind_at_direct_position(pop, event_position)
		if direct_kind.is_empty():
			direct_kind = _module_action_badge_kind_at_direct_position(pop, event_position)
		if direct_kind != "pin":
			continue
		return {
			"card": card,
			"host": pop,
			"module_key": str(pop.get_meta("module_ui_key", ""))
		}
	return {}


func _route_collapsed_module_expand_input(event: InputEvent) -> bool:
	if not host._input_routing_shell()._is_primary_press_event(event):
		return false
	if _detail_actions_scroll_suppresses_child_click():
		return false
	var press_position := Vector2.ZERO
	if event is InputEventMouseButton:
		press_position = (event as InputEventMouseButton).global_position
	elif event is InputEventScreenTouch:
		press_position = (event as InputEventScreenTouch).position
	else:
		return false
	if host._input_routing_shell()._position_inside_bottom_interactive_ui(press_position) or not host._input_routing_shell()._position_inside_detail_actions_viewport(press_position):
		return false
	var row: Control = _collapsed_module_row_at_position(press_position)
	if row == null:
		return false
	var module_key := ModuleUiRuntime.normalize(row.get_meta("module_ui_key", ""))
	if module_key.is_empty():
		return false
	var action_hit := _module_action_circle_at_position(press_position)
	if not action_hit.is_empty() and str(action_hit.get("kind", "")) == "pin":
		return false
	if detail_actions_scroll != null and is_instance_valid(detail_actions_scroll):
		detail_actions_scroll.prepare_child_tap()
	_expand_module_ui_key(module_key)
	return true


func _collapsed_module_row_at_position(event_position: Vector2) -> Control:
	for raw_row in host.get_tree().get_nodes_in_group("collapsed_module_rows"):
		var row := raw_row as Control
		if row == null or not is_instance_valid(row) or row.is_queued_for_deletion():
			continue
		if not row.visible:
			continue
		if row.get_global_rect().has_point(event_position):
			return row
	return null


func _collapsed_module_row_for_key(module_key: String) -> Control:
	var normalized_key: String = ModuleUiRuntime.normalize(module_key)
	if normalized_key.is_empty():
		return null
	for raw_row in host.get_tree().get_nodes_in_group("collapsed_module_rows"):
		var row := raw_row as Control
		if row == null or not is_instance_valid(row) or row.is_queued_for_deletion():
			continue
		if ModuleUiRuntime.normalize(row.get_meta("module_ui_key", "")) == normalized_key:
			return row
	return null


func _collapsed_module_layout_host(row: Control) -> Control:
	if row == null or not is_instance_valid(row):
		return null
	var current := row
	while current != null and is_instance_valid(current):
		var parent: Node = current.get_parent()
		if parent == detail_lazy_stack or parent is VBoxContainer:
			return current
		var parent_control := parent as Control
		if parent_control == null or not is_instance_valid(parent_control):
			break
		current = parent_control
	return row


func _on_module_collapse_zone_gui_input(event: InputEvent, module_key: String, card_host_id: int) -> void:
	if host.module_ui_runtime.update_pending_module_collapse_press(event, host.PASSIVE_BUTTON_TAP_RELEASE_SLOP, host._skill_swipe_activity_surface().skill_swipe_tracking, _detail_actions_scroll_suppresses_child_click(), Callable(self, "_commit_module_collapse_tap")):
		host.accept_event()
		return
	if host.module_ui_runtime.collapse_press_active() and host.module_ui_runtime.module_collapse_press_event_belongs_to_active_press(event):
		host.module_ui_runtime.update_pending_module_collapse_drag(event, host.PASSIVE_BUTTON_TAP_RELEASE_SLOP, host._skill_swipe_activity_surface().skill_swipe_tracking)
	if not host._input_routing_shell()._is_primary_press_event(event):
		return
	if host._fishing_ui_surface()._event_inside_fishing_location_image(event):
		return
	if not _module_ui_key_allows_pin_or_collapse(module_key):
		return
	if _module_ui_is_collapsed(module_key):
		_expand_module_ui_key(module_key)
		host.accept_event()
		return
	var card_host: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(card_host_id))
	if card_host == null or card_host.is_queued_for_deletion():
		return
	var zone := _module_action_zone_for_card(card_host, "collapse")
	if zone == null:
		return
	var event_position := _module_action_zone_event_global_position(zone, event)
	if event_position == Vector2.INF:
		return
	if host._input_routing_shell()._position_inside_bottom_interactive_ui(event_position):
		return
	if not _module_action_zone_event_inside_circle(card_host, "collapse", event):
		return
	var normalized_key: String = ModuleUiRuntime.normalize(module_key)
	if host.module_ui_runtime.begin_module_collapse_press(normalized_key, card_host_id, event_position, ModuleUiRuntime.press_touch_index_for_event(event), Callable(self, "_module_ui_key_allows_pin_or_collapse")):
		if detail_actions_scroll != null and is_instance_valid(detail_actions_scroll):
			detail_actions_scroll.prepare_child_tap()
	host.accept_event()


func _module_ui_is_collapsed(module_key: String) -> bool:
	return host.module_ui_runtime.is_collapsed(module_key, Callable(self, "_module_ui_key_allows_pin_or_collapse"))


func _commit_module_collapse_tap(module_key: String, card_host_id: int) -> void:
	var normalized_key: String = ModuleUiRuntime.normalize(module_key)
	if normalized_key.is_empty() or not _module_ui_key_allows_pin_or_collapse(normalized_key):
		return
	if _module_ui_is_collapsed(normalized_key):
		_expand_module_ui_key(normalized_key)
		return
	var card_host: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(card_host_id))
	if card_host == null or card_host.is_queued_for_deletion():
		return
	var badge := _module_collapse_badge(card_host)
	if badge != null and badge.visible and not badge.disabled:
		_collapse_module_ui_key(normalized_key, card_host_id)
	else:
		_show_module_collapse_confirm(card_host, normalized_key)


func _show_module_collapse_confirm(card_host: Control, module_key: String) -> void:
	var normalized_key: String = ModuleUiRuntime.normalize(module_key)
	if normalized_key.is_empty() or not _module_ui_key_allows_pin_or_collapse(normalized_key):
		return
	var badge := _ensure_module_collapse_badge(card_host, normalized_key)
	if badge == null:
		return
	badge.visible = true
	badge.disabled = false
	_position_module_collapse_badge(badge)
	badge.scale = Vector2.ONE
	host._app_lifecycle_runtime().set_canvas_item_alpha_if_changed(badge, 1.0)


func _collapse_module_ui_key(module_key: String, card_host_id: int) -> void:
	var normalized_key: String = host.module_ui_runtime.collapse_key(module_key, Callable(self, "_module_ui_key_allows_pin_or_collapse"))
	if normalized_key.is_empty():
		return
	module_ui_animating_collapse_key = normalized_key
	var card_host: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(card_host_id))
	if card_host != null and not card_host.is_queued_for_deletion():
		var badge := _module_collapse_badge(card_host)
		if badge != null:
			badge.disabled = true
			badge.visible = false
	host._mark_save_dirty("module collapsed")
	host.save_game()
	if card_host != null and _collapse_module_ui_key_in_place(normalized_key, card_host):
		return
	call_deferred("_refresh_visible_skill_detail_action_list", -1, host.selected_skill_id, true, true)


func _collapse_module_ui_key_in_place(module_key: String, card_host: Control) -> bool:
	var normalized_key: String = ModuleUiRuntime.normalize(module_key)
	if normalized_key.is_empty() or card_host == null or not is_instance_valid(card_host) or not card_host.is_inside_tree():
		return false
	var row := card_host.get_parent() as Control
	if row == null or not is_instance_valid(row) or not row.is_inside_tree():
		return false
	var start_height := maxf(1.0, maxf(row.custom_minimum_size.y, row.size.y))
	var target_height := _module_collapsed_squeeze_height()
	if start_height <= target_height + 8.0:
		_set_module_root_layout_height(row, target_height)
		_update_detail_lazy_module_height(normalized_key, target_height)
		_clear_module_ui_animating_collapse_key(normalized_key)
		return true
	if not row.has_meta("module_ui_full_height"):
		row.set_meta("module_ui_full_height", start_height)
	if not row.has_meta("module_ui_original_mouse_filter"):
		row.set_meta("module_ui_original_mouse_filter", int(row.mouse_filter))
	if not row.has_meta("module_ui_original_clip_contents"):
		row.set_meta("module_ui_original_clip_contents", row.clip_contents)
	row.set_meta("module_ui_key", normalized_key)
	row.set_meta("module_ui_collapsed_squeeze", true)
	row.add_to_group("collapsed_module_rows")
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.clip_contents = false
	var row_input := _on_collapsed_module_row_gui_input.bind(normalized_key, row.get_instance_id())
	if not row.gui_input.is_connected(row_input):
		row.gui_input.connect(row_input)
	var layout_host: Control = _collapsed_module_layout_host(row)
	_kill_module_list_transition_tween(row)
	if layout_host != null and layout_host != row:
		_kill_module_list_transition_tween(layout_host)
		_set_module_root_layout_height(layout_host, start_height)
	_set_collapsed_module_visual_clipping(row, normalized_key, true, false)
	var tween: Tween = host.create_tween()
	row.set_meta("module_list_transition_tween", tween)
	if layout_host != null and layout_host != row:
		layout_host.set_meta("module_list_transition_tween", tween)
	var layout_host_id := layout_host.get_instance_id() if layout_host != null else 0
	tween.tween_method(
		_set_collapsed_module_squeeze_height_for_tween.bind(row.get_instance_id(), layout_host_id),
		start_height,
		target_height,
		MODULE_COLLAPSE_SQUEEZE_SECONDS
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_finish_collapsed_module_collapse_animation.bind(row.get_instance_id(), layout_host_id, normalized_key, target_height))
	return true


func _set_collapsed_module_squeeze_height_for_tween(value: float, row_id: int, layout_host_id: int) -> void:
	var row: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(row_id))
	if row != null:
		_set_module_root_layout_height(row, value)
	var layout_host: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(layout_host_id))
	if layout_host != null:
		_set_module_root_layout_height(layout_host, value)


func _finish_collapsed_module_collapse_animation(row_id: int, layout_host_id: int, module_key: String, target_height: float) -> void:
	var row: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(row_id))
	var layout_host: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(layout_host_id))
	if layout_host != null:
		_set_module_root_layout_height(layout_host, target_height)
		if layout_host.has_meta("module_list_transition_tween"):
			layout_host.remove_meta("module_list_transition_tween")
	if row != null:
		_set_module_root_layout_height(row, target_height)
		row.size.y = target_height
		if row.has_meta("module_list_transition_tween"):
			row.remove_meta("module_list_transition_tween")
	_update_detail_lazy_module_height(module_key, target_height)
	_clear_module_ui_animating_collapse_key(module_key)


func _on_collapsed_module_row_gui_input(event: InputEvent, module_key: String, row_id: int) -> void:
	if not host._input_routing_shell()._is_primary_press_event(event):
		return
	if _detail_actions_scroll_suppresses_child_click():
		return
	var row: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(row_id))
	if row == null or row.is_queued_for_deletion():
		return
	if host._input_routing_shell()._event_points_inside_bottom_interactive_ui(event, row) or not host._input_routing_shell()._event_points_inside_detail_actions_viewport(event, row):
		return
	_expand_module_ui_key(module_key)
	host.accept_event()


func _module_ui_key_allows_pin_or_collapse(module_key: String) -> bool:
	return host.module_ui_runtime.key_allows_pin_or_collapse(
		module_key,
		Callable(self, "_module_ui_action_allows_pin_or_collapse"),
		Callable(self, "_module_ui_thieving_heist_allows_pin_or_collapse"),
		Callable(self, "_module_ui_fishing_area_is_unlocked")
	)


func _module_ui_action_allows_pin_or_collapse(skill_id: String, action_id: String) -> bool:
	var action: Dictionary = host._action_data(skill_id, action_id)
	return not action.is_empty() and host._activity_unlock_runtime()._is_action_unlocked(skill_id, action)


func _module_ui_thieving_heist_allows_pin_or_collapse(heist_id: String) -> bool:
	for raw_heist in host.thieving_state.visible_heists_for_render():
		var heist := raw_heist as Dictionary
		if str(heist.get("id", "")) == heist_id:
			return true
	return false


func _module_ui_fishing_area_is_unlocked(module_key: String) -> bool:
	for raw_area_def in host._fishing_ui_surface().render_area_modules("fishing"):
		var area_def := raw_area_def as Dictionary
		if ModuleUiRuntime.fishing_area(host.fishing_runtime.area_module_key("fishing", area_def)) != module_key:
			continue
		var area_id := str(area_def.get("id", ""))
		if host.fishing_runtime.area_uses_location_tiles(area_def, FishingState.FISHING_LOCATION_DEFS):
			for raw_location in host.fishing_runtime.locations_for_area(area_id, FishingState.FISHING_LOCATION_DEFS):
				if host.fishing_runtime.location_is_unlocked(host, area_id, raw_location as Dictionary, FishingState.FISHING_LOCATION_DEFS, FishingState.FISHING_TOOL_LOCATION_ACTIONS):
					return true
			return false
		for raw_method_id in area_def.get("methods", []):
			var action: Dictionary = host._action_data("fishing", str(raw_method_id))
			if not action.is_empty() and host._activity_unlock_runtime()._is_action_unlocked("fishing", action):
				return true
		return false
	return false


func _expand_module_ui_key(module_key: String) -> void:
	var normalized_key: String = ModuleUiRuntime.normalize(module_key)
	if normalized_key.is_empty():
		return
	var row: Control = _collapsed_module_row_for_key(normalized_key)
	if row != null and is_instance_valid(row):
		if bool(row.get_meta("module_ui_expanding_from_collapsed", false)):
			return
		_play_collapsed_module_expand_animation(row, normalized_key)
		return
	_finish_expand_module_ui_key(normalized_key)


func _play_collapsed_module_expand_animation(row: Control, module_key: String) -> void:
	var normalized_key: String = ModuleUiRuntime.normalize(module_key)
	if row == null or not is_instance_valid(row) or normalized_key.is_empty():
		_finish_expand_module_ui_key(normalized_key)
		return
	row.set_meta("module_ui_expanding_from_collapsed", true)
	_kill_module_list_transition_tween(row)
	var layout_host: Control = _collapsed_module_layout_host(row)
	if layout_host != null and layout_host != row:
		_kill_module_list_transition_tween(layout_host)
	var start_height := maxf(1.0, maxf(row.custom_minimum_size.y, row.size.y))
	var target_height := _module_root_full_height(row)
	if target_height <= start_height + 8.0:
		if row.has_meta("module_ui_expanding_from_collapsed"):
			row.remove_meta("module_ui_expanding_from_collapsed")
		_finish_expand_module_ui_key(normalized_key)
		return
	row.clip_contents = false
	if layout_host != null and is_instance_valid(layout_host):
		_set_module_root_layout_height(layout_host, start_height)
	_set_collapsed_module_visual_clipping(row, normalized_key, true, true)
	_set_collapsed_module_title_lift(row, false, false)
	var tween: Tween = host.create_tween()
	row.set_meta("module_list_transition_tween", tween)
	if layout_host != null and layout_host != row:
		layout_host.set_meta("module_list_transition_tween", tween)
	var layout_host_id := layout_host.get_instance_id() if layout_host != null else 0
	var row_id := row.get_instance_id()
	tween.tween_method(_apply_collapsed_module_expand_height.bind(row_id, layout_host_id), start_height, target_height, MODULE_COLLAPSE_SQUEEZE_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_finish_collapsed_module_expand_animation.bind(row_id, layout_host_id, normalized_key, target_height))


func _apply_collapsed_module_expand_height(value: float, row_id: int, layout_host_id: int) -> void:
	var row: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(row_id))
	if row != null:
		_set_module_root_layout_height(row, value)
	var layout_host: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(layout_host_id))
	if layout_host != null:
		_set_module_root_layout_height(layout_host, value)


func _finish_collapsed_module_expand_animation(row_id: int, layout_host_id: int, module_key: String, target_height: float) -> void:
	var row: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(row_id))
	var layout_host: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(layout_host_id))
	if layout_host != null:
		_set_module_root_layout_height(layout_host, target_height)
		if layout_host.has_meta("module_list_transition_tween"):
			layout_host.remove_meta("module_list_transition_tween")
	if row != null:
		_set_module_root_layout_height(row, target_height)
		_set_collapsed_module_visual_clipping(row, module_key, false, true)
		if row.has_meta("module_list_transition_tween"):
			row.remove_meta("module_list_transition_tween")
		if row.has_meta("module_ui_expanding_from_collapsed"):
			row.remove_meta("module_ui_expanding_from_collapsed")
		_finish_expanded_module_row_in_place(row, module_key, layout_host, target_height)
	_finish_expand_module_ui_key(module_key, row == null)


func _finish_expanded_module_row_in_place(row: Control, module_key: String, layout_host: Control, target_height: float) -> void:
	if row == null or not is_instance_valid(row):
		return
	row.set_meta("module_ui_collapsed_squeeze", false)
	row.remove_from_group("collapsed_module_rows")
	row.mouse_filter = int(row.get_meta("module_ui_original_mouse_filter", Control.MOUSE_FILTER_IGNORE))
	row.clip_contents = bool(row.get_meta("module_ui_original_clip_contents", false))
	_set_collapsed_module_visual_clipping(row, module_key, false, true)
	_set_module_root_layout_height(row, target_height)
	if layout_host != null and is_instance_valid(layout_host):
		_set_module_root_layout_height(layout_host, target_height)
	_update_detail_lazy_module_height(module_key, target_height)


func _update_detail_lazy_module_height(module_key: String, target_height: float) -> void:
	var normalized_key: String = ModuleUiRuntime.normalize(module_key)
	if normalized_key.is_empty() or detail_lazy_plan.is_empty():
		return
	var changed := false
	for index in range(detail_lazy_plan.size()):
		var lazy_entry := detail_lazy_plan[index] as Dictionary
		if ModuleUiRuntime.normalize(_detail_lazy_module_ui_key(lazy_entry, host.selected_skill_id)) != normalized_key:
			continue
		lazy_entry["height"] = target_height
		detail_lazy_plan[index] = lazy_entry
		changed = true
		break
	if not changed:
		return
	var y := 0.0
	for index in range(detail_lazy_plan.size()):
		var lazy_entry := detail_lazy_plan[index] as Dictionary
		lazy_entry["y"] = y
		y += float(lazy_entry.get("height", 0.0)) + DETAIL_LAZY_STACK_SEPARATION
		detail_lazy_plan[index] = lazy_entry


func _finish_expand_module_ui_key(module_key: String, refresh_list := true) -> void:
	var normalized_key: String = host.module_ui_runtime.expand_key(module_key)
	if normalized_key.is_empty():
		return
	host._mark_save_dirty("module expanded")
	host.save_game()
	if refresh_list:
		call_deferred("_refresh_visible_skill_detail_action_list", -1, host.selected_skill_id, true, true)


func _on_module_pin_zone_gui_input(event: InputEvent, module_key: String, card_host_id: int) -> void:
	if host.module_ui_runtime.update_pending_module_pin_press(event, host.PASSIVE_BUTTON_TAP_RELEASE_SLOP, host._skill_swipe_activity_surface().skill_swipe_tracking, Callable(self, "_commit_module_pin_tap")):
		host.accept_event()
		return
	if host.module_ui_runtime.pin_press_active() and host.module_ui_runtime.module_pin_press_event_belongs_to_active_press(event):
		host.module_ui_runtime.update_pending_module_pin_drag(event, host.PASSIVE_BUTTON_TAP_RELEASE_SLOP, host._skill_swipe_activity_surface().skill_swipe_tracking)
	if not host._input_routing_shell()._is_primary_press_event(event):
		return
	if not _module_ui_key_allows_pin_or_collapse(module_key):
		return
	var card_host: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(card_host_id))
	if card_host == null or card_host.is_queued_for_deletion():
		return
	var zone := _module_action_zone_for_card(card_host, "pin")
	if zone == null:
		return
	var event_position := _module_action_zone_event_global_position(zone, event)
	if event_position == Vector2.INF:
		return
	if host._input_routing_shell()._position_inside_bottom_interactive_ui(event_position):
		return
	if not _module_action_zone_event_inside_circle(card_host, "pin", event):
		return
	var normalized_key: String = ModuleUiRuntime.normalize(module_key)
	host.module_ui_runtime.begin_module_pin_press(normalized_key, card_host_id, event_position, ModuleUiRuntime.press_touch_index_for_event(event), Callable(self, "_module_ui_key_allows_pin_or_collapse"))
	host.accept_event()



func _restore_module_ui_pin_scroll_anchor(skill_id: String) -> void:
	if module_ui_pending_pin_scroll_anchor.is_empty():
		module_ui_pin_scroll_anchor_debug = "restore-empty"
		return
	var anchor: Dictionary = module_ui_pending_pin_scroll_anchor.duplicate(true)
	if host.current_screen != "skill" or host.selected_skill_id != skill_id:
		module_ui_pin_scroll_anchor_debug = "restore-wrong-screen:%s/%s skill=%s target=%s" % [host.current_screen, host.selected_skill_id, skill_id, str(anchor)]
		module_ui_pending_pin_scroll_anchor.clear()
		return
	if str(anchor.get("skill_id", "")) != skill_id:
		module_ui_pin_scroll_anchor_debug = "restore-wrong-skill:%s target=%s" % [str(anchor), skill_id]
		module_ui_pending_pin_scroll_anchor.clear()
		return
	if detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll):
		module_ui_pin_scroll_anchor_debug = "restore-missing-scroll"
		module_ui_pending_pin_scroll_anchor.clear()
		return
	await host.get_tree().process_frame
	await host.get_tree().process_frame
	_sync_detail_actions_scroll_limit()
	if detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll):
		module_ui_pending_pin_scroll_anchor.clear()
		return
	var module_key := ModuleUiRuntime.normalize(anchor.get("module_key", ""))
	if module_key.is_empty():
		module_ui_pin_scroll_anchor_debug = "restore-empty-key:%s" % str(anchor)
		module_ui_pending_pin_scroll_anchor.clear()
		return
	var anchor_control := _find_normal_module_ui_control_for_scroll_anchor(detail_actions_scroll, module_key)
	if anchor_control == null:
		module_ui_pin_scroll_anchor_debug = "restore-missing-anchor:%s" % str(anchor)
		module_ui_pending_pin_scroll_anchor.clear()
		return
	var old_y := float(anchor.get("screen_y", anchor_control.get_global_rect().position.y))
	var new_y := anchor_control.get_global_rect().position.y
	var delta_y := new_y - old_y
	if absf(delta_y) < 1.0:
		module_ui_pin_scroll_anchor_debug = "restore-waiting-delta old=%s new=%s anchor=%s" % [old_y, new_y, str(anchor)]
		module_ui_pending_pin_scroll_anchor.clear()
		return
	var base_scroll := int(round(detail_actions_scroll.scroll_vertical))
	var target_scroll := clampi(int(round(float(base_scroll) + delta_y)), 0, int(detail_actions_scroll.get_max_scroll_vertical()))
	detail_actions_scroll.scroll_vertical = target_scroll
	detail_actions_scroll.set("drag_scroll_position", float(target_scroll))
	module_ui_pending_pin_scroll_anchor.clear()
	module_ui_pin_scroll_anchor_debug = "restore-applied delta=%s target=%s old=%s new=%s" % [delta_y, target_scroll, old_y, new_y]


func _find_normal_module_ui_control_for_scroll_anchor(root_node: Node, module_key: String, inside_duplicate := false) -> Control:
	if root_node == null or not is_instance_valid(root_node):
		return null
	var control := root_node as Control
	var next_inside_duplicate := inside_duplicate
	if control != null:
		next_inside_duplicate = (
			inside_duplicate
			or bool(control.get_meta("module_ui_pinned_shelf_copy", false))
			or bool(control.get_meta("module_ui_pinned_page_copy", false))
		)
	for child in root_node.get_children():
		var found := _find_normal_module_ui_control_for_scroll_anchor(child, module_key, next_inside_duplicate)
		if found != null:
			return found
	if control != null and not next_inside_duplicate and ModuleUiRuntime.normalize(control.get_meta("module_ui_key", "")) == module_key:
		return control
	return null


func _refresh_module_ui_after_pin_change(delay_seconds := 0.0) -> void:
	module_ui_refresh_token += 1
	var refresh_token: int = module_ui_refresh_token
	if host.current_screen == "skill" or host.current_screen == "pinned":
		if delay_seconds > 0.0:
			call_deferred("_refresh_module_ui_after_pin_change_after_delay", refresh_token, host.current_screen, host.selected_skill_id, delay_seconds)
		else:
			call_deferred("_refresh_module_ui_after_pin_change_deferred", refresh_token, host.current_screen, host.selected_skill_id)


func _refresh_module_ui_after_pin_change_after_delay(refresh_token: int, target_screen: String, target_skill_id: String, delay_seconds: float) -> void:
	await host.get_tree().create_timer(maxf(0.01, delay_seconds)).timeout
	_refresh_module_ui_after_pin_change_deferred(refresh_token, target_screen, target_skill_id)


func _refresh_module_ui_after_pin_change_deferred(refresh_token: int, target_screen: String, target_skill_id: String) -> void:
	if refresh_token != module_ui_refresh_token:
		return
	if host.current_screen != target_screen:
		return
	if target_screen == "skill":
		if host.selected_skill_id != target_skill_id:
			return
		_sync_visible_module_pin_badges()
	elif target_screen == "pinned":
		host._navigation_shell()._refresh_pinned_activities_shelf_after_pin_change()
		_sync_visible_module_pin_badges()
		host._navigation_shell()._sync_pinned_active_shelf(0.0, true)


func _module_pin_badge_contains_point(badge: TextureButton, event_position: Vector2) -> bool:
	if badge == null or not is_instance_valid(badge) or not badge.visible or badge.disabled or badge.is_queued_for_deletion():
		return false
	if not badge.is_inside_tree() or not badge.is_visible_in_tree():
		return false
	var clip_host: Control = _module_pin_badge_clip_host(badge)
	if clip_host != null and clip_host.clip_contents and not _visible_control_contains_point(clip_host, event_position):
		return false
	for candidate in host._input_routing_shell()._activity_input_position_candidates(event_position):
		var local_point: Vector2 = badge.get_global_transform().affine_inverse() * candidate
		if local_point.x < ModuleUiRuntime.MODULE_PIN_BADGE_HIT_MIN.x or local_point.y < ModuleUiRuntime.MODULE_PIN_BADGE_HIT_MIN.y:
			continue
		if local_point.x > ModuleUiRuntime.MODULE_PIN_BADGE_HIT_MAX.x or local_point.y > ModuleUiRuntime.MODULE_PIN_BADGE_HIT_MAX.y:
			continue
		return true
	return false


func _module_pin_badge_is_exiting(card_host: Control) -> bool:
	var badge: TextureButton = _module_pin_badge(card_host)
	return badge != null and is_instance_valid(badge) and badge.has_meta("module_pin_tween")


func _visible_control_contains_point(control: Control, event_position: Vector2) -> bool:
	if control == null or not is_instance_valid(control) or not control.visible or control.is_queued_for_deletion():
		return false
	if not control.is_inside_tree() or not control.is_visible_in_tree():
		return false
	var rect := control.get_global_rect()
	for candidate in host._input_routing_shell()._activity_input_position_candidates(event_position):
		if rect.has_point(candidate):
			return true
	return false


func _module_action_circle_at_position(event_position: Vector2) -> Dictionary:
	if event_position == Vector2.INF:
		return {}
	if host._input_routing_shell()._position_inside_bottom_interactive_ui(event_position):
		return {}
	var direct_hit := _module_action_circle_at_direct_position(event_position)
	if not direct_hit.is_empty():
		return direct_hit
	_prune_invalid_action_cards()
	for raw_card in action_cards.values():
		var card := raw_card as Dictionary
		var raw_host = card.get("pop", null)
		var card_host: Control = host._app_lifecycle_runtime().valid_control_ref(raw_host)
		if card_host == null:
			continue
		if not card_host.is_inside_tree() or not card_host.is_visible_in_tree():
			continue
		var kind := _module_action_zone_kind_at_position(card_host, event_position)
		if kind.is_empty():
			var badge_kind := _module_action_badge_kind_at_position(card_host, event_position)
			if badge_kind == "pin" or badge_kind == "collapse":
				kind = badge_kind
		if kind.is_empty():
			continue
		return {
			"card": card,
			"kind": kind,
			"host": card_host,
			"module_key": str(card_host.get_meta("module_ui_key", ""))
		}
	for raw_root in [content_scroll, detail_lazy_stack]:
		var root: Control = host._app_lifecycle_runtime().valid_control_ref(raw_root)
		var tree_hit := _module_action_circle_at_position_in_tree(root, event_position)
		if not tree_hit.is_empty():
			return tree_hit
	return {}


func _module_action_circle_at_direct_position(event_position: Vector2) -> Dictionary:
	_prune_invalid_action_cards()
	for raw_card in action_cards.values():
		var card := raw_card as Dictionary
		var raw_host = card.get("pop", null)
		var card_host: Control = host._app_lifecycle_runtime().valid_control_ref(raw_host)
		if card_host == null:
			continue
		if not card_host.is_inside_tree() or not card_host.is_visible_in_tree():
			continue
		var kind := _module_action_zone_kind_at_direct_position(card_host, event_position)
		if kind.is_empty():
			var badge_kind := _module_action_badge_kind_at_direct_position(card_host, event_position)
			if badge_kind == "pin" or badge_kind == "collapse":
				kind = badge_kind
		if kind.is_empty():
			continue
		return {
			"card": card,
			"kind": kind,
			"host": card_host,
			"module_key": str(card_host.get_meta("module_ui_key", ""))
		}
	for raw_root in [content_scroll, detail_lazy_stack]:
		var root: Control = host._app_lifecycle_runtime().valid_control_ref(raw_root)
		var tree_hit := _module_action_circle_at_direct_position_in_tree(root, event_position)
		if not tree_hit.is_empty():
			return tree_hit
	return {}


func _module_action_circle_at_direct_position_in_tree(root: Control, event_position: Vector2) -> Dictionary:
	if root == null or not is_instance_valid(root) or root.is_queued_for_deletion() or not root.is_inside_tree():
		return {}
	if not root.is_visible_in_tree():
		return {}
	var module_key: String = ModuleUiRuntime.normalize(root.get_meta("module_ui_key", ""))
	if not module_key.is_empty() and _module_ui_key_allows_pin_or_collapse(module_key):
		var kind := _module_action_zone_kind_at_direct_position(root, event_position)
		if kind.is_empty():
			var badge_kind := _module_action_badge_kind_at_direct_position(root, event_position)
			if badge_kind == "pin" or badge_kind == "collapse":
				kind = badge_kind
		if not kind.is_empty():
			return {
				"card": {},
				"kind": kind,
				"host": root,
				"module_key": module_key
			}
	for child in root.get_children():
		var child_control := child as Control
		if child_control == null:
			continue
		var child_hit := _module_action_circle_at_direct_position_in_tree(child_control, event_position)
		if not child_hit.is_empty():
			return child_hit
	return {}


func _module_action_zone_kind_at_direct_position(card_host: Control, event_position: Vector2) -> String:
	if card_host == null or not is_instance_valid(card_host):
		return ""
	for child in card_host.get_children():
		var zone := child as Control
		if zone == null or not bool(zone.get_meta("module_action_circle_zone", false)):
			continue
		if not zone.visible or zone.is_queued_for_deletion():
			continue
		var kind := str(zone.get_meta("module_action_kind", ""))
		var rect := zone.get_global_rect()
		var center := rect.get_center()
		var radius := minf(rect.size.x, rect.size.y) * 0.5
		if center.distance_to(event_position) <= radius:
			return kind
	return ""


func _module_action_badge_kind_at_direct_position(card_host: Control, event_position: Vector2) -> String:
	var pin_badge: TextureButton = _module_pin_badge(card_host)
	if _module_pin_badge_contains_direct_point(pin_badge, event_position):
		return "pin"
	var collapse_badge := _module_collapse_badge(card_host)
	if _visible_control_direct_contains_point(collapse_badge, event_position):
		return "collapse"
	return ""


func _module_pin_badge_contains_direct_point(badge: TextureButton, event_position: Vector2) -> bool:
	if badge == null or not is_instance_valid(badge) or not badge.visible or badge.disabled or badge.is_queued_for_deletion():
		return false
	if not badge.is_inside_tree() or not badge.is_visible_in_tree():
		return false
	var clip_host: Control = _module_pin_badge_clip_host(badge)
	if clip_host != null and clip_host.clip_contents and not _visible_control_direct_contains_point(clip_host, event_position):
		return false
	var local_point := badge.get_global_transform().affine_inverse() * event_position
	if local_point.x < ModuleUiRuntime.MODULE_PIN_BADGE_HIT_MIN.x or local_point.y < ModuleUiRuntime.MODULE_PIN_BADGE_HIT_MIN.y:
		return false
	if local_point.x > ModuleUiRuntime.MODULE_PIN_BADGE_HIT_MAX.x or local_point.y > ModuleUiRuntime.MODULE_PIN_BADGE_HIT_MAX.y:
		return false
	return true


func _visible_control_direct_contains_point(control: Control, event_position: Vector2) -> bool:
	if control == null or not is_instance_valid(control) or not control.visible or control.is_queued_for_deletion():
		return false
	if not control.is_inside_tree() or not control.is_visible_in_tree():
		return false
	return control.get_global_rect().has_point(event_position)


func _module_action_circle_at_position_in_tree(root: Control, event_position: Vector2) -> Dictionary:
	if root == null or not is_instance_valid(root) or root.is_queued_for_deletion() or not root.is_inside_tree():
		return {}
	if not root.is_visible_in_tree():
		return {}
	var module_key: String = ModuleUiRuntime.normalize(root.get_meta("module_ui_key", ""))
	if not module_key.is_empty() and _module_ui_key_allows_pin_or_collapse(module_key):
		var kind := _module_action_zone_kind_at_position(root, event_position)
		if kind.is_empty():
			var badge_kind := _module_action_badge_kind_at_position(root, event_position)
			if badge_kind == "pin" or badge_kind == "collapse":
				kind = badge_kind
		if not kind.is_empty():
			return {
				"card": {},
				"kind": kind,
				"host": root,
				"module_key": module_key
			}
	for child in root.get_children():
		var child_control := child as Control
		if child_control == null:
			continue
		var child_hit := _module_action_circle_at_position_in_tree(child_control, event_position)
		if not child_hit.is_empty():
			return child_hit
	return {}


func _module_collapse_badge(card_host: Control) -> Button:
	if card_host == null or not is_instance_valid(card_host) or not card_host.has_meta("module_collapse_badge_id"):
		return null
	return host._app_lifecycle_runtime().valid_button_ref(instance_from_id(int(card_host.get_meta("module_collapse_badge_id", 0))))


func _ensure_module_collapse_badge(card_host: Control, module_key: String) -> Button:
	var existing := _module_collapse_badge(card_host)
	if existing != null and is_instance_valid(existing) and not existing.is_queued_for_deletion():
		return existing
	var badge := Button.new()
	badge.name = "ModuleCollapseConfirmBadge"
	badge.text = ""
	badge.anchor_left = 1.0
	badge.anchor_right = 1.0
	badge.anchor_top = 0.0
	badge.anchor_bottom = 0.0
	badge.size = MODULE_COLLAPSE_BADGE_SIZE
	badge.custom_minimum_size = MODULE_COLLAPSE_BADGE_SIZE
	_position_module_collapse_badge(badge)
	badge.pivot_offset = MODULE_COLLAPSE_BADGE_SIZE * 0.5
	badge.focus_mode = Control.FOCUS_NONE
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.z_index = 4095
	badge.visible = false
	badge.modulate.a = 0.0
	badge.add_theme_color_override("font_color", Color.TRANSPARENT)
	badge.add_theme_stylebox_override("normal", _module_collapse_badge_style(false))
	badge.add_theme_stylebox_override("hover", _module_collapse_badge_style(false))
	badge.add_theme_stylebox_override("pressed", _module_collapse_badge_style(true))
	badge.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var glyph := ModuleCollapseMinusGlyph.new()
	glyph.name = "ModuleCollapseMinusGlyph"
	glyph.set_anchors_preset(Control.PRESET_FULL_RECT)
	glyph.offset_left = 8.0
	glyph.offset_right = -8.0
	glyph.offset_top = 8.0
	glyph.offset_bottom = -8.0
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.z_index = 3
	badge.add_child(glyph)
	badge.pressed.connect(Callable(self, "_collapse_module_ui_key").bind(module_key, card_host.get_instance_id()))
	card_host.add_child(badge)
	card_host.set_meta("module_collapse_badge_id", badge.get_instance_id())
	return badge


func _position_module_collapse_badge(badge: Control) -> void:
	if badge == null or not is_instance_valid(badge):
		return
	badge.anchor_left = 1.0
	badge.anchor_right = 1.0
	badge.anchor_top = 0.0
	badge.anchor_bottom = 0.0
	badge.offset_left = MODULE_COLLAPSE_BADGE_POSITION.x
	badge.offset_right = MODULE_COLLAPSE_BADGE_POSITION.x + MODULE_COLLAPSE_BADGE_SIZE.x
	badge.offset_top = MODULE_COLLAPSE_BADGE_POSITION.y
	badge.offset_bottom = MODULE_COLLAPSE_BADGE_POSITION.y + MODULE_COLLAPSE_BADGE_SIZE.y


func _module_collapse_badge_style(pressed := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_GOLD.darkened(0.08) if pressed else COLOR_GOLD
	style.border_color = COLOR_INK
	style.border_width_left = 8
	style.border_width_top = 8
	style.border_width_right = 8
	style.border_width_bottom = 10
	style.corner_radius_top_left = 999
	style.corner_radius_top_right = 999
	style.corner_radius_bottom_left = 999
	style.corner_radius_bottom_right = 999
	style.shadow_color = Color(0, 0, 0, 0.30)
	style.shadow_size = 9
	style.shadow_offset = Vector2(4, 8)
	return style


func _remove_module_collapse_zones(root: Control) -> void:
	if root == null or not is_instance_valid(root):
		return
	for child in root.get_children():
		if child is Control:
			var child_control := child as Control
			if str(child_control.get_meta("module_action_kind", "")) == "collapse":
				child_control.queue_free()
			else:
				_remove_module_collapse_zones(child_control)


func _action_card_background_texture(action: Dictionary) -> Texture2D:
	var bg_path := str(action.get("bg", ""))
	if bg_path.is_empty():
		bg_path = str(action.get("background", ""))
	return host.visual_texture_cache._texture_or_visual_fallback(bg_path)


func _action_card_background(skill_id: String, action: Dictionary) -> Control:
	var background_texture := _action_card_background_texture(action)
	if DisplayServer.get_name() == "headless" and OS.get_environment("IDLE_ELITE_HEADLESS_SIMPLE_ACTION_BG") == "1":
		var fallback_bg := ColorRect.new()
		fallback_bg.color = ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE).darkened(0.08)
		fallback_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		fallback_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fallback_bg.z_index = 150
		return fallback_bg
	var bg := RoundedTextureRect.new()
	bg.texture = background_texture
	bg.modulate = Color.WHITE
	bg.radius = host.ACTION_CARD_FACE_RADIUS
	bg.mask_inset = ActivityCardStyles.ACTION_CARD_STROKE_WIDTH * 0.5
	bg.corner_mask_mode = 1
	bg.crop_left = host.FISHING_BACKGROUND_CROP_LEFT if skill_id == "fishing" else 0.0
	bg.crop_top = host.FISHING_BACKGROUND_CROP_TOP if skill_id == "fishing" else 0.0
	bg.crop_right = host.FISHING_BACKGROUND_CROP_RIGHT if skill_id == "fishing" else 0.0
	bg.art_height = host.ACTION_CARD_HEIGHT
	bg.fallback_color = ThemeStyles.activity_card_fill_color(ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE))
	if host._convergence_runtime()._is_convergence_action(action):
		bg.aspect_mode = 2
		bg.fallback_color = Color("#8baa54")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.z_index = 150
	return bg



func _detail_action_card_shell(skill_id: String, action: Dictionary, content_width: float, uses_blue_guy_chicken_brawl_stage: bool) -> Dictionary:
	var uses_diamond_arena: bool = host._fighting_runtime().action_uses_diamond_combat_arena(action)
	var uses_recovery_card := RecoveryModules.has_recovery(action)
	var uses_flat_normal_card := not uses_recovery_card and not uses_diamond_arena
	var uses_rooster_stage: bool = host._fighting_runtime().action_uses_rooster_punch_out_stage(action)
	var card_depth_offset: Vector2 = host.ACTION_CARD_3D_DEPTH_OFFSET if uses_diamond_arena else (ActivityCardStyles.RECOVERY_ACTIVITY_CARD_DEPTH_OFFSET if uses_recovery_card else ActivityCardStyles.NORMAL_ACTIVITY_CARD_DEPTH_OFFSET)
	var face_bottom_inset: float = card_depth_offset.y
	var layout_depth_offset_y: float = host.ACTION_CARD_3D_DEPTH_OFFSET.y if uses_diamond_arena else card_depth_offset.y
	var card_root := Control.new()
	card_root.custom_minimum_size = Vector2(content_width, ActivityCardStyles.root_height_for_action(action, false, uses_diamond_arena, host.ACTION_CARD_HEIGHT, host.ACTION_CARD_EXPANDED_HEIGHT, host.COMBAT_DIAMOND_ARENA_CARD_HEIGHT, layout_depth_offset_y))
	card_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_root.clip_contents = false

	var pop_card := Control.new()
	pop_card.name = "ActivityCardFace"
	pop_card.anchor_left = 0.0
	pop_card.anchor_right = 1.0
	pop_card.anchor_top = 0.0
	pop_card.anchor_bottom = 1.0
	pop_card.offset_left = host.ACTION_CARD_POP_GUTTER
	pop_card.offset_right = -host.ACTION_CARD_POP_GUTTER
	pop_card.offset_top = 0.0
	pop_card.set_meta("activity_card_depth_bottom_inset", card_depth_offset.y)
	pop_card.offset_bottom = ActivityCardStyles.activity_card_pop_base_bottom_offset(pop_card)
	pop_card.set_meta("activity_card_base_offset_left", pop_card.offset_left)
	pop_card.set_meta("activity_card_base_offset_right", pop_card.offset_right)
	if not uses_diamond_arena:
		pop_card.set_meta("activity_card_press_offset", ActivityCardStyles.NORMAL_ACTIVITY_CARD_PRESS_OFFSET)
	pop_card.clip_contents = false
	pop_card.mouse_filter = Control.MOUSE_FILTER_PASS
	pop_card.z_index = 1

	var depth: ActivityCardDepth = null
	if uses_diamond_arena:
		pop_card.set_meta("activity_card_depth_bottom_inset", 0.0)
		pop_card.offset_bottom = ActivityCardStyles.activity_card_pop_base_bottom_offset(pop_card)
	else:
		depth = ActivityCardStyles.activity_card_depth_layer(ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE), card_depth_offset, host.ACTION_CARD_FACE_RADIUS, host.ACTION_CARD_POP_GUTTER)
		ThemeStyles.apply_activity_card_depth_action_theme(depth, skill_id, action, Callable(host._activity_unlock_runtime(), "_action_unlock_requirements"), host.COLOR_BLUE)
		_apply_recovery_card_depth_shape(depth, action)
		if uses_flat_normal_card:
			ActivityCardStyles.apply_normal_activity_card_depth(depth, ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE))
			depth.visible = false
		if BuildableModules.is_buildable(action) and not BuildableModules.is_built(host.built_modules, skill_id, action, Callable(host, "_action_key")):
			depth.back_color = Color("#14758e")
			depth.side_color = Color("#0f5e75")
			depth.bottom_color = Color("#1f9ab8")
			depth.highlight_color = Color(0.72, 0.95, 1.0, 0.24)
			depth.shadow_color = Color(0.02, 0.08, 0.10, 0.32)
		card_root.add_child(depth)
		pop_card.set_meta("activity_card_depth_node_id", depth.get_instance_id())
	card_root.add_child(pop_card)

	var background_underlay_fill: Color = ThemeStyles.activity_card_fill_color(ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE))
	if uses_flat_normal_card:
		background_underlay_fill = Color(0, 0, 0, 0)
	var background_underlay: Panel = ActivityCardStyles.action_card_background_edge_underlay(background_underlay_fill, host.ACTION_CARD_FACE_RADIUS)
	background_underlay.add_theme_stylebox_override("panel", ActivityCardStyles.activity_card_face_skin(background_underlay_fill, host.ACTION_CARD_FACE_RADIUS, host.paper_button_style_textures, host.COLOR_INK, host.COLOR_BLUE, Callable(host.visual_texture_cache, "_can_create_image_textures"), Callable(host.visual_texture_cache, "_create_image_texture"), Callable(host.visual_texture_cache, "_visual_fallback_texture")))
	background_underlay.visible = false
	pop_card.add_child(background_underlay)
	if uses_flat_normal_card:
		var body_plate := Panel.new()
		body_plate.name = "NormalActivityCardBackFace"
		body_plate.set_anchors_preset(Control.PRESET_FULL_RECT)
		body_plate.offset_left = pop_card.offset_left
		body_plate.offset_right = pop_card.offset_right
		body_plate.offset_top = card_depth_offset.y
		body_plate.offset_bottom = 0.0
		body_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body_plate.z_index = 145
		body_plate.add_theme_stylebox_override("panel", ActivityCardStyles.normal_activity_card_body(host.ACTION_CARD_FACE_RADIUS, host.COLOR_INK, ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE)))
		card_root.add_child(body_plate)
		var body_connectors := ActivityCardStyles.prism_connector_overlay(card_depth_offset, host.ACTION_CARD_FACE_RADIUS, "", ActivityCardStyles.ACTION_CARD_STROKE_WIDTH, host.COLOR_INK)
		body_connectors.name = "NormalActivityCardPrismConnectors"
		body_connectors.offset_left = pop_card.offset_left
		body_connectors.offset_right = pop_card.offset_right
		body_connectors.face_bottom_inset = card_depth_offset.y
		var normal_card_base_color := ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE).darkened(0.42)
		body_connectors.side_fill_color = normal_card_base_color
		body_connectors.bottom_fill_color = normal_card_base_color
		body_connectors.z_index = 146
		card_root.add_child(body_connectors)
		pop_card.set_meta("activity_card_connector_node_id", body_connectors.get_instance_id())
	var bg = _action_card_background(skill_id, action)
	_apply_recovery_card_background_shape(bg, action)
	if uses_flat_normal_card:
		bg.offset_left = 0.0
		bg.offset_right = 0.0
		bg.offset_top = 0.0
		bg.offset_bottom = -face_bottom_inset
		if bg is RoundedTextureRect:
			(bg as RoundedTextureRect).radius = host.ACTION_CARD_FACE_RADIUS
	bg.visible = not uses_diamond_arena
	pop_card.add_child(bg)
	if uses_flat_normal_card:
		var face_outline := ActivityCardBorder.new()
		face_outline.set_anchors_preset(Control.PRESET_FULL_RECT)
		face_outline.offset_bottom = -face_bottom_inset
		face_outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		face_outline.z_index = host.ACTION_CARD_FACE_BORDER_Z_INDEX
		face_outline.radius = host.ACTION_CARD_FACE_RADIUS
		face_outline.border_width = ActivityCardStyles.ACTION_CARD_STROKE_WIDTH
		face_outline.border_color = Color("#171615")
		pop_card.add_child(face_outline)

	var rooster_boss_stage: Control = null
	if uses_rooster_stage:
		pop_card.clip_contents = true
		rooster_boss_stage = RoosterPunchOutStage.new()
		rooster_boss_stage.set_anchors_preset(Control.PRESET_FULL_RECT)
		rooster_boss_stage.offset_bottom = -face_bottom_inset
		rooster_boss_stage.z_index = 220
		host._fighting_runtime().configure_rooster_punch_out_stage(rooster_boss_stage)
		pop_card.add_child(rooster_boss_stage)
		card_root.set_meta("boss_stage", "rooster_punch_out")

	var blue_guy_chicken_stage: Control = null
	if uses_blue_guy_chicken_brawl_stage:
		blue_guy_chicken_stage = BlueGuyChickenBrawlStageClass.new()
		blue_guy_chicken_stage.set_anchors_preset(Control.PRESET_FULL_RECT)
		blue_guy_chicken_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
		blue_guy_chicken_stage.z_index = 220
		if uses_diamond_arena:
			blue_guy_chicken_stage.z_index = host.MODULE_TITLE_OVER_PIN_Z_INDEX + 1
			blue_guy_chicken_stage.set("arena_shape", "diamond")
			blue_guy_chicken_stage.offset_top = -40.0
			blue_guy_chicken_stage.offset_bottom = -140.0
		pop_card.add_child(blue_guy_chicken_stage)
		if blue_guy_chicken_stage.has_method("setup_action"):
			blue_guy_chicken_stage.call("setup_action", action)
		host._fighting_runtime().configure_blue_guy_chicken_brawl_stage(blue_guy_chicken_stage)
		if uses_diamond_arena:
			blue_guy_chicken_stage.clip_contents = false
			var diamond_frame := _attach_diamond_combat_arena_frame(pop_card)
			diamond_frame.offset_top = blue_guy_chicken_stage.offset_top
			diamond_frame.offset_bottom = blue_guy_chicken_stage.offset_bottom
			diamond_frame.z_index = blue_guy_chicken_stage.z_index - 1
			card_root.set_meta("combat_arena_shape", "diamond")

	var shade: Panel = null
	if not host._activity_unlock_runtime()._is_action_unlocked(skill_id, action):
		shade = ActivityCardStyles.activity_card_shade_layer(pop_card, 0.20)
		if uses_diamond_arena:
			shade.z_index = blue_guy_chicken_stage.z_index + 1

	return {
		"card_root": card_root,
		"pop": pop_card,
		"depth": depth,
		"bg": bg,
		"shade": shade,
		"rooster_boss_stage": rooster_boss_stage,
		"blue_guy_chicken_stage": blue_guy_chicken_stage,
	}


func _attach_diamond_combat_arena_frame(pop_card: Control) -> _DiamondArenaFrame:
	var frame := _DiamondArenaFrame.new()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.visible = false
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.z_index = 238
	frame.fill_color = Color("#a01419")
	frame.border_color = COLOR_INK
	frame.accent_color = Color("#ff0b42")
	frame.border_width = ActivityCardStyles.ACTION_CARD_STROKE_WIDTH
	frame.accent_width = 6.0
	frame.inset = 26.0
	pop_card.add_child(frame)
	return frame


func _detail_action_card_body(card_root: Control, pop_card: Control, skill_id: String, action: Dictionary, is_convergence_card: bool, uses_blue_guy_chicken_brawl_stage: bool) -> Dictionary:
	var uses_rooster_boss_stage = host._fighting_runtime().action_uses_rooster_punch_out_stage(action)
	var uses_flat_normal_card: bool = not host._fighting_runtime().action_uses_diamond_combat_arena(action)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 68 if uses_flat_normal_card else 54)
	margin.add_theme_constant_override("margin_right", 82 if uses_flat_normal_card else 54)
	margin.add_theme_constant_override("margin_top", 38 if uses_flat_normal_card else 46)
	margin.add_theme_constant_override("margin_bottom", 126)
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.z_index = 200
	margin.visible = not uses_blue_guy_chicken_brawl_stage and not uses_rooster_boss_stage
	pop_card.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 48 if uses_flat_normal_card else 56)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_child(row)

	var art_slot := MarginContainer.new()
	art_slot.add_theme_constant_override("margin_top", 152 if uses_flat_normal_card else 146)
	art_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art_panel := Panel.new()
	var art_panel_size := Vector2(400, 400) if uses_flat_normal_card else ActionArtUi.ACTION_ART_PANEL_SIZE
	art_panel.custom_minimum_size = art_panel_size
	art_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var art_panel_style := ActivityCardStyles.cached_action_art(Callable(host, "_surface_style"))
	art_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new() if uses_flat_normal_card else art_panel_style)
	art_panel.clip_contents = false
	art_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_slot.add_child(art_panel)
	if uses_flat_normal_card:
		var art_face := ActionArtUi.border_overlay(art_panel_style)
		art_face.name = "ActionArtRaisedFace"
		art_face.z_index = 1
		art_panel.add_child(art_face)
	var art = ActionArtUi.image(action, Callable(host.visual_texture_cache, "_texture_or_visual_fallback"), Callable(host.visual_texture_cache, "_visual_fallback_texture"), DisplayServer.get_name() == "headless")
	if uses_flat_normal_card:
		art.custom_minimum_size = Vector2(416, 416)
		art.size = Vector2(416, 416)
		art.position = Vector2(-8, -8)
		art.z_index = 2
	art_panel.add_child(art)
	if uses_blue_guy_chicken_brawl_stage:
		art.visible = false
	ActionArtUi.add_corner_badges(
		art_panel,
		ActionArtUi.resource_icon_paths(action, Callable(host._action_runtime(), "_action_mat_reward_defs"), Callable(host.material_runtime, "icon_path"), Callable(host._temporary_event_runtime(), "_temporary_event_log_reward_mat_id")),
		ActionArtUi.special_type_icon_path(action, Callable(host, "_is_event_action")),
		Callable(host.visual_texture_cache, "_texture_or_visual_fallback")
	)
	var art_border := ActionArtUi.border_overlay(ActivityCardStyles.cached_action_art_border(Callable(host, "_surface_style")))
	art_panel.add_child(art_border)

	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 18 if uses_flat_normal_card else 38)
	copy.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(copy)
	if not is_convergence_card and not uses_blue_guy_chicken_brawl_stage:
		row.add_child(art_slot)

	var title_row: HBoxContainer = null
	var build_title_button_panel: PanelContainer = null
	var build_title_button_label: Label = null
	if BuildableModules.is_buildable(action) and not BuildableModules.is_built(host.built_modules, skill_id, action, Callable(host, "_action_key")):
		title_row = HBoxContainer.new()
		title_row.alignment = BoxContainer.ALIGNMENT_BEGIN
		title_row.add_theme_constant_override("separation", 18)
		title_row.mouse_filter = Control.MOUSE_FILTER_PASS
		title_row.z_index = 735
		title_row.z_as_relative = false
		copy.add_child(title_row)

	var action_name_label = host._label(ActivityCardStyles.activity_card_title_text(str(action["name"])), ActivityCardStyles.ACTIVITY_CARD_TITLE_FONT_SIZE, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT) as Label
	ActivityCardStyles.configure_activity_card_title(action_name_label)
	action_name_label.add_theme_color_override("font_outline_color", COLOR_INK)
	action_name_label.add_theme_constant_override("outline_size", host.ACTION_CARD_TITLE_OUTLINE_SIZE)
	action_name_label.self_modulate = Color.WHITE
	action_name_label.set_meta("module_ui_title_label", true)
	action_name_label.set_meta("activity_card_locked_title_z_index", 0)
	action_name_label.z_index = ActivityCardStyles.activity_card_title_z_index(host._activity_unlock_runtime()._is_action_unlocked(skill_id, action), action_name_label, host.MODULE_TITLE_OVER_PIN_Z_INDEX)
	if title_row != null:
		action_name_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		action_name_label.custom_minimum_size = Vector2(640, 120)
		action_name_label.z_index = 0
		action_name_label.z_as_relative = true
		title_row.add_child(action_name_label)
		build_title_button_panel = PanelContainer.new()
		build_title_button_panel.custom_minimum_size = Vector2(352, 134)
		build_title_button_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		build_title_button_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		build_title_button_panel.add_theme_stylebox_override("panel", BuildableModuleOverlay.cta_style(BuildableModules.can_pay(action, Callable(host.material_runtime, "amount")), COLOR_INK, true))
		title_row.add_child(build_title_button_panel)
		build_title_button_label = BuildableModuleOverlay.label(BuildableModules.label(action).to_upper(), 84, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, host.app_bold_font, host.app_font)
		build_title_button_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		build_title_button_label.add_theme_color_override("font_outline_color", COLOR_INK)
		build_title_button_label.add_theme_constant_override("outline_size", 24)
		build_title_button_panel.add_child(build_title_button_label)
	else:
		var title_spacer := Control.new()
		title_spacer.custom_minimum_size = Vector2(0, 120)
		title_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		copy.add_child(title_spacer)
		var title_band := MarginContainer.new()
		title_band.set_anchors_preset(Control.PRESET_TOP_WIDE)
		title_band.offset_left = 16
		title_band.offset_right = -16
		title_band.offset_top = 32
		title_band.offset_bottom = 172
		title_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
		title_band.z_index = 200
		title_band.visible = margin.visible
		pop_card.add_child(title_band)
		title_band.add_child(action_name_label)
	card_root.set_meta("module_ui_title_label_id", action_name_label.get_instance_id())
	pop_card.set_meta("module_ui_title_label_id", action_name_label.get_instance_id())

	return {
		"margin": margin,
		"row": row,
		"art_panel": art_panel,
		"art": art,
		"copy": copy,
		"title": action_name_label,
		"build_button_panel": build_title_button_panel,
		"build_cta_title": build_title_button_label,
	}


func _detail_action_stat_widgets(copy: VBoxContainer, skill_id: String, action: Dictionary, action_id: String, is_convergence_card: bool) -> Dictionary:
	var uses_flat_normal_card: bool = not host._fighting_runtime().action_uses_diamond_combat_arena(action)
	var stat_row := HBoxContainer.new()
	stat_row.add_theme_constant_override("separation", 18 if uses_flat_normal_card else 28)
	stat_row.mouse_filter = Control.MOUSE_FILTER_PASS
	copy.add_child(stat_row)

	var xp_label = _action_stat_label("") as Label
	var stamina_label = _action_stat_label("") as Label
	var time_label = _action_stat_label("") as Label
	var success_label = _action_stat_label("") as Label
	var xp_box: Control = null
	var stamina_box: Control = null
	var time_box: Control = null
	var success_box: Control = null
	var normal_stat_top: Label = null
	var normal_stat_bottom: Label = null
	if uses_flat_normal_card:
		var stat_panel := _normal_activity_stat_panel(Vector2(0, 272), ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE))
		var stat_items := GridContainer.new()
		stat_items.columns = 2
		stat_items.add_theme_constant_override("h_separation", 20)
		stat_items.add_theme_constant_override("v_separation", -24)
		stat_items.mouse_filter = Control.MOUSE_FILTER_IGNORE
		xp_box = _normal_activity_stat_item(xp_label, "xp", true, skill_id, action_id)
		stamina_box = _normal_activity_stat_item(stamina_label, "stamina", true, skill_id, action_id)
		time_box = _normal_activity_stat_item(time_label, "time", true, skill_id, action_id)
		success_box = _normal_activity_stat_item(success_label, "success", true, skill_id, action_id)
		stat_items.add_child(xp_box)
		stat_items.add_child(time_box)
		stat_items.add_child(stamina_box)
		stat_items.add_child(success_box)
		stat_panel.add_child(stat_items)
		stat_row.add_child(stat_panel)
	else:
		xp_box = _action_stat_box(xp_label, true, skill_id, action_id, "xp") as Control
		stat_row.add_child(xp_box)
		stamina_box = _action_stat_box(stamina_label, true, skill_id, action_id, "stamina") as Control
		stat_row.add_child(stamina_box)
		time_box = _action_stat_box(time_label, true, skill_id, action_id, "time") as Control
		stat_row.add_child(time_box)
		if not host._fighting_runtime().action_uses_diamond_combat_arena(action):
			success_box = _action_stat_box(success_label, true, skill_id, action_id, "success") as Control
			stat_row.add_child(success_box)
	host._material_collection_surface().call_deferred("sync_berry_prep_badges")

	var initial_xp_parts = host._action_runtime()._action_xp_reward_parts_for_display(skill_id, action)
	host._app_lifecycle_runtime().set_label_text_if_changed(xp_label, "+%s" % GameFormatting.info_chip_number(float(host._action_runtime()._action_xp_reward_total(initial_xp_parts))))
	host._app_lifecycle_runtime().set_label_text_if_changed(stamina_label, host._skill_swipe_activity_surface()._action_stamina_stat_text(skill_id, action))
	host._app_lifecycle_runtime().set_label_text_if_changed(time_label, "%ss" % GameFormatting.info_chip_number(host._action_runtime()._action_cycle_seconds(skill_id, action)))
	host._app_lifecycle_runtime().set_label_text_if_changed(success_label, "%s%%" % GameFormatting.info_chip_number(host._action_runtime()._success_chance(skill_id, action)))
	_sync_action_stat_chip_title(xp_label, "XP")
	_sync_action_stat_chip_title(stamina_label, "STAM" if host._skill_swipe_activity_surface()._action_shows_stamina_stat(skill_id, action) else "")
	_sync_action_stat_chip_title(time_label, "TIME")
	_sync_action_stat_chip_title(success_label, "RATE")
	if uses_flat_normal_card:
		_sync_normal_activity_stat_text({
			"normal_stat_top": normal_stat_top,
			"normal_stat_bottom": normal_stat_bottom,
			"xp": xp_label,
			"stamina": stamina_label,
			"time": time_label,
			"success": success_label,
		}, host._skill_swipe_activity_surface()._action_shows_stamina_stat(skill_id, action), "TIME")
	if is_convergence_card:
		stamina_box.visible = false
		if success_box != null:
			success_box.visible = false

	return {
		"stat_row": stat_row,
		"xp": xp_label,
		"stamina": stamina_label,
		"time": time_label,
		"success": success_label,
		"normal_stat_top": normal_stat_top,
		"normal_stat_bottom": normal_stat_bottom,
		"stat_boxes": {
			"xp": xp_box,
			"stamina": stamina_box,
			"time": time_box,
			"success": success_box,
		},
	}


func _detail_action_boss_line(copy: VBoxContainer, action: Dictionary) -> Label:
	var fighting_runtime = host._fighting_runtime()
	if copy == null or not fighting_runtime.is_boss_fight_action(action) or fighting_runtime.action_uses_rooster_punch_out_stage(action):
		return null
	var boss := action.get("boss", {}) as Dictionary
	var cleared_text := "CLEARED" if fighting_runtime.boss_is_completed(action) else "BOSS GATE"
	var text := "%s: %s  %s HP" % [cleared_text, fighting_runtime.boss_name(action).to_upper(), int(boss.get("hp", 100))]
	var node := Label.new()
	node.text = text
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size", host.MIN_MOBILE_INFO_TITLE_FONT_SIZE)
	node.add_theme_color_override("font_color", Color("#ffe56b"))
	node.add_theme_color_override("font_outline_color", host.COLOR_INK)
	node.add_theme_constant_override("outline_size", 18)
	if host.app_bold_font != null:
		node.add_theme_font_override("font", host.app_bold_font)
	elif host.app_font != null:
		node.add_theme_font_override("font", host.app_font)
	copy.add_child(node)
	return node


func _detail_action_mastery_widgets(copy: VBoxContainer, art_panel: Panel, skill_id: String, action: Dictionary) -> Dictionary:
	var medal: TextureRect = null
	var mastery_progress: CleanProgressBar = null
	var mastery_ring: Control = null
	if MasteryState.action_has_mastery(host, action):
		mastery_ring = ActivityCardStyles.action_art_mastery_ring(ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE))
		mastery_ring.z_index = 0
		art_panel.add_child(mastery_ring)
		medal = TextureRect.new()
		medal.anchor_left = 0.0
		medal.anchor_right = 0.0
		medal.anchor_top = 0.0
		medal.anchor_bottom = 0.0
		medal.offset_left = 0
		medal.offset_right = 190
		medal.offset_top = 0
		medal.offset_bottom = 190
		medal.size = Vector2(190, 190)
		medal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		medal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		medal.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		medal.texture = host._skill_swipe_activity_surface()._action_card_medal_texture_for_level(0)
		medal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		medal.z_index = host.ACTION_CARD_FACE_BORDER_Z_INDEX + 1
		art_panel.add_child(medal)
		mastery_progress = ThemeStyles.progress_bar(Color("#f4bf35"), 56)
		mastery_progress.border_color = COLOR_INK
		mastery_progress.border_width = ActivityCardStyles.ACTION_CARD_STROKE_WIDTH
		ThemeStyles.apply_mastery_progress_bar_theme(mastery_progress, ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE), host.COLOR_INK)
		mastery_progress.easing_speed = 5.0
		mastery_progress.z_index = 20
		copy.add_child(mastery_progress)
	return {"medal": medal, "mastery": mastery_progress, "mastery_ring": mastery_ring}


func _detail_action_progress_widgets(card_root: Control, pop_card: Control, skill_id: String, action: Dictionary, content_width: float, uses_blue_guy_chicken_brawl_stage: bool) -> Dictionary:
	var progress: ActivityProgressRail = null
	var convergence_progress: ConvergenceMultiProgressBar = null
	var fluid_strip: Control = null
	if host._fishing_rework_active_for_skill(skill_id) and not host.fishing_runtime.action_should_render_standalone(host, skill_id, action):
		fluid_strip = host._fishing_ui_surface()._attach_fishing_fluid_strip(pop_card, action)
	elif host._convergence_runtime()._is_convergence_action(action):
		convergence_progress = ConvergenceMultiProgressBar.new()
		convergence_progress.anchor_left = 0.0
		convergence_progress.anchor_right = 1.0
		convergence_progress.anchor_top = 1.0
		convergence_progress.anchor_bottom = 1.0
		convergence_progress.offset_left = host.ACTION_PROGRESS_RAIL_INSET + 18
		convergence_progress.offset_right = -host.ACTION_PROGRESS_RAIL_INSET - 18
		convergence_progress.offset_top = -CONVERGENCE_BAR_HEIGHT + 34
		convergence_progress.offset_bottom = 34
		convergence_progress.z_index = 234
		convergence_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pop_card.add_child(convergence_progress)
	elif not uses_blue_guy_chicken_brawl_stage and not host._fighting_runtime().action_uses_rooster_punch_out_stage(action):
		progress = ActivityProgressRail.new()
		progress.visible = true
		ThemeStyles.apply_activity_progress_rail_action_theme(progress, ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE), ThemeStyles.combo_progress_segment_theme_colors(skill_id, action, Callable(host._activity_unlock_runtime(), "_action_unlock_requirements"), host.COLOR_BLUE), host.COLOR_INK)
		progress.anchor_left = 0.0
		progress.anchor_right = 1.0
		progress.anchor_top = 1.0
		progress.anchor_bottom = 1.0
		progress.offset_left = 0.0
		progress.offset_right = 0.0
		var normal_progress_bottom_margin := 0.0
		progress.offset_top = -host.ACTION_PROGRESS_RAIL_HEIGHT if RecoveryModules.has_recovery(action) else -ActivityCardStyles.NORMAL_ACTIVITY_CARD_DEPTH_OFFSET.y - normal_progress_bottom_margin - NORMAL_ACTIVITY_PROGRESS_HEIGHT
		progress.offset_bottom = -host.ACTION_PROGRESS_RAIL_INSET if RecoveryModules.has_recovery(action) else -ActivityCardStyles.NORMAL_ACTIVITY_CARD_DEPTH_OFFSET.y - normal_progress_bottom_margin
		progress.top_lip_height = ActivityCardStyles.ACTION_CARD_STROKE_WIDTH
		progress.edge_inset = ActivityCardStyles.ACTION_CARD_STROKE_WIDTH
		if not RecoveryModules.has_recovery(action):
			progress.bottom_radius = host.ACTION_CARD_FACE_RADIUS
		if skill_id == host.running_skill_id and str(action.get("id", "")) == host.running_action_id:
			progress.set_value(clampf(host.action_progress, 0.0, 1.0) * 100.0)
		_apply_recovery_progress_rail_shape(progress, action)
		progress.z_index = 232
		progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pop_card.add_child(progress)

	var mat_collection = host._material_collection_surface()._build_mat_collection_row(skill_id, action, content_width) if host._action_runtime()._action_has_mat_rewards(action) else {}
	if not mat_collection.is_empty():
		card_root.add_child(mat_collection.get("root") as Control)

	return {
		"progress": progress,
		"convergence_progress": convergence_progress,
		"fluid_strip": fluid_strip,
		"mat_collection": mat_collection,
	}


func _detail_action_convergence_overlay(pop_card: Control, action: Dictionary) -> Dictionary:
	if host._convergence_runtime()._is_convergence_action(action):
		return ConvergenceBuildOverlay.build(pop_card, CONVERGENCE_BUILD_OVERLAY_COLOR, COLOR_INK, host.app_bold_font, host.app_font, host.MIN_MOBILE_BODY_FONT_SIZE)
	return {}


func _sync_convergence_card_static_state(card: Dictionary, action: Dictionary, unlocked: bool) -> void:
	var convergence_runtime = host._convergence_runtime()
	var module_id := str(action.get("id", ConvergenceRuntime.CONVERGENCE_DEFAULT_MODULE_ID))
	var state: Dictionary = convergence_runtime._ensure_convergence_state(module_id)
	var built := bool(state.get("built", false))
	var building := bool(state.get("building", false))
	var requires_build: bool = convergence_runtime._convergence_requires_build(action)
	var overlay := card.get("convergence_overlay") as ColorRect
	var overlay_label := card.get("convergence_overlay_label") as Label
	var cta := card.get("convergence_build_cta") as PanelContainer
	var cta_meta := card.get("convergence_build_cta_meta") as Label
	var bg := card.get("bg") as CanvasItem
	var art_panel := card.get("art_panel") as CanvasItem
	var art := card.get("art") as CanvasItem
	var convergence_progress := card.get("convergence_progress") as ConvergenceMultiProgressBar
	var should_overlay: bool = requires_build and unlocked and (building or not built)
	if overlay != null:
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(overlay, should_overlay)
		var overlay_color := CONVERGENCE_BUILD_OVERLAY_COLOR if building else Color(0.08, 0.07, 0.05, 0.26)
		if not host._app_lifecycle_runtime().colors_close_enough(overlay.color, overlay_color):
			overlay.color = overlay_color
	if overlay_label != null:
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(overlay_label, unlocked and building)
		if building:
			host._app_lifecycle_runtime().set_label_text_if_changed(overlay_label, "BUILDING\n%s" % GameFormatting.countdown(convergence_runtime._convergence_build_remaining(module_id)))
	if cta != null:
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(cta, requires_build and unlocked and not built and not building)
	if cta_meta != null:
		var cta_text := "%s Softwood  |  %s" % [convergence_runtime._convergence_log_cost(action), GameFormatting.countdown(convergence_runtime._convergence_build_seconds(action))]
		if not requires_build:
			cta_text = "READY"
		host._app_lifecycle_runtime().set_label_text_if_changed(cta_meta, cta_text)
	var tint := Color.WHITE if built else CONVERGENCE_UNBUILT_CARD_TINT
	if bg != null:
		host._app_lifecycle_runtime().set_canvas_item_modulate_if_changed(bg, tint)
	if art_panel != null:
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(art_panel, not convergence_runtime._is_convergence_action(action))
	if art != null:
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(art, not convergence_runtime._is_convergence_action(action))
	if convergence_progress != null:
		convergence_progress.set_bar_pattern(convergence_runtime._convergence_bar_pattern(action))
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(convergence_progress, built)


func _detail_action_buildable_overlay(pop_card: Control, skill_id: String, action: Dictionary) -> Dictionary:
	if pop_card == null or not BuildableModules.is_buildable(action) or BuildableModules.is_built(host.built_modules, skill_id, action, Callable(host, "_action_key")):
		return {}
	var cost_text = BuildableModules.cost_text(action, Callable(host.material_runtime, "amount_text_for_host").bind(host), Callable(host.material_runtime, "display_name"))
	var meta_text := "Cost: %s" % cost_text if not cost_text.is_empty() else "Ready to build"
	var cost: Dictionary = BuildableModules.cost(action)
	var cost_icon_paths := {}
	for raw_mat_id in cost.keys():
		var mat_id := str(raw_mat_id)
		cost_icon_paths[mat_id] = host.material_runtime.icon_path(mat_id)
	var plank_textures := []
	for texture_path in MaterialRuntime.BUILD_REQUIRED_PLANK_PIECE_TEXTURES:
		plank_textures.append(host.visual_texture_cache._texture_or_visual_fallback(str(texture_path)))
	return BuildableModuleOverlay.build(pop_card, str(action.get("name", "Module")), meta_text, BuildableModules.label(action).to_upper(), BuildableModules.can_pay(action, Callable(host.material_runtime, "amount")), COLOR_INK, host.app_bold_font, host.app_font, host.MIN_MOBILE_BODY_FONT_SIZE, plank_textures, cost, cost_icon_paths)


func _play_buildable_module_built_animation(skill_id: String, action: Dictionary, refresh_scroll: int) -> bool:
	var action_id := str(action.get("id", ""))
	var card_key: String = str(host._action_key(skill_id, action_id))
	if card_key.is_empty() or not action_cards.has(card_key):
		return false
	var card := action_cards[card_key] as Dictionary
	var overlay: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("build_overlay"))
	var plank_layer: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("build_plank_layer"))
	var cta: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("build_cta"))
	var button: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("build_button_panel"))
	if overlay == null and plank_layer == null and cta == null and button == null:
		return false
	var tween: Tween = host.create_tween()
	tween.set_parallel(true)
	for raw_node in [overlay, plank_layer, cta, button]:
		var node := raw_node as Control
		if node == null:
			continue
		node.set_meta("build_complete_animation_tween", tween)
		tween.tween_property(node, "modulate:a", 0.0, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var plank_nodes: Array = card.get("build_plank_nodes", []) as Array
	if plank_nodes is Array:
		for raw_plank in plank_nodes:
			var plank := raw_plank as Control
			if plank == null or not is_instance_valid(plank):
				continue
			plank.pivot_offset = plank.size * 0.5
			tween.tween_property(plank, "scale", Vector2(1.10, 0.72), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tween.tween_property(plank, "position", plank.position + Vector2(0.0, -180.0), 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.finished.connect(_finish_buildable_module_built_animation.bind(refresh_scroll))
	return true


func _finish_buildable_module_built_animation(refresh_scroll: int) -> void:
	host._navigation_shell()._render_screen(false, refresh_scroll)
	host._update_ui(0.0, true)


func _activity_lock_overlay(parent: Control, unlock_level: int, skill_id = "", requirements = []) -> Dictionary:
	var overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.clip_contents = false
	overlay.visible = false
	overlay.z_index = 280
	parent.add_child(overlay)

	var group = ActivityLockCluster.new()
	var theme_skill_id = skill_id if not skill_id.is_empty() else host.selected_skill_id
	var padlock_source: Texture2D = host.visual_texture_cache._texture(ActivityLockRig.UNLOCK_PADLOCK_TEXTURE)
	group.setup(
		host.visual_texture_cache._texture(ActivityLockRig.UNLOCK_CHAIN_LINK_TEXTURE),
		ActivityLockRig.cropped_padlock_texture(padlock_source),
		host.visual_texture_cache._texture(ActivityLockRig.UNLOCK_LOCK_PULSE_MASK_TEXTURE),
		unlock_level,
		host.app_bold_font,
		host.app_font,
		ActivityLockRig.cropped_padlock_hit_image(padlock_source),
		host.visual_texture_cache._texture(ActivityLockRig.UNLOCK_LOCK_TINT_MASK_TEXTURE),
		ThemeStyles.skill_theme_color(theme_skill_id, host.COLOR_BLUE),
		host.visual_texture_cache._texture(ActivityLockRig.UNLOCK_LOCK_BODY_TEXTURE),
		host.visual_texture_cache._texture(ActivityLockRig.UNLOCK_LOCK_SHACKLE_CLOSED_TEXTURE),
		host.visual_texture_cache._texture(ActivityLockRig.UNLOCK_LOCK_SHACKLE_OPEN_TEXTURE),
		requirements
	)
	group.set_anchors_preset(Control.PRESET_FULL_RECT)
	group.clip_contents = false
	group.visible = false
	group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.chain_moved.connect(host._audio_director()._play_chain_move_jingle_mix.bind(group))
	group.padlock_clicked.connect(host._audio_director()._play_padlock_cluster_sfx)
	group.padlock_clicked.connect(Callable(host._onboarding_runtime(), "_mark_lock_click_tip_seen"))
	overlay.add_child(group)

	return {
		"root": overlay,
		"group": group
	}


func _connect_activity_lock_handler(overlay: Dictionary, skill_id: String, action_id: String) -> void:
	var group = host._app_lifecycle_runtime().valid_control_ref(overlay.get("group"))
	if group == null or action_id.is_empty():
		return
	group.padlock_clicked.connect(_on_activity_lock_clicked.bind(skill_id, action_id, group))


func _ensure_activity_lock_overlay(card: Dictionary, unlock_level: int) -> Dictionary:
	var existing = card.get("lock_overlay", {}) as Dictionary
	if not existing.is_empty():
		var root = host._app_lifecycle_runtime().valid_control_ref(existing.get("root"))
		var group = host._app_lifecycle_runtime().valid_control_ref(existing.get("group"))
		if root != null and group != null:
			return existing
	var pop_card = host._app_lifecycle_runtime().valid_control_ref(card.get("pop"))
	if pop_card == null:
		return {}
	var skill_id = str(card.get("skill_id", host.selected_skill_id))
	var action = card.get("action", {}) as Dictionary
	var overlay = _activity_lock_overlay(pop_card, unlock_level, skill_id, _lock_requirements_for_overlay(skill_id, action))
	var action_id = str(card.get("action_id", ""))
	if action_id.is_empty():
		action_id = str(action.get("id", ""))
	_connect_activity_lock_handler(overlay, skill_id, action_id)
	card["lock_overlay"] = overlay
	return overlay


func _resolve_activity_unlock_card(skill_id: String, action_id: String) -> Dictionary:
	if skill_id.is_empty() or action_id.is_empty():
		return {}
	_ensure_detail_lazy_entry_mounted(action_id)
	if host._fishing_rework_active_for_skill(skill_id):
		var fishing_method_card = host._fishing_ui_surface()._fishing_method_card_for_action(skill_id, action_id)
		if not fishing_method_card.is_empty():
			return fishing_method_card
	var key = host._action_key(skill_id, action_id)
	if action_cards.has(key):
		var card = action_cards[key] as Dictionary
		if card != null and not card.is_empty():
			return card
	var preview_card = host._activity_unlock_ceremony_surface().activity_preview_card_for_action_id(action_id)
	if preview_card.is_empty():
		return {}
	if str(preview_card.get("skill_id", host.selected_skill_id)) != skill_id:
		return {}
	return preview_card


func _stage_unlock_preview_after_lock_click(preview_id: String) -> void:
	if host.current_screen != "skill" or preview_id.is_empty():
		return
	if _lock_click_tip_remaining_collapse_seconds() > 0.0:
		_stage_next_locked_activity_preview_after_tip_collapse(preview_id)
		return
	if host._activity_unlock_ceremony_surface().stage_next_locked_preview(false):
		host._activity_unlock_ceremony_surface().fade_staged_next_locked_preview(preview_id)


func _on_activity_lock_clicked(skill_id: String, action_id: String, group: Control) -> void:
	var action = host._action_data(skill_id, action_id)
	if action.is_empty():
		return
	var already_unlocked = host._activity_unlock_runtime()._is_action_unlocked(skill_id, action)
	if already_unlocked and not _action_has_pending_combo_requirement_lock(skill_id, action):
		return
	var card = _resolve_activity_unlock_card(skill_id, action_id)
	if _should_route_activity_unlock_to_fishing_method(card, skill_id, action_id):
		if group != null and group.has_method("consume_unlock_click"):
			group.call("consume_unlock_click")
		_hide_generic_activity_lock_overlay(card)
		host._fishing_ui_surface()._on_fishing_method_lock_pressed(skill_id, action_id)
		return
	var clicked_requirement_index = _clicked_activity_requirement_index(group)
	if clicked_requirement_index >= 0:
		var requirement_states = host._activity_unlock_runtime()._action_requirement_states(skill_id, action)
		if clicked_requirement_index < requirement_states.size():
			var clicked_state = requirement_states[clicked_requirement_index] as Dictionary
			if bool(clicked_state.get("met", false)) and not bool(clicked_state.get("dismissed", false)):
				if group != null and group.has_method("consume_unlock_click"):
					group.call("consume_unlock_click")
				host._activity_unlock_runtime().clear_pending_readiness_action(skill_id, action_id)
				host._activity_unlock_ceremony_surface().detail_refresh_done = false
				host._activity_unlock_ceremony_surface().center_scroll_target = -1
				if card.is_empty():
					card = _resolve_activity_unlock_card(skill_id, action_id)
				var final_requirement_unlock = _action_requirement_unlocks_complete_after(skill_id, action, clicked_requirement_index)
				if final_requirement_unlock:
					var preview_after_unlock = host._activity_unlock_runtime()._preview_after_manual_activity_unlock(skill_id, action_id)
					host._activity_unlock_ceremony_surface().set_preview_after_ceremony(preview_after_unlock)
					host._activity_unlock_ceremony_surface().heist_preview_after_ceremony_id = host.thieving_state.heist_revealed_by_action_unlock(skill_id, action)
					if host._activity_unlock_ceremony_surface().heist_preview_after_ceremony_id.is_empty() and not host._activity_unlock_ceremony_surface().preview_after_ceremony_id.is_empty():
						host._activity_unlock_ceremony_surface().prestage_preview_card(host._activity_unlock_ceremony_surface().preview_after_ceremony_id)
				_play_activity_requirement_lock_dismissal(card, skill_id, action, clicked_requirement_index, group, final_requirement_unlock)
				host._reward_feedback_surface()._set_result("%s unlocked." % str(action.get("name", "Activity")) if final_requirement_unlock else "%s lock opened." % SkillState.skill_name(host.skill_defs, str(clicked_state.get("skill", skill_id))))
				return
	if not host._activity_unlock_runtime()._can_unlock_action(skill_id, action):
		_pulse_missing_action_requirements(group, skill_id, action)
		if group != null and group.has_method("consume_unlock_click"):
			group.call("consume_unlock_click")
		host._reward_feedback_surface()._set_result("%s needs %s." % [str(action.get("name", "Activity")), _missing_action_requirements_text(skill_id, action)])
		return
	if group != null and group.has_method("consume_unlock_click"):
		group.call("consume_unlock_click")
	host._activity_unlock_runtime().clear_pending_readiness_action(skill_id, action_id)
	host._activity_unlock_ceremony_surface().detail_refresh_done = false
	host._activity_unlock_ceremony_surface().center_scroll_target = -1
	var ceremony_started = false
	var preview_after_unlock = host._activity_unlock_runtime()._preview_after_manual_activity_unlock(skill_id, action_id)
	if not card.is_empty() and not bool(card.get("unlock_ceremony_active", false)):
		card["unlock_ceremony_pending"] = true
		card["unlock_ceremony_finalized"] = false
		host._activity_unlock_runtime()._queue_manual_activity_unlock_for_ceremony(card, skill_id, action_id)
		card.erase("lock_overlay_sync_key")
		_sync_activity_lock_overlay(card, action, false)
		host._activity_unlock_ceremony_surface().play_ceremony(card, group)
		ceremony_started = true
	host._activity_unlock_ceremony_surface().set_preview_after_ceremony(preview_after_unlock)
	host._activity_unlock_ceremony_surface().heist_preview_after_ceremony_id = host.thieving_state.heist_revealed_by_action_unlock(skill_id, action)
	if host._activity_unlock_ceremony_surface().heist_preview_after_ceremony_id.is_empty() and not host._activity_unlock_ceremony_surface().preview_after_ceremony_id.is_empty():
		host._activity_unlock_ceremony_surface().prestage_preview_card(host._activity_unlock_ceremony_surface().preview_after_ceremony_id)
	if not ceremony_started:
		if card.is_empty():
			card = _resolve_activity_unlock_card(skill_id, action_id)
		if card.is_empty():
			host._activity_unlock_runtime()._finalize_manual_activity_unlock(skill_id, action_id)
			host.call_deferred("_refresh_skill_detail_after_activity_unlock_ceremony")
		elif not bool(card.get("unlock_ceremony_active", false)):
			card["unlock_ceremony_pending"] = true
			card["unlock_ceremony_finalized"] = false
			host._activity_unlock_runtime()._queue_manual_activity_unlock_for_ceremony(card, skill_id, action_id)
			card.erase("lock_overlay_sync_key")
			_sync_activity_lock_overlay(card, action, true)
			host._activity_unlock_ceremony_surface().play_ceremony(card, group)
			ceremony_started = true
	host._reward_feedback_surface()._set_result("%s unlocked." % str(action.get("name", "Activity")))
	if not ceremony_started:
		host._mark_save_dirty("activity unlock")


func _clicked_activity_requirement_index(group: Control) -> int:
	if group == null or not is_instance_valid(group):
		return -1
	if group.has_method("get_last_clicked_requirement_index"):
		return int(group.call("get_last_clicked_requirement_index"))
	return 0


func _should_route_activity_unlock_to_fishing_method(card: Dictionary, skill_id: String, action_id: String) -> bool:
	if not host._fishing_rework_active_for_skill(skill_id):
		return false
	if action_id.is_empty():
		return false
	if not card.is_empty() and bool(card.get("is_fishing_method", false)):
		return true
	var method_card = host._fishing_ui_surface()._fishing_method_card_for_action(skill_id, action_id)
	return not method_card.is_empty() and bool(method_card.get("is_fishing_method", false))


func _hide_generic_activity_lock_overlay(card: Dictionary) -> void:
	if card.is_empty():
		return
	var overlay = card.get("lock_overlay", {}) as Dictionary
	if overlay.is_empty():
		return
	_set_activity_lock_overlay_active(overlay, false)


func _action_requirement_unlocks_complete_after(skill_id: String, action: Dictionary, clicked_requirement_index: int) -> bool:
	var states = host._activity_unlock_runtime()._action_requirement_states(skill_id, action)
	if states.is_empty():
		return false
	for index in range(states.size()):
		var state = states[index] as Dictionary
		if not bool(state.get("met", false)):
			return false
		if index == clicked_requirement_index:
			continue
		if not bool(state.get("dismissed", false)):
			return false
	return true


func _action_has_pending_combo_requirement_lock(skill_id: String, action: Dictionary) -> bool:
	if host._activity_unlock_runtime()._action_unlock_requirements(skill_id, action).size() <= 1:
		return false
	for raw_state in host._activity_unlock_runtime()._action_requirement_states(skill_id, action):
		if typeof(raw_state) != TYPE_DICTIONARY:
			continue
		var state = raw_state as Dictionary
		if bool(state.get("met", false)) and not bool(state.get("dismissed", false)):
			return true
	return false


func _play_activity_requirement_lock_dismissal(card: Dictionary, skill_id: String, action: Dictionary, requirement_index: int, group: Control, final_requirement_unlock: bool) -> void:
	if group == null or not is_instance_valid(group) or not group.has_method("play_requirement_unlock_drop_animation"):
		return
	var action_id = str(action.get("id", ""))
	if action_id.is_empty():
		return
	card["requirement_lock_dismiss_active"] = true
	card["unlock_ready_pending"] = false
	card.erase("lock_overlay_sync_key")
	host._activity_unlock_runtime()._mark_activity_requirement_manually_unlocked(skill_id, action, requirement_index)
	host._mark_save_dirty("activity requirement unlock")
	if not final_requirement_unlock:
		host.save_game()
	var overlay = card.get("lock_overlay", {}) as Dictionary
	var overlay_root = host._app_lifecycle_runtime().valid_control_ref(overlay.get("root"))
	var shade = host._app_lifecycle_runtime().valid_canvas_item_ref(ActivityCardStyles.ensure_activity_card_shade(card, 0.50))
	var button = host._app_lifecycle_runtime().valid_button_ref(card.get("button"))
	var group_ref = host._app_lifecycle_runtime().weak_object_ref(group)
	var overlay_root_ref = host._app_lifecycle_runtime().weak_object_ref(overlay_root)
	var shade_ref = host._app_lifecycle_runtime().weak_object_ref(shade)
	var button_ref = host._app_lifecycle_runtime().weak_object_ref(button)
	if final_requirement_unlock:
		card["unlock_ceremony_pending"] = false
		card["unlock_ceremony_active"] = true
		card["unlock_ceremony_finalized"] = false
		card["unlock_ceremony_lock_rig"] = group
		card["unlock_ceremony_overlay_root"] = overlay_root
		host._activity_unlock_runtime()._queue_manual_activity_unlock_for_ceremony(card, skill_id, action_id)
		host._activity_unlock_ceremony_surface().ceremony_count += 1
		host._activity_unlock_ceremony_surface().ceremony_action_key = host._action_key(skill_id, action_id)
		var root = host._app_lifecycle_runtime().valid_control_ref(card.get("root"))
		if root != null:
			card["unlock_ceremony_original_z_index"] = root.z_index
			card["unlock_ceremony_original_clip"] = root.clip_contents
			root.z_index = 90
			root.clip_contents = false
	if overlay_root != null and is_instance_valid(overlay_root):
		overlay_root.visible = true
		overlay_root.modulate = Color.WHITE
	group.visible = true
	group.modulate = Color.WHITE
	group.set_process(true)
	if shade != null and is_instance_valid(shade):
		shade.visible = true
		shade.modulate = Color.WHITE
	host._audio_director()._play_chain_fall_sfx_sequence(group)
	group.call("play_requirement_unlock_drop_animation", requirement_index)
	await host.get_tree().create_timer(ActivityLockRig.UNLOCK_DROP_SECONDS + 0.05).timeout
	if card.is_empty():
		return
	group = host._app_lifecycle_runtime().valid_control_ref(host._app_lifecycle_runtime().weak_ref_value(group_ref))
	overlay_root = host._app_lifecycle_runtime().valid_control_ref(host._app_lifecycle_runtime().weak_ref_value(overlay_root_ref))
	shade = host._app_lifecycle_runtime().valid_canvas_item_ref(host._app_lifecycle_runtime().weak_ref_value(shade_ref))
	button = host._app_lifecycle_runtime().valid_button_ref(host._app_lifecycle_runtime().weak_ref_value(button_ref))
	if final_requirement_unlock:
		card["requirement_lock_dismiss_active"] = false
		host._activity_unlock_ceremony_surface().finish_ceremony_safe(card, overlay_root, shade, button, true)
		await host._activity_unlock_ceremony_surface().run_post_ceremony_preview(card)
		var preview_id = host._activity_unlock_ceremony_surface().preview_after_ceremony_id
		if host._activity_unlock_ceremony_surface().heist_preview_after_ceremony_id.is_empty() and not preview_id.is_empty():
			call_deferred("_stage_unlock_preview_after_lock_click", preview_id)
		return
	if group == null or group.is_queued_for_deletion():
		card["requirement_lock_dismiss_active"] = false
		card["unlock_ceremony_pending"] = false
		card["unlock_ceremony_active"] = false
		card["unlock_ceremony_finalized"] = false
		return
	if group.has_method("set_requirement_lock_gone"):
		group.call("set_requirement_lock_gone", requirement_index)
	card["requirement_lock_dismiss_active"] = false
	card["unlock_ceremony_pending"] = false
	card["unlock_ceremony_active"] = false
	card["unlock_ceremony_finalized"] = false
	card.erase("lock_overlay_sync_key")
	_sync_activity_lock_overlay(card, action, false)
	if shade != null and is_instance_valid(shade):
		shade.visible = true
		shade.modulate = Color.WHITE
	host._activity_unlock_runtime()._schedule_auto_unlock_pending_lockpads()


func _lock_click_tip_remaining_collapse_seconds() -> float:
	return maxf(0.0, float(host.lock_click_tip_collapse_until_msec - Time.get_ticks_msec()) / 1000.0)


func _stage_next_locked_activity_preview_after_tip_collapse(action_id: String) -> void:
	var delay = _lock_click_tip_remaining_collapse_seconds()
	if delay > 0.0:
		await host.get_tree().create_timer(delay).timeout
	if host.current_screen != "skill" or action_id.is_empty():
		return
	if host._activity_unlock_ceremony_surface().preview_after_ceremony_id != action_id:
		return
	if host._activity_unlock_ceremony_surface().stage_next_locked_preview(false):
		host._activity_unlock_ceremony_surface().fade_staged_next_locked_preview(action_id)


func _lock_requirements_for_overlay(skill_id: String, action: Dictionary) -> Array:
	if action.is_empty():
		return []
	var requirements = []
	for raw_requirement in host._activity_unlock_runtime()._action_unlock_requirements(skill_id, action):
		if typeof(raw_requirement) != TYPE_DICTIONARY:
			continue
		var requirement = raw_requirement as Dictionary
		var requirement_skill = str(requirement.get("skill", skill_id))
		if requirement_skill.is_empty():
			requirement_skill = skill_id
		requirements.append({
			"skill": requirement_skill,
			"level": maxi(1, int(requirement.get("level", action.get("unlock", 1)))),
			"theme_color": ThemeStyles.skill_theme_color(requirement_skill, host.COLOR_BLUE)
		})
	return requirements


func _missing_action_requirements_text(skill_id: String, action: Dictionary) -> String:
	var unmet = host._activity_unlock_runtime()._action_lock_cluster_state(skill_id, action).get("unmet", []) as Array
	var parts = []
	for raw_state in unmet:
		if typeof(raw_state) != TYPE_DICTIONARY:
			continue
		var state = raw_state as Dictionary
		var requirement_skill = str(state.get("skill", skill_id))
		var requirement_level = maxi(1, int(state.get("level", action.get("unlock", 1))))
		parts.append("%s Lv %s" % [SkillState.skill_name(host.skill_defs, requirement_skill), requirement_level])
	for raw_required_boss in host._fighting_runtime().action_missing_boss_requirements(action):
		parts.append("%s cleared" % str(raw_required_boss).capitalize())
	if parts.is_empty():
		return "%s Lv %s" % [SkillState.skill_name(host.skill_defs, skill_id), int(action.get("unlock", 1))]
	return ", ".join(parts)


func _pulse_missing_action_requirements(group: Control, skill_id: String, action: Dictionary) -> void:
	if group == null or not group.has_method("pulse_requirement_states"):
		return
	group.call("pulse_requirement_states", host._activity_unlock_runtime()._action_requirement_states(skill_id, action))


func _sync_activity_lock_overlay(card: Dictionary, action: Dictionary, unlocked: bool) -> void:
	if bool(card.get("is_fishing_area", false)) or bool(card.get("is_fishing_method", false)):
		_hide_generic_activity_lock_overlay(card)
		_reset_activity_lock_overlay_pieces(card)
		return
	var ceremony_active = (
		bool(card.get("unlock_ceremony_pending", false))
		or bool(card.get("unlock_ceremony_active", false))
	)
	_set_activity_card_locked_visual(card, (not unlocked) or ceremony_active)
	var skill_id = str(card.get("skill_id", host.selected_skill_id))
	var action_id = str(action.get("id", card.get("action_id", "")))
	var ready_pending = bool(card.get("unlock_ready_pending", false)) or host._activity_unlock_runtime()._action_has_pending_unlock_readiness(action_id)
	var lock_visible = (not unlocked) or ceremony_active
	var preview_revealing = (
		not ceremony_active
		and not ready_pending
		and lock_visible
		and bool(card.get("locked_preview_hidden", false))
	)
	var overlay = card.get("lock_overlay", {}) as Dictionary
	if overlay.is_empty():
		if not lock_visible and not preview_revealing:
			card["lock_overlay_sync_key"] = "%s:%s:%s" % [false, false, int(action.get("unlock", 1))]
			return
		overlay = _ensure_activity_lock_overlay(card, int(action.get("unlock", 1)))
		if overlay.is_empty():
			return
	var overlay_root = host._app_lifecycle_runtime().valid_control_ref(overlay.get("root"))
	if overlay_root == null:
		return
	var rig = host._app_lifecycle_runtime().valid_control_ref(overlay.get("group"))
	if (
		rig != null
		and bool(rig.get("unlock_drop_active"))
		and not (rig.has_method("set_requirement_states") and lock_visible and not ceremony_active)
	):
		return
	if ceremony_active and rig != null:
		_set_activity_lock_overlay_active(overlay, true, true)
		rig.call("set_unlock_level", int(action.get("unlock", 1)))
		rig.call("set_theme_color", ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE))
		card["lock_overlay_sync_key"] = "ceremony:%s" % int(action.get("unlock", 1))
		return
	if preview_revealing:
		_set_activity_lock_overlay_active(overlay, false)
		card["lock_overlay_sync_key"] = "preview_revealing:%s" % int(action.get("unlock", 1))
		return
	var sync_key = "%s:%s:%s:%s" % [
		lock_visible,
		ceremony_active,
		int(action.get("unlock", 1)),
		_activity_lock_requirement_sync_key(skill_id, action)
	]
	if str(card.get("lock_overlay_sync_key", "")) == sync_key:
		return
	card["lock_overlay_sync_key"] = sync_key
	_set_activity_lock_overlay_active(overlay, lock_visible)
	if rig != null:
		rig.call("set_unlock_level", int(action.get("unlock", 1)))
		rig.call("set_theme_color", ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE))
		if lock_visible and not ceremony_active and rig.has_method("set_requirement_states"):
			rig.call("set_requirement_states", host._activity_unlock_runtime()._action_requirement_states(skill_id, action))
		else:
			rig.call("set_lock_state", _activity_lock_visual_state(skill_id, action, unlocked, ceremony_active, lock_visible))


func _set_activity_card_locked_visual(card: Dictionary, locked: bool) -> void:
	var next_shade: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("shade")) as Control
	if next_shade == null and locked:
		next_shade = ActivityCardStyles.ensure_activity_card_shade(card, 0.20)
	if next_shade != null:
		next_shade.visible = locked
		next_shade.modulate = Color.WHITE


func _activity_lock_requirement_sync_key(skill_id: String, action: Dictionary) -> String:
	var parts = []
	for raw_state in host._activity_unlock_runtime()._action_requirement_states(skill_id, action):
		if typeof(raw_state) != TYPE_DICTIONARY:
			continue
		var state = raw_state as Dictionary
		parts.append("%s:%s:%s" % [
			str(state.get("skill", skill_id)),
			int(state.get("level", action.get("unlock", 1))),
			"%s:%s" % [bool(state.get("met", false)), bool(state.get("dismissed", false))]
		])
	return ",".join(parts)


func _activity_lock_visual_state(skill_id: String, action: Dictionary, unlocked: bool, ceremony_active: bool, lock_visible: bool) -> String:
	if ceremony_active:
		return ActivityLockRig.LOCK_STATE_DROPPING
	if not lock_visible:
		return ActivityLockRig.LOCK_STATE_GONE
	if (not unlocked) and host._activity_unlock_runtime()._can_unlock_action(skill_id, action):
		return ActivityLockRig.LOCK_STATE_READY_OPEN
	return ActivityLockRig.LOCK_STATE_CLOSED


func _set_activity_lock_overlay_active(overlay: Dictionary, active: bool, skip_rig_reset = false) -> void:
	var overlay_root = host._app_lifecycle_runtime().valid_control_ref(overlay.get("root"))
	if overlay_root != null:
		overlay_root.visible = active
		overlay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rig = host._app_lifecycle_runtime().valid_control_ref(overlay.get("group"))
	if rig != null:
		rig.visible = active
		rig.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rig.set_process(active)
		if active:
			if not skip_rig_reset and not bool(rig.get("unlock_drop_active")) and rig.has_method("reset_unlock_drop_animation"):
				rig.call("reset_unlock_drop_animation")
			rig.call_deferred("_layout_base")
		else:
			if rig.has_method("set_lock_state"):
				rig.call("set_lock_state", ActivityLockRig.LOCK_STATE_GONE)


func _prepare_activity_unlock_ceremony_overlay(card: Dictionary, lock_rig: Control = null) -> void:
	var overlay = card.get("lock_overlay", {}) as Dictionary
	if overlay.is_empty():
		overlay = _ensure_activity_lock_overlay(card, int((card.get("action", {}) as Dictionary).get("unlock", 1)))
		if overlay.is_empty():
			return
	var overlay_root = host._app_lifecycle_runtime().valid_control_ref(overlay.get("root"))
	var rig = host._app_lifecycle_runtime().valid_control_ref(lock_rig) if lock_rig != null else host._app_lifecycle_runtime().valid_control_ref(overlay.get("group"))
	if overlay_root != null:
		overlay_root.visible = true
		overlay_root.modulate = Color.WHITE
	if rig != null:
		rig.visible = true
		rig.modulate = Color.WHITE
		rig.set_process(true)
		rig.call_deferred("_layout_base")
	var shade = host._app_lifecycle_runtime().valid_canvas_item_ref(ActivityCardStyles.ensure_activity_card_shade(card, 0.50))
	if shade != null:
		shade.visible = true
		shade.modulate = Color.WHITE


func _reset_activity_lock_overlay_pieces(card: Dictionary) -> void:
	var overlay = card.get("lock_overlay", {}) as Dictionary
	for key in ["group"]:
		var piece = host._app_lifecycle_runtime().valid_control_ref(overlay.get(key))
		if piece == null:
			continue
		piece.visible = true
		piece.modulate = Color.WHITE
		piece.scale = Vector2.ONE
		piece.rotation = 0.0
		piece.pivot_offset = piece.size * 0.5
		if piece.has_method("reset_unlock_drop_animation"):
			piece.call("reset_unlock_drop_animation")

func _sync_activity_stat_popup(card: Dictionary, skill_id: String, action: Dictionary, _unlocked: bool, _delta: float, instant: bool) -> void:
	var action_id = str(action.get("id", ""))
	var key = str(card.get("card_key", host._action_key(skill_id, action_id)))
	var stat_kind = expanded_activity_stat_kind if expanded_activity_stat_key == key else ""
	var expanded = not stat_kind.is_empty()
	var root = card.get("root") as Control
	var visual_key = "%s:%s" % [stat_kind, ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE).to_html(true)]
	if (
		not instant
		and not expanded
		and not _action_info_chips_blocked_by_lock(card)
		and str(card.get("stat_popup_visual_key", "")) == visual_key
		and not bool(card.get("bonus_expanded", false))
		and not card.has("bonus_tween")
		and not card.has("bonus_content_tween")
	):
		return
	if _action_info_chips_blocked_by_lock(card):
		if expanded_activity_stat_key == key:
			expanded_activity_stat_key = ""
			expanded_activity_stat_kind = ""
		_sync_activity_stat_box_styles(card, "")
		_set_activity_card_expanded(card, card.get("root") as Control, false, instant)
		return
	if str(card.get("stat_popup_visual_key", "")) != visual_key:
		card["stat_popup_visual_key"] = visual_key
		var bg = card.get("bg") as RoundedTextureRect
		if bg != null:
			bg.art_height = host.ACTION_CARD_HEIGHT
			bg.feather_height = 170.0
			bg.fallback_color = ThemeStyles.activity_card_fill_color(ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE))
			bg._update_mask_params()
		var border = card.get("border") as ActivityCardBorder
		if border != null:
			border.border_color = host.COLOR_INK
			border.border_width = ActivityCardStyles.ACTION_CARD_STROKE_WIDTH
			border.queue_redraw()
		_sync_activity_stat_box_styles(card, stat_kind)
	if expanded:
		if _ensure_activity_stat_bonus_panel(card).is_empty():
			return
		var displayed_stat_kind = str(card.get("bonus_displayed_stat_kind", ""))
		var pending_stat_kind = str(card.get("bonus_pending_stat_kind", ""))
		if pending_stat_kind == stat_kind and card.has("bonus_content_tween"):
			_set_activity_card_expanded(card, root, expanded, instant)
			return
		if displayed_stat_kind != stat_kind:
			_transition_activity_stat_bonus_panel(card, skill_id, action, stat_kind, instant or displayed_stat_kind.is_empty())
		elif not card.has("bonus_content_tween"):
			_update_activity_stat_bonus_panel(card, skill_id, action, stat_kind)
	else:
		card.erase("bonus_displayed_stat_kind")
		card.erase("bonus_pending_stat_kind")
	_set_activity_card_expanded(card, root, expanded, instant)


func _sync_activity_stat_box_styles(card: Dictionary, active_kind: String) -> void:
	var boxes = card.get("stat_boxes", {}) as Dictionary
	for kind in boxes.keys():
		var box = boxes[kind] as Control
		if box == null:
			continue
		var active = str(kind) == active_kind
		if bool(box.get_meta("stat_box_style_active", false)) == active:
			continue
		box.set_meta("stat_box_style_active", active)
		_apply_action_stat_box_style(box, active)


func _set_activity_card_expanded(card: Dictionary, root: Control, expanded: bool, instant: bool) -> void:
	if root == null:
		return
	var entry = card.get("entry") as Control
	if bool(card.get("locked_preview_hidden", false)):
		host._app_lifecycle_runtime()._kill_card_tween(card, "bonus_tween")
		card["bonus_expanded"] = false
		host._app_lifecycle_runtime().set_control_minimum_height(root, 0.0)
		if entry != null and is_instance_valid(entry):
			host._app_lifecycle_runtime().set_control_minimum_height(entry, 0.0)
		root.visible = true
		root.modulate = Color(1, 1, 1, 0)
		root.clip_contents = true
		return
	if bool(root.get_meta("module_ui_collapsed_squeeze", false)):
		var collapsed_height = _module_collapsed_squeeze_height()
		var mat_collection = card.get("mat_collection", {}) as Dictionary
		var mat_collection_height = host._material_collection_surface().visible_collection_height(mat_collection)
		_set_module_root_layout_height(root, collapsed_height)
		root.clip_contents = false
		_set_collapsed_module_visual_clipping(root, str(root.get_meta("module_ui_key", "")), true)
		host._material_collection_surface()._sync_mat_collection_row_position(card, collapsed_height)
		if entry != null and is_instance_valid(entry):
			_set_module_root_layout_height(entry, collapsed_height + mat_collection_height)
			_update_detail_lazy_entry_height_for_card(card, collapsed_height + mat_collection_height)
		host._app_lifecycle_runtime()._kill_card_tween(card, "bonus_tween")
		card["bonus_expanded"] = false
		return
	var action = card.get("action", {}) as Dictionary
	var uses_diamond_arena: bool = bool(host._fighting_runtime().action_uses_diamond_combat_arena(action))
	var depth_offset_y: float = host.ACTION_CARD_3D_DEPTH_OFFSET.y if uses_diamond_arena else ActivityCardStyles.NORMAL_ACTIVITY_CARD_DEPTH_OFFSET.y
	var target_height = ActivityCardStyles.root_height_for_action(action, expanded, uses_diamond_arena, host.ACTION_CARD_HEIGHT, host.ACTION_CARD_EXPANDED_HEIGHT, host.COMBAT_DIAMOND_ARENA_CARD_HEIGHT, depth_offset_y)
	var mat_collection = card.get("mat_collection", {}) as Dictionary
	var mat_collection_height = host._material_collection_surface().visible_collection_height(mat_collection)
	var target_entry_height = target_height + mat_collection_height
	host._material_collection_surface()._sync_mat_collection_row_position(card, target_height)
	var target_size = Vector2(root.custom_minimum_size.x, target_height)
	var target_entry_size = Vector2(target_size.x, target_entry_height)
	if entry != null and is_instance_valid(entry):
		target_entry_size.x = entry.custom_minimum_size.x
	var bonus = card.get("bonus_panel", {}) as Dictionary
	var bonus_root = bonus.get("root") as Control
	var state_changed = bool(card.get("bonus_expanded", false)) != expanded
	card["bonus_expanded"] = expanded
	var entry_at_height = entry == null or not is_instance_valid(entry) or absf(entry.custom_minimum_size.y - target_entry_height) <= 0.5
	if not state_changed and absf(root.custom_minimum_size.y - target_height) <= 0.5 and entry_at_height:
		return
	host._app_lifecycle_runtime()._kill_card_tween(card, "bonus_tween")
	if bonus_root != null:
		bonus_root.visible = true
	if instant:
		root.custom_minimum_size = target_size
		if entry != null and is_instance_valid(entry):
			entry.custom_minimum_size = target_entry_size
		_update_detail_lazy_entry_height_for_card(card, target_entry_height)
		if bonus_root != null:
			bonus_root.modulate.a = 1.0 if expanded else 0.0
			bonus_root.visible = expanded
		return
	var tween = host.create_tween()
	card["bonus_tween"] = tween
	tween.set_parallel(true)
	tween.tween_property(root, "custom_minimum_size", target_size, host.ACTION_CARD_INFO_EXPAND_SECONDS).set_trans(Tween.TRANS_BACK if expanded else Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if entry != null and is_instance_valid(entry):
		tween.tween_property(entry, "custom_minimum_size", target_entry_size, host.ACTION_CARD_INFO_EXPAND_SECONDS).set_trans(Tween.TRANS_BACK if expanded else Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var bonus_root_id = bonus_root.get_instance_id() if bonus_root != null else 0
	if bonus_root != null:
		var fade_seconds = host.ACTION_CARD_INFO_FADE_IN_SECONDS if expanded else host.ACTION_CARD_INFO_FADE_OUT_SECONDS
		tween.tween_property(bonus_root, "modulate:a", 1.0 if expanded else 0.0, fade_seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_finish_activity_card_expanded.bind(str(card.get("card_key", "")), bonus_root_id, expanded))
	tween.finished.connect(_update_detail_lazy_entry_height_for_card.bind(card, target_entry_height))


func _update_detail_lazy_entry_height_for_card(card: Dictionary, height: float) -> void:
	var action_id := str(card.get("action_id", ""))
	if action_id.is_empty():
		return
	var lazy_entry: Dictionary = _detail_lazy_entry_for_track_id(action_id)
	if not lazy_entry.is_empty():
		lazy_entry["height"] = maxf(1.0, height)


func _finish_activity_card_expanded(card_key: String, bonus_root_id: int, expanded: bool) -> void:
	if bonus_root_id != 0 and not expanded:
		var cb_bonus_root = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(bonus_root_id))
		if cb_bonus_root != null:
			cb_bonus_root.visible = false
	var card = host.action_cards.get(card_key, {}) as Dictionary
	if not card.is_empty():
		card.erase("bonus_tween")


func _update_activity_stat_bonus_panel(card: Dictionary, skill_id: String, action: Dictionary, stat_kind: String) -> void:
	var bonus = card.get("bonus_panel", {}) as Dictionary
	if bonus.is_empty():
		return
	var title = bonus.get("title") as Label
	var original = bonus.get("original") as Label
	var current = bonus.get("current") as Label
	var bonuses = bonus.get("bonuses") as Label
	var details = _activity_stat_bonus_details(skill_id, action, stat_kind)
	host._app_lifecycle_runtime().set_label_text_if_changed(title, str(details.get("title", "")))
	host._app_lifecycle_runtime().set_label_text_if_changed(original, "Base: %s" % str(details.get("original", "")))
	host._app_lifecycle_runtime().set_label_text_if_changed(current, "Now: %s" % str(details.get("current", "")))
	var bonus_lines = details.get("bonuses", []) as Array
	host._app_lifecycle_runtime().set_label_text_if_changed(bonuses, "Boosts\n%s" % _format_activity_bonus_lines(bonus_lines))


func _transition_activity_stat_bonus_panel(card: Dictionary, skill_id: String, action: Dictionary, stat_kind: String, instant: bool) -> void:
	var bonus = card.get("bonus_panel", {}) as Dictionary
	var bonus_root = bonus.get("root") as Control
	host._app_lifecycle_runtime()._kill_card_tween(card, "bonus_content_tween")
	card["bonus_pending_stat_kind"] = stat_kind
	if instant or bonus_root == null or not bonus_root.visible or bonus_root.modulate.a <= 0.05:
		_update_activity_stat_bonus_panel(card, skill_id, action, stat_kind)
		card["bonus_displayed_stat_kind"] = stat_kind
		card.erase("bonus_pending_stat_kind")
		return
	var tween = host.create_tween()
	card["bonus_content_tween"] = tween
	var card_key = str(card.get("card_key", ""))
	var action_id = str(action.get("id", card.get("action_id", "")))
	tween.tween_property(bonus_root, "modulate:a", 0.0, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_swap_activity_stat_bonus_panel.bind(card_key, skill_id, action_id, stat_kind))
	tween.tween_property(bonus_root, "modulate:a", 1.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_finish_activity_stat_bonus_panel_transition.bind(card_key))


func _swap_activity_stat_bonus_panel(card_key: String, skill_id: String, action_id: String, stat_kind: String) -> void:
	var card = host.action_cards.get(card_key, {}) as Dictionary
	var action = host._action_data(skill_id, action_id)
	if card.is_empty() or action.is_empty():
		return
	_update_activity_stat_bonus_panel(card, skill_id, action, stat_kind)
	card["bonus_displayed_stat_kind"] = stat_kind


func _finish_activity_stat_bonus_panel_transition(card_key: String) -> void:
	var card = host.action_cards.get(card_key, {}) as Dictionary
	if card.is_empty():
		return
	card.erase("bonus_content_tween")
	card.erase("bonus_pending_stat_kind")


func _format_activity_bonus_lines(lines: Array) -> String:
	var packed = PackedStringArray()
	for line in lines:
		packed.append(str(line))
	if packed.is_empty():
		packed.append("None active")
	return "\n".join(packed)


func _format_xp_reward_parts(parts: Array, use_full_names := false) -> String:
	var packed := PackedStringArray()
	for raw_part in parts:
		if typeof(raw_part) != TYPE_DICTIONARY:
			continue
		var part := raw_part as Dictionary
		var reward_skill_id := str(part.get("skill", ""))
		var label: String = SkillState.skill_name(host.skill_defs, reward_skill_id) if use_full_names else SkillState.skill_short_code(host.skill_defs, reward_skill_id)
		packed.append("+%s %s" % [GameFormatting.info_chip_number(float(part.get("amount", 0))), label])
	if packed.is_empty():
		packed.append("+0 XP")
	return " / ".join(packed)


func _activity_xp_bonus_lines_for_rewards(owner_skill_id: String, action: Dictionary) -> Array:
	var lines := []
	var rewards: Dictionary = host._action_runtime()._base_xp_reward_map(action, owner_skill_id)
	var medal_xp := AchievementState.global_medal_bonus(host, "xp_mult")
	var ad_xp: float = host._ad_bonus_runtime().xp_multiplier()
	if medal_xp > 0.0:
		lines.append("+%s%% global medal XP" % GameFormatting.percent_points(medal_xp * 100.0))
	if ad_xp > 0.0:
		lines.append("+%s%% ad XP" % GameFormatting.percent_points(ad_xp * 100.0))
	for raw_reward_skill_id in host._action_runtime()._ordered_xp_reward_skill_ids(owner_skill_id, rewards):
		var reward_skill_id := str(raw_reward_skill_id)
		var achievement_xp := AchievementState.reward_bonus(AchievementState.milestones(host), "xp_mult", reward_skill_id)
		if achievement_xp > 0.0:
			lines.append("+%s%% %s achievement XP" % [GameFormatting.percent_points(achievement_xp * 100.0), SkillState.skill_name(host.skill_defs, reward_skill_id)])
	if rewards.has(owner_skill_id) and host._passive_modules_runtime().plank_bonus_applies(owner_skill_id):
		lines.append("+5% plank build XP")
	if rewards.has(owner_skill_id) and host._hub_runtime().mission_bonus_applies(owner_skill_id, action):
		lines.append("+%s%% mission board XP" % GameFormatting.percent_points(host._hub_runtime().mission_xp_bonus() * 100.0))
	if lines.is_empty():
		lines.append("None active")
	return lines


func _activity_stat_bonus_details(skill_id: String, action: Dictionary, stat_kind: String) -> Dictionary:
	match stat_kind:
		"xp":
			var base_parts = host._action_runtime()._base_xp_reward_parts_for_display(skill_id, action)
			var current_parts = host._action_runtime()._action_xp_reward_parts_for_display(skill_id, action)
			return {
				"title": "XP REWARDS" if current_parts.size() > 1 else "XP",
				"original": _format_xp_reward_parts(base_parts, true),
				"current": _format_xp_reward_parts(current_parts, true),
				"bonuses": _activity_xp_bonus_lines_for_rewards(skill_id, action)
			}
		"stamina":
			var base_stamina = maxi(1, int(action.get("stamina", 1)))
			var stamina_lines = []
			var medal_reduction = AchievementState.activity_medal_stamina_cost_reduction(host, skill_id, action)
			if medal_reduction > 0.0:
				stamina_lines.append_array(AchievementState.activity_medal_buff_lines(host, skill_id, action, "stamina", "-"))
			var tier_stamina = AchievementState.activity_tier_stamina_cost_reduction(host, skill_id, action)
			if tier_stamina > 0.0:
				stamina_lines.append("-%s%% tier medal support" % GameFormatting.percent_points(tier_stamina * 100.0))
			if host._hub_runtime().mission_bonus_applies(skill_id, action):
				stamina_lines.append("-%s%% mission board stamina" % GameFormatting.percent_points(host._hub_runtime().mission_stamina_reduction() * 100.0))
			if stamina_lines.is_empty():
				stamina_lines.append("None active")
			return {
				"title": "STAMINA COST",
				"original": "%s STAM" % GameFormatting.stamina_cost_detail(float(base_stamina)),
				"current": "%s STAM" % GameFormatting.stamina_cost_detail(host._action_runtime()._effective_stamina(skill_id, action)),
				"bonuses": stamina_lines
			}
		"time":
			if host._action_runtime()._fishing_batch_soak_active(skill_id):
				var batch_lines = ["Fish enter the net in batches, then the full net hauls at 10+ fish."]
				var batch_medal_time = AchievementState.activity_medal_time_reduction(host, skill_id, action)
				if batch_medal_time > 0.0:
					batch_lines.append_array(AchievementState.activity_medal_buff_lines(host, skill_id, action, "time", "-"))
				var batch_tier_time = AchievementState.activity_tier_time_reduction(host, skill_id, action)
				if batch_tier_time > 0.0:
					batch_lines.append("-%s%% tier medal support" % GameFormatting.percent_points(batch_tier_time * 100.0))
				return {
					"title": "FILL",
					"original": "%ss" % GameFormatting.significant_digits(float(action.get("seconds", 1.0))),
					"current": "%ss" % GameFormatting.significant_digits(host._action_runtime()._action_cycle_seconds(skill_id, action)),
					"bonuses": batch_lines
				}
			var base_seconds = maxf(0.1, float(action.get("seconds", 1.0)))
			var time_lines = []
			var medal_speed = AchievementState.global_medal_bonus(host, "speed_mult")
			var achievement_speed = AchievementState.reward_bonus(AchievementState.milestones(host), "speed_mult", skill_id)
			var ad_speed = host._ad_bonus_runtime().speed_multiplier()
			var activity_medal_speed = AchievementState.activity_medal_time_reduction(host, skill_id, action)
			var activity_tier_speed = AchievementState.activity_tier_time_reduction(host, skill_id, action)
			if medal_speed > 0.0:
				time_lines.append("-%s%% global medal speed" % GameFormatting.percent_points(medal_speed * 100.0))
			if achievement_speed > 0.0:
				time_lines.append("-%s%% achievement speed" % GameFormatting.percent_points(achievement_speed * 100.0))
			if activity_medal_speed > 0.0:
				time_lines.append_array(AchievementState.activity_medal_buff_lines(host, skill_id, action, "time", "-"))
			if activity_tier_speed > 0.0:
				time_lines.append("-%s%% tier medal support" % GameFormatting.percent_points(activity_tier_speed * 100.0))
			if ad_speed > 0.0:
				time_lines.append("-%s%% ad speed" % GameFormatting.percent_points(ad_speed * 100.0))
			if host._hub_runtime().mission_bonus_applies(skill_id, action):
				time_lines.append("-%s%% mission board speed" % GameFormatting.percent_points(host._hub_runtime().mission_time_reduction() * 100.0))
			if time_lines.is_empty():
				time_lines.append("None active")
			return {
				"title": "TIME",
				"original": "%ss" % GameFormatting.significant_digits(base_seconds),
				"current": "%ss" % GameFormatting.significant_digits(host._action_runtime()._action_cycle_seconds(skill_id, action)),
				"bonuses": time_lines
			}
		"success":
			var base_success = clampf(float(action.get("success", 90.0)), 5.0, 100.0)
			var success_lines = []
			var medal_success = AchievementState.global_medal_bonus(host, "success_bonus")
			var achievement_success = AchievementState.reward_bonus(AchievementState.milestones(host), "success_bonus", skill_id)
			if medal_success > 0.0:
				success_lines.append("+%s%% global medal success" % GameFormatting.percent_points(medal_success))
			if achievement_success > 0.0:
				success_lines.append("+%s%% achievement success" % GameFormatting.percent_points(achievement_success))
			var action_id = str(action.get("id", ""))
			var medal_level = MasteryState.level(host.mastery, host._action_key(skill_id, action_id))
			if medal_level > 0:
				success_lines.append("+%s%% %s medal" % [GameFormatting.percent_points(float(medal_level)), MasteryState.medal_name(medal_level)])
			var activity_medal_accuracy = AchievementState.activity_medal_accuracy_bonus(host, skill_id, action)
			if activity_medal_accuracy > 0.0:
				success_lines.append_array(AchievementState.activity_medal_buff_lines(host, skill_id, action, "accuracy", "+"))
			var tier_accuracy = AchievementState.activity_tier_accuracy_bonus(host, skill_id, action)
			if tier_accuracy > 0.0:
				success_lines.append("+%s%% tier medal support" % GameFormatting.percent_points(tier_accuracy))
			if not host._fishing_rework_active_for_skill(skill_id):
				var success_before_barn = clampf(base_success + medal_success + achievement_success + float(medal_level) + activity_medal_accuracy + tier_accuracy, 5.0, 100.0)
				var barn_bonus = (100.0 - success_before_barn) * host._hub_surface()._hub_barn_failure_factor()
				if barn_bonus > 0.0:
					success_lines.append("+%s%% Barn reliability" % GameFormatting.percent_points(barn_bonus))
				var trophy_success = host._hub_runtime().trophy_success_bonus() * 100.0
				if trophy_success > 0.0:
					success_lines.append("+%s%% Trophy display" % GameFormatting.percent_points(trophy_success))
			if host._action_runtime()._success_chance(skill_id, action) >= 100.0:
				success_lines.append("RATE maxed at 100%")
			if success_lines.is_empty():
				success_lines.append("None active")
			return {
				"title": "RATE",
				"original": "%s%%" % GameFormatting.percent_points(base_success),
				"current": "%s%%" % GameFormatting.percent_points(host._action_runtime()._success_chance(skill_id, action)),
				"bonuses": success_lines
			}
	return {"title": "", "original": "", "current": "", "bonuses": []}


func _activity_stat_bonus_panel() -> Dictionary:
	var root = HBoxContainer.new()
	root.custom_minimum_size = Vector2(0, 520)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 40)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.modulate.a = 0.0
	root.visible = false
	var values = VBoxContainer.new()
	values.custom_minimum_size = Vector2(820, 0)
	values.add_theme_constant_override("separation", 8)
	values.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(values)
	var title = _activity_bonus_label("", 120)
	values.add_child(title)
	var original = _activity_bonus_label("", 104)
	values.add_child(original)
	var current = _activity_bonus_label("", 104)
	values.add_child(current)
	var bonus_column = VBoxContainer.new()
	bonus_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bonus_column.add_theme_constant_override("separation", 8)
	bonus_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bonus_column)
	var bonuses = _activity_bonus_label("", 104)
	bonuses.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bonuses.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bonuses.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bonus_column.add_child(bonuses)
	return {
		"root": root,
		"title": title,
		"original": original,
		"current": current,
		"bonuses": bonuses
	}


func _ensure_activity_stat_bonus_panel(card: Dictionary) -> Dictionary:
	var existing = card.get("bonus_panel", {}) as Dictionary
	if not existing.is_empty():
		var root = host._app_lifecycle_runtime().valid_control_ref(existing.get("root"))
		if root != null:
			return existing
	var parent = card.get("bonus_parent") as Control
	if parent == null or not is_instance_valid(parent):
		return {}
	var bonus = _activity_stat_bonus_panel()
	parent.add_child(bonus["root"] as Control)
	card["bonus_panel"] = bonus
	return bonus


func _activity_bonus_label(text: String, font_size: int) -> Label:
	var label = host._label(text, font_size, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_outline_color", host.COLOR_INK)
	label.add_theme_constant_override("outline_size", maxi(12, int(round(float(font_size) * 0.30))))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _tier_banner_key(skill_id: String, tier: int) -> String:
	return "tier:%s:%s" % [skill_id, tier]


func _tier_banner_height(tier_key: String) -> float:
	return 1720.0 if expanded_tier_banner_key == tier_key else 560.0


func _toggle_tier_banner(skill_id: String, tier: int) -> void:
	var key := _tier_banner_key(skill_id, tier)
	expanded_tier_banner_key = "" if expanded_tier_banner_key == key else key
	var opening := expanded_tier_banner_key == key
	_clear_activity_stat_popup()
	var restore_scroll := -1
	if detail_actions_scroll != null and is_instance_valid(detail_actions_scroll):
		restore_scroll = int(round(detail_actions_scroll.drag_scroll_position))
		if opening:
			restore_scroll += 620
	call_deferred("_refresh_visible_skill_detail_action_list", restore_scroll, skill_id, false, true)


func _build_tier_banner(skill_id: String, tier: int, content_width: float) -> Control:
	var key := _tier_banner_key(skill_id, tier)
	var expanded := expanded_tier_banner_key == key
	var counts := AchievementState.tier_medal_counts(host, skill_id, tier)
	var counts_signature := "%s|%s|%s" % [int(counts.get("earned", 0)), int(counts.get("possible", 0)), str(counts.get("tiers", []))]
	var root := Control.new()
	root.set_meta("detail_lazy_tier_banner", true)
	root.set_meta("tier_banner_counts_signature", counts_signature)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	root.custom_minimum_size = Vector2(content_width, _tier_banner_height(key))
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var plaque := TierPlaque.new()
	plaque.tier = tier
	plaque.custom_minimum_size = Vector2(content_width, 560.0)
	plaque.set_anchors_preset(Control.PRESET_TOP_WIDE)
	plaque.offset_left = 0.0
	plaque.offset_right = 0.0
	plaque.offset_top = 0.0
	plaque.offset_bottom = 560.0
	plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(plaque)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_TOP_WIDE)
	margin.offset_left = 0.0
	margin.offset_right = 0.0
	margin.offset_top = 0.0
	margin.offset_bottom = 560.0
	margin.add_theme_constant_override("margin_left", 180)
	margin.add_theme_constant_override("margin_right", 180)
	margin.add_theme_constant_override("margin_top", 190)
	margin.add_theme_constant_override("margin_bottom", 30)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 16)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(stack)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(header)
	var title: Label = host._label("TIER %s" % tier, 162 + mini(tier, 4) * 4, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_theme_color_override("font_outline_color", COLOR_INK)
	title.add_theme_constant_override("outline_size", 44)
	if host.app_bold_font != null:
		title.add_theme_font_override("font", host.app_bold_font)
	header.add_child(title)
	root.add_child(_tier_banner_hit_button(Vector2(0.0, 0.0), Vector2(content_width, 560.0), Callable(self, "_toggle_tier_banner").bind(skill_id, tier), "tier_banner_plaque_hit"))
	if expanded:
		_add_tier_banner_expanded_menu(root, skill_id, tier, counts)
	return root


func _refresh_mounted_tier_banners() -> void:
	if host.current_screen != "skill" or expanded_tier_banner_key.is_empty():
		return
	var content_width: float = float(host._skill_content_width())
	for raw_entry in detail_lazy_plan:
		var lazy_entry := raw_entry as Dictionary
		if str(lazy_entry.get("kind", "")) != "tier_banner" or not bool(lazy_entry.get("mounted", false)):
			continue
		var stack_host: Control = host._app_lifecycle_runtime().valid_control_ref(lazy_entry.get("stack_host"))
		if stack_host == null:
			continue
		var old_banner: Control = null
		for raw_child in stack_host.get_children():
			var child := raw_child as Control
			if child != null and bool(child.get_meta("detail_lazy_tier_banner", false)):
				old_banner = child
				break
		if old_banner == null:
			continue
		var entry_data: Dictionary = lazy_entry.get("entry", {}) as Dictionary
		var skill_id := str(entry_data.get("skill_id", selected_skill_id))
		var tier := int(entry_data.get("tier", 1))
		var counts := AchievementState.tier_medal_counts(host, skill_id, tier)
		var counts_signature := "%s|%s|%s" % [int(counts.get("earned", 0)), int(counts.get("possible", 0)), str(counts.get("tiers", []))]
		if str(old_banner.get_meta("tier_banner_counts_signature", "")) == counts_signature:
			continue
		stack_host.remove_child(old_banner)
		old_banner.queue_free()
		_detail_lazy_add_child_to_host(stack_host, _build_tier_banner(skill_id, tier, content_width), content_width, content_width)


func _tier_banner_hit_button(position: Vector2, hit_size: Vector2, callback: Callable, meta_key: String) -> Button:
	var button := Button.new()
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	button.offset_left = position.x
	button.offset_top = position.y
	button.offset_right = position.x + hit_size.x
	button.offset_bottom = position.y + hit_size.y
	button.size = hit_size
	button.custom_minimum_size = hit_size
	button.z_index = 100
	button.set_meta(meta_key, true)
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.pressed.connect(callback)
	return button


func _add_tier_banner_expanded_menu(root: Control, skill_id: String, tier: int, counts: Dictionary) -> void:
	var panel_position := Vector2(86.0, 560.0)
	var panel_size := Vector2(maxf(1.0, root.custom_minimum_size.x - 172.0), _tier_banner_height(_tier_banner_key(skill_id, tier)) - 560.0)
	root.add_child(_tier_banner_hit_button(panel_position, panel_size, Callable(self, "_toggle_tier_banner").bind(skill_id, tier), "tier_banner_panel_hit"))
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.offset_left = 86.0
	panel.offset_right = -86.0
	panel.offset_top = 560.0
	panel.offset_bottom = _tier_banner_height(_tier_banner_key(skill_id, tier))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.z_index = 10
	panel.add_theme_stylebox_override("panel", _tier_banner_expanded_menu_style())
	root.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 50)
	margin.add_theme_constant_override("margin_right", 50)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 18)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(stack)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(header)
	var left_spacer := Control.new()
	left_spacer.custom_minimum_size = Vector2(78, 78)
	left_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(left_spacer)
	var earned_medals := int(counts.get("earned", 0))
	var possible_medals := int(counts.get("possible", 0))
	var completion := 0.0 if possible_medals <= 0 else float(earned_medals) / float(possible_medals) * 100.0
	var summary: Label = host._label("Tier %s mastery: %s / %s medals" % [tier, earned_medals, possible_medals], 62, COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(summary)
	header.add_child(_skill_header_info_button(
		"Tier Medal Support",
		"Earn Bronze, Silver, and Gold on every activity in this tier to unlock the listed Tier %s bonuses." % (tier + 1)
	))
	stack.add_child(_tier_banner_progress_bar(earned_medals, possible_medals, Color("#dc8b32"), "%s%%" % GameFormatting.percent_points(completion), 78.0))
	_add_tier_banner_expanded_content(stack, skill_id, tier)


func _tier_banner_expanded_menu_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color.TRANSPARENT
	style.border_width_left = 0
	style.border_width_right = 0
	style.border_width_top = 0
	style.border_width_bottom = 0
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 26
	style.corner_radius_bottom_right = 26
	style.shadow_color = Color.TRANSPARENT
	style.shadow_size = 0
	return style


func _add_tier_banner_expanded_content(stack: VBoxContainer, skill_id: String, tier: int) -> void:
	for raw_goal in AchievementState.tier_support_goals(host, skill_id, tier):
		stack.add_child(_tier_banner_goal_card(raw_goal as Dictionary, tier))


func _tier_banner_goal_card(goal: Dictionary, tier: int) -> Control:
	var medal_level := int(goal.get("medal_level", 1))
	var earned := int(goal.get("earned", 0))
	var possible := int(goal.get("possible", 0))
	var completed := earned >= possible and possible > 0
	var medal_color := MasteryState.MEDAL_ACCENTS[clampi(medal_level, 1, MasteryState.MEDAL_ACCENTS.size()) - 1] as Color
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 260)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", _tier_banner_goal_card_style(medal_color, completed))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 22)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)
	var medal_stack := VBoxContainer.new()
	medal_stack.custom_minimum_size = Vector2(230, 0)
	medal_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	medal_stack.add_theme_constant_override("separation", -8)
	medal_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(medal_stack)
	var medal_source := load(str(AchievementPresentation.MASTERY_MEDAL_TEXTURES[clampi(medal_level - 1, 0, AchievementPresentation.MASTERY_MEDAL_TEXTURES.size() - 1)])) as Texture2D
	var medal_texture := AtlasTexture.new()
	medal_texture.atlas = medal_source
	medal_texture.region = Rect2(168, 168, 432, 432)
	var medal := TextureRect.new()
	medal.texture = medal_texture
	medal.custom_minimum_size = Vector2(168, 168)
	medal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	medal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	medal.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	medal.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	medal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	medal_stack.add_child(medal)
	var medal_name: Label = host._label(str(goal.get("medal", "Medal")), 52, COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	medal_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	medal_stack.add_child(medal_name)
	var progress_stack := VBoxContainer.new()
	progress_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	progress_stack.add_theme_constant_override("separation", 14)
	progress_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(progress_stack)
	var requirement: Label = host._label("%s on every Tier %s activity" % [str(goal.get("medal", "Medal")), tier], 48, COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	requirement.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	requirement.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_stack.add_child(requirement)
	var progress_text := "%s / %s  COMPLETE" % [earned, possible] if completed else "%s / %s" % [earned, possible]
	progress_stack.add_child(_tier_banner_progress_bar(earned, possible, medal_color, progress_text, 104.0))
	row.add_child(_tier_banner_reward_chip(str(goal.get("reward_text", "")), medal_color))
	return card


func _tier_banner_progress_bar(earned: int, possible: int, accent: Color, text: String, height: float) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(0, height)
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pct := clampf(float(earned) / float(maxi(1, possible)) * 100.0, 0.0, 100.0)
	var bar := ThemeStyles.progress_bar(accent.lightened(0.08), int(height), pct)
	bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar.offset_left = 0
	bar.offset_right = 0
	bar.offset_top = 0
	bar.offset_bottom = 0
	bar.track_color = accent.darkened(0.55)
	bar.border_color = COLOR_INK
	bar.border_width = 12.0
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(bar)
	var label: Label = host._label(text, 58, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_outline_color", COLOR_INK)
	label.add_theme_constant_override("outline_size", 16)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 2
	holder.add_child(label)
	return holder


func _tier_banner_reward_chip(reward_text: String, accent: Color) -> Control:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(430, 210)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = accent.darkened(0.10)
	style.border_color = COLOR_INK
	style.set_border_width_all(10)
	style.set_corner_radius_all(42)
	style.shadow_color = Color(0, 0, 0, 0.24)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 8)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 14
	style.content_margin_bottom = 16
	chip.add_theme_stylebox_override("panel", style)
	var reward := VBoxContainer.new()
	reward.alignment = BoxContainer.ALIGNMENT_CENTER
	reward.add_theme_constant_override("separation", -4)
	reward.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(reward)
	var reward_header: Label = host._label("REWARD", 48, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	reward_header.add_theme_color_override("font_outline_color", COLOR_INK)
	reward_header.add_theme_constant_override("outline_size", 12)
	reward_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward.add_child(reward_header)
	var parts := reward_text.split(" ", false, 1)
	var main_text := str(parts[0]) if parts.size() > 0 else reward_text
	var detail_text := str(parts[1]) if parts.size() > 1 else ""
	var main: Label = host._label(main_text, 72, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	main.add_theme_color_override("font_outline_color", COLOR_INK)
	main.add_theme_constant_override("outline_size", 16)
	main.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward.add_child(main)
	if not detail_text.is_empty():
		var detail: Label = host._label(detail_text, 48, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
		detail.add_theme_color_override("font_outline_color", COLOR_INK)
		detail.add_theme_constant_override("outline_size", 10)
		detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		reward.add_child(detail)
	return chip


func _tier_banner_goal_card_style(accent: Color, completed: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fff9ed").lerp(accent, 0.22 if completed else 0.13)
	style.border_color = accent.darkened(0.24)
	style.set_border_width_all(10)
	style.set_corner_radius_all(48)
	style.shadow_color = Color(0, 0, 0, 0.20)
	style.shadow_size = 14
	style.shadow_offset = Vector2(0, 10)
	return style


func _detail_stack_entry(child: Control, child_width: float, stack_width: float) -> Control:
	if child == null or absf(stack_width - child_width) <= 0.001:
		return child
	var entry := Control.new()
	entry.set_meta("detail_stack_entry_wrapper", true)
	var child_height := child.custom_minimum_size.y
	if child_height <= 1.0:
		child_height = child.size.y
	entry.custom_minimum_size = Vector2(stack_width, maxf(1.0, child_height))
	entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry.clip_contents = false
	child.anchor_left = 0.0
	child.anchor_right = 0.0
	child.anchor_top = 0.0
	child.anchor_bottom = 0.0
	child.size = Vector2(child_width, maxf(1.0, child_height))
	child.position = Vector2((stack_width - child_width) * 0.5, 0.0)
	child.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	entry.add_child(child)
	return entry


func _detail_lazy_scroll_y() -> float:
	var scroll = host._app_lifecycle_runtime().valid_control_ref(detail_actions_scroll)
	if scroll == null:
		return 0.0
	return (scroll as ScrollContainer).drag_scroll_position if scroll is ScrollContainer else 0.0


func _detail_lazy_viewport_height() -> float:
	var scroll = host._app_lifecycle_runtime().valid_control_ref(detail_actions_scroll)
	if scroll == null:
		return 1200.0
	return maxf(maxf(scroll.size.y, scroll.custom_minimum_size.y), 800.0)


func _detail_lazy_pinned_track_ids() -> Dictionary:
	var pinned = {}
	var fishing_ui = host._fishing_ui_surface()
	if selected_skill_id != "fishing" and not fishing_ui.fishing_unlock_visible_mount_ids.is_empty():
		fishing_ui.fishing_unlock_visible_mount_ids.clear()
	if selected_skill_id != "fishing" and not fishing_ui.fishing_unlock_preview_fade_marker_ids.is_empty():
		fishing_ui.fishing_unlock_preview_fade_marker_ids.clear()
	if host.running_skill_id == selected_skill_id and not host.running_action_id.is_empty():
		pinned[host.running_action_id] = true
	var temporary_events = host._temporary_event_runtime()
	if temporary_events.event_running_skill_id == selected_skill_id and not temporary_events.event_running_action_id.is_empty():
		pinned[temporary_events.event_running_action_id] = true
	if selected_skill_id == "thieving":
		for raw_action_id in host.thieving_state.action_jails.keys():
			var jailed_action_id = str(raw_action_id)
			if jailed_action_id.is_empty() or host._thieving_surface()._thieving_action_jail_remaining(jailed_action_id) <= 0:
				continue
			pinned[jailed_action_id] = true
	if not host._activity_unlock_runtime().pending_readiness_pages().is_empty():
		for raw_action_id in host._activity_unlock_runtime().pending_readiness_action_ids(selected_skill_id):
			var pending_action_id = str(raw_action_id)
			if not pending_action_id.is_empty():
				pinned[pending_action_id] = true
	if not host._activity_unlock_ceremony_surface().preview_after_ceremony_id.is_empty():
		pinned[host._activity_unlock_ceremony_surface().preview_after_ceremony_id] = true
	if not host._activity_unlock_ceremony_surface().ceremony_action_key.is_empty():
		var ceremony_parts = host._activity_unlock_ceremony_surface().ceremony_action_key.split(":")
		if ceremony_parts.size() >= 2:
			pinned[str(ceremony_parts[1])] = true
	if selected_skill_id == "fishing":
		for raw_mount_id in fishing_ui.fishing_unlock_visible_mount_ids:
			var queued_mount_id = str(raw_mount_id)
			if not queued_mount_id.is_empty():
				pinned[queued_mount_id] = true
		var next_fishing_unlock_id = host._activity_unlock_runtime()._fishing_next_visible_auto_unlock_action_id()
		if not next_fishing_unlock_id.is_empty():
			pinned[next_fishing_unlock_id] = true
	for raw_card in action_cards.values():
		if typeof(raw_card) != TYPE_DICTIONARY:
			continue
		var card = raw_card as Dictionary
		if bool(card.get("unlock_ceremony_active", false)) or bool(card.get("unlock_ceremony_pending", false)):
			var ceremony_action_id = str(card.get("action_id", ""))
			if ceremony_action_id.is_empty():
				var ceremony_action = card.get("action", {}) as Dictionary
				ceremony_action_id = str(ceremony_action.get("id", ""))
			if not ceremony_action_id.is_empty():
				pinned[ceremony_action_id] = true
	var pending_heist_key = str(host.thieving_state.pending_trophy_reward_float.get("key", "")) if not host.thieving_state.pending_trophy_reward_float.is_empty() else ""
	if pending_heist_key.begins_with("thieving_heist:"):
		pinned["heist:%s" % pending_heist_key.substr("thieving_heist:".length())] = true
	for preview_track_id in host.module_ui_runtime.preview_pinned_track_ids(selected_skill_id):
		pinned[str(preview_track_id)] = true
	var recent_track_id = host.module_ui_runtime.recent_pinned_track_id(selected_skill_id)
	if not recent_track_id.is_empty():
		pinned[recent_track_id] = true
	return pinned


func _detail_lazy_entry_is_pinned(lazy_entry: Dictionary, pinned: Dictionary) -> bool:
	var track_id = str(lazy_entry.get("track_id", ""))
	if not track_id.is_empty() and pinned.has(track_id):
		return true
	if str(lazy_entry.get("kind", "")) == "fishing_area":
		for raw_method_id in lazy_entry.get("method_ids", []) as Array:
			if pinned.has(str(raw_method_id)):
				return true
	return false


func _detail_lazy_entry_height(lazy_entry: Dictionary) -> float:
	var entry_data = lazy_entry.get("entry", {}) as Dictionary
	var action = entry_data.get("action", {}) as Dictionary
	match str(lazy_entry.get("kind", "")):
		"beta_notice":
			return BETA_NOTICE_HEIGHT
		"tier_banner":
			return float(lazy_entry.get("height", 250.0))
		"heist":
			return host._thieving_surface().card_height()
		"passive":
			return host._passive_firepit_surface()._passive_action_card_height(action)
		"fishing_area":
			return float(host.ACTION_CARD_HEIGHT)
		"fishing_offer":
			return host._fishing_ui_surface()._fishing_offer_height(str(lazy_entry.get("offer_id", "")))
		"lock_tip", "activity_start_tip", "skill_swipe_tip":
			return DETAIL_LAZY_TIP_HEIGHT
	var uses_diamond_arena: bool = bool(host._fighting_runtime().action_uses_diamond_combat_arena(action))
	var depth_offset_y: float = host.ACTION_CARD_3D_DEPTH_OFFSET.y if uses_diamond_arena else ActivityCardStyles.NORMAL_ACTIVITY_CARD_DEPTH_OFFSET.y
	return ActivityCardStyles.root_height_for_action(action, false, uses_diamond_arena, host.ACTION_CARD_HEIGHT, host.ACTION_CARD_EXPANDED_HEIGHT, host.COMBAT_DIAMOND_ARENA_CARD_HEIGHT, depth_offset_y) + host._material_collection_surface().layout_height_for_action(selected_skill_id, action, host._action_runtime()._action_has_mat_rewards(action), host.running_skill_id, host.running_action_id)


func _detail_lazy_track_id_for_entry(entry_data: Dictionary) -> String:
	if str(entry_data.get("kind", "")) == "beta_notice":
		return "beta_notice"
	if str(entry_data.get("kind", "")) == "tier_banner":
		return "tier:%s:%s" % [str(entry_data.get("skill_id", selected_skill_id)), int(entry_data.get("tier", 1))]
	if str(entry_data.get("kind", "")) == "thieving_heist":
		var heist = entry_data.get("heist", {}) as Dictionary
		return "heist:%s" % str(heist.get("id", ""))
	var action = entry_data.get("action", {}) as Dictionary
	return str(action.get("id", ""))


func _detail_lazy_viewport_buffer_px() -> float:
	if boot_detail_render_in_progress:
		return DETAIL_LAZY_BOOT_VIEWPORT_BUFFER_PX
	if host._fishing_rework_active_for_skill(selected_skill_id):
		return FISHING_DETAIL_LAZY_VIEWPORT_BUFFER_PX
	return DETAIL_LAZY_VIEWPORT_BUFFER_PX


func _detail_lazy_unmount_buffer_px() -> float:
	if host._fishing_rework_active_for_skill(selected_skill_id):
		return FISHING_DETAIL_LAZY_UNMOUNT_BUFFER_PX
	return DETAIL_LAZY_UNMOUNT_BUFFER_PX


func _detail_lazy_entry_rect_for_viewport(lazy_entry: Dictionary) -> Rect2:
	var stack_host = host._app_lifecycle_runtime().valid_control_ref(lazy_entry.get("stack_host"))
	var stack = host._app_lifecycle_runtime().valid_control_ref(detail_lazy_stack)
	if stack == null:
		stack = _detail_actions_stack()
	if stack_host != null and stack != null and is_instance_valid(stack) and stack_host.is_inside_tree():
		var actual_rect = _detail_control_rect_in_stack(stack_host, stack)
		if actual_rect.size.y > 1.0:
			return actual_rect
	var entry_y = float(lazy_entry.get("y", 0.0)) + _detail_actions_top_spacer_height()
	return Rect2(
		Vector2(0.0, entry_y),
		Vector2(host._skill_content_width(), float(lazy_entry.get("height", 0.0)))
	)


func _detail_lazy_entry_in_viewport(lazy_entry: Dictionary) -> bool:
	var stack_host = host._app_lifecycle_runtime().valid_control_ref(lazy_entry.get("stack_host"))
	if lazy_entry.has("stack_host") and stack_host == null:
		return false
	var scroll_y = _detail_lazy_scroll_y()
	var viewport_buffer = _detail_lazy_viewport_buffer_px()
	var view_top = scroll_y - viewport_buffer
	var view_bottom = scroll_y + _detail_lazy_viewport_height() + viewport_buffer
	var entry_rect = _detail_lazy_entry_rect_for_viewport(lazy_entry)
	var entry_y = entry_rect.position.y
	var entry_bottom = entry_y + entry_rect.size.y
	return entry_rect.size.y > 1.0 and entry_bottom >= view_top and entry_y <= view_bottom


func _detail_lazy_entry_in_visible_viewport(lazy_entry: Dictionary) -> bool:
	var stack_host = host._app_lifecycle_runtime().valid_control_ref(lazy_entry.get("stack_host"))
	if lazy_entry.has("stack_host") and stack_host == null:
		return false
	var scroll_y = _detail_lazy_scroll_y()
	var view_top = scroll_y
	var view_bottom = scroll_y + _detail_lazy_viewport_height()
	var entry_rect = _detail_lazy_entry_rect_for_viewport(lazy_entry)
	var entry_y = entry_rect.position.y
	var entry_bottom = entry_y + entry_rect.size.y
	return entry_rect.size.y > 1.0 and entry_bottom >= view_top and entry_y <= view_bottom


func _detail_lazy_should_mount_entry(lazy_entry: Dictionary, pinned: Dictionary, plan_index: int) -> bool:
	if bool(lazy_entry.get("mounted", false)):
		return false
	var kind = str(lazy_entry.get("kind", ""))
	var initial_force_count = _detail_lazy_initial_force_mount_count_for_skill(selected_skill_id)
	if kind in ["lock_tip", "activity_start_tip", "skill_swipe_tip"]:
		return plan_index < initial_force_count
	if _detail_lazy_entry_is_pinned(lazy_entry, pinned):
		return true
	if _detail_lazy_mount_should_wait_for_scroll(lazy_entry):
		return false
	if plan_index < initial_force_count and _detail_lazy_scroll_y() <= DETAIL_LAZY_VIEWPORT_BUFFER_PX:
		return true
	return _detail_lazy_entry_in_viewport(lazy_entry)


func _detail_lazy_mount_should_wait_for_scroll(lazy_entry: Dictionary) -> bool:
	if not detail_scroll_visual_work_this_frame:
		return false
	if not host._fishing_rework_active_for_skill(selected_skill_id):
		return false
	if lazy_entry.has("cached_root"):
		return false
	if _detail_lazy_entry_in_visible_viewport(lazy_entry):
		return false
	if detail_actions_scroll != null and is_instance_valid(detail_actions_scroll):
		var max_scroll = float(detail_actions_scroll.get_max_scroll_vertical())
		if max_scroll > 0.0 and _detail_lazy_scroll_y() >= max_scroll - 1.0:
			return false
	return str(lazy_entry.get("kind", "")) in ["action", "passive", "heist", "fishing_area", "fishing_offer"]


func _detail_lazy_should_sync_visible_window() -> bool:
	if detail_lazy_plan.is_empty() or host._app_lifecycle_runtime().valid_control_ref(detail_lazy_stack) == null:
		return false
	if detail_lazy_last_scroll < -0.5:
		return true
	var scroll_y = _detail_lazy_scroll_y()
	if absf(scroll_y - detail_lazy_last_scroll) > 8.0:
		return true
	for raw_lazy_entry in detail_lazy_plan:
		var lazy_entry = raw_lazy_entry as Dictionary
		if bool(lazy_entry.get("mounted", false)):
			continue
		if _detail_lazy_entry_in_viewport(lazy_entry):
			return true
	var pinned = _detail_lazy_pinned_track_ids()
	if pinned.is_empty():
		return false
	for raw_lazy_entry in detail_lazy_plan:
		var lazy_entry = raw_lazy_entry as Dictionary
		if bool(lazy_entry.get("mounted", false)):
			continue
		if _detail_lazy_entry_is_pinned(lazy_entry, pinned):
			return true
	return false


func _detail_lazy_slot_has_real_content(slot: Control) -> bool:
	if slot == null or not is_instance_valid(slot):
		return false
	for child in slot.get_children():
		if child == null or not is_instance_valid(child):
			continue
		if child is Control and bool(child.get_meta("detail_lazy_placeholder", false)):
			continue
		if child is CanvasItem and (child as CanvasItem).modulate.a <= 0.01:
			continue
		if child is Control:
			var child_control = child as Control
			if bool(child_control.get_meta("detail_lazy_render_culled", false)):
				return true
			if not child_control.visible or child_control.is_queued_for_deletion():
				continue
			if maxf(child_control.custom_minimum_size.y, child_control.size.y) <= 1.0:
				continue
		return true
	return false


func _detail_lazy_prepare_host_for_mount(stack_host: Control, placeholder: Control) -> void:
	if placeholder == null or not is_instance_valid(placeholder):
		return
	if stack_host != null and is_instance_valid(stack_host) and stack_host.has_meta("detail_lazy_placeholder"):
		stack_host.remove_meta("detail_lazy_placeholder")
	if placeholder == stack_host:
		if placeholder.has_meta("detail_lazy_placeholder"):
			placeholder.remove_meta("detail_lazy_placeholder")
		return
	var parent = placeholder.get_parent()
	if parent != null and is_instance_valid(parent):
		parent.remove_child(placeholder)
	placeholder.queue_free()


func _detail_lazy_add_child_to_host(stack_host: Control, child: Control, content_width: float, actions_width: float) -> void:
	if DisplayServer.get_name() == "headless":
		host.visual_texture_cache._fill_headless_null_textures(child)
	var previous_height = maxf(stack_host.custom_minimum_size.y, stack_host.size.y)
	var child_height = child.custom_minimum_size.y
	if child_height <= 1.0:
		child_height = child.size.y
	var host_height = maxf(1.0, child_height)
	stack_host.custom_minimum_size.y = host_height
	if absf(stack_host.size.y - host_height) > 0.5 or bool(stack_host.get_meta("detail_lazy_placeholder", false)):
		stack_host.size.y = host_height
	stack_host.update_minimum_size()
	if absf(actions_width - content_width) <= 0.001:
		stack_host.add_child(child)
		_play_collapsed_host_squeeze_if_needed(stack_host, child, previous_height, host_height)
		return
	child.anchor_left = 0.0
	child.anchor_right = 0.0
	child.anchor_top = 0.0
	child.anchor_bottom = 0.0
	child.size = Vector2(content_width, maxf(1.0, child_height))
	child.position = Vector2((actions_width - content_width) * 0.5, 0.0)
	child.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	stack_host.add_child(child)
	_play_collapsed_host_squeeze_if_needed(stack_host, child, previous_height, host_height)


func _detail_lazy_entry_kind(lazy_entry: Dictionary) -> String:
	return str(lazy_entry.get("kind", ""))


func _detail_lazy_kind_is_action_backed(kind: String) -> bool:
	return kind == "action" or kind == "passive"


func _detail_lazy_kind_is_fishing_module(kind: String) -> bool:
	return _detail_lazy_kind_is_action_backed(kind) or kind == "fishing_area" or kind == "fishing_offer"


func _detail_lazy_kind_is_module(kind: String) -> bool:
	return kind == "heist" or _detail_lazy_kind_is_fishing_module(kind)


func _play_detail_lazy_fade_in(target: Control) -> void:
	if target == null or not is_instance_valid(target):
		return
	_kill_detail_lazy_reveal_tween(target)
	var base_y = target.position.y
	var base_scale = target.scale
	target.set_meta("detail_lazy_reveal_base_y", base_y)
	target.set_meta("detail_lazy_reveal_base_scale", base_scale)
	target.modulate.a = 0.0
	target.position.y = base_y + DETAIL_LAZY_SLIDE_IN_OFFSET_Y
	target.pivot_offset = target.size * 0.5
	target.scale = base_scale * DETAIL_LAZY_SCALE_IN_AMOUNT
	var tween = host.create_tween()
	target.set_meta("detail_lazy_reveal_tween", tween)
	tween.set_parallel(true)
	tween.tween_property(target, "modulate:a", 1.0, DETAIL_LAZY_FADE_IN_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "position:y", base_y, DETAIL_LAZY_FADE_IN_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "scale", base_scale, DETAIL_LAZY_FADE_IN_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	tween.tween_callback(_finish_detail_lazy_reveal.bind(target.get_instance_id(), base_y, base_scale))


func _finish_detail_lazy_reveal(target_id: int, base_y: float, base_scale: Vector2) -> void:
	var target = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(target_id))
	if target == null or target.is_queued_for_deletion():
		return
	target.modulate.a = 1.0
	target.position.y = base_y
	target.scale = base_scale
	if target.has_meta("detail_lazy_reveal_tween"):
		target.remove_meta("detail_lazy_reveal_tween")
	if target.has_meta("detail_lazy_reveal_base_y"):
		target.remove_meta("detail_lazy_reveal_base_y")
	if target.has_meta("detail_lazy_reveal_base_scale"):
		target.remove_meta("detail_lazy_reveal_base_scale")


func _kill_detail_lazy_reveal_tween(target: Control) -> void:
	if target == null or not is_instance_valid(target):
		return
	host._app_lifecycle_runtime()._kill_meta_tween(target, "detail_lazy_reveal_tween")
	if target.has_meta("detail_lazy_reveal_base_y"):
		target.position.y = float(target.get_meta("detail_lazy_reveal_base_y"))
		target.remove_meta("detail_lazy_reveal_base_y")
	if target.has_meta("detail_lazy_reveal_base_scale"):
		target.scale = host._app_lifecycle_runtime().meta_vector2(target, "detail_lazy_reveal_base_scale", target.scale)
		target.remove_meta("detail_lazy_reveal_base_scale")


func _cancel_boot_detail_completion() -> void:
	host.boot_detail_completion_token += 1
	host.boot_detail_render_queue.clear()
	host.boot_detail_scroll_locked = false


func _detail_lazy_finalize_action_card(card: Dictionary, skill_id: String, action: Dictionary, action_id: String) -> void:
	_ensure_interactive_action_card_button(card, skill_id, action_id)
	host._activity_unlock_ceremony_surface().prepare_locked_activity_preview_fade(card, skill_id, action)
	host._activity_unlock_ceremony_surface().sync_locked_preview_presence(card, skill_id, action)
	if host._activity_unlock_runtime()._action_has_pending_unlock_readiness(action_id):
		card["unlock_ready_pending"] = true
		card.erase("lock_overlay_sync_key")
	if host._activity_unlock_runtime()._action_matches_pending_unlock_preview(action_id):
		if host._activity_unlock_ceremony_surface().stage_preview_once(action_id, card):
			card["fade_in_pending"] = true
	elif host._activity_unlock_ceremony_surface().preview_after_ceremony_id == action_id:
		if host._activity_unlock_ceremony_surface().stage_preview_once(action_id, card, false):
			card["fade_in_pending"] = true
	var medal = card.get("medal") as TextureRect
	host._skill_swipe_activity_surface()._update_action_card_static_state(card, skill_id, action, host._activity_unlock_runtime()._is_action_unlocked(skill_id, action))
	if skill_id == "thieving":
		host._thieving_surface()._sync_thieving_action_jail_overlay(card, action_id)
	if MasteryState.action_has_mastery(host, action):
		host._skill_swipe_activity_surface()._set_action_card_medal(card, medal, MasteryState.level(host.mastery, host._action_key(skill_id, action_id)), true)
		host._skill_swipe_activity_surface()._update_action_card_mastery_bar(card, skill_id, action_id, 0.0, true)
	var temporary_events = host._temporary_event_runtime()
	var running_here = (host.running_skill_id == skill_id and host.running_action_id == action_id) or (temporary_events.event_running_skill_id == skill_id and temporary_events.event_running_action_id == action_id)
	host._material_collection_surface()._sync_mat_collection_card(card, running_here, true)
	host._tutorial_overlay_surface()._apply_onboarding_fight_action_card_stats_visibility(card, skill_id)
	host._tutorial_overlay_surface()._schedule_activity_start_highlight_if_needed(skill_id, action_id)


func _ensure_interactive_action_card_button(card: Dictionary, skill_id: String, action_id: String) -> void:
	if card.is_empty() or skill_id.is_empty() or action_id.is_empty():
		return
	var existing = card.get("button") as Button
	if existing != null and is_instance_valid(existing):
		existing.mouse_filter = Control.MOUSE_FILTER_STOP
		return
	var pop_card = card.get("pop") as Control
	if pop_card == null or not is_instance_valid(pop_card):
		return
	host._skill_swipe_activity_surface()._attach_swipe_preview_activity_button(card, skill_id, action_id, pop_card)


func _clear_detail_lazy_cache_bin() -> void:
	_clear_detail_lazy_cached_roots()
	if detail_lazy_cache_bin != null and is_instance_valid(detail_lazy_cache_bin):
		detail_lazy_cache_bin.queue_free()
	detail_lazy_cache_bin = null


func _clear_detail_lazy_cached_roots() -> void:
	for raw_lazy_entry in detail_lazy_plan:
		var lazy_entry = raw_lazy_entry as Dictionary
		if bool(lazy_entry.get("mounted", false)):
			continue
		var cached_root = host._app_lifecycle_runtime().valid_control_ref(lazy_entry.get("cached_root"))
		if cached_root != null and not cached_root.is_queued_for_deletion():
			if cached_root.get_parent() != null:
				cached_root.queue_free()
			else:
				cached_root.free()
		lazy_entry.erase("cached_root")
		lazy_entry.erase("cached_card")


func _park_detail_lazy_cached_root(root: Control) -> void:
	if root == null or not is_instance_valid(root) or root.is_queued_for_deletion():
		return
	host._app_lifecycle_runtime().set_canvas_item_modulate_if_changed(root, Color.WHITE)
	if root.get_parent() != null:
		root.get_parent().remove_child(root)
	host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(root, false)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _discard_detail_lazy_cached_root(lazy_entry: Dictionary) -> void:
	var cached_root = host._app_lifecycle_runtime().valid_control_ref(lazy_entry.get("cached_root"))
	var stack_host = host._app_lifecycle_runtime().valid_control_ref(lazy_entry.get("stack_host"))
	if cached_root != null and cached_root != stack_host and not cached_root.is_queued_for_deletion():
		if cached_root.get_parent() != null:
			cached_root.queue_free()
		else:
			cached_root.free()
	lazy_entry.erase("cached_root")
	lazy_entry.erase("cached_card")


func _detail_lazy_build_cached_entry(
	lazy_entry: Dictionary,
	skill_id: String,
	content_width: float,
	actions_width: float
) -> bool:
	if bool(lazy_entry.get("mounted", false)) or lazy_entry.has("cached_root"):
		return false
	var kind = str(lazy_entry.get("kind", ""))
	var root: Control = null
	var cached_card = {}
	var cached_built = {}
	match kind:
		"action", "passive":
			var entry_data = lazy_entry.get("entry", {}) as Dictionary
			if host._fishing_rework_active_for_skill(skill_id):
				var action = entry_data.get("action", {}) as Dictionary
				if action.is_empty():
					return false
				if host._passive_modules_runtime().is_passive_action(action):
					var passive_built = host._passive_firepit_surface()._build_passive_module_card(skill_id, action, content_width, true)
					root = passive_built.get("root") as Control
					cached_card = passive_built.get("card", {}) as Dictionary
				else:
					var built = _build_detail_interactive_action_card(skill_id, action, content_width, actions_width)
					root = built.get("card_root") as Control
					cached_card = built.get("card", {}) as Dictionary
			else:
				var cached: Dictionary = host._skill_swipe_activity_surface()._build_swipe_preview_real_card_cache_entry(
					skill_id,
					entry_data,
					content_width,
					actions_width
				)
				root = cached.get("root") as Control
				cached_card = cached.get("card", {}) as Dictionary
		"fishing_area":
			var area_def = lazy_entry.get("area_def", {}) as Dictionary
			if area_def.is_empty():
				return false
			cached_built = host._fishing_ui_surface()._build_fishing_area_module(skill_id, area_def, content_width)
			root = cached_built.get("root") as Control
			cached_card = cached_built.get("area_card", {}) as Dictionary
		"fishing_offer":
			root = host._fishing_ui_surface()._build_fishing_offer_module(str(lazy_entry.get("offer_id", "")), content_width)
		_:
			return false
	if root == null or not is_instance_valid(root):
		return false
	_park_detail_lazy_cached_root(root)
	lazy_entry["cached_root"] = root
	if not cached_card.is_empty():
		lazy_entry["cached_card"] = cached_card
	if not cached_built.is_empty():
		lazy_entry["cached_built"] = cached_built
	return true


func _detail_lazy_entry_for_track_id(track_id: String) -> Dictionary:
	if track_id.is_empty():
		return {}
	for raw_lazy_entry in detail_lazy_plan:
		var lazy_entry = raw_lazy_entry as Dictionary
		if _detail_lazy_entry_matches_track_id(lazy_entry, track_id):
			return lazy_entry
	return {}


func _detail_lazy_entry_matches_track_id(lazy_entry: Dictionary, track_id: String) -> bool:
	if str(lazy_entry.get("track_id", "")) == track_id:
		return true
	if str(lazy_entry.get("kind", "")) == "fishing_area":
		for raw_method_id in lazy_entry.get("method_ids", []) as Array:
			if str(raw_method_id) == track_id:
				return true
	return false


func _apply_detail_lazy_entry_height(value: float, track_id: String) -> void:
	var lazy_entry = _detail_lazy_entry_for_track_id(track_id)
	if lazy_entry.is_empty():
		return
	var height = maxf(0.0, value)
	lazy_entry["height"] = height
	var placeholder = host._app_lifecycle_runtime().valid_control_ref(lazy_entry.get("placeholder"))
	if placeholder != null:
		placeholder.custom_minimum_size.y = height
		placeholder.size.y = height
		placeholder.update_minimum_size()
		var placeholder_parent = placeholder.get_parent() as Container
		if placeholder_parent != null:
			placeholder_parent.queue_sort()
	var stack_host = host._app_lifecycle_runtime().valid_control_ref(lazy_entry.get("stack_host"))
	if stack_host != null:
		stack_host.custom_minimum_size.y = height
		stack_host.size.y = height
		stack_host.update_minimum_size()
		var stack_parent = stack_host.get_parent() as Container
		if stack_parent != null:
			stack_parent.queue_sort()


func _detail_lazy_refresh_after_page_ready(expected_token = -1):
	if detail_lazy_plan.is_empty():
		return
	if expected_token >= 0 and expected_token != detail_lazy_refresh_token:
		return
	if detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll):
		return
	if detail_actions_scroll.get_child_count() <= 0:
		return
	var stack = detail_actions_scroll.get_child(0) as VBoxContainer
	if stack == null or not is_instance_valid(stack):
		return
	detail_lazy_stack = stack
	if detail_lazy_plan.is_empty():
		detail_rendered_action_ids.clear()
		detail_lazy_plan = host._fishing_ui_surface()._build_fishing_detail_lazy_plan(selected_skill_id) if host._fishing_rework_active_for_skill(selected_skill_id) else _build_detail_lazy_plan(selected_skill_id)
	var content_width = host._skill_content_width()
	_detail_lazy_rebind_plan_to_existing_stack(stack, selected_skill_id, content_width, content_width)
	await host.get_tree().process_frame
	if expected_token >= 0 and expected_token != detail_lazy_refresh_token:
		return
	if host._app_lifecycle_runtime().valid_control_ref(detail_lazy_stack) != stack or not is_instance_valid(stack):
		return
	var initial_force_count = _detail_lazy_initial_force_mount_count_for_skill(selected_skill_id)
	if host._fishing_rework_active_for_skill(selected_skill_id):
		_sync_detail_lazy_visible_cards(true, initial_force_count)
	else:
		_sync_detail_lazy_visible_cards(true, -1)
	if host._fishing_rework_active_for_skill(selected_skill_id):
		_detail_lazy_mount_initial_window_sync(true, initial_force_count)
	_queue_detail_lazy_settle_warm_mount(selected_skill_id)


func _detail_lazy_plan_and_signature_for_skill(skill_id: String) -> Dictionary:
	if host._fishing_rework_active_for_skill(skill_id):
		return {
			"plan": host._fishing_ui_surface()._build_fishing_detail_lazy_plan(skill_id),
			"signature": host._fishing_ui_surface()._fishing_detail_render_signature()
		}
	var previous_ids = detail_rendered_action_ids.duplicate()
	detail_rendered_action_ids.clear()
	var plan = _build_detail_lazy_plan(skill_id)
	var signature = detail_rendered_action_ids.duplicate()
	detail_rendered_action_ids = previous_ids
	return {
		"plan": plan,
		"signature": signature
	}


func _detail_lazy_runtime_entries_by_track_id(plan: Array) -> Dictionary:
	var lazy_entries_by_track_id = {}
	for raw_lazy_entry in plan:
		var lazy_entry = raw_lazy_entry as Dictionary
		var track_id = str(lazy_entry.get("track_id", ""))
		if not track_id.is_empty():
			lazy_entries_by_track_id[track_id] = lazy_entry
	return lazy_entries_by_track_id


func _detail_lazy_copy_runtime_entry_state(target_entry: Dictionary, source_entry: Dictionary) -> void:
	for key in [
		"stack_host",
		"placeholder",
		"direct_stack_child",
		"mounted",
		"card",
		"built",
		"cached_root",
		"cached_card"
	]:
		if source_entry.has(key):
			target_entry[key] = source_entry[key]


func _detail_lazy_stack_insert_index_for_plan_index(stack: VBoxContainer, plan_index: int) -> int:
	if stack == null or not is_instance_valid(stack):
		return 0
	var entry_index = 0
	var fallback_index = stack.get_child_count()
	for child_index in range(stack.get_child_count()):
		var child = stack.get_child(child_index)
		var control = child as Control
		if control != null and control.name == "DetailActionsBottomSpacer":
			fallback_index = child_index
			break
		if control != null and control.name == "DetailActionsTopSpacer":
			continue
		if entry_index >= plan_index:
			return child_index
		entry_index += 1
	return clampi(fallback_index, 0, stack.get_child_count())


func _detail_lazy_find_action_plan_index(plan: Array, action_id: String) -> int:
	if action_id.is_empty():
		return -1
	for index in range(plan.size()):
		var lazy_entry = plan[index] as Dictionary
		if str(lazy_entry.get("track_id", "")) != action_id:
			continue
		if str(lazy_entry.get("kind", "")) == "action":
			return index
	return -1


func _ensure_activity_unlock_preview_lazy_entry(action_id: String) -> bool:
	if action_id.is_empty():
		return false
	if not host._activity_unlock_ceremony_surface().activity_preview_card_for_action_id(action_id, false).is_empty():
		return true
	if current_screen != "skill" or selected_skill_id.is_empty():
		return false
	var stack = host._app_lifecycle_runtime().valid_control_ref(detail_lazy_stack)
	if stack == null:
		return false
	if detail_lazy_plan.is_empty() or not host._skill_swipe_activity_surface()._skill_detail_stack_has_visible_modules(stack):
		return false
	var plan_data = _detail_lazy_plan_and_signature_for_skill(selected_skill_id)
	var new_plan = plan_data.get("plan", []) as Array
	var new_signature = plan_data.get("signature", []) as Array
	var preview_index = _detail_lazy_find_action_plan_index(new_plan, action_id)
	if preview_index < 0:
		return false
	var old_entries_by_track_id = _detail_lazy_runtime_entries_by_track_id(detail_lazy_plan)
	for raw_new_entry in new_plan:
		var new_entry = raw_new_entry as Dictionary
		var track_id = str(new_entry.get("track_id", ""))
		if track_id == action_id or not old_entries_by_track_id.has(track_id):
			continue
		_detail_lazy_copy_runtime_entry_state(new_entry, old_entries_by_track_id[track_id] as Dictionary)
	var preview_entry = new_plan[preview_index] as Dictionary
	var content_width = host._skill_content_width()
	var actions_width = content_width
	var layout_snapshot = _capture_detail_module_layout_snapshot()
	_detail_lazy_create_slot_for_entry(stack, selected_skill_id, preview_entry, content_width, actions_width)
	var preview_host = host._app_lifecycle_runtime().valid_control_ref(preview_entry.get("stack_host"))
	if preview_host == null:
		return false
	var insert_index = _detail_lazy_stack_insert_index_for_plan_index(stack, preview_index)
	stack.move_child(preview_host, clampi(insert_index, 0, maxi(0, stack.get_child_count() - 1)))
	if not _detail_lazy_mount_item(preview_entry, selected_skill_id, content_width, actions_width, false):
		_detail_lazy_remove_unmounted_inserted_host(preview_entry)
		return false
	_detail_lazy_reorder_existing_hosts_for_plan(stack, new_plan, action_id)
	detail_lazy_plan = new_plan
	detail_rendered_action_ids = new_signature
	detail_lazy_last_scroll = _detail_lazy_scroll_y()
	host._skill_swipe_activity_surface()._sync_current_skill_strip_detail_refs()
	if not layout_snapshot.is_empty():
		call_deferred("_play_detail_module_layout_transition", layout_snapshot)
	return true


func _detail_lazy_primary_child_control(module_host: Control) -> Control:
	if module_host == null or not is_instance_valid(module_host):
		return null
	for child in module_host.get_children():
		var control = child as Control
		if control == null:
			continue
		if bool(control.get_meta("detail_lazy_placeholder", false)):
			continue
		return control
	return module_host


func _detail_lazy_remove_unmounted_inserted_host(inserted_entry: Dictionary) -> void:
	var track_id = str(inserted_entry.get("track_id", ""))
	if not track_id.is_empty():
		detail_action_card_nodes.erase(track_id)
		_discard_action_card_key(host._action_key(selected_skill_id, track_id))
	var stack_host = host._app_lifecycle_runtime().valid_control_ref(inserted_entry.get("stack_host"))
	if stack_host == null or not is_instance_valid(stack_host):
		return
	var parent = stack_host.get_parent()
	if parent != null and is_instance_valid(parent):
		parent.remove_child(stack_host)
	stack_host.queue_free()


func _detail_lazy_reorder_existing_hosts_for_plan(stack: VBoxContainer, plan: Array, skip_track_id: String) -> void:
	if stack == null or not is_instance_valid(stack):
		return
	for plan_index in range(plan.size()):
		var lazy_entry = plan[plan_index] as Dictionary
		if str(lazy_entry.get("track_id", "")) == skip_track_id:
			continue
		var stack_host = host._app_lifecycle_runtime().valid_control_ref(lazy_entry.get("stack_host"))
		if stack_host == null or not is_instance_valid(stack_host) or stack_host.get_parent() != stack:
			continue
		var target_index = _detail_lazy_stack_insert_index_for_plan_index(stack, plan_index)
		stack.move_child(stack_host, clampi(target_index, 0, maxi(0, stack.get_child_count() - 1)))


func _try_refresh_detail_module_order_in_place() -> bool:
	if current_screen != "skill" or selected_skill_id.is_empty():
		return false
	if host._navigation_shell().screen_render_in_progress or boot_detail_render_in_progress or host._skill_swipe_activity_surface()._skill_swipe_navigation_blocks_detail_refresh():
		return false
	if host._skill_swipe_activity_surface().skill_swipe_pending_full_finalize or host._skill_swipe_activity_surface()._skill_swipe_handoff_cover_is_opaque_cream_transition():
		return false
	var stack = detail_lazy_stack
	if stack == null or not is_instance_valid(stack):
		stack = _detail_actions_stack() as VBoxContainer
	if stack == null or not is_instance_valid(stack):
		return false
	if detail_lazy_plan.is_empty() or not host._skill_swipe_activity_surface()._skill_detail_stack_has_visible_modules(stack):
		return false
	var layout_snapshot = _capture_detail_module_layout_snapshot()
	if layout_snapshot.is_empty():
		return false
	var plan_data = _detail_lazy_plan_and_signature_for_skill(selected_skill_id)
	var new_plan = plan_data.get("plan", []) as Array
	if new_plan.is_empty():
		return false
	var new_signature = plan_data.get("signature", []) as Array
	var old_entries_by_track_id = _detail_lazy_runtime_entries_by_track_id(detail_lazy_plan)
	var new_track_ids = {}
	for raw_new_entry in new_plan:
		var new_entry = raw_new_entry as Dictionary
		var track_id = str(new_entry.get("track_id", ""))
		if track_id.is_empty():
			continue
		new_track_ids[track_id] = true
		if old_entries_by_track_id.has(track_id):
			_detail_lazy_copy_runtime_entry_state(new_entry, old_entries_by_track_id[track_id] as Dictionary)
	var content_width = host._skill_content_width()
	var actions_width = content_width
	for plan_index in range(new_plan.size()):
		var new_entry = new_plan[plan_index] as Dictionary
		var stack_host = host._app_lifecycle_runtime().valid_control_ref(new_entry.get("stack_host"))
		if stack_host != null and is_instance_valid(stack_host):
			continue
		_detail_lazy_create_slot_for_entry(stack, selected_skill_id, new_entry, content_width, actions_width)
		if _detail_lazy_should_mount_entry(new_entry, _detail_lazy_pinned_track_ids(), plan_index):
			_detail_lazy_mount_item(new_entry, selected_skill_id, content_width, actions_width, false)
	for raw_old_entry in detail_lazy_plan:
		var old_entry = raw_old_entry as Dictionary
		var old_track_id = str(old_entry.get("track_id", ""))
		if old_track_id.is_empty() or new_track_ids.has(old_track_id):
			continue
		_detail_lazy_remove_unmounted_inserted_host(old_entry)
	detail_lazy_stack = stack
	detail_lazy_plan = new_plan
	detail_rendered_action_ids = new_signature
	_detail_lazy_reorder_existing_hosts_for_plan(stack, detail_lazy_plan, "")
	detail_lazy_last_scroll = _detail_lazy_scroll_y()
	host._skill_swipe_activity_surface()._sync_current_skill_strip_detail_refs()
	call_deferred("_play_detail_module_layout_transition", layout_snapshot)
	Callable(self, "_sync_detail_actions_scroll_limit_deferred").call_deferred()
	return true


func _detail_lazy_rebind_plan_to_existing_stack(stack: VBoxContainer, skill_id: String, content_width: float, actions_width: float) -> void:
	var plan_index = 0
	for child in stack.get_children():
		if not child is Control:
			continue
		var control = child as Control
		if control.name in ["DetailActionsTopSpacer", "DetailActionsBottomSpacer"]:
			continue
		if plan_index >= detail_lazy_plan.size():
			break
		var lazy_entry = detail_lazy_plan[plan_index] as Dictionary
		lazy_entry["stack_host"] = control
		lazy_entry["direct_stack_child"] = skill_id == "thieving" and str(lazy_entry.get("kind", "")) == "heist"
		if bool(control.get_meta("detail_lazy_placeholder", false)):
			lazy_entry["mounted"] = false
			lazy_entry["placeholder"] = control
			plan_index += 1
			continue
		if _detail_lazy_slot_has_real_content(control):
			lazy_entry["mounted"] = true
			lazy_entry["placeholder"] = null
		else:
			lazy_entry["mounted"] = false
			var existing_placeholder: Control = null
			for slot_child in control.get_children():
				if slot_child is Control and bool((slot_child as Control).get_meta("detail_lazy_placeholder", false)):
					existing_placeholder = slot_child as Control
					break
			if existing_placeholder != null and is_instance_valid(existing_placeholder):
				lazy_entry["placeholder"] = existing_placeholder
			else:
				var placeholder = Control.new()
				placeholder.custom_minimum_size = Vector2(content_width, float(lazy_entry.get("height", ActivityCardStyles.root_height(false, host.ACTION_CARD_HEIGHT, host.ACTION_CARD_EXPANDED_HEIGHT, host.ACTION_CARD_3D_DEPTH_OFFSET.y))))
				placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
				placeholder.set_meta("detail_lazy_placeholder", true)
				if bool(lazy_entry.get("direct_stack_child", false)):
					placeholder.custom_minimum_size.x = actions_width
				lazy_entry["placeholder"] = placeholder
				control.add_child(placeholder)
		plan_index += 1


func _detail_lazy_initial_force_mount_count_for_skill(skill_id: String) -> int:
	if skill_id == "fishing":
		return FISHING_DETAIL_LAZY_INITIAL_FORCE_MOUNT_COUNT
	if skill_id == "woodcutting":
		return 1
	return DETAIL_LAZY_INITIAL_FORCE_MOUNT_COUNT


func _detail_lazy_idle_warm_mount_can_mount(skill_id: String, lazy_entry: Dictionary) -> bool:
	if not host._fishing_rework_active_for_skill(skill_id):
		return true
	if host.web_fishing_perf_probe_enabled:
		return true
	if host.FISHING_DETAIL_IDLE_WARM_MOUNT_MAX_ACTION_CARDS <= 0:
		return true
	var kind = str(lazy_entry.get("kind", ""))
	var card_cost = 0
	if kind == "fishing_area":
		card_cost = 1 + (lazy_entry.get("method_ids", []) as Array).size()
	elif kind in ["action", "passive", "heist"]:
		card_cost = 1
	return action_cards.size() + card_cost <= host.FISHING_DETAIL_IDLE_WARM_MOUNT_MAX_ACTION_CARDS


func _repair_blank_detail_lazy_stack() -> bool:
	if current_screen != "skill":
		return false
	if detail_lazy_plan.is_empty():
		return false
	var stack = _detail_actions_stack() as VBoxContainer
	if stack == null or not is_instance_valid(stack):
		return false
	if host._skill_swipe_activity_surface()._skill_detail_stack_has_visible_modules(stack):
		return false
	var bottom_spacer = host._app_lifecycle_runtime().valid_control_ref(detail_unlock_scroll_spacer)
	var had_bottom_spacer = bottom_spacer != null and bottom_spacer.get_parent() == stack
	if had_bottom_spacer:
		stack.remove_child(bottom_spacer)
	for child in stack.get_children():
		var control = child as Control
		if control == null:
			continue
		if control.name == "DetailActionsTopSpacer":
			continue
		stack.remove_child(control)
		control.queue_free()
	detail_lazy_stack = stack
	detail_action_card_nodes.clear()
	for raw_key in action_cards.keys():
		var key = str(raw_key)
		if key.begins_with("%s:" % selected_skill_id) or (selected_skill_id == "thieving" and key.begins_with("thieving_heist:")):
			_discard_action_card_key(key)
	detail_rendered_action_ids.clear()
	detail_lazy_plan = host._fishing_ui_surface()._build_fishing_detail_lazy_plan(selected_skill_id) if host._fishing_rework_active_for_skill(selected_skill_id) else _build_detail_lazy_plan(selected_skill_id)
	var content_width = host._skill_content_width()
	_detail_lazy_create_slots(stack, selected_skill_id, content_width, content_width)
	_detail_lazy_mount_initial_window_sync(true, _detail_lazy_initial_force_mount_count_for_skill(selected_skill_id))
	detail_lazy_last_scroll = _detail_lazy_scroll_y()
	if had_bottom_spacer and bottom_spacer != null and is_instance_valid(bottom_spacer):
		stack.add_child(bottom_spacer)
	return host._skill_swipe_activity_surface()._skill_detail_stack_has_visible_modules(stack)


func _maybe_repair_blank_detail_lazy_stack() -> void:
	if current_screen != "skill" or detail_lazy_plan.is_empty():
		return
	if host._skill_swipe_activity_surface()._skill_swipe_handoff_cover_is_opaque_cream_transition() or host._skill_swipe_activity_surface().skill_swipe_defer_initial_lazy_mount:
		return
	var now = Time.get_ticks_msec()
	if now < detail_lazy_blank_repair_next_msec:
		return
	var stack = _detail_actions_stack()
	if stack == null or not is_instance_valid(stack) or host._skill_swipe_activity_surface()._skill_detail_stack_has_visible_modules(stack):
		return
	detail_lazy_blank_repair_next_msec = now + 1000
	_repair_blank_detail_lazy_stack()


func _detail_lazy_create_slot_for_entry(
	stack: VBoxContainer,
	skill_id: String,
	lazy_entry: Dictionary,
	content_width: float,
	actions_width: float
) -> void:
	var height := float(lazy_entry.get("height", 0.0))
	var placeholder := Control.new()
	placeholder.custom_minimum_size = Vector2(content_width, height)
	placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placeholder.set_meta("detail_lazy_placeholder", true)
	var module_key: String = _detail_lazy_module_ui_key(lazy_entry, skill_id)
	if not module_key.is_empty():
		placeholder.set_meta("module_ui_key", module_key)
	lazy_entry["placeholder"] = placeholder
	if skill_id == "thieving" and str(lazy_entry.get("kind", "")) == "heist":
		placeholder.custom_minimum_size.x = actions_width
		stack.add_child(placeholder)
		lazy_entry["stack_host"] = placeholder
		lazy_entry["direct_stack_child"] = true
	else:
		var stack_entry := _detail_stack_entry(placeholder, content_width, actions_width)
		if not module_key.is_empty():
			stack_entry.set_meta("module_ui_key", module_key)
		stack.add_child(stack_entry)
		lazy_entry["stack_host"] = stack_entry


func _detail_lazy_create_slots(stack: VBoxContainer, skill_id: String, content_width: float, actions_width: float) -> void:
	for lazy_entry in detail_lazy_plan:
		_detail_lazy_create_slot_for_entry(stack, skill_id, lazy_entry as Dictionary, content_width, actions_width)


func _detail_lazy_create_slots_batched(
	stack: VBoxContainer,
	skill_id: String,
	content_width: float,
	actions_width: float,
	batch_size: int
) -> bool:
	var created_since_yield := 0
	var batch_limit := maxi(1, batch_size)
	for lazy_entry in detail_lazy_plan:
		if current_screen != "skill" or selected_skill_id != skill_id:
			return false
		if stack == null or not is_instance_valid(stack):
			return false
		_detail_lazy_create_slot_for_entry(stack, skill_id, lazy_entry as Dictionary, content_width, actions_width)
		created_since_yield += 1
		if created_since_yield >= batch_limit:
			created_since_yield = 0
			await host.get_tree().process_frame
	return true


func _detail_eager_add_to_stack(stack: VBoxContainer, node: Control) -> void:
	if stack == null or not is_instance_valid(stack) or node == null or not is_instance_valid(node):
		return
	stack.add_child(node)
	if (
		detail_unlock_scroll_spacer != null
		and is_instance_valid(detail_unlock_scroll_spacer)
		and detail_unlock_scroll_spacer.get_parent() == stack
	):
		var target_index := clampi(detail_unlock_scroll_spacer.get_index(), 0, maxi(0, stack.get_child_count() - 1))
		stack.move_child(node, target_index)


func _detail_eager_add_activity_start_tip_below_content(stack: VBoxContainer, note: Control, content_width: float, actions_width: float) -> void:
	if stack == null or not is_instance_valid(stack) or note == null or not is_instance_valid(note):
		return
	var entry: Control = _detail_stack_entry(note, content_width, actions_width)
	stack.add_child(entry)
	var insert_index := maxi(0, stack.get_child_count() - 1)
	for i in range(stack.get_child_count()):
		var child := stack.get_child(i)
		if child == entry:
			continue
		if child.name == "DetailActionsTopSpacer":
			insert_index = mini(insert_index, i + 1)
			continue
		if child.name == "DetailActionsBottomSpacer":
			insert_index = mini(insert_index, i)
			break
		insert_index = i + 1
		break
	stack.move_child(entry, clampi(insert_index, 0, maxi(0, stack.get_child_count() - 1)))


func _detail_stack_child_for_action(action_id: String) -> Control:
	var stack: VBoxContainer = _resolve_detail_lazy_stack()
	if stack == null or not is_instance_valid(stack):
		return null
	if action_id.is_empty():
		return null
	if not detail_action_card_nodes.has(action_id):
		_ensure_detail_lazy_entry_mounted(action_id)
	if not detail_action_card_nodes.has(action_id):
		return null
	var node := detail_action_card_nodes[action_id] as Control
	if node == null or not is_instance_valid(node):
		return null
	if node.get_parent() == stack:
		return node
	var parent := node.get_parent() as Control
	if parent != null and is_instance_valid(parent) and parent.get_parent() == stack:
		return parent
	return null


func _detail_eager_add_tutorial_note_after_action(action_id: String, note: Control, content_width: float, actions_width: float) -> Control:
	var stack: VBoxContainer = _resolve_detail_lazy_stack()
	if stack == null or not is_instance_valid(stack) or note == null or not is_instance_valid(note):
		return null
	var entry: Control = _detail_stack_entry(note, content_width, actions_width)
	stack.add_child(entry)
	var anchor := _detail_stack_child_for_action(action_id)
	if anchor != null and is_instance_valid(anchor) and anchor.get_parent() == stack:
		stack.move_child(entry, clampi(anchor.get_index() + 1, 0, maxi(0, stack.get_child_count() - 1)))
	elif detail_unlock_scroll_spacer != null and is_instance_valid(detail_unlock_scroll_spacer) and detail_unlock_scroll_spacer.get_parent() == stack:
		stack.move_child(entry, clampi(detail_unlock_scroll_spacer.get_index(), 0, maxi(0, stack.get_child_count() - 1)))
	return entry


func _skill_swipe_tip_anchor_track_id(skill_id: String) -> String:
	var visible_action_count := 0
	var fallback_action_id := ""
	for raw_entry in _visible_detail_entries_for_skill(skill_id):
		var entry := raw_entry as Dictionary
		if str(entry.get("kind", "")) != "action":
			continue
		var action := entry.get("action", {}) as Dictionary
		var action_id := str(action.get("id", ""))
		if action_id.is_empty():
			continue
		if skill_id == host.TUTORIAL_STARTER_SKILL_ID and action_id == host.TUTORIAL_LEVEL_TWO_ACTION_ID:
			return action_id
		visible_action_count += 1
		if visible_action_count == 2:
			fallback_action_id = action_id
	return fallback_action_id


func _detail_eager_add_smooth_tutorial_tip_after_action(action_id: String, note: Control, content_width: float, actions_width: float, group_name: String) -> Control:
	var stack: VBoxContainer = _resolve_detail_lazy_stack()
	if stack == null or not is_instance_valid(stack) or note == null or not is_instance_valid(note):
		return null
	var entry: Control = _detail_stack_entry(note, content_width, actions_width)
	if entry != note and not group_name.is_empty():
		note.remove_from_group(group_name)
		entry.add_to_group(group_name)
	stack.add_child(entry)
	var anchor := _detail_stack_child_for_action(action_id)
	if anchor != null and is_instance_valid(anchor) and anchor.get_parent() == stack:
		stack.move_child(entry, clampi(anchor.get_index() + 1, 0, maxi(0, stack.get_child_count() - 1)))
	elif detail_unlock_scroll_spacer != null and is_instance_valid(detail_unlock_scroll_spacer) and detail_unlock_scroll_spacer.get_parent() == stack:
		stack.move_child(entry, clampi(detail_unlock_scroll_spacer.get_index(), 0, maxi(0, stack.get_child_count() - 1)))
	return entry


func _detail_eager_add_skill_swipe_tip_after_anchor(stack: VBoxContainer, note: Control, content_width: float, actions_width: float) -> Control:
	if stack == null or not is_instance_valid(stack) or note == null or not is_instance_valid(note):
		return null
	var anchor_id := _skill_swipe_tip_anchor_track_id(selected_skill_id)
	if not anchor_id.is_empty():
		var anchored_entry := _detail_eager_add_smooth_tutorial_tip_after_action(anchor_id, note, content_width, actions_width, "skill_swipe_tip_notes")
		if anchored_entry != null and is_instance_valid(anchored_entry):
			return anchored_entry
	var entry: Control = _detail_stack_entry(note, content_width, actions_width)
	stack.add_child(entry)
	if detail_unlock_scroll_spacer != null and is_instance_valid(detail_unlock_scroll_spacer) and detail_unlock_scroll_spacer.get_parent() == stack:
		stack.move_child(entry, clampi(detail_unlock_scroll_spacer.get_index(), 0, maxi(0, stack.get_child_count() - 1)))
	return entry


func _detail_eager_add_smooth_tutorial_tip(stack: VBoxContainer, note: Control, content_width: float, actions_width: float, group_name: String) -> Control:
	if stack == null or not is_instance_valid(stack) or note == null or not is_instance_valid(note):
		return null
	var entry: Control = _detail_stack_entry(note, content_width, actions_width)
	if entry != note and not group_name.is_empty():
		note.remove_from_group(group_name)
		entry.add_to_group(group_name)
	_detail_eager_add_to_stack(stack, entry)
	return entry


func _finish_smooth_tutorial_tip_entry_reveal(entry_id: int) -> void:
	var entry: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(entry_id))
	if entry != null:
		entry.clip_contents = false


func _tutorial_note_is_in_stack(note: Control, stack: VBoxContainer) -> bool:
	if note == null or stack == null or not is_instance_valid(note) or not is_instance_valid(stack):
		return false
	var parent := note.get_parent() as Control
	if parent == null or not is_instance_valid(parent):
		return false
	return parent == stack or parent.get_parent() == stack


func _tutorial_note_group_has_node_in_stack(group_name: String, stack: VBoxContainer) -> bool:
	for node in host.get_tree().get_nodes_in_group(group_name):
		var note := node as Control
		if _tutorial_note_is_in_stack(note, stack):
			return true
	return false


func _append_detail_eager_trailing_tips(stack: VBoxContainer, content_width: float, actions_width: float) -> void:
	if host._onboarding_runtime().tutorial_active or host._onboarding_runtime()._onboarding_path_active():
		return
	if _activity_start_inline_tip_available(selected_skill_id):
		if _tutorial_note_group_has_node_in_stack("activity_start_tip_notes", stack):
			return
		var note: Control = host._tutorial_overlay_surface()._bottom_tutorial_tip_note(content_width, "Click an activity to start doing it.", "activity_start_tip_notes")
		_detail_eager_add_activity_start_tip_below_content(stack, note, content_width, actions_width)
		_fade_in_activity_start_tip_note(note)
	elif host._onboarding_runtime()._skill_swipe_tip_available():
		host._tutorial_overlay_surface().call_deferred("_run_onboarding_swipe_tip_sequence")


func _activity_start_inline_tip_available(skill_id: String = selected_skill_id) -> bool:
	if host._onboarding_runtime().activity_start_tip_seen:
		return false
	if not host._onboarding_runtime()._skill_detail_shows_tutorial_tips(skill_id):
		return false
	if host._onboarding_runtime()._tutorial_starter_only_detail_active(skill_id):
		return true
	if host._onboarding_runtime().tutorial_active:
		return false
	return skill_id != host.TUTORIAL_STARTER_SKILL_ID


func _fade_in_activity_start_tip_note(note: Control) -> void:
	if note == null or not is_instance_valid(note):
		return
	note.modulate = Color.WHITE


func _should_show_lock_click_tip(_skill_id: String, _action: Dictionary) -> bool:
	return false


func _should_show_passive_module_tip(skill_id: String, action: Dictionary) -> bool:
	var module_id := str(action.get("id", ""))
	return (
		not host._onboarding_runtime().passive_module_tip_seen
		and skill_id == "woodcutting"
		and module_id == PassiveModulesRuntime.WOODCUTTING_FIREPIT_MODULE_ID
		and host._passive_modules_runtime().is_passive_action(action)
		and host._passive_modules_runtime().is_passive_module_unlocked(module_id)
	)


func _build_detail_lazy_plan(skill_id: String) -> Array:
	var plan = []
	var y = 0.0
	var activity_start_tip_pending = _activity_start_inline_tip_available(skill_id)
	var skill_swipe_tip_pending = not activity_start_tip_pending and host._onboarding_runtime()._skill_swipe_tip_available()
	var skill_swipe_tip_anchor_track_id = _skill_swipe_tip_anchor_track_id(skill_id)
	for entry in _visible_detail_entries_for_skill(skill_id):
		var entry_data = entry as Dictionary
		var track_id = _detail_lazy_track_id_for_entry(entry_data)
		if not track_id.is_empty():
			detail_rendered_action_ids.append(track_id)
		var lazy_entry = {
			"kind": "action",
			"entry": entry_data,
			"track_id": track_id,
			"y": y,
			"height": 0.0,
			"mounted": false,
			"stack_host": null,
			"placeholder": null,
			"direct_stack_child": false
		}
		if str(entry_data.get("kind", "")) == "tier_banner":
			lazy_entry["kind"] = "tier_banner"
			track_id = _tier_banner_key(skill_id, int(entry_data.get("tier", 1)))
			lazy_entry["track_id"] = track_id
		elif str(entry_data.get("kind", "")) == "beta_notice":
			lazy_entry["kind"] = "beta_notice"
		elif str(entry_data.get("kind", "")) == "thieving_heist":
			lazy_entry["kind"] = "heist"
		elif host._passive_modules_runtime().is_passive_action(entry_data.get("action", {}) as Dictionary):
			lazy_entry["kind"] = "passive"
		lazy_entry["height"] = _tier_banner_height(track_id) if lazy_entry["kind"] == "tier_banner" else _detail_lazy_entry_height(lazy_entry)
		var module_key = _detail_lazy_module_ui_key(lazy_entry, skill_id)
		if not module_key.is_empty() and _module_ui_is_collapsed(module_key):
			lazy_entry["height"] = _module_collapsed_squeeze_height()
		plan.append(lazy_entry)
		y += float(lazy_entry["height"]) + DETAIL_LAZY_STACK_SEPARATION
		if activity_start_tip_pending:
			plan.append({
				"kind": "activity_start_tip",
				"entry": {},
				"track_id": "tip:activity_start",
				"y": y,
				"height": DETAIL_LAZY_TIP_HEIGHT,
				"mounted": false,
				"stack_host": null,
				"placeholder": null,
				"direct_stack_child": false
			})
			y += DETAIL_LAZY_TIP_HEIGHT + DETAIL_LAZY_STACK_SEPARATION
			activity_start_tip_pending = false
		if lazy_entry["kind"] in ["passive", "action"]:
			var action = entry_data.get("action", {}) as Dictionary
			if _should_show_lock_click_tip(skill_id, action):
				plan.append({
					"kind": "lock_tip",
					"entry": {},
					"track_id": "tip:lock:%s" % str(action.get("id", "")),
					"y": y,
					"height": DETAIL_LAZY_TIP_HEIGHT,
					"mounted": false,
					"stack_host": null,
					"placeholder": null,
					"direct_stack_child": false
				})
				y += DETAIL_LAZY_TIP_HEIGHT + DETAIL_LAZY_STACK_SEPARATION
		if skill_swipe_tip_pending and not skill_swipe_tip_anchor_track_id.is_empty() and track_id == skill_swipe_tip_anchor_track_id:
			plan.append({
				"kind": "skill_swipe_tip",
				"entry": {},
				"track_id": "tip:skill_swipe",
				"y": y,
				"height": DETAIL_LAZY_TIP_HEIGHT,
				"mounted": false,
				"stack_host": null,
				"placeholder": null,
				"direct_stack_child": false
			})
			y += DETAIL_LAZY_TIP_HEIGHT + DETAIL_LAZY_STACK_SEPARATION
			skill_swipe_tip_pending = false
	if activity_start_tip_pending:
		plan.append({
			"kind": "activity_start_tip",
			"entry": {},
			"track_id": "tip:activity_start",
			"y": y,
			"height": DETAIL_LAZY_TIP_HEIGHT,
			"mounted": false,
			"stack_host": null,
			"placeholder": null,
			"direct_stack_child": false
		})
		y += DETAIL_LAZY_TIP_HEIGHT + DETAIL_LAZY_STACK_SEPARATION
	if skill_swipe_tip_pending:
		plan.append({
			"kind": "skill_swipe_tip",
			"entry": {},
			"track_id": "tip:skill_swipe",
			"y": y,
			"height": DETAIL_LAZY_TIP_HEIGHT,
			"mounted": false,
			"stack_host": null,
			"placeholder": null,
			"direct_stack_child": false
		})
	return plan

func _detail_lazy_mount_cached_item(
	lazy_entry: Dictionary,
	skill_id: String,
	content_width: float,
	actions_width: float,
	fade_in: bool
) -> bool:
	var cached_root = host._app_lifecycle_runtime().valid_control_ref(lazy_entry.get("cached_root"))
	if cached_root == null or cached_root.is_queued_for_deletion():
		lazy_entry.erase("cached_root")
		lazy_entry.erase("cached_card")
		lazy_entry.erase("cached_built")
		return false
	var stack_host = host._app_lifecycle_runtime().valid_control_ref(lazy_entry.get("stack_host"))
	if stack_host == null or not is_instance_valid(stack_host):
		return false
	var track_id = str(lazy_entry.get("track_id", ""))
	if track_id.is_empty():
		return false
	var kind = _detail_lazy_entry_kind(lazy_entry)
	var cached_card = lazy_entry.get("cached_card", {}) as Dictionary
	if kind == "heist":
		_discard_detail_lazy_cached_root(lazy_entry)
		return false
	if bool(lazy_entry.get("direct_stack_child", false)):
		var parent = stack_host.get_parent()
		if parent == null or not is_instance_valid(parent):
			return false
		var slot_index = stack_host.get_index()
		parent.remove_child(stack_host)
		stack_host.queue_free()
		if cached_root.get_parent() != null:
			cached_root.reparent(parent, false)
		else:
			parent.add_child(cached_root)
		parent.move_child(cached_root, clampi(slot_index, 0, maxi(0, parent.get_child_count() - 1)))
		cached_root.visible = true
		host._app_lifecycle_runtime().set_canvas_item_modulate_if_changed(cached_root, Color.WHITE)
		host._skill_swipe_activity_surface()._enable_interactive_control_tree(cached_root)
		lazy_entry["stack_host"] = cached_root
		lazy_entry["placeholder"] = null
		detail_action_card_nodes[track_id] = cached_root
		lazy_entry["mounted"] = true
		host._skill_swipe_activity_surface()._mark_detail_lazy_module_mounted(cached_root)
		return true
	if kind == "fishing_area":
		var placeholder = host._app_lifecycle_runtime().valid_control_ref(lazy_entry.get("placeholder"))
		_detail_lazy_prepare_host_for_mount(stack_host, placeholder)
		lazy_entry["placeholder"] = null
		if cached_root.get_parent() != null:
			cached_root.get_parent().remove_child(cached_root)
		cached_root = _apply_lazy_entry_module_squeeze(cached_root, lazy_entry, skill_id)
		cached_root.visible = true
		host._skill_swipe_activity_surface()._enable_interactive_control_tree(cached_root)
		_detail_lazy_add_child_to_host(stack_host, cached_root, content_width, actions_width)
		var cached_built = lazy_entry.get("cached_built", {}) as Dictionary
		var area_key = track_id
		var area_card = cached_card
		if not cached_built.is_empty():
			area_key = str(cached_built.get("area_key", track_id))
			area_card = cached_built.get("area_card", cached_card) as Dictionary
			lazy_entry["built"] = cached_built
		_register_action_card(area_key, area_card)
		lazy_entry["card"] = area_card
		detail_action_card_nodes[area_key] = stack_host
		for raw_method_id in lazy_entry.get("method_ids", []) as Array:
			detail_action_card_nodes[str(raw_method_id)] = stack_host
		if fade_in:
			_play_detail_lazy_fade_in(cached_root)
		lazy_entry["mounted"] = true
		host._skill_swipe_activity_surface()._mark_detail_lazy_module_mounted(stack_host)
		return true
	if kind == "fishing_offer":
		var placeholder = host._app_lifecycle_runtime().valid_control_ref(lazy_entry.get("placeholder"))
		_detail_lazy_prepare_host_for_mount(stack_host, placeholder)
		lazy_entry["placeholder"] = null
		if cached_root.get_parent() != null:
			cached_root.get_parent().remove_child(cached_root)
		cached_root = _apply_lazy_entry_module_squeeze(cached_root, lazy_entry, skill_id)
		cached_root.visible = true
		host._skill_swipe_activity_surface()._enable_interactive_control_tree(cached_root)
		_detail_lazy_add_child_to_host(stack_host, cached_root, content_width, actions_width)
		if fade_in:
			_play_detail_lazy_fade_in(cached_root)
		lazy_entry["mounted"] = true
		host._skill_swipe_activity_surface()._mark_detail_lazy_module_mounted(stack_host)
		return true
	if not _detail_lazy_kind_is_action_backed(kind):
		return false
	var placeholder = host._app_lifecycle_runtime().valid_control_ref(lazy_entry.get("placeholder"))
	_detail_lazy_prepare_host_for_mount(stack_host, placeholder)
	lazy_entry["placeholder"] = null
	if cached_root.get_parent() != null:
		cached_root.get_parent().remove_child(cached_root)
	cached_root = _apply_lazy_entry_module_squeeze(cached_root, lazy_entry, skill_id)
	cached_root.visible = true
	host._skill_swipe_activity_surface()._enable_interactive_control_tree(cached_root)
	_detail_lazy_add_child_to_host(stack_host, cached_root, content_width, actions_width)
	if fade_in:
		_play_detail_lazy_fade_in(cached_root)
	if cached_card.is_empty():
		return false
	var action = (lazy_entry.get("entry") as Dictionary).get("action", {}) as Dictionary
	cached_card["entry"] = stack_host
	_register_action_card(host._action_key(skill_id, track_id), cached_card)
	lazy_entry["card"] = cached_card
	_detail_lazy_finalize_action_card(cached_card, skill_id, action, track_id)
	detail_action_card_nodes[track_id] = stack_host
	lazy_entry["mounted"] = true
	host._skill_swipe_activity_surface()._mark_detail_lazy_module_mounted(stack_host)
	return true

func _detail_lazy_mount_item(lazy_entry: Dictionary, skill_id: String, content_width: float, actions_width: float, fade_in: bool) -> bool:
	if bool(lazy_entry.get("mounted", false)):
		return false
	var trace_mount = OS.get_environment("IDLE_ELITE_TRACE_PROCESS_SLOW") == "1"
	var trace_mount_skill = OS.get_environment("IDLE_ELITE_TRACE_PROCESS_SKILL")
	if trace_mount and not trace_mount_skill.is_empty() and skill_id != trace_mount_skill:
		trace_mount = false
	var trace_started_usec = Time.get_ticks_usec() if trace_mount else 0
	var kind = _detail_lazy_entry_kind(lazy_entry)
	var stack_host = host._app_lifecycle_runtime().valid_control_ref(lazy_entry.get("stack_host"))
	var placeholder = host._app_lifecycle_runtime().valid_control_ref(lazy_entry.get("placeholder"))
	if stack_host == null or not is_instance_valid(stack_host):
		return false
	var track_id = str(lazy_entry.get("track_id", ""))
	if host._fishing_ui_surface()._fishing_ablation_enabled("plain_fishing_modules") and skill_id == "fishing" and _detail_lazy_kind_is_fishing_module(kind):
		return _detail_lazy_mount_plain_ablation_item(lazy_entry, content_width, actions_width)
	var fade_target: Control = null
	var fade_allowed = false
	var mounted_ok = false
	if lazy_entry.has("cached_root") and _detail_lazy_mount_cached_item(lazy_entry, skill_id, content_width, actions_width, fade_in):
		if trace_mount:
			var cached_mount_us = Time.get_ticks_usec() - trace_started_usec
			if cached_mount_us >= 1500:
				print("LAZY_MOUNT_TRACE skill=%s kind=%s track=%s us=%s fade=false cached=true context=%s" % [
					skill_id,
					kind,
					track_id,
					str(cached_mount_us),
					detail_lazy_mount_trace_context
				])
		return true
	match kind:
		"beta_notice":
			var notice := _build_beta_notice_board(content_width)
			_detail_lazy_prepare_host_for_mount(stack_host, placeholder)
			lazy_entry["placeholder"] = null
			_detail_lazy_add_child_to_host(stack_host, notice, content_width, actions_width)
			fade_target = notice
			fade_allowed = true
			mounted_ok = true
		"tier_banner":
			var entry_data = lazy_entry.get("entry", {}) as Dictionary
			var banner := _build_tier_banner(skill_id, int(entry_data.get("tier", 1)), content_width)
			_detail_lazy_prepare_host_for_mount(stack_host, placeholder)
			lazy_entry["placeholder"] = null
			_detail_lazy_add_child_to_host(stack_host, banner, content_width, actions_width)
			fade_target = banner
			fade_allowed = true
			mounted_ok = true
		"heist":
			var heist = (lazy_entry.get("entry") as Dictionary).get("heist", {}) as Dictionary
			var heist_root = host._thieving_surface()._build_thieving_heist_card(heist, actions_width)
			heist_root = _apply_lazy_entry_module_squeeze(heist_root, lazy_entry, skill_id)
			var parent = stack_host.get_parent()
			var slot_index = stack_host.get_index()
			if parent != null and is_instance_valid(parent):
				parent.remove_child(stack_host)
				stack_host.queue_free()
				parent.add_child(heist_root)
				parent.move_child(heist_root, slot_index)
				lazy_entry["stack_host"] = heist_root
				lazy_entry["placeholder"] = null
				detail_action_card_nodes[track_id] = heist_root
				fade_target = heist_root
				fade_allowed = true
				mounted_ok = true
		"passive":
			var action = (lazy_entry.get("entry") as Dictionary).get("action", {}) as Dictionary
			var defer_passive_loot = skill_swipe_pending_full_finalize or host._skill_swipe_activity_surface()._skill_swipe_handoff_cover_is_opaque_cream_transition()
			var passive_card = host._passive_firepit_surface()._build_passive_module_card(skill_id, action, content_width, true, defer_passive_loot)
			var passive_root = passive_card["root"] as Control
			passive_root = _apply_lazy_entry_module_squeeze(passive_root, lazy_entry, skill_id)
			_detail_lazy_prepare_host_for_mount(stack_host, placeholder)
			lazy_entry["placeholder"] = null
			_detail_lazy_add_child_to_host(stack_host, passive_root, content_width, actions_width)
			var card = passive_card["card"] as Dictionary
			card["entry"] = stack_host
			_register_action_card(host._action_key(skill_id, track_id), card)
			lazy_entry["card"] = card
			_detail_lazy_finalize_action_card(card, skill_id, action, track_id)
			detail_action_card_nodes[track_id] = stack_host
			fade_target = passive_root
			fade_allowed = not action.is_empty() and host._activity_unlock_runtime()._is_action_unlocked(skill_id, action)
			mounted_ok = true
		"action":
			var action = (lazy_entry.get("entry") as Dictionary).get("action", {}) as Dictionary
			var built = _build_detail_interactive_action_card(skill_id, action, content_width, actions_width)
			var card_root = built["card_root"] as Control
			card_root = _apply_lazy_entry_module_squeeze(card_root, lazy_entry, skill_id)
			_detail_lazy_prepare_host_for_mount(stack_host, placeholder)
			lazy_entry["placeholder"] = null
			_detail_lazy_add_child_to_host(stack_host, card_root, content_width, actions_width)
			var card = built["card"] as Dictionary
			card["entry"] = stack_host
			_register_action_card(host._action_key(skill_id, track_id), card)
			lazy_entry["card"] = card
			_detail_lazy_finalize_action_card(card, skill_id, action, track_id)
			detail_action_card_nodes[track_id] = stack_host
			fade_target = card_root
			fade_allowed = not action.is_empty() and host._activity_unlock_runtime()._is_action_unlocked(skill_id, action)
			mounted_ok = true
		"fishing_area":
			var area_def = lazy_entry.get("area_def", {}) as Dictionary
			if not area_def.is_empty():
				var built = host._fishing_ui_surface()._build_fishing_area_module(skill_id, area_def, content_width)
				var root = built.get("root") as Control
				if root != null and is_instance_valid(root):
					root = _apply_lazy_entry_module_squeeze(root, lazy_entry, skill_id)
					_detail_lazy_prepare_host_for_mount(stack_host, placeholder)
					lazy_entry["placeholder"] = null
					_detail_lazy_add_child_to_host(stack_host, root, content_width, actions_width)
					var area_key = str(built.get("area_key", track_id))
					var area_card = built.get("area_card", {}) as Dictionary
					_register_action_card(area_key, area_card)
					lazy_entry["card"] = area_card
					lazy_entry["built"] = built
					detail_action_card_nodes[area_key] = stack_host
					for raw_method_id in built.get("method_ids", []) as Array:
						detail_action_card_nodes[str(raw_method_id)] = stack_host
					fade_target = root
					fade_allowed = true
					mounted_ok = true
		"fishing_offer":
			var offer_root = host._fishing_ui_surface()._build_fishing_offer_module(str(lazy_entry.get("offer_id", "")), content_width)
			if offer_root != null and is_instance_valid(offer_root):
				offer_root.set_meta("detail_lazy_track_id", track_id)
				offer_root = _apply_lazy_entry_module_squeeze(offer_root, lazy_entry, skill_id)
				_detail_lazy_prepare_host_for_mount(stack_host, placeholder)
				lazy_entry["placeholder"] = null
				_detail_lazy_add_child_to_host(stack_host, offer_root, content_width, actions_width)
				fade_target = offer_root
				fade_allowed = true
				mounted_ok = true
		"lock_tip":
			_detail_lazy_prepare_host_for_mount(stack_host, placeholder)
			lazy_entry["placeholder"] = null
			_detail_lazy_add_child_to_host(stack_host, host._tutorial_overlay_surface()._bottom_tutorial_tip_note(content_width, "Tap to unlock", "lock_click_tip_notes"), content_width, actions_width)
			mounted_ok = true
		"activity_start_tip":
			_detail_lazy_prepare_host_for_mount(stack_host, placeholder)
			lazy_entry["placeholder"] = null
			var start_note = host._tutorial_overlay_surface()._bottom_tutorial_tip_note(content_width, "Click an activity to start doing it.", "activity_start_tip_notes")
			_detail_lazy_add_child_to_host(stack_host, start_note, content_width, actions_width)
			_fade_in_activity_start_tip_note(start_note)
			mounted_ok = true
		"skill_swipe_tip":
			_detail_lazy_prepare_host_for_mount(stack_host, placeholder)
			lazy_entry["placeholder"] = null
			var swipe_note = host._tutorial_overlay_surface()._bottom_tutorial_tip_note(content_width, "Some activities require multiple skills.\nSwipe left or right to see other skills.", "skill_swipe_tip_notes")
			swipe_note.modulate = Color(1, 1, 1, 0)
			_detail_lazy_add_child_to_host(stack_host, swipe_note, content_width, actions_width)
			host._tutorial_overlay_surface().call_deferred("_fade_in_skill_swipe_tip_note", swipe_note)
			mounted_ok = true
	if not mounted_ok:
		return false
	lazy_entry["mounted"] = true
	host._skill_swipe_activity_surface()._mark_detail_lazy_module_mounted(host._app_lifecycle_runtime().valid_control_ref(lazy_entry.get("stack_host")))
	if fade_in and fade_allowed and fade_target != null and not boot_detail_render_in_progress:
		_play_detail_lazy_fade_in(fade_target)
	if trace_mount:
		var mount_us = Time.get_ticks_usec() - trace_started_usec
		if mount_us >= 1500:
			print("LAZY_MOUNT_TRACE skill=%s kind=%s track=%s us=%s fade=%s context=%s" % [
				skill_id,
				kind,
				track_id,
				str(mount_us),
				str(fade_in),
				detail_lazy_mount_trace_context
			])
	return true

func _detail_lazy_mount_plain_ablation_item(lazy_entry: Dictionary, content_width: float, actions_width: float) -> bool:
	var stack_host = host._app_lifecycle_runtime().valid_control_ref(lazy_entry.get("stack_host"))
	if stack_host == null or not is_instance_valid(stack_host):
		return false
	var placeholder = host._app_lifecycle_runtime().valid_control_ref(lazy_entry.get("placeholder"))
	var kind = _detail_lazy_entry_kind(lazy_entry)
	var track_id = str(lazy_entry.get("track_id", ""))
	var module_height = maxf(120.0, float(lazy_entry.get("height", 420.0)))
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(actions_width, module_height)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", host._surface_style(Color("#fff6e1"), 16, 8, false))
	var label = host._label("%s %s" % [kind, track_id], 48, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(actions_width, module_height)
	panel.add_child(label)
	_detail_lazy_prepare_host_for_mount(stack_host, placeholder)
	lazy_entry["placeholder"] = null
	_detail_lazy_add_child_to_host(stack_host, panel, content_width, actions_width)
	lazy_entry["mounted"] = true
	host._skill_swipe_activity_surface()._mark_detail_lazy_module_mounted(stack_host)
	if not track_id.is_empty():
		detail_action_card_nodes[track_id] = stack_host
	return true

func _sync_detail_lazy_visible_cards(instant: bool, max_mounts: int = -1) -> int:
	if detail_lazy_plan.is_empty() or host._app_lifecycle_runtime().valid_control_ref(detail_lazy_stack) == null or host._app_lifecycle_runtime().valid_control_ref(detail_actions_scroll) == null:
		return 0
	var pinned = _detail_lazy_pinned_track_ids()
	var content_width = host._skill_content_width()
	var actions_width = content_width
	var mounted_count = 0
	var previous_mount_context = detail_lazy_mount_trace_context
	detail_lazy_mount_trace_context = "visible_window_sync"
	for plan_index in range(detail_lazy_plan.size()):
		var lazy_entry = detail_lazy_plan[plan_index] as Dictionary
		var cached_visible_fishing_entry = (
			host._fishing_rework_active_for_skill(selected_skill_id)
			and detail_scroll_visual_work_this_frame
			and lazy_entry.has("cached_root")
			and _detail_lazy_entry_in_viewport(lazy_entry)
		)
		if max_mounts >= 0 and mounted_count >= max_mounts and not cached_visible_fishing_entry:
			continue
		if not _detail_lazy_should_mount_entry(lazy_entry, pinned, plan_index):
			continue
		var had_cached_root = lazy_entry.has("cached_root")
		var fade_in = (not instant) and not detail_scroll_visual_work_this_frame
		if _detail_lazy_mount_item(lazy_entry, selected_skill_id, content_width, actions_width, fade_in):
			if not (cached_visible_fishing_entry and had_cached_root):
				mounted_count += 1
	detail_lazy_mount_trace_context = previous_mount_context
	detail_lazy_last_scroll = _detail_lazy_scroll_y()
	return mounted_count

func _sync_detail_lazy_next_cards(instant: bool, max_mounts: int = 1) -> int:
	if detail_lazy_plan.is_empty() or host._app_lifecycle_runtime().valid_control_ref(detail_lazy_stack) == null or host._app_lifecycle_runtime().valid_control_ref(detail_actions_scroll) == null:
		return 0
	if max_mounts == 0:
		return 0
	var content_width = host._skill_content_width()
	var actions_width = content_width
	var mounted_count = 0
	for raw_lazy_entry in detail_lazy_plan:
		if max_mounts >= 0 and mounted_count >= max_mounts:
			break
		var lazy_entry = raw_lazy_entry as Dictionary
		if bool(lazy_entry.get("mounted", false)):
			continue
		if _detail_lazy_mount_item(lazy_entry, selected_skill_id, content_width, actions_width, not instant):
			mounted_count += 1
	return mounted_count


func _schedule_proxy_skill_detail_full_refresh(skill_id: String) -> void:
	if skill_id.is_empty():
		return
	call_deferred("_proxy_skill_detail_full_refresh_after_frames", skill_id, host.main_process_frame_index + host.SKILL_SWIPE_PROXY_FULL_REFRESH_DELAY_FRAMES)


func _proxy_skill_detail_full_refresh_after_frames(skill_id: String, ready_frame: int) -> void:
	while host.main_process_frame_index < ready_frame:
		if host.current_screen != "skill" or host.selected_skill_id != skill_id:
			return
		await host.get_tree().process_frame
	if host.current_screen != "skill" or host.selected_skill_id != skill_id:
		return
	if host._skill_swipe_activity_surface().skill_swipe_tracking or host._skill_swipe_activity_surface().skill_swipe_animating or host._skill_swipe_activity_surface().skill_swipe_pending_full_finalize:
		call_deferred("_proxy_skill_detail_full_refresh_after_frames", skill_id, host.main_process_frame_index + 60)
		return
	_refresh_visible_skill_detail_action_list(-1, skill_id, true)


func _detail_lazy_entry_far_from_viewport(lazy_entry: Dictionary) -> bool:
	var scroll_y = _detail_lazy_scroll_y()
	var unmount_buffer = _detail_lazy_unmount_buffer_px()
	var view_top = scroll_y - unmount_buffer
	var view_bottom = scroll_y + _detail_lazy_viewport_height() + unmount_buffer
	var entry_rect = _detail_lazy_entry_rect_for_viewport(lazy_entry)
	var entry_y = entry_rect.position.y
	var entry_bottom = entry_y + entry_rect.size.y
	return entry_rect.size.y > 1.0 and (entry_bottom < view_top or entry_y > view_bottom)

func _detail_lazy_can_unmount_entry(lazy_entry: Dictionary, pinned: Dictionary) -> bool:
	if not bool(lazy_entry.get("mounted", false)):
		return false
	var kind = _detail_lazy_entry_kind(lazy_entry)
	if not _detail_lazy_kind_is_module(kind):
		return false
	var track_id = str(lazy_entry.get("track_id", ""))
	if track_id.is_empty() or _detail_lazy_entry_is_pinned(lazy_entry, pinned):
		return false
	return _detail_lazy_entry_far_from_viewport(lazy_entry)

func _detail_lazy_unmount_item(lazy_entry: Dictionary, skill_id: String, content_width: float) -> bool:
	var stack_host = host._app_lifecycle_runtime().valid_control_ref(lazy_entry.get("stack_host"))
	if stack_host == null or not is_instance_valid(stack_host):
		return false
	var track_id = str(lazy_entry.get("track_id", ""))
	if track_id.is_empty():
		return false
	var kind = _detail_lazy_entry_kind(lazy_entry)
	var mounted_card = lazy_entry.get("card", {}) as Dictionary
	host._app_lifecycle_runtime()._kill_transient_tweens_in_subtree(stack_host)
	if DisplayServer.get_name() == "headless":
		host.visual_texture_cache._fill_headless_null_textures(stack_host)
	var cached_root: Control = null
	var should_cache_unmounted_root = not host._fishing_rework_active_for_skill(skill_id)
	if should_cache_unmounted_root and _detail_lazy_kind_is_fishing_module(kind):
		for child in stack_host.get_children():
			var child_control = child as Control
			if child_control == null or bool(child_control.get_meta("detail_lazy_placeholder", false)):
				continue
			cached_root = child_control
			break
		if cached_root != null and is_instance_valid(cached_root):
			_park_detail_lazy_cached_root(cached_root)
			lazy_entry["cached_root"] = cached_root
			lazy_entry["cached_card"] = mounted_card
			if kind == "fishing_area":
				lazy_entry["cached_built"] = lazy_entry.get("built", {}) as Dictionary
	elif kind == "heist":
		lazy_entry.erase("cached_root")
		lazy_entry.erase("cached_card")
		lazy_entry.erase("cached_built")
	if not should_cache_unmounted_root:
		lazy_entry.erase("cached_root")
		lazy_entry.erase("cached_card")
		lazy_entry.erase("cached_built")
	for child in stack_host.get_children():
		if child != null and is_instance_valid(child) and child != cached_root:
			child.queue_free()
	var placeholder = Control.new()
	placeholder.custom_minimum_size = Vector2(content_width, float(lazy_entry.get("height", ActivityCardStyles.root_height(false, host.ACTION_CARD_HEIGHT, host.ACTION_CARD_EXPANDED_HEIGHT, host.ACTION_CARD_3D_DEPTH_OFFSET.y))))
	placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placeholder.set_meta("detail_lazy_placeholder", true)
	if bool(lazy_entry.get("direct_stack_child", false)):
		var parent = stack_host.get_parent()
		if parent == null or not is_instance_valid(parent):
			placeholder.queue_free()
			return false
		var slot_index = stack_host.get_index()
		parent.remove_child(stack_host)
		if cached_root == stack_host:
			_park_detail_lazy_cached_root(cached_root)
		if cached_root != stack_host:
			stack_host.queue_free()
		parent.add_child(placeholder)
		parent.move_child(placeholder, slot_index)
		lazy_entry["stack_host"] = placeholder
	else:
		stack_host.add_child(placeholder)
		stack_host.set_meta("detail_lazy_placeholder", true)
	lazy_entry["placeholder"] = placeholder
	lazy_entry["mounted"] = false
	if cached_root == null:
		lazy_entry.erase("built")
		lazy_entry.erase("cached_built")
	if kind == "fishing_area":
		detail_action_card_nodes.erase(track_id)
		for raw_method_id in lazy_entry.get("method_ids", []) as Array:
			detail_action_card_nodes.erase(str(raw_method_id))
		host._fishing_ui_surface()._discard_fishing_area_module_card_keys(track_id, mounted_card, skill_id)
	elif kind != "fishing_offer":
		detail_action_card_nodes.erase(track_id)
		var card_key = host._thieving_surface()._thieving_heist_card_key(track_id.substr("heist:".length())) if track_id.begins_with("heist:") else host._action_key(skill_id, track_id)
		_discard_action_card_key(card_key)
	lazy_entry.erase("card")
	return true

func _prune_detail_lazy_far_cards(max_unmounts: int = 2) -> int:
	if not DETAIL_LAZY_UNMOUNT_ENABLED:
		return 0
	if detail_lazy_plan.is_empty() or host._app_lifecycle_runtime().valid_control_ref(detail_lazy_stack) == null or boot_detail_render_in_progress:
		return 0
	if not module_ui_pending_pin_scroll_anchor.is_empty():
		return 0
	if not host.module_ui_runtime.recent_pinned_track_id(selected_skill_id).is_empty():
		return 0
	var pinned = _detail_lazy_pinned_track_ids()
	var content_width = host._skill_content_width()
	var unmounted_count = 0
	for raw_lazy_entry in detail_lazy_plan:
		if max_unmounts >= 0 and unmounted_count >= max_unmounts:
			break
		var lazy_entry = raw_lazy_entry as Dictionary
		if not _detail_lazy_can_unmount_entry(lazy_entry, pinned):
			continue
		if _detail_lazy_unmount_item(lazy_entry, selected_skill_id, content_width):
			unmounted_count += 1
	return unmounted_count

func _detail_lazy_mount_all_sync(instant := true) -> int:
	var mounted_count = 0
	for plan_index in range(detail_lazy_plan.size()):
		var lazy_entry = detail_lazy_plan[plan_index] as Dictionary
		if bool(lazy_entry.get("mounted", false)):
			continue
		var content_width = host._skill_content_width()
		var actions_width = content_width
		if _detail_lazy_mount_item(lazy_entry, selected_skill_id, content_width, actions_width, not instant):
			mounted_count += 1
	return mounted_count

func _detail_lazy_mount_thieving_heists_sync(instant := true) -> int:
	if selected_skill_id != "thieving":
		return 0
	var mounted_count := 0
	var content_width: float = host._skill_content_width()
	var actions_width: float = content_width
	for raw_lazy_entry in detail_lazy_plan:
		var lazy_entry := raw_lazy_entry as Dictionary
		if bool(lazy_entry.get("mounted", false)):
			continue
		if str(lazy_entry.get("kind", "")) != "heist":
			continue
		if _detail_lazy_mount_item(lazy_entry, selected_skill_id, content_width, actions_width, not instant):
			mounted_count += 1
	return mounted_count

func _detail_lazy_all_mounted() -> bool:
	var current_frame := Engine.get_process_frames()
	if detail_lazy_all_mounted_cache_frame == current_frame:
		return detail_lazy_all_mounted_cache_value
	detail_lazy_all_mounted_cache_frame = current_frame
	detail_lazy_all_mounted_cache_value = true
	for raw_lazy_entry in detail_lazy_plan:
		var lazy_entry := raw_lazy_entry as Dictionary
		if not bool(lazy_entry.get("mounted", false)):
			detail_lazy_all_mounted_cache_value = false
			break
	return detail_lazy_all_mounted_cache_value

func _detail_lazy_mount_initial_window_sync(instant := true, mount_count: int = 2) -> int:
	var target = mini(mount_count, detail_lazy_plan.size())
	var mounted_count = 0
	var pinned = _detail_lazy_pinned_track_ids()
	var previous_mount_context = detail_lazy_mount_trace_context
	detail_lazy_mount_trace_context = "initial_window_sync"
	for plan_index in range(detail_lazy_plan.size()):
		var lazy_entry = detail_lazy_plan[plan_index] as Dictionary
		if bool(lazy_entry.get("mounted", false)):
			continue
		if plan_index >= target and not _detail_lazy_entry_is_pinned(lazy_entry, pinned):
			continue
		var content_width = host._skill_content_width()
		var actions_width = content_width
		if _detail_lazy_mount_item(lazy_entry, selected_skill_id, content_width, actions_width, not instant):
			mounted_count += 1
	detail_lazy_mount_trace_context = previous_mount_context
	return mounted_count

func _new_detail_lazy_stack(actions_width: float) -> VBoxContainer:
	var stack := VBoxContainer.new()
	stack.custom_minimum_size.x = actions_width
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 56)
	return stack


func _replace_swipe_preview_stack_for_finalize(actions_scroll: MobileScrollContainer, old_stack: VBoxContainer, actions_width: float) -> VBoxContainer:
	if actions_scroll == null or not is_instance_valid(actions_scroll):
		return null
	var new_stack := _new_detail_lazy_stack(actions_width)
	var insert_index := 0
	if old_stack != null and is_instance_valid(old_stack):
		var parent := old_stack.get_parent()
		if parent != null and is_instance_valid(parent):
			insert_index = old_stack.get_index()
			parent.remove_child(old_stack)
		old_stack.visible = false
		old_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	actions_scroll.add_child(new_stack)
	actions_scroll.move_child(new_stack, clampi(insert_index, 0, maxi(0, actions_scroll.get_child_count() - 1)))
	return new_stack


func _free_retired_swipe_preview_stack_batched(stack: VBoxContainer, children: Array, start_index: int) -> void:
	if stack == null or not is_instance_valid(stack):
		return
	var end_index := mini(children.size(), start_index + maxi(1, SKILL_SWIPE_PREVIEW_FREE_BATCH_SIZE))
	for index in range(start_index, end_index):
		var child := children[index] as Node
		if child != null and is_instance_valid(child):
			child.queue_free()
	if end_index >= children.size():
		stack.queue_free()
		return
	await host.get_tree().process_frame
	call_deferred("_free_retired_swipe_preview_stack_batched", stack, children, end_index)


func _schedule_mount_swipe_finalized_lazy_cards(target_skill_id: String, token: int, mounted_total: int) -> void:
	call_deferred("_mount_swipe_finalized_lazy_cards_after_frame", target_skill_id, token, mounted_total)


func _mount_swipe_finalized_lazy_cards_after_frame(target_skill_id: String, token: int, mounted_total: int) -> void:
	await host.get_tree().process_frame
	_mount_swipe_finalized_lazy_cards(target_skill_id, token, mounted_total)


func _mount_swipe_finalized_lazy_cards(target_skill_id: String, token: int, mounted_total: int) -> void:
	if token != skill_swipe_lazy_finalize_token or current_screen != "skill" or selected_skill_id != target_skill_id:
		skill_swipe_finalized_lazy_mount_pending = false
		return
	if host._skill_swipe_activity_surface().skill_swipe_queued_offset != 0:
		if host._skill_swipe_activity_surface().skill_swipe_handoff_cover != null and is_instance_valid(host._skill_swipe_activity_surface().skill_swipe_handoff_cover):
			host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(host._skill_swipe_activity_surface().skill_swipe_handoff_cover, true)
			host._app_lifecycle_runtime().set_canvas_item_modulate_if_changed(host._skill_swipe_activity_surface().skill_swipe_handoff_cover, Color.WHITE)
			host._skill_swipe_activity_surface().skill_swipe_outgoing_cover_active = true
		if host._consume_queued_skill_swipe_navigation():
			skill_swipe_finalized_lazy_mount_pending = false
			return
	if detail_lazy_plan.is_empty() or detail_lazy_stack == null or not is_instance_valid(detail_lazy_stack):
		if host._ensure_finalized_skill_detail_presentable(target_skill_id):
			host._fade_clear_skill_swipe_rebuild_cover()
		else:
			var missing_restore_scroll := -1
			if detail_actions_scroll != null and is_instance_valid(detail_actions_scroll):
				missing_restore_scroll = detail_actions_scroll.scroll_vertical
			host._skill_swipe_activity_surface()._rebuild_skill_detail_after_preview(missing_restore_scroll)
		skill_swipe_finalized_lazy_mount_pending = false
		return
	var cover = host._skill_swipe_activity_surface().skill_swipe_handoff_cover
	var process_frame := Engine.get_process_frames()
	if (
		cover != null
		and is_instance_valid(cover)
		and host._skill_swipe_activity_surface()._skill_swipe_handoff_cover_is_opaque_cream_transition()
		and int(cover.get_meta("swipe_cover_last_lazy_mount_process_frame", -1)) == process_frame
	):
		_schedule_mount_swipe_finalized_lazy_cards(target_skill_id, token, mounted_total)
		return
	var mounted := _sync_detail_lazy_next_cards(true, 1)
	if mounted > 0:
		detail_lazy_mounted_this_frame = true
		if cover != null and is_instance_valid(cover) and host._skill_swipe_activity_surface()._skill_swipe_handoff_cover_is_opaque_cream_transition():
			cover.set_meta("swipe_cover_last_lazy_mount_process_frame", process_frame)
	var next_total := mounted_total + mounted
	if mounted <= 0 and not host._skill_detail_stack_is_presentable(detail_lazy_stack):
		if host._ensure_finalized_skill_detail_presentable(target_skill_id):
			Callable(self, "_sync_detail_actions_scroll_limit_deferred").call_deferred()
			if host._consume_queued_skill_swipe_navigation():
				skill_swipe_finalized_lazy_mount_pending = false
				return
			skill_swipe_finalized_lazy_mount_pending = false
			host._fade_clear_skill_swipe_rebuild_cover()
		else:
			var blank_restore_scroll := -1
			if detail_actions_scroll != null and is_instance_valid(detail_actions_scroll):
				blank_restore_scroll = detail_actions_scroll.scroll_vertical
			host._skill_swipe_activity_surface()._rebuild_skill_detail_after_preview(blank_restore_scroll)
			skill_swipe_finalized_lazy_mount_pending = false
		return
	if mounted > 0 and next_total < SKILL_SWIPE_FINALIZE_VISIBLE_MOUNT_LIMIT:
		_schedule_mount_swipe_finalized_lazy_cards(target_skill_id, token, next_total)
		return
	if next_total < SKILL_SWIPE_FINALIZE_VISIBLE_MOUNT_LIMIT and not host._skill_swipe_activity_surface()._skill_detail_stack_has_visible_modules(detail_lazy_stack):
		_schedule_mount_swipe_finalized_lazy_cards(target_skill_id, token, next_total)
		return
	if next_total < SKILL_SWIPE_FINALIZE_VISIBLE_MOUNT_LIMIT:
		_schedule_mount_swipe_finalized_lazy_cards(target_skill_id, token, next_total)
		return
	Callable(self, "_sync_detail_actions_scroll_limit_deferred").call_deferred()
	if not host._ensure_finalized_skill_detail_presentable(target_skill_id):
		if next_total < SKILL_SWIPE_FINALIZE_VISIBLE_MOUNT_LIMIT:
			_schedule_mount_swipe_finalized_lazy_cards(target_skill_id, token, next_total)
		else:
			var restore_scroll := -1
			if detail_actions_scroll != null and is_instance_valid(detail_actions_scroll):
				restore_scroll = detail_actions_scroll.scroll_vertical
			host._skill_swipe_activity_surface()._rebuild_skill_detail_after_preview(restore_scroll)
			skill_swipe_finalized_lazy_mount_pending = false
		return
	if host._consume_queued_skill_swipe_navigation():
		skill_swipe_finalized_lazy_mount_pending = false
		return
	skill_swipe_finalized_lazy_mount_pending = false
	host._fade_clear_skill_swipe_rebuild_cover()


func _finalize_swipe_preview_to_lazy_detail(preview_state: Dictionary, preserve_scroll: int, target_skill_id: String, token: int) -> void:
	var trace_finalize = OS.get_environment("IDLE_ELITE_TRACE_SWIPE_FINALIZE") == "1"
	var trace_start = Time.get_ticks_usec()
	if token != skill_swipe_lazy_finalize_token or current_screen != "skill" or selected_skill_id != target_skill_id:
		return
	if skills_content == null or skill_swipe_page == null or not is_instance_valid(skill_swipe_page):
		if trace_finalize:
			print("SWIPE_FINALIZE_TRACE fallback=missing_page us=%s" % str(Time.get_ticks_usec() - trace_start))
		skill_swipe_pending_full_finalize = false
		host._skill_swipe_activity_surface()._rebuild_skill_detail_after_preview(0 if selected_skill_id == "thieving" else maxi(0, preserve_scroll))
		return
	var preview_page = skill_swipe_page
	var preview_scroll = preview_state.get("actions_scroll") as MobileScrollContainer
	if preview_scroll == null or not is_instance_valid(preview_scroll):
		preview_scroll = host._find_skill_preview_actions_scroll(preview_page) as MobileScrollContainer
	if preview_scroll == null or not is_instance_valid(preview_scroll):
		if trace_finalize:
			print("SWIPE_FINALIZE_TRACE fallback=missing_scroll us=%s" % str(Time.get_ticks_usec() - trace_start))
		skill_swipe_pending_full_finalize = false
		host._skill_swipe_activity_surface()._rebuild_skill_detail_after_preview(0 if selected_skill_id == "thieving" else maxi(0, preserve_scroll))
		return
	var stack = host._find_skill_preview_stack(preview_page) as VBoxContainer
	if stack == null or not is_instance_valid(stack):
		if trace_finalize:
			print("SWIPE_FINALIZE_TRACE fallback=missing_stack us=%s" % str(Time.get_ticks_usec() - trace_start))
		skill_swipe_pending_full_finalize = false
		host._skill_swipe_activity_surface()._rebuild_skill_detail_after_preview(0 if selected_skill_id == "thieving" else maxi(0, preserve_scroll))
		return
	if trace_finalize:
		print("SWIPE_FINALIZE_TRACE phase=resolved us=%s children=%s" % [str(Time.get_ticks_usec() - trace_start), str(stack.get_child_count())])

	host._skill_swipe_activity_surface()._begin_skill_swipe_rebuild_cover()
	stack.visible = false
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	await host.get_tree().process_frame
	if token != skill_swipe_lazy_finalize_token or current_screen != "skill" or selected_skill_id != target_skill_id:
		return
	detail_actions_scroll = preview_scroll
	var actions_parent = _ensure_skill_detail_actions_clip_wrapper(preview_page, detail_actions_scroll, host._skill_content_width())
	detail_actions_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	detail_actions_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_actions_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	detail_actions_scroll.clip_contents = true
	detail_lazy_stack = stack
	host._skill_swipe_activity_surface()._clear_action_pop_tweens()
	host._reward_feedback_surface()._clear_action_crit_tweens()
	host._reward_feedback_surface()._clear_stamina_gauge_pop_tween()
	host._activity_unlock_ceremony_surface().clear_visual_scroll_tween()
	for raw_key in action_card_keys.duplicate():
		_discard_action_card_key(str(raw_key))
	action_cards.clear()
	action_card_keys.clear()
	detail_action_card_nodes.clear()
	detail_rendered_action_ids.clear()
	_clear_detail_lazy_cache_bin()
	detail_lazy_plan.clear()
	detail_lazy_last_scroll = -1.0
	var content_width = host._skill_content_width()
	var actions_width = content_width
	await host.get_tree().process_frame
	if token != skill_swipe_lazy_finalize_token or current_screen != "skill" or selected_skill_id != target_skill_id:
		return
	var retired_preview_stack = stack
	stack = _replace_swipe_preview_stack_for_finalize(preview_scroll, stack, actions_width)
	if stack == null or not is_instance_valid(stack):
		if trace_finalize:
			print("SWIPE_FINALIZE_TRACE fallback=replace_stack_failed us=%s" % str(Time.get_ticks_usec() - trace_start))
		host._skill_swipe_activity_surface()._rebuild_skill_detail_after_preview(0 if selected_skill_id == "thieving" else maxi(0, preserve_scroll))
		return
	detail_lazy_stack = stack
	if token != skill_swipe_lazy_finalize_token or current_screen != "skill" or selected_skill_id != target_skill_id:
		return
	call_deferred(
		"_free_retired_swipe_preview_stack_batched",
		retired_preview_stack,
		retired_preview_stack.get_children() if retired_preview_stack != null and is_instance_valid(retired_preview_stack) else [],
		0
	)
	if trace_finalize:
		print("SWIPE_FINALIZE_TRACE phase=cleared us=%s" % str(Time.get_ticks_usec() - trace_start))

	var top_spacer = Control.new()
	top_spacer.name = "DetailActionsTopSpacer"
	top_spacer.custom_minimum_size = Vector2(0, onboarding_first_module_top_spacer_height(selected_skill_id))
	top_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(top_spacer)
	detail_actions_top_spacer = top_spacer
	await host.get_tree().process_frame
	if token != skill_swipe_lazy_finalize_token or current_screen != "skill" or selected_skill_id != target_skill_id:
		return
	if host._fishing_rework_active_for_skill(selected_skill_id):
		detail_lazy_plan = host._fishing_ui_surface()._build_fishing_detail_lazy_plan(selected_skill_id)
	else:
		detail_lazy_plan = _build_detail_lazy_plan(selected_skill_id)
	host._skill_swipe_activity_surface()._apply_swipe_preview_real_card_cacoe_to_lazy_plan(preview_state)
	host._skill_swipe_activity_surface()._apply_global_swipe_real_card_cacoe_to_lazy_plan(selected_skill_id)
	var slots_created = await _detail_lazy_create_slots_batched(
		stack,
		selected_skill_id,
		content_width,
		actions_width,
		SKILL_SWIPE_FINALIZE_SLOT_BATCH_SIZE
	)
	if not slots_created:
		if trace_finalize:
			print("SWIPE_FINALIZE_TRACE fallback=slots_failed us=%s" % str(Time.get_ticks_usec() - trace_start))
		host._skill_swipe_activity_surface()._rebuild_skill_detail_after_preview(0 if selected_skill_id == "thieving" else maxi(0, preserve_scroll))
		return
	if token != skill_swipe_lazy_finalize_token or current_screen != "skill" or selected_skill_id != target_skill_id:
		return
	_detail_lazy_mount_thieving_heists_sync(true)
	_queue_skill_detail_and_swipe_texture_prewarm(selected_skill_id)
	skill_swipe_pending_full_finalize = false
	if trace_finalize:
		print("SWIPE_FINALIZE_TRACE phase=slots us=%s plan=%s children=%s" % [str(Time.get_ticks_usec() - trace_start), str(detail_lazy_plan.size()), str(stack.get_child_count())])

	var bottom_spacer = Control.new()
	bottom_spacer.name = "DetailActionsBottomSpacer"
	var bottom_pad = _detail_actions_bottom_scroll_pad(selected_skill_id)
	bottom_spacer.custom_minimum_size = Vector2(0, bottom_pad)
	bottom_spacer.visible = bottom_pad > 1.0
	bottom_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(bottom_spacer)
	detail_unlock_scroll_spacer = bottom_spacer

	var restore_scroll = 0 if selected_skill_id == "thieving" else maxi(0, preserve_scroll)
	if preserve_scroll >= 0:
		detail_actions_scroll.drag_scroll_position = float(restore_scroll)
		detail_actions_scroll.scroll_vertical = restore_scroll
	if actions_parent == null or not is_instance_valid(actions_parent):
		actions_parent = detail_actions_scroll.get_parent() as Control
	if actions_parent != null and is_instance_valid(actions_parent):
		_build_detail_jump_arrows(actions_parent)
	if detail_shelf_shadow_overlay == null or not is_instance_valid(detail_shelf_shadow_overlay):
		_add_skill_detail_shadow_overlay(_skill_detail_shadow_top_y())
	Callable(self, "_sync_detail_actions_scroll_limit_deferred").call_deferred()
	skill_swipe_finalized_lazy_mount_pending = true
	_schedule_mount_swipe_finalized_lazy_cards(selected_skill_id, token, 0)
	host._skill_swipe_activity_surface().call_deferred("_apply_pending_swipe_resume_scroll", target_skill_id)
	if trace_finalize:
		print("SWIPE_FINALIZE_TRACE phase=done us=%s" % str(Time.get_ticks_usec() - trace_start))


func _add_skill_detail_shadow_overlay(top_y: float) -> void:
	if skills_content == null:
		return
	detail_shelf_shadow_alpha = _skill_detail_shadow_target_alpha()
	detail_shelf_shadow_overlay = _add_skill_detail_shadow_overlay_to(skills_content, top_y, detail_shelf_shadow_alpha)


func _skill_detail_shadow_top_y() -> float:
	return float(SKILL_DETAIL_HEADER_HEIGHT + SKILL_DETAIL_ACTIONS_DIVIDER_HEIGHT)


func _add_skill_detail_shadow_overlay_to(parent: Control, top_y: float, initial_alpha := -1.0, bottom_y := -1.0, shadow_name := "SkillDetailFixedShelfShadow", shadow_z_index := 500) -> Control:
	if parent == null or not is_instance_valid(parent) or parent.is_queued_for_deletion():
		return null
	var shelf_shadow := _PageShelfShadow.new()
	shelf_shadow.name = shadow_name
	shelf_shadow.anchor_left = 0.0
	shelf_shadow.anchor_right = 1.0
	shelf_shadow.anchor_top = 0.0
	shelf_shadow.anchor_bottom = 0.0
	shelf_shadow.offset_left = 0.0
	shelf_shadow.offset_right = 0.0
	shelf_shadow.offset_top = top_y
	shelf_shadow.offset_bottom = top_y + 116.0 if bottom_y < 0.0 else bottom_y
	shelf_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shelf_shadow.z_index = shadow_z_index
	shelf_shadow.set_shadow_alpha(detail_shelf_shadow_alpha if initial_alpha < 0.0 else clampf(initial_alpha, 0.0, 1.0))
	parent.add_child(shelf_shadow)
	return shelf_shadow


func _skill_detail_shadow_target_alpha() -> float:
	if current_screen == "menu":
		if content_scroll == null or not is_instance_valid(content_scroll):
			return 0.0
		var menu_scroll_amount := float(content_scroll.scroll_vertical)
		return clampf(menu_scroll_amount / host.SKILL_DETAIL_SHADOW_FADE_SCROLL, 0.0, 1.0)
	if current_screen == "pinned":
		if content_scroll == null or not is_instance_valid(content_scroll):
			return 0.0
		var pinned_scroll_amount := maxf(float(content_scroll.scroll_vertical), float(content_scroll.get("drag_scroll_position")))
		return clampf(pinned_scroll_amount / host.SKILL_DETAIL_SHADOW_FADE_SCROLL, 0.0, 1.0)
	if current_screen != "skill" or detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll):
		return 0.0
	if onboarding_first_module_center_active():
		return 0.0
	var scroll_amount := float(detail_actions_scroll.scroll_vertical)
	return clampf(scroll_amount / host.SKILL_DETAIL_SHADOW_FADE_SCROLL, 0.0, 1.0)


func _update_skill_detail_shadow(delta: float, instant := false) -> void:
	var target_alpha := _skill_detail_shadow_target_alpha()
	if instant:
		detail_shelf_shadow_alpha = target_alpha
	else:
		var step := 1.0 - exp(-host.SKILL_DETAIL_SHADOW_FADE_SPEED * delta)
		detail_shelf_shadow_alpha = lerpf(detail_shelf_shadow_alpha, target_alpha, step)
		if absf(detail_shelf_shadow_alpha - target_alpha) <= 0.01:
			detail_shelf_shadow_alpha = target_alpha
	if detail_shelf_shadow_overlay == null:
		return
	if not is_instance_valid(detail_shelf_shadow_overlay) or detail_shelf_shadow_overlay.is_queued_for_deletion():
		detail_shelf_shadow_overlay = null
		return
	if not detail_shelf_shadow_overlay.is_inside_tree():
		return
	var should_show_shadow := detail_shelf_shadow_alpha > 0.001
	host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(detail_shelf_shadow_overlay, should_show_shadow)
	if not should_show_shadow:
		return
	if not is_instance_valid(detail_shelf_shadow_overlay) or detail_shelf_shadow_overlay.is_queued_for_deletion() or not detail_shelf_shadow_overlay.is_inside_tree():
		return
	if detail_shelf_shadow_overlay.has_method("set_shadow_alpha"):
		detail_shelf_shadow_overlay.call("set_shadow_alpha", detail_shelf_shadow_alpha)


func _build_detail_jump_arrows(parent: Control) -> void:
	if detail_actions_scroll == null:
		return
	if host._onboarding_runtime()._onboarding_path_active():
		return
	var scroll_direction_callback := Callable(host, "_on_detail_actions_user_scroll_direction")
	if not detail_actions_scroll.user_scroll_direction.is_connected(scroll_direction_callback):
		detail_actions_scroll.user_scroll_direction.connect(scroll_direction_callback)
	detail_jump_top_button = _activity_jump_button(ACTIVITY_JUMP_TOP_TEXTURE, true)
	detail_jump_bottom_button = _activity_jump_button(ACTIVITY_JUMP_BOTTOM_TEXTURE, false)
	parent.add_child(detail_jump_top_button)
	parent.add_child(detail_jump_bottom_button)


func _navigation_detail_back_state() -> Dictionary:
	return {
		"detail_back_button": detail_back_button,
		"detail_back_press_active": detail_back_press_active,
		"detail_back_press_touch_index": detail_back_press_touch_index,
	}


func _apply_navigation_detail_back_state(state: Dictionary) -> void:
	detail_back_button = host._app_lifecycle_runtime().state_object_ref(state.get("detail_back_button"))
	detail_back_press_active = bool(state.get("detail_back_press_active", false))
	detail_back_press_touch_index = int(state.get("detail_back_press_touch_index", -1))


func _set_detail_back_button(back_button: BaseButton) -> void:
	detail_back_button = back_button


func _route_detail_back_button_input(event: InputEvent) -> bool:
	if host.current_screen != "skill" or detail_back_button == null or not is_instance_valid(detail_back_button):
		_clear_detail_back_button_input_state()
		return false
	var event_position := Vector2.ZERO
	var pressed := false
	var released := false
	var is_motion := false
	var touch_index := -1
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		event_position = event.global_position
		pressed = event.pressed
		released = not event.pressed
	elif event is InputEventMouseMotion:
		event_position = (event as InputEventMouseMotion).global_position
		is_motion = true
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		event_position = touch_event.position
		touch_index = touch_event.index
		pressed = touch_event.pressed
		released = not touch_event.pressed
	elif event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		event_position = drag_event.position
		touch_index = drag_event.index
		is_motion = true
	else:
		return false
	if pressed:
		if not _detail_back_button_contains_position(event_position):
			return false
		detail_back_press_active = true
		detail_back_press_touch_index = touch_index
		action_card_press_key = ""
		action_card_press_stat_kind = ""
		action_card_press_dragged = false
		host._skill_swipe_activity_surface()._cancel_skill_swipe_feedback(false)
		return true
	if not detail_back_press_active:
		return false
	if touch_index >= 0 and detail_back_press_touch_index >= 0 and touch_index != detail_back_press_touch_index:
		return false
	if is_motion:
		return true
	if released:
		_clear_detail_back_button_input_state()
		if _detail_back_button_contains_position(event_position):
			host._navigation_shell()._show_skills()
		return true
	return false


func _detail_back_button_contains_position(event_position: Vector2) -> bool:
	if detail_back_button == null or not is_instance_valid(detail_back_button):
		return false
	var back_rect := detail_back_button.get_global_rect().grow(36.0)
	return host._input_routing_shell()._first_position_in_rect(host._input_routing_shell()._activity_input_position_candidates(event_position), back_rect) != null


func _skill_detail_back_arrow_allowed() -> bool:
	return false


func _sync_activity_back_button_visibility(back_button: Button, interactive: bool) -> void:
	if back_button == null or not is_instance_valid(back_button):
		return
	var allowed := interactive and _skill_detail_back_arrow_allowed()
	host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(back_button, allowed)
	var next_mouse_filter := Control.MOUSE_FILTER_STOP if allowed else Control.MOUSE_FILTER_IGNORE
	if back_button.mouse_filter != next_mouse_filter:
		back_button.mouse_filter = next_mouse_filter


func _sync_skill_detail_back_arrow_visibility() -> void:
	if detail_back_button == null or not is_instance_valid(detail_back_button):
		if detail_header_body == null or not is_instance_valid(detail_header_body):
			return
		for child in detail_header_body.get_children():
			if child is Button:
				var candidate := child as Button
				if bool(candidate.get_meta("activity_back_button", false)):
					detail_back_button = candidate
					break
	if detail_back_button == null or not is_instance_valid(detail_back_button):
		return
	_sync_activity_back_button_visibility(detail_back_button as Button, true)


func _add_activity_back_arrow(parent: Control, interactive := true) -> Button:
	var back_button := Button.new()
	back_button.text = ""
	back_button.custom_minimum_size = ACTIVITY_BACK_BUTTON_SIZE
	back_button.focus_mode = Control.FOCUS_NONE
	back_button.tooltip_text = ""
	back_button.set_meta("activity_back_button", true)
	var empty_style := StyleBoxEmpty.new()
	back_button.add_theme_stylebox_override("normal", empty_style)
	back_button.add_theme_stylebox_override("hover", empty_style)
	back_button.add_theme_stylebox_override("pressed", empty_style)
	back_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	back_button.modulate = Color.WHITE
	host.button_press_runtime.attach_button_depress_animation(back_button, 0.955)
	var back_tint := Color(1, 1, 1, 0.5)
	var arrow := TextureRect.new()
	arrow.texture = host.visual_texture_cache._texture_or_visual_fallback(ACTIVITY_BACK_TEXTURE)
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow.custom_minimum_size = ACTIVITY_BACK_ARROW_SIZE
	arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	arrow.modulate = back_tint
	arrow.offset_left = 34
	arrow.offset_top = 28
	arrow.offset_right = arrow.offset_left + ACTIVITY_BACK_ARROW_SIZE.x
	arrow.offset_bottom = arrow.offset_top + ACTIVITY_BACK_ARROW_SIZE.y
	back_button.add_child(arrow)
	var skills_label: Label = host._label("skills", host.MIN_MOBILE_BODY_FONT_SIZE, Color(0, 0, 0, 0.5), HORIZONTAL_ALIGNMENT_LEFT)
	skills_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if host.app_bold_font != null:
		skills_label.add_theme_font_override("font", host.app_bold_font)
	skills_label.offset_left = 270
	skills_label.offset_top = 24
	skills_label.offset_right = 442
	skills_label.offset_bottom = 108
	back_button.add_child(skills_label)
	back_button.offset_left = 24
	back_button.offset_top = 26
	back_button.offset_right = back_button.offset_left + ACTIVITY_BACK_BUTTON_SIZE.x
	back_button.offset_bottom = back_button.offset_top + ACTIVITY_BACK_BUTTON_SIZE.y
	back_button.z_index = 80
	if interactive:
		back_button.pressed.connect(Callable(host._navigation_shell(), "_show_skills"))
		detail_back_button = back_button
	parent.add_child(back_button)
	_sync_activity_back_button_visibility(back_button, interactive)
	return back_button


func _enable_skill_detail_back_arrow(header_body: Control) -> void:
	if header_body == null or not is_instance_valid(header_body):
		return
	for child in header_body.get_children():
		if child is BaseButton:
			var back_button := child as BaseButton
			if not bool(back_button.get_meta("activity_back_button", false)):
				continue
			back_button.visible = false
			back_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if detail_back_button == back_button:
				detail_back_button = null
			continue
		if child is Control and child.get_child_count() > 0:
			_enable_skill_detail_back_arrow(child as Control)


func _clear_detail_back_button_input_state() -> void:
	detail_back_press_active = false
	detail_back_press_touch_index = -1


func _clear_detail_back_arrow_state() -> void:
	detail_back_button = null
	_clear_detail_back_button_input_state()


func _activity_jump_button(path: String, top: bool) -> TextureButton:
	var button := TextureButton.new()
	button.texture_normal = host.visual_texture_cache._texture_or_visual_fallback(path)
	button.texture_hover = button.texture_normal
	button.texture_pressed = button.texture_normal
	button.texture_disabled = button.texture_normal
	button.texture_focused = button.texture_normal
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.custom_minimum_size = ACTIVITY_JUMP_ARROW_SIZE
	button.focus_mode = Control.FOCUS_NONE
	button.z_index = ProfileChatOverlaySurface.CHAT_UI_Z + 140
	button.z_as_relative = false
	button.anchor_left = 0.5
	button.anchor_right = 0.5
	button.offset_left = -ACTIVITY_JUMP_ARROW_SIZE.x * 0.5
	button.offset_right = ACTIVITY_JUMP_ARROW_SIZE.x * 0.5
	if top:
		button.anchor_top = 0.0
		button.anchor_bottom = 0.0
		button.offset_top = ACTIVITY_JUMP_ARROW_EDGE_INSET
		button.offset_bottom = ACTIVITY_JUMP_ARROW_EDGE_INSET + ACTIVITY_JUMP_ARROW_SIZE.y
	else:
		button.anchor_top = 1.0
		button.anchor_bottom = 1.0
		button.offset_top = -ACTIVITY_JUMP_ARROW_BOTTOM_EDGE_INSET - ACTIVITY_JUMP_ARROW_SIZE.y
		button.offset_bottom = -ACTIVITY_JUMP_ARROW_BOTTOM_EDGE_INSET
	button.modulate = Color(1, 1, 1, 0)
	button.disabled = true
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.mouse_entered.connect(_on_detail_jump_arrow_hovered.bind(top, true))
	button.mouse_exited.connect(_on_detail_jump_arrow_hovered.bind(top, false))
	host.button_press_runtime.attach_button_depress_animation(button, 0.93)
	button.pressed.connect(_on_detail_jump_arrow_pressed.bind(-1 if top else 1))
	return button


func _event_points_inside_detail_jump_arrow(event: InputEvent, source: Control = null) -> bool:
	var event_position := Vector2.ZERO
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return false
		event_position = host._input_routing_shell()._global_event_position(mouse_event.position, mouse_event.global_position, source)
	elif event is InputEventMouseMotion:
		var motion_event := event as InputEventMouseMotion
		event_position = host._input_routing_shell()._global_event_position(motion_event.position, motion_event.global_position, source)
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		event_position = host._input_routing_shell()._global_event_position(touch_event.position, touch_event.position, source)
	elif event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		event_position = host._input_routing_shell()._global_event_position(drag_event.position, drag_event.position, source)
	else:
		return false
	return _detail_jump_arrow_direction_at_position(event_position) != 0


func _route_detail_jump_arrow_input(event: InputEvent) -> bool:
	if host.current_screen != "skill" or detail_actions_scroll == null:
		_clear_detail_jump_arrow_input_state()
		return false
	var event_position := Vector2.ZERO
	var pressed := false
	var released := false
	var is_motion := false
	var touch_index := -1
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_event := event as InputEventMouseButton
		event_position = mouse_event.global_position
		pressed = mouse_event.pressed
		released = not mouse_event.pressed
	elif event is InputEventMouseMotion:
		event_position = (event as InputEventMouseMotion).global_position
		is_motion = true
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		event_position = touch_event.position
		touch_index = touch_event.index
		pressed = touch_event.pressed
		released = not touch_event.pressed
	elif event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		event_position = drag_event.position
		touch_index = drag_event.index
		is_motion = true
	else:
		return false
	if pressed:
		var direction := _detail_jump_arrow_direction_at_position(event_position)
		if direction == 0:
			return false
		detail_jump_press_direction = direction
		detail_jump_press_touch_index = touch_index
		action_card_press_key = ""
		host._skill_swipe_activity_surface()._cancel_skill_swipe_feedback(false)
		return true
	if detail_jump_press_direction == 0:
		return false
	if touch_index >= 0 and detail_jump_press_touch_index >= 0 and touch_index != detail_jump_press_touch_index:
		return false
	if is_motion:
		return true
	if released:
		var direction := detail_jump_press_direction
		_clear_detail_jump_arrow_input_state()
		if _detail_jump_arrow_direction_at_position(event_position) == direction:
			_on_detail_jump_arrow_pressed(direction)
		return true
	return false


func _clear_detail_jump_arrow_input_state() -> void:
	detail_jump_press_direction = 0
	detail_jump_press_touch_index = -1


func _clear_detail_jump_arrow_state() -> void:
	detail_jump_top_button = null
	detail_jump_bottom_button = null
	detail_jump_top_hold = 0.0
	detail_jump_bottom_hold = 0.0
	detail_jump_top_hovered = false
	detail_jump_bottom_hovered = false
	_clear_detail_jump_arrow_input_state()


func _detail_jump_arrow_direction_at_position(event_position: Vector2) -> int:
	if _detail_jump_arrow_contains_position(detail_jump_top_button, -1, event_position):
		return -1
	if _detail_jump_arrow_contains_position(detail_jump_bottom_button, 1, event_position):
		return 1
	return 0


func _detail_jump_arrow_contains_position(raw_button: Variant, direction: int, event_position: Vector2) -> bool:
	if raw_button == null or not is_instance_valid(raw_button):
		return false
	var button := raw_button as TextureButton
	if button == null or not is_instance_valid(button):
		return false
	if not _detail_jump_arrow_can_use(direction):
		return false
	if button.modulate.a <= 0.04:
		return false
	return button.get_global_rect().grow(18.0).has_point(event_position)


func _detail_jump_arrow_can_use(direction: int) -> bool:
	if detail_actions_scroll == null or not _detail_jump_arrows_have_enough_modules():
		return false
	var max_scroll: int = detail_actions_scroll.get_max_scroll_vertical()
	if max_scroll <= ACTIVITY_JUMP_ARROW_EDGE_EPSILON:
		return false
	var scroll: int = detail_actions_scroll.scroll_vertical
	if direction < 0:
		return scroll > ACTIVITY_JUMP_ARROW_EDGE_EPSILON
	return scroll < max_scroll - ACTIVITY_JUMP_ARROW_EDGE_EPSILON


func _detail_jump_arrows_have_enough_modules() -> bool:
	if not detail_lazy_plan.is_empty():
		return _detail_jump_arrow_lazy_module_count() >= ACTIVITY_JUMP_ARROW_MIN_MODULES
	return detail_rendered_action_ids.size() >= ACTIVITY_JUMP_ARROW_MIN_MODULES


func _detail_jump_arrow_lazy_module_count() -> int:
	var count := 0
	for raw_lazy_entry in detail_lazy_plan:
		var lazy_entry := raw_lazy_entry as Dictionary
		if str(lazy_entry.get("kind", "")) in ["action", "passive", "heist", "fishing_area", "fishing_offer"]:
			count += 1
	return count


func _on_detail_jump_arrow_hovered(top: bool, hovered: bool) -> void:
	if top:
		detail_jump_top_hovered = hovered
		if hovered:
			_reveal_detail_jump_arrow(-1)
		else:
			detail_jump_top_hold = ACTIVITY_JUMP_ARROW_LINGER_SECONDS
	else:
		detail_jump_bottom_hovered = hovered
		if hovered:
			_reveal_detail_jump_arrow(1)
		else:
			detail_jump_bottom_hold = ACTIVITY_JUMP_ARROW_LINGER_SECONDS


func _on_detail_jump_arrow_pressed(direction: int) -> void:
	if host.current_screen != "skill" or detail_actions_scroll == null:
		return
	if direction < 0:
		detail_jump_top_hold = 0.0
		detail_jump_bottom_hold = 0.0
		detail_jump_bottom_hovered = false
		_prepare_detail_jump_arrow_target_window(0)
		detail_actions_scroll.scroll_to_vertical(0, 0.24)
	else:
		detail_jump_bottom_hold = 0.0
		detail_jump_top_hold = 0.0
		detail_jump_top_hovered = false
		var bottom_scroll: int = detail_actions_scroll.get_max_scroll_vertical()
		bottom_scroll = _prepare_detail_jump_arrow_target_window(bottom_scroll)
		detail_actions_scroll.scroll_to_vertical(bottom_scroll, 0.24)
	host.get_viewport().set_input_as_handled()


func _detail_lazy_entry_intersects_scroll_window(lazy_entry: Dictionary, target_scroll_y: float, viewport_buffer: float) -> bool:
	var stack_host: Control = host._app_lifecycle_runtime().valid_control_ref(lazy_entry.get("stack_host"))
	if lazy_entry.has("stack_host") and stack_host == null:
		return false
	var view_top := maxf(0.0, target_scroll_y - maxf(0.0, viewport_buffer))
	var view_bottom: float = target_scroll_y + _detail_lazy_viewport_height() + maxf(0.0, viewport_buffer)
	var entry_rect: Rect2 = _detail_lazy_entry_rect_for_viewport(lazy_entry)
	var entry_y: float = entry_rect.position.y
	var entry_bottom: float = entry_y + entry_rect.size.y
	return entry_rect.size.y > 1.0 and entry_bottom >= view_top and entry_y <= view_bottom


func _sync_detail_lazy_cards_for_scroll_window(target_scroll_y: float, viewport_buffer := ACTIVITY_JUMP_ARROW_LANDING_PREFILL_BUFFER_PX) -> int:
	if host.current_screen != "skill":
		return 0
	if detail_lazy_plan.is_empty() or host._app_lifecycle_runtime().valid_control_ref(detail_lazy_stack) == null or host._app_lifecycle_runtime().valid_control_ref(detail_actions_scroll) == null:
		return 0
	var content_width: float = host._skill_content_width()
	var actions_width: float = content_width
	var mounted_count := 0
	var previous_mount_context: String = detail_lazy_mount_trace_context
	detail_lazy_mount_trace_context = "jump_landing_prefill"
	for raw_lazy_entry in detail_lazy_plan:
		var lazy_entry := raw_lazy_entry as Dictionary
		if bool(lazy_entry.get("mounted", false)):
			continue
		if not _detail_lazy_entry_intersects_scroll_window(lazy_entry, target_scroll_y, viewport_buffer):
			continue
		if _detail_lazy_mount_item(lazy_entry, selected_skill_id, content_width, actions_width, false):
			mounted_count += 1
	detail_lazy_mount_trace_context = previous_mount_context
	if mounted_count > 0:
		detail_lazy_mounted_this_frame = true
		detail_lazy_all_mounted_cache_frame = -1
	return mounted_count


func _prepare_detail_jump_arrow_target_window(target_scroll: int) -> int:
	if detail_lazy_plan.is_empty() or detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll):
		return target_scroll
	_sync_detail_lazy_cards_for_scroll_window(float(target_scroll), ACTIVITY_JUMP_ARROW_LANDING_PREFILL_BUFFER_PX)
	_sync_detail_actions_scroll_limit()
	var clamped_target := clampi(target_scroll, 0, detail_actions_scroll.get_max_scroll_vertical())
	if clamped_target != target_scroll:
		_sync_detail_lazy_cards_for_scroll_window(float(clamped_target), ACTIVITY_JUMP_ARROW_LANDING_PREFILL_BUFFER_PX)
	return clamped_target


func _reveal_detail_jump_arrow(direction: int) -> void:
	if detail_actions_scroll == null or not _detail_jump_arrows_have_enough_modules():
		return
	if direction < 0 and _detail_jump_arrow_can_use(-1):
		detail_jump_top_hold = ACTIVITY_JUMP_ARROW_LINGER_SECONDS
	elif direction > 0 and _detail_jump_arrow_can_use(1):
		detail_jump_bottom_hold = ACTIVITY_JUMP_ARROW_LINGER_SECONDS


func _process_detail_jump_arrows(delta: float) -> void:
	var top_button := _valid_texture_button_ref(detail_jump_top_button)
	var bottom_button := _valid_texture_button_ref(detail_jump_bottom_button)
	if top_button == null:
		detail_jump_top_button = null
	if bottom_button == null:
		detail_jump_bottom_button = null
	if _detail_jump_arrows_idle(top_button, bottom_button):
		return
	if detail_actions_scroll == null or host.current_screen != "skill":
		_process_detail_jump_arrow(top_button, true, false, delta)
		_process_detail_jump_arrow(bottom_button, false, false, delta)
		return
	_process_detail_jump_arrow(top_button, true, _detail_jump_arrow_can_use(-1), delta)
	_process_detail_jump_arrow(bottom_button, false, _detail_jump_arrow_can_use(1), delta)


func _detail_jump_arrows_idle(top_button: TextureButton, bottom_button: TextureButton) -> bool:
	if detail_jump_top_hold > 0.0 or detail_jump_bottom_hold > 0.0 or detail_jump_top_hovered or detail_jump_bottom_hovered:
		return false
	if top_button != null and is_instance_valid(top_button):
		if top_button.modulate.a > 0.001 or not top_button.disabled or top_button.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			return false
	if bottom_button != null and is_instance_valid(bottom_button):
		if bottom_button.modulate.a > 0.001 or not bottom_button.disabled or bottom_button.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			return false
	return true


func _detail_jump_arrows_need_processing() -> bool:
	return not _detail_jump_arrows_idle(
		_valid_texture_button_ref(detail_jump_top_button),
		_valid_texture_button_ref(detail_jump_bottom_button)
	)


func _valid_texture_button_ref(value) -> TextureButton:
	var control: Control = host._app_lifecycle_runtime().valid_control_ref(value)
	if control == null:
		return null
	return control as TextureButton


func _process_detail_jump_arrow(button: TextureButton, top: bool, can_use: bool, delta: float) -> void:
	if button == null or not is_instance_valid(button):
		return
	if top:
		if not can_use:
			detail_jump_top_hold = 0.0
			detail_jump_top_hovered = false
		elif detail_jump_top_hovered:
			detail_jump_top_hold = ACTIVITY_JUMP_ARROW_LINGER_SECONDS
		else:
			detail_jump_top_hold = maxf(0.0, detail_jump_top_hold - delta)
	else:
		if not can_use:
			detail_jump_bottom_hold = 0.0
			detail_jump_bottom_hovered = false
		elif detail_jump_bottom_hovered:
			detail_jump_bottom_hold = ACTIVITY_JUMP_ARROW_LINGER_SECONDS
		else:
			detail_jump_bottom_hold = maxf(0.0, detail_jump_bottom_hold - delta)
	var held := detail_jump_top_hold if top else detail_jump_bottom_hold
	var hovered := detail_jump_top_hovered if top else detail_jump_bottom_hovered
	var target_alpha := 1.0 if can_use and (hovered or held > 0.0) else 0.0
	var fade_seconds: float = ACTIVITY_JUMP_ARROW_FADE_IN_SECONDS if target_alpha > button.modulate.a else ACTIVITY_JUMP_ARROW_FADE_OUT_SECONDS
	var step := delta / maxf(0.001, fade_seconds)
	var next_alpha := move_toward(button.modulate.a, target_alpha, step)
	if absf(button.modulate.a - next_alpha) > 0.001 or button.modulate.r != 1.0 or button.modulate.g != 1.0 or button.modulate.b != 1.0:
		button.modulate = Color(1, 1, 1, next_alpha)
	var active := can_use and next_alpha > 0.04
	var next_disabled := not active
	if button.disabled != next_disabled:
		button.disabled = next_disabled
	var next_mouse_filter := Control.MOUSE_FILTER_STOP if active else Control.MOUSE_FILTER_IGNORE
	if button.mouse_filter != next_mouse_filter:
		button.mouse_filter = next_mouse_filter


func _module_list_transition_key_for_control(control: Control) -> String:
	if control == null or not is_instance_valid(control):
		return ""
	var direct_key := ModuleUiRuntime.normalize(control.get_meta("module_ui_key", ""))
	if not direct_key.is_empty():
		if bool(control.get_meta("module_ui_pinned_shelf_copy", false)):
			return "pinned_shelf:%s" % direct_key
		if bool(control.get_meta("module_ui_pinned_page_copy", false)):
			return "pinned_page:%s" % direct_key
		return direct_key
	for child in control.get_children():
		var child_control := child as Control
		if child_control == null:
			continue
		var child_key := _module_list_transition_key_for_control(child_control)
		if not child_key.is_empty():
			return child_key
	return ""


func _capture_detail_module_layout_snapshot() -> Dictionary:
	if current_screen != "skill":
		return {}
	var stack := _detail_actions_stack() as VBoxContainer
	if stack == null or not is_instance_valid(stack):
		return {}
	var snapshot := {}
	var occurrence_counts := {}
	for child in stack.get_children():
		var control := child as Control
		if control == null or not is_instance_valid(control):
			continue
		if control.name in ["DetailActionsTopSpacer", "DetailActionsBottomSpacer"]:
			continue
		var module_key := _module_list_transition_key_for_control(control)
		if module_key.is_empty():
			continue
		var occurrence_index := int(occurrence_counts.get(module_key, 0))
		occurrence_counts[module_key] = occurrence_index + 1
		var occurrence_key := "%s#%s" % [module_key, occurrence_index]
		snapshot[occurrence_key] = {
			"global_rect": control.get_global_rect()
		}
	return snapshot


func _detail_module_transition_child_visible(control: Control) -> bool:
	if control == null or not is_instance_valid(control):
		return false
	if detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll):
		return true
	var viewport_rect: Rect2 = detail_actions_scroll.get_global_rect().grow(220.0)
	return viewport_rect.intersects(control.get_global_rect())


func _kill_module_list_transition_tween(control: Control) -> void:
	host._app_lifecycle_runtime()._kill_meta_tween(control, "module_list_transition_tween")


func _clear_module_ui_animating_collapse_key(module_key: String) -> void:
	if module_ui_animating_collapse_key == ModuleUiRuntime.normalize(module_key):
		module_ui_animating_collapse_key = ""


func _finish_module_list_transition(
	control_id: int,
	final_position: Vector2,
	final_scale: Vector2,
	final_minimum_size := Vector2(-1.0, -1.0),
	final_clip_contents := false
) -> void:
	var control: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(control_id))
	if control == null or control.is_queued_for_deletion():
		return
	control.position = final_position
	control.scale = final_scale
	control.modulate.a = 1.0
	control.pivot_offset = Vector2.ZERO
	if final_minimum_size.x >= 0.0 and final_minimum_size.y >= 0.0:
		if _control_tree_has_bool_meta(control, "module_ui_collapsed_squeeze"):
			final_minimum_size.y = _module_collapsed_squeeze_height()
		control.custom_minimum_size = final_minimum_size
		if bool(control.get_meta("module_ui_collapsed_squeeze", false)):
			control.size.y = final_minimum_size.y
	control.clip_contents = final_clip_contents
	if bool(control.get_meta("module_ui_collapsed_squeeze", false)):
		control.clip_contents = false
		_set_collapsed_module_visual_clipping(control, str(control.get_meta("module_ui_key", "")), true)
	if control.has_meta("module_list_transition_tween"):
		control.remove_meta("module_list_transition_tween")


func _control_tree_has_named_descendant(control: Control, target_name: String) -> bool:
	if control == null or not is_instance_valid(control):
		return false
	if control.name == target_name:
		return true
	for child in control.get_children():
		var child_control := child as Control
		if child_control != null and _control_tree_has_named_descendant(child_control, target_name):
			return true
	return false


func _control_tree_has_bool_meta(control: Control, meta_key: String) -> bool:
	if control == null or not is_instance_valid(control):
		return false
	if bool(control.get_meta(meta_key, false)):
		return true
	for child in control.get_children():
		var child_control := child as Control
		if child_control != null and _control_tree_has_bool_meta(child_control, meta_key):
			return true
	return false


func _first_control_with_bool_meta(control: Control, meta_key: String) -> Control:
	if control == null or not is_instance_valid(control):
		return null
	if bool(control.get_meta(meta_key, false)):
		return control
	for child in control.get_children():
		var child_control := child as Control
		if child_control == null:
			continue
		var found := _first_control_with_bool_meta(child_control, meta_key)
		if found != null:
			return found
	return null


func _play_detail_module_layout_transition(snapshot: Dictionary) -> void:
	if snapshot.is_empty() or current_screen != "skill":
		return
	await host.get_tree().process_frame
	if current_screen != "skill":
		return
	var stack = _detail_actions_stack() as VBoxContainer
	if stack == null or not is_instance_valid(stack):
		return
	var animated_count = 0
	var occurrence_counts = {}
	for child in stack.get_children():
		var control = child as Control
		if control == null or not is_instance_valid(control):
			continue
		if control.name in ["DetailActionsTopSpacer", "DetailActionsBottomSpacer"]:
			continue
		var module_key = _module_list_transition_key_for_control(control)
		if module_key.is_empty() or not _detail_module_transition_child_visible(control):
			continue
		var occurrence_index = int(occurrence_counts.get(module_key, 0))
		occurrence_counts[module_key] = occurrence_index + 1
		var occurrence_key = "%s#%s" % [module_key, occurrence_index]
		_kill_module_list_transition_tween(control)
		var final_position = control.position
		var final_scale = control.scale
		var final_minimum_size = control.custom_minimum_size
		var final_clip_contents = control.clip_contents
		var final_collapsed_squeeze = _first_control_with_bool_meta(control, "module_ui_collapsed_squeeze")
		if final_collapsed_squeeze != null:
			final_minimum_size.y = _module_collapsed_squeeze_height()
			if final_collapsed_squeeze == control:
				control.custom_minimum_size.y = final_minimum_size.y
		control.pivot_offset = control.size * 0.5
		var tween = host.create_tween()
		control.set_meta("module_list_transition_tween", tween)
		tween.set_parallel(true)
		if snapshot.has(occurrence_key):
			var old_rect = (snapshot.get(occurrence_key, {}) as Dictionary).get("global_rect", Rect2()) as Rect2
			var new_rect = control.get_global_rect()
			var delta = old_rect.position - new_rect.position
			var height_delta = old_rect.size.y - new_rect.size.y
			if delta.length() >= MODULE_LIST_TRANSITION_MIN_MOVE:
				control.position = final_position + delta
				tween.tween_property(control, "position", final_position, MODULE_LIST_TRANSITION_SECONDS).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
				animated_count += 1
			if height_delta > 8.0 and ModuleUiRuntime.normalize(module_key) == module_ui_animating_collapse_key and (
				_control_tree_has_named_descendant(control, "CollapsedModuleRow")
				or _control_tree_has_bool_meta(control, "module_ui_collapsed_squeeze")
			):
				var start_minimum_size = final_minimum_size
				start_minimum_size.y = maxf(final_minimum_size.y, old_rect.size.y)
				var collapsed_squeeze = _first_control_with_bool_meta(control, "module_ui_collapsed_squeeze")
				var animate_squeeze_root = collapsed_squeeze == control
				if collapsed_squeeze != null:
					collapsed_squeeze.size.y = start_minimum_size.y
				if not animate_squeeze_root:
					control.custom_minimum_size = start_minimum_size
				control.clip_contents = false if animate_squeeze_root else true
				if animate_squeeze_root:
					_set_collapsed_module_visual_clipping(control, str(control.get_meta("module_ui_key", "")), true)
					_set_collapsed_module_title_lift(control, false, true)
					_set_collapsed_module_title_lift(control, true, false)
				control.modulate.a = minf(control.modulate.a, 0.86)
				if animate_squeeze_root:
					tween.tween_property(control, "size:y", final_minimum_size.y, MODULE_COLLAPSE_SQUEEZE_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				else:
					tween.tween_property(control, "custom_minimum_size", final_minimum_size, MODULE_COLLAPSE_SQUEEZE_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				if collapsed_squeeze != null and not animate_squeeze_root:
					tween.tween_property(collapsed_squeeze, "size:y", final_minimum_size.y, MODULE_COLLAPSE_SQUEEZE_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				tween.tween_property(control, "modulate:a", 1.0, MODULE_COLLAPSE_SQUEEZE_SECONDS * 0.72).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				animated_count += 1
			elif absf(height_delta) > 8.0:
				control.modulate.a = minf(control.modulate.a, 0.72)
				tween.tween_property(control, "modulate:a", 1.0, MODULE_LIST_TRANSITION_NEW_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				animated_count += 1
		else:
			control.position = final_position + Vector2(0.0, MODULE_LIST_TRANSITION_NEW_OFFSET_Y)
			control.scale = final_scale * DETAIL_LAZY_SCALE_IN_AMOUNT
			control.modulate.a = 0.0
			tween.tween_property(control, "position", final_position, MODULE_LIST_TRANSITION_NEW_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.tween_property(control, "scale", final_scale, MODULE_LIST_TRANSITION_NEW_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.tween_property(control, "modulate:a", 1.0, MODULE_LIST_TRANSITION_NEW_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			animated_count += 1
		tween.set_parallel(false)
		tween.tween_callback(_finish_module_list_transition.bind(control.get_instance_id(), final_position, final_scale, final_minimum_size, final_clip_contents))
		if ModuleUiRuntime.normalize(module_key) == module_ui_animating_collapse_key:
			tween.tween_callback(_clear_module_ui_animating_collapse_key.bind(module_key))
	if animated_count > 0:
		_hold_skill_detail_layout_refresh(MODULE_LIST_TRANSITION_SECONDS + 0.08)
