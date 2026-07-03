extends RefCounted

const ActivityLockNumber = preload("res://scripts/activity_lock_number.gd")
const ActivityCardBorder = preload("res://scripts/ui/activity_card_border.gd")
const ActivityCardStyles = preload("res://scripts/ui/activity_card_styles.gd")
const ButtonPressState = preload("res://scripts/ui/button_press_state.gd")
const FeatheredCollectGlow = preload("res://scripts/ui/feathered_collect_glow.gd")
const FishingState = preload("res://scripts/fishing/state.gd")
const MobileScrollContainer = preload("res://scripts/ui/mobile_scroll_container.gd")
const ModuleUiRuntime = preload("res://scripts/module_ui/runtime.gd")
const RoundedCornerCropOverlay = preload("res://scripts/ui/rounded_corner_crop_overlay.gd")
const RoundedTextureRect = preload("res://scripts/ui/rounded_texture_rect.gd")

const FISHING_CATCH_POP_SIZE := Vector2(183, 183)
const FISHING_CATCH_POP_STAGGER_SECONDS := 0.11
const FISHING_CATCH_POP_RISE_PIXELS := 120.0
const FISHING_CATCH_POP_MAX_VISUALS := 9

var host
var fishing_ablation_flags := {}
var fishing_ablation_flags_loaded := false
var fishing_ablation_label := ""
var fishing_input_trace_requested := false
var web_fishing_perf_probe_ready := false
var web_fishing_perf_probe_setup_started := false
var web_fishing_perf_probe_last_scroll := -999999
var web_fishing_perf_probe_last_mounted := -1
var web_fishing_perf_probe_last_publish_msec := 0
var web_direct_wheel_callback: JavaScriptObject = null

func _init(host_ref) -> void:
	host = host_ref


func _load_fishing_debug_env_flags() -> void:
	if fishing_ablation_flags_loaded:
		return
	fishing_ablation_flags_loaded = true
	fishing_ablation_flags.clear()
	fishing_ablation_label = OS.get_environment("IDLE_ELITE_FISHING_ABLATION").strip_edges()
	fishing_input_trace_requested = OS.get_environment("IDLE_ELITE_TRACE_FISHING_INPUT") == "1"
	if fishing_ablation_label.is_empty() and (OS.get_name() == "Web" or OS.has_feature("web")):
		var search_text := str(JavaScriptBridge.eval("window.location.search", true))
		var ablation_marker := "fishing_ablation="
		var ablation_start := search_text.find(ablation_marker)
		if ablation_start >= 0:
			var raw_label := search_text.substr(ablation_start + ablation_marker.length())
			var ablation_end := raw_label.find("&")
			if ablation_end >= 0:
				raw_label = raw_label.substr(0, ablation_end)
			fishing_ablation_label = raw_label.replace("%2C", ",").replace("%2c", ",").replace("+", " ").strip_edges()
		if search_text.find("trace_fishing_input=1") >= 0:
			fishing_input_trace_requested = true
	if fishing_ablation_label.is_empty():
		return
	for raw_flag in fishing_ablation_label.split(",", false):
		var flag := str(raw_flag).strip_edges().to_lower()
		if not flag.is_empty():
			fishing_ablation_flags[flag] = true


func _fishing_ablation_enabled(flag: String) -> bool:
	_load_fishing_debug_env_flags()
	if fishing_ablation_flags.is_empty():
		return false
	return fishing_ablation_flags.has(flag)


func _fishing_input_trace_enabled() -> bool:
	_load_fishing_debug_env_flags()
	return fishing_input_trace_requested and host.current_screen == "skill" and host.selected_skill_id == "fishing"


func _trace_fishing_input_duration(label: String, started_usec: int, event: InputEvent) -> void:
	if started_usec <= 0:
		return
	var elapsed_usec := Time.get_ticks_usec() - started_usec
	if elapsed_usec < 1000:
		return
	print("FISHING_INPUT_TRACE label=%s event=%s us=%s ablation=%s" % [
		label,
		event.get_class(),
		str(elapsed_usec),
		fishing_ablation_label
	])


func _auto_eat_fish_icon_texture() -> Texture2D:
	return host.visual_texture_cache._texture("res://assets/content/fishing/catch-icons/00-minnow-cutout.png")


func _attach_auto_eat_fish_toggle(parent: Control, skill_id: String) -> TextureButton:
	if parent == null or not is_instance_valid(parent) or host._fishing_rework_active_for_skill(skill_id):
		return null
	var button := TextureButton.new()
	button.name = "AutoEatFishToggle"
	var transparent_texture: Texture2D = host.visual_texture_cache._visual_fallback_texture()
	button.texture_normal = transparent_texture
	button.texture_pressed = transparent_texture
	button.texture_hover = transparent_texture
	button.texture_disabled = transparent_texture
	button.texture_focused = transparent_texture
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.custom_minimum_size = Vector2(198, 198)
	button.size = Vector2(198, 198)
	button.position = Vector2(-66, -60)
	button.tooltip_text = "Auto eat fish"
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.z_index = 4095
	button.z_as_relative = false
	button.set_meta("auto_eat_skill_id", skill_id)
	_build_auto_eat_fish_toggle_visual(button)
	button.add_to_group("auto_eat_fish_toggle")
	button.pressed.connect(_on_auto_eat_fish_toggle_pressed.bind(skill_id))
	parent.add_child(button)
	_sync_auto_eat_fish_toggle_button(button)
	return button


func _auto_eat_fish_toggle_unlocked() -> bool:
	return host.fish_currency_ever_earned or host.fish_currency >= 1.0


func _build_auto_eat_fish_toggle_visual(button: TextureButton) -> void:
	var texture := _auto_eat_fish_icon_texture()
	if button == null or texture == null:
		return
	var visual := Control.new()
	visual.name = "AutoEatFishVisual"
	visual.set_anchors_preset(Control.PRESET_FULL_RECT)
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.pivot_offset = button.size * 0.5
	visual.rotation = deg_to_rad(-45.0)
	button.add_child(visual)
	var icon_size := Vector2(201, 201)
	var icon_position := (button.size - icon_size) * 0.5
	var fish: TextureRect = host.visual_texture_cache._image_from_texture(texture, icon_size)
	fish.name = "AutoEatFishIcon"
	fish.position = icon_position
	fish.material = _auto_eat_fish_solid_material(texture)
	fish.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.add_child(fish)


func _auto_eat_fish_solid_material(texture: Texture2D) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform vec4 fill_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	COLOR = vec4(fill_color.rgb, base.a * fill_color.a);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("fill_color", Color.WHITE)
	return material


func _sync_auto_eat_fish_toggle_button(button: TextureButton) -> void:
	if button == null or not is_instance_valid(button):
		return
	var unlocked := _auto_eat_fish_toggle_unlocked()
	button.visible = unlocked
	button.disabled = not unlocked
	button.mouse_filter = Control.MOUSE_FILTER_STOP if unlocked else Control.MOUSE_FILTER_IGNORE
	button.modulate = Color.WHITE
	button.scale = Vector2.ONE
	var fish := button.find_child("AutoEatFishIcon", true, false) as TextureRect
	if fish != null and is_instance_valid(fish):
		var skill_id := str(button.get_meta("auto_eat_skill_id", host.selected_skill_id))
		var fill: Color = host._skill_theme_color(skill_id) if host._auto_eat_fish_enabled_for_skill(skill_id) else Color("#77726d", 0.35)
		var material := fish.material as ShaderMaterial
		if material != null:
			material.set_shader_parameter("fill_color", fill)
		fish.modulate = Color.WHITE


func _sync_auto_eat_fish_toggle_buttons() -> void:
	for node in host.get_tree().get_nodes_in_group("auto_eat_fish_toggle"):
		_sync_auto_eat_fish_toggle_button(node as TextureButton)


func _on_auto_eat_fish_toggle_pressed(skill_id: String) -> void:
	host._cancel_pending_stamina_gauge_click()
	host._set_auto_eat_fish_enabled_for_skill(skill_id, not host._auto_eat_fish_enabled_for_skill(skill_id))
	_sync_auto_eat_fish_toggle_buttons()
	_play_auto_eat_fish_toggle_pop(skill_id)
	host._audio_director()._play_click_sfx()
	host.save_game()


