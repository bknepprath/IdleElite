extends TextureRect

# A local, input-transparent cue. Its owner supplies an authored target box;
# no texture measurements determine scale or placement.
const ARROW = preload("res://assets/content/ui/tutorial-arrow-curved.png")
const DRAW_BOX := Vector2(82, 132)
const TIP := Vector2(0.48, 0.98)
const GAP := 24.0

var host
var interaction_id := ""
var target: Control
var target_box := Rect2()
var target_centered_box := false
var approach_from_top := false
var eligible: Callable
var elapsed := 0.0
var reveal_seconds := 0.0

func _init() -> void:
	name = "SoftTutorialArrow"
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	texture = ARROW
	size = DRAW_BOX
	rotation = -PI * 0.5
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_as_relative = false
	z_index = 750
	visible = false

func _process(delta: float) -> void:
	elapsed += delta
	if not is_instance_valid(target) or target.is_queued_for_deletion():
		visible = false
		return
	var onboarding = host._onboarding_runtime()
	var allowed: bool = (
		not onboarding.soft_interactions_seen.has(interaction_id)
		and target.is_visible_in_tree()
		and not onboarding.tutorial_active
		and not host._tutorial_overlay_surface().blocking_tip_active
		and not host._skill_swipe_activity_surface().skill_swipe_tracking
		and not host._input_routing_shell()._any_modal_overlay_visible()
		and (not eligible.is_valid() or eligible.call())
	)
	var box := target_box
	if not box.has_area():
		box = Rect2(Vector2.ZERO, target.size)
	elif target_centered_box:
		box.position += target.size * 0.5
	# Approach the centre from the left, ending outside the target artwork.
	var point: Vector2 = target.get_global_transform() * Vector2(box.position.x - GAP - 4.0 - sin(elapsed * TAU / 2.4) * 4.0, box.get_center().y)
	if approach_from_top:
		rotation=0
		point=target.get_global_transform()*Vector2(box.get_center().x,box.position.y-GAP-4.0-sin(elapsed*TAU/2.4)*4.0)
	position = get_parent().get_global_transform().affine_inverse() * point - (size * TIP).rotated(rotation)
	var bounds: Rect2 = get_global_transform() * Rect2(Vector2.ZERO, size)
	allowed = allowed and get_viewport_rect().encloses(bounds)
	var ancestor := get_parent()
	while ancestor is Control:
		if ancestor.clip_contents and not ancestor.get_global_rect().encloses(bounds):
			allowed = false
		ancestor = ancestor.get_parent()
	visible = allowed
	reveal_seconds = minf(0.25, reveal_seconds + delta) if allowed else 0.0
	modulate.a = reveal_seconds / 0.25
