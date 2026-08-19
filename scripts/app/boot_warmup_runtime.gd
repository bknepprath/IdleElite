extends RefCounted

class _BootFlexLoadingAnimation:
	extends Control

	const SHEET_PATH := "res://assets/loading/blue-guy-flex-loading-spritesheet.png"
	const BUBBLE_PATH := "res://assets/loading/blue-guy-flex-speech-bubble-blank.png"
	const FONT_PATH := "res://assets/fonts/Fredoka.ttf"
	const FRAME_SIZE := Vector2(512, 512)
	const LOOP_SECONDS := 2.15
	const SHAKE_START := 0.22
	const COLOR_INK := Color("#171615")
	const SKILL_THEME_COLORS := [
		Color("#e84d4d"),
		Color("#8956bc"),
		Color("#237cd5"),
		Color("#6ea937"),
		Color("#2dc0b9")
	]


	var rng := RandomNumberGenerator.new()
	var elapsed := 0.0
	var previous_loop_pos := 0.0
	var sheet_texture: Texture2D
	var bubble_texture: Texture2D
	var bubble_font: Font
	var atlas_texture: AtlasTexture
	var sprite_holder: Control
	var sprite: TextureRect
	var bubble: TextureRect
	var bubble_text: Control
	var bubble_line_top: Label
	var bubble_line_big: Label
	var xp_layer: Control
	var sprite_base_position := Vector2.ZERO
	var current_frame := -1
	var transparent_texture: Texture2D


	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		rng.randomize()
		sheet_texture = _load_texture_or_fallback(SHEET_PATH, Vector2i(int(FRAME_SIZE.x * 4.0), int(FRAME_SIZE.y)))
		bubble_texture = _load_texture_or_fallback(BUBBLE_PATH, Vector2i(8, 8))
		_load_bubble_font()
		_build_nodes()
		_sync_layout()
		set_process(not _headless_mode())


	func restart() -> void:
		elapsed = 0.0
		previous_loop_pos = 0.0
		current_frame = -1
		_set_frame(0)
		if sprite_holder != null:
			sprite_holder.position = sprite_base_position
		if xp_layer != null:
			for child in xp_layer.get_children():
				child.queue_free()
		set_process(not _headless_mode())


	func stop() -> void:
		set_process(false)


	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			_sync_layout()


	func _process(delta: float) -> void:
		if _headless_mode():
			return
		var next_elapsed := elapsed + delta
		var loop_pos := fmod(next_elapsed, LOOP_SECONDS)
		var wrapped := loop_pos < previous_loop_pos
		if wrapped or (previous_loop_pos < LOOP_SECONDS * SHAKE_START and loop_pos >= LOOP_SECONDS * SHAKE_START):
			_spawn_xp_drop()
		elapsed = next_elapsed
		previous_loop_pos = loop_pos
		var phase := loop_pos / LOOP_SECONDS
		_set_frame(_frame_for_phase(phase))
		if sprite_holder != null:
			sprite_holder.position = sprite_base_position + Vector2(_shake_x_for_phase(phase), 0.0)


	func _build_nodes() -> void:
		sprite_holder = Control.new()
		sprite_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sprite_holder.z_index = 10
		add_child(sprite_holder)

		atlas_texture = AtlasTexture.new()
		atlas_texture.atlas = null if _headless_mode() else sheet_texture
		atlas_texture.region = Rect2(Vector2.ZERO, FRAME_SIZE)

		sprite = TextureRect.new()
		sprite.texture = _transparent_fallback_texture(Vector2i(int(FRAME_SIZE.x), int(FRAME_SIZE.y))) if _headless_mode() else atlas_texture
		sprite.set_anchors_preset(Control.PRESET_FULL_RECT)
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sprite_holder.add_child(sprite)

		bubble = TextureRect.new()
		bubble.texture = bubble_texture
		bubble.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bubble.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bubble)

		bubble_text = Control.new()
		bubble_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bubble_text)

		bubble_line_top = _make_bubble_label("I must become an")
		bubble_text.add_child(bubble_line_top)

		bubble_line_big = _make_bubble_label("IDLE ELITIST!")
		bubble_text.add_child(bubble_line_big)

		xp_layer = Control.new()
		xp_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
		xp_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		xp_layer.z_index = 30
		add_child(xp_layer)


	func _make_bubble_label(text: String) -> Label:
		var label := Label.new()
		label.text = text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", COLOR_INK)
		label.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0, 0.64))
		label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.10))
		label.add_theme_constant_override("outline_size", 1)
		label.add_theme_constant_override("shadow_offset_x", 0)
		label.add_theme_constant_override("shadow_offset_y", 1)
		if bubble_font != null:
			label.add_theme_font_override("font", bubble_font)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return label


	func _load_bubble_font() -> void:
		if ResourceLoader.exists(FONT_PATH):
			var loaded := load(FONT_PATH)
			if loaded is Font:
				var bold := FontVariation.new()
				bold.base_font = loaded
				bold.variation_embolden = 1.45
				bubble_font = bold
		if bubble_font == null:
			bubble_font = ThemeDB.fallback_font


	func _sync_layout() -> void:
		if size.x <= 1.0 or size.y <= 1.0:
			return
		var sprite_size := clampf(minf(size.x, size.y) * 2.05, 500.0, 750.0)
		var center := size * 0.5 + Vector2(0.0, 360.0)
		sprite_base_position = center - Vector2(sprite_size, sprite_size) * 0.5
		sprite_base_position.y -= sprite_size * 0.22
		if sprite_holder != null:
			sprite_holder.size = Vector2(sprite_size, sprite_size)
			sprite_holder.position = sprite_base_position

		var bubble_width := clampf(size.x * 0.78, 1240.0, 1760.0)
		var bubble_height := bubble_width * 0.43
		var bubble_y := maxf(56.0, sprite_base_position.y - bubble_height + 166.0)
		if bubble != null:
			bubble.size = Vector2(bubble_width, bubble_height)
			bubble.position = Vector2((size.x - bubble_width) * 0.5, bubble_y)
		if bubble_text != null:
			bubble_text.size = Vector2(bubble_width * 0.92, bubble_height * 0.78)
			bubble_text.position = Vector2((size.x - bubble_text.size.x) * 0.5, bubble_y + bubble_height * 0.135)
			_layout_bubble_text()


	func _layout_bubble_text() -> void:
		if bubble_text == null:
			return
		var top_height := bubble_text.size.y * 0.30
		var big_height := bubble_text.size.y * 0.70
		var small_font := int(clampf(bubble_text.size.x * 0.064, 48.0, 94.0))
		var big_font := int(clampf(bubble_text.size.x * 0.136, 122.0, 210.0))
		if bubble_line_top != null:
			bubble_line_top.size = Vector2(bubble_text.size.x, top_height)
			bubble_line_top.position = Vector2.ZERO
			bubble_line_top.add_theme_font_size_override("font_size", small_font)
		if bubble_line_big != null:
			bubble_line_big.size = Vector2(bubble_text.size.x, big_height)
			bubble_line_big.position = Vector2(0.0, top_height - bubble_text.size.y * 0.20)
			bubble_line_big.add_theme_font_size_override("font_size", big_font)


	func _frame_for_phase(phase: float) -> int:
		if phase < 0.08:
			return 0
		if phase < 0.15:
			return 1
		if phase < 0.22:
			return 2
		if phase < 0.92:
			return 3
		return 0


	func _set_frame(frame: int) -> void:
		if _headless_mode() or frame == current_frame or atlas_texture == null:
			return
		current_frame = frame
		atlas_texture.region = Rect2(Vector2(FRAME_SIZE.x * frame, 0.0), FRAME_SIZE)


	func _shake_x_for_phase(phase: float) -> float:
		if phase < 0.22 or phase >= 0.31:
			return 0.0
		if phase < 0.232:
			return -12.0
		if phase < 0.244:
			return 12.0
		if phase < 0.256:
			return -12.0
		if phase < 0.268:
			return 12.0
		if phase < 0.280:
			return -7.0
		if phase < 0.292:
			return 7.0
		if phase < 0.302:
			return -3.0
		return 3.0


	func _spawn_xp_drop() -> void:
		if xp_layer == null or sprite_holder == null:
			return
		var amount := rng.randi_range(1, 3)
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		var sprite_size := sprite_holder.size.x
		var start := sprite_base_position + Vector2(
			sprite_size * 0.5 + side * rng.randf_range(sprite_size * 0.18, sprite_size * 0.30),
			rng.randf_range(sprite_size * 0.18, sprite_size * 0.25)
		)
		var color: Color = SKILL_THEME_COLORS[rng.randi_range(0, SKILL_THEME_COLORS.size() - 1)]
		_float_reward("+%s XP" % amount, color, start)


	func _float_reward(text: String, color: Color, center: Vector2) -> void:
		var reward_size := Vector2(240, 64)
		var holder := Control.new()
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.size = reward_size
		holder.position = center - reward_size * 0.5
		holder.modulate.a = 0.0
		holder.scale = Vector2(0.82, 0.82)
		xp_layer.add_child(holder)

		var shadow := Label.new()
		shadow.text = text
		shadow.size = reward_size
		shadow.position = Vector2(1.5, 2)
		shadow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		shadow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		shadow.add_theme_font_size_override("font_size", 48)
		shadow.add_theme_color_override("font_color", COLOR_INK)
		shadow.modulate = Color(1, 1, 1, 0.34)
		holder.add_child(shadow)

		var label := Label.new()
		label.text = text
		label.size = reward_size
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 48)
		label.add_theme_color_override("font_color", color)
		label.add_theme_color_override("font_outline_color", COLOR_INK)
		label.add_theme_constant_override("outline_size", 7)
		holder.add_child(label)

		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(holder, "position", holder.position + Vector2(0, -66), 1.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(holder, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(holder, "modulate:a", 1.0, 0.08)
		tween.tween_property(holder, "modulate:a", 0.0, 0.85).set_delay(0.55)
		tween.chain().tween_callback(_queue_free_instance_id.bind(holder.get_instance_id()))


	func _load_texture_or_fallback(path: String, fallback_size: Vector2i) -> Texture2D:
		if _headless_mode():
			return _transparent_fallback_texture(fallback_size)
		var loaded = load(path)
		if loaded is Texture2D:
			return loaded
		return _transparent_fallback_texture(fallback_size)


	func _transparent_fallback_texture(fallback_size: Vector2i) -> Texture2D:
		if transparent_texture != null:
			return transparent_texture
		if _headless_mode():
			var placeholder := PlaceholderTexture2D.new()
			placeholder.size = Vector2(maxi(1, fallback_size.x), maxi(1, fallback_size.y))
			transparent_texture = placeholder
			return transparent_texture
		var image := Image.create(maxi(1, fallback_size.x), maxi(1, fallback_size.y), false, Image.FORMAT_RGBA8)
		image.fill(Color(1.0, 1.0, 1.0, 0.0))
		transparent_texture = ImageTexture.create_from_image(image)
		return transparent_texture


	func _queue_free_instance_id(instance_id: int) -> void:
		var node := instance_from_id(instance_id) as Node
		if node != null and is_instance_valid(node):
			node.queue_free()


	func _headless_mode() -> bool:
		return DisplayServer.get_name() == "headless"

const BOOT_WARMUP_MIN_VISIBLE_SECONDS := 1.65

var host
var active := false
var layer: CanvasLayer
var overlay: Control
var background: ColorRect
var splash: Control
var shade: ColorRect
var footer: VBoxContainer
var label: Label
var progress_bar
var cancel_requested := false
var game_revealed := false
var show_msec := 0
var hide_requested := false
var boot_early_services_started := false


func _init(host_ref) -> void:
	host = host_ref


func _boot_progress_step(text: String, progress: float):
	_set_progress(text, progress)
	await host.get_tree().process_frame


func _finish_boot_render_async():
	if not host.is_inside_tree():
		return
	host.current_screen = "skill"
	host.boot_detail_render_in_progress = true
	host.boot_detail_card_yield = true
	_set_progress("Drawing first skill...", 0.70)
	await host._navigation_shell()._render_screen(true, -1, true)
	host.boot_detail_card_yield = false
	host.boot_detail_render_in_progress = false
	host.boot_lazy_background_mount_allowed = false
	_set_progress("Finishing startup...", 0.74)
	if not host.startup_initialized:
		host.startup_initialized = true
		host._crash_report_runtime().write_session_marker("running")
	host._update_ui(0.0, true)
	_dismiss_boot_splash_for_play()
	if host.app_resume_repair_pending:
		host._app_lifecycle_runtime().call_deferred("_repair_after_app_resume")
	host._activity_unlock_runtime().call_deferred("_run_startup_auto_unlock_lockpads")
	if DisplayServer.get_name() != "headless":
		if not boot_early_services_started:
			host._audio_director().call_deferred("_prepare_audio_buses")
			host._navigation_shell().call_deferred("_ensure_nav_bar_icons")
			host._navigation_shell().call_deferred("_sync_hero_nav_button", true)
			host._navigation_shell().call_deferred("_sync_hub_nav_button", true)
			host._navigation_shell().call_deferred("_sync_shop_nav_button", true)
			host._profile_chat_overlay_surface().call_deferred("_ensure_chat_strip")
		host._achievement_toast_surface().call_deferred("show_pending_completed_toasts")
		host._save_runtime().call_deferred("_schedule_boot_post_load_simulation")
		call_deferred("begin_background_boot_validation")
		host._ad_bonus_runtime().call_deferred("_init_ads")


func validate_state(priority_skill_ids: Array = []) -> void:
	var validate_all := priority_skill_ids.is_empty()
	SkillState.invalidate_stat_caches(host)
	host.fishing_runtime.equipped_tool_id = "hands"
	for def in host.skill_defs:
		var skill_id := str(def["id"])
		if not host.skills.has(skill_id):
			host.skills[skill_id] = {"xp": 0, "level": 1}
		if not host.stamina.has(skill_id):
			host.stamina[skill_id] = float(SkillState.max_stamina(host, skill_id))
		if not host.stamina_bank.has(skill_id):
			host.stamina_bank[skill_id] = 0.0
		if validate_all or priority_skill_ids.has(skill_id):
			_validate_skill_actions(skill_id, true)
		else:
			_validate_skill_actions(skill_id, false)
		SkillState.recalculate_level(host, skill_id)
	if not host.skills.has(host.selected_skill_id):
		host.selected_skill_id = "fight"
	host._passive_modules_runtime().sync_passive_module_unlocks(host._unix_now())
	host.thieving_state.ensure_all_trophy_state()
	host._hub_runtime().sync_trophy_level_from_thieving()
	host._hub_surface()._validate_hub_module_positions()
	host._hub_runtime().sync_missions()
	SkillState.invalidate_stat_caches(host)


func validate_state_bootstrap() -> void:
	for def in host.skill_defs:
		var skill_id := str(def["id"])
		if not host.skills.has(skill_id):
			host.skills[skill_id] = {"xp": 0, "level": 1}
		if not host.stamina.has(skill_id):
			host.stamina[skill_id] = float(SkillState.max_stamina(host, skill_id))
		if not host.stamina_bank.has(skill_id):
			host.stamina_bank[skill_id] = 0.0
	if not host.skills.has(host.selected_skill_id):
		host.selected_skill_id = "fight"


func prepare_selected_skill_for_render(boot_fast := false) -> void:
	validate_state_bootstrap()
	if not host.skills.has(host.selected_skill_id):
		host.selected_skill_id = "fight"
	if host._onboarding_runtime()._onboarding_path_active() and not host._onboarding_runtime()._onboarding_skill_accessible(host.selected_skill_id):
		host.selected_skill_id = host.TUTORIAL_STARTER_SKILL_ID
	if boot_fast:
		var prepared_action_ids := {}
		for entry in host._skill_detail_surface()._visible_detail_entries_for_skill(host.selected_skill_id):
			var entry_data := entry as Dictionary
			if str(entry_data.get("kind", "")) == "thieving_heist":
				continue
			var action := entry_data.get("action", {}) as Dictionary
			if action.is_empty():
				continue
			var action_id := str(action.get("id", ""))
			if action_id.is_empty() or prepared_action_ids.has(action_id):
				continue
			prepared_action_ids[action_id] = true
			var key: String = host._action_key(host.selected_skill_id, action_id)
			if not host.mastery.has(key):
				host.mastery[key] = {"xp": 0, "level": 0}
			MasteryState.recalculate_host(host, key)
		_ensure_skill_mastery_keys(host.selected_skill_id)
		SkillState.recalculate_level(host, host.selected_skill_id, false)
		return
	for action in host.actions_by_skill.get(host.selected_skill_id, []):
		var action_data := action as Dictionary
		if host._convergence_runtime()._is_convergence_action(action_data):
			host._convergence_runtime()._ensure_convergence_state(str(action_data.get("id", "")))
			continue
		if host._passive_modules_runtime().is_passive_action(action_data):
			host._passive_modules_runtime().ensure_passive_module_state(str(action_data.get("id", "")), host._unix_now())
			continue
		var key: String = host._action_key(host.selected_skill_id, str(action_data.get("id", "")))
		if not host.mastery.has(key):
			host.mastery[key] = {"xp": 0, "level": 0}
		MasteryState.recalculate_host(host, key)
	SkillState.recalculate_level(host, host.selected_skill_id, false)


func begin_background_boot_validation() -> void:
	if not host.is_inside_tree():
		return
	if host.deferred_selected_skill_mastery_pending:
		host.deferred_selected_skill_mastery_pending = false
		prepare_selected_skill_for_render(false)
	if not host.deferred_skill_validation_pending:
		return
	if not host._save_runtime().pending_save_restore_data.is_empty():
		host._save_runtime()._load_game_secondary_restore()
	await host.get_tree().process_frame
	_validate_remaining_skills_deferred()


func _ensure_skill_mastery_keys(skill_id: String) -> void:
	for action in host.actions_by_skill.get(skill_id, []):
		if host._convergence_runtime()._is_convergence_action(action as Dictionary) or host._passive_modules_runtime().is_passive_action(action as Dictionary):
			continue
		var key: String = host._action_key(skill_id, str(action["id"]))
		if not host.mastery.has(key):
			host.mastery[key] = {"xp": 0, "level": 0}


func _validate_skill_actions(skill_id: String, recalculate_mastery: bool) -> void:
	for action in host.actions_by_skill.get(skill_id, []):
		if host._convergence_runtime()._is_convergence_action(action as Dictionary):
			host._convergence_runtime()._ensure_convergence_state(str(action.get("id", "")))
			continue
		if host._passive_modules_runtime().is_passive_action(action as Dictionary):
			host._passive_modules_runtime().ensure_passive_module_state(str(action.get("id", "")), host._unix_now())
			continue
		var key: String = host._action_key(skill_id, str(action["id"]))
		if not host.mastery.has(key):
			host.mastery[key] = {"xp": 0, "level": 0}
		if recalculate_mastery:
			MasteryState.recalculate_host(host, key)


func _validate_remaining_skills_deferred() -> void:
	if not host.deferred_skill_validation_pending or not host.is_inside_tree():
		return
	for def in host.skill_defs:
		if not host.deferred_skill_validation_pending or not host.is_inside_tree():
			return
		var skill_id := str(def.get("id", ""))
		if skill_id.is_empty() or skill_id == host.selected_skill_id:
			continue
		_validate_skill_actions(skill_id, true)
		SkillState.recalculate_level(host, skill_id)
		await host.get_tree().process_frame
	host.deferred_skill_validation_pending = false
	SkillState.invalidate_stat_caches(host)
	if host.current_screen == "skill" or host.current_screen == "home":
		host._update_ui(0.0)


func build_overlay() -> void:
	layer = CanvasLayer.new()
	layer.layer = host.BOOT_WARMUP_LAYER
	host.add_child(layer)

	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	layer.add_child(overlay)

	background = ColorRect.new()
	background.color = host._theme_paper_color()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(background)

	splash = _BootFlexLoadingAnimation.new()
	splash.set_anchors_preset(Control.PRESET_FULL_RECT)
	splash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(splash)

	shade = ColorRect.new()
	shade.color = Color(0.10, 0.08, 0.04, 0.04)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(shade)

	footer = VBoxContainer.new()
	footer.anchor_left = 0.5
	footer.anchor_right = 0.5
	footer.anchor_top = 1.0
	footer.anchor_bottom = 1.0
	footer.offset_left = -310
	footer.offset_right = 310
	footer.offset_top = -215
	footer.offset_bottom = -105
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 17)
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.visible = false
	overlay.add_child(footer)

	label = host._label("Warming up...", 58, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	label.add_theme_color_override("font_outline_color", host.COLOR_INK)
	label.add_theme_constant_override("outline_size", 9)
	footer.add_child(label)

	progress_bar = ThemeStyles.progress_bar(host.COLOR_GREEN, 34, 0.0)
	progress_bar.custom_minimum_size = Vector2(590, 17)
	progress_bar.border_color = host.COLOR_INK
	footer.add_child(progress_bar)


func show_overlay() -> void:
	active = true
	game_revealed = false
	hide_requested = false
	show_msec = Time.get_ticks_msec()
	if overlay == null:
		return
	host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(overlay, true)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	host._app_lifecycle_runtime().set_canvas_item_alpha_if_changed(overlay, 1.0)
	if splash != null and is_instance_valid(splash) and splash.has_method("restart"):
		splash.call("restart")
	_set_progress("Warming up...", 0.0)


func hide_overlay() -> void:
	if overlay == null or not is_instance_valid(overlay) or overlay.is_queued_for_deletion():
		active = false
		return
	if hide_requested:
		return
	hide_requested = true
	if BOOT_WARMUP_MIN_VISIBLE_SECONDS > 0.0 and show_msec > 0:
		var visible_elapsed := float(Time.get_ticks_msec() - show_msec) / 1000.0
		var remaining := BOOT_WARMUP_MIN_VISIBLE_SECONDS - visible_elapsed
		if remaining > 0.0:
			await host.get_tree().create_timer(remaining).timeout
			if overlay == null or not is_instance_valid(overlay) or overlay.is_queued_for_deletion():
				active = false
				return
	active = false
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host._clear_page_transient_input_state()
	var tween: Tween = host.create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_finish_overlay_hide)


func _finish_overlay_hide() -> void:
	if overlay != null and is_instance_valid(overlay):
		if splash != null and is_instance_valid(splash) and splash.has_method("stop"):
			splash.call("stop")
	if layer != null and is_instance_valid(layer):
		layer.queue_free()
	layer = null
	overlay = null
	background = null
	splash = null
	shade = null
	footer = null
	label = null
	progress_bar = null


func _add_boot_warmup_texture_path(paths: Array, path: String) -> void:
	if path.is_empty() or paths.has(path):
		return
	paths.append(path)


func _set_progress(text: String, progress: float) -> void:
	if label != null:
		label.text = text
	if progress_bar != null:
		progress_bar.set_value(clampf(progress, 0.0, 1.0) * 100.0)


func _reveal_game_under_boot_splash() -> void:
	if game_revealed or overlay == null or not is_instance_valid(overlay):
		return
	game_revealed = true


func _dismiss_boot_splash_for_play() -> void:
	active = false
	if overlay == null or not is_instance_valid(overlay):
		return
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if footer != null and is_instance_valid(footer):
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(footer, false)
	hide_overlay()


func reset_for_shutdown() -> void:
	cancel_requested = true
	active = false
	game_revealed = false
	show_msec = 0
	hide_requested = false
	layer = null
	overlay = null
	background = null
	splash = null
	shade = null
	footer = null
	label = null
	progress_bar = null


func apply_theme_background() -> void:
	if background != null and is_instance_valid(background):
		background.color = host._theme_paper_color()
