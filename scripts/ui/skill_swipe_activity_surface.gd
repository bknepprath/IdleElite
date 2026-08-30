extends RefCounted

const ActivityCardBorder = preload("res://scripts/ui/activity_card_border.gd")
const ActivityCardDepth = preload("res://scripts/ui/activity_card_depth.gd")
const ActivityCardStyles = preload("res://scripts/ui/activity_card_styles.gd")
const ActivityUnlockCeremonySurface = preload("res://scripts/ui/activity_unlock_ceremony_surface.gd")
const ActivityProgressRail = preload("res://scripts/ui/activity_progress_rail.gd")
const ActionArtUi = preload("res://scripts/ui/action_art_ui.gd")
const AchievementState = preload("res://scripts/achievements/state.gd")
const AchievementPresentation = preload("res://scripts/achievements/presentation.gd")
const BlueGuyChickenBrawlStageClass = preload("res://scripts/ui/blue_guy_chicken_brawl_stage.gd")
const BuildableModules = preload("res://scripts/gameplay/buildable_modules.gd")
const ConvergenceRuntime = preload("res://scripts/gameplay/convergence_runtime.gd")
const ConvergenceMultiProgressBar = preload("res://scripts/ui/convergence_multi_progress_bar.gd")
const CleanProgressBar = preload("res://scripts/ui/clean_progress_bar.gd")
const FishCircle = preload("res://scripts/ui/fish_circle.gd")
const MobileScrollContainer = preload("res://scripts/ui/mobile_scroll_container.gd")
const ModuleUiRuntime = preload("res://scripts/module_ui/runtime.gd")
const PaperButtonStyles = preload("res://scripts/ui/paper_button_styles.gd")
const PassiveModuleStyles = preload("res://scripts/ui/passive_module_styles.gd")
const PassiveModulesRuntime = preload("res://scripts/gameplay/passive_modules_runtime.gd")
const ProfileChatOverlaySurface = preload("res://scripts/ui/profile_chat_overlay_surface.gd")
const MasteryState = preload("res://scripts/progression/mastery_state.gd")
const ACTION_CARD_MEDAL_STANDARD_SIZE := Vector2(184.68, 184.68)
const ACTION_CARD_MEDAL_CORNER_INSET := Vector2(24, 18)
const ACTION_CARD_MEDAL_WINGED_SIZES := {
	9: Vector2(330.48, 184.68),
	10: Vector2(290.628, 184.68),
	19: Vector2(327.564, 228.42),
	20: Vector2(326.592, 228.42),
}
const RoundedTextureRect = preload("res://scripts/ui/rounded_texture_rect.gd")
const RoundedCornerCropOverlay = preload("res://scripts/ui/rounded_corner_crop_overlay.gd")
const RecoveryModules = preload("res://scripts/gameplay/recovery_modules.gd")
const RegenCircle = preload("res://scripts/ui/regen_circle.gd")
const SkillIconBadge = preload("res://scripts/ui/skill_icon_badge.gd")
const SkillState = preload("res://scripts/progression/skill_state.gd")

const SKILL_SWIPE_SHELF_BACKGROUND_FADE_OUT_SECONDS := 0.18
const SKILL_SWIPE_SHELF_BACKGROUND_FADE_IN_SECONDS := 0.24
const SKILL_SWIPE_FLICK_MIN_DISTANCE := 72.0
const SKILL_SWIPE_FLICK_MIN_VELOCITY := 650.0
const SKILL_SWIPE_FLICK_MAX_RELEASE_DELAY_MSEC := 140

class _MedalShineSlash:
	extends Control

	var shine_color := Color.WHITE
	var progress := 0.0
	var line_width := 14.0
	var coin_center_ratio := Vector2(0.5, 0.43)
	var coin_radius_ratio := 0.38

	func set_progress(next_progress: float) -> void:
		progress = clampf(next_progress, 0.0, 1.0)
		queue_redraw()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func _draw() -> void:
		if size.x <= 1.0 or size.y <= 1.0:
			return
		var center := Vector2(size.x * coin_center_ratio.x, size.y * coin_center_ratio.y)
		var radius := minf(size.x, size.y) * coin_radius_ratio
		var sweep := lerpf(-radius * 1.75, radius * 1.75, progress)
		_draw_coin_clipped_band(center, radius, sweep, line_width * 3.2, Color(shine_color.r, shine_color.g, shine_color.b, shine_color.a * 0.16))
		_draw_coin_clipped_band(center, radius, sweep, line_width * 1.85, Color(shine_color.r, shine_color.g, shine_color.b, shine_color.a * 0.42))
		_draw_coin_clipped_band(center, radius, sweep, line_width * 0.58, Color(shine_color.r, shine_color.g, shine_color.b, shine_color.a * 0.92))

	func _draw_coin_clipped_band(center: Vector2, radius: float, sweep: float, width: float, color: Color) -> void:
		var row_height := 3.0
		var normal_scale := sqrt(2.0)
		var y := center.y - radius
		while y <= center.y + radius:
			var dy := y - center.y
			var circle_half_width := sqrt(maxf(0.0, radius * radius - dy * dy))
			var circle_left := center.x - circle_half_width
			var circle_right := center.x + circle_half_width
			var band_center_x := center.x + sweep * normal_scale - dy
			var band_half_width := width * normal_scale * 0.5
			var left := maxf(circle_left, band_center_x - band_half_width)
			var right := minf(circle_right, band_center_x + band_half_width)
			if right > left:
				draw_line(Vector2(left, y), Vector2(right, y), color, row_height + 0.75, false)
			y += row_height

const RECOVERY_WIDE_U_BOTTOM_RISE := ActivityCardStyles.RECOVERY_WIDE_U_BOTTOM_RISE
const RECOVERY_WIDE_U_SHOULDER_RATIO := ActivityCardStyles.RECOVERY_WIDE_U_SHOULDER_RATIO
const MASTERY_BAR_EASE_SECONDS := 0.16
const ACTION_PROGRESS_TURNOVER_DRAIN_SECONDS := 0.20
const ACTION_PROGRESS_TURNOVER_EMPTY_SECONDS := 0.02
const ACTION_PROGRESS_TURNOVER_RECOVER_SECONDS := 0.18
const ACTION_PROGRESS_TURNOVER_SECONDS := ACTION_PROGRESS_TURNOVER_DRAIN_SECONDS + ACTION_PROGRESS_TURNOVER_EMPTY_SECONDS + ACTION_PROGRESS_TURNOVER_RECOVER_SECONDS
const ACTION_CARD_MEDAL_TAP_SPARKLE_COUNTS := [
	0, # Bronze
	1, # Silver
	2, # Gold
	2, # Platinum
	3, # Sapphire
	3, # Emerald
	4, # Ruby
	4, # Diamond
	5, # Demonic
	5, # Heavenly
	6, # Elite Bronze
	6, # Elite Silver
	7, # Elite Gold
	7, # Elite Platinum
	8, # Elite Sapphire
	8, # Elite Emerald
	9, # Elite Ruby
	10, # Elite Diamond
	15, # Elite Demonic
	20 # Elite Heavenly
]
const ACTION_CARD_MEDAL_TAP_SPARKLE_PALETTES := [
	[Color("#d9852e"), Color("#ffb15c"), Color("#ffd08a")], # Bronze
	[Color("#f4f7ff"), Color("#d5dbe4"), Color("#a9adb7")], # Silver
	[Color("#fff4a8"), Color("#ffd34a"), Color("#ffffff")], # Gold
	[Color("#ffffff"), Color("#e8f7ff"), Color("#c6d6df")], # Platinum
	[Color("#88d8ff"), Color("#3aa0ff"), Color("#0f66ff")], # Sapphire
	[Color("#d2ffd9"), Color("#a9ffbc"), Color("#35d86d"), Color("#1fb655")], # Emerald
	[Color("#ff9aa4"), Color("#e84d4d"), Color("#ff2430")], # Ruby
	[Color("#ffffff"), Color("#bdf3ff"), Color("#8fdcff")], # Diamond
	[Color("#171615"), Color("#3a0507"), Color("#850d12"), Color("#e1121b")], # Demonic
	[Color("#ffffff"), Color("#fff0ba"), Color("#ffe37a")], # Heavenly
	[Color("#ffb15c"), Color("#ffcf92"), Color("#c06d2c"), Color("#fff0ba")], # Elite Bronze
	[Color("#ffffff"), Color("#dce4ef"), Color("#aeb9c8"), Color("#cfefff")], # Elite Silver
	[Color("#fff4a8"), Color("#ffd32f"), Color("#ffffff"), Color("#ffec66")], # Elite Gold
	[Color("#ffffff"), Color("#f1ebe0"), Color("#d9f7ff"), Color("#c5d7e6")], # Elite Platinum
	[Color("#7fd1ff"), Color("#1f82ff"), Color("#35e8ff"), Color("#005eff")], # Elite Sapphire
	[Color("#d2ffd9"), Color("#7dff9b"), Color("#22cc58"), Color("#00a83f")], # Elite Emerald
	[Color("#ff8a94"), Color("#ff2430"), Color("#ff4c6d"), Color("#e01928")], # Elite Ruby
	[Color("#ffffff"), Color("#aeeeff"), Color("#82e7ff"), Color("#d8a8ff")], # Elite Diamond
	[Color("#171615"), Color("#2a0204"), Color("#5a070b"), Color("#9f1017"), Color("#ff2430")], # Elite Demonic
	[Color("#ff3b3b"), Color("#ffd93d"), Color("#48ff6d"), Color("#36e6ff"), Color("#6f7bff"), Color("#ff6bff"), Color("#ff9f1c"), Color("#b8ff2c"), Color("#ff4fd8")] # Elite Heavenly
]
const ACTION_CARD_MEDAL_TAP_EXTRA_SHINE_STEPS := [
	{"level": 8, "delay": 0.30},
	{"level": 15, "delay": 0.52},
	{"level": 20, "delay": 0.72}
]

var host
var skill_swipe_tracking := false
var skill_swipe_horizontal := false
var skill_swipe_start := Vector2.ZERO
var skill_swipe_last := Vector2.ZERO
var skill_swipe_last_motion_msec := 0
var skill_swipe_velocity_x := 0.0
var skill_swipe_touch_index := -1
var skill_swipe_tween: Tween
var skill_swipe_frame: Control
var skill_swipe_page: Control
var skill_swipe_animating := false
var skill_swipe_animation_mode := ""
var skill_swipe_drag_base_x := 0.0
var skill_swipe_drag_offset_x := 0.0
var skill_swipe_gap_render_offset_x := 0.0
var skill_swipe_child_click_suppressed := false
var skill_swipe_button_suppressed_until_msec := 0
var skill_swipe_handoff_cover: Control
var skill_nav_cover_layer: CanvasLayer
var skill_swipe_cover_fade_tween: Tween
var skill_detail_refresh_cover_active := false
var direct_skill_nav_cover_active := false
var skill_swipe_outgoing_cover_active := false
var skill_swipe_rebuild_cover_active := false
var skill_swipe_queued_offset := 0
var skill_swipe_pending_full_finalize := false
var skill_swipe_pending_preview_state := {}
var skill_swipe_defer_initial_lazy_mount := false
var skill_swipe_lazy_finalize_token := 0
var skill_swipe_finalize_schedule_token := 0
var skill_swipe_finalized_lazy_mount_pending := false
var skill_swipe_finalize_ready_process_frame := -1
var skill_swipe_finalize_target_skill_id := ""
var skill_swipe_pending_resume_scroll_skill_id := ""
var real_card_cache_by_skill = {}
var preview_page: Control
var preview_pages = {}
var preview_states = {}
var preview_offset = 0
var preview_module_reveal_token = 0
var light_preview_card_style_cache = {}
var queue_selection_banner: Control
var action_pop_tweens := {}
var depressed_activity_shell_buttons := {}
var action_art_last_running_key := ""
var skill_swipe_paper_fade_overlay: ColorRect
var skill_swipe_paper_fade_hold_alpha := 0.0
var skill_swipe_strip_committed_crossfade := false
var skill_strip_ids: Array = []
var skill_strip_index := 0
var skill_strip_refs := {}
var skill_strip_wrap_relocated_id := ""

func _init(host_ref) -> void:
	host = host_ref

var SKILL_SWIPE_FEEDBACK_DEADZONE: float:
	get: return host.SKILL_SWIPE_FEEDBACK_DEADZONE
var SKILL_SWIPE_PAGE_GAP: float:
	get: return host.SKILL_SWIPE_PAGE_GAP
var SKILL_SWIPE_THRESHOLD: float:
	get: return host.SKILL_SWIPE_THRESHOLD
var SKILL_SWIPE_SETTLE_SECONDS: float:
	get: return host.SKILL_SWIPE_SETTLE_SECONDS
var SKILL_SWIPE_CANCEL_SECONDS: float:
	get: return host.SKILL_SWIPE_CANCEL_SECONDS
var SKILL_SWIPE_GAP_LOAD_TRANSITION_ENABLED: bool:
	get: return host.SKILL_SWIPE_GAP_LOAD_TRANSITION_ENABLED
var SKILL_SWIPE_GAP_READY_WAIT_FRAMES: int:
	get: return host.SKILL_SWIPE_GAP_READY_WAIT_FRAMES
var SKILL_SWIPE_CREAM_COVER_FADE_IN_SECONDS: float:
	get: return host.SKILL_SWIPE_CREAM_COVER_FADE_IN_SECONDS
var SKILL_SWIPE_REBUILD_COVER_FADE_SECONDS: float:
	get: return host.SKILL_SWIPE_REBUILD_COVER_FADE_SECONDS
var SKILL_SWIPE_PAGE_SWITCH_FADE_OUT_SECONDS: float:
	get: return host.SKILL_SWIPE_PAGE_SWITCH_FADE_OUT_SECONDS
var SKILL_SWIPE_PAGE_SWITCH_FADE_IN_SECONDS: float:
	get: return host.SKILL_SWIPE_PAGE_SWITCH_FADE_IN_SECONDS
var SKILL_SWIPE_MODULE_UTILITY_FADE_OUT_SECONDS: float:
	get: return host.SKILL_SWIPE_MODULE_UTILITY_FADE_OUT_SECONDS
var SKILL_SWIPE_MODULE_UTILITY_FADE_IN_SECONDS: float:
	get: return host.SKILL_SWIPE_MODULE_UTILITY_FADE_IN_SECONDS
var SKILL_SWIPE_FINALIZE_SETTLE_FRAMES: int:
	get: return host.SKILL_SWIPE_FINALIZE_SETTLE_FRAMES
var SKILL_SWIPE_BUTTON_SUPPRESS_MSEC: int:
	get: return host.SKILL_SWIPE_BUTTON_SUPPRESS_MSEC
var DIRECT_SKILL_NAV_COVER_MIN_SECONDS: float:
	get: return host.DIRECT_SKILL_NAV_COVER_MIN_SECONDS
var DIRECT_SKILL_NAV_COVER_FADE_IN_SECONDS: float:
	get: return host.DIRECT_SKILL_NAV_COVER_FADE_IN_SECONDS
var DIRECT_SKILL_NAV_COVER_FADE_SECONDS: float:
	get: return host.DIRECT_SKILL_NAV_COVER_FADE_SECONDS
var SKILL_NAV_COVER_CANVAS_LAYER: int:
	get: return host.SKILL_NAV_COVER_CANVAS_LAYER
var SKILLS_PAGE_TOP_PAD: float:
	get: return host.SKILLS_PAGE_TOP_PAD
var TUTORIAL_STARTER_SKILL_ID: String:
	get: return host.TUTORIAL_STARTER_SKILL_ID
var DETAIL_RESTORE_SCROLL_BOTTOM: int:
	get: return host.DETAIL_RESTORE_SCROLL_BOTTOM

var selected_skill_id: String:
	get: return host.selected_skill_id
	set(value): host.selected_skill_id = str(value)
var current_screen: String:
	get: return host.current_screen
	set(value): host.current_screen = str(value)
var skills_page: Control:
	get: return host.skills_page
var skills_content: Control:
	get: return host.skills_content
var skill_defs: Array:
	get: return host.skill_defs
var button_press_runtime:
	get: return host.button_press_runtime
var module_ui_runtime:
	get: return host.module_ui_runtime
var module_ui_pin_refresh_cover_requested: bool:
	get: return host.module_ui_pin_refresh_cover_requested
var module_ui_pending_pin_scroll_anchor: Dictionary:
	get: return host.module_ui_pending_pin_scroll_anchor
var action_cards: Dictionary:
	get: return host.action_cards
var action_card_keys: Array:
	get: return host.action_card_keys
var action_card_press_key: String:
	get: return host._skill_detail_surface().action_card_press_key
	set(value): host._skill_detail_surface().action_card_press_key = str(value)
var action_card_press_stat_kind: String:
	get: return host._skill_detail_surface().action_card_press_stat_kind
	set(value): host._skill_detail_surface().action_card_press_stat_kind = str(value)
var action_card_press_dragged: bool:
	get: return host._skill_detail_surface().action_card_press_dragged
	set(value): host._skill_detail_surface().action_card_press_dragged = bool(value)
var detail_xp_label: Label:
	get: return host._skill_detail_surface().detail_xp_label
	set(value): host._skill_detail_surface().detail_xp_label = value
var detail_xp_bar: CleanProgressBar:
	get: return host._skill_detail_surface().detail_xp_bar
	set(value): host._skill_detail_surface().detail_xp_bar = value
var detail_regen_circle: RegenCircle:
	get: return host._skill_detail_surface().detail_regen_circle
	set(value): host._skill_detail_surface().detail_regen_circle = value
var detail_regen_circle_host: Control:
	get: return host._skill_detail_surface().detail_regen_circle_host
	set(value): host._skill_detail_surface().detail_regen_circle_host = value
var detail_regen_circle_fade_group: CanvasGroup:
	get: return host._skill_detail_surface().detail_regen_circle_fade_group
	set(value): host._skill_detail_surface().detail_regen_circle_fade_group = value
var detail_fish_circle: FishCircle:
	get: return host._skill_detail_surface().detail_fish_circle
	set(value): host._skill_detail_surface().detail_fish_circle = value
var detail_auto_eat_fish_button: TextureButton:
	get: return host._skill_detail_surface().detail_auto_eat_fish_button
	set(value): host._skill_detail_surface().detail_auto_eat_fish_button = value
var detail_header_body: Control:
	get: return host._skill_detail_surface().detail_header_body
	set(value): host._skill_detail_surface().detail_header_body = value
var detail_actions_scroll: MobileScrollContainer:
	get: return host._skill_detail_surface().detail_actions_scroll
	set(value): host._skill_detail_surface().detail_actions_scroll = value
var detail_action_card_nodes: Dictionary:
	get: return host._skill_detail_surface().detail_action_card_nodes
var content_scroll:
	get: return host.content_scroll
var dark_mode_enabled: bool:
	get: return host.dark_mode_enabled
var onboarding_explore_tip_seen: bool:
	get: return host._onboarding_runtime().onboarding_explore_tip_seen
var onboarding_swipe_tip_sequence_running: bool:
	get: return host._onboarding_runtime().onboarding_swipe_tip_sequence_running
var skill_swipe_tip_seen: bool:
	get: return host._onboarding_runtime().skill_swipe_tip_seen
	set(value): host._onboarding_runtime().skill_swipe_tip_seen = bool(value)

func create_tween() -> Tween:
	return host.create_tween()

func get_tree() -> SceneTree:
	return host.get_tree()

func add_child(child: Node, force_readable_name := false, internal := Node.INTERNAL_MODE_DISABLED) -> void:
	host.add_child(child, force_readable_name, internal)

func save_game() -> void:
	host.save_game()

func _skill_swipe_activity_surface():
	return self

func _navigation_shell():
	return host._navigation_shell()

func _skill_detail_surface():
	return host._skill_detail_surface()

func _onboarding_runtime():
	return host._onboarding_runtime()

func _tutorial_overlay_surface():
	return host._tutorial_overlay_surface()

func _passive_firepit_surface():
	return host._passive_firepit_surface()

func _fishing_ui_surface():
	return host._fishing_ui_surface()

func _settings_surface():
	return host._settings_surface()

func _action_runtime():
	return host._action_runtime()

func _activity_unlock_runtime():
	return host._activity_unlock_runtime()

func _passive_modules_runtime():
	return host._passive_modules_runtime()

func _thieving_surface():
	return host._thieving_surface()

func _app_lifecycle_runtime():
	return host._app_lifecycle_runtime()

func _set_canvas_item_visible_if_changed(item: CanvasItem, visible: bool) -> void:
	host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(item, visible)

func _set_canvas_item_modulate_if_changed(item: CanvasItem, modulate: Color) -> void:
	host._app_lifecycle_runtime().set_canvas_item_modulate_if_changed(item, modulate)

func _set_canvas_item_alpha_if_changed(item: CanvasItem, alpha: float) -> void:
	host._app_lifecycle_runtime().set_canvas_item_alpha_if_changed(item, alpha)

func _set_skill_swipe_control_alpha(control: Control, alpha: float) -> void:
	if control == null or not is_instance_valid(control):
		return
	var next_modulate := control.modulate
	next_modulate.a = clampf(alpha, 0.0, 1.0)
	host._app_lifecycle_runtime().set_canvas_item_modulate_if_changed(control, next_modulate)

func _valid_control_ref(value) -> Control:
	return host._app_lifecycle_runtime().valid_control_ref(value)

func _theme_paper_color() -> Color:
	return host._theme_paper_color()

func _skill_content_width() -> float:
	return host._skill_content_width()

func _current_canvas_size() -> Vector2:
	return host._current_canvas_size()

func _skill_index(skill_id: String) -> int:
	return host._skill_index(skill_id)

func _action_key(skill_id: String, action_id: String) -> String:
	return host._action_key(skill_id, action_id)

var main_process_frame_index: int:
	get: return host.main_process_frame_index

func get_viewport() -> Viewport:
	return host.get_viewport()

func _set_skill_strip_page_virtual_pos(skill_id: String, virtual_x: float, _alpha := 1.0) -> void:
	if skill_strip_wrap_relocated_id == skill_id:
		return
	if not skill_strip_wrap_relocated_id.is_empty():
		_restore_skill_strip_wrap_page()
	var refs := skill_strip_refs.get(skill_id, {}) as Dictionary
	var page := refs.get("page") as Control
	if page == null or not is_instance_valid(page):
		return
	var content_width := _skill_content_width()
	page.offset_left = virtual_x
	page.offset_right = virtual_x + content_width
	skill_strip_wrap_relocated_id = skill_id

func _restore_skill_strip_wrap_page() -> void:
	if skill_strip_wrap_relocated_id.is_empty():
		return
	var sid := skill_strip_wrap_relocated_id
	skill_strip_wrap_relocated_id = ""
	var refs := skill_strip_refs.get(sid, {}) as Dictionary
	var page := refs.get("page") as Control
	if page == null or not is_instance_valid(page):
		return
	var page_idx := skill_strip_ids.find(sid)
	if page_idx < 0:
		return
	var content_width := _skill_content_width()
	page.offset_left = float(page_idx) * content_width
	page.offset_right = float(page_idx) * content_width + content_width

func _apply_skill_swipe_drag_offset(drag_x: float) -> void:
	skill_swipe_drag_offset_x = drag_x
	if skill_swipe_frame == null or not is_instance_valid(skill_swipe_frame):
		return
	if not skill_strip_ids.is_empty():
		var page_width := _skill_content_width()
		var left := -float(skill_strip_index) * page_width + drag_x
		skill_swipe_frame.offset_left = left
		skill_swipe_frame.offset_right = left + page_width
		_sync_skill_swipe_drag_frame_fade(drag_x)
		return
	var content_width: float = host._skill_swipe_frame_content_width()
	if skill_swipe_frame.custom_minimum_size.x > 1.0:
		content_width = skill_swipe_frame.custom_minimum_size.x
	_apply_skill_column_layout(skill_swipe_frame, content_width, drag_x)
	_sync_skill_swipe_drag_frame_fade(drag_x)
	_sync_skill_swipe_live_page_fade(drag_x)

func _skill_swipe_navigation_blocks_detail_refresh() -> bool:
	return skill_swipe_animating or skill_swipe_pending_full_finalize

func _repair_blank_detail_lazy_stack() -> bool:
	return host._skill_detail_surface()._repair_blank_detail_lazy_stack()

func _find_named_control_descendant(root: Node, control_name: String) -> Control:
	return host._find_named_control_descendant(root, control_name)

func _complete_passive_module_tip_page_visit(skill_id := selected_skill_id) -> void:
	host._onboarding_runtime()._complete_passive_module_tip_page_visit(skill_id)

func _apply_skill_column_layout(frame: Control, frame_width: float, offset_x: float) -> void:
	frame.anchor_left = 0.0
	frame.anchor_right = 0.0
	frame.anchor_top = 0.0
	frame.anchor_bottom = 1.0
	frame.offset_top = 0.0
	frame.offset_bottom = 0.0
	frame.position = Vector2.ZERO
	frame.custom_minimum_size.x = frame_width
	var left: float = (host._skill_column_host_width() - frame_width) * 0.5 + offset_x
	frame.offset_left = left
	frame.offset_right = left + frame_width

func _normalize_skill_detail_page_layout(page: Control = null) -> void:
	_apply_skill_swipe_drag_offset(0.0)
	if not skill_strip_ids.is_empty():
		return
	var target_page := page
	if target_page == null or not is_instance_valid(target_page):
		target_page = skill_swipe_page
	if target_page != null and is_instance_valid(target_page):
		target_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		target_page.offset_left = 0.0
		target_page.offset_top = 0.0
		target_page.offset_right = 0.0
		target_page.offset_bottom = 0.0
		target_page.position = Vector2.ZERO

func _fishing_rework_active_for_skill(skill_id: String) -> bool:
	return host._fishing_rework_active_for_skill(skill_id)

func _discard_action_card_key(card_key: String) -> void:
	host._skill_detail_surface()._discard_action_card_key(card_key)

func _clear_skills_content_orphans() -> void:
	host._navigation_shell()._clear_skills_content_orphans()

func _finish_render_screen_transition(target_key: String) -> void:
	host._navigation_shell()._finish_render_screen_transition(target_key)

func _clear_page_transient_input_state() -> void:
	host._clear_page_transient_input_state()

func _prepare_skills_page_transition(target_key: String) -> void:
	host._navigation_shell()._prepare_skills_page_transition(target_key)

func _apply_skills_content_layout_for_screen() -> void:
	host._navigation_shell()._apply_skills_content_layout_for_screen()

func _request_swipe_resume_scroll() -> void:
	# Swiping between skill detail pages should leave the incoming page at the
	# viewport chosen by the gesture/finalize handoff. Direct navigation paths
	# still opt into resume scrolling through _render_skill_detail.
	skill_swipe_pending_resume_scroll_skill_id = ""

func _apply_pending_swipe_resume_scroll(expected_skill_id: String = "") -> void:
	var target_skill_id := expected_skill_id if not expected_skill_id.is_empty() else skill_swipe_pending_resume_scroll_skill_id
	if target_skill_id.is_empty() or skill_swipe_pending_resume_scroll_skill_id != target_skill_id:
		return
	if host.current_screen != "skill" or host.selected_skill_id != target_skill_id:
		return
	if _skill_detail_surface().detail_actions_scroll == null or not is_instance_valid(_skill_detail_surface().detail_actions_scroll):
		call_deferred("_apply_pending_swipe_resume_scroll", target_skill_id)
		return
	skill_swipe_pending_resume_scroll_skill_id = ""
	await host._skill_detail_surface()._scroll_to_resume_activity(false)

func _reset_skill_swipe_entry_positions() -> void:
	_restore_skill_strip_wrap_page()
	_normalize_skill_detail_page_layout()

func _ensure_skill_swipe_frame_centered() -> void:
	if skill_swipe_frame == null or not is_instance_valid(skill_swipe_frame):
		return
	if skill_swipe_tracking or skill_swipe_animating:
		_apply_skill_swipe_drag_offset(skill_swipe_drag_offset_x)
		return
	_apply_skill_swipe_drag_offset(0.0)

func _sync_skill_strip_page_visibility(animated: bool) -> void:
	if skill_strip_ids.is_empty():
		return
	var current_idx := skill_strip_index
	var count := skill_strip_ids.size()
	if current_idx < 0 or count <= 0:
		return
	for i in count:
		var k := str(skill_strip_ids[i])
		var k_page := (skill_strip_refs.get(k, {}) as Dictionary).get("page") as Control
		if k_page == null or not is_instance_valid(k_page):
			continue
		var dist := mini(absi(i - current_idx), count - absi(i - current_idx))
		var should_show := dist == 0 or (animated and dist <= 1)
		k_page.visible = should_show
		k_page.process_mode = Node.PROCESS_MODE_INHERIT if dist == 0 else Node.PROCESS_MODE_DISABLED
		if not should_show:
			_set_skill_swipe_control_alpha(k_page, 1.0)

func _register_action_card(card_key: String, card: Dictionary) -> void:
	host._skill_detail_surface()._register_action_card(card_key, card)

func _detail_lazy_finalize_action_card(card: Dictionary, skill_id: String, action: Dictionary, action_id: String) -> void:
	host._skill_detail_surface()._detail_lazy_finalize_action_card(card, skill_id, action, action_id)

func _update_ui(delta: float, instant := false) -> void:
	host._update_ui(delta, instant)

func _swap_skill_strip_refs(skill_id: String) -> void:
	if not skill_strip_refs.has(skill_id):
		return
	_sync_skill_strip_page_visibility(false)
	var refs := skill_strip_refs[skill_id] as Dictionary
	skill_swipe_page = refs.get("page") as Control
	detail_xp_label = refs.get("xp_label") as Label
	detail_xp_bar = refs.get("xp_bar") as CleanProgressBar
	detail_regen_circle = refs.get("regen_circle") as RegenCircle
	detail_regen_circle_host = refs.get("regen_circle_host") as Control
	detail_regen_circle_fade_group = refs.get("regen_circle_fade_group") as CanvasGroup
	detail_fish_circle = refs.get("fish_circle") as FishCircle
	detail_auto_eat_fish_button = refs.get("auto_eat_fish_button") as TextureButton
	host._skill_detail_surface().detail_stamina_bar = refs.get("stamina_bar") as CleanProgressBar
	detail_header_body = refs.get("header_body") as Control
	host._skill_detail_surface().detail_header_left_block = refs.get("header_left_block") as Control
	_skill_detail_surface().detail_actions_scroll = refs.get("actions_scroll") as MobileScrollContainer
	host._skill_detail_surface().detail_unlock_scroll_spacer = refs.get("unlock_scroll_spacer") as Control
	_skill_detail_surface().detail_shelf_shadow_overlay = refs.get("shelf_shadow_overlay") as Control
	_skill_detail_surface()._set_detail_back_button(refs.get("back_button") as BaseButton)
	_skill_detail_surface().detail_action_card_nodes = refs.get("action_card_nodes", {}) as Dictionary
	_skill_detail_surface().detail_rendered_action_ids = refs.get("rendered_action_ids", []) as Array
	_skill_detail_surface().detail_lazy_plan = refs.get("lazy_plan", []) as Array
	_skill_detail_surface().detail_lazy_stack = refs.get("lazy_stack") as VBoxContainer
	_skill_detail_surface().detail_lazy_last_scroll = float(refs.get("lazy_last_scroll", -1.0))
	Callable(_skill_detail_surface(), "_sync_detail_actions_scroll_limit_deferred").call_deferred()

func _sync_current_skill_strip_detail_refs() -> void:
	if skill_strip_ids.is_empty() or selected_skill_id.is_empty() or not skill_strip_refs.has(selected_skill_id):
		return
	var refs := skill_strip_refs[selected_skill_id] as Dictionary
	refs["action_card_nodes"] = _skill_detail_surface().detail_action_card_nodes.duplicate()
	refs["rendered_action_ids"] = _skill_detail_surface().detail_rendered_action_ids.duplicate()
	refs["lazy_plan"] = _skill_detail_surface().detail_lazy_plan.duplicate()
	refs["lazy_stack"] = _skill_detail_surface().detail_lazy_stack
	refs["lazy_last_scroll"] = _skill_detail_surface().detail_lazy_last_scroll
	skill_strip_refs[selected_skill_id] = refs

func _begin_skill_swipe_tracking(pointer_position: Vector2, touch_index: int) -> void:
	if _onboarding_runtime()._onboarding_blocks_skill_swipe():
		if not _onboarding_runtime()._ensure_onboarding_swipe_unlocked(true):
			return
	_skill_detail_surface()._cancel_detail_lazy_settle_warm_mount()
	if not _skill_swipe_animation_blocks_input():
		_interrupt_skill_swipe_animation_for_input()
		_park_skill_swipe_preview()
	skill_swipe_tracking = true
	skill_swipe_horizontal = false
	skill_swipe_start = pointer_position
	skill_swipe_last = pointer_position
	skill_swipe_last_motion_msec = Time.get_ticks_msec()
	skill_swipe_velocity_x = 0.0
	skill_swipe_drag_base_x = _current_skill_swipe_page_x()
	skill_swipe_touch_index = touch_index
	_set_skill_strip_committed_crossfade(false)
	_skill_detail_surface()._queue_skill_detail_and_swipe_texture_prewarm(selected_skill_id)
	_sync_skill_strip_page_visibility(true)


func _route_skill_swipe_button_input(event: InputEvent, source: Control = null) -> bool:
	if current_screen != "skill":
		return false
	if _navigation_shell()._event_points_inside_bottom_nav(event, source):
		_cancel_skill_swipe_feedback(false)
		_skill_detail_surface().action_card_press_key = ""
		return false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_event := event as InputEventMouseButton
		var event_position: Vector2 = host._input_routing_shell()._global_event_position(mouse_event.position, mouse_event.global_position, source)
		if mouse_event.pressed:
			_begin_skill_swipe_tracking(event_position, -1)
		elif skill_swipe_tracking:
			_finish_skill_swipe(event_position)
		return true
	if event is InputEventMouseMotion and skill_swipe_tracking:
		var motion_event := event as InputEventMouseMotion
		_update_skill_swipe_feedback(host._input_routing_shell()._global_event_position(motion_event.position, motion_event.global_position, source))
		return true
	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		var event_position: Vector2 = host._input_routing_shell()._global_event_position(touch_event.position, touch_event.position, source)
		if touch_event.pressed:
			_begin_skill_swipe_tracking(event_position, touch_event.index)
		elif skill_swipe_tracking and touch_event.index == skill_swipe_touch_index:
			_finish_skill_swipe(event_position)
		return true
	if event is InputEventScreenDrag and skill_swipe_tracking:
		var drag_event := event as InputEventScreenDrag
		if drag_event.index == skill_swipe_touch_index:
			_update_skill_swipe_feedback(host._input_routing_shell()._global_event_position(drag_event.position, drag_event.position, source))
			return true
	return false


