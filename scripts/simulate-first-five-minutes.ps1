param(
    [int] $DurationSeconds = 300,
    [ValidateSet("CurrentTiredTraining", "WaitForStamina")]
    [string] $StaminaMode = "CurrentTiredTraining"
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$databasePath = Join-Path $projectRoot "docs\activity-database.json"

if (-not (Test-Path -LiteralPath $databasePath)) {
    throw "Activity database was not found at $databasePath"
}

$database = Get-Content -LiteralPath $databasePath -Raw | ConvertFrom-Json
$baseMaxStamina = [double]$database.global_rules.base_max_stamina
$regenSeconds = [double]$database.global_rules.stamina_regen_seconds
$lowStaminaSpeedMultiplier = 0.20

function Get-XpForLevel {
    param([int] $Level)

    if ($Level -le 1) {
        return 0
    }
    return [int][math]::Round(22.0 * [math]::Pow(($Level - 1), 2.08))
}

function Get-LevelForXp {
    param([double] $Xp)

    $level = 1
    while ($level -lt 99 -and $Xp -ge (Get-XpForLevel ($level + 1))) {
        $level++
    }
    return $level
}

function Get-UnlockedActions {
    param(
        [object] $Skill,
        [int] $Level
    )

    @($Skill.actions) | Where-Object {
        $kind = [string]$_.kind
        ([string]::IsNullOrWhiteSpace($kind) -or $kind -ne "passive_item_collect") -and [int]$_.unlock -le $Level
    }
}

function Get-BestAction {
    param(
        [object] $Skill,
        [int] $Level
    )

    $actions = @(Get-UnlockedActions $Skill $Level)
    if ($actions.Count -eq 0) {
        return $null
    }
    return $actions | Sort-Object @{ Expression = { [int]$_.unlock }; Descending = $true }, @{ Expression = { [double]$_.xp }; Descending = $true } | Select-Object -First 1
}

function New-SimState {
    $state = @{
        Time = 0.0
        Skills = @{}
        ActiveSkillId = ""
        ActiveActionId = ""
        ActionProgress = 0.0
        Completions = 0
        Switches = 0
        Events = New-Object System.Collections.Generic.List[string]
    }

    foreach ($skill in @($database.skills)) {
        $state.Skills[[string]$skill.id] = @{
            Xp = 0.0
            Level = 1
            Stamina = $baseMaxStamina
            Completions = 0
            XpEarned = 0.0
        }
    }
    return $state
}

function Set-ActiveSkill {
    param(
        [hashtable] $State,
        [string] $SkillId,
        [object] $Action
    )

    if ($State.ActiveSkillId -ne "" -and $State.ActiveSkillId -ne $SkillId) {
        $State.Switches++
    }
    $State.ActiveSkillId = $SkillId
    $State.ActiveActionId = [string]$Action.id
    $State.ActionProgress = 0.0
}

function Add-SimEvent {
    param(
        [hashtable] $State,
        [string] $Message
    )

    if ($State.Events.Count -lt 14) {
        $State.Events.Add(("{0,4}s  {1}" -f [int][math]::Floor($State.Time), $Message)) | Out-Null
    }
}

function Choose-Action {
    param(
        [hashtable] $State,
        [string] $Strategy
    )

    $skills = @($database.skills)

    if ($Strategy -eq "StayFight") {
        $skill = $skills | Where-Object { $_.id -eq "fight" } | Select-Object -First 1
        return @{ Skill = $skill; Action = Get-BestAction $skill $State.Skills["fight"].Level }
    }

    if ($Strategy -eq "BalancedTour") {
        $sorted = $skills | Sort-Object {
            $skillState = $State.Skills[[string]$_.id]
            [int]$skillState.Completions
        }, {
            [string]$_.id
        }
        foreach ($skill in $sorted) {
            $skillState = $State.Skills[[string]$skill.id]
            $action = Get-BestAction $skill $skillState.Level
            if ($null -ne $action) {
                return @{ Skill = $skill; Action = $action }
            }
        }
    }

    if ($Strategy -eq "RotateLowStamina") {
        $currentIndex = 0
        for ($i = 0; $i -lt $skills.Count; $i++) {
            if ([string]$skills[$i].id -eq $State.ActiveSkillId) {
                $currentIndex = $i
                break
            }
        }
        for ($offset = 0; $offset -lt $skills.Count; $offset++) {
            $skill = $skills[($currentIndex + $offset) % $skills.Count]
            $skillState = $State.Skills[[string]$skill.id]
            $action = Get-BestAction $skill $skillState.Level
            if ($null -ne $action -and [double]$skillState.Stamina + 0.0001 -ge [double]$action.stamina) {
                return @{ Skill = $skill; Action = $action }
            }
        }
    }

    if ($Strategy -eq "ChaseNewestUnlock") {
        $best = $null
        foreach ($skill in $skills) {
            $skillState = $State.Skills[[string]$skill.id]
            $action = Get-BestAction $skill $skillState.Level
            if ($null -eq $action) {
                continue
            }
            $candidate = @{
                Skill = $skill
                Action = $action
                Unlock = [int]$action.unlock
                Xp = [double]$action.xp
            }
            if ($null -eq $best -or $candidate.Unlock -gt $best.Unlock -or ($candidate.Unlock -eq $best.Unlock -and $candidate.Xp -gt $best.Xp)) {
                $best = $candidate
            }
        }
        if ($null -ne $best) {
            return @{ Skill = $best.Skill; Action = $best.Action }
        }
    }

    $fallbackSkill = $skills[0]
    return @{ Skill = $fallbackSkill; Action = Get-BestAction $fallbackSkill $State.Skills[[string]$fallbackSkill.id].Level }
}

function Invoke-Simulation {
    param([string] $Strategy)

    $state = New-SimState
    $choice = Choose-Action $state $Strategy
    Set-ActiveSkill $state ([string]$choice["Skill"].id) $choice["Action"]
    Add-SimEvent $state ("started {0}/{1}" -f $choice["Skill"].id, $choice["Action"].name)

    while ($state.Time -lt $DurationSeconds) {
        $delta = 1.0
        foreach ($skill in @($database.skills)) {
            $skillState = $state.Skills[[string]$skill.id]
            $skillState.Stamina = [math]::Min($baseMaxStamina, [double]$skillState.Stamina + ($delta / $regenSeconds))
        }

        $activeSkill = @($database.skills) | Where-Object { $_.id -eq $state.ActiveSkillId } | Select-Object -First 1
        $activeState = $state.Skills[$state.ActiveSkillId]
        $activeAction = @($activeSkill.actions) | Where-Object { $_.id -eq $state.ActiveActionId } | Select-Object -First 1

        if ($null -eq $activeAction) {
            $choice = Choose-Action $state $Strategy
            Set-ActiveSkill $state ([string]$choice["Skill"].id) $choice["Action"]
            $activeSkill = $choice["Skill"]
            $activeAction = $choice["Action"]
            $activeState = $state.Skills[[string]$activeSkill.id]
        }

        $hasStamina = [double]$activeState.Stamina + 0.0001 -ge [double]$activeAction.stamina
        if (-not $hasStamina -and $StaminaMode -eq "WaitForStamina") {
            $choice = Choose-Action $state $Strategy
            if ([string]$choice["Skill"].id -ne $state.ActiveSkillId -or [string]$choice["Action"].id -ne $state.ActiveActionId) {
                Set-ActiveSkill $state ([string]$choice["Skill"].id) $choice["Action"]
                Add-SimEvent $state ("switched to {0}/{1}" -f $choice["Skill"].id, $choice["Action"].name)
            }
            $state.Time += $delta
            continue
        }

        $speed = 1.0
        if (-not $hasStamina) {
            $speed = $lowStaminaSpeedMultiplier
        }
        $state.ActionProgress += $delta / [double]$activeAction.seconds * $speed
        $state.Time += $delta

        if ($state.ActionProgress -lt 1.0) {
            continue
        }

        $state.ActionProgress = 0.0
        if ([double]$activeState.Stamina + 0.0001 -ge [double]$activeAction.stamina) {
            $activeState.Stamina = [math]::Max(0.0, [double]$activeState.Stamina - [double]$activeAction.stamina)
        }

        $expectedXp = [double]$activeAction.xp * ([double]$activeAction.success / 100.0)
        $oldLevel = [int]$activeState.Level
        $activeState.Xp += $expectedXp
        $activeState.XpEarned += $expectedXp
        $activeState.Completions++
        $state.Completions++
        $activeState.Level = Get-LevelForXp $activeState.Xp

        if ([int]$activeState.Level -gt $oldLevel) {
            Add-SimEvent $state ("{0} reached Lv {1}" -f $activeSkill.id, $activeState.Level)
        }

        $choice = Choose-Action $state $Strategy
        if ([string]$choice["Skill"].id -ne $state.ActiveSkillId -or [string]$choice["Action"].id -ne $state.ActiveActionId) {
            Set-ActiveSkill $state ([string]$choice["Skill"].id) $choice["Action"]
            Add-SimEvent $state ("switched to {0}/{1}" -f $choice["Skill"].id, $choice["Action"].name)
        }
    }

    return $state
}

$strategies = @("StayFight", "RotateLowStamina", "BalancedTour", "ChaseNewestUnlock")

Write-Output "First five minutes simulator"
Write-Output "Duration: $DurationSeconds seconds"
Write-Output "Stamina mode: $StaminaMode"
Write-Output "Model: expected XP from success chance; crits, streak XP, mastery, ads, and global medal buffs are not modeled yet."
Write-Output ""

foreach ($strategy in $strategies) {
    $result = Invoke-Simulation $strategy
    $leveledSkills = 0
    $totalLevels = 0
    $skillLines = New-Object System.Collections.Generic.List[string]

    foreach ($skill in @($database.skills)) {
        $skillState = $result.Skills[[string]$skill.id]
        if ([int]$skillState.Level -gt 1) {
            $leveledSkills++
        }
        $totalLevels += [int]$skillState.Level
        $skillLines.Add(("{0} Lv {1} ({2:n1} XP, {3:n1} stamina)" -f $skill.id, $skillState.Level, $skillState.Xp, $skillState.Stamina)) | Out-Null
    }

    Write-Output $strategy
    Write-Output ("  completions: {0}; switches: {1}; leveled skills: {2}; global level: {3}" -f $result.Completions, $result.Switches, $leveledSkills, $totalLevels)
    Write-Output ("  skills: {0}" -f ($skillLines -join "; "))
    if ($result.Events.Count -gt 0) {
        Write-Output "  events:"
        foreach ($eventText in $result.Events) {
            Write-Output "    $eventText"
        }
    }
    Write-Output ""
}
