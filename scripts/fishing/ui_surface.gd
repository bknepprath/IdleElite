extends RefCounted

const ActivityLockRig = preload("res://scripts/ui/activity_lock_rig.gd")
const ActivityCardBorder = preload("res://scripts/ui/activity_card_border.gd")
const ActivityCardStyles = preload("res://scripts/ui/activity_card_styles.gd")
const ActionArtUi = preload("res://scripts/ui/action_art_ui.gd")
const ButtonPressState = preload("res://scripts/ui/button_press_state.gd")
const FishCircle = preload("res://scripts/ui/fish_circle.gd")
const FishingFluidStripClass = preload("res://scripts/fishing/fluid_strip.gd")
const FishingState = preload("res://scripts/fishing/state.gd")
const MasteryState = preload("res://scripts/progression/mastery_state.gd")
const MobileScrollContainer = preload("res://scripts/ui/mobile_scroll_container.gd")
const ModuleUiRuntime = preload("res://scripts/module_ui/runtime.gd")
const RoundedCornerCropOverlay = preload("res://scripts/ui/rounded_corner_crop_overlay.gd")
const RoundedTextureRect = preload("res://scripts/ui/rounded_texture_rect.gd")
const RewardFeedbackSurface = preload("res://scripts/ui/reward_feedback_surface.gd")
const SkillDetailSurface = preload("res://scripts/ui/skill_detail_surface.gd")
const ActivityUnlockCeremonySurface = preload("res://scripts/ui/activity_unlock_ceremony_surface.gd")

class FeatheredCollectGlow extends Control:
	var glow_color := Color("#ffe872")

	func _draw() -> void:
		var center := size * 0.5
		var base_radius := minf(size.x, size.y) * 0.5
		for i in range(13, 0, -1):
			var t := float(i) / 13.0
			var radius := base_radius * t
			var alpha := pow(1.0 - t, 1.75) * 0.30
			var color := Color(glow_color.r, glow_color.g, glow_color.b, alpha)
			_draw_ellipse(center, Vector2(radius * 1.12, radius * 0.82), color)
		_draw_ellipse(center, Vector2(base_radius * 0.50, base_radius * 0.36), Color(glow_color.r, glow_color.g, glow_color.b, 0.11))

	func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
		var points := PackedVector2Array()
		for i in range(48):
			var angle := TAU * float(i) / 48.0
			points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
		draw_colored_polygon(points, color)

const FISHING_CATCH_POP_SIZE := Vector2(91.5, 91.5)
const FISHING_CATCH_POP_STAGGER_SECONDS := 0.11
const FISHING_CATCH_POP_RISE_PIXELS := 60.0
const FISHING_CATCH_POP_MAX_VISUALS := 9
const FISHING_FLUID_STRIP_HEIGHT := 44.0
const FISHING_FLUID_STRIP_BOTTOM_INSET := 0.0
const FISHING_FLUID_STRIP_Z_INDEX := 205
const FISHING_ACTIVE_TOOL_Z_INDEX := FISHING_FLUID_STRIP_Z_INDEX - 1
const FISHING_COLLECTION_CANVAS_LAYER := 124
const FISHING_AREA_STAT_FADE_SECONDS := 0.22
const FISHING_METHOD_ACTIVE_SWAY_SPEED := 1.18
const FISHING_METHOD_ACTIVE_SWAY_OFFSET := Vector2(2.1, 1.7)
const FISHING_METHOD_ACTIVE_SWAY_ROTATION := 0.026
const FISHING_METHOD_ACTIVE_SWAY_SCALE_PULSE := 0.042
const FISHING_METHOD_ACTIVE_SWAY_RETURN_SECONDS := 0.2
const FISHING_LOCATION_ACTIVE_CAMERA_ZOOM := 2.35
const FISHING_LOCATION_ACTIVE_CAMERA_PAN := Vector2(46.0, 37.0)
const FISHING_LOCATION_ACTIVE_CAMERA_EASE := 1.45
const FISHING_LOCATION_ACTIVE_CAMERA_RETURN_SECONDS := 0.18
const FISHING_MODULE_TITLE_Z_INDEX := 500
const FISHING_METHOD_PADLOCK_SIZE := Vector2(168, 184)
const FISHING_METHOD_PADLOCK_LEVEL_SIZE := Vector2(75, 65)
const FISHING_METHOD_PADLOCK_LEVEL_FONT := 64
const FISHING_METHOD_PADLOCK_LEVEL_OUTLINE := 7
const FISHING_METHOD_TITLE_OUTLINE := 5
const FISHING_MODULE_TITLE_FONT_SIZE := 60
const FISHING_MODULE_TITLE_OUTLINE := 17
const FISHING_MODULE_TITLE_TOP := 9
const FISHING_MODULE_TITLE_BAND_HEIGHT := 53
const FISHING_MODULE_TITLE_LEFT_INSET := 27.0
const FISHING_MODULE_TITLE_RIGHT_INSET := 52.0
const FISHING_EQUIPMENT_OFFER_TITLE_SIDE_INSET := 44.0
const FISHING_AREA_MAX_BUTTONS_PER_MODULE := 2
const FISHING_AREA_CONTENT_TOP_MARGIN := FISHING_MODULE_TITLE_TOP
const FISHING_AREA_WATER_BOTTOM_MARGIN := 35
const FISHING_AREA_STAT_COLUMN_TOP_MARGIN := FISHING_MODULE_TITLE_TOP + FISHING_MODULE_TITLE_BAND_HEIGHT
const FISHING_AREA_METHOD_TOP_MARGIN := 0
const FISHING_ACTIVE_TOOL_VISUAL_LANE_WIDTH := 175.0
const FISHING_ACTIVE_TOOL_LAYER_SIZE := Vector2(410, 215)
const FISHING_ACTIVE_TOOL_LAYER_RIGHT_OFFSET := -235.0
const FISHING_ACTIVE_TOOL_LAYER_TOP := 125.0
const FISHING_ACTIVE_TOOL_ICON_SIZE := Vector2(159.5, 159.5)
const FISHING_ACTIVE_NET_ICON_SIZE := Vector2(218.5, 218.5)
const FISHING_ACTIVE_TOOL_FLOAT_Y := 13.0
const FISHING_ACTIVE_TOOL_DIP_Y := 111.0
const FISHING_ACTIVE_TOOL_HARVEST_Y := 83.0
const FISHING_ACTIVE_TOOL_INIT_SECONDS := 0.46
const FISHING_PADLOCK_UNLOCK_DROP_SECONDS := 0.96
const FISHING_PADLOCK_UNLOCK_POP_SECONDS := 0.30
const FISHING_LOCATION_TILE_SIZE := Vector2(205, 205)
const FISHING_NET_OFFER_HEIGHT := 370
const FISHING_ROD_OFFER_HEIGHT := 370
const FISHING_ROD_UPGRADE_OFFER_HEIGHT := 370
const FISHING_BOAT_OFFER_HEIGHT := 370
const FISHING_MIRROR_OFFER_HEIGHT := 370
const FISHING_OFFER_UNAVAILABLE_ART_MODULATE := Color(1, 1, 1, 0.52)

var host
var fishing_collection_canvas: CanvasLayer
var fishing_tool_wallet_open := false
var fishing_tool_wallet_canvas: CanvasLayer
var fishing_tool_wallet_popup: Control
var fishing_tool_wallet_pop_tween: Tween
var fishing_tool_wallet_last_toggle_msec := 0
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
var fishing_method_button_press_active := false
var fishing_method_button_press_source_id := 0
var fishing_offer_button_press_active := false
var fishing_unlock_visible_mount_ids: Array = []
var fishing_unlock_preview_fade_marker_ids: Array = []
var fishing_detail_render_cull_counts_cache := {"rendered": 0, "culled": 0}
var fishing_detail_visible_culled_count_cache := 0
var fishing_detail_render_signature_cache_key := -1
var fishing_detail_render_signature_cache: Array = []
var fishing_scroll_perf_active := false
var fishing_scroll_perf_start_msec := 0
var fishing_scroll_perf_frames := 0
var fishing_scroll_perf_over_50_frames := 0
var fishing_scroll_perf_max_delta_msec := 0.0
var fishing_scroll_perf_start_scroll := 0.0
var fishing_scroll_perf_last_scroll := 0.0
var fishing_scroll_perf_last_summary := {}
var fishing_scroll_mouse_pick_suspended := false
var fishing_scroll_mode_active := false
var fishing_scroll_mode_release_msec := 0
var fishing_detail_primary_pointer_down := false

func _init(host_ref) -> void:
	host = host_ref


func is_fishing_tool_wallet_open() -> bool:
	return fishing_tool_wallet_open


func reset_wallet_refs_for_shutdown() -> void:
	fishing_tool_wallet_canvas = null
	fishing_tool_wallet_popup = null


func kill_wallet_pop_tween() -> void:
	if fishing_tool_wallet_pop_tween != null and fishing_tool_wallet_pop_tween.is_valid():
		fishing_tool_wallet_pop_tween.kill()
	fishing_tool_wallet_pop_tween = null


func has_active_fishing_method_press() -> bool:
	return fishing_method_button_press_active


func has_active_fishing_offer_press() -> bool:
	return fishing_offer_button_press_active


func has_active_fishing_button_press() -> bool:
	return fishing_method_button_press_active or fishing_offer_button_press_active


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


func _fishing_fluid_kind_for_action(action: Dictionary) -> String:
	var action_id := str(action.get("id", ""))
	if str(action.get("area", "")) == "space" or action_id.begins_with("space-"):
		return "space"
	if str(action.get("area", "")) == "winter_lake":
		return "ice"
	if str(action.get("area", "")) == "deep_sea":
		return "deep_water"
	if str(action.get("area", "")) == "stormy_sea":
		return "storm"
	if action_id in ["drain-gate", "tunnel-pool"]:
		return "sewer"
	if action_id.contains("chum") or action_id.contains("leviathan") or action_id.contains("lobster"):
		return "lava"
	return "water"


func _attach_fishing_fluid_strip(parent: Control, action: Dictionary) -> Control:
	if _fishing_ablation_enabled("no_fluid"):
		var spacer := Control.new()
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spacer.z_index = 1
		parent.add_child(spacer)
		return spacer
	var fluid: Control = FishingFluidStripClass.new()
	fluid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fluid.z_index = 1
	fluid.set_fluid_kind(_fishing_fluid_kind_for_action(action))
	parent.add_child(fluid)
	return fluid


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


func _fishing_tool_def(tool_id: String) -> Dictionary:
	for raw_tool in FishingState.FISHING_TOOL_DEFS:
		var tool := raw_tool as Dictionary
		if str(tool.get("id", "")) == tool_id:
			return tool
	return FishingState.FISHING_TOOL_DEFS[0] as Dictionary


func _fishing_tool_label(tool_id: String) -> String:
	return str(_fishing_tool_def(tool_id).get("name", tool_id.capitalize()))


func _fishing_visible_wallet_tool_defs() -> Array:
	var visible_wallet_tools: Array = []
	var rod_slot_id: String = host.fishing_runtime.visible_rod_slot_id()
	for raw_tool in FishingState.FISHING_TOOL_DEFS:
		var tool := raw_tool as Dictionary
		var tool_id := str(tool.get("id", ""))
		if tool_id in ["line", "reinforced_rod", "star_rod"] and tool_id != rod_slot_id:
			continue
		visible_wallet_tools.append(tool)
	return visible_wallet_tools


func _fishing_tool_icon_texture(tool_id_or_path: String) -> Texture2D:
	match tool_id_or_path:
		"hands":
			return host.visual_texture_cache._texture_or_visual_fallback("res://assets/content/fishing/tools/tool-bare-hands.png")
		"bamboo-rod":
			return host.visual_texture_cache._texture_or_visual_fallback("res://assets/content/fishing/tools/tool-bamboo-rod.png")
		"line":
			return _fishing_tool_icon_texture("bamboo-rod")
		"reinforced_rod", "star_rod":
			return _fishing_tool_icon_texture("bamboo-rod")
		"net":
			return host.visual_texture_cache._texture_or_visual_fallback("res://assets/content/fishing/tools/net-player.png")
		"boat":
			return host.visual_texture_cache._texture_or_visual_fallback("res://assets/content/fishing/tools/tool-boat.png")
		"mirror":
			return host.visual_texture_cache._texture_or_visual_fallback("res://assets/content/fishing/tools/reflection-net.png")
		"tool:hands":
			return _fishing_tool_icon_texture("hands")
		"tool:bamboo-rod":
			return _fishing_tool_icon_texture("bamboo-rod")
		_:
			for raw_tool in FishingState.FISHING_TOOL_DEFS:
				var tool := raw_tool as Dictionary
				if str(tool.get("art", "")) == tool_id_or_path:
					return _fishing_tool_icon_texture(str(tool.get("id", "")))
			return host.visual_texture_cache._texture_or_visual_fallback(tool_id_or_path)


func _fishing_location_thumbnail_path(area_id: String, location_id: String) -> String:
	match host.fishing_runtime.location_key(area_id, location_id):
		"beach.shallows":
			return "res://assets/content/fishing/locations/location-shallows.png"
		"beach.rocky":
			return "res://assets/content/fishing/locations/location-rocky-ledge.png"
		"pier.dock-cup":
			return "res://assets/content/fishing/locations/location-dock-cup.png"
		"pier.piling-line":
			return "res://assets/content/fishing/locations/location-piling-line.png"
		"river.bend":
			return "res://assets/content/fishing/locations/river-bend.png"
		"river.rapids":
			return "res://assets/content/fishing/locations/river-rapids.png"
		"sewers.drain-gate":
			return "res://assets/content/fishing/locations/sewers-drain-gate.png"
		"sewers.tunnel-pool":
			return "res://assets/content/fishing/locations/sewers-tunnel-pool.png"
		"winter_lake.ice-hole":
			return "res://assets/content/fishing/locations/winter-lake-ice-hole.png"
		"reef.pot":
			return "res://assets/content/fishing/locations/reef-pot.png"
		"reef.cage":
			return "res://assets/content/fishing/locations/reef-cage.png"
		"reef.night-reef":
			return "res://assets/content/fishing/locations/reef-night-reef.png"
		"reef.pearl-bed":
			return "res://assets/content/fishing/locations/reef-pearl-bed.png"
		"sea.rowboat":
			return "res://assets/content/fishing/locations/sea-rowboat.png"
		"sea.open-water":
			return "res://assets/content/fishing/locations/sea-open-water.png"
		"sea.chum-line":
			return "res://assets/content/fishing/locations/sea-chum-line.png"
		"stormy_sea.ripple":
			return "res://assets/content/fishing/locations/stormy-sea-ripple.png"
		"stormy_sea.storm-line":
			return "res://assets/content/fishing/locations/stormy-sea-storm-line.png"
		"deep_sea.wreck-drop":
			return "res://assets/content/fishing/locations/deep-sea-wreck-drop.png"
		"deep_sea.abyss":
			return "res://assets/content/fishing/locations/deep-sea-abyss.png"
		"deep_sea.trench":
			return "res://assets/content/fishing/locations/deep-sea-trench.png"
		"space.starlight":
			return "res://assets/content/fishing/locations/space-starlight.png"
		"space.reflection":
			return "res://assets/content/fishing/locations/space-reflection.png"
	return "res://assets/content/fishing/locations/location-shallows.png"


func _fishing_location_thumbnail_texture(area_id: String, location_id: String) -> Texture2D:
	return host.visual_texture_cache._texture_or_visual_fallback(_fishing_location_thumbnail_path(area_id, location_id))


func _player_facing_action_art_path(skill_id: String, action: Dictionary) -> String:
	if skill_id == "fishing":
		return host.fishing_runtime.indexed_action_art_path(action, FishingState.FISHING_TOOL_LOCATION_ACTIONS, Callable(self, "_fishing_location_thumbnail_path"))
	return str(action.get("art", ""))


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
	button.custom_minimum_size = Vector2(99, 99)
	button.size = Vector2(99, 99)
	button.position = Vector2(-33, -30)
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
	return host.fishing_runtime.fish_currency_ever_earned or host.fishing_runtime.fish_currency >= 1.0


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
	var icon_size := Vector2(100.5, 100.5)
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
		var fill: Color = ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE) if host.fishing_runtime.auto_eat_fish_enabled_for_skill(host, skill_id) else Color("#77726d", 0.35)
		var material := fish.material as ShaderMaterial
		if material != null:
			material.set_shader_parameter("fill_color", fill)
		fish.modulate = Color.WHITE


func _sync_auto_eat_fish_toggle_buttons() -> void:
	for node in host.get_tree().get_nodes_in_group("auto_eat_fish_toggle"):
		_sync_auto_eat_fish_toggle_button(node as TextureButton)


