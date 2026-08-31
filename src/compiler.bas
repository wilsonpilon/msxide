#Include Once "compiler.bi"
#Include Once "db.bi"

Type KeywordToken
    kw As String
    tokHex As String
    tokData As String
    isJump As Integer
    literalMode As Integer
End Type

Const TOK_LITERAL_NONE = 0
Const TOK_LITERAL_DATA_REM = 1

Dim Shared gKeywords(1 To 256) As KeywordToken
Dim Shared gKeywordCount As Integer
Dim Shared gKeywordInit As Integer

Private Function CompilerDebugLogPath() As String
    Dim p As String = Environ("TEMP")
    If Len(p) = 0 Then p = CurDir()
    If Right(p, 1) <> "\\" And Right(p, 1) <> "/" Then p &= "\\"
    Return p & "bahero_compile_debug.log"
End Function

Private Function CompilerDebugSanitize(ByRef txt As String) As String
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

Private Function CompilerLogNormalizeSlashes(ByRef txt As String) As String
    Dim src As String = Trim(txt)
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

Private Sub CompilerDebugLog(ByRef area As String, ByRef messageText As String)
    Dim logMsg As String = CompilerLogNormalizeSlashes(CompilerDebugSanitize(messageText))
    Dim ff As Integer = FreeFile
    If Open(CompilerDebugLogPath() For Append As #ff) <> 0 Then Exit Sub
    Print #ff, Date & " " & Time & " [" & area & "] " & logMsg
    Close #ff
End Sub

Private Function IsAlphaNumOrSigil(ByVal ch As Integer) As Integer
    If ch >= Asc("A") And ch <= Asc("Z") Then Return -1
    If ch >= Asc("a") And ch <= Asc("z") Then Return -1
    If ch >= Asc("0") And ch <= Asc("9") Then Return -1
    If ch = Asc("_") Or ch = Asc("$") Then Return -1
    Return 0
End Function

Private Function TokIsBoundaryBefore(ByRef textLine As String, ByVal idxChar As Integer) As Integer
    If idxChar <= 1 Then Return -1
    Dim prevCh As Integer = Asc(Mid(textLine, idxChar - 1, 1))
    Return IIf(IsAlphaNumOrSigil(prevCh) = 0, -1, 0)
End Function

Private Function TokIsBoundaryAfter(ByRef textLine As String, ByVal idxAfter As Integer) As Integer
    If idxAfter > Len(textLine) Then Return -1
    Dim nextCh As Integer = Asc(Mid(textLine, idxAfter, 1))
    Return IIf(IsAlphaNumOrSigil(nextCh) = 0, -1, 0)
End Function

Private Function ReadTextFile(ByRef filePath As String, ByRef outText As String, ByRef errMsg As String) As Integer
    outText = ""
    errMsg = ""

    If Len(filePath) = 0 Then
        errMsg = "Caminho de arquivo vazio."
        Return 0
    End If

    If Dir(filePath) = "" Then
        errMsg = "Arquivo nao encontrado: " & filePath
        Return 0
    End If

    Dim ff As Integer = FreeFile
    If Open(filePath For Input As #ff) <> 0 Then
        errMsg = "Falha ao abrir arquivo para leitura: " & filePath
        Return 0
    End If

    Dim lineText As String
    While Not Eof(ff)
        Line Input #ff, lineText
        outText &= lineText
        If Not Eof(ff) Then outText &= Chr(10)
    Wend
    Close #ff

    Return -1
End Function

Private Function ReadBinaryFile(ByRef filePath As String, ByRef outBytes As String, ByRef errMsg As String) As Integer
    outBytes = ""
    errMsg = ""

    If Dir(filePath) = "" Then
        errMsg = "Arquivo nao encontrado: " & filePath
        Return 0
    End If

    Dim ff As Integer = FreeFile
    If Open(filePath For Binary Access Read As #ff) <> 0 Then
        errMsg = "Falha ao abrir arquivo binario: " & filePath
        Return 0
    End If

    Dim sizeBytes As LongInt = Lof(ff)
    If sizeBytes < 0 Then
        Close #ff
        errMsg = "Falha ao ler tamanho de arquivo: " & filePath
        Return 0
    End If

    If sizeBytes > 0 Then
        outBytes = Space(sizeBytes)
        Get #ff, , outBytes
    End If
    Close #ff

    Return -1
End Function

Private Function WriteTextFile(ByRef filePath As String, ByRef content As String, ByRef errMsg As String) As Integer
    errMsg = ""
    Dim ff As Integer = FreeFile
    If Open(filePath For Output As #ff) <> 0 Then
        errMsg = "Falha ao abrir arquivo para escrita: " & filePath
        Return 0
    End If
    Print #ff, content;
    Close #ff
    Return -1
End Function

Private Function WriteBinaryFile(ByRef filePath As String, ByRef content As String, ByRef errMsg As String) As Integer
    errMsg = ""
    Dim ff As Integer = FreeFile
    If Open(filePath For Binary Access Write As #ff) <> 0 Then
        errMsg = "Falha ao abrir arquivo binario para escrita: " & filePath
        Return 0
    End If
    If Len(content) > 0 Then Put #ff, , content
    Close #ff
    Return -1
End Function

Private Function ClearDiskDirByPattern(ByRef diskDir As String, ByRef pattern As String, ByRef errMsg As String) As Integer
    Dim fileMask As String = diskDir
    If Right(fileMask, 1) <> "\\" And Right(fileMask, 1) <> "/" Then fileMask &= "\\"
    fileMask &= pattern

    Dim entryName As String = Dir(fileMask)
    While Len(entryName) > 0
        Dim filePath As String = diskDir
        If Right(filePath, 1) <> "\\" And Right(filePath, 1) <> "/" Then filePath &= "\\"
        filePath &= entryName

        If Dir(filePath) <> "" Then
            Kill filePath
            If Dir(filePath) <> "" Then
                errMsg = "Falha ao limpar arquivo antigo: " & filePath
                Return 0
            End If
        End If
        entryName = Dir()
    Wend

    Return -1
End Function

Private Function ClearRunDiskDir(ByRef diskDir As String, ByRef errMsg As String) As Integer
    errMsg = ""
    If ClearDiskDirByPattern(diskDir, "*.dsk", errMsg) = 0 Then Return 0
    If ClearDiskDirByPattern(diskDir, "*.amx", errMsg) = 0 Then Return 0
    If ClearDiskDirByPattern(diskDir, "*.bmx", errMsg) = 0 Then Return 0
    If ClearDiskDirByPattern(diskDir, "*.dmx", errMsg) = 0 Then Return 0
    If ClearDiskDirByPattern(diskDir, "*.bas", errMsg) = 0 Then Return 0
    Return -1
End Function

Private Function NormalizePathValue(ByRef pathValue As String) As String
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

Private Function StripCR(ByRef txt As String) As String
    Dim outText As String = ""
    Dim i As Integer
    For i = 1 To Len(txt)
        Dim c As String = Mid(txt, i, 1)
        If c <> Chr(13) Then outText &= c
    Next i
    Return outText
End Function

Private Function CollapseSpacesOutsideStrings(ByRef txt As String) As String
    Dim outText As String = ""
    Dim inString As Integer = 0
    Dim prevSpace As Integer = 0
    Dim i As Integer

    For i = 1 To Len(txt)
        Dim ch As String = Mid(txt, i, 1)
        If ch = Chr(34) Then
            inString = Not inString
            outText &= ch
            prevSpace = 0
        ElseIf inString = 0 And (ch = " " Or ch = Chr(9)) Then
            If prevSpace = 0 Then
                outText &= " "
                prevSpace = -1
            End If
        Else
            outText &= ch
            prevSpace = 0
        End If
    Next i

    Return Trim(outText)
End Function

Private Function IsTrueSetting(ByRef keyName As String, ByVal fallbackValue As Integer = 0) As Integer
    Dim fb As String = IIf(fallbackValue <> 0, "True", "False")
    Dim rawValue As String = LCase(Trim(DbGetSetting(keyName, fb)))

    Select Case rawValue
        Case "1", "true", "yes", "on", "y"
            Return -1
        Case "0", "false", "no", "off", "n"
            Return 0
    End Select

    Return fallbackValue
End Function

Private Function IntSetting(ByRef keyName As String, ByVal fallbackValue As Integer, ByVal minValue As Integer, ByVal maxValue As Integer) As Integer
    Dim rawValue As String = Trim(DbGetSetting(keyName, Trim(Str(fallbackValue))))
    Dim v As Integer = ValInt(rawValue)
    If v < minValue Then v = minValue
    If v > maxValue Then v = maxValue
    Return v
End Function

Private Function ParseNumberedLine(ByRef rawLine As String, ByRef lineNumber As Integer, ByRef bodyText As String) As Integer
    Dim s As String = LTrim(rawLine)
    lineNumber = 0
    bodyText = ""

    If Len(s) = 0 Then Return 0

    Dim i As Integer = 1
    While i <= Len(s)
        Dim ch As Integer = Asc(Mid(s, i, 1))
        If ch < Asc("0") Or ch > Asc("9") Then Exit While
        i += 1
    Wend

    If i = 1 Then Return 0
    lineNumber = ValInt(Left(s, i - 1))

    If i <= Len(s) Then
        bodyText = LTrim(Mid(s, i))
    Else
        bodyText = ""
    End If

    Return -1
End Function

Private Function RewriteInlineExitForLoop(ByRef textIn As String, ByVal targetLineNo As Integer) As String
    Dim src As String = textIn
    Dim outText As String = ""
    Dim inString As Integer = 0
    Dim i As Integer = 1
    Dim repl As String = "GOTO " & Trim(Str(targetLineNo))

    While i <= Len(src)
        Dim ch As String = Mid(src, i, 1)
        If ch = Chr(34) Then
            inString = Not inString
            outText &= ch
            i += 1
        ElseIf inString = 0 And i + 3 <= Len(src) _
            And UCase(Mid(src, i, 4)) = "EXIT" _
            And TokIsBoundaryBefore(src, i) <> 0 _
            And TokIsBoundaryAfter(src, i + 4) <> 0 Then
            outText &= repl
            i += 4
        Else
            outText &= ch
            i += 1
        End If
    Wend

    Return outText
End Function

Private Function NormalizeConvertPrintMode(ByRef rawValue As String) As String
    Dim v As String = UCase(Trim(rawValue))
    If v = "?" Or v = "PRINT" Then Return v

    ' Compatibilidade com valor legado bool.
    If v = "TRUE" Or v = "1" Or v = "YES" Or v = "ON" Then Return "?"
    If v = "FALSE" Or v = "0" Or v = "NO" Or v = "OFF" Then Return "PRINT"

    Return "PRINT"
End Function

Private Function NormalizeIfJumpMode(ByRef rawValue As String) As String
    Dim v As String = UCase(Trim(rawValue))
    If v = "THEN" Or v = "GOTO" Then Return v

    ' Compatibilidade com valor legado bool.
    If v = "TRUE" Or v = "1" Or v = "YES" Or v = "ON" Then Return "THEN"
    If v = "FALSE" Or v = "0" Or v = "NO" Or v = "OFF" Then Return "GOTO"

    Return "THEN"
End Function

Private Function IsTokenBoundaryAt(ByRef src As String, ByVal pos1 As Integer, ByVal tokenLen As Integer) As Integer
    Return IIf(TokIsBoundaryBefore(src, pos1) <> 0 And TokIsBoundaryAfter(src, pos1 + tokenLen) <> 0, -1, 0)
End Function

Private Function ContainsIfTokenOutsideString(ByRef src As String) As Integer
    Dim i As Integer = 1
    Dim inString As Integer = 0

    While i <= Len(src)
        Dim ch As String = Mid(src, i, 1)
        If ch = Chr(34) Then
            inString = Not inString
            i += 1
            Continue While
        End If

        If inString = 0 And i + 1 <= Len(src) Then
            If UCase(Mid(src, i, 2)) = "IF" And IsTokenBoundaryAt(src, i, 2) <> 0 Then
                Return -1
            End If
        End If
        i += 1
    Wend

    Return 0
End Function

Private Function NextNonSpacePos(ByRef src As String, ByVal startPos As Integer) As Integer
    Dim i As Integer = startPos
    While i <= Len(src)
        Dim ch As Integer = Asc(Mid(src, i, 1))
        If ch <> Asc(" ") And ch <> 9 Then Exit While
        i += 1
    Wend
    Return i
End Function

Private Function ConvertPrintByMode(ByRef src As String, ByRef modeText As String) As String
    Dim modeU As String = UCase(Trim(modeText))
    If modeU <> "?" And modeU <> "PRINT" Then Return src

    Dim outText As String = ""
    Dim inString As Integer = 0
    Dim i As Integer = 1

    While i <= Len(src)
        Dim ch As String = Mid(src, i, 1)
        If ch = Chr(34) Then
            inString = Not inString
            outText &= ch
            i += 1
            Continue While
        End If

        If inString = 0 And modeU = "?" And i + 4 <= Len(src) Then
            If UCase(Mid(src, i, 5)) = "PRINT" And IsTokenBoundaryAt(src, i, 5) <> 0 Then
                outText &= "?"
                i += 5
                Continue While
            End If
        End If

        If inString = 0 And modeU = "PRINT" And ch = "?" Then
            outText &= "PRINT"
            i += 1
            Continue While
        End If

        outText &= ch
        i += 1
    Wend

    Return outText
End Function

Private Function RewriteIfThenGotoByMode(ByRef src As String, ByRef modeText As String) As String
    Dim modeU As String = UCase(Trim(modeText))
    If modeU <> "THEN" And modeU <> "GOTO" Then Return src
    If ContainsIfTokenOutsideString(src) = 0 Then Return src

    Dim outText As String = ""
    Dim inString As Integer = 0
    Dim i As Integer = 1

    While i <= Len(src)
        Dim ch As String = Mid(src, i, 1)
        If ch = Chr(34) Then
            inString = Not inString
            outText &= ch
            i += 1
            Continue While
        End If

        If inString = 0 And i + 3 <= Len(src) Then
            If UCase(Mid(src, i, 4)) = "THEN" And IsTokenBoundaryAt(src, i, 4) <> 0 Then
                Dim p As Integer = NextNonSpacePos(src, i + 4)
                If p + 3 <= Len(src) And UCase(Mid(src, p, 4)) = "GOTO" And IsTokenBoundaryAt(src, p, 4) <> 0 Then
                    If modeU = "THEN" Then
                        outText &= "THEN"
                    Else
                        outText &= "GOTO"
                    End If
                    i = p + 4
                    Continue While
                ElseIf p <= Len(src) Then
                    Dim n0 As Integer = Asc(Mid(src, p, 1))
                    If n0 >= Asc("0") And n0 <= Asc("9") Then
                        If modeU = "THEN" Then
                            outText &= "THEN"
                        Else
                            outText &= "GOTO"
                        End If
                        i += 4
                        Continue While
                    End If
                End If
            End If
        End If

        If inString = 0 And modeU = "THEN" And i + 3 <= Len(src) Then
            If UCase(Mid(src, i, 4)) = "GOTO" And IsTokenBoundaryAt(src, i, 4) <> 0 Then
                Dim p As Integer = NextNonSpacePos(src, i + 4)
                If p <= Len(src) Then
                    Dim n0 As Integer = Asc(Mid(src, p, 1))
                    If n0 >= Asc("0") And n0 <= Asc("9") Then
                        outText &= "THEN"
                        i += 4
                        Continue While
                    End If
                End If
            End If
        End If

        outText &= ch
        i += 1
    Wend

    Return outText
End Function

Private Function ChangeExt(ByRef filePath As String, ByRef newExt As String) As String
    Dim p As Integer = InStrRev(filePath, ".")
    If p <= 0 Then Return filePath & newExt
    Return Left(filePath, p - 1) & newExt
End Function

Private Function GetExtLower(ByRef filePath As String) As String
    Dim p As Integer = InStrRev(filePath, ".")
    If p <= 0 Then Return ""
    Return LCase(Mid(filePath, p))
End Function

Private Function BaseNameNoExt(ByRef filePath As String) As String
    Dim lastSlash As Integer = InStrRev(filePath, "\\")
    Dim lastFwd As Integer = InStrRev(filePath, "/")
    If lastFwd > lastSlash Then lastSlash = lastFwd

    Dim filePart As String
    If lastSlash > 0 Then
        filePart = Mid(filePath, lastSlash + 1)
    Else
        filePart = filePath
    End If

    Dim dotPos As Integer = InStrRev(filePart, ".")
    If dotPos > 0 Then
        Return Left(filePart, dotPos - 1)
    End If
    Return filePart
End Function

Private Function PathDir(ByRef filePath As String) As String
    Dim lastSlash As Integer = InStrRev(filePath, "\\")
    Dim lastFwd As Integer = InStrRev(filePath, "/")
    If lastFwd > lastSlash Then lastSlash = lastFwd
    If lastSlash <= 0 Then Return CurDir()
    Return Left(filePath, lastSlash - 1)
End Function

Private Function ToAbsolutePathLocal(ByRef baseDir As String, ByRef pathValue As String) As String
    Dim p As String = Trim(pathValue)
    If Len(p) = 0 Then Return ""
    If Len(p) >= 2 And Mid(p, 2, 1) = ":" Then Return p
    If Left(p, 1) = "\\" Or Left(p, 1) = "/" Then Return p
    Dim sep As String = "\\"
    If Right(baseDir, 1) = "\\" Or Right(baseDir, 1) = "/" Then sep = ""
    Return baseDir & sep & p
End Function

Private Function StartsWithText(ByRef fullText As String, ByRef prefix As String) As Integer
    If Len(prefix) > Len(fullText) Then Return 0
    Return IIf(Left(fullText, Len(prefix)) = prefix, -1, 0)
End Function

Private Function HexDigitValue(ByVal c As Integer) As Integer
    If c >= Asc("0") And c <= Asc("9") Then Return c - Asc("0")
    If c >= Asc("A") And c <= Asc("F") Then Return c - Asc("A") + 10
    If c >= Asc("a") And c <= Asc("f") Then Return c - Asc("a") + 10
    Return -1
End Function

Private Function HexToBin(ByRef hexText As String) As String
    Dim h As String = Trim(hexText)
    Dim outData As String = ""
    Dim i As Integer

    If Len(h) Mod 2 <> 0 Then h = "0" & h

    For i = 1 To Len(h) Step 2
        Dim hi As Integer = HexDigitValue(Asc(Mid(h, i, 1)))
        Dim lo As Integer = HexDigitValue(Asc(Mid(h, i + 1, 1)))
        If hi < 0 Or lo < 0 Then Exit For
        outData &= Chr((hi Shl 4) Or lo)
    Next i

    Return outData
End Function

Type DefineEntry
    nameKey As String
    content As String
End Type

Type ProcLine
    text As String
    kind As Integer
    loopId As Integer
    labelTarget As String
    nsKey As String
End Type

Type LabelMap
    nameKey As String
    stmtIndex As Integer
End Type

Type LoopState
    loopId As Integer
    labelName As String
End Type

Const STMT_NORMAL = 0
Const STMT_GOTO_LABEL = 1
Const STMT_EXIT_LOOP = 2

Private Function FindDefineIndex(defs() As DefineEntry, ByVal defCount As Integer, ByRef keyName As String) As Integer
    Dim k As String = UCase(Trim(keyName))
    Dim i As Integer
    For i = 1 To defCount
        If defs(i).nameKey = k Then Return i
    Next i
    Return 0
End Function

Private Sub UpsertDefine(defs() As DefineEntry, ByRef defCount As Integer, ByRef keyName As String, ByRef content As String)
    Dim norm As String = UCase(Trim(keyName))
    If Len(norm) = 0 Then Exit Sub

    Dim idx As Integer = FindDefineIndex(defs(), defCount, norm)
    If idx <= 0 Then
        defCount += 1
        ReDim Preserve defs(1 To defCount)
        idx = defCount
    End If

    defs(idx).nameKey = norm
    defs(idx).content = content
End Sub

Private Function ReplaceFirstBracketArg(ByRef sourceText As String, ByRef argValue As String) As String
    Dim p1 As Integer = InStr(sourceText, "[")
    If p1 <= 0 Then Return sourceText
    Dim p2 As Integer = InStr(p1 + 1, sourceText, "]")
    If p2 <= 0 Then Return sourceText

    Dim defaultArg As String = Mid(sourceText, p1 + 1, p2 - p1 - 1)
    Dim useArg As String = IIf(Len(argValue) > 0, argValue, defaultArg)
    Return Left(sourceText, p1 - 1) & useArg & Mid(sourceText, p2 + 1)
End Function

Private Function ScopedName(ByRef nsKey As String, ByRef localName As String) As String
    Return UCase(nsKey) & "|" & UCase(Trim(localName))
End Function

Private Function ParseDefineLine(ByRef lineText As String, defs() As DefineEntry, ByRef defCount As Integer) As Integer
    Dim t As String = LTrim(lineText)
    If Len(t) < 6 Then Return 0
    If UCase(Left(t, 6)) <> "DEFINE" Then Return 0

    Dim body As String = Trim(Mid(t, 7))
    If Len(body) = 0 Then Return -1

    Dim items() As String
    Dim itemCount As Integer = 0
    Dim depth As Integer = 0
    Dim chunk As String = ""
    Dim i As Integer

    For i = 1 To Len(body)
        Dim ch As String = Mid(body, i, 1)
        If ch = "[" Then
            depth += 1
            chunk &= ch
        ElseIf ch = "]" Then
            If depth > 0 Then depth -= 1
            chunk &= ch
        ElseIf ch = "," And depth = 0 Then
            itemCount += 1
            ReDim Preserve items(1 To itemCount)
            items(itemCount) = Trim(chunk)
            chunk = ""
        Else
            chunk &= ch
        End If
    Next i

    If Len(Trim(chunk)) > 0 Then
        itemCount += 1
        ReDim Preserve items(1 To itemCount)
        items(itemCount) = Trim(chunk)
    End If

    For i = 1 To itemCount
        Dim one As String = items(i)
        Dim p1 As Integer = InStr(one, "[")
        Dim p2 As Integer = InStr(p1 + 1, one, "]")
        Dim p3 As Integer = InStr(p2 + 1, one, "[")
        Dim p4 As Integer = InStr(p3 + 1, one, "]")
        If p1 > 0 And p2 > p1 And p3 > p2 And p4 > p3 Then
            Dim dName As String = Mid(one, p1 + 1, p2 - p1 - 1)
            Dim dContent As String = Mid(one, p3 + 1, p4 - p3 - 1)
            UpsertDefine(defs(), defCount, dName, dContent)
        End If
    Next i

    Return -1
End Function

Private Function ApplyDefinesOnce(ByRef inText As String, defs() As DefineEntry, ByVal defCount As Integer, ByRef currentNs As String) As String
    Dim outText As String = ""
    Dim i As Integer = 1

    While i <= Len(inText)
        Dim ch As String = Mid(inText, i, 1)
        If ch = "[" Then
            Dim p2 As Integer = InStr(i + 1, inText, "]")
            If p2 > 0 Then
                Dim keyName As String = Mid(inText, i + 1, p2 - i - 1)
                Dim idx As Integer = FindDefineIndex(defs(), defCount, ScopedName(currentNs, keyName))
                If idx <= 0 Then idx = FindDefineIndex(defs(), defCount, keyName)
                If idx > 0 Then
                    Dim argValue As String = ""
                    Dim consumeTo As Integer = p2
                    If p2 < Len(inText) And Mid(inText, p2 + 1, 1) = "(" Then
                        Dim p3 As Integer = InStr(p2 + 2, inText, ")")
                        If p3 > 0 Then
                            argValue = Mid(inText, p2 + 2, p3 - p2 - 2)
                            consumeTo = p3
                        End If
                    End If

                    Dim repl As String = ReplaceFirstBracketArg(defs(idx).content, argValue)
                    outText &= repl
                    i = consumeTo + 1
                    Continue While
                End If
            End If
        End If

        outText &= ch
        i += 1
    Wend

    Return outText
End Function

Private Function ApplyDefinesRecursive(ByRef inText As String, defs() As DefineEntry, ByVal defCount As Integer) As String
    Dim cur As String = inText
    Dim pass As Integer
    Dim fallbackNs As String = ""
    For pass = 1 To 8
        Dim nxt As String = ApplyDefinesOnce(cur, defs(), defCount, fallbackNs)
        If nxt = cur Then Exit For
        cur = nxt
    Next pass
    Return cur
End Function

Private Function ApplyDefinesRecursiveScoped(ByRef inText As String, defs() As DefineEntry, ByVal defCount As Integer, ByRef currentNs As String) As String
    Dim cur As String = inText
    Dim pass As Integer
    For pass = 1 To 8
        Dim nxt As String = ApplyDefinesOnce(cur, defs(), defCount, currentNs)
        If nxt = cur Then Exit For
        cur = nxt
    Next pass
    Return cur
End Function

Private Function ExtractQuotedPath(ByRef lineText As String, ByRef outPath As String) As Integer
    outPath = ""
    Dim p1 As Integer = InStr(lineText, Chr(34))
    If p1 <= 0 Then Return 0
    Dim p2 As Integer = InStr(p1 + 1, lineText, Chr(34))
    If p2 <= p1 Then Return 0
    outPath = Mid(lineText, p1 + 1, p2 - p1 - 1)
    Return -1
End Function

Private Function ExpandIncludesText(ByRef sourcePath As String, ByRef sourceText As String, ByRef outText As String, ByRef errMsg As String, includeStack() As String, ByRef stackCount As Integer) As Integer
    Dim fullSourcePath As String = ToAbsolutePathLocal(CurDir(), sourcePath)
    Dim sourceDir As String = PathDir(fullSourcePath)
    Dim normalized As String = StripCR(sourceText)
    outText = "##BB:NS=" & fullSourcePath

    Dim posStart As Integer = 1
    While posStart <= Len(normalized)
        Dim br As Integer = InStr(posStart, normalized, Chr(10))
        Dim oneLine As String
        If br = 0 Then
            oneLine = Mid(normalized, posStart)
            posStart = Len(normalized) + 1
        Else
            oneLine = Mid(normalized, posStart, br - posStart)
            posStart = br + 1
        End If

        Dim t As String = LTrim(oneLine)
        If UCase(Left(t, 7)) = "INCLUDE" Then
            Dim relPath As String
            If ExtractQuotedPath(t, relPath) <> 0 Then
                Dim incPath As String = ToAbsolutePathLocal(sourceDir, relPath)
                Dim i As Integer
                For i = 1 To stackCount
                    If UCase(includeStack(i)) = UCase(incPath) Then
                        errMsg = "Include recursivo detectado: " & incPath
                        Return 0
                    End If
                Next i

                Dim incText As String
                If ReadTextFile(incPath, incText, errMsg) = 0 Then Return 0

                stackCount += 1
                ReDim Preserve includeStack(1 To stackCount)
                includeStack(stackCount) = incPath

                Dim expanded As String
                If ExpandIncludesText(incPath, incText, expanded, errMsg, includeStack(), stackCount) = 0 Then Return 0

                stackCount -= 1
                If stackCount > 0 Then
                    ReDim Preserve includeStack(1 To stackCount)
                Else
                    Erase includeStack
                End If

                If Len(outText) > 0 And Right(outText, 1) <> Chr(10) Then outText &= Chr(10)
                outText &= expanded
                If Len(outText) = 0 Or Right(outText, 1) <> Chr(10) Then outText &= Chr(10)
                Continue While
            End If
        End If

        If Len(outText) > 0 Then outText &= Chr(10)
        outText &= oneLine
    Wend

    Return -1
End Function

Private Function FindLabelIndex(labels() As LabelMap, ByVal labelCount As Integer, ByRef nameKey As String) As Integer
    Dim key As String = UCase(Trim(nameKey))
    Dim i As Integer
    For i = 1 To labelCount
        If labels(i).nameKey = key Then Return i
    Next i
    Return 0
End Function

Private Function IsValidLabelName(ByRef nameText As String) As Integer
    Dim s As String = Trim(nameText)
    If Len(s) = 0 Then Return 0
    If s = "@" Then Return -1

    Dim i As Integer
    For i = 1 To Len(s)
        Dim c As Integer = Asc(Mid(s, i, 1))
        Dim ok As Integer = 0
        If c >= Asc("A") And c <= Asc("Z") Then ok = -1
        If c >= Asc("a") And c <= Asc("z") Then ok = -1
        If c >= Asc("0") And c <= Asc("9") Then ok = -1
        If c = Asc("_") Then ok = -1
        If ok = 0 Then Return 0
    Next i

    Dim firstC As Integer = Asc(Left(s, 1))
    If firstC >= Asc("0") And firstC <= Asc("9") Then Return 0

    Return -1
End Function

Private Function ResolveLabelRefs(ByRef textIn As String, ByVal stmtIndex As Integer, stmtLineNos() As Integer, labels() As LabelMap, ByVal labelCount As Integer, ByRef currentNs As String, ByRef errMsg As String) As String
    Dim outText As String = ""
    Dim i As Integer = 1
    Dim inString As Integer = 0

    While i <= Len(textIn)
        Dim ch As String = Mid(textIn, i, 1)

        If ch = Chr(34) Then
            inString = Not inString
            outText &= ch
            i += 1
            Continue While
        End If

        If inString = 0 And ch = "{" Then
            Dim p2 As Integer = InStr(i + 1, textIn, "}")
            If p2 > i Then
                Dim labelName As String = Mid(textIn, i + 1, p2 - i - 1)
                Dim key As String = UCase(Trim(labelName))
                Dim replacement As String

                If key = "@" Then
                    replacement = Trim(Str(stmtLineNos(stmtIndex)))
                Else
                    Dim idx As Integer = FindLabelIndex(labels(), labelCount, ScopedName(currentNs, key))
                    If idx <= 0 Then idx = FindLabelIndex(labels(), labelCount, key)
                    If idx <= 0 Then
                        errMsg = "Label nao encontrado: {" & labelName & "}"
                        Return ""
                    End If
                    replacement = Trim(Str(stmtLineNos(labels(idx).stmtIndex)))
                End If

                outText &= replacement
                i = p2 + 1
                Continue While
            End If
        End If

        outText &= ch
        i += 1
    Wend

    Return outText
End Function

Private Function PreprocessDignified(ByRef sourceText As String, ByRef srcPath As String, ByRef outAmxText As String, ByRef outAmxOverride As String, ByRef errMsg As String) As Integer
    errMsg = ""
    outAmxText = ""
    outAmxOverride = ""

    Dim lineStart As Integer = IntSetting("cfg.badig.line_start", 10, 1, 65535)
    Dim lineStep As Integer = IntSetting("cfg.badig.line_step", 10, 1, 9999)
    Dim stripSpaces As Integer = IsTrueSetting("cfg.badig.strip_spaces", 0)
    Dim uppercaseAll As Integer = IsTrueSetting("cfg.badig.capitalize_all", 0)
    Dim remHeaderText As String = Trim(DbGetSetting("cfg.badig.rem_header", ""))
    Dim useRemHeader As Integer = 0
    Dim convertPrintMode As String = NormalizeConvertPrintMode(DbGetSetting("cfg.msxbasic.badig.convert_print", ""))
    Dim ifJumpMode As String = NormalizeIfJumpMode(DbGetSetting("cfg.msxbasic.badig.strip_then_goto", ""))
    Dim currentNs As String = UCase(ToAbsolutePathLocal(CurDir(), srcPath))

    Dim includeStack() As String
    Dim stackCount As Integer = 1
    ReDim includeStack(1 To 1)
    includeStack(1) = srcPath

    Dim expandedSource As String
    If ExpandIncludesText(srcPath, sourceText, expandedSource, errMsg, includeStack(), stackCount) = 0 Then Return 0

    Dim defs() As DefineEntry
    Dim defCount As Integer = 0

    Dim stmts() As ProcLine
    Dim stmtCount As Integer = 0

    Dim labels() As LabelMap
    Dim labelCount As Integer = 0

    Dim loopStack() As LoopState
    Dim loopTop As Integer = 0
    Dim nextLoopId As Integer = 1
    Dim loopExitTarget() As Integer
    ReDim loopExitTarget(1 To 1)

    Dim pendingLabels() As String
    Dim pendingCount As Integer = 0

    Dim posStart As Integer = 1
    Dim normalized As String = StripCR(expandedSource)

    While posStart <= Len(normalized)
        Dim br As Integer = InStr(posStart, normalized, Chr(10))
        Dim oneLine As String
        If br = 0 Then
            oneLine = Mid(normalized, posStart)
            posStart = Len(normalized) + 1
        Else
            oneLine = Mid(normalized, posStart, br - posStart)
            posStart = br + 1
        End If

        Dim t As String = Trim(oneLine)
        If Len(t) = 0 Then Continue While

        Dim upperT As String = UCase(t)

        If Left(upperT, 5) = "##BB:" Then
            Dim payload As String = Trim(Mid(t, 6))
            Dim eqPos As Integer = InStr(payload, "=")
            If eqPos > 0 Then
                Dim rk As String = LCase(Trim(Left(payload, eqPos - 1)))
                Dim rv As String = Trim(Mid(payload, eqPos + 1))
                If rk = "ns" Then
                    If Len(rv) > 0 Then currentNs = UCase(rv)
                ElseIf rk = "export_file" Then
                    If Len(rv) > 0 Then
                        outAmxOverride = ToAbsolutePathLocal(PathDir(srcPath), rv)
                    End If
                ElseIf rk = "arguments" Then
                    Dim args As String = " " & rv & " "
                    Dim p As Integer
                    p = InStr(args, " -ss ")
                    If p > 0 Then stripSpaces = -1
                    p = InStr(args, " -ca ")
                    If p > 0 Then uppercaseAll = -1

                    p = InStr(args, " -rh ")
                    If p > 0 Then useRemHeader = -1

                    p = InStr(args, " -ls ")
                    If p > 0 Then
                        Dim tail As String = Mid(args, p + 5)
                        lineStart = ValInt(Trim(tail))
                        If lineStart < 1 Then lineStart = 1
                    End If

                    p = InStr(args, " -lp ")
                    If p > 0 Then
                        Dim tail2 As String = Mid(args, p + 5)
                        lineStep = ValInt(Trim(tail2))
                        If lineStep < 1 Then lineStep = 1
                    End If
                ElseIf rk = "help" Then
                    ' Mantem compatibilidade de parsing de remtag sem alterar pipeline.
                End If
            End If
            Continue While
        End If

        If Left(t, 2) = "##" Then Continue While

        Dim parseLine As String = t
        If UCase(Left(parseLine, 6)) = "DEFINE" Then
            Dim body As String = Trim(Mid(parseLine, 7))
            If Len(body) > 0 Then
                Dim items() As String
                Dim itemCount As Integer = 0
                Dim depth As Integer = 0
                Dim chunk As String = ""
                Dim di As Integer
                For di = 1 To Len(body)
                    Dim dch As String = Mid(body, di, 1)
                    If dch = "[" Then
                        depth += 1
                        chunk &= dch
                    ElseIf dch = "]" Then
                        If depth > 0 Then depth -= 1
                        chunk &= dch
                    ElseIf dch = "," And depth = 0 Then
                        itemCount += 1
                        ReDim Preserve items(1 To itemCount)
                        items(itemCount) = Trim(chunk)
                        chunk = ""
                    Else
                        chunk &= dch
                    End If
                Next di
                If Len(Trim(chunk)) > 0 Then
                    itemCount += 1
                    ReDim Preserve items(1 To itemCount)
                    items(itemCount) = Trim(chunk)
                End If

                For di = 1 To itemCount
                    Dim one As String = items(di)
                    Dim p1 As Integer = InStr(one, "[")
                    Dim p2 As Integer = InStr(p1 + 1, one, "]")
                    Dim p3 As Integer = InStr(p2 + 1, one, "[")
                    Dim p4 As Integer = InStr(p3 + 1, one, "]")
                    If p1 > 0 And p2 > p1 And p3 > p2 And p4 > p3 Then
                        Dim dName As String = Mid(one, p1 + 1, p2 - p1 - 1)
                        Dim dContent As String = Mid(one, p3 + 1, p4 - p3 - 1)
                        UpsertDefine(defs(), defCount, ScopedName(currentNs, dName), dContent)
                    End If
                Next di
            End If
            Continue While
        End If

        t = ApplyDefinesRecursiveScoped(t, defs(), defCount, currentNs)
        t = Trim(t)
        If Len(t) = 0 Then Continue While

        Do While Left(t, 1) = "{" And InStr(t, "}") > 1
            Dim p2 As Integer = InStr(t, "}")
            Dim lbl As String = Mid(t, 2, p2 - 2)
            If IsValidLabelName(lbl) = 0 Then
                errMsg = "Label invalido: " & lbl
                Return 0
            End If
            pendingCount += 1
            ReDim Preserve pendingLabels(1 To pendingCount)
            pendingLabels(pendingCount) = ScopedName(currentNs, lbl)
            t = Trim(Mid(t, p2 + 1))
            If Len(t) > 0 And Left(t, 1) = ":" Then t = Trim(Mid(t, 2))
        Loop

        If Len(t) = 0 Then Continue While

        If Right(t, 1) = "{" Then
            Dim loopLbl As String = Trim(Left(t, Len(t) - 1))
            If IsValidLabelName(loopLbl) = 0 Then
                errMsg = "Loop label invalido: " & loopLbl
                Return 0
            End If

            pendingCount += 1
            ReDim Preserve pendingLabels(1 To pendingCount)
            pendingLabels(pendingCount) = ScopedName(currentNs, loopLbl)

            loopTop += 1
            ReDim Preserve loopStack(1 To loopTop)
            loopStack(loopTop).loopId = nextLoopId
            loopStack(loopTop).labelName = ScopedName(currentNs, loopLbl)

            If nextLoopId > UBound(loopExitTarget) Then ReDim Preserve loopExitTarget(1 To nextLoopId)
            loopExitTarget(nextLoopId) = 0
            nextLoopId += 1
            Continue While
        End If

        Dim stmt As ProcLine
        stmt.kind = STMT_NORMAL
        stmt.loopId = IIf(loopTop > 0, loopStack(loopTop).loopId, 0)
        stmt.labelTarget = ""
        stmt.nsKey = currentNs

        If t = "}" Then
            If loopTop <= 0 Then
                errMsg = "Fechamento de loop sem abertura."
                Return 0
            End If
            stmt.kind = STMT_GOTO_LABEL
            stmt.labelTarget = loopStack(loopTop).labelName
        ElseIf LCase(t) = "exit" Then
            If loopTop <= 0 Then
                errMsg = "exit fora de loop."
                Return 0
            End If
            stmt.kind = STMT_EXIT_LOOP
            stmt.loopId = loopStack(loopTop).loopId
        Else
            stmt.text = t
        End If

        stmtCount += 1
        ReDim Preserve stmts(1 To stmtCount)
        stmts(stmtCount) = stmt

        Dim i As Integer
        If pendingCount > 0 Then
            For i = 1 To pendingCount
                Dim keyLbl As String = pendingLabels(i)
                If FindLabelIndex(labels(), labelCount, keyLbl) > 0 Then
                    errMsg = "Label duplicado: " & keyLbl
                    Return 0
                End If
                labelCount += 1
                ReDim Preserve labels(1 To labelCount)
                labels(labelCount).nameKey = keyLbl
                labels(labelCount).stmtIndex = stmtCount
            Next i
            pendingCount = 0
            Erase pendingLabels
        End If

        If t = "}" Then
            loopExitTarget(loopStack(loopTop).loopId) = stmtCount + 1
            loopTop -= 1
            If loopTop > 0 Then
                ReDim Preserve loopStack(1 To loopTop)
            Else
                Erase loopStack
            End If
        End If
    Wend

    If loopTop > 0 Then
        errMsg = "Ha loop labels sem fechamento."
        Return 0
    End If

    If pendingCount > 0 Then
        errMsg = "Label no final sem comando associado."
        Return 0
    End If

    If stmtCount <= 0 Then
        errMsg = "Fonte vazia apos preprocessamento."
        Return 0
    End If

    Dim stmtLineNos(1 To stmtCount) As Integer
    Dim i As Integer
    For i = 1 To stmtCount
        stmtLineNos(i) = lineStart + (i - 1) * lineStep
    Next i

    Dim outCount As Integer = 0
    For i = 1 To stmtCount
        Dim body As String = ""
        If stmts(i).kind = STMT_GOTO_LABEL Then
            Dim idx As Integer = FindLabelIndex(labels(), labelCount, stmts(i).labelTarget)
            If idx <= 0 Then
                errMsg = "Loop label inexistente: " & stmts(i).labelTarget
                Return 0
            End If
            body = "GOTO " & Trim(Str(stmtLineNos(labels(idx).stmtIndex)))
        ElseIf stmts(i).kind = STMT_EXIT_LOOP Then
            If stmts(i).loopId <= 0 Or stmts(i).loopId > UBound(loopExitTarget) Then
                errMsg = "exit com loop invalido."
                Return 0
            End If
            Dim targetStmt As Integer = loopExitTarget(stmts(i).loopId)
            If targetStmt <= 0 Or targetStmt > stmtCount Then
                errMsg = "exit sem destino de fechamento."
                Return 0
            End If
            body = "GOTO " & Trim(Str(stmtLineNos(targetStmt)))
        Else
            body = ResolveLabelRefs(stmts(i).text, i, stmtLineNos(), labels(), labelCount, stmts(i).nsKey, errMsg)
            If Len(errMsg) > 0 Then Return 0
            If stmts(i).loopId > 0 Then
                If stmts(i).loopId > UBound(loopExitTarget) Then
                    errMsg = "exit com loop invalido."
                    Return 0
                End If
                Dim targetStmt As Integer = loopExitTarget(stmts(i).loopId)
                If targetStmt <= 0 Or targetStmt > stmtCount Then
                    errMsg = "exit sem destino de fechamento."
                    Return 0
                End If
                body = RewriteInlineExitForLoop(body, stmtLineNos(targetStmt))
            End If
        End If

        If stripSpaces <> 0 Then body = CollapseSpacesOutsideStrings(body)
        body = ConvertPrintByMode(body, convertPrintMode)
        body = RewriteIfThenGotoByMode(body, ifJumpMode)
        If uppercaseAll <> 0 Then body = UCase(body)

        Dim outLine As String = Trim(Str(stmtLineNos(i))) & " " & body
        If outCount > 0 Then outAmxText &= Chr(13) & Chr(10)
        outAmxText &= outLine
        outCount += 1
    Next i

    If useRemHeader <> 0 And Len(remHeaderText) > 0 Then
        ' Remtag reconhecida; efeito textual completo sera aplicado em evolucao futura.
    End If

    Return -1
End Function

Private Sub InitKeywordTable()
    If gKeywordInit <> 0 Then Exit Sub

    gKeywordCount = 0

    #Macro ADDTOK(textValue, tokenHexValue, jumpFlag, literalFlag)
        gKeywordCount += 1
        gKeywords(gKeywordCount).kw = textValue
        gKeywords(gKeywordCount).tokHex = tokenHexValue
        gKeywords(gKeywordCount).tokData = HexToBin(tokenHexValue)
        gKeywords(gKeywordCount).isJump = jumpFlag
        gKeywords(gKeywordCount).literalMode = literalFlag
    #EndMacro

    ADDTOK(">", "ee", 0, TOK_LITERAL_NONE)
    ADDTOK("PAINT", "bf", 0, TOK_LITERAL_NONE)
    ADDTOK("=", "ef", 0, TOK_LITERAL_NONE)
    ADDTOK("ERROR", "a6", 0, TOK_LITERAL_NONE)
    ADDTOK("ERR", "e2", 1, TOK_LITERAL_NONE)
    ADDTOK("<", "f0", 0, TOK_LITERAL_NONE)
    ADDTOK("+", "f1", 0, TOK_LITERAL_NONE)
    ADDTOK("FIELD", "b1", 0, TOK_LITERAL_NONE)
    ADDTOK("PLAY", "c1", 0, TOK_LITERAL_NONE)
    ADDTOK("-", "f2", 0, TOK_LITERAL_NONE)
    ADDTOK("FILES", "b7", 0, TOK_LITERAL_NONE)
    ADDTOK("POINT", "ed", 0, TOK_LITERAL_NONE)
    ADDTOK("*", "f3", 0, TOK_LITERAL_NONE)
    ADDTOK("POKE", "98", 0, TOK_LITERAL_NONE)
    ADDTOK("/", "f4", 0, TOK_LITERAL_NONE)
    ADDTOK("FN", "de", 0, TOK_LITERAL_NONE)
    ADDTOK("^", "f5", 0, TOK_LITERAL_NONE)
    ADDTOK("FOR", "82", 0, TOK_LITERAL_NONE)
    ADDTOK("PRESET", "c3", 0, TOK_LITERAL_NONE)
    ADDTOK("\\", "fc", 0, TOK_LITERAL_NONE)
    ADDTOK("PRINT", "91", 0, TOK_LITERAL_NONE)
    ADDTOK("?", "91", 0, TOK_LITERAL_NONE)
    ADDTOK("PSET", "c2", 0, TOK_LITERAL_NONE)
    ADDTOK("AND", "f6", 0, TOK_LITERAL_NONE)
    ADDTOK("GET", "b2", 0, TOK_LITERAL_NONE)
    ADDTOK("PUT", "b3", 0, TOK_LITERAL_NONE)
    ADDTOK("GOSUB", "8d", 1, TOK_LITERAL_NONE)
    ADDTOK("READ", "87", 0, TOK_LITERAL_NONE)
    ADDTOK("GOTO", "89", 1, TOK_LITERAL_NONE)
    ADDTOK("ATTR$", "e9", 0, TOK_LITERAL_NONE)
    ADDTOK("RENUM", "aa", 1, TOK_LITERAL_NONE)
    ADDTOK("AUTO", "a9", 1, TOK_LITERAL_NONE)
    ADDTOK("IF", "8b", 0, TOK_LITERAL_NONE)
    ADDTOK("RESTORE", "8c", 1, TOK_LITERAL_NONE)
    ADDTOK("BASE", "c9", 0, TOK_LITERAL_NONE)
    ADDTOK("IMP", "fa", 0, TOK_LITERAL_NONE)
    ADDTOK("RESUME", "a7", 1, TOK_LITERAL_NONE)
    ADDTOK("BEEP", "c0", 0, TOK_LITERAL_NONE)
    ADDTOK("INKEY$", "ec", 0, TOK_LITERAL_NONE)
    ADDTOK("RETURN", "8e", 1, TOK_LITERAL_NONE)
    ADDTOK("BLOAD", "cf", 0, TOK_LITERAL_NONE)
    ADDTOK("INPUT", "85", 0, TOK_LITERAL_NONE)
    ADDTOK("BSAVE", "d0", 0, TOK_LITERAL_NONE)
    ADDTOK("INSTR", "e5", 0, TOK_LITERAL_NONE)
    ADDTOK("RSET", "b9", 0, TOK_LITERAL_NONE)
    ADDTOK("CALL", "ca", 0, TOK_LITERAL_DATA_REM)
    ADDTOK("_", "5f", 0, TOK_LITERAL_DATA_REM)
    ADDTOK("RUN", "8a", 1, TOK_LITERAL_NONE)
    ADDTOK("IPL", "d5", 0, TOK_LITERAL_NONE)
    ADDTOK("SAVE", "ba", 0, TOK_LITERAL_NONE)
    ADDTOK("KEY", "cc", 0, TOK_LITERAL_NONE)
    ADDTOK("SCREEN", "c5", 0, TOK_LITERAL_NONE)
    ADDTOK("KILL", "d4", 0, TOK_LITERAL_NONE)
    ADDTOK("SET", "d2", 0, TOK_LITERAL_NONE)
    ADDTOK("CIRCLE", "bc", 0, TOK_LITERAL_NONE)
    ADDTOK("CLEAR", "92", 0, TOK_LITERAL_NONE)
    ADDTOK("CLOAD", "9b", 0, TOK_LITERAL_NONE)
    ADDTOK("LET", "88", 0, TOK_LITERAL_NONE)
    ADDTOK("SOUND", "c4", 0, TOK_LITERAL_NONE)
    ADDTOK("CLOSE", "b4", 0, TOK_LITERAL_NONE)
    ADDTOK("LFILES", "bb", 0, TOK_LITERAL_NONE)
    ADDTOK("CLS", "9f", 0, TOK_LITERAL_NONE)
    ADDTOK("LINE", "af", 0, TOK_LITERAL_NONE)
    ADDTOK("SPC(", "df", 0, TOK_LITERAL_NONE)
    ADDTOK("CMD", "d7", 0, TOK_LITERAL_NONE)
    ADDTOK("LIST", "93", 1, TOK_LITERAL_NONE)
    ADDTOK("SPRITE", "c7", 0, TOK_LITERAL_NONE)
    ADDTOK("COLOR", "bd", 0, TOK_LITERAL_NONE)
    ADDTOK("LLIST", "9e", 1, TOK_LITERAL_NONE)
    ADDTOK("CONT", "99", 0, TOK_LITERAL_NONE)
    ADDTOK("LOAD", "b5", 0, TOK_LITERAL_NONE)
    ADDTOK("STEP", "dc", 0, TOK_LITERAL_NONE)
    ADDTOK("COPY", "d6", 0, TOK_LITERAL_NONE)
    ADDTOK("LOCATE", "d8", 0, TOK_LITERAL_NONE)
    ADDTOK("STOP", "90", 0, TOK_LITERAL_NONE)
    ADDTOK("CSAVE", "9a", 0, TOK_LITERAL_NONE)
    ADDTOK("CSRLIN", "e8", 0, TOK_LITERAL_NONE)
    ADDTOK("STRING$", "e3", 0, TOK_LITERAL_NONE)
    ADDTOK("LPRINT", "9d", 0, TOK_LITERAL_NONE)
    ADDTOK("SWAP", "a4", 0, TOK_LITERAL_NONE)
    ADDTOK("LSET", "b8", 0, TOK_LITERAL_NONE)
    ADDTOK("TAB(", "db", 0, TOK_LITERAL_NONE)
    ADDTOK("MAX", "cd", 0, TOK_LITERAL_NONE)
    ADDTOK("DATA", "84", 0, TOK_LITERAL_DATA_REM)
    ADDTOK("MERGE", "b6", 0, TOK_LITERAL_NONE)
    ADDTOK("THEN", "da", 1, TOK_LITERAL_NONE)
    ADDTOK("TIME", "cb", 0, TOK_LITERAL_NONE)
    ADDTOK("TO", "d9", 0, TOK_LITERAL_NONE)
    ADDTOK("DEFDBL", "ae", 0, TOK_LITERAL_NONE)
    ADDTOK("DEFINT", "ac", 0, TOK_LITERAL_NONE)
    ADDTOK("DEFSTR", "ab", 0, TOK_LITERAL_NONE)
    ADDTOK("TROFF", "a3", 0, TOK_LITERAL_NONE)
    ADDTOK("DEFSNG", "ad", 0, TOK_LITERAL_NONE)
    ADDTOK("TRON", "a2", 0, TOK_LITERAL_NONE)
    ADDTOK("DEF", "97", 0, TOK_LITERAL_NONE)
    ADDTOK("MOD", "fb", 0, TOK_LITERAL_NONE)
    ADDTOK("USING", "e4", 0, TOK_LITERAL_NONE)
    ADDTOK("DELETE", "a8", 1, TOK_LITERAL_NONE)
    ADDTOK("MOTOR", "ce", 0, TOK_LITERAL_NONE)
    ADDTOK("USR", "dd", 0, TOK_LITERAL_NONE)
    ADDTOK("DIM", "86", 0, TOK_LITERAL_NONE)
    ADDTOK("NAME", "d3", 0, TOK_LITERAL_NONE)
    ADDTOK("DRAW", "be", 0, TOK_LITERAL_NONE)
    ADDTOK("NEW", "94", 0, TOK_LITERAL_NONE)
    ADDTOK("VARPTR", "e7", 0, TOK_LITERAL_NONE)
    ADDTOK("NEXT", "83", 0, TOK_LITERAL_NONE)
    ADDTOK("VDP", "c8", 0, TOK_LITERAL_NONE)
    ADDTOK("DSKI$", "ea", 0, TOK_LITERAL_NONE)
    ADDTOK("NOT", "e0", 0, TOK_LITERAL_NONE)
    ADDTOK("DSKO$", "d1", 0, TOK_LITERAL_NONE)
    ADDTOK("VPOKE", "c6", 0, TOK_LITERAL_NONE)
    ADDTOK("OFF", "eb", 0, TOK_LITERAL_NONE)
    ADDTOK("WAIT", "96", 0, TOK_LITERAL_NONE)
    ADDTOK("END", "81", 0, TOK_LITERAL_NONE)
    ADDTOK("ON", "95", 0, TOK_LITERAL_NONE)
    ADDTOK("WIDTH", "a0", 0, TOK_LITERAL_NONE)
    ADDTOK("OPEN", "b0", 0, TOK_LITERAL_NONE)
    ADDTOK("XOR", "f8", 0, TOK_LITERAL_NONE)
    ADDTOK("EQV", "f9", 0, TOK_LITERAL_NONE)
    ADDTOK("OR", "f7", 0, TOK_LITERAL_NONE)
    ADDTOK("ERASE", "a5", 0, TOK_LITERAL_NONE)
    ADDTOK("OUT", "9c", 0, TOK_LITERAL_NONE)
    ADDTOK("ERL", "e1", 1, TOK_LITERAL_NONE)
    ADDTOK("REM", "8f", 0, TOK_LITERAL_DATA_REM)

    ADDTOK("PDL", "ffa4", 0, TOK_LITERAL_NONE)
    ADDTOK("EXP", "ff8b", 0, TOK_LITERAL_NONE)
    ADDTOK("PEEK", "ff97", 0, TOK_LITERAL_NONE)
    ADDTOK("FIX", "ffa1", 0, TOK_LITERAL_NONE)
    ADDTOK("POS", "ff91", 0, TOK_LITERAL_NONE)
    ADDTOK("FPOS", "ffa7", 0, TOK_LITERAL_NONE)
    ADDTOK("ABS", "ff86", 0, TOK_LITERAL_NONE)
    ADDTOK("FRE", "ff8f", 0, TOK_LITERAL_NONE)
    ADDTOK("ASC", "ff95", 0, TOK_LITERAL_NONE)
    ADDTOK("ATN", "ff8e", 0, TOK_LITERAL_NONE)
    ADDTOK("HEX$", "ff9b", 0, TOK_LITERAL_NONE)
    ADDTOK("BIN$", "ff9d", 0, TOK_LITERAL_NONE)
    ADDTOK("INP", "ff90", 0, TOK_LITERAL_NONE)
    ADDTOK("RIGHT$", "ff82", 0, TOK_LITERAL_NONE)
    ADDTOK("RND", "ff88", 0, TOK_LITERAL_NONE)
    ADDTOK("INT", "ff85", 0, TOK_LITERAL_NONE)
    ADDTOK("CDBL", "ffa0", 0, TOK_LITERAL_NONE)
    ADDTOK("CHR$", "ff96", 0, TOK_LITERAL_NONE)
    ADDTOK("CINT", "ff9e", 0, TOK_LITERAL_NONE)
    ADDTOK("LEFT$", "ff81", 0, TOK_LITERAL_NONE)
    ADDTOK("SGN", "ff84", 0, TOK_LITERAL_NONE)
    ADDTOK("LEN", "ff92", 0, TOK_LITERAL_NONE)
    ADDTOK("SIN", "ff89", 0, TOK_LITERAL_NONE)
    ADDTOK("SPACE$", "ff99", 0, TOK_LITERAL_NONE)
    ADDTOK("SQR", "ff87", 0, TOK_LITERAL_NONE)
    ADDTOK("LOC(", "ffac28", 0, TOK_LITERAL_NONE)
    ADDTOK("STICK", "ffa2", 0, TOK_LITERAL_NONE)
    ADDTOK("COS", "ff8c", 0, TOK_LITERAL_NONE)
    ADDTOK("LOF", "ffad", 0, TOK_LITERAL_NONE)
    ADDTOK("STR$", "ff93", 0, TOK_LITERAL_NONE)
    ADDTOK("CSNG", "ff9f", 0, TOK_LITERAL_NONE)
    ADDTOK("LOG", "ff8a", 0, TOK_LITERAL_NONE)
    ADDTOK("STRIG", "ffa3", 0, TOK_LITERAL_NONE)
    ADDTOK("LPOS", "ff9c", 0, TOK_LITERAL_NONE)
    ADDTOK("CVD", "ffaa", 0, TOK_LITERAL_NONE)
    ADDTOK("CVI", "ffa8", 0, TOK_LITERAL_NONE)
    ADDTOK("CVS", "ffa9", 0, TOK_LITERAL_NONE)
    ADDTOK("TAN", "ff8d", 0, TOK_LITERAL_NONE)
    ADDTOK("MID$", "ff83", 0, TOK_LITERAL_NONE)
    ADDTOK("MKD$", "ffb0", 0, TOK_LITERAL_NONE)
    ADDTOK("MKI$", "ffae", 0, TOK_LITERAL_NONE)
    ADDTOK("MKS$", "ffaf", 0, TOK_LITERAL_NONE)
    ADDTOK("VAL", "ff94", 0, TOK_LITERAL_NONE)
    ADDTOK("DSKF", "ffa6", 0, TOK_LITERAL_NONE)
    ADDTOK("VPEEK", "ff98", 0, TOK_LITERAL_NONE)
    ADDTOK("OCT$", "ff9a", 0, TOK_LITERAL_NONE)
    ADDTOK("EOF", "ffab", 0, TOK_LITERAL_NONE)
    ADDTOK("PAD", "ffa5", 0, TOK_LITERAL_NONE)

    ADDTOK("'", "3a8fe6", 0, TOK_LITERAL_DATA_REM)
    ADDTOK("ELSE", "3aa1", 1, TOK_LITERAL_NONE)
    ADDTOK("AS", "4153", 0, TOK_LITERAL_NONE)

    gKeywordInit = -1
End Sub

Private Function TokenizeLineBody(ByRef bodyText As String) As String
    InitKeywordTable()

    Dim outBin As String = ""
    Dim src As String = bodyText

    While Len(src) > 0
        Dim matched As Integer = 0
        Dim k As Integer

        For k = 1 To gKeywordCount
            Dim kw As String = gKeywords(k).kw
            If Len(src) >= Len(kw) And UCase(Left(src, Len(kw))) = kw Then
                outBin &= gKeywords(k).tokData
                src = Mid(src, Len(kw) + 1)
                matched = -1

                If kw = "AS" Then
                    Dim spaceLen As Integer = 0
                    While spaceLen < Len(src) And Mid(src, spaceLen + 1, 1) = " "
                        spaceLen += 1
                    Wend
                    Dim digitLen As Integer = 0
                    While spaceLen + digitLen < Len(src)
                        Dim c As Integer = Asc(Mid(src, spaceLen + digitLen + 1, 1))
                        If c < Asc("0") Or c > Asc("9") Then Exit While
                        digitLen += 1
                        If digitLen >= 2 Then Exit While
                    Wend
                    If digitLen > 0 Then
                        Dim n As Integer = ValInt(Mid(src, spaceLen + 1, digitLen))
                        Dim i As Integer
                        For i = 1 To spaceLen
                            outBin &= Chr(32)
                        Next i
                        outBin &= Chr(n And &HFF)
                        src = Mid(src, spaceLen + digitLen + 1)
                    End If
                End If

                If gKeywords(k).isJump <> 0 Then
                    Do
                        Dim s As Integer = 0
                        While s < Len(src) And Mid(src, s + 1, 1) = " "
                            s += 1
                        Wend
                        Dim p As Integer = s + 1
                        If p > Len(src) Then Exit Do

                        Dim d As Integer = 0
                        While p + d <= Len(src)
                            Dim c As Integer = Asc(Mid(src, p + d, 1))
                            If c < Asc("0") Or c > Asc("9") Then Exit While
                            d += 1
                        Wend

                        If d > 0 Then
                            Dim jumpLine As Integer = ValInt(Mid(src, p, d))
                            Dim i As Integer
                            For i = 1 To s
                                outBin &= Chr(32)
                            Next i
                            outBin &= Chr(&H0E) & Chr(jumpLine And &HFF) & Chr((jumpLine Shr 8) And &HFF)
                            src = Mid(src, p + d)
                        ElseIf Mid(src, p, 1) = "," Then
                            Dim commaLen As Integer = 0
                            While p + commaLen <= Len(src) And Mid(src, p + commaLen, 1) = ","
                                commaLen += 1
                            Wend
                            Dim i As Integer
                            For i = 1 To s
                                outBin &= Chr(32)
                            Next i
                            For i = 1 To commaLen
                                outBin &= ","
                            Next i
                            src = Mid(src, p + commaLen)
                        Else
                            Exit Do
                        End If
                    Loop
                End If

                If gKeywords(k).literalMode = TOK_LITERAL_DATA_REM Then
                    Do While Len(src) > 0
                        Dim c As String = Left(src, 1)
                        If kw = "DATA" And c = ":" Then Exit Do
                        If (kw = "CALL" Or kw = "_") And (c = ":" Or c = "(") Then Exit Do
                        If kw = "CALL" Or kw = "_" Then
                            outBin &= UCase(c)
                        Else
                            outBin &= c
                        End If
                        src = Mid(src, 2)
                        If kw = "REM" Or kw = "'" Then
                            If Len(src) = 0 Then Exit Do
                        End If
                    Loop
                End If

                Exit For
            End If
        Next k

        If matched <> 0 Then Continue While

        Dim firstCh As String = Left(src, 1)
        Dim firstCode As Integer = Asc(firstCh)

        If firstCode >= Asc("0") And firstCode <= Asc("9") Then
            Dim nLen As Integer = 0
            While nLen < Len(src)
                Dim c As Integer = Asc(Mid(src, nLen + 1, 1))
                If c < Asc("0") Or c > Asc("9") Then Exit While
                nLen += 1
            Wend
            If nLen > 0 Then
                Dim nValue As Integer = ValInt(Left(src, nLen))
                If nValue >= 0 And nValue <= 9 Then
                    outBin &= Chr(&H11 + nValue)
                ElseIf nValue >= 10 And nValue <= 255 Then
                    outBin &= Chr(&H0F) & Chr(nValue And &HFF)
                ElseIf nValue >= 256 And nValue <= 32767 Then
                    outBin &= Chr(&H1C) & Chr(nValue And &HFF) & Chr((nValue Shr 8) And &HFF)
                Else
                    outBin &= Left(src, nLen)
                End If
                src = Mid(src, nLen + 1)
                Continue While
            End If
        End If

        If Len(src) >= 2 And UCase(Left(src, 2)) = "&H" Then
            Dim dLen As Integer = 0
            While 2 + dLen < Len(src)
                Dim c As Integer = Asc(Mid(src, 3 + dLen, 1))
                If HexDigitValue(c) < 0 Then Exit While
                dLen += 1
            Wend
            Dim valText As String = Mid(src, 3, dLen)
            Dim nValue As Integer = IIf(Len(valText) > 0, Val("&H" & valText), 0)
            outBin &= Chr(&H0C) & Chr(nValue And &HFF) & Chr((nValue Shr 8) And &HFF)
            src = Mid(src, 3 + dLen)
            Continue While
        End If

        If Len(src) >= 2 And UCase(Left(src, 2)) = "&O" Then
            Dim dLen As Integer = 0
            While 2 + dLen < Len(src)
                Dim c As Integer = Asc(Mid(src, 3 + dLen, 1))
                If c < Asc("0") Or c > Asc("7") Then Exit While
                dLen += 1
            Wend
            Dim nValue As Integer = 0
            Dim i As Integer
            For i = 1 To dLen
                nValue = nValue * 8 + (Asc(Mid(src, 2 + i, 1)) - Asc("0"))
            Next i
            outBin &= Chr(&H0B) & Chr(nValue And &HFF) & Chr((nValue Shr 8) And &HFF)
            src = Mid(src, 3 + dLen)
            Continue While
        End If

        If Len(src) >= 2 And UCase(Left(src, 2)) = "&B" Then
            Dim dLen As Integer = 0
            While 2 + dLen < Len(src)
                Dim c As String = Mid(src, 3 + dLen, 1)
                If c <> "0" And c <> "1" Then Exit While
                dLen += 1
            Wend
            outBin &= Chr(&H26) & Chr(&H42)
            Dim i As Integer
            For i = 1 To dLen
                outBin &= Mid(src, 2 + i, 1)
            Next i
            src = Mid(src, 3 + dLen)
            Continue While
        End If

        If firstCh = Chr(34) Then
            outBin &= firstCh
            src = Mid(src, 2)
            Do While Len(src) > 0
                Dim c As String = Left(src, 1)
                outBin &= c
                src = Mid(src, 2)
                If c = Chr(34) Then Exit Do
            Loop
            Continue While
        End If

        outBin &= UCase(firstCh)
        src = Mid(src, 2)
    Wend

    Return outBin
End Function

Private Function BuildBmxFromAmxText(ByRef amxText As String, ByRef outBinary As String, ByRef errMsg As String) As Integer
    outBinary = ""
    errMsg = ""

    Dim normalized As String = StripCR(amxText)
    Dim bodyLines() As String
    Dim lineNos() As Integer
    Dim lineCount As Integer = 0
    Dim posStart As Integer = 1

    While posStart <= Len(normalized)
        Dim br As Integer = InStr(posStart, normalized, Chr(10))
        Dim oneLine As String
        If br = 0 Then
            oneLine = Mid(normalized, posStart)
            posStart = Len(normalized) + 1
        Else
            oneLine = Mid(normalized, posStart, br - posStart)
            posStart = br + 1
        End If

        oneLine = Trim(oneLine)
        If Len(oneLine) = 0 Then Continue While

        Dim ln As Integer
        Dim body As String
        If ParseNumberedLine(oneLine, ln, body) = 0 Then
            errMsg = "Linha sem numeracao: " & oneLine
            Return 0
        End If

        lineCount += 1
        ReDim Preserve bodyLines(1 To lineCount)
        ReDim Preserve lineNos(1 To lineCount)
        bodyLines(lineCount) = TokenizeLineBody(body)
        lineNos(lineCount) = ln
    Wend

    If lineCount = 0 Then
        errMsg = "Arquivo AMX vazio."
        Return 0
    End If

    Dim outBin As String = Chr(&HFF)
    Dim nextAddr As UInteger = &H8001
    Dim i As Integer

    For i = 1 To lineCount
        Dim lineData As String = bodyLines(i)
        Dim lineLen As Integer = Len(lineData)
        Dim addrAfter As UInteger = nextAddr + 4 + lineLen + 1

        outBin &= Chr(addrAfter And &HFF)
        outBin &= Chr((addrAfter Shr 8) And &HFF)
        outBin &= Chr(lineNos(i) And &HFF)
        outBin &= Chr((lineNos(i) Shr 8) And &HFF)
        outBin &= lineData
        outBin &= Chr(0)

        nextAddr = addrAfter
    Next i

    outBin &= Chr(0) & Chr(0)
    outBinary = outBin
    Return -1
End Function

Private Function ToDos83(ByRef fileName As String, ByRef outName83 As String, ByRef errMsg As String) As Integer
    Dim src As String = UCase(Trim(fileName))
    If Len(src) = 0 Then
        errMsg = "Nome de arquivo vazio."
        Return 0
    End If

    Dim dotPos As Integer = InStrRev(src, ".")
    Dim baseName As String
    Dim extName As String

    If dotPos > 0 Then
        baseName = Left(src, dotPos - 1)
        extName = Mid(src, dotPos + 1)
    Else
        baseName = src
        extName = ""
    End If

    Dim i As Integer
    Dim cleanBase As String = ""
    For i = 1 To Len(baseName)
        Dim c As Integer = Asc(Mid(baseName, i, 1))
        If (c >= Asc("A") And c <= Asc("Z")) Or (c >= Asc("0") And c <= Asc("9")) Or c = Asc("_") Then
            cleanBase &= Chr(c)
        Else
            cleanBase &= "_"
        End If
    Next i

    Dim cleanExt As String = ""
    For i = 1 To Len(extName)
        Dim c As Integer = Asc(Mid(extName, i, 1))
        If (c >= Asc("A") And c <= Asc("Z")) Or (c >= Asc("0") And c <= Asc("9")) Or c = Asc("_") Then
            cleanExt &= Chr(c)
        Else
            cleanExt &= "_"
        End If
    Next i

    If Len(cleanBase) = 0 Then cleanBase = "NONAME"
    cleanBase = Left(cleanBase, 8)
    cleanExt = Left(cleanExt, 3)

    outName83 = cleanBase & String(8 - Len(cleanBase), " ") & cleanExt & String(3 - Len(cleanExt), " ")
    Return -1
End Function

Private Sub Fat12SetEntry(fat() As UByte, ByVal cluster As Integer, ByVal value As Integer)
    Dim offset As Integer = (cluster * 3) \ 2

    If (cluster And 1) = 0 Then
        fat(offset) = value And &HFF
        fat(offset + 1) = (fat(offset + 1) And &HF0) Or ((value Shr 8) And &H0F)
    Else
        fat(offset) = (fat(offset) And &H0F) Or ((value Shl 4) And &HF0)
        fat(offset + 1) = (value Shr 4) And &HFF
    End If
End Sub

Private Function BuildRunDisk(ByRef srcPath As String, ByRef amxPath As String, ByRef bmxPath As String, ByRef outDiskPath As String, ByRef errMsg As String, ByVal cleanDiskDir As Integer) As Integer
    Const SECTOR_SIZE = 512
    Const TOTAL_SECTORS = 1440
    Const DISK_SIZE = SECTOR_SIZE * TOTAL_SECTORS
    Const SECTORS_PER_CLUSTER = 2
    Const RESERVED_SECTORS = 1
    Const FAT_COUNT = 2
    Const SECTORS_PER_FAT = 3
    Const ROOT_ENTRIES = 112
    Const ROOT_DIR_SECTORS = 7

    Dim disk(0 To DISK_SIZE - 1) As UByte
    Dim fat(0 To (SECTORS_PER_FAT * SECTOR_SIZE) - 1) As UByte

    Dim i As Integer
    For i = 0 To UBound(disk)
        disk(i) = 0
    Next i
    For i = 0 To UBound(fat)
        fat(i) = 0
    Next i

    disk(0) = &HEB
    disk(1) = &HFE
    disk(2) = &H90

    Dim oem As String = "MSXIDE  "
    For i = 1 To Len(oem)
        disk(2 + i) = Asc(Mid(oem, i, 1))
    Next i

    disk(11) = &H00
    disk(12) = &H02
    disk(13) = SECTORS_PER_CLUSTER
    disk(14) = RESERVED_SECTORS
    disk(15) = 0
    disk(16) = FAT_COUNT
    disk(17) = ROOT_ENTRIES And &HFF
    disk(18) = (ROOT_ENTRIES Shr 8) And &HFF
    disk(19) = TOTAL_SECTORS And &HFF
    disk(20) = (TOTAL_SECTORS Shr 8) And &HFF
    disk(21) = &HF9
    disk(22) = SECTORS_PER_FAT
    disk(23) = 0
    disk(24) = 9
    disk(25) = 0
    disk(26) = 2
    disk(27) = 0
    disk(510) = &H55
    disk(511) = &HAA

    fat(0) = &HF9
    fat(1) = &HFF
    fat(2) = &HFF

    Dim dmxPath As String = srcPath

    Dim srcExt As String = GetExtLower(srcPath)
    If srcExt <> ".dmx" And srcExt <> ".bad" Then
        dmxPath = ""
    End If

    Dim workRoot As String = NormalizePathValue(PathDir(srcPath))
    If Len(workRoot) = 0 Then workRoot = NormalizePathValue(CurDir())
    If Right(workRoot, 1) <> "\\" And Right(workRoot, 1) <> "/" Then workRoot &= "\\"

    Dim diskDir As String = NormalizePathValue(workRoot & "disk")
    If Dir(diskDir) = "" Then MkDir diskDir
    If Right(diskDir, 1) <> "\\" And Right(diskDir, 1) <> "/" Then diskDir &= "\\"

    If cleanDiskDir <> 0 Then
        If ClearRunDiskDir(diskDir, errMsg) = 0 Then Return 0
    End If

    Dim baseName As String = UCase(BaseNameNoExt(srcPath))
    If Len(baseName) = 0 Then baseName = "PROGRAM"

    Dim autoexecPath As String = NormalizePathValue(diskDir & "AUTOEXEC.BAS")
    Dim autoexecText As String = "10 RUN " & Chr(34) & Left(baseName, 8) & ".BMX" & Chr(34) & Chr(13) & Chr(10)
    If WriteTextFile(autoexecPath, autoexecText, errMsg) = 0 Then Return 0

    Dim filePath(1 To 4) As String
    Dim fileName(1 To 4) As String
    Dim fileCount As Integer = 0

    If Len(dmxPath) > 0 And Dir(dmxPath) <> "" Then
        fileCount += 1
        filePath(fileCount) = dmxPath
        fileName(fileCount) = Left(baseName, 8) & ".DMX"
    End If

    If Dir(amxPath) = "" Then
        errMsg = "Arquivo AMX nao encontrado: " & amxPath
        Return 0
    End If
    fileCount += 1
    filePath(fileCount) = amxPath
    fileName(fileCount) = Left(baseName, 8) & ".AMX"

    If Dir(bmxPath) = "" Then
        errMsg = "Arquivo BMX nao encontrado: " & bmxPath
        Return 0
    End If
    fileCount += 1
    filePath(fileCount) = bmxPath
    fileName(fileCount) = Left(baseName, 8) & ".BMX"

    fileCount += 1
    filePath(fileCount) = autoexecPath
    fileName(fileCount) = "AUTOEXEC.BAS"

    Dim rootOffset As Integer = (RESERVED_SECTORS + FAT_COUNT * SECTORS_PER_FAT) * SECTOR_SIZE
    Dim dataOffset As Integer = (RESERVED_SECTORS + FAT_COUNT * SECTORS_PER_FAT + ROOT_DIR_SECTORS) * SECTOR_SIZE
    Dim clusterSize As Integer = SECTORS_PER_CLUSTER * SECTOR_SIZE
    Dim maxCluster As Integer = 2 + ((TOTAL_SECTORS - (RESERVED_SECTORS + FAT_COUNT * SECTORS_PER_FAT + ROOT_DIR_SECTORS)) \ SECTORS_PER_CLUSTER) - 1
    Dim nextCluster As Integer = 2

    For i = 1 To fileCount
        If i > ROOT_ENTRIES Then
            errMsg = "Numero de arquivos excede o diretorio raiz FAT12."
            Return 0
        End If

        Dim dataBytes As String
        If ReadBinaryFile(filePath(i), dataBytes, errMsg) = 0 Then Return 0

        Dim sz As Integer = Len(dataBytes)
        Dim startCluster As Integer = 0
        Dim neededClusters As Integer = 0

        If sz > 0 Then
            neededClusters = (sz + clusterSize - 1) \ clusterSize
            startCluster = nextCluster
            If (startCluster + neededClusters - 1) > maxCluster Then
                errMsg = "Espaco insuficiente no disco virtual."
                Return 0
            End If

            Dim c As Integer
            For c = 0 To neededClusters - 1
                Dim curCluster As Integer = startCluster + c
                Dim nxt As Integer = IIf(c = neededClusters - 1, &HFFF, curCluster + 1)
                Fat12SetEntry(fat(), curCluster, nxt)

                Dim srcPos As Integer = c * clusterSize + 1
                Dim chunk As Integer = clusterSize
                If srcPos + chunk - 1 > sz Then chunk = sz - srcPos + 1

                Dim dstPos As Integer = dataOffset + (curCluster - 2) * clusterSize
                Dim j As Integer
                For j = 0 To chunk - 1
                    disk(dstPos + j) = Asc(Mid(dataBytes, srcPos + j, 1))
                Next j
            Next c

            nextCluster = startCluster + neededClusters
        End If

        Dim dosName As String
        If ToDos83(fileName(i), dosName, errMsg) = 0 Then Return 0

        Dim entryOffset As Integer = rootOffset + (i - 1) * 32
        Dim n As Integer
        For n = 1 To 11
            disk(entryOffset + (n - 1)) = Asc(Mid(dosName, n, 1))
        Next n

        disk(entryOffset + 11) = &H20
        disk(entryOffset + 26) = startCluster And &HFF
        disk(entryOffset + 27) = (startCluster Shr 8) And &HFF
        disk(entryOffset + 28) = sz And &HFF
        disk(entryOffset + 29) = (sz Shr 8) And &HFF
        disk(entryOffset + 30) = (sz Shr 16) And &HFF
        disk(entryOffset + 31) = (sz Shr 24) And &HFF
    Next i

    Dim fat1Offset As Integer = RESERVED_SECTORS * SECTOR_SIZE
    Dim fat2Offset As Integer = (RESERVED_SECTORS + SECTORS_PER_FAT) * SECTOR_SIZE
    For i = 0 To UBound(fat)
        disk(fat1Offset + i) = fat(i)
        disk(fat2Offset + i) = fat(i)
    Next i

    outDiskPath = NormalizePathValue(diskDir & Left(baseName, 8) & ".dsk")

    Dim ff As Integer = FreeFile
    If Open(outDiskPath For Binary Access Write As #ff) <> 0 Then
        errMsg = "Falha ao criar disco: " & outDiskPath
        Return 0
    End If

    For i = 0 To UBound(disk)
        Put #ff, , disk(i)
    Next i

    Close #ff
    Return -1
End Function

Function CompilerCompileToAmx(ByRef srcPath As String, ByRef outAmxPath As String, ByRef errMsg As String) As Integer
    CompilerDebugLog("compiler", "CompilerCompileToAmx start src=" & srcPath)
    errMsg = ""
    outAmxPath = ChangeExt(srcPath, ".amx")

    Dim ext As String = GetExtLower(srcPath)
    Dim sourceText As String
    If ReadTextFile(srcPath, sourceText, errMsg) = 0 Then
        CompilerDebugLog("compiler", "CompilerCompileToAmx fail read err=" & errMsg)
        Return 0
    End If

    Dim amxText As String
    If ext = ".amx" Or ext = ".asc" Then
        amxText = sourceText
    Else
        Dim amxOverride As String = ""
        If PreprocessDignified(sourceText, srcPath, amxText, amxOverride, errMsg) = 0 Then
            CompilerDebugLog("compiler", "CompilerCompileToAmx fail preprocess err=" & errMsg)
            Return 0
        End If
        If Len(amxOverride) > 0 Then outAmxPath = amxOverride
    End If

    If WriteTextFile(outAmxPath, amxText, errMsg) = 0 Then
        CompilerDebugLog("compiler", "CompilerCompileToAmx fail write err=" & errMsg)
        Return 0
    End If
    CompilerDebugLog("compiler", "CompilerCompileToAmx ok out=" & outAmxPath & " size=" & Trim(Str(Len(amxText))))
    Return -1
End Function

Function CompilerTokenizeAmx(ByRef amxPath As String, ByRef outBmxPath As String, ByRef errMsg As String) As Integer
    CompilerDebugLog("compiler", "CompilerTokenizeAmx start amx=" & amxPath)
    errMsg = ""
    outBmxPath = ChangeExt(amxPath, ".bmx")

    Dim amxText As String
    If ReadTextFile(amxPath, amxText, errMsg) = 0 Then
        CompilerDebugLog("compiler", "CompilerTokenizeAmx fail read err=" & errMsg)
        Return 0
    End If

    Dim binOut As String
    If BuildBmxFromAmxText(amxText, binOut, errMsg) = 0 Then
        CompilerDebugLog("compiler", "CompilerTokenizeAmx fail tokenize err=" & errMsg)
        Return 0
    End If

    If WriteBinaryFile(outBmxPath, binOut, errMsg) = 0 Then
        CompilerDebugLog("compiler", "CompilerTokenizeAmx fail write err=" & errMsg)
        Return 0
    End If
    CompilerDebugLog("compiler", "CompilerTokenizeAmx ok out=" & outBmxPath & " size=" & Trim(Str(Len(binOut))))
    Return -1
End Function

Function CompilerCompileToBmx(ByRef srcPath As String, ByRef outAmxPath As String, ByRef outBmxPath As String, ByRef errMsg As String) As Integer
    CompilerDebugLog("compiler", "CompilerCompileToBmx start src=" & srcPath)
    errMsg = ""
    outAmxPath = ""
    outBmxPath = ""

    If CompilerCompileToAmx(srcPath, outAmxPath, errMsg) = 0 Then
        CompilerDebugLog("compiler", "CompilerCompileToBmx fail compile-amx err=" & errMsg)
        Return 0
    End If
    If CompilerTokenizeAmx(outAmxPath, outBmxPath, errMsg) = 0 Then
        CompilerDebugLog("compiler", "CompilerCompileToBmx fail tokenize err=" & errMsg)
        Return 0
    End If

    CompilerDebugLog("compiler", "CompilerCompileToBmx ok amx=" & outAmxPath & " bmx=" & outBmxPath)
    Return -1
End Function

Function CompilerBuildRunDisk(ByRef srcPath As String, ByRef amxPath As String, ByRef bmxPath As String, ByRef outDiskPath As String, ByRef errMsg As String, ByVal cleanDiskDir As Integer = 0) As Integer
    outDiskPath = ""
    CompilerDebugLog("compiler", "CompilerBuildRunDisk start src=" & srcPath & " amx=" & amxPath & " bmx=" & bmxPath & " cleanDiskDir=" & Trim(Str(cleanDiskDir)))
    Dim rc As Integer = BuildRunDisk(srcPath, amxPath, bmxPath, outDiskPath, errMsg, cleanDiskDir)
    If rc = 0 Then
        CompilerDebugLog("compiler", "CompilerBuildRunDisk fail err=" & errMsg)
    Else
        CompilerDebugLog("compiler", "CompilerBuildRunDisk ok dsk=" & outDiskPath)
    End If
    Return rc
End Function
