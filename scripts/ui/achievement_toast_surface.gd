extends RefCounted

const AchievementState = preload("res://scripts/achievements/state.gd")
const AchievementPresentation = preload("res://scripts/achievements/presentation.gd")
const NavigationShell = preload("res://scripts/ui/navigation_shell.gd")
const CANVAS_LAYER := 128
const SIZE := Vector2(1500, 300)
const GAP := 28.0
const VIEWPORT_MARGIN := Vector2(36, 36)
const EXIT_DELAY := 6.0
const AUTO_EXIT_SECONDS := 0.64
const TAP_EXIT_SECONDS := 0.12
const TAP_SWAP_SECONDS := 0.045
const QUEUE_BADGE_SIZE := Vector2(190, 118)
const QUEUE_BADGE_TOP_OVERHANG := 66.0

var host
var pending_offline_summary_achievements := []
var achievement_toast_layer: CanvasLayer
var achievement_toast_root: Control
var achievement_toasts := []
var achievement_toast_queue := []
var achievement_toast_queue_ids := {}
var achievement_toast_queue_active := false
var reward_italic_font: Font

func _init(host_ref) -> void:
	host = host_ref


func seen_ids() -> Dictionary:
	return host._save_runtime().achievement_toast_seen_ids


func toast_root() -> Control:
	return achievement_toast_root


func transient_work_active() -> bool:
	return achievement_toast_queue_active or not achievement_toasts.is_empty()


func reset_for_shutdown() -> void:
	achievement_toast_layer = null
	achievement_toast_root = null
	achievement_toasts.clear()
	achievement_toast_queue.clear()
	achievement_toast_queue_ids.clear()
	achievement_toast_queue_active = false
	pending_offline_summary_achievements.clear()


func ensure_built() -> void:
	if achievement_toast_root != null and is_instance_valid(achievement_toast_root):
		return
	_build_achievement_toast_layer()


func _build_achievement_toast_layer() -> void:
	achievement_toast_layer = CanvasLayer.new()
	achievement_toast_layer.layer = CANVAS_LAYER
	host.add_child(achievement_toast_layer)

	achievement_toast_root = Control.new()
	achievement_toast_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	achievement_toast_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	achievement_toast_layer.add_child(achievement_toast_root)

func show_pending_completed_toasts() -> void:
	while host._boot_warmup_runtime().active:
		await host.get_tree().process_frame
	while host._save_runtime().pending_post_load_saved_at >= 0 or host._save_runtime().boot_post_load_simulation_scheduled:
		await host.get_tree().process_frame
	await host.get_tree().process_frame
	while host._achievement_overlay_surface().offline_summary_visible():
		await host.get_tree().process_frame
	var showed_toast := false
	for achievement in AchievementState.milestones(host, false):
		var id := str(achievement.get("id", ""))
		if id.is_empty() or not bool(achievement.get("completed", false)):
			continue
		if bool(achievement.get("log_only", false)):
			continue
		if bool(seen_ids().get(id, false)):
			continue
		show_unlocked(achievement)
		showed_toast = true
	if showed_toast:
		host.save_game()

func play_pending_offline_summary_toasts() -> void:
	var achievements: Array = pending_offline_summary_achievements.duplicate()
	pending_offline_summary_achievements.clear()
	show_offline_summary_toasts(achievements)

func show_offline_summary_toasts(achievements: Array) -> void:
	var showed_toast := false
	for achievement in achievements:
		var achievement_def := achievement as Dictionary
		var id := str(achievement_def.get("id", ""))
		if id.is_empty() or bool(seen_ids().get(id, false)):
			continue
		show_unlocked(achievement_def)
		showed_toast = true
	if showed_toast:
		host.save_game()

func show_unlocked(achievement: Dictionary) -> void:
	var achievement_id := str(achievement.get("id", ""))
	if not achievement_id.is_empty():
		seen_ids()[achievement_id] = true
	_queue_achievement_toast(achievement)

