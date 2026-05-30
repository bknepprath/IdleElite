$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $projectRoot "firebase-leaderboard-config.json"
$firebaseDatabaseUrlPattern = '^https://([a-z0-9-]+\.firebaseio\.com|[a-z0-9-]+\.[a-z0-9-]+\.firebasedatabase\.app)$'

function Invoke-Step {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][scriptblock]$Script
    )

    Write-Output "== $Name =="
    & $Script
}

function Get-GodotProcessSnapshot {
    $processes = @(Get-CimInstance Win32_Process -Filter "name like 'Godot%'" -ErrorAction SilentlyContinue)
    foreach ($process in $processes) {
        [pscustomobject]@{
            ProcessId = $process.ProcessId
            Name = $process.Name
            CommandLine = $process.CommandLine
        }
    }
}

Invoke-Step "Firebase rules are generated from activity database" {
    & (Join-Path $projectRoot "scripts\update-firebase-leaderboard-rules.ps1") -Check
}

Invoke-Step "Leaderboard cost-safety audit" {
    & (Join-Path $projectRoot "scripts\check-leaderboard-cost-safety.ps1")
}

Invoke-Step "Rules and activity JSON parse" {
	$null = Get-Content -LiteralPath (Join-Path $projectRoot "firebase-realtime-database.rules.json") -Raw | ConvertFrom-Json
	$null = Get-Content -LiteralPath (Join-Path $projectRoot "docs\activity-database.json") -Raw | ConvertFrom-Json
	Write-Output "json-parse-ok"
}

Invoke-Step "Firebase config validation" {
    & (Join-Path $projectRoot "scripts\test-firebase-leaderboard-config-validation.ps1")
}

Invoke-Step "Firebase setup state" {
    & (Join-Path $projectRoot "scripts\check-firebase-leaderboard-setup-state.ps1")
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

Invoke-Step "Firebase runtime config guard" {
    & (Join-Path $projectRoot "scripts\test-firebase-leaderboard-runtime-guard.ps1")
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

Invoke-Step "Firebase rules deploy check" {
    & (Join-Path $projectRoot "scripts\deploy-firebase-leaderboard-rules.ps1") -ProjectId "idle-elite-check" -CheckOnly
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

Invoke-Step "Optional local Firebase config" {
    if (-not (Test-Path -LiteralPath $configPath)) {
        Write-Output "firebase-config-absent"
        return
    }
    $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
    $databaseUrl = [string]$config.database_url
    $webApiKey = [string]$config.web_api_key
    if ($databaseUrl.Trim().TrimEnd("/") -cnotmatch $firebaseDatabaseUrlPattern) {
        throw "firebase-leaderboard-config.json has an invalid database_url."
    }
    if ($databaseUrl -match 'your-project-id|YOUR-PROJECT') {
        throw "firebase-leaderboard-config.json still contains a placeholder database_url."
    }
    if ($webApiKey.Trim().Length -lt 20 -or $webApiKey -eq "YOUR_FIREBASE_WEB_API_KEY" -or $webApiKey -match '\s') {
        throw "firebase-leaderboard-config.json has an invalid web_api_key."
    }
    Write-Output "firebase-config-ok"
}

Invoke-Step "Godot safe validation" {
    & (Join-Path $projectRoot "scripts\check-project.ps1")
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

Invoke-Step "Post-Godot process snapshot" {
    $snapshot = @(Get-GodotProcessSnapshot)
    $headless = @($snapshot | Where-Object { $_.CommandLine -match '--headless' })
    if ($headless.Count -gt 0) {
        $headless | Format-Table -AutoSize | Out-String | Write-Output
        throw "A headless Godot process is still running after validation."
    }
    if ($snapshot.Count -eq 0) {
        Write-Output "no-godot-processes"
    } else {
        $snapshot | Format-Table -AutoSize | Out-String | Write-Output
    }
}

Write-Output "firebase-leaderboard-preflight-ok"
