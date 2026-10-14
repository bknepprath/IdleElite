Option Explicit
Dim shell, fs, scriptPath, quote
Set shell = CreateObject("WScript.Shell")
Set fs = CreateObject("Scripting.FileSystemObject")
quote = Chr(34)
scriptPath = fs.BuildPath(fs.GetParentFolderName(WScript.ScriptFullName), "scripts\play-progression-prototype.ps1")
shell.Run "powershell.exe -NoProfile -File " & quote & scriptPath & quote, 0, False
