param(
    [string]$OutputDirectory
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$sourceRulesPath = Join-Path $projectRoot "firebase-realtime-database.rules.json"
$gitIgnorePath = Join-Path $projectRoot ".gitignore"
$releaseRoot = [System.IO.Path]::GetFullPath((Join-Path $projectRoot "release"))
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $releaseRoot "firebase-migration-freeze"
} elseif (-not [System.IO.Path]::IsPathRooted($OutputDirectory)) {
    $OutputDirectory = Join-Path $projectRoot $OutputDirectory
}
$OutputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)

function Assert-Condition {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Convert-ToFreezeValue {
    param($Value)

    if ($null -eq $Value) {
        return $null
    }
    if ($Value -is [pscustomobject]) {
        $copy = [ordered]@{}
        foreach ($property in $Value.PSObject.Properties) {
            if ([string]$property.Name -ceq ".write") {
                $script:writeRuleCount += 1
                $copy[$property.Name] = $false
            } else {
                $copy[$property.Name] = Convert-ToFreezeValue -Value $property.Value
            }
        }
        return $copy
    }
    if ($Value -is [System.Array]) {
        $items = @()
        foreach ($item in $Value) {
            $items += ,(Convert-ToFreezeValue -Value $item)
        }
        return ,$items
    }
    return $Value
}

function Assert-FreezeEquivalent {
    param(
        $Source,
        $Frozen,
        [Parameter(Mandatory = $true)][string]$Path
    )

    if ($Source -is [pscustomobject]) {
        Assert-Condition ($Frozen -is [pscustomobject]) "Freeze rules changed the JSON type at $Path."
        $sourceNames = @($Source.PSObject.Properties | ForEach-Object { [string]$_.Name })
        $frozenNames = @($Frozen.PSObject.Properties | ForEach-Object { [string]$_.Name })
        Assert-Condition (($sourceNames -join "`n") -ceq ($frozenNames -join "`n")) "Freeze rules changed property names at $Path."
        foreach ($property in $Source.PSObject.Properties) {
            $name = [string]$property.Name
            $frozenValue = $Frozen.PSObject.Properties[$name].Value
            if ($name -ceq ".write") {
                $script:validatedWriteRuleCount += 1
                Assert-Condition ($frozenValue -is [bool] -and $frozenValue -eq $false) "Freeze rules contain a non-false write at $Path/.write."
            } else {
                Assert-FreezeEquivalent -Source $property.Value -Frozen $frozenValue -Path "$Path/$name"
            }
        }
        return
    }
    if ($Source -is [System.Array]) {
        Assert-Condition ($Frozen -is [System.Array]) "Freeze rules changed an array at $Path."
        Assert-Condition ($Source.Count -eq $Frozen.Count) "Freeze rules changed array length at $Path."
        for ($index = 0; $index -lt $Source.Count; $index++) {
            Assert-FreezeEquivalent -Source $Source[$index] -Frozen $Frozen[$index] -Path "$Path[$index]"
        }
        return
    }

    $sourceJson = ConvertTo-Json -InputObject $Source -Compress
    $frozenJson = ConvertTo-Json -InputObject $Frozen -Compress
    Assert-Condition ($sourceJson -ceq $frozenJson) "Freeze rules changed a non-write value at $Path."
}

Assert-Condition (Test-Path -LiteralPath $sourceRulesPath -PathType Leaf) "Missing firebase-realtime-database.rules.json."
Assert-Condition (Test-Path -LiteralPath $gitIgnorePath -PathType Leaf) "Missing .gitignore."
$gitIgnore = Get-Content -LiteralPath $gitIgnorePath -Raw
Assert-Condition ($gitIgnore -match '(?m)^release/\s*$') "The release directory must remain ignored before generating migration evidence."
Assert-Condition ($OutputDirectory.StartsWith($releaseRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) "Migration freeze artifacts must stay inside the ignored release directory."

& (Join-Path $PSScriptRoot "update-firebase-leaderboard-rules.ps1") -Check

$sourceRules = Get-Content -LiteralPath $sourceRulesPath -Raw | ConvertFrom-Json
$script:writeRuleCount = 0
$frozenRules = Convert-ToFreezeValue -Value $sourceRules
Assert-Condition ($script:writeRuleCount -gt 0) "The generated final rules did not contain any .write rules to freeze."

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$freezeRulesPath = Join-Path $OutputDirectory "firebase-realtime-database.rules.json"
$temporaryFirebaseConfigPath = Join-Path $OutputDirectory "firebase.json"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$freezeRulesJson = ($frozenRules | ConvertTo-Json -Depth 64) + "`n"
[System.IO.File]::WriteAllText($freezeRulesPath, $freezeRulesJson, $utf8NoBom)

$temporaryFirebaseConfig = [ordered]@{
    database = [ordered]@{
        rules = "firebase-realtime-database.rules.json"
    }
}
$temporaryFirebaseConfigJson = ($temporaryFirebaseConfig | ConvertTo-Json -Depth 4) + "`n"
[System.IO.File]::WriteAllText($temporaryFirebaseConfigPath, $temporaryFirebaseConfigJson, $utf8NoBom)

$writtenFreezeRules = Get-Content -LiteralPath $freezeRulesPath -Raw | ConvertFrom-Json
$script:validatedWriteRuleCount = 0
Assert-FreezeEquivalent -Source $sourceRules -Frozen $writtenFreezeRules -Path '$'
Assert-Condition ($script:validatedWriteRuleCount -eq $script:writeRuleCount) "Freeze rules validation did not inspect every .write rule."

$writtenFirebaseConfig = Get-Content -LiteralPath $temporaryFirebaseConfigPath -Raw | ConvertFrom-Json
Assert-Condition ([string]$writtenFirebaseConfig.database.rules -ceq "firebase-realtime-database.rules.json") "Temporary firebase.json does not target the generated freeze rules."
Assert-Condition ($writtenFirebaseConfig.PSObject.Properties.Count -eq 1) "Temporary firebase.json must remain database-only."

Write-Output "firebase-migration-freeze-rules-ok writes_disabled=$($script:writeRuleCount)"
Write-Output "freeze_rules=$freezeRulesPath"
Write-Output "temporary_firebase_config=$temporaryFirebaseConfigPath"
