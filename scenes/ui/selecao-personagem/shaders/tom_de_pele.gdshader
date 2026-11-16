shader_type canvas_item;

varying vec4 modulacao;

void vertex() {
	modulacao = COLOR;
}

void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	float croma = pixel.r - pixel.b;
	float matiz = (pixel.g - pixel.b) / max(croma, 0.001);

	// Isola os tons quentes da pele, preservando os cabelos e o uniforme.
	float faixa_pele = smoothstep(0.31, 0.38, matiz) * (1.0 - smoothstep(0.51, 0.58, matiz));
	float intensidade = faixa_pele * smoothstep(0.11, 0.27, croma) * smoothstep(0.57, 0.89, pixel.r);
	vec3 pele = pixel.rgb * vec3(0.78, 0.64, 0.54);
	COLOR = vec4(mix(pixel.rgb, pele, intensidade), pixel.a) * modulacao;
}