func _queue_achievement_toast(achievement: Dictionary) -> void:
	var achievement_id := str(achievement.get("id", ""))
	if not achievement_id.is_empty() and bool(achievement_toast_queue_ids.get(achievement_id, false)):
		return
	var banner_data := achievement.duplicate()
	banner_data["completed"] = true
	achievement_toast_queue.append(banner_data)
	if not achievement_id.is_empty():
		achievement_toast_queue_ids[achievement_id] = true
	_sync_achievement_toast_queue_badges()
	_schedule_achievement_toast_queue()

func _schedule_achievement_toast_queue() -> void:
	if achievement_toast_queue_active:
		return
	achievement_toast_queue_active = true
	call_deferred("_drain_achievement_toast_queue")

func _achievement_toast_queue_blocked() -> bool:
	if host._boot_warmup_runtime().active:
		return true
	if host._save_runtime().pending_post_load_saved_at >= 0 or host._save_runtime().boot_post_load_simulation_scheduled:
		return true
	return host._achievement_overlay_surface().offline_summary_visible()

func _drain_achievement_toast_queue() -> void:
	while host.is_inside_tree():
		while host.is_inside_tree() and _achievement_toast_queue_blocked():
			await host.get_tree().process_frame
		if not host.is_inside_tree():
			break
		_prune_achievement_toasts()
		if not achievement_toasts.is_empty():
			await host.get_tree().process_frame
			continue
		if achievement_toast_queue.is_empty():
			achievement_toast_queue_active = false
			return
		var achievement := achievement_toast_queue.pop_front() as Dictionary
		var achievement_id := str(achievement.get("id", ""))
		if not achievement_id.is_empty():
			achievement_toast_queue_ids.erase(achievement_id)
		_present_achievement_toast(achievement)
		_sync_achievement_toast_queue_badges()
		await host.get_tree().process_frame
	achievement_toast_queue_active = false

func _sync_achievement_toast_queue_badges() -> void:
	var queued_count: int = achievement_toast_queue.size()
	for raw_toast in achievement_toasts:
		var toast := raw_toast as Control
		if not _achievement_toast_live(toast):
			continue
		var badge := _achievement_toast_queue_badge_for_toast(toast)
		if queued_count <= 0:
			if badge != null:
				badge.queue_free()
				toast.remove_meta("achievement_toast_queue_badge_id")
			continue
		if badge == null:
			badge = _achievement_toast_queue_badge()
			toast.add_child(badge)
			toast.set_meta("achievement_toast_queue_badge_id", badge.get_instance_id())
		_update_achievement_toast_queue_badge(toast, badge, queued_count)

func _achievement_toast_queue_badge_for_toast(toast: Control) -> Control:
	if not _achievement_toast_live(toast) or not toast.has_meta("achievement_toast_queue_badge_id"):
		return null
	var badge_id := int(toast.get_meta("achievement_toast_queue_badge_id"))
	var badge: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(badge_id))
	if badge == null or badge.is_queued_for_deletion():
		toast.remove_meta("achievement_toast_queue_badge_id")
		return null
	return badge

