# Mamute Assembler

Referência do monitor `MON>` do Mamute Assembler - o mesmo texto de ajuda escrito originalmente para
o Mamute Assembler no paleobasic (a IDE PureBasic que serviu de inspiração/fonte deste projeto), adaptado
apenas na formatação para o visualizador de ajuda do msxIDE. Como o msxIDE é uma TUI (não uma GUI com
janelas/mouse/diálogos do Windows), alguns comandos aqui descritos com janela própria, grade de edição
ao vivo, PDF de impressora ou teclado numérico remapeável foram implementados de forma **simplificada,
mas funcional**, dentro do terminal `MON>` - a saída real de cada comando (mensagens `?ERRO DE SINTAXE`,
`ACHADO EM`, `GRAVADO EM`, etc.) é o que efetivamente roda no msxIDE hoje; o texto abaixo permanece como
a documentação original, sem cortes.

## Introdução

O **Mamute Assembler** (`Mamute -> Abrir Mamute Assembler`) é uma janela estilo "monitor" - inspirada
nos montadores de linha de comando dos computadores de 8 bits dos anos 80 (o **MegaAssembler** original
foi a inspiração direta) - em vez de uma tela cheia de campos e botões, um prompt `MON>` aceita comandos
digitados, um de cada vez.

Fundo preto, texto monoespaçado verde: visual deliberadamente diferente do resto da IDE - pra lembrar um
terminal de verdade daquela época, não um diálogo moderno.

**Não é o Editor Hexa nem os assemblers já existentes** (Basic Dignified, asMSX) - é uma ferramenta à
parte, com seu próprio pequeno conjunto de comandos. Comandos disponíveis: **BA / QUIT**, **PAGE**,
**DM**, **ZAP**, **SCR**, **SH**, **MS**, **LOAD**, **SAVE**, **M**, **S**, **C**, **D**, **P**, **V**,
**T**, **F**, **G**, **X**, **R**, **EDIT**, **L**, **LP** (**G** e **R** ainda só validam a sintaxe e confirmam no
log - a execução de programas e o carregamento de assemblados ficam pra uma fase futura). **Os
endereços/setores digitados em qualquer comando são sempre em hexadecimal** - o padrão de entrada do
Mamute Assembler inteiro.

O Mamute Assembler simula o **sistema de slots do MSX de verdade**: 4 slots (0-3), cada um com 4 páginas
de 16KB (`Página 0` = `0000-3FFF`, `Página 1` = `4000-7FFF`, `Página 2` = `8000-BFFF`, `Página 3` =
`C000-FFFF`) - 16 blocos de memória ao todo. `Configurar -> Mamute (Memória)` define o que existe
FISICAMENTE em cada um desses 16 blocos (Vazio/RAM/ROM/BIOS/BASIC/EXTBIOS, e um arquivo pra carregar
quando for ROM/BIOS/BASIC/EXTBIOS). Blocos RAM começam sempre em branco; blocos ROM/BIOS/BASIC/EXTBIOS
com arquivo configurado são lidos de verdade toda vez que o terminal abre - se o arquivo for menor que
16KB, o resto do bloco fica em branco.

A mesma tela de configuração também define o **tamanho da VRAM simulada** (16KB/32KB/64KB/128KB/192KB,
usada pelo comando `V`) - endereço plano, sem banco/página, já que a VRAM de um MSX de verdade nunca
fica mapeada no espaço de endereços do Z80 (é acessada pelas portas do VDP).

## BA / QUIT

Encerra a janela do Mamute Assembler - equivalente a fechar pelo X da janela. Sem argumentos, funciona
em qualquer um dos dois nomes (não diferencia maiúsculas de minúsculas).

**Sintaxe:**

```
MON>BA
```

ou

```
MON>QUIT
```

Qualquer outra entrada não reconhecida ainda mostra `?COMANDO INVALIDO`.

## PAGE

Mostra ou troca o **mapeamento ativo agora mesmo**: pra cada uma das 4 páginas que o Z80 enxerga (0-3),
qual dos 4 slots físicos (`Configurar -> Mamute (Memória)`) está comutado ali - exatamente como o
registrador de slot primário de um MSX de verdade. Isso é diferente da configuração física: um slot pode
ter RAM/ROM/BIOS/BASIC configurados nele, mas só o slot MAPEADO numa página é o que os próximos comandos
que mostram/inserem dados vão realmente enxergar naquele endereço.

**`PAGE`** (sem argumentos) - coloca as 4 páginas no slot marcado como RAM (o primeiro slot, varrendo 0
a 3, que tiver RAM configurada em alguma página). Mostra `?SEM RAM CONFIGURADA` se nenhum slot tiver RAM
ainda.

**`PAGE ?`** - só mostra o mapeamento ativo, sem mudar nada:

```
MON>PAGE ?
PAGE0(0000-3FFF) SLOT 0
PAGE1(4000-7FFF) SLOT 0
PAGE2(8000-BFFF) SLOT 3
PAGE3(C000-FFFF) SLOT 3
```

