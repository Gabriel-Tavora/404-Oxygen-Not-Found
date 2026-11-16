shader_type canvas_item;
render_mode unshaded;

uniform vec4 cor_luz : source_color = vec4(0.19, 0.64, 1.0, 1.0);
varying float opacidade;

void vertex() {
	opacidade = COLOR.a;
}

void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	float tom = dot(pixel.rgb, vec3(0.299, 0.587, 0.114));
	vec3 cor = cor_luz.rgb;

	if (pixel.a < 0.99) {
		pixel.a *= 1.7;
	} else if (tom < 0.30) {
		cor *= 0.22;
	} else if (tom < 0.55) {
		cor *= 0.76;
	} else if (tom > 0.85) {
		cor = mix(cor, vec3(1.0), 0.8);
	}

	COLOR = vec4(cor, pixel.a * opacidade);
}
