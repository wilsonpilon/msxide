#ifndef __COMPILER_BI__
#define __COMPILER_BI__

Declare Function CompilerCompileToAmx(ByRef srcPath As String, ByRef outAmxPath As String, ByRef errMsg As String) As Integer
Declare Function CompilerTokenizeAmx(ByRef amxPath As String, ByRef outBmxPath As String, ByRef errMsg As String) As Integer
Declare Function CompilerCompileToBmx(ByRef srcPath As String, ByRef outAmxPath As String, ByRef outBmxPath As String, ByRef errMsg As String) As Integer
Declare Function CompilerBuildRunDisk(ByRef srcPath As String, ByRef amxPath As String, ByRef bmxPath As String, ByRef outDiskPath As String, ByRef errMsg As String, ByVal cleanDiskDir As Integer = 0) As Integer

#endif
