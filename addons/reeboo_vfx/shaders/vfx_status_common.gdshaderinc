// REEBOO Stylized VFX - Status Effects: shared helpers.
// Life progress comes from the particle system: INSTANCE_CUSTOM.y / INSTANCE_CUSTOM.w runs 0 -> 1.
// life_mode 0 (one-shot): fades in over fade_in and out over fade_out (fractions of the particle's life).
// life_mode 1 (loop): weight sin^2(pi * age). Two particles half a life apart add up to a constant 1,
// so an always-on layer never blinks and still fades out when the effect stops emitting.

uniform int life_mode : hint_enum("One-shot", "Loop crossfade") = 0;
uniform float fade_in : hint_range(0.0, 1.0) = 0.1;
uniform float fade_out : hint_range(0.0, 1.0) = 0.4;

float status_life_weight(float age) {
	if (life_mode == 1) {
		float s = sin(age * PI);
		return s * s;
	}
	float a = fade_in > 0.0 ? smoothstep(0.0, fade_in, age) : 1.0;
	float b = fade_out > 0.0 ? 1.0 - smoothstep(1.0 - fade_out, 1.0, age) : 1.0;
	return a * b;
}

vec3 status_to_linear(vec3 c) {
	return mix(pow((c + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)), c * (1.0 / 12.92), lessThan(c, vec3(0.04045)));
}

