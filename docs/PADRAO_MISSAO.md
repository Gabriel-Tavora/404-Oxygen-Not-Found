# Padrão de missão

Use o [laboratório de Física](../scenes/lab-fisica/lab-fisica.tscn) como referência para montar o entorno de uma missão. As cenas abaixo podem ser reutilizadas na mesma fase ou em outros laboratórios.

## Sinal luminoso

Instancie [sinal-atividade.tscn](../scenes/laboratorios/sinal-atividade.tscn) uma vez por missão, de preferência sob o nó `Sinais` da fase. Posicione-o onde o personagem consegue pisar e configure a propriedade `atividade` no Inspector com o identificador da missão.

- A cena já tem a luz pulsante e a área de detecção. Por padrão, a área detecta a camada de colisão 2 e o script exige que o corpo esteja no grupo `jogador`.
- Conecte `convite_solicitado(atividade)` ao código da fase que abre o convite. O sinal é emitido quando o jogador entra na área. Para acioná-lo de novo após fechar o convite, o jogador sai da área e volta a pisar nela.

## Convite e aviso de repetição

Instancie uma única [convite-atividade.tscn](../scenes/ui/convite-atividade.tscn) na camada de interface da fase. Física reaproveita essa instância para os dois sinais. A cena já traz o título, o ícone, a descrição, a faixa de recompensa e os botões.

| Estado | Faixa de recompensa | Botões |
| --- | --- | --- |
| Primeira tentativa | Informe qual atributo a missão concede. Em Física, a frase é “Faz essa missão que você vai ganhar Conhecimento pra poder ir pro espaço”. | **Agora não** e **Quero tentar!** |
| Missão já concluída | Use o mesmo layout, com fundo vermelho vivo (`#d41429`) e letras brancas. Em Física, o aviso é “Você pode repetir, mas não vai ganhar mais pontos de Conhecimento.” A pergunta é “Missão concluída. Quer jogar de novo?” | **Agora não** e **Jogar de novo** |

No [script do convite](../scenes/ui/convite_atividade.gd), os títulos e as descrições ficam no dicionário `ATIVIDADES`. Para incluir outra missão, cadastre o identificador, adapte o ícone exibido e use o atributo correspondente nos textos da recompensa e da repetição. O script atual reconhece `ima` e `movimento` e usa **Conhecimento**. Ao adaptar para **Resistência** ou **Mental**, mantenha o visual e troque o nome do atributo conforme a missão.

Na [integração de Física](../scenes/lab-fisica/lab_fisica.gd), a fase consulta `ProgressoConhecimento.tarefa_concluida(id)` antes de chamar `abrir(atividade, concluida)`. Se o convite abrir, bloqueie os controles da fase. Use `respondido(atividade, aceitou)` para iniciar a missão ou devolver os controles. **Esc** equivale a recusar o convite. Ao sair da missão, devolva os controles da fase.

Registre o ponto no evento de conclusão da missão. Em Física, os IDs são `fisica/ima` e `fisica/movimento`. O [progresso de Conhecimento](../scenes/laboratorios/progresso_conhecimento.gd) registra cada ID uma vez durante a partida, então concluir a mesma missão de novo permite jogar sem somar outro ponto. Para cadastrar uma missão nova, adicione seu ID no formato `laboratorio/tarefa` a `TAREFAS` e chame `ProgressoConhecimento.concluir_tarefa(id)` quando o jogador cumprir o objetivo.

## Caixa de fala do astronauta

Instancie [dialogo-astronauta.tscn](../scenes/ui/dialogo-astronauta.tscn) como filho do `Control` da atividade quando precisar exibir uma orientação ou uma fala de encerramento. A caixa já fica no rodapé e traz o retrato pixel art. Ela começa oculta. Chame `mostrar(fala)` com o texto e `hide()` quando precisar ocultá-la. Confira se a frase cabe na resolução-base de 480 × 288.

## Barra de Conhecimento da fase

Para uma fase que acompanhe **Conhecimento**, instancie [barra-conhecimento.tscn](../scenes/ui/barra-conhecimento.tscn) na raiz da fase, como em Física. Ela tem sua própria `CanvasLayer` e acompanha o total registrado no `ProgressoConhecimento`. Para exibir outro atributo, adapte o rótulo e ligue a barra à fonte de progresso desse atributo.