func _update_skill_swipe_feedback(pointer_position: Vector2) -> void:
	if _onboarding_runtime()._onboarding_blocks_skill_swipe():
		if not _onboarding_runtime()._ensure_onboarding_swipe_unlocked(true):
			skill_swipe_tracking = false
			skill_swipe_touch_index = -1
			skill_swipe_horizontal = false
			return
	var motion_msec := Time.get_ticks_msec()
	var motion_elapsed_msec := motion_msec - skill_swipe_last_motion_msec
	if motion_elapsed_msec > 0 and motion_elapsed_msec <= 120:
		var instant_velocity_x := (pointer_position.x - skill_swipe_last.x) * 1000.0 / float(motion_elapsed_msec)
		skill_swipe_velocity_x = lerpf(skill_swipe_velocity_x, instant_velocity_x, 0.55)
	skill_swipe_last = pointer_position
	skill_swipe_last_motion_msec = motion_msec
	var delta := pointer_position - skill_swipe_start
	var abs_x := absf(delta.x)
	var abs_y := absf(delta.y)
	if _skill_swipe_animation_blocks_input():
		if not skill_swipe_horizontal:
			if abs_y >= SKILL_SWIPE_FEEDBACK_DEADZONE and abs_y > abs_x * 1.15:
				skill_swipe_tracking = false
				skill_swipe_touch_index = -1
				return
			if abs_x < 6.0:
				return
			if abs_x < abs_y * 1.25:
				return
			skill_swipe_horizontal = true
		if skill_swipe_horizontal:
			_suppress_skill_swipe_action_click()
		return
	if not skill_swipe_horizontal:
		if abs_y >= SKILL_SWIPE_FEEDBACK_DEADZONE and abs_y > abs_x * 1.15:
			skill_swipe_tracking = false
			skill_swipe_touch_index = -1
			return
		if abs_x < 6.0:
			return
		if abs_x < abs_y * 1.25:
			return
		skill_swipe_horizontal = true
		return
	if skill_swipe_horizontal:
		_suppress_skill_swipe_action_click()
	if not skill_strip_ids.is_empty():
		var strip_direction := 1.0 if delta.x > 0.0 else -1.0
		var strip_visual_distance := _skill_swipe_visual_distance(abs_x)
		var skill_count := skill_strip_ids.size()
		var page_width := _skill_content_width()
		if strip_direction > 0.0 and skill_strip_index == 0 and _onboarding_runtime()._swipe_offset_accessible(-1):
			_set_skill_strip_page_virtual_pos(str(skill_strip_ids[skill_count - 1]), -page_width)
		elif strip_direction < 0.0 and skill_strip_index == skill_count - 1 and _onboarding_runtime()._swipe_offset_accessible(1):
			_set_skill_strip_page_virtual_pos(str(skill_strip_ids[0]), float(skill_count) * page_width)
		else:
			_restore_skill_strip_wrap_page()
		_apply_skill_swipe_drag_offset(skill_swipe_drag_base_x + strip_direction * strip_visual_distance)
		return
	var target := _skill_swipe_visual_target()
	if target == null:
		return
	var offset := 1 if delta.x < 0.0 else -1
	if not _onboarding_runtime()._swipe_offset_accessible(offset):
		_skill_swipe_activity_surface()._park_skill_swipe_preview()
	var page_direction := 1.0 if delta.x > 0.0 else -1.0
	var page_visual_distance := _skill_swipe_visual_distance(abs_x)
	_skill_swipe_activity_surface()._set_skill_swipe_positions(offset, skill_swipe_drag_base_x + page_direction * page_visual_distance)
	_navigation_shell()._sync_skill_page_switch_modules_for_drag(abs_x)
	_navigation_shell()._sync_skill_swipe_module_utility_row_for_drag(abs_x)


func _skill_swipe_visual_target() -> Control:
	if skill_swipe_frame != null and is_instance_valid(skill_swipe_frame):
		return skill_swipe_frame
	return null


func _skill_swipe_visual_distance(abs_x: float) -> float:
	return clampf(abs_x, 0.0, _skill_swipe_page_span())


func _skill_swipe_page_span() -> float:
	var active_width := _skill_content_width()
	return active_width + SKILL_SWIPE_PAGE_GAP


func _current_skill_swipe_page_x() -> float:
	return skill_swipe_drag_offset_x


func _kill_skill_swipe_tween() -> void:
	if skill_swipe_tween != null and skill_swipe_tween.is_valid():
		skill_swipe_tween.kill()
	skill_swipe_tween = null
	skill_swipe_animating = false
	skill_swipe_animation_mode = ""


func _clear_queued_skill_swipe_navigation() -> void:
	skill_swipe_queued_offset = 0


func _skill_swipe_animation_blocks_input() -> bool:
	return skill_swipe_pending_full_finalize or (
		skill_swipe_animating
		and (skill_swipe_animation_mode == "entry" or skill_swipe_animation_mode == "cancel")
	)


func _interrupt_skill_swipe_animation_for_input() -> void:
	if not skill_swipe_animating:
		return
	if _skill_swipe_animation_blocks_input():
		return
	var mode := skill_swipe_animation_mode
	var offset: int = _skill_swipe_activity_surface()._active_preview_offset()
	var preview_page: Control = _skill_swipe_activity_surface()._active_preview_page()
	if mode == "settle" and offset != 0 and preview_page != null:
		_kill_skill_swipe_tween()
		_navigate_skill_page(offset, 0.0, false, false)
		return
	_kill_skill_swipe_tween()


func _begin_skill_swipe_handoff_cover() -> void:
	_clear_skill_swipe_handoff_cover()
	if skills_page == null or skill_swipe_frame == null or not is_instance_valid(skill_swipe_frame):
		return
	var page: Control = _skill_swipe_activity_surface()._active_preview_page()
	if page == null:
		return
	_skill_swipe_activity_surface()._take_preview_for_handoff(false)

	var cover := Control.new()
	_navigation_shell()._apply_skill_page_cover_bounds(cover, true)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.z_index = 0
	cover.z_as_relative = false
	cover.clip_contents = true
	_ensure_skill_nav_cover_layer().add_child(cover)

	var backing := ColorRect.new()
	backing.color = _theme_paper_color()
	backing.set_anchors_preset(Control.PRESET_FULL_RECT)
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backing.z_index = -1
	cover.add_child(backing)
	if module_ui_pin_refresh_cover_requested or not module_ui_pending_pin_scroll_anchor.is_empty():
		cover.set_meta("module_pin_refresh_opaque_cover", true)
		skill_swipe_handoff_cover = cover
		skill_detail_refresh_cover_active = true
		return
	_skill_swipe_activity_surface()._set_active_preview(null, 0)

	var holder := Control.new()
	holder.position = skill_swipe_frame.global_position
	holder.size = skill_swipe_frame.size
	holder.custom_minimum_size = skill_swipe_frame.size
	holder.clip_contents = true
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.add_child(holder)
	page.reparent(holder)
	page.position = Vector2.ZERO
	page.z_index = 0
	_skill_detail_surface()._add_skill_detail_shadow_overlay_to(cover, SKILLS_PAGE_TOP_PAD + _skill_detail_surface()._skill_detail_shadow_top_y(), _skill_detail_surface().detail_shelf_shadow_alpha)

	skill_swipe_handoff_cover = cover


func _clear_skill_swipe_handoff_cover() -> void:
	if _navigation_shell()._page_switch_scroll_cover_active() and _navigation_shell()._page_switch_render_cover_transition_waiting():
		return
	var was_page_switch_cover: bool = _navigation_shell()._page_switch_scroll_cover_active()
	if not module_ui_pending_pin_scroll_anchor.is_empty():
		if (
			skill_detail_refresh_cover_active
			and skill_swipe_handoff_cover != null
			and is_instance_valid(skill_swipe_handoff_cover)
		):
			return
	_kill_skill_swipe_cover_fade_tween()
	if skill_swipe_handoff_cover != null and is_instance_valid(skill_swipe_handoff_cover):
		skill_swipe_handoff_cover.queue_free()
	skill_swipe_handoff_cover = null
	skill_detail_refresh_cover_active = false
	direct_skill_nav_cover_active = false
	skill_swipe_outgoing_cover_active = false
	skill_swipe_rebuild_cover_active = false
	_navigation_shell()._clear_page_switch_render_cover_transition_state()
	if was_page_switch_cover:
		_navigation_shell()._release_page_switch_transition_button()


func _clear_skill_swipe_handoff_cover_immediate() -> void:
	if _navigation_shell()._page_switch_scroll_cover_active() and _navigation_shell()._page_switch_render_cover_transition_waiting():
		return
	var was_page_switch_cover: bool = _navigation_shell()._page_switch_scroll_cover_active()
	if not module_ui_pending_pin_scroll_anchor.is_empty():
		if (
			skill_detail_refresh_cover_active
			and skill_swipe_handoff_cover != null
			and is_instance_valid(skill_swipe_handoff_cover)
		):
			return
	_kill_skill_swipe_cover_fade_tween()
	if skill_swipe_handoff_cover != null and is_instance_valid(skill_swipe_handoff_cover):
		skill_swipe_handoff_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_canvas_item_visible_if_changed(skill_swipe_handoff_cover, false)
		skill_swipe_handoff_cover.free()
	skill_swipe_handoff_cover = null
	skill_detail_refresh_cover_active = false
	direct_skill_nav_cover_active = false
	skill_swipe_outgoing_cover_active = false
	skill_swipe_rebuild_cover_active = false
	_navigation_shell()._clear_page_switch_render_cover_transition_state()
	if was_page_switch_cover:
		_navigation_shell()._release_page_switch_transition_button()


func _kill_skill_swipe_cover_fade_tween() -> void:
	if skill_swipe_cover_fade_tween != null and skill_swipe_cover_fade_tween.is_valid():
		skill_swipe_cover_fade_tween.kill()
	skill_swipe_cover_fade_tween = null


func _force_skill_swipe_cover_opaque_cream() -> void:
	var cover := skill_swipe_handoff_cover
	if cover == null or not is_instance_valid(cover):
		return
	_kill_skill_swipe_cover_fade_tween()
	_set_canvas_item_visible_if_changed(cover, true)
	_set_canvas_item_modulate_if_changed(cover, Color.WHITE)
	cover.set_meta("swipe_cream_transition_cover", true)
	skill_swipe_outgoing_cover_active = true


func _hold_skill_swipe_cover_for_pending_finalize() -> void:
	var cover := skill_swipe_handoff_cover
	if cover == null or not is_instance_valid(cover):
		return
	_force_skill_swipe_cover_opaque_cream()
	_kill_skill_swipe_cover_fade_tween()
	_set_canvas_item_visible_if_changed(cover, true)
	_set_canvas_item_modulate_if_changed(cover, Color.WHITE)
	skill_swipe_outgoing_cover_active = true
	skill_swipe_rebuild_cover_active = false


func _maybe_release_ready_skill_swipe_cover() -> void:
	if current_screen != "skill" or skill_swipe_pending_full_finalize:
		return
	if skill_swipe_cover_fade_tween != null and skill_swipe_cover_fade_tween.is_valid():
		return
	if not _skill_swipe_handoff_cover_is_opaque_cream_transition():
		return
	if _skill_detail_surface().detail_lazy_plan.is_empty() or action_cards.is_empty():
		return
	_skill_detail_surface()._sync_detail_actions_scroll_limit()
	if not _skill_detail_ready_to_reveal_under_cover():
		return
	skill_swipe_outgoing_cover_active = true
	_fade_clear_skill_swipe_cover(SKILL_SWIPE_REBUILD_COVER_FADE_SECONDS)


func _cancel_skill_swipe_finalize_for_navigation() -> void:
	skill_swipe_pending_full_finalize = false
	skill_swipe_pending_preview_state = {}
	skill_swipe_animating = false
	skill_swipe_animation_mode = ""


func _begin_skill_detail_refresh_cover() -> void:
	if _skill_swipe_navigation_blocks_detail_refresh():
		return
	if (
		skill_detail_refresh_cover_active
		and skill_swipe_handoff_cover != null
		and is_instance_valid(skill_swipe_handoff_cover)
	):
		return
	_clear_skill_swipe_handoff_cover()
	if skills_page == null or not is_instance_valid(skills_page):
		return
	var opaque_pin_refresh := module_ui_pin_refresh_cover_requested or not module_ui_pending_pin_scroll_anchor.is_empty()
	var old_page := skill_swipe_frame
	if old_page == null or not is_instance_valid(old_page):
		if skills_content != null and is_instance_valid(skills_content) and skills_content.get_child_count() > 0:
			old_page = skills_content.get_child(0) as Control
	if not opaque_pin_refresh and (old_page == null or not is_instance_valid(old_page)):
		return
	var cover := Control.new()
	_navigation_shell()._apply_skill_page_cover_bounds(cover, true)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.z_index = 0
	cover.z_as_relative = false
	cover.clip_contents = true
	_ensure_skill_nav_cover_layer().add_child(cover)

	var backing := ColorRect.new()
	backing.color = _theme_paper_color()
	backing.set_anchors_preset(Control.PRESET_FULL_RECT)
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backing.z_index = -1
	cover.add_child(backing)
	if opaque_pin_refresh:
		cover.set_meta("module_pin_refresh_opaque_cover", true)
		skill_swipe_handoff_cover = cover
		skill_detail_refresh_cover_active = true
		return

	var holder := Control.new()
	holder.position = old_page.global_position
	holder.size = old_page.size
	holder.custom_minimum_size = old_page.size
	holder.clip_contents = true
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.add_child(holder)
	old_page.reparent(holder)
	old_page.z_index = 0
	_skill_detail_surface()._add_skill_detail_shadow_overlay_to(cover, SKILLS_PAGE_TOP_PAD + _skill_detail_surface()._skill_detail_shadow_top_y(), _skill_detail_surface().detail_shelf_shadow_alpha)
	skill_swipe_handoff_cover = cover
	skill_detail_refresh_cover_active = true


func _begin_direct_skill_nav_cover() -> void:
	if _skill_swipe_handoff_cover_is_opaque_cream_transition():
		direct_skill_nav_cover_active = true
		return
	_clear_skill_swipe_handoff_cover_immediate()
	var cover := Control.new()
	_navigation_shell()._apply_skill_page_cover_bounds(cover, true)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	cover.z_index = 0
	cover.z_as_relative = false
	cover.clip_contents = true
	cover.modulate = Color(1.0, 1.0, 1.0, 0.0)
	cover.set_meta("swipe_cream_transition_cover", true)
	cover.set_meta("direct_skill_nav_cover", true)
	cover.set_meta("direct_skill_nav_cover_started_msec", Time.get_ticks_msec())
	_ensure_skill_nav_cover_layer().add_child(cover)

	var backing := ColorRect.new()
	backing.color = _theme_paper_color()
	backing.set_anchors_preset(Control.PRESET_FULL_RECT)
	backing.mouse_filter = Control.MOUSE_FILTER_STOP
	cover.add_child(backing)

	skill_swipe_handoff_cover = cover
	direct_skill_nav_cover_active = true
	_start_skill_nav_cover_fade_in(cover)


func _ensure_skill_nav_cover_layer() -> CanvasLayer:
	if skill_nav_cover_layer == null or not is_instance_valid(skill_nav_cover_layer):
		skill_nav_cover_layer = CanvasLayer.new()
		skill_nav_cover_layer.name = "SkillNavCoverLayer"
		skill_nav_cover_layer.layer = SKILL_NAV_COVER_CANVAS_LAYER
		add_child(skill_nav_cover_layer)
	return skill_nav_cover_layer


