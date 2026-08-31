#Include Once "editor.bi"
#Include Once "db.bi"
#Include Once "console.bi"

Dim running As Integer = 1
Dim menuOpen As Integer = 0
Dim keyText As String
Dim startupName As String = "msx00.dmx"
Dim argText As String
Dim argIndex As Integer
Dim hasArgs As Integer = 0
Dim runHelpSmoke As Integer = 0
Dim needsRedraw As Integer = 1
Dim inputType As Integer
Dim mouseX As Integer
Dim mouseY As Integer
Dim mouseAction As Integer

DbInit("msxide.db")
startupName = DbGetSetting("startup_document", "msx00.dmx")

argIndex = 1
argText = Command(argIndex)
If Len(argText) > 0 Then
    hasArgs = 1
    If LCase(argText) = "--smoke-help" Then
        runHelpSmoke = -1
    End If
End If

If hasArgs = 0 Then
    EditorInit(startupName)
Else
    EditorInit("msx00.dmx")
End If

If hasArgs <> 0 Then
    If runHelpSmoke = 0 Then
        EditorOpenFromPath(argText)
        argIndex += 1
        While Len(Command(argIndex)) > 0
            EditorOpenFromPath(Command(argIndex))
            argIndex += 1
        Wend
    End If
End If

If runHelpSmoke <> 0 Then
    Dim smokeReport As String
    Dim smokeOk As Integer = EditorRunHelpSmokeTest(smokeReport)
    Print smokeReport
    EditorSaveAllToDb()
    DbShutdown()
    EditorShutdown()
    If smokeOk <> 0 Then
        End 0
    Else
        End 1
    End If
End If

Do While running <> 0
    If needsRedraw <> 0 Then
        EditorDraw(menuOpen)
        needsRedraw = 0
    End If

    If ConsolePollInput(inputType, keyText, mouseX, mouseY, mouseAction) <> 0 Then
        If inputType = MSX_INPUT_KEY Then
            EditorHandleKey(keyText, running, menuOpen)
        ElseIf inputType = MSX_INPUT_MOUSE Then
            EditorHandleMouse(mouseX, mouseY, mouseAction, running, menuOpen)
        End If
        needsRedraw = 1
    Else
        Sleep 5, 1
    End If
Loop

EditorSaveAllToDb()
DbShutdown()
EditorShutdown()
