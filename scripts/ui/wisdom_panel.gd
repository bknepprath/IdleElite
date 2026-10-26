extends VBoxContainer

const WisdomState = preload("res://scripts/progression/wisdom_state.gd")
const ActivityCardStyles = preload("res://scripts/ui/activity_card_styles.gd")
var host
var card: Dictionary
var meter: ProgressBar
var caption: Label
var caption_row: HBoxContainer
var information_icon: Control
var help: PanelContainer
var reward_badge: Control
var reward_button: Button
# The card is collapsed to its title: its badges are hidden with the rest of it.
var reward_collapsed := false
var unlock_tween: Tween
var unlock_state_initialized := false
var requirement_retracted := false
const RETRACT_SECONDS := 0.55
const CAPTION_FADE_SECONDS := 0.12
const REVEAL_SECONDS := 0.20
static var book_color_shader: Shader

class InformationIcon extends Control:
	func _draw() -> void:
		var center := size * 0.5
		var radius := minf(size.x, size.y) * 0.46
		draw_circle(center, radius, Color.WHITE)
		draw_arc(center, radius, 0.0, TAU, 48, Color.BLACK, 4.0, true)
		draw_circle(center + Vector2(0, -8), 2.5, Color.BLACK)
		draw_line(center + Vector2(0, -1), center + Vector2(0, 10), Color.BLACK, 4.5, true)

func _book_icon() -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = host.visual_texture_cache._texture_or_visual_fallback("res://assets/content/icons/resources/wisdom.png")
	icon.material = book_material(str(card.skill_id))
	icon.custom_minimum_size = Vector2(58, 58)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon

