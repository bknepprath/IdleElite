shader_type canvas_item;
uniform vec4 water_color : source_color = vec4(0.24, 0.72, 0.85, 1.0);
uniform bool front_half = false;

void fragment() {
	// Canonical authored ellipse and a uniform 3px black rim. The surface is
	// scaled as a whole with the stage; no raster edge or frame fitting.
	vec2 point = (UV - vec2(0.5)) * vec2(188.0, 36.0);
	float distance_to_edge = length(point / vec2(94.0, 18.0)) - 1.0;
	float edge_width = max(fwidth(distance_to_edge), 0.001);
	float coverage = 1.0 - smoothstep(-edge_width, edge_width, distance_to_edge);
	float inner_distance = length(point / vec2(91.0, 15.0)) - 1.0;
	float inner_width = max(fwidth(inner_distance), 0.001);
	float fill = 1.0 - smoothstep(-inner_width, inner_width, inner_distance);
	if (front_half) {
		coverage *= smoothstep(-0.7, 0.7, point.y);
	}
	COLOR = vec4(mix(vec3(0.0), water_color.rgb, fill), mix(1.0, water_color.a, fill) * coverage);
}
