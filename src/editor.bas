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

Type MamuteMemCell
    cellType As Integer
    romPath As String
    romOffset As Integer
End Type

Dim Shared MamuteMemGrid(0 To 3, 0 To 3, 0 To 3) As MamuteMemCell
Dim Shared MamuteMemSubOn(0 To 3) As Integer

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
    Dim i As Integer
    Dim j As Integer

    For j = 1 To MAX_LINES
        tempMap(j) = msxDictLineCommand(docIndex, j)
    Next j

    For i = docIndex To docCount - 1
        docs(i) = docs(i + 1)
        mamuteInputBuf(i) = mamuteInputBuf(i + 1)
        mamuteInputCursor(i) = mamuteInputCursor(i + 1)
        For j = 1 To MAX_LINES
            msxDictLineCommand(i, j) = msxDictLineCommand(i + 1, j)
        Next j
    Next i

    docs(docCount) = temp
    mamuteInputBuf(docCount) = tempInputBuf
    mamuteInputCursor(docCount) = tempInputCursor
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
        For j = 1 To MAX_LINES
            msxDictLineCommand(i, j) = msxDictLineCommand(i + 1, j)
        Next j
    Next i

    mamuteInputBuf(docCount) = ""
    mamuteInputCursor(docCount) = 0
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
        Dim inputRow As Integer = d.winY + 1 + GetClientTextHeight(d)
        Dim cx2 As Integer = Len(MAMUTE_PROMPT) + mamuteInputCursor(activeDoc) + 1
        If cx2 >= 1 And cx2 <= clientW2 Then
            ConsoleSetCursor(d.winX + cx2, inputRow, 1)
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

    If menuOpen = MENU_VIEW_HELP Then
        ConsoleWriteText(33, 1, "Ajuda", 0, 7)
    Else
        ConsoleWriteText(33, 1, "Ajuda", 15, 1)
    End If

    If menuOpen = MENU_VIEW_REFERENCE Then
        ConsoleWriteText(40, 1, "Referencia", 0, 7)
    Else
        ConsoleWriteText(40, 1, "Referencia", 15, 1)
    End If

    If menuOpen = MENU_VIEW_MAMUTE Then
        ConsoleWriteText(52, 1, "Mamute", 0, 7)
    Else
        ConsoleWriteText(52, 1, "Mamute", 15, 1)
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
        ConsoleWriteText(33, 2, Chr(201) & String(34, Chr(205)) & Chr(187), 15, 1)
        ConsoleWriteText(33, 3, Chr(186) & " B Basic Dignified                  " & Chr(186), 0, 7)
        ConsoleWriteText(33, 4, Chr(186) & " D Dignified                        " & Chr(186), 0, 7)
        ConsoleWriteText(33, 5, Chr(186) & " T BaToken                          " & Chr(186), 0, 7)
        ConsoleWriteText(33, 6, Chr(186) & " A asMSX                            " & Chr(186), 0, 7)
        ConsoleWriteText(33, 7, Chr(186) & " M MSX BASIC Dictionary             " & Chr(186), 0, 7)
        ConsoleWriteText(33, 8, Chr(186) & " E Editor                           " & Chr(186), 0, 7)
        ConsoleWriteText(33, 9, Chr(186) & IIf(helpTheme = HELP_THEME_EDITORIAL, " C Tema: Editorial                  ", " C Tema: Classic                    ") & Chr(186), 0, 7)
        ConsoleWriteText(33, 10, Chr(200) & String(34, Chr(205)) & Chr(188), 15, 1)
    ElseIf menuOpen = MENU_VIEW_REFERENCE Then
        ConsoleWriteText(40, 2, Chr(201) & String(40, Chr(205)) & Chr(187), 15, 1)
        ConsoleWriteText(40, 3, Chr(186) & Left(" R The MSX Red Book" & Space(40), 40) & Chr(186), 0, 7)
        ConsoleWriteText(40, 4, Chr(186) & Left(" N Nestor Basic" & Space(40), 40) & Chr(186), 0, 7)
        ConsoleWriteText(40, 5, Chr(186) & Left(" T MSX2 Technical Handbook" & Space(40), 40) & Chr(186), 0, 7)
        ConsoleWriteText(40, 6, Chr(186) & Left(" M Manuais MSX" & Space(40), 40) & Chr(186), 0, 7)
        ConsoleWriteText(40, 7, Chr(186) & Left(" C BIOS Chamadas" & Space(40), 40) & Chr(186), 0, 7)
        ConsoleWriteText(40, 8, Chr(186) & Left(" W BIOS Hardware" & Space(40), 40) & Chr(186), 0, 7)
        ConsoleWriteText(40, 9, Chr(186) & Left(" D BIOS Documentacao" & Space(40), 40) & Chr(186), 0, 7)
        ConsoleWriteText(40, 10, Chr(186) & Left(" S SEE Tracker" & Space(40), 40) & Chr(186), 0, 7)
        ConsoleWriteText(40, 11, Chr(186) & Left(" O openMSX" & Space(40), 40) & Chr(186), 0, 7)
        ConsoleWriteText(40, 12, Chr(186) & Left(" X MSXBAS2ROM" & Space(40), 40) & Chr(186), 0, 7)
        ConsoleWriteText(40, 13, Chr(200) & String(40, Chr(205)) & Chr(188), 15, 1)
    ElseIf menuOpen = MENU_VIEW_MAMUTE Then
        ConsoleWriteText(52, 2, Chr(201) & String(30, Chr(205)) & Chr(187), 15, 1)
        ConsoleWriteText(52, 3, Chr(186) & Left(" A Abrir Mamute Assembler" & Space(30), 30) & Chr(186), 0, 7)
        ConsoleWriteText(52, 4, Chr(200) & String(30, Chr(205)) & Chr(188), 15, 1)
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
                End If
                MamuteMemGrid(slot, subIdx, pageIdx).cellType = cellType
                MamuteMemGrid(slot, subIdx, pageIdx).romPath = DbGetSetting(prefix & "rompath", "")
                MamuteMemGrid(slot, subIdx, pageIdx).romOffset = ValInt(DbGetSetting(prefix & "romoffset", "0"))
            Next pageIdx
        Next subIdx
    Next slot
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
                DbSetSetting(prefix & "type", typeText)
                DbSetSetting(prefix & "rompath", cell.romPath)
                DbSetSetting(prefix & "romoffset", Trim(Str(cell.romOffset)))
            Next pageIdx
        Next subIdx
    Next slot
