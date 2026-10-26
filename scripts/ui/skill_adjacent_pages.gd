extends RefCounted
## Keeps the previous and next skill pages built beside the current page.
##
## Each neighbour is a real skill detail page rendered by the same code as the
## current page. It is built off the drag path (after the current page settles,
## one small step per frame, paused while a finger is down), scrolled to its
## landing position and has its visible cards mounted instantly before it can be
## seen. A swipe then slides the whole frame so the neighbour moves in with the
## finger, and a committed swipe swaps the per-page references so the neighbour
## becomes the current page without being rendered again.

const SkillState = preload("res://scripts/progression/skill_state.gd")

const OFFSETS := [-1, 1]
const BUILD_START_DELAY_FRAMES := 1
const MOUNT_STEPS_LIMIT := 24
const SETTLE_RETRY_LIMIT := 3
const STALE_CHECK_INTERVAL_FRAMES := 45
# Full signature re-check of one page even when the cheap key did not move.
const STALE_BACKSTOP_INTERVAL_CHECKS := 20
const LANDING_SCROLL_EPSILON_PX := 1.5

# Per-page references and lazy-list state held by the skill detail surface.
# They are swapped wholesale when a page becomes the current one.
const CONTEXT_PROPERTIES := [
	"detail_xp_label",
	"detail_xp_bar",
	"detail_regen_circle",
	"detail_regen_circle_host",
	"detail_regen_circle_fade_group",
	"detail_fish_circle",
	"detail_blue_guy_health_gauge",
	"detail_auto_eat_fish_button",
	"detail_stamina_bar",
	"detail_header_body",
	"detail_header_left_block",
	"detail_actions_scroll",
	"detail_actions_top_spacer",
	"detail_unlock_scroll_spacer",
	"detail_back_button",
	"detail_jump_top_button",
	"detail_jump_bottom_button",
	"detail_pull_tip_root",
	"detail_pull_tip_label",
	"detail_action_card_nodes",
	"detail_rendered_action_ids",
	"detail_lazy_plan",
	"detail_lazy_stack",
	"detail_lazy_last_scroll",
	"detail_lazy_cache_bin",
	"detail_lazy_settle_warm_mount_exhausted",
	"detail_lazy_window_sync_elapsed",
	"detail_lazy_render_cull_last_scroll",
	"detail_lazy_render_cull_last_msec",
]

# Shared state a neighbour render or mount may touch; always restored to the
# current page's values afterwards.
const TRANSIENT_PROPERTIES := [
	"detail_lazy_settle_warm_mount_skill_id",
	"detail_lazy_mounted_this_frame",
	"detail_lazy_mount_trace_context",
	"detail_pull_tip_active",
	"detail_pull_tip_direction",
	"detail_jump_top_hold",
	"detail_jump_bottom_hold",
	"detail_jump_top_hovered",
	"detail_jump_bottom_hovered",
	"detail_shelf_shadow_overlay",
	"detail_shelf_shadow_alpha",
	"detail_header_gauge_refresh_elapsed",
]

var host
# -1 until IDLE_ELITE_DISABLE_ADJACENT_SKILL_PAGES has been read once.
var disabled_by_env := -1
# offset (-1 / 1) -> page record Dictionary
var pages := {}
var build_token := 0
var last_build_process_frame := -1
var neighbour_render_active := false
var render_record := {}
var render_token := -1
var render_aborted := false
var render_saved_context := {}
var render_saved_transients := {}
var render_saved_skill_id := ""
var render_chunk_started_usec := 0
var refresh_all_pages_now := false
var last_swap_process_frame := -1
var stale_backstop_counter := 0
# The stride the neighbour pages and the header shelves were last laid out for.
var laid_out_stride := 0.0
var preferred_offset := 1


func _init(host_ref) -> void:
	host = host_ref


func _detail():
	return host._skill_detail_surface()


func _swipe():
	return host._skill_swipe_activity_surface()


func enabled() -> bool:
	if host.desktop_layout.enabled():
		return false
	if disabled_by_env == -1:
		disabled_by_env = 1 if OS.get_environment("IDLE_ELITE_DISABLE_ADJACENT_SKILL_PAGES") == "1" else 0
	if disabled_by_env == 1:
		return false
	if host.current_screen != "skill":
		return false
	if host.skill_defs.size() < 3:
		return false
	var onboarding = host._onboarding_runtime()
	if onboarding.tutorial_active:
		return false
	if host.boot_detail_render_in_progress or host.boot_detail_scroll_locked or not host.boot_detail_render_queue.is_empty():
		return false
	return true