**`PAGE X[,Y][,Z][,K]`** - troca o mapeamento: `X` é o slot da página 0, `Y` da página 1, `Z` da página
2, `K` da página 3 (cada um de 0 a 3). **No msxIDE, ao contrário do manual original do MegaAssembler,
cada posição é opcional** - deixar um campo em branco (vírgula dupla, ou faltando no final) deixa aquela
página como está, sem precisar informar as 4 de uma vez. Exemplos:

```
MON>PAGE 2,2,2,2
```

coloca as 4 páginas no slot 2;

```
MON>PAGE 1
```

muda só a página 0 pro slot 1, deixando as demais como estavam;

```
MON>PAGE ,,2
```

muda só a página 2 pro slot 2, deixando as demais como estavam. Depois de aplicar, o novo mapeamento é
mostrado na hora (igual `PAGE ?`), pra confirmar visualmente o que mudou. Argumento fora de 0-3 mostra
`?ARGUMENTO INVALIDO`.

## DM

**Despejo de Memória** - o primeiro comando que realmente lê a memória simulada. Mostra 128 bytes (16
linhas de 8 bytes) a partir do endereço informado, em hexa e ASCII lado a lado.

**Sintaxe:**

```
MON>DM <endereco>[,<deslocamento>]
```

`<endereco>` (obrigatório) - onde começa o despejo, em hexa (0000-FFFF). `<deslocamento>` (opcional,
também hexa, com sinal `+`/`-` opcional na frente) - de `-7F` a `80` - "criptografa/descriptografa" só a
INTERPRETAÇÃO ASCII exibida: cada byte mostrado como texto é o valor cru mais o deslocamento (módulo
256) - o bloco hexa sempre mostra o byte cru da memória, sem nenhuma alteração. Exemplo:

```
MON>DM 4000,-20
```

**Layout de cada linha:** endereço na primeira coluna, 8 bytes em hexa nas colunas seguintes, os 8
caracteres correspondentes como um bloco no final. Caractere que não dá pra imprimir vira `.`. Abaixo da
grade, duas linhas de status: `Endereco:` (o endereço base atual) e `Desloc.:` (o deslocamento ativo).

**Nesta versão do msxIDE**, o `DM` é um despejo somente-leitura direto no scrollback do terminal (a
grade navegável/editável ao vivo do original fica pra uma fase futura) - pra gravar um byte, use
`M <endereco> <byte>` (ver o tópico `M`).

Escrita **só tem efeito em células mapeadas como RAM agora** (`PAGE`/`Configurar -> Mamute (Memória)`) -
ROM, BIOS, BASIC e Vazio são somente-leitura, igual hardware real (não há o que escrever fisicamente
ali).

## ZAP

**Editor de Setores de disco** - muito parecido com o `DM`, mas em vez de mostrar a memória simulada do
MSX, abre uma **imagem de disco (.dsk)** e mostra os bytes crus dela, setor a setor (512 bytes/setor).
O ZAP não interpreta a estrutura FAT12 (boot sector, FAT, diretório) - só lê bytes crus por posição,
igual um editor de setor de verdade da época.

**Sintaxe:**

```
MON>ZAP <setor inicial>[,<deslocamento>]
```

`<setor inicial>` (obrigatório, hexa) - o setor onde a grade começa (setor 0 = boot sector).
`<deslocamento>` (opcional, hexa com sinal, `-7F` a `80`) - idêntico ao do `DM`: "criptografa/
descriptografa" só a interpretação ASCII exibida, nunca o byte cru.

**Ao rodar, primeiro pede um arquivo .dsk.** Cancelar a escolha cancela o comando inteiro, sem abrir
nada.

**Layout** idêntico ao `DM` - a diferença é o rótulo de cada linha, que mostra o deslocamento DENTRO DO
SETOR atual (`000` a `1F8`), e as linhas de status mostram `Setor:` + `Byte:` (endereço absoluto dentro
do arquivo) em vez de `Endereco:`.

**Nesta versão do msxIDE**, o `ZAP` é um despejo somente-leitura do setor escolhido - a edição/gravação
de setor de volta no `.dsk` fica pra uma fase futura.

## SCR

**Display gráfico da memória** - mostra uma tela FIXA de 256x192 pixels (32x24 caracteres 8x8, a mesma
resolução de um SCREEN 2/1 real do MSX) preenchida com a memória a partir de um endereço, cada caractere
formado por 8 bytes/8 pixels (1 bit = 1 pixel), exatamente como a Pattern Generator Table do SCREEN 1/2
ou a Sprite Pattern Table de um MSX real - útil pra visualizar fontes de caracteres e sprites direto na
memória simulada.

**Sintaxe:**

```
MON>SCR <endinic>,<dx>,<dy>[,<modo>]
```

