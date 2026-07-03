extends RefCounted

const BuildableModules = preload("res://scripts/gameplay/buildable_modules.gd")
const BuildableModuleOverlay = preload("res://scripts/ui/buildable_module_overlay.gd")
const ActivityCardStyles = preload("res://scripts/ui/activity_card_styles.gd")
const ActionArtUi = preload("res://scripts/ui/action_art_ui.gd")
const BlueGuyChickenBrawlStageClass = preload("res://scripts/ui/blue_guy_chicken_brawl_stage.gd")
const ConvergenceBuildOverlay = preload("res://scripts/ui/convergence_build_overlay.gd")
const DiamondArenaFrame = preload("res://scripts/ui/diamond_arena_frame.gd")
const FishCircle = preload("res://scripts/ui/fish_circle.gd")
const FishingState = preload("res://scripts/fishing/state.gd")
const GameFormatting = preload("res://scripts/core/formatting.gd")
const MobileScrollContainer = preload("res://scripts/ui/mobile_scroll_container.gd")
const ModuleActionCircleZone = preload("res://scripts/ui/module_action_circle_zone.gd")
const ModuleCollapseMinusGlyph = preload("res://scripts/ui/module_collapse_minus_glyph.gd")
const ModuleUiRuntime = preload("res://scripts/module_ui/runtime.gd")
const MasteryState = preload("res://scripts/progression/mastery_state.gd")
const PassiveModuleStyles = preload("res://scripts/ui/passive_module_styles.gd")
const RegenCircle = preload("res://scripts/ui/regen_circle.gd")
const AchievementState = preload("res://scripts/achievements/state.gd")
const RoundedTextureRect = preload("res://scripts/ui/rounded_texture_rect.gd")
const RoosterPunchOutStage = preload("res://scripts/ui/rooster_punch_out_stage.gd")
const RecoveryModules = preload("res://scripts/gameplay/recovery_modules.gd")
const SkillIconBadge = preload("res://scripts/ui/skill_icon_badge.gd")
const SkillState = preload("res://scripts/progression/skill_state.gd")

const RECOVERY_WIDE_U_BOTTOM_RISE := 19.333

var host
var detail_jump_top_button: TextureButton
var detail_jump_bottom_button: TextureButton
var detail_jump_top_hold := 0.0
var detail_jump_bottom_hold := 0.0
var detail_jump_top_hovered := false
var detail_jump_bottom_hovered := false
var detail_jump_press_direction := 0
var detail_jump_press_touch_index := -1

func _detail_card_texture_paths_for_skill(skill_id: String) -> Array:
	var paths := []
	var boot_warmup = host._boot_warmup_runtime()
	boot_warmup._add_boot_warmup_texture_path(paths, host._skill_icon_path(skill_id))
	if skill_id == "fishing":
		host._fishing_ui_surface()._add_fishing_detail_visual_texture_paths(paths)
	for raw_entry in host._visible_detail_entries_for_skill(skill_id):
		var entry := raw_entry as Dictionary
		if str(entry.get("kind", "")) == "thieving_heist":
			boot_warmup._add_boot_warmup_texture_path(paths, host.THIEVING_HEIST_BACKGROUND_SHEET)
			boot_warmup._add_boot_warmup_texture_path(paths, host.THIEVING_HEIST_TROPHY_SHEET)
			boot_warmup._add_boot_warmup_texture_path(paths, host.THIEVING_HEIST_JAIL_BARS_TEXTURE)
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
	host.detail_texture_prewarm_skill_id = skill_id
	host.detail_texture_prewarm_pending.clear()
	host.detail_texture_prewarm_request_queue = host.visual_texture_cache._uncached_texture_paths(_detail_card_texture_paths_for_skill(skill_id))


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
	host.detail_texture_prewarm_skill_id = skill_id
	host.detail_texture_prewarm_pending.clear()
	host.detail_texture_prewarm_request_queue = host.visual_texture_cache._uncached_texture_paths(paths)


func _prewarm_detail_card_style_resources() -> void:
	_stat_box_style(false, false)
	_stat_box_style(false, true)
	_stat_box_style(true, false)
	_stat_box_style(true, true)
	ActivityCardStyles.cached_action_art(Callable(host, "_surface_style"))
	ActivityCardStyles.cached_action_art_border(Callable(host, "_surface_style"))
	ActivityCardStyles.cached_shade(0.50)


func _cancel_detail_card_texture_prewarm() -> void:
	host.detail_texture_prewarm_skill_id = ""
	host.detail_texture_prewarm_request_queue.clear()
	host.detail_texture_prewarm_pending.clear()


func _process_detail_card_texture_prewarm() -> void:
	if host.detail_texture_prewarm_skill_id.is_empty():
		return
	if host.current_screen != "skill":
		_cancel_detail_card_texture_prewarm()
		return
	if host.skill_swipe_pending_full_finalize or host.skill_swipe_defer_initial_lazy_mount or host._skill_swipe_handoff_cover_is_opaque_cream_transition():
		return
	_collect_completed_detail_texture_prewarm_requests()
	var requests_started := 0
	while requests_started < host.DETAIL_TEXTURE_PREWARM_REQUESTS_PER_FRAME and not host.detail_texture_prewarm_request_queue.is_empty():
		var path := str(host.detail_texture_prewarm_request_queue.pop_front())
		var normalized: String = host.visual_texture_cache._res_path(path)
		if normalized.is_empty() or host.visual_texture_cache.texture_cache.has(normalized) or host.detail_texture_prewarm_pending.has(normalized):
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
			host.detail_texture_prewarm_pending[normalized] = true
		else:
			host.visual_texture_cache._texture(path)
		requests_started += 1
	if host.detail_texture_prewarm_request_queue.is_empty() and host.detail_texture_prewarm_pending.is_empty():
		host.detail_texture_prewarm_skill_id = ""


func _collect_completed_detail_texture_prewarm_requests() -> void:
	if host.detail_texture_prewarm_pending.is_empty():
		return
	var completed := []
	for raw_path in host.detail_texture_prewarm_pending.keys():
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
		host.detail_texture_prewarm_pending.erase(normalized)


# Host-forwarded main.gd state.
var _clear_module_ui_animating_collapse_key:
	get: return host._clear_module_ui_animating_collapse_key
	set(value): host._clear_module_ui_animating_collapse_key = value

var _finish_module_list_transition:
	get: return host._finish_module_list_transition
	set(value): host._finish_module_list_transition = value

var _on_detail_actions_pull_offset_changed:
	get: return host._on_detail_actions_pull_offset_changed
	set(value): host._on_detail_actions_pull_offset_changed = value

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

var ActivityCardBorder:
	get: return host.ActivityCardBorder
	set(value): host.ActivityCardBorder = value

var ActivityCardDepth:
	get: return host.ActivityCardDepth
	set(value): host.ActivityCardDepth = value

var ActivityProgressRail:
	get: return host.ActivityProgressRail
	set(value): host.ActivityProgressRail = value

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

var CleanProgressBar:
	get: return host.CleanProgressBar
	set(value): host.CleanProgressBar = value

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

var MODULE_ACTION_ZONE_SIZE:
	get: return host.MODULE_ACTION_ZONE_SIZE
	set(value): host.MODULE_ACTION_ZONE_SIZE = value

var MODULE_ACTION_ZONE_TOP_OFFSET:
	get: return host.MODULE_ACTION_ZONE_TOP_OFFSET
	set(value): host.MODULE_ACTION_ZONE_TOP_OFFSET = value

var MODULE_ACTION_ZONE_OUTER_OFFSET:
	get: return host.MODULE_ACTION_ZONE_OUTER_OFFSET
	set(value): host.MODULE_ACTION_ZONE_OUTER_OFFSET = value

var MODULE_COLLAPSE_ACTION_ZONE_SIZE:
	get: return host.MODULE_COLLAPSE_ACTION_ZONE_SIZE
	set(value): host.MODULE_COLLAPSE_ACTION_ZONE_SIZE = value

var MODULE_COLLAPSE_ACTION_ZONE_TOP_OFFSET:
	get: return host.MODULE_COLLAPSE_ACTION_ZONE_TOP_OFFSET
	set(value): host.MODULE_COLLAPSE_ACTION_ZONE_TOP_OFFSET = value

var MODULE_COLLAPSE_ACTION_ZONE_OUTER_OFFSET:
	get: return host.MODULE_COLLAPSE_ACTION_ZONE_OUTER_OFFSET
	set(value): host.MODULE_COLLAPSE_ACTION_ZONE_OUTER_OFFSET = value

var MODULE_ACTION_ZONE_Z_INDEX:
	get: return host.MODULE_ACTION_ZONE_Z_INDEX
	set(value): host.MODULE_ACTION_ZONE_Z_INDEX = value

var MODULE_PIN_BADGE_HIT_MIN:
	get: return host.MODULE_PIN_BADGE_HIT_MIN
	set(value): host.MODULE_PIN_BADGE_HIT_MIN = value

var MODULE_PIN_BADGE_HIT_MAX:
	get: return host.MODULE_PIN_BADGE_HIT_MAX
	set(value): host.MODULE_PIN_BADGE_HIT_MAX = value

var MODULE_COLLAPSE_BADGE_SIZE:
	get: return host.MODULE_COLLAPSE_BADGE_SIZE
	set(value): host.MODULE_COLLAPSE_BADGE_SIZE = value

var MODULE_COLLAPSE_BADGE_POSITION:
	get: return host.MODULE_COLLAPSE_BADGE_POSITION
	set(value): host.MODULE_COLLAPSE_BADGE_POSITION = value

var ConvergenceMultiProgressBar:
	get: return host.ConvergenceMultiProgressBar
	set(value): host.ConvergenceMultiProgressBar = value

var current_screen:
	get: return host.current_screen
	set(value): host.current_screen = value

var dark_mode_enabled:
	get: return host.dark_mode_enabled
	set(value): host.dark_mode_enabled = value

var detail_action_card_nodes:
	get: return host.detail_action_card_nodes
	set(value): host.detail_action_card_nodes = value

var detail_actions_scroll:
	get: return host.detail_actions_scroll
	set(value): host.detail_actions_scroll = value

var detail_actions_top_spacer:
	get: return host.detail_actions_top_spacer
	set(value): host.detail_actions_top_spacer = value

var detail_auto_eat_fish_button:
	get: return host.detail_auto_eat_fish_button
	set(value): host.detail_auto_eat_fish_button = value

var detail_blue_guy_health_gauge:
	get: return host.detail_blue_guy_health_gauge
	set(value): host.detail_blue_guy_health_gauge = value

var detail_fish_circle:
	get: return host.detail_fish_circle
	set(value): host.detail_fish_circle = value

var detail_header_body:
	get: return host.detail_header_body
	set(value): host.detail_header_body = value

var detail_header_left_block:
	get: return host.detail_header_left_block
	set(value): host.detail_header_left_block = value

var DETAIL_LAZY_BOOT_EAGER_COUNT:
	get: return host.DETAIL_LAZY_BOOT_EAGER_COUNT
	set(value): host.DETAIL_LAZY_BOOT_EAGER_COUNT = value

var DETAIL_LAZY_INITIAL_FORCE_MOUNT_COUNT:
	get: return host.DETAIL_LAZY_INITIAL_FORCE_MOUNT_COUNT
	set(value): host.DETAIL_LAZY_INITIAL_FORCE_MOUNT_COUNT = value

var detail_lazy_last_scroll:
	get: return host.detail_lazy_last_scroll
	set(value): host.detail_lazy_last_scroll = value

var DETAIL_LAZY_MOUNT_BUDGET_PER_FRAME:
	get: return host.DETAIL_LAZY_MOUNT_BUDGET_PER_FRAME
	set(value): host.DETAIL_LAZY_MOUNT_BUDGET_PER_FRAME = value

var detail_lazy_mount_trace_context:
	get: return host.detail_lazy_mount_trace_context
	set(value): host.detail_lazy_mount_trace_context = value

var detail_lazy_mounted_this_frame:
	get: return host.detail_lazy_mounted_this_frame
	set(value): host.detail_lazy_mounted_this_frame = value

var detail_lazy_plan:
	get: return host.detail_lazy_plan
	set(value): host.detail_lazy_plan = value

var DETAIL_LAZY_SCALE_IN_AMOUNT:
	get: return host.DETAIL_LAZY_SCALE_IN_AMOUNT
	set(value): host.DETAIL_LAZY_SCALE_IN_AMOUNT = value

var detail_lazy_stack:
	get: return host.detail_lazy_stack
	set(value): host.detail_lazy_stack = value

var DETAIL_LAZY_STACK_SEPARATION:
	get: return host.DETAIL_LAZY_STACK_SEPARATION
	set(value): host.DETAIL_LAZY_STACK_SEPARATION = value

var DETAIL_LAZY_TIP_HEIGHT:
	get: return host.DETAIL_LAZY_TIP_HEIGHT
	set(value): host.DETAIL_LAZY_TIP_HEIGHT = value

var DETAIL_LAZY_UNMOUNT_BUDGET_PER_FRAME:
	get: return host.DETAIL_LAZY_UNMOUNT_BUDGET_PER_FRAME
	set(value): host.DETAIL_LAZY_UNMOUNT_BUDGET_PER_FRAME = value

var DETAIL_LAZY_UNMOUNT_ENABLED:
	get: return host.DETAIL_LAZY_UNMOUNT_ENABLED
	set(value): host.DETAIL_LAZY_UNMOUNT_ENABLED = value

var detail_scroll_visual_work_this_frame:
	get: return host.detail_scroll_visual_work_this_frame
	set(value): host.detail_scroll_visual_work_this_frame = value

