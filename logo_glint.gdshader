shader_type canvas_item;

uniform float glint_progress : hint_range(-0.3, 1.3) = -0.3;
uniform float glint_width    : hint_range(0.01, 0.5) = 0.12;
uniform float glint_strength : hint_range(0.0,  2.0) = 0.55;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	// Diagonal coord: 0 at top-left, 1 at bottom-right
	float diag  = (UV.x + UV.y) * 0.5;
	float dist  = abs(diag - glint_progress);
	float glint = smoothstep(glint_width, 0.0, dist) * glint_strength;
	// Only brighten non-transparent pixels
	col.rgb += glint * col.a;
	COLOR = col;
}
