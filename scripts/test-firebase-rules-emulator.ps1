<#
Proves, against LOCAL Firebase emulators only, that the committed Realtime Database
rules (firebase-realtime-database.rules.json) accept every write the 0.6.0 client
makes and reject legacy / cheating writes.

Safety model (never touches the live project):
- The project id must start with "demo-" (emulator-only project ids).
- The Realtime Database emulator JAR is launched directly with java. The Firebase
  CLI's own database-emulator startup path looks up the project's default database
  instance through the Firebase Management API (firebase.googleapis.com); launching
  the JAR ourselves removes that code path entirely. The committed rules are then
  loaded into the emulator namespace with the emulator-only "Bearer owner" admin.
- The Firebase CLI is only used for `emulators:exec --only auth`, with an isolated
  XDG_CONFIG_HOME (so it sees no logged-in account), update checks disabled, and an
  HTTP(S)_PROXY that points at a closed local port (NO_PROXY covers localhost), so
  any unexpected outbound request fails locally instead of leaving the machine.
- The emulator JAR is never downloaded: it must already exist locally and must match
  the SHA-256 the installed firebase-tools expects.

Usage:
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\test-firebase-rules-emulator.ps1
  (optional) -DatabaseEmulatorJar <path to firebase-database-emulator-v*.jar>
#>
[CmdletBinding()]
param(
    [switch]$Runner,
    [int]$AuthPort = 0,
    [int]$DatabasePort = 0,
    [string]$ProjectId = "demo-idle-elite",
    [string]$DatabaseEmulatorJar = "",
    # Test another rules file (for example the rules currently deployed) instead of the committed one.
    [string]$RulesPath = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2

if (-not $ProjectId.StartsWith("demo-")) {
    throw "Refusing to run: project id '$ProjectId' is not an emulator-only demo- project."
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$workDir = Join-Path $projectRoot ".codex-tmp\firebase-rules-emulator"
$committedRulesPath = Join-Path $projectRoot "firebase-realtime-database.rules.json"
if ($RulesPath) { $committedRulesPath = (Resolve-Path -LiteralPath $RulesPath).Path }

function Get-FreeLocalPort {
    $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, 0)
    $listener.Start()
    try { return ([System.Net.IPEndPoint]$listener.LocalEndpoint).Port } finally { $listener.Stop() }
}

function Test-LocalPortOpen([int]$Port) {
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $async = $client.BeginConnect("127.0.0.1", $Port, $null, $null)
        if (-not $async.AsyncWaitHandle.WaitOne(500)) { return $false }
        $client.EndConnect($async)
        return $true
    } catch {
        return $false
    } finally {
        $client.Close()
    }
}

function Get-FileSha256Hex([string]$Path) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $stream = [System.IO.File]::OpenRead($Path)
    try { return ([BitConverter]::ToString($sha.ComputeHash($stream)) -replace "-", "").ToLowerInvariant() } finally { $stream.Dispose(); $sha.Dispose() }
}

function Stop-LocalPortListeners([int[]]$Ports) {
    foreach ($port in $Ports) {
        if ($port -le 0) { continue }
        try {
            $owners = @(Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction Stop | Select-Object -ExpandProperty OwningProcess -Unique)
        } catch {
            $owners = @()
        }
        foreach ($owner in $owners) {
            if ($owner -and $owner -ne $PID) {
                try { Stop-Process -Id $owner -Force -ErrorAction Stop; Write-Host "cleanup: stopped PID $owner listening on port $port" } catch {}
            }
        }
    }
}

# =====================================================================================
# Orchestrator
# =====================================================================================
if (-not $Runner) {
    New-Item -ItemType Directory -Force -Path $workDir | Out-Null
    $binDir = Join-Path $workDir "bin"
    New-Item -ItemType Directory -Force -Path $binDir | Out-Null

    # --- Locate and verify the database emulator JAR (never downloaded). ---
    $firebaseCommand = Get-Command firebase.cmd -ErrorAction Stop
    $firebaseToolsDir = Join-Path (Split-Path -Parent $firebaseCommand.Source) "node_modules\firebase-tools"
    $emulatorInfoPath = Join-Path $firebaseToolsDir "lib\emulator\downloadableEmulatorInfo.json"
    if (-not (Test-Path $emulatorInfoPath)) { throw "Cannot find firebase-tools emulator manifest at $emulatorInfoPath" }
    $emulatorInfo = Get-Content -Raw -Path $emulatorInfoPath | ConvertFrom-Json
    $dbVersion = [string]$emulatorInfo.database.version
    $dbExpectedSha = ([string]$emulatorInfo.database.expectedChecksumSHA256).ToLowerInvariant()
    $jarName = "firebase-database-emulator-v$dbVersion.jar"
    $jarCandidates = @()
    if ($DatabaseEmulatorJar) { $jarCandidates += $DatabaseEmulatorJar }
    $jarCandidates += (Join-Path $binDir $jarName)
    if ($env:DATABASE_EMULATOR_BINARY_PATH) { $jarCandidates += $env:DATABASE_EMULATOR_BINARY_PATH }
    if ($env:FIREBASE_EMULATORS_PATH) { $jarCandidates += (Join-Path $env:FIREBASE_EMULATORS_PATH $jarName) }
    $jarCandidates += (Join-Path $env:USERPROFILE ".cache\firebase\emulators\$jarName")
    $sourceJar = $jarCandidates | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
    if (-not $sourceJar) {
        throw "No local $jarName found. This script never downloads it. Pass -DatabaseEmulatorJar <path> (SHA-256 $dbExpectedSha)."
    }
    $actualSha = Get-FileSha256Hex $sourceJar
    if ($actualSha -ne $dbExpectedSha) {
        throw "Database emulator JAR $sourceJar has SHA-256 $actualSha, expected $dbExpectedSha for v$dbVersion."
    }
    $jarPath = Join-Path $binDir $jarName
    if ((Resolve-Path -LiteralPath $sourceJar).Path -ne $jarPath) { Copy-Item -LiteralPath $sourceJar -Destination $jarPath -Force }
    Write-Host "database emulator jar: $jarPath (v$dbVersion, sha256 verified)"

    # --- Copy committed rules and write the temp firebase.json. ---
    $rulesCopy = Join-Path $workDir "database.rules.json"
    Copy-Item -LiteralPath $committedRulesPath -Destination $rulesCopy -Force
    $null = Get-Content -Raw -Path $rulesCopy | ConvertFrom-Json  # must be valid JSON

    $ports = @{}
    $used = @{}
    foreach ($name in @("auth", "database", "hub", "logging", "sinkhole")) {
        do { $p = Get-FreeLocalPort } while ($used.ContainsKey($p))
        $used[$p] = $true
        $ports[$name] = $p
    }
    $firebaseJson = [ordered]@{
        database = [ordered]@{ rules = "database.rules.json" }
        emulators = [ordered]@{
            auth = [ordered]@{ host = "127.0.0.1"; port = $ports.auth }
            database = [ordered]@{ host = "127.0.0.1"; port = $ports.database }
            hub = [ordered]@{ host = "127.0.0.1"; port = $ports.hub }
            logging = [ordered]@{ host = "127.0.0.1"; port = $ports.logging }
            ui = [ordered]@{ enabled = $false }
            singleProjectMode = $true
        }
    }
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText((Join-Path $workDir "firebase.json"), ($firebaseJson | ConvertTo-Json -Depth 10), $utf8NoBom)
    $runnerCmd = "@echo off`r`npowershell -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Runner -AuthPort $($ports.auth) -DatabasePort $($ports.database) -ProjectId $ProjectId$(if ($RulesPath) { ' -RulesPath `"' + $committedRulesPath + '`"' })`r`nexit /b %ERRORLEVEL%`r`n"
    [System.IO.File]::WriteAllText((Join-Path $workDir "run-rules-cases.cmd"), $runnerCmd, (New-Object System.Text.ASCIIEncoding))
    Write-Host "ports: auth=$($ports.auth) database=$($ports.database) hub=$($ports.hub) logging=$($ports.logging)"

    $envNames = @("XDG_CONFIG_HOME", "NO_UPDATE_NOTIFIER", "HTTPS_PROXY", "HTTP_PROXY", "https_proxy", "http_proxy", "NO_PROXY", "no_proxy", "GOOGLE_APPLICATION_CREDENTIALS", "FIREBASE_TOKEN", "GCLOUD_PROJECT")
    $savedEnv = @{}
    foreach ($n in $envNames) { $savedEnv[$n] = [Environment]::GetEnvironmentVariable($n, "Process") }

    $dbProcess = $null
    $exitCode = 1
    $sawOk = $false
    Push-Location $workDir
    try {
        # --- Start the database emulator JAR directly. ---
        $dbProcess = Start-Process -FilePath "java" -ArgumentList @("-Duser.language=en", "-jar", "`"$jarPath`"", "--host", "127.0.0.1", "--port", "$($ports.database)", "--single_project_mode", "Warning") -PassThru -NoNewWindow -RedirectStandardOutput (Join-Path $workDir "database-emulator.out.log") -RedirectStandardError (Join-Path $workDir "database-emulator.err.log")
        $deadline = (Get-Date).AddSeconds(90)
        while (-not (Test-LocalPortOpen $ports.database)) {
            if ($dbProcess.HasExited) { throw "Database emulator exited early (code $($dbProcess.ExitCode)). See $workDir\database-emulator.*.log" }
            if ((Get-Date) -gt $deadline) { throw "Database emulator did not open port $($ports.database) within 90s." }
            Start-Sleep -Milliseconds 300
        }
        Write-Host "database emulator ready on 127.0.0.1:$($ports.database) (PID $($dbProcess.Id))"

        # --- Isolate the CLI from the real account and from the network. ---
        $xdg = Join-Path $workDir "xdg-config"
        New-Item -ItemType Directory -Force -Path $xdg | Out-Null
        $env:XDG_CONFIG_HOME = $xdg
        $env:NO_UPDATE_NOTIFIER = "1"
        $sinkhole = "http://127.0.0.1:$($ports.sinkhole)"
        $env:HTTPS_PROXY = $sinkhole; $env:HTTP_PROXY = $sinkhole; $env:https_proxy = $sinkhole; $env:http_proxy = $sinkhole
        $env:NO_PROXY = "127.0.0.1,localhost"; $env:no_proxy = "127.0.0.1,localhost"
        $env:GOOGLE_APPLICATION_CREDENTIALS = (Join-Path $workDir "no-such-credentials.json")
        $env:FIREBASE_TOKEN = $null
        $env:GCLOUD_PROJECT = $ProjectId

        $previousPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        try {
            & $firebaseCommand.Source emulators:exec --only auth --project $ProjectId ".\run-rules-cases.cmd" 2>&1 | ForEach-Object {
                $line = "$_"
                if ($line -match '^\s*firebase-rules-emulator-ok\s*$') { $sawOk = $true }
                Write-Host $line
            }
            $exitCode = $LASTEXITCODE
        } finally {
            $ErrorActionPreference = $previousPreference
        }
    } finally {
        Pop-Location
        foreach ($n in $envNames) { [Environment]::SetEnvironmentVariable($n, $savedEnv[$n], "Process") }
        if ($null -ne $dbProcess -and -not $dbProcess.HasExited) {
            # `java` may be the Oracle javapath launcher shim; kill the whole tree.
            $ErrorActionPreference = "Continue"
            try { & taskkill.exe /PID $dbProcess.Id /T /F 2>&1 | Out-Null } catch {}
            Write-Host "cleanup: stopped database emulator process tree PID $($dbProcess.Id)"
        }
        Stop-LocalPortListeners @($ports.database, $ports.auth, $ports.hub, $ports.logging)
    }
    if ($exitCode -ne 0 -or -not $sawOk) {
        Write-Host "firebase-rules-emulator FAILED (exit=$exitCode, ok-marker=$sawOk)"
        exit 1
    }
    exit 0
}