func setup(host_ref, card_ref: Dictionary) -> void:
	host = host_ref
	card = card_ref
	name = "WisdomPanel"
	z_index = 300
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_constant_override("separation", 44 if int(card.action.get("wisdom_required", 0)) > 0 else 8)
	var button: Button = host._menu_button("")
	host._apply_empty_button_style(button)
	button.name = "WisdomInformationButton"
	button.custom_minimum_size = Vector2(0, ActivityCardStyles.WISDOM_REQUIREMENT_HEIGHT)
	button.add_to_group("feedback_help_buttons")
	button.pressed.connect(_toggle_help)
	add_child(button)
	meter = ProgressBar.new()
	meter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	meter.show_percentage = false
	meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := StyleBoxFlat.new()
	background.bg_color = ThemeStyles.skill_theme_color(str(card.skill_id), Color("#8956bc")).darkened(0.60)
	background.border_color = Color.BLACK
	background.set_border_width_all(6)
	background.set_corner_radius_all(33)
	var fill := background.duplicate() as StyleBoxFlat
	fill.bg_color = ThemeStyles.skill_theme_color(str(card.skill_id), Color("#8956bc"))
	fill.border_color = fill.bg_color
	fill.set_corner_radius_all(0)
	fill.corner_radius_top_left = 27
	fill.corner_radius_bottom_left = 27
	fill.expand_margin_left = -6
	fill.expand_margin_right = -6
	fill.expand_margin_top = -6
	fill.expand_margin_bottom = -6
	meter.add_theme_stylebox_override("background", background)
	meter.add_theme_stylebox_override("fill", fill)
	button.add_child(meter)
	caption_row = HBoxContainer.new()
	caption_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	caption_row.alignment = BoxContainer.ALIGNMENT_CENTER
	caption_row.add_theme_constant_override("separation", 20)
	caption_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(caption_row)
	caption_row.add_child(_book_icon())
	caption = host._label("", 52, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_color_override("font_outline_color", Color.BLACK)
	caption.add_theme_constant_override("outline_size", 16)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption_row.add_child(caption)
	information_icon = InformationIcon.new()
	information_icon.custom_minimum_size = Vector2(44, 44)
	information_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	information_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption_row.add_child(information_icon)
	help = PanelContainer.new()
	help.name = "WisdomHelp"
	var help_background := background.duplicate() as StyleBoxFlat
	help_background.set_corner_radius_all(16)
	help.add_theme_stylebox_override("panel", help_background)
	help.visible = false
	add_child(help)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	help.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 12)
	margin.add_child(stack)
	for source in (WisdomState.sources(host, str(card.skill_id)) if int(card.action.get("wisdom_required", 0)) > 0 else []):
		var action: Dictionary = source.action
		var link := Button.new()
		link.text = "%s  +%s" % [str(action.name), int(action.wisdom_reward)]
		link.icon = host.visual_texture_cache._texture_or_visual_fallback("res://assets/content/icons/resources/wisdom.png")
		link.add_theme_constant_override("icon_max_width", 52)
		link.expand_icon = true
		link.add_theme_font_override("font", host.app_bold_font)
		var link_style := help_background.duplicate() as StyleBoxFlat
		link_style.bg_color = Color("#309afa")
		link_style.content_margin_top = 10
		link_style.content_margin_bottom = 10
		for state in ["normal", "hover", "pressed", "focus"]:
			link.add_theme_stylebox_override(state, link_style)
		link.add_theme_color_override("font_color", Color.WHITE)
		link.add_theme_color_override("font_hover_color", Color.WHITE)
		link.add_theme_color_override("font_pressed_color", Color.WHITE)
		link.add_theme_color_override("font_outline_color", Color.BLACK)
		link.add_theme_constant_override("outline_size", 16)
		link.custom_minimum_size.y = 84
		link.add_theme_font_size_override("font_size", 52)
		link.add_to_group("feedback_help_buttons")
		link.set_meta("wisdom_source", true)
		link.pressed.connect(_open_source.bind(str(source.skill_id), str(action.id)))
		stack.add_child(link)
	if int(card.action.get("wisdom_reward", 0)) > 0:
		_build_reward_badge()
		if int(card.action.get("wisdom_required", 0)) == 0:
			var reward_row := HBoxContainer.new()
			reward_row.alignment = BoxContainer.ALIGNMENT_CENTER
			reward_row.add_theme_constant_override("separation", 16)
			reward_row.add_child(_book_icon())
			var amount: Label = host._label("+%s" % int(card.action.wisdom_reward), 52, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
			amount.add_theme_color_override("font_outline_color", Color.BLACK)
			amount.add_theme_constant_override("outline_size", 16)
			reward_row.add_child(amount)
			stack.add_child(reward_row)
			button.hide()
			set_deferred("size", Vector2(size.x, 0))
	sync()

func _build_reward_badge() -> void:
	var art_panel := card.get("art_panel") as Control
	if not is_instance_valid(art_panel):
		return
	reward_badge = preload("res://scripts/ui/action_art_ui.gd").corner_badge(
		"res://assets/content/icons/resources/wisdom.png", true, 0,
		Callable(host.visual_texture_cache, "_texture_or_visual_fallback")
	)
	reward_badge.name = "WisdomRewardBadge"
	art_panel.add_child(reward_badge)
	(reward_badge.get_child(1) as TextureRect).material = book_material(str(card.skill_id))
	reward_button = Button.new()
	reward_button.name = "WisdomRewardInformation"
	reward_button.position = Vector2.ZERO
	reward_button.size = Vector2(86, 86)
	reward_button.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed", "focus"]:
		reward_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	reward_button.add_to_group("feedback_help_buttons")
	reward_button.pressed.connect(_toggle_help)
	reward_badge.add_child(reward_button)

static func book_material(skill_id: String) -> ShaderMaterial:
	if book_color_shader == null:
		book_color_shader = Shader.new()
		book_color_shader.code = """
shader_type canvas_item;
uniform vec4 skill_color : source_color = vec4(0.54, 0.34, 0.74, 1.0);
void fragment() {
	vec4 color = texture(TEXTURE, UV) * COLOR;
	if (color.r > color.g * 1.2 && color.b > color.g * 1.3) {
		color.rgb = skill_color.rgb * clamp(color.r / 0.54, 0.65, 1.12);
	} else if (color.r > color.b * 1.3 && color.g > color.b * 1.2) {
		color.rgb = mix(skill_color.rgb, vec3(1.0), 0.35) * clamp(color.g / 0.80, 0.65, 1.08);
	}
	COLOR = color;
}
"""
	var color_material := ShaderMaterial.new()
	color_material.shader = book_color_shader
	color_material.set_shader_parameter("skill_color", ThemeStyles.skill_theme_color(skill_id, Color("#8956bc")))
	return color_material

# The Wisdom icon on an activity that gives Wisdom shows while Wisdom still has
# an activity to unlock in that skill. When the last one is unlocked the icon
# goes, and with it the explanation it opens.
func sync_reward_badge() -> void:
	if not is_instance_valid(reward_badge):
		return
	var applicable: bool = WisdomState.applicable(host, str(card.action.get("wisdom_skill", card.skill_id)))
	reward_badge.visible = applicable and not reward_collapsed
	if not applicable and help.visible and int(card.action.get("wisdom_required", 0)) == 0:
		help.hide()
		set_deferred("size", Vector2(size.x, 0))
		card["wisdom_help_height"] = 0.0
		host._skill_detail_surface()._set_activity_card_expanded(card, card.root, bool(card.get("bonus_expanded", false)), true)


func sync() -> void:
	sync_reward_badge()
	var action: Dictionary = card.action
	var required := int(action.get("wisdom_required", 0))
	if required > 0:
		var unlocked: bool = host._activity_unlock_runtime()._is_action_unlocked(str(card.skill_id), action)
		# Whether the bar belongs on the card as things stand.
		var shown: bool = WisdomState.requirement_bar_shown(host, str(card.skill_id), action)
		var moving: bool = bool(card.get("wisdom_unlock_active", false))
		if not unlock_state_initialized:
			unlock_state_initialized = true
			if not shown:
				requirement_retracted = true
				card["wisdom_layer_fraction"] = 0.0
				hide()
				call_deferred("_apply_retraction", 1.0)
		elif unlocked and not requirement_retracted and not moving:
			play_unlock_transition()
		elif not shown and not requirement_retracted and not moving and not _card_is_unlocking():
			# Full, with locks that open by themselves: the bar is put away as a
			# padlock is when its level is reached. What is left keeps the
			# activity locked.
			play_unlock_transition(false, true)
		elif shown and requirement_retracted and not moving:
			_restore_requirement()
	var amount := WisdomState.total(host, str(card.skill_id))
	meter.max_value = maxi(1, required)
	meter.value = mini(amount, required) if required > 0 else 1
	var fill := meter.get_theme_stylebox("fill") as StyleBoxFlat
	fill.corner_radius_bottom_right = 27 if meter.value >= meter.max_value else 0
	fill.corner_radius_top_right = fill.corner_radius_bottom_right
	if required > 0:
		caption.text = "%s / %s" % [mini(amount, required), required]
		if WisdomState.requirement_met(host, str(card.skill_id), action):
			caption.text = "%s / %s" % [required, required]
			meter.value = meter.max_value
		if _ready_to_unlock():
			caption.text = "Unlock"
		information_icon.visible = not _ready_to_unlock()
	else:
		caption.text = "+%s" % int(action.get("wisdom_reward", 0))

func _ready_to_unlock() -> bool:
	var unlocks = host._activity_unlock_runtime()
	if unlocks._is_action_unlocked(str(card.skill_id), card.action) or not unlocks._can_unlock_action(str(card.skill_id), card.action):
		return false
	for state in unlocks._action_requirement_states(str(card.skill_id), card.action):
		if not bool(state.dismissed):
			return false
	return true

func _toggle_help() -> void:
	if bool(card.get("wisdom_unlock_active", false)) or requirement_retracted:
		return
	if _ready_to_unlock():
		play_unlock_transition(true)
		return
	help.visible = not help.visible
	if not help.visible and int(card.action.get("wisdom_required", 0)) == 0:
		set_deferred("size", Vector2(size.x, 0))
	host._skill_detail_surface()._clear_activity_stat_popup()
	card["wisdom_help_height"] = _help_room() if help.visible else 0.0
	host._skill_detail_surface()._set_activity_card_expanded(card, card.root, false, true)
	if help.visible:
		await host.get_tree().process_frame
		card["wisdom_help_height"] = _help_room()
		host._skill_detail_surface()._set_activity_card_expanded(card, card.root, false, true)
		await host._skill_detail_surface()._scroll_to_activity_card(str(card.action_id), true, false)

# The height the open note adds to its card. On a rest activity the curved bar
# is below the note, in the room a rest activity keeps under its stat panel.
func _help_room() -> float:
	var room: float = help.get_combined_minimum_size().y + get_theme_constant("separation")
	if ActivityCardStyles.wisdom_opens_above_bar(card.action):
		room += ActivityCardStyles.RECOVERY_INFORMATION_SURROUND
	return room

# An unlock is being played on this card: a padlock is dropping, or the
# activity's own unlock has begun. The bar waits, and the unlock puts it away.
func _card_is_unlocking() -> bool:
	return bool(card.get("unlock_ceremony_pending", false)) or bool(card.get("unlock_ceremony_active", false)) or bool(card.get("requirement_lock_dismiss_active", false))

# The requirement stands again (locks were set back to wait for a tap, or the
# Wisdom is no longer there): the bar comes back as it was.
func _restore_requirement() -> void:
	requirement_retracted = false
	z_index = 300
	caption_row.modulate.a = 1.0
	(get_child(0) as Button).disabled = false
	visible = not reward_collapsed
	call_deferred("_apply_retraction", 0.0)

# A card that is out of view takes the state of its bar at once: the motion is
# for a bar that is put away while the player looks at it. Only for an activity
# that is still locked and has nothing being played on its card: an unlock
# keeps its own way of putting the bar away.
func settle_now() -> void:
	if int(card.action.get("wisdom_required", 0)) <= 0 or not unlock_state_initialized:
		return
	if bool(card.get("wisdom_unlock_active", false)) or _card_is_unlocking():
		return
	# A card made ahead of its row has no row yet, and sizes none. One whose row
	# has gone is left as it is.
	var row = card.get("entry")
	if typeof(row) != TYPE_NIL and not is_instance_valid(row):
		return
	if host._activity_unlock_runtime()._is_action_unlocked(str(card.skill_id), card.action):
		return
	var shown: bool = WisdomState.requirement_bar_shown(host, str(card.skill_id), card.action)
	if shown != requirement_retracted:
		return
	requirement_retracted = not shown
	z_index = 300
	caption_row.modulate.a = 1.0
	(get_child(0) as Button).disabled = not shown
	visible = shown and not reward_collapsed
	card.erase("lock_overlay_sync_key")
	_apply_retraction(0.0 if shown else 1.0)

# The bar is put away: its words fade, it slides up behind the card, and the
# card closes the room it took. With stay_locked the activity is still locked by
# something else, so its dimming, chain and padlocks are left as they are.
func play_unlock_transition(finalize_unlock := false, stay_locked := false) -> void:
	if bool(card.get("wisdom_unlock_active", false)) or requirement_retracted:
		return
	card["wisdom_unlock_active"] = true
	help.hide()
	card["wisdom_help_height"] = 0.0
	(get_child(0) as Button).disabled = true
	if not stay_locked and is_instance_valid(card.get("button")):
		card.button.disabled = true
	var shade: Control = card.get("shade")
	var shade_anchor := 1.0
	var shade_bottom := 0.0
	if is_instance_valid(shade):
		shade_anchor = shade.anchor_bottom
		shade_bottom = shade.offset_bottom
		shade.anchor_bottom = 0.0
		shade.offset_bottom = host.ACTION_CARD_HEIGHT - ActivityCardStyles.NORMAL_ACTIVITY_CARD_DEPTH_OFFSET.y
	# The real bar passes behind the art and original rounded progress rail.
	z_index = 149
	unlock_tween = create_tween()
	unlock_tween.tween_property(caption, "modulate:a", 0.0, CAPTION_FADE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	unlock_tween.tween_method(_apply_retraction, 0.0, 1.0, RETRACT_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if not stay_locked:
		unlock_tween.tween_method(_apply_unlock_reveal, 0.0, 1.0, REVEAL_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await unlock_tween.finished
	if is_instance_valid(shade):
		shade.anchor_bottom = shade_anchor
		shade.offset_bottom = shade_bottom
	if finalize_unlock:
		host._activity_unlock_runtime()._finalize_manual_activity_unlock(str(card.skill_id), str(card.action_id))
	requirement_retracted = true
	card["wisdom_unlock_active"] = false
	hide()
	card.erase("lock_overlay_sync_key")
	host._update_ui(0.0, true)

func _apply_retraction(progress: float) -> void:
	card["wisdom_layer_fraction"] = 1.0 - progress
	position.y = host.ACTION_CARD_HEIGHT - ActivityCardStyles.NORMAL_ACTIVITY_CARD_DEPTH_OFFSET.y - ActivityCardStyles.WISDOM_REQUIREMENT_HEIGHT * progress
	var face: Control = card.pop.get_parent()
	face.offset_bottom = host.ACTION_CARD_HEIGHT + ActivityCardStyles.NORMAL_ACTIVITY_CARD_DEPTH_OFFSET.y + ActivityCardStyles.WISDOM_REQUIREMENT_LAYOUT_HEIGHT * (1.0 - progress)
	host._skill_detail_surface()._set_activity_card_expanded(card, card.root, bool(card.get("bonus_expanded", false)), true)
	if not bool(card.root.get_meta("module_ui_collapsed_squeeze", false)):
		card.root.set_meta("module_ui_full_height", card.root.custom_minimum_size.y)
		var entry: Control = card.get("entry")
		if is_instance_valid(entry):
			entry.set_meta("module_ui_full_height", entry.custom_minimum_size.y)

func _apply_unlock_reveal(progress: float) -> void:
	for layer in [card.get("shade"), card.get("lock_overlay", {}).get("root")]:
		if is_instance_valid(layer):
			layer.modulate.a = 1.0 - progress

func _open_source(skill_id: String, action_id: String) -> void:
	host._navigation_shell()._select_skill(skill_id)
	host._skill_detail_surface().call_deferred("_scroll_to_activity_card", action_id, true, true)