Todos os números são hexa. `<endinic>` (obrigatório) - endereço do primeiro caractere. A TELA em si é
sempre 256x192 - `<dx>`/`<dy>` (obrigatórios, >=1) NÃO mudam esse tamanho, eles definem o "azulejo"
(bloco de `dx`x`dy` caracteres) usado pra ladrilhar a tela inteira, da esquerda pra direita e de cima
pra baixo. `<modo>` (opcional, `0` ou `1`, default `0`) - ordem em que os blocos de 8 bytes são lidos
DENTRO de cada azulejo:
- **`0` (horizontal)** - linha por linha dentro do azulejo.
- **`1` (vertical)** - coluna por coluna dentro do azulejo, a mesma ordem real de armazenamento de
  sprites do MSX (por isso o manual original chama esse modo de "formato sprite").

Exemplo pra ver a tabela de caracteres ASCII de uma ROM de fonte carregada em `Configurar -> Mamute
(Memória)` (endereço 1BBF é onde a maioria das BIOS de MSX guarda o início da Pattern Generator Table;
`<dx>`=`<dy>`=`1` ladrilha a tela toda com 1 caractere por azulejo):

```
MON>SCR 1BBF,1,1
```

**Nesta versão do msxIDE**, o `SCR` mostra uma visualização reduzida em ASCII (`#`/`.`) de UM único
azulejo `dx`x`dy`, não a tela 256x192 completa ladrilhada - a navegação por setas, a moldura de edição
2x2 caracteres e o modo de edição pixel a pixel do original ficam pra uma fase futura.

## SH

**Busca de bytes ou texto na memória** - procura uma sequência de bytes exatos (com curingas opcionais)
ou um texto (testando automaticamente todos os deslocamentos possíveis). Mostra o resultado direto no
log do `MON>`.

**Sintaxe (modo bytes):**

```
MON>SH [<endereco>],<byte>[,<byte>...]
```

`<endereco>` (hexa) - onde começar a busca. Se for omitido (a vírgula continua ali, só o número antes
dela que falta - ex.: `SH ,2A,40`), a busca continua do endereço onde a ÚLTIMA busca deste comando achou
algo, mais 1 - só funciona depois de um `SH` que já tenha achado algo nesta mesma sessão da janela do
Mamute Assembler.

Cada `<byte>` é 1-2 dígitos hexa. **Deixar um `<byte>` vazio (vírgula dupla) vira curinga** - "esse byte
pode ser qualquer um". Exemplos:

```
MON>SH 4000,2A,40,0C
```

procura a sequência exata `2A 40 0C` a partir de `4000`;

```
MON>SH 4000,2A,,0C
```

procura 3 bytes onde o 1o é `2A`, o 2o pode ser qualquer coisa, e o 3o é `0C`.

**Sintaxe (modo texto):**

```
MON>SH [<endereco>],'<texto>
```

Um apóstrofo seguido do texto (sem precisar fechar com outro apóstrofo), 2+ caracteres. Diferente do
modo bytes, a busca de texto testa TODOS os deslocamentos possíveis (`-7F` a `80`, mesma faixa do
`DM`/`ZAP`) em cada posição candidata - acha tanto o texto puro (deslocamento `+00`) quanto texto
"cifrado" por um deslocamento fixo (truque comum em jogos antigos pra não deixar diálogo legível num
editor de disco cru). Exemplo:

```
MON>SH 3F41,'teste
```

**Resultado:** `ACHADO EM <endereco>` (modo bytes) ou `ACHADO EM <endereco> DESLOC <deslocamento>` (modo
texto, com sinal `+`/`-`), ou `NAO ENCONTRADO` se a busca varrer os 65536 endereços (com volta ao
início) sem achar nada.

## MS

**Grava uma string na memória** - escreve o texto digitado, byte a byte, a partir de um endereço, com um
deslocamento opcional. Confirma no log do `MON>`.

**Sintaxe:**

```
MON>MS <endereco>,[<deslocamento>],'<texto>
```

`<endereco>` (obrigatório, hexa) - onde começa a gravação. `<deslocamento>` (opcional, hexa com sinal
`+`/`-`, `-7F` a `80`, mesma faixa do `DM`/`ZAP`/`SH`) - `0` se omitido. Um apóstrofo seguido do texto
(sem precisar fechar com outro apóstrofo) - qualquer vírgula dentro do texto NÃO quebra o comando, tudo
depois do apóstrofo vira parte do texto.

Cada caractere é gravado como `(codigo do caractere - deslocamento) & FF` - a MESMA fórmula usada pelo
bloco de texto do `DM` ao editar. Isso significa que o texto gravado com um deslocamento diferente de
zero fica "cifrado" nos bytes crus - só volta a aparecer legível se depois for lido (`DM`) ou procurado
(`SH`) com esse MESMO deslocamento. Exemplo:

```
MON>MS 9A15,20,'nome
```

grava a string `nome` a partir do endereço `9A15` com deslocamento `+20` - `DM 9A15,20` (ou `SH ,'nome`
após ajustar o deslocamento) mostraria `nome` de volta.

Escrita **só tem efeito em células mapeadas como RAM agora** (`PAGE`) - mesma regra do `DM`, ROM/BIOS/
BASIC/Vazio são somente-leitura (recusa silenciosa, sem aviso separado).

## LOAD

