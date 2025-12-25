Set WshShell = CreateObject("WScript.Shell")
Set FSO = CreateObject("Scripting.FileSystemObject")

' 获取脚本所在目录
scriptDir = FSO.GetParentFolderName(WScript.ScriptFullName)
mainPyPath = FSO.BuildPath(scriptDir, "main.py")

' 使用 pythonw.exe 启动，如果不存在则使用 python.exe，完全隐藏窗口
pythonCmd = "pythonw"
If Not CheckPythonw() Then
    pythonCmd = "python"
End If

' 以隐藏窗口方式运行
WshShell.Run pythonCmd & " """ & mainPyPath & """", 0, False

Function CheckPythonw()
    On Error Resume Next
    WshShell.Run "pythonw --version", 0, True
    CheckPythonw = (Err.Number = 0)
    On Error GoTo 0
End Function
