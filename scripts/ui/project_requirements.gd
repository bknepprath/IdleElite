extends PanelContainer

const Piece := preload("res://scripts/ui/project_requirement_piece.gd")
const Wisdom := preload("res://scripts/progression/wisdom_state.gd")
var host
var skill_id: String
var action: Dictionary
var project: Dictionary
var counts: Dictionary = {}
var step_bars: Dictionary = {}
var pieces: Dictionary = {}
var level_pieces: Array = []
var next_unlock := true
var cost_button: Button
var unlock_button: Button
var wisdom_piece: Button
var elapsed := 0.0
signal navigate_requested(skill_id: String, action_id: String)
signal unlock_requested

static func height_for(data: Dictionary, _focused := true) -> float:
	var definition: Dictionary = data.get("unlock_project", {})
	var levels: int = maxi(1, (data.get("requirements", []) as Array).size())
	return 300.0 + ((definition.get("steps", []) as Array).size() + levels + (1 if definition.has("cost") else 0) + (1 if int(data.get("wisdom_required", 0)) > 0 else 0)) * 300.0 + 120.0

func setup(host_ref, owner_skill: String, data: Dictionary, width: float, focused := true) -> void:
	host = host_ref
	skill_id = owner_skill
	action = data
	project = data.unlock_project
	next_unlock = focused
	name = "Project_" + str(project.id)
	add_to_group("activity_project_details")
	custom_minimum_size = Vector2(width, height_for(data, focused))
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_PASS
	var box := StyleBoxFlat.new()
	box.bg_color = Color("#30261e")
	box.border_color = Color("#171615")
	box.set_border_width_all(8)
	box.set_corner_radius_all(32)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 12
	box.content_margin_bottom = 20
	add_theme_stylebox_override("panel", box)
	var background := preload("res://scripts/ui/rounded_texture_rect.gd").new()
	background.texture = _texture(str(action.get("bg", action.get("background", ""))))
	background.radius = 32
	background.feather_height = 0
	background.aspect_mode = 2
	background.resized.connect(func():
		if background.texture != null: background.sample_zoom = maxf(1.0, background.size.y * background.texture.get_width() / maxf(1.0, background.size.x * background.texture.get_height()))
	)
	background.modulate = Color(0.6, 0.6, 0.6)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 0)
	add_child(stack)
	var header := PanelContainer.new()
	header.custom_minimum_size.y = 280
	header.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	stack.add_child(header)
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 22)
	header.add_child(content)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 12)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(margin)
	var title := host._label(str(action.name), 64, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT) as Label
	title.add_theme_constant_override("outline_size", 14)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	margin.add_child(title)
	var art := TextureRect.new()
	art.texture = _texture(str(action.get("art", "")))
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.custom_minimum_size = Vector2(250, 250)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(art)
	for step in project.steps:
		var source: Dictionary = host._action_data(str(step.source_skill), str(step.source_action))
		var piece := _piece(stack, "Successes", str(source.get("name", step.source_action)), _texture(str(source.get("art", ""))), str(step.source_skill))
		piece.set_meta("project_source", str(step.source_skill) + ":" + str(step.source_action))
		piece.pressed.connect(open_source.bind(str(step.source_skill), str(step.source_action)))
		pieces[str(step.id)] = piece
		counts[str(step.id)] = piece.count_label
		step_bars[str(step.id)] = piece.bar
	for requirement in host._activity_unlock_runtime()._action_unlock_requirements(skill_id, action):
		var owner := str(requirement.skill)
		var level := int(requirement.level)
		var piece := _piece(stack, "Level " + str(level), SkillState.skill_name(host.skill_defs, owner), _skill_icon(owner), owner)
		piece.pressed.connect(func(): navigate_requested.emit(owner, ""))
		level_pieces.append({"piece": piece, "skill": owner, "level": level})
	if project.has("cost"):
		var names: Array[String] = []
		for material in project.cost: names.append(host.material_runtime.display_name(str(material)))
		cost_button = _piece(stack, "Materials", ", ".join(names), _texture(host.material_runtime.icon_path(str(project.cost.keys()[0]))), skill_id)
		cost_button.pressed.connect(func(): host._project_runtime().commit(action); sync())
	if int(action.get("wisdom_required", 0)) > 0:
		wisdom_piece = _piece(stack, "Wisdom", SkillState.skill_name(host.skill_defs, skill_id), _texture("assets/content/icons/resources/wisdom.png"), skill_id)
		wisdom_piece.pressed.connect(_open_wisdom_source)
	unlock_button = Button.new()
	unlock_button.text = "Unlock"
	unlock_button.custom_minimum_size.y = 100
	unlock_button.add_theme_font_override("font", host.app_bold_font)
	unlock_button.add_theme_font_size_override("font_size", 60)
	unlock_button.add_theme_constant_override("outline_size", 12)
	unlock_button.add_theme_color_override("font_outline_color", Color("#171615"))
	unlock_button.add_theme_color_override("font_color", Color.WHITE)
	var unlock_style := StyleBoxFlat.new()
	unlock_style.bg_color = Color("#547a3c")
	unlock_style.border_color = Color("#171615")
	unlock_style.set_border_width_all(8)
	unlock_style.set_corner_radius_all(26)
	for key in ["normal", "hover", "pressed", "disabled"]: unlock_button.add_theme_stylebox_override(key, unlock_style)
	var disabled_style := unlock_style.duplicate() as StyleBoxFlat
	disabled_style.bg_color = Color("#51473a")
	unlock_button.add_theme_stylebox_override("disabled", disabled_style)
	unlock_button.pressed.connect(unlock)
	stack.add_child(unlock_button)
	host._project_runtime().changed.connect(_on_changed)
	sync()