func stride() -> float:
	# One page per screen width: the gutter between two page columns equals the
	# two side margins, so nothing of a neighbour is on screen at rest.
	var column_width: float = host._skill_content_width()
	return maxf(column_width + float(host.PAGE_PAD) * 2.0, host._skill_column_host_width())


func half_gutter() -> float:
	return maxf(0.0, (stride() - host._skill_content_width()) * 0.5)


func active() -> bool:
	return not pages.is_empty()


func has_page(offset: int) -> bool:
	var record := pages.get(offset, {}) as Dictionary
	if record.is_empty():
		return false
	var page: Control = host._app_lifecycle_runtime().valid_control_ref(record.get("page"))
	return page != null and not page.is_queued_for_deletion()


func page_ready(offset: int) -> bool:
	return has_page(offset) and bool((pages[offset] as Dictionary).get("ready", false))


func page_for_offset(offset: int) -> Control:
	if not has_page(offset):
		return null
	return _control((pages[offset] as Dictionary).get("page"))


func skill_for_offset(offset: int) -> String:
	return str(_swipe()._skill_id_for_swipe_offset(offset))


func reset() -> void:
	build_token += 1
	pages.clear()
	refresh_all_pages_now = false


func debug_state() -> Dictionary:
	var state := {}
	for offset in OFFSETS:
		var record := pages.get(offset, {}) as Dictionary
		if record.is_empty():
			continue
		var page := page_for_offset(offset)
		state[offset] = {
			"skill_id": str(record.get("skill_id", "")),
			"ready": bool(record.get("ready", false)),
			"stage": str(record.get("stage", "")),
			"page_id": page.get_instance_id() if page != null else 0,
			"mounted": _mounted_count(record),
		}
	return state


# --- Per-page context -------------------------------------------------------

func capture_context() -> Dictionary:
	var detail = _detail()
	var context := {}
	for property_name in CONTEXT_PROPERTIES:
		context[property_name] = detail.get(property_name)
	context["skill_swipe_page"] = _swipe().skill_swipe_page
	return context


func apply_context(context: Dictionary) -> void:
	var detail = _detail()
	for property_name in CONTEXT_PROPERTIES:
		if context.has(property_name):
			detail.set(property_name, _live(context[property_name]))
	_swipe().skill_swipe_page = _control(context.get("skill_swipe_page"))


## Freed nodes can sit in a stored context (a page was cleared meanwhile);
## never hand them back to typed properties.
func _live(value):
	if typeof(value) == TYPE_OBJECT and not is_instance_valid(value):
		return null
	return value


func _control(value) -> Control:
	return host._app_lifecycle_runtime().valid_control_ref(value)


func blank_context() -> Dictionary:
	return {
		"detail_xp_label": null,
		"detail_xp_bar": null,
		"detail_regen_circle": null,
		"detail_regen_circle_host": null,
		"detail_regen_circle_fade_group": null,
		"detail_fish_circle": null,
		"detail_blue_guy_health_gauge": null,
		"detail_auto_eat_fish_button": null,
		"detail_stamina_bar": null,
		"detail_header_body": null,
		"detail_header_left_block": null,
		"detail_actions_scroll": null,
		"detail_actions_top_spacer": null,
		"detail_unlock_scroll_spacer": null,
		"detail_back_button": null,
		"detail_jump_top_button": null,
		"detail_jump_bottom_button": null,
		"detail_pull_tip_root": null,
		"detail_pull_tip_label": null,
		"detail_action_card_nodes": {},
		"detail_rendered_action_ids": [],
		"detail_lazy_plan": [],
		"detail_lazy_stack": null,
		"detail_lazy_last_scroll": -1.0,
		"detail_lazy_cache_bin": null,
		"detail_lazy_settle_warm_mount_exhausted": false,
		"detail_lazy_window_sync_elapsed": 0.0,
		"detail_lazy_render_cull_last_scroll": -999999.0,
		"detail_lazy_render_cull_last_msec": 0,
		"skill_swipe_page": null,
	}


func _capture_transients() -> Dictionary:
	var detail = _detail()
	var transients := {}
	for property_name in TRANSIENT_PROPERTIES:
		transients[property_name] = detail.get(property_name)
	return transients


func _restore_transients(transients: Dictionary) -> void:
	var detail = _detail()
	for property_name in transients.keys():
		detail.set(property_name, _live(transients[property_name]))