# =====================================================================================
# Runner (executed inside `firebase emulators:exec`)
# =====================================================================================
if ($AuthPort -le 0 -or $DatabasePort -le 0) { throw "Runner needs -AuthPort and -DatabasePort." }

Add-Type -AssemblyName System.Net.Http
$handler = New-Object System.Net.Http.HttpClientHandler
$handler.UseProxy = $false
$handler.AllowAutoRedirect = $false
$http = New-Object System.Net.Http.HttpClient($handler)
$http.Timeout = [TimeSpan]::FromSeconds(60)

$namespace = "$ProjectId-default-rtdb"
$dbBase = "http://127.0.0.1:$DatabasePort"
$authBase = "http://127.0.0.1:$AuthPort"
$ownerHeaders = @{ Authorization = "Bearer owner" }
$script:caseResults = New-Object System.Collections.Generic.List[object]

function Invoke-Http {
    param([string]$Method, [string]$Url, $Body = $null, [hashtable]$Headers = @{})
    $request = New-Object System.Net.Http.HttpRequestMessage((New-Object System.Net.Http.HttpMethod($Method)), $Url)
    foreach ($key in $Headers.Keys) { [void]$request.Headers.TryAddWithoutValidation($key, [string]$Headers[$key]) }
    if ($null -ne $Body) {
        $text = if ($Body -is [string]) { $Body } else { ConvertTo-Json -InputObject $Body -Depth 30 -Compress }
        $request.Content = New-Object System.Net.Http.StringContent($text, [System.Text.Encoding]::UTF8, "application/json")
    }
    $response = $http.SendAsync($request).GetAwaiter().GetResult()
    $content = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
    $etag = $null
    $values = $null
    if ($response.Headers.TryGetValues("ETag", [ref]$values)) { $etag = @($values)[0] }
    return [pscustomobject]@{ Status = [int]$response.StatusCode; Body = $content; ETag = $etag }
}

function Get-DbUrl {
    param([string]$Path, [string]$Token = "", [string]$Query = "")
    $clean = $Path.Trim("/")
    $url = if ($clean) { "$dbBase/$clean.json" } else { "$dbBase/.json" }
    $parts = @()
    if ($Query) { $parts += $Query }
    $parts += "ns=$namespace"
    if ($Token) { $parts += "auth=$([Uri]::EscapeDataString($Token))" }
    return "${url}?$($parts -join '&')"
}

# Mirrors the client: writes go through `?print=silent&auth=<idToken>`.
function Invoke-Db {
    param([string]$Method, [string]$Path, $Body = $null, [string]$Token = "", [string]$Query = "", [hashtable]$Headers = @{})
    return Invoke-Http -Method $Method -Url (Get-DbUrl -Path $Path -Token $Token -Query $Query) -Body $Body -Headers $Headers
}

function Invoke-Admin {
    param([string]$Method, [string]$Path, $Body = $null)
    $r = Invoke-Http -Method $Method -Url (Get-DbUrl -Path $Path) -Body $Body -Headers $ownerHeaders
    if ($r.Status -lt 200 -or $r.Status -ge 300) { throw "Admin $Method $Path failed: HTTP $($r.Status) $($r.Body)" }
    return $r
}

function Assert-Case {
    param([string]$Name, [ValidateSet("allow", "deny", "conflict")][string]$Expected, $Response)
    $status = [int]$Response.Status
    $actual = if ($status -ge 200 -and $status -lt 300) { "allow" } elseif ($status -eq 401 -or $status -eq 403) { "deny" } elseif ($status -eq 412) { "conflict" } else { "http$status" }
    $ok = $actual -eq $Expected
    Write-Host ("RULES_CASE name={0} expected={1} actual={2} ok={3} status={4}" -f $Name, $Expected, $actual, $ok.ToString().ToLowerInvariant(), $status)
    if (-not $ok) {
        $detail = [string]$Response.Body
        if ($detail.Length -gt 300) { $detail = $detail.Substring(0, 300) + "..." }
        Write-Host "  mismatch detail: $detail"
    }
    $script:caseResults.Add([pscustomobject]@{ Name = $Name; Expected = $Expected; Actual = $actual; Ok = $ok })
}

function Get-NowMs { return [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() }
function Get-NowUnix { return [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() }
function New-ServerTimestamp { return @{ ".sv" = "timestamp" } }

function Get-Sha256Text([string]$Text) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Text))) -replace "-", "").ToLowerInvariant() } finally { $sha.Dispose() }
}

function New-RandomHex([int]$Length) {
    $bytes = New-Object byte[] ([int][Math]::Ceiling($Length / 2))
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    return (([BitConverter]::ToString($bytes) -replace "-", "").ToLowerInvariant()).Substring(0, $Length)
}

