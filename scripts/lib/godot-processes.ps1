$ErrorActionPreference = "Stop"

function Get-HeadlessGodotProcesses {
    $processes = @(Get-CimInstance Win32_Process -Filter "name like 'Godot%'" -ErrorAction SilentlyContinue)
    @($processes | Where-Object { $_.CommandLine -match '--headless' })
}

function Assert-NoHeadlessGodotProcesses {
    param([Parameter(Mandatory = $true)][string]$Context)

    $headless = @()
    for ($attempt = 1; $attempt -le 30; $attempt++) {
        $headless = @(Get-HeadlessGodotProcesses)
        if ($headless.Count -eq 0) {
            return
        }
        Start-Sleep -Milliseconds 500
    }

    if ($headless.Count -gt 0) {
        $headless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "A headless Godot process is still running after $Context."
    }
}
