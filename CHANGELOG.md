# Changelog

Todas as mudanças notáveis do msxIDE são registradas aqui. Formato livre, em português, por versão.

## [0.2.0] — "MAMUTE.COM" — 2026-09-04

O mamute aprendeu a montar sozinho: o Mamute Assembler sai do "início" e vira um monitor Z80 completo,
com editor de fonte estilo ZX-81 e um assembler nativo próprio — sem depender de nenhuma ferramenta
externa pra montar código de verdade.

### Adicionado

- **Todos os comandos clássicos do monitor `MON>`**: `DM`, `ZAP`, `SCR`, `SH`, `MS`, `LOAD`/`SAVE`,
  `C`/`D`/`P`/`V`, `T`/`F`, `G`/`X`/`R`, `L`/`LP`, `HELP` — além dos já existentes `CLS`/`PAGE`/`BA`/
  `QUIT`. Escrita numa página que não é RAM agora avisa explicitamente (`AVISO: pagina nao e RAM
  agora...`) em vez de falhar em silêncio, uma melhoria deliberada sobre o comportamento do hardware
  real numa ferramenta de depuração.
- **Comando `M` virou um editor hexadecimal interativo**: grade de 128 bytes (16×8) ocupando a janela
  inteira, cursor navegável por setas/PgUp/PgDn, edição dígito a dígito em hexadecimal com avanço
  automático, rolagem contínua ao passar do fim da tela, `ENTER` avança sem gravar, `ESC` sai da edição
  sem fechar a janela nem o msxIDE.
- **Comando `EDIT`**: editor de linhas do programa-fonte Z80, estilo ZX-81/ZX Spectrum, em janela
  própria — listagem com cursor `>`, campo `ASM>` reservado embaixo, rolagem automática de meia tela.
  Sintaxe `NN Label: instrução operando ;comentário`. Comandos de gerenciamento completos: `LIST`,
  `NEW`, `DELETE`, `RENUM`, `CHANGE`, `SEARCH`/`FIND`/`LSEARCH`, `SAVE`/`LOAD`/`MERGE` (formato ASCII
  `.mza` próprio), `QUIT`.
- **Assembler Z80 nativo**, escrito do zero em FreeBASIC (compatível M80/Nestor80): tokenizador de
  expressão, avaliador RPN (shunting-yard), tabela de símbolos de 2 passes, e o codificador de
  instrução cobrindo toda a tabela de opcodes Z80 documentados e indocumentados (`IXH`/`IXL`/`IYH`/
  `IYL`, `(IX+d)`/`(IY+d)`). Acionado pelo comando `A` dentro do `EDIT`, com todas as opções do
  original combináveis (`O` grava na RAM simulada resolvida pelo `PAGE` ativo, `N` esconde número de
  linha, `P` grava a listagem em `.txt`, `I` grava código-objeto em disco no formato `BSAVE`/`BLOAD`
  real do MSX, `R`/`S`/`D` anexam referência cruzada/lista de símbolos, `H` manda a lista de símbolos
  pra um arquivo separado, `/<offset>` remonta com o `ORG` deslocado) e pelo comando `MAP`. Erro de
  montagem posiciona o cursor `>` direto na linha problemática.
- **Acentuação correta no console em Windows com locale em inglês**: o texto de ajuda (UTF-8 em disco)
  agora é convertido pra codepage OEM 860 (Português) antes de chegar na tela, em vez de aparecer como
  bytes UTF-8 crus — sem quebrar as bordas de janela (que usam a mesma faixa de caracteres OEM em
  qualquer codepage).
- **`ESC` não fecha mais o msxIDE inteiro** — era um atalho global que conflitava com o uso local de
  `ESC` em telas como a nova grade de edição do `M`. Fechar o programa continua disponível pelo menu
  `Arquivo -> Exit`.
- Testes headless (`msxide.exe --smoke-mamute`) expandidos para cobrir cada um desses comandos fim-a-
  fim através de teclas reais (`EditorHandleKey`), incluindo o comando `A` montando um programa de
  verdade, gravando na RAM simulada e mapeando um erro semântico pra linha certa do `EDIT`.

### Corrigido

