shader_type canvas_item;

uniform vec4 ice_tint : source_color = vec4(0.75, 0.9, 1.0, 0.85);
uniform float shine_strength : hint_range(0.0, 1.0) = 0.35;
uniform float time_scale = 0.4;

void fragment() {
	vec3 base = COLOR.rgb;
	float wave = sin((UV.x + UV.y + TIME * time_scale) * 12.0) * 0.5 + 0.5;
	float gloss = smoothstep(0.55, 0.95, wave) * shine_strength;
	vec3 tinted = mix(base, ice_tint.rgb, 0.45);
	tinted += vec3(gloss);
	COLOR = vec4(tinted, COLOR.a * ice_tint.a);
}
