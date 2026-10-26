extends TextureButton

var host
var skill_id := ""
var icon: TextureRect
var off_material: ShaderMaterial
var fade: Tween
var initialized := false
var shown := false

func setup(host_ref, skill: String) -> void:
	host = host_ref
	skill_id = skill
	name = "AutoEatCandyToggle"
	texture_normal = host.visual_texture_cache._visual_fallback_texture()
	ignore_texture_size = true
	stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	custom_minimum_size = Vector2(99, 99)
	size = Vector2(99, 99)
	position = Vector2(-86, 62)
	focus_mode = Control.FOCUS_NONE
	z_index = 4095
	z_as_relative = false
	tooltip_text = "Auto eat candy: 10–15 stamina. One piece may exceed maximum stamina."
	add_to_group("auto_eat_candy_toggle")
	icon = TextureRect.new()
	icon.texture = load("res://assets/content/events/halloween/candy.tres")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size = Vector2(80, 80)
	icon.position = (size - icon.size) * 0.5
	icon.pivot_offset = icon.size * 0.5
	icon.rotation = deg_to_rad(-45.0)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	off_material = host._fishing_ui_surface()._auto_eat_fish_solid_material(icon.texture)
	off_material.set_shader_parameter("fill_color", Color("#77726d", 0.35))
	add_child(icon)
	host._fishing_ui_surface()._connect_fishing_button(self, toggle_candy)
	host._halloween_runtime().changed.connect(sync)

func _ready() -> void:
	sync()

func sync() -> void:
	var runtime = host._halloween_runtime()
	var next_shown: bool = runtime.ever_earned and (runtime.active() or runtime.candy > 0)
	var enabled: bool = runtime.auto_by_skill.get(skill_id, false)
	icon.material = null if enabled else off_material
	disabled = not next_shown
	mouse_filter = Control.MOUSE_FILTER_STOP if next_shown else Control.MOUSE_FILTER_IGNORE
	if initialized and shown == next_shown: return
	shown = next_shown
	if is_instance_valid(fade): fade.kill()
	if not initialized:
		initialized = true
		visible = shown
		modulate.a = 1.0 if shown else 0.0
		return
	if shown: show()
	fade = create_tween()
	fade.tween_property(self, "modulate:a", 1.0 if shown else 0.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if not shown: fade.tween_callback(hide)

func toggle_candy() -> void:
	host._action_runtime()._cancel_pending_stamina_gauge_click()
	var runtime = host._halloween_runtime()
	runtime.set_auto(skill_id, not runtime.auto_by_skill.get(skill_id, false))
	host._audio_director()._play_click_sfx()

func _exit_tree() -> void:
	if is_instance_valid(fade): fade.kill()


func _make_custom_tooltip(_text: String) -> Object:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fffaf0")
	style.border_color = Color("#171615")
	style.set_border_width_all(4)
	style.set_corner_radius_all(18)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]: style.set_content_margin(side, 18)
	panel.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = "Auto eat candy\n10-15 stamina\nOne piece can exceed maximum."
	label.add_theme_font_size_override("font_size", 52)
	label.add_theme_color_override("font_color", Color("#171615"))
	label.custom_minimum_size.x = 550
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(label)
	return panel