func _on_auto_eat_fish_toggle_pressed(skill_id: String) -> void:
	host._action_runtime()._cancel_pending_stamina_gauge_click()
	host.fishing_runtime.set_auto_eat_fish_enabled_for_skill(host, skill_id, not host.fishing_runtime.auto_eat_fish_enabled_for_skill(host, skill_id))
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
		host._app_lifecycle_runtime()._kill_meta_tween(button, "auto_eat_pop_tween")
		button.pivot_offset = button.size * 0.5
		button.scale = Vector2(1.0, 1.0)
		var tween: Tween = host.create_tween()
		button.set_meta("auto_eat_pop_tween", tween)
		tween.tween_property(button, "scale", Vector2(1.15, 1.15), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "scale", Vector2.ONE, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.finished.connect(host._app_lifecycle_runtime()._remove_meta_from_instance_id.bind(button.get_instance_id(), "auto_eat_pop_tween"))


func _web_fishing_perf_probe_mounted_count() -> int:
	var mounted_count := 0
	for raw_entry in host._skill_detail_surface().detail_lazy_plan:
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
	if host.current_screen != "skill" or host._skill_detail_surface().detail_actions_scroll == null or not is_instance_valid(host._skill_detail_surface().detail_actions_scroll):
		return
	if not host._skill_detail_surface().detail_actions_scroll.visible or not host._skill_detail_surface().detail_actions_scroll.is_visible_in_tree():
		return
	var delta_y := float(args[0]) if args.size() > 0 else 0.0
	var delta_mode := int(args[1]) if args.size() > 1 else 0
	if delta_mode == 1:
		delta_y *= 48.0
	elif delta_mode == 2:
		delta_y *= host._skill_detail_surface()._detail_lazy_viewport_height()
	host._skill_detail_surface().detail_actions_scroll.apply_direct_wheel_delta(delta_y)
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
	await host._navigation_shell()._render_screen(false, -1, false)
	for _frame in range(90):
		await host.get_tree().process_frame
	host._skill_detail_surface()._detail_lazy_mount_initial_window_sync(true, 999)
	host._sync_detail_actions_scroll_limit()
	for _frame in range(180):
		if host._skill_detail_surface().detail_card_texture_prewarm_idle():
			break
		await host.get_tree().process_frame
	for _frame in range(45):
		await host.get_tree().process_frame
	if host._skill_detail_surface().detail_actions_scroll != null and is_instance_valid(host._skill_detail_surface().detail_actions_scroll):
		var start_scroll := mini(120, host._skill_detail_surface().detail_actions_scroll.get_max_scroll_vertical())
		host._skill_detail_surface().detail_actions_scroll.scroll_vertical = start_scroll
		host._skill_detail_surface().detail_actions_scroll.drag_scroll_position = float(start_scroll)
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
	if host._skill_detail_surface().detail_actions_scroll != null and is_instance_valid(host._skill_detail_surface().detail_actions_scroll):
		scroll_y = int(host._skill_detail_surface().detail_actions_scroll.scroll_vertical)
		max_scroll = host._skill_detail_surface().detail_actions_scroll.get_max_scroll_vertical()
		drag_active = host._skill_detail_surface().detail_actions_scroll.drag_scrolling
		scroll_velocity = host._skill_detail_surface().detail_actions_scroll.velocity
	var mounted_count := _web_fishing_perf_probe_mounted_count()
	if not force and scroll_y == web_fishing_perf_probe_last_scroll and mounted_count == web_fishing_perf_probe_last_mounted:
		return
	var visible_placeholders := false
	if host.current_screen == "skill" and (not web_fishing_perf_probe_ready or mounted_count < host._skill_detail_surface().detail_lazy_plan.size()):
		visible_placeholders = host._skill_swipe_activity_surface()._skill_detail_has_visible_lazy_placeholders()
	var active_scroll_perf := {}
	if fishing_scroll_perf_active:
		active_scroll_perf = {
			"durationMsec": maxi(0, Time.get_ticks_msec() - fishing_scroll_perf_start_msec),
			"frames": fishing_scroll_perf_frames,
			"maxFrameMsec": fishing_scroll_perf_max_delta_msec,
			"over50": fishing_scroll_perf_over_50_frames,
			"scrollDelta": fishing_scroll_perf_last_scroll - fishing_scroll_perf_start_scroll
		}
	var publish_culling_detail: bool = force or not fishing_scroll_perf_active
	var render_cull_state: Dictionary = _fishing_detail_render_cull_counts() if publish_culling_detail else {}
	var visible_culled_state: int = _fishing_detail_visible_culled_count() if publish_culling_detail else 0
	var texture_prewarm_counts: Dictionary = host._skill_detail_surface().detail_card_texture_prewarm_counts()
	var state := {
		"ready": web_fishing_perf_probe_ready,
		"screen": host.current_screen,
		"skill": host.selected_skill_id,
		"scroll": scroll_y,
		"maxScroll": max_scroll,
		"mounted": mounted_count,
		"plan": host._skill_detail_surface().detail_lazy_plan.size(),
		"cards": host.action_cards.size(),
		"renderCull": render_cull_state,
		"visibleCulled": visible_culled_state,
		"visiblePlaceholders": visible_placeholders,
		"texturePrewarmQueue": texture_prewarm_counts.get("queue", 0),
		"texturePrewarmPending": texture_prewarm_counts.get("pending", 0),
		"drag": drag_active,
		"velocity": scroll_velocity,
		"scrollPerfActive": active_scroll_perf,
		"scrollPerfLast": fishing_scroll_perf_last_summary,
		"godotMsec": Time.get_ticks_msec(),
		"frame": Engine.get_process_frames()
	}
	web_fishing_perf_probe_last_scroll = scroll_y
	web_fishing_perf_probe_last_mounted = mounted_count
	JavaScriptBridge.eval("window.__idleEliteFishingPerf = %s;" % JSON.stringify(state), false)
	web_fishing_perf_probe_last_publish_msec = Time.get_ticks_msec()


func _add_fishing_boot_warmup_texture_paths(paths: Array) -> void:
	var boot_warmup = host._boot_warmup_runtime()
	for tool in FishingState.FISHING_TOOL_DEFS:
		boot_warmup._add_boot_warmup_texture_path(paths, str((tool as Dictionary).get("art", "")))
	_add_fishing_detail_visual_texture_paths(paths)


func _add_fishing_detail_visual_texture_paths(paths: Array) -> void:
	var boot_warmup = host._boot_warmup_runtime()
	boot_warmup._add_boot_warmup_texture_path(paths, FishCircle.FISH_CURRENCY_ICON_TEXTURE)
	boot_warmup._add_boot_warmup_texture_path(paths, FishingState.FISHING_LOCATION_THUMBNAIL_SHEET)
	for raw_area in host.fishing_runtime.area_definitions:
		var area_def := raw_area as Dictionary
		var area_bg_path := str(area_def.get("bg", ""))
		if str(area_def.get("id", "")) == "beach" and ResourceLoader.exists("res://assets/content/fishing/backgrounds/beach-rocky-zoom.png"):
			area_bg_path = "res://assets/content/fishing/backgrounds/beach-rocky-zoom.png"
		boot_warmup._add_boot_warmup_texture_path(paths, area_bg_path)
		var area_id := str(area_def.get("id", ""))
		if host.fishing_runtime.area_uses_location_tiles(area_def, FishingState.FISHING_LOCATION_DEFS):
			for raw_location in host.fishing_runtime.locations_for_area(area_id, FishingState.FISHING_LOCATION_DEFS):
				var location := raw_location as Dictionary
				boot_warmup._add_boot_warmup_texture_path(paths, _fishing_location_thumbnail_path(area_id, str(location.get("id", ""))))
	for raw_tool in FishingState.FISHING_TOOL_DEFS:
		var tool := raw_tool as Dictionary
		boot_warmup._add_boot_warmup_texture_path(paths, str(tool.get("art", "")))
	for raw_catch_path in FishingState.FISHING_ACTION_CATCH_TEXTURE_PATHS.values():
		boot_warmup._add_boot_warmup_texture_path(paths, str(raw_catch_path))


func _process_fishing_scroll_perf_probe(delta: float, scroll_active: bool) -> void:
	if not OS.is_debug_build() and not host.web_fishing_perf_probe_enabled:
		return
	if host.current_screen != "skill" or not host._fishing_rework_active_for_skill(host.selected_skill_id):
		if fishing_scroll_perf_active:
			_finish_fishing_scroll_perf_probe("left_page")
		return
	var scroll := host._app_lifecycle_runtime().valid_control_ref(host._skill_detail_surface().detail_actions_scroll) as MobileScrollContainer
	if scroll == null:
		if fishing_scroll_perf_active:
			_finish_fishing_scroll_perf_probe("missing_scroll")
		return
	var active := scroll_active or scroll.drag_scrolling or absf(scroll.velocity) >= 4.0
	if not active:
		if fishing_scroll_perf_active:
			_finish_fishing_scroll_perf_probe("settled")
		return
	var scroll_y := float(scroll.scroll_vertical)
	if not fishing_scroll_perf_active:
		fishing_scroll_perf_active = true
		fishing_scroll_perf_start_msec = Time.get_ticks_msec()
		fishing_scroll_perf_frames = 0
		fishing_scroll_perf_over_50_frames = 0
		fishing_scroll_perf_max_delta_msec = 0.0
		fishing_scroll_perf_start_scroll = scroll_y
	fishing_scroll_perf_last_scroll = scroll_y
	fishing_scroll_perf_frames += 1
	var frame_msec := maxf(0.0, delta * 1000.0)
	fishing_scroll_perf_max_delta_msec = maxf(fishing_scroll_perf_max_delta_msec, frame_msec)
	if frame_msec > 50.0:
		fishing_scroll_perf_over_50_frames += 1
	if host.web_fishing_perf_probe_enabled:
		_publish_web_fishing_perf_probe_state()


func _sync_fishing_detail_visible_viewport_cards(max_mounts: int = -1) -> int:
	if host.current_screen != "skill" or not host._fishing_rework_active_for_skill(host.selected_skill_id):
		return 0
	if host._skill_detail_surface().detail_lazy_plan.is_empty() or host._app_lifecycle_runtime().valid_control_ref(host._skill_detail_surface().detail_lazy_stack) == null or host._app_lifecycle_runtime().valid_control_ref(host._skill_detail_surface().detail_actions_scroll) == null:
		return 0
	var content_width: float = host._skill_content_width()
	var actions_width: float = content_width
	var mounted_count := 0
	var previous_mount_context: String = host._skill_detail_surface().detail_lazy_mount_trace_context
	host._skill_detail_surface().detail_lazy_mount_trace_context = "visible_viewport_fill"
	for raw_lazy_entry in host._skill_detail_surface().detail_lazy_plan:
		if max_mounts >= 0 and mounted_count >= max_mounts:
			break
		var lazy_entry := raw_lazy_entry as Dictionary
		if bool(lazy_entry.get("mounted", false)):
			continue
		if not host._skill_detail_surface()._detail_lazy_entry_in_visible_viewport(lazy_entry):
			continue
		if host._skill_detail_surface()._detail_lazy_mount_item(lazy_entry, host.selected_skill_id, content_width, actions_width, false):
			mounted_count += 1
	host._skill_detail_surface().detail_lazy_mount_trace_context = previous_mount_context
	if mounted_count > 0:
		host._skill_detail_surface().detail_lazy_mounted_this_frame = true
	return mounted_count


func _finish_fishing_scroll_perf_probe(reason: String) -> void:
	if host.current_screen == "skill" and host._fishing_rework_active_for_skill(host.selected_skill_id):
		_sync_fishing_detail_visible_viewport_cards(host.FISHING_DETAIL_VISIBLE_SETTLE_FILL_BUDGET)
		_sync_fishing_detail_render_culling(true)
	var duration_msec := maxi(0, Time.get_ticks_msec() - fishing_scroll_perf_start_msec)
	var scroll_delta: float = fishing_scroll_perf_last_scroll - fishing_scroll_perf_start_scroll
	var render_counts: Dictionary = _fishing_detail_render_cull_counts()
	fishing_scroll_perf_last_summary = {
		"reason": reason,
		"durationMsec": duration_msec,
		"frames": fishing_scroll_perf_frames,
		"maxFrameMsec": fishing_scroll_perf_max_delta_msec,
		"over50": fishing_scroll_perf_over_50_frames,
		"scrollDelta": scroll_delta,
		"mounted": _web_fishing_perf_probe_mounted_count(),
		"rendered": int(render_counts.get("rendered", 0)),
		"culled": int(render_counts.get("culled", 0)),
		"cards": host.action_cards.size()
	}
	print("FISHING_SCROLL_PERF reason=%s duration_ms=%s frames=%s max_frame_ms=%.2f over50=%s scroll_delta=%.1f mounted=%s rendered=%s culled=%s cards=%s" % [
		reason,
		str(duration_msec),
		str(fishing_scroll_perf_frames),
		fishing_scroll_perf_max_delta_msec,
		str(fishing_scroll_perf_over_50_frames),
		scroll_delta,
		str(_web_fishing_perf_probe_mounted_count()),
		str(int(render_counts.get("rendered", 0))),
		str(int(render_counts.get("culled", 0))),
		str(host.action_cards.size())
	])
	fishing_scroll_perf_active = false
	fishing_scroll_perf_start_msec = 0
	fishing_scroll_perf_frames = 0
	fishing_scroll_perf_over_50_frames = 0
	fishing_scroll_perf_max_delta_msec = 0.0
	fishing_scroll_perf_start_scroll = 0.0
	fishing_scroll_perf_last_scroll = 0.0
	if host.web_fishing_perf_probe_enabled:
		_publish_web_fishing_perf_probe_state(true)


func _process_fishing_scroll_mode(scroll_visual_work: bool) -> void:
	if host.current_screen != "skill" or not host._fishing_rework_active_for_skill(host.selected_skill_id):
		_set_fishing_scroll_mode_active(false)
		return
	var scroll := host._app_lifecycle_runtime().valid_control_ref(host._skill_detail_surface().detail_actions_scroll) as MobileScrollContainer
	if scroll == null:
		_set_fishing_scroll_mode_active(false)
		return
	var confirmed_scroll := scroll.drag_scrolling or absf(scroll.velocity) >= 4.0
	if confirmed_scroll:
		fishing_scroll_mode_release_msec = Time.get_ticks_msec() + host.FISHING_SCROLL_MODE_SETTLE_MSEC
		_set_fishing_scroll_mode_active(true)
		return
	if fishing_scroll_mode_active:
		var still_settling: bool = scroll_visual_work and Time.get_ticks_msec() <= fishing_scroll_mode_release_msec
		_set_fishing_scroll_mode_active(still_settling)


func _fishing_detail_scroll_is_actively_moving() -> bool:
	if host.current_screen != "skill" or not host._fishing_rework_active_for_skill(host.selected_skill_id):
		return false
	var scroll := host._app_lifecycle_runtime().valid_control_ref(host._skill_detail_surface().detail_actions_scroll) as MobileScrollContainer
	if scroll == null:
		return false
	return (
		fishing_detail_primary_pointer_down
		or scroll.drag_tracking
		or scroll.drag_scrolling
		or absf(scroll.velocity) >= 4.0
		or fishing_scroll_mode_active
	)


func _fishing_detail_scroll_frame_can_skip_ui_update() -> bool:
	if host.current_screen != "skill" or host.selected_skill_id != "fishing":
		return false
	if not host._skill_detail_surface().detail_scroll_visual_work_this_frame:
		return false
	if host.running_skill_id == host.selected_skill_id and not host.running_action_id.is_empty():
		return false
	var temporary_events = host._temporary_event_runtime()
	if temporary_events.event_running_skill_id == host.selected_skill_id and not temporary_events.event_running_action_id.is_empty():
		return false
	if host._skill_swipe_activity_surface().skill_swipe_tracking or host._skill_swipe_activity_surface().skill_swipe_animating:
		return false
	if host._action_stop_hold().active() or not host._skill_detail_surface().action_card_press_key.is_empty():
		return false
	if host._tutorial_overlay_surface().activity_start_highlight_active or host._tutorial_overlay_surface().activity_start_highlight_pending:
		return false
	if host._activity_unlock_ceremony_surface().locked_preview_fade_play_pending:
		return false
	if host._activity_unlock_runtime().has_pending_readiness_for_skill(host.selected_skill_id) or host._activity_unlock_ceremony_surface().ceremony_count > 0:
		return false
	if host._performance_runtime()._skill_detail_has_fishing_camera_returning():
		return false
	if host._skill_swipe_activity_surface()._skill_swipe_previews_need_frame_updates():
		return false
	return true


func _fishing_detail_should_defer_action_process_for_scroll() -> bool:
	if host.current_screen != "skill" or host.selected_skill_id != "fishing":
		fishing_detail_primary_pointer_down = false
		return false
	if host.running_skill_id != "fishing" and host._temporary_event_runtime().event_running_skill_id != "fishing":
		return false
	var scroll := host._app_lifecycle_runtime().valid_control_ref(host._skill_detail_surface().detail_actions_scroll) as MobileScrollContainer
	if scroll == null:
		return false
	return fishing_detail_primary_pointer_down or fishing_scroll_mode_active or scroll.drag_tracking or scroll.drag_scrolling


func _fishing_detail_can_defer_scroll_bounds_work(detail_lazy_mounted_count: int) -> bool:
	if host.current_screen != "skill" or host.selected_skill_id != "fishing":
		return false
	if not host._skill_detail_surface().detail_scroll_visual_work_this_frame:
		return false
	if detail_lazy_mounted_count > 0 or host._skill_detail_surface().detail_lazy_mounted_this_frame:
		return false
	if host._skill_detail_surface().detail_actions_scroll == null or not is_instance_valid(host._skill_detail_surface().detail_actions_scroll):
		return false
	if host.boot_detail_scroll_locked or host._activity_unlock_ceremony_surface().ceremony_count > 0:
		return false
	if not host._skill_detail_surface().detail_unlock_scroll_spacer_heights.is_empty():
		return false
	if host._activity_unlock_ceremony_surface().visual_scroll_tween != null and host._activity_unlock_ceremony_surface().visual_scroll_tween.is_valid():
		return false
	if host._skill_detail_surface().detail_unlock_scroll_spacer_tween != null and host._skill_detail_surface().detail_unlock_scroll_spacer_tween.is_valid():
		return false
	return true


func _fishing_detail_can_defer_scroll_tail_work() -> bool:
	if host.current_screen != "skill" or host.selected_skill_id != "fishing":
		return false
	if not host._skill_detail_surface().detail_scroll_visual_work_this_frame:
		return false
	if host._skill_swipe_activity_surface().skill_swipe_tracking or host._skill_swipe_activity_surface().skill_swipe_animating:
		return false
	if host._skill_detail_surface().detail_lazy_plan.is_empty():
		return false
	if host._activity_unlock_ceremony_surface().ceremony_count > 0 or host.boot_detail_render_in_progress:
		return false
	if host._skill_detail_surface()._detail_jump_arrows_need_processing():
		return false
	return true


func _set_fishing_scroll_mode_active(active: bool) -> void:
	if fishing_scroll_mode_active == active:
		return
	var was_active: bool = fishing_scroll_mode_active
	fishing_scroll_mode_active = active
	_sync_fishing_scroll_mouse_pick_suspension(active)
	if was_active and not active and host.current_screen == "skill" and host._fishing_rework_active_for_skill(host.selected_skill_id):
		_sync_fishing_detail_visible_viewport_cards(host.FISHING_DETAIL_VISIBLE_SETTLE_FILL_BUDGET)
		_sync_fishing_detail_render_culling(true)


func _maybe_end_fishing_scroll_mode_for_new_press(event: InputEvent) -> void:
	if not fishing_scroll_mode_active:
		return
	if host.current_screen != "skill" or not host._fishing_rework_active_for_skill(host.selected_skill_id):
		_set_fishing_scroll_mode_active(false)
		return
	if not host._input_routing_shell()._is_primary_press_event(event):
		return
	var event_position: Vector2 = host._input_routing_shell()._fishing_detail_event_position(event)
	if event_position == Vector2.INF:
		return
	if host._input_routing_shell()._position_inside_bottom_interactive_ui(event_position) or not host._input_routing_shell()._position_inside_detail_actions_viewport(event_position):
		return
	var active_scroll: MobileScrollContainer = host._skill_detail_surface()._active_action_scroll_container()
	if active_scroll != null and is_instance_valid(active_scroll):
		active_scroll.prepare_child_tap()
	_set_fishing_scroll_mode_active(false)


func _fishing_detail_render_cull_counts() -> Dictionary:
	return fishing_detail_render_cull_counts_cache


func _fishing_detail_visible_culled_count() -> int:
	return fishing_detail_visible_culled_count_cache


func _reset_fishing_detail_render_cull_cache() -> void:
	fishing_detail_render_cull_counts_cache = {"rendered": 0, "culled": 0}
	fishing_detail_visible_culled_count_cache = 0


func _sync_fishing_scroll_mouse_pick_suspension(active: bool) -> void:
	if host.current_screen != "skill" or not host._fishing_rework_active_for_skill(host.selected_skill_id):
		active = false
	fishing_scroll_mouse_pick_suspended = active


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
	if host._skill_detail_surface().detail_lazy_plan.is_empty() or host._skill_detail_surface().detail_actions_scroll == null or not is_instance_valid(host._skill_detail_surface().detail_actions_scroll):
		_reset_fishing_detail_render_cull_cache()
		return
	if host._skill_detail_surface()._detail_lazy_all_mounted():
		_restore_fishing_detail_render_culling()
		_reset_fishing_detail_render_cull_cache()
		return
	var scroll_y: float = host._skill_detail_surface()._detail_lazy_scroll_y()
	if not force:
		var cull_scroll_step: float = host.FISHING_DETAIL_RENDER_CULL_ACTIVE_STEP_PX if host._skill_detail_surface().detail_scroll_visual_work_this_frame else 24.0
		var cull_min_msec: int = host.FISHING_DETAIL_RENDER_CULL_ACTIVE_MIN_MSEC if host._skill_detail_surface().detail_scroll_visual_work_this_frame else 0
		var cull_elapsed_msec: int = Time.get_ticks_msec() - host._skill_detail_surface().detail_lazy_render_cull_last_msec
		if absf(scroll_y - host._skill_detail_surface().detail_lazy_render_cull_last_scroll) < cull_scroll_step:
			return
		if cull_min_msec > 0 and cull_elapsed_msec < cull_min_msec:
			return
	host._skill_detail_surface().detail_lazy_render_cull_last_scroll = scroll_y
	host._skill_detail_surface().detail_lazy_render_cull_last_msec = Time.get_ticks_msec()
	var viewport_height: float = host._skill_detail_surface()._detail_lazy_viewport_height()
	var viewport_top: float = scroll_y
	var viewport_bottom: float = scroll_y + viewport_height
	var reveal_top: float = scroll_y - host.FISHING_DETAIL_RENDER_REVEAL_BUFFER_PX
	var reveal_bottom: float = scroll_y + viewport_height + host.FISHING_DETAIL_RENDER_REVEAL_BUFFER_PX
	var hide_top: float = scroll_y - host.FISHING_DETAIL_RENDER_HIDE_BUFFER_PX
	var hide_bottom: float = scroll_y + viewport_height + host.FISHING_DETAIL_RENDER_HIDE_BUFFER_PX
	var rendered_count := 0
	var culled_count := 0
	var visible_culled_count := 0
	for raw_lazy_entry in host._skill_detail_surface().detail_lazy_plan:
		var lazy_entry := raw_lazy_entry as Dictionary
		if not bool(lazy_entry.get("mounted", false)):
			continue
		var kind := str(lazy_entry.get("kind", ""))
		if kind not in ["action", "passive", "fishing_area", "fishing_offer"]:
			continue
		var stack_host: Control = host._app_lifecycle_runtime().valid_control_ref(lazy_entry.get("stack_host"))
		if stack_host == null:
			continue
		var content_root: Control = host._skill_detail_surface()._detail_lazy_primary_child_control(stack_host)
		if content_root == null or content_root == stack_host:
			continue
		var entry_top: float = float(lazy_entry.get("y", 0.0)) + host._skill_detail_surface()._detail_actions_top_spacer_height()
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
	fishing_detail_render_cull_counts_cache = {"rendered": rendered_count, "culled": culled_count}
	fishing_detail_visible_culled_count_cache = visible_culled_count


func _restore_fishing_detail_render_culling() -> void:
	if host._skill_detail_surface().detail_lazy_plan.is_empty():
		_reset_fishing_detail_render_cull_cache()
		return
	if host._skill_detail_surface().detail_lazy_render_cull_last_scroll <= -999998.0:
		return
	host._skill_detail_surface().detail_lazy_render_cull_last_scroll = -999999.0
	host._skill_detail_surface().detail_lazy_render_cull_last_msec = 0
	for raw_lazy_entry in host._skill_detail_surface().detail_lazy_plan:
		var lazy_entry := raw_lazy_entry as Dictionary
		var stack_host: Control = host._app_lifecycle_runtime().valid_control_ref(lazy_entry.get("stack_host"))
		if stack_host == null:
			continue
		var content_root: Control = host._skill_detail_surface()._detail_lazy_primary_child_control(stack_host)
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
	if host._skill_detail_surface().detail_fish_circle == null or not is_instance_valid(host._skill_detail_surface().detail_fish_circle):
		return
	_clear_fishing_tool_circle_menu()
	fishing_tool_wallet_open = true
	var visible_wallet_tools = _fishing_visible_wallet_tool_defs()
	var row_count = visible_wallet_tools.size()
	if row_count <= 0:
		return
	var circle_rect = host._skill_detail_surface().detail_fish_circle.get_global_rect()
	var gear_button_size = clampf(minf(circle_rect.size.x, circle_rect.size.y) * 0.60, 120.0, 168.0)
	if gear_button_size <= 0.0:
		gear_button_size = 148.0
	var column_count = mini(3, row_count)
	var grid_rows = int(ceil(float(row_count) / float(column_count)))
	var gear_gap = maxf(12.0, gear_button_size * 0.08)
	var panel_padding = maxf(15.0, gear_button_size * 0.10)
	var panel_width = panel_padding * 2.0 + float(column_count) * gear_button_size + float(maxi(0, column_count - 1)) * gear_gap
	var panel_height = panel_padding * 2.0 + float(grid_rows) * gear_button_size + float(maxi(0, grid_rows - 1)) * gear_gap
	var viewport_size = host.get_viewport_rect().size
	var panel_left = clampf(circle_rect.get_center().x - panel_width * 0.5, 6.0, maxf(6.0, viewport_size.x - panel_width - 6.0))
	var panel_top = circle_rect.end.y + maxf(7.0, gear_button_size * 0.08)
	if panel_top + panel_height > viewport_size.y - 6.0:
		panel_top = maxf(6.0, viewport_size.y - panel_height - 6.0)
	var canvas = CanvasLayer.new()
	canvas.name = "FishingToolWalletCanvas"
	canvas.layer = 120
	host.add_child(canvas)
	fishing_tool_wallet_canvas = canvas
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
	fishing_tool_wallet_popup = popup
	var column = Control.new()
	column.position = Vector2(panel_padding, panel_padding)
	column.size = Vector2(panel_width - panel_padding * 2.0, panel_height - panel_padding * 2.0)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup.add_child(column)
	for index in range(visible_wallet_tools.size()):
		var tool = visible_wallet_tools[index] as Dictionary
		var tool_id = str(tool.get("id", ""))
		var unlocked = host.fishing_runtime.tool_is_unlocked(tool_id)
		var equipped = tool_id == host.fishing_runtime.equipped_tool_id
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
		button.pressed.connect(_on_fishing_tool_selected.bind(tool_id))
		column.add_child(button)
		var icon_size = Vector2(gear_button_size * 0.66, gear_button_size * 0.66)
		var icon = host.visual_texture_cache._image_from_texture(_fishing_tool_icon_texture(tool_id), icon_size, str(tool.get("art", "")))
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
	fishing_tool_wallet_open = false
	if fishing_tool_wallet_popup != null and is_instance_valid(fishing_tool_wallet_popup):
		fishing_tool_wallet_popup.queue_free()
	if fishing_tool_wallet_canvas != null and is_instance_valid(fishing_tool_wallet_canvas):
		fishing_tool_wallet_canvas.queue_free()
	fishing_tool_wallet_canvas = null
	fishing_tool_wallet_popup = null
	if host._skill_detail_surface().detail_fish_circle != null and is_instance_valid(host._skill_detail_surface().detail_fish_circle):
		host._skill_detail_surface().detail_fish_circle.set_wallet_open_visual(false)
		host._skill_detail_surface().detail_fish_circle.wallet_button_rects.clear()
		if host._skill_detail_surface().detail_fish_circle.wallet_visual_root != null and is_instance_valid(host._skill_detail_surface().detail_fish_circle.wallet_visual_root):
			host._skill_detail_surface().detail_fish_circle.wallet_visual_root.queue_free()
			host._skill_detail_surface().detail_fish_circle.wallet_visual_root = null


func _set_fishing_tool_wallet_open(open: bool) -> void:
	if not host._fishing_rework_active_for_skill(host.selected_skill_id):
		open = false
	if fishing_tool_wallet_open == open and (not open or (fishing_tool_wallet_popup != null and is_instance_valid(fishing_tool_wallet_popup))):
		return
	var now_msec := Time.get_ticks_msec()
	if fishing_tool_wallet_last_toggle_msec > 0 and now_msec - fishing_tool_wallet_last_toggle_msec < 180:
		return
	fishing_tool_wallet_last_toggle_msec = now_msec
	_play_fishing_wallet_circle_pop()
	if open:
		host._audio_director()._play_chain_impact_cluster(2, 0.34, "drag_start", 1.0)
		host._audio_director()._play_chain_jingle_mix(1, 0.16, 0.34, 0.16)
	fishing_tool_wallet_open = open
	if open:
		_render_fishing_tool_popup_menu()
	else:
		_clear_fishing_tool_circle_menu()
	if host._skill_detail_surface().detail_fish_circle != null and is_instance_valid(host._skill_detail_surface().detail_fish_circle):
		host._skill_detail_surface().detail_fish_circle.set_wallet_open_visual(open)


func _on_fishing_tool_selected(tool_id: String) -> void:
	if not host.fishing_runtime.tool_is_unlocked(tool_id):
		return
	host.fishing_runtime.active_tool_init_token += 1
	if tool_id == host.fishing_runtime.equipped_tool_id:
		_set_fishing_tool_wallet_open(false)
		return
	host._audio_director()._play_chain_impact_cluster(1, 0.42, "click", 1.0)
	host.fishing_runtime.set_equipped_tool(tool_id)
	fishing_tool_wallet_open = false
	_clear_fishing_tool_circle_menu()
	host.save_game()
	host._navigation_shell()._render_screen(false, host._skill_detail_surface().detail_actions_scroll.scroll_vertical if host._skill_detail_surface().detail_actions_scroll != null else -1)
	host._reward_feedback_surface()._set_result("%s equipped." % _fishing_tool_label(tool_id))


func _play_fishing_wallet_circle_pop(delay := 0.0) -> void:
	if host._skill_detail_surface().detail_fish_circle == null or not is_instance_valid(host._skill_detail_surface().detail_fish_circle):
		return
	host._skill_detail_surface().detail_fish_circle.pivot_offset = host._skill_detail_surface().detail_fish_circle.size * 0.5
	if fishing_tool_wallet_pop_tween != null and fishing_tool_wallet_pop_tween.is_valid():
		fishing_tool_wallet_pop_tween.kill()
	host._skill_detail_surface().detail_fish_circle.scale = Vector2.ONE
	fishing_tool_wallet_pop_tween = host.create_tween()
	if delay > 0.0:
		fishing_tool_wallet_pop_tween.tween_interval(delay)
	fishing_tool_wallet_pop_tween.tween_property(host._skill_detail_surface().detail_fish_circle, "scale", Vector2(1.08, 1.08), 0.075).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fishing_tool_wallet_pop_tween.tween_property(host._skill_detail_surface().detail_fish_circle, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _show_fishing_tool_not_unlocked_feedback(anchor: Control = null, global_point := Vector2.ZERO, use_global_point := false) -> void:
	var target := anchor
	if target == null or not is_instance_valid(target) or not target.is_inside_tree():
		target = host._skill_detail_surface().detail_fish_circle
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
		Vector2(0, -17),
		Vector2(0, -71),
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
	if fishing_tool_wallet_open:
		if fishing_tool_wallet_popup != null and is_instance_valid(fishing_tool_wallet_popup):
			for child in fishing_tool_wallet_popup.find_children("FishingToolPopupButton*", "Button", true, false):
				var button := child as Button
				if button == null:
					continue
				if button.get_global_rect().has_point(point):
					if bool(button.get_meta("tool_unlocked", false)):
						_on_fishing_tool_selected(str(button.get_meta("tool_id", "")))
					else:
						_show_fishing_tool_not_unlocked_feedback(button)
					return true
			if fishing_tool_wallet_popup.get_global_rect().has_point(point):
				return true
		if host._skill_detail_surface().detail_fish_circle != null and is_instance_valid(host._skill_detail_surface().detail_fish_circle) and host._skill_detail_surface().detail_fish_circle.get_global_rect().grow(16.0).has_point(point):
			var circle_tool_index: int = host._skill_detail_surface().detail_fish_circle.wallet_button_index_at(point)
			if (
				circle_tool_index >= 0
				and circle_tool_index < host._skill_detail_surface().detail_fish_circle.wallet_tool_ids.size()
				and circle_tool_index < host._skill_detail_surface().detail_fish_circle.wallet_unlocked_states.size()
			):
				if bool(host._skill_detail_surface().detail_fish_circle.wallet_unlocked_states[circle_tool_index]):
					_on_fishing_tool_selected(str(host._skill_detail_surface().detail_fish_circle.wallet_tool_ids[circle_tool_index]))
				else:
					_show_fishing_tool_not_unlocked_feedback(host._skill_detail_surface().detail_fish_circle, point, true)
				return true
			_set_fishing_tool_wallet_open(false)
			return true
		return false
	if host._skill_detail_surface().detail_fish_circle != null and is_instance_valid(host._skill_detail_surface().detail_fish_circle) and host._skill_detail_surface().detail_fish_circle.get_global_rect().grow(16.0).has_point(point):
		_set_fishing_tool_wallet_open(true)
		return true
	return false


func _on_fishing_tool_wallet_pressed() -> void:
	_set_fishing_tool_wallet_open(not fishing_tool_wallet_open)


func _set_fish_circle_for_skill_bound(circle_id: int, skill_id: String, instant := false) -> void:
	var circle := instance_from_id(circle_id) as FishCircle
	_set_fish_circle_for_skill(circle, skill_id, instant)


func _set_fish_circle_for_skill(circle: FishCircle, skill_id: String, instant := false) -> void:
	if circle == null or not is_instance_valid(circle):
		return
	if not circle.is_inside_tree():
		return
	circle.set_tool_icon_texture_resolver(Callable(self, "_fishing_tool_icon_texture"))
	circle.set_theme_color(ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE))
	circle.set_fish_count(host.fishing_runtime.fish_currency, GameFormatting.compact_number(maxf(0.0, host.fishing_runtime.fish_currency), 3), instant)
	var tool_def := _fishing_tool_def(host.fishing_runtime.equipped_tool_id)
	circle.set_tool_text("")
	circle.set_tool_icon(str(tool_def.get("art", "res://assets/content/fishing/tools/tool-bare-hands.png")))


func _attach_fishing_fish_circle_button(circle: Control) -> void:
	if circle == null:
		return
	var wallet_pressed_callable := Callable(self, "_on_fishing_tool_wallet_pressed")
	circle.mouse_filter = Control.MOUSE_FILTER_STOP
	if circle is BaseButton:
		var button := circle as BaseButton
		button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		if not button.pressed.is_connected(wallet_pressed_callable):
			button.pressed.connect(wallet_pressed_callable)
	if circle.has_signal("wallet_pressed") and not circle.is_connected("wallet_pressed", wallet_pressed_callable):
		circle.connect("wallet_pressed", wallet_pressed_callable)


func _refresh_fish_circle_currency_only() -> void:
	if host._skill_detail_surface().detail_fish_circle == null or not is_instance_valid(host._skill_detail_surface().detail_fish_circle) or not host._skill_detail_surface().detail_fish_circle.is_inside_tree():
		return
	host._skill_detail_surface().detail_fish_circle.set_theme_color(ThemeStyles.skill_theme_color(host.selected_skill_id, host.COLOR_BLUE))
	host._skill_detail_surface().detail_fish_circle.set_fish_count(host.fishing_runtime.fish_currency, GameFormatting.compact_number(maxf(0.0, host.fishing_runtime.fish_currency), 3), true)


func _fishing_tool_wallet_popup_style(panel_size: Vector2) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#e8fbf6", 0.95)
	style.border_color = Color("#168f83")
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	var corner = int(panel_size.x * 0.5)
	style.corner_radius_top_left = corner
	style.corner_radius_top_right = corner
	style.corner_radius_bottom_left = corner
	style.corner_radius_bottom_right = corner
	style.shadow_color = Color(0, 0, 0, 0.2)
	style.shadow_size = 5
	style.shadow_offset = Vector2(2, 3)
	return style


func _fishing_tool_circle_button_style(equipped: bool, unlocked: bool, pressed = false) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#e8f7f6") if equipped else (Color("#fffdf8") if unlocked else Color("#cfcac0"))
	if pressed:
		style.bg_color = style.bg_color.darkened(0.08)
	style.border_color = host.COLOR_GOLD if equipped else (host.COLOR_INK if unlocked else host.COLOR_MUTED)
	style.border_width_left = 4 if equipped else 5
	style.border_width_top = 4 if equipped else 5
	style.border_width_right = 4 if equipped else 5
	style.border_width_bottom = 4 if equipped else 5
	style.corner_radius_top_left = 499.5
	style.corner_radius_top_right = 499.5
	style.corner_radius_bottom_left = 499.5
	style.corner_radius_bottom_right = 499.5
	style.shadow_color = Color(0, 0, 0, 0.22) if unlocked else Color.TRANSPARENT
	style.shadow_size = 3 if unlocked else 0
	style.shadow_offset = Vector2(1.5, 2.5) if unlocked else Vector2.ZERO
	return style


func _fishing_rod_offer_available() -> bool:
	return not host.fishing_runtime.rod_collected and SkillState.host_skill_level(host, "fishing") >= FishingState.FISHING_ROD_OFFER_UNLOCK_LEVEL


func _fishing_net_offer_available() -> bool:
	return not host.fishing_runtime.net_collected and SkillState.host_skill_level(host, "fishing") >= FishingState.FISHING_NET_OFFER_UNLOCK_LEVEL


func _fishing_reinforced_rod_offer_available() -> bool:
	return host.fishing_runtime.rod_collected and not host.fishing_runtime.reinforced_rod_collected and SkillState.host_skill_level(host, "fishing") >= FishingState.FISHING_REINFORCED_ROD_UNLOCK_LEVEL


func _fishing_star_rod_offer_available() -> bool:
	return host.fishing_runtime.reinforced_rod_collected and not host.fishing_runtime.star_rod_collected and SkillState.host_skill_level(host, "fishing") >= FishingState.FISHING_STAR_ROD_UNLOCK_LEVEL


func _fishing_boat_offer_available() -> bool:
	return not host.fishing_runtime.boat_built and SkillState.host_skill_level(host, "fishing") >= FishingState.FISHING_BOAT_OFFER_UNLOCK_LEVEL


func _fishing_mirror_offer_available() -> bool:
	return not host.fishing_runtime.mirror_collected and SkillState.host_skill_level(host, "fishing") >= FishingState.FISHING_MIRROR_OFFER_UNLOCK_LEVEL


func method_should_show(skill_id: String, action_id: String) -> bool:
	return host.fishing_runtime.method_should_show(host, skill_id, action_id, FishingState.FISHING_LOCATION_DEFS, FishingState.FISHING_TOOL_LOCATION_ACTIONS)


func render_area_modules(skill_id: String) -> Array:
	return host.fishing_runtime.render_area_modules(host, skill_id, FishingState.FISHING_LOCATION_DEFS, FishingState.FISHING_TOOL_LOCATION_ACTIONS, FISHING_AREA_MAX_BUTTONS_PER_MODULE)


func render_area_module_for_action(skill_id: String, action_id: String) -> Dictionary:
	if action_id.is_empty():
		return {}
	for raw_area in render_area_modules(skill_id):
		var area_def := raw_area as Dictionary
		for raw_method_id in area_module_method_ids(skill_id, area_def):
			if str(raw_method_id) == action_id:
				return area_def
	return {}


func render_module_unlock(area_def: Dictionary) -> int:
	return host.fishing_runtime.render_module_unlock(host, area_def, FishingState.FISHING_LOCATION_DEFS, FishingState.FISHING_TOOL_LOCATION_ACTIONS)


func area_module_method_ids(skill_id: String, area_def: Dictionary) -> Array:
	var method_ids: Array = []
	var area_id := str(area_def.get("id", ""))
	if host.fishing_runtime.area_uses_location_tiles(area_def, FishingState.FISHING_LOCATION_DEFS):
		for raw_location in host.fishing_runtime.locations_for_area_module(area_def, FishingState.FISHING_LOCATION_DEFS):
			var location := raw_location as Dictionary
			if not host.fishing_runtime.location_should_show(host, area_id, location, FishingState.FISHING_LOCATION_DEFS, FishingState.FISHING_TOOL_LOCATION_ACTIONS):
				continue
			var action: Dictionary = host.fishing_runtime.location_display_action(host, area_id, location, FishingState.FISHING_LOCATION_DEFS, FishingState.FISHING_TOOL_LOCATION_ACTIONS)
			var action_id := str(action.get("id", ""))
			if not action_id.is_empty():
				method_ids.append(action_id)
		return method_ids
	for raw_method_id in area_def.get("methods", []):
		var action_id := str(raw_method_id)
		if method_should_show(skill_id, action_id):
			method_ids.append(action_id)
	return method_ids


func _fishing_detail_render_signature_state_key() -> int:
	var skill_levels := PackedInt32Array()
	for raw_skill_def in host.skill_defs:
		var skill_def := raw_skill_def as Dictionary
		var skill_id := str(skill_def.get("id", ""))
		if not skill_id.is_empty():
			skill_levels.append(SkillState.host_skill_level(host, skill_id))
	var unlock_runtime = host._activity_unlock_runtime()
	var event_runtime = host._temporary_event_runtime()
	var onboarding_runtime = host._onboarding_runtime()
	return hash([
		skill_levels,
		host.fishing_runtime.equipped_tool_id,
		host.fishing_runtime.net_collected,
		host.fishing_runtime.rod_collected,
		host.fishing_runtime.reinforced_rod_collected,
		host.fishing_runtime.star_rod_collected,
		host.fishing_runtime.boat_built,
		host.fishing_runtime.mirror_collected,
		host.material_runtime.amount("softwood"),
		unlock_runtime.manual_activity_unlocks,
		unlock_runtime.pending_activity_unlock_ceremony,
		event_runtime.temporary_event_active,
		onboarding_runtime.tutorial_active,
		onboarding_runtime.tutorial_step,
		onboarding_runtime.tutorial_gate_latch_only_until_swipe,
	])


func _fishing_detail_render_signature() -> Array:
	var cache_key := _fishing_detail_render_signature_state_key()
	if cache_key == fishing_detail_render_signature_cache_key and not fishing_detail_render_signature_cache.is_empty():
		return fishing_detail_render_signature_cache.duplicate()
	var signature: Array = [
		"tool:%s" % host.fishing_runtime.equipped_tool_id,
		"net-offer:%s:%s" % [str(host.fishing_runtime.net_collected), str(_fishing_net_offer_available())],
		"rod-offer:%s:%s" % [str(host.fishing_runtime.rod_collected), str(_fishing_rod_offer_available())],
		"reinforced-rod-offer:%s:%s" % [str(host.fishing_runtime.reinforced_rod_collected), str(_fishing_reinforced_rod_offer_available())],
		"star-rod-offer:%s:%s" % [str(host.fishing_runtime.star_rod_collected), str(_fishing_star_rod_offer_available())],
		"boat-offer:%s:%s:%s:%s" % [str(host.fishing_runtime.boat_built), str(_fishing_boat_offer_available()), str(SkillState.host_skill_level(host, "build")), str(host.material_runtime.amount("softwood"))],
		"mirror-offer:%s:%s" % [str(host.fishing_runtime.mirror_collected), str(_fishing_mirror_offer_available())],
	]
	for action in host._activity_unlock_runtime()._visible_actions_for_skill("fishing"):
		if host._passive_modules_runtime().is_passive_action(action as Dictionary):
			signature.append(str(action.get("id", "")))
	var inserted_actions: Array = host.fishing_runtime.standalone_and_event_actions_for_render(host, "fishing")
	var inserted_index := 0
	for area_def in render_area_modules("fishing"):
		var unlock_level: int = render_module_unlock(area_def)
		while inserted_index < inserted_actions.size() and host.activity_data_catalog.activity_action_display_sort_level(inserted_actions[inserted_index] as Dictionary) <= unlock_level:
			signature.append(str((inserted_actions[inserted_index] as Dictionary).get("id", "")))
			inserted_index += 1
		signature.append("area:%s" % str(area_def.get("id", "")))
		if host.fishing_runtime.area_uses_location_tiles(area_def, FishingState.FISHING_LOCATION_DEFS):
			var area_id := str(area_def.get("id", ""))
			if int(area_def.get("module_index", -1)) >= 0:
				signature.append("area-module:%s:%s" % [area_id, int(area_def.get("module_index", 0))])
			for raw_location in host.fishing_runtime.locations_for_area_module(area_def, FishingState.FISHING_LOCATION_DEFS):
				var location := raw_location as Dictionary
				if host.fishing_runtime.location_should_show(host, area_id, location, FishingState.FISHING_LOCATION_DEFS, FishingState.FISHING_TOOL_LOCATION_ACTIONS):
					signature.append("location-tile:%s:%s" % [area_id, str(location.get("id", ""))])
			continue
		if int(area_def.get("module_index", -1)) >= 0:
			signature.append("area-module:%s:%s" % [str(area_def.get("id", "")), int(area_def.get("module_index", 0))])
		for method_id in area_def.get("methods", []):
			if method_should_show("fishing", str(method_id)):
				signature.append(str(method_id))
	while inserted_index < inserted_actions.size():
		signature.append(str((inserted_actions[inserted_index] as Dictionary).get("id", "")))
		inserted_index += 1
	if host._skill_detail_surface()._beta_notice_unlocked():
		signature.append("beta_notice")
	fishing_detail_render_signature_cache_key = cache_key
	fishing_detail_render_signature_cache = signature.duplicate()
	return signature


func _build_fishing_detail_lazy_plan(skill_id: String) -> Array:
	var plan: Array = []
	var y = 0.0
	for action in host._activity_unlock_runtime()._visible_actions_for_skill(skill_id):
		var action_data = action as Dictionary
		if not host._passive_modules_runtime().is_passive_action(action_data):
			continue
		var action_id = str(action_data.get("id", ""))
		if action_id.is_empty():
			continue
		var passive_height = float(host.PASSIVE_MODULE_CARD_HEIGHT)
		var passive_module_key = ModuleUiRuntime.action_for_record(skill_id, action_data, host.FISHING_ACTION_ID_ALIASES)
		if host._skill_detail_surface()._module_ui_is_collapsed(passive_module_key):
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
		y += float(passive_entry["height"]) + host._skill_detail_surface().DETAIL_LAZY_STACK_SEPARATION

	var net_offer_rendered = false
	var rod_offer_rendered = false
	var reinforced_rod_offer_rendered = false
	var star_rod_offer_rendered = false
	var boat_offer_rendered = false
	var mirror_offer_rendered = false
	var inserted_actions = host.fishing_runtime.standalone_and_event_actions_for_render(host, skill_id)
	var inserted_index = 0
	for area_def in render_area_modules(skill_id):
		var unlock_level = render_module_unlock(area_def)
		while inserted_index < inserted_actions.size() and host.activity_data_catalog.activity_action_display_sort_level(inserted_actions[inserted_index] as Dictionary) <= unlock_level:
			y = _append_fishing_action_lazy_entry(plan, y, inserted_actions[inserted_index] as Dictionary)
			inserted_index += 1
		if _fishing_net_offer_available() and not net_offer_rendered and unlock_level > FishingState.FISHING_NET_OFFER_UNLOCK_LEVEL:
			y = _append_fishing_offer_lazy_entry(plan, y, "net")
			net_offer_rendered = true
		if _fishing_rod_offer_available() and not rod_offer_rendered and unlock_level > FishingState.FISHING_ROD_OFFER_UNLOCK_LEVEL:
			y = _append_fishing_offer_lazy_entry(plan, y, "rod")
			rod_offer_rendered = true
		if _fishing_reinforced_rod_offer_available() and not reinforced_rod_offer_rendered and unlock_level > FishingState.FISHING_REINFORCED_ROD_UNLOCK_LEVEL:
			y = _append_fishing_offer_lazy_entry(plan, y, "reinforced_rod")
			reinforced_rod_offer_rendered = true
		if _fishing_boat_offer_available() and not boat_offer_rendered and unlock_level > FishingState.FISHING_BOAT_OFFER_UNLOCK_LEVEL:
			y = _append_fishing_offer_lazy_entry(plan, y, "boat")
			boat_offer_rendered = true
		if _fishing_star_rod_offer_available() and not star_rod_offer_rendered and unlock_level > FishingState.FISHING_STAR_ROD_UNLOCK_LEVEL:
			y = _append_fishing_offer_lazy_entry(plan, y, "star_rod")
			star_rod_offer_rendered = true
		if _fishing_mirror_offer_available() and not mirror_offer_rendered and unlock_level > FishingState.FISHING_MIRROR_OFFER_UNLOCK_LEVEL:
			y = _append_fishing_offer_lazy_entry(plan, y, "mirror")
			mirror_offer_rendered = true
		var area_key = host.fishing_runtime.area_module_key(skill_id, area_def)
		var area_height = float(host.ACTION_CARD_HEIGHT)
		var area_module_key = ModuleUiRuntime.fishing_area(host.fishing_runtime.area_module_key(skill_id, area_def))
		if host._skill_detail_surface()._module_ui_is_collapsed(area_module_key):
			area_height = host._module_collapsed_squeeze_height()
		var area_entry = {
			"kind": "fishing_area",
			"area_def": area_def,
			"track_id": area_key,
			"method_ids": area_module_method_ids(skill_id, area_def),
			"y": y,
			"height": area_height,
			"mounted": false,
			"stack_host": null,
			"placeholder": null,
			"direct_stack_child": false
		}
		plan.append(area_entry)
		y += float(area_entry["height"]) + host._skill_detail_surface().DETAIL_LAZY_STACK_SEPARATION
	while inserted_index < inserted_actions.size():
		y = _append_fishing_action_lazy_entry(plan, y, inserted_actions[inserted_index] as Dictionary)
		inserted_index += 1
	if _fishing_net_offer_available() and not net_offer_rendered:
		y = _append_fishing_offer_lazy_entry(plan, y, "net")
	if _fishing_rod_offer_available() and not rod_offer_rendered:
		y = _append_fishing_offer_lazy_entry(plan, y, "rod")
	if _fishing_reinforced_rod_offer_available() and not reinforced_rod_offer_rendered:
		y = _append_fishing_offer_lazy_entry(plan, y, "reinforced_rod")
	if _fishing_boat_offer_available() and not boat_offer_rendered:
		y = _append_fishing_offer_lazy_entry(plan, y, "boat")
	if _fishing_star_rod_offer_available() and not star_rod_offer_rendered:
		y = _append_fishing_offer_lazy_entry(plan, y, "star_rod")
	if _fishing_mirror_offer_available() and not mirror_offer_rendered:
		y = _append_fishing_offer_lazy_entry(plan, y, "mirror")
	plan = host.module_ui_runtime.sort_fishing_lazy_plan(
		plan,
		skill_id,
		host._skill_detail_surface().DETAIL_LAZY_STACK_SEPARATION,
		Callable(host._skill_detail_surface(), "_detail_entry_level_sort_value"),
		Callable(host._activity_unlock_runtime(), "_action_unlock_requirements")
	)
	if host._skill_detail_surface()._beta_notice_unlocked():
		var notice_y := 0.0
		if not plan.is_empty():
			var last_entry := plan[-1] as Dictionary
			notice_y = float(last_entry.get("y", 0.0)) + float(last_entry.get("height", 0.0)) + host._skill_detail_surface().DETAIL_LAZY_STACK_SEPARATION
		plan.append({
			"kind": "beta_notice",
			"entry": {"kind": "beta_notice"},
			"track_id": "beta_notice",
			"y": notice_y,
			"height": host._skill_detail_surface().BETA_NOTICE_HEIGHT,
			"mounted": false,
			"stack_host": null,
			"placeholder": null,
			"direct_stack_child": false
		})
	return plan


func render_area_modules_into_stack(stack: VBoxContainer, content_width: float) -> void:
	var skill_id := "fishing"
	host._skill_detail_surface()._clear_detail_lazy_cache_bin()
	host._skill_detail_surface().detail_rendered_action_ids = _fishing_detail_render_signature()
	host._skill_detail_surface().detail_lazy_plan = _build_fishing_detail_lazy_plan(skill_id)
	host._skill_detail_surface().detail_lazy_last_scroll = -1.0
	host._skill_detail_surface()._detail_lazy_create_slots(stack, skill_id, content_width, content_width)
	var initial_force_count: int = host._skill_detail_surface()._detail_lazy_initial_force_mount_count_for_skill(skill_id)
	if _fishing_ablation_enabled("no_lazy"):
		host._skill_detail_surface()._detail_lazy_mount_initial_window_sync(true, host._skill_detail_surface().detail_lazy_plan.size())
		host._skill_detail_surface()._sync_detail_actions_scroll_limit()
		_restore_fishing_detail_render_culling()
	else:
		host._skill_detail_surface()._detail_lazy_mount_initial_window_sync(true, initial_force_count)
		host._skill_detail_surface()._sync_detail_actions_scroll_limit()
		_sync_fishing_detail_render_culling(true)
		host._skill_detail_surface()._queue_detail_lazy_settle_warm_mount(skill_id)


func _render_fishing_area_modules_preview(stack: VBoxContainer, content_width: float, state: Dictionary) -> void:
	var skill_id = "fishing"
	var net_offer_rendered = false
	var rod_offer_rendered = false
	var reinforced_rod_offer_rendered = false
	var star_rod_offer_rendered = false
	var boat_offer_rendered = false
	var mirror_offer_rendered = false
	for action in host._activity_unlock_runtime()._visible_actions_for_skill(skill_id):
		if not host._passive_modules_runtime().is_passive_action(action as Dictionary):
			continue
		var passive_card = host._passive_firepit_surface()._build_passive_module_card(skill_id, action as Dictionary, content_width, false)
		host._activity_unlock_ceremony_surface().prepare_locked_activity_preview_fade(passive_card["card"] as Dictionary, skill_id, action as Dictionary)
		host._activity_unlock_ceremony_surface().sync_locked_preview_presence(passive_card["card"] as Dictionary, skill_id, action as Dictionary)
		stack.add_child(passive_card["root"] as Control)
		(state["host.action_cards"] as Array).append(passive_card["card"])

	var inserted_actions = host.fishing_runtime.standalone_and_event_actions_for_render(host, skill_id)
	var inserted_index = 0
	for area_def in render_area_modules(skill_id):
		var unlock_level = render_module_unlock(area_def)
		while inserted_index < inserted_actions.size() and host.activity_data_catalog.activity_action_display_sort_level(inserted_actions[inserted_index] as Dictionary) <= unlock_level:
			_add_fishing_preview_standalone_action(stack, skill_id, inserted_actions[inserted_index] as Dictionary, content_width, state)
			inserted_index += 1
		if _fishing_net_offer_available() and not net_offer_rendered and unlock_level > FishingState.FISHING_NET_OFFER_UNLOCK_LEVEL:
			var net_offer = _build_fishing_net_offer_module(content_width)
			_set_preview_controls_mouse_filter(net_offer)
			stack.add_child(net_offer)
			net_offer_rendered = true
		if _fishing_rod_offer_available() and not rod_offer_rendered and unlock_level > FishingState.FISHING_ROD_OFFER_UNLOCK_LEVEL:
			var rod_offer = _build_fishing_rod_offer_module(content_width)
			_set_preview_controls_mouse_filter(rod_offer)
			stack.add_child(rod_offer)
			rod_offer_rendered = true
		if _fishing_reinforced_rod_offer_available() and not reinforced_rod_offer_rendered and unlock_level > FishingState.FISHING_REINFORCED_ROD_UNLOCK_LEVEL:
			var reinforced_offer = _build_fishing_rod_upgrade_offer_module(content_width, "reinforced_rod")
			_set_preview_controls_mouse_filter(reinforced_offer)
			stack.add_child(reinforced_offer)
			reinforced_rod_offer_rendered = true
		if _fishing_boat_offer_available() and not boat_offer_rendered and unlock_level > FishingState.FISHING_BOAT_OFFER_UNLOCK_LEVEL:
			var boat_offer = _build_fishing_boat_offer_module(content_width)
			_set_preview_controls_mouse_filter(boat_offer)
			stack.add_child(boat_offer)
			boat_offer_rendered = true
		if _fishing_mirror_offer_available() and not mirror_offer_rendered and unlock_level > FishingState.FISHING_MIRROR_OFFER_UNLOCK_LEVEL:
			var mirror_offer = _build_fishing_mirror_offer_module(content_width)
			_set_preview_controls_mouse_filter(mirror_offer)
			stack.add_child(mirror_offer)
			mirror_offer_rendered = true
		if _fishing_star_rod_offer_available() and not star_rod_offer_rendered and unlock_level > FishingState.FISHING_STAR_ROD_UNLOCK_LEVEL:
			var star_offer = _build_fishing_rod_upgrade_offer_module(content_width, "star_rod")
			_set_preview_controls_mouse_filter(star_offer)
			stack.add_child(star_offer)
			star_rod_offer_rendered = true
		var built = _build_fishing_area_module(skill_id, area_def, content_width)
		_mark_fishing_preview_module_cards(built)
		var root = built["root"] as Control
		_set_preview_controls_mouse_filter(root)
		stack.add_child(root)
		(state["fishing_built_modules"] as Array).append(built)
	while inserted_index < inserted_actions.size():
		_add_fishing_preview_standalone_action(stack, skill_id, inserted_actions[inserted_index] as Dictionary, content_width, state)
		inserted_index += 1
	if _fishing_net_offer_available() and not net_offer_rendered:
		var net_offer = _build_fishing_net_offer_module(content_width)
		_set_preview_controls_mouse_filter(net_offer)
		stack.add_child(net_offer)
	if _fishing_rod_offer_available() and not rod_offer_rendered:
		var rod_offer = _build_fishing_rod_offer_module(content_width)
		_set_preview_controls_mouse_filter(rod_offer)
		stack.add_child(rod_offer)
	if _fishing_reinforced_rod_offer_available() and not reinforced_rod_offer_rendered:
		var reinforced_offer = _build_fishing_rod_upgrade_offer_module(content_width, "reinforced_rod")
		_set_preview_controls_mouse_filter(reinforced_offer)
		stack.add_child(reinforced_offer)
	if _fishing_boat_offer_available() and not boat_offer_rendered:
		var boat_offer = _build_fishing_boat_offer_module(content_width)
		_set_preview_controls_mouse_filter(boat_offer)
		stack.add_child(boat_offer)
	if _fishing_star_rod_offer_available() and not star_rod_offer_rendered:
		var star_offer = _build_fishing_rod_upgrade_offer_module(content_width, "star_rod")
		_set_preview_controls_mouse_filter(star_offer)
		stack.add_child(star_offer)
	if _fishing_mirror_offer_available() and not mirror_offer_rendered:
		var mirror_offer = _build_fishing_mirror_offer_module(content_width)
		_set_preview_controls_mouse_filter(mirror_offer)
		stack.add_child(mirror_offer)


func _build_fishing_location_tile(
	skill_id: String,
	area_id: String,
	area_key: String,
	location: Dictionary,
	method_row: HBoxContainer
) -> Dictionary:
	var location_id = str(location.get("id", ""))
	var action = host.fishing_runtime.location_display_action(host, area_id, location, FishingState.FISHING_LOCATION_DEFS, FishingState.FISHING_TOOL_LOCATION_ACTIONS)
	if action.is_empty():
		return {}
	var action_id = str(action.get("id", ""))
	var location_unlocked = host.fishing_runtime.location_is_available(host, area_id, location)
	var action_unlocked = host._activity_unlock_runtime()._is_action_unlocked(skill_id, action)
	var unlocked = location_unlocked and action_unlocked
	var unlock_ready_pending = host._activity_unlock_runtime()._action_has_pending_unlock_readiness(action_id)

	var method_column = VBoxContainer.new()
	method_column.add_theme_constant_override("separation", FISHING_MODULE_TITLE_TOP)
	method_column.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	method_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	method_row.add_child(method_column)

	var method_title_slot := Control.new()
	method_title_slot.custom_minimum_size = Vector2(FISHING_LOCATION_TILE_SIZE.x, 29)
	method_title_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	method_column.add_child(method_title_slot)
	var method_title = host._label(str(location.get("name", location_id.capitalize())), 48, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	method_title.add_theme_color_override("font_outline_color", host.COLOR_INK)
	method_title.add_theme_constant_override("outline_size", FISHING_METHOD_TITLE_OUTLINE)
	method_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	method_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	method_title.set_anchors_preset(Control.PRESET_FULL_RECT)
	method_title.offset_top = -9
	method_title.offset_bottom = -9
	method_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	method_title_slot.add_child(method_title)

	var art_panel = Panel.new()
	art_panel.custom_minimum_size = FISHING_LOCATION_TILE_SIZE
	art_panel.size = FISHING_LOCATION_TILE_SIZE
	art_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	art_panel.clip_contents = false
	art_panel.add_theme_stylebox_override("panel", _fishing_location_tile_style(unlocked))
	art_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	method_column.add_child(art_panel)

	var tile_motion_root = Control.new()
	tile_motion_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	tile_motion_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile_motion_root.pivot_offset = FISHING_LOCATION_TILE_SIZE * 0.5
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
		flat_location_art.texture = _fishing_location_thumbnail_texture(area_id, location_id)
		flat_location_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		flat_location_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		location_art = flat_location_art
	else:
		var rounded_location_art = RoundedTextureRect.new()
		rounded_location_art.texture = _fishing_location_thumbnail_texture(area_id, location_id)
		rounded_location_art.radius = 15.0
		rounded_location_art.mask_inset = 5.0
		rounded_location_art.aspect_mode = 2
		rounded_location_art.fallback_color = Color("#224d45")
		location_art = rounded_location_art
	location_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	location_art.modulate = Color.WHITE if unlocked else Color(0.72, 0.72, 0.72, 0.82)
	location_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	location_art.pivot_offset = FISHING_LOCATION_TILE_SIZE * 0.5
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
	medal.offset_left = 0
	medal.offset_right = 95
	medal.offset_top = 0
	medal.offset_bottom = 95
	medal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	medal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	medal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	medal.z_index = host.ACTION_CARD_FACE_BORDER_Z_INDEX + 1
	tile_motion_root.add_child(medal)

	var mastery_progress = ThemeStyles.progress_bar(Color("#f4bf35"), 28)
	mastery_progress.border_color = host.COLOR_INK
	ThemeStyles.apply_mastery_progress_bar_theme(mastery_progress, ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE), host.COLOR_INK)
	mastery_progress.easing_speed = 24.0
	mastery_progress.custom_minimum_size = Vector2(FISHING_LOCATION_TILE_SIZE.x, 28.0)
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
	method_button.disabled = not unlocked
	method_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	method_button.set_anchors_preset(Control.PRESET_FULL_RECT)
	method_button.add_theme_stylebox_override("normal", host.empty_style_cache)
	method_button.add_theme_stylebox_override("hover", host.empty_style_cache)
	method_button.add_theme_stylebox_override("pressed", host.empty_style_cache)
	method_button.add_theme_stylebox_override("disabled", host.empty_style_cache)
	method_button.add_theme_stylebox_override("focus", host.empty_style_cache)
	method_button.z_index = SkillDetailSurface.MODULE_ACTION_ZONE_Z_INDEX + 1
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
		"mastery_action_id": host.fishing_runtime.location_mastery_action_id(area_id, location_id, FishingState.FISHING_TOOL_LOCATION_ACTIONS),
		"area_id": area_id,
		"location_id": location_id,
		"art_panel": art_panel,
		"wiggle_root": tile_motion_root,
		"art": location_art,
		"active_rest_position": Vector2.ZERO,
		"active_sway_offset": Vector2.ZERO,
		"active_sway_rotation": 0.0,
		"active_sway_scale_pulse": 0.0,
		"active_camera_zoom": FISHING_LOCATION_ACTIVE_CAMERA_ZOOM,
		"active_camera_pan": FISHING_LOCATION_ACTIVE_CAMERA_PAN,
		"medal": medal,
		"attempt_bar": null,
		"mastery": mastery_progress,
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


func _fishing_active_tool_hit_at_position(area_card: Dictionary, event_position: Vector2) -> bool:
	var layer := area_card.get("active_tool_layer") as Control
	var art := area_card.get("active_tool_art") as TextureRect
	if layer == null or art == null or not is_instance_valid(layer) or not is_instance_valid(art):
		return false
	if not layer.visible or not layer.is_visible_in_tree():
		return false
	return art.get_global_rect().grow(18.0).has_point(event_position)


func _fishing_active_tool_ease(value: float) -> float:
	var t := clampf(value, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


func _fishing_active_tool_base_x(icon_width: float) -> float:
	return FISHING_ACTIVE_TOOL_LAYER_SIZE.x - FISHING_ACTIVE_TOOL_VISUAL_LANE_WIDTH + (FISHING_ACTIVE_TOOL_VISUAL_LANE_WIDTH - icon_width) * 0.5


func _fishing_tool_uses_initial_drop(tool_id: String) -> bool:
	return tool_id in ["net", "mirror", "boat"] or FishingState.is_rod(tool_id)


func _on_fishing_active_tool_pressed(anchor: Control) -> void:
	if anchor == null or not is_instance_valid(anchor):
		return
	host._reward_feedback_surface()._float_reward(host, anchor, _fishing_tool_label(host.fishing_runtime.equipped_tool_id), 54, host.COLOR_INK, Vector2(0, -12), Vector2(0, -59), 0.0)


func _route_fishing_active_tool_input(event: InputEvent) -> bool:
	if host.selected_skill_id != "fishing":
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
	for raw_card in host.action_cards.values():
		if typeof(raw_card) != TYPE_DICTIONARY:
			continue
		var method_card := raw_card as Dictionary
		if not bool(method_card.get("is_fishing_method", false)):
			continue
		var method_button := method_card.get("method_button") as Control
		if method_button != null and is_instance_valid(method_button) and method_button.visible and method_button.is_visible_in_tree():
			if method_button.get_global_rect().has_point(event_position):
				return false
	for raw_card in host.action_cards.values():
		if typeof(raw_card) != TYPE_DICTIONARY:
			continue
		var area_card := raw_card as Dictionary
		if not bool(area_card.get("is_fishing_area", false)):
			continue
		if not _fishing_area_card_owns_action(area_card, host.running_action_id):
			continue
		var layer := area_card.get("active_tool_layer") as Control
		var art := area_card.get("active_tool_art") as TextureRect
		if layer == null or art == null or not is_instance_valid(layer) or not is_instance_valid(art):
			continue
		if not layer.visible or not layer.is_visible_in_tree():
			continue
		var art_rect := art.get_global_rect().grow(18.0)
		if not art_rect.has_point(event_position):
			continue
		host._reward_feedback_surface()._float_reward(host, art, _fishing_tool_label(host.fishing_runtime.equipped_tool_id), 54, host.COLOR_INK, Vector2(0, -12), Vector2(0, -59), 0.0)
		return true
	return false


func _sync_fishing_active_tool_hit(area_card: Dictionary) -> void:
	var layer := area_card.get("active_tool_layer") as Control
	var art := area_card.get("active_tool_art") as TextureRect
	var hit := area_card.get("active_tool_hit") as Button
	if layer == null or art == null or hit == null or not is_instance_valid(layer) or not is_instance_valid(art) or not is_instance_valid(hit):
		return
	host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(hit, layer.visible)
	hit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hit_padding := Vector2(17.0, 17.0)
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
	host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(layer, active_here)
	if not active_here:
		art.position = Vector2(_fishing_active_tool_base_x(FISHING_ACTIVE_TOOL_ICON_SIZE.x), FISHING_ACTIVE_TOOL_FLOAT_Y)
		art.rotation = 0.0
		art.scale = Vector2.ONE
		_sync_fishing_active_tool_hit(area_card)
		return
	var current_tool_id = host.fishing_runtime.equipped_tool_id
	if str(area_card.get("active_tool_id", "")) != current_tool_id:
		area_card["active_tool_id"] = current_tool_id
		area_card["active_tool_init_token"] = host.fishing_runtime.active_tool_init_token
		art.texture = _fishing_tool_icon_texture(current_tool_id)
		var icon_size = FISHING_ACTIVE_NET_ICON_SIZE if current_tool_id in ["net", "mirror"] else FISHING_ACTIVE_TOOL_ICON_SIZE
		art.custom_minimum_size = icon_size
		art.size = icon_size
		if current_tool_id in ["net", "mirror"]:
			art.pivot_offset = Vector2(icon_size.x * 0.20, icon_size.y * 0.78)
		elif FishingState.is_rod(current_tool_id):
			art.pivot_offset = Vector2(icon_size.x * 0.30, icon_size.y * 0.68)
		else:
			art.pivot_offset = icon_size * 0.5
		if _fishing_tool_uses_initial_drop(current_tool_id):
			area_card["active_tool_init_seconds"] = FISHING_ACTIVE_TOOL_INIT_SECONDS
			art.position = Vector2(_fishing_active_tool_base_x(icon_size.x), FISHING_ACTIVE_TOOL_FLOAT_Y - 88.0)
		else:
			area_card["active_tool_init_seconds"] = 0.0
			art.position = Vector2(_fishing_active_tool_base_x(icon_size.x), FISHING_ACTIVE_TOOL_FLOAT_Y)
		art.rotation = 0.0
		art.scale = Vector2.ONE
	elif int(area_card.get("active_tool_init_token", -1)) != host.fishing_runtime.active_tool_init_token:
		area_card["active_tool_init_token"] = host.fishing_runtime.active_tool_init_token
		var icon_size = FISHING_ACTIVE_NET_ICON_SIZE if current_tool_id in ["net", "mirror"] else FISHING_ACTIVE_TOOL_ICON_SIZE
		if _fishing_tool_uses_initial_drop(current_tool_id):
			area_card["active_tool_init_seconds"] = FISHING_ACTIVE_TOOL_INIT_SECONDS
			art.position = Vector2(_fishing_active_tool_base_x(icon_size.x), FISHING_ACTIVE_TOOL_FLOAT_Y - 88.0)
		else:
			area_card["active_tool_init_seconds"] = 0.0
			art.position = Vector2(_fishing_active_tool_base_x(icon_size.x), FISHING_ACTIVE_TOOL_FLOAT_Y)
		art.rotation = 0.0
		art.scale = Vector2.ONE
	var progress = clampf(host.action_progress, 0.0, 1.0)
	var init_seconds = float(area_card.get("active_tool_init_seconds", 0.0))
	if init_seconds > 0.0:
		init_seconds = maxf(0.0, init_seconds - delta)
		area_card["active_tool_init_seconds"] = init_seconds
		var init_progress = 1.0 - clampf(init_seconds / FISHING_ACTIVE_TOOL_INIT_SECONDS, 0.0, 1.0)
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
	var y = FISHING_ACTIVE_TOOL_FLOAT_Y
	if progress < 0.32:
		y += sin(progress / 0.45 * PI * 2.0) * 6.0
	elif progress < 0.88:
		var dip_t = 1.0 - pow(1.0 - clampf((progress - 0.32) / 0.16, 0.0, 1.0), 3.0)
		y = lerpf(FISHING_ACTIVE_TOOL_FLOAT_Y, FISHING_ACTIVE_TOOL_DIP_Y, dip_t)
	else:
		var rise_t = 1.0 - pow(1.0 - clampf((progress - 0.88) / 0.12, 0.0, 1.0), 2.2)
		y = lerpf(FISHING_ACTIVE_TOOL_DIP_Y, FISHING_ACTIVE_TOOL_HARVEST_Y, rise_t)
	var x = _fishing_active_tool_base_x(FISHING_ACTIVE_TOOL_ICON_SIZE.x) + sin(progress * TAU * 1.4) * 5.0
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
	layer.offset_left = FISHING_ACTIVE_TOOL_LAYER_RIGHT_OFFSET - FISHING_ACTIVE_TOOL_LAYER_SIZE.x
	layer.offset_right = FISHING_ACTIVE_TOOL_LAYER_RIGHT_OFFSET
	layer.offset_top = FISHING_ACTIVE_TOOL_LAYER_TOP
	layer.offset_bottom = FISHING_ACTIVE_TOOL_LAYER_TOP + FISHING_ACTIVE_TOOL_LAYER_SIZE.y
	layer.clip_contents = true
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.visible = false
	layer.z_index = FISHING_ACTIVE_TOOL_Z_INDEX

	var art := TextureRect.new()
	art.texture = _fishing_tool_icon_texture(host.fishing_runtime.equipped_tool_id)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.custom_minimum_size = FISHING_ACTIVE_TOOL_ICON_SIZE
	art.size = FISHING_ACTIVE_TOOL_ICON_SIZE
	art.position = Vector2(_fishing_active_tool_base_x(FISHING_ACTIVE_TOOL_ICON_SIZE.x), FISHING_ACTIVE_TOOL_FLOAT_Y)
	art.pivot_offset = FISHING_ACTIVE_TOOL_ICON_SIZE * 0.5
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
	hit_button.pressed.connect(Callable(self, "_on_fishing_active_tool_pressed").bind(hit_button))
	layer.add_child(hit_button)

	return {
		"layer": layer,
		"art": art,
		"hit": hit_button,
		"tool_id": host.fishing_runtime.equipped_tool_id,
	}


func _update_fishing_net_tool_animation(area_card: Dictionary, art: TextureRect, progress: float, delta: float, instant: bool) -> void:
	var center_x = _fishing_active_tool_base_x(FISHING_ACTIVE_NET_ICON_SIZE.x)
	var ready_position := Vector2(center_x - 34.0, FISHING_ACTIVE_TOOL_FLOAT_Y - 18.0)
	var scoop_position := Vector2(center_x + 34.0, FISHING_ACTIVE_TOOL_DIP_Y - 2.0)
	var harvest_position := Vector2(center_x + 14.0, FISHING_ACTIVE_TOOL_HARVEST_Y - 134.0)
	var target_position = ready_position
	var target_rotation = 0.38
	var target_scale := Vector2.ONE
	if host.fishing_runtime.net_haul_visual_seconds > 0.0:
		var haul_progress := 1.0 - clampf(host.fishing_runtime.net_haul_visual_seconds / FishingState.FISHING_NET_HAUL_VISUAL_SECONDS, 0.0, 1.0)
		var lift_t = _fishing_active_tool_ease(clampf(haul_progress / 0.42, 0.0, 1.0))
		var hold_t := clampf((haul_progress - 0.42) / 0.24, 0.0, 1.0)
		var lower_t = _fishing_active_tool_ease(clampf((haul_progress - 0.66) / 0.34, 0.0, 1.0))
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
		host.fishing_runtime.net_haul_visual_seconds = maxf(0.0, host.fishing_runtime.net_haul_visual_seconds - delta)
	elif progress < 0.24 and host.fishing_runtime.net_stored_fish <= 0 and host.fishing_runtime.net_successes <= 0:
		if host.fishing_runtime.net_set_in_water:
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
	area_card["active_tool_underwater"] = host.fishing_runtime.net_haul_visual_seconds <= 0.0 and (progress >= 0.12 or host.fishing_runtime.net_set_in_water or host.fishing_runtime.net_stored_fish > 0 or host.fishing_runtime.net_successes > 0)
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
	var center_x = _fishing_active_tool_base_x(FISHING_ACTIVE_NET_ICON_SIZE.x)
	var float_position := Vector2(center_x - 6.0, FISHING_ACTIVE_TOOL_FLOAT_Y - 18.0)
	var reach_position := Vector2(center_x + 6.0, FISHING_ACTIVE_TOOL_DIP_Y - 4.0)
	var lift_position := Vector2(center_x - 18.0, FISHING_ACTIVE_TOOL_HARVEST_Y - 12.0)
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
	var center_x = _fishing_active_tool_base_x(FISHING_ACTIVE_TOOL_ICON_SIZE.x) - 72.0
	var start_position := Vector2(center_x + 6.0, FISHING_ACTIVE_TOOL_FLOAT_Y - 42.0)
	var water_position := Vector2(center_x + 4.0, FISHING_ACTIVE_TOOL_DIP_Y - 28.0)
	var target_position = water_position
	var float_rotation := 0.02
	var target_rotation = float_rotation
	var target_scale := Vector2.ONE * 1.54
	if host.fishing_runtime.boat_haul_visual_seconds > 0.0:
		var haul_t := 1.0 - clampf(host.fishing_runtime.boat_haul_visual_seconds / FishingState.FISHING_BOAT_HAUL_VISUAL_SECONDS, 0.0, 1.0)
		haul_t = _fishing_active_tool_ease(haul_t)
		target_position = water_position + Vector2(sin(haul_t * PI) * 7.0, -sin(haul_t * PI) * 16.0)
		target_rotation = float_rotation + sin(haul_t * PI * 2.0) * 0.035
		target_scale = Vector2.ONE * lerpf(1.58, 1.54, haul_t)
		host.fishing_runtime.boat_haul_visual_seconds = maxf(0.0, host.fishing_runtime.boat_haul_visual_seconds - delta)
	elif not host.fishing_runtime.boat_set_in_water and progress < 0.18:
		var plop_t := 1.0 - pow(1.0 - clampf(progress / 0.18, 0.0, 1.0), 2.2)
		target_position = start_position.lerp(water_position, plop_t)
		target_position.y -= sin(plop_t * PI) * 16.0
		target_rotation = lerpf(float_rotation - 0.03, float_rotation, plop_t)
		target_scale = Vector2.ONE * lerpf(1.36, 1.54, plop_t)
	else:
		host.fishing_runtime.boat_set_in_water = true
		var bob_t := progress * TAU
		target_position = water_position + Vector2(sin(bob_t * 0.7) * 3.0, sin(bob_t) * 5.0)
		target_rotation = float_rotation + sin(bob_t * 0.74) * 0.018
		var load_sag := clampf(float(host.fishing_runtime.boat_stored_fish) / float(FishingState.FISHING_BOAT_HAUL_THRESHOLD), 0.0, 1.0) * 5.0
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
	var base_x = _fishing_active_tool_base_x(FISHING_ACTIVE_TOOL_ICON_SIZE.x)
	var float_position := Vector2(base_x, FISHING_ACTIVE_TOOL_FLOAT_Y)
	var dip_position := Vector2(base_x + 3.0, FISHING_ACTIVE_TOOL_DIP_Y - 8.0)
	var lift_position := Vector2(base_x - 10.0, FISHING_ACTIVE_TOOL_HARVEST_Y - 128.0)
	var target_position = dip_position
	var target_rotation = 0.42
	var target_scale := Vector2.ONE
	if host.fishing_runtime.rod_haul_visual_seconds > 0.0:
		var haul_t := 1.0 - clampf(host.fishing_runtime.rod_haul_visual_seconds / FishingState.FISHING_ROD_HAUL_VISUAL_SECONDS, 0.0, 1.0)
		haul_t = _fishing_active_tool_ease(haul_t)
		target_position = dip_position.lerp(lift_position, haul_t)
		target_position.y -= sin(haul_t * PI) * 26.0
		target_rotation = lerpf(0.44, -0.18, haul_t)
		target_scale = Vector2.ONE * lerpf(1.02, 1.0, haul_t)
		host.fishing_runtime.rod_haul_visual_seconds = maxf(0.0, host.fishing_runtime.rod_haul_visual_seconds - delta)
		if host.fishing_runtime.rod_haul_visual_seconds <= 0.0:
			host.fishing_runtime.rod_set_in_water = false
	elif not host.fishing_runtime.rod_set_in_water and progress < 0.34:
		var cast_t := 1.0 - pow(1.0 - clampf(progress / 0.34, 0.0, 1.0), 2.2)
		target_position = float_position.lerp(dip_position, cast_t)
		target_position.y -= sin(cast_t * PI) * 6.0
		target_rotation = lerpf(0.04, 0.42, cast_t)
		target_scale = Vector2.ONE * (1.0 + sin(cast_t * PI) * 0.02)
	else:
		host.fishing_runtime.rod_set_in_water = true
		var hold_t := progress * TAU
		target_position = dip_position + Vector2(sin(hold_t * 0.55) * 2.0, sin(hold_t * 0.8) * 1.5)
		target_rotation = 0.42 + sin(hold_t * 0.7) * 0.012
		target_scale = Vector2.ONE
	area_card["active_tool_underwater"] = host.fishing_runtime.rod_set_in_water and host.fishing_runtime.rod_haul_visual_seconds <= 0.0
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
	var icon_size = FISHING_ACTIVE_NET_ICON_SIZE if tool_id in ["net", "mirror"] else FISHING_ACTIVE_TOOL_ICON_SIZE
	var base_x = _fishing_active_tool_base_x(icon_size.x)
	var high_position := Vector2(base_x, FISHING_ACTIVE_TOOL_FLOAT_Y - 88.0)
	var water_position := Vector2(base_x, FISHING_ACTIVE_TOOL_DIP_Y - 8.0)
	var high_rotation := 0.0
	var water_rotation := 0.0
	var high_scale := Vector2.ONE
	var water_scale := Vector2.ONE
	match tool_id:
		"net":
			high_position = Vector2(base_x - 34.0, FISHING_ACTIVE_TOOL_FLOAT_Y - 96.0)
			water_position = Vector2(base_x + 34.0, FISHING_ACTIVE_TOOL_DIP_Y - 2.0)
			high_rotation = 0.30
			water_rotation = 1.14
			high_scale = Vector2.ONE * 0.98
			water_scale = Vector2.ONE * 1.04
		"mirror":
			high_position = Vector2(base_x - 8.0, FISHING_ACTIVE_TOOL_FLOAT_Y - 96.0)
			water_position = Vector2(base_x + 6.0, FISHING_ACTIVE_TOOL_DIP_Y - 4.0)
			high_rotation = 0.58
			water_rotation = 1.52
			high_scale = Vector2.ONE * 1.02
			water_scale = Vector2.ONE * 1.10
		"boat":
			base_x = _fishing_active_tool_base_x(FISHING_ACTIVE_TOOL_ICON_SIZE.x) - 72.0
			high_position = Vector2(base_x + 6.0, FISHING_ACTIVE_TOOL_FLOAT_Y - 82.0)
			water_position = Vector2(base_x + 4.0, FISHING_ACTIVE_TOOL_DIP_Y - 28.0)
			high_rotation = -0.04
			water_rotation = 0.02
			high_scale = Vector2.ONE * 1.40
			water_scale = Vector2.ONE * 1.54
		_:
			if FishingState.is_rod(tool_id):
				high_position = Vector2(base_x - 8.0, FISHING_ACTIVE_TOOL_FLOAT_Y - 88.0)
				water_position = Vector2(base_x + 3.0, FISHING_ACTIVE_TOOL_DIP_Y - 8.0)
				high_rotation = -0.10
				water_rotation = 0.42
			else:
				high_position = Vector2(base_x, FISHING_ACTIVE_TOOL_FLOAT_Y - 72.0)
				water_position = Vector2(base_x + 2.0, FISHING_ACTIVE_TOOL_DIP_Y - 4.0)
				high_rotation = -0.04
				water_rotation = 0.04
	var t = _fishing_active_tool_ease(init_progress)
	var target_position = high_position.lerp(water_position, t)
	target_position.y -= sin(t * PI) * 18.0
	var target_rotation = lerpf(high_rotation, water_rotation, t)
	var target_scale := high_scale.lerp(water_scale, t)
	if init_progress >= 1.0:
		match tool_id:
			"net":
				host.fishing_runtime.net_set_in_water = true
			"boat":
				host.fishing_runtime.boat_set_in_water = true
			_:
				if FishingState.is_rod(tool_id):
					host.fishing_runtime.rod_set_in_water = true
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


func _fishing_method_short_label(action: Dictionary) -> String:
	var action_id := str(action.get("id", ""))
	var custom := {
		"shallows": "Shallows",
		"rocks": "Rocks",
		"reef-pot": "Reef Pot",
		"storm-ripple": "Storm Ripple",
		"dock-edge": "Dock Edge",
		"piling-line": "Piling Line",
		"river-bend": "River Bend",
		"rapids": "Rapids",
		"drain-gate": "Drain Gate",
		"tunnel-pool": "Tunnel Pool",
		"ice-hole": "Ice Hole",
		"reef-cage": "Reef Cage",
		"night-reef": "Night Reef",
		"pearl-bed": "Pearl Bed",
		"rowboat": "Rowboat",
		"open-water": "Open Water",
		"chum-line": "Chum Line",
		"storm-line": "Storm Line",
		"wreck-drop": "Wreck Drop",
		"abyss": "Abyss",
		"deep-trench": "Deep Trench",
		"starlight": "Starlight",
		"reflection": "Reflection",
	}
	if custom.has(action_id):
		return str(custom[action_id])
	var words := str(action.get("name", "")).split(" ")
	return words[0] if not words.is_empty() else action_id


func _fishing_area_focused_method_label(action: Dictionary) -> String:
	var action_id := str(action.get("id", ""))
	var custom := {
		"river-bend": "River Bend",
		"rapids": "Rapids",
		"drain-gate": "Drain Gate",
		"tunnel-pool": "Tunnel Pool",
		"ice-hole": "Ice Hole",
		"reef-cage": "Reef Cage",
		"night-reef": "Night Reef",
		"pearl-bed": "Pearl Bed",
		"rowboat": "Rowboat",
		"open-water": "Open Water",
		"chum-line": "Chum Line",
		"storm-line": "Storm Line",
		"wreck-drop": "Wreck Drop",
		"abyss": "Abyss",
		"deep-trench": "Deep Trench",
		"starlight": "Starlight",
		"reflection": "Reflection",
		"reef-pot": "Reef Pot",
		"storm-ripple": "Storm Ripple",
	}
	if custom.has(action_id):
		return str(custom[action_id])
	return _fishing_method_short_label(action)


func _build_fishing_area_action_method_tile(skill_id: String, area_key: String, area_bg_path: String, action_id: String, action: Dictionary, method_row: HBoxContainer, status: Label) -> Dictionary:
	var unlocked = host._activity_unlock_runtime()._is_action_unlocked(skill_id, action)
	var unlock_ready_pending = host._activity_unlock_runtime()._action_has_pending_unlock_readiness(action_id)

	var method_column = VBoxContainer.new()
	method_column.add_theme_constant_override("separation", FISHING_MODULE_TITLE_TOP)
	method_column.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	method_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	method_row.add_child(method_column)

	var method_title_slot := Control.new()
	method_title_slot.custom_minimum_size = Vector2(FISHING_LOCATION_TILE_SIZE.x, 29)
	method_title_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	method_column.add_child(method_title_slot)
	var method_title = host._label(_fishing_area_focused_method_label(action), 48, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	method_title.add_theme_color_override("font_outline_color", host.COLOR_INK)
	method_title.add_theme_constant_override("outline_size", FISHING_METHOD_TITLE_OUTLINE)
	method_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	method_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	method_title.set_anchors_preset(Control.PRESET_FULL_RECT)
	method_title.offset_top = -9
	method_title.offset_bottom = -9
	method_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	method_title_slot.add_child(method_title)

	var art_panel = Panel.new()
	art_panel.custom_minimum_size = FISHING_LOCATION_TILE_SIZE
	art_panel.size = FISHING_LOCATION_TILE_SIZE
	art_panel.set_meta("fishing_area_method_ready_marker", true)
	art_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	art_panel.clip_contents = false
	art_panel.add_theme_stylebox_override("panel", _fishing_location_tile_style(unlocked))
	art_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	method_column.add_child(art_panel)

	var tile_motion_root = Control.new()
	tile_motion_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	tile_motion_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile_motion_root.pivot_offset = FISHING_LOCATION_TILE_SIZE * 0.5
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
	art.radius = 15.0
	art.mask_inset = 5.0
	art.aspect_mode = 2
	art.fallback_color = Color("#224d45")
	art.modulate = Color.WHITE if unlocked else Color(0.72, 0.72, 0.72, 0.82)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.pivot_offset = FISHING_LOCATION_TILE_SIZE * 0.5
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
	medal.offset_left = 0
	medal.offset_right = 95
	medal.offset_top = 0
	medal.offset_bottom = 95
	medal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	medal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	medal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	medal.z_index = host.ACTION_CARD_FACE_BORDER_Z_INDEX + 1
	tile_motion_root.add_child(medal)

	var mastery_progress = ThemeStyles.progress_bar(Color("#f4bf35"), 28)
	mastery_progress.border_color = host.COLOR_INK
	ThemeStyles.apply_mastery_progress_bar_theme(mastery_progress, ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE), host.COLOR_INK)
	mastery_progress.easing_speed = 24.0
	mastery_progress.custom_minimum_size = Vector2(FISHING_LOCATION_TILE_SIZE.x, 28.0)
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
	method_button.disabled = not unlocked
	method_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	method_button.set_anchors_preset(Control.PRESET_FULL_RECT)
	method_button.add_theme_stylebox_override("normal", host.empty_style_cache)
	method_button.add_theme_stylebox_override("hover", host.empty_style_cache)
	method_button.add_theme_stylebox_override("pressed", host.empty_style_cache)
	method_button.add_theme_stylebox_override("disabled", host.empty_style_cache)
	method_button.add_theme_stylebox_override("focus", host.empty_style_cache)
	method_button.z_index = SkillDetailSurface.MODULE_ACTION_ZONE_Z_INDEX + 1
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
		"active_camera_zoom": FISHING_LOCATION_ACTIVE_CAMERA_ZOOM,
		"active_camera_pan": FISHING_LOCATION_ACTIVE_CAMERA_PAN,
		"medal": medal,
		"attempt_bar": null,
		"mastery": mastery_progress,
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
	var padlock_source: Texture2D = host.visual_texture_cache._texture(ActivityLockRig.UNLOCK_PADLOCK_TEXTURE)
	var padlock_texture = ActivityLockRig.cropped_padlock_texture(padlock_source)
	if padlock_texture == null:
		return null
	var padlock_size = FISHING_METHOD_PADLOCK_SIZE
	var lock_root = Control.new()
	lock_root.custom_minimum_size = padlock_size
	lock_root.mouse_filter = Control.MOUSE_FILTER_PASS
	lock_root.anchor_left = 0.5
	lock_root.anchor_right = 0.5
	lock_root.anchor_top = 0.5
	lock_root.anchor_bottom = 0.5
	lock_root.offset_left = -padlock_size.x * 0.5
	lock_root.offset_right = padlock_size.x * 0.5
	lock_root.offset_top = -padlock_size.y * 0.5 - 6.0
	lock_root.offset_bottom = padlock_size.y * 0.5 - 6.0
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
	padlock_shadow.position = Vector2(0, 7)
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

	var tint_mask = host.visual_texture_cache._texture(ActivityLockRig.UNLOCK_LOCK_TINT_MASK_TEXTURE)
	if tint_mask != null:
		var padlock_tint = TextureRect.new()
		padlock_tint.texture = tint_mask
		padlock_tint.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		padlock_tint.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		padlock_tint.size = padlock_size
		var padlock_tint_color: Color = ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE)
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
	padlock_hit_area.gui_input.connect(_on_fishing_method_lock_hit_input.bind(skill_id, action_id, shake_body))
	shake_body.add_child(padlock_hit_area)
	lock_root.set_meta("padlock_button", padlock_hit_area)

	var level_label = ActivityLockRig.new_lock_number()
	level_label.set_text(str(unlock_level))
	level_label.font_size = FISHING_METHOD_PADLOCK_LEVEL_FONT
	level_label.outline_size = FISHING_METHOD_PADLOCK_LEVEL_OUTLINE
	level_label.size = FISHING_METHOD_PADLOCK_LEVEL_SIZE
	level_label.position = Vector2(
		padlock_size.x * 0.5 - FISHING_METHOD_PADLOCK_LEVEL_SIZE.x * 0.5 - 7.5,
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


func _play_padlock_click_shake(shake_body: Control) -> void:
	if shake_body == null or not is_instance_valid(shake_body):
		return
	host._audio_director()._play_padlock_cluster_sfx()
	var pivot_size := shake_body.size
	if pivot_size.length_squared() <= 1.0:
		pivot_size = FISHING_METHOD_PADLOCK_SIZE
	shake_body.pivot_offset = pivot_size * 0.5
	var rest_meta_key := "padlock_shake_rest_position"
	if not shake_body.has_meta(rest_meta_key):
		shake_body.set_meta(rest_meta_key, shake_body.position)
	var base_position: Vector2 = host._app_lifecycle_runtime().meta_vector2(shake_body, rest_meta_key, shake_body.position)
	var base_rotation := 0.0
	var shake_direction := -1.0 if randf() < 0.5 else 1.0
	var tween_meta_key := "padlock_shake_tween"
	host._app_lifecycle_runtime()._kill_meta_tween(shake_body, tween_meta_key)
	shake_body.position = base_position
	shake_body.rotation = base_rotation
	var tween: Tween = host.create_tween()
	shake_body.set_meta(tween_meta_key, tween)
	var shake_body_id := shake_body.get_instance_id()
	tween.tween_method(_apply_padlock_click_shake_frame.bind(shake_body_id, base_position, base_rotation, shake_direction), 0.0, 1.0, host.ACTIVITY_PADLOCK_CLICK_SHAKE_SECONDS).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_finish_padlock_click_shake.bind(shake_body_id, base_position, base_rotation, tween_meta_key))


func _apply_padlock_click_shake_frame(progress: float, shake_body_id: int, base_position: Vector2, base_rotation: float, shake_direction: float) -> void:
	var body: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(shake_body_id))
	if body == null:
		return
	var shake_pct := 1.0 - progress
	var shake_wave := sin((1.0 - shake_pct) * PI * 7.0) * shake_pct * shake_direction
	body.position = base_position + Vector2(shake_wave * 10.0, absf(shake_wave) * 3.0)
	body.rotation = base_rotation + shake_wave * 0.085