func _achievement_toast_queue_badge() -> PanelContainer:
	var badge := PanelContainer.new()
	badge.custom_minimum_size = QUEUE_BADGE_SIZE
	badge.size = QUEUE_BADGE_SIZE
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.z_index = 12
	badge.add_theme_stylebox_override("panel", AchievementPresentation.toast_queue_badge())
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(center)
	var label: Label = host._label("", 58, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_outline_color", host.COLOR_INK)
	label.add_theme_constant_override("outline_size", 8)
	center.add_child(label)
	badge.set_meta("achievement_toast_queue_badge_label_id", label.get_instance_id())
	return badge

func _update_achievement_toast_queue_badge(toast: Control, badge: Control, queued_count: int) -> void:
	var fitted_scale := float(toast.get_meta("achievement_toast_scale", 1.0))
	badge.size = QUEUE_BADGE_SIZE
	badge.custom_minimum_size = QUEUE_BADGE_SIZE
	badge.scale = Vector2(fitted_scale, fitted_scale)
	badge.position = Vector2(
		(toast.size.x - QUEUE_BADGE_SIZE.x * fitted_scale) * 0.5,
		-QUEUE_BADGE_TOP_OVERHANG * fitted_scale
	)
	var label_id := int(badge.get_meta("achievement_toast_queue_badge_label_id", 0))
	var label: Label = host._app_lifecycle_runtime().valid_label_ref(instance_from_id(label_id))
	if label != null:
		label.text = "+%s" % queued_count

func _present_achievement_toast(achievement: Dictionary) -> void:
	_prune_achievement_toasts()
	var canvas_size: Vector2 = host._current_canvas_size()
	var fitted_scale: float = host._fit_scale_to_canvas(SIZE, VIEWPORT_MARGIN)
	var presentation_size: Vector2 = SIZE * fitted_scale
	var banner := Control.new()
	banner.z_index = 4095
	banner.z_as_relative = false
	banner.mouse_filter = Control.MOUSE_FILTER_STOP
	banner.custom_minimum_size = presentation_size
	banner.size = presentation_size
	var toast_parent: Node = achievement_toast_root if achievement_toast_root != null and is_instance_valid(achievement_toast_root) else host
	if toast_parent.is_queued_for_deletion():
		toast_parent = host
	toast_parent.add_child(banner)
	achievement_toasts.append(banner)
	var card: Control = card(achievement)
	card.custom_minimum_size = SIZE
	card.size = SIZE
	card.scale = Vector2(fitted_scale, fitted_scale)
	banner.add_child(card)
	banner.set_meta("achievement_toast_scale", fitted_scale)
	banner.set_meta("achievement_toast_card_id", card.get_instance_id())
	_sync_achievement_toast_queue_badges()

	var toast_index: int = achievement_toasts.size() - 1
	var bottom_inset := minf(NavigationShell.BOTTOM_NAV_HEIGHT, canvas_size.y * 0.22)
	var target_position := Vector2(
		(canvas_size.x - presentation_size.x) * 0.5,
		canvas_size.y - bottom_inset - presentation_size.y - VIEWPORT_MARGIN.y - float(toast_index) * (presentation_size.y + GAP * fitted_scale)
	)
	target_position.x = clampf(
		target_position.x,
		VIEWPORT_MARGIN.x,
		maxf(VIEWPORT_MARGIN.x, canvas_size.x - presentation_size.x - VIEWPORT_MARGIN.x)
	)
	target_position.y = clampf(
		target_position.y,
		VIEWPORT_MARGIN.y,
		maxf(VIEWPORT_MARGIN.y, canvas_size.y - presentation_size.y - VIEWPORT_MARGIN.y)
	)
	banner.position = target_position + Vector2(0, 90.0 * fitted_scale)
	host._app_lifecycle_runtime().set_canvas_item_modulate_if_changed(banner, Color(1, 1, 1, 0))
	banner.scale = Vector2(0.92, 0.92)
	banner.pivot_offset = presentation_size * 0.5
	var exit_offset := Vector2(0, 110.0 * fitted_scale)
	banner.set_meta("achievement_exit_offset", exit_offset)
	var banner_id := banner.get_instance_id()
	banner.gui_input.connect(_on_achievement_toast_gui_input_bound.bind(banner_id, exit_offset))

	var tween: Tween = host.create_tween()
	banner.set_meta("achievement_tween", tween)
	tween.set_parallel(true)
	tween.tween_property(banner, "position", target_position, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(banner, "modulate:a", 1.0, 0.12)
	tween.tween_property(banner, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(banner, "scale", Vector2(1.03, 1.03), 0.14).set_delay(0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(banner, "scale", Vector2.ONE, 0.16).set_delay(0.48).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_interval(EXIT_DELAY)
	tween.chain().tween_callback(_dismiss_achievement_toast_bound.bind(banner_id, exit_offset, true))

func _on_achievement_toast_gui_input_bound(event: InputEvent, banner_id: int, exit_offset: Vector2) -> void:
	var banner: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(banner_id))
	if not _achievement_toast_live(banner):
		return
	_on_achievement_toast_gui_input(event, banner, exit_offset)

func _on_achievement_toast_gui_input(event: InputEvent, banner: Control, exit_offset: Vector2) -> void:
	if _achievement_toast_accepts_dismiss_event(event, banner):
		host._input_routing_shell()._block_background_input_briefly()
		banner.accept_event()
		_dismiss_achievement_toast(banner, exit_offset, false)
		host.get_viewport().set_input_as_handled()

func _route_achievement_toast_input(event: InputEvent) -> bool:
	if achievement_toasts.is_empty():
		return false
	for i in range(achievement_toasts.size() - 1, -1, -1):
		var toast := achievement_toasts[i] as Control
		if toast == null or not is_instance_valid(toast) or not toast.visible or not toast.is_visible_in_tree():
			continue
		if not _achievement_toast_accepts_dismiss_event(event, toast):
			continue
		host._input_routing_shell()._block_background_input_briefly()
		_dismiss_achievement_toast(toast, host._app_lifecycle_runtime().meta_vector2(toast, "achievement_exit_offset", Vector2(0, 110.0)), false)
		return true
	return false

func _achievement_toast_accepts_dismiss_event(event: InputEvent, banner: Control) -> bool:
	if not _achievement_toast_live(banner):
		return false
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
			return false
		return _achievement_toast_contains_canvas_press(banner, event.global_position)
	if event is InputEventScreenTouch:
		if not event.pressed:
			return false
		return _achievement_toast_contains_canvas_press(banner, event.position)
	return false

func _achievement_toast_contains_canvas_press(banner: Control, press_position: Vector2) -> bool:
	if not _achievement_toast_live(banner):
		return false
	var toast_rect := Rect2(Vector2.ZERO, banner.size)
	var canvas_local := banner.get_global_transform_with_canvas().affine_inverse() * press_position
	return toast_rect.has_point(canvas_local)

func _event_points_inside_achievement_toast(event: InputEvent, source: Control = null) -> bool:
	if achievement_toasts.is_empty():
		return false
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
	for raw_toast in achievement_toasts:
		var toast := raw_toast as Control
		if not _achievement_toast_live(toast) or not toast.visible or not toast.is_visible_in_tree():
			continue
		if _achievement_toast_contains_canvas_press(toast, event_position):
			return true
	return false

func _dismiss_achievement_toast(banner: Control, exit_offset: Vector2, automatic := false) -> void:
	if not _achievement_toast_live(banner):
		return
	if bool(banner.get_meta("achievement_card_transitioning", false)):
		if automatic:
			return
		_finish_achievement_toast_card_transition_now(banner)
		return
	elif bool(banner.get_meta("achievement_dismissing", false)):
		if not automatic:
			_finish_achievement_toast_exit_now(banner)
		return
	if not achievement_toast_queue.is_empty():
		_transition_achievement_toast_to_next_card(banner, exit_offset, automatic)
		return
	banner.set_meta("achievement_dismissing", true)
	if not automatic:
		_kill_achievement_toast_tween(banner)
	var tween: Tween = host.create_tween()
	banner.set_meta("achievement_tween", tween)
	tween.set_parallel(true)
	var exit_seconds: float = AUTO_EXIT_SECONDS if automatic else TAP_EXIT_SECONDS
	var slide_offset := exit_offset * (1.35 if automatic else 1.0)
	var fade_seconds: float = exit_seconds * (0.82 if automatic else 0.67)
	tween.tween_property(banner, "position", banner.position + slide_offset, exit_seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT if automatic else Tween.EASE_IN)
	tween.tween_property(banner, "modulate:a", 0.0, fade_seconds).set_delay(0.06 if automatic else 0.0)
	tween.chain().tween_callback(_finish_achievement_toast_exit.bind(banner.get_instance_id()))

func _transition_achievement_toast_to_next_card(banner: Control, exit_offset: Vector2, automatic := false) -> void:
	if not _achievement_toast_live(banner) or bool(banner.get_meta("achievement_card_transitioning", false)):
		return
	if achievement_toast_queue.is_empty():
		_dismiss_achievement_toast(banner, exit_offset, true)
		return
	banner.set_meta("achievement_card_transitioning", true)
	banner.set_meta("achievement_dismissing", true)
	if not automatic:
		_kill_achievement_toast_tween(banner)
	var achievement := achievement_toast_queue.pop_front() as Dictionary
	var achievement_id := str(achievement.get("id", ""))
	if not achievement_id.is_empty():
		achievement_toast_queue_ids.erase(achievement_id)
	var old_card: Control = _achievement_toast_card_for_banner(banner)
	if old_card != null:
		old_card.queue_free()
	var fitted_scale := float(banner.get_meta("achievement_toast_scale", 1.0))
	var card: Control = card(achievement)
	card.custom_minimum_size = SIZE
	card.size = SIZE
	card.scale = Vector2(fitted_scale, fitted_scale)
	host._app_lifecycle_runtime().set_canvas_item_modulate_if_changed(card, Color.WHITE)
	banner.add_child(card)
	banner.move_child(card, 0)
	banner.set_meta("achievement_toast_card_id", card.get_instance_id())
	_sync_achievement_toast_queue_badges()
	banner.scale = Vector2(0.94, 0.94)
	host._app_lifecycle_runtime().set_canvas_item_alpha_if_changed(banner, 1.0)
	var banner_id := banner.get_instance_id()
	var tween: Tween = host.create_tween()
	banner.set_meta("achievement_tween", tween)
	tween.set_parallel(true)
	tween.tween_property(banner, "scale", Vector2(1.02, 1.02), TAP_SWAP_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "modulate:a", 1.0, TAP_SWAP_SECONDS)
	tween.chain().tween_property(banner, "scale", Vector2.ONE, TAP_SWAP_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(_finish_achievement_toast_card_transition.bind(banner_id))
	tween.chain().tween_interval(EXIT_DELAY)
	tween.chain().tween_callback(_dismiss_achievement_toast_bound.bind(banner_id, exit_offset, true))

func _achievement_toast_card_for_banner(banner: Control) -> Control:
	if not _achievement_toast_live(banner) or not banner.has_meta("achievement_toast_card_id"):
		return null
	var card_id := int(banner.get_meta("achievement_toast_card_id"))
	var card: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(card_id))
	if card == null or card.is_queued_for_deletion():
		banner.remove_meta("achievement_toast_card_id")
		return null
	return card

func _finish_achievement_toast_card_transition(banner_id: int) -> void:
	var banner: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(banner_id))
	if not _achievement_toast_live(banner):
		return
	_apply_achievement_toast_card_transition_finished(banner)

func _finish_achievement_toast_card_transition_now(banner: Control) -> void:
	if not _achievement_toast_live(banner):
		return
	_kill_achievement_toast_tween(banner)
	_apply_achievement_toast_card_transition_finished(banner)

func _apply_achievement_toast_card_transition_finished(banner: Control) -> void:
	if not _achievement_toast_live(banner):
		return
	banner.scale = Vector2.ONE
	host._app_lifecycle_runtime().set_canvas_item_alpha_if_changed(banner, 1.0)
	banner.set_meta("achievement_card_transitioning", false)
	banner.set_meta("achievement_dismissing", false)
	_sync_achievement_toast_queue_badges()

func _dismiss_achievement_toast_bound(banner_id: int, exit_offset: Vector2, automatic := false) -> void:
	var banner: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(banner_id))
	if not _achievement_toast_live(banner):
		return
	_dismiss_achievement_toast(banner, exit_offset, automatic)

func _finish_achievement_toast_exit(banner_id: int) -> void:
	var banner: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(banner_id))
	if not _achievement_toast_live(banner):
		return
	_apply_achievement_toast_exit_finished(banner)

