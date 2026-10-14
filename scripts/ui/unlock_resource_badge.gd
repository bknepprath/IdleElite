extends Control

var host
var source_key: String
var drop: Dictionary
var icon: TextureRect
var flying: TextureRect
var motion: Tween
var last_award_frame := -1
var visibility_motion: Tween
var availability_initialized := false
var needed := false
var slot_index := 0

func setup(host_ref, skill_id: String, action: Dictionary) -> void:
	host = host_ref
	source_key = host._action_key(skill_id, str(action.id))
	drop = action.unlock_drop
	name = "UnlockResourceBadge"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 60
	size = Vector2(86, 86)
	icon = TextureRect.new()
	icon.texture = host.visual_texture_cache._texture_or_visual_fallback(str(drop.icon))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.size = Vector2(86, 86)
	add_child(icon)
	host._project_runtime().resource_sent.connect(_on_resource_sent)
	host._project_runtime().availability_changed.connect(_sync_availability)

func _ready() -> void:
	get_parent().resized.connect(_position_badge)
	_position_badge()
	_sync_availability()
	host._project_runtime().queue_availability_refresh()

func _position_badge() -> void:
	position = Vector2(get_parent().size.x - size.x + 30 - slot_index * 82, -30)

func _sync_availability() -> void:
	var next_needed: bool = host._project_runtime().needed_resources.has(str(drop.id))
	if availability_initialized and next_needed == needed: return
	needed = next_needed
	if is_instance_valid(visibility_motion): visibility_motion.kill()
	if not availability_initialized:
		availability_initialized = true
		visible = needed
		modulate.a = 1.0 if needed else 0.0
		return
	if needed: show()
	visibility_motion = create_tween()
	visibility_motion.tween_property(self, "modulate:a", 1.0 if needed else 0.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if not needed: visibility_motion.tween_callback(hide)

func _on_resource_sent(key: String, resource: String, _amount: int, project_id: String) -> void:
	if resource != str(drop.id) or key != source_key or not is_visible_in_tree() or host.current_screen != "skill": return
	if last_award_frame == Engine.get_process_frames() or is_instance_valid(flying): return
	var source_rect := get_global_rect()
	if not Rect2(Vector2.ZERO, host.size).intersects(source_rect): return
	var ancestor := get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer and not ancestor.get_global_rect().intersects(source_rect): return
		ancestor = ancestor.get_parent()
	last_award_frame = Engine.get_process_frames()
	var start := source_rect.get_center()
	var destination := start + Vector2(0, 180)
	for panel in get_tree().get_nodes_in_group("activity_project_panels"):
		if str(panel.project.id) == project_id and panel.is_visible_in_tree() and panel.blockers.has(resource):
			var target: Rect2 = panel.blockers[resource].get_global_rect()
			if Rect2(Vector2.ZERO, host.size).encloses(target): destination = target.get_center()
	flying = TextureRect.new()
	flying.texture = icon.texture
	flying.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	flying.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	flying.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flying.size = Vector2(80, 80)
	flying.position = start - flying.size * 0.5
	flying.z_index = 3500
	flying.z_as_relative = false
	host.add_child(flying)
	motion = create_tween()
	motion.tween_property(flying, "position", destination - flying.size * 0.5, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	motion.parallel().tween_property(flying, "modulate:a", 0.0, 0.18).set_delay(0.37)
	motion.tween_callback(func():
		if is_instance_valid(flying): flying.queue_free()
		flying = null
	)

func _exit_tree() -> void:
	if is_instance_valid(visibility_motion): visibility_motion.kill()
	if is_instance_valid(motion): motion.kill()
	if is_instance_valid(flying): flying.queue_free()