func _finish_padlock_click_shake(shake_body_id: int, base_position: Vector2, base_rotation: float, tween_meta_key: String) -> void:
	var body: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(shake_body_id))
	if body == null:
		return
	body.position = base_position
	body.rotation = base_rotation
	if body.has_meta(tween_meta_key):
		body.remove_meta(tween_meta_key)


func _fishing_padlock_unlock_fall_progress(drop_progress: float) -> float:
	var elapsed: float = drop_progress * FISHING_PADLOCK_UNLOCK_DROP_SECONDS
	var fall_delay: float = FISHING_PADLOCK_UNLOCK_POP_SECONDS * 0.72
	var fall_elapsed := maxf(0.0, elapsed - fall_delay)
	return clampf(fall_elapsed / maxf(0.001, FISHING_PADLOCK_UNLOCK_DROP_SECONDS - fall_delay), 0.0, 1.0)


func _fishing_padlock_unlock_pop_scale(pop_progress: float) -> float:
	if pop_progress >= 1.0:
		return 1.0
	var pop := pow(1.0 - pop_progress, 1.35) * 0.14
	var settle := sin(pop_progress * PI) * 0.018
	return 1.0 + pop - settle


func _fishing_padlock_unlock_pop_wiggle(pop_progress: float, direction: float) -> float:
	if pop_progress >= 1.0:
		return 0.0
	var damping := pow(1.0 - pop_progress, 1.55)
	var wave := cos(pop_progress * TAU * 1.65)
	return wave * damping * direction * 0.58


