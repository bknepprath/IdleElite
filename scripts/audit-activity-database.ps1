$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$databasePath = Join-Path $projectRoot "docs\activity-database.json"
$mainScriptPath = Join-Path $projectRoot "scripts\main.gd"

if (-not (Test-Path -LiteralPath $databasePath)) {
    throw "Activity database was not found at $databasePath"
}

$database = Get-Content -LiteralPath $databasePath -Raw | ConvertFrom-Json
$mainScript = ""
if (Test-Path -LiteralPath $mainScriptPath) {
    $mainScript = Get-Content -LiteralPath $mainScriptPath -Raw
}

$errors = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]
$notes = New-Object System.Collections.Generic.List[string]

function Add-Finding {
    param(
        [System.Collections.Generic.List[string]] $List,
        [string] $Message
    )

    $List.Add($Message) | Out-Null
}

function Resolve-ProjectPath {
    param([string] $Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $null
    }

    $cleanPath = $Path
    if ($cleanPath.StartsWith("res://")) {
        $cleanPath = $cleanPath.Substring(6)
    }
    $cleanPath = $cleanPath -replace "/", "\"
    return Join-Path $projectRoot $cleanPath
}

function Read-GdConstNumber {
    param([string] $Name)

    if ([string]::IsNullOrWhiteSpace($mainScript)) {
        return $null
    }

    $match = [regex]::Match($mainScript, "const\s+$Name\s*:=\s*([0-9\s\.\+\-\*/]+)")
    if (-not $match.Success) {
        return $null
    }

    $expression = $match.Groups[1].Value.Trim()
    if ($expression -notmatch "^[0-9\s\.\+\-\*/]+$") {
        return $null
    }

    $table = New-Object System.Data.DataTable
    $value = $table.Compute($expression, "")
    return [double]$value
}

$skillIds = @{}
$actionCount = 0
$passiveCount = 0
$missingAssets = 0
$skills = @($database.skills)

if ($skills.Count -eq 0) {
    Add-Finding $errors "No skills were found in docs/activity-database.json."
}

foreach ($skill in $skills) {
    $skillId = [string]$skill.id
    if ([string]::IsNullOrWhiteSpace($skillId)) {
        Add-Finding $errors "A skill is missing an id."
        continue
    }

    if ($skillIds.ContainsKey($skillId)) {
        Add-Finding $errors "Duplicate skill id: $skillId."
    }
    $skillIds[$skillId] = $true

    $actions = @($skill.actions)
    if ($actions.Count -eq 0) {
        Add-Finding $errors "$skillId has no actions."
        continue
    }

    $actionIds = @{}
    $lastUnlock = 0
    $lastStamina = 0
    $lastXp = 0
    $lastSeconds = 0.0
    $lastSuccess = 101.0

    for ($i = 0; $i -lt $actions.Count; $i++) {
        $action = $actions[$i]
        $actionCount++
        $actionId = [string]$action.id
        $label = "$skillId action #$($i + 1)"
        if (-not [string]::IsNullOrWhiteSpace($actionId)) {
            $label = "$skillId/$actionId"
        }

        if ([string]::IsNullOrWhiteSpace($actionId)) {
            Add-Finding $errors "$label is missing an id."
        } elseif ($actionIds.ContainsKey($actionId)) {
            Add-Finding $errors "Duplicate action id within ${skillId}: $actionId."
        } else {
            $actionIds[$actionId] = $true
        }

        $kind = [string]$action.kind
        if ([string]::IsNullOrWhiteSpace($kind)) {
            $kind = "activity"
        }
        if ($kind -eq "passive_item_collect") {
            $passiveCount++
            if ($null -eq $action.passive) {
                Add-Finding $errors "$label is passive_item_collect but has no passive block."
            }
        }

        $unlock = [int]$action.unlock
        $stamina = [int]$action.stamina
        $xp = [int]$action.xp
        $seconds = [double]$action.seconds
        $success = [double]$action.success

        if ($unlock -lt $lastUnlock) {
            Add-Finding $warnings "$label unlock level drops from $lastUnlock to $unlock."
        }
        if ($kind -ne "passive_item_collect" -and $stamina -lt $lastStamina) {
            Add-Finding $warnings "$label stamina drops from $lastStamina to $stamina."
        }
        if ($kind -ne "passive_item_collect" -and $xp -lt $lastXp) {
            Add-Finding $warnings "$label XP drops from $lastXp to $xp."
        }
        if ($kind -ne "passive_item_collect" -and $seconds -lt $lastSeconds) {
            Add-Finding $warnings "$label seconds drops from $lastSeconds to $seconds."
        }
        if ($kind -ne "passive_item_collect" -and $success -gt $lastSuccess) {
            Add-Finding $warnings "$label success rises from $lastSuccess to $success."
        }
        if ($kind -ne "passive_item_collect" -and ($success -lt 5 -or $success -gt 100)) {
            Add-Finding $errors "$label success must be between 5 and 100, found $success."
        }

        foreach ($field in @("art", "background")) {
            $assetPath = [string]$action.$field
            if ([string]::IsNullOrWhiteSpace($assetPath)) {
                Add-Finding $warnings "$label has no $field path."
                continue
            }

            $resolved = Resolve-ProjectPath $assetPath
            if ($null -ne $resolved -and -not (Test-Path -LiteralPath $resolved)) {
                $missingAssets++
                Add-Finding $errors "$label references missing ${field}: $assetPath."
            }
        }

        $lastUnlock = $unlock
        if ($kind -ne "passive_item_collect") {
            $lastStamina = $stamina
            $lastXp = $xp
            $lastSeconds = $seconds
            $lastSuccess = $success
        }
    }
}

