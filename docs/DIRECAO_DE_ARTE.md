# Direção de arte global

Todas as próximas seções e fases devem seguir este mesmo sistema visual.

- Pixel art 2D artesanal com inspiração em RPGs clássicos.
- Perspectiva top-down 3/4; profundidade por sobreposição e sombras em blocos.
- Tiles de 16 × 16 pixels. Resolução-base inicial: 480 × 288 pixels.
- Ampliação inteira, preferencialmente 3× ou 4×, com nearest-neighbor.
- Contornos escuros de 1 a 2 pixels na resolução-base.
- Aproximadamente 3 a 5 tonalidades por material; sem gradientes suaves.
- Texturas com agrupamentos intencionais de pixels, sem ruído excessivo.
- Iluminação principal vinda do alto à esquerda.
- Sprites futuros de 16 × 24 ou 24 × 32 pixels, compactos e levemente chibi.
- UI pixelada, legível e alinhada à grade, com a mesma escala do cenário.
- Não usar antialiasing, imagens vetoriais no cenário, fotografias ou 3D.

## Fase lab-fisica

Laboratório acolhedor voltado a crianças de 7 a 12 anos. Madeira em tons
quentes, paredes verde-água e contornos azul-acinzentados. A área da atividade
deve ter boa legibilidade e ser visualmente mais importante que a decoração.

Construir uma seção por vez:

1. Base: chão, paredes e vigas estruturais.
2. Centro: bancada com superfície limpa para ligar pontos.
3. Fundo: janela, prateleiras e quadro com desenhos de física.
4. Esquerda: ímã e objetos metálicos.
5. Direita: pêndulo e rampa com bolinha.
6. Parte inferior: instruções, dicas e botões.

As seções 1 a 5 estão implementadas. A bancada fica em (96, 96), ocupa
288 × 128 pixels e possui uma área central uniforme de 256 × 64 pixels para
a atividade, com origem em (112, 112) na fase. A superfície clara contrasta
com o piso; os detalhes ficam na moldura e nas gavetas frontais.

A bancada é uma cena separada, com sombra, estrutura, tampo e um marcador
de origem da área de atividade. Mantém as mesmas cores de madeira e
verde-água da sala. A faixa inferior para a interface continua livre.

O fundo é a cena `fundo-laboratorio.tscn`: janela à esquerda do quadro,
quadro de física no centro e duas prateleiras à direita. A janela mostra uma
paisagem em blocos de cor. Nuvens e colinas deslizam em ritmos diferentes
atrás dos vidros, com o sol fixo. O quadro tem uma lâmpada e a queda de uma
bola, com legendas curtas. As prateleiras contêm livros, uma régua, um peso e
uma caixa de peças. Os três elementos são independentes e usam sombras
curtas no lado inferior direito. Toda a decoração fica atrás da bancada,
sem cobrir o tampo nem ocupar as áreas dos experimentos laterais.

A lateral esquerda é a cena `lateral-magnetismo.tscn`, posicionada em
(24, 128). A mesinha ocupa 64 × 96 pixels; sombra, mesa, ímã e peças são
sprites raster separados. O ímã em ferradura possui duas metades coloridas,
polos N/S e pontas metálicas. Um prego de ferro e um clipe de aço encostam
nas pontas, enquanto outro clipe e uma esfera de aço ficam apoiados no tampo.
A mesa mantém a madeira e o verde-água do laboratório; a cor do seu tampo
é mais discreta que a superfície da bancada principal.

A lateral direita usa a mesma mesinha em (392, 128). O pêndulo oscila em
16 quadros raster na grade de pixels. A rampa de madeira tem uma bolinha
apoiada no alto. A faixa inferior fica reservada à interface.
