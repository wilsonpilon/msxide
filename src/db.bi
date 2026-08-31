#ifndef __DB_BI__
#define __DB_BI__

Declare Sub DbInit(ByRef dbPath As String)
Declare Sub DbShutdown()
Declare Sub DbSetSetting(ByRef keyName As String, ByRef keyValue As String)
Declare Function DbGetSetting(ByRef keyName As String, ByRef fallback As String = "") As String
Declare Function DbGetHelpDoc(ByRef docName As String, ByRef fallbackPath As String = "") As String
Declare Function DbGetConfigDocument(ByRef configGroup As String) As String
Declare Sub DbSaveConfigDocument(ByRef configGroup As String, ByRef content As String)
Declare Sub DbSaveDocumentState(ByRef title As String, ByRef filePath As String, ByVal cursorX As Integer, ByVal cursorY As Integer)
Declare Sub DbSavePerfSecond(ByRef backendVersion As String, ByRef bucketTime As String, ByVal frameCount As Integer, ByVal avgChar As Double, ByVal avgAttr As Double, ByVal avgFill As Double, ByVal p95Char As Double, ByVal p95Attr As Double, ByVal p95Fill As Double)

#endif
