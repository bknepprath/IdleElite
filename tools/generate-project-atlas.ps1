param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$OutputDirectory = (Join-Path (Split-Path -Parent $PSScriptRoot) "project-atlas")
)

$ErrorActionPreference = "Stop"
$projectPath = (Resolve-Path -LiteralPath $ProjectRoot).Path
$outputPath = [System.IO.Path]::GetFullPath($OutputDirectory)
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

if (-not (Test-Path -LiteralPath $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath | Out-Null
}

function Get-RelativeProjectPath {
    param([string]$FullName)
    return $FullName.Substring($projectPath.Length + 1).Replace("\", "/")
}

function Get-TopArea {
    param([string]$Path)

    $lower = $Path.ToLowerInvariant()
    if ($lower -match '^project-atlas/') { return "Atlas" }
    if ($lower -match '^(\.godot|\.codex-tmp|\.codex-tools|\.playwright-cli|tmp|test-results)/') { return "Generated and cache" }
    if ($lower -match '^(builds|output|outputs|release)/') { return "Builds and exports" }
    if ($lower -match '^(play-store|android)/' -or $lower -match '^assets/android/') { return "Android and Play Store" }
    if ($lower -match '^assets/') { return "Game assets" }
    if ($lower -match '^scenes/' -or $lower -match '^scripts/' -or $lower -eq 'project.godot') { return "Game source" }
    if ($lower -match '^addons/') { return "Add-ons" }
    if ($lower -match '^docs/' -or $lower -match '\.(md|pptx|xlsx|docx|pdf)$') { return "Planning and documents" }
    if ($lower -match '^tools/') { return "Tools" }
    return "Project support"
}

function Get-Lifecycle {
    param(
        [string]$Path,
        [string]$Area,
        [bool]$IsDirectRuntimeImage
    )

    $lower = $Path.ToLowerInvariant()
    if ($Area -eq "Generated and cache") { return "Review generated" }
    if ($Area -eq "Builds and exports") { return "Review artifact" }
    if ($Area -eq "Planning and documents") { return "Review purpose" }
    if ($Area -eq "Atlas") { return "Keep atlas" }
    if ($IsDirectRuntimeImage) { return "Keep referenced" }
    if ($Area -in @("Game source", "Add-ons")) { return "Keep operational" }
    if ($Area -eq "Game assets") { return "Verify asset" }
    if ($Area -eq "Android and Play Store") { return "Verify release" }
    return "Verify support"
}

function Test-PlanningFile {
    param([string]$Path, [string]$Extension)
    $lower = $Path.ToLowerInvariant()
    $documentExtension = $Extension -in @('.md', '.txt', '.html', '.htm', '.json', '.csv', '.pptx', '.xlsx', '.docx', '.pdf')
    return ($lower -match '(^|/)(docs?|plans?|planning|notes?|research|specs?|briefs?)(/|$)' -or
        $Extension -in @('.md', '.pptx', '.xlsx', '.docx', '.pdf') -or
        ($documentExtension -and $lower -match '(plan|roadmap|brief|pitch|checklist|runbook|status|audit|notes?)'))
}

function Test-PlayStoreFile {
    param([string]$Path)
    $lower = $Path.ToLowerInvariant()
    return ($lower -match '^(play-store|android)/' -or
        $lower -match '^assets/android/' -or
        $lower -match '\.(aab|apk|apks)$' -or
        $lower -match '(android|play-store|google-play|release-aab|launcher-(main|adaptive))')
}

function Test-SensitiveName {
    param([string]$Path)
    $lower = $Path.ToLowerInvariant()
    return ($lower -match '(^|/)(google key downloads|credentials?|secrets?|keystore|keys?)(/|$)' -or
        $lower -match '(service-account|firebase.*config|\.keystore$|\.jks$|\.pem$|\.p12$)')
}

$allFiles = @(Get-ChildItem -LiteralPath $projectPath -Recurse -Force -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch '[\\/]\.git([\\/]|$)' })

$tracked = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
Push-Location $projectPath
try {
    $trackedOutput = & git ls-files 2>$null
    foreach ($item in $trackedOutput) {
        if ($item) { [void]$tracked.Add($item.Replace("\", "/")) }
    }
}
finally {
    Pop-Location
}

$imageExtensions = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($extension in @('.png', '.jpg', '.jpeg', '.webp', '.gif', '.svg', '.bmp', '.tga', '.ico')) {
    [void]$imageExtensions.Add($extension)
}

$imagesByPath = @{}
foreach ($file in $allFiles) {
    if ($imageExtensions.Contains($file.Extension)) {
        $relative = Get-RelativeProjectPath $file.FullName
        $imagesByPath[$relative.ToLowerInvariant()] = $relative
    }
}

$runtimeReferenceExtensions = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($extension in @('.gd', '.tscn', '.tres', '.godot', '.cfg', '.json', '.gdshader')) {
    [void]$runtimeReferenceExtensions.Add($extension)
}

$referencesByImage = @{}
$pathPattern = [regex]'(?i)(?:res://)?(?<path>(?:assets|scenes|scripts)/[^"''\s\)\]\}>,;]+?\.(?:png|jpe?g|webp|gif|svg|bmp|tga|ico))'
foreach ($source in $allFiles) {
    if (-not $runtimeReferenceExtensions.Contains($source.Extension)) { continue }
    $sourceRelative = Get-RelativeProjectPath $source.FullName
    if ($sourceRelative -match '^(\.godot|\.codex-tmp|\.codex-tools|builds|output|outputs|tmp|test-results|android/build)/') { continue }
    if ($source.Length -gt 20MB) { continue }

    try {
        $content = [System.IO.File]::ReadAllText($source.FullName)
    }
    catch {
        continue
    }

    foreach ($match in $pathPattern.Matches($content)) {
        $candidate = $match.Groups['path'].Value.Replace("\", "/").TrimStart('/')
        $candidateKey = $candidate.ToLowerInvariant()
        if (-not $imagesByPath.ContainsKey($candidateKey)) { continue }
        $canonical = $imagesByPath[$candidateKey]
        if (-not $referencesByImage.ContainsKey($canonical)) {
            $referencesByImage[$canonical] = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        }
        [void]$referencesByImage[$canonical].Add($sourceRelative)
    }
}

$records = [System.Collections.Generic.List[object]]::new()
$areaSummary = @{}
$extensionSummary = @{}
$imageSummary = [ordered]@{
    all = [ordered]@{ count = 0; bytes = [int64]0 }
    game = [ordered]@{ count = 0; bytes = [int64]0 }
    direct = [ordered]@{ count = 0; bytes = [int64]0 }
    no_direct = [ordered]@{ count = 0; bytes = [int64]0 }
    store = [ordered]@{ count = 0; bytes = [int64]0 }
    support = [ordered]@{ count = 0; bytes = [int64]0 }
    imported_texture_cache = [ordered]@{ count = 0; bytes = [int64]0 }
}

foreach ($file in $allFiles) {
    $relative = Get-RelativeProjectPath $file.FullName
    $extension = $file.Extension.ToLowerInvariant()
    if (-not $extension) { $extension = '[none]' }
    $area = Get-TopArea $relative
    $isImage = $imageExtensions.Contains($file.Extension)
    $isGameImage = $isImage -and $relative -match '^assets/' -and $relative -notmatch '^assets/android/'
    $isDirectImage = $isImage -and $referencesByImage.ContainsKey($relative)
    $imageState = ""
    if ($isImage) {
        $imageSummary.all.count++
        $imageSummary.all.bytes += $file.Length
        if ($isGameImage) {
            $imageSummary.game.count++
            $imageSummary.game.bytes += $file.Length
            if ($isDirectImage) {
                $imageState = "Direct runtime reference"
                $imageSummary.direct.count++
                $imageSummary.direct.bytes += $file.Length
            }
            else {
                $imageState = "No direct runtime reference"
                $imageSummary.no_direct.count++
                $imageSummary.no_direct.bytes += $file.Length
            }
        }
        elseif (Test-PlayStoreFile $relative) {
            $imageState = "Store or Android"
            $imageSummary.store.count++
            $imageSummary.store.bytes += $file.Length
        }
        else {
            $imageState = "Support or generated"
            $imageSummary.support.count++
            $imageSummary.support.bytes += $file.Length
        }
    }
    elseif ($file.Extension -ieq '.ctex') {
        $imageSummary.imported_texture_cache.count++
        $imageSummary.imported_texture_cache.bytes += $file.Length
    }

    $flags = 0
    if (Test-PlayStoreFile $relative) { $flags = $flags -bor 1 }
    if (Test-PlanningFile $relative $file.Extension.ToLowerInvariant()) { $flags = $flags -bor 2 }
    if ($file.Extension -ieq '.html' -or $file.Extension -ieq '.htm') { $flags = $flags -bor 4 }
    if (Test-SensitiveName $relative) { $flags = $flags -bor 8 }
    if ($area -eq 'Generated and cache') { $flags = $flags -bor 16 }
    if ($area -in @('Game source', 'Game assets')) { $flags = $flags -bor 32 }

    $lifecycle = Get-Lifecycle $relative $area $isDirectImage
    $record = @(
        $relative,
        [int64]$file.Length,
        $extension,
        $area,
        $lifecycle,
        $tracked.Contains($relative),
        $flags,
        $imageState,
        $file.LastWriteTime.ToString('yyyy-MM-dd')
    )
    $records.Add($record)

    if (-not $areaSummary.ContainsKey($area)) { $areaSummary[$area] = [ordered]@{ count = 0; bytes = [int64]0 } }
    $areaSummary[$area].count++
    $areaSummary[$area].bytes += $file.Length
    if (-not $extensionSummary.ContainsKey($extension)) { $extensionSummary[$extension] = [ordered]@{ count = 0; bytes = [int64]0 } }
    $extensionSummary[$extension].count++
    $extensionSummary[$extension].bytes += $file.Length
}

$referencePayload = [ordered]@{}
foreach ($entry in $referencesByImage.GetEnumerator() | Sort-Object Key) {
    $referencePayload[$entry.Key] = @($entry.Value | Sort-Object)
}

$dependencyGroups = @{}
foreach ($entry in $referencesByImage.GetEnumerator()) {
    foreach ($source in $entry.Value) {
        $group = ($source -split '/')[0]
        if (-not $dependencyGroups.ContainsKey($group)) { $dependencyGroups[$group] = [ordered]@{ links = 0; images = [System.Collections.Generic.HashSet[string]]::new() } }
        $dependencyGroups[$group].links++
        [void]$dependencyGroups[$group].images.Add($entry.Key)
    }
}
$dependencyPayload = @($dependencyGroups.GetEnumerator() | ForEach-Object {
    [ordered]@{ group = $_.Key; images = $_.Value.images.Count; links = $_.Value.links }
} | Sort-Object images -Descending)

$payload = [ordered]@{
    generated_at = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss zzz')
    project_root = $projectPath
    scope = 'All files below the project root except .git internal metadata.'
    field_guide = @('path', 'bytes', 'extension', 'area', 'lifecycle', 'tracked', 'flags', 'image_state', 'modified')
    flag_guide = [ordered]@{ play_store = 1; planning = 2; html = 4; sensitive_name = 8; generated = 16; runtime = 32 }
    files = $records
    areas = $areaSummary
    extensions = $extensionSummary
    images = $imageSummary
    image_references = $referencePayload
    dependency_groups = $dependencyPayload
}

$dataFile = Join-Path $outputPath 'atlas-data.js'
$dataRelative = Get-RelativeProjectPath $dataFile
$dataRecord = $records | Where-Object { $_[0] -eq $dataRelative } | Select-Object -First 1
for ($attempt = 0; $attempt -lt 4; $attempt++) {
    $json = $payload | ConvertTo-Json -Depth 8 -Compress
    $javascript = "window.ATLAS_DATA=$json;"
    $finalDataBytes = [System.Text.Encoding]::UTF8.GetByteCount($javascript)
    if (-not $dataRecord -or $dataRecord[1] -eq $finalDataBytes) { break }

    $difference = $finalDataBytes - $dataRecord[1]
    $dataRecord[1] = [int64]$finalDataBytes
    $areaSummary['Atlas'].bytes += $difference
    $extensionSummary['.js'].bytes += $difference
}
[System.IO.File]::WriteAllText($dataFile, $javascript, $utf8NoBom)

Write-Output "Atlas data written to $dataFile"
Write-Output "Files indexed: $($records.Count)"
Write-Output "Bytes indexed: $(($records | ForEach-Object { $_[1] } | Measure-Object -Sum).Sum)"