func _finish_achievement_toast_exit_now(banner: Control) -> void:
	if not _achievement_toast_live(banner):
		return
	_kill_achievement_toast_tween(banner)
	_apply_achievement_toast_exit_finished(banner)

func _apply_achievement_toast_exit_finished(banner: Control) -> void:
	if not _achievement_toast_live(banner):
		return
	_kill_achievement_toast_tween(banner)
	achievement_toasts.erase(banner)
	banner.queue_free()
	_sync_achievement_toast_queue_badges()
	if not achievement_toast_queue.is_empty():
		_schedule_achievement_toast_queue()

func _prune_achievement_toasts() -> void:
	for i in range(achievement_toasts.size() - 1, -1, -1):
		var toast := achievement_toasts[i] as Control
		if not _achievement_toast_live(toast):
			achievement_toasts.remove_at(i)

func _achievement_toast_live(toast: Control) -> bool:
	return toast != null and is_instance_valid(toast) and not toast.is_queued_for_deletion()

func _kill_achievement_toast_tween(banner: Control) -> void:
	if not _achievement_toast_live(banner):
		return
	host._app_lifecycle_runtime()._kill_meta_tween(banner, "achievement_tween")

func card(achievement: Dictionary) -> Control:
	var completed := bool(achievement.get("completed", true))
	var card := PanelContainer.new()
	card.clip_contents = true
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", AchievementPresentation.card(Color("#fffdf8") if completed else Color("#fff6e1"), 34, 10, Callable(host, "_surface_style")))

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	card.add_child(margin)

	var copy := VBoxContainer.new()
	copy.custom_minimum_size = Vector2(SIZE.x - 38, 0)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.size_flags_vertical = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 8)
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(copy)

	var title_label: Label = host._label(_achievement_done_text(achievement), 74, host.COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	title_label.custom_minimum_size = Vector2(0, 88)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_force_toast_ink(title_label)
	if host.app_bold_font != null:
		title_label.add_theme_font_override("font", host.app_bold_font)
	copy.add_child(title_label)

	var reward_label: Label = host._label(_reward_text(achievement), 50, host.COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	reward_label.custom_minimum_size = Vector2(0, 60)
	reward_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	reward_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	reward_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_force_toast_ink(reward_label)
	var italic_font := _reward_italic_font()
	if italic_font != null:
		reward_label.add_theme_font_override("font", italic_font)
	copy.add_child(reward_label)

	return card

func _force_toast_ink(label: Label) -> void:
	label.add_theme_color_override("font_color", host.COLOR_INK)
	label.add_theme_color_override("font_outline_color", Color.TRANSPARENT)

func _reward_italic_font() -> Font:
	if reward_italic_font != null:
		return reward_italic_font
	if host.app_font == null:
		return null
	var font := FontVariation.new()
	font.base_font = host.app_font
	font.variation_transform = Transform2D(Vector2(1, 0), Vector2(-0.18, 1), Vector2.ZERO)
	reward_italic_font = font
	return reward_italic_font

func _achievement_done_text(achievement: Dictionary) -> String:
	var kind := str(achievement.get("kind", ""))
	if kind == "tier_count":
		var medal_name := str(achievement.get("title", "Medals"))
		if medal_name.ends_with(" Medals"):
			medal_name = medal_name.substr(0, medal_name.length() - " Medals".length())
		return "%s %s medals" % [int(achievement.get("target", achievement.get("current", 0))), medal_name]
	if kind == "cumulative_medals":
		return "%s total medals" % int(achievement.get("target", achievement.get("current", 0)))
	if kind == "total_level":
		return "Total level %s" % int(achievement.get("target", achievement.get("current", 0)))
	return str(achievement.get("title", "Achievement"))

func _reward_text(achievement: Dictionary) -> String:
	var reward_text := str(achievement.get("reward", "")).strip_edges()
	if reward_text.is_empty():
		return "Unlocked"
	if reward_text.begins_with("Reward:"):
		reward_text = reward_text.substr("Reward:".length()).strip_edges()
	return reward_text.replace("max stamina", "Max Stamina")

