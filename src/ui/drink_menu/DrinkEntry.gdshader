shader_type canvas_item;

uniform vec4 glass_tint : source_color = vec4(0.85, 0.95, 1.0, 1.0);
uniform float reflection_strength : hint_range(0.0, 1.0) = 0.25;
uniform float base_opacity : hint_range(0.0, 1.0) = 0.04;
uniform float edge_shadow_strength : hint_range(0.0, 1.0) = 0.35;

void fragment() {
	// Reflections cross the entire window, including the model beneath it.
	float diagonal = UV.x + UV.y * 0.48;
	float broad_streak = 1.0 - smoothstep(0.04, 0.13, abs(diagonal - 0.65));
	float narrow_streak = 1.0 - smoothstep(0.008, 0.025, abs(diagonal - 0.84));
	float highlight = max(texture(TEXTURE, UV).r * 0.35,
		max(broad_streak * 0.8, narrow_streak));
	float opacity = mix(base_opacity, reflection_strength, highlight) * glass_tint.a;

	// A dark inset edge makes the glass read as a recessed display window.
	vec2 edge_distance = min(UV, vec2(1.0) - UV);
	float inset = 1.0 - smoothstep(0.0, 0.075, min(edge_distance.x, edge_distance.y));
	float shadow = inset * edge_shadow_strength;
	float combined_alpha = shadow + opacity * (1.0 - shadow);
	vec3 combined_color = (vec3(0.015, 0.025, 0.035) * shadow
		+ glass_tint.rgb * opacity * (1.0 - shadow)) / max(combined_alpha, 0.0001);
	COLOR = vec4(combined_color, combined_alpha);
}
