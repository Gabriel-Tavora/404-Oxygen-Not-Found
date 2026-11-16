shader_type canvas_item;
// Pinta uma imagem em tons de cinza com a cor escolhida (mochila do personagem e ícone).
// Preto vira contorno, cinza médio vira a cor, branco vira o brilho.
uniform vec4 cor : source_color = vec4(0.27, 0.47, 0.86, 1.0);

void fragment() {
	vec4 t = texture(TEXTURE, UV);
	float l = t.r;
	vec3 c = cor.rgb * mix(0.55, 1.25, l);
	if (l < 0.12) {
		c = vec3(0.07, 0.08, 0.11);
	}
	COLOR = vec4(min(c, vec3(1.0)), t.a * COLOR.a);
}
