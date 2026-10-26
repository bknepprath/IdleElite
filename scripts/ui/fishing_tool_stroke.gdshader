shader_type canvas_item;
render_mode unshaded;

uniform float stroke_pixels : hint_range(0.0, 5.0) = 3.0;
uniform vec2 draw_size = vec2(136.0);
uniform float brightness : hint_range(0.5, 1.0) = 0.88;

vec4 sample_icon(sampler2D tex, vec2 uv) {
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) return vec4(0.0);
	return texture(tex, uv);
}

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	vec2 step_uv = vec2(stroke_pixels) / draw_size;
	float outline_alpha = source.a;
	float dark_stroke = step(max(source.r, max(source.g, source.b)), 0.20) * source.a;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 direction = vec2(float(x), float(y));
			if (x != 0 || y != 0) direction = normalize(direction);
			vec4 nearby = sample_icon(TEXTURE, UV + direction * step_uv);
			outline_alpha = max(outline_alpha, nearby.a);
			vec4 inner = sample_icon(TEXTURE, UV + direction * step_uv * 0.18);
			float ink = step(max(inner.r, max(inner.g, inner.b)), 0.20) * inner.a;
			dark_stroke = max(dark_stroke, ink);
		}
	}
	vec3 color = mix(source.rgb * brightness, vec3(0.0), smoothstep(0.2, 0.75, dark_stroke));
	color = mix(vec3(0.0), color, source.a);
	COLOR = vec4(color, outline_alpha);
}
