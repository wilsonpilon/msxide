#Include Once "editor.bi"
#Include Once "db.bi"
#Include Once "console.bi"
#Include Once "compiler.bi"

Dim Shared docs(1 To MAX_DOCS) As Document
Dim Shared docCount As Integer
Dim Shared activeDoc As Integer
Dim Shared untitledCounter As Integer = 1
Dim Shared forceFullRedraw As Integer = 1
Dim Shared uiW As Integer = 100
Dim Shared uiH As Integer = 35

Const RENDER_CURSOR = 1
Const RENDER_LINE = 2
Const RENDER_CLIENT = 3
Const RENDER_FULL = 4

Const MENU_CMD_NONE = 0
Const MENU_CMD_NEW = 1
Const MENU_CMD_OPEN = 2
Const MENU_CMD_SAVE = 3
Const MENU_CMD_SAVE_AS = 4
Const MENU_CMD_CLOSE = 5
Const MENU_CMD_EXIT = 6
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

Const MENU_VIEW_NONE = 0
Const MENU_VIEW_FILE = 1
Const MENU_VIEW_HELP = 2
Const MENU_VIEW_CONFIG = 3
Const MENU_VIEW_COMPILE = 4

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
Dim Shared msxDictHasReturnHelp As Integer = 0
Dim Shared msxDictReturnHelpPath As String
Dim Shared msxDictReturnHelpTitle As String

Const MSX_DICT_DATA_PATH = "paleobasic\\src\\editor\\help\\MsxBasicDictData.pbi"
Const MSX_DICT_DATA_PATH_2P = "paleobasic\\src\\editor\\help\\MsxBasic2PlusDictData.pbi"
Const MSX_MANUAL_DATA_PATH = "paleobasic\\src\\editor\\help\\MsxBasicManualData.pbi"
Const MSX_MANUAL_DATA_PATH_2P = "paleobasic\\src\\editor\\help\\MsxBasic2PlusManualData.pbi"

Const DRAG_NONE = 0
Const DRAG_MOVE = 1
Const DRAG_RESIZE = 2
Const DRAG_VSCROLL = 3
Const DRAG_HSCROLL = 4

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
Declare Sub BuildMarkdownHelpBuffer(ByRef filePath As String, ByVal wrapWidth As Integer, outLines() As String, outColors() As UByte, outBgs() As UByte, ByRef outCount As Integer, indexTargets() As Integer, ByRef indexCount As Integer)
Declare Sub EnsureHelpRerender(ByRef d As Document)
Declare Sub ShowConfigForm(ByRef titleText As String, ByRef configGroup As String)
Declare Function PromptConfigExitAction(ByRef titleText As String) As Integer
Declare Sub CompileActiveDocument(ByVal compileMode As Integer)
Declare Sub ShowInfoDialog(ByRef titleText As String, ByRef msg1 As String, ByRef msg2 As String = "")
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

Private Function CompileDebugLogPath() As String
    Dim p As String = Environ("TEMP")
    If Len(p) = 0 Then p = CurDir()
    If Right(p, 1) <> "\\" And Right(p, 1) <> "/" Then p &= "\\"
    Return p & "bahero_compile_debug.log"
End Function

Private Function CompileDebugWorkspaceLogPath() As String
    MkDir("logs")
    Return CurDir() & "\\logs\\bahero_compile_debug.log"
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
    Dim lineText As String = Date & " " & Time & " [" & area & "] " & CompileDebugSanitize(messageText)

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

Private Function OpenMsxDictFromActiveIndexCursor() As Integer
    If activeDoc < 1 Or activeDoc > docCount Then Return 0
    Dim ByRef d As Document = docs(activeDoc)
    If Left(LCase(d.filePath), 13) <> "msxdict:index" Then Return 0
    If d.cursorY < 1 Or d.cursorY > MAX_LINES Then Return 0

    Dim kw As String = msxDictLineCommand(activeDoc, d.cursorY)
    If Len(kw) = 0 Then Return 0

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
    If Left(LCase(d.filePath), 13) = "msxdict:index" Then
        If lineIndex >= 1 And lineIndex <= MAX_LINES Then
            If Len(msxDictLineCommand(docIndex, lineIndex)) > 0 Then fg = 11
        End If
    End If
    For i = 1 To clientW
        ConsoleSetCell(d.winX + i, rowY, Asc(Mid(padded, i, 1)), fg, 0)
    Next i