# LeaderboardProfile.make_player_id(): legacy 0.5.3 authless ids are "p" + 32 hex.
function New-LegacyPlayerId { return "p$(New-RandomHex 32)" }
# ChatState.make_message_id(now_unix): "m<unix>_<12 hex>".
function New-MessageId { return "m$(Get-NowUnix)_$(New-RandomHex 12)" }

function New-AnonymousUser([string]$Label) {
    $r = Invoke-Http -Method POST -Url "$authBase/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key" -Body @{ returnSecureToken = $true }
    if ($r.Status -ne 200) { throw "Auth emulator signUp for $Label failed: HTTP $($r.Status) $($r.Body)" }
    $data = $r.Body | ConvertFrom-Json
    if (-not $data.idToken -or -not $data.localId) { throw "Auth emulator signUp for $Label returned no idToken/localId." }
    Write-Host "setup: anonymous user $Label uid=$($data.localId)"
    return [pscustomobject]@{ Label = $Label; Uid = [string]$data.localId; Token = [string]$data.idToken }
}

# online_runtime.gd _start_queued_name_claim(): name_claims/<key> payload.
function New-NameClaimPayload($Uid, $Name, $Key, [int]$Avatar) {
    return [ordered]@{
        uid = $Uid; name = $Name; name_key = $Key; avatar_index = $Avatar
        created_at = (New-ServerTimestamp); updated_at = (New-ServerTimestamp); submitted_at_unix = (Get-NowUnix)
    }
}

# online_runtime.gd _profile_recovery_record().
function New-ProfilePayload($Uid, $Name, $Key, [int]$Avatar, $Provider = "anonymous") {
    return [ordered]@{
        uid = $Uid; display_name = $Name; name_key = $Key; avatar_index = $Avatar
        profile_claimed = $true; name_claim_verified = $true; auth_provider = $Provider
        updated_at = (New-ServerTimestamp); updated_at_unix = (Get-NowUnix)
    }
}

# online_runtime.gd _leaderboard_submit_scores(): scores/<category_key>/<uid> payload.
function New-ScorePayload($Name, $Key, [int]$Avatar, [long]$Score, [int]$SkillLevel = 0, [long]$TotalXp = 0) {
    return [ordered]@{
        name = $Name; name_key = $Key; avatar_index = $Avatar; score = $Score
        skill_level = $SkillLevel; total_xp = $TotalXp
        updated_at = (New-ServerTimestamp); submitted_at_unix = (Get-NowUnix)
    }
}

# online_runtime.gd gate payload for player_write_gates / user_write_gates.
function New-GatePayload { return [ordered]@{ updated_at = (New-ServerTimestamp); submitted_at_unix = (Get-NowUnix) } }

# ChatState.outgoing_message_payload() + remote_message_payload() (created_at -> server timestamp).
function New-ChatPayload($SenderId, $Name, [int]$TotalLevel, [int]$Avatar, $Text, $NameKey = "") {
    $payload = [ordered]@{
        sender_id = $SenderId; name = $Name; total_level = $TotalLevel; avatar_index = $Avatar; text = $Text
        created_at = (New-ServerTimestamp); created_at_unix = (Get-NowUnix); deleted = $false
    }
    if ($NameKey) { $payload["name_key"] = $NameKey }
    return $payload
}

# online_runtime.gd _cloud_save_record() / _cloud_save_archival_record().
function New-CloudSaveRecord($Uid, [string]$PayloadJson, [long]$Revision, [long]$TotalSkillXp, [int]$TotalLevel, [long]$SavedAt) {
    return [ordered]@{
        uid = $Uid; updated_at = (New-ServerTimestamp); updated_at_unix = (Get-NowUnix)
        save_schema_version = 2; saved_at = $SavedAt; total_skill_xp = $TotalSkillXp; total_level = $TotalLevel
        revision = $Revision; payload_checksum = (Get-Sha256Text $PayloadJson); payload_json = $PayloadJson
    }
}

function Set-ScoreGate($Uid, [switch]$Stale) {
    $value = if ($Stale) { (Get-NowMs) - 16 * 60 * 1000 } else { New-ServerTimestamp }
    [void](Invoke-Admin PUT "leaderboards/v1/player_write_gates/$Uid" ([ordered]@{ updated_at = $value; submitted_at_unix = (Get-NowUnix) }))
}

function Set-ChatGate($Uid, [switch]$Stale) {
    $value = if ($Stale) { (Get-NowMs) - 60 * 1000 } else { New-ServerTimestamp }
    [void](Invoke-Admin PUT "global_chat/v1/user_write_gates/$Uid" ([ordered]@{ updated_at = $value; submitted_at_unix = (Get-NowUnix) }))
}

$lb = "leaderboards/v1"
$chat = "global_chat/v1"
$cloud = "cloud_saves/v1"
$silent = "print=silent"
$categories = @("total_level", "skill_xp__fight", "skill_xp__thieving", "skill_xp__build", "skill_xp__woodcutting", "skill_xp__fishing", "medals_earned", "elite_heavenly")