**Carrega um arquivo na memória simulada** - totalmente interativo: não se digita nome de arquivo no
comando. Basta digitar `LOAD` sozinho:

```
MON>LOAD
```

Um nome de arquivo pode ser digitado depois do `LOAD` (`MON>LOAD alfabeto.rom`) - ele só pré-preenche o
campo de nome na janela de escolher arquivo. O arquivo que de fato vai ser carregado é sempre o que for
confirmado na janela. Cancelar a escolha cancela o comando inteiro, sem gravar nada.

Em seguida, **sempre** é perguntado em qual **Slot (0-3)** carregar - o slot que tiver RAM configurada
(`Configurar -> Mamute (Memória)`) é sugerido como padrão, mas qualquer slot pode ser escolhido.

**O que acontece depois depende da extensão do arquivo:**
- **`.ROM`** (cartucho) - carregado a partir do endereço `4000` (Página 1). Se tiver mais de 16KB (até
  32KB), ocupa também a Página 2 (`8000`). Arquivos com mais de 32KB não são suportados (precisariam de
  troca de banco, que este simulador não faz) - `?ROM MAIOR QUE 32KB NAO SUPORTADA`.
- **Binário com cabeçalho BSAVE** (qualquer outra extensão, ex.: `.bin`) - se o arquivo começar com o
  cabeçalho real do BSAVE do MSX (byte `FE` seguido de endereço inicial/final/execução, 2 bytes cada),
  carrega automaticamente no endereço indicado pelo cabeçalho.
- **Binário sem cabeçalho** - se não começar com `FE`, pergunta o **endereço inicial** (hexa) antes de
  carregar.

**`.CAS` ainda não é suportado** - mostra `?ARQUIVOS .CAS NAO SUPORTADOS AINDA` e cancela, em vez de
tentar interpretar errado.

Ao final, o resultado é mostrado no log: `CARREGADO NO SLOT <slot> EM <endereco> - TAMANHO <tamanho> -
FIM <endereco final>`.

**Diferente do `DM`/`MS`**: `LOAD` grava DIRETO na memória física do slot escolhido, independente do que
o `PAGE` tem mapeado ativo agora (simula "inserir um cartucho/carregar dado naquele slot", não escrever
pela CPU). Também ajusta a configuração física das páginas tocadas (RAM pro binário, ROM pro `.rom`) -
mas só em memória, nunca grava na configuração salva; fechar e reabrir a janela do Mamute Assembler volta
pra configuração salva de antes, igual desligar e ligar um MSX de verdade tira o cartucho.

## SAVE

**Grava um bloco de memória num arquivo** - o inverso do `LOAD`.

**Sintaxe:**

```
MON>SAVE [<nome>][,<endinic>,<endfim>[,<endexec>]]
```

Tudo opcional - `MON>SAVE` sozinho pergunta tudo interativamente. `<nome>` sugere o nome do arquivo. Se
`<endinic>`/`<endfim>` forem informados (sempre os dois juntos, `<endexec>` opcional separado - vazio
assume igual ao inicial), pré-preenchem o intervalo a gravar. Exemplo:

```
MON>SAVE rom.bin,4000,7FFF
```

**Passos:**
- **Arquivo** - nome/caminho de saída.
- **Slot (0-3)** - de qual slot físico ler os bytes. Sugerido a partir do que o `PAGE` tem mapeado ATIVO
  agora na página do endereço inicial - sempre editável pra qualquer slot.
- **Endereço inicial / final** - o bloco a gravar (inclusive nos dois extremos), obrigatórios na hora de
  salvar.
- **Endereço de execução** - vai no cabeçalho; deixar vazio usa o mesmo valor do inicial.
- **Formato** - `BIN` (cabeçalho real do BSAVE do MSX: byte `FE` + inicial + final + execução, 2 bytes
  cada) ou `ROM` (mesma ideia, mas com `AB` no lugar do `FE` - formato próprio deste simulador, NÃO é o
  cabeçalho real de 16 bytes de um cartucho MSX de verdade). Escolhido automaticamente como `ROM` se o
  nome do arquivo terminar em `.rom` (ou `BIN` caso contrário).

Ao gravar com sucesso, confirma no log do `MON>`: `SALVO "<arquivo>" - SLOT <slot> - <inicial>-<final> -
TAMANHO <tamanho>`.

**Igual o `LOAD`**: lê DIRETO da memória física do slot escolhido, sem passar pelo `PAGE` - o slot lido
é sempre exatamente o escolhido, não o que estiver mapeado ativo no momento.

## M

**Edição rápida de memória** - mesma grade de 128 bytes (16 linhas de 8, hexa+ASCII) do `DM` - a
diferença é como um byte é editado.

**Sintaxe:**

```
MON>M [<endereco>]
```

`<endereco>` opcional (hexa) - se não for informado, reabre exatamente onde ficou da última vez (só
funciona depois que o `M` já abriu pelo menos uma vez nesta sessão).

