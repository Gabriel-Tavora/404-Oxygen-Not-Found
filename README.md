# 404 Oxygen Not Found

Protótipo de jogo educativo 2D em pixel art. Um astronauta explora laboratórios e
ganha pontos de Conhecimento ao completar experiências.

## Como jogar

Importe `project.godot` no **Godot 4.7** e pressione **F5**. Escolha o personagem,
o cabelo e a mochila com o mouse ou as setas e **Enter**. No mapa, use **WASD**
ou as **setas** para chegar à Base de Lançamento, à Biblioteca (Biologia),
à Academia (Resistência) ou à Sala das Emoções. O sinal vermelho da Base de
Lançamento mostra os treinos e o progresso necessários para o embarque.

Use **Esc** durante o jogo para abrir a pausa, voltar à partida ou fechar o jogo.
No hub, use **M** para trocar de personagem. Dentro de um laboratório, use **M**
ou o botão **M volta ao hub** para retornar ao mapa. Pise em um sinal luminoso
para receber o convite de uma atividade. As portas no fundo de Física e
Biologia também ligam os dois laboratórios com **E**.

## Laboratório de Física

| Sinal | Missão | Controles |
| --- | --- | --- |
| Esquerdo | Expedição magnética | Ande com **A/D** ou **←/→**, pule com **Espaço**, **W** ou **↑**, troque de polo com **X** e use o ímã com **E**. Colete as moedas e chegue à saída. |
| Direito | Lançamento oblíquo | Segure o **botão esquerdo do mouse** e arraste para ajustar a mira e a força. Solte para lançar na caixa da mesma cor. O vento muda a cada rodada. |

Use **M** para voltar ao laboratório. Para reabrir uma atividade, saia do
sinal e pise nele novamente. A barra de Conhecimento soma um ponto pela
primeira conclusão de cada missão durante a partida.

## Estrutura do projeto

- `scenes/lab-fisica/` e `scenes/lab-biologia/` guardam as fases, os cenários e as atividades.
- `scenes/astronauta/` guarda o personagem. Ele usa a camada de colisão 2 e encontra obstáculos na camada 1. Os sinais detectam o grupo `jogador`.
- `scenes/laboratorios/` guarda a bancada compartilhada, o sinal de atividade e o progresso de Conhecimento.
- `scenes/ui/` guarda a interface, os convites, a caixa de diálogo e a barra de Conhecimento.
- `assets/` reúne texturas, TileSets, animações e fontes. `tools/` contém os geradores e o script de captura.

Na árvore de cada fase, abra `Cenario` para editar a base e a decoração. Os
gatilhos das atividades ficam em `Sinais`. O jogo usa resolução-base de
480 × 288, tiles de 16 × 16, escala inteira, filtro nearest-neighbor e o
renderizador Compatibility.