try {
    # ---------------------------------------------------------------- rules load
    $rulesSource = Join-Path $workDir "database.rules.json"
    if (-not (Test-Path -LiteralPath $rulesSource)) { $rulesSource = $committedRulesPath }
    $rulesText = [System.IO.File]::ReadAllText($rulesSource)
    if ($rulesText -ne [System.IO.File]::ReadAllText($committedRulesPath)) { throw "Rules copy $rulesSource differs from the committed rules file." }
    $put = Invoke-Http -Method PUT -Url "$dbBase/.settings/rules.json?ns=$namespace" -Body $rulesText -Headers $ownerHeaders
    if ($put.Status -ne 200) { throw "Loading rules failed: HTTP $($put.Status) $($put.Body)" }
    $loaded = Invoke-Http -Method GET -Url "$dbBase/.settings/rules.json?ns=$namespace" -Headers $ownerHeaders
    if ($loaded.Status -ne 200 -or $loaded.Body -notmatch "leaderboards") { throw "Rules readback failed: HTTP $($loaded.Status)" }
    Write-Host "setup: committed rules loaded into namespace $namespace"

    $A = New-AnonymousUser "A"
    $B = New-AnonymousUser "B"
    $C = New-AnonymousUser "C"
    $D = New-AnonymousUser "D"
    $E = New-AnonymousUser "E"
    $aName = "Mossy Knight"; $aKey = "mossy_knight"; $aAvatar = 3
    $bName = "Ember Fox"; $bKey = "ember_fox"; $bAvatar = 11

    # ---------------------------------------------------------------- sanity
    Assert-Case "sanity_root_read_unauthenticated" deny (Invoke-Db GET "")
    Assert-Case "sanity_root_write_authenticated" deny (Invoke-Db PUT "anything" @{ x = 1 } $A.Token $silent)

    # ---------------------------------------------------------------- name claims / profiles
    # 0.6.0 client: PATCH leaderboards/v1 {name_claims/<key>, profiles_by_uid/<uid>}.
    Assert-Case "client_claim_name_and_profile_A" allow (Invoke-Db PATCH $lb @{
        "name_claims/$aKey" = (New-NameClaimPayload $A.Uid $aName $aKey $aAvatar)
        "profiles_by_uid/$($A.Uid)" = (New-ProfilePayload $A.Uid $aName $aKey $aAvatar)
    } $A.Token $silent)
    Assert-Case "client_claim_name_and_profile_B" allow (Invoke-Db PATCH $lb @{
        "name_claims/$bKey" = (New-NameClaimPayload $B.Uid $bName $bKey $bAvatar)
        "profiles_by_uid/$($B.Uid)" = (New-ProfilePayload $B.Uid $bName $bKey $bAvatar)
    } $B.Token $silent)
    Assert-Case "client_reclaim_own_name_retry_A" allow (Invoke-Db PATCH $lb @{
        "name_claims/$aKey" = (New-NameClaimPayload $A.Uid $aName $aKey $aAvatar)
        "profiles_by_uid/$($A.Uid)" = (New-ProfilePayload $A.Uid $aName $aKey $aAvatar)
    } $A.Token $silent)
    Assert-Case "claim_name_owned_by_other_uid" deny (Invoke-Db PATCH $lb @{
        "name_claims/$aKey" = (New-NameClaimPayload $C.Uid $aName $aKey 0)
        "profiles_by_uid/$($C.Uid)" = (New-ProfilePayload $C.Uid $aName $aKey 0)
    } $C.Token $silent)
    Assert-Case "claim_name_with_uid_field_of_other_user" deny (Invoke-Db PATCH $lb @{
        "name_claims/rogue_name" = (New-NameClaimPayload $B.Uid "Rogue Name" "rogue_name" 0)
    } $C.Token $silent)
    Assert-Case "rename_after_claim_profile_locked" deny (Invoke-Db PATCH $lb @{
        "name_claims/mossy_two" = (New-NameClaimPayload $A.Uid "Mossy Two" "mossy_two" $aAvatar)
        "profiles_by_uid/$($A.Uid)" = (New-ProfilePayload $A.Uid "Mossy Two" "mossy_two" $aAvatar)
    } $A.Token $silent)
    Assert-Case "legacy_053_unauth_name_claim" deny (Invoke-Db PATCH $lb @{
        "name_claims/legacy_name" = (New-NameClaimPayload (New-LegacyPlayerId) "Legacy Name" "legacy_name" 0)
    } "" $silent)
    Assert-Case "write_other_users_profile" deny (Invoke-Db PUT "$lb/profiles_by_uid/$($B.Uid)" (New-ProfilePayload $B.Uid $bName $bKey 5) $A.Token $silent)
    Assert-Case "profile_without_matching_name_claim" deny (Invoke-Db PUT "$lb/profiles_by_uid/$($C.Uid)" (New-ProfilePayload $C.Uid "Nobody Here" "nobody_here" 0) $C.Token $silent)
    Assert-Case "profile_avatar_index_above_19" deny (Invoke-Db PATCH $lb @{
        "name_claims/cap_test_c" = (New-NameClaimPayload $C.Uid "Cap Test C" "cap_test_c" 20)
        "profiles_by_uid/$($C.Uid)" = (New-ProfilePayload $C.Uid "Cap Test C" "cap_test_c" 20)
    } $C.Token $silent)
    Assert-Case "profile_auth_provider_not_allowed" deny (Invoke-Db PATCH $lb @{
        "name_claims/cap_test_c" = (New-NameClaimPayload $C.Uid "Cap Test C" "cap_test_c" 1)
        "profiles_by_uid/$($C.Uid)" = (New-ProfilePayload $C.Uid "Cap Test C" "cap_test_c" 1 "admin")
    } $C.Token $silent)
    Assert-Case "name_key_not_matching_path" deny (Invoke-Db PUT "$lb/name_claims/some_key" (New-NameClaimPayload $C.Uid "Other Key" "other_key" 1) $C.Token $silent)
    Assert-Case "self_issued_name_recovery_ticket" deny (Invoke-Db PUT "$lb/name_recovery_tickets/$bKey" ([ordered]@{ active = $true; target_uid = $C.Uid; expires_at = (Get-NowMs) + 3600000 }) $C.Token $silent)
    # Client GET profiles_by_uid/<uid>?auth=... (profile recovery lookup).
    Assert-Case "client_read_own_profile" allow (Invoke-Db GET "$lb/profiles_by_uid/$($A.Uid)" $null $A.Token)
    Assert-Case "client_read_own_missing_profile_null" allow (Invoke-Db GET "$lb/profiles_by_uid/$($D.Uid)" $null $D.Token)
    Assert-Case "read_other_users_profile" deny (Invoke-Db GET "$lb/profiles_by_uid/$($B.Uid)" $null $A.Token)
    Assert-Case "read_profile_unauthenticated" deny (Invoke-Db GET "$lb/profiles_by_uid/$($A.Uid)")
    Assert-Case "read_name_claims" deny (Invoke-Db GET "$lb/name_claims" $null $A.Token)

    # ---------------------------------------------------------------- scores
    $legacyId = New-LegacyPlayerId
    # 0.5.3 web/authless: PATCH leaderboards/v1 {scores/<cat>/p<32hex>: payload} with no auth.
    Assert-Case "legacy_053_unauth_score_write" deny (Invoke-Db PATCH $lb @{
        "scores/total_level/$legacyId" = (New-ScorePayload "Legacy Hero" "legacy_hero" 2 140 0 800000)
        "scores/skill_xp__fishing/$legacyId" = (New-ScorePayload "Legacy Hero" "legacy_hero" 2 240000 57 0)
    } "" $silent)
    Assert-Case "legacy_053_unauth_score_gate" deny (Invoke-Db PUT "$lb/player_write_gates/$legacyId" (New-GatePayload) "" $silent)
    Assert-Case "legacy_053_unauth_single_score_put" deny (Invoke-Db PUT "$lb/scores/total_level/$legacyId" (New-ScorePayload "Legacy Hero" "legacy_hero" 2 140 0 800000) "" $silent)

    # 0.6.0 client: PUT player_write_gates/<uid>, then PATCH leaderboards/v1 with every changed category.
    Assert-Case "client_score_gate_A" allow (Invoke-Db PUT "$lb/player_write_gates/$($A.Uid)" (New-GatePayload) $A.Token $silent)
    Assert-Case "client_score_multipath_A" allow (Invoke-Db PATCH $lb @{
        "scores/total_level/$($A.Uid)" = (New-ScorePayload $aName $aKey $aAvatar 142 0 812345)
        "scores/skill_xp__fishing/$($A.Uid)" = (New-ScorePayload $aName $aKey $aAvatar 245000 58 0)
        "scores/skill_xp__woodcutting/$($A.Uid)" = (New-ScorePayload $aName $aKey $aAvatar 98000 45 0)
        "scores/skill_xp__fight/$($A.Uid)" = (New-ScorePayload $aName $aKey $aAvatar 30500 31 0)
        "scores/medals_earned/$($A.Uid)" = (New-ScorePayload $aName $aKey $aAvatar 37 0 0)
        "scores/elite_heavenly/$($A.Uid)" = (New-ScorePayload $aName $aKey $aAvatar 2 0 0)
    } $A.Token $silent)
    Assert-Case "client_score_gate_B" allow (Invoke-Db PUT "$lb/player_write_gates/$($B.Uid)" (New-GatePayload) $B.Token $silent)
    Assert-Case "client_score_multipath_B" allow (Invoke-Db PATCH $lb @{
        "scores/total_level/$($B.Uid)" = (New-ScorePayload $bName $bKey $bAvatar 88 0 150000)
        "scores/skill_xp__thieving/$($B.Uid)" = (New-ScorePayload $bName $bKey $bAvatar 60000 40 0)
        "scores/skill_xp__build/$($B.Uid)" = (New-ScorePayload $bName $bKey $bAvatar 12000 22 0)
    } $B.Token $silent)

    # Cheat cases. The write gate is refreshed (admin) before each so the ONLY failing
    # condition is the one the case names. Payloads use the client's single-score shape
    # PATCH leaderboards/v1 {"scores/<cat>/<uid>": payload}.
    function Test-ScoreCase([string]$Name, [string]$Expected, $User, [string]$Category, $Payload, [string]$PathUid = "") {
        if (-not $PathUid) { $PathUid = $User.Uid }
        Set-ScoreGate $User.Uid
        Assert-Case $Name $Expected (Invoke-Db PATCH $lb @{ "scores/$Category/$PathUid" = $Payload } $User.Token $silent)
    }
    Test-ScoreCase "score_decrease_monotonic" deny $A "skill_xp__fishing" (New-ScorePayload $aName $aKey $aAvatar 240000 57 0)
    Test-ScoreCase "client_single_score_equal_value_retry" allow $A "skill_xp__fishing" (New-ScorePayload $aName $aKey $aAvatar 245000 58 0)
    Test-ScoreCase "total_level_total_xp_decrease" deny $A "total_level" (New-ScorePayload $aName $aKey $aAvatar 142 0 800000)
    Test-ScoreCase "total_level_above_495" deny $A "total_level" (New-ScorePayload $aName $aKey $aAvatar 496 0 900000)
    Test-ScoreCase "total_level_at_495_cap_allowed" allow $B "total_level" (New-ScorePayload $bName $bKey $bAvatar 495 0 160000)
    Test-ScoreCase "score_above_1e12" deny $A "skill_xp__woodcutting" (New-ScorePayload $aName $aKey $aAvatar 1000000000001 99 0)
    Test-ScoreCase "total_xp_above_1e12" deny $A "total_level" (New-ScorePayload $aName $aKey $aAvatar 142 0 1000000000001)
    Test-ScoreCase "skill_level_above_99" deny $A "skill_xp__woodcutting" (New-ScorePayload $aName $aKey $aAvatar 99000 100 0)
    Test-ScoreCase "score_negative" deny $A "skill_xp__thieving" (New-ScorePayload $aName $aKey $aAvatar -1 0 0)
    Test-ScoreCase "score_string_type" deny $A "medals_earned" ([ordered]@{ name = $aName; name_key = $aKey; avatar_index = $aAvatar; score = "999"; skill_level = 0; total_xp = 0; updated_at = (New-ServerTimestamp); submitted_at_unix = (Get-NowUnix) })
    $extra = New-ScorePayload $aName $aKey $aAvatar 38 0 0; $extra["verified"] = $true
    Test-ScoreCase "score_extra_field" deny $A "medals_earned" $extra
    $missing = New-ScorePayload $aName $aKey $aAvatar 38 0 0; $missing.Remove("submitted_at_unix")
    Test-ScoreCase "score_missing_required_field" deny $A "medals_earned" $missing
    $staleTs = New-ScorePayload $aName $aKey $aAvatar 38 0 0; $staleTs["updated_at"] = (Get-NowMs) - 10 * 60 * 1000
    Test-ScoreCase "score_client_supplied_stale_updated_at" deny $A "medals_earned" $staleTs
    Test-ScoreCase "retired_category_total_xp" deny $A "total_xp" (New-ScorePayload $aName $aKey $aAvatar 812345 0 812345)
    Test-ScoreCase "unknown_category" deny $A "skill_xp__cooking" (New-ScorePayload $aName $aKey $aAvatar 1000 10 0)
    Test-ScoreCase "score_impersonate_other_name" deny $A "medals_earned" (New-ScorePayload $bName $bKey $bAvatar 38 0 0)
    Test-ScoreCase "score_avatar_not_matching_profile" deny $A "medals_earned" (New-ScorePayload $aName $aKey 9 38 0 0)
    Test-ScoreCase "score_unclaimed_uid_guest" deny $D "medals_earned" (New-ScorePayload "guest0421" "guest0421" 0 5 0 0)
    Set-ScoreGate $B.Uid
    Test-ScoreCase "write_other_users_score" deny $A "total_level" (New-ScorePayload $bName $bKey $bAvatar 400 0 900000) $B.Uid

    # Throttle: gate rewrite within 15 minutes, raise without a fresh gate, then after cooldown.
    Assert-Case "score_gate_rewrite_within_15min" deny (Invoke-Db PUT "$lb/player_write_gates/$($A.Uid)" (New-GatePayload) $A.Token $silent)
    Set-ScoreGate $A.Uid -Stale
    Assert-Case "score_raise_with_stale_gate" deny (Invoke-Db PATCH $lb @{ "scores/skill_xp__fishing/$($A.Uid)" = (New-ScorePayload $aName $aKey $aAvatar 250000 58 0) } $A.Token $silent)
    Assert-Case "client_score_gate_after_cooldown" allow (Invoke-Db PUT "$lb/player_write_gates/$($A.Uid)" (New-GatePayload) $A.Token $silent)
    Assert-Case "client_score_raise_after_new_gate" allow (Invoke-Db PATCH $lb @{ "scores/skill_xp__fishing/$($A.Uid)" = (New-ScorePayload $aName $aKey $aAvatar 250000 58 0) } $A.Token $silent)
    # Row-cooldown branch: stale gate, but the stored row is older than 15 minutes.
    Set-ScoreGate $A.Uid -Stale
    $oldRow = New-ScorePayload $aName $aKey $aAvatar 37 0 0; $oldRow["updated_at"] = (Get-NowMs) - 20 * 60 * 1000
    [void](Invoke-Admin PUT "$lb/scores/medals_earned/$($A.Uid)" $oldRow)
    Assert-Case "score_raise_after_row_cooldown_without_gate" allow (Invoke-Db PATCH $lb @{ "scores/medals_earned/$($A.Uid)" = (New-ScorePayload $aName $aKey $aAvatar 40 0 0) } $A.Token $silent)
    Assert-Case "score_raise_again_inside_row_cooldown" deny (Invoke-Db PATCH $lb @{ "scores/medals_earned/$($A.Uid)" = (New-ScorePayload $aName $aKey $aAvatar 41 0 0) } $A.Token $silent)

    # ---------------------------------------------------------------- leaderboard reads (client GETs are unauthenticated)
    foreach ($category in $categories) {
        Assert-Case "client_read_leaderboard_$category" allow (Invoke-Db GET "$lb/scores/$category" $null "" 'orderBy=%22score%22&limitToLast=50')
    }
    $top = Invoke-Db GET "$lb/scores/total_level" $null "" 'orderBy=%22score%22&limitToLast=50'
    $topRows = $top.Body | ConvertFrom-Json
    if (-not ($topRows.PSObject.Properties.Name -contains $A.Uid) -or [long]$topRows.($A.Uid).score -ne 142 -or [long]$topRows.($A.Uid).updated_at -le 0) {
        throw "Leaderboard read did not return A's stored total_level row: $($top.Body)"
    }
    Assert-Case "read_leaderboard_limit_51" deny (Invoke-Db GET "$lb/scores/total_level" $null "" 'orderBy=%22score%22&limitToLast=51')
    Assert-Case "read_leaderboard_no_query" deny (Invoke-Db GET "$lb/scores/total_level")
    Assert-Case "read_leaderboard_order_by_name" deny (Invoke-Db GET "$lb/scores/total_level" $null "" 'orderBy=%22name%22&limitToLast=50')
    Assert-Case "read_leaderboard_limit_to_first" deny (Invoke-Db GET "$lb/scores/total_level" $null "" 'orderBy=%22score%22&limitToFirst=50')
    Assert-Case "read_leaderboard_retired_total_xp" deny (Invoke-Db GET "$lb/scores/total_xp" $null "" 'orderBy=%22score%22&limitToLast=50')
    Assert-Case "read_all_scores" deny (Invoke-Db GET "$lb/scores" $null $A.Token)
    Assert-Case "read_player_write_gates" deny (Invoke-Db GET "$lb/player_write_gates" $null $A.Token)
    Assert-Case "read_name_recovery_tickets" deny (Invoke-Db GET "$lb/name_recovery_tickets" $null $A.Token)

    # ---------------------------------------------------------------- chat
    # 0.6.0 client: PUT global_chat/v1/user_write_gates/<uid>, then PUT messages/<id>.
    $aMessages = New-Object System.Collections.Generic.List[string]
    Assert-Case "client_chat_gate_A" allow (Invoke-Db PUT "$chat/user_write_gates/$($A.Uid)" (New-GatePayload) $A.Token $silent)
    $mid = New-MessageId
    Assert-Case "client_chat_message_claimed_A" allow (Invoke-Db PUT "$chat/messages/$mid" (New-ChatPayload $A.Uid $aName 142 $aAvatar "hello from the rules test" $aKey) $A.Token $silent)
    $aMessages.Add($mid)
    Assert-Case "chat_gate_rewrite_within_2s" deny (Invoke-Db PUT "$chat/user_write_gates/$($A.Uid)" (New-GatePayload) $A.Token $silent)
    Start-Sleep -Milliseconds 2300
    Assert-Case "client_chat_gate_after_2s" allow (Invoke-Db PUT "$chat/user_write_gates/$($A.Uid)" (New-GatePayload) $A.Token $silent)
    $mid = New-MessageId
    Assert-Case "client_chat_message_80_chars" allow (Invoke-Db PUT "$chat/messages/$mid" (New-ChatPayload $A.Uid $aName 142 $aAvatar ("x" * 80) $aKey) $A.Token $silent)
    $aMessages.Add($mid)
    # Guest (unclaimed guestNNNN name, no name_key).
    Assert-Case "client_chat_gate_guest_D" allow (Invoke-Db PUT "$chat/user_write_gates/$($D.Uid)" (New-GatePayload) $D.Token $silent)
    Assert-Case "client_chat_message_guest_D" allow (Invoke-Db PUT "$chat/messages/$(New-MessageId)" (New-ChatPayload $D.Uid "guest0421" 3 0 "hi all") $D.Token $silent)
    # Chat reads (client GET/stream: orderBy="created_at"&limitToLast=2 or 25, no auth).
    Assert-Case "client_read_chat_limit_25" allow (Invoke-Db GET "$chat/messages" $null "" 'orderBy=%22created_at%22&limitToLast=25')
    Assert-Case "client_read_chat_limit_2" allow (Invoke-Db GET "$chat/messages" $null "" 'orderBy=%22created_at%22&limitToLast=2')
    Assert-Case "read_chat_limit_26" deny (Invoke-Db GET "$chat/messages" $null "" 'orderBy=%22created_at%22&limitToLast=26')
    Assert-Case "read_chat_no_query" deny (Invoke-Db GET "$chat/messages")
    Assert-Case "read_chat_user_write_gates" deny (Invoke-Db GET "$chat/user_write_gates" $null $A.Token)
    Assert-Case "read_chat_moderation_logs" deny (Invoke-Db GET "$chat/moderation_logs" $null $A.Token)

    function Test-ChatCase([string]$Name, [string]$Expected, $User, $Payload, [string]$MessageId = "") {
        if (-not $MessageId) { $MessageId = New-MessageId }
        Set-ChatGate $User.Uid
        Assert-Case $Name $Expected (Invoke-Db PUT "$chat/messages/$MessageId" $Payload $User.Token $silent)
    }
    Set-ChatGate $A.Uid -Stale
    Assert-Case "chat_message_without_fresh_gate" deny (Invoke-Db PUT "$chat/messages/$(New-MessageId)" (New-ChatPayload $A.Uid $aName 142 $aAvatar "no gate" $aKey) $A.Token $silent)
    Set-ChatGate $B.Uid
    Test-ChatCase "chat_spoof_sender_id" deny $A (New-ChatPayload $B.Uid $bName 88 $bAvatar "I am B" $bKey)
    Test-ChatCase "chat_impersonate_claimed_name" deny $A (New-ChatPayload $A.Uid $bName 142 $bAvatar "I am B" $bKey)
    Test-ChatCase "chat_claimed_name_without_name_key" deny $D (New-ChatPayload $D.Uid $aName 3 0 "no key")
    Test-ChatCase "chat_text_81_chars" deny $A (New-ChatPayload $A.Uid $aName 142 $aAvatar ("x" * 81) $aKey)
    Test-ChatCase "chat_avatar_not_matching_profile" deny $A (New-ChatPayload $A.Uid $aName 142 9 "wrong avatar" $aKey)
    $old = New-ChatPayload $A.Uid $aName 142 $aAvatar "backdated" $aKey; $old["created_at"] = (Get-NowMs) - 10 * 60 * 1000
    Test-ChatCase "chat_client_supplied_old_created_at" deny $A $old
    $pre = New-ChatPayload $A.Uid $aName 142 $aAvatar "pre-deleted" $aKey; $pre["deleted"] = $true
    Test-ChatCase "chat_create_as_deleted" deny $A $pre
    Test-ChatCase "chat_message_id_too_short" deny $A (New-ChatPayload $A.Uid $aName 142 $aAvatar "short id" $aKey) "m1"
    Assert-Case "legacy_053_unauth_chat_patch" deny (Invoke-Db PATCH $chat @{
        "messages/$(New-MessageId)" = (New-ChatPayload $legacyId "guest1234" 5 0 "legacy hello")
        "user_write_gates/$legacyId" = (New-GatePayload)
    } "" $silent)
    Assert-Case "legacy_053_unauth_chat_put" deny (Invoke-Db PUT "$chat/messages/$(New-MessageId)" (New-ChatPayload $legacyId "guest1234" 5 0 "legacy hello") "" $silent)
    # Edits / deletes of existing messages.
    $firstMessage = Invoke-Admin GET "$chat/messages/$($aMessages[0])"
    $stored = $firstMessage.Body | ConvertFrom-Json
    $edited = [ordered]@{ sender_id = $A.Uid; name = $aName; name_key = $aKey; total_level = 142; avatar_index = $aAvatar; text = "edited text"; created_at = [long]$stored.created_at; created_at_unix = [long]$stored.created_at_unix; deleted = $false }
    Assert-Case "chat_edit_own_message_text" deny (Invoke-Db PUT "$chat/messages/$($aMessages[0])" $edited $A.Token $silent)
    $softDelete = [ordered]@{ sender_id = $A.Uid; name = $aName; name_key = $aKey; total_level = 142; avatar_index = $aAvatar; text = [string]$stored.text; created_at = [long]$stored.created_at; created_at_unix = [long]$stored.created_at_unix; deleted = $true }
    Assert-Case "chat_non_moderator_soft_delete" deny (Invoke-Db PUT "$chat/messages/$($aMessages[0])" $softDelete $A.Token $silent)
    Assert-Case "chat_hard_delete_own_message" deny (Invoke-Db DELETE "$chat/messages/$($aMessages[0])" $null $A.Token $silent)
    $hijack = [ordered]@{ sender_id = $B.Uid; name = $bName; name_key = $bKey; total_level = 88; avatar_index = $bAvatar; text = [string]$stored.text; created_at = [long]$stored.created_at; created_at_unix = [long]$stored.created_at_unix; deleted = $false }
    Assert-Case "chat_other_user_rewrites_message" deny (Invoke-Db PUT "$chat/messages/$($aMessages[0])" $hijack $B.Token $silent)
    Assert-Case "chat_moderation_log_by_player" deny (Invoke-Db PUT "$chat/moderation_logs/log_$(New-RandomHex 8)" ([ordered]@{ message_id = $aMessages[0]; moderator_id = $A.Uid; reason = "x"; created_at = (New-ServerTimestamp); created_at_unix = (Get-NowUnix) }) $A.Token $silent)

    # ---------------------------------------------------------------- cloud saves (A)
    $savedAt = Get-NowUnix
    $payload1 = '{"save_schema_version":2,"saved_at":' + $savedAt + ',"skills":{"fishing":{"xp":245000},"woodcutting":{"xp":98000},"fight":{"xp":30500},"thieving":{"xp":0},"build":{"xp":0}},"gold":1234,"leaderboard_display_name":"Mossy Knight"}'
    $payload2 = $payload1.Replace('"gold":1234', '"gold":1500')
    $etagHeaders = @{ "X-Firebase-ETag" = "true" }
    # Fetch: GET users/<uid>?auth=... with X-Firebase-ETag: true.
    $fetch = Invoke-Db GET "$cloud/users/$($A.Uid)" $null $A.Token "" $etagHeaders
    Assert-Case "client_cloud_save_fetch_own_empty" allow $fetch
    $etag = if ($fetch.ETag) { $fetch.ETag } else { "null_etag" }
    $rec1 = New-CloudSaveRecord $A.Uid $payload1 1 373500 142 $savedAt
    # Exact 0.6.0 request (online_runtime.gd _start_cloud_save_put): PUT users/<uid>?auth=... (no print=silent;
    # Firebase rejects print=silent together with if-match) and headers X-Firebase-ETag: true, if-match: <etag or null_etag>.
    $exact = Invoke-Db PUT "$cloud/users/$($A.Uid)" $rec1 $A.Token "" @{ "X-Firebase-ETag" = "true"; "if-match" = $etag }
    Assert-Case "client_cloud_save_put_rev1_exact_request" allow $exact
    Assert-Case "client_cloud_history_snapshot_rev1_slot1" allow (Invoke-Db PUT "$cloud/history/$($A.Uid)/slots/1" $rec1 $A.Token $silent)
    $fetch = Invoke-Db GET "$cloud/users/$($A.Uid)" $null $A.Token "" $etagHeaders
    Assert-Case "client_cloud_save_fetch_own" allow $fetch
    if (-not $fetch.ETag) { throw "Cloud save GET with X-Firebase-ETag returned no ETag header." }
    # Next session: archive the fetched current record (same revision, same payload text) before replacing.
    $archival = New-CloudSaveRecord $A.Uid $payload1 1 373500 142 $savedAt
    Assert-Case "client_cloud_history_before_replace_same_payload" allow (Invoke-Db PUT "$cloud/history/$($A.Uid)/slots/1" $archival $A.Token $silent)
    $rec2 = New-CloudSaveRecord $A.Uid $payload2 2 373500 142 (Get-NowUnix)
    Assert-Case "cloud_save_put_stale_etag_precondition" conflict (Invoke-Db PUT "$cloud/users/$($A.Uid)" $rec2 $A.Token "" @{ "X-Firebase-ETag" = "true"; "if-match" = "stale-etag-value" })
    $exact = Invoke-Db PUT "$cloud/users/$($A.Uid)" $rec2 $A.Token "" @{ "X-Firebase-ETag" = "true"; "if-match" = $fetch.ETag }
    Assert-Case "client_cloud_save_put_rev2_exact_request" allow $exact
    Assert-Case "client_cloud_history_snapshot_rev2_slot2" allow (Invoke-Db PUT "$cloud/history/$($A.Uid)/slots/2" $rec2 $A.Token $silent)
    Assert-Case "client_cloud_history_fetch_own" allow (Invoke-Db GET "$cloud/history/$($A.Uid)/slots" $null $A.Token)
    # Cheats / invalid shapes (no if-match, so only the rules decide).
    Assert-Case "cloud_save_revision_skip" deny (Invoke-Db PUT "$cloud/users/$($A.Uid)" (New-CloudSaveRecord $A.Uid $payload2 4 373500 142 (Get-NowUnix)) $A.Token $silent)
    Assert-Case "cloud_save_revision_not_incremented" deny (Invoke-Db PUT "$cloud/users/$($A.Uid)" (New-CloudSaveRecord $A.Uid $payload2 2 373500 142 (Get-NowUnix)) $A.Token $silent)
    $noRev = New-CloudSaveRecord $A.Uid $payload2 3 373500 142 (Get-NowUnix); $noRev.Remove("revision"); $noRev.Remove("payload_checksum")
    Assert-Case "cloud_save_legacy_unrevisioned_over_revisioned" deny (Invoke-Db PUT "$cloud/users/$($A.Uid)" $noRev $A.Token $silent)
    $badUid = New-CloudSaveRecord $A.Uid $payload2 3 373500 142 (Get-NowUnix); $badUid["uid"] = $B.Uid
    Assert-Case "cloud_save_uid_field_mismatch" deny (Invoke-Db PUT "$cloud/users/$($A.Uid)" $badUid $A.Token $silent)
    $badSum = New-CloudSaveRecord $A.Uid $payload2 3 373500 142 (Get-NowUnix); $badSum["payload_checksum"] = "not-a-sha256"
    Assert-Case "cloud_save_bad_checksum_format" deny (Invoke-Db PUT "$cloud/users/$($A.Uid)" $badSum $A.Token $silent)
    $extraSave = New-CloudSaveRecord $A.Uid $payload2 3 373500 142 (Get-NowUnix); $extraSave["admin"] = $true
    Assert-Case "cloud_save_extra_field" deny (Invoke-Db PUT "$cloud/users/$($A.Uid)" $extraSave $A.Token $silent)
    Assert-Case "cloud_save_payload_over_950000_chars" deny (Invoke-Db PUT "$cloud/users/$($A.Uid)" (New-CloudSaveRecord $A.Uid ("x" * 950001) 3 373500 142 (Get-NowUnix)) $A.Token $silent)
    Assert-Case "write_other_users_cloud_save" deny (Invoke-Db PUT "$cloud/users/$($B.Uid)" (New-CloudSaveRecord $B.Uid $payload1 1 1 1 (Get-NowUnix)) $A.Token $silent)
    Assert-Case "read_other_users_cloud_save" deny (Invoke-Db GET "$cloud/users/$($A.Uid)" $null $B.Token)
    Assert-Case "read_cloud_save_unauthenticated" deny (Invoke-Db GET "$cloud/users/$($A.Uid)")
    Assert-Case "cloud_history_slot_5_out_of_range" deny (Invoke-Db PUT "$cloud/history/$($A.Uid)/slots/5" $rec2 $A.Token $silent)
    Assert-Case "cloud_history_older_revision_over_newer" deny (Invoke-Db PUT "$cloud/history/$($A.Uid)/slots/2" (New-CloudSaveRecord $A.Uid $payload1 1 373500 142 $savedAt) $A.Token $silent)
    # Same revision, different payload text (e.g. a re-serialized archival record) is rejected.
    $reserialized = $payload1.Replace('"thieving":{"xp":0}', '"thieving":{"xp":0.0}')
    Assert-Case "cloud_history_same_revision_different_payload" deny (Invoke-Db PUT "$cloud/history/$($A.Uid)/slots/1" (New-CloudSaveRecord $A.Uid $reserialized 1 373500 142 $savedAt) $A.Token $silent)
    Assert-Case "write_other_users_cloud_history" deny (Invoke-Db PUT "$cloud/history/$($B.Uid)/slots/1" (New-CloudSaveRecord $B.Uid $payload1 1 1 1 $savedAt) $A.Token $silent)
    Assert-Case "read_other_users_cloud_history" deny (Invoke-Db GET "$cloud/history/$($A.Uid)/slots" $null $B.Token)

    # ---------------------------------------------------------------- profile reference refresh (avatar change)
    # 0.6.0 client _refresh_profile_references(): canonical PATCH at DB root, then reference PATCH at DB root.
    $newAvatar = 7
    Assert-Case "client_profile_refresh_canonical_avatar_change" allow (Invoke-Db PATCH "" @{
        "leaderboards/v1/name_claims/$aKey" = (New-NameClaimPayload $A.Uid $aName $aKey $newAvatar)
        "leaderboards/v1/profiles_by_uid/$($A.Uid)" = (New-ProfilePayload $A.Uid $aName $aKey $newAvatar)
    } $A.Token $silent)
    Set-ScoreGate $A.Uid -Stale  # no fresh gate: the client does not write one for reference refreshes
    $refUpdates = @{}
    foreach ($category in $categories) {
        $row = (Invoke-Admin GET "$lb/scores/$category/$($A.Uid)").Body | ConvertFrom-Json
        if ($null -eq $row) { continue }
        $totalXp = if ($category -eq "total_level") { 812345 } else { 0 }
        $refUpdates["leaderboards/v1/scores/$category/$($A.Uid)"] = (New-ScorePayload $aName $aKey $newAvatar ([long]$row.score) ([int]$row.skill_level) $totalXp)
    }
    foreach ($messageId in $aMessages) {
        $m = (Invoke-Admin GET "$chat/messages/$messageId").Body | ConvertFrom-Json
        $refUpdates["global_chat/v1/messages/$messageId"] = [ordered]@{
            sender_id = $A.Uid; name = $aName; name_key = $aKey; total_level = 143; avatar_index = $newAvatar
            text = [string]$m.text; created_at = [long]$m.created_at; created_at_unix = [long]$m.created_at_unix; deleted = $false
        }
    }
    Assert-Case "client_profile_refresh_references_scores_and_chat" allow (Invoke-Db PATCH "" $refUpdates $A.Token $silent)
    Assert-Case "reference_refresh_cannot_raise_score_without_gate" deny (Invoke-Db PATCH "" @{
        "leaderboards/v1/scores/skill_xp__fishing/$($A.Uid)" = (New-ScorePayload $aName $aKey $newAvatar 999999 70 0)
    } $A.Token $silent)

    # ---------------------------------------------------------------- legacy username transfer (support ticket)
    $legacyOwner = New-LegacyPlayerId
    $legacyClaim = [ordered]@{ uid = $legacyOwner; name = "Old Hero"; name_key = "old_hero"; avatar_index = 4; created_at = (Get-NowMs) - 86400000; updated_at = (Get-NowMs) - 86400000; submitted_at_unix = (Get-NowUnix) - 86400 }
    [void](Invoke-Admin PUT "$lb/name_claims/old_hero" $legacyClaim)
    [void](Invoke-Admin PUT "$lb/name_recovery_tickets/old_hero" ([ordered]@{ active = $true; target_uid = $C.Uid; expires_at = (Get-NowMs) + 3600000 }))
    function New-TransferUpdates($User, [string]$OldUid) {
        return @{
            "name_claims/old_hero" = (New-NameClaimPayload $User.Uid "Old Hero" "old_hero" 4)
            "profiles_by_uid/$($User.Uid)" = (New-ProfilePayload $User.Uid "Old Hero" "old_hero" 4)
            "name_recovery_gates/$($User.Uid)" = [ordered]@{ name_key = "old_hero"; old_uid = $OldUid; target_uid = $User.Uid; updated_at = (New-ServerTimestamp) }
        }
    }
    Assert-Case "transfer_without_ticket_for_uid" deny (Invoke-Db PATCH $lb (New-TransferUpdates $E $legacyOwner) $E.Token $silent)
    Assert-Case "transfer_with_wrong_old_uid" deny (Invoke-Db PATCH $lb (New-TransferUpdates $C (New-LegacyPlayerId)) $C.Token $silent)
    Assert-Case "transfer_claim_without_gate" deny (Invoke-Db PATCH $lb @{
        "name_claims/old_hero" = (New-NameClaimPayload $C.Uid "Old Hero" "old_hero" 4)
        "profiles_by_uid/$($C.Uid)" = (New-ProfilePayload $C.Uid "Old Hero" "old_hero" 4)
    } $C.Token $silent)
    Assert-Case "client_transfer_with_ticket" allow (Invoke-Db PATCH $lb (New-TransferUpdates $C $legacyOwner) $C.Token $silent)
    Assert-Case "client_score_gate_after_transfer" allow (Invoke-Db PUT "$lb/player_write_gates/$($C.Uid)" (New-GatePayload) $C.Token $silent)
    Assert-Case "client_score_after_transfer" allow (Invoke-Db PATCH $lb @{ "scores/total_level/$($C.Uid)" = (New-ScorePayload "Old Hero" "old_hero" 4 120 0 500000) } $C.Token $silent)
    $legacyOwner2 = New-LegacyPlayerId
    [void](Invoke-Admin PUT "$lb/name_claims/old_rogue" ([ordered]@{ uid = $legacyOwner2; name = "Old Rogue"; name_key = "old_rogue"; avatar_index = 2; created_at = (Get-NowMs) - 86400000; updated_at = (Get-NowMs) - 86400000; submitted_at_unix = (Get-NowUnix) - 86400 }))
    [void](Invoke-Admin PUT "$lb/name_recovery_tickets/old_rogue" ([ordered]@{ active = $true; target_uid = $E.Uid; expires_at = (Get-NowMs) - 1000 }))
    Assert-Case "transfer_with_expired_ticket" deny (Invoke-Db PATCH $lb @{
        "name_claims/old_rogue" = (New-NameClaimPayload $E.Uid "Old Rogue" "old_rogue" 2)
        "profiles_by_uid/$($E.Uid)" = (New-ProfilePayload $E.Uid "Old Rogue" "old_rogue" 2)
        "name_recovery_gates/$($E.Uid)" = [ordered]@{ name_key = "old_rogue"; old_uid = $legacyOwner2; target_uid = $E.Uid; updated_at = (New-ServerTimestamp) }
    } $E.Token $silent)
    Assert-Case "legacy_owner_unauth_reclaim_after_transfer" deny (Invoke-Db PUT "$lb/name_claims/old_hero" (New-NameClaimPayload $legacyOwner "Old Hero" "old_hero" 4) "" $silent)

    # ---------------------------------------------------------------- leaderboard fresh start (returning 0.5.3 player)
    # The client signs a returning legacy player in with a brand-new anonymous UID and
    # re-claims the saved name through the canonical refresh (name claim + profile in
    # one root PATCH, as _profile_reference_updates() builds it). The legacy authless
    # claim blocks that until the one-time wipe deletes it; afterwards it must succeed
    # with no recovery ticket, and the repair publish must be accepted.
    $R = New-AnonymousUser "R"
    $returnerLegacyUid = New-LegacyPlayerId
    [void](Invoke-Admin PUT "$lb/name_claims/returner" ([ordered]@{ uid = $returnerLegacyUid; name = "Returner"; name_key = "returner"; avatar_index = 3; created_at = (Get-NowMs) - 86400000; updated_at = (Get-NowMs) - 86400000; submitted_at_unix = (Get-NowUnix) - 86400 }))
    [void](Invoke-Admin PUT "$lb/scores/total_level/$returnerLegacyUid" ([ordered]@{ name = "Returner"; name_key = "returner"; avatar_index = 3; score = 150; skill_level = 0; total_xp = 900000; updated_at = (Get-NowMs) - 86400000; submitted_at_unix = (Get-NowUnix) - 86400 }))
    function New-FreshStartReclaimUpdates($User) {
        return @{
            "leaderboards/v1/name_claims/returner" = (New-NameClaimPayload $User.Uid "Returner" "returner" 3)
            "leaderboards/v1/profiles_by_uid/$($User.Uid)" = (New-ProfilePayload $User.Uid "Returner" "returner" 3)
        }
    }
    Assert-Case "fresh_start_missing_profile_read_is_null" allow (Invoke-Db GET "$lb/profiles_by_uid/$($R.Uid)" $null $R.Token)
    Assert-Case "fresh_start_reclaim_while_legacy_claim_exists" deny (Invoke-Db PATCH "" (New-FreshStartReclaimUpdates $R) $R.Token $silent)
    Assert-Case "fresh_start_claim_only_while_legacy_claim_exists" deny (Invoke-Db PUT "$lb/name_claims/returner" (New-NameClaimPayload $R.Uid "Returner" "returner" 3) $R.Token $silent)
    # One-time wipe: delete legacy claims and score rows that belong to no Auth account.
    [void](Invoke-Admin DELETE "$lb/name_claims/returner")
    [void](Invoke-Admin DELETE "$lb/scores/total_level/$returnerLegacyUid")
    Assert-Case "fresh_start_reclaim_after_legacy_claim_deleted" allow (Invoke-Db PATCH "" (New-FreshStartReclaimUpdates $R) $R.Token $silent)
    Assert-Case "fresh_start_claim_probe_own_claim" allow (Invoke-Db PUT "$lb/name_claims/returner" (New-NameClaimPayload $R.Uid "Returner" "returner" 3) $R.Token $silent)
    Assert-Case "fresh_start_profile_read_after_reclaim" allow (Invoke-Db GET "$lb/profiles_by_uid/$($R.Uid)" $null $R.Token)
    Assert-Case "fresh_start_repair_publish_gate" allow (Invoke-Db PUT "$lb/player_write_gates/$($R.Uid)" (New-GatePayload) $R.Token $silent)
    Assert-Case "fresh_start_repair_publish_scores" allow (Invoke-Db PATCH $lb @{
        "scores/total_level/$($R.Uid)" = (New-ScorePayload "Returner" "returner" 3 150 0 900000)
        "scores/skill_xp__fishing/$($R.Uid)" = (New-ScorePayload "Returner" "returner" 3 240000 57 0)
    } $R.Token $silent)
    Assert-Case "fresh_start_legacy_uid_cannot_retake_name" deny (Invoke-Db PUT "$lb/name_claims/returner" (New-NameClaimPayload $returnerLegacyUid "Returner" "returner" 3) "" $silent)

    # ---------------------------------------------------------------- informational (documents current rule behavior)
    # A claimed user can reserve additional name keys without a profile (name_claims-only write).
    Assert-Case "info_extra_name_claim_without_profile_allowed" allow (Invoke-Db PUT "$lb/name_claims/mossy_spare" (New-NameClaimPayload $A.Uid "Mossy Spare" "mossy_spare" $newAvatar) $A.Token $silent)
} catch {
    Write-Host "RUNNER ERROR: $($_.Exception.Message)"
    Write-Host $_.ScriptStackTrace
    exit 2
} finally {
    $http.Dispose()
}

$failed = @($script:caseResults | Where-Object { -not $_.Ok })
Write-Host ("RULES_SUMMARY total={0} passed={1} failed={2}" -f $script:caseResults.Count, ($script:caseResults.Count - $failed.Count), $failed.Count)
if ($failed.Count -gt 0) {
    foreach ($f in $failed) { Write-Host "RULES_FAILED name=$($f.Name) expected=$($f.Expected) actual=$($f.Actual)" }
    exit 1
}
Write-Host "firebase-rules-emulator-ok"
exit 0