End Sub

Private Function GetClientTextWidth(ByRef d As Document) As Integer
    Dim w As Integer = d.winW - 3
    If w < 1 Then w = 1
    Return w
End Function

Private Function GetClientTextHeight(ByRef d As Document) As Integer
    Dim h As Integer = d.winH - 3
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
    Dim i As Integer
    Dim j As Integer

    For j = 1 To MAX_LINES
        tempMap(j) = msxDictLineCommand(docIndex, j)
    Next j

    For i = docIndex To docCount - 1
        docs(i) = docs(i + 1)
        For j = 1 To MAX_LINES
            msxDictLineCommand(i, j) = msxDictLineCommand(i + 1, j)
        Next j
    Next i

    docs(docCount) = temp
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
        For j = 1 To MAX_LINES
            msxDictLineCommand(i, j) = msxDictLineCommand(i + 1, j)
        Next j
    Next i

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
        ConsoleWriteText(2, 1, "File", 0, 7)
    Else
        ConsoleWriteText(2, 1, "File", 15, 1)
    End If

    If menuOpen = MENU_VIEW_CONFIG Then
        ConsoleWriteText(8, 1, "Configurar", 0, 7)
    Else
        ConsoleWriteText(8, 1, "Configurar", 15, 1)
    End If

    If menuOpen = MENU_VIEW_COMPILE Then
        ConsoleWriteText(20, 1, "Compilar", 0, 7)
    Else
        ConsoleWriteText(20, 1, "Compilar", 15, 1)
    End If

    If menuOpen = MENU_VIEW_HELP Then
        ConsoleWriteText(30, 1, "Ajuda", 0, 7)
    Else
        ConsoleWriteText(30, 1, "Ajuda", 15, 1)
    End If

    If menuOpen = MENU_VIEW_FILE Then
        ConsoleWriteText(2, 2, Chr(201) & String(24, Chr(205)) & Chr(187), 15, 1)
        ConsoleWriteText(2, 3, Chr(186) & " N Novo        F4       " & Chr(186), 0, 7)
        ConsoleWriteText(2, 4, Chr(186) & " O Abrir...    F3       " & Chr(186), 0, 7)
        ConsoleWriteText(2, 5, Chr(186) & " S Salvar      F2       " & Chr(186), 0, 7)
        ConsoleWriteText(2, 6, Chr(186) & " A Salvar Como         " & Chr(186), 0, 7)
        ConsoleWriteText(2, 7, Chr(186) & " F Fechar      F5       " & Chr(186), 0, 7)
        ConsoleWriteText(2, 8, Chr(186) & " X Exit                 " & Chr(186), 0, 7)
        ConsoleWriteText(2, 9, Chr(200) & String(24, Chr(205)) & Chr(188), 15, 1)
    ElseIf menuOpen = MENU_VIEW_CONFIG Then
        ConsoleWriteText(8, 2, Chr(201) & String(32, Chr(205)) & Chr(187), 15, 1)
        ConsoleWriteText(8, 3, Chr(186) & " B Basic Dignified               " & Chr(186), 0, 7)
        ConsoleWriteText(8, 4, Chr(186) & " M MSX Basic                     " & Chr(186), 0, 7)
        ConsoleWriteText(8, 5, Chr(186) & " E Emulador                      " & Chr(186), 0, 7)
        ConsoleWriteText(8, 7, Chr(200) & String(32, Chr(205)) & Chr(188), 15, 1)
    ElseIf menuOpen = MENU_VIEW_COMPILE Then
        ConsoleWriteText(20, 2, Chr(201) & String(42, Chr(205)) & Chr(187), 15, 1)
        ConsoleWriteText(20, 3, Chr(186) & " M MSX-Basic (gera .amx + .bmx)             " & Chr(186), 0, 7)
        ConsoleWriteText(20, 4, Chr(186) & " D Basic Dignified (gera .amx)              " & Chr(186), 0, 7)
        ConsoleWriteText(20, 5, Chr(186) & " A Tokenizar AMX atual (forca modo classico)" & Chr(186), 0, 7)
        ConsoleWriteText(20, 6, Chr(186) & " E Compilar + Executar no emulador          " & Chr(186), 0, 7)
        ConsoleWriteText(20, 7, Chr(186) & " L Abrir log de compilacao                  " & Chr(186), 0, 7)
        ConsoleWriteText(20, 8, Chr(200) & String(42, Chr(205)) & Chr(188), 15, 1)
    ElseIf menuOpen = MENU_VIEW_HELP Then
        ConsoleWriteText(30, 2, Chr(201) & String(34, Chr(205)) & Chr(187), 15, 1)
        ConsoleWriteText(30, 3, Chr(186) & " B Basic Dignified                  " & Chr(186), 0, 7)
        ConsoleWriteText(30, 4, Chr(186) & " D Dignified                        " & Chr(186), 0, 7)
        ConsoleWriteText(30, 5, Chr(186) & " T BaToken                          " & Chr(186), 0, 7)
        ConsoleWriteText(30, 6, Chr(186) & " M MSX BASIC Dictionary             " & Chr(186), 0, 7)
        ConsoleWriteText(30, 7, Chr(186) & IIf(helpTheme = HELP_THEME_EDITORIAL, " C Tema: Editorial                  ", " C Tema: Classic                    ") & Chr(186), 0, 7)
        ConsoleWriteText(30, 8, Chr(200) & String(34, Chr(205)) & Chr(188), 15, 1)
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

    ConsoleWriteText(1, uiH, String(uiW, " "), 0, 7)
    ConsoleWriteText(2, uiH, statusLine, 0, 7, uiW - 2)
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

