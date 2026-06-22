param(
    [switch]$Check
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$activityDatabasePath = Join-Path $projectRoot "docs\activity-database.json"
$rulesPath = Join-Path $projectRoot "firebase-realtime-database.rules.json"

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function New-CategoryExpression {
    param([Parameter(Mandatory = $true)][string[]]$CategoryKeys)

    $parts = @($CategoryKeys | ForEach-Object { "`$category == '$_'" })
    return "(" + ($parts -join " || ") + ")"
}

function Assert-ValidCategoryKey {
    param([Parameter(Mandatory = $true)][string]$CategoryKey)

    Assert-True ($CategoryKey -match '^[a-z0-9_-]+$') "Invalid leaderboard category key '$CategoryKey'. Use only lowercase letters, numbers, underscores, and hyphens."
}

Assert-True (Test-Path -LiteralPath $activityDatabasePath) "Missing docs\activity-database.json"

$activityDatabase = Get-Content -LiteralPath $activityDatabasePath -Raw | ConvertFrom-Json
$skillIds = @($activityDatabase.skills | ForEach-Object { $_.id } | Where-Object { $_ })
Assert-True ($skillIds.Count -gt 0) "Activity database must define leaderboard skill categories."
foreach ($skillId in $skillIds) {
    Assert-True ($skillId -match '^[a-z0-9_-]+$') "Invalid activity skill id '$skillId' for leaderboard category generation. Use only lowercase letters, numbers, underscores, and hyphens."
}

$categoryKeys = @("total_level") + @($skillIds | ForEach-Object { "skill_xp__$_" }) + @("medals_earned", "elite_heavenly")
$duplicateCategoryKeys = @($categoryKeys | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
Assert-True ($duplicateCategoryKeys.Count -eq 0) "Leaderboard category keys must be unique: $($duplicateCategoryKeys -join ', ')"
foreach ($categoryKey in $categoryKeys) {
    Assert-ValidCategoryKey -CategoryKey $categoryKey
}
$categoryExpression = New-CategoryExpression -CategoryKeys $categoryKeys

$freshClientTimestampRule = "newData.isNumber() && newData.val() >= now - 10000 && newData.val() <= now + 60000"
$freshGateTimestampExpr = "{0}.isNumber() && {0}.val() >= now - 10000 && {0}.val() <= now + 60000"
$leaderboardWriterRule = "((auth != null && auth.uid == `$playerId) || auth == null)"
$nameClaimWriterRule = "((auth != null && newData.child('uid').val() == auth.uid && (!data.exists() || data.child('uid').val() == auth.uid)) || (auth == null && newData.child('uid').isString() && newData.child('uid').val().length >= 8 && newData.child('uid').val().length <= 48 && (!data.exists() || data.child('uid').val() == newData.child('uid').val())))"
$leaderboardNameClaimRule = "root.child('leaderboards').child('v1').child('name_claims').child(newData.child('name_key').val()).child('uid').val() == `$playerId"
$leaderboardFreshGateRule = "root.child('leaderboards').child('v1').child('player_write_gates').child(`$playerId).child('updated_at').isNumber() && root.child('leaderboards').child('v1').child('player_write_gates').child(`$playerId).child('updated_at').val() >= now - 10000 && root.child('leaderboards').child('v1').child('player_write_gates').child(`$playerId).child('updated_at').val() <= now + 60000"
$leaderboardLegacyRowCooldownRule = "newData.child('updated_at').isNumber() && newData.child('updated_at').val() >= now - 10000 && newData.child('updated_at').val() <= now + 60000 && (!data.exists() || now - data.child('updated_at').val() >= 900000)"
$leaderboardLegacyTotalLevelScoreRule = "`$category == 'total_level' && data.exists() && data.child('score').isNumber() && data.child('score').val() > 999 && newData.parent().child('total_xp').isNumber() && newData.parent().child('total_xp').val() >= data.child('score').val()"
$chatSenderRule = "newData.child('sender_id').isString() && newData.child('sender_id').val().length >= 8 && newData.child('sender_id').val().length <= 48 && (auth == null || newData.child('sender_id').val() == auth.uid)"
$chatFreshGateRule = "newData.parent().parent().child('user_write_gates').child(newData.child('sender_id').val()).child('updated_at').isNumber() && newData.parent().parent().child('user_write_gates').child(newData.child('sender_id').val()).child('updated_at').val() >= now - 10000 && newData.parent().parent().child('user_write_gates').child(newData.child('sender_id').val()).child('updated_at').val() <= now + 60000"
$chatClaimedNameRule = "newData.child('name_key').isString() && root.child('leaderboards').child('v1').child('name_claims').child(newData.child('name_key').val()).child('uid').val() == newData.child('sender_id').val()"
$chatGuestNameRule = "!newData.child('name_key').exists() && newData.child('name').isString() && newData.child('name').val().matches(/^guest[0-9]{4}$/)"
$chatCreateRule = "newData.exists() && !data.exists() && $chatSenderRule && ($chatClaimedNameRule || $chatGuestNameRule) && `$messageId.length >= 8 && `$messageId.length <= 64 && $chatFreshGateRule"
$chatOwnerRefreshRule = "data.exists() && newData.exists() && data.child('sender_id').val() == newData.child('sender_id').val() && (auth == null || data.child('sender_id').val() == auth.uid) && $chatClaimedNameRule && newData.child('sender_id').val() == data.child('sender_id').val() && newData.child('text').val() == data.child('text').val() && newData.child('created_at').val() == data.child('created_at').val() && newData.child('created_at_unix').val() == data.child('created_at_unix').val() && newData.child('deleted').val() == data.child('deleted').val() && newData.child('deleted_at').val() == data.child('deleted_at').val() && newData.child('deleted_by').val() == data.child('deleted_by').val()"
$chatModerationRule = "data.exists() && newData.exists() && auth.token.moderator == true && newData.child('sender_id').val() == data.child('sender_id').val() && newData.child('name').val() == data.child('name').val() && newData.child('name_key').val() == data.child('name_key').val() && newData.child('total_level').val() == data.child('total_level').val() && newData.child('avatar_index').val() == data.child('avatar_index').val() && newData.child('text').val() == data.child('text').val() && newData.child('created_at').val() == data.child('created_at').val() && newData.child('created_at_unix').val() == data.child('created_at_unix').val() && newData.child('deleted').val() == true && newData.child('deleted_at').val() == now && newData.child('deleted_by').val() == auth.uid"

$rulesObject = [ordered]@{
    rules = [ordered]@{
        ".read" = $false
        ".write" = $false
        leaderboards = [ordered]@{
            v1 = [ordered]@{
                ".read" = $false
                ".write" = $false
                name_claims = [ordered]@{
                    '$nameKey' = [ordered]@{
                        ".read" = $false
                        ".write" = "newData.exists() && `$nameKey.length > 0 && `$nameKey.length <= 16 && newData.child('name_key').val() == `$nameKey && $nameClaimWriterRule"
                        ".validate" = "newData.hasChildren(['uid', 'name', 'name_key', 'avatar_index', 'created_at', 'updated_at', 'submitted_at_unix'])"
                        uid = [ordered]@{
                            ".validate" = "newData.isString() && newData.val().length >= 8 && newData.val().length <= 48 && (!data.exists() || newData.val() == data.val())"
                        }
                        name = [ordered]@{
                            ".validate" = "newData.isString() && newData.val().length > 0 && newData.val().length <= 16"
                        }
                        name_key = [ordered]@{
                            ".validate" = "newData.isString() && newData.val() == `$nameKey && newData.val().matches(/^[a-z0-9_]{1,16}$/)"
                        }
                        avatar_index = [ordered]@{
                            ".validate" = "newData.isNumber() && newData.val() >= 0 && newData.val() <= 19"
                        }
                        created_at = [ordered]@{
                            ".validate" = "newData.isNumber() && ((!data.exists() && newData.val() >= now - 300000 && newData.val() <= now + 60000) || (data.exists() && newData.val() >= data.val()))"
                        }
                        updated_at = [ordered]@{
                            ".validate" = $freshClientTimestampRule
                        }
                        submitted_at_unix = [ordered]@{
                            ".validate" = "newData.isNumber() && newData.val() > 0"
                        }
                        '$other' = [ordered]@{
                            ".validate" = $false
                        }
                    }
                }
                scores = [ordered]@{
                    '$category' = [ordered]@{
                        ".read" = "$categoryExpression && query.orderByChild == 'score' && query.limitToLast != null && query.limitToLast > 0 && query.limitToLast <= 50"
                        ".indexOn" = @("score")
                        '$playerId' = [ordered]@{
                            ".write" = "newData.exists() && $leaderboardWriterRule && $categoryExpression && `$playerId.length >= 8 && `$playerId.length <= 48 && $leaderboardNameClaimRule && (($leaderboardFreshGateRule) || ($leaderboardLegacyRowCooldownRule) || (data.exists() && newData.child('score').val() == data.child('score').val() && newData.child('updated_at').val() >= now - 10000 && newData.child('updated_at').val() <= now + 60000))"
                            ".validate" = "newData.hasChildren(['name', 'name_key', 'avatar_index', 'score', 'updated_at', 'submitted_at_unix'])"
                            name = [ordered]@{
                                ".validate" = "newData.isString() && newData.val().length > 0 && newData.val().length <= 16"
                            }
                            name_key = [ordered]@{
                                ".validate" = "newData.isString() && newData.val().matches(/^[a-z0-9_]{1,16}$/)"
                            }
                            avatar_index = [ordered]@{
                                ".validate" = "newData.isNumber() && newData.val() >= 0 && newData.val() <= 19"
                            }
                            score = [ordered]@{
                                ".validate" = "newData.isNumber() && newData.val() >= 0 && newData.val() <= 1000000000000 && (!data.exists() || newData.val() >= data.val() || ($leaderboardLegacyTotalLevelScoreRule))"
                            }
                            skill_level = [ordered]@{
                                ".validate" = "newData.isNumber() && newData.val() >= 0 && newData.val() <= 99"
                            }
                            total_xp = [ordered]@{
                                ".validate" = "newData.isNumber() && newData.val() >= 0 && newData.val() <= 1000000000000 && (!data.exists() || !data.child('total_xp').exists() || newData.val() >= data.child('total_xp').val())"
                            }
                            updated_at = [ordered]@{
                                ".validate" = "newData.isNumber() && newData.val() >= now - 300000 && newData.val() <= now + 60000"
                            }
                            submitted_at_unix = [ordered]@{
                                ".validate" = "newData.isNumber() && newData.val() > 0"
                            }
                            '$other' = [ordered]@{
                                ".validate" = $false
                            }
                        }
                    }
                }
                player_write_gates = [ordered]@{
                    '$playerId' = [ordered]@{
                        ".read" = $false
                        ".write" = "newData.exists() && $leaderboardWriterRule && `$playerId.length >= 8 && `$playerId.length <= 48 && (!data.exists() || now - data.child('updated_at').val() >= 900000)"
                        ".validate" = "newData.hasChildren(['updated_at', 'submitted_at_unix'])"
                        updated_at = [ordered]@{
                            ".validate" = $freshClientTimestampRule
                        }
                        submitted_at_unix = [ordered]@{
                            ".validate" = "newData.isNumber() && newData.val() > 0"
                        }
                        '$other' = [ordered]@{
                            ".validate" = $false
                        }
                    }
                }
            }
        }
        global_chat = [ordered]@{
            v1 = [ordered]@{
                ".read" = $false
                ".write" = $false
                messages = [ordered]@{
                    ".read" = "query.orderByChild == 'created_at' && query.limitToLast != null && query.limitToLast > 0 && query.limitToLast <= 25"
                    ".indexOn" = @("created_at")
                    '$messageId' = [ordered]@{
                        ".write" = "(($chatCreateRule) || ($chatOwnerRefreshRule) || ($chatModerationRule))"
                        ".validate" = "newData.hasChildren(['sender_id', 'name', 'avatar_index', 'text', 'created_at', 'created_at_unix', 'deleted'])"
                        sender_id = [ordered]@{
                            ".validate" = "newData.isString() && newData.val().length >= 8 && newData.val().length <= 48"
                        }
                        name = [ordered]@{
                            ".validate" = "newData.isString() && newData.val().length > 0 && newData.val().length <= 16"
                        }
                        name_key = [ordered]@{
                            ".validate" = "newData.isString() && newData.val().matches(/^[a-z0-9_]{1,16}$/)"
                        }
                        total_level = [ordered]@{
                            ".validate" = "newData.isNumber() && newData.val() >= 0 && newData.val() <= 1000000"
                        }
                        avatar_index = [ordered]@{
                            ".validate" = "newData.isNumber() && newData.val() >= 0 && newData.val() <= 19"
                        }
                        text = [ordered]@{
                            ".validate" = "newData.isString() && newData.val().length > 0 && newData.val().length <= 80"
                        }
                        created_at = [ordered]@{
                            ".validate" = "newData.isNumber() && ((!data.exists() && newData.val() >= now - 300000 && newData.val() <= now + 60000) || (data.exists() && newData.val() == data.val()))"
                        }
                        created_at_unix = [ordered]@{
                            ".validate" = "newData.isNumber() && newData.val() > 0"
                        }
                        deleted = [ordered]@{
                            ".validate" = "newData.isBoolean() && ((!data.exists() && newData.val() == false) || data.exists())"
                        }
                        deleted_at = [ordered]@{
                            ".validate" = "newData.isNumber() && data.exists() && auth.token.moderator == true && newData.val() == now"
                        }
                        deleted_by = [ordered]@{
                            ".validate" = "newData.isString() && data.exists() && auth.token.moderator == true && newData.val() == auth.uid"
                        }
                        '$other' = [ordered]@{
                            ".validate" = $false
                        }
                    }
                }
                user_write_gates = [ordered]@{
                    '$playerId' = [ordered]@{
                        ".read" = $false
                        ".write" = "newData.exists() && ((auth != null && auth.uid == `$playerId) || auth == null) && `$playerId.length >= 8 && `$playerId.length <= 48 && (!data.exists() || now - data.child('updated_at').val() >= 2000)"
                        ".validate" = "newData.hasChildren(['updated_at', 'submitted_at_unix'])"
                        updated_at = [ordered]@{
                            ".validate" = $freshClientTimestampRule
                        }
                        submitted_at_unix = [ordered]@{
                            ".validate" = "newData.isNumber() && newData.val() > 0"
                        }
                        '$other' = [ordered]@{
                            ".validate" = $false
                        }
                    }
                }
                moderation_logs = [ordered]@{
                    '$logId' = [ordered]@{
                        ".read" = "auth != null && auth.token.moderator == true"
                        ".write" = "auth != null && auth.token.moderator == true && newData.exists() && !data.exists()"
                        ".validate" = "newData.hasChildren(['message_id', 'moderator_id', 'reason', 'created_at', 'created_at_unix'])"
                        message_id = [ordered]@{
                            ".validate" = "newData.isString() && newData.val().length >= 8 && newData.val().length <= 64"
                        }
                        moderator_id = [ordered]@{
                            ".validate" = "newData.isString() && newData.val() == auth.uid"
                        }
                        reason = [ordered]@{
                            ".validate" = "newData.isString() && newData.val().length > 0 && newData.val().length <= 160"
                        }
                        created_at = [ordered]@{
                            ".validate" = "newData.isNumber() && newData.val() == now"
                        }
                        created_at_unix = [ordered]@{
                            ".validate" = "newData.isNumber() && newData.val() > 0"
                        }
                        '$other' = [ordered]@{
                            ".validate" = $false
                        }
                    }
                }
            }
        }
    }
}

$generated = ($rulesObject | ConvertTo-Json -Depth 32)
$generated = $generated.Replace("\u0026", "&")
$generated = $generated.Replace("\u0027", "'")
$generated = $generated.Replace("\u003c", "<")
$generated = $generated.Replace("\u003e", ">")
$generated += "`n"

if ($Check) {
    Assert-True (Test-Path -LiteralPath $rulesPath) "Missing firebase-realtime-database.rules.json"
    $current = Get-Content -LiteralPath $rulesPath -Raw
    $normalizedCurrent = $current -replace "`r`n", "`n"
    $normalizedGenerated = $generated -replace "`r`n", "`n"
    Assert-True ($normalizedCurrent -eq $normalizedGenerated) "firebase-realtime-database.rules.json is out of date. Run .\scripts\update-firebase-leaderboard-rules.ps1"
    Write-Output "firebase-leaderboard-rules-current"
    exit 0
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($rulesPath, $generated, $utf8NoBom)
Write-Output "firebase-leaderboard-rules-updated"