func _start_skill_nav_cover_fade_in(cover: Control) -> void:
	if cover == null or not is_instance_valid(cover):
		return
	_kill_skill_swipe_cover_fade_tween()
	skill_swipe_cover_fade_tween = create_tween()
	skill_swipe_cover_fade_tween.tween_property(
		cover,
		"modulate:a",
		1.0,
		DIRECT_SKILL_NAV_COVER_FADE_IN_SECONDS
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	skill_swipe_cover_fade_tween.tween_callback(_finish_skill_nav_cover_fade_in.bind(cover.get_instance_id()))


func _finish_skill_nav_cover_fade_in(cover_id: int) -> void:
	if skill_swipe_cover_fade_tween != null and not skill_swipe_cover_fade_tween.is_valid():
		skill_swipe_cover_fade_tween = null
	var cover := _active_skill_swipe_cover_ref(cover_id)
	if cover == null:
		return
	_set_canvas_item_modulate_if_changed(cover, Color.WHITE)


func _fade_clear_direct_skill_nav_cover() -> void:
	var cover := skill_swipe_handoff_cover
	if cover == null or not is_instance_valid(cover) or not bool(cover.get_meta("direct_skill_nav_cover", false)):
		_clear_skill_swipe_handoff_cover_immediate()
		return
	if bool(cover.get_meta("direct_skill_nav_cover_release_pending", false)):
		return
	var started_msec := int(cover.get_meta("direct_skill_nav_cover_started_msec", Time.get_ticks_msec()))
	var elapsed_seconds := float(maxi(0, Time.get_ticks_msec() - started_msec)) / 1000.0
	var remaining_seconds := DIRECT_SKILL_NAV_COVER_MIN_SECONDS - elapsed_seconds
	if remaining_seconds > 0.0:
		cover.set_meta("direct_skill_nav_cover_release_pending", true)
		call_deferred("_fade_clear_direct_skill_nav_cover_after_delay", remaining_seconds)
		return
	_fade_clear_skill_swipe_cover(DIRECT_SKILL_NAV_COVER_FADE_SECONDS)


func _fade_clear_direct_skill_nav_cover_after_delay(delay_seconds: float) -> void:
	await get_tree().create_timer(maxf(0.01, delay_seconds), true, false, true).timeout
	var cover := skill_swipe_handoff_cover
	if cover == null or not is_instance_valid(cover) or not bool(cover.get_meta("direct_skill_nav_cover", false)):
		return
	cover.remove_meta("direct_skill_nav_cover_release_pending")
	_fade_clear_direct_skill_nav_cover()


func _begin_skill_swipe_outgoing_cover() -> Control:
	_clear_skill_swipe_handoff_cover()
	if skills_page == null or skill_swipe_frame == null or not is_instance_valid(skill_swipe_frame):
		return null

	var cover := Control.new()
	_navigation_shell()._apply_skill_page_cover_bounds(cover, true)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.z_index = 0
	cover.z_as_relative = false
	cover.clip_contents = true
	cover.modulate = Color.WHITE
	cover.set_meta("swipe_cream_transition_cover", true)
	if OS.get_environment("IDLE_ELITE_TRACE_SWIPE_COVER") == "1":
		print("SWIPE_COVER_TRACE begin_outgoing selected=%s alpha=%.3f ready=%s placeholders=%s" % [
			selected_skill_id,
			cover.modulate.a,
			str(_skill_detail_ready_to_reveal_under_cover() if current_screen == "skill" else true),
			str(_skill_detail_has_visible_lazy_placeholders() if current_screen == "skill" else false)
		])
	_ensure_skill_nav_cover_layer().add_child(cover)

	var backing := ColorRect.new()
	backing.color = _theme_paper_color()
	backing.set_anchors_preset(Control.PRESET_FULL_RECT)
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.add_child(backing)

	var holder := Control.new()
	var holder_size: Vector2 = skill_swipe_frame.size
	if holder_size.x <= 1.0:
		holder_size.x = _skill_content_width()
	if holder_size.y <= 1.0:
		holder_size.y = _current_canvas_size().y
	holder.position = skill_swipe_frame.global_position
	holder.size = holder_size
	holder.custom_minimum_size = holder_size
	holder.clip_contents = true
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.modulate = Color(1.0, 1.0, 1.0, 0.0) if _skill_swipe_activity_surface()._paper_fade_hold_active() else Color.WHITE
	cover.add_child(holder)
	skill_swipe_frame.reparent(holder)
	skill_swipe_frame.position = Vector2.ZERO
	skill_swipe_frame.z_index = 0
	cover.set_meta("swipe_outgoing_page_holder_id", holder.get_instance_id())

	skill_swipe_handoff_cover = cover
	skill_swipe_outgoing_cover_active = true
	return cover


func _skill_swipe_handoff_cover_is_cream_transition() -> bool:
	return (
		skill_swipe_handoff_cover != null
		and is_instance_valid(skill_swipe_handoff_cover)
		and bool(skill_swipe_handoff_cover.get_meta("swipe_cream_transition_cover", false))
	)


func _skill_swipe_handoff_cover_is_opaque_cream_transition() -> bool:
	return (
		_skill_swipe_handoff_cover_is_cream_transition()
		and skill_swipe_handoff_cover.visible
		and skill_swipe_handoff_cover.modulate.a >= 0.92
	)


func _fade_skill_swipe_cover_to_opaque(seconds: float):
	var cover := skill_swipe_handoff_cover
	if cover == null or not is_instance_valid(cover):
		return
	_set_canvas_item_visible_if_changed(cover, true)
	_set_canvas_item_modulate_if_changed(cover, Color.WHITE)
	var holder_id := int(cover.get_meta("swipe_outgoing_page_holder_id", 0))
	var outgoing_holder: Control = null
	if holder_id != 0:
		outgoing_holder = _valid_control_ref(instance_from_id(holder_id))
	if outgoing_holder != null:
		var tween := create_tween()
		tween.tween_property(outgoing_holder, "modulate:a", 0.0, maxf(0.01, seconds)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		await tween.finished
		outgoing_holder = _valid_control_ref(instance_from_id(holder_id))
		if outgoing_holder != null:
			_set_canvas_item_alpha_if_changed(outgoing_holder, 0.0)
		return
	var next_modulate := cover.modulate
	next_modulate.a = clampf(next_modulate.a, 0.0, 1.0)
	_set_canvas_item_modulate_if_changed(cover, next_modulate)
	if cover.modulate.a >= 0.99:
		_set_canvas_item_modulate_if_changed(cover, Color.WHITE)
		return
	var tween := create_tween()
	tween.tween_property(cover, "modulate:a", 1.0, maxf(0.01, seconds)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	if cover != null and is_instance_valid(cover):
		_set_canvas_item_modulate_if_changed(cover, Color.WHITE)


func _clear_skill_swipe_content_under_cover() -> void:
	if skills_content == null or not is_instance_valid(skills_content):
		return
	if (
		skill_swipe_frame != null
		and is_instance_valid(skill_swipe_frame)
		and not _skill_swipe_handoff_cover_is_opaque_cream_transition()
	):
		_app_lifecycle_runtime()._kill_transient_tweens_in_subtree(skill_swipe_frame)
	while skills_content.get_child_count() > 0:
		var child := skills_content.get_child(0)
		skills_content.remove_child(child)
		child.queue_free()
	skill_swipe_frame = null
	skill_swipe_page = null
	_navigation_shell()._reset_page_control_refs()


func _begin_skill_swipe_rebuild_cover() -> void:
	if skill_swipe_handoff_cover != null and is_instance_valid(skill_swipe_handoff_cover):
		_force_skill_swipe_cover_opaque_cream()
		skill_swipe_outgoing_cover_active = false
		skill_swipe_rebuild_cover_active = true
		return
	_clear_skill_swipe_handoff_cover_immediate()
	if skills_page == null or not is_instance_valid(skills_page):
		return
	var cover := Control.new()
	_navigation_shell()._apply_skill_page_cover_bounds(cover, true)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.z_index = 0
	cover.z_as_relative = false
	cover.clip_contents = true
	cover.modulate = Color.WHITE
	cover.set_meta("swipe_cream_transition_cover", true)
	_ensure_skill_nav_cover_layer().add_child(cover)

	var backing := ColorRect.new()
	backing.color = _theme_paper_color()
	backing.set_anchors_preset(Control.PRESET_FULL_RECT)
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.add_child(backing)

	skill_swipe_handoff_cover = cover
	skill_swipe_rebuild_cover_active = true


func _active_skill_swipe_cover_ref(cover_id: int) -> Control:
	var cover := _valid_control_ref(instance_from_id(cover_id))
	if cover == null or cover != skill_swipe_handoff_cover:
		return null
	return cover


func _fade_clear_skill_swipe_rebuild_cover() -> void:
	if not skill_swipe_rebuild_cover_active and not skill_swipe_outgoing_cover_active:
		return
	_fade_clear_skill_swipe_cover(SKILL_SWIPE_REBUILD_COVER_FADE_SECONDS)


func _fade_clear_skill_swipe_cover(seconds: float) -> void:
	var cover := skill_swipe_handoff_cover
	if cover == null or not is_instance_valid(cover):
		_clear_skill_swipe_handoff_cover_immediate()
		return
	if OS.get_environment("IDLE_ELITE_TRACE_SWIPE_COVER") == "1":
		print("SWIPE_COVER_TRACE fade_clear screen=%s selected=%s pending=%s alpha=%.3f ready=%s placeholders=%s" % [
			current_screen,
			selected_skill_id,
			str(skill_swipe_pending_full_finalize),
			cover.modulate.a,
			str(_skill_detail_ready_to_reveal_under_cover() if current_screen == "skill" else true),
			str(_skill_detail_has_visible_lazy_placeholders() if current_screen == "skill" else false)
		])
	if skill_swipe_pending_full_finalize:
		_hold_skill_swipe_cover_for_pending_finalize()
		return
	if current_screen == "skill" and skill_swipe_defer_initial_lazy_mount and not _navigation_shell()._page_switch_scroll_cover_active():
		_force_skill_swipe_cover_opaque_cream()
		call_deferred("_fade_clear_skill_swipe_cover_after_layout_frame", seconds)
		return
	if current_screen == "skill" and not bool(cover.get_meta("swipe_cover_layout_frame_seen", false)):
		_kill_skill_swipe_cover_fade_tween()
		_set_canvas_item_visible_if_changed(cover, true)
		_set_canvas_item_modulate_if_changed(cover, Color.WHITE)
		cover.set_meta("swipe_cover_layout_frame_seen", true)
		call_deferred("_fade_clear_skill_swipe_cover_after_layout_frame", seconds)
		return
	if current_screen == "skill" and not _navigation_shell()._page_switch_scroll_cover_active() and not _skill_detail_ready_to_reveal_under_cover():
		_hold_skill_swipe_cover_until_detail_ready(seconds, 0)
		return
	if current_screen == "pinned" and not bool(cover.get_meta("pinned_cover_layout_frame_seen", false)):
		_kill_skill_swipe_cover_fade_tween()
		_set_canvas_item_visible_if_changed(cover, true)
		_set_canvas_item_modulate_if_changed(cover, Color.WHITE)
		cover.set_meta("pinned_cover_layout_frame_seen", true)
		call_deferred("_fade_clear_skill_swipe_cover_after_layout_frame", seconds)
		return
	if current_screen == "pinned" and not _pinned_page_ready_to_reveal_under_cover():
		_hold_skill_swipe_cover_until_pinned_ready(seconds, 0)
		return
	if current_screen == "skill" and _navigation_shell()._page_switch_scroll_cover_active():
		_force_skill_detail_reveal_mount_under_cover()
	_start_skill_swipe_cover_fade(seconds)


func _fade_clear_skill_swipe_cover_after_layout_frame(seconds: float) -> void:
	await get_tree().process_frame
	await get_tree().create_timer(1.0 / 120.0, true, false, true).timeout
	_fade_clear_skill_swipe_cover(seconds)


func _start_skill_swipe_cover_fade(seconds: float) -> void:
	var cover := skill_swipe_handoff_cover
	if cover == null or not is_instance_valid(cover):
		_clear_skill_swipe_handoff_cover_immediate()
		return
	if current_screen == "skill" and skill_swipe_defer_initial_lazy_mount and not _navigation_shell()._page_switch_scroll_cover_active():
		_force_skill_swipe_cover_opaque_cream()
		call_deferred("_fade_clear_skill_swipe_cover_after_layout_frame", seconds)
		return
	if current_screen == "skill" and not _navigation_shell()._page_switch_scroll_cover_active() and not _skill_detail_ready_to_reveal_under_cover():
		_hold_skill_swipe_cover_until_detail_ready(seconds, 0)
		return
	if current_screen == "pinned" and not _pinned_page_ready_to_reveal_under_cover():
		_hold_skill_swipe_cover_until_pinned_ready(seconds, 0)
		return
	if current_screen == "skill" and _navigation_shell()._page_switch_scroll_cover_active():
		_force_skill_detail_reveal_mount_under_cover()
	if OS.get_environment("IDLE_ELITE_TRACE_SWIPE_COVER") == "1":
		print("SWIPE_COVER_TRACE start_fade selected=%s alpha=%.3f ready=%s placeholders=%s" % [
			selected_skill_id,
			cover.modulate.a,
			str(_skill_detail_ready_to_reveal_under_cover() if current_screen == "skill" else true),
			str(_skill_detail_has_visible_lazy_placeholders() if current_screen == "skill" else false)
	])
	_kill_skill_swipe_cover_fade_tween()
	var cover_id := cover.get_instance_id()
	skill_swipe_cover_fade_tween = create_tween()
	skill_swipe_cover_fade_tween.tween_method(
		_apply_skill_swipe_cover_fade_alpha.bind(cover_id, seconds),
		cover.modulate.a,
		0.0,
		maxf(0.01, seconds)
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	skill_swipe_cover_fade_tween.tween_callback(_finish_skill_swipe_rebuild_cover_fade.bind(cover_id))


func _apply_skill_swipe_cover_fade_alpha(alpha: float, cover_id: int, seconds: float) -> void:
	var cover := _active_skill_swipe_cover_ref(cover_id)
	if cover == null:
		return
	if current_screen == "skill" and skill_swipe_defer_initial_lazy_mount and not _navigation_shell()._page_switch_scroll_cover_active():
		_force_skill_swipe_cover_opaque_cream()
		if not bool(cover.get_meta("swipe_cover_fade_cancel_requested", false)):
			cover.set_meta("swipe_cover_fade_cancel_requested", true)
			call_deferred("_cancel_skill_swipe_cover_fade_until_ready", cover_id, seconds)
		return
	if current_screen == "skill" and not _navigation_shell()._page_switch_scroll_cover_active() and not _skill_detail_ready_to_reveal_under_cover():
		_set_canvas_item_visible_if_changed(cover, true)
		_set_canvas_item_modulate_if_changed(cover, Color.WHITE)
		if not bool(cover.get_meta("swipe_cover_fade_cancel_requested", false)):
			cover.set_meta("swipe_cover_fade_cancel_requested", true)
			call_deferred("_cancel_skill_swipe_cover_fade_until_ready", cover_id, seconds)
		return
	if current_screen == "pinned" and not _pinned_page_ready_to_reveal_under_cover():
		_set_canvas_item_visible_if_changed(cover, true)
		_set_canvas_item_modulate_if_changed(cover, Color.WHITE)
		if not bool(cover.get_meta("pinned_cover_fade_cancel_requested", false)):
			cover.set_meta("pinned_cover_fade_cancel_requested", true)
			call_deferred("_cancel_skill_swipe_cover_fade_until_pinned_ready", cover_id, seconds)
		return
	_set_canvas_item_alpha_if_changed(cover, alpha)


func _cancel_skill_swipe_cover_fade_until_ready(cover_id: int, seconds: float) -> void:
	var cover := _active_skill_swipe_cover_ref(cover_id)
	if cover == null:
		return
	if not bool(cover.get_meta("swipe_cover_fade_cancel_requested", false)):
		return
	cover.remove_meta("swipe_cover_fade_cancel_requested")
	_kill_skill_swipe_cover_fade_tween()
	_set_canvas_item_visible_if_changed(cover, true)
	_set_canvas_item_modulate_if_changed(cover, Color.WHITE)
	skill_swipe_outgoing_cover_active = true
	_hold_skill_swipe_cover_until_detail_ready(seconds, 0)


func _hold_skill_swipe_cover_until_detail_ready(seconds: float, attempts: int) -> void:
	var cover := skill_swipe_handoff_cover
	if cover == null or not is_instance_valid(cover):
		_clear_skill_swipe_handoff_cover_immediate()
		return
	_kill_skill_swipe_cover_fade_tween()
	_set_canvas_item_visible_if_changed(cover, true)
	_set_canvas_item_modulate_if_changed(cover, Color.WHITE)
	skill_swipe_outgoing_cover_active = true
	if not _skill_detail_ready_to_reveal_under_cover():
		_force_skill_detail_reveal_mount_under_cover()
	if OS.get_environment("IDLE_ELITE_TRACE_SWIPE_COVER") == "1":
		print("SWIPE_COVER_TRACE hold_ready selected=%s attempts=%s alpha=%.3f ready=%s placeholders=%s" % [
			selected_skill_id,
			str(attempts),
			cover.modulate.a,
			str(_skill_detail_ready_to_reveal_under_cover()),
			str(_skill_detail_has_visible_lazy_placeholders())
		])
	if _skill_detail_ready_to_reveal_under_cover():
		_start_skill_swipe_cover_fade(seconds)
		return
	if attempts >= 18:
		_repair_blank_detail_lazy_stack()
		_force_skill_detail_reveal_mount_under_cover()
		if _skill_detail_ready_to_reveal_under_cover():
			_start_skill_swipe_cover_fade(seconds)
			return
	call_deferred("_hold_skill_swipe_cover_until_detail_ready_after_frame", seconds, attempts + 1)


func _hold_skill_swipe_cover_until_detail_ready_after_frame(seconds: float, attempts: int) -> void:
	await get_tree().process_frame
	await get_tree().create_timer(1.0 / 120.0, true, false, true).timeout
	_hold_skill_swipe_cover_until_detail_ready(seconds, attempts)


func _pinned_page_ready_to_reveal_under_cover() -> bool:
	if current_screen != "pinned":
		return true
	if content_scroll == null or not is_instance_valid(content_scroll) or not content_scroll.is_inside_tree():
		return false
	if skills_content == null or not is_instance_valid(skills_content) or not skills_content.is_inside_tree():
		return false
	if _find_named_control_descendant(skills_content, "PinnedActivitiesPage") == null:
		return false
	if _find_named_control_descendant(skills_content, "PinnedActivitiesActiveShelf") == null:
		return false
	return true


func _cancel_skill_swipe_cover_fade_until_pinned_ready(cover_id: int, seconds: float) -> void:
	var cover := _active_skill_swipe_cover_ref(cover_id)
	if cover == null:
		return
	if not bool(cover.get_meta("pinned_cover_fade_cancel_requested", false)):
		return
	cover.remove_meta("pinned_cover_fade_cancel_requested")
	_kill_skill_swipe_cover_fade_tween()
	_set_canvas_item_visible_if_changed(cover, true)
	_set_canvas_item_modulate_if_changed(cover, Color.WHITE)
	skill_swipe_outgoing_cover_active = true
	_hold_skill_swipe_cover_until_pinned_ready(seconds, 0)


func _hold_skill_swipe_cover_until_pinned_ready(seconds: float, attempts: int) -> void:
	var cover := skill_swipe_handoff_cover
	if cover == null or not is_instance_valid(cover):
		_clear_skill_swipe_handoff_cover_immediate()
		return
	_kill_skill_swipe_cover_fade_tween()
	_set_canvas_item_visible_if_changed(cover, true)
	_set_canvas_item_modulate_if_changed(cover, Color.WHITE)
	skill_swipe_outgoing_cover_active = true
	if _pinned_page_ready_to_reveal_under_cover() or attempts >= 18:
		_start_skill_swipe_cover_fade(seconds)
		return
	call_deferred("_hold_skill_swipe_cover_until_pinned_ready_after_frame", seconds, attempts + 1)


func _hold_skill_swipe_cover_until_pinned_ready_after_frame(seconds: float, attempts: int) -> void:
	await get_tree().process_frame
	await get_tree().create_timer(1.0 / 120.0, true, false, true).timeout
	_hold_skill_swipe_cover_until_pinned_ready(seconds, attempts)


func _finish_skill_swipe_rebuild_cover_fade(cover_id: int) -> void:
	skill_swipe_cover_fade_tween = null
	if skill_swipe_pending_full_finalize:
		_hold_skill_swipe_cover_for_pending_finalize()
		return
	var cover := _active_skill_swipe_cover_ref(cover_id)
	if cover == null:
		if skill_swipe_handoff_cover == null or not is_instance_valid(skill_swipe_handoff_cover):
			skill_swipe_handoff_cover = null
		skill_swipe_rebuild_cover_active = false
		return
	if skill_swipe_handoff_cover == cover:
		_clear_skill_swipe_handoff_cover_immediate()


func _cancel_skill_swipe_feedback(animated := true) -> void:
	skill_swipe_tracking = false
	skill_swipe_horizontal = false
	skill_swipe_touch_index = -1
	skill_swipe_drag_base_x = 0.0
	_skill_swipe_activity_surface()._set_skill_strip_committed_crossfade(false)
	if skill_swipe_frame == null or not is_instance_valid(skill_swipe_frame):
		_skill_swipe_activity_surface()._clear_skill_swipe_preview()
		return
	_kill_skill_swipe_tween()
	if animated and absf(skill_swipe_drag_offset_x) > 1.0:
		skill_swipe_animating = true
		skill_swipe_animation_mode = "cancel"
		_navigation_shell()._fade_skill_page_switch_modules(true, SKILL_SWIPE_PAGE_SWITCH_FADE_IN_SECONDS)
		_navigation_shell()._fade_skill_swipe_module_utility_row(true, SKILL_SWIPE_MODULE_UTILITY_FADE_IN_SECONDS)
		_skill_swipe_activity_surface()._fade_skill_shelf_backgrounds(true)
		skill_swipe_tween = create_tween()
		skill_swipe_tween.set_parallel(true)
		var start_drag := skill_swipe_drag_offset_x
		skill_swipe_tween.tween_method(_apply_skill_swipe_drag_offset, start_drag, 0.0, SKILL_SWIPE_CANCEL_SECONDS).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
		var preview_page: Control = _skill_swipe_activity_surface()._active_preview_page()
		if preview_page != null:
			var preview_exit: float = _skill_swipe_activity_surface()._skill_swipe_preview_rest_x(_skill_swipe_activity_surface()._active_preview_offset())
			skill_swipe_tween.tween_property(preview_page, "position:x", preview_exit, SKILL_SWIPE_CANCEL_SECONDS).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
			skill_swipe_tween.tween_property(preview_page, "modulate:a", 0.0, SKILL_SWIPE_CANCEL_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		skill_swipe_tween.finished.connect(_finish_skill_swipe_cancel_tween)
	else:
		_restore_skill_strip_wrap_page()
		_apply_skill_swipe_drag_offset(0.0)
		_sync_skill_strip_page_visibility(false)
		_skill_swipe_activity_surface()._park_skill_swipe_preview()
		_navigation_shell()._fade_skill_page_switch_modules(true, SKILL_SWIPE_PAGE_SWITCH_FADE_IN_SECONDS)
		_navigation_shell()._fade_skill_swipe_module_utility_row(true, SKILL_SWIPE_MODULE_UTILITY_FADE_IN_SECONDS)
		_skill_swipe_activity_surface()._fade_skill_shelf_backgrounds(true)


func _finish_skill_swipe(end_position: Vector2) -> void:
	if _onboarding_runtime()._onboarding_blocks_skill_swipe():
		if not _onboarding_runtime()._ensure_onboarding_swipe_unlocked(true):
			skill_swipe_tracking = false
			skill_swipe_touch_index = -1
			skill_swipe_horizontal = false
			_cancel_skill_swipe_feedback(true)
			if skill_swipe_child_click_suppressed:
				call_deferred("_clear_skill_swipe_action_click_suppression")
			return
	var delta: Vector2 = end_position - skill_swipe_start
	var was_horizontal := skill_swipe_horizontal
	var abs_x := absf(delta.x)
	var release_msec := Time.get_ticks_msec()
	var recent_motion := release_msec - skill_swipe_last_motion_msec <= SKILL_SWIPE_FLICK_MAX_RELEASE_DELAY_MSEC
	var flick_direction_matches := signf(skill_swipe_velocity_x) == signf(delta.x)
	var flick_commits := (
		was_horizontal
		and abs_x >= SKILL_SWIPE_FLICK_MIN_DISTANCE
		and recent_motion
		and flick_direction_matches
		and absf(skill_swipe_velocity_x) >= SKILL_SWIPE_FLICK_MIN_VELOCITY
	)
	var direction_is_horizontal := was_horizontal or abs_x >= absf(delta.y) * 1.35
	skill_swipe_tracking = false
	skill_swipe_touch_index = -1
	skill_swipe_drag_base_x = 0.0
	if (abs_x < SKILL_SWIPE_THRESHOLD and not flick_commits) or not direction_is_horizontal:
		if _skill_swipe_animation_blocks_input():
			if skill_swipe_child_click_suppressed:
				call_deferred("_clear_skill_swipe_action_click_suppression")
			return
		_cancel_skill_swipe_feedback(true)
		if skill_swipe_child_click_suppressed:
			call_deferred("_clear_skill_swipe_action_click_suppression")
		return
	if _skill_swipe_animation_blocks_input():
		_queue_skill_swipe_navigation(1 if delta.x < 0.0 else -1)
		_suppress_skill_swipe_action_click()
		if skill_swipe_child_click_suppressed:
			call_deferred("_clear_skill_swipe_action_click_suppression")
		return
	_update_skill_swipe_feedback(end_position)
	var offset := 1 if delta.x < 0.0 else -1
	if not _onboarding_runtime()._swipe_offset_accessible(offset):
		_cancel_skill_swipe_feedback(true)
		if skill_swipe_child_click_suppressed:
			call_deferred("_clear_skill_swipe_action_click_suppression")
		return
	_commit_skill_swipe(offset)
	if skill_swipe_child_click_suppressed:
		call_deferred("_clear_skill_swipe_action_click_suppression")


func _suppress_skill_swipe_action_click() -> void:
	skill_swipe_child_click_suppressed = true
	_passive_firepit_surface()._invalidate_passive_button_tap()
	skill_swipe_button_suppressed_until_msec = Time.get_ticks_msec() + SKILL_SWIPE_BUTTON_SUPPRESS_MSEC
	get_viewport().set_input_as_handled()


func _clear_skill_swipe_action_click_suppression() -> void:
	skill_swipe_child_click_suppressed = false


func _clear_skill_swipe_button_suppression() -> void:
	skill_swipe_child_click_suppressed = false
	skill_swipe_button_suppressed_until_msec = 0


func _skill_swipe_suppresses_button_action() -> bool:
	return skill_swipe_child_click_suppressed or Time.get_ticks_msec() < skill_swipe_button_suppressed_until_msec


func _collapse_expanded_activity_modules() -> void:
	_skill_detail_surface()._clear_activity_stat_popup()
	_passive_firepit_surface()._clear_passive_button_press()
	for raw_card in action_cards.values():
		var card := raw_card as Dictionary
		var info_popover := card.get("info_popover") as Control
		if info_popover != null and is_instance_valid(info_popover):
			_passive_firepit_surface()._schedule_passive_info_popover_dismiss(info_popover)
		var root := card.get("root") as Control
		if root != null and is_instance_valid(root) and card.has("bonus_panel"):
			_skill_detail_surface()._set_activity_card_expanded(card, root, false, true)
			card.erase("bonus_displayed_stat_kind")
			card.erase("bonus_pending_stat_kind")


func _commit_skill_swipe(offset: int) -> void:
	skill_swipe_horizontal = false
	if offset != 0 and skill_strip_ids.is_empty():
		_navigation_shell()._fade_skill_page_switch_modules(false, SKILL_SWIPE_PAGE_SWITCH_FADE_OUT_SECONDS)
		_navigation_shell()._fade_skill_swipe_module_utility_row(false, SKILL_SWIPE_MODULE_UTILITY_FADE_OUT_SECONDS)
		_skill_swipe_activity_surface()._fade_skill_shelf_backgrounds(false)
	var entry_x := signi(offset) * _skill_swipe_page_span()
	entry_x = skill_swipe_drag_offset_x
	var animate_commit_release := absf(entry_x) > 1.0 and absf(entry_x) < absf(_skill_swipe_commit_release_target_x(offset)) - 1.0
	if not animate_commit_release:
		if skill_strip_ids.is_empty():
			_skill_swipe_activity_surface()._hold_skill_swipe_paper_fade_for_commit()
		else:
			_skill_swipe_activity_surface()._set_skill_strip_committed_crossfade(true)
			_skill_swipe_activity_surface()._hide_skill_swipe_paper_fade()
	var outgoing_skill_id := selected_skill_id
	if offset != 0 and outgoing_skill_id == "fishing" and _fishing_ui_surface().is_fishing_tool_wallet_open():
		_fishing_ui_surface()._clear_fishing_tool_circle_menu()
	if offset != 0 and outgoing_skill_id == TUTORIAL_STARTER_SKILL_ID:
		_onboarding_runtime()._clear_tutorial_gate_latch_only_after_skill_swipe(false)
	_complete_passive_module_tip_page_visit(outgoing_skill_id)
	_onboarding_runtime()._complete_silver_opportunity_tip_page_visit(outgoing_skill_id)
	if offset != 0 and _onboarding_runtime()._onboarding_path_active():
		if onboarding_explore_tip_seen:
			_onboarding_runtime()._graduate_onboarding_tutorial()
		elif outgoing_skill_id == TUTORIAL_STARTER_SKILL_ID:
			_tutorial_overlay_surface()._fade_tip_group("skill_swipe_tip_notes", false, true)
			_tutorial_overlay_surface().fade_out_onboarding_swipe_overlay_tip()
			if not skill_swipe_tip_seen:
				skill_swipe_tip_seen = true
				save_game()
	if animate_commit_release:
		_animate_skill_swipe_commit_release(offset, entry_x)
	else:
		_navigate_skill_page(offset, entry_x, true, false)
	action_card_press_key = ""
	action_card_press_stat_kind = ""
	action_card_press_dragged = false
	_passive_firepit_surface()._clear_passive_button_press()
	module_ui_runtime.clear_module_pin_press()
	_clear_skill_swipe_button_suppression()


func _animate_skill_swipe_commit_release(offset: int, start_x: float) -> void:
	if offset == 0 or skill_swipe_frame == null or not is_instance_valid(skill_swipe_frame):
		_navigate_skill_page(offset, start_x, true, false)
		return
	if not skill_strip_ids.is_empty():
		_skill_swipe_activity_surface()._set_skill_strip_committed_crossfade(false)
	_kill_skill_swipe_tween()
	skill_swipe_animating = true
	skill_swipe_animation_mode = "settle"
	_skill_swipe_activity_surface()._set_active_preview(_skill_swipe_activity_surface()._active_preview_page(), offset)
	var swipe_surface = _skill_swipe_activity_surface()
	var target_x := _skill_swipe_commit_release_target_x(offset)
	var remaining_ratio := clampf(absf(target_x - start_x) / maxf(1.0, _skill_swipe_commit_release_span()), 0.0, 1.0)
	var settle_seconds := clampf(SKILL_SWIPE_SETTLE_SECONDS * remaining_ratio, 0.08, SKILL_SWIPE_SETTLE_SECONDS)
	skill_swipe_tween = create_tween()
	skill_swipe_tween.tween_method(
		Callable(swipe_surface, "_apply_skill_swipe_commit_release_offset").bind(offset),
		start_x,
		target_x,
		settle_seconds
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	skill_swipe_tween.finished.connect(_finish_skill_swipe_commit_tween.bind(offset, target_x))


func _skill_swipe_commit_release_span() -> float:
	return _skill_content_width() if not skill_strip_ids.is_empty() else _skill_swipe_page_span()


func _finish_skill_swipe_cancel_tween() -> void:
	skill_swipe_animating = false
	skill_swipe_animation_mode = ""
	_restore_skill_strip_wrap_page()
	_skill_swipe_activity_surface()._set_skill_strip_committed_crossfade(false)
	_apply_skill_swipe_drag_offset(0.0)
	_sync_skill_strip_page_visibility(false)
	_skill_swipe_activity_surface()._park_skill_swipe_preview()


func _finish_skill_swipe_commit_tween(offset: int, target_x: float) -> void:
	skill_swipe_animating = false
	skill_swipe_animation_mode = ""
	if skill_strip_ids.is_empty():
		_skill_swipe_activity_surface()._hold_skill_swipe_paper_fade_for_commit()
	else:
		_skill_swipe_activity_surface()._set_skill_strip_committed_crossfade(true)
	_navigate_skill_page(offset, target_x, true, false)


func _skill_swipe_commit_release_target_x(offset: int) -> float:
	return -float(signi(offset)) * _skill_swipe_commit_release_span()


func _queue_skill_swipe_navigation(offset: int) -> void:
	if offset == 0:
		return
	skill_swipe_queued_offset += offset


func _consume_queued_skill_swipe_navigation() -> bool:
	if skill_swipe_queued_offset == 0 or current_screen != "skill":
		return false
	var offset := skill_swipe_queued_offset
	skill_swipe_queued_offset = 0
	var skill_count := skill_defs.size()
	if skill_count <= 0:
		return false
	offset = offset % skill_count
	if offset == 0:
		return false
	if not _onboarding_runtime()._swipe_offset_accessible(offset):
		return false
	_force_skill_swipe_cover_opaque_cream()
	_skill_swipe_activity_surface()._ensure_skill_swipe_preview_page_cached(offset)
	_navigate_skill_page(offset, signi(offset) * _skill_swipe_page_span(), true, false)
	return true


func _discard_incoming_swipe_preview_for_animated_handoff(incoming_preview: Dictionary) -> void:
	if incoming_preview.is_empty():
		return
	_discard_incoming_swipe_preview(incoming_preview)


func _mount_swipe_preview_as_skill_detail(preview_page: Control, preview_state: Dictionary) -> void:
	var skill_id := str(preview_state.get("skill_id", selected_skill_id))
	_settings_surface()._clear_settings_page_control_refs()
	_navigation_shell()._reset_page_control_refs()
	var frame := Control.new()
	skill_swipe_frame = frame
	frame.clip_contents = false
	var frame_width := _skill_content_width()
	_apply_skill_column_layout(frame, frame_width, skill_swipe_gap_render_offset_x)
	skills_content.add_child(frame)
	skill_swipe_page = preview_page
	if preview_page.get_parent() != null:
		preview_page.reparent(frame)
	else:
		frame.add_child(preview_page)
	_normalize_skill_detail_page_layout(preview_page)
	preview_page.z_index = 20
	preview_page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_xp_label = preview_state.get("xp_label") as Label
	detail_xp_bar = preview_state.get("xp_bar") as CleanProgressBar
	detail_regen_circle = preview_state.get("regen_circle") as RegenCircle
	detail_fish_circle = preview_state.get("fish_circle") as FishCircle
	detail_auto_eat_fish_button = preview_state.get("auto_eat_fish_button") as TextureButton
	detail_header_body = preview_state.get("header_body") as Control
	_ensure_promoted_swipe_header_gauge(preview_page, preview_state, skill_id)
	var preview_scroll := preview_state.get("actions_scroll") as MobileScrollContainer
	if preview_scroll != null and is_instance_valid(preview_scroll):
		_skill_detail_surface()._ensure_skill_detail_actions_clip_wrapper(preview_page, preview_scroll, frame_width)
		detail_actions_scroll = preview_scroll
		preview_scroll.visible = true
		preview_scroll.modulate = Color.WHITE
	_skill_swipe_activity_surface()._show_mounted_swipe_preview_modules(preview_page, preview_state)
	_wire_mounted_swipe_preview_detail(preview_state)
	_skill_detail_surface()._add_skill_detail_shadow_overlay(_skill_detail_surface()._skill_detail_shadow_top_y())
	if bool(preview_state.get("proxy_handoff", false)) and not (preview_state.get("action_cards", []) as Array).is_empty():
		_skill_detail_surface().detail_lazy_plan.clear()
		_skill_detail_surface().detail_lazy_last_scroll = -1.0
		_skill_detail_surface().detail_lazy_mounted_this_frame = false
		_promote_swipe_preview_to_interactive(preview_state)
		skill_swipe_pending_full_finalize = false
		skill_swipe_pending_preview_state = {}
		_skill_detail_surface()._schedule_proxy_skill_detail_full_refresh(skill_id)
		return
	skill_swipe_pending_full_finalize = true
	skill_swipe_pending_preview_state = preview_state
	_hold_skill_swipe_cover_for_pending_finalize()


func _wire_mounted_swipe_preview_detail(_preview_state: Dictionary) -> void:
	_skill_detail_surface().detail_lazy_stack = _skill_detail_surface()._detail_actions_stack() as VBoxContainer
	_skill_detail_surface().detail_rendered_action_ids.clear()
	detail_action_card_nodes.clear()
	if skill_swipe_page != null and is_instance_valid(skill_swipe_page):
		skill_swipe_page.mouse_filter = Control.MOUSE_FILTER_PASS
	if skill_swipe_frame != null and is_instance_valid(skill_swipe_frame):
		skill_swipe_frame.mouse_filter = Control.MOUSE_FILTER_PASS
	if detail_actions_scroll != null and is_instance_valid(detail_actions_scroll):
		detail_actions_scroll.mouse_filter = Control.MOUSE_FILTER_PASS


func _ensure_promoted_swipe_header_gauge(preview_page: Control, preview_state: Dictionary, skill_id: String) -> void:
	if preview_page == null or not is_instance_valid(preview_page):
		return
	var gauge_parent := _swipe_preview_header_gauge_parent(preview_state, preview_page)
	if gauge_parent == null or not is_instance_valid(gauge_parent):
		return
	if _fishing_rework_active_for_skill(skill_id):
		if detail_fish_circle != null and is_instance_valid(detail_fish_circle):
			preview_state["fish_circle"] = detail_fish_circle
			return
		_clear_swipe_preview_header_gauge_slot(gauge_parent)
		detail_regen_circle = null
		detail_regen_circle_host = null
		detail_regen_circle_fade_group = null
		detail_auto_eat_fish_button = null
		var fish_circle := FishCircle.new()
		fish_circle.custom_minimum_size = Vector2(552, 552)
		fish_circle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fish_circle.mouse_filter = Control.MOUSE_FILTER_PASS
		fish_circle.z_index = 3000
		fish_circle.z_as_relative = false
		gauge_parent.add_child(fish_circle)
		detail_fish_circle = fish_circle
		preview_state["fish_circle"] = fish_circle
		_fishing_ui_surface()._attach_fishing_fish_circle_button(fish_circle)
		_fishing_ui_surface()._set_fish_circle_for_skill(fish_circle, skill_id, true)
		return
	if detail_regen_circle != null and is_instance_valid(detail_regen_circle):
		var existing_toggle := preview_state.get("auto_eat_fish_button") as TextureButton
		if existing_toggle != null and is_instance_valid(existing_toggle):
			detail_auto_eat_fish_button = existing_toggle
			detail_auto_eat_fish_button.set_meta("auto_eat_skill_id", skill_id)
			preview_state["regen_circle"] = detail_regen_circle
			_fishing_ui_surface()._sync_auto_eat_fish_toggle_button(detail_auto_eat_fish_button)
			return
	_clear_swipe_preview_header_gauge_slot(gauge_parent)
	detail_fish_circle = null
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
	detail_regen_circle.gui_input.connect(Callable(_action_runtime(), "_on_stamina_gauge_input").bind("", detail_regen_circle))
	detail_regen_circle_fade_group.add_child(detail_regen_circle)
	detail_regen_circle_host.add_child(detail_regen_circle_fade_group)
	gauge_parent.add_child(detail_regen_circle_host)
	detail_auto_eat_fish_button = _fishing_ui_surface()._attach_auto_eat_fish_toggle(detail_regen_circle_host, skill_id)
	preview_state["regen_circle"] = detail_regen_circle
	preview_state["regen_circle_host"] = detail_regen_circle_host
	preview_state["regen_circle_fade_group"] = detail_regen_circle_fade_group
	preview_state["auto_eat_fish_button"] = detail_auto_eat_fish_button
	detail_regen_circle.sync_for_skill(self, skill_id, true)


func _swipe_preview_header_gauge_parent(preview_state: Dictionary, preview_page: Control) -> Control:
	var regen_circle := preview_state.get("regen_circle") as Control
	if regen_circle != null and is_instance_valid(regen_circle):
		return regen_circle.get_parent() as Control
	var fish_circle := preview_state.get("fish_circle") as Control
	if fish_circle != null and is_instance_valid(fish_circle):
		return fish_circle.get_parent() as Control
	var header_body := preview_state.get("header_body") as Control
	if header_body == null or not is_instance_valid(header_body):
		header_body = _find_swipe_preview_header_body(preview_page)
	if header_body == null or not is_instance_valid(header_body):
		return null
	var row := _find_first_descendant_of_class(header_body, "HBoxContainer") as HBoxContainer
	if row == null or not is_instance_valid(row) or row.get_child_count() <= 0:
		return null
	return row


func _find_swipe_preview_header_body(preview_page: Control) -> Control:
	if preview_page == null or not is_instance_valid(preview_page) or preview_page.get_child_count() <= 0:
		return null
	var header := preview_page.get_child(0) as Control
	if header == null or not is_instance_valid(header) or header.get_child_count() <= 0:
		return null
	return header.get_child(0) as Control


func _find_first_descendant_of_class(root: Control, target_class_name: String) -> Control:
	if root == null or not is_instance_valid(root):
		return null
	for child in root.get_children():
		var control := child as Control
		if control == null:
			continue
		if control.get_class() == target_class_name:
			return control
		var nested := _find_first_descendant_of_class(control, target_class_name)
		if nested != null:
			return nested
	return null


func _clear_swipe_preview_header_gauge_slot(gauge_parent: Control) -> void:
	if gauge_parent == null or not is_instance_valid(gauge_parent):
		return
	for child in gauge_parent.get_children():
		if child is Control and bool((child as Control).size_flags_horizontal & Control.SIZE_EXPAND):
			continue
		gauge_parent.remove_child(child)
		child.queue_free()


func _schedule_swipe_preview_finalize_after_navigation() -> void:
	if not skill_swipe_pending_full_finalize:
		return
	_freeze_pending_swipe_preview_stack_under_cover()
	skill_swipe_finalize_schedule_token += 1
	skill_swipe_finalize_target_skill_id = selected_skill_id
	skill_swipe_finalize_ready_process_frame = main_process_frame_index + maxi(1, SKILL_SWIPE_FINALIZE_SETTLE_FRAMES)
	if OS.get_environment("IDLE_ELITE_TRACE_SWIPE_FINALIZE") == "1":
		print("SWIPE_FINALIZE_TRACE schedule frame=%s ready=%s target=%s pending=%s anim=%s tracking=%s" % [
			str(main_process_frame_index),
			str(skill_swipe_finalize_ready_process_frame),
			skill_swipe_finalize_target_skill_id,
			str(skill_swipe_pending_full_finalize),
			str(skill_swipe_animating),
			str(skill_swipe_tracking)
		])


func _freeze_pending_swipe_preview_stack_under_cover() -> void:
	if skill_swipe_handoff_cover == null or not is_instance_valid(skill_swipe_handoff_cover):
		return
	var preview_page := skill_swipe_page
	if preview_page == null or not is_instance_valid(preview_page):
		return
	var stack := _skill_swipe_activity_surface()._find_skill_preview_stack(preview_page) as Control
	if stack == null or not is_instance_valid(stack):
		return
	stack.visible = false
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process_pending_swipe_preview_finalize() -> void:
	if not skill_swipe_pending_full_finalize:
		skill_swipe_finalize_ready_process_frame = -1
		skill_swipe_finalize_target_skill_id = ""
		return
	if skill_swipe_finalize_ready_process_frame < 0:
		return
	if current_screen != "skill" or selected_skill_id != skill_swipe_finalize_target_skill_id:
		if OS.get_environment("IDLE_ELITE_TRACE_SWIPE_FINALIZE") == "1":
			print("SWIPE_FINALIZE_TRACE cancel=mismatch frame=%s screen=%s selected=%s target=%s" % [
				str(main_process_frame_index),
				current_screen,
				selected_skill_id,
				skill_swipe_finalize_target_skill_id
			])
		skill_swipe_finalize_ready_process_frame = -1
		skill_swipe_finalize_target_skill_id = ""
		return
	if skill_swipe_tracking:
		if OS.get_environment("IDLE_ELITE_TRACE_SWIPE_FINALIZE") == "1":
			print("SWIPE_FINALIZE_TRACE wait=tracking frame=%s ready=%s target=%s anim=%s tracking=%s" % [
				str(main_process_frame_index),
				str(skill_swipe_finalize_ready_process_frame),
				skill_swipe_finalize_target_skill_id,
				str(skill_swipe_animating),
				str(skill_swipe_tracking)
			])
		skill_swipe_finalize_ready_process_frame = main_process_frame_index + maxi(1, SKILL_SWIPE_FINALIZE_SETTLE_FRAMES)
		return
	if main_process_frame_index < skill_swipe_finalize_ready_process_frame:
		if OS.get_environment("IDLE_ELITE_TRACE_SWIPE_FINALIZE") == "1":
			print("SWIPE_FINALIZE_TRACE wait=settle frame=%s ready=%s target=%s" % [
				str(main_process_frame_index),
				str(skill_swipe_finalize_ready_process_frame),
				skill_swipe_finalize_target_skill_id
			])
		return
	var target_skill_id := skill_swipe_finalize_target_skill_id
	if OS.get_environment("IDLE_ELITE_TRACE_SWIPE_FINALIZE") == "1":
		print("SWIPE_FINALIZE_TRACE finalize frame=%s target=%s" % [str(main_process_frame_index), target_skill_id])
	skill_swipe_finalize_ready_process_frame = -1
	skill_swipe_finalize_target_skill_id = ""
	_finalize_swipe_preview_to_full_detail(target_skill_id)


func _preview_actions_scroll_vertical(preview_state: Dictionary) -> int:
	var scroll := preview_state.get("actions_scroll") as ScrollContainer
	if scroll == null or not is_instance_valid(scroll):
		return -1
	return scroll.scroll_vertical


func _incoming_swipe_preview_usable(incoming_preview: Dictionary) -> bool:
	var preview_page := incoming_preview.get("page") as Control
	var preview_state := incoming_preview.get("state", {}) as Dictionary
	if preview_page == null or not is_instance_valid(preview_page):
		return false
	var scroll := preview_state.get("actions_scroll") as Control
	if scroll == null or not is_instance_valid(scroll):
		scroll = _skill_swipe_activity_surface()._find_skill_preview_actions_scroll(preview_page)
	if scroll == null or not is_instance_valid(scroll):
		return false
	var cards := preview_state.get("action_cards", []) as Array
	if not cards.is_empty():
		return true
	var fishing_modules := preview_state.get("fishing_built_modules", []) as Array
	if not fishing_modules.is_empty():
		return true
	# Light preview cards are only a visual handoff. Promoting them to the live
	# page makes the modules appear briefly, then disappear when finalize swaps
	# them for real lazy slots.
	return _skill_swipe_handoff_cover_is_opaque_cream_transition()


func _skill_detail_stack_has_visible_modules(stack: Control) -> bool:
	if stack == null or not is_instance_valid(stack):
		return false
	for child in stack.get_children():
		var control := child as Control
		if _skill_detail_surface()._detail_stack_child_is_module_content(control):
			return true
	return false


func _skill_detail_visible_module_stats() -> Dictionary:
	var stats := {
		"scroll_area": 0.0,
		"visible_modules": 0,
		"visible_module_area": 0.0,
		"action_stat_boxes": 0,
		"visible_action_stat_boxes": 0,
		"fishing_method_tiles": 0,
		"visible_fishing_method_tiles": 0,
		"freshly_mounted_modules": 0,
	}
	if detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll):
		return stats
	if not detail_actions_scroll.visible or not detail_actions_scroll.is_visible_in_tree():
		return stats
	var scroll_rect := detail_actions_scroll.get_global_rect()
	stats["scroll_area"] = maxf(0.0, scroll_rect.size.x) * maxf(0.0, scroll_rect.size.y)
	if scroll_rect.size.x <= 1.0 or scroll_rect.size.y <= 1.0:
		return stats
	var visible_rect := Rect2(Vector2.ZERO, _current_canvas_size())
	var viewport_rect := scroll_rect.intersection(visible_rect)
	if viewport_rect.size.x <= 1.0 or viewport_rect.size.y <= 1.0:
		return stats
	var stack := _skill_detail_surface()._detail_actions_stack() as Control
	if stack == null or not is_instance_valid(stack):
		return stats
	for raw_child in stack.get_children():
		var child := raw_child as Control
		if child == null or not _skill_detail_surface()._detail_stack_child_is_module_content(child):
			continue
		var intersection := child.get_global_rect().intersection(viewport_rect)
		var area := maxf(0.0, intersection.size.x) * maxf(0.0, intersection.size.y)
		if area <= 1.0:
			continue
		stats["visible_modules"] = int(stats["visible_modules"]) + 1
		stats["visible_module_area"] = float(stats["visible_module_area"]) + area
		if not _detail_lazy_visible_module_mount_frames_settled(child):
			stats["freshly_mounted_modules"] = int(stats["freshly_mounted_modules"]) + 1
		var stat_boxes := _action_stat_box_visibility_stats(child, viewport_rect)
		stats["action_stat_boxes"] = int(stats["action_stat_boxes"]) + int(stat_boxes.get("total", 0))
		stats["visible_action_stat_boxes"] = int(stats["visible_action_stat_boxes"]) + int(stat_boxes.get("visible", 0))
		var fishing_tiles := _marked_control_visibility_stats(child, viewport_rect, "fishing_area_method_ready_marker")
		stats["fishing_method_tiles"] = int(stats["fishing_method_tiles"]) + int(fishing_tiles.get("total", 0))
		stats["visible_fishing_method_tiles"] = int(stats["visible_fishing_method_tiles"]) + int(fishing_tiles.get("visible", 0))
	return stats


func _mark_detail_lazy_module_mounted(control: Control) -> void:
	if control == null or not is_instance_valid(control):
		return
	control.set_meta("detail_lazy_mounted_process_frame", Engine.get_process_frames())


func _detail_lazy_visible_module_mount_frames_settled(control: Control) -> bool:
	return _detail_lazy_control_mount_frames_settled(control, Engine.get_process_frames())


func _detail_lazy_control_mount_frames_settled(control: Control, current_process_frame: int) -> bool:
	if control == null or not is_instance_valid(control):
		return true
	if control.has_meta("detail_lazy_mounted_process_frame"):
		var mounted_process_frame := int(control.get_meta("detail_lazy_mounted_process_frame"))
		if current_process_frame - mounted_process_frame < 2:
			return false
	for raw_child in control.get_children():
		var child := raw_child as Control
		if child != null and not _detail_lazy_control_mount_frames_settled(child, current_process_frame):
			return false
	return true


func _marked_control_visibility_stats(control: Control, viewport_rect: Rect2, marker_name: String) -> Dictionary:
	var stats := {"total": 0, "visible": 0}
	_collect_marked_control_visibility_stats(control, viewport_rect, marker_name, stats)
	return stats


func _collect_marked_control_visibility_stats(control: Control, viewport_rect: Rect2, marker_name: String, stats: Dictionary) -> void:
	if control == null or not is_instance_valid(control):
		return
	if bool(control.get_meta(marker_name, false)):
		stats["total"] = int(stats.get("total", 0)) + 1
		if _control_rect_intersects_viewport(control, viewport_rect):
			stats["visible"] = int(stats.get("visible", 0)) + 1
	for raw_child in control.get_children():
		var child := raw_child as Control
		if child != null:
			_collect_marked_control_visibility_stats(child, viewport_rect, marker_name, stats)


func _action_stat_box_visibility_stats(control: Control, viewport_rect: Rect2) -> Dictionary:
	var stats := {"total": 0, "visible": 0}
	_collect_action_stat_box_visibility_stats(control, viewport_rect, stats)
	return stats


func _collect_action_stat_box_visibility_stats(control: Control, viewport_rect: Rect2, stats: Dictionary) -> void:
	if control == null or not is_instance_valid(control):
		return
	if bool(control.get_meta("action_stat_box", false)):
		stats["total"] = int(stats.get("total", 0)) + 1
		if _control_rect_intersects_viewport(control, viewport_rect):
			stats["visible"] = int(stats.get("visible", 0)) + 1
	for raw_child in control.get_children():
		var child := raw_child as Control
		if child != null:
			_collect_action_stat_box_visibility_stats(child, viewport_rect, stats)


func _skill_detail_stack_is_presentable(stack: Control) -> bool:
	if stack == null or not is_instance_valid(stack):
		return false
	if not stack.visible or not stack.is_visible_in_tree() or stack.modulate.a <= 0.01:
		return false
	return _skill_detail_stack_has_visible_modules(stack)


func _control_rect_intersects_viewport(control: Control, viewport_rect: Rect2) -> bool:
	if control == null or not is_instance_valid(control):
		return false
	if not control.visible or control.is_queued_for_deletion() or control.modulate.a <= 0.01:
		return false
	var rect := control.get_global_rect()
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		return false
	return rect.intersects(viewport_rect)


func _control_tree_has_lazy_placeholder(control: Control) -> bool:
	if control == null or not is_instance_valid(control):
		return false
	if bool(control.get_meta("detail_lazy_placeholder", false)):
		return true
	for raw_child in control.get_children():
		var child := raw_child as Control
		if child != null and _control_tree_has_lazy_placeholder(child):
			return true
	return false


func _skill_detail_has_visible_lazy_placeholders() -> bool:
	if detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll):
		return false
	var stack := _skill_detail_surface()._detail_actions_stack() as Control
	if stack == null or not is_instance_valid(stack):
		return false
	var viewport_rect := detail_actions_scroll.get_global_rect()
	for raw_child in stack.get_children():
		var child := raw_child as Control
		if child == null:
			continue
		if child.name == "DetailActionsTopSpacer" or child.name == "DetailActionsBottomSpacer":
			continue
		if _control_rect_intersects_viewport(child, viewport_rect) and _control_tree_has_lazy_placeholder(child):
			return true
	return false


func _skill_detail_ready_to_reveal_under_cover() -> bool:
	if _skill_swipe_cover_reveal_blocked_by_animation():
		return false
	var stack := _skill_detail_surface()._detail_actions_stack() as Control
	if not _skill_detail_stack_is_presentable(stack):
		return false
	var stats := _skill_detail_visible_module_stats()
	if float(stats.get("scroll_area", 0.0)) < 100000.0:
		return false
	if int(stats.get("visible_modules", 0)) <= 0:
		return false
	if float(stats.get("visible_module_area", 0.0)) < 50000.0:
		return false
	if int(stats.get("freshly_mounted_modules", 0)) > 0:
		return false
	var action_stat_box_count := int(stats.get("action_stat_boxes", 0))
	if action_stat_box_count > 0 and not _tutorial_overlay_surface()._onboarding_fight_action_stats_should_hide():
		var visible_stat_box_count := int(stats.get("visible_action_stat_boxes", 0))
		if visible_stat_box_count < mini(2, action_stat_box_count):
			return false
	var fishing_tile_count := int(stats.get("fishing_method_tiles", 0))
	if fishing_tile_count > 0 and int(stats.get("visible_fishing_method_tiles", 0)) <= 0:
		return false
	return not _skill_detail_has_visible_lazy_placeholders()


func _skill_swipe_cover_reveal_blocked_by_animation() -> bool:
	if current_screen != "skill" or not skill_swipe_animating or skill_swipe_animation_mode.is_empty():
		return false
	var cover := skill_swipe_handoff_cover
	if (
		cover != null
		and is_instance_valid(cover)
		and skill_swipe_animation_mode == "entry"
		and bool(cover.get_meta("swipe_gap_entry_reveal_allowed", false))
	):
		return false
	return true


func _force_skill_detail_reveal_mount_under_cover() -> void:
	if current_screen != "skill":
		return
	if detail_actions_scroll != null and is_instance_valid(detail_actions_scroll):
		var stats := _skill_detail_visible_module_stats()
		if (
			float(stats.get("scroll_area", 0.0)) >= 100000.0
			and int(stats.get("visible_modules", 0)) <= 0
		):
			detail_actions_scroll.drag_scroll_position = 0.0
			detail_actions_scroll.scroll_vertical = 0
	if _skill_detail_surface().detail_lazy_plan.size() > 0:
		var cover := skill_swipe_handoff_cover
		var throttle_by_frame := _skill_swipe_handoff_cover_is_opaque_cream_transition()
		var process_frame := Engine.get_process_frames()
		if (
			throttle_by_frame
			and cover != null
			and is_instance_valid(cover)
			and int(cover.get_meta("swipe_cover_last_lazy_mount_process_frame", -1)) == process_frame
		):
			_skill_detail_surface()._sync_detail_actions_scroll_limit()
			_ensure_finalized_skill_detail_presentable(selected_skill_id)
			return
		var mounted: int = _skill_detail_surface()._sync_detail_lazy_visible_cards(true, _skill_detail_surface().DETAIL_LAZY_MOUNT_BUDGET_PER_FRAME)
		if mounted <= 0 and not _skill_detail_stack_is_presentable(_skill_detail_surface()._detail_actions_stack() as Control):
			mounted = _skill_detail_surface()._sync_detail_lazy_next_cards(true, _skill_detail_surface().DETAIL_LAZY_MOUNT_BUDGET_PER_FRAME)
		if throttle_by_frame and mounted > 0 and cover != null and is_instance_valid(cover):
			cover.set_meta("swipe_cover_last_lazy_mount_process_frame", process_frame)
	_skill_detail_surface()._sync_detail_actions_scroll_limit()
	_ensure_finalized_skill_detail_presentable(selected_skill_id)


func _ensure_finalized_skill_detail_presentable(target_skill_id: String) -> bool:
	if current_screen != "skill" or selected_skill_id != target_skill_id:
		return false
	if skill_swipe_page != null and is_instance_valid(skill_swipe_page):
		skill_swipe_page.visible = true
		skill_swipe_page.modulate = Color.WHITE
	if detail_actions_scroll != null and is_instance_valid(detail_actions_scroll):
		detail_actions_scroll.visible = true
		detail_actions_scroll.modulate = Color.WHITE
	var stack := _skill_detail_surface()._detail_actions_stack() as VBoxContainer
	if stack != null and is_instance_valid(stack):
		stack.visible = true
		stack.modulate = Color.WHITE
		_skill_detail_surface().detail_lazy_stack = stack
	if _skill_detail_stack_is_presentable(stack):
		return true
	if _repair_blank_detail_lazy_stack():
		stack = _skill_detail_surface()._detail_actions_stack() as VBoxContainer
		if stack != null and is_instance_valid(stack):
			stack.visible = true
			stack.modulate = Color.WHITE
		return _skill_detail_stack_is_presentable(stack)
	return false


func _discard_incoming_swipe_preview(incoming_preview: Dictionary) -> void:
	var preview_state := incoming_preview.get("state", {}) as Dictionary
	var skill_id := str(preview_state.get("skill_id", ""))
	_skill_swipe_activity_surface()._move_swipe_preview_real_card_cache_to_global(preview_state)
	_skill_swipe_activity_surface()._free_swipe_preview_real_card_cache(preview_state)
	for raw_card in preview_state.get("action_cards", []) as Array:
		var card := raw_card as Dictionary
		if card.is_empty():
			continue
		var heist_id := str(card.get("heist_id", ""))
		if not heist_id.is_empty():
			_discard_action_card_key(_thieving_surface()._thieving_heist_card_key(heist_id))
			continue
		var action := card.get("action", {}) as Dictionary
		var action_id := str(action.get("id", ""))
		if not skill_id.is_empty() and not action_id.is_empty():
			_discard_action_card_key(_action_key(skill_id, action_id))
	if skill_id == "thieving":
		for key in action_cards.keys():
			if str(key).begins_with("thieving_heist:"):
				_discard_action_card_key(str(key))
	var preview_page := incoming_preview.get("page") as Control
	if preview_page != null and is_instance_valid(preview_page):
		preview_page.queue_free()


func _should_promote_incoming_swipe_preview(skill_id: String) -> bool:
	return false


func _prepare_full_rendered_swipe_target_for_cover_clear(target_skill_id: String) -> void:
	if current_screen != "skill" or selected_skill_id != target_skill_id:
		return
	if _skill_detail_surface().detail_lazy_plan.is_empty() or _skill_detail_surface().detail_lazy_stack == null or not is_instance_valid(_skill_detail_surface().detail_lazy_stack):
		return
	_ensure_finalized_skill_detail_presentable(target_skill_id)


func _rebuild_skill_detail_after_preview(restore_detail_scroll := -1) -> void:
	if skills_content == null:
		return
	var target_skill_id := selected_skill_id
	var target_key: String = _navigation_shell()._skill_detail_cache_key(target_skill_id)
	skill_swipe_pending_full_finalize = false
	skill_swipe_pending_preview_state = {}
	skill_swipe_finalize_ready_process_frame = -1
	skill_swipe_finalize_target_skill_id = ""
	skill_swipe_lazy_finalize_token += 1
	skill_swipe_finalized_lazy_mount_pending = false
	call_deferred("_rebuild_skill_detail_after_preview_deferred", restore_detail_scroll, target_skill_id, target_key)


func _rebuild_skill_detail_after_preview_deferred(restore_detail_scroll: int, target_skill_id: String, target_key: String) -> void:
	if current_screen != "skill" or selected_skill_id != target_skill_id or skills_content == null:
		return
	_app_lifecycle_runtime()._kill_transient_tweens_in_subtree(skills_content)
	_skill_swipe_activity_surface()._clear_skill_swipe_preview()
	skill_swipe_frame = null
	skill_swipe_page = null
	_navigation_shell()._reset_page_control_refs()
	_clear_skills_content_orphans()
	await _skill_detail_surface()._render_skill_detail(false, restore_detail_scroll)
	if current_screen != "skill" or selected_skill_id != target_skill_id:
		return
	_normalize_skill_detail_page_layout()
	_finish_render_screen_transition(target_key)
	_fade_clear_skill_swipe_rebuild_cover()
	call_deferred("_apply_pending_swipe_resume_scroll", target_skill_id)


func _skill_swipe_install_target_page(target_key: String, incoming_preview: Dictionary = {}):
	_skill_detail_surface()._cancel_detail_lazy_settle_warm_mount()
	skill_swipe_finalize_schedule_token += 1
	skill_swipe_finalize_ready_process_frame = -1
	skill_swipe_finalize_target_skill_id = ""
	skill_swipe_pending_full_finalize = false
	skill_swipe_pending_preview_state = {}
	skill_swipe_finalized_lazy_mount_pending = false
	_skill_detail_surface()._hold_skill_detail_layout_refresh_after_navigation()
	_clear_page_transient_input_state()
	_prepare_skills_page_transition(target_key)
	skill_swipe_drag_offset_x = skill_swipe_gap_render_offset_x
	if (
		not incoming_preview.is_empty()
		and _incoming_swipe_preview_usable(incoming_preview)
		and _should_promote_incoming_swipe_preview(selected_skill_id)
	):
		var preview_page := incoming_preview.get("page") as Control
		var preview_state := incoming_preview.get("state", {}) as Dictionary
		_settings_surface()._clear_settings_page_control_refs()
		_app_lifecycle_runtime()._kill_transient_tweens_in_subtree(skills_content)
		_skill_swipe_activity_surface()._clear_skill_swipe_preview()
		skill_swipe_frame = null
		skill_swipe_page = null
		_navigation_shell()._reset_page_control_refs()
		_clear_skills_content_orphans()
		_mount_swipe_preview_as_skill_detail(preview_page, preview_state)
		_promote_swipe_preview_to_interactive(preview_state)
		_finish_render_screen_transition(target_key)
		return
	if not incoming_preview.is_empty():
		_discard_incoming_swipe_preview(incoming_preview)
	_settings_surface()._clear_settings_page_control_refs()
	_app_lifecycle_runtime()._kill_transient_tweens_in_subtree(skills_content)
	_apply_skills_content_layout_for_screen()
	_skill_swipe_activity_surface()._clear_skill_swipe_preview()
	skill_swipe_frame = null
	skill_swipe_page = null
	_navigation_shell()._reset_page_control_refs()
	_clear_skills_content_orphans()
	var defer_initial_mount := _skill_swipe_handoff_cover_is_opaque_cream_transition()
	skill_swipe_defer_initial_lazy_mount = defer_initial_mount
	await _skill_detail_surface()._render_skill_detail(false, -1)
	_normalize_skill_detail_page_layout()
	if defer_initial_mount:
		_force_skill_detail_reveal_mount_under_cover()
	else:
		_prepare_full_rendered_swipe_target_for_cover_clear(selected_skill_id)
	_finish_render_screen_transition(target_key)
	skill_swipe_defer_initial_lazy_mount = false


func _complete_skill_swipe_navigation() -> void:
	_request_swipe_resume_scroll()
	skill_swipe_animating = false
	skill_swipe_animation_mode = ""
	skill_swipe_drag_offset_x = 0.0
	_reset_skill_swipe_entry_positions()
	_ensure_skill_swipe_frame_centered()
	_skill_swipe_activity_surface()._reset_skill_swipe_fade_state(true)
	if skill_swipe_handoff_cover != null and is_instance_valid(skill_swipe_handoff_cover):
		if skill_swipe_pending_full_finalize:
			skill_swipe_outgoing_cover_active = true
		else:
			_fade_clear_skill_swipe_cover(SKILL_SWIPE_REBUILD_COVER_FADE_SECONDS)
	_sync_skill_strip_page_visibility(false)
	if current_screen == "skill":
		_navigation_shell()._fade_skill_page_switch_modules(true, SKILL_SWIPE_PAGE_SWITCH_FADE_IN_SECONDS)
		_navigation_shell()._fade_skill_swipe_module_utility_row(true, SKILL_SWIPE_MODULE_UTILITY_FADE_IN_SECONDS)
		_skill_swipe_activity_surface()._fade_skill_shelf_backgrounds(true)
		_skill_detail_surface().call_deferred("_queue_detail_lazy_settle_warm_mount", selected_skill_id)
		_schedule_swipe_preview_finalize_after_navigation()
		if not skill_swipe_pending_full_finalize:
			call_deferred("_apply_pending_swipe_resume_scroll", selected_skill_id)
		if selected_skill_id == TUTORIAL_STARTER_SKILL_ID:
			if _onboarding_runtime()._onboarding_swipe_tip_sequence_resumable() and not onboarding_swipe_tip_sequence_running:
				_tutorial_overlay_surface().call_deferred("_run_onboarding_swipe_tip_sequence")
		else:
			_tutorial_overlay_surface()._fade_tip_group("skill_swipe_tip_notes", false, true)
			_onboarding_runtime()._mark_skill_swipe_tip_seen()
			_onboarding_runtime().call_deferred("_maybe_show_onboarding_explore_tip")


func _skill_detail_ready_for_gap_entry() -> bool:
	var stack := _skill_detail_surface()._detail_actions_stack() as Control
	if not _skill_detail_stack_is_presentable(stack):
		return false
	return not _skill_detail_has_visible_lazy_placeholders()


func _wait_for_skill_swipe_gap_entry_ready(target_skill_id: String) -> void:
	if target_skill_id.is_empty():
		return
	for _i in range(SKILL_SWIPE_GAP_READY_WAIT_FRAMES):
		if current_screen != "skill" or selected_skill_id != target_skill_id:
			return
		_force_skill_detail_reveal_mount_under_cover()
		if _skill_detail_ready_for_gap_entry():
			return
		await get_tree().process_frame
	if current_screen == "skill" and selected_skill_id == target_skill_id:
		_force_skill_detail_reveal_mount_under_cover()


func _begin_skill_swipe_incoming_entry(start_x: float) -> void:
	_kill_skill_swipe_tween()
	skill_swipe_animating = true
	skill_swipe_animation_mode = "entry"
	_skill_swipe_activity_surface()._hide_skill_swipe_paper_fade()
	_apply_skill_swipe_drag_offset(start_x)
	skill_swipe_tween = create_tween()
	skill_swipe_tween.tween_method(
		_apply_skill_swipe_drag_offset,
		start_x,
		0.0,
		SKILL_SWIPE_SETTLE_SECONDS
	).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	skill_swipe_tween.finished.connect(_complete_skill_swipe_navigation)


func _finalize_swipe_preview_to_full_detail(target_skill_id := "") -> void:
	if not skill_swipe_pending_full_finalize:
		return
	if not target_skill_id.is_empty() and selected_skill_id != target_skill_id:
		return
	skill_swipe_finalize_ready_process_frame = -1
	skill_swipe_finalize_target_skill_id = ""
	var preview_state := skill_swipe_pending_preview_state
	skill_swipe_pending_preview_state = {}
	var preserve_scroll := _preview_actions_scroll_vertical(preview_state)
	_skill_detail_surface()._hold_skill_detail_layout_refresh_after_navigation()
	skill_swipe_lazy_finalize_token += 1
	var token := skill_swipe_lazy_finalize_token
	_skill_detail_surface().call_deferred("_finalize_swipe_preview_to_lazy_detail", preview_state, preserve_scroll, selected_skill_id, token)


func _promote_swipe_preview_to_interactive(preview_state: Dictionary) -> void:
	var skill_id := str(preview_state.get("skill_id", selected_skill_id))
	if _fishing_rework_active_for_skill(skill_id):
		_promote_fishing_swipe_preview(preview_state)
	else:
		for raw_card in preview_state.get("action_cards", []) as Array:
			var card := raw_card as Dictionary
			if card.is_empty():
				continue
			var heist_id := str(card.get("heist_id", ""))
			if not heist_id.is_empty():
				_promote_heist_swipe_preview_card(card, heist_id)
				continue
			if bool(card.get("passive", false)):
				_promote_passive_swipe_preview_card(card, skill_id)
				continue
			var action := card.get("action", {}) as Dictionary
			var action_id := str(action.get("id", card.get("action_id", "")))
			if action.is_empty() or action_id.is_empty():
				continue
			_promote_action_swipe_preview_card(card, skill_id, action_id, action)
	if detail_header_body != null and is_instance_valid(detail_header_body):
		_skill_detail_surface()._enable_skill_detail_back_arrow(detail_header_body)
		_tutorial_overlay_surface()._apply_onboarding_fight_header_visibility()
		_skill_detail_surface()._sync_skill_detail_back_arrow_visibility()
		if _onboarding_runtime()._onboarding_auto_run_message_resumable():
			_onboarding_runtime().call_deferred("_run_onboarding_auto_run_message_sequence")
		if _onboarding_runtime()._onboarding_header_reveal_sequence_resumable():
			_onboarding_runtime().call_deferred("_run_onboarding_header_reveal_sequence")
	if detail_actions_scroll != null and is_instance_valid(detail_actions_scroll):
		var actions_clip: Control = _skill_detail_surface()._ensure_skill_detail_actions_clip_wrapper(skill_swipe_page, detail_actions_scroll, _skill_content_width())
		if actions_clip == null or not is_instance_valid(actions_clip):
			actions_clip = detail_actions_scroll.get_parent() as Control
		if actions_clip != null and is_instance_valid(actions_clip):
			_skill_detail_surface()._build_detail_jump_arrows(actions_clip)
	if skill_swipe_page != null and is_instance_valid(skill_swipe_page):
		skill_swipe_page.mouse_filter = Control.MOUSE_FILTER_PASS


func _promote_action_swipe_preview_card(card: Dictionary, skill_id: String, action_id: String, action: Dictionary) -> void:
	if bool(card.get("swipe_promoted", false)):
		return
	card["swipe_promoted"] = true
	var card_root := card.get("root") as Control
	var pop_card := card.get("pop") as Control
	if card_root != null and is_instance_valid(card_root):
		card_root.mouse_filter = Control.MOUSE_FILTER_PASS
	if pop_card != null and is_instance_valid(pop_card):
		pop_card.mouse_filter = Control.MOUSE_FILTER_PASS
	_attach_swipe_preview_activity_button(card, skill_id, action_id, pop_card)
	card["action_id"] = action_id
	card["action"] = action
	card["preview_only"] = false
	_register_action_card(_action_key(skill_id, action_id), card)
	if not bool(card.get("swipe_proxy", false)):
		_detail_lazy_finalize_action_card(card, skill_id, action, action_id)
	detail_action_card_nodes[action_id] = card_root
	if not _skill_detail_surface().detail_rendered_action_ids.has(action_id):
		_skill_detail_surface().detail_rendered_action_ids.append(action_id)


func _promote_heist_swipe_preview_card(card: Dictionary, heist_id: String) -> void:
	if bool(card.get("swipe_promoted", false)):
		return
	card["swipe_promoted"] = true
	card["preview_only"] = false
	_register_action_card(_thieving_surface()._thieving_heist_card_key(heist_id), card)
	var heist_root := card.get("root") as Control
	if heist_root != null and is_instance_valid(heist_root):
		heist_root.mouse_filter = Control.MOUSE_FILTER_PASS
		var button := card.get("button") as Button
		if button != null and is_instance_valid(button):
			button.mouse_filter = Control.MOUSE_FILTER_STOP
		detail_action_card_nodes["heist:%s" % heist_id] = heist_root
	var track_id := "heist:%s" % heist_id
	if not _skill_detail_surface().detail_rendered_action_ids.has(track_id):
		_skill_detail_surface().detail_rendered_action_ids.append(track_id)


func _attach_swipe_preview_activity_button(card: Dictionary, skill_id: String, action_id: String, pop_card: Control) -> void:
	if card.get("button") != null:
		var existing := card.get("button") as Button
		if existing != null and is_instance_valid(existing):
			existing.mouse_filter = Control.MOUSE_FILTER_STOP
		return
	var button := Button.new()
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.flat = true
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.z_index = 218
	button.gui_input.connect(_skill_swipe_activity_surface()._on_action_card_input.bind(skill_id, action_id, button))
	pop_card.add_child(button)
	card["button"] = button


func _promote_passive_swipe_preview_card(card: Dictionary, skill_id: String) -> void:
	if bool(card.get("swipe_promoted", false)):
		return
	card["swipe_promoted"] = true
	var action := card.get("action", {}) as Dictionary
	var module_id := str(action.get("id", ""))
	if module_id.is_empty():
		return
	var card_root := card.get("root") as Control
	var pop_card := card.get("pop") as Control
	if card_root != null and is_instance_valid(card_root):
		card_root.clip_contents = false
		card_root.mouse_filter = Control.MOUSE_FILTER_PASS
	if pop_card != null and is_instance_valid(pop_card):
		pop_card.mouse_filter = Control.MOUSE_FILTER_PASS
	var loot := card.get("loot") as Control
	if loot != null and is_instance_valid(loot):
		loot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var collect_button := card.get("button") as Button
	if collect_button != null and is_instance_valid(collect_button):
		collect_button.mouse_filter = Control.MOUSE_FILTER_STOP
		collect_button.gui_input.connect(_passive_firepit_surface()._on_passive_module_button_input.bind("collect", module_id, "", null, collect_button))
		collect_button.pressed.connect(_passive_firepit_surface()._on_passive_collect_pressed.bind(module_id))
	var info_button := card.get("info_button") as Button
	if info_button != null and is_instance_valid(info_button):
		info_button.mouse_filter = Control.MOUSE_FILTER_STOP
		var info_popover := card.get("info_popover") as Control
		if info_popover != null:
			info_button.gui_input.connect(_passive_firepit_surface()._on_passive_module_button_input.bind("info", module_id, "", info_popover, info_button))
			info_button.pressed.connect(Callable(_passive_firepit_surface(), "_toggle_passive_info_popover").bind(info_popover))
	var plank_button := card.get("plank") as Button
	if plank_button != null and is_instance_valid(plank_button):
		plank_button.mouse_filter = Control.MOUSE_FILTER_STOP
		plank_button.gui_input.connect(_passive_firepit_surface()._on_passive_module_button_input.bind("plank", module_id, "", null, plank_button))
		plank_button.pressed.connect(_passive_firepit_surface()._on_passive_plank_pressed.bind(module_id))
	var upgrade_buttons := card.get("upgrade_buttons", {}) as Dictionary
	for stat_type in upgrade_buttons.keys():
		var upgrade := upgrade_buttons.get(stat_type) as Button
		if upgrade == null or not is_instance_valid(upgrade):
			continue
		upgrade.mouse_filter = Control.MOUSE_FILTER_STOP
		upgrade.gui_input.connect(_passive_firepit_surface()._on_passive_module_button_input.bind("upgrade", module_id, stat_type, null, upgrade))
		upgrade.pressed.connect(_passive_firepit_surface()._on_passive_upgrade_pressed.bind(module_id, stat_type))
	card["preview_only"] = false
	_register_action_card(_action_key(skill_id, module_id), card)
	if not bool(card.get("swipe_proxy", false)):
		_passive_firepit_surface()._update_passive_card_static_state(card, skill_id, action, _activity_unlock_runtime()._is_action_unlocked(skill_id, action))
	detail_action_card_nodes[module_id] = card_root
	if not _skill_detail_surface().detail_rendered_action_ids.has(module_id):
		_skill_detail_surface().detail_rendered_action_ids.append(module_id)


func _promote_fishing_swipe_preview(preview_state: Dictionary) -> void:
	var skill_id := "fishing"
	for raw_card in preview_state.get("action_cards", []) as Array:
		var card := raw_card as Dictionary
		if card.is_empty():
			continue
		var action := card.get("action", {}) as Dictionary
		var action_id := str(action.get("id", card.get("action_id", "")))
		if bool(card.get("passive", false)) or _passive_modules_runtime().is_passive_action(action):
			_promote_passive_swipe_preview_card(card, skill_id)
			continue
		if action.is_empty() or action_id.is_empty():
			continue
		_promote_action_swipe_preview_card(card, skill_id, action_id, action)
	for raw_built in preview_state.get("fishing_built_modules", []) as Array:
		var built := raw_built as Dictionary
		if built.is_empty():
			continue
		var area_key := str(built.get("area_key", ""))
		if area_key.is_empty():
			continue
		_register_action_card(area_key, built.get("area_card", {}) as Dictionary)
		var root := built.get("root") as Control
		if root != null and is_instance_valid(root):
			_enable_interactive_control_tree(root)
			for method_id in built.get("method_ids", []) as Array:
				detail_action_card_nodes[str(method_id)] = root
	_skill_detail_surface().detail_rendered_action_ids = _fishing_ui_surface()._fishing_detail_render_signature()


func _enable_interactive_control_tree(root: Control) -> void:
	if root == null or not is_instance_valid(root):
		return
	if root is Button:
		root.mouse_filter = Control.MOUSE_FILTER_STOP
	elif root.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		root.mouse_filter = Control.MOUSE_FILTER_PASS
	for child in root.get_children():
		var child_control := child as Control
		if child_control != null:
			_enable_interactive_control_tree(child_control)


func _navigate_skill_page(offset: int, entry_x := 0.0, animate_entry := true, play_click := true) -> void:
	if not _onboarding_runtime()._swipe_offset_accessible(offset):
		return
	if not skill_strip_ids.is_empty():
		_navigate_skill_strip(offset, entry_x, animate_entry, play_click)
		return
	var current_index := _skill_index(selected_skill_id)
	if current_index < 0:
		return
	var skill_count := skill_defs.size()
	if skill_count <= 0:
		return
	_action_runtime()._cancel_stamina_gauge_boost_for_navigation()
	_collapse_expanded_activity_modules()
	var next_index := (current_index + offset) % skill_count
	if next_index < 0:
		next_index += skill_count
	var next_skill_id := str(skill_defs[next_index]["id"])
	if play_click:
		button_press_runtime.play_default_button_sfx()
	var use_outgoing_animation := animate_entry and absf(entry_x) > 1.0
	var use_gap_load_transition := use_outgoing_animation and SKILL_SWIPE_GAP_LOAD_TRANSITION_ENABLED
	var gap_entry_x := float(signi(offset)) * _skill_swipe_page_span() if use_gap_load_transition else 0.0
	var incoming_preview := {}
	if offset != 0:
		incoming_preview = _skill_swipe_activity_surface()._extract_incoming_swipe_preview(offset)
	_skill_swipe_activity_surface()._park_skill_swipe_preview()
	if offset != 0 and selected_skill_id == TUTORIAL_STARTER_SKILL_ID:
		_onboarding_runtime()._clear_tutorial_gate_latch_only_after_skill_swipe(false)
	if not play_click and not animate_entry and absf(entry_x) <= 1.0:
		_begin_skill_swipe_handoff_cover()
	var transition_cover := _begin_skill_swipe_outgoing_cover() if use_outgoing_animation else null
	if use_outgoing_animation:
		if not use_gap_load_transition:
			_discard_incoming_swipe_preview_for_animated_handoff(incoming_preview)
			incoming_preview = {}
		skill_swipe_animating = true
		skill_swipe_animation_mode = "entry"
		if transition_cover != null and is_instance_valid(transition_cover) and not use_gap_load_transition:
			await _fade_skill_swipe_cover_to_opaque(SKILL_SWIPE_CREAM_COVER_FADE_IN_SECONDS)
		if use_gap_load_transition:
			_skill_swipe_activity_surface()._hide_skill_swipe_paper_fade()
		_clear_skill_swipe_content_under_cover()
	selected_skill_id = next_skill_id
	current_screen = "skill"
	var target_key: String = _navigation_shell()._skill_detail_cache_key(next_skill_id)
	skill_swipe_gap_render_offset_x = gap_entry_x
	await _skill_swipe_install_target_page(target_key, incoming_preview)
	if use_gap_load_transition:
		_apply_skill_swipe_drag_offset(gap_entry_x)
		if transition_cover != null and is_instance_valid(transition_cover):
			transition_cover.set_meta("swipe_gap_entry_reveal_allowed", true)
	skill_swipe_gap_render_offset_x = 0.0
	_update_ui(0.0, true)
	if use_gap_load_transition:
		await _wait_for_skill_swipe_gap_entry_ready(next_skill_id)
	if use_outgoing_animation:
		_begin_skill_swipe_incoming_entry(gap_entry_x if use_gap_load_transition else float(signi(offset)) * _skill_swipe_page_span())
		if use_gap_load_transition:
			call_deferred("_release_skill_swipe_gap_cover_when_ready", next_skill_id)
	else:
		_reset_skill_swipe_entry_positions()
		_complete_skill_swipe_navigation()


func _release_skill_swipe_gap_cover_when_ready(target_skill_id: String) -> void:
	await _wait_for_skill_swipe_gap_entry_ready(target_skill_id)
	if current_screen != "skill" or selected_skill_id != target_skill_id:
		return
	var cover := skill_swipe_handoff_cover
	if cover == null or not is_instance_valid(cover):
		return
	if not bool(cover.get_meta("swipe_gap_entry_reveal_allowed", false)):
		return
	_fade_clear_skill_swipe_cover(SKILL_SWIPE_REBUILD_COVER_FADE_SECONDS)


func _navigate_skill_strip(offset: int, entry_x: float, animate_entry: bool, play_click: bool) -> void:
	var current_index := skill_strip_index
	var skill_count := skill_strip_ids.size()
	var new_index := (current_index + offset) % skill_count
	if new_index < 0:
		new_index += skill_count
	if new_index == current_index:
		return
	_action_runtime()._cancel_stamina_gauge_boost_for_navigation()
	_collapse_expanded_activity_modules()
	if play_click:
		button_press_runtime.play_default_button_sfx()
	var page_width := _skill_content_width()
	var tween_start := entry_x + float(offset) * page_width
	skill_strip_index = new_index
	selected_skill_id = str(skill_strip_ids[new_index])
	current_screen = "skill"
	_swap_skill_strip_refs(selected_skill_id)
	_sync_skill_strip_page_visibility(true)
	_skill_detail_surface()._sync_detail_lazy_visible_cards(true, -1)
	_ensure_finalized_skill_detail_presentable(selected_skill_id)
	_skill_detail_surface()._hold_skill_detail_layout_refresh_after_navigation()
	_clear_page_transient_input_state()
	_update_ui(0.0, true)
	if animate_entry and absf(entry_x) > 1.0:
		_kill_skill_swipe_tween()
		_restore_skill_strip_wrap_page()
		_apply_skill_swipe_drag_offset(tween_start)
		skill_swipe_animating = true
		skill_swipe_animation_mode = "entry"
		skill_swipe_tween = create_tween()
		skill_swipe_tween.tween_method(
			_apply_skill_swipe_drag_offset,
			tween_start,
			0.0,
			SKILL_SWIPE_SETTLE_SECONDS
		).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
		skill_swipe_tween.finished.connect(_complete_skill_swipe_navigation)
	else:
		_complete_skill_swipe_navigation()

func _skill_swipe_preview_fade_progress(abs_x: float) -> float:
	var t := clampf(abs_x / maxf(1.0, host.SKILL_SWIPE_PREVIEW_FADE_DISTANCE), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

func _skill_swipe_paper_fade_progress(abs_x: float) -> float:
	var t := clampf(abs_x / maxf(1.0, host.SKILL_SWIPE_PAPER_FADE_DISTANCE), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

func _set_skill_strip_committed_crossfade(committed: bool) -> void:
	skill_swipe_strip_committed_crossfade = committed

func _paper_fade_hold_active() -> bool:
	return skill_swipe_paper_fade_hold_alpha >= 0.99

func _reset_skill_swipe_fade_state(sync := false) -> void:
	skill_swipe_strip_committed_crossfade = false
	skill_swipe_paper_fade_hold_alpha = 0.0
	if sync:
		_sync_skill_strip_page_crossfade(0.0)
		_sync_skill_swipe_paper_fade(0.0)

func _collect_skill_shelf_backgrounds(root_node: Node, backgrounds: Array) -> void:
	if root_node == null or not is_instance_valid(root_node):
		return
	if root_node is Control and root_node.name == "SkillDetailFullBleedShelfBackground":
		backgrounds.append(root_node)
		return
	for raw_child in root_node.get_children():
		_collect_skill_shelf_backgrounds(raw_child as Node, backgrounds)

func _current_skill_shelf_backgrounds() -> Array:
	var backgrounds := []
	var root_node: Node = skill_swipe_page if skill_swipe_page != null and is_instance_valid(skill_swipe_page) else host.skills_content
	_collect_skill_shelf_backgrounds(root_node, backgrounds)
	return backgrounds

func _skill_swipe_shelf_background_should_start_hidden() -> bool:
	return (
		(
			host.current_screen == "skill"
			and skill_swipe_animating
			and skill_swipe_animation_mode == "entry"
		)
		or host._onboarding_runtime()._tutorial_starter_only_detail_active(host.selected_skill_id)
	)

func _set_skill_shelf_background_alpha(background: Control, alpha: float) -> void:
	if background == null or not is_instance_valid(background):
		return
	host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(background, alpha > 0.001)
	var next_modulate := background.modulate
	next_modulate.a = clampf(alpha, 0.0, 1.0)
	host._app_lifecycle_runtime().set_canvas_item_modulate_if_changed(background, next_modulate)

func _set_skill_shelf_background_alpha_by_id(background_id: int, alpha: float) -> void:
	_set_skill_shelf_background_alpha(host._app_lifecycle_runtime().valid_control_ref(instance_from_id(background_id)), alpha)

func _fade_skill_shelf_backgrounds(visible: bool, seconds := -1.0) -> void:
	if seconds < 0.0:
		seconds = SKILL_SWIPE_SHELF_BACKGROUND_FADE_IN_SECONDS if visible else SKILL_SWIPE_SHELF_BACKGROUND_FADE_OUT_SECONDS
	for raw_background in _current_skill_shelf_backgrounds():
		var background := raw_background as Control
		if background == null or not is_instance_valid(background):
			continue
		host._app_lifecycle_runtime()._kill_meta_tween(background, "skill_swipe_shelf_background_fade_tween")
		var target_alpha := 1.0 if visible else 0.0
		if seconds <= 0.001:
			_set_skill_shelf_background_alpha(background, target_alpha)
			continue
		var tween: Tween = host.create_tween()
		background.set_meta("skill_swipe_shelf_background_fade_tween", tween)
		var background_id := background.get_instance_id()
		tween.tween_method(
			func(alpha: float) -> void:
				_set_skill_shelf_background_alpha_by_id(background_id, alpha),
			background.modulate.a,
			target_alpha,
			seconds
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_callback(_finish_skill_shelf_background_fade.bind(background_id))

func _finish_skill_shelf_background_fade(background_id: int) -> void:
	var background: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(background_id))
	if background != null and background.has_meta("skill_swipe_shelf_background_fade_tween"):
		background.remove_meta("skill_swipe_shelf_background_fade_tween")

func _ensure_skill_swipe_paper_fade_overlay() -> void:
	if host.skills_page == null or not is_instance_valid(host.skills_page):
		return
	if skill_swipe_paper_fade_overlay != null and is_instance_valid(skill_swipe_paper_fade_overlay):
		host._navigation_shell()._apply_skill_page_cover_bounds(skill_swipe_paper_fade_overlay, true)
		return
	skill_swipe_paper_fade_overlay = ColorRect.new()
	skill_swipe_paper_fade_overlay.color = host._theme_paper_color()
	host._navigation_shell()._apply_skill_page_cover_bounds(skill_swipe_paper_fade_overlay, true)
	skill_swipe_paper_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skill_swipe_paper_fade_overlay.z_index = 0
	skill_swipe_paper_fade_overlay.z_as_relative = false
	skill_swipe_paper_fade_overlay.visible = false
	host._skill_swipe_activity_surface()._ensure_skill_nav_cover_layer().add_child(skill_swipe_paper_fade_overlay)

func _sync_skill_swipe_paper_fade(drag_x: float) -> void:
	if skill_swipe_paper_fade_overlay == null or not is_instance_valid(skill_swipe_paper_fade_overlay):
		return
	host._navigation_shell()._apply_skill_page_cover_bounds(skill_swipe_paper_fade_overlay, true)
	var alpha := maxf(_skill_swipe_paper_fade_progress(absf(drag_x)), skill_swipe_paper_fade_hold_alpha)
	if alpha <= 0.01:
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(skill_swipe_paper_fade_overlay, false)
		return
	host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(skill_swipe_paper_fade_overlay, true)
	host._app_lifecycle_runtime().set_canvas_item_alpha_if_changed(skill_swipe_paper_fade_overlay, alpha)

func _hide_skill_swipe_paper_fade() -> void:
	skill_swipe_paper_fade_hold_alpha = 0.0
	if skill_swipe_paper_fade_overlay != null and is_instance_valid(skill_swipe_paper_fade_overlay):
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(skill_swipe_paper_fade_overlay, false)

func _sync_skill_strip_page_crossfade(drag_x: float) -> void:
	if skill_strip_ids.is_empty():
		return
	_hide_skill_swipe_paper_fade()
	var count: int = skill_strip_ids.size()
	if count <= 0 or skill_strip_index < 0:
		return
	var incoming_index: int = skill_strip_index
	var progress := 0.0
	if skill_swipe_strip_committed_crossfade and not skill_swipe_tracking:
		progress = 0.0
	elif absf(drag_x) > 1.0:
		var offset := 1 if drag_x < 0.0 else -1
		if host._onboarding_runtime()._swipe_offset_accessible(offset):
			incoming_index = (skill_strip_index + offset) % count
			if incoming_index < 0:
				incoming_index += count
			progress = _skill_swipe_paper_fade_progress(absf(drag_x))
	for i in count:
		var sid := str(skill_strip_ids[i])
		var page := (skill_strip_refs.get(sid, {}) as Dictionary).get("page") as Control
		if page == null or not is_instance_valid(page):
			continue
		var alpha := 1.0 if i == skill_strip_index else 0.0
		if not skill_swipe_strip_committed_crossfade or skill_swipe_tracking:
			if i == skill_strip_index:
				alpha = 1.0 - progress
			elif i == incoming_index:
				alpha = progress
		_set_skill_swipe_control_alpha(page, alpha)

func _hold_skill_swipe_paper_fade_for_commit() -> void:
	_hide_skill_swipe_paper_fade()

func _sync_skill_swipe_drag_frame_fade(drag_x: float) -> void:
	if not skill_strip_ids.is_empty():
		_sync_skill_strip_page_crossfade(drag_x)
		return
	if skill_swipe_animation_mode == "entry":
		_hide_skill_swipe_paper_fade()
		return
	_hide_skill_swipe_paper_fade()

func _sync_skill_swipe_live_page_fade(drag_x: float) -> void:
	if skill_swipe_page == null or not is_instance_valid(skill_swipe_page):
		return
	if not skill_strip_ids.is_empty():
		return
	_set_skill_swipe_control_alpha(skill_swipe_page, 1.0)

func _sync_skill_swipe_preview_page_fade(current_x: float) -> void:
	var active_preview_page := _active_preview_page()
	if active_preview_page == null:
		return
	active_preview_page.visible = false
	var alpha := 1.0
	_set_skill_swipe_control_alpha(active_preview_page, alpha)

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


func _preview_control(value) -> Control:
	if value == null:
		return null
	if typeof(value) != TYPE_OBJECT or not is_instance_valid(value):
		return null
	if value is Control:
		return value as Control
	return null

func _find_skill_preview_actions_scroll(preview_page: Control) -> Control:
	if preview_page == null or not is_instance_valid(preview_page):
		return null
	var nested := _find_skill_preview_actions_scroll_in(preview_page)
	if nested != null:
		return nested
	return null

func _find_skill_preview_actions_scroll_in(control: Control) -> Control:
	if control == null or not is_instance_valid(control):
		return null
	for child in control.get_children():
		if child is ScrollContainer:
			return child as Control
	for child in control.get_children():
		var child_control := child as Control
		if child_control == null:
			continue
		var nested := _find_skill_preview_actions_scroll_in(child_control)
		if nested != null:
			return nested
	return null

func _find_skill_preview_stack(preview_page: Control) -> Control:
	var scroll := _find_skill_preview_actions_scroll(preview_page)
	if scroll == null or scroll.get_child_count() <= 0:
		return null
	return scroll.get_child(0) as Control

func _show_mounted_swipe_preview_modules(preview_page: Control, preview_state: Dictionary) -> void:
	_cancel_skill_swipe_preview_modules_reveal(preview_state)
	var modules_root := preview_state.get("modules_root") as Control
	if modules_root != null and is_instance_valid(modules_root):
		modules_root.visible = true
		modules_root.modulate = Color.WHITE
	_cancel_skill_swipe_preview_modules_reveal(preview_state)
	if modules_root == null or not is_instance_valid(modules_root):
		modules_root = preview_state.get("actions_scroll") as Control
	if modules_root == null or not is_instance_valid(modules_root):
		modules_root = _find_skill_preview_actions_scroll(preview_page)
	if modules_root != null and is_instance_valid(modules_root):
		modules_root.visible = true
		modules_root.modulate = Color(1, 1, 1, 1)
	if preview_page != null and is_instance_valid(preview_page):
		preview_page.visible = true
		preview_page.modulate = Color.WHITE

func _active_preview_page() -> Control:
	return _preview_control(preview_page)

func _active_preview_offset() -> int:
	return preview_offset

func _set_active_preview(page: Control, offset: int) -> void:
	preview_page = page
	preview_offset = offset

func _cancel_preview_prewarm() -> void:
	return


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
	preview_page = host._app_lifecycle_runtime().state_object_ref(state.get("skill_swipe_preview_page"))
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
		and not skill_swipe_tracking
		and not skill_swipe_animating
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
	var xp = SkillState.xp_progress(host.skills, skill_id, SkillState.host_skill_level(host, skill_id))
	var xp_label = state.get("xp_label") as Label
	if xp_label != null:
		xp_label.text = SkillState.level_xp_text(host.skills, skill_id, SkillState.host_skill_level(host, skill_id))
	var xp_bar = state.get("xp_bar") as CleanProgressBar
	if xp_bar != null:
		ThemeStyles.apply_xp_progress_bar_theme(xp_bar, ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE), host.COLOR_INK)
		ThemeStyles.set_progress_bar_value(xp_bar, float(xp["pct"]), delta, instant)
	var fish_circle = state.get("fish_circle")
	if fish_circle != null:
		host._fishing_ui_surface()._set_fish_circle_for_skill(fish_circle, skill_id, instant)
	var regen_circle = state.get("regen_circle")
	if regen_circle != null:
		regen_circle.sync_for_skill(host, skill_id, instant)
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
		var unlocked = host._activity_unlock_runtime()._is_action_unlocked(skill_id, action)
		if host._passive_modules_runtime().is_passive_action(action):
			_update_passive_card_static_state(action_card, skill_id, action, unlocked)
			continue
		var running = host.running_skill_id == skill_id and host.running_action_id == action_id
		host._fighting_runtime().sync_blue_guy_chicken_brawl_stage_active(action_card, skill_id, action_id, running)
		_update_action_card_static_state(action_card, skill_id, action, unlocked)
		if MasteryState.action_has_mastery(host, action):
			var medal = action_card.get("medal") as TextureRect
			var mastery_level = MasteryState.level(host.mastery, host._action_key(skill_id, action_id))
			_set_action_card_medal(action_card, medal, mastery_level, instant)
			_update_action_card_mastery_bar(action_card, skill_id, action_id, delta, instant)
		_sync_action_art_animation_state(action_card, running)
		_update_action_card_run_feedback(action_card, skill_id, running, delta, instant)

func _sync_action_art_animation_state(card: Dictionary, running: bool) -> void:
	var art: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("art"))
	if art == null or not is_instance_valid(art) or not art.has_method("set_playing"):
		return
	art.call("set_playing", running)


func _sync_action_art_animations_for_running_state(force := false) -> void:
	var running_key: String = host._action_key(host.running_skill_id, host.running_action_id) if not host.running_skill_id.is_empty() and not host.running_action_id.is_empty() else ""
	var temporary_events = host._temporary_event_runtime()
	var event_key: String = host._action_key(temporary_events.event_running_skill_id, temporary_events.event_running_action_id) if not temporary_events.event_running_skill_id.is_empty() and not temporary_events.event_running_action_id.is_empty() else ""
	var active_key: String = "%s|%s" % [running_key, event_key]
	if not force and active_key == action_art_last_running_key:
		return
	action_art_last_running_key = active_key
	for raw_key in host.action_card_keys:
		var key := str(raw_key)
		if not host.action_cards.has(key):
			continue
		var card := host.action_cards[key] as Dictionary
		if card.is_empty():
			continue
		var skill_id := str(card.get("skill_id", ""))
		var action_id := str(card.get("action_id", ""))
		var running_here: bool = (
			(not running_key.is_empty() and skill_id == host.running_skill_id and action_id == host.running_action_id)
			or (not event_key.is_empty() and skill_id == temporary_events.event_running_skill_id and action_id == temporary_events.event_running_action_id)
		)
		_sync_action_art_animation_state(card, running_here)


func _update_action_card_run_feedback(card: Dictionary, skill_id: String, running: bool, delta: float, instant: bool, progress_override := -1.0) -> void:
	_sync_action_art_animation_state(card, running)
	var card_progress := clampf(progress_override if progress_override >= 0.0 else host.action_progress, 0.0, 1.0)
	var art: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("art"))
	if art != null and is_instance_valid(art) and art.has_method("set_action_progress"):
		art.call("set_action_progress", card_progress)
	if host._fishing_rework_active_for_skill(skill_id) and card.get("is_fishing_method"):
		return
	if host._fishing_rework_active_for_skill(skill_id):
		var fluid_strip := card.get("fluid_strip") as Control
		if fluid_strip != null:
			if fluid_strip.has_method("set_running"):
				fluid_strip.call("set_running", running)
			if running and fluid_strip.has_method("set_attempt_progress"):
				fluid_strip.call("set_attempt_progress", card_progress)
			if card.get("is_fishing_area"):
				var water_strip_host := card.get("water_strip_host") as Control
				if water_strip_host != null:
					var strip_visible := running
					if fluid_strip != null and fluid_strip.has_method("is_animating_visible"):
						strip_visible = strip_visible or bool(fluid_strip.call("is_animating_visible"))
					host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(water_strip_host, strip_visible)
					card["fluid_exiting"] = (not running) and strip_visible
					card["fluid_was_running"] = running
			return
	var action_id_for_card := str(card.get("action_id", ""))
	var action_for_card: Dictionary = host._action_data(skill_id, action_id_for_card)
	if host._convergence_runtime()._is_convergence_action(action_for_card):
		var convergence_progress := card.get("convergence_progress") as ConvergenceMultiProgressBar
		if convergence_progress != null:
			var values: Array = host._convergence_runtime()._convergence_segment_progress(action_for_card, card_progress if running else 0.0)
			var colors := []
			for raw_skill_id in host._convergence_runtime()._convergence_skill_order(action_for_card):
				colors.append(ThemeStyles.skill_theme_color(str(raw_skill_id), host.COLOR_BLUE))
			host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(convergence_progress, host._convergence_runtime()._convergence_is_built(action_id_for_card))
			convergence_progress.set_bar_pattern(host._convergence_runtime()._convergence_bar_pattern(action_for_card))
			convergence_progress.set_segments(values, colors)
		return
	var progress_rail := card.get("progress") as ActivityProgressRail
	if progress_rail != null:
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(progress_rail, true)
		ThemeStyles.sync_action_card_progress_rail_theme(card, progress_rail, skill_id, action_for_card, Callable(host._activity_unlock_runtime(), "_action_unlock_requirements"), host.COLOR_BLUE, host.COLOR_INK)
		var action_id := str(card.get("action_id", ""))
		var opportunity_windows: Array[Vector2] = []
		var opportunity_active := false
		var opportunity_visible := false
		if running and not action_id.is_empty():
			opportunity_windows = host._action_runtime()._action_opportunity_pattern_windows(skill_id, action_id)
			opportunity_active = host._action_runtime()._action_opportunity_active(skill_id, action_id)
			opportunity_visible = true
		progress_rail.set_opportunity_windows(opportunity_windows, opportunity_active, opportunity_visible, host._action_runtime().action_opportunity_missed)
		var canceled_progress: float = 0.0 if running else host._action_runtime()._canceled_action_progress(skill_id, action_id)
		var progress_target: float = (card_progress if running else canceled_progress) * 100.0
		var progress_instant := instant
		var previous_progress := float(card.get("last_running_progress", card_progress))
		var progress_speed := float(card.get("last_running_progress_speed", 0.0))
		if running and not instant and card_progress + 0.001 < previous_progress:
			card["progress_turnover_elapsed"] = 0.0
			card["progress_turnover_start"] = progress_rail.value
		if running:
			if delta > 0.0 and card_progress >= previous_progress:
				progress_speed = (card_progress - previous_progress) * 100.0 / delta
				card["last_running_progress_speed"] = progress_speed
			card["last_running_progress"] = card_progress
		else:
			card.erase("last_running_progress")
			card.erase("last_running_progress_speed")
			card.erase("progress_turnover_elapsed")
			card.erase("progress_turnover_start")
		if not running and canceled_progress > 0.0:
			progress_instant = true
		if card.has("progress_turnover_elapsed"):
			var turnover_elapsed := float(card["progress_turnover_elapsed"]) + maxf(0.0, delta)
			var step_delta := minf(maxf(0.0, delta), 0.1)
			var follower_weight := 1.0 - exp(-progress_rail.easing_speed * step_delta)
			var handoff_lag := progress_speed * step_delta / follower_weight if follower_weight > 0.0001 else 0.0
			card["progress_turnover_elapsed"] = turnover_elapsed
			progress_rail.set_value(_action_progress_turnover_value(turnover_elapsed, progress_target, float(card.get("progress_turnover_start", progress_rail.value)), progress_speed, handoff_lag))
			if turnover_elapsed >= ACTION_PROGRESS_TURNOVER_SECONDS:
				card.erase("progress_turnover_elapsed")
				card.erase("progress_turnover_start")
		else:
			ThemeStyles.set_progress_bar_value(progress_rail, progress_target, delta, progress_instant)
		host._material_collection_surface()._sync_mat_collection_card(card, running, instant)


func _action_progress_turnover_value(elapsed: float, live_target: float, start_value: float, live_speed: float, handoff_lag: float) -> float:
	var empty_start := ACTION_PROGRESS_TURNOVER_DRAIN_SECONDS
	var recover_start := empty_start + ACTION_PROGRESS_TURNOVER_EMPTY_SECONDS
	if elapsed < empty_start:
		var drain_progress := clampf(elapsed / ACTION_PROGRESS_TURNOVER_DRAIN_SECONDS, 0.0, 1.0)
		return lerpf(start_value, 0.0, smoothstep(0.0, 1.0, drain_progress))
	if elapsed < recover_start:
		return 0.0
	var recover_progress := clampf((elapsed - recover_start) / ACTION_PROGRESS_TURNOVER_RECOVER_SECONDS, 0.0, 1.0)
	var recover_progress_squared := recover_progress * recover_progress
	var recover_progress_cubed := recover_progress_squared * recover_progress
	var handoff_value := maxf(0.0, live_target - handoff_lag)
	var handoff_tangent := live_speed * ACTION_PROGRESS_TURNOVER_RECOVER_SECONDS
	return clampf((-2.0 * recover_progress_cubed + 3.0 * recover_progress_squared) * handoff_value + (recover_progress_cubed - recover_progress_squared) * handoff_tangent, 0.0, live_target)

func _set_action_card_medal(card: Dictionary, medal: TextureRect, mastery_level: int, instant: bool) -> void:
	if medal == null or not is_instance_valid(medal):
		return
	var last_level := int(card.get("last_mastery_level", -1))
	if last_level == mastery_level:
		return
	var should_animate := not instant and last_level >= 0 and mastery_level > last_level and mastery_level > 0
	var old_texture := medal.texture
	var replacing := should_animate and last_level > 0 and old_texture != null and medal.visible
	_clear_action_card_medal_ceremony(card)
	if should_animate:
		_play_new_medal_ceremony(card, medal, old_texture, replacing, mastery_level)
	else:
		_place_action_card_medal(card, medal, mastery_level)
	card["last_mastery_level"] = mastery_level


func _action_card_medal_texture_for_level(mastery_level: int) -> Texture2D:
	return AchievementPresentation.mastery_medal_visual_texture(mastery_level, host.MASTERY_MAX_LEVEL, Callable(host.visual_texture_cache, "_texture"), Callable(host.visual_texture_cache, "_visual_fallback_texture")) if mastery_level > 0 else host.visual_texture_cache._visual_fallback_texture()


func _action_card_medal_size(mastery_level: int) -> Vector2:
	if ACTION_CARD_MEDAL_WINGED_SIZES.has(mastery_level):
		return ACTION_CARD_MEDAL_WINGED_SIZES[mastery_level] as Vector2
	return ACTION_CARD_MEDAL_STANDARD_SIZE * AchievementPresentation.mastery_medal_display_scale(mastery_level)


func _apply_action_card_medal_layout(card: Dictionary, medal: TextureRect, mastery_level: int) -> Vector2:
	var size := _action_card_medal_size(mastery_level)
	medal.size = size
	var destination := -size * 0.5 + ACTION_CARD_MEDAL_CORNER_INSET
	card["medal_destination"] = destination
	return destination


func _update_action_card_mastery_bar(card: Dictionary, skill_id: String, action_id: String, _delta: float, instant: bool) -> void:
	var mastery_bar := card.get("mastery") as Control
	if mastery_bar == null or not is_instance_valid(mastery_bar):
		return
	var action: Dictionary = host._action_data(skill_id, action_id)
	if not bool(card.get("mastery_bar_instant_updates", false)):
		var mastery_ring := card.get("mastery_ring") as Control
		var normal_mastery_action_id := str(card.get("mastery_action_id", action_id))
		var normal_mastery_level: int = MasteryState.level(host.mastery, host._action_key(skill_id, normal_mastery_action_id))
		var normal_maxed: bool = normal_mastery_level >= host.MASTERY_MAX_LEVEL
		if mastery_ring != null and is_instance_valid(mastery_ring):
			mastery_ring.visible = not normal_maxed
			if mastery_ring.has_method("set_progress"):
				var ring_progress := 1.0 if normal_maxed else MasteryState.progress_pct(host.mastery, host._action_key(skill_id, normal_mastery_action_id), host.MASTERY_MAX_LEVEL) / 100.0
				mastery_ring.call("set_progress", ring_progress)
		mastery_bar.visible = false
		return
	if host._convergence_runtime()._is_convergence_action(action):
		if bool(card.get("mastery_hidden_for_convergence", false)) and not mastery_bar.visible:
			return
		card["mastery_hidden_for_convergence"] = true
		mastery_bar.visible = false
		var medal := card.get("medal") as TextureRect
		if medal != null:
			medal.visible = false
		return
	card.erase("mastery_hidden_for_convergence")
	var mastery_action_id := str(card.get("mastery_action_id", action_id))
	var mastery_level: int = MasteryState.level(host.mastery, host._action_key(skill_id, mastery_action_id))
	var maxed: bool = mastery_level >= host.MASTERY_MAX_LEVEL
	var progress_pct := 100.0 if maxed else MasteryState.progress_pct(host.mastery, host._action_key(skill_id, mastery_action_id), host.MASTERY_MAX_LEVEL)
	var theme_color := ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE)
	var refresh_key := "%s|%s|%s|%s|%s|%s" % [
		skill_id,
		mastery_action_id,
		mastery_level,
		GameFormatting.info_chip_number(progress_pct),
		maxed,
		theme_color.to_html(true)
	]
	if not instant and str(card.get("mastery_bar_refresh_key", "")) == refresh_key:
		return
	card["mastery_bar_refresh_key"] = refresh_key
	if mastery_bar is CleanProgressBar:
		ThemeStyles.apply_mastery_progress_bar_theme(mastery_bar as CleanProgressBar, theme_color, host.COLOR_INK)
	mastery_bar.visible = not maxed
	if maxed:
		_clear_mastery_bar_tween(mastery_bar)
		return
	_set_mastery_bar(mastery_bar, progress_pct, instant or bool(card.get("mastery_bar_instant_updates", false)))


func _set_mastery_bar(mastery_bar: Control, target: float, instant: bool) -> void:
	if mastery_bar == null or not is_instance_valid(mastery_bar):
		return
	var current_value := 0.0
	if mastery_bar is CleanProgressBar:
		current_value = float((mastery_bar as CleanProgressBar).value)
	else:
		return
	var clamped_target := clampf(target, 0.0, 100.0)
	var previous_target := float(mastery_bar.get_meta("mastery_bar_target", -9999.0))
	var initialized := bool(mastery_bar.get_meta("mastery_bar_initialized", false))
	if instant or not initialized:
		_clear_mastery_bar_tween(mastery_bar)
		mastery_bar.set_meta("mastery_bar_initialized", true)
		mastery_bar.set_meta("mastery_bar_target", clamped_target)
		if absf(current_value - clamped_target) > 0.001:
			mastery_bar.call("set_value", clamped_target)
		return
	if absf(previous_target - clamped_target) <= 0.001:
		return
	mastery_bar.set_meta("mastery_bar_target", clamped_target)
	_clear_mastery_bar_tween(mastery_bar)
	if absf(current_value - clamped_target) <= 0.01:
		mastery_bar.call("set_value", clamped_target)
		return
	var tween: Tween = host.create_tween()
	mastery_bar.set_meta("mastery_bar_tween", tween)
	var mastery_bar_id := mastery_bar.get_instance_id()
	tween.tween_method(_set_mastery_bar_value_bound.bind(mastery_bar_id), current_value, clamped_target, MASTERY_BAR_EASE_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_finish_mastery_bar_tween.bind(mastery_bar_id, clamped_target))


func _set_mastery_bar_value_bound(value: float, mastery_bar_id: int) -> void:
	var mastery_bar: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(mastery_bar_id))
	if mastery_bar == null:
		return
	mastery_bar.call("set_value", value)


func _finish_mastery_bar_tween(mastery_bar_id: int, clamped_target: float) -> void:
	var callback_mastery_bar: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(mastery_bar_id))
	if callback_mastery_bar == null:
		return
	callback_mastery_bar.call("set_value", clamped_target)
	if callback_mastery_bar.has_meta("mastery_bar_tween"):
		callback_mastery_bar.remove_meta("mastery_bar_tween")


