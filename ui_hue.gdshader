shader_type canvas_item;
uniform float hue_shift : hint_range(0.0, 1.0) = 0.0;

vec3 hue_rotate(vec3 c, float shift) {
	vec3  k   = vec3(0.57735);
	float ang = shift * 6.28318;
	float cs  = cos(ang);
	float sn  = sin(ang);
	return c * cs + cross(k, c) * sn + k * dot(k, c) * (1.0 - cs);
}

void fragment() {
	// texture(TEXTURE, UV) * COLOR captures both image-based and flat-colour draws
	vec4 col = texture(TEXTURE, UV) * COLOR;
	col.rgb = hue_rotate(col.rgb, hue_shift);
	COLOR = col;
}