func _play_auto_eat_fish_toggle_pop(skill_id: String) -> void:
	for node in host.get_tree().get_nodes_in_group("auto_eat_fish_toggle"):
		var button := node as TextureButton
		if button == null or not is_instance_valid(button) or not button.is_inside_tree():
			continue
		if str(button.get_meta("auto_eat_skill_id", "")) != skill_id:
			continue
		host._kill_meta_tween(button, "auto_eat_pop_tween")
		button.pivot_offset = button.size * 0.5
		button.scale = Vector2(1.0, 1.0)
		var tween: Tween = host.create_tween()
		button.set_meta("auto_eat_pop_tween", tween)
		tween.tween_property(button, "scale", Vector2(1.15, 1.15), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "scale", Vector2.ONE, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.finished.connect(host._remove_meta_from_instance_id.bind(button.get_instance_id(), "auto_eat_pop_tween"))


func _web_fishing_perf_probe_mounted_count() -> int:
	var mounted_count := 0
	for raw_entry in host.detail_lazy_plan:
		var lazy_entry := raw_entry as Dictionary
		if lazy_entry != null and bool(lazy_entry.get("mounted", false)):
			mounted_count += 1
	return mounted_count


func _web_fishing_perf_probe_requested() -> bool:
	if OS.get_name() != "Web" and not OS.has_feature("web"):
		return false
	var search_text := str(JavaScriptBridge.eval("window.location.search", true))
	return search_text.find("codex_fishing_perf") >= 0


func _focus_web_canvas_for_input() -> void:
	if OS.get_name() != "Web" and not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("""
		(function () {
			var canvas = document.getElementById('canvas');
			if (canvas && document.activeElement !== canvas) {
				if (!canvas.hasAttribute('tabindex')) {
					canvas.setAttribute('tabindex', '0');
				}
				canvas.focus({ preventScroll: true });
			}
		})();
	""", false)


func _install_web_direct_wheel_scroll_bridge() -> void:
	if OS.get_name() != "Web" and not OS.has_feature("web"):
		return
	if web_direct_wheel_callback != null:
		return
	web_direct_wheel_callback = JavaScriptBridge.create_callback(_on_web_direct_wheel_scroll)
	var window := JavaScriptBridge.get_interface("window")
	if window == null:
		return
	window.__idleEliteDirectWheelScroll = web_direct_wheel_callback
	JavaScriptBridge.eval("""
		(function() {
			if (window.__idleEliteDirectWheelScrollInstalled) return;
			window.__idleEliteDirectWheelScrollInstalled = true;
			window.addEventListener('wheel', function(event) {
				var canvas = document.querySelector('canvas');
				if (!canvas) return;
				var target = event.target;
				if (target !== canvas && !(target instanceof Node && canvas.contains(target))) return;
				if (typeof window.__idleEliteDirectWheelScroll !== 'function') return;
				event.preventDefault();
				event.stopImmediatePropagation();
				window.__idleEliteDirectWheelScroll(event.deltaY || 0, event.deltaMode || 0);
			}, {capture: true, passive: false});
		})();
	""", false)


func _on_web_direct_wheel_scroll(args: Array) -> void:
	if host.current_screen != "skill" or host.detail_actions_scroll == null or not is_instance_valid(host.detail_actions_scroll):
		return
	if not host.detail_actions_scroll.visible or not host.detail_actions_scroll.is_visible_in_tree():
		return
	var delta_y := float(args[0]) if args.size() > 0 else 0.0
	var delta_mode := int(args[1]) if args.size() > 1 else 0
	if delta_mode == 1:
		delta_y *= 48.0
	elif delta_mode == 2:
		delta_y *= host._detail_lazy_viewport_height()
	host.detail_actions_scroll.apply_direct_wheel_delta(delta_y)
	_publish_web_fishing_perf_probe_state(true)


func _run_web_fishing_perf_probe_setup() -> void:
	if web_fishing_perf_probe_setup_started:
		return
	web_fishing_perf_probe_setup_started = true
	_focus_web_canvas_for_input()
	JavaScriptBridge.eval("window.__idleEliteFishingPerf = {ready:false, setupStarted:true};", false)
	await host.get_tree().process_frame
	host._test_state_runtime()._god_mode_unlock_onboarding_state()
	host._test_state_runtime()._god_mode_max_skills_state()
	host._test_state_runtime()._god_mode_unlock_actions_state()
	host.running_skill_id = ""
	host.running_action_id = ""
	host.action_progress = 0.0
	host.current_screen = "skill"
	host.selected_skill_id = "fishing"
	host._passive_modules_runtime().sync_passive_module_unlocks(host._unix_now())
	await host._render_screen(false, -1, false)
	for _frame in range(90):
		await host.get_tree().process_frame
	host._skill_detail_surface()._detail_lazy_mount_initial_window_sync(true, 999)
	host._sync_detail_actions_scroll_limit()
	for _frame in range(180):
		if host.detail_texture_prewarm_request_queue.is_empty() and host.detail_texture_prewarm_pending.is_empty():
			break
		await host.get_tree().process_frame
	for _frame in range(45):
		await host.get_tree().process_frame
	if host.detail_actions_scroll != null and is_instance_valid(host.detail_actions_scroll):
		var start_scroll := mini(120, host.detail_actions_scroll.get_max_scroll_vertical())
		host.detail_actions_scroll.scroll_vertical = start_scroll
		host.detail_actions_scroll.drag_scroll_position = float(start_scroll)
	_sync_fishing_detail_render_culling(true)
	_focus_web_canvas_for_input()
	web_fishing_perf_probe_ready = true
	_publish_web_fishing_perf_probe_state(true)


func _publish_web_fishing_perf_probe_state(force := false) -> void:
	if not host.web_fishing_perf_probe_enabled or (OS.get_name() != "Web" and not OS.has_feature("web")):
		return
	if not force and not web_fishing_perf_probe_ready:
		return
	if not force:
		var now_msec := Time.get_ticks_msec()
		if now_msec - web_fishing_perf_probe_last_publish_msec < 80:
			return
	var scroll_y := -1
	var max_scroll := -1
	var drag_active := false
	var scroll_velocity := 0.0
	if host.detail_actions_scroll != null and is_instance_valid(host.detail_actions_scroll):
		scroll_y = int(host.detail_actions_scroll.scroll_vertical)
		max_scroll = host.detail_actions_scroll.get_max_scroll_vertical()
		drag_active = host.detail_actions_scroll.drag_scrolling
		scroll_velocity = host.detail_actions_scroll.velocity
	var mounted_count := _web_fishing_perf_probe_mounted_count()
	if not force and scroll_y == web_fishing_perf_probe_last_scroll and mounted_count == web_fishing_perf_probe_last_mounted:
		return
	var visible_placeholders := false
	if host.current_screen == "skill" and (not web_fishing_perf_probe_ready or mounted_count < host.detail_lazy_plan.size()):
		visible_placeholders = host._skill_detail_has_visible_lazy_placeholders()
	var active_scroll_perf := {}
	if host.fishing_scroll_perf_active:
		active_scroll_perf = {
			"durationMsec": maxi(0, Time.get_ticks_msec() - host.fishing_scroll_perf_start_msec),
			"frames": host.fishing_scroll_perf_frames,
			"maxFrameMsec": host.fishing_scroll_perf_max_delta_msec,
			"over50": host.fishing_scroll_perf_over_50_frames,
			"scrollDelta": host.fishing_scroll_perf_last_scroll - host.fishing_scroll_perf_start_scroll
		}
	var publish_culling_detail: bool = force or not host.fishing_scroll_perf_active
	var render_cull_state: Dictionary = _fishing_detail_render_cull_counts() if publish_culling_detail else {}
	var visible_culled_state: int = _fishing_detail_visible_culled_count() if publish_culling_detail else 0
	var state := {
		"ready": web_fishing_perf_probe_ready,
		"screen": host.current_screen,
		"skill": host.selected_skill_id,
		"scroll": scroll_y,
		"maxScroll": max_scroll,
		"mounted": mounted_count,
		"plan": host.detail_lazy_plan.size(),
		"cards": host.action_cards.size(),
		"renderCull": render_cull_state,
		"visibleCulled": visible_culled_state,
		"visiblePlaceholders": visible_placeholders,
		"texturePrewarmQueue": host.detail_texture_prewarm_request_queue.size(),
		"texturePrewarmPending": host.detail_texture_prewarm_pending.size(),
		"drag": drag_active,
		"velocity": scroll_velocity,
		"scrollPerfActive": active_scroll_perf,
		"scrollPerfLast": host.fishing_scroll_perf_last_summary,
		"godotMsec": Time.get_ticks_msec(),
		"frame": Engine.get_process_frames()
	}
	web_fishing_perf_probe_last_scroll = scroll_y
	web_fishing_perf_probe_last_mounted = mounted_count
	JavaScriptBridge.eval("window.__idleEliteFishingPerf = %s;" % JSON.stringify(state), false)
	web_fishing_perf_probe_last_publish_msec = Time.get_ticks_msec()


func _add_fishing_boot_warmup_texture_paths(paths: Array) -> void:
	var boot_warmup = host._boot_warmup_runtime()
	for tool in host.FISHING_TOOL_DEFS:
		boot_warmup._add_boot_warmup_texture_path(paths, str((tool as Dictionary).get("art", "")))
	_add_fishing_detail_visual_texture_paths(paths)


func _add_fishing_detail_visual_texture_paths(paths: Array) -> void:
	var boot_warmup = host._boot_warmup_runtime()
	boot_warmup._add_boot_warmup_texture_path(paths, host.FISH_CURRENCY_ICON_TEXTURE)
	boot_warmup._add_boot_warmup_texture_path(paths, host.FISHING_LOCATION_THUMBNAIL_SHEET)
	for raw_area in host.fishing_runtime.area_definitions:
		var area_def := raw_area as Dictionary
		var area_bg_path := str(area_def.get("bg", ""))
		if str(area_def.get("id", "")) == "beach" and ResourceLoader.exists("res://assets/content/fishing/backgrounds/beach-rocky-zoom.png"):
			area_bg_path = "res://assets/content/fishing/backgrounds/beach-rocky-zoom.png"
		boot_warmup._add_boot_warmup_texture_path(paths, area_bg_path)
		var area_id := str(area_def.get("id", ""))
		if host._fishing_area_uses_location_tiles(area_def):
			for raw_location in host._fishing_locations_for_area(area_id):
				var location := raw_location as Dictionary
				boot_warmup._add_boot_warmup_texture_path(paths, host._fishing_location_thumbnail_path(area_id, str(location.get("id", ""))))
	for raw_tool in host.FISHING_TOOL_DEFS:
		var tool := raw_tool as Dictionary
		boot_warmup._add_boot_warmup_texture_path(paths, str(tool.get("art", "")))
	for raw_catch_path in FishingState.FISHING_ACTION_CATCH_TEXTURE_PATHS.values():
		boot_warmup._add_boot_warmup_texture_path(paths, str(raw_catch_path))


func _process_fishing_scroll_perf_probe(delta: float, scroll_active: bool) -> void:
	if not OS.is_debug_build() and not host.web_fishing_perf_probe_enabled:
		return
	if host.current_screen != "skill" or not host._fishing_rework_active_for_skill(host.selected_skill_id):
		if host.fishing_scroll_perf_active:
			_finish_fishing_scroll_perf_probe("left_page")
		return
	var scroll := host._valid_control_ref(host.detail_actions_scroll) as MobileScrollContainer
	if scroll == null:
		if host.fishing_scroll_perf_active:
			_finish_fishing_scroll_perf_probe("missing_scroll")
		return
	var active := scroll_active or scroll.drag_scrolling or absf(scroll.velocity) >= 4.0
	if not active:
		if host.fishing_scroll_perf_active:
			_finish_fishing_scroll_perf_probe("settled")
		return
	var scroll_y := float(scroll.scroll_vertical)
	if not host.fishing_scroll_perf_active:
		host.fishing_scroll_perf_active = true
		host.fishing_scroll_perf_start_msec = Time.get_ticks_msec()
		host.fishing_scroll_perf_frames = 0
		host.fishing_scroll_perf_over_50_frames = 0
		host.fishing_scroll_perf_max_delta_msec = 0.0
		host.fishing_scroll_perf_start_scroll = scroll_y
	host.fishing_scroll_perf_last_scroll = scroll_y
	host.fishing_scroll_perf_frames += 1
	var frame_msec := maxf(0.0, delta * 1000.0)
	host.fishing_scroll_perf_max_delta_msec = maxf(host.fishing_scroll_perf_max_delta_msec, frame_msec)
	if frame_msec > 50.0:
		host.fishing_scroll_perf_over_50_frames += 1
	if host.web_fishing_perf_probe_enabled:
		_publish_web_fishing_perf_probe_state()


func _finish_fishing_scroll_perf_probe(reason: String) -> void:
	if host.current_screen == "skill" and host._fishing_rework_active_for_skill(host.selected_skill_id):
		host._sync_fishing_detail_visible_viewport_cards(host.FISHING_DETAIL_VISIBLE_SETTLE_FILL_BUDGET)
		_sync_fishing_detail_render_culling(true)
	var duration_msec := maxi(0, Time.get_ticks_msec() - host.fishing_scroll_perf_start_msec)
	var scroll_delta: float = host.fishing_scroll_perf_last_scroll - host.fishing_scroll_perf_start_scroll
	var render_counts: Dictionary = _fishing_detail_render_cull_counts()
	host.fishing_scroll_perf_last_summary = {
		"reason": reason,
		"durationMsec": duration_msec,
		"frames": host.fishing_scroll_perf_frames,
		"maxFrameMsec": host.fishing_scroll_perf_max_delta_msec,
		"over50": host.fishing_scroll_perf_over_50_frames,
		"scrollDelta": scroll_delta,
		"mounted": _web_fishing_perf_probe_mounted_count(),
		"rendered": int(render_counts.get("rendered", 0)),
		"culled": int(render_counts.get("culled", 0)),
		"cards": host.action_cards.size()
	}
	print("FISHING_SCROLL_PERF reason=%s duration_ms=%s frames=%s max_frame_ms=%.2f over50=%s scroll_delta=%.1f mounted=%s rendered=%s culled=%s cards=%s" % [
		reason,
		str(duration_msec),
		str(host.fishing_scroll_perf_frames),
		host.fishing_scroll_perf_max_delta_msec,
		str(host.fishing_scroll_perf_over_50_frames),
		scroll_delta,
		str(_web_fishing_perf_probe_mounted_count()),
		str(int(render_counts.get("rendered", 0))),
		str(int(render_counts.get("culled", 0))),
		str(host.action_cards.size())
	])
	host.fishing_scroll_perf_active = false
	host.fishing_scroll_perf_start_msec = 0
	host.fishing_scroll_perf_frames = 0
	host.fishing_scroll_perf_over_50_frames = 0
	host.fishing_scroll_perf_max_delta_msec = 0.0
	host.fishing_scroll_perf_start_scroll = 0.0
	host.fishing_scroll_perf_last_scroll = 0.0
	if host.web_fishing_perf_probe_enabled:
		_publish_web_fishing_perf_probe_state(true)


func _process_fishing_scroll_mode(scroll_visual_work: bool) -> void:
	if host.current_screen != "skill" or not host._fishing_rework_active_for_skill(host.selected_skill_id):
		_set_fishing_scroll_mode_active(false)
		return
	var scroll := host._valid_control_ref(host.detail_actions_scroll) as MobileScrollContainer
	if scroll == null:
		_set_fishing_scroll_mode_active(false)
		return
	var confirmed_scroll := scroll.drag_scrolling or absf(scroll.velocity) >= 4.0
	if confirmed_scroll:
		host.fishing_scroll_mode_release_msec = Time.get_ticks_msec() + host.FISHING_SCROLL_MODE_SETTLE_MSEC
		_set_fishing_scroll_mode_active(true)
		return
	if host.fishing_scroll_mode_active:
		var still_settling: bool = scroll_visual_work and Time.get_ticks_msec() <= host.fishing_scroll_mode_release_msec
		_set_fishing_scroll_mode_active(still_settling)


func _fishing_detail_scroll_is_actively_moving() -> bool:
	if host.current_screen != "skill" or not host._fishing_rework_active_for_skill(host.selected_skill_id):
		return false
	var scroll := host._valid_control_ref(host.detail_actions_scroll) as MobileScrollContainer
	if scroll == null:
		return false
	return (
		host.fishing_detail_primary_pointer_down
		or scroll.drag_tracking
		or scroll.drag_scrolling
		or absf(scroll.velocity) >= 4.0
		or host.fishing_scroll_mode_active
	)


func _set_fishing_scroll_mode_active(active: bool) -> void:
	if host.fishing_scroll_mode_active == active:
		return
	var was_active: bool = host.fishing_scroll_mode_active
	host.fishing_scroll_mode_active = active
	_sync_fishing_scroll_mouse_pick_suspension(active)
	if was_active and not active and host.current_screen == "skill" and host._fishing_rework_active_for_skill(host.selected_skill_id):
		host._sync_fishing_detail_visible_viewport_cards(host.FISHING_DETAIL_VISIBLE_SETTLE_FILL_BUDGET)
		_sync_fishing_detail_render_culling(true)


func _maybe_end_fishing_scroll_mode_for_new_press(event: InputEvent) -> void:
	if not host.fishing_scroll_mode_active:
		return
	if host.current_screen != "skill" or not host._fishing_rework_active_for_skill(host.selected_skill_id):
		_set_fishing_scroll_mode_active(false)
		return
	if not host._is_primary_press_event(event):
		return
	var event_position: Vector2 = host._input_routing_shell()._fishing_detail_event_position(event)
	if event_position == Vector2.INF:
		return
	if host._position_inside_bottom_interactive_ui(event_position) or not host._position_inside_detail_actions_viewport(event_position):
		return
	var active_scroll: MobileScrollContainer = host._active_action_scroll_container()
	if active_scroll != null and is_instance_valid(active_scroll):
		active_scroll.prepare_child_tap()
	_set_fishing_scroll_mode_active(false)


func _fishing_detail_render_cull_counts() -> Dictionary:
	return host.fishing_detail_render_cull_counts_cache


func _fishing_detail_visible_culled_count() -> int:
	return host.fishing_detail_visible_culled_count_cache


func _reset_fishing_detail_render_cull_cache() -> void:
	host.fishing_detail_render_cull_counts_cache = {"rendered": 0, "culled": 0}
	host.fishing_detail_visible_culled_count_cache = 0


func _sync_fishing_scroll_mouse_pick_suspension(active: bool) -> void:
	if host.current_screen != "skill" or not host._fishing_rework_active_for_skill(host.selected_skill_id):
		active = false
	host.fishing_scroll_mouse_pick_suspended = active


func _sync_fishing_detail_render_culling(force := false) -> void:
	if host.current_screen != "skill" or not host._fishing_rework_active_for_skill(host.selected_skill_id):
		_sync_fishing_scroll_mouse_pick_suspension(false)
		_restore_fishing_detail_render_culling()
		_reset_fishing_detail_render_cull_cache()
		return
	if _fishing_ablation_enabled("no_lazy"):
		_restore_fishing_detail_render_culling()
		_reset_fishing_detail_render_cull_cache()
		return
	if host.detail_lazy_plan.is_empty() or host.detail_actions_scroll == null or not is_instance_valid(host.detail_actions_scroll):
		_reset_fishing_detail_render_cull_cache()
		return
	if host._skill_detail_surface()._detail_lazy_all_mounted():
		_restore_fishing_detail_render_culling()
		_reset_fishing_detail_render_cull_cache()
		return
	var scroll_y: float = host._detail_lazy_scroll_y()
	if not force:
		var cull_scroll_step: float = host.FISHING_DETAIL_RENDER_CULL_ACTIVE_STEP_PX if host.detail_scroll_visual_work_this_frame else 24.0
		var cull_min_msec: int = host.FISHING_DETAIL_RENDER_CULL_ACTIVE_MIN_MSEC if host.detail_scroll_visual_work_this_frame else 0
		var cull_elapsed_msec: int = Time.get_ticks_msec() - host.detail_lazy_render_cull_last_msec
		if absf(scroll_y - host.detail_lazy_render_cull_last_scroll) < cull_scroll_step:
			return
		if cull_min_msec > 0 and cull_elapsed_msec < cull_min_msec:
			return
	host.detail_lazy_render_cull_last_scroll = scroll_y
	host.detail_lazy_render_cull_last_msec = Time.get_ticks_msec()
	var viewport_height: float = host._detail_lazy_viewport_height()
	var viewport_top: float = scroll_y
	var viewport_bottom: float = scroll_y + viewport_height
	var reveal_top: float = scroll_y - host.FISHING_DETAIL_RENDER_REVEAL_BUFFER_PX
	var reveal_bottom: float = scroll_y + viewport_height + host.FISHING_DETAIL_RENDER_REVEAL_BUFFER_PX
	var hide_top: float = scroll_y - host.FISHING_DETAIL_RENDER_HIDE_BUFFER_PX
	var hide_bottom: float = scroll_y + viewport_height + host.FISHING_DETAIL_RENDER_HIDE_BUFFER_PX
	var rendered_count := 0
	var culled_count := 0
	var visible_culled_count := 0
	for raw_lazy_entry in host.detail_lazy_plan:
		var lazy_entry := raw_lazy_entry as Dictionary
		if not bool(lazy_entry.get("mounted", false)):
			continue
		var kind := str(lazy_entry.get("kind", ""))
		if kind not in ["action", "passive", "fishing_area", "fishing_offer"]:
			continue
		var stack_host: Control = host._valid_control_ref(lazy_entry.get("stack_host"))
		if stack_host == null:
			continue
		var content_root: Control = host._detail_lazy_primary_child_control(stack_host)
		if content_root == null or content_root == stack_host:
			continue
		var entry_top: float = float(lazy_entry.get("y", 0.0)) + host._detail_actions_top_spacer_height()
		var entry_height := maxf(float(lazy_entry.get("height", 0.0)), stack_host.custom_minimum_size.y)
		var entry_bottom: float = entry_top + entry_height
		var culled := bool(content_root.get_meta("detail_lazy_render_culled", false))
		var should_render := entry_height <= 1.0
		if culled:
			should_render = should_render or (entry_bottom >= reveal_top and entry_top <= reveal_bottom)
		else:
			should_render = should_render or (entry_bottom >= hide_top and entry_top <= hide_bottom)
		var next_culled := not should_render
		if next_culled:
			culled_count += 1
			if entry_bottom >= viewport_top and entry_top <= viewport_bottom:
				visible_culled_count += 1
		else:
			rendered_count += 1
		_set_detail_lazy_render_culled(content_root, next_culled)
	host.fishing_detail_render_cull_counts_cache = {"rendered": rendered_count, "culled": culled_count}
	host.fishing_detail_visible_culled_count_cache = visible_culled_count


func _restore_fishing_detail_render_culling() -> void:
	if host.detail_lazy_plan.is_empty():
		_reset_fishing_detail_render_cull_cache()
		return
	if host.detail_lazy_render_cull_last_scroll <= -999998.0:
		return
	host.detail_lazy_render_cull_last_scroll = -999999.0
	host.detail_lazy_render_cull_last_msec = 0
	for raw_lazy_entry in host.detail_lazy_plan:
		var lazy_entry := raw_lazy_entry as Dictionary
		var stack_host: Control = host._valid_control_ref(lazy_entry.get("stack_host"))
		if stack_host == null:
			continue
		var content_root: Control = host._detail_lazy_primary_child_control(stack_host)
		if content_root != null and content_root != stack_host:
			_set_detail_lazy_render_culled(content_root, false)
	_reset_fishing_detail_render_cull_cache()


func _set_detail_lazy_render_culled(content_root: Control, culled: bool) -> void:
	if content_root == null or not is_instance_valid(content_root):
		return
	if culled:
		if not bool(content_root.get_meta("detail_lazy_render_culled", false)):
			content_root.set_meta("detail_lazy_render_culled", true)
			content_root.set_meta("detail_lazy_render_previous_process_mode", int(content_root.process_mode))
			content_root.set_meta("detail_lazy_render_previous_mouse_filter", int(content_root.mouse_filter))
		if content_root.process_mode != Node.PROCESS_MODE_DISABLED:
			content_root.process_mode = Node.PROCESS_MODE_DISABLED
		if content_root.visible:
			content_root.visible = false
			content_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return
	if bool(content_root.get_meta("detail_lazy_render_culled", false)):
		content_root.remove_meta("detail_lazy_render_culled")
	if content_root.has_meta("detail_lazy_render_previous_process_mode"):
		content_root.process_mode = int(content_root.get_meta("detail_lazy_render_previous_process_mode"))
		content_root.remove_meta("detail_lazy_render_previous_process_mode")
	elif content_root.process_mode == Node.PROCESS_MODE_DISABLED:
		content_root.process_mode = Node.PROCESS_MODE_INHERIT
	if content_root.has_meta("detail_lazy_render_previous_mouse_filter"):
		content_root.mouse_filter = int(content_root.get_meta("detail_lazy_render_previous_mouse_filter"))
		content_root.remove_meta("detail_lazy_render_previous_mouse_filter")
	if not content_root.visible:
		content_root.visible = true


func _render_fishing_tool_popup_menu() -> void:
	if host.detail_fish_circle == null or not is_instance_valid(host.detail_fish_circle):
		return
	_clear_fishing_tool_circle_menu()
	host.fishing_tool_wallet_open = true
	var visible_wallet_tools = host._fishing_visible_wallet_tool_defs()
	var row_count = visible_wallet_tools.size()
	if row_count <= 0:
		return
	var circle_rect = host.detail_fish_circle.get_global_rect()
	var gear_button_size = clampf(minf(circle_rect.size.x, circle_rect.size.y) * 0.60, 240.0, 336.0)
	if gear_button_size <= 0.0:
		gear_button_size = 296.0
	var column_count = mini(3, row_count)
	var grid_rows = int(ceil(float(row_count) / float(column_count)))
	var gear_gap = maxf(24.0, gear_button_size * 0.08)
	var panel_padding = maxf(30.0, gear_button_size * 0.10)
	var panel_width = panel_padding * 2.0 + float(column_count) * gear_button_size + float(maxi(0, column_count - 1)) * gear_gap
	var panel_height = panel_padding * 2.0 + float(grid_rows) * gear_button_size + float(maxi(0, grid_rows - 1)) * gear_gap
	var viewport_size = host.get_viewport_rect().size
	var panel_left = clampf(circle_rect.get_center().x - panel_width * 0.5, 12.0, maxf(12.0, viewport_size.x - panel_width - 12.0))
	var panel_top = circle_rect.end.y + maxf(14.0, gear_button_size * 0.08)
	if panel_top + panel_height > viewport_size.y - 12.0:
		panel_top = maxf(12.0, viewport_size.y - panel_height - 12.0)
	var canvas = CanvasLayer.new()
	canvas.name = "FishingToolWalletCanvas"
	canvas.layer = 120
	host.add_child(canvas)
	host.fishing_tool_wallet_canvas = canvas
	var popup = Panel.new()
	popup.name = "FishingToolPopupWallet"
	popup.position = Vector2(panel_left, panel_top)
	popup.size = Vector2(panel_width, panel_height)
	popup.custom_minimum_size = Vector2(panel_width, panel_height)
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup.clip_contents = false
	popup.pivot_offset = Vector2(panel_width * 0.5, 0.0)
	popup.scale = Vector2(0.88, 0.18)
	popup.modulate = Color(1, 1, 1, 0)
	popup.add_theme_stylebox_override("panel", _fishing_tool_wallet_popup_style(Vector2(panel_width, panel_height)))
	canvas.add_child(popup)
	host.fishing_tool_wallet_popup = popup
	var column = Control.new()
	column.position = Vector2(panel_padding, panel_padding)
	column.size = Vector2(panel_width - panel_padding * 2.0, panel_height - panel_padding * 2.0)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup.add_child(column)
	for index in range(visible_wallet_tools.size()):
		var tool = visible_wallet_tools[index] as Dictionary
		var tool_id = str(tool.get("id", ""))
		var unlocked = host.fishing_runtime.tool_is_unlocked(tool_id)
		var equipped = tool_id == host.equipped_fishing_tool_id
		var button = Button.new()
		button.name = "FishingToolPopupButton%s" % str(index)
		button.set_meta("tool_id", tool_id)
		button.set_meta("tool_unlocked", unlocked)
		button.custom_minimum_size = Vector2(gear_button_size, gear_button_size)
		button.size = Vector2(gear_button_size, gear_button_size)
		var grid_column = index % column_count
		var grid_row = int(floor(float(index) / float(column_count)))
		var target_y = float(grid_row) * (gear_button_size + gear_gap)
		button.position.x = float(grid_column) * (gear_button_size + gear_gap)
		button.position.y = target_y
		button.set_meta("wallet_target_y", target_y)
		button.clip_contents = true
		button.text = ""
		button.disabled = not unlocked
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.modulate = Color(1, 1, 1, 0)
		button.position.y -= gear_button_size * 0.10
		button.add_theme_stylebox_override("normal", _fishing_tool_circle_button_style(equipped, unlocked))
		button.add_theme_stylebox_override("hover", _fishing_tool_circle_button_style(equipped, unlocked))
		button.add_theme_stylebox_override("pressed", _fishing_tool_circle_button_style(equipped, unlocked, true))
		button.add_theme_stylebox_override("disabled", _fishing_tool_circle_button_style(equipped, false))
		button.pressed.connect(host._on_fishing_tool_selected.bind(tool_id))
		column.add_child(button)
		var icon_size = Vector2(gear_button_size * 0.66, gear_button_size * 0.66)
		var icon = host.visual_texture_cache._image_from_texture(host._fishing_tool_icon_texture(tool_id), icon_size, str(tool.get("art", "")))
		icon.set_anchors_preset(Control.PRESET_CENTER)
		icon.offset_left = -icon_size.x * 0.5
		icon.offset_right = icon_size.x * 0.5
		icon.offset_top = -icon_size.y * 0.5
		icon.offset_bottom = icon_size.y * 0.5
		icon.size = icon_size
		icon.modulate = Color.WHITE if unlocked else Color(1, 1, 1, 0.42)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(icon)
	popup.show()
	var tween = host.create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "modulate:a", 1.0, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	for index in range(column.get_child_count()):
		var button = column.get_child(index) as Control
		if button == null:
			continue
		var delay = 0.025 * float(index)
		tween.tween_property(button, "position:y", float(button.get_meta("wallet_target_y", 0.0)), 0.15).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "modulate:a", 1.0, 0.08).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _clear_fishing_tool_circle_menu() -> void:
	host.fishing_tool_wallet_open = false
	if host.fishing_tool_wallet_popup != null and is_instance_valid(host.fishing_tool_wallet_popup):
		host.fishing_tool_wallet_popup.queue_free()
	if host.fishing_tool_wallet_canvas != null and is_instance_valid(host.fishing_tool_wallet_canvas):
		host.fishing_tool_wallet_canvas.queue_free()
	elif host.fishing_tool_wallet_layer != null and is_instance_valid(host.fishing_tool_wallet_layer):
		host.fishing_tool_wallet_layer.queue_free()
	host.fishing_tool_wallet_layer = null
	host.fishing_tool_wallet_canvas = null
	host.fishing_tool_wallet_popup = null
	if host.detail_fish_circle != null and is_instance_valid(host.detail_fish_circle):
		host.detail_fish_circle.set_wallet_open_visual(false)
		host.detail_fish_circle.wallet_button_rects.clear()
		if host.detail_fish_circle.wallet_visual_root != null and is_instance_valid(host.detail_fish_circle.wallet_visual_root):
			host.detail_fish_circle.wallet_visual_root.queue_free()
			host.detail_fish_circle.wallet_visual_root = null


func _set_fishing_tool_wallet_open(open: bool) -> void:
	if not host._fishing_rework_active_for_skill(host.selected_skill_id):
		open = false
	if host.fishing_tool_wallet_open == open and (not open or (host.fishing_tool_wallet_popup != null and is_instance_valid(host.fishing_tool_wallet_popup))):
		return
	var now_msec := Time.get_ticks_msec()
	if host.fishing_tool_wallet_last_toggle_msec > 0 and now_msec - host.fishing_tool_wallet_last_toggle_msec < 180:
		return
	host.fishing_tool_wallet_last_toggle_msec = now_msec
	_play_fishing_wallet_circle_pop()
	if open:
		host._audio_director()._play_chain_impact_cluster(2, 0.34, "drag_start", 1.0)
		host._audio_director()._play_chain_jingle_mix(1, 0.16, 0.34, 0.16)
	host.fishing_tool_wallet_open = open
	if open:
		_render_fishing_tool_popup_menu()
	else:
		_clear_fishing_tool_circle_menu()
	if host.detail_fish_circle != null and is_instance_valid(host.detail_fish_circle):
		host.detail_fish_circle.set_wallet_open_visual(open)


