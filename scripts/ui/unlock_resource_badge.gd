extends Control

# The badges that are showing pack into the top right corner of the art. Each
# is 86 px wide and sits this far from the one before it, so two overlap a bit.
const CORNER_OVERHANG := 30.0
const PACKED_STEP := 58.0
# A finger needs more room than the icon covers.
const TAP_MARGIN := 14.0
# The copy of the icon that rises off the badge when the item is earned.
const GAIN_ICON_SIZE := Vector2(80, 80)

var host
var source_key: String
var drop: Dictionary
var icon: TextureRect
var last_award_frame := -1
var visibility_motion: Tween
var availability_initialized := false
var needed := false
var slot_index := 0
# How far the badge hangs over the corner, to the right and upward. A Fishing
# tile has a neighbour 14 px to its right, so its badges hang over less far.
var overhang := Vector2(CORNER_OVERHANG, CORNER_OVERHANG)

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
	if get_parent() == null: return
	# A badge that is not needed leaves no gap: the first one showing takes the
	# corner and the next closes up beside it.
	var rank := 0
	for sibling in get_parent().get_children():
		if sibling != self and sibling.has_method("accepts_tap_at") and sibling.needed and sibling.slot_index < slot_index: rank += 1
	position = Vector2(get_parent().size.x - size.x + overhang.x - rank * PACKED_STEP, -overhang.y)

# The tap target, only while the badge is showing.
func accepts_tap_at(global_point: Vector2) -> bool:
	return needed and is_visible_in_tree() and get_global_rect().grow(TAP_MARGIN).has_point(global_point)

# A tap says which locked activity this resource is filling. A second tap soon
# after goes to it.
func open_target() -> void:
	var runtime = host._project_runtime()
	runtime.open_target(str(drop.id), self, runtime.second_tap("badge:%s:%s" % [source_key, str(drop.id)]))

func _sync_availability() -> void:
	_show_needed(host._project_runtime().needed_resources.has(str(drop.id)))

# Shows the badge while what it stands for is still needed, and fades it otherwise.
func _show_needed(next_needed: bool) -> void:
	if availability_initialized and next_needed == needed: return
	needed = next_needed
	# Every badge on this art hears the same signal; place them once all have.
	if get_parent() != null:
		for sibling in get_parent().get_children():
			if sibling.has_method("accepts_tap_at"): sibling.call_deferred("_position_badge")
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

# Each success that sends the item lifts a copy of the icon off the badge. It
# rises and fades like every other gain on the page; until 2026-10-17 it slid
# down the page, to the locked frame or 180 px below the badge.
func _on_resource_sent(key: String, resource: String, _amount: int, _project_id: String) -> void:
	if resource != str(drop.id) or key != source_key or not is_visible_in_tree() or host.current_screen != "skill": return
	if last_award_frame == Engine.get_process_frames(): return
	var source_rect := get_global_rect()
	if not Rect2(Vector2.ZERO, host.size).intersects(source_rect): return
	var ancestor := get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer and not ancestor.get_global_rect().intersects(source_rect): return
		ancestor = ancestor.get_parent()
	last_award_frame = Engine.get_process_frames()
	host._reward_feedback_surface()._float_reward_icon(icon.texture, source_rect.get_center() - host.global_position - GAIN_ICON_SIZE * 0.5, GAIN_ICON_SIZE)

func _exit_tree() -> void:
	if is_instance_valid(visibility_motion): visibility_motion.kill()
