#Include Once "windows.bi"
#Include Once "console_win.bi"

Const MAX_CONSOLE_W = 180
Const MAX_CONSOLE_H = 80
Const INPUT_KEY_EVENT = &h0001
Const INPUT_MOUSE_EVENT = &h0002

Dim Shared gW As Integer
Dim Shared gH As Integer
Dim Shared gOut As HANDLE
Dim Shared gIn As HANDLE
Dim Shared gOriginalInMode As DWORD
Dim Shared gHasOriginalInMode As Integer
Dim Shared gMouseLeftDown As Integer
Dim Shared gCursorVisible As Integer
Dim Shared gRowText(1 To MAX_CONSOLE_H) As String
Dim Shared gRowAttr(1 To MAX_CONSOLE_H, 1 To MAX_CONSOLE_W) As UShort
Dim Shared gDirtyRowAny(1 To MAX_CONSOLE_H) As UByte
Dim Shared gDirtyCell(1 To MAX_CONSOLE_H, 1 To MAX_CONSOLE_W) As UByte

Dim Shared gFrameCharCalls As UInteger
Dim Shared gFrameAttrCalls As UInteger
Dim Shared gFrameFillCalls As UInteger

Dim Shared gLastCharCalls As UInteger
Dim Shared gLastAttrCalls As UInteger
Dim Shared gLastFillCalls As UInteger

Dim Shared gTotalCharCalls As UInteger
Dim Shared gTotalAttrCalls As UInteger
Dim Shared gTotalFillCalls As UInteger

Private Function Clamp(ByVal v As Integer, ByVal mn As Integer, ByVal mx As Integer) As Integer
    If v < mn Then Return mn
    If v > mx Then Return mx
    Return v
End Function

Private Function MakeAttr(ByVal fg As UByte, ByVal bg As UByte) As UShort
    Return Cast(UShort, (bg And 15) Shl 4 Or (fg And 15))
End Function

Private Function IsUniformAttr(ByVal y As Integer, ByVal x1 As Integer, ByVal x2 As Integer, ByRef outAttr As UShort) As Integer
    If x1 > x2 Then Return 0

    Dim a As UShort = gRowAttr(y, x1)
    Dim x As Integer
    For x = x1 + 1 To x2
        If gRowAttr(y, x) <> a Then Return 0
    Next x

    outAttr = a
    Return -1
End Function

Private Function IsRangeAttr(ByVal y As Integer, ByVal x1 As Integer, ByVal x2 As Integer, ByVal attrValue As UShort) As Integer
    If x1 > x2 Then Return -1

    Dim x As Integer
    For x = x1 To x2
        If gRowAttr(y, x) <> attrValue Then Return 0
    Next x

    Return -1
End Function

Private Sub MarkAllDirty()
    Dim y As Integer
    Dim x As Integer
    For y = 1 To gH
        gDirtyRowAny(y) = 1
        For x = 1 To gW
            gDirtyCell(y, x) = 1
        Next x
    Next y
End Sub

Private Sub MarkDirtyRange(ByVal y As Integer, ByVal x1 As Integer, ByVal x2 As Integer)
    If y < 1 Or y > gH Then Exit Sub
    If x1 > x2 Then Exit Sub

    x1 = Clamp(x1, 1, gW)
    x2 = Clamp(x2, 1, gW)
    If x1 > x2 Then Exit Sub

    Dim x As Integer
    gDirtyRowAny(y) = 1
    For x = x1 To x2
        gDirtyCell(y, x) = 1
    Next x
End Sub

Private Sub RestoreInputMode()
    If gIn = 0 Then Exit Sub

    Dim inputMode As DWORD
    If gHasOriginalInMode <> 0 Then
        inputMode = gOriginalInMode
    ElseIf GetConsoleMode(gIn, @inputMode) = 0 Then
        Exit Sub
    End If

    inputMode = inputMode Or ENABLE_EXTENDED_FLAGS
    inputMode = inputMode Or ENABLE_MOUSE_INPUT
    inputMode = inputMode Or ENABLE_WINDOW_INPUT
    inputMode = inputMode And Not ENABLE_QUICK_EDIT_MODE
    SetConsoleMode(gIn, inputMode)
End Sub

