// REEBOO Stylized VFX - Status Effects: flat circle under a character (PlaneMesh drawn by a particle layer).
// Styles: pulse rings, rune circle, reticle, dashed speed ring, soft glow, hex ring, splat puddle, halo ring.
// Looping effects use two particles in "Loop crossfade" so the circle never blinks and fades out on stop().
shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform int style : hint_enum("Pulse Rings", "Rune Circle", "Reticle", "Dashed Ring", "Soft Glow", "Hex Ring", "Splat", "Halo Ring") = 0;
uniform vec4 color : source_color = vec4(0.4, 1.0, 0.6, 1.0);
uniform vec4 inner_color : source_color = vec4(1.0);
uniform float emission_energy : hint_range(0.0, 20.0) = 3.0;
uniform float thickness : hint_range(0.005, 0.3) = 0.04;
uniform float rotate_speed = 0.4;
uniform float pulse_speed = 0.8;
uniform int sides : hint_range(3, 12) = 6;
uniform float inner_glow : hint_range(0.0, 2.0) = 0.25;
// One-shot only: radius grows from this fraction to full size during the first third of the life.
uniform float start_scale : hint_range(0.0, 1.0) = 1.0;
uniform sampler2D noise_texture : hint_default_white, filter_linear_mipmap, repeat_enable;

#include "vfx_status_common.gdshaderinc"

varying float v_age;
varying float v_seed;

void vertex() {
	v_age = clamp(INSTANCE_CUSTOM.y / max(INSTANCE_CUSTOM.w, 0.0001), 0.0, 1.0);
	v_seed = fract(sin(float(INSTANCE_ID) * 12.9898 + 78.233) * 43758.5453);
}

float band(float x, float center, float width) {
	return 1.0 - smoothstep(0.0, width, abs(x - center));
}

vec2 rot2(vec2 p, float a) {
	return vec2(cos(a) * p.x - sin(a) * p.y, sin(a) * p.x + cos(a) * p.y);
}

float polygon_radius(vec2 q, float n) {
	float pa = atan(q.y, q.x);
	return cos(PI / n) / cos(mod(pa + PI / n, 2.0 * PI / n) - PI / n);
}

void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float grow = life_mode == 1 ? 1.0 : mix(start_scale, 1.0, 1.0 - pow(1.0 - clamp(v_age * 3.0, 0.0, 1.0), 3.0));
	q /= max(grow, 0.001);
	float r = length(q);
	float a = atan(q.y, q.x);
	float t = TIME;
	float m = 0.0;
	float inner = 0.0;
	if (style == 0) {
		for (int i = 0; i < 3; i++) {
			float ph = fract(t * pulse_speed + float(i) / 3.0);
			m += band(r, ph * 0.92, thickness) * (1.0 - ph) * smoothstep(0.0, 0.15, ph);
		}
		m += band(r, 0.94, thickness * 0.6) * 0.6;
		inner = (1.0 - smoothstep(0.0, 0.9, r)) * inner_glow;
	} else if (style == 1) {
		float ra = a + t * rotate_speed;
		m = band(r, 0.93, thickness) + band(r, 0.8, thickness * 0.6);
		float ticks = step(0.5, fract(ra * 24.0 / TAU)) * step(0.83, r) * step(r, 0.9);
		m += ticks * 0.7;
		// Inner star: two polygons turning the other way.
		float n = float(sides);
		float p1 = polygon_radius(rot2(q, -t * rotate_speed * 1.5), n);
		float p2 = polygon_radius(rot2(q, -t * rotate_speed * 1.5 + PI / n), n);
		m += band(r, 0.66 * p1, thickness * 0.7) * 0.9;
		m += band(r, 0.66 * p2, thickness * 0.7) * 0.9;
		inner = (1.0 - smoothstep(0.0, 0.8, r)) * inner_glow;
	} else if (style == 2) {
		float ra = a + t * rotate_speed;
		float brackets = band(r, 0.86, thickness) * step(0.62, abs(cos(ra * 2.0)));
		m = brackets + band(r, 0.6, thickness * 0.5) * 0.7;
		vec2 rq = rot2(q, t * rotate_speed);
		float cross_l = min(abs(rq.x), abs(rq.y));
		m += (1.0 - smoothstep(0.0, thickness * 0.6, cross_l)) * step(0.32, r) * step(r, 0.52);
		float pulse = 0.75 + 0.25 * sin(t * pulse_speed * TAU);
		m *= pulse;
		inner = (1.0 - smoothstep(0.0, 0.7, r)) * inner_glow * pulse;
	} else if (style == 3) {
		float n = float(sides);
		float f1 = fract((a - t * rotate_speed) * n / TAU);
		float dash = smoothstep(0.3, 0.45, f1) * (1.0 - smoothstep(0.85, 1.0, f1));
		m = band(r, 0.88, thickness) * dash;
		float f2 = fract((-a - t * rotate_speed * 0.6) * n * 0.5 / TAU);
		m += band(r, 0.68, thickness * 0.7) * smoothstep(0.3, 0.5, f2) * 0.7;
		inner = (1.0 - smoothstep(0.0, 0.85, r)) * inner_glow;
	} else if (style == 4) {
		float n = texture(noise_texture, q * 0.35 + vec2(t * 0.02, v_seed)).r;
		m = (1.0 - smoothstep(0.1, 1.0, r + (n - 0.5) * 0.35)) * (0.8 + 0.2 * sin(t * pulse_speed * TAU));
	} else if (style == 5) {
		float h1 = sd_hexagon(rot2(q, t * rotate_speed), 0.8);
		float h2 = sd_hexagon(rot2(q, -t * rotate_speed), 0.6);
		m = (1.0 - smoothstep(0.0, thickness, abs(h1))) + (1.0 - smoothstep(0.0, thickness * 0.7, abs(h2))) * 0.6;
		inner = (1.0 - smoothstep(0.0, 0.8, r)) * inner_glow;
	} else if (style == 6) {
		float n = texture(noise_texture, q * 0.45 + vec2(v_seed * 3.1, v_seed * 1.7)).r;
		m = 1.0 - smoothstep(0.55, 0.65, r + (n - 0.5) * 0.55);
	} else if (style == 7) {
		float sweep = pow(max(cos(a - t * rotate_speed * TAU), 0.0), 12.0);
		m = band(r, 0.8, thickness) * (1.0 + sweep * 1.5) + exp(-abs(r - 0.8) * 10.0) * 0.3 * step(r, 0.98);
		inner = (1.0 - smoothstep(0.0, 0.8, r)) * inner_glow;
	}
	m *= step(r, 1.0);
	inner *= step(r, 1.0);
	vec3 col = status_to_linear(color.rgb) * (m + inner * status_to_linear(inner_color.rgb));
	ALBEDO = col * emission_energy;
	ALPHA = clamp((m + inner) * color.a * COLOR.a * status_life_weight(v_age), 0.0, 1.0);
}