## Runs `work` with the neighbour page installed as if it were the current page,
## then puts the real current page back. `work` must not await.
func _run_in_page_context(record: Dictionary, work: Callable) -> Variant:
	var saved_context := capture_context()
	var saved_transients := _capture_transients()
	var saved_skill_id: String = host.selected_skill_id
	apply_context(record.get("context", {}) as Dictionary)
	host.selected_skill_id = str(record.get("skill_id", saved_skill_id))
	var result = work.call()
	record["context"] = capture_context()
	host.selected_skill_id = saved_skill_id
	apply_context(saved_context)
	_restore_transients(saved_transients)
	return result


# --- Building ---------------------------------------------------------------

func schedule_build() -> void:
	build_token += 1
	if host.current_screen != "skill":
		return
	# The page just rendered and its shelf are laid out for the stride of now.
	laid_out_stride = stride()
	_build_loop(build_token)


func _get_tree() -> SceneTree:
	return host.get_tree()


func _build_blocked() -> bool:
	var swipe = _swipe()
	var preparing_during_motion: bool = (swipe.skill_swipe_tracking and swipe.skill_swipe_horizontal) or (swipe.skill_swipe_animating and swipe.skill_swipe_animation_mode == "settle")
	# The previous frame's neighbour mount deliberately marks the shared budget
	# as used. It must not stall its own preparation on the following frame.
	var current_page_mount: bool = _detail().detail_lazy_mounted_this_frame and last_build_process_frame < Engine.get_process_frames() - 1
	return (
		(swipe.skill_swipe_tracking and not preparing_during_motion)
		or (swipe.skill_swipe_animating and not preparing_during_motion)
		or _detail().detail_scroll_visual_work_this_frame
		or current_page_mount
		or (host._skill_swipe_loading_transition_active() and not preparing_during_motion)
		or swipe.skill_swipe_pending_full_finalize
		or swipe.direct_skill_nav_cover_active
		or swipe.skill_swipe_outgoing_cover_active
		or swipe.skill_swipe_rebuild_cover_active
		or host._navigation_shell().screen_render_in_progress
		or swipe.skill_swipe_handoff_cover != null and is_instance_valid(swipe.skill_swipe_handoff_cover)
		or swipe.skill_swipe_frame == null
		or not is_instance_valid(swipe.skill_swipe_frame)
		or _detail().detail_actions_scroll == null
		or not is_instance_valid(_detail().detail_actions_scroll)
	)


func _build_loop(token: int) -> void:
	var idle_frames := 0
	var stale_frames := 0
	var off_rest_frames := 0
	while is_instance_valid(host) and host.is_inside_tree():
		await _get_tree().process_frame
		if not is_instance_valid(host) or not host.is_inside_tree() or token != build_token:
			return
		if host.current_screen != "skill":
			if active():
				discard_all()
			return
		if not enabled():
			# Boot, onboarding or tutorial: swipes use the classic path. Wait here
			# so neighbours appear as soon as that ends without another render.
			if active():
				discard_all()
			idle_frames = 0
			continue
		_sync_layout_to_stride()
		# Never leave the strip parked between two pages: a finger that caught a
		# settle and then scrolled vertically or tapped ends with no release
		# animation, so glide back to the current page.
		if _frame_parked_off_rest():
			off_rest_frames += 1
			if off_rest_frames >= 2:
				off_rest_frames = 0
				_swipe()._cancel_skill_swipe_feedback(true)
			continue
		off_rest_frames = 0
		if _build_blocked():
			idle_frames = 0
			continue
		idle_frames += 1
		if idle_frames < BUILD_START_DELAY_FRAMES:
			continue
		if await _build_step():
			idle_frames = BUILD_START_DELAY_FRAMES
			stale_frames = 0
			continue
		stale_frames += 1
		if stale_frames >= STALE_CHECK_INTERVAL_FRAMES:
			stale_frames = 0
			_discard_stale_pages()


func _frame_parked_off_rest() -> bool:
	var swipe = _swipe()
	if absf(float(swipe.skill_swipe_drag_offset_x)) <= 0.5:
		return false
	if swipe.skill_swipe_frame == null or not is_instance_valid(swipe.skill_swipe_frame):
		return false
	if swipe.skill_swipe_handoff_cover != null and is_instance_valid(swipe.skill_swipe_handoff_cover):
		return false
	return not host._skill_swipe_loading_transition_active() and not host._navigation_shell().screen_render_in_progress


