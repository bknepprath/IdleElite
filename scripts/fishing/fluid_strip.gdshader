shader_type canvas_item;
render_mode unshaded;

uniform vec4 fluid_color : source_color = vec4(0.239, 0.722, 0.851, 1.0);
uniform vec4 fluid_deep : source_color = vec4(0.165, 0.561, 0.722, 1.0);
uniform float reveal_success = 0.0;
uniform float foam_scroll = 0.0;
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
	vec3 col = fluid_deep.rgb;
	if (mask > 0.001) {
		vec2 uv = UV;
		float wave = 0.06 * sin((uv.x * 7.0 + foam_scroll) * 6.28318)
			+ 0.03 * sin((uv.x * 11.0 - foam_scroll * 0.6) * 6.28318);
		float surface_y = 0.36 + wave;
		float depth_mix = smoothstep(surface_y - 0.12, surface_y + 0.04, uv.y);
		col = mix(fluid_color.rgb, fluid_deep.rgb, clamp(depth_mix, 0.0, 1.0));
		float crest = smoothstep(surface_y - 0.02, surface_y + 0.03, uv.y)
			* (1.0 - smoothstep(surface_y + 0.03, surface_y + 0.07, uv.y));
		crest *= 0.18 + 0.1 * sin((uv.x * 20.0 + foam_scroll * 1.5) * 6.28318);
		col = mix(col, vec3(0.92, 0.98, 1.0), crest * 0.55);
	}
	COLOR = vec4(col, mask);
}