func _clear_mastery_bar_tween(mastery_bar: Control) -> void:
	host._app_lifecycle_runtime()._kill_meta_tween(mastery_bar, "mastery_bar_tween")


func _place_action_card_medal(card: Dictionary, medal: TextureRect, mastery_level: int) -> void:
	var destination := _apply_action_card_medal_layout(card, medal, mastery_level)
	host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(medal, mastery_level > 0)
	medal.texture = _action_card_medal_texture_for_level(mastery_level)
	if mastery_level > 0 and medal.texture == null:
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(medal, false)
		return
	medal.position = destination
	medal.scale = Vector2.ONE
	medal.rotation_degrees = 0.0
	medal.pivot_offset = medal.size * 0.5
	host._app_lifecycle_runtime().set_canvas_item_modulate_if_changed(medal, Color.WHITE)


func _play_action_card_medal_tap_ceremony(card: Dictionary) -> void:
	var medal := card.get("medal") as TextureRect
	if medal == null or not is_instance_valid(medal) or not medal.visible:
		return
	var mastery_level := _action_card_visible_medal_level(card)
	if mastery_level <= 0:
		return
	_clear_action_card_medal_tap_ceremony(card)
	_play_action_card_medal_tap_pop(card, medal)
	_play_action_card_medal_shader_shine(card, medal, mastery_level, 0.04, mastery_level <= 2)
	var sparkle_count := _action_card_medal_tap_sparkle_count(mastery_level)
	for i in range(sparkle_count):
		_spawn_action_card_medal_sparkle(card, medal, mastery_level, i, sparkle_count)
	for raw_shine_step in ACTION_CARD_MEDAL_TAP_EXTRA_SHINE_STEPS:
		var shine_step := raw_shine_step as Dictionary
		if mastery_level >= int(shine_step.get("level", 0)):
			var shine_delay := float(shine_step.get("delay", 0.30))
			_play_action_card_medal_shader_shine(card, medal, mastery_level, shine_delay, false)