## One bounded unit of work per frame. Returns true when it did something.
func _build_step() -> bool:
	# Finish the likely destination before spending frames on the other side.
	for offset in [preferred_offset, -preferred_offset]:
		var expected_skill_id := skill_for_offset(offset)
		var record := pages.get(offset, {}) as Dictionary
		if not record.is_empty() and (str(record.get("skill_id", "")) != expected_skill_id or not has_page(offset)):
			discard_page(offset)
			record = {}
		if record.is_empty():
			if expected_skill_id.is_empty() or expected_skill_id == host.selected_skill_id:
				continue
			if not host._onboarding_runtime()._swipe_offset_accessible(offset):
				continue
			await _build_page_skeleton(offset, expected_skill_id)
			return true
		if not has_page(offset):
			continue
		if bool(record.get("ready", false)) and not bool(record.get("needs_landing", false)):
			continue
		if _advance_page(record):
			return true
	return false


## Header shelf backgrounds bleed sideways past the page column. With pages
## side by side they may only reach the middle of the gutter.
func clamp_shelf_bleed(page: Control) -> void:
	if page == null or not is_instance_valid(page):
		return
	var bleed := half_gutter()
	var shelves := page.find_children("SkillDetailFullBleedShelfBackground", "", true, false)
	for raw_shelf in shelves:
		var shelf := raw_shelf as Control
		if shelf == null:
			continue
		if absf(shelf.offset_left + bleed) > 0.5 or absf(shelf.offset_right - bleed) > 0.5:
			shelf.offset_left = -bleed
			shelf.offset_right = bleed


## Renders a neighbour page with the regular skill detail render. The render
## runs in staged chunks: at each of its frame breaks the real current page is
## put back (see yield_neighbour_render), so no single frame carries the whole
## page and nothing else ever sees half a neighbour as the current page.
func _build_page_skeleton(offset: int, skill_id: String) -> void:
	var frame: Control = _control(_swipe().skill_swipe_frame)
	clamp_shelf_bleed(_swipe().skill_swipe_page)
	var record := {
		"offset": offset,
		"skill_id": skill_id,
		"context": blank_context(),
		"ready": false,
		"stage": "layout",
		"mount_steps": 0,
		"settle_retries": 0,
		"max_chunk_usec": 0,
		"fresh_key": freshness_key(skill_id),
	}
	var started_msec := Time.get_ticks_msec()
	render_record = record
	render_token = build_token
	render_aborted = false
	_enter_neighbour_render(record)
	await _detail()._render_skill_detail(false, -1, false, 1)
	if not is_instance_valid(host) or not host.is_inside_tree():
		return
	if neighbour_render_active:
		_leave_neighbour_render(record)
	render_record = {}
	var page := _control((record.get("context", {}) as Dictionary).get("skill_swipe_page"))
	if render_aborted or render_token != build_token or page == null or not is_instance_valid(page) or page.get_parent() != frame:
		_free_partial_page(record)
		return
	record["page"] = page
	page.name = "AdjacentSkillPage_%s" % skill_id
	page.set_meta("adjacent_skill_page", skill_id)
	pages[offset] = record
	layout_page(page, offset)
	clamp_shelf_bleed(page)
	page.process_mode = Node.PROCESS_MODE_DISABLED
	_trace("skeleton skill=%s offset=%d ms=%d max_chunk_us=%d chunks=%s" % [skill_id, offset, Time.get_ticks_msec() - started_msec, int(record.get("max_chunk_usec", 0)), str(record.get("chunks", []))])


func _enter_neighbour_render(record: Dictionary) -> void:
	last_build_process_frame = Engine.get_process_frames()
	render_saved_context = capture_context()
	render_saved_transients = _capture_transients()
	render_saved_skill_id = host.selected_skill_id
	apply_context(record.get("context", {}) as Dictionary)
	host.selected_skill_id = str(record.get("skill_id", render_saved_skill_id))
	# Enables the render's frame breaks and batched slot creation, and skips the
	# eager first-card mounts (the neighbour mounts around its landing scroll).
	_swipe().skill_swipe_defer_initial_lazy_mount = true
	neighbour_render_active = true
	render_chunk_started_usec = Time.get_ticks_usec()


func _leave_neighbour_render(record: Dictionary) -> void:
	var chunk_usec := Time.get_ticks_usec() - render_chunk_started_usec
	record["max_chunk_usec"] = maxi(int(record.get("max_chunk_usec", 0)), chunk_usec)
	if not record.has("chunks"):
		record["chunks"] = []
	(record["chunks"] as Array).append(chunk_usec)
	record["context"] = capture_context()
	host.selected_skill_id = render_saved_skill_id
	apply_context(render_saved_context)
	_restore_transients(render_saved_transients)
	_swipe().skill_swipe_defer_initial_lazy_mount = false
	neighbour_render_active = false


