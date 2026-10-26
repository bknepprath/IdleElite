extends ColorRect

# Reveal the finished, opaque card against its existing background. Fading each
# nested CanvasItem instead makes the card's backing, art and text bleed together.
const META := "activity_reveal_cover"
static var shared_reveal_shader: Shader
var target_ref: WeakRef
var host_ref: WeakRef
var revealed := 0.0

static func apply(target: Control, amount: float, host) -> void:
	if not is_instance_valid(target) or target.is_queued_for_deletion(): return
	target.modulate.a = 1.0
	var cover = target.get_meta(META) if target.has_meta(META) else null
	if cover is WeakRef: cover = cover.get_ref()
	if amount >= 1.0:
		if is_instance_valid(cover):
			cover.hide()
			cover.queue_free()
		if target.has_meta(META): target.remove_meta(META)
		return
	if not is_instance_valid(cover):
		cover = load("res://scripts/ui/reveal_cover.gd").new()
		cover.name = "ActivityRevealCover"
		cover.target_ref = weakref(target)
		cover.host_ref = weakref(host)
		cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cover.z_index = 4096
		cover.z_as_relative = false
		# Uniforms belong to each material; the immutable shader is shared by all
		# entrances instead of allocating another shader for every mounted card.
		if shared_reveal_shader == null:
			shared_reveal_shader = Shader.new()
			shared_reveal_shader.code = """shader_type canvas_item;
uniform vec4 paper : source_color;
uniform vec4 colors[5] : source_color;
uniform vec4 intro_color : source_color;
uniform float reveal = 1.0;
uniform float first_center;
uniform float spacing;
uniform vec2 header_offset;
uniform vec2 header_scale;
uniform float cover_alpha;
void fragment() {
 vec2 uv = header_offset + UV * header_scale;
 vec4 tint = colors[0];
 for (int i = 1; i < 5; i++) {
  tint = mix(tint, colors[i], smoothstep(first_center + float(i-1)*spacing, first_center + float(i)*spacing, uv.x));
 }
 float strength = (0.12 + 0.20*smoothstep(0.0, 0.5, uv.y))*(1.0-smoothstep(0.52, 1.0, uv.y));
 if (uv.y < 0.0 || uv.y > 1.0) strength = 0.0;
 COLOR = vec4(mix(paper, mix(intro_color, tint, reveal), strength).rgb, cover_alpha);
}"""
		var mat := ShaderMaterial.new()
		mat.shader = shared_reveal_shader
		cover.material = mat
		host.add_child(cover)
		cover.set_as_top_level(true)
		cover.add_to_group("activity_reveal_covers")
		target.set_meta(META, weakref(cover))
	cover.revealed = clampf(amount, 0.0, 1.0)
	cover._sync()

static func apply_safe(amount: float, target_id: int, host) -> void:
	apply(instance_from_id(target_id) as Control, amount, host)

func _process(_delta: float) -> void:
	_sync()

func _sync() -> void:
	var target = target_ref.get_ref()
	var host = host_ref.get_ref()
	if not is_instance_valid(target) or target.is_queued_for_deletion() or not is_instance_valid(host):
		hide()
		queue_free()
		return
	visible = target.is_visible_in_tree() and host.current_screen == "skill" and not host._input_routing_shell()._any_modal_overlay_visible()
	var bounds: Rect2 = target.get_global_rect()
	# Locks and the dimensional card edge extend a few pixels past the card root.
	if target.get_parent() != host.desktop_layout.carousel_frame:
		bounds = bounds.grow_individual(22.0, 4.0, 22.0, 22.0)
	var ancestor = target.get_parent()
	while ancestor is Control:
		if ancestor.clip_contents: bounds = bounds.intersection(ancestor.get_global_rect())
		ancestor = ancestor.get_parent()
	global_position = bounds.position
	size = bounds.size
	material.set_shader_parameter("paper", host._theme_paper_color())
	material.set_shader_parameter("cover_alpha", 1.0 - revealed)
	var header = host.desktop_layout.atmosphere
	if is_instance_valid(header) and header.material is ShaderMaterial:
		for key in ["colors", "intro_color", "reveal", "first_center", "spacing"]:
			material.set_shader_parameter(key, header.material.get_shader_parameter(key))
		material.set_shader_parameter("header_offset", (bounds.position - header.global_position) / header.size)
		material.set_shader_parameter("header_scale", bounds.size / header.size)
	else:
		material.set_shader_parameter("header_offset", Vector2(0, 2))
