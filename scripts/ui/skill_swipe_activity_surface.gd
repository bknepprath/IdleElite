extends RefCounted

const ActivityCardBorder = preload("res://scripts/ui/activity_card_border.gd")
const ActivityCardDepth = preload("res://scripts/ui/activity_card_depth.gd")
const ActivityCardStyles = preload("res://scripts/ui/activity_card_styles.gd")
const ActivityProgressRail = preload("res://scripts/ui/activity_progress_rail.gd")
const ActionArtUi = preload("res://scripts/ui/action_art_ui.gd")
const BlueGuyChickenBrawlStageClass = preload("res://scripts/ui/blue_guy_chicken_brawl_stage.gd")
const BuildableModules = preload("res://scripts/gameplay/buildable_modules.gd")
const CleanProgressBar = preload("res://scripts/ui/clean_progress_bar.gd")
const FirepitFuelRing = preload("res://scripts/ui/firepit_fuel_ring.gd")
const FirepitWarmthOverlay = preload("res://scripts/ui/firepit_warmth_overlay.gd")
const MobileScrollContainer = preload("res://scripts/ui/mobile_scroll_container.gd")
const ModuleUiRuntime = preload("res://scripts/module_ui/runtime.gd")
const ModuleUtilityCollapseArrow = preload("res://scripts/ui/module_utility_collapse_arrow.gd")
const PageSwitchButtonFace = preload("res://scripts/ui/page_switch_button_face.gd")
const PassiveModuleStyles = preload("res://scripts/ui/passive_module_styles.gd")
const PassiveSerpentineProgressBar = preload("res://scripts/ui/passive_serpentine_progress_bar.gd")
const MasteryState = preload("res://scripts/progression/mastery_state.gd")
const RoundedTextureRect = preload("res://scripts/ui/rounded_texture_rect.gd")
const RoundedCornerCropOverlay = preload("res://scripts/ui/rounded_corner_crop_overlay.gd")
const RecoveryModules = preload("res://scripts/gameplay/recovery_modules.gd")
const SkillIconBadge = preload("res://scripts/ui/skill_icon_badge.gd")
const SkillState = preload("res://scripts/progression/skill_state.gd")

const RECOVERY_WIDE_U_BOTTOM_RISE := 19.333

var host
var real_card_cache_by_skill = {}
var preview_page: Control
var preview_pages = {}
var preview_states = {}
var preview_offset = 0
var preview_module_reveal_token = 0
var preview_prewarm_token = 0
var preview_prewarm_pending = false
var real_card_prewarm_token = 0
var light_preview_card_style_cache = {}
var queue_selection_banner: Control

func _init(host_ref) -> void:
	host = host_ref

func _apply_recovery_progress_rail_shape(bar: ActivityProgressRail, action: Dictionary) -> void:
	if bar == null or not RecoveryModules.has_recovery(action):
		return
	bar.offset_top = -142.0
	bar.offset_bottom = -host.ACTION_PROGRESS_RAIL_INSET
	bar.bottom_radius = host.ACTION_PROGRESS_RAIL_HEIGHT
	bar.bottom_shape = "wide_u"
	bar.wide_u_bottom_rise = RECOVERY_WIDE_U_BOTTOM_RISE
	bar.queue_redraw()
	bar._queue_opportunity_overlay_redraw()


func _apply_recovery_card_depth_shape(depth: ActivityCardDepth, action: Dictionary) -> void:
	if depth == null or not RecoveryModules.has_recovery(action):
		return
	depth.bottom_shape = "wide_u"
	depth.wide_u_bottom_rise = RECOVERY_WIDE_U_BOTTOM_RISE
	depth.queue_redraw()


func _apply_recovery_card_background_shape(bg: Control, action: Dictionary) -> void:
	if bg == null or not RecoveryModules.has_recovery(action):
		return
	var rounded_bg := bg as RoundedTextureRect
	if rounded_bg == null:
		return
	rounded_bg.bottom_shape = "wide_u"
	rounded_bg.wide_u_bottom_rise = RECOVERY_WIDE_U_BOTTOM_RISE
	rounded_bg.queue_redraw()


func _preview_control(value) -> Control:
	if value == null:
		return null
	if typeof(value) != TYPE_OBJECT or not is_instance_valid(value):
		return null
	if value is Control:
		return value as Control
	return null

func _active_preview_page() -> Control:
	return _preview_control(preview_page)

func _active_preview_offset() -> int:
	return preview_offset

func _set_active_preview(page: Control, offset: int) -> void:
	preview_page = page
	preview_offset = offset

func _cancel_preview_prewarm() -> void:
	preview_prewarm_token += 1
	preview_prewarm_pending = false

func _clear_light_preview_style_cache() -> void:
	light_preview_card_style_cache.clear()

func _preview_state_values() -> Array:
	return preview_states.values()

func _navigation_state() -> Dictionary:
	return {
		"skill_swipe_preview_page": preview_page,
		"skill_swipe_preview_pages": preview_pages,
		"skill_swipe_preview_states": preview_states,
		"skill_swipe_preview_offset": preview_offset,
	}

func _apply_navigation_state(state: Dictionary) -> void:
	preview_page = host._state_object_ref(state.get("skill_swipe_preview_page"))
	preview_pages = state.get("skill_swipe_preview_pages", {}) as Dictionary
	preview_states = state.get("skill_swipe_preview_states", {}) as Dictionary
	preview_offset = int(state.get("skill_swipe_preview_offset", 0))

func _update_skill_swipe_preview_states(delta: float, instant: bool) -> void:
	for raw_offset in preview_states.keys():
		var offset = int(raw_offset)
		if preview_page != null and is_instance_valid(preview_page) and offset != preview_offset:
			continue
		_update_skill_swipe_preview_state(preview_states[offset] as Dictionary, delta, instant, false)

func _skill_swipe_previews_need_frame_updates() -> bool:
	return (
		preview_page != null
		and is_instance_valid(preview_page)
		and not host.skill_swipe_tracking
		and not host.skill_swipe_animating
	)

func _update_skill_swipe_preview_state(state: Dictionary, delta: float, instant: bool, update_cards := true) -> void:
	if state == null:
		return
	var page = state.get("page") as Control
	if page == null or not is_instance_valid(page):
		return
	if not bool(state.get("prewarmed", false)):
		_sync_skill_swipe_preview_scroll_state(state)
	var skill_id = str(state.get("skill_id", ""))
	if skill_id.is_empty():
		return
	var xp = SkillState.xp_progress(host.skills, skill_id, host._skill_level(skill_id))
	var xp_label = state.get("xp_label") as Label
	if xp_label != null:
		xp_label.text = host._skill_level_xp_text(skill_id)
	var xp_bar = state.get("xp_bar") as CleanProgressBar
	if xp_bar != null:
		host._apply_xp_progress_bar_theme(xp_bar, host._skill_theme_color(skill_id))
		host._set_bar(xp_bar, float(xp["pct"]), delta, instant)
	var fish_circle = state.get("fish_circle")
	if fish_circle != null:
		host._set_fish_circle_for_skill(fish_circle, skill_id, instant)
	var regen_circle = state.get("regen_circle")
	if regen_circle != null:
		host._set_regen_circle_for_skill(regen_circle, skill_id, instant)
	if not update_cards:
		return
	var preview_cards = state.get("action_cards", []) as Array
	for card in preview_cards:
		var action_card = card as Dictionary
		if action_card == null:
			continue
		var action = action_card.get("action", {}) as Dictionary
		var action_id = str(action.get("id", ""))
		if action_id.is_empty():
			continue
		var unlocked = host._is_action_unlocked(skill_id, action)
		if host._is_passive_action(action):
			_update_passive_card_static_state(action_card, skill_id, action, unlocked)
			continue
		var running = host.running_skill_id == skill_id and host.running_action_id == action_id
		host._fighting_runtime().sync_blue_guy_chicken_brawl_stage_active(action_card, skill_id, action_id, running)
		_update_action_card_static_state(action_card, skill_id, action, unlocked)
		if host._action_has_mastery(action):
			var medal = action_card.get("medal") as TextureRect
			var mastery_level = MasteryState.level(host.mastery, host._action_key(skill_id, action_id))
			host._set_action_card_medal(action_card, medal, mastery_level, instant)
			host._update_action_card_mastery_bar(action_card, skill_id, action_id, delta, instant)
		host._sync_action_art_animation_state(action_card, running)
		host._update_action_card_run_feedback(action_card, skill_id, running, delta, instant)

func _sync_skill_swipe_preview_scroll_state(state: Dictionary) -> void:
	var preview_scroll = state.get("actions_scroll") as ScrollContainer
	if preview_scroll == null or not is_instance_valid(preview_scroll):
		return
	var scroll_value = float(host.detail_actions_scroll.scroll_vertical) if host.detail_actions_scroll != null and is_instance_valid(host.detail_actions_scroll) else 0.0
	var scroll_bar = preview_scroll.get_v_scroll_bar()
	if scroll_bar != null:
		scroll_value = clampf(scroll_value, 0.0, maxf(0.0, scroll_bar.max_value - scroll_bar.page))
	preview_scroll.scroll_vertical = int(round(scroll_value))

func _render_activity_queue_page() -> void:
	var content_width = host._skill_content_width()
	var frame = Control.new()
	frame.name = "ActivityQueueFrame"
	frame.clip_contents = false
	host._apply_skill_column_layout(frame, content_width, 0.0)
	host.skills_content.add_child(frame)

	var page = VBoxContainer.new()
	page.name = "ActivityQueuePage"
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.custom_minimum_size.x = content_width
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 0)
	frame.add_child(page)

	page.add_child(host._navigation_shell()._activity_queue_active_shelf(content_width))
	var divider = Control.new()
	divider.name = "ActivityQueueShelfDivider"
	divider.custom_minimum_size = Vector2(content_width, host.SKILL_DETAIL_ACTIONS_DIVIDER_HEIGHT)
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(divider)

	var actions_clip = Control.new()
	actions_clip.name = "ActivityQueueActionsClip"
	actions_clip.custom_minimum_size.x = content_width
	actions_clip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_clip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	actions_clip.clip_contents = true
	page.add_child(actions_clip)

	host.content_scroll = MobileScrollContainer.new()
	host.content_scroll.name = "ActivityQueueActionsScroll"
	host.content_scroll.clip_contents = true
	host.content_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	host.content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	host.content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	host.content_scroll.set_pull_resistance_enabled(true)
	host.content_scroll.gui_input.connect(Callable(host, "_on_pinned_activities_action_scroll_input"))
	actions_clip.add_child(host.content_scroll)

	var stack = VBoxContainer.new()
	stack.custom_minimum_size.x = content_width
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 0)
	host.content_scroll.add_child(stack)

	var shelf_clearance = Control.new()
	shelf_clearance.name = "ActivityQueueShelfClearance"
	shelf_clearance.custom_minimum_size = Vector2(content_width, host.SKILL_DETAIL_ACTIONS_TOP_SPACER_HEIGHT)
	shelf_clearance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(shelf_clearance)
	var shelf = VBoxContainer.new()
	shelf.name = "ActivityQueueShelf"
	shelf.custom_minimum_size = Vector2(content_width, 0)
	shelf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shelf.add_theme_constant_override("separation", 34)
	shelf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var queue_index = 0
	for raw_key in host._activity_queue_runtime().get_activity_queue():
		var module_key = ModuleUiRuntime.normalize(raw_key)
		if module_key.is_empty():
			continue
		var module_root = host._build_queue_activities_module(module_key, content_width)
		if module_root == null:
			continue
		module_root.set_meta("module_ui_pinned_page_copy", true)
		module_root.set_meta("module_ui_force_expanded", true)
		module_root.set_meta("module_ui_key", module_key)
		host._skill_detail_surface()._remove_module_collapse_zones(module_root)
		shelf.add_child(module_root)
		queue_index += 1
	if shelf.get_child_count() <= 0:
		shelf.queue_free()
	else:
		stack.add_child(shelf)
	var queue_has_items = host._activity_queue_runtime().get_activity_queue().size() > 0
	var queue_button_label = "Adjust Queue" if queue_has_items else "Set Queue"
	stack.add_child(_activity_queue_list_button(content_width, "ActivityQueueSetQueueButton", queue_button_label, Color("#47b7d8")))
	if queue_has_items:
		stack.add_child(_activity_queue_list_button(content_width, "ActivityQueueClearQueueButton", "Clear Queue", Color("#d75545")))
	else:
		stack.add_child(_activity_queue_empty_description(content_width))
	var bottom_spacer = Control.new()
	bottom_spacer.name = "ActivityQueueBottomSpacer"
	bottom_spacer.custom_minimum_size = Vector2(0, host._skills_content_bottom_inset_for_screen() + 190.0)
	bottom_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(bottom_spacer)
	host._navigation_shell()._add_pinned_active_shelf_shadow_overlay()


func _activity_queue_list_button(content_width: float, node_name: String, label_text: String, fill: Color) -> Control:
	var holder := MarginContainer.new()
	holder.name = "ActivityQueueListButtonRow"
	holder.custom_minimum_size = Vector2(content_width, 420)
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.add_theme_constant_override("margin_left", 220)
	holder.add_theme_constant_override("margin_right", 220)
	holder.add_theme_constant_override("margin_top", 38)
	holder.add_theme_constant_override("margin_bottom", 38)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var button := Button.new()
	button.name = node_name
	button.text = label_text
	button.custom_minimum_size = Vector2(0, 344)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	button.clip_contents = false
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_font_override("font", host.app_bold_font)
	button.add_theme_font_size_override("font_size", 88)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_oover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", host._module_utility_button_style(fill, false, false))
	button.add_theme_stylebox_override("oover", host._module_utility_button_style(fill.lightened(0.06), false, false))
	button.add_theme_stylebox_override("pressed", host._module_utility_button_style(fill, true, false))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if node_name == "ActivityQueueSetQueueButton":
		button.pressed.connect(_on_activity_queue_set_pressed)
	elif node_name == "ActivityQueueClearQueueButton":
		button.pressed.connect(_on_activity_queue_clear_pressed)
	holder.add_child(button)
	return holder


