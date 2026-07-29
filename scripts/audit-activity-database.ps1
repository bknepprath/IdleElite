$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$databasePath = Join-Path $projectRoot "docs\activity-database.json"
$mainScriptPath = Join-Path $projectRoot "scripts\main.gd"
$skillStateScriptPath = Join-Path $projectRoot "scripts\progression\skill_state.gd"
$passiveRuntimeScriptPath = Join-Path $projectRoot "scripts\gameplay\passive_modules_runtime.gd"
$hubSurfaceScriptPath = Join-Path $projectRoot "scripts\ui\hub_surface.gd"
$exportPresetsPath = Join-Path $projectRoot "export_presets.cfg"

if (-not (Test-Path -LiteralPath $databasePath)) {
    throw "Activity database was not found at $databasePath"
}

$database = Get-Content -LiteralPath $databasePath -Raw | ConvertFrom-Json
$mainScript = ""
if (Test-Path -LiteralPath $mainScriptPath) {
    $mainScript = Get-Content -LiteralPath $mainScriptPath -Raw
}
$runtimeConstantScripts = @($mainScript)
foreach ($runtimeScriptPath in @($skillStateScriptPath, $passiveRuntimeScriptPath)) {
    if (Test-Path -LiteralPath $runtimeScriptPath) {
        $runtimeConstantScripts += Get-Content -LiteralPath $runtimeScriptPath -Raw
    }
}
$hubSurfaceScript = ""
if (Test-Path -LiteralPath $hubSurfaceScriptPath) {
    $hubSurfaceScript = Get-Content -LiteralPath $hubSurfaceScriptPath -Raw
}
$exportPresets = ""
if (Test-Path -LiteralPath $exportPresetsPath) {
    $exportPresets = Get-Content -LiteralPath $exportPresetsPath -Raw
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

    foreach ($runtimeScript in $runtimeConstantScripts) {
        $match = [regex]::Match($runtimeScript, "const\s+$Name\s*:=\s*([0-9\s\.\+\-\*/]+)")
        if (-not $match.Success) {
            continue
        }

        $expression = $match.Groups[1].Value.Trim()
        if ($expression -notmatch "^[0-9\s\.\+\-\*/]+$") {
            continue
        }

        $table = New-Object System.Data.DataTable
        return [double]$table.Compute($expression, "")
    }

    return $null
}

function Has-ObjectProperty {
    param(
        [object] $Object,
        [string] $Name
    )

    if ($null -eq $Object) {
        return $false
    }
    return $null -ne $Object.PSObject.Properties[$Name]
}

function Get-ObjectProperty {
    param(
        [object] $Object,
        [string] $Name
    )

    if ($null -eq $Object) {
        return $null
    }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }
    return $property.Value
}

function Get-ArrayProperty {
    param(
        [object] $Object,
        [string] $Name
    )

    if (-not (Has-ObjectProperty $Object $Name)) {
        return @()
    }
    $value = Get-ObjectProperty $Object $Name
    if ($null -eq $value) {
        return @()
    }
    return @($value)
}

function Test-PositiveNumber {
    param([object] $Value)

    if ($null -eq $Value) {
        return $false
    }
    try {
        $number = [double]$Value
    } catch {
        return $false
    }
    return (-not [double]::IsNaN($number)) -and (-not [double]::IsInfinity($number)) -and $number -gt 0
}

function Test-PositiveInteger {
    param([object] $Value)

    if ($null -eq $Value) {
        return $false
    }
    $text = ([string]$Value).Trim()
    if ($text -notmatch "^\d+$") {
        return $false
    }
    return [int]$text -gt 0
}

function Validate-OptionalPositiveInteger {
    param(
        [object] $Item,
        [string] $PropertyName,
        [string] $Label
    )

    if (-not (Has-ObjectProperty $Item $PropertyName)) {
        return
    }
    $value = Get-ObjectProperty $Item $PropertyName
    if (-not (Test-PositiveInteger $value)) {
        Add-Finding $errors "$label $PropertyName must be a positive integer, found $value."
    }
}

function Validate-RequirementList {
    param(
        [object] $Item,
        [string] $Label,
        [string] $OwnerSkillId,
        [bool] $RequireExplicit = $false
    )

    if (-not (Has-ObjectProperty $Item "requirements")) {
        if ($RequireExplicit) {
            Add-Finding $errors "$Label must define requirements."
        } elseif (-not (Test-PositiveInteger (Get-ObjectProperty $Item "unlock"))) {
            Add-Finding $errors "$Label must define a positive unlock level or explicit requirements."
        }
        return 0
    }

    $requirements = Get-ArrayProperty $Item "requirements"
    if ($requirements.Count -eq 0) {
        Add-Finding $errors "$Label requirements must contain at least one entry."
        return 0
    }
    if ($requirements.Count -gt 5) {
        Add-Finding $errors "$Label requirements has $($requirements.Count) entries; max supported lock count is 5."
    }

    $seenRequirementSkills = @{}
    for ($r = 0; $r -lt $requirements.Count; $r++) {
        $requirement = $requirements[$r]
        $reqLabel = "$Label requirement #$($r + 1)"
        $reqSkill = [string](Get-ObjectProperty $requirement "skill")
        $reqLevel = Get-ObjectProperty $requirement "level"

        if ([string]::IsNullOrWhiteSpace($reqSkill)) {
            Add-Finding $errors "$reqLabel is missing a skill id."
        } elseif (-not $knownSkillIds.ContainsKey($reqSkill)) {
            Add-Finding $errors "$reqLabel references unknown skill: $reqSkill."
        } elseif ($seenRequirementSkills.ContainsKey($reqSkill)) {
            Add-Finding $errors "$Label repeats requirement skill: $reqSkill."
        } else {
            $seenRequirementSkills[$reqSkill] = $true
        }

        if (-not (Test-PositiveInteger $reqLevel)) {
            Add-Finding $errors "$reqLabel level must be a positive integer, found $reqLevel."
        }
    }

    if ($requirements.Count -eq 1) {
        $onlySkill = [string](Get-ObjectProperty $requirements[0] "skill")
        if (-not [string]::IsNullOrWhiteSpace($OwnerSkillId) -and $onlySkill -ne $OwnerSkillId) {
            Add-Finding $warnings "$Label has one explicit requirement for $onlySkill but lives on $OwnerSkillId."
        }
    }

    return $requirements.Count
}