func _play_action_card_medal_tap_pop(card: Dictionary, medal: TextureRect) -> void:
	host._app_lifecycle_runtime()._kill_meta_tween(medal, "medal_tap_pop_tween")
	var destination := _action_card_medal_destination(card, medal)
	medal.position = destination
	medal.scale = Vector2.ONE
	medal.rotation_degrees = 0.0
	medal.pivot_offset = medal.size * 0.5
	var tween: Tween = host.create_tween()
	medal.set_meta("medal_tap_pop_tween", tween)
	tween.tween_property(medal, "scale", Vector2(1.13, 1.13), 0.075).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(medal, "rotation_degrees", -3.0, 0.075).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(medal, "scale", Vector2(0.97, 0.97), 0.075).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(medal, "rotation_degrees", 2.0, 0.075).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(medal, "scale", Vector2.ONE, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(medal, "rotation_degrees", 0.0, 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_finish_action_card_medal_tap_pop.bind(medal.get_instance_id()))


func _finish_action_card_medal_tap_pop(medal_id: int) -> void:
	var medal: TextureRect = host._app_lifecycle_runtime().valid_texture_rect_ref(instance_from_id(medal_id))
	if medal == null:
		return
	medal.scale = Vector2.ONE
	medal.rotation_degrees = 0.0
	if medal.has_meta("medal_tap_pop_tween"):
		medal.remove_meta("medal_tap_pop_tween")


func _action_card_medal_tap_sparkle_count(mastery_level: int) -> int:
	if mastery_level <= 0:
		return 0
	var index := clampi(mastery_level - 1, 0, ACTION_CARD_MEDAL_TAP_SPARKLE_COUNTS.size() - 1)
	return int(ACTION_CARD_MEDAL_TAP_SPARKLE_COUNTS[index])


func _spawn_action_card_medal_sparkle(card: Dictionary, medal: TextureRect, mastery_level: int, sparkle_index: int, sparkle_count: int) -> void:
	var parent := medal.get_parent() as Control
	if parent == null or not is_instance_valid(parent):
		return
	var tier_ratio := clampf(float(mastery_level - 1) / float(maxi(1, host.MASTERY_MAX_LEVEL - 1)), 0.0, 1.0)
	var star := AchievementPresentation.MedalSparkleStar.new()
	var star_size := randf_range(92.0, 112.0 + tier_ratio * 28.0)
	star.size = Vector2(star_size, star_size)
	star.fill_color = _action_card_medal_sparkle_color(mastery_level, sparkle_index)
	star.outline_color = Color("#171615", 0.58)
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	star.z_index = medal.z_index + 4 + sparkle_index
	star.modulate = Color(1, 1, 1, 0)
	star.scale = Vector2(0.22, 0.22)
	star.rotation = randf_range(-0.35, 0.35)
	var origin := medal.position + medal.size * 0.5 - star.size * 0.5
	star.position = origin
	parent.add_child(star)
	var angle := randf_range(-PI, PI)
	var wave_ratio := float(sparkle_index) / maxf(1.0, float(sparkle_count - 1))
	var distance := randf_range(34.0, 70.0 + tier_ratio * 122.0) + wave_ratio * (18.0 + tier_ratio * 38.0)
	var target_position := origin + Vector2(cos(angle), sin(angle)) * distance
	var peak_scale := Vector2.ONE * randf_range(1.06, 1.42 + tier_ratio * 0.36)
	var delay := 0.07 + wave_ratio * (0.30 + tier_ratio * 0.15) + randf_range(0.0, 0.035)
	var tween: Tween = host.create_tween()
	star.set_meta("medal_tap_effect_tween", tween)
	_register_action_card_medal_tap_effect(card, star, tween)
	tween.tween_interval(delay)
	tween.tween_property(star, "modulate:a", 1.0, 0.055).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(star, "scale", peak_scale, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(star, "position", origin.lerp(target_position, 0.56), 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(star, "rotation", star.rotation + randf_range(-0.75, 0.75), 0.26).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(star, "position", target_position, 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(star, "scale", Vector2(0.18, 0.18), 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(star, "modulate:a", 0.0, 0.30).set_delay(0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(_finish_action_card_medal_tap_effect.bind(str(card.get("card_key", "")), star.get_instance_id()))


func _play_action_card_medal_shader_shine(card: Dictionary, medal: TextureRect, mastery_level: int, delay: float, tiny := false) -> void:
	if medal == null or not is_instance_valid(medal):
		return
	var shine_overlay := _MedalShineSlash.new()
	shine_overlay.anchor_left = 0.0
	shine_overlay.anchor_right = 0.0
	shine_overlay.anchor_top = 0.0
	shine_overlay.anchor_bottom = 0.0
	shine_overlay.position = Vector2.ZERO
	shine_overlay.size = medal.size
	shine_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shine_overlay.z_index = 1
	shine_overlay.modulate = Color.WHITE
	var tier_ratio := clampf(float(mastery_level - 1) / float(maxi(1, host.MASTERY_MAX_LEVEL - 1)), 0.0, 1.0)
	shine_overlay.line_width = 10.0 if tiny else 13.0 + tier_ratio * 7.0
	shine_overlay.shine_color = Color(1.0, 0.96, 0.76, 0.84 if tiny else 0.96)
	medal.add_child(shine_overlay)
	var duration := 0.34 if tiny else 0.42 + tier_ratio * 0.16
	var tween: Tween = host.create_tween()
	shine_overlay.set_meta("medal_tap_effect_tween", tween)
	_register_action_card_medal_tap_effect(card, shine_overlay, tween)
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_method(_set_action_card_medal_shader_shine_progress.bind(shine_overlay.get_instance_id()), 0.0, 1.0, duration).set_trans(Tween.TRANS_LINEAR)
	tween.finished.connect(_finish_action_card_medal_tap_effect.bind(str(card.get("card_key", "")), shine_overlay.get_instance_id()))


func _set_action_card_medal_shader_shine_progress(progress: float, medal_id: int) -> void:
	var shine_overlay := instance_from_id(medal_id) as _MedalShineSlash
	if shine_overlay == null or not is_instance_valid(shine_overlay):
		return
	shine_overlay.set_progress(progress)


func _restore_action_card_medal_material(medal: TextureRect) -> void:
	if medal == null or not is_instance_valid(medal):
		return
	if medal.has_meta("medal_shine_original_material"):
		medal.material = medal.get_meta("medal_shine_original_material") as Material
		medal.remove_meta("medal_shine_original_material")
	else:
		medal.material = null


func _action_card_medal_sparkle_color(mastery_level: int, sparkle_index: int) -> Color:
	var palette := _action_card_medal_sparkle_palette(mastery_level)
	if palette.is_empty():
		return Color.WHITE
	return palette[sparkle_index % palette.size()] as Color


func _action_card_medal_sparkle_palette(mastery_level: int) -> Array:
	if mastery_level <= 0:
		return []
	var index := clampi(mastery_level - 1, 0, ACTION_CARD_MEDAL_TAP_SPARKLE_PALETTES.size() - 1)
	return ACTION_CARD_MEDAL_TAP_SPARKLE_PALETTES[index] as Array


func _register_action_card_medal_tap_effect(card: Dictionary, node: Node, tween: Tween) -> void:
	var effects := card.get("medal_tap_effects", []) as Array
	effects.append(node)
	card["medal_tap_effects"] = effects
	var tweens := card.get("medal_tap_tweens", []) as Array
	tweens.append(tween)
	card["medal_tap_tweens"] = tweens


func _finish_action_card_medal_tap_effect(card_key: String, effect_id: int) -> void:
	var effect: Node = host._app_lifecycle_runtime().valid_node_ref(instance_from_id(effect_id))
	if effect != null:
		effect.queue_free()
	var card := host.action_cards.get(card_key, {}) as Dictionary
	if card.is_empty():
		return
	var remaining_effects := []
	for raw_effect in card.get("medal_tap_effects", []) as Array:
		if raw_effect != null and is_instance_valid(raw_effect) and raw_effect is Node and raw_effect.get_instance_id() != effect_id:
			remaining_effects.append(raw_effect)
	card["medal_tap_effects"] = remaining_effects


func _clear_action_card_medal_tap_ceremony(card: Dictionary) -> void:
	for raw_tween in card.get("medal_tap_tweens", []) as Array:
		if raw_tween != null and is_instance_valid(raw_tween) and raw_tween is Tween and raw_tween.is_valid():
			raw_tween.kill()
	card.erase("medal_tap_tweens")
	card.erase("medal_shine_active_count")
	var medal = card.get("medal", null)
	if medal != null and is_instance_valid(medal):
		_restore_action_card_medal_material(medal)
		if medal.has_meta("medal_tap_effect_tween"):
			medal.remove_meta("medal_tap_effect_tween")
	for raw_effect in card.get("medal_tap_effects", []) as Array:
		if raw_effect != null and is_instance_valid(raw_effect) and raw_effect is Node and raw_effect != medal:
			raw_effect.queue_free()
	card.erase("medal_tap_effects")


func _play_new_medal_ceremony(card: Dictionary, medal: TextureRect, old_texture: Texture2D, replacing: bool, mastery_level: int) -> void:
	if replacing:
		_start_replaced_medal_fall(card, medal, old_texture)
	var destination := _apply_action_card_medal_layout(card, medal, mastery_level)
	medal.texture = _action_card_medal_texture_for_level(mastery_level)
	host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(medal, true)
	medal.position = destination + Vector2(92, -148)
	medal.scale = Vector2(1.34, 1.34)
	medal.rotation_degrees = -7.0
	medal.pivot_offset = medal.size * 0.5
	host._app_lifecycle_runtime().set_canvas_item_modulate_if_changed(medal, Color(1, 1, 1, 0))
	var anticipation_position := destination + Vector2(122, -192)
	var tween: Tween = host.create_tween()
	card["medal_ceremony_tween"] = tween
	tween.tween_property(medal, "position", anticipation_position, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(medal, "scale", Vector2(1.48, 1.48), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(medal, "rotation_degrees", -13.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(medal, "modulate:a", 1.0, 0.12)
	tween.chain().tween_property(medal, "position", destination, 0.48).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(medal, "scale", Vector2(0.95, 0.95), 0.48).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(medal, "rotation_degrees", 2.0, 0.48).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(medal, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(medal, "rotation_degrees", 0.0, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var medal_id := medal.get_instance_id()
	tween.finished.connect(_finish_new_medal_ceremony.bind(str(card.get("card_key", "")), medal_id, destination))


func _finish_new_medal_ceremony(card_key: String, medal_id: int, destination: Vector2) -> void:
	var callback_medal: TextureRect = host._app_lifecycle_runtime().valid_texture_rect_ref(instance_from_id(medal_id))
	if callback_medal != null and not callback_medal.is_queued_for_deletion():
		callback_medal.position = destination
		callback_medal.scale = Vector2.ONE
		callback_medal.rotation_degrees = 0.0
		host._app_lifecycle_runtime().set_canvas_item_modulate_if_changed(callback_medal, Color.WHITE)
	var card := host.action_cards.get(card_key, {}) as Dictionary
	if not card.is_empty():
		card.erase("medal_ceremony_tween")
		_play_earned_medal_tap_ceremony(card, callback_medal)


func _play_earned_medal_tap_ceremony(card: Dictionary, medal: TextureRect) -> void:
	if card.is_empty() or medal == null or not is_instance_valid(medal) or not medal.is_visible_in_tree():
		return
	var card_medal = card.get("medal", null)
	if card_medal != medal:
		return
	_play_action_card_medal_tap_ceremony(card)


func _start_replaced_medal_fall(card: Dictionary, medal: TextureRect, old_texture: Texture2D) -> void:
	var parent := medal.get_parent() as Control
	if parent == null or old_texture == null:
		return
	var origin := medal.position
	var outgoing := TextureRect.new()
	outgoing.texture = old_texture
	outgoing.anchor_left = 0.0
	outgoing.anchor_right = 0.0
	outgoing.anchor_top = 0.0
	outgoing.anchor_bottom = 0.0
	outgoing.expand_mode = medal.expand_mode
	outgoing.stretch_mode = medal.stretch_mode
	outgoing.position = origin
	outgoing.size = medal.size
	outgoing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outgoing.z_index = medal.z_index + 1
	outgoing.pivot_offset = outgoing.size * 0.5
	outgoing.scale = medal.scale
	outgoing.rotation_degrees = medal.rotation_degrees
	outgoing.modulate = medal.modulate
	parent.add_child(outgoing)
	card["medal_outgoing"] = outgoing
	var tween: Tween = host.create_tween()
	card["medal_outgoing_tween"] = tween
	tween.set_parallel(true)
	tween.tween_property(outgoing, "position", origin + Vector2(-62, 260), 0.60).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(outgoing, "rotation_degrees", -46.0, 0.60).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(outgoing, "scale", Vector2(0.76, 0.76), 0.54).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(outgoing, "modulate:a", 0.0, 0.39).set_delay(0.17).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var outgoing_id := outgoing.get_instance_id()
	tween.finished.connect(_finish_replaced_medal_fall.bind(str(card.get("card_key", "")), outgoing_id))


func _finish_replaced_medal_fall(card_key: String, outgoing_id: int) -> void:
	var callback_outgoing: TextureRect = host._app_lifecycle_runtime().valid_texture_rect_ref(instance_from_id(outgoing_id))
	if callback_outgoing != null:
		callback_outgoing.queue_free()
	var card := host.action_cards.get(card_key, {}) as Dictionary
	if not card.is_empty():
		card.erase("medal_outgoing")
		card.erase("medal_outgoing_tween")


func _clear_action_card_medal_ceremony(card: Dictionary) -> void:
	_clear_action_card_medal_tap_ceremony(card)
	var ceremony_tween = card.get("medal_ceremony_tween", null)
	if ceremony_tween != null and is_instance_valid(ceremony_tween) and ceremony_tween is Tween and ceremony_tween.is_valid():
		ceremony_tween.kill()
	card.erase("medal_ceremony_tween")
	var outgoing_tween = card.get("medal_outgoing_tween", null)
	if outgoing_tween != null and is_instance_valid(outgoing_tween) and outgoing_tween is Tween and outgoing_tween.is_valid():
		outgoing_tween.kill()
	card.erase("medal_outgoing_tween")
	var outgoing = card.get("medal_outgoing", null)
	if outgoing != null and is_instance_valid(outgoing) and outgoing is Node:
		outgoing.queue_free()
	card.erase("medal_outgoing")


func _action_card_medal_destination(card: Dictionary, medal: TextureRect) -> Vector2:
	if card.has("medal_destination"):
		return card["medal_destination"] as Vector2
	card["medal_destination"] = medal.position
	return medal.position

func _action_card_medal_hit_from_positions(card: Dictionary, positions: Array[Vector2]) -> bool:
	for event_position in positions:
		if _action_card_medal_hit_at_position(card, event_position):
			return true
	return false


func _action_card_medal_hit_at_position(card: Dictionary, event_position: Vector2) -> bool:
	var medal := card.get("medal") as TextureRect
	if medal == null or not is_instance_valid(medal):
		return false
	if not medal.visible or not medal.is_visible_in_tree():
		return false
	if _action_card_visible_medal_level(card) <= 0:
		return false
	return medal.get_global_rect().grow(26.0).has_point(event_position)


func _action_card_visible_medal_level(card: Dictionary) -> int:
	if card.is_empty() or bool(card.get("mastery_hidden_for_convergence", false)):
		return 0
	var skill_id := str(card.get("skill_id", ""))
	var action_id := str(card.get("mastery_action_id", card.get("action_id", "")))
	if skill_id.is_empty() or action_id.is_empty():
		return 0
	return clampi(MasteryState.level(host.mastery, host._action_key(skill_id, action_id)), 0, host.MASTERY_MAX_LEVEL)


func _sync_skill_swipe_preview_scroll_state(state: Dictionary) -> void:
	var preview_scroll = state.get("actions_scroll") as ScrollContainer
	if preview_scroll == null or not is_instance_valid(preview_scroll):
		return
	var scroll_value = float(host._skill_detail_surface().detail_actions_scroll.scroll_vertical) if host._skill_detail_surface().detail_actions_scroll != null and is_instance_valid(host._skill_detail_surface().detail_actions_scroll) else 0.0
	var scroll_bar = preview_scroll.get_v_scroll_bar()
	if scroll_bar != null:
		scroll_value = clampf(scroll_value, 0.0, maxf(0.0, scroll_bar.max_value - scroll_bar.page))
	preview_scroll.scroll_vertical = int(round(scroll_value))

func _render_activity_queue_page() -> void:
	var content_width = host._skill_content_width()
	var frame = Control.new()
	frame.name = "ActivityQueueFrame"
	frame.clip_contents = false
	_apply_skill_column_layout(frame, content_width, 0.0)
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
	host.content_scroll.gui_input.connect(Callable(host._navigation_shell(), "_on_pinned_activities_action_scroll_input"))
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
		var module_root = host._navigation_shell()._build_queue_activities_module(module_key, content_width)
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
	bottom_spacer.custom_minimum_size = Vector2(0, host._navigation_shell()._skills_content_bottom_inset_for_screen() + 190.0)
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
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _module_utility_button_style(fill, false, false))
	button.add_theme_stylebox_override("hover", _module_utility_button_style(fill.lightened(0.06), false, false))
	button.add_theme_stylebox_override("pressed", _module_utility_button_style(fill, true, false))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if node_name == "ActivityQueueSetQueueButton":
		button.pressed.connect(_on_activity_queue_set_pressed)
	elif node_name == "ActivityQueueClearQueueButton":
		button.pressed.connect(_on_activity_queue_clear_pressed)
	holder.add_child(button)
	return holder


func _module_utility_button_style(fill: Color, pressed := false, active := false) -> StyleBox:
	return PaperButtonStyles.chunky_activity_button_style(fill, 36, 18, pressed, active, host.paper_button_style_textures, host.COLOR_INK, host.COLOR_BLUE, Callable(host.visual_texture_cache, "_can_create_image_textures"), Callable(host.visual_texture_cache, "_create_image_texture"), Callable(host.visual_texture_cache, "_visual_fallback_texture"))


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
	var pop: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("pop", null))
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
	host.button_press_runtime.play_default_button_sfx()
	return true


func _enter_queue_selection_mode() -> void:
	host.queue_selection_mode = true
	host._navigation_shell().skills_utility_return_screen = "queue"
	host._navigation_shell().skills_utility_return_skill_id = host.selected_skill_id
	if host.current_screen == "queue" or host.current_screen == "pinned":
		host._navigation_shell()._clear_top_level_nav_lock()
		host.current_screen = "menu"
		host._navigation_shell()._render_screen()
	elif host.current_screen == "skill":
		_refresh_activity_queue_visuals()
	elif host.skills_content != null and is_instance_valid(host.skills_content):
		host._navigation_shell()._render_screen()
	_sync_queue_selection_banner()
	_refresh_activity_queue_visuals()


func _finish_queue_selection_mode() -> void:
	host.queue_selection_mode = false
	_sync_queue_selection_banner()
	_begin_direct_skill_nav_cover()
	host.current_screen = "queue"
	host._navigation_shell()._render_screen()


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
	banner.z_index = ProfileChatOverlaySurface.CHAT_UI_Z + 120
	banner.z_as_relative = false
	banner.mouse_filter = Control.MOUSE_FILTER_STOP
	banner.add_theme_stylebox_override("panel", _module_utility_button_style(Color("#47b7d8"), false, true))
	host.add_child(banner)
	queue_selection_banner = banner

	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 42)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(row)
	var title: Label = host._label("QUEUE SELECTION MODE", 96, host.COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(title)


func _refresh_activity_queue_visuals() -> void:
	_sync_queue_overlays_for_visible_cards()
	if host.current_screen == "queue" and not host._navigation_shell().screen_render_in_progress:
		host._navigation_shell()._render_screen()


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
		var area_host: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("queue_overlay_host", null))
		if area_host != null:
			return area_host
	return host._app_lifecycle_runtime().valid_control_ref(card.get("pop", null))


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




func _action_cards_hidden_by_transition_cover() -> bool:
	if not (skill_swipe_pending_full_finalize or skill_swipe_rebuild_cover_active or skill_swipe_defer_initial_lazy_mount or skill_swipe_outgoing_cover_active):
		return false
	if skill_swipe_handoff_cover == null or not is_instance_valid(skill_swipe_handoff_cover):
		return false
	return skill_swipe_handoff_cover.visible and skill_swipe_handoff_cover.modulate.a >= 0.92


func _refresh_visible_action_cards(delta: float, instant: bool, static_refresh: bool, skill_frame_refresh: bool, passive_card_progress_refresh: bool) -> bool:
	if host.current_screen != "skill" and host.current_screen != "pinned" and host.current_screen != "queue" and host.current_screen != "menu":
		return true
	if host._skill_detail_surface().detail_lazy_mounted_this_frame and not instant:
		return false
	if _action_cards_hidden_by_transition_cover():
		return false
	if skill_frame_refresh:
		host._activity_unlock_ceremony_surface().apply_pending_readiness()
	if static_refresh and host.current_screen == "skill" and not host.boot_detail_render_in_progress and host.selected_skill_id == "thieving":
		host._thieving_surface()._cleanup_stale_thieving_heist_cards()
	if not skill_frame_refresh:
		return false
	var temporary_events: Object = host._temporary_event_runtime()
	for raw_key in host.action_card_keys:
		var key := str(raw_key)
		if not host.action_cards.has(key):
			continue
		var card: Dictionary = host.action_cards[key]
		var card_root: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("root", null))
		if card_root == null:
			host._skill_detail_surface()._discard_action_card_key(key)
			continue
		var skill_id := str(card.get("skill_id", ""))
		if (
			host.current_screen != "pinned"
			and host.current_screen != "queue"
			and not skill_strip_ids.is_empty()
			and not skill_id.is_empty()
			and skill_id != host.selected_skill_id
			and skill_id != host.running_skill_id
			and skill_id != temporary_events.event_running_skill_id
		):
			continue
		var action_id := str(card.get("action_id", ""))
		if skill_id.is_empty() or action_id.is_empty():
			var separator := key.find(":")
			if separator > 0:
				if skill_id.is_empty():
					skill_id = key.substr(0, separator)
				if action_id.is_empty() and not key.begins_with("thieving_heist:"):
					action_id = key.substr(separator + 1)
		if card.get("heist_id") != null:
			if static_refresh:
				host._thieving_surface()._update_thieving_heist_card(card, delta, instant)
			continue
		if card.get("is_fishing_area"):
			var area_running: bool = (
				host.running_skill_id == skill_id
				and host._fishing_ui_surface()._fishing_area_card_owns_action(card, host.running_action_id)
			)
			if bool(card.get("fluid_was_running", false)) and not area_running:
				card["fluid_exiting"] = true
			var area_camera_returning: bool = host._fishing_ui_surface()._fishing_area_has_active_camera_return(card)
			if not static_refresh and not area_running and not bool(card.get("fluid_exiting", false)) and not area_camera_returning:
				continue
			host._fishing_ui_surface()._update_fishing_area_module(card, skill_id, area_running, delta, instant)
			continue
		if card.get("is_fishing_method"):
			action_id = str(card.get("action_id", action_id))
			var method_running: bool = host.running_skill_id == skill_id and host.running_action_id == action_id
			if card.get("is_fishing_location"):
				method_running = (
					method_running
					and str(host.fishing_runtime.selected_locations.get(str(card.get("area_id", "")), "")) == str(card.get("location_id", ""))
				)
			if float(card.get("active_camera_zoom", 0.0)) > 1.0 and bool(card.get("active_camera_was_running", false)) and not method_running:
				card["active_camera_returning"] = true
			if not static_refresh and not method_running and not bool(card.get("active_camera_returning", false)):
				continue
			host._fishing_ui_surface()._update_fishing_method_slot(card, skill_id, action_id, {}, false, method_running, delta, instant)
			continue
		var action: Dictionary = host._action_data(skill_id, action_id)
		var event_running: bool = temporary_events.event_running_skill_id == skill_id and temporary_events.event_running_action_id == action_id
		var running: bool = (host.running_skill_id == skill_id and host.running_action_id == action_id) or event_running
		var running_progress: float = temporary_events.event_action_progress if event_running else host.action_progress
		if not running and not static_refresh and not instant:
			continue
		if not running and not static_refresh and (skill_swipe_tracking or skill_swipe_animating):
			continue
		if not running and not static_refresh and not skill_strip_ids.is_empty() and skill_id != host.selected_skill_id:
			continue
		host._fighting_runtime().sync_blue_guy_chicken_brawl_stage_active(card, skill_id, action_id, running)
		host._fighting_runtime().sync_rooster_punch_out_stage_active(card, skill_id, action_id, running)
		if bool(card.get("swipe_proxy", false)):
			continue
		var unlocked: bool = host._activity_unlock_runtime()._is_action_unlocked(skill_id, action)
		if host._passive_modules_runtime().is_passive_action(action):
			if static_refresh:
				host._passive_firepit_surface()._update_passive_card_static_state(card, skill_id, action, unlocked)
			elif passive_card_progress_refresh:
				host._passive_firepit_surface()._update_passive_card_progress(card, action, unlocked, instant)
			continue
		if static_refresh:
			if not card.has("xp") or not card.has("stamina") or not card.has("time") or not card.has("success"):
				host._skill_detail_surface()._discard_action_card_key(key)
				continue
			_update_action_card_static_state(card, skill_id, action, unlocked)
			host._skill_detail_surface()._sync_activity_stat_popup(card, skill_id, action, unlocked, delta, instant)
			var status := card.get("status") as Label
			if status != null:
				host._app_lifecycle_runtime().set_label_text_if_changed(status, "")
			if MasteryState.action_has_mastery(host, action):
				var medal := card.get("medal") as TextureRect
				var mastery_level := MasteryState.level(host.mastery, host._action_key(skill_id, action_id))
				_set_action_card_medal(card, medal, mastery_level, instant)
				_update_action_card_mastery_bar(card, skill_id, action_id, delta, instant)
		elif running and MasteryState.action_has_mastery(host, action):
			_update_action_card_mastery_bar(card, skill_id, action_id, delta, instant)
		if skill_id == "thieving":
			host._thieving_surface()._sync_thieving_action_jail_overlay(card, action_id)
		_update_action_card_run_feedback(card, skill_id, running, delta, instant, running_progress)
	host._activity_unlock_ceremony_surface().sync_hidden_locked_activity_preview_layouts()
	return true


func _action_card_static_refresh_key(skill_id: String, action: Dictionary, unlocked: bool, ceremony_active: bool) -> String:
	if host._convergence_runtime()._is_convergence_action(action):
		return ""
	return "%s|%s|%s|%s|%s" % [
		host._action_runtime()._action_stat_value_cache_key("static", skill_id, action),
		unlocked,
		ceremony_active,
		hash(action.get("xp_rewards", {})),
		ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE).to_html(true)
	]


func _sync_xp_reward_chips(xp_box: Control, xp_label: Label, skill_id: String, action: Dictionary) -> void:
	if xp_box == null or not is_instance_valid(xp_box) or xp_label == null or not is_instance_valid(xp_label):
		return
	if not host._convergence_runtime()._is_convergence_action(action):
		var reward_parts: Array = host._action_runtime()._action_xp_reward_parts_for_display(skill_id, action)
		host._app_lifecycle_runtime().set_label_text_if_changed(xp_label, "+%s" % GameFormatting.info_chip_number(float(host._action_runtime()._action_xp_reward_total(reward_parts))))
	xp_label.visible = true
	if xp_box.has_meta("xp_reward_chip_grid"):
		var existing = xp_box.get_meta("xp_reward_chip_grid")
		if existing is GridContainer and is_instance_valid(existing):
			(existing as GridContainer).queue_free()
		xp_box.remove_meta("xp_reward_chip_grid")
	xp_box.set_meta("xp_reward_chip_key", "")


func _action_stat_chip_buffed(skill_id: String, action: Dictionary, stat_kind: String) -> bool:
	match stat_kind:
		"xp":
			var base_rewards: Dictionary = host._action_runtime()._base_xp_reward_map(action, skill_id)
			var effective_rewards: Dictionary = host._action_runtime()._effective_xp_reward_map(action, skill_id)
			for raw_skill_id in base_rewards.keys():
				var reward_skill_id := str(raw_skill_id)
				if int(effective_rewards.get(reward_skill_id, 0)) > int(base_rewards.get(raw_skill_id, 0)):
					return true
			return false
		"stamina":
			var base_stamina := float(maxi(1, int(action.get("stamina", 1))))
			return host._action_runtime()._effective_stamina(skill_id, action) + 0.0001 < base_stamina
		"time":
			return _action_stat_time_chip_buffed(skill_id, action)
		"success":
			return host._action_runtime()._success_chance(skill_id, action) > _base_success_chance_for_chip(skill_id, action) + 0.001
	return false


func _action_shows_stamina_stat(skill_id: String, action: Dictionary) -> bool:
	return not host._convergence_runtime()._is_convergence_action(action) and not host._action_runtime()._is_fishing_event_action(skill_id, action) and not (host._fishing_rework_active_for_skill(skill_id) and not host._is_event_action(action))


func _action_stamina_stat_text(skill_id: String, action: Dictionary) -> String:
	if not _action_shows_stamina_stat(skill_id, action):
		return ""
	var stamina_value: float = host._action_runtime()._effective_stamina(skill_id, action)
	if stamina_value < -0.0001:
		return "+%s" % GameFormatting.info_chip_number(absf(stamina_value))
	return "%s" % GameFormatting.info_chip_number(stamina_value)


func _action_stat_time_chip_buffed(skill_id: String, action: Dictionary) -> bool:
	if host._fishing_rework_active_for_skill(skill_id):
		return AchievementState.activity_medal_time_reduction(host, skill_id, action) > 0.0 or AchievementState.activity_tier_time_reduction(host, skill_id, action) > 0.0 or host._hub_runtime().mission_bonus_applies(skill_id, action)
	return (
		AchievementState.global_reward_bonus(host, "speed_mult", skill_id) > 0.0
		or host._ad_bonus_runtime().speed_multiplier() > 0.0
		or AchievementState.activity_medal_time_reduction(host, skill_id, action) > 0.0
		or AchievementState.activity_tier_time_reduction(host, skill_id, action) > 0.0
		or host._hub_runtime().mission_bonus_applies(skill_id, action)
	)


func _base_success_chance_for_chip(skill_id: String, action: Dictionary) -> float:
	if host._fishing_rework_active_for_skill(skill_id):
		return clampf(host.fishing_runtime.attempt_success_chance(host, str(action.get("id", ""))), 5.0, 100.0)
	return clampf(float(action.get("success", 90.0)), 5.0, 100.0)


func _action_card_for_input_source(skill_id: String, action_id: String, source: Control) -> Dictionary:
	if source != null and is_instance_valid(source):
		for raw_card in host.action_cards.values():
			var candidate := raw_card as Dictionary
			if candidate.is_empty():
				continue
			if str(candidate.get("skill_id", "")) != skill_id or str(candidate.get("action_id", "")) != action_id:
				continue
			var candidate_button := candidate.get("button", null) as Control
			if candidate_button == source:
				return candidate
			var candidate_pop := candidate.get("pop", null) as Control
			if candidate_pop == source:
				return candidate
			if candidate_pop != null and is_instance_valid(candidate_pop) and candidate_pop.is_ancestor_of(source):
				return candidate
	var key: String = host._action_key(skill_id, action_id)
	return host.action_cards.get(key, {}) as Dictionary


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
	var lock_blocks_button = (not unlocked) or ceremony_active or bool(card.get("unlock_ready_pending", false)) or host._activity_unlock_runtime()._action_has_pending_unlock_readiness(action_id)
	var button = card.get("button") as Button
	if button != null:
		host._app_lifecycle_runtime().set_base_button_disabled_if_changed(button, lock_blocks_button)
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(button, true)
		host._app_lifecycle_runtime().set_canvas_item_modulate_if_changed(button, Color(1, 1, 1, 0))
	var static_refresh_key = _action_card_static_refresh_key(skill_id, action, unlocked, ceremony_active)
	var xp_reward_parts = host._action_runtime()._action_xp_reward_parts_for_display(skill_id, action)
	var xp_text = "+%s" % GameFormatting.info_chip_number(float(host._action_runtime()._action_xp_reward_total(xp_reward_parts)))
	var show_stamina_stat = _action_shows_stamina_stat(skill_id, action)
	var stamina_text = _action_stamina_stat_text(skill_id, action)
	var time_label = "FILL" if host._action_runtime()._fishing_batch_soak_active(skill_id) and not host._is_event_action(action) else "TIME"
	var time_text = "%ss" % GameFormatting.info_chip_number(host._action_runtime()._action_cycle_seconds(skill_id, action))
	var success_text = "%s%%" % GameFormatting.info_chip_number(host._action_runtime()._success_chance(skill_id, action))
	if host._convergence_runtime()._is_convergence_action(action):
		var module_id = str(action.get("id", ConvergenceRuntime.CONVERGENCE_DEFAULT_MODULE_ID))
		xp_text = "+%s ALL" % GameFormatting.info_chip_number(float(host._convergence_runtime()._convergence_current_xp(module_id)))
		stamina_text = ""
		time_label = "CYCLE"
		time_text = "%ss" % GameFormatting.info_chip_number(host._convergence_runtime()._convergence_total_cycle_seconds(action))
		success_text = ""
	if not static_refresh_key.is_empty() and str(card.get("action_card_static_refresh_key", "")) == static_refresh_key:
		host._app_lifecycle_runtime().set_label_text_if_changed(xp_label, xp_text)
		host._app_lifecycle_runtime().set_label_text_if_changed(stamina_label, stamina_text)
		host._app_lifecycle_runtime().set_label_text_if_changed(time_value_label, time_text)
		host._app_lifecycle_runtime().set_label_text_if_changed(success_label, success_text)
		host._skill_detail_surface()._sync_action_stat_chip_title(xp_label, "XP")
		host._skill_detail_surface()._sync_action_stat_chip_title(stamina_label, "STAM" if show_stamina_stat else "")
		host._skill_detail_surface()._sync_action_stat_chip_title(time_value_label, time_label)
		host._skill_detail_surface()._sync_action_stat_chip_title(success_label, "" if host._convergence_runtime()._is_convergence_action(action) else "RATE")
		host._skill_detail_surface()._sync_activity_lock_overlay(card, action, unlocked)
		ActivityCardStyles.sync_activity_card_title_layer(card, unlocked, host.MODULE_TITLE_OVER_PIN_Z_INDEX)
		var cached_stat_boxes = card.get("stat_boxes", {}) as Dictionary
		_sync_xp_reward_chips(cached_stat_boxes.get("xp") as Control, xp_label, skill_id, action)
		host._skill_detail_surface()._sync_normal_activity_stat_text(card, show_stamina_stat, time_label)
		host._activity_unlock_ceremony_surface().sync_locked_preview_presence(card, skill_id, action)
		return
	if not static_refresh_key.is_empty():
		card["action_card_static_refresh_key"] = static_refresh_key
	var previous_stat_texts := {
		"xp": str(card.get("last_xp_text", "")),
		"stamina": str(card.get("last_stamina_text", "")),
		"time": str(card.get("last_time_text", "")),
		"success": str(card.get("last_success_text", "")),
	}
	var had_previous_stat_text := card.has("last_xp_text")
	var stat_boxes = card.get("stat_boxes", {}) as Dictionary
	var previous_buff_states := {}
	for stat_kind in ["xp", "stamina", "time", "success"]:
		var previous_box := stat_boxes.get(stat_kind) as Control
		previous_buff_states[stat_kind] = previous_box != null and bool(previous_box.get_meta("stat_box_buffed", false))
	host._app_lifecycle_runtime().set_label_text_if_changed(xp_label, xp_text)
	card["last_xp_text"] = xp_text
	host._app_lifecycle_runtime().set_label_text_if_changed(stamina_label, stamina_text)
	card["last_stamina_text"] = stamina_text
	host._app_lifecycle_runtime().set_label_text_if_changed(time_value_label, time_text)
	card["last_time_text"] = time_text
	host._app_lifecycle_runtime().set_label_text_if_changed(success_label, success_text)
	card["last_success_text"] = success_text
	host._skill_detail_surface()._sync_action_stat_chip_title(xp_label, "XP")
	host._skill_detail_surface()._sync_action_stat_chip_title(stamina_label, "STAM" if show_stamina_stat else "")
	host._skill_detail_surface()._sync_action_stat_chip_title(time_value_label, time_label)
	host._skill_detail_surface()._sync_action_stat_chip_title(success_label, "" if host._convergence_runtime()._is_convergence_action(action) else "RATE")
	var stat_theme_color = ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE)
	var current_buff_states := {
		"xp": _action_stat_chip_buffed(skill_id, action, "xp"),
		"stamina": _action_stat_chip_buffed(skill_id, action, "stamina"),
		"time": _action_stat_chip_buffed(skill_id, action, "time"),
		"success": _action_stat_chip_buffed(skill_id, action, "success"),
	}
	_sync_xp_reward_chips(stat_boxes.get("xp") as Control, xp_label, skill_id, action)
	host._skill_detail_surface()._sync_normal_activity_stat_text(card, show_stamina_stat, time_label)
	host._skill_detail_surface()._sync_action_stat_chip_label_style(xp_label, bool(current_buff_states["xp"]), stat_theme_color, stat_boxes.get("xp") as Control)
	host._skill_detail_surface()._sync_action_stat_chip_label_style(stamina_label, bool(current_buff_states["stamina"]), stat_theme_color, stat_boxes.get("stamina") as Control)
	host._skill_detail_surface()._sync_action_stat_chip_label_style(time_value_label, bool(current_buff_states["time"]), stat_theme_color, stat_boxes.get("time") as Control)
	host._skill_detail_surface()._sync_action_stat_chip_label_style(success_label, bool(current_buff_states["success"]), stat_theme_color, stat_boxes.get("success") as Control)
	if had_previous_stat_text:
		var current_stat_texts := {"xp": xp_text, "stamina": stamina_text, "time": time_text, "success": success_text}
		for stat_kind in ["xp", "stamina", "time", "success"]:
			var was_buffed := bool(previous_buff_states[stat_kind])
			var is_buffed := bool(current_buff_states[stat_kind])
			if (was_buffed or is_buffed) and str(previous_stat_texts[stat_kind]) != str(current_stat_texts[stat_kind]):
				host._skill_detail_surface()._wiggle_normal_activity_stat_symbol(stat_boxes.get(stat_kind) as Control)
	var stamina_box = stat_boxes.get("stamina") as Control
	if host._convergence_runtime()._is_convergence_action(action):
		if stamina_box != null:
			stamina_box.visible = false
		var success_box = stat_boxes.get("success") as Control
		if success_box != null:
			success_box.visible = false
	elif host._action_runtime()._is_fishing_event_action(skill_id, action):
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
		host._skill_detail_surface()._sync_convergence_card_static_state(card, action, unlocked)
	ActivityCardStyles.sync_activity_card_title_layer(card, unlocked, host.MODULE_TITLE_OVER_PIN_Z_INDEX)
	var shade = card.get("shade") as Panel
	if shade == null and ((not unlocked) or ceremony_active):
		shade = ActivityCardStyles.ensure_activity_card_shade(card, 0.20)
	if shade != null:
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(shade, (not unlocked) or ceremony_active)
		if not unlocked:
			host._app_lifecycle_runtime().set_canvas_item_modulate_if_changed(shade, Color.WHITE)
		elif not ceremony_active:
			host._app_lifecycle_runtime().set_canvas_item_modulate_if_changed(shade, Color(1, 1, 1, 0))
	if card.get("last_unlocked", null) == unlocked:
		return
	if button != null:
		host._app_lifecycle_runtime().set_base_button_disabled_if_changed(button, lock_blocks_button)
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(button, true)
		host._app_lifecycle_runtime().set_canvas_item_modulate_if_changed(button, Color(1, 1, 1, 0))
	var bg = card.get("bg") as CanvasItem
	if bg != null:
		host._app_lifecycle_runtime().set_canvas_item_modulate_if_changed(bg, Color.WHITE)
	var art_panel = card.get("art_panel") as CanvasItem
	if art_panel != null:
		host._app_lifecycle_runtime().set_canvas_item_modulate_if_changed(art_panel, Color.WHITE)
	var border = card.get("border") as ActivityCardBorder
	if border != null:
		if str(card.get("passive_border_state", "")) != "default":
			card["passive_border_state"] = "default"
			border.border_color = host.COLOR_INK
			border.border_width = ActivityCardStyles.ACTION_CARD_STROKE_WIDTH
			border.queue_redraw()
	card["last_unlocked"] = unlocked
	if host._convergence_runtime()._is_convergence_action(action):
		host._skill_detail_surface()._sync_convergence_card_static_state(card, action, unlocked)
	host._activity_unlock_ceremony_surface().sync_locked_preview_presence(card, skill_id, action)




func _on_action_card_input(event: InputEvent, skill_id: String, action_id: String, source: Control) -> void:
	var card = _action_card_for_input_source(skill_id, action_id, source)
	if card.is_empty():
		return
	var key = str(card.get("card_key", host._action_key(skill_id, action_id)))
	var action = host._action_data(skill_id, action_id)
	if action.is_empty():
		return
	var unlocked = host._activity_unlock_runtime()._is_action_unlocked(skill_id, action)
	if not unlocked or host._skill_detail_surface()._action_info_chips_blocked_by_lock(card):
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var event_positions = host._input_routing_shell()._action_card_event_positions(event, source)
		if not host._input_routing_shell()._positions_inside_detail_actions_viewport(event_positions):
			if not event.pressed and host._skill_detail_surface().action_card_press_key == key:
				host._skill_detail_surface().action_card_press_key = ""
				host._skill_detail_surface().action_card_press_stat_kind = ""
				host._skill_detail_surface().action_card_press_dragged = false
				_release_action_card_3d_press(key)
			return
		if event.pressed:
			var stat_kind = host._skill_detail_surface()._activity_stat_kind_from_positions(card, event_positions)
			if stat_kind.is_empty() and _action_card_medal_hit_from_positions(card, event_positions):
				stat_kind = host.ACTION_CARD_MEDAL_PRESS_KIND
			if not stat_kind.is_empty() and stat_kind != host.ACTION_CARD_MEDAL_PRESS_KIND:
				host._skill_detail_surface()._begin_activity_stat_hold(card, skill_id, action_id, stat_kind, host._input_routing_shell()._first_event_position(event_positions), -1)
				host.get_viewport().set_input_as_handled()
				return
			if stat_kind == host.ACTION_CARD_MEDAL_PRESS_KIND:
				_route_skill_swipe_button_input(event, source)
				host._skill_detail_surface().action_card_press_key = key
				host._skill_detail_surface().action_card_press_position = host._input_routing_shell()._first_event_position(event_positions)
				host._skill_detail_surface().action_card_press_stat_kind = stat_kind
				host._skill_detail_surface().action_card_press_dragged = false
				host.get_viewport().set_input_as_handled()
				return
			host._skill_detail_surface().action_card_press_key = key
			host._skill_detail_surface().action_card_press_position = host._input_routing_shell()._first_event_position(event_positions)
			host._skill_detail_surface().action_card_press_stat_kind = ""
			host._skill_detail_surface().action_card_press_dragged = false
			_queue_action_card_3d_press(key)
			_route_skill_swipe_button_input(event, source)
			host.get_viewport().set_input_as_handled()
		elif host._skill_detail_surface().action_card_press_key == key and not _skill_swipe_suppresses_button_action():
			var stat_kind = host._skill_detail_surface().action_card_press_stat_kind
			var close_to_press = host._input_routing_shell()._event_positions_close_to_press(event_positions)
			if not stat_kind.is_empty():
				close_to_press = host._skill_detail_surface()._event_positions_inside_activity_stat_box(card, stat_kind, event_positions)
			host._skill_detail_surface().action_card_press_key = ""
			host._skill_detail_surface().action_card_press_stat_kind = ""
			_release_action_card_3d_press(key)
			if close_to_press and not host._skill_detail_surface().action_card_press_dragged:
				if BuildableModules.is_buildable(action) and not BuildableModules.is_built(host.built_modules, skill_id, action, Callable(host, "_action_key")):
					host._action_runtime()._start_action_from_card_tap(skill_id, action_id, key)
					_cancel_skill_swipe_feedback(false)
				elif stat_kind == host.ACTION_CARD_MEDAL_PRESS_KIND:
					_play_action_card_medal_tap_ceremony(card)
				else:
					host._action_runtime()._start_action_from_card_tap(skill_id, action_id, key)
					_cancel_skill_swipe_feedback(false)
			host._skill_detail_surface().action_card_press_dragged = false
			host.get_viewport().set_input_as_handled()
		elif host._skill_detail_surface().action_card_press_key == key:
			host._skill_detail_surface().action_card_press_key = ""
			host._skill_detail_surface().action_card_press_stat_kind = ""
			host._skill_detail_surface().action_card_press_dragged = false
			_release_action_card_3d_press(key)
			if skill_swipe_tracking:
				_route_skill_swipe_button_input(event, source)
			host.get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		if skill_swipe_tracking:
			_route_skill_swipe_button_input(event, source)
			host.get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		var event_positions = host._input_routing_shell()._action_card_event_positions(event, source)
		if not host._input_routing_shell()._positions_inside_detail_actions_viewport(event_positions):
			if not event.pressed and host._skill_detail_surface().action_card_press_key == key:
				host._skill_detail_surface().action_card_press_key = ""
				host._skill_detail_surface().action_card_press_stat_kind = ""
				host._skill_detail_surface().action_card_press_dragged = false
				_release_action_card_3d_press(key)
			return
		if event.pressed:
			var stat_kind = host._skill_detail_surface()._activity_stat_kind_from_positions(card, event_positions)
			if stat_kind.is_empty() and _action_card_medal_hit_from_positions(card, event_positions):
				stat_kind = host.ACTION_CARD_MEDAL_PRESS_KIND
			if not stat_kind.is_empty() and stat_kind != host.ACTION_CARD_MEDAL_PRESS_KIND:
				host._skill_detail_surface()._begin_activity_stat_hold(card, skill_id, action_id, stat_kind, host._input_routing_shell()._first_event_position(event_positions), event.index)
				host.get_viewport().set_input_as_handled()
				return
			if stat_kind == host.ACTION_CARD_MEDAL_PRESS_KIND:
				_route_skill_swipe_button_input(event, source)
				host._skill_detail_surface().action_card_press_key = key
				host._skill_detail_surface().action_card_press_position = host._input_routing_shell()._first_event_position(event_positions)
				host._skill_detail_surface().action_card_press_stat_kind = stat_kind
				host._skill_detail_surface().action_card_press_dragged = false
				host.get_viewport().set_input_as_handled()
				return
			host._skill_detail_surface().action_card_press_key = key
			host._skill_detail_surface().action_card_press_position = host._input_routing_shell()._first_event_position(event_positions)
			host._skill_detail_surface().action_card_press_stat_kind = ""
			host._skill_detail_surface().action_card_press_dragged = false
			_queue_action_card_3d_press(key)
			_route_skill_swipe_button_input(event, source)
			host.get_viewport().set_input_as_handled()
		elif host._skill_detail_surface().action_card_press_key == key and not _skill_swipe_suppresses_button_action():
			var stat_kind = host._skill_detail_surface().action_card_press_stat_kind
			var close_to_press = host._input_routing_shell()._event_positions_close_to_press(event_positions)
			if not stat_kind.is_empty():
				close_to_press = host._skill_detail_surface()._event_positions_inside_activity_stat_box(card, stat_kind, event_positions)
			host._skill_detail_surface().action_card_press_key = ""
			host._skill_detail_surface().action_card_press_stat_kind = ""
			_release_action_card_3d_press(key)
			if close_to_press and not host._skill_detail_surface().action_card_press_dragged:
				if BuildableModules.is_buildable(action) and not BuildableModules.is_built(host.built_modules, skill_id, action, Callable(host, "_action_key")):
					host._action_runtime()._start_action_from_card_tap(skill_id, action_id, key)
					_cancel_skill_swipe_feedback(false)
				elif stat_kind == host.ACTION_CARD_MEDAL_PRESS_KIND:
					_play_action_card_medal_tap_ceremony(card)
				else:
					host._action_runtime()._start_action_from_card_tap(skill_id, action_id, key)
					_cancel_skill_swipe_feedback(false)
			host._skill_detail_surface().action_card_press_dragged = false
			host.get_viewport().set_input_as_handled()
		elif host._skill_detail_surface().action_card_press_key == key:
			host._skill_detail_surface().action_card_press_key = ""
			host._skill_detail_surface().action_card_press_stat_kind = ""
			host._skill_detail_surface().action_card_press_dragged = false
			_release_action_card_3d_press(key)
			if skill_swipe_tracking:
				_route_skill_swipe_button_input(event, source)
			host.get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if skill_swipe_tracking:
			_route_skill_swipe_button_input(event, source)
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
	header.add_theme_stylebox_override("panel", host._skill_detail_surface()._skill_detail_shelf_style(skill_id, false))
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(header)

	var header_body = Control.new()
	header_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	header_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(header_body)
	host._skill_detail_surface()._add_skill_detail_shelf_background(header_body, skill_id, content_width)
	state["header_body"] = header_body
	host._skill_detail_surface()._add_activity_back_arrow(header_body, false)

	var xp = SkillState.xp_progress(host.skills, skill_id, SkillState.host_skill_level(host, skill_id))
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
		light_stack.add_child(host._label(SkillState.skill_name(host.skill_defs, skill_id), SkillState.skill_detail_title_font_size(skill_id, host.SKILL_DETAIL_TITLE_FONT_SIZE, host.SKILL_DETAIL_WOODCUTTING_TITLE_FONT_SIZE), host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT))
		var light_xp_label = host._label(SkillState.level_xp_text(host.skills, skill_id, SkillState.host_skill_level(host, skill_id)), host.SKILL_DETAIL_XP_FONT_SIZE, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
		light_stack.add_child(light_xp_label)
		state["xp_label"] = light_xp_label
		var light_xp_bar = ThemeStyles.skill_detail_xp_bar(skill_id, float(xp["pct"]), host.COLOR_BLUE, host.COLOR_INK, host.SKILL_DETAIL_XP_BAR_HEIGHT, host.SKILL_DETAIL_XP_BAR_WIDTH)
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
		title_stack.add_child(host._label(SkillState.skill_name(host.skill_defs, skill_id), SkillState.skill_detail_title_font_size(skill_id, host.SKILL_DETAIL_TITLE_FONT_SIZE, host.SKILL_DETAIL_WOODCUTTING_TITLE_FONT_SIZE), host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT))
		var xp_label = host._label(SkillState.level_xp_text(host.skills, skill_id, SkillState.host_skill_level(host, skill_id)), host.SKILL_DETAIL_XP_FONT_SIZE, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
		title_stack.add_child(xp_label)
		state["xp_label"] = xp_label
		var xp_bar = ThemeStyles.skill_detail_xp_bar(skill_id, float(xp["pct"]), host.COLOR_BLUE, host.COLOR_INK, host.SKILL_DETAIL_XP_BAR_HEIGHT, host.SKILL_DETAIL_XP_BAR_WIDTH)
		title_stack.add_child(xp_bar)
		state["xp_bar"] = xp_bar

		if host._fishing_rework_active_for_skill(skill_id):
			var fish_circle = FishCircle.new()
			fish_circle.custom_minimum_size = Vector2(552, 552)
			fish_circle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			fish_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
			header_row.add_child(fish_circle)
			state["fish_circle"] = fish_circle
			host._fishing_ui_surface()._set_fish_circle_for_skill(fish_circle, skill_id, true)
		else:
			var regen_circle = RegenCircle.new()
			regen_circle.custom_minimum_size = Vector2(552, 552)
			regen_circle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			regen_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
			header_row.add_child(regen_circle)
			state["regen_circle"] = regen_circle
			regen_circle.sync_for_skill(host, skill_id, true)

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
					else host._skill_detail_surface().DETAIL_LAZY_STACK_SEPARATION + entry_height
				)
				preview_entry_y += entry_height + host._skill_detail_surface().DETAIL_LAZY_STACK_SEPARATION
				preview_index += 1
				continue
			pending_placeholder_height = _flush_skill_swipe_preview_placeholder(preview_stack, actions_width, pending_placeholder_height)
			if str(entry_data.get("kind", "")) == "thieving_heist":
				var heist = entry_data.get("heist", {}) as Dictionary
				var heist_root = host._thieving_surface()._build_thieving_heist_card(heist, actions_width, true)
				heist_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
				preview_stack.add_child(heist_root)
				preview_entry_y += entry_height + host._skill_detail_surface().DETAIL_LAZY_STACK_SEPARATION
				preview_index += 1
				continue
			if str(entry_data.get("kind", "")) == "beta_notice":
				preview_stack.add_child(host._skill_detail_surface()._build_beta_notice_board(content_width))
				preview_entry_y += entry_height + host._skill_detail_surface().DETAIL_LAZY_STACK_SEPARATION
				preview_index += 1
				continue
			var action = entry_data.get("action", {}) as Dictionary
			var card_result = host._passive_firepit_surface()._build_passive_module_card(skill_id, action, content_width, false) if host._passive_modules_runtime().is_passive_action(action) else _skill_swipe_preview_action_card(skill_id, action, content_width)
			(card_result["card"] as Dictionary)["preview_only"] = true
			preview_stack.add_child(card_result["root"])
			(state["action_cards"] as Array).append(card_result["card"])
			preview_entry_y += entry_height + host._skill_detail_surface().DETAIL_LAZY_STACK_SEPARATION
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
	_apply_skill_swipe_drag_offset(current_x)
	var active_page := _active_preview_page()
	if active_page != null:
		active_page.position.x = _skill_swipe_preview_rest_x(offset)
		_sync_skill_swipe_preview_page_fade(current_x)

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

func _extract_incoming_swipe_preview(offset: int) -> Dictionary:
	if offset == 0 or skill_swipe_frame == null or not is_instance_valid(skill_swipe_frame):
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
		var scroll = _find_skill_preview_actions_scroll(incoming_page)
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

func _free_swipe_preview_real_card_cache(preview_state: Dictionary) -> void:
	if preview_state.is_empty():
		return
	var cache = preview_state.get("real_card_cache", {}) as Dictionary
	if cache == null or cache.is_empty():
		preview_state.erase("real_card_cache")
		return
	for raw_cached in cache.values():
		var cached = raw_cached as Dictionary
		var root = host._app_lifecycle_runtime().valid_control_ref(cached.get("root"))
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
			var duplicate_root = host._app_lifecycle_runtime().valid_control_ref(cached.get("root"))
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
	if host._passive_modules_runtime().is_passive_action(action):
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
		return host._skill_detail_surface()._visible_detail_entries_for_skill(skill_id)
	var entries := []
	for entry in host._skill_detail_surface()._visible_detail_entries_for_skill(skill_id):
		var entry_data := entry as Dictionary
		if str(entry_data.get("kind", "")) == "thieving_heist":
			continue
		var action := entry_data.get("action", {}) as Dictionary
		if action.is_empty() or not host._activity_unlock_runtime()._is_action_unlocked(skill_id, action):
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
		var root = host._app_lifecycle_runtime().valid_control_ref(cached.get("root"))
		if root == null or root.is_queued_for_deletion():
			continue
		if root.get_parent() != null:
			root.queue_free()
		else:
			root.free()
	cache.clear()

func _free_global_swipe_real_card_cache() -> void:
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
	return false

func _queue_skill_swipe_real_card_cache_prewarm(source_skill_id: String) -> void:
	return

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
	if skill_id.is_empty() or host._skill_detail_surface().detail_lazy_plan.is_empty():
		return
	var cache = real_card_cache_by_skill.get(skill_id, {}) as Dictionary
	if cache == null or cache.is_empty():
		return
	for raw_lazy_entry in host._skill_detail_surface().detail_lazy_plan:
		var lazy_entry = raw_lazy_entry as Dictionary
		var track_id = str(lazy_entry.get("track_id", ""))
		if track_id.is_empty() or not cache.has(track_id) or lazy_entry.has("cached_root"):
			continue
		var cached = cache.get(track_id, {}) as Dictionary
		var root = host._app_lifecycle_runtime().valid_control_ref(cached.get("root"))
		var card = cached.get("card", {}) as Dictionary
		if root == null or root.is_queued_for_deletion() or card.is_empty():
			continue
		lazy_entry["cached_root"] = root
		lazy_entry["cached_card"] = card
		cache.erase(track_id)
	if cache.is_empty():
		real_card_cache_by_skill.erase(skill_id)

func _apply_swipe_preview_real_card_cache_to_lazy_plan(preview_state: Dictionary) -> void:
	if preview_state.is_empty() or host._skill_detail_surface().detail_lazy_plan.is_empty():
		return
	var cache = preview_state.get("real_card_cache", {}) as Dictionary
	if cache == null or cache.is_empty():
		preview_state.erase("real_card_cache")
		return
	for raw_lazy_entry in host._skill_detail_surface().detail_lazy_plan:
		var lazy_entry = raw_lazy_entry as Dictionary
		var track_id = str(lazy_entry.get("track_id", ""))
		if track_id.is_empty() or not cache.has(track_id):
			continue
		var cached = cache.get(track_id, {}) as Dictionary
		var root = host._app_lifecycle_runtime().valid_control_ref(cached.get("root"))
		var card = cached.get("card", {}) as Dictionary
		if root == null or root.is_queued_for_deletion() or card.is_empty():
			continue
		lazy_entry["cached_root"] = root
		lazy_entry["cached_card"] = card
		cache.erase(track_id)
	_free_swipe_preview_real_card_cache({"real_card_cache": cache})
	preview_state.erase("real_card_cache")

func _skill_swipe_prewarm_can_continue(skill_id: String, token: int) -> bool:
	return false

func _finish_skill_swipe_preview_prewarm(token: int) -> void:
	return

func _ensure_skill_swipe_preview_page_cached(offset: int) -> Control:
	if skill_swipe_frame == null or not is_instance_valid(skill_swipe_frame):
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
	skill_swipe_frame.add_child(cached_page)
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
	if str(entry_data.get("kind", "")) == "beta_notice":
		return host._skill_detail_surface().BETA_NOTICE_HEIGHT
	if str(entry_data.get("kind", "")) == "thieving_heist":
		return host._thieving_surface().card_height()
	var action = entry_data.get("action", {}) as Dictionary
	if host._passive_modules_runtime().is_passive_action(action):
		return float(host.PASSIVE_MODULE_CARD_HEIGHT)
	return ActivityCardStyles.root_height_for_action(action, false, false, host.ACTION_CARD_HEIGHT, host.ACTION_CARD_EXPANDED_HEIGHT, host.COMBAT_DIAMOND_ARENA_CARD_HEIGHT, ActivityCardStyles.NORMAL_ACTIVITY_CARD_DEPTH_OFFSET.y)

func _skill_swipe_preview_scroll_y() -> float:
	if host._skill_detail_surface().detail_actions_scroll != null and is_instance_valid(host._skill_detail_surface().detail_actions_scroll):
		return float(host._skill_detail_surface().detail_actions_scroll.scroll_vertical)
	return 0.0

func _skill_swipe_preview_viewport_height() -> float:
	if host._skill_detail_surface().detail_actions_scroll != null and is_instance_valid(host._skill_detail_surface().detail_actions_scroll):
		var viewport_height = host._skill_detail_surface().detail_actions_scroll.size.y
		if viewport_height <= 1.0:
			viewport_height = host._skill_detail_surface().detail_actions_scroll.custom_minimum_size.y
		if viewport_height > 1.0:
			return viewport_height
	return host._skill_detail_surface()._detail_lazy_viewport_height()

func _skill_swipe_preview_should_build_entry(entry_y: float, entry_height: float, preview_index: int) -> bool:
	var scroll_y = _skill_swipe_preview_scroll_y()
	if preview_index < host._skill_detail_surface().DETAIL_LAZY_INITIAL_FORCE_MOUNT_COUNT and scroll_y <= host._skill_detail_surface().DETAIL_LAZY_VIEWPORT_BUFFER_PX:
		return true
	var view_top = scroll_y - host._skill_detail_surface().DETAIL_LAZY_VIEWPORT_BUFFER_PX
	var view_bottom = scroll_y + _skill_swipe_preview_viewport_height() + host._skill_detail_surface().DETAIL_LAZY_VIEWPORT_BUFFER_PX
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
		return SkillState.skill_name(host.skill_defs, skill_id)
	return str(action.get("name", SkillState.skill_name(host.skill_defs, skill_id)))

func _skill_swipe_light_preview_card_style(skill_id: String) -> StyleBoxFlat:
	var key = skill_id
	if light_preview_card_style_cache.has(key):
		return light_preview_card_style_cache[key] as StyleBoxFlat
	var theme = ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE)
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
	if str(entry_data.get("kind", "")) == "beta_notice":
		return {"root": host._skill_detail_surface()._build_beta_notice_board(content_width), "card": {}}
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
			"passive": host._passive_modules_runtime().is_passive_action(action),
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

	var title = host._label(_skill_swipe_light_preview_card_title(skill_id, entry_data), 120, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
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
	var theme = ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE)
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
	var maximum = maxi(1, SkillState.max_stamina(host, skill_id))
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
	var max_label = host._label(str(maximum), 116, Color("#171615"), HORIZONTAL_ALIGNMENT_CENTER)
	max_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(max_label)
	return circle

func _render_light_skill_swipe_preview_entries(stack: VBoxContainer, skill_id: String, content_width: float, actions_width: float, state: Dictionary) -> void:
	var entries = host._skill_detail_surface()._visible_detail_entries_for_skill(skill_id) if skill_id == "thieving" else _preview_detail_entries_for_skill(skill_id)
	if entries.is_empty():
		_add_skill_swipe_preview_placeholder(stack, actions_width, ActivityCardStyles.root_height(false, host.ACTION_CARD_HEIGHT, host.ACTION_CARD_EXPANDED_HEIGHT, host.ACTION_CARD_3D_DEPTH_OFFSET.y))
		return
	var preview_entry_y = 0.0
	var preview_index = 0
	var built_count = 0
	var max_preview_cards = host.SKILL_SWIPE_HIDDEN_PREVIEW_MAX_CARDS
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
				else host._skill_detail_surface().DETAIL_LAZY_STACK_SEPARATION + entry_height
			)
			preview_entry_y += entry_height + host._skill_detail_surface().DETAIL_LAZY_STACK_SEPARATION
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
		preview_entry_y += entry_height + host._skill_detail_surface().DETAIL_LAZY_STACK_SEPARATION
		preview_index += 1
	pending_placeholder_height = _flush_skill_swipe_preview_placeholder(stack, actions_width, pending_placeholder_height)

func _force_show_skill_swipe_preview_modules(offset: int) -> void:
	if not preview_states.has(offset):
		return
	var state = preview_states[offset] as Dictionary
	if state == null:
		return
	_cancel_skill_swipe_preview_modules_reveal(state)
	if not bool(state.get("prewarmed", false)):
		_update_skill_swipe_preview_state(state, 0.0, true)
	var modules_root = state.get("modules_root") as Control
	if modules_root != null and is_instance_valid(modules_root):
		modules_root.visible = true
		modules_root.modulate.a = 1.0


func _cancel_skill_swipe_preview_modules_reveal(preview_state: Dictionary) -> void:
	preview_module_reveal_token += 1
	host._app_lifecycle_runtime()._kill_card_tween(preview_state, "reveal_tween")


func _apply_skill_swipe_commit_release_offset(current_x: float, offset: int) -> void:
	_set_skill_swipe_positions(offset, current_x)




func _update_passive_card_static_state(card: Dictionary, _skill_id: String, action: Dictionary, unlocked: bool) -> void:
	if bool(card.get("firepit", false)):
		_update_firepit_card_static_state(card, _skill_id, action, unlocked)
		return
	host._skill_detail_surface()._sync_module_action_zones_for_card(card, ModuleUiRuntime.action_for_record(_skill_id, action, host.FISHING_ACTION_ID_ALIASES))
	var module_id = str(action.get("id", PassiveModulesRuntime.WOODCUTTING_LOG_MODULE_ID))
	var passive_runtime = host._passive_modules_runtime()
	var now: int = host._unix_now()
	var state = passive_runtime.passive_module_state(module_id, now)
	var ceremony_active = bool(card.get("unlock_ceremony_pending", false)) or bool(card.get("unlock_ceremony_active", false))
	host._skill_detail_surface()._sync_activity_lock_overlay(card, action, unlocked)
	ActivityCardStyles.sync_activity_card_title_layer(card, unlocked, host.MODULE_TITLE_OVER_PIN_Z_INDEX)
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
		if absf(float(border.get("border_width")) - ActivityCardStyles.ACTION_CARD_STROKE_WIDTH) > 0.001:
			border.set("border_width", ActivityCardStyles.ACTION_CARD_STROKE_WIDTH)
			border_dirty = true
		if border_dirty:
			border.queue_redraw()
	var currency_label = card.get("currency") as Label
	if currency_label != null:
		var log_currency: float = host.material_runtime.amount("softwood")
		var currency_text = str(int(floor(log_currency + 0.0001))) if log_currency < 1000 else GameFormatting.compact_number(log_currency)
		var currency_font_size = 96
		if currency_label.get_theme_font_size("font_size") != currency_font_size:
			currency_label.add_theme_font_size_override("font_size", currency_font_size)
		host._app_lifecycle_runtime().set_label_text_if_changed(currency_label, currency_text)
	var plank_button = card.get("plank") as Button
	if plank_button != null:
		plank_button.button_pressed = host.plank_boost_enabled
		plank_button.disabled = (not unlocked) or ceremony_active
		if not plank_button.has_meta("passive_style_active") or bool(plank_button.get_meta("passive_style_active", false)) != host.plank_boost_enabled:
			plank_button.set_meta("passive_style_active", host.plank_boost_enabled)
			plank_button.add_theme_stylebox_override("normal", PassiveModuleStyles.icon_button(host.plank_boost_enabled, false, host.COLOR_INK, host.COLOR_GOLD, Callable(host, "_surface_style")))
			plank_button.add_theme_stylebox_override("hover", PassiveModuleStyles.icon_button(host.plank_boost_enabled, false, host.COLOR_INK, host.COLOR_GOLD, Callable(host, "_surface_style")))
			plank_button.add_theme_stylebox_override("pressed", PassiveModuleStyles.icon_button(true, true, host.COLOR_INK, host.COLOR_GOLD, Callable(host, "_surface_style")))
			plank_button.add_theme_stylebox_override("disabled", PassiveModuleStyles.icon_button(false, false, host.COLOR_INK, host.COLOR_GOLD, Callable(host, "_surface_style")))
	var plank_light = card.get("plank_light") as Panel
	if plank_light != null:
		var light_active = host.plank_boost_enabled and unlocked
		if bool(plank_light.get_meta("passive_light_active", false)) != light_active:
			plank_light.set_meta("passive_light_active", light_active)
			plank_light.add_theme_stylebox_override("panel", PassiveModuleStyles.plank_light(light_active, host.COLOR_INK))
	var stats = card.get("stats", {}) as Dictionary
	host._app_lifecycle_runtime().set_label_text_if_changed(stats.get("time") as Label, GameFormatting.duration(float(state.get("time_seconds", PassiveModulesRuntime.PASSIVE_TIME_START))))
	host._app_lifecycle_runtime().set_label_text_if_changed(stats.get("yield") as Label, "+%s" % int(state.get("yield", PassiveModulesRuntime.PASSIVE_YIELD_START)))
	host._app_lifecycle_runtime().set_label_text_if_changed(stats.get("capacity") as Label, "%s" % int(state.get("capacity", PassiveModulesRuntime.PASSIVE_CAPACITY_START)))
	var upgrade_buttons = card.get("upgrade_buttons", {}) as Dictionary
	for stat_type in ["time", "yield", "capacity"]:
		var upgrade = upgrade_buttons.get(stat_type) as Button
		if upgrade == null:
			continue
		var maxed = passive_runtime.passive_upgrade_maxed(module_id, stat_type, now)
		var cost = passive_runtime.passive_upgrade_cost(module_id, stat_type, now)
		upgrade.visible = not maxed
		upgrade.disabled = (not unlocked) or ceremony_active or maxed or host.material_runtime.amount("softwood") < float(cost)
		upgrade.modulate = Color(1, 1, 1, 0.42) if upgrade.disabled else Color.WHITE
		var cost_label = upgrade.get_meta("cost_label", null) as Label
		if cost_label != null:
			host._app_lifecycle_runtime().set_label_text_if_changed(cost_label, str(cost))
	var progress = card.get("progress") as PassiveModuleStyles.SerpentineProgressBar
	if progress != null:
		var locked_visual = (not unlocked) or ceremony_active
		var progress_theme = ThemeStyles.skill_theme_color("woodcutting", host.COLOR_BLUE)
		var next_unlocked_empty = ThemeStyles.progress_empty_color(progress_theme, host.COLOR_INK)
		var next_shadow = progress.locked_shadow_color if locked_visual else progress.unlocked_shadow_color
		var next_empty = progress.locked_empty_color if locked_visual else next_unlocked_empty
		var next_outline = progress.locked_outline_color if locked_visual else progress.unlocked_outline_color
		var next_fill = progress.locked_empty_color if locked_visual else ThemeStyles.progress_fill_color(progress_theme)
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
		if skill_swipe_pending_full_finalize or _skill_swipe_handoff_cover_is_opaque_cream_transition():
			return
		card.erase("passive_loot_render_deferred")
	host._passive_firepit_surface()._render_passive_loot(card, module_id, unlocked)




func _update_firepit_card_static_state(card: Dictionary, skill_id: String, action: Dictionary, unlocked: bool, instant = false) -> void:
	host._skill_detail_surface()._sync_module_action_zones_for_card(card, ModuleUiRuntime.action_for_record(skill_id, action, host.FISHING_ACTION_ID_ALIASES))
	var module_id = str(action.get("id", PassiveModulesRuntime.WOODCUTTING_FIREPIT_MODULE_ID))
	var passive_runtime = host._passive_modules_runtime()
	var now: int = host._unix_now()
	var state = passive_runtime.firepit_state(now)
	var ceremony_active = bool(card.get("unlock_ceremony_pending", false)) or bool(card.get("unlock_ceremony_active", false))
	host._skill_detail_surface()._sync_activity_lock_overlay(card, action, unlocked)
	ActivityCardStyles.sync_activity_card_title_layer(card, unlocked, host.MODULE_TITLE_OVER_PIN_Z_INDEX)
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
	var active_dim = card.get("active_dim") as Control
	if active_dim != null and active_dim.has_method("set_cover"):
		active_dim.call("set_cover", unlocked and not ceremony_active, active)
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
		if absf(float(border.get("border_width")) - ActivityCardStyles.ACTION_CARD_STROKE_WIDTH) > 0.001:
			border.set("border_width", ActivityCardStyles.ACTION_CARD_STROKE_WIDTH)
			border_dirty = true
		if border_dirty:
			border.queue_redraw()
	var status_label = card.get("status") as Label
	if status_label != null:
		var status_text = passive_runtime.firepit_comfort_text(oeat_tier) if active else "Starting fire" if igniting else "Warmth fading" if cooling else "Fire is out"
		host._app_lifecycle_runtime().set_label_text_if_changed(status_label, status_text)
		status_label.add_theme_color_override("font_color", Color("#ffe27a") if active or cooling or igniting else Color.WHITE)
	var scrapwood_label = card.get("scrapwood_label") as Label
	if scrapwood_label != null:
		host._app_lifecycle_runtime().set_label_text_if_changed(scrapwood_label, host.material_runtime.amount_text_for_host("scrapwood", scrapwood, host))
	var timer_label = card.get("timer") as Label
	if timer_label != null:
		var timer_text = ""
		if active:
			timer_text = "%s left" % GameFormatting.duration(passive_runtime.firepit_seconds_available(scrapwood))
		elif igniting:
			timer_text = "igniting"
		elif cooling:
			timer_text = "cooling"
		host._app_lifecycle_runtime().set_label_text_if_changed(timer_label, timer_text)
		timer_label.visible = not timer_text.is_empty()
	var buff_label = card.get("buff") as Label
	if buff_label != null:
		var buff_text = ""
		if active or cooling:
			buff_text = "+%s%% stamina\nregen boost" % GameFormatting.percent_points(regen_bonus * 100.0)
		host._app_lifecycle_runtime().set_label_text_if_changed(buff_label, buff_text)
		buff_label.visible = active or cooling
	var toggle_button = card.get("toggle") as Button
	if toggle_button != null:
		toggle_button.text = ""
		toggle_button.disabled = (not unlocked) or ceremony_active or igniting or ((not active) and scrapwood < PassiveModulesRuntime.FIREPIT_START_SCRAPWOOD_COST)
		toggle_button.modulate = Color(1, 1, 1, 0.42) if toggle_button.disabled else Color.WHITE
	var flame_fx = card.get("flame_fx") as Control
	if flame_fx != null and flame_fx.has_method("set_active"):
		flame_fx.call("set_active", unlocked and active)
	var progress = card.get("progress") as Control
	if progress != null and progress.has_method("set_target_value") and progress.has_method("set_inner_target_value"):
		var show_bonus_ring = unlocked and (active or cooling)
		var progress_target = passive_runtime.firepit_heat_bonus_progress_pct(now) if show_bonus_ring else 0.0
		progress.call("set_target_value", progress_target, (not unlocked) or ((not active) and (not cooling)) or progress_target + 8.0 < float(progress.get("value")))
		var next_scrapwood_target = passive_runtime.firepit_next_scrapwood_progress_pct(state, now) if (unlocked and active) else 0.0
		var consume_hold_until = int(progress.get_meta("firepit_consume_hold_until_msec", 0))
		if consume_hold_until > Time.get_ticks_msec() and unlocked and active:
			progress.call("set_inner_value", 0.0)
		else:
			if consume_hold_until > 0:
				progress.remove_meta("firepit_consume_hold_until_msec")
			progress.call("set_inner_target_value", next_scrapwood_target, (not unlocked) or (not active) or next_scrapwood_target + 8.0 < float(progress.get("inner_value")))
	var title = card.get("title") as Label
	if title != null:
		title.z_index = ActivityCardStyles.activity_card_title_z_index(unlocked, title, host.MODULE_TITLE_OVER_PIN_Z_INDEX)
	host.passive_modules[module_id] = state




func _skill_swipe_preview_action_card(skill_id: String, action: Dictionary, content_width: float) -> Dictionary:
	var uses_blue_guy_chicken_brawl_stage = host._fighting_runtime().action_uses_blue_guy_chicken_brawl_stage(action)
	var uses_recovery_card := RecoveryModules.has_recovery(action)
	var uses_flat_normal_card := not uses_recovery_card
	var card_depth_offset := ActivityCardStyles.RECOVERY_ACTIVITY_CARD_DEPTH_OFFSET if uses_recovery_card else ActivityCardStyles.NORMAL_ACTIVITY_CARD_DEPTH_OFFSET
	var card_root = Control.new()
	card_root.custom_minimum_size = Vector2(content_width, ActivityCardStyles.root_height_for_action(action, false, false, host.ACTION_CARD_HEIGHT, host.ACTION_CARD_EXPANDED_HEIGHT, host.COMBAT_DIAMOND_ARENA_CARD_HEIGHT, card_depth_offset.y))
	card_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_root.clip_contents = false
	card_root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var pop_card = Control.new()
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
	if uses_flat_normal_card:
		pop_card.set_meta("activity_card_press_offset", ActivityCardStyles.NORMAL_ACTIVITY_CARD_PRESS_OFFSET)
	pop_card.clip_contents = false
	pop_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pop_card.z_index = 1
	var depth = ActivityCardStyles.activity_card_depth_layer(ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE), card_depth_offset, host.ACTION_CARD_FACE_RADIUS, host.ACTION_CARD_POP_GUTTER)
	ThemeStyles.apply_activity_card_depth_action_theme(depth, skill_id, action, Callable(host._activity_unlock_runtime(), "_action_unlock_requirements"), host.COLOR_BLUE)
	_apply_recovery_card_depth_shape(depth, action)
	depth.visible = true
	if uses_flat_normal_card:
		ActivityCardStyles.apply_normal_activity_card_depth(depth, ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE))
	depth.visible = false
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
	var bg = host._skill_detail_surface()._action_card_background(skill_id, action)
	_apply_recovery_card_background_shape(bg, action)
	if uses_flat_normal_card:
		bg.offset_left = 0.0
		bg.offset_right = 0.0
		bg.offset_top = 0.0
		bg.offset_bottom = -card_depth_offset.y
		if bg is RoundedTextureRect:
			(bg as RoundedTextureRect).radius = host.ACTION_CARD_FACE_RADIUS
	pop_card.add_child(bg)
	if uses_flat_normal_card:
		var face_outline := ActivityCardBorder.new()
		face_outline.set_anchors_preset(Control.PRESET_FULL_RECT)
		face_outline.offset_bottom = -card_depth_offset.y
		face_outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		face_outline.z_index = host.ACTION_CARD_FACE_BORDER_Z_INDEX
		face_outline.radius = host.ACTION_CARD_FACE_RADIUS
		face_outline.border_width = ActivityCardStyles.ACTION_CARD_STROKE_WIDTH
		face_outline.border_color = Color("#171615")
		pop_card.add_child(face_outline)
	var blue_guy_chicken_stage: Control = null
	if uses_blue_guy_chicken_brawl_stage:
		blue_guy_chicken_stage = BlueGuyChickenBrawlStageClass.new()
		blue_guy_chicken_stage.set_anchors_preset(Control.PRESET_FULL_RECT)
		blue_guy_chicken_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
		blue_guy_chicken_stage.z_index = 220
		host._fighting_runtime().configure_blue_guy_chicken_brawl_stage(blue_guy_chicken_stage)
		pop_card.add_child(blue_guy_chicken_stage)

	var shade: Panel = null
	if not host._activity_unlock_runtime()._is_action_unlocked(skill_id, action):
		shade = ActivityCardStyles.activity_card_shade_layer(pop_card, 0.20)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 54)
	margin.add_theme_constant_override("margin_right", 122)
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
	art_slot.add_theme_constant_override("margin_top", 140)
	art_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art_panel = Panel.new()
	var art_panel_size := Vector2(382, 382)
	art_panel.custom_minimum_size = art_panel_size
	art_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var art_panel_style := ActivityCardStyles.cached_action_art(Callable(host, "_surface_style"))
	art_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	art_panel.modulate = Color.WHITE
	art_panel.clip_contents = false
	art_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_slot.add_child(art_panel)
	var art_face := ActionArtUi.border_overlay(art_panel_style)
	art_face.name = "ActionArtRaisedFace"
	art_face.z_index = 1
	art_panel.add_child(art_face)
	var art = ActionArtUi.image(action, Callable(host.visual_texture_cache, "_texture_or_visual_fallback"), Callable(host.visual_texture_cache, "_visual_fallback_texture"), DisplayServer.get_name() == "headless")
	art.custom_minimum_size = Vector2(398, 398)
	art.size = Vector2(398, 398)
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

	var copy = VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 18)
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(copy)
	row.add_child(art_slot)

	var action_name_label = host._label(ActivityCardStyles.activity_card_title_text(str(action["name"])), ActivityCardStyles.ACTIVITY_CARD_TITLE_FONT_SIZE, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	ActivityCardStyles.configure_activity_card_title(action_name_label)
	action_name_label.add_theme_color_override("font_outline_color", host.COLOR_INK)
	action_name_label.add_theme_constant_override("outline_size", host.ACTION_CARD_TITLE_OUTLINE_SIZE)
	action_name_label.self_modulate = Color.WHITE
	action_name_label.set_meta("activity_card_locked_title_z_index", 0)
	action_name_label.z_index = ActivityCardStyles.activity_card_title_z_index(host._activity_unlock_runtime()._is_action_unlocked(skill_id, action), action_name_label, host.MODULE_TITLE_OVER_PIN_Z_INDEX)
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

	var stat_row = HBoxContainer.new()
	stat_row.add_theme_constant_override("separation", 18)
	stat_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(stat_row)
	var skill_detail_surface = host._skill_detail_surface()
	var xp_label = skill_detail_surface._action_stat_label("")
	var stamina_label = skill_detail_surface._action_stat_label("")
	var time_label = skill_detail_surface._action_stat_label("")
	var success_label = skill_detail_surface._action_stat_label("")
	var xp_box: Control = null
	var stamina_box: Control = null
	var time_box: Control = null
	var success_box: Control = null
	var normal_stat_top: Label = null
	var normal_stat_bottom: Label = null
	if uses_flat_normal_card or uses_recovery_card:
		var normal_stat_panel: PanelContainer = skill_detail_surface._normal_activity_stat_panel(Vector2(880, 272), ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE))
		var normal_stat_items := GridContainer.new()
		normal_stat_items.columns = 2
		normal_stat_items.add_theme_constant_override("h_separation", 0)
		normal_stat_items.add_theme_constant_override("v_separation", 0)
		normal_stat_items.mouse_filter = Control.MOUSE_FILTER_IGNORE
		xp_box = skill_detail_surface._normal_activity_stat_item(xp_label, "xp")
		stamina_box = skill_detail_surface._normal_activity_stat_item(stamina_label, "stamina")
		time_box = skill_detail_surface._normal_activity_stat_item(time_label, "time")
		success_box = skill_detail_surface._normal_activity_stat_item(success_label, "success")
		normal_stat_items.add_child(xp_box)
		normal_stat_items.add_child(time_box)
		normal_stat_items.add_child(stamina_box)
		normal_stat_items.add_child(success_box)
		normal_stat_panel.add_child(normal_stat_items)
		stat_row.add_child(normal_stat_panel)
	else:
		xp_box = skill_detail_surface._action_stat_box(xp_label)
		stat_row.add_child(xp_box)
		stamina_box = skill_detail_surface._action_stat_box(stamina_label)
		stat_row.add_child(stamina_box)
		time_box = skill_detail_surface._action_stat_box(time_label)
		stat_row.add_child(time_box)
		success_box = skill_detail_surface._action_stat_box(success_label)
		stat_row.add_child(success_box)

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
		medal.texture = _action_card_medal_texture_for_level(0)
		medal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		medal.z_index = host.ACTION_CARD_FACE_BORDER_Z_INDEX + 1
		art_panel.add_child(medal)
		mastery_progress = ThemeStyles.progress_bar(Color("#f4bf35"), 56)
		mastery_progress.border_color = host.COLOR_INK
		ThemeStyles.apply_mastery_progress_bar_theme(mastery_progress, ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE), host.COLOR_INK)
		mastery_progress.easing_speed = 5.0
		mastery_progress.z_index = 20
		copy.add_child(mastery_progress)
		mastery_progress.visible = false

	var progress: ActivityProgressRail = null
	var fluid_strip: Control = null
	if host._fishing_rework_active_for_skill(skill_id) and not host.fishing_runtime.action_should_render_standalone(host, skill_id, action):
		fluid_strip = host._fishing_ui_surface()._attach_fishing_fluid_strip(pop_card, action)
	elif not uses_blue_guy_chicken_brawl_stage:
		progress = ActivityProgressRail.new()
		progress.visible = true
		ThemeStyles.apply_activity_progress_rail_action_theme(progress, ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE), ThemeStyles.combo_progress_segment_theme_colors(skill_id, action, Callable(host._activity_unlock_runtime(), "_action_unlock_requirements"), host.COLOR_BLUE), host.COLOR_INK)
		progress.anchor_left = 0.0
		progress.anchor_right = 1.0
		progress.anchor_top = 1.0
		progress.anchor_bottom = 1.0
		progress.offset_left = 0.0
		progress.offset_right = 0.0
		var normal_progress_height := 112.0
		var normal_progress_bottom_margin := 0.0
		progress.offset_top = -host.ACTION_PROGRESS_RAIL_HEIGHT if RecoveryModules.has_recovery(action) else -ActivityCardStyles.NORMAL_ACTIVITY_CARD_DEPTH_OFFSET.y - normal_progress_bottom_margin - normal_progress_height
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

	var border: ActivityCardBorder = null
	if host.ACTION_CARD_FACE_BORDER_ENABLED and RecoveryModules.has_recovery(action):
		border = ActivityCardBorder.new()
		border.set_anchors_preset(Control.PRESET_FULL_RECT)
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		border.z_index = host.ACTION_CARD_FACE_BORDER_Z_INDEX
		border.bottom_shape = "wide_u"
		border.wide_u_bottom_rise = RECOVERY_WIDE_U_BOTTOM_RISE
		border.wide_u_shoulder_ratio = RECOVERY_WIDE_U_SHOULDER_RATIO
		pop_card.add_child(border)
	var action_id = str(action.get("id", ""))
	var lock_overlay = host._skill_detail_surface()._activity_lock_overlay(pop_card, int(action.get("unlock", 1)), skill_id, host._skill_detail_surface()._lock_requirements_for_overlay(skill_id, action)) if not host._activity_unlock_runtime()._is_action_unlocked(skill_id, action) else {}
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
		"normal_stat_top": normal_stat_top,
		"normal_stat_bottom": normal_stat_bottom,
		"status": null,
		"medal": medal,
		"mastery": mastery_progress,
		"mastery_ring": mastery_ring,
		"progress": progress,
		"stat_row": stat_row,
		"stat_boxes": {
			"xp": xp_box,
			"stamina": stamina_box,
			"time": time_box,
			"success": success_box,
		},
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
	host._skill_detail_surface()._hold_skill_detail_layout_refresh(host.ACTIVITY_PREVIEW_FADE_IN_SECONDS + 0.18)
	var root = host._app_lifecycle_runtime().valid_control_ref(card.get("root"))
	if root == null or root.is_queued_for_deletion():
		return
	host._app_lifecycle_runtime()._kill_card_tween(card, "preview_fade_tween")
	var pop = host._app_lifecycle_runtime().valid_control_ref(card.get("pop"))
	var expand_from_zero = card.has("preview_enter_target_height")
	var smooth_unlock_reveal = bool(card.get("unlock_next_preview_smooth", false))
	var stable_preview_fade = bool(card.get("stable_preview_fade", false))
	var target_height = float(card.get("preview_enter_target_height", root.custom_minimum_size.y))
	var unlock_ceremony_surface = host._activity_unlock_ceremony_surface()
	var entry_target_height = float(card.get("preview_enter_entry_target_height", unlock_ceremony_surface.activity_preview_entry_height(card, root, target_height)))
	var skill_id = str(card.get("skill_id", host.selected_skill_id))
	var action = card.get("action", {}) as Dictionary
	var action_id = str(action.get("id", card.get("action_id", "")))
	var card_key = str(card.get("card_key", host._action_key(skill_id, action_id)))
	var lock_overlay = card.get("lock_overlay", {}) as Dictionary
	var lock_rig = host._app_lifecycle_runtime().state_object_ref(lock_overlay.get("group"))
	var show_lock_fade = (
		lock_rig != null
		and not action.is_empty()
		and not host._activity_unlock_runtime()._is_action_unlocked(skill_id, action)
	)
	var show_onboarding_level_up_tip = (
		host._onboarding_runtime()._onboarding_path_active()
		and skill_id == host.TUTORIAL_STARTER_SKILL_ID
		and not action.is_empty()
		and str(action.get("id", "")) == host._activity_unlock_runtime()._first_locked_action_id(skill_id)
		and int(action.get("unlock", 0)) == 2
		and SkillState.host_skill_level(host, skill_id) < 2
		and bool(card.get("unlock_next_preview_smooth", false))
	)
	if host._onboarding_runtime()._should_release_onboarding_first_module_centering_for_preview(skill_id, action):
		host._onboarding_runtime()._release_onboarding_first_module_centering()
	var tutorial_surface = host._tutorial_overlay_surface()
	if show_onboarding_level_up_tip:
		tutorial_surface.fade_out_onboarding_mastery_tip(host.ACTIVITY_PREVIEW_FADE_IN_SECONDS)
		tutorial_surface.fade_out_onboarding_medal_tip(host.ACTIVITY_PREVIEW_FADE_IN_SECONDS)
	if show_lock_fade:
		host._skill_detail_surface()._set_activity_lock_overlay_active(lock_overlay, true)
		host._app_lifecycle_runtime().set_canvas_item_modulate_if_changed(lock_rig, Color(1, 1, 1, 0))
		lock_rig.reset_unlock_drop_animation()
		if lock_rig.has_method("_layout_base"):
			lock_rig.call("_layout_base")
	var scroll_preserve_context = {}
	var skill_detail_surface = host._skill_detail_surface()
	host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(root, true)
	host._app_lifecycle_runtime().set_canvas_item_modulate_if_changed(root, Color(1, 1, 1, 0))
	if expand_from_zero:
		scroll_preserve_context = skill_detail_surface._detail_scroll_height_change_preserve_context(root)
		host._app_lifecycle_runtime().set_control_minimum_height(root, 0.0)
		unlock_ceremony_surface.set_activity_preview_entry_height(card, root, 0.0)
		root.clip_contents = true
		if not scroll_preserve_context.is_empty():
			skill_detail_surface._apply_detail_scroll_height_change_preserve_context(0.0, scroll_preserve_context)
	if pop != null:
		unlock_ceremony_surface.set_preview_pop_vertical_offset(pop, 0.0 if stable_preview_fade else ActivityUnlockCeremonySurface.NEXT_PREVIEW_SETTLE_OFFSET if smooth_unlock_reveal else 34.0)
	var tween = host.create_tween()
	card["preview_fade_tween"] = tween
	tween.set_parallel(true)
	var root_id = root.get_instance_id()
	tween.tween_method(
		Callable(host._app_lifecycle_runtime(), "set_canvas_item_alpha_safe").bind(root_id),
		0.0,
		1.0,
		host.ACTIVITY_PREVIEW_FADE_IN_SECONDS
	).set_trans(Tween.TRANS_SINE if smooth_unlock_reveal else Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if show_lock_fade:
		var lock_rig_fade_id = lock_rig.get_instance_id()
		tween.tween_method(
			Callable(host._app_lifecycle_runtime(), "set_canvas_item_alpha_safe").bind(lock_rig_fade_id),
			0.0,
			1.0,
			host.ACTIVITY_PREVIEW_FADE_IN_SECONDS
		).set_trans(Tween.TRANS_SINE if smooth_unlock_reveal else Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if expand_from_zero:
		tween.tween_method(
			Callable(host._app_lifecycle_runtime(), "set_control_minimum_height_safe").bind(root_id),
			0.0,
			target_height,
			host.ACTIVITY_PREVIEW_FADE_IN_SECONDS
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if not scroll_preserve_context.is_empty():
			tween.tween_method(
				Callable(skill_detail_surface, "_apply_detail_scroll_height_change_preserve_context").bind(scroll_preserve_context),
				0.0,
				1.0,
				host.ACTIVITY_PREVIEW_FADE_IN_SECONDS
			).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
		var entry = unlock_ceremony_surface.activity_preview_entry_control(card, root)
		if entry != null:
			var entry_id = entry.get_instance_id()
			tween.tween_method(
				Callable(host._app_lifecycle_runtime(), "set_control_minimum_height_safe").bind(entry_id),
				0.0,
				entry_target_height,
				host.ACTIVITY_PREVIEW_FADE_IN_SECONDS
			).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if pop != null:
		var start_offset = 0.0 if stable_preview_fade else ActivityUnlockCeremonySurface.NEXT_PREVIEW_SETTLE_OFFSET if smooth_unlock_reveal else 34.0
		var pop_offset_id = pop.get_instance_id()
		tween.tween_method(
			Callable(unlock_ceremony_surface, "set_preview_pop_vertical_offset_safe").bind(pop_offset_id),
			start_offset,
			0.0,
			host.ACTIVITY_PREVIEW_FADE_IN_SECONDS
		).set_trans(Tween.TRANS_QUINT if smooth_unlock_reveal else Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var level_up_tip: Control = null
	if show_onboarding_level_up_tip:
		level_up_tip = tutorial_surface.ensure_onboarding_level_up_tip(card)
		if level_up_tip != null and is_instance_valid(level_up_tip):
			level_up_tip.modulate.a = 0.0
			tutorial_surface.sync_onboarding_level_up_tip_position(card)
			tween.tween_property(level_up_tip, "modulate:a", 1.0, host.ACTIVITY_PREVIEW_FADE_IN_SECONDS).set_trans(Tween.TRANS_SINE if smooth_unlock_reveal else Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_method(
				Callable(tutorial_surface, "sync_onboarding_level_up_tip_position_by_key").bind(card_key),
				0.0,
				1.0,
				host.ACTIVITY_PREVIEW_FADE_IN_SECONDS
			)
	var pop_id = pop.get_instance_id() if pop != null else 0
	var lock_rig_id = lock_rig.get_instance_id() if lock_rig != null else 0
	tween.finished.connect(Callable(unlock_ceremony_surface, "finish_activity_preview_fade_in").bind(card_key, root_id, pop_id, lock_rig_id, expand_from_zero, target_height, skill_id, action_id))




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
		var normal_depth := Panel.new()
		normal_depth.name = "ActivityButtonDepth"
		normal_depth.set_anchors_preset(Control.PRESET_FULL_RECT)
		normal_depth.offset_left = gutter
		normal_depth.offset_right = -gutter
		normal_depth.offset_top = depth_offset.y
		normal_depth.mouse_filter = Control.MOUSE_FILTER_IGNORE
		normal_depth.z_index = 0
		normal_depth.add_theme_stylebox_override("panel", ActivityCardStyles.normal_activity_card_bottom_base(radius, host.COLOR_INK, fill))
		depth = normal_depth
	else:
		var shaped_depth = ActivityCardStyles.prism_connector_overlay(depth_offset, radius, diagonal_side, 12.0, host.COLOR_INK)
		shaped_depth.name = "ActivityButtonDepth"
		shaped_depth.face_gutter = gutter
		shaped_depth.face_bottom_inset = depth_offset.y
		shaped_depth.side_fill_color = fill.darkened(0.42)
		shaped_depth.bottom_fill_color = shaped_depth.side_fill_color
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
		var shaped_face = ActivityCardStyles.page_switch_button_face()
		shaped_face.side = diagonal_side
		shaped_face.fill_color = fill
		shaped_face.ink_color = host.COLOR_INK
		shaped_face.radius = radius
		shaped_face.stroke_width = 12.0
		shaped_face.draw_stroke = absf(depth_offset.x) <= 0.01
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
		activity_border.anti_aliasing = false
		activity_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		activity_border.z_index = host.ACTION_CARD_FACE_BORDER_Z_INDEX
		pop.add_child(activity_border)
		border = activity_border
	button.set_meta("activity_button_pop_id", pop.get_instance_id())
	button.set_meta("activity_button_depth_id", depth.get_instance_id())
	button.set_meta("activity_button_face_id", face.get_instance_id())
	button.set_meta("activity_button_border_id", border.get_instance_id() if border != null else 0)
	button.set_meta("activity_button_radius", radius)
	button.set_meta("activity_button_diagonal_side", diagonal_side)
	button.set_meta("activity_button_depth_offset", depth_offset)
	_set_activity_button_shell_theme(button, fill, false)
	return pop


func _activity_button_target_face_global_rect(button: Button, active: bool) -> Rect2:
	if button == null or not is_instance_valid(button):
		return Rect2()
	var face_rect = button.get_global_rect()
	var pop = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(int(button.get_meta("activity_button_pop_id", 0)))) as Control
	if pop != null:
		face_rect = pop.get_global_rect()
		var current_offset = _activity_button_pop_depth_offset(pop)
		var target_offset: Vector2 = host._app_lifecycle_runtime().meta_vector2(button, "activity_button_depth_offset", host.ACTION_CARD_3D_DEPTH_OFFSET) if active else Vector2.ZERO
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
		and depressed_activity_shell_buttons.has(button.get_instance_id())
		and button.has_meta("activity_button_hold_nav_target_active")
	):
		var pressed_pending_target_active = bool(button.get_meta("activity_button_hold_nav_target_active", false))
		if pressed_pending_target_active == active:
			button.set_meta("activity_button_shell_fill", fill)
			button.set_meta("activity_button_shell_active", active)
		return
	if button.has_meta("activity_button_hold_nav_press") and not depressed_activity_shell_buttons.has(button.get_instance_id()):
		var early_has_pending_nav_target = button.has_meta("activity_button_hold_nav_target_active")
		var early_pending_target_active = bool(button.get_meta("activity_button_hold_nav_target_active", false))
		if early_has_pending_nav_target and early_pending_target_active != active:
			return
	button.set_meta("activity_button_shell_fill", fill)
	button.set_meta("activity_button_shell_active", active)
	var outline_color: Color = host.COLOR_INK
	var depth_control: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(int(button.get_meta("activity_button_depth_id", 0))))
	var depth = depth_control as ActivityCardDepth
	if depth != null:
		depth.back_color = fill.darkened(0.42)
		depth.side_color = depth.back_color
		depth.bottom_color = depth.back_color
		depth.draw_back_plate_bottom_outline = false
		depth.queue_redraw()
	elif depth_control is Panel:
		var normal_depth := depth_control as Panel
		var depth_radius := float(button.get_meta("activity_button_radius", host.ACTION_CARD_FACE_RADIUS))
		normal_depth.add_theme_stylebox_override("panel", ActivityCardStyles.normal_activity_card_bottom_base(depth_radius, host.COLOR_INK, fill))
	elif ActivityCardStyles.is_page_switch_button_face(depth_control):
		var shaped_depth = depth_control
		shaped_depth.fill_color = fill.darkened(0.42)
		shaped_depth.ink_color = host.COLOR_INK
		shaped_depth.queue_redraw()
	elif ActivityCardStyles.is_prism_connector_overlay(depth_control):
		var prism_depth = depth_control
		prism_depth.side_fill_color = fill.darkened(0.42)
		prism_depth.bottom_fill_color = prism_depth.side_fill_color
		prism_depth.ink_color = host.COLOR_INK
		prism_depth.queue_redraw()
	var face: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(int(button.get_meta("activity_button_face_id", 0))))
	if face != null:
		var radius: float = host.ACTION_CARD_FACE_RADIUS
		var border = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(int(button.get_meta("activity_button_border_id", 0)))) as ActivityCardBorder
		if border != null:
			radius = border.radius
		if face is Panel:
			(face as Panel).add_theme_stylebox_override("panel", ActivityCardStyles.button_face(fill, radius))
		elif ActivityCardStyles.is_page_switch_button_face(face):
			var shaped_face = face
			shaped_face.fill_color = fill
			shaped_face.ink_color = outline_color
			shaped_face.queue_redraw()
	var outline = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(int(button.get_meta("activity_button_border_id", 0)))) as ActivityCardBorder
	if outline != null:
		outline.border_color = outline_color
		outline.queue_redraw()
	var suppress_state_tween = bool(button.get_meta("activity_button_suppress_next_state_tween", false))
	if suppress_state_tween:
		button.remove_meta("activity_button_suppress_next_state_tween")
	var waiting_for_nav_target = false
	if button.has_meta("activity_button_hold_nav_press") and not depressed_activity_shell_buttons.has(button.get_instance_id()):
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
		return host._app_lifecycle_runtime().meta_vector2(button, "activity_button_depth_offset", host.ACTION_CARD_3D_DEPTH_OFFSET)
	return Vector2.ZERO


