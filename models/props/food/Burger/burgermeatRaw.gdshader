shader_type spatial;

uniform sampler2D albedo_texture : source_color;
uniform vec4 raw_color : source_color = vec4(0.82, 0.38, 0.38, 1.0);

void fragment() {
	vec3 tex = texture(albedo_texture, UV).rgb;

	float brightness = dot(tex, vec3(0.299, 0.587, 0.114));

	ALBEDO = raw_color.rgb * (0.5 + brightness * 0.7);
}