function Validate-RewardMap {
    param(
        [object] $Item,
        [string] $Label,
        [string] $OwnerSkillId,
        [bool] $RequireExplicit = $false
    )

    if (-not (Has-ObjectProperty $Item "xp_rewards")) {
        if ($RequireExplicit) {
            Add-Finding $errors "$Label must define xp_rewards."
        } elseif (-not (Test-PositiveNumber (Get-ObjectProperty $Item "xp"))) {
            Add-Finding $errors "$Label must define positive xp or xp_rewards."
        }
        return 0
    }

    $rewardMap = Get-ObjectProperty $Item "xp_rewards"
    $rewardProperties = @()
    if ($null -ne $rewardMap -and $null -ne $rewardMap.PSObject) {
        $rewardProperties = @($rewardMap.PSObject.Properties)
    }
    if ($rewardProperties.Count -eq 0) {
        Add-Finding $errors "$Label xp_rewards must contain at least one skill reward."
        return 0
    }

    foreach ($reward in $rewardProperties) {
        $rewardSkill = [string]$reward.Name
        $rewardXp = $reward.Value
        if ([string]::IsNullOrWhiteSpace($rewardSkill)) {
            Add-Finding $errors "$Label has an empty xp_rewards skill id."
        } elseif (-not $knownSkillIds.ContainsKey($rewardSkill)) {
            Add-Finding $errors "$Label xp_rewards references unknown skill: $rewardSkill."
        }
        if (-not (Test-PositiveNumber $rewardXp)) {
            Add-Finding $errors "$Label xp_rewards.$rewardSkill must be positive, found $rewardXp."
        }
    }

    if ($rewardProperties.Count -eq 1) {
        $onlySkill = [string]$rewardProperties[0].Name
        if (-not [string]::IsNullOrWhiteSpace($OwnerSkillId) -and $onlySkill -ne $OwnerSkillId) {
            Add-Finding $warnings "$Label has one explicit XP reward for $onlySkill but lives on $OwnerSkillId."
        }
    }

    return $rewardProperties.Count
}

$skillIds = @{}
$knownSkillIds = @{}
$globalActionIds = @{}
$actionCount = 0
$passiveCount = 0
$missingAssets = 0
$comboActionCount = 0
$eventComboCount = 0
$rewardMapCount = 0
$requirementEntryCount = 0
$eventModuleCount = 0
$skills = @($database.skills)

if ($skills.Count -eq 0) {
    Add-Finding $errors "No skills were found in docs/activity-database.json."
}

foreach ($skill in $skills) {
    $knownSkillId = [string]$skill.id
    if (-not [string]::IsNullOrWhiteSpace($knownSkillId)) {
        $knownSkillIds[$knownSkillId] = $true
    }
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
        if (-not [string]::IsNullOrWhiteSpace($actionId)) {
            if ($globalActionIds.ContainsKey($actionId)) {
                Add-Finding $errors "Duplicate action id across modules: $actionId is used by $($globalActionIds[$actionId]) and $label."
            } else {
                $globalActionIds[$actionId] = $label
            }
        }

        $kind = [string]$action.kind
        if ([string]::IsNullOrWhiteSpace($kind)) {
            $kind = "activity"
        }
        $isLinearAction = $kind -eq "activity" -and -not (Has-ObjectProperty $action "recovery") -and -not (Has-ObjectProperty $action "combat")
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

        Validate-OptionalPositiveInteger $action "sort_unlock" $label
        $requirementCount = Validate-RequirementList $action $label $skillId
        if ($requirementCount -gt 0) {
            $requirementEntryCount += $requirementCount
        }
        if ($requirementCount -gt 1) {
            $comboActionCount++
        }
        if ($kind -ne "passive_item_collect") {
            $rewardCount = Validate-RewardMap $action $label $skillId
            if ($rewardCount -gt 0) {
                $rewardMapCount++
            }
        }

        if ($isLinearAction -and $unlock -lt $lastUnlock) {
            Add-Finding $warnings "$label unlock level drops from $lastUnlock to $unlock."
        }
        # Recovery, combat, and fishing methods have their own reward and timing curves.
        if ($skillId -ne "fishing" -and $isLinearAction) {
            if ($stamina -lt $lastStamina) {
                Add-Finding $warnings "$label stamina drops from $lastStamina to $stamina."
            }
            if ($xp -lt $lastXp) {
                Add-Finding $warnings "$label XP drops from $lastXp to $xp."
            }
            if ($seconds -lt $lastSeconds) {
                Add-Finding $warnings "$label seconds drops from $lastSeconds to $seconds."
            }
            if ($success -gt $lastSuccess) {
                Add-Finding $warnings "$label success rises from $lastSuccess to $success."
            }
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

        if ($isLinearAction) {
            $lastUnlock = $unlock
            $lastStamina = $stamina
            $lastXp = $xp
            $lastSeconds = $seconds
            $lastSuccess = $success
        }
    }

    if ($skillId -eq "fishing") {
        $areas = @($skill.areas)
        $areaIds = @{}
        $actionsByArea = @{}
        if ($areas.Count -eq 0) {
            Add-Finding $errors "fishing has no areas block (required for rework modules)."
        } else {
            foreach ($area in $areas) {
                $areaId = [string]$area.id
                $label = "fishing/area:$areaId"
                if ([string]::IsNullOrWhiteSpace($areaId)) {
                    Add-Finding $errors "A fishing area is missing an id."
                    continue
                }
                if ($areaIds.ContainsKey($areaId)) {
                    Add-Finding $errors "Duplicate fishing area id: $areaId."
                } else {
                    $areaIds[$areaId] = $true
                }
                $bgPath = [string]$area.background
                if ([string]::IsNullOrWhiteSpace($bgPath)) {
                    $bgPath = [string]$area.bg
                }
                if ([string]::IsNullOrWhiteSpace($bgPath)) {
                    Add-Finding $errors "$label has no background path."
                } else {
                    $resolvedBg = Resolve-ProjectPath $bgPath
                    if ($null -ne $resolvedBg -and -not (Test-Path -LiteralPath $resolvedBg)) {
                        $missingAssets++
                        Add-Finding $errors "$label references missing background: $bgPath."
                    }
                }
            }
        }
        for ($i = 0; $i -lt $actions.Count; $i++) {
            $action = $actions[$i]
            $label = "$skillId/$([string]$action.id)"
            $kind = [string]$action.kind
            if ([string]::IsNullOrWhiteSpace($kind)) {
                $kind = "activity"
            }
            if ($kind -eq "passive_item_collect") {
                continue
            }
            $areaId = [string]$action.area
            if ([string]::IsNullOrWhiteSpace($areaId)) {
                Add-Finding $errors "$label is missing area (required for fishing rework)."
                continue
            }
            if ($areaIds.Count -gt 0 -and -not $areaIds.ContainsKey($areaId)) {
                Add-Finding $errors "$label references unknown area: $areaId."
            }
            if (-not $actionsByArea.ContainsKey($areaId)) {
                $actionsByArea[$areaId] = New-Object System.Collections.Generic.List[string]
            }
            $actionsByArea[$areaId].Add([string]$action.id) | Out-Null
        }
        foreach ($areaId in $areaIds.Keys) {
            if (-not $actionsByArea.ContainsKey($areaId) -or $actionsByArea[$areaId].Count -eq 0) {
                Add-Finding $warnings "fishing/area:$areaId has no actions assigned."
            }
        }
    }
}

