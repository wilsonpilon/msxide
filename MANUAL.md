# Manual do msxIDE

Guia de instalação, compilação e uso do msxIDE. Para arquitetura/decisões de projeto veja
[SPEC.md](SPEC.md); para o histórico de versões veja [CHANGELOG.md](CHANGELOG.md).

## 1. O que é

Um ambiente de desenvolvimento em modo texto (TUI) pra MSX BASIC (via a suíte **Basic Dignified**) e
Z80 Assembly (via **asMSX**), com editor multi-janela, compilação/execução no **openMSX**, sistema de
projetos, ajuda integrada com dez documentos de referência MSX, e o início de um monitor/assembler
interativo (**Mamute Assembler**).

## 2. Dependências

| Dependência | Necessário para | Como obter |
|---|---|---|
| **FreeBASIC** (`fbc64.exe`) | Compilar o msxIDE | [freebasic.net](https://www.freebasic.net/) |
| **PowerShell** | Rodar `build.ps1` e os scripts de teste | Já vem no Windows 10/11 |
| **sqlite3.dll** | Rodar o msxIDE (persistência) | Baixado automaticamente pelo `build.ps1` na primeira execução |
| **asMSX** (`asmsx.exe`) | Compilar Z80 Assembly | Já incluso em `asMSX/` |
| **Basic Dignified Suite** | Compilar/tokenizar MSX BASIC | Já incluso em `basic-dignified/` |
| **openMSX** | Executar os programas compilados | Instalar à parte e apontar o caminho em `Configurar -> Emulador` |
| **newt-freebasic** | Só se for compilar com `--Backend newt` | Já incluso em `newt-freebasic/` |

O msxIDE roda em Windows (console nativo, backend `win`) e experimentalmente em outros terminais via
backend `newt` (mouse virtual por teclado — `F8` liga/desliga, setas/HJKL movem, Espaço/Enter clicam).

## 3. Download e instalação

1. Clone o repositório (ou baixe o `.zip`).
2. Instale o FreeBASIC e anote o diretório de instalação (ex.: `C:\dos\freebasic`).
3. Não é preciso instalar SQLite manualmente — o `build.ps1` baixa `sqlite3.dll` sozinho na primeira
   compilação, se ela ainda não existir na pasta do projeto.
4. (Opcional, pra rodar programas) instale o [openMSX](https://openmsx.org/) e configure o caminho em
   `Configurar -> Emulador` dentro do próprio msxIDE, ou na chave `cfg.emulator.windows.emulator_path`.

## 4. Compilação

Primeira vez (grava compilador e pasta do FreeBASIC como padrão em `.build-config.json`):

```powershell
powershell -ExecutionPolicy Bypass -File .\build.ps1 --Basic C:\dos\freebasic --Compiler fbc64.exe --Backend win
```

Depois disso, builds seguintes só precisam de:

```powershell
.\build.ps1
```

Outras opções úteis:

```powershell
.\build.ps1 --Backend newt          # compila com o backend newt em vez do nativo do Windows
.\build.ps1 --Run                   # compila e ja executa msxide.exe
.\build.ps1 --Version 1.2.3         # define uma versao manual
.\build.ps1 --Version release       # incrementa o patch (X.Y.Z+1)
.\build.ps1 --Version minor         # incrementa o minor, zera o patch (X.Y+1.0)
.\build.ps1 --Version major         # incrementa o major, zera minor/patch (X+1.0.0)
.\build.ps1 --Help                  # lista todas as opcoes
```

Se o código-fonte mudar e `--Version` não for informado, o script incrementa o patch automaticamente
(release auto). A versão atual fica gravada em `src/version.bi` (gerado a cada build) e aparece na
barra de status do editor.

O build compila `src/main.bas src/editor.bas src/compiler.bas src/db.bas src/project.bas
src/console.bas` (os backends `console_win.bas`/`console_newt.bas` entram via `#Include` dentro de
`console.bas`) e gera `msxide.exe` na raiz do projeto.

## 5. Executando

```powershell
.\msxide.exe                        # abre com o documento padrao (msx00.dmx)
.\msxide.exe arquivo1.dmx arquivo2.asm   # abre um ou mais arquivos
```

Testes headless (não precisam de teclado/mouse, seguros pra rodar em automação):

```powershell
.\msxide.exe --smoke-help           # valida o sistema de ajuda/referencia inteiro
.\msxide.exe --smoke-mamute         # valida o round-trip da config de memoria do Mamute (usa um banco descartavel proprio)
```

Suíte de testes completa:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\run-tests.ps1                    # regressao + smoke
powershell -ExecutionPolicy Bypass -File .\tests\regression\run-regression.ps1    # so regressao
powershell -ExecutionPolicy Bypass -File .\tests\smoke\run-help-smoke.ps1         # so smoke de help
```

## 6. Visão geral dos menus

- **Arquivo**: novo documento (Basic Dignified ou asMSX), abrir/salvar/fechar, e o sistema de projetos
  (`.msxproj`).
- **Configurar**: ajustes de Basic Dignified, MSX Basic (tokenizer), Emulador, e o novo configurador de
  memória do Mamute Assembler.
- **Compilar**: MSX-Basic clássico, Basic Dignified, tokenizar AMX, compilar+executar no emulador, e o
  log de compilação.
- **Ajuda**: documentação dos dialetos suportados, dicionário MSX BASIC completo, e o guia do próprio
  editor (atalhos de teclado — veja também a seção 7 abaixo).
- **Referência**: dez documentos técnicos MSX (Red Book, manuais, BIOS, openMSX, Nestor Basic, SEE
  Tracker, MSXBAS2ROM).
- **Mamute**: abre o terminal do Mamute Assembler (ainda em desenvolvimento — ver [SPEC.md](SPEC.md)).

## 7. Atalhos essenciais

| Tecla | Ação |
|---|---|
| `F10` | Abre o menu Arquivo |
| `F1` | Abre o menu Ajuda |
| `Shift+F1` | Verbete do dicionário MSX BASIC para a palavra sob o cursor |
| `F2` / `F3` / `F4` / `F5` | Salvar / Abrir / Novo / Fechar |
| `F6` | Alterna para a próxima janela aberta |
| `F8` | Abre o menu Compilar |
| `Ctrl+L` | Abre o log de compilação direto |
| `Esc` | Fecha menu/diálogo aberto, ou sai do msxIDE |
| Roda do mouse | Rola o texto (edição e ajuda) |

Lista completa e sempre atualizada: `Ajuda -> Editor` dentro do próprio programa.

## 8. Persistência

Banco `msxide.db` (SQLite) na pasta do executável — tabelas `settings`, `projects`, `documents`, mais
métricas de performance por segundo (`perf_metrics_sec`). Um `.msxproj` (sistema de projetos) é um
segundo banco SQLite independente, autocontido, que pode ser levado pra outra máquina.

## 9. Estrutura de diretórios (resumo)

```
src/            codigo-fonte FreeBASIC do msxIDE (ver apelidos dos modulos em SPEC.md)
asMSX/          assembler Z80 (binario + doc + fontes)
basic-dignified/ suite Basic Dignified (compilador/tokenizer MSX BASIC)
ajuda/          dados de referencia MSX (Red Book, manuais, BIOS, etc.) usados pelo menu Referencia
docs/help/      paginas de ajuda em markdown simples (Nestor Basic, SEE Tracker, MSXBAS2ROM, Editor)
newt-freebasic/ backend newt (so necessario para --Backend newt)
tests/          regressao + smoke tests
build.ps1       script de build/versionamento
```