**Nesta versão do msxIDE**, `M <endereco> <byte>` grava um byte direto e confirma `GRAVADO <byte> EM
<endereco>` (a grade viva com auto-avanço do original, digitando dois dígitos hexa direto sobre a
célula, fica pra uma fase futura); `M [<endereco>]` sozinho mostra a mesma grade de 128 bytes do `DM`
(somente-leitura).

Escrita **só tem efeito em células mapeadas como RAM agora** (`PAGE`) - mesma regra do `DM`.

## S

**Igual ao `M`** (mesma grade, mesmo jeito de editar) - a ÚNICA diferença no manual original é QUAIS
teclas do teclado representam cada dígito hexa (um teclado numérico reduzido configurável, por padrão o
bloco `1234/QWER/ASDF/ZXCV` mapeado pra `0-F`, pensado pra digitar hexa rápido num teclado sem numpad
dedicado).

**Sintaxe:**

```
MON>S [<endereco>]
```

`<endereco>` opcional, mesma regra do `M` - mas o `S` guarda seu próprio "último endereço", separado do
`M`.

**Nesta versão do msxIDE**, como o terminal já aceita dígitos hexa (`0-9`/`A-F`) direto do teclado, `S` é
simplesmente um **alias completo de `M`** (mesmo formato de grade, mesmo `S <endereco> <byte>` pra
gravar) - o remapeamento de teclado numérico do manual original não se aplica a um terminal de texto.

## C

**Escolhe o modo de exibição** que os comandos `D`, `P` e `V` (dump de memória formatado) vão usar.
Sozinho não mostra nada além da confirmação - só guarda a escolha pra esses três comandos consultarem.

**Sintaxe:**

```
MON>C <modo>
```

`<modo>` de `0` a `3`:
- **`0`** - hexadecimal + ASCII, 4 bytes por linha.
- **`1`** - igual ao `0`, mas 16 bytes por linha (pra telas/impressoras de 80 colunas).
- **`2`** - só hexadecimal, 8 bytes por linha, com um checksum no final de cada linha = soma dos 8
  bytes + o byte baixo do endereço inicial da linha (tudo módulo 256).
- **`3`** - igual ao `2`, mas o checksum é só a soma dos bytes, sem somar o endereço.

Exemplo:

```
MON>C 1
MODO 1: HEXA+ASCII, 16 BYTES/LINHA
```

*Nota: precisa de espaço entre `C` e o número (`C 1`) - o `C1` colado do manual original do
MegaAssembler não é reconhecido, porque todo comando aqui separa o verbo dos argumentos pelo primeiro
espaço digitado.*

O modo escolhido dura só enquanto a janela do Mamute Assembler estiver aberta - fechar e reabrir volta
pro modo `0`.

## D

**Despejo formatado de memória, direto no log do `MON>`** - mesma memória RAM/ROM que o `DM` enxerga
(resolve pelo mapeamento `PAGE` ativo agora), formatado conforme o modo escolhido em `C` (padrão: modo
`0`).

**Sintaxe:**

```
MON>D <endinic>[,<endfim>]
```

Sem `<endfim>`, mostra só 16 bytes a partir de `<endinic>`. Com os dois, mostra o intervalo inteiro
(inclusive) - `<endfim>` não pode ser menor que `<endinic>`, e nenhum dos dois passa de `FFFF` (sem dar
a volta pro `0000` como o `SH`/`M` fazem).

Exemplo:

```
MON>D 4000,400F
```

## P

**Igual ao `D`**, mas ao invés de mandar o despejo pro log, gera uma listagem num arquivo. Simula "a
impressora" do MegaAssembler original - um driver de verdade pra impressora Epson FX-80 (ponto-a-ponto,
matriz de pontos) fica pra uma fase futura.

**Sintaxe:**

```
MON>P <endinic>[,<endfim>]
```

Mesmas regras de `<endinic>`/`<endfim>` do `D` (lê a mesma RAM/ROM mapeada agora). Cancelar a janela de
salvar não gera arquivo nenhum - só mostra `CANCELADO`.

**Nesta versão do msxIDE**, o `P` grava um arquivo de texto simples (`.txt`) em vez de um PDF - mesma
listagem, formato mais simples.

## V

