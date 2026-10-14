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

$maxGodots = 4
$waitSeconds = 300
$pollSeconds = 10

if ($env:GODOT_MAX_PROCESSES) {
    $maxGodots = [int]$env:GODOT_MAX_PROCESSES
}
if ($maxGodots -lt 1 -or $maxGodots -gt 4) {
    throw "GODOT_MAX_PROCESSES must be between 1 and 4."
}
if ($env:GODOT_SLOT_WAIT_SECONDS) {
    $waitSeconds = [int]$env:GODOT_SLOT_WAIT_SECONDS
}

$candidatePaths = @(
    $env:GODOT_BIN,
    "C:\Users\bknep\Documents\New project 4\.codex-godot-r471\godot.exe"
)
$godotPath = $candidatePaths | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Leaf) } | Select-Object -First 1
if (-not $godotPath) {
    throw "Godot was not found. Set GODOT_BIN to the Godot executable path."
}

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

    # No Godot can be left behind when the process inventory is empty. Avoid
    # requiring WMI/CIM permissions just to prove this common successful case.
    if (@(Get-Process godot* -ErrorAction SilentlyContinue).Count -eq 0) {
        return @()
    }
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
$allow4kReferenceCapture = $false
if ($godotArgs -contains "--allow-4k-reference-capture") {
    $allow4kReferenceCapture = $true
    $godotArgs = @($godotArgs | Where-Object { $_ -ne "--allow-4k-reference-capture" })
}
$visibleGame = $false
if ($godotArgs -contains "--visible-game") {
    $visibleGame = $true
    $godotArgs = @($godotArgs | Where-Object { $_ -ne "--visible-game" })
}
if ($allow4kReferenceCapture -and -not $visibleGame) {
    throw "--allow-4k-reference-capture requires --visible-game."
}

$idleEliteLaunchProjectRoot = (Get-Location).Path
for ($argumentIndex = 0; $argumentIndex -lt $godotArgs.Count; $argumentIndex++) {
    if ($godotArgs[$argumentIndex] -eq "--path") {
        if ($argumentIndex + 1 -ge $godotArgs.Count) {
            throw "--path requires a project directory."
        }
        $idleEliteLaunchProjectRoot = [System.IO.Path]::GetFullPath($godotArgs[$argumentIndex + 1])
        break
    }
    if ($godotArgs[$argumentIndex] -like "--path=*") {
        $idleEliteLaunchProjectRoot = [System.IO.Path]::GetFullPath($godotArgs[$argumentIndex].Substring(7))
        break
    }
}

$idleEliteLaunchProjectSettingsPath = Join-Path $idleEliteLaunchProjectRoot "project.godot"
if (Test-Path -LiteralPath $idleEliteLaunchProjectSettingsPath) {
    $idleEliteLaunchProjectSettings = Get-Content -Raw -LiteralPath $idleEliteLaunchProjectSettingsPath
    $idleEliteLaunchIsArchived4k = (
        $idleEliteLaunchProjectSettings -match '(?m)^window/size/viewport_width=2160\r?$' -and
        $idleEliteLaunchProjectSettings -match '(?m)^window/size/viewport_height=3840\r?$'
    )
    if ($idleEliteLaunchIsArchived4k -and -not $allow4kReferenceCapture) {
        throw "Refusing to launch the archived 2160 x 3840 Idle Elite project. Use --allow-4k-reference-capture with --visible-game only for side-by-side image capture; all gameplay testing and validation must use a native 1080 x 1920 worktree."
    }
}