var detail_pull_tip_active:
	get: return host.detail_pull_tip_active
	set(value): host.detail_pull_tip_active = value

var detail_pull_tip_direction:
	get: return host.detail_pull_tip_direction
	set(value): host.detail_pull_tip_direction = value

var detail_pull_tip_label:
	get: return host.detail_pull_tip_label
	set(value): host.detail_pull_tip_label = value

var detail_pull_tip_root:
	get: return host.detail_pull_tip_root
	set(value): host.detail_pull_tip_root = value

var detail_regen_circle:
	get: return host.detail_regen_circle
	set(value): host.detail_regen_circle = value

var detail_regen_circle_fade_group:
	get: return host.detail_regen_circle_fade_group
	set(value): host.detail_regen_circle_fade_group = value

var detail_regen_circle_host:
	get: return host.detail_regen_circle_host
	set(value): host.detail_regen_circle_host = value

var detail_rendered_action_ids:
	get: return host.detail_rendered_action_ids
	set(value): host.detail_rendered_action_ids = value

var DETAIL_RESTORE_SCROLL_BOTTOM:
	get: return host.DETAIL_RESTORE_SCROLL_BOTTOM
	set(value): host.DETAIL_RESTORE_SCROLL_BOTTOM = value

var detail_shelf_shadow_overlay:
	get: return host.detail_shelf_shadow_overlay
	set(value): host.detail_shelf_shadow_overlay = value

var detail_stamina_bar:
	get: return host.detail_stamina_bar
	set(value): host.detail_stamina_bar = value

var detail_unlock_scroll_spacer:
	get: return host.detail_unlock_scroll_spacer
	set(value): host.detail_unlock_scroll_spacer = value

var detail_unlock_scroll_spacer_heights:
	get: return host.detail_unlock_scroll_spacer_heights
	set(value): host.detail_unlock_scroll_spacer_heights = value

var detail_xp_bar:
	get: return host.detail_xp_bar
	set(value): host.detail_xp_bar = value

var detail_xp_label:
	get: return host.detail_xp_label
	set(value): host.detail_xp_label = value

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

var MODULE_COLLAPSE_SQUEEZE_SECONDS:
	get: return host.MODULE_COLLAPSE_SQUEEZE_SECONDS
	set(value): host.MODULE_COLLAPSE_SQUEEZE_SECONDS = value

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

var module_ui_animating_collapse_key:
	get: return host.module_ui_animating_collapse_key
	set(value): host.module_ui_animating_collapse_key = value

var module_ui_pending_pin_scroll_anchor:
	get: return host.module_ui_pending_pin_scroll_anchor
	set(value): host.module_ui_pending_pin_scroll_anchor = value

var module_ui_recent_pin_prune_hold_skill_id:
	get: return host.module_ui_recent_pin_prune_hold_skill_id
	set(value): host.module_ui_recent_pin_prune_hold_skill_id = value

var module_ui_recent_pin_prune_hold_until_msec:
	get: return host.module_ui_recent_pin_prune_hold_until_msec
	set(value): host.module_ui_recent_pin_prune_hold_until_msec = value

var onboarding_fight_stamina_revealed:
	get: return host.onboarding_fight_stamina_revealed
	set(value): host.onboarding_fight_stamina_revealed = value


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

var skill_swipe:
	get: return host.skill_swipe
	set(value): host.skill_swipe = value

var skill_swipe_defer_initial_lazy_mount:
	get: return host.skill_swipe_defer_initial_lazy_mount
	set(value): host.skill_swipe_defer_initial_lazy_mount = value

var skill_swipe_drag_offset_x:
	get: return host.skill_swipe_drag_offset_x
	set(value): host.skill_swipe_drag_offset_x = value

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
	get: return host.skill_swipe_finalized_lazy_mount_pending
	set(value): host.skill_swipe_finalized_lazy_mount_pending = value

var skill_swipe_frame:
	get: return host.skill_swipe_frame
	set(value): host.skill_swipe_frame = value

var skill_swipe_gap_render_offset_x:
	get: return host.skill_swipe_gap_render_offset_x
	set(value): host.skill_swipe_gap_render_offset_x = value

var skill_swipe_lazy_finalize_token:
	get: return host.skill_swipe_lazy_finalize_token
	set(value): host.skill_swipe_lazy_finalize_token = value

var skill_swipe_page:
	get: return host.skill_swipe_page
	set(value): host.skill_swipe_page = value

var skill_swipe_pending_full_finalize:
	get: return host.skill_swipe_pending_full_finalize
	set(value): host.skill_swipe_pending_full_finalize = value

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
	get: return host.stamina_gauge_tip_seen
	set(value): host.stamina_gauge_tip_seen = value

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
		host._set_label_text_if_changed(title_label, title_text)
	if int(title_label.get_meta("stat_title_outline_size", -1)) != 0:
		title_label.set_meta("stat_title_outline_size", 0)
		title_label.add_theme_constant_override("outline_size", 0)


func _on_action_stat_box_gui_input(event: InputEvent, skill_id: String, action_id: String, stat_kind: String) -> void:
	var card := action_cards.get(host._action_key(skill_id, action_id), {}) as Dictionary
	if not host._action_stat_box_accepts_input(card, stat_kind):
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			host._on_action_stat_button_pressed(skill_id, action_id, stat_kind)
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			host._on_action_stat_button_pressed(skill_id, action_id, stat_kind)


func _action_stat_label(text: String) -> Label:
	var label := host._label(text, 60, COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER) as Label
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
	label.add_theme_font_size_override("font_size", 66)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.z_index = 10
	stack.add_child(label)
	var title_label := _action_stat_label(str(stat_kind).to_upper())
	title_label.add_theme_font_size_override("font_size", 48)
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
	var buffed := box != null and bool(box.get_meta("stat_box_buffed", false))
	var theme_variant = box.get_meta("stat_box_theme_color", host.COLOR_BLUE) if box != null else host.COLOR_BLUE
	var theme_color := theme_variant as Color
	return "%s:%s:%s:%s" % [active, pressed, buffed, theme_color.to_html(true)]


func _stat_box_style_for_box(box: Control, active := false, pressed := false) -> StyleBoxTexture:
	if box != null and bool(box.get_meta("stat_box_buffed", false)):
		var theme_variant = box.get_meta("stat_box_theme_color", host.COLOR_BLUE)
		var theme_color := theme_variant as Color
		return _stat_box_style(active, pressed, theme_color)
	return _stat_box_style(active, pressed)


func _stat_box_style(active := false, pressed := false, fill := Color.WHITE) -> StyleBoxTexture:
	var outline: Color = host.COLOR_BLUE if active else COLOR_INK
	return host._paper_button_style_with_outline(fill, 38, 18, pressed, false, outline)


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
	host._apply_info_symbol_button_text_color(button)
	button.add_theme_stylebox_override("normal", PassiveModuleStyles.round_button(host.COLOR_PANEL, COLOR_INK, Callable(host, "_surface_style"), Callable(host, "_theme_outline_color")))
	button.add_theme_stylebox_override("hover", PassiveModuleStyles.round_button(host.COLOR_PANEL.lightened(0.06), COLOR_INK, Callable(host, "_surface_style"), Callable(host, "_theme_outline_color")))
	button.add_theme_stylebox_override("pressed", PassiveModuleStyles.round_button(COLOR_GOLD.darkened(0.08), COLOR_INK, Callable(host, "_surface_style"), Callable(host, "_theme_outline_color")))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if host.app_bold_font != null:
		button.add_theme_font_override("font", host.app_bold_font)
	host._button_press_runtime().attach_button_depress_animation(button, 0.90)
	var popover := _skill_header_info_popover(title_text, body_text)
	button.add_child(popover)
	host._passive_firepit_surface()._prewarm_passive_info_popover(popover)
	button.pressed.connect(Callable(host._passive_firepit_surface(), "_toggle_passive_info_popover").bind(popover))
	return button


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


