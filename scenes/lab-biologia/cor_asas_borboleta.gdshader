shader_type canvas_item;
render_mode unshaded;

uniform vec4 cor_asas : source_color = vec4(0.0);

void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	if (cor_asas.a > 0.0 && pixel.r > pixel.g && pixel.g > pixel.b) {
		float tom = smoothstep(0.34, 0.86, pixel.g);
		vec3 cor_escura = cor_asas.rgb * 0.5;
		vec3 cor_clara = mix(cor_asas.rgb, vec3(1.0), 0.58);
		pixel.rgb = mix(cor_escura, cor_clara, tom);
	}
	COLOR = pixel;
}
