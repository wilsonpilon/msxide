# msxIDE v0.4.0 — "MAMUTE.FNT"

*2026-09-08*

O nome é um trocadilho direto: `.FNT` é a extensão clássica de arquivo de fonte bitmap (Windows,
impressoras antigas) — e esta versão é justamente a que ensina o mamute a desenhar suas próprias letras,
pixel a pixel, com um editor visual de fontes de caracteres MSX de verdade.

## Tema da versão

Duas frentes novas, as duas sobre "ver o que se está editando ao vivo":

1. **Editor de Fontes MSX** — cria e edita fontes de caracteres 8x8 reais do MSX (o mesmo formato que o
   hardware usa pra gerar caracteres na tela), com mapa geral e preview ampliado sempre visíveis lado a
   lado, e integração direta com o sistema de projetos.
2. **Editor de Markdown** — três modos de visualização (edição simples, dividido com preview ao vivo,
   somente leitura), reaproveitando o mesmo motor de renderização que já desenha toda a Ajuda do
   msxIDE.

## Novidades

### Editor de Fontes MSX

- **`Arquivo -> Novo Editor de Fontes`** (ou abrir um `.alf`/`.fnt`/`.chr` existente) abre um editor
  visual: mapa geral 16x16 dos 256 caracteres à esquerda, caractere selecionado ampliado em pixels (8x8,
  cada pixel desenhado como bloco cheio duplicado horizontalmente pra ficar quadrado no console) à
  direita — os dois sempre visíveis ao mesmo tempo, sem precisar esconder um pra ver o outro. Navegar
  pelo mapa já atualiza o desenho ampliado na hora; `ENTER`/`Espaço` entra no modo de edição de pixel
  (setas movem o cursor, `Espaço`/`ENTER` alterna o pixel).
- **Formato de arquivo real do MSX**: cabeçalho BSAVE de 7 bytes (`FE` + endereço inicial, final e de
  execução, 2 bytes cada, little-endian) seguido de 2048 bytes de dados (256 caracteres × 8 bytes, 1 bit
  por pixel) — o mesmo formato que `BSAVE`/`BLOAD` usam no MSX de verdade. Todo alfabeto novo nasce
  semeado a partir de `roms/msx1.alf` (a fonte MSX1 padrão, incluída neste pacote) em vez de começar em
  branco; salvar sempre grava no endereço padrão de alfabeto do MSX (`9200H`), pronto pra carregar de
  volta na RAM com `BLOAD` de verdade — mesmo que o arquivo de origem (como o próprio `msx1.alf`, um
  dump de ROM) tenha vindo de outro endereço.
- **Integração com projetos**: com um `.msxproj` aberto, cada alfabeto novo já nasce dentro da pasta
  `roms\` do próprio projeto, e é registrado no banco do projeto assim que é salvo (`F2`) — sem precisar
  passar por "Salvar Projeto" — permitindo quantos alfabetos forem necessários no mesmo projeto. O
  espaço sobrando abaixo do mapa de caracteres (a grade só precisa de 16 linhas; a maioria das janelas
  tem bem mais altura que isso) mostra a lista de alfabetos já salvos no projeto ativo: `TAB` foca a
  lista, `Cima`/`Baixo` escolhe, `ENTER` abre o escolhido numa aba nova.
- **Base pronta pro editor de Sprites**: a arquitetura (um campo `pixelEditKind` reservado no
  `Document`, toda a lógica de edição de pixel isolada em funções próprias) já foi pensada pra que um
  futuro editor de Sprites reaproveite quase tudo — só o formato dos dados e a tabela de destino mudam.

### Editor de Markdown

- **`Arquivo -> Novo Arquivo MD`** (ou abrir qualquer `.md` existente) abre o arquivo no editor de texto
  normal com um recurso a mais: `F7` alterna entre três modos — **edição simples** (só o texto cru),
  **dividido** (metade esquerda editável, metade direita com o preview renderizado ao vivo, atualizado a
  cada tecla) e **somente leitura** (a janela inteira mostra só o preview, útil pra revisar um documento
  pronto).
- Reaproveita o mesmo motor que já renderiza toda a Ajuda do msxIDE (cabeçalhos, **negrito**, `código`,
  listas, tabelas com bordas de verdade) — extraído para uma função própria
  (`BuildMarkdownBufferFromText`) sem alterar em nada o comportamento da Ajuda existente.
  Arquivos `.md` entram no sistema de projetos junto com o código-fonte.
- Novo tópico **`Ajuda -> Markdown`** com a referência rápida de formatação e o que já ganha destaque de
  verdade no preview do msxIDE.

## Corrigido

- **`F7` não tinha mapeamento nenhum**: faltava tanto no backend nativo do Windows (`console_win.bas`)
  quanto na tabela de fallback ANSI (`NormalizeKey`) — descoberto durante a implementação do atalho de
  alternância de modo do editor de Markdown, que dependia exatamente dessa tecla.

## Bastidores

- Todo o trabalho novo foi verificado com testes headless (`--smoke-help`) expandidos: navegação/edição
  de pixel no editor de Fontes, round-trip binário completo com cabeçalho BSAVE real, e um cenário de
  ponta a ponta do fluxo de projeto (criar projeto, salvar dois alfabetos, navegar e abrir pela lista do
  rodapé via teclas reais simuladas) — incluindo verificações A/B (quebra deliberada de um trecho +
  confirmação de que o teste realmente pega a regressão, depois restaurado) na detecção do cabeçalho
  BSAVE ao carregar e no endereço fixo usado ao gravar.
- O pacote `distribute/roms/msx1.alf` foi adicionado à distribuição (`build-distribute.ps1`) — sem ele,
  o Editor de Fontes cairia num alfabeto em branco em qualquer cópia instalada a partir deste pacote,
  em vez de vir pré-semeado com a fonte MSX1 padrão. Os dumps de BIOS/ROM reais (`roms\*.ROM`) continuam
  de fora do pacote distribuído — como sempre, são apontados manualmente pelo usuário em
  `Configurar -> Mamute`.

## Créditos

Ver a seção "Agradecimentos" em [README.md](README.md#agradecimentos).