func _apply_fishing_padlock_unlock_drop_frame(shake_body: Control, direction: float, progress: float) -> void:
	if shake_body == null or not is_instance_valid(shake_body) or shake_body.is_queued_for_deletion():
		return
	var padlock_size: Vector2 = FISHING_METHOD_PADLOCK_SIZE
	var drop_progress := clampf(progress, 0.0, 1.0)
	var elapsed: float = drop_progress * FISHING_PADLOCK_UNLOCK_DROP_SECONDS
	var pop_progress := clampf(elapsed / FISHING_PADLOCK_UNLOCK_POP_SECONDS, 0.0, 1.0)
	var fall_progress := _fishing_padlock_unlock_fall_progress(drop_progress)
	var gravity := fall_progress * fall_progress
	var fallover := smoothstep(0.18, 1.0, fall_progress)
	var settling_wobble := sin(fall_progress * PI * 1.75) * 0.045 * (1.0 - fall_progress)
	var pop_wiggle := _fishing_padlock_unlock_pop_wiggle(pop_progress, direction)
	var lock_offset := Vector2(
		direction * 14.0 * fall_progress + pop_wiggle * 6.0,
		padlock_size.y * 0.46 * gravity - absf(pop_wiggle) * 2.0
	)
	var lock_rotation := (0.78 * direction * fallover) + settling_wobble + pop_wiggle * 0.10
	var pop_scale := _fishing_padlock_unlock_pop_scale(pop_progress)
	shake_body.position = lock_offset
	shake_body.rotation = lock_rotation
	shake_body.scale = Vector2.ONE * pop_scale
	shake_body.pivot_offset = padlock_size * 0.5