Private Sub SaveActiveDocumentToDisk()
    Dim ByRef d As Document = docs(activeDoc)
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
    Dim indexCount As Integer
    Dim wrapW As Integer = GetClientTextWidth(d)
    If wrapW < 24 Then wrapW = 24
    Dim i As Integer
    Dim oldLineCount As Integer = d.lineCount
    Dim oldScrollY As Integer = d.scrollY
    Dim oldCursorY As Integer = d.cursorY
    Dim oldCursorX As Integer = d.cursorX

    BuildMarkdownHelpBuffer(filePath, wrapW, renderLines(), renderColors(), renderBgs(), renderCount, indexTargets(), indexCount)

    d.title = "HELP " & helpTitle
    d.filePath = filePath
    d.isHelp = -1
    d.helpTitle = helpTitle
    d.helpWrapWidth = wrapW
    d.lineCount = 0

    For i = 1 To renderCount
        If d.lineCount >= MAX_LINES Then Exit For
        d.lineCount = d.lineCount + 1
        d.lines(d.lineCount) = renderLines(i)
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

Private Sub BuildMarkdownHelpBuffer(ByRef filePath As String, ByVal wrapWidth As Integer, outLines() As String, outColors() As UByte, outBgs() As UByte, ByRef outCount As Integer, indexTargets() As Integer, ByRef indexCount As Integer)
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
        For i = 1 To headingCount
            Dim item As String = Trim(Str(i)) & ". "
            If headingLevels(i) > 1 Then
                item &= String((headingLevels(i) - 1) * 2, " ")
            End If
            item &= headingTitles(i)
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
    Dim indexCount As Integer
    Dim topLine As Integer = 1

    BuildMarkdownHelpBuffer(filePath, viewW, lines(), colors(), bgs(), lineCount, indexTargets(), indexCount)
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

        ConsoleWriteText(dialogX + 2, dialogY, " " & titleText & " ", 0, 7, dialogW - 4)
        ConsoleWriteText(dialogX + 2, dialogY + 2, Left(msg1 & String(dialogW - 4, " "), dialogW - 4), 15, 1)
        ConsoleWriteText(dialogX + 2, dialogY + 3, Left(msg2 & String(dialogW - 4, " "), dialogW - 4), 11, 1)
        ConsoleWriteText(dialogX + 2, dialogY + 5, "Enter/Esc fecha", 8, 1)

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
        If keyText = Chr(13) Or keyText = Chr(27) Then Exit Do
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
    If Len(path) >= 1 And (Left(path, 1) = "\\" Or Left(path, 1) = "/") Then Return path
    Return CurDir() & "\\" & path
End Function

Private Function Q(ByRef value As String) As String
    Return Chr(34) & value & Chr(34)
End Function