## Called by the render at each frame break while a neighbour is being built.
func yield_neighbour_render() -> void:
	var record := render_record
	var token := render_token
	_leave_neighbour_render(record)
	while true:
		await _get_tree().process_frame
		if not is_instance_valid(host) or not host.is_inside_tree():
			return
		if token != build_token or render_record != record or not enabled():
			_abort_neighbour_render(record)
			return
		# A quick reversal can arrive while the other side is only half built.
		# Retire that unfinished, unseen page at this safe yield boundary so the
		# single builder can prepare the direction the finger actually chose.
		var swipe = _swipe()
		if swipe.skill_swipe_tracking and swipe.skill_swipe_horizontal and int(record.get("offset",0)) != preferred_offset and not has_page(preferred_offset):
			_abort_neighbour_render(record)
			return
		var frame: Control = _control(_swipe().skill_swipe_frame)
		var page := _control((record.get("context", {}) as Dictionary).get("skill_swipe_page"))
		if frame == null or not is_instance_valid(frame) or page == null or not is_instance_valid(page) or page.get_parent() != frame:
			_abort_neighbour_render(record)
			return
		if not _build_blocked():
			break
	_enter_neighbour_render(record)


## Leaves the real current page installed and frees the half-built page, so the
## render's own "still valid?" checks stop it at its next step.
func _abort_neighbour_render(record: Dictionary) -> void:
	render_aborted = true
	_free_partial_page(record)


func _free_partial_page(record: Dictionary) -> void:
	_discard_record_cards(record)
	var page: Control = host._app_lifecycle_runtime().valid_control_ref((record.get("context", {}) as Dictionary).get("skill_swipe_page"))
	if page == null or page == _swipe().skill_swipe_page:
		return
	var parent := page.get_parent()
	if parent != null:
		parent.remove_child(page)
	page.free()


## Positions a page the render just created (it is not the current page).
func prepare_neighbour_page(page: Control) -> void:
	var offset := int(render_record.get("offset", 1))
	layout_page(page, offset)
	page.process_mode = Node.PROCESS_MODE_DISABLED


func layout_page(page: Control, offset: int) -> void:
	if page == null or not is_instance_valid(page):
		return
	var column_width: float = host._skill_content_width()
	var left := float(offset) * stride()
	page.anchor_left = 0.0
	page.anchor_right = 0.0
	page.anchor_top = 0.0
	page.anchor_bottom = 1.0
	page.offset_left = left
	page.offset_right = left + column_width
	page.offset_top = 0.0
	page.offset_bottom = 0.0
	page.custom_minimum_size.x = column_width
	page.visible = true
	page.modulate = Color.WHITE


## The stride is one screen width, and a window can change its width (web and
## desktop; a phone's does not). Pages that are already built keep the offsets
## they were laid out with, and header shelves the bleed they were given, so
## both are laid out again when the stride has moved: otherwise a window made
## wider shows the edge of each neighbour, and of its shelf, at rest. Only the
## places change: the pages, their scroll and their mounted cards are kept.
func _sync_layout_to_stride() -> void:
	var current := stride()
	if absf(current - laid_out_stride) <= 0.5:
		return
	laid_out_stride = current
	var column_width: float = host._skill_content_width()
	for offset in OFFSETS:
		var page := page_for_offset(offset)
		if page == null:
			continue
		var left := float(offset) * current
		page.offset_left = left
		page.offset_right = left + column_width
		clamp_shelf_bleed(page)
	clamp_shelf_bleed(_control(_swipe().skill_swipe_page))


func layout_current_page(page: Control) -> void:
	if page == null or not is_instance_valid(page):
		return
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.offset_left = 0.0
	page.offset_top = 0.0
	page.offset_right = 0.0
	page.offset_bottom = 0.0
	page.position = Vector2.ZERO
	page.visible = true
	page.modulate = Color.WHITE
	page.process_mode = Node.PROCESS_MODE_INHERIT


