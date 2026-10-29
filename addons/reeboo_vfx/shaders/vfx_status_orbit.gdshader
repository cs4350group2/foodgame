// REEBOO Stylized VFX - Status Effects: icons circling a character (hex plates, stars, diamonds...).
// The mesh is a list of quads whose vertices store data instead of positions:
//   VERTEX = (phase 0..1, height, radius), UV = quad corner, UV2 = (size, speed multiplier).
// It is drawn by a particle layer (two particles in "Loop crossfade") so it fades out on stop().
shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled, skip_vertex_transform;

uniform int glyph : hint_enum("Plus", "Arrow Up", "Arrow Down", "Double Chevron", "Hex Plate", "Heart", "Letter Z",
		"Snowflake", "Droplet", "Bubble", "Skull", "Star", "Reticle", "Spike", "Diamond", "Bolt", "Exclamation", "Question") = 4;
uniform vec4 color : source_color = vec4(0.5, 0.75, 1.0, 1.0);
uniform float emission_energy : hint_range(0.0, 20.0) = 3.0;
// Turns per second.
uniform float speed = 0.25;
uniform float bob = 0.05;
uniform float bob_speed = 1.2;
// Tilt of the orbit plane, in degrees around X.
uniform float tilt = 0.0;
// On: icons face the camera. Off: flat plates facing out from the center, like armor.
uniform bool face_camera = true;
uniform float glow_strength : hint_range(0.0, 2.0) = 0.6;
uniform float glow_width : hint_range(0.01, 1.0) = 0.18;
uniform float core_white : hint_range(0.0, 1.0) = 0.4;
// Icons on the far side of the orbit are drawn dimmer (0 = no depth cue).
uniform float back_dim : hint_range(0.0, 1.0) = 0.5;
// Opacity of the icon body; a low value plus rim gives see-through plates with bright edges.
uniform float fill_opacity : hint_range(0.0, 1.0) = 1.0;
uniform float rim : hint_range(0.0, 3.0) = 0.0;

#include "vfx_status_common.gdshaderinc"

varying float v_age;
varying float v_back;

void vertex() {
	v_age = clamp(INSTANCE_CUSTOM.y / max(INSTANCE_CUSTOM.w, 0.0001), 0.0, 1.0);
	float phase = VERTEX.x;
	float h = VERTEX.y;
	float rad = VERTEX.z;
	float size = UV2.x;
	float a = phase * TAU + TIME * speed * TAU * UV2.y;
	vec3 c = vec3(cos(a) * rad, sin(TIME * bob_speed + phase * TAU) * bob, sin(a) * rad);
	float tr = radians(tilt);
	c = vec3(c.x, c.y * cos(tr) - c.z * sin(tr), c.y * sin(tr) + c.z * cos(tr));
	c.y += h;
	vec2 corner = (UV - 0.5) * vec2(1.0, -1.0) * size;
	vec3 view_c = (MODELVIEW_MATRIX * vec4(c, 1.0)).xyz;
	vec3 center_v = (MODELVIEW_MATRIX * vec4(0.0, c.y, 0.0, 1.0)).xyz;
	// 1 = behind the center (farther from the camera), 0 = in front.
	v_back = clamp((center_v.z - view_c.z) / max(rad, 0.001) * 0.5 + 0.5, 0.0, 1.0);
	if (face_camera) {
		VERTEX = view_c + vec3(corner, 0.0);
		NORMAL = vec3(0.0, 0.0, 1.0);
	} else {
		vec3 tang = vec3(-sin(a), 0.0, cos(a));
		vec3 pos = c + tang * corner.x + vec3(0.0, corner.y, 0.0);
		VERTEX = (MODELVIEW_MATRIX * vec4(pos, 1.0)).xyz;
		NORMAL = normalize((MODELVIEW_MATRIX * vec4(cos(a), 0.0, sin(a), 0.0)).xyz);
	}
}

void fragment() {
	vec2 p = (UV * 2.0 - 1.0) * vec2(1.0, -1.0);
	if (!FRONT_FACING && !face_camera) {
		p.x = -p.x;
	}
	float d = status_glyph(glyph, p);
	float aa = max(fwidth(d), 0.002);
	float fill = 1.0 - smoothstep(-aa, aa, d);
	float border = 1.0 - smoothstep(0.72, 1.0, length(p));
	float glow = exp(-max(d, 0.0) / glow_width) * glow_strength * (1.0 - fill) * border;
	float core = smoothstep(0.0, -0.25, d) * core_white;
	// Inner bevel line so hex plates read as plates.
	float bevel = glyph == 4 ? (1.0 - smoothstep(0.0, aa * 2.0, abs(d + 0.18))) * 0.7 : 0.0;
	vec3 base = status_to_linear(color.rgb);
	float depth = mix(1.0, 1.0 - back_dim, v_back);
	float edge = fill * (1.0 - smoothstep(0.0, 0.1, -d)) * rim;
	float body = fill * fill_opacity + edge;
	vec3 col = base * (body * 0.8 + glow) + (vec3(core) * fill_opacity + vec3(bevel)) * fill * base * 1.5 + vec3(core * 0.3) * fill * fill_opacity;
	ALBEDO = col * emission_energy * depth;
	ALPHA = clamp((body + glow + bevel * fill) * color.a * COLOR.a * status_life_weight(v_age), 0.0, 1.0);
}