func _render_skill_detail(scroll_latest_activity = false, restore_detail_scroll = -1, async_action_cards = false, strip_index: int = -1):
	var strip_mode = strip_index >= 0
	var initial_drag_x = 0.0 if strip_mode else skill_swipe_gap_render_offset_x
	if not strip_mode:
		skill_swipe_drag_offset_x = initial_drag_x
	var content_width = host._skill_content_width()
	var actions_width = content_width
	if not host._detail_unlock_extra_scroll_space_allowed(selected_skill_id):
		detail_unlock_scroll_spacer_heights.erase(selected_skill_id)
	if not strip_mode:
		var frame = Control.new()
		skill_swipe_frame = frame
		frame.clip_contents = false
		var frame_width = content_width
		host._apply_skill_column_layout(frame, frame_width, initial_drag_x)
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
	header.add_theme_stylebox_override("panel", host._skill_detail_shelf_style(selected_skill_id, false))
	page.add_child(header)
	var header_body = Control.new()
	detail_header_body = header_body
	header_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	header.add_child(header_body)
	host._add_skill_detail_shelf_background(header_body, selected_skill_id, content_width)
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
	var title = host._label(host._skill_name(selected_skill_id), host._skill_detail_title_font_size(selected_skill_id), COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
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
	var xp = SkillState.xp_progress(host.skills, selected_skill_id, host._skill_level(selected_skill_id))
	detail_xp_label = host._label(host._skill_level_xp_text(selected_skill_id), SKILL_DETAIL_XP_FONT_SIZE, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	detail_xp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_stack.add_child(detail_xp_label)
	detail_xp_bar = host._skill_detail_xp_bar(selected_skill_id, float(xp["pct"]))
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
		host._attach_fishing_fish_circle_button(detail_fish_circle)
		host._set_fish_circle_for_skill(detail_fish_circle, selected_skill_id, true)
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
		detail_regen_circle.gui_input.connect(host._on_stamina_gauge_input.bind("", detail_regen_circle))
		detail_regen_circle_fade_group.add_child(detail_regen_circle)
		detail_regen_circle_host.add_child(detail_regen_circle_fade_group)
		header_row.add_child(detail_regen_circle_host)
		detail_auto_eat_fish_button = host._fishing_ui_surface()._attach_auto_eat_fish_toggle(detail_regen_circle_host, selected_skill_id)
		host._set_regen_circle_for_skill(detail_regen_circle, selected_skill_id, true)
	host._tutorial_overlay_surface()._apply_onboarding_fight_header_visibility()
	host._tutorial_overlay_surface()._apply_onboarding_fight_action_stats_visibility_all()
	host._sync_skill_detail_back_arrow_visibility()
	if host._onboarding_runtime()._onboarding_auto_run_message_resumable():
		host._onboarding_runtime().call_deferred("_run_onboarding_auto_run_message_sequence")
	if host._onboarding_runtime()._onboarding_header_reveal_sequence_resumable():
		host._onboarding_runtime().call_deferred("_run_onboarding_header_reveal_sequence")
	elif onboarding_fight_stamina_revealed and not stamina_gauge_tip_seen and host._onboarding_runtime()._onboarding_fight_header_sequence_active():
		host._onboarding_runtime().call_deferred("_run_onboarding_stamina_tip_sequence")
	elif host._onboarding_runtime()._onboarding_swipe_tip_sequence_resumable():
		host.call_deferred("_run_onboarding_swipe_tip_sequence")
	elif host._fishing_rework_active_for_skill(selected_skill_id):
		host._dismiss_skill_detail_tutorial_tips()

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
	host._build_detail_pull_tip_overlay(actions_clip, content_width)
	var stack = VBoxContainer.new()
	stack.custom_minimum_size.x = actions_width
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 56)
	actions_scroll.add_child(stack)
	var scroll_top_spacer = Control.new()
	scroll_top_spacer.name = "DetailActionsTopSpacer"
	scroll_top_spacer.custom_minimum_size = Vector2(0, host._onboarding_first_module_top_spacer_height(selected_skill_id))
	stack.add_child(scroll_top_spacer)
	detail_actions_top_spacer = scroll_top_spacer

	detail_lazy_stack = stack
	if host._fishing_rework_active_for_skill(selected_skill_id):
		host._render_fishing_area_modules(stack, content_width)
		if boot_detail_card_yield:
			await host.get_tree().process_frame
		if host._activity_start_inline_tip_available(selected_skill_id):
			var start_note = host._activity_start_tip_note(content_width)
			host._detail_eager_add_activity_start_tip_below_content(stack, start_note, content_width, actions_width)
			host._fade_in_activity_start_tip_note(start_note)
		elif host._onboarding_runtime()._skill_swipe_tip_available():
			host.call_deferred("_run_onboarding_swipe_tip_sequence")
	else:
		if boot_detail_card_yield:
			await host._render_detail_eager_card_list_async(stack, content_width, actions_width, DETAIL_LAZY_BOOT_EAGER_COUNT)
		elif async_action_cards:
			await host._render_detail_eager_card_list_async(stack, content_width, actions_width)
		else:
			if skill_swipe_defer_initial_lazy_mount:
				var lazy_slots_created = await host._render_detail_lazy_card_list_batched(
					stack,
					content_width,
					actions_width,
					SKILL_SWIPE_FINALIZE_SLOT_BATCH_SIZE
				)
				if not lazy_slots_created:
					return
			else:
				host._render_detail_lazy_card_list(stack, content_width, actions_width)
	if boot_detail_card_yield:
		boot_detail_render_in_progress = false
		if boot_detail_render_queue.is_empty():
			boot_detail_scroll_locked = false
			host._append_detail_eager_trailing_tips(stack, content_width, actions_width)
		else:
			boot_detail_scroll_locked = true
			actions_scroll.set_max_scroll_override(0)
			actions_scroll.set_scroll_enabled_by_content(false)
			host.call_deferred("_complete_boot_detail_cards_async")
	host._render_page_switch_module(stack, selected_skill_id, content_width, actions_width)
	var scroll_bottom_spacer = Control.new()
	scroll_bottom_spacer.name = "DetailActionsBottomSpacer"
	var bottom_pad = host._detail_actions_bottom_scroll_pad(selected_skill_id)
	scroll_bottom_spacer.custom_minimum_size = Vector2(0, bottom_pad)
	scroll_bottom_spacer.visible = bottom_pad > 1.0
	stack.add_child(scroll_bottom_spacer)
	detail_unlock_scroll_spacer = scroll_bottom_spacer
	if boot_detail_card_yield:
		host.call_deferred("_finish_boot_skill_detail_extras")
	else:
		_build_detail_jump_arrows(actions_clip)
		host._add_skill_detail_shadow_overlay(host._skill_detail_shadow_top_y())
		if not strip_mode:
			host._skill_swipe_activity_surface()._queue_skill_swipe_preview_prewarm()
	if not strip_mode:
		host.call_deferred("_sync_detail_actions_scroll_limit_deferred")
		if restore_detail_scroll == DETAIL_RESTORE_SCROLL_BOTTOM:
			actions_scroll.drag_scroll_position = 10000000.0
			actions_scroll.scroll_vertical = 10000000
			host.call_deferred("_scroll_detail_actions_to_bottom_after_layout")
		elif host._suppress_detail_auto_scroll_for_first_module():
			host.call_deferred("_sync_onboarding_first_module_top_spacer", true)
		elif restore_detail_scroll >= 0:
			var detail_restore_scroll = host._detail_restore_scroll_value(restore_detail_scroll)
			actions_scroll.drag_scroll_position = float(detail_restore_scroll)
			actions_scroll.scroll_vertical = detail_restore_scroll
			host.call_deferred("_restore_detail_actions_scroll", detail_restore_scroll)
		elif scroll_latest_activity:
			host.call_deferred("_scroll_to_resume_activity", false)
		host.call_deferred("_ensure_skill_swipe_frame_centered")
		host._normalize_skill_detail_page_layout()


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
	var stat_hit_buttons = {}
	var recovery_label: Label = null
	var boss_label = _detail_action_boss_line(copy, action)

	var mastery_widgets = _detail_action_mastery_widgets(copy, art_panel, skill_id, action)
	var medal = mastery_widgets.get("medal") as TextureRect
	var mastery_progress = mastery_widgets.get("mastery") as CleanProgressBar
	if RecoveryModules.has_recovery(action) and mastery_progress != null:
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
	if ACTION_CARD_FACE_BORDER_ENABLED and not host._fighting_runtime().action_uses_diamond_combat_arena(action):
		border = ActivityCardBorder.new()
		border.set_anchors_preset(Control.PRESET_FULL_RECT)
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		border.z_index = ACTION_CARD_FACE_BORDER_Z_INDEX
		if RecoveryModules.has_recovery(action):
			border.bottom_shape = "wide_u"
			border.wide_u_bottom_rise = RECOVERY_WIDE_U_BOTTOM_RISE
		pop_card.add_child(border)
	var mission_badge = {}
	var lock_overlay = _activity_lock_overlay(pop_card, int(action.get("unlock", 1)), skill_id, _lock_requirements_for_overlay(skill_id, action)) if build_overlay == null and not host._is_action_unlocked(skill_id, action) else {}
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
		"stat_boxes": stat_boxes,
		"bonus_parent": copy,
		"stat_hit_buttons": stat_hit_buttons,
		"bonus_panel": bonus_panel,
		"status": status,
		"medal": medal,
		"mastery": mastery_progress,
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
	if card_host == null or not is_instance_valid(card_host) or normalized_key.is_empty() or not host._module_ui_key_allows_pin_or_collapse(normalized_key):
		return {}
	card_host.set_meta("module_ui_key", normalized_key)
	var existing := _module_action_zones_for_card(card_host)
	if not existing.is_empty():
		return existing
	var pin_zone := _module_action_zone("pin", normalized_key, true)
	var collapse_zone := _module_action_zone("collapse", normalized_key, false)
	pin_zone.gui_input.connect(Callable(host, "_on_module_pin_zone_gui_input").bind(normalized_key, card_host.get_instance_id()))
	collapse_zone.gui_input.connect(Callable(host, "_on_module_collapse_zone_gui_input").bind(normalized_key, card_host.get_instance_id()))
	card_host.add_child(pin_zone)
	card_host.add_child(collapse_zone)
	host._sync_module_pin_badge(card_host, normalized_key)
	return {
		"pin": pin_zone,
		"collapse": collapse_zone
	}


func _sync_module_action_zones_for_card(card: Dictionary, module_key: String) -> void:
	if card.is_empty():
		return
	var normalized_key: String = ModuleUiRuntime.normalize(module_key)
	var raw_host = card.get("pop", null)
	var card_host: Control = host._valid_control_ref(raw_host)
	if card_host == null or normalized_key.is_empty():
		return
	if not host._module_ui_key_allows_pin_or_collapse(normalized_key):
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
	var badge: TextureButton = host._module_pin_badge(card_host)
	if badge != null:
		badge.visible = false
		badge.disabled = true
		host._set_canvas_item_alpha_if_changed(badge, 0.0)
	var collapse_badge: Button = _module_collapse_badge(card_host)
	if collapse_badge != null:
		collapse_badge.visible = false
		collapse_badge.disabled = true
		host._set_canvas_item_alpha_if_changed(collapse_badge, 0.0)


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
	for candidate in host._activity_input_position_candidates(event_position):
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
		for candidate in host._activity_input_position_candidates(event_position):
			if center.distance_to(candidate) <= radius:
				return kind
	return ""


func _module_action_badge_kind_at_position(card_host: Control, event_position: Vector2) -> String:
	var pin_badge: TextureButton = host._module_pin_badge(card_host)
	if _module_pin_badge_contains_point(pin_badge, event_position):
		return "pin"
	var collapse_badge := _module_collapse_badge(card_host)
	if _visible_control_contains_point(collapse_badge, event_position):
		return "collapse"
	return ""


func _module_pin_badge_contains_point(badge: TextureButton, event_position: Vector2) -> bool:
	if badge == null or not is_instance_valid(badge) or not badge.visible or badge.disabled or badge.is_queued_for_deletion():
		return false
	if not badge.is_inside_tree() or not badge.is_visible_in_tree():
		return false
	var clip_host: Control = host._module_pin_badge_clip_host(badge)
	if clip_host != null and clip_host.clip_contents and not _visible_control_contains_point(clip_host, event_position):
		return false
	for candidate in host._activity_input_position_candidates(event_position):
		var local_point: Vector2 = badge.get_global_transform().affine_inverse() * candidate
		if local_point.x < MODULE_PIN_BADGE_HIT_MIN.x or local_point.y < MODULE_PIN_BADGE_HIT_MIN.y:
			continue
		if local_point.x > MODULE_PIN_BADGE_HIT_MAX.x or local_point.y > MODULE_PIN_BADGE_HIT_MAX.y:
			continue
		return true
	return false


func _module_pin_badge_is_exiting(card_host: Control) -> bool:
	var badge: TextureButton = host._module_pin_badge(card_host)
	return badge != null and is_instance_valid(badge) and badge.has_meta("module_pin_tween")


func _visible_control_contains_point(control: Control, event_position: Vector2) -> bool:
	if control == null or not is_instance_valid(control) or not control.visible or control.is_queued_for_deletion():
		return false
	if not control.is_inside_tree() or not control.is_visible_in_tree():
		return false
	var rect := control.get_global_rect()
	for candidate in host._activity_input_position_candidates(event_position):
		if rect.has_point(candidate):
			return true
	return false


func _module_action_circle_at_position(event_position: Vector2) -> Dictionary:
	if event_position == Vector2.INF:
		return {}
	if host._position_inside_bottom_interactive_ui(event_position):
		return {}
	var direct_hit := _module_action_circle_at_direct_position(event_position)
	if not direct_hit.is_empty():
		return direct_hit
	host._prune_invalid_action_cards()
	for raw_card in action_cards.values():
		var card := raw_card as Dictionary
		var raw_host = card.get("pop", null)
		var card_host: Control = host._valid_control_ref(raw_host)
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
		var root: Control = host._valid_control_ref(raw_root)
		var tree_hit := _module_action_circle_at_position_in_tree(root, event_position)
		if not tree_hit.is_empty():
			return tree_hit
	return {}


func _module_action_circle_at_direct_position(event_position: Vector2) -> Dictionary:
	host._prune_invalid_action_cards()
	for raw_card in action_cards.values():
		var card := raw_card as Dictionary
		var raw_host = card.get("pop", null)
		var card_host: Control = host._valid_control_ref(raw_host)
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
		var root: Control = host._valid_control_ref(raw_root)
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
	if not module_key.is_empty() and host._module_ui_key_allows_pin_or_collapse(module_key):
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
	var pin_badge: TextureButton = host._module_pin_badge(card_host)
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
	var clip_host: Control = host._module_pin_badge_clip_host(badge)
	if clip_host != null and clip_host.clip_contents and not _visible_control_direct_contains_point(clip_host, event_position):
		return false
	var local_point := badge.get_global_transform().affine_inverse() * event_position
	if local_point.x < MODULE_PIN_BADGE_HIT_MIN.x or local_point.y < MODULE_PIN_BADGE_HIT_MIN.y:
		return false
	if local_point.x > MODULE_PIN_BADGE_HIT_MAX.x or local_point.y > MODULE_PIN_BADGE_HIT_MAX.y:
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
	if not module_key.is_empty() and host._module_ui_key_allows_pin_or_collapse(module_key):
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
	return host._valid_button_ref(instance_from_id(int(card_host.get_meta("module_collapse_badge_id", 0))))


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
	badge.pressed.connect(Callable(host, "_collapse_module_ui_key").bind(module_key, card_host.get_instance_id()))
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



func _detail_action_card_shell(skill_id: String, action: Dictionary, content_width: float, uses_blue_guy_chicken_brawl_stage: bool) -> Dictionary:
	var card_root := Control.new()
	card_root.custom_minimum_size = Vector2(content_width, host._activity_card_root_height_for_action(action))
	card_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_root.clip_contents = false

	var pop_card := Control.new()
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
	pop_card.mouse_filter = Control.MOUSE_FILTER_PASS
	pop_card.z_index = 1

	var uses_diamond_arena: bool = host._fighting_runtime().action_uses_diamond_combat_arena(action)
	var depth: ActivityCardDepth = null
	if uses_diamond_arena:
		pop_card.set_meta("activity_card_depth_bottom_inset", 0.0)
		pop_card.offset_bottom = host._activity_card_pop_base_bottom_offset(pop_card)
	else:
		depth = ActivityCardStyles.activity_card_depth_layer(host._skill_theme_color(skill_id), host.ACTION_CARD_3D_DEPTH_OFFSET, host.ACTION_CARD_FACE_RADIUS, host.ACTION_CARD_POP_GUTTER)
		host._apply_activity_card_depth_action_theme(depth, skill_id, action)
		_apply_recovery_card_depth_shape(depth, action)
		if BuildableModules.is_buildable(action) and not BuildableModules.is_built(host.built_modules, skill_id, action, Callable(host, "_action_key")):
			depth.back_color = Color("#14758e")
			depth.side_color = Color("#0f5e75")
			depth.bottom_color = Color("#1f9ab8")
			depth.highlight_color = Color(0.72, 0.95, 1.0, 0.24)
			depth.shadow_color = Color(0.02, 0.08, 0.10, 0.32)
		card_root.add_child(depth)
		pop_card.set_meta("activity_card_depth_node_id", depth.get_instance_id())
	card_root.add_child(pop_card)

	var background_underlay: Panel = ActivityCardStyles.action_card_background_edge_underlay(host._themed_activity_card_fill_color(host._skill_theme_color(skill_id)), host.ACTION_CARD_FACE_RADIUS)
	background_underlay.visible = not RecoveryModules.has_recovery(action) and not uses_diamond_arena
	pop_card.add_child(background_underlay)
	var bg = host._action_card_background(skill_id, action)
	_apply_recovery_card_background_shape(bg, action)
	bg.visible = not uses_diamond_arena
	pop_card.add_child(bg)

	var rooster_boss_stage: Control = null
	if host._fighting_runtime().action_uses_rooster_punch_out_stage(action):
		pop_card.clip_contents = true
		rooster_boss_stage = RoosterPunchOutStage.new()
		rooster_boss_stage.set_anchors_preset(Control.PRESET_FULL_RECT)
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
	if not host._is_action_unlocked(skill_id, action):
		shade = ActivityCardStyles.activity_card_shade_layer(pop_card, 0.50)

	return {
		"card_root": card_root,
		"pop": pop_card,
		"depth": depth,
		"bg": bg,
		"shade": shade,
		"rooster_boss_stage": rooster_boss_stage,
		"blue_guy_chicken_stage": blue_guy_chicken_stage,
	}


func _attach_diamond_combat_arena_frame(pop_card: Control) -> DiamondArenaFrame:
	var frame := DiamondArenaFrame.new()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.z_index = 238
	frame.fill_color = Color("#a01419")
	frame.border_color = COLOR_INK
	frame.accent_color = Color("#ff0b42")
	frame.border_width = 14.0
	frame.accent_width = 6.0
	frame.inset = 26.0
	pop_card.add_child(frame)
	return frame


func _detail_action_card_body(card_root: Control, pop_card: Control, skill_id: String, action: Dictionary, is_convergence_card: bool, uses_blue_guy_chicken_brawl_stage: bool) -> Dictionary:
	var uses_rooster_boss_stage = host._fighting_runtime().action_uses_rooster_punch_out_stage(action)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 54)
	margin.add_theme_constant_override("margin_right", 54)
	margin.add_theme_constant_override("margin_top", 46)
	margin.add_theme_constant_override("margin_bottom", 126)
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.z_index = 200
	margin.visible = not uses_blue_guy_chicken_brawl_stage and not uses_rooster_boss_stage
	pop_card.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 56)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_child(row)

	var art_slot := MarginContainer.new()
	art_slot.add_theme_constant_override("margin_top", 42)
	art_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art_panel := Panel.new()
	art_panel.custom_minimum_size = ActionArtUi.ACTION_ART_PANEL_SIZE
	art_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	art_panel.add_theme_stylebox_override("panel", ActivityCardStyles.cached_action_art(Callable(host, "_surface_style")))
	art_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_slot.add_child(art_panel)
	var art = ActionArtUi.image(action, Callable(host, "_texture_or_visual_fallback"), Callable(host.visual_texture_cache, "_visual_fallback_texture"), DisplayServer.get_name() == "headless")
	art_panel.add_child(art)
	if uses_blue_guy_chicken_brawl_stage:
		art.visible = false
		var chicken_stage := BlueGuyChickenBrawlStageClass.new()
		chicken_stage.set_anchors_preset(Control.PRESET_FULL_RECT)
		chicken_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chicken_stage.z_index = 2
		art_panel.add_child(chicken_stage)
	ActionArtUi.add_corner_badges(
		art_panel,
		ActionArtUi.resource_icon_paths(action, Callable(host._action_runtime(), "_action_mat_reward_defs"), Callable(host.material_runtime, "icon_path"), Callable(host._temporary_event_runtime(), "_temporary_event_log_reward_mat_id")),
		ActionArtUi.special_type_icon_path(action, Callable(host, "_is_event_action")),
		Callable(host, "_texture_or_visual_fallback")
	)
	art_panel.add_child(ActionArtUi.border_overlay(ActivityCardStyles.cached_action_art_border(Callable(host, "_surface_style"))))

	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 38)
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

	var action_name_label = host._label(str(action["name"]), 82, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT) as Label
	action_name_label.add_theme_color_override("font_outline_color", COLOR_INK)
	action_name_label.add_theme_constant_override("outline_size", host.ACTION_CARD_TITLE_OUTLINE_SIZE)
	action_name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	action_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	action_name_label.set_meta("module_ui_title_label", true)
	action_name_label.set_meta("activity_card_locked_title_z_index", 0)
	action_name_label.z_index = host._activity_card_title_z_index(host._is_action_unlocked(skill_id, action), action_name_label)
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
		copy.add_child(action_name_label)
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
	var stat_row := HBoxContainer.new()
	stat_row.add_theme_constant_override("separation", 28)
	stat_row.mouse_filter = Control.MOUSE_FILTER_PASS
	copy.add_child(stat_row)

	var xp_label = _action_stat_label("") as Label
	var xp_box = _action_stat_box(xp_label, true, skill_id, action_id, "xp") as Control
	stat_row.add_child(xp_box)
	var stamina_label = _action_stat_label("") as Label
	var stamina_box = _action_stat_box(stamina_label, true, skill_id, action_id, "stamina") as Control
	stat_row.add_child(stamina_box)
	var time_label = _action_stat_label("") as Label
	var time_box = _action_stat_box(time_label, true, skill_id, action_id, "time") as Control
	stat_row.add_child(time_box)
	var success_label = _action_stat_label("") as Label
	var success_box = _action_stat_box(success_label, true, skill_id, action_id, "success") as Control
	stat_row.add_child(success_box)
	host._material_collection_surface().call_deferred("sync_berry_prep_badges")

	var initial_xp_parts = host._action_xp_reward_parts_for_display(skill_id, action)
	host._set_label_text_if_changed(xp_label, "+%s" % GameFormatting.info_chip_number(float(host._action_xp_reward_total(initial_xp_parts))))
	host._set_label_text_if_changed(stamina_label, host._action_stamina_stat_text(skill_id, action))
	host._set_label_text_if_changed(time_label, "%ss" % GameFormatting.info_chip_number(host._action_runtime()._action_cycle_seconds(skill_id, action)))
	host._set_label_text_if_changed(success_label, "%s%%" % GameFormatting.info_chip_number(host._action_runtime()._success_chance(skill_id, action)))
	_sync_action_stat_chip_title(xp_label, "XP")
	_sync_action_stat_chip_title(stamina_label, "STAM" if host._action_shows_stamina_stat(skill_id, action) else "")
	_sync_action_stat_chip_title(time_label, "TIME")
	_sync_action_stat_chip_title(success_label, "RATE")
	if is_convergence_card:
		stamina_box.visible = false
		success_box.visible = false

	return {
		"stat_row": stat_row,
		"xp": xp_label,
		"stamina": stamina_label,
		"time": time_label,
		"success": success_label,
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
		medal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		medal.texture = host._action_card_medal_texture_for_level(0)
		medal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		medal.z_index = 21
		art_panel.add_child(medal)
		mastery_progress = host._progress(Color("#f4bf35"), 56)
		mastery_progress.border_color = COLOR_INK
		host._apply_mastery_progress_bar_theme(mastery_progress, host._skill_theme_color(skill_id))
		mastery_progress.easing_speed = 5.0
		mastery_progress.z_index = 20
		copy.add_child(mastery_progress)
	return {"medal": medal, "mastery": mastery_progress}


func _detail_action_progress_widgets(card_root: Control, pop_card: Control, skill_id: String, action: Dictionary, content_width: float, uses_blue_guy_chicken_brawl_stage: bool) -> Dictionary:
	var progress: ActivityProgressRail = null
	var convergence_progress: ConvergenceMultiProgressBar = null
	var fluid_strip: Control = null
	if host._fishing_rework_active_for_skill(skill_id) and not host.fishing_runtime.action_should_render_standalone(host, skill_id, action):
		fluid_strip = host._attach_fishing_fluid_strip(pop_card, action)
	elif host._convergence_runtime()._is_convergence_action(action):
		convergence_progress = ConvergenceMultiProgressBar.new()
		convergence_progress.anchor_left = 0.0
		convergence_progress.anchor_right = 1.0
		convergence_progress.anchor_top = 1.0
		convergence_progress.anchor_bottom = 1.0
		convergence_progress.offset_left = host.ACTION_PROGRESS_RAIL_INSET + 18
		convergence_progress.offset_right = -host.ACTION_PROGRESS_RAIL_INSET - 18
		convergence_progress.offset_top = -host.CONVERGENCE_BAR_HEIGHT + 34
		convergence_progress.offset_bottom = 34
		convergence_progress.z_index = 234
		convergence_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pop_card.add_child(convergence_progress)
	elif not uses_blue_guy_chicken_brawl_stage and not host._fighting_runtime().action_uses_rooster_punch_out_stage(action):
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
		return ConvergenceBuildOverlay.build(pop_card, host.CONVERGENCE_BUILD_OVERLAY_COLOR, COLOR_INK, host.app_bold_font, host.app_font, host.MIN_MOBILE_BODY_FONT_SIZE)
	return {}


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
	for texture_path in host.BUILD_REQUIRED_PLANK_PIECE_TEXTURES:
		plank_textures.append(host.visual_texture_cache._texture_or_visual_fallback(str(texture_path)))
	return BuildableModuleOverlay.build(pop_card, str(action.get("name", "Module")), meta_text, BuildableModules.label(action).to_upper(), BuildableModules.can_pay(action, Callable(host.material_runtime, "amount")), COLOR_INK, host.app_bold_font, host.app_font, host.MIN_MOBILE_BODY_FONT_SIZE, plank_textures, cost, cost_icon_paths)


func _play_buildable_module_built_animation(skill_id: String, action: Dictionary, refresh_scroll: int) -> bool:
	var action_id := str(action.get("id", ""))
	var card_key: String = str(host._action_key(skill_id, action_id))
	if card_key.is_empty() or not action_cards.has(card_key):
		return false
	var card := action_cards[card_key] as Dictionary
	var overlay: Control = host._valid_control_ref(card.get("build_overlay"))
	var plank_layer: Control = host._valid_control_ref(card.get("build_plank_layer"))
	var cta: Control = host._valid_control_ref(card.get("build_cta"))
	var button: Control = host._valid_control_ref(card.get("build_button_panel"))
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
	host._render_screen(false, refresh_scroll)
	host._update_ui(0.0, true)


func _activity_lock_overlay(parent: Control, unlock_level: int, skill_id = "", requirements = []) -> Dictionary:
	var overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.clip_contents = false
	overlay.visible = false
	overlay.z_index = 280
	parent.add_child(overlay)

	var group = host.ActivityLockCluster.new()
	var theme_skill_id = skill_id if not skill_id.is_empty() else host.selected_skill_id
	group.setup(
		host.visual_texture_cache._texture(host.UNLOCK_CHAIN_LINK_TEXTURE),
		host._cropped_unlock_padlock_texture(),
		host.visual_texture_cache._texture(host.UNLOCK_LOCK_PULSE_MASK_TEXTURE),
		unlock_level,
		host.app_bold_font,
		host.app_font,
		host._cropped_unlock_padlock_image(),
		host._unlock_padlock_tint_mask_texture(),
		host._skill_theme_color(theme_skill_id),
		host.visual_texture_cache._texture(host.UNLOCK_LOCK_BODY_TEXTURE),
		host.visual_texture_cache._texture(host.UNLOCK_LOCK_SHACKLE_CLOSED_TEXTURE),
		host.visual_texture_cache._texture(host.UNLOCK_LOCK_SHACKLE_OPEN_TEXTURE),
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
	var group = host._valid_control_ref(overlay.get("group"))
	if group == null or action_id.is_empty():
		return
	group.padlock_clicked.connect(_on_activity_lock_clicked.bind(skill_id, action_id, group))


func _ensure_activity_lock_overlay(card: Dictionary, unlock_level: int) -> Dictionary:
	var existing = card.get("lock_overlay", {}) as Dictionary
	if not existing.is_empty():
		var root = host._valid_control_ref(existing.get("root"))
		var group = host._valid_control_ref(existing.get("group"))
		if root != null and group != null:
			return existing
	var pop_card = host._valid_control_ref(card.get("pop"))
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
	host._ensure_detail_lazy_entry_mounted(action_id)
	if host._fishing_rework_active_for_skill(skill_id):
		var fishing_method_card = host._fishing_method_card_for_action(skill_id, action_id)
		if not fishing_method_card.is_empty():
			return fishing_method_card
	var key = host._action_key(skill_id, action_id)
	if action_cards.has(key):
		var card = action_cards[key] as Dictionary
		if card != null and not card.is_empty():
			return card
	var preview_card = host._activity_preview_card_for_action_id(action_id)
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
	if host._stage_next_locked_activity_preview(false):
		host._fade_staged_next_locked_activity_preview(preview_id)


func _on_activity_lock_clicked(skill_id: String, action_id: String, group: Control) -> void:
	var action = host._action_data(skill_id, action_id)
	if action.is_empty():
		return
	var already_unlocked = host._is_action_unlocked(skill_id, action)
	if already_unlocked and not _action_has_pending_combo_requirement_lock(skill_id, action):
		return
	var card = _resolve_activity_unlock_card(skill_id, action_id)
	if _should_route_activity_unlock_to_fishing_method(card, skill_id, action_id):
		if group != null and group.has_method("consume_unlock_click"):
			group.call("consume_unlock_click")
		_hide_generic_activity_lock_overlay(card)
		host._on_fishing_method_lock_pressed(skill_id, action_id)
		return
	var clicked_requirement_index = _clicked_activity_requirement_index(group)
	if clicked_requirement_index >= 0:
		var requirement_states = host._activity_unlock_runtime()._action_requirement_states(skill_id, action)
		if clicked_requirement_index < requirement_states.size():
			var clicked_state = requirement_states[clicked_requirement_index] as Dictionary
			if bool(clicked_state.get("met", false)) and not bool(clicked_state.get("dismissed", false)):
				if group != null and group.has_method("consume_unlock_click"):
					group.call("consume_unlock_click")
				host._clear_pending_activity_readiness_action(skill_id, action_id)
				host.activity_unlock_detail_refresh_done = false
				host.activity_unlock_center_scroll_target = -1
				if card.is_empty():
					card = _resolve_activity_unlock_card(skill_id, action_id)
				var final_requirement_unlock = _action_requirement_unlocks_complete_after(skill_id, action, clicked_requirement_index)
				if final_requirement_unlock:
					var preview_after_unlock = host._preview_after_manual_activity_unlock(skill_id, action_id)
					host._set_activity_unlock_preview_after_ceremony(preview_after_unlock)
					host.activity_unlock_heist_preview_after_ceremony_id = host.thieving_state.heist_revealed_by_action_unlock(skill_id, action)
					if host.activity_unlock_heist_preview_after_ceremony_id.is_empty() and not host.activity_unlock_preview_after_ceremony_id.is_empty():
						host._prestage_activity_unlock_preview_card(host.activity_unlock_preview_after_ceremony_id)
				_play_activity_requirement_lock_dismissal(card, skill_id, action, clicked_requirement_index, group, final_requirement_unlock)
				host._set_result("%s unlocked." % str(action.get("name", "Activity")) if final_requirement_unlock else "%s lock opened." % host._skill_name(str(clicked_state.get("skill", skill_id))))
				return
	if not host._activity_unlock_runtime()._can_unlock_action(skill_id, action):
		_pulse_missing_action_requirements(group, skill_id, action)
		if group != null and group.has_method("consume_unlock_click"):
			group.call("consume_unlock_click")
		host._set_result("%s needs %s." % [str(action.get("name", "Activity")), _missing_action_requirements_text(skill_id, action)])
		return
	if group != null and group.has_method("consume_unlock_click"):
		group.call("consume_unlock_click")
	host._clear_pending_activity_readiness_action(skill_id, action_id)
	host.activity_unlock_detail_refresh_done = false
	host.activity_unlock_center_scroll_target = -1
	var ceremony_started = false
	var preview_after_unlock = host._preview_after_manual_activity_unlock(skill_id, action_id)
	if not card.is_empty() and not bool(card.get("unlock_ceremony_active", false)):
		card["unlock_ceremony_pending"] = true
		card["unlock_ceremony_finalized"] = false
		host._activity_unlock_runtime()._queue_manual_activity_unlock_for_ceremony(card, skill_id, action_id)
		card.erase("lock_overlay_sync_key")
		_sync_activity_lock_overlay(card, action, false)
		host._play_activity_unlock_ceremony(card, group)
		ceremony_started = true
	host._set_activity_unlock_preview_after_ceremony(preview_after_unlock)
	host.activity_unlock_heist_preview_after_ceremony_id = host.thieving_state.heist_revealed_by_action_unlock(skill_id, action)
	if host.activity_unlock_heist_preview_after_ceremony_id.is_empty() and not host.activity_unlock_preview_after_ceremony_id.is_empty():
		host._prestage_activity_unlock_preview_card(host.activity_unlock_preview_after_ceremony_id)
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
			host._play_activity_unlock_ceremony(card, group)
			ceremony_started = true
	host._set_result("%s unlocked." % str(action.get("name", "Activity")))
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
	var method_card = host._fishing_method_card_for_action(skill_id, action_id)
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
	var overlay = card.get("lock_overlay", {}) as Dictionary
	var overlay_root = host._valid_control_ref(overlay.get("root"))
	var shade = host._valid_canvas_item_ref(ActivityCardStyles.ensure_activity_card_shade(card, 0.50))
	var button = host._valid_button_ref(card.get("button"))
	var group_ref = host._weak_object_ref(group)
	var overlay_root_ref = host._weak_object_ref(overlay_root)
	var shade_ref = host._weak_object_ref(shade)
	var button_ref = host._weak_object_ref(button)
	if final_requirement_unlock:
		card["unlock_ceremony_pending"] = false
		card["unlock_ceremony_active"] = true
		card["unlock_ceremony_finalized"] = false
		card["unlock_ceremony_lock_rig"] = group
		card["unlock_ceremony_overlay_root"] = overlay_root
		host._activity_unlock_runtime()._queue_manual_activity_unlock_for_ceremony(card, skill_id, action_id)
		host.activity_unlock_ceremony_count += 1
		host.activity_unlock_ceremony_action_key = host._action_key(skill_id, action_id)
		var root = host._valid_control_ref(card.get("root"))
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
	await host.get_tree().create_timer(host.ActivityLockCluster.UNLOCK_DROP_SECONDS + 0.05).timeout
	if card.is_empty():
		return
	group = host._valid_control_ref(host._weak_ref_value(group_ref))
	overlay_root = host._valid_control_ref(host._weak_ref_value(overlay_root_ref))
	shade = host._valid_canvas_item_ref(host._weak_ref_value(shade_ref))
	button = host._valid_button_ref(host._weak_ref_value(button_ref))
	if final_requirement_unlock:
		card["requirement_lock_dismiss_active"] = false
		host._finish_activity_unlock_ceremony_safe(card, overlay_root, shade, button, true)
		await host._run_post_unlock_ceremony_preview(card)
		var preview_id = host.activity_unlock_preview_after_ceremony_id
		if host.activity_unlock_heist_preview_after_ceremony_id.is_empty() and not preview_id.is_empty():
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
	host._schedule_auto_unlock_pending_lockpads()


func _lock_click_tip_remaining_collapse_seconds() -> float:
	return maxf(0.0, float(host.lock_click_tip_collapse_until_msec - Time.get_ticks_msec()) / 1000.0)


func _stage_next_locked_activity_preview_after_tip_collapse(action_id: String) -> void:
	var delay = _lock_click_tip_remaining_collapse_seconds()
	if delay > 0.0:
		await host.get_tree().create_timer(delay).timeout
	if host.current_screen != "skill" or action_id.is_empty():
		return
	if host.activity_unlock_preview_after_ceremony_id != action_id:
		return
	if host._stage_next_locked_activity_preview(false):
		host._fade_staged_next_locked_activity_preview(action_id)


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
			"theme_color": host._skill_theme_color(requirement_skill)
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
		parts.append("%s Lv %s" % [host._skill_name(requirement_skill), requirement_level])
	for raw_required_boss in host._fighting_runtime().action_missing_boss_requirements(action):
		parts.append("%s cleared" % str(raw_required_boss).capitalize())
	if parts.is_empty():
		return "%s Lv %s" % [host._skill_name(skill_id), int(action.get("unlock", 1))]
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
	var skill_id = str(card.get("skill_id", host.selected_skill_id))
	var action_id = str(action.get("id", card.get("action_id", "")))
	var ready_pending = bool(card.get("unlock_ready_pending", false)) or host._action_has_pending_unlock_readiness(action_id)
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
	var overlay_root = host._valid_control_ref(overlay.get("root"))
	if overlay_root == null:
		return
	var rig = host._valid_control_ref(overlay.get("group"))
	if (
		rig != null
		and bool(rig.get("unlock_drop_active"))
		and not (rig.has_method("set_requirement_states") and lock_visible and not ceremony_active)
	):
		return
	if ceremony_active and rig != null:
		_set_activity_lock_overlay_active(overlay, true, true)
		rig.call("set_unlock_level", int(action.get("unlock", 1)))
		rig.call("set_theme_color", host._skill_theme_color(skill_id))
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
		rig.call("set_theme_color", host._skill_theme_color(skill_id))
		if lock_visible and not ceremony_active and rig.has_method("set_requirement_states"):
			rig.call("set_requirement_states", host._activity_unlock_runtime()._action_requirement_states(skill_id, action))
		else:
			rig.call("set_lock_state", _activity_lock_visual_state(skill_id, action, unlocked, ceremony_active, lock_visible))


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
		return host.ActivityLockRig.LOCK_STATE_DROPPING
	if not lock_visible:
		return host.ActivityLockRig.LOCK_STATE_GONE
	if (not unlocked) and host._activity_unlock_runtime()._can_unlock_action(skill_id, action):
		return host.ActivityLockRig.LOCK_STATE_READY_OPEN
	return host.ActivityLockRig.LOCK_STATE_CLOSED


func _set_activity_lock_overlay_active(overlay: Dictionary, active: bool, skip_rig_reset = false) -> void:
	var overlay_root = host._valid_control_ref(overlay.get("root"))
	if overlay_root != null:
		overlay_root.visible = active
		overlay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rig = host._valid_control_ref(overlay.get("group"))
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
				rig.call("set_lock_state", host.ActivityLockRig.LOCK_STATE_GONE)


func _prepare_activity_unlock_ceremony_overlay(card: Dictionary, lock_rig: Control = null) -> void:
	var overlay = card.get("lock_overlay", {}) as Dictionary
	if overlay.is_empty():
		overlay = _ensure_activity_lock_overlay(card, int((card.get("action", {}) as Dictionary).get("unlock", 1)))
		if overlay.is_empty():
			return
	var overlay_root = host._valid_control_ref(overlay.get("root"))
	var rig = host._valid_control_ref(lock_rig) if lock_rig != null else host._valid_control_ref(overlay.get("group"))
	if overlay_root != null:
		overlay_root.visible = true
		overlay_root.modulate = Color.WHITE
	if rig != null:
		rig.visible = true
		rig.modulate = Color.WHITE
		rig.set_process(true)
		rig.call_deferred("_layout_base")
	var shade = host._valid_canvas_item_ref(ActivityCardStyles.ensure_activity_card_shade(card, 0.50))
	if shade != null:
		shade.visible = true
		shade.modulate = Color.WHITE


func _reset_activity_lock_overlay_pieces(card: Dictionary) -> void:
	var overlay = card.get("lock_overlay", {}) as Dictionary
	for key in ["group"]:
		var piece = host._valid_control_ref(overlay.get(key))
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
	var stat_kind = host.expanded_activity_stat_kind if host.expanded_activity_stat_key == key else ""
	var expanded = not stat_kind.is_empty()
	var root = card.get("root") as Control
	var visual_key = "%s:%s" % [stat_kind, host._skill_theme_color(skill_id).to_html(true)]
	if (
		not instant
		and not expanded
		and not host._action_info_chips_blocked_by_lock(card)
		and str(card.get("stat_popup_visual_key", "")) == visual_key
		and not bool(card.get("bonus_expanded", false))
		and not card.has("bonus_tween")
		and not card.has("bonus_content_tween")
	):
		return
	if host._action_info_chips_blocked_by_lock(card):
		if host.expanded_activity_stat_key == key:
			host.expanded_activity_stat_key = ""
			host.expanded_activity_stat_kind = ""
		_sync_activity_stat_box_styles(card, "")
		_set_activity_card_expanded(card, card.get("root") as Control, false, instant)
		return
	if str(card.get("stat_popup_visual_key", "")) != visual_key:
		card["stat_popup_visual_key"] = visual_key
		var bg = card.get("bg") as RoundedTextureRect
		if bg != null:
			bg.art_height = host.ACTION_CARD_HEIGHT
			bg.feather_height = 170.0
			bg.fallback_color = host._themed_activity_card_fill_color(host._skill_theme_color(skill_id))
			bg._update_mask_params()
		var border = card.get("border") as ActivityCardBorder
		if border != null:
			border.border_color = host.COLOR_INK
			border.border_width = 8.0
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
		host._set_control_minimum_height(root, 0.0)
		if entry != null and is_instance_valid(entry):
			host._set_control_minimum_height(entry, 0.0)
		root.visible = true
		root.modulate = Color(1, 1, 1, 0)
		root.clip_contents = true
		return
	if bool(root.get_meta("module_ui_collapsed_squeeze", false)):
		var collapsed_height = host._module_collapsed_squeeze_height()
		var mat_collection = card.get("mat_collection", {}) as Dictionary
		var mat_collection_height = host.MAT_COLLECTION_AREA_HEIGHT if (not mat_collection.is_empty() and bool(mat_collection.get("visible", false))) else 0.0
		host._set_module_root_layout_height(root, collapsed_height)
		root.clip_contents = false
		host._set_collapsed_module_visual_clipping(root, str(root.get_meta("module_ui_key", "")), true)
		host._material_collection_surface()._sync_mat_collection_row_position(card, collapsed_height)
		if entry != null and is_instance_valid(entry):
			host._set_module_root_layout_height(entry, collapsed_height + mat_collection_height)
			host._update_detail_lazy_entry_height_for_card(card, collapsed_height + mat_collection_height)
		host._app_lifecycle_runtime()._kill_card_tween(card, "bonus_tween")
		card["bonus_expanded"] = false
		return
	var action = card.get("action", {}) as Dictionary
	var target_height = host._activity_card_root_height_for_action(action, expanded)
	var mat_collection = card.get("mat_collection", {}) as Dictionary
	var mat_collection_height = host.MAT_COLLECTION_AREA_HEIGHT if (not mat_collection.is_empty() and bool(mat_collection.get("visible", false))) else 0.0
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
		host._update_detail_lazy_entry_height_for_card(card, target_entry_height)
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
	tween.finished.connect(host._update_detail_lazy_entry_height_for_card.bind(card, target_entry_height))


func _finish_activity_card_expanded(card_key: String, bonus_root_id: int, expanded: bool) -> void:
	if bonus_root_id != 0 and not expanded:
		var cb_bonus_root = host._valid_control_ref(instance_from_id(bonus_root_id))
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
	host._set_label_text_if_changed(title, str(details.get("title", "")))
	host._set_label_text_if_changed(original, "Original: %s" % str(details.get("original", "")))
	host._set_label_text_if_changed(current, "Current: %s" % str(details.get("current", "")))
	var bonus_lines = details.get("bonuses", []) as Array
	host._set_label_text_if_changed(bonuses, "Bonuses:\n%s" % _format_activity_bonus_lines(bonus_lines))


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
		packed.append("No active bonuses yet")
	return "\n".join(packed)


func _format_xp_reward_parts(parts: Array, use_full_names := false) -> String:
	var packed := PackedStringArray()
	for raw_part in parts:
		if typeof(raw_part) != TYPE_DICTIONARY:
			continue
		var part := raw_part as Dictionary
		var reward_skill_id := str(part.get("skill", ""))
		var label: String = host._skill_name(reward_skill_id) if use_full_names else host._skill_short_code(reward_skill_id)
		packed.append("+%s %s" % [GameFormatting.info_chip_number(float(part.get("amount", 0))), label])
	if packed.is_empty():
		packed.append("+0 XP")
	return " / ".join(packed)


func _activity_xp_bonus_lines_for_rewards(owner_skill_id: String, action: Dictionary) -> Array:
	var lines := []
	var rewards: Dictionary = host._base_xp_reward_map(action, owner_skill_id)
	var medal_xp := AchievementState.global_medal_bonus(host, "xp_mult")
	var ad_xp: float = host._ad_bonus_runtime().xp_multiplier()
	if medal_xp > 0.0:
		lines.append("+%s%% global medal XP" % GameFormatting.percent_points(medal_xp * 100.0))
	if ad_xp > 0.0:
		lines.append("+%s%% ad XP" % GameFormatting.percent_points(ad_xp * 100.0))
	for raw_reward_skill_id in host._ordered_xp_reward_skill_ids(owner_skill_id, rewards):
		var reward_skill_id := str(raw_reward_skill_id)
		var achievement_xp := AchievementState.reward_bonus(AchievementState.milestones(host), "xp_mult", reward_skill_id)
		if achievement_xp > 0.0:
			lines.append("+%s%% %s achievement XP" % [GameFormatting.percent_points(achievement_xp * 100.0), host._skill_name(reward_skill_id)])
	if rewards.has(owner_skill_id) and host._plank_bonus_applies(owner_skill_id):
		lines.append("+5% plank build XP")
	if rewards.has(owner_skill_id) and host._hub_runtime().mission_bonus_applies(owner_skill_id, action):
		lines.append("+%s%% mission board XP" % GameFormatting.percent_points(host._hub_runtime().mission_xp_bonus() * 100.0))
	if lines.is_empty():
		lines.append("No active XP bonuses yet")
	return lines


func _activity_stat_bonus_details(skill_id: String, action: Dictionary, stat_kind: String) -> Dictionary:
	match stat_kind:
		"xp":
			var base_parts = host._base_xp_reward_parts_for_display(skill_id, action)
			var current_parts = host._action_xp_reward_parts_for_display(skill_id, action)
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
			if host._hub_runtime().mission_bonus_applies(skill_id, action):
				stamina_lines.append("-%s%% mission board stamina" % GameFormatting.percent_points(host._hub_runtime().mission_stamina_reduction() * 100.0))
			if stamina_lines.is_empty():
				stamina_lines.append("No stamina cost bonuses yet")
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
			if medal_speed > 0.0:
				time_lines.append("-%s%% global medal speed" % GameFormatting.percent_points(medal_speed * 100.0))
			if achievement_speed > 0.0:
				time_lines.append("-%s%% achievement speed" % GameFormatting.percent_points(achievement_speed * 100.0))
			if activity_medal_speed > 0.0:
				time_lines.append_array(AchievementState.activity_medal_buff_lines(host, skill_id, action, "time", "-"))
			if ad_speed > 0.0:
				time_lines.append("-%s%% ad speed" % GameFormatting.percent_points(ad_speed * 100.0))
			if host._hub_runtime().mission_bonus_applies(skill_id, action):
				time_lines.append("-%s%% mission board speed" % GameFormatting.percent_points(host._hub_runtime().mission_time_reduction() * 100.0))
			if time_lines.is_empty():
				time_lines.append("No active time bonuses yet")
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
				success_lines.append("+%s%% %s medal" % [GameFormatting.percent_points(float(medal_level)), host._mastery_medal_name(medal_level)])
			var activity_medal_accuracy = AchievementState.activity_medal_accuracy_bonus(host, skill_id, action)
			if activity_medal_accuracy > 0.0:
				success_lines.append_array(AchievementState.activity_medal_buff_lines(host, skill_id, action, "accuracy", "+"))
			if not host._fishing_rework_active_for_skill(skill_id):
				var success_before_barn = clampf(base_success + medal_success + achievement_success + float(medal_level) + activity_medal_accuracy, 5.0, 100.0)
				var barn_bonus = (100.0 - success_before_barn) * host._hub_surface()._hub_barn_failure_factor()
				if barn_bonus > 0.0:
					success_lines.append("+%s%% Barn reliability" % GameFormatting.percent_points(barn_bonus))
				var trophy_success = host._hub_runtime().trophy_success_bonus() * 100.0
				if trophy_success > 0.0:
					success_lines.append("+%s%% Trophy display" % GameFormatting.percent_points(trophy_success))
			if host._action_runtime()._success_chance(skill_id, action) >= 100.0:
				success_lines.append("RATE maxed at 100%")
			if success_lines.is_empty():
				success_lines.append("No active rate bonuses yet")
			return {
				"title": "RATE",
				"original": "%s%%" % GameFormatting.percent_points(base_success),
				"current": "%s%%" % GameFormatting.percent_points(host._action_runtime()._success_chance(skill_id, action)),
				"bonuses": success_lines
			}
	return {"title": "", "original": "", "current": "", "bonuses": []}


func _activity_stat_bonus_panel() -> Dictionary:
	var root = HBoxContainer.new()
	root.custom_minimum_size = Vector2(0, 282)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 54)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.modulate.a = 0.0
	root.visible = false
	var values = VBoxContainer.new()
	values.custom_minimum_size = Vector2(570, 0)
	values.add_theme_constant_override("separation", 8)
	values.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(values)
	var title = _activity_bonus_label("", 62)
	values.add_child(title)
	var original = _activity_bonus_label("", 52)
	values.add_child(original)
	var current = _activity_bonus_label("", 58)
	values.add_child(current)
	var bonus_column = VBoxContainer.new()
	bonus_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bonus_column.add_theme_constant_override("separation", 8)
	bonus_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bonus_column)
	var bonuses = _activity_bonus_label("", 52)
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
		var root = host._valid_control_ref(existing.get("root"))
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


