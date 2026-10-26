shader_type canvas_item;
uniform vec4 water_color : source_color = vec4(0.04, 0.79, 0.89, 1.0);
uniform vec4 highlight_color : source_color = vec4(0.64, 0.96, 0.98, 1.0);

varying vec4 piece_tint;

void vertex() {
	piece_tint = COLOR;
}

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	// Discard the source sheet's soft halo and retain its solid water silhouette.
	float coverage = smoothstep(0.88, 0.96, source.a);
	float highlight = smoothstep(0.35, 0.6, source.r);
	vec3 water = mix(water_color.rgb, highlight_color.rgb, highlight);
	COLOR = vec4(water, coverage) * piece_tint;
}