- `DM`/`M` mostravam sempre zero mesmo com BIOS configurada: a página BASIC vizinha (segunda metade de
  uma ROM de 32KB) podia ficar sem arquivo próprio associado (configuração antiga/dessincronizada) —
  agora herda o arquivo da BIOS vizinha automaticamente ao carregar a memória física.

### Créditos desta versão

Ver a seção "Agradecimentos" em [README.md](README.md#agradecimentos).

---

## [0.1.1] — "MAMUTE.SYS" — 2026-09-03

Primeira versão com changelog formal — reúne tudo implementado até aqui num único marco.

### Adicionado

- **Editor de texto em TUI** com múltiplos documentos em janelas MDI (arrastar, redimensionar,
  maximizar, fechar), barras de rolagem, e roda do mouse funcionando na edição e nas telas de ajuda.
- **Compilação Basic Dignified/MSX BASIC clássico** (`Compilar`): gera `.amx`/`.bmx`, monta disco
  `.dsk` e lança o **openMSX** automaticamente. Diálogo de compilação pequeno com log rolante e botão
  de fechar `[.]`.
- **Suporte a Z80 Assembly via asMSX**: `Arquivo -> Novo asMSX` cria um "Hello ASM World" pronto pra
  montar; `Compilar + Executar` monta com o **asMSX** real e oferece inserir o binário resultante num
  programa BASIC aberto — como `BLOAD` direto, como rotina `DATA`/`POKE` com `DEFUSR`/`USR()` (tudo em
  hexadecimal, `GOSUB` automático no topo do programa), ou salvar como `.inc` pra reaproveitar em
  outros fontes assembly.
- **Sistema de projetos** (`Arquivo -> Novo/Abrir/Salvar/Fechar Projeto`): um `.msxproj` (SQLite) que
  funciona como um "zip" portátil — todo o projeto (fontes, binários, config) num arquivo só, extraído
  pra uma pasta de trabalho ao abrir e reimportado ao salvar.
- **Sistema de Ajuda** (`Ajuda`): Basic Dignified, Dignified, BaToken, asMSX, MSX BASIC Dictionary
  (dicionário completo MSX1/MSX2+/FM-Music com verbetes contextuais via `Shift+F1`), e um novo guia do
  próprio editor com todos os atalhos.
- **Menu Referência**: dez documentos técnicos MSX portados pra dentro do IDE — The MSX Red Book, MSX2
  Technical Handbook, manuais MSX-DOS2/Z80/R800/Turbo-Basic Compiler/FM-PAC, BIOS Chamadas/Hardware/
  Documentação, openMSX, Nestor Basic, SEE Tracker e MSXBAS2ROM (snapshot congelado da wiki oficial).
- **Início do Mamute Assembler** (`Configurar -> Mamute (Memória)` e `Mamute -> Abrir Mamute
  Assembler`): réplica do monitor/assembler interativo do paleobasic (mistura de Mega Assembler +
  Super-X). Fase 1: configurador de memória simulada (4 slots × sub-slots × 4 páginas, RAM/ROM,
  carregamento de ROM de 32KB dividida em BIOS+MSX-BASIC) e um terminal `MON>` básico estilo ZX-81
  (scrollback em cima, linha de comando fixa embaixo), com os comandos `CLS`/`PAGE`/`BA`/`QUIT`. Ver
  [SPEC.md](SPEC.md#2-módulo-mamute-assembler) para o roadmap completo.
- Correção do boot de disco MSX-DOS (bootstrap real portado do paleobasic — antes o disco gerado não
  passava do boot).
- Testes headless (`msxide.exe --smoke-help`, `--smoke-mamute`) cobrindo o sistema de ajuda e o
  round-trip da configuração de memória do Mamute, sem depender de automação de teclado/mouse.

### Créditos desta versão

Ver a seção "Agradecimentos" em [README.md](README.md#agradecimentos).

---

## [0.0.x] — Desenvolvimento inicial

Marco zero: janela TUI, menu `File -> Exit`, edição de texto básica estilo `EDIT` do MS-DOS,
persistência em SQLite. Sem changelog detalhado por versão nesse período — consulte o histórico do
Git.
