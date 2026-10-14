shader_type canvas_item;

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

varying vec4 vertex_tint;

void vertex() { vertex_tint = COLOR; }

void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	// Preserve the drawn black outline while replacing the berry colour.
	float ink_mask = smoothstep(0.12, 0.35, max(pixel.r, max(pixel.g, pixel.b)));
	pixel.rgb = mix(pixel.rgb, vec3(0.20, 0.90, 0.36), flash_amount * ink_mask);
	COLOR = pixel * vertex_tint;
}
