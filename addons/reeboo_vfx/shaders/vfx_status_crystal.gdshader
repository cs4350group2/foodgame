// REEBOO Stylized VFX - Status Effects: faceted ice crystals (mesh particles).
// Flat facets come from screen-space derivatives, so any cone or cylinder mesh looks cut.
shader_type spatial;
render_mode blend_mix, unshaded, cull_back, depth_draw_opaque, shadows_disabled;

uniform vec4 deep_color : source_color = vec4(0.1, 0.4, 0.8, 1.0);
uniform vec4 edge_color : source_color = vec4(0.82, 0.97, 1.0, 1.0);
uniform float emission_energy : hint_range(0.0, 10.0) = 1.4;
uniform float opacity : hint_range(0.0, 1.0) = 0.85;
uniform float shine_speed = 0.6;

#include "vfx_status_common.gdshaderinc"

varying float v_age;
varying float v_height;

void vertex() {
	v_age = clamp(INSTANCE_CUSTOM.y / max(INSTANCE_CUSTOM.w, 0.0001), 0.0, 1.0);
	v_height = VERTEX.y;
}

void fragment() {
	vec3 n = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
	float fres = pow(1.0 - abs(dot(n, normalize(VIEW))), 1.6);
	float facet = clamp(dot(n, normalize(vec3(0.4, 0.8, 0.45))) * 0.5 + 0.5, 0.0, 1.0);
	float shine = 1.0 - smoothstep(0.0, 0.06, abs(fract(v_height * 1.4 - TIME * shine_speed) - 0.5));
	vec3 col = mix(status_to_linear(deep_color.rgb), status_to_linear(edge_color.rgb), clamp(fres + facet * 0.35, 0.0, 1.0));
	col += status_to_linear(edge_color.rgb) * shine * 0.6;
	ALBEDO = col * emission_energy * COLOR.rgb;
	ALPHA = clamp(mix(0.7, 1.0, fres) * opacity * COLOR.a * status_life_weight(v_age), 0.0, 1.0);
}
