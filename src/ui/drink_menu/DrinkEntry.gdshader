shader_type canvas_item;

uniform vec4 glass_tint : source_color = vec4(0.85, 0.95, 1.0, 1.0);
uniform float reflection_strength : hint_range(0.0, 1.0) = 0.25;
uniform float base_opacity : hint_range(0.0, 1.0) = 0.04;

void fragment() {
	float highlight = texture(TEXTURE, UV).r;

	float opacity = mix(
		base_opacity,
		reflection_strength,
		highlight
	);

	COLOR = vec4(glass_tint.rgb, opacity * glass_tint.a);
}