Private Function CleanPathEntry(ByRef rawValue As String) As String
    Dim t As String = Trim(rawValue)
    If Len(t) >= 2 And Left(t, 1) = Chr(34) And Right(t, 1) = Chr(34) Then
        t = Mid(t, 2, Len(t) - 2)
    End If
    Return Trim(t)
End Function

Private Function NormalizePathForDisplay(ByRef pathValue As String) As String
    Dim src As String = Trim(pathValue)
    If Len(src) = 0 Then Return ""

    Dim outText As String = ""
    Dim lastSep As Integer = 0
    Dim preserveUnc As Integer = IIf(Left(src, 2) = "\\", -1, 0)
    Dim i As Integer

    For i = 1 To Len(src)
        Dim ch As String = Mid(src, i, 1)
        If ch = "/" Then ch = "\\"

        If ch = "\\" Then
            If Len(outText) = 0 Then
                outText &= ch
                lastSep = -1
            ElseIf preserveUnc <> 0 And Len(outText) = 1 And Left(outText, 1) = "\\" Then
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
    If Len(settingFile) > 0 Then outArgs &= " -setting " & Q(settingFile)

    Dim machineName As String = Trim(DbGetSetting("cfg.emulator.machine", ""))
    If Len(machineName) > 0 Then outArgs &= " -machine " & Q(machineName)

    Dim extensionName As String = Trim(DbGetSetting("cfg.emulator.extension", ""))
    If Len(extensionName) > 0 Then outArgs &= " -ext " & Q(extensionName)

    If DbBoolSetting("cfg.emulator.nothrottle", 0) <> 0 Then outArgs &= " -no-throttle"
    If DbBoolSetting("cfg.emulator.monitor", 0) <> 0 Then
        Dim scriptPath As String = "basic-dignified\\msx\\openmsx_output.tcl"
        If Dir(scriptPath) <> "" Then outArgs &= " -script " & Q(ToAbsolutePath(scriptPath))
    End If

    outArgs &= " -diska " & Q(diskPath)
    Return outArgs
End Function

Sub CompileActiveDocument(ByVal compileMode As Integer)
    If activeDoc < 1 Or activeDoc > docCount Then Exit Sub
    Dim ByRef d As Document = docs(activeDoc)
    CompileDebugLog("compile", "start mode=" & Trim(Str(compileMode)) & " file=" & d.filePath)

    If d.isHelp <> 0 Then
        Dim m As String = "Ajuda nao pode ser compilada."
        ShowInfoDialog("Compilar", m)
        Exit Sub
    End If

    If Left(LCase(d.filePath), 4) = "cfg:" Then
        Dim m As String = "Tela de configuracao nao pode ser compilada."
        ShowInfoDialog("Compilar", m)
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

    If compileMode = COMPILE_MODE_TOKENIZE_AMX Then
        modeLabel = "Tokenizar AMX"
        If ext <> ".amx" And ext <> ".asc" Then
            Dim m As String = "Abra um arquivo .amx/.asc para tokenizar."
            ShowInfoDialog("Compilar", m)
            Exit Sub
        End If
        rc = CompilerTokenizeAmx(srcPath, bmxOut, errMsg)
        amxOut = srcPath
    ElseIf compileMode = COMPILE_MODE_DIGNIFIED Then
        modeLabel = "Basic Dignified"
        If ext = ".amx" Or ext = ".asc" Then
            Dim m As String = "Use este modo com fonte .dmx/.bad."
            ShowInfoDialog("Compilar", m)
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
        ShowInfoDialog("Compilar", msg1, msg2)
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
                ShowInfoDialog("Compilar", msg1, msg2)
                Exit Sub
            End If

            Dim diskPathDisp As String = NormalizePathForDisplay(diskPath)
            Dim runCmd As String = Q(emuPath) & BuildOpenMsxLaunchArgs(diskPath)
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
    ShowInfoDialog("Compilar", msg1, msg2)
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
                Case "M"
                    Return MENU_CMD_HELP_MSX_DICT
                Case "C"
                    Return MENU_CMD_HELP_THEME
            End Select
        End If
        Return MENU_CMD_NONE
    End If

    If Len(keyText) = 1 Then
        Select Case UCase(keyText)
            Case "N"
                Return MENU_CMD_NEW
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

