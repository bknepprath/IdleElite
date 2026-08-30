$ErrorActionPreference = "Stop"

if (-not ("GodotRunner.NativeErrorMode" -as [type])) {
    Add-Type @"
using System.Runtime.InteropServices;

namespace GodotRunner {
    public static class NativeErrorMode {
        [DllImport("kernel32.dll")]
        public static extern uint GetErrorMode();

        [DllImport("kernel32.dll")]
        public static extern uint SetErrorMode(uint mode);
    }
}
"@
}

$maxGodots = 1
$waitSeconds = 300
$pollSeconds = 10

if ($env:GODOT_MAX_PROCESSES) {
    $maxGodots = [int]$env:GODOT_MAX_PROCESSES
    if ($maxGodots -lt 1 -or $maxGodots -gt 4) {
        throw "GODOT_MAX_PROCESSES must be between 1 and 4."
    }
}
if ($env:GODOT_SLOT_WAIT_SECONDS) {
    $waitSeconds = [int]$env:GODOT_SLOT_WAIT_SECONDS
    if ($waitSeconds -lt 0) {
        throw "GODOT_SLOT_WAIT_SECONDS cannot be negative."
    }
}

$headlessCandidatePaths = @()
$visibleCandidatePaths = @()
if ($env:GODOT_BIN) {
    $headlessCandidatePaths += $env:GODOT_BIN
    $visibleCandidatePaths += $env:GODOT_BIN
}
$headlessCandidatePaths += @(
    (Join-Path $env:TEMP "godot471\Godot_v4.7.1-stable_win64_console.exe")
)
$visibleCandidatePaths += @(
    (Join-Path ([Environment]::GetFolderPath("MyDocuments")) "New project 4\.codex-godot-r471\godot.exe")
)

function Get-GodotProcessSnapshot {
    $godotProcesses = @(Get-Process godot* -ErrorAction SilentlyContinue)
    $processDetails = @{}

    if ($godotProcesses.Count -gt 0) {
        $filter = ($godotProcesses.Id | ForEach-Object { "ProcessId=$_" }) -join " OR "
        foreach ($item in @(Get-CimInstance Win32_Process -Filter $filter -ErrorAction SilentlyContinue)) {
            $processDetails[[int]$item.ProcessId] = $item
        }
    }

    return @{
        Processes = $godotProcesses
        Details = $processDetails
    }
}

function Get-ChildProcessIds {
    param([Parameter(Mandatory = $true)][int]$ParentProcessId)

    $children = @(Get-CimInstance Win32_Process -Filter "ParentProcessId=$ParentProcessId" -ErrorAction SilentlyContinue)
    $ids = @()
    foreach ($child in $children) {
        $childId = [int]$child.ProcessId
        $ids += $childId
        $ids += Get-ChildProcessIds -ParentProcessId $childId
    }
    return $ids
}

$godotArgs = @($args)
$visibleGame = $false
if ($godotArgs -contains "--visible-game") {
    $visibleGame = $true
    $godotArgs = @($godotArgs | Where-Object { $_ -ne "--visible-game" })
}
if ($visibleGame -and $godotArgs -contains "--headless") {
    throw "--visible-game cannot be combined with --headless."
}
if ($godotArgs -contains "--editor" -or $godotArgs -contains "-e" -or $godotArgs -contains "--project-manager") {
    throw "Refusing to launch the Godot editor or project manager."
}
if (-not $visibleGame -and $godotArgs -notcontains "--headless") {
    $godotArgs = @("--headless") + $godotArgs
}
$candidatePaths = if ($visibleGame) { $visibleCandidatePaths } else { $headlessCandidatePaths }
$godotPath = $candidatePaths | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
if (-not $godotPath) {
    $launchKind = if ($visibleGame) { "visible-game" } else { "headless console" }
    throw "The Godot $launchKind executable was not found. Set GODOT_BIN to the matching Godot executable path."
}
$previousAppData = $env:APPDATA
$headlessUserDataDir = ""
$removeHeadlessUserData = $false
$isolatedUserDataActive = -not $visibleGame -or [bool]$env:IDLE_ELITE_TEST_USER_DATA_DIR
if ($isolatedUserDataActive) {
    $requestedUserDataDir = if ($env:IDLE_ELITE_TEST_USER_DATA_DIR) {
        $env:IDLE_ELITE_TEST_USER_DATA_DIR
    } else {
        $removeHeadlessUserData = $true
        Join-Path $env:TEMP ("idle-elite-godot-user-{0}" -f ([guid]::NewGuid()))
    }
    $headlessUserDataDir = (New-Item -ItemType Directory -Force -Path $requestedUserDataDir).FullName
    $testUserDataDir = $headlessUserDataDir
    $env:APPDATA = $testUserDataDir
}