func _snap_activity_button_shell_to_state(button: Button) -> void:
	if button == null or not is_instance_valid(button):
		return
	var pop = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(int(button.get_meta("activity_button_pop_id", 0)))) as Control
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


func _activity_button_arrow(button: Button) -> Control:
	if button == null or not is_instance_valid(button):
		return null
	var direct_arrow := button.get_node_or_null("ActivityButtonArrow") as Control
	if direct_arrow != null:
		return direct_arrow
	var pop = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(int(button.get_meta("activity_button_pop_id", 0)))) as Control
	if pop == null:
		return null
	return pop.get_node_or_null("ActivityButtonArrow") as Control


func _activity_button_pop_depth_offset(pop: Control) -> Vector2:
	if pop == null or not is_instance_valid(pop):
		return Vector2.ZERO
	var gutter = float(pop.get_meta("activity_button_gutter", host.ACTION_CARD_POP_GUTTER))
	return Vector2(pop.offset_left - gutter, pop.offset_top)


func _set_activity_button_pop_depth_offset_bound(offset: Vector2, pop_id: int) -> void:
	var pop: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(pop_id))
	if pop == null:
		return
	var gutter = float(pop.get_meta("activity_button_gutter", host.ACTION_CARD_POP_GUTTER))
	var bottom_inset = float(pop.get_meta("activity_button_depth_bottom_inset", host.ACTION_CARD_3D_DEPTH_OFFSET.y))
	pop.offset_left = gutter + offset.x
	pop.offset_right = -gutter + offset.x
	pop.offset_top = offset.y
	pop.offset_bottom = -bottom_inset + offset.y
	ActivityCardStyles.set_activity_card_depth_face_offset_from_pop(pop, offset, host.ACTION_CARD_POP_GUTTER, bottom_inset)


