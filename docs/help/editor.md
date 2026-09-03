# Editor do msxIDE

Referência rápida dos comandos e atalhos do editor de texto do msxIDE - movimentação, edição, janelas
e ajuda contextual.

## Teclas de função

- `F1` - abre o menu Ajuda.
- `Shift+F1` - Dicionário MSX BASIC: abre o verbete do comando sob o cursor (ou o índice, se o cursor
  não estiver sobre uma palavra reconhecida). Pressionar de novo enquanto o verbete está aberto volta
  para o documento anterior.
- `F2` - Salvar o documento ativo.
- `F3` - Abrir arquivo...
- `F4` - Novo (Basic Dignified).
- `F5` - Fechar o documento ativo.
- `F6` - Janela: alterna para a próxima janela aberta.
- `F8` - abre o menu Compilar.
- `F9` - abre o menu Configurar.
- `F10` - abre o menu Arquivo.
- `Ctrl+L` - abre direto o log de compilação, sem passar pelo menu.
- `Esc` - fecha um menu ou diálogo aberto; se nada estiver aberto, sai do msxIDE.

## Movimentação do cursor

- Setas - move o cursor uma célula/linha por vez.
- `Home` - vai para o início da linha atual.
- `End` - vai para o fim da linha atual.
- `PgUp` / `PgDn` - rola uma tela inteira para cima/baixo (mantém a coluna quando possível).
- Roda do mouse - rola o texto verticalmente, tanto na tela de edição quanto nas telas de ajuda.

## Edição de texto

- Digitar um caractere imprimível insere no cursor.
- `Enter` - insere uma nova linha (nos documentos de ajuda/dicionário, em vez disso abre o link ou
  verbete sob o cursor).
- `Backspace` - apaga o caractere antes do cursor.
- `Delete` - apaga o caractere sob o cursor.

## Janelas (mouse)

Cada documento aberto vive na sua própria janela, ao estilo MDI:

- Clicar e arrastar a barra de título move a janela.
- Clicar o quadradinho `[.]` no canto superior esquerdo da barra de título fecha a janela.
- Clicar a seta no canto superior direito maximiza/restaura a janela.
- Arrastar o "grip" no canto inferior direito redimensiona a janela.
- Clicar ou arrastar as barras de rolagem vertical/horizontal move a posição de leitura.
- `F6` cicla entre as janelas abertas sem precisar do mouse.

## Ajuda contextual

- `Shift+F1` sobre uma palavra do editor abre o verbete correspondente no Dicionário MSX BASIC
  (`Ajuda -> MSX BASIC Dictionary`), se reconhecida.
- Dentro de uma tela de ajuda, clique ou `Enter` sobre uma entrada do índice, um tópico ou um link
  ("Ver também") navega até o alvo.
- `Shift+F1` dentro de uma tela de ajuda volta para o documento de onde a consulta foi aberta.

## Menus

A barra de menu no topo tem cinco itens: **Arquivo** (novo/abrir/salvar/projeto), **Configurar**
(Basic Dignified/MSX Basic/Emulador), **Compilar**, **Ajuda** (documentação do msxIDE e dos dialetos
suportados) e **Referência** (Red Book, manuais MSX, BIOS, openMSX, etc.). Clique no nome do menu na
barra do topo, ou use a tecla de função correspondente (`F10`/`F9`/`F8`/`F1`), para abrir cada um.