End Sub

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
    Dim message As String = "Setas navega | Espaco/Enter tipo | T sub-slots | L Carregar ROM 32KB | F2 salva | Esc cancela"

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
        detailText &= " Pag." & Trim(Str(selCol)) & " = " & MamuteCellTypeLabel(selCell.cellType)
        If selCell.cellType = MAMUTE_CELL_ROM Then
            detailText &= " (" & NormalizePathForDisplay(selCell.romPath) & ", offset " & Trim(Str(selCell.romOffset)) & ")"
        End If
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
                MamuteMemGrid(curSlot, curSub, 0).cellType = MAMUTE_CELL_ROM
                MamuteMemGrid(curSlot, curSub, 0).romPath = romFile
                MamuteMemGrid(curSlot, curSub, 0).romOffset = 0
                MamuteMemGrid(curSlot, curSub, 1).cellType = MAMUTE_CELL_ROM
                MamuteMemGrid(curSlot, curSub, 1).romPath = romFile
                MamuteMemGrid(curSlot, curSub, 1).romOffset = 16384
                memDirty = -1
                message = "ROM 32KB carregada no Slot " & Trim(Str(curSlot)) & " (BIOS pag.0 / BASIC pag.1)."
            End If
            Continue Do
        End If

        If keyText = " " Or keyText = Chr(13) Then
            Dim ByRef cell As MamuteMemCell = MamuteMemGrid(curSlot, curSub, selCol)

            If keyText = Chr(13) And cell.cellType = MAMUTE_CELL_ROM Then
                Dim canceled2 As Integer
                Dim newPath As String = PromptPathDialog("ROM da pagina", "Arquivo .rom:", cell.romPath, canceled2)
                If canceled2 = 0 Then
                    cell.romPath = newPath
                    Dim offCanceled As Integer
                    Dim offText As String = PromptPathDialog("Offset no arquivo", "Offset em bytes:", Trim(Str(cell.romOffset)), offCanceled)
                    If offCanceled = 0 Then cell.romOffset = ValInt(offText)
                    memDirty = -1
                End If
            Else
                Select Case cell.cellType
                    Case MAMUTE_CELL_NONE
                        cell.cellType = MAMUTE_CELL_RAM
                        memDirty = -1
                    Case MAMUTE_CELL_RAM
                        Dim canceled3 As Integer
                        Dim romPath3 As String = PromptPathDialog("ROM da pagina", "Arquivo .rom:", "", canceled3)
                        If canceled3 = 0 And Len(romPath3) > 0 Then
                            cell.cellType = MAMUTE_CELL_ROM
                            cell.romPath = romPath3
                            cell.romOffset = 0
                            memDirty = -1
                        End If
                    Case Else
                        cell.cellType = MAMUTE_CELL_NONE
                        cell.romPath = ""
                        cell.romOffset = 0
                        memDirty = -1
                End Select
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
    End Select

    menuOpen = 0
    forceFullRedraw = 1
    renderMode = RENDER_FULL