Private Sub ExecuteMenuCommand(ByVal commandId As Integer, ByRef running As Integer, ByRef menuOpen As Integer)
    Select Case commandId
        Case MENU_CMD_NEW
            EditorCreateUntitled()
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
        Case MENU_CMD_HELP_MSX_DICT
            OpenMsxDictHelp()
        Case MENU_CMD_HELP_THEME
            If helpTheme = HELP_THEME_EDITORIAL Then
                helpTheme = HELP_THEME_CLASSIC
            Else
                helpTheme = HELP_THEME_EDITORIAL
            End If
            ApplyHelpTheme()
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

    ' Clique na barra de menu (File)
    If mouseY = 1 And mouseX >= 2 And mouseX <= 5 Then
        menuOpen = IIf(menuOpen = MENU_VIEW_FILE, MENU_VIEW_NONE, MENU_VIEW_FILE)
        dragMode = DRAG_NONE
        forceFullRedraw = 1
        renderMode = RENDER_FULL
        Exit Sub
    End If

    ' Clique na barra de menu (Configurar)
    If mouseY = 1 And mouseX >= 8 And mouseX <= 16 Then
        menuOpen = IIf(menuOpen = MENU_VIEW_CONFIG, MENU_VIEW_NONE, MENU_VIEW_CONFIG)
        dragMode = DRAG_NONE
        forceFullRedraw = 1
        renderMode = RENDER_FULL
        Exit Sub
    End If

    ' Clique na barra de menu (Compilar)
    If mouseY = 1 And mouseX >= 20 And mouseX <= 27 Then
        menuOpen = IIf(menuOpen = MENU_VIEW_COMPILE, MENU_VIEW_NONE, MENU_VIEW_COMPILE)
        dragMode = DRAG_NONE
        forceFullRedraw = 1
        renderMode = RENDER_FULL
        Exit Sub
    End If

    ' Clique na barra de menu (Ajuda)
    If mouseY = 1 And mouseX >= 30 And mouseX <= 34 Then
        menuOpen = IIf(menuOpen = MENU_VIEW_HELP, MENU_VIEW_NONE, MENU_VIEW_HELP)
        dragMode = DRAG_NONE
        forceFullRedraw = 1
        renderMode = RENDER_FULL
        Exit Sub
    End If

    If menuOpen <> 0 Then
        Dim menuCmd As Integer = MENU_CMD_NONE
        If menuOpen = MENU_VIEW_FILE Then
            If mouseX >= 3 And mouseX <= 25 Then
                Select Case mouseY
                    Case 3
                        menuCmd = MENU_CMD_NEW
                    Case 4
                        menuCmd = MENU_CMD_OPEN
                    Case 5
                        menuCmd = MENU_CMD_SAVE
                    Case 6
                        menuCmd = MENU_CMD_SAVE_AS
                    Case 7
                        menuCmd = MENU_CMD_CLOSE
                    Case 8
                        menuCmd = MENU_CMD_EXIT
                End Select
            End If
        ElseIf menuOpen = MENU_VIEW_CONFIG Then
            If mouseX >= 9 And mouseX <= 40 Then
                Select Case mouseY
                    Case 3
                        menuCmd = MENU_CMD_CFG_BADIG
                    Case 4
                        menuCmd = MENU_CMD_CFG_MSX
                    Case 5
                        menuCmd = MENU_CMD_CFG_EMULATOR
                End Select
            End If
        ElseIf menuOpen = MENU_VIEW_COMPILE Then
            If mouseX >= 21 And mouseX <= 62 Then
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
            If mouseX >= 31 And mouseX <= 64 Then
                Select Case mouseY
                    Case 3
                        menuCmd = MENU_CMD_HELP_BASIC
                    Case 4
                        menuCmd = MENU_CMD_HELP_DIGNIFIED
                    Case 5
                        menuCmd = MENU_CMD_HELP_BATOKEN
                    Case 6
                        menuCmd = MENU_CMD_HELP_MSX_DICT
                    Case 7
                        menuCmd = MENU_CMD_HELP_THEME
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

    report = "SMOKE HELP OK: ESC modal->log, retorno Shift+F1, contextual PRINT, comando exclusivo MSX2+/FM (" & msx2Exclusive & "), topico de referencia, indice, clique e Enter para " & firstKeyword
    Return -1
End Function

Sub EditorShutdown()
    PerfFlushBucket(Date & " " & Time)
    ConsoleShutdown()
End Sub
