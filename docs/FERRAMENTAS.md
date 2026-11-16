# Ferramentas do projeto

Os recursos usados pelo jogo já estão em `assets/` e `scenes/`. Execute os
comandos abaixo na raiz do projeto, com o editor fechado. Se o Godot estiver
fora do PATH, use o caminho do executável no lugar de `godot`.

## Base de tiles de Física

O gerador redesenha o atlas e recria o TileSet e a cena
`scenes/lab-fisica/base-lab-fisica.tscn`. A primeira execução gera a textura
para que o editor possa importá-la antes de montar a cena.

```powershell
godot --headless --path . --script res://tools/create_lab_base.gd -- --texture-only
godot --headless --path . --editor --import
godot --headless --path . --script res://tools/create_lab_base.gd
```

## Texturas e fonte

| Script em `tools/` | Recursos gerados |
| --- | --- |
| `create_lab_bench.gd` | Sombra, estrutura e tampo da bancada compartilhada |
| `create_lab_background.gd` | Camadas da janela, quadro e prateleiras de Física |
| `create_lab_magnetism.gd` | Mesa de magnetismo, ímã, peças metálicas e sombra compartilhada |
| `create_lab_motion.gd` | Pêndulo, suporte, rampa, bolinha e placa |
| `create_lab_interaction.gd` | Sinal luminoso, ícones dos convites e fonte pixelada |

Execute apenas o gerador dos arquivos que quer reconstruir e reimporte os
recursos. Por exemplo, para recriar a bancada, use estes comandos.

```powershell
godot --headless --path . --script res://tools/create_lab_bench.gd
godot --headless --path . --editor --import
```

## Captura da fase de Física

```powershell
godot --path . --script res://tools/preview_lab_base.gd -- --name=lab-fisica
```

A captura usa o renderizador do Godot e salva em `artifacts/` um PNG de
480 × 288 e outro ampliado 3×. As capturas, os logs e as cópias de recuperação
dessa pasta ficam locais.
