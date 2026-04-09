shader_type canvas_item;

uniform vec3  color_bg   : source_color = vec3(0.0, 0.20, 0.0);
uniform vec3  color_blob : source_color = vec3(0.03, 0.05, 0.03);
uniform float speed      : hint_range(0.002, 0.30) = 0.16;
uniform float blob_r     : hint_range(0.02, 0.40)  = 0.17;
uniform float threshold  : hint_range(0.8, 12.0)   = 5.5;
uniform float hue_shift  = 0.0;

vec3 hue_rotate(vec3 col, float shift) {
	vec3  k    = vec3(0.57735);
	float ang  = shift * 6.28318;
	float c    = cos(ang);
	float s    = sin(ang);
	return col * c + cross(k, col) * s + k * dot(k, col) * (1.0 - c);
}

float blob(vec2 uv, vec2 center) {
	return blob_r / (length(uv - center) + 0.04);
}

void fragment() {
	vec2  uv = UV;
	float t  = TIME * speed;

	// Two group centres drift slowly across the full screen
	vec2 g1 = vec2(0.50 + sin(t * 0.43 + 0.00) * 0.42,
	               0.50 + cos(t * 0.37 + 1.00) * 0.42);
	vec2 g2 = vec2(0.50 + cos(t * 0.51 + 2.10) * 0.40,
	               0.50 + sin(t * 0.41 + 3.70) * 0.38);

	// Each blob has:
	//   - a weight that oscillates slowly (0.10 → 1.0) so blobs appear/disappear
	//   - an offset from the group centre that changes slowly (shape-shifting)
	float field = 0.0;

	// ── Group 1 — irregular offsets: wide x/narrow y, narrow x/wide y, etc. ──
	field += (0.55 + 0.45*sin(t*0.13+0.00)) * blob(uv, g1+vec2(sin(t*0.45+0.0)*0.28, cos(t*0.38+0.5)*0.05));
	field += (0.55 + 0.45*sin(t*0.17+0.80)) * blob(uv, g1+vec2(cos(t*0.52+1.2)*0.04, sin(t*0.41+1.8)*0.27));
	field += (0.55 + 0.45*sin(t*0.11+1.60)) * blob(uv, g1+vec2(sin(t*0.33+2.4)*0.22, cos(t*0.57+0.3)*0.03));
	field += (0.55 + 0.45*sin(t*0.19+2.40)) * blob(uv, g1+vec2(cos(t*0.61+3.1)*0.03, sin(t*0.29+2.7)*0.25));
	field += (0.55 + 0.45*sin(t*0.14+3.20)) * blob(uv, g1+vec2(sin(t*0.47+1.5)*0.18, cos(t*0.43+3.5)*0.26));
	field += (0.55 + 0.45*sin(t*0.21+4.00)) * blob(uv, g1+vec2(cos(t*0.35+0.7)*0.02, sin(t*0.55+1.1)*0.30));
	field += (0.55 + 0.45*sin(t*0.12+4.80)) * blob(uv, g1+vec2(sin(t*0.63+2.9)*0.29, cos(t*0.31+0.9)*0.02));
	field += (0.55 + 0.45*sin(t*0.16+5.60)) * blob(uv, g1+vec2(cos(t*0.49+4.1)*0.24, sin(t*0.37+3.3)*0.08));
	field += (0.55 + 0.45*sin(t*0.10+0.40)) * blob(uv, g1+vec2(sin(t*0.27+1.7)*0.06, cos(t*0.59+2.2)*0.22));
	field += (0.55 + 0.45*sin(t*0.18+1.20)) * blob(uv, g1+vec2(cos(t*0.53+3.8)*0.21, sin(t*0.25+0.6)*0.04));
	field += (0.55 + 0.45*sin(t*0.22+2.00)) * blob(uv, g1+vec2(sin(t*0.39+0.2)*0.05, cos(t*0.45+4.4)*0.28));
	field += (0.55 + 0.45*sin(t*0.13+2.80)) * blob(uv, g1+vec2(cos(t*0.67+1.0)*0.26, sin(t*0.50+2.0)*0.07));
	field += (0.55 + 0.45*sin(t*0.15+3.60)) * blob(uv, g1+vec2(sin(t*0.58+3.6)*0.03, cos(t*0.34+1.4)*0.20));
	field += (0.55 + 0.45*sin(t*0.20+4.40)) * blob(uv, g1+vec2(cos(t*0.44+2.6)*0.19, sin(t*0.62+0.4)*0.29));
	field += (0.55 + 0.45*sin(t*0.09+5.20)) * blob(uv, g1+vec2(sin(t*0.30+4.8)*0.27, cos(t*0.48+3.0)*0.06));

	// ── Group 2 — same strategy, different asymmetry per blob ─────────────────
	field += (0.55 + 0.45*sin(t*0.14+1.10)) * blob(uv, g2+vec2(cos(t*0.46+0.3)*0.04, sin(t*0.39+0.8)*0.26));
	field += (0.55 + 0.45*sin(t*0.18+1.90)) * blob(uv, g2+vec2(sin(t*0.54+1.5)*0.25, cos(t*0.42+1.3)*0.03));
	field += (0.55 + 0.45*sin(t*0.12+2.70)) * blob(uv, g2+vec2(cos(t*0.34+2.7)*0.07, sin(t*0.58+2.6)*0.29));
	field += (0.55 + 0.45*sin(t*0.20+3.50)) * blob(uv, g2+vec2(sin(t*0.62+3.2)*0.30, cos(t*0.30+3.1)*0.05));
	field += (0.55 + 0.45*sin(t*0.15+4.30)) * blob(uv, g2+vec2(cos(t*0.48+1.8)*0.22, sin(t*0.44+0.2)*0.02));
	field += (0.55 + 0.45*sin(t*0.22+5.10)) * blob(uv, g2+vec2(sin(t*0.36+4.0)*0.03, cos(t*0.56+1.6)*0.24));
	field += (0.55 + 0.45*sin(t*0.11+5.90)) * blob(uv, g2+vec2(cos(t*0.64+2.3)*0.28, sin(t*0.32+4.5)*0.06));
	field += (0.55 + 0.45*sin(t*0.17+0.70)) * blob(uv, g2+vec2(sin(t*0.50+0.6)*0.05, cos(t*0.38+3.8)*0.21));
	field += (0.55 + 0.45*sin(t*0.10+1.50)) * blob(uv, g2+vec2(cos(t*0.28+1.1)*0.20, sin(t*0.60+2.4)*0.28));
	field += (0.55 + 0.45*sin(t*0.19+2.30)) * blob(uv, g2+vec2(sin(t*0.40+3.4)*0.29, cos(t*0.46+0.7)*0.04));
	field += (0.55 + 0.45*sin(t*0.23+3.10)) * blob(uv, g2+vec2(cos(t*0.55+0.9)*0.06, sin(t*0.26+1.9)*0.23));
	field += (0.55 + 0.45*sin(t*0.13+3.90)) * blob(uv, g2+vec2(sin(t*0.68+2.1)*0.27, cos(t*0.49+4.2)*0.03));
	field += (0.55 + 0.45*sin(t*0.16+4.70)) * blob(uv, g2+vec2(cos(t*0.45+3.5)*0.02, sin(t*0.63+0.1)*0.26));
	field += (0.55 + 0.45*sin(t*0.21+5.50)) * blob(uv, g2+vec2(sin(t*0.59+1.3)*0.24, cos(t*0.35+2.9)*0.07));
	field += (0.55 + 0.45*sin(t*0.08+0.30)) * blob(uv, g2+vec2(cos(t*0.31+4.7)*0.08, sin(t*0.53+3.6)*0.30));

	float t_val  = smoothstep(threshold - 2.50, threshold + 2.50, field);
	vec3  bg     = hue_rotate(color_bg,   hue_shift);
	vec3  blob   = hue_rotate(color_blob, hue_shift);
	COLOR = vec4(mix(bg, blob, t_val), 1.0);
}
