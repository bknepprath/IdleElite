extends Control

const Styles := preload("res://scripts/ui/activity_card_styles.gd")
const Recovery := preload("res://scripts/gameplay/recovery_modules.gd")
const Blocker := preload("res://scripts/ui/project_resource_blocker.gd")
const Wisdom := preload("res://scripts/progression/wisdom_state.gd")
var host
var skill_id: String
var action: Dictionary
var project: Dictionary
var barrier_material: String
var card_root: Control
var fracture: Control
var title: Label
var blockers := {}
var damage_state := -1
var reveal_motion: Tween
var reveal_started := false
var handoff_started := false
var elapsed := 0.0

static func height_for(data: Dictionary, _focused := true) -> float:
	var material := str((data.get("unlock_project", {}) as Dictionary).get("material", "timber"))
	var cover_clearance := 0.0 if material in ["timber", "stone"] else 96.0
	return cover_clearance + Styles.face_height_for_action(data, 360.0) + (Styles.RECOVERY_ACTIVITY_CARD_DEPTH_OFFSET.y if Recovery.has_recovery(data) else Styles.NORMAL_ACTIVITY_CARD_DEPTH_OFFSET.y)

func setup(host_ref, owner_skill: String, data: Dictionary, width: float, _focused := true) -> void:
	host = host_ref
	skill_id = owner_skill
	action = data
	project = data.unlock_project
	name = "Project_" + str(project.id)
	add_to_group("activity_project_panels")
	custom_minimum_size = Vector2(width, height_for(data))
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_PASS
	barrier_material = str(project.get("material", "stone" if skill_id in ["fight", "thieving"] else "timber"))
	card_root = Control.new()
	card_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card_root)
	card_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fracture = preload("res://scripts/ui/project_fracture.gd").new()
	fracture.material_id = barrier_material
	card_root.add_child(fracture)
	fracture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title = host._label(str(action.name), 60, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_font_override("font", host.app_bold_font)
	title.add_theme_constant_override("outline_size", host.ACTION_CARD_TITLE_OUTLINE_SIZE)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("line_spacing", -22)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_root.add_child(title)
	for row in requirements():
		var blocker := Blocker.new()
		blocker.setup(host, row, barrier_material)
		blocker.pressed.connect(_open_source.bind(str(row.id)))
		card_root.add_child(blocker)
		blockers[str(row.id)] = blocker
	resized.connect(_layout)
	host._project_runtime().changed.connect(_on_changed)
	_layout()
	sync()

func _layout() -> void:
	if not is_instance_valid(title): return
	title.position = Vector2(120, 48)
	title.size = Vector2(maxf(100, size.x - 240), 108)
	var width := blockers.size() * 228.0 - 8.0
	var x := (size.x - width) * 0.5
	for blocker in blockers.values():
		blocker.position = Vector2(x, 145)
		blocker.size = Vector2(220, 220)
		x += 228

func requirements() -> Array:
	var rows := {}
	var runtime = host._project_runtime()
	for step in project.steps:
		var resource := str(step.resource)
		if not rows.has(resource):
			var info: Dictionary = runtime.resource_info(resource)
			rows[resource] = {"id": resource, "amount": 0, "target": 0, "icon": str(info.get("icon", "")), "tooltip": str(info.get("name", resource))}
		rows[resource].amount += runtime.amount(str(project.id), str(step.id))
		rows[resource].target += int(step.target)

	var wisdom := int(action.get("wisdom_required", 0))
	if wisdom > 0:
		rows.wisdom = {"id": "wisdom", "amount": mini(Wisdom.total(host, skill_id), wisdom), "target": wisdom, "icon": "assets/content/icons/resources/wisdom.png", "tooltip": "Wisdom"}
	return rows.values()

func sync() -> void:
	if handoff_started: return
	var rows := requirements()
	var ready := true
	var damage := 0.0
	for row in rows:
		blockers[str(row.id)].update_requirement(row)
		if int(row.amount) < int(row.target): ready = false
		damage += float(row.amount) / maxi(1, int(row.target))
	damage /= maxi(1, rows.size())
	_update_damage(clampi(int(ceil(damage * fracture.last_stage())), 0, fracture.last_stage()))
	if ready and not reveal_started and is_inside_tree():
		reveal_started = true
		for blocker in blockers.values(): blocker.disabled = true
		# Keep the cover opaque until its activity has actually been mounted.
		# A timer-driven fade can otherwise finish before a queued refresh runs.
		host._project_runtime().refresh_cleared_barrier(skill_id)

func reveal_mounted_activity() -> void:
	if handoff_started: return
	handoff_started = true
	set_process(false)
	remove_from_group("activity_project_panels")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for blocker in blockers.values():
		blocker.disabled = true
		blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# This is the original cover, retained above the real activity in its slot.
	# Fading only the cover leaves the activity and surrounding layout opaque.
	get_parent().move_child(self, -1)
	# Card faces, locks and pin badges use their own elevated canvas layers.
	# Keep the outgoing cover above all of them while retaining scroll clipping.
	z_as_relative = false
	z_index = preload("res://scripts/module_ui/runtime.gd").MODULE_PIN_BADGE_Z_INDEX + 100
	if not is_visible_in_tree():
		queue_free()
		return
	reveal_motion = create_tween()
	reveal_motion.tween_property(card_root, "modulate:a", 0.0, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	reveal_motion.tween_callback(queue_free)

func _open_source(resource: String) -> void:
	if resource == "wisdom":
		var best := {}
		for source in Wisdom.sources(host, skill_id):
			if host._activity_unlock_runtime()._is_action_unlocked(skill_id, source.action) and (best.is_empty() or int(source.action.unlock) > int(best.action.unlock)): best = source
		if not best.is_empty(): host._project_runtime().open_source(skill_id, str(best.action.id))
		return
	var best: Dictionary = host._project_runtime().best_source(resource)
	if not best.is_empty(): host._project_runtime().open_source(str(best.skill), str(best.action.id))

func _update_damage(state: int) -> void:
	if state == damage_state: return
	fracture.set_stage(state, damage_state >= 0 and state > damage_state)
	damage_state = state

func _on_changed(id: String) -> void:
	if id == str(project.id): sync()

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	elapsed += delta
	if elapsed >= 0.4: elapsed = 0; sync()

func _exit_tree() -> void:
	for tween in [reveal_motion]:
		if is_instance_valid(tween): tween.kill()
