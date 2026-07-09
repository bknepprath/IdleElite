$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$writerPath = Join-Path $projectRoot "scripts\write-firebase-leaderboard-config.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\firebase-config-validation"
$validTestKey = "AIzaSyValidationOnlyNotARealFirebaseKey123456"
$validGoogleWebClientId = "1234567890-validationonly.apps.googleusercontent.com"

function Invoke-ExpectValidConfig {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$DatabaseUrl
    )

    $outputPath = Join-Path $testDir "$Name.json"
    & $writerPath -DatabaseUrl $DatabaseUrl -WebApiKey $validTestKey -GoogleWebClientId $validGoogleWebClientId -OutputPath $outputPath | Out-Null

    Assert-True (Test-Path -LiteralPath $outputPath) "Expected config writer to create $Name."
    $config = Get-Content -LiteralPath $outputPath -Raw | ConvertFrom-Json
    Assert-True ([string]$config.database_url -eq $DatabaseUrl.Trim().TrimEnd("/")) "Config writer did not normalize $Name database_url."
    Assert-True ([string]$config.web_api_key -eq $validTestKey) "Config writer did not persist $Name web_api_key."
    Assert-True ([string]$config.google_web_client_id -eq $validGoogleWebClientId) "Config writer did not persist $Name google_web_client_id."
}

function Invoke-ExpectInvalidConfig {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$DatabaseUrl,
        [string]$WebApiKey = $validTestKey
    )

    $outputPath = Join-Path $testDir "$Name.json"
    $failed = $false
    try {
        & $writerPath -DatabaseUrl $DatabaseUrl -WebApiKey $WebApiKey -OutputPath $outputPath | Out-Null
    } catch {
        $failed = $true
    }

    Assert-True $failed "Expected config writer to reject $Name."
    Assert-True (-not (Test-Path -LiteralPath $outputPath)) "Config writer should not create $Name after validation failure."
}

function Invoke-ExpectInvalidGoogleClientConfig {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$GoogleWebClientId
    )

    $outputPath = Join-Path $testDir "$Name.json"
    $failed = $false
    try {
        & $writerPath -DatabaseUrl "https://idle-elite-default-rtdb.firebaseio.com" -WebApiKey $validTestKey -GoogleWebClientId $GoogleWebClientId -OutputPath $outputPath | Out-Null
    } catch {
        $failed = $true
    }

    Assert-True $failed "Expected config writer to reject $Name."
    Assert-True (-not (Test-Path -LiteralPath $outputPath)) "Config writer should not create $Name after Google client validation failure."
}

if (Test-Path -LiteralPath $testDir) {
    Remove-Item -LiteralPath $testDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

try {
    Invoke-ExpectValidConfig -Name "us-central1" -DatabaseUrl "https://idle-elite-default-rtdb.firebaseio.com/"
    Invoke-ExpectValidConfig -Name "regional" -DatabaseUrl "https://idle-elite-default-rtdb.europe-west1.firebasedatabase.app/"

    Invoke-ExpectInvalidConfig -Name "placeholder-url" -DatabaseUrl "https://your-project-id-default-rtdb.firebaseio.com"
    Invoke-ExpectInvalidConfig -Name "wrong-host" -DatabaseUrl "https://idle-elite.example.com"
    Invoke-ExpectInvalidConfig -Name "uppercase-host" -DatabaseUrl "https://Idle-Elite-default-rtdb.firebaseio.com"
    Invoke-ExpectInvalidConfig -Name "short-key" -DatabaseUrl "https://idle-elite-default-rtdb.firebaseio.com" -WebApiKey "too-short"
    Invoke-ExpectInvalidConfig -Name "spaced-key" -DatabaseUrl "https://idle-elite-default-rtdb.firebaseio.com" -WebApiKey "AIzaSy Validation Only Key"
    Invoke-ExpectInvalidGoogleClientConfig -Name "bad-google-client" -GoogleWebClientId "not-a-client-id"
} finally {
    Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Output "firebase-config-validation-ok"
