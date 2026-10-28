// REEBOO Stylized VFX - Status Effects: camera-facing icon particles (plus signs, hearts, Zs, skulls...).
// Included by vfx_status_glyph_add.gdshader (glowing) and vfx_status_glyph_mix.gdshader (solid, outlined).
// Color and alpha come from the particle's color ramp. The icon is drawn from a signed distance
// function (vfx_status_common.gdshaderinc), so it stays sharp at any size and needs no texture.

uniform int glyph : hint_enum("Plus", "Arrow Up", "Arrow Down", "Double Chevron", "Hex Plate", "Heart", "Letter Z",
		"Snowflake", "Droplet", "Bubble", "Skull", "Star", "Reticle", "Spike", "Diamond", "Bolt", "Exclamation", "Question") = 0;
uniform float emission_energy : hint_range(0.0, 20.0) = 3.0;
// Glow halo around the icon (additive variant).
uniform float glow_strength : hint_range(0.0, 2.0) = 0.6;
uniform float glow_width : hint_range(0.01, 1.0) = 0.18;
// White-hot center (additive) or light top half (solid variant).
uniform float core_white : hint_range(0.0, 1.0) = 0.5;
// Solid variant: dark outline around the icon.
uniform vec4 outline_color : source_color = vec4(0.05, 0.04, 0.08, 1.0);
uniform float outline_width : hint_range(0.0, 0.4) = 0.12;
// Spins the icon with the particle's angle (off keeps icons upright).
uniform bool use_particle_angle = false;
// Opacity of the icon body; with a low value and some rim the icon reads as an outline (additive variant).
uniform float fill_opacity : hint_range(0.0, 1.0) = 1.0;
uniform float rim : hint_range(0.0, 3.0) = 0.0;
// Up and down bobbing in meters (each particle gets its own phase).
uniform float bob = 0.0;
uniform float bob_speed = 3.0;

#include "vfx_status_common.gdshaderinc"

varying float v_age;
varying float v_seed;

void vertex() {
	v_age = clamp(INSTANCE_CUSTOM.y / max(INSTANCE_CUSTOM.w, 0.0001), 0.0, 1.0);
	v_seed = fract(sin(float(INSTANCE_ID) * 12.9898 + 78.233) * 43758.5453);
	float ang = use_particle_angle ? INSTANCE_CUSTOM.x : 0.0;
	mat4 mat_world = mat4(
			normalize(INV_VIEW_MATRIX[0]),
			normalize(INV_VIEW_MATRIX[1]),
			normalize(INV_VIEW_MATRIX[2]),
			MODEL_MATRIX[3] + vec4(0.0, sin(TIME * bob_speed + v_seed * TAU) * bob, 0.0, 0.0));
	mat_world = mat_world * mat4(
			vec4(cos(ang), -sin(ang), 0.0, 0.0),
			vec4(sin(ang), cos(ang), 0.0, 0.0),
			vec4(0.0, 0.0, 1.0, 0.0),
			vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat_world;
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
			vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
			vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
			vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
			vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 p = (UV * 2.0 - 1.0) * vec2(1.0, -1.0);
	float d = status_glyph(glyph, p);
	float aa = max(fwidth(d), 0.002);
	float fill = 1.0 - smoothstep(-aa, aa, d);
	vec3 base = status_to_linear(COLOR.rgb);
	float w = status_life_weight(v_age);
#ifdef STATUS_GLYPH_SOLID
	float outer = 1.0 - smoothstep(outline_width - aa, outline_width + aa, d);
	float shade = mix(0.8, 1.0 + core_white, clamp(p.y * 0.5 + 0.5, 0.0, 1.0));
	vec3 col = mix(status_to_linear(outline_color.rgb), base * shade, fill);
	ALBEDO = col * emission_energy;
	ALPHA = clamp(max(fill, outer * outline_color.a) * COLOR.a * w, 0.0, 1.0);
#else
	float border = 1.0 - smoothstep(0.72, 1.0, length(p));
	float glow = exp(-max(d, 0.0) / glow_width) * glow_strength * (1.0 - fill) * border;
	float core = smoothstep(0.0, -0.22, d) * core_white;
	float edge = fill * (1.0 - smoothstep(0.0, 0.1, -d)) * rim;
	float body = fill * fill_opacity + edge;
	vec3 col = base * (body + glow) + vec3(core) * fill * fill_opacity;
	ALBEDO = col * emission_energy;
	ALPHA = clamp((body + glow) * COLOR.a * w, 0.0, 1.0);
#endif
}