if ($godotArgs -contains "--editor" -or $godotArgs -contains "-e" -or $godotArgs -contains "--project-manager") {
    throw "Refusing to launch the Godot editor or project manager."
}
if (-not $visibleGame -and $godotArgs -notcontains "--headless") {
    $godotArgs = @("--headless") + $godotArgs
}
$previousAppData = $env:APPDATA
# Every headless run gets its own user:// so tests and smoke boots can never load
# or overwrite the developer's real desktop save. Visible game runs keep the real
# profile unless a test explicitly supplies IDLE_ELITE_TEST_USER_DATA_DIR.
$removeHeadlessUserData = $false
# Exports never run game code, and they need the real export_templates folder under APPDATA.
$exportRun = @($godotArgs | Where-Object { "$_" -like "--export-*" }).Count -gt 0
$isolatedUserDataActive = (-not $visibleGame -and -not $exportRun) -or [bool]$env:IDLE_ELITE_TEST_USER_DATA_DIR
$headlessUserDataDir = ""
if ($isolatedUserDataActive) {
    $requestedUserDataDir = $env:IDLE_ELITE_TEST_USER_DATA_DIR
    if (-not $requestedUserDataDir) {
        $removeHeadlessUserData = $true
        $requestedUserDataDir = Join-Path $env:TEMP ("idle-elite-godot-user-{0}" -f ([guid]::NewGuid()))
    }
    $headlessUserDataDir = (New-Item -ItemType Directory -Force -Path $requestedUserDataDir).FullName
    $env:APPDATA = $headlessUserDataDir
}