Sub ConsoleInit(ByVal w As Integer, ByVal h As Integer)
    Dim y As Integer
    Dim x As Integer

    gW = Clamp(w, 1, MAX_CONSOLE_W)
    gH = Clamp(h, 1, MAX_CONSOLE_H)
    gOut = GetStdHandle(STD_OUTPUT_HANDLE)
    gIn = GetStdHandle(STD_INPUT_HANDLE)

    ' Codepage OEM 860 (Portugues) em vez do padrao 437 (EUA) de um Windows
    ' em ingles: mantem os mesmos caracteres de linha/caixa (176-223, iguais
    ' em qualquer codepage OEM) mas cobre corretamente as letras acentuadas
    ' do portugues que faltam na 437 (ã, õ, Á, Í, Ó, Ú). Se falhar (SO nao
    ' suporta essa codepage por algum motivo), segue com o que ja estava
    ' ativo - ConsoleUtf8ToActiveCp le a codepage realmente ativa depois.
    SetConsoleOutputCP(860)
    SetConsoleCP(860)

    gHasOriginalInMode = 0
    If GetConsoleMode(gIn, @gOriginalInMode) <> 0 Then
        gHasOriginalInMode = -1
    End If
    RestoreInputMode()

    Dim sb As COORD
    sb.X = gW
    sb.Y = gH
    SetConsoleScreenBufferSize(gOut, sb)

    Dim rect As SMALL_RECT
    rect.Left = 0
    rect.Top = 0
    rect.Right = gW - 1
    rect.Bottom = gH - 1
    SetConsoleWindowInfo(gOut, TRUE, @rect)

    For y = 1 To gH
        gRowText(y) = String(gW, " ")
        For x = 1 To gW
            gRowAttr(y, x) = MakeAttr(7, 0)
            gDirtyCell(y, x) = 0
        Next x
        gDirtyRowAny(y) = 0
    Next y

    gCursorVisible = 1
    gFrameCharCalls = 0
    gFrameAttrCalls = 0
    gFrameFillCalls = 0
    gLastCharCalls = 0
    gLastAttrCalls = 0
    gLastFillCalls = 0
    gTotalCharCalls = 0
    gTotalAttrCalls = 0
    gTotalFillCalls = 0
    gMouseLeftDown = 0
    MarkAllDirty()
End Sub

Sub ConsoleGetCurrentSize(ByRef w As Integer, ByRef h As Integer)
    Dim outH As HANDLE = GetStdHandle(STD_OUTPUT_HANDLE)
    Dim info As CONSOLE_SCREEN_BUFFER_INFO

    If GetConsoleScreenBufferInfo(outH, @info) = 0 Then
        w = 100
        h = 35
        Exit Sub
    End If

    w = (info.srWindow.Right - info.srWindow.Left) + 1
    h = (info.srWindow.Bottom - info.srWindow.Top) + 1

    If w < 40 Then w = 40
    If h < 15 Then h = 15
    If w > MAX_CONSOLE_W Then w = MAX_CONSOLE_W
    If h > MAX_CONSOLE_H Then h = MAX_CONSOLE_H
End Sub

Sub ConsoleShutdown()
    If gHasOriginalInMode <> 0 Then
        SetConsoleMode(gIn, gOriginalInMode)
    End If

    Dim ci As CONSOLE_CURSOR_INFO
    ci.dwSize = 20
    ci.bVisible = TRUE
    SetConsoleCursorInfo(gOut, @ci)
End Sub

Private Function TranslateKeyEvent(ByRef rec As KEY_EVENT_RECORD, ByRef keyText As String) As Integer
    If rec.bKeyDown = 0 Then Return 0

    Select Case rec.wVirtualKeyCode
        Case VK_LEFT
            keyText = Chr(0) & Chr(75): Return -1
        Case VK_RIGHT
            keyText = Chr(0) & Chr(77): Return -1
        Case VK_UP
            keyText = Chr(0) & Chr(72): Return -1
        Case VK_DOWN
            keyText = Chr(0) & Chr(80): Return -1
        Case VK_HOME
            keyText = Chr(0) & Chr(71): Return -1
        Case VK_END
            keyText = Chr(0) & Chr(79): Return -1
        Case VK_PRIOR
            keyText = Chr(0) & Chr(73): Return -1
        Case VK_NEXT
            keyText = Chr(0) & Chr(81): Return -1
        Case VK_DELETE
            keyText = Chr(0) & Chr(83): Return -1
        Case VK_F1
            If (rec.dwControlKeyState And SHIFT_PRESSED) <> 0 Then
                keyText = Chr(0) & Chr(84)
            Else
                keyText = Chr(0) & Chr(59)
            End If
            Return -1
        Case VK_F2
            keyText = Chr(0) & Chr(60): Return -1
        Case VK_F3
            keyText = Chr(0) & Chr(61): Return -1
        Case VK_F4
            keyText = Chr(0) & Chr(62): Return -1
        Case VK_F5
            keyText = Chr(0) & Chr(63): Return -1
        Case VK_F6
            keyText = Chr(0) & Chr(64): Return -1
        Case VK_F10
            keyText = Chr(0) & Chr(68): Return -1
        Case VK_RETURN
            keyText = Chr(13): Return -1
        Case VK_BACK
            keyText = Chr(8): Return -1
        Case VK_ESCAPE
            keyText = Chr(27): Return -1
    End Select

    Dim c As Integer = rec.uChar.UnicodeChar
    If c >= 32 And c <= 126 Then
        keyText = Chr(c)
        Return -1
    End If

    Return 0