func _activity_queue_empty_description(content_width: float) -> Control:
	var holder := MarginContainer.new()
	holder.name = "ActivityQueueEmptyDescription"
	holder.custom_minimum_size = Vector2(content_width, 470)
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.add_theme_constant_override("margin_left", 160)
	holder.add_theme_constant_override("margin_right", 160)
	holder.add_theme_constant_override("margin_top", 18)
	holder.add_theme_constant_override("margin_bottom", 36)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label: Label = host._label(
		"Tap Set Queue, then choose activities from the skills list. Start any queued activity here and your character will try the queue in order, moving down when stamina runs low.",
		58,
		host.COLOR_INK,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	label.name = "ActivityQueueEmptyDescriptionLabel"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.add_theme_color_override("font_outline_color", Color.WHITE)
	label.add_theme_constant_override("outline_size", 8)
	label.add_theme_constant_override("line_spacing", 8)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(label)
	return holder


func _on_activity_queue_set_pressed() -> void:
	_enter_queue_selection_mode()


func _on_activity_queue_clear_pressed() -> void:
	host._activity_queue_runtime().set_activity_queue([])


func _toggle_activity_queue_entry(module_key: String) -> bool:
	var normalized_key: String = ModuleUiRuntime.normalize(module_key)
	if normalized_key.is_empty():
		return false
	if host._activity_queue_runtime().is_activity_queued(normalized_key):
		return host._activity_queue_runtime().remove_activity_from_queue(normalized_key)
	return host._activity_queue_runtime().add_activity_to_queue(normalized_key)


func _activity_queue_module_key_for_card(card: Dictionary) -> String:
	if card.is_empty():
		return ""
	var card_key := str(card.get("card_key", ""))
	if card_key.begins_with("pinned_page:"):
		var pinned_key: String = ModuleUiRuntime.normalize(card_key.substr("pinned_page:".length()))
		if not pinned_key.is_empty():
			return pinned_key
	if card_key.begins_with("queue_page:"):
		var queue_key: String = ModuleUiRuntime.normalize(card_key.substr("queue_page:".length()))
		if not queue_key.is_empty():
			return queue_key
	var pop: Control = host._valid_control_ref(card.get("pop", null))
	if pop != null:
		var pop_key: String = ModuleUiRuntime.normalize(pop.get_meta("module_ui_key", ""))
		if not pop_key.is_empty():
			return pop_key
	if bool(card.get("is_fishing_area", false)):
		var area_def := card.get("area_def", {}) as Dictionary
		if not area_def.is_empty():
			return ModuleUiRuntime.fishing_area(host.fishing_runtime.area_module_key(str(card.get("skill_id", "fishing")), area_def))
	var skill_id := str(card.get("skill_id", ""))
	var action_id := str(card.get("action_id", ""))
	if not skill_id.is_empty() and not action_id.is_empty():
		return ModuleUiRuntime.action(skill_id, action_id, host.FISHING_ACTION_ID_ALIASES)
	return ""


func _queue_selection_toggle_from_card(card: Dictionary) -> bool:
	var module_key := _activity_queue_module_key_for_card(card)
	if module_key.is_empty():
		return false
	if not _toggle_activity_queue_entry(module_key):
		return false
	host._button_press_runtime().play_default_button_sfx()
	return true


func _enter_queue_selection_mode() -> void:
	host.queue_selection_mode = true
	host.skills_utility_return_screen = "queue"
	host.skills_utility_return_skill_id = host.selected_skill_id
	if host.current_screen == "queue" or host.current_screen == "pinned":
		host.top_level_nav_locked_until_msec = 0
		host.current_screen = "menu"
		host._render_screen()
	elif host.current_screen == "skill":
		_refresh_activity_queue_visuals()
	elif host.skills_content != null and is_instance_valid(host.skills_content):
		host._render_screen()
	_sync_queue_selection_banner()
	_refresh_activity_queue_visuals()


func _finish_queue_selection_mode() -> void:
	host.queue_selection_mode = false
	_sync_queue_selection_banner()
	host._begin_direct_skill_nav_cover()
	host.current_screen = "queue"
	host._render_screen()


func _sync_queue_selection_banner() -> void:
	if not host.queue_selection_mode:
		if queue_selection_banner != null and is_instance_valid(queue_selection_banner):
			queue_selection_banner.queue_free()
		queue_selection_banner = null
		return
	if queue_selection_banner != null and is_instance_valid(queue_selection_banner):
		return
	var banner := PanelContainer.new()
	banner.name = "QueueSelectionBanner"
	banner.set_anchors_preset(Control.PRESET_TOP_WIDE)
	banner.offset_left = 22.0
	banner.offset_right = -22.0
	banner.offset_top = 22.0
	banner.offset_bottom = 142.0
	banner.z_index = host.CHAT_UI_Z + 120
	banner.z_as_relative = false
	banner.mouse_filter = Control.MOUSE_FILTER_STOP
	banner.add_theme_stylebox_override("panel", host._module_utility_button_style(Color("#47b7d8"), false, true))
	host.add_child(banner)
	queue_selection_banner = banner

	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 42)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(row)
	var title: Label = host._label("QUEUE SELECTION MODE", 48, host.COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(title)


func _refresh_activity_queue_visuals() -> void:
	_sync_queue_overlays_for_visible_cards()
	if host.current_screen == "queue" and not host.screen_render_in_progress:
		host._render_screen()


func _add_activity_queue_number_overlay(overlay_host: Control, number: int, module_key: String) -> void:
	if overlay_host == null or not is_instance_valid(overlay_host) or number <= 0:
		return
	var overlay := PanelContainer.new()
	overlay.name = "ActivityQueueNumberOverlay"
	overlay.anchor_left = 0.5
	overlay.anchor_right = 0.5
	overlay.anchor_top = 0.5
	overlay.anchor_bottom = 0.5
	overlay.offset_left = -88.0
	overlay.offset_right = 88.0
	overlay.offset_top = -88.0
	overlay.offset_bottom = 88.0
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 260
	overlay.add_theme_stylebox_override("panel", _activity_queue_overlay_style())
	overlay_host.add_child(overlay)
	var label: Label = host._label(str(number), 108, host.COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_outline_color", Color.WHITE)
	label.add_theme_constant_override("outline_size", 0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(label)
	overlay.set_meta("activity_queue_overlay_key", module_key)
	overlay.set_meta("activity_queue_overlay_number", number)


func _activity_queue_overlay_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.border_color = host.COLOR_INK
	style.set_border_width_all(10)
	style.corner_radius_top_left = 999
	style.corner_radius_top_right = 999
	style.corner_radius_bottom_left = 999
	style.corner_radius_bottom_right = 999
	return style


func _sync_queue_overlays_for_visible_cards() -> void:
	for raw_card in host.action_cards.values():
		if typeof(raw_card) != TYPE_DICTIONARY:
			continue
		var card := raw_card as Dictionary
		var overlay_host := _activity_queue_overlay_host_for_card(card)
		if overlay_host == null:
			continue
		var module_key := _activity_queue_module_key_for_card(card)
		if module_key.is_empty():
			continue
		_sync_activity_queue_overlay_for_host(overlay_host, module_key)


func _activity_queue_overlay_host_for_card(card: Dictionary) -> Control:
	if card.is_empty():
		return null
	if bool(card.get("is_fishing_area", false)):
		var area_host: Control = host._valid_control_ref(card.get("queue_overlay_host", null))
		if area_host != null:
			return area_host
	return host._valid_control_ref(card.get("pop", null))


func _sync_activity_queue_overlay_for_host(overlay_host: Control, module_key: String) -> void:
	if overlay_host == null or not is_instance_valid(overlay_host):
		return
	var existing_overlays: Array[Control] = []
	for child in overlay_host.get_children():
		var control := child as Control
		if control != null and control.name == "ActivityQueueNumberOverlay":
			existing_overlays.append(control)
	var queue_index: int = host._activity_queue_runtime().get_queue_index(module_key)
	if not host.queue_selection_mode or queue_index < 0:
		for overlay in existing_overlays:
			overlay.queue_free()
		return
	var desired_number: int = queue_index + 1
	var kept_overlay: Control = null
	for overlay in existing_overlays:
		var overlay_key: String = ModuleUiRuntime.normalize(overlay.get_meta("activity_queue_overlay_key", ""))
		var overlay_number := int(overlay.get_meta("activity_queue_overlay_number", -1))
		if kept_overlay == null and overlay_key == module_key and overlay_number == desired_number:
			kept_overlay = overlay
		else:
			overlay.queue_free()
	if kept_overlay != null:
		return
	_add_activity_queue_number_overlay(overlay_host, desired_number, module_key)




func _update_action_card_static_state(card: Dictionary, skill_id: String, action: Dictionary, unlocked: bool) -> void:
	host._skill_detail_surface()._sync_module_action_zones_for_card(card, ModuleUiRuntime.action_for_record(skill_id, action, host.FISHING_ACTION_ID_ALIASES))
	var xp_label = card.get("xp") as Label
	var stamina_label = card.get("stamina") as Label
	var time_value_label = card.get("time") as Label
	var success_label = card.get("success") as Label
	if (
		xp_label == null or not is_instance_valid(xp_label)
		or stamina_label == null or not is_instance_valid(stamina_label)
		or time_value_label == null or not is_instance_valid(time_value_label)
		or success_label == null or not is_instance_valid(success_label)
	):
		return
	var ceremony_active = bool(card.get("unlock_ceremony_pending", false)) or bool(card.get("unlock_ceremony_active", false))
	var action_id = str(action.get("id", card.get("action_id", "")))
	var lock_blocks_button = (not unlocked) or ceremony_active or bool(card.get("unlock_ready_pending", false)) or host._action_has_pending_unlock_readiness(action_id)
	var button = card.get("button") as Button
	if button != null:
		host._set_base_button_disabled_if_changed(button, lock_blocks_button)
		host._set_canvas_item_visible_if_changed(button, true)
		host._set_canvas_item_modulate_if_changed(button, Color(1, 1, 1, 0))
	var static_refresh_key = host._action_card_static_refresh_key(skill_id, action, unlocked, ceremony_active)
	var xp_reward_parts = host._action_xp_reward_parts_for_display(skill_id, action)
	var xp_text = "+%s" % GameFormatting.info_chip_number(float(host._action_xp_reward_total(xp_reward_parts)))
	var show_stamina_stat = host._action_shows_stamina_stat(skill_id, action)
	var stamina_text = host._action_stamina_stat_text(skill_id, action)
	var time_label = "FILL" if host._action_runtime()._fishing_batch_soak_active(skill_id) and not host._is_event_action(action) else "TIME"
	var time_text = "%ss" % GameFormatting.info_chip_number(host._action_runtime()._action_cycle_seconds(skill_id, action))
	var success_text = "%s%%" % GameFormatting.info_chip_number(host._action_runtime()._success_chance(skill_id, action))
	if host._convergence_runtime()._is_convergence_action(action):
		var module_id = str(action.get("id", host.CONVERGENCE_DEFAULT_MODULE_ID))
		xp_text = "+%s ALL" % GameFormatting.info_chip_number(float(host._convergence_runtime()._convergence_current_xp(module_id)))
		stamina_text = ""
		time_label = "CYCLE"
		time_text = "%ss" % GameFormatting.info_chip_number(host._convergence_runtime()._convergence_total_cycle_seconds(action))
		success_text = ""
	if not static_refresh_key.is_empty() and str(card.get("action_card_static_refresh_key", "")) == static_refresh_key:
		host._set_label_text_if_changed(xp_label, xp_text)
		host._set_label_text_if_changed(stamina_label, stamina_text)
		host._set_label_text_if_changed(time_value_label, time_text)
		host._set_label_text_if_changed(success_label, success_text)
		host._skill_detail_surface()._sync_action_stat_chip_title(xp_label, "XP")
		host._skill_detail_surface()._sync_action_stat_chip_title(stamina_label, "STAM" if show_stamina_stat else "")
		host._skill_detail_surface()._sync_action_stat_chip_title(time_value_label, time_label)
		host._skill_detail_surface()._sync_action_stat_chip_title(success_label, "" if host._convergence_runtime()._is_convergence_action(action) else "RATE")
		host._skill_detail_surface()._sync_activity_lock_overlay(card, action, unlocked)
		host._sync_activity_card_title_layer(card, unlocked)
		var cached_stat_boxes = card.get("stat_boxes", {}) as Dictionary
		host._sync_xp_reward_chips(cached_stat_boxes.get("xp") as Control, xp_label, skill_id, action)
		host._sync_locked_activity_preview_presence(card, skill_id, action)
		return
	if not static_refresh_key.is_empty():
		card["action_card_static_refresh_key"] = static_refresh_key
	host._set_label_text_if_changed(xp_label, xp_text)
	card["last_xp_text"] = xp_text
	host._set_label_text_if_changed(stamina_label, stamina_text)
	card["last_stamina_text"] = stamina_text
	host._set_label_text_if_changed(time_value_label, time_text)
	card["last_time_text"] = time_text
	host._set_label_text_if_changed(success_label, success_text)
	card["last_success_text"] = success_text
	host._skill_detail_surface()._sync_action_stat_chip_title(xp_label, "XP")
	host._skill_detail_surface()._sync_action_stat_chip_title(stamina_label, "STAM" if show_stamina_stat else "")
	host._skill_detail_surface()._sync_action_stat_chip_title(time_value_label, time_label)
	host._skill_detail_surface()._sync_action_stat_chip_title(success_label, "" if host._convergence_runtime()._is_convergence_action(action) else "RATE")
	var stat_theme_color = host._skill_theme_color(skill_id)
	var stat_boxes = card.get("stat_boxes", {}) as Dictionary
	host._sync_xp_reward_chips(stat_boxes.get("xp") as Control, xp_label, skill_id, action)
	host._sync_action_stat_chip_label_style(xp_label, host._action_stat_chip_buffed(skill_id, action, "xp"), stat_theme_color, stat_boxes.get("xp") as Control)
	host._sync_action_stat_chip_label_style(stamina_label, host._action_stat_chip_buffed(skill_id, action, "stamina"), stat_theme_color, stat_boxes.get("stamina") as Control)
	host._sync_action_stat_chip_label_style(time_value_label, host._action_stat_chip_buffed(skill_id, action, "time"), stat_theme_color, stat_boxes.get("time") as Control)
	host._sync_action_stat_chip_label_style(success_label, host._action_stat_chip_buffed(skill_id, action, "success"), stat_theme_color, stat_boxes.get("success") as Control)
	var stamina_box = stat_boxes.get("stamina") as Control
	if host._convergence_runtime()._is_convergence_action(action):
		if stamina_box != null:
			stamina_box.visible = false
		var success_box = stat_boxes.get("success") as Control
		if success_box != null:
			success_box.visible = false
	elif host._is_fishing_event_action(skill_id, action):
		if stamina_box != null:
			stamina_box.visible = false
	elif not show_stamina_stat:
		if stamina_box != null:
			stamina_box.visible = false
	elif stamina_box != null:
		stamina_box.visible = true
	host._hub_surface()._sync_hub_mission_badge(card, skill_id, action, unlocked)
	host._skill_detail_surface()._sync_activity_lock_overlay(card, action, unlocked)
	if host._convergence_runtime()._is_convergence_action(action):
		host._sync_convergence_card_static_state(card, action, unlocked)
	host._sync_activity_card_title_layer(card, unlocked)
	var shade = card.get("shade") as Panel
	if shade == null and ((not unlocked) or ceremony_active):
		shade = ActivityCardStyles.ensure_activity_card_shade(card, 0.50)
	if shade != null:
		host._set_canvas_item_visible_if_changed(shade, (not unlocked) or ceremony_active)
		if not unlocked:
			host._set_canvas_item_modulate_if_changed(shade, Color.WHITE)
		elif not ceremony_active:
			host._set_canvas_item_modulate_if_changed(shade, Color(1, 1, 1, 0))
	if card.get("last_unlocked", null) == unlocked:
		return
	if button != null:
		host._set_base_button_disabled_if_changed(button, lock_blocks_button)
		host._set_canvas_item_visible_if_changed(button, true)
		host._set_canvas_item_modulate_if_changed(button, Color(1, 1, 1, 0))
	var bg = card.get("bg") as CanvasItem
	if bg != null:
		host._set_canvas_item_modulate_if_changed(bg, Color.WHITE)
	var art_panel = card.get("art_panel") as CanvasItem
	if art_panel != null:
		host._set_canvas_item_modulate_if_changed(art_panel, Color.WHITE)
	var border = card.get("border") as ActivityCardBorder
	if border != null:
		if str(card.get("passive_border_state", "")) != "default":
			card["passive_border_state"] = "default"
			border.border_color = host.COLOR_INK
			border.border_width = 8.0
			border.queue_redraw()
	card["last_unlocked"] = unlocked
	if host._convergence_runtime()._is_convergence_action(action):
		host._sync_convergence_card_static_state(card, action, unlocked)
	host._sync_locked_activity_preview_presence(card, skill_id, action)




func _on_action_card_input(event: InputEvent, skill_id: String, action_id: String, source: Control) -> void:
	var card = host._action_card_for_input_source(skill_id, action_id, source)
	if card.is_empty():
		return
	var key = str(card.get("card_key", host._action_key(skill_id, action_id)))
	var action = host._action_data(skill_id, action_id)
	if action.is_empty():
		return
	var unlocked = host._is_action_unlocked(skill_id, action)
	if not unlocked or host._action_info_chips_blocked_by_lock(card):
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var event_positions = host._action_card_event_positions(event, source)
		if not host._positions_inside_detail_actions_viewport(event_positions):
			if not event.pressed and host.action_card_press_key == key:
				host.action_card_press_key = ""
				host.action_card_press_stat_kind = ""
				host.action_card_press_dragged = false
				_release_action_card_3d_press(key)
			return
		if event.pressed:
			var stat_kind = host._activity_stat_kind_from_positions(card, event_positions)
			if stat_kind.is_empty() and host._action_card_medal_hit_from_positions(card, event_positions):
				stat_kind = host.ACTION_CARD_MEDAL_PRESS_KIND
			if not stat_kind.is_empty():
				host._route_skill_swipe_button_input(event, source)
				host.action_card_press_key = key
				host.action_card_press_position = host._first_event_position(event_positions)
				host.action_card_press_stat_kind = stat_kind
				host.action_card_press_dragged = false
				host.get_viewport().set_input_as_handled()
				return
			host.action_card_press_key = key
			host.action_card_press_position = host._first_event_position(event_positions)
			host.action_card_press_stat_kind = ""
			host.action_card_press_dragged = false
			_queue_action_card_3d_press(key)
			host._route_skill_swipe_button_input(event, source)
			host.get_viewport().set_input_as_handled()
		elif host.action_card_press_key == key and not host._skill_swipe_suppresses_button_action():
			var stat_kind = host.action_card_press_stat_kind
			var close_to_press = host._event_positions_close_to_press(event_positions)
			if not stat_kind.is_empty():
				close_to_press = host._event_positions_inside_activity_stat_box(card, stat_kind, event_positions)
			host.action_card_press_key = ""
			host.action_card_press_stat_kind = ""
			_release_action_card_3d_press(key)
			if close_to_press and not host.action_card_press_dragged:
				if BuildableModules.is_buildable(action) and not BuildableModules.is_built(host.built_modules, skill_id, action, Callable(host, "_action_key")):
					host._start_action_from_card_tap(skill_id, action_id, key)
					host._cancel_skill_swipe_feedback(false)
				elif stat_kind == host.ACTION_CARD_MEDAL_PRESS_KIND:
					host._play_action_card_medal_tap_ceremony(card)
				elif not stat_kind.is_empty():
					host._toggle_activity_stat_popup_for_card(card, skill_id, action_id, stat_kind)
				else:
					host._start_action_from_card_tap(skill_id, action_id, key)
					host._cancel_skill_swipe_feedback(false)
			host.action_card_press_dragged = false
			host.get_viewport().set_input_as_handled()
		elif host.action_card_press_key == key:
			host.action_card_press_key = ""
			host.action_card_press_stat_kind = ""
			host.action_card_press_dragged = false
			_release_action_card_3d_press(key)
			if host.skill_swipe_tracking:
				host._route_skill_swipe_button_input(event, source)
			host.get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		if host.skill_swipe_tracking:
			host._route_skill_swipe_button_input(event, source)
			host.get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		var event_positions = host._action_card_event_positions(event, source)
		if not host._positions_inside_detail_actions_viewport(event_positions):
			if not event.pressed and host.action_card_press_key == key:
				host.action_card_press_key = ""
				host.action_card_press_stat_kind = ""
				host.action_card_press_dragged = false
				_release_action_card_3d_press(key)
			return
		if event.pressed:
			var stat_kind = host._activity_stat_kind_from_positions(card, event_positions)
			if stat_kind.is_empty() and host._action_card_medal_hit_from_positions(card, event_positions):
				stat_kind = host.ACTION_CARD_MEDAL_PRESS_KIND
			if not stat_kind.is_empty():
				host._route_skill_swipe_button_input(event, source)
				host.action_card_press_key = key
				host.action_card_press_position = host._first_event_position(event_positions)
				host.action_card_press_stat_kind = stat_kind
				host.action_card_press_dragged = false
				host.get_viewport().set_input_as_handled()
				return
			host.action_card_press_key = key
			host.action_card_press_position = host._first_event_position(event_positions)
			host.action_card_press_stat_kind = ""
			host.action_card_press_dragged = false
			_queue_action_card_3d_press(key)
			host._route_skill_swipe_button_input(event, source)
			host.get_viewport().set_input_as_handled()
		elif host.action_card_press_key == key and not host._skill_swipe_suppresses_button_action():
			var stat_kind = host.action_card_press_stat_kind
			var close_to_press = host._event_positions_close_to_press(event_positions)
			if not stat_kind.is_empty():
				close_to_press = host._event_positions_inside_activity_stat_box(card, stat_kind, event_positions)
			host.action_card_press_key = ""
			host.action_card_press_stat_kind = ""
			_release_action_card_3d_press(key)
			if close_to_press and not host.action_card_press_dragged:
				if BuildableModules.is_buildable(action) and not BuildableModules.is_built(host.built_modules, skill_id, action, Callable(host, "_action_key")):
					host._start_action_from_card_tap(skill_id, action_id, key)
					host._cancel_skill_swipe_feedback(false)
				elif stat_kind == host.ACTION_CARD_MEDAL_PRESS_KIND:
					host._play_action_card_medal_tap_ceremony(card)
				elif not stat_kind.is_empty():
					host._toggle_activity_stat_popup_for_card(card, skill_id, action_id, stat_kind)
				else:
					host._start_action_from_card_tap(skill_id, action_id, key)
					host._cancel_skill_swipe_feedback(false)
			host.action_card_press_dragged = false
			host.get_viewport().set_input_as_handled()
		elif host.action_card_press_key == key:
			host.action_card_press_key = ""
			host.action_card_press_stat_kind = ""
			host.action_card_press_dragged = false
			_release_action_card_3d_press(key)
			if host.skill_swipe_tracking:
				host._route_skill_swipe_button_input(event, source)
			host.get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if host.skill_swipe_tracking:
			host._route_skill_swipe_button_input(event, source)
			host.get_viewport().set_input_as_handled()




func _build_skill_swipe_preview_page(skill_id: String, offset = 0) -> Control:
	var content_width = host._skill_content_width()
	var actions_width = content_width
	var state = {
		"skill_id": skill_id,
		"action_cards": [],
		"fishing_built_modules": [],
		"prewarmed": false,
		"proxy_oandoff": host.SKILL_SWIPE_LIGHT_PREVIEW_ENABLED,
	}
	var page = VBoxContainer.new()
	state["page"] = page
	page.set_meta("skill_swipe_preview_state", state)
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.custom_minimum_size.x = actions_width
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 0)
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.z_index = 10

	var header = PanelContainer.new()
	header.custom_minimum_size = Vector2(0, host.SKILL_DETAIL_HEADER_HEIGHT)
	header.custom_minimum_size.x = content_width
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_stylebox_override("panel", host._skill_detail_shelf_style(skill_id, false))
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(header)

	var header_body = Control.new()
	header_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	header_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(header_body)
	host._add_skill_detail_shelf_background(header_body, skill_id, content_width)
	state["header_body"] = header_body
	host._add_activity_back_arrow(header_body, false)

	var xp = SkillState.xp_progress(host.skills, skill_id, host._skill_level(skill_id))
	if host.SKILL_SWIPE_LIGHT_PREVIEW_HEADER_ENABLED:
		var light_margin = MarginContainer.new()
		light_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		light_margin.add_theme_constant_override("margin_left", 66)
		light_margin.add_theme_constant_override("margin_right", 46)
		light_margin.add_theme_constant_override("margin_top", 88)
		light_margin.add_theme_constant_override("margin_bottom", host.SKILL_DETAIL_HEADER_MARGIN_BOTTOM)
		light_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		header_body.add_child(light_margin)

		var light_row = HBoxContainer.new()
		light_row.add_theme_constant_override("separation", 66)
		light_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		light_margin.add_child(light_row)

		var light_left = HBoxContainer.new()
		light_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		light_left.alignment = BoxContainer.ALIGNMENT_CENTER
		light_left.add_theme_constant_override("separation", host.SKILL_DETAIL_LEFT_SEPARATION)
		light_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
		light_row.add_child(light_left)

		light_left.add_child(SkillIconBadge.detail_icon(host, skill_id))

		var light_stack = VBoxContainer.new()
		light_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		light_stack.alignment = BoxContainer.ALIGNMENT_CENTER
		light_stack.add_theme_constant_override("separation", host.SKILL_DETAIL_TEXT_SEPARATION)
		light_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
		light_left.add_child(light_stack)
		light_stack.add_child(host._label(host._skill_name(skill_id), host._skill_detail_title_font_size(skill_id), host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT))
		var light_xp_label = host._label(host._skill_level_xp_text(skill_id), host.SKILL_DETAIL_XP_FONT_SIZE, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
		light_stack.add_child(light_xp_label)
		state["xp_label"] = light_xp_label
		var light_xp_bar = host._skill_detail_xp_bar(skill_id, float(xp["pct"]))
		light_stack.add_child(light_xp_bar)
		state["xp_bar"] = light_xp_bar
		light_row.add_child(_skill_swipe_light_preview_header_circle(skill_id))
	else:
		var header_margin = MarginContainer.new()
		header_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		header_margin.add_theme_constant_override("margin_left", 66)
		header_margin.add_theme_constant_override("margin_right", 46)
		header_margin.add_theme_constant_override("margin_top", 88)
		header_margin.add_theme_constant_override("margin_bottom", host.SKILL_DETAIL_HEADER_MARGIN_BOTTOM)
		header_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		header_body.add_child(header_margin)

		var header_row = HBoxContainer.new()
		header_row.add_theme_constant_override("separation", 66)
		header_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		header_margin.add_child(header_row)

		var left_block = HBoxContainer.new()
		left_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		left_block.alignment = BoxContainer.ALIGNMENT_CENTER
		left_block.add_theme_constant_override("separation", host.SKILL_DETAIL_LEFT_SEPARATION)
		left_block.mouse_filter = Control.MOUSE_FILTER_IGNORE
		header_row.add_child(left_block)

		var summary_icon = SkillIconBadge.detail_icon(host, skill_id)
		left_block.add_child(summary_icon)

		var title_stack = VBoxContainer.new()
		title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_stack.alignment = BoxContainer.ALIGNMENT_CENTER
		title_stack.add_theme_constant_override("separation", host.SKILL_DETAIL_TEXT_SEPARATION)
		title_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
		left_block.add_child(title_stack)
		title_stack.add_child(host._label(host._skill_name(skill_id), host._skill_detail_title_font_size(skill_id), host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT))
		var xp_label = host._label(host._skill_level_xp_text(skill_id), host.SKILL_DETAIL_XP_FONT_SIZE, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
		title_stack.add_child(xp_label)
		state["xp_label"] = xp_label
		var xp_bar = host._skill_detail_xp_bar(skill_id, float(xp["pct"]))
		title_stack.add_child(xp_bar)
		state["xp_bar"] = xp_bar

		if host._fishing_rework_active_for_skill(skill_id):
			var fish_circle = host.FishCircle.new()
			fish_circle.custom_minimum_size = Vector2(552, 552)
			fish_circle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			fish_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
			header_row.add_child(fish_circle)
			state["fish_circle"] = fish_circle
			host._set_fish_circle_for_skill(fish_circle, skill_id, true)
		else:
			var regen_circle = host.RegenCircle.new()
			regen_circle.custom_minimum_size = Vector2(552, 552)
			regen_circle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			regen_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
			regen_circle.set_dark_mode(host.dark_mode_enabled)
			regen_circle.set_theme_color(host._skill_theme_color(skill_id))
			regen_circle.set_regen_ring_color(host._stamina_regen_circle_color(skill_id))
			header_row.add_child(regen_circle)
			state["regen_circle"] = regen_circle
			host._set_regen_circle_for_skill(regen_circle, skill_id, true)

	var divider = Control.new()
	divider.custom_minimum_size = Vector2(0, host.SKILL_DETAIL_ACTIONS_DIVIDER_HEIGHT)
	divider.custom_minimum_size.x = content_width
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(divider)

	var actions_clip = Control.new()
	actions_clip.name = "DetailActionsClip"
	actions_clip.custom_minimum_size.x = actions_width
	actions_clip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_clip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	actions_clip.clip_contents = true
	actions_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(actions_clip)

	var preview_scroll = MobileScrollContainer.new()
	preview_scroll.custom_minimum_size.x = actions_width
	preview_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	preview_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	preview_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	preview_scroll.clip_contents = true
	preview_scroll.set_pull_resistance_enabled(true)
	preview_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	actions_clip.add_child(preview_scroll)
	state["actions_scroll"] = preview_scroll
	state["modules_root"] = preview_scroll

	var preview_stack = VBoxContainer.new()
	preview_stack.custom_minimum_size.x = actions_width
	preview_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_stack.add_theme_constant_override("separation", 56)
	preview_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_scroll.add_child(preview_stack)

	var top_spacer = Control.new()
	top_spacer.name = "DetailActionsTopSpacer"
	top_spacer.custom_minimum_size = Vector2(0, host.SKILL_DETAIL_ACTIONS_TOP_SPACER_HEIGHT)
	top_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_stack.add_child(top_spacer)

	if host.SKILL_SWIPE_LIGHT_PREVIEW_ENABLED:
		_render_light_skill_swipe_preview_entries(preview_stack, skill_id, content_width, actions_width, state)
	elif host._fishing_rework_active_for_skill(skill_id):
		host._fishing_ui_surface()._render_fishing_area_modules_preview(preview_stack, content_width, state)
	else:
		var preview_entry_y = 0.0
		var preview_index = 0
		var pending_placeholder_height = 0.0
		for entry in _preview_detail_entries_for_skill(skill_id):
			var entry_data = entry as Dictionary
			var entry_height = _skill_swipe_preview_entry_height(entry_data)
			if not _skill_swipe_preview_should_build_entry(preview_entry_y, entry_height, preview_index):
				pending_placeholder_height += (
					entry_height
					if pending_placeholder_height <= 1.0
					else host.DETAIL_LAZY_STACK_SEPARATION + entry_height
				)
				preview_entry_y += entry_height + host.DETAIL_LAZY_STACK_SEPARATION
				preview_index += 1
				continue
			pending_placeholder_height = _flush_skill_swipe_preview_placeholder(preview_stack, actions_width, pending_placeholder_height)
			if str(entry_data.get("kind", "")) == "thieving_heist":
				var heist = entry_data.get("heist", {}) as Dictionary
				var heist_root = host._build_thieving_heist_card(heist, actions_width, true)
				heist_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
				preview_stack.add_child(heist_root)
				preview_entry_y += entry_height + host.DETAIL_LAZY_STACK_SEPARATION
				preview_index += 1
				continue
			var action = entry_data.get("action", {}) as Dictionary
			var card_result = host._passive_firepit_surface()._build_passive_module_card(skill_id, action, content_width, false) if host._is_passive_action(action) else _skill_swipe_preview_action_card(skill_id, action, content_width)
			(card_result["card"] as Dictionary)["preview_only"] = true
			preview_stack.add_child(card_result["root"])
			(state["action_cards"] as Array).append(card_result["card"])
			preview_entry_y += entry_height + host.DETAIL_LAZY_STACK_SEPARATION
			preview_index += 1
		pending_placeholder_height = _flush_skill_swipe_preview_placeholder(preview_stack, actions_width, pending_placeholder_height)
	var scroll_bottom_spacer = Control.new()
	scroll_bottom_spacer.name = "DetailActionsBottomSpacer"
	scroll_bottom_spacer.custom_minimum_size = Vector2.ZERO
	scroll_bottom_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_stack.add_child(scroll_bottom_spacer)
	if offset != 0:
		preview_states[offset] = state
	_sync_skill_swipe_preview_scroll_state(state)
	_update_skill_swipe_preview_state(state, 0.0, true)
	return page

func _clear_skill_swipe_preview() -> void:
	_cancel_preview_prewarm()
	preview_module_reveal_token += 1
	var active_was_cached = false
	var active_preview = _preview_control(preview_page)
	for raw_state in preview_states.values():
		_free_swipe_preview_real_card_cache(raw_state as Dictionary)
	for preview in preview_pages.values():
		var cached_page = _preview_control(preview)
		if cached_page == null:
			continue
		if active_preview != null and cached_page == active_preview:
			active_was_cached = true
		cached_page.queue_free()
	preview_pages.clear()
	preview_states.clear()
	if not active_was_cached and active_preview != null:
		active_preview.queue_free()
	preview_page = null
	preview_offset = 0

func _skill_swipe_preview_rest_x(offset: int) -> float:
	var direction := signi(offset)
	if direction == 0:
		return 0.0
	if direction > 0:
		return host._skill_swipe_frame_content_width(host.selected_skill_id) + host.SKILL_SWIPE_PAGE_GAP
	var preview_skill_id := _skill_id_for_swipe_offset(offset)
	var preview_width: float = host._skill_swipe_frame_content_width(preview_skill_id) if not preview_skill_id.is_empty() else host._skill_swipe_frame_content_width(host.selected_skill_id)
	return -(preview_width + host.SKILL_SWIPE_PAGE_GAP)

func _set_skill_swipe_positions(offset: int, current_x: float) -> void:
	host._apply_skill_swipe_drag_offset(current_x)
	var active_page := _active_preview_page()
	if active_page != null:
		active_page.position.x = _skill_swipe_preview_rest_x(offset)
		host._sync_skill_swipe_preview_page_fade(current_x)

func _hide_parked_skill_swipe_preview_pages(active_page: Control = null) -> void:
	for preview in preview_pages.values():
		var page = _preview_control(preview)
		if page == null or page == active_page:
			continue
		page.visible = false

func _park_skill_swipe_preview() -> void:
	var parked_page = _preview_control(preview_page)
	var parked_offset = preview_offset
	if parked_page != null and parked_offset != 0:
		if host.SKILL_SWIPE_PREVIEW_CACHE_PARKED_PAGES:
			parked_page.position.x = _skill_swipe_preview_rest_x(parked_offset)
			parked_page.visible = false
		else:
			for raw_offset in preview_pages.keys():
				if _preview_control(preview_pages[raw_offset]) == parked_page:
					preview_pages.erase(raw_offset)
					break
			if preview_states.has(parked_offset):
				_free_swipe_preview_real_card_cache(preview_states[parked_offset] as Dictionary)
				preview_states.erase(parked_offset)
			parked_page.queue_free()
	preview_page = null
	preview_offset = 0

func _take_preview_for_oandoff(clear_active := true) -> Control:
	var page = _preview_control(preview_page)
	if page == null:
		return null
	_force_show_skill_swipe_preview_modules(preview_offset)
	for raw_offset in preview_pages.keys():
		if preview_pages[raw_offset] == page:
			preview_pages.erase(raw_offset)
			break
	if preview_states.has(preview_offset):
		_free_swipe_preview_real_card_cache(preview_states[preview_offset] as Dictionary)
		preview_states.erase(preview_offset)
	if clear_active:
		preview_page = null
		preview_offset = 0
	return page

func _extract_incoming_swipe_preview(offset: int) -> Dictionary:
	if offset == 0 or host.skill_swipe_frame == null or not is_instance_valid(host.skill_swipe_frame):
		return {}
	var expected_id = _skill_id_for_swipe_offset(offset)
	if expected_id.is_empty():
		return {}
	var incoming_page: Control = null
	if preview_page != null and is_instance_valid(preview_page) and preview_offset == offset:
		incoming_page = preview_page
	elif preview_pages.has(offset):
		incoming_page = _preview_control(preview_pages[offset])
	if incoming_page == null or not is_instance_valid(incoming_page):
		return {}
	var state = preview_states.get(offset, {}) as Dictionary
	if state == null or state.is_empty():
		state = {
			"skill_id": expected_id,
			"page": incoming_page,
			"action_cards": [],
			"fishing_built_modules": [],
			"prewarmed": false,
		}
		var scroll = host._find_skill_preview_actions_scroll(incoming_page)
		state["actions_scroll"] = scroll
		state["modules_root"] = scroll
	if state != null and str(state.get("skill_id", "")) != expected_id:
		return {}
	var preview_parent = incoming_page.get_parent()
	if preview_parent != null:
		preview_parent.remove_child(incoming_page)
	preview_pages.erase(offset)
	if preview_page == incoming_page:
		preview_page = null
		preview_offset = 0
	preview_states.erase(offset)
	return {
		"page": incoming_page,
		"state": state if state != null else {}
	}

func _queue_skill_swipe_preview_prewarm() -> void:
	if not host.SKILL_SWIPE_IDLE_PREWARM_ENABLED:
		preview_prewarm_pending = false
		return
	if not host.skill_strip_ids.is_empty():
		return
	if DisplayServer.get_name() == "headless":
		return
	if host.current_screen != "skill" or host.skill_swipe_frame == null or not is_instance_valid(host.skill_swipe_frame):
		return
	if host.skill_swipe_tracking or host.skill_swipe_animating:
		return
	if host.detail_actions_scroll != null and is_instance_valid(host.detail_actions_scroll) and host.detail_actions_scroll.is_child_click_suppressed():
		return
	if preview_prewarm_pending:
		return
	preview_prewarm_token += 1
	preview_prewarm_pending = true
	call_deferred("_prewarm_skill_swipe_neighbor_previews", host.selected_skill_id, preview_prewarm_token)

func _prewarm_skill_swipe_neighbor_previews(skill_id: String, token: int) -> void:
	if not _skill_swipe_prewarm_can_continue(skill_id, token):
		_finish_skill_swipe_preview_prewarm(token)
		return
	await host.get_tree().process_frame
	await _prewarm_global_swipe_real_card_cache_for_neighbors(skill_id, token)
	for offset in [-1, 1]:
		if not host._onboarding_runtime()._swipe_offset_accessible(offset):
			continue
		if not _skill_swipe_prewarm_can_continue(skill_id, token):
			_finish_skill_swipe_preview_prewarm(token)
			return
		var page = _ensure_skill_swipe_preview_page_cached(offset)
		if page == null or not is_instance_valid(page):
			continue
		page.position.x = _skill_swipe_preview_rest_x(offset)
		var state = preview_states.get(offset, {}) as Dictionary
		if state == null:
			continue
		state["prewarmed"] = false
		_update_skill_swipe_preview_state(state, 0.0, true)
		await host.get_tree().process_frame
		if not _skill_swipe_prewarm_can_continue(skill_id, token):
			_finish_skill_swipe_preview_prewarm(token)
			return
		_update_skill_swipe_preview_state(state, 0.0, true)
		state["prewarmed"] = true
		var modules_root = state.get("modules_root") as Control
		if modules_root != null and is_instance_valid(modules_root):
			modules_root.visible = true
			modules_root.modulate.a = 1.0
		await _prewarm_swipe_preview_real_card_cache(state, str(state.get("skill_id", "")), token)
	_finish_skill_swipe_preview_prewarm(token)

func _free_swipe_preview_real_card_cache(preview_state: Dictionary) -> void:
	if preview_state.is_empty():
		return
	var cache = preview_state.get("real_card_cache", {}) as Dictionary
	if cache == null or cache.is_empty():
		preview_state.erase("real_card_cache")
		return
	for raw_cached in cache.values():
		var cached = raw_cached as Dictionary
		var root = host._valid_control_ref(cached.get("root"))
		if root == null or root.is_queued_for_deletion():
			continue
		if root.get_parent() != null:
			root.queue_free()
		else:
			root.free()
	cache.clear()
	preview_state.erase("real_card_cache")

func _move_swipe_preview_real_card_cache_to_global(preview_state: Dictionary) -> void:
	if preview_state.is_empty():
		return
	var skill_id = str(preview_state.get("skill_id", ""))
	var cache = preview_state.get("real_card_cache", {}) as Dictionary
	if skill_id.is_empty() or cache == null or cache.is_empty():
		return
	var global_cache = real_card_cache_by_skill.get(skill_id, {}) as Dictionary
	if global_cache == null:
		global_cache = {}
	for raw_key in cache.keys():
		var cached = cache.get(raw_key, {}) as Dictionary
		if cached.is_empty():
			continue
		var track_id = str(cached.get("track_id", raw_key))
		if track_id.is_empty():
			continue
		if global_cache.has(track_id):
			var duplicate_root = host._valid_control_ref(cached.get("root"))
			if duplicate_root != null and not duplicate_root.is_queued_for_deletion():
				if duplicate_root.get_parent() != null:
					duplicate_root.queue_free()
				else:
					duplicate_root.free()
			continue
		global_cache[track_id] = cached
	cache.clear()
	preview_state.erase("real_card_cache")
	if not global_cache.is_empty():
		real_card_cache_by_skill[skill_id] = global_cache

func _build_swipe_preview_real_card_cache_entry(skill_id: String, entry_data: Dictionary, content_width: float, actions_width: float) -> Dictionary:
	if skill_id.is_empty() or host._fishing_rework_active_for_skill(skill_id):
		return {}
	if str(entry_data.get("kind", "")) == "thieving_heist":
		return {}
	var action = entry_data.get("action", {}) as Dictionary
	var action_id = str(action.get("id", ""))
	if action.is_empty() or action_id.is_empty():
		return {}
	var root: Control = null
	var card = {}
	if host._is_passive_action(action):
		var passive_built = host._passive_firepit_surface()._build_passive_module_card(skill_id, action, content_width, true)
		root = passive_built.get("root") as Control
		card = passive_built.get("card", {}) as Dictionary
	else:
		var built = host._skill_detail_surface()._build_detail_interactive_action_card(skill_id, action, content_width, actions_width)
		root = built.get("card_root") as Control
		card = built.get("card", {}) as Dictionary
	if root == null or not is_instance_valid(root) or card.is_empty():
		if root != null and is_instance_valid(root):
			root.free()
		return {}
	root.visible = false
	root.modulate = Color.WHITE
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return {
		"track_id": action_id,
		"root": root,
		"card": card,
	}

func _preview_detail_entries_for_skill(skill_id: String) -> Array:
	if not host._onboarding_runtime()._onboarding_path_active() or skill_id == host.TUTORIAL_STARTER_SKILL_ID:
		return host._visible_detail_entries_for_skill(skill_id)
	var entries := []
	for entry in host._visible_detail_entries_for_skill(skill_id):
		var entry_data := entry as Dictionary
		if str(entry_data.get("kind", "")) == "thieving_heist":
			continue
		var action := entry_data.get("action", {}) as Dictionary
		if action.is_empty() or not host._is_action_unlocked(skill_id, action):
			continue
		entries.append(entry_data)
	return entries

func _prewarm_swipe_preview_real_card_cache(preview_state: Dictionary, skill_id: String, token: int) -> void:
	if skill_id.is_empty() or host._fishing_rework_active_for_skill(skill_id):
		return
	var cache = preview_state.get("real_card_cache", {}) as Dictionary
	if cache == null:
		cache = {}
	preview_state["real_card_cache"] = cache
	var content_width = host._skill_content_width()
	var actions_width = content_width
	var built_count = cache.size()
	for entry in _preview_detail_entries_for_skill(skill_id):
		if built_count >= host.SKILL_SWIPE_REAL_CARD_PREWARM_COUNT:
			break
		if not _skill_swipe_prewarm_can_continue(host.selected_skill_id, token):
			_free_swipe_preview_real_card_cache(preview_state)
			return
		var entry_data = entry as Dictionary
		if str(entry_data.get("kind", "")) == "thieving_heist":
			continue
		var action = entry_data.get("action", {}) as Dictionary
		var action_id = str(action.get("id", ""))
		if action_id.is_empty() or cache.has(action_id):
			continue
		await host.get_tree().process_frame
		if not _skill_swipe_prewarm_can_continue(host.selected_skill_id, token):
			_free_swipe_preview_real_card_cache(preview_state)
			return
		var cached = _build_swipe_preview_real_card_cache_entry(skill_id, entry_data, content_width, actions_width)
		if cached.is_empty():
			continue
		cache[str(cached.get("track_id", action_id))] = cached
		built_count += 1

func _free_swipe_real_card_cache_dictionary(cache: Dictionary) -> void:
	if cache == null or cache.is_empty():
		return
	for raw_cached in cache.values():
		var cached = raw_cached as Dictionary
		var root = host._valid_control_ref(cached.get("root"))
		if root == null or root.is_queued_for_deletion():
			continue
		if root.get_parent() != null:
			root.queue_free()
		else:
			root.free()
	cache.clear()

func _free_global_swipe_real_card_cache() -> void:
	real_card_prewarm_token += 1
	for raw_cache in real_card_cache_by_skill.values():
		_free_swipe_real_card_cache_dictionary(raw_cache as Dictionary)
	real_card_cache_by_skill.clear()

func _prune_global_swipe_real_card_cache_for_skills(allowed_skill_ids: Dictionary) -> void:
	for raw_skill_id in real_card_cache_by_skill.keys().duplicate():
		var skill_id = str(raw_skill_id)
		if allowed_skill_ids.has(skill_id):
			continue
		var cache = real_card_cache_by_skill.get(skill_id, {}) as Dictionary
		_free_swipe_real_card_cache_dictionary(cache)
		real_card_cache_by_skill.erase(skill_id)

func _skill_swipe_real_card_prewarm_can_continue(source_skill_id: String, token: int) -> bool:
	return (
		host.SKILL_SWIPE_REAL_CARD_IDLE_PREWARM_ENABLED
		and token == real_card_prewarm_token
		and host.current_screen == "skill"
		and host.selected_skill_id == source_skill_id
		and not host.skill_swipe_tracking
		and not host.skill_swipe_animating
		and not host.skill_swipe_pending_full_finalize
		and not host._skill_swipe_oandoff_cover_is_cream_transition()
	)

func _queue_skill_swipe_real_card_cache_prewarm(source_skill_id: String) -> void:
	if not host.SKILL_SWIPE_REAL_CARD_IDLE_PREWARM_ENABLED:
		return
	if source_skill_id.is_empty() or host.current_screen != "skill" or host.selected_skill_id != source_skill_id:
		return
	if host.skill_swipe_tracking or host.skill_swipe_animating or host.skill_swipe_pending_full_finalize:
		return
	if host._skill_swipe_oandoff_cover_is_cream_transition():
		return
	real_card_prewarm_token += 1
	call_deferred("_prewarm_global_swipe_real_card_cache_for_neighbors_idle", source_skill_id, real_card_prewarm_token)

func _prewarm_global_swipe_real_card_cache_for_skill_idle(skill_id: String, source_skill_id: String, token: int) -> void:
	if skill_id.is_empty() or host._fishing_rework_active_for_skill(skill_id):
		return
	var cache = real_card_cache_by_skill.get(skill_id, {}) as Dictionary
	if cache == null:
		cache = {}
	real_card_cache_by_skill[skill_id] = cache
	var content_width = host._skill_content_width()
	var actions_width = content_width
	var built_count = cache.size()
	for entry in _preview_detail_entries_for_skill(skill_id):
		if built_count >= host.SKILL_SWIPE_REAL_CARD_PREWARM_COUNT:
			break
		if not _skill_swipe_real_card_prewarm_can_continue(source_skill_id, token):
			return
		var entry_data = entry as Dictionary
		if str(entry_data.get("kind", "")) == "thieving_heist":
			continue
		var action = entry_data.get("action", {}) as Dictionary
		var action_id = str(action.get("id", ""))
		if action_id.is_empty() or cache.has(action_id):
			continue
		await host.get_tree().process_frame
		if not _skill_swipe_real_card_prewarm_can_continue(source_skill_id, token):
			return
		var cached = _build_swipe_preview_real_card_cache_entry(skill_id, entry_data, content_width, actions_width)
		if cached.is_empty():
			continue
		if not _skill_swipe_real_card_prewarm_can_continue(source_skill_id, token):
			_free_swipe_real_card_cache_dictionary({"stale": cached})
			return
		cache[str(cached.get("track_id", action_id))] = cached
		built_count += 1

func _prewarm_global_swipe_real_card_cache_for_neighbors_idle(source_skill_id: String, token: int) -> void:
	if not _skill_swipe_real_card_prewarm_can_continue(source_skill_id, token):
		return
	var allowed = {source_skill_id: true}
	for offset in [-1, 1]:
		if not host._onboarding_runtime()._swipe_offset_accessible(offset):
			continue
		var neighbor_skill_id = _skill_id_for_swipe_offset(offset)
		if not neighbor_skill_id.is_empty():
			allowed[neighbor_skill_id] = true
	_prune_global_swipe_real_card_cache_for_skills(allowed)
	await _prewarm_global_swipe_real_card_cache_for_skill_idle(source_skill_id, source_skill_id, token)
	for raw_skill_id in allowed.keys():
		var skill_id = str(raw_skill_id)
		if skill_id == source_skill_id:
			continue
		if not _skill_swipe_real_card_prewarm_can_continue(source_skill_id, token):
			return
		await _prewarm_global_swipe_real_card_cache_for_skill_idle(skill_id, source_skill_id, token)

func _prewarm_global_swipe_real_card_cache_for_skill(skill_id: String, source_skill_id: String, token: int) -> void:
	if skill_id.is_empty() or host._fishing_rework_active_for_skill(skill_id):
		return
	var cache = real_card_cache_by_skill.get(skill_id, {}) as Dictionary
	if cache == null:
		cache = {}
	real_card_cache_by_skill[skill_id] = cache
	var content_width = host._skill_content_width()
	var actions_width = content_width
	var built_count = cache.size()
	for entry in _preview_detail_entries_for_skill(skill_id):
		if built_count >= host.SKILL_SWIPE_REAL_CARD_PREWARM_COUNT:
			break
		if not _skill_swipe_prewarm_can_continue(source_skill_id, token):
			return
		var entry_data = entry as Dictionary
		if str(entry_data.get("kind", "")) == "thieving_heist":
			continue
		var action = entry_data.get("action", {}) as Dictionary
		var action_id = str(action.get("id", ""))
		if action_id.is_empty() or cache.has(action_id):
			continue
		await host.get_tree().process_frame
		if not _skill_swipe_prewarm_can_continue(source_skill_id, token):
			return
		var cached = _build_swipe_preview_real_card_cache_entry(skill_id, entry_data, content_width, actions_width)
		if cached.is_empty():
			continue
		cache[str(cached.get("track_id", action_id))] = cached
		built_count += 1

func _prewarm_global_swipe_real_card_cache_for_neighbors(source_skill_id: String, token: int) -> void:
	await _prewarm_global_swipe_real_card_cache_for_skill(source_skill_id, source_skill_id, token)
	for offset in [-1, 1]:
		var neighbor_skill_id = _skill_id_for_swipe_offset(offset)
		if neighbor_skill_id.is_empty():
			continue
		await _prewarm_global_swipe_real_card_cache_for_skill(neighbor_skill_id, source_skill_id, token)

func _apply_global_swipe_real_card_cache_to_lazy_plan(skill_id: String) -> void:
	if skill_id.is_empty() or host.detail_lazy_plan.is_empty():
		return
	var cache = real_card_cache_by_skill.get(skill_id, {}) as Dictionary
	if cache == null or cache.is_empty():
		return
	for raw_lazy_entry in host.detail_lazy_plan:
		var lazy_entry = raw_lazy_entry as Dictionary
		var track_id = str(lazy_entry.get("track_id", ""))
		if track_id.is_empty() or not cache.has(track_id) or lazy_entry.has("cached_root"):
			continue
		var cached = cache.get(track_id, {}) as Dictionary
		var root = host._valid_control_ref(cached.get("root"))
		var card = cached.get("card", {}) as Dictionary
		if root == null or root.is_queued_for_deletion() or card.is_empty():
			continue
		lazy_entry["cached_root"] = root
		lazy_entry["cached_card"] = card
		cache.erase(track_id)
	if cache.is_empty():
		real_card_cache_by_skill.erase(skill_id)

func _apply_swipe_preview_real_card_cache_to_lazy_plan(preview_state: Dictionary) -> void:
	if preview_state.is_empty() or host.detail_lazy_plan.is_empty():
		return
	var cache = preview_state.get("real_card_cache", {}) as Dictionary
	if cache == null or cache.is_empty():
		preview_state.erase("real_card_cache")
		return
	for raw_lazy_entry in host.detail_lazy_plan:
		var lazy_entry = raw_lazy_entry as Dictionary
		var track_id = str(lazy_entry.get("track_id", ""))
		if track_id.is_empty() or not cache.has(track_id):
			continue
		var cached = cache.get(track_id, {}) as Dictionary
		var root = host._valid_control_ref(cached.get("root"))
		var card = cached.get("card", {}) as Dictionary
		if root == null or root.is_queued_for_deletion() or card.is_empty():
			continue
		lazy_entry["cached_root"] = root
		lazy_entry["cached_card"] = card
		cache.erase(track_id)
	_free_swipe_preview_real_card_cache({"real_card_cache": cache})
	preview_state.erase("real_card_cache")

func _skill_swipe_prewarm_can_continue(skill_id: String, token: int) -> bool:
	return (
		token == preview_prewarm_token
		and host.current_screen == "skill"
		and host.selected_skill_id == skill_id
		and not host.skill_swipe_tracking
		and not host.skill_swipe_animating
		and host.skill_swipe_frame != null
		and is_instance_valid(host.skill_swipe_frame)
	)

func _finish_skill_swipe_preview_prewarm(token: int) -> void:
	if token == preview_prewarm_token:
		preview_prewarm_pending = false
		_hide_parked_skill_swipe_preview_pages(preview_page)

func _ensure_skill_swipe_preview_page_cached(offset: int) -> Control:
	if host.skill_swipe_frame == null or not is_instance_valid(host.skill_swipe_frame):
		return null
	var cached_page = _preview_control(preview_pages.get(offset))
	if cached_page != null:
		return cached_page
	preview_pages.erase(offset)
	var next_skill_id = _skill_id_for_swipe_offset(offset)
	if next_skill_id.is_empty():
		return null
	cached_page = _build_skill_swipe_preview_page(next_skill_id, offset)
	cached_page.position.x = _skill_swipe_preview_rest_x(offset)
	cached_page.visible = false
	host.skill_swipe_frame.add_child(cached_page)
	preview_pages[offset] = cached_page
	return cached_page

func _skill_id_for_swipe_offset(offset: int) -> String:
	return _skill_id_for_swipe_offset_from(host.selected_skill_id, offset)

func _skill_id_for_swipe_offset_from(base_skill_id: String, offset: int) -> String:
	var current_index: int = host._skill_index(base_skill_id)
	if current_index < 0 or host.skill_defs.is_empty():
		return ""
	var next_index: int = (current_index + offset) % host.skill_defs.size()
	if next_index < 0:
		next_index += host.skill_defs.size()
	return str(host.skill_defs[next_index]["id"])

func _skill_page_neighbor_ids(skill_id: String) -> Dictionary:
	if skill_id.is_empty() or host.skill_defs.size() < 2:
		return {}
	return {
		"previous": _skill_id_for_swipe_offset_from(skill_id, -1),
		"next": _skill_id_for_swipe_offset_from(skill_id, 1)
	}

func _skill_swipe_preview_entry_height(entry_data: Dictionary) -> float:
	if str(entry_data.get("kind", "")) == "thieving_heist":
		return float(host.THIEVING_HEIST_CARD_HEIGHT)
	var action = entry_data.get("action", {}) as Dictionary
	if host._is_passive_action(action):
		return float(host.PASSIVE_MODULE_CARD_HEIGHT)
	return host._activity_card_root_height()

func _skill_swipe_preview_scroll_y() -> float:
	if host.detail_actions_scroll != null and is_instance_valid(host.detail_actions_scroll):
		return float(host.detail_actions_scroll.scroll_vertical)
	return 0.0

func _skill_swipe_preview_viewport_height() -> float:
	if host.detail_actions_scroll != null and is_instance_valid(host.detail_actions_scroll):
		var viewport_height = host.detail_actions_scroll.size.y
		if viewport_height <= 1.0:
			viewport_height = host.detail_actions_scroll.custom_minimum_size.y
		if viewport_height > 1.0:
			return viewport_height
	return host._detail_lazy_viewport_height()

func _skill_swipe_preview_should_build_entry(entry_y: float, entry_height: float, preview_index: int) -> bool:
	var scroll_y = _skill_swipe_preview_scroll_y()
	if preview_index < host.DETAIL_LAZY_INITIAL_FORCE_MOUNT_COUNT and scroll_y <= host.DETAIL_LAZY_VIEWPORT_BUFFER_PX:
		return true
	var view_top = scroll_y - host.DETAIL_LAZY_VIEWPORT_BUFFER_PX
	var view_bottom = scroll_y + _skill_swipe_preview_viewport_height() + host.DETAIL_LAZY_VIEWPORT_BUFFER_PX
	var content_y = float(host.SKILL_DETAIL_ACTIONS_TOP_SPACER_HEIGHT) + entry_y
	var content_bottom = content_y + entry_height
	return content_bottom >= view_top and content_y <= view_bottom

func _add_skill_swipe_preview_placeholder(stack: VBoxContainer, width: float, height: float) -> void:
	if stack == null or not is_instance_valid(stack) or height <= 1.0:
		return
	var spacer = Control.new()
	spacer.name = "SwipePreviewSpacer"
	spacer.custom_minimum_size = Vector2(width, height)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.set_meta("skill_swipe_preview_placeholder", true)
	stack.add_child(spacer)

func _flush_skill_swipe_preview_placeholder(stack: VBoxContainer, width: float, pending_height: float) -> float:
	_add_skill_swipe_preview_placeholder(stack, width, pending_height)
	return 0.0

func _skill_swipe_light_preview_card_title(skill_id: String, entry_data: Dictionary) -> String:
	if str(entry_data.get("kind", "")) == "thieving_heist":
		var heist = entry_data.get("heist", {}) as Dictionary
		return str(heist.get("name", "Heist"))
	var action = entry_data.get("action", {}) as Dictionary
	if action.is_empty():
		return host._skill_name(skill_id)
	return str(action.get("name", host._skill_name(skill_id)))

func _skill_swipe_light_preview_card_style(skill_id: String) -> StyleBoxFlat:
	var key = skill_id
	if light_preview_card_style_cache.has(key):
		return light_preview_card_style_cache[key] as StyleBoxFlat
	var theme = host._skill_theme_color(skill_id)
	var style = StyleBoxFlat.new()
	style.bg_color = theme.darkened(0.06)
	style.border_color = Color(host.COLOR_INK.r, host.COLOR_INK.g, host.COLOR_INK.b, 0.72)
	style.set_border_width_all(5)
	style.corner_radius_top_left = 46
	style.corner_radius_top_right = 46
	style.corner_radius_bottom_left = 46
	style.corner_radius_bottom_right = 46
	light_preview_card_style_cache[key] = style
	return style

func _skill_swipe_light_preview_card(skill_id: String, entry_data: Dictionary, content_width: float) -> Dictionary:
	var height = _skill_swipe_preview_entry_height(entry_data)
	var root = _skill_swipe_light_preview_simple_card(skill_id, entry_data, content_width, height)
	var card = {}
	if str(entry_data.get("kind", "")) == "thieving_heist":
		var heist = entry_data.get("heist", {}) as Dictionary
		var heist_id = str(heist.get("id", ""))
		if not heist_id.is_empty():
			card = {
				"root": root,
				"pop": root,
				"heist_id": heist_id,
				"preview_only": true,
				"swipe_proxy": true,
			}
		return {"root": root, "card": card}
	var action = entry_data.get("action", {}) as Dictionary
	var action_id = str(action.get("id", ""))
	if not action_id.is_empty():
		card = {
			"root": root,
			"pop": root,
			"action": action,
			"action_id": action_id,
			"skill_id": skill_id,
			"passive": host._is_passive_action(action),
			"preview_only": true,
			"swipe_proxy": true,
		}
	return {"root": root, "card": card}

func _skill_swipe_light_preview_simple_card(skill_id: String, entry_data: Dictionary, content_width: float, height: float) -> Control:
	var root = Control.new()
	root.set_meta("skill_swipe_light_preview_card", true)
	root.custom_minimum_size = Vector2(content_width, height)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = host.ACTION_CARD_POP_GUTTER
	panel.offset_right = -host.ACTION_CARD_POP_GUTTER
	panel.offset_top = 0.0
	panel.offset_bottom = 0.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _skill_swipe_light_preview_card_style(skill_id))
	root.add_child(panel)

	var title = host._label(_skill_swipe_light_preview_card_title(skill_id, entry_data), 76, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	title.add_theme_color_override("font_outline_color", host.COLOR_INK)
	title.add_theme_constant_override("outline_size", 16)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.position = Vector2(54, 46)
	title.size = Vector2(maxf(1.0, content_width - host.ACTION_CARD_POP_GUTTER * 2.0 - 108.0), 104)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(title)
	return root

func _skill_swipe_light_preview_header_circle_style(skill_id: String) -> StyleBoxFlat:
	var key = "header:%s" % skill_id
	if light_preview_card_style_cache.has(key):
		return light_preview_card_style_cache[key] as StyleBoxFlat
	var theme = host._skill_theme_color(skill_id)
	var style = StyleBoxFlat.new()
	style.bg_color = theme.darkened(0.02)
	style.border_color = host.COLOR_INK
	style.set_border_width_all(12)
	style.corner_radius_top_left = 220
	style.corner_radius_top_right = 220
	style.corner_radius_bottom_left = 220
	style.corner_radius_bottom_right = 220
	style.shadow_color = theme.darkened(0.48)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 10)
	light_preview_card_style_cache[key] = style
	return style

func _skill_swipe_light_preview_header_circle(skill_id: String) -> PanelContainer:
	var circle = PanelContainer.new()
	circle.custom_minimum_size = Vector2(430, 430)
	circle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circle.add_theme_stylebox_override("panel", _skill_swipe_light_preview_header_circle_style(skill_id))
	var stack = VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", -8)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circle.add_child(stack)
	var maximum = maxi(1, host._max_stamina(skill_id))
	var current_value = clampi(int(round(float(host.stamina.get(skill_id, maximum)))), 0, maximum)
	var current_label = host._label(str(current_value), 124, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	current_label.add_theme_color_override("font_outline_color", host.COLOR_INK)
	current_label.add_theme_constant_override("outline_size", 16)
	current_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(current_label)
	var divider = ColorRect.new()
	divider.custom_minimum_size = Vector2(150, 8)
	divider.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	divider.color = host.COLOR_INK
	stack.add_child(divider)
	var max_label = host._label(str(maximum), 58, Color("#171615"), HORIZONTAL_ALIGNMENT_CENTER)
	max_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(max_label)
	return circle

func _render_light_skill_swipe_preview_entries(stack: VBoxContainer, skill_id: String, content_width: float, actions_width: float, state: Dictionary) -> void:
	var entries = host._visible_detail_entries_for_skill(skill_id) if skill_id == "thieving" else _preview_detail_entries_for_skill(skill_id)
	if entries.is_empty():
		_add_skill_swipe_preview_placeholder(stack, actions_width, host._activity_card_root_height())
		return
	var preview_entry_y = 0.0
	var preview_index = 0
	var built_count = 0
	var max_preview_cards = host.SKILL_SWIPE_LIGHT_PREVIEW_MAX_CARDS if host.SKILL_SWIPE_SHOW_INCOMING_PREVIEW_DURING_DRAG else host.SKILL_SWIPE_HIDDEN_PREVIEW_MAX_CARDS
	var pending_placeholder_height = 0.0
	for entry in entries:
		var entry_data = entry as Dictionary
		var entry_height = _skill_swipe_preview_entry_height(entry_data)
		var should_build = (
			built_count < max_preview_cards
			and _skill_swipe_preview_should_build_entry(preview_entry_y, entry_height, preview_index)
		)
		if not should_build:
			pending_placeholder_height += (
				entry_height
				if pending_placeholder_height <= 1.0
				else host.DETAIL_LAZY_STACK_SEPARATION + entry_height
			)
			preview_entry_y += entry_height + host.DETAIL_LAZY_STACK_SEPARATION
			preview_index += 1
			continue
		pending_placeholder_height = _flush_skill_swipe_preview_placeholder(stack, actions_width, pending_placeholder_height)
		var card_result = _skill_swipe_light_preview_card(skill_id, entry_data, content_width)
		var card_root = card_result.get("root") as Control
		if card_root != null:
			stack.add_child(card_root)
		var card = card_result.get("card", {}) as Dictionary
		if not card.is_empty():
			(state["action_cards"] as Array).append(card)
		built_count += 1
		preview_entry_y += entry_height + host.DETAIL_LAZY_STACK_SEPARATION
		preview_index += 1
	pending_placeholder_height = _flush_skill_swipe_preview_placeholder(stack, actions_width, pending_placeholder_height)

func _force_show_skill_swipe_preview_modules(offset: int) -> void:
	if not preview_states.has(offset):
		return
	var state = preview_states[offset] as Dictionary
	if state == null:
		return
	host._cancel_skill_swipe_preview_modules_reveal(state)
	if not bool(state.get("prewarmed", false)):
		_update_skill_swipe_preview_state(state, 0.0, true)
	var modules_root = state.get("modules_root") as Control
	if modules_root != null and is_instance_valid(modules_root):
		modules_root.visible = true
		modules_root.modulate.a = 1.0




func _update_passive_card_static_state(card: Dictionary, _skill_id: String, action: Dictionary, unlocked: bool) -> void:
	if bool(card.get("firepit", false)):
		_update_firepit_card_static_state(card, _skill_id, action, unlocked)
		return
	host._skill_detail_surface()._sync_module_action_zones_for_card(card, ModuleUiRuntime.action_for_record(_skill_id, action, host.FISHING_ACTION_ID_ALIASES))
	var module_id = str(action.get("id", host.WOODCUTTING_LOG_MODULE_ID))
	var passive_runtime = host._passive_modules_runtime()
	var now: int = host._unix_now()
	var state = passive_runtime.passive_module_state(module_id, now)
	var ceremony_active = bool(card.get("unlock_ceremony_pending", false)) or bool(card.get("unlock_ceremony_active", false))
	host._skill_detail_surface()._sync_activity_lock_overlay(card, action, unlocked)
	host._sync_activity_card_title_layer(card, unlocked)
	var button = card.get("button") as Button
	if button != null:
		button.disabled = (not unlocked) or ceremony_active
	var shade = card.get("shade") as Panel
	if shade != null:
		shade.visible = (not unlocked) or ceremony_active
		if not unlocked:
			shade.modulate = Color.WHITE
		elif not ceremony_active:
			shade.modulate = Color(1, 1, 1, 0)
	var border = card.get("border") as Control
	if border != null:
		var border_dirty = false
		if border.get("border_color") != host.COLOR_INK:
			border.set("border_color", host.COLOR_INK)
			border_dirty = true
		if absf(float(border.get("border_width")) - 8.0) > 0.001:
			border.set("border_width", 8.0)
			border_dirty = true
		if border_dirty:
			border.queue_redraw()
	var currency_label = card.get("currency") as Label
	if currency_label != null:
		var currency_text = str(host.log_currency) if host.log_currency < 1000 else GameFormatting.compact_number(float(host.log_currency))
		var currency_font_size = 82 if currency_text.length() <= 6 else 74
		if currency_label.get_theme_font_size("font_size") != currency_font_size:
			currency_label.add_theme_font_size_override("font_size", currency_font_size)
		host._set_label_text_if_changed(currency_label, currency_text)
	var plank_button = card.get("plank") as Button
	if plank_button != null:
		plank_button.button_pressed = host.plank_bhost_enabled
		plank_button.disabled = (not unlocked) or ceremony_active
		if not plank_button.has_meta("passive_style_active") or bool(plank_button.get_meta("passive_style_active", false)) != host.plank_bhost_enabled:
			plank_button.set_meta("passive_style_active", host.plank_bhost_enabled)
			plank_button.add_theme_stylebox_override("normal", PassiveModuleStyles.icon_button(host.plank_bhost_enabled, false, host.COLOR_INK, host.COLOR_GOLD, Callable(host, "_surface_style")))
			plank_button.add_theme_stylebox_override("oover", PassiveModuleStyles.icon_button(host.plank_bhost_enabled, false, host.COLOR_INK, host.COLOR_GOLD, Callable(host, "_surface_style")))
			plank_button.add_theme_stylebox_override("pressed", PassiveModuleStyles.icon_button(true, true, host.COLOR_INK, host.COLOR_GOLD, Callable(host, "_surface_style")))
			plank_button.add_theme_stylebox_override("disabled", PassiveModuleStyles.icon_button(false, false, host.COLOR_INK, host.COLOR_GOLD, Callable(host, "_surface_style")))
	var plank_light = card.get("plank_light") as Panel
	if plank_light != null:
		var light_active = host.plank_bhost_enabled and unlocked
		if bool(plank_light.get_meta("passive_light_active", false)) != light_active:
			plank_light.set_meta("passive_light_active", light_active)
			plank_light.add_theme_stylebox_override("panel", PassiveModuleStyles.plank_light(light_active, host.COLOR_INK))
	var stats = card.get("stats", {}) as Dictionary
	host._set_label_text_if_changed(stats.get("time") as Label, host._format_passive_time(int(state.get("time_seconds", host.PASSIVE_TIME_START))))
	host._set_label_text_if_changed(stats.get("yield") as Label, "+%s" % int(state.get("yield", host.PASSIVE_YIELD_START)))
	host._set_label_text_if_changed(stats.get("capacity") as Label, "%s" % int(state.get("capacity", host.PASSIVE_CAPACITY_START)))
	var upgrade_buttons = card.get("upgrade_buttons", {}) as Dictionary
	for stat_type in ["time", "yield", "capacity"]:
		var upgrade = upgrade_buttons.get(stat_type) as Button
		if upgrade == null:
			continue
		var maxed = passive_runtime.passive_upgrade_maxed(module_id, stat_type, now)
		var cost = passive_runtime.passive_upgrade_cost(module_id, stat_type, now)
		upgrade.visible = not maxed
		upgrade.disabled = (not unlocked) or ceremony_active or maxed or host.log_currency < cost
		upgrade.modulate = Color(1, 1, 1, 0.42) if upgrade.disabled else Color.WHITE
		var cost_label = upgrade.get_meta("cost_label", null) as Label
		if cost_label != null:
			host._set_label_text_if_changed(cost_label, str(cost))
	var progress = card.get("progress") as PassiveSerpentineProgressBar
	if progress != null:
		var locked_visual = (not unlocked) or ceremony_active
		var progress_theme = host._skill_theme_color("woodcutting")
		var next_unlocked_empty = host._themed_progress_empty_color(progress_theme)
		var next_shadow = progress.locked_shadow_color if locked_visual else progress.unlocked_shadow_color
		var next_empty = progress.locked_empty_color if locked_visual else next_unlocked_empty
		var next_outline = progress.locked_outline_color if locked_visual else progress.unlocked_outline_color
		var next_fill = progress.locked_empty_color if locked_visual else host._themed_progress_fill_color(progress_theme)
		var progress_dirty = false
		if progress.unlocked_empty_color != next_unlocked_empty:
			progress.unlocked_empty_color = next_unlocked_empty
			progress_dirty = true
		if progress.z_index != host.PASSIVE_PROGRESS_BAR_Z_INDEX:
			progress.z_index = host.PASSIVE_PROGRESS_BAR_Z_INDEX
		if progress.shadow_color != next_shadow:
			progress.shadow_color = next_shadow
			progress_dirty = true
		if progress.empty_color != next_empty:
			progress.empty_color = next_empty
			progress_dirty = true
		if progress.outline_color != next_outline:
			progress.outline_color = next_outline
			progress_dirty = true
		if progress.fill_color != next_fill:
			progress.fill_color = next_fill
			progress_dirty = true
		host._passive_firepit_surface()._update_passive_card_progress(card, action, unlocked)
		if progress_dirty:
			progress.queue_redraw()
	if bool(card.get("passive_loot_render_deferred", false)):
		if host.skill_swipe_pending_full_finalize or host._skill_swipe_oandoff_cover_is_opaque_cream_transition():
			return
		card.erase("passive_loot_render_deferred")
	host._passive_firepit_surface()._render_passive_loot(card, module_id, unlocked)




func _update_firepit_card_static_state(card: Dictionary, skill_id: String, action: Dictionary, unlocked: bool, instant = false) -> void:
	host._skill_detail_surface()._sync_module_action_zones_for_card(card, ModuleUiRuntime.action_for_record(skill_id, action, host.FISHING_ACTION_ID_ALIASES))
	var module_id = str(action.get("id", host.WOODCUTTING_FIREPIT_MODULE_ID))
	var passive_runtime = host._passive_modules_runtime()
	var now: int = host._unix_now()
	var state = passive_runtime.firepit_state(now)
	var ceremony_active = bool(card.get("unlock_ceremony_pending", false)) or bool(card.get("unlock_ceremony_active", false))
	host._skill_detail_surface()._sync_activity_lock_overlay(card, action, unlocked)
	host._sync_activity_card_title_layer(card, unlocked)
	var active = passive_runtime.firepit_active(now)
	var igniting = bool(state.get("igniting", false)) and not active
	var regen_bonus = passive_runtime.firepit_stamina_regen_bonus(skill_id, now)
	var cooling = (not active) and regen_bonus > 0.0001
	host._passive_firepit_surface()._sync_firepit_dependency_layout(card, unlocked and (active or igniting) and not ceremony_active, instant)
	var scrapwood = host.material_runtime.amount("scrapwood")
	var oeat_tier = passive_runtime.firepit_heat_tier(now)
	var shade = card.get("shade") as Panel
	if shade != null:
		shade.visible = (not unlocked) or ceremony_active
		if not unlocked:
			shade.modulate = Color.WHITE
		elif not ceremony_active:
			shade.modulate = Color(1, 1, 1, 0)
	var active_dim = card.get("active_dim") as FirepitWarmthOverlay
	if active_dim != null:
		active_dim.set_cover(unlocked and not ceremony_active, active)
	var corner_crop = card.get("corner_crop") as RoundedCornerCropOverlay
	if corner_crop != null:
		var crop_color = host._theme_paper_color()
		if corner_crop.cover_color != crop_color:
			corner_crop.cover_color = crop_color
			corner_crop.queue_redraw()
	var border = card.get("border") as Control
	if border != null:
		var next_color = Color("#ff9c2f") if active else host.COLOR_INK
		var border_dirty = false
		if border.get("border_color") != next_color:
			border.set("border_color", next_color)
			border_dirty = true
		if absf(float(border.get("border_width")) - (10.0 if active else 8.0)) > 0.001:
			border.set("border_width", 10.0 if active else 8.0)
			border_dirty = true
		if border_dirty:
			border.queue_redraw()
	var status_label = card.get("status") as Label
	if status_label != null:
		var status_text = passive_runtime.firepit_comfort_text(oeat_tier) if active else "Starting fire" if igniting else "Warmth fading" if cooling else "Fire is out"
		host._set_label_text_if_changed(status_label, status_text)
		status_label.add_theme_color_override("font_color", Color("#ffe27a") if active or cooling or igniting else Color.WHITE)
	var scrapwood_label = card.get("scrapwood_label") as Label
	if scrapwood_label != null:
		host._set_label_text_if_changed(scrapwood_label, host.material_runtime.amount_text_for_host("scrapwood", scrapwood, host))
	var timer_label = card.get("timer") as Label
	if timer_label != null:
		var timer_text = ""
		if active:
			timer_text = "%s left" % GameFormatting.duration(passive_runtime.firepit_seconds_available(scrapwood))
		elif igniting:
			timer_text = "igniting"
		elif cooling:
			timer_text = "cooling"
		host._set_label_text_if_changed(timer_label, timer_text)
		timer_label.visible = not timer_text.is_empty()
	var buff_label = card.get("buff") as Label
	if buff_label != null:
		var buff_text = ""
		if active or cooling:
			buff_text = "+%s%% host.stamina\nregen bhost" % GameFormatting.percent_points(regen_bonus * 100.0)
		host._set_label_text_if_changed(buff_label, buff_text)
		buff_label.visible = active or cooling
	var toggle_button = card.get("toggle") as Button
	if toggle_button != null:
		toggle_button.text = ""
		toggle_button.disabled = (not unlocked) or ceremony_active or igniting or ((not active) and scrapwood < host.FIREPIT_START_SCRAPWOOD_COST)
		toggle_button.modulate = Color(1, 1, 1, 0.42) if toggle_button.disabled else Color.WHITE
	var flame_fx = card.get("flame_fx") as Control
	if flame_fx != null and flame_fx.has_method("set_active"):
		flame_fx.call("set_active", unlocked and active)
	var progress = card.get("progress") as FirepitFuelRing
	if progress != null:
		var show_bonus_ring = unlocked and (active or cooling)
		var progress_target = passive_runtime.firepit_heat_bonus_progress_pct(now) if show_bonus_ring else 0.0
		progress.set_target_value(progress_target, (not unlocked) or ((not active) and (not cooling)) or progress_target + 8.0 < progress.value)
		var next_scrapwood_target = passive_runtime.firepit_next_scrapwood_progress_pct(state, now) if (unlocked and active) else 0.0
		var consume_hold_until = int(progress.get_meta("firepit_consume_hold_until_msec", 0))
		if consume_hold_until > Time.get_ticks_msec() and unlocked and active:
			progress.set_inner_value(0.0)
		else:
			if consume_hold_until > 0:
				progress.remove_meta("firepit_consume_hold_until_msec")
			progress.set_inner_target_value(next_scrapwood_target, (not unlocked) or (not active) or next_scrapwood_target + 8.0 < progress.inner_value)
	var title = card.get("title") as Label
	if title != null:
		title.z_index = host._activity_card_title_z_index(unlocked, title)
	host.passive_modules[module_id] = state




func _skill_swipe_preview_action_card(skill_id: String, action: Dictionary, content_width: float) -> Dictionary:
	var uses_blue_guy_chicken_brawl_stage = host._fighting_runtime().action_uses_blue_guy_chicken_brawl_stage(action)
	var card_root = Control.new()
	card_root.custom_minimum_size = Vector2(content_width, host._activity_card_root_height())
	card_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_root.clip_contents = false
	card_root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var pop_card = Control.new()
	pop_card.anchor_left = 0.0
	pop_card.anchor_right = 1.0
	pop_card.anchor_top = 0.0
	pop_card.anchor_bottom = 1.0
	pop_card.offset_left = host.ACTION_CARD_POP_GUTTER
	pop_card.offset_right = -host.ACTION_CARD_POP_GUTTER
	pop_card.offset_top = 0.0
	pop_card.set_meta("activity_card_depth_bottom_inset", host.ACTION_CARD_3D_DEPTH_OFFSET.y)
	pop_card.offset_bottom = host._activity_card_pop_base_bottom_offset(pop_card)
	pop_card.clip_contents = false
	pop_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pop_card.z_index = 1
	var depth = ActivityCardStyles.activity_card_depth_layer(host._skill_theme_color(skill_id), host.ACTION_CARD_3D_DEPTH_OFFSET, host.ACTION_CARD_FACE_RADIUS, host.ACTION_CARD_POP_GUTTER)
	host._apply_activity_card_depth_action_theme(depth, skill_id, action)
	_apply_recovery_card_depth_shape(depth, action)
	card_root.add_child(depth)
	pop_card.set_meta("activity_card_depth_node_id", depth.get_instance_id())
	card_root.add_child(pop_card)

	var background_underlay: Panel = ActivityCardStyles.action_card_background_edge_underlay(host._themed_activity_card_fill_color(host._skill_theme_color(skill_id)), host.ACTION_CARD_FACE_RADIUS)
	background_underlay.visible = not RecoveryModules.has_recovery(action)
	pop_card.add_child(background_underlay)
	var bg = host._action_card_background(skill_id, action)
	_apply_recovery_card_background_shape(bg, action)
	pop_card.add_child(bg)
	var blue_guy_chicken_stage: Control = null
	if uses_blue_guy_chicken_brawl_stage:
		blue_guy_chicken_stage = BlueGuyChickenBrawlStageClass.new()
		blue_guy_chicken_stage.set_anchors_preset(Control.PRESET_FULL_RECT)
		blue_guy_chicken_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
		blue_guy_chicken_stage.z_index = 220
		host._fighting_runtime().configure_blue_guy_chicken_brawl_stage(blue_guy_chicken_stage)
		pop_card.add_child(blue_guy_chicken_stage)

	var shade: Panel = null
	if not host._is_action_unlocked(skill_id, action):
		shade = ActivityCardStyles.activity_card_shade_layer(pop_card, 0.50)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 54)
	margin.add_theme_constant_override("margin_right", 54)
	margin.add_theme_constant_override("margin_top", 46)
	margin.add_theme_constant_override("margin_bottom", 126)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.z_index = 200
	margin.visible = not uses_blue_guy_chicken_brawl_stage
	pop_card.add_child(margin)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 56)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)

	var art_slot = MarginContainer.new()
	art_slot.add_theme_constant_override("margin_top", 42)
	art_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art_panel = Panel.new()
	art_panel.custom_minimum_size = ActionArtUi.ACTION_ART_PANEL_SIZE
	art_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	art_panel.add_theme_stylebox_override("panel", ActivityCardStyles.cached_action_art(Callable(host, "_surface_style")))
	art_panel.modulate = Color.WHITE
	art_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_slot.add_child(art_panel)
	var art = ActionArtUi.image(action, Callable(host, "_texture_or_visual_fallback"), Callable(host, "_visual_fallback_texture"), DisplayServer.get_name() == "headless")
	art_panel.add_child(art)
	if uses_blue_guy_chicken_brawl_stage:
		art.visible = false
	ActionArtUi.add_corner_badges(
		art_panel,
		ActionArtUi.resource_icon_paths(action, Callable(host._action_runtime(), "_action_mat_reward_defs"), Callable(host.material_runtime, "icon_path"), Callable(host._temporary_event_runtime(), "_temporary_event_log_reward_mat_id")),
		ActionArtUi.special_type_icon_path(action, Callable(host, "_is_event_action")),
		Callable(host, "_texture_or_visual_fallback")
	)
	art_panel.add_child(ActionArtUi.border_overlay(ActivityCardStyles.cached_action_art_border(Callable(host, "_surface_style"))))

	var copy = VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 38)
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(copy)
	row.add_child(art_slot)

	var action_name_label = host._label(str(action["name"]), 82, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	action_name_label.add_theme_color_override("font_outline_color", host.COLOR_INK)
	action_name_label.add_theme_constant_override("outline_size", host.ACTION_CARD_TITLE_OUTLINE_SIZE)
	action_name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	action_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	action_name_label.set_meta("activity_card_locked_title_z_index", 0)
	action_name_label.z_index = host._activity_card_title_z_index(host._is_action_unlocked(skill_id, action), action_name_label)
	copy.add_child(action_name_label)

	var stat_row = HBoxContainer.new()
	stat_row.add_theme_constant_override("separation", 28)
	stat_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(stat_row)
	var skill_detail_surface = host._skill_detail_surface()
	var xp_label = skill_detail_surface._action_stat_label("")
	stat_row.add_child(skill_detail_surface._action_stat_box(xp_label))
	var stamina_label = skill_detail_surface._action_stat_label("")
	stat_row.add_child(skill_detail_surface._action_stat_box(stamina_label))
	var time_label = skill_detail_surface._action_stat_label("")
	stat_row.add_child(skill_detail_surface._action_stat_box(time_label))
	var success_label = skill_detail_surface._action_stat_label("")
	stat_row.add_child(skill_detail_surface._action_stat_box(success_label))

	var medal: TextureRect = null
	var mastery_progress: CleanProgressBar = null
	if host._action_has_mastery(action):
		medal = TextureRect.new()
		medal.anchor_left = 0.0
		medal.anchor_right = 0.0
		medal.anchor_top = 0.0
		medal.anchor_bottom = 0.0
		medal.offset_left = -80
		medal.offset_right = 110
		medal.offset_top = -62
		medal.offset_bottom = 128
		medal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		medal.stretco_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		medal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		medal.z_index = 21
		art_panel.add_child(medal)
		mastery_progress = host._progress(Color("#f4bf35"), 56)
		mastery_progress.border_color = host.COLOR_INK
		host._apply_mastery_progress_bar_theme(mastery_progress, host._skill_theme_color(skill_id))
		mastery_progress.easing_speed = 5.0
		mastery_progress.z_index = 20
		copy.add_child(mastery_progress)
		if RecoveryModules.has_recovery(action):
			copy.remove_child(mastery_progress)
			pop_card.add_child(mastery_progress)
			mastery_progress.anchor_left = 0.0
			mastery_progress.anchor_right = 1.0
			mastery_progress.anchor_top = 1.0
			mastery_progress.anchor_bottom = 1.0
			mastery_progress.offset_left = 0.0
			mastery_progress.offset_right = 0.0
			mastery_progress.offset_top = -144.0
			mastery_progress.offset_bottom = -88.0

	var progress: ActivityProgressRail = null
	var fluid_strip: Control = null
	if host._fishing_rework_active_for_skill(skill_id) and not host.fishing_runtime.action_should_render_standalone(host, skill_id, action):
		fluid_strip = host._attach_fishing_fluid_strip(pop_card, action)
	elif not uses_blue_guy_chicken_brawl_stage:
		progress = ActivityProgressRail.new()
		host._apply_activity_progress_rail_action_theme(progress, skill_id, action)
		progress.anchor_left = 0.0
		progress.anchor_right = 1.0
		progress.anchor_top = 1.0
		progress.anchor_bottom = 1.0
		progress.offset_left = 0.0 if RecoveryModules.has_recovery(action) else host.ACTION_PROGRESS_RAIL_INSET
		progress.offset_right = 0.0 if RecoveryModules.has_recovery(action) else -host.ACTION_PROGRESS_RAIL_INSET
		progress.offset_top = -host.ACTION_PROGRESS_RAIL_HEIGHT
		progress.offset_bottom = -host.ACTION_PROGRESS_RAIL_INSET
		_apply_recovery_progress_rail_shape(progress, action)
		progress.z_index = 232
		progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pop_card.add_child(progress)

	var border: ActivityCardBorder = null
	if host.ACTION_CARD_FACE_BORDER_ENABLED:
		border = ActivityCardBorder.new()
		border.set_anchors_preset(Control.PRESET_FULL_RECT)
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		border.z_index = host.ACTION_CARD_FACE_BORDER_Z_INDEX
		if RecoveryModules.has_recovery(action):
			border.bottom_shape = "wide_u"
			border.wide_u_bottom_rise = RECOVERY_WIDE_U_BOTTOM_RISE
		pop_card.add_child(border)
	var action_id = str(action.get("id", ""))
	var lock_overlay = host._skill_detail_surface()._activity_lock_overlay(pop_card, int(action.get("unlock", 1)), skill_id, host._skill_detail_surface()._lock_requirements_for_overlay(skill_id, action)) if not host._is_action_unlocked(skill_id, action) else {}
	if not lock_overlay.is_empty():
		host._skill_detail_surface()._connect_activity_lock_handler(lock_overlay, skill_id, action_id)
	var card = {
		"root": card_root,
		"skill_id": skill_id,
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
		"status": null,
		"medal": medal,
		"mastery": mastery_progress,
		"progress": progress,
		"fluid_strip": fluid_strip,
		"blue_guy_chicken_stage": blue_guy_chicken_stage,
		"border": border,
		"lock_overlay": lock_overlay,
		"action": action,
		"medal_destination": Vector2(medal.offset_left, medal.offset_top) if medal != null else Vector2.ZERO
	}
	return {"root": card_root, "card": card}




func _play_activity_preview_fade_in(card: Dictionary) -> void:
	card["fade_in_pending"] = false
	host._hold_skill_detail_layout_refresh(host.ACTIVITY_PREVIEW_FADE_IN_SECONDS + 0.18)
	var root = host._valid_control_ref(card.get("root"))
	if root == null or root.is_queued_for_deletion():
		return
	host._app_lifecycle_runtime()._kill_card_tween(card, "preview_fade_tween")
	var pop = host._valid_control_ref(card.get("pop"))
	var expand_from_zero = card.has("preview_enter_target_height")
	var smooth_unlock_reveal = bool(card.get("unlock_next_preview_smooth", false))
	var stable_preview_fade = bool(card.get("stable_preview_fade", false))
	var target_height = float(card.get("preview_enter_target_height", root.custom_minimum_size.y))
	var entry_target_height = float(card.get("preview_enter_entry_target_height", host._activity_preview_entry_height(card, root, target_height)))
	var skill_id = str(card.get("skill_id", host.selected_skill_id))
	var action = card.get("action", {}) as Dictionary
	var action_id = str(action.get("id", card.get("action_id", "")))
	var card_key = str(card.get("card_key", host._action_key(skill_id, action_id)))
	var lock_overlay = card.get("lock_overlay", {}) as Dictionary
	var lock_rig = host._state_object_ref(lock_overlay.get("group"))
	var show_lock_fade = (
		lock_rig != null
		and not action.is_empty()
		and not host._is_action_unlocked(skill_id, action)
	)
	var show_onboarding_level_up_tip = (
		host._onboarding_runtime()._onboarding_path_active()
		and skill_id == host.TUTORIAL_STARTER_SKILL_ID
		and not action.is_empty()
		and str(action.get("id", "")) == host._first_locked_action_id(skill_id)
		and int(action.get("unlock", 0)) == 2
		and host._skill_level(skill_id) < 2
		and bool(card.get("unlock_next_preview_smooth", false))
	)
	if host._should_release_onboarding_first_module_centering_for_preview(skill_id, action):
		host._release_onboarding_first_module_centering()
	if show_onboarding_level_up_tip:
		host._fade_out_onboarding_mastery_tip(host.ACTIVITY_PREVIEW_FADE_IN_SECONDS)
		host._fade_out_onboarding_medal_tip(host.ACTIVITY_PREVIEW_FADE_IN_SECONDS)
	if show_lock_fade:
		host._skill_detail_surface()._set_activity_lock_overlay_active(lock_overlay, true)
		host._set_canvas_item_modulate_if_changed(lock_rig, Color(1, 1, 1, 0))
		lock_rig.reset_unlock_drop_animation()
		if lock_rig.has_method("_layout_base"):
			lock_rig.call("_layout_base")
	var scroll_preserve_context = {}
	host._set_canvas_item_visible_if_changed(root, true)
	host._set_canvas_item_modulate_if_changed(root, Color(1, 1, 1, 0))
	if expand_from_zero:
		scroll_preserve_context = host._detail_scroll_height_change_preserve_context(root)
		host._set_control_minimum_height(root, 0.0)
		host._set_activity_preview_entry_height(card, root, 0.0)
		root.clip_contents = true
		if not scroll_preserve_context.is_empty():
			host._apply_detail_scroll_height_change_preserve_context(0.0, scroll_preserve_context)
	if pop != null:
		host._set_preview_pop_vertical_offset(pop, 0.0 if stable_preview_fade else host.ACTIVITY_UNLOCK_NEXT_PREVIEW_SETTLE_OFFSET if smooth_unlock_reveal else 34.0)
	var tween = host.create_tween()
	card["preview_fade_tween"] = tween
	tween.set_parallel(true)
	var root_id = root.get_instance_id()
	tween.tween_method(
		Callable(host, "_set_canvas_item_alpha_safe").bind(root_id),
		0.0,
		1.0,
		host.ACTIVITY_PREVIEW_FADE_IN_SECONDS
	).set_trans(Tween.TRANS_SINE if smooth_unlock_reveal else Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if show_lock_fade:
		var lock_rig_fade_id = lock_rig.get_instance_id()
		tween.tween_method(
			Callable(host, "_set_canvas_item_alpha_safe").bind(lock_rig_fade_id),
			0.0,
			1.0,
			host.ACTIVITY_PREVIEW_FADE_IN_SECONDS
		).set_trans(Tween.TRANS_SINE if smooth_unlock_reveal else Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if expand_from_zero:
		tween.tween_method(
			Callable(host, "_set_control_minimum_height_safe").bind(root_id),
			0.0,
			target_height,
			host.ACTIVITY_PREVIEW_FADE_IN_SECONDS
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if not scroll_preserve_context.is_empty():
			tween.tween_method(
				Callable(host, "_apply_detail_scroll_height_change_preserve_context").bind(scroll_preserve_context),
				0.0,
				1.0,
				host.ACTIVITY_PREVIEW_FADE_IN_SECONDS
			).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
		var entry = host._activity_preview_entry_control(card, root)
		if entry != null:
			var entry_id = entry.get_instance_id()
			tween.tween_method(
				Callable(host, "_set_control_minimum_height_safe").bind(entry_id),
				0.0,
				entry_target_height,
				host.ACTIVITY_PREVIEW_FADE_IN_SECONDS
			).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if pop != null:
		var start_offset = 0.0 if stable_preview_fade else host.ACTIVITY_UNLOCK_NEXT_PREVIEW_SETTLE_OFFSET if smooth_unlock_reveal else 34.0
		var pop_offset_id = pop.get_instance_id()
		tween.tween_method(
			Callable(host, "_set_preview_pop_vertical_offset_safe").bind(pop_offset_id),
			start_offset,
			0.0,
			host.ACTIVITY_PREVIEW_FADE_IN_SECONDS
		).set_trans(Tween.TRANS_QUINT if smooth_unlock_reveal else Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var level_up_tip: Control = null
	if show_onboarding_level_up_tip:
		level_up_tip = host._ensure_onboarding_level_up_tip(card)
		if level_up_tip != null and is_instance_valid(level_up_tip):
			level_up_tip.modulate.a = 0.0
			host._sync_onboarding_level_up_tip_position(card)
			tween.tween_property(level_up_tip, "modulate:a", 1.0, host.ACTIVITY_PREVIEW_FADE_IN_SECONDS).set_trans(Tween.TRANS_SINE if smooth_unlock_reveal else Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_method(
				Callable(host, "_sync_onboarding_level_up_tip_position_by_key").bind(card_key),
				0.0,
				1.0,
				host.ACTIVITY_PREVIEW_FADE_IN_SECONDS
			)
	var pop_id = pop.get_instance_id() if pop != null else 0
	var lock_rig_id = lock_rig.get_instance_id() if lock_rig != null else 0
	tween.finished.connect(Callable(host, "_finish_activity_preview_fade_in").bind(card_key, root_id, pop_id, lock_rig_id, expand_from_zero, target_height, skill_id, action_id))




func _install_activity_button_shell(button: Button, fill: Color, radius: float, gutter: float, depth_offset: Vector2, diagonal_side = "") -> Control:
	if button == null:
		return null
	var empty = StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("hover", empty)
	button.add_theme_stylebox_override("pressed", empty)
	button.add_theme_stylebox_override("disabled", empty)
	button.add_theme_stylebox_override("focus", empty)

	var depth: Control
	if diagonal_side.is_empty():
		var activity_depth = ActivityCardStyles.activity_card_depth_layer(fill, host.ACTION_CARD_3D_DEPTH_OFFSET, host.ACTION_CARD_FACE_RADIUS, host.ACTION_CARD_POP_GUTTER)
		activity_depth.name = "ActivityButtonDepth"
		activity_depth.radius = radius
		activity_depth.depth_offset = depth_offset
		activity_depth.draw_back_plate_bottom_outline = true
		depth = activity_depth
	else:
		var shaped_depth = PageSwitchButtonFace.new()
		shaped_depth.name = "ActivityButtonDepth"
		shaped_depth.side = diagonal_side
		shaped_depth.fill_color = fill.darkened(0.34)
		shaped_depth.ink_color = host.COLOR_INK
		shaped_depth.radius = radius
		shaped_depth.diagonal_radius = 32.0
		shaped_depth.stroke_width = 12.0
		shaped_depth.draw_stroke = false
		shaped_depth.depth_offset = depth_offset
		shaped_depth.anchor_left = 0.0
		shaped_depth.anchor_right = 1.0
		shaped_depth.anchor_top = 0.0
		shaped_depth.anchor_bottom = 1.0
		shaped_depth.offset_left = gutter + depth_offset.x
		shaped_depth.offset_right = -gutter + depth_offset.x
		shaped_depth.offset_top = depth_offset.y
		shaped_depth.offset_bottom = 0.0
		shaped_depth.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shaped_depth.z_index = 0
		depth = shaped_depth
	button.add_child(depth)

	var pop = Control.new()
	pop.name = "ActivityButtonFace"
	pop.anchor_left = 0.0
	pop.anchor_right = 1.0
	pop.anchor_top = 0.0
	pop.anchor_bottom = 1.0
	pop.offset_left = gutter
	pop.offset_right = -gutter
	pop.offset_top = 0.0
	pop.set_meta("activity_button_gutter", gutter)
	pop.set_meta("activity_button_depth_bottom_inset", depth_offset.y)
	pop.offset_bottom = -depth_offset.y
	pop.set_meta("activity_card_depth_node_id", depth.get_instance_id())
	pop.clip_contents = false
	pop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pop.z_index = 1
	button.add_child(pop)

	var face: Control
	if diagonal_side.is_empty():
		var panel_face = Panel.new()
		panel_face.add_theme_stylebox_override("panel", ActivityCardStyles.button_face(fill, radius))
		face = panel_face
	else:
		var shaped_face = PageSwitchButtonFace.new()
		shaped_face.side = diagonal_side
		shaped_face.fill_color = fill
		shaped_face.ink_color = host.COLOR_INK
		shaped_face.radius = radius
		shaped_face.stroke_width = 12.0
		shaped_face.draw_stroke = false
		face = shaped_face
	face.name = "ActivityButtonFaceFill"
	face.set_anchors_preset(Control.PRESET_FULL_RECT)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.z_index = 150
	pop.add_child(face)

	var border: Control = null
	if diagonal_side.is_empty():
		var activity_border = ActivityCardBorder.new()
		activity_border.name = "ActivityButtonBorder"
		activity_border.set_anchors_preset(Control.PRESET_FULL_RECT)
		activity_border.radius = radius
		activity_border.border_color = host.COLOR_INK
		activity_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		activity_border.z_index = host.ACTION_CARD_FACE_BORDER_Z_INDEX
		pop.add_child(activity_border)
		border = activity_border
	if not diagonal_side.is_empty():
		var prism_fill = ActivityCardStyles.prism_connector_overlay(depth_offset, radius, diagonal_side, 12.0, host.COLOR_INK)
		prism_fill.name = "ActivityButtonPrismFill"
		prism_fill.face_gutter = gutter
		prism_fill.face_bottom_inset = depth_offset.y
		prism_fill.side_fill_color = fill.darkened(0.48)
		prism_fill.bottom_fill_color = fill.darkened(0.24)
		prism_fill.draw_strokes = false
		prism_fill.z_index = 140
		button.add_child(prism_fill)
		var prism_connector = ActivityCardStyles.prism_connector_overlay(depth_offset, radius, diagonal_side, 12.0, host.COLOR_INK)
		prism_connector.name = "ActivityButtonPrismConnector"
		prism_connector.face_gutter = gutter
		prism_connector.face_bottom_inset = depth_offset.y
		prism_connector.draw_fill = false
		prism_connector.z_index = host.ACTION_CARD_FACE_BORDER_Z_INDEX + 20
		button.add_child(prism_connector)
		pop.set_meta("activity_card_connector_node_id", prism_connector.get_instance_id())
		pop.set_meta("activity_card_fill_node_id", prism_fill.get_instance_id())

	button.set_meta("activity_button_pop_id", pop.get_instance_id())
	button.set_meta("activity_button_depth_id", depth.get_instance_id())
	button.set_meta("activity_button_face_id", face.get_instance_id())
	button.set_meta("activity_button_border_id", border.get_instance_id() if border != null else 0)
	button.set_meta("activity_button_diagonal_side", diagonal_side)
	button.set_meta("activity_button_depth_offset", depth_offset)
	_set_activity_button_shell_theme(button, fill, false)
	return pop


func _activity_button_target_face_global_rect(button: Button, active: bool) -> Rect2:
	if button == null or not is_instance_valid(button):
		return Rect2()
	var face_rect = button.get_global_rect()
	var pop = host._valid_control_ref(instance_from_id(int(button.get_meta("activity_button_pop_id", 0)))) as Control
	if pop != null:
		face_rect = pop.get_global_rect()
		var current_offset = _activity_button_pop_depth_offset(pop)
		var target_offset: Vector2 = host._meta_vector2(button, "activity_button_depth_offset", host.ACTION_CARD_3D_DEPTH_OFFSET) if active else Vector2.ZERO
		face_rect.position += target_offset - current_offset
	return face_rect


func _set_activity_button_shell_theme(button: Button, fill: Color, active := false, animate_state_change := false) -> void:
	if button == null or not is_instance_valid(button):
		return
	var had_active_state = button.has_meta("activity_button_shell_active")
	var previous_active = bool(button.get_meta("activity_button_shell_active", false))
	if (
		host._navigation_shell()._is_module_utility_nav_button(button)
		and button.has_meta("activity_button_hold_nav_press")
		and host.depressed_activity_shell_buttons.has(button.get_instance_id())
		and button.has_meta("activity_button_hold_nav_target_active")
	):
		var pressed_pending_target_active = bool(button.get_meta("activity_button_hold_nav_target_active", false))
		if pressed_pending_target_active == active:
			button.set_meta("activity_button_shell_fill", fill)
			button.set_meta("activity_button_shell_active", active)
		return
	if button.has_meta("activity_button_hold_nav_press") and not host.depressed_activity_shell_buttons.has(button.get_instance_id()):
		var early_has_pending_nav_target = button.has_meta("activity_button_hold_nav_target_active")
		var early_pending_target_active = bool(button.get_meta("activity_button_hold_nav_target_active", false))
		if early_has_pending_nav_target and early_pending_target_active != active:
			return
	button.set_meta("activity_button_shell_fill", fill)
	button.set_meta("activity_button_shell_active", active)
	var outline_color: Color = host.COLOR_INK
	var depth_control: Control = host._valid_control_ref(instance_from_id(int(button.get_meta("activity_button_depth_id", 0))))
	var depth = depth_control as ActivityCardDepth
	if depth != null:
		depth.back_color = fill.darkened(0.36)
		depth.side_color = fill.darkened(0.48)
		depth.bottom_color = fill.darkened(0.24)
		var highlight = fill.lightened(0.42)
		highlight.a = 0.24
		depth.highlight_color = highlight
		var themed_shadow = fill.darkened(0.72)
		themed_shadow.a = 0.28
		depth.shadow_color = themed_shadow
		depth.queue_redraw()
	elif depth_control is PageSwitchButtonFace:
		var shaped_depth = depth_control as PageSwitchButtonFace
		shaped_depth.fill_color = fill.darkened(0.34)
		shaped_depth.ink_color = host.COLOR_INK
		shaped_depth.queue_redraw()
	var face: Control = host._valid_control_ref(instance_from_id(int(button.get_meta("activity_button_face_id", 0))))
	if face != null:
		var radius: float = host.ACTION_CARD_FACE_RADIUS
		var border = host._valid_control_ref(instance_from_id(int(button.get_meta("activity_button_border_id", 0)))) as ActivityCardBorder
		if border != null:
			radius = border.radius
		if face is Panel:
			(face as Panel).add_theme_stylebox_override("panel", ActivityCardStyles.button_face(fill, radius))
		elif face is PageSwitchButtonFace:
			var shaped_face = face as PageSwitchButtonFace
			shaped_face.fill_color = fill
			shaped_face.ink_color = outline_color
			shaped_face.queue_redraw()
	var outline = host._valid_control_ref(instance_from_id(int(button.get_meta("activity_button_border_id", 0)))) as ActivityCardBorder
	if outline != null:
		outline.border_color = outline_color
		outline.queue_redraw()
	var suppress_state_tween = bool(button.get_meta("activity_button_suppress_next_state_tween", false))
	if suppress_state_tween:
		button.remove_meta("activity_button_suppress_next_state_tween")
	var waiting_for_nav_target = false
	if button.has_meta("activity_button_hold_nav_press") and not host.depressed_activity_shell_buttons.has(button.get_instance_id()):
		var has_pending_nav_target = button.has_meta("activity_button_hold_nav_target_active")
		var pending_target_active = bool(button.get_meta("activity_button_hold_nav_target_active", false))
		waiting_for_nav_target = has_pending_nav_target and pending_target_active != active
		if not has_pending_nav_target or pending_target_active == active:
			button.remove_meta("activity_button_hold_nav_press")
			if has_pending_nav_target:
				button.remove_meta("activity_button_hold_nav_target_active")
	if waiting_for_nav_target:
		return
	if animate_state_change and had_active_state and previous_active != active and not suppress_state_tween:
		_animate_activity_button_shell_to_state(button)
	elif not animate_state_change or not button.has_meta("activity_button_depth_tween"):
		_snap_activity_button_shell_to_state(button)
	elif suppress_state_tween:
		_snap_activity_button_shell_to_state(button)


func _activity_button_shell_target_offset(button: Button) -> Vector2:
	if button == null or not is_instance_valid(button):
		return Vector2.ZERO
	if bool(button.get_meta("activity_button_shell_active", false)):
		return host._meta_vector2(button, "activity_button_depth_offset", host.ACTION_CARD_3D_DEPTH_OFFSET)
	return Vector2.ZERO


func _snap_activity_button_shell_to_state(button: Button) -> void:
	if button == null or not is_instance_valid(button):
		return
	var pop = host._valid_control_ref(instance_from_id(int(button.get_meta("activity_button_pop_id", 0)))) as Control
	if pop == null:
		return
	_kill_activity_button_shell_tween(button)
	_set_activity_button_pop_depth_offset_bound(_activity_button_shell_target_offset(button), pop.get_instance_id())


func _animate_activity_button_shell_to_state(button: Button) -> void:
	if button == null or not is_instance_valid(button):
		return
	var target_offset = _activity_button_shell_target_offset(button)
	var pressing = target_offset.length_squared() > 0.25
	_animate_activity_button_shell_to(
		button,
		target_offset,
		host.ACTION_CARD_3D_PRESS_SECONDS if pressing else host.ACTION_CARD_3D_RELEASE_SECONDS,
		Tween.TRANS_QUAD if pressing else Tween.TRANS_BACK,
		Tween.EASE_OUT
	)


func _activity_button_arrow(button: Button) -> ModuleUtilityCollapseArrow:
	if button == null or not is_instance_valid(button):
		return null
	var direct_arrow = button.get_node_or_null("ActivityButtonArrow") as ModuleUtilityCollapseArrow
	if direct_arrow != null:
		return direct_arrow
	var pop = host._valid_control_ref(instance_from_id(int(button.get_meta("activity_button_pop_id", 0)))) as Control
	if pop == null:
		return null
	return pop.get_node_or_null("ActivityButtonArrow") as ModuleUtilityCollapseArrow


func _activity_button_pop_depth_offset(pop: Control) -> Vector2:
	if pop == null or not is_instance_valid(pop):
		return Vector2.ZERO
	var gutter = float(pop.get_meta("activity_button_gutter", host.ACTION_CARD_POP_GUTTER))
	return Vector2(pop.offset_left - gutter, pop.offset_top)


func _set_activity_button_pop_depth_offset_bound(offset: Vector2, pop_id: int) -> void:
	var pop: Control = host._valid_control_ref(instance_from_id(pop_id))
	if pop == null:
		return
	var gutter = float(pop.get_meta("activity_button_gutter", host.ACTION_CARD_POP_GUTTER))
	var bottom_inset = float(pop.get_meta("activity_button_depth_bottom_inset", host.ACTION_CARD_3D_DEPTH_OFFSET.y))
	pop.offset_left = gutter + offset.x
	pop.offset_right = -gutter + offset.x
	pop.offset_top = offset.y
	pop.offset_bottom = -bottom_inset + offset.y
	host._set_activity_card_depth_face_offset_from_pop(pop, offset)


func _activity_card_pop_depth_offset(pop: Control) -> Vector2:
	if pop == null or not is_instance_valid(pop):
		return Vector2.ZERO
	return Vector2(pop.offset_left - host.ACTION_CARD_POP_GUTTER, pop.offset_top)


func _set_activity_card_pop_depth_offset_bound(offset: Vector2, pop_id: int) -> void:
	var pop: Control = host._valid_control_ref(instance_from_id(pop_id))
	if pop == null:
		return
	pop.offset_left = host.ACTION_CARD_POP_GUTTER + offset.x
	pop.offset_right = -host.ACTION_CARD_POP_GUTTER + offset.x
	pop.offset_top = offset.y
	pop.offset_bottom = host._activity_card_pop_base_bottom_offset(pop) + offset.y
	host._set_activity_card_depth_face_offset_from_pop(pop, offset)


func _action_card_supports_3d_press(card: Dictionary) -> bool:
	if card.is_empty():
		return false
	var pop: Control = host._valid_control_ref(card.get("pop"))
	var depth: Control = host._valid_control_ref(card.get("depth"))
	return pop != null and depth != null


func _queue_action_card_3d_press(action_key: String) -> void:
	if action_key.is_empty() or not host.action_cards.has(action_key):
		return
	_cancel_pending_action_card_3d_press()
	host.action_card_press_visual_token += 1
	host.action_card_press_visual_pending_key = action_key
	_apply_action_card_3d_press_after_delay(action_key, host.action_card_press_visual_token)


func _cancel_pending_action_card_3d_press() -> void:
	if host.action_card_press_visual_pending_key.is_empty():
		return
	host.action_card_press_visual_token += 1
	host.action_card_press_visual_pending_key = ""


func _apply_action_card_3d_press_after_delay(action_key: String, visual_token: int) -> void:
	if host.ACTION_CARD_3D_PRESS_FEEDBACK_DELAY_SECONDS > 0.0:
		await host.get_tree().create_timer(host.ACTION_CARD_3D_PRESS_FEEDBACK_DELAY_SECONDS).timeout
	if visual_token != host.action_card_press_visual_token:
		return
	host.action_card_press_visual_pending_key = ""
	if host.action_card_press_key != action_key or host.action_card_press_dragged or not host.action_card_press_stat_kind.is_empty():
		return
	if host._detail_actions_scroll_suppresses_child_click():
		return
	_press_action_card_3d(action_key)


func _press_action_card_3d(action_key: String) -> void:
	if action_key.is_empty() or not host.action_cards.has(action_key):
		return
	var card := host.action_cards[action_key] as Dictionary
	if not _action_card_supports_3d_press(card):
		return
	card["card_3d_pressed"] = true
	_animate_action_card_depth_to(card, host.ACTION_CARD_3D_PRESS_OFFSET, host.ACTION_CARD_3D_PRESS_SECONDS, Tween.TRANS_QUAD, Tween.EASE_OUT)


func _release_action_card_3d_press(action_key: String) -> void:
	if action_key.is_empty() or not host.action_cards.has(action_key):
		return
	var card := host.action_cards[action_key] as Dictionary
	if not _action_card_supports_3d_press(card):
		return
	card["card_3d_pressed"] = false
	_animate_action_card_depth_to(card, Vector2.ZERO, host.ACTION_CARD_3D_RELEASE_SECONDS, Tween.TRANS_BACK, Tween.EASE_OUT)


func _animate_action_card_3d_click(action_key: String) -> void:
	if action_key.is_empty() or not host.action_cards.has(action_key):
		return
	var card := host.action_cards[action_key] as Dictionary
	if not _action_card_supports_3d_press(card):
		var fallback_pop: Control = host._valid_control_ref(card.get("pop"))
		if fallback_pop != null:
			host._animate_activity_press_effect(fallback_pop, action_key, 0.982)
		return
	var pop: Control = host._valid_control_ref(card.get("pop"))
	if pop == null:
		host._discard_action_card_key(action_key)
		return
	var current := _activity_card_pop_depth_offset(pop)
	if current.length_squared() > 0.25:
		_release_action_card_3d_press(action_key)
		return
	host._app_lifecycle_runtime()._kill_card_tween(card, "depth_press_tween")
	var pop_id := pop.get_instance_id()
	var tween: Tween = host.create_tween()
	card["depth_press_tween"] = tween
	var setter := Callable(self, "_set_activity_card_pop_depth_offset_bound").bind(pop_id)
	tween.tween_method(setter, current, host.ACTION_CARD_3D_PRESS_OFFSET, host.ACTION_CARD_3D_PRESS_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(setter, host.ACTION_CARD_3D_PRESS_OFFSET, Vector2.ZERO, host.ACTION_CARD_3D_RELEASE_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_finish_action_card_3d_click.bind(action_key, pop_id))


func _finish_action_card_3d_click(action_key: String, pop_id: int) -> void:
	var card := host.action_cards.get(action_key, {}) as Dictionary
	if not card.is_empty():
		card.erase("depth_press_tween")
	_set_activity_card_pop_depth_offset_bound(Vector2.ZERO, pop_id)


func _animate_action_card_depth_to(card: Dictionary, target_offset: Vector2, seconds: float, transition: Tween.TransitionType, ease_type: Tween.EaseType) -> void:
	if not _action_card_supports_3d_press(card):
		return
	var pop: Control = host._valid_control_ref(card.get("pop"))
	if pop == null:
		return
	var pop_id := pop.get_instance_id()
	var current := _activity_card_pop_depth_offset(pop)
	if current.distance_squared_to(target_offset) <= 0.01:
		_set_activity_card_pop_depth_offset_bound(target_offset, pop_id)
		return
	host._app_lifecycle_runtime()._kill_card_tween(card, "depth_press_tween")
	var tween: Tween = host.create_tween()
	card["depth_press_tween"] = tween
	var setter := Callable(self, "_set_activity_card_pop_depth_offset_bound").bind(pop_id)
	tween.tween_method(setter, current, target_offset, seconds).set_trans(transition).set_ease(ease_type)
	tween.finished.connect(_finish_action_card_depth_to.bind(str(card.get("card_key", "")), pop_id, target_offset))


func _finish_action_card_depth_to(card_key: String, pop_id: int, target_offset: Vector2) -> void:
	var card := host.action_cards.get(card_key, {}) as Dictionary
	if not card.is_empty():
		card.erase("depth_press_tween")
	if target_offset == Vector2.ZERO:
		_set_activity_card_pop_depth_offset_bound(Vector2.ZERO, pop_id)


func _attach_activity_button_press_animation(button: Button) -> void:
	if button == null or button.has_meta("activity_button_press_attached"):
		return
	button.set_meta("activity_button_press_attached", true)
	host._button_press_runtime().attach_default_button_sfx(button)
	var button_id = button.get_instance_id()
	var down_callable = Callable(self, "_press_activity_button_shell_bound").bind(button_id)
	if not button.button_down.is_connected(down_callable):
		button.button_down.connect(down_callable)
	var up_callable = Callable(self, "_release_activity_button_shell_bound").bind(button_id)
	if not button.button_up.is_connected(up_callable):
		button.button_up.connect(up_callable)


func _press_activity_button_shell_bound(button_id: int) -> void:
	var button: Button = host._valid_button_ref(instance_from_id(button_id))
	if button == null or button.disabled:
		return
	var navigation_shell = host._navigation_shell()
	if navigation_shell._is_module_utility_nav_button(button):
		navigation_shell._prime_module_utility_nav_button_press_state(button)
	if host.depressed_activity_shell_buttons.has(button_id):
		return
	host.depressed_activity_shell_buttons[button_id] = button
	var depth_offset: Vector2 = host._meta_vector2(button, "activity_button_depth_offset", host.ACTION_CARD_3D_DEPTH_OFFSET)
	var pop = host._valid_control_ref(instance_from_id(int(button.get_meta("activity_button_pop_id", 0)))) as Control
	if pop != null and _activity_button_pop_depth_offset(pop).distance_squared_to(depth_offset) <= 0.25:
		return
	_animate_activity_button_shell_to(button, depth_offset, host.ACTION_CARD_3D_PRESS_SECONDS, Tween.TRANS_QUAD, Tween.EASE_OUT)


func _release_activity_button_shell_bound(button_id: int, force_visual_release := false) -> void:
	var button: Button = host._valid_button_ref(instance_from_id(button_id))
	if button == null:
		return
	if not force_visual_release and host._navigation_shell()._page_switch_button_shell_release_preserved(button):
		_hold_activity_button_shell_at_depth(button)
		return
	var was_depressed: bool = host.depressed_activity_shell_buttons.has(button_id)
	host.depressed_activity_shell_buttons.erase(button_id)
	var target_offset = Vector2.ZERO
	var target_active = bool(button.get_meta("activity_button_shell_active", false))
	if target_active:
		target_offset = host._meta_vector2(button, "activity_button_depth_offset", host.ACTION_CARD_3D_DEPTH_OFFSET)
	var pop = host._valid_control_ref(instance_from_id(int(button.get_meta("activity_button_pop_id", 0)))) as Control
	if bool(button.get_meta("activity_button_hold_nav_press", false)):
		var has_pending_nav_target: bool = button.has_meta("activity_button_hold_nav_target_active")
		var pending_target_active = bool(button.get_meta("activity_button_hold_nav_target_active", false))
		if has_pending_nav_target and pending_target_active == target_active:
			button.remove_meta("activity_button_hold_nav_press")
			button.remove_meta("activity_button_hold_nav_target_active")
		else:
			var depth_offset: Vector2 = host._meta_vector2(button, "activity_button_depth_offset", host.ACTION_CARD_3D_DEPTH_OFFSET)
			_kill_activity_button_shell_tween(button)
			if pop != null:
				_set_activity_button_pop_depth_offset_bound(depth_offset, pop.get_instance_id())
			return
	if not was_depressed and pop != null and _activity_button_pop_depth_offset(pop).distance_squared_to(target_offset) <= 0.25:
		return
	_animate_activity_button_shell_to(button, target_offset, host.ACTION_CARD_3D_RELEASE_SECONDS, Tween.TRANS_BACK, Tween.EASE_OUT)


func release_depressed_activity_shell_buttons_if_pointer_left(event: InputEvent) -> void:
	if host.depressed_activity_shell_buttons.is_empty():
		return
	var event_position := Vector2.ZERO
	var has_event_position := false
	if event is InputEventMouseMotion:
		event_position = (event as InputEventMouseMotion).global_position
		has_event_position = true
	elif event is InputEventScreenDrag:
		event_position = (event as InputEventScreenDrag).position
		has_event_position = true
	if not has_event_position:
		return
	for raw_button in host.depressed_activity_shell_buttons.values().duplicate():
		if raw_button == null or not is_instance_valid(raw_button):
			continue
		var button := raw_button as Button
		if button == null:
			continue
		if host._navigation_shell()._page_switch_button_shell_release_preserved(button):
			_hold_activity_button_shell_at_depth(button)
			continue
		if host._button_press_runtime().pointer_inside_button_release_rect(event_position, button):
			continue
		host._button_press_runtime().force_button_unpressed(button)
		_release_activity_button_shell_bound(button.get_instance_id())


func release_all_depressed_activity_shell_buttons() -> void:
	if host.depressed_activity_shell_buttons.is_empty():
		return
	var activity_buttons: Array = host.depressed_activity_shell_buttons.values()
	host.depressed_activity_shell_buttons.clear()
	for raw_button in activity_buttons:
		if raw_button == null or not is_instance_valid(raw_button):
			continue
		var button := raw_button as Button
		if button == null:
			continue
		if host._navigation_shell()._page_switch_button_shell_release_preserved(button):
			_hold_activity_button_shell_at_depth(button)
			continue
		host._button_press_runtime().force_button_unpressed(button)
		_animate_activity_button_shell_to(button, Vector2.ZERO, host.ACTION_CARD_3D_RELEASE_SECONDS, Tween.TRANS_BACK, Tween.EASE_OUT)


func _hold_activity_button_shell_at_depth(button: Button) -> void:
	if button == null or not is_instance_valid(button):
		return
	var button_id = button.get_instance_id()
	host.depressed_activity_shell_buttons[button_id] = button
	host._button_press_runtime().force_button_unpressed(button)
	var depth_offset: Vector2 = host._meta_vector2(button, "activity_button_depth_offset", host.ACTION_CARD_3D_DEPTH_OFFSET)
	var pop = host._valid_control_ref(instance_from_id(int(button.get_meta("activity_button_pop_id", 0)))) as Control
	_kill_activity_button_shell_tween(button)
	if pop != null:
		_set_activity_button_pop_depth_offset_bound(depth_offset, pop.get_instance_id())


func _animate_activity_button_shell_to(button: Button, target_offset: Vector2, seconds: float, transition: Tween.TransitionType, ease_type: Tween.EaseType) -> void:
	if button == null or not is_instance_valid(button):
		return
	var pop = host._valid_control_ref(instance_from_id(int(button.get_meta("activity_button_pop_id", 0)))) as Control
	if pop == null:
		return
	_kill_activity_button_shell_tween(button)
	var pop_id = pop.get_instance_id()
	var current = _activity_button_pop_depth_offset(pop)
	var tween: Tween = host.create_tween()
	button.set_meta("activity_button_depth_tween", tween)
	var setter = Callable(self, "_set_activity_button_pop_depth_offset_bound").bind(pop_id)
	tween.tween_method(setter, current, target_offset, seconds).set_trans(transition).set_ease(ease_type)
	tween.finished.connect(Callable(self, "_finish_activity_button_shell_tween").bind(button.get_instance_id(), pop_id, target_offset))


func _finish_activity_button_shell_tween(button_id: int, pop_id: int, target_offset: Vector2) -> void:
	var button: Button = host._valid_button_ref(instance_from_id(button_id))
	if button != null and button.has_meta("activity_button_depth_tween"):
		button.remove_meta("activity_button_depth_tween")
	if target_offset == Vector2.ZERO:
		_set_activity_button_pop_depth_offset_bound(Vector2.ZERO, pop_id)


func _kill_activity_button_shell_tween(button: Button) -> void:
	host._kill_meta_tween(button, "activity_button_depth_tween")