func _build_detail_lazy_plan(skill_id: String) -> Array:
	var plan = []
	var y = 0.0
	var activity_start_tip_pending = host._activity_start_inline_tip_available(skill_id)
	var skill_swipe_tip_pending = not activity_start_tip_pending and host._onboarding_runtime()._skill_swipe_tip_available()
	var skill_swipe_tip_anchor_track_id = host._skill_swipe_tip_anchor_track_id(skill_id)
	for entry in host._visible_detail_entries_for_skill(skill_id):
		var entry_data = entry as Dictionary
		var track_id = host._detail_lazy_track_id_for_entry(entry_data)
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
		if str(entry_data.get("kind", "")) == "thieving_heist":
			lazy_entry["kind"] = "heist"
		elif host._is_passive_action(entry_data.get("action", {}) as Dictionary):
			lazy_entry["kind"] = "passive"
		lazy_entry["height"] = host._detail_lazy_entry_height(lazy_entry)
		var module_key = host._detail_lazy_module_ui_key(lazy_entry, skill_id)
		if not module_key.is_empty() and host._module_ui_is_collapsed(module_key):
			lazy_entry["height"] = host._module_collapsed_squeeze_height()
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
			if host._should_show_lock_click_tip(skill_id, action):
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
	var cached_root = host._valid_control_ref(lazy_entry.get("cached_root"))
	if cached_root == null or cached_root.is_queued_for_deletion():
		lazy_entry.erase("cached_root")
		lazy_entry.erase("cached_card")
		lazy_entry.erase("cached_built")
		return false
	var stack_host = host._valid_control_ref(lazy_entry.get("stack_host"))
	if stack_host == null or not is_instance_valid(stack_host):
		return false
	var track_id = str(lazy_entry.get("track_id", ""))
	if track_id.is_empty():
		return false
	var kind = host._detail_lazy_entry_kind(lazy_entry)
	var cached_card = lazy_entry.get("cached_card", {}) as Dictionary
	if kind == "heist":
		host._discard_detail_lazy_cached_root(lazy_entry)
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
		host._set_canvas_item_modulate_if_changed(cached_root, Color.WHITE)
		host._enable_interactive_control_tree(cached_root)
		lazy_entry["stack_host"] = cached_root
		lazy_entry["placeholder"] = null
		detail_action_card_nodes[track_id] = cached_root
		lazy_entry["mounted"] = true
		host._mark_detail_lazy_module_mounted(cached_root)
		return true
	if kind == "fishing_area":
		var placeholder = host._valid_control_ref(lazy_entry.get("placeholder"))
		host._detail_lazy_prepare_host_for_mount(stack_host, placeholder)
		lazy_entry["placeholder"] = null
		if cached_root.get_parent() != null:
			cached_root.get_parent().remove_child(cached_root)
		cached_root = host._apply_lazy_entry_module_squeeze(cached_root, lazy_entry, skill_id)
		cached_root.visible = true
		host._enable_interactive_control_tree(cached_root)
		host._detail_lazy_add_child_to_host(stack_host, cached_root, content_width, actions_width)
		var cached_built = lazy_entry.get("cached_built", {}) as Dictionary
		var area_key = track_id
		var area_card = cached_card
		if not cached_built.is_empty():
			area_key = str(cached_built.get("area_key", track_id))
			area_card = cached_built.get("area_card", cached_card) as Dictionary
			lazy_entry["built"] = cached_built
		host._register_action_card(area_key, area_card)
		lazy_entry["card"] = area_card
		detail_action_card_nodes[area_key] = stack_host
		for raw_method_id in lazy_entry.get("method_ids", []) as Array:
			detail_action_card_nodes[str(raw_method_id)] = stack_host
		if fade_in:
			host._play_detail_lazy_fade_in(cached_root)
		lazy_entry["mounted"] = true
		host._mark_detail_lazy_module_mounted(stack_host)
		return true
	if kind == "fishing_offer":
		var placeholder = host._valid_control_ref(lazy_entry.get("placeholder"))
		host._detail_lazy_prepare_host_for_mount(stack_host, placeholder)
		lazy_entry["placeholder"] = null
		if cached_root.get_parent() != null:
			cached_root.get_parent().remove_child(cached_root)
		cached_root = host._apply_lazy_entry_module_squeeze(cached_root, lazy_entry, skill_id)
		cached_root.visible = true
		host._enable_interactive_control_tree(cached_root)
		host._detail_lazy_add_child_to_host(stack_host, cached_root, content_width, actions_width)
		if fade_in:
			host._play_detail_lazy_fade_in(cached_root)
		lazy_entry["mounted"] = true
		host._mark_detail_lazy_module_mounted(stack_host)
		return true
	if not host._detail_lazy_kind_is_action_backed(kind):
		return false
	var placeholder = host._valid_control_ref(lazy_entry.get("placeholder"))
	host._detail_lazy_prepare_host_for_mount(stack_host, placeholder)
	lazy_entry["placeholder"] = null
	if cached_root.get_parent() != null:
		cached_root.get_parent().remove_child(cached_root)
	cached_root = host._apply_lazy_entry_module_squeeze(cached_root, lazy_entry, skill_id)
	cached_root.visible = true
	host._enable_interactive_control_tree(cached_root)
	host._detail_lazy_add_child_to_host(stack_host, cached_root, content_width, actions_width)
	if fade_in:
		host._play_detail_lazy_fade_in(cached_root)
	if cached_card.is_empty():
		return false
	var action = (lazy_entry.get("entry") as Dictionary).get("action", {}) as Dictionary
	cached_card["entry"] = stack_host
	host._register_action_card(host._action_key(skill_id, track_id), cached_card)
	lazy_entry["card"] = cached_card
	host._detail_lazy_finalize_action_card(cached_card, skill_id, action, track_id)
	detail_action_card_nodes[track_id] = stack_host
	lazy_entry["mounted"] = true
	host._mark_detail_lazy_module_mounted(stack_host)
	return true