End Function

Private Function TranslateMouseEvent(ByRef rec As MOUSE_EVENT_RECORD, ByRef mouseX As Integer, ByRef mouseY As Integer, ByRef mouseAction As Integer) As Integer
    mouseX = rec.dwMousePosition.X + 1
    mouseY = rec.dwMousePosition.Y + 1
    mouseAction = 0

    Dim leftNow As Integer = IIf((rec.dwButtonState And FROM_LEFT_1ST_BUTTON_PRESSED) <> 0, 1, 0)

    If rec.dwEventFlags = MOUSE_MOVED Then
        If leftNow <> 0 Then
            mouseAction = MSX_MOUSE_MOVE
        End If
    ElseIf rec.dwEventFlags = DOUBLE_CLICK Then
        mouseAction = MSX_MOUSE_DOWN
    ElseIf rec.dwEventFlags = MOUSE_WHEELED Then
        ' Delta do wheel fica na word alta de dwButtonState (com sinal).
        Dim wheelDelta As Short = Cast(Short, (rec.dwButtonState Shr 16) And &hFFFF)
        If wheelDelta > 0 Then
            mouseAction = MSX_MOUSE_WHEEL_UP
        ElseIf wheelDelta < 0 Then
            mouseAction = MSX_MOUSE_WHEEL_DOWN
        End If
    ElseIf rec.dwEventFlags = 0 Then
        If leftNow <> 0 And gMouseLeftDown = 0 Then
            mouseAction = MSX_MOUSE_DOWN
        ElseIf leftNow = 0 And gMouseLeftDown <> 0 Then
            mouseAction = MSX_MOUSE_UP
        End If
    End If

    gMouseLeftDown = leftNow
    Return IIf(mouseAction <> 0, -1, 0)
End Function

Function ConsolePollInput(ByRef eventType As Integer, ByRef keyText As String, ByRef mouseX As Integer, ByRef mouseY As Integer, ByRef mouseAction As Integer) As Integer
    eventType = MSX_INPUT_NONE
    keyText = ""
    mouseAction = 0

    Dim available As DWORD
    Dim tries As Integer

    For tries = 1 To 16
        If GetNumberOfConsoleInputEvents(gIn, @available) = 0 Then Return 0
        If available = 0 Then Return 0

        Dim ir As INPUT_RECORD
        Dim readCount As DWORD
        If ReadConsoleInput(gIn, @ir, 1, @readCount) = 0 Then Return 0
        If readCount = 0 Then Return 0

        Select Case ir.EventType
            Case INPUT_KEY_EVENT
                If TranslateKeyEvent(ir.Event.KeyEvent, keyText) <> 0 Then
                    eventType = MSX_INPUT_KEY
                    Return -1
                End If
            Case INPUT_MOUSE_EVENT
                If TranslateMouseEvent(ir.Event.MouseEvent, mouseX, mouseY, mouseAction) <> 0 Then
                    eventType = MSX_INPUT_MOUSE
                    Return -1
                End If
        End Select
    Next tries

    Return 0
End Function

Sub ConsoleResetInputState()
    gMouseLeftDown = 0
    If gIn <> 0 Then FlushConsoleInputBuffer(gIn)
    RestoreInputMode()
End Sub

Sub ConsoleClear(ByVal fg As UByte = 7, ByVal bg As UByte = 0)
    Dim y As Integer
    Dim x As Integer
    Dim attr As UShort = MakeAttr(fg, bg)

    For y = 1 To gH
        gRowText(y) = String(gW, " ")
        For x = 1 To gW
            gRowAttr(y, x) = attr
            gDirtyCell(y, x) = 1
        Next x
        gDirtyRowAny(y) = 1
    Next y
End Sub