function ConvertTo-ProcessArgument {
    param([Parameter(Mandatory = $true)][string]$Argument)

    if ($Argument -notmatch '[\s"]') {
        return $Argument
    }

    $escaped = $Argument -replace '(\\*)"', '$1$1\"'
    $escaped = $escaped -replace '(\\*)$', '$1$1'
    return '"' + $escaped + '"'
}

$stdoutPath = Join-Path $env:TEMP ("godot-safe-{0}.stdout.log" -f ([guid]::NewGuid()))
$stderrPath = Join-Path $env:TEMP ("godot-safe-{0}.stderr.log" -f ([guid]::NewGuid()))
$mutex = New-Object System.Threading.Mutex($false, "Global\IdleEliteGodotLaunchGate")
$deadline = (Get-Date).AddSeconds($waitSeconds)
$process = $null
$mutexHeld = $false
$beforeSnapshot = Get-GodotProcessSnapshot
$exitCode = $null

try {
try {
    while ($true) {
        $mutexHeld = $mutex.WaitOne([TimeSpan]::FromSeconds($pollSeconds))
        if (-not $mutexHeld) {
            if ((Get-Date) -ge $deadline) {
                [Console]::Error.WriteLine("Timed out waiting for the Godot launch gate.")
                exit 75
            }
            continue
        }

        $running = @(Get-Process godot* -ErrorAction SilentlyContinue)
        if ($running.Count -lt $maxGodots) {
            $argumentList = ($godotArgs | ForEach-Object { ConvertTo-ProcessArgument $_ }) -join " "
            $previousErrorMode = [GodotRunner.NativeErrorMode]::GetErrorMode()
            $noCrashDialogMode = $previousErrorMode -bor 0x0001 -bor 0x0002
            [void][GodotRunner.NativeErrorMode]::SetErrorMode($noCrashDialogMode)
            try {
                if ($visibleGame) {
                    $process = Start-Process `
                        -FilePath $godotPath `
                        -ArgumentList $argumentList `
                        -PassThru `
                        -WindowStyle Normal `
                        -RedirectStandardOutput $stdoutPath `
                        -RedirectStandardError $stderrPath
                } else {
                    $process = Start-Process `
                        -FilePath $godotPath `
                        -ArgumentList $argumentList `
                        -PassThru `
                        -WindowStyle Hidden `
                        -RedirectStandardOutput $stdoutPath `
                        -RedirectStandardError $stderrPath
                }
            }
            finally {
                [void][GodotRunner.NativeErrorMode]::SetErrorMode($previousErrorMode)
            }
            break
        }

        $mutex.ReleaseMutex()
        $mutexHeld = $false

        if ((Get-Date) -ge $deadline) {
            [Console]::Error.WriteLine("There are already $($running.Count) Godot processes running. No slot opened within $waitSeconds seconds.")
            exit 75
        }

        Write-Host "There are already $($running.Count) Godot processes running. Waiting..."
        Start-Sleep -Seconds $pollSeconds
    }
}
finally {
    if ($mutexHeld) {
        $mutex.ReleaseMutex()
    }
    $mutex.Dispose()
}

$runTimeoutSeconds = 0
if ($env:GODOT_RUN_TIMEOUT_SECONDS) {
    $runTimeoutSeconds = [int]$env:GODOT_RUN_TIMEOUT_SECONDS
}

$launchedProcessIds = @($process.Id)
Start-Sleep -Milliseconds 100
$launchedProcessIds += @(Get-ChildProcessIds -ParentProcessId $process.Id)
$launchedProcessIds = @($launchedProcessIds | Sort-Object -Unique)

if ($runTimeoutSeconds -gt 0) {
    $finished = $process.WaitForExit($runTimeoutSeconds * 1000)
    if (-not $finished) {
        $launchedProcessIds += @(Get-ChildProcessIds -ParentProcessId $process.Id)
        $launchedProcessIds = @($launchedProcessIds | Sort-Object -Unique)
        foreach ($knownProcessId in @($launchedProcessIds | Sort-Object -Descending)) {
            Stop-Process -Id $knownProcessId -Force -ErrorAction SilentlyContinue
        }
        [Console]::Error.WriteLine("Godot did not finish within $runTimeoutSeconds seconds and was stopped.")
        exit 124
    }
} else {
    $process.WaitForExit()
}

if (Test-Path -LiteralPath $stdoutPath) {
    Get-Content -LiteralPath $stdoutPath
}
$stderrLines = @()
if (Test-Path -LiteralPath $stderrPath) {
    $stderrLines = @(Get-Content -LiteralPath $stderrPath)
    $stderrLines | ForEach-Object { [Console]::Error.WriteLine($_) }
}

$process.Refresh()
$exitCode = if ($null -eq $process.ExitCode) { 0 } else { $process.ExitCode }
if ($exitCode -eq 0 -and ($stderrLines -match "Main executable .* not found")) {
    $exitCode = 1
}
if ($exitCode -eq 0 -and ($stderrLines -match "CrashHandlerException: Program crashed|Program crashed with signal")) {
    $exitCode = 139
}

$launchedProcessIds += @(Get-ChildProcessIds -ParentProcessId $process.Id)
$launchedProcessIds = @($launchedProcessIds | Sort-Object -Unique)
$afterSnapshot = Get-GodotProcessSnapshot
$remainingLaunchedIds = @(
    $launchedProcessIds |
        Where-Object { $afterSnapshot.Details.ContainsKey([int]$_) } |
        Sort-Object -Unique
)

foreach ($processId in $remainingLaunchedIds) {
    $remainingProcess = Get-Process -Id $processId -ErrorAction SilentlyContinue
    if (-not $remainingProcess) {
        continue
    }
    if ($visibleGame) {
        [Console]::Error.WriteLine("Godot process from this visible command is still active and was not terminated: PID $processId")
        if ($exitCode -eq 0) {
            $exitCode = 125
        }
        continue
    }

    $cpuBefore = $remainingProcess.CPU
    Start-Sleep -Milliseconds 500
    $remainingProcess.Refresh()
    $cpuAfter = $remainingProcess.CPU
    $cpuDelta = if ($null -ne $cpuBefore -and $null -ne $cpuAfter) { $cpuAfter - $cpuBefore } else { 0 }

    if ($cpuDelta -lt 0.05) {
        Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
        [Console]::Error.WriteLine("Terminated idle Godot process left behind by this command: PID $processId")
    } else {
        [Console]::Error.WriteLine("Godot process from this command is still active and was not terminated: PID $processId")
        if ($exitCode -eq 0) {
            $exitCode = 125
        }
    }
}

$newUnattributedIds = @(
    $afterSnapshot.Processes |
        Where-Object { -not $beforeSnapshot.Details.ContainsKey([int]$_.Id) -and ($remainingLaunchedIds -notcontains [int]$_.Id) } |
        ForEach-Object { [int]$_.Id } |
        Sort-Object -Unique
)
if ($newUnattributedIds.Count -gt 0) {
    # Godot can briefly hand off to a second process after the original launcher
    # exits. Wait for that process to close before another validation reuses the
    # same user-data/log directory. Never terminate an unattributed process.
    $unattributedStillRunning = @($newUnattributedIds)
    for ($attempt = 1; $attempt -le 50 -and $unattributedStillRunning.Count -gt 0; $attempt++) {
        Start-Sleep -Milliseconds 100
        $unattributedStillRunning = @(
            $unattributedStillRunning |
                Where-Object { $null -ne (Get-Process -Id $_ -ErrorAction SilentlyContinue) }
        )
    }
    if ($unattributedStillRunning.Count -gt 0) {
        [Console]::Error.WriteLine("New Godot process(es) appeared during this command but were not confirmed as children of this run: $($unattributedStillRunning -join ', '). They were not terminated.")
        if ($exitCode -eq 0) {
            $exitCode = 125
        }
    }
}

}
finally {
    if ($isolatedUserDataActive) {
        if ($null -eq $previousAppData) {
            Remove-Item Env:\APPDATA -ErrorAction SilentlyContinue
        } else {
            $env:APPDATA = $previousAppData
        }
    }
    Remove-Item -LiteralPath $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
    if ($removeHeadlessUserData -and $exitCode -eq 0) {
        $tempRoot = [IO.Path]::GetFullPath($env:TEMP).TrimEnd('\') + '\'
        if ($headlessUserDataDir.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) {
            Remove-Item -LiteralPath $headlessUserDataDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

exit $exitCode
