# msxIDE v0.3.0 — "MAMUTE.PRN"

*2026-09-06*

O nome é um trocadilho: `PRN` é o nome de dispositivo reservado da impressora no MS-DOS clássico — e
esta versão é justamente a que ensina o Mamute Assembler a imprimir de verdade, ao mesmo tempo em que
começa a incorporar o **SUPER-X**, o segundo monitor/debugger clássico de MSX que inspira a outra metade
do projeto (ao lado do MegaAssembler, já presente desde a v0.2.0).

## Tema da versão

Duas frentes novas e complementares:

1. **SUPER-X chega ao Mamute Assembler** — começando pelo alicerce (o endereçamento estendido por
   slot/sub-slot/VRAM que praticamente todo comando futuro do SUPER-X vai usar) e cinco comandos reais:
   `XCL` (calculadora), `XD` (despejo de memória), `XF` (formato de exibição do `XD`), `XA` (listagem
   ASCII) e `XI` (listagem disassemblada).
2. **Impressora virtual com PDF de verdade** — `P`/`V`/`LP` (e as opções de impressão do `EDIT`) e
   qualquer comando não-interativo prefixado com `?` agora geram um `.pdf` real, com papel A4 ou
   formulário contínuo (CPD picotado/zebrado) configurável.

## Novidades

### SUPER-X

- **Endereçamento estendido** `<endereço>[#<slot>[-<subslot>]]`/`#V`/`#4`/`#S`/`#5` — mira um slot/
  sub-slot físico específico ou a VRAM plana (até 192KB), ignorando o mapeamento `PAGE` ativo no
  momento. Essa é a peça que todo comando SUPER-X futuro reaproveita.
- **`XCL <expressão>`** — calculadora HEX/BIN/DEC/octal: números em hexadecimal por padrão (sufixos
  `D`/`B`/`H`/`O` pras outras bases), operadores `+ - * / % | & ^ !` com precedência clássica e
  parênteses, tudo em 16 bits com wraparound.
- **`XD <inicial>[,<final>][,SAVE]`** — despejo de memória com o endereçamento estendido completo (só o
  `<inicial>` escolhe o alvo, igual a sintaxe original do SUPER-X); sem `<final>`, despeja 128 bytes;
  `SAVE` grava a mesma listagem num `.txt` à parte.
- **`XF <D|C|A|I|M>`** — escolhe o formato do `XD`: `D` (8 bytes hexa + 8 ASCII, clássico), `C` (matriz
  de pixels 16x16, porta do modo "Char"/`XH` do SUPER-X original), `A` (só ASCII), `I` (só o
  mnemônico) ou `M` (endereço + bytes + mnemônico completo).
- **`XA`**/**`XI`** — versões dedicadas do despejo ASCII e da listagem disassemblada (endereço+bytes+
  mnemônico, igual ao `L`/`LP`) como comandos próprios, com a mesma sintaxe do `XD`, independentes do
  formato atual escolhido em `XF`.

### Impressora Virtual

- **PDF real, montado do zero** (sem biblioteca nenhuma) — Courier (um dos 14 fontes base do PDF, não
  precisa embutir nada), paginação automática, e abre sozinho no visualizador padrão do Windows depois
  de gravar.
- **Papel A4** (210x297mm, margem de 1cm nos 4 lados) ou **contínuo** (formulário CPD picotado, 9.5x11
  polegadas de carro estreito, **sempre 66 linhas por formulário** — limite físico do papel, não muda
  com a fonte): zebrado **Verde**/**Azul** linha a linha cobrindo o formulário inteiro (não só as linhas
  com conteúdo), furos redondos nas duas margens a cada meio polegada, e uma linha picotada tracejada
  simulando a dobra entre formulários a cada 66 linhas.
- **Fonte Normal (10 cps) / Condensada (17 cps)** — densidade real de impressora matricial, muda quantas
  colunas cabem por linha.
- **Prefixo `?`** na frente de qualquer comando do Mamute que não dependa de mais interação (`PAGE`,
  `DM`, `SH`, `D`, `XD`, `XCL`, etc. — das duas famílias, MegaAssembler e SUPER-X) manda a saída direto
  pro PDF em vez da tela — convenção herdada do SUPER-X original, estendida aqui pra qualquer comando
  não-interativo, não só os portados do SUPER-X.
- **`Configurar -> Impressora`** — nova tela de configuração (Papel, Fonte, Zebrado, Abrir PDF
  automático).
- `P`/`V`/`LP` e as opções de impressão do `EDIT` (`LSEARCH`, `A P`, `A H`) migradas de `.txt` simples
  pra essa mesma impressora virtual.

### Documentação e organização

- `docs/help/mamute.md` reorganizado em duas famílias claras — `## Comandos do MegaAssembler` e
  `## Comandos do SUPER-X` — com uma seção nova `## Impressora Virtual`.

## Corrigido

- **Bug real de cache**: `Ajuda -> Mamute`/Editor/Nestor Basic/SEE Tracker/MSXBAS2ROM carregavam o
  markdown de `docs/help/*.md` uma única vez e guardavam pra sempre no banco local, nunca relendo o
  arquivo do disco — qualquer edição feita depois da primeira abertura ficava invisível. Esses 5
  documentos agora são ressemeados do disco toda vez que o msxIDE abre, igual os 3 documentos
  vendorizados do Basic Dignified já faziam.

## Bastidores

- Todo o trabalho novo foi verificado com testes headless (`--smoke-mamute`/`--smoke-help`) expandidos
  com dezenas de asserções, incluindo checagem estrutural real do PDF gerado (`%PDF-1.4`, `/MediaBox`,
  operadores de zebrado/furos) e verificações A/B (quebra deliberada de um trecho + confirmação de que o
  teste realmente detecta a regressão, depois restaurado) nos pontos mais arriscados — endereçamento por
  sub-slot/VRAM, layout do papel contínuo, e cada um dos 5 formatos do `XF`.
- Um PDF de teste real foi gerado e inspecionado visualmente (não só checado por string) pra confirmar
  que o zebrado linha a linha, a cobertura até o fim do formulário e a linha picotada realmente
  renderizam do jeito esperado.

## Créditos

Ver a seção "Agradecimentos" em [README.md](README.md#agradecimentos) — em especial **Romi**, autor
original do SUPER-X (1994), e **NYYRIKKI**/**JP Grobler** pela versão estendida/tradução que serviram de
referência pro endereçamento estendido e pros comandos portados nesta versão.