func _play_fishing_wallet_circle_pop(delay := 0.0) -> void:
	if host.detail_fish_circle == null or not is_instance_valid(host.detail_fish_circle):
		return
	host.detail_fish_circle.pivot_offset = host.detail_fish_circle.size * 0.5
	if host.fishing_tool_wallet_pop_tween != null and host.fishing_tool_wallet_pop_tween.is_valid():
		host.fishing_tool_wallet_pop_tween.kill()
	host.detail_fish_circle.scale = Vector2.ONE
	host.fishing_tool_wallet_pop_tween = host.create_tween()
	if delay > 0.0:
		host.fishing_tool_wallet_pop_tween.tween_interval(delay)
	host.fishing_tool_wallet_pop_tween.tween_property(host.detail_fish_circle, "scale", Vector2(1.08, 1.08), 0.075).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	host.fishing_tool_wallet_pop_tween.tween_property(host.detail_fish_circle, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _show_fishing_tool_not_unlocked_feedback(anchor: Control = null, global_point := Vector2.ZERO, use_global_point := false) -> void:
	var target := anchor
	if target == null or not is_instance_valid(target) or not target.is_inside_tree():
		target = host.detail_fish_circle
	if target == null or not is_instance_valid(target) or not target.is_inside_tree():
		return
	host._audio_director()._play_failure_sfx()
	var anchor_x := -1.0
	if use_global_point:
		anchor_x = clampf(target.to_local(global_point).x, 0.0, target.size.x)
	host._reward_feedback_surface()._float_reward(
		host,
		target,
		"not unlocked",
		54,
		Color("#ffd95a"),
		Vector2(0, -34),
		Vector2(0, -142),
		0.0,
		false,
		anchor_x
	)


func _fishing_wallet_event_point(event: InputEvent) -> Dictionary:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			return {"pressed": true, "point": mouse_event.global_position}
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			return {"pressed": true, "point": touch_event.position}
	return {"pressed": false, "point": Vector2.ZERO}


func _route_fishing_wallet_unhandled_input(event: InputEvent) -> bool:
	if host.current_screen != "skill" or not host._fishing_rework_active_for_skill(host.selected_skill_id):
		return false
	if host._input_routing_shell()._any_modal_overlay_visible():
		return false
	var parsed := _fishing_wallet_event_point(event)
	if not bool(parsed.get("pressed", false)):
		return false
	var point := parsed.get("point", Vector2.ZERO) as Vector2
	if host.fishing_tool_wallet_open:
		if host.fishing_tool_wallet_popup != null and is_instance_valid(host.fishing_tool_wallet_popup):
			for child in host.fishing_tool_wallet_popup.find_children("FishingToolPopupButton*", "Button", true, false):
				var button := child as Button
				if button == null:
					continue
				if button.get_global_rect().has_point(point):
					if bool(button.get_meta("tool_unlocked", false)):
						host._on_fishing_tool_selected(str(button.get_meta("tool_id", "")))
					else:
						_show_fishing_tool_not_unlocked_feedback(button)
					return true
			if host.fishing_tool_wallet_popup.get_global_rect().has_point(point):
				return true
		if host.detail_fish_circle != null and is_instance_valid(host.detail_fish_circle) and host.detail_fish_circle.get_global_rect().grow(16.0).has_point(point):
			var circle_tool_index: int = host.detail_fish_circle.wallet_button_index_at(point)
			if (
				circle_tool_index >= 0
				and circle_tool_index < host.detail_fish_circle.wallet_tool_ids.size()
				and circle_tool_index < host.detail_fish_circle.wallet_unlocked_states.size()
			):
				if bool(host.detail_fish_circle.wallet_unlocked_states[circle_tool_index]):
					host._on_fishing_tool_selected(str(host.detail_fish_circle.wallet_tool_ids[circle_tool_index]))
				else:
					_show_fishing_tool_not_unlocked_feedback(host.detail_fish_circle, point, true)
				return true
			_set_fishing_tool_wallet_open(false)
			return true
		return false
	if host.detail_fish_circle != null and is_instance_valid(host.detail_fish_circle) and host.detail_fish_circle.get_global_rect().grow(16.0).has_point(point):
		_set_fishing_tool_wallet_open(true)
		return true
	return false


func _on_fishing_tool_wallet_pressed() -> void:
	_set_fishing_tool_wallet_open(not host.fishing_tool_wallet_open)


func _fishing_tool_wallet_popup_style(panel_size: Vector2) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#e8fbf6", 0.95)
	style.border_color = Color("#168f83")
	style.border_width_left = 6
	style.border_width_top = 6
	style.border_width_right = 6
	style.border_width_bottom = 6
	var corner = int(panel_size.x * 0.5)
	style.corner_radius_top_left = corner
	style.corner_radius_top_right = corner
	style.corner_radius_bottom_left = corner
	style.corner_radius_bottom_right = corner
	style.shadow_color = Color(0, 0, 0, 0.2)
	style.shadow_size = 10
	style.shadow_offset = Vector2(4, 6)
	return style


func _fishing_tool_circle_button_style(equipped: bool, unlocked: bool, pressed = false) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#e8f7f6") if equipped else (Color("#fffdf8") if unlocked else Color("#cfcac0"))
	if pressed:
		style.bg_color = style.bg_color.darkened(0.08)
	style.border_color = host.COLOR_GOLD if equipped else (host.COLOR_INK if unlocked else host.COLOR_MUTED)
	style.border_width_left = 8 if equipped else 5
	style.border_width_top = 8 if equipped else 5
	style.border_width_right = 8 if equipped else 5
	style.border_width_bottom = 8 if equipped else 5
	style.corner_radius_top_left = 999
	style.corner_radius_top_right = 999
	style.corner_radius_bottom_left = 999
	style.corner_radius_bottom_right = 999
	style.shadow_color = Color(0, 0, 0, 0.22) if unlocked else Color.TRANSPARENT
	style.shadow_size = 6 if unlocked else 0
	style.shadow_offset = Vector2(3, 5) if unlocked else Vector2.ZERO
	return style


func _fishing_detail_render_signature() -> Array:
	var signature: Array = [
		"tool:%s" % host.equipped_fishing_tool_id,
		"net-offer:%s:%s" % [str(host.fishing_net_collected), str(host._fishing_net_offer_available())],
		"rod-offer:%s:%s" % [str(host.fishing_rod_collected), str(host._fishing_rod_offer_available())],
		"reinforced-rod-offer:%s:%s" % [str(host.fishing_reinforced_rod_collected), str(host._fishing_reinforced_rod_offer_available())],
		"star-rod-offer:%s:%s" % [str(host.fishing_star_rod_collected), str(host._fishing_star_rod_offer_available())],
		"boat-offer:%s:%s:%s:%s" % [str(host.fishing_boat_built), str(host._fishing_boat_offer_available()), str(host._skill_level("build")), str(host.material_runtime.amount("softwood"))],
		"mirror-offer:%s:%s" % [str(host.fishing_mirror_collected), str(host._fishing_mirror_offer_available())],
	]
	for action in host._visible_actions_for_skill("fishing"):
		if host._is_passive_action(action as Dictionary):
			signature.append(str(action.get("id", "")))
	var inserted_actions: Array = host.fishing_runtime.standalone_and_event_actions_for_render(host, "fishing")
	var inserted_index := 0
	for area_def in host._fishing_render_area_modules("fishing"):
		var unlock_level: int = host._fishing_render_module_unlock(area_def)
		while inserted_index < inserted_actions.size() and host._activity_data_catalog().activity_action_display_sort_level(inserted_actions[inserted_index] as Dictionary) <= unlock_level:
			signature.append(str((inserted_actions[inserted_index] as Dictionary).get("id", "")))
			inserted_index += 1
		signature.append("area:%s" % str(area_def.get("id", "")))
		if host._fishing_area_uses_location_tiles(area_def):
			var area_id := str(area_def.get("id", ""))
			if int(area_def.get("module_index", -1)) >= 0:
				signature.append("area-module:%s:%s" % [area_id, int(area_def.get("module_index", 0))])
			for raw_location in host._fishing_locations_for_area_module(area_def):
				var location := raw_location as Dictionary
				if host._fishing_location_should_show(area_id, location):
					signature.append("location-tile:%s:%s" % [area_id, str(location.get("id", ""))])
			continue
		if int(area_def.get("module_index", -1)) >= 0:
			signature.append("area-module:%s:%s" % [str(area_def.get("id", "")), int(area_def.get("module_index", 0))])
		for method_id in area_def.get("methods", []):
			if host._fishing_method_should_show("fishing", str(method_id)):
				signature.append(str(method_id))
	while inserted_index < inserted_actions.size():
		signature.append(str((inserted_actions[inserted_index] as Dictionary).get("id", "")))
		inserted_index += 1
	return signature


func _build_fishing_detail_lazy_plan(skill_id: String) -> Array:
	var plan: Array = []
	var y = 0.0
	for action in host._visible_actions_for_skill(skill_id):
		var action_data = action as Dictionary
		if not host._is_passive_action(action_data):
			continue
		var action_id = str(action_data.get("id", ""))
		if action_id.is_empty():
			continue
		var passive_height = float(host.PASSIVE_MODULE_CARD_HEIGHT)
		var passive_module_key = ModuleUiRuntime.action_for_record(skill_id, action_data, host.FISHING_ACTION_ID_ALIASES)
		if host._module_ui_is_collapsed(passive_module_key):
			passive_height = host._module_collapsed_squeeze_height()
		var passive_entry = {
			"kind": "passive",
			"entry": {"action": action_data},
			"track_id": action_id,
			"y": y,
			"height": passive_height,
			"mounted": false,
			"stack_host": null,
			"placeholder": null,
			"direct_stack_child": false
		}
		plan.append(passive_entry)
		y += float(passive_entry["height"]) + host.DETAIL_LAZY_STACK_SEPARATION

	var net_offer_rendered = false
	var rod_offer_rendered = false
	var reinforced_rod_offer_rendered = false
	var star_rod_offer_rendered = false
	var boat_offer_rendered = false
	var mirror_offer_rendered = false
	var inserted_actions = host.fishing_runtime.standalone_and_event_actions_for_render(host, skill_id)
	var inserted_index = 0
	for area_def in host._fishing_render_area_modules(skill_id):
		var unlock_level = host._fishing_render_module_unlock(area_def)
		while inserted_index < inserted_actions.size() and host._activity_data_catalog().activity_action_display_sort_level(inserted_actions[inserted_index] as Dictionary) <= unlock_level:
			y = host._append_fishing_action_lazy_entry(plan, y, inserted_actions[inserted_index] as Dictionary)
			inserted_index += 1
		if host._fishing_net_offer_available() and not net_offer_rendered and unlock_level > host.FISHING_NET_OFFER_UNLOCK_LEVEL:
			y = _append_fishing_offer_lazy_entry(plan, y, "net")
			net_offer_rendered = true
		if host._fishing_rod_offer_available() and not rod_offer_rendered and unlock_level > host.FISHING_ROD_OFFER_UNLOCK_LEVEL:
			y = _append_fishing_offer_lazy_entry(plan, y, "rod")
			rod_offer_rendered = true
		if host._fishing_reinforced_rod_offer_available() and not reinforced_rod_offer_rendered and unlock_level > host.FISHING_REINFORCED_ROD_UNLOCK_LEVEL:
			y = _append_fishing_offer_lazy_entry(plan, y, "reinforced_rod")
			reinforced_rod_offer_rendered = true
		if host._fishing_boat_offer_available() and not boat_offer_rendered and unlock_level > host.FISHING_BOAT_OFFER_UNLOCK_LEVEL:
			y = _append_fishing_offer_lazy_entry(plan, y, "boat")
			boat_offer_rendered = true
		if host._fishing_star_rod_offer_available() and not star_rod_offer_rendered and unlock_level > host.FISHING_STAR_ROD_UNLOCK_LEVEL:
			y = _append_fishing_offer_lazy_entry(plan, y, "star_rod")
			star_rod_offer_rendered = true
		if host._fishing_mirror_offer_available() and not mirror_offer_rendered and unlock_level > host.FISHING_MIRROR_OFFER_UNLOCK_LEVEL:
			y = _append_fishing_offer_lazy_entry(plan, y, "mirror")
			mirror_offer_rendered = true
		var area_key = host.fishing_runtime.area_module_key(skill_id, area_def)
		var area_height = float(host.ACTION_CARD_HEIGHT)
		var area_module_key = ModuleUiRuntime.fishing_area(host.fishing_runtime.area_module_key(skill_id, area_def))
		if host._module_ui_is_collapsed(area_module_key):
			area_height = host._module_collapsed_squeeze_height()
		var area_entry = {
			"kind": "fishing_area",
			"area_def": area_def,
			"track_id": area_key,
			"method_ids": host._fishing_area_module_method_ids(skill_id, area_def),
			"y": y,
			"height": area_height,
			"mounted": false,
			"stack_host": null,
			"placeholder": null,
			"direct_stack_child": false
		}
		plan.append(area_entry)
		y += float(area_entry["height"]) + host.DETAIL_LAZY_STACK_SEPARATION
	while inserted_index < inserted_actions.size():
		y = host._append_fishing_action_lazy_entry(plan, y, inserted_actions[inserted_index] as Dictionary)
		inserted_index += 1
	if host._fishing_net_offer_available() and not net_offer_rendered:
		y = _append_fishing_offer_lazy_entry(plan, y, "net")
	if host._fishing_rod_offer_available() and not rod_offer_rendered:
		y = _append_fishing_offer_lazy_entry(plan, y, "rod")
	if host._fishing_reinforced_rod_offer_available() and not reinforced_rod_offer_rendered:
		y = _append_fishing_offer_lazy_entry(plan, y, "reinforced_rod")
	if host._fishing_boat_offer_available() and not boat_offer_rendered:
		y = _append_fishing_offer_lazy_entry(plan, y, "boat")
	if host._fishing_star_rod_offer_available() and not star_rod_offer_rendered:
		y = _append_fishing_offer_lazy_entry(plan, y, "star_rod")
	if host._fishing_mirror_offer_available() and not mirror_offer_rendered:
		y = _append_fishing_offer_lazy_entry(plan, y, "mirror")
	return host.module_ui_runtime.sort_fishing_lazy_plan(
		plan,
		skill_id,
		host.DETAIL_LAZY_STACK_SEPARATION,
		Callable(host, "_detail_entry_level_sort_value"),
		Callable(host, "_action_is_combo_module"),
		Callable(host, "_action_is_collection_module")
	)


func _render_fishing_area_modules_preview(stack: VBoxContainer, content_width: float, state: Dictionary) -> void:
	var skill_id = "fishing"
	var net_offer_rendered = false
	var rod_offer_rendered = false
	var reinforced_rod_offer_rendered = false
	var star_rod_offer_rendered = false
	var boat_offer_rendered = false
	var mirror_offer_rendered = false
	for action in host._visible_actions_for_skill(skill_id):
		if not host._is_passive_action(action as Dictionary):
			continue
		var passive_card = host._passive_firepit_surface()._build_passive_module_card(skill_id, action as Dictionary, content_width, false)
		host._prepare_locked_activity_preview_fade(passive_card["card"] as Dictionary, skill_id, action as Dictionary)
		host._sync_locked_activity_preview_presence(passive_card["card"] as Dictionary, skill_id, action as Dictionary)
		stack.add_child(passive_card["root"] as Control)
		(state["host.action_cards"] as Array).append(passive_card["card"])

	var inserted_actions = host.fishing_runtime.standalone_and_event_actions_for_render(host, skill_id)
	var inserted_index = 0
	for area_def in host._fishing_render_area_modules(skill_id):
		var unlock_level = host._fishing_render_module_unlock(area_def)
		while inserted_index < inserted_actions.size() and host._activity_data_catalog().activity_action_display_sort_level(inserted_actions[inserted_index] as Dictionary) <= unlock_level:
			host._add_fishing_preview_standalone_action(stack, skill_id, inserted_actions[inserted_index] as Dictionary, content_width, state)
			inserted_index += 1
		if host._fishing_net_offer_available() and not net_offer_rendered and unlock_level > host.FISHING_NET_OFFER_UNLOCK_LEVEL:
			var net_offer = _build_fishing_net_offer_module(content_width)
			host._set_preview_controls_mouse_filter(net_offer)
			stack.add_child(net_offer)
			net_offer_rendered = true
		if host._fishing_rod_offer_available() and not rod_offer_rendered and unlock_level > host.FISHING_ROD_OFFER_UNLOCK_LEVEL:
			var rod_offer = _build_fishing_rod_offer_module(content_width)
			host._set_preview_controls_mouse_filter(rod_offer)
			stack.add_child(rod_offer)
			rod_offer_rendered = true
		if host._fishing_reinforced_rod_offer_available() and not reinforced_rod_offer_rendered and unlock_level > host.FISHING_REINFORCED_ROD_UNLOCK_LEVEL:
			var reinforced_offer = _build_fishing_rod_upgrade_offer_module(content_width, "reinforced_rod")
			host._set_preview_controls_mouse_filter(reinforced_offer)
			stack.add_child(reinforced_offer)
			reinforced_rod_offer_rendered = true
		if host._fishing_boat_offer_available() and not boat_offer_rendered and unlock_level > host.FISHING_BOAT_OFFER_UNLOCK_LEVEL:
			var boat_offer = _build_fishing_boat_offer_module(content_width)
			host._set_preview_controls_mouse_filter(boat_offer)
			stack.add_child(boat_offer)
			boat_offer_rendered = true
		if host._fishing_mirror_offer_available() and not mirror_offer_rendered and unlock_level > host.FISHING_MIRROR_OFFER_UNLOCK_LEVEL:
			var mirror_offer = _build_fishing_mirror_offer_module(content_width)
			host._set_preview_controls_mouse_filter(mirror_offer)
			stack.add_child(mirror_offer)
			mirror_offer_rendered = true
		if host._fishing_star_rod_offer_available() and not star_rod_offer_rendered and unlock_level > host.FISHING_STAR_ROD_UNLOCK_LEVEL:
			var star_offer = _build_fishing_rod_upgrade_offer_module(content_width, "star_rod")
			host._set_preview_controls_mouse_filter(star_offer)
			stack.add_child(star_offer)
			star_rod_offer_rendered = true
		var built = _build_fishing_area_module(skill_id, area_def, content_width)
		host._mark_fishing_preview_module_cards(built)
		var root = built["root"] as Control
		host._set_preview_controls_mouse_filter(root)
		stack.add_child(root)
		(state["fishing_built_modules"] as Array).append(built)
	while inserted_index < inserted_actions.size():
		host._add_fishing_preview_standalone_action(stack, skill_id, inserted_actions[inserted_index] as Dictionary, content_width, state)
		inserted_index += 1
	if host._fishing_net_offer_available() and not net_offer_rendered:
		var net_offer = _build_fishing_net_offer_module(content_width)
		host._set_preview_controls_mouse_filter(net_offer)
		stack.add_child(net_offer)
	if host._fishing_rod_offer_available() and not rod_offer_rendered:
		var rod_offer = _build_fishing_rod_offer_module(content_width)
		host._set_preview_controls_mouse_filter(rod_offer)
		stack.add_child(rod_offer)
	if host._fishing_reinforced_rod_offer_available() and not reinforced_rod_offer_rendered:
		var reinforced_offer = _build_fishing_rod_upgrade_offer_module(content_width, "reinforced_rod")
		host._set_preview_controls_mouse_filter(reinforced_offer)
		stack.add_child(reinforced_offer)
	if host._fishing_boat_offer_available() and not boat_offer_rendered:
		var boat_offer = _build_fishing_boat_offer_module(content_width)
		host._set_preview_controls_mouse_filter(boat_offer)
		stack.add_child(boat_offer)
	if host._fishing_star_rod_offer_available() and not star_rod_offer_rendered:
		var star_offer = _build_fishing_rod_upgrade_offer_module(content_width, "star_rod")
		host._set_preview_controls_mouse_filter(star_offer)
		stack.add_child(star_offer)
	if host._fishing_mirror_offer_available() and not mirror_offer_rendered:
		var mirror_offer = _build_fishing_mirror_offer_module(content_width)
		host._set_preview_controls_mouse_filter(mirror_offer)
		stack.add_child(mirror_offer)


func _build_fishing_location_tile(
	skill_id: String,
	area_id: String,
	area_key: String,
	location: Dictionary,
	method_row: HBoxContainer
) -> Dictionary:
	var location_id = str(location.get("id", ""))
	var action = host._fishing_location_display_action(area_id, location)
	if action.is_empty():
		return {}
	var action_id = str(action.get("id", ""))
	var location_unlocked = host._fishing_location_is_available(area_id, location)
	var action_unlocked = host._is_action_unlocked(skill_id, action)
	var unlocked = location_unlocked and action_unlocked
	var unlock_ready_pending = host._action_has_pending_unlock_readiness(action_id)

	var method_column = VBoxContainer.new()
	method_column.add_theme_constant_override("separation", host.FISHING_MODULE_TITLE_TOP)
	method_column.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	method_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	method_row.add_child(method_column)

	var method_title = host._label(str(location.get("name", location_id.capitalize())), 48, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	method_title.add_theme_color_override("font_outline_color", host.COLOR_INK)
	method_title.add_theme_constant_override("outline_size", host.FISHING_METHOD_TITLE_OUTLINE)
	method_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	method_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	method_title.custom_minimum_size.x = host.FISHING_LOCATION_TILE_SIZE.x
	method_title.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	method_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	method_column.add_child(method_title)

	var art_panel = Panel.new()
	art_panel.custom_minimum_size = host.FISHING_LOCATION_TILE_SIZE
	art_panel.size = host.FISHING_LOCATION_TILE_SIZE
	art_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	art_panel.clip_contents = false
	art_panel.add_theme_stylebox_override("panel", _fishing_location_tile_style(unlocked))
	art_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	method_column.add_child(art_panel)

	var tile_motion_root = Control.new()
	tile_motion_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	tile_motion_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile_motion_root.pivot_offset = host.FISHING_LOCATION_TILE_SIZE * 0.5
	art_panel.add_child(tile_motion_root)

	var tile_frame_clip = Control.new()
	tile_frame_clip.set_anchors_preset(Control.PRESET_FULL_RECT)
	tile_frame_clip.clip_contents = true
	tile_frame_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile_frame_clip.z_index = 1
	tile_motion_root.add_child(tile_frame_clip)

	var art_clip = Control.new()
	art_clip.set_anchors_preset(Control.PRESET_FULL_RECT)
	art_clip.clip_contents = true
	art_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_clip.z_index = 1
	tile_frame_clip.add_child(art_clip)

	var location_art: Control
	if _fishing_ablation_enabled("no_rounded_art"):
		var flat_location_art = TextureRect.new()
		flat_location_art.texture = host._fishing_location_thumbnail_texture(area_id, location_id)
		flat_location_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		flat_location_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		location_art = flat_location_art
	else:
		var rounded_location_art = RoundedTextureRect.new()
		rounded_location_art.texture = host._fishing_location_thumbnail_texture(area_id, location_id)
		rounded_location_art.radius = 30.0
		rounded_location_art.mask_inset = 10.0
		rounded_location_art.aspect_mode = 2
		rounded_location_art.fallback_color = Color("#224d45")
		location_art = rounded_location_art
	location_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	location_art.modulate = Color.WHITE if unlocked else Color(0.72, 0.72, 0.72, 0.82)
	location_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	location_art.pivot_offset = host.FISHING_LOCATION_TILE_SIZE * 0.5
	location_art.z_index = 1
	art_clip.add_child(location_art)

	var location_border = Panel.new()
	location_border.set_anchors_preset(Control.PRESET_FULL_RECT)
	location_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	location_border.z_index = 20
	location_border.add_theme_stylebox_override("panel", _fishing_location_tile_style(unlocked))
	tile_frame_clip.add_child(location_border)

	var medal = TextureRect.new()
	medal.anchor_left = 0.0
	medal.anchor_right = 0.0
	medal.anchor_top = 0.0
	medal.anchor_bottom = 0.0
	medal.offset_left = 314
	medal.offset_right = 464
	medal.offset_top = -42.0
	medal.offset_bottom = 108.0
	medal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	medal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	medal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	medal.z_index = 21
	tile_motion_root.add_child(medal)

	var mastery_progress = host._progress(Color("#f4bf35"), 56)
	mastery_progress.border_color = host.COLOR_INK
	host._apply_mastery_progress_bar_theme(mastery_progress, host._skill_theme_color(skill_id))
	mastery_progress.easing_speed = 24.0
	mastery_progress.custom_minimum_size = Vector2(host.FISHING_LOCATION_TILE_SIZE.x, 56.0)
	mastery_progress.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mastery_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mastery_progress.z_index = 24
	method_column.add_child(mastery_progress)
	var lock_root: Control = null
	if not unlocked or unlock_ready_pending:
		lock_root = _attach_fishing_method_padlock(
			art_panel, skill_id, action_id, int(location.get("unlock", action.get("unlock", 1)))
		)

	var method_button = Button.new()
	method_button.text = ""
	method_button.focus_mode = Control.FOCUS_NONE
	method_button.flat = true
	method_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	method_button.set_anchors_preset(Control.PRESET_FULL_RECT)
	method_button.add_theme_stylebox_override("normal", host.empty_style_cache)
	method_button.add_theme_stylebox_override("hover", host.empty_style_cache)
	method_button.add_theme_stylebox_override("pressed", host.empty_style_cache)
	method_button.add_theme_stylebox_override("disabled", host.empty_style_cache)
	method_button.add_theme_stylebox_override("focus", host.empty_style_cache)
	method_button.z_index = host.MODULE_ACTION_ZONE_Z_INDEX + 1
	method_button.z_as_relative = false
	method_button.set_meta("action_button_skill_id", skill_id)
	method_button.set_meta("action_button_action_id", action_id)
	method_button.add_to_group("fishing_method_buttons")
	art_panel.add_child(method_button)

	var method_card = {
		"is_fishing_method": true,
		"is_fishing_location": true,
		"fishing_area_key": area_key,
		"skill_id": skill_id,
		"action": action,
		"action_id": action_id,
		"mastery_action_id": host._fishing_location_mastery_action_id(area_id, location_id),
		"area_id": area_id,
		"location_id": location_id,
		"art_panel": art_panel,
		"wiggle_root": tile_motion_root,
		"art": location_art,
		"active_rest_position": Vector2.ZERO,
		"active_sway_offset": Vector2.ZERO,
		"active_sway_rotation": 0.0,
		"active_sway_scale_pulse": 0.0,
		"active_camera_zoom": host.FISHING_LOCATION_ACTIVE_CAMERA_ZOOM,
		"active_camera_pan": host.FISHING_LOCATION_ACTIVE_CAMERA_PAN,
		"medal": medal,
		"attempt_bar": null,
		"host.mastery": mastery_progress,
		"mastery_bar_instant_updates": true,
		"method_button": method_button,
		"method_hit_control": method_column,
		"method_image_hit_control": art_panel,
		"lock_root": lock_root,
		"status": null,
		"medal_destination": Vector2(medal.offset_left, medal.offset_top),
		"last_mastery_level": -1,
		"method_active_sway_phase": randf() * TAU,
		"fixed_layout": true,
		"unlock_ceremony_pending": false,
		"unlock_ready_pending": unlock_ready_pending,
	}
	method_button.set_meta("fishing_method_card", method_card)
	return method_card


func _sync_fishing_active_tool_hit(area_card: Dictionary) -> void:
	var layer := area_card.get("active_tool_layer") as Control
	var art := area_card.get("active_tool_art") as TextureRect
	var hit := area_card.get("active_tool_hit") as Button
	if layer == null or art == null or hit == null or not is_instance_valid(layer) or not is_instance_valid(art) or not is_instance_valid(hit):
		return
	host._set_canvas_item_visible_if_changed(hit, layer.visible)
	hit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hit_padding := Vector2(34.0, 34.0)
	hit.position = art.position - hit_padding
	hit.size = art.size + hit_padding * 2.0
	hit.custom_minimum_size = hit.size
	hit.pivot_offset = art.pivot_offset
	hit.rotation = 0.0
	hit.scale = Vector2.ONE


func _update_fishing_active_tool_animation(area_card: Dictionary, running: bool, delta: float, instant: bool) -> void:
	var layer = area_card.get("active_tool_layer") as Control
	var art = area_card.get("active_tool_art") as TextureRect
	if layer == null or art == null or not is_instance_valid(layer) or not is_instance_valid(art):
		return
	var active_here = running and _fishing_area_card_owns_action(area_card, host.running_action_id)
	host._set_canvas_item_visible_if_changed(layer, active_here)
	if not active_here:
		art.position = Vector2(host._fishing_active_tool_base_x(host.FISHING_ACTIVE_TOOL_ICON_SIZE.x), host.FISHING_ACTIVE_TOOL_FLOAT_Y)
		art.rotation = 0.0
		art.scale = Vector2.ONE
		_sync_fishing_active_tool_hit(area_card)
		return
	var current_tool_id = host.equipped_fishing_tool_id
	if str(area_card.get("active_tool_id", "")) != current_tool_id:
		area_card["active_tool_id"] = current_tool_id
		area_card["active_tool_init_token"] = host.fishing_active_tool_init_token
		art.texture = host._fishing_tool_icon_texture(current_tool_id)
		var icon_size = host.FISHING_ACTIVE_NET_ICON_SIZE if current_tool_id in ["net", "mirror"] else host.FISHING_ACTIVE_TOOL_ICON_SIZE
		art.custom_minimum_size = icon_size
		art.size = icon_size
		if current_tool_id in ["net", "mirror"]:
			art.pivot_offset = Vector2(icon_size.x * 0.20, icon_size.y * 0.78)
		elif FishingState.is_rod(current_tool_id):
			art.pivot_offset = Vector2(icon_size.x * 0.30, icon_size.y * 0.68)
		else:
			art.pivot_offset = icon_size * 0.5
		if host._fishing_tool_uses_initial_drop(current_tool_id):
			area_card["active_tool_init_seconds"] = host.FISHING_ACTIVE_TOOL_INIT_SECONDS
			art.position = Vector2(host._fishing_active_tool_base_x(icon_size.x), host.FISHING_ACTIVE_TOOL_FLOAT_Y - 88.0)
		else:
			area_card["active_tool_init_seconds"] = 0.0
			art.position = Vector2(host._fishing_active_tool_base_x(icon_size.x), host.FISHING_ACTIVE_TOOL_FLOAT_Y)
		art.rotation = 0.0
		art.scale = Vector2.ONE
	elif int(area_card.get("active_tool_init_token", -1)) != host.fishing_active_tool_init_token:
		area_card["active_tool_init_token"] = host.fishing_active_tool_init_token
		var icon_size = host.FISHING_ACTIVE_NET_ICON_SIZE if current_tool_id in ["net", "mirror"] else host.FISHING_ACTIVE_TOOL_ICON_SIZE
		if host._fishing_tool_uses_initial_drop(current_tool_id):
			area_card["active_tool_init_seconds"] = host.FISHING_ACTIVE_TOOL_INIT_SECONDS
			art.position = Vector2(host._fishing_active_tool_base_x(icon_size.x), host.FISHING_ACTIVE_TOOL_FLOAT_Y - 88.0)
		else:
			area_card["active_tool_init_seconds"] = 0.0
			art.position = Vector2(host._fishing_active_tool_base_x(icon_size.x), host.FISHING_ACTIVE_TOOL_FLOAT_Y)
		art.rotation = 0.0
		art.scale = Vector2.ONE
	var progress = clampf(host.action_progress, 0.0, 1.0)
	var init_seconds = float(area_card.get("active_tool_init_seconds", 0.0))
	if init_seconds > 0.0:
		init_seconds = maxf(0.0, init_seconds - delta)
		area_card["active_tool_init_seconds"] = init_seconds
		var init_progress = 1.0 - clampf(init_seconds / host.FISHING_ACTIVE_TOOL_INIT_SECONDS, 0.0, 1.0)
		_update_fishing_active_tool_initialization(area_card, art, current_tool_id, init_progress, delta, instant)
		_sync_fishing_active_tool_hit(area_card)
		return
	if current_tool_id == "net":
		_update_fishing_net_tool_animation(area_card, art, progress, delta, instant)
		_sync_fishing_active_tool_hit(area_card)
		return
	if current_tool_id == "mirror":
		_update_fishing_reflect_net_tool_animation(area_card, art, progress, delta, instant)
		_sync_fishing_active_tool_hit(area_card)
		return
	if current_tool_id == "boat":
		_update_fishing_boat_tool_animation(area_card, art, progress, delta, instant)
		_sync_fishing_active_tool_hit(area_card)
		return
	if FishingState.is_rod(current_tool_id):
		_update_fishing_rod_tool_animation(area_card, art, progress, delta, instant)
		_sync_fishing_active_tool_hit(area_card)
		return
	var y = host.FISHING_ACTIVE_TOOL_FLOAT_Y
	if progress < 0.32:
		y += sin(progress / 0.45 * PI * 2.0) * 6.0
	elif progress < 0.88:
		var dip_t = 1.0 - pow(1.0 - clampf((progress - 0.32) / 0.16, 0.0, 1.0), 3.0)
		y = lerpf(host.FISHING_ACTIVE_TOOL_FLOAT_Y, host.FISHING_ACTIVE_TOOL_DIP_Y, dip_t)
	else:
		var rise_t = 1.0 - pow(1.0 - clampf((progress - 0.88) / 0.12, 0.0, 1.0), 2.2)
		y = lerpf(host.FISHING_ACTIVE_TOOL_DIP_Y, host.FISHING_ACTIVE_TOOL_HARVEST_Y, rise_t)
	var x = host._fishing_active_tool_base_x(host.FISHING_ACTIVE_TOOL_ICON_SIZE.x) + sin(progress * TAU * 1.4) * 5.0
	var target_position = Vector2(x, y)
	var target_rotation = sin(progress * TAU * 1.1) * 0.045
	if FishingState.is_rod(current_tool_id):
		var cast_t = 1.0 - pow(1.0 - clampf((progress - 0.24) / 0.36, 0.0, 1.0), 2.0)
		var lift_t = clampf((progress - 0.82) / 0.18, 0.0, 1.0)
		var hook_tilt = sin(cast_t * PI * 0.5) * (1.0 - lift_t)
		target_rotation += lerpf(0.10, 0.28, hook_tilt)
	var target_scale = Vector2.ONE * (1.0 + sin(progress * TAU * 2.0) * 0.025)
	if instant:
		art.position = target_position
		art.rotation = target_rotation
		art.scale = target_scale
		return
	var blend = clampf(delta * 18.0, 0.0, 1.0)
	art.position = art.position.lerp(target_position, blend)
	art.rotation = lerpf(art.rotation, target_rotation, blend)
	art.scale = art.scale.lerp(target_scale, blend)
	_sync_fishing_active_tool_hit(area_card)


func _build_fishing_active_tool_layer() -> Dictionary:
	var layer := Control.new()
	layer.anchor_left = 1.0
	layer.anchor_right = 1.0
	layer.anchor_top = 0.0
	layer.anchor_bottom = 0.0
	layer.offset_left = host.FISHING_ACTIVE_TOOL_LAYER_RIGHT_OFFSET - host.FISHING_ACTIVE_TOOL_LAYER_SIZE.x
	layer.offset_right = host.FISHING_ACTIVE_TOOL_LAYER_RIGHT_OFFSET
	layer.offset_top = host.FISHING_ACTIVE_TOOL_LAYER_TOP
	layer.offset_bottom = host.FISHING_ACTIVE_TOOL_LAYER_TOP + host.FISHING_ACTIVE_TOOL_LAYER_SIZE.y
	layer.clip_contents = true
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.visible = false
	layer.z_index = host.FISHING_ACTIVE_TOOL_Z_INDEX

	var art := TextureRect.new()
	art.texture = host._fishing_tool_icon_texture(host.equipped_fishing_tool_id)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.custom_minimum_size = host.FISHING_ACTIVE_TOOL_ICON_SIZE
	art.size = host.FISHING_ACTIVE_TOOL_ICON_SIZE
	art.position = Vector2(host._fishing_active_tool_base_x(host.FISHING_ACTIVE_TOOL_ICON_SIZE.x), host.FISHING_ACTIVE_TOOL_FLOAT_Y)
	art.pivot_offset = host.FISHING_ACTIVE_TOOL_ICON_SIZE * 0.5
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(art)

	var hit_button := Button.new()
	hit_button.text = ""
	hit_button.flat = true
	hit_button.focus_mode = Control.FOCUS_NONE
	hit_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hit_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	hit_button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	hit_button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	hit_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	hit_button.pressed.connect(host._on_fishing_active_tool_pressed.bind(hit_button))
	layer.add_child(hit_button)

	return {
		"layer": layer,
		"art": art,
		"hit": hit_button,
		"tool_id": host.equipped_fishing_tool_id,
	}


func _update_fishing_net_tool_animation(area_card: Dictionary, art: TextureRect, progress: float, delta: float, instant: bool) -> void:
	var center_x = host._fishing_active_tool_base_x(host.FISHING_ACTIVE_NET_ICON_SIZE.x)
	var ready_position := Vector2(center_x - 34.0, host.FISHING_ACTIVE_TOOL_FLOAT_Y - 18.0)
	var scoop_position := Vector2(center_x + 34.0, host.FISHING_ACTIVE_TOOL_DIP_Y - 2.0)
	var harvest_position := Vector2(center_x + 14.0, host.FISHING_ACTIVE_TOOL_HARVEST_Y - 134.0)
	var target_position = ready_position
	var target_rotation = 0.38
	var target_scale := Vector2.ONE
	if host.fishing_net_haul_visual_seconds > 0.0:
		var haul_progress := 1.0 - clampf(host.fishing_net_haul_visual_seconds / host.FISHING_NET_HAUL_VISUAL_SECONDS, 0.0, 1.0)
		var lift_t = host._fishing_active_tool_ease(clampf(haul_progress / 0.42, 0.0, 1.0))
		var hold_t := clampf((haul_progress - 0.42) / 0.24, 0.0, 1.0)
		var lower_t = host._fishing_active_tool_ease(clampf((haul_progress - 0.66) / 0.34, 0.0, 1.0))
		target_position = scoop_position.lerp(harvest_position, lift_t)
		target_position.y -= sin(lift_t * PI) * 30.0
		target_rotation = lerpf(1.18, 0.16, lift_t)
		target_scale = Vector2.ONE * lerpf(1.04, 1.20, lift_t)
		if hold_t > 0.0:
			target_position = harvest_position
			target_rotation = 0.16
			target_scale = Vector2.ONE * 1.20
		if lower_t > 0.0:
			target_position = harvest_position.lerp(scoop_position, lower_t)
			target_rotation = lerpf(0.16, 1.14, lower_t)
			target_scale = Vector2.ONE * lerpf(1.20, 1.04, lower_t)
		host.fishing_net_haul_visual_seconds = maxf(0.0, host.fishing_net_haul_visual_seconds - delta)
	elif progress < 0.24 and host.fishing_net_stored_fish <= 0 and host.fishing_net_successes <= 0:
		if host.fishing_net_set_in_water:
			var water_phase := float(area_card.get("net_water_phase", 0.0)) + delta * 1.55
			area_card["net_water_phase"] = water_phase
			var sway_t := sin(water_phase)
			target_position = scoop_position + Vector2(sway_t * 7.0, sin(water_phase * 0.52) * 2.0)
			target_rotation = 1.14 + sway_t * 0.08
			target_scale = Vector2.ONE * 1.04
		else:
			var reach_t := 1.0 - pow(1.0 - clampf(progress / 0.24, 0.0, 1.0), 2.4)
			target_position = ready_position.lerp(scoop_position, reach_t)
			target_position.y -= sin(reach_t * PI) * 12.0
			target_rotation = lerpf(0.38, 1.14, reach_t)
			target_scale = Vector2.ONE * lerpf(0.96, 1.04, reach_t)
	else:
		var fill_progress := clampf((progress - 0.24) / 0.76, 0.0, 1.0)
		var water_phase := float(area_card.get("net_water_phase", 0.0)) + delta * 1.55
		area_card["net_water_phase"] = water_phase
		var scoop := sin(water_phase)
		target_position = scoop_position + Vector2(scoop * 8.0, sin(water_phase * 0.52) * 2.0)
		target_rotation = 1.14 + scoop * 0.09
		target_scale = Vector2.ONE * (1.04 + fill_progress * 0.04)
	area_card["active_tool_underwater"] = host.fishing_net_haul_visual_seconds <= 0.0 and (progress >= 0.12 or host.fishing_net_set_in_water or host.fishing_net_stored_fish > 0 or host.fishing_net_successes > 0)
	if instant:
		art.position = target_position
		art.rotation = target_rotation
		art.scale = target_scale
		return
	var blend := clampf(delta * 10.0, 0.0, 1.0)
	art.position = art.position.lerp(target_position, blend)
	art.rotation = lerpf(art.rotation, target_rotation, blend)
	art.scale = art.scale.lerp(target_scale, blend)


func _update_fishing_reflect_net_tool_animation(area_card: Dictionary, art: TextureRect, progress: float, delta: float, instant: bool) -> void:
	var center_x = host._fishing_active_tool_base_x(host.FISHING_ACTIVE_NET_ICON_SIZE.x)
	var float_position := Vector2(center_x - 6.0, host.FISHING_ACTIVE_TOOL_FLOAT_Y - 18.0)
	var reach_position := Vector2(center_x + 6.0, host.FISHING_ACTIVE_TOOL_DIP_Y - 4.0)
	var lift_position := Vector2(center_x - 18.0, host.FISHING_ACTIVE_TOOL_HARVEST_Y - 12.0)
	var target_position = float_position
	var target_rotation = 0.72
	var target_scale := Vector2.ONE * 1.06
	if progress < 0.34:
		var reach_t := 1.0 - pow(1.0 - clampf(progress / 0.34, 0.0, 1.0), 2.6)
		target_position = float_position.lerp(reach_position, reach_t)
		target_position.y -= sin(reach_t * PI) * 10.0
		target_rotation = lerpf(0.72, 1.52, reach_t)
		target_scale = Vector2.ONE * lerpf(1.02, 1.10, reach_t)
	elif progress < 0.72:
		var scoop_t := clampf((progress - 0.34) / 0.38, 0.0, 1.0)
		var scoop_swing := sin(scoop_t * PI)
		target_position = reach_position + Vector2(scoop_swing * 28.0, scoop_swing * 10.0)
		target_rotation = 1.52 - scoop_swing * 0.54
		target_scale = Vector2.ONE * 1.10
	else:
		var lift_t = 1.0 - pow(1.0 - clampf((progress - 0.72) / 0.28, 0.0, 1.0), 2.0)
		target_position = reach_position.lerp(lift_position, lift_t)
		target_position.y -= sin(lift_t * PI) * 22.0
		target_rotation = lerpf(1.18, 0.70, lift_t)
		target_scale = Vector2.ONE * lerpf(1.10, 1.04, lift_t)
	area_card["active_tool_underwater"] = progress >= 0.20 and progress < 0.86
	if instant:
		art.position = target_position
		art.rotation = target_rotation
		art.scale = target_scale
		return
	var blend := clampf(delta * 16.0, 0.0, 1.0)
	art.position = art.position.lerp(target_position, blend)
	art.rotation = lerpf(art.rotation, target_rotation, blend)
	art.scale = art.scale.lerp(target_scale, blend)


func _update_fishing_boat_tool_animation(area_card: Dictionary, art: TextureRect, progress: float, delta: float, instant: bool) -> void:
	var center_x = host._fishing_active_tool_base_x(host.FISHING_ACTIVE_TOOL_ICON_SIZE.x) - 72.0
	var start_position := Vector2(center_x + 6.0, host.FISHING_ACTIVE_TOOL_FLOAT_Y - 42.0)
	var water_position := Vector2(center_x + 4.0, host.FISHING_ACTIVE_TOOL_DIP_Y - 28.0)
	var target_position = water_position
	var float_rotation := 0.02
	var target_rotation = float_rotation
	var target_scale := Vector2.ONE * 1.54
	if host.fishing_boat_haul_visual_seconds > 0.0:
		var haul_t := 1.0 - clampf(host.fishing_boat_haul_visual_seconds / host.FISHING_BOAT_HAUL_VISUAL_SECONDS, 0.0, 1.0)
		haul_t = host._fishing_active_tool_ease(haul_t)
		target_position = water_position + Vector2(sin(haul_t * PI) * 7.0, -sin(haul_t * PI) * 16.0)
		target_rotation = float_rotation + sin(haul_t * PI * 2.0) * 0.035
		target_scale = Vector2.ONE * lerpf(1.58, 1.54, haul_t)
		host.fishing_boat_haul_visual_seconds = maxf(0.0, host.fishing_boat_haul_visual_seconds - delta)
	elif not host.fishing_boat_set_in_water and progress < 0.18:
		var plop_t := 1.0 - pow(1.0 - clampf(progress / 0.18, 0.0, 1.0), 2.2)
		target_position = start_position.lerp(water_position, plop_t)
		target_position.y -= sin(plop_t * PI) * 16.0
		target_rotation = lerpf(float_rotation - 0.03, float_rotation, plop_t)
		target_scale = Vector2.ONE * lerpf(1.36, 1.54, plop_t)
	else:
		host.fishing_boat_set_in_water = true
		var bob_t := progress * TAU
		target_position = water_position + Vector2(sin(bob_t * 0.7) * 3.0, sin(bob_t) * 5.0)
		target_rotation = float_rotation + sin(bob_t * 0.74) * 0.018
		var load_sag := clampf(float(host.fishing_boat_stored_fish) / float(host.FISHING_BOAT_HAUL_THRESHOLD), 0.0, 1.0) * 5.0
		target_position.y += load_sag
		target_scale = Vector2.ONE * (1.54 + sin(bob_t * 0.5) * 0.018 + load_sag * 0.002)
	area_card["active_tool_underwater"] = true
	if instant:
		art.position = target_position
		art.rotation = target_rotation
		art.scale = target_scale
		return
	var blend := clampf(delta * 14.0, 0.0, 1.0)
	art.position = art.position.lerp(target_position, blend)
	art.rotation = lerpf(art.rotation, target_rotation, blend)
	art.scale = art.scale.lerp(target_scale, blend)


func _update_fishing_rod_tool_animation(area_card: Dictionary, art: TextureRect, progress: float, delta: float, instant: bool) -> void:
	var base_x = host._fishing_active_tool_base_x(host.FISHING_ACTIVE_TOOL_ICON_SIZE.x)
	var float_position := Vector2(base_x, host.FISHING_ACTIVE_TOOL_FLOAT_Y)
	var dip_position := Vector2(base_x + 3.0, host.FISHING_ACTIVE_TOOL_DIP_Y - 8.0)
	var lift_position := Vector2(base_x - 10.0, host.FISHING_ACTIVE_TOOL_HARVEST_Y - 128.0)
	var target_position = dip_position
	var target_rotation = 0.42
	var target_scale := Vector2.ONE
	if host.fishing_rod_haul_visual_seconds > 0.0:
		var haul_t := 1.0 - clampf(host.fishing_rod_haul_visual_seconds / host.FISHING_ROD_HAUL_VISUAL_SECONDS, 0.0, 1.0)
		haul_t = host._fishing_active_tool_ease(haul_t)
		target_position = dip_position.lerp(lift_position, haul_t)
		target_position.y -= sin(haul_t * PI) * 26.0
		target_rotation = lerpf(0.44, -0.18, haul_t)
		target_scale = Vector2.ONE * lerpf(1.02, 1.0, haul_t)
		host.fishing_rod_haul_visual_seconds = maxf(0.0, host.fishing_rod_haul_visual_seconds - delta)
		if host.fishing_rod_haul_visual_seconds <= 0.0:
			host.fishing_rod_set_in_water = false
	elif not host.fishing_rod_set_in_water and progress < 0.34:
		var cast_t := 1.0 - pow(1.0 - clampf(progress / 0.34, 0.0, 1.0), 2.2)
		target_position = float_position.lerp(dip_position, cast_t)
		target_position.y -= sin(cast_t * PI) * 6.0
		target_rotation = lerpf(0.04, 0.42, cast_t)
		target_scale = Vector2.ONE * (1.0 + sin(cast_t * PI) * 0.02)
	else:
		host.fishing_rod_set_in_water = true
		var hold_t := progress * TAU
		target_position = dip_position + Vector2(sin(hold_t * 0.55) * 2.0, sin(hold_t * 0.8) * 1.5)
		target_rotation = 0.42 + sin(hold_t * 0.7) * 0.012
		target_scale = Vector2.ONE
	area_card["active_tool_underwater"] = host.fishing_rod_set_in_water and host.fishing_rod_haul_visual_seconds <= 0.0
	if instant:
		art.position = target_position
		art.rotation = target_rotation
		art.scale = target_scale
		return
	var blend := clampf(delta * 16.0, 0.0, 1.0)
	art.position = art.position.lerp(target_position, blend)
	art.rotation = lerpf(art.rotation, target_rotation, blend)
	art.scale = art.scale.lerp(target_scale, blend)


func _update_fishing_active_tool_initialization(area_card: Dictionary, art: TextureRect, tool_id: String, init_progress: float, delta: float, instant: bool) -> void:
	var icon_size = host.FISHING_ACTIVE_NET_ICON_SIZE if tool_id in ["net", "mirror"] else host.FISHING_ACTIVE_TOOL_ICON_SIZE
	var base_x = host._fishing_active_tool_base_x(icon_size.x)
	var high_position := Vector2(base_x, host.FISHING_ACTIVE_TOOL_FLOAT_Y - 88.0)
	var water_position := Vector2(base_x, host.FISHING_ACTIVE_TOOL_DIP_Y - 8.0)
	var high_rotation := 0.0
	var water_rotation := 0.0
	var high_scale := Vector2.ONE
	var water_scale := Vector2.ONE
	match tool_id:
		"net":
			high_position = Vector2(base_x - 34.0, host.FISHING_ACTIVE_TOOL_FLOAT_Y - 96.0)
			water_position = Vector2(base_x + 34.0, host.FISHING_ACTIVE_TOOL_DIP_Y - 2.0)
			high_rotation = 0.30
			water_rotation = 1.14
			high_scale = Vector2.ONE * 0.98
			water_scale = Vector2.ONE * 1.04
		"mirror":
			high_position = Vector2(base_x - 8.0, host.FISHING_ACTIVE_TOOL_FLOAT_Y - 96.0)
			water_position = Vector2(base_x + 6.0, host.FISHING_ACTIVE_TOOL_DIP_Y - 4.0)
			high_rotation = 0.58
			water_rotation = 1.52
			high_scale = Vector2.ONE * 1.02
			water_scale = Vector2.ONE * 1.10
		"boat":
			base_x = host._fishing_active_tool_base_x(host.FISHING_ACTIVE_TOOL_ICON_SIZE.x) - 72.0
			high_position = Vector2(base_x + 6.0, host.FISHING_ACTIVE_TOOL_FLOAT_Y - 82.0)
			water_position = Vector2(base_x + 4.0, host.FISHING_ACTIVE_TOOL_DIP_Y - 28.0)
			high_rotation = -0.04
			water_rotation = 0.02
			high_scale = Vector2.ONE * 1.40
			water_scale = Vector2.ONE * 1.54
		_:
			if FishingState.is_rod(tool_id):
				high_position = Vector2(base_x - 8.0, host.FISHING_ACTIVE_TOOL_FLOAT_Y - 88.0)
				water_position = Vector2(base_x + 3.0, host.FISHING_ACTIVE_TOOL_DIP_Y - 8.0)
				high_rotation = -0.10
				water_rotation = 0.42
			else:
				high_position = Vector2(base_x, host.FISHING_ACTIVE_TOOL_FLOAT_Y - 72.0)
				water_position = Vector2(base_x + 2.0, host.FISHING_ACTIVE_TOOL_DIP_Y - 4.0)
				high_rotation = -0.04
				water_rotation = 0.04
	var t = host._fishing_active_tool_ease(init_progress)
	var target_position = high_position.lerp(water_position, t)
	target_position.y -= sin(t * PI) * 18.0
	var target_rotation = lerpf(high_rotation, water_rotation, t)
	var target_scale := high_scale.lerp(water_scale, t)
	if init_progress >= 1.0:
		match tool_id:
			"net":
				host.fishing_net_set_in_water = true
			"boat":
				host.fishing_boat_set_in_water = true
			_:
				if FishingState.is_rod(tool_id):
					host.fishing_rod_set_in_water = true
	area_card["active_tool_underwater"] = init_progress >= 0.72
	if instant:
		art.position = target_position
		art.rotation = target_rotation
		art.scale = target_scale
		return
	var blend := clampf(delta * 18.0, 0.0, 1.0)
	art.position = art.position.lerp(target_position, blend)
	art.rotation = lerpf(art.rotation, target_rotation, blend)
	art.scale = art.scale.lerp(target_scale, blend)


func _build_fishing_area_action_method_tile(skill_id: String, area_key: String, area_bg_path: String, action_id: String, action: Dictionary, method_row: HBoxContainer, status: Label) -> Dictionary:
	var unlocked = host._is_action_unlocked(skill_id, action)
	var unlock_ready_pending = host._action_has_pending_unlock_readiness(action_id)

	var method_column = VBoxContainer.new()
	method_column.add_theme_constant_override("separation", host.FISHING_MODULE_TITLE_TOP)
	method_column.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	method_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	method_row.add_child(method_column)

	var method_title = host._label(host._fishing_area_focused_method_label(action), 48, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	method_title.add_theme_color_override("font_outline_color", host.COLOR_INK)
	method_title.add_theme_constant_override("outline_size", host.FISHING_METHOD_TITLE_OUTLINE)
	method_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	method_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	method_title.custom_minimum_size.x = host.FISHING_LOCATION_TILE_SIZE.x
	method_title.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	method_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	method_column.add_child(method_title)

	var art_panel = Panel.new()
	art_panel.custom_minimum_size = host.FISHING_LOCATION_TILE_SIZE
	art_panel.size = host.FISHING_LOCATION_TILE_SIZE
	art_panel.set_meta("fishing_area_method_ready_marker", true)
	art_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	art_panel.clip_contents = false
	art_panel.add_theme_stylebox_override("panel", _fishing_location_tile_style(unlocked))
	art_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	method_column.add_child(art_panel)

	var tile_motion_root = Control.new()
	tile_motion_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	tile_motion_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile_motion_root.pivot_offset = host.FISHING_LOCATION_TILE_SIZE * 0.5
	art_panel.add_child(tile_motion_root)

	var tile_frame_clip = Control.new()
	tile_frame_clip.set_anchors_preset(Control.PRESET_FULL_RECT)
	tile_frame_clip.clip_contents = true
	tile_frame_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile_frame_clip.z_index = 1
	tile_motion_root.add_child(tile_frame_clip)

	var art_clip = Control.new()
	art_clip.set_anchors_preset(Control.PRESET_FULL_RECT)
	art_clip.clip_contents = true
	art_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_clip.z_index = 1
	tile_frame_clip.add_child(art_clip)

	var art = RoundedTextureRect.new()
	art.texture = host.visual_texture_cache._texture_or_visual_fallback(str(action.get("background", area_bg_path)))
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.radius = 30.0
	art.mask_inset = 10.0
	art.aspect_mode = 2
	art.fallback_color = Color("#224d45")
	art.modulate = Color.WHITE if unlocked else Color(0.72, 0.72, 0.72, 0.82)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.pivot_offset = host.FISHING_LOCATION_TILE_SIZE * 0.5
	art.z_index = 1
	art_clip.add_child(art)

	var location_border = Panel.new()
	location_border.set_anchors_preset(Control.PRESET_FULL_RECT)
	location_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	location_border.z_index = 20
	location_border.add_theme_stylebox_override("panel", _fishing_location_tile_style(unlocked))
	tile_frame_clip.add_child(location_border)

	var medal = TextureRect.new()
	medal.anchor_left = 0.0
	medal.anchor_right = 0.0
	medal.anchor_top = 0.0
	medal.anchor_bottom = 0.0
	medal.offset_left = 314
	medal.offset_right = 464
	medal.offset_top = -42.0
	medal.offset_bottom = 108.0
	medal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	medal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	medal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	medal.z_index = 21
	tile_motion_root.add_child(medal)

	var mastery_progress = host._progress(Color("#f4bf35"), 56)
	mastery_progress.border_color = host.COLOR_INK
	host._apply_mastery_progress_bar_theme(mastery_progress, host._skill_theme_color(skill_id))
	mastery_progress.easing_speed = 24.0
	mastery_progress.custom_minimum_size = Vector2(host.FISHING_LOCATION_TILE_SIZE.x, 56.0)
	mastery_progress.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mastery_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mastery_progress.z_index = 24
	method_column.add_child(mastery_progress)

	var lock_root: Control = null
	if not unlocked or unlock_ready_pending:
		lock_root = _attach_fishing_method_padlock(art_panel, skill_id, action_id, int(action.get("unlock", 1)))

	var method_button = Button.new()
	method_button.text = ""
	method_button.focus_mode = Control.FOCUS_NONE
	method_button.flat = true
	method_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	method_button.set_anchors_preset(Control.PRESET_FULL_RECT)
	method_button.add_theme_stylebox_override("normal", host.empty_style_cache)
	method_button.add_theme_stylebox_override("hover", host.empty_style_cache)
	method_button.add_theme_stylebox_override("pressed", host.empty_style_cache)
	method_button.add_theme_stylebox_override("disabled", host.empty_style_cache)
	method_button.add_theme_stylebox_override("focus", host.empty_style_cache)
	method_button.z_index = host.MODULE_ACTION_ZONE_Z_INDEX + 1
	method_button.z_as_relative = false
	method_button.set_meta("action_button_skill_id", skill_id)
	method_button.set_meta("action_button_action_id", action_id)
	method_button.add_to_group("fishing_method_buttons")
	art_panel.add_child(method_button)

	var method_card = {
		"is_fishing_method": true,
		"fishing_area_key": area_key,
		"skill_id": skill_id,
		"action": action,
		"action_id": action_id,
		"art_panel": art_panel,
		"wiggle_root": tile_motion_root,
		"art": art,
		"active_rest_position": Vector2.ZERO,
		"active_sway_offset": Vector2.ZERO,
		"active_sway_rotation": 0.0,
		"active_sway_scale_pulse": 0.0,
		"active_camera_zoom": host.FISHING_LOCATION_ACTIVE_CAMERA_ZOOM,
		"active_camera_pan": host.FISHING_LOCATION_ACTIVE_CAMERA_PAN,
		"medal": medal,
		"attempt_bar": null,
		"host.mastery": mastery_progress,
		"mastery_bar_instant_updates": true,
		"method_button": method_button,
		"method_hit_control": method_column,
		"method_image_hit_control": art_panel,
		"lock_root": lock_root,
		"status": status,
		"medal_destination": Vector2(medal.offset_left, medal.offset_top),
		"last_mastery_level": -1,
		"method_active_sway_phase": randf() * TAU,
		"fixed_layout": true,
		"unlock_ceremony_pending": false,
		"unlock_ready_pending": unlock_ready_pending,
	}
	method_button.set_meta("fishing_method_card", method_card)
	return method_card


func _attach_fishing_method_padlock(art_panel: Panel, skill_id: String, action_id: String, unlock_level: int) -> Control:
	var padlock_texture = host._cropped_unlock_padlock_texture()
	if padlock_texture == null:
		return null
	var padlock_size = host.FISHING_METHOD_PADLOCK_SIZE
	var lock_root = Control.new()
	lock_root.custom_minimum_size = padlock_size
	lock_root.mouse_filter = Control.MOUSE_FILTER_PASS
	lock_root.anchor_left = 0.5
	lock_root.anchor_right = 0.5
	lock_root.anchor_top = 0.5
	lock_root.anchor_bottom = 0.5
	lock_root.offset_left = -padlock_size.x * 0.5
	lock_root.offset_right = padlock_size.x * 0.5
	lock_root.offset_top = -padlock_size.y * 0.5 - 12.0
	lock_root.offset_bottom = padlock_size.y * 0.5 - 12.0
	lock_root.z_index = 900
	lock_root.z_as_relative = false
	art_panel.add_child(lock_root)

	var shake_body = Control.new()
	shake_body.custom_minimum_size = padlock_size
	shake_body.size = padlock_size
	shake_body.position = Vector2.ZERO
	shake_body.pivot_offset = padlock_size * 0.5
	shake_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lock_root.add_child(shake_body)

	var padlock_shadow = TextureRect.new()
	padlock_shadow.texture = padlock_texture
	padlock_shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	padlock_shadow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	padlock_shadow.size = padlock_size
	padlock_shadow.position = Vector2(0, 14)
	padlock_shadow.modulate = Color(0, 0, 0, 0.26)
	padlock_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padlock_shadow.z_index = 4
	shake_body.add_child(padlock_shadow)

	var padlock_visual = TextureRect.new()
	padlock_visual.texture = padlock_texture
	padlock_visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	padlock_visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	padlock_visual.size = padlock_size
	padlock_visual.modulate = Color.WHITE
	padlock_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padlock_visual.z_index = 5
	shake_body.add_child(padlock_visual)

	var tint_mask = host._unlock_padlock_tint_mask_texture()
	if tint_mask != null:
		var padlock_tint = TextureRect.new()
		padlock_tint.texture = tint_mask
		padlock_tint.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		padlock_tint.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		padlock_tint.size = padlock_size
		var padlock_tint_color: Color = host._skill_theme_color(skill_id)
		padlock_tint_color.a = 0.92
		padlock_tint.modulate = padlock_tint_color
		padlock_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		padlock_tint.z_index = 6
		shake_body.add_child(padlock_tint)

	var padlock_hit_area = Control.new()
	padlock_hit_area.custom_minimum_size = padlock_size
	padlock_hit_area.size = padlock_size
	padlock_hit_area.mouse_filter = Control.MOUSE_FILTER_STOP
	padlock_hit_area.z_index = 7
	padlock_hit_area.gui_input.connect(host._on_fishing_method_lock_hit_input.bind(skill_id, action_id, shake_body))
	shake_body.add_child(padlock_hit_area)
	lock_root.set_meta("padlock_button", padlock_hit_area)

	var level_label = ActivityLockNumber.new()
	level_label.set_text(str(unlock_level))
	level_label.font_size = host.FISHING_METHOD_PADLOCK_LEVEL_FONT
	level_label.outline_size = host.FISHING_METHOD_PADLOCK_LEVEL_OUTLINE
	level_label.size = host.FISHING_METHOD_PADLOCK_LEVEL_SIZE
	level_label.position = Vector2(
		padlock_size.x * 0.5 - host.FISHING_METHOD_PADLOCK_LEVEL_SIZE.x * 0.5 - 15.0,
		padlock_size.y * 0.52
	)
	level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_label.z_index = 7
	if host.app_bold_font != null:
		level_label.font = host.app_bold_font
	elif host.app_font != null:
		level_label.font = host.app_font
	shake_body.add_child(level_label)
	lock_root.set_meta("padlock_shake_body", shake_body)
	return lock_root


func _float_eaten_fish_icon(skill_id: String, target: Control) -> void:
	if target == null or not is_instance_valid(target) or not target.is_inside_tree():
		return
	var texture = host.visual_texture_cache._texture("res://assets/content/fishing/catch-icons/00-minnow-cutout.png")
	if texture == null:
		return
	var target_rect := target.get_global_rect()
	var canvas = _fishing_collection_canvas()
	var target_center := target_rect.get_center()
	var start := target_center + Vector2(randf_range(-18.0, 18.0), -target_rect.size.y * 0.28 - 34.0)
	var finish := start + Vector2(randf_range(-14.0, 14.0), -118.0)
	var control := start.lerp(finish, 0.46) + Vector2(randf_range(-20.0, 20.0), -38.0)
	var root := Control.new()
	root.size = Vector2(288, 228)
	root.custom_minimum_size = root.size
	root.position = start - root.size * 0.5
	root.pivot_offset = root.size * 0.5
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.z_index = host.MODAL_OVERLAY_Z
	root.z_as_relative = false
	root.scale = Vector2(0.52, 0.52)
	root.modulate = Color(1, 1, 1, 0)
	canvas.add_child(root)

	var minus_size := Vector2(96, 126)
	var minus_shadow = host._label("-", 116, Color("#171615"), HORIZONTAL_ALIGNMENT_CENTER)
	minus_shadow.size = minus_size
	minus_shadow.position = Vector2(19, 53)
	minus_shadow.modulate = Color(1, 1, 1, 0.46)
	minus_shadow.add_theme_constant_override("outline_size", 16)
	minus_shadow.add_theme_color_override("font_outline_color", Color(0.09, 0.08, 0.07, 0.75))
	root.add_child(minus_shadow)

	var minus = host._label("-", 116, Color("#fff0a8"), HORIZONTAL_ALIGNMENT_CENTER)
	minus.size = minus_size
	minus.position = Vector2(14, 48)
	minus.add_theme_constant_override("outline_size", 14)
	minus.add_theme_color_override("font_outline_color", host.COLOR_INK)
	root.add_child(minus)

	var icon_size = Vector2(214, 214)
	var icon = host.visual_texture_cache._image_from_texture(texture, icon_size)
	icon.size = icon_size
	icon.position = Vector2(72, 7)
	icon.pivot_offset = icon.size * 0.5
	icon.rotation = randf_range(-0.22, 0.22)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(icon)

	var root_id := root.get_instance_id()
	var spin := randf_range(-0.38, 0.38)
	var theme = host._skill_theme_color(skill_id)
	var tween = host.create_tween()
	tween.set_parallel(true)
	tween.tween_method(Callable(self, "_apply_fish_collection_fly_progress").bind(root_id, start, control, finish, spin), 0.0, 1.0, 0.48).set_trans(Tween.TRANS_LINEAR)
	tween.parallel().tween_property(icon, "modulate", Color(theme.r, theme.g, theme.b, 0.0), 0.18).set_delay(0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(icon, "rotation", icon.rotation + randf_range(-0.62, 0.62), 0.48).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(host._queue_free_instance_id.bind(root.get_instance_id()))


func _apply_fish_collection_fly_progress(progress: float, root_id: int, start: Vector2, control_point: Vector2, finish: Vector2, spin: float) -> void:
	var node: Control = host._valid_control_ref(instance_from_id(root_id))
	if node == null:
		return
	var eased := progress * progress * (3.0 - 2.0 * progress)
	var a := start.lerp(control_point, eased)
	var b := control_point.lerp(finish, eased)
	var point := a.lerp(b, eased)
	node.position = point - node.size * 0.5
	var pop_amount := sin(progress * PI)
	node.rotation = spin * progress
	var fade_in := minf(1.0, progress * 5.0)
	var fade_out := 1.0 - maxf(0.0, progress - 0.78) / 0.22
	node.modulate = Color(1.0, 1.0, 1.0, fade_in * fade_out)
	var scale_curve := 1.0 - pow(1.0 - pop_amount, 1.45)
	node.scale = Vector2.ONE * lerpf(0.52, 1.04, scale_curve)


func _float_fish_reward(parent: Control, anchor: Control, fish_amount: float) -> void:
	if fish_amount <= 0.0:
		return
	if parent == null or anchor == null or not is_instance_valid(parent) or not is_instance_valid(anchor) or parent.is_queued_for_deletion() or anchor.is_queued_for_deletion():
		return
	var texture = host.visual_texture_cache._texture("res://assets/content/fishing/catch-icons/00-minnow-cutout.png")
	if texture == null:
		host._reward_feedback_surface()._float_reward(parent, anchor, "+%s fish" % host._fish_currency_display_text(fish_amount), 58, Color("#8ff8ff"), Vector2(0, -44), Vector2(0, -188), 0.08, false, -1.0, host.SKILL_REWARD_FLOAT_GROUP)
		return
	var reward_size := Vector2(420, 128)
	var holder := Control.new()
	holder.z_index = host.REWARD_FLOAT_Z
	holder.z_as_relative = false
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.size = reward_size
	holder.add_to_group(host.SKILL_REWARD_FLOAT_GROUP)
	parent.add_child(holder)

	var icon_size = Vector2(94, 94)
	var icon_shadow = host.visual_texture_cache._image_from_texture(texture, icon_size)
	icon_shadow.size = icon_size
	icon_shadow.position = Vector2(78, 18)
	icon_shadow.modulate = Color(0.02, 0.02, 0.02, 0.34)
	icon_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(icon_shadow)

	var icon = host.visual_texture_cache._image_from_texture(texture, icon_size)
	icon.size = icon_size
	icon.position = Vector2(74, 14)
	icon.rotation = -0.10
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(icon)

	var text := "+%s" % host._fish_currency_display_text(fish_amount)
	var label_size := Vector2(250, 128)
	var shadow = host._label(text, 60, Color("#171615"), HORIZONTAL_ALIGNMENT_LEFT)
	shadow.size = label_size
	shadow.position = Vector2(178, 9)
	shadow.modulate = Color(1, 1, 1, 0.34)
	holder.add_child(shadow)
	var label = host._label(text, 60, Color("#8ff8ff"), HORIZONTAL_ALIGNMENT_LEFT)
	label.size = label_size
	label.position = Vector2(174, 5)
	label.add_theme_color_override("font_outline_color", host.COLOR_INK)
	label.add_theme_constant_override("outline_size", 10)
	holder.add_child(label)

	var local_pos := anchor.global_position - parent.global_position
	var desired_position := local_pos + Vector2(anchor.size.x * 0.5 - reward_size.x * 0.5, anchor.size.y * 0.18 - reward_size.y * 0.5) + Vector2(0, -44)
	holder.position = host._reward_feedback_surface()._clamp_reward_holder_position(parent, desired_position, reward_size)
	host._reward_feedback_surface()._start_reward_float_tween(holder, Vector2(0, -188), 0.08)


func _attach_fishing_area_module_title(pop_card: Control, title_text: String) -> Label:
	var area_title: Label = host._label(title_text, host.FISHING_MODULE_TITLE_FONT_SIZE, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	area_title.add_theme_color_override("font_outline_color", host.COLOR_INK)
	area_title.add_theme_constant_override("outline_size", host.FISHING_MODULE_TITLE_OUTLINE)
	area_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	area_title.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	area_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	area_title.anchor_left = 0.0
	area_title.anchor_right = 1.0
	area_title.anchor_top = 0.0
	area_title.anchor_bottom = 0.0
	area_title.offset_left = host.FISHING_MODULE_TITLE_LEFT_INSET
	area_title.offset_right = -host.FISHING_MODULE_TITLE_RIGHT_INSET
	area_title.offset_top = host.FISHING_MODULE_TITLE_TOP
	area_title.offset_bottom = host.FISHING_MODULE_TITLE_TOP + host.FISHING_MODULE_TITLE_BAND_HEIGHT
	area_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area_title.z_index = host.FISHING_MODULE_TITLE_Z_INDEX
	area_title.z_as_relative = true
	area_title.visible = true
	pop_card.add_child(area_title)
	return area_title


func _fishing_location_tile_style(available: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.draw_center = false
	style.border_color = Color.WHITE if available else Color("#d9cfbc")
	style.border_width_left = 10
	style.border_width_top = 10
	style.border_width_right = 10
	style.border_width_bottom = 10
	style.corner_radius_top_left = 30
	style.corner_radius_top_right = 30
	style.corner_radius_bottom_left = 30
	style.corner_radius_bottom_right = 30
	style.shadow_color = Color.TRANSPARENT
	style.shadow_size = 0
	style.shadow_offset = Vector2.ZERO
	return style


func _add_fishing_area_module_corner_crop(parent: Control) -> RoundedCornerCropOverlay:
	var corner_crop := RoundedCornerCropOverlay.new()
	corner_crop.radius = 66.0
	corner_crop.cover_color = host._theme_paper_color()
	corner_crop.set_anchors_preset(Control.PRESET_FULL_RECT)
	corner_crop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corner_crop.z_index = 151
	parent.add_child(corner_crop)
	return corner_crop


func _fishing_area_background_path(area_id: String, area_def: Dictionary) -> String:
	var area_bg_path := str(area_def.get("bg", ""))
	if area_id == "beach" and ResourceLoader.exists("res://assets/content/fishing/backgrounds/beach-rocky-zoom.png"):
		area_bg_path = "res://assets/content/fishing/backgrounds/beach-rocky-zoom.png"
	return area_bg_path


func _fishing_area_module_shell(skill_id: String, area_def: Dictionary, area_id: String, content_width: float) -> Dictionary:
	var card_root := Control.new()
	card_root.custom_minimum_size = Vector2(content_width, host.ACTION_CARD_HEIGHT)
	card_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_root.clip_contents = false
	card_root.mouse_filter = Control.MOUSE_FILTER_PASS

	var pop_card := Control.new()
	pop_card.anchor_left = 0.0
	pop_card.anchor_right = 1.0
	pop_card.anchor_top = 0.0
	pop_card.anchor_bottom = 1.0
	pop_card.offset_left = host.ACTION_CARD_POP_GUTTER
	pop_card.offset_right = -host.ACTION_CARD_POP_GUTTER
	pop_card.offset_top = 0.0
	pop_card.offset_bottom = 0.0
	pop_card.clip_contents = false
	pop_card.mouse_filter = Control.MOUSE_FILTER_PASS
	pop_card.z_index = 1
	card_root.add_child(pop_card)

	var area_bg_path := _fishing_area_background_path(area_id, area_def)
	var bg: Control
	if host.FISHING_DETAIL_USE_FLAT_ART or _fishing_ablation_enabled("no_rounded_art"):
		var flat_bg := TextureRect.new()
		flat_bg.texture = host.visual_texture_cache._texture_or_visual_fallback(area_bg_path)
		flat_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		flat_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg = flat_bg
	else:
		var rounded_bg := RoundedTextureRect.new()
		rounded_bg.texture = host.visual_texture_cache._texture_or_visual_fallback(area_bg_path)
		rounded_bg.radius = 66.0
		rounded_bg.art_height = host.ACTION_CARD_HEIGHT
		rounded_bg.feather_height = 0.0
		rounded_bg.fallback_color = host._skill_theme_color(skill_id).darkened(0.12)
		bg = rounded_bg
	bg.modulate = Color.WHITE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.z_index = 150
	pop_card.add_child(bg)
	_add_fishing_area_module_corner_crop(pop_card)
	return {"root": card_root, "pop": pop_card, "bg": bg, "area_bg_path": area_bg_path}


func _fishing_area_module_layout(pop_card: Control, skill_id: String) -> Dictionary:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 54)
	margin.add_theme_constant_override("margin_right", 54)
	margin.add_theme_constant_override("margin_top", host.FISHING_AREA_CONTENT_TOP_MARGIN)
	margin.add_theme_constant_override("margin_bottom", host.FISHING_AREA_WATER_BOTTOM_MARGIN)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.z_index = 200
	pop_card.add_child(margin)

	var layout_column := VBoxContainer.new()
	layout_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout_column.add_theme_constant_override("separation", 10)
	layout_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(layout_column)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 28)
	top_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout_column.add_child(top_row)

	var method_slot := MarginContainer.new()
	method_slot.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	method_slot.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	method_slot.add_theme_constant_override("margin_top", host.FISHING_AREA_METHOD_TOP_MARGIN)
	method_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(method_slot)

	var method_row := HBoxContainer.new()
	method_row.add_theme_constant_override("separation", 28)
	method_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	method_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	method_slot.add_child(method_row)

	var top_spacer := Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(top_spacer)

	var stat_slot := MarginContainer.new()
	stat_slot.size_flags_horizontal = Control.SIZE_SHRINK_END
	stat_slot.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	stat_slot.add_theme_constant_override("margin_top", host.FISHING_AREA_STAT_COLUMN_TOP_MARGIN)
	stat_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(stat_slot)

	var stat_column := VBoxContainer.new()
	stat_column.add_theme_constant_override("separation", 28)
	stat_column.size_flags_horizontal = Control.SIZE_SHRINK_END
	stat_column.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	stat_column.alignment = BoxContainer.ALIGNMENT_BEGIN
	stat_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stat_slot.add_child(stat_column)
	var skill_detail_surface = host._skill_detail_surface()
	var xp_side = skill_detail_surface._action_stat_label("")
	var xp_box = skill_detail_surface._action_stat_box(xp_side, false, skill_id, "", "xp")
	stat_column.add_child(xp_box)
	var yield_side = skill_detail_surface._action_stat_label("")
	var yield_box = skill_detail_surface._action_stat_box(yield_side, false, skill_id, "", "yield")
	stat_column.add_child(yield_box)
	stat_column.modulate.a = 0.0
	return {"method_slot": method_slot, "method_row": method_row, "stat_column": stat_column, "area_xp": xp_side, "area_yield": yield_side, "stat_boxes": {"xp": xp_box, "yield": yield_box}}


func _fishing_area_runtime_layers(pop_card: Control, area_def: Dictionary, selected_id: String) -> Dictionary:
	var active_tool := _build_fishing_active_tool_layer()
	var active_tool_layer := active_tool["layer"] as Control
	pop_card.add_child(active_tool_layer)

	var water_strip_host := Control.new()
	water_strip_host.anchor_left = 0.0
	water_strip_host.anchor_right = 1.0
	water_strip_host.anchor_top = 1.0
	water_strip_host.anchor_bottom = 1.0
	water_strip_host.offset_left = 0.0
	water_strip_host.offset_right = 0.0
	water_strip_host.offset_top = -host.FISHING_FLUID_STRIP_HEIGHT
	water_strip_host.offset_bottom = host.FISHING_FLUID_STRIP_BOTTOM_INSET
	water_strip_host.clip_contents = true
	water_strip_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	water_strip_host.visible = false
	water_strip_host.z_index = host.FISHING_FLUID_STRIP_Z_INDEX
	pop_card.add_child(water_strip_host)
	var fluid_strip: Control = host._attach_fishing_fluid_strip(water_strip_host, {"id": selected_id})
	if fluid_strip.has_method("set_fluid_kind"):
		fluid_strip.call("set_fluid_kind", str(area_def.get("fluid", "water")))

	var catch_burst := Control.new()
	catch_burst.set_anchors_preset(Control.PRESET_FULL_RECT)
	catch_burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	catch_burst.z_index = 640
	pop_card.add_child(catch_burst)

	var border: ActivityCardBorder = null
	if host.ACTION_CARD_FACE_BORDER_ENABLED:
		border = ActivityCardBorder.new()
		border.set_anchors_preset(Control.PRESET_FULL_RECT)
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		border.z_index = host.ACTION_CARD_FACE_BORDER_Z_INDEX
		pop_card.add_child(border)

	var status: Label = host._label("", host.MIN_MOBILE_BODY_FONT_SIZE, host.COLOR_RED, HORIZONTAL_ALIGNMENT_LEFT)
	status.visible = false
	return {
		"active_tool": active_tool,
		"active_tool_layer": active_tool_layer,
		"water_strip_host": water_strip_host,
		"fluid_strip": fluid_strip,
		"catch_burst": catch_burst,
		"border": border,
		"status": status,
	}


func _mount_fishing_area_method_cards(skill_id: String, area_id: String, area_key: String, area_def: Dictionary, area_bg_path: String, method_row: HBoxContainer, status: Label) -> Dictionary:
	var method_slots: Dictionary = {}
	var method_source_ids = area_def.get("methods", [])
	if host._fishing_area_uses_location_tiles(area_def):
		method_source_ids = []
		for raw_location in host._fishing_locations_for_area_module(area_def):
			var location := raw_location as Dictionary
			if not host._fishing_location_should_show(area_id, location):
				continue
			var location_card := _build_fishing_location_tile(skill_id, area_id, area_key, location, method_row)
			if location_card.is_empty():
				continue
			var location_hit_control := location_card.get("method_hit_control") as Control
			if location_hit_control != null and is_instance_valid(location_hit_control):
				location_hit_control.set_meta("fishing_area_method_ready_marker", true)
			var location_action_id := str(location_card.get("action_id", ""))
			var location_ui_key := "%s:location-%s-%s" % [skill_id, area_id, str(location.get("id", ""))]
			host._register_action_card(location_ui_key, location_card)
			method_slots[location_action_id] = location_card

	for method_id in method_source_ids:
		var action_id := str(method_id)
		if not host._fishing_method_should_show(skill_id, action_id):
			continue
		var action: Dictionary = host._action_data(skill_id, action_id)
		if action.is_empty():
			continue
		var method_card := _build_fishing_area_action_method_tile(skill_id, area_key, area_bg_path, action_id, action, method_row, status)
		host._register_action_card(host._action_key(skill_id, action_id), method_card)
		method_slots[action_id] = method_card
	return method_slots


func _fishing_area_queue_overlay_host(method_slots: Dictionary, selected_id: String) -> Control:
	var selected_method_card := method_slots.get(selected_id, {}) as Dictionary
	if selected_method_card.is_empty():
		return null
	var queue_overlay_host: Control = host._valid_control_ref(selected_method_card.get("method_image_hit_control", null))
	if queue_overlay_host == null:
		queue_overlay_host = host._valid_control_ref(selected_method_card.get("art_panel", null))
	return queue_overlay_host


func _fishing_area_card_owns_action(area_card: Dictionary, action_id: String) -> bool:
	if action_id.is_empty():
		return false
	for method_id in area_card.get("method_ids", []):
		if str(method_id) == action_id:
			return true
	return false


func _fishing_area_card_for_action(skill_id: String, action_id: String) -> Dictionary:
	for raw_card in host.action_cards.values():
		if typeof(raw_card) != TYPE_DICTIONARY:
			continue
		var card := raw_card as Dictionary
		if not card.get("is_fishing_area"):
			continue
		if str(card.get("skill_id", "")) != skill_id:
			continue
		if _fishing_area_card_owns_action(card, action_id):
			var action: Dictionary = host._action_data(skill_id, action_id)
			if (
				host.fishing_unlock_preview_fade_marker_ids.has(action_id)
				and not action.is_empty()
				and not host._is_action_unlocked(skill_id, action)
			):
				card["fade_in_pending"] = true
				card["unlock_next_preview_pending"] = true
			return card
	return {}


func _fishing_area_card_for_pop_instance_id(pop_instance_id: int) -> Dictionary:
	if pop_instance_id <= 0:
		return {}
	for raw_card in host.action_cards.values():
		if typeof(raw_card) != TYPE_DICTIONARY:
			continue
		var card := raw_card as Dictionary
		if not card.get("is_fishing_area"):
			continue
		var pop := card.get("pop") as Control
		if pop != null and is_instance_valid(pop) and pop.get_instance_id() == pop_instance_id:
			return card
	return {}


func _finish_fishing_area_module_card(area_card: Dictionary, method_slots: Dictionary, pop_card: Control, skill_id: String, area_def: Dictionary, selected_id: String) -> void:
	var area_title := _attach_fishing_area_module_title(pop_card, host.fishing_runtime.area_module_display_name(area_def))
	area_card["area_title"] = area_title
	area_card["module_action_zones"] = host._skill_detail_surface()._add_module_action_zones(pop_card, ModuleUiRuntime.fishing_area(host.fishing_runtime.area_module_key(skill_id, area_def)))
	for raw_method_card in method_slots.values():
		var method_card := raw_method_card as Dictionary
		if method_card.is_empty():
			continue
		var method_button := method_card.get("method_button", null) as Button
		if method_button != null and is_instance_valid(method_button):
			method_button.set_meta("fishing_method_owner_pop_instance_id", pop_card.get_instance_id())
		if host._is_action_unlocked(skill_id, method_card.get("action", {}) as Dictionary):
			host._activate_fishing_method_button(method_card, pop_card.get_instance_id())
	host._apply_fishing_area_selection(area_card, selected_id, true)
	host._set_fishing_area_stats_visible(area_card, false, 0.0, true)
	host._sync_fishing_area_stat_hit_buttons(area_card, false)


func _build_fishing_area_module(skill_id: String, area_def: Dictionary, content_width: float) -> Dictionary:
	var area_id := str(area_def.get("id", ""))
	var area_key = host.fishing_runtime.area_module_key(skill_id, area_def)
	var selected_id = host.fishing_runtime.area_default_method(host, skill_id, area_def, host.FISHING_LOCATION_DEFS, host.FISHING_TOOL_LOCATION_ACTIONS)
	if host._fishing_area_uses_location_tiles(area_def) and str(host.selected_fishing_locations.get(area_id, "")).is_empty():
		host.selected_fishing_locations[area_id] = host._fishing_selected_location_id(area_def)

	var shell = _fishing_area_module_shell(skill_id, area_def, area_id, content_width)
	var card_root := shell.get("root") as Control
	var pop_card := shell.get("pop") as Control
	var bg := shell.get("bg") as Control
	var area_bg_path := str(shell.get("area_bg_path", ""))
	var layout := _fishing_area_module_layout(pop_card, skill_id)
	var method_slot := layout.get("method_slot") as MarginContainer
	var method_row := layout.get("method_row") as HBoxContainer
	var stat_column := layout.get("stat_column") as VBoxContainer
	var xp_side := layout.get("area_xp") as Label
	var yield_side := layout.get("area_yield") as Label
	var stat_boxes := layout.get("stat_boxes") as Dictionary
	var runtime_layers = _fishing_area_runtime_layers(pop_card, area_def, selected_id)
	var active_tool := runtime_layers.get("active_tool") as Dictionary
	var method_slots = _mount_fishing_area_method_cards(skill_id, area_id, area_key, area_def, area_bg_path, method_row, runtime_layers.get("status") as Label)
	var stat_hit_buttons = host._fishing_area_stat_hit_buttons(pop_card, skill_id, area_key, method_slots.size())
	var queue_overlay_host = _fishing_area_queue_overlay_host(method_slots, selected_id)

	var area_card := {
		"is_fishing_area": true, "area_id": area_id, "area_key": area_key, "method_ids": method_slots.keys(), "skill_id": skill_id, "area_def": area_def, "area_bg_path": area_bg_path,
		"root": card_root, "pop": pop_card, "bg": bg, "border": runtime_layers.get("border"), "fluid_strip": runtime_layers.get("fluid_strip"), "water_strip_host": runtime_layers.get("water_strip_host"),
		"active_tool_layer": runtime_layers.get("active_tool_layer"), "active_tool_art": active_tool["art"], "active_tool_hit": active_tool["hit"], "active_tool_id": active_tool["tool_id"],
		"uses_static_background_only": true, "catch_burst": runtime_layers.get("catch_burst"), "area_xp": xp_side, "area_yield": yield_side, "area_warning": null, "area_warning_box": null,
		"stat_column": stat_column, "stat_boxes": stat_boxes, "stat_hit_buttons": stat_hit_buttons, "method_row": method_row, "method_slot": method_slot, "method_slots": method_slots,
		"queue_overlay_host": queue_overlay_host, "selected_action_id": selected_id, "status": runtime_layers.get("status"),
	}
	_finish_fishing_area_module_card(area_card, method_slots, pop_card, skill_id, area_def, selected_id)
	return {"root": card_root, "area_key": area_key, "area_card": area_card, "method_ids": method_slots.keys()}


func _reset_fishing_net_collect_flyer_visuals(art_id: int) -> void:
	var flyer = host._valid_control_ref(instance_from_id(art_id))
	if flyer != null:
		flyer.scale = Vector2.ONE
		flyer.modulate = Color.WHITE


func _fishing_catch_burst_visual_count(action_id: String, fish_count: int) -> int:
	if host.equipped_fishing_tool_id == "net":
		return clampi(fish_count, 1, 6)
	var archetype := FishingState.method_archetype(host, action_id)
	var max_visuals := FISHING_CATCH_POP_MAX_VISUALS
	match archetype:
		"commit":
			max_visuals = 4
		"risk":
			max_visuals = 6
		"chaos":
			max_visuals = 7
		"volume":
			max_visuals = FISHING_CATCH_POP_MAX_VISUALS
		_:
			max_visuals = 5
	return clampi(fish_count, 1, max_visuals)


func _fishing_catch_burst_stagger_seconds(action_id: String, _fish_count: int) -> float:
	if host.equipped_fishing_tool_id == "net":
		return 0.018
	match FishingState.method_archetype(host, action_id):
		"volume":
			return 0.065
		"chaos":
			return 0.075
		"commit":
			return 0.145
		"risk":
			return 0.125
		_:
			return FISHING_CATCH_POP_STAGGER_SECONDS


func _fishing_catch_burst_rise_pixels(action_id: String, _fish_count: int) -> float:
	if host.equipped_fishing_tool_id == "net":
		return 156.0
	match FishingState.method_archetype(host, action_id):
		"volume":
			return 136.0
		"commit", "risk":
			return 150.0
		_:
			return FISHING_CATCH_POP_RISE_PIXELS


func _play_fishing_catch_burst(area_card: Dictionary, action_id: String, fish_count: int) -> void:
	if fish_count <= 0:
		return
	var catch_burst := area_card.get("catch_burst") as Control
	var method_slots := area_card.get("method_slots", {}) as Dictionary
	var method_card := method_slots.get(action_id) as Dictionary
	if catch_burst == null or method_card == null:
		return
	var art_panel := method_card.get("art_panel") as Control
	if art_panel == null or not is_instance_valid(art_panel):
		return
	var action := method_card.get("action") as Dictionary
	if action.is_empty():
		return
	host._clear_fishing_catch_burst(catch_burst)
	var catch_path = FishingState.catch_texture_path(action)
	var texture = host.visual_texture_cache._texture(catch_path)
	if texture == null:
		return
	var button := method_card.get("method_button") as Control
	var anchor_rect := button.get_global_rect() if button != null and is_instance_valid(button) else art_panel.get_global_rect()
	var burst_origin := catch_burst.get_global_transform().affine_inverse() * Vector2(anchor_rect.position.x + anchor_rect.size.x * 0.5, anchor_rect.position.y + anchor_rect.size.y * 0.28)
	var visual_count = _fishing_catch_burst_visual_count(action_id, fish_count)
	var stagger_seconds = _fishing_catch_burst_stagger_seconds(action_id, fish_count)
	var rise_pixels = _fishing_catch_burst_rise_pixels(action_id, fish_count)
	for i in range(visual_count):
		var pop = host.visual_texture_cache._image_from_texture(texture, FISHING_CATCH_POP_SIZE, catch_path)
		pop.size = FISHING_CATCH_POP_SIZE
		pop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pop.position = burst_origin + Vector2(randf_range(-8.0, 8.0), randf_range(-6.0, 6.0)) - pop.size * 0.5
		pop.rotation = randf_range(-0.16, 0.16)
		pop.scale = Vector2(0.35, 0.35)
		pop.pivot_offset = pop.size * 0.5
		pop.modulate = Color("#6240b8", 0.0) if host.equipped_fishing_tool_id == "mirror" else Color(1, 1, 1, 0)
		pop.z_index = i
		catch_burst.add_child(pop)
		var delay = float(i) * stagger_seconds
		var fly_direction := Vector2(randf_range(-0.58, 0.58), -1.0).normalized()
		var fly_distance = rise_pixels * randf_range(0.86, 1.18)
		var target_position = pop.position + fly_direction * fly_distance
		var target_rotation = pop.rotation + randf_range(-0.55, 0.55)
		var tween = host.create_tween()
		tween.set_parallel(true)
		tween.tween_property(pop, "scale", Vector2.ONE, 0.22).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(pop, "modulate:a", 1.0, 0.08).set_delay(delay)
		tween.chain().tween_property(pop, "position", target_position, 0.62).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(pop, "rotation", target_rotation, 0.62).set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(pop, "modulate:a", 0.0, 0.34).set_delay(delay + 0.44)
		tween.chain().tween_callback(host._queue_free_instance_id.bind(pop.get_instance_id()))


func _update_fishing_location_active_camera(
	card: Dictionary,
	art: Control,
	running: bool,
	delta: float,
	instant: bool,
	rest_position: Vector2,
	camera_zoom: float
) -> void:
	if art.size.x > 1.0 and art.size.y > 1.0:
		art.pivot_offset = art.size * 0.5
	art.rotation = 0.0
	var rounded_art = art as RoundedTextureRect
	if running:
		card["active_camera_was_running"] = true
		card["active_camera_returning"] = false
		card.erase("active_camera_return_elapsed")
		card.erase("active_camera_return_start_position")
		card.erase("active_camera_return_start_scale")
		if not bool(card.get("active_camera_initialized", false)):
			card["active_camera_initialized"] = true
			card["active_camera_target"] = Vector2.ZERO
			card["active_camera_next_shift"] = randf_range(1.35, 2.4)
		var next_shift = float(card.get("active_camera_next_shift", 0.0)) - delta
		if next_shift <= 0.0:
			var pan = card.get("active_camera_pan", host.FISHING_LOCATION_ACTIVE_CAMERA_PAN) as Vector2
			card["active_camera_target"] = Vector2(
				randf_range(-pan.x, pan.x),
				randf_range(-pan.y, pan.y)
			)
			next_shift = randf_range(2.6, 4.4)
		card["active_camera_next_shift"] = next_shift
		var target_position = rest_position + (card.get("active_camera_target", Vector2.ZERO) as Vector2)
		if rounded_art != null:
			rounded_art.position = rest_position
			rounded_art.scale = Vector2.ONE
			var current_zoom = rounded_art.sample_zoom
			if current_zoom <= 0.0:
				current_zoom = 1.0
			var current_offset = rounded_art.sample_offset_px
			if instant:
				current_zoom = camera_zoom
				current_offset = target_position
			else:
				var blend = clampf(delta * host.FISHING_LOCATION_ACTIVE_CAMERA_EASE, 0.0, 1.0)
				current_zoom = lerpf(current_zoom, camera_zoom, blend)
				current_offset = current_offset.lerp(target_position, blend)
			rounded_art.sample_zoom = current_zoom
			rounded_art.sample_offset_px = current_offset
			rounded_art.queue_redraw()
			return
		if instant:
			art.position = target_position
			art.scale = Vector2(camera_zoom, camera_zoom)
			return
		var blend = clampf(delta * host.FISHING_LOCATION_ACTIVE_CAMERA_EASE, 0.0, 1.0)
		art.position = art.position.lerp(target_position, blend)
		art.scale = art.scale.lerp(Vector2(camera_zoom, camera_zoom), blend)
		return
	card["active_camera_was_running"] = false
	card["active_camera_initialized"] = false
	card["active_camera_target"] = Vector2.ZERO
	if rounded_art != null:
		rounded_art.position = rest_position
		rounded_art.rotation = 0.0
		rounded_art.scale = Vector2.ONE
		if instant:
			rounded_art.sample_zoom = 1.0
			rounded_art.sample_offset_px = Vector2.ZERO
			rounded_art.queue_redraw()
			card["active_camera_returning"] = false
			card.erase("active_camera_return_elapsed")
			card.erase("active_camera_return_start_position")
			card.erase("active_camera_return_start_scale")
			return
		var zoom_step = clampf(delta / maxf(0.001, host.FISHING_METHOD_ACTIVE_SWAY_RETURN_SECONDS), 0.0, 1.0)
		rounded_art.sample_zoom = lerpf(rounded_art.sample_zoom, 1.0, zoom_step)
		rounded_art.sample_offset_px = rounded_art.sample_offset_px.lerp(Vector2.ZERO, zoom_step)
		if absf(rounded_art.sample_zoom - 1.0) <= 0.001 and rounded_art.sample_offset_px.length_squared() <= 0.25:
			rounded_art.sample_zoom = 1.0
			rounded_art.sample_offset_px = Vector2.ZERO
			card["active_camera_returning"] = false
			card.erase("active_camera_return_elapsed")
			card.erase("active_camera_return_start_position")
			card.erase("active_camera_return_start_scale")
		rounded_art.queue_redraw()
		return
	if instant:
		art.position = rest_position
		art.rotation = 0.0
		art.scale = Vector2.ONE
		card["active_camera_returning"] = false
		card.erase("active_camera_return_elapsed")
		card.erase("active_camera_return_start_position")
		card.erase("active_camera_return_start_scale")
		return
	if not card.has("active_camera_return_elapsed"):
		card["active_camera_return_elapsed"] = 0.0
		card["active_camera_return_start_position"] = art.position
		card["active_camera_return_start_scale"] = art.scale
	var return_elapsed = float(card.get("active_camera_return_elapsed", 0.0)) + delta
	card["active_camera_return_elapsed"] = return_elapsed
	var return_t = clampf(return_elapsed / maxf(0.001, host.FISHING_LOCATION_ACTIVE_CAMERA_RETURN_SECONDS), 0.0, 1.0)
	var eased_return_t = 1.0 - pow(1.0 - return_t, 3.0)
	var start_position = card.get("active_camera_return_start_position", art.position) as Vector2
	var start_scale = card.get("active_camera_return_start_scale", art.scale) as Vector2
	art.position = start_position.lerp(rest_position, eased_return_t)
	art.scale = start_scale.lerp(Vector2.ONE, eased_return_t)
	if return_t >= 1.0:
		art.position = rest_position
		art.scale = Vector2.ONE
		card["active_camera_returning"] = false
		card.erase("active_camera_return_elapsed")
		card.erase("active_camera_return_start_position")
		card.erase("active_camera_return_start_scale")


func _fishing_control_drag_is_vertical_scroll(source: Control, event_position: Vector2, press_position_meta: String) -> bool:
	if source == null or not is_instance_valid(source) or not source.has_meta(press_position_meta):
		return false
	var press_position: Vector2 = host._meta_vector2(source, press_position_meta, event_position)
	var drag_offset: Vector2 = event_position - press_position
	return (
		absf(drag_offset.y) >= host.ACTION_CARD_SCROLL_DRAG_VISUAL_DEADZONE
		and absf(drag_offset.y) > absf(drag_offset.x) * 1.15
	)


func _fishing_control_drag_is_horizontal_swipe(source: Control, event_position: Vector2, press_position_meta: String) -> bool:
	if host.current_screen != "skill" or host.selected_skill_id != "fishing":
		return false
	if source == null or not is_instance_valid(source) or not source.has_meta(press_position_meta):
		return false
	var press_position: Vector2 = host._meta_vector2(source, press_position_meta, event_position)
	var drag_offset: Vector2 = event_position - press_position
	return (
		absf(drag_offset.x) >= host.ACTION_CARD_SCROLL_DRAG_VISUAL_DEADZONE
		and absf(drag_offset.x) > absf(drag_offset.y) * 1.15
	)


func _fishing_control_drag_exceeds_tap_slop(source: Control, event_position: Vector2, press_position_meta: String) -> bool:
	if source == null or not is_instance_valid(source) or not source.has_meta(press_position_meta):
		return false
	var press_position: Vector2 = host._meta_vector2(source, press_position_meta, event_position)
	return event_position.distance_to(press_position) > host.PASSIVE_BUTTON_TAP_RELEASE_SLOP


func _prepare_fishing_control_tap() -> void:
	var active_scroll: MobileScrollContainer = host._active_action_scroll_container()
	if active_scroll != null and is_instance_valid(active_scroll):
		active_scroll.prepare_child_tap()
	host.skill_swipe_tracking = false
	host.skill_swipe_horizontal = false
	host.skill_swipe_touch_index = -1


func _motion_event_touch_index(event: InputEvent) -> int:
	if event is InputEventScreenDrag:
		return (event as InputEventScreenDrag).index
	return -1


func _handoff_fishing_vertical_scroll(press_position: Vector2, event_position: Vector2, touch_index := -1) -> void:
	var active_scroll: MobileScrollContainer = host._active_action_scroll_container()
	if active_scroll == null or not is_instance_valid(active_scroll):
		return
	active_scroll.handoff_drag_scroll(press_position, event_position, touch_index)
	_set_fishing_scroll_mode_active(true)
	host.fishing_scroll_mode_release_msec = Time.get_ticks_msec() + host.FISHING_SCROLL_MODE_SETTLE_MSEC


func _on_fishing_method_button_input(
	event: InputEvent,
	skill_id: String,
	action_id: String,
	area_key: String,
	owner_area_pop_instance_id: int,
	source: Button
) -> bool:
	if source == null or not is_instance_valid(source) or source.disabled:
		return false
	var event_position = host._passive_button_event_position(event, source)
	var event_kind = ButtonPressState.event_kind(event)
	if event_kind == "press":
		if host._position_inside_bottom_interactive_ui(event_position) or not host._position_inside_detail_actions_viewport(event_position):
			return false
		var method_card_for_press = host._fishing_method_card_for_action(skill_id, action_id)
		var press_kind = host.ACTION_CARD_MEDAL_PRESS_KIND if host._action_card_medal_hit_at_position(method_card_for_press, event_position) else ""
		if host.running_skill_id == skill_id and host.running_action_id == action_id:
			if press_kind.is_empty() and host._action_runtime()._try_action_opportunity_click(skill_id, action_id, event_position):
				host.action_card_press_consumed = true
				host._cancel_action_stop_hold()
				host.skill_swipe_tracking = false
				host.skill_swipe_horizontal = false
				host.skill_swipe_touch_index = -1
				host.get_viewport().set_input_as_handled()
				return true
			if press_kind.is_empty() and host._action_runtime()._miss_action_opportunity_click(skill_id, action_id, event_position):
				host.action_card_press_consumed = true
				host._cancel_action_stop_hold()
				host.skill_swipe_tracking = false
				host.skill_swipe_horizontal = false
				host.skill_swipe_touch_index = -1
				host.get_viewport().set_input_as_handled()
				return true
			if press_kind.is_empty():
				var pointer_id = (event as InputEventScreenTouch).index if event is InputEventScreenTouch else -1
				host._begin_action_stop_hold(skill_id, action_id, event_position, pointer_id)
				host.get_viewport().set_input_as_handled()
				return true
		_prepare_fishing_control_tap()
		_clear_active_fishing_method_button_press()
		host.fishing_method_button_press_active = true
		host.fishing_method_button_press_source_id = source.get_instance_id()
		source.set_meta("fishing_method_owner_pop_instance_id", owner_area_pop_instance_id)
		ButtonPressState.begin(source, "fishing_method", event_position)
		source.set_meta("fishing_method_press_kind", press_kind)
		host.get_viewport().set_input_as_handled()
		return true
	if event_kind == "drag":
		if ButtonPressState.active(source, "fishing_method"):
			if _fishing_control_drag_exceeds_tap_slop(source, event_position, "fishing_method_press_position"):
				ButtonPressState.update_drag(source, "fishing_method", event_position, host.PASSIVE_BUTTON_TAP_RELEASE_SLOP)
			if _fishing_control_drag_is_vertical_scroll(source, event_position, "fishing_method_press_position"):
				var method_scroll_press_position = host._meta_vector2(source, "fishing_method_press_position", event_position)
				_clear_active_fishing_method_button_press()
				_handoff_fishing_vertical_scroll(method_scroll_press_position, event_position, _motion_event_touch_index(event))
				return true
			if _fishing_control_drag_is_horizontal_swipe(source, event_position, "fishing_method_press_position"):
				var method_swipe_press_position = host._meta_vector2(source, "fishing_method_press_position", event_position)
				var touch_index = (event as InputEventScreenDrag).index if event is InputEventScreenDrag else -1
				ButtonPressState.clear(source, "fishing_method", ["kind"])
				host.fishing_method_button_press_active = false
				host.fishing_method_button_press_source_id = 0
				host._begin_skill_swipe_tracking(method_swipe_press_position, touch_index)
				if host.skill_swipe_tracking:
					host._update_skill_swipe_feedback(event_position)
				host.get_viewport().set_input_as_handled()
				return true
			ButtonPressState.update_drag(source, "fishing_method", event_position, -1.0)
			host.get_viewport().set_input_as_handled()
			return true
		return false
	if event_kind == "release":
		var was_active = ButtonPressState.active(source, "fishing_method")
		var press_kind = str(source.get_meta("fishing_method_press_kind", ""))
		var valid_tap = ButtonPressState.finish(source, "fishing_method", event_position, host.PASSIVE_BUTTON_TAP_RELEASE_SLOP, -1.0, ["kind"])
		host.fishing_method_button_press_active = false
		host.fishing_method_button_press_source_id = 0
		if not was_active:
			return false
		if (
			valid_tap
			and host._position_inside_detail_actions_viewport(event_position)
			and not host._detail_actions_scroll_suppresses_child_click()
			and not host._skill_swipe_suppresses_button_action()
		):
			var method_card = host._fishing_method_card_for_action(skill_id, action_id)
			if press_kind == host.ACTION_CARD_MEDAL_PRESS_KIND:
				if host._action_card_medal_hit_at_position(method_card, event_position):
					host._play_action_card_medal_tap_ceremony(method_card)
			elif host.queue_selection_mode:
				var owner_area_card = _fishing_area_card_for_pop_instance_id(owner_area_pop_instance_id)
				if owner_area_card.is_empty():
					host._skill_swipe_activity_surface()._queue_selection_toggle_from_card(method_card)
				else:
					host._skill_swipe_activity_surface()._queue_selection_toggle_from_card(owner_area_card)
			elif host.current_screen == "queue":
				var owner_area_card = _fishing_area_card_for_pop_instance_id(owner_area_pop_instance_id)
				var module_key = host._skill_swipe_activity_surface()._activity_queue_module_key_for_card(owner_area_card if not owner_area_card.is_empty() else method_card)
				if not module_key.is_empty():
					host._activity_queue_runtime()._start_activity_queue_from_key(module_key)
			else:
				host._on_fishing_method_pressed(skill_id, action_id, area_key, owner_area_pop_instance_id)
		host.get_viewport().set_input_as_handled()
		return true
	return false


func _route_fishing_method_button_global_input(event: InputEvent) -> bool:
	if host.fishing_scroll_mouse_pick_suspended:
		return false
	if host.current_screen != "skill" and host.current_screen != "pinned" and host.current_screen != "queue":
		return false
	if host.current_screen == "skill" and host.selected_skill_id != "fishing":
		return false
	var event_position := Vector2.ZERO
	var is_press := false
	var is_release := false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_event := event as InputEventMouseButton
		event_position = mouse_event.global_position
		is_press = mouse_event.pressed
		is_release = not mouse_event.pressed
	elif event is InputEventMouseMotion:
		event_position = (event as InputEventMouseMotion).global_position
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		event_position = touch_event.position
		is_press = touch_event.pressed
		is_release = not touch_event.pressed
	elif event is InputEventScreenDrag:
		event_position = (event as InputEventScreenDrag).position
	else:
		return false
	if host.skill_swipe_tracking and host.skill_swipe_horizontal:
		return false
	if is_release and not host.fishing_method_button_press_active:
		var active_scroll := host._active_action_scroll_container() as ScrollContainer
		if active_scroll != null and is_instance_valid(active_scroll) and active_scroll.drag_tracking:
			active_scroll._input(event)
			return true
	if not is_press and not host.fishing_method_button_press_active:
		return false
	var hit := _fishing_method_button_hit(event_position, true) if is_press else _active_fishing_method_button_hit()
	if hit.is_empty():
		return false
	var method_card := hit.get("method_card", {}) as Dictionary
	var source := hit.get("button", null) as Button
	if method_card.is_empty() or source == null or not is_instance_valid(source):
		return false
	var owner_area_card := hit.get("owner_area_card", {}) as Dictionary
	var owner_pop := owner_area_card.get("pop", null) as Control
	var owner_area_pop_instance_id := owner_pop.get_instance_id() if owner_pop != null and is_instance_valid(owner_pop) else 0
	if owner_area_pop_instance_id == 0:
		owner_area_pop_instance_id = int(hit.get("owner_pop_instance_id", 0))
	return _on_fishing_method_button_input(
		event,
		str(method_card.get("skill_id", "fishing")),
		str(method_card.get("action_id", "")),
		str(method_card.get("fishing_area_key", "")),
		owner_area_pop_instance_id,
		source
	)


func _route_fishing_location_image_priority_press(event: InputEvent) -> bool:
	if host.fishing_scroll_mouse_pick_suspended:
		return false
	if host.current_screen != "skill" and host.current_screen != "pinned" and host.current_screen != "queue":
		return false
	if host.current_screen == "skill" and host.selected_skill_id != "fishing":
		return false
	var event_position := Vector2.ZERO
	var is_press := false
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return false
		event_position = mouse_event.global_position
		is_press = mouse_event.pressed
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		event_position = touch_event.position
		is_press = touch_event.pressed
	else:
		return false
	if not is_press:
		return false
	if host._position_inside_bottom_interactive_ui(event_position) or not host._position_inside_detail_actions_viewport(event_position):
		return false
	var hit := _fishing_method_button_hit(event_position, true)
	if hit.is_empty():
		return false
	var method_card := hit.get("method_card", {}) as Dictionary
	if method_card.is_empty() or not bool(method_card.get("is_fishing_location", false)):
		return false
	var skill_id := str(method_card.get("skill_id", "fishing"))
	var action_id := str(method_card.get("action_id", ""))
	var action: Dictionary = host._action_data(skill_id, action_id)
	if action.is_empty() or not host._is_action_unlocked(skill_id, action):
		return false
	var owner_area_card := hit.get("owner_area_card", {}) as Dictionary
	var owner_pop := owner_area_card.get("pop", null) as Control
	var owner_area_pop_instance_id := owner_pop.get_instance_id() if owner_pop != null and is_instance_valid(owner_pop) else 0
	if owner_area_pop_instance_id == 0:
		owner_area_pop_instance_id = int(hit.get("owner_pop_instance_id", 0))
	var source := hit.get("button", null) as Button
	if source == null or not is_instance_valid(source):
		return false
	return _on_fishing_method_button_input(
		event,
		skill_id,
		action_id,
		str(method_card.get("fishing_area_key", "")),
		owner_area_pop_instance_id,
		source
	)


func _fishing_method_button_hit(event_position: Vector2, require_contains_point := true) -> Dictionary:
	if host.fishing_scroll_mouse_pick_suspended:
		return {}
	var positions: Array = host._activity_input_position_candidates(event_position)
	var matched_hit := {}
	var matched_rect_area := INF
	var matched_rect_center_distance := INF
	var trace_hit: bool = _fishing_input_trace_enabled() and require_contains_point
	for hit in _fishing_method_button_hit_candidates():
		var button := hit.get("button", null) as Button
		if button == null or not is_instance_valid(button) or button.disabled:
			continue
		if not button.is_inside_tree() or not button.is_visible_in_tree():
			continue
		var method_card_for_hit := hit.get("method_card", {}) as Dictionary
		var hit_control := hit.get("hit_control", button) as Control
		if require_contains_point and bool(method_card_for_hit.get("is_fishing_location", false)):
			var image_hit_control := method_card_for_hit.get("method_image_hit_control", null) as Control
			if (
				image_hit_control != null
				and is_instance_valid(image_hit_control)
				and host._first_position_in_rect(positions, image_hit_control.get_global_rect()) != null
			):
				hit_control = image_hit_control
		if hit_control == null or not is_instance_valid(hit_control) or not hit_control.is_inside_tree() or not hit_control.is_visible_in_tree():
			hit_control = button
		var hit_rect := hit_control.get_global_rect()
		if require_contains_point:
			if host._first_position_in_rect(positions, hit_rect) == null:
				continue
			var rect_area := hit_rect.size.x * hit_rect.size.y
			if trace_hit:
				var trace_card := hit.get("method_card", {}) as Dictionary
				print("FISHING_METHOD_HIT_TRACE action=%s area=%s rect=%s rect_area=%.1f" % [
					str(trace_card.get("action_id", "")),
					str(trace_card.get("area_id", "")),
					str(hit_rect),
					rect_area
				])
			var rect_center_distance := hit_rect.get_center().distance_to(event_position)
			if (
				not matched_hit.is_empty()
				and (
					rect_area > matched_rect_area + 0.5
					or (absf(rect_area - matched_rect_area) <= 0.5 and rect_center_distance >= matched_rect_center_distance)
				)
			):
				continue
			matched_rect_area = rect_area
			matched_rect_center_distance = rect_center_distance
		matched_hit = hit
	if trace_hit and not matched_hit.is_empty():
		var matched_card := matched_hit.get("method_card", {}) as Dictionary
		print("FISHING_METHOD_HIT_TRACE matched=%s pos=%s" % [str(matched_card.get("action_id", "")), str(event_position)])
	return matched_hit


func _event_inside_fishing_location_image(event: InputEvent) -> bool:
	var event_position := Vector2.ZERO
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		event_position = host._global_event_position(mouse_event.position, mouse_event.global_position)
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		event_position = host._global_event_position(touch_event.position, touch_event.position)
	else:
		return false
	return _fishing_location_image_hit_at_position(event_position)


func _fishing_location_image_hit_at_position(event_position: Vector2) -> bool:
	var positions: Array = host._activity_input_position_candidates(event_position)
	for hit in _fishing_method_button_hit_candidates():
		var method_card := hit.get("method_card", {}) as Dictionary
		if not bool(method_card.get("is_fishing_location", false)):
			continue
		var hit_control := method_card.get("method_image_hit_control", null) as Control
		if hit_control == null or not is_instance_valid(hit_control) or not hit_control.is_inside_tree() or not hit_control.is_visible_in_tree():
			continue
		if host._first_position_in_rect(positions, hit_control.get_global_rect()) != null:
			return true
	return false


func _active_fishing_method_button_hit() -> Dictionary:
	if host.fishing_method_button_press_source_id != 0:
		var active_button := instance_from_id(host.fishing_method_button_press_source_id) as Button
		if ButtonPressState.active(active_button, "fishing_method"):
			var method_card := active_button.get_meta("fishing_method_card", {}) as Dictionary
			if not method_card.is_empty():
				var hit_control := method_card.get("method_hit_control", active_button) as Control
				return {
					"method_card": method_card,
					"button": active_button,
					"hit_control": hit_control,
					"owner_area_card": {},
					"owner_pop_instance_id": int(active_button.get_meta("fishing_method_owner_pop_instance_id", 0))
				}
	for hit in _fishing_method_button_hit_candidates():
		var button := hit.get("button", null) as Button
		if ButtonPressState.active(button, "fishing_method"):
			return hit
	return {}


func _clear_active_fishing_method_button_press() -> void:
	host.fishing_method_button_press_active = false
	host.fishing_method_button_press_source_id = 0
	for hit in _fishing_method_button_hit_candidates():
		var button := hit.get("button", null) as Button
		if button == null or not is_instance_valid(button):
			continue
		ButtonPressState.clear(button, "fishing_method", ["kind"])


func _fishing_method_button_hit_candidates() -> Array:
	var hits: Array = []
	var seen_buttons := {}
	for raw_card in host.action_cards.values():
		if typeof(raw_card) != TYPE_DICTIONARY:
			continue
		var card := raw_card as Dictionary
		if bool(card.get("is_fishing_method", false)):
			var button := card.get("method_button", null) as Button
			var hit_control := card.get("method_hit_control", button) as Control
			if button != null and is_instance_valid(button) and not seen_buttons.has(button.get_instance_id()):
				seen_buttons[button.get_instance_id()] = true
				hits.append({"method_card": card, "button": button, "hit_control": hit_control, "owner_area_card": {}})
			continue
		if not bool(card.get("is_fishing_area", false)):
			continue
		for raw_method_card in (card.get("method_slots", {}) as Dictionary).values():
			if typeof(raw_method_card) != TYPE_DICTIONARY:
				continue
			var method_card := raw_method_card as Dictionary
			if not bool(method_card.get("is_fishing_method", false)):
				continue
			var method_button := method_card.get("method_button", null) as Button
			var hit_control := method_card.get("method_hit_control", method_button) as Control
			if method_button != null and is_instance_valid(method_button) and not seen_buttons.has(method_button.get_instance_id()):
				seen_buttons[method_button.get_instance_id()] = true
				hits.append({"method_card": method_card, "button": method_button, "hit_control": hit_control, "owner_area_card": card})
	for raw_lazy_entry in host.detail_lazy_plan:
		if typeof(raw_lazy_entry) != TYPE_DICTIONARY:
			continue
		var lazy_entry := raw_lazy_entry as Dictionary
		if str(lazy_entry.get("kind", "")) != "fishing_area" or not bool(lazy_entry.get("mounted", false)):
			continue
		var lazy_area_card := lazy_entry.get("card", {}) as Dictionary
		if lazy_area_card.is_empty():
			continue
		for raw_lazy_method_card in (lazy_area_card.get("method_slots", {}) as Dictionary).values():
			if typeof(raw_lazy_method_card) != TYPE_DICTIONARY:
				continue
			var lazy_method_card := raw_lazy_method_card as Dictionary
			if not bool(lazy_method_card.get("is_fishing_method", false)):
				continue
			var lazy_method_button := lazy_method_card.get("method_button", null) as Button
			var lazy_hit_control := lazy_method_card.get("method_hit_control", lazy_method_button) as Control
			if lazy_method_button != null and is_instance_valid(lazy_method_button) and not seen_buttons.has(lazy_method_button.get_instance_id()):
				seen_buttons[lazy_method_button.get_instance_id()] = true
				hits.append({"method_card": lazy_method_card, "button": lazy_method_button, "hit_control": lazy_hit_control, "owner_area_card": lazy_area_card})
	var tree := host.get_tree() as SceneTree
	if tree != null:
		for raw_button in tree.get_nodes_in_group("fishing_method_buttons"):
			var grouped_button := raw_button as Button
			if grouped_button == null or not is_instance_valid(grouped_button) or seen_buttons.has(grouped_button.get_instance_id()):
				continue
			var grouped_method_card := grouped_button.get_meta("fishing_method_card", {}) as Dictionary
			if grouped_method_card.is_empty() or not bool(grouped_method_card.get("is_fishing_method", false)):
				continue
			var grouped_hit_control := grouped_method_card.get("method_hit_control", grouped_button) as Control
			seen_buttons[grouped_button.get_instance_id()] = true
			hits.append({
				"method_card": grouped_method_card,
				"button": grouped_button,
				"hit_control": grouped_hit_control,
				"owner_area_card": {},
				"owner_pop_instance_id": int(grouped_button.get_meta("fishing_method_owner_pop_instance_id", 0))
			})
	return hits

func _fishing_offer_height(offer_id: String) -> float:
	match offer_id:
		"net":
			return float(host.FISHING_NET_OFFER_HEIGHT)
		"rod":
			return float(host.FISHING_ROD_OFFER_HEIGHT)
		"reinforced_rod", "star_rod":
			return float(host.FISHING_ROD_UPGRADE_OFFER_HEIGHT)
		"boat":
			return float(host.FISHING_BOAT_OFFER_HEIGHT)
		"mirror":
			return float(host.FISHING_MIRROR_OFFER_HEIGHT)
	return float(host.FISHING_ROD_OFFER_HEIGHT)

func _build_fishing_offer_module(offer_id: String, content_width: float) -> Control:
	var root: Control = null
	match offer_id:
		"net":
			root = _build_fishing_net_offer_module(content_width)
		"rod":
			root = _build_fishing_rod_offer_module(content_width)
		"reinforced_rod", "star_rod":
			root = _build_fishing_rod_upgrade_offer_module(content_width, offer_id)
		"boat":
			root = _build_fishing_boat_offer_module(content_width)
		"mirror":
			root = _build_fishing_mirror_offer_module(content_width)
	if root != null and is_instance_valid(root):
		host._skill_detail_surface()._add_module_action_zones(root, ModuleUiRuntime.fishing_offer(offer_id))
	return root

func _append_fishing_offer_lazy_entry(plan: Array, y: float, offer_id: String) -> float:
	var height := _fishing_offer_height(offer_id)
	var module_key: String = ModuleUiRuntime.fishing_offer(offer_id)
	if host._module_ui_is_collapsed(module_key):
		height = host._module_collapsed_squeeze_height()
	plan.append({
		"kind": "fishing_offer",
		"offer_id": offer_id,
		"track_id": "fishing_offer:%s" % offer_id,
		"y": y,
		"height": height,
		"mounted": false,
		"stack_host": null,
		"placeholder": null,
		"direct_stack_child": false
	})
	return y + height + host.DETAIL_LAZY_STACK_SEPARATION

func _fishing_offer_unlock_level(offer_id: String) -> int:
	match offer_id:
		"net":
			return host.FISHING_NET_OFFER_UNLOCK_LEVEL
		"rod":
			return host.FISHING_ROD_OFFER_UNLOCK_LEVEL
		"reinforced_rod":
			return host.FISHING_REINFORCED_ROD_UNLOCK_LEVEL
		"star_rod":
			return host.FISHING_STAR_ROD_UNLOCK_LEVEL
		"boat":
			return host.FISHING_BOAT_OFFER_UNLOCK_LEVEL
		"mirror":
			return host.FISHING_MIRROR_OFFER_UNLOCK_LEVEL
	return 999999

func _configure_fishing_equipment_offer_title(title: Label, font_size: int, outline_size: int) -> void:
	if title == null:
		return
	title.add_theme_color_override("font_outline_color", host.COLOR_INK)
	title.add_theme_constant_override("outline_size", outline_size)
	title.add_theme_font_size_override("font_size", font_size)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.anchor_left = 0.0
	title.anchor_right = 1.0
	title.anchor_top = 0.0
	title.anchor_bottom = 0.0
	title.offset_left = host.FISHING_EQUIPMENT_OFFER_TITLE_SIDE_INSET
	title.offset_right = -host.FISHING_EQUIPMENT_OFFER_TITLE_SIDE_INSET
	title.offset_top = 28
	title.offset_bottom = 158
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _fishing_offer_shell(content_width: float, offer_height: float, texture: Texture2D, shade_alpha: float, clip_contents := false, fallback_color := Color.TRANSPARENT, feather_height := 120.0) -> Dictionary:
	var root := Control.new()
	root.custom_minimum_size = Vector2(content_width, offer_height)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var pop_card := Control.new()
	pop_card.anchor_left = 0.0
	pop_card.anchor_right = 1.0
	pop_card.anchor_top = 0.0
	pop_card.anchor_bottom = 1.0
	pop_card.offset_left = host.ACTION_CARD_POP_GUTTER
	pop_card.offset_right = -host.ACTION_CARD_POP_GUTTER
	pop_card.clip_contents = clip_contents
	root.add_child(pop_card)

	var bg := RoundedTextureRect.new()
	bg.texture = texture
	bg.radius = 64.0
	bg.art_height = offer_height
	bg.feather_height = feather_height
	if fallback_color.a > 0.0:
		bg.fallback_color = fallback_color
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pop_card.add_child(bg)

	var shade := Panel.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.add_theme_stylebox_override("panel", ActivityCardStyles.cached_shade(shade_alpha))
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pop_card.add_child(shade)

	return {"root": root, "pop": pop_card, "bg": bg, "shade": shade}

func _fishing_offer_base_button() -> Button:
	var button := Button.new()
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.flat = true
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host._apply_empty_button_style(button)
	host._button_press_runtime().attach_default_button_sfx(button)
	return button

func _register_fishing_offer_button(button: Button, root: Control, pop_card: Control, offer_id: String, connect_gui_input := false) -> void:
	button.set_meta("fishing_offer_id", offer_id)
	button.set_meta("fishing_offer_root_id", root.get_instance_id())
	button.set_meta("fishing_offer_hit_id", pop_card.get_instance_id())
	button.add_to_group("fishing_offer_buttons")
	if connect_gui_input:
		button.gui_input.connect(_on_fishing_offer_button_input.bind(offer_id, button))

func _fishing_equipment_offer_button(pop_card: Control, root: Control, offer_id: String, connect_gui_input := false) -> Button:
	var button := _fishing_offer_base_button()
	button.anchor_left = 0.5
	button.anchor_right = 0.5
	button.anchor_top = 0.5
	button.anchor_bottom = 0.5
	button.offset_left = -280
	button.offset_right = 280
	button.offset_top = -170
	button.offset_bottom = 220
	pop_card.add_child(button)
	_register_fishing_offer_button(button, root, pop_card, offer_id, connect_gui_input)
	return button

func _fishing_full_offer_button(pop_card: Control, root: Control, offer_id: String, connect_gui_input := false) -> Button:
	var button := _fishing_offer_base_button()
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	pop_card.add_child(button)
	_register_fishing_offer_button(button, root, pop_card, offer_id, connect_gui_input)
	return button

func _fishing_offer_hint(pop_card: Control, hint_text: String, available: bool, outline_size := 20, offset_top := -156.0, offset_bottom := -34.0, vertical_alignment := VERTICAL_ALIGNMENT_TOP) -> Label:
	var hint: Label = host._label(hint_text, 68, Color.WHITE if available else Color("#ffd95a"), HORIZONTAL_ALIGNMENT_CENTER)
	hint.add_theme_color_override("font_outline_color", host.COLOR_INK)
	hint.add_theme_constant_override("outline_size", outline_size)
	hint.anchor_left = 0.0
	hint.anchor_right = 1.0
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.offset_left = 48
	hint.offset_right = -48
	hint.offset_top = offset_top
	hint.offset_bottom = offset_bottom
	hint.vertical_alignment = vertical_alignment
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pop_card.add_child(hint)
	return hint

func _build_fishing_net_offer_module(content_width: float) -> Control:
	var shell := _fishing_offer_shell(content_width, host.FISHING_NET_OFFER_HEIGHT, host.visual_texture_cache._first_texture_or_visual_fallback([
		"res://assets/content/fishing/backgrounds/beach-rocky-zoom.png",
		"res://assets/content/fishing/backgrounds/00-tide-pool-shallows.png"
	]), 0.06, false, host._skill_theme_color("fishing").darkened(0.12), 0.0)
	var root := shell.get("root") as Control
	var pop_card := shell.get("pop") as Control

	var title: Label = host._label("You find an old net on the beach", 62, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_color_override("font_outline_color", host.COLOR_INK)
	title.add_theme_constant_override("outline_size", 24)
	title.anchor_left = 0.0
	title.anchor_right = 1.0
	title.anchor_top = 0.0
	title.anchor_bottom = 0.0
	title.offset_left = 48
	title.offset_right = -48
	title.offset_top = 12
	title.offset_bottom = 188
	title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pop_card.add_child(title)

	var net_button := _fishing_full_offer_button(pop_card, root, "net", true)

	var net_motion_root := Control.new()
	net_motion_root.anchor_left = 0.5
	net_motion_root.anchor_right = 0.5
	net_motion_root.anchor_top = 0.5
	net_motion_root.anchor_bottom = 0.5
	net_motion_root.offset_left = -258.5
	net_motion_root.offset_right = 258.5
	net_motion_root.offset_top = -144.5
	net_motion_root.offset_bottom = 218.5
	net_motion_root.custom_minimum_size = Vector2(517, 363)
	net_motion_root.size = Vector2(517, 363)
	net_motion_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	net_motion_root.z_index = 12
	pop_card.add_child(net_motion_root)

	var net_art: TextureRect = host.visual_texture_cache._image("res://assets/content/fishing/tools/net-player.png", Vector2(517, 363))
	net_art.anchor_left = 0.0
	net_art.anchor_right = 0.0
	net_art.anchor_top = 0.0
	net_art.anchor_bottom = 0.0
	net_art.position = Vector2.ZERO
	net_art.size = Vector2(517, 363)
	net_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	net_motion_root.add_child(net_art)
	_start_fishing_net_offer_idle_motion(net_motion_root)
	net_button.set_meta("fishing_net_art_id", net_motion_root.get_instance_id())
	_fishing_offer_hint(pop_card, "Tap the net", true, 14, -132.0, -48.0, VERTICAL_ALIGNMENT_CENTER)

	return root

func _fishing_offer_art_modulate(available: bool, available_modulate := Color.WHITE) -> Color:
	return available_modulate if available else host.FISHING_OFFER_UNAVAILABLE_ART_MODULATE

func _build_fishing_rod_offer_module(content_width: float) -> Control:
	var shell := _fishing_offer_shell(content_width, host.FISHING_ROD_OFFER_HEIGHT, host.visual_texture_cache._texture_or_visual_fallback("res://assets/content/fishing/backgrounds/02-river-bend.png"), 0.28)
	var root := shell.get("root") as Control
	var pop_card := shell.get("pop") as Control

	var title: Label = host._label("Bamboo rod", 94, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_configure_fishing_equipment_offer_title(title, 88, 24)
	pop_card.add_child(title)

	var rod_button := _fishing_equipment_offer_button(pop_card, root, "rod", true)

	var rod_art: TextureRect = host.visual_texture_cache._image("res://assets/content/fishing/tools/tool-bamboo-rod.png", Vector2(520, 360))
	rod_art.position = Vector2(20, 10)
	rod_art.modulate = _fishing_offer_art_modulate(host.fish_currency >= host.FISHING_ROD_OFFER_COST)
	rod_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rod_button.add_child(rod_art)

	var hint_text := "Buy for %s fish" % GameFormatting.compact_number(float(host.FISHING_ROD_OFFER_COST), 3)
	if host.fish_currency < host.FISHING_ROD_OFFER_COST:
		hint_text = "%s fish needed" % GameFormatting.compact_number(float(host.FISHING_ROD_OFFER_COST), 3)
	_fishing_offer_hint(pop_card, hint_text, host.fish_currency >= host.FISHING_ROD_OFFER_COST)

	return root

func _build_fishing_mirror_offer_module(content_width: float) -> Control:
	var shell := _fishing_offer_shell(content_width, host.FISHING_MIRROR_OFFER_HEIGHT, host.visual_texture_cache._texture_or_visual_fallback("res://assets/content/fishing/backgrounds/11-cosmic-dream-sea.png"), 0.34)
	var root := shell.get("root") as Control
	var pop_card := shell.get("pop") as Control

	var title: Label = host._label("Reflection mirror", 88, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_configure_fishing_equipment_offer_title(title, 80, 23)
	pop_card.add_child(title)

	var mirror_button := _fishing_equipment_offer_button(pop_card, root, "mirror")

	var mirror_art: TextureRect = host.visual_texture_cache._image("res://assets/content/fishing/tools/reflection-net.png", Vector2(520, 360))
	mirror_art.position = Vector2(20, 10)
	mirror_art.modulate = _fishing_offer_art_modulate(host.fish_currency >= host.FISHING_MIRROR_OFFER_COST)
	mirror_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mirror_button.add_child(mirror_art)

	var hint_text := "Buy for %s fish" % GameFormatting.compact_number(float(host.FISHING_MIRROR_OFFER_COST), 3)
	if host.fish_currency < host.FISHING_MIRROR_OFFER_COST:
		hint_text = "%s fish needed" % GameFormatting.compact_number(float(host.FISHING_MIRROR_OFFER_COST), 3)
	_fishing_offer_hint(pop_card, hint_text, host.fish_currency >= host.FISHING_MIRROR_OFFER_COST)

	return root

func _fishing_rod_upgrade_cost(tool_id: String) -> int:
	return host.FISHING_STAR_ROD_COST if tool_id == "star_rod" else host.FISHING_REINFORCED_ROD_COST

func _fishing_rod_upgrade_title(tool_id: String) -> String:
	return "Star rod" if tool_id == "star_rod" else "Reinforced rod"

func _build_fishing_rod_upgrade_offer_module(content_width: float, tool_id: String) -> Control:
	var shell := _fishing_offer_shell(content_width, host.FISHING_ROD_UPGRADE_OFFER_HEIGHT, host.visual_texture_cache._texture_or_visual_fallback("res://assets/content/fishing/backgrounds/04-frozen-lake.png" if tool_id == "star_rod" else "res://assets/content/fishing/backgrounds/05-coral-reef-shallows.png"), 0.30, true)
	var root := shell.get("root") as Control
	var pop_card := shell.get("pop") as Control

	var title: Label = host._label(_fishing_rod_upgrade_title(tool_id), 88, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_configure_fishing_equipment_offer_title(title, 78 if tool_id == "reinforced_rod" else 84, 23)
	pop_card.add_child(title)

	var upgrade_button := _fishing_equipment_offer_button(pop_card, root, tool_id)

	var cost := _fishing_rod_upgrade_cost(tool_id)
	var rod_art: TextureRect = host.visual_texture_cache._image("res://assets/content/fishing/tools/tool-bamboo-rod.png", Vector2(520, 360))
	rod_art.position = Vector2(20, 10)
	rod_art.modulate = _fishing_offer_art_modulate(host.fish_currency >= cost, Color("#dcf7ff") if tool_id == "star_rod" else Color("#ffe8a8"))
	rod_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	upgrade_button.add_child(rod_art)

	var hint_text := "Upgrade for %s fish" % GameFormatting.compact_number(float(cost), 3)
	if host.fish_currency < cost:
		hint_text = "%s fish needed" % GameFormatting.compact_number(float(cost), 3)
	_fishing_offer_hint(pop_card, hint_text, host.fish_currency >= cost)

	return root

func _build_fishing_boat_offer_module(content_width: float) -> Control:
	var shell := _fishing_offer_shell(content_width, host.FISHING_BOAT_OFFER_HEIGHT, host.visual_texture_cache._texture_or_visual_fallback("res://assets/content/fishing/backgrounds/07-rowboat-offshore.png"), 0.30, true)
	var root := shell.get("root") as Control
	var pop_card := shell.get("pop") as Control

	var title: Label = host._label("Build boat", 94, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_configure_fishing_equipment_offer_title(title, 88, 24)
	pop_card.add_child(title)

	var boat_button := _fishing_equipment_offer_button(pop_card, root, "boat")

	var boat_art: TextureRect = host.visual_texture_cache._image("res://assets/content/fishing/tools/tool-boat.png", Vector2(520, 360))
	boat_art.position = Vector2(20, 10)
	var can_build: bool = host._skill_level("build") >= host.FISHING_BOAT_BUILD_REQUIRED_LEVEL and host.material_runtime.amount("softwood") >= float(host.FISHING_BOAT_OFFER_COST)
	boat_art.modulate = _fishing_offer_art_modulate(can_build)
	boat_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boat_button.add_child(boat_art)

	var hint_text := "Build for %s Softwood" % GameFormatting.compact_number(float(host.FISHING_BOAT_OFFER_COST), 3)
	if host._skill_level("build") < host.FISHING_BOAT_BUILD_REQUIRED_LEVEL:
		hint_text = "Requires Building Lv %s" % host.FISHING_BOAT_BUILD_REQUIRED_LEVEL
	elif host.material_runtime.amount("softwood") < float(host.FISHING_BOAT_OFFER_COST):
		hint_text = "%s Softwood needed" % GameFormatting.compact_number(float(host.FISHING_BOAT_OFFER_COST), 3)
	_fishing_offer_hint(pop_card, hint_text, can_build)

	return root

func _on_fishing_offer_button_input(event: InputEvent, offer_id: String, source: Button) -> bool:
	if source == null or not is_instance_valid(source) or source.disabled:
		return false
	var event_position: Vector2 = host._passive_button_event_position(event, source)
	var event_kind := ButtonPressState.event_kind(event)
	if event_kind == "press":
		if (
			(host._position_inside_bottom_interactive_ui(event_position) and not _fishing_offer_button_contains_point(source, event_position))
			or not host._position_inside_detail_actions_viewport(event_position)
		):
			return false
		_prepare_fishing_control_tap()
		host.fishing_offer_button_press_active = true
		ButtonPressState.begin(source, "fishing_offer", event_position)
		host.get_viewport().set_input_as_handled()
		return true
	if event_kind == "drag":
		if ButtonPressState.active(source, "fishing_offer"):
			if _fishing_control_drag_exceeds_tap_slop(source, event_position, "fishing_offer_press_position"):
				ButtonPressState.update_drag(source, "fishing_offer", event_position, host.PASSIVE_BUTTON_TAP_RELEASE_SLOP)
			if _fishing_control_drag_is_vertical_scroll(source, event_position, "fishing_offer_press_position"):
				var offer_scroll_press_position: Vector2 = host._meta_vector2(source, "fishing_offer_press_position", event_position)
				_clear_fishing_offer_button_press(source)
				_handoff_fishing_vertical_scroll(offer_scroll_press_position, event_position, _motion_event_touch_index(event))
				return false
			if _fishing_control_drag_is_horizontal_swipe(source, event_position, "fishing_offer_press_position"):
				var offer_swipe_press_position: Vector2 = host._meta_vector2(source, "fishing_offer_press_position", event_position)
				var touch_index := (event as InputEventScreenDrag).index if event is InputEventScreenDrag else -1
				_clear_fishing_offer_button_press(source)
				host._begin_skill_swipe_tracking(offer_swipe_press_position, touch_index)
				if host.skill_swipe_tracking:
					host._update_skill_swipe_feedback(event_position)
				host.get_viewport().set_input_as_handled()
				return true
			ButtonPressState.update_drag(source, "fishing_offer", event_position, -1.0)
			host.get_viewport().set_input_as_handled()
			return true
		return false
	if event_kind == "release":
		var was_active := ButtonPressState.active(source, "fishing_offer")
		var valid_tap := ButtonPressState.finish(source, "fishing_offer", event_position, host.PASSIVE_BUTTON_TAP_RELEASE_SLOP)
		host.fishing_offer_button_press_active = false
		if not was_active:
			return false
		if (
			valid_tap
			and host._position_inside_detail_actions_viewport(event_position)
			and not host._skill_swipe_suppresses_button_action()
		):
			host._activate_fishing_offer_button(offer_id, source)
		host.get_viewport().set_input_as_handled()
		return true
	return false

func _route_fishing_offer_button_global_input(event: InputEvent) -> bool:
	if host.current_screen != "skill" or host.selected_skill_id != "fishing":
		return false
	var event_position := Vector2.ZERO
	var is_press := false
	var is_release := false
	var is_motion := false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_event := event as InputEventMouseButton
		event_position = mouse_event.global_position
		is_press = mouse_event.pressed
		is_release = not mouse_event.pressed
	elif event is InputEventMouseMotion:
		event_position = (event as InputEventMouseMotion).global_position
		is_motion = true
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		event_position = touch_event.position
		is_press = touch_event.pressed
		is_release = not touch_event.pressed
	elif event is InputEventScreenDrag:
		event_position = (event as InputEventScreenDrag).position
		is_motion = true
	else:
		return false
	if host.fishing_scroll_mouse_pick_suspended:
		if is_press:
			_set_fishing_scroll_mode_active(false)
		else:
			return false
	if not is_press and not host.fishing_offer_button_press_active:
		return false
	var source := _fishing_offer_button_hit(event_position, true) if is_press else _active_fishing_offer_button()
	if host._position_inside_bottom_interactive_ui(event_position):
		if source == null:
			_clear_fishing_offer_button_press(_active_fishing_offer_button())
			return false
	if source == null:
		return false
	return _on_fishing_offer_button_input(event, str(source.get_meta("fishing_offer_id", "")), source)

func _fishing_offer_button_hit(event_position: Vector2, require_contains_point := true) -> Button:
	if host.fishing_scroll_mouse_pick_suspended:
		return null
	for raw_button in host.get_tree().get_nodes_in_group("fishing_offer_buttons"):
		var button := raw_button as Button
		if button == null or not is_instance_valid(button) or button.disabled:
			continue
		if not button.is_inside_tree() or not button.is_visible_in_tree():
			continue
		if require_contains_point and not _fishing_offer_button_contains_point(button, event_position):
			continue
		return button
	return null

func _fishing_offer_button_contains_point(button: Button, event_position: Vector2) -> bool:
	if button.get_global_rect().has_point(event_position):
		return true
	for meta_name in ["fishing_offer_hit_id", "fishing_offer_root_id"]:
		if not button.has_meta(meta_name):
			continue
		var hit_control: Control = host._valid_control_ref(instance_from_id(int(button.get_meta(meta_name))))
		if hit_control == null:
			continue
		if not hit_control.is_inside_tree() or not hit_control.is_visible_in_tree():
			continue
		if hit_control.get_global_rect().has_point(event_position):
			return true
	return false

func _active_fishing_offer_button() -> Button:
	for raw_button in host.get_tree().get_nodes_in_group("fishing_offer_buttons"):
		var button := raw_button as Button
		if ButtonPressState.active(button, "fishing_offer"):
			return button
	return null

func _clear_fishing_offer_button_press(source: Button) -> void:
	host.fishing_offer_button_press_active = false
	ButtonPressState.clear(source, "fishing_offer")

func _start_fishing_net_offer_idle_motion(net_root: Control) -> void:
	if net_root == null or not is_instance_valid(net_root):
		return
	await host.get_tree().process_frame
	if net_root == null or not is_instance_valid(net_root):
		return
	net_root.pivot_offset = net_root.size * 0.5
	var base_position := net_root.position
	var tween: Tween = host.create_tween()
	tween.set_loops()
	tween.tween_method(_apply_fishing_net_offer_idle_frame.bind(net_root.get_instance_id(), base_position), 0.0, 1.0, 2.90).set_trans(Tween.TRANS_LINEAR)
	net_root.set_meta("fishing_net_offer_idle_tween", tween)

func _apply_fishing_net_offer_idle_frame(value: float, net_root_id: int, base_position: Vector2) -> void:
	var net_root: Control = host._valid_control_ref(instance_from_id(net_root_id))
	if net_root == null:
		return
	var phase := value * TAU
	var bob := sin(phase) * 10.0
	var sway := sin(phase + 0.6) * 7.0
	net_root.position = base_position + Vector2(sway, bob)
	net_root.rotation = sin(phase - 0.4) * 0.055

func _collect_fishing_net_offer_to_wallet(net_root: Control) -> bool:
	if net_root == null or not is_instance_valid(net_root) or host.detail_fish_circle == null or not is_instance_valid(host.detail_fish_circle):
		return false
	host._kill_meta_tween(net_root, "fishing_net_offer_idle_tween")
	var source_rect := net_root.get_global_rect()
	var target_rect: Rect2 = host.detail_fish_circle.get_global_rect()
	var to_local: Transform2D = host.get_global_transform_with_canvas().affine_inverse()
	var start: Vector2 = to_local * source_rect.get_center()
	var target: Vector2 = to_local * target_rect.get_center()
	var old_parent := net_root.get_parent()
	if old_parent != null:
		old_parent.remove_child(net_root)
	var collection_canvas := _fishing_collection_canvas()
	collection_canvas.add_child(net_root)
	net_root.anchor_left = 0.0
	net_root.anchor_right = 0.0
	net_root.anchor_top = 0.0
	net_root.anchor_bottom = 0.0
	net_root.size = source_rect.size
	net_root.position = start - net_root.size * 0.5
	net_root.pivot_offset = net_root.size * 0.5
	net_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	net_root.z_index = host.MODAL_OVERLAY_Z - 1
	net_root.z_as_relative = false
	_play_staged_net_collect_to_wallet(net_root, target)
	_play_fishing_wallet_circle_pop(2.40)
	return true

func _fishing_collection_canvas() -> CanvasLayer:
	if host.fishing_collection_canvas != null and is_instance_valid(host.fishing_collection_canvas):
		return host.fishing_collection_canvas
	var canvas := CanvasLayer.new()
	canvas.name = "FishingCollectionCanvas"
	canvas.layer = host.FISHING_COLLECTION_CANVAS_LAYER
	host.add_child(canvas)
	host.fishing_collection_canvas = canvas
	return canvas

func _fly_fishing_tool_to_wallet(source: Control, texture_path: String, staged_net_collect := false) -> void:
	if source == null or not is_instance_valid(source) or host.detail_fish_circle == null or not is_instance_valid(host.detail_fish_circle):
		return
	var texture: Texture2D = host.visual_texture_cache._texture(texture_path)
	if texture == null:
		return
	var source_rect := source.get_global_rect()
	var target_rect: Rect2 = host.detail_fish_circle.get_global_rect() if staged_net_collect else host.detail_fish_circle.tool_icon_global_rect() if host.detail_fish_circle.has_method("tool_icon_global_rect") else host.detail_fish_circle.get_global_rect()
	var to_local: Transform2D = host.get_global_transform_with_canvas().affine_inverse()
	var start: Vector2 = to_local * source_rect.get_center()
	var target: Vector2 = to_local * target_rect.get_center()
	var art := TextureRect.new()
	art.texture = texture
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.size = Vector2(260, 260) if staged_net_collect else Vector2(220, 220)
	art.position = start - art.size * 0.5
	art.pivot_offset = art.size * 0.5
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.z_index = host.MODAL_OVERLAY_Z - 1
	art.z_as_relative = false
	_fishing_collection_canvas().add_child(art)
	if staged_net_collect:
		_play_staged_net_collect_to_wallet(art, target)
		_play_fishing_wallet_circle_pop(2.40)
		return
	var tween: Tween = host.create_tween()
	tween.set_parallel(true)
	tween.tween_property(art, "position", target - art.size * 0.5, 0.46).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(art, "scale", Vector2(0.62, 0.62), 0.46).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(art, "rotation", randf_range(-0.35, 0.35), 0.46).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.chain().tween_callback(host._set_fish_circle_for_skill_bound.bind(host.detail_fish_circle.get_instance_id(), host.selected_skill_id, true))
	tween.chain().tween_interval(0.08)
	tween.tween_property(art, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(art, "scale", Vector2(0.44, 0.44), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(host._queue_free_instance_id.bind(art.get_instance_id()))
	_play_fishing_wallet_circle_pop()

func _play_staged_net_collect_to_wallet(art: Control, target: Vector2) -> void:
	if art == null or not is_instance_valid(art):
		return
	var start_position := art.position
	var target_position := target - art.size * 0.5
	var glow := FeatheredCollectGlow.new()
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.size = art.size * 1.38
	glow.position = -art.size * 0.19
	glow.z_index = -1
	art.add_child(glow)
	art.scale = Vector2(0.82, 0.82)
	art.modulate = Color(1.12, 1.08, 0.72, 1.0)
	glow.modulate.a = 0.0
	var tween: Tween = host.create_tween()
	var art_id := art.get_instance_id()
	tween.tween_property(art, "scale", Vector2(1.10, 1.10), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(art, "scale", Vector2.ONE, 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(glow, "modulate:a", 0.78, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(_apply_fishing_net_collect_start_hover_frame.bind(art_id, start_position), 0.0, 1.0, 0.82).set_trans(Tween.TRANS_LINEAR)
	tween.chain().tween_property(glow, "modulate:a", 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(_reset_fishing_net_collect_flyer_visuals.bind(art_id))
	tween.chain().tween_property(art, "position", target_position, 1.05).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(art, "rotation", 0.0, 1.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(host._set_fish_circle_for_skill_bound.bind(host.detail_fish_circle.get_instance_id(), host.selected_skill_id, true))
	tween.chain().tween_method(_apply_fishing_net_collect_target_hover_frame.bind(art_id, target_position), 0.0, 1.0, 1.0).set_trans(Tween.TRANS_LINEAR)
	tween.chain().tween_property(art, "modulate:a", 0.0, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(host._finish_fishing_net_collect)
	tween.chain().tween_callback(host._queue_free_instance_id.bind(art.get_instance_id()))

func _apply_fishing_net_collect_start_hover_frame(value: float, art_id: int, start_position: Vector2) -> void:
	var flyer: Control = host._valid_control_ref(instance_from_id(art_id))
	if flyer == null:
		return
	var bob := sin(value * TAU * 2.0) * 10.0
	var sway := sin(value * TAU * 1.35 + 0.7) * 8.0
	flyer.position = start_position + Vector2(sway, bob)
	flyer.rotation = sin(value * TAU * 1.6) * 0.075

func _apply_fishing_net_collect_target_hover_frame(value: float, art_id: int, target_position: Vector2) -> void:
	var flyer: Control = host._valid_control_ref(instance_from_id(art_id))
	if flyer == null:
		return
	var bob := sin(value * TAU * 2.4) * 8.0
	var sway := sin(value * TAU * 1.55) * 6.0
	flyer.position = target_position + Vector2(sway, bob)
	flyer.rotation = sin(value * TAU * 1.8) * 0.055

func _play_fishing_offer_collected_transition(source: Control, start_delay := 0.10, collapse_after_fade := false) -> void:
	if source == null or not is_instance_valid(source) or source.is_queued_for_deletion():
		return
	source.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if source is BaseButton:
		host._set_base_button_disabled_if_changed(source as BaseButton, true)
	var pop_card := source.get_parent() as Control
	var root := pop_card.get_parent() as Control if pop_card != null and is_instance_valid(pop_card) else null
	if root == null or not is_instance_valid(root) or root.is_queued_for_deletion():
		return
	var track_id := str(root.get_meta("detail_lazy_track_id", ""))
	if not track_id.is_empty() and not collapse_after_fade:
		host._apply_detail_lazy_entry_height(0.0, track_id)
	var start_height := root.custom_minimum_size.y
	var tween: Tween = host.create_tween()
	var root_id := root.get_instance_id()
	if collapse_after_fade:
		tween.tween_property(root, "modulate:a", 0.0, 0.20).set_delay(start_delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween.chain().tween_method(_apply_fishing_offer_collected_height.bind(root_id), start_height, 0.0, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		if not track_id.is_empty():
			tween.parallel().tween_method(host._apply_detail_lazy_entry_height.bind(track_id), start_height, 0.0, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tween.tween_callback(host._hide_control_bound.bind(root_id))
		return
	tween.set_parallel(true)
	tween.tween_property(root, "modulate:a", 0.0, 0.20).set_delay(start_delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(_apply_fishing_offer_collected_height.bind(root_id), start_height, 0.0, 0.24).set_delay(start_delay + 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.chain().tween_callback(host._hide_control_bound.bind(root_id))

func _apply_fishing_offer_collected_height(value: float, root_id: int) -> void:
	var root: Control = host._valid_control_ref(instance_from_id(root_id))
	if root == null or root.is_queued_for_deletion():
		return
	root.custom_minimum_size = Vector2(root.custom_minimum_size.x, value)
	root.size.y = value
	root.update_minimum_size()
	var parent := root.get_parent() as Container
	if parent != null:
		parent.queue_sort()
