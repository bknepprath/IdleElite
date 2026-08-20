$ErrorActionPreference = "Stop"

$maxGodots = 4
$waitSeconds = 300
$pollSeconds = 10

if ($env:GODOT_MAX_PROCESSES) {
    $maxGodots = [int]$env:GODOT_MAX_PROCESSES
}
if ($env:GODOT_SLOT_WAIT_SECONDS) {
    $waitSeconds = [int]$env:GODOT_SLOT_WAIT_SECONDS
}

$candidatePaths = @(
    "C:\Users\bknep\Documents\New project 4\.codex-godot-r471\godot.exe"
)
if ($env:GODOT_BIN) {
    $candidatePaths += $env:GODOT_BIN
}

$godotPath = $candidatePaths | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
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
if ($godotArgs -contains "--editor" -or $godotArgs -contains "-e" -or $godotArgs -contains "--project-manager") {
    throw "Refusing to launch the Godot editor or project manager."
}
if (-not $visibleGame -and $godotArgs -notcontains "--headless") {
    $godotArgs = @("--headless") + $godotArgs
}
$previousAppData = $env:APPDATA
if ($env:IDLE_ELITE_TEST_USER_DATA_DIR) {
    $testUserDataDir = (New-Item -ItemType Directory -Force -Path $env:IDLE_ELITE_TEST_USER_DATA_DIR).FullName
    $env:APPDATA = $testUserDataDir
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
$beforeSnapshot = Get-GodotProcessSnapshot

try {
    while ($true) {
        $mutexHeld = $mutex.WaitOne([TimeSpan]::FromSeconds($pollSeconds))
        if (-not $mutexHeld) {
            if ((Get-Date) -ge $deadline) {
                Write-Error "Timed out waiting for the Godot launch gate."
                exit 75
            }
            continue
        }

        $running = @(Get-Process godot* -ErrorAction SilentlyContinue)
        if ($running.Count -lt $maxGodots) {
            $argumentList = ($godotArgs | ForEach-Object { ConvertTo-ProcessArgument $_ }) -join " "
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
            break
        }

        $mutex.ReleaseMutex()
        $mutexHeld = $false

        if ((Get-Date) -ge $deadline) {
            Write-Error "There are already $($running.Count) Godot processes running. No slot opened within $waitSeconds seconds."
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
    $stderrLines | ForEach-Object { [Console]::Error.WriteLine($_) }
}

$process.Refresh()
$exitCode = if ($null -eq $process.ExitCode) { 0 } else { $process.ExitCode }
if ($exitCode -eq 0 -and ($stderrLines -match "Main executable .* not found")) {
    $exitCode = 1
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
$unmatchedNewIds = @()
foreach ($processId in $newUnattributedIds) {
    $detail = $afterSnapshot.Details[[int]$processId]
    $commandLine = if ($null -ne $detail) { [string]$detail.CommandLine } else { "" }
    $executablePath = if ($null -ne $detail) { [string]$detail.ExecutablePath } else { "" }
    $matchesInvocation = -not $visibleGame -and -not [string]::IsNullOrWhiteSpace($commandLine)
    if ($matchesInvocation -and -not [string]::IsNullOrWhiteSpace($executablePath)) {
        $matchesInvocation = [IO.Path]::GetFullPath($executablePath) -eq [IO.Path]::GetFullPath($godotPath)
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
    [Console]::Error.WriteLine("New Godot process(es) appeared during this command but were not confirmed as children of this run: $($unmatchedNewIds -join ', '). They were not terminated.")
}

if ($env:IDLE_ELITE_TEST_USER_DATA_DIR) {
    if ($null -eq $previousAppData) {
        Remove-Item Env:\APPDATA -ErrorAction SilentlyContinue
    } else {
        $env:APPDATA = $previousAppData
    }
}

Remove-Item -LiteralPath $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
exit $exitCode
