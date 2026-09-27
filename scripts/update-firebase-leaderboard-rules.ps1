param(
    [switch]$Check
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$activityDatabasePath = Join-Path $projectRoot "docs\activity-database.json"
$rulesPath = Join-Path $projectRoot "firebase-realtime-database.rules.json"

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
$leaderboardWriterRule = "auth != null && auth.uid == `$playerId"
$nameRecoveryTicketRule = "root.child('leaderboards').child('v1').child('name_recovery_tickets').child(`$nameKey).child('active').val() == true && root.child('leaderboards').child('v1').child('name_recovery_tickets').child(`$nameKey).child('target_uid').val() == auth.uid && root.child('leaderboards').child('v1').child('name_recovery_tickets').child(`$nameKey).child('expires_at').isNumber() && root.child('leaderboards').child('v1').child('name_recovery_tickets').child(`$nameKey).child('expires_at').val() >= now"
$nameRecoveryClaimGateRule = "newData.parent().parent().child('name_recovery_gates').child(auth.uid).child('name_key').val() == `$nameKey && newData.parent().parent().child('name_recovery_gates').child(auth.uid).child('target_uid').val() == auth.uid && newData.parent().parent().child('name_recovery_gates').child(auth.uid).child('old_uid').val() == data.child('uid').val()"
$nameRecoveryUidGateRule = "newData.parent().parent().parent().child('name_recovery_gates').child(auth.uid).child('name_key').val() == `$nameKey && newData.parent().parent().parent().child('name_recovery_gates').child(auth.uid).child('target_uid').val() == auth.uid && newData.parent().parent().parent().child('name_recovery_gates').child(auth.uid).child('old_uid').val() == data.val()"
$nameClaimWriterRule = "auth != null && newData.child('uid').val() == auth.uid && (!data.exists() || data.child('uid').val() == auth.uid || (($nameRecoveryTicketRule) && ($nameRecoveryClaimGateRule)))"
$leaderboardNameClaimRule = "root.child('leaderboards').child('v1').child('name_claims').child(newData.child('name_key').val()).child('uid').val() == `$playerId && root.child('leaderboards').child('v1').child('name_claims').child(newData.child('name_key').val()).child('name').val() == newData.child('name').val() && root.child('leaderboards').child('v1').child('profiles_by_uid').child(`$playerId).child('uid').val() == `$playerId && root.child('leaderboards').child('v1').child('profiles_by_uid').child(`$playerId).child('display_name').val() == newData.child('name').val() && root.child('leaderboards').child('v1').child('profiles_by_uid').child(`$playerId).child('name_key').val() == newData.child('name_key').val() && root.child('leaderboards').child('v1').child('profiles_by_uid').child(`$playerId).child('avatar_index').val() == newData.child('avatar_index').val()"
$profileNameClaimRule = "newData.parent().parent().child('name_claims').child(newData.child('name_key').val()).child('uid').val() == auth.uid && newData.parent().parent().child('name_claims').child(newData.child('name_key').val()).child('name').val() == newData.child('display_name').val() && newData.parent().parent().child('name_claims').child(newData.child('name_key').val()).child('avatar_index').val() == newData.child('avatar_index').val()"
$profileExistingNameRule = "!data.exists() || data.child('name_key').val() == newData.child('name_key').val()"
$profileReadRule = "auth != null && auth.uid == `$uid && (!data.exists() || (root.child('leaderboards').child('v1').child('name_claims').child(data.child('name_key').val()).child('uid').val() == `$uid && root.child('leaderboards').child('v1').child('name_claims').child(data.child('name_key').val()).child('name').val() == data.child('display_name').val() && root.child('leaderboards').child('v1').child('name_claims').child(data.child('name_key').val()).child('avatar_index').val() == data.child('avatar_index').val()))"
$legacyRecoveryGateTicketRule = "root.child('leaderboards').child('v1').child('name_recovery_tickets').child(newData.child('name_key').val()).child('active').val() == true && root.child('leaderboards').child('v1').child('name_recovery_tickets').child(newData.child('name_key').val()).child('target_uid').val() == auth.uid && root.child('leaderboards').child('v1').child('name_recovery_tickets').child(newData.child('name_key').val()).child('expires_at').isNumber() && root.child('leaderboards').child('v1').child('name_recovery_tickets').child(newData.child('name_key').val()).child('expires_at').val() >= now"
$legacyRecoveryGateOldClaimRule = "root.child('leaderboards').child('v1').child('name_claims').child(newData.child('name_key').val()).child('uid').val() == newData.child('old_uid').val() || (root.child('leaderboards').child('v1').child('name_claims').child(newData.child('name_key').val()).child('uid').val() == auth.uid && data.exists() && data.child('name_key').val() == newData.child('name_key').val() && data.child('old_uid').val() == newData.child('old_uid').val() && data.child('target_uid').val() == auth.uid)"
$leaderboardFreshGateRule = "root.child('leaderboards').child('v1').child('player_write_gates').child(`$playerId).child('updated_at').isNumber() && root.child('leaderboards').child('v1').child('player_write_gates').child(`$playerId).child('updated_at').val() >= now - 10000 && root.child('leaderboards').child('v1').child('player_write_gates').child(`$playerId).child('updated_at').val() <= now + 60000"
$leaderboardLegacyRowCooldownRule = "newData.child('updated_at').isNumber() && newData.child('updated_at').val() >= now - 10000 && newData.child('updated_at').val() <= now + 60000 && (!data.exists() || now - data.child('updated_at').val() >= 900000)"
$leaderboardLegacyTotalLevelScoreRule = "`$category == 'total_level' && data.exists() && data.child('score').isNumber() && data.child('score').val() > 999 && newData.parent().child('total_xp').isNumber() && newData.parent().child('total_xp').val() >= data.child('score').val()"
$chatSenderRule = "newData.child('sender_id').isString() && newData.child('sender_id').val().length >= 8 && newData.child('sender_id').val().length <= 48 && auth != null && newData.child('sender_id').val() == auth.uid"
$chatFreshGateRule = "newData.parent().parent().child('user_write_gates').child(newData.child('sender_id').val()).child('updated_at').isNumber() && newData.parent().parent().child('user_write_gates').child(newData.child('sender_id').val()).child('updated_at').val() >= now - 10000 && newData.parent().parent().child('user_write_gates').child(newData.child('sender_id').val()).child('updated_at').val() <= now + 60000"
$chatClaimedNameRule = "newData.child('name_key').isString() && root.child('leaderboards').child('v1').child('name_claims').child(newData.child('name_key').val()).child('uid').val() == newData.child('sender_id').val() && root.child('leaderboards').child('v1').child('name_claims').child(newData.child('name_key').val()).child('name').val() == newData.child('name').val() && root.child('leaderboards').child('v1').child('profiles_by_uid').child(newData.child('sender_id').val()).child('uid').val() == newData.child('sender_id').val() && root.child('leaderboards').child('v1').child('profiles_by_uid').child(newData.child('sender_id').val()).child('display_name').val() == newData.child('name').val() && root.child('leaderboards').child('v1').child('profiles_by_uid').child(newData.child('sender_id').val()).child('name_key').val() == newData.child('name_key').val() && root.child('leaderboards').child('v1').child('profiles_by_uid').child(newData.child('sender_id').val()).child('avatar_index').val() == newData.child('avatar_index').val()"
$chatGuestNameRule = "!newData.child('name_key').exists() && newData.child('name').isString() && newData.child('name').val().matches(/^guest[0-9]{4}$/)"
$chatCreateRule = "newData.exists() && !data.exists() && $chatSenderRule && ($chatClaimedNameRule || $chatGuestNameRule) && `$messageId.length >= 8 && `$messageId.length <= 64 && $chatFreshGateRule"
$chatOwnerRefreshRule = "data.exists() && newData.exists() && data.child('sender_id').val() == newData.child('sender_id').val() && auth != null && data.child('sender_id').val() == auth.uid && $chatClaimedNameRule && newData.child('sender_id').val() == data.child('sender_id').val() && newData.child('text').val() == data.child('text').val() && newData.child('created_at').val() == data.child('created_at').val() && newData.child('created_at_unix').val() == data.child('created_at_unix').val() && newData.child('deleted').val() == data.child('deleted').val() && newData.child('deleted_at').val() == data.child('deleted_at').val() && newData.child('deleted_by').val() == data.child('deleted_by').val()"
$chatModerationRule = "data.exists() && newData.exists() && auth != null && auth.token.moderator == true && newData.child('sender_id').val() == data.child('sender_id').val() && newData.child('name').val() == data.child('name').val() && newData.child('name_key').val() == data.child('name_key').val() && newData.child('total_level').val() == data.child('total_level').val() && newData.child('avatar_index').val() == data.child('avatar_index').val() && newData.child('text').val() == data.child('text').val() && newData.child('created_at').val() == data.child('created_at').val() && newData.child('created_at_unix').val() == data.child('created_at_unix').val() && newData.child('deleted').val() == true && newData.child('deleted_at').val() == now && newData.child('deleted_by').val() == auth.uid"

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
                            ".validate" = "newData.isString() && newData.val().length >= 8 && newData.val().length <= 48 && (!data.exists() || newData.val() == data.val() || (auth != null && newData.val() == auth.uid && ($nameRecoveryTicketRule) && ($nameRecoveryUidGateRule)))"
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
                profiles_by_uid = [ordered]@{
                    '$uid' = [ordered]@{
                        ".read" = $profileReadRule
                        ".write" = "auth != null && auth.uid == `$uid && newData.exists() && newData.child('uid').val() == auth.uid && ($profileExistingNameRule) && $profileNameClaimRule"
                        ".validate" = "newData.hasChildren(['uid', 'display_name', 'name_key', 'avatar_index', 'profile_claimed', 'name_claim_verified', 'auth_provider', 'updated_at', 'updated_at_unix'])"
                        uid = [ordered]@{
                            ".validate" = "newData.isString() && newData.val() == auth.uid"
                        }
                        display_name = [ordered]@{
                            ".validate" = "newData.isString() && newData.val().length > 0 && newData.val().length <= 16"
                        }
                        name_key = [ordered]@{
                            ".validate" = "newData.isString() && newData.val().matches(/^[a-z0-9_]{1,16}$/)"
                        }
                        avatar_index = [ordered]@{
                            ".validate" = "newData.isNumber() && newData.val() >= 0 && newData.val() <= 19"
                        }
                        profile_claimed = [ordered]@{
                            ".validate" = "newData.isBoolean() && newData.val() == true"
                        }
                        name_claim_verified = [ordered]@{
                            ".validate" = "newData.isBoolean() && newData.val() == true"
                        }
                        auth_provider = [ordered]@{
                            ".validate" = "newData.isString() && (newData.val() == 'anonymous' || newData.val() == 'google')"
                        }
                        updated_at = [ordered]@{
                            ".validate" = $freshClientTimestampRule
                        }
                        updated_at_unix = [ordered]@{
                            ".validate" = "newData.isNumber() && newData.val() > 0"
                        }
                        '$other' = [ordered]@{
                            ".validate" = $false
                        }
                    }
                }
                name_recovery_tickets = [ordered]@{
                    '$nameKey' = [ordered]@{
                        ".read" = $false
                        ".write" = $false
                    }
                }
                name_recovery_gates = [ordered]@{
                    '$uid' = [ordered]@{
                        ".read" = $false
                        ".write" = "auth != null && auth.uid == `$uid && newData.exists() && newData.child('target_uid').val() == auth.uid && ($legacyRecoveryGateTicketRule) && ($legacyRecoveryGateOldClaimRule)"
                        ".validate" = "newData.hasChildren(['name_key', 'old_uid', 'target_uid', 'updated_at'])"
                        name_key = [ordered]@{
                            ".validate" = "newData.isString() && newData.val().matches(/^[a-z0-9_]{1,16}$/)"
                        }
                        old_uid = [ordered]@{
                            ".validate" = "newData.isString() && newData.val().matches(/^[A-Za-z0-9_-]{8,48}$/)"
                        }
                        target_uid = [ordered]@{
                            ".validate" = "newData.isString() && newData.val() == auth.uid"
                        }
                        updated_at = [ordered]@{
                            ".validate" = $freshClientTimestampRule
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
        cloud_saves = [ordered]@{
            v1 = [ordered]@{
                ".read" = $false
                ".write" = $false
                users = [ordered]@{
                    '$uid' = [ordered]@{
                        ".read" = "auth != null && auth.uid == `$uid"
                        ".write" = "auth != null && auth.uid == `$uid && newData.exists() && (!data.child('revision').exists() || (newData.child('revision').isNumber() && newData.child('revision').val() == data.child('revision').val() + 1))"
                        ".validate" = "newData.hasChildren(['uid', 'updated_at', 'updated_at_unix', 'save_schema_version', 'saved_at', 'total_skill_xp', 'total_level', 'payload_json']) && ((!newData.child('revision').exists() && !newData.child('payload_checksum').exists()) || newData.hasChildren(['revision', 'payload_checksum']))"
                        uid = [ordered]@{
                            ".validate" = "newData.isString() && newData.val() == auth.uid"
                        }
                        updated_at = [ordered]@{
                            ".validate" = $freshClientTimestampRule
                        }
                        updated_at_unix = [ordered]@{
                            ".validate" = "newData.isNumber() && newData.val() > 0"
                        }
                        save_schema_version = [ordered]@{
                            ".validate" = "newData.isNumber() && newData.val() >= 1 && newData.val() <= 1000"
                        }
                        saved_at = [ordered]@{
                            ".validate" = "newData.isNumber() && newData.val() > 0"
                        }
                        total_skill_xp = [ordered]@{
                            ".validate" = "newData.isNumber() && newData.val() >= 0 && newData.val() <= 1000000000000"
                        }
                        total_level = [ordered]@{
                            ".validate" = "newData.isNumber() && newData.val() >= 0 && newData.val() <= 1000000"
                        }
                        revision = [ordered]@{
                            ".validate" = "newData.isNumber() && newData.val() >= 1 && newData.val() <= 1000000000 && (!data.exists() || newData.val() == data.val() + 1)"
                        }
                        payload_checksum = [ordered]@{
                            ".validate" = "newData.isString() && newData.val().matches(/^[a-f0-9]{64}$/)"
                        }
                        payload_json = [ordered]@{
                            ".validate" = "newData.isString() && newData.val().length > 0 && newData.val().length <= 950000"
                        }
                        '$other' = [ordered]@{
                            ".validate" = $false
                        }
                    }
                }
                history = [ordered]@{
                    '$uid' = [ordered]@{
                        ".read" = "auth != null && auth.uid == `$uid"
                        slots = [ordered]@{
                            '$slot' = [ordered]@{
                                ".write" = "auth != null && auth.uid == `$uid && (`$slot == '0' || `$slot == '1' || `$slot == '2' || `$slot == '3' || `$slot == '4') && newData.exists() && newData.child('uid').val() == auth.uid && (!data.exists() || newData.child('revision').val() > data.child('revision').val() || (newData.child('revision').val() == data.child('revision').val() && newData.child('payload_checksum').val() == data.child('payload_checksum').val() && newData.child('payload_json').val() == data.child('payload_json').val()))"
                                ".validate" = "newData.hasChildren(['uid', 'updated_at', 'updated_at_unix', 'save_schema_version', 'saved_at', 'total_skill_xp', 'total_level', 'revision', 'payload_checksum', 'payload_json'])"
                                uid = [ordered]@{
                                    ".validate" = "newData.isString() && newData.val() == auth.uid"
                                }
                                updated_at = [ordered]@{
                                    ".validate" = $freshClientTimestampRule
                                }
                                updated_at_unix = [ordered]@{
                                    ".validate" = "newData.isNumber() && newData.val() > 0"
                                }
                                save_schema_version = [ordered]@{
                                    ".validate" = "newData.isNumber() && newData.val() >= 1 && newData.val() <= 1000"
                                }
                                saved_at = [ordered]@{
                                    ".validate" = "newData.isNumber() && newData.val() > 0"
                                }
                                total_skill_xp = [ordered]@{
                                    ".validate" = "newData.isNumber() && newData.val() >= 0 && newData.val() <= 1000000000000"
                                }
                                total_level = [ordered]@{
                                    ".validate" = "newData.isNumber() && newData.val() >= 0 && newData.val() <= 1000000"
                                }
                                revision = [ordered]@{
                                    ".validate" = "newData.isNumber() && newData.val() >= 1 && newData.val() <= 1000000000"
                                }
                                payload_checksum = [ordered]@{
                                    ".validate" = "newData.isString() && newData.val().matches(/^[a-f0-9]{64}$/)"
                                }
                                payload_json = [ordered]@{
                                    ".validate" = "newData.isString() && newData.val().length > 0 && newData.val().length <= 950000"
                                }
                                '$other' = [ordered]@{
                                    ".validate" = $false
                                }
                            }
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
                        ".write" = "newData.exists() && auth != null && auth.uid == `$playerId && `$playerId.length >= 8 && `$playerId.length <= 48 && (!data.exists() || now - data.child('updated_at').val() >= 2000)"
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