func _detail_lazy_mount_item(lazy_entry: Dictionary, skill_id: String, content_width: float, actions_width: float, fade_in: bool) -> bool:
	if bool(lazy_entry.get("mounted", false)):
		return false
	var trace_mount = OS.get_environment("IDLE_ELITE_TRACE_PROCESS_SLOW") == "1"
	var trace_mount_skill = OS.get_environment("IDLE_ELITE_TRACE_PROCESS_SKILL")
	if trace_mount and not trace_mount_skill.is_empty() and skill_id != trace_mount_skill:
		trace_mount = false
	var trace_started_usec = Time.get_ticks_usec() if trace_mount else 0
	var kind = host._detail_lazy_entry_kind(lazy_entry)
	var stack_host = host._valid_control_ref(lazy_entry.get("stack_host"))
	var placeholder = host._valid_control_ref(lazy_entry.get("placeholder"))
	if stack_host == null or not is_instance_valid(stack_host):
		return false
	var track_id = str(lazy_entry.get("track_id", ""))
	if host._fishing_ui_surface()._fishing_ablation_enabled("plain_fishing_modules") and skill_id == "fishing" and host._detail_lazy_kind_is_fishing_module(kind):
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
		"heist":
			var heist = (lazy_entry.get("entry") as Dictionary).get("heist", {}) as Dictionary
			var heist_root = host._thieving_surface()._build_thieving_heist_card(heist, actions_width)
			heist_root = host._apply_lazy_entry_module_squeeze(heist_root, lazy_entry, skill_id)
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
			var defer_passive_loot = skill_swipe_pending_full_finalize or host._skill_swipe_handoff_cover_is_opaque_cream_transition()
			var passive_card = host._passive_firepit_surface()._build_passive_module_card(skill_id, action, content_width, true, defer_passive_loot)
			var passive_root = passive_card["root"] as Control
			passive_root = host._apply_lazy_entry_module_squeeze(passive_root, lazy_entry, skill_id)
			host._detail_lazy_prepare_host_for_mount(stack_host, placeholder)
			lazy_entry["placeholder"] = null
			host._detail_lazy_add_child_to_host(stack_host, passive_root, content_width, actions_width)
			var card = passive_card["card"] as Dictionary
			card["entry"] = stack_host
			host._register_action_card(host._action_key(skill_id, track_id), card)
			lazy_entry["card"] = card
			host._detail_lazy_finalize_action_card(card, skill_id, action, track_id)
			detail_action_card_nodes[track_id] = stack_host
			fade_target = passive_root
			fade_allowed = host._detail_lazy_fade_allowed(skill_id, action)
			mounted_ok = true
		"action":
			var action = (lazy_entry.get("entry") as Dictionary).get("action", {}) as Dictionary
			var built = _build_detail_interactive_action_card(skill_id, action, content_width, actions_width)
			var card_root = built["card_root"] as Control
			card_root = host._apply_lazy_entry_module_squeeze(card_root, lazy_entry, skill_id)
			host._detail_lazy_prepare_host_for_mount(stack_host, placeholder)
			lazy_entry["placeholder"] = null
			host._detail_lazy_add_child_to_host(stack_host, card_root, content_width, actions_width)
			var card = built["card"] as Dictionary
			card["entry"] = stack_host
			host._register_action_card(host._action_key(skill_id, track_id), card)
			lazy_entry["card"] = card
			host._detail_lazy_finalize_action_card(card, skill_id, action, track_id)
			detail_action_card_nodes[track_id] = stack_host
			fade_target = card_root
			fade_allowed = host._detail_lazy_fade_allowed(skill_id, action)
			mounted_ok = true
		"fishing_area":
			var area_def = lazy_entry.get("area_def", {}) as Dictionary
			if not area_def.is_empty():
				var built = host._fishing_ui_surface()._build_fishing_area_module(skill_id, area_def, content_width)
				var root = built.get("root") as Control
				if root != null and is_instance_valid(root):
					root = host._apply_lazy_entry_module_squeeze(root, lazy_entry, skill_id)
					host._detail_lazy_prepare_host_for_mount(stack_host, placeholder)
					lazy_entry["placeholder"] = null
					host._detail_lazy_add_child_to_host(stack_host, root, content_width, actions_width)
					var area_key = str(built.get("area_key", track_id))
					var area_card = built.get("area_card", {}) as Dictionary
					host._register_action_card(area_key, area_card)
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
				offer_root = host._apply_lazy_entry_module_squeeze(offer_root, lazy_entry, skill_id)
				host._detail_lazy_prepare_host_for_mount(stack_host, placeholder)
				lazy_entry["placeholder"] = null
				host._detail_lazy_add_child_to_host(stack_host, offer_root, content_width, actions_width)
				fade_target = offer_root
				fade_allowed = true
				mounted_ok = true
		"lock_tip":
			host._detail_lazy_prepare_host_for_mount(stack_host, placeholder)
			lazy_entry["placeholder"] = null
			host._detail_lazy_add_child_to_host(stack_host, host._lock_click_tip_note(content_width), content_width, actions_width)
			mounted_ok = true
		"activity_start_tip":
			host._detail_lazy_prepare_host_for_mount(stack_host, placeholder)
			lazy_entry["placeholder"] = null
			var start_note = host._activity_start_tip_note(content_width)
			host._detail_lazy_add_child_to_host(stack_host, start_note, content_width, actions_width)
			host._fade_in_activity_start_tip_note(start_note)
			mounted_ok = true
		"skill_swipe_tip":
			host._detail_lazy_prepare_host_for_mount(stack_host, placeholder)
			lazy_entry["placeholder"] = null
			var swipe_note = host._skill_swipe_tip_note(content_width)
			swipe_note.modulate = Color(1, 1, 1, 0)
			host._detail_lazy_add_child_to_host(stack_host, swipe_note, content_width, actions_width)
			host.call_deferred("_fade_in_skill_swipe_tip_note", swipe_note)
			mounted_ok = true
	if not mounted_ok:
		return false
	lazy_entry["mounted"] = true
	host._mark_detail_lazy_module_mounted(host._valid_control_ref(lazy_entry.get("stack_host")))
	if fade_in and fade_allowed and fade_target != null and not boot_detail_render_in_progress:
		host._play_detail_lazy_fade_in(fade_target)
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
	var stack_host = host._valid_control_ref(lazy_entry.get("stack_host"))
	if stack_host == null or not is_instance_valid(stack_host):
		return false
	var placeholder = host._valid_control_ref(lazy_entry.get("placeholder"))
	var kind = host._detail_lazy_entry_kind(lazy_entry)
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
	host._detail_lazy_prepare_host_for_mount(stack_host, placeholder)
	lazy_entry["placeholder"] = null
	host._detail_lazy_add_child_to_host(stack_host, panel, content_width, actions_width)
	lazy_entry["mounted"] = true
	host._mark_detail_lazy_module_mounted(stack_host)
	if not track_id.is_empty():
		detail_action_card_nodes[track_id] = stack_host
	return true

