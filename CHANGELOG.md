# Changelog

Todas as mudanças notáveis do msxIDE são registradas aqui. Formato livre, em português, por versão.

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
