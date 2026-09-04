#Include Once "editor.bi"
#Include Once "db.bi"
#Include Once "console.bi"
#Include Once "compiler.bi"
#Include Once "project.bi"
#Include Once "version.bi"

Dim Shared docs(1 To MAX_DOCS) As Document
Dim Shared docCount As Integer
Dim Shared activeDoc As Integer
Dim Shared untitledCounter As Integer = 1
Dim Shared untitledAsmCounter As Integer = 0
Dim Shared forceFullRedraw As Integer = 1
Dim Shared uiW As Integer = 100
Dim Shared uiH As Integer = 35

Const RENDER_CURSOR = 1
Const RENDER_LINE = 2
Const RENDER_CLIENT = 3
Const RENDER_FULL = 4

Const MENU_CMD_NONE = 0
Const MENU_CMD_NEW = 1
Const MENU_CMD_NEW_ASMSX = 7
Const MENU_CMD_OPEN = 2
Const MENU_CMD_SAVE = 3
Const MENU_CMD_SAVE_AS = 4
Const MENU_CMD_CLOSE = 5
Const MENU_CMD_EXIT = 6
Const MENU_CMD_PROJECT_NEW = 8
Const MENU_CMD_PROJECT_OPEN = 9
Const MENU_CMD_PROJECT_SAVE = 10
Const MENU_CMD_PROJECT_CLOSE = 27
Const MENU_CMD_CFG_BADIG = 11
Const MENU_CMD_CFG_MSX = 12
Const MENU_CMD_CFG_EMULATOR = 13
Const MENU_CMD_COMPILE_MSX = 14
Const MENU_CMD_COMPILE_DIGNIFIED = 15
Const MENU_CMD_COMPILE_TOKENIZE_AMX = 16
Const MENU_CMD_COMPILE_RUN_EMU = 17
Const MENU_CMD_COMPILE_OPEN_LOG = 18
Const MENU_CMD_HELP_BASIC = 21
Const MENU_CMD_HELP_DIGNIFIED = 22
Const MENU_CMD_HELP_BATOKEN = 23
Const MENU_CMD_HELP_THEME = 24
Const MENU_CMD_HELP_MSX_DICT = 25
Const MENU_CMD_HELP_ASMSX = 26
Const MENU_CMD_HELP_EDITOR = 29
Const MENU_CMD_REF_REDBOOK = 30
Const MENU_CMD_REF_NESTOR = 31
Const MENU_CMD_REF_HANDBOOK = 32
Const MENU_CMD_REF_MANUALS = 33
Const MENU_CMD_REF_BIOSCALLS = 34
Const MENU_CMD_REF_HARDWARE = 35
Const MENU_CMD_REF_BIOSDOC = 36
Const MENU_CMD_REF_SEETRACKER = 37
Const MENU_CMD_REF_OPENMSX = 38
Const MENU_CMD_REF_MSXBAS2ROM = 39
Const MENU_CMD_CFG_MAMUTE_MEM = 40
Const MENU_CMD_MAMUTE_OPEN = 41
Const MENU_CMD_MAMUTE_HELP = 42

Const MENU_VIEW_NONE = 0
Const MENU_VIEW_FILE = 1
Const MENU_VIEW_HELP = 2
Const MENU_VIEW_CONFIG = 3
Const MENU_VIEW_COMPILE = 4
Const MENU_VIEW_REFERENCE = 5
Const MENU_VIEW_MAMUTE = 6

Const HELP_THEME_CLASSIC = 1
Const HELP_THEME_EDITORIAL = 2

Dim Shared renderMode As Integer = RENDER_FULL
Dim Shared dirtyLine As Integer = 1

Const MAX_PERF_FRAMES = 512
Dim Shared perfBackendVersion As String
Dim Shared perfBucketStart As Double
Dim Shared perfFrameCount As Integer
Dim Shared perfCharSamples(1 To MAX_PERF_FRAMES) As UInteger
Dim Shared perfAttrSamples(1 To MAX_PERF_FRAMES) As UInteger
Dim Shared perfFillSamples(1 To MAX_PERF_FRAMES) As UInteger
Dim Shared dragMode As Integer
Dim Shared dragOffsetX As Integer
Dim Shared dragOffsetY As Integer
Dim Shared resizeStartMouseX As Integer
Dim Shared resizeStartMouseY As Integer
Dim Shared resizeStartW As Integer
Dim Shared resizeStartH As Integer
Dim Shared helpTheme As Integer = HELP_THEME_EDITORIAL
Dim Shared helpFgText As UByte = 15
Dim Shared helpBgText As UByte = 1
Dim Shared helpFgH1 As UByte = 15
Dim Shared helpBgH1 As UByte = 4
Dim Shared helpFgH2 As UByte = 15
Dim Shared helpBgH2 As UByte = 2
Dim Shared helpFgH3 As UByte = 14
Dim Shared helpBgH3 As UByte = 0
Dim Shared helpFgCode As UByte = 10
Dim Shared helpBgCode As UByte = 8
Dim Shared helpFgList As UByte = 11
Dim Shared helpBgList As UByte = 0
Dim Shared helpFgTable As UByte = 0
Dim Shared helpBgTable As UByte = 7
Dim Shared msxDictLineCommand(1 To MAX_DOCS, 1 To MAX_LINES) As String
Dim Shared helpLineFg(1 To MAX_DOCS, 1 To MAX_LINES) As UByte
Dim Shared helpLineBg(1 To MAX_DOCS, 1 To MAX_LINES) As UByte
Dim Shared msxDictHasReturnHelp As Integer = 0
Dim Shared msxDictReturnHelpPath As String
Dim Shared msxDictReturnHelpTitle As String

' Terminal Mamute (Mon>): buffer/cursor da linha de entrada, um por documento -
' paralelo a msxDictLineCommand, nunca misturado com d.lines() (que e so o
' scrollback rolavel).
Const MAMUTE_PROMPT = "MON> "
Dim Shared mamuteInputBuf(1 To MAX_DOCS) As String
Dim Shared mamuteInputCursor(1 To MAX_DOCS) As Integer

' Estado da "caminhada" de edicao sequencial do comando X (ver o motor do
' Mamute mais abaixo no arquivo) - declarado aqui em cima, e nao perto do
' resto do motor, porque BringDocumentToFront/CloseDocument (que shiftam
' esses arrays em lockstep com docs()) ficam bem antes no arquivo.
Dim Shared MamuteXWalking(1 To MAX_DOCS) As Integer
Dim Shared MamuteXWalkIdx(1 To MAX_DOCS) As Integer

' Estado do editor interativo de memoria do comando M (grade de 128 bytes,
' 16 linhas x 8 colunas em hexa, adaptado pro terminal em modo texto a
' partir de MamuteM_Open do paleobasic - la e' uma janela GUI com grade
' clicavel, aqui e' o proprio corpo do documento do terminal em modo
' especial) - um por documento, mesmo motivo/mesmo padrao de shift em
' lockstep do bloco acima.
Dim Shared mamuteMEditActive(1 To MAX_DOCS) As Integer
Dim Shared mamuteMEditBaseAddr(1 To MAX_DOCS) As Integer
Dim Shared mamuteMEditCursorRow(1 To MAX_DOCS) As Integer
Dim Shared mamuteMEditCursorCol(1 To MAX_DOCS) As Integer
Dim Shared mamuteMEditNibbleStage(1 To MAX_DOCS) As Integer
Dim Shared mamuteMEditPendingHigh(1 To MAX_DOCS) As Integer

' Estado de UI de uma janela EDIT (comando EDIT do MON>, editor de linhas do
' programa-fonte Z80 estilo ZX-81) - um por documento (varias janelas EDIT
' podem coexistir, todas olhando o MESMO MamuteAsmProgram() global, ver perto
' de CompileDebugLogPath). mamuteInputBuf/mamuteInputCursor (ja declarados
' acima) sao reaproveitados pro campo "ASM>" - um documento e' terminal MON>
' OU janela EDIT, nunca os dois, sem colisao possivel.
Dim Shared mamuteEditTopIndex(1 To MAX_DOCS) As Integer
Dim Shared mamuteEditCursorIndex(1 To MAX_DOCS) As Integer
Dim Shared mamuteEditPendingScroll(1 To MAX_DOCS) As Integer
Dim Shared mamuteEditFilterMode(1 To MAX_DOCS) As Integer
Dim Shared mamuteEditListingMode(1 To MAX_DOCS) As Integer
Dim Shared mamuteEditStatusText(1 To MAX_DOCS) As String

Const MSX_DICT_DATA_PATH = "ajuda\\MsxBasicDictData.pbi"
Const MSX_DICT_DATA_PATH_2P = "ajuda\\MsxBasic2PlusDictData.pbi"
Const MSX_MANUAL_DATA_PATH = "ajuda\\MsxBasicManualData.pbi"
Const MSX_MANUAL_DATA_PATH_2P = "ajuda\\MsxBasic2PlusManualData.pbi"

' Fontes dos dicionarios de referencia (Red Book, manuais, BIOS, etc.) -
' arquivos .pbi rastreados em ajuda\, parseados em runtime com o mesmo
' mecanismo do MSX BASIC Dictionary acima (ExtractPbCallTextFromSource /
' SplitMsxDictArgs / EvalPbStringExpr).
Const REFDICT_REDBOOK_PATH = "ajuda\\RedBookHelpData.pbi"
Const REFDICT_TH2HANDBOOK_PATH = "ajuda\\Th2HandbookHelpData.pbi"
Const REFDICT_BIOSCALLS_PATH = "ajuda\\BiosCallsHelpData.pbi"
Const REFDICT_HARDWARE_PATH = "ajuda\\HardwareHelpData.pbi"
Const REFDICT_BIOSDOC_PATH = "ajuda\\BiosDocHelpData.pbi"
Const REFDICT_OPENMSX_PATH = "ajuda\\OpenMsxHelpData.pbi"
Const REFDICT_MSXMANUALS_PATH = "ajuda\\MsxManualsHelpData.pbi"
Const REFDICT_MSXMANUALS_SKIP_GROUP = "MSX2 Technical Handbook"

Const DRAG_NONE = 0
Const DRAG_MOVE = 1
Const DRAG_RESIZE = 2
Const DRAG_VSCROLL = 3
Const DRAG_HSCROLL = 4

Const COMPILE_DLG_LOG_MAX = 300

Dim Shared gCompileDlgActive As Integer = 0
Dim Shared gCompileDlgTitle As String
Dim Shared gCompileDlgLines(1 To COMPILE_DLG_LOG_MAX) As String
Dim Shared gCompileDlgLineCount As Integer = 0
Dim Shared gCompileDlgX As Integer
Dim Shared gCompileDlgY As Integer
Dim Shared gCompileDlgW As Integer
Dim Shared gCompileDlgH As Integer

Const COL_DEFAULT = 15
Const COL_COMMENT = 8
Const COL_STRING = 10
Const COL_NUMBER = 3
Const COL_CLASSIC_CMD = 14
Const COL_CLASSIC_FUNC = 9
Const COL_DIGNIFIED_CMD = 13
Const COL_OPERATOR = 12
Const COL_LABEL = 11
Const COL_DEFINE = 5
Const COL_SYMBOL = 7
Const COL_LITERAL = 6
Const COL_VARIABLE = 2

Const LIST_CLASSIC_CMDS = "|AS|AUTO|BASE|BEEP|BLOAD|BSAVE|CALL|CIRCLE|CLEAR|CLOAD|CLOSE|CLS|CMD|COLOR|CONT|COPY|CSAVE|CSRLIN|DATA|DEF|DEFDBL|DEFINT|DEFSNG|DEFSTR|DELETE|DIM|DRAW|END|ERASE|ERROR|FIELD|FILES|FOR|GET|GOSUB|GOTO|IF|INPUT|IPL|KEY|KILL|LET|LFILES|LINE|LIST|LLIST|LOAD|LOCATE|LPRINT|LSET|MAX|MERGE|MOTOR|NAME|NEW|NEXT|OFF|ON|OPEN|OUT|PAINT|POKE|PRESET|PRINT|PSET|PUT|READ|RENUM|RESTORE|RESUME|RETURN|RSET|RUN|SAVE|SCREEN|SET|SOUND|SPRITE|STEP|STOP|SWAP|THEN|TIME|TO|TROFF|TRON|USING|VDP|VPOKE|WAIT|WIDTH|"
Const LIST_CLASSIC_JUMPS = "|AUTO|DELETE|ELSE|ERL|GOSUB|GOTO|LLIST|LIST|RENUM|RESTORE|RESUME|RETURN|RUN|THEN|"
Const LIST_CLASSIC_FUNCS = "|ABS|ASC|ATN|ATTR$|BIN$|CDBL|CHR$|CINT|COS|CSNG|CVD|CVI|CVS|DEFUSR|DSKF|DSKI$|DSKO$|EOF|ERL|ERR|EXP|FIX|FN|FPOS|FRE|HEX$|INKEY$|INP|INSTR|INT|LEFT$|LEN|LOC|LOF|LOG|LPOS|MID$|MKD$|MKI$|MKS$|OCT$|PAD|PDL|PEEK|PLAY|POINT|POS|RIGHT$|RND|SGN|SIN|SPC|SQR|STICK|STR$|STRING$|STRIG|TAB|TAN|USR|VAL|VARPTR|VPEEK|"
Const LIST_DIGNIFIED_CMDS = "|DEFINE|DECLARE|INCLUDE|KEEP|ENDIF|FUNC|RET|EXIT|"
Const LIST_OPERATORS = "|AND|MOD|NOT|OR|XOR|IMP|EQV|"
Const LIST_LITERALS = "|TRUE|FALSE|"

Const MAX_SYNTAX_W = 256

Const CFG_KIND_TEXT = 0
Const CFG_KIND_BOOL = 1
Const CFG_KIND_INT = 2
Const CFG_KIND_ENUM = 3
Const CFG_KIND_PATH = 4

Const CFG_EXIT_CANCEL = 0
Const CFG_EXIT_SAVE = 1
Const CFG_EXIT_DISCARD = 2

Const COMPILE_MODE_MSX = 1
Const COMPILE_MODE_DIGNIFIED = 2
Const COMPILE_MODE_TOKENIZE_AMX = 3
Const COMPILE_MODE_RUN_EMU = 4

Const ASM_LOADER_NONE = 0
Const ASM_LOADER_BLOAD = 1
Const ASM_LOADER_DATA = 2
Const ASM_LOADER_INC = 3

Type ConfigField
    keyName As String
    label As String
    kind As Integer
    value As String
    defaultValue As String
    originalValue As String
    hint As String
    options As String
    hasIntRange As Integer
    minInt As Integer
    maxInt As Integer
    dirty As Integer
End Type

Declare Function GetClientTextWidth(ByRef d As Document) As Integer
Declare Function GetMaxScrollY(ByRef d As Document) As Integer
Declare Sub ClampScroll(ByRef d As Document)
Declare Sub DrawMamuteInputLine(ByVal docIndex As Integer, ByVal rowY As Integer)
Declare Sub BuildMarkdownHelpBuffer(ByRef filePath As String, ByVal wrapWidth As Integer, outLines() As String, outColors() As UByte, outBgs() As UByte, ByRef outCount As Integer, indexTargets() As Integer, indexEntryLine() As Integer, ByRef indexCount As Integer)
Declare Sub EnsureHelpRerender(ByRef d As Document)
Declare Sub ShowConfigForm(ByRef titleText As String, ByRef configGroup As String)
Declare Function PromptConfigExitAction(ByRef titleText As String) As Integer
Declare Sub CompileActiveDocument(ByVal compileMode As Integer)
Declare Sub ShowInfoDialog(ByRef titleText As String, ByRef msg1 As String, ByRef msg2 As String = "")
Declare Sub EditorCreateAsmUntitled()
Declare Sub EditorCreateMamuteTerm()
Declare Sub ShowMamuteMemoryConfig()
Declare Sub HandleMamuteTermKey(ByRef d As Document, ByRef keyText As String, ByRef renderHint As Integer)
Declare Sub HandleMamuteMEditKey(ByRef d As Document, ByRef keyText As String, ByRef renderHint As Integer)
Declare Sub DrawMamuteMEditGrid(ByVal docIndex As Integer)
Declare Sub MamuteMEditOpen(ByVal docIndex As Integer, ByVal startAddr As Integer)
Declare Sub HandleMamuteEditKey(ByRef d As Document, ByRef keyText As String, ByRef renderHint As Integer)
Declare Sub DrawMamuteEditView(ByVal docIndex As Integer)
Declare Sub EditorCreateMamuteEdit()
Declare Function MamuteCurrentPromptText(ByVal docIndex As Integer) As String
Declare Sub CompileDlgReset(ByRef titleText As String)
Declare Sub CompileDlgLog(ByRef lineText As String)
Declare Sub CompileDlgFinish(ByRef msg1 As String, ByRef msg2 As String, ByVal isSuccess As Integer)
Declare Sub BringDocumentToFront(ByVal docIndex As Integer)
Declare Sub ReflowWindows()
Declare Sub InitBlankDocument(ByRef d As Document, ByRef docTitle As String)
Declare Sub LayoutNewDocumentWindow(ByVal docIndex As Integer)

Type MsxDictEntry
    title As String
    isFunction As Integer
    isAdvanced As Integer
    origin As String
    summary As String
    formatText As String
    formatExample As String
    functionText As String
    programExample As String
    pageNumber As Integer
End Type

Type MsxManualTopicEntry
    title As String
    partName As String
    bodyText As String
    pageNumber As Integer
End Type

Type RefTopicEntry
    title As String
    groupName As String
    bodyText As String
End Type

' Modelo de memoria simulada do Mamute Assembler: 4 slots x 4 sub-slots x 4
' paginas de 16KB cada. Quando um slot nao tem sub-slots ligados, so o sub 0
' e usado e representa o slot inteiro.
Const MAMUTE_CELL_NONE = 0
Const MAMUTE_CELL_RAM = 1
Const MAMUTE_CELL_ROM = 2
Const MAMUTE_CELL_BIOS = 3
Const MAMUTE_CELL_BASIC = 4
Const MAMUTE_CELL_EXTBIOS = 5

Type MamuteMemCell
    cellType As Integer
    romPath As String
    romOffset As Integer
End Type

Dim Shared MamuteMemGrid(0 To 3, 0 To 3, 0 To 3) As MamuteMemCell
Dim Shared MamuteMemSubOn(0 To 3) As Integer

' Tamanho da VRAM simulada, em KB - so os valores reais existentes em
' hardware MSX (16/32 = MSX1, 64/128 = MSX2 comum, 192 = MSX2+/turboR).
Dim Shared MamuteVramKB As Integer

' Mapeamento "ativo" de PAGE: pra cada pagina da CPU (0-3), qual slot/sub-slot
' esta visivel ali agora (equivalente ao registrador de selecao de slot
' primario/secundario do MSX de verdade). Preenchido por
' SetMamuteDefaultPageMapping() quando o terminal abre.
Dim Shared MamuteActiveSlot(0 To 3) As Integer
Dim Shared MamuteActiveSub(0 To 3) As Integer

' Memoria FISICA simulada: um byte de verdade por Slot x Sub-slot x Pagina x
' Deslocamento (4x4x4x16384 = 4MB, trivial hoje em dia). So e populada por
' Mamute_LoadPhysicalMemory() (chamada quando o terminal abre - nunca a cada
' comando, senao RAM escrita seria perdida toda hora): celulas RAM comecam
' zeradas; celulas ROM/BASIC/BIOS/EXTBIOS com arquivo configurado sao lidas
' de verdade do arquivo, a partir do offset configurado, ate 16KB (arquivo
' menor = resto zerado). MamuteVram e' um bloco plano separado (a VRAM real
' de um MSX nunca fica mapeada no espaco de enderecos do Z80).
Dim Shared MamuteMem(0 To 3, 0 To 3, 0 To 3, 0 To 16383) As UByte
Dim Shared MamuteVram(0 To 196607) As UByte

' Registradores do Z80 simulado (comando X) - pares de 16 bits; os de 8 bits
' (A/F/B/C/D/E/H/L) sao as metades alta/baixa dos 4 primeiros. Resetam pra
' 0000 toda vez que o terminal abre (mesmo espirito volatil do PAGE/C).
Dim Shared MamuteRegAF As Integer
Dim Shared MamuteRegBC As Integer
Dim Shared MamuteRegDE As Integer
Dim Shared MamuteRegHL As Integer
Dim Shared MamuteRegIX As Integer
Dim Shared MamuteRegIY As Integer
Dim Shared MamuteRegSP As Integer

' (MamuteXWalking/MamuteXWalkIdx ja declarados perto do topo do arquivo,
' junto de mamuteInputBuf/mamuteInputCursor - ver linha ~120.)

' Modo de exibicao (comando C) usado por D/P/V - dura so' enquanto o
' terminal estiver aberto (reseta pra 0 quando reabre).
Dim Shared MamuteDisplayMode As Integer

' Ultimo endereco/estado de continuacao dos comandos que "lembram de onde
' pararam" quando chamados sem argumento: SH (busca), M, S (edicao rapida),
' L/LP (disassembler, os dois avancam o MESMO ponteiro).
Dim Shared MamuteLastShAddr As Integer
Dim Shared MamuteLastShValid As Integer
Dim Shared MamuteLastMAddr As Integer
Dim Shared MamuteLastMValid As Integer
Dim Shared MamuteLastSAddr As Integer
Dim Shared MamuteLastSValid As Integer
Dim Shared MamuteLastDisasmAddr As Integer
Dim Shared MamuteLastDisasmValid As Integer

' Programa-fonte Z80 do comando EDIT (editor de linhas estilo ZX-81) - um
' array so, Global/Shared (nao por documento): varias janelas EDIT podem
' estar abertas ao mesmo tempo, todas editando o MESMO programa (mesmo
' espirito do "o programa fica na memoria do EMA" do manual original -
' fechar a janela com QUIT nao apaga nada, so' NEW apaga). Mantido sempre
' ordenado por lineNum (Mamute_AsmStoreLine insere/substitui na posicao
' certa por deslocamento de array, ja que FreeBASIC nao tem lista ligada
' nativa aqui) - MAX_LINES (2000) e' o mesmo teto usado por Document.lines().
Const MAMUTE_ASM_MAX_LINES = MAX_LINES

Type MamuteAsmLine
    lineNum As Integer
    rawText As String   ' corpo completo digitado (sem o NN) - o que SAVE grava e SEARCH/CHANGE varrem
    labelText As String ' sem o ":" final; "" se nao tiver
    instr As String     ' mnemonico/pseudo-instrucao, sempre maiusculo
    operand As String   ' texto cru do operando (antes do ";")
    comment As String   ' texto depois do ";", sem o ";"; "" se nao tiver
End Type

Dim Shared MamuteAsmProgram(1 To MAMUTE_ASM_MAX_LINES) As MamuteAsmLine
Dim Shared MamuteAsmProgramCount As Integer

' Resultados do ultimo SEARCH/LSEARCH bem-sucedido (comando EDIT) - indices
' (1-based) dentro de MamuteAsmProgram(), em ordem crescente. Global, mesmo
' espirito do array acima - consumido pelo "modo filtro" de qualquer janela
' EDIT com mamuteEditFilterMode(doc)<>0.
Dim Shared MamuteAsmSearchMatches(1 To MAMUTE_ASM_MAX_LINES) As Integer
Dim Shared MamuteAsmSearchCount As Integer

Private Function CompileDebugLogPath() As String
    Dim p As String = Environ("TEMP")
    If Len(p) = 0 Then p = CurDir()
    If Right(p, 1) <> Chr(92) And Right(p, 1) <> "/" Then p &= Chr(92)
    Return p & "bahero_compile_debug.log"
End Function

Private Function CompileDebugWorkspaceLogPath() As String
    MkDir("logs")
    Return CurDir() & Chr(92) & "logs" & Chr(92) & "bahero_compile_debug.log"
End Function

Private Function CompileDebugSanitize(ByRef txt As String) As String
    Dim outText As String = ""
    Dim i As Integer
    For i = 1 To Len(txt)
        Dim ch As Integer = Asc(Mid(txt, i, 1))
        If ch = 9 Or ch = 10 Or ch = 13 Then
            outText &= " "
        Else
            outText &= Chr(ch)
        End If
    Next i
    Return Trim(outText)
End Function

Private Sub CompileDebugLog(ByRef area As String, ByRef messageText As String)
    Dim cleanMsg As String = CompileDebugSanitize(messageText)
    Dim lineText As String = Date & " " & Time & " [" & area & "] " & cleanMsg

    Dim ff As Integer = FreeFile
    If Open(CompileDebugLogPath() For Append As #ff) = 0 Then
        Print #ff, lineText
        Close #ff
    End If

    ff = FreeFile
    If Open(CompileDebugWorkspaceLogPath() For Append As #ff) = 0 Then
        Print #ff, lineText
        Close #ff
    End If

    Dim dlgLine As String = "[" & area & "] " & cleanMsg
    CompileDlgLog(dlgLine)
End Sub

Private Sub OpenCompileLogDocument()
    Dim logPath As String = CompileDebugLogPath()
    Dim i As Integer

    For i = 1 To docCount
        If docs(i).isHelp = 0 And LCase(docs(i).filePath) = LCase(logPath) Then
            BringDocumentToFront(i)
            forceFullRedraw = 1
            renderMode = RENDER_FULL
            Exit Sub
        End If
    Next i

    If Dir(logPath) = "" Then
        Dim ff As Integer = FreeFile
        If Open(logPath For Output As #ff) <> 0 Then
            ShowInfoDialog("Compilar", "Falha ao abrir log de compilacao.", logPath)
            Exit Sub
        End If
        Print #ff, "Log criado. Aguardando eventos de compilacao..."
        Close #ff
    End If

    EditorOpenFromPath(logPath)
End Sub

Private Function P95FromSamples(ByVal arrBase As UInteger Ptr, ByVal n As Integer) As Double
    If n <= 0 Then Return 0

    Dim tmp(1 To MAX_PERF_FRAMES) As UInteger
    Dim i As Integer
    For i = 1 To n
        tmp(i) = *(arrBase + (i - 1))
    Next i

    ' Insertion sort e suficiente para lote pequeno de 1 segundo.
    Dim j As Integer
    For i = 2 To n
        Dim v As UInteger = tmp(i)
        j = i - 1
        While j >= 1 And tmp(j) > v
            tmp(j + 1) = tmp(j)
            j -= 1
        Wend
        tmp(j + 1) = v
    Next i

    Dim idx As Integer = CInt(n * 0.95)
    If (n * 95) Mod 100 <> 0 Then idx += 1
    If idx < 1 Then idx = 1
    If idx > n Then idx = n
    Return tmp(idx)
End Function

Private Sub PerfResetBucket()
    perfBucketStart = Timer
    perfFrameCount = 0
End Sub

Private Sub PerfFlushBucket(ByRef bucketTime As String)
    If perfFrameCount <= 0 Then Exit Sub

    Dim i As Integer
    Dim sumChar As Double = 0
    Dim sumAttr As Double = 0
    Dim sumFill As Double = 0

    For i = 1 To perfFrameCount
        sumChar += perfCharSamples(i)
        sumAttr += perfAttrSamples(i)
        sumFill += perfFillSamples(i)
    Next i

    Dim avgChar As Double = sumChar / perfFrameCount
    Dim avgAttr As Double = sumAttr / perfFrameCount
    Dim avgFill As Double = sumFill / perfFrameCount

    Dim p95Char As Double = P95FromSamples(@perfCharSamples(1), perfFrameCount)
    Dim p95Attr As Double = P95FromSamples(@perfAttrSamples(1), perfFrameCount)
    Dim p95Fill As Double = P95FromSamples(@perfFillSamples(1), perfFrameCount)

    DbSavePerfSecond(perfBackendVersion, bucketTime, perfFrameCount, avgChar, avgAttr, avgFill, p95Char, p95Attr, p95Fill)
    perfFrameCount = 0
End Sub

Private Sub PerfCaptureFrame()
    Dim charCalls As UInteger
    Dim attrCalls As UInteger
    Dim fillCalls As UInteger

    ConsoleGetLastFrameStats(charCalls, attrCalls, fillCalls)

    If perfFrameCount < MAX_PERF_FRAMES Then
        perfFrameCount += 1
        perfCharSamples(perfFrameCount) = charCalls
        perfAttrSamples(perfFrameCount) = attrCalls
        perfFillSamples(perfFrameCount) = fillCalls
    End If

    Dim nowT As Double = Timer
    Dim dt As Double = nowT - perfBucketStart
    If dt < 0 Then
        ' Ajuste de virada de dia do Timer.
        dt += 86400
    End If

    If dt >= 1.0 Then
        PerfFlushBucket(Date & " " & Time)
        perfBucketStart = nowT
    End If
End Sub

Private Sub RequestRender(ByVal mode As Integer, ByVal lineNumber As Integer = 1)
    If mode > renderMode Then renderMode = mode
    If mode = RENDER_LINE Then dirtyLine = lineNumber
End Sub

Private Function NormalizeKey(ByRef keyText As String) As String
    Dim k As String = keyText

    ' Alguns ambientes retornam teclas estendidas com prefixo 255.
    If Len(k) = 2 And Asc(Left(k, 1)) = 255 Then
        Return Chr(0) & Right(k, 1)
    End If

    ' Sequencias ANSI comuns de navegacao.
    If Left(k, 2) = Chr(27) & "[" Then
        Select Case k
            Case Chr(27) & "[A"
                Return Chr(0) & Chr(72) ' Up
            Case Chr(27) & "[B"
                Return Chr(0) & Chr(80) ' Down
            Case Chr(27) & "[C"
                Return Chr(0) & Chr(77) ' Right
            Case Chr(27) & "[D"
                Return Chr(0) & Chr(75) ' Left
            Case Chr(27) & "[H", Chr(27) & "[1~"
                Return Chr(0) & Chr(71) ' Home
            Case Chr(27) & "[F", Chr(27) & "[4~"
                Return Chr(0) & Chr(79) ' End
            Case Chr(27) & "[5~"
                Return Chr(0) & Chr(73) ' PgUp
            Case Chr(27) & "[6~"
                Return Chr(0) & Chr(81) ' PgDn
            Case Chr(27) & "[3~"
                Return Chr(0) & Chr(83) ' Delete
            Case Chr(27) & "[12~"
                Return Chr(0) & Chr(60) ' F2
            Case Chr(27) & "[13~"
                Return Chr(0) & Chr(61) ' F3
            Case Chr(27) & "[14~"
                Return Chr(0) & Chr(62) ' F4
            Case Chr(27) & "[15~"
                Return Chr(0) & Chr(63) ' F5
            Case Chr(27) & "[17~"
                Return Chr(0) & Chr(64) ' F6
            Case Chr(27) & "[19~"
                Return Chr(0) & Chr(66) ' F8
                Case Chr(27) & "[21~"
                    Return Chr(0) & Chr(68) ' F10
                Case Chr(27) & "[1;2P", Chr(27) & "[11;2~", Chr(27) & "[25~"
                    Return Chr(0) & Chr(84) ' Shift+F1
        End Select
    End If

    ' Variantes VT para F1..F4, usamos as que o editor precisa hoje.
        If k = Chr(27) & "OP" Then Return Chr(0) & Chr(59) ' F1
        If k = Chr(27) & "O1;2P" Then Return Chr(0) & Chr(84) ' Shift+F1 (alguns terminais VT)
    If k = Chr(27) & "OQ" Then Return Chr(0) & Chr(60) ' F2
    If k = Chr(27) & "OR" Then Return Chr(0) & Chr(61) ' F3
    If k = Chr(27) & "OS" Then Return Chr(0) & Chr(62) ' F4

    Return k
End Function

Private Function Clamp(ByVal value As Integer, ByVal minValue As Integer, ByVal maxValue As Integer) As Integer
    If value < minValue Then Return minValue
    If value > maxValue Then Return maxValue
    Return value
End Function

Private Function StripCR(ByRef textIn As String) As String
    Dim outText As String = ""
    Dim i As Integer
    For i = 1 To Len(textIn)
        Dim ch As String = Mid(textIn, i, 1)
        If ch <> Chr(13) Then outText &= ch
    Next i
    Return outText
End Function

Private Function IsWordStart(ByVal ch As String) As Integer
    Dim c As Integer
    If Len(ch) = 0 Then Return 0
    c = Asc(ch)
    If (c >= 65 And c <= 90) Or (c >= 97 And c <= 122) Or c = 95 Then Return -1
    Return 0
End Function

Private Function IsWordChar(ByVal ch As String) As Integer
    Dim c As Integer
    If Len(ch) = 0 Then Return 0
    c = Asc(ch)
    If (c >= 65 And c <= 90) Or (c >= 97 And c <= 122) Or (c >= 48 And c <= 57) Or c = 95 Then Return -1
    Return 0
End Function

Private Function IsDecDigit(ByVal ch As String) As Integer
    Dim c As Integer
    If Len(ch) = 0 Then Return 0
    c = Asc(ch)
    If c >= 48 And c <= 57 Then Return -1
    Return 0
End Function

Private Function IsHexDigit(ByVal ch As String) As Integer
    Dim c As Integer
    If Len(ch) = 0 Then Return 0
    c = Asc(UCase(ch))
    If (c >= 48 And c <= 57) Or (c >= 65 And c <= 70) Then Return -1
    Return 0
End Function

Private Function IsOctDigit(ByVal ch As String) As Integer
    Dim c As Integer
    If Len(ch) = 0 Then Return 0
    c = Asc(ch)
    If c >= 48 And c <= 55 Then Return -1
    Return 0
End Function

Private Function IsBinDigit(ByVal ch As String) As Integer
    If ch = "0" Or ch = "1" Then Return -1
    Return 0
End Function

Private Function InPipeList(ByRef tokenUpper As String, ByRef pipeList As String) As Integer
    If Len(tokenUpper) = 0 Then Return 0
    If InStr(pipeList, "|" & tokenUpper & "|") > 0 Then Return -1
    Return 0
End Function

Private Function IsMsxDictDoc(ByRef d As Document) As Integer
    Dim fp As String = LCase(d.filePath)
    If Left(fp, 8) = "msxdict:" Then Return -1
    Return 0
End Function

Private Sub ClearMsxDictLineMap(ByVal docIndex As Integer)
    Dim i As Integer
    For i = 1 To MAX_LINES
        msxDictLineCommand(docIndex, i) = ""
    Next i
End Sub

Private Function ReadWholeTextFile(ByRef filePath As String, ByRef outText As String) As Integer
    outText = ""
    If Dir(filePath) = "" Then Return 0
    Dim ff As Integer = FreeFile
    If Open(filePath For Input As #ff) <> 0 Then Return 0

    Dim lineText As String
    While Not Eof(ff)
        Line Input #ff, lineText
        outText &= lineText
        If Not Eof(ff) Then outText &= Chr(10)
    Wend
    Close #ff
    Return -1
End Function

Private Function UnescapePbString(ByRef rawText As String) As String
    Dim outText As String = ""
    Dim i As Integer = 1
    While i <= Len(rawText)
        If i < Len(rawText) And Mid(rawText, i, 2) = Chr(34) & Chr(34) Then
            outText &= Chr(34)
            i += 2
        Else
            outText &= Mid(rawText, i, 1)
            i += 1
        End If
    Wend
    Return outText
End Function

Private Function TrimTokenWs(ByRef s As String) As String
    If Len(s) = 0 Then Return ""

    Dim a As Integer = 1
    Dim b As Integer = Len(s)

    While a <= b
        Dim ca As Integer = Asc(Mid(s, a, 1))
        If ca > 32 Then Exit While
        a += 1
    Wend

    While b >= a
        Dim cb As Integer = Asc(Mid(s, b, 1))
        If cb > 32 Then Exit While
        b -= 1
    Wend

    If b < a Then Return ""
    Return Mid(s, a, b - a + 1)
End Function

Private Function ParsePbStringToken(ByRef sourceText As String, ByVal startPos As Integer, ByRef tokenText As String, ByRef nextPos As Integer) As Integer
    tokenText = ""
    nextPos = startPos
    If startPos < 1 Or startPos > Len(sourceText) Then Return 0
    If Mid(sourceText, startPos, 1) <> Chr(34) Then Return 0

    Dim i As Integer = startPos + 1
    While i <= Len(sourceText)
        Dim ch As String = Mid(sourceText, i, 1)
        If ch = Chr(34) Then
            If i < Len(sourceText) And Mid(sourceText, i + 1, 1) = Chr(34) Then
                tokenText &= Chr(34) & Chr(34)
                i += 2
                Continue While
            End If
            nextPos = i + 1
            Return -1
        End If
        tokenText &= ch
        i += 1
    Wend

    Return 0
End Function

Private Function EvalPbStringExpr(ByRef expr As String) As String
    Dim outText As String = ""
    Dim i As Integer = 1
    Dim inString As Integer = 0
    Dim chunk As String = ""

    While i <= Len(expr)
        Dim ch As String = Mid(expr, i, 1)
        If ch = Chr(34) Then
            If inString <> 0 And i < Len(expr) And Mid(expr, i + 1, 1) = Chr(34) Then
                chunk &= Chr(34) & Chr(34)
                i += 2
                Continue While
            End If
            inString = Not inString
            chunk &= ch
            i += 1
            Continue While
        End If

        If inString = 0 And ch = "+" Then
            Dim part As String = TrimTokenWs(chunk)
            If Left(part, 1) = Chr(34) And Right(part, 1) = Chr(34) And Len(part) >= 2 Then
                outText &= UnescapePbString(Mid(part, 2, Len(part) - 2))
            ElseIf UCase(part) = "#CRLF$" Then
                outText &= Chr(13) & Chr(10)
            ElseIf UCase(part) = "MSXQ" Then
                outText &= Chr(34)
            ElseIf UCase(part) = "CHR(34)" Then
                outText &= Chr(34)
            End If
            chunk = ""
            i += 1
            Continue While
        End If

        chunk &= ch
        i += 1
    Wend

    Dim tail As String = TrimTokenWs(chunk)
    If Left(tail, 1) = Chr(34) And Right(tail, 1) = Chr(34) And Len(tail) >= 2 Then
        outText &= UnescapePbString(Mid(tail, 2, Len(tail) - 2))
    ElseIf UCase(tail) = "#CRLF$" Then
        outText &= Chr(13) & Chr(10)
    ElseIf UCase(tail) = "MSXQ" Then
        outText &= Chr(34)
    ElseIf UCase(tail) = "CHR(34)" Then
        outText &= Chr(34)
    End If

    Return outText
End Function

Private Function SplitMsxDictArgs(ByRef callText As String, args() As String, ByRef argCount As Integer) As Integer
    argCount = 0
    Dim pOpen As Integer = InStr(callText, "(")
    Dim pClose As Integer = InStrRev(callText, ")")
    If pOpen <= 0 Or pClose <= pOpen Then Return 0

    Dim body As String = Mid(callText, pOpen + 1, pClose - pOpen - 1)
    Dim i As Integer = 1
    Dim inString As Integer = 0
    Dim depth As Integer = 0
    Dim chunk As String = ""

    While i <= Len(body)
        Dim ch As String = Mid(body, i, 1)
        If ch = Chr(34) Then
            If inString <> 0 And i < Len(body) And Mid(body, i + 1, 1) = Chr(34) Then
                chunk &= Chr(34) & Chr(34)
                i += 2
                Continue While
            End If
            inString = Not inString
            chunk &= ch
            i += 1
            Continue While
        End If

        If inString = 0 Then
            If ch = "(" Then
                depth += 1
            ElseIf ch = ")" And depth > 0 Then
                depth -= 1
            ElseIf ch = "," And depth = 0 Then
                argCount += 1
                If argCount = 1 Then
                    ReDim args(1 To 1)
                Else
                    ReDim Preserve args(1 To argCount)
                End If
                args(argCount) = TrimTokenWs(chunk)
                chunk = ""
                i += 1
                Continue While
            End If
        End If

        chunk &= ch
        i += 1
    Wend

    If Len(TrimTokenWs(chunk)) > 0 Then
        argCount += 1
        If argCount = 1 Then
            ReDim args(1 To 1)
        Else
            ReDim Preserve args(1 To argCount)
        End If
        args(argCount) = TrimTokenWs(chunk)
    End If

    Return IIf(argCount > 0, -1, 0)
End Function

Private Function ParseMsxDictCall(ByRef callText As String, ByRef outEntry As MsxDictEntry) As Integer
    Dim args() As String
    Dim argCount As Integer
    If SplitMsxDictArgs(callText, args(), argCount) = 0 Then Return 0
    If argCount < 10 Then Return 0

    outEntry.title = EvalPbStringExpr(args(1))
    outEntry.isFunction = IIf(UCase(TrimTokenWs(args(2))) = "#TRUE", -1, 0)
    outEntry.isAdvanced = IIf(UCase(TrimTokenWs(args(3))) = "#TRUE", -1, 0)
    outEntry.origin = EvalPbStringExpr(args(4))
    outEntry.summary = EvalPbStringExpr(args(5))
    outEntry.formatText = EvalPbStringExpr(args(6))
    outEntry.formatExample = EvalPbStringExpr(args(7))
    outEntry.functionText = EvalPbStringExpr(args(8))
    outEntry.programExample = EvalPbStringExpr(args(9))
    outEntry.pageNumber = ValInt(TrimTokenWs(args(10)))
    Return IIf(Len(outEntry.title) > 0, -1, 0)
End Function

Private Function ExtractPbCallTextFromSource(ByRef sourceText As String, ByVal startPos As Integer, ByRef outCallText As String) As Integer
    outCallText = ""
    If startPos < 1 Or startPos > Len(sourceText) Then Return 0

    Dim p As Integer = InStr(startPos, sourceText, "(")
    If p <= 0 Then Return 0

    Dim i As Integer = p
    Dim depth As Integer = 0
    Dim inString As Integer = 0

    While i <= Len(sourceText)
        Dim ch As String = Mid(sourceText, i, 1)
        If ch = Chr(34) Then
            If inString <> 0 And i < Len(sourceText) And Mid(sourceText, i + 1, 1) = Chr(34) Then
                i += 2
                Continue While
            End If
            inString = Not inString
        ElseIf inString = 0 Then
            If ch = "(" Then
                depth += 1
            ElseIf ch = ")" Then
                depth -= 1
                If depth = 0 Then Exit While
            End If
        End If
        i += 1
    Wend

    If i > Len(sourceText) Then Return 0
    outCallText = Mid(sourceText, startPos, i - startPos + 1)
    Return -1
End Function

Private Function ParseMsxManualCall(ByRef callText As String, ByRef outEntry As MsxManualTopicEntry) As Integer
    Dim args() As String
    Dim argCount As Integer
    If SplitMsxDictArgs(callText, args(), argCount) = 0 Then Return 0
    If argCount < 4 Then Return 0

    outEntry.title = EvalPbStringExpr(args(1))
    outEntry.partName = EvalPbStringExpr(args(2))
    outEntry.bodyText = EvalPbStringExpr(args(3))
    outEntry.pageNumber = ValInt(TrimTokenWs(args(4)))
    Return IIf(Len(outEntry.title) > 0, -1, 0)
End Function

Private Function CollectMsxManualTopics(entries() As MsxManualTopicEntry, ByRef entryCount As Integer, ByRef errMsg As String) As Integer
    errMsg = ""
    entryCount = 0

    Dim paths(1 To 2) As String
    paths(1) = MSX_MANUAL_DATA_PATH
    paths(2) = MSX_MANUAL_DATA_PATH_2P

    Dim pidx As Integer
    For pidx = 1 To 2
        Dim src As String
        If ReadWholeTextFile(paths(pidx), src) = 0 Then
            errMsg = "Nao foi possivel abrir base de topicos: " & paths(pidx)
            Return 0
        End If

        Dim p As Integer = 1
        Do
            p = InStr(p, src, "MSXManual_Add(")
            If p <= 0 Then Exit Do

            Dim callText As String
            If ExtractPbCallTextFromSource(src, p, callText) = 0 Then Exit Do

            Dim e As MsxManualTopicEntry
            If ParseMsxManualCall(callText, e) <> 0 Then
                entryCount += 1
                If entryCount = 1 Then
                    ReDim entries(1 To 1)
                Else
                    ReDim Preserve entries(1 To entryCount)
                End If
                entries(entryCount) = e
            End If

            p += Len("MSXManual_Add(")
        Loop
    Next pidx

    Return IIf(entryCount > 0, -1, 0)
End Function

Private Function FindMsxDictCallText(ByRef keyword As String, ByRef callText As String, ByRef errMsg As String) As Integer
    errMsg = ""
    callText = ""

    Dim paths(1 To 2) As String
    paths(1) = MSX_DICT_DATA_PATH
    paths(2) = MSX_DICT_DATA_PATH_2P

    Dim target As String = UCase(Trim(keyword))
    Dim findExpr1 As String = "MSXDict_Add(" & Chr(34) & target & Chr(34)
    Dim findExpr2 As String = "MSXDict_Add2Plus(" & Chr(34) & target & Chr(34)

    Dim pidx As Integer
    For pidx = 1 To 2
        Dim src As String
        If ReadWholeTextFile(paths(pidx), src) = 0 Then
            errMsg = "Nao foi possivel abrir base do dicionario: " & paths(pidx)
            Return 0
        End If

        Dim startPos1 As Integer = InStr(1, src, findExpr1)
        Dim startPos2 As Integer = InStr(1, src, findExpr2)
        Dim startPos As Integer = 0

        If startPos1 > 0 And startPos2 > 0 Then
            startPos = IIf(startPos1 < startPos2, startPos1, startPos2)
        ElseIf startPos1 > 0 Then
            startPos = startPos1
        ElseIf startPos2 > 0 Then
            startPos = startPos2
        End If

        If startPos > 0 Then
            If ExtractPbCallTextFromSource(src, startPos, callText) <> 0 Then Return -1
            errMsg = "Bloco incompleto no dicionario para: " & keyword
            Return 0
        End If
    Next pidx

    errMsg = "Comando nao encontrado no dicionario: " & keyword
    Return 0
End Function

Private Function FindMsxDictEntry(ByRef keyword As String, ByRef outEntry As MsxDictEntry, ByRef errMsg As String) As Integer
    errMsg = ""
    Dim callText As String
    If FindMsxDictCallText(keyword, callText, errMsg) = 0 Then Return 0

    If ParseMsxDictCall(callText, outEntry) = 0 Then
        errMsg = "Falha ao interpretar verbete: " & keyword
        Return 0
    End If
    Return -1
End Function

Private Function CollectMsxDictKeywords(items() As String, ByRef itemCount As Integer, ByRef errMsg As String) As Integer
    errMsg = ""
    itemCount = 0

    Dim paths(1 To 2) As String
    paths(1) = MSX_DICT_DATA_PATH
    paths(2) = MSX_DICT_DATA_PATH_2P

    Dim pidx As Integer
    For pidx = 1 To 2
        Dim src As String
        If ReadWholeTextFile(paths(pidx), src) = 0 Then
            errMsg = "Nao foi possivel abrir base do dicionario: " & paths(pidx)
            Return 0
        End If

        Dim p As Integer = 1
        Dim prefix1 As String = "MSXDict_Add(" & Chr(34)
        Dim prefix2 As String = "MSXDict_Add2Plus(" & Chr(34)
        Do
            Dim p1 As Integer = InStr(p, src, prefix1)
            Dim p2 As Integer = InStr(p, src, prefix2)
            Dim tokenPos As Integer = 0
            Dim tokenPrefix As String = ""

            If p1 > 0 And (p2 = 0 Or p1 < p2) Then
                tokenPos = p1
                tokenPrefix = prefix1
            ElseIf p2 > 0 Then
                tokenPos = p2
                tokenPrefix = prefix2
            End If

            If tokenPos <= 0 Then Exit Do

            Dim s1 As Integer = tokenPos + Len(tokenPrefix)
            Dim s2 As Integer = InStr(s1, src, Chr(34))
            If s2 <= s1 Then Exit Do

            Dim kw As String = UCase(Trim(Mid(src, s1, s2 - s1)))
            If Len(kw) > 0 Then
                Dim exists As Integer = 0
                Dim i As Integer
                For i = 1 To itemCount
                    If items(i) = kw Then
                        exists = -1
                        Exit For
                    End If
                Next i

                If exists = 0 Then
                    itemCount += 1
                    If itemCount = 1 Then
                        ReDim items(1 To 1)
                    Else
                        ReDim Preserve items(1 To itemCount)
                    End If
                    items(itemCount) = kw
                End If
            End If
            p = s2 + 1
        Loop
    Next pidx

    If itemCount > 1 Then
        Dim i As Integer
        Dim j As Integer
        For i = 1 To itemCount - 1
            For j = i + 1 To itemCount
                If items(j) < items(i) Then
                    Dim t As String = items(i)
                    items(i) = items(j)
                    items(j) = t
                End If
            Next j
        Next i
    End If

    Return IIf(itemCount > 0, -1, 0)
End Function

Private Function GetKeywordAtCursor(ByRef d As Document) As String
    If d.cursorY < 1 Or d.cursorY > d.lineCount Then Return ""
    Dim lineText As String = d.lines(d.cursorY)
    If Len(lineText) = 0 Then Return ""

    Dim p As Integer = d.cursorX
    If p < 1 Then p = 1
    If p > Len(lineText) Then p = Len(lineText)

    Dim ch As String = Mid(lineText, p, 1)
    If (IsWordChar(ch) = 0 And ch <> "$") And p > 1 Then
        p = p - 1
        ch = Mid(lineText, p, 1)
    End If

    If ch = "?" Then Return "PRINT"
    If IsWordChar(ch) = 0 And ch <> "$" Then Return ""

    Dim a As Integer = p
    While a > 1
        Dim c As String = Mid(lineText, a - 1, 1)
        If IsWordChar(c) = 0 And c <> "$" Then Exit While
        a -= 1
    Wend

    Dim b As Integer = p
    While b < Len(lineText)
        Dim c As String = Mid(lineText, b + 1, 1)
        If IsWordChar(c) = 0 And c <> "$" Then Exit While
        b += 1
    Wend

    Return UCase(Trim(Mid(lineText, a, b - a + 1)))
End Function

Private Sub AppendDocTextLines(ByRef d As Document, ByRef textIn As String)
    Dim src As String = StripCR(textIn)
    Dim p As Integer = 1
    While p <= Len(src)
        Dim br As Integer = InStr(p, src, Chr(10))
        Dim one As String
        If br = 0 Then
            one = Mid(src, p)
            p = Len(src) + 1
        Else
            one = Mid(src, p, br - p)
            p = br + 1
        End If

        If d.lineCount < MAX_LINES Then
            d.lineCount += 1
            d.lines(d.lineCount) = one
        End If
    Wend
End Sub

Private Sub AppendWrappedHelpText(ByRef d As Document, ByRef textIn As String, ByVal wrapW As Integer)
    Dim src As String = StripCR(textIn)
    Dim p As Integer = 1
    If wrapW < 16 Then wrapW = 16

    While p <= Len(src)
        Dim br As Integer = InStr(p, src, Chr(10))
        Dim one As String
        If br = 0 Then
            one = Mid(src, p)
            p = Len(src) + 1
        Else
            one = Mid(src, p, br - p)
            p = br + 1
        End If

        If Len(one) = 0 Then
            If d.lineCount < MAX_LINES Then
                d.lineCount += 1
                d.lines(d.lineCount) = ""
            End If
            Continue While
        End If

        Dim remain As String = one
        Do While Len(remain) > wrapW
            Dim cutPos As Integer = wrapW
            Dim j As Integer
            For j = wrapW To 1 Step -1
                If Mid(remain, j, 1) = " " Then
                    cutPos = j
                    Exit For
                End If
            Next j
            If cutPos <= 1 Then cutPos = wrapW

            If d.lineCount < MAX_LINES Then
                d.lineCount += 1
                d.lines(d.lineCount) = Left(remain, cutPos)
            End If

            If cutPos < Len(remain) And Mid(remain, cutPos, 1) = " " Then
                remain = LTrim(Mid(remain, cutPos + 1))
            Else
                remain = Mid(remain, cutPos + 1)
            End If
        Loop

        If d.lineCount < MAX_LINES Then
            d.lineCount += 1
            d.lines(d.lineCount) = remain
        End If
    Wend
End Sub

Private Function IsMsxTopicToken(ByRef tokenText As String) As Integer
    Dim t As String = UCase(Trim(tokenText))
    If Left(t, 7) = "@TOPIC:" Then Return -1
    Return 0
End Function

Private Function GetMsxTopicIdFromToken(ByRef tokenText As String) As Integer
    If IsMsxTopicToken(tokenText) = 0 Then Return 0
    Return ValInt(Mid(tokenText, 8))
End Function

Private Sub LoadMsxManualTopicIntoDocument(ByRef d As Document, ByVal topicId As Integer)
    Dim entries() As MsxManualTopicEntry
    Dim entryCount As Integer
    Dim errMsg As String

    If CollectMsxManualTopics(entries(), entryCount, errMsg) = 0 Then
        d.title = "HELP MSX TOPICOS"
        d.filePath = "msxdict:topic:" & Trim(Str(topicId))
        d.isHelp = -1
        d.helpTitle = "MSX Topics"
        d.helpWrapWidth = GetClientTextWidth(d)
        d.lineCount = 3
        d.lines(1) = "MSX TOPICOS"
        d.lines(2) = ""
        d.lines(3) = errMsg
        d.cursorX = 1
        d.cursorY = 1
        d.scrollX = 0
        d.scrollY = 0
        Exit Sub
    End If

    If topicId < 1 Or topicId > entryCount Then
        d.title = "HELP MSX TOPICOS"
        d.filePath = "msxdict:topic:" & Trim(Str(topicId))
        d.isHelp = -1
        d.helpTitle = "MSX Topics"
        d.helpWrapWidth = GetClientTextWidth(d)
        d.lineCount = 3
        d.lines(1) = "MSX TOPICOS"
        d.lines(2) = ""
        d.lines(3) = "Topico invalido: " & Trim(Str(topicId))
        d.cursorX = 1
        d.cursorY = 1
        d.scrollX = 0
        d.scrollY = 0
        Exit Sub
    End If

    Dim e As MsxManualTopicEntry = entries(topicId)
    Dim wrapW As Integer = GetClientTextWidth(d)
    If wrapW < 24 Then wrapW = 24

    d.title = "HELP " & e.title
    d.filePath = "msxdict:topic:" & Trim(Str(topicId))
    d.isHelp = -1
    d.helpTitle = "MSX Topics"
    d.helpWrapWidth = wrapW
    d.lineCount = 0

    d.lineCount += 1 : d.lines(d.lineCount) = "MSX TOPICOS"
    d.lineCount += 1 : d.lines(d.lineCount) = "Topico: " & e.title
    d.lineCount += 1 : d.lines(d.lineCount) = "Secao: " & e.partName
    d.lineCount += 1 : d.lines(d.lineCount) = "Pagina livro/manual: " & Trim(Str(e.pageNumber))
    d.lineCount += 1 : d.lines(d.lineCount) = ""

    AppendWrappedHelpText(d, e.bodyText, wrapW)

    d.cursorX = 1
    d.cursorY = 1
    d.scrollX = 0
    d.scrollY = 0
End Sub

Private Sub LoadMsxDictCommandIntoDocument(ByRef d As Document, ByRef keyword As String)
    Dim e As MsxDictEntry
    Dim errMsg As String
    Dim keyU As String = UCase(Trim(keyword))
    If keyU = "?" Then keyU = "PRINT"

    If FindMsxDictEntry(keyU, e, errMsg) = 0 Then
        d.title = "HELP MSX BASIC DICT"
        d.filePath = "msxdict:cmd:" & keyU
        d.isHelp = -1
        d.helpTitle = "MSX BASIC Dict"
        d.helpWrapWidth = GetClientTextWidth(d)
        d.lineCount = 3
        d.lines(1) = "MSX BASIC DICTIONARY"
        d.lines(2) = ""
        d.lines(3) = errMsg
        d.cursorX = 1
        d.cursorY = 1
        d.scrollX = 0
        d.scrollY = 0
        ClearMsxDictLineMap(activeDoc)
        Exit Sub
    End If

    d.title = "HELP " & e.title
    d.filePath = "msxdict:cmd:" & e.title
    d.isHelp = -1
    d.helpTitle = "MSX BASIC Dict"
    d.helpWrapWidth = GetClientTextWidth(d)
    d.lineCount = 0
    Dim wrapW As Integer = d.helpWrapWidth
    If wrapW < 24 Then wrapW = 24

    d.lineCount += 1 : d.lines(d.lineCount) = "MSX BASIC DICTIONARY"
    d.lineCount += 1 : d.lines(d.lineCount) = "Comando: " & e.title
    Dim flags As String = ""
    If e.isFunction <> 0 Then flags &= " (F)"
    If e.isAdvanced <> 0 Then flags &= " *"
    If Len(flags) > 0 Then d.lineCount += 1 : d.lines(d.lineCount) = "Flags:" & flags
    d.lineCount += 1 : d.lines(d.lineCount) = "Origem: " & e.origin
    d.lineCount += 1 : d.lines(d.lineCount) = "Pagina livro: " & Trim(Str(e.pageNumber))
    d.lineCount += 1 : d.lines(d.lineCount) = ""
    d.lineCount += 1 : d.lines(d.lineCount) = "Resumo"
    AppendWrappedHelpText(d, e.summary, wrapW)
    d.lineCount += 1 : d.lines(d.lineCount) = ""
    d.lineCount += 1 : d.lines(d.lineCount) = "Formato"
    AppendWrappedHelpText(d, e.formatText, wrapW)
    d.lineCount += 1 : d.lines(d.lineCount) = ""
    d.lineCount += 1 : d.lines(d.lineCount) = "Exemplo"
    AppendWrappedHelpText(d, e.formatExample, wrapW)
    d.lineCount += 1 : d.lines(d.lineCount) = ""
    d.lineCount += 1 : d.lines(d.lineCount) = "Funcao"
    AppendWrappedHelpText(d, e.functionText, wrapW)
    If Len(e.programExample) > 0 Then
        d.lineCount += 1 : d.lines(d.lineCount) = ""
        d.lineCount += 1 : d.lines(d.lineCount) = "Programa exemplo"
        AppendWrappedHelpText(d, e.programExample, wrapW)
    End If

    d.cursorX = 1
    d.cursorY = 1
    d.scrollX = 0
    d.scrollY = 0
    ClearMsxDictLineMap(activeDoc)
End Sub

Private Sub LoadMsxDictIndexIntoDocument(ByRef d As Document)
    Dim items() As String
    Dim itemCount As Integer
    Dim topics() As MsxManualTopicEntry
    Dim topicCount As Integer
    Dim errMsg As String

    d.title = "HELP MSX BASIC DICT"
    d.filePath = "msxdict:index"
    d.isHelp = -1
    d.helpTitle = "MSX BASIC Dict"
    d.helpWrapWidth = GetClientTextWidth(d)
    d.lineCount = 0
    ClearMsxDictLineMap(activeDoc)

    d.lineCount += 1 : d.lines(d.lineCount) = "MSX BASIC - AJUDA COMPLETA (MSX1 + MSX2+ + FM-MUSIC)"
    d.lineCount += 1 : d.lines(d.lineCount) = "Topicos de referencia e dicionario unificado de comandos."
    d.lineCount += 1 : d.lines(d.lineCount) = "Atalho: Shift+F1 abre o verbete da palavra sob o cursor no editor."
    d.lineCount += 1 : d.lines(d.lineCount) = ""
    d.lineCount += 1 : d.lines(d.lineCount) = "[PARTE I / III / IV + ACVS + FM-MUSIC - TOPICOS]"

    If CollectMsxManualTopics(topics(), topicCount, errMsg) = 0 Then
        d.lineCount += 1 : d.lines(d.lineCount) = errMsg
    Else
        Dim lastPart As String = ""
        Dim i As Integer
        For i = 1 To topicCount
            If topics(i).partName <> lastPart Then
                If Len(lastPart) > 0 Then
                    d.lineCount += 1 : d.lines(d.lineCount) = ""
                End If
                lastPart = topics(i).partName
                d.lineCount += 1 : d.lines(d.lineCount) = "{" & lastPart & "}"
            End If

            d.lineCount += 1
            d.lines(d.lineCount) = "  " & topics(i).title
            msxDictLineCommand(activeDoc, d.lineCount) = "@TOPIC:" & Trim(Str(i))
        Next i
    End If

    d.lineCount += 1 : d.lines(d.lineCount) = ""
    d.lineCount += 1 : d.lines(d.lineCount) = "[PARTE II - COMANDOS E FUNCOES]"

    If CollectMsxDictKeywords(items(), itemCount, errMsg) = 0 Then
        d.lineCount += 1 : d.lines(d.lineCount) = errMsg
        Exit Sub
    End If

    Dim i As Integer
    Dim currentLetter As String = ""
    For i = 1 To itemCount
        Dim kw As String = items(i)
        Dim firstLetter As String = Left(kw, 1)
        If firstLetter <> currentLetter Then
            If Len(currentLetter) > 0 Then
                d.lineCount += 1
                d.lines(d.lineCount) = ""
            End If
            currentLetter = firstLetter
            d.lineCount += 1
            d.lines(d.lineCount) = "[" & currentLetter & "]"
        End If
        d.lineCount += 1
        d.lines(d.lineCount) = "  " & kw
        msxDictLineCommand(activeDoc, d.lineCount) = kw
    Next i

    d.cursorX = 1
    d.cursorY = 1
    d.scrollX = 0
    d.scrollY = 0
End Sub

' ---------------------------------------------------------------------------
' Dicionarios de referencia (Red Book, manuais MSX, BIOS, openMSX, etc.) -
' mesmo padrao do MSX BASIC Dictionary acima (indice agrupado + topico
' individual), mas lendo os .pbi de ajuda\ que seguem a convencao
' Xxx_Begin() / Xxx_L("linha") / Xxx_Commit(Titulo,Grupo) / Xxx_AddAnchor
' (openMSX usa uma convencao mais simples, Xxx_Add(Titulo,Grupo,Corpo)).
' ---------------------------------------------------------------------------

Private Function RefDictTitle(ByRef dictId As String) As String
    Select Case LCase(dictId)
        Case "redbook" : Return "The MSX Red Book"
        Case "th2handbook" : Return "MSX2 Technical Handbook"
        Case "bioscalls" : Return "BIOS Chamadas"
        Case "hardware" : Return "BIOS Hardware"
        Case "biosdoc" : Return "BIOS Documentacao"
        Case "openmsx" : Return "openMSX"
        Case "msxmanuals" : Return "Manuais MSX"
    End Select
    Return "Referencia"
End Function

Private Function CollectRefTopicsBeginL(ByRef sourcePath As String, ByRef callPrefix As String, ByRef skipGroup As String, entries() As RefTopicEntry, anchorNames() As String, anchorTargets() As Integer, ByRef entryCount As Integer, ByRef anchorCount As Integer, ByRef errMsg As String) As Integer
    errMsg = ""
    entryCount = 0
    anchorCount = 0

    Dim src As String
    If ReadWholeTextFile(sourcePath, src) = 0 Then
        errMsg = "Nao foi possivel abrir base de referencia: " & sourcePath
        Return 0
    End If

    Dim beginTag As String = callPrefix & "_L("
    Dim commitTag As String = callPrefix & "_Commit("
    Dim anchorTag As String = callPrefix & "_AddAnchor("

    Dim p As Integer = 1
    Do
        Dim posCommit As Integer = InStr(p, src, commitTag)
        If posCommit <= 0 Then Exit Do

        Dim bodyText As String = ""
        Dim q As Integer = p
        Do
            Dim posL As Integer = InStr(q, src, beginTag)
            If posL <= 0 Or posL > posCommit Then Exit Do
            Dim lCallText As String
            If ExtractPbCallTextFromSource(src, posL, lCallText) = 0 Then Exit Do
            Dim lArgs() As String
            Dim lArgCount As Integer
            If SplitMsxDictArgs(lCallText, lArgs(), lArgCount) <> 0 And lArgCount >= 1 Then
                If Len(bodyText) > 0 Then bodyText &= Chr(13) & Chr(10)
                bodyText &= EvalPbStringExpr(lArgs(1))
            End If
            q = posL + Len(beginTag)
        Loop

        Dim commitCallText As String
        If ExtractPbCallTextFromSource(src, posCommit, commitCallText) = 0 Then Exit Do
        Dim cArgs() As String
        Dim cArgCount As Integer
        If SplitMsxDictArgs(commitCallText, cArgs(), cArgCount) <> 0 And cArgCount >= 2 Then
            Dim titleText As String = EvalPbStringExpr(cArgs(1))
            Dim groupText As String = EvalPbStringExpr(cArgs(2))
            If (Len(skipGroup) = 0 Or groupText <> skipGroup) And Len(titleText) > 0 Then
                entryCount += 1
                If entryCount = 1 Then
                    ReDim entries(1 To 1)
                Else
                    ReDim Preserve entries(1 To entryCount)
                End If
                entries(entryCount).title = titleText
                entries(entryCount).groupName = groupText
                entries(entryCount).bodyText = bodyText
            End If
        End If

        p = posCommit + Len(commitTag)
    Loop

    p = 1
    Do
        Dim posA As Integer = InStr(p, src, anchorTag)
        If posA <= 0 Then Exit Do
        Dim aCallText As String
        If ExtractPbCallTextFromSource(src, posA, aCallText) <> 0 Then
            Dim aArgs() As String
            Dim aArgCount As Integer
            If SplitMsxDictArgs(aCallText, aArgs(), aArgCount) <> 0 And aArgCount >= 2 Then
                anchorCount += 1
                If anchorCount = 1 Then
                    ReDim anchorNames(1 To 1)
                    ReDim anchorTargets(1 To 1)
                Else
                    ReDim Preserve anchorNames(1 To anchorCount)
                    ReDim Preserve anchorTargets(1 To anchorCount)
                End If
                anchorNames(anchorCount) = EvalPbStringExpr(aArgs(1))
                anchorTargets(anchorCount) = ValInt(TrimTokenWs(aArgs(2))) + 1
            End If
        End If
        p = posA + Len(anchorTag)
    Loop

    Return IIf(entryCount > 0, -1, 0)
End Function

Private Function CollectRefTopicsAddStyle(ByRef sourcePath As String, ByRef callPrefix As String, entries() As RefTopicEntry, ByRef entryCount As Integer, ByRef errMsg As String) As Integer
    errMsg = ""
    entryCount = 0

    Dim src As String
    If ReadWholeTextFile(sourcePath, src) = 0 Then
        errMsg = "Nao foi possivel abrir base de referencia: " & sourcePath
        Return 0
    End If

    Dim findExpr As String = callPrefix & "_Add("
    Dim p As Integer = 1
    Do
        p = InStr(p, src, findExpr)
        If p <= 0 Then Exit Do

        Dim callText As String
        If ExtractPbCallTextFromSource(src, p, callText) = 0 Then Exit Do

        Dim args() As String
        Dim argCount As Integer
        If SplitMsxDictArgs(callText, args(), argCount) <> 0 And argCount >= 3 Then
            entryCount += 1
            If entryCount = 1 Then
                ReDim entries(1 To 1)
            Else
                ReDim Preserve entries(1 To entryCount)
            End If
            entries(entryCount).title = EvalPbStringExpr(args(1))
            entries(entryCount).groupName = EvalPbStringExpr(args(2))
            entries(entryCount).bodyText = EvalPbStringExpr(args(3))
        End If

        p += Len(findExpr)
    Loop

    Return IIf(entryCount > 0, -1, 0)
End Function

Private Function CollectRefTopics(ByRef dictId As String, entries() As RefTopicEntry, anchorNames() As String, anchorTargets() As Integer, ByRef entryCount As Integer, ByRef anchorCount As Integer, ByRef errMsg As String) As Integer
    errMsg = ""
    entryCount = 0
    anchorCount = 0

    Select Case LCase(dictId)
        Case "redbook"
            Return CollectRefTopicsBeginL(REFDICT_REDBOOK_PATH, "RedBookHelp", "", entries(), anchorNames(), anchorTargets(), entryCount, anchorCount, errMsg)
        Case "th2handbook"
            Return CollectRefTopicsBeginL(REFDICT_TH2HANDBOOK_PATH, "Th2HandbookHelp", "", entries(), anchorNames(), anchorTargets(), entryCount, anchorCount, errMsg)
        Case "bioscalls"
            Return CollectRefTopicsBeginL(REFDICT_BIOSCALLS_PATH, "BiosCallsHelp", "", entries(), anchorNames(), anchorTargets(), entryCount, anchorCount, errMsg)
        Case "hardware"
            Return CollectRefTopicsBeginL(REFDICT_HARDWARE_PATH, "HardwareHelp", "", entries(), anchorNames(), anchorTargets(), entryCount, anchorCount, errMsg)
        Case "biosdoc"
            Return CollectRefTopicsBeginL(REFDICT_BIOSDOC_PATH, "BiosDocHelp", "", entries(), anchorNames(), anchorTargets(), entryCount, anchorCount, errMsg)
        Case "msxmanuals"
            Return CollectRefTopicsBeginL(REFDICT_MSXMANUALS_PATH, "ManualsHelp", REFDICT_MSXMANUALS_SKIP_GROUP, entries(), anchorNames(), anchorTargets(), entryCount, anchorCount, errMsg)
        Case "openmsx"
            Return CollectRefTopicsAddStyle(REFDICT_OPENMSX_PATH, "OMSXHelp", entries(), entryCount, errMsg)
    End Select

    errMsg = "Dicionario de referencia desconhecido: " & dictId
    Return 0
End Function

Private Function ResolveRefAnchor(anchorNames() As String, anchorTargets() As Integer, ByVal anchorCount As Integer, ByRef anchor As String) As Integer
    Dim i As Integer
    For i = 1 To anchorCount
        If anchorNames(i) = anchor Then Return anchorTargets(i)
    Next i
    Return 0
End Function

Private Function StripRefInlineMarkup(ByRef lineText As String, linkTexts() As String, linkAnchors() As String, ByRef linkCount As Integer) As String
    Dim outText As String = ""
    Dim i As Integer = 1
    Dim n As Integer = Len(lineText)

    While i <= n
        If Mid(lineText, i, 3) = "[[[" Then
            Dim sepPos As Integer = InStr(i + 3, lineText, "|||")
            Dim endPos As Integer = 0
            If sepPos > 0 Then endPos = InStr(sepPos + 3, lineText, "]]]")

            If sepPos > 0 And endPos > 0 Then
                Dim linkText As String = Mid(lineText, i + 3, sepPos - (i + 3))
                Dim anchorText As String = Mid(lineText, sepPos + 3, endPos - (sepPos + 3))

                If Left(anchorText, 4) = "img:" Then
                    outText &= "[Figura: " & UCase(Mid(anchorText, 5)) & "]"
                Else
                    outText &= linkText
                    Dim wasEmpty As Integer = IIf(linkCount = 0, -1, 0)
                    linkCount += 1
                    If wasEmpty <> 0 Then
                        ReDim linkTexts(1 To 1)
                        ReDim linkAnchors(1 To 1)
                    Else
                        ReDim Preserve linkTexts(1 To linkCount)
                        ReDim Preserve linkAnchors(1 To linkCount)
                    End If
                    linkTexts(linkCount) = linkText
                    linkAnchors(linkCount) = anchorText
                End If

                i = endPos + 3
                Continue While
            End If
        End If

        If Mid(lineText, i, 2) = "**" Then
            i += 2
            Continue While
        End If

        If Mid(lineText, i, 1) = Chr(96) Then
            i += 1
            Continue While
        End If

        outText &= Mid(lineText, i, 1)
        i += 1
    Wend

    Return outText
End Function

Private Sub AppendRefWrappedLine(ByRef d As Document, ByRef textLine As String, ByVal wrapW As Integer, ByVal fg As UByte, ByVal bg As UByte)
    Dim rest As String = textLine
    If wrapW < 8 Then wrapW = 8

    If Len(rest) = 0 Then
        If d.lineCount < MAX_LINES Then
            d.lineCount += 1
            d.lines(d.lineCount) = ""
            helpLineFg(activeDoc, d.lineCount) = fg
            helpLineBg(activeDoc, d.lineCount) = bg
        End If
        Exit Sub
    End If

    Do While Len(rest) > wrapW
        Dim cutPos As Integer = wrapW
        Dim i As Integer
        For i = wrapW To 1 Step -1
            If Mid(rest, i, 1) = " " Then
                cutPos = i
                Exit For
            End If
        Next i
        If cutPos < 1 Then cutPos = wrapW

        If d.lineCount < MAX_LINES Then
            d.lineCount += 1
            d.lines(d.lineCount) = RTrim(Left(rest, cutPos))
            helpLineFg(activeDoc, d.lineCount) = fg
            helpLineBg(activeDoc, d.lineCount) = bg
        End If

        If cutPos < Len(rest) And Mid(rest, cutPos, 1) = " " Then
            rest = LTrim(Mid(rest, cutPos + 1))
        Else
            rest = Mid(rest, cutPos + 1)
        End If
    Loop

    If d.lineCount < MAX_LINES Then
        d.lineCount += 1
        d.lines(d.lineCount) = rest
        helpLineFg(activeDoc, d.lineCount) = fg
        helpLineBg(activeDoc, d.lineCount) = bg
    End If
End Sub

Private Sub LoadRefDictIndexIntoDocument(ByRef d As Document, ByRef dictId As String)
    Dim entries() As RefTopicEntry
    Dim entryCount As Integer
    Dim anchorNames() As String
    Dim anchorTargets() As Integer
    Dim anchorCount As Integer
    Dim errMsg As String
    Dim titleText As String = RefDictTitle(dictId)

    d.title = "HELP " & titleText
    d.filePath = "refdict:" & LCase(dictId) & ":index"
    d.isHelp = -1
    d.helpTitle = titleText
    d.helpWrapWidth = GetClientTextWidth(d)
    d.lineCount = 0
    ClearMsxDictLineMap(activeDoc)

    If d.lineCount < MAX_LINES Then d.lineCount += 1 : d.lines(d.lineCount) = titleText
    If d.lineCount < MAX_LINES Then d.lineCount += 1 : d.lines(d.lineCount) = ""

    If CollectRefTopics(dictId, entries(), anchorNames(), anchorTargets(), entryCount, anchorCount, errMsg) = 0 Then
        If d.lineCount < MAX_LINES Then d.lineCount += 1 : d.lines(d.lineCount) = errMsg
    Else
        Dim lastGroup As String = Chr(1)
        Dim i As Integer
        For i = 1 To entryCount
            If entries(i).groupName <> lastGroup Then
                If lastGroup <> Chr(1) Then
                    If d.lineCount < MAX_LINES Then d.lineCount += 1 : d.lines(d.lineCount) = ""
                End If
                lastGroup = entries(i).groupName
                If Len(lastGroup) > 0 Then
                    If d.lineCount < MAX_LINES Then d.lineCount += 1 : d.lines(d.lineCount) = "{" & lastGroup & "}"
                End If
            End If

            If d.lineCount < MAX_LINES Then
                d.lineCount += 1
                d.lines(d.lineCount) = "  " & entries(i).title
                msxDictLineCommand(activeDoc, d.lineCount) = "RTOPIC:" & LCase(dictId) & ":" & Trim(Str(i))
                helpLineFg(activeDoc, d.lineCount) = 11
                helpLineBg(activeDoc, d.lineCount) = helpBgText
            End If
        Next i
    End If

    d.cursorX = 1
    d.cursorY = 1
    d.scrollX = 0
    d.scrollY = 0
End Sub

Private Sub LoadRefDictTopicIntoDocument(ByRef d As Document, ByRef dictId As String, ByVal topicIdx As Integer)
    Dim entries() As RefTopicEntry
    Dim entryCount As Integer
    Dim anchorNames() As String
    Dim anchorTargets() As Integer
    Dim anchorCount As Integer
    Dim errMsg As String
    Dim titleText As String = RefDictTitle(dictId)

    d.filePath = "refdict:" & LCase(dictId) & ":topic:" & Trim(Str(topicIdx))
    d.isHelp = -1
    d.helpTitle = titleText
    d.helpWrapWidth = GetClientTextWidth(d)
    d.lineCount = 0
    ClearMsxDictLineMap(activeDoc)

    Dim okRc As Integer = CollectRefTopics(dictId, entries(), anchorNames(), anchorTargets(), entryCount, anchorCount, errMsg)
    If okRc = 0 Or topicIdx < 1 Or topicIdx > entryCount Then
        d.title = "HELP " & titleText
        If d.lineCount < MAX_LINES Then d.lineCount += 1 : d.lines(d.lineCount) = titleText
        If d.lineCount < MAX_LINES Then d.lineCount += 1 : d.lines(d.lineCount) = ""
        If d.lineCount < MAX_LINES Then d.lineCount += 1 : d.lines(d.lineCount) = IIf(Len(errMsg) > 0, errMsg, "Topico invalido: " & Trim(Str(topicIdx)))
        d.cursorX = 1
        d.cursorY = 1
        d.scrollX = 0
        d.scrollY = 0
        Exit Sub
    End If

    Dim e As RefTopicEntry = entries(topicIdx)
    Dim wrapW As Integer = d.helpWrapWidth
    If wrapW < 24 Then wrapW = 24

    d.title = "HELP " & e.title

    If d.lineCount < MAX_LINES Then d.lineCount += 1 : d.lines(d.lineCount) = e.title : helpLineFg(activeDoc, d.lineCount) = helpFgH1 : helpLineBg(activeDoc, d.lineCount) = helpBgH1
    If Len(e.groupName) > 0 Then
        If d.lineCount < MAX_LINES Then d.lineCount += 1 : d.lines(d.lineCount) = e.groupName : helpLineFg(activeDoc, d.lineCount) = 8 : helpLineBg(activeDoc, d.lineCount) = helpBgText
    End If
    If d.lineCount < MAX_LINES Then d.lineCount += 1 : d.lines(d.lineCount) = ""

    Dim linkTexts() As String
    Dim linkAnchors() As String
    Dim linkCount As Integer = 0

    Dim src As String = StripCR(e.bodyText)
    Dim p As Integer = 1
    While p <= Len(src)
        Dim br As Integer = InStr(p, src, Chr(10))
        Dim lineText As String
        If br = 0 Then
            lineText = Mid(src, p)
            p = Len(src) + 1
        Else
            lineText = Mid(src, p, br - p)
            p = br + 1
        End If

        If Left(lineText, 3) = "@@@" Then
            AppendRefWrappedLine(d, "  " & Mid(lineText, 4), wrapW, helpFgCode, helpBgCode)
        ElseIf Left(lineText, 3) = "## " Then
            AppendRefWrappedLine(d, Trim(Mid(lineText, 4)), wrapW, helpFgH2, helpBgH2)
        Else
            Dim cleanLine As String = StripRefInlineMarkup(lineText, linkTexts(), linkAnchors(), linkCount)
            AppendRefWrappedLine(d, cleanLine, wrapW, helpFgText, helpBgText)
        End If
    Wend

    If linkCount > 0 Then
        AppendRefWrappedLine(d, "", wrapW, helpFgText, helpBgText)
        AppendRefWrappedLine(d, "Ver tambem:", wrapW, 13, helpBgText)

        Dim seen As String = "|"
        Dim k As Integer
        For k = 1 To linkCount
            Dim targetIdx As Integer = ResolveRefAnchor(anchorNames(), anchorTargets(), anchorCount, linkAnchors(k))
            If targetIdx >= 1 And targetIdx <= entryCount Then
                Dim dedupKey As String = "|" & Trim(Str(targetIdx)) & "|"
                If InStr(seen, dedupKey) = 0 Then
                    seen &= Trim(Str(targetIdx)) & "|"
                    If d.lineCount < MAX_LINES Then
                        d.lineCount += 1
                        d.lines(d.lineCount) = "  * " & entries(targetIdx).title
                        helpLineFg(activeDoc, d.lineCount) = 11
                        helpLineBg(activeDoc, d.lineCount) = helpBgText
                        msxDictLineCommand(activeDoc, d.lineCount) = "RTOPIC:" & LCase(dictId) & ":" & Trim(Str(targetIdx))
                    End If
                End If
            End If
        Next k
    End If

    d.cursorX = 1
    d.cursorY = 1
    d.scrollX = 0
    d.scrollY = 0
End Sub

Private Sub OpenRefDictHelp(ByRef dictId As String)
    Dim targetPath As String = "refdict:" & LCase(dictId) & ":index"
    Dim i As Integer

    For i = 1 To docCount
        If docs(i).isHelp <> 0 And LCase(docs(i).filePath) = targetPath Then
            BringDocumentToFront(i)
            forceFullRedraw = 1
            renderMode = RENDER_FULL
            Exit Sub
        End If
    Next i

    If activeDoc >= 1 And activeDoc <= docCount Then
        If docs(activeDoc).isHelp <> 0 Then
            LoadRefDictIndexIntoDocument(docs(activeDoc), dictId)
            forceFullRedraw = 1
            renderMode = RENDER_FULL
            Exit Sub
        End If
    End If

    If docCount >= MAX_DOCS Then Exit Sub

    docCount += 1
    activeDoc = docCount
    InitBlankDocument(docs(docCount), RefDictTitle(dictId))
    LayoutNewDocumentWindow(docCount)
    LoadRefDictIndexIntoDocument(docs(docCount), dictId)

    forceFullRedraw = 1
    renderMode = RENDER_FULL
End Sub

Private Sub OpenMsxDictHelpByKeyword(ByVal requestedKey As String)
    Dim targetKey As String = UCase(Trim(requestedKey))
    If targetKey = "?" Then targetKey = "PRINT"
    Dim targetPath As String = IIf(Len(targetKey) > 0, "msxdict:cmd:" & targetKey, "msxdict:index")

    Dim i As Integer
    For i = 1 To docCount
        If docs(i).isHelp <> 0 And LCase(docs(i).filePath) = LCase(targetPath) Then
            BringDocumentToFront(i)
            forceFullRedraw = 1
            renderMode = RENDER_FULL
            Exit Sub
        End If
    Next i

    ' Reusa a janela de help ativa (opcao 3), preservando o layout das demais janelas.
    If activeDoc >= 1 And activeDoc <= docCount Then
        If docs(activeDoc).isHelp <> 0 Then
            If Len(targetKey) > 0 Then
                LoadMsxDictCommandIntoDocument(docs(activeDoc), targetKey)
            Else
                LoadMsxDictIndexIntoDocument(docs(activeDoc))
            End If
            forceFullRedraw = 1
            renderMode = RENDER_FULL
            Exit Sub
        End If
    End If

    If docCount >= MAX_DOCS Then Exit Sub
    docCount += 1
    activeDoc = docCount

    InitBlankDocument(docs(docCount), "MSX BASIC DICT")
    LayoutNewDocumentWindow(docCount)

    If Len(targetKey) > 0 Then
        LoadMsxDictCommandIntoDocument(docs(docCount), targetKey)
    Else
        LoadMsxDictIndexIntoDocument(docs(docCount))
    End If

    forceFullRedraw = 1
    renderMode = RENDER_FULL
End Sub

Private Sub OpenMsxDictHelp()
    OpenMsxDictHelpByKeyword("")
End Sub

' Dispara a navegacao de uma linha clicavel (indice de ajuda) sob o cursor.
' Cobre dois esquemas: "JUMP:N" (generico - qualquer doc de ajuda markdown,
' rola ate a linha N, usado pelo indice de secoes gerado por
' BuildMarkdownHelpBuffer) e o indice especifico do MSX BASIC Dict
' (msxdict:index - abre o verbete/topico).
Private Function OpenMsxDictFromActiveIndexCursor() As Integer
    If activeDoc < 1 Or activeDoc > docCount Then Return 0
    Dim ByRef d As Document = docs(activeDoc)
    If d.cursorY < 1 Or d.cursorY > MAX_LINES Then Return 0

    Dim kw As String = msxDictLineCommand(activeDoc, d.cursorY)
    If Len(kw) = 0 Then Return 0

    If Left(kw, 5) = "JUMP:" Then
        Dim targetLine As Integer = ValInt(Mid(kw, 6))
        If targetLine < 1 Then targetLine = 1
        d.cursorY = Clamp(targetLine, 1, d.lineCount)
        d.cursorX = 1
        d.scrollY = Clamp(targetLine - 1, 0, GetMaxScrollY(d))
        ClampScroll(d)
        Return -1
    End If

    If Left(kw, 7) = "RTOPIC:" Then
        Dim rest As String = Mid(kw, 8)
        Dim sepPos As Integer = InStr(rest, ":")
        If sepPos <= 0 Then Return 0
        Dim dId As String = Left(rest, sepPos - 1)
        Dim tIdx As Integer = ValInt(Mid(rest, sepPos + 1))
        LoadRefDictTopicIntoDocument(d, dId, tIdx)
        Return -1
    End If

    If Left(LCase(d.filePath), 13) <> "msxdict:index" Then Return 0

    If IsMsxTopicToken(kw) <> 0 Then
        Dim topicId As Integer = GetMsxTopicIdFromToken(kw)
        If topicId <= 0 Then Return 0
        LoadMsxManualTopicIntoDocument(d, topicId)
    Else
        OpenMsxDictHelpByKeyword(kw)
    End If
    Return -1
End Function

Private Sub PaintRange(colors() As UByte, ByVal startPos As Integer, ByVal endPos As Integer, ByVal colorCode As UByte, ByVal maxLen As Integer)
    Dim i As Integer
    If startPos < 1 Then startPos = 1
    If endPos > maxLen Then endPos = maxLen
    If startPos > endPos Then Exit Sub
    For i = startPos To endPos
        colors(i) = colorCode
    Next i
End Sub

Private Sub DrawSyntaxLine(ByVal docIndex As Integer, ByVal lineIndex As Integer, ByVal rowY As Integer)
    Dim ByRef d As Document = docs(docIndex)
    Dim clientW As Integer = GetClientTextWidth(d)
    If clientW > MAX_SYNTAX_W Then clientW = MAX_SYNTAX_W

    Dim lineRaw As String
    If lineIndex <= d.lineCount Then
        lineRaw = Mid(d.lines(lineIndex), d.scrollX + 1, clientW)
    Else
        lineRaw = ""
    End If

    Dim padded As String = Left(lineRaw & Space(clientW), clientW)
    Dim colors(1 To MAX_SYNTAX_W) As UByte
    Dim i As Integer
    For i = 1 To clientW
        colors(i) = COL_DEFAULT
    Next i

    Dim n As Integer = Len(lineRaw)
    i = 1
    While i <= n
        Dim ch As String = Mid(lineRaw, i, 1)
        Dim ch2 As String
        If i < n Then ch2 = Mid(lineRaw, i + 1, 1) Else ch2 = ""

        If ch = "'" Then
            PaintRange(colors(), i, n, COL_COMMENT, clientW)
            Exit While
        End If

        If ch = "#" And ch2 = "#" Then
            PaintRange(colors(), i, n, COL_COMMENT, clientW)
            Exit While
        End If

        If ch = Chr(34) Then
            Dim j As Integer = i + 1
            While j <= n
                If Mid(lineRaw, j, 1) = Chr(34) Then
                    If j < n And Mid(lineRaw, j + 1, 1) = Chr(34) Then
                        j += 2
                        Continue While
                    End If
                    Exit While
                End If
                j += 1
            Wend
            If j > n Then j = n
            PaintRange(colors(), i, j, COL_STRING, clientW)
            i = j + 1
            Continue While
        End If

        If ch = "{" Then
            Dim k As Integer = InStr(i + 1, lineRaw, "}")
            If k > 0 Then
                PaintRange(colors(), i, k, COL_LABEL, clientW)
                i = k + 1
                Continue While
            End If
        End If

        If ch = "[" Then
            Dim k As Integer = InStr(i + 1, lineRaw, "]")
            If k > 0 Then
                PaintRange(colors(), i, k, COL_DEFINE, clientW)
                i = k + 1
                Continue While
            End If
        End If

        If ch = "#" Then
            Dim j As Integer = i + 1
            While j <= n And IsWordChar(Mid(lineRaw, j, 1)) <> 0
                j += 1
            Wend
            If j > i + 1 Then
                PaintRange(colors(), i, j - 1, COL_DEFINE, clientW)
                i = j
                Continue While
            End If
        End If

        If ch = "." And i < n And IsWordStart(ch2) <> 0 Then
            Dim j As Integer = i + 2
            While j <= n And IsWordChar(Mid(lineRaw, j, 1)) <> 0
                j += 1
            Wend
            PaintRange(colors(), i, j - 1, COL_CLASSIC_FUNC, clientW)
            i = j
            Continue While
        End If

        If ch = "&" And i < n Then
            Dim baseTag As String = UCase(ch2)
            Dim j As Integer = i + 2
            If baseTag = "H" Then
                While j <= n And IsHexDigit(Mid(lineRaw, j, 1)) <> 0
                    j += 1
                Wend
                PaintRange(colors(), i, j - 1, COL_NUMBER, clientW)
                i = j
                Continue While
            ElseIf baseTag = "O" Then
                While j <= n And IsOctDigit(Mid(lineRaw, j, 1)) <> 0
                    j += 1
                Wend
                PaintRange(colors(), i, j - 1, COL_NUMBER, clientW)
                i = j
                Continue While
            ElseIf baseTag = "B" Then
                While j <= n And IsBinDigit(Mid(lineRaw, j, 1)) <> 0
                    j += 1
                Wend
                PaintRange(colors(), i, j - 1, COL_NUMBER, clientW)
                i = j
                Continue While
            End If
        End If

        If IsDecDigit(ch) <> 0 Or (ch = "." And IsDecDigit(ch2) <> 0) Then
            Dim j As Integer = i
            If ch = "." Then j += 1
            While j <= n And IsDecDigit(Mid(lineRaw, j, 1)) <> 0
                j += 1
            Wend
            If j <= n And Mid(lineRaw, j, 1) = "." Then
                j += 1
                While j <= n And IsDecDigit(Mid(lineRaw, j, 1)) <> 0
                    j += 1
                Wend
            End If
            If j <= n And (UCase(Mid(lineRaw, j, 1)) = "E" Or UCase(Mid(lineRaw, j, 1)) = "D") Then
                Dim k As Integer = j + 1
                If k <= n And (Mid(lineRaw, k, 1) = "+" Or Mid(lineRaw, k, 1) = "-") Then k += 1
                While k <= n And IsDecDigit(Mid(lineRaw, k, 1)) <> 0
                    k += 1
                Wend
                j = k
            End If
            If j <= n Then
                Dim t As String = Mid(lineRaw, j, 1)
                If t = "%" Or t = "!" Or t = "#" Then j += 1
            End If
            PaintRange(colors(), i, j - 1, COL_NUMBER, clientW)
            i = j
            Continue While
        End If

        If IsWordStart(ch) <> 0 Then
            Dim j As Integer = i + 1
            While j <= n And IsWordChar(Mid(lineRaw, j, 1)) <> 0
                j += 1
            Wend
            If j <= n And InStr("$%!#", Mid(lineRaw, j, 1)) > 0 Then j += 1

            Dim token As String = Mid(lineRaw, i, j - i)
            Dim tokenUpper As String = UCase(token)

            If j <= n And Mid(lineRaw, j, 1) = "{" Then
                PaintRange(colors(), i, j, COL_LABEL, clientW)
                i = j + 1
                Continue While
            End If

            If tokenUpper = "REM" Then
                PaintRange(colors(), i, n, COL_COMMENT, clientW)
                Exit While
            ElseIf InPipeList(tokenUpper, LIST_DIGNIFIED_CMDS) <> 0 Then
                PaintRange(colors(), i, j - 1, COL_DIGNIFIED_CMD, clientW)
            ElseIf InPipeList(tokenUpper, LIST_CLASSIC_JUMPS) <> 0 Then
                PaintRange(colors(), i, j - 1, COL_CLASSIC_CMD, clientW)
            ElseIf InPipeList(tokenUpper, LIST_CLASSIC_CMDS) <> 0 Then
                PaintRange(colors(), i, j - 1, COL_CLASSIC_CMD, clientW)
            ElseIf InPipeList(tokenUpper, LIST_CLASSIC_FUNCS) <> 0 Or Left(tokenUpper, 3) = "USR" Or Left(tokenUpper, 6) = "DEFUSR" Then
                PaintRange(colors(), i, j - 1, COL_CLASSIC_FUNC, clientW)
                If j <= n And Mid(lineRaw, j, 1) = "(" And (tokenUpper = "SPC" Or tokenUpper = "TAB" Or tokenUpper = "LOC") Then
                    PaintRange(colors(), j, j, COL_CLASSIC_FUNC, clientW)
                End If
            ElseIf InPipeList(tokenUpper, LIST_OPERATORS) <> 0 Then
                PaintRange(colors(), i, j - 1, COL_OPERATOR, clientW)
            ElseIf InPipeList(tokenUpper, LIST_LITERALS) <> 0 Then
                PaintRange(colors(), i, j - 1, COL_LITERAL, clientW)
            Else
                PaintRange(colors(), i, j - 1, COL_VARIABLE, clientW)
            End If

            i = j
            Continue While
        End If

        Dim twoOps As String = ch & ch2
        If twoOps = "++" Or twoOps = "--" Or twoOps = "+=" Or twoOps = "-=" Or twoOps = "*=" Or twoOps = "/=" Or twoOps = "^=" Or twoOps = "<>" Or twoOps = "<=" Or twoOps = ">=" Then
            PaintRange(colors(), i, i + 1, COL_OPERATOR, clientW)
            i += 2
            Continue While
        End If

        If ch = "?" Then
            PaintRange(colors(), i, i, COL_CLASSIC_CMD, clientW)
            i += 1
            Continue While
        End If

        If InStr("+-*/^=<>:,;()[]{}@~_\\", ch) > 0 Then
            PaintRange(colors(), i, i, COL_SYMBOL, clientW)
        End If

        i += 1
    Wend

    For i = 1 To clientW
        ConsoleSetCell(d.winX + i, rowY, Asc(Mid(padded, i, 1)), colors(i), 0)
    Next i
End Sub

Private Sub DrawHelpLine(ByVal docIndex As Integer, ByVal lineIndex As Integer, ByVal rowY As Integer)
    Dim ByRef d As Document = docs(docIndex)
    Dim clientW As Integer = GetClientTextWidth(d)
    If clientW > MAX_SYNTAX_W Then clientW = MAX_SYNTAX_W

    Dim lineRaw As String
    If lineIndex <= d.lineCount Then
        lineRaw = Mid(d.lines(lineIndex), d.scrollX + 1, clientW)
    Else
        lineRaw = ""
    End If

    Dim padded As String = Left(lineRaw & Space(clientW), clientW)
    Dim i As Integer
    Dim fg As UByte = 15
    Dim bg As UByte = 0
    If IsMsxDictDoc(d) <> 0 Then
        If Left(LCase(d.filePath), 13) = "msxdict:index" Then
            If lineIndex >= 1 And lineIndex <= MAX_LINES Then
                If Len(msxDictLineCommand(docIndex, lineIndex)) > 0 Then fg = 11
            End If
        End If
    ElseIf lineIndex >= 1 And lineIndex <= MAX_LINES Then
        fg = helpLineFg(docIndex, lineIndex)
        bg = helpLineBg(docIndex, lineIndex)
    End If
    For i = 1 To clientW
        ConsoleSetCell(d.winX + i, rowY, Asc(Mid(padded, i, 1)), fg, bg)
    Next i
End Sub

Private Function GetClientTextWidth(ByRef d As Document) As Integer
    Dim w As Integer = d.winW - 3
    If w < 1 Then w = 1
    Return w
End Function

Private Function GetClientTextHeight(ByRef d As Document) As Integer
    Dim h As Integer = d.winH - 3
    If d.isMamuteTerm <> 0 Then h -= 1
    If d.isMamuteEdit <> 0 Then h -= 2
    If h < 1 Then h = 1
    Return h
End Function

Private Function GetMaxLineLen(ByRef d As Document) As Integer
    Dim i As Integer
    Dim best As Integer = 0
    For i = 1 To d.lineCount
        Dim ll As Integer = Len(d.lines(i))
        If ll > best Then best = ll
    Next i
    Return best
End Function

Private Function GetMaxScrollX(ByRef d As Document) As Integer
    If d.isHelp <> 0 Then Return 0
    Dim maxScroll As Integer = GetMaxLineLen(d) - GetClientTextWidth(d)
    If maxScroll < 0 Then maxScroll = 0
    Return maxScroll
End Function

Private Function GetMaxScrollY(ByRef d As Document) As Integer
    Dim maxScroll As Integer = d.lineCount - GetClientTextHeight(d)
    If maxScroll < 0 Then maxScroll = 0
    Return maxScroll
End Function

Private Sub ComputeThumb(ByVal contentTotal As Integer, ByVal viewSize As Integer, ByVal scrollPos As Integer, ByVal trackLen As Integer, ByRef thumbStart As Integer, ByRef thumbLen As Integer, ByRef maxScroll As Integer)
    If trackLen <= 0 Then
        thumbStart = 0
        thumbLen = 0
        maxScroll = 0
        Exit Sub
    End If

    If contentTotal < 1 Then contentTotal = 1
    If viewSize < 1 Then viewSize = 1
    If contentTotal < viewSize Then contentTotal = viewSize

    maxScroll = contentTotal - viewSize
    If maxScroll < 0 Then maxScroll = 0

    If maxScroll = 0 Then
        thumbStart = 0
        thumbLen = trackLen
        Exit Sub
    End If

    thumbLen = (viewSize * trackLen) \ contentTotal
    If thumbLen < 1 Then thumbLen = 1
    If thumbLen > trackLen Then thumbLen = trackLen

    Dim freeTrack As Integer = trackLen - thumbLen
    If freeTrack <= 0 Then
        thumbStart = 0
    Else
        scrollPos = Clamp(scrollPos, 0, maxScroll)
        thumbStart = (scrollPos * freeTrack) \ maxScroll
    End If
End Sub

Private Sub ClampScroll(ByRef d As Document)
    d.scrollX = Clamp(d.scrollX, 0, GetMaxScrollX(d))
    d.scrollY = Clamp(d.scrollY, 0, GetMaxScrollY(d))
End Sub

Private Sub SetScrollFromVBar(ByRef d As Document, ByVal mouseY As Integer)
    Dim trackTop As Integer = d.winY + 1
    Dim trackLen As Integer = d.winH - 3
    Dim viewSize As Integer = GetClientTextHeight(d)
    Dim contentTotal As Integer = d.lineCount
    Dim thumbStart As Integer
    Dim thumbLen As Integer
    Dim maxScroll As Integer

    If trackLen <= 0 Then Exit Sub
    ComputeThumb(contentTotal, viewSize, d.scrollY, trackLen, thumbStart, thumbLen, maxScroll)

    Dim rel As Integer = Clamp(mouseY, trackTop, trackTop + trackLen - 1) - trackTop
    If maxScroll <= 0 Then
        d.scrollY = 0
    Else
        Dim freeTrack As Integer = trackLen - thumbLen
        If freeTrack <= 0 Then
            d.scrollY = 0
        Else
            Dim targetStart As Integer = rel - (thumbLen \ 2)
            targetStart = Clamp(targetStart, 0, freeTrack)
            d.scrollY = (targetStart * maxScroll) \ freeTrack
        End If
    End If
    ClampScroll(d)
End Sub

Private Sub SetScrollFromHBar(ByRef d As Document, ByVal mouseX As Integer)
    Dim trackLeft As Integer = d.winX + 1
    Dim trackLen As Integer = d.winW - 3
    Dim viewSize As Integer = GetClientTextWidth(d)
    Dim contentTotal As Integer = GetMaxLineLen(d)
    Dim thumbStart As Integer
    Dim thumbLen As Integer
    Dim maxScroll As Integer

    If trackLen <= 0 Then Exit Sub
    ComputeThumb(contentTotal, viewSize, d.scrollX, trackLen, thumbStart, thumbLen, maxScroll)

    Dim rel As Integer = Clamp(mouseX, trackLeft, trackLeft + trackLen - 1) - trackLeft
    If maxScroll <= 0 Then
        d.scrollX = 0
    Else
        Dim freeTrack As Integer = trackLen - thumbLen
        If freeTrack <= 0 Then
            d.scrollX = 0
        Else
            Dim targetStart As Integer = rel - (thumbLen \ 2)
            targetStart = Clamp(targetStart, 0, freeTrack)
            d.scrollX = (targetStart * maxScroll) \ freeTrack
        End If
    End If
    ClampScroll(d)
End Sub

Private Sub DrawDesktop()
    Dim y As Integer
    Dim lineText As String
    Dim tile As String = Chr(177)

    For y = 2 To uiH - 1
        lineText = String(uiW, tile)
        ' Trama interna do proprio caractere (estilo DOS), sem alternancia por celula.
        ConsoleWriteText(1, y, lineText, 9, 1, uiW)
    Next y
End Sub

Private Function PointInRect(ByVal px As Integer, ByVal py As Integer, ByVal x As Integer, ByVal y As Integer, ByVal w As Integer, ByVal h As Integer) As Integer
    If px < x Or px > x + w - 1 Then Return 0
    If py < y Or py > y + h - 1 Then Return 0
    Return -1
End Function

Private Function FindTopWindowAt(ByVal px As Integer, ByVal py As Integer) As Integer
    Dim i As Integer
    For i = docCount To 1 Step -1
        If PointInRect(px, py, docs(i).winX, docs(i).winY, docs(i).winW, docs(i).winH) <> 0 Then
            Return i
        End If
    Next i
    Return 0
End Function

Private Sub ClampWindowToDesktop(ByRef d As Document)
    Dim minX As Integer = 1
    Dim minY As Integer = 2
    Dim maxX As Integer = uiW - d.winW + 1
    Dim maxY As Integer = uiH - d.winH

    If maxX < minX Then maxX = minX
    If maxY < minY Then maxY = minY

    d.winX = Clamp(d.winX, minX, maxX)
    d.winY = Clamp(d.winY, minY, maxY)
End Sub

Private Sub ClampWindowSize(ByRef d As Document)
    Dim minW As Integer = 20
    Dim minH As Integer = 8
    Dim maxW As Integer = uiW
    Dim maxH As Integer = uiH - 1

    d.winW = Clamp(d.winW, minW, maxW)
    d.winH = Clamp(d.winH, minH, maxH)
    ClampWindowToDesktop(d)
End Sub

Private Sub EnsureCursorVisible(ByRef d As Document)
    Dim clientW As Integer = GetClientTextWidth(d)
    Dim clientH As Integer = GetClientTextHeight(d)

    If d.cursorX <= d.scrollX Then d.scrollX = d.cursorX - 1
    If d.cursorX > d.scrollX + clientW Then d.scrollX = d.cursorX - clientW

    If d.cursorY <= d.scrollY Then d.scrollY = d.cursorY - 1
    If d.cursorY > d.scrollY + clientH Then d.scrollY = d.cursorY - clientH

    ClampScroll(d)
End Sub

Private Sub ReflowWindows()
    Dim i As Integer
    For i = 1 To docCount
        docs(i).winX = 3 + ((i - 1) Mod 5) * 2
        docs(i).winY = 3 + ((i - 1) Mod 5) * 1
        docs(i).winW = uiW - 6
        docs(i).winH = uiH - 7
        If docs(i).winW < 20 Then docs(i).winW = 20
        If docs(i).winH < 8 Then docs(i).winH = 8
    Next i
End Sub

Private Sub LayoutNewDocumentWindow(ByVal docIndex As Integer)
    If docIndex < 1 Or docIndex > docCount Then Exit Sub

    docs(docIndex).winX = 3 + ((docIndex - 1) Mod 5) * 2
    docs(docIndex).winY = 3 + ((docIndex - 1) Mod 5) * 1
    docs(docIndex).winW = uiW - 6
    docs(docIndex).winH = uiH - 7

    If docs(docIndex).winW < 20 Then docs(docIndex).winW = 20
    If docs(docIndex).winH < 8 Then docs(docIndex).winH = 8
End Sub

Private Sub BringDocumentToFront(ByVal docIndex As Integer)
    If docIndex < 1 Or docIndex > docCount Then Exit Sub
    If docIndex = docCount Then
        activeDoc = docCount
        Exit Sub
    End If

    Dim temp As Document = docs(docIndex)
    Dim tempMap(1 To MAX_LINES) As String
    Dim tempInputBuf As String = mamuteInputBuf(docIndex)
    Dim tempInputCursor As Integer = mamuteInputCursor(docIndex)
    Dim tempXWalking As Integer = MamuteXWalking(docIndex)
    Dim tempXWalkIdx As Integer = MamuteXWalkIdx(docIndex)
    Dim tempMEditActive As Integer = mamuteMEditActive(docIndex)
    Dim tempMEditBaseAddr As Integer = mamuteMEditBaseAddr(docIndex)
    Dim tempMEditCursorRow As Integer = mamuteMEditCursorRow(docIndex)
    Dim tempMEditCursorCol As Integer = mamuteMEditCursorCol(docIndex)
    Dim tempMEditNibbleStage As Integer = mamuteMEditNibbleStage(docIndex)
    Dim tempMEditPendingHigh As Integer = mamuteMEditPendingHigh(docIndex)
    Dim tempEditTopIndex As Integer = mamuteEditTopIndex(docIndex)
    Dim tempEditCursorIndex As Integer = mamuteEditCursorIndex(docIndex)
    Dim tempEditPendingScroll As Integer = mamuteEditPendingScroll(docIndex)
    Dim tempEditFilterMode As Integer = mamuteEditFilterMode(docIndex)
    Dim tempEditListingMode As Integer = mamuteEditListingMode(docIndex)
    Dim tempEditStatusText As String = mamuteEditStatusText(docIndex)
    Dim i As Integer
    Dim j As Integer

    For j = 1 To MAX_LINES
        tempMap(j) = msxDictLineCommand(docIndex, j)
    Next j

    For i = docIndex To docCount - 1
        docs(i) = docs(i + 1)
        mamuteInputBuf(i) = mamuteInputBuf(i + 1)
        mamuteInputCursor(i) = mamuteInputCursor(i + 1)
        MamuteXWalking(i) = MamuteXWalking(i + 1)
        MamuteXWalkIdx(i) = MamuteXWalkIdx(i + 1)
        mamuteMEditActive(i) = mamuteMEditActive(i + 1)
        mamuteMEditBaseAddr(i) = mamuteMEditBaseAddr(i + 1)
        mamuteMEditCursorRow(i) = mamuteMEditCursorRow(i + 1)
        mamuteMEditCursorCol(i) = mamuteMEditCursorCol(i + 1)
        mamuteMEditNibbleStage(i) = mamuteMEditNibbleStage(i + 1)
        mamuteMEditPendingHigh(i) = mamuteMEditPendingHigh(i + 1)
        mamuteEditTopIndex(i) = mamuteEditTopIndex(i + 1)
        mamuteEditCursorIndex(i) = mamuteEditCursorIndex(i + 1)
        mamuteEditPendingScroll(i) = mamuteEditPendingScroll(i + 1)
        mamuteEditFilterMode(i) = mamuteEditFilterMode(i + 1)
        mamuteEditListingMode(i) = mamuteEditListingMode(i + 1)
        mamuteEditStatusText(i) = mamuteEditStatusText(i + 1)
        For j = 1 To MAX_LINES
            msxDictLineCommand(i, j) = msxDictLineCommand(i + 1, j)
        Next j
    Next i

    docs(docCount) = temp
    mamuteInputBuf(docCount) = tempInputBuf
    mamuteInputCursor(docCount) = tempInputCursor
    MamuteXWalking(docCount) = tempXWalking
    MamuteXWalkIdx(docCount) = tempXWalkIdx
    mamuteMEditActive(docCount) = tempMEditActive
    mamuteMEditBaseAddr(docCount) = tempMEditBaseAddr
    mamuteMEditCursorRow(docCount) = tempMEditCursorRow
    mamuteMEditCursorCol(docCount) = tempMEditCursorCol
    mamuteMEditNibbleStage(docCount) = tempMEditNibbleStage
    mamuteMEditPendingHigh(docCount) = tempMEditPendingHigh
    mamuteEditTopIndex(docCount) = tempEditTopIndex
    mamuteEditCursorIndex(docCount) = tempEditCursorIndex
    mamuteEditPendingScroll(docCount) = tempEditPendingScroll
    mamuteEditFilterMode(docCount) = tempEditFilterMode
    mamuteEditListingMode(docCount) = tempEditListingMode
    mamuteEditStatusText(docCount) = tempEditStatusText
    For j = 1 To MAX_LINES
        msxDictLineCommand(docCount, j) = tempMap(j)
    Next j
    activeDoc = docCount
End Sub

Private Sub CloseDocument(ByVal docIndex As Integer)
    If docIndex < 1 Or docIndex > docCount Then Exit Sub

    Dim i As Integer
    Dim j As Integer
    For i = docIndex To docCount - 1
        docs(i) = docs(i + 1)
        mamuteInputBuf(i) = mamuteInputBuf(i + 1)
        mamuteInputCursor(i) = mamuteInputCursor(i + 1)
        MamuteXWalking(i) = MamuteXWalking(i + 1)
        MamuteXWalkIdx(i) = MamuteXWalkIdx(i + 1)
        mamuteMEditActive(i) = mamuteMEditActive(i + 1)
        mamuteMEditBaseAddr(i) = mamuteMEditBaseAddr(i + 1)
        mamuteMEditCursorRow(i) = mamuteMEditCursorRow(i + 1)
        mamuteMEditCursorCol(i) = mamuteMEditCursorCol(i + 1)
        mamuteMEditNibbleStage(i) = mamuteMEditNibbleStage(i + 1)
        mamuteMEditPendingHigh(i) = mamuteMEditPendingHigh(i + 1)
        mamuteEditTopIndex(i) = mamuteEditTopIndex(i + 1)
        mamuteEditCursorIndex(i) = mamuteEditCursorIndex(i + 1)
        mamuteEditPendingScroll(i) = mamuteEditPendingScroll(i + 1)
        mamuteEditFilterMode(i) = mamuteEditFilterMode(i + 1)
        mamuteEditListingMode(i) = mamuteEditListingMode(i + 1)
        mamuteEditStatusText(i) = mamuteEditStatusText(i + 1)
        For j = 1 To MAX_LINES
            msxDictLineCommand(i, j) = msxDictLineCommand(i + 1, j)
        Next j
    Next i

    mamuteInputBuf(docCount) = ""
    mamuteInputCursor(docCount) = 0
    MamuteXWalking(docCount) = 0
    MamuteXWalkIdx(docCount) = 0
    mamuteMEditActive(docCount) = 0
    mamuteMEditBaseAddr(docCount) = 0
    mamuteMEditCursorRow(docCount) = 0
    mamuteMEditCursorCol(docCount) = 0
    mamuteMEditNibbleStage(docCount) = 0
    mamuteMEditPendingHigh(docCount) = 0
    mamuteEditTopIndex(docCount) = 0
    mamuteEditCursorIndex(docCount) = 0
    mamuteEditPendingScroll(docCount) = 0
    mamuteEditFilterMode(docCount) = 0
    mamuteEditListingMode(docCount) = 0
    mamuteEditStatusText(docCount) = ""
    For j = 1 To MAX_LINES
        msxDictLineCommand(docCount, j) = ""
    Next j

    docCount -= 1

    If docCount <= 0 Then
        docCount = 0
        EditorOpenFromPath("msx00.dmx")
    Else
        activeDoc = docCount
    End If
End Sub

Private Sub ToggleMaximizeActiveWindow()
    If activeDoc < 1 Or activeDoc > docCount Then Exit Sub
    Dim ByRef d As Document = docs(activeDoc)

    If d.isMaximized = 0 Then
        d.normalX = d.winX
        d.normalY = d.winY
        d.normalW = d.winW
        d.normalH = d.winH

        d.winX = 1
        d.winY = 2
        d.winW = uiW
        d.winH = uiH - 2
        d.isMaximized = -1
    Else
        d.winX = d.normalX
        d.winY = d.normalY
        d.winW = d.normalW
        d.winH = d.normalH
        d.isMaximized = 0
        ClampWindowSize(d)
    End If
End Sub

Private Sub PlaceActiveCursor()
    Dim ByRef d As Document = docs(activeDoc)

    If d.isMamuteTerm <> 0 Then
        Dim clientW2 As Integer = GetClientTextWidth(d)

        If mamuteMEditActive(activeDoc) <> 0 Then
            Dim gridRow As Integer = mamuteMEditCursorRow(activeDoc)
            Dim gridCol As Integer = mamuteMEditCursorCol(activeDoc)
            Dim hexStartCol As Integer = 7 + gridCol * 3
            If mamuteMEditNibbleStage(activeDoc) <> 0 Then hexStartCol += 1
            If hexStartCol >= 1 And hexStartCol <= clientW2 Then
                ConsoleSetCursor(d.winX + hexStartCol, d.winY + 1 + gridRow, 1)
            End If
            Exit Sub
        End If

        Dim inputRow As Integer = d.winY + 1 + GetClientTextHeight(d)
        Dim cx2 As Integer = Len(MamuteCurrentPromptText(activeDoc)) + mamuteInputCursor(activeDoc) + 1
        If cx2 >= 1 And cx2 <= clientW2 Then
            ConsoleSetCursor(d.winX + cx2, inputRow, 1)
        End If
        Exit Sub
    End If

    If d.isMamuteEdit <> 0 Then
        Dim clientW3 As Integer = GetClientTextWidth(d)
        Dim inputRow2 As Integer = d.winY + 1 + GetClientTextHeight(d) + 1
        Dim cx3 As Integer = Len("ASM> ") + mamuteInputCursor(activeDoc) + 1
        If cx3 >= 1 And cx3 <= clientW3 Then
            ConsoleSetCursor(d.winX + cx3, inputRow2, 1)
        End If
        Exit Sub
    End If

    Dim cx As Integer = d.cursorX - d.scrollX
    Dim cy As Integer = d.cursorY - d.scrollY
    Dim clientW As Integer = GetClientTextWidth(d)
    Dim clientH As Integer = GetClientTextHeight(d)

    If cx >= 1 And cx <= clientW And cy >= 1 And cy <= clientH Then
        ConsoleSetCursor(d.winX + cx, d.winY + cy, 1)
    End If
End Sub

Private Sub InitBlankDocument(ByRef d As Document, ByRef docTitle As String)
    d.title = docTitle
    d.filePath = docTitle
    d.isHelp = 0
    d.isMamuteTerm = 0
    d.isMamuteEdit = 0
    d.helpTitle = ""
    d.helpWrapWidth = 0
    d.lineCount = 1
    d.lines(1) = ""
    d.cursorX = 1
    d.cursorY = 1
    d.scrollX = 0
    d.scrollY = 0
    d.isMaximized = 0
    d.normalX = 1
    d.normalY = 2
    d.normalW = 20
    d.normalH = 8
End Sub

Private Sub LoadFromDisk(ByRef d As Document, ByRef path As String)
    Dim ff As Integer = FreeFile
    Dim lineText As String
    Dim errCode As Integer

    errCode = Open(path For Input As #ff)
    If errCode <> 0 Then Exit Sub

    d.lineCount = 0
    While Not Eof(ff)
        Line Input #ff, lineText
        If d.lineCount < MAX_LINES Then
            d.lineCount += 1
            d.lines(d.lineCount) = lineText
        End If
    Wend
    Close #ff

    If d.lineCount = 0 Then
        d.lineCount = 1
        d.lines(1) = ""
    End If
End Sub

Private Sub DrawBox(ByVal x As Integer, ByVal y As Integer, ByVal w As Integer, ByVal h As Integer, ByRef title As String, ByVal isActive As Integer)
    Dim i As Integer
    Dim label As String = " " & title & " "

    Dim chTL As String = Chr(201)
    Dim chTR As String = Chr(187)
    Dim chBL As String = Chr(200)
    Dim chBR As String = Chr(188)
    Dim chH As String = Chr(205)
    Dim chV As String = Chr(186)

    Dim fg As UByte = IIf(isActive, 15, 7)
    ConsoleWriteText(x, y, chTL & String(w - 2, chH) & chTR, fg, 0)
    For i = y + 1 To y + h - 2
        ConsoleSetCell(x, i, Asc(chV), fg, 0)
        ConsoleSetCell(x + w - 1, i, Asc(chV), fg, 0)
    Next i
    ConsoleWriteText(x, y + h - 1, chBL & String(w - 2, chH) & chBR, fg, 0)

    ' Botao de fechar no topo esquerdo, antes do nome.
    ConsoleSetCell(x + 2, y, 254, IIf(isActive, 15, 8), 0)

    ' Botao de maximizar/restaurar no topo direito.
    If activeDoc >= 1 And activeDoc <= docCount And docs(activeDoc).winX = x And docs(activeDoc).winY = y Then
        If docs(activeDoc).isMaximized = 0 Then
            ConsoleSetCell(x + w - 3, y, 24, 14, 0)
        Else
            ConsoleSetCell(x + w - 3, y, 18, 14, 0)
        End If
    Else
        ConsoleSetCell(x + w - 3, y, 24, 8, 0)
    End If

    If Len(label) > w - 8 Then label = Left(label, w - 8)
    ConsoleWriteText(x + 4, y, label, fg, 0)

End Sub

Private Sub DrawScrollBars(ByVal docIndex As Integer)
    Dim ByRef d As Document = docs(docIndex)
    Dim isActive As Integer = IIf(docIndex = activeDoc, 1, 0)

    Dim trackVTop As Integer = d.winY + 1
    Dim trackVLen As Integer = d.winH - 3
    Dim trackVX As Integer = d.winX + d.winW - 2

    Dim trackHLeft As Integer = d.winX + 1
    Dim trackHLen As Integer = d.winW - 3
    Dim trackHY As Integer = d.winY + d.winH - 2

    Dim i As Integer
    For i = 0 To trackVLen - 1
        ConsoleSetCell(trackVX, trackVTop + i, 176, IIf(isActive, 11, 8), 0)
    Next i

    For i = 0 To trackHLen - 1
        ConsoleSetCell(trackHLeft + i, trackHY, 176, IIf(isActive, 11, 8), 0)
    Next i

    Dim thumbVStart As Integer
    Dim thumbVLen As Integer
    Dim maxScrollY As Integer
    ComputeThumb(d.lineCount, GetClientTextHeight(d), d.scrollY, trackVLen, thumbVStart, thumbVLen, maxScrollY)

    For i = 0 To thumbVLen - 1
        ConsoleSetCell(trackVX, trackVTop + thumbVStart + i, 219, IIf(isActive, 15, 7), 1)
    Next i

    Dim thumbHStart As Integer
    Dim thumbHLen As Integer
    Dim maxScrollX As Integer
    ComputeThumb(GetMaxLineLen(d), GetClientTextWidth(d), d.scrollX, trackHLen, thumbHStart, thumbHLen, maxScrollX)

    For i = 0 To thumbHLen - 1
        ConsoleSetCell(trackHLeft + thumbHStart + i, trackHY, 219, IIf(isActive, 15, 7), 1)
    Next i

    ' Junção entre barras com marca de resize por arraste.
    ConsoleSetCell(d.winX + d.winW - 2, d.winY + d.winH - 2, 206, IIf(isActive, 14, 8), 0)
End Sub

Private Sub DrawMenuBar(ByVal menuOpen As Integer)
    ConsoleWriteText(1, 1, String(uiW, " "), 15, 1)

    If menuOpen = MENU_VIEW_FILE Then
        ConsoleWriteText(2, 1, "Arquivo", 0, 7)
    Else
        ConsoleWriteText(2, 1, "Arquivo", 15, 1)
    End If

    If menuOpen = MENU_VIEW_CONFIG Then
        ConsoleWriteText(11, 1, "Configurar", 0, 7)
    Else
        ConsoleWriteText(11, 1, "Configurar", 15, 1)
    End If

    If menuOpen = MENU_VIEW_COMPILE Then
        ConsoleWriteText(23, 1, "Compilar", 0, 7)
    Else
        ConsoleWriteText(23, 1, "Compilar", 15, 1)
    End If

    If menuOpen = MENU_VIEW_REFERENCE Then
        ConsoleWriteText(33, 1, "Referencia", 0, 7)
    Else
        ConsoleWriteText(33, 1, "Referencia", 15, 1)
    End If

    If menuOpen = MENU_VIEW_MAMUTE Then
        ConsoleWriteText(45, 1, "Mamute", 0, 7)
    Else
        ConsoleWriteText(45, 1, "Mamute", 15, 1)
    End If

    If menuOpen = MENU_VIEW_HELP Then
        ConsoleWriteText(53, 1, "Ajuda", 0, 7)
    Else
        ConsoleWriteText(53, 1, "Ajuda", 15, 1)
    End If

    If menuOpen = MENU_VIEW_FILE Then
        ConsoleWriteText(2, 2, Chr(201) & String(32, Chr(205)) & Chr(187), 15, 1)
        ConsoleWriteText(2, 3, Chr(186) & " N Novo Basic Dignified    F4   " & Chr(186), 0, 7)
        ConsoleWriteText(2, 4, Chr(186) & " Z Novo asMSX                   " & Chr(186), 0, 7)
        ConsoleWriteText(2, 5, Chr(186) & " O Abrir...                F3   " & Chr(186), 0, 7)
        ConsoleWriteText(2, 6, Chr(186) & " S Salvar                  F2   " & Chr(186), 0, 7)
        ConsoleWriteText(2, 7, Chr(186) & " A Salvar Como                  " & Chr(186), 0, 7)
        ConsoleWriteText(2, 8, Chr(186) & " F Fechar                  F5   " & Chr(186), 0, 7)
        ConsoleWriteText(2, 9, Chr(186) & " X Exit                         " & Chr(186), 0, 7)
        ConsoleWriteText(2, 10, Chr(186) & "                                " & Chr(186), 0, 7)
        ConsoleWriteText(2, 11, Chr(186) & " P Novo Projeto                 " & Chr(186), 0, 7)
        ConsoleWriteText(2, 12, Chr(186) & " J Abrir Projeto...             " & Chr(186), 0, 7)
        ConsoleWriteText(2, 13, Chr(186) & " K Salvar Projeto               " & Chr(186), 0, 7)
        ConsoleWriteText(2, 14, Chr(186) & " W Fechar Projeto               " & Chr(186), 0, 7)
        ConsoleWriteText(2, 15, Chr(200) & String(32, Chr(205)) & Chr(188), 15, 1)
    ElseIf menuOpen = MENU_VIEW_CONFIG Then
        ConsoleWriteText(11, 2, Chr(201) & String(32, Chr(205)) & Chr(187), 15, 1)
        ConsoleWriteText(11, 3, Chr(186) & " B Basic Dignified               " & Chr(186), 0, 7)
        ConsoleWriteText(11, 4, Chr(186) & " M MSX Basic                     " & Chr(186), 0, 7)
        ConsoleWriteText(11, 5, Chr(186) & " E Emulador                      " & Chr(186), 0, 7)
        ConsoleWriteText(11, 6, Chr(186) & Left(" A Mamute (Memoria)" & Space(32), 32) & Chr(186), 0, 7)
        ConsoleWriteText(11, 7, Chr(200) & String(32, Chr(205)) & Chr(188), 15, 1)
    ElseIf menuOpen = MENU_VIEW_COMPILE Then
        ConsoleWriteText(23, 2, Chr(201) & String(42, Chr(205)) & Chr(187), 15, 1)
        ConsoleWriteText(23, 3, Chr(186) & " M MSX-Basic (gera .amx + .bmx)             " & Chr(186), 0, 7)
        ConsoleWriteText(23, 4, Chr(186) & " D Basic Dignified (gera .amx)              " & Chr(186), 0, 7)
        ConsoleWriteText(23, 5, Chr(186) & " A Tokenizar AMX atual (forca modo classico)" & Chr(186), 0, 7)
        ConsoleWriteText(23, 6, Chr(186) & " E Compilar + Executar no emulador          " & Chr(186), 0, 7)
        ConsoleWriteText(23, 7, Chr(186) & " L Abrir log de compilacao                  " & Chr(186), 0, 7)
        ConsoleWriteText(23, 8, Chr(200) & String(42, Chr(205)) & Chr(188), 15, 1)
    ElseIf menuOpen = MENU_VIEW_HELP Then
        ConsoleWriteText(53, 2, Chr(201) & String(34, Chr(205)) & Chr(187), 15, 1)
        ConsoleWriteText(53, 3, Chr(186) & " B Basic Dignified                  " & Chr(186), 0, 7)
        ConsoleWriteText(53, 4, Chr(186) & " D Dignified                        " & Chr(186), 0, 7)
        ConsoleWriteText(53, 5, Chr(186) & " T BaToken                          " & Chr(186), 0, 7)
        ConsoleWriteText(53, 6, Chr(186) & " A asMSX                            " & Chr(186), 0, 7)
        ConsoleWriteText(53, 7, Chr(186) & " M MSX BASIC Dictionary             " & Chr(186), 0, 7)
        ConsoleWriteText(53, 8, Chr(186) & " E Editor                           " & Chr(186), 0, 7)
        ConsoleWriteText(53, 9, Chr(186) & " N Mamute Assembler                 " & Chr(186), 0, 7)
        ConsoleWriteText(53, 10, Chr(186) & IIf(helpTheme = HELP_THEME_EDITORIAL, " C Tema: Editorial                  ", " C Tema: Classic                    ") & Chr(186), 0, 7)
        ConsoleWriteText(53, 11, Chr(200) & String(34, Chr(205)) & Chr(188), 15, 1)
    ElseIf menuOpen = MENU_VIEW_REFERENCE Then
        ConsoleWriteText(33, 2, Chr(201) & String(40, Chr(205)) & Chr(187), 15, 1)
        ConsoleWriteText(33, 3, Chr(186) & Left(" R The MSX Red Book" & Space(40), 40) & Chr(186), 0, 7)
        ConsoleWriteText(33, 4, Chr(186) & Left(" N Nestor Basic" & Space(40), 40) & Chr(186), 0, 7)
        ConsoleWriteText(33, 5, Chr(186) & Left(" T MSX2 Technical Handbook" & Space(40), 40) & Chr(186), 0, 7)
        ConsoleWriteText(33, 6, Chr(186) & Left(" M Manuais MSX" & Space(40), 40) & Chr(186), 0, 7)
        ConsoleWriteText(33, 7, Chr(186) & Left(" C BIOS Chamadas" & Space(40), 40) & Chr(186), 0, 7)
        ConsoleWriteText(33, 8, Chr(186) & Left(" W BIOS Hardware" & Space(40), 40) & Chr(186), 0, 7)
        ConsoleWriteText(33, 9, Chr(186) & Left(" D BIOS Documentacao" & Space(40), 40) & Chr(186), 0, 7)
        ConsoleWriteText(33, 10, Chr(186) & Left(" S SEE Tracker" & Space(40), 40) & Chr(186), 0, 7)
        ConsoleWriteText(33, 11, Chr(186) & Left(" O openMSX" & Space(40), 40) & Chr(186), 0, 7)
        ConsoleWriteText(33, 12, Chr(186) & Left(" X MSXBAS2ROM" & Space(40), 40) & Chr(186), 0, 7)
        ConsoleWriteText(33, 13, Chr(200) & String(40, Chr(205)) & Chr(188), 15, 1)
    ElseIf menuOpen = MENU_VIEW_MAMUTE Then
        ConsoleWriteText(45, 2, Chr(201) & String(30, Chr(205)) & Chr(187), 15, 1)
        ConsoleWriteText(45, 3, Chr(186) & Left(" A Abrir Mamute Assembler" & Space(30), 30) & Chr(186), 0, 7)
        ConsoleWriteText(45, 4, Chr(200) & String(30, Chr(205)) & Chr(188), 15, 1)
    End If
End Sub

Private Sub DrawStatusBar()
    Dim ByRef d As Document = docs(activeDoc)
    Dim frameCharCalls As UInteger
    Dim frameAttrCalls As UInteger
    Dim frameFillCalls As UInteger
    Dim mouseHudAvailable As Integer
    Dim mouseHudEnabled As Integer
    Dim mouseHudX As Integer
    Dim mouseHudY As Integer

    ConsoleGetLastFrameStats(frameCharCalls, frameAttrCalls, frameFillCalls)
    ConsoleGetMouseHud(mouseHudAvailable, mouseHudEnabled, mouseHudX, mouseHudY)

    Dim statusLine As String
        statusLine = "F10 Menu F8 Compilar F1 Ajuda Shift+F1 Dict F6 Janela F4 Novo F3 Abrir F2 Salvar F5 Fechar Ctrl+L Log | Esc Sair | "
    statusLine &= "Ln " & Trim(Str(d.cursorY)) & ", Col " & Trim(Str(d.cursorX))
    statusLine &= " | C:" & Trim(Str(frameCharCalls))
    statusLine &= " A:" & Trim(Str(frameAttrCalls))
    statusLine &= " F:" & Trim(Str(frameFillCalls))

    If mouseHudAvailable <> 0 Then
        statusLine &= " | VMOUSE "
        If mouseHudEnabled <> 0 Then
            statusLine &= "ON"
        Else
            statusLine &= "OFF"
        End If
        statusLine &= " (" & Trim(Str(mouseHudX)) & "," & Trim(Str(mouseHudY)) & ")"

        If mouseHudEnabled <> 0 Then
            statusLine &= " HJKL/Setas Move Space/Enter Click F7 Centro F9 Dbl F8 Off"
        Else
            statusLine &= " F8 On"
        End If
    End If

    statusLine &= " | " & d.title
    If ProjectIsActive() <> 0 Then statusLine &= " | proj:" & ProjectActiveName()

    Dim versionBlock As String = " | v" & MSXIDE_VERSION_STR
    Dim mainAreaW As Integer = uiW - 2 - Len(versionBlock)
    If mainAreaW < 1 Then mainAreaW = uiW - 2

    ConsoleWriteText(1, uiH, String(uiW, " "), 0, 7)
    ConsoleWriteText(2, uiH, statusLine, 0, 7, mainAreaW)
    ConsoleWriteText(uiW - Len(versionBlock) + 1, uiH, versionBlock, 8, 7)
End Sub

Private Sub DrawDocumentClient(ByVal docIndex As Integer)
    Dim ByRef d As Document = docs(docIndex)

    If d.isMamuteTerm <> 0 And mamuteMEditActive(docIndex) <> 0 Then
        DrawMamuteMEditGrid(docIndex)
        Exit Sub
    End If

    If d.isMamuteEdit <> 0 Then
        DrawMamuteEditView(docIndex)
        Exit Sub
    End If

    If d.isHelp <> 0 And docIndex = activeDoc Then EnsureHelpRerender(d)
    Dim row As Integer
    Dim lineIndex As Integer
    Dim clientH As Integer

    clientH = GetClientTextHeight(d)

    For row = 0 To clientH - 1
        lineIndex = d.scrollY + row + 1
        If d.isHelp <> 0 Then
            DrawHelpLine(docIndex, lineIndex, d.winY + 1 + row)
        Else
            DrawSyntaxLine(docIndex, lineIndex, d.winY + 1 + row)
        End If
    Next row

    If d.isMamuteTerm <> 0 Then DrawMamuteInputLine(docIndex, d.winY + 1 + clientH)

    DrawScrollBars(docIndex)
End Sub

Private Sub DrawDocumentLine(ByVal docIndex As Integer, ByVal lineNumber As Integer)
    Dim ByRef d As Document = docs(docIndex)

    If d.isMamuteTerm <> 0 And mamuteMEditActive(docIndex) <> 0 Then
        DrawMamuteMEditGrid(docIndex)
        Exit Sub
    End If

    If d.isMamuteEdit <> 0 Then
        DrawMamuteEditView(docIndex)
        Exit Sub
    End If

    If d.isHelp <> 0 And docIndex = activeDoc Then EnsureHelpRerender(d)
    Dim clientH As Integer = GetClientTextHeight(d)
    Dim row As Integer = lineNumber - d.scrollY

    If row < 1 Or row > clientH Then Exit Sub
    If d.isHelp <> 0 Then
        DrawHelpLine(docIndex, lineNumber, d.winY + row)
    Else
        DrawSyntaxLine(docIndex, lineNumber, d.winY + row)
    End If
End Sub

Private Sub DrawDocumentsFull()
    Dim i As Integer
    For i = 1 To docCount
        DrawBox(docs(i).winX, docs(i).winY, docs(i).winW, docs(i).winH, docs(i).title, IIf(i = activeDoc, 1, 0))
        DrawDocumentClient(i)
    Next i
End Sub

Private Sub DrawDocumentsFast()
    Select Case renderMode
        Case RENDER_LINE
            DrawDocumentLine(activeDoc, dirtyLine)
        Case RENDER_CLIENT
            DrawDocumentClient(activeDoc)
        Case Else
            ' RENDER_CURSOR: somente reposicionamento de cursor e status.
    End Select
End Sub

Private Sub MoveLeft(ByRef d As Document)
    If d.cursorX > 1 Then
        d.cursorX -= 1
    ElseIf d.cursorY > 1 Then
        d.cursorY -= 1
        d.cursorX = Len(d.lines(d.cursorY)) + 1
    End If
End Sub

Private Sub MoveRight(ByRef d As Document)
    Dim lineLen As Integer = Len(d.lines(d.cursorY))
    If d.cursorX <= lineLen Then
        d.cursorX += 1
    ElseIf d.cursorY < d.lineCount Then
        d.cursorY += 1
        d.cursorX = 1
    End If
End Sub

Private Sub MoveUp(ByRef d As Document)
    If d.cursorY > 1 Then
        d.cursorY -= 1
        d.cursorX = Clamp(d.cursorX, 1, Len(d.lines(d.cursorY)) + 1)
    End If
End Sub

Private Sub MoveDown(ByRef d As Document)
    If d.cursorY < d.lineCount Then
        d.cursorY += 1
        d.cursorX = Clamp(d.cursorX, 1, Len(d.lines(d.cursorY)) + 1)
    End If
End Sub

Private Sub InsertCharAtCursor(ByRef d As Document, ByRef ch As String)
    Dim lineText As String = d.lines(d.cursorY)
    lineText = Left(lineText, d.cursorX - 1) & ch & Mid(lineText, d.cursorX)
    d.lines(d.cursorY) = lineText
    d.cursorX += 1
End Sub

Private Sub InsertNewLine(ByRef d As Document)
    If d.lineCount >= MAX_LINES Then Exit Sub

    Dim lineText As String = d.lines(d.cursorY)
    Dim leftSide As String = Left(lineText, d.cursorX - 1)
    Dim rightSide As String = Mid(lineText, d.cursorX)
    Dim i As Integer

    For i = d.lineCount To d.cursorY + 1 Step -1
        d.lines(i + 1) = d.lines(i)
    Next i

    d.lines(d.cursorY) = leftSide
    d.lines(d.cursorY + 1) = rightSide
    d.lineCount += 1

    d.cursorY += 1
    d.cursorX = 1
End Sub

Private Sub BackspaceAtCursor(ByRef d As Document)
    If d.cursorX > 1 Then
        Dim lineText As String = d.lines(d.cursorY)
        lineText = Left(lineText, d.cursorX - 2) & Mid(lineText, d.cursorX)
        d.lines(d.cursorY) = lineText
        d.cursorX -= 1
        Exit Sub
    End If

    If d.cursorY > 1 Then
        Dim prevLen As Integer = Len(d.lines(d.cursorY - 1))
        d.lines(d.cursorY - 1) &= d.lines(d.cursorY)

        Dim i As Integer
        For i = d.cursorY To d.lineCount - 1
            d.lines(i) = d.lines(i + 1)
        Next i
        d.lines(d.lineCount) = ""
        d.lineCount -= 1

        d.cursorY -= 1
        d.cursorX = prevLen + 1
    End If
End Sub

Private Sub DeleteAtCursor(ByRef d As Document)
    Dim lineText As String = d.lines(d.cursorY)
    Dim lineLen As Integer = Len(lineText)

    If d.cursorX <= lineLen Then
        lineText = Left(lineText, d.cursorX - 1) & Mid(lineText, d.cursorX + 1)
        d.lines(d.cursorY) = lineText
        Exit Sub
    End If

    If d.cursorY < d.lineCount Then
        d.lines(d.cursorY) &= d.lines(d.cursorY + 1)
        Dim i As Integer
        For i = d.cursorY + 1 To d.lineCount - 1
            d.lines(i) = d.lines(i + 1)
        Next i
        d.lines(d.lineCount) = ""
        d.lineCount -= 1
    End If
End Sub

Private Sub SaveDocumentToDisk(ByRef d As Document)
    If d.isHelp <> 0 Then Exit Sub

    If Left(LCase(d.filePath), 4) = "cfg:" Then
        Dim cfgGroup As String = Mid(d.filePath, 5)
        Dim content As String = ""
        Dim i As Integer
        For i = 1 To d.lineCount
            content &= d.lines(i)
            If i < d.lineCount Then content &= Chr(10)
        Next i
        DbSaveConfigDocument(cfgGroup, content)
        Exit Sub
    End If

    Dim ff As Integer = FreeFile

    If Open(d.filePath For Output As #ff) <> 0 Then Exit Sub

    Dim i As Integer
    For i = 1 To d.lineCount
        Print #ff, d.lines(i)
    Next i

    Close #ff
End Sub

Private Sub SaveActiveDocumentToDisk()
    SaveDocumentToDisk(docs(activeDoc))
End Sub

Private Sub FinalizeModalInputState()
    dragMode = DRAG_NONE
    ConsoleResetInputState()
End Sub

Private Function PromptPathDialog(ByRef titleText As String, ByRef promptText As String, ByRef initialValue As String, ByRef canceled As Integer) As String
    Dim value As String = initialValue
    Dim cursorPos As Integer = Len(value) + 1
    Dim inputEvent As Integer
    Dim inputKey As String
    Dim inputMouseX As Integer
    Dim inputMouseY As Integer
    Dim inputMouseAction As Integer
    Dim dialogW As Integer = Clamp(uiW - 8, 40, 90)
    Dim dialogH As Integer = 7
    Dim dialogX As Integer = ((uiW - dialogW) \ 2) + 1
    Dim dialogY As Integer = ((uiH - dialogH) \ 2) + 1
    Dim maxInputLen As Integer = dialogW - 6

    canceled = 0

    Do
        ConsoleBeginFrame()
        DrawDesktop()
        DrawDocumentsFull()
        DrawMenuBar(0)
        DrawStatusBar()

        Dim topLine As String = Chr(201) & String(dialogW - 2, Chr(205)) & Chr(187)
        Dim midLine As String = Chr(186) & String(dialogW - 2, " ") & Chr(186)
        Dim botLine As String = Chr(200) & String(dialogW - 2, Chr(205)) & Chr(188)
        Dim i As Integer

        ConsoleWriteText(dialogX, dialogY, topLine, 15, 1)
        For i = 1 To dialogH - 2
            ConsoleWriteText(dialogX, dialogY + i, midLine, 15, 1)
        Next i
        ConsoleWriteText(dialogX, dialogY + dialogH - 1, botLine, 15, 1)

        ConsoleWriteText(dialogX + 2, dialogY, " " & titleText & " ", 0, 7, dialogW - 4)
        ConsoleWriteText(dialogX + 2, dialogY + 2, promptText, 15, 1, dialogW - 4)
        ConsoleWriteText(dialogX + 2, dialogY + 3, Left(value & String(maxInputLen, " "), maxInputLen), 0, 7, maxInputLen)
        ConsoleWriteText(dialogX + 2, dialogY + 5, "Enter confirma | Esc cancela", 8, 1, dialogW - 4)

        Dim cursorScreenX As Integer = dialogX + 2 + cursorPos - 1
        If cursorScreenX > dialogX + dialogW - 4 Then cursorScreenX = dialogX + dialogW - 4
        ConsoleSetCursor(cursorScreenX, dialogY + 3, 1)

        ConsoleFlush()
        ConsoleEndFrame()

        If ConsolePollInput(inputEvent, inputKey, inputMouseX, inputMouseY, inputMouseAction) = 0 Then
            Sleep 5, 1
            Continue Do
        End If

        If inputEvent <> MSX_INPUT_KEY Then Continue Do
        inputKey = NormalizeKey(inputKey)

        If inputKey = Chr(27) Then
            canceled = -1
            Exit Do
        End If

        If inputKey = Chr(13) Then Exit Do

        If inputKey = Chr(8) Then
            If cursorPos > 1 Then
                value = Left(value, cursorPos - 2) & Mid(value, cursorPos)
                cursorPos -= 1
            End If
            Continue Do
        End If

        If Len(inputKey) = 1 Then
            Dim c As Integer = Asc(inputKey)
            If c >= 32 And c <= 126 And Len(value) < maxInputLen Then
                value = Left(value, cursorPos - 1) & inputKey & Mid(value, cursorPos)
                cursorPos += 1
            End If
            Continue Do
        End If

        If Len(inputKey) = 2 And Asc(Left(inputKey, 1)) = 0 Then
            Select Case Asc(Right(inputKey, 1))
                Case 75
                    If cursorPos > 1 Then cursorPos -= 1
                Case 77
                    If cursorPos <= Len(value) Then cursorPos += 1
                Case 71
                    cursorPos = 1
                Case 79
                    cursorPos = Len(value) + 1
                Case 83
                    If cursorPos <= Len(value) Then
                        value = Left(value, cursorPos - 1) & Mid(value, cursorPos + 1)
                    End If
            End Select
        End If
    Loop

    FinalizeModalInputState()
    Return Trim(value)
End Function

Private Sub OpenDocumentDialog()
    Dim canceled As Integer
    Dim path As String

    path = PromptPathDialog("Abrir arquivo", "Caminho:", "", canceled)
    If canceled <> 0 Then Exit Sub
    If Len(path) = 0 Then Exit Sub

    EditorOpenFromPath(path)
End Sub

Private Sub SaveActiveDocumentAsDialog()
    If activeDoc < 1 Or activeDoc > docCount Then Exit Sub

    Dim ByRef d As Document = docs(activeDoc)
    If d.isHelp <> 0 Then Exit Sub
    If Left(LCase(d.filePath), 4) = "cfg:" Then Exit Sub
    Dim canceled As Integer
    Dim path As String

    path = PromptPathDialog("Salvar como", "Caminho:", d.filePath, canceled)
    If canceled <> 0 Then Exit Sub
    If Len(path) = 0 Then Exit Sub

    d.filePath = path
    d.title = path
    SaveActiveDocumentToDisk()
End Sub

Private Sub CloseActiveDocument()
    If activeDoc < 1 Or activeDoc > docCount Then Exit Sub
    CloseDocument(activeDoc)
End Sub

Private Sub LoadHelpIntoDocument(ByRef d As Document, ByRef helpTitle As String, ByRef filePath As String, ByVal preservePosition As Integer = 0)
    Dim renderLines() As String
    Dim renderColors() As UByte
    Dim renderBgs() As UByte
    Dim renderCount As Integer
    Dim indexTargets() As Integer
    Dim indexEntryLine() As Integer
    Dim indexCount As Integer
    Dim wrapW As Integer = GetClientTextWidth(d)
    If wrapW < 24 Then wrapW = 24
    Dim i As Integer
    Dim oldLineCount As Integer = d.lineCount
    Dim oldScrollY As Integer = d.scrollY
    Dim oldCursorY As Integer = d.cursorY
    Dim oldCursorX As Integer = d.cursorX

    BuildMarkdownHelpBuffer(filePath, wrapW, renderLines(), renderColors(), renderBgs(), renderCount, indexTargets(), indexEntryLine(), indexCount)

    d.title = "HELP " & helpTitle
    d.filePath = filePath
    d.isHelp = -1
    d.helpTitle = helpTitle
    d.helpWrapWidth = wrapW
    d.lineCount = 0
    ClearMsxDictLineMap(activeDoc)

    For i = 1 To renderCount
        If d.lineCount >= MAX_LINES Then Exit For
        d.lineCount = d.lineCount + 1
        d.lines(d.lineCount) = renderLines(i)
        helpLineFg(activeDoc, d.lineCount) = renderColors(i)
        helpLineBg(activeDoc, d.lineCount) = renderBgs(i)
    Next i

    ' As entradas do INDICE (topo do texto) viram alvo clicavel: clicar ou
    ' dar Enter numa delas rola o documento ate o cabecalho correspondente.
    For i = 1 To indexCount
        If indexEntryLine(i) >= 1 And indexEntryLine(i) <= d.lineCount Then
            msxDictLineCommand(activeDoc, indexEntryLine(i)) = "JUMP:" & Trim(Str(indexTargets(i)))
        End If
    Next i

    If d.lineCount <= 0 Then
        d.lineCount = 1
        d.lines(1) = "Ajuda indisponivel."
    End If

    If preservePosition <> 0 And oldLineCount > 0 Then
        Dim oldMax As Integer = oldLineCount - 1
        If oldMax < 1 Then oldMax = 1
        Dim newMax As Integer = d.lineCount - 1
        If newMax < 1 Then newMax = 1

        d.scrollY = (oldScrollY * newMax) \ oldMax
        d.cursorY = (oldCursorY * d.lineCount) \ oldLineCount
        d.cursorX = oldCursorX
    Else
        d.cursorX = 1
        d.cursorY = 1
        d.scrollY = 0
    End If

    If d.cursorY < 1 Then d.cursorY = 1
    If d.cursorY > d.lineCount Then d.cursorY = d.lineCount
    Dim lineLen As Integer = Len(d.lines(d.cursorY)) + 1
    If d.cursorX < 1 Then d.cursorX = 1
    If d.cursorX > lineLen Then d.cursorX = lineLen
    d.scrollX = 0
    ClampScroll(d)
End Sub

Private Sub EnsureHelpRerender(ByRef d As Document)
    If d.isHelp = 0 Then Exit Sub

    Dim wrapW As Integer = GetClientTextWidth(d)
    If wrapW < 24 Then wrapW = 24

    If d.helpWrapWidth <> wrapW Then
        If IsMsxDictDoc(d) <> 0 Then
            Dim oldLineCount As Integer = d.lineCount
            Dim oldScrollY As Integer = d.scrollY
            Dim oldCursorY As Integer = d.cursorY
            Dim oldCursorX As Integer = d.cursorX
            Dim fp As String = LCase(d.filePath)

            If Left(fp, 13) = "msxdict:index" Then
                LoadMsxDictIndexIntoDocument(d)
            ElseIf Left(fp, 12) = "msxdict:cmd:" Then
                Dim keyName As String = Mid(d.filePath, 13)
                LoadMsxDictCommandIntoDocument(d, keyName)
            ElseIf Left(fp, 14) = "msxdict:topic:" Then
                Dim topicId As Integer = ValInt(Mid(d.filePath, 14))
                LoadMsxManualTopicIntoDocument(d, topicId)
            Else
                LoadMsxDictIndexIntoDocument(d)
            End If

            If oldLineCount > 0 Then
                Dim oldMax As Integer = oldLineCount - 1
                If oldMax < 1 Then oldMax = 1
                Dim newMax As Integer = d.lineCount - 1
                If newMax < 1 Then newMax = 1

                d.scrollY = (oldScrollY * newMax) \ oldMax
                d.cursorY = (oldCursorY * d.lineCount) \ oldLineCount
                d.cursorX = oldCursorX
                If d.cursorY < 1 Then d.cursorY = 1
                If d.cursorY > d.lineCount Then d.cursorY = d.lineCount
                If d.cursorX < 1 Then d.cursorX = 1
                Dim lineLen As Integer = Len(d.lines(d.cursorY)) + 1
                If d.cursorX > lineLen Then d.cursorX = lineLen
                d.scrollX = 0
                ClampScroll(d)
            End If
        ElseIf Left(LCase(d.filePath), 8) = "refdict:" Then
            Dim oldLineCount2 As Integer = d.lineCount
            Dim oldScrollY2 As Integer = d.scrollY
            Dim oldCursorY2 As Integer = d.cursorY
            Dim oldCursorX2 As Integer = d.cursorX

            Dim afterPrefix As String = Mid(d.filePath, 9)
            Dim colonPos As Integer = InStr(afterPrefix, ":")
            Dim dId As String = IIf(colonPos > 0, Left(afterPrefix, colonPos - 1), afterPrefix)
            Dim tail As String = IIf(colonPos > 0, Mid(afterPrefix, colonPos + 1), "")

            If Left(tail, 6) = "topic:" Then
                LoadRefDictTopicIntoDocument(d, dId, ValInt(Mid(tail, 7)))
            Else
                LoadRefDictIndexIntoDocument(d, dId)
            End If

            If oldLineCount2 > 0 Then
                Dim oldMax2 As Integer = oldLineCount2 - 1
                If oldMax2 < 1 Then oldMax2 = 1
                Dim newMax2 As Integer = d.lineCount - 1
                If newMax2 < 1 Then newMax2 = 1

                d.scrollY = (oldScrollY2 * newMax2) \ oldMax2
                d.cursorY = (oldCursorY2 * d.lineCount) \ oldLineCount2
                d.cursorX = oldCursorX2
                If d.cursorY < 1 Then d.cursorY = 1
                If d.cursorY > d.lineCount Then d.cursorY = d.lineCount
                If d.cursorX < 1 Then d.cursorX = 1
                Dim lineLen2 As Integer = Len(d.lines(d.cursorY)) + 1
                If d.cursorX > lineLen2 Then d.cursorX = lineLen2
                d.scrollX = 0
                ClampScroll(d)
            End If
        Else
            Dim ht As String = d.helpTitle
            If Len(ht) = 0 Then ht = d.title
            LoadHelpIntoDocument(d, ht, d.filePath, -1)
        End If
    End If
End Sub

Private Sub OpenConfigDocument(ByRef titleText As String, ByRef configGroup As String)
    Dim cfgPath As String = "cfg:" & LCase(configGroup)
    Dim i As Integer

    For i = 1 To docCount
        If docs(i).isHelp = 0 And LCase(docs(i).filePath) = cfgPath Then
            BringDocumentToFront(i)
            forceFullRedraw = 1
            renderMode = RENDER_FULL
            Exit Sub
        End If
    Next i

    If docCount >= MAX_DOCS Then Exit Sub

    docCount += 1
    activeDoc = docCount
    InitBlankDocument(docs(docCount), titleText)
    LayoutNewDocumentWindow(docCount)
    docs(docCount).title = "CFG " & titleText
    docs(docCount).filePath = cfgPath
    docs(docCount).isHelp = 0
    docs(docCount).lineCount = 0

    Dim rawText As String = StripCR(DbGetConfigDocument(configGroup))
    Dim p As Integer = 1

    While p <= Len(rawText)
        Dim br As Integer = InStr(p, rawText, Chr(10))
        Dim rowText As String
        If br = 0 Then
            rowText = Mid(rawText, p)
            p = Len(rawText) + 1
        Else
            rowText = Mid(rawText, p, br - p)
            p = br + 1
        End If

        If docs(docCount).lineCount < MAX_LINES Then
            docs(docCount).lineCount += 1
            docs(docCount).lines(docs(docCount).lineCount) = rowText
        End If
    Wend

    If docs(docCount).lineCount <= 0 Then
        docs(docCount).lineCount = 1
        docs(docCount).lines(1) = "[CONFIGS]"
    End If

    docs(docCount).cursorX = 1
    docs(docCount).cursorY = 1
    docs(docCount).scrollX = 0
    docs(docCount).scrollY = 0

    forceFullRedraw = 1
    renderMode = RENDER_FULL
End Sub

Private Sub OpenHelpDocument(ByRef helpTitle As String, ByRef filePath As String)
    Dim i As Integer
    For i = 1 To docCount
        If docs(i).isHelp <> 0 And LCase(docs(i).filePath) = LCase(filePath) Then
            BringDocumentToFront(i)
            forceFullRedraw = 1
            renderMode = RENDER_FULL
            Exit Sub
        End If
    Next i

    ' Reusa a janela de help ativa (opcao 3), sem abrir nova aba de help.
    If activeDoc >= 1 And activeDoc <= docCount Then
        If docs(activeDoc).isHelp <> 0 Then
            LoadHelpIntoDocument(docs(activeDoc), helpTitle, filePath)
            forceFullRedraw = 1
            renderMode = RENDER_FULL
            Exit Sub
        End If
    End If

    If docCount >= MAX_DOCS Then Exit Sub

    docCount = docCount + 1
    activeDoc = docCount

    InitBlankDocument(docs(docCount), helpTitle)
    LayoutNewDocumentWindow(docCount)
    LoadHelpIntoDocument(docs(docCount), helpTitle, filePath)

    forceFullRedraw = 1
    renderMode = RENDER_FULL
End Sub

Private Sub ApplyHelpTheme()
    If helpTheme = HELP_THEME_CLASSIC Then
        helpFgText = 7
        helpBgText = 0
        helpFgH1 = 15
        helpBgH1 = 1
        helpFgH2 = 14
        helpBgH2 = 1
        helpFgH3 = 11
        helpBgH3 = 0
        helpFgCode = 10
        helpBgCode = 0
        helpFgList = 7
        helpBgList = 0
        helpFgTable = 7
        helpBgTable = 0
    Else
        helpFgText = 15
        helpBgText = 1
        helpFgH1 = 15
        helpBgH1 = 4
        helpFgH2 = 15
        helpBgH2 = 2
        helpFgH3 = 14
        helpBgH3 = 0
        helpFgCode = 10
        helpBgCode = 8
        helpFgList = 11
        helpBgList = 0
        helpFgTable = 0
        helpBgTable = 7
    End If
End Sub

Private Sub AddHelpLine(lines() As String, colors() As UByte, bgs() As UByte, ByRef count As Integer, ByVal textLine As String, ByVal fg As UByte, ByVal bg As UByte)
    count += 1
    If count = 1 Then
        ReDim lines(1 To 1)
        ReDim colors(1 To 1)
        ReDim bgs(1 To 1)
    Else
        ReDim Preserve lines(1 To count)
        ReDim Preserve colors(1 To count)
        ReDim Preserve bgs(1 To count)
    End If
    lines(count) = textLine
    colors(count) = fg
    bgs(count) = bg
End Sub

Private Sub AddWrappedHelpLine(lines() As String, colors() As UByte, bgs() As UByte, ByRef count As Integer, ByVal textLine As String, ByVal fg As UByte, ByVal bg As UByte, ByVal maxWidth As Integer)
    Dim rest As String = textLine

    If maxWidth < 8 Then maxWidth = 8
    If Len(rest) = 0 Then
        AddHelpLine(lines(), colors(), bgs(), count, "", fg, bg)
        Exit Sub
    End If

    Do While Len(rest) > maxWidth
        Dim cutPos As Integer = maxWidth
        Dim i As Integer
        For i = maxWidth To 1 Step -1
            If Mid(rest, i, 1) = " " Then
                cutPos = i
                Exit For
            End If
        Next i

        If cutPos < 1 Then cutPos = maxWidth
        AddHelpLine(lines(), colors(), bgs(), count, RTrim(Left(rest, cutPos)), fg, bg)
        rest = LTrim(Mid(rest, cutPos + 1))
    Loop

    AddHelpLine(lines(), colors(), bgs(), count, rest, fg, bg)
End Sub

Private Function ExpandTabsForHelp(ByRef textLine As String) As String
    Dim outText As String = ""
    Dim i As Integer
    For i = 1 To Len(textLine)
        Dim ch As String = Mid(textLine, i, 1)
        If ch = Chr(9) Then
            outText &= "    "
        Else
            outText &= ch
        End If
    Next i
    Return outText
End Function

Private Function CountCharInText(ByRef textLine As String, ByVal ch As String) As Integer
    Dim i As Integer
    Dim cnt As Integer = 0
    For i = 1 To Len(textLine)
        If Mid(textLine, i, 1) = ch Then cnt = cnt + 1
    Next i
    Return cnt
End Function

Private Function IsTableSeparatorRow(ByRef textLine As String) As Integer
    Dim t As String = Trim(textLine)
    Dim i As Integer

    If Len(t) = 0 Then Return 0
    If CountCharInText(t, "|") < 2 Then Return 0

    For i = 1 To Len(t)
        Dim c As String = Mid(t, i, 1)
        If InStr("|-: ", c) = 0 Then Return 0
    Next i

    Return -1
End Function

Private Function BuildTableVisualRow(ByRef rawLine As String) As String
    Dim t As String = Trim(rawLine)
    Dim outLine As String = Chr(179)
    Dim cellText As String = ""
    Dim i As Integer

    If Left(t, 1) = "|" Then t = Mid(t, 2)
    If Right(t, 1) = "|" Then t = Left(t, Len(t) - 1)

    For i = 1 To Len(t)
        Dim ch As String = Mid(t, i, 1)
        If ch = "|" Then
            outLine &= " " & Trim(cellText) & " " & Chr(179)
            cellText = ""
        Else
            cellText &= ch
        End If
    Next i

    outLine &= " " & Trim(cellText) & " " & Chr(179)
    Return outLine
End Function

Private Function GetTableCellCount(ByRef rawLine As String) As Integer
    Dim t As String = Trim(rawLine)
    Dim i As Integer
    Dim bars As Integer = 0

    If Left(t, 1) = "|" Then t = Mid(t, 2)
    If Right(t, 1) = "|" Then t = Left(t, Len(t) - 1)
    If Len(t) = 0 Then Return 1

    For i = 1 To Len(t)
        If Mid(t, i, 1) = "|" Then bars = bars + 1
    Next i

    Return bars + 1
End Function

Private Function GetTableCellText(ByRef rawLine As String, ByVal cellIndex As Integer) As String
    Dim t As String = Trim(rawLine)
    Dim i As Integer
    Dim curr As Integer = 1
    Dim cellText As String = ""

    If Left(t, 1) = "|" Then t = Mid(t, 2)
    If Right(t, 1) = "|" Then t = Left(t, Len(t) - 1)

    For i = 1 To Len(t)
        Dim ch As String = Mid(t, i, 1)
        If ch = "|" Then
            If curr = cellIndex Then Return Trim(cellText)
            curr = curr + 1
            cellText = ""
        Else
            cellText &= ch
        End If
    Next i

    If curr = cellIndex Then Return Trim(cellText)
    Return ""
End Function

Private Sub FitTableColWidths(colWidths() As Integer, ByVal colCount As Integer, ByVal maxTotalWidth As Integer)
    Dim i As Integer
    Dim total As Integer = 1
    For i = 1 To colCount
        If colWidths(i) < 3 Then colWidths(i) = 3
        total = total + colWidths(i) + 3
    Next i

    While total > maxTotalWidth
        Dim bestCol As Integer = 0
        Dim bestW As Integer = -1

        For i = 1 To colCount
            If colWidths(i) > bestW Then
                bestW = colWidths(i)
                bestCol = i
            End If
        Next i

        If bestCol = 0 Or colWidths(bestCol) <= 3 Then Exit While

        colWidths(bestCol) = colWidths(bestCol) - 1
        total = total - 1
    Wend
End Sub

Private Function BuildTableVisualRowAligned(ByRef rawLine As String, colWidths() As Integer, ByVal colCount As Integer) As String
    Dim outLine As String = Chr(179)
    Dim c As Integer

    For c = 1 To colCount
        Dim cellText As String = GetTableCellText(rawLine, c)
        Dim w As Integer = colWidths(c)

        If Len(cellText) > w Then
            If w >= 4 Then
                cellText = Left(cellText, w - 1) & Chr(250)
            Else
                cellText = Left(cellText, w)
            End If
        End If

        cellText &= Space(w - Len(cellText))
        outLine &= " " & cellText & " " & Chr(179)
    Next c

    Return outLine
End Function

Private Sub BuildMarkdownHelpBuffer(ByRef filePath As String, ByVal wrapWidth As Integer, outLines() As String, outColors() As UByte, outBgs() As UByte, ByRef outCount As Integer, indexTargets() As Integer, indexEntryLine() As Integer, ByRef indexCount As Integer)
    Dim srcLines() As String
    Dim srcCount As Integer = 0
    Dim headingTitles() As String
    Dim headingLevels() As Integer
    Dim headingSourceLine() As Integer
    Dim headingCount As Integer = 0
    Dim ff As Integer = FreeFile
    Dim lineText As String
    Dim errCode As Integer
    Dim i As Integer
    Dim sourceText As String = ""

    outCount = 0
    indexCount = 0

    If Left(LCase(filePath), 7) = "dbhelp:" Then
        Dim sepPos As Integer = InStr(filePath, "|")
        Dim docKey As String
        Dim fallbackPath As String = ""

        If sepPos > 0 Then
            docKey = Mid(filePath, 8, sepPos - 8)
            fallbackPath = Mid(filePath, sepPos + 1)
        Else
            docKey = Mid(filePath, 8)
        End If
        sourceText = DbGetHelpDoc(docKey, fallbackPath)
    Else
        errCode = Open(filePath For Input As #ff)
        If errCode <> 0 Then
            AddHelpLine(outLines(), outColors(), outBgs(), outCount, "Nao foi possivel abrir: " & filePath, 12, helpBgText)
            Exit Sub
        End If

        While Not Eof(ff)
            Line Input #ff, lineText
            sourceText &= lineText
            If Not Eof(ff) Then sourceText &= Chr(10)
        Wend
        Close #ff
    End If

    sourceText = StripCR(sourceText)
    sourceText = ConsoleUtf8ToActiveCp(sourceText)
    Dim p As Integer = 1
    While p <= Len(sourceText)
        Dim br As Integer = InStr(p, sourceText, Chr(10))
        If br = 0 Then
            lineText = Mid(sourceText, p)
            p = Len(sourceText) + 1
        Else
            lineText = Mid(sourceText, p, br - p)
            p = br + 1
        End If

        srcCount += 1
        If srcCount = 1 Then
            ReDim srcLines(1 To 1)
        Else
            ReDim Preserve srcLines(1 To srcCount)
        End If
        srcLines(srcCount) = lineText

        Dim t As String = LTrim(lineText)
        Dim lvl As Integer = 0
        While lvl < Len(t) And Mid(t, lvl + 1, 1) = "#"
            lvl += 1
        Wend
        If lvl > 0 And lvl <= 6 And Len(t) > lvl And Mid(t, lvl + 1, 1) = " " Then
            headingCount += 1
            If headingCount = 1 Then
                ReDim headingTitles(1 To 1)
                ReDim headingLevels(1 To 1)
                ReDim headingSourceLine(1 To 1)
            Else
                ReDim Preserve headingTitles(1 To headingCount)
                ReDim Preserve headingLevels(1 To headingCount)
                ReDim Preserve headingSourceLine(1 To headingCount)
            End If
            headingTitles(headingCount) = Trim(Mid(t, lvl + 2))
            headingLevels(headingCount) = lvl
            headingSourceLine(headingCount) = srcCount
        End If
    Wend

    If srcCount = 0 Then
        AddHelpLine(outLines(), outColors(), outBgs(), outCount, "Documento vazio.", 8, helpBgText)
        Exit Sub
    End If

    AddHelpLine(outLines(), outColors(), outBgs(), outCount, "INDICE", 14, helpBgText)
    AddHelpLine(outLines(), outColors(), outBgs(), outCount, String(6, Chr(196)), 14, helpBgText)

    If headingCount = 0 Then
        AddHelpLine(outLines(), outColors(), outBgs(), outCount, "(sem secoes detectadas)", 8, helpBgText)
    Else
        indexCount = headingCount
        ReDim indexTargets(1 To headingCount)
        ReDim indexEntryLine(1 To headingCount)
        For i = 1 To headingCount
            Dim item As String = Trim(Str(i)) & ". "
            If headingLevels(i) > 1 Then
                item &= String((headingLevels(i) - 1) * 2, " ")
            End If
            item &= headingTitles(i)
            indexEntryLine(i) = outCount + 1
            AddWrappedHelpLine(outLines(), outColors(), outBgs(), outCount, item, 11, helpBgText, wrapWidth)
        Next i
    End If

    AddHelpLine(outLines(), outColors(), outBgs(), outCount, "", helpFgText, helpBgText)
    AddHelpLine(outLines(), outColors(), outBgs(), outCount, "CONTEUDO", 13, helpBgText)
    AddHelpLine(outLines(), outColors(), outBgs(), outCount, String(8, Chr(196)), 13, helpBgText)
    AddHelpLine(outLines(), outColors(), outBgs(), outCount, "", helpFgText, helpBgText)

    Dim inCodeFence As Integer = 0
    Dim headingIdx As Integer = 1

    For i = 1 To srcCount
        lineText = srcLines(i)
        Dim t As String = LTrim(lineText)

        If Left(t, 3) = "```" Then
            inCodeFence = IIf(inCodeFence = 0, 1, 0)
            AddHelpLine(outLines(), outColors(), outBgs(), outCount, String(wrapWidth, Chr(196)), 8, helpBgCode)
            Continue For
        End If

        If inCodeFence <> 0 Then
            Dim codeLine As String = "  " & ExpandTabsForHelp(lineText)
            AddWrappedHelpLine(outLines(), outColors(), outBgs(), outCount, codeLine, helpFgCode, helpBgCode, wrapWidth)
            Continue For
        End If

        Dim lvl As Integer = 0
        While lvl < Len(t) And Mid(t, lvl + 1, 1) = "#"
            lvl += 1
        Wend

        If lvl > 0 And lvl <= 6 And Len(t) > lvl And Mid(t, lvl + 1, 1) = " " Then
            Dim titleLine As String = Trim(Mid(t, lvl + 2))
            Dim headColor As UByte = 15
            Dim headBg As UByte = helpBgText
            Select Case lvl
                Case 1
                    headColor = helpFgH1
                    headBg = helpBgH1
                Case 2
                    headColor = helpFgH2
                    headBg = helpBgH2
                Case 3
                    headColor = helpFgH3
                    headBg = helpBgH3
                Case Else
                    headColor = 10
                    headBg = helpBgText
            End Select

            If headingIdx <= headingCount Then
                indexTargets(headingIdx) = outCount + 1
                headingIdx += 1
            End If

            AddWrappedHelpLine(outLines(), outColors(), outBgs(), outCount, titleLine, headColor, headBg, wrapWidth)
            AddHelpLine(outLines(), outColors(), outBgs(), outCount, String(Clamp(Len(titleLine), 3, wrapWidth), Chr(205)), headColor, headBg)
            Continue For
        End If

        If Left(t, 1) = ">" Then
            AddWrappedHelpLine(outLines(), outColors(), outBgs(), outCount, "| " & LTrim(Mid(t, 2)), 8, helpBgText, wrapWidth)
            Continue For
        End If

        If Left(t, 2) = "- " Or Left(t, 2) = "* " Then
            AddWrappedHelpLine(outLines(), outColors(), outBgs(), outCount, "* " & Mid(t, 3), helpFgList, helpBgList, wrapWidth)
            Continue For
        End If

        Dim dotPos As Integer = InStr(t, ". ")
        If dotPos > 1 Then
            Dim onlyDigits As Integer = -1
            Dim k As Integer
            For k = 1 To dotPos - 1
                Dim c As Integer = Asc(Mid(t, k, 1))
                If c < 48 Or c > 57 Then
                    onlyDigits = 0
                    Exit For
                End If
            Next k
            If onlyDigits <> 0 Then
                AddWrappedHelpLine(outLines(), outColors(), outBgs(), outCount, t, helpFgList, helpBgList, wrapWidth)
                Continue For
            End If
        End If

        If CountCharInText(t, "|") >= 2 Then
            Dim tableRows() As String
            Dim tableRowCount As Integer = 0
            Dim j As Integer = i
            Dim hasHeaderSep As Integer = 0
            Dim maxRowLen As Integer = 0
            Dim tableRawRows() As String
            Dim colCount As Integer = 0

            While j <= srcCount
                Dim maybeTable As String = LTrim(srcLines(j))
                If CountCharInText(maybeTable, "|") < 2 Then Exit While

                If IsTableSeparatorRow(maybeTable) <> 0 Then
                    hasHeaderSep = -1
                Else
                    tableRowCount = tableRowCount + 1
                    If tableRowCount = 1 Then
                        ReDim tableRows(1 To 1)
                        ReDim tableRawRows(1 To 1)
                    Else
                        ReDim Preserve tableRows(1 To tableRowCount)
                        ReDim Preserve tableRawRows(1 To tableRowCount)
                    End If
                    tableRawRows(tableRowCount) = maybeTable

                    Dim currCols As Integer = GetTableCellCount(maybeTable)
                    If currCols > colCount Then colCount = currCols

                    tableRows(tableRowCount) = BuildTableVisualRow(maybeTable)
                End If
                j = j + 1
            Wend

            If tableRowCount > 0 Then
                If helpTheme = HELP_THEME_EDITORIAL And colCount > 0 Then
                    Dim colWidths() As Integer
                    ReDim colWidths(1 To colCount)

                    Dim tr As Integer
                    For tr = 1 To tableRowCount
                        Dim c As Integer
                        For c = 1 To colCount
                            Dim cellText As String = GetTableCellText(tableRawRows(tr), c)
                            If Len(cellText) > colWidths(c) Then colWidths(c) = Len(cellText)
                        Next c
                    Next tr

                    FitTableColWidths(colWidths(), colCount, wrapWidth)

                    For tr = 1 To tableRowCount
                        tableRows(tr) = BuildTableVisualRowAligned(tableRawRows(tr), colWidths(), colCount)
                    Next tr
                End If

                Dim tr As Integer
                For tr = 1 To tableRowCount
                    If Len(tableRows(tr)) > maxRowLen Then maxRowLen = Len(tableRows(tr))
                Next tr

                If maxRowLen > wrapWidth Then maxRowLen = wrapWidth
                If maxRowLen < 4 Then maxRowLen = 4

                AddHelpLine(outLines(), outColors(), outBgs(), outCount, Chr(218) & String(maxRowLen - 2, Chr(196)) & Chr(191), helpFgTable, helpBgTable)

                For tr = 1 To tableRowCount
                    Dim rowTxt As String = Left(tableRows(tr) & Space(maxRowLen), maxRowLen)
                    If Right(rowTxt, 1) <> Chr(179) Then Mid(rowTxt, maxRowLen, 1) = Chr(179)
                    Mid(rowTxt, 1, 1) = Chr(179)
                    AddHelpLine(outLines(), outColors(), outBgs(), outCount, rowTxt, helpFgTable, helpBgTable)

                    If tr = 1 And hasHeaderSep <> 0 And tableRowCount > 1 Then
                        AddHelpLine(outLines(), outColors(), outBgs(), outCount, Chr(195) & String(maxRowLen - 2, Chr(196)) & Chr(180), helpFgTable, helpBgTable)
                    End If
                Next tr

                AddHelpLine(outLines(), outColors(), outBgs(), outCount, Chr(192) & String(maxRowLen - 2, Chr(196)) & Chr(217), helpFgTable, helpBgTable)
            End If

            i = j - 1
            Continue For
        End If

        Dim plainLine As String = ExpandTabsForHelp(lineText)
        AddWrappedHelpLine(outLines(), outColors(), outBgs(), outCount, plainLine, helpFgText, helpBgText, wrapWidth)
    Next i
End Sub

Private Sub DrawStyledHelpLine(ByVal x As Integer, ByVal y As Integer, ByRef lineText As String, ByVal baseFg As UByte, ByVal bg As UByte, ByVal maxWidth As Integer)
    Dim outX As Integer = 0
    Dim srcPos As Integer = 1
    Dim emph As Integer = 0
    Dim inCode As Integer = 0

    While outX < maxWidth
        If srcPos > Len(lineText) Then
            ConsoleSetCell(x + outX, y, Asc(" "), baseFg, bg)
            outX = outX + 1
            Continue While
        End If

        If srcPos < Len(lineText) And Mid(lineText, srcPos, 2) = "**" Then
            emph = IIf(emph = 0, 1, 0)
            srcPos = srcPos + 2
            Continue While
        End If

        If Mid(lineText, srcPos, 1) = "`" Then
            inCode = IIf(inCode = 0, 1, 0)
            srcPos = srcPos + 1
            Continue While
        End If

        Dim ch As String = Mid(lineText, srcPos, 1)
        Dim fg As UByte = baseFg
        If emph <> 0 Then fg = 15
        If inCode <> 0 Then fg = 3

        ConsoleSetCell(x + outX, y, Asc(ch), fg, bg)
        outX = outX + 1
        srcPos = srcPos + 1
    Wend
End Sub

Private Sub ShowMarkdownHelp(ByRef helpTitle As String, ByRef filePath As String)
    Dim dialogW As Integer = Clamp(uiW - 6, 60, uiW)
    Dim dialogH As Integer = Clamp(uiH - 4, 16, uiH - 1)
    Dim dialogX As Integer = ((uiW - dialogW) \ 2) + 1
    Dim dialogY As Integer = ((uiH - dialogH) \ 2) + 1
    Dim viewW As Integer = dialogW - 5
    Dim viewH As Integer = dialogH - 4
    Dim barX As Integer = dialogX + dialogW - 3

    Dim lines() As String
    Dim colors() As UByte
    Dim bgs() As UByte
    Dim lineCount As Integer
    Dim indexTargets() As Integer
    Dim indexEntryLine() As Integer
    Dim indexCount As Integer
    Dim topLine As Integer = 1

    BuildMarkdownHelpBuffer(filePath, viewW, lines(), colors(), bgs(), lineCount, indexTargets(), indexEntryLine(), indexCount)
    If lineCount <= 0 Then Exit Sub

    Do
        ConsoleBeginFrame()
        DrawDesktop()
        DrawDocumentsFull()
        DrawMenuBar(MENU_VIEW_NONE)
        DrawStatusBar()

        Dim topBorder As String = Chr(201) & String(dialogW - 2, Chr(205)) & Chr(187)
        Dim midBorder As String = Chr(186) & String(dialogW - 2, " ") & Chr(186)
        Dim botBorder As String = Chr(200) & String(dialogW - 2, Chr(205)) & Chr(188)
        Dim row As Integer

        ConsoleWriteText(dialogX, dialogY, topBorder, 15, 1)
        For row = 1 To dialogH - 2
            ConsoleWriteText(dialogX, dialogY + row, midBorder, 15, 1)
        Next row
        ConsoleWriteText(dialogX, dialogY + dialogH - 1, botBorder, 15, 1)

        ConsoleWriteText(dialogX + 2, dialogY, " Ajuda: " & helpTitle & " ", 0, 7, dialogW - 4)

        For row = 0 To viewH - 1
            Dim idx As Integer = topLine + row
            If idx >= 1 And idx <= lineCount Then
                DrawStyledHelpLine(dialogX + 2, dialogY + 1 + row, lines(idx), colors(idx), bgs(idx), viewW)
            Else
                ConsoleWriteText(dialogX + 2, dialogY + 1 + row, String(viewW, " "), helpFgText, helpBgText)
            End If
        Next row

        Dim maxTop As Integer = lineCount - viewH + 1
        If maxTop < 1 Then maxTop = 1
        Dim thumbLen As Integer = (viewH * viewH) \ lineCount
        If thumbLen < 1 Then thumbLen = 1
        If thumbLen > viewH Then thumbLen = viewH
        Dim freeTrack As Integer = viewH - thumbLen
        Dim thumbStart As Integer = 0
        If maxTop > 1 And freeTrack > 0 Then
            thumbStart = ((topLine - 1) * freeTrack) \ (maxTop - 1)
        End If

        For row = 0 To viewH - 1
            ConsoleSetCell(barX, dialogY + 1 + row, 176, 8, helpBgText)
        Next row
        For row = 0 To thumbLen - 1
            ConsoleSetCell(barX, dialogY + 1 + thumbStart + row, 219, 15, helpBgText)
        Next row

        Dim footer As String = "Esc fecha | Setas/PgUp/PgDn rola | Home/End inicio/fim"
        If indexCount > 0 Then footer &= " | 1-9 pula indice"
        ConsoleWriteText(dialogX + 2, dialogY + dialogH - 2, footer, 8, helpBgText, viewW)

        ConsoleSetCursor(1, 1, 0)
        ConsoleFlush()
        ConsoleEndFrame()

        Dim eventType As Integer
        Dim keyText As String
        Dim mouseX As Integer
        Dim mouseY As Integer
        Dim mouseAction As Integer

        If ConsolePollInput(eventType, keyText, mouseX, mouseY, mouseAction) = 0 Then
            Sleep 5, 1
            Continue Do
        End If

        If eventType <> MSX_INPUT_KEY Then Continue Do
        keyText = NormalizeKey(keyText)

        If keyText = Chr(27) Then Exit Do

        If Len(keyText) = 1 Then
            Dim c As Integer = Asc(keyText)
            If c >= 49 And c <= 57 Then
                Dim jumpIdx As Integer = c - 48
                If jumpIdx <= indexCount Then
                    topLine = indexTargets(jumpIdx)
                End If
            End If
            Continue Do
        End If

        If Len(keyText) = 2 And Asc(Left(keyText, 1)) = 0 Then
            Select Case Asc(Right(keyText, 1))
                Case 72
                    topLine -= 1
                Case 80
                    topLine += 1
                Case 73
                    topLine -= viewH
                Case 81
                    topLine += viewH
                Case 71
                    topLine = 1
                Case 79
                    topLine = lineCount - viewH + 1
            End Select
        End If

        If topLine < 1 Then topLine = 1
        maxTop = lineCount - viewH + 1
        If maxTop < 1 Then maxTop = 1
        If topLine > maxTop Then topLine = maxTop
    Loop

    forceFullRedraw = 1
    renderMode = RENDER_FULL
End Sub

Private Sub AddConfigField(fields() As ConfigField, ByRef count As Integer, ByRef keyName As String, ByRef label As String, ByVal kind As Integer, ByRef fallbackValue As String, ByRef hintText As String, ByRef optionsText As String = "", ByVal hasIntRange As Integer = 0, ByVal minInt As Integer = 0, ByVal maxInt As Integer = 0)
    count += 1
    If count = 1 Then
        ReDim fields(1 To 1)
    Else
        ReDim Preserve fields(1 To count)
    End If

    fields(count).keyName = keyName
    fields(count).label = label
    fields(count).kind = kind
    fields(count).value = DbGetSetting(keyName, fallbackValue)
    fields(count).defaultValue = fallbackValue
    fields(count).originalValue = fields(count).value
    fields(count).hint = hintText
    fields(count).options = optionsText
    fields(count).hasIntRange = hasIntRange
    fields(count).minInt = minInt
    fields(count).maxInt = maxInt
    fields(count).dirty = 0
End Sub

Private Function IsIntegerValue(ByRef txt As String) As Integer
    Dim t As String = Trim(txt)
    If Len(t) = 0 Then Return 0

    Dim i As Integer = 1
    If Left(t, 1) = "+" Or Left(t, 1) = "-" Then
        If Len(t) = 1 Then Return 0
        i = 2
    End If

    For i = i To Len(t)
        Dim c As Integer = Asc(Mid(t, i, 1))
        If c < 48 Or c > 57 Then Return 0
    Next i

    Return -1
End Function

Private Function NormalizeBoolText(ByRef txt As String, ByRef outValue As String) As Integer
    Dim t As String = LCase(Trim(txt))
    Select Case t
        Case "1", "true", "yes", "y", "on"
            outValue = "True"
            Return -1
        Case "0", "false", "no", "n", "off"
            outValue = "False"
            Return -1
    End Select
    Return 0
End Function

Private Function NormalizeMsxBasicConvertPrintValue(ByRef rawValue As String) As String
    Dim t As String = UCase(Trim(rawValue))
    If t = "?" Or t = "PRINT" Then Return t

    If t = "TRUE" Or t = "1" Or t = "YES" Or t = "Y" Or t = "ON" Then Return "?"
    If t = "FALSE" Or t = "0" Or t = "NO" Or t = "N" Or t = "OFF" Then Return "PRINT"

    Return "PRINT"
End Function

Private Function NormalizeMsxBasicThenGotoValue(ByRef rawValue As String) As String
    Dim t As String = UCase(Trim(rawValue))
    If t = "THEN" Or t = "GOTO" Then Return t

    If t = "TRUE" Or t = "1" Or t = "YES" Or t = "Y" Or t = "ON" Then Return "THEN"
    If t = "FALSE" Or t = "0" Or t = "NO" Or t = "N" Or t = "OFF" Then Return "GOTO"

    Return "THEN"
End Function

Private Function EnumContains(ByRef optionsText As String, ByRef candidate As String) As Integer
    Dim t As String = "|" & LCase(Trim(optionsText)) & "|"
    Dim c As String = "|" & LCase(Trim(candidate)) & "|"
    If InStr(t, c) > 0 Then Return -1
    Return 0
End Function

Private Function EnumAt(ByRef optionsText As String, ByVal idx As Integer) As String
    Dim p As Integer = 1
    Dim cur As Integer = 0
    Dim t As String = optionsText

    While p <= Len(t)
        Dim sep As Integer = InStr(p, t, "|")
        Dim part As String
        If sep = 0 Then
            part = Mid(t, p)
            p = Len(t) + 1
        Else
            part = Mid(t, p, sep - p)
            p = sep + 1
        End If

        part = Trim(part)
        If Len(part) > 0 Then
            cur += 1
            If cur = idx Then Return part
        End If
    Wend

    Return ""
End Function

Private Function EnumCount(ByRef optionsText As String) As Integer
    Dim idx As Integer = 1
    Dim n As Integer = 0
    While Len(EnumAt(optionsText, idx)) > 0
        n += 1
        idx += 1
    Wend
    Return n
End Function

Private Function EnumCycleValue(ByRef optionsText As String, ByRef currentValue As String, ByVal stepDir As Integer) As String
    Dim n As Integer = EnumCount(optionsText)
    If n <= 0 Then Return currentValue

    Dim i As Integer
    Dim found As Integer = 1
    For i = 1 To n
        If LCase(EnumAt(optionsText, i)) = LCase(Trim(currentValue)) Then
            found = i
            Exit For
        End If
    Next i

    Dim nextIdx As Integer = found + stepDir
    If nextIdx < 1 Then nextIdx = n
    If nextIdx > n Then nextIdx = 1
    Return EnumAt(optionsText, nextIdx)
End Function

Private Function ValidateConfigValue(ByVal kind As Integer, ByRef rawValue As String, ByRef optionsText As String, ByVal hasIntRange As Integer, ByVal minInt As Integer, ByVal maxInt As Integer, ByRef normalizedValue As String, ByRef errorText As String) As Integer
    normalizedValue = Trim(rawValue)
    errorText = ""

    Select Case kind
        Case CFG_KIND_BOOL
            If NormalizeBoolText(normalizedValue, normalizedValue) = 0 Then
                errorText = "Bool invalido. Use True/False, 1/0, yes/no."
                Return 0
            End If
        Case CFG_KIND_INT
            If IsIntegerValue(normalizedValue) = 0 Then
                errorText = "Numero inteiro invalido."
                Return 0
            End If
            If hasIntRange <> 0 Then
                Dim n As Integer = CInt(normalizedValue)
                If n < minInt Or n > maxInt Then
                    errorText = "Inteiro fora da faixa: " & Trim(Str(minInt)) & ".." & Trim(Str(maxInt))
                    Return 0
                End If
            End If
        Case CFG_KIND_ENUM
            If EnumContains(optionsText, normalizedValue) = 0 Then
                errorText = "Valor fora das opcoes permitidas."
                Return 0
            End If
        Case CFG_KIND_PATH
            If Len(normalizedValue) = 0 Then
                errorText = "Caminho nao pode ficar vazio."
                Return 0
            End If
    End Select

    Return -1
End Function

Private Sub RefreshFieldDirty(ByRef f As ConfigField)
    If LCase(Trim(f.value)) <> LCase(Trim(f.originalValue)) Then
        f.dirty = -1
    Else
        f.dirty = 0
    End If
End Sub

Private Function AnyConfigFieldDirty(fields() As ConfigField, ByVal fieldCount As Integer) As Integer
    Dim i As Integer
    For i = 1 To fieldCount
        If fields(i).dirty <> 0 Then Return -1
    Next i
    Return 0
End Function

Private Sub SaveConfigFields(fields() As ConfigField, ByVal fieldCount As Integer)
    Dim i As Integer
    For i = 1 To fieldCount
        DbSetSetting(fields(i).keyName, fields(i).value)
        fields(i).originalValue = fields(i).value
        fields(i).dirty = 0
    Next i
End Sub

Private Sub RestoreConfigDefaults(fields() As ConfigField, ByVal fieldCount As Integer)
    Dim i As Integer
    For i = 1 To fieldCount
        fields(i).value = fields(i).defaultValue
        If fields(i).kind = CFG_KIND_BOOL Then
            Dim norm As String
            If NormalizeBoolText(fields(i).value, norm) <> 0 Then
                fields(i).value = norm
            End If
        End If
        RefreshFieldDirty(fields(i))
    Next i
End Sub

Private Function PromptConfigExitAction(ByRef titleText As String) As Integer
    Dim dialogW As Integer = Clamp(uiW - 20, 46, 78)
    Dim dialogH As Integer = 7
    Dim dialogX As Integer = ((uiW - dialogW) \ 2) + 1
    Dim dialogY As Integer = ((uiH - dialogH) \ 2) + 1
    Dim selected As Integer = CFG_EXIT_CANCEL
    Dim result As Integer = CFG_EXIT_CANCEL

    Do
        ConsoleBeginFrame()
        DrawDesktop()
        DrawDocumentsFull()
        DrawMenuBar(MENU_VIEW_NONE)
        DrawStatusBar()

        ConsoleWriteText(dialogX, dialogY, Chr(201) & String(dialogW - 2, Chr(205)) & Chr(187), 15, 1)
        Dim i As Integer
        For i = 1 To dialogH - 2
            ConsoleWriteText(dialogX, dialogY + i, Chr(186) & String(dialogW - 2, " ") & Chr(186), 15, 1)
        Next i
        ConsoleWriteText(dialogX, dialogY + dialogH - 1, Chr(200) & String(dialogW - 2, Chr(205)) & Chr(188), 15, 1)

        ConsoleWriteText(dialogX + 2, dialogY, " Confirmar saida: " & titleText & " ", 0, 7, dialogW - 4)
        ConsoleWriteText(dialogX + 2, dialogY + 2, "Ha alteracoes nao salvas. O que deseja fazer?", 15, 1, dialogW - 4)

        Dim optSaveFg As UByte = IIf(selected = CFG_EXIT_SAVE, 0, 14)
        Dim optSaveBg As UByte = IIf(selected = CFG_EXIT_SAVE, 7, 1)
        Dim optDiscardFg As UByte = IIf(selected = CFG_EXIT_DISCARD, 0, 12)
        Dim optDiscardBg As UByte = IIf(selected = CFG_EXIT_DISCARD, 7, 1)
        Dim optCancelFg As UByte = IIf(selected = CFG_EXIT_CANCEL, 0, 11)
        Dim optCancelBg As UByte = IIf(selected = CFG_EXIT_CANCEL, 7, 1)

        ConsoleWriteText(dialogX + 2, dialogY + 3, "S Salvar", optSaveFg, optSaveBg)
        ConsoleWriteText(dialogX + 14, dialogY + 3, "D Descartar", optDiscardFg, optDiscardBg)
        ConsoleWriteText(dialogX + 30, dialogY + 3, "C Cancelar", optCancelFg, optCancelBg)
        ConsoleWriteText(dialogX + 2, dialogY + 5, "Setas escolhem | Enter confirma | Esc cancela", 8, 1, dialogW - 4)

        ConsoleSetCursor(1, 1, 0)
        ConsoleFlush()
        ConsoleEndFrame()

        Dim eventType As Integer
        Dim keyText As String
        Dim mouseX As Integer
        Dim mouseY As Integer
        Dim mouseAction As Integer

        If ConsolePollInput(eventType, keyText, mouseX, mouseY, mouseAction) = 0 Then
            Sleep 5, 1
            Continue Do
        End If

        If eventType <> MSX_INPUT_KEY Then Continue Do
        keyText = NormalizeKey(keyText)

        If keyText = Chr(27) Then
            result = CFG_EXIT_CANCEL
            Exit Do
        End If
        If Len(keyText) = 1 Then
            Select Case UCase(keyText)
                Case "S"
                    result = CFG_EXIT_SAVE
                    Exit Do
                Case "D"
                    result = CFG_EXIT_DISCARD
                    Exit Do
                Case "C"
                    result = CFG_EXIT_CANCEL
                    Exit Do
            End Select
        End If

        If keyText = Chr(13) Then
            result = selected
            Exit Do
        End If

        If Len(keyText) = 2 And Asc(Left(keyText, 1)) = 0 Then
            Select Case Asc(Right(keyText, 1))
                Case 75, 72
                    selected -= 1
                    If selected < CFG_EXIT_SAVE Then selected = CFG_EXIT_CANCEL
                Case 77, 80
                    selected += 1
                    If selected > CFG_EXIT_CANCEL Then selected = CFG_EXIT_SAVE
                Case 71
                    selected = CFG_EXIT_SAVE
                Case 79
                    selected = CFG_EXIT_CANCEL
            End Select
        End If
    Loop

    FinalizeModalInputState()
    Return result
End Function

Private Sub CompileDlgDraw(ByRef statusLine1 As String, ByVal statusColor1 As UByte, ByRef statusLine2 As String, ByVal statusColor2 As UByte, ByRef hintText As String)
    Dim x As Integer = gCompileDlgX
    Dim y As Integer = gCompileDlgY
    Dim w As Integer = gCompileDlgW
    Dim h As Integer = gCompileDlgH
    Dim logH As Integer = h - 6
    If logH < 1 Then logH = 1

    ConsoleBeginFrame()
    DrawDesktop()
    DrawDocumentsFull()
    DrawMenuBar(MENU_VIEW_NONE)
    DrawStatusBar()

    ConsoleWriteText(x, y, Chr(201) & String(w - 2, Chr(205)) & Chr(187), 15, 1)
    Dim i As Integer
    For i = 1 To h - 2
        ConsoleWriteText(x, y + i, Chr(186) & String(w - 2, " ") & Chr(186), 15, 1)
    Next i
    ConsoleWriteText(x, y + h - 1, Chr(200) & String(w - 2, Chr(205)) & Chr(188), 15, 1)

    ' Botao de fechar (quadradinho), igual as janelas de documento.
    ConsoleSetCell(x + 2, y, 254, 15, 1)

    Dim label As String = " " & gCompileDlgTitle & " "
    If Len(label) > w - 8 Then label = Left(label, w - 8)
    ConsoleWriteText(x + 4, y, label, 15, 1)

    Dim firstLine As Integer = gCompileDlgLineCount - logH + 1
    If firstLine < 1 Then firstLine = 1

    Dim row As Integer
    For row = 0 To logH - 1
        Dim lineIdx As Integer = firstLine + row
        Dim lineText As String = ""
        If lineIdx >= 1 And lineIdx <= gCompileDlgLineCount Then lineText = gCompileDlgLines(lineIdx)
        ConsoleWriteText(x + 2, y + 1 + row, Left(lineText & String(w - 4, " "), w - 4), 8, 1)
    Next row

    ConsoleWriteText(x + 2, y + 1 + logH, String(w - 4, Chr(196)), 8, 1)
    ConsoleWriteText(x + 2, y + 2 + logH, Left(statusLine1 & String(w - 4, " "), w - 4), statusColor1, 1)
    ConsoleWriteText(x + 2, y + 3 + logH, Left(statusLine2 & String(w - 4, " "), w - 4), statusColor2, 1)
    ConsoleWriteText(x + 2, y + 4 + logH, Left(hintText & String(w - 4, " "), w - 4), 8, 1)

    ConsoleSetCursor(1, 1, 0)
    ConsoleFlush()
    ConsoleEndFrame()
End Sub

Private Sub CompileDlgReset(ByRef titleText As String)
    gCompileDlgTitle = titleText
    gCompileDlgLineCount = 0
    gCompileDlgW = Clamp(uiW - 24, 44, 60)
    gCompileDlgH = 13
    gCompileDlgX = ((uiW - gCompileDlgW) \ 2) + 1
    gCompileDlgY = ((uiH - gCompileDlgH) \ 2) + 1
    gCompileDlgActive = -1

    ConsoleResetInputState()
    CompileDlgDraw("Processando...", 14, "", 7, "")
End Sub

Private Sub CompileDlgLog(ByRef lineText As String)
    If gCompileDlgActive = 0 Then Exit Sub

    If gCompileDlgLineCount < COMPILE_DLG_LOG_MAX Then
        gCompileDlgLineCount += 1
        gCompileDlgLines(gCompileDlgLineCount) = lineText
    Else
        Dim i As Integer
        For i = 1 To COMPILE_DLG_LOG_MAX - 1
            gCompileDlgLines(i) = gCompileDlgLines(i + 1)
        Next i
        gCompileDlgLines(COMPILE_DLG_LOG_MAX) = lineText
    End If

    CompileDlgDraw("Processando...", 14, "", 7, "")
    Sleep 30, 1
End Sub

Private Sub CompileDlgFinish(ByRef msg1 As String, ByRef msg2 As String, ByVal isSuccess As Integer)
    If gCompileDlgActive = 0 Then Exit Sub

    Dim statusColor As UByte = IIf(isSuccess <> 0, 10, 12)
    Dim hintText As String = "Enter / Esc / clique em [" & Chr(254) & "] fecha"

    ConsoleResetInputState()

    Do
        CompileDlgDraw(msg1, statusColor, msg2, 7, hintText)

        Dim eventType As Integer
        Dim keyText As String
        Dim mouseX As Integer
        Dim mouseY As Integer
        Dim mouseAction As Integer
        If ConsolePollInput(eventType, keyText, mouseX, mouseY, mouseAction) = 0 Then
            Sleep 5, 1
            Continue Do
        End If

        If eventType = MSX_INPUT_KEY Then
            keyText = NormalizeKey(keyText)
            If keyText = Chr(13) Or keyText = Chr(27) Then Exit Do
        ElseIf eventType = MSX_INPUT_MOUSE Then
            If mouseAction = MSX_MOUSE_DOWN Then
                If mouseY = gCompileDlgY And mouseX = gCompileDlgX + 2 Then Exit Do
            End If
        End If
    Loop

    gCompileDlgActive = 0
    forceFullRedraw = 1
    renderMode = RENDER_FULL
    FinalizeModalInputState()
End Sub

Private Sub ShowInfoDialog(ByRef titleText As String, ByRef msg1 As String, ByRef msg2 As String = "")
    Dim dialogW As Integer = Clamp(uiW - 12, 40, 90)
    Dim dialogH As Integer = 7
    Dim dialogX As Integer = ((uiW - dialogW) \ 2) + 1
    Dim dialogY As Integer = ((uiH - dialogH) \ 2) + 1

    Do
        ConsoleBeginFrame()
        DrawDesktop()
        DrawDocumentsFull()
        DrawMenuBar(MENU_VIEW_NONE)
        DrawStatusBar()

        ConsoleWriteText(dialogX, dialogY, Chr(201) & String(dialogW - 2, Chr(205)) & Chr(187), 15, 1)
        Dim i As Integer
        For i = 1 To dialogH - 2
            ConsoleWriteText(dialogX, dialogY + i, Chr(186) & String(dialogW - 2, " ") & Chr(186), 15, 1)
        Next i
        ConsoleWriteText(dialogX, dialogY + dialogH - 1, Chr(200) & String(dialogW - 2, Chr(205)) & Chr(188), 15, 1)

        ConsoleWriteText(dialogX + 2, dialogY, String(dialogW - 4, " "), 0, 7)
        ConsoleSetCell(dialogX + 2, dialogY, 254, 0, 7)
        ConsoleWriteText(dialogX + 4, dialogY, titleText, 0, 7, dialogW - 8)
        ConsoleWriteText(dialogX + 2, dialogY + 2, Left(msg1 & String(dialogW - 4, " "), dialogW - 4), 15, 1)
        ConsoleWriteText(dialogX + 2, dialogY + 3, Left(msg2 & String(dialogW - 4, " "), dialogW - 4), 11, 1)
        ConsoleWriteText(dialogX + 2, dialogY + 5, "Enter / Esc / clique em [" & Chr(254) & "] fecha", 8, 1)

        ConsoleSetCursor(1, 1, 0)
        ConsoleFlush()
        ConsoleEndFrame()

        Dim eventType As Integer
        Dim keyText As String
        Dim mouseX As Integer
        Dim mouseY As Integer
        Dim mouseAction As Integer
        If ConsolePollInput(eventType, keyText, mouseX, mouseY, mouseAction) = 0 Then
            Sleep 5, 1
            Continue Do
        End If
        If eventType = MSX_INPUT_KEY Then
            keyText = NormalizeKey(keyText)
            If keyText = Chr(13) Or keyText = Chr(27) Then Exit Do
        ElseIf eventType = MSX_INPUT_MOUSE Then
            If mouseAction = MSX_MOUSE_DOWN Then
                If mouseY = dialogY And mouseX = dialogX + 2 Then Exit Do
            End If
        End If
    Loop

    FinalizeModalInputState()
End Sub

Private Function GetExtLower(ByRef path As String) As String
    Dim p As Integer = InStrRev(path, ".")
    If p <= 0 Then Return ""
    Return LCase(Mid(path, p))
End Function

Private Function ChangeExt(ByRef path As String, ByRef newExt As String) As String
    Dim p As Integer = InStrRev(path, ".")
    If p <= 0 Then Return path & newExt
    Return Left(path, p - 1) & newExt
End Function

Private Function ToAbsolutePath(ByRef path As String) As String
    If Len(path) >= 2 And Mid(path, 2, 1) = ":" Then Return path
    If Len(path) >= 1 And (Left(path, 1) = Chr(92) Or Left(path, 1) = "/") Then Return path
    Return CurDir() & Chr(92) & path
End Function

' Retorna o diretorio de filePath incluindo a barra final (ou "" se nao houver
' separador). Usado para trocar o diretorio de trabalho antes de invocar
' ferramentas externas (ex.: asmsx) que resolvem nomes de saida contra o CWD.
Private Function PathDirOf(ByRef filePath As String) As String
    Dim lastSlash As Integer = InStrRev(filePath, Chr(92))
    Dim lastFwd As Integer = InStrRev(filePath, "/")
    If lastFwd > lastSlash Then lastSlash = lastFwd
    If lastSlash <= 0 Then Return ""
    Return Left(filePath, lastSlash)
End Function

Private Function Q(ByRef value As String) As String
    Return Chr(34) & value & Chr(34)
End Function

Private Function BaseNameNoExtOf(ByRef filePath As String) As String
    Dim dirPart As String = PathDirOf(filePath)
    Dim filePart As String = Mid(filePath, Len(dirPart) + 1)
    Dim dotPos As Integer = InStrRev(filePart, ".")
    If dotPos > 0 Then Return Left(filePart, dotPos - 1)
    Return filePart
End Function

' Converte um nome de arquivo num label valido de Basic Dignified (so
' letras, numeros e underscore, nao pode comecar com numero).
Private Function SanitizeLabelName(ByRef rawName As String) As String
    Dim outText As String = ""
    Dim i As Integer
    For i = 1 To Len(rawName)
        Dim c As Integer = Asc(Mid(rawName, i, 1))
        If (c >= 65 And c <= 90) Or (c >= 97 And c <= 122) Or (c >= 48 And c <= 57) Or c = 95 Then
            outText &= Chr(c)
        Else
            outText &= "_"
        End If
    Next i
    If Len(outText) = 0 Then outText = "asmrotina"
    If Asc(Left(outText, 1)) >= 48 And Asc(Left(outText, 1)) <= 57 Then outText = "r" & outText
    Return outText
End Function

Private Function CleanPathEntry(ByRef rawValue As String) As String
    Dim t As String = Trim(rawValue)
    If Len(t) >= 2 And Left(t, 1) = Chr(34) And Right(t, 1) = Chr(34) Then
        t = Mid(t, 2, Len(t) - 2)
    End If
    Return Trim(t)
End Function

Private Function CommandLineArg(ByRef rawValue As String) As String
    Dim value As String = CleanPathEntry(rawValue)
    If InStr(value, " ") = 0 And InStr(value, Chr(9)) = 0 Then Return value
    Return Q(value)
End Function

Private Function NormalizePathForDisplay(ByRef pathValue As String) As String
    Dim src As String = Trim(pathValue)
    If Len(src) = 0 Then Return ""

    Dim pathSep As String = Chr(92)
    Dim outText As String = ""
    Dim lastSep As Integer = 0
    Dim preserveUnc As Integer = IIf(Left(src, 2) = "\\", -1, 0)
    Dim i As Integer

    For i = 1 To Len(src)
        Dim ch As String = Mid(src, i, 1)
        If ch = "/" Then ch = pathSep

        If ch = pathSep Then
            If Len(outText) = 0 Then
                outText &= ch
                lastSep = -1
            ElseIf preserveUnc <> 0 And Len(outText) = 1 And Left(outText, 1) = pathSep Then
                outText &= ch
                lastSep = -1
            ElseIf lastSep = 0 Then
                outText &= ch
                lastSep = -1
            End If
        Else
            outText &= ch
            lastSep = 0
        End If
    Next i

    Return outText
End Function

Private Function FindExeInPath(ByRef exeName As String, ByRef outPath As String) As Integer
    outPath = ""
    Dim p As String = Environ("PATH")
    If Len(p) = 0 Then Return 0

    Dim i As Integer = 1
    Dim chunk As String = ""
    While i <= Len(p) + 1
        Dim ch As String = IIf(i <= Len(p), Mid(p, i, 1), ";")
        If ch = ";" Then
            Dim dirPart As String = CleanPathEntry(chunk)
            If Len(dirPart) > 0 Then
                Dim sep As String = Right(dirPart, 1)
                If sep <> "\\" And sep <> "/" Then dirPart &= "\\"
                Dim candidate As String = dirPart & exeName
                If Dir(candidate) <> "" Then
                    outPath = candidate
                    Return -1
                End If
            End If
            chunk = ""
        Else
            chunk &= ch
        End If
        i += 1
    Wend

    Return 0
End Function

Private Function ResolveOpenMsxPath(ByRef resolvedPath As String) As Integer
    resolvedPath = ""

    Dim emuPath As String = Trim(DbGetSetting("cfg.emulator.windows.emulator_path", ""))
    If Len(emuPath) = 0 Then emuPath = Trim(DbGetSetting("cfg.emulator.emulator_path", ""))
    emuPath = CleanPathEntry(emuPath)

    If Len(emuPath) > 0 Then
        Dim up As String = UCase(emuPath)
        If Left(up, 7) <> "PATH_TO" Then
            Dim candidate As String = ToAbsolutePath(emuPath)
            If Dir(candidate) <> "" Then
                resolvedPath = candidate
                Return -1
            End If
        End If
    End If

    If FindExeInPath("openmsx.exe", resolvedPath) <> 0 Then Return -1
    If FindExeInPath("openmsx", resolvedPath) <> 0 Then Return -1

    Return 0
End Function

Private Function ResolveAsmsxPath(ByRef resolvedPath As String) As Integer
    resolvedPath = ""

    Dim cfgPath As String = CleanPathEntry(Trim(DbGetSetting("cfg.assembler.asmsx_path", "")))
    If Len(cfgPath) > 0 Then
        Dim candidate As String = ToAbsolutePath(cfgPath)
        If Dir(candidate) <> "" Then
            resolvedPath = candidate
            Return -1
        End If
    End If

    Dim bundled As String = ToAbsolutePath("asmsx" & Chr(92) & "asmsx.exe")
    If Dir(bundled) <> "" Then
        resolvedPath = bundled
        Return -1
    End If

    If FindExeInPath("asmsx.exe", resolvedPath) <> 0 Then Return -1
    If FindExeInPath("asmsx", resolvedPath) <> 0 Then Return -1

    Return 0
End Function

' Lista todas as janelas de programa Basic Dignified (.dmx/.bad) ja abertas,
' ideal para oferecer "incluir a chamada da rotina asMSX nesse arquivo".
' Varre de tras pra frente (docCount ate 1) pra listar a mais recentemente
' usada primeiro, excluindo o documento indicado (o .asm recem montado).
Private Sub CollectOpenBasicDocs(ByVal excludeDocIndex As Integer, candidates() As Integer, ByRef candidateCount As Integer)
    candidateCount = 0
    Dim i As Integer
    For i = docCount To 1 Step -1
        If i <> excludeDocIndex Then
            If docs(i).isHelp = 0 Then
                Dim ext As String = GetExtLower(docs(i).filePath)
                If ext = ".dmx" Or ext = ".bad" Then
                    candidateCount += 1
                    If candidateCount <= UBound(candidates) Then candidates(candidateCount) = i
                End If
            End If
        End If
    Next i
End Sub

' Deixa o usuario escolher em qual das janelas BASIC abertas incluir a
' chamada da rotina, quando ha mais de uma candidata. Retorna o indice em
' docs() escolhido, ou 0 se cancelado.
Private Function PromptPickBasicDoc(candidates() As Integer, ByVal candidateCount As Integer) As Integer
    If candidateCount <= 0 Then Return 0

    Dim dialogW As Integer = Clamp(uiW - 16, 50, 84)
    Dim dialogH As Integer = candidateCount + 7
    Dim dialogX As Integer = ((uiW - dialogW) \ 2) + 1
    Dim dialogY As Integer = ((uiH - dialogH) \ 2) + 1
    Dim selected As Integer = 1
    Dim result As Integer = 0

    Do
        ConsoleBeginFrame()
        DrawDesktop()
        DrawDocumentsFull()
        DrawMenuBar(MENU_VIEW_NONE)
        DrawStatusBar()

        ConsoleWriteText(dialogX, dialogY, Chr(201) & String(dialogW - 2, Chr(205)) & Chr(187), 15, 1)
        Dim i As Integer
        For i = 1 To dialogH - 2
            ConsoleWriteText(dialogX, dialogY + i, Chr(186) & String(dialogW - 2, " ") & Chr(186), 15, 1)
        Next i
        ConsoleWriteText(dialogX, dialogY + dialogH - 1, Chr(200) & String(dialogW - 2, Chr(205)) & Chr(188), 15, 1)

        ConsoleWriteText(dialogX + 2, dialogY, String(dialogW - 4, " "), 0, 7)
        ConsoleSetCell(dialogX + 2, dialogY, 254, 0, 7)
        ConsoleWriteText(dialogX + 4, dialogY, "Incluir em qual arquivo?", 0, 7, dialogW - 8)
        ConsoleWriteText(dialogX + 2, dialogY + 2, "Ha mais de um BASIC aberto. Escolha o destino:", 15, 1, dialogW - 4)

        For i = 1 To candidateCount
            Dim itemFg As UByte = IIf(i = selected, 0, 10)
            Dim itemBg As UByte = IIf(i = selected, 7, 1)
            Dim itemText As String = Trim(Str(i)) & " " & docs(candidates(i)).title
            ConsoleWriteText(dialogX + 2, dialogY + 3 + i, itemText, itemFg, itemBg, dialogW - 4)
        Next i

        ConsoleWriteText(dialogX + 2, dialogY + dialogH - 2, "Numero ou setas + Enter | Esc cancela", 8, 1, dialogW - 4)

        ConsoleSetCursor(1, 1, 0)
        ConsoleFlush()
        ConsoleEndFrame()

        Dim eventType As Integer
        Dim keyText As String
        Dim mouseX As Integer
        Dim mouseY As Integer
        Dim mouseAction As Integer

        If ConsolePollInput(eventType, keyText, mouseX, mouseY, mouseAction) = 0 Then
            Sleep 5, 1
            Continue Do
        End If

        If eventType = MSX_INPUT_KEY Then
            keyText = NormalizeKey(keyText)

            If keyText = Chr(27) Then
                result = 0
                Exit Do
            End If
            If keyText = Chr(13) Then
                result = candidates(selected)
                Exit Do
            End If
            If Len(keyText) = 1 And keyText >= "1" And keyText <= "9" Then
                Dim picked As Integer = Val(keyText)
                If picked >= 1 And picked <= candidateCount Then
                    result = candidates(picked)
                    Exit Do
                End If
            End If
            If Len(keyText) = 2 And Asc(Left(keyText, 1)) = 0 Then
                Select Case Asc(Right(keyText, 1))
                    Case 75, 72
                        selected -= 1
                        If selected < 1 Then selected = candidateCount
                    Case 77, 80
                        selected += 1
                        If selected > candidateCount Then selected = 1
                End Select
            End If
        ElseIf eventType = MSX_INPUT_MOUSE Then
            If mouseAction = MSX_MOUSE_DOWN Then
                If mouseY = dialogY And mouseX = dialogX + 2 Then
                    result = 0
                    Exit Do
                End If
                If mouseY >= dialogY + 4 And mouseY <= dialogY + 3 + candidateCount Then
                    result = candidates(mouseY - (dialogY + 3))
                    Exit Do
                End If
            End If
        End If
    Loop

    FinalizeModalInputState()
    Return result
End Function

Private Function DocHasLabel(ByRef d As Document, ByRef tag As String) As Integer
    Dim i As Integer
    For i = 1 To d.lineCount
        If InStr(d.lines(i), tag) > 0 Then Return -1
    Next i
    Return 0
End Function

Private Function UniqueLabelForDoc(ByRef d As Document, ByRef baseLabel As String) As String
    Dim candidate As String = baseLabel
    Dim suffix As Integer = 1
    Dim tag As String = "{" & candidate & "}"
    While DocHasLabel(d, tag) <> 0
        suffix += 1
        candidate = baseLabel & "_" & Trim(Str(suffix))
        tag = "{" & candidate & "}"
    Wend
    Return candidate
End Function

' Insere "gosub {labelName}" bem no inicio do programa, logo apos qualquer
' bloco de gosubs de rotinas asm ja inseridos anteriormente (pra empilhar
' varias rotinas em sequencia, uma apos a outra, sem perder a ordem de
' insercao) e antes do resto do codigo original do usuario.
Private Sub InsertGosubAtTop(ByRef d As Document, ByRef labelName As String)
    If d.lineCount >= MAX_LINES Then Exit Sub

    Dim insertPos As Integer = 0
    Dim i As Integer
    For i = 1 To d.lineCount
        If Left(LCase(Trim(d.lines(i))), 7) = "gosub {" Then
            insertPos = i
        Else
            Exit For
        End If
    Next i

    Dim j As Integer
    For j = d.lineCount To insertPos + 1 Step -1
        d.lines(j + 1) = d.lines(j)
    Next j
    d.lines(insertPos + 1) = "gosub {" & labelName & "}"
    d.lineCount += 1
End Sub

' Acha o proximo indice DEFUSR livre (1-9) no documento, olhando pro maior
' DEFUSRn ja usado no texto. MSX-Basic so tem USR0-USR9.
Private Function NextUsrIndexForDoc(ByRef d As Document) As Integer
    Dim maxUsed As Integer = 0
    Dim i As Integer
    For i = 1 To d.lineCount
        Dim upLine As String = UCase(d.lines(i))
        Dim p As Integer = InStr(upLine, "DEFUSR")
        While p > 0
            Dim digitPos As Integer = p + 6
            If digitPos <= Len(upLine) Then
                Dim ch As String = Mid(upLine, digitPos, 1)
                If ch >= "0" And ch <= "9" Then
                    Dim n As Integer = Val(ch)
                    If n > maxUsed Then maxUsed = n
                End If
            End If
            p = InStr(p + 6, upLine, "DEFUSR")
        Wend
    Next i
    Return maxUsed + 1
End Function

Private Function PromptAsmLoaderChoice(ByVal hasBasicTarget As Integer) As Integer
    Dim dialogW As Integer = Clamp(uiW - 16, 50, 84)
    Dim dialogH As Integer = 11
    Dim dialogX As Integer = ((uiW - dialogW) \ 2) + 1
    Dim dialogY As Integer = ((uiH - dialogH) \ 2) + 1
    Dim selected As Integer = ASM_LOADER_INC
    Dim result As Integer = ASM_LOADER_NONE

    Do
        ConsoleBeginFrame()
        DrawDesktop()
        DrawDocumentsFull()
        DrawMenuBar(MENU_VIEW_NONE)
        DrawStatusBar()

        ConsoleWriteText(dialogX, dialogY, Chr(201) & String(dialogW - 2, Chr(205)) & Chr(187), 15, 1)
        Dim i As Integer
        For i = 1 To dialogH - 2
            ConsoleWriteText(dialogX, dialogY + i, Chr(186) & String(dialogW - 2, " ") & Chr(186), 15, 1)
        Next i
        ConsoleWriteText(dialogX, dialogY + dialogH - 1, Chr(200) & String(dialogW - 2, Chr(205)) & Chr(188), 15, 1)

        ConsoleWriteText(dialogX + 2, dialogY, String(dialogW - 4, " "), 0, 7)
        ConsoleSetCell(dialogX + 2, dialogY, 254, 0, 7)
        ConsoleWriteText(dialogX + 4, dialogY, "Rotina montada", 0, 7, dialogW - 8)
        ConsoleWriteText(dialogX + 2, dialogY + 2, "O que deseja fazer com a rotina?", 15, 1, dialogW - 4)

        Dim bloadDim As UByte = IIf(hasBasicTarget <> 0, 14, 8)
        Dim dataDim As UByte = IIf(hasBasicTarget <> 0, 10, 8)
        Dim optBloadFg As UByte = IIf(selected = ASM_LOADER_BLOAD And hasBasicTarget <> 0, 0, bloadDim)
        Dim optBloadBg As UByte = IIf(selected = ASM_LOADER_BLOAD And hasBasicTarget <> 0, 7, 1)
        Dim optDataFg As UByte = IIf(selected = ASM_LOADER_DATA And hasBasicTarget <> 0, 0, dataDim)
        Dim optDataBg As UByte = IIf(selected = ASM_LOADER_DATA And hasBasicTarget <> 0, 7, 1)
        Dim optIncFg As UByte = IIf(selected = ASM_LOADER_INC, 0, 13)
        Dim optIncBg As UByte = IIf(selected = ASM_LOADER_INC, 7, 1)
        Dim optNoneFg As UByte = IIf(selected = ASM_LOADER_NONE, 0, 11)
        Dim optNoneBg As UByte = IIf(selected = ASM_LOADER_NONE, 7, 1)

        Dim bloadLabel As String = "B BLOAD (usa o .bin externo)"
        Dim dataLabel As String = "C Carregador (embute os bytes via DATA)"
        If hasBasicTarget = 0 Then
            bloadLabel &= " - nenhum BASIC aberto"
            dataLabel &= " - nenhum BASIC aberto"
        End If

        ConsoleWriteText(dialogX + 2, dialogY + 4, bloadLabel, optBloadFg, optBloadBg, dialogW - 4)
        ConsoleWriteText(dialogX + 2, dialogY + 5, dataLabel, optDataFg, optDataBg, dialogW - 4)
        ConsoleWriteText(dialogX + 2, dialogY + 6, "I Gerar .INC (pra incluir em outro ASM)", optIncFg, optIncBg, dialogW - 4)
        ConsoleWriteText(dialogX + 2, dialogY + 7, "N Nao incluir", optNoneFg, optNoneBg, dialogW - 4)
        ConsoleWriteText(dialogX + 2, dialogY + 9, "Setas escolhem | Enter confirma | Esc = Nao incluir", 8, 1, dialogW - 4)

        ConsoleSetCursor(1, 1, 0)
        ConsoleFlush()
        ConsoleEndFrame()

        Dim eventType As Integer
        Dim keyText As String
        Dim mouseX As Integer
        Dim mouseY As Integer
        Dim mouseAction As Integer

        If ConsolePollInput(eventType, keyText, mouseX, mouseY, mouseAction) = 0 Then
            Sleep 5, 1
            Continue Do
        End If

        If eventType = MSX_INPUT_KEY Then
            keyText = NormalizeKey(keyText)

            If keyText = Chr(27) Then
                result = ASM_LOADER_NONE
                Exit Do
            End If
            If keyText = Chr(13) Then
                result = selected
                Exit Do
            End If
            If Len(keyText) = 1 Then
                Select Case UCase(keyText)
                    Case "B"
                        If hasBasicTarget <> 0 Then
                            result = ASM_LOADER_BLOAD
                            Exit Do
                        End If
                    Case "C"
                        If hasBasicTarget <> 0 Then
                            result = ASM_LOADER_DATA
                            Exit Do
                        End If
                    Case "I"
                        result = ASM_LOADER_INC
                        Exit Do
                    Case "N"
                        result = ASM_LOADER_NONE
                        Exit Do
                End Select
            End If
            If Len(keyText) = 2 And Asc(Left(keyText, 1)) = 0 Then
                Select Case Asc(Right(keyText, 1))
                    Case 75, 72
                        Do
                            selected -= 1
                            If selected < ASM_LOADER_NONE Then selected = ASM_LOADER_INC
                        Loop While selected <> ASM_LOADER_INC And selected <> ASM_LOADER_NONE And hasBasicTarget = 0
                    Case 77, 80
                        Do
                            selected += 1
                            If selected > ASM_LOADER_INC Then selected = ASM_LOADER_NONE
                        Loop While selected <> ASM_LOADER_INC And selected <> ASM_LOADER_NONE And hasBasicTarget = 0
                End Select
            End If
        ElseIf eventType = MSX_INPUT_MOUSE Then
            If mouseAction = MSX_MOUSE_DOWN Then
                If mouseY = dialogY And mouseX = dialogX + 2 Then
                    result = ASM_LOADER_NONE
                    Exit Do
                End If
                If mouseY = dialogY + 4 And hasBasicTarget <> 0 Then
                    result = ASM_LOADER_BLOAD
                    Exit Do
                ElseIf mouseY = dialogY + 5 And hasBasicTarget <> 0 Then
                    result = ASM_LOADER_DATA
                    Exit Do
                ElseIf mouseY = dialogY + 6 Then
                    result = ASM_LOADER_INC
                    Exit Do
                ElseIf mouseY = dialogY + 7 Then
                    result = ASM_LOADER_NONE
                    Exit Do
                End If
            End If
        End If
    Loop

    FinalizeModalInputState()
    Return result
End Function

Private Function DbBoolSetting(ByRef keyName As String, ByVal fallbackValue As Integer = 0) As Integer
    Dim fb As String = IIf(fallbackValue <> 0, "True", "False")
    Dim rawValue As String = LCase(Trim(DbGetSetting(keyName, fb)))

    Select Case rawValue
        Case "1", "true", "yes", "on", "y"
            Return -1
        Case "0", "false", "no", "off", "n"
            Return 0
        Case Else
            Return fallbackValue
    End Select
End Function

Private Function BuildOpenMsxLaunchArgs(ByRef diskPath As String) As String
    Dim outArgs As String = ""

    Dim settingFile As String = Trim(DbGetSetting("cfg.emulator.setting", ""))
    If Len(settingFile) > 0 Then outArgs &= " -setting " & CommandLineArg(settingFile)

    Dim machineName As String = Trim(DbGetSetting("cfg.emulator.machine", ""))
    If Len(machineName) > 0 Then outArgs &= " -machine " & CommandLineArg(machineName)

    Dim extensionName As String = Trim(DbGetSetting("cfg.emulator.extension", ""))
    If Len(extensionName) > 0 Then outArgs &= " -ext " & CommandLineArg(extensionName)

    If DbBoolSetting("cfg.emulator.nothrottle", 0) <> 0 Then outArgs &= " -no-throttle"
    If DbBoolSetting("cfg.emulator.monitor", 0) <> 0 Then
        Dim scriptPath As String = "basic-dignified\\msx\\openmsx_output.tcl"
        If Dir(scriptPath) <> "" Then outArgs &= " -script " & CommandLineArg(ToAbsolutePath(scriptPath))
    End If

    outArgs &= " -diska " & CommandLineArg(diskPath)
    Return outArgs
End Function

Sub CompileActiveDocument(ByVal compileMode As Integer)
    If activeDoc < 1 Or activeDoc > docCount Then Exit Sub
    Dim ByRef d As Document = docs(activeDoc)

    CompileDlgReset("Compilar")
    CompileDebugLog("compile", "start mode=" & Trim(Str(compileMode)) & " file=" & d.filePath)

    If d.isHelp <> 0 Then
        CompileDlgFinish("Ajuda nao pode ser compilada.", "", 0)
        Exit Sub
    End If

    If Left(LCase(d.filePath), 4) = "cfg:" Then
        CompileDlgFinish("Tela de configuracao nao pode ser compilada.", "", 0)
        Exit Sub
    End If

    SaveActiveDocumentToDisk()

    Dim srcPath As String = ToAbsolutePath(d.filePath)
    Dim ext As String = GetExtLower(srcPath)
    Dim srcPathDisp As String = NormalizePathForDisplay(srcPath)
    Dim modeLabel As String
    Dim amxOut As String = ""
    Dim bmxOut As String = ""
    Dim errMsg As String = ""
    Dim rc As Integer = 0
    CompileDebugLog("compile", "resolved src=" & srcPathDisp & " ext=" & ext)

    If ext = ".asm" Then
        If compileMode <> COMPILE_MODE_RUN_EMU Then
            CompileDlgFinish("Arquivos .asm sao montados com Compilar e Executar (E).", "", 0)
            Exit Sub
        End If

        Dim asmsxPath As String = ""
        If ResolveAsmsxPath(asmsxPath) = 0 Then
            CompileDlgFinish("asmsx nao encontrado.", "Configure cfg.assembler.asmsx_path, coloque asmsx.exe em asmsx\ ou inclua no PATH.", 0)
            Exit Sub
        End If

        Dim srcDir As String = PathDirOf(srcPath)
        Dim srcFile As String = Mid(srcPath, Len(srcDir) + 1)
        Dim origDir As String = CurDir()

        ChDir srcDir
        Dim asmCmd As String = CommandLineArg(asmsxPath) & " " & CommandLineArg(srcFile)
        Dim asmRc As Integer = Shell(asmCmd)
        ChDir origDir
        CompileDebugLog("compile", "asmsx rc=" & Trim(Str(asmRc)) & " cmd=" & NormalizePathForDisplay(asmCmd) & " cwd=" & NormalizePathForDisplay(srcDir))

        Dim binOut As String = ChangeExt(srcPath, ".bin")
        If Dir(binOut) = "" Then
            CompileDlgFinish("Falha ao montar com asmsx.", "Nao gerou " & NormalizePathForDisplay(binOut) & ". Veja o log: " & CompileDebugLogPath(), 0)
            Exit Sub
        End If

        Dim binOutDisp As String = NormalizePathForDisplay(binOut)

        ' Oferece o que fazer com a rotina montada: incluir num BASIC aberto
        ' (BLOAD ou carregador embutido via DATA/READ/POKE, escolhendo o
        ' arquivo se houver mais de um .dmx/.bad aberto), gerar um .inc pra
        ' incluir em outro programa asm, ou nao fazer nada.
        Dim loaderNote As String = ""
        Dim basicCandidates(1 To MAX_DOCS) As Integer
        Dim basicCandidateCount As Integer = 0
        CollectOpenBasicDocs(activeDoc, basicCandidates(), basicCandidateCount)

        Dim loaderChoice As Integer = PromptAsmLoaderChoice(IIf(basicCandidateCount > 0, -1, 0))

        If loaderChoice = ASM_LOADER_INC Then
            Dim labelBaseInc As String = SanitizeLabelName(BaseNameNoExtOf(srcPath))
            Dim incPath As String = ""
            Dim incErr As String = ""
            If CompilerBuildAsmIncFile(binOut, srcPath, labelBaseInc, incPath, incErr) = 0 Then
                loaderNote = " | Falha ao gerar .inc: " & incErr
                CompileDebugLog("compile", "asm inc gen fail err=" & incErr)
            Else
                loaderNote = " | Gerado: " & NormalizePathForDisplay(incPath)
                CompileDebugLog("compile", "asm inc generated: " & incPath)
            End If
        ElseIf loaderChoice = ASM_LOADER_BLOAD Or loaderChoice = ASM_LOADER_DATA Then
            Dim targetDocIdx As Integer = 0
            If basicCandidateCount = 1 Then
                targetDocIdx = basicCandidates(1)
            ElseIf basicCandidateCount > 1 Then
                targetDocIdx = PromptPickBasicDoc(basicCandidates(), basicCandidateCount)
            End If

            If targetDocIdx > 0 Then
                Dim ByRef targetDoc As Document = docs(targetDocIdx)
                Dim usrIdx As Integer = NextUsrIndexForDoc(targetDoc)
                If usrIdx > 9 Then
                    loaderNote = " | Nao incluido em " & targetDoc.title & ": DEFUSR0-9 ja em uso"
                    CompileDebugLog("compile", "asm loader skipped: no DEFUSR slot free in " & targetDoc.title)
                Else
                    Dim labelBase As String = SanitizeLabelName(BaseNameNoExtOf(srcPath))
                    Dim labelName As String = UniqueLabelForDoc(targetDoc, labelBase)
                    Dim loaderErr As String = ""
                    Dim loaderCode As String = ""
                    Dim loaderOk As Integer = 0

                    If loaderChoice = ASM_LOADER_DATA Then
                        loaderOk = CompilerBuildAsmDataLoader(binOut, labelName, usrIdx, loaderCode, loaderErr)
                    Else
                        Dim startA As Integer
                        Dim endA As Integer
                        Dim execA As Integer
                        loaderOk = CompilerReadAsmBinInfo(binOut, startA, endA, execA, loaderErr)
                        If loaderOk <> 0 Then
                            Dim binBaseName As String = UCase(Left(BaseNameNoExtOf(srcPath), 8))
                            Dim usrTag As String = "USR" & Trim(Str(usrIdx))
                            Dim ind As String = "    "
                            loaderCode = "{" & labelName & "}" & Chr(10)
                            loaderCode &= ind & "' Chame com: A=" & usrTag & "(0)  ou  PRINT " & usrTag & "(0)" & Chr(10)
                            loaderCode &= ind & "bload " & Chr(34) & binBaseName & ".BIN" & Chr(34) & Chr(10)
                            loaderCode &= ind & "defusr" & Trim(Str(usrIdx)) & " = &H" & Hex(execA) & Chr(10)
                            loaderCode &= ind & "return" & Chr(10)
                        End If
                    End If

                    If loaderOk = 0 Then
                        loaderNote = " | Falha ao gerar carregador: " & loaderErr
                        CompileDebugLog("compile", "asm loader gen fail err=" & loaderErr)
                    Else
                        InsertGosubAtTop(targetDoc, labelName)
                        AppendDocTextLines(targetDoc, loaderCode)
                        SaveDocumentToDisk(targetDoc)
                        forceFullRedraw = 1
                        renderMode = RENDER_FULL
                        loaderNote = " | Incluido em " & targetDoc.title & ": {" & labelName & "} DEFUSR" & Trim(Str(usrIdx))
                        CompileDebugLog("compile", "asm loader added to " & targetDoc.title & " label=" & labelName & " usr=" & Trim(Str(usrIdx)))
                    End If
                End If
            End If
        End If

        Dim emuPathAsm As String = ""
        If ResolveOpenMsxPath(emuPathAsm) <> 0 Then
            Dim diskPathAsm As String = ""
            Dim cleanDiskDirAsm As Integer = DbBoolSetting("cfg.emulator.clean_disk_dir", 0)
            If CompilerBuildAsmRunDisk(srcPath, binOut, diskPathAsm, errMsg, cleanDiskDirAsm) = 0 Then
                Dim msgA As String = errMsg
                If Len(Trim(msgA)) = 0 Then msgA = "Sem detalhes no retorno. Veja log: " & CompileDebugLogPath()
                CompileDebugLog("compile", "asm disk build fail err=" & msgA)
                CompileDlgFinish("Falha ao montar disco de execucao", msgA, 0)
                Exit Sub
            End If

            Dim diskPathAsmDisp As String = NormalizePathForDisplay(diskPathAsm)
            Dim runCmdAsm As String = CommandLineArg(emuPathAsm) & BuildOpenMsxLaunchArgs(diskPathAsm)
            Dim runRcAsm As Integer = Shell(runCmdAsm)
            CompileDebugLog("compile", "asm run emu rc=" & Trim(Str(runRcAsm)) & " cmd=" & NormalizePathForDisplay(runCmdAsm))

            Dim msg2Asm As String
            If runRcAsm = 0 Then
                msg2Asm = "Gerado: " & binOutDisp & " | Disco: " & diskPathAsmDisp & " | openMSX iniciado" & loaderNote
            Else
                msg2Asm = "Gerado: " & binOutDisp & " | Falha ao iniciar openMSX" & loaderNote
            End If
            CompileDebugLog("compile", "asm success msg2=" & msg2Asm)
            CompileDlgFinish("OK: asMSX Montar e Executar", msg2Asm, 1)
        Else
            CompileDlgFinish("OK: asMSX Montar e Executar", "Gerado: " & binOutDisp & " | openMSX nao encontrado (configure cfg.emulator.windows.emulator_path ou inclua no PATH)" & loaderNote, 1)
        End If

        Exit Sub
    End If

    If compileMode = COMPILE_MODE_TOKENIZE_AMX Then
        modeLabel = "Tokenizar AMX"
        If ext <> ".amx" And ext <> ".asc" Then
            CompileDlgFinish("Abra um arquivo .amx/.asc para tokenizar.", "", 0)
            Exit Sub
        End If
        rc = CompilerTokenizeAmx(srcPath, bmxOut, errMsg)
        amxOut = srcPath
    ElseIf compileMode = COMPILE_MODE_DIGNIFIED Then
        modeLabel = "Basic Dignified"
        If ext = ".amx" Or ext = ".asc" Then
            CompileDlgFinish("Use este modo com fonte .dmx/.bad.", "", 0)
            Exit Sub
        End If
        rc = CompilerCompileToAmx(srcPath, amxOut, errMsg)
    ElseIf compileMode = COMPILE_MODE_RUN_EMU Then
        modeLabel = "Compilar e Executar"
        rc = CompilerCompileToBmx(srcPath, amxOut, bmxOut, errMsg)
    Else
        modeLabel = "MSX-Basic"
        rc = CompilerCompileToBmx(srcPath, amxOut, bmxOut, errMsg)
    End If
    Dim amxOutDisp As String = NormalizePathForDisplay(amxOut)
    Dim bmxOutDisp As String = NormalizePathForDisplay(bmxOut)
    CompileDebugLog("compile", "modeLabel=" & modeLabel & " rc=" & Trim(Str(rc)) & " err=" & errMsg & " amxOut=" & amxOutDisp & " bmxOut=" & bmxOutDisp)

    If rc = 0 Then
        Dim msg1 As String = "Falha ao compilar."
        Dim msg2 As String = errMsg
        If Len(Trim(msg2)) = 0 Then msg2 = "Sem detalhes no retorno. Veja log: " & CompileDebugLogPath()
        CompileDebugLog("compile", "fail shown msg2=" & msg2)
        CompileDlgFinish(msg1, msg2, 0)
        Exit Sub
    End If

    Dim msg1 As String
    Dim msg2 As String
    If compileMode = COMPILE_MODE_DIGNIFIED Then
        msg1 = "OK: " & modeLabel
        msg2 = "Gerado: " & amxOutDisp
    ElseIf compileMode = COMPILE_MODE_TOKENIZE_AMX Then
        msg1 = "OK: " & modeLabel
        msg2 = "Gerado: " & NormalizePathForDisplay(ChangeExt(srcPath, ".bmx"))
    ElseIf compileMode = COMPILE_MODE_RUN_EMU Then
        Dim emuPath As String = ""
        If ResolveOpenMsxPath(emuPath) <> 0 Then
            Dim diskPath As String = ""
            Dim cleanDiskDir As Integer = DbBoolSetting("cfg.emulator.clean_disk_dir", 0)
            If CompilerBuildRunDisk(srcPath, amxOut, bmxOut, diskPath, errMsg, cleanDiskDir) = 0 Then
                msg1 = "Falha ao montar disco de execucao"
                msg2 = errMsg
                If Len(Trim(msg2)) = 0 Then msg2 = "Sem detalhes no retorno. Veja log: " & CompileDebugLogPath()
                CompileDebugLog("compile", "disk build fail err=" & msg2)
                CompileDlgFinish(msg1, msg2, 0)
                Exit Sub
            End If

            Dim diskPathDisp As String = NormalizePathForDisplay(diskPath)
            Dim runCmd As String = CommandLineArg(emuPath) & BuildOpenMsxLaunchArgs(diskPath)
            Dim runRc As Integer = Shell(runCmd)
            CompileDebugLog("compile", "run emu rc=" & Trim(Str(runRc)) & " cmd=" & NormalizePathForDisplay(runCmd))
            msg1 = "OK: " & modeLabel
            If runRc = 0 Then
                msg2 = "Gerados: " & amxOutDisp & " e " & bmxOutDisp & " | Disco: " & diskPathDisp & " | openMSX iniciado"
            Else
                msg2 = "Gerados: " & amxOutDisp & " e " & bmxOutDisp & " | Falha ao iniciar openMSX"
            End If
        Else
            msg1 = "OK: " & modeLabel
            msg2 = "Gerados: " & amxOutDisp & " e " & NormalizePathForDisplay(ChangeExt(srcPath, ".bmx")) & " | openMSX nao encontrado (configure cfg.emulator.windows.emulator_path ou inclua no PATH)"
        End If
    Else
        msg1 = "OK: " & modeLabel
        msg2 = "Gerados: " & amxOutDisp & " e " & NormalizePathForDisplay(ChangeExt(srcPath, ".bmx"))
    End If
    CompileDebugLog("compile", "success msg1=" & msg1 & " msg2=" & msg2)
    CompileDlgFinish(msg1, msg2, 1)
End Sub

Private Function MamuteCellTypeLabel(ByVal cellType As Integer) As String
    Select Case cellType
        Case MAMUTE_CELL_RAM
            Return "RAM"
        Case MAMUTE_CELL_ROM
            Return "ROM"
        Case MAMUTE_CELL_BIOS
            Return "BIOS"
        Case MAMUTE_CELL_BASIC
            Return "BASIC"
        Case MAMUTE_CELL_EXTBIOS
            Return "EXTBIOS"
    End Select
    Return "."
End Function

Private Sub LoadMamuteMemConfig()
    Dim slot As Integer
    Dim subIdx As Integer
    Dim pageIdx As Integer

    For slot = 0 To 3
        Dim subKey As String = "cfg.mamute.mem.slot" & Trim(Str(slot)) & ".subslots"
        MamuteMemSubOn(slot) = IIf(LCase(DbGetSetting(subKey, "False")) = "true", -1, 0)

        For subIdx = 0 To 3
            For pageIdx = 0 To 3
                Dim prefix As String = "cfg.mamute.mem.slot" & Trim(Str(slot)) & ".sub" & Trim(Str(subIdx)) & ".page" & Trim(Str(pageIdx)) & "."
                Dim typeText As String = LCase(DbGetSetting(prefix & "type", "none"))
                Dim cellType As Integer = MAMUTE_CELL_NONE
                If typeText = "ram" Then
                    cellType = MAMUTE_CELL_RAM
                ElseIf typeText = "rom" Then
                    cellType = MAMUTE_CELL_ROM
                ElseIf typeText = "bios" Then
                    cellType = MAMUTE_CELL_BIOS
                ElseIf typeText = "basic" Then
                    cellType = MAMUTE_CELL_BASIC
                ElseIf typeText = "extbios" Then
                    cellType = MAMUTE_CELL_EXTBIOS
                End If
                MamuteMemGrid(slot, subIdx, pageIdx).cellType = cellType
                MamuteMemGrid(slot, subIdx, pageIdx).romPath = DbGetSetting(prefix & "rompath", "")
                MamuteMemGrid(slot, subIdx, pageIdx).romOffset = ValInt(DbGetSetting(prefix & "romoffset", "0"))
            Next pageIdx
        Next subIdx
    Next slot

    MamuteVramKB = ValInt(DbGetSetting("cfg.mamute.mem.vramkb", "16"))
    If MamuteVramKB <> 16 And MamuteVramKB <> 32 And MamuteVramKB <> 64 And MamuteVramKB <> 128 And MamuteVramKB <> 192 Then
        MamuteVramKB = 16
    End If
End Sub

Private Sub SaveMamuteMemConfig()
    Dim slot As Integer
    Dim subIdx As Integer
    Dim pageIdx As Integer

    For slot = 0 To 3
        Dim subKey As String = "cfg.mamute.mem.slot" & Trim(Str(slot)) & ".subslots"
        DbSetSetting(subKey, IIf(MamuteMemSubOn(slot) <> 0, "True", "False"))

        For subIdx = 0 To 3
            For pageIdx = 0 To 3
                Dim prefix As String = "cfg.mamute.mem.slot" & Trim(Str(slot)) & ".sub" & Trim(Str(subIdx)) & ".page" & Trim(Str(pageIdx)) & "."
                Dim ByRef cell As MamuteMemCell = MamuteMemGrid(slot, subIdx, pageIdx)
                Dim typeText As String = "none"
                If cell.cellType = MAMUTE_CELL_RAM Then typeText = "ram"
                If cell.cellType = MAMUTE_CELL_ROM Then typeText = "rom"
                If cell.cellType = MAMUTE_CELL_BIOS Then typeText = "bios"
                If cell.cellType = MAMUTE_CELL_BASIC Then typeText = "basic"
                If cell.cellType = MAMUTE_CELL_EXTBIOS Then typeText = "extbios"
                DbSetSetting(prefix & "type", typeText)
                DbSetSetting(prefix & "rompath", cell.romPath)
                DbSetSetting(prefix & "romoffset", Trim(Str(cell.romOffset)))
            Next pageIdx
        Next subIdx
    Next slot

    DbSetSetting("cfg.mamute.mem.vramkb", Trim(Str(MamuteVramKB)))
End Sub

' Aplica um arquivo de ROM numa pagina, com o preenchimento automatico das
' paginas vizinhas que o Mega Assembler/Super-X original faz quando a ROM
' informada tem mais de 16KB (BIOS+BASIC juntos no mesmo arquivo):
'   BIOS   -> pagina atual = 1os 16KB (BIOS); pagina SEGUINTE do mesmo
'             slot/sub-slot = 16KB seguintes, marcada BASIC.
'   BASIC  -> o inverso: pagina atual = 16KB seguintes (BASIC); pagina
'             ANTERIOR do mesmo slot/sub-slot = 1os 16KB, marcada BIOS.
'   ROM    -> mesma divisao em 16KB da BIOS (atual + seguinte): a pagina
'             atual continua ROM (foi o tipo escolhido), mas a seguinte
'             tambem vira BASIC, ja que na pratica e a mesma dupla
'             BIOS+BASIC de 32KB - so a pagina inicial recebe o rotulo que
'             o usuario escolheu.
'   EXTBIOS-> so a pagina atual, sem particionar (nao faz parte do par
'             BIOS/BASIC de 32KB).
' Arquivos com 16KB ou menos nao disparam o preenchimento da vizinha - so a
' pagina selecionada recebe o arquivo, a partir do offset 0 (ou 16384 pro
' caso BASIC "sozinho", ja que BASIC sem BIOS junto so faz sentido como a
' segunda metade de uma imagem maior).
Declare Function Mamute_ResolveRomPath(ByRef rawPath As String) As String

Private Sub AssignMamuteRomFile(ByVal slot As Integer, ByVal subIdx As Integer, ByVal pageIdx As Integer, ByVal cellType As Integer, ByRef romFile As String, ByRef resultMsg As String)
    Dim fileSize As LongInt = 0
    ' Resolve via a mesma convencao de pasta "roms\" que Mamute_LoadPhysicalMemory
    ' usa - sem isso, um caminho digitado como so "expert1.rom" (arquivo de
    ' verdade em roms\expert1.rom) nunca era achado AQUI, entao fileSize ficava
    ' 0 e o preenchimento automatico da pagina BASIC vizinha nunca disparava,
    ' mesmo com o arquivo de 32KB existindo e sendo carregado certinho depois.
    Dim resolvedForSize As String = Mamute_ResolveRomPath(romFile)
    If Dir(resolvedForSize) <> "" Then
        Dim sizeFf As Integer = FreeFile
        Open resolvedForSize For Binary Access Read As #sizeFf
        fileSize = Lof(sizeFf)
        Close #sizeFf
    End If
    Dim needsSplit As Integer = IIf(fileSize > 16384, -1, 0)
    Dim pageLabel As String = "pag." & Trim(Str(pageIdx))
    Dim spaceHint As String = " Espaco troca o tipo de qualquer pagina."

    Select Case cellType
        Case MAMUTE_CELL_BIOS
            MamuteMemGrid(slot, subIdx, pageIdx).cellType = MAMUTE_CELL_BIOS
            MamuteMemGrid(slot, subIdx, pageIdx).romPath = romFile
            MamuteMemGrid(slot, subIdx, pageIdx).romOffset = 0
            If needsSplit <> 0 And pageIdx <= 2 Then
                MamuteMemGrid(slot, subIdx, pageIdx + 1).cellType = MAMUTE_CELL_BASIC
                MamuteMemGrid(slot, subIdx, pageIdx + 1).romPath = romFile
                MamuteMemGrid(slot, subIdx, pageIdx + 1).romOffset = 16384
                resultMsg = "BIOS na " & pageLabel & " + BASIC na pag." & Trim(Str(pageIdx + 1)) & " (ROM dividida)." & spaceHint
            ElseIf needsSplit <> 0 Then
                resultMsg = "BIOS na " & pageLabel & " (ROM maior que 16KB, mas nao ha pagina seguinte no slot p/ BASIC)." & spaceHint
            Else
                resultMsg = "BIOS na " & pageLabel & " (arquivo de 16KB ou menos, so essa pagina)." & spaceHint
            End If

        Case MAMUTE_CELL_BASIC
            MamuteMemGrid(slot, subIdx, pageIdx).cellType = MAMUTE_CELL_BASIC
            MamuteMemGrid(slot, subIdx, pageIdx).romPath = romFile
            If needsSplit <> 0 And pageIdx >= 1 Then
                MamuteMemGrid(slot, subIdx, pageIdx).romOffset = 16384
                MamuteMemGrid(slot, subIdx, pageIdx - 1).cellType = MAMUTE_CELL_BIOS
                MamuteMemGrid(slot, subIdx, pageIdx - 1).romPath = romFile
                MamuteMemGrid(slot, subIdx, pageIdx - 1).romOffset = 0
                resultMsg = "BASIC na " & pageLabel & " + BIOS na pag." & Trim(Str(pageIdx - 1)) & " (ROM dividida)." & spaceHint
            ElseIf needsSplit <> 0 Then
                MamuteMemGrid(slot, subIdx, pageIdx).romOffset = 16384
                resultMsg = "BASIC na " & pageLabel & " (ROM maior que 16KB, mas nao ha pagina anterior no slot p/ BIOS)." & spaceHint
            Else
                MamuteMemGrid(slot, subIdx, pageIdx).romOffset = 0
                resultMsg = "BASIC na " & pageLabel & " (arquivo de 16KB ou menos, so essa pagina)." & spaceHint
            End If

        Case MAMUTE_CELL_ROM
            MamuteMemGrid(slot, subIdx, pageIdx).cellType = MAMUTE_CELL_ROM
            MamuteMemGrid(slot, subIdx, pageIdx).romPath = romFile
            MamuteMemGrid(slot, subIdx, pageIdx).romOffset = 0
            If needsSplit <> 0 And pageIdx <= 2 Then
                MamuteMemGrid(slot, subIdx, pageIdx + 1).cellType = MAMUTE_CELL_BASIC
                MamuteMemGrid(slot, subIdx, pageIdx + 1).romPath = romFile
                MamuteMemGrid(slot, subIdx, pageIdx + 1).romOffset = 16384
                resultMsg = "ROM na " & pageLabel & " + BASIC na pag." & Trim(Str(pageIdx + 1)) & " (ROM dividida)." & spaceHint
            ElseIf needsSplit <> 0 Then
                resultMsg = "ROM na " & pageLabel & " (ROM maior que 16KB, mas nao ha pagina seguinte no slot)." & spaceHint
            Else
                resultMsg = "ROM na " & pageLabel & " (offset 0)." & spaceHint
            End If

        Case MAMUTE_CELL_EXTBIOS
            MamuteMemGrid(slot, subIdx, pageIdx).cellType = MAMUTE_CELL_EXTBIOS
            MamuteMemGrid(slot, subIdx, pageIdx).romPath = romFile
            MamuteMemGrid(slot, subIdx, pageIdx).romOffset = 0
            resultMsg = "EXTBIOS na " & pageLabel & "." & spaceHint
    End Select
End Sub

' Mapeamento inicial de PAGE quando o terminal do Mamute abre: paginas 0 e 1
' apontam pro primeiro slot/sub-slot com BIOS na pag.0 (o mesmo que tem BASIC
' na pag.1, gracas ao preenchimento automatico de AssignMamuteRomFile); as
' paginas 2 e 3 apontam pro primeiro slot/sub-slot com RAM em cada uma delas.
' Sem BIOS/RAM configurados ainda, fica tudo no Slot 0 (mesmo default de um
' MSX real recem-ligado, antes do boot escolher os slots primarios).
Private Sub SetMamuteDefaultPageMapping()
    Dim p As Integer
    For p = 0 To 3
        MamuteActiveSlot(p) = 0
        MamuteActiveSub(p) = 0
    Next p

    Dim slot As Integer
    Dim subIdx As Integer
    Dim maxSub As Integer
    Dim foundBios As Integer = 0
    For slot = 0 To 3
        maxSub = IIf(MamuteMemSubOn(slot) <> 0, 3, 0)
        For subIdx = 0 To maxSub
            If foundBios = 0 And MamuteMemGrid(slot, subIdx, 0).cellType = MAMUTE_CELL_BIOS Then
                MamuteActiveSlot(0) = slot : MamuteActiveSub(0) = subIdx
                MamuteActiveSlot(1) = slot : MamuteActiveSub(1) = subIdx
                foundBios = -1
            End If
        Next subIdx
    Next slot

    Dim foundRam2 As Integer = 0
    For slot = 0 To 3
        maxSub = IIf(MamuteMemSubOn(slot) <> 0, 3, 0)
        For subIdx = 0 To maxSub
            If foundRam2 = 0 And MamuteMemGrid(slot, subIdx, 2).cellType = MAMUTE_CELL_RAM Then
                MamuteActiveSlot(2) = slot : MamuteActiveSub(2) = subIdx
                foundRam2 = -1
            End If
        Next subIdx
    Next slot

    Dim foundRam3 As Integer = 0
    For slot = 0 To 3
        maxSub = IIf(MamuteMemSubOn(slot) <> 0, 3, 0)
        For subIdx = 0 To maxSub
            If foundRam3 = 0 And MamuteMemGrid(slot, subIdx, 3).cellType = MAMUTE_CELL_RAM Then
                MamuteActiveSlot(3) = slot : MamuteActiveSub(3) = subIdx
                foundRam3 = -1
            End If
        Next subIdx
    Next slot
End Sub

' Acha o primeiro slot/sub-slot (varrendo slot 0-3, sub 0-3, pag. 0-3, nessa
' ordem) que tem alguma pagina marcada como RAM - usado pelo comando "PAGE"
' sem argumentos, que joga as 4 paginas inteiras pra esse slot (workspace de
' RAM full pro assembler ter onde escrever, igual ao Mega Assembler/Super-X).
Private Function FindMamuteRamSlot(ByRef foundSlot As Integer, ByRef foundSub As Integer) As Integer
    Dim slot As Integer
    Dim subIdx As Integer
    Dim pageIdx As Integer
    Dim maxSub As Integer
    For slot = 0 To 3
        maxSub = IIf(MamuteMemSubOn(slot) <> 0, 3, 0)
        For subIdx = 0 To maxSub
            For pageIdx = 0 To 3
                If MamuteMemGrid(slot, subIdx, pageIdx).cellType = MAMUTE_CELL_RAM Then
                    foundSlot = slot
                    foundSub = subIdx
                    Return -1
                End If
            Next pageIdx
        Next subIdx
    Next slot
    Return 0
End Function

Private Function MamuteActivePageSummary() As String
    Dim txt As String = "PAGE ativo:"
    Dim p As Integer
    For p = 0 To 3
        Dim s As Integer = MamuteActiveSlot(p)
        Dim label As String = "Slot " & Trim(Str(s))
        If MamuteMemSubOn(s) <> 0 Then label &= "." & Trim(Str(MamuteActiveSub(p)))
        txt &= " P" & Trim(Str(p)) & "=" & label
    Next p
    Return txt
End Function

' Intervalo de enderecos (Z80, 16 bits) da pagina de 16KB indicada:
' pag.0=0000-3FFF, pag.1=4000-7FFF, pag.2=8000-BFFF, pag.3=C000-FFFF.
Private Function MamutePageAddrRange(ByVal pageIdx As Integer) As String
    Dim startAddr As Integer = pageIdx * 16384
    Dim endAddr As Integer = startAddr + 16383
    Return Hex(startAddr, 4) & "-" & Hex(endAddr, 4)
End Function

Private Function NextMamuteVramSize(ByVal current As Integer) As Integer
    Select Case current
        Case 16
            Return 32
        Case 32
            Return 64
        Case 64
            Return 128
        Case 128
            Return 192
        Case Else
            Return 16
    End Select
End Function

' ---------------------------------------------------------------------------
' Motor de memoria fisica do Mamute Assembler: le/escreve MamuteMem() de
' verdade, resolvendo endereco Z80 (0000-FFFF) pelo mapeamento PAGE ativo
' agora. Chamado por todos os comandos que tocam memoria de verdade (DM, M,
' S, SH, MS, T, F, D, P, L, LP).
' ---------------------------------------------------------------------------

' Popula MamuteMem() a partir da config fisica atual (MamuteMemGrid): RAM
' comeca zerada, ROM/BASIC/BIOS/EXTBIOS com arquivo configurado sao lidas de
' verdade do disco. So' deve ser chamada quando o terminal ABRE - nunca a
' cada comando, ou RAM escrita durante a sessao seria perdida.
' Resolve um caminho de ROM configurado: se nao existir exatamente como
' digitado (relativo ao diretorio de trabalho atual), tenta de novo dentro
' de uma pasta "roms\" ao lado do executavel - convencao onde este usuario
' guarda os arquivos de BIOS/firmware (fora do controle de versao, por
' direitos autorais). Sem isso, um caminho salvo como so "expert1.rom" (sem
' a pasta na frente) nunca era encontrado e a pagina ficava sempre zerada,
' sem aviso nenhum.
Private Function Mamute_ResolveRomPath(ByRef rawPath As String) As String
    If Len(rawPath) = 0 Then Return rawPath
    If Dir(rawPath) <> "" Then Return rawPath
    Dim tryRoms As String = "roms" & Chr(92) & rawPath
    If Dir(tryRoms) <> "" Then Return tryRoms
    Return rawPath
End Function

Private Sub Mamute_LoadPhysicalMemory()
    Dim slot As Integer
    Dim subIdx As Integer
    Dim pageIdx As Integer
    Dim i As Integer

    For slot = 0 To 3
        For subIdx = 0 To 3
            For pageIdx = 0 To 3
                For i = 0 To 16383
                    MamuteMem(slot, subIdx, pageIdx, i) = 0
                Next i

                Dim ByRef cell As MamuteMemCell = MamuteMemGrid(slot, subIdx, pageIdx)
                Dim isRomLike As Integer = 0
                If cell.cellType = MAMUTE_CELL_ROM Or cell.cellType = MAMUTE_CELL_BIOS Or cell.cellType = MAMUTE_CELL_BASIC Or cell.cellType = MAMUTE_CELL_EXTBIOS Then isRomLike = -1

                Dim effRomPath As String = cell.romPath
                Dim effRomOffset As Integer = cell.romOffset

                ' Pagina BASIC sem caminho proprio (config antiga/dessincronizada -
                ' por exemplo a BIOS foi reconfigurada num momento em que o arquivo
                ' nao existia/tinha nome errado, entao AssignMamuteRomFile nao
                ' conseguiu medir o tamanho e nunca preencheu esta pagina vizinha):
                ' cai pro arquivo da BIOS na pagina anterior do MESMO slot/sub-slot,
                ' offset 16384 - e a segunda metade da mesma imagem de 32KB. So' usa
                ' esse fallback quando esta pagina nao tem arquivo proprio - uma
                ' pagina BASIC com caminho ja configurado continua usando o dela.
                If cell.cellType = MAMUTE_CELL_BASIC And Len(Trim(effRomPath)) = 0 And pageIdx >= 1 Then
                    Dim ByRef biosCell As MamuteMemCell = MamuteMemGrid(slot, subIdx, pageIdx - 1)
                    If biosCell.cellType = MAMUTE_CELL_BIOS And Len(biosCell.romPath) > 0 Then
                        effRomPath = biosCell.romPath
                        effRomOffset = 16384
                    End If
                End If

                Dim resolvedRomPath As String = ""
                If isRomLike <> 0 And Len(effRomPath) > 0 Then resolvedRomPath = Mamute_ResolveRomPath(effRomPath)

                If isRomLike <> 0 And Len(resolvedRomPath) > 0 And Dir(resolvedRomPath) <> "" Then
                    Dim ff As Integer = FreeFile
                    Open resolvedRomPath For Binary Access Read As #ff
                    Dim fsize As LongInt = Lof(ff)
                    If effRomOffset < fsize Then
                        Dim avail As LongInt = fsize - effRomOffset
                        Dim toRead As Integer = 16384
                        If avail < toRead Then toRead = CInt(avail)
                        If toRead > 0 Then
                            Dim buf(0 To toRead - 1) As UByte
                            Get #ff, effRomOffset + 1, buf()
                            For i = 0 To toRead - 1
                                MamuteMem(slot, subIdx, pageIdx, i) = buf(i)
                            Next i
                        End If
                    End If
                    Close #ff
                End If
            Next pageIdx
        Next subIdx
    Next slot

    For i = 0 To 196607
        MamuteVram(i) = 0
    Next i
End Sub

Private Sub Mamute_ResolveAddress(ByVal addr As Integer, ByRef outSlot As Integer, ByRef outSub As Integer, ByRef outPage As Integer, ByRef outOffset As Integer)
    outPage = (addr \ 16384) And 3
    outSlot = MamuteActiveSlot(outPage)
    outSub = MamuteActiveSub(outPage)
    outOffset = addr And 16383
End Sub

Private Function Mamute_ReadByte(ByVal addr As Integer) As Integer
    Dim slot As Integer, subIdx As Integer, pageIdx As Integer, offset As Integer
    Mamute_ResolveAddress(addr, slot, subIdx, pageIdx, offset)
    Return MamuteMem(slot, subIdx, pageIdx, offset)
End Function

Private Function Mamute_CanWriteAt(ByVal addr As Integer) As Integer
    Dim slot As Integer, subIdx As Integer, pageIdx As Integer, offset As Integer
    Mamute_ResolveAddress(addr, slot, subIdx, pageIdx, offset)
    Return IIf(MamuteMemGrid(slot, subIdx, pageIdx).cellType = MAMUTE_CELL_RAM, -1, 0)
End Function

' Sufixo de aviso pra comandos de escrita (M/S/MS/T/F) - a escrita em si
' continua silenciosa igual hardware real (nao ha erro, o byte so nao muda),
' mas um monitor de debug ganha muito em avisar quando isso acontece, ao
' inves de deixar o usuario decifrar sozinho por que nada mudou.
Private Function Mamute_WriteWarnSuffix(ByVal addr As Integer) As String
    If Mamute_CanWriteAt(addr) = 0 Then
        Return " (AVISO: pagina nao e RAM agora - escrita sem efeito, ver PAGE/Configurar -> Mamute (Memoria))"
    End If
    Return ""
End Function

' Escrita silenciosa: nao ha o que gravar fisicamente numa celula que nao
' seja RAM (ROM/BASIC/BIOS/EXTBIOS/Vazio), igual hardware real - o byte
' simplesmente nao muda, sem erro nenhum. Regra usada por DM/M/S/MS/T/F.
Private Sub Mamute_WriteByte(ByVal addr As Integer, ByVal value As Integer)
    Dim slot As Integer, subIdx As Integer, pageIdx As Integer, offset As Integer
    Mamute_ResolveAddress(addr, slot, subIdx, pageIdx, offset)
    If MamuteMemGrid(slot, subIdx, pageIdx).cellType = MAMUTE_CELL_RAM Then
        MamuteMem(slot, subIdx, pageIdx, offset) = value And 255
    End If
End Sub

' ---------------------------------------------------------------------------
' Helpers de parsing compartilhados por (quase) todo comando do Mamute:
' enderecos/bytes/deslocamentos sempre em hexadecimal, listas separadas por
' virgula onde um campo vazio e valido (fica "nao informado").
' ---------------------------------------------------------------------------

Private Function Mamute_IsHexString(ByRef token As String, ByVal maxLen As Integer) As Integer
    If Len(token) < 1 Or Len(token) > maxLen Then Return 0
    Dim i As Integer
    For i = 1 To Len(token)
        If InStr("0123456789ABCDEFabcdef", Mid(token, i, 1)) = 0 Then Return 0
    Next i
    Return -1
End Function

' Endereco de 1-4 digitos hexa (memoria Z80, 0000-FFFF). maxDigits=5 pra V
' (VRAM, ate 192KB precisa de 5 digitos).
Private Function Mamute_ParseHexAddr(ByRef token As String, ByRef outAddr As Integer, ByVal maxDigits As Integer = 4) As Integer
    Dim t As String = Trim(token)
    If Mamute_IsHexString(t, maxDigits) = 0 Then Return 0
    outAddr = ValInt("&H" & t)
    Return -1
End Function

Private Function Mamute_ParseHexByte(ByRef token As String, ByRef outByte As Integer) As Integer
    Dim t As String = Trim(token)
    If Mamute_IsHexString(t, 2) = 0 Then Return 0
    outByte = ValInt("&H" & t) And 255
    Return -1
End Function

' Deslocamento com sinal opcional, -7F a 80 (faixa usada por DM/ZAP/SH/MS).
Private Function Mamute_ParseHexOffset(ByRef token As String, ByRef outOffset As Integer) As Integer
    Dim t As String = Trim(token)
    Dim sign As Integer = 1
    If Len(t) > 0 And (Left(t, 1) = "+" Or Left(t, 1) = "-") Then
        If Left(t, 1) = "-" Then sign = -1
        t = Mid(t, 2)
    End If
    If Mamute_IsHexString(t, 2) = 0 Then Return 0
    Dim v As Integer = ValInt("&H" & t) * sign
    If v < -127 Or v > 128 Then Return 0
    outOffset = v
    Return -1
End Function

' Separa argsText em ate maxTokens campos por virgula - um campo vazio entre
' duas virgulas (ou no comeco/fim) vira uma string vazia no array, nao e'
' descartado (assim "PAGE ,,2"/"SH ,2A,40" preservam as posicoes certas).
Private Sub Mamute_SplitArgs(ByRef argsText As String, tokens() As String, ByRef tokCount As Integer, ByVal maxTokens As Integer)
    ReDim tokens(0 To maxTokens - 1)
    tokCount = 0
    Dim remaining As String = argsText
    Do While tokCount < maxTokens
        Dim commaPos As Integer = InStr(remaining, ",")
        If commaPos = 0 Then
            tokens(tokCount) = Trim(remaining)
            tokCount += 1
            Exit Do
        Else
            tokens(tokCount) = Trim(Left(remaining, commaPos - 1))
            remaining = Mid(remaining, commaPos + 1)
            tokCount += 1
        End If
    Loop
End Sub

Private Function Mamute_PrintableChar(ByVal b As Integer) As String
    If b >= 32 And b <= 126 Then Return Chr(b)
    Return "."
End Function

' ---------------------------------------------------------------------------
' Registradores do Z80 simulado (comando X).
' ---------------------------------------------------------------------------

Private Function MamuteXRegName(ByVal mode As Integer, ByVal idx As Integer) As String
    If mode = 1 Then
        Select Case idx
            Case 0 : Return "AF"
            Case 1 : Return "BC"
            Case 2 : Return "DE"
            Case 3 : Return "HL"
            Case 4 : Return "IX"
            Case 5 : Return "IY"
            Case 6 : Return "SP"
        End Select
    Else
        Select Case idx
            Case 0 : Return "A"
            Case 1 : Return "F"
            Case 2 : Return "B"
            Case 3 : Return "C"
            Case 4 : Return "D"
            Case 5 : Return "E"
            Case 6 : Return "H"
            Case 7 : Return "L"
        End Select
    End If
    Return ""
End Function

Private Function MamuteXRegCount(ByVal mode As Integer) As Integer
    If mode = 1 Then Return 7
    Return 8
End Function

' Acha (mode,idx) do nome de registrador dado - mode=0 se nao reconhecido.
Private Sub MamuteXFindReg(ByRef regName As String, ByRef outMode As Integer, ByRef outIdx As Integer)
    Dim n As String = UCase(Trim(regName))
    Dim i As Integer
    For i = 0 To 6
        If MamuteXRegName(1, i) = n Then
            outMode = 1 : outIdx = i
            Exit Sub
        End If
    Next i
    For i = 0 To 7
        If MamuteXRegName(2, i) = n Then
            outMode = 2 : outIdx = i
            Exit Sub
        End If
    Next i
    outMode = 0 : outIdx = 0
End Sub

Private Function MamuteXGetReg(ByRef regName As String) As Integer
    Select Case UCase(Trim(regName))
        Case "AF" : Return MamuteRegAF
        Case "BC" : Return MamuteRegBC
        Case "DE" : Return MamuteRegDE
        Case "HL" : Return MamuteRegHL
        Case "IX" : Return MamuteRegIX
        Case "IY" : Return MamuteRegIY
        Case "SP" : Return MamuteRegSP
        Case "A" : Return (MamuteRegAF \ 256) And 255
        Case "F" : Return MamuteRegAF And 255
        Case "B" : Return (MamuteRegBC \ 256) And 255
        Case "C" : Return MamuteRegBC And 255
        Case "D" : Return (MamuteRegDE \ 256) And 255
        Case "E" : Return MamuteRegDE And 255
        Case "H" : Return (MamuteRegHL \ 256) And 255
        Case "L" : Return MamuteRegHL And 255
    End Select
    Return 0
End Function

Private Sub MamuteXSetReg(ByRef regName As String, ByVal value As Integer)
    Select Case UCase(Trim(regName))
        Case "AF" : MamuteRegAF = value And 65535
        Case "BC" : MamuteRegBC = value And 65535
        Case "DE" : MamuteRegDE = value And 65535
        Case "HL" : MamuteRegHL = value And 65535
        Case "IX" : MamuteRegIX = value And 65535
        Case "IY" : MamuteRegIY = value And 65535
        Case "SP" : MamuteRegSP = value And 65535
        Case "A" : MamuteRegAF = (MamuteRegAF And 255) Or ((value And 255) * 256)
        Case "F" : MamuteRegAF = (MamuteRegAF And 65280) Or (value And 255)
        Case "B" : MamuteRegBC = (MamuteRegBC And 255) Or ((value And 255) * 256)
        Case "C" : MamuteRegBC = (MamuteRegBC And 65280) Or (value And 255)
        Case "D" : MamuteRegDE = (MamuteRegDE And 255) Or ((value And 255) * 256)
        Case "E" : MamuteRegDE = (MamuteRegDE And 65280) Or (value And 255)
        Case "H" : MamuteRegHL = (MamuteRegHL And 255) Or ((value And 255) * 256)
        Case "L" : MamuteRegHL = (MamuteRegHL And 65280) Or (value And 255)
    End Select
End Sub

Private Sub Mamute_ResetRegs()
    MamuteRegAF = 0 : MamuteRegBC = 0 : MamuteRegDE = 0 : MamuteRegHL = 0
    MamuteRegIX = 0 : MamuteRegIY = 0 : MamuteRegSP = 0
End Sub

' Prompt do terminal agora: "MON> " normalmente, ou "REG(valor)> " enquanto o
' comando X estiver caminhando pelos registradores (ver DrawMamuteInputLine/
' PlaceActiveCursor).
Private Function MamuteCurrentPromptText(ByVal docIndex As Integer) As String
    If MamuteXWalking(docIndex) <> 0 Then
        Dim wRegName As String = MamuteXRegName(MamuteXWalking(docIndex), MamuteXWalkIdx(docIndex))
        Dim wDigits As Integer = 4
        If MamuteXWalking(docIndex) = 2 Then wDigits = 2
        Return wRegName & "(" & Hex(MamuteXGetReg(wRegName), wDigits) & ")> "
    End If
    Return MAMUTE_PROMPT
End Function

' ---------------------------------------------------------------------------
' Disassembler Z80 (comandos L/LP/D/P) - decodificacao padrao por
' x=(op>>6)&3, y=(op>>3)&7, z=op&7, p=y>>1, q=y&1 sobre o byte de opcode
' (depois de consumir prefixos DD/FD/CB/ED). Conjunto documentado inteiro +
' as formas nao documentadas mais estaveis (IXH/IXL/IYH/IYL, DD/FD CB
' indexado).
' ---------------------------------------------------------------------------

Private Function MamuteDisasmNextByte(ByRef curPos As Integer, ByRef consumed As Integer) As Integer
    Dim v As Integer = Mamute_ReadByte(curPos)
    curPos += 1
    consumed += 1
    Return v
End Function

Private Function MamuteDisasmNextWord(ByRef curPos As Integer, ByRef consumed As Integer) As Integer
    Dim lo As Integer = MamuteDisasmNextByte(curPos, consumed)
    Dim hi As Integer = MamuteDisasmNextByte(curPos, consumed)
    Return (hi * 256 + lo) And 65535
End Function

' "+05"/"-05" - deslocamento assinado de 2 digitos hexa, formato do IX+d/IY+d.
Private Function MamuteDispText(ByVal d As Integer) As String
    Dim sd As Integer = d And 255
    If sd > 127 Then sd -= 256
    If sd >= 0 Then Return "+" & Hex(sd, 2) & "H"
    Return "-" & Hex(-sd, 2) & "H"
End Function

Private Function MamuteReg8Text(ByVal r As Integer, ByVal idxMode As Integer, ByRef dispText As String) As String
    Select Case r
        Case 0 : Return "B"
        Case 1 : Return "C"
        Case 2 : Return "D"
        Case 3 : Return "E"
        Case 4
            If idxMode = 1 Then Return "IXH"
            If idxMode = 2 Then Return "IYH"
            Return "H"
        Case 5
            If idxMode = 1 Then Return "IXL"
            If idxMode = 2 Then Return "IYL"
            Return "L"
        Case 6
            If idxMode = 1 Then Return "(IX" & dispText & ")"
            If idxMode = 2 Then Return "(IY" & dispText & ")"
            Return "(HL)"
        Case 7 : Return "A"
    End Select
    Return "?"
End Function

' Igual a MamuteReg8Text, mas consome o byte de deslocamento sozinho, na
' hora certa (logo apos o opcode, antes de qualquer imediato que venha
' depois), quando r=6 e o modo indexado esta ligado.
Private Function MamuteReg8TextAuto(ByVal r As Integer, ByVal idxMode As Integer, ByRef curPos As Integer, ByRef consumed As Integer) As String
    If r = 6 And idxMode <> 0 Then
        Dim d As Integer = MamuteDisasmNextByte(curPos, consumed)
        Dim letter As String = "X"
        If idxMode = 2 Then letter = "Y"
        Return "(I" & letter & MamuteDispText(d) & ")"
    End If
    Return MamuteReg8Text(r, idxMode, "")
End Function

Private Function MamuteReg16Text(ByVal regP As Integer, ByVal idxMode As Integer) As String
    Select Case regP
        Case 0 : Return "BC"
        Case 1 : Return "DE"
        Case 2
            If idxMode = 1 Then Return "IX"
            If idxMode = 2 Then Return "IY"
            Return "HL"
        Case 3 : Return "SP"
    End Select
    Return "?"
End Function

Private Function MamuteReg16AltText(ByVal regP As Integer, ByVal idxMode As Integer) As String
    If regP = 3 Then Return "AF"
    Return MamuteReg16Text(regP, idxMode)
End Function

Private Function MamuteCondText(ByVal y As Integer) As String
    Select Case y
        Case 0 : Return "NZ"
        Case 1 : Return "Z"
        Case 2 : Return "NC"
        Case 3 : Return "C"
        Case 4 : Return "PO"
        Case 5 : Return "PE"
        Case 6 : Return "P"
        Case 7 : Return "M"
    End Select
    Return "?"
End Function

Private Function MamuteAluMnemonic(ByVal y As Integer) As String
    Select Case y
        Case 0 : Return "ADD A,"
        Case 1 : Return "ADC A,"
        Case 2 : Return "SUB "
        Case 3 : Return "SBC A,"
        Case 4 : Return "AND "
        Case 5 : Return "XOR "
        Case 6 : Return "OR "
        Case 7 : Return "CP "
    End Select
    Return "?"
End Function

Private Function MamuteRotMnemonic(ByVal y As Integer) As String
    Select Case y
        Case 0 : Return "RLC "
        Case 1 : Return "RRC "
        Case 2 : Return "RL "
        Case 3 : Return "RR "
        Case 4 : Return "SLA "
        Case 5 : Return "SRA "
        Case 6 : Return "SLL "
        Case 7 : Return "SRL "
    End Select
    Return "?"
End Function

Private Function MamuteDecodeCB(ByVal op As Integer, ByVal idxMode As Integer, ByRef dispText As String) As String
    Dim x As Integer = (op \ 64) And 3
    Dim y As Integer = (op \ 8) And 7
    Dim z As Integer = op And 7
    Dim operandText As String

    If idxMode <> 0 Then
        Dim letter As String = "X"
        If idxMode = 2 Then letter = "Y"
        operandText = "(I" & letter & dispText & ")"
    Else
        operandText = MamuteReg8Text(z, 0, "")
    End If

    Select Case x
        Case 0
            Return MamuteRotMnemonic(y) & operandText
        Case 1
            Return "BIT " & Trim(Str(y)) & "," & operandText
        Case 2
            Return "RES " & Trim(Str(y)) & "," & operandText
        Case 3
            Return "SET " & Trim(Str(y)) & "," & operandText
    End Select
    Return "DEFB 0CBh," & Hex(op, 2) & "H"
End Function

Private Function MamuteDecodeED(ByVal op As Integer, ByRef curPos As Integer, ByRef consumed As Integer) As String
    Dim x As Integer = (op \ 64) And 3
    Dim y As Integer = (op \ 8) And 7
    Dim z As Integer = op And 7
    Dim regP As Integer = y \ 2
    Dim regQ As Integer = y And 1

    If x = 1 Then
        Select Case z
            Case 0
                If y = 6 Then Return "IN F,(C)"
                Return "IN " & MamuteReg8Text(y, 0, "") & ",(C)"
            Case 1
                If y = 6 Then Return "OUT (C),0"
                Return "OUT (C)," & MamuteReg8Text(y, 0, "")
            Case 2
                If regQ = 0 Then Return "SBC HL," & MamuteReg16Text(regP, 0)
                Return "ADC HL," & MamuteReg16Text(regP, 0)
            Case 3
                Dim addrVal As Integer = MamuteDisasmNextWord(curPos, consumed)
                If regQ = 0 Then Return "LD (" & Hex(addrVal, 4) & "H)," & MamuteReg16Text(regP, 0)
                Return "LD " & MamuteReg16Text(regP, 0) & ",(" & Hex(addrVal, 4) & "H)"
            Case 4
                Return "NEG"
            Case 5
                If y = 1 Then Return "RETI"
                Return "RETN"
            Case 6
                Select Case y Mod 4
                    Case 0, 1 : Return "IM 0"
                    Case 2 : Return "IM 1"
                    Case 3 : Return "IM 2"
                End Select
            Case 7
                Select Case y
                    Case 0 : Return "LD I,A"
                    Case 1 : Return "LD R,A"
                    Case 2 : Return "LD A,I"
                    Case 3 : Return "LD A,R"
                    Case 4 : Return "RRD"
                    Case 5 : Return "RLD"
                    Case Else : Return "NOP"
                End Select
        End Select
    ElseIf x = 2 And y >= 4 And z <= 3 Then
        Select Case z
            Case 0
                Select Case y
                    Case 4 : Return "LDI"
                    Case 5 : Return "LDD"
                    Case 6 : Return "LDIR"
                    Case 7 : Return "LDDR"
                End Select
            Case 1
                Select Case y
                    Case 4 : Return "CPI"
                    Case 5 : Return "CPD"
                    Case 6 : Return "CPIR"
                    Case 7 : Return "CPDR"
                End Select
            Case 2
                Select Case y
                    Case 4 : Return "INI"
                    Case 5 : Return "IND"
                    Case 6 : Return "INIR"
                    Case 7 : Return "INDR"
                End Select
            Case 3
                Select Case y
                    Case 4 : Return "OUTI"
                    Case 5 : Return "OUTD"
                    Case 6 : Return "OTIR"
                    Case 7 : Return "OTDR"
                End Select
        End Select
    End If

    Return "DEFB 0EDh," & Hex(op, 2) & "H"
End Function

Private Function MamuteDecodePlain(ByVal b As Integer, ByVal idxMode As Integer, ByRef curPos As Integer, ByRef consumed As Integer) As String
    Dim x As Integer = (b \ 64) And 3
    Dim y As Integer = (b \ 8) And 7
    Dim z As Integer = b And 7
    Dim regP As Integer = y \ 2
    Dim regQ As Integer = y And 1

    Select Case x
        Case 0
            Select Case z
                Case 0
                    If y = 0 Then Return "NOP"
                    If y = 1 Then Return "EX AF,AF'"
                    Dim relDisp As Integer = MamuteDisasmNextByte(curPos, consumed)
                    Dim signedDisp As Integer = relDisp
                    If signedDisp > 127 Then signedDisp -= 256
                    Dim targetAddr As Integer = (curPos + signedDisp) And 65535
                    If y = 2 Then Return "DJNZ " & Hex(targetAddr, 4) & "H"
                    If y = 3 Then Return "JR " & Hex(targetAddr, 4) & "H"
                    Return "JR " & MamuteCondText(y - 4) & "," & Hex(targetAddr, 4) & "H"
                Case 1
                    If regQ = 0 Then
                        Dim immWord As Integer = MamuteDisasmNextWord(curPos, consumed)
                        Return "LD " & MamuteReg16Text(regP, idxMode) & "," & Hex(immWord, 4) & "H"
                    Else
                        Dim destReg As String = "HL"
                        If idxMode = 1 Then destReg = "IX"
                        If idxMode = 2 Then destReg = "IY"
                        Return "ADD " & destReg & "," & MamuteReg16Text(regP, idxMode)
                    End If
                Case 2
                    If regQ = 0 Then
                        Select Case regP
                            Case 0 : Return "LD (BC),A"
                            Case 1 : Return "LD (DE),A"
                            Case 2
                                Dim wa2 As Integer = MamuteDisasmNextWord(curPos, consumed)
                                Dim rr2 As String = "HL"
                                If idxMode = 1 Then rr2 = "IX"
                                If idxMode = 2 Then rr2 = "IY"
                                Return "LD (" & Hex(wa2, 4) & "H)," & rr2
                            Case 3
                                Dim wa3 As Integer = MamuteDisasmNextWord(curPos, consumed)
                                Return "LD (" & Hex(wa3, 4) & "H),A"
                        End Select
                    Else
                        Select Case regP
                            Case 0 : Return "LD A,(BC)"
                            Case 1 : Return "LD A,(DE)"
                            Case 2
                                Dim wa4 As Integer = MamuteDisasmNextWord(curPos, consumed)
                                Dim rr4 As String = "HL"
                                If idxMode = 1 Then rr4 = "IX"
                                If idxMode = 2 Then rr4 = "IY"
                                Return "LD " & rr4 & ",(" & Hex(wa4, 4) & "H)"
                            Case 3
                                Dim wa5 As Integer = MamuteDisasmNextWord(curPos, consumed)
                                Return "LD A,(" & Hex(wa5, 4) & "H)"
                        End Select
                    End If
                Case 3
                    If regQ = 0 Then Return "INC " & MamuteReg16Text(regP, idxMode)
                    Return "DEC " & MamuteReg16Text(regP, idxMode)
                Case 4
                    Return "INC " & MamuteReg8TextAuto(y, idxMode, curPos, consumed)
                Case 5
                    Return "DEC " & MamuteReg8TextAuto(y, idxMode, curPos, consumed)
                Case 6
                    Dim destText6 As String = MamuteReg8TextAuto(y, idxMode, curPos, consumed)
                    Dim immVal6 As Integer = MamuteDisasmNextByte(curPos, consumed)
                    Return "LD " & destText6 & "," & Hex(immVal6, 2) & "H"
                Case 7
                    Select Case y
                        Case 0 : Return "RLCA"
                        Case 1 : Return "RRCA"
                        Case 2 : Return "RLA"
                        Case 3 : Return "RRA"
                        Case 4 : Return "DAA"
                        Case 5 : Return "CPL"
                        Case 6 : Return "SCF"
                        Case 7 : Return "CCF"
                    End Select
            End Select

        Case 1
            Dim dstText As String
            Dim srcText As String
            If y = 6 Or z = 6 Then
                If y = 6 Then
                    dstText = MamuteReg8TextAuto(6, idxMode, curPos, consumed)
                    srcText = MamuteReg8Text(z, 0, "")
                Else
                    dstText = MamuteReg8Text(y, 0, "")
                    srcText = MamuteReg8TextAuto(6, idxMode, curPos, consumed)
                End If
            Else
                dstText = MamuteReg8Text(y, idxMode, "")
                srcText = MamuteReg8Text(z, idxMode, "")
            End If
            Return "LD " & dstText & "," & srcText

        Case 2
            Return MamuteAluMnemonic(y) & MamuteReg8TextAuto(z, idxMode, curPos, consumed)

        Case 3
            Select Case z
                Case 0
                    Return "RET " & MamuteCondText(y)
                Case 1
                    If regQ = 0 Then
                        Return "POP " & MamuteReg16AltText(regP, idxMode)
                    Else
                        Select Case regP
                            Case 0 : Return "RET"
                            Case 1 : Return "EXX"
                            Case 2
                                Dim jpReg As String = "HL"
                                If idxMode = 1 Then jpReg = "IX"
                                If idxMode = 2 Then jpReg = "IY"
                                Return "JP (" & jpReg & ")"
                            Case 3
                                Dim ldReg As String = "HL"
                                If idxMode = 1 Then ldReg = "IX"
                                If idxMode = 2 Then ldReg = "IY"
                                Return "LD SP," & ldReg
                        End Select
                    End If
                Case 2
                    Dim jpAddr As Integer = MamuteDisasmNextWord(curPos, consumed)
                    Return "JP " & MamuteCondText(y) & "," & Hex(jpAddr, 4) & "H"
                Case 3
                    Select Case y
                        Case 0
                            Dim jpAddr2 As Integer = MamuteDisasmNextWord(curPos, consumed)
                            Return "JP " & Hex(jpAddr2, 4) & "H"
                        Case 2
                            Dim outN As Integer = MamuteDisasmNextByte(curPos, consumed)
                            Return "OUT (" & Hex(outN, 2) & "H),A"
                        Case 3
                            Dim inN As Integer = MamuteDisasmNextByte(curPos, consumed)
                            Return "IN A,(" & Hex(inN, 2) & "H)"
                        Case 4
                            Dim exReg As String = "HL"
                            If idxMode = 1 Then exReg = "IX"
                            If idxMode = 2 Then exReg = "IY"
                            Return "EX (SP)," & exReg
                        Case 5
                            Return "EX DE,HL"
                        Case 6
                            Return "DI"
                        Case 7
                            Return "EI"
                    End Select
                Case 4
                    Dim callAddr As Integer = MamuteDisasmNextWord(curPos, consumed)
                    Return "CALL " & MamuteCondText(y) & "," & Hex(callAddr, 4) & "H"
                Case 5
                    If regQ = 0 Then
                        Return "PUSH " & MamuteReg16AltText(regP, idxMode)
                    Else
                        If regP = 0 Then
                            Dim callAddr2 As Integer = MamuteDisasmNextWord(curPos, consumed)
                            Return "CALL " & Hex(callAddr2, 4) & "H"
                        End If
                    End If
                Case 6
                    Dim aluN As Integer = MamuteDisasmNextByte(curPos, consumed)
                    Return MamuteAluMnemonic(y) & Hex(aluN, 2) & "H"
                Case 7
                    Return "RST " & Hex(y * 8, 2) & "H"
            End Select
    End Select

    Return "DEFB " & Hex(b, 2) & "H"
End Function

' Decodifica UMA instrucao a partir de addr (consumindo prefixos DD/FD/CB/ED
' como precisar). outLen = quantos bytes a instrucao ocupou; outText = texto
' mnemonico pronto (sem o endereco/bytes crus na frente - quem chama monta
' isso).
Private Sub MamuteDisasmOne(ByVal addr As Integer, ByRef outLen As Integer, ByRef outText As String)
    Dim idxMode As Integer = 0
    Dim curPos As Integer = addr
    Dim consumed As Integer = 0
    Dim b As Integer = MamuteDisasmNextByte(curPos, consumed)

    Do While b = &HDD Or b = &HFD
        If b = &HDD Then idxMode = 1 Else idxMode = 2
        b = MamuteDisasmNextByte(curPos, consumed)
    Loop

    If b = &HCB Then
        Dim dispText As String = ""
        If idxMode <> 0 Then
            Dim d As Integer = MamuteDisasmNextByte(curPos, consumed)
            dispText = MamuteDispText(d)
        End If
        Dim op As Integer = MamuteDisasmNextByte(curPos, consumed)
        outText = MamuteDecodeCB(op, idxMode, dispText)
        outLen = consumed
        Exit Sub
    End If

    If b = &HED Then
        Dim op2 As Integer = MamuteDisasmNextByte(curPos, consumed)
        outText = MamuteDecodeED(op2, curPos, consumed)
        outLen = consumed
        Exit Sub
    End If

    If b = &H76 Then
        outText = "HALT"
        outLen = consumed
        Exit Sub
    End If

    outText = MamuteDecodePlain(b, idxMode, curPos, consumed)
    outLen = consumed
End Sub

' Monta uma linha "AAAA  XX XX XX     MNEMONICO" pronta pra AppendMamuteLine.
Private Function MamuteDisasmLine(ByVal addr As Integer) As String
    Dim instrLen As Integer
    Dim mnemonic As String
    MamuteDisasmOne(addr, instrLen, mnemonic)
    If instrLen < 1 Then instrLen = 1

    Dim bytesText As String = ""
    Dim i As Integer
    For i = 0 To instrLen - 1
        bytesText &= Hex(Mamute_ReadByte((addr + i) And 65535), 2) & " "
    Next i

    Return Hex(addr, 4) & "  " & Left(bytesText & Space(13), 13) & mnemonic
End Function

' Reconstroi a lista de linhas visiveis da grade (1 linha por slot sem
' sub-slots, ou 4 linhas Slot N.0-N.3 quando ligados) - chamado a cada volta
' do loop, ja que "T" pode mudar isso a qualquer momento.
Private Sub BuildMamuteMemVisibleRows(visSlot() As Integer, visSub() As Integer, ByRef visCount As Integer)
    ReDim visSlot(1 To 16)
    ReDim visSub(1 To 16)
    visCount = 0
    Dim slot As Integer
    For slot = 0 To 3
        If MamuteMemSubOn(slot) <> 0 Then
            Dim subIdx As Integer
            For subIdx = 0 To 3
                visCount += 1
                visSlot(visCount) = slot
                visSub(visCount) = subIdx
            Next subIdx
        Else
            visCount += 1
            visSlot(visCount) = slot
            visSub(visCount) = 0
        End If
    Next slot
End Sub

Private Sub ShowMamuteMemoryConfig()
    LoadMamuteMemConfig()
    Dim memDirty As Integer = 0

    Dim visSlot() As Integer
    Dim visSub() As Integer
    Dim visCount As Integer

    Dim selRowIdx As Integer = 1
    Dim selCol As Integer = 0
    Dim message As String = "Setas navega | Espaco tipo | Enter arquivo ROM | T sub-slots | V VRAM | L Carregar ROM 32KB | F2 salva | Esc cancela"

    Dim dialogW As Integer = Clamp(uiW - 8, 66, uiW)
    Dim dialogH As Integer = Clamp(uiH - 4, 20, uiH - 1)
    Dim dialogX As Integer = ((uiW - dialogW) \ 2) + 1
    Dim dialogY As Integer = ((uiH - dialogH) \ 2) + 1
    Dim listX As Integer = dialogX + 2
    Dim listY As Integer = dialogY + 4
    Dim listH As Integer = dialogH - 9
    Dim colW As Integer = 11

    Do
        BuildMamuteMemVisibleRows(visSlot(), visSub(), visCount)
        If selRowIdx < 1 Then selRowIdx = 1
        If selRowIdx > visCount Then selRowIdx = visCount
        Dim topIdx As Integer = 1
        If selRowIdx > listH Then topIdx = selRowIdx - listH + 1

        Dim curSlot As Integer = visSlot(selRowIdx)
        Dim curSub As Integer = visSub(selRowIdx)

        ConsoleBeginFrame()
        DrawDesktop()
        DrawDocumentsFull()
        DrawMenuBar(MENU_VIEW_NONE)
        DrawStatusBar()

        ConsoleWriteText(dialogX, dialogY, Chr(201) & String(dialogW - 2, Chr(205)) & Chr(187), 15, 1)
        Dim r As Integer
        For r = 1 To dialogH - 2
            ConsoleWriteText(dialogX, dialogY + r, Chr(186) & String(dialogW - 2, " ") & Chr(186), 15, 1)
        Next r
        ConsoleWriteText(dialogX, dialogY + dialogH - 1, Chr(200) & String(dialogW - 2, Chr(205)) & Chr(188), 15, 1)

        Dim titleStatus As String = ""
        If memDirty <> 0 Then titleStatus = " *NAO SALVO*"
        ConsoleWriteText(dialogX + 2, dialogY, " Configurar: Mamute (Memoria)" & titleStatus & " ", 0, 7, dialogW - 4)
        ConsoleWriteText(dialogX + 2, dialogY + 2, "Slot       Pag.0      Pag.1      Pag.2      Pag.3", 14, 1, dialogW - 4)
        Dim addrLine As String = Left("Enderecos:" & Space(colW), colW)
        Dim addrCol As Integer
        For addrCol = 0 To 3
            addrLine &= Left(MamutePageAddrRange(addrCol) & Space(colW), colW)
        Next addrCol
        ConsoleWriteText(dialogX + 2, dialogY + 3, Left(addrLine & String(dialogW - 4, " "), dialogW - 4), 8, 1)

        For r = 0 To listH - 1
            Dim idx As Integer = topIdx + r
            Dim rowY As Integer = listY + r
            ConsoleWriteText(listX, rowY, String(dialogW - 4, " "), 15, 1)
            If idx <= visCount Then
                Dim rSlot As Integer = visSlot(idx)
                Dim rSub As Integer = visSub(idx)
                Dim rowLabel As String
                If MamuteMemSubOn(rSlot) <> 0 Then
                    rowLabel = "Slot " & Trim(Str(rSlot)) & "." & Trim(Str(rSub))
                Else
                    rowLabel = "Slot " & Trim(Str(rSlot))
                End If
                ConsoleWriteText(listX, rowY, Left(rowLabel & Space(colW), colW), 15, 1)

                Dim c As Integer
                For c = 0 To 3
                    Dim cellFg As UByte = 15
                    Dim cellBg As UByte = 1
                    If idx = selRowIdx And c = selCol Then
                        cellFg = 0
                        cellBg = 7
                    End If
                    Dim cellText As String = MamuteCellTypeLabel(MamuteMemGrid(rSlot, rSub, c).cellType)
                    ConsoleWriteText(listX + colW + c * colW, rowY, Left(cellText & Space(colW), colW), cellFg, cellBg)
                Next c
            End If
        Next r

        Dim ByRef selCell As MamuteMemCell = MamuteMemGrid(curSlot, curSub, selCol)
        Dim detailText As String = "Selecionado: Slot " & Trim(Str(curSlot))
        If MamuteMemSubOn(curSlot) <> 0 Then detailText &= "." & Trim(Str(curSub))
        detailText &= " Pag." & Trim(Str(selCol)) & " (" & MamutePageAddrRange(selCol) & ") = " & MamuteCellTypeLabel(selCell.cellType)
        If selCell.cellType = MAMUTE_CELL_ROM Or selCell.cellType = MAMUTE_CELL_BIOS Or selCell.cellType = MAMUTE_CELL_BASIC Or selCell.cellType = MAMUTE_CELL_EXTBIOS Then
            detailText &= " (" & NormalizePathForDisplay(selCell.romPath) & ", offset " & Trim(Str(selCell.romOffset)) & ")"
        End If
        ConsoleWriteText(dialogX + 2, dialogY + dialogH - 5, Left("VRAM: " & Trim(Str(MamuteVramKB)) & "KB (V troca: 16/32/64/128/192)" & String(dialogW - 4, " "), dialogW - 4), 8, 1)
        ConsoleWriteText(dialogX + 2, dialogY + dialogH - 4, Left(detailText & String(dialogW - 4, " "), dialogW - 4), 11, 1)
        ConsoleWriteText(dialogX + 2, dialogY + dialogH - 3, Left("Sub-slots deste slot: " & IIf(MamuteMemSubOn(curSlot) <> 0, "ligados", "desligados") & String(dialogW - 4, " "), dialogW - 4), 8, 1)
        ConsoleWriteText(dialogX + 2, dialogY + dialogH - 2, Left(message & String(dialogW - 4, " "), dialogW - 4), 8, 1)

        ConsoleSetCursor(1, 1, 0)
        ConsoleFlush()
        ConsoleEndFrame()

        Dim eventType As Integer
        Dim keyText As String
        Dim mouseX As Integer
        Dim mouseY As Integer
        Dim mouseAction As Integer

        If ConsolePollInput(eventType, keyText, mouseX, mouseY, mouseAction) = 0 Then
            Sleep 5, 1
            Continue Do
        End If

        If eventType <> MSX_INPUT_KEY Then Continue Do
        keyText = NormalizeKey(keyText)

        If keyText = Chr(27) Then
            If memDirty <> 0 Then
                Dim action As Integer = PromptConfigExitAction("Mamute (Memoria)")
                Select Case action
                    Case CFG_EXIT_SAVE
                        SaveMamuteMemConfig()
                        message = "Mapa de memoria salvo."
                        Exit Do
                    Case CFG_EXIT_DISCARD
                        message = "Alteracoes descartadas."
                        Exit Do
                    Case Else
                        Continue Do
                End Select
            Else
                Exit Do
            End If
        End If

        If UCase(keyText) = "V" Then
            MamuteVramKB = NextMamuteVramSize(MamuteVramKB)
            memDirty = -1
            message = "VRAM definida para " & Trim(Str(MamuteVramKB)) & "KB."
            Continue Do
        End If

        If UCase(keyText) = "T" Then
            MamuteMemSubOn(curSlot) = IIf(MamuteMemSubOn(curSlot) <> 0, 0, -1)
            memDirty = -1
            message = "Sub-slots do Slot " & Trim(Str(curSlot)) & ": " & IIf(MamuteMemSubOn(curSlot) <> 0, "ligados", "desligados")
            Continue Do
        End If

        If UCase(keyText) = "L" Then
            Dim canceled4 As Integer
            Dim romFile As String = PromptPathDialog("Carregar ROM 32KB", "Arquivo .rom (32KB, BIOS+BASIC):", "", canceled4)
            If canceled4 = 0 And Len(romFile) > 0 Then
                Dim assignMsg4 As String
                AssignMamuteRomFile(curSlot, curSub, 0, MAMUTE_CELL_BIOS, romFile, assignMsg4)
                memDirty = -1
                message = assignMsg4
            End If
            Continue Do
        End If

        ' Espaco so cicla o TIPO da celula (barato pra explorar); o arquivo de
        ' ROM em si (com o preenchimento automatico de pagina vizinha pra
        ' BIOS/BASIC/ROM de 32KB) e atribuido separadamente com Enter, via
        ' AssignMamuteRomFile.
        If keyText = " " Then
            Dim ByRef cellSp As MamuteMemCell = MamuteMemGrid(curSlot, curSub, selCol)
            Select Case cellSp.cellType
                Case MAMUTE_CELL_NONE
                    cellSp.cellType = MAMUTE_CELL_RAM
                Case MAMUTE_CELL_RAM
                    cellSp.cellType = MAMUTE_CELL_ROM
                Case MAMUTE_CELL_ROM
                    cellSp.cellType = MAMUTE_CELL_BIOS
                Case MAMUTE_CELL_BIOS
                    cellSp.cellType = MAMUTE_CELL_BASIC
                Case MAMUTE_CELL_BASIC
                    cellSp.cellType = MAMUTE_CELL_EXTBIOS
                Case Else
                    cellSp.cellType = MAMUTE_CELL_NONE
            End Select
            If cellSp.cellType = MAMUTE_CELL_NONE Or cellSp.cellType = MAMUTE_CELL_RAM Then
                cellSp.romPath = ""
                cellSp.romOffset = 0
            End If
            memDirty = -1
            Continue Do
        End If

        If keyText = Chr(13) Then
            Dim ByRef cellEn As MamuteMemCell = MamuteMemGrid(curSlot, curSub, selCol)
            If cellEn.cellType = MAMUTE_CELL_ROM Or cellEn.cellType = MAMUTE_CELL_BIOS Or cellEn.cellType = MAMUTE_CELL_BASIC Or cellEn.cellType = MAMUTE_CELL_EXTBIOS Then
                Dim canceled2 As Integer
                Dim newPath As String = PromptPathDialog("ROM da pagina", "Arquivo .rom:", cellEn.romPath, canceled2)
                If canceled2 = 0 And Len(newPath) > 0 Then
                    Dim assignMsg As String
                    AssignMamuteRomFile(curSlot, curSub, selCol, cellEn.cellType, newPath, assignMsg)
                    memDirty = -1
                    message = assignMsg
                End If
            End If
            Continue Do
        End If

        If Len(keyText) = 2 And Asc(Left(keyText, 1)) = 0 Then
            Select Case Asc(Right(keyText, 1))
                Case 72
                    selRowIdx -= 1
                Case 80
                    selRowIdx += 1
                Case 75
                    selCol = Clamp(selCol - 1, 0, 3)
                Case 77
                    selCol = Clamp(selCol + 1, 0, 3)
                Case 71
                    selRowIdx = 1
                Case 79
                    selRowIdx = visCount
                Case 60
                    SaveMamuteMemConfig()
                    message = "Mapa de memoria salvo."
                    Exit Do
            End Select
        End If
    Loop

    FinalizeModalInputState()
    forceFullRedraw = 1
    renderMode = RENDER_FULL
End Sub

Sub ShowConfigForm(ByRef titleText As String, ByRef configGroup As String)
    Dim fields() As ConfigField
    Dim fieldCount As Integer = 0
    Dim grp As String = LCase(configGroup)

    If grp = "badig" Then
        AddConfigField(fields(), fieldCount, "cfg.badig.use_ini_file", "Use INI File", CFG_KIND_BOOL, "True", "Ler defaults do INI")
        AddConfigField(fields(), fieldCount, "cfg.badig.source_file", "Source File", CFG_KIND_PATH, "", "Arquivo de entrada")
        AddConfigField(fields(), fieldCount, "cfg.badig.destin_file", "Destin File", CFG_KIND_PATH, "", "Arquivo de saida")
        AddConfigField(fields(), fieldCount, "cfg.badig.system_id", "System ID", CFG_KIND_ENUM, "msx", "Dialeto alvo", "msx|coco")
        AddConfigField(fields(), fieldCount, "cfg.badig.line_start", "Line Start", CFG_KIND_INT, "10", "Primeira linha", "", -1, 1, 65535)
        AddConfigField(fields(), fieldCount, "cfg.badig.line_step", "Line Step", CFG_KIND_INT, "10", "Incremento", "", -1, 1, 9999)
        AddConfigField(fields(), fieldCount, "cfg.badig.rem_header", "REM Header", CFG_KIND_TEXT, "", "Texto de cabecalho")
        AddConfigField(fields(), fieldCount, "cfg.badig.strip_spaces", "Strip Spaces", CFG_KIND_BOOL, "False", "Remover espacos extras")
        AddConfigField(fields(), fieldCount, "cfg.badig.capitalize_all", "Capitalize All", CFG_KIND_BOOL, "False", "Forcar maiusculas")
        AddConfigField(fields(), fieldCount, "cfg.badig.translate", "Translate", CFG_KIND_BOOL, "False", "Traduzir palavras-chave")
        AddConfigField(fields(), fieldCount, "cfg.badig.print_report", "Print Report", CFG_KIND_BOOL, "False", "Resumo no fim")
        AddConfigField(fields(), fieldCount, "cfg.badig.label_report", "Label Report", CFG_KIND_BOOL, "False", "Relatorio de labels")
        AddConfigField(fields(), fieldCount, "cfg.badig.var_report", "Var Report", CFG_KIND_BOOL, "False", "Relatorio de variaveis")
        AddConfigField(fields(), fieldCount, "cfg.badig.line_report", "Line Report", CFG_KIND_BOOL, "False", "Relatorio de linhas")
        AddConfigField(fields(), fieldCount, "cfg.badig.lexer_report", "Lexer Report", CFG_KIND_BOOL, "False", "Relatorio do lexer")
        AddConfigField(fields(), fieldCount, "cfg.badig.parser_report", "Parser Report", CFG_KIND_BOOL, "False", "Relatorio do parser")
        AddConfigField(fields(), fieldCount, "cfg.badig.tab_lenght", "Tab Length", CFG_KIND_INT, "4", "Largura do TAB", "", -1, 1, 16)
        AddConfigField(fields(), fieldCount, "cfg.badig.verbose_level", "Verbose Level", CFG_KIND_INT, "3", "Nivel de log", "", -1, 0, 5)
    ElseIf grp = "msxbasic" Then
        AddConfigField(fields(), fieldCount, "cfg.msxbasic.badig.convert_print", "Convert PRINT", CFG_KIND_ENUM, "PRINT", "Modo de PRINT: ? ou PRINT", "?|PRINT")
        fields(fieldCount).value = NormalizeMsxBasicConvertPrintValue(fields(fieldCount).value)
        fields(fieldCount).originalValue = fields(fieldCount).value

        AddConfigField(fields(), fieldCount, "cfg.msxbasic.badig.strip_then_goto", "Strip THEN GOTO", CFG_KIND_ENUM, "THEN", "Modo IF jump: THEN ou GOTO", "THEN|GOTO")
        fields(fieldCount).value = NormalizeMsxBasicThenGotoValue(fields(fieldCount).value)
        fields(fieldCount).originalValue = fields(fieldCount).value
        AddConfigField(fields(), fieldCount, "cfg.msxbasic.tokenizer.file_load", "Tokenizer File Load", CFG_KIND_PATH, "", "Arquivo de entrada tokenizer")
        AddConfigField(fields(), fieldCount, "cfg.msxbasic.tokenizer.file_save", "Tokenizer File Save", CFG_KIND_PATH, "", "Arquivo de saida tokenizer")
        AddConfigField(fields(), fieldCount, "cfg.msxbasic.tokenizer.list", "Tokenizer List", CFG_KIND_INT, "16", "Formato de listagem", "", -1, 0, 99)
        AddConfigField(fields(), fieldCount, "cfg.msxbasic.tokenizer.del_ascii", "Tokenizer Del ASCII", CFG_KIND_BOOL, "False", "Remove ASCII extra")
        AddConfigField(fields(), fieldCount, "cfg.msxbasic.tokenizer.verbose", "Tokenizer Verbose", CFG_KIND_INT, "3", "Nivel de log tokenizer", "", -1, 0, 5)
    ElseIf grp = "emulator" Then
        AddConfigField(fields(), fieldCount, "cfg.emulator.run", "Run", CFG_KIND_BOOL, "False", "Executar emulador apos build")
        AddConfigField(fields(), fieldCount, "cfg.emulator.setting", "Setting", CFG_KIND_TEXT, "", "Preset/settings")
        AddConfigField(fields(), fieldCount, "cfg.emulator.machine", "Machine", CFG_KIND_TEXT, "", "Maquina alvo")
        AddConfigField(fields(), fieldCount, "cfg.emulator.extension", "Extension", CFG_KIND_TEXT, "", "Extensao de arquivo")
        AddConfigField(fields(), fieldCount, "cfg.emulator.monitor", "Monitor", CFG_KIND_BOOL, "False", "Abrir monitor")
        AddConfigField(fields(), fieldCount, "cfg.emulator.nothrottle", "No Throttle", CFG_KIND_BOOL, "False", "Sem limitacao de velocidade")
        AddConfigField(fields(), fieldCount, "cfg.emulator.clean_disk_dir", "Clean Disk Dir", CFG_KIND_BOOL, "False", "Limpar pasta disk antes de gerar DSK")
        AddConfigField(fields(), fieldCount, "cfg.emulator.verbose", "Verbose", CFG_KIND_BOOL, "False", "Logs verbosos")
        AddConfigField(fields(), fieldCount, "cfg.emulator.windows.emulator_path", "Windows Emulator Path", CFG_KIND_PATH, "PATH_TO\\openmsx.exe", "Caminho do openmsx.exe")
        AddConfigField(fields(), fieldCount, "cfg.emulator.darwin.emulator_path", "Darwin Emulator Path", CFG_KIND_PATH, "PATH_TO/openMSX.app", "Caminho no macOS")
        AddConfigField(fields(), fieldCount, "cfg.emulator.linux.emulator_path", "Linux Emulator Path", CFG_KIND_PATH, "PATH_TO/openMSX", "Caminho no Linux")
    End If

    If fieldCount <= 0 Then Exit Sub

    Dim i As Integer
    For i = 1 To fieldCount
        If fields(i).kind = CFG_KIND_BOOL Then
            Dim norm As String
            If NormalizeBoolText(fields(i).value, norm) <> 0 Then
                fields(i).value = norm
                fields(i).originalValue = norm
            End If
        End If
        RefreshFieldDirty(fields(i))
    Next i

    Dim dialogW As Integer = Clamp(uiW - 8, 72, uiW)
    Dim dialogH As Integer = Clamp(uiH - 4, 14, uiH - 1)
    Dim dialogX As Integer = ((uiW - dialogW) \ 2) + 1
    Dim dialogY As Integer = ((uiH - dialogH) \ 2) + 1
    Dim listX As Integer = dialogX + 2
    Dim listY As Integer = dialogY + 2
    Dim listW As Integer = dialogW - 4
    Dim listH As Integer = dialogH - 6
    Dim selected As Integer = 1
    Dim topIdx As Integer = 1
    Dim message As String = "Setas navegam | Enter edita | Space toggle | F2 salva | F5/R padrao | Esc cancela"

    Do
        If selected < 1 Then selected = 1
        If selected > fieldCount Then selected = fieldCount
        If selected < topIdx Then topIdx = selected
        If selected > topIdx + listH - 1 Then topIdx = selected - listH + 1
        If topIdx < 1 Then topIdx = 1

        ConsoleBeginFrame()
        DrawDesktop()
        DrawDocumentsFull()
        DrawMenuBar(MENU_VIEW_NONE)
        DrawStatusBar()

        ConsoleWriteText(dialogX, dialogY, Chr(201) & String(dialogW - 2, Chr(205)) & Chr(187), 15, 1)
        Dim r As Integer
        For r = 1 To dialogH - 2
            ConsoleWriteText(dialogX, dialogY + r, Chr(186) & String(dialogW - 2, " ") & Chr(186), 15, 1)
        Next r
        ConsoleWriteText(dialogX, dialogY + dialogH - 1, Chr(200) & String(dialogW - 2, Chr(205)) & Chr(188), 15, 1)

        Dim hasDirty As Integer = AnyConfigFieldDirty(fields(), fieldCount)
        Dim titleStatus As String = ""
        If hasDirty <> 0 Then titleStatus = " *NAO SALVO*"
        ConsoleWriteText(dialogX + 2, dialogY, " Configurar: " & titleText & titleStatus & " ", 0, 7, dialogW - 4)
        ConsoleWriteText(dialogX + 2, dialogY + 1, "Campo", 14, 1, 24)
        ConsoleWriteText(dialogX + 28, dialogY + 1, "Valor", 14, 1, dialogW - 30)

        For r = 0 To listH - 1
            Dim idx As Integer = topIdx + r
            Dim fg As UByte = 15
            Dim bg As UByte = 1
            If idx = selected Then
                fg = 0
                bg = 7
            End If

            Dim rowY As Integer = listY + r
            ConsoleWriteText(listX, rowY, String(listW, " "), fg, bg)

            If idx <= fieldCount Then
                Dim dirtyMark As String = IIf(fields(idx).dirty <> 0, "*", " ")
                Dim labelTxt As String = Left(dirtyMark & " " & fields(idx).label & String(24, " "), 24)
                Dim valueTxt As String = fields(idx).value
                Dim valueFg As UByte = fg
                Dim valueBg As UByte = bg
                If fields(idx).dirty <> 0 Then
                    If idx = selected Then
                        valueFg = 15
                        valueBg = 4
                    Else
                        valueFg = 14
                        valueBg = 1
                    End If
                End If
                If Len(valueTxt) > listW - 28 Then valueTxt = Left(valueTxt, listW - 29) & Chr(250)
                ConsoleWriteText(listX, rowY, labelTxt, fg, bg)
                ConsoleWriteText(listX + 26, rowY, valueTxt, valueFg, valueBg, listW - 26)
            End If
        Next r

        Dim hintText As String = fields(selected).hint
        If fields(selected).kind = CFG_KIND_ENUM Then
            hintText &= " [" & fields(selected).options & "]"
        ElseIf fields(selected).kind = CFG_KIND_INT And fields(selected).hasIntRange <> 0 Then
            hintText &= " [" & Trim(Str(fields(selected).minInt)) & ".." & Trim(Str(fields(selected).maxInt)) & "]"
        End If
        ConsoleWriteText(dialogX + 2, dialogY + dialogH - 3, Left(hintText & String(dialogW - 4, " "), dialogW - 4), 11, 1)
        ConsoleWriteText(dialogX + 2, dialogY + dialogH - 2, Left(message & String(dialogW - 4, " "), dialogW - 4), 8, 1)

        ConsoleSetCursor(1, 1, 0)
        ConsoleFlush()
        ConsoleEndFrame()

        Dim eventType As Integer
        Dim keyText As String
        Dim mouseX As Integer
        Dim mouseY As Integer
        Dim mouseAction As Integer

        If ConsolePollInput(eventType, keyText, mouseX, mouseY, mouseAction) = 0 Then
            Sleep 5, 1
            Continue Do
        End If

        If eventType <> MSX_INPUT_KEY Then Continue Do
        keyText = NormalizeKey(keyText)

        If keyText = Chr(27) Then
            If AnyConfigFieldDirty(fields(), fieldCount) <> 0 Then
                Dim action As Integer = PromptConfigExitAction(titleText)
                Select Case action
                    Case CFG_EXIT_SAVE
                        SaveConfigFields(fields(), fieldCount)
                        message = "Configuracoes salvas no banco."
                        Exit Do
                    Case CFG_EXIT_DISCARD
                        message = "Alteracoes descartadas."
                        Exit Do
                    Case Else
                        message = "Saida cancelada; alteracoes mantidas."
                        Continue Do
                End Select
            Else
                Exit Do
            End If
        End If

        If keyText = " " And fields(selected).kind = CFG_KIND_BOOL Then
            If LCase(fields(selected).value) = "true" Or fields(selected).value = "1" Then
                fields(selected).value = "False"
            Else
                fields(selected).value = "True"
            End If
            RefreshFieldDirty(fields(selected))
            message = "Campo alterado. Pressione F2 para salvar."
            Continue Do
        End If

        If Len(keyText) = 1 Then
            If UCase(keyText) = "S" Then
                SaveConfigFields(fields(), fieldCount)
                message = "Configuracoes salvas no banco."
                Exit Do
            ElseIf UCase(keyText) = "R" Then
                RestoreConfigDefaults(fields(), fieldCount)
                message = "Padroes restaurados. Pressione F2 para salvar."
                Continue Do
            End If
        End If

        If keyText = Chr(13) Then
            Dim canceled As Integer
            Dim promptTitle As String = "Editar: " & fields(selected).label
            Dim rawValue As String = PromptPathDialog(promptTitle, "Valor:", fields(selected).value, canceled)
            If canceled <> 0 Then Continue Do

            Dim normalized As String
            Dim errText As String
            If ValidateConfigValue(fields(selected).kind, rawValue, fields(selected).options, fields(selected).hasIntRange, fields(selected).minInt, fields(selected).maxInt, normalized, errText) = 0 Then
                message = errText
            Else
                fields(selected).value = normalized
                RefreshFieldDirty(fields(selected))
                message = "Campo alterado. Pressione F2 para salvar."
            End If
            Continue Do
        End If

        If Len(keyText) = 2 And Asc(Left(keyText, 1)) = 0 Then
            Select Case Asc(Right(keyText, 1))
                Case 72
                    selected -= 1
                Case 80
                    selected += 1
                Case 73
                    selected -= listH
                Case 81
                    selected += listH
                Case 71
                    selected = 1
                Case 79
                    selected = fieldCount
                Case 75
                    If fields(selected).kind = CFG_KIND_ENUM Then
                        fields(selected).value = EnumCycleValue(fields(selected).options, fields(selected).value, -1)
                        RefreshFieldDirty(fields(selected))
                        message = "Campo alterado. Pressione F2 para salvar."
                    End If
                Case 77
                    If fields(selected).kind = CFG_KIND_ENUM Then
                        fields(selected).value = EnumCycleValue(fields(selected).options, fields(selected).value, 1)
                        RefreshFieldDirty(fields(selected))
                        message = "Campo alterado. Pressione F2 para salvar."
                    End If
                Case 60
                    SaveConfigFields(fields(), fieldCount)
                    message = "Configuracoes salvas no banco."
                    Exit Do
                Case 63
                    RestoreConfigDefaults(fields(), fieldCount)
                    message = "Padroes restaurados. Pressione F2 para salvar."
            End Select
        End If
    Loop

    FinalizeModalInputState()
    forceFullRedraw = 1
    renderMode = RENDER_FULL
End Sub

Private Function MenuCommandFromKey(ByVal menuView As Integer, ByRef keyText As String) As Integer
    If menuView = MENU_VIEW_COMPILE Then
        If Len(keyText) = 1 Then
            Select Case UCase(keyText)
                Case "M"
                    Return MENU_CMD_COMPILE_MSX
                Case "D"
                    Return MENU_CMD_COMPILE_DIGNIFIED
                Case "A"
                    Return MENU_CMD_COMPILE_TOKENIZE_AMX
                Case "E"
                    Return MENU_CMD_COMPILE_RUN_EMU
                Case "L"
                    Return MENU_CMD_COMPILE_OPEN_LOG
            End Select
        End If
        Return MENU_CMD_NONE
    End If

    If menuView = MENU_VIEW_CONFIG Then
        If Len(keyText) = 1 Then
            Select Case UCase(keyText)
                Case "B"
                    Return MENU_CMD_CFG_BADIG
                Case "M"
                    Return MENU_CMD_CFG_MSX
                Case "E"
                    Return MENU_CMD_CFG_EMULATOR
                Case "A"
                    Return MENU_CMD_CFG_MAMUTE_MEM
            End Select
        End If
        Return MENU_CMD_NONE
    End If

    If menuView = MENU_VIEW_HELP Then
        If Len(keyText) = 1 Then
            Select Case UCase(keyText)
                Case "B"
                    Return MENU_CMD_HELP_BASIC
                Case "D"
                    Return MENU_CMD_HELP_DIGNIFIED
                Case "T"
                    Return MENU_CMD_HELP_BATOKEN
                Case "A"
                    Return MENU_CMD_HELP_ASMSX
                Case "M"
                    Return MENU_CMD_HELP_MSX_DICT
                Case "E"
                    Return MENU_CMD_HELP_EDITOR
                Case "N"
                    Return MENU_CMD_MAMUTE_HELP
                Case "C"
                    Return MENU_CMD_HELP_THEME
            End Select
        End If
        Return MENU_CMD_NONE
    End If

    If menuView = MENU_VIEW_REFERENCE Then
        If Len(keyText) = 1 Then
            Select Case UCase(keyText)
                Case "R"
                    Return MENU_CMD_REF_REDBOOK
                Case "N"
                    Return MENU_CMD_REF_NESTOR
                Case "T"
                    Return MENU_CMD_REF_HANDBOOK
                Case "M"
                    Return MENU_CMD_REF_MANUALS
                Case "C"
                    Return MENU_CMD_REF_BIOSCALLS
                Case "W"
                    Return MENU_CMD_REF_HARDWARE
                Case "D"
                    Return MENU_CMD_REF_BIOSDOC
                Case "S"
                    Return MENU_CMD_REF_SEETRACKER
                Case "O"
                    Return MENU_CMD_REF_OPENMSX
                Case "X"
                    Return MENU_CMD_REF_MSXBAS2ROM
            End Select
        End If
        Return MENU_CMD_NONE
    End If

    If menuView = MENU_VIEW_MAMUTE Then
        If Len(keyText) = 1 Then
            Select Case UCase(keyText)
                Case "A"
                    Return MENU_CMD_MAMUTE_OPEN
            End Select
        End If
        Return MENU_CMD_NONE
    End If

    If Len(keyText) = 1 Then
        Select Case UCase(keyText)
            Case "N"
                Return MENU_CMD_NEW
            Case "Z"
                Return MENU_CMD_NEW_ASMSX
            Case "O"
                Return MENU_CMD_OPEN
            Case "S"
                Return MENU_CMD_SAVE
            Case "A"
                Return MENU_CMD_SAVE_AS
            Case "F"
                Return MENU_CMD_CLOSE
            Case "X"
                Return MENU_CMD_EXIT
            Case "P"
                Return MENU_CMD_PROJECT_NEW
            Case "J"
                Return MENU_CMD_PROJECT_OPEN
            Case "K"
                Return MENU_CMD_PROJECT_SAVE
            Case "W"
                Return MENU_CMD_PROJECT_CLOSE
        End Select
    End If

    If Len(keyText) = 2 And Asc(Left(keyText, 1)) = 0 Then
        Select Case Asc(Right(keyText, 1))
            Case 60
                Return MENU_CMD_SAVE
            Case 61
                Return MENU_CMD_OPEN
            Case 62
                Return MENU_CMD_NEW
            Case 63
                Return MENU_CMD_CLOSE
        End Select
    End If

    Return MENU_CMD_NONE
End Function

Private Sub ExecuteProjectNew()
    Dim canceled As Integer
    Dim initial As String = "projeto.msxproj"
    Dim path As String = PromptPathDialog("Novo Projeto", "Caminho do projeto (.msxproj):", initial, canceled)
    If canceled <> 0 Or Len(path) = 0 Then Exit Sub

    path = ToAbsolutePath(path)
    Dim errMsg As String = ""
    If ProjectNew(path, errMsg) = 0 Then
        ShowInfoDialog("Projeto", "Falha ao criar projeto.", errMsg)
        Exit Sub
    End If

    ShowInfoDialog("Projeto", "Projeto criado: " & ProjectActiveName(), NormalizePathForDisplay(ProjectActivePath()))
End Sub

Private Sub ExecuteProjectOpen()
    Dim canceled As Integer
    Dim initial As String = ""
    Dim path As String = PromptPathDialog("Abrir Projeto", "Caminho do projeto (.msxproj):", initial, canceled)
    If canceled <> 0 Or Len(path) = 0 Then Exit Sub

    path = ToAbsolutePath(path)
    Dim errMsg As String = ""
    If ProjectOpen(path, errMsg) = 0 Then
        ShowInfoDialog("Projeto", "Falha ao abrir projeto.", errMsg)
        Exit Sub
    End If

    ShowInfoDialog("Projeto", "Projeto aberto: " & ProjectActiveName(), NormalizePathForDisplay(ProjectActivePath()))
End Sub

Private Sub ExecuteProjectSave()
    If ProjectIsActive() = 0 Then
        ShowInfoDialog("Projeto", "Nenhum projeto aberto.", "")
        Exit Sub
    End If

    Dim errMsg As String = ""
    Dim savedCount As Integer = 0
    If ProjectSave(errMsg, savedCount) = 0 Then
        ShowInfoDialog("Projeto", "Falha ao salvar projeto.", errMsg)
        Exit Sub
    End If

    ShowInfoDialog("Projeto", "Projeto salvo: " & ProjectActiveName(), Trim(Str(savedCount)) & " arquivo(s) reimportado(s).")
End Sub

Private Sub ExecuteProjectClose()
    If ProjectIsActive() = 0 Then
        ShowInfoDialog("Projeto", "Nenhum projeto aberto.", "")
        Exit Sub
    End If

    Dim projName As String = ProjectActiveName()
    Dim errMsg As String = ""
    Dim savedCount As Integer = 0
    ProjectSave(errMsg, savedCount)
    ProjectClose()

    ShowInfoDialog("Projeto", "Projeto fechado: " & projName, "")
End Sub

Private Sub ExecuteMenuCommand(ByVal commandId As Integer, ByRef running As Integer, ByRef menuOpen As Integer)
    Select Case commandId
        Case MENU_CMD_NEW
            EditorCreateUntitled()
        Case MENU_CMD_NEW_ASMSX
            EditorCreateAsmUntitled()
        Case MENU_CMD_OPEN
            OpenDocumentDialog()
        Case MENU_CMD_SAVE
            SaveActiveDocumentToDisk()
        Case MENU_CMD_SAVE_AS
            SaveActiveDocumentAsDialog()
        Case MENU_CMD_CLOSE
            CloseActiveDocument()
        Case MENU_CMD_EXIT
            running = 0
        Case MENU_CMD_PROJECT_NEW
            ExecuteProjectNew()
        Case MENU_CMD_PROJECT_OPEN
            ExecuteProjectOpen()
        Case MENU_CMD_PROJECT_SAVE
            ExecuteProjectSave()
        Case MENU_CMD_PROJECT_CLOSE
            ExecuteProjectClose()
        Case MENU_CMD_CFG_BADIG
            ShowConfigForm("Basic Dignified", "badig")
        Case MENU_CMD_CFG_MSX
            ShowConfigForm("MSX Basic", "msxbasic")
        Case MENU_CMD_CFG_EMULATOR
            ShowConfigForm("Emulador", "emulator")
        Case MENU_CMD_COMPILE_MSX
            CompileActiveDocument(COMPILE_MODE_MSX)
        Case MENU_CMD_COMPILE_DIGNIFIED
            CompileActiveDocument(COMPILE_MODE_DIGNIFIED)
        Case MENU_CMD_COMPILE_TOKENIZE_AMX
            CompileActiveDocument(COMPILE_MODE_TOKENIZE_AMX)
        Case MENU_CMD_COMPILE_RUN_EMU
            CompileActiveDocument(COMPILE_MODE_RUN_EMU)
        Case MENU_CMD_COMPILE_OPEN_LOG
            OpenCompileLogDocument()
        Case MENU_CMD_HELP_BASIC
            OpenHelpDocument("Basic Dignified", "dbhelp:BASIC_DIGNIFIED|basic-dignified\documentation\BASIC_DIGNIFIED.md")
        Case MENU_CMD_HELP_DIGNIFIED
            OpenHelpDocument("Dignified", "dbhelp:DIGNIFIED|basic-dignified\documentation\DIGNIFIED.md")
        Case MENU_CMD_HELP_BATOKEN
            OpenHelpDocument("BaToken", "dbhelp:BATOKEN|basic-dignified\documentation\BATOKEN.md")
        Case MENU_CMD_HELP_ASMSX
            OpenHelpDocument("asMSX", "dbhelp:ASMSX|asMSX\doc\asmsx.md")
        Case MENU_CMD_HELP_MSX_DICT
            OpenMsxDictHelp()
        Case MENU_CMD_HELP_EDITOR
            OpenHelpDocument("Editor", "dbhelp:EDITOR|docs\help\editor.md")
        Case MENU_CMD_HELP_THEME
            If helpTheme = HELP_THEME_EDITORIAL Then
                helpTheme = HELP_THEME_CLASSIC
            Else
                helpTheme = HELP_THEME_EDITORIAL
            End If
            ApplyHelpTheme()
        Case MENU_CMD_REF_REDBOOK
            OpenRefDictHelp("redbook")
        Case MENU_CMD_REF_HANDBOOK
            OpenRefDictHelp("th2handbook")
        Case MENU_CMD_REF_MANUALS
            OpenRefDictHelp("msxmanuals")
        Case MENU_CMD_REF_BIOSCALLS
            OpenRefDictHelp("bioscalls")
        Case MENU_CMD_REF_HARDWARE
            OpenRefDictHelp("hardware")
        Case MENU_CMD_REF_BIOSDOC
            OpenRefDictHelp("biosdoc")
        Case MENU_CMD_REF_OPENMSX
            OpenRefDictHelp("openmsx")
        Case MENU_CMD_REF_NESTOR
            OpenHelpDocument("Nestor Basic", "dbhelp:NESTORBASIC|docs\help\nestorbasic.md")
        Case MENU_CMD_REF_SEETRACKER
            OpenHelpDocument("SEE Tracker", "dbhelp:SEETRACKER|docs\help\seetracker.md")
        Case MENU_CMD_REF_MSXBAS2ROM
            OpenHelpDocument("MSXBAS2ROM", "dbhelp:MSXBAS2ROM|docs\help\msxbas2rom.md")
        Case MENU_CMD_CFG_MAMUTE_MEM
            ShowMamuteMemoryConfig()
        Case MENU_CMD_MAMUTE_OPEN
            EditorCreateMamuteTerm()
        Case MENU_CMD_MAMUTE_HELP
            OpenHelpDocument("Mamute Assembler", "dbhelp:MAMUTE|docs\help\mamute.md")
    End Select

    menuOpen = 0
    forceFullRedraw = 1
    renderMode = RENDER_FULL
End Sub

Private Sub HandleEditorKey(ByRef keyText As String, ByRef running As Integer, ByRef needFullRedraw As Integer, ByRef renderHint As Integer)
    Dim ByRef d As Document = docs(activeDoc)
    renderHint = RENDER_CURSOR

    If d.isMamuteTerm <> 0 And mamuteMEditActive(activeDoc) <> 0 Then
        HandleMamuteMEditKey(d, keyText, renderHint)
        Exit Sub
    End If

    If d.isMamuteTerm <> 0 Then
        HandleMamuteTermKey(d, keyText, renderHint)
        Exit Sub
    End If

    If d.isMamuteEdit <> 0 Then
        HandleMamuteEditKey(d, keyText, renderHint)
        Exit Sub
    End If

    If d.isHelp <> 0 And keyText = Chr(13) Then
        If OpenMsxDictFromActiveIndexCursor() <> 0 Then
            needFullRedraw = 1
            renderHint = RENDER_FULL
        End If
        Exit Sub
    End If

    If keyText = Chr(13) Then
        InsertNewLine(d)
        renderHint = RENDER_CLIENT
        Exit Sub
    End If

    If d.isHelp <> 0 And keyText = Chr(8) Then Exit Sub

    If keyText = Chr(8) Then
        If d.cursorX > 1 Then
            renderHint = RENDER_LINE
        Else
            renderHint = RENDER_CLIENT
        End If
        BackspaceAtCursor(d)
        Exit Sub
    End If

    If Len(keyText) = 1 Then
        If d.isHelp <> 0 Then Exit Sub
        Dim c As Integer = Asc(keyText)
        If c >= 32 And c <= 126 Then
            InsertCharAtCursor(d, keyText)
            renderHint = RENDER_LINE
        End If
        Exit Sub
    End If

    If Len(keyText) = 2 And Asc(Left(keyText, 1)) = 0 Then
        Select Case Asc(Right(keyText, 1))
            Case 75
                MoveLeft(d)
            Case 77
                MoveRight(d)
            Case 72
                MoveUp(d)
            Case 80
                MoveDown(d)
            Case 71
                d.cursorX = 1
            Case 79
                d.cursorX = Len(d.lines(d.cursorY)) + 1
            Case 73
                d.cursorY = Clamp(d.cursorY - GetClientTextHeight(d), 1, d.lineCount)
                d.cursorX = Clamp(d.cursorX, 1, Len(d.lines(d.cursorY)) + 1)
            Case 81
                d.cursorY = Clamp(d.cursorY + GetClientTextHeight(d), 1, d.lineCount)
                d.cursorX = Clamp(d.cursorX, 1, Len(d.lines(d.cursorY)) + 1)
            Case 83
                If d.isHelp <> 0 Then Exit Select
                If d.cursorX <= Len(d.lines(d.cursorY)) Then
                    renderHint = RENDER_LINE
                Else
                    renderHint = RENDER_CLIENT
                End If
                DeleteAtCursor(d)
            Case 64
                If docCount > 1 Then
                    Dim nextDoc As Integer = activeDoc + 1
                    If nextDoc > docCount Then nextDoc = 1
                    BringDocumentToFront(nextDoc)
                    needFullRedraw = 1
                    renderHint = RENDER_FULL
                End If
            Case 62
                EditorCreateUntitled()
                needFullRedraw = 1
                renderHint = RENDER_FULL
            Case 61
                OpenDocumentDialog()
                needFullRedraw = 1
                renderHint = RENDER_FULL
            Case 60
                SaveActiveDocumentToDisk()
            Case 63
                CloseActiveDocument()
                needFullRedraw = 1
                renderHint = RENDER_FULL
        End Select
    End If
End Sub

Sub EditorInit(ByRef startupName As String)
    ConsoleGetCurrentSize(uiW, uiH)
    ConsoleInit(uiW, uiH)
    ConsoleClear(7, 0)

    docCount = 0
    activeDoc = 0
    untitledCounter = 1
    untitledAsmCounter = 0
    forceFullRedraw = 1
    renderMode = RENDER_FULL
    perfBackendVersion = DbGetSetting("backend_version", "win32-buffer-v3")
    dragMode = DRAG_NONE
    ApplyHelpTheme()
    PerfResetBucket()

    EditorOpenFromPath(startupName)
End Sub

Sub EditorOpenFromPath(ByRef path As String)
    If docCount >= MAX_DOCS Then Exit Sub

    docCount += 1
    activeDoc = docCount

    InitBlankDocument(docs(docCount), path)
    ClearMsxDictLineMap(docCount)
    If Dir(path) <> "" Then
        LoadFromDisk(docs(docCount), path)
    End If

    LayoutNewDocumentWindow(docCount)
    forceFullRedraw = 1
    renderMode = RENDER_FULL
End Sub

Sub EditorCreateUntitled()
    Dim docName As String
    Do
        docName = "msx" & Right("00" & Trim(Str(untitledCounter)), 2) & ".dmx"
        untitledCounter += 1
    Loop While untitledCounter < 100 And docName = "msx00.dmx"

    EditorOpenFromPath(docName)
End Sub

Private Function BuildAsmHelloWorldTemplate(ByRef baseName As String) As String
    Dim s As String

    s = "; ------------------------------------------------------------------" & Chr(10)
    s &= "; " & baseName & ".asm - Hello ASM World" & Chr(10)
    s &= "; Modelo inicial gerado pelo msxIDE para o assembler asMSX (Z80/MSX)." & Chr(10)
    s &= ";" & Chr(10)
    s &= "; Monta com o asmsx para um binario MSX-BASIC (.bin), carregavel com:" & Chr(10)
    s &= ";   BLOAD " & Chr(34) & UCase(baseName) & ".BIN" & Chr(34) & ",R" & Chr(10)
    s &= "; ------------------------------------------------------------------" & Chr(10)
    s &= Chr(10)
    s &= "    .BIOS                       ; nomes oficiais das rotinas da BIOS" & Chr(10)
    s &= "    .BIOSVARS                   ; nomes oficiais das variaveis de sistema" & Chr(10)
    s &= "    .BASIC                      ; gera cabecalho de binario MSX-BASIC (.bin)" & Chr(10)
    s &= "    .ORG 0xC000                 ; endereco de montagem/execucao" & Chr(10)
    s &= Chr(10)
    s &= "MAIN:" & Chr(10)
    s &= "    ld a,40                     ; SCREEN 0 : WIDTH 40" & Chr(10)
    s &= "    ld [LINL40],a" & Chr(10)
    s &= "    call INITXT" & Chr(10)
    s &= Chr(10)
    s &= "    ld a,15                     ; COLOR 15,1,1" & Chr(10)
    s &= "    ld [FORCLR],a" & Chr(10)
    s &= "    ld a,1" & Chr(10)
    s &= "    ld [BAKCLR],a" & Chr(10)
    s &= "    ld a,1" & Chr(10)
    s &= "    ld [BDRCLR],a" & Chr(10)
    s &= "    call CHGCLR" & Chr(10)
    s &= Chr(10)
    s &= "    call ERAFNK                 ; KEY OFF" & Chr(10)
    s &= Chr(10)
    s &= "    call CLS                    ; CLS" & Chr(10)
    s &= Chr(10)
    s &= "    ld hl,MSG                   ; PRINT " & Chr(34) & "Hello ASM World" & Chr(34) & Chr(10)
    s &= "    call PUTSTR" & Chr(10)
    s &= Chr(10)
    s &= "    ret                         ; encerra e volta ao MSX-BASIC" & Chr(10)
    s &= Chr(10)
    s &= "; ------------------------------------------------------------------" & Chr(10)
    s &= "; Imprime uma string terminada em 24h (" & Chr(34) & "$" & Chr(34) & "), padrao classico da BIOS" & Chr(10)
    s &= "; ------------------------------------------------------------------" & Chr(10)
    s &= "PUTSTR:" & Chr(10)
    s &= "    ld a,[hl]" & Chr(10)
    s &= "    cp 24h" & Chr(10)
    s &= "    ret z" & Chr(10)
    s &= "    call CHPUT" & Chr(10)
    s &= "    inc hl" & Chr(10)
    s &= "    jr PUTSTR" & Chr(10)
    s &= Chr(10)
    s &= "MSG:" & Chr(10)
    s &= "    db " & Chr(34) & "Hello ASM World" & Chr(34) & ",13,10," & Chr(34) & "$" & Chr(34) & Chr(10)

    Return s
End Function

Private Sub EditorCreateAsmUntitled()
    Dim baseName As String = "asmsx" & Right("00" & Trim(Str(untitledAsmCounter)), 2)
    Dim docName As String = baseName & ".asm"
    untitledAsmCounter += 1

    EditorOpenFromPath(docName)

    If activeDoc >= 1 And activeDoc <= docCount Then
        Dim ByRef d As Document = docs(activeDoc)
        d.lineCount = 0
        AppendDocTextLines(d, BuildAsmHelloWorldTemplate(baseName))
        d.cursorX = 1
        d.cursorY = 1
        d.scrollX = 0
        d.scrollY = 0
    End If
End Sub

Private Sub AppendMamuteLine(ByRef d As Document, ByRef textLine As String)
    If d.lineCount < MAX_LINES Then
        d.lineCount += 1
        d.lines(d.lineCount) = textLine
    Else
        Dim i As Integer
        For i = 1 To MAX_LINES - 1
            d.lines(i) = d.lines(i + 1)
        Next i
        d.lines(MAX_LINES) = textLine
    End If
    d.scrollY = GetMaxScrollY(d)
End Sub

Private Function MamutePageRowText(ByVal slot As Integer, ByVal subIdx As Integer) As String
    Dim label As String = "Slot " & Trim(Str(slot))
    If MamuteMemSubOn(slot) <> 0 Then label &= "." & Trim(Str(subIdx))
    Dim txt As String = Left(label & Space(10), 10)
    Dim c As Integer
    For c = 0 To 3
        txt &= Left(MamuteCellTypeLabel(MamuteMemGrid(slot, subIdx, c).cellType) & Space(8), 8)
    Next c
    Return txt
End Function

' ===========================================================================
' Motor de assembly Z80 (clone de paleobasic/src/editor/assemblers/Z80Asm.pbi,
' escopo "Fase A" - absoluto, sem macros/condicionais/relocavel, ja que a
' gramatica do EDIT do Mamute nunca produz ASEG/CSEG/PUBLIC/EXTRN/MACRO/IF).
' Todo simbolo publico prefixado Z80_ (namespace por convencao, FreeBASIC nao
' tem Module de verdade dentro de um unico arquivo).
' ===========================================================================

Const Z80_MAX_SYMBOLS = 4000
Const Z80_MAX_SYMBOL_REFS = 8000
Const Z80_MAX_LISTING_ROWS = 12000
Const Z80_MAX_TOKENS = 96
Const Z80_MAX_DATA_BYTES = 65536

Const Z80OP_PLUS = 0
Const Z80OP_MINUS = 1
Const Z80OP_MUL = 2
Const Z80OP_DIV = 3
Const Z80OP_MOD = 4
Const Z80OP_SHL = 5
Const Z80OP_SHR = 6
Const Z80OP_AND = 7
Const Z80OP_OR = 8
Const Z80OP_XOR = 9
Const Z80OP_NOT = 10
Const Z80OP_EQ = 11
Const Z80OP_NE = 12
Const Z80OP_LT = 13
Const Z80OP_LE = 14
Const Z80OP_GT = 15
Const Z80OP_GE = 16
Const Z80OP_HIGH = 17
Const Z80OP_LOW = 18
Const Z80OP_UNARYMINUS = 19
Const Z80OP_UNARYPLUS = 20

Const Z80TK_NUMBER = 0
Const Z80TK_SYMBOL = 1
Const Z80TK_CURLOC = 2
Const Z80TK_OPERATOR = 3
Const Z80TK_LPAREN = 4
Const Z80TK_RPAREN = 5

Const Z80OPND_NONE = 0
Const Z80OPND_REG8 = 1
Const Z80OPND_REG16 = 2
Const Z80OPND_REGAF = 3
Const Z80OPND_IX = 4
Const Z80OPND_IY = 5
Const Z80OPND_IXHALF = 6
Const Z80OPND_IYHALF = 7
Const Z80OPND_INDHL = 8
Const Z80OPND_INDBC = 9
Const Z80OPND_INDDE = 10
Const Z80OPND_INDSP = 11
Const Z80OPND_INDC = 12
Const Z80OPND_INDIX = 13
Const Z80OPND_INDIY = 14
Const Z80OPND_COND = 15
Const Z80OPND_IMM = 16
Const Z80OPND_INDIMM = 17

Type Z80ExprTok
    tokKind As Integer
    numValue As Integer
    symName As String
    opCode As Integer
End Type

Type Z80Symbol
    symName As String
    symValue As Integer
    isKnown As Integer
    isConstant As Integer
End Type

Type Z80SymbolRef
    symName As String
    refAddr As Integer
End Type

Type Z80ListingRow
    sourceLine As Integer
    hasAddr As Integer
    isEqu As Integer
    rowAddr As Integer
    byteCount As Integer
    byte0 As Integer
    byte1 As Integer
    byte2 As Integer
    byte3 As Integer
End Type

Type Z80XrefRow
    symName As String
    hasValue As Integer
    rowValue As Integer
    addrCount As Integer
    addr0 As Integer
    addr1 As Integer
    addr2 As Integer
    addr3 As Integer
End Type

Type Z80Operand
    opndKind As Integer
    regCode As Integer
    opndExpr As String
    present As Integer
End Type

Type Z80ParsedLine
    hasLabel As Integer
    lbl As String
    labelHasColon As Integer
    hasOperator As Integer
    oper As String
    argsText As String
    isBlank As Integer
End Type


Dim Shared Z80Symbols(1 To Z80_MAX_SYMBOLS) As Z80Symbol
Dim Shared Z80SymbolCount As Integer
Dim Shared Z80SymbolRefs(1 To Z80_MAX_SYMBOL_REFS) As Z80SymbolRef
Dim Shared Z80SymbolRefCount As Integer
Dim Shared Z80SymbolDefOrder(1 To Z80_MAX_SYMBOLS) As String
Dim Shared Z80SymbolDefOrderCount As Integer
Dim Shared Z80ListingRows(1 To Z80_MAX_LISTING_ROWS) As Z80ListingRow
Dim Shared Z80ListingRowCount As Integer
Dim Shared Z80XrefRows(1 To Z80_MAX_SYMBOLS) As Z80XrefRow
Dim Shared Z80XrefRowCount As Integer

Dim Shared Z80CurLoc As Integer
Dim Shared Z80RealPos As Integer
Dim Shared Z80PassNumber As Integer
Dim Shared Z80LastEvalError As String
Dim Shared Z80LastEvalUnknownSymbol As String
Dim Shared Z80LastAsmError As String
Dim Shared Z80AsmErrorLine As Integer
Dim Shared Z80AsmErrorText As String
' Buffer de 64KB reaproveitado por Z80_Assemble() - Shared/estatico em vez de
' local, senao 3 buffers de 64KB (aqui + o outBytes() de quem chama +
' Z80_EncodeDataDirective) empilhados na mesma pilha de chamadas estoura a
' pilha padrao de 1MB (achado real testando este motor isolado).
Dim Shared Z80AssembleMem(0 To 65535) As Integer
Dim Shared Z80RunOneDataBytes(1 To Z80_MAX_DATA_BYTES) As Integer

Dim Shared Z80MinAddrTouched As Integer
Dim Shared Z80MaxAddrTouched As Integer
Dim Shared Z80AnyByteWritten As Integer

' ---------------------------------------------------------------------------
' Vocabulario
' ---------------------------------------------------------------------------

Const Z80_MNEMONICS = "|ADC|ADD|AND|BIT|CALL|CCF|CP|CPD|CPDR|CPI|CPIR|CPL|DAA|DEC|DI|DJNZ|EI|" & _
    "EXX|EX|HALT|IM|IN|INC|IND|INDR|INI|INIR|JP|JR|LD|LDD|LDDR|LDI|LDIR|NEG|NOP|" & _
    "OR|OTDR|OTIR|OUT|OUTD|OUTI|POP|PUSH|RES|RET|RETI|RETN|RL|RLA|RLC|RLCA|" & _
    "RLD|RR|RRA|RRC|RRCA|RRD|RST|SBC|SCF|SET|SLA|SLL|SRA|SRL|SUB|XOR|"

Const Z80_PSEUDOOPS = "|ORG|DEFB|DEFW|DEFM|DEFS|EQU|END|"

Private Function Z80_InPipeList(ByRef tokenUpper As String, ByRef pipeList As String) As Integer
    If Len(tokenUpper) = 0 Then Return 0
    If InStr(pipeList, "|" & tokenUpper & "|") > 0 Then Return -1
    Return 0
End Function

Function Z80_IsMnemonic(ByRef word As String) As Integer
    Return Z80_InPipeList(UCase(word), Z80_MNEMONICS)
End Function

Function Z80_IsAsmPseudoOp(ByRef word As String) As Integer
    Return Z80_InPipeList(UCase(word), Z80_PSEUDOOPS)
End Function

' ---------------------------------------------------------------------------
' Classificacao de caracteres
' ---------------------------------------------------------------------------

Private Function Z80ChIsDigit(ByRef c As String) As Integer
    Return (c >= "0" And c <= "9")
End Function

Private Function Z80ChIsHexDigit(ByRef c As String) As Integer
    Dim u As String = UCase(c)
    Return (Z80ChIsDigit(c) Or (u >= "A" And u <= "F"))
End Function

Private Function Z80ChIsAlpha(ByRef c As String) As Integer
    Dim u As String = UCase(c)
    Return (u >= "A" And u <= "Z")
End Function

Private Function Z80ChIsIdentExtra(ByRef c As String) As Integer
    Return (c = "$" Or c = "." Or c = "?" Or c = "@" Or c = "_")
End Function

Private Function Z80ChIsIdentStart(ByRef c As String) As Integer
    Return (Z80ChIsAlpha(c) Or Z80ChIsIdentExtra(c))
End Function

Private Function Z80ChIsIdentCont(ByRef c As String) As Integer
    Return (Z80ChIsAlpha(c) Or Z80ChIsDigit(c) Or Z80ChIsIdentExtra(c))
End Function

' ---------------------------------------------------------------------------
' Parser de linha
' ---------------------------------------------------------------------------

Private Function Z80FindCommentStart(ByRef lineText As String) As Integer
    Dim lineLen As Integer = Len(lineText)
    Dim idx As Integer = 1
    Dim c As String
    Dim delimCh As String
    While idx <= lineLen
        c = Mid(lineText, idx, 1)
        If c = ";" Then Return idx
        If c = Chr(34) Or c = "'" Then
            delimCh = c
            idx += 1
            While idx <= lineLen
                c = Mid(lineText, idx, 1)
                If c = delimCh Then
                    If idx < lineLen And Mid(lineText, idx + 1, 1) = delimCh Then
                        idx += 2
                        Continue While
                    End If
                    idx += 1
                    Exit While
                End If
                idx += 1
            Wend
            Continue While
        End If
        idx += 1
    Wend
    Return 0
End Function

Private Function Z80SkipWs(ByRef s As String, ByVal startPos As Integer) As Integer
    Dim l As Integer = Len(s)
    Dim idx As Integer = startPos
    While idx <= l And (Mid(s, idx, 1) = " " Or Mid(s, idx, 1) = Chr(9))
        idx += 1
    Wend
    Return idx
End Function

Private Function Z80RTrimWs(ByRef s As String) As String
    Dim l As Integer = Len(s)
    While l > 0 And (Mid(s, l, 1) = " " Or Mid(s, l, 1) = Chr(9))
        l -= 1
    Wend
    Return Left(s, l)
End Function

Function Z80_ParseLine(ByRef rawLine As String, ByRef outLine As Z80ParsedLine) As Integer
    Dim commentPos As Integer = Z80FindCommentStart(rawLine)
    Dim codeText As String

    outLine.hasLabel = 0 : outLine.lbl = ""
    outLine.labelHasColon = 0
    outLine.hasOperator = 0 : outLine.oper = ""
    outLine.argsText = ""
    outLine.isBlank = 0

    If commentPos > 0 Then
        codeText = Left(rawLine, commentPos - 1)
    Else
        codeText = rawLine
    End If

    Dim codeLen As Integer = Len(codeText)
    Dim idx As Integer = Z80SkipWs(codeText, 1)

    If idx > codeLen Then
        outLine.isBlank = -1
        Return -1
    End If

    If Z80ChIsIdentStart(Mid(codeText, idx, 1)) = 0 Then
        outLine.argsText = Z80RTrimWs(Mid(codeText, idx))
        Return -1
    End If

    Dim wStart As Integer = idx
    idx += 1
    While idx <= codeLen And Z80ChIsIdentCont(Mid(codeText, idx, 1))
        idx += 1
    Wend
    Dim wStop As Integer = idx - 1
    Dim word1 As String = UCase(Mid(codeText, wStart, wStop - wStart + 1))
    Dim afterWord1 As Integer = idx

    If idx <= codeLen And Mid(codeText, idx, 1) = ":" Then
        outLine.hasLabel = -1
        outLine.lbl = word1
        outLine.labelHasColon = -1
        idx += 1
        If idx <= codeLen And Mid(codeText, idx, 1) = ":" Then idx += 1

        idx = Z80SkipWs(codeText, idx)
        If idx > codeLen Then Return -1
        If Z80ChIsIdentStart(Mid(codeText, idx, 1)) = 0 Then
            outLine.argsText = Z80RTrimWs(Mid(codeText, idx))
            Return -1
        End If

        wStart = idx
        idx += 1
        While idx <= codeLen And Z80ChIsIdentCont(Mid(codeText, idx, 1))
            idx += 1
        Wend
        wStop = idx - 1
        outLine.hasOperator = -1
        outLine.oper = UCase(Mid(codeText, wStart, wStop - wStart + 1))

        idx = Z80SkipWs(codeText, idx)
        If idx <= codeLen Then outLine.argsText = Z80RTrimWs(Mid(codeText, idx))
        Return -1
    End If

    Dim p2 As Integer = Z80SkipWs(codeText, afterWord1)
    If p2 <= codeLen And Z80ChIsIdentStart(Mid(codeText, p2, 1)) Then
        Dim w2Start As Integer = p2
        p2 += 1
        While p2 <= codeLen And Z80ChIsIdentCont(Mid(codeText, p2, 1))
            p2 += 1
        Wend
        Dim w2End As Integer = p2 - 1
        Dim word2 As String = UCase(Mid(codeText, w2Start, w2End - w2Start + 1))

        If word2 = "EQU" Or word2 = "DEFL" Or word2 = "ASET" Then
            outLine.hasLabel = -1
            outLine.lbl = word1
            outLine.labelHasColon = 0
            outLine.hasOperator = -1
            outLine.oper = word2

            p2 = Z80SkipWs(codeText, p2)
            If p2 <= codeLen Then outLine.argsText = Z80RTrimWs(Mid(codeText, p2))
            Return -1
        End If
    End If

    outLine.hasOperator = -1
    outLine.oper = word1
    idx = Z80SkipWs(codeText, afterWord1)
    If idx <= codeLen Then outLine.argsText = Z80RTrimWs(Mid(codeText, idx))

    Return -1
End Function

' ---------------------------------------------------------------------------
' Precedencia / operadores por extenso
' ---------------------------------------------------------------------------

Private Function Z80OpPrecedence(ByVal op As Integer) As Integer
    Select Case op
        Case Z80OP_HIGH, Z80OP_LOW : Return 1
        Case Z80OP_MUL, Z80OP_DIV, Z80OP_MOD, Z80OP_SHL, Z80OP_SHR : Return 2
        Case Z80OP_UNARYMINUS, Z80OP_UNARYPLUS : Return 3
        Case Z80OP_PLUS, Z80OP_MINUS : Return 4
        Case Z80OP_EQ, Z80OP_NE, Z80OP_LT, Z80OP_LE, Z80OP_GT, Z80OP_GE : Return 5
        Case Z80OP_NOT : Return 6
        Case Z80OP_AND : Return 7
        Case Z80OP_OR, Z80OP_XOR : Return 8
    End Select
    Return 99
End Function

Private Function Z80OpIsUnary(ByVal op As Integer) As Integer
    Return (op = Z80OP_NOT Or op = Z80OP_HIGH Or op = Z80OP_LOW Or op = Z80OP_UNARYMINUS Or op = Z80OP_UNARYPLUS)
End Function

Private Function Z80WordToOpCode(ByRef word As String) As Integer
    Select Case UCase(word)
        Case "AND" : Return Z80OP_AND
        Case "OR" : Return Z80OP_OR
        Case "XOR" : Return Z80OP_XOR
        Case "NOT" : Return Z80OP_NOT
        Case "MOD" : Return Z80OP_MOD
        Case "SHR" : Return Z80OP_SHR
        Case "SHL" : Return Z80OP_SHL
        Case "HIGH" : Return Z80OP_HIGH
        Case "LOW" : Return Z80OP_LOW
        Case "EQ" : Return Z80OP_EQ
        Case "NE", "NEQ" : Return Z80OP_NE
        Case "LT" : Return Z80OP_LT
        Case "LE", "LTE" : Return Z80OP_LE
        Case "GT" : Return Z80OP_GT
        Case "GE", "GTE" : Return Z80OP_GE
    End Select
    Return -1
End Function

' ---------------------------------------------------------------------------
' Tokenizador de expressao
' ---------------------------------------------------------------------------

Private Function Z80CountAllHex(ByRef s As String) As Integer
    Dim idx As Integer
    For idx = 1 To Len(s)
        If Z80ChIsHexDigit(Mid(s, idx, 1)) = 0 Then Return 0
    Next idx
    Return -1
End Function

Private Function Z80CountAllOctal(ByRef s As String) As Integer
    Dim idx As Integer
    Dim c As String
    For idx = 1 To Len(s)
        c = Mid(s, idx, 1)
        If c < "0" Or c > "7" Then Return 0
    Next idx
    Return -1
End Function

Private Function Z80CountAllDecimal(ByRef s As String) As Integer
    Dim idx As Integer
    For idx = 1 To Len(s)
        If Z80ChIsDigit(Mid(s, idx, 1)) = 0 Then Return 0
    Next idx
    Return -1
End Function

Private Function Z80CountAllBinary(ByRef s As String) As Integer
    Dim idx As Integer
    Dim c As String
    For idx = 1 To Len(s)
        c = Mid(s, idx, 1)
        If c <> "0" And c <> "1" Then Return 0
    Next idx
    Return -1
End Function

Private Function Z80HexFromOctalDigits(ByRef s As String) As String
    Dim idx As Integer
    Dim v As LongInt = 0
    For idx = 1 To Len(s)
        v = (v * 8) + (Asc(Mid(s, idx, 1)) - Asc("0"))
    Next idx
    Return Hex(v)
End Function

Function Z80_TokenizeExpr(ByRef text As String, toks() As Z80ExprTok, ByRef tokCount As Integer) As Integer
    Dim textLen As Integer = Len(text)
    Dim idx As Integer = 1
    Dim c As String
    Dim lastWasOperand As Integer = 0

    tokCount = 0
    Z80LastEvalError = ""

    While idx <= textLen
        c = Mid(text, idx, 1)

        If c = " " Or c = Chr(9) Then
            idx += 1
            Continue While
        End If

        If tokCount >= Z80_MAX_TOKENS Then
            Z80LastEvalError = "Expressao com termos demais"
            Return 0
        End If

        If c = "(" Then
            tokCount += 1 : toks(tokCount).tokKind = Z80TK_LPAREN
            idx += 1 : lastWasOperand = 0
            Continue While
        End If

        If c = ")" Then
            tokCount += 1 : toks(tokCount).tokKind = Z80TK_RPAREN
            idx += 1 : lastWasOperand = -1
            Continue While
        End If

        If c = "$" And (idx = textLen Or Z80ChIsIdentCont(Mid(text, idx + 1, 1)) = 0) Then
            tokCount += 1 : toks(tokCount).tokKind = Z80TK_CURLOC
            idx += 1 : lastWasOperand = -1
            Continue While
        End If

        If c = "#" And idx < textLen And Z80ChIsHexDigit(Mid(text, idx + 1, 1)) Then
            Dim hStart As Integer = idx + 1
            idx += 1
            While idx <= textLen And Z80ChIsHexDigit(Mid(text, idx, 1))
                idx += 1
            Wend
            tokCount += 1 : toks(tokCount).tokKind = Z80TK_NUMBER
            toks(tokCount).numValue = ValInt("&H" & Mid(text, hStart, idx - hStart))
            lastWasOperand = -1
            Continue While
        End If

        If c = "%" And idx < textLen And (Mid(text, idx + 1, 1) = "0" Or Mid(text, idx + 1, 1) = "1") Then
            Dim bStart As Integer = idx + 1
            idx += 1
            While idx <= textLen And (Mid(text, idx, 1) = "0" Or Mid(text, idx, 1) = "1")
                idx += 1
            Wend
            tokCount += 1 : toks(tokCount).tokKind = Z80TK_NUMBER
            toks(tokCount).numValue = ValInt("&B" & Mid(text, bStart, idx - bStart))
            lastWasOperand = -1
            Continue While
        End If

        If c = Chr(34) Or c = "'" Then
            Dim delimCh As String = c
            Dim bodyText As String = ""
            Dim c2 As String
            idx += 1
            While idx <= textLen
                c2 = Mid(text, idx, 1)
                If c2 = delimCh Then
                    If idx < textLen And Mid(text, idx + 1, 1) = delimCh Then
                        bodyText &= delimCh : idx += 2 : Continue While
                    End If
                    idx += 1
                    Exit While
                End If
                If c2 = Chr(13) Or c2 = Chr(10) Then Exit While
                bodyText &= c2 : idx += 1
            Wend
            Select Case Len(bodyText)
                Case 0
                    tokCount += 1 : toks(tokCount).tokKind = Z80TK_NUMBER : toks(tokCount).numValue = 0
                Case 1
                    tokCount += 1 : toks(tokCount).tokKind = Z80TK_NUMBER : toks(tokCount).numValue = Asc(bodyText)
                Case 2
                    tokCount += 1 : toks(tokCount).tokKind = Z80TK_NUMBER
                    toks(tokCount).numValue = ((Asc(Left(bodyText, 1)) And 255) Shl 8) Or (Asc(Mid(bodyText, 2, 1)) And 255)
                Case Else
                    Z80LastEvalError = "String com mais de 2 caracteres nao pode ser usada como valor numerico: " & bodyText
                    Return 0
            End Select
            lastWasOperand = -1
            Continue While
        End If

        If Z80ChIsDigit(c) Then
            Dim numStart As Integer = idx
            If c = "0" And idx < textLen And (UCase(Mid(text, idx + 1, 1)) = "X" Or UCase(Mid(text, idx + 1, 1)) = "B") Then
                Dim prefixIsHex As Integer = (UCase(Mid(text, idx + 1, 1)) = "X")
                Dim pStart As Integer = idx + 2
                idx += 2
                If prefixIsHex Then
                    While idx <= textLen And Z80ChIsHexDigit(Mid(text, idx, 1))
                        idx += 1
                    Wend
                Else
                    While idx <= textLen And (Mid(text, idx, 1) = "0" Or Mid(text, idx, 1) = "1")
                        idx += 1
                    Wend
                End If
                If idx > pStart Then
                    tokCount += 1 : toks(tokCount).tokKind = Z80TK_NUMBER
                    If prefixIsHex Then
                        toks(tokCount).numValue = ValInt("&H" & Mid(text, pStart, idx - pStart))
                    Else
                        toks(tokCount).numValue = ValInt("&B" & Mid(text, pStart, idx - pStart))
                    End If
                    lastWasOperand = -1
                    Continue While
                Else
                    idx = numStart
                End If
            End If

            While idx <= textLen And (Z80ChIsDigit(Mid(text, idx, 1)) Or Z80ChIsAlpha(Mid(text, idx, 1)))
                idx += 1
            Wend
            Dim rawTok As String = UCase(Mid(text, numStart, idx - numStart))
            Dim lastDigitCh As String = Right(rawTok, 1)
            Dim digitsPart As String
            Dim valueOut As Integer
            Dim okFlag As Integer = 0

            If lastDigitCh = "H" Then
                digitsPart = Left(rawTok, Len(rawTok) - 1)
                If digitsPart <> "" And Z80CountAllHex(digitsPart) <> 0 Then
                    valueOut = ValInt("&H" & digitsPart) : okFlag = -1
                End If
            ElseIf lastDigitCh = "O" Or lastDigitCh = "Q" Then
                digitsPart = Left(rawTok, Len(rawTok) - 1)
                If digitsPart <> "" And Z80CountAllOctal(digitsPart) <> 0 Then
                    valueOut = ValInt("&H" & Z80HexFromOctalDigits(digitsPart)) : okFlag = -1
                End If
            ElseIf lastDigitCh = "D" Or lastDigitCh = "M" Then
                digitsPart = Left(rawTok, Len(rawTok) - 1)
                If digitsPart <> "" And Z80CountAllDecimal(digitsPart) <> 0 Then
                    valueOut = ValInt(digitsPart) : okFlag = -1
                End If
            ElseIf lastDigitCh = "B" Or lastDigitCh = "I" Then
                digitsPart = Left(rawTok, Len(rawTok) - 1)
                If digitsPart <> "" And Z80CountAllBinary(digitsPart) <> 0 Then
                    valueOut = ValInt("&B" & digitsPart) : okFlag = -1
                End If
            End If

            If okFlag = 0 Then
                If Z80CountAllDecimal(rawTok) <> 0 Then
                    valueOut = ValInt(rawTok) : okFlag = -1
                End If
            End If

            If okFlag = 0 Then
                Z80LastEvalError = "Numero invalido: " & rawTok
                Return 0
            End If

            tokCount += 1 : toks(tokCount).tokKind = Z80TK_NUMBER : toks(tokCount).numValue = valueOut
            lastWasOperand = -1
            Continue While
        End If

        If Z80ChIsIdentStart(c) Then
            Dim identStart As Integer = idx
            idx += 1
            While idx <= textLen And Z80ChIsIdentCont(Mid(text, idx, 1))
                idx += 1
            Wend
            Dim word As String = Mid(text, identStart, idx - identStart)

            Dim opCodeFound As Integer = Z80WordToOpCode(word)
            If opCodeFound >= 0 Then
                tokCount += 1 : toks(tokCount).tokKind = Z80TK_OPERATOR : toks(tokCount).opCode = opCodeFound
                lastWasOperand = 0
                Continue While
            End If

            If idx + 1 <= textLen And Mid(text, idx, 2) = "##" Then idx += 2

            tokCount += 1 : toks(tokCount).tokKind = Z80TK_SYMBOL : toks(tokCount).symName = UCase(word)
            lastWasOperand = -1
            Continue While
        End If

        Select Case c
            Case "+"
                tokCount += 1 : toks(tokCount).tokKind = Z80TK_OPERATOR
                If lastWasOperand <> 0 Then toks(tokCount).opCode = Z80OP_PLUS Else toks(tokCount).opCode = Z80OP_UNARYPLUS
                idx += 1 : lastWasOperand = 0
                Continue While
            Case "-"
                tokCount += 1 : toks(tokCount).tokKind = Z80TK_OPERATOR
                If lastWasOperand <> 0 Then toks(tokCount).opCode = Z80OP_MINUS Else toks(tokCount).opCode = Z80OP_UNARYMINUS
                idx += 1 : lastWasOperand = 0
                Continue While
            Case "*"
                tokCount += 1 : toks(tokCount).tokKind = Z80TK_OPERATOR : toks(tokCount).opCode = Z80OP_MUL
                idx += 1 : lastWasOperand = 0
                Continue While
            Case "/"
                tokCount += 1 : toks(tokCount).tokKind = Z80TK_OPERATOR : toks(tokCount).opCode = Z80OP_DIV
                idx += 1 : lastWasOperand = 0
                Continue While
        End Select

        Z80LastEvalError = "Caractere inesperado em expressao: '" & c & "'"
        Return 0
    Wend

    Return -1
End Function

' ---------------------------------------------------------------------------
' Shunting-yard: infixo -> posfixo
' ---------------------------------------------------------------------------

Function Z80_ToPostfixExpr(inToks() As Z80ExprTok, ByVal inCount As Integer, outToks() As Z80ExprTok, ByRef outCount As Integer) As Integer
    Dim opStack(1 To Z80_MAX_TOKENS) As Z80ExprTok
    Dim opStackCount As Integer = 0
    outCount = 0

    Dim i As Integer
    For i = 1 To inCount
        Select Case inToks(i).tokKind
            Case Z80TK_NUMBER, Z80TK_SYMBOL, Z80TK_CURLOC
                outCount += 1 : outToks(outCount) = inToks(i)

            Case Z80TK_LPAREN
                opStackCount += 1 : opStack(opStackCount) = inToks(i)

            Case Z80TK_RPAREN
                Dim foundOpen As Integer = 0
                While opStackCount > 0
                    If opStack(opStackCount).tokKind = Z80TK_LPAREN Then
                        foundOpen = -1
                        opStackCount -= 1
                        Exit While
                    End If
                    outCount += 1 : outToks(outCount) = opStack(opStackCount)
                    opStackCount -= 1
                Wend
                If foundOpen = 0 Then
                    Z80LastEvalError = "Parenteses desbalanceados: falta '('"
                    Return 0
                End If

            Case Z80TK_OPERATOR
                If Z80OpIsUnary(inToks(i).opCode) <> 0 Then
                    opStackCount += 1 : opStack(opStackCount) = inToks(i)
                Else
                    Dim newPrec As Integer = Z80OpPrecedence(inToks(i).opCode)
                    While opStackCount > 0
                        If opStack(opStackCount).tokKind = Z80TK_LPAREN Then Exit While
                        Dim stackPrec As Integer = Z80OpPrecedence(opStack(opStackCount).opCode)
                        If stackPrec > newPrec And Z80OpIsUnary(opStack(opStackCount).opCode) = 0 Then Exit While
                        outCount += 1 : outToks(outCount) = opStack(opStackCount)
                        opStackCount -= 1
                    Wend
                    opStackCount += 1 : opStack(opStackCount) = inToks(i)
                End If
        End Select
    Next i

    While opStackCount > 0
        If opStack(opStackCount).tokKind = Z80TK_LPAREN Then
            Z80LastEvalError = "Parenteses desbalanceados: sobrou '('"
            Return 0
        End If
        outCount += 1 : outToks(outCount) = opStack(opStackCount)
        opStackCount -= 1
    Wend

    Return -1
End Function

' ---------------------------------------------------------------------------
' Tabela de simbolos
' ---------------------------------------------------------------------------

Private Function Z80FindSymbol(ByRef symbolName As String) As Integer
    Dim key As String = UCase(symbolName)
    Dim i As Integer
    For i = 1 To Z80SymbolCount
        If Z80Symbols(i).symName = key Then Return i
    Next i
    Return 0
End Function

Private Function Z80FindOrAddSymbol(ByRef symbolName As String) As Integer
    Dim idx As Integer = Z80FindSymbol(symbolName)
    If idx > 0 Then Return idx
    If Z80SymbolCount >= Z80_MAX_SYMBOLS Then Return 0
    Z80SymbolCount += 1
    Z80Symbols(Z80SymbolCount).symName = UCase(symbolName)
    Z80Symbols(Z80SymbolCount).symValue = 0
    Z80Symbols(Z80SymbolCount).isKnown = 0
    Z80Symbols(Z80SymbolCount).isConstant = 0
    Return Z80SymbolCount
End Function

Sub Z80_ResetState()
    Z80SymbolCount = 0
    Z80CurLoc = 0
    Z80PassNumber = 1
    Z80LastEvalError = ""
    Z80LastEvalUnknownSymbol = ""
End Sub

Function Z80_DefineSymbol(ByRef symbolName As String, ByVal value As Integer, ByVal isConstant As Integer) As Integer
    Dim key As String = UCase(symbolName)
    Dim idx As Integer = Z80FindSymbol(key)

    If idx > 0 And Z80Symbols(idx).isKnown <> 0 And Z80Symbols(idx).isConstant <> 0 Then
        If Z80Symbols(idx).symValue = value Then Return -1
        Z80LastEvalError = "Simbolo ja definido (EQU nao pode ser redefinido): " & key
        Return 0
    End If

    Dim wasKnownBefore As Integer = (idx > 0 And Z80Symbols(idx).isKnown <> 0)
    If idx = 0 Then idx = Z80FindOrAddSymbol(key)
    If idx = 0 Then
        Z80LastEvalError = "Tabela de simbolos cheia"
        Return 0
    End If

    Z80Symbols(idx).symValue = value
    Z80Symbols(idx).isKnown = -1
    Z80Symbols(idx).isConstant = isConstant

    If wasKnownBefore = 0 Then
        If Z80SymbolDefOrderCount < Z80_MAX_SYMBOLS Then
            Z80SymbolDefOrderCount += 1
            Z80SymbolDefOrder(Z80SymbolDefOrderCount) = key
        End If
    End If

    Return -1
End Function

Function Z80_IsSymbolKnown(ByRef symbolName As String) As Integer
    Dim idx As Integer = Z80FindSymbol(symbolName)
    If idx > 0 Then Return Z80Symbols(idx).isKnown
    Return 0
End Function

Function Z80_GetSymbolValue(ByRef symbolName As String) As Integer
    Dim idx As Integer = Z80FindSymbol(symbolName)
    If idx > 0 Then Return Z80Symbols(idx).symValue
    Return 0
End Function

' ---------------------------------------------------------------------------
' Avaliacao da lista posfixa
' ---------------------------------------------------------------------------

Function Z80_EvalPostfixExpr(toks() As Z80ExprTok, ByVal tokCount As Integer, ByRef outValue As Integer) As Integer
    Dim stackVal(1 To Z80_MAX_TOKENS) As Integer
    Dim stackCount As Integer = 0
    Dim i As Integer

    For i = 1 To tokCount
        Select Case toks(i).tokKind
            Case Z80TK_NUMBER
                stackCount += 1 : stackVal(stackCount) = toks(i).numValue

            Case Z80TK_CURLOC
                stackCount += 1 : stackVal(stackCount) = Z80CurLoc

            Case Z80TK_SYMBOL
                Dim symIdx As Integer = Z80FindOrAddSymbol(toks(i).symName)
                If symIdx = 0 Or Z80Symbols(symIdx).isKnown = 0 Then
                    Z80LastEvalUnknownSymbol = toks(i).symName
                    Return 0
                End If
                If Z80PassNumber = 2 Then
                    If Z80SymbolRefCount < Z80_MAX_SYMBOL_REFS Then
                        Z80SymbolRefCount += 1
                        Z80SymbolRefs(Z80SymbolRefCount).symName = toks(i).symName
                        Z80SymbolRefs(Z80SymbolRefCount).refAddr = Z80CurLoc
                    End If
                End If
                stackCount += 1 : stackVal(stackCount) = Z80Symbols(symIdx).symValue

            Case Z80TK_OPERATOR
                If Z80OpIsUnary(toks(i).opCode) <> 0 Then
                    If stackCount < 1 Then
                        Z80LastEvalError = "Expressao mal formada (operador unario sem operando)"
                        Return 0
                    End If
                    Dim av As Integer = stackVal(stackCount)
                    Dim rv As Integer
                    Select Case toks(i).opCode
                        Case Z80OP_UNARYMINUS : rv = (-av) And &HFFFF
                        Case Z80OP_UNARYPLUS : rv = av
                        Case Z80OP_NOT : rv = (Not av) And &HFFFF
                        Case Z80OP_HIGH : rv = (av Shr 8) And &HFF
                        Case Z80OP_LOW : rv = av And &HFF
                    End Select
                    stackVal(stackCount) = rv
                Else
                    If stackCount < 2 Then
                        Z80LastEvalError = "Expressao mal formada (operador binario sem dois operandos)"
                        Return 0
                    End If
                    Dim bv As Integer = stackVal(stackCount) : stackCount -= 1
                    Dim av2 As Integer = stackVal(stackCount)
                    Dim rv2 As Integer
                    Select Case toks(i).opCode
                        Case Z80OP_PLUS : rv2 = (av2 + bv) And &HFFFF
                        Case Z80OP_MINUS : rv2 = (av2 - bv) And &HFFFF
                        Case Z80OP_MUL : rv2 = (av2 * bv) And &HFFFF
                        Case Z80OP_DIV
                            If bv = 0 Then Z80LastEvalError = "Divisao por zero" : Return 0
                            rv2 = (av2 \ bv) And &HFFFF
                        Case Z80OP_MOD
                            If bv = 0 Then Z80LastEvalError = "Divisao por zero (MOD)" : Return 0
                            rv2 = (av2 Mod bv) And &HFFFF
                        Case Z80OP_SHL : rv2 = (av2 Shl bv) And &HFFFF
                        Case Z80OP_SHR : rv2 = (av2 Shr bv) And &HFFFF
                        Case Z80OP_AND : rv2 = (av2 And bv) And &HFFFF
                        Case Z80OP_OR : rv2 = (av2 Or bv) And &HFFFF
                        Case Z80OP_XOR : rv2 = (av2 Xor bv) And &HFFFF
                        Case Z80OP_EQ : rv2 = IIf(av2 = bv, &HFFFF, 0)
                        Case Z80OP_NE : rv2 = IIf(av2 <> bv, &HFFFF, 0)
                        Case Z80OP_LT : rv2 = IIf(av2 < bv, &HFFFF, 0)
                        Case Z80OP_LE : rv2 = IIf(av2 <= bv, &HFFFF, 0)
                        Case Z80OP_GT : rv2 = IIf(av2 > bv, &HFFFF, 0)
                        Case Z80OP_GE : rv2 = IIf(av2 >= bv, &HFFFF, 0)
                    End Select
                    stackVal(stackCount) = rv2
                End If
        End Select
    Next i

    If stackCount <> 1 Then
        Z80LastEvalError = "Expressao mal formada (sobrou mais de um valor na pilha)"
        Return 0
    End If

    outValue = stackVal(stackCount)
    Return -1
End Function

Function Z80_EvalExpr(ByRef text As String, ByRef outValue As Integer) As Integer
    Dim infixToks(1 To Z80_MAX_TOKENS) As Z80ExprTok
    Dim infixCount As Integer
    Dim postfixToks(1 To Z80_MAX_TOKENS) As Z80ExprTok
    Dim postfixCount As Integer

    Z80LastEvalError = ""
    Z80LastEvalUnknownSymbol = ""

    If Z80_TokenizeExpr(text, infixToks(), infixCount) = 0 Then Return 0
    If infixCount = 0 Then
        Z80LastEvalError = "Expressao vazia"
        Return 0
    End If
    If Z80_ToPostfixExpr(infixToks(), infixCount, postfixToks(), postfixCount) = 0 Then Return 0
    Return Z80_EvalPostfixExpr(postfixToks(), postfixCount, outValue)
End Function

' ---------------------------------------------------------------------------
' Classificacao de operando
' ---------------------------------------------------------------------------

Sub Z80_ClassifyOperand(ByRef text As String, ByRef outOpnd As Z80Operand)
    Dim t As String = Z80RTrimWs(Mid(text, Z80SkipWs(text, 1)))
    Dim u As String = UCase(t)

    outOpnd.opndKind = Z80OPND_IMM
    outOpnd.regCode = 0
    outOpnd.opndExpr = t
    outOpnd.present = (t <> "")

    If t = "" Then
        outOpnd.opndKind = Z80OPND_NONE
        Exit Sub
    End If

    Select Case u
        Case "B" : outOpnd.opndKind = Z80OPND_REG8 : outOpnd.regCode = 0 : Exit Sub
        Case "C" : outOpnd.opndKind = Z80OPND_REG8 : outOpnd.regCode = 1 : Exit Sub
        Case "D" : outOpnd.opndKind = Z80OPND_REG8 : outOpnd.regCode = 2 : Exit Sub
        Case "E" : outOpnd.opndKind = Z80OPND_REG8 : outOpnd.regCode = 3 : Exit Sub
        Case "H" : outOpnd.opndKind = Z80OPND_REG8 : outOpnd.regCode = 4 : Exit Sub
        Case "L" : outOpnd.opndKind = Z80OPND_REG8 : outOpnd.regCode = 5 : Exit Sub
        Case "A" : outOpnd.opndKind = Z80OPND_REG8 : outOpnd.regCode = 7 : Exit Sub
        Case "BC" : outOpnd.opndKind = Z80OPND_REG16 : outOpnd.regCode = 0 : Exit Sub
        Case "DE" : outOpnd.opndKind = Z80OPND_REG16 : outOpnd.regCode = 1 : Exit Sub
        Case "HL" : outOpnd.opndKind = Z80OPND_REG16 : outOpnd.regCode = 2 : Exit Sub
        Case "SP" : outOpnd.opndKind = Z80OPND_REG16 : outOpnd.regCode = 3 : Exit Sub
        Case "AF" : outOpnd.opndKind = Z80OPND_REGAF : outOpnd.regCode = 3 : Exit Sub
        Case "IX" : outOpnd.opndKind = Z80OPND_IX : Exit Sub
        Case "IY" : outOpnd.opndKind = Z80OPND_IY : Exit Sub
        Case "IXH" : outOpnd.opndKind = Z80OPND_IXHALF : outOpnd.regCode = 4 : Exit Sub
        Case "IXL" : outOpnd.opndKind = Z80OPND_IXHALF : outOpnd.regCode = 5 : Exit Sub
        Case "IYH" : outOpnd.opndKind = Z80OPND_IYHALF : outOpnd.regCode = 4 : Exit Sub
        Case "IYL" : outOpnd.opndKind = Z80OPND_IYHALF : outOpnd.regCode = 5 : Exit Sub
        Case "(HL)" : outOpnd.opndKind = Z80OPND_INDHL : Exit Sub
        Case "(BC)" : outOpnd.opndKind = Z80OPND_INDBC : Exit Sub
        Case "(DE)" : outOpnd.opndKind = Z80OPND_INDDE : Exit Sub
        Case "(SP)" : outOpnd.opndKind = Z80OPND_INDSP : Exit Sub
        Case "(C)" : outOpnd.opndKind = Z80OPND_INDC : Exit Sub
        Case "(IX)" : outOpnd.opndKind = Z80OPND_INDIX : outOpnd.opndExpr = "" : Exit Sub
        Case "(IY)" : outOpnd.opndKind = Z80OPND_INDIY : outOpnd.opndExpr = "" : Exit Sub
        Case "NZ" : outOpnd.opndKind = Z80OPND_COND : outOpnd.regCode = 0 : Exit Sub
        Case "Z" : outOpnd.opndKind = Z80OPND_COND : outOpnd.regCode = 1 : Exit Sub
        Case "NC" : outOpnd.opndKind = Z80OPND_COND : outOpnd.regCode = 2 : Exit Sub
        Case "PO" : outOpnd.opndKind = Z80OPND_COND : outOpnd.regCode = 4 : Exit Sub
        Case "PE" : outOpnd.opndKind = Z80OPND_COND : outOpnd.regCode = 5 : Exit Sub
        Case "P" : outOpnd.opndKind = Z80OPND_COND : outOpnd.regCode = 6 : Exit Sub
        Case "M" : outOpnd.opndKind = Z80OPND_COND : outOpnd.regCode = 7 : Exit Sub
    End Select

    If Len(t) >= 2 And Left(t, 1) = "(" And Right(t, 1) = ")" Then
        Dim inner As String = Mid(t, 2, Len(t) - 2)
        Dim innerU As String = UCase(inner)
        If Left(innerU, 2) = "IX" And Len(inner) > 2 And (Mid(innerU, 3, 1) = "+" Or Mid(innerU, 3, 1) = "-") Then
            outOpnd.opndKind = Z80OPND_INDIX
            outOpnd.opndExpr = Mid(inner, 3)
            Exit Sub
        ElseIf Left(innerU, 2) = "IY" And Len(inner) > 2 And (Mid(innerU, 3, 1) = "+" Or Mid(innerU, 3, 1) = "-") Then
            outOpnd.opndKind = Z80OPND_INDIY
            outOpnd.opndExpr = Mid(inner, 3)
            Exit Sub
        End If
    End If

    If Left(t, 1) = "(" Then
        outOpnd.opndKind = Z80OPND_INDIMM
        outOpnd.opndExpr = t
        Exit Sub
    End If
End Sub

Function Z80_CountOperands(ByRef argsText As String) As Integer
    Dim l As Integer = Len(argsText)
    Dim idx As Integer = 1
    Dim c As String
    Dim depth As Integer = 0
    Dim n As Integer

    If Z80RTrimWs(Mid(argsText, Z80SkipWs(argsText, 1))) = "" Then Return 0
    n = 1
    While idx <= l
        c = Mid(argsText, idx, 1)
        If c = Chr(34) Or c = "'" Then
            Dim delimCh As String = c
            idx += 1
            While idx <= l And Mid(argsText, idx, 1) <> delimCh
                idx += 1
            Wend
        ElseIf c = "(" Then
            depth += 1
        ElseIf c = ")" Then
            depth -= 1
        ElseIf c = "," And depth = 0 Then
            n += 1
        End If
        idx += 1
    Wend
    Return n
End Function

Function Z80_GetOperand(ByRef argsText As String, ByVal index As Integer) As String
    Dim l As Integer = Len(argsText)
    Dim idx As Integer = 1
    Dim c As String
    Dim depth As Integer = 0
    Dim n As Integer = 1
    Dim startPos As Integer = 1

    While idx <= l
        c = Mid(argsText, idx, 1)
        If c = Chr(34) Or c = "'" Then
            Dim delimCh As String = c
            idx += 1
            While idx <= l And Mid(argsText, idx, 1) <> delimCh
                idx += 1
            Wend
        ElseIf c = "(" Then
            depth += 1
        ElseIf c = ")" Then
            depth -= 1
        ElseIf c = "," And depth = 0 Then
            If n = index Then Return Mid(argsText, startPos, idx - startPos)
            n += 1
            startPos = idx + 1
        End If
        idx += 1
    Wend
    If n = index Then Return Mid(argsText, startPos)
    Return ""
End Function

Function Z80_EvalOperandExpr(ByRef expr As String, ByVal emitMode As Integer, ByRef outValue As Integer) As Integer
    If emitMode = 0 Then
        outValue = 0
        Return -1
    End If
    If Z80_EvalExpr(expr, outValue) = 0 Then
        Z80LastAsmError = "Expressao invalida (" & expr & "): " & Z80LastEvalError & Z80LastEvalUnknownSymbol
        Return 0
    End If
    Return -1
End Function

Function Z80_EvalDisplacement(ByRef expr As String, ByVal emitMode As Integer, ByRef outValue As Integer) As Integer
    If expr = "" Then
        outValue = 0
        Return -1
    End If
    Return Z80_EvalOperandExpr(expr, emitMode, outValue)
End Function

' ---------------------------------------------------------------------------
' Familias de codificacao de instrucao - cada uma devolve o numero de bytes
' (0-4) ou -1 (erro, ver Z80LastAsmError).
' ---------------------------------------------------------------------------

Private Function Z80EncodeRst(ByRef op1 As Z80Operand, ByVal emitMode As Integer, outBytes() As Integer) As Integer
    Dim v As Integer
    If op1.present = 0 Then
        Z80LastAsmError = "RST precisa de um operando (0,8,16,24,32,40,48,56)"
        Return -1
    End If
    If Z80_EvalOperandExpr(op1.opndExpr, emitMode, v) = 0 Then Return -1
    outBytes(0) = &HC7
    If emitMode <> 0 Then
        If (v And 7) <> 0 Or v > 56 Then
            Z80LastAsmError = "RST: valor invalido (precisa ser 0,8,16,24,32,40,48 ou 56): " & Str(v)
            Return -1
        End If
        outBytes(0) = &HC7 Or ((v \ 8) Shl 3)
    End If
    Return 1
End Function

Private Function Z80EncodeIm(ByRef op1 As Z80Operand, ByVal emitMode As Integer, outBytes() As Integer) As Integer
    Dim v As Integer
    If op1.present = 0 Then
        Z80LastAsmError = "IM precisa de um operando (0, 1 ou 2)"
        Return -1
    End If
    If Z80_EvalOperandExpr(op1.opndExpr, emitMode, v) = 0 Then Return -1
    outBytes(0) = &HED
    If emitMode <> 0 Then
        Select Case v
            Case 0 : outBytes(1) = &H46
            Case 1 : outBytes(1) = &H56
            Case 2 : outBytes(1) = &H5E
            Case Else
                Z80LastAsmError = "IM: valor invalido (precisa ser 0, 1 ou 2)"
                Return -1
        End Select
    End If
    Return 2
End Function

Private Function Z80EncodeEx(ByRef op1 As Z80Operand, ByRef op2 As Z80Operand, ByVal emitMode As Integer, outBytes() As Integer) As Integer
    If op1.opndKind = Z80OPND_REG16 And op1.regCode = 1 And op2.opndKind = Z80OPND_REG16 And op2.regCode = 2 Then
        outBytes(0) = &HEB
        Return 1
    End If
    If op1.opndKind = Z80OPND_REGAF And UCase(op2.opndExpr) = "AF'" Then
        outBytes(0) = &H08
        Return 1
    End If
    If op1.opndKind = Z80OPND_INDSP Then
        If op2.opndKind = Z80OPND_REG16 And op2.regCode = 2 Then
            outBytes(0) = &HE3
            Return 1
        ElseIf op2.opndKind = Z80OPND_IX Then
            outBytes(0) = &HDD : outBytes(1) = &HE3
            Return 2
        ElseIf op2.opndKind = Z80OPND_IY Then
            outBytes(0) = &HFD : outBytes(1) = &HE3
            Return 2
        End If
    End If
    Z80LastAsmError = "EX: combinacao de operandos invalida"
    Return -1
End Function

Private Function Z80EncodeIn(ByRef op1 As Z80Operand, ByRef op2 As Z80Operand, ByVal nOps As Integer, ByVal emitMode As Integer, outBytes() As Integer) As Integer
    Dim v As Integer
    If nOps <> 2 Then
        Z80LastAsmError = "IN precisa de 2 operandos"
        Return -1
    End If
    If op1.opndKind = Z80OPND_REG8 And op1.regCode = 7 And op2.opndKind = Z80OPND_INDIMM Then
        If Z80_EvalOperandExpr(op2.opndExpr, emitMode, v) = 0 Then Return -1
        outBytes(0) = &HDB
        If emitMode <> 0 Then outBytes(1) = v And &HFF
        Return 2
    End If
    If op1.opndKind = Z80OPND_REG8 And op2.opndKind = Z80OPND_INDC Then
        outBytes(0) = &HED
        outBytes(1) = &H40 Or (op1.regCode Shl 3)
        Return 2
    End If
    Z80LastAsmError = "IN: combinacao de operandos invalida"
    Return -1
End Function

Private Function Z80EncodeOut(ByRef op1 As Z80Operand, ByRef op2 As Z80Operand, ByVal emitMode As Integer, outBytes() As Integer) As Integer
    Dim v As Integer
    If op1.opndKind = Z80OPND_INDIMM And op2.opndKind = Z80OPND_REG8 And op2.regCode = 7 Then
        If Z80_EvalOperandExpr(op1.opndExpr, emitMode, v) = 0 Then Return -1
        outBytes(0) = &HD3
        If emitMode <> 0 Then outBytes(1) = v And &HFF
        Return 2
    End If
    If op1.opndKind = Z80OPND_INDC And op2.opndKind = Z80OPND_REG8 Then
        outBytes(0) = &HED
        outBytes(1) = &H41 Or (op2.regCode Shl 3)
        Return 2
    End If
    Z80LastAsmError = "OUT: combinacao de operandos invalida"
    Return -1
End Function

Private Function Z80EncodePushPop(ByVal baseOp As Integer, ByRef op1 As Z80Operand, ByVal emitMode As Integer, outBytes() As Integer) As Integer
    Select Case op1.opndKind
        Case Z80OPND_REG16
            If op1.regCode = 3 Then
                Z80LastAsmError = "PUSH/POP: SP nao existe aqui (o slot 11 e AF, nao SP - quis dizer AF?)"
                Return -1
            End If
            outBytes(0) = baseOp Or (op1.regCode Shl 4)
            Return 1
        Case Z80OPND_REGAF
            outBytes(0) = baseOp Or (3 Shl 4)
            Return 1
        Case Z80OPND_IX
            outBytes(0) = &HDD : outBytes(1) = baseOp Or (2 Shl 4)
            Return 2
        Case Z80OPND_IY
            outBytes(0) = &HFD : outBytes(1) = baseOp Or (2 Shl 4)
            Return 2
    End Select
    Z80LastAsmError = "PUSH/POP: operando invalido (precisa ser BC, DE, HL, AF, IX ou IY)"
    Return -1
End Function

Private Function Z80EncodeIncDec(ByVal isInc As Integer, ByRef op1 As Z80Operand, ByVal emitMode As Integer, outBytes() As Integer) As Integer
    Dim v As Integer
    Dim op8 As Integer, op16 As Integer, opIxIy As Integer, opInd As Integer, opHalfH As Integer, opHalfL As Integer
    If isInc <> 0 Then
        op8 = &H04 : op16 = &H03 : opIxIy = &H23 : opInd = &H34 : opHalfH = &H24 : opHalfL = &H2C
    Else
        op8 = &H05 : op16 = &H0B : opIxIy = &H2B : opInd = &H35 : opHalfH = &H25 : opHalfL = &H2D
    End If

    Select Case op1.opndKind
        Case Z80OPND_REG8
            outBytes(0) = op8 Or (op1.regCode Shl 3)
            Return 1
        Case Z80OPND_INDHL
            outBytes(0) = op8 Or (6 Shl 3)
            Return 1
        Case Z80OPND_REG16
            outBytes(0) = op16 Or (op1.regCode Shl 4)
            Return 1
        Case Z80OPND_IX
            outBytes(0) = &HDD : outBytes(1) = opIxIy
            Return 2
        Case Z80OPND_IY
            outBytes(0) = &HFD : outBytes(1) = opIxIy
            Return 2
        Case Z80OPND_IXHALF
            outBytes(0) = &HDD
            If op1.regCode = 4 Then outBytes(1) = opHalfH Else outBytes(1) = opHalfL
            Return 2
        Case Z80OPND_IYHALF
            outBytes(0) = &HFD
            If op1.regCode = 4 Then outBytes(1) = opHalfH Else outBytes(1) = opHalfL
            Return 2
        Case Z80OPND_INDIX
            outBytes(0) = &HDD : outBytes(1) = opInd
            If Z80_EvalDisplacement(op1.opndExpr, emitMode, v) = 0 Then Return -1
            If emitMode <> 0 Then outBytes(2) = v And &HFF
            Return 3
        Case Z80OPND_INDIY
            outBytes(0) = &HFD : outBytes(1) = opInd
            If Z80_EvalDisplacement(op1.opndExpr, emitMode, v) = 0 Then Return -1
            If emitMode <> 0 Then outBytes(2) = v And &HFF
            Return 3
    End Select
    Z80LastAsmError = "INC/DEC: operando invalido"
    Return -1
End Function

Private Function Z80EncodeAluSingle(ByVal idxAlu As Integer, ByRef op1 As Z80Operand, ByRef op2 As Z80Operand, ByVal nOps As Integer, ByVal emitMode As Integer, outBytes() As Integer) As Integer
    Dim v As Integer
    Dim theOp As Z80Operand
    If nOps = 2 Then
        If op1.opndKind <> Z80OPND_REG8 Or op1.regCode <> 7 Then
            Z80LastAsmError = "So A pode ser o primeiro operando quando dois sao dados"
            Return -1
        End If
        theOp = op2
    ElseIf nOps = 1 Then
        theOp = op1
    Else
        Z80LastAsmError = "Precisa de 1 operando (ou 2, com A como o primeiro)"
        Return -1
    End If

    Select Case theOp.opndKind
        Case Z80OPND_REG8
            outBytes(0) = &H80 Or (idxAlu Shl 3) Or theOp.regCode
            Return 1
        Case Z80OPND_INDHL
            outBytes(0) = &H80 Or (idxAlu Shl 3) Or 6
            Return 1
        Case Z80OPND_IXHALF
            outBytes(0) = &HDD : outBytes(1) = &H80 Or (idxAlu Shl 3) Or theOp.regCode
            Return 2
        Case Z80OPND_IYHALF
            outBytes(0) = &HFD : outBytes(1) = &H80 Or (idxAlu Shl 3) Or theOp.regCode
            Return 2
        Case Z80OPND_INDIX
            outBytes(0) = &HDD : outBytes(1) = &H86 Or (idxAlu Shl 3)
            If Z80_EvalDisplacement(theOp.opndExpr, emitMode, v) = 0 Then Return -1
            If emitMode <> 0 Then outBytes(2) = v And &HFF
            Return 3
        Case Z80OPND_INDIY
            outBytes(0) = &HFD : outBytes(1) = &H86 Or (idxAlu Shl 3)
            If Z80_EvalDisplacement(theOp.opndExpr, emitMode, v) = 0 Then Return -1
            If emitMode <> 0 Then outBytes(2) = v And &HFF
            Return 3
        Case Z80OPND_INDIMM
            Z80LastAsmError = "So (HL), (IX+d) ou (IY+d) sao validos aqui, nao (nn)"
            Return -1
        Case Z80OPND_IMM
            If Z80_EvalOperandExpr(theOp.opndExpr, emitMode, v) = 0 Then Return -1
            outBytes(0) = &HC6 Or (idxAlu Shl 3)
            If emitMode <> 0 Then outBytes(1) = v And &HFF
            Return 2
    End Select
    Z80LastAsmError = "Operando invalido"
    Return -1
End Function

Private Function Z80EncodeAdd(ByRef op1 As Z80Operand, ByRef op2 As Z80Operand, ByVal nOps As Integer, ByVal emitMode As Integer, outBytes() As Integer) As Integer
    If nOps <> 2 Then
        Z80LastAsmError = "ADD precisa de 2 operandos"
        Return -1
    End If

    If op1.opndKind = Z80OPND_REG8 And op1.regCode = 7 Then
        Return Z80EncodeAluSingle(0, op1, op2, 2, emitMode, outBytes())
    End If

    If op1.opndKind = Z80OPND_REG16 And op1.regCode = 2 Then
        If op2.opndKind = Z80OPND_REG16 Then
            outBytes(0) = &H09 Or (op2.regCode Shl 4)
            Return 1
        End If
        Z80LastAsmError = "ADD HL,?: segundo operando precisa ser BC, DE, HL ou SP"
        Return -1
    End If

    If op1.opndKind = Z80OPND_IX Then
        outBytes(0) = &HDD
        If op2.opndKind = Z80OPND_REG16 And op2.regCode <> 2 Then
            outBytes(1) = &H09 Or (op2.regCode Shl 4)
            Return 2
        ElseIf op2.opndKind = Z80OPND_IX Then
            outBytes(1) = &H09 Or (2 Shl 4)
            Return 2
        End If
        Z80LastAsmError = "ADD IX,?: segundo operando precisa ser BC, DE, IX ou SP"
        Return -1
    End If

    If op1.opndKind = Z80OPND_IY Then
        outBytes(0) = &HFD
        If op2.opndKind = Z80OPND_REG16 And op2.regCode <> 2 Then
            outBytes(1) = &H09 Or (op2.regCode Shl 4)
            Return 2
        ElseIf op2.opndKind = Z80OPND_IY Then
            outBytes(1) = &H09 Or (2 Shl 4)
            Return 2
        End If
        Z80LastAsmError = "ADD IY,?: segundo operando precisa ser BC, DE, IY ou SP"
        Return -1
    End If

    Z80LastAsmError = "ADD: combinacao de operandos invalida"
    Return -1
End Function

Private Function Z80EncodeAdcSbc(ByVal isAdc As Integer, ByRef op1 As Z80Operand, ByRef op2 As Z80Operand, ByVal nOps As Integer, ByVal emitMode As Integer, outBytes() As Integer) As Integer
    If nOps <> 2 Then
        Z80LastAsmError = "ADC/SBC precisa de 2 operandos"
        Return -1
    End If

    If op1.opndKind = Z80OPND_REG8 And op1.regCode = 7 Then
        If isAdc <> 0 Then
            Return Z80EncodeAluSingle(1, op1, op2, 2, emitMode, outBytes())
        Else
            Return Z80EncodeAluSingle(3, op1, op2, 2, emitMode, outBytes())
        End If
    End If

    If op1.opndKind = Z80OPND_REG16 And op1.regCode = 2 And op2.opndKind = Z80OPND_REG16 Then
        outBytes(0) = &HED
        If isAdc <> 0 Then
            outBytes(1) = &H4A Or (op2.regCode Shl 4)
        Else
            outBytes(1) = &H42 Or (op2.regCode Shl 4)
        End If
        Return 2
    End If

    Z80LastAsmError = "ADC/SBC: combinacao de operandos invalida"
    Return -1
End Function

Private Function Z80CondCodeOf(ByRef op As Z80Operand) As Integer
    If op.opndKind = Z80OPND_COND Then Return op.regCode
    If op.opndKind = Z80OPND_REG8 And op.regCode = 1 Then Return 3
    Return -1
End Function

Private Function Z80EncodeJp(ByRef op1 As Z80Operand, ByRef op2 As Z80Operand, ByVal nOps As Integer, ByVal emitMode As Integer, outBytes() As Integer) As Integer
    Dim v As Integer
    If nOps = 1 Then
        Select Case op1.opndKind
            Case Z80OPND_INDHL
                outBytes(0) = &HE9
                Return 1
            Case Z80OPND_INDIX
                outBytes(0) = &HDD : outBytes(1) = &HE9
                Return 2
            Case Z80OPND_INDIY
                outBytes(0) = &HFD : outBytes(1) = &HE9
                Return 2
            Case Z80OPND_IMM
                If Z80_EvalOperandExpr(op1.opndExpr, emitMode, v) = 0 Then Return -1
                outBytes(0) = &HC3
                If emitMode <> 0 Then
                    outBytes(1) = v And &HFF
                    outBytes(2) = (v Shr 8) And &HFF
                End If
                Return 3
        End Select
        Z80LastAsmError = "JP: operando invalido"
        Return -1
    ElseIf nOps = 2 Then
        Dim ccJp As Integer = Z80CondCodeOf(op1)
        If ccJp < 0 Then
            Z80LastAsmError = "JP cc,nn: primeiro operando precisa ser uma condicao (NZ,Z,NC,C,PO,PE,P,M)"
            Return -1
        End If
        If Z80_EvalOperandExpr(op2.opndExpr, emitMode, v) = 0 Then Return -1
        outBytes(0) = &HC2 Or (ccJp Shl 3)
        If emitMode <> 0 Then
            outBytes(1) = v And &HFF
            outBytes(2) = (v Shr 8) And &HFF
        End If
        Return 3
    End If
    Z80LastAsmError = "JP: numero de operandos invalido"
    Return -1
End Function

Private Function Z80EncodeJr(ByRef op1 As Z80Operand, ByRef op2 As Z80Operand, ByVal nOps As Integer, ByVal emitMode As Integer, outBytes() As Integer) As Integer
    Dim v As Integer
    Dim targetExpr As String
    Dim baseOp As Integer

    If nOps = 1 Then
        baseOp = &H18
        targetExpr = op1.opndExpr
    ElseIf nOps = 2 Then
        Dim ccJr As Integer = Z80CondCodeOf(op1)
        If ccJr < 0 Or ccJr > 3 Then
            Z80LastAsmError = "JR cc,e: condicao precisa ser NZ, Z, NC ou C"
            Return -1
        End If
        Select Case ccJr
            Case 0 : baseOp = &H20
            Case 1 : baseOp = &H28
            Case 2 : baseOp = &H30
            Case 3 : baseOp = &H38
        End Select
        targetExpr = op2.opndExpr
    Else
        Z80LastAsmError = "JR: numero de operandos invalido"
        Return -1
    End If

    outBytes(0) = baseOp
    If emitMode = 0 Then Return 2

    If Z80_EvalExpr(targetExpr, v) = 0 Then
        Z80LastAsmError = "JR: " & Z80LastEvalError & Z80LastEvalUnknownSymbol
        Return -1
    End If
    Dim disp As Integer = v - (Z80CurLoc + 2)
    If disp < -128 Or disp > 127 Then
        Z80LastAsmError = "JR: alvo fora de alcance (-128..127), deslocamento = " & Str(disp)
        Return -1
    End If
    outBytes(1) = disp And &HFF
    Return 2
End Function

Private Function Z80EncodeDjnz(ByRef op1 As Z80Operand, ByVal emitMode As Integer, outBytes() As Integer) As Integer
    Dim v As Integer
    outBytes(0) = &H10
    If emitMode = 0 Then Return 2
    If Z80_EvalExpr(op1.opndExpr, v) = 0 Then
        Z80LastAsmError = "DJNZ: " & Z80LastEvalError & Z80LastEvalUnknownSymbol
        Return -1
    End If
    Dim disp As Integer = v - (Z80CurLoc + 2)
    If disp < -128 Or disp > 127 Then
        Z80LastAsmError = "DJNZ: alvo fora de alcance (-128..127), deslocamento = " & Str(disp)
        Return -1
    End If
    outBytes(1) = disp And &HFF
    Return 2
End Function

Private Function Z80EncodeCallRet(ByVal isCall As Integer, ByRef op1 As Z80Operand, ByRef op2 As Z80Operand, ByVal nOps As Integer, ByVal emitMode As Integer, outBytes() As Integer) As Integer
    Dim v As Integer
    If isCall <> 0 Then
        If nOps = 1 Then
            If Z80_EvalOperandExpr(op1.opndExpr, emitMode, v) = 0 Then Return -1
            outBytes(0) = &HCD
            If emitMode <> 0 Then
                outBytes(1) = v And &HFF
                outBytes(2) = (v Shr 8) And &HFF
            End If
            Return 3
        ElseIf nOps = 2 Then
            Dim ccCall As Integer = Z80CondCodeOf(op1)
            If ccCall < 0 Then
                Z80LastAsmError = "CALL cc,nn: primeiro operando precisa ser uma condicao"
                Return -1
            End If
            If Z80_EvalOperandExpr(op2.opndExpr, emitMode, v) = 0 Then Return -1
            outBytes(0) = &HC4 Or (ccCall Shl 3)
            If emitMode <> 0 Then
                outBytes(1) = v And &HFF
                outBytes(2) = (v Shr 8) And &HFF
            End If
            Return 3
        End If
        Z80LastAsmError = "CALL: numero de operandos invalido"
        Return -1
    Else
        If nOps = 0 Then
            outBytes(0) = &HC9
            Return 1
        ElseIf nOps = 1 Then
            Dim ccRet As Integer = Z80CondCodeOf(op1)
            If ccRet < 0 Then
                Z80LastAsmError = "RET cc: operando precisa ser uma condicao"
                Return -1
            End If
            outBytes(0) = &HC0 Or (ccRet Shl 3)
            Return 1
        End If
        Z80LastAsmError = "RET: numero de operandos invalido"
        Return -1
    End If
End Function

Private Function Z80EncodeCbShift(ByRef m As String, ByRef op1 As Z80Operand, ByVal emitMode As Integer, outBytes() As Integer) As Integer
    Dim idxCb As Integer
    Dim v As Integer
    Select Case m
        Case "RLC" : idxCb = 0
        Case "RRC" : idxCb = 1
        Case "RL" : idxCb = 2
        Case "RR" : idxCb = 3
        Case "SLA" : idxCb = 4
        Case "SRA" : idxCb = 5
        Case "SLL" : idxCb = 6
        Case "SRL" : idxCb = 7
    End Select

    Select Case op1.opndKind
        Case Z80OPND_REG8
            outBytes(0) = &HCB : outBytes(1) = (idxCb Shl 3) Or op1.regCode
            Return 2
        Case Z80OPND_INDHL
            outBytes(0) = &HCB : outBytes(1) = (idxCb Shl 3) Or 6
            Return 2
        Case Z80OPND_INDIX
            outBytes(0) = &HDD : outBytes(1) = &HCB
            If Z80_EvalDisplacement(op1.opndExpr, emitMode, v) = 0 Then Return -1
            If emitMode <> 0 Then outBytes(2) = v And &HFF
            outBytes(3) = (idxCb Shl 3) Or 6
            Return 4
        Case Z80OPND_INDIY
            outBytes(0) = &HFD : outBytes(1) = &HCB
            If Z80_EvalDisplacement(op1.opndExpr, emitMode, v) = 0 Then Return -1
            If emitMode <> 0 Then outBytes(2) = v And &HFF
            outBytes(3) = (idxCb Shl 3) Or 6
            Return 4
    End Select
    Z80LastAsmError = m & ": operando invalido"
    Return -1
End Function

Private Function Z80EncodeCbBit(ByRef m As String, ByRef op1 As Z80Operand, ByRef op2 As Z80Operand, ByVal emitMode As Integer, outBytes() As Integer) As Integer
    Dim baseOp As Integer
    Dim v As Integer
    Dim bv As Integer
    Dim bNum As Integer
    Select Case m
        Case "BIT" : baseOp = &H40
        Case "RES" : baseOp = &H80
        Case "SET" : baseOp = &HC0
    End Select

    If Z80_EvalOperandExpr(op1.opndExpr, emitMode, bv) = 0 Then Return -1
    If emitMode <> 0 Then
        If bv > 7 Then
            Z80LastAsmError = m & ": numero de bit precisa ser 0-7"
            Return -1
        End If
        bNum = bv
    End If

    Select Case op2.opndKind
        Case Z80OPND_REG8
            outBytes(0) = &HCB : outBytes(1) = baseOp Or (bNum Shl 3) Or op2.regCode
            Return 2
        Case Z80OPND_INDHL
            outBytes(0) = &HCB : outBytes(1) = baseOp Or (bNum Shl 3) Or 6
            Return 2
        Case Z80OPND_INDIX
            outBytes(0) = &HDD : outBytes(1) = &HCB
            If Z80_EvalDisplacement(op2.opndExpr, emitMode, v) = 0 Then Return -1
            If emitMode <> 0 Then outBytes(2) = v And &HFF
            outBytes(3) = baseOp Or (bNum Shl 3) Or 6
            Return 4
        Case Z80OPND_INDIY
            outBytes(0) = &HFD : outBytes(1) = &HCB
            If Z80_EvalDisplacement(op2.opndExpr, emitMode, v) = 0 Then Return -1
            If emitMode <> 0 Then outBytes(2) = v And &HFF
            outBytes(3) = baseOp Or (bNum Shl 3) Or 6
            Return 4
    End Select
    Z80LastAsmError = m & ": segundo operando invalido"
    Return -1
End Function

Private Function Z80EncodeLd(ByRef op1 As Z80Operand, ByRef op2 As Z80Operand, ByVal emitMode As Integer, outBytes() As Integer) As Integer
    Dim v As Integer

    If op1.present = 0 Or op2.present = 0 Then
        Z80LastAsmError = "LD precisa de 2 operandos"
        Return -1
    End If

    If op1.opndKind = Z80OPND_REG8 And op1.regCode = 7 And op2.opndKind = Z80OPND_IMM Then
        If UCase(op2.opndExpr) = "I" Then
            outBytes(0) = &HED : outBytes(1) = &H57 : Return 2
        ElseIf UCase(op2.opndExpr) = "R" Then
            outBytes(0) = &HED : outBytes(1) = &H5F : Return 2
        End If
    End If
    If op2.opndKind = Z80OPND_REG8 And op2.regCode = 7 And op1.opndKind = Z80OPND_IMM Then
        If UCase(op1.opndExpr) = "I" Then
            outBytes(0) = &HED : outBytes(1) = &H47 : Return 2
        ElseIf UCase(op1.opndExpr) = "R" Then
            outBytes(0) = &HED : outBytes(1) = &H4F : Return 2
        End If
    End If

    If (op1.opndKind = Z80OPND_REG8 Or op1.opndKind = Z80OPND_INDHL) And (op2.opndKind = Z80OPND_REG8 Or op2.opndKind = Z80OPND_INDHL) Then
        If op1.opndKind = Z80OPND_INDHL And op2.opndKind = Z80OPND_INDHL Then
            Z80LastAsmError = "LD (HL),(HL) nao existe (seria HALT)"
            Return -1
        End If
        Dim r1 As Integer, r2 As Integer
        If op1.opndKind = Z80OPND_INDHL Then r1 = 6 Else r1 = op1.regCode
        If op2.opndKind = Z80OPND_INDHL Then r2 = 6 Else r2 = op2.regCode
        outBytes(0) = &H40 Or (r1 Shl 3) Or r2
        Return 1
    End If

    If (op1.opndKind = Z80OPND_REG8 Or op1.opndKind = Z80OPND_INDHL) And op2.opndKind = Z80OPND_IMM Then
        Dim r1b As Integer
        If op1.opndKind = Z80OPND_INDHL Then r1b = 6 Else r1b = op1.regCode
        If Z80_EvalOperandExpr(op2.opndExpr, emitMode, v) = 0 Then Return -1
        outBytes(0) = &H06 Or (r1b Shl 3)
        If emitMode <> 0 Then outBytes(1) = v And &HFF
        Return 2
    End If

    If op1.opndKind = Z80OPND_REG8 And op1.regCode = 7 And op2.opndKind = Z80OPND_INDBC Then
        outBytes(0) = &H0A : Return 1
    End If
    If op1.opndKind = Z80OPND_REG8 And op1.regCode = 7 And op2.opndKind = Z80OPND_INDDE Then
        outBytes(0) = &H1A : Return 1
    End If
    If op1.opndKind = Z80OPND_INDBC And op2.opndKind = Z80OPND_REG8 And op2.regCode = 7 Then
        outBytes(0) = &H02 : Return 1
    End If
    If op1.opndKind = Z80OPND_INDDE And op2.opndKind = Z80OPND_REG8 And op2.regCode = 7 Then
        outBytes(0) = &H12 : Return 1
    End If

    If op1.opndKind = Z80OPND_REG8 And op1.regCode = 7 And op2.opndKind = Z80OPND_INDIMM Then
        If Z80_EvalOperandExpr(op2.opndExpr, emitMode, v) = 0 Then Return -1
        outBytes(0) = &H3A
        If emitMode <> 0 Then outBytes(1) = v And &HFF : outBytes(2) = (v Shr 8) And &HFF
        Return 3
    End If
    If op1.opndKind = Z80OPND_INDIMM And op2.opndKind = Z80OPND_REG8 And op2.regCode = 7 Then
        If Z80_EvalOperandExpr(op1.opndExpr, emitMode, v) = 0 Then Return -1
        outBytes(0) = &H32
        If emitMode <> 0 Then outBytes(1) = v And &HFF : outBytes(2) = (v Shr 8) And &HFF
        Return 3
    End If

    If op1.opndKind = Z80OPND_REG16 And op2.opndKind = Z80OPND_INDIMM Then
        If Z80_EvalOperandExpr(op2.opndExpr, emitMode, v) = 0 Then Return -1
        If op1.regCode = 2 Then
            outBytes(0) = &H2A
            If emitMode <> 0 Then outBytes(1) = v And &HFF : outBytes(2) = (v Shr 8) And &HFF
            Return 3
        Else
            outBytes(0) = &HED : outBytes(1) = &H4B Or (op1.regCode Shl 4)
            If emitMode <> 0 Then outBytes(2) = v And &HFF : outBytes(3) = (v Shr 8) And &HFF
            Return 4
        End If
    End If
    If op1.opndKind = Z80OPND_INDIMM And op2.opndKind = Z80OPND_REG16 Then
        If Z80_EvalOperandExpr(op1.opndExpr, emitMode, v) = 0 Then Return -1
        If op2.regCode = 2 Then
            outBytes(0) = &H22
            If emitMode <> 0 Then outBytes(1) = v And &HFF : outBytes(2) = (v Shr 8) And &HFF
            Return 3
        Else
            outBytes(0) = &HED : outBytes(1) = &H43 Or (op2.regCode Shl 4)
            If emitMode <> 0 Then outBytes(2) = v And &HFF : outBytes(3) = (v Shr 8) And &HFF
            Return 4
        End If
    End If

    If op1.opndKind = Z80OPND_IX And op2.opndKind = Z80OPND_INDIMM Then
        If Z80_EvalOperandExpr(op2.opndExpr, emitMode, v) = 0 Then Return -1
        outBytes(0) = &HDD : outBytes(1) = &H2A
        If emitMode <> 0 Then outBytes(2) = v And &HFF : outBytes(3) = (v Shr 8) And &HFF
        Return 4
    End If
    If op1.opndKind = Z80OPND_INDIMM And op2.opndKind = Z80OPND_IX Then
        If Z80_EvalOperandExpr(op1.opndExpr, emitMode, v) = 0 Then Return -1
        outBytes(0) = &HDD : outBytes(1) = &H22
        If emitMode <> 0 Then outBytes(2) = v And &HFF : outBytes(3) = (v Shr 8) And &HFF
        Return 4
    End If
    If op1.opndKind = Z80OPND_IY And op2.opndKind = Z80OPND_INDIMM Then
        If Z80_EvalOperandExpr(op2.opndExpr, emitMode, v) = 0 Then Return -1
        outBytes(0) = &HFD : outBytes(1) = &H2A
        If emitMode <> 0 Then outBytes(2) = v And &HFF : outBytes(3) = (v Shr 8) And &HFF
        Return 4
    End If
    If op1.opndKind = Z80OPND_INDIMM And op2.opndKind = Z80OPND_IY Then
        If Z80_EvalOperandExpr(op1.opndExpr, emitMode, v) = 0 Then Return -1
        outBytes(0) = &HFD : outBytes(1) = &H22
        If emitMode <> 0 Then outBytes(2) = v And &HFF : outBytes(3) = (v Shr 8) And &HFF
        Return 4
    End If

    If op1.opndKind = Z80OPND_REG16 And op2.opndKind = Z80OPND_IMM Then
        If Z80_EvalOperandExpr(op2.opndExpr, emitMode, v) = 0 Then Return -1
        outBytes(0) = &H01 Or (op1.regCode Shl 4)
        If emitMode <> 0 Then outBytes(1) = v And &HFF : outBytes(2) = (v Shr 8) And &HFF
        Return 3
    End If
    If op1.opndKind = Z80OPND_IX And op2.opndKind = Z80OPND_IMM Then
        If Z80_EvalOperandExpr(op2.opndExpr, emitMode, v) = 0 Then Return -1
        outBytes(0) = &HDD : outBytes(1) = &H21
        If emitMode <> 0 Then outBytes(2) = v And &HFF : outBytes(3) = (v Shr 8) And &HFF
        Return 4
    End If
    If op1.opndKind = Z80OPND_IY And op2.opndKind = Z80OPND_IMM Then
        If Z80_EvalOperandExpr(op2.opndExpr, emitMode, v) = 0 Then Return -1
        outBytes(0) = &HFD : outBytes(1) = &H21
        If emitMode <> 0 Then outBytes(2) = v And &HFF : outBytes(3) = (v Shr 8) And &HFF
        Return 4
    End If

    If op1.opndKind = Z80OPND_REG16 And op1.regCode = 3 And op2.opndKind = Z80OPND_REG16 And op2.regCode = 2 Then
        outBytes(0) = &HF9 : Return 1
    End If
    If op1.opndKind = Z80OPND_REG16 And op1.regCode = 3 And op2.opndKind = Z80OPND_IX Then
        outBytes(0) = &HDD : outBytes(1) = &HF9 : Return 2
    End If
    If op1.opndKind = Z80OPND_REG16 And op1.regCode = 3 And op2.opndKind = Z80OPND_IY Then
        outBytes(0) = &HFD : outBytes(1) = &HF9 : Return 2
    End If

    If op1.opndKind = Z80OPND_REG8 And op2.opndKind = Z80OPND_INDIX Then
        outBytes(0) = &HDD : outBytes(1) = &H46 Or (op1.regCode Shl 3)
        If Z80_EvalDisplacement(op2.opndExpr, emitMode, v) = 0 Then Return -1
        If emitMode <> 0 Then outBytes(2) = v And &HFF
        Return 3
    End If
    If op1.opndKind = Z80OPND_REG8 And op2.opndKind = Z80OPND_INDIY Then
        outBytes(0) = &HFD : outBytes(1) = &H46 Or (op1.regCode Shl 3)
        If Z80_EvalDisplacement(op2.opndExpr, emitMode, v) = 0 Then Return -1
        If emitMode <> 0 Then outBytes(2) = v And &HFF
        Return 3
    End If
    If op1.opndKind = Z80OPND_INDIX And op2.opndKind = Z80OPND_REG8 Then
        outBytes(0) = &HDD : outBytes(1) = &H70 Or op2.regCode
        If Z80_EvalDisplacement(op1.opndExpr, emitMode, v) = 0 Then Return -1
        If emitMode <> 0 Then outBytes(2) = v And &HFF
        Return 3
    End If
    If op1.opndKind = Z80OPND_INDIY And op2.opndKind = Z80OPND_REG8 Then
        outBytes(0) = &HFD : outBytes(1) = &H70 Or op2.regCode
        If Z80_EvalDisplacement(op1.opndExpr, emitMode, v) = 0 Then Return -1
        If emitMode <> 0 Then outBytes(2) = v And &HFF
        Return 3
    End If
    If op1.opndKind = Z80OPND_INDIX And op2.opndKind = Z80OPND_IMM Then
        Dim d1 As Integer, n1 As Integer
        outBytes(0) = &HDD : outBytes(1) = &H36
        If Z80_EvalDisplacement(op1.opndExpr, emitMode, d1) = 0 Then Return -1
        If Z80_EvalOperandExpr(op2.opndExpr, emitMode, n1) = 0 Then Return -1
        If emitMode <> 0 Then outBytes(2) = d1 And &HFF : outBytes(3) = n1 And &HFF
        Return 4
    End If
    If op1.opndKind = Z80OPND_INDIY And op2.opndKind = Z80OPND_IMM Then
        Dim d2 As Integer, n2 As Integer
        outBytes(0) = &HFD : outBytes(1) = &H36
        If Z80_EvalDisplacement(op1.opndExpr, emitMode, d2) = 0 Then Return -1
        If Z80_EvalOperandExpr(op2.opndExpr, emitMode, n2) = 0 Then Return -1
        If emitMode <> 0 Then outBytes(2) = d2 And &HFF : outBytes(3) = n2 And &HFF
        Return 4
    End If

    If op1.opndKind = Z80OPND_IXHALF And op2.opndKind = Z80OPND_IMM Then
        If Z80_EvalOperandExpr(op2.opndExpr, emitMode, v) = 0 Then Return -1
        outBytes(0) = &HDD : outBytes(1) = &H06 Or (op1.regCode Shl 3)
        If emitMode <> 0 Then outBytes(2) = v And &HFF
        Return 3
    End If
    If op1.opndKind = Z80OPND_IYHALF And op2.opndKind = Z80OPND_IMM Then
        If Z80_EvalOperandExpr(op2.opndExpr, emitMode, v) = 0 Then Return -1
        outBytes(0) = &HFD : outBytes(1) = &H06 Or (op1.regCode Shl 3)
        If emitMode <> 0 Then outBytes(2) = v And &HFF
        Return 3
    End If
    If op1.opndKind = Z80OPND_IXHALF And (op2.opndKind = Z80OPND_REG8 Or op2.opndKind = Z80OPND_IXHALF) Then
        outBytes(0) = &HDD : outBytes(1) = &H40 Or (op1.regCode Shl 3) Or op2.regCode
        Return 2
    End If
    If op2.opndKind = Z80OPND_IXHALF And op1.opndKind = Z80OPND_REG8 Then
        outBytes(0) = &HDD : outBytes(1) = &H40 Or (op1.regCode Shl 3) Or op2.regCode
        Return 2
    End If
    If op1.opndKind = Z80OPND_IYHALF And (op2.opndKind = Z80OPND_REG8 Or op2.opndKind = Z80OPND_IYHALF) Then
        outBytes(0) = &HFD : outBytes(1) = &H40 Or (op1.regCode Shl 3) Or op2.regCode
        Return 2
    End If
    If op2.opndKind = Z80OPND_IYHALF And op1.opndKind = Z80OPND_REG8 Then
        outBytes(0) = &HFD : outBytes(1) = &H40 Or (op1.regCode Shl 3) Or op2.regCode
        Return 2
    End If

    Z80LastAsmError = "LD: combinacao de operandos invalida"
    Return -1
End Function

Function Z80_EncodeInstruction(ByRef mnemonic As String, ByRef argsText As String, ByVal emitMode As Integer, outBytes() As Integer) As Integer
    Dim m As String = UCase(mnemonic)
    Dim nOps As Integer = Z80_CountOperands(argsText)
    Dim op1 As Z80Operand, op2 As Z80Operand

    Z80LastAsmError = ""

    If nOps >= 1 Then
        Z80_ClassifyOperand(Z80_GetOperand(argsText, 1), op1)
    Else
        op1.opndKind = Z80OPND_NONE : op1.present = 0
    End If
    If nOps >= 2 Then
        Z80_ClassifyOperand(Z80_GetOperand(argsText, 2), op2)
    Else
        op2.opndKind = Z80OPND_NONE : op2.present = 0
    End If

    Select Case m
        Case "NOP" : outBytes(0) = &H00 : Return 1
        Case "HALT" : outBytes(0) = &H76 : Return 1
        Case "DI" : outBytes(0) = &HF3 : Return 1
        Case "EI" : outBytes(0) = &HFB : Return 1
        Case "DAA" : outBytes(0) = &H27 : Return 1
        Case "CPL" : outBytes(0) = &H2F : Return 1
        Case "CCF" : outBytes(0) = &H3F : Return 1
        Case "SCF" : outBytes(0) = &H37 : Return 1
        Case "RLCA" : outBytes(0) = &H07 : Return 1
        Case "RLA" : outBytes(0) = &H17 : Return 1
        Case "RRCA" : outBytes(0) = &H0F : Return 1
        Case "RRA" : outBytes(0) = &H1F : Return 1
        Case "EXX" : outBytes(0) = &HD9 : Return 1
        Case "NEG" : outBytes(0) = &HED : outBytes(1) = &H44 : Return 2
        Case "RETN" : outBytes(0) = &HED : outBytes(1) = &H45 : Return 2
        Case "RETI" : outBytes(0) = &HED : outBytes(1) = &H4D : Return 2
        Case "RLD" : outBytes(0) = &HED : outBytes(1) = &H6F : Return 2
        Case "RRD" : outBytes(0) = &HED : outBytes(1) = &H67 : Return 2
        Case "LDI" : outBytes(0) = &HED : outBytes(1) = &HA0 : Return 2
        Case "LDD" : outBytes(0) = &HED : outBytes(1) = &HA8 : Return 2
        Case "LDIR" : outBytes(0) = &HED : outBytes(1) = &HB0 : Return 2
        Case "LDDR" : outBytes(0) = &HED : outBytes(1) = &HB8 : Return 2
        Case "CPI" : outBytes(0) = &HED : outBytes(1) = &HA1 : Return 2
        Case "CPD" : outBytes(0) = &HED : outBytes(1) = &HA9 : Return 2
        Case "CPIR" : outBytes(0) = &HED : outBytes(1) = &HB1 : Return 2
        Case "CPDR" : outBytes(0) = &HED : outBytes(1) = &HB9 : Return 2
        Case "INI" : outBytes(0) = &HED : outBytes(1) = &HA2 : Return 2
        Case "IND" : outBytes(0) = &HED : outBytes(1) = &HAA : Return 2
        Case "INIR" : outBytes(0) = &HED : outBytes(1) = &HB2 : Return 2
        Case "INDR" : outBytes(0) = &HED : outBytes(1) = &HBA : Return 2
        Case "OUTI" : outBytes(0) = &HED : outBytes(1) = &HA3 : Return 2
        Case "OUTD" : outBytes(0) = &HED : outBytes(1) = &HAB : Return 2
        Case "OTIR" : outBytes(0) = &HED : outBytes(1) = &HB3 : Return 2
        Case "OTDR" : outBytes(0) = &HED : outBytes(1) = &HBB : Return 2
        Case "RST" : Return Z80EncodeRst(op1, emitMode, outBytes())
        Case "IM" : Return Z80EncodeIm(op1, emitMode, outBytes())
        Case "EX" : Return Z80EncodeEx(op1, op2, emitMode, outBytes())
        Case "IN" : Return Z80EncodeIn(op1, op2, nOps, emitMode, outBytes())
        Case "OUT" : Return Z80EncodeOut(op1, op2, emitMode, outBytes())
        Case "PUSH" : Return Z80EncodePushPop(&HC5, op1, emitMode, outBytes())
        Case "POP" : Return Z80EncodePushPop(&HC1, op1, emitMode, outBytes())
        Case "INC" : Return Z80EncodeIncDec(-1, op1, emitMode, outBytes())
        Case "DEC" : Return Z80EncodeIncDec(0, op1, emitMode, outBytes())
        Case "ADD" : Return Z80EncodeAdd(op1, op2, nOps, emitMode, outBytes())
        Case "ADC" : Return Z80EncodeAdcSbc(-1, op1, op2, nOps, emitMode, outBytes())
        Case "SBC" : Return Z80EncodeAdcSbc(0, op1, op2, nOps, emitMode, outBytes())
        Case "SUB" : Return Z80EncodeAluSingle(2, op1, op2, nOps, emitMode, outBytes())
        Case "AND" : Return Z80EncodeAluSingle(4, op1, op2, nOps, emitMode, outBytes())
        Case "XOR" : Return Z80EncodeAluSingle(5, op1, op2, nOps, emitMode, outBytes())
        Case "OR" : Return Z80EncodeAluSingle(6, op1, op2, nOps, emitMode, outBytes())
        Case "CP" : Return Z80EncodeAluSingle(7, op1, op2, nOps, emitMode, outBytes())
        Case "LD" : Return Z80EncodeLd(op1, op2, emitMode, outBytes())
        Case "JP" : Return Z80EncodeJp(op1, op2, nOps, emitMode, outBytes())
        Case "JR" : Return Z80EncodeJr(op1, op2, nOps, emitMode, outBytes())
        Case "DJNZ" : Return Z80EncodeDjnz(op1, emitMode, outBytes())
        Case "CALL" : Return Z80EncodeCallRet(-1, op1, op2, nOps, emitMode, outBytes())
        Case "RET" : Return Z80EncodeCallRet(0, op1, op2, nOps, emitMode, outBytes())
        Case "RLC", "RRC", "RL", "RR", "SLA", "SRA", "SLL", "SRL"
            Return Z80EncodeCbShift(m, op1, emitMode, outBytes())
        Case "BIT", "SET", "RES"
            Return Z80EncodeCbBit(m, op1, op2, emitMode, outBytes())
    End Select

    Z80LastAsmError = "Mnemonico Z80 desconhecido: " & mnemonic
    Return -1
End Function

' ---------------------------------------------------------------------------
' Diretivas de dados (DEFB/DEFM/DEFW/DEFS - unico subconjunto que a gramatica
' do EDIT do Mamute pode produzir).
' ---------------------------------------------------------------------------

Private Function Z80ExpandDataOperand(ByRef text As String, ByVal emitMode As Integer, outBytes() As Integer, ByRef outCount As Integer) As Integer
    Dim t As String = Z80RTrimWs(Mid(text, Z80SkipWs(text, 1)))
    Dim v As Integer

    If Len(t) >= 2 And (Left(t, 1) = Chr(34) Or Left(t, 1) = "'") And Right(t, 1) = Left(t, 1) Then
        Dim delimCh As String = Left(t, 1)
        Dim bodyText As String = Mid(t, 2, Len(t) - 2)
        Dim dd As String = delimCh & delimCh
        Dim rebuilt As String = ""
        Dim scanIdx As Integer = 1
        While scanIdx <= Len(bodyText)
            If Mid(bodyText, scanIdx, 2) = dd Then
                rebuilt &= delimCh
                scanIdx += 2
            Else
                rebuilt &= Mid(bodyText, scanIdx, 1)
                scanIdx += 1
            End If
        Wend
        Dim ci As Integer
        For ci = 1 To Len(rebuilt)
            outCount += 1
            outBytes(outCount) = Asc(Mid(rebuilt, ci, 1)) And &HFF
        Next ci
        Return -1
    End If

    If Z80_EvalOperandExpr(t, emitMode, v) = 0 Then Return 0
    outCount += 1
    outBytes(outCount) = v And &HFF
    Return -1
End Function

Function Z80_EncodeDataDirective(ByRef op As String, ByRef argsText As String, ByVal emitMode As Integer, outBytes() As Integer, ByRef outCount As Integer) As Integer
    outCount = 0
    Dim nOps As Integer = Z80_CountOperands(argsText)
    Dim idxOp As Integer

    Select Case op
        Case "DEFB", "DEFM"
            If nOps = 0 Then
                Z80LastAsmError = op & ": precisa de pelo menos um operando"
                Return 0
            End If
            For idxOp = 1 To nOps
                If Z80ExpandDataOperand(Z80_GetOperand(argsText, idxOp), emitMode, outBytes(), outCount) = 0 Then Return 0
            Next idxOp
            Return -1

        Case "DEFW"
            If nOps = 0 Then
                Z80LastAsmError = op & ": precisa de pelo menos um operando"
                Return 0
            End If
            Dim vw As Integer
            For idxOp = 1 To nOps
                If Z80_EvalOperandExpr(Z80_GetOperand(argsText, idxOp), emitMode, vw) = 0 Then Return 0
                outCount += 1 : outBytes(outCount) = vw And &HFF
                outCount += 1 : outBytes(outCount) = (vw Shr 8) And &HFF
            Next idxOp
            Return -1

        Case "DEFS"
            If nOps < 1 Or nOps > 2 Then
                Z80LastAsmError = "DEFS: precisa de 1 ou 2 operandos (tamanho[,valor])"
                Return 0
            End If
            Dim sizeV As Integer
            If Z80_EvalExpr(Z80_GetOperand(argsText, 1), sizeV) = 0 Then
                Z80LastAsmError = "DEFS: tamanho precisa ser conhecido ja no pass 1 (nao pode depender de rotulo definido so depois): " & Z80LastEvalError & Z80LastEvalUnknownSymbol
                Return 0
            End If
            Dim fillV As Integer = 0
            If nOps = 2 Then
                If Z80_EvalOperandExpr(Z80_GetOperand(argsText, 2), emitMode, fillV) = 0 Then Return 0
                fillV = fillV And &HFF
            End If
            Dim dsIdx As Integer
            For dsIdx = 1 To sizeV
                outCount += 1 : outBytes(outCount) = fillV
            Next dsIdx
            Return -1
    End Select

    Z80LastAsmError = "Diretiva de dados desconhecida: " & op
    Return 0
End Function

' ---------------------------------------------------------------------------
' Listagem / referencia cruzada
' ---------------------------------------------------------------------------

Private Sub Z80ListingAddRow(ByVal srcLine As Integer, ByVal isEquLine As Integer, ByVal addrOrValue As Integer, byteVals() As Integer, ByVal byteValsCount As Integer)
    Dim firstFlag As Integer = -1
    Dim chunkIdx As Integer = 0
    Dim bi As Integer

    If byteValsCount = 0 Then
        If Z80ListingRowCount < Z80_MAX_LISTING_ROWS Then
            Z80ListingRowCount += 1
            Z80ListingRows(Z80ListingRowCount).sourceLine = srcLine
            Z80ListingRows(Z80ListingRowCount).hasAddr = -1
            Z80ListingRows(Z80ListingRowCount).isEqu = isEquLine
            Z80ListingRows(Z80ListingRowCount).rowAddr = addrOrValue
            Z80ListingRows(Z80ListingRowCount).byteCount = 0
        End If
        Exit Sub
    End If

    For bi = 1 To byteValsCount
        If chunkIdx = 0 Then
            If Z80ListingRowCount >= Z80_MAX_LISTING_ROWS Then Exit For
            Z80ListingRowCount += 1
            If firstFlag <> 0 Then
                Z80ListingRows(Z80ListingRowCount).sourceLine = srcLine
                Z80ListingRows(Z80ListingRowCount).hasAddr = -1
                Z80ListingRows(Z80ListingRowCount).isEqu = isEquLine
                Z80ListingRows(Z80ListingRowCount).rowAddr = addrOrValue
                firstFlag = 0
            End If
        End If
        Select Case chunkIdx
            Case 0 : Z80ListingRows(Z80ListingRowCount).byte0 = byteVals(bi)
            Case 1 : Z80ListingRows(Z80ListingRowCount).byte1 = byteVals(bi)
            Case 2 : Z80ListingRows(Z80ListingRowCount).byte2 = byteVals(bi)
            Case 3 : Z80ListingRows(Z80ListingRowCount).byte3 = byteVals(bi)
        End Select
        Z80ListingRows(Z80ListingRowCount).byteCount += 1
        chunkIdx += 1
        If chunkIdx >= 4 Then chunkIdx = 0
    Next bi
End Sub

Sub Z80_XrefBuildRows()
    Z80XrefRowCount = 0

    Dim names(1 To Z80_MAX_SYMBOLS) As String
    Dim nameCount As Integer = 0
    Dim si As Integer
    For si = 1 To Z80SymbolCount
        If Z80Symbols(si).isKnown <> 0 Then
            nameCount += 1
            names(nameCount) = Z80Symbols(si).symName
        End If
    Next si

    ' insertion sort alfabetico (nameCount tipicamente pequeno - poucas
    ' centenas de simbolos no maximo, num programa de ate 2000 linhas)
    Dim ai As Integer, bi As Integer
    For ai = 2 To nameCount
        Dim keyName As String = names(ai)
        bi = ai - 1
        While bi >= 1 And names(bi) > keyName
            names(bi + 1) = names(bi)
            bi -= 1
        Wend
        names(bi + 1) = keyName
    Next ai

    Dim useAddrs(1 To Z80_MAX_SYMBOL_REFS) As Integer
    Dim useCount As Integer
    Dim ni As Integer
    For ni = 1 To nameCount
        Dim symIdx As Integer = Z80FindSymbol(names(ni))
        Dim symValue As Integer = 0
        If symIdx > 0 Then symValue = Z80Symbols(symIdx).symValue

        useCount = 0
        Dim ri As Integer
        For ri = 1 To Z80SymbolRefCount
            If Z80SymbolRefs(ri).symName = names(ni) Then
                useCount += 1
                useAddrs(useCount) = Z80SymbolRefs(ri).refAddr
            End If
        Next ri

        Dim firstRow As Integer = -1
        If useCount = 0 Then
            If Z80XrefRowCount < Z80_MAX_SYMBOLS Then
                Z80XrefRowCount += 1
                Z80XrefRows(Z80XrefRowCount).symName = names(ni)
                Z80XrefRows(Z80XrefRowCount).hasValue = -1
                Z80XrefRows(Z80XrefRowCount).rowValue = symValue
                Z80XrefRows(Z80XrefRowCount).addrCount = 0
            End If
        Else
            Dim remaining As Integer = useCount
            Dim consumed As Integer = 0
            While remaining > 0
                If Z80XrefRowCount >= Z80_MAX_SYMBOLS Then Exit While
                Z80XrefRowCount += 1
                If firstRow <> 0 Then
                    Z80XrefRows(Z80XrefRowCount).symName = names(ni)
                    Z80XrefRows(Z80XrefRowCount).hasValue = -1
                    Z80XrefRows(Z80XrefRowCount).rowValue = symValue
                    firstRow = 0
                End If
                Dim thisChunk As Integer = remaining
                If thisChunk > 4 Then thisChunk = 4
                Z80XrefRows(Z80XrefRowCount).addrCount = thisChunk
                Dim b As Integer
                For b = 0 To thisChunk - 1
                    consumed += 1
                    Select Case b
                        Case 0 : Z80XrefRows(Z80XrefRowCount).addr0 = useAddrs(consumed)
                        Case 1 : Z80XrefRows(Z80XrefRowCount).addr1 = useAddrs(consumed)
                        Case 2 : Z80XrefRows(Z80XrefRowCount).addr2 = useAddrs(consumed)
                        Case 3 : Z80XrefRows(Z80XrefRowCount).addr3 = useAddrs(consumed)
                    End Select
                Next b
                remaining -= thisChunk
            Wend
        End If
    Next ni
End Sub

Function Z80_GetLabelDefOrderCount() As Integer
    Return Z80SymbolDefOrderCount
End Function

Function Z80_GetLabelDefOrderName(ByVal index0 As Integer) As String
    If index0 < 0 Or index0 >= Z80SymbolDefOrderCount Then Return ""
    Return Z80SymbolDefOrder(index0 + 1)
End Function

Function Z80_GetXrefRowCount() As Integer
    Return Z80XrefRowCount
End Function

Function Z80_GetXrefRow(ByVal index0 As Integer, ByRef outRow As Z80XrefRow) As Integer
    If index0 < 0 Or index0 >= Z80XrefRowCount Then Return 0
    outRow = Z80XrefRows(index0 + 1)
    Return -1
End Function

Function Z80_GetListingRowCount() As Integer
    Return Z80ListingRowCount
End Function

Function Z80_GetListingRow(ByVal index0 As Integer, ByRef outRow As Z80ListingRow) As Integer
    If index0 < 0 Or index0 >= Z80ListingRowCount Then Return 0
    outRow = Z80ListingRows(index0 + 1)
    Return -1
End Function

Function Z80_GetAssembleErrorLine() As Integer
    Return Z80AsmErrorLine
End Function

Function Z80_GetAssembleErrorText() As String
    Return Z80AsmErrorText
End Function

Function Z80_GetAssembleStartAddr() As Integer
    Return Z80MinAddrTouched And &HFFFF
End Function

Function Z80_GetAssembleEndAddr() As Integer
    Return Z80MaxAddrTouched And &HFFFF
End Function

' ---------------------------------------------------------------------------
' Driver de 2 passes
' ---------------------------------------------------------------------------

Private Function Z80ReplaceAllLocal(ByRef sourceText As String, ByRef findText As String, ByRef replaceText As String) As String
    If Len(findText) = 0 Then Return sourceText
    Dim resultText As String = ""
    Dim remaining As String = sourceText
    Do
        Dim foundPos As Integer = InStr(remaining, findText)
        If foundPos = 0 Then
            resultText &= remaining
            Exit Do
        End If
        resultText &= Left(remaining, foundPos - 1) & replaceText
        remaining = Mid(remaining, foundPos + Len(findText))
    Loop
    Return resultText
End Function

Private Sub Z80SplitSourceLines(ByRef sourceText As String, lines() As String, ByRef lineCount As Integer)
    lineCount = 0
    Dim norm As String = sourceText
    norm = Z80ReplaceAllLocal(norm, Chr(13) & Chr(10), Chr(10))
    norm = Z80ReplaceAllLocal(norm, Chr(13), Chr(10))

    Dim startPos As Integer = 1
    Dim lenNorm As Integer = Len(norm)
    Dim scanPos As Integer
    For scanPos = 1 To lenNorm + 1
        If scanPos > lenNorm OrElse Mid(norm, scanPos, 1) = Chr(10) Then
            lineCount += 1
            lines(lineCount) = Mid(norm, startPos, scanPos - startPos)
            startPos = scanPos + 1
        End If
    Next scanPos
    If lineCount = 0 Then
        lineCount = 1
        lines(1) = ""
    End If
End Sub

Const Z80_MAX_SOURCE_LINES = 4000

Private Function Z80RunOnePass(lines() As String, ByVal lineCount As Integer, ByVal sizeOnly As Integer, mem() As Integer) As Integer
    Dim lineNum As Integer = 0
    Dim pl As Z80ParsedLine
    Dim bytesOut(0 To 3) As Integer
    Dim len4 As Integer, idx As Integer
    Dim endedFlag As Integer = 0
    Dim v1 As Integer, v2 As Integer, v3 As Integer
    Dim emitNow As Integer = (sizeOnly = 0)

    If sizeOnly <> 0 Then Z80PassNumber = 1 Else Z80PassNumber = 2

    Z80CurLoc = 0
    Z80RealPos = 0

    Dim li As Integer
    For li = 1 To lineCount
        If endedFlag <> 0 Then Exit For
        lineNum += 1

        Z80_ParseLine(lines(li), pl)

        If pl.isBlank <> 0 Then Continue For

        If pl.hasLabel <> 0 And pl.labelHasColon <> 0 And Not (pl.hasOperator <> 0 And (pl.oper = "EQU" Or pl.oper = "DEFL" Or pl.oper = "ASET")) Then
            If Z80_DefineSymbol(pl.lbl, Z80CurLoc, 0) = 0 Then
                Z80AsmErrorLine = lineNum : Z80AsmErrorText = Z80LastEvalError
                Return 0
            End If
        End If

        If pl.hasOperator = 0 Then Continue For

        Select Case pl.oper
            Case "EQU"
                If Z80_EvalExpr(pl.argsText, v1) <> 0 Then
                    If Z80_DefineSymbol(pl.lbl, v1, -1) = 0 Then
                        Z80AsmErrorLine = lineNum : Z80AsmErrorText = Z80LastEvalError
                        Return 0
                    End If
                    If sizeOnly = 0 Then
                        Dim emptyB(0 To 0) As Integer
                        Z80ListingAddRow(lineNum, -1, v1, emptyB(), 0)
                    End If
                ElseIf sizeOnly = 0 Then
                    Z80AsmErrorLine = lineNum : Z80AsmErrorText = "EQU: " & Z80LastEvalError & Z80LastEvalUnknownSymbol
                    Return 0
                End If
                Continue For

            Case "DEFL", "ASET"
                If Z80_EvalExpr(pl.argsText, v2) <> 0 Then
                    Dim symIdx2 As Integer = Z80FindOrAddSymbol(pl.lbl)
                    If symIdx2 > 0 Then
                        Z80Symbols(symIdx2).symValue = v2
                        Z80Symbols(symIdx2).isKnown = -1
                        Z80Symbols(symIdx2).isConstant = 0
                    End If
                    If sizeOnly = 0 Then
                        Dim emptyB2(0 To 0) As Integer
                        Z80ListingAddRow(lineNum, -1, v2, emptyB2(), 0)
                    End If
                ElseIf sizeOnly = 0 Then
                    Z80AsmErrorLine = lineNum : Z80AsmErrorText = "DEFL/ASET: " & Z80LastEvalError & Z80LastEvalUnknownSymbol
                    Return 0
                End If
                Continue For

            Case "ORG"
                If Z80_EvalExpr(pl.argsText, v3) <> 0 Then
                    Z80CurLoc = v3
                    Z80RealPos = v3
                ElseIf sizeOnly = 0 Then
                    Z80AsmErrorLine = lineNum : Z80AsmErrorText = "ORG: " & Z80LastEvalError & Z80LastEvalUnknownSymbol
                    Return 0
                End If
                Continue For

            Case "END"
                endedFlag = -1
                Continue For

            Case "DEFB", "DEFW", "DEFM", "DEFS"
                Dim dataCount As Integer
                If Z80_EncodeDataDirective(pl.oper, pl.argsText, emitNow, Z80RunOneDataBytes(), dataCount) = 0 Then
                    Z80AsmErrorLine = lineNum : Z80AsmErrorText = Z80LastAsmError
                    Return 0
                End If
                If sizeOnly = 0 Then
                    Dim dIdx As Integer
                    Dim dAddr As Integer
                    For dIdx = 1 To dataCount
                        dAddr = (Z80RealPos + dIdx - 1) And &HFFFF
                        mem(dAddr) = Z80RunOneDataBytes(dIdx)
                        If Z80AnyByteWritten = 0 Then
                            Z80MinAddrTouched = dAddr : Z80MaxAddrTouched = dAddr : Z80AnyByteWritten = -1
                        Else
                            If dAddr < Z80MinAddrTouched Then Z80MinAddrTouched = dAddr
                            If dAddr > Z80MaxAddrTouched Then Z80MaxAddrTouched = dAddr
                        End If
                    Next dIdx
                    Z80ListingAddRow(lineNum, 0, Z80RealPos, Z80RunOneDataBytes(), dataCount)
                End If
                Z80CurLoc = (Z80CurLoc + dataCount) And &HFFFF
                Z80RealPos = (Z80RealPos + dataCount) And &HFFFF
                Continue For
        End Select

        If Z80_IsMnemonic(pl.oper) = 0 Then
            Z80AsmErrorLine = lineNum
            Z80AsmErrorText = "Diretiva/mnemonico nao suportado nesta versao: " & pl.oper
            Return 0
        End If

        len4 = Z80_EncodeInstruction(pl.oper, pl.argsText, emitNow, bytesOut())
        If len4 < 0 Then
            Z80AsmErrorLine = lineNum : Z80AsmErrorText = Z80LastAsmError
            Return 0
        End If

        If sizeOnly = 0 Then
            Dim iAddr As Integer
            For idx = 0 To len4 - 1
                iAddr = (Z80RealPos + idx) And &HFFFF
                mem(iAddr) = bytesOut(idx)
                If Z80AnyByteWritten = 0 Then
                    Z80MinAddrTouched = iAddr : Z80MaxAddrTouched = iAddr : Z80AnyByteWritten = -1
                Else
                    If iAddr < Z80MinAddrTouched Then Z80MinAddrTouched = iAddr
                    If iAddr > Z80MaxAddrTouched Then Z80MaxAddrTouched = iAddr
                End If
            Next idx
            Dim listBytes(1 To 4) As Integer
            For idx = 0 To len4 - 1
                listBytes(idx + 1) = bytesOut(idx)
            Next idx
            Z80ListingAddRow(lineNum, 0, Z80RealPos, listBytes(), len4)
        End If

        Z80CurLoc = (Z80CurLoc + len4) And &HFFFF
        Z80RealPos = (Z80RealPos + len4) And &HFFFF
    Next li

    Return -1
End Function

Function Z80_Assemble(ByRef sourceText As String, outBytes() As Integer) As Integer
    Dim lines(1 To Z80_MAX_SOURCE_LINES) As String
    Dim lineCount As Integer
    Dim idx As Integer

    Z80_ResetState()
    Z80AsmErrorLine = 0 : Z80AsmErrorText = ""
    Z80MinAddrTouched = 0 : Z80MaxAddrTouched = 0 : Z80AnyByteWritten = 0
    Z80ListingRowCount = 0
    Z80SymbolRefCount = 0
    Z80SymbolDefOrderCount = 0
    For idx = 0 To 65535
        Z80AssembleMem(idx) = 0
    Next idx

    Z80SplitSourceLines(sourceText, lines(), lineCount)

    If Z80RunOnePass(lines(), lineCount, -1, Z80AssembleMem()) = 0 Then Return -1
    If Z80RunOnePass(lines(), lineCount, 0, Z80AssembleMem()) = 0 Then Return -1

    Z80_XrefBuildRows()

    If Z80AnyByteWritten = 0 Then Return 0

    Dim n As Integer = Z80MaxAddrTouched - Z80MinAddrTouched + 1
    For idx = 0 To n - 1
        outBytes(idx) = Z80AssembleMem(Z80MinAddrTouched + idx)
    Next idx
    Return n
End Function

' ---------------------------------------------------------------------------
' Comando EDIT: editor de linhas do programa-fonte Z80, estilo ZX-81/ZX
' Spectrum (pedido explicito do usuario), portado de MamuteEditGui.pbi/
' MamuteSupport.pbi (paleobasic) pro terminal em modo texto. Abre numa
' janela PROPRIA (nao mistura com o scrollback do MON>) - a listagem do
' programa e' a propria area de cima do documento, cursor ">" marcando a
' linha atual, campo "ASM>" reservado embaixo (mesma ideia da linha de
' entrada do MON>, so' que com mais uma linha de status acima dela).
'
' Sintaxe de cada linha (formato do manual original do MegaAssembler):
'   NN Label: instrucao operando ;comentario
' NN e' decimal (0-65529, mesmo teto do numero de linha do BASIC/MSX) -
' digitar de novo o mesmo NN substitui a linha. Numeros DENTRO do operando
' (Mamute_ParseAsmNumber) seguem a convencao ja estabelecida no resto do
' Mamute: hexadecimal por padrao, sufixo H/B/D pra hexa explicito/binario/
' decimal.
'
' Escopo desta fase (pedido do usuario cobre listar/editar/navegar entre
' linhas): aceitar, editar, listar, navegar e os comandos de gerenciamento
' do fonte (NEW/DELETE/RENUM/CHANGE/SEARCH/FIND/LSEARCH/SAVE/LOAD/MERGE/
' QUIT). O comando A (montar de verdade) e MAP ficam FORA desta fase -
' precisam de um assembler Z80 completo por baixo (Z80Asm.pbi la' no
' paleobasic; nao existe equivalente aqui ainda), sinalizado no HELP e na
' propria janela em vez de fingir suporte.
' ---------------------------------------------------------------------------

' Mnemonicos Z80 validos (so' o NOME - EDIT nao valida modo de enderecamento
' nem resolve simbolos, mesmo escopo raso do original: "por hora vamos
' apenas aceitar o programa, depois trataremos a compilacao") + as 6
' pseudo-instrucoes do manual (ORG/DEFB/DEFW/DEFM/DEFS/EQU) mais END (ultima
' linha do proprio exemplo oficial do manual - sem ela nem aquele exemplo
' seria aceito).
Const MAMUTE_ASM_MNEMONICS = "|LD|PUSH|POP|EX|EXX|LDI|LDIR|LDD|LDDR|CPI|CPIR|CPD|CPDR|ADD|ADC|SUB|SBC|AND|OR|XOR|CP|INC|DEC|DAA|CPL|NEG|CCF|SCF|NOP|HALT|DI|EI|IM|RLCA|RRCA|RLA|RRA|RLC|RRC|RL|RR|SLA|SRA|SLL|SRL|RLD|RRD|BIT|SET|RES|JP|JR|DJNZ|CALL|RET|RETI|RETN|RST|IN|OUT|INI|INIR|IND|INDR|OUTI|OTIR|OUTD|OTDR|"
Const MAMUTE_ASM_PSEUDOOPS = "|ORG|DEFB|DEFW|DEFM|DEFS|EQU|END|"

Private Function Mamute_IsAsmMnemonic(ByRef word As String) As Integer
    Return InPipeList(UCase(word), MAMUTE_ASM_MNEMONICS)
End Function

Private Function Mamute_IsAsmPseudoOp(ByRef word As String) As Integer
    Return InPipeList(UCase(word), MAMUTE_ASM_PSEUDOOPS)
End Function

Private Function Mamute_IsDecimalString(ByRef token As String) As Integer
    If Len(token) = 0 Then Return 0
    Dim i As Integer
    For i = 1 To Len(token)
        Dim ch As String = Mid(token, i, 1)
        If ch < "0" Or ch > "9" Then Return 0
    Next i
    Return -1
End Function

' Identificador de label - primeiro caractere letra ou "_", resto
' letras/digitos/"_".
Private Function Mamute_IsValidAsmLabel(ByRef labelText As String) As Integer
    If Len(labelText) = 0 Then Return 0
    Dim firstCh As String = UCase(Mid(labelText, 1, 1))
    If (firstCh < "A" Or firstCh > "Z") And firstCh <> "_" Then Return 0
    Dim i As Integer
    For i = 2 To Len(labelText)
        Dim ch As String = UCase(Mid(labelText, i, 1))
        If (ch < "A" Or ch > "Z") And (ch < "0" Or ch > "9") And ch <> "_" Then Return 0
    Next i
    Return -1
End Function

' Numero no dialeto do operando do EDIT - token PRECISA comecar com digito
' 0-9. Sufixo opcional no ULTIMO caractere (H/B/D) decide a base e SEMPRE
' vence sobre a leitura hexa padrao (H nunca e' digito hexa valido, mas B/D
' sao - pra escrever um hexa terminado em B/D sem ambiguidade, use o sufixo
' H explicito, ex.: "1BH").
Private Function Mamute_ParseAsmNumber(ByRef token As String, ByRef outValue As Integer) As Integer
    If Len(token) = 0 Then Return 0
    Dim firstCh As String = Mid(token, 1, 1)
    If firstCh < "0" Or firstCh > "9" Then Return 0

    Dim lastCh As String = UCase(Right(token, 1))
    Dim digitsTok As String
    Dim baseVal As Integer
    Select Case lastCh
        Case "H"
            digitsTok = Left(token, Len(token) - 1) : baseVal = 16
        Case "B"
            digitsTok = Left(token, Len(token) - 1) : baseVal = 2
        Case "D"
            digitsTok = Left(token, Len(token) - 1) : baseVal = 10
        Case Else
            digitsTok = token : baseVal = 16
    End Select
    If Len(digitsTok) = 0 Then Return 0

    Dim hexDigits As String = "0123456789ABCDEF"
    Dim i As Integer
    Dim valueAcc As Integer = 0
    For i = 1 To Len(digitsTok)
        Dim ch As String = UCase(Mid(digitsTok, i, 1))
        Dim digVal As Integer = InStr(hexDigits, ch) - 1
        If digVal < 0 Or digVal >= baseVal Then Return 0
        valueAcc = valueAcc * baseVal + digVal
    Next i

    outValue = valueAcc
    Return -1
End Function

' Varre o operando procurando tokens alfanumericos fora de trechos entre
' apostrofos (texto/char literal de DEFB/DEFM/etc., nunca numero) - todo
' token comecando em digito 0-9 precisa passar por Mamute_ParseAsmNumber();
' tokens comecando em letra (label/registrador) nao sao validados aqui (sem
' tabela de simbolos nesta fase).
Private Function Mamute_ValidateAsmOperandNumbers(ByRef operandText As String) As Integer
    Dim inQuote As Integer = 0
    Dim lenText As Integer = Len(operandText)
    Dim i As Integer
    Dim tokenBuf As String = ""
    Dim dummyVal As Integer

    For i = 1 To lenText + 1
        Dim ch As String
        If i <= lenText Then
            ch = Mid(operandText, i, 1)
        Else
            ch = " " ' sentinela pra fechar o ultimo token pendente
        End If

        If inQuote <> 0 Then
            If ch = "'" Then inQuote = 0
            Continue For
        End If

        If ch = "'" Then
            inQuote = -1
            If Len(tokenBuf) > 0 Then
                Dim tFirst As String = Mid(tokenBuf, 1, 1)
                If tFirst >= "0" And tFirst <= "9" Then
                    If Mamute_ParseAsmNumber(tokenBuf, dummyVal) = 0 Then Return 0
                End If
                tokenBuf = ""
            End If
            Continue For
        End If

        Dim isAlnum As Integer = 0
        If (ch >= "0" And ch <= "9") Or (ch >= "A" And ch <= "Z") Or (ch >= "a" And ch <= "z") Then isAlnum = -1
        If isAlnum <> 0 Then
            tokenBuf &= ch
        Else
            If Len(tokenBuf) > 0 Then
                Dim tFirst2 As String = Mid(tokenBuf, 1, 1)
                If tFirst2 >= "0" And tFirst2 <= "9" Then
                    If Mamute_ParseAsmNumber(tokenBuf, dummyVal) = 0 Then Return 0
                End If
                tokenBuf = ""
            End If
        End If
    Next i

    Return -1
End Function

' Parser de uma linha completa "NN Label: instrucao operando ;comentario"
' pro formato interno (MamuteAsmLine). So' validacao SINTATICA (numero de
' linha, rotulo, instrucao reconhecida, formato dos numeros no operando) -
' nao valida modo de enderecamento nem resolve labels (fica pro futuro
' comando de montagem). Retorna 0 (linha rejeitada) em qualquer desvio da
' gramatica.
Private Function Mamute_ParseAsmLine(ByRef rawTextIn As String, ByRef outLine As MamuteAsmLine) As Integer
    Dim asmText As String = rawTextIn ' sem Trim aqui - o NN precisa comecar na coluna 1

    Dim i As Integer = 1
    Dim lenText As Integer = Len(asmText)
    While i <= lenText And Mid(asmText, i, 1) >= "0" And Mid(asmText, i, 1) <= "9"
        i += 1
    Wend
    If i = 1 Then Return 0

    Dim lineNumTok As String = Left(asmText, i - 1)
    If Len(lineNumTok) > 5 Then Return 0
    Dim lineNumVal As Integer = ValInt(lineNumTok)
    If lineNumVal > 65529 Then Return 0
    If i > lenText Or Mid(asmText, i, 1) <> " " Then Return 0

    Dim bodyText As String = Trim(Mid(asmText, i + 1))
    If Len(bodyText) = 0 Then Return 0

    Dim inQuote2 As Integer = 0
    Dim commentPos As Integer = 0
    Dim bodyLen As Integer = Len(bodyText)
    For i = 1 To bodyLen
        Dim scanCh As String = Mid(bodyText, i, 1)
        If scanCh = "'" Then
            inQuote2 = IIf(inQuote2 = 0, -1, 0)
        ElseIf scanCh = ";" And inQuote2 = 0 Then
            commentPos = i
            Exit For
        End If
    Next i

    Dim commentText As String = ""
    Dim mainPart As String = bodyText
    If commentPos > 0 Then
        commentText = Trim(Mid(bodyText, commentPos + 1))
        mainPart = Trim(Left(bodyText, commentPos - 1))
    End If
    If Len(mainPart) = 0 Then Return 0

    Dim spacePosA As Integer = InStr(mainPart, " ")
    Dim firstTok As String
    Dim restAfterFirst As String
    If spacePosA > 0 Then
        firstTok = Left(mainPart, spacePosA - 1)
        restAfterFirst = LTrim(Mid(mainPart, spacePosA + 1))
    Else
        firstTok = mainPart
        restAfterFirst = ""
    End If

    Dim labelTextV As String = ""
    Dim instrSection As String
    If Right(firstTok, 1) = ":" Then
        labelTextV = Left(firstTok, Len(firstTok) - 1)
        If Mamute_IsValidAsmLabel(labelTextV) = 0 Then Return 0
        instrSection = restAfterFirst
    Else
        instrSection = mainPart
    End If
    If Len(instrSection) = 0 Then Return 0

    Dim spacePosB As Integer = InStr(instrSection, " ")
    Dim instrTok As String
    Dim operandTok As String
    If spacePosB > 0 Then
        instrTok = Left(instrSection, spacePosB - 1)
        operandTok = Trim(Mid(instrSection, spacePosB + 1))
    Else
        instrTok = instrSection
        operandTok = ""
    End If

    Dim instrUpper As String = UCase(instrTok)
    If Mamute_IsAsmMnemonic(instrUpper) = 0 And Mamute_IsAsmPseudoOp(instrUpper) = 0 Then Return 0
    If instrUpper = "EQU" And Len(labelTextV) = 0 Then Return 0
    If Len(operandTok) = 0 And (instrUpper = "ORG" Or instrUpper = "DEFB" Or instrUpper = "DEFW" Or instrUpper = "DEFM" Or instrUpper = "DEFS" Or instrUpper = "EQU") Then Return 0

    If instrUpper = "DEFM" Then
        If Left(operandTok, 1) <> "'" Then Return 0
    Else
        If Mamute_ValidateAsmOperandNumbers(operandTok) = 0 Then Return 0
    End If

    outLine.lineNum = lineNumVal
    outLine.rawText = bodyText
    outLine.labelText = labelTextV
    outLine.instr = instrUpper
    outLine.operand = operandTok
    outLine.comment = commentText
    Return -1
End Function

' Guarda/substitui uma linha em MamuteAsmProgram(), mantendo sempre ordenado
' por lineNum (digitar de novo o mesmo NN substitui a linha, mesma edicao
' "como se fosse BASIC" do manual original).
Private Sub Mamute_AsmStoreLine(ByRef newLine As MamuteAsmLine)
    Dim i As Integer
    For i = 1 To MamuteAsmProgramCount
        If MamuteAsmProgram(i).lineNum = newLine.lineNum Then
            MamuteAsmProgram(i) = newLine
            Exit Sub
        ElseIf MamuteAsmProgram(i).lineNum > newLine.lineNum Then
            If MamuteAsmProgramCount < MAMUTE_ASM_MAX_LINES Then
                Dim j As Integer
                For j = MamuteAsmProgramCount + 1 To i + 1 Step -1
                    MamuteAsmProgram(j) = MamuteAsmProgram(j - 1)
                Next j
                MamuteAsmProgram(i) = newLine
                MamuteAsmProgramCount += 1
            End If
            Exit Sub
        End If
    Next i
    If MamuteAsmProgramCount < MAMUTE_ASM_MAX_LINES Then
        MamuteAsmProgramCount += 1
        MamuteAsmProgram(MamuteAsmProgramCount) = newLine
    End If
End Sub

Private Sub Mamute_AsmNew()
    MamuteAsmProgramCount = 0
End Sub

Private Function MamuteEditIndexOfLine(ByVal lineNumVal As Integer) As Integer
    Dim i As Integer
    For i = 1 To MamuteAsmProgramCount
        If MamuteAsmProgram(i).lineNum = lineNumVal Then Return i
    Next i
    Return 0
End Function

' DELETE <lininic>[-[<linfin>]] - apaga uma linha, um intervalo inclusive, ou
' (<lininic>- sem <linfin>) da linha ate o fim do programa. Devolve quantas
' linhas foram apagadas; -1 = erro de sintaxe.
Private Function Mamute_AsmDelete(ByRef argsText As String) As Integer
    Dim dashPos As Integer = InStr(argsText, "-")
    Dim startTok As String
    Dim endTok As String
    Dim hasEnd As Integer = 0
    Dim endLine As Integer

    If dashPos > 0 Then
        startTok = Trim(Left(argsText, dashPos - 1))
        endTok = Trim(Mid(argsText, dashPos + 1))
        If Len(endTok) > 0 Then
            If Mamute_IsDecimalString(endTok) = 0 Then Return -1
            hasEnd = -1
            endLine = ValInt(endTok)
        End If
    Else
        startTok = Trim(argsText)
    End If

    If Mamute_IsDecimalString(startTok) = 0 Then Return -1
    Dim startLine As Integer = ValInt(startTok)

    If dashPos = 0 Then
        endLine = startLine
    ElseIf hasEnd = 0 Then
        endLine = 65529
    End If
    If endLine < startLine Then Return -1

    Dim deletedCount As Integer = 0
    Dim i As Integer = 1
    While i <= MamuteAsmProgramCount
        If MamuteAsmProgram(i).lineNum >= startLine And MamuteAsmProgram(i).lineNum <= endLine Then
            Dim j As Integer
            For j = i To MamuteAsmProgramCount - 1
                MamuteAsmProgram(j) = MamuteAsmProgram(j + 1)
            Next j
            MamuteAsmProgramCount -= 1
            deletedCount += 1
        Else
            i += 1
        End If
    Wend
    Return deletedCount
End Function

' RENUM [<novali>[,<antigali>[,<incr>]]] - renumera a partir da linha ANTIGA
' <antigali> em diante pra uma nova sequencia comecando em <novali> com passo
' <incr> (sem nenhum parametro: tudo, comecando em 10, passo 10). Rejeita a
' operacao INTEIRA (nada e' alterado) se a nova numeracao colidir com uma
' linha nao renumerada ou passar do teto 65529.
Private Function Mamute_AsmRenum(ByRef argsText As String) As Integer
    Dim novaLi As Integer = 10
    Dim antigaLi As Integer = -1
    Dim incrVal As Integer = 10

    Dim trimmedArgs As String = Trim(argsText)
    If Len(trimmedArgs) > 0 Then
        Dim fields() As String
        Dim fieldCount As Integer
        Mamute_SplitArgs(trimmedArgs, fields(), fieldCount, 3)
        If fieldCount >= 1 And Len(Trim(fields(0))) > 0 Then
            If Mamute_IsDecimalString(Trim(fields(0))) = 0 Then Return 0
            novaLi = ValInt(Trim(fields(0)))
        End If
        If fieldCount >= 2 And Len(Trim(fields(1))) > 0 Then
            If Mamute_IsDecimalString(Trim(fields(1))) = 0 Then Return 0
            antigaLi = ValInt(Trim(fields(1)))
        End If
        If fieldCount >= 3 And Len(Trim(fields(2))) > 0 Then
            If Mamute_IsDecimalString(Trim(fields(2))) = 0 Then Return 0
            incrVal = ValInt(Trim(fields(2)))
            If incrVal <= 0 Then Return 0
        End If
    End If

    If MamuteAsmProgramCount = 0 Then Return -1

    If antigaLi = -1 Then antigaLi = MamuteAsmProgram(1).lineNum

    Dim newLinesCount As Integer = 0
    Dim i As Integer
    For i = 1 To MamuteAsmProgramCount
        If MamuteAsmProgram(i).lineNum >= antigaLi Then newLinesCount += 1
    Next i
    If newLinesCount = 0 Then Return -1

    Dim lastNew As Integer = novaLi + (newLinesCount - 1) * incrVal
    If novaLi < 0 Or lastNew > 65529 Then Return 0

    For i = 1 To MamuteAsmProgramCount
        If MamuteAsmProgram(i).lineNum < antigaLi And MamuteAsmProgram(i).lineNum >= novaLi Then Return 0
    Next i

    Dim nextNum As Integer = novaLi
    For i = 1 To MamuteAsmProgramCount
        If MamuteAsmProgram(i).lineNum >= antigaLi Then
            MamuteAsmProgram(i).lineNum = nextNum
            nextNum += incrVal
        End If
    Next i
    Return -1
End Function

Private Function Mamute_ReplaceAll(ByRef sourceText As String, ByRef findText As String, ByRef replaceText As String) As String
    If Len(findText) = 0 Then Return sourceText
    Dim resultText As String = ""
    Dim remaining As String = sourceText
    Do
        Dim foundPos As Integer = InStr(remaining, findText)
        If foundPos = 0 Then
            resultText &= remaining
            Exit Do
        End If
        resultText &= Left(remaining, foundPos - 1) & replaceText
        remaining = Mid(remaining, foundPos + Len(findText))
    Loop
    Return resultText
End Function

' CHANGE '<string1>'[,'<string2>'] - troca todas as ocorrencias de string1
' por string2 (ou apaga string1, se string2 for omitido) no CORPO de cada
' linha. Cada linha alterada e' RE-VALIDADA via Mamute_ParseAsmLine() antes
' de aplicar - se a troca quebrar a gramatica, essa linha fica como estava.
Private Function Mamute_AsmChange(ByRef string1 As String, ByRef string2 As String) As Integer
    If Len(string1) = 0 Then Return -1

    Dim changedCount As Integer = 0
    Dim i As Integer
    Dim reparsed As MamuteAsmLine
    For i = 1 To MamuteAsmProgramCount
        If InStr(MamuteAsmProgram(i).rawText, string1) > 0 Then
            Dim newBody As String = Mamute_ReplaceAll(MamuteAsmProgram(i).rawText, string1, string2)
            Dim fullLine As String = Trim(Str(MamuteAsmProgram(i).lineNum)) & " " & newBody
            If Mamute_ParseAsmLine(fullLine, reparsed) <> 0 Then
                MamuteAsmProgram(i) = reparsed
                changedCount += 1
            End If
        End If
    Next i
    Return changedCount
End Function

' Sintaxe adaptada pro idioma ja usado por SH/MS: CHANGE '<string1>'[,'<string2>']
' (o manual original mostra sem virgula: CHANGE '<string1>'<string2>).
Private Function MamuteEditParseChangeArgs(ByRef argsText As String, ByRef outStr1 As String, ByRef outStr2 As String) As Integer
    Dim trimmedArgs As String = Trim(argsText)
    If Left(trimmedArgs, 1) <> "'" Then Return 0
    Dim close1 As Integer = InStr(2, trimmedArgs, "'")
    If close1 = 0 Then Return 0
    outStr1 = Mid(trimmedArgs, 2, close1 - 2)
    outStr2 = ""

    Dim restText As String = Trim(Mid(trimmedArgs, close1 + 1))
    If Len(restText) > 0 Then
        If Left(restText, 1) <> "," Then Return 0
        Dim afterComma As String = Trim(Mid(restText, 2))
        If Left(afterComma, 1) = "'" Then
            Dim close2 As Integer = InStr(2, afterComma, "'")
            If close2 > 0 Then
                outStr2 = Mid(afterComma, 2, close2 - 2)
            Else
                outStr2 = Mid(afterComma, 2)
            End If
        End If
    End If
    Return -1
End Function

' Motor comum de SEARCH/LSEARCH/FIND: '<string>' entre aspas = busca
' LITERAL case-sensitive; sem aspas = busca LIVRE case-insensitive - ambas
' no CORPO cru (rawText) de cada linha. Preenche MamuteAsmSearchMatches().
' Retorna a quantidade de ocorrencias; -1 = erro de sintaxe (termo vazio).
Private Function Mamute_AsmSearch(ByRef argsText As String) As Integer
    MamuteAsmSearchCount = 0
    Dim trimmedArgs As String = Trim(argsText)
    If Len(trimmedArgs) = 0 Then Return -1

    Dim needle As String
    Dim caseSensitive As Integer
    If Left(trimmedArgs, 1) = "'" Then
        Dim closePos As Integer = InStr(2, trimmedArgs, "'")
        If closePos > 0 Then
            needle = Mid(trimmedArgs, 2, closePos - 2)
        Else
            needle = Mid(trimmedArgs, 2)
        End If
        caseSensitive = -1
    Else
        needle = trimmedArgs
        caseSensitive = 0
    End If
    If Len(needle) = 0 Then Return -1

    Dim needleCmp As String = needle
    If caseSensitive = 0 Then needleCmp = UCase(needle)

    Dim i As Integer
    For i = 1 To MamuteAsmProgramCount
        Dim hay As String = MamuteAsmProgram(i).rawText
        If caseSensitive = 0 Then hay = UCase(hay)
        If InStr(hay, needleCmp) > 0 Then
            If MamuteAsmSearchCount < MAMUTE_ASM_MAX_LINES Then
                MamuteAsmSearchCount += 1
                MamuteAsmSearchMatches(MamuteAsmSearchCount) = i
            End If
        End If
    Next i
    Return MamuteAsmSearchCount
End Function

' SAVE - grava o programa-fonte inteiro em ASCII puro (uma linha "NN corpo"
' por linha - o MESMO texto que, digitado de volta no EDIT, reproduz a linha
' via Mamute_ParseAsmLine, round-trip garantido). Formato PROPRIO desta
' porta (extensao .mza), NAO o formato binario proprietario do MegaAssembler
' original. Devolve mensagem de status ("" = cancelado).
Private Function Mamute_AsmSave() As String
    Dim canceled As Integer
    Dim filePath As String = PromptPathDialog("SAVE - Programa-fonte (EDIT)", "Nome do arquivo (.mza):", "programa.mza", canceled)
    If canceled <> 0 Or Len(Trim(filePath)) = 0 Then Return ""
    If InStr(filePath, ".") = 0 Then filePath &= ".mza"

    Dim ff As Integer = FreeFile
    Dim errCode As Integer = Open(filePath For Output As #ff)
    If errCode <> 0 Then Return "?ERRO AO GRAVAR ARQUIVO"
    Dim i As Integer
    For i = 1 To MamuteAsmProgramCount
        Print #ff, Trim(Str(MamuteAsmProgram(i).lineNum)) & " " & MamuteAsmProgram(i).rawText
    Next i
    Close #ff
    Return "GRAVADO: " & filePath
End Function

' Motor comum de LOAD/MERGE - le um arquivo no mesmo formato ASCII de
' Mamute_AsmSave(), cada linha passando pelo MESMO Mamute_ParseAsmLine() da
' digitacao ao vivo, depois Mamute_AsmStoreLine() (que ja' SUBSTITUI
' automaticamente qualquer linha existente com o MESMO NN) - e' exatamente a
' regra "em caso de colisao de numero, a linha lida do arquivo prevalece" do
' MERGE. Linhas invalidas no arquivo sao ignoradas silenciosamente.
' clearFirst<>0 (LOAD) apaga o programa em memoria ANTES de ler; 0 (MERGE)
' funde de verdade. Devolve quantas linhas foram lidas; -1 = cancelado/erro.
Private Function Mamute_AsmLoadOrMerge(ByRef titleText As String, ByVal clearFirst As Integer) As Integer
    Dim canceled As Integer
    Dim filePath As String = PromptPathDialog(titleText, "Nome do arquivo (.mza):", "programa.mza", canceled)
    If canceled <> 0 Or Len(Trim(filePath)) = 0 Then Return -1
    If Dir(filePath) = "" Then Return -1

    Dim ff As Integer = FreeFile
    Dim errCode As Integer = Open(filePath For Input As #ff)
    If errCode <> 0 Then Return -1

    If clearFirst <> 0 Then Mamute_AsmNew()

    Dim loadedCount As Integer = 0
    Dim lineText As String
    Dim parsedLine As MamuteAsmLine
    While Not Eof(ff)
        Line Input #ff, lineText
        If Len(Trim(lineText)) > 0 Then
            If Mamute_ParseAsmLine(lineText, parsedLine) <> 0 Then
                Mamute_AsmStoreLine(parsedLine)
                loadedCount += 1
            End If
        End If
    Wend
    Close #ff
    Return loadedCount
End Function

Private Function Mamute_AsmLoad() As Integer
    Return Mamute_AsmLoadOrMerge("LOAD - Programa-fonte (EDIT)", -1)
End Function

Private Function Mamute_AsmMerge() As Integer
    Return Mamute_AsmLoadOrMerge("MERGE - Programa-fonte (EDIT)", 0)
End Function

' ---------------------------------------------------------------------------
' Comando A do EDIT: monta o programa-fonte de verdade via Z80_Assemble()
' (motor Z80 acima) - opcoes O/N/P/I/R/S/D/H + /<offset>, mesmo vocabulario
' do comando A do MegaAssembler original/paleobasic. Diferencas desta versao:
' "P"/"H" gravam um arquivo .txt em vez de PDF (msxIDE nao tem gerador de
' PDF - mesma adaptacao ja usada por LP/LSEARCH); sem o eco cosmetico
' PASSO-1/PASSO-2 (so' fazia sentido numa janela GUI com WindowEvent() pra
' "bombear" durante a pausa - o msxIDE nao tem esse loop).
' ---------------------------------------------------------------------------

Type MamuteAsmResult
    okFlag As Integer
    errorLine As Integer
    errorText As String
    byteCount As Integer
    startAddr As Integer
    endAddr As Integer
End Type

Dim Shared MamuteAsmHasResult As Integer
Dim Shared MamuteAsmLastByteCount As Integer
Dim Shared MamuteAsmLastStartAddr As Integer
Dim Shared MamuteAsmLastEndAddr As Integer

Dim Shared MamuteAsmListingLines(1 To Z80_MAX_LISTING_ROWS) As String
Dim Shared MamuteAsmListingLineCount As Integer
Dim Shared MamuteAsmXrefLines(1 To Z80_MAX_SYMBOLS) As String
Dim Shared MamuteAsmXrefLineCount As Integer
Dim Shared MamuteAsmLabelListLines(1 To Z80_MAX_SYMBOLS) As String
Dim Shared MamuteAsmLabelListLineCount As Integer
Dim Shared MamuteAsmLabelOrderLines(1 To Z80_MAX_SYMBOLS) As String
Dim Shared MamuteAsmLabelOrderLineCount As Integer

' Buffer de 64KB reaproveitado por Mamute_AsmAssemble() - Shared, mesmo
' motivo/mesmo achado do Z80AssembleMem() no motor acima (evitar empilhar
' varios buffers de 64KB na mesma cadeia de chamadas e estourar a pilha).
Dim Shared MamuteAsmOutBytesBuf(0 To 65535) As Integer

' Devolve o NN (numero de linha do Mamute) correspondente a' LinhaFonte
' (1-based - mesma numeracao que Z80_GetAssembleErrorLine() devolve). Como o
' texto-fonte pra Z80_Assemble() e' montado juntando MamuteAsmProgram() em
' ordem, 1 linha de texto por elemento, a linha K do fonte e' SEMPRE o
' K-esimo elemento do array. -1 se fora da faixa.
Private Function Mamute_AsmLineNumberAtSourceLine(ByVal sourceLine As Integer) As Integer
    If sourceLine < 1 Or sourceLine > MamuteAsmProgramCount Then Return -1
    Return MamuteAsmProgram(sourceLine).lineNum
End Function

' Se Token comeca com digito e NAO tem sufixo H/B/D reconhecido no final,
' acrescenta "H" - o EDIT aceita numeros SEM sufixo como HEXADECIMAL por
' padrao (mesma convencao do resto do Mamute), mas o motor Z80 (TokenizeExpr,
' acima) segue a convencao classica M80/Nestor80: numero sem sufixo e'
' DECIMAL. "0A2" digitado no EDIT significa hexa 162 - sem esta traducao, o
' motor tentaria ler "0A2" como decimal (tem letra, nao bate) e rejeitaria.
' Sufixos que JA existem (H/B/D) tem o MESMO significado nos dois sistemas,
' ficam intocados.
Private Function Mamute_MaybeAddHexSuffix(ByRef token As String) As String
    If Len(token) = 0 Then Return token
    Dim firstCh As String = Mid(token, 1, 1)
    If firstCh < "0" Or firstCh > "9" Then Return token
    Dim lastCh As String = UCase(Right(token, 1))
    If lastCh = "H" Or lastCh = "B" Or lastCh = "D" Then Return token
    Return token & "H"
End Function

Private Function Mamute_TranslateOperandForZ80Asm(ByRef operandText As String) As String
    Dim resultText As String = ""
    Dim inQuote As Integer = 0
    Dim lenText As Integer = Len(operandText)
    Dim i As Integer
    Dim tokenBuf As String = ""

    For i = 1 To lenText + 1
        Dim ch As String
        If i <= lenText Then ch = Mid(operandText, i, 1) Else ch = " "

        If inQuote <> 0 Then
            resultText &= ch
            If ch = "'" Then inQuote = 0
            Continue For
        End If

        If ch = "'" Then
            If Len(tokenBuf) > 0 Then
                resultText &= Mamute_MaybeAddHexSuffix(tokenBuf)
                tokenBuf = ""
            End If
            inQuote = -1
            resultText &= ch
            Continue For
        End If

        Dim isAlnum As Integer = 0
        If (ch >= "0" And ch <= "9") Or (ch >= "A" And ch <= "Z") Or (ch >= "a" And ch <= "z") Then isAlnum = -1
        If isAlnum <> 0 Then
            tokenBuf &= ch
        Else
            If Len(tokenBuf) > 0 Then
                resultText &= Mamute_MaybeAddHexSuffix(tokenBuf)
                tokenBuf = ""
            End If
            If i <= lenText Then resultText &= ch
        End If
    Next i

    Return resultText
End Function

Private Function Mamute_Hex4Local(ByVal v As Integer) As String
    Return Hex(v And &HFFFF, 4)
End Function

' Formata Z80_GetListingRow() (ja' preenchida pela ultima Z80_Assemble() bem-
' sucedida) em texto pronto pra desenhar/gravar: "NN  ENDR  XX XX XX XX
' conteudo" - NN/ENDR em branco numa linha de CONTINUACAO (mais de 4 bytes na
' mesma linha-fonte). hideLineNumbers (opcao N do comando A) so' deixa a
' coluna NN em branco, o resto continua igual.
Private Sub Mamute_AsmBuildListingLines(ByVal hideLineNumbers As Integer)
    MamuteAsmListingLineCount = 0
    Dim rowCount As Integer = Z80_GetListingRowCount()
    Dim i As Integer, b As Integer
    Dim row As Z80ListingRow
    Dim lineText As String, hexPart As String, contentText As String, numPart As String

    For i = 0 To rowCount - 1
        Z80_GetListingRow(i, row)

        contentText = ""
        If row.hasAddr <> 0 And row.sourceLine >= 1 And row.sourceLine <= MamuteAsmProgramCount Then
            contentText = MamuteAsmProgram(row.sourceLine).rawText
            If hideLineNumbers <> 0 Then
                numPart = Space(5)
            Else
                numPart = Right(Space(5) & Trim(Str(MamuteAsmProgram(row.sourceLine).lineNum)), 5)
            End If
            lineText = numPart & "  " & Mamute_Hex4Local(row.rowAddr) & "  "
        Else
            lineText = Space(5) & "  " & Space(4) & "  "
        End If

        hexPart = ""
        For b = 0 To row.byteCount - 1
            Select Case b
                Case 0 : hexPart &= Hex(row.byte0, 2) & " "
                Case 1 : hexPart &= Hex(row.byte1, 2) & " "
                Case 2 : hexPart &= Hex(row.byte2, 2) & " "
                Case 3 : hexPart &= Hex(row.byte3, 2) & " "
            End Select
        Next b
        lineText &= Left(hexPart & Space(12), 12) & " " & contentText

        If MamuteAsmListingLineCount < Z80_MAX_LISTING_ROWS Then
            MamuteAsmListingLineCount += 1
            MamuteAsmListingLines(MamuteAsmListingLineCount) = lineText
        End If
    Next i
End Sub

' Formata Z80_GetXrefRow() (ja' preenchida pela ultima Z80_Assemble() bem-
' sucedida): "NOME  VALOR  ENDR ENDR..." - NOME/VALOR em branco numa linha de
' CONTINUACAO (simbolo com mais de 4 usos).
Private Sub Mamute_AsmBuildXrefLines()
    MamuteAsmXrefLineCount = 0
    Dim rowCount As Integer = Z80_GetXrefRowCount()
    Dim i As Integer, a As Integer
    Dim row As Z80XrefRow
    Dim lineText As String, addrPart As String

    For i = 0 To rowCount - 1
        Z80_GetXrefRow(i, row)
        If row.hasValue <> 0 Then
            lineText = Left(row.symName & Space(8), 8) & "  " & Mamute_Hex4Local(row.rowValue) & "  "
        Else
            lineText = Space(8) & "  " & Space(4) & "  "
        End If

        addrPart = ""
        For a = 0 To row.addrCount - 1
            Select Case a
                Case 0 : addrPart &= Mamute_Hex4Local(row.addr0) & " "
                Case 1 : addrPart &= Mamute_Hex4Local(row.addr1) & " "
                Case 2 : addrPart &= Mamute_Hex4Local(row.addr2) & " "
                Case 3 : addrPart &= Mamute_Hex4Local(row.addr3) & " "
            End Select
        Next a
        lineText &= Trim(addrPart)

        If MamuteAsmXrefLineCount < Z80_MAX_SYMBOLS Then
            MamuteAsmXrefLineCount += 1
            MamuteAsmXrefLines(MamuteAsmXrefLineCount) = lineText
        End If
    Next i
End Sub

' "NOME  VALOR" simples, ordem ALFABETICA (opcao S do comando A) - mesma
' tabela de Z80_GetXrefRow() (ja' alfabetica), so' aproveita as linhas com
' hasValue (pula as de continuacao, cujos enderecos de uso nao interessam
' aqui).
Private Sub Mamute_AsmBuildLabelListLines()
    MamuteAsmLabelListLineCount = 0
    Dim rowCount As Integer = Z80_GetXrefRowCount()
    Dim i As Integer
    Dim row As Z80XrefRow

    For i = 0 To rowCount - 1
        Z80_GetXrefRow(i, row)
        If row.hasValue <> 0 Then
            If MamuteAsmLabelListLineCount < Z80_MAX_SYMBOLS Then
                MamuteAsmLabelListLineCount += 1
                MamuteAsmLabelListLines(MamuteAsmLabelListLineCount) = Left(row.symName & Space(8), 8) & "  " & Mamute_Hex4Local(row.rowValue)
            End If
        End If
    Next i
End Sub

' Mesmo layout "NOME  VALOR" acima, mas em ordem de DEFINICAO no fonte
' (opcao D do comando A) - Z80_GetLabelDefOrderCount()/Name() em vez da
' tabela xref alfabetica.
Private Sub Mamute_AsmBuildLabelOrderLines()
    MamuteAsmLabelOrderLineCount = 0
    Dim countN As Integer = Z80_GetLabelDefOrderCount()
    Dim i As Integer
    Dim symName As String

    For i = 0 To countN - 1
        symName = Z80_GetLabelDefOrderName(i)
        If MamuteAsmLabelOrderLineCount < Z80_MAX_SYMBOLS Then
            MamuteAsmLabelOrderLineCount += 1
            MamuteAsmLabelOrderLines(MamuteAsmLabelOrderLineCount) = Left(symName & Space(8), 8) & "  " & Mamute_Hex4Local(Z80_GetSymbolValue(symName))
        End If
    Next i
End Sub

' Monta MamuteAsmProgram() inteiro via Z80_Assemble() - so' valida/monta (sem
' gravar em lugar nenhum ainda; quem chama decide o que fazer com
' outBytes()/StartAddr/EndAddr em caso de sucesso - ver Case "A" no key
' handler do EDIT). Reconstroi cada linha a partir dos campos JA separados
' (Label/Instr/Operand, ja' validados por Mamute_ParseAsmLine na hora da
' digitacao) em vez de RawText direto, pra poder traduzir o Operando pro
' dialeto numerico do motor Z80 (Mamute_TranslateOperandForZ80Asm acima).
' offsetValue (opcao /<offset>): somado ao operando de toda linha ORG (entre
' parenteses, "0" na frente do literal garantindo que o motor nunca confunda
' com um label mesmo comecando com A-F) ANTES de reconstruir o texto-fonte -
' o resto da montagem (rotulos, saltos, listagem) segue automaticamente o
' ORG deslocado.
Private Sub Mamute_AsmAssemble(ByRef outResult As MamuteAsmResult, ByVal hideLineNumbers As Integer, ByVal offsetValue As Integer)
    outResult.okFlag = 0
    outResult.errorLine = 0
    outResult.errorText = ""
    outResult.byteCount = 0
    outResult.startAddr = 0
    outResult.endAddr = 0

    Dim sourceText As String = ""
    Dim lineOut As String
    Dim orgOperand As String
    Dim i As Integer
    For i = 1 To MamuteAsmProgramCount
        If Len(sourceText) > 0 Then sourceText &= Chr(10)
        lineOut = ""
        If Len(MamuteAsmProgram(i).labelText) > 0 Then lineOut = MamuteAsmProgram(i).labelText & ": "
        lineOut &= MamuteAsmProgram(i).instr
        If Len(MamuteAsmProgram(i).operand) > 0 Then
            orgOperand = Mamute_TranslateOperandForZ80Asm(MamuteAsmProgram(i).operand)
            If offsetValue <> 0 And MamuteAsmProgram(i).instr = "ORG" Then
                orgOperand = "(" & orgOperand & ")+0" & Hex(offsetValue And &HFFFF, 4) & "H"
            End If
            lineOut &= " " & orgOperand
        End If
        If Len(MamuteAsmProgram(i).comment) > 0 Then lineOut &= " ;" & MamuteAsmProgram(i).comment
        sourceText &= lineOut
    Next i

    Dim n As Integer = Z80_Assemble(sourceText, MamuteAsmOutBytesBuf())
    If n < 0 Then
        Dim srcLine As Integer = Z80_GetAssembleErrorLine()
        Dim mappedLine As Integer = Mamute_AsmLineNumberAtSourceLine(srcLine)
        If mappedLine >= 0 Then outResult.errorLine = mappedLine
        outResult.errorText = Z80_GetAssembleErrorText()
        Exit Sub
    End If

    outResult.okFlag = -1
    outResult.byteCount = n
    If n > 0 Then
        outResult.startAddr = Z80_GetAssembleStartAddr()
        outResult.endAddr = Z80_GetAssembleEndAddr()
    End If

    MamuteAsmHasResult = -1
    MamuteAsmLastByteCount = n
    MamuteAsmLastStartAddr = outResult.startAddr
    MamuteAsmLastEndAddr = outResult.endAddr
    Mamute_AsmBuildListingLines(hideLineNumbers)
    Mamute_AsmBuildXrefLines()
    Mamute_AsmBuildLabelListLines()
    Mamute_AsmBuildLabelOrderLines()
End Sub

' Preenche Text com espacos ate TargetCol - se ja passou de TargetCol,
' avanca pro proximo multiplo de 8 (mesma largura de "tab stop" de um tab
' literal, mesmo com fonte monoespacada).
Private Function MamuteEditPadToColumn(ByRef textIn As String, ByVal targetCol As Integer) As String
    Dim colNow As Integer = Len(textIn)
    Dim target As Integer = targetCol
    If colNow >= target Then target = ((colNow \ 8) + 1) * 8
    Return textIn & Space(target - colNow)
End Function

' Monta a linha formatada (Label/Instr/Operand/Comment) alinhada em colunas
' fixas - so' pra EXIBICAO na listagem/LSEARCH; rawText/labelText/instr/
' operand/comment continuam guardados exatamente como digitados.
Private Function MamuteEdit_FormatLine(ByRef lineData As MamuteAsmLine) As String
    Dim textOut As String = ""
    If Len(lineData.labelText) > 0 Then textOut = lineData.labelText & ":"
    textOut = MamuteEditPadToColumn(textOut, 8)
    textOut &= lineData.instr
    If Len(lineData.operand) > 0 Then textOut &= " " & lineData.operand
    If Len(lineData.comment) > 0 Then
        textOut = MamuteEditPadToColumn(textOut, 24)
        textOut &= ";" & lineData.comment
    End If
    Return textOut
End Function

' Quantas "linhas" existem na sequencia ATIVA agora - o programa inteiro, ou
' (FilterMode) so' os resultados do ultimo SEARCH.
Private Function MamuteEditActiveCount(ByVal docIndex As Integer) As Integer
    If mamuteEditListingMode(docIndex) <> 0 Then Return MamuteAsmListingLineCount
    If mamuteEditFilterMode(docIndex) <> 0 Then Return MamuteAsmSearchCount
    Return MamuteAsmProgramCount
End Function

' Indice (1-based) REAL dentro de MamuteAsmProgram() correspondente a
' Position dentro da sequencia ATIVA (ver MamuteEditActiveCount acima) - 0
' se Position estiver fora da faixa valida.
Private Function MamuteEditRealIndexAt(ByVal docIndex As Integer, ByVal position As Integer) As Integer
    If mamuteEditFilterMode(docIndex) <> 0 Then
        If position < 1 Or position > MamuteAsmSearchCount Then Return 0
        Return MamuteAsmSearchMatches(position)
    End If
    If position < 1 Or position > MamuteAsmProgramCount Then Return 0
    Return position
End Function

' Garante que CursorIndex esteja dentro da janela [TopIndex,
' TopIndex+VisibleLines-1] - se nao estiver (linha nova encheu a tela, ou a
' seta moveu o cursor pra fora), rola por METADE de uma tela na direcao
' certa, repetindo se precisar (pedido explicito do usuario, mesmo espirito
' do ZX-81).
Private Sub MamuteEditEnsureCursorVisible(ByVal docIndex As Integer)
    Dim total As Integer = MamuteEditActiveCount(docIndex)
    If total = 0 Then
        mamuteEditTopIndex(docIndex) = 1
        mamuteEditCursorIndex(docIndex) = 1
        Exit Sub
    End If
    If mamuteEditCursorIndex(docIndex) < 1 Then mamuteEditCursorIndex(docIndex) = 1
    If mamuteEditCursorIndex(docIndex) > total Then mamuteEditCursorIndex(docIndex) = total

    Dim visLines As Integer = GetClientTextHeight(docs(docIndex))
    Dim half As Integer = visLines \ 2
    If half < 1 Then half = 1

    While mamuteEditCursorIndex(docIndex) < mamuteEditTopIndex(docIndex)
        mamuteEditTopIndex(docIndex) -= half
        If mamuteEditTopIndex(docIndex) < 1 Then mamuteEditTopIndex(docIndex) = 1
    Wend
    While mamuteEditCursorIndex(docIndex) > mamuteEditTopIndex(docIndex) + visLines - 1
        mamuteEditTopIndex(docIndex) += half
    Wend
End Sub

Sub DrawMamuteEditView(ByVal docIndex As Integer)
    Dim ByRef d As Document = docs(docIndex)
    Dim clientW As Integer = GetClientTextWidth(d)
    Dim clientH As Integer = GetClientTextHeight(d)
    Dim topIdx As Integer = mamuteEditTopIndex(docIndex)
    Dim curIdx As Integer = mamuteEditCursorIndex(docIndex)

    Dim row As Integer
    Dim seqPos As Integer = topIdx
    For row = 0 To clientH - 1
        Dim rowY As Integer = d.winY + 1 + row
        Dim lineText As String = ""
        If mamuteEditListingMode(docIndex) <> 0 Then
            ' Listagem da ultima montagem (comando A) - so' leitura, sem
            ' cursor ">" (linhas de continuacao/xref/labels nao correspondem
            ' a nenhuma linha REAL de MamuteAsmProgram()).
            If seqPos >= 1 And seqPos <= MamuteAsmListingLineCount Then
                lineText = MamuteAsmListingLines(seqPos)
            End If
        Else
            Dim realIdx As Integer = MamuteEditRealIndexAt(docIndex, seqPos)
            If realIdx > 0 Then
                Dim marker As String = " "
                If seqPos = curIdx Then marker = ">"
                lineText = Right(Space(5) & Trim(Str(MamuteAsmProgram(realIdx).lineNum)), 5) & " " & marker & " " & MamuteEdit_FormatLine(MamuteAsmProgram(realIdx))
            End If
        End If
        Dim padded As String = Left(lineText & Space(clientW), clientW)
        Dim i As Integer
        For i = 1 To clientW
            ConsoleSetCell(d.winX + i, rowY, Asc(Mid(padded, i, 1)), 15, 0)
        Next i
        seqPos += 1
    Next row

    Dim statusRow As Integer = d.winY + 1 + clientH
    Dim statusPadded As String = Left(mamuteEditStatusText(docIndex) & Space(clientW), clientW)
    Dim si As Integer
    For si = 1 To clientW
        ConsoleSetCell(d.winX + si, statusRow, Asc(Mid(statusPadded, si, 1)), 14, 0)
    Next si

    Dim inputRow As Integer = statusRow + 1
    Dim inputLineText As String = "ASM> " & mamuteInputBuf(docIndex)
    Dim inputPadded As String = Left(inputLineText & Space(clientW), clientW)
    Dim ii As Integer
    For ii = 1 To clientW
        ConsoleSetCell(d.winX + ii, inputRow, Asc(Mid(inputPadded, ii, 1)), 10, 0)
    Next ii

    DrawScrollBars(docIndex)
End Sub

Private Sub HandleMamuteEditKey(ByRef d As Document, ByRef keyText As String, ByRef renderHint As Integer)
    renderHint = RENDER_CLIENT
    Dim docIndex As Integer = activeDoc

    If keyText = Chr(13) Then
        Dim typedText As String = Trim(mamuteInputBuf(docIndex))
        mamuteInputBuf(docIndex) = ""
        mamuteInputCursor(docIndex) = 0

        If mamuteEditPendingScroll(docIndex) <> 0 Then
            Dim answerUp As String = UCase(typedText)
            If answerUp = "S" Or answerUp = "Y" Then
                mamuteEditTopIndex(docIndex) += GetClientTextHeight(d)
                Dim totalS As Integer = MamuteEditActiveCount(docIndex)
                If mamuteEditTopIndex(docIndex) > totalS Then mamuteEditTopIndex(docIndex) = totalS
                If mamuteEditTopIndex(docIndex) < 1 Then mamuteEditTopIndex(docIndex) = 1
                mamuteEditCursorIndex(docIndex) = mamuteEditTopIndex(docIndex)
                If mamuteEditTopIndex(docIndex) + GetClientTextHeight(d) - 1 < totalS Then
                    mamuteEditStatusText(docIndex) = "Rolar mais uma tela? (S/N)"
                Else
                    mamuteEditPendingScroll(docIndex) = 0
                    mamuteEditStatusText(docIndex) = ""
                End If
            Else
                mamuteEditPendingScroll(docIndex) = 0
                mamuteEditStatusText(docIndex) = ""
            End If
            Exit Sub
        End If

        If Len(typedText) = 0 Then
            If mamuteEditListingMode(docIndex) = 0 Then
                Dim curReal As Integer = MamuteEditRealIndexAt(docIndex, mamuteEditCursorIndex(docIndex))
                If curReal > 0 Then
                    mamuteInputBuf(docIndex) = Trim(Str(MamuteAsmProgram(curReal).lineNum)) & " " & MamuteAsmProgram(curReal).rawText
                    mamuteInputCursor(docIndex) = Len(mamuteInputBuf(docIndex))
                End If
            End If
            Exit Sub
        End If

        Dim vSpacePos As Integer = InStr(typedText, " ")
        Dim vVerb As String
        Dim vArgs As String
        If vSpacePos > 0 Then
            vVerb = UCase(Left(typedText, vSpacePos - 1))
            vArgs = Trim(Mid(typedText, vSpacePos + 1))
        Else
            vVerb = UCase(typedText)
            vArgs = ""
        End If

        mamuteEditFilterMode(docIndex) = 0
        mamuteEditListingMode(docIndex) = 0

        Select Case vVerb
            Case "LIST"
                mamuteEditTopIndex(docIndex) = 1
                mamuteEditCursorIndex(docIndex) = 1
                If MamuteAsmProgramCount > GetClientTextHeight(d) Then
                    mamuteEditPendingScroll(docIndex) = -1
                    mamuteEditStatusText(docIndex) = "Rolar mais uma tela? (S/N)"
                Else
                    mamuteEditStatusText(docIndex) = ""
                End If

            Case "NEW"
                Mamute_AsmNew()
                mamuteEditTopIndex(docIndex) = 1
                mamuteEditCursorIndex(docIndex) = 1
                mamuteEditStatusText(docIndex) = "PROGRAMA APAGADO"

            Case "DELETE"
                Dim delCount As Integer = Mamute_AsmDelete(vArgs)
                If delCount < 0 Then
                    mamuteEditStatusText(docIndex) = "?ERRO DE SINTAXE"
                Else
                    MamuteEditEnsureCursorVisible(docIndex)
                    mamuteEditStatusText(docIndex) = Trim(Str(delCount)) & " LINHA(S) APAGADA(S)"
                End If

            Case "RENUM"
                If Mamute_AsmRenum(vArgs) <> 0 Then
                    MamuteEditEnsureCursorVisible(docIndex)
                    mamuteEditStatusText(docIndex) = "RENUMERADO"
                Else
                    mamuteEditStatusText(docIndex) = "?ERRO DE SINTAXE"
                End If

            Case "CHANGE"
                Dim ch1 As String
                Dim ch2 As String
                If MamuteEditParseChangeArgs(vArgs, ch1, ch2) <> 0 Then
                    Dim chCount As Integer = Mamute_AsmChange(ch1, ch2)
                    MamuteEditEnsureCursorVisible(docIndex)
                    mamuteEditStatusText(docIndex) = Trim(Str(chCount)) & " LINHA(S) ALTERADA(S)"
                Else
                    mamuteEditStatusText(docIndex) = "?ERRO DE SINTAXE"
                End If

            Case "SAVE"
                Dim saveMsg As String = Mamute_AsmSave()
                If Len(saveMsg) > 0 Then
                    mamuteEditStatusText(docIndex) = saveMsg
                Else
                    mamuteEditStatusText(docIndex) = "CANCELADO"
                End If

            Case "LOAD"
                Dim loadCount As Integer = Mamute_AsmLoad()
                If loadCount >= 0 Then
                    mamuteEditTopIndex(docIndex) = 1
                    mamuteEditCursorIndex(docIndex) = 1
                    mamuteEditStatusText(docIndex) = Trim(Str(loadCount)) & " LINHA(S) CARREGADA(S)"
                Else
                    mamuteEditStatusText(docIndex) = "CANCELADO"
                End If

            Case "MERGE"
                Dim mergeCount As Integer = Mamute_AsmMerge()
                If mergeCount >= 0 Then
                    mamuteEditTopIndex(docIndex) = 1
                    mamuteEditCursorIndex(docIndex) = 1
                    MamuteEditEnsureCursorVisible(docIndex)
                    mamuteEditStatusText(docIndex) = Trim(Str(mergeCount)) & " LINHA(S) MESCLADA(S)"
                Else
                    mamuteEditStatusText(docIndex) = "CANCELADO"
                End If

            Case "SEARCH", "FIND"
                Dim searchCount As Integer = Mamute_AsmSearch(vArgs)
                If searchCount < 0 Then
                    mamuteEditStatusText(docIndex) = "?ERRO DE SINTAXE"
                ElseIf searchCount = 0 Then
                    mamuteEditStatusText(docIndex) = "NENHUMA OCORRENCIA"
                Else
                    mamuteEditFilterMode(docIndex) = -1
                    mamuteEditTopIndex(docIndex) = 1
                    mamuteEditCursorIndex(docIndex) = 1
                    mamuteEditStatusText(docIndex) = Trim(Str(searchCount)) & " OCORRENCIA(S) - digite LIST pra voltar ao programa completo"
                End If

            Case "LSEARCH"
                Dim lsCount As Integer = Mamute_AsmSearch(vArgs)
                If lsCount < 0 Then
                    mamuteEditStatusText(docIndex) = "?ERRO DE SINTAXE"
                ElseIf lsCount = 0 Then
                    mamuteEditStatusText(docIndex) = "NENHUMA OCORRENCIA"
                Else
                    Dim lsCanceled As Integer
                    Dim lsPath As String = PromptPathDialog("LSEARCH - Salvar busca", "Arquivo .txt de saida:", "busca.txt", lsCanceled)
                    If lsCanceled <> 0 Or Len(lsPath) = 0 Then
                        mamuteEditStatusText(docIndex) = "CANCELADO"
                    Else
                        Dim lsFf As Integer = FreeFile
                        Open lsPath For Output As #lsFf
                        Print #lsFf, "LSEARCH " & Trim(vArgs)
                        Dim si2 As Integer
                        For si2 = 1 To MamuteAsmSearchCount
                            Dim realI As Integer = MamuteAsmSearchMatches(si2)
                            Print #lsFf, Right(Space(5) & Trim(Str(MamuteAsmProgram(realI).lineNum)), 5) & "   " & MamuteEdit_FormatLine(MamuteAsmProgram(realI))
                        Next si2
                        Close #lsFf
                        mamuteEditStatusText(docIndex) = "GRAVADO: " & lsPath
                    End If
                End If

            Case "QUIT"
                CloseDocument(docIndex)
                Exit Sub

            Case "A"
                Dim asmFlags As String = UCase(Trim(vArgs))
                Dim asmOffsetValue As Integer = 0
                Dim asmOffsetOk As Integer = -1
                Dim asmSlashPos As Integer = InStr(asmFlags, "/")
                Dim asmLetterPart As String = asmFlags
                If asmSlashPos > 0 Then
                    asmLetterPart = Left(asmFlags, asmSlashPos - 1)
                    Dim asmOffsetText As String = Mid(asmFlags, asmSlashPos + 1)
                    If Len(asmOffsetText) = 0 Or Mamute_ParseHexAddr(asmOffsetText, asmOffsetValue) = 0 Then
                        asmOffsetOk = 0
                    End If
                End If

                Dim asmHasO As Integer = 0, asmHasN As Integer = 0, asmHasP As Integer = 0, asmHasI As Integer = 0
                Dim asmHasR As Integer = 0, asmHasS As Integer = 0, asmHasD As Integer = 0, asmHasH As Integer = 0
                Dim asmFlagsOk As Integer = -1
                Dim fi As Integer
                For fi = 1 To Len(asmLetterPart)
                    Select Case Mid(asmLetterPart, fi, 1)
                        Case "O" : asmHasO = -1
                        Case "N" : asmHasN = -1
                        Case "P" : asmHasP = -1
                        Case "I" : asmHasI = -1
                        Case "R" : asmHasR = -1
                        Case "S" : asmHasS = -1
                        Case "D" : asmHasD = -1
                        Case "H" : asmHasH = -1
                        Case Else : asmFlagsOk = 0
                    End Select
                Next fi

                If asmFlagsOk = 0 Then
                    mamuteEditStatusText(docIndex) = "?OPCAO NAO IMPLEMENTADA (combine 'O'/'N'/'P'/'I'/'R'/'S'/'D'/'H', ex. 'A', 'A O', 'A ONPIRSDH')"
                ElseIf asmOffsetOk = 0 Then
                    mamuteEditStatusText(docIndex) = "?OFFSET INVALIDO (hexa, 0000-FFFF, ex. 'A O/8000')"
                ElseIf asmHasH <> 0 And asmHasS = 0 And asmHasD = 0 Then
                    mamuteEditStatusText(docIndex) = "?OPCAO H PRECISA DE 'S' OU 'D' JUNTO (ex. 'A SH', 'A DH')"
                Else
                    Dim asmRes As MamuteAsmResult
                    Mamute_AsmAssemble(asmRes, asmHasN, asmOffsetValue)

                    If asmRes.okFlag = 0 Then
                        If asmRes.errorLine > 0 Then
                            Dim errIdx As Integer = MamuteEditIndexOfLine(asmRes.errorLine)
                            If errIdx > 0 Then
                                mamuteEditCursorIndex(docIndex) = errIdx
                                MamuteEditEnsureCursorVisible(docIndex)
                            End If
                            mamuteEditStatusText(docIndex) = "ERRO NA LINHA " & Trim(Str(asmRes.errorLine)) & ": " & asmRes.errorText
                        Else
                            mamuteEditStatusText(docIndex) = "ERRO: " & asmRes.errorText
                        End If
                    ElseIf asmRes.byteCount = 0 Then
                        mamuteEditStatusText(docIndex) = "MONTADO SEM ERROS - NADA GERADO (so rotulos/EQU/diretivas)"
                    Else
                        If asmHasO <> 0 Then
                            Dim wByte As Integer
                            For wByte = 0 To asmRes.byteCount - 1
                                Mamute_WriteByte((asmRes.startAddr + wByte) And 65535, MamuteAsmOutBytesBuf(wByte))
                            Next wByte
                        End If

                        ' R/S/D - anexa ao final de MamuteAsmListingLines (com 1
                        ' linha em branco de separador) - vira parte da MESMA
                        ' listagem que aparece na tela (ListingMode) e que "P"
                        ' grava no arquivo abaixo.
                        If asmHasR <> 0 Then
                            If MamuteAsmListingLineCount < Z80_MAX_LISTING_ROWS Then
                                MamuteAsmListingLineCount += 1 : MamuteAsmListingLines(MamuteAsmListingLineCount) = ""
                            End If
                            Dim ri As Integer
                            For ri = 1 To MamuteAsmXrefLineCount
                                If MamuteAsmListingLineCount < Z80_MAX_LISTING_ROWS Then
                                    MamuteAsmListingLineCount += 1 : MamuteAsmListingLines(MamuteAsmListingLineCount) = MamuteAsmXrefLines(ri)
                                End If
                            Next ri
                        End If
                        If asmHasS <> 0 Then
                            If MamuteAsmListingLineCount < Z80_MAX_LISTING_ROWS Then
                                MamuteAsmListingLineCount += 1 : MamuteAsmListingLines(MamuteAsmListingLineCount) = ""
                            End If
                            Dim si2 As Integer
                            For si2 = 1 To MamuteAsmLabelListLineCount
                                If MamuteAsmListingLineCount < Z80_MAX_LISTING_ROWS Then
                                    MamuteAsmListingLineCount += 1 : MamuteAsmListingLines(MamuteAsmListingLineCount) = MamuteAsmLabelListLines(si2)
                                End If
                            Next si2
                        End If
                        If asmHasD <> 0 Then
                            If MamuteAsmListingLineCount < Z80_MAX_LISTING_ROWS Then
                                MamuteAsmListingLineCount += 1 : MamuteAsmListingLines(MamuteAsmListingLineCount) = ""
                            End If
                            Dim di As Integer
                            For di = 1 To MamuteAsmLabelOrderLineCount
                                If MamuteAsmListingLineCount < Z80_MAX_LISTING_ROWS Then
                                    MamuteAsmListingLineCount += 1 : MamuteAsmListingLines(MamuteAsmListingLineCount) = MamuteAsmLabelOrderLines(di)
                                End If
                            Next di
                        End If

                        Dim asmSuffix As String = ""
                        If asmHasP <> 0 Then
                            Dim pCanceled As Integer
                            Dim pPath As String = PromptPathDialog("A P - Salvar listagem", "Arquivo .txt de saida:", "montagem.txt", pCanceled)
                            If pCanceled = 0 And Len(pPath) > 0 Then
                                Dim pFf As Integer = FreeFile
                                Open pPath For Output As #pFf
                                Print #pFf, "MONTAGEM " & Hex(asmRes.startAddr, 4) & "-" & Hex(asmRes.endAddr, 4)
                                Dim pi As Integer
                                For pi = 1 To MamuteAsmListingLineCount
                                    Print #pFf, MamuteAsmListingLines(pi)
                                Next pi
                                Close #pFf
                                asmSuffix &= " - LISTAGEM: " & pPath
                            End If
                        End If

                        If asmHasI <> 0 Then
                            Dim iCanceled As Integer
                            Dim iPath As String = PromptPathDialog("A I - Gravar codigo-objeto", "Arquivo de saida:", "montagem.bin", iCanceled)
                            If iCanceled = 0 And Len(iPath) > 0 Then
                                Dim iFf As Integer = FreeFile
                                Open iPath For Binary Access Write As #iFf
                                Dim iHdr(0 To 6) As UByte
                                iHdr(0) = &HFE
                                iHdr(1) = asmRes.startAddr And 255 : iHdr(2) = (asmRes.startAddr \ 256) And 255
                                iHdr(3) = asmRes.endAddr And 255 : iHdr(4) = (asmRes.endAddr \ 256) And 255
                                iHdr(5) = asmRes.startAddr And 255 : iHdr(6) = (asmRes.startAddr \ 256) And 255
                                Put #iFf, 1, iHdr()
                                Dim iBuf(0 To asmRes.byteCount - 1) As UByte
                                Dim ibi As Integer
                                For ibi = 0 To asmRes.byteCount - 1
                                    iBuf(ibi) = MamuteAsmOutBytesBuf(ibi) And 255
                                Next ibi
                                Put #iFf, 8, iBuf()
                                Close #iFf
                                asmSuffix &= " - GRAVADO: " & iPath
                            End If
                        End If

                        Dim asmHSuffix As String = ""
                        If asmHasH <> 0 Then
                            Dim hCanceled As Integer
                            Dim hPath As String = PromptPathDialog("A H - Salvar labels", "Arquivo .txt de saida:", "labels.txt", hCanceled)
                            If hCanceled = 0 And Len(hPath) > 0 Then
                                Dim hFf As Integer = FreeFile
                                Open hPath For Output As #hFf
                                Print #hFf, "LABELS " & Hex(asmRes.startAddr, 4) & "-" & Hex(asmRes.endAddr, 4)
                                Dim hi As Integer
                                If asmHasS <> 0 Then
                                    For hi = 1 To MamuteAsmLabelListLineCount
                                        Print #hFf, MamuteAsmLabelListLines(hi)
                                    Next hi
                                End If
                                If asmHasD <> 0 Then
                                    If asmHasS <> 0 Then Print #hFf, ""
                                    For hi = 1 To MamuteAsmLabelOrderLineCount
                                        Print #hFf, MamuteAsmLabelOrderLines(hi)
                                    Next hi
                                End If
                                Close #hFf
                                asmHSuffix = " - LABELS: " & hPath
                            End If
                        End If

                        mamuteEditListingMode(docIndex) = -1
                        mamuteEditTopIndex(docIndex) = 1
                        mamuteEditCursorIndex(docIndex) = 1

                        If MamuteAsmListingLineCount > GetClientTextHeight(d) Then
                            mamuteEditPendingScroll(docIndex) = -1
                            mamuteEditStatusText(docIndex) = "Rolar mais uma tela? (S/N)" & asmSuffix & asmHSuffix
                        ElseIf asmHasO <> 0 Then
                            mamuteEditStatusText(docIndex) = "MONTADO E GRAVADO NA RAM " & Hex(asmRes.startAddr, 4) & "-" & Hex(asmRes.endAddr, 4) & " (" & Trim(Str(asmRes.byteCount)) & " BYTES)" & asmSuffix & asmHSuffix
                        Else
                            mamuteEditStatusText(docIndex) = "MONTADO SEM ERROS " & Hex(asmRes.startAddr, 4) & "-" & Hex(asmRes.endAddr, 4) & " (" & Trim(Str(asmRes.byteCount)) & " BYTES)" & asmSuffix & asmHSuffix
                        End If
                    End If
                End If

            Case "MAP"
                If MamuteAsmHasResult = 0 Then
                    mamuteEditStatusText(docIndex) = "PROGRAMA AINDA NAO MONTADO - USE A (OU A O) PRIMEIRO"
                ElseIf MamuteAsmLastByteCount = 0 Then
                    mamuteEditStatusText(docIndex) = "ULTIMA MONTAGEM NAO GEROU CODIGO (SO ROTULOS/EQU/DIRETIVAS)"
                Else
                    mamuteEditStatusText(docIndex) = "ENDERECO INICIAL: " & Hex(MamuteAsmLastStartAddr, 4) & "  ENDERECO FINAL: " & Hex(MamuteAsmLastEndAddr, 4)
                End If

            Case Else
                Dim newLine As MamuteAsmLine
                If Mamute_ParseAsmLine(typedText, newLine) <> 0 Then
                    Mamute_AsmStoreLine(newLine)
                    Dim newIdx As Integer = MamuteEditIndexOfLine(newLine.lineNum)
                    If newIdx > 0 Then mamuteEditCursorIndex(docIndex) = newIdx
                    MamuteEditEnsureCursorVisible(docIndex)
                    mamuteEditStatusText(docIndex) = ""
                Else
                    mamuteEditStatusText(docIndex) = "?ERRO DE SINTAXE"
                End If
        End Select
        Exit Sub
    End If

    If keyText = Chr(27) Then
        mamuteInputBuf(docIndex) = ""
        mamuteInputCursor(docIndex) = 0
        mamuteEditPendingScroll(docIndex) = 0
        mamuteEditStatusText(docIndex) = ""
        Exit Sub
    End If

    If keyText = Chr(8) Then
        Dim caretPos As Integer = mamuteInputCursor(docIndex)
        If caretPos > 0 Then
            Dim txt As String = mamuteInputBuf(docIndex)
            mamuteInputBuf(docIndex) = Left(txt, caretPos - 1) & Mid(txt, caretPos + 1)
            mamuteInputCursor(docIndex) = caretPos - 1
        End If
        Exit Sub
    End If

    If Len(keyText) = 1 Then
        Dim c As Integer = Asc(keyText)
        If c >= 32 And c <= 126 Then
            Dim caretPos2 As Integer = mamuteInputCursor(docIndex)
            Dim txt2 As String = mamuteInputBuf(docIndex)
            mamuteInputBuf(docIndex) = Left(txt2, caretPos2) & keyText & Mid(txt2, caretPos2 + 1)
            mamuteInputCursor(docIndex) = caretPos2 + 1
        End If
        Exit Sub
    End If

    If Len(keyText) = 2 And Asc(Left(keyText, 1)) = 0 Then
        Select Case Asc(Right(keyText, 1))
            Case 75 ' Left
                If mamuteInputCursor(docIndex) > 0 Then mamuteInputCursor(docIndex) -= 1
            Case 77 ' Right
                If mamuteInputCursor(docIndex) < Len(mamuteInputBuf(docIndex)) Then mamuteInputCursor(docIndex) += 1
            Case 71 ' Home
                mamuteInputCursor(docIndex) = 0
            Case 79 ' End
                mamuteInputCursor(docIndex) = Len(mamuteInputBuf(docIndex))
            Case 83 ' Delete
                Dim caretPos3 As Integer = mamuteInputCursor(docIndex)
                Dim txt3 As String = mamuteInputBuf(docIndex)
                If caretPos3 < Len(txt3) Then
                    mamuteInputBuf(docIndex) = Left(txt3, caretPos3) & Mid(txt3, caretPos3 + 2)
                End If
            Case 72 ' Up
                If mamuteEditPendingScroll(docIndex) = 0 Then
                    mamuteEditCursorIndex(docIndex) -= 1
                    If mamuteEditCursorIndex(docIndex) < 1 Then mamuteEditCursorIndex(docIndex) = 1
                    MamuteEditEnsureCursorVisible(docIndex)
                End If
            Case 80 ' Down
                If mamuteEditPendingScroll(docIndex) = 0 Then
                    Dim totalD As Integer = MamuteEditActiveCount(docIndex)
                    If mamuteEditCursorIndex(docIndex) < totalD Then mamuteEditCursorIndex(docIndex) += 1
                    MamuteEditEnsureCursorVisible(docIndex)
                End If
        End Select
    End If
End Sub

Sub EditorCreateMamuteEdit()
    Dim i As Integer
    For i = 1 To docCount
        If docs(i).isMamuteEdit <> 0 Then
            BringDocumentToFront(i)
            forceFullRedraw = 1
            renderMode = RENDER_FULL
            Exit Sub
        End If
    Next i

    If docCount >= MAX_DOCS Then Exit Sub

    docCount += 1
    activeDoc = docCount

    InitBlankDocument(docs(docCount), "Mamute Assembler - EDIT")
    LayoutNewDocumentWindow(docCount)
    docs(docCount).isMamuteEdit = -1

    mamuteInputBuf(docCount) = ""
    mamuteInputCursor(docCount) = 0
    mamuteEditTopIndex(docCount) = 1
    mamuteEditCursorIndex(docCount) = 1
    mamuteEditPendingScroll(docCount) = 0
    mamuteEditFilterMode(docCount) = 0
    mamuteEditListingMode(docCount) = 0
    mamuteEditStatusText(docCount) = ""

    forceFullRedraw = 1
    renderMode = RENDER_FULL
End Sub

' ---------------------------------------------------------------------------
' Implementacao dos comandos do monitor (alem de CLS/PAGE/BA/QUIT, ja
' existentes). Cada Mamute_Cmd_XXX recebe o texto de argumentos JA sem o
' verbo (e sem o espaco separador) e escreve o resultado no scrollback via
' AppendMamuteLine - ExecuteMamuteCommand so' despacha.
' ---------------------------------------------------------------------------

Private Function MamuteDisplayModeText(ByVal modeVal As Integer) As String
    Select Case modeVal
        Case 0 : Return "HEXA+ASCII, 4 BYTES/LINHA"
        Case 1 : Return "HEXA+ASCII, 16 BYTES/LINHA"
        Case 2 : Return "HEXA, 8 BYTES/LINHA + CHECKSUM (SOMA+ENDERECO)"
        Case 3 : Return "HEXA, 8 BYTES/LINHA + CHECKSUM (SO SOMA)"
    End Select
    Return "?"
End Function

' Grade de 128 bytes (16 linhas de 8) em hexa+ASCII, usada por DM/M/S.
Private Sub MamuteRenderDump(ByRef d As Document, ByVal baseAddr As Integer, ByVal offsetVal As Integer)
    AppendMamuteLine(d, "")
    Dim row As Integer
    For row = 0 To 15
        Dim lineAddr As Integer = (baseAddr + row * 8) And 65535
        Dim hexPart As String = ""
        Dim asciiPart As String = ""
        Dim c As Integer
        For c = 0 To 7
            Dim rb As Integer = Mamute_ReadByte((lineAddr + c) And 65535)
            hexPart &= Hex(rb, 2) & " "
            asciiPart &= Mamute_PrintableChar((rb + offsetVal) And 255)
        Next c
        AppendMamuteLine(d, Hex(lineAddr, 4) & ": " & hexPart & asciiPart)
    Next row
    AppendMamuteLine(d, "")
    AppendMamuteLine(d, "Endereco: " & Hex(baseAddr, 4) & "H")
    Dim offSign As String = "+"
    If offsetVal < 0 Then offSign = "-"
    AppendMamuteLine(d, "Desloc.: " & offSign & Hex(Abs(offsetVal), 2) & "H")
End Sub

' Despejo formatado (modo escolhido em C), usado por D/P/V.
Private Sub MamuteBuildDumpLines(ByRef d As Document, ByVal startAddr As Integer, ByVal endAddr As Integer)
    Dim bytesPerLine As Integer = 8
    If MamuteDisplayMode = 0 Then bytesPerLine = 4
    If MamuteDisplayMode = 1 Then bytesPerLine = 16

    Dim curAddr As Integer = startAddr
    Do While curAddr <= endAddr
        Dim lineAddr As Integer = curAddr
        Dim hexPart As String = ""
        Dim asciiPart As String = ""
        Dim checksum As Integer = 0
        Dim n As Integer = 0
        Do While n < bytesPerLine And curAddr <= endAddr
            Dim rb As Integer = Mamute_ReadByte(curAddr)
            hexPart &= Hex(rb, 2) & " "
            If MamuteDisplayMode = 0 Or MamuteDisplayMode = 1 Then asciiPart &= Mamute_PrintableChar(rb)
            checksum = (checksum + rb) And 255
            curAddr += 1
            n += 1
        Loop

        Dim lineText As String = Hex(lineAddr, 4) & ": " & hexPart
        If MamuteDisplayMode = 0 Or MamuteDisplayMode = 1 Then
            lineText &= " " & asciiPart
        ElseIf MamuteDisplayMode = 2 Then
            lineText &= Hex((checksum + (lineAddr And 255)) And 255, 2)
        ElseIf MamuteDisplayMode = 3 Then
            lineText &= Hex(checksum And 255, 2)
        End If
        AppendMamuteLine(d, lineText)
    Loop
End Sub

Private Sub MamuteCmd_DM(ByRef d As Document, ByRef argsText As String)
    Dim tokens() As String
    Dim tokCount As Integer
    Mamute_SplitArgs(argsText, tokens(), tokCount, 2)

    If tokCount < 1 Or Len(tokens(0)) = 0 Then
        AppendMamuteLine(d, "?ERRO DE SINTAXE")
        Exit Sub
    End If

    Dim baseAddr As Integer
    If Mamute_ParseHexAddr(tokens(0), baseAddr) = 0 Then
        AppendMamuteLine(d, "?ERRO DE SINTAXE")
        Exit Sub
    End If

    Dim offsetVal As Integer = 0
    If tokCount >= 2 And Len(tokens(1)) > 0 Then
        If Mamute_ParseHexOffset(tokens(1), offsetVal) = 0 Then
            AppendMamuteLine(d, "?ERRO DE SINTAXE")
            Exit Sub
        End If
    End If

    MamuteRenderDump(d, baseAddr, offsetVal)
    AppendMamuteLine(d, "(despejo somente-leitura nesta versao do msxIDE - use M " & Chr(60) & "endereco" & Chr(62) & " " & Chr(60) & "byte" & Chr(62) & " pra gravar um byte direto)")
End Sub

Private Sub MamuteCmd_ZAP(ByRef d As Document, ByRef argsText As String)
    Dim tokens() As String
    Dim tokCount As Integer
    Mamute_SplitArgs(argsText, tokens(), tokCount, 2)

    If tokCount < 1 Or Len(tokens(0)) = 0 Then
        AppendMamuteLine(d, "?ERRO DE SINTAXE")
        Exit Sub
    End If

    Dim sectorNum As Integer
    If Mamute_ParseHexAddr(tokens(0), sectorNum) = 0 Then
        AppendMamuteLine(d, "?ERRO DE SINTAXE")
        Exit Sub
    End If

    Dim offsetVal As Integer = 0
    If tokCount >= 2 And Len(tokens(1)) > 0 Then
        If Mamute_ParseHexOffset(tokens(1), offsetVal) = 0 Then
            AppendMamuteLine(d, "?ERRO DE SINTAXE")
            Exit Sub
        End If
    End If

    Dim canceled As Integer
    Dim dskPath As String = PromptPathDialog("ZAP - imagem de disco", "Arquivo .dsk:", "", canceled)
    If canceled <> 0 Or Len(dskPath) = 0 Then
        AppendMamuteLine(d, "CANCELADO")
        Exit Sub
    End If
    If Dir(dskPath) = "" Then
        AppendMamuteLine(d, "?ARQUIVO NAO ENCONTRADO: " & dskPath)
        Exit Sub
    End If

    Dim ff As Integer = FreeFile
    Open dskPath For Binary Access Read As #ff
    Dim fsize As LongInt = Lof(ff)
    Dim baseByteOff As LongInt = sectorNum * 512

    AppendMamuteLine(d, "")
    Dim row As Integer
    For row = 0 To 15
        Dim rowOff As LongInt = baseByteOff + row * 8
        Dim hexPart As String = ""
        Dim asciiPart As String = ""
        Dim c As Integer
        For c = 0 To 7
            Dim thisOff As LongInt = rowOff + c
            Dim rb As Integer = 0
            If thisOff < fsize Then
                Dim buf(0 To 0) As UByte
                Get #ff, thisOff + 1, buf()
                rb = buf(0)
            End If
            hexPart &= Hex(rb, 2) & " "
            asciiPart &= Mamute_PrintableChar((rb + offsetVal) And 255)
        Next c
        AppendMamuteLine(d, Hex(row * 8, 3) & ": " & hexPart & asciiPart)
    Next row
    Close #ff

    AppendMamuteLine(d, "")
    AppendMamuteLine(d, "Setor: " & Hex(sectorNum, 4) & "H")
    AppendMamuteLine(d, "Byte: " & Hex(baseByteOff, 8) & "H")
    AppendMamuteLine(d, "(despejo somente-leitura nesta versao do msxIDE - edicao/gravacao de setor fica pra uma fase futura)")
End Sub

Private Sub MamuteCmd_SCR(ByRef d As Document, ByRef argsText As String)
    Dim tokens() As String
    Dim tokCount As Integer
    Mamute_SplitArgs(argsText, tokens(), tokCount, 4)

    If tokCount < 3 Or Len(tokens(0)) = 0 Or Len(tokens(1)) = 0 Or Len(tokens(2)) = 0 Then
        AppendMamuteLine(d, "?ERRO DE SINTAXE")
        Exit Sub
    End If

    Dim baseAddr As Integer
    If Mamute_ParseHexAddr(tokens(0), baseAddr) = 0 Then
        AppendMamuteLine(d, "?ERRO DE SINTAXE")
        Exit Sub
    End If
    If Mamute_IsHexString(tokens(1), 2) = 0 Then
        AppendMamuteLine(d, "?ERRO DE SINTAXE")
        Exit Sub
    End If
    Dim dxVal As Integer = ValInt("&H" & tokens(1))
    If Mamute_IsHexString(tokens(2), 2) = 0 Then
        AppendMamuteLine(d, "?ERRO DE SINTAXE")
        Exit Sub
    End If
    Dim dyVal As Integer = ValInt("&H" & tokens(2))
    If dxVal < 1 Or dyVal < 1 Then
        AppendMamuteLine(d, "?ERRO DE SINTAXE")
        Exit Sub
    End If

    Dim modeVal As Integer = 0
    If tokCount >= 4 And Len(tokens(3)) > 0 Then
        If Mamute_IsHexString(tokens(3), 1) = 0 Then
            AppendMamuteLine(d, "?ERRO DE SINTAXE")
            Exit Sub
        End If
        modeVal = ValInt("&H" & tokens(3))
        If modeVal <> 0 And modeVal <> 1 Then
            AppendMamuteLine(d, "?ERRO DE SINTAXE")
            Exit Sub
        End If
    End If

    AppendMamuteLine(d, "")
    AppendMamuteLine(d, "(visualizacao reduzida nesta versao do msxIDE - 1 azulejo " & Trim(Str(dxVal)) & "x" & Trim(Str(dyVal)) & " caracteres em ASCII, nao a tela 256x192 completa)")
    AppendMamuteLine(d, "")

    Dim charRow As Integer
    Dim pixRow As Integer
    For charRow = 0 To dyVal - 1
        For pixRow = 0 To 7
            Dim lineText As String = ""
            Dim charCol As Integer
            For charCol = 0 To dxVal - 1
                Dim charIdx As Integer
                If modeVal = 0 Then
                    charIdx = charRow * dxVal + charCol
                Else
                    charIdx = charCol * dyVal + charRow
                End If
                Dim byteAddr As Integer = (baseAddr + charIdx * 8 + pixRow) And 65535
                Dim rowByte As Integer = Mamute_ReadByte(byteAddr)
                Dim bitIdx As Integer
                For bitIdx = 7 To 0 Step -1
                    If ((rowByte Shr bitIdx) And 1) <> 0 Then
                        lineText &= "#"
                    Else
                        lineText &= "."
                    End If
                Next bitIdx
            Next charCol
            AppendMamuteLine(d, lineText)
        Next pixRow
    Next charRow
End Sub

Private Sub MamuteCmd_SH(ByRef d As Document, ByRef argsText As String)
    Dim firstComma As Integer = InStr(argsText, ",")
    If firstComma = 0 Then
        AppendMamuteLine(d, "?ERRO DE SINTAXE")
        Exit Sub
    End If
    Dim addrToken As String = Trim(Left(argsText, firstComma - 1))
    Dim restText As String = Mid(argsText, firstComma + 1)

    Dim startAddr As Integer
    If Len(addrToken) > 0 Then
        If Mamute_ParseHexAddr(addrToken, startAddr) = 0 Then
            AppendMamuteLine(d, "?ERRO DE SINTAXE")
            Exit Sub
        End If
    Else
        If MamuteLastShValid = 0 Then
            AppendMamuteLine(d, "?ERRO DE SINTAXE")
            Exit Sub
        End If
        startAddr = (MamuteLastShAddr + 1) And 65535
    End If

    If Left(Trim(restText), 1) = "'" Then
        Dim textVal As String = Mid(Trim(restText), 2)
        If Len(textVal) < 2 Then
            AppendMamuteLine(d, "?ERRO DE SINTAXE")
            Exit Sub
        End If

        Dim tryAddr As Integer = startAddr
        Dim count As Integer = 0
        Dim found As Integer = 0
        Dim foundAddr As Integer = 0
        Dim foundOffset As Integer = 0
        Do While count < 65536
            Dim firstByte As Integer = Mamute_ReadByte(tryAddr)
            Dim firstChar As Integer = Asc(Left(textVal, 1))
            Dim rawOffset As Integer = firstChar - firstByte
            rawOffset = ((rawOffset Mod 256) + 256) Mod 256
            If rawOffset > 127 Then rawOffset -= 256
            If rawOffset >= -127 And rawOffset <= 128 Then
                Dim allMatch As Integer = -1
                Dim k As Integer
                For k = 1 To Len(textVal)
                    Dim chAddr As Integer = (tryAddr + k - 1) And 65535
                    Dim chByte As Integer = Mamute_ReadByte(chAddr)
                    Dim expectChar As Integer = Asc(Mid(textVal, k, 1))
                    If ((chByte + rawOffset) And 255) <> expectChar Then
                        allMatch = 0
                        Exit For
                    End If
                Next k
                If allMatch <> 0 Then
                    found = -1
                    foundAddr = tryAddr
                    foundOffset = rawOffset
                    Exit Do
                End If
            End If
            tryAddr = (tryAddr + 1) And 65535
            count += 1
        Loop

        If found <> 0 Then
            MamuteLastShAddr = foundAddr
            MamuteLastShValid = -1
            Dim signTxt As String = "+"
            If foundOffset < 0 Then signTxt = "-"
            AppendMamuteLine(d, "ACHADO EM " & Hex(foundAddr, 4) & "H DESLOC " & signTxt & Hex(Abs(foundOffset), 2) & "H")
        Else
            AppendMamuteLine(d, "NAO ENCONTRADO")
        End If
        Exit Sub
    End If

    Dim byteTokens() As String
    Dim byteCount As Integer
    Mamute_SplitArgs(restText, byteTokens(), byteCount, 32)
    If byteCount < 1 Or Len(Trim(restText)) = 0 Then
        AppendMamuteLine(d, "?ERRO DE SINTAXE")
        Exit Sub
    End If

    Dim wildMask(0 To byteCount - 1) As Integer
    Dim wantByte(0 To byteCount - 1) As Integer
    Dim bi As Integer
    For bi = 0 To byteCount - 1
        If Len(byteTokens(bi)) = 0 Then
            wildMask(bi) = -1
        Else
            Dim bv As Integer
            If Mamute_ParseHexByte(byteTokens(bi), bv) = 0 Then
                AppendMamuteLine(d, "?ERRO DE SINTAXE")
                Exit Sub
            End If
            wildMask(bi) = 0
            wantByte(bi) = bv
        End If
    Next bi

    Dim tryAddr2 As Integer = startAddr
    Dim count2 As Integer = 0
    Dim found2 As Integer = 0
    Dim foundAddr2 As Integer = 0
    Do While count2 < 65536
        Dim allMatch2 As Integer = -1
        Dim k2 As Integer
        For k2 = 0 To byteCount - 1
            If wildMask(k2) = 0 Then
                Dim cAddr As Integer = (tryAddr2 + k2) And 65535
                If Mamute_ReadByte(cAddr) <> wantByte(k2) Then
                    allMatch2 = 0
                    Exit For
                End If
            End If
        Next k2
        If allMatch2 <> 0 Then
            found2 = -1
            foundAddr2 = tryAddr2
            Exit Do
        End If
        tryAddr2 = (tryAddr2 + 1) And 65535
        count2 += 1
    Loop

    If found2 <> 0 Then
        MamuteLastShAddr = foundAddr2
        MamuteLastShValid = -1
        AppendMamuteLine(d, "ACHADO EM " & Hex(foundAddr2, 4) & "H")
    Else
        AppendMamuteLine(d, "NAO ENCONTRADO")
    End If
End Sub

Private Sub MamuteCmd_MS(ByRef d As Document, ByRef argsText As String)
    Dim firstComma As Integer = InStr(argsText, ",")
    If firstComma = 0 Then
        AppendMamuteLine(d, "?ERRO DE SINTAXE")
        Exit Sub
    End If
    Dim addrToken As String = Trim(Left(argsText, firstComma - 1))
    Dim restArgs As String = Mid(argsText, firstComma + 1)

    Dim baseAddr As Integer
    If Mamute_ParseHexAddr(addrToken, baseAddr) = 0 Then
        AppendMamuteLine(d, "?ERRO DE SINTAXE")
        Exit Sub
    End If

    Dim offsetVal As Integer = 0
    Dim textVal As String
    Dim trimRest As String = Trim(restArgs)
    If Left(trimRest, 1) = "'" Then
        textVal = Mid(trimRest, 2)
    Else
        Dim secondComma As Integer = InStr(restArgs, ",")
        If secondComma = 0 Then
            AppendMamuteLine(d, "?ERRO DE SINTAXE")
            Exit Sub
        End If
        Dim offToken As String = Trim(Left(restArgs, secondComma - 1))
        If Len(offToken) > 0 Then
            If Mamute_ParseHexOffset(offToken, offsetVal) = 0 Then
                AppendMamuteLine(d, "?ERRO DE SINTAXE")
                Exit Sub
            End If
        End If
        Dim afterOff As String = Trim(Mid(restArgs, secondComma + 1))
        If Left(afterOff, 1) <> "'" Then
            AppendMamuteLine(d, "?ERRO DE SINTAXE")
            Exit Sub
        End If
        textVal = Mid(afterOff, 2)
    End If

    If Len(textVal) = 0 Then
        AppendMamuteLine(d, "?ERRO DE SINTAXE")
        Exit Sub
    End If

    Dim msWarn As String = Mamute_WriteWarnSuffix(baseAddr)
    Dim k As Integer
    For k = 1 To Len(textVal)
        Dim chAddr As Integer = (baseAddr + k - 1) And 65535
        Dim chVal As Integer = (Asc(Mid(textVal, k, 1)) - offsetVal) And 255
        Mamute_WriteByte(chAddr, chVal)
    Next k

    AppendMamuteLine(d, "GRAVADO EM " & Hex(baseAddr, 4) & "H" & msWarn)
End Sub

Private Sub MamuteCmd_LOAD(ByRef d As Document, ByRef argsText As String)
    Dim filterHint As String = Trim(argsText)
    Dim canceled As Integer
    Dim filePath As String = PromptPathDialog("LOAD", "Arquivo (.rom/.bin/outros):", filterHint, canceled)
    If canceled <> 0 Or Len(filePath) = 0 Then
        AppendMamuteLine(d, "CANCELADO")
        Exit Sub
    End If
    If Dir(filePath) = "" Then
        AppendMamuteLine(d, "?ARQUIVO NAO ENCONTRADO: " & filePath)
        Exit Sub
    End If

    Dim ext As String = LCase(Right(filePath, 4))
    If ext = ".cas" Then
        AppendMamuteLine(d, "?ARQUIVOS .CAS NAO SUPORTADOS AINDA")
        Exit Sub
    End If

    Dim ramSlot As Integer
    Dim ramSub As Integer
    Dim defaultSlot As Integer = 0
    If FindMamuteRamSlot(ramSlot, ramSub) <> 0 Then defaultSlot = ramSlot

    Dim slotCanceled As Integer
    Dim slotText As String = PromptPathDialog("LOAD - Slot", "Slot de destino (0-3):", Trim(Str(defaultSlot)), slotCanceled)
    If slotCanceled <> 0 Then
        AppendMamuteLine(d, "CANCELADO")
        Exit Sub
    End If
    Dim targetSlot As Integer = ValInt(Trim(slotText))
    If targetSlot < 0 Or targetSlot > 3 Then
        AppendMamuteLine(d, "?ARGUMENTO INVALIDO (slot deve ser 0-3)")
        Exit Sub
    End If

    Dim ff As Integer = FreeFile
    Open filePath For Binary Access Read As #ff
    Dim fsize As LongInt = Lof(ff)

    If ext = ".rom" Then
        If fsize > 32768 Then
            Close #ff
            AppendMamuteLine(d, "?ROM MAIOR QUE 32KB NAO SUPORTADA")
            Exit Sub
        End If
        Dim toRead As Integer = CInt(fsize)
        Dim page1Len As Integer = toRead
        If page1Len > 16384 Then page1Len = 16384
        Dim page2Len As Integer = toRead - 16384
        If page2Len < 0 Then page2Len = 0

        Dim i As Integer
        For i = 0 To 16383
            MamuteMem(targetSlot, 0, 1, i) = 0
            MamuteMem(targetSlot, 0, 2, i) = 0
        Next i

        If page1Len > 0 Then
            Dim buf1(0 To page1Len - 1) As UByte
            Get #ff, 1, buf1()
            For i = 0 To page1Len - 1
                MamuteMem(targetSlot, 0, 1, i) = buf1(i)
            Next i
        End If
        MamuteMemGrid(targetSlot, 0, 1).cellType = MAMUTE_CELL_ROM

        Dim finalEndAddr As Integer = &H7FFF
        If page2Len > 0 Then
            Dim buf2b(0 To page2Len - 1) As UByte
            Get #ff, 16385, buf2b()
            For i = 0 To page2Len - 1
                MamuteMem(targetSlot, 0, 2, i) = buf2b(i)
            Next i
            MamuteMemGrid(targetSlot, 0, 2).cellType = MAMUTE_CELL_ROM
            finalEndAddr = &HBFFF
        End If
        Close #ff

        AppendMamuteLine(d, "CARREGADO NO SLOT " & Trim(Str(targetSlot)) & " EM 4000H - TAMANHO " & Hex(toRead, 4) & "H - FIM " & Hex(finalEndAddr, 4) & "H")
        Exit Sub
    End If

    Dim hasHeader As Integer = 0
    Dim hdrStart As Integer = 0
    Dim hdrEnd As Integer = 0
    If fsize >= 7 Then
        Dim hb(0 To 6) As UByte
        Get #ff, 1, hb()
        If hb(0) = &HFE Then
            hasHeader = -1
            hdrStart = hb(1) + hb(2) * 256
            hdrEnd = hb(3) + hb(4) * 256
        End If
    End If

    Dim loadAddr As Integer
    Dim dataStart As LongInt
    Dim dataLen As LongInt

    If hasHeader <> 0 Then
        loadAddr = hdrStart
        dataStart = 7
        dataLen = fsize - 7
        If dataLen < 0 Then dataLen = 0
        Dim expectedLen As LongInt = ((hdrEnd - hdrStart) And 65535) + 1
        If expectedLen > 0 And expectedLen < dataLen Then dataLen = expectedLen
    Else
        Dim addrCanceled As Integer
        Dim addrText As String = PromptPathDialog("LOAD - Endereco inicial", "Endereco inicial (hexa):", "4000", addrCanceled)
        If addrCanceled <> 0 Then
            Close #ff
            AppendMamuteLine(d, "CANCELADO")
            Exit Sub
        End If
        If Mamute_ParseHexAddr(Trim(addrText), loadAddr) = 0 Then
            Close #ff
            AppendMamuteLine(d, "?ERRO DE SINTAXE")
            Exit Sub
        End If
        dataStart = 1
        dataLen = fsize
    End If

    Dim maxBytes As LongInt = dataLen
    If maxBytes > 65536 Then maxBytes = 65536
    Dim readLen As Integer = CInt(maxBytes)

    If readLen > 0 Then
        Dim dataBuf(0 To readLen - 1) As UByte
        Get #ff, dataStart + 1, dataBuf()
        Close #ff

        Dim writeAddr As Integer = loadAddr
        Dim wi As Integer
        For wi = 0 To readLen - 1
            Dim wpage As Integer = (writeAddr \ 16384) And 3
            Dim woff As Integer = writeAddr And 16383
            MamuteMem(targetSlot, 0, wpage, woff) = dataBuf(wi)
            MamuteMemGrid(targetSlot, 0, wpage).cellType = MAMUTE_CELL_RAM
            writeAddr = (writeAddr + 1) And 65535
        Next wi
    Else
        Close #ff
    End If

    Dim finalEndAddr2 As Integer = (loadAddr + readLen - 1) And 65535
    AppendMamuteLine(d, "CARREGADO NO SLOT " & Trim(Str(targetSlot)) & " EM " & Hex(loadAddr, 4) & "H - TAMANHO " & Hex(readLen, 4) & "H - FIM " & Hex(finalEndAddr2, 4) & "H")
End Sub

Private Sub MamuteCmd_SAVE(ByRef d As Document, ByRef argsText As String)
    Dim tokens() As String
    Dim tokCount As Integer
    Mamute_SplitArgs(argsText, tokens(), tokCount, 4)

    Dim nameHint As String = ""
    Dim prefStart As Integer = 0
    Dim prefEnd As Integer = 0
    Dim prefExec As Integer = 0
    Dim haveRange As Integer = 0

    If tokCount >= 1 And Len(tokens(0)) > 0 Then nameHint = tokens(0)
    If tokCount >= 3 And Len(tokens(1)) > 0 And Len(tokens(2)) > 0 Then
        If Mamute_ParseHexAddr(tokens(1), prefStart) <> 0 And Mamute_ParseHexAddr(tokens(2), prefEnd) <> 0 Then
            haveRange = -1
            prefExec = prefStart
            If tokCount >= 4 And Len(tokens(3)) > 0 Then
                Dim execTmp As Integer
                If Mamute_ParseHexAddr(tokens(3), execTmp) <> 0 Then prefExec = execTmp
            End If
        End If
    End If

    Dim canceled As Integer
    Dim filePath As String = PromptPathDialog("SAVE", "Arquivo de saida:", nameHint, canceled)
    If canceled <> 0 Or Len(filePath) = 0 Then
        AppendMamuteLine(d, "CANCELADO")
        Exit Sub
    End If

    Dim startAddr As Integer = prefStart
    Dim endAddr As Integer = prefEnd
    If haveRange = 0 Then
        Dim rangeCanceled As Integer
        Dim rangeText As String = PromptPathDialog("SAVE - Intervalo", "Endereco inicial,final (hexa):", "4000,7FFF", rangeCanceled)
        If rangeCanceled <> 0 Then
            AppendMamuteLine(d, "CANCELADO")
            Exit Sub
        End If
        Dim rTokens() As String
        Dim rCount As Integer
        Mamute_SplitArgs(Trim(rangeText), rTokens(), rCount, 2)
        If rCount < 2 Or Mamute_ParseHexAddr(rTokens(0), startAddr) = 0 Or Mamute_ParseHexAddr(rTokens(1), endAddr) = 0 Then
            AppendMamuteLine(d, "?ERRO DE SINTAXE")
            Exit Sub
        End If
        prefExec = startAddr
    End If

    If endAddr < startAddr Then
        AppendMamuteLine(d, "?ERRO DE SINTAXE")
        Exit Sub
    End If

    Dim startPage As Integer = (startAddr \ 16384) And 3
    Dim suggestSlot As Integer = MamuteActiveSlot(startPage)
    Dim slotCanceled As Integer
    Dim slotText As String = PromptPathDialog("SAVE - Slot", "Slot de origem (0-3):", Trim(Str(suggestSlot)), slotCanceled)
    If slotCanceled <> 0 Then
        AppendMamuteLine(d, "CANCELADO")
        Exit Sub
    End If
    Dim srcSlot As Integer = ValInt(Trim(slotText))
    If srcSlot < 0 Or srcSlot > 3 Then
        AppendMamuteLine(d, "?ARGUMENTO INVALIDO (slot deve ser 0-3)")
        Exit Sub
    End If

    Dim isRomFormat As Integer = 0
    If LCase(Right(filePath, 4)) = ".rom" Then isRomFormat = -1

    Dim ff As Integer = FreeFile
    Open filePath For Binary Access Write As #ff
    Dim hdr(0 To 6) As UByte
    hdr(0) = IIf(isRomFormat <> 0, &HAB, &HFE)
    hdr(1) = startAddr And 255 : hdr(2) = (startAddr \ 256) And 255
    hdr(3) = endAddr And 255 : hdr(4) = (endAddr \ 256) And 255
    hdr(5) = prefExec And 255 : hdr(6) = (prefExec \ 256) And 255
    Put #ff, 1, hdr()

    Dim total As Integer = (endAddr - startAddr) + 1
    Dim outBuf(0 To total - 1) As UByte
    Dim srcAddr As Integer = startAddr
    Dim oi As Integer
    For oi = 0 To total - 1
        Dim spage As Integer = (srcAddr \ 16384) And 3
        Dim soff As Integer = srcAddr And 16383
        outBuf(oi) = MamuteMem(srcSlot, 0, spage, soff)
        srcAddr = (srcAddr + 1) And 65535
    Next oi
    Put #ff, 8, outBuf()
    Close #ff

    AppendMamuteLine(d, "SALVO " & Chr(34) & filePath & Chr(34) & " - SLOT " & Trim(Str(srcSlot)) & " - " & Hex(startAddr, 4) & "H-" & Hex(endAddr, 4) & "H - TAMANHO " & Hex(total, 4) & "H")
End Sub

' ---------------------------------------------------------------------------
' Editor interativo de memoria do comando M: grade de 128 bytes (16 linhas x
' 8 colunas) ocupando o corpo inteiro do terminal, adaptado de MamuteM_Open
' (paleobasic, MamuteMGui.pbi) - la e' uma janela GUI clicavel com botoes,
' aqui e' o proprio documento do terminal trocando de modo (mesma ideia da
' linha de entrada reservada: GetClientTextHeight ja desconta 1 linha extra
' pra isMamuteTerm, que uso aqui como linha de status em vez do prompt MON>).
' Diferencas deliberadas do original, a pedido do usuario: nao ha estagio de
' "campo de texto ASCII" nem tabela de teclas configuravel (isso e' o "S", que
' continua so' leitura por enquanto); ENTER aqui avanca sem gravar (no
' original, ENTER sempre fechava a janela); e navegar/digitar alem da ultima
' celula da tela rola pra pagina de 128 bytes seguinte/anterior automatico,
' em vez de travar no canto como no original.
' ---------------------------------------------------------------------------

Private Function MamuteMEditCellAddr(ByVal docIndex As Integer, ByVal row As Integer, ByVal col As Integer) As Integer
    Return (mamuteMEditBaseAddr(docIndex) + row * 8 + col) And 65535
End Function

Sub MamuteMEditOpen(ByVal docIndex As Integer, ByVal startAddr As Integer)
    mamuteMEditActive(docIndex) = -1
    mamuteMEditBaseAddr(docIndex) = startAddr And 65535
    mamuteMEditCursorRow(docIndex) = 0
    mamuteMEditCursorCol(docIndex) = 0
    mamuteMEditNibbleStage(docIndex) = 0
    mamuteMEditPendingHigh(docIndex) = 0
End Sub

' Move o cursor por linha/coluna (setas). Passar da ultima celula da tela
' (linha 15 col 7) ou da primeira (linha 0 col 0) rola BaseAddr em blocos de
' 128 bytes, ao inves de travar no canto.
Private Sub MamuteMEditMove(ByVal docIndex As Integer, ByVal dRow As Integer, ByVal dCol As Integer)
    Dim newCol As Integer = mamuteMEditCursorCol(docIndex) + dCol
    Dim newRow As Integer = mamuteMEditCursorRow(docIndex) + dRow

    If newCol > 7 Then
        newCol = 0
        newRow += 1
    ElseIf newCol < 0 Then
        newCol = 7
        newRow -= 1
    End If

    If newRow > 15 Then
        newRow = 0
        mamuteMEditBaseAddr(docIndex) = (mamuteMEditBaseAddr(docIndex) + 128) And 65535
    ElseIf newRow < 0 Then
        newRow = 15
        mamuteMEditBaseAddr(docIndex) = (mamuteMEditBaseAddr(docIndex) - 128) And 65535
    End If

    mamuteMEditCursorRow(docIndex) = newRow
    mamuteMEditCursorCol(docIndex) = newCol
    mamuteMEditNibbleStage(docIndex) = 0
End Sub

Private Sub HandleMamuteMEditKey(ByRef d As Document, ByRef keyText As String, ByRef renderHint As Integer)
    renderHint = RENDER_CLIENT
    Dim docIndex As Integer = activeDoc

    If keyText = Chr(27) Then
        mamuteMEditActive(docIndex) = 0
        AppendMamuteLine(d, "M: EDICAO ENCERRADA EM " & Hex(mamuteMEditBaseAddr(docIndex), 4) & "H")
        MamuteLastMAddr = mamuteMEditBaseAddr(docIndex)
        MamuteLastMValid = -1
        Exit Sub
    End If

    If keyText = Chr(13) Then
        mamuteMEditNibbleStage(docIndex) = 0
        MamuteMEditMove(docIndex, 0, 1)
        Exit Sub
    End If

    If Len(keyText) = 1 Then
        Dim nibbleVal As Integer = -1
        Dim ch As String = UCase(keyText)
        If ch >= "0" And ch <= "9" Then nibbleVal = Asc(ch) - Asc("0")
        If ch >= "A" And ch <= "F" Then nibbleVal = Asc(ch) - Asc("A") + 10
        If nibbleVal >= 0 Then
            If mamuteMEditNibbleStage(docIndex) = 0 Then
                mamuteMEditPendingHigh(docIndex) = nibbleVal
                mamuteMEditNibbleStage(docIndex) = -1
            Else
                Dim cellAddr As Integer = MamuteMEditCellAddr(docIndex, mamuteMEditCursorRow(docIndex), mamuteMEditCursorCol(docIndex))
                Dim newByte As Integer = (mamuteMEditPendingHigh(docIndex) * 16) + nibbleVal
                Mamute_WriteByte(cellAddr, newByte)
                mamuteMEditNibbleStage(docIndex) = 0
                MamuteMEditMove(docIndex, 0, 1)
            End If
            Exit Sub
        End If
    End If

    If Len(keyText) = 2 And Asc(Left(keyText, 1)) = 0 Then
        Select Case Asc(Right(keyText, 1))
            Case 72 : MamuteMEditMove(docIndex, -1, 0) ' Up
            Case 80 : MamuteMEditMove(docIndex, 1, 0)  ' Down
            Case 75 : MamuteMEditMove(docIndex, 0, -1) ' Left
            Case 77 : MamuteMEditMove(docIndex, 0, 1)  ' Right
            Case 73 ' PgUp
                mamuteMEditBaseAddr(docIndex) = (mamuteMEditBaseAddr(docIndex) - 128) And 65535
                mamuteMEditNibbleStage(docIndex) = 0
            Case 81 ' PgDn
                mamuteMEditBaseAddr(docIndex) = (mamuteMEditBaseAddr(docIndex) + 128) And 65535
                mamuteMEditNibbleStage(docIndex) = 0
        End Select
    End If
End Sub

Sub DrawMamuteMEditGrid(ByVal docIndex As Integer)
    Dim ByRef d As Document = docs(docIndex)
    Dim clientW As Integer = GetClientTextWidth(d)
    Dim clientH As Integer = GetClientTextHeight(d)
    Dim curRow As Integer = mamuteMEditCursorRow(docIndex)
    Dim curCol As Integer = mamuteMEditCursorCol(docIndex)

    Dim row As Integer
    For row = 0 To 15
        If row >= clientH Then Continue For
        Dim rowY As Integer = d.winY + 1 + row
        Dim rowAddr As Integer = MamuteMEditCellAddr(docIndex, row, 0)

        Dim lineText As String = Hex(rowAddr, 4) & ": "
        Dim asciiText As String = ""
        Dim col As Integer
        For col = 0 To 7
            Dim rb As Integer = Mamute_ReadByte(MamuteMEditCellAddr(docIndex, row, col))
            Dim hexTxt As String
            If row = curRow And col = curCol And mamuteMEditNibbleStage(docIndex) <> 0 Then
                hexTxt = Mid("0123456789ABCDEF", mamuteMEditPendingHigh(docIndex) + 1, 1) & "_"
            Else
                hexTxt = Hex(rb, 2)
            End If
            lineText &= hexTxt & " "
            asciiText &= Mamute_PrintableChar(rb)
        Next col
        lineText &= " " & asciiText

        Dim padded As String = Left(lineText & Space(clientW), clientW)
        Dim hexStartCol As Integer = 7 + curCol * 3
        Dim i As Integer
        For i = 1 To clientW
            Dim cellFg As UByte = 15
            Dim cellBg As UByte = 0
            If row = curRow And (i = hexStartCol Or i = hexStartCol + 1) Then
                cellFg = 0 : cellBg = 7
            End If
            ConsoleSetCell(d.winX + i, rowY, Asc(Mid(padded, i, 1)), cellFg, cellBg)
        Next i
    Next row

    Dim statusRow As Integer = d.winY + 1 + clientH
    Dim statusText As String = "M " & Hex(mamuteMEditBaseAddr(docIndex), 4) & "H - Setas/PgUp/PgDn move  0-F edita  ENTER prox  ESC sai"
    Dim statusPadded As String = Left(statusText & Space(clientW), clientW)
    Dim si As Integer
    For si = 1 To clientW
        ConsoleSetCell(d.winX + si, statusRow, Asc(Mid(statusPadded, si, 1)), 10, 0)
    Next si

    DrawScrollBars(docIndex)
End Sub

Private Sub MamuteCmd_M(ByRef d As Document, ByRef argsText As String)
    Dim trimmed As String = Trim(argsText)
    If Len(trimmed) = 0 Then
        If MamuteLastMValid = 0 Then
            AppendMamuteLine(d, "?ERRO DE SINTAXE")
            Exit Sub
        End If
        MamuteMEditOpen(activeDoc, MamuteLastMAddr)
        Exit Sub
    End If

    Dim spacePos2 As Integer = InStr(trimmed, " ")
    If spacePos2 > 0 Then
        Dim addrTok As String = Trim(Left(trimmed, spacePos2 - 1))
        Dim byteTok As String = Trim(Mid(trimmed, spacePos2 + 1))
        Dim addrVal As Integer
        Dim byteVal As Integer
        If Mamute_ParseHexAddr(addrTok, addrVal) = 0 Or Mamute_ParseHexByte(byteTok, byteVal) = 0 Then
            AppendMamuteLine(d, "?ERRO DE SINTAXE")
            Exit Sub
        End If
        Dim mWarn As String = Mamute_WriteWarnSuffix(addrVal)
        Mamute_WriteByte(addrVal, byteVal)
        MamuteLastMAddr = addrVal
        MamuteLastMValid = -1
        AppendMamuteLine(d, "GRAVADO " & Hex(byteVal, 2) & "H EM " & Hex(addrVal, 4) & "H" & mWarn)
        Exit Sub
    End If

    Dim onlyAddr As Integer
    If Mamute_ParseHexAddr(trimmed, onlyAddr) = 0 Then
        AppendMamuteLine(d, "?ERRO DE SINTAXE")
        Exit Sub
    End If
    MamuteLastMAddr = onlyAddr
    MamuteLastMValid = -1
    MamuteMEditOpen(activeDoc, onlyAddr)
End Sub

Private Sub MamuteCmd_S(ByRef d As Document, ByRef argsText As String)
    Dim trimmed As String = Trim(argsText)
    If Len(trimmed) = 0 Then
        If MamuteLastSValid = 0 Then
            AppendMamuteLine(d, "?ERRO DE SINTAXE")
            Exit Sub
        End If
        MamuteRenderDump(d, MamuteLastSAddr, 0)
        AppendMamuteLine(d, "(S e' um alias de M nesta versao do msxIDE - o remapeamento de teclado numerico do original nao se aplica a um terminal de texto)")
        Exit Sub
    End If

    Dim spacePos2 As Integer = InStr(trimmed, " ")
    If spacePos2 > 0 Then
        Dim addrTok As String = Trim(Left(trimmed, spacePos2 - 1))
        Dim byteTok As String = Trim(Mid(trimmed, spacePos2 + 1))
        Dim addrVal As Integer
        Dim byteVal As Integer
        If Mamute_ParseHexAddr(addrTok, addrVal) = 0 Or Mamute_ParseHexByte(byteTok, byteVal) = 0 Then
            AppendMamuteLine(d, "?ERRO DE SINTAXE")
            Exit Sub
        End If
        Dim sWarn As String = Mamute_WriteWarnSuffix(addrVal)
        Mamute_WriteByte(addrVal, byteVal)
        MamuteLastSAddr = addrVal
        MamuteLastSValid = -1
        AppendMamuteLine(d, "GRAVADO " & Hex(byteVal, 2) & "H EM " & Hex(addrVal, 4) & "H" & sWarn)
        Exit Sub
    End If

    Dim onlyAddr As Integer
    If Mamute_ParseHexAddr(trimmed, onlyAddr) = 0 Then
        AppendMamuteLine(d, "?ERRO DE SINTAXE")
        Exit Sub
    End If
    MamuteLastSAddr = onlyAddr
    MamuteLastSValid = -1
    MamuteRenderDump(d, onlyAddr, 0)
    AppendMamuteLine(d, "(S e' um alias de M nesta versao do msxIDE - o remapeamento de teclado numerico do original nao se aplica a um terminal de texto)")
End Sub

Private Sub MamuteCmd_C(ByRef d As Document, ByRef argsText As String)
    Dim trimmed As String = Trim(argsText)
    If Mamute_IsHexString(trimmed, 1) = 0 Then
        AppendMamuteLine(d, "?ERRO DE SINTAXE")
        Exit Sub
    End If
    Dim modeVal As Integer = ValInt("&H" & trimmed)
    If modeVal < 0 Or modeVal > 3 Then
        AppendMamuteLine(d, "?ERRO DE SINTAXE")
        Exit Sub
    End If
    MamuteDisplayMode = modeVal
    AppendMamuteLine(d, "MODO " & Trim(Str(modeVal)) & ": " & MamuteDisplayModeText(modeVal))
End Sub

Private Sub MamuteCmd_D(ByRef d As Document, ByRef argsText As String)
    Dim tokens() As String
    Dim tokCount As Integer
    Mamute_SplitArgs(argsText, tokens(), tokCount, 2)
    If tokCount < 1 Or Len(tokens(0)) = 0 Then
        AppendMamuteLine(d, "?ERRO DE SINTAXE")
        Exit Sub
    End If
    Dim startAddr As Integer
    If Mamute_ParseHexAddr(tokens(0), startAddr) = 0 Then
        AppendMamuteLine(d, "?ERRO DE SINTAXE")
        Exit Sub
    End If
    Dim endAddr As Integer
    If tokCount >= 2 And Len(tokens(1)) > 0 Then
        If Mamute_ParseHexAddr(tokens(1), endAddr) = 0 Then
            AppendMamuteLine(d, "?ERRO DE SINTAXE")
            Exit Sub
        End If
        If endAddr < startAddr Then
            AppendMamuteLine(d, "?ERRO DE SINTAXE")
            Exit Sub
        End If
    Else
        endAddr = startAddr + 15
        If endAddr > 65535 Then endAddr = 65535
    End If
    MamuteBuildDumpLines(d, startAddr, endAddr)
End Sub

Private Sub MamuteCmd_P(ByRef d As Document, ByRef argsText As String)
    Dim tokens() As String
    Dim tokCount As Integer
    Mamute_SplitArgs(argsText, tokens(), tokCount, 2)
    If tokCount < 1 Or Len(tokens(0)) = 0 Then
        AppendMamuteLine(d, "?ERRO DE SINTAXE")
        Exit Sub
    End If
    Dim startAddr As Integer
    If Mamute_ParseHexAddr(tokens(0), startAddr) = 0 Then
        AppendMamuteLine(d, "?ERRO DE SINTAXE")
        Exit Sub
    End If
    Dim endAddr As Integer
    If tokCount >= 2 And Len(tokens(1)) > 0 Then
        If Mamute_ParseHexAddr(tokens(1), endAddr) = 0 Then
            AppendMamuteLine(d, "?ERRO DE SINTAXE")
            Exit Sub
        End If
        If endAddr < startAddr Then
            AppendMamuteLine(d, "?ERRO DE SINTAXE")
            Exit Sub
        End If
    Else
        endAddr = startAddr + 15
        If endAddr > 65535 Then endAddr = 65535
    End If

    Dim canceled As Integer
    Dim outPath As String = PromptPathDialog("P - Salvar listagem", "Arquivo .txt de saida:", "listagem.txt", canceled)
    If canceled <> 0 Or Len(outPath) = 0 Then
        AppendMamuteLine(d, "CANCELADO")
        Exit Sub
    End If

    Dim ff As Integer = FreeFile
    Open outPath For Output As #ff
    Print #ff, "P " & Hex(startAddr, 4) & "H-" & Hex(endAddr, 4) & "H MODO " & Trim(Str(MamuteDisplayMode))

    Dim tempDoc As Document
    tempDoc.lineCount = 1
    tempDoc.lines(1) = ""
    MamuteBuildDumpLines(tempDoc, startAddr, endAddr)
    Dim i As Integer
    For i = 2 To tempDoc.lineCount
        Print #ff, tempDoc.lines(i)
    Next i
    Close #ff

    AppendMamuteLine(d, "ARQUIVO GRAVADO: " & outPath)
End Sub

Private Sub MamuteCmd_V(ByRef d As Document, ByRef argsText As String)
    Dim tokens() As String
    Dim tokCount As Integer
    Mamute_SplitArgs(argsText, tokens(), tokCount, 2)
    If tokCount < 1 Or Len(tokens(0)) = 0 Then
        AppendMamuteLine(d, "?ERRO DE SINTAXE")
        Exit Sub
    End If
    Dim vramMax As Integer = MamuteVramKB * 1024 - 1

    Dim startAddr As Integer
    If Mamute_ParseHexAddr(tokens(0), startAddr, 5) = 0 Or startAddr > vramMax Then
        AppendMamuteLine(d, "?ERRO DE SINTAXE")
        Exit Sub
    End If
    Dim endAddr As Integer
    If tokCount >= 2 And Len(tokens(1)) > 0 Then
        If Mamute_ParseHexAddr(tokens(1), endAddr, 5) = 0 Or endAddr > vramMax Then
            AppendMamuteLine(d, "?ERRO DE SINTAXE")
            Exit Sub
        End If
        If endAddr < startAddr Then
            AppendMamuteLine(d, "?ERRO DE SINTAXE")
            Exit Sub
        End If
    Else
        endAddr = startAddr + 15
        If endAddr > vramMax Then endAddr = vramMax
    End If

    Dim canceled As Integer
    Dim outPath As String = PromptPathDialog("V - Salvar listagem VRAM", "Arquivo .txt de saida:", "vram.txt", canceled)
    If canceled <> 0 Or Len(outPath) = 0 Then
        AppendMamuteLine(d, "CANCELADO")
        Exit Sub
    End If

    Dim ff As Integer = FreeFile
    Open outPath For Output As #ff
    Print #ff, "V " & Hex(startAddr, 5) & "H-" & Hex(endAddr, 5) & "H MODO " & Trim(Str(MamuteDisplayMode))

    Dim bytesPerLine As Integer = 8
    If MamuteDisplayMode = 0 Then bytesPerLine = 4
    If MamuteDisplayMode = 1 Then bytesPerLine = 16

    Dim curAddr As Integer = startAddr
    Do While curAddr <= endAddr
        Dim lineAddr As Integer = curAddr
        Dim hexPart As String = ""
        Dim asciiPart As String = ""
        Dim checksum As Integer = 0
        Dim n As Integer = 0
        Do While n < bytesPerLine And curAddr <= endAddr
            Dim rb As Integer = MamuteVram(curAddr)
            hexPart &= Hex(rb, 2) & " "
            If MamuteDisplayMode = 0 Or MamuteDisplayMode = 1 Then asciiPart &= Mamute_PrintableChar(rb)
            checksum = (checksum + rb) And 255
            curAddr += 1
            n += 1
        Loop
        Dim lineText As String = Hex(lineAddr, 5) & ": " & hexPart
        If MamuteDisplayMode = 0 Or MamuteDisplayMode = 1 Then
            lineText &= " " & asciiPart
        ElseIf MamuteDisplayMode = 2 Then
            lineText &= Hex((checksum + (lineAddr And 255)) And 255, 2)
        ElseIf MamuteDisplayMode = 3 Then
            lineText &= Hex(checksum And 255, 2)
        End If
        Print #ff, lineText
    Loop
    Close #ff

    AppendMamuteLine(d, "ARQUIVO GRAVADO: " & outPath)
End Sub

Private Sub MamuteCmd_T(ByRef d As Document, ByRef argsText As String)
    Dim tokens() As String
    Dim tokCount As Integer
    Mamute_SplitArgs(argsText, tokens(), tokCount, 3)
    If tokCount < 3 Or Len(tokens(0)) = 0 Or Len(tokens(1)) = 0 Or Len(tokens(2)) = 0 Then
        AppendMamuteLine(d, "?ERRO DE SINTAXE")
        Exit Sub
    End If
    Dim startAddr As Integer
    Dim endAddr As Integer
    Dim destAddr As Integer
    If Mamute_ParseHexAddr(tokens(0), startAddr) = 0 Or Mamute_ParseHexAddr(tokens(1), endAddr) = 0 Or Mamute_ParseHexAddr(tokens(2), destAddr) = 0 Then
        AppendMamuteLine(d, "?ERRO DE SINTAXE")
        Exit Sub
    End If
    If endAddr < startAddr Then
        AppendMamuteLine(d, "?ERRO DE SINTAXE")
        Exit Sub
    End If
    Dim lengthVal As Integer = endAddr - startAddr + 1
    If destAddr + lengthVal - 1 > 65535 Then
        AppendMamuteLine(d, "?ERRO DE SINTAXE")
        Exit Sub
    End If

    Dim tWarn As String = ""
    If Mamute_CanWriteAt(destAddr) = 0 Or Mamute_CanWriteAt(destAddr + lengthVal - 1) = 0 Then
        tWarn = " (AVISO: destino tem pagina que nao e RAM agora - parte ou toda a copia sem efeito)"
    End If

    Dim i As Integer
    If destAddr > startAddr Then
        For i = lengthVal - 1 To 0 Step -1
            Mamute_WriteByte(destAddr + i, Mamute_ReadByte(startAddr + i))
        Next i
    Else
        For i = 0 To lengthVal - 1
            Mamute_WriteByte(destAddr + i, Mamute_ReadByte(startAddr + i))
        Next i
    End If

    AppendMamuteLine(d, "TRANSFERIDO " & Hex(startAddr, 4) & "H-" & Hex(endAddr, 4) & "H PARA " & Hex(destAddr, 4) & "H" & tWarn)
End Sub

Private Sub MamuteCmd_F(ByRef d As Document, ByRef argsText As String)
    Dim tokens() As String
    Dim tokCount As Integer
    Mamute_SplitArgs(argsText, tokens(), tokCount, 3)
    If tokCount < 3 Or Len(tokens(0)) = 0 Or Len(tokens(1)) = 0 Or Len(tokens(2)) = 0 Then
        AppendMamuteLine(d, "?ERRO DE SINTAXE")
        Exit Sub
    End If
    Dim startAddr As Integer
    Dim endAddr As Integer
    Dim fillByte As Integer
    If Mamute_ParseHexAddr(tokens(0), startAddr) = 0 Or Mamute_ParseHexAddr(tokens(1), endAddr) = 0 Or Mamute_ParseHexByte(tokens(2), fillByte) = 0 Then
        AppendMamuteLine(d, "?ERRO DE SINTAXE")
        Exit Sub
    End If
    If endAddr < startAddr Then
        AppendMamuteLine(d, "?ERRO DE SINTAXE")
        Exit Sub
    End If

    Dim fWarn As String = ""
    If Mamute_CanWriteAt(startAddr) = 0 Or Mamute_CanWriteAt(endAddr) = 0 Then
        fWarn = " (AVISO: intervalo tem pagina que nao e RAM agora - parte ou todo o preenchimento sem efeito)"
    End If

    Dim addr As Integer
    For addr = startAddr To endAddr
        Mamute_WriteByte(addr, fillByte)
    Next addr

    AppendMamuteLine(d, "PREENCHIDO " & Hex(startAddr, 4) & "H-" & Hex(endAddr, 4) & "H COM " & Hex(fillByte, 2) & "H" & fWarn)
End Sub

Private Sub MamuteCmd_G(ByRef d As Document, ByRef argsText As String)
    Dim tokens() As String
    Dim tokCount As Integer
    Mamute_SplitArgs(argsText, tokens(), tokCount, 3)
    If tokCount < 1 Or Len(tokens(0)) = 0 Then
        AppendMamuteLine(d, "?ERRO DE SINTAXE")
        Exit Sub
    End If
    Dim startAddr As Integer
    If Mamute_ParseHexAddr(tokens(0), startAddr) = 0 Then
        AppendMamuteLine(d, "?ERRO DE SINTAXE")
        Exit Sub
    End If
    Dim confirmText As String = "G " & Hex(startAddr, 4) & "H"
    If tokCount >= 2 And Len(tokens(1)) > 0 Then
        Dim brk1 As Integer
        If Mamute_ParseHexAddr(tokens(1), brk1) = 0 Then
            AppendMamuteLine(d, "?ERRO DE SINTAXE")
            Exit Sub
        End If
        confirmText &= "," & Hex(brk1, 4) & "H"
        If tokCount >= 3 And Len(tokens(2)) > 0 Then
            Dim brk2 As Integer
            If Mamute_ParseHexAddr(tokens(2), brk2) = 0 Then
                AppendMamuteLine(d, "?ERRO DE SINTAXE")
                Exit Sub
            End If
            confirmText &= "," & Hex(brk2, 4) & "H"
        End If
    End If
    AppendMamuteLine(d, confirmText)
    AppendMamuteLine(d, "(execucao de verdade ainda nao implementada nesta fase)")
End Sub

Private Sub MamuteCmd_X(ByRef d As Document, ByRef argsText As String)
    Dim trimmed As String = Trim(argsText)
    If Len(trimmed) = 0 Then
        AppendMamuteLine(d, "AF=" & Hex(MamuteRegAF, 4) & " BC=" & Hex(MamuteRegBC, 4) & " DE=" & Hex(MamuteRegDE, 4) & " HL=" & Hex(MamuteRegHL, 4))
        AppendMamuteLine(d, "IX=" & Hex(MamuteRegIX, 4) & " IY=" & Hex(MamuteRegIY, 4) & " SP=" & Hex(MamuteRegSP, 4))
        Exit Sub
    End If

    Dim regMode As Integer
    Dim regIdx As Integer
    MamuteXFindReg(trimmed, regMode, regIdx)
    If regMode = 0 Then
        AppendMamuteLine(d, "?ERRO DE SINTAXE")
        Exit Sub
    End If

    MamuteXWalking(activeDoc) = regMode
    MamuteXWalkIdx(activeDoc) = regIdx
End Sub

Private Sub Mamute_ContinueXWalk(ByRef d As Document, ByRef valueText As String)
    Dim mode As Integer = MamuteXWalking(activeDoc)
    Dim idx As Integer = MamuteXWalkIdx(activeDoc)
    Dim regNameW As String = MamuteXRegName(mode, idx)
    Dim digitsW As Integer = 4
    If mode = 2 Then digitsW = 2
    Dim trimmedVal As String = Trim(valueText)

    AppendMamuteLine(d, regNameW & "(" & Hex(MamuteXGetReg(regNameW), digitsW) & ")> " & valueText)

    If Len(trimmedVal) > 0 Then
        If Mamute_IsHexString(trimmedVal, digitsW) = 0 Then
            AppendMamuteLine(d, "?ERRO DE SINTAXE")
            MamuteXWalking(activeDoc) = 0
            MamuteXWalkIdx(activeDoc) = 0
            Exit Sub
        End If
        MamuteXSetReg(regNameW, ValInt("&H" & trimmedVal))
    End If

    Dim newIdx As Integer = idx + 1
    If newIdx >= MamuteXRegCount(mode) Then
        MamuteXWalking(activeDoc) = 0
        MamuteXWalkIdx(activeDoc) = 0
        AppendMamuteLine(d, "AF=" & Hex(MamuteRegAF, 4) & " BC=" & Hex(MamuteRegBC, 4) & " DE=" & Hex(MamuteRegDE, 4) & " HL=" & Hex(MamuteRegHL, 4))
        AppendMamuteLine(d, "IX=" & Hex(MamuteRegIX, 4) & " IY=" & Hex(MamuteRegIY, 4) & " SP=" & Hex(MamuteRegSP, 4))
    Else
        MamuteXWalkIdx(activeDoc) = newIdx
    End If
End Sub

Private Sub MamuteCmd_R(ByRef d As Document, ByRef argsText As String)
    AppendMamuteLine(d, "R - CARREGAMENTO DE PROGRAMA ASSEMBLADO AINDA NAO IMPLEMENTADO, FICA PRA UMA FASE FUTURA")
End Sub

Private Sub MamuteCmd_L(ByRef d As Document, ByRef argsText As String)
    Dim tokens() As String
    Dim tokCount As Integer
    Mamute_SplitArgs(argsText, tokens(), tokCount, 2)

    Dim startAddr As Integer
    Dim endAddr As Integer
    Dim haveEnd As Integer = 0

    If tokCount >= 1 And Len(tokens(0)) > 0 Then
        If Mamute_ParseHexAddr(tokens(0), startAddr) = 0 Then
            AppendMamuteLine(d, "?ERRO DE SINTAXE")
            Exit Sub
        End If
        If tokCount >= 2 And Len(tokens(1)) > 0 Then
            If Mamute_ParseHexAddr(tokens(1), endAddr) = 0 Then
                AppendMamuteLine(d, "?ERRO DE SINTAXE")
                Exit Sub
            End If
            haveEnd = -1
        End If
    Else
        If MamuteLastDisasmValid = 0 Then
            AppendMamuteLine(d, "?ERRO DE SINTAXE")
            Exit Sub
        End If
        startAddr = MamuteLastDisasmAddr
    End If

    Dim curAddr As Integer = startAddr
    If haveEnd <> 0 Then
        Do While curAddr <= endAddr
            AppendMamuteLine(d, MamuteDisasmLine(curAddr))
            Dim instrLen As Integer
            Dim mnem As String
            MamuteDisasmOne(curAddr, instrLen, mnem)
            If instrLen < 1 Then instrLen = 1
            curAddr += instrLen
            If curAddr > 65535 Then Exit Do
        Loop
    Else
        Dim nInstr As Integer
        For nInstr = 1 To 10
            AppendMamuteLine(d, MamuteDisasmLine(curAddr))
            Dim instrLen2 As Integer
            Dim mnem2 As String
            MamuteDisasmOne(curAddr, instrLen2, mnem2)
            If instrLen2 < 1 Then instrLen2 = 1
            curAddr += instrLen2
            If curAddr > 65535 Then Exit For
        Next nInstr
    End If

    MamuteLastDisasmAddr = curAddr And 65535
    MamuteLastDisasmValid = -1
End Sub

Private Sub MamuteCmd_LP(ByRef d As Document, ByRef argsText As String)
    Dim tokens() As String
    Dim tokCount As Integer
    Mamute_SplitArgs(argsText, tokens(), tokCount, 2)

    Dim startAddr As Integer
    Dim endAddr As Integer
    Dim haveEnd As Integer = 0

    If tokCount >= 1 And Len(tokens(0)) > 0 Then
        If Mamute_ParseHexAddr(tokens(0), startAddr) = 0 Then
            AppendMamuteLine(d, "?ERRO DE SINTAXE")
            Exit Sub
        End If
        If tokCount >= 2 And Len(tokens(1)) > 0 Then
            If Mamute_ParseHexAddr(tokens(1), endAddr) = 0 Then
                AppendMamuteLine(d, "?ERRO DE SINTAXE")
                Exit Sub
            End If
            haveEnd = -1
        End If
    Else
        If MamuteLastDisasmValid = 0 Then
            AppendMamuteLine(d, "?ERRO DE SINTAXE")
            Exit Sub
        End If
        startAddr = MamuteLastDisasmAddr
    End If

    Dim canceled As Integer
    Dim outPath As String = PromptPathDialog("LP - Salvar listagem", "Arquivo .txt de saida:", "disassembly.txt", canceled)
    If canceled <> 0 Or Len(outPath) = 0 Then
        AppendMamuteLine(d, "CANCELADO")
        Exit Sub
    End If

    Dim ff As Integer = FreeFile
    Open outPath For Output As #ff
    Dim headerText As String = "L " & Hex(startAddr, 4) & "H"
    If haveEnd <> 0 Then headerText &= "-" & Hex(endAddr, 4) & "H"
    Print #ff, headerText

    Dim curAddr As Integer = startAddr
    If haveEnd <> 0 Then
        Do While curAddr <= endAddr
            Print #ff, MamuteDisasmLine(curAddr)
            Dim instrLen As Integer
            Dim mnem As String
            MamuteDisasmOne(curAddr, instrLen, mnem)
            If instrLen < 1 Then instrLen = 1
            curAddr += instrLen
            If curAddr > 65535 Then Exit Do
        Loop
    Else
        Dim nInstr As Integer
        For nInstr = 1 To 10
            Print #ff, MamuteDisasmLine(curAddr)
            Dim instrLen2 As Integer
            Dim mnem2 As String
            MamuteDisasmOne(curAddr, instrLen2, mnem2)
            If instrLen2 < 1 Then instrLen2 = 1
            curAddr += instrLen2
            If curAddr > 65535 Then Exit For
        Next nInstr
    End If
    Close #ff

    MamuteLastDisasmAddr = curAddr And 65535
    MamuteLastDisasmValid = -1

    AppendMamuteLine(d, "ARQUIVO GRAVADO: " & outPath)
End Sub

Private Sub MamuteCmd_HELP(ByRef d As Document, ByRef argsText As String)
    OpenHelpDocument("Mamute Assembler", "dbhelp:MAMUTE|docs\help\mamute.md")
End Sub

Private Sub ExecuteMamuteCommand(ByRef d As Document, ByRef cmdTextIn As String)
    Dim cmdText As String = Trim(cmdTextIn)
    If Len(cmdText) = 0 Then Exit Sub

    Dim verb As String = cmdText
    Dim spacePos As Integer = InStr(cmdText, " ")
    If spacePos > 0 Then verb = Left(cmdText, spacePos - 1)
    verb = UCase(verb)

    Dim genericArgs As String = ""
    If spacePos > 0 Then genericArgs = Trim(Mid(cmdText, spacePos + 1))

    Select Case verb
        Case "CLS"
            d.lineCount = 1
            d.lines(1) = ""
            d.scrollY = 0
        Case "PAGE"
            LoadMamuteMemConfig()
            Dim pageArgs As String = ""
            If spacePos > 0 Then pageArgs = Trim(Mid(cmdText, spacePos + 1))

            If Len(pageArgs) = 0 Then
                ' PAGE sem argumentos: joga as 4 paginas inteiras pro slot
                ' com RAM (workspace limpo pro assembler), igual ao original.
                Dim ramSlot As Integer
                Dim ramSub As Integer
                If FindMamuteRamSlot(ramSlot, ramSub) <> 0 Then
                    Dim rp As Integer
                    For rp = 0 To 3
                        MamuteActiveSlot(rp) = ramSlot
                        MamuteActiveSub(rp) = ramSub
                    Next rp
                    AppendMamuteLine(d, MamuteActivePageSummary())
                Else
                    AppendMamuteLine(d, "?SEM RAM CONFIGURADA (Configurar -> Mamute (Memoria))")
                End If

            ElseIf pageArgs = "?" Then
                ' PAGE ?: mostra o estado atual completo (slots ativos,
                ' enderecos, VRAM e o mapa de memoria configurado).
                AppendMamuteLine(d, "")
                AppendMamuteLine(d, MamuteActivePageSummary())
                AppendMamuteLine(d, "Enderecos: Pag.0=" & MamutePageAddrRange(0) & " Pag.1=" & MamutePageAddrRange(1) & " Pag.2=" & MamutePageAddrRange(2) & " Pag.3=" & MamutePageAddrRange(3))
                AppendMamuteLine(d, "VRAM: " & Trim(Str(MamuteVramKB)) & "KB")
                AppendMamuteLine(d, "")
                Dim slot As Integer
                For slot = 0 To 3
                    If MamuteMemSubOn(slot) <> 0 Then
                        Dim subIdx As Integer
                        For subIdx = 0 To 3
                            AppendMamuteLine(d, MamutePageRowText(slot, subIdx))
                        Next subIdx
                    Else
                        AppendMamuteLine(d, MamutePageRowText(slot, 0))
                    End If
                Next slot

            Else
                ' PAGE X[,Y][,Z][,K]: X/Y/Z/K sao os slots (0-3) das paginas
                ' 0/1/2/3 nessa ordem - argumento em branco (ou omitido no
                ' final) deixa aquela pagina como esta. Ex.: "PAGE 1" muda so
                ' a pag.0 pro Slot 1; "PAGE ,,2" muda so a pag.2 pro Slot 2.
                Dim tokens(0 To 3) As String
                Dim tokCount As Integer = 0
                Dim remaining As String = pageArgs
                Do While tokCount < 4
                    Dim commaPos As Integer = InStr(remaining, ",")
                    If commaPos = 0 Then
                        tokens(tokCount) = Trim(remaining)
                        tokCount += 1
                        Exit Do
                    Else
                        tokens(tokCount) = Trim(Left(remaining, commaPos - 1))
                        remaining = Mid(remaining, commaPos + 1)
                        tokCount += 1
                    End If
                Loop

                Dim badArg As Integer = 0
                Dim changedAny As Integer = 0
                Dim ti As Integer
                For ti = 0 To tokCount - 1
                    If Len(tokens(ti)) > 0 Then
                        Dim slotVal As Integer = ValInt(tokens(ti))
                        If slotVal < 0 Or slotVal > 3 Then
                            badArg = -1
                        Else
                            MamuteActiveSlot(ti) = slotVal
                            MamuteActiveSub(ti) = 0
                            changedAny = -1
                        End If
                    End If
                Next ti

                If badArg <> 0 Then
                    AppendMamuteLine(d, "?ARGUMENTO INVALIDO (slot deve ser 0-3)")
                ElseIf changedAny = 0 Then
                    AppendMamuteLine(d, "?COMANDO INVALIDO")
                Else
                    AppendMamuteLine(d, MamuteActivePageSummary())
                End If
            End If
        Case "DM"
            MamuteCmd_DM(d, genericArgs)
        Case "ZAP"
            MamuteCmd_ZAP(d, genericArgs)
        Case "SCR"
            MamuteCmd_SCR(d, genericArgs)
        Case "SH"
            MamuteCmd_SH(d, genericArgs)
        Case "MS"
            MamuteCmd_MS(d, genericArgs)
        Case "LOAD"
            MamuteCmd_LOAD(d, genericArgs)
        Case "SAVE"
            MamuteCmd_SAVE(d, genericArgs)
        Case "M"
            MamuteCmd_M(d, genericArgs)
        Case "S"
            MamuteCmd_S(d, genericArgs)
        Case "C"
            MamuteCmd_C(d, genericArgs)
        Case "D"
            MamuteCmd_D(d, genericArgs)
        Case "P"
            MamuteCmd_P(d, genericArgs)
        Case "V"
            MamuteCmd_V(d, genericArgs)
        Case "T"
            MamuteCmd_T(d, genericArgs)
        Case "F"
            MamuteCmd_F(d, genericArgs)
        Case "G"
            MamuteCmd_G(d, genericArgs)
        Case "X"
            MamuteCmd_X(d, genericArgs)
        Case "R"
            MamuteCmd_R(d, genericArgs)
        Case "L"
            MamuteCmd_L(d, genericArgs)
        Case "LP"
            MamuteCmd_LP(d, genericArgs)
        Case "HELP"
            MamuteCmd_HELP(d, genericArgs)
        Case "EDIT"
            EditorCreateMamuteEdit()
        Case "BA", "QUIT"
            CloseDocument(activeDoc)
        Case Else
            AppendMamuteLine(d, "?COMANDO INVALIDO")
    End Select
End Sub

Private Sub HandleMamuteTermKey(ByRef d As Document, ByRef keyText As String, ByRef renderHint As Integer)
    renderHint = RENDER_CLIENT

    If keyText = Chr(13) Then
        Dim cmdText As String = mamuteInputBuf(activeDoc)
        mamuteInputBuf(activeDoc) = ""
        mamuteInputCursor(activeDoc) = 0
        If MamuteXWalking(activeDoc) <> 0 Then
            Mamute_ContinueXWalk(d, cmdText)
        Else
            AppendMamuteLine(d, MAMUTE_PROMPT & cmdText)
            ExecuteMamuteCommand(d, cmdText)
        End If
        Exit Sub
    End If

    If keyText = Chr(8) Then
        Dim caretPos As Integer = mamuteInputCursor(activeDoc)
        If caretPos > 0 Then
            Dim txt As String = mamuteInputBuf(activeDoc)
            mamuteInputBuf(activeDoc) = Left(txt, caretPos - 1) & Mid(txt, caretPos + 1)
            mamuteInputCursor(activeDoc) = caretPos - 1
        End If
        Exit Sub
    End If

    If Len(keyText) = 1 Then
        Dim c As Integer = Asc(keyText)
        If c >= 32 And c <= 126 Then
            Dim caretPos2 As Integer = mamuteInputCursor(activeDoc)
            Dim txt2 As String = mamuteInputBuf(activeDoc)
            mamuteInputBuf(activeDoc) = Left(txt2, caretPos2) & keyText & Mid(txt2, caretPos2 + 1)
            mamuteInputCursor(activeDoc) = caretPos2 + 1
        End If
        Exit Sub
    End If

    If Len(keyText) = 2 And Asc(Left(keyText, 1)) = 0 Then
        Select Case Asc(Right(keyText, 1))
            Case 75
                If mamuteInputCursor(activeDoc) > 0 Then mamuteInputCursor(activeDoc) -= 1
            Case 77
                If mamuteInputCursor(activeDoc) < Len(mamuteInputBuf(activeDoc)) Then mamuteInputCursor(activeDoc) += 1
            Case 71
                mamuteInputCursor(activeDoc) = 0
            Case 79
                mamuteInputCursor(activeDoc) = Len(mamuteInputBuf(activeDoc))
            Case 83
                Dim caretPos3 As Integer = mamuteInputCursor(activeDoc)
                Dim txt3 As String = mamuteInputBuf(activeDoc)
                If caretPos3 < Len(txt3) Then
                    mamuteInputBuf(activeDoc) = Left(txt3, caretPos3) & Mid(txt3, caretPos3 + 2)
                End If
            Case 72
                d.scrollY = Clamp(d.scrollY - 1, 0, GetMaxScrollY(d))
            Case 80
                d.scrollY = Clamp(d.scrollY + 1, 0, GetMaxScrollY(d))
            Case 73
                d.scrollY = Clamp(d.scrollY - GetClientTextHeight(d), 0, GetMaxScrollY(d))
            Case 81
                d.scrollY = Clamp(d.scrollY + GetClientTextHeight(d), 0, GetMaxScrollY(d))
        End Select
    End If
End Sub

Private Sub DrawMamuteInputLine(ByVal docIndex As Integer, ByVal rowY As Integer)
    Dim ByRef d As Document = docs(docIndex)
    Dim clientW As Integer = GetClientTextWidth(d)
    If clientW > MAX_SYNTAX_W Then clientW = MAX_SYNTAX_W
    Dim lineText As String = MamuteCurrentPromptText(docIndex) & mamuteInputBuf(docIndex)
    Dim padded As String = Left(lineText & Space(clientW), clientW)
    Dim i As Integer
    For i = 1 To clientW
        ConsoleSetCell(d.winX + i, rowY, Asc(Mid(padded, i, 1)), 10, 0)
    Next i
End Sub

Private Sub EditorCreateMamuteTerm()
    If docCount >= MAX_DOCS Then Exit Sub

    docCount += 1
    activeDoc = docCount

    LoadMamuteMemConfig()
    SetMamuteDefaultPageMapping()
    Mamute_LoadPhysicalMemory()
    Mamute_ResetRegs()
    MamuteDisplayMode = 0
    MamuteLastShValid = 0
    MamuteLastMValid = 0
    MamuteLastSValid = 0
    MamuteLastDisasmValid = 0
    MamuteXWalking(docCount) = 0
    MamuteXWalkIdx(docCount) = 0
    mamuteMEditActive(docCount) = 0

    InitBlankDocument(docs(docCount), "Mamute Assembler")
    docs(docCount).isMamuteTerm = -1
    docs(docCount).lineCount = 3
    docs(docCount).lines(1) = "Mamute Assembler - MON>"
    docs(docCount).lines(2) = "Comandos: CLS, PAGE, DM, ZAP, SCR, SH, MS, LOAD, SAVE, M, S, C, D, P, V, T, F, G, X, R, EDIT, L, LP, HELP, BA/QUIT."
    docs(docCount).lines(3) = MamuteActivePageSummary()
    mamuteInputBuf(docCount) = ""
    mamuteInputCursor(docCount) = 0

    LayoutNewDocumentWindow(docCount)

    forceFullRedraw = 1
    renderMode = RENDER_FULL
End Sub

Sub EditorDraw(ByVal menuOpen As Integer)
    ConsoleBeginFrame()

    If forceFullRedraw <> 0 Then
        DrawDesktop()
        DrawDocumentsFull()
        DrawMenuBar(menuOpen)
        DrawStatusBar()
        forceFullRedraw = 0
        renderMode = RENDER_CURSOR
    Else
        DrawDocumentsFast()
        DrawStatusBar()
    End If

    PlaceActiveCursor()
    ConsoleFlush()
    ConsoleEndFrame()
    PerfCaptureFrame()
End Sub

Sub EditorHandleKey(ByRef keyText As String, ByRef running As Integer, ByRef menuOpen As Integer)
    keyText = NormalizeKey(keyText)

    If Len(keyText) = 2 And Asc(Left(keyText, 1)) = 0 And Asc(Right(keyText, 1)) = 84 Then
        If activeDoc >= 1 And activeDoc <= docCount Then
            Dim ByRef ad As Document = docs(activeDoc)
            If ad.isHelp = 0 Then
                msxDictHasReturnHelp = 0
                msxDictReturnHelpPath = ""
                msxDictReturnHelpTitle = ""
                Dim kw As String = GetKeywordAtCursor(ad)
                If Len(kw) > 0 Then
                    OpenMsxDictHelpByKeyword(kw)
                Else
                    OpenMsxDictHelp()
                End If
            Else
                If IsMsxDictDoc(ad) <> 0 Then
                    If msxDictHasReturnHelp <> 0 And Len(msxDictReturnHelpPath) > 0 Then
                        OpenHelpDocument(msxDictReturnHelpTitle, msxDictReturnHelpPath)
                    Else
                        OpenMsxDictHelp()
                    End If
                Else
                    msxDictHasReturnHelp = -1
                    msxDictReturnHelpPath = ad.filePath
                    msxDictReturnHelpTitle = ad.helpTitle
                    OpenMsxDictHelp()
                End If
            End If
        Else
            OpenMsxDictHelp()
        End If
        Exit Sub
    End If

    ' Ctrl+L opens compile debug log directly, without going through menus.
    If keyText = Chr(12) Then
        OpenCompileLogDocument()
        menuOpen = 0
        forceFullRedraw = 1
        renderMode = RENDER_FULL
        Exit Sub
    End If

    If Len(keyText) = 2 And Asc(Left(keyText, 1)) = 0 And Asc(Right(keyText, 1)) = 68 Then
        menuOpen = IIf(menuOpen = MENU_VIEW_NONE, MENU_VIEW_FILE, MENU_VIEW_NONE)
        forceFullRedraw = 1
        Exit Sub
    End If

    If Len(keyText) = 2 And Asc(Left(keyText, 1)) = 0 And Asc(Right(keyText, 1)) = 59 Then
        menuOpen = IIf(menuOpen = MENU_VIEW_HELP, MENU_VIEW_NONE, MENU_VIEW_HELP)
        forceFullRedraw = 1
        renderMode = RENDER_FULL
        Exit Sub
    End If

    If Len(keyText) = 2 And Asc(Left(keyText, 1)) = 0 And Asc(Right(keyText, 1)) = 67 Then
        menuOpen = IIf(menuOpen = MENU_VIEW_CONFIG, MENU_VIEW_NONE, MENU_VIEW_CONFIG)
        forceFullRedraw = 1
        renderMode = RENDER_FULL
        Exit Sub
    End If

    If Len(keyText) = 2 And Asc(Left(keyText, 1)) = 0 And Asc(Right(keyText, 1)) = 66 Then
        menuOpen = IIf(menuOpen = MENU_VIEW_COMPILE, MENU_VIEW_NONE, MENU_VIEW_COMPILE)
        forceFullRedraw = 1
        renderMode = RENDER_FULL
        Exit Sub
    End If

    If menuOpen <> 0 Then
        If keyText = Chr(27) Then
            menuOpen = 0
            forceFullRedraw = 1
            renderMode = RENDER_FULL
        Else
            Dim menuCmd As Integer = MenuCommandFromKey(menuOpen, keyText)
            If keyText = Chr(13) Then
                If menuOpen = MENU_VIEW_HELP Then
                    menuCmd = MENU_CMD_HELP_BASIC
                ElseIf menuOpen = MENU_VIEW_CONFIG Then
                    menuCmd = MENU_CMD_CFG_BADIG
                ElseIf menuOpen = MENU_VIEW_COMPILE Then
                    menuCmd = MENU_CMD_COMPILE_MSX
                ElseIf menuOpen = MENU_VIEW_REFERENCE Then
                    menuCmd = MENU_CMD_REF_REDBOOK
                ElseIf menuOpen = MENU_VIEW_MAMUTE Then
                    menuCmd = MENU_CMD_MAMUTE_OPEN
                Else
                    menuCmd = MENU_CMD_EXIT
                End If
            End If
            If menuCmd <> MENU_CMD_NONE Then
                ExecuteMenuCommand(menuCmd, running, menuOpen)
            End If
        End If
        Exit Sub
    End If

    Dim needFullRedraw As Integer = 0
    Dim renderHint As Integer = RENDER_CURSOR

    Dim oldScrollX As Integer = docs(activeDoc).scrollX
    Dim oldScrollY As Integer = docs(activeDoc).scrollY

    HandleEditorKey(keyText, running, needFullRedraw, renderHint)
    ' Terminal do Mamute gerencia d.scrollY sozinho (AppendMamuteLine rola
    ' pro fim a cada linha nova; PgUp/PgDn/Home/End tem tratamento proprio em
    ' HandleMamuteTermKey) - nunca usa d.cursorX/d.cursorY (esses ficam
    ' parados no valor inicial, ja que a "digitacao" vai pro buffer da linha
    ' de comando, nao pra d.lines()). Chamar EnsureCursorVisible aqui pra um
    ' documento assim prendia a rolagem sempre no topo, escondendo a saida
    ' nova de todo comando digitado.
    If docs(activeDoc).isMamuteTerm = 0 And docs(activeDoc).isMamuteEdit = 0 Then EnsureCursorVisible(docs(activeDoc))

    If docs(activeDoc).scrollX <> oldScrollX Or docs(activeDoc).scrollY <> oldScrollY Then
        renderHint = RENDER_CLIENT
    End If

    If needFullRedraw <> 0 Then forceFullRedraw = 1
    RequestRender(renderHint, docs(activeDoc).cursorY)
End Sub

Sub EditorHandleMouse(ByVal mouseX As Integer, ByVal mouseY As Integer, ByVal mouseAction As Integer, ByRef running As Integer, ByRef menuOpen As Integer)
    If mouseAction = MSX_MOUSE_UP Then
        dragMode = DRAG_NONE
        Exit Sub
    End If

    If mouseAction = MSX_MOUSE_WHEEL_UP Or mouseAction = MSX_MOUSE_WHEEL_DOWN Then
        Dim hitWheel As Integer = FindTopWindowAt(mouseX, mouseY)
        If hitWheel = 0 Then Exit Sub

        BringDocumentToFront(hitWheel)
        Dim ByRef dw As Document = docs(activeDoc)
        Dim wheelStep As Integer = 3

        If mouseAction = MSX_MOUSE_WHEEL_UP Then
            dw.scrollY -= wheelStep
        Else
            dw.scrollY += wheelStep
        End If
        ClampScroll(dw)

        forceFullRedraw = 1
        renderMode = RENDER_FULL
        Exit Sub
    End If

    If mouseAction = MSX_MOUSE_MOVE Then
        If dragMode = DRAG_MOVE Then
            Dim ByRef d As Document = docs(activeDoc)
            d.winX = mouseX - dragOffsetX
            d.winY = mouseY - dragOffsetY
            ClampWindowToDesktop(d)
            forceFullRedraw = 1
            renderMode = RENDER_FULL
        ElseIf dragMode = DRAG_RESIZE Then
            Dim ByRef d As Document = docs(activeDoc)
            If d.isMaximized = 0 Then
                d.winW = resizeStartW + (mouseX - resizeStartMouseX)
                d.winH = resizeStartH + (mouseY - resizeStartMouseY)
                ClampWindowSize(d)
                ClampScroll(d)
                d.normalW = d.winW
                d.normalH = d.winH
                forceFullRedraw = 1
                renderMode = RENDER_FULL
            End If
        ElseIf dragMode = DRAG_VSCROLL Then
            Dim ByRef d As Document = docs(activeDoc)
            SetScrollFromVBar(d, mouseY)
            forceFullRedraw = 1
            renderMode = RENDER_FULL
        ElseIf dragMode = DRAG_HSCROLL Then
            Dim ByRef d As Document = docs(activeDoc)
            SetScrollFromHBar(d, mouseX)
            forceFullRedraw = 1
            renderMode = RENDER_FULL
        End If
        Exit Sub
    End If

    If mouseAction <> MSX_MOUSE_DOWN Then Exit Sub

    ' Clique na barra de menu (Arquivo)
    If mouseY = 1 And mouseX >= 2 And mouseX <= 8 Then
        menuOpen = IIf(menuOpen = MENU_VIEW_FILE, MENU_VIEW_NONE, MENU_VIEW_FILE)
        dragMode = DRAG_NONE
        forceFullRedraw = 1
        renderMode = RENDER_FULL
        Exit Sub
    End If

    ' Clique na barra de menu (Configurar)
    If mouseY = 1 And mouseX >= 11 And mouseX <= 20 Then
        menuOpen = IIf(menuOpen = MENU_VIEW_CONFIG, MENU_VIEW_NONE, MENU_VIEW_CONFIG)
        dragMode = DRAG_NONE
        forceFullRedraw = 1
        renderMode = RENDER_FULL
        Exit Sub
    End If

    ' Clique na barra de menu (Compilar)
    If mouseY = 1 And mouseX >= 23 And mouseX <= 30 Then
        menuOpen = IIf(menuOpen = MENU_VIEW_COMPILE, MENU_VIEW_NONE, MENU_VIEW_COMPILE)
        dragMode = DRAG_NONE
        forceFullRedraw = 1
        renderMode = RENDER_FULL
        Exit Sub
    End If

    ' Clique na barra de menu (Referencia)
    If mouseY = 1 And mouseX >= 33 And mouseX <= 42 Then
        menuOpen = IIf(menuOpen = MENU_VIEW_REFERENCE, MENU_VIEW_NONE, MENU_VIEW_REFERENCE)
        dragMode = DRAG_NONE
        forceFullRedraw = 1
        renderMode = RENDER_FULL
        Exit Sub
    End If

    ' Clique na barra de menu (Mamute)
    If mouseY = 1 And mouseX >= 45 And mouseX <= 51 Then
        menuOpen = IIf(menuOpen = MENU_VIEW_MAMUTE, MENU_VIEW_NONE, MENU_VIEW_MAMUTE)
        dragMode = DRAG_NONE
        forceFullRedraw = 1
        renderMode = RENDER_FULL
        Exit Sub
    End If

    ' Clique na barra de menu (Ajuda)
    If mouseY = 1 And mouseX >= 53 And mouseX <= 57 Then
        menuOpen = IIf(menuOpen = MENU_VIEW_HELP, MENU_VIEW_NONE, MENU_VIEW_HELP)
        dragMode = DRAG_NONE
        forceFullRedraw = 1
        renderMode = RENDER_FULL
        Exit Sub
    End If

    If menuOpen <> 0 Then
        Dim menuCmd As Integer = MENU_CMD_NONE
        If menuOpen = MENU_VIEW_FILE Then
            If mouseX >= 3 And mouseX <= 34 Then
                Select Case mouseY
                    Case 3
                        menuCmd = MENU_CMD_NEW
                    Case 4
                        menuCmd = MENU_CMD_NEW_ASMSX
                    Case 5
                        menuCmd = MENU_CMD_OPEN
                    Case 6
                        menuCmd = MENU_CMD_SAVE
                    Case 7
                        menuCmd = MENU_CMD_SAVE_AS
                    Case 8
                        menuCmd = MENU_CMD_CLOSE
                    Case 9
                        menuCmd = MENU_CMD_EXIT
                    Case 11
                        menuCmd = MENU_CMD_PROJECT_NEW
                    Case 12
                        menuCmd = MENU_CMD_PROJECT_OPEN
                    Case 13
                        menuCmd = MENU_CMD_PROJECT_SAVE
                    Case 14
                        menuCmd = MENU_CMD_PROJECT_CLOSE
                End Select
            End If
        ElseIf menuOpen = MENU_VIEW_CONFIG Then
            If mouseX >= 12 And mouseX <= 43 Then
                Select Case mouseY
                    Case 3
                        menuCmd = MENU_CMD_CFG_BADIG
                    Case 4
                        menuCmd = MENU_CMD_CFG_MSX
                    Case 5
                        menuCmd = MENU_CMD_CFG_EMULATOR
                    Case 6
                        menuCmd = MENU_CMD_CFG_MAMUTE_MEM
                End Select
            End If
        ElseIf menuOpen = MENU_VIEW_COMPILE Then
            If mouseX >= 24 And mouseX <= 65 Then
                Select Case mouseY
                    Case 3
                        menuCmd = MENU_CMD_COMPILE_MSX
                    Case 4
                        menuCmd = MENU_CMD_COMPILE_DIGNIFIED
                    Case 5
                        menuCmd = MENU_CMD_COMPILE_TOKENIZE_AMX
                    Case 6
                        menuCmd = MENU_CMD_COMPILE_RUN_EMU
                    Case 7
                        menuCmd = MENU_CMD_COMPILE_OPEN_LOG
                End Select
            End If
        ElseIf menuOpen = MENU_VIEW_HELP Then
            If mouseX >= 54 And mouseX <= 87 Then
                Select Case mouseY
                    Case 3
                        menuCmd = MENU_CMD_HELP_BASIC
                    Case 4
                        menuCmd = MENU_CMD_HELP_DIGNIFIED
                    Case 5
                        menuCmd = MENU_CMD_HELP_BATOKEN
                    Case 6
                        menuCmd = MENU_CMD_HELP_ASMSX
                    Case 7
                        menuCmd = MENU_CMD_HELP_MSX_DICT
                    Case 8
                        menuCmd = MENU_CMD_HELP_EDITOR
                    Case 9
                        menuCmd = MENU_CMD_MAMUTE_HELP
                    Case 10
                        menuCmd = MENU_CMD_HELP_THEME
                End Select
            End If
        ElseIf menuOpen = MENU_VIEW_REFERENCE Then
            If mouseX >= 33 And mouseX <= 74 Then
                Select Case mouseY
                    Case 3
                        menuCmd = MENU_CMD_REF_REDBOOK
                    Case 4
                        menuCmd = MENU_CMD_REF_NESTOR
                    Case 5
                        menuCmd = MENU_CMD_REF_HANDBOOK
                    Case 6
                        menuCmd = MENU_CMD_REF_MANUALS
                    Case 7
                        menuCmd = MENU_CMD_REF_BIOSCALLS
                    Case 8
                        menuCmd = MENU_CMD_REF_HARDWARE
                    Case 9
                        menuCmd = MENU_CMD_REF_BIOSDOC
                    Case 10
                        menuCmd = MENU_CMD_REF_SEETRACKER
                    Case 11
                        menuCmd = MENU_CMD_REF_OPENMSX
                    Case 12
                        menuCmd = MENU_CMD_REF_MSXBAS2ROM
                End Select
            End If
        ElseIf menuOpen = MENU_VIEW_MAMUTE Then
            If mouseX >= 45 And mouseX <= 75 Then
                Select Case mouseY
                    Case 3
                        menuCmd = MENU_CMD_MAMUTE_OPEN
                End Select
            End If
        End If

        If menuCmd <> MENU_CMD_NONE Then
            ExecuteMenuCommand(menuCmd, running, menuOpen)
        Else
            menuOpen = 0
            forceFullRedraw = 1
            renderMode = RENDER_FULL
        End If
        Exit Sub
    End If

    Dim hit As Integer = FindTopWindowAt(mouseX, mouseY)
    If hit = 0 Then
        dragMode = DRAG_NONE
        Exit Sub
    End If

    BringDocumentToFront(hit)
    Dim ByRef d As Document = docs(activeDoc)

    ' Botao fechar (quadradinho no topo esquerdo).
    If mouseY = d.winY And mouseX = d.winX + 2 Then
        CloseDocument(activeDoc)
        dragMode = DRAG_NONE
        forceFullRedraw = 1
        renderMode = RENDER_FULL
        Exit Sub
    End If

    ' Botao maximizar/restaurar (seta no topo direito).
    If mouseY = d.winY And mouseX = d.winX + d.winW - 3 Then
        ToggleMaximizeActiveWindow()
        dragMode = DRAG_NONE
        forceFullRedraw = 1
        renderMode = RENDER_FULL
        Exit Sub
    End If

    ' Grip de resize no canto inferior direito.
    If mouseX = d.winX + d.winW - 2 And mouseY = d.winY + d.winH - 2 Then
        If d.isMaximized = 0 Then
            dragMode = DRAG_RESIZE
            resizeStartMouseX = mouseX
            resizeStartMouseY = mouseY
            resizeStartW = d.winW
            resizeStartH = d.winH
        End If
        Exit Sub
    End If

    ' Barra vertical: clique para posicionar thumb e iniciar arraste.
    If mouseX = d.winX + d.winW - 2 And mouseY >= d.winY + 1 And mouseY <= d.winY + d.winH - 3 Then
        SetScrollFromVBar(d, mouseY)
        dragMode = DRAG_VSCROLL
        forceFullRedraw = 1
        renderMode = RENDER_FULL
        Exit Sub
    End If

    ' Barra horizontal: clique para posicionar thumb e iniciar arraste.
    If mouseY = d.winY + d.winH - 2 And mouseX >= d.winX + 1 And mouseX <= d.winX + d.winW - 3 Then
        SetScrollFromHBar(d, mouseX)
        dragMode = DRAG_HSCROLL
        forceFullRedraw = 1
        renderMode = RENDER_FULL
        Exit Sub
    End If

    If mouseY = d.winY Then
        ' Arraste pela barra de titulo da janela.
        If d.isMaximized = 0 Then
            dragMode = DRAG_MOVE
        Else
            dragMode = DRAG_NONE
        End If
        dragOffsetX = mouseX - d.winX
        dragOffsetY = mouseY - d.winY
    Else
        dragMode = DRAG_NONE

        ' Clique na area de texto posiciona o cursor.
        If mouseX >= d.winX + 1 And mouseX <= d.winX + d.winW - 3 And mouseY >= d.winY + 1 And mouseY <= d.winY + d.winH - 3 Then
            d.cursorY = d.scrollY + (mouseY - (d.winY + 1)) + 1
            d.cursorY = Clamp(d.cursorY, 1, d.lineCount)

            Dim lineLen As Integer = Len(d.lines(d.cursorY))
            d.cursorX = d.scrollX + (mouseX - (d.winX + 1)) + 1
            d.cursorX = Clamp(d.cursorX, 1, lineLen + 1)

            If OpenMsxDictFromActiveIndexCursor() <> 0 Then Exit Sub
        End If
    End If

    forceFullRedraw = 1
    renderMode = RENDER_FULL
End Sub

Sub EditorSaveAllToDb()
    Dim i As Integer
    For i = 1 To docCount
        If docs(i).isHelp = 0 Then
            DbSaveDocumentState(docs(i).title, docs(i).filePath, docs(i).cursorX, docs(i).cursorY)
        End If
    Next i
End Sub

Function EditorRunHelpSmokeTest(ByRef report As String) As Integer
    report = ""

    Dim running As Integer = 1
    Dim menuOpen As Integer = 0
    Dim keyText As String = Chr(0) & Chr(84) ' Shift+F1

    Dim parserCallText As String
    Dim parserEntry As MsxDictEntry
    Dim parserErr As String
    If FindMsxDictEntry("INKEY$", parserEntry, parserErr) = 0 Then
        report = "SMOKE HELP FAIL: parser INKEY$ nao encontrado (" & parserErr & ")"
        Return 0
    End If
    If Len(Trim(parserEntry.summary)) = 0 Or Len(Trim(parserEntry.formatText)) = 0 Or Len(Trim(parserEntry.formatExample)) = 0 Or Len(Trim(parserEntry.functionText)) = 0 Then
        Dim dbgArgCount As Integer = 0
        Dim dbgArgs() As String
        Dim dbg5 As String = ""
        Dim dbg6 As String = ""
        Dim dbg9 As String = ""
        If FindMsxDictCallText("INKEY$", parserCallText, parserErr) <> 0 Then
            SplitMsxDictArgs(parserCallText, dbgArgs(), dbgArgCount)
            If dbgArgCount >= 5 Then dbg5 = Left(Trim(dbgArgs(5)), 40)
            If dbgArgCount >= 6 Then dbg6 = Left(Trim(dbgArgs(6)), 40)
            If dbgArgCount >= 9 Then dbg9 = Left(Trim(dbgArgs(9)), 40)
        End If
        report = "SMOKE HELP FAIL: parser INKEY$ campos vazios (args=" & Trim(Str(dbgArgCount)) & ", a5='" & dbg5 & "', a6='" & dbg6 & "', a9='" & dbg9 & "')"
        Return 0
    End If
    If InStr(1, parserEntry.programExample, "10 REM INKEY$") = 0 Or InStr(1, parserEntry.programExample, "70 X=X-") = 0 Or InStr(1, parserEntry.programExample, "100 GOTO 60") = 0 Then
        report = "SMOKE HELP FAIL: parser INKEY$ retornou programa exemplo truncado"
        Return 0
    End If

    If docCount < 1 Or activeDoc < 1 Or activeDoc > docCount Then
        report = "SMOKE HELP FAIL: editor sem documento ativo"
        Return 0
    End If

    ' Micro-smoke de ESC em modal: reset de input seguido de acao imediata em menu/log.
    dragMode = DRAG_MOVE
    FinalizeModalInputState()
    If dragMode <> DRAG_NONE Then
        report = "SMOKE HELP FAIL: estado de drag nao resetado apos ESC em modal"
        Return 0
    End If

    ExecuteMenuCommand(MENU_CMD_COMPILE_OPEN_LOG, running, menuOpen)
    If activeDoc < 1 Or activeDoc > docCount Then
        report = "SMOKE HELP FAIL: sem documento apos abrir log de compilacao"
        Return 0
    End If
    If docs(activeDoc).isHelp <> 0 Then
        report = "SMOKE HELP FAIL: log de compilacao abriu como help"
        Return 0
    End If
    If LCase(docs(activeDoc).filePath) <> LCase(CompileDebugLogPath()) Then
        report = "SMOKE HELP FAIL: modal ESC + log abriu caminho inesperado (" & docs(activeDoc).filePath & ")"
        Return 0
    End If

    ' Explicit cycle: normal help -> Shift+F1 -> dict -> Shift+F1 -> return previous help.
    OpenHelpDocument("BaToken", "dbhelp:BATOKEN|basic-dignified\documentation\BATOKEN.md")
    If activeDoc < 1 Or activeDoc > docCount Or docs(activeDoc).isHelp = 0 Then
        report = "SMOKE HELP FAIL: nao abriu help normal para teste de retorno"
        Return 0
    End If

    Dim prevHelpPath As String = docs(activeDoc).filePath
    Dim prevHelpTitle As String = docs(activeDoc).helpTitle

    EditorHandleKey(keyText, running, menuOpen)
    If activeDoc < 1 Or activeDoc > docCount Then
        report = "SMOKE HELP FAIL: sem documento apos Shift+F1 no help normal"
        Return 0
    End If
    If IsMsxDictDoc(docs(activeDoc)) = 0 Then
        report = "SMOKE HELP FAIL: Shift+F1 no help normal nao abriu dicionario (" & docs(activeDoc).filePath & ")"
        Return 0
    End If

    EditorHandleKey(keyText, running, menuOpen)
    If activeDoc < 1 Or activeDoc > docCount Then
        report = "SMOKE HELP FAIL: sem documento apos Shift+F1 de retorno"
        Return 0
    End If
    If LCase(docs(activeDoc).filePath) <> LCase(prevHelpPath) Then
        report = "SMOKE HELP FAIL: Shift+F1 nao retornou ao help anterior (esperado " & prevHelpPath & ", atual " & docs(activeDoc).filePath & ")"
        Return 0
    End If
    If LCase(docs(activeDoc).helpTitle) <> LCase(prevHelpTitle) Then
        report = "SMOKE HELP FAIL: retornou para help com titulo inesperado"
        Return 0
    End If

    ' Fecha help para continuar nos cenarios partindo de documento de codigo.
    CloseDocument(activeDoc)
    If docCount < 1 Or activeDoc < 1 Or activeDoc > docCount Then
        report = "SMOKE HELP FAIL: sem documento apos fechar help de retorno"
        Return 0
    End If

    ' Contextual open from source document (word under cursor).
    docs(activeDoc).isHelp = 0
    docs(activeDoc).lineCount = 1
    docs(activeDoc).lines(1) = "PRINT 1: GOTO 100"
    docs(activeDoc).cursorY = 1
    docs(activeDoc).cursorX = 2
    docs(activeDoc).scrollX = 0
    docs(activeDoc).scrollY = 0

    EditorHandleKey(keyText, running, menuOpen)
    If activeDoc < 1 Or activeDoc > docCount Then
        report = "SMOKE HELP FAIL: sem documento apos Shift+F1 contextual"
        Return 0
    End If
    If docs(activeDoc).isHelp = 0 Then
        report = "SMOKE HELP FAIL: Shift+F1 nao abriu documento de help"
        Return 0
    End If
    If LCase(Left(docs(activeDoc).filePath, 17)) <> "msxdict:cmd:print" Then
        report = "SMOKE HELP FAIL: Shift+F1 nao abriu verbete PRINT (" & docs(activeDoc).filePath & ")"
        Return 0
    End If

    Dim hasResumo As Integer = 0
    Dim hasFormato As Integer = 0
    Dim hasExemplo As Integer = 0
    Dim hasPrograma As Integer = 0
    Dim hasListingLine As Integer = 0
    Dim i As Integer
    For i = 1 To docs(activeDoc).lineCount
        Dim l As String = Trim(UCase(docs(activeDoc).lines(i)))
        If l = "RESUMO" Then hasResumo = -1
        If l = "FORMATO" Then hasFormato = -1
        If l = "EXEMPLO" Then hasExemplo = -1
        If l = "PROGRAMA EXEMPLO" Then hasPrograma = -1
        If InStr(1, l, "PRINT") > 0 Or InStr(1, l, "GOTO") > 0 Or InStr(1, l, "FOR ") > 0 Then
            hasListingLine = -1
        End If
    Next i
    If hasResumo = 0 Or hasFormato = 0 Or hasExemplo = 0 Then
        report = "SMOKE HELP FAIL: secoes principais do verbete nao foram carregadas"
        Return 0
    End If
    If hasPrograma = 0 Or hasListingLine = 0 Then
        report = "SMOKE HELP FAIL: programa exemplo ausente ou truncado"
        Return 0
    End If

    ' Shift+F1 from help should fallback to index.
    EditorHandleKey(keyText, running, menuOpen)
    If LCase(docs(activeDoc).filePath) <> "msxdict:index" Then
        report = "SMOKE HELP FAIL: Shift+F1 em help nao abriu indice (" & docs(activeDoc).filePath & ")"
        Return 0
    End If

    Dim hasParteI As Integer = 0
    Dim hasParteIII As Integer = 0
    Dim hasParteIV As Integer = 0
    Dim hasAcvs As Integer = 0
    Dim hasFmMusic As Integer = 0
    Dim sectionLine As String
    For i = 1 To docs(activeDoc).lineCount
        sectionLine = UCase(Trim(docs(activeDoc).lines(i)))
        If InStr(1, sectionLine, "PARTE I") > 0 And InStr(1, sectionLine, "ESTRUTURA") > 0 Then hasParteI = -1
        If InStr(1, sectionLine, "PARTE III") > 0 And InStr(1, sectionLine, "APLICACOES") > 0 Then hasParteIII = -1
        If InStr(1, sectionLine, "PARTE IV") > 0 And InStr(1, sectionLine, "APENDICES") > 0 Then hasParteIV = -1
        If InStr(1, sectionLine, "MSX 2+") > 0 And InStr(1, sectionLine, "ACVS") > 0 Then hasAcvs = -1
        If InStr(1, sectionLine, "FM-MUSIC") > 0 Then hasFmMusic = -1
    Next i

    If hasParteI = 0 Or hasParteIII = 0 Or hasParteIV = 0 Or hasAcvs = 0 Or hasFmMusic = 0 Then
        report = "SMOKE HELP FAIL: indice sem blocos esperados (Parte I/III/IV, ACVS, FM-Music)"
        Return 0
    End If

    Dim idxDoc As Integer = activeDoc
    Dim clientH As Integer = GetClientTextHeight(docs(idxDoc))
    Dim visibleStart As Integer = docs(idxDoc).scrollY + 1
    Dim visibleEnd As Integer = docs(idxDoc).scrollY + clientH
    If visibleEnd > docs(idxDoc).lineCount Then visibleEnd = docs(idxDoc).lineCount

    Dim firstLine As Integer = 0
    Dim firstKeyword As String = ""
    i = 0
    For i = visibleStart To visibleEnd
        If Len(msxDictLineCommand(idxDoc, i)) > 0 Then
            If IsMsxTopicToken(msxDictLineCommand(idxDoc, i)) = 0 Then
                firstLine = i
                firstKeyword = msxDictLineCommand(idxDoc, i)
                Exit For
            End If
        End If
    Next i

    If firstLine = 0 Then
        For i = 1 To docs(idxDoc).lineCount
            If Len(msxDictLineCommand(idxDoc, i)) > 0 Then
                If IsMsxTopicToken(msxDictLineCommand(idxDoc, i)) = 0 Then
                    firstLine = i
                    firstKeyword = msxDictLineCommand(idxDoc, i)
                    Exit For
                End If
            End If
        Next i
    End If

    If firstLine = 0 Or Len(firstKeyword) = 0 Then
        report = "SMOKE HELP FAIL: indice sem entradas clicaveis"
        Return 0
    End If

    Dim msx2Exclusive As String = "SETPAGE"
    Dim msx2Line As Integer = 0
    For i = 1 To docs(idxDoc).lineCount
        If UCase(msxDictLineCommand(idxDoc, i)) = msx2Exclusive Then
            msx2Line = i
            Exit For
        End If
    Next i
    If msx2Line = 0 Then
        report = "SMOKE HELP FAIL: indice fundido sem comando MSX2+/FM exclusivo (" & msx2Exclusive & ")"
        Return 0
    End If

    docs(idxDoc).cursorY = msx2Line
    docs(idxDoc).cursorX = 1
    Dim msx2Rc As Integer = OpenMsxDictFromActiveIndexCursor()
    If msx2Rc = 0 Or LCase(docs(activeDoc).filePath) <> LCase("msxdict:cmd:" & msx2Exclusive) Then
        report = "SMOKE HELP FAIL: comando exclusivo MSX2+/FM nao abriu (" & msx2Exclusive & ")"
        Return 0
    End If

    OpenMsxDictHelp()
    idxDoc = activeDoc

    Dim firstTopicLine As Integer = 0
    For i = 1 To docs(idxDoc).lineCount
        If IsMsxTopicToken(msxDictLineCommand(idxDoc, i)) <> 0 Then
            firstTopicLine = i
            Exit For
        End If
    Next i
    If firstTopicLine = 0 Then
        report = "SMOKE HELP FAIL: indice sem topicos de referencia"
        Return 0
    End If

    docs(idxDoc).cursorY = firstTopicLine
    docs(idxDoc).cursorX = 1
    Dim topicRc As Integer = OpenMsxDictFromActiveIndexCursor()
    If topicRc = 0 Or Left(LCase(docs(activeDoc).filePath), 14) <> "msxdict:topic:" Then
        report = "SMOKE HELP FAIL: topico de referencia nao abriu"
        Return 0
    End If

    OpenMsxDictHelp()
    idxDoc = activeDoc

    If firstLine > docs(idxDoc).scrollY + clientH Then
        docs(idxDoc).scrollY = firstLine - clientH
    End If
    If firstLine <= docs(idxDoc).scrollY Then
        docs(idxDoc).scrollY = firstLine - 1
    End If
    If docs(idxDoc).scrollY < 0 Then docs(idxDoc).scrollY = 0

    docs(idxDoc).cursorY = firstLine
    docs(idxDoc).cursorX = 1
    Dim openRc As Integer = OpenMsxDictFromActiveIndexCursor()

    If activeDoc < 1 Or activeDoc > docCount Then
        report = "SMOKE HELP FAIL: sem documento apos clique no indice"
        Return 0
    End If
    If LCase(docs(activeDoc).filePath) <> LCase("msxdict:cmd:" & firstKeyword) Then
        Dim lineAfter As Integer = docs(activeDoc).cursorY
        Dim mapAfter As String = ""
        If lineAfter >= 1 And lineAfter <= MAX_LINES Then mapAfter = msxDictLineCommand(activeDoc, lineAfter)
        report = "SMOKE HELP FAIL: clique nao abriu verbete esperado (esperado " & firstKeyword & ", atual " & docs(activeDoc).filePath & ", rc=" & Trim(Str(openRc)) & ", linha=" & Trim(Str(lineAfter)) & ", mapa='" & mapAfter & "')"
        Return 0
    End If

    ' Stability cycle: close command doc, reopen index, and open via Enter.
    CloseDocument(activeDoc)
    OpenMsxDictHelp()
    If LCase(docs(activeDoc).filePath) <> "msxdict:index" Then
        report = "SMOKE HELP FAIL: apos reabrir, indice nao ficou ativo (" & docs(activeDoc).filePath & ")"
        Return 0
    End If

    Dim enterLine As Integer = 0
    For i = 1 To docs(activeDoc).lineCount
        If Len(msxDictLineCommand(activeDoc, i)) > 0 Then
            If IsMsxTopicToken(msxDictLineCommand(activeDoc, i)) = 0 Then
                enterLine = i
                Exit For
            End If
        End If
    Next i
    If enterLine = 0 Then
        report = "SMOKE HELP FAIL: indice reaberto sem entradas"
        Return 0
    End If

    docs(activeDoc).cursorY = enterLine
    docs(activeDoc).cursorX = 1
    Dim enterKey As String = Chr(13)
    EditorHandleKey(enterKey, running, menuOpen)

    If Left(LCase(docs(activeDoc).filePath), 11) <> "msxdict:cmd" Then
        report = "SMOKE HELP FAIL: Enter no indice nao abriu verbete apos reabrir (" & docs(activeDoc).filePath & ")"
        Return 0
    End If

    ' Smoke do dicionario de referencia novo (piloto: BIOS Documentacao, sem grupos/anchors).
    OpenRefDictHelp("biosdoc")
    Dim refIdxDoc As Integer = activeDoc
    If Left(LCase(docs(refIdxDoc).filePath), 8) <> "refdict:" Then
        report = "SMOKE HELP FAIL: refdict biosdoc nao abriu indice (" & docs(refIdxDoc).filePath & ")"
        Return 0
    End If

    Dim refFirstLine As Integer = 0
    For i = 1 To docs(refIdxDoc).lineCount
        If Left(msxDictLineCommand(refIdxDoc, i), 7) = "RTOPIC:" Then
            refFirstLine = i
            Exit For
        End If
    Next i
    If refFirstLine = 0 Then
        report = "SMOKE HELP FAIL: refdict biosdoc sem topicos no indice"
        Return 0
    End If

    docs(refIdxDoc).cursorY = refFirstLine
    docs(refIdxDoc).cursorX = 1
    Dim refOpenRc As Integer = OpenMsxDictFromActiveIndexCursor()
    If refOpenRc = 0 Or Left(LCase(docs(activeDoc).filePath), 15) <> "refdict:biosdoc" Then
        report = "SMOKE HELP FAIL: RTOPIC nao abriu topico do refdict biosdoc (" & docs(activeDoc).filePath & ", rc=" & Trim(Str(refOpenRc)) & ")"
        Return 0
    End If
    If docs(activeDoc).lineCount < 2 Then
        report = "SMOKE HELP FAIL: topico do refdict biosdoc veio vazio"
        Return 0
    End If
    Dim biosdocLineCount As Integer = docs(activeDoc).lineCount

    ' Smoke do dicionario com Begin/L/Commit/AddAnchor (Red Book) - conta topicos,
    ' acha um com links e confere a secao "Ver tambem" resolvendo pelo menos 1 alvo.
    OpenRefDictHelp("redbook")
    Dim rbIdxDoc As Integer = activeDoc
    Dim rbTopicCount As Integer = 0
    Dim rbGroupHeaders As Integer = 0
    For i = 1 To docs(rbIdxDoc).lineCount
        If Left(msxDictLineCommand(rbIdxDoc, i), 7) = "RTOPIC:" Then rbTopicCount += 1
        If Left(LTrim(docs(rbIdxDoc).lines(i)), 1) = "{" Then rbGroupHeaders += 1
    Next i
    If rbTopicCount < 900 Or rbTopicCount > 1000 Then
        report = "SMOKE HELP FAIL: refdict redbook com contagem de topicos fora do esperado (" & Trim(Str(rbTopicCount)) & ")"
        Return 0
    End If
    If rbGroupHeaders < 8 Then
        report = "SMOKE HELP FAIL: refdict redbook com poucos grupos de capitulo (" & Trim(Str(rbGroupHeaders)) & ")"
        Return 0
    End If

    Dim rbLinkedTopic As Integer = 0
    Dim rbProbeMax As Integer = 40
    If rbProbeMax > rbTopicCount Then rbProbeMax = rbTopicCount
    Dim rbTopicIdx As Integer
    For rbTopicIdx = 1 To rbProbeMax
        LoadRefDictTopicIntoDocument(docs(rbIdxDoc), "redbook", rbTopicIdx)
        Dim j As Integer
        Dim hasSeeAlso As Integer = 0
        For j = 1 To docs(rbIdxDoc).lineCount
            If InStr(docs(rbIdxDoc).lines(j), "Ver tambem:") > 0 Then hasSeeAlso = -1 : Exit For
        Next j
        If hasSeeAlso <> 0 Then
            rbLinkedTopic = rbTopicIdx
            Exit For
        End If
    Next rbTopicIdx
    If rbLinkedTopic = 0 Then
        report = "SMOKE HELP FAIL: nenhum dos primeiros " & Trim(Str(rbProbeMax)) & " topicos do redbook produziu secao Ver tambem"
        Return 0
    End If

    ' Smoke do dicionario com grupo filtrado (msxmanuals nao deve trazer o bloco
    ' "MSX2 Technical Handbook" embutido no mesmo .pbi).
    OpenRefDictHelp("msxmanuals")
    Dim mmIdxDoc As Integer = activeDoc
    Dim mmTopicCount As Integer = 0
    For i = 1 To docs(mmIdxDoc).lineCount
        If Left(msxDictLineCommand(mmIdxDoc, i), 7) = "RTOPIC:" Then mmTopicCount += 1
        If InStr(docs(mmIdxDoc).lines(i), "MSX2 Technical Handbook") > 0 Then
            report = "SMOKE HELP FAIL: refdict msxmanuals nao filtrou o grupo duplicado do Handbook"
            Return 0
        End If
    Next i
    If mmTopicCount < 8 Or mmTopicCount > 12 Then
        report = "SMOKE HELP FAIL: refdict msxmanuals com contagem de topicos fora do esperado (" & Trim(Str(mmTopicCount)) & ")"
        Return 0
    End If

    ' Smoke do parser estilo Add (openMSX, sem Begin/L/Commit).
    OpenRefDictHelp("openmsx")
    Dim omIdxDoc As Integer = activeDoc
    Dim omTopicCount As Integer = 0
    For i = 1 To docs(omIdxDoc).lineCount
        If Left(msxDictLineCommand(omIdxDoc, i), 7) = "RTOPIC:" Then omTopicCount += 1
    Next i
    If omTopicCount < 50 Then
        report = "SMOKE HELP FAIL: refdict openmsx com poucos topicos (" & Trim(Str(omTopicCount)) & ")"
        Return 0
    End If

    ' Smoke rapido dos 3 refdicts restantes (mesmo parser ja provado acima).
    OpenRefDictHelp("th2handbook")
    Dim thTopicCount As Integer = 0
    For i = 1 To docs(activeDoc).lineCount
        If Left(msxDictLineCommand(activeDoc, i), 7) = "RTOPIC:" Then thTopicCount += 1
    Next i
    If thTopicCount < 1200 Or thTopicCount > 1400 Then
        report = "SMOKE HELP FAIL: refdict th2handbook com contagem de topicos fora do esperado (" & Trim(Str(thTopicCount)) & ")"
        Return 0
    End If

    OpenRefDictHelp("bioscalls")
    Dim bcTopicCount As Integer = 0
    For i = 1 To docs(activeDoc).lineCount
        If Left(msxDictLineCommand(activeDoc, i), 7) = "RTOPIC:" Then bcTopicCount += 1
    Next i
    If bcTopicCount < 10 Then
        report = "SMOKE HELP FAIL: refdict bioscalls com poucos topicos (" & Trim(Str(bcTopicCount)) & ")"
        Return 0
    End If

    OpenRefDictHelp("hardware")
    Dim hwTopicCount As Integer = 0
    For i = 1 To docs(activeDoc).lineCount
        If Left(msxDictLineCommand(activeDoc, i), 7) = "RTOPIC:" Then hwTopicCount += 1
    Next i
    If hwTopicCount < 10 Then
        report = "SMOKE HELP FAIL: refdict hardware com poucos topicos (" & Trim(Str(hwTopicCount)) & ")"
        Return 0
    End If

    ' Smoke dos 3 helps markdown simples (docs\help\*.md, rota dbhelp: ja existente).
    OpenHelpDocument("Nestor Basic", "dbhelp:NESTORBASIC|docs\help\nestorbasic.md")
    If docs(activeDoc).lineCount < 20 Then
        report = "SMOKE HELP FAIL: docs\help\nestorbasic.md nao carregou (" & Trim(Str(docs(activeDoc).lineCount)) & " linhas)"
        Return 0
    End If

    OpenHelpDocument("SEE Tracker", "dbhelp:SEETRACKER|docs\help\seetracker.md")
    If docs(activeDoc).lineCount < 20 Then
        report = "SMOKE HELP FAIL: docs\help\seetracker.md nao carregou (" & Trim(Str(docs(activeDoc).lineCount)) & " linhas)"
        Return 0
    End If

    OpenHelpDocument("MSXBAS2ROM", "dbhelp:MSXBAS2ROM|docs\help\msxbas2rom.md")
    If docs(activeDoc).lineCount < 20 Then
        report = "SMOKE HELP FAIL: docs\help\msxbas2rom.md nao carregou (" & Trim(Str(docs(activeDoc).lineCount)) & " linhas)"
        Return 0
    End If

    OpenHelpDocument("Editor", "dbhelp:EDITOR|docs\help\editor.md")
    If docs(activeDoc).lineCount < 15 Then
        report = "SMOKE HELP FAIL: docs\help\editor.md nao carregou (" & Trim(Str(docs(activeDoc).lineCount)) & " linhas)"
        Return 0
    End If

    OpenHelpDocument("Mamute Assembler", "dbhelp:MAMUTE|docs\help\mamute.md")
    If docs(activeDoc).lineCount < 100 Then
        report = "SMOKE HELP FAIL: docs\help\mamute.md nao carregou (" & Trim(Str(docs(activeDoc).lineCount)) & " linhas)"
        Return 0
    End If

    ' Confere que a acentuacao do .md (gravado em UTF-8 em disco) foi
    ' convertida pra bytes da codepage OEM ativa no console (860, definida
    ' em ConsoleInit), e nao ficou como bytes UTF-8 crus (que apareceriam
    ' bagunçados num Windows com locale em ingles - ver ConsoleUtf8ToActiveCp
    ' em console_win.bas). "e" com circunflexo em CP860 = Chr(136) (&H88),
    ' valor conferido de forma independente via .NET Encoding.GetEncoding(860).
    Dim accentFound As Integer = 0
    Dim accentLineIdx As Integer
    For accentLineIdx = 1 To docs(activeDoc).lineCount
        If InStr(docs(activeDoc).lines(accentLineIdx), "Refer" & Chr(&H88) & "ncia") > 0 Then
            accentFound = -1
            Exit For
        End If
    Next accentLineIdx
    If accentFound = 0 Then
        report = "SMOKE HELP FAIL: acentuacao de mamute.md nao foi convertida pra CP860 (esperava 'Refer' + Chr(136) + 'ncia' de 'Referencia' em alguma linha)"
        Return 0
    End If

    report = "SMOKE HELP OK: ESC modal->log, retorno Shift+F1, contextual PRINT, comando exclusivo MSX2+/FM (" & msx2Exclusive & "), topico de referencia, indice, clique e Enter para " & firstKeyword & ", refdict biosdoc (" & Trim(Str(biosdocLineCount)) & " linhas), redbook (" & Trim(Str(rbTopicCount)) & " topicos/" & Trim(Str(rbGroupHeaders)) & " grupos, Ver tambem OK), msxmanuals (" & Trim(Str(mmTopicCount)) & " topicos, sem duplicata), openmsx (" & Trim(Str(omTopicCount)) & " topicos), nestorbasic/seetracker/msxbas2rom/editor/mamute OK, th2handbook (" & Trim(Str(thTopicCount)) & "), bioscalls (" & Trim(Str(bcTopicCount)) & "), hardware (" & Trim(Str(hwTopicCount)) & ")"
    Return -1
End Function

' Diagnostico manual (--mamute-diag): le a configuracao REAL do msxide.db do
' usuario (nao um banco descartavel), mostra o que MamuteMemGrid tem gravado
' pra cada celula fisica, o mapeamento PAGE default calculado, e os
' primeiros 16 bytes de cada uma das 4 paginas apos Mamute_LoadPhysicalMemory
' - usado pra investigar "ROM configurada mas DM mostra so' zero".
Function EditorRunMamuteDiag(ByRef report As String) As Integer
    LoadMamuteMemConfig()

    Dim diagOut As String = ""
    Dim slot As Integer
    Dim subIdx As Integer
    Dim pageIdx As Integer

    diagOut &= "=== VRAM: " & Trim(Str(MamuteVramKB)) & "KB ===" & Chr(10)
    diagOut &= "=== Config fisica (MamuteMemGrid) - so celulas nao-vazias ===" & Chr(10)
    Dim anyCell As Integer = 0
    For slot = 0 To 3
        diagOut &= "Slot " & Trim(Str(slot)) & ": subslots=" & IIf(MamuteMemSubOn(slot) <> 0, "ligados", "desligados") & Chr(10)
        Dim maxSub As Integer = IIf(MamuteMemSubOn(slot) <> 0, 3, 0)
        For subIdx = 0 To maxSub
            For pageIdx = 0 To 3
                Dim ByRef cell As MamuteMemCell = MamuteMemGrid(slot, subIdx, pageIdx)
                If cell.cellType <> MAMUTE_CELL_NONE Then
                    anyCell = -1
                    diagOut &= "  Slot " & Trim(Str(slot)) & "." & Trim(Str(subIdx)) & " Pag." & Trim(Str(pageIdx)) & " = " & MamuteCellTypeLabel(cell.cellType) & " path=[" & cell.romPath & "] offset=" & Trim(Str(cell.romOffset))
                    If Len(cell.romPath) > 0 Then
                        Dim resolvedDiagPath As String = Mamute_ResolveRomPath(cell.romPath)
                        diagOut &= " resolvido=[" & resolvedDiagPath & "] Dir()=" & IIf(Dir(resolvedDiagPath) <> "", "ACHOU", "NAO ACHOU") & " CurDir=[" & CurDir() & "]"
                        If Dir(resolvedDiagPath) <> "" Then
                            Dim ff2 As Integer = FreeFile
                            Open resolvedDiagPath For Binary Access Read As #ff2
                            diagOut &= " TamanhoArquivo=" & Trim(Str(Lof(ff2)))
                            Close #ff2
                        End If
                    End If
                    diagOut &= Chr(10)
                End If
            Next pageIdx
        Next subIdx
    Next slot
    If anyCell = 0 Then diagOut &= "  (nenhuma celula configurada - tudo Vazio)" & Chr(10)

    SetMamuteDefaultPageMapping()
    diagOut &= "=== PAGE ativo calculado por SetMamuteDefaultPageMapping ===" & Chr(10)
    Dim p As Integer
    For p = 0 To 3
        diagOut &= "Pag." & Trim(Str(p)) & " = Slot " & Trim(Str(MamuteActiveSlot(p))) & "." & Trim(Str(MamuteActiveSub(p))) & Chr(10)
    Next p

    Mamute_LoadPhysicalMemory()

    diagOut &= "=== Primeiros 16 bytes de cada pagina (Mamute_ReadByte, PAGE ativo acima) ===" & Chr(10)
    Dim baseAddrs(0 To 3) As Integer
    baseAddrs(0) = &H0000 : baseAddrs(1) = &H4000 : baseAddrs(2) = &H8000 : baseAddrs(3) = &HC000
    For p = 0 To 3
        Dim lineText As String = "Pag." & Trim(Str(p)) & " (" & Hex(baseAddrs(p), 4) & "H): "
        Dim i As Integer
        For i = 0 To 15
            lineText &= Hex(Mamute_ReadByte(baseAddrs(p) + i), 2) & " "
        Next i
        diagOut &= lineText & Chr(10)
    Next p

    diagOut &= "=== Teste de escrita/leitura via Mamute_WriteByte/Mamute_ReadByte direto ===" & Chr(10)
    For p = 0 To 3
        Dim testAddr As Integer = baseAddrs(p)
        Dim canWrite As Integer = Mamute_CanWriteAt(testAddr)
        Mamute_WriteByte(testAddr, &H77)
        Dim readBack As Integer = Mamute_ReadByte(testAddr)
        diagOut &= "Pag." & Trim(Str(p)) & " (" & Hex(testAddr, 4) & "H): CanWrite=" & IIf(canWrite <> 0, "SIM(RAM)", "NAO(nao-RAM)") & " escreveu 77H, releu " & Hex(readBack, 2) & "H" & Chr(10)
    Next p

    diagOut &= "=== Teste via ExecuteMamuteCommand (M 8000 FF, depois DM 8000) ===" & Chr(10)
    Dim diagDoc As Document
    diagDoc.lineCount = 1
    diagDoc.lines(1) = ""
    ExecuteMamuteCommand(diagDoc, "M 8000 FF")
    ExecuteMamuteCommand(diagDoc, "DM 8000")
    Dim di As Integer
    For di = 1 To diagDoc.lineCount
        If Len(diagDoc.lines(di)) > 0 Then diagOut &= "  > " & diagDoc.lines(di) & Chr(10)
    Next di

    report = diagOut
    Return -1
End Function

Function EditorRunMamuteSmokeTest(ByRef report As String) As Integer
    report = ""

    ' Monta uma configuracao conhecida: Slot 0 sem sub-slots, ROM de 32KB nas
    ' paginas 0-1 (BIOS/BASIC); Slot 2 com sub-slots ligados, RAM na 2.3.
    Dim slot As Integer
    Dim subIdx As Integer
    Dim pageIdx As Integer
    For slot = 0 To 3
        MamuteMemSubOn(slot) = 0
        For subIdx = 0 To 3
            For pageIdx = 0 To 3
                MamuteMemGrid(slot, subIdx, pageIdx).cellType = MAMUTE_CELL_NONE
                MamuteMemGrid(slot, subIdx, pageIdx).romPath = ""
                MamuteMemGrid(slot, subIdx, pageIdx).romOffset = 0
            Next pageIdx
        Next subIdx
    Next slot

    MamuteMemGrid(0, 0, 0).cellType = MAMUTE_CELL_ROM
    MamuteMemGrid(0, 0, 0).romPath = "bios.rom"
    MamuteMemGrid(0, 0, 0).romOffset = 0
    MamuteMemGrid(0, 0, 1).cellType = MAMUTE_CELL_ROM
    MamuteMemGrid(0, 0, 1).romPath = "bios.rom"
    MamuteMemGrid(0, 0, 1).romOffset = 16384

    MamuteMemSubOn(2) = -1
    MamuteMemGrid(2, 3, 2).cellType = MAMUTE_CELL_RAM

    SaveMamuteMemConfig()

    ' Suja a memoria antes de reler, pra garantir que o load nao esta so
    ' "acertando por acidente" com o que ja estava la.
    For slot = 0 To 3
        MamuteMemSubOn(slot) = -1
        For subIdx = 0 To 3
            For pageIdx = 0 To 3
                MamuteMemGrid(slot, subIdx, pageIdx).cellType = MAMUTE_CELL_ROM
                MamuteMemGrid(slot, subIdx, pageIdx).romPath = "lixo"
                MamuteMemGrid(slot, subIdx, pageIdx).romOffset = 999
            Next pageIdx
        Next subIdx
    Next slot

    LoadMamuteMemConfig()

    If MamuteMemSubOn(0) <> 0 Then
        report = "SMOKE MAMUTE FAIL: Slot 0 deveria estar sem sub-slots apos reler"
        Return 0
    End If
    If MamuteMemGrid(0, 0, 0).cellType <> MAMUTE_CELL_ROM Or MamuteMemGrid(0, 0, 0).romPath <> "bios.rom" Or MamuteMemGrid(0, 0, 0).romOffset <> 0 Then
        report = "SMOKE MAMUTE FAIL: Slot 0 pagina 0 nao voltou como ROM bios.rom offset 0"
        Return 0
    End If
    If MamuteMemGrid(0, 0, 1).cellType <> MAMUTE_CELL_ROM Or MamuteMemGrid(0, 0, 1).romOffset <> 16384 Then
        report = "SMOKE MAMUTE FAIL: Slot 0 pagina 1 nao voltou como ROM offset 16384"
        Return 0
    End If
    If MamuteMemGrid(0, 0, 2).cellType <> MAMUTE_CELL_NONE Then
        report = "SMOKE MAMUTE FAIL: Slot 0 pagina 2 deveria ter voltado vazia"
        Return 0
    End If
    If MamuteMemSubOn(2) = 0 Then
        report = "SMOKE MAMUTE FAIL: Slot 2 deveria estar com sub-slots ligados apos reler"
        Return 0
    End If
    If MamuteMemGrid(2, 3, 2).cellType <> MAMUTE_CELL_RAM Then
        report = "SMOKE MAMUTE FAIL: Slot 2 sub 3 pagina 2 deveria ter voltado como RAM"
        Return 0
    End If
    If MamuteMemGrid(1, 0, 0).cellType <> MAMUTE_CELL_NONE Then
        report = "SMOKE MAMUTE FAIL: Slot 1 (nunca tocado) deveria ter voltado vazio"
        Return 0
    End If

    ' Testa o preenchimento automatico de AssignMamuteRomFile com uma ROM de
    ' 32KB de verdade (BIOS -> pag. seguinte vira BASIC; BASIC -> pag.
    ' anterior vira BIOS; EXTBIOS nao particiona).
    Dim tempRomPath As String = Environ("TEMP") & Chr(92) & "msxide_mamute_smoke_rom.bin"
    Dim romFf As Integer = FreeFile
    Open tempRomPath For Output As #romFf
    Dim fillLine As String = String(1024, "X")
    Dim fi As Integer
    For fi = 1 To 32
        Print #romFf, fillLine;
    Next fi
    Close #romFf

    For slot = 0 To 3
        MamuteMemSubOn(slot) = 0
        For subIdx = 0 To 3
            For pageIdx = 0 To 3
                MamuteMemGrid(slot, subIdx, pageIdx).cellType = MAMUTE_CELL_NONE
                MamuteMemGrid(slot, subIdx, pageIdx).romPath = ""
                MamuteMemGrid(slot, subIdx, pageIdx).romOffset = 0
            Next pageIdx
        Next subIdx
    Next slot

    Dim assignMsgTest As String
    AssignMamuteRomFile(0, 0, 0, MAMUTE_CELL_BIOS, tempRomPath, assignMsgTest)
    If MamuteMemGrid(0, 0, 0).cellType <> MAMUTE_CELL_BIOS Or MamuteMemGrid(0, 0, 0).romOffset <> 0 Then
        Kill tempRomPath
        report = "SMOKE MAMUTE FAIL: AssignMamuteRomFile(BIOS) nao marcou a pag.0 como BIOS offset 0"
        Return 0
    End If
    If MamuteMemGrid(0, 0, 1).cellType <> MAMUTE_CELL_BASIC Or MamuteMemGrid(0, 0, 1).romOffset <> 16384 Then
        Kill tempRomPath
        report = "SMOKE MAMUTE FAIL: AssignMamuteRomFile(BIOS) nao preencheu a pag.1 seguinte como BASIC offset 16384"
        Return 0
    End If

    Dim assignMsgTest2 As String
    AssignMamuteRomFile(1, 0, 3, MAMUTE_CELL_BASIC, tempRomPath, assignMsgTest2)
    If MamuteMemGrid(1, 0, 3).cellType <> MAMUTE_CELL_BASIC Or MamuteMemGrid(1, 0, 3).romOffset <> 16384 Then
        Kill tempRomPath
        report = "SMOKE MAMUTE FAIL: AssignMamuteRomFile(BASIC) nao marcou a pag.3 como BASIC offset 16384"
        Return 0
    End If
    If MamuteMemGrid(1, 0, 2).cellType <> MAMUTE_CELL_BIOS Or MamuteMemGrid(1, 0, 2).romOffset <> 0 Then
        Kill tempRomPath
        report = "SMOKE MAMUTE FAIL: AssignMamuteRomFile(BASIC) nao preencheu a pag.2 anterior como BIOS offset 0 (inverso da BIOS)"
        Return 0
    End If

    Dim assignMsgTest3 As String
    AssignMamuteRomFile(3, 0, 1, MAMUTE_CELL_EXTBIOS, tempRomPath, assignMsgTest3)
    If MamuteMemGrid(3, 0, 1).cellType <> MAMUTE_CELL_EXTBIOS Or MamuteMemGrid(3, 0, 1).romOffset <> 0 Then
        Kill tempRomPath
        report = "SMOKE MAMUTE FAIL: AssignMamuteRomFile(EXTBIOS) nao marcou a pag.1 como EXTBIOS offset 0"
        Return 0
    End If
    If MamuteMemGrid(3, 0, 0).cellType <> MAMUTE_CELL_NONE Or MamuteMemGrid(3, 0, 2).cellType <> MAMUTE_CELL_NONE Then
        Kill tempRomPath
        report = "SMOKE MAMUTE FAIL: AssignMamuteRomFile(EXTBIOS) nao deveria particionar paginas vizinhas"
        Return 0
    End If

    ' Tipo ROM tambem particiona (pag. atual continua ROM, a seguinte vira
    ' BASIC), disparado a partir de qualquer arquivo maior que 16KB - nao so
    ' os 32KB exatos.
    Dim assignMsgTest4 As String
    AssignMamuteRomFile(2, 0, 0, MAMUTE_CELL_ROM, tempRomPath, assignMsgTest4)
    If MamuteMemGrid(2, 0, 0).cellType <> MAMUTE_CELL_ROM Or MamuteMemGrid(2, 0, 0).romOffset <> 0 Then
        Kill tempRomPath
        report = "SMOKE MAMUTE FAIL: AssignMamuteRomFile(ROM) nao manteve a pag.0 como ROM offset 0"
        Return 0
    End If
    If MamuteMemGrid(2, 0, 1).cellType <> MAMUTE_CELL_BASIC Or MamuteMemGrid(2, 0, 1).romOffset <> 16384 Then
        Kill tempRomPath
        report = "SMOKE MAMUTE FAIL: AssignMamuteRomFile(ROM) nao preencheu a pag.1 seguinte como BASIC offset 16384"
        Return 0
    End If

    Kill tempRomPath

    ' Regressao: pagina BASIC "orfa" (cellType=BASIC mas romPath vazio -
    ' config antiga/dessincronizada, o bug relatado onde a BIOS estava
    ' configurada certinho mas a pagina BASIC vizinha ficou sem arquivo
    ' proprio porque o split automatico nao rodou na hora certa, ex.: nome de
    ' arquivo digitado errado na hora, corrigido so' depois) tem que herdar o
    ' arquivo da BIOS vizinha (mesmo slot/sub-slot, pagina anterior) na
    ' leitura fisica (Mamute_LoadPhysicalMemory), offset 16384.
    Dim tempRomPathB As String = Environ("TEMP") & Chr(92) & "msxide_mamute_smoke_rom_orphan.bin"
    Dim romFfB As Integer = FreeFile
    Open tempRomPathB For Binary Access Write As #romFfB
    Dim orphanBuf(0 To 32767) As UByte
    Dim orphanIdx As Integer
    For orphanIdx = 0 To 16383
        orphanBuf(orphanIdx) = &HAA
    Next orphanIdx
    For orphanIdx = 16384 To 32767
        orphanBuf(orphanIdx) = &HBB
    Next orphanIdx
    Put #romFfB, 1, orphanBuf()
    Close #romFfB

    MamuteMemGrid(0, 1, 0).cellType = MAMUTE_CELL_BIOS
    MamuteMemGrid(0, 1, 0).romPath = tempRomPathB
    MamuteMemGrid(0, 1, 0).romOffset = 0
    MamuteMemGrid(0, 1, 1).cellType = MAMUTE_CELL_BASIC
    MamuteMemGrid(0, 1, 1).romPath = ""
    MamuteMemGrid(0, 1, 1).romOffset = 0

    Mamute_LoadPhysicalMemory()

    If MamuteMem(0, 1, 0, 0) <> &HAA Then
        Kill tempRomPathB
        report = "SMOKE MAMUTE FAIL: pagina BIOS nao carregou o arquivo temporario (teste de pagina BASIC orfa)"
        Return 0
    End If
    If MamuteMem(0, 1, 1, 0) <> &HBB Then
        Kill tempRomPathB
        report = "SMOKE MAMUTE FAIL: pagina BASIC orfa (sem romPath proprio) nao herdou os dados da BIOS vizinha (offset 16384)"
        Return 0
    End If

    Kill tempRomPathB

    ' Endereco de cada pagina de 16KB no espaco Z80 de 64KB.
    If MamutePageAddrRange(0) <> "0000-3FFF" Or MamutePageAddrRange(1) <> "4000-7FFF" Or MamutePageAddrRange(2) <> "8000-BFFF" Or MamutePageAddrRange(3) <> "C000-FFFF" Then
        report = "SMOKE MAMUTE FAIL: MamutePageAddrRange nao bateu com os enderecos Z80 esperados"
        Return 0
    End If

    ' Round-trip do tamanho de VRAM.
    MamuteVramKB = 64
    SaveMamuteMemConfig()
    MamuteVramKB = 999
    LoadMamuteMemConfig()
    If MamuteVramKB <> 64 Then
        report = "SMOKE MAMUTE FAIL: VRAM nao voltou como 64KB apos reler"
        Return 0
    End If
    If NextMamuteVramSize(16) <> 32 Or NextMamuteVramSize(32) <> 64 Or NextMamuteVramSize(64) <> 128 Or NextMamuteVramSize(128) <> 192 Or NextMamuteVramSize(192) <> 16 Then
        report = "SMOKE MAMUTE FAIL: ciclo de tamanhos de VRAM (16/32/64/128/192) quebrado"
        Return 0
    End If

    ' Testa SetMamuteDefaultPageMapping: Slot 0 tem BIOS/BASIC nas pag.0-1 (do
    ' teste acima), Slot 2 sub 3 tem RAM nas pag.2-3 -> deve virar o PAGE
    ' default (pag.0-1 = Slot 0, pag.2-3 = Slot 2.3).
    MamuteMemSubOn(2) = -1
    MamuteMemGrid(2, 3, 2).cellType = MAMUTE_CELL_RAM
    MamuteMemGrid(2, 3, 3).cellType = MAMUTE_CELL_RAM

    SetMamuteDefaultPageMapping()

    If MamuteActiveSlot(0) <> 0 Or MamuteActiveSlot(1) <> 0 Then
        report = "SMOKE MAMUTE FAIL: PAGE default deveria ter pag.0/1 no Slot 0 (BIOS/BASIC)"
        Return 0
    End If
    If MamuteActiveSlot(2) <> 2 Or MamuteActiveSub(2) <> 3 Then
        report = "SMOKE MAMUTE FAIL: PAGE default deveria ter pag.2 no Slot 2.3 (RAM)"
        Return 0
    End If
    If MamuteActiveSlot(3) <> 2 Or MamuteActiveSub(3) <> 3 Then
        report = "SMOKE MAMUTE FAIL: PAGE default deveria ter pag.3 no Slot 2.3 (RAM)"
        Return 0
    End If

    ' Testa o comando de terminal PAGE (ExecuteMamuteCommand) direto, sem
    ' passar pelo teclado/console: "PAGE" sozinho joga as 4 paginas pro slot
    ' com RAM; "PAGE X[,Y][,Z][,K]" muda so as paginas informadas, mantendo
    ' as outras; "PAGE ?" imprime o dump completo; argumento fora de 0-3 vira
    ' erro sem mudar nada.
    For slot = 0 To 3
        MamuteMemSubOn(slot) = 0
        For subIdx = 0 To 3
            For pageIdx = 0 To 3
                MamuteMemGrid(slot, subIdx, pageIdx).cellType = MAMUTE_CELL_NONE
                MamuteMemGrid(slot, subIdx, pageIdx).romPath = ""
                MamuteMemGrid(slot, subIdx, pageIdx).romOffset = 0
            Next pageIdx
        Next subIdx
    Next slot
    MamuteMemGrid(1, 0, 0).cellType = MAMUTE_CELL_RAM
    MamuteMemGrid(1, 0, 1).cellType = MAMUTE_CELL_RAM
    MamuteMemGrid(1, 0, 2).cellType = MAMUTE_CELL_RAM
    MamuteMemGrid(1, 0, 3).cellType = MAMUTE_CELL_RAM
    SaveMamuteMemConfig()

    Dim testDoc As Document
    testDoc.lineCount = 1
    testDoc.lines(1) = ""
    Dim pp2 As Integer
    For pp2 = 0 To 3
        MamuteActiveSlot(pp2) = 0
        MamuteActiveSub(pp2) = 0
    Next pp2

    ExecuteMamuteCommand(testDoc, "PAGE")
    If MamuteActiveSlot(0) <> 1 Or MamuteActiveSlot(1) <> 1 Or MamuteActiveSlot(2) <> 1 Or MamuteActiveSlot(3) <> 1 Then
        report = "SMOKE MAMUTE FAIL: PAGE (sem args) deveria mapear as 4 paginas pro Slot 1 (RAM)"
        Return 0
    End If

    ExecuteMamuteCommand(testDoc, "PAGE 2")
    If MamuteActiveSlot(0) <> 2 Then
        report = "SMOKE MAMUTE FAIL: PAGE 2 deveria mudar so a pag.0 pro Slot 2"
        Return 0
    End If
    If MamuteActiveSlot(1) <> 1 Or MamuteActiveSlot(2) <> 1 Or MamuteActiveSlot(3) <> 1 Then
        report = "SMOKE MAMUTE FAIL: PAGE 2 nao deveria mexer nas pags.1-3"
        Return 0
    End If

    ExecuteMamuteCommand(testDoc, "PAGE ,,2")
    If MamuteActiveSlot(2) <> 2 Then
        report = "SMOKE MAMUTE FAIL: PAGE ,,2 deveria mudar so a pag.2 pro Slot 2"
        Return 0
    End If
    If MamuteActiveSlot(0) <> 2 Or MamuteActiveSlot(1) <> 1 Or MamuteActiveSlot(3) <> 1 Then
        report = "SMOKE MAMUTE FAIL: PAGE ,,2 nao deveria mexer nas pags.0,1,3"
        Return 0
    End If

    Dim linesBeforeBad As Integer = testDoc.lineCount
    ExecuteMamuteCommand(testDoc, "PAGE 9")
    If testDoc.lineCount <> linesBeforeBad + 1 Or InStr(testDoc.lines(testDoc.lineCount), "ARGUMENTO INVALIDO") = 0 Then
        report = "SMOKE MAMUTE FAIL: PAGE 9 deveria reportar ?ARGUMENTO INVALIDO sem mudar nada"
        Return 0
    End If
    If MamuteActiveSlot(0) <> 2 Then
        report = "SMOKE MAMUTE FAIL: PAGE 9 (invalido) nao deveria ter mudado a pag.0"
        Return 0
    End If

    Dim linesBeforeDump As Integer = testDoc.lineCount
    ExecuteMamuteCommand(testDoc, "PAGE ?")
    If testDoc.lineCount < linesBeforeDump + 5 Then
        report = "SMOKE MAMUTE FAIL: PAGE ? deveria imprimir o dump completo (varias linhas)"
        Return 0
    End If

    For slot = 0 To 3
        For subIdx = 0 To 3
            For pageIdx = 0 To 3
                MamuteMemGrid(slot, subIdx, pageIdx).cellType = MAMUTE_CELL_NONE
            Next pageIdx
        Next subIdx
    Next slot
    SaveMamuteMemConfig()
    Dim linesBeforeNoRam As Integer = testDoc.lineCount
    ExecuteMamuteCommand(testDoc, "PAGE")
    If testDoc.lineCount <> linesBeforeNoRam + 1 Or InStr(testDoc.lines(testDoc.lineCount), "SEM RAM") = 0 Then
        report = "SMOKE MAMUTE FAIL: PAGE sem RAM configurada deveria reportar ?SEM RAM CONFIGURADA"
        Return 0
    End If

    ' Testa o disassembler Z80 (MamuteDisasmLine) contra os proprios exemplos
    ' verbatim do HELP (PUSH HL / CALL 5439H / LD B,H) mais alguns casos que
    ' cobrem prefixos DD/CB/ED e desvio relativo.
    MamuteActiveSlot(0) = 0 : MamuteActiveSub(0) = 0
    MamuteMem(0, 0, 0, &H100) = &HE5              ' PUSH HL
    MamuteMem(0, 0, 0, &H101) = &HCD               ' CALL 5439H
    MamuteMem(0, 0, 0, &H102) = &H39
    MamuteMem(0, 0, 0, &H103) = &H54
    MamuteMem(0, 0, 0, &H104) = &H44               ' LD B,H
    MamuteMem(0, 0, 0, &H105) = &HDD               ' LD IX,4000H
    MamuteMem(0, 0, 0, &H106) = &H21
    MamuteMem(0, 0, 0, &H107) = &H00
    MamuteMem(0, 0, 0, &H108) = &H40
    MamuteMem(0, 0, 0, &H109) = &HCB               ' RLC B
    MamuteMem(0, 0, 0, &H10A) = &H00
    MamuteMem(0, 0, 0, &H10B) = &HED               ' LDIR
    MamuteMem(0, 0, 0, &H10C) = &HB0
    MamuteMem(0, 0, 0, &H10D) = &H18               ' JR $+0 (desloc -2 -> volta pro proprio JR)
    MamuteMem(0, 0, 0, &H10E) = &HFE
    MamuteMem(0, 0, 0, &H10F) = &HDD               ' BIT 0,(IX+05H)
    MamuteMem(0, 0, 0, &H110) = &HCB
    MamuteMem(0, 0, 0, &H111) = &H05
    MamuteMem(0, 0, 0, &H112) = &H46

    Dim disasmLen As Integer
    Dim disasmText As String

    MamuteDisasmOne(&H100, disasmLen, disasmText)
    If disasmLen <> 1 Or disasmText <> "PUSH HL" Then
        report = "SMOKE MAMUTE FAIL: disassembler E5 deveria ser PUSH HL/1 byte, veio '" & disasmText & "'/" & Trim(Str(disasmLen))
        Return 0
    End If

    MamuteDisasmOne(&H101, disasmLen, disasmText)
    If disasmLen <> 3 Or disasmText <> "CALL 5439H" Then
        report = "SMOKE MAMUTE FAIL: disassembler CD 39 54 deveria ser CALL 5439H/3 bytes, veio '" & disasmText & "'/" & Trim(Str(disasmLen))
        Return 0
    End If

    MamuteDisasmOne(&H104, disasmLen, disasmText)
    If disasmLen <> 1 Or disasmText <> "LD B,H" Then
        report = "SMOKE MAMUTE FAIL: disassembler 44 deveria ser LD B,H/1 byte, veio '" & disasmText & "'/" & Trim(Str(disasmLen))
        Return 0
    End If

    MamuteDisasmOne(&H105, disasmLen, disasmText)
    If disasmLen <> 4 Or disasmText <> "LD IX,4000H" Then
        report = "SMOKE MAMUTE FAIL: disassembler DD 21 00 40 deveria ser LD IX,4000H/4 bytes, veio '" & disasmText & "'/" & Trim(Str(disasmLen))
        Return 0
    End If

    MamuteDisasmOne(&H109, disasmLen, disasmText)
    If disasmLen <> 2 Or disasmText <> "RLC B" Then
        report = "SMOKE MAMUTE FAIL: disassembler CB 00 deveria ser RLC B/2 bytes, veio '" & disasmText & "'/" & Trim(Str(disasmLen))
        Return 0
    End If

    MamuteDisasmOne(&H10B, disasmLen, disasmText)
    If disasmLen <> 2 Or disasmText <> "LDIR" Then
        report = "SMOKE MAMUTE FAIL: disassembler ED B0 deveria ser LDIR/2 bytes, veio '" & disasmText & "'/" & Trim(Str(disasmLen))
        Return 0
    End If

    MamuteDisasmOne(&H10D, disasmLen, disasmText)
    If disasmLen <> 2 Or disasmText <> "JR 010DH" Then
        report = "SMOKE MAMUTE FAIL: disassembler 18 FE deveria ser JR 010DH (salta pra si mesmo)/2 bytes, veio '" & disasmText & "'/" & Trim(Str(disasmLen))
        Return 0
    End If

    MamuteDisasmOne(&H10F, disasmLen, disasmText)
    If disasmLen <> 4 Or disasmText <> "BIT 0,(IX+05H)" Then
        report = "SMOKE MAMUTE FAIL: disassembler DD CB 05 46 deveria ser BIT 0,(IX+05H)/4 bytes, veio '" & disasmText & "'/" & Trim(Str(disasmLen))
        Return 0
    End If

    If MamuteDisasmLine(&H100) <> "0100  E5           PUSH HL" Then
        report = "SMOKE MAMUTE FAIL: MamuteDisasmLine nao bateu com o formato de linha esperado, veio '" & MamuteDisasmLine(&H100) & "'"
        Return 0
    End If

    ' Testa os comandos de terminal que so' precisam de memoria simulada (sem
    ' dialogo de arquivo): F, T, MS, SH (bytes/curinga/texto), C+D, G, X.
    activeDoc = 1
    Mamute_ResetRegs()
    MamuteMemGrid(0, 0, 0).cellType = MAMUTE_CELL_RAM
    MamuteActiveSlot(0) = 0 : MamuteActiveSub(0) = 0

    ExecuteMamuteCommand(testDoc, "F 0100,010F,AA")
    If Mamute_ReadByte(&H100) <> &HAA Or Mamute_ReadByte(&H10F) <> &HAA Then
        report = "SMOKE MAMUTE FAIL: F 0100,010F,AA nao preencheu o bloco com AA"
        Return 0
    End If

    ExecuteMamuteCommand(testDoc, "T 0100,010F,0200")
    If Mamute_ReadByte(&H200) <> &HAA Or Mamute_ReadByte(&H20F) <> &HAA Then
        report = "SMOKE MAMUTE FAIL: T 0100,010F,0200 nao copiou o bloco pra 0200"
        Return 0
    End If

    ExecuteMamuteCommand(testDoc, "MS 0300,,'AB")
    If Mamute_ReadByte(&H300) <> Asc("A") Or Mamute_ReadByte(&H301) <> Asc("B") Then
        report = "SMOKE MAMUTE FAIL: MS 0300,,'AB nao gravou 'AB' em 0300"
        Return 0
    End If

    Dim linesBeforeSh As Integer = testDoc.lineCount
    ExecuteMamuteCommand(testDoc, "SH 0300,41,42")
    If testDoc.lineCount <> linesBeforeSh + 1 Or testDoc.lines(testDoc.lineCount) <> "ACHADO EM 0300H" Then
        report = "SMOKE MAMUTE FAIL: SH 0300,41,42 deveria achar em 0300H, veio '" & testDoc.lines(testDoc.lineCount) & "'"
        Return 0
    End If

    ExecuteMamuteCommand(testDoc, "SH 0300,,42")
    If testDoc.lines(testDoc.lineCount) <> "ACHADO EM 0300H" Then
        report = "SMOKE MAMUTE FAIL: SH 0300,,42 (byte curinga) deveria achar em 0300H, veio '" & testDoc.lines(testDoc.lineCount) & "'"
        Return 0
    End If

    ExecuteMamuteCommand(testDoc, "SH 0300,'AB")
    If testDoc.lines(testDoc.lineCount) <> "ACHADO EM 0300H DESLOC +00H" Then
        report = "SMOKE MAMUTE FAIL: SH 0300,'AB (modo texto) deveria achar em 0300H deslocamento +00H, veio '" & testDoc.lines(testDoc.lineCount) & "'"
        Return 0
    End If

    ExecuteMamuteCommand(testDoc, "C 1")
    If MamuteDisplayMode <> 1 Or testDoc.lines(testDoc.lineCount) <> "MODO 1: HEXA+ASCII, 16 BYTES/LINHA" Then
        report = "SMOKE MAMUTE FAIL: C 1 nao selecionou o modo 1 corretamente"
        Return 0
    End If

    ExecuteMamuteCommand(testDoc, "D 0100,0107")
    If Left(testDoc.lines(testDoc.lineCount), 30) <> "0100: AA AA AA AA AA AA AA AA " Then
        report = "SMOKE MAMUTE FAIL: D 0100,0107 nao bateu com o dump esperado, veio '" & testDoc.lines(testDoc.lineCount) & "'"
        Return 0
    End If

    ExecuteMamuteCommand(testDoc, "G 4000")
    If testDoc.lines(testDoc.lineCount - 1) <> "G 4000H" Then
        report = "SMOKE MAMUTE FAIL: G 4000 deveria confirmar 'G 4000H', veio '" & testDoc.lines(testDoc.lineCount - 1) & "'"
        Return 0
    End If
    ExecuteMamuteCommand(testDoc, "G ZZZZ")
    If testDoc.lines(testDoc.lineCount) <> "?ERRO DE SINTAXE" Then
        report = "SMOKE MAMUTE FAIL: G ZZZZ (endereco invalido) deveria dar ?ERRO DE SINTAXE"
        Return 0
    End If

    ExecuteMamuteCommand(testDoc, "X")
    If testDoc.lines(testDoc.lineCount - 1) <> "AF=0000 BC=0000 DE=0000 HL=0000" Or testDoc.lines(testDoc.lineCount) <> "IX=0000 IY=0000 SP=0000" Then
        report = "SMOKE MAMUTE FAIL: X (sem args) deveria despejar os 7 registradores zerados"
        Return 0
    End If

    ExecuteMamuteCommand(testDoc, "X BC")
    If MamuteXWalking(activeDoc) <> 1 Or MamuteXRegName(MamuteXWalking(activeDoc), MamuteXWalkIdx(activeDoc)) <> "BC" Then
        report = "SMOKE MAMUTE FAIL: X BC deveria entrar no modo de caminhada no par BC"
        Return 0
    End If
    Dim xWalkVal As String = "1234"
    Mamute_ContinueXWalk(testDoc, xWalkVal)
    If MamuteRegBC <> &H1234 Then
        report = "SMOKE MAMUTE FAIL: X BC + '1234' deveria gravar BC=1234H, veio " & Hex(MamuteRegBC, 4)
        Return 0
    End If
    If MamuteXWalking(activeDoc) <> 1 Or MamuteXRegName(MamuteXWalking(activeDoc), MamuteXWalkIdx(activeDoc)) <> "DE" Then
        report = "SMOKE MAMUTE FAIL: apos editar BC, a caminhada deveria avancar pro proximo par (DE)"
        Return 0
    End If
    Dim xWalkBlank As String = ""
    Dim walkStep As Integer
    For walkStep = 1 To 5
        Mamute_ContinueXWalk(testDoc, xWalkBlank)
    Next walkStep
    If MamuteXWalking(activeDoc) <> 0 Then
        report = "SMOKE MAMUTE FAIL: a caminhada de X deveria terminar sozinha apos passar por todos os pares"
        Return 0
    End If

    ' Testa que M/S/MS/T/F avisam quando o destino nao e RAM agora (bug real
    ' relatado: escrita silenciosa numa pagina Vazia/ROM deixava parecer que
    ' o comando nao fez nada, sem explicar por que).
    MamuteMemGrid(1, 0, 0).cellType = MAMUTE_CELL_NONE
    MamuteActiveSlot(1) = 1 : MamuteActiveSub(1) = 0
    ExecuteMamuteCommand(testDoc, "M 4000 FF")
    If InStr(testDoc.lines(testDoc.lineCount), "AVISO") = 0 Then
        report = "SMOKE MAMUTE FAIL: M numa pagina nao-RAM deveria avisar que a escrita nao teve efeito"
        Return 0
    End If
    If Mamute_ReadByte(&H4000) <> 0 Then
        report = "SMOKE MAMUTE FAIL: M numa pagina nao-RAM nao deveria ter alterado o byte"
        Return 0
    End If

    ' Testa a regressao real desta sessao: EnsureCursorVisible (chamada a
    ' cada tecla em EditorHandleKey) nao pode "puxar" a rolagem do terminal
    ' de volta pro topo depois de um comando encher a tela - o terminal so'
    ' usa d.scrollY (via AppendMamuteLine), nunca d.cursorX/d.cursorY.
    EditorCreateMamuteTerm()
    Dim mamDocIdx As Integer = docCount
    Dim runningDummy As Integer = 1
    Dim menuOpenDummy As Integer = 0
    Dim enterKey As String = Chr(13)
    Dim scrollStep As Integer
    For scrollStep = 1 To 40
        mamuteInputBuf(mamDocIdx) = "PAGE ?"
        EditorHandleKey(enterKey, runningDummy, menuOpenDummy)
    Next scrollStep
    Dim expectedScrollY As Integer = GetMaxScrollY(docs(mamDocIdx))
    If expectedScrollY <= 0 Then
        report = "SMOKE MAMUTE FAIL: teste de rolagem nao encheu a tela o suficiente pra ser um teste valido"
        Return 0
    End If
    If docs(mamDocIdx).scrollY <> expectedScrollY Then
        report = "SMOKE MAMUTE FAIL: apos Enter enchendo a tela, scrollY=" & Trim(Str(docs(mamDocIdx).scrollY)) & " deveria ser " & Trim(Str(expectedScrollY)) & " (EnsureCursorVisible prendendo a rolagem no topo)"
        Return 0
    End If

    ' Testa o editor interativo de memoria do comando M (grade de 128 bytes)
    ' fim-a-fim, via EditorHandleKey de verdade (mesmo mamDocIdx/terminal real
    ' do teste de rolagem acima) - pedido explicito: "M <endereco>" sozinho
    ' deve abrir uma grade editavel com cursor na 1a celula, setas/PgUp/PgDn
    ' navegando, digitos hexa gravando e avancando sozinhos, ENTER avancando
    ' SEM gravar, e ESC encerrando so' a edicao (sem fechar o msxIDE inteiro -
    ' o Esc "global" de HandleEditorKey roda bem antes do isMamuteTerm normal).
    MamuteMemGrid(2, 0, 2).cellType = MAMUTE_CELL_RAM
    MamuteActiveSlot(2) = 2 : MamuteActiveSub(2) = 0
    Mamute_WriteByte(&H8000, 0)
    Mamute_WriteByte(&H8001, 0)

    mamuteInputBuf(mamDocIdx) = "M 8000"
    EditorHandleKey(enterKey, runningDummy, menuOpenDummy)
    If mamuteMEditActive(mamDocIdx) = 0 Then
        report = "SMOKE MAMUTE FAIL: M <endereco> deveria abrir o editor de grade de 128 bytes"
        Return 0
    End If
    If mamuteMEditBaseAddr(mamDocIdx) <> &H8000 Or mamuteMEditCursorRow(mamDocIdx) <> 0 Or mamuteMEditCursorCol(mamDocIdx) <> 0 Then
        report = "SMOKE MAMUTE FAIL: M 8000 deveria abrir a grade com BaseAddr=8000H e cursor na 1a celula"
        Return 0
    End If

    Dim keyF As String = "F"
    EditorHandleKey(keyF, runningDummy, menuOpenDummy)
    If mamuteMEditNibbleStage(mamDocIdx) = 0 Or mamuteMEditPendingHigh(mamDocIdx) <> 15 Then
        report = "SMOKE MAMUTE FAIL: 1o digito hexa (F) na grade deveria ficar pendente como nibble alto"
        Return 0
    End If
    EditorHandleKey(keyF, runningDummy, menuOpenDummy)
    If Mamute_ReadByte(&H8000) <> &HFF Then
        report = "SMOKE MAMUTE FAIL: 2 digitos hexa (FF) na grade deveriam gravar o byte 8000H=FFH, veio " & Hex(Mamute_ReadByte(&H8000), 2)
        Return 0
    End If
    If mamuteMEditNibbleStage(mamDocIdx) <> 0 Or mamuteMEditCursorCol(mamDocIdx) <> 1 Then
        report = "SMOKE MAMUTE FAIL: apos completar um byte, o cursor deveria avancar sozinho pra proxima coluna"
        Return 0
    End If

    EditorHandleKey(enterKey, runningDummy, menuOpenDummy)
    If mamuteMEditCursorCol(mamDocIdx) <> 2 Then
        report = "SMOKE MAMUTE FAIL: ENTER na grade deveria avancar o cursor sem gravar"
        Return 0
    End If
    If Mamute_ReadByte(&H8001) <> 0 Then
        report = "SMOKE MAMUTE FAIL: ENTER na grade nao deveria ter alterado o byte pulado"
        Return 0
    End If

    Dim pgDnKey As String = Chr(0) & Chr(81)
    Dim pgUpKey As String = Chr(0) & Chr(73)
    EditorHandleKey(pgDnKey, runningDummy, menuOpenDummy)
    If mamuteMEditBaseAddr(mamDocIdx) <> &H8080 Then
        report = "SMOKE MAMUTE FAIL: PgDn na grade deveria avancar 128 bytes (8080H), veio " & Hex(mamuteMEditBaseAddr(mamDocIdx), 4)
        Return 0
    End If
    EditorHandleKey(pgUpKey, runningDummy, menuOpenDummy)
    If mamuteMEditBaseAddr(mamDocIdx) <> &H8000 Then
        report = "SMOKE MAMUTE FAIL: PgUp na grade deveria voltar 128 bytes (8000H), veio " & Hex(mamuteMEditBaseAddr(mamDocIdx), 4)
        Return 0
    End If

    mamuteMEditCursorRow(mamDocIdx) = 15
    mamuteMEditCursorCol(mamDocIdx) = 7
    Dim rightKey As String = Chr(0) & Chr(77)
    EditorHandleKey(rightKey, runningDummy, menuOpenDummy)
    If mamuteMEditBaseAddr(mamDocIdx) <> &H8080 Or mamuteMEditCursorRow(mamDocIdx) <> 0 Or mamuteMEditCursorCol(mamDocIdx) <> 0 Then
        report = "SMOKE MAMUTE FAIL: seta direita na ultima celula da tela deveria rolar pra pagina seguinte (8080H) e voltar o cursor pro inicio"
        Return 0
    End If

    Dim escKey As String = Chr(27)
    EditorHandleKey(escKey, runningDummy, menuOpenDummy)
    If mamuteMEditActive(mamDocIdx) <> 0 Then
        report = "SMOKE MAMUTE FAIL: ESC deveria encerrar a edicao da grade (mamuteMEditActive continuou ligado)"
        Return 0
    End If
    If runningDummy = 0 Then
        report = "SMOKE MAMUTE FAIL: ESC dentro da grade nao deveria fechar o msxIDE inteiro (running virou 0)"
        Return 0
    End If

    ' Testa o comando EDIT (editor de linhas do programa-fonte Z80, estilo
    ' ZX-81) fim-a-fim, via EditorHandleKey de verdade (mesmo padrao dos
    ' testes acima).
    Mamute_AsmNew()
    EditorCreateMamuteEdit()
    Dim editDocIdx As Integer = docCount

    mamuteInputBuf(editDocIdx) = "10 START: LD HL,100H ;comeco"
    EditorHandleKey(enterKey, runningDummy, menuOpenDummy)
    If MamuteAsmProgramCount <> 1 Then
        report = "SMOKE MAMUTE FAIL: EDIT nao gravou a 1a linha do programa"
        Return 0
    End If
    If MamuteAsmProgram(1).lineNum <> 10 Or MamuteAsmProgram(1).labelText <> "START" Or MamuteAsmProgram(1).instr <> "LD" Or MamuteAsmProgram(1).operand <> "HL,100H" Or MamuteAsmProgram(1).comment <> "comeco" Then
        report = "SMOKE MAMUTE FAIL: EDIT nao separou label/instrucao/operando/comentario corretamente"
        Return 0
    End If

    mamuteInputBuf(editDocIdx) = "20 JR START"
    EditorHandleKey(enterKey, runningDummy, menuOpenDummy)
    If MamuteAsmProgramCount <> 2 Then
        report = "SMOKE MAMUTE FAIL: EDIT nao gravou a 2a linha"
        Return 0
    End If

    mamuteInputBuf(editDocIdx) = "10 START: LD HL,200H"
    EditorHandleKey(enterKey, runningDummy, menuOpenDummy)
    If MamuteAsmProgramCount <> 2 Or MamuteAsmProgram(1).operand <> "HL,200H" Then
        report = "SMOKE MAMUTE FAIL: repetir o NN deveria SUBSTITUIR a linha 10, nao duplicar"
        Return 0
    End If

    mamuteInputBuf(editDocIdx) = "30 XXXNOTAMNEMONIC 5"
    EditorHandleKey(enterKey, runningDummy, menuOpenDummy)
    If MamuteAsmProgramCount <> 2 Then
        report = "SMOKE MAMUTE FAIL: instrucao invalida nao deveria ter sido aceita no EDIT"
        Return 0
    End If
    If InStr(mamuteEditStatusText(editDocIdx), "ERRO") = 0 Then
        report = "SMOKE MAMUTE FAIL: instrucao invalida deveria mostrar ?ERRO DE SINTAXE no status do EDIT"
        Return 0
    End If

    mamuteEditCursorIndex(editDocIdx) = 1
    mamuteInputBuf(editDocIdx) = ""
    EditorHandleKey(enterKey, runningDummy, menuOpenDummy)
    If mamuteInputBuf(editDocIdx) <> "10 START: LD HL,200H" Then
        report = "SMOKE MAMUTE FAIL: ENTER com campo vazio deveria puxar a linha do cursor pro campo (EDIT)"
        Return 0
    End If

    Dim escKeyE As String = Chr(27)
    EditorHandleKey(escKeyE, runningDummy, menuOpenDummy)
    If Len(mamuteInputBuf(editDocIdx)) <> 0 Then
        report = "SMOKE MAMUTE FAIL: ESC deveria limpar o campo de entrada do EDIT"
        Return 0
    End If
    If runningDummy = 0 Then
        report = "SMOKE MAMUTE FAIL: ESC dentro do EDIT nao deveria fechar o msxIDE inteiro"
        Return 0
    End If

    mamuteEditCursorIndex(editDocIdx) = 1
    Dim downKeyE As String = Chr(0) & Chr(80)
    EditorHandleKey(downKeyE, runningDummy, menuOpenDummy)
    If mamuteEditCursorIndex(editDocIdx) <> 2 Then
        report = "SMOKE MAMUTE FAIL: seta Baixo deveria mover o cursor do EDIT pra proxima linha"
        Return 0
    End If
    Dim upKeyE As String = Chr(0) & Chr(72)
    EditorHandleKey(upKeyE, runningDummy, menuOpenDummy)
    If mamuteEditCursorIndex(editDocIdx) <> 1 Then
        report = "SMOKE MAMUTE FAIL: seta Cima deveria mover o cursor do EDIT de volta"
        Return 0
    End If

    mamuteInputBuf(editDocIdx) = "DELETE 20"
    EditorHandleKey(enterKey, runningDummy, menuOpenDummy)
    If MamuteAsmProgramCount <> 1 Then
        report = "SMOKE MAMUTE FAIL: DELETE 20 deveria ter apagado a linha 20 no EDIT"
        Return 0
    End If

    mamuteInputBuf(editDocIdx) = "RENUM 100,,50"
    EditorHandleKey(enterKey, runningDummy, menuOpenDummy)
    If MamuteAsmProgram(1).lineNum <> 100 Then
        report = "SMOKE MAMUTE FAIL: RENUM 100,,50 deveria renumerar a unica linha pra 100 no EDIT"
        Return 0
    End If

    mamuteInputBuf(editDocIdx) = "CHANGE '200H','300H'"
    EditorHandleKey(enterKey, runningDummy, menuOpenDummy)
    If MamuteAsmProgram(1).operand <> "HL,300H" Then
        report = "SMOKE MAMUTE FAIL: CHANGE nao trocou 200H por 300H no operando (EDIT)"
        Return 0
    End If

    mamuteInputBuf(editDocIdx) = "SEARCH 'START'"
    EditorHandleKey(enterKey, runningDummy, menuOpenDummy)
    If mamuteEditFilterMode(editDocIdx) = 0 Then
        report = "SMOKE MAMUTE FAIL: SEARCH deveria ligar o modo filtro do EDIT"
        Return 0
    End If

    mamuteInputBuf(editDocIdx) = "LIST"
    EditorHandleKey(enterKey, runningDummy, menuOpenDummy)
    If mamuteEditFilterMode(editDocIdx) <> 0 Then
        report = "SMOKE MAMUTE FAIL: LIST deveria sair do modo filtro do EDIT"
        Return 0
    End If

    mamuteInputBuf(editDocIdx) = "NEW"
    EditorHandleKey(enterKey, runningDummy, menuOpenDummy)
    If MamuteAsmProgramCount <> 0 Then
        report = "SMOKE MAMUTE FAIL: NEW deveria apagar o programa inteiro do EDIT"
        Return 0
    End If

    ' Testa o comando A (monta de verdade via Z80_Assemble/motor Z80 acima)
    ' fim-a-fim atraves do EDIT de verdade: linhas digitadas -> Mamute_AsmAssemble
    ' (que traduz "100" pro dialeto hexa-por-padrao do motor, "100H") -> "A O"
    ' grava na RAM simulada mapeada pelo PAGE ativo -> MAP mostra o intervalo.
    MamuteMemGrid(2, 0, 3).cellType = MAMUTE_CELL_RAM
    MamuteActiveSlot(3) = 2 : MamuteActiveSub(3) = 0
    Mamute_WriteByte(&HC000, 0) : Mamute_WriteByte(&HC001, 0) : Mamute_WriteByte(&HC002, 0)
    Mamute_WriteByte(&HC003, 0) : Mamute_WriteByte(&HC004, 0) : Mamute_WriteByte(&HC005, 0)

    mamuteInputBuf(editDocIdx) = "10 ORG 0C000H"
    EditorHandleKey(enterKey, runningDummy, menuOpenDummy)
    mamuteInputBuf(editDocIdx) = "20 START: LD HL,100"
    EditorHandleKey(enterKey, runningDummy, menuOpenDummy)
    mamuteInputBuf(editDocIdx) = "30 JP START"
    EditorHandleKey(enterKey, runningDummy, menuOpenDummy)
    If MamuteAsmProgramCount <> 3 Then
        report = "SMOKE MAMUTE FAIL: EDIT nao gravou as 3 linhas do programa de teste do comando A"
        Return 0
    End If

    mamuteInputBuf(editDocIdx) = "A O"
    EditorHandleKey(enterKey, runningDummy, menuOpenDummy)
    If InStr(mamuteEditStatusText(editDocIdx), "GRAVADO NA RAM") = 0 Then
        report = "SMOKE MAMUTE FAIL: A O deveria montar e gravar na RAM, status foi: " & mamuteEditStatusText(editDocIdx)
        Return 0
    End If
    If Mamute_ReadByte(&HC000) <> &H21 Or Mamute_ReadByte(&HC001) <> &H00 Or Mamute_ReadByte(&HC002) <> &H01 Then
        report = "SMOKE MAMUTE FAIL: A O deveria ter gravado LD HL,0100H (21 00 01) em C000H - veio " & Hex(Mamute_ReadByte(&HC000),2) & " " & Hex(Mamute_ReadByte(&HC001),2) & " " & Hex(Mamute_ReadByte(&HC002),2)
        Return 0
    End If
    If Mamute_ReadByte(&HC003) <> &HC3 Or Mamute_ReadByte(&HC004) <> &H00 Or Mamute_ReadByte(&HC005) <> &HC0 Then
        report = "SMOKE MAMUTE FAIL: A O deveria ter gravado JP START (C3 00 C0) em C003H - veio " & Hex(Mamute_ReadByte(&HC003),2) & " " & Hex(Mamute_ReadByte(&HC004),2) & " " & Hex(Mamute_ReadByte(&HC005),2)
        Return 0
    End If
    If MamuteAsmLastStartAddr <> &HC000 Or MamuteAsmLastEndAddr <> &HC005 Then
        report = "SMOKE MAMUTE FAIL: A O deveria ter registrado StartAddr=C000H/EndAddr=C005H pro MAP, veio " & Hex(MamuteAsmLastStartAddr,4) & "/" & Hex(MamuteAsmLastEndAddr,4)
        Return 0
    End If

    mamuteInputBuf(editDocIdx) = "MAP"
    EditorHandleKey(enterKey, runningDummy, menuOpenDummy)
    If InStr(mamuteEditStatusText(editDocIdx), "C000") = 0 Or InStr(mamuteEditStatusText(editDocIdx), "C005") = 0 Then
        report = "SMOKE MAMUTE FAIL: MAP deveria mostrar C000/C005, status foi: " & mamuteEditStatusText(editDocIdx)
        Return 0
    End If

    ' Linha sintaticamente aceita pelo EDIT (Mamute_ParseAsmLine so' confere
    ' vocabulario/formato, nao modo de enderecamento) mas semanticamente
    ' invalida pro Z80 de verdade (PUSH so' aceita par de 16 bits/AF/IX/IY,
    ' nao o registrador de 8 bits A) - so' o motor real (Z80_EncodeInstruction)
    ' pega isso, exatamente o comportamento pretendido ("por hora aceita o
    ' programa, a validacao semantica fica pro comando de montagem").
    mamuteInputBuf(editDocIdx) = "40 PUSH A"
    EditorHandleKey(enterKey, runningDummy, menuOpenDummy)
    mamuteInputBuf(editDocIdx) = "A"
    EditorHandleKey(enterKey, runningDummy, menuOpenDummy)
    If InStr(mamuteEditStatusText(editDocIdx), "ERRO NA LINHA 40") = 0 Then
        report = "SMOKE MAMUTE FAIL: A deveria rejeitar PUSH A com erro na linha 40, status foi: " & mamuteEditStatusText(editDocIdx)
        Return 0
    End If
    If mamuteEditCursorIndex(editDocIdx) <> 4 Then
        report = "SMOKE MAMUTE FAIL: erro do comando A deveria ter posicionado o cursor na linha 40 (indice 4), veio indice " & Trim(Str(mamuteEditCursorIndex(editDocIdx)))
        Return 0
    End If

    mamuteInputBuf(editDocIdx) = "NEW"
    EditorHandleKey(enterKey, runningDummy, menuOpenDummy)

    Dim docCountBeforeQuit As Integer = docCount
    mamuteInputBuf(editDocIdx) = "QUIT"
    EditorHandleKey(enterKey, runningDummy, menuOpenDummy)
    If docCount <> docCountBeforeQuit - 1 Then
        report = "SMOKE MAMUTE FAIL: QUIT deveria fechar so' a janela EDIT"
        Return 0
    End If
    If runningDummy = 0 Then
        report = "SMOKE MAMUTE FAIL: QUIT do EDIT nao deveria fechar o msxIDE inteiro"
        Return 0
    End If

    report = "SMOKE MAMUTE OK: round-trip do mapa de memoria (ROM 32KB no Slot 0, sub-slots + RAM no Slot 2.3), AssignMamuteRomFile (BIOS/BASIC/ROM/EXTBIOS), pagina BASIC orfa herdando arquivo da BIOS vizinha, PAGE default, enderecos de pagina, VRAM (64KB + ciclo 16-192), comando PAGE (sem args/posicional/?/erro), disassembler Z80 (plain/DD/CB/ED/DD+CB/JR), comandos F/T/MS/SH/C/D/G/X, aviso de escrita nao-RAM, rolagem automatica do terminal, editor de grade do M (128 bytes, setas/PgUp/PgDn/hexa/ENTER/ESC), comando EDIT (linhas/label/instr/operando/comentario, substituir por NN, NEW/DELETE/RENUM/CHANGE/SEARCH/LIST/QUIT) e motor Z80/comando A (montagem real, traducao hexa-por-padrao, A O grava na RAM, MAP, erro semantico mapeado pra linha certa)"
    Return -1
End Function

Sub EditorShutdown()
    PerfFlushBucket(Date & " " & Time)
    ConsoleShutdown()
End Sub
