$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")

$parseFailures = @()
$powerShellScripts = @(Get-ChildItem -LiteralPath $PSScriptRoot -Filter "*.ps1" -File -Recurse)
foreach ($script in $powerShellScripts) {
    $tokens = $null
    $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref]$tokens, [ref]$errors)
    foreach ($parseError in @($errors)) {
        $relativePath = [IO.Path]::GetRelativePath($projectRoot, $script.FullName)
        $parseFailures += "${relativePath}:$($parseError.Extent.StartLineNumber): $($parseError.Message)"
    }
}
Assert-True ($parseFailures.Count -eq 0) "PowerShell harness parse failures:`n$($parseFailures -join "`n")"

$fishingHarnessPath = Join-Path $PSScriptRoot "test-fishing-click-flow.ps1"
Assert-True (Test-Path -LiteralPath $fishingHarnessPath) "Fishing click-flow harness is missing."
$fishingHarnessText = Get-Content -LiteralPath $fishingHarnessPath -Raw
$generatedScriptMatch = [regex]::Match($fishingHarnessText, "(?s)@'\r?\n(?<gd>.*)\r?\n'@ \| Set-Content")
Assert-True $generatedScriptMatch.Success "Fishing click-flow generated GDScript could not be located."
$corruptionPattern = 'procecc|ccene|falce|fiching|rec://|run-godot-cafe|ic_inctance|\.cet\(|\.cize\(|\.valuec\(|\.keyc\(|%c|\bac\b|ctr\('
Assert-True (-not [regex]::IsMatch($generatedScriptMatch.Groups["gd"].Value, $corruptionPattern)) "Fishing click-flow generated GDScript contains a known corruption signature."
Assert-True ($fishingHarnessText -match 'IDLE_ELITE_DISABLE_SAVE_WRITES') "Fishing click-flow harness must disable save writes."
Assert-True ($fishingHarnessText -match 'Get-HeadlessGodotProcesses') "Fishing click-flow harness must verify headless-process cleanup."

$navigationHarnessPath = Join-Path $PSScriptRoot "test-accidental-navigation-release.ps1"
Assert-True (Test-Path -LiteralPath $navigationHarnessPath) "Accidental-navigation harness is missing."
$navigationHarnessText = Get-Content -LiteralPath $navigationHarnessPath -Raw
Assert-True ($navigationHarnessText -match 'IDLE_ELITE_TEST_USER_DATA_DIR') "Accidental-navigation harness must use isolated user data."
Assert-True ($navigationHarnessText -match 'IDLE_ELITE_DISABLE_SAVE_WRITES') "Accidental-navigation harness must disable save writes."
Assert-True ($navigationHarnessText -match 'Get-HeadlessGodotProcesses') "Accidental-navigation harness must verify headless-process cleanup."

$captureFailures = @()
$captureScripts = @(Get-ChildItem -LiteralPath $PSScriptRoot -Filter "capture-*.ps1" -File)
foreach ($script in $captureScripts) {
    $text = Get-Content -LiteralPath $script.FullName -Raw
    if ($text -notmatch 'save_png') {
        continue
    }
    $relativePath = [IO.Path]::GetRelativePath($projectRoot, $script.FullName)
    foreach ($contract in @(
        @{ Valid = $text -match 'res://scenes/main\.tscn'; Message = "must instantiate res://scenes/main.tscn" },
        @{ Valid = $text -match '--visible-game'; Message = "must run through the bounded visible-game wrapper" },
        @{ Valid = $text -match 'CONTENT_SCALE_MODE_VIEWPORT'; Message = "must use viewport content scaling" },
        @{ Valid = $text -notmatch 'CONTENT_SCALE_MODE_CANVAS_ITEMS'; Message = "must not use canvas-items content scaling" },
        @{ Valid = $text -notmatch '\bSubViewport\b'; Message = "must not use an isolated SubViewport" },
        @{ Valid = $text -notmatch '\bscene\.visible\s*=\s*false'; Message = "must not hide the production scene" }
    )) {
        if (-not $contract.Valid) {
            $captureFailures += "${relativePath}: $($contract.Message)"
        }
    }
}

$standaloneCaptureScripts = @(Get-ChildItem -LiteralPath $PSScriptRoot -Filter "*capture*.gd" -File -Recurse)
foreach ($script in $standaloneCaptureScripts) {
    $text = Get-Content -LiteralPath $script.FullName -Raw
    $relativePath = [IO.Path]::GetRelativePath($projectRoot, $script.FullName)
    if ($text -match 'CONTENT_SCALE_MODE_CANVAS_ITEMS|\bSubViewport\b') {
        $captureFailures += "${relativePath}: standalone capture uses a prohibited isolated-render technique"
    }
}
Assert-True ($captureFailures.Count -eq 0) "Visual-evidence contract failures:`n$($captureFailures -join "`n")"

$projectText = Get-Content -LiteralPath (Join-Path $projectRoot "project.godot") -Raw
Assert-True ($projectText -match 'window/stretch/mode="viewport"') "project.godot must retain viewport stretch mode."

Write-Output "test-harness-contracts-ok powershell=$($powerShellScripts.Count) captures=$($captureScripts.Count)"
