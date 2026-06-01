shader_type canvas_item;
render_mode unshaded;

uniform vec4 fill_color : source_color = vec4(0.165, 0.561, 0.722, 1.0);
uniform vec2 strip_size = vec2(1.0, 1.0);
uniform float corner_radius = 66.0;
uniform float edge_inset = 6.0;
uniform float bottom_inset = 0.0;

float activity_bottom_strip_mask(vec2 p) {
	float left = edge_inset;
	float right = strip_size.x - edge_inset;
	float bottom = strip_size.y - bottom_inset;
	if (p.x < left || p.x > right || p.y < 0.0 || p.y > bottom) {
		return 0.0;
	}
	float radius = min(corner_radius, (right - left) * 0.5);
	float curve_top = bottom - radius;
	if (p.y <= curve_top) {
		return 1.0;
	}
	float dy = p.y - curve_top;
	float chord_sq = max(0.0, radius * radius - dy * dy);
	float chord = sqrt(chord_sq);
	float corner_left = left + radius - chord;
	float corner_right = right - radius + chord;
	if (p.x < corner_left || p.x > corner_right) {
		return 0.0;
	}
	return 1.0;
}

void fragment() {
	vec2 p = UV * strip_size;
	float mask = activity_bottom_strip_mask(p);
	COLOR = vec4(fill_color.rgb, fill_color.a * mask);
}
