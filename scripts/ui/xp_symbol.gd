extends TextureRect

static var symbol_shader: Shader

func _init() -> void:
	if symbol_shader == null:
		symbol_shader = Shader.new()
		symbol_shader.code = """
shader_type canvas_item;
uniform vec2 symbol_size = vec2(80.0);
void fragment() {
	vec4 tint = COLOR;
	vec2 uv = UV - vec2(0.0, 3.0 / symbol_size.y);
	vec4 original = texture(TEXTURE, uv);
	float alpha = original.a;
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			alpha = max(alpha, texture(TEXTURE, uv + vec2(float(x), float(y)) / symbol_size).a);
		}
	}
	COLOR = vec4(original.rgb * original.a / max(alpha, 0.001), alpha) * tint;
}
"""
	var ink := ShaderMaterial.new()
	ink.shader = symbol_shader
	material = ink
	resized.connect(_sync_size)

func _sync_size() -> void:
	if material is ShaderMaterial:
		(material as ShaderMaterial).set_shader_parameter("symbol_size", Vector2(maxf(1.0, size.x), maxf(1.0, size.y)))