func _advance_page(record: Dictionary) -> bool:
	last_build_process_frame = Engine.get_process_frames()
	var stage := str(record.get("stage", "layout"))
	if bool(record.get("needs_landing", false)) and stage == "ready":
		stage = "scroll"
		record["needs_landing"] = false
		record["ready"] = false
		record["settle_retries"] = 0
		record["mount_steps"] = 0
	match stage:
		"layout":
			# Containers sort at the end of the frame the page was added in.
			record["stage"] = "scroll"
			return true
		"scroll":
			_run_in_page_context(record, func():
				_apply_landing_scroll(record)
				return null
			)
			record["stage"] = "mount"
			return true
		"mount":
			var mounted = _run_in_page_context(record, func():
				return _detail()._sync_detail_lazy_visible_cards(true, 1)
			)
			record["mount_steps"] = int(record.get("mount_steps", 0)) + 1
			if int(mounted) > 0 and int(record["mount_steps"]) < MOUNT_STEPS_LIMIT:
				return true
			record["stage"] = "settle"
			return true
		"settle":
			var moved = _run_in_page_context(record, func():
				return _settle_page(record)
			)
			if bool(moved) and int(record.get("settle_retries", 0)) < SETTLE_RETRY_LIMIT:
				record["settle_retries"] = int(record.get("settle_retries", 0)) + 1
				record["stage"] = "mount"
				return true
			record["stage"] = "ready"
			record["ready"] = true
			_trace("ready skill=%s offset=%d mounted=%d" % [str(record.get("skill_id", "")), int(record.get("offset", 0)), _mounted_count(record)])
			return true
	return false


func _landing_scroll_target() -> int:
	var detail = _detail()
	var scroll = detail.detail_actions_scroll
	if scroll == null or not is_instance_valid(scroll):
		return -1
	var skill_id: String = host.selected_skill_id
	if detail._has_only_one_unlocked_activity(skill_id):
		return 0
	var action_id: String = detail._latest_unlocked_action_id(skill_id)
	if action_id.is_empty():
		return 0
	detail._ensure_detail_lazy_entry_mounted(action_id)
	var card: Control = host._app_lifecycle_runtime().valid_control_ref(detail.detail_action_card_nodes.get(action_id))
	if card == null or card.is_queued_for_deletion():
		return -1
	return detail._detail_actions_scroll_target_for_card(card, false)


func _apply_landing_scroll(record: Dictionary) -> void:
	var detail = _detail()
	var scroll = detail.detail_actions_scroll
	if scroll == null or not is_instance_valid(scroll):
		return
	detail._sync_detail_actions_scroll_limit()
	var target := _landing_scroll_target()
	if target < 0:
		target = int(scroll.scroll_vertical)
	scroll.scroll_to_vertical(target, 0.0)
	record["landing_scroll"] = int(scroll.scroll_vertical)


## Re-checks the landing position after the visible cards got their real
## heights. Returns true when the scroll had to move (so mount again).
func _settle_page(record: Dictionary) -> bool:
	var detail = _detail()
	var scroll = detail.detail_actions_scroll
	if scroll == null or not is_instance_valid(scroll):
		return false
	detail._sync_detail_actions_scroll_limit()
	var target := _landing_scroll_target()
	var moved := false
	if target >= 0 and absf(float(target) - float(scroll.scroll_vertical)) > LANDING_SCROLL_EPSILON_PX:
		scroll.scroll_to_vertical(target, 0.0)
		moved = true
	record["landing_scroll"] = int(scroll.scroll_vertical)
	if host._fishing_rework_active_for_skill(host.selected_skill_id):
		host._fishing_ui_surface()._sync_fishing_detail_render_culling(true)
	detail._update_detail_header_gauges(true, true, true, 0.0, true)
	return moved


func _mounted_count(record: Dictionary) -> int:
	var plan := (record.get("context", {}) as Dictionary).get("detail_lazy_plan", []) as Array
	var count := 0
	for raw_entry in plan:
		if bool((raw_entry as Dictionary).get("mounted", false)):
			count += 1
	return count


## Finishes a neighbour synchronously (used when a swipe commits to a page that
## was still mid-build). Visible cards are mounted without fades.
func finish_page_now(offset: int) -> void:
	if not has_page(offset):
		return
	var record := pages[offset] as Dictionary
	if bool(record.get("ready", false)):
		return
	var guard := 0
	while not bool(record.get("ready", false)) and guard < MOUNT_STEPS_LIMIT * 2:
		guard += 1
		if str(record.get("stage", "")) == "mount":
			_run_in_page_context(record, func():
				return _detail()._sync_detail_lazy_visible_cards(true, -1)
			)
			record["stage"] = "settle"
			continue
		if not _advance_page(record):
			break


# --- Freshness --------------------------------------------------------------

