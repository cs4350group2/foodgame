// REEBOO Stylized VFX - Status Effects: soft aura column around a character (open CylinderMesh drawn by a particle).
// Noise streaks scroll upward, the silhouette edges glow and the top fades out.
shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 color : source_color = vec4(0.4, 1.0, 0.6, 1.0);
uniform float emission_energy : hint_range(0.0, 20.0) = 1.5;
uniform sampler2D noise_texture : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec2 noise_scale = vec2(3.0, 0.6);
uniform float scroll_speed = 0.6;
uniform float twist = 0.0;
// 0 = soft fog, 1 = sharp streaks.
uniform float streak_sharpness : hint_range(0.0, 1.0) = 0.5;
uniform float edge_power : hint_range(0.0, 8.0) = 1.5;
uniform float top_fade : hint_range(0.0, 4.0) = 1.4;
uniform float base_glow : hint_range(0.0, 1.0) = 0.15;

#include "vfx_status_common.gdshaderinc"

varying float v_age;

void vertex() {
	v_age = clamp(INSTANCE_CUSTOM.y / max(INSTANCE_CUSTOM.w, 0.0001), 0.0, 1.0);
}

void fragment() {
	float h = 1.0 - UV.y;
	vec2 nuv = vec2(UV.x * noise_scale.x + h * twist, h * noise_scale.y - TIME * scroll_speed);
	float n = texture(noise_texture, nuv).r;
	float n2 = texture(noise_texture, nuv * vec2(1.7, 1.3) + vec2(0.37, -TIME * scroll_speed * 0.6)).r;
	float s = n * 0.6 + n2 * 0.4;
	float lo = mix(0.25, 0.55, streak_sharpness);
	float streaks = smoothstep(lo, lo + mix(0.5, 0.12, streak_sharpness), s);
	float fres = 1.0 - abs(dot(normalize(NORMAL), normalize(VIEW)));
	// Brighter toward the sides but fading right at the silhouette, so the column has no hard outline.
	float edge = edge_power > 0.001 ? (0.2 + pow(fres, edge_power) * 1.4) * smoothstep(0.0, 0.45, 1.0 - fres) : 1.0;
	float vert = pow(clamp(1.0 - h, 0.0, 1.0), top_fade) * smoothstep(0.0, 0.06, h);
	float m = (streaks + base_glow) * edge * vert;
	ALBEDO = status_to_linear(color.rgb) * emission_energy;
	ALPHA = clamp(m * color.a * COLOR.a * status_life_weight(v_age), 0.0, 1.0);
}
