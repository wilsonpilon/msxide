#ifndef __EDITOR_BI__
#define __EDITOR_BI__

Const MAX_DOCS = 8
Const MAX_LINES = 2000
Const SCREEN_W = 100
Const SCREEN_H = 35

Type Document
    title As String
    filePath As String
    isHelp As Integer
    helpTitle As String
    helpWrapWidth As Integer
    lineCount As Integer
    lines(1 To MAX_LINES) As String
    cursorX As Integer
    cursorY As Integer
    scrollX As Integer
    scrollY As Integer
    winX As Integer
    winY As Integer
    winW As Integer
    winH As Integer
    isMaximized As Integer
    normalX As Integer
    normalY As Integer
    normalW As Integer
    normalH As Integer
End Type

Declare Sub EditorInit(ByRef startupName As String)
Declare Sub EditorOpenFromPath(ByRef path As String)
Declare Sub EditorCreateUntitled()
Declare Sub EditorDraw(ByVal menuOpen As Integer)
Declare Sub EditorHandleKey(ByRef keyText As String, ByRef running As Integer, ByRef menuOpen As Integer)
Declare Sub EditorHandleMouse(ByVal mouseX As Integer, ByVal mouseY As Integer, ByVal mouseAction As Integer, ByRef running As Integer, ByRef menuOpen As Integer)
Declare Sub EditorSaveAllToDb()
Declare Sub EditorShutdown()
Declare Function EditorRunHelpSmokeTest(ByRef report As String) As Integer

#endif