Sub ConsoleSetCell(ByVal x As Integer, ByVal y As Integer, ByVal ch As UByte, ByVal fg As UByte = 7, ByVal bg As UByte = 0)
    If x < 1 Or x > gW Or y < 1 Or y > gH Then Exit Sub

    Mid(gRowText(y), x, 1) = Chr(ch)
    gRowAttr(y, x) = MakeAttr(fg, bg)
    MarkDirtyRange(y, x, x)
End Sub

' Converte texto UTF-8 (a codificacao em que os arquivos .md de ajuda e o
' banco de dados guardam o texto) para a codepage de saida realmente ativa
' no console (normalmente 860, definida em ConsoleInit; le a ativa de novo
' aqui em vez de assumir, caso o SO tenha recusado o SetConsoleOutputCP).
' Sem isso, cada acento vira 2-3 bytes UTF-8 exibidos como glifos errados.
Function ConsoleUtf8ToActiveCp(ByRef txt As String) As String
    Dim srcLen As Long = Len(txt)
    If srcLen <= 0 Then Return txt

    Dim targetCp As UInteger = GetConsoleOutputCP()
    If targetCp = 0 Then Return txt

    Dim wLen As Long = MultiByteToWideChar(CP_UTF8, 0, StrPtr(txt), srcLen, 0, 0)
    If wLen <= 0 Then Return txt

    Dim wBuf As Any Ptr = CAllocate((wLen + 1) * 2)
    If wBuf = 0 Then Return txt
    MultiByteToWideChar(CP_UTF8, 0, StrPtr(txt), srcLen, Cast(LPWSTR, wBuf), wLen)

    Dim outLen As Long = WideCharToMultiByte(targetCp, 0, Cast(LPCWCH, wBuf), wLen, 0, 0, 0, 0)
    If outLen <= 0 Then
        DeAllocate(wBuf)
        Return txt
    End If

    Dim outBuf As Any Ptr = CAllocate(outLen + 1)
    If outBuf = 0 Then
        DeAllocate(wBuf)
        Return txt
    End If
    WideCharToMultiByte(targetCp, 0, Cast(LPCWCH, wBuf), wLen, Cast(LPSTR, outBuf), outLen, 0, 0)

    Dim result As String = Space(outLen)
    CopyMemory(StrPtr(result), outBuf, outLen)

    DeAllocate(wBuf)
    DeAllocate(outBuf)

    Return result
End Function

Sub ConsoleWriteText(ByVal x As Integer, ByVal y As Integer, ByRef txt As String, ByVal fg As UByte = 7, ByVal bg As UByte = 0, ByVal maxLen As Integer = -1)
    If y < 1 Or y > gH Then Exit Sub
    If x > gW Then Exit Sub

    Dim drawLen As Integer
    If maxLen < 0 Then
        drawLen = Len(txt)
    Else
        drawLen = maxLen
    End If

    If drawLen <= 0 Then Exit Sub
    If x < 1 Then
        drawLen += x - 1
        x = 1
    End If
    If drawLen <= 0 Then Exit Sub

    If x + drawLen - 1 > gW Then drawLen = gW - x + 1
    If drawLen <= 0 Then Exit Sub

    Dim outTxt As String = Left(txt & String(drawLen, " "), drawLen)
    Mid(gRowText(y), x, drawLen) = outTxt

    Dim i As Integer
    Dim attr As UShort = MakeAttr(fg, bg)
    For i = 0 To drawLen - 1
        gRowAttr(y, x + i) = attr
    Next i

    MarkDirtyRange(y, x, x + drawLen - 1)
End Sub

Sub ConsoleSetCursor(ByVal x As Integer, ByVal y As Integer, ByVal visible As Integer)
    x = Clamp(x, 1, gW)
    y = Clamp(y, 1, gH)

    Dim ci As CONSOLE_CURSOR_INFO
    ci.dwSize = 20
    ci.bVisible = IIf(visible <> 0, TRUE, FALSE)
    SetConsoleCursorInfo(gOut, @ci)
    gCursorVisible = visible

    Dim c As COORD
    c.X = x - 1
    c.Y = y - 1
    SetConsoleCursorPosition(gOut, c)
End Sub

Sub ConsoleBeginFrame()
    gFrameCharCalls = 0
    gFrameAttrCalls = 0
    gFrameFillCalls = 0
End Sub