func _texture(path: String) -> Texture2D:
	return host.visual_texture_cache._texture_or_visual_fallback(path) if not path.is_empty() else null

func _skill_icon(owner: String) -> Texture2D:
	return _texture(preload("res://scripts/ui/skill_icon_badge.gd").icon_path(owner))

func _piece(stack: VBoxContainer, title: String, source: String, texture: Texture2D, owner: String) -> Button:
	var piece := Piece.new()
	piece.setup(host, title, source, texture, ThemeStyles.skill_theme_color(owner, Color("#237cd5")))
	stack.add_child(piece)
	piece.add_to_group("feedback_help_buttons")
	return piece

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	elapsed += delta
	if elapsed < 0.4: return
	elapsed = 0.0
	sync()

func _on_changed(id: String) -> void:
	if id == str(project.id): sync()

func sync() -> void:
	var runtime = host._project_runtime()
	for step in project.steps:
		var earned: int = runtime.amount(str(project.id), str(step.id))
		pieces[str(step.id)].update_progress(float(earned) / maxi(1, int(step.target)), "%s/%s" % [earned, int(step.target)])
	for entry in level_pieces:
		var level := SkillState.skill_level(host.skills, entry.skill)
		var fraction: float = host._activity_unlock_runtime()._level_requirement_progress(str(entry.skill), int(entry.level))
		entry.piece.update_progress(fraction, "%s/%s" % [mini(level, entry.level), entry.level])
	if is_instance_valid(cost_button):
		var paid: bool = runtime.amount(str(project.id), "materials") == 1
		var fraction := 0.0
		var amounts: Array[String] = []
		for material in project.cost:
			var required := int(project.cost[material])
			var have := required if paid else mini(int(host.material_runtime.amount(str(material))), required)
			fraction += float(have) / maxi(1, required)
			amounts.append("%s/%s" % [have, required])
		cost_button.update_progress(fraction / maxi(1, project.cost.size()), " · ".join(amounts))
		cost_button.title_label.text = "Materials fitted" if paid else "Fit materials"
		cost_button.disabled = paid or not runtime.can_commit(action)
	if is_instance_valid(wisdom_piece):
		var required := int(action.wisdom_required)
		var have := mini(Wisdom.total(host, skill_id), required)
		wisdom_piece.update_progress(float(have) / maxi(1, required), "%s/%s" % [have, required])
	unlock_button.visible = true
	unlock_button.disabled = not host._activity_unlock_runtime()._can_unlock_action(skill_id, action)

func _open_wisdom_source() -> void:
	for source in Wisdom.sources(host, skill_id):
		if host._activity_unlock_runtime()._is_action_unlocked(skill_id, source.action):
			open_source(skill_id, str(source.action.id))
			return

func open_source(source_skill: String, source_action: String) -> void:
	navigate_requested.emit(source_skill, source_action)

func unlock() -> void:
	if not host._activity_unlock_runtime()._can_unlock_action(skill_id, action): return
	if host._activity_unlock_runtime()._finalize_manual_activity_unlock(skill_id, str(action.id)):
		unlock_requested.emit()