$eventModules = Get-ArrayProperty $database "event_modules"
for ($i = 0; $i -lt $eventModules.Count; $i++) {
    $event = $eventModules[$i]
    $eventModuleCount++
    $eventId = [string]$event.id
    $label = "event module #$($i + 1)"
    if (-not [string]::IsNullOrWhiteSpace($eventId)) {
        $label = "event/$eventId"
    }

    if ([string]::IsNullOrWhiteSpace($eventId)) {
        Add-Finding $errors "$label is missing an id."
    } elseif ($globalActionIds.ContainsKey($eventId)) {
        Add-Finding $errors "Duplicate action id across modules: $eventId is used by $($globalActionIds[$eventId]) and $label."
    } else {
        $globalActionIds[$eventId] = $label
    }

    $eventPage = [string]$event.page
    if ([string]::IsNullOrWhiteSpace($eventPage)) {
        Add-Finding $errors "$label is missing a page skill id."
    } elseif (-not $knownSkillIds.ContainsKey($eventPage)) {
        Add-Finding $errors "$label references unknown page skill: $eventPage."
    }

    $eventKind = [string]$event.kind
    if ($eventKind -ne "event_activity") {
        Add-Finding $warnings "$label kind should be event_activity, found $eventKind."
    }

    foreach ($requiredIntegerField in @("target_level", "minimum_level", "unlock", "sort_unlock")) {
        $fieldValue = Get-ObjectProperty $event $requiredIntegerField
        if (-not (Test-PositiveInteger $fieldValue)) {
            Add-Finding $errors "$label $requiredIntegerField must be a positive integer, found $fieldValue."
        }
    }

    foreach ($requiredNumberField in @("stamina", "seconds", "xp", "spawn_weight", "active_duration_seconds", "respawn_cooldown_seconds")) {
        $fieldValue = Get-ObjectProperty $event $requiredNumberField
        if (-not (Test-PositiveNumber $fieldValue)) {
            Add-Finding $errors "$label $requiredNumberField must be positive, found $fieldValue."
        }
    }

    $eventSuccess = [double]$event.success
    if ($eventSuccess -lt 5 -or $eventSuccess -gt 100) {
        Add-Finding $errors "$label success must be between 5 and 100, found $eventSuccess."
    }

    $eventRequirementCount = Validate-RequirementList $event $label $eventPage $true
    if ($eventRequirementCount -gt 0) {
        $requirementEntryCount += $eventRequirementCount
    }
    if ($eventRequirementCount -gt 1) {
        $eventComboCount++
    }
    $eventRewardCount = Validate-RewardMap $event $label $eventPage $true
    if ($eventRewardCount -gt 0) {
        $rewardMapCount++
    }

    if ((Test-PositiveNumber $event.active_duration_seconds) -and (Test-PositiveNumber $event.respawn_cooldown_seconds)) {
        $activeDuration = [double]$event.active_duration_seconds
        $cooldownDuration = [double]$event.respawn_cooldown_seconds
        if ($cooldownDuration -lt $activeDuration) {
            Add-Finding $warnings "$label cooldown $cooldownDuration is shorter than active duration $activeDuration."
        }
    }

    foreach ($field in @("art", "background")) {
        $assetPath = [string]$event.$field
        if ([string]::IsNullOrWhiteSpace($assetPath)) {
            Add-Finding $errors "$label has no $field path."
            continue
        }

        $resolved = Resolve-ProjectPath $assetPath
        if ($null -ne $resolved -and -not (Test-Path -LiteralPath $resolved)) {
            $missingAssets++
            Add-Finding $errors "$label references missing ${field}: $assetPath."
        }
    }
}

$globalRules = $database.global_rules
if ($null -ne $globalRules) {
    $tierSupportGoals = Get-ArrayProperty $globalRules "tier_support_goals"
    if ($tierSupportGoals.Count -ne 3) {
        Add-Finding $errors "global_rules.tier_support_goals must define Bronze, Silver, and Gold."
    }
    $seenMedalLevels = @{}
    $seenSupportStats = @{}
    foreach ($goal in $tierSupportGoals) {
        $medalLevel = [int]$goal.medal_level
        $stat = [string]$goal.stat
        if ($medalLevel -lt 1 -or $medalLevel -gt 3 -or $seenMedalLevels.ContainsKey($medalLevel)) {
            Add-Finding $errors "Tier support medal levels must be unique values from 1 through 3."
        } else {
            $seenMedalLevels[$medalLevel] = $true
        }
        if ($stat -notin @("accuracy", "stamina", "time") -or $seenSupportStats.ContainsKey($stat)) {
            Add-Finding $errors "Tier support stats must use accuracy, stamina, and time once each."
        } else {
            $seenSupportStats[$stat] = $true
        }
        if ([string]$goal.target -ne "all_tier_activities") {
            Add-Finding $errors "Tier support goals must target all_tier_activities so every tier remains attainable."
        }
        if (-not (Test-PositiveNumber $goal.amount)) {
            Add-Finding $errors "Tier support goal amounts must be positive."
        }
    }

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
            Add-Finding $warnings "Could not find $codeName in runtime progression scripts."
            continue
        }
        if ([math]::Abs($jsonValue - $codeValue) -gt 0.001) {
            Add-Finding $warnings "Global rule $jsonName is $jsonValue, but $codeName is $codeValue."
        }
    }
} else {
    Add-Finding $warnings "No global_rules block was found."
}