func _sync_detail_lazy_visible_cards(instant: bool, max_mounts: int = -1) -> int:
	if detail_lazy_plan.is_empty() or host._valid_control_ref(detail_lazy_stack) == null or host._valid_control_ref(detail_actions_scroll) == null:
		return 0
	var pinned = host._detail_lazy_pinned_track_ids()
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
			and host._detail_lazy_entry_in_viewport(lazy_entry)
		)
		if max_mounts >= 0 and mounted_count >= max_mounts and not cached_visible_fishing_entry:
			continue
		if not host._detail_lazy_should_mount_entry(lazy_entry, pinned, plan_index):
			continue
		var had_cached_root = lazy_entry.has("cached_root")
		var fade_in = (not instant) and not detail_scroll_visual_work_this_frame
		if _detail_lazy_mount_item(lazy_entry, selected_skill_id, content_width, actions_width, fade_in):
			if not (cached_visible_fishing_entry and had_cached_root):
				mounted_count += 1
	detail_lazy_mount_trace_context = previous_mount_context
	detail_lazy_last_scroll = host._detail_lazy_scroll_y()
	return mounted_count

func _sync_detail_lazy_next_cards(instant: bool, max_mounts: int = 1) -> int:
	if detail_lazy_plan.is_empty() or host._valid_control_ref(detail_lazy_stack) == null or host._valid_control_ref(detail_actions_scroll) == null:
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

