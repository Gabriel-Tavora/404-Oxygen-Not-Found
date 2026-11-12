# Laboratório de Biologia — O ciclo da borboleta

- **Público** · Crianças de 7 a 12 anos
- **Objetivo** · Ligar pontos para revelar uma borboleta e descobrir as quatro etapas da sua vida.

## Base do cenário

Laboratório com piso de madeira quente, paredes verde-sálvia e contornos azul-petróleo. O tampo marfim destaca a área jogável, enquanto verdes de musgo e detalhes âmbar identificam as estações laterais. A base usa o mesmo enquadramento de **480 × 288 px** do laboratório de Física, equivalente a **30 × 18 tiles de 16 × 16 px**.

O cenário usa perspectiva top-down 3/4, luz no alto à esquerda e sombras em blocos para baixo e à direita. Os elementos mantêm contornos de 1 a 2 pixels e cerca de 3 a 5 tons por material. A exibição prevista no Godot é de 1440 × 864 a 3× ou 1920 × 1152 a 4×, com filtro nearest-neighbor. A UI usa a fonte pixelada do projeto. A cena já usa o astronauta na escala original.

1. **Centro — bancada principal.** Tampo marfim uniforme para o desenho de uma borboleta com 12 pontos numerados. A moldura e as gavetas concentram os detalhes da bancada. Números, áreas de toque e linhas entram em uma camada interativa sobre o tampo.
2. **Fundo — decoração do laboratório.** Janela com vista para um jardim, quadro com desenhos de folha e lupa e prateleiras com livros e potes de sementes. A parede usa contrastes mais suaves para preservar a leitura dos pontos.
3. **Lateral esquerda — botânica.** Bancada com bandeja de mudas, sementes e lupa. As folhas ajudam a relacionar o laboratório ao habitat das lagartas.
4. **Lateral direita — metamorfose.** Terrário com uma lagarta sobre uma folha e uma crisálida pendurada em um galho. As duas formas devem ser reconhecíveis mesmo na resolução-base.
5. **Parte inferior — interface.** Faixa livre para a instrução **«Toque no 1. Depois, siga os números.»** e os botões **Dica** e **Recomeçar**. A faixa tem fundo escuro, texto marfim e fica fora do tampo.

## Atividade de ligar pontos

- O ponto **1** recebe um contorno piscante até o primeiro toque. A criança clica ou toca nos pontos de **1 a 12**. Cada acerto fixa um segmento, e o jogo fecha o contorno ao tocar no **12**.
- Um toque fora da ordem preserva os segmentos já feitos e destaca brevemente o próximo número. **Dica** mostra uma seta para esse número. A criança pode jogar no próprio ritmo, sem cronômetro ou limite de tentativas.
- Ao completar o contorno, a borboleta ganha cor e surgem quatro ilustrações com rótulos curtos **ovo → lagarta → crisálida → borboleta**. A frase **«A lagarta muda de forma dentro da crisálida e sai como borboleta.»** resume o que foi observado no terrário.

## Montagem no Godot

- A cena [lab-bio.tscn](../scenes/lab-biologia/lab-bio.tscn) já tem cenário, astronauta, colisões, barra de Conhecimento e o sinal `SinalBorboleta`. A base usa quatro camadas de tiles editáveis no Godot para piso, parede de fundo, sombras estruturais e vigas.
- Ligar o sinal ao convite e à atividade. Registrar `biologia/borboleta` ao completar o contorno.
- Ancorar a atividade à área clara da mesa e usar a camada de interface para os controles inferiores. Manter as áreas de toque separadas e testar a leitura dos números na resolução-base e a 3×.
- Conferir o fluxo com mouse e toque, inclusive o primeiro ponto, um toque fora da ordem, a dica, o reinício e o resultado com as quatro etapas.