function Restore-RunnerUserData {
    param([int]$ExitCode)
    if (-not $isolatedUserDataActive) {
        return
    }
    if ($null -eq $previousAppData) {
        Remove-Item Env:\APPDATA -ErrorAction SilentlyContinue
    } else {
        $env:APPDATA = $previousAppData
    }
    if ($removeHeadlessUserData -and $ExitCode -eq 0) {
        $tempRoot = [IO.Path]::GetFullPath($env:TEMP).TrimEnd('') + ''
        if ($headlessUserDataDir.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) {
            Remove-Item -LiteralPath $headlessUserDataDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function ConvertTo-ProcessArgument {
    param([Parameter(Mandatory = $true)][string]$Argument)

    if ($Argument -notmatch '[\s"]') {
        return $Argument
    }

    return '"' + ($Argument -replace '\\(?=")', '\\' -replace '"', '\"') + '"'
}

$stdoutPath = Join-Path $env:TEMP ("godot-safe-{0}.stdout.log" -f ([guid]::NewGuid()))
$stderrPath = Join-Path $env:TEMP ("godot-safe-{0}.stderr.log" -f ([guid]::NewGuid()))
$mutex = New-Object System.Threading.Mutex($false, "Global\IdleEliteGodotLaunchGate")
$deadline = (Get-Date).AddSeconds($waitSeconds)
$process = $null
$mutexHeld = $false

try {
    while ($true) {
        $mutexHeld = $mutex.WaitOne([TimeSpan]::FromSeconds($pollSeconds))
        if (-not $mutexHeld) {
            if ((Get-Date) -ge $deadline) {
                Write-Error "Timed out waiting for the Godot launch gate."
                Restore-RunnerUserData 75
                exit 75
            }
            continue
        }

        $beforeSnapshot = Get-GodotProcessSnapshot
        $running = $beforeSnapshot.Processes
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
                        -WindowStyle Normal
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
            # Windows PowerShell only records ExitCode for a Start-Process object whose
            # handle was opened while the process was alive. Without this, ExitCode is
            # $null and every failing Godot run below would be reported as exit 0.
            $null = $process.Handle
            break
        }

        $mutex.ReleaseMutex()
        $mutexHeld = $false

        if ((Get-Date) -ge $deadline) {
            Write-Error "There are already $($running.Count) Godot processes running. No slot opened within $waitSeconds seconds."
            Restore-RunnerUserData 75
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

if ($runTimeoutSeconds -gt 0) {
    $finished = $process.WaitForExit($runTimeoutSeconds * 1000)
    if (-not $finished) {
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
        Write-Error "Godot did not finish within $runTimeoutSeconds seconds and was stopped."
        Restore-RunnerUserData 124
        exit 124
    }
} else {
    $process.WaitForExit()
}

if (-not $visibleGame -and (Test-Path -LiteralPath $stdoutPath)) {
    Get-Content -LiteralPath $stdoutPath
}
$stderrLines = @()
if (-not $visibleGame -and (Test-Path -LiteralPath $stderrPath)) {
    $stderrLines = @(Get-Content -LiteralPath $stderrPath)
    $stderrLines | ForEach-Object { Write-Output $_ }
}

$process.Refresh()
$exitCode = if ($null -eq $process.ExitCode) { 1 } else { $process.ExitCode }
if ($exitCode -eq 0 -and ($stderrLines -match "Main executable .* not found")) {
    $exitCode = 1
}
if ($exitCode -eq 0 -and ($stderrLines -match "CrashHandlerException|Program crashed with signal|-- END OF C\+\+ BACKTRACE --")) {
    $exitCode = 139
}

$launchedProcessIds = @($process.Id) + @(Get-ChildProcessIds -ParentProcessId $process.Id)
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

    $cpuBefore = $null
    $cpuAfter = $null
    try {
        $cpuBefore = $remainingProcess.CPU
        Start-Sleep -Milliseconds 500
        $remainingProcess.Refresh()
        $cpuAfter = $remainingProcess.CPU
    } catch {
        # The process may exit or deny access between cleanup checks.
    }
    $cpuDelta = if ($null -ne $cpuBefore -and $null -ne $cpuAfter) { $cpuAfter - $cpuBefore } else { 0 }

    if ($null -ne $cpuBefore -and $null -ne $cpuAfter -and $cpuDelta -lt 0.05) {
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
$unmatchedNewIds = @()
foreach ($processId in $newUnattributedIds) {
    $detail = $afterSnapshot.Details[[int]$processId]
    $commandLine = if ($null -ne $detail) { [string]$detail.CommandLine } else { "" }
    $executablePath = if ($null -ne $detail) { [string]$detail.ExecutablePath } else { "" }
    $matchesInvocation = -not $visibleGame -and -not [string]::IsNullOrWhiteSpace($commandLine)
    if ($matchesInvocation) {
        if ([string]::IsNullOrWhiteSpace($executablePath)) {
            $matchesInvocation = $false
        } else {
            try {
                $matchesInvocation = [IO.Path]::GetFullPath($executablePath) -eq [IO.Path]::GetFullPath($godotPath)
            } catch {
                $matchesInvocation = $false
            }
        }
    }
    if ($matchesInvocation) {
        foreach ($argument in $godotArgs) {
            if ($argument -eq "--headless" -or [string]::IsNullOrWhiteSpace([string]$argument)) {
                continue
            }
            if ($commandLine.IndexOf([string]$argument, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
                $matchesInvocation = $false
                break
            }
        }
    }
    if (-not $matchesInvocation) {
        $unmatchedNewIds += $processId
        continue
    }
    Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
    [Console]::Error.WriteLine("Terminated detached headless Godot process matched to this command: PID $processId")
}
if ($unmatchedNewIds.Count -gt 0) {
    $unattributedStillRunning = @($unmatchedNewIds)
    for ($attempt = 1; $attempt -le 50 -and $unattributedStillRunning.Count -gt 0; $attempt++) {
        Start-Sleep -Milliseconds 100
        $currentGodotSnapshot = Get-GodotProcessSnapshot
        $unattributedStillRunning = @(
            $unattributedStillRunning |
                Where-Object { $currentGodotSnapshot.Details.ContainsKey([int]$_) }
        )
    }
    if ($unattributedStillRunning.Count -gt 0) {
        Write-Error "New Godot process(es) appeared during this command but were not confirmed as children of this run: $($unattributedStillRunning -join ', '). They were not terminated." -ErrorAction Continue
        if ($exitCode -eq 0) {
            $exitCode = 125
        }
    }
}

Restore-RunnerUserData $exitCode
Remove-Item -LiteralPath $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
exit $exitCode