func _activity_card_pop_depth_offset(pop: Control) -> Vector2:
	if pop == null or not is_instance_valid(pop):
		return Vector2.ZERO
	var base_left := float(pop.get_meta("activity_card_base_offset_left", host.ACTION_CARD_POP_GUTTER))
	return Vector2(pop.offset_left - base_left, pop.offset_top)


func _set_activity_card_pop_depth_offset_bound(offset: Vector2, pop_id: int) -> void:
	var pop: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(pop_id))
	if pop == null:
		return
	var base_left := float(pop.get_meta("activity_card_base_offset_left", host.ACTION_CARD_POP_GUTTER))
	var base_right := float(pop.get_meta("activity_card_base_offset_right", -host.ACTION_CARD_POP_GUTTER))
	pop.offset_left = base_left + offset.x
	pop.offset_right = base_right + offset.x
	pop.offset_top = offset.y
	pop.offset_bottom = ActivityCardStyles.activity_card_pop_base_bottom_offset(pop) + offset.y
	ActivityCardStyles.set_activity_card_depth_face_offset_from_pop(pop, offset, host.ACTION_CARD_POP_GUTTER, host.ACTION_CARD_3D_DEPTH_OFFSET.y)


func _action_card_supports_3d_press(card: Dictionary) -> bool:
	if card.is_empty():
		return false
	var pop: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("pop"))
	var depth: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("depth"))
	return pop != null and depth != null