$globalRules = $database.global_rules
if ($null -ne $globalRules) {
    $constantChecks = @(
        @{ Json = "base_max_stamina"; Code = "BASE_MAX_STAMINA" },
        @{ Json = "stamina_regen_seconds"; Code = "STAMINA_REGEN_SECONDS" },
        @{ Json = "max_offline_seconds"; Code = "MAX_OFFLINE_SECONDS" }
    )

    foreach ($check in $constantChecks) {
        $jsonName = $check.Json
        $codeName = $check.Code
        $jsonValue = [double]$globalRules.$jsonName
        $codeValue = Read-GdConstNumber $codeName
        if ($null -eq $codeValue) {
            Add-Finding $warnings "Could not find $codeName in scripts/main.gd."
            continue
        }
        if ([math]::Abs($jsonValue - $codeValue) -gt 0.001) {
            Add-Finding $warnings "Global rule $jsonName is $jsonValue, but $codeName is $codeValue."
        }
    }
} else {
    Add-Finding $warnings "No global_rules block was found."
}

foreach ($skill in $skills) {
    $actions = @($skill.actions)
    if ($actions.Count -gt 0) {
        $first = $actions[0]
        $last = $actions[$actions.Count - 1]
        Add-Finding $notes ("{0}: {1} actions, Lv {2}-{3}, XP {4}-{5}, success {6}%-{7}%." -f $skill.id, $actions.Count, $first.unlock, $last.unlock, $first.xp, $last.xp, $first.success, $last.success)
    }
}

Write-Output "Activity database audit"
Write-Output "Project: $projectRoot"
Write-Output ("Skills: {0}; actions: {1}; passive modules: {2}; missing assets: {3}" -f $skills.Count, $actionCount, $passiveCount, $missingAssets)
Write-Output ""

if ($errors.Count -gt 0) {
    Write-Output "Errors:"
    foreach ($errorText in $errors) {
        Write-Output "  - $errorText"
    }
    Write-Output ""
}

if ($warnings.Count -gt 0) {
    Write-Output "Warnings:"
    foreach ($warningText in $warnings) {
        Write-Output "  - $warningText"
    }
    Write-Output ""
}

Write-Output "Skill curves:"
foreach ($note in $notes) {
    Write-Output "  - $note"
}

if ($errors.Count -gt 0) {
    exit 1
}