Sub ConsoleFlush()
    Dim y As Integer
    For y = 1 To gH
        If gDirtyRowAny(y) <> 0 Then
            Dim x As Integer = 1

            Dim hasPendingAttrBatch As Integer = 0
            Dim pendingAttr As UShort = 0
            Dim pendingStart As Integer = 0
            Dim pendingEnd As Integer = 0

            Dim written As DWORD
            Do While x <= gW
                While x <= gW And gDirtyCell(y, x) = 0
                    x += 1
                Wend
                If x > gW Then Exit Do

                Dim x1 As Integer = x
                While x <= gW And gDirtyCell(y, x) <> 0
                    x += 1
                Wend
                Dim x2 As Integer = x - 1
                Dim runLen As Integer = x2 - x1 + 1

                Dim c As COORD
                c.X = x1 - 1
                c.Y = y - 1

                Dim textPtr As ZString Ptr = Cast(ZString Ptr, Cast(UByte Ptr, StrPtr(gRowText(y))) + (x1 - 1))

                Dim i As Integer
                For i = x1 To x2
                    gDirtyCell(y, i) = 0
                Next i

                WriteConsoleOutputCharacter(gOut, textPtr, runLen, c, @written)
                gFrameCharCalls += 1
                gTotalCharCalls += 1

                Dim runAttr As UShort
                Dim runIsUniform As Integer = IsUniformAttr(y, x1, x2, runAttr)

                If runIsUniform <> 0 Then
                    If hasPendingAttrBatch = 0 Then
                        hasPendingAttrBatch = 1
                        pendingAttr = runAttr
                        pendingStart = x1
                        pendingEnd = x2
                    Else
                        Dim canMerge As Integer = 0
                        If runAttr = pendingAttr Then
                            If x1 = pendingEnd + 1 Then
                                canMerge = -1
                            ElseIf x1 > pendingEnd + 1 Then
                                ' Permite mesclar atravessando gaps se o gap tambem usa o mesmo atributo.
                                If IsRangeAttr(y, pendingEnd + 1, x1 - 1, pendingAttr) <> 0 Then
                                    canMerge = -1
                                End If
                            End If
                        End If

                        If canMerge <> 0 Then
                            pendingEnd = x2
                        Else
                            Dim cAttr As COORD
                            cAttr.X = pendingStart - 1
                            cAttr.Y = y - 1
                            FillConsoleOutputAttribute(gOut, pendingAttr, pendingEnd - pendingStart + 1, cAttr, @written)
                            gFrameFillCalls += 1
                            gTotalFillCalls += 1

                            pendingAttr = runAttr
                            pendingStart = x1
                            pendingEnd = x2
                        End If
                    End If
                Else
                    If hasPendingAttrBatch <> 0 Then
                        Dim cAttr As COORD
                        cAttr.X = pendingStart - 1
                        cAttr.Y = y - 1
                        FillConsoleOutputAttribute(gOut, pendingAttr, pendingEnd - pendingStart + 1, cAttr, @written)
                        gFrameFillCalls += 1
                        gTotalFillCalls += 1
                        hasPendingAttrBatch = 0
                    End If

                    Dim attrPtr As UShort Ptr = @gRowAttr(y, x1)
                    WriteConsoleOutputAttribute(gOut, attrPtr, runLen, c, @written)
                    gFrameAttrCalls += 1
                    gTotalAttrCalls += 1
                End If
            Loop

            If hasPendingAttrBatch <> 0 Then
                Dim cAttr As COORD
                cAttr.X = pendingStart - 1
                cAttr.Y = y - 1
                FillConsoleOutputAttribute(gOut, pendingAttr, pendingEnd - pendingStart + 1, cAttr, @written)
                gFrameFillCalls += 1
                gTotalFillCalls += 1
            End If

            gDirtyRowAny(y) = 0
        End If
    Next y
End Sub

Sub ConsoleEndFrame()
    gLastCharCalls = gFrameCharCalls
    gLastAttrCalls = gFrameAttrCalls
    gLastFillCalls = gFrameFillCalls
End Sub

Sub ConsoleGetLastFrameStats(ByRef charCalls As UInteger, ByRef attrCalls As UInteger, ByRef fillCalls As UInteger)
    charCalls = gLastCharCalls
    attrCalls = gLastAttrCalls
    fillCalls = gLastFillCalls
End Sub

Sub ConsoleGetTotalStats(ByRef charCalls As UInteger, ByRef attrCalls As UInteger, ByRef fillCalls As UInteger)
    charCalls = gTotalCharCalls
    attrCalls = gTotalAttrCalls
    fillCalls = gTotalFillCalls
End Sub

Sub ConsoleGetMouseHud(ByRef available As Integer, ByRef enabled As Integer, ByRef x As Integer, ByRef y As Integer)
    available = 0
    enabled = 0
    x = 0
    y = 0
End Sub