func _detail_lazy_entry_far_from_viewport(lazy_entry: Dictionary) -> bool:
	var scroll_y = host._detail_lazy_scroll_y()
	var unmount_buffer = host._detail_lazy_unmount_buffer_px()
	var view_top = scroll_y - unmount_buffer
	var view_bottom = scroll_y + host._detail_lazy_viewport_height() + unmount_buffer
	var entry_rect = host._detail_lazy_entry_rect_for_viewport(lazy_entry)
	var entry_y = entry_rect.position.y
	var entry_bottom = entry_y + entry_rect.size.y
	return entry_rect.size.y > 1.0 and (entry_bottom < view_top or entry_y > view_bottom)

func _detail_lazy_can_unmount_entry(lazy_entry: Dictionary, pinned: Dictionary) -> bool:
	if not bool(lazy_entry.get("mounted", false)):
		return false
	var kind = host._detail_lazy_entry_kind(lazy_entry)
	if not host._detail_lazy_kind_is_module(kind):
		return false
	if host._fishing_rework_active_for_skill(selected_skill_id) and host._detail_lazy_kind_is_fishing_module(kind):
		return false
	var track_id = str(lazy_entry.get("track_id", ""))
	if track_id.is_empty() or host._detail_lazy_entry_is_pinned(lazy_entry, pinned):
		return false
	return _detail_lazy_entry_far_from_viewport(lazy_entry)

func _detail_lazy_unmount_item(lazy_entry: Dictionary, skill_id: String, content_width: float) -> bool:
	var stack_host = host._valid_control_ref(lazy_entry.get("stack_host"))
	if stack_host == null or not is_instance_valid(stack_host):
		return false
	var track_id = str(lazy_entry.get("track_id", ""))
	if track_id.is_empty():
		return false
	var kind = host._detail_lazy_entry_kind(lazy_entry)
	var mounted_card = lazy_entry.get("card", {}) as Dictionary
	host._kill_transient_tweens_in_subtree(stack_host)
	if DisplayServer.get_name() == "headless":
		host._fill_headless_null_textures(stack_host)
	var cached_root: Control = null
	var should_cache_unmounted_root = not host._fishing_rework_active_for_skill(skill_id)
	if should_cache_unmounted_root and host._detail_lazy_kind_is_fishing_module(kind):
		for child in stack_host.get_children():
			var child_control = child as Control
			if child_control == null or bool(child_control.get_meta("detail_lazy_placeholder", false)):
				continue
			cached_root = child_control
			break
		if cached_root != null and is_instance_valid(cached_root):
			host._park_detail_lazy_cached_root(cached_root)
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
	placeholder.custom_minimum_size = Vector2(content_width, float(lazy_entry.get("height", host._activity_card_root_height())))
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
			host._park_detail_lazy_cached_root(cached_root)
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
		host._discard_fishing_area_module_card_keys(track_id, mounted_card, skill_id)
	elif kind != "fishing_offer":
		detail_action_card_nodes.erase(track_id)
		var card_key = host._thieving_surface()._thieving_heist_card_key(track_id.substr("heist:".length())) if track_id.begins_with("heist:") else host._action_key(skill_id, track_id)
		host._discard_action_card_key(card_key)
	lazy_entry.erase("card")
	return true

func _prune_detail_lazy_far_cards(max_unmounts: int = 2) -> int:
	if not DETAIL_LAZY_UNMOUNT_ENABLED:
		return 0
	if detail_lazy_plan.is_empty() or host._valid_control_ref(detail_lazy_stack) == null or boot_detail_render_in_progress:
		return 0
	if not module_ui_pending_pin_scroll_anchor.is_empty():
		return 0
	if module_ui_recent_pin_prune_hold_skill_id == selected_skill_id and Time.get_ticks_msec() < module_ui_recent_pin_prune_hold_until_msec:
		return 0
	var pinned = host._detail_lazy_pinned_track_ids()
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
	if host.detail_lazy_all_mounted_cache_frame == current_frame:
		return host.detail_lazy_all_mounted_cache_value
	host.detail_lazy_all_mounted_cache_frame = current_frame
	host.detail_lazy_all_mounted_cache_value = true
	for raw_lazy_entry in detail_lazy_plan:
		var lazy_entry := raw_lazy_entry as Dictionary
		if not bool(lazy_entry.get("mounted", false)):
			host.detail_lazy_all_mounted_cache_value = false
			break
	return host.detail_lazy_all_mounted_cache_value