End Sub

Private Sub HandleEditorKey(ByRef keyText As String, ByRef running As Integer, ByRef needFullRedraw As Integer, ByRef renderHint As Integer)
    Dim ByRef d As Document = docs(activeDoc)
    renderHint = RENDER_CURSOR

    If keyText = Chr(27) Then
        running = 0
        Exit Sub
    End If

    If d.isMamuteTerm <> 0 Then
        HandleMamuteTermKey(d, keyText, renderHint)
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
        txt &= Left(MamuteCellTypeLabel(MamuteMemGrid(slot, subIdx, c).cellType) & Space(6), 6)
    Next c
    Return txt
End Function

Private Sub ExecuteMamuteCommand(ByRef d As Document, ByRef cmdTextIn As String)
    Dim cmdText As String = Trim(cmdTextIn)
    If Len(cmdText) = 0 Then Exit Sub

    Dim verb As String = cmdText
    Dim spacePos As Integer = InStr(cmdText, " ")
    If spacePos > 0 Then verb = Left(cmdText, spacePos - 1)
    verb = UCase(verb)

    Select Case verb
        Case "CLS"
            d.lineCount = 1
            d.lines(1) = ""
            d.scrollY = 0
        Case "PAGE"
            LoadMamuteMemConfig()
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
        AppendMamuteLine(d, MAMUTE_PROMPT & cmdText)
        ExecuteMamuteCommand(d, cmdText)
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
    Dim lineText As String = MAMUTE_PROMPT & mamuteInputBuf(docIndex)
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

    InitBlankDocument(docs(docCount), "Mamute Assembler")
    docs(docCount).isMamuteTerm = -1
    docs(docCount).lineCount = 3
    docs(docCount).lines(1) = "Mamute Assembler - MON>"
    docs(docCount).lines(2) = "Comandos disponiveis nesta fase: CLS, PAGE, BA/QUIT."
    docs(docCount).lines(3) = ""
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
    EnsureCursorVisible(docs(activeDoc))

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

    ' Clique na barra de menu (Ajuda)
    If mouseY = 1 And mouseX >= 33 And mouseX <= 37 Then
        menuOpen = IIf(menuOpen = MENU_VIEW_HELP, MENU_VIEW_NONE, MENU_VIEW_HELP)
        dragMode = DRAG_NONE
        forceFullRedraw = 1
        renderMode = RENDER_FULL
        Exit Sub
    End If

    ' Clique na barra de menu (Referencia)
    If mouseY = 1 And mouseX >= 40 And mouseX <= 49 Then
        menuOpen = IIf(menuOpen = MENU_VIEW_REFERENCE, MENU_VIEW_NONE, MENU_VIEW_REFERENCE)
        dragMode = DRAG_NONE
        forceFullRedraw = 1
        renderMode = RENDER_FULL
        Exit Sub
    End If

    ' Clique na barra de menu (Mamute)
    If mouseY = 1 And mouseX >= 52 And mouseX <= 58 Then
        menuOpen = IIf(menuOpen = MENU_VIEW_MAMUTE, MENU_VIEW_NONE, MENU_VIEW_MAMUTE)
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
            If mouseX >= 34 And mouseX <= 67 Then
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
                        menuCmd = MENU_CMD_HELP_THEME
                End Select
            End If
        ElseIf menuOpen = MENU_VIEW_REFERENCE Then
            If mouseX >= 40 And mouseX <= 81 Then
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
            If mouseX >= 52 And mouseX <= 82 Then
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

    report = "SMOKE HELP OK: ESC modal->log, retorno Shift+F1, contextual PRINT, comando exclusivo MSX2+/FM (" & msx2Exclusive & "), topico de referencia, indice, clique e Enter para " & firstKeyword & ", refdict biosdoc (" & Trim(Str(biosdocLineCount)) & " linhas), redbook (" & Trim(Str(rbTopicCount)) & " topicos/" & Trim(Str(rbGroupHeaders)) & " grupos, Ver tambem OK), msxmanuals (" & Trim(Str(mmTopicCount)) & " topicos, sem duplicata), openmsx (" & Trim(Str(omTopicCount)) & " topicos), nestorbasic/seetracker/msxbas2rom/editor OK, th2handbook (" & Trim(Str(thTopicCount)) & "), bioscalls (" & Trim(Str(bcTopicCount)) & "), hardware (" & Trim(Str(hwTopicCount)) & ")"
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

    report = "SMOKE MAMUTE OK: round-trip do mapa de memoria (ROM 32KB no Slot 0, sub-slots + RAM no Slot 2.3)"
    Return -1
End Function

Sub EditorShutdown()
    PerfFlushBucket(Date & " " & Time)
    ConsoleShutdown()
End Sub
