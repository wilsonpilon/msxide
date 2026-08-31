# MSX TUI IDE (FreeBASIC)

![MSX TUI IDE](images/msxide.png)

## Sobre o projeto

O MSX TUI IDE e um ambiente de desenvolvimento em modo texto para criar e editar programas MSX BASIC. Inspirado nas ferramentas classicas da Microsoft, como o QuickBasic e o EDIT do MS-DOS, o projeto combina uma interface retro com recursos modernos, incluindo multiplos documentos, persistencia em SQLite, compilacao automatizada e integracao com ferramentas do ecossistema MSX.

O desenvolvimento e realizado no Windows 11 com [Visual Studio Code](https://code.visualstudio.com/), [GitHub](https://github.com/) e [PowerShell](https://learn.microsoft.com/powershell/). A aplicacao e escrita em FreeBASIC e oferece backends de console nativo do Windows e newt.

## Agradecimentos

Nosso agradecimento a [Fred Rique (farique)](https://github.com/farique1), autor da [Basic Dignified Suite](https://github.com/farique1/basic-dignified), que inclui as ferramentas para MSX BASIC utilizadas neste projeto.

## Objetivo

- IDE em modo texto (TUI) inspirada no estilo dos programas antigos da Microsoft (QuickBasic).
- Estrutura modular para estudo.
- Persistencia de configuracoes/projeto em SQLite.

Estado inicial implementado

- Janela principal TUI com barra de menu simples: File -> Exit.
- Desktop com fundo quadriculado em tons de azul.
- Tamanho de janela do editor acompanha o tamanho visivel atual do console (com limites minimos/maximos de seguranca).
- Suporte interno a multiplos documentos abertos ao mesmo tempo.
- Ao iniciar sem parametros, cria automaticamente o documento `msx00.dmx`.
- Edicao de texto basica no estilo EDIT do MS-DOS:
  - Insercao de caracteres
  - Enter (quebra de linha)
  - Backspace/Delete
  - Setas, Home/End, PgUp/PgDn
  - Barras de rolagem vertical/horizontal com trilho quadriculado e thumb proporcional (posicao e tamanho)
  - Canto de juncao interno (entre barras) com grip para redimensionar por clique e arraste
- Atalhos:
  - F10: abre/fecha menu
  - Enter (no menu): Exit
  - F6: alterna janela ativa
  - F4: novo documento untitled (msxNN.dmx)
  - F2: salva documento ativo em disco
  - Esc: sai (fora do menu)
  - F8 (backend newt): alterna modo de mouse virtual
  - F7 (backend newt): centraliza ponteiro virtual
  - F9 (backend newt): clique duplo virtual

Persistencia em SQLite

- Banco: `msxide.db` (na pasta atual)
- Tabelas:
  - settings
  - projects
  - documents
- Configuracoes default gravadas:
  - source_base_url
  - startup_document
- Estado dos documentos (titulo, caminho, cursor) e salvo ao encerrar.

Dependencias

1. FreeBASIC (fbc)
2. SQLite3 (biblioteca C)

Build (Windows, exemplo)

- fbc src\main.bas src\editor.bas src\db.bas src\console.bas -d MSX_CONSOLE_WIN -x msxide.exe

SQLite em runtime

- O projeto agora carrega `sqlite3.dll` dinamicamente em tempo de execucao.
- Coloque `sqlite3.dll` ao lado de `msxide.exe` (ou em algum caminho do PATH do Windows).
- Isso evita o erro de link `cannot find -lsqlite3` no build.
- O `build.ps1` tambem baixa automaticamente a DLL oficial do SQLite para o projeto quando ela nao existir.

Execucao

- msxide.exe
- msxide.exe arquivo1.bas arquivo2.bas

Testes automatizados

- Pipeline padrao (regressao + smoke de help):

- powershell -ExecutionPolicy Bypass -File .\tests\run-tests.ps1

- Apenas regressao:

- powershell -ExecutionPolicy Bypass -File .\tests\regression\run-regression.ps1

- Apenas smoke de help:

- powershell -ExecutionPolicy Bypass -File .\tests\smoke\run-help-smoke.ps1

Build rapido com PowerShell

- Script: `build.ps1`
- O script salva configuracao padrao em `.build-config.json` apos o setup inicial.
- O backend pode ser selecionado por `--Backend win|newt`.

Exemplos:

1. Setup inicial (salva compilador e pasta FreeBASIC como padrao):

- powershell -ExecutionPolicy Bypass -File .\build.ps1 --Basic c:\dos\freebasic --Compiler fbc64.exe --Backend win

2. Build normal usando padrao salvo:

- powershell -ExecutionPolicy Bypass -File .\build.ps1

  2.1 Build com backend newt:

- powershell -ExecutionPolicy Bypass -File .\build.ps1 --Backend newt

3. Build e executar:

- powershell -ExecutionPolicy Bypass -File .\build.ps1 --Run

4. Versao manual:

- powershell -ExecutionPolicy Bypass -File .\build.ps1 --Version 1.2.3

5. Incremento de versao:

- release (patch): powershell -ExecutionPolicy Bypass -File .\build.ps1 --Version release
- minor (feature/bugfix): powershell -ExecutionPolicy Bypass -File .\build.ps1 --Version minor
- major (pacote fechado): powershell -ExecutionPolicy Bypass -File .\build.ps1 --Version major

Regra automatica:

- Se os fontes em `src` mudarem e `--Version` nao for informado, o script incrementa automaticamente a versao release (patch).

Metricas de performance no SQLite

- O editor grava metricas por segundo na tabela `perf_metrics_sec`.
- Campos registrados: `frame_count`, medias e `p95` de:
  - `char_calls` (WriteConsoleOutputCharacter)
  - `attr_calls` (WriteConsoleOutputAttribute)
  - `fill_calls` (FillConsoleOutputAttribute)
- O campo `backend_version` permite comparar historico entre versoes do backend.

Notas

- O modulo de acesso a arquivos de internet do site especifico foi preparado via configuracao `source_base_url` no SQLite. O download em si pode ser adicionado no proximo passo para manter este primeiro marco simples e estavel.
- No backend newt atual, o mouse e virtual: F8 liga/desliga; H/J/K/L ou setas movem o ponteiro; Espaco/Enter simulam clique; F9 faz clique duplo; F7 centraliza o ponteiro.