func _detail_lazy_mount_initial_window_sync(instant := true, mount_count: int = 2) -> int:
	var target = mini(mount_count, detail_lazy_plan.size())
	var mounted_count = 0
	var pinned = host._detail_lazy_pinned_track_ids()
	var previous_mount_context = detail_lazy_mount_trace_context
	detail_lazy_mount_trace_context = "initial_window_sync"
	for plan_index in range(detail_lazy_plan.size()):
		var lazy_entry = detail_lazy_plan[plan_index] as Dictionary
		if bool(lazy_entry.get("mounted", false)):
			continue
		if plan_index >= target and not host._detail_lazy_entry_is_pinned(lazy_entry, pinned):
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
	if host.skill_swipe_queued_offset != 0:
		if host.skill_swipe_handoff_cover != null and is_instance_valid(host.skill_swipe_handoff_cover):
			host._set_canvas_item_visible_if_changed(host.skill_swipe_handoff_cover, true)
			host._set_canvas_item_modulate_if_changed(host.skill_swipe_handoff_cover, Color.WHITE)
			host.skill_swipe_outgoing_cover_active = true
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
			host._rebuild_skill_detail_after_preview(missing_restore_scroll)
		skill_swipe_finalized_lazy_mount_pending = false
		return
	var cover = host.skill_swipe_handoff_cover
	var process_frame := Engine.get_process_frames()
	if (
		cover != null
		and is_instance_valid(cover)
		and host._skill_swipe_handoff_cover_is_opaque_cream_transition()
		and int(cover.get_meta("swipe_cover_last_lazy_mount_process_frame", -1)) == process_frame
	):
		_schedule_mount_swipe_finalized_lazy_cards(target_skill_id, token, mounted_total)
		return
	var mounted := _sync_detail_lazy_next_cards(true, 1)
	if mounted > 0:
		detail_lazy_mounted_this_frame = true
		if cover != null and is_instance_valid(cover) and host._skill_swipe_handoff_cover_is_opaque_cream_transition():
			cover.set_meta("swipe_cover_last_lazy_mount_process_frame", process_frame)
	var next_total := mounted_total + mounted
	if mounted <= 0 and not host._skill_detail_stack_is_presentable(detail_lazy_stack):
		if host._ensure_finalized_skill_detail_presentable(target_skill_id):
			Callable(host, "_sync_detail_actions_scroll_limit_deferred").call_deferred()
			if host._consume_queued_skill_swipe_navigation():
				skill_swipe_finalized_lazy_mount_pending = false
				return
			skill_swipe_finalized_lazy_mount_pending = false
			host._fade_clear_skill_swipe_rebuild_cover()
		else:
			var blank_restore_scroll := -1
			if detail_actions_scroll != null and is_instance_valid(detail_actions_scroll):
				blank_restore_scroll = detail_actions_scroll.scroll_vertical
			host._rebuild_skill_detail_after_preview(blank_restore_scroll)
			skill_swipe_finalized_lazy_mount_pending = false
		return
	if mounted > 0 and next_total < SKILL_SWIPE_FINALIZE_VISIBLE_MOUNT_LIMIT:
		_schedule_mount_swipe_finalized_lazy_cards(target_skill_id, token, next_total)
		return
	if next_total < SKILL_SWIPE_FINALIZE_VISIBLE_MOUNT_LIMIT and not host._skill_detail_stack_has_visible_modules(detail_lazy_stack):
		_schedule_mount_swipe_finalized_lazy_cards(target_skill_id, token, next_total)
		return
	if next_total < SKILL_SWIPE_FINALIZE_VISIBLE_MOUNT_LIMIT:
		_schedule_mount_swipe_finalized_lazy_cards(target_skill_id, token, next_total)
		return
	Callable(host, "_sync_detail_actions_scroll_limit_deferred").call_deferred()
	if not host._ensure_finalized_skill_detail_presentable(target_skill_id):
		if next_total < SKILL_SWIPE_FINALIZE_VISIBLE_MOUNT_LIMIT:
			_schedule_mount_swipe_finalized_lazy_cards(target_skill_id, token, next_total)
		else:
			var restore_scroll := -1
			if detail_actions_scroll != null and is_instance_valid(detail_actions_scroll):
				restore_scroll = detail_actions_scroll.scroll_vertical
			host._rebuild_skill_detail_after_preview(restore_scroll)
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
		host._rebuild_skill_detail_after_preview(0 if selected_skill_id == "thieving" else maxi(0, preserve_scroll))
		return
	var preview_page = skill_swipe_page
	var preview_scroll = preview_state.get("actions_scroll") as MobileScrollContainer
	if preview_scroll == null or not is_instance_valid(preview_scroll):
		preview_scroll = host._find_skill_preview_actions_scroll(preview_page) as MobileScrollContainer
	if preview_scroll == null or not is_instance_valid(preview_scroll):
		if trace_finalize:
			print("SWIPE_FINALIZE_TRACE fallback=missing_scroll us=%s" % str(Time.get_ticks_usec() - trace_start))
		skill_swipe_pending_full_finalize = false
		host._rebuild_skill_detail_after_preview(0 if selected_skill_id == "thieving" else maxi(0, preserve_scroll))
		return
	var stack = host._find_skill_preview_stack(preview_page) as VBoxContainer
	if stack == null or not is_instance_valid(stack):
		if trace_finalize:
			print("SWIPE_FINALIZE_TRACE fallback=missing_stack us=%s" % str(Time.get_ticks_usec() - trace_start))
		skill_swipe_pending_full_finalize = false
		host._rebuild_skill_detail_after_preview(0 if selected_skill_id == "thieving" else maxi(0, preserve_scroll))
		return
	if trace_finalize:
		print("SWIPE_FINALIZE_TRACE phase=resolved us=%s children=%s" % [str(Time.get_ticks_usec() - trace_start), str(stack.get_child_count())])

	host._begin_skill_swipe_rebuild_cover()
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
	host._clear_action_pop_tweens()
	host._reward_feedback_surface()._clear_action_crit_tweens()
	host._clear_stamina_gauge_pop_tween()
	host._clear_activity_unlock_visual_scroll_tween()
	for raw_key in action_card_keys.duplicate():
		host._discard_action_card_key(str(raw_key))
	action_cards.clear()
	action_card_keys.clear()
	detail_action_card_nodes.clear()
	detail_rendered_action_ids.clear()
	host._clear_detail_lazy_cache_bin()
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
		host._rebuild_skill_detail_after_preview(0 if selected_skill_id == "thieving" else maxi(0, preserve_scroll))
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
	top_spacer.custom_minimum_size = Vector2(0, host._onboarding_first_module_top_spacer_height(selected_skill_id))
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
	var slots_created = await host._detail_lazy_create_slots_batched(
		stack,
		selected_skill_id,
		content_width,
		actions_width,
		SKILL_SWIPE_FINALIZE_SLOT_BATCH_SIZE
	)
	if not slots_created:
		if trace_finalize:
			print("SWIPE_FINALIZE_TRACE fallback=slots_failed us=%s" % str(Time.get_ticks_usec() - trace_start))
		host._rebuild_skill_detail_after_preview(0 if selected_skill_id == "thieving" else maxi(0, preserve_scroll))
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
	var bottom_pad = host._detail_actions_bottom_scroll_pad(selected_skill_id)
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
		host._add_skill_detail_shadow_overlay(host._skill_detail_shadow_top_y())
	Callable(host, "_sync_detail_actions_scroll_limit_deferred").call_deferred()
	skill_swipe_finalized_lazy_mount_pending = true
	_schedule_mount_swipe_finalized_lazy_cards(selected_skill_id, token, 0)
	Callable(host, "_apply_pending_swipe_resume_scroll").call_deferred(target_skill_id)
	if trace_finalize:
		print("SWIPE_FINALIZE_TRACE phase=done us=%s" % str(Time.get_ticks_usec() - trace_start))

func _build_detail_jump_arrows(parent: Control) -> void:
	if detail_actions_scroll == null:
		return
	if host._onboarding_runtime()._onboarding_path_active():
		return
	var scroll_direction_callback := Callable(host, "_on_detail_actions_user_scroll_direction")
	if not detail_actions_scroll.user_scroll_direction.is_connected(scroll_direction_callback):
		detail_actions_scroll.user_scroll_direction.connect(scroll_direction_callback)
	detail_jump_top_button = _activity_jump_button(host.ACTIVITY_JUMP_TOP_TEXTURE, true)
	detail_jump_bottom_button = _activity_jump_button(host.ACTIVITY_JUMP_BOTTOM_TEXTURE, false)
	parent.add_child(detail_jump_top_button)
	parent.add_child(detail_jump_bottom_button)


func _activity_jump_button(path: String, top: bool) -> TextureButton:
	var button := TextureButton.new()
	button.texture_normal = host.visual_texture_cache._texture_or_visual_fallback(path)
	button.texture_hover = button.texture_normal
	button.texture_pressed = button.texture_normal
	button.texture_disabled = button.texture_normal
	button.texture_focused = button.texture_normal
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.custom_minimum_size = host.ACTIVITY_JUMP_ARROW_SIZE
	button.focus_mode = Control.FOCUS_NONE
	button.z_index = host.CHAT_UI_Z + 140
	button.z_as_relative = false
	button.anchor_left = 0.5
	button.anchor_right = 0.5
	button.offset_left = -host.ACTIVITY_JUMP_ARROW_SIZE.x * 0.5
	button.offset_right = host.ACTIVITY_JUMP_ARROW_SIZE.x * 0.5
	if top:
		button.anchor_top = 0.0
		button.anchor_bottom = 0.0
		button.offset_top = host.ACTIVITY_JUMP_ARROW_EDGE_INSET
		button.offset_bottom = host.ACTIVITY_JUMP_ARROW_EDGE_INSET + host.ACTIVITY_JUMP_ARROW_SIZE.y
	else:
		button.anchor_top = 1.0
		button.anchor_bottom = 1.0
		button.offset_top = -host.ACTIVITY_JUMP_ARROW_BOTTOM_EDGE_INSET - host.ACTIVITY_JUMP_ARROW_SIZE.y
		button.offset_bottom = -host.ACTIVITY_JUMP_ARROW_BOTTOM_EDGE_INSET
	button.modulate = Color(1, 1, 1, 0)
	button.disabled = true
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.mouse_entered.connect(_on_detail_jump_arrow_hovered.bind(top, true))
	button.mouse_exited.connect(_on_detail_jump_arrow_hovered.bind(top, false))
	host._button_press_runtime().attach_button_depress_animation(button, 0.93)
	button.pressed.connect(_on_detail_jump_arrow_pressed.bind(-1 if top else 1))
	return button


func _event_points_inside_detail_jump_arrow(event: InputEvent, source: Control = null) -> bool:
	var event_position := Vector2.ZERO
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return false
		event_position = host._global_event_position(mouse_event.position, mouse_event.global_position, source)
	elif event is InputEventMouseMotion:
		var motion_event := event as InputEventMouseMotion
		event_position = host._global_event_position(motion_event.position, motion_event.global_position, source)
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		event_position = host._global_event_position(touch_event.position, touch_event.position, source)
	elif event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		event_position = host._global_event_position(drag_event.position, drag_event.position, source)
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
		host.action_card_press_key = ""
		host._cancel_skill_swipe_feedback(false)
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
	if max_scroll <= host.ACTIVITY_JUMP_ARROW_EDGE_EPSILON:
		return false
	var scroll: int = detail_actions_scroll.scroll_vertical
	if direction < 0:
		return scroll > host.ACTIVITY_JUMP_ARROW_EDGE_EPSILON
	return scroll < max_scroll - host.ACTIVITY_JUMP_ARROW_EDGE_EPSILON


func _detail_jump_arrows_have_enough_modules() -> bool:
	if not detail_lazy_plan.is_empty():
		return _detail_jump_arrow_lazy_module_count() >= host.ACTIVITY_JUMP_ARROW_MIN_MODULES
	return detail_rendered_action_ids.size() >= host.ACTIVITY_JUMP_ARROW_MIN_MODULES


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
			detail_jump_top_hold = host.ACTIVITY_JUMP_ARROW_LINGER_SECONDS
	else:
		detail_jump_bottom_hovered = hovered
		if hovered:
			_reveal_detail_jump_arrow(1)
		else:
			detail_jump_bottom_hold = host.ACTIVITY_JUMP_ARROW_LINGER_SECONDS


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
	host._skill_swipe_activity_surface()._queue_skill_swipe_preview_prewarm()
	host.get_viewport().set_input_as_handled()


func _prepare_detail_jump_arrow_target_window(target_scroll: int) -> int:
	if detail_lazy_plan.is_empty() or detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll):
		return target_scroll
	host._sync_detail_lazy_cards_for_scroll_window(float(target_scroll), host.ACTIVITY_JUMP_ARROW_LANDING_PREFILL_BUFFER_PX)
	host._sync_detail_actions_scroll_limit()
	var clamped_target := clampi(target_scroll, 0, detail_actions_scroll.get_max_scroll_vertical())
	if clamped_target != target_scroll:
		host._sync_detail_lazy_cards_for_scroll_window(float(clamped_target), host.ACTIVITY_JUMP_ARROW_LANDING_PREFILL_BUFFER_PX)
	return clamped_target


func _reveal_detail_jump_arrow(direction: int) -> void:
	if detail_actions_scroll == null or not _detail_jump_arrows_have_enough_modules():
		return
	if direction < 0 and _detail_jump_arrow_can_use(-1):
		detail_jump_top_hold = host.ACTIVITY_JUMP_ARROW_LINGER_SECONDS
	elif direction > 0 and _detail_jump_arrow_can_use(1):
		detail_jump_bottom_hold = host.ACTIVITY_JUMP_ARROW_LINGER_SECONDS


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
	var control: Control = host._valid_control_ref(value)
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
			detail_jump_top_hold = host.ACTIVITY_JUMP_ARROW_LINGER_SECONDS
		else:
			detail_jump_top_hold = maxf(0.0, detail_jump_top_hold - delta)
	else:
		if not can_use:
			detail_jump_bottom_hold = 0.0
			detail_jump_bottom_hovered = false
		elif detail_jump_bottom_hovered:
			detail_jump_bottom_hold = host.ACTIVITY_JUMP_ARROW_LINGER_SECONDS
		else:
			detail_jump_bottom_hold = maxf(0.0, detail_jump_bottom_hold - delta)
	var held := detail_jump_top_hold if top else detail_jump_bottom_hold
	var hovered := detail_jump_top_hovered if top else detail_jump_bottom_hovered
	var target_alpha := 1.0 if can_use and (hovered or held > 0.0) else 0.0
	var fade_seconds: float = host.ACTIVITY_JUMP_ARROW_FADE_IN_SECONDS if target_alpha > button.modulate.a else host.ACTIVITY_JUMP_ARROW_FADE_OUT_SECONDS
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


func _play_detail_module_layout_transition(snapshot: Dictionary) -> void:
	if snapshot.is_empty() or current_screen != "skill":
		return
	await host.get_tree().process_frame
	if current_screen != "skill":
		return
	var stack = host._detail_actions_stack() as VBoxContainer
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
		var module_key = host._module_list_transition_key_for_control(control)
		if module_key.is_empty() or not host._detail_module_transition_child_visible(control):
			continue
		var occurrence_index = int(occurrence_counts.get(module_key, 0))
		occurrence_counts[module_key] = occurrence_index + 1
		var occurrence_key = "%s#%s" % [module_key, occurrence_index]
		host._kill_module_list_transition_tween(control)
		var final_position = control.position
		var final_scale = control.scale
		var final_minimum_size = control.custom_minimum_size
		var final_clip_contents = control.clip_contents
		var final_collapsed_squeeze = host._first_control_with_bool_meta(control, "module_ui_collapsed_squeeze")
		if final_collapsed_squeeze != null:
			final_minimum_size.y = host._module_collapsed_squeeze_height()
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
				host._control_tree_has_named_descendant(control, "CollapsedModuleRow")
				or host._control_tree_has_bool_meta(control, "module_ui_collapsed_squeeze")
			):
				var start_minimum_size = final_minimum_size
				start_minimum_size.y = maxf(final_minimum_size.y, old_rect.size.y)
				var collapsed_squeeze = host._first_control_with_bool_meta(control, "module_ui_collapsed_squeeze")
				var animate_squeeze_root = collapsed_squeeze == control
				if collapsed_squeeze != null:
					collapsed_squeeze.size.y = start_minimum_size.y
				if not animate_squeeze_root:
					control.custom_minimum_size = start_minimum_size
				control.clip_contents = false if animate_squeeze_root else true
				if animate_squeeze_root:
					host._set_collapsed_module_visual_clipping(control, str(control.get_meta("module_ui_key", "")), true)
					host._set_collapsed_module_title_lift(control, false, true)
					host._set_collapsed_module_title_lift(control, true, false)
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
		host._hold_skill_detail_layout_refresh(MODULE_LIST_TRANSITION_SECONDS + 0.08)