// ---- Glyph signed distances. p runs -1..1 with +y up. Negative = inside.
float sd_box(vec2 p, vec2 b) {
	vec2 d = abs(p) - b;
	return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float sd_segment(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

float sd_triangle_up(vec2 p, vec2 q) {
	// Isosceles triangle, apex at (0, q.y) and base at y = 0 with half width q.x (Inigo Quilez).
	p.y = q.y - p.y;
	p.x = abs(p.x);
	vec2 a = p - q * clamp(dot(p, q) / dot(q, q), 0.0, 1.0);
	vec2 b = p - q * vec2(clamp(p.x / q.x, 0.0, 1.0), 1.0);
	float s = -sign(q.y);
	vec2 d = min(vec2(dot(a, a), s * (p.x * q.y - p.y * q.x)), vec2(dot(b, b), s * (p.y - q.y)));
	return -sqrt(d.x) * sign(d.y);
}

float sd_hexagon(vec2 p, float r) {
	const vec3 k = vec3(-0.866025404, 0.5, 0.577350269);
	p = abs(p);
	p -= 2.0 * min(dot(k.xy, p), 0.0) * k.xy;
	p -= vec2(clamp(p.x, -k.z * r, k.z * r), r);
	return length(p) * sign(p.y);
}

float sd_heart(vec2 p) {
	// Inigo Quilez heart: tip at (0, 0), lobes up to y ~ 1.
	p.x = abs(p.x);
	if (p.y + p.x > 1.0) {
		return length(p - vec2(0.25, 0.75)) - sqrt(2.0) / 4.0;
	}
	vec2 a = p - vec2(0.0, 1.0);
	vec2 b = p - 0.5 * max(p.x + p.y, 0.0);
	return sqrt(min(dot(a, a), dot(b, b))) * sign(p.x - p.y);
}

float sd_star5(vec2 p, float r, float rf) {
	const vec2 k1 = vec2(0.809016994375, -0.587785252292);
	const vec2 k2 = vec2(-k1.x, k1.y);
	p.x = abs(p.x);
	p -= 2.0 * max(dot(k1, p), 0.0) * k1;
	p -= 2.0 * max(dot(k2, p), 0.0) * k2;
	p.x = abs(p.x);
	p.y -= r;
	vec2 ba = rf * vec2(-k1.y, k1.x) - vec2(0.0, 1.0);
	float h = clamp(dot(p, ba) / dot(ba, ba), 0.0, r);
	return length(p - ba * h) * sign(p.y * ba.x - p.x * ba.y);
}

float sd_uneven_capsule(vec2 p, float r1, float r2, float h) {
	p.x = abs(p.x);
	float b = (r1 - r2) / h;
	float a = sqrt(1.0 - b * b);
	float k = dot(p, vec2(-b, a));
	if (k < 0.0) return length(p) - r1;
	if (k > a * h) return length(p - vec2(0.0, h)) - r2;
	return dot(p, vec2(a, b)) - r1;
}

// 0 Plus, 1 Arrow Up, 2 Arrow Down, 3 Double Chevron, 4 Hex Plate, 5 Heart, 6 Letter Z, 7 Snowflake,
// 8 Droplet, 9 Bubble, 10 Skull, 11 Star, 12 Reticle, 13 Spike, 14 Diamond, 15 Bolt, 16 Exclamation, 17 Question
float status_glyph(int g, vec2 p) {
	if (g == 0) {
		return min(sd_box(p, vec2(0.24, 0.78)), sd_box(p, vec2(0.78, 0.24))) - 0.08;
	} else if (g == 1 || g == 2) {
		if (g == 2) p.y = -p.y;
		float head = sd_triangle_up(p - vec2(0.0, 0.0), vec2(0.78, 0.86)) - 0.04;
		float shaft = sd_box(p - vec2(0.0, -0.42), vec2(0.24, 0.46)) - 0.04;
		return min(head, shaft);
	} else if (g == 3) {
		float a = min(sd_segment(p, vec2(-0.62, -0.02), vec2(0.0, 0.5)), sd_segment(p, vec2(0.0, 0.5), vec2(0.62, -0.02)));
		vec2 q = p + vec2(0.0, 0.55);
		float b = min(sd_segment(q, vec2(-0.62, -0.02), vec2(0.0, 0.5)), sd_segment(q, vec2(0.0, 0.5), vec2(0.62, -0.02)));
		return min(a, b) - 0.15;
	} else if (g == 4) {
		return sd_hexagon(p.yx, 0.78) - 0.06;
	} else if (g == 5) {
		return sd_heart((p + vec2(0.0, 0.8)) * 0.6) / 0.6;
	} else if (g == 6) {
		float d = sd_segment(p, vec2(-0.55, 0.6), vec2(0.55, 0.6));
		d = min(d, sd_segment(p, vec2(0.55, 0.6), vec2(-0.55, -0.6)));
		d = min(d, sd_segment(p, vec2(-0.55, -0.6), vec2(0.55, -0.6)));
		return d - 0.15;
	} else if (g == 7) {
		float r = length(p);
		float a = atan(p.y, p.x) + PI / 2.0;
		float sector = mod(a + PI / 6.0, PI / 3.0) - PI / 6.0;
		vec2 q = r * vec2(cos(sector), abs(sin(sector)));
		float d = sd_segment(q, vec2(0.0), vec2(0.86, 0.0));
		d = min(d, sd_segment(q, vec2(0.42, 0.0), vec2(0.64, 0.22)));
		d = min(d, sd_segment(q, vec2(0.62, 0.0), vec2(0.76, 0.14)));
		return min(d - 0.075, r - 0.16);
	} else if (g == 8) {
		return sd_uneven_capsule(p - vec2(0.0, -0.36), 0.5, 0.04, 1.2);
	} else if (g == 9) {
		float ring = abs(length(p) - 0.78) - 0.08;
		float shine = length(p - vec2(-0.33, 0.33)) - 0.16;
		return min(ring, shine);
	} else if (g == 10) {
		float head = length(p - vec2(0.0, 0.16)) - 0.7;
		float jaw = sd_box(p - vec2(0.0, -0.52), vec2(0.36, 0.26)) - 0.08;
		float d = min(head, jaw);
		vec2 e = vec2(abs(p.x), p.y) - vec2(0.28, 0.1);
		float eyes = length(e) - 0.2;
		float nose = sd_triangle_up(p - vec2(0.0, -0.3), vec2(0.09, 0.16));
		vec2 t = vec2(mod(p.x + 0.12, 0.24) - 0.12, p.y + 0.66);
		float teeth = abs(p.x) < 0.3 ? sd_box(t, vec2(0.025, 0.12)) : 1.0;
		return max(max(max(d, -eyes), -nose), -teeth);
	} else if (g == 11) {
		return sd_star5(p * vec2(1.0, 1.0) + vec2(0.0, 0.06), 0.9, 0.45) - 0.04;
	} else if (g == 12) {
		float ring = abs(length(p) - 0.62) - 0.07;
		float ticks = min(sd_box(p, vec2(0.06, 0.95)), sd_box(p, vec2(0.95, 0.06)));
		ticks = max(ticks, -(length(p) - 0.36));
		float dot_c = length(p) - 0.1;
		return min(min(ring, ticks), dot_c);
	} else if (g == 13) {
		return sd_triangle_up(p + vec2(0.0, 0.9), vec2(0.38, 1.8)) - 0.02;
	} else if (g == 14) {
		vec2 q = abs(p);
		return (q.x * 1.0 + q.y * 0.62 - 0.62) * 0.85;
	} else if (g == 15) {
		float d = sd_segment(p, vec2(0.22, 0.92), vec2(-0.32, 0.02));
		d = min(d, sd_segment(p, vec2(-0.32, 0.02), vec2(0.3, 0.06)));
		d = min(d, sd_segment(p, vec2(0.3, 0.06), vec2(-0.2, -0.9)));
		return d - 0.12;
	} else if (g == 16) {
		float bar = sd_uneven_capsule(p - vec2(0.0, -0.22), 0.1, 0.19, 0.98);
		return min(bar, length(p - vec2(0.0, -0.7)) - 0.16);
	} else if (g == 17) {
		vec2 c = vec2(0.0, 0.36);
		float r = 0.36;
		vec2 q = p - c;
		float ang = atan(q.y, q.x);
		vec2 e1 = c + vec2(-r, 0.0);
		vec2 e2 = c + r * vec2(cos(-1.2), sin(-1.2));
		float arc = ang >= -1.2 ? abs(length(q) - r) : min(length(p - e1), length(p - e2));
		float stem = sd_segment(p, e2, vec2(0.0, -0.3));
		float d = min(arc, stem) - 0.13;
		return min(d, length(p - vec2(0.0, -0.7)) - 0.15);
	}
	return length(p) - 0.8;
}