func _apply_fishing_padlock_unlock_drop_frame_bound(progress: float, shake_body_id: int, direction: float) -> void:
	var shake_body: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(shake_body_id))
	_apply_fishing_padlock_unlock_drop_frame(shake_body, direction, progress)


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
	root.size = Vector2(144, 114)
	root.custom_minimum_size = root.size
	root.position = start - root.size * 0.5
	root.pivot_offset = root.size * 0.5
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.z_index = host.MODAL_OVERLAY_Z
	root.z_as_relative = false
	root.scale = Vector2(0.52, 0.52)
	root.modulate = Color(1, 1, 1, 0)
	canvas.add_child(root)

	var minus_size := Vector2(48, 63)
	var minus_shadow = host._label("-", 58, Color("#171615"), HORIZONTAL_ALIGNMENT_CENTER)
	minus_shadow.size = minus_size
	minus_shadow.position = Vector2(9.5, 26.5)
	minus_shadow.modulate = Color(1, 1, 1, 0.46)
	minus_shadow.add_theme_constant_override("outline_size", 4)
	minus_shadow.add_theme_color_override("font_outline_color", Color(0.09, 0.08, 0.07, 0.75))
	root.add_child(minus_shadow)

	var minus = host._label("-", 58, Color("#fff0a8"), HORIZONTAL_ALIGNMENT_CENTER)
	minus.size = minus_size
	minus.position = Vector2(7, 24)
	minus.add_theme_constant_override("outline_size", 4)
	minus.add_theme_color_override("font_outline_color", host.COLOR_INK)
	root.add_child(minus)

	var icon_size = Vector2(107, 107)
	var icon = host.visual_texture_cache._image_from_texture(texture, icon_size)
	icon.size = icon_size
	icon.position = Vector2(36, 3.5)
	icon.pivot_offset = icon.size * 0.5
	icon.rotation = randf_range(-0.22, 0.22)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(icon)

	var root_id := root.get_instance_id()
	var spin := randf_range(-0.38, 0.38)
	var theme = ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE)
	var tween = host.create_tween()
	tween.set_parallel(true)
	tween.tween_method(Callable(self, "_apply_fish_collection_fly_progress").bind(root_id, start, control, finish, spin), 0.0, 1.0, 0.48).set_trans(Tween.TRANS_LINEAR)
	tween.parallel().tween_property(icon, "modulate", Color(theme.r, theme.g, theme.b, 0.0), 0.18).set_delay(0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(icon, "rotation", icon.rotation + randf_range(-0.62, 0.62), 0.48).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(host._app_lifecycle_runtime()._queue_free_instance_id.bind(root.get_instance_id()))


func _apply_fish_collection_fly_progress(progress: float, root_id: int, start: Vector2, control_point: Vector2, finish: Vector2, spin: float) -> void:
	var node: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(root_id))
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
		host._reward_feedback_surface()._float_reward(parent, anchor, "+%s fish" % GameFormatting.compact_number(maxf(0.0, fish_amount), 3), 58, Color("#8ff8ff"), Vector2(0, -22), Vector2(0, -94), 0.08, false, -1.0, RewardFeedbackSurface.SKILL_REWARD_FLOAT_GROUP)
		return
	var reward_size := Vector2(210, 64)
	var holder := Control.new()
	holder.z_index = RewardFeedbackSurface.REWARD_FLOAT_Z
	holder.z_as_relative = false
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.size = reward_size
	holder.add_to_group(RewardFeedbackSurface.SKILL_REWARD_FLOAT_GROUP)
	parent.add_child(holder)

	var icon_size = Vector2(47, 47)
	var icon_shadow = host.visual_texture_cache._image_from_texture(texture, icon_size)
	icon_shadow.size = icon_size
	icon_shadow.position = Vector2(39, 9)
	icon_shadow.modulate = Color(0.02, 0.02, 0.02, 0.34)
	icon_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(icon_shadow)

	var icon = host.visual_texture_cache._image_from_texture(texture, icon_size)
	icon.size = icon_size
	icon.position = Vector2(37, 7)
	icon.rotation = -0.10
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(icon)

	var text := "+%s" % GameFormatting.compact_number(maxf(0.0, fish_amount), 3)
	var label_size := Vector2(125, 64)
	var shadow = host._label(text, 60, Color("#171615"), HORIZONTAL_ALIGNMENT_LEFT)
	shadow.size = label_size
	shadow.position = Vector2(89, 4.5)
	shadow.modulate = Color(1, 1, 1, 0.34)
	holder.add_child(shadow)
	var label = host._label(text, 60, Color("#8ff8ff"), HORIZONTAL_ALIGNMENT_LEFT)
	label.size = label_size
	label.position = Vector2(87, 2.5)
	label.add_theme_color_override("font_outline_color", host.COLOR_INK)
	label.add_theme_constant_override("outline_size", 5)
	holder.add_child(label)

	var local_pos := anchor.global_position - parent.global_position
	var desired_position := local_pos + Vector2(anchor.size.x * 0.5 - reward_size.x * 0.5, anchor.size.y * 0.18 - reward_size.y * 0.5) + Vector2(0, -22)
	holder.position = host._reward_feedback_surface()._clamp_reward_holder_position(parent, desired_position, reward_size)
	host._reward_feedback_surface()._start_reward_float_tween(holder, Vector2(0, -94), 0.08)


func _attach_fishing_area_module_title(pop_card: Control, title_text: String) -> Label:
	var area_title: Label = host._label(title_text, FISHING_MODULE_TITLE_FONT_SIZE, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	area_title.add_theme_color_override("font_outline_color", host.COLOR_INK)
	area_title.add_theme_constant_override("outline_size", FISHING_MODULE_TITLE_OUTLINE)
	area_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	area_title.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	area_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	area_title.anchor_left = 0.0
	area_title.anchor_right = 1.0
	area_title.anchor_top = 0.0
	area_title.anchor_bottom = 0.0
	area_title.offset_left = FISHING_MODULE_TITLE_LEFT_INSET
	area_title.offset_right = -FISHING_MODULE_TITLE_RIGHT_INSET
	area_title.offset_top = FISHING_MODULE_TITLE_TOP
	area_title.offset_bottom = FISHING_MODULE_TITLE_TOP + FISHING_MODULE_TITLE_BAND_HEIGHT
	area_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area_title.z_index = FISHING_MODULE_TITLE_Z_INDEX
	area_title.z_as_relative = true
	area_title.visible = true
	pop_card.add_child(area_title)
	return area_title


func _fishing_location_tile_style(available: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.draw_center = false
	style.border_color = Color.WHITE if available else Color("#d9cfbc")
	style.border_width_left = 5
	style.border_width_top = 5
	style.border_width_right = 5
	style.border_width_bottom = 5
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	style.shadow_color = Color.TRANSPARENT
	style.shadow_size = 0
	style.shadow_offset = Vector2.ZERO
	return style


func _add_fishing_area_module_corner_crop(parent: Control) -> RoundedCornerCropOverlay:
	var corner_crop := RoundedCornerCropOverlay.new()
	corner_crop.radius = 33.0
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
		rounded_bg.radius = 33.0
		rounded_bg.art_height = host.ACTION_CARD_HEIGHT
		rounded_bg.feather_height = 0.0
		rounded_bg.fallback_color = ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE).darkened(0.12)
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
	margin.add_theme_constant_override("margin_left", 27)
	margin.add_theme_constant_override("margin_right", 27)
	margin.add_theme_constant_override("margin_top", FISHING_AREA_CONTENT_TOP_MARGIN)
	margin.add_theme_constant_override("margin_bottom", FISHING_AREA_WATER_BOTTOM_MARGIN)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.z_index = 200
	pop_card.add_child(margin)

	var layout_column := VBoxContainer.new()
	layout_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout_column.add_theme_constant_override("separation", 5)
	layout_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(layout_column)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 14)
	top_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout_column.add_child(top_row)

	var method_slot := MarginContainer.new()
	method_slot.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	method_slot.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	method_slot.add_theme_constant_override("margin_top", FISHING_AREA_METHOD_TOP_MARGIN)
	method_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(method_slot)

	var method_row := HBoxContainer.new()
	method_row.add_theme_constant_override("separation", 14)
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
	stat_slot.add_theme_constant_override("margin_top", FISHING_AREA_STAT_COLUMN_TOP_MARGIN)
	stat_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(stat_slot)

	var stat_column := VBoxContainer.new()
	stat_column.add_theme_constant_override("separation", 14)
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
	water_strip_host.offset_top = -FISHING_FLUID_STRIP_HEIGHT
	water_strip_host.offset_bottom = FISHING_FLUID_STRIP_BOTTOM_INSET
	water_strip_host.clip_contents = true
	water_strip_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	water_strip_host.visible = false
	water_strip_host.z_index = FISHING_FLUID_STRIP_Z_INDEX
	pop_card.add_child(water_strip_host)
	var fluid_strip: Control = _attach_fishing_fluid_strip(water_strip_host, {"id": selected_id})
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

	var status: Label = host._label("", host.MIN_MOBILE_HELP_FONT_SIZE, host.COLOR_RED, HORIZONTAL_ALIGNMENT_LEFT)
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
	if host.fishing_runtime.area_uses_location_tiles(area_def, FishingState.FISHING_LOCATION_DEFS):
		method_source_ids = []
		for raw_location in host.fishing_runtime.locations_for_area_module(area_def, FishingState.FISHING_LOCATION_DEFS):
			var location := raw_location as Dictionary
			if not host.fishing_runtime.location_should_show(host, area_id, location, FishingState.FISHING_LOCATION_DEFS, FishingState.FISHING_TOOL_LOCATION_ACTIONS):
				continue
			var location_card := _build_fishing_location_tile(skill_id, area_id, area_key, location, method_row)
			if location_card.is_empty():
				continue
			var location_hit_control := location_card.get("method_hit_control") as Control
			if location_hit_control != null and is_instance_valid(location_hit_control):
				location_hit_control.set_meta("fishing_area_method_ready_marker", true)
			var location_action_id := str(location_card.get("action_id", ""))
			var location_ui_key := "%s:location-%s-%s" % [skill_id, area_id, str(location.get("id", ""))]
			host._skill_detail_surface()._register_action_card(location_ui_key, location_card)
			method_slots[location_action_id] = location_card

	for method_id in method_source_ids:
		var action_id := str(method_id)
		if not method_should_show(skill_id, action_id):
			continue
		var action: Dictionary = host._action_data(skill_id, action_id)
		if action.is_empty():
			continue
		var method_card := _build_fishing_area_action_method_tile(skill_id, area_key, area_bg_path, action_id, action, method_row, status)
		host._skill_detail_surface()._register_action_card(host._action_key(skill_id, action_id), method_card)
		method_slots[action_id] = method_card
	return method_slots


func _fishing_area_queue_overlay_host(method_slots: Dictionary, selected_id: String) -> Control:
	var selected_method_card := method_slots.get(selected_id, {}) as Dictionary
	if selected_method_card.is_empty():
		return null
	var queue_overlay_host: Control = host._app_lifecycle_runtime().valid_control_ref(selected_method_card.get("method_image_hit_control", null))
	if queue_overlay_host == null:
		queue_overlay_host = host._app_lifecycle_runtime().valid_control_ref(selected_method_card.get("art_panel", null))
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
				fishing_unlock_preview_fade_marker_ids.has(action_id)
				and not action.is_empty()
				and not host._activity_unlock_runtime()._is_action_unlocked(skill_id, action)
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


func _activate_fishing_method_button(method_card: Dictionary, owner_area_pop_instance_id := 0) -> void:
	if method_card.is_empty():
		return
	var method_button := method_card.get("method_button") as Button
	if method_button == null or not is_instance_valid(method_button) or method_button.is_queued_for_deletion():
		return
	host._app_lifecycle_runtime().set_base_button_disabled_if_changed(method_button, false)
	method_button.mouse_filter = Control.MOUSE_FILTER_STOP if host.current_screen == "pinned" else Control.MOUSE_FILTER_IGNORE
	var skill_id := str(method_card.get("skill_id", ""))
	var action_id := str(method_card.get("action_id", ""))
	var area_key := str(method_card.get("fishing_area_key", ""))
	if not bool(method_button.get_meta("fishing_method_pressed_connected", false)):
		method_button.gui_input.connect(_on_fishing_method_button_input.bind(skill_id, action_id, area_key, owner_area_pop_instance_id, method_button))
		host.button_press_runtime.attach_default_button_sfx(method_button)
		method_button.set_meta("fishing_method_pressed_connected", true)
	var art_panel := method_card.get("art_panel", null) as Control
	if art_panel != null and is_instance_valid(art_panel) and not art_panel.is_queued_for_deletion():
		art_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		if not bool(art_panel.get_meta("fishing_method_art_pressed_connected", false)):
			art_panel.gui_input.connect(_on_fishing_method_button_input.bind(skill_id, action_id, area_key, owner_area_pop_instance_id, method_button))
			art_panel.set_meta("fishing_method_art_pressed_connected", true)


func _sync_fishing_method_card_unlocked_live(method_card: Dictionary, owner_area_pop_instance_id := 0) -> void:
	if method_card.is_empty():
		return
	method_card["unlock_ready_pending"] = false
	method_card["unlock_ceremony_pending"] = false
	var art := method_card.get("art", null) as CanvasItem
	if art != null and is_instance_valid(art):
		art.modulate = Color.WHITE
	var art_panel := method_card.get("art_panel", null) as Panel
	if art_panel != null and is_instance_valid(art_panel):
		art_panel.add_theme_stylebox_override("panel", _fishing_location_tile_style(true))
	var lock_root := method_card.get("lock_root", null) as Control
	if lock_root != null and is_instance_valid(lock_root):
		var padlock_hit_area := lock_root.get_meta("padlock_button") as Control
		if padlock_hit_area != null and is_instance_valid(padlock_hit_area):
			padlock_hit_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_activate_fishing_method_button(method_card, owner_area_pop_instance_id)


func _on_fishing_method_lock_hit_input(event: InputEvent, skill_id: String, action_id: String, shake_body: Control = null) -> void:
	var pressed := false
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		pressed = mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed
	elif event is InputEventScreenTouch:
		pressed = (event as InputEventScreenTouch).pressed
	if not pressed:
		return
	_on_fishing_method_lock_pressed(skill_id, action_id, shake_body)
	var viewport: Viewport = host.get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()


func _queue_fishing_unlock_visible_mount(action_id: String) -> void:
	if host.current_screen != "skill" or host.selected_skill_id != "fishing":
		return
	if not host._fishing_rework_active_for_skill("fishing"):
		return
	var mount_ids := [str(action_id)]
	var next_preview_id: String = host.fishing_runtime.first_locked_location_action_after_manual_unlock(host, str(action_id), "", host.fishing_runtime.FISHING_LOCATION_DEFS, host.fishing_runtime.FISHING_TOOL_LOCATION_ACTIONS)
	if not next_preview_id.is_empty():
		mount_ids.append(next_preview_id)
		if not fishing_unlock_preview_fade_marker_ids.has(next_preview_id):
			fishing_unlock_preview_fade_marker_ids.append(next_preview_id)
	for raw_mount_id in mount_ids:
		var mount_id := str(raw_mount_id)
		if mount_id.is_empty() or fishing_unlock_visible_mount_ids.has(mount_id):
			continue
		fishing_unlock_visible_mount_ids.append(mount_id)
	_ensure_queued_fishing_unlock_entries_mounted()
	call_deferred("_ensure_queued_fishing_unlock_entries_mounted")