func _action_card_press_offset(card: Dictionary) -> Vector2:
	var pop: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("pop"))
	if pop != null and pop.has_meta("activity_card_press_offset"):
		return pop.get_meta("activity_card_press_offset") as Vector2
	return host.ACTION_CARD_3D_PRESS_OFFSET


func _queue_action_card_3d_press(action_key: String) -> void:
	if action_key.is_empty() or not host.action_cards.has(action_key):
		return
	_cancel_pending_action_card_3d_press()
	host._skill_detail_surface().action_card_press_visual_token += 1
	host._skill_detail_surface().action_card_press_visual_pending_key = action_key
	_apply_action_card_3d_press_after_delay(action_key, host._skill_detail_surface().action_card_press_visual_token)


func _cancel_pending_action_card_3d_press() -> void:
	if host._skill_detail_surface().action_card_press_visual_pending_key.is_empty():
		return
	host._skill_detail_surface().action_card_press_visual_token += 1
	host._skill_detail_surface().action_card_press_visual_pending_key = ""


func _apply_action_card_3d_press_after_delay(action_key: String, visual_token: int) -> void:
	if host.ACTION_CARD_3D_PRESS_FEEDBACK_DELAY_SECONDS > 0.0:
		await host.get_tree().create_timer(host.ACTION_CARD_3D_PRESS_FEEDBACK_DELAY_SECONDS).timeout
	if visual_token != host._skill_detail_surface().action_card_press_visual_token:
		return
	host._skill_detail_surface().action_card_press_visual_pending_key = ""
	if host._skill_detail_surface().action_card_press_key != action_key or host._skill_detail_surface().action_card_press_dragged or not host._skill_detail_surface().action_card_press_stat_kind.is_empty():
		return
	if host._skill_detail_surface()._detail_actions_scroll_suppresses_child_click():
		return
	_press_action_card_3d(action_key)


func _press_action_card_3d(action_key: String) -> void:
	if action_key.is_empty() or not host.action_cards.has(action_key):
		return
	var card := host.action_cards[action_key] as Dictionary
	if not _action_card_supports_3d_press(card):
		return
	card["card_3d_pressed"] = true
	_animate_action_card_depth_to(card, _action_card_press_offset(card), host.ACTION_CARD_3D_PRESS_SECONDS, Tween.TRANS_QUAD, Tween.EASE_OUT)


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
		var fallback_pop: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("pop"))
		if fallback_pop != null:
			_animate_activity_press_effect(fallback_pop, action_key, 0.982)
		return
	var pop: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("pop"))
	if pop == null:
		host._skill_detail_surface()._discard_action_card_key(action_key)
		return
	var current := _activity_card_pop_depth_offset(pop)
	host._app_lifecycle_runtime()._kill_card_tween(card, "depth_press_tween")
	var pop_id := pop.get_instance_id()
	var tween: Tween = host.create_tween()
	card["depth_press_tween"] = tween
	var setter := Callable(self, "_set_activity_card_pop_depth_offset_bound").bind(pop_id)
	var press_offset := _action_card_press_offset(card)
	tween.tween_method(setter, current, press_offset, host.ACTION_CARD_3D_PRESS_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_interval(host.ACTION_CARD_3D_PRESS_HOLD_SECONDS)
	tween.tween_method(setter, press_offset, Vector2.ZERO, host.ACTION_CARD_3D_RELEASE_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_finish_action_card_3d_click.bind(action_key, pop_id))


func _pop_activity_button(action_key: String) -> void:
	if not host.action_cards.has(action_key):
		return
	var card := host.action_cards[action_key] as Dictionary
	if action_key.begins_with("thieving_heist:"):
		var heist_button: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("button"))
		if heist_button != null:
			_animate_activity_press_effect(heist_button, "%s:button" % action_key, 0.965)
		return
	var pop: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("pop"))
	if pop != null:
		_animate_action_card_3d_click(action_key)
		return
	if card.get("is_fishing_method"):
		var art_panel: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("art_panel"))
		if art_panel != null:
			_animate_activity_press_effect(art_panel, action_key, 0.982)


func _press_activity_stat_box(action_key: String, stat_kind: String) -> void:
	if not host.action_cards.has(action_key):
		return
	var card := host.action_cards[action_key] as Dictionary
	var boxes := card.get("stat_boxes", {}) as Dictionary
	var box := boxes.get(stat_kind) as Control
	if box == null:
		return
	_animate_activity_press_effect(box, "%s:stat:%s" % [action_key, stat_kind], 0.94)


func _animate_activity_press_effect(control: Control, tween_key: String, pressed_scale: float) -> void:
	if control == null or not is_instance_valid(control):
		return
	if action_pop_tweens.has(tween_key):
		host._app_lifecycle_runtime()._kill_tween_value(action_pop_tweens[tween_key])
	control.scale = Vector2.ONE
	control.pivot_offset = control.size * 0.5
	var tween: Tween = host.create_tween()
	action_pop_tweens[tween_key] = tween
	tween.tween_property(control, "scale", Vector2(pressed_scale, pressed_scale), 0.055).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_finish_activity_press_effect.bind(tween_key, tween))


func _finish_activity_press_effect(tween_key: String, tween: Tween) -> void:
	if action_pop_tweens.get(tween_key) == tween:
		action_pop_tweens.erase(tween_key)


func _clear_action_pop_tweens() -> void:
	for tween in action_pop_tweens.values():
		host._app_lifecycle_runtime()._kill_tween_value(tween)
	action_pop_tweens.clear()


func _finish_action_card_3d_click(action_key: String, pop_id: int) -> void:
	var card := host.action_cards.get(action_key, {}) as Dictionary
	if not card.is_empty():
		card.erase("depth_press_tween")
	_set_activity_card_pop_depth_offset_bound(Vector2.ZERO, pop_id)


func _animate_action_card_depth_to(card: Dictionary, target_offset: Vector2, seconds: float, transition: Tween.TransitionType, ease_type: Tween.EaseType) -> void:
	if not _action_card_supports_3d_press(card):
		return
	var pop: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("pop"))
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
	host.button_press_runtime.attach_default_button_sfx(button)
	var button_id = button.get_instance_id()
	var down_callable = Callable(self, "_press_activity_button_shell_bound").bind(button_id)
	if not button.button_down.is_connected(down_callable):
		button.button_down.connect(down_callable)
	var up_callable = Callable(self, "_release_activity_button_shell_bound").bind(button_id)
	if not button.button_up.is_connected(up_callable):
		button.button_up.connect(up_callable)


func _press_activity_button_shell_bound(button_id: int) -> void:
	var button: Button = host._app_lifecycle_runtime().valid_button_ref(instance_from_id(button_id))
	if button == null or button.disabled:
		return
	var navigation_shell = host._navigation_shell()
	if navigation_shell._is_module_utility_nav_button(button):
		navigation_shell._prime_module_utility_nav_button_press_state(button)
	if depressed_activity_shell_buttons.has(button_id):
		return
	depressed_activity_shell_buttons[button_id] = button
	var depth_offset: Vector2 = host._app_lifecycle_runtime().meta_vector2(button, "activity_button_depth_offset", host.ACTION_CARD_3D_DEPTH_OFFSET)
	var pop = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(int(button.get_meta("activity_button_pop_id", 0)))) as Control
	if pop != null and _activity_button_pop_depth_offset(pop).distance_squared_to(depth_offset) <= 0.25:
		return
	_animate_activity_button_shell_to(button, depth_offset, host.ACTION_CARD_3D_PRESS_SECONDS, Tween.TRANS_QUAD, Tween.EASE_OUT)


func _release_activity_button_shell_bound(button_id: int, force_visual_release := false) -> void:
	var button: Button = host._app_lifecycle_runtime().valid_button_ref(instance_from_id(button_id))
	if button == null:
		return
	if not force_visual_release and host._navigation_shell()._page_switch_button_shell_release_preserved(button):
		_hold_activity_button_shell_at_depth(button)
		return
	var was_depressed: bool = depressed_activity_shell_buttons.has(button_id)
	depressed_activity_shell_buttons.erase(button_id)
	var target_offset = Vector2.ZERO
	var target_active = bool(button.get_meta("activity_button_shell_active", false))
	if target_active:
		target_offset = host._app_lifecycle_runtime().meta_vector2(button, "activity_button_depth_offset", host.ACTION_CARD_3D_DEPTH_OFFSET)
	var pop = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(int(button.get_meta("activity_button_pop_id", 0)))) as Control
	if bool(button.get_meta("activity_button_hold_nav_press", false)):
		var has_pending_nav_target: bool = button.has_meta("activity_button_hold_nav_target_active")
		var pending_target_active = bool(button.get_meta("activity_button_hold_nav_target_active", false))
		if has_pending_nav_target and pending_target_active == target_active:
			button.remove_meta("activity_button_hold_nav_press")
			button.remove_meta("activity_button_hold_nav_target_active")
		else:
			var depth_offset: Vector2 = host._app_lifecycle_runtime().meta_vector2(button, "activity_button_depth_offset", host.ACTION_CARD_3D_DEPTH_OFFSET)
			_kill_activity_button_shell_tween(button)
			if pop != null:
				_set_activity_button_pop_depth_offset_bound(depth_offset, pop.get_instance_id())
			return
	if not was_depressed and pop != null and _activity_button_pop_depth_offset(pop).distance_squared_to(target_offset) <= 0.25:
		return
	_animate_activity_button_shell_to(button, target_offset, host.ACTION_CARD_3D_RELEASE_SECONDS, Tween.TRANS_BACK, Tween.EASE_OUT)


func has_depressed_activity_shell_button(button_id: int) -> bool:
	return depressed_activity_shell_buttons.has(button_id)


func forget_depressed_activity_shell_button(button_id: int) -> void:
	depressed_activity_shell_buttons.erase(button_id)


func release_depressed_activity_shell_buttons_if_pointer_left(event: InputEvent) -> void:
	if depressed_activity_shell_buttons.is_empty():
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
	for raw_button in depressed_activity_shell_buttons.values().duplicate():
		if raw_button == null or not is_instance_valid(raw_button):
			continue
		var button := raw_button as Button
		if button == null:
			continue
		if host._navigation_shell()._page_switch_button_shell_release_preserved(button):
			_hold_activity_button_shell_at_depth(button)
			continue
		if host.button_press_runtime.pointer_inside_button_release_rect(event_position, button):
			continue
		host.button_press_runtime.force_button_unpressed(button)
		_release_activity_button_shell_bound(button.get_instance_id())


func release_all_depressed_activity_shell_buttons() -> void:
	if depressed_activity_shell_buttons.is_empty():
		return
	var activity_buttons: Array = depressed_activity_shell_buttons.values()
	depressed_activity_shell_buttons.clear()
	for raw_button in activity_buttons:
		if raw_button == null or not is_instance_valid(raw_button):
			continue
		var button := raw_button as Button
		if button == null:
			continue
		if host._navigation_shell()._page_switch_button_shell_release_preserved(button):
			_hold_activity_button_shell_at_depth(button)
			continue
		host.button_press_runtime.force_button_unpressed(button)
		_animate_activity_button_shell_to(button, Vector2.ZERO, host.ACTION_CARD_3D_RELEASE_SECONDS, Tween.TRANS_BACK, Tween.EASE_OUT)


func _hold_activity_button_shell_at_depth(button: Button) -> void:
	if button == null or not is_instance_valid(button):
		return
	var button_id = button.get_instance_id()
	depressed_activity_shell_buttons[button_id] = button
	host.button_press_runtime.force_button_unpressed(button)
	var depth_offset: Vector2 = host._app_lifecycle_runtime().meta_vector2(button, "activity_button_depth_offset", host.ACTION_CARD_3D_DEPTH_OFFSET)
	var pop = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(int(button.get_meta("activity_button_pop_id", 0)))) as Control
	_kill_activity_button_shell_tween(button)
	if pop != null:
		_set_activity_button_pop_depth_offset_bound(depth_offset, pop.get_instance_id())


func _animate_activity_button_shell_to(button: Button, target_offset: Vector2, seconds: float, transition: Tween.TransitionType, ease_type: Tween.EaseType) -> void:
	if button == null or not is_instance_valid(button):
		return
	var pop = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(int(button.get_meta("activity_button_pop_id", 0)))) as Control
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
	var button: Button = host._app_lifecycle_runtime().valid_button_ref(instance_from_id(button_id))
	if button != null and button.has_meta("activity_button_depth_tween"):
		button.remove_meta("activity_button_depth_tween")
	if target_offset == Vector2.ZERO:
		_set_activity_button_pop_depth_offset_bound(Vector2.ZERO, pop_id)


func _kill_activity_button_shell_tween(button: Button) -> void:
	host._app_lifecycle_runtime()._kill_meta_tween(button, "activity_button_depth_tween")
