shader_type canvas_item;

uniform vec2 object_center;
uniform float object_angle = 0.0;
uniform float object_scale = 1.0;
uniform float shaft_width = 1.0;
uniform vec2 water_center;
uniform vec2 pool_radii = vec2(91.0, 15.0);

varying vec2 tool_point;

void vertex() {
	vec2 cross_axis = vec2(0.70710678);
	vec2 local = VERTEX - vec2(100.0);
	VERTEX -= cross_axis * dot(local, cross_axis) * (1.0 - shaft_width);
	tool_point = VERTEX;
}

void fragment() {
	vec2 local = (tool_point - vec2(100.0)) * object_scale;
	float c = cos(object_angle);
	float s = sin(object_angle);
	vec2 point = object_center + vec2(c * local.x - s * local.y, s * local.x + c * local.y) - water_center;
	// Above the waterline the whole tool remains visible. Below it, equipment
	// is restricted to the inside of the pool, including the curved side rims.
	float distance_to_edge = length(point / pool_radii) - 1.0;
	float edge_width = max(fwidth(distance_to_edge), 0.001);
	float coverage = 1.0 - smoothstep(-edge_width, edge_width, distance_to_edge);
	if (point.y > 0.0) {
		COLOR.a *= coverage;
	}
}