func _ensure_queued_fishing_unlock_entries_mounted() -> void:
	if fishing_unlock_visible_mount_ids.is_empty():
		return
	if host.current_screen != "skill" or host.selected_skill_id != "fishing" or host._skill_detail_surface().detail_lazy_plan.is_empty():
		return
	for raw_mount_id in fishing_unlock_visible_mount_ids:
		var mount_id := str(raw_mount_id)
		if mount_id.is_empty():
			continue
		host._skill_detail_surface()._ensure_detail_lazy_entry_mounted(mount_id)
		var mount_action: Dictionary = host._action_data("fishing", mount_id)
		if mount_action.is_empty() or host._activity_unlock_runtime()._is_action_unlocked("fishing", mount_action):
			continue
		if not fishing_unlock_preview_fade_marker_ids.has(mount_id):
			fishing_unlock_preview_fade_marker_ids.append(mount_id)
		host._activity_unlock_ceremony_surface().stage_preview_for_action_id(mount_id, false)


func _fishing_method_padlock_shake_body(skill_id: String, action_id: String, preferred_shake_body: Control = null) -> Control:
	var preferred: Control = host._app_lifecycle_runtime().valid_control_ref(preferred_shake_body)
	if preferred != null and preferred.is_inside_tree():
		return preferred
	var method_card := _fishing_method_card_for_action(skill_id, action_id)
	var lock_root: Control = host._app_lifecycle_runtime().valid_control_ref(method_card.get("lock_root", null)) if not method_card.is_empty() else null
	var shake_body := _fishing_method_padlock_shake_body_from_root(lock_root)
	if shake_body != null:
		return shake_body
	for raw_card in host.action_cards.values():
		if typeof(raw_card) != TYPE_DICTIONARY:
			continue
		var card := raw_card as Dictionary
		if not bool(card.get("is_fishing_method", false)):
			continue
		if str(card.get("skill_id", "")) != skill_id or str(card.get("action_id", "")) != action_id:
			continue
		shake_body = _fishing_method_padlock_shake_body_from_root(host._app_lifecycle_runtime().valid_control_ref(card.get("lock_root")))
		if shake_body != null:
			return shake_body
	return null


func _fishing_method_padlock_shake_body_from_root(lock_root: Control) -> Control:
	if lock_root == null or not is_instance_valid(lock_root) or not lock_root.is_inside_tree():
		return null
	if not lock_root.visible or not lock_root.is_visible_in_tree():
		return null
	return host._app_lifecycle_runtime().valid_control_ref(lock_root.get_meta("padlock_shake_body"))


func _fishing_method_card_for_action(skill_id: String, action_id: String) -> Dictionary:
	var direct = host.action_cards.get(host._action_key(skill_id, action_id))
	if typeof(direct) == TYPE_DICTIONARY:
		return direct as Dictionary
	for raw_key in host.action_cards.keys():
		var raw_card = host.action_cards.get(raw_key)
		if typeof(raw_card) != TYPE_DICTIONARY:
			continue
		var card := raw_card as Dictionary
		if not card.get("is_fishing_method"):
			continue
		if str(card.get("skill_id", "")) == skill_id and str(card.get("action_id", "")) == action_id:
			return card
	for raw_card in host.action_cards.values():
		if typeof(raw_card) != TYPE_DICTIONARY:
			continue
		var area_card := raw_card as Dictionary
		if not bool(area_card.get("is_fishing_area", false)):
			continue
		if str(area_card.get("skill_id", "")) != skill_id:
			continue
		for raw_method_card in (area_card.get("method_slots", {}) as Dictionary).values():
			if typeof(raw_method_card) != TYPE_DICTIONARY:
				continue
			var method_card := raw_method_card as Dictionary
			if not bool(method_card.get("is_fishing_method", false)):
				continue
			if str(method_card.get("skill_id", "")) == skill_id and str(method_card.get("action_id", "")) == action_id:
				return method_card
	return {}


func _finish_fishing_method_unlock_ceremony(method_card: Dictionary, refresh_detail: bool) -> void:
	if method_card.is_empty() or bool(method_card.get("unlock_ceremony_finalized", false)):
		return
	method_card["unlock_ceremony_finalized"] = true
	var pending_skill_id := str(method_card.get("manual_unlock_pending_skill_id", method_card.get("skill_id", host.selected_skill_id)))
	var pending_action_id := str(method_card.get("manual_unlock_pending_action_id", method_card.get("action_id", "")))
	host._activity_unlock_runtime().clear_pending_readiness_action(pending_skill_id, pending_action_id)
	if not host._activity_unlock_runtime()._finalize_manual_activity_unlock_for_card(method_card, "fishing method unlock"):
		host._activity_unlock_runtime()._finalize_manual_activity_unlock(pending_skill_id, pending_action_id, "fishing method unlock")
	var method_button := method_card.get("method_button") as Button
	if method_button != null and is_instance_valid(method_button):
		_activate_fishing_method_button(method_card)
	method_card["unlock_ceremony_active"] = false
	host._activity_unlock_ceremony_surface().ceremony_count = maxi(0, host._activity_unlock_ceremony_surface().ceremony_count - 1)
	host._activity_unlock_runtime()._schedule_auto_unlock_pending_lockpads()
	if refresh_detail and host._activity_unlock_ceremony_surface().ceremony_count <= 0:
		host._activity_unlock_ceremony_surface().detail_refresh_done = false
		host.call_deferred("_refresh_skill_detail_after_activity_unlock_ceremony")


func _run_fishing_method_unlock_drop_motion(method_card: Dictionary) -> void:
	await host.get_tree().create_timer(ActivityUnlockCeremonySurface.MOTION_START_DELAY).timeout
	if method_card.is_empty() or bool(method_card.get("unlock_ceremony_finalized", false)):
		return
	if host.current_screen != "skill":
		_finish_fishing_method_unlock_ceremony(method_card, false)
		return
	var lock_root := method_card.get("lock_root") as Control
	if lock_root == null or not is_instance_valid(lock_root) or lock_root.is_queued_for_deletion():
		_finish_fishing_method_unlock_ceremony(method_card, true)
		return
	var shake_body := lock_root.get_meta("padlock_shake_body") as Control
	if shake_body == null or not is_instance_valid(shake_body) or shake_body.is_queued_for_deletion():
		_finish_fishing_method_unlock_ceremony(method_card, true)
		return
	host._app_lifecycle_runtime()._kill_meta_tween(shake_body, "padlock_shake_tween")
	host._audio_director()._play_padlock_cluster_sfx()
	shake_body.modulate = Color.WHITE
	shake_body.position = Vector2.ZERO
	shake_body.rotation = 0.0
	shake_body.scale = Vector2.ONE
	var direction := -1.0 if randf() < 0.5 else 1.0
	var drop_tween: Tween = host.create_tween()
	var shake_body_id := shake_body.get_instance_id()
	drop_tween.tween_method(
		Callable(self, "_apply_fishing_padlock_unlock_drop_frame_bound").bind(shake_body_id, direction),
		0.0,
		1.0,
		FISHING_PADLOCK_UNLOCK_DROP_SECONDS
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var fade_tween: Tween = host.create_tween()
	var fade_delay := FISHING_PADLOCK_UNLOCK_DROP_SECONDS * 0.58
	var fade_seconds := maxf(0.08, FISHING_PADLOCK_UNLOCK_DROP_SECONDS - fade_delay)
	fade_tween.tween_property(shake_body, "modulate:a", 0.0, fade_seconds).set_delay(fade_delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fade_tween.finished.connect(_finish_fishing_method_unlock_ceremony_by_action.bind(
		str(method_card.get("skill_id", "fishing")),
		str(method_card.get("action_id", "")),
		true
	))


func _finish_fishing_method_unlock_ceremony_by_action(skill_id: String, action_id: String, refresh_detail: bool) -> void:
	var method_card := _fishing_method_card_for_action(skill_id, action_id)
	if not method_card.is_empty():
		_finish_fishing_method_unlock_ceremony(method_card, refresh_detail)
		return
	host._activity_unlock_runtime().clear_pending_readiness_action(skill_id, action_id)
	host._activity_unlock_runtime()._finalize_manual_activity_unlock(skill_id, action_id, "fishing method unlock")
	host._activity_unlock_ceremony_surface().ceremony_count = maxi(0, host._activity_unlock_ceremony_surface().ceremony_count - 1)
	host._activity_unlock_runtime()._schedule_auto_unlock_pending_lockpads()
	if refresh_detail and host._activity_unlock_ceremony_surface().ceremony_count <= 0:
		host._activity_unlock_ceremony_surface().detail_refresh_done = false
		host.call_deferred("_refresh_skill_detail_after_activity_unlock_ceremony")


func _play_fishing_method_unlock_ceremony(method_card: Dictionary) -> void:
	if method_card.is_empty() or bool(method_card.get("unlock_ceremony_active", false)):
		return
	method_card["unlock_ceremony_pending"] = false
	method_card["unlock_ready_pending"] = false
	method_card["unlock_ceremony_active"] = true
	method_card["unlock_ceremony_finalized"] = false
	host._activity_unlock_ceremony_surface().ceremony_count += 1
	var method_button := method_card.get("method_button") as Button
	if method_button != null and is_instance_valid(method_button):
		var skill_id := str(method_card.get("skill_id", "fishing"))
		var action: Dictionary = host._action_data(skill_id, str(method_card.get("action_id", "")))
		if not host._activity_unlock_runtime()._is_action_unlocked(skill_id, action):
			host._app_lifecycle_runtime().set_base_button_disabled_if_changed(method_button, true)
	var lock_root := method_card.get("lock_root") as Control
	if lock_root != null:
		var padlock_hit_area := lock_root.get_meta("padlock_button") as Control
		if padlock_hit_area != null:
			padlock_hit_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_run_fishing_method_unlock_drop_motion(method_card)


func _on_fishing_method_lock_pressed(skill_id: String, action_id: String, preferred_shake_body: Control = null) -> void:
	var action: Dictionary = host._action_data(skill_id, action_id)
	if action.is_empty() or host._activity_unlock_runtime()._is_action_unlocked(skill_id, action):
		return
	var method_card := _fishing_method_card_for_action(skill_id, action_id)
	var shake_body := _fishing_method_padlock_shake_body(skill_id, action_id, preferred_shake_body)
	host._onboarding_runtime()._mark_lock_click_tip_seen()
	if not host._activity_unlock_runtime()._can_unlock_action(skill_id, action):
		if shake_body != null and is_instance_valid(shake_body):
			_play_padlock_click_shake(shake_body)
		host._reward_feedback_surface()._set_result("%s needs %s." % [str(action.get("name", "Method")), host._skill_detail_surface()._missing_action_requirements_text(skill_id, action)])
		return
	host._activity_unlock_ceremony_surface().detail_refresh_done = false
	var preview_after_unlock: String = host._onboarding_runtime()._tutorial_preview_after_manual_unlock(skill_id, action_id)
	if host._fishing_rework_active_for_skill(skill_id) and not preview_after_unlock.is_empty():
		host._activity_unlock_ceremony_surface().clear_preview_reveal_guards()
	host._activity_unlock_ceremony_surface().set_preview_after_ceremony(preview_after_unlock)
	var preview_id: String = host._activity_unlock_ceremony_surface().preview_after_ceremony_id
	if not preview_id.is_empty():
		host._activity_unlock_ceremony_surface().prestage_preview_card(preview_id)
	if host._skill_detail_surface()._lock_click_tip_remaining_collapse_seconds() > 0.0:
		host._skill_detail_surface()._stage_next_locked_activity_preview_after_tip_collapse(preview_id)
	var ceremony_started := false
	if method_card != null and method_card.get("lock_root") != null:
		host._activity_unlock_runtime()._queue_manual_activity_unlock_for_ceremony(method_card, skill_id, action_id)
		host._activity_unlock_runtime().clear_pending_readiness_action(skill_id, action_id)
		host._activity_unlock_runtime()._finalize_manual_activity_unlock(skill_id, action_id, "fishing method unlock")
		var owner_area_card := _fishing_area_card_for_action(skill_id, action_id)
		var owner_pop := owner_area_card.get("pop", null) as Control
		var owner_area_pop_instance_id := owner_pop.get_instance_id() if owner_pop != null and is_instance_valid(owner_pop) else 0
		_sync_fishing_method_card_unlocked_live(method_card, owner_area_pop_instance_id)
		_play_fishing_method_unlock_ceremony(method_card)
		ceremony_started = true
	else:
		host._activity_unlock_runtime().clear_pending_readiness_action(skill_id, action_id)
		host._activity_unlock_runtime()._finalize_manual_activity_unlock(skill_id, action_id, "fishing method unlock")
		host.call_deferred("_refresh_skill_detail_after_activity_unlock_ceremony")
	host._reward_feedback_surface()._set_result("%s unlocked." % str(action.get("name", "Method")))
	if not ceremony_started:
		host._mark_save_dirty("fishing method unlock")


func _play_fishing_location_tile_wiggle(method_card: Dictionary) -> void:
	if bool(method_card.get("is_fishing_location", false)) or bool(method_card.get("fixed_layout", false)):
		return
	var target := method_card.get("wiggle_root") as Control
	if target == null or not is_instance_valid(target):
		target = method_card.get("art_panel") as Control
	if target == null or not is_instance_valid(target):
		return
	target.pivot_offset = target.size * 0.5
	host._app_lifecycle_runtime()._kill_meta_tween(target, "fishing_tile_wiggle_tween")
	target.rotation = 0.0
	target.scale = Vector2.ONE
	var direction := -1.0 if randf() < 0.5 else 1.0
	var tween: Tween = host.create_tween()
	target.set_meta("fishing_tile_wiggle_tween", tween)
	tween.tween_property(target, "rotation", 0.035 * direction, 0.09).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(target, "scale", Vector2(1.025, 1.025), 0.09).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "rotation", -0.024 * direction, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(target, "rotation", 0.0, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(target, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_finish_fishing_location_tile_wiggle.bind(target.get_instance_id()))


func _finish_fishing_location_tile_wiggle(target_id: int) -> void:
	var target: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(target_id))
	if target != null:
		target.rotation = 0.0
		target.scale = Vector2.ONE
		if target.has_meta("fishing_tile_wiggle_tween"):
			target.remove_meta("fishing_tile_wiggle_tween")


func _fishing_area_stat_fade_controls(area_card: Dictionary) -> Array:
	var controls: Array = []
	var stat_column := area_card.get("stat_column") as Control
	if stat_column != null and is_instance_valid(stat_column):
		controls.append(stat_column)
	for raw_button in (area_card.get("stat_hit_buttons", {}) as Dictionary).values():
		var button := raw_button as Control
		if button != null and is_instance_valid(button):
			controls.append(button)
	return controls


func _set_fishing_area_stats_visible(area_card: Dictionary, should_show: bool, _delta: float, instant: bool) -> void:
	var target_alpha := 1.0 if should_show else 0.0
	host._app_lifecycle_runtime()._kill_card_tween(area_card, "stat_fade_tween")
	var controls := _fishing_area_stat_fade_controls(area_card)
	if controls.is_empty():
		return
	if instant:
		for control in controls:
			host._app_lifecycle_runtime().set_canvas_item_alpha_if_changed(control, target_alpha)
		area_card["stats_visible"] = should_show
		return
	var lead := controls[0] as Control
	if absf(lead.modulate.a - target_alpha) < 0.02:
		area_card["stats_visible"] = should_show
		return
	var tween: Tween = host.create_tween()
	area_card["stat_fade_tween"] = tween
	tween.set_parallel(true)
	for control in controls:
		tween.tween_property(control, "modulate:a", target_alpha, FISHING_AREA_STAT_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_finish_fishing_area_stats_visible.bind(str(area_card.get("card_key", "")), should_show))


func _finish_fishing_area_stats_visible(card_key: String, should_show: bool) -> void:
	var area_card := host.action_cards.get(card_key, {}) as Dictionary
	if area_card.is_empty():
		return
	area_card.erase("stat_fade_tween")
	area_card["stats_visible"] = should_show


func _fishing_area_stat_hit_buttons(pop_card: Control, _skill_id: String, _area_key: String, _method_count: int) -> Dictionary:
	var hit_buttons := {}
	var kinds := ["xp", "yield"]
	var button_size := Vector2(150, 111)
	var right_inset := 54.0
	var stack_top: float = FISHING_AREA_STAT_COLUMN_TOP_MARGIN
	var stack_step := button_size.y + 28.0
	for i in range(kinds.size()):
		var kind := str(kinds[i])
		var button := Button.new()
		button.text = ""
		button.focus_mode = Control.FOCUS_NONE
		button.flat = true
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.anchor_left = 1.0
		button.anchor_right = 1.0
		button.anchor_top = 0.0
		button.anchor_bottom = 0.0
		button.offset_left = -(right_inset + button_size.x)
		button.offset_right = -right_inset
		button.offset_top = stack_top + float(i) * stack_step
		button.offset_bottom = button.offset_top + button_size.y
		button.z_index = 219
		button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		pop_card.add_child(button)
		button.modulate.a = 0.0
		hit_buttons[kind] = button
	return hit_buttons


func _sync_fishing_area_stat_hit_buttons(area_card: Dictionary, running: bool) -> void:
	var selected_id := str(area_card.get("selected_action_id", ""))
	var enabled := false and running and not selected_id.is_empty()
	for raw_button in (area_card.get("stat_hit_buttons", {}) as Dictionary).values():
		var button := raw_button as Button
		if button == null or not is_instance_valid(button):
			continue
		if bool(button.get_meta("fishing_area_stat_enabled", false)) == enabled:
			continue
		button.set_meta("fishing_area_stat_enabled", enabled)
		host._app_lifecycle_runtime().set_base_button_disabled_if_changed(button, not enabled)
		if button.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _apply_fishing_area_selection(area_card: Dictionary, action_id: String, instant := false) -> void:
	var skill_id := str(area_card.get("skill_id", "fishing"))
	var action: Dictionary = host._action_data(skill_id, action_id)
	if action.is_empty():
		return
	var warning_text: String = host.fishing_runtime.tool_warning_text(action_id)
	var xp_text := "+%s" % GameFormatting.info_chip_number(float(host.fishing_runtime.flat_xp_reward(host, action, skill_id)))
	if not warning_text.is_empty():
		xp_text = warning_text.replace(" ", "\n")
	var yield_title := "FISH"
	var yield_text: String = host.fishing_runtime.yield_label(host, action, host.fishing_runtime.equipped_tool_id, FishingState.FISHING_NET_HAUL_THRESHOLD)
	if host.fishing_runtime.equipped_tool_id == "net" and not FishingState.tool_catches_nothing_for_action(host.fishing_runtime.equipped_tool_id, action_id):
		yield_text = "%s/%s" % [mini(host.fishing_runtime.net_stored_fish, FishingState.FISHING_NET_HAUL_THRESHOLD), FishingState.FISHING_NET_HAUL_THRESHOLD]
		yield_title = "NET"
	if host.fishing_runtime.equipped_tool_id == "boat" and not FishingState.tool_catches_nothing_for_action(host.fishing_runtime.equipped_tool_id, action_id):
		yield_text = "%s/%s" % [mini(host.fishing_runtime.boat_stored_fish, FishingState.FISHING_BOAT_HAUL_THRESHOLD), FishingState.FISHING_BOAT_HAUL_THRESHOLD]
		yield_title = "BOAT"
	var running_here: bool = host.running_skill_id == skill_id and host.running_action_id == action_id
	var selection_key := "%s:%s:%s:%s:%s" % [action_id, xp_text, yield_text, yield_title, warning_text]
	var border_key := "%s:%s" % [action_id, running_here]
	if (
		not instant
		and str(area_card.get("selection_sync_key", "")) == selection_key
		and str(area_card.get("selection_border_key", "")) == border_key
	):
		return
	area_card["selection_sync_key"] = selection_key
	area_card["selection_border_key"] = border_key
	area_card["selected_action_id"] = action_id
	var xp_label := area_card.get("area_xp") as Label
	if xp_label != null:
		if warning_text.is_empty():
			host._skill_detail_surface()._sync_action_stat_chip_title(xp_label, "XP")
			host._skill_detail_surface()._sync_action_stat_chip_label_style(xp_label, host._skill_swipe_activity_surface()._action_stat_chip_buffed(skill_id, action, "xp"), ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE))
		else:
			host._skill_detail_surface()._sync_action_stat_chip_label_style(xp_label, false, ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE))
			xp_label.add_theme_color_override("font_color", Color("#b82121"))
			xp_label.add_theme_constant_override("outline_size", 0)
			host._skill_detail_surface()._sync_action_stat_chip_title(xp_label, "")
		host._app_lifecycle_runtime().set_label_text_if_changed(xp_label, xp_text)
	var yield_label := area_card.get("area_yield") as Label
	if yield_label != null:
		host._skill_detail_surface()._sync_action_stat_chip_title(yield_label, yield_title)
		host._app_lifecycle_runtime().set_label_text_if_changed(yield_label, yield_text)
	var warning_label := area_card.get("area_warning") as Label
	if warning_label != null:
		host._app_lifecycle_runtime().set_label_text_if_changed(warning_label, warning_text)
	var warning_box := area_card.get("area_warning_box") as Control
	if warning_box != null:
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(warning_box, not warning_text.is_empty())
	var border = area_card.get("border")
	if border != null:
		border.border_color = Color("#1f6f4a") if running_here else host.COLOR_INK
		border.queue_redraw()


func _update_fishing_area_module(area_card: Dictionary, skill_id: String, running: bool, delta: float, instant: bool) -> void:
	if _fishing_ablation_enabled("no_fishing_updates"):
		return
	if (
		host._skill_detail_surface().detail_scroll_visual_work_this_frame
		and not running
		and not bool(area_card.get("stats_running", false))
		and not _fishing_area_has_active_camera_return(area_card)
	):
		return
	if running and not host.running_action_id.is_empty():
		if _fishing_area_card_owns_action(area_card, host.running_action_id):
			if host.running_action_id != str(area_card.get("selected_action_id", "")):
				_apply_fishing_area_selection(area_card, host.running_action_id, instant)
	var stats_running := running
	if bool(area_card.get("stats_running", false)) != stats_running:
		area_card["stats_running"] = stats_running
		if stats_running:
			var show_id: String = host.running_action_id
			if show_id.is_empty():
				show_id = str(area_card.get("selected_action_id", ""))
			if not show_id.is_empty():
				_apply_fishing_area_selection(area_card, show_id, instant)
		_set_fishing_area_stats_visible(area_card, stats_running, delta, instant)
	_sync_fishing_area_stat_hit_buttons(area_card, stats_running)
	if host._skill_detail_surface().detail_scroll_visual_work_this_frame and not running and not _fishing_area_has_active_camera_return(area_card):
		return
	_update_fishing_active_tool_animation(area_card, running, delta, instant)
	host._skill_swipe_activity_surface()._update_action_card_run_feedback(area_card, skill_id, running, delta, instant)
	_update_fishing_area_method_slots(area_card, skill_id, delta, instant)


func _update_fishing_area_method_slots(area_card: Dictionary, skill_id: String, delta: float, instant: bool) -> void:
	for raw_method_card in (area_card.get("method_slots", {}) as Dictionary).values():
		var method_card := raw_method_card as Dictionary
		if method_card.is_empty():
			continue
		var action_id := str(method_card.get("action_id", ""))
		if action_id.is_empty():
			continue
		var method_action: Dictionary = host._action_data(skill_id, action_id)
		var method_unlocked: bool = host._activity_unlock_runtime()._is_action_unlocked(skill_id, method_action)
		var method_running: bool = host.running_skill_id == skill_id and host.running_action_id == action_id
		if bool(method_card.get("is_fishing_location", false)):
			method_running = (
				method_running
				and str(host.fishing_runtime.selected_locations.get(str(method_card.get("area_id", "")), "")) == str(method_card.get("location_id", ""))
			)
		if float(method_card.get("active_camera_zoom", 0.0)) > 1.0 and bool(method_card.get("active_camera_was_running", false)) and not method_running:
			method_card["active_camera_returning"] = true
		if host._skill_detail_surface().detail_scroll_visual_work_this_frame and not method_running and not bool(method_card.get("active_camera_returning", false)):
			continue
		_update_fishing_method_slot(method_card, skill_id, action_id, method_action, method_unlocked, method_running, delta, instant)


func _fishing_area_has_active_camera_return(area_card: Dictionary) -> bool:
	for raw_method_card in (area_card.get("method_slots", {}) as Dictionary).values():
		var method_card := raw_method_card as Dictionary
		if method_card.is_empty():
			continue
		if bool(method_card.get("active_camera_returning", false)):
			return true
		if float(method_card.get("active_camera_zoom", 0.0)) > 1.0 and bool(method_card.get("active_camera_was_running", false)):
			return true
	return false


func _update_fishing_method_slot(
	card: Dictionary,
	skill_id: String,
	action_id: String,
	_action: Dictionary,
	_unlocked: bool,
	running: bool,
	delta: float,
	instant: bool
) -> void:
	var status := card.get("status") as Label
	if status != null:
		host._app_lifecycle_runtime().set_label_text_if_changed(status, "")
	var medal := card.get("medal") as TextureRect
	var mastery_action_id := str(card.get("mastery_action_id", action_id))
	var mastery_level := MasteryState.level(host.mastery, host._action_key(skill_id, mastery_action_id))
	host._skill_swipe_activity_surface()._set_action_card_medal(card, medal, mastery_level, instant)
	host._skill_swipe_activity_surface()._update_action_card_mastery_bar(card, skill_id, mastery_action_id, delta, instant)
	var art_panel := card.get("art_panel") as CanvasItem
	if art_panel != null:
		host._app_lifecycle_runtime().set_canvas_item_modulate_if_changed(art_panel, Color.WHITE)
	var active_art := card.get("art") as Control
	_update_fishing_method_active_art(card, active_art, running, delta, instant)
	_update_fishing_method_attempt_bar(card, action_id, running, instant)
	var area_key := str(card.get("fishing_area_key", ""))
	var area_card_variant = host.action_cards.get(area_key, null)
	if typeof(area_card_variant) == TYPE_DICTIONARY:
		var area_card := area_card_variant as Dictionary
		if str(area_card.get("selected_action_id", "")) == action_id:
			_apply_fishing_area_selection(area_card, action_id, instant)


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
		if host._activity_unlock_runtime()._is_action_unlocked(skill_id, method_card.get("action", {}) as Dictionary):
			_activate_fishing_method_button(method_card, pop_card.get_instance_id())
	_apply_fishing_area_selection(area_card, selected_id, true)
	_set_fishing_area_stats_visible(area_card, false, 0.0, true)
	_sync_fishing_area_stat_hit_buttons(area_card, false)