func _page_signature_current(record: Dictionary) -> bool:
	var skill_id := str(record.get("skill_id", ""))
	var context := record.get("context", {}) as Dictionary
	var rendered := context.get("detail_rendered_action_ids", []) as Array
	# Same ids, in the same order, that the lazy plan records while rendering.
	var expected: Array = _run_in_page_context(record, func():
		var ids: Array = []
		if host._fishing_rework_active_for_skill(skill_id):
			return host._fishing_ui_surface()._fishing_detail_render_signature()
		for entry in _detail()._visible_detail_entries_for_skill(skill_id):
			var track_id: String = _detail()._detail_lazy_track_id_for_entry(entry as Dictionary)
			if not track_id.is_empty():
				ids.append(track_id)
		return ids
	)
	if expected.size() != rendered.size():
		_trace("signature size skill=%s expected=%s rendered=%s" % [skill_id, str(expected), str(rendered)])
		return false
	for index in range(expected.size()):
		if str(expected[index]) != str(rendered[index]):
			_trace("signature diff skill=%s index=%d expected=%s rendered=%s" % [skill_id, index, str(expected[index]), str(rendered[index])])
			return false
	return true


## Cheap key over the state that decides which modules a skill page lists
## (levels, manual unlocks, bosses, events, heists, fishing offers). Only when it
## moves does a page pay for the full signature check.
func freshness_key(skill_id: String) -> int:
	var levels := PackedInt32Array()
	for raw_skill_def in host.skill_defs:
		var def_skill_id := str((raw_skill_def as Dictionary).get("id", ""))
		if not def_skill_id.is_empty():
			levels.append(SkillState.host_skill_level(host, def_skill_id))
	var unlock_runtime = host._activity_unlock_runtime()
	var parts := [
		levels,
		unlock_runtime.manual_activity_unlocks,
		unlock_runtime.pending_activity_unlock_ceremony,
		host._temporary_event_runtime().temporary_event_active,
		host._fighting_runtime().completed_bosses,
	]
	if skill_id == "thieving":
		parts.append(host.thieving_state.visible_heists_for_render().size())
	if host._fishing_rework_active_for_skill(skill_id):
		parts.append(host._fishing_ui_surface()._fishing_detail_render_signature_state_key())
	return hash(parts)


func _discard_stale_pages() -> void:
	stale_backstop_counter += 1
	var backstop := stale_backstop_counter >= STALE_BACKSTOP_INTERVAL_CHECKS
	if backstop:
		stale_backstop_counter = 0
	for offset in OFFSETS:
		if not has_page(offset):
			continue
		var record := pages[offset] as Dictionary
		if not bool(record.get("ready", false)):
			continue
		var skill_id := str(record.get("skill_id", ""))
		if host._activity_unlock_runtime().has_pending_readiness_for_skill(skill_id):
			continue
		var key := freshness_key(skill_id)
		if key == int(record.get("fresh_key", 0)) and not backstop:
			continue
		if _page_signature_current(record):
			record["fresh_key"] = key
			backstop = false
			continue
		_trace("stale skill=%s" % skill_id)
		discard_page(offset)
		return


# --- Discarding -------------------------------------------------------------

func _discard_record_cards(record: Dictionary) -> void:
	var skill_id := str(record.get("skill_id", ""))
	if skill_id.is_empty():
		return
	var context := record.get("context", {}) as Dictionary
	var plan := context.get("detail_lazy_plan", []) as Array
	var detail = _detail()
	for raw_entry in plan:
		var lazy_entry := raw_entry as Dictionary
		var cached_root: Control = host._app_lifecycle_runtime().valid_control_ref(lazy_entry.get("cached_root"))
		if cached_root != null and cached_root.get_parent() == null:
			cached_root.queue_free()
	for raw_key in host.action_cards.keys().duplicate():
		var card := host.action_cards[raw_key] as Dictionary
		if card == null:
			continue
		if str(card.get("skill_id", "")) != skill_id and not str(raw_key).begins_with("%s:" % skill_id):
			continue
		var root: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("root"))
		var page: Control = host._app_lifecycle_runtime().valid_control_ref(record.get("page"))
		if root != null and page != null and not page.is_ancestor_of(root):
			continue
		detail._discard_action_card_key(str(raw_key))
	var cache_bin: Control = host._app_lifecycle_runtime().valid_control_ref(context.get("detail_lazy_cache_bin"))
	if cache_bin != null:
		cache_bin.queue_free()


