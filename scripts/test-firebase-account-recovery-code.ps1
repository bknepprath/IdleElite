$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$resolver = Join-Path $PSScriptRoot "resolve-firebase-account-recovery-code.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\firebase-account-recovery-code-test"
$authPath = Join-Path $testDir "auth.json"
$rtdbPath = Join-Path $testDir "rtdb.json"
$targetUid = "firebaseTargetUid123456"
$sourceUid = "p0123456789abcdef0123456789abcdef"

function Get-TestFingerprint {
    param([Parameter(Mandatory = $true)][string]$Value)

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Value)
        $hex = [System.BitConverter]::ToString($sha256.ComputeHash($bytes)).Replace("-", "").ToLowerInvariant()
        return $hex.Substring(0, 12)
    } finally {
        $sha256.Dispose()
    }
}

if (Test-Path -LiteralPath $testDir) {
    Remove-Item -LiteralPath $testDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

try {
    @{
        users = @(@{localId = $targetUid; disabled = $false})
    } | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $authPath -Encoding UTF8
    @{
        leaderboards = @{
            v1 = @{
                name_claims = @{
                    test_player = @{
                        uid = $sourceUid
                        name = "Test Player"
                        name_key = "test_player"
                        avatar_index = 3
                    }
                }
                profiles_by_uid = @{}
            }
        }
    } | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $rtdbPath -Encoding UTF8
    $code = "T-{0} S-{1}" -f (Get-TestFingerprint -Value $targetUid), (Get-TestFingerprint -Value $sourceUid)
    $result = & $resolver -RecoveryCode $code -AuthExportPath $authPath -RtdbBackupPath $rtdbPath
    Assert-True ($result.status -eq "unique-match") "A unique active target and authless source claim should resolve."
    Assert-True ($result.target_uid -ceq $targetUid -and $result.source_uid -ceq $sourceUid) "The resolver returned the wrong unique target/source pair."
    Assert-True ($result.name_key -ceq "test_player") "The resolver returned the wrong source name claim."

    @{
        users = @(
            @{localId = $targetUid; disabled = $false},
            @{localId = $sourceUid; disabled = $false}
        )
    } | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $authPath -Encoding UTF8
    $liveSourceRefused = $false
    try {
        $null = & $resolver -RecoveryCode $code -AuthExportPath $authPath -RtdbBackupPath $rtdbPath
    } catch {
        $liveSourceRefused = $_.Exception.Message -eq "The source identifier still exists in Firebase Auth and cannot use the deleted/authless transfer workflow."
    }
    Assert-True $liveSourceRefused "A source UID that still exists in Auth must never be transferable."
    Write-Output "firebase-account-recovery-code-test-ok"
} finally {
    Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
}