func _build_fishing_area_module(skill_id: String, area_def: Dictionary, content_width: float) -> Dictionary:
	var area_id := str(area_def.get("id", ""))
	var area_key = host.fishing_runtime.area_module_key(skill_id, area_def)
	var selected_id = host.fishing_runtime.area_default_method(host, skill_id, area_def, FishingState.FISHING_LOCATION_DEFS, FishingState.FISHING_TOOL_LOCATION_ACTIONS)
	if host.fishing_runtime.area_uses_location_tiles(area_def, FishingState.FISHING_LOCATION_DEFS) and str(host.fishing_runtime.selected_locations.get(area_id, "")).is_empty():
		host.fishing_runtime.selected_locations[area_id] = host.fishing_runtime.selected_location_id(host, area_def, FishingState.FISHING_LOCATION_DEFS, FishingState.FISHING_TOOL_LOCATION_ACTIONS)

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
	var stat_hit_buttons = _fishing_area_stat_hit_buttons(pop_card, skill_id, area_key, method_slots.size())
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
	var flyer = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(art_id))
	if flyer != null:
		flyer.scale = Vector2.ONE
		flyer.modulate = Color.WHITE


func _fishing_catch_burst_visual_count(action_id: String, fish_count: int) -> int:
	if host.fishing_runtime.equipped_tool_id == "net":
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
	if host.fishing_runtime.equipped_tool_id == "net":
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
	if host.fishing_runtime.equipped_tool_id == "net":
		return 156.0
	match FishingState.method_archetype(host, action_id):
		"volume":
			return 136.0
		"commit", "risk":
			return 150.0
		_:
			return FISHING_CATCH_POP_RISE_PIXELS


func _clear_fishing_catch_burst(catch_burst: Control) -> void:
	if catch_burst == null or not is_instance_valid(catch_burst):
		return
	for child in catch_burst.get_children():
		if child != null and is_instance_valid(child):
			child.queue_free()


func _play_fishing_catch_burst_for_action(skill_id: String, action_id: String, fish_count: int) -> void:
	var burst_area_card := _fishing_area_card_for_action(skill_id, action_id)
	if burst_area_card.is_empty():
		return
	_play_fishing_catch_burst(burst_area_card, action_id, fish_count)


func _play_fishing_attempt_reveal(skill_id: String, action_id: String, success: bool) -> void:
	if not host._fishing_rework_active_for_skill(skill_id):
		return
	var area_id := FishingState.area_id_for_action(host, action_id)
	var area_card := _fishing_area_card_for_action(skill_id, action_id) if not area_id.is_empty() else {}
	var method_card := _fishing_method_card_for_action(skill_id, action_id)
	if not method_card.is_empty():
		method_card["attempt_reveal_kind"] = "success" if success else "fail"
		_update_fishing_method_attempt_bar(method_card, action_id, false, true)


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
	_clear_fishing_catch_burst(catch_burst)
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
		pop.modulate = Color("#6240b8", 0.0) if host.fishing_runtime.equipped_tool_id == "mirror" else Color(1, 1, 1, 0)
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
		tween.chain().tween_callback(host._app_lifecycle_runtime()._queue_free_instance_id.bind(pop.get_instance_id()))


func _update_fishing_method_active_art(
	card: Dictionary,
	art: Control,
	running: bool,
	delta: float,
	instant: bool
) -> void:
	if art == null or not is_instance_valid(art):
		return
	var rest_position := card.get("active_rest_position", ActionArtUi.ACTION_ART_OFFSET) as Vector2
	var camera_zoom := float(card.get("active_camera_zoom", 0.0))
	if camera_zoom > 1.0:
		_update_fishing_location_active_camera(card, art, running, delta, instant, rest_position, camera_zoom)
		return
	var sway_offset := card.get("active_sway_offset", FISHING_METHOD_ACTIVE_SWAY_OFFSET) as Vector2
	var sway_rotation := float(card.get("active_sway_rotation", FISHING_METHOD_ACTIVE_SWAY_ROTATION))
	var sway_scale_pulse := float(card.get("active_sway_scale_pulse", FISHING_METHOD_ACTIVE_SWAY_SCALE_PULSE))
	if running:
		var phase := float(card.get("method_active_sway_phase", 0.0)) + delta * FISHING_METHOD_ACTIVE_SWAY_SPEED * 1.20
		card["method_active_sway_phase"] = phase
		var bob := sin(phase)
		var sway := sin(phase * 0.85 + 0.55)
		var tilt := sin(phase * 0.95 - 0.35) * sway_rotation
		var pulse := 1.0 + sin(phase * 3.05) * sway_scale_pulse
		art.position = rest_position + Vector2(
			sway * sway_offset.x,
			bob * sway_offset.y
		)
		art.rotation = tilt
		art.scale = Vector2(pulse, pulse)
		return
	if instant:
		art.position = rest_position
		art.rotation = 0.0
		art.scale = Vector2.ONE
		return
	var return_step := clampf(delta / maxf(0.001, FISHING_METHOD_ACTIVE_SWAY_RETURN_SECONDS), 0.0, 1.0)
	art.position = art.position.lerp(rest_position, return_step)
	art.rotation = lerpf(art.rotation, 0.0, return_step)
	art.scale = art.scale.lerp(Vector2.ONE, return_step)
	if (
		art.position.distance_squared_to(rest_position) <= 0.25
		and absf(art.rotation) <= 0.001
		and art.scale.distance_squared_to(Vector2.ONE) <= 0.0001
	):
		art.position = rest_position
		art.rotation = 0.0
		art.scale = Vector2.ONE


func _update_fishing_method_attempt_bar(
	card: Dictionary,
	action_id: String,
	running: bool,
	instant: bool
) -> void:
	var attempt_bar := card.get("attempt_bar") as Control
	if attempt_bar == null or not is_instance_valid(attempt_bar):
		return
	if not attempt_bar.has_method("set_archetype") or not attempt_bar.has_method("set_attempt"):
		return
	var archetype := str(_fishing_tool_def("hands").get("archetype", FishingState.method_archetype(host, action_id)))
	if str(attempt_bar.get("archetype")) != archetype:
		attempt_bar.call("set_archetype", archetype)
	var reveal_kind := ""
	if not running:
		reveal_kind = str(card.get("attempt_reveal_kind", ""))
		if instant:
			card["attempt_reveal_kind"] = ""
	var progress: float = host.action_progress if running else 0.0
	attempt_bar.call("set_attempt", progress, running, reveal_kind)
	host._app_lifecycle_runtime().set_canvas_item_alpha_if_changed(attempt_bar, 1.0 if running or not reveal_kind.is_empty() else 0.42)


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
			var pan = card.get("active_camera_pan", FISHING_LOCATION_ACTIVE_CAMERA_PAN) as Vector2
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
				var blend = clampf(delta * FISHING_LOCATION_ACTIVE_CAMERA_EASE, 0.0, 1.0)
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
		var blend = clampf(delta * FISHING_LOCATION_ACTIVE_CAMERA_EASE, 0.0, 1.0)
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
		var zoom_step = clampf(delta / maxf(0.001, FISHING_METHOD_ACTIVE_SWAY_RETURN_SECONDS), 0.0, 1.0)
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
	var return_t = clampf(return_elapsed / maxf(0.001, FISHING_LOCATION_ACTIVE_CAMERA_RETURN_SECONDS), 0.0, 1.0)
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
	var press_position: Vector2 = host._app_lifecycle_runtime().meta_vector2(source, press_position_meta, event_position)
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
	var press_position: Vector2 = host._app_lifecycle_runtime().meta_vector2(source, press_position_meta, event_position)
	var drag_offset: Vector2 = event_position - press_position
	return (
		absf(drag_offset.x) >= host.ACTION_CARD_SCROLL_DRAG_VISUAL_DEADZONE
		and absf(drag_offset.x) > absf(drag_offset.y) * 1.15
	)


func _fishing_control_drag_exceeds_tap_slop(source: Control, event_position: Vector2, press_position_meta: String) -> bool:
	if source == null or not is_instance_valid(source) or not source.has_meta(press_position_meta):
		return false
	var press_position: Vector2 = host._app_lifecycle_runtime().meta_vector2(source, press_position_meta, event_position)
	return event_position.distance_to(press_position) > host.PASSIVE_BUTTON_TAP_RELEASE_SLOP


func _prepare_fishing_control_tap() -> void:
	var active_scroll: MobileScrollContainer = host._skill_detail_surface()._active_action_scroll_container()
	if active_scroll != null and is_instance_valid(active_scroll):
		active_scroll.prepare_child_tap()
	host._skill_swipe_activity_surface().skill_swipe_tracking = false
	host._skill_swipe_activity_surface().skill_swipe_horizontal = false
	host._skill_swipe_activity_surface().skill_swipe_touch_index = -1


func _motion_event_touch_index(event: InputEvent) -> int:
	if event is InputEventScreenDrag:
		return (event as InputEventScreenDrag).index
	return -1


func _handoff_fishing_vertical_scroll(press_position: Vector2, event_position: Vector2, touch_index := -1) -> void:
	var active_scroll: MobileScrollContainer = host._skill_detail_surface()._active_action_scroll_container()
	if active_scroll == null or not is_instance_valid(active_scroll):
		return
	active_scroll.handoff_drag_scroll(press_position, event_position, touch_index)
	_set_fishing_scroll_mode_active(true)
	fishing_scroll_mode_release_msec = Time.get_ticks_msec() + host.FISHING_SCROLL_MODE_SETTLE_MSEC


func _on_fishing_method_pressed(skill_id: String, action_id: String, _area_key: String, owner_area_pop_instance_id := 0) -> void:
	var method_card := _fishing_method_card_for_action(skill_id, action_id)
	if bool(method_card.get("is_fishing_location", false)):
		var area_id := str(method_card.get("area_id", ""))
		var location_id := str(method_card.get("location_id", ""))
		if not area_id.is_empty() and not location_id.is_empty():
			host.fishing_runtime.selected_locations[area_id] = location_id
	var owner_area_card := _fishing_area_card_for_pop_instance_id(owner_area_pop_instance_id)
	if owner_area_card.is_empty():
		var area_card := _fishing_area_card_for_action(skill_id, action_id)
		if not area_card.is_empty():
			_apply_fishing_area_selection(area_card, action_id, false)
	else:
		_apply_fishing_area_selection(owner_area_card, action_id, false)
	if bool(method_card.get("is_fishing_location", false)):
		host.save_game()
		_play_fishing_location_tile_wiggle(method_card)
	host._action_runtime()._start_action_from_card_tap(skill_id, action_id)


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
	var event_position = host._input_routing_shell()._passive_button_event_position(event, source)
	var event_kind = ButtonPressState.event_kind(event)
	if event_kind == "press":
		if host._input_routing_shell()._position_inside_bottom_interactive_ui(event_position) or not host._input_routing_shell()._position_inside_detail_actions_viewport(event_position):
			return false
		var method_card_for_press = _fishing_method_card_for_action(skill_id, action_id)
		var press_kind = host.ACTION_CARD_MEDAL_PRESS_KIND if host._skill_swipe_activity_surface()._action_card_medal_hit_at_position(method_card_for_press, event_position) else ""
		_prepare_fishing_control_tap()
		_clear_active_fishing_method_button_press()
		fishing_method_button_press_active = true
		fishing_method_button_press_source_id = source.get_instance_id()
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
				var method_scroll_press_position = host._app_lifecycle_runtime().meta_vector2(source, "fishing_method_press_position", event_position)
				_clear_active_fishing_method_button_press()
				_handoff_fishing_vertical_scroll(method_scroll_press_position, event_position, _motion_event_touch_index(event))
				return true
			if _fishing_control_drag_is_horizontal_swipe(source, event_position, "fishing_method_press_position"):
				var method_swipe_press_position = host._app_lifecycle_runtime().meta_vector2(source, "fishing_method_press_position", event_position)
				var touch_index = (event as InputEventScreenDrag).index if event is InputEventScreenDrag else -1
				ButtonPressState.clear(source, "fishing_method", ["kind"])
				fishing_method_button_press_active = false
				fishing_method_button_press_source_id = 0
				host._skill_swipe_activity_surface()._begin_skill_swipe_tracking(method_swipe_press_position, touch_index)
				if host._skill_swipe_activity_surface().skill_swipe_tracking:
					host._skill_swipe_activity_surface()._update_skill_swipe_feedback(event_position)
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
		fishing_method_button_press_active = false
		fishing_method_button_press_source_id = 0
		if not was_active:
			return false
		if (
			valid_tap
			and host._input_routing_shell()._position_inside_detail_actions_viewport(event_position)
			and not host._skill_detail_surface()._detail_actions_scroll_suppresses_child_click()
			and not host._skill_swipe_activity_surface()._skill_swipe_suppresses_button_action()
		):
			var method_card = _fishing_method_card_for_action(skill_id, action_id)
			if press_kind == host.ACTION_CARD_MEDAL_PRESS_KIND:
				if host._skill_swipe_activity_surface()._action_card_medal_hit_at_position(method_card, event_position):
					host._skill_swipe_activity_surface()._play_action_card_medal_tap_ceremony(method_card)
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
				_on_fishing_method_pressed(skill_id, action_id, area_key, owner_area_pop_instance_id)
		host.get_viewport().set_input_as_handled()
		return true
	return false


func _route_fishing_method_button_global_input(event: InputEvent) -> bool:
	if fishing_scroll_mouse_pick_suspended:
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
	if host._skill_swipe_activity_surface().skill_swipe_tracking and host._skill_swipe_activity_surface().skill_swipe_horizontal:
		return false
	if is_release and not fishing_method_button_press_active:
		var active_scroll := host._skill_detail_surface()._active_action_scroll_container() as ScrollContainer
		if active_scroll != null and is_instance_valid(active_scroll) and active_scroll.drag_tracking:
			active_scroll._input(event)
			return true
	if not is_press and not fishing_method_button_press_active:
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
	if fishing_scroll_mouse_pick_suspended:
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
	if host._input_routing_shell()._position_inside_bottom_interactive_ui(event_position) or not host._input_routing_shell()._position_inside_detail_actions_viewport(event_position):
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
	if action.is_empty() or not host._activity_unlock_runtime()._is_action_unlocked(skill_id, action):
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
	if fishing_scroll_mouse_pick_suspended:
		return {}
	var positions: Array = host._input_routing_shell()._activity_input_position_candidates(event_position)
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
				and host._input_routing_shell()._first_position_in_rect(positions, image_hit_control.get_global_rect()) != null
			):
				hit_control = image_hit_control
		if hit_control == null or not is_instance_valid(hit_control) or not hit_control.is_inside_tree() or not hit_control.is_visible_in_tree():
			hit_control = button
		var hit_rect := hit_control.get_global_rect()
		if require_contains_point:
			if host._input_routing_shell()._first_position_in_rect(positions, hit_rect) == null:
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
		event_position = host._input_routing_shell()._global_event_position(mouse_event.position, mouse_event.global_position)
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		event_position = host._input_routing_shell()._global_event_position(touch_event.position, touch_event.position)
	else:
		return false
	return _fishing_location_image_hit_at_position(event_position)


func _fishing_location_image_hit_at_position(event_position: Vector2) -> bool:
	var positions: Array = host._input_routing_shell()._activity_input_position_candidates(event_position)
	for hit in _fishing_method_button_hit_candidates():
		var method_card := hit.get("method_card", {}) as Dictionary
		if not bool(method_card.get("is_fishing_location", false)):
			continue
		var hit_control := method_card.get("method_image_hit_control", null) as Control
		if hit_control == null or not is_instance_valid(hit_control) or not hit_control.is_inside_tree() or not hit_control.is_visible_in_tree():
			continue
		if host._input_routing_shell()._first_position_in_rect(positions, hit_control.get_global_rect()) != null:
			return true
	return false


func _active_fishing_method_button_hit() -> Dictionary:
	if fishing_method_button_press_source_id != 0:
		var active_button := instance_from_id(fishing_method_button_press_source_id) as Button
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
	fishing_method_button_press_active = false
	fishing_method_button_press_source_id = 0
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
	for raw_lazy_entry in host._skill_detail_surface().detail_lazy_plan:
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
			return float(FISHING_NET_OFFER_HEIGHT)
		"rod":
			return float(FISHING_ROD_OFFER_HEIGHT)
		"reinforced_rod", "star_rod":
			return float(FISHING_ROD_UPGRADE_OFFER_HEIGHT)
		"boat":
			return float(FISHING_BOAT_OFFER_HEIGHT)
		"mirror":
			return float(FISHING_MIRROR_OFFER_HEIGHT)
	return float(FISHING_ROD_OFFER_HEIGHT)

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
	if host._skill_detail_surface()._module_ui_is_collapsed(module_key):
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
	return y + height + host._skill_detail_surface().DETAIL_LAZY_STACK_SEPARATION


func _append_fishing_action_lazy_entry(plan: Array, y: float, action: Dictionary) -> float:
	var action_id := str(action.get("id", ""))
	if action_id.is_empty():
		return y
	var height := ActivityCardStyles.root_height(false, host.ACTION_CARD_HEIGHT, host.ACTION_CARD_EXPANDED_HEIGHT, host.ACTION_CARD_3D_DEPTH_OFFSET.y)
	var module_key := ModuleUiRuntime.action_for_record("fishing", action, host.FISHING_ACTION_ID_ALIASES)
	if host._skill_detail_surface()._module_ui_is_collapsed(module_key):
		height = host._module_collapsed_squeeze_height()
	plan.append({
		"kind": "action",
		"entry": {"kind": "action", "action": action},
		"track_id": action_id,
		"y": y,
		"height": height,
		"mounted": false,
		"stack_host": null,
		"placeholder": null,
		"direct_stack_child": false
	})
	return y + height + host._skill_detail_surface().DETAIL_LAZY_STACK_SEPARATION


func _add_fishing_preview_standalone_action(stack: VBoxContainer, skill_id: String, action: Dictionary, content_width: float, state: Dictionary) -> void:
	var action_card: Dictionary = host._skill_swipe_activity_surface()._skill_swipe_preview_action_card(skill_id, action, content_width)
	(action_card["card"] as Dictionary)["preview_only"] = true
	var root := action_card["root"] as Control
	_set_preview_controls_mouse_filter(root)
	stack.add_child(root)
	(state["action_cards"] as Array).append(action_card["card"])


func _mark_fishing_preview_module_cards(built: Dictionary) -> void:
	var area_key := str(built.get("area_key", ""))
	var area_card := built.get("area_card", {}) as Dictionary
	if area_card.is_empty():
		if not area_key.is_empty():
			host._skill_detail_surface()._discard_action_card_key(area_key)
		return
	area_card["preview_only"] = true
	for raw_method_card in (area_card.get("method_slots", {}) as Dictionary).values():
		var method_card := raw_method_card as Dictionary
		if method_card.is_empty():
			continue
		method_card["preview_only"] = true
	_discard_fishing_area_module_card_keys(area_key, area_card, str(area_card.get("skill_id", "fishing")))


func _discard_fishing_area_module_card_keys(area_key: String, area_card: Dictionary, skill_id: String) -> void:
	host._skill_detail_surface()._discard_action_card_key(area_key)
	for raw_method_id in area_card.get("method_ids", []) as Array:
		host._skill_detail_surface()._discard_action_card_key(host._action_key(skill_id, str(raw_method_id)))
	for raw_method_card in (area_card.get("method_slots", {}) as Dictionary).values():
		var method_card := raw_method_card as Dictionary
		if method_card.is_empty():
			continue
		var action_id := str(method_card.get("action_id", ""))
		if not action_id.is_empty():
			host._skill_detail_surface()._discard_action_card_key(host._action_key(skill_id, action_id))
		if bool(method_card.get("is_fishing_location", false)):
			var location_key := "%s:location-%s-%s" % [
				str(method_card.get("skill_id", skill_id)),
				str(method_card.get("area_id", "")),
				str(method_card.get("location_id", ""))
			]
			host._skill_detail_surface()._discard_action_card_key(location_key)


func _set_preview_controls_mouse_filter(root: Control) -> void:
	if root == null:
		return
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in root.get_children():
		var child_control := child as Control
		if child_control != null:
			_set_preview_controls_mouse_filter(child_control)


func _fishing_offer_unlock_level(offer_id: String) -> int:
	match offer_id:
		"net":
			return FishingState.FISHING_NET_OFFER_UNLOCK_LEVEL
		"rod":
			return FishingState.FISHING_ROD_OFFER_UNLOCK_LEVEL
		"reinforced_rod":
			return FishingState.FISHING_REINFORCED_ROD_UNLOCK_LEVEL
		"star_rod":
			return FishingState.FISHING_STAR_ROD_UNLOCK_LEVEL
		"boat":
			return FishingState.FISHING_BOAT_OFFER_UNLOCK_LEVEL
		"mirror":
			return FishingState.FISHING_MIRROR_OFFER_UNLOCK_LEVEL
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
	title.offset_left = FISHING_EQUIPMENT_OFFER_TITLE_SIDE_INSET
	title.offset_right = -FISHING_EQUIPMENT_OFFER_TITLE_SIDE_INSET
	title.offset_top = 14
	title.offset_bottom = 79
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _fishing_offer_shell(content_width: float, offer_height: float, texture: Texture2D, shade_alpha: float, clip_contents := false, fallback_color := Color.TRANSPARENT, feather_height := 60.0) -> Dictionary:
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
	bg.radius = 32.0
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
	host.button_press_runtime.attach_default_button_sfx(button)
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
	button.offset_left = -140
	button.offset_right = 140
	button.offset_top = -85
	button.offset_bottom = 110
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

func _fishing_offer_hint(pop_card: Control, hint_text: String, available: bool, outline_size := 10, offset_top := -78.0, offset_bottom := -17.0, vertical_alignment := VERTICAL_ALIGNMENT_TOP) -> Label:
	var hint: Label = host._label(hint_text, 52, Color.WHITE if available else Color("#ffd95a"), HORIZONTAL_ALIGNMENT_CENTER)
	hint.add_theme_color_override("font_outline_color", host.COLOR_INK)
	hint.add_theme_constant_override("outline_size", outline_size)
	hint.anchor_left = 0.0
	hint.anchor_right = 1.0
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.offset_left = 24
	hint.offset_right = -24
	hint.offset_top = offset_top
	hint.offset_bottom = offset_bottom
	hint.vertical_alignment = vertical_alignment
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pop_card.add_child(hint)
	return hint