if ([string]::IsNullOrWhiteSpace($exportPresets)) {
    Add-Finding $warnings "Could not read export_presets.cfg; exported builds may omit docs\activity-database.json."
} else {
    $normalizedExportPresets = $exportPresets -replace "\\", "/"
    if ($normalizedExportPresets -notmatch "docs/activity-database\.json") {
        Add-Finding $errors "export_presets.cfg must include docs/activity-database.json so Godot builds use the source-of-truth activity data."
    }
}

if (-not [string]::IsNullOrWhiteSpace($mainScript)) {
    foreach ($token in @("SKILL_DEFS", "ACTION_FILES", "UNLOCK_LEVELS", "_fishing_area_definitions_fallback", "_background_for_action")) {
        if ($mainScript.Contains($token)) {
            Add-Finding $errors "scripts/main.gd still contains obsolete activity fallback token: $token."
        }
    }
    foreach ($token in @('"manual_activity_unlocks": manual_activity_unlocks', 'manual_activity_unlocks[_canonical_action_key')) {
        if ($mainScript.Contains($token)) {
            Add-Finding $errors "scripts/main.gd still contains obsolete raw manual unlock persistence token: $token."
        }
    }
    if ($mainScript -match '(?m)^\s*"mastery":\s*mastery,') {
        Add-Finding $errors 'scripts/main.gd still saves raw mastery instead of _mastery_for_save().'
    }
    if ($mainScript -match '(?m)^\s*"skills":\s*skills,') {
        Add-Finding $errors 'scripts/main.gd still saves raw skills instead of SkillState.skills_for_save().'
    }
    if ($mainScript -match '(?m)^\s*"stamina":\s*stamina,') {
        Add-Finding $errors 'scripts/main.gd still saves raw stamina instead of SkillState.stamina_for_save().'
    }
    if ($mainScript -match '(?m)^\s*"stamina_bank":\s*stamina_bank,') {
        Add-Finding $errors 'scripts/main.gd still saves raw stamina_bank instead of SkillState.stamina_bank_for_save().'
    }
    if ($mainScript -match '(?m)^\s*"selected_fishing_locations":\s*selected_fishing_locations,') {
        Add-Finding $errors 'scripts/main.gd still saves raw selected_fishing_locations instead of FishingState.save_payload().'
    }
    foreach ($rawFishingSave in @(
        @{ Pattern = '(?m)^\s*"equipped_fishing_tool_id":\s*equipped_fishing_tool_id,'; Helper = 'FishingState.save_payload()' },
        @{ Pattern = '(?m)^\s*"log_currency":\s*log_currency,'; Helper = '_log_currency_for_save()' },
        @{ Pattern = '(?m)^\s*"fish_currency":\s*fish_currency,'; Helper = '_fish_currency_for_save()' },
        @{ Pattern = '(?m)^\s*"fishing_net_stored_fish":\s*fishing_net_stored_fish,'; Helper = 'FishingState.save_payload()' },
        @{ Pattern = '(?m)^\s*"fishing_net_successes":\s*fishing_net_successes,'; Helper = 'FishingState.save_payload()' },
        @{ Pattern = '(?m)^\s*"fishing_net_stored_xp":\s*fishing_net_stored_xp,'; Helper = 'FishingState.save_payload()' },
        @{ Pattern = '(?m)^\s*"fishing_net_stored_mastery":\s*fishing_net_stored_mastery,'; Helper = 'FishingState.save_payload()' },
        @{ Pattern = '(?m)^\s*"fishing_boat_stored_fish":\s*fishing_boat_stored_fish,'; Helper = 'FishingState.save_payload()' },
        @{ Pattern = '(?m)^\s*"fishing_boat_successes":\s*fishing_boat_successes,'; Helper = 'FishingState.save_payload()' },
        @{ Pattern = '(?m)^\s*"fishing_boat_stored_xp":\s*fishing_boat_stored_xp,'; Helper = 'FishingState.save_payload()' },
        @{ Pattern = '(?m)^\s*"fishing_boat_stored_mastery":\s*fishing_boat_stored_mastery,'; Helper = 'FishingState.save_payload()' }
    )) {
        if ($mainScript -match $rawFishingSave.Pattern) {
            Add-Finding $errors "scripts/main.gd still saves raw fishing numeric state instead of $($rawFishingSave.Helper)."
        }
    }
    if ($mainScript -match '(?m)^\s*"fishing_net_collected":') {
        Add-Finding $errors 'scripts/main.gd should not save legacy fishing_net_collected; use fishing_net_collect_completed only.'
    }
    foreach ($rawRodSave in @(
        @{ Pattern = '(?m)^\s*"fishing_rod_collected":\s*fishing_rod_collected,'; Helper = 'FishingState.save_payload()' },
        @{ Pattern = '(?m)^\s*"fishing_reinforced_rod_collected":\s*fishing_reinforced_rod_collected,'; Helper = 'FishingState.save_payload()' },
        @{ Pattern = '(?m)^\s*"fishing_star_rod_collected":\s*fishing_star_rod_collected,'; Helper = 'FishingState.save_payload()' }
    )) {
        if ($mainScript -match $rawRodSave.Pattern) {
            Add-Finding $errors "scripts/main.gd still saves raw fishing rod collection state instead of $($rawRodSave.Helper)."
        }
    }
    foreach ($rawAudioSave in @(
        @{ Pattern = '(?m)^\s*"music_volume":\s*music_volume,'; Helper = '_music_volume_for_save()' },
        @{ Pattern = '(?m)^\s*"sfx_volume":\s*sfx_volume,'; Helper = '_sfx_volume_for_save()' }
    )) {
        if ($mainScript -match $rawAudioSave.Pattern) {
            Add-Finding $errors "scripts/main.gd still saves raw audio setting state instead of $($rawAudioSave.Helper)."
        }
    }
    if ($mainScript -match '(?m)^\s*"is_muted":') {
        Add-Finding $errors 'scripts/main.gd should not save obsolete global is_muted audio state.'
    }
    if ($mainScript -match '(?m)^\s*"god_mode_enabled":\s*god_mode_enabled,') {
        Add-Finding $errors 'scripts/main.gd still saves raw god_mode_enabled instead of _god_mode_enabled_for_save().'
    }
    if ($mainScript -match '(?m)^\s*"passive_modules":\s*passive_modules,') {
        Add-Finding $errors 'scripts/main.gd still saves raw passive_modules instead of PassiveModulesRuntime.for_save().'
    }
    if ($mainScript -match '(?m)^\s*"convergence_modules":\s*convergence_modules,') {
        Add-Finding $errors 'scripts/main.gd still saves raw convergence_modules instead of _convergence_modules_for_save().'
    }
    if ($mainScript -match '(?m)^\s*"hub_modules":\s*hub_modules,') {
        Add-Finding $errors 'Save payload still saves raw hub_modules instead of HubRuntime.modules_for_save().'
    }
    foreach ($rawScalarSave in @(
        @{ Pattern = '(?m)^\s*"hub_selected_module_id":\s*hub_selected_module_id,'; Helper = 'HubRuntime.selected_module_id_for_save()' },
        @{ Pattern = '(?m)^\s*"hub_mission_cooldown_until_unix":\s*hub_mission_cooldown_until_unix,'; Helper = '_hub_mission_cooldown_until_unix_for_save()' },
        @{ Pattern = '(?m)^\s*"plank_boost_enabled":\s*plank_boost_enabled,'; Helper = '_plank_boost_enabled_for_save()' },
        @{ Pattern = '(?m)^\s*"ad_bonus_seconds_remaining":\s*ad_bonus_seconds_remaining,'; Helper = '_ad_bonus_seconds_remaining_for_save()' },
        @{ Pattern = '(?m)^\s*"activity_start_count":\s*activity_start_count,'; Helper = '_activity_start_count_for_save()' },
        @{ Pattern = '(?m)^\s*"activity_completion_count":\s*activity_completion_count,'; Helper = '_activity_completion_count_for_save()' },
        @{ Pattern = '(?m)^\s*"guaranteed_success_action_completions":\s*guaranteed_success_action_completions,'; Helper = '_guaranteed_success_action_completions_for_save()' },
        @{ Pattern = '(?m)^\s*"onboarding_starter_action_completion_count":\s*onboarding_starter_action_completion_count,'; Helper = '_onboarding_starter_action_completion_count_for_save()' },
        @{ Pattern = '(?m)^\s*"stamina_gauge_pre_tip_hold_seconds":\s*stamina_gauge_pre_tip_hold_seconds,'; Helper = '_stamina_gauge_pre_tip_hold_seconds_for_save()' },
        @{ Pattern = '(?m)^\s*"flow_heat":\s*flow_heat,'; Helper = '_flow_heat_for_save()' },
        @{ Pattern = '(?m)^\s*"flow_active_action_seconds":\s*flow_active_action_seconds,'; Helper = '_flow_active_action_seconds_for_save()' }
    )) {
        if ($mainScript -match $rawScalarSave.Pattern) {
            Add-Finding $errors "scripts/main.gd still saves raw scalar progression metadata instead of $($rawScalarSave.Helper)."
        }
    }
    $hubSelectedRestoreMatches = [regex]::Matches($mainScript, '(?m)^\s*hub_selected_module_id = str\(data\.get\("hub_selected_module_id", hub_selected_module_id\)\)')
    if ($hubSelectedRestoreMatches.Count -gt 1) {
        Add-Finding $errors 'scripts/main.gd still restores raw hub_selected_module_id outside HubRuntime.restore_selected_module_id().'
    }
    $hubMissionCooldownRestoreMatches = [regex]::Matches($mainScript, '(?m)^\s*hub_mission_cooldown_until_unix = maxi\(0, int\(data\.get\("hub_mission_cooldown_until_unix", 0\)\)\)')
    if ($hubMissionCooldownRestoreMatches.Count -gt 1) {
        Add-Finding $errors 'scripts/main.gd still restores raw hub_mission_cooldown_until_unix outside HubRuntime.restore_mission_cooldown().'
    }
    $plankBoostRestoreMatches = [regex]::Matches($mainScript, '(?m)^\s*plank_boost_enabled = bool\(data\.get\("plank_boost_enabled", false\)\)')
    if ($plankBoostRestoreMatches.Count -gt 1) {
        Add-Finding $errors 'scripts/main.gd still restores raw plank_boost_enabled outside _restore_plank_boost_enabled_from_save().'
    }
    $adBonusRestoreMatches = [regex]::Matches($mainScript, '(?m)^\s*ad_bonus_seconds_remaining = clampf\(float\(data\.get\("ad_bonus_seconds_remaining", 0\.0\)\), 0\.0, float\(AdBonus\.AD_BONUS_MAX_SECONDS\)\)')
    if ($adBonusRestoreMatches.Count -gt 1) {
        Add-Finding $errors 'scripts/main.gd still restores raw ad_bonus_seconds_remaining outside AdBonus.restore_seconds_from_save().'
    }
    $activityStartRestoreMatches = [regex]::Matches($mainScript, '(?m)^\s*activity_start_count = maxi\(0, int\(data\.get\("activity_start_count", 0\)\)\)')
    if ($activityStartRestoreMatches.Count -gt 1) {
        Add-Finding $errors 'scripts/main.gd still restores raw activity progress counters outside _restore_activity_progress_counts_from_save().'
    }
    $guaranteedSuccessRestoreMatches = [regex]::Matches($mainScript, '(?m)^\s*guaranteed_success_action_completions = clampi\(')
    if ($guaranteedSuccessRestoreMatches.Count -gt 1) {
        Add-Finding $errors 'scripts/main.gd still restores raw guaranteed-success completions outside _restore_activity_progress_counts_from_save().'
    }
    $staminaTipHoldRestoreMatches = [regex]::Matches($mainScript, '(?m)^\s*stamina_gauge_pre_tip_hold_seconds = clampf\(float\(data\.get\("stamina_gauge_pre_tip_hold_seconds", 0\.0\)\), 0\.0, STAMINA_TIP_DISCOVERY_HOLD_SECONDS\)')
    if ($staminaTipHoldRestoreMatches.Count -gt 1) {
        Add-Finding $errors 'scripts/main.gd still restores raw stamina_gauge_pre_tip_hold_seconds outside _restore_stamina_gauge_pre_tip_hold_seconds_from_save().'
    }
    $flowHeatRestoreMatches = [regex]::Matches($mainScript, '(?m)^\s*flow_heat = clampf\(float\(data\.get\("flow_heat", flow_heat\)\), 0\.0, 36\.0\)')
    if ($flowHeatRestoreMatches.Count -gt 1) {
        Add-Finding $errors 'scripts/main.gd still restores raw music flow state outside AudioDirector.'
    }
    $flowActiveSecondsRestoreMatches = [regex]::Matches($mainScript, '(?m)^\s*flow_active_action_seconds = maxf\(0\.0, float\(data\.get\("flow_active_action_seconds", flow_active_action_seconds\)\)\)')
    if ($flowActiveSecondsRestoreMatches.Count -gt 1) {
        Add-Finding $errors 'scripts/main.gd still restores raw music flow active seconds outside AudioDirector.'
    }
    if ($mainScript -match '(?m)^\s*"hub_decor_layout":\s*hub_decor_layout,') {
        Add-Finding $errors 'scripts/main.gd still saves raw hub_decor_layout instead of _hub_decor_layout_for_save().'
    }
    if ($mainScript -match '(?m)^\s*"hub_module_positions":\s*hub_module_positions,') {
        Add-Finding $errors 'scripts/main.gd still saves raw hub_module_positions instead of HubSurface serialization.'
    }
    if ($mainScript -match '(?m)^\s*"achievement_toast_seen_ids":\s*achievement_toast_seen_ids,') {
        Add-Finding $errors 'scripts/main.gd still saves raw achievement_toast_seen_ids instead of _achievement_toast_seen_ids_for_save().'
    }
    $activityCritRestoreMatches = [regex]::Matches($mainScript, '(?m)^\s*activity_crit_seen = bool\(data\.get\("activity_crit_seen", false\)\)')
    if ($activityCritRestoreMatches.Count -gt 1) {
        Add-Finding $errors 'scripts/main.gd still restores raw activity crit metadata outside _restore_activity_crit_metadata_from_save().'
    }
    $activityStartTipRestoreMatches = [regex]::Matches($mainScript, '(?m)^\s*activity_start_tip_seen = bool\(data\.get\("activity_start_tip_seen", false\)\)')
    if ($activityStartTipRestoreMatches.Count -gt 1) {
        Add-Finding $errors 'scripts/main.gd still restores raw boot-visible tip flags outside _restore_boot_visible_tip_flags_from_save().'
    }
    $hubTutorialTipRestoreMatches = [regex]::Matches($mainScript, '(?m)^\s*hub_tutorial_tip_seen = bool\(data\.get\("hub_tutorial_tip_seen", false\)\)')
    if ($hubTutorialTipRestoreMatches.Count -gt 1) {
        Add-Finding $errors 'scripts/main.gd still restores raw hub tutorial tip state outside _restore_boot_visible_tip_flags_from_save().'
    }
    if ($mainScript -match '(?m)^\s*"thieving_action_jails":\s*thieving_action_jails,') {
        Add-Finding $errors 'scripts/main.gd still saves raw thieving_action_jails instead of ThievingState.action_jails_for_save().'
    }
    if ($mainScript -match '(?m)^\s*"thieving_trophies":\s*thieving_trophies,') {
        Add-Finding $errors 'scripts/main.gd still saves raw thieving_trophies instead of ThievingState.trophies_for_save().'
    }
    if ($mainScript -match '(?m)^\s*"hub_missions":\s*hub_missions,') {
        Add-Finding $errors 'Save payload still saves raw hub_missions instead of HubRuntime.missions_for_save().'
    }
    if ($mainScript -match '(?m)^\s*"leaderboard_last_submitted_scores_by_category":\s*leaderboard_last_submitted_scores_by_category,') {
        Add-Finding $errors 'scripts/main.gd still saves raw leaderboard category scores instead of LeaderboardState serialization.'
    }
    $leaderboardScoreRestoreMatches = [regex]::Matches($mainScript, '(?m)^\s*leaderboard_last_submitted_score = maxi\(0, int\(data\.get\("leaderboard_last_submitted_score", 0\)\)\)')
    if ($leaderboardScoreRestoreMatches.Count -gt 1) {
        Add-Finding $errors 'scripts/main.gd still restores raw leaderboard submission metadata outside LeaderboardState.'
    }
    if ($mainScript.Contains('var submitted_scores = data.get("leaderboard_last_submitted_scores_by_category", {})')) {
        Add-Finding $errors 'scripts/main.gd still restores raw leaderboard category scores outside LeaderboardState.'
    }
    foreach ($rawLeaderboardSave in @(
        @{ Pattern = '(?m)^\s*"leaderboard_last_submitted_score":\s*leaderboard_last_submitted_score,'; Helper = '_leaderboard_last_submitted_score_for_save()' },
        @{ Pattern = '(?m)^\s*"leaderboard_last_submitted_total_xp":\s*leaderboard_last_submitted_total_xp,'; Helper = '_leaderboard_last_submitted_total_xp_for_save()' },
        @{ Pattern = '(?m)^\s*"leaderboard_last_submit_unix":\s*leaderboard_last_submit_unix,'; Helper = '_leaderboard_last_submit_unix_for_save()' },
        @{ Pattern = '(?m)^\s*"leaderboard_display_name":\s*leaderboard_display_name,'; Helper = 'LeaderboardProfile.display_name_for_save()' },
        @{ Pattern = '(?m)^\s*"leaderboard_name_key":\s*leaderboard_name_key,'; Helper = 'LeaderboardProfile.name_key_for_save()' },
        @{ Pattern = '(?m)^\s*"leaderboard_avatar_index":\s*leaderboard_avatar_index,'; Helper = 'LeaderboardProfile.avatar_index_for_save()' },
        @{ Pattern = '(?m)^\s*"leaderboard_profile_claimed":\s*leaderboard_profile_claimed,'; Helper = 'LeaderboardProfile.profile_claimed_for_save()' },
        @{ Pattern = '(?m)^\s*"leaderboard_name_claim_verified":\s*leaderboard_name_claim_verified,'; Helper = 'LeaderboardProfile.name_claim_verified_for_save()' },
        @{ Pattern = '(?m)^\s*"leaderboard_player_id":\s*leaderboard_player_id,'; Helper = 'LeaderboardProfile.player_id_for_save()' },
        @{ Pattern = '(?m)^\s*"leaderboard_auth_refresh_token":\s*leaderboard_auth_refresh_token,'; Helper = 'LeaderboardProfile.auth_refresh_token_for_save()' },
        @{ Pattern = '(?m)^\s*"leaderboard_auth_retry_after_unix":\s*leaderboard_auth_retry_after_unix,'; Helper = '_leaderboard_auth_retry_after_unix_for_save()' },
        @{ Pattern = '(?m)^\s*"leaderboard_fetch_retry_unix_by_category":\s*leaderboard_fetch_retry_unix_by_category,'; Helper = 'LeaderboardState fetch retry serialization' }
    )) {
        if ($mainScript -match $rawLeaderboardSave.Pattern) {
            Add-Finding $errors "scripts/main.gd still saves raw leaderboard metadata instead of $($rawLeaderboardSave.Helper)."
        }
    }
    $leaderboardProfileDisplayRestoreMatches = [regex]::Matches($mainScript, '(?m)^\s*leaderboard_display_name = _sanitize_leaderboard_display_name\(str\(data\.get\("leaderboard_display_name", leaderboard_display_name\)\)\)')
    if ($leaderboardProfileDisplayRestoreMatches.Count -gt 1) {
        Add-Finding $errors 'scripts/main.gd still restores raw leaderboard profile metadata instead of LeaderboardProfile.restore_profile_metadata_from_save().'
    }
    $leaderboardProfileClaimRestoreMatches = [regex]::Matches($mainScript, '(?m)^\s*leaderboard_profile_claimed = bool\(data\.get\("leaderboard_profile_claimed", false\)\)')
    if ($leaderboardProfileClaimRestoreMatches.Count -gt 1) {
        Add-Finding $errors 'scripts/main.gd still restores raw leaderboard profile claim state instead of LeaderboardProfile.restore_profile_metadata_from_save().'
    }
    $leaderboardAvatarRestoreMatches = [regex]::Matches($mainScript, '(?m)^\s*leaderboard_avatar_index = _valid_profile_avatar_index\(int\(data\.get\("leaderboard_avatar_index", leaderboard_avatar_index\)\)\)')
    if ($leaderboardAvatarRestoreMatches.Count -gt 1) {
        Add-Finding $errors 'scripts/main.gd still restores raw leaderboard avatar indexes outside LeaderboardProfile.restore_profile_metadata_from_save().'
    }
    $leaderboardPlayerIdRestoreMatches = [regex]::Matches($mainScript, '(?m)^\s*leaderboard_player_id = _sanitize_leaderboard_player_id\(str\(data\.get\("leaderboard_player_id", leaderboard_player_id\)\)\)')
    if ($leaderboardPlayerIdRestoreMatches.Count -gt 1) {
        Add-Finding $errors 'scripts/main.gd still restores raw leaderboard player ids outside LeaderboardProfile.restore_profile_metadata_from_save().'
    }
    if ($mainScript -match '(?m)^\s*"chat_stream_retry_unix":\s*chat_stream_retry_unix,') {
        Add-Finding $errors 'scripts/main.gd still saves raw chat_stream_retry_unix instead of ChatState.metadata_for_save().'
    }
    if ($mainScript -match '(?m)^\s*"chat_stream_next_connect_unix":\s*chat_stream_next_connect_unix,') {
        Add-Finding $errors 'scripts/main.gd still saves raw chat_stream_next_connect_unix instead of ChatState.metadata_for_save().'
    }
    $chatLastSendRestoreMatches = [regex]::Matches($mainScript, '(?m)^\s*chat_last_send_unix = maxi\(0, int\(data\.get\("chat_last_send_unix", 0\)\)\)')
    if ($chatLastSendRestoreMatches.Count -gt 1) {
        Add-Finding $errors 'scripts/main.gd still restores raw chat_last_send_unix outside ChatState.restore_metadata_to_host().'
    }
    $chatStreamRetryRestoreMatches = [regex]::Matches($mainScript, '(?m)^\s*chat_stream_retry_unix = mini\(maxi\(0, int\(data\.get\("chat_stream_retry_unix", data\.get\("chat_fetch_retry_unix", 0\)\)\)\), max_chat_retry_unix\)')
    if ($chatStreamRetryRestoreMatches.Count -gt 1) {
        Add-Finding $errors 'scripts/main.gd still restores raw chat_stream_retry_unix outside ChatState.restore_metadata_to_host().'
    }
    $chatStreamNextConnectRestoreMatches = [regex]::Matches($mainScript, '(?m)^\s*chat_stream_next_connect_unix = mini\(maxi\(chat_stream_retry_unix, int\(data\.get\("chat_stream_next_connect_unix", 0\)\)\), max_chat_retry_unix\)')
    if ($chatStreamNextConnectRestoreMatches.Count -gt 1) {
        Add-Finding $errors 'scripts/main.gd still restores raw chat_stream_next_connect_unix outside ChatState.restore_metadata_to_host().'
    }
    if ($mainScript -match '(?m)^\s*"chat_last_opened_created_at":\s*chat_last_opened_created_at,') {
        Add-Finding $errors 'scripts/main.gd still saves raw chat_last_opened_created_at instead of ChatState.metadata_for_save().'
    }
    if ($mainScript -match '(?m)^\s*"chat_last_opened_message_id":\s*chat_last_opened_message_id,') {
        Add-Finding $errors 'scripts/main.gd still saves raw chat_last_opened_message_id instead of ChatState.metadata_for_save().'
    }
    $chatOpenedCreatedAtRestoreMatches = [regex]::Matches($mainScript, '(?m)^\s*chat_last_opened_created_at = maxi\(0, int\(data\.get\("chat_last_opened_created_at", 0\)\)\)')
    if ($chatOpenedCreatedAtRestoreMatches.Count -gt 1) {
        Add-Finding $errors 'scripts/main.gd still restores raw chat_last_opened_created_at outside ChatState.restore_metadata_to_host().'
    }
    if ($mainScript -match '(?m)^\s*chat_last_opened_message_id = str\(data\.get\("chat_last_opened_message_id", ""\)\)\.strip_edges\(\)') {
        Add-Finding $errors 'scripts/main.gd still restores raw chat_last_opened_message_id outside ChatState.restore_metadata_to_host().'
    }
    if ($mainScript.Contains('var loaded_thieving_action_jails = data.get("thieving_action_jails", {})')) {
        Add-Finding $errors 'scripts/main.gd still restores raw thieving_action_jails instead of ThievingState.restore_action_jails().'
    }
    if ($mainScript.Contains('var loaded_thieving_trophies = data.get("thieving_trophies", {})')) {
        Add-Finding $errors 'scripts/main.gd still restores raw thieving_trophies instead of _restore_thieving_trophies_from_save().'
    }
    if ($mainScript.Contains('var loaded_convergence_modules = data.get("convergence_modules", {})')) {
        Add-Finding $errors 'scripts/main.gd still restores raw convergence_modules instead of _restore_convergence_modules_from_save().'
    }
    if ($mainScript.Contains('var loaded_hub_modules = data.get("hub_modules", {})')) {
        Add-Finding $errors 'scripts/main.gd still restores raw hub_modules instead of HubRuntime.restore_modules().'
    }
    if ($mainScript.Contains('var saved_fetch_retry_unix = data.get("leaderboard_fetch_retry_unix_by_category", {})')) {
        Add-Finding $errors 'scripts/main.gd still restores raw leaderboard_fetch_retry_unix_by_category instead of LeaderboardState.'
    }
    $leaderboardFetchSuccessClearMatches = [regex]::Matches($mainScript, '(?m)^\s*leaderboard_fetch_unix_by_category\.clear\(\)')
    if ($leaderboardFetchSuccessClearMatches.Count -gt 2) {
        Add-Finding $errors 'scripts/main.gd still clears leaderboard successful fetch timestamps outside LeaderboardState and reset paths.'
    }
    if ($mainScript.Contains('var loaded_seen = data.get("achievement_toast_seen_ids", {})')) {
        Add-Finding $errors 'scripts/main.gd still restores raw achievement_toast_seen_ids instead of _normalized_achievement_toast_seen_ids().'
    }
    if ($mainScript.Contains('hub_module_positions.clear()') -and -not $hubSurfaceScript.Contains('func _normalized_hub_module_positions(raw_positions: Variant) -> Dictionary:')) {
        Add-Finding $errors 'scripts/main.gd restores hub_module_positions inline instead of HubSurface._normalized_hub_module_positions().'
    }
    if ($mainScript.Contains('hub_decor_layout.clear()') -and -not $hubSurfaceScript.Contains('func _normalized_hub_decor_layout(raw_layout: Variant) -> Array:')) {
        Add-Finding $errors 'scripts/main.gd restores hub_decor_layout inline instead of HubSurface._normalized_hub_decor_layout().'
    }
    if ($mainScript.Contains('var loaded_hub_missions = data.get("hub_missions", [])')) {
        Add-Finding $errors 'scripts/main.gd still restores raw hub_missions instead of HubRuntime.restore_missions().'
    }
    if ($mainScript -match '(?m)^\s*"running_action_id":\s*running_action_id,') {
        Add-Finding $errors 'scripts/main.gd still saves raw running_action_id instead of _running_action_id_for_save().'
    }
    if ($mainScript -match '(?m)^\s*"selected_skill_id":\s*selected_skill_id,') {
        Add-Finding $errors 'scripts/main.gd still saves raw selected_skill_id instead of _selected_skill_id_for_save().'
    }
    if ($mainScript -match '(?m)^\s*"running_skill_id":\s*running_skill_id,') {
        Add-Finding $errors 'scripts/main.gd still saves raw running_skill_id instead of _running_skill_id_for_save().'
    }
    if ($mainScript -match '(?m)^\s*"action_progress":\s*action_progress,') {
        Add-Finding $errors 'scripts/main.gd still saves raw action_progress instead of _action_progress_for_save().'
    }
    if ($mainScript.Contains('action_progress = float(data.get("action_progress", 0.0))')) {
        Add-Finding $errors 'scripts/main.gd still restores raw action_progress instead of _normalized_action_progress().'
    }
    if ($mainScript -match '(?m)^\s*"silver_opportunity_tip_action_key":\s*silver_opportunity_tip_action_key,') {
        Add-Finding $errors 'scripts/main.gd still saves raw silver_opportunity_tip_action_key instead of _action_key_for_save().'
    }
    $lockClickTipRestoreMatches = [regex]::Matches($mainScript, '(?m)^\s*lock_click_tip_seen = bool\(data\.get\("lock_click_tip_seen", false\)\)')
    if ($lockClickTipRestoreMatches.Count -gt 1) {
        Add-Finding $errors 'scripts/main.gd still restores raw tip metadata outside SaveRuntime tip metadata restore.'
    }
    $silverTipActionRestoreMatches = [regex]::Matches($mainScript, '(?m)^\s*silver_opportunity_tip_action_key = _action_key_for_save\(str\(data\.get\("silver_opportunity_tip_action_key", ""\)\)\)')
    if ($silverTipActionRestoreMatches.Count -gt 1) {
        Add-Finding $errors 'scripts/main.gd still restores raw silver opportunity action keys outside SaveRuntime tip metadata restore.'
    }
    $leaderboardAuthRefreshRestoreMatches = [regex]::Matches($mainScript, '(?m)^\s*leaderboard_auth_refresh_token = str\(data\.get\("leaderboard_auth_refresh_token", ""\)\)\.strip_edges\(\)')
    if ($leaderboardAuthRefreshRestoreMatches.Count -gt 1) {
        Add-Finding $errors 'scripts/main.gd still restores raw leaderboard auth metadata instead of LeaderboardProfile.restore_auth_metadata_from_save().'
    }
    $leaderboardAuthRetryRestoreMatches = [regex]::Matches($mainScript, '(?m)^\s*leaderboard_auth_retry_after_unix = maxi\(0, int\(data\.get\("leaderboard_auth_retry_after_unix", 0\)\)\)')
    if ($leaderboardAuthRetryRestoreMatches.Count -gt 1) {
        Add-Finding $errors 'scripts/main.gd still restores raw leaderboard auth retry state instead of LeaderboardProfile.restore_auth_metadata_from_save().'
    }
    foreach ($token in @('var loaded_mastery = data.get("mastery", {})')) {
        if ($mainScript.Contains($token)) {
            Add-Finding $errors "scripts/main.gd still contains obsolete raw mastery restore token: $token."
        }
    }
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
Write-Output ("Skills: {0}; actions: {1}; combo modules: {2}; event modules: {3}; event combos: {4}; passive modules: {5}; requirement entries: {6}; reward maps: {7}; missing assets: {8}" -f $skills.Count, $actionCount, $comboActionCount, $eventModuleCount, $eventComboCount, $passiveCount, $requirementEntryCount, $rewardMapCount, $missingAssets)
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