**Igual ao `P`**, mas lê da **VRAM simulada** em vez da RAM/ROM - endereço plano, sem `PAGE` nem banco
algum (a VRAM de verdade de um MSX nunca fica mapeada no espaço de endereços do Z80; é acessada pelas
portas do VDP, então esta ferramenta simula ela num bloco de memória à parte, `Configurar -> Mamute
(Memória)` -> tamanho de VRAM: **16KB**/**32KB** (MSX1), **64KB**/**128KB** (MSX2) ou **192KB**
(MSX2+/turboR).

**Sintaxe:**

```
MON>V <endinic>[,<endfim>]
```

`<endinic>`/`<endfim>` aqui podem ter até 5 dígitos hexa (a VRAM máxima configurável, 192KB, passa de
`FFFF`) e são validados contra o tamanho de VRAM configurado agora - passar do teto é `?ERRO DE SINTAXE`,
sem dar a volta.

*Nota: ainda não existe nenhum comando que ESCREVA na VRAM simulada nesta versão - por enquanto ela
começa sempre zerada.*

## T

**Transfere (copia) um bloco de memória** RAM/ROM (mesma memória mapeada agora pelo `PAGE`) de um
intervalo de endereços pra outro.

**Sintaxe:**

```
MON>T <endinic>,<endfim>,<enddest>
```

Copia o bloco de `<endinic>` a `<endfim>` (inclusive) pro bloco do mesmo tamanho iniciado em
`<enddest>`. Exemplo:

```
MON>T 4000,7FFF,8000
```

copia o bloco de `4000` a `7FFF` para `8000` em diante.

Se origem e destino se sobrepõem, a cópia é feita na ordem certa pra não corromper dado ainda não lido
(de trás pra frente quando o destino vem depois da origem, de frente pra trás caso contrário) - mesmo
cuidado de um `memmove` de verdade.

`<endfim>` não pode ser menor que `<endinic>`, e o bloco copiado não pode passar de `FFFF` no destino
(sem dar a volta pro `0000`) - qualquer um dos dois casos é `?ERRO DE SINTAXE`. Escrita silenciosa em
células do destino que não sejam RAM (mesma regra do `DM`/`MS`).

## F

**Preenche um bloco de memória** RAM/ROM (mesma memória mapeada agora pelo `PAGE`) inteiro com um único
byte repetido.

**Sintaxe:**

```
MON>F <endinic>,<endfim>,<byte>
```

Exemplo:

```
MON>F 8000,C000,FF
```

preenche o bloco de `8000` a `C000` (inclusive) com `FF` em todo byte.

`<endfim>` não pode ser menor que `<endinic>`. Escrita silenciosa em células que não sejam RAM (mesma
regra do `DM`/`MS`/`T`).

## G

**Ainda NAO executa nada** - por enquanto só reconhece e valida a sintaxe do comando, confirmando no log
que o Mamute Assembler entendeu o pedido. A execução de verdade de programas na memória simulada (com
breakpoints, registradores etc.) fica pra uma fase futura deste projeto.

**Sintaxe:**

```
MON>G <endinic>[,<brkpnt1>[,<brkpnt2>]]
```

`<endinic>` (obrigatório) e até dois endereços de breakpoint opcionais - todos validados como endereço
hexa de 4 dígitos, mesma sintaxe planejada pro comando de verdade quando existir (iniciaria a execução
em `<endinic>`, carregando os registradores com o que o `X` guardou, parando ao atingir
`<brkpnt1>`/`<brkpnt2>`).

## X

**Mostra ou edita os registradores do Z80 simulado.** Sem argumento, mostra os 7 pares de registrador de
uma vez. Com argumento, entra num modo de edição sequencial - aceita tanto um PAR de registrador (`AF`,
`BC`, `DE`, `HL`, `IX`, `IY`, `SP` - editado como um valor único de 16 bits/4 dígitos hexa) quanto um
registrador de UM BYTE isolado (`A`, `F`, `B`, `C`, `D`, `E`, `H`, `L` - 2 dígitos hexa).

**Sintaxe:**

```
MON>X [<reg>]
```

Exemplos:

```
MON>X
AF=0000 BC=0000 DE=0000 HL=0000
IX=0000 IY=0000 SP=0000
```

```
MON>X BC
```

muda o prompt do terminal pra mostrar o valor atual de `BC` e pede o novo valor - confirmar com **ENTER
sem digitar nada mantém** o valor (e passa pro próximo registrador da sequência: `DE`, `HL`, `IX`, `IY`,
`SP`); digitar um valor hexa válido grava e também avança pro próximo.

```
MON>X A
```

mesma ideia, mas caminhando pelos BYTES isolados: `A`, `F`, `B`, `C`, `D`, `E`, `H`, `L`.

*Nota: o manual original do MegaAssembler só tem os registradores de 1 byte (`A`-`L`) mais `X`/`Y`/`S`
como abreviação de `IX`/`IY`/`SP` - os nomes de par diretos (`AF`/`BC`/`DE`/`HL`) editáveis como um valor
só de 16 bits são uma extensão desta ferramenta.*

Os registradores duram só enquanto a janela do Mamute Assembler estiver aberta - fechar e reabrir zera
todos de novo (mesmo espírito volátil do `PAGE`/`C`). Quando o comando `G` (execução de programas) for
implementado de verdade, vai carregar o Z80 simulado com estes valores.

## R

**Ainda NAO faz nada além de confirmar no log** que o carregamento de um programa assemblado depende do
assemblador Z80 embutido nesta ferramenta - que também fica pra uma fase futura. Nenhum argumento é
validado por enquanto.

**Sintaxe:**

```
MON>R [<offset>]
```

## L

**Disassembla a memória RAM/ROM** (mesma memória mapeada agora pelo `PAGE`) direto no log do `MON>` - um
disassembler Z80 de verdade, com o conjunto de instruções documentado inteiro mais as formas não
documentadas mais estáveis/conhecidas (`IXH`/`IXL`/`IYH`/`IYL`, formas indexadas do `CB`).

**Sintaxe:**

```
MON>L [<endinic>[,<endfim>]]
```

- **Os dois endereços** - disassembla de `<endinic>` até ultrapassar `<endfim>` (a instrução que começa
  dentro do intervalo entra inteira, mesmo que os últimos bytes dela passem um pouco de `<endfim>`).
- **Só `<endinic>`** - disassembla exatamente 10 instruções a partir dali.
- **Nenhum endereço** - continua de onde o `L`/`LP` mais recente parou, também 10 instruções.

Cada linha mostra o endereço, os bytes crus em hexa (1 a 4 bytes, conforme o tamanho da instrução) e o
mnemônico com os operandos - saltos relativos (`JR`/`DJNZ`) já mostram o **endereço de destino
absoluto**, não o deslocamento cru.

Exemplo:

```
MON>L 4000,4010
4000  E5           PUSH HL
4001  CD 39 54     CALL 5439
4004  44           LD B,H
```

## LP

**Igual ao `L`**, mas ao invés de mandar a listagem pro log, gera um arquivo de listagem - mesma ideia do
`P`/`V` (a impressora Epson FX-80 de verdade fica pra uma fase futura).

**Sintaxe:**

```
MON>LP [<endinic>[,<endfim>]]
```

Mesmas regras de `<endinic>`/`<endfim>` do `L` (inclusive continuar de onde o `L`/`LP` mais recente
parou, se nenhum endereço for passado). Cancelar a janela de salvar não gera arquivo nenhum - só mostra
`CANCELADO`.

**Nesta versão do msxIDE**, o `LP` grava um arquivo de texto simples (`.txt`) em vez de um PDF - mesma
listagem, formato mais simples.

## EDIT

**Abre uma janela separada** com um editor de linhas pro **programa-fonte Z80**, no estilo do editor de
BASIC do ZX-81/ZX Spectrum - a listagem é a própria área de cima do documento (sem log de comandos nem
mensagem "OK"), com um cursor `>` marcando a linha atual. Um campo `ASM>` reservado embaixo (junto de uma
linha de status logo acima dele) recebe tanto linhas novas do programa quanto os comandos de
gerenciamento abaixo.

**Sintaxe de cada linha** (formato do manual original do MegaAssembler):

```
NN Label: instrucao operando ;comentario
```

- **`NN`** - número da linha, **obrigatório**, **decimal** (0-65529, mesmo teto do número de linha do
  BASIC/MSX). Digitar de novo o mesmo número **substitui** a linha.
- **`Label:`** - opcional, termina em `:`.
- **`instrucao`** - um mnemônico Z80 válido ou uma das pseudo-instruções `ORG`/`DEFB`/`DEFW`/`DEFM`/
  `DEFS`/`EQU`/`END`. `EQU` exige `Label:`.
- **`;comentario`** - opcional, até o fim da linha.

**Números dentro do operando** seguem a mesma convenção já estabelecida no resto do Mamute:
**hexadecimal por padrão** (diferente do manual original, que usa decimal) - sufixos opcionais `H`
(hexa, redundante), `B` (binário), `D` (decimal, único jeito de escrever decimal agora).

**Navegação e edição, ao estilo ZX-81:**

- **Setas Cima/Baixo** movem o cursor `>` pela listagem.
- **ENTER com o campo VAZIO** puxa a linha do cursor `>` pro campo, pronta pra editar.
- **ENTER com o campo preenchido** grava a linha digitada (nova ou substituindo por `NN`).
- **ESC** descarta o que estiver no campo, sem gravar nada (não fecha a janela - use `QUIT` pra isso).
- **Tela cheia**: ao digitar linhas novas, o cursor rola **meia tela** automaticamente pra caber mais.
- **`LIST`** (digitado no campo, sem `NN` na frente): lista a partir da 1ª linha. Se o programa não
  couber inteiro, pergunta `Rolar mais uma tela? (S/N)` no rodapé (responda no mesmo campo + ENTER).

**Comandos de gerenciamento** (também digitados no campo, sem `NN` na frente):

- **`NEW`** - apaga o programa inteiro da memória, sem confirmação.
- **`DELETE <lininic>[-[<linfin>]]`** - apaga uma linha (`DELETE 50`), um intervalo inclusive
  (`DELETE 50-90`), ou da linha até o fim do programa (`DELETE 50-`, sem número final).
- **`RENUM [<novali>[,<antigali>[,<incr>]]]`** - renumera a partir da linha ANTIGA `antigali` pra uma
  nova sequência começando em `novali` com passo `incr` (`RENUM` sozinho: tudo, começando em 10, passo
  10).
- **`CHANGE '<string1>'[,'<string2>']`** - troca todas as ocorrências de `<string1>` por `<string2>` em
  qualquer lugar de cada linha; se `<string2>` for omitido, apaga as ocorrências de `<string1>`.
- **`SAVE`**/**`LOAD`** - gravam/lêem o programa-fonte inteiro num arquivo `.mza` em **ASCII simples**
  (pede o nome do arquivo no mesmo estilo do `LOAD`/`SAVE` do `MON>`) - formato próprio desta versão, não
  o formato binário proprietário do MegaAssembler original. `LOAD` SUBSTITUI o programa em memória.
- **`MERGE`** - igual ao `LOAD`, mas NÃO apaga o programa em memória - funde os dois. Uma linha do
  arquivo com o MESMO número de uma linha já existente SOBREPÕE a existente.
- **`SEARCH '<string>'`** (entre aspas) - busca LITERAL, case-sensitive. **`SEARCH <string>`** (sem
  aspas) - busca LIVRE, case-insensitive. Bem-sucedida, a tela passa a mostrar SÓ as linhas encontradas
  (mesmas setas/`ENTER` de sempre navegam entre elas) - digite `LIST` pra voltar ao programa completo.
- **`LSEARCH`** - igual ao `SEARCH`, mas em vez de filtrar a tela, grava a listagem das linhas
  encontradas num arquivo `.txt` (pede o nome do arquivo).
- **`FIND`** - apelido de `SEARCH` (mesmo resultado).
- **`QUIT`** - fecha a janela do `EDIT` e volta pro `MON>`, SEM apagar o programa da memória - abrir
  `EDIT` de novo continua exatamente de onde parou.

- **`A [<opções>][/<offset>]`** - monta o programa-fonte de verdade, com o mesmo assembler Z80 nativo do
  msxIDE (compatível M80/Nestor80). `A` sozinho só valida - mostra a listagem clássica (número da linha,
  endereço ou valor do `EQU`, até 4 bytes hexa por linha, conteúdo da linha) com a mesma paginação do
  `LIST` (`Rolar mais uma tela? (S/N)`) se não couber tudo de uma vez. Em caso de erro, mostra a
  mensagem descritiva e o cursor `>` pula direto pra linha com problema. As opções (qualquer combinação,
  coladas, ex. `A ONPIRSDH`):
  - **`O`** - além de validar, GRAVA o código-objeto montado na RAM simulada, no endereço do `ORG`,
    resolvido pelo mapeamento de `PAGE` ativo agora (mesma regra do `DM`/`M`: só grava de verdade se a
    célula mapeada for RAM).
  - **`N`** - a listagem NÃO mostra a coluna do número de linha (o resto é igual).
  - **`P`** - grava a MESMA listagem num arquivo `.txt` (pede o nome do arquivo) - **nesta versão do
    msxIDE**, em vez do PDF do manual original.
  - **`I`** - grava o código-objeto recém-montado direto em DISCO (pede o nome do arquivo), no formato
    real do `BSAVE`/`BLOAD` do MSX (cabeçalho `FE` + endereço inicial/final/execução) - funciona sozinho,
    não depende de `O` ter gravado nada na RAM antes.
  - **`R`** - anexa ao final da listagem uma referência cruzada dos símbolos (ordem alfabética): nome,
    valor (constante `EQU` ou endereço de definição do rótulo) e todos os endereços onde foi usado.
  - **`S`** - anexa ao final uma lista alfabética simples de símbolos (nome + valor, sem os endereços de
    uso).
  - **`D`** - igual a `S`, mas em ORDEM DE APARIÇÃO no fonte, não alfabética.
  - **`H`** - manda só a(s) lista(s) de símbolos (`S`/`D`, pelo menos uma precisa estar ativa) pra um
    arquivo `.txt` SEPARADO do de `P`.
  - **`/<offset>`** - monta o programa para o endereço indicado pelo `ORG` MAIS `<offset>` (hexa) - útil
    pra testar o mesmo código-objeto em outro endereço sem editar o `ORG` do fonte.
- **`MAP`** - mostra o endereço inicial e final da ÚLTIMA montagem bem-sucedida (`A` ou `A O` - os dois
  calculam o mesmo intervalo). Sem nenhuma montagem ainda, pede pra rodar `A` primeiro.

**Diferenças desta versão em relação ao manual original**: as opções `P`/`H` gravam um arquivo de texto
simples em vez de PDF (o msxIDE não tem gerador de PDF - mesma adaptação já usada pelo `L`/`LP`/
`LSEARCH`). O eco cosmético "PASSO-1"/"PASSO-2" do assembler de 2 passagens não existe aqui (só fazia
sentido numa janela gráfica animada). O motor Z80 cobre o vocabulário que o `EDIT` realmente aceita
(mnemônicos Z80 + `ORG`/`DEFB`/`DEFW`/`DEFM`/`DEFS`/`EQU`/`END`) - macros, assembly condicional
(`IF`/`IFDEF`/etc.) e segmentos relocáveis (`ASEG`/`CSEG`/`PUBLIC`/`EXTRN`) não fazem parte da gramática
do `EDIT` e por isso não são suportados.

## CLS

**Limpa a tela** - apaga todo o conteúdo do log do `MON>` (rolagem, banner de abertura, histórico de
comandos anteriores - tudo), deixando a janela em branco pronta pra continuar. Não afeta memória/PAGE/
registradores - só o texto visível no log é apagado. Sem argumentos.