func _build_fishing_net_offer_module(content_width: float) -> Control:
	var shell := _fishing_offer_shell(content_width, FISHING_NET_OFFER_HEIGHT, host.visual_texture_cache._first_texture_or_visual_fallback([
		"res://assets/content/fishing/backgrounds/beach-rocky-zoom.png",
		"res://assets/content/fishing/backgrounds/00-tide-pool-shallows.png"
	]), 0.06, false, ThemeStyles.skill_theme_color("fishing", host.COLOR_BLUE).darkened(0.12), 0.0)
	var root := shell.get("root") as Control
	var pop_card := shell.get("pop") as Control

	var title: Label = host._label("You find an old net on the beach", 60, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_color_override("font_outline_color", host.COLOR_INK)
	title.add_theme_constant_override("outline_size", 12)
	title.anchor_left = 0.0
	title.anchor_right = 1.0
	title.anchor_top = 0.0
	title.anchor_bottom = 0.0
	title.offset_left = 24
	title.offset_right = -24
	title.offset_top = 6
	title.offset_bottom = 94
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
	net_motion_root.offset_left = -129.25
	net_motion_root.offset_right = 129.25
	net_motion_root.offset_top = -72.25
	net_motion_root.offset_bottom = 109.25
	net_motion_root.custom_minimum_size = Vector2(258.5, 181.5)
	net_motion_root.size = Vector2(258.5, 181.5)
	net_motion_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	net_motion_root.z_index = 12
	pop_card.add_child(net_motion_root)

	var net_art: TextureRect = host.visual_texture_cache._image("res://assets/content/fishing/tools/net-player.png", Vector2(258.5, 181.5))
	net_art.anchor_left = 0.0
	net_art.anchor_right = 0.0
	net_art.anchor_top = 0.0
	net_art.anchor_bottom = 0.0
	net_art.position = Vector2.ZERO
	net_art.size = Vector2(258.5, 181.5)
	net_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	net_motion_root.add_child(net_art)
	_start_fishing_net_offer_idle_motion(net_motion_root)
	net_button.set_meta("fishing_net_art_id", net_motion_root.get_instance_id())
	_fishing_offer_hint(pop_card, "Tap the net", true, 7, -66.0, -24.0, VERTICAL_ALIGNMENT_CENTER)

	return root

func _fishing_offer_art_modulate(available: bool, available_modulate := Color.WHITE) -> Color:
	return available_modulate if available else FISHING_OFFER_UNAVAILABLE_ART_MODULATE

func _build_fishing_rod_offer_module(content_width: float) -> Control:
	var shell := _fishing_offer_shell(content_width, FISHING_ROD_OFFER_HEIGHT, host.visual_texture_cache._texture_or_visual_fallback("res://assets/content/fishing/backgrounds/02-river-bend.png"), 0.28)
	var root := shell.get("root") as Control
	var pop_card := shell.get("pop") as Control

	var title: Label = host._label("Bamboo rod", 60, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_configure_fishing_equipment_offer_title(title, 60, 12)
	pop_card.add_child(title)

	var rod_button := _fishing_equipment_offer_button(pop_card, root, "rod", true)

	var rod_art: TextureRect = host.visual_texture_cache._image("res://assets/content/fishing/tools/tool-bamboo-rod.png", Vector2(260, 180))
	rod_art.position = Vector2(10, 5)
	rod_art.modulate = _fishing_offer_art_modulate(host.fishing_runtime.fish_currency >= FishingState.FISHING_ROD_OFFER_COST)
	rod_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rod_button.add_child(rod_art)

	var hint_text := "Buy for %s fish" % GameFormatting.compact_number(float(FishingState.FISHING_ROD_OFFER_COST), 3)
	if host.fishing_runtime.fish_currency < FishingState.FISHING_ROD_OFFER_COST:
		hint_text = "%s fish needed" % GameFormatting.compact_number(float(FishingState.FISHING_ROD_OFFER_COST), 3)
	_fishing_offer_hint(pop_card, hint_text, host.fishing_runtime.fish_currency >= FishingState.FISHING_ROD_OFFER_COST)

	return root

func _build_fishing_mirror_offer_module(content_width: float) -> Control:
	var shell := _fishing_offer_shell(content_width, FISHING_MIRROR_OFFER_HEIGHT, host.visual_texture_cache._texture_or_visual_fallback("res://assets/content/fishing/backgrounds/11-cosmic-dream-sea.png"), 0.34)
	var root := shell.get("root") as Control
	var pop_card := shell.get("pop") as Control

	var title: Label = host._label("Reflection mirror", 60, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_configure_fishing_equipment_offer_title(title, 60, 12)
	pop_card.add_child(title)

	var mirror_button := _fishing_equipment_offer_button(pop_card, root, "mirror")

	var mirror_art: TextureRect = host.visual_texture_cache._image("res://assets/content/fishing/tools/reflection-net.png", Vector2(260, 180))
	mirror_art.position = Vector2(10, 5)
	mirror_art.modulate = _fishing_offer_art_modulate(host.fishing_runtime.fish_currency >= FishingState.FISHING_MIRROR_OFFER_COST)
	mirror_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mirror_button.add_child(mirror_art)

	var hint_text := "Buy for %s fish" % GameFormatting.compact_number(float(FishingState.FISHING_MIRROR_OFFER_COST), 3)
	if host.fishing_runtime.fish_currency < FishingState.FISHING_MIRROR_OFFER_COST:
		hint_text = "%s fish needed" % GameFormatting.compact_number(float(FishingState.FISHING_MIRROR_OFFER_COST), 3)
	_fishing_offer_hint(pop_card, hint_text, host.fishing_runtime.fish_currency >= FishingState.FISHING_MIRROR_OFFER_COST)

	return root

func _fishing_rod_upgrade_cost(tool_id: String) -> int:
	return FishingState.FISHING_STAR_ROD_COST if tool_id == "star_rod" else FishingState.FISHING_REINFORCED_ROD_COST

func _fishing_rod_upgrade_title(tool_id: String) -> String:
	return "Star rod" if tool_id == "star_rod" else "Reinforced rod"

func _build_fishing_rod_upgrade_offer_module(content_width: float, tool_id: String) -> Control:
	var shell := _fishing_offer_shell(content_width, FISHING_ROD_UPGRADE_OFFER_HEIGHT, host.visual_texture_cache._texture_or_visual_fallback("res://assets/content/fishing/backgrounds/04-frozen-lake.png" if tool_id == "star_rod" else "res://assets/content/fishing/backgrounds/05-coral-reef-shallows.png"), 0.30, true)
	var root := shell.get("root") as Control
	var pop_card := shell.get("pop") as Control

	var title: Label = host._label(_fishing_rod_upgrade_title(tool_id), 60, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_configure_fishing_equipment_offer_title(title, 60, 12)
	pop_card.add_child(title)

	var upgrade_button := _fishing_equipment_offer_button(pop_card, root, tool_id)

	var cost := _fishing_rod_upgrade_cost(tool_id)
	var rod_art: TextureRect = host.visual_texture_cache._image("res://assets/content/fishing/tools/tool-bamboo-rod.png", Vector2(260, 180))
	rod_art.position = Vector2(10, 5)
	rod_art.modulate = _fishing_offer_art_modulate(host.fishing_runtime.fish_currency >= cost, Color("#dcf7ff") if tool_id == "star_rod" else Color("#ffe8a8"))
	rod_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	upgrade_button.add_child(rod_art)

	var hint_text := "Upgrade for %s fish" % GameFormatting.compact_number(float(cost), 3)
	if host.fishing_runtime.fish_currency < cost:
		hint_text = "%s fish needed" % GameFormatting.compact_number(float(cost), 3)
	_fishing_offer_hint(pop_card, hint_text, host.fishing_runtime.fish_currency >= cost)

	return root

func _build_fishing_boat_offer_module(content_width: float) -> Control:
	var shell := _fishing_offer_shell(content_width, FISHING_BOAT_OFFER_HEIGHT, host.visual_texture_cache._texture_or_visual_fallback("res://assets/content/fishing/backgrounds/07-rowboat-offshore.png"), 0.30, true)
	var root := shell.get("root") as Control
	var pop_card := shell.get("pop") as Control

	var title: Label = host._label("Build boat", 60, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_configure_fishing_equipment_offer_title(title, 60, 12)
	pop_card.add_child(title)

	var boat_button := _fishing_equipment_offer_button(pop_card, root, "boat")

	var boat_art: TextureRect = host.visual_texture_cache._image("res://assets/content/fishing/tools/tool-boat.png", Vector2(260, 180))
	boat_art.position = Vector2(10, 5)
	var can_build: bool = SkillState.host_skill_level(host, "build") >= FishingState.FISHING_BOAT_BUILD_REQUIRED_LEVEL and host.material_runtime.amount("softwood") >= float(FishingState.FISHING_BOAT_OFFER_COST)
	boat_art.modulate = _fishing_offer_art_modulate(can_build)
	boat_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boat_button.add_child(boat_art)

	var hint_text := "Build for %s Softwood" % GameFormatting.compact_number(float(FishingState.FISHING_BOAT_OFFER_COST), 3)
	if SkillState.host_skill_level(host, "build") < FishingState.FISHING_BOAT_BUILD_REQUIRED_LEVEL:
		hint_text = "Requires Building Lv %s" % FishingState.FISHING_BOAT_BUILD_REQUIRED_LEVEL
	elif host.material_runtime.amount("softwood") < float(FishingState.FISHING_BOAT_OFFER_COST):
		hint_text = "%s Softwood needed" % GameFormatting.compact_number(float(FishingState.FISHING_BOAT_OFFER_COST), 3)
	_fishing_offer_hint(pop_card, hint_text, can_build)

	return root

func _on_fishing_offer_button_input(event: InputEvent, offer_id: String, source: Button) -> bool:
	if source == null or not is_instance_valid(source) or source.disabled:
		return false
	var event_position: Vector2 = host._input_routing_shell()._passive_button_event_position(event, source)
	var event_kind := ButtonPressState.event_kind(event)
	if event_kind == "press":
		if (
			(host._input_routing_shell()._position_inside_bottom_interactive_ui(event_position) and not _fishing_offer_button_contains_point(source, event_position))
			or not host._input_routing_shell()._position_inside_detail_actions_viewport(event_position)
		):
			return false
		_prepare_fishing_control_tap()
		fishing_offer_button_press_active = true
		ButtonPressState.begin(source, "fishing_offer", event_position)
		host.get_viewport().set_input_as_handled()
		return true
	if event_kind == "drag":
		if ButtonPressState.active(source, "fishing_offer"):
			if _fishing_control_drag_exceeds_tap_slop(source, event_position, "fishing_offer_press_position"):
				ButtonPressState.update_drag(source, "fishing_offer", event_position, host.PASSIVE_BUTTON_TAP_RELEASE_SLOP)
			if _fishing_control_drag_is_vertical_scroll(source, event_position, "fishing_offer_press_position"):
				var offer_scroll_press_position: Vector2 = host._app_lifecycle_runtime().meta_vector2(source, "fishing_offer_press_position", event_position)
				_clear_fishing_offer_button_press(source)
				_handoff_fishing_vertical_scroll(offer_scroll_press_position, event_position, _motion_event_touch_index(event))
				return false
			if _fishing_control_drag_is_horizontal_swipe(source, event_position, "fishing_offer_press_position"):
				var offer_swipe_press_position: Vector2 = host._app_lifecycle_runtime().meta_vector2(source, "fishing_offer_press_position", event_position)
				var touch_index := (event as InputEventScreenDrag).index if event is InputEventScreenDrag else -1
				_clear_fishing_offer_button_press(source)
				host._skill_swipe_activity_surface()._begin_skill_swipe_tracking(offer_swipe_press_position, touch_index)
				if host._skill_swipe_activity_surface().skill_swipe_tracking:
					host._skill_swipe_activity_surface()._update_skill_swipe_feedback(event_position)
				host.get_viewport().set_input_as_handled()
				return true
			ButtonPressState.update_drag(source, "fishing_offer", event_position, -1.0)
			host.get_viewport().set_input_as_handled()
			return true
		return false
	if event_kind == "release":
		var was_active := ButtonPressState.active(source, "fishing_offer")
		var valid_tap := ButtonPressState.finish(source, "fishing_offer", event_position, host.PASSIVE_BUTTON_TAP_RELEASE_SLOP)
		fishing_offer_button_press_active = false
		if not was_active:
			return false
		if (
			valid_tap
			and host._input_routing_shell()._position_inside_detail_actions_viewport(event_position)
			and not host._skill_swipe_activity_surface()._skill_swipe_suppresses_button_action()
		):
			_activate_fishing_offer_button(offer_id, source)
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
	if fishing_scroll_mouse_pick_suspended:
		if is_press:
			_set_fishing_scroll_mode_active(false)
		else:
			return false
	if not is_press and not fishing_offer_button_press_active:
		return false
	var source := _fishing_offer_button_hit(event_position, true) if is_press else _active_fishing_offer_button()
	if host._input_routing_shell()._position_inside_bottom_interactive_ui(event_position):
		if source == null:
			_clear_fishing_offer_button_press(_active_fishing_offer_button())
			return false
	if source == null:
		return false
	return _on_fishing_offer_button_input(event, str(source.get_meta("fishing_offer_id", "")), source)

func _fishing_offer_button_hit(event_position: Vector2, require_contains_point := true) -> Button:
	if fishing_scroll_mouse_pick_suspended:
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
		var hit_control: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(int(button.get_meta(meta_name))))
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
	fishing_offer_button_press_active = false
	ButtonPressState.clear(source, "fishing_offer")

func _activate_fishing_offer_button(offer_id: String, source: Button) -> void:
	if source == null or not is_instance_valid(source):
		return
	match offer_id:
		"net":
			var net_art: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(int(source.get_meta("fishing_net_art_id", 0))))
			_on_fishing_net_offer_pressed(source, net_art)
		"rod":
			_on_fishing_rod_offer_pressed(source)
		"mirror":
			_on_fishing_mirror_offer_pressed(source)
		"reinforced_rod", "star_rod":
			_on_fishing_rod_upgrade_offer_pressed(offer_id, source)
		"boat":
			_on_fishing_boat_offer_pressed(source)


func _on_fishing_net_offer_pressed(net_button: Control, net_art: Control = null) -> void:
	if host.fishing_runtime.net_collected or host.fishing_runtime.net_collect_pending:
		return
	host.fishing_runtime.net_collect_pending = true
	var collect_animation_started := false
	if net_button != null and is_instance_valid(net_button):
		host._reward_feedback_surface()._float_reward(net_button, net_button, "Net found!", 58, host.COLOR_GOLD, Vector2(0, -20), Vector2(0, -85), 0.0)
		collect_animation_started = _collect_fishing_net_offer_to_wallet(net_art if net_art != null and is_instance_valid(net_art) else net_button)
		_play_fishing_offer_collected_transition(net_button, FishingState.FISHING_NET_COLLECT_LAYOUT_DELAY_SECONDS if collect_animation_started else 0.10, collect_animation_started)
	host._reward_feedback_surface()._set_result("Collecting net...")
	if not collect_animation_started:
		_finish_fishing_net_collect()


func _finish_fishing_net_collect() -> void:
	if host.fishing_runtime.net_collected:
		host.fishing_runtime.net_collect_pending = false
		return
	host.fishing_runtime.net_collected = true
	host.fishing_runtime.net_collect_pending = false
	host.save_game()
	host._reward_feedback_surface()._set_result("Net collected!")
	_refresh_fish_circle_currency_only()
	host._skill_detail_surface().detail_rendered_action_ids = _fishing_detail_render_signature()


func _on_fishing_rod_offer_pressed(rod_button: Control) -> void:
	if host.fishing_runtime.rod_collected:
		return
	if host.fishing_runtime.fish_currency < FishingState.FISHING_ROD_OFFER_COST:
		if rod_button != null and is_instance_valid(rod_button):
			host._reward_feedback_surface()._float_reward(rod_button, rod_button, "Need %s fish" % GameFormatting.compact_number(float(FishingState.FISHING_ROD_OFFER_COST), 3), 50, Color("#ffd95a"), Vector2(0, -20), Vector2(0, -75), 0.0)
		host._reward_feedback_surface()._set_result("Need %s fish for the rod." % GameFormatting.compact_number(float(FishingState.FISHING_ROD_OFFER_COST), 3))
		return
	host.fishing_runtime.fish_currency = maxf(0.0, host.fishing_runtime.fish_currency - float(FishingState.FISHING_ROD_OFFER_COST))
	host.fishing_runtime.rod_collected = true
	host.save_game()
	if rod_button != null and is_instance_valid(rod_button):
		host._reward_feedback_surface()._float_reward(rod_button, rod_button, "Rod collected!", 58, host.COLOR_GOLD, Vector2(0, -20), Vector2(0, -85), 0.0)
		_fly_fishing_tool_to_wallet(rod_button, "res://assets/content/fishing/tools/tool-bamboo-rod.png")
		_play_fishing_offer_collected_transition(rod_button)
	host._reward_feedback_surface()._set_result("Bamboo rod collected!")
	_refresh_fish_circle_currency_only()
	host._skill_detail_surface().detail_rendered_action_ids = _fishing_detail_render_signature()


func _on_fishing_rod_upgrade_offer_pressed(tool_id: String, upgrade_button: Control) -> void:
	var needs_previous: bool = (tool_id == "star_rod" and not host.fishing_runtime.reinforced_rod_collected) or (tool_id == "reinforced_rod" and not host.fishing_runtime.rod_collected)
	if needs_previous:
		return
	if (tool_id == "star_rod" and host.fishing_runtime.star_rod_collected) or (tool_id == "reinforced_rod" and host.fishing_runtime.reinforced_rod_collected):
		return
	var cost := _fishing_rod_upgrade_cost(tool_id)
	if host.fishing_runtime.fish_currency < cost:
		if upgrade_button != null and is_instance_valid(upgrade_button):
			host._reward_feedback_surface()._float_reward(upgrade_button, upgrade_button, "Need %s fish" % GameFormatting.compact_number(float(cost), 3), 50, Color("#ffd95a"), Vector2(0, -20), Vector2(0, -75), 0.0)
		host._reward_feedback_surface()._set_result("Need %s fish for the %s." % [GameFormatting.compact_number(float(cost), 3), _fishing_rod_upgrade_title(tool_id)])
		return
	host.fishing_runtime.fish_currency = maxf(0.0, host.fishing_runtime.fish_currency - float(cost))
	if tool_id == "star_rod":
		host.fishing_runtime.star_rod_collected = true
	else:
		host.fishing_runtime.reinforced_rod_collected = true
	host.save_game()
	if upgrade_button != null and is_instance_valid(upgrade_button):
		host._reward_feedback_surface()._float_reward(upgrade_button, upgrade_button, "%s collected!" % _fishing_rod_upgrade_title(tool_id), 58, host.COLOR_GOLD, Vector2(0, -20), Vector2(0, -85), 0.0)
		_fly_fishing_tool_to_wallet(upgrade_button, "res://assets/content/fishing/tools/tool-bamboo-rod.png")
		_play_fishing_offer_collected_transition(upgrade_button)
	host._reward_feedback_surface()._set_result("%s collected!" % _fishing_rod_upgrade_title(tool_id))
	_refresh_fish_circle_currency_only()
	host._skill_detail_surface().detail_rendered_action_ids = _fishing_detail_render_signature()


func _on_fishing_boat_offer_pressed(boat_button: Control) -> void:
	if host.fishing_runtime.boat_built:
		return
	if SkillState.host_skill_level(host, "build") < FishingState.FISHING_BOAT_BUILD_REQUIRED_LEVEL:
		if boat_button != null and is_instance_valid(boat_button):
			host._reward_feedback_surface()._float_reward(boat_button, boat_button, "Building Lv %s required" % FishingState.FISHING_BOAT_BUILD_REQUIRED_LEVEL, 48, Color("#ffd95a"), Vector2(0, -20), Vector2(0, -75), 0.0)
		host._reward_feedback_surface()._set_result("Building Lv %s required to build the boat." % FishingState.FISHING_BOAT_BUILD_REQUIRED_LEVEL)
		return
	if host.material_runtime.amount("softwood") < float(FishingState.FISHING_BOAT_OFFER_COST):
		if boat_button != null and is_instance_valid(boat_button):
			host._reward_feedback_surface()._float_reward(boat_button, boat_button, "Need %s Softwood" % GameFormatting.compact_number(float(FishingState.FISHING_BOAT_OFFER_COST), 3), 50, Color("#ffd95a"), Vector2(0, -20), Vector2(0, -75), 0.0)
		host._reward_feedback_surface()._set_result("Need %s Softwood for the boat." % GameFormatting.compact_number(float(FishingState.FISHING_BOAT_OFFER_COST), 3))
		return
	host.material_runtime.spend_amount("softwood", float(FishingState.FISHING_BOAT_OFFER_COST))
	host.fishing_runtime.boat_built = true
	host.save_game()
	if boat_button != null and is_instance_valid(boat_button):
		host._reward_feedback_surface()._float_reward(boat_button, boat_button, "Boat built!", 58, host.COLOR_GOLD, Vector2(0, -20), Vector2(0, -85), 0.0)
		_fly_fishing_tool_to_wallet(boat_button, "res://assets/content/fishing/tools/tool-boat.png")
		_play_fishing_offer_collected_transition(boat_button)
	host._reward_feedback_surface()._set_result("Boat built!")
	_refresh_fish_circle_currency_only()
	host._skill_detail_surface().detail_rendered_action_ids = _fishing_detail_render_signature()


func _on_fishing_mirror_offer_pressed(mirror_button: Control) -> void:
	if host.fishing_runtime.mirror_collected:
		return
	if host.fishing_runtime.fish_currency < FishingState.FISHING_MIRROR_OFFER_COST:
		if mirror_button != null and is_instance_valid(mirror_button):
			host._reward_feedback_surface()._float_reward(mirror_button, mirror_button, "Need %s fish" % GameFormatting.compact_number(float(FishingState.FISHING_MIRROR_OFFER_COST), 3), 50, Color("#ffd95a"), Vector2(0, -20), Vector2(0, -75), 0.0)
		host._reward_feedback_surface()._set_result("Need %s fish for the mirror." % GameFormatting.compact_number(float(FishingState.FISHING_MIRROR_OFFER_COST), 3))
		return
	host.fishing_runtime.fish_currency = maxf(0.0, host.fishing_runtime.fish_currency - float(FishingState.FISHING_MIRROR_OFFER_COST))
	host.fishing_runtime.mirror_collected = true
	host.save_game()
	if mirror_button != null and is_instance_valid(mirror_button):
		host._reward_feedback_surface()._float_reward(mirror_button, mirror_button, "Mirror collected!", 58, host.COLOR_GOLD, Vector2(0, -20), Vector2(0, -85), 0.0)
		_fly_fishing_tool_to_wallet(mirror_button, "res://assets/content/fishing/tools/reflection-net.png")
		_play_fishing_offer_collected_transition(mirror_button)
	host._reward_feedback_surface()._set_result("Reflection mirror collected!")
	_refresh_fish_circle_currency_only()
	host._skill_detail_surface().detail_rendered_action_ids = _fishing_detail_render_signature()


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
	var net_root: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(net_root_id))
	if net_root == null:
		return
	var phase := value * TAU
	var bob := sin(phase) * 10.0
	var sway := sin(phase + 0.6) * 7.0
	net_root.position = base_position + Vector2(sway, bob)
	net_root.rotation = sin(phase - 0.4) * 0.055

func _collect_fishing_net_offer_to_wallet(net_root: Control) -> bool:
	if net_root == null or not is_instance_valid(net_root) or host._skill_detail_surface().detail_fish_circle == null or not is_instance_valid(host._skill_detail_surface().detail_fish_circle):
		return false
	host._app_lifecycle_runtime()._kill_meta_tween(net_root, "fishing_net_offer_idle_tween")
	var source_rect := net_root.get_global_rect()
	var target_rect: Rect2 = host._skill_detail_surface().detail_fish_circle.get_global_rect()
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
	if fishing_collection_canvas != null and is_instance_valid(fishing_collection_canvas):
		return fishing_collection_canvas
	var canvas := CanvasLayer.new()
	canvas.name = "FishingCollectionCanvas"
	canvas.layer = FISHING_COLLECTION_CANVAS_LAYER
	host.add_child(canvas)
	fishing_collection_canvas = canvas
	return canvas

func clear_fishing_collection_canvas_cache() -> void:
	fishing_collection_canvas = null

func _fly_fishing_tool_to_wallet(source: Control, texture_path: String, staged_net_collect := false) -> void:
	if source == null or not is_instance_valid(source) or host._skill_detail_surface().detail_fish_circle == null or not is_instance_valid(host._skill_detail_surface().detail_fish_circle):
		return
	var texture: Texture2D = host.visual_texture_cache._texture(texture_path)
	if texture == null:
		return
	var source_rect := source.get_global_rect()
	var target_rect: Rect2 = host._skill_detail_surface().detail_fish_circle.get_global_rect() if staged_net_collect else host._skill_detail_surface().detail_fish_circle.tool_icon_global_rect() if host._skill_detail_surface().detail_fish_circle.has_method("tool_icon_global_rect") else host._skill_detail_surface().detail_fish_circle.get_global_rect()
	var to_local: Transform2D = host.get_global_transform_with_canvas().affine_inverse()
	var start: Vector2 = to_local * source_rect.get_center()
	var target: Vector2 = to_local * target_rect.get_center()
	var art := TextureRect.new()
	art.texture = texture
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.size = Vector2(130, 130) if staged_net_collect else Vector2(110, 110)
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
	tween.chain().tween_callback(Callable(self, "_set_fish_circle_for_skill_bound").bind(host._skill_detail_surface().detail_fish_circle.get_instance_id(), host.selected_skill_id, true))
	tween.chain().tween_interval(0.08)
	tween.tween_property(art, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(art, "scale", Vector2(0.44, 0.44), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(host._app_lifecycle_runtime()._queue_free_instance_id.bind(art.get_instance_id()))
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
	tween.chain().tween_callback(Callable(self, "_set_fish_circle_for_skill_bound").bind(host._skill_detail_surface().detail_fish_circle.get_instance_id(), host.selected_skill_id, true))
	tween.chain().tween_method(_apply_fishing_net_collect_target_hover_frame.bind(art_id, target_position), 0.0, 1.0, 1.0).set_trans(Tween.TRANS_LINEAR)
	tween.chain().tween_property(art, "modulate:a", 0.0, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(_finish_fishing_net_collect)
	tween.chain().tween_callback(host._app_lifecycle_runtime()._queue_free_instance_id.bind(art.get_instance_id()))

func _apply_fishing_net_collect_start_hover_frame(value: float, art_id: int, start_position: Vector2) -> void:
	var flyer: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(art_id))
	if flyer == null:
		return
	var bob := sin(value * TAU * 2.0) * 10.0
	var sway := sin(value * TAU * 1.35 + 0.7) * 8.0
	flyer.position = start_position + Vector2(sway, bob)
	flyer.rotation = sin(value * TAU * 1.6) * 0.075

func _apply_fishing_net_collect_target_hover_frame(value: float, art_id: int, target_position: Vector2) -> void:
	var flyer: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(art_id))
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
		host._app_lifecycle_runtime().set_base_button_disabled_if_changed(source as BaseButton, true)
	var pop_card := source.get_parent() as Control
	var root := pop_card.get_parent() as Control if pop_card != null and is_instance_valid(pop_card) else null
	if root == null or not is_instance_valid(root) or root.is_queued_for_deletion():
		return
	var track_id := str(root.get_meta("detail_lazy_track_id", ""))
	if not track_id.is_empty() and not collapse_after_fade:
		host._skill_detail_surface()._apply_detail_lazy_entry_height(0.0, track_id)
	var start_height := root.custom_minimum_size.y
	var tween: Tween = host.create_tween()
	var root_id := root.get_instance_id()
	if collapse_after_fade:
		tween.tween_property(root, "modulate:a", 0.0, 0.20).set_delay(start_delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween.chain().tween_method(_apply_fishing_offer_collected_height.bind(root_id), start_height, 0.0, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		if not track_id.is_empty():
			tween.parallel().tween_method(host._skill_detail_surface()._apply_detail_lazy_entry_height.bind(track_id), start_height, 0.0, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tween.tween_callback(host._app_lifecycle_runtime()._hide_control_bound.bind(root_id))
		return
	tween.set_parallel(true)
	tween.tween_property(root, "modulate:a", 0.0, 0.20).set_delay(start_delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(_apply_fishing_offer_collected_height.bind(root_id), start_height, 0.0, 0.24).set_delay(start_delay + 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.chain().tween_callback(host._app_lifecycle_runtime()._hide_control_bound.bind(root_id))

func _apply_fishing_offer_collected_height(value: float, root_id: int) -> void:
	var root: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(root_id))
	if root == null or root.is_queued_for_deletion():
		return
	root.custom_minimum_size = Vector2(root.custom_minimum_size.x, value)
	root.size.y = value
	root.update_minimum_size()
	var parent := root.get_parent() as Container
	if parent != null:
		parent.queue_sort()