func discard_page(offset: int) -> void:
	var record := pages.get(offset, {}) as Dictionary
	pages.erase(offset)
	if record.is_empty():
		return
	_discard_record_cards(record)
	var page: Control = host._app_lifecycle_runtime().valid_control_ref(record.get("page"))
	if page != null:
		var parent := page.get_parent()
		if parent != null:
			parent.remove_child(page)
		page.queue_free()


func discard_all() -> void:
	for offset in OFFSETS:
		discard_page(offset)
	pages.clear()


# --- Drag and commit --------------------------------------------------------

## Brings neighbour headers and cards up to date the moment a horizontal drag
## starts, so nothing changes on them while or after they slide in.
func refresh_for_drag() -> void:
	if not active():
		return
	for offset in OFFSETS:
		if not has_page(offset):
			continue
		var record := pages[offset] as Dictionary
		_run_in_page_context(record, func():
			_detail()._update_detail_header_gauges(true, true, true, 0.0, true)
			return null
		)
	refresh_all_pages_now = true
	_swipe()._refresh_visible_action_cards(0.0, true, true, true, true)
	refresh_all_pages_now = false


## Card refresh gate: cards on neighbour pages only update while a drag or a
## settle makes them visible, or during an explicit full refresh.
func card_update_allowed(skill_id: String) -> bool:
	if refresh_all_pages_now or not active():
		return true
	if skill_id.is_empty() or skill_id == host.selected_skill_id:
		return true
	var swipe = _swipe()
	if not (swipe.skill_swipe_tracking or swipe.skill_swipe_animating):
		return false
	return skill_id == host.running_skill_id or skill_id == host._temporary_event_runtime().event_running_skill_id


## Swaps the neighbour at `offset` in as the current page. The frame keeps its
## on-screen position; returns the drag offset the frame now sits at.
func swap_to(offset: int, current_drag_x: float) -> float:
	preferred_offset = offset
	var record := pages.get(offset, {}) as Dictionary
	var incoming_page: Control = page_for_offset(offset)
	var outgoing_skill_id: String = host.selected_skill_id
	_reset_transient_page_chrome()
	var outgoing_context := capture_context()
	var outgoing_page: Control = _swipe().skill_swipe_page
	# The page two steps away is dropped; the page we leave becomes the
	# neighbour on the other side.
	discard_page(-offset)
	pages.erase(offset)
	apply_context(record.get("context", {}) as Dictionary)
	host.selected_skill_id = str(record.get("skill_id", outgoing_skill_id))
	var outgoing_record := {
		"offset": -offset,
		"skill_id": outgoing_skill_id,
		"context": outgoing_context,
		"page": outgoing_page,
		"ready": true,
		"stage": "ready",
		"needs_landing": true,
		"mount_steps": 0,
		"settle_retries": 0,
		"fresh_key": freshness_key(outgoing_skill_id),
	}
	if outgoing_page != null and is_instance_valid(outgoing_page):
		pages[-offset] = outgoing_record
		layout_page(outgoing_page, -offset)
		outgoing_page.process_mode = Node.PROCESS_MODE_DISABLED
	layout_current_page(incoming_page)
	last_swap_process_frame = Engine.get_process_frames()
	return current_drag_x + float(offset) * stride()


## Jump arrows and the pull tip are transient per-page hints driven by shared
## timers; hide them on the page being left so none fades in after a swipe.
func _reset_transient_page_chrome() -> void:
	var detail = _detail()
	for raw_button in [detail.detail_jump_top_button, detail.detail_jump_bottom_button]:
		var button: Control = host._app_lifecycle_runtime().valid_control_ref(raw_button)
		if button == null:
			continue
		button.modulate = Color(1, 1, 1, 0)
		if button is BaseButton:
			(button as BaseButton).disabled = true
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail.detail_jump_top_hold = 0.0
	detail.detail_jump_bottom_hold = 0.0
	detail.detail_jump_top_hovered = false
	detail.detail_jump_bottom_hovered = false
	var pull_tip_root: Control = host._app_lifecycle_runtime().valid_control_ref(detail.detail_pull_tip_root)
	if pull_tip_root != null:
		pull_tip_root.visible = false
		pull_tip_root.modulate.a = 0.0
	detail.detail_pull_tip_active = false
	detail.detail_pull_tip_direction = 0


func _trace(message: String) -> void:
	if OS.get_environment("IDLE_ELITE_TRACE_ADJACENT_PAGES") == "1":
		print("ADJACENT_PAGES %s" % message)
