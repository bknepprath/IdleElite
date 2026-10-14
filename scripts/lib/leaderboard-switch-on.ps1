# Pure helpers for scripts\switch-on-firebase-leaderboard-rules.ps1 (no network, testable offline).

# Score rows written by signed-in (0.6.0+) players are keyed by their Firebase UID, and that UID
# has a profile under profiles_by_uid. Every other row is a legacy (pre-auth) or orphaned entry
# that the authenticated rules will never let anyone update again. The same goes for name claims.
function Get-StaleLeaderboardScorePaths {
    param([Parameter(Mandatory = $true)] $LeaderboardsV1)
    $profiles = @{}
    if ($null -ne $LeaderboardsV1.profiles_by_uid) {
        foreach ($property in $LeaderboardsV1.profiles_by_uid.PSObject.Properties) {
            $profiles[[string]$property.Name] = $true
        }
    }
    $stale = New-Object System.Collections.Generic.List[string]
    $kept = 0
    if ($null -ne $LeaderboardsV1.scores) {
        foreach ($category in $LeaderboardsV1.scores.PSObject.Properties) {
            if ($null -eq $category.Value) {
                continue
            }
            foreach ($row in $category.Value.PSObject.Properties) {
                if ($profiles.ContainsKey([string]$row.Name)) {
                    $kept++
                } else {
                    $stale.Add("scores/$($category.Name)/$($row.Name)")
                }
            }
        }
    }
    # Name claims held by an id without a signed-in profile are legacy claims; freeing them lets
    # returning players (fresh start, no support ticket) claim their names again.
    $keptClaims = 0
    if ($null -ne $LeaderboardsV1.name_claims) {
        foreach ($claim in $LeaderboardsV1.name_claims.PSObject.Properties) {
            $claimUid = if ($null -ne $claim.Value) { [string]$claim.Value.uid } else { "" }
            if ($profiles.ContainsKey($claimUid)) {
                $keptClaims++
            } else {
                $stale.Add("name_claims/$($claim.Name)")
            }
        }
    }
    return [pscustomobject]@{ Stale = $stale.ToArray(); Kept = $kept; KeptClaims = $keptClaims }
}

# Multi-path update body that deletes each stale row (null removes the key).
function New-StaleLeaderboardDeleteUpdate {
    param([string[]] $StalePaths)
    $update = [ordered]@{}
    foreach ($path in $StalePaths) {
        $update[$path] = $null
    }
    return $update
}
