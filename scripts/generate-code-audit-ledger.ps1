param(
    [string]$BaseCommit = "989d716b",
    [string]$OutputPath = "docs/code-audit-ledger.csv"
)

$ErrorActionPreference = "Stop"
$extensions = @(".gd", ".gdshader", ".ps1", ".py", ".js", ".ts", ".tsx", ".jsx", ".sh")
$excludedRoots = "^(addons|android|build|builds|dist|output|outputs|release|test-results|tmp|vendor|third_party|\.godot|\.codex-tmp|\.codex-tools)/"
$files = @(
    git ls-tree -r --name-only $BaseCommit |
        Where-Object {
            $extensions -contains [IO.Path]::GetExtension($_).ToLowerInvariant() -and
            $_ -notmatch $excludedRoots
        } |
        Sort-Object
)
if ($LASTEXITCODE -ne 0 -or $files.Count -eq 0) {
    throw "Unable to read source files from commit $BaseCommit."
}

$fileRanges = @()
$globalLine = 1
foreach ($file in $files) {
    $lineCount = @(git show "${BaseCommit}:$file").Count
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to read $file from commit $BaseCommit."
    }
    if ($lineCount -eq 0) {
        continue
    }
    $fileRanges += [pscustomobject]@{
        File = $file
        Start = $globalLine
        End = $globalLine + $lineCount - 1
    }
    $globalLine += $lineCount
}

$totalLines = $globalLine - 1
$rows = for ($chunk = 1; $chunk -le [math]::Ceiling($totalLines / 100.0); $chunk++) {
    $start = (($chunk - 1) * 100) + 1
    $end = [math]::Min($chunk * 100, $totalLines)
    $segments = foreach ($range in $fileRanges) {
        if ($range.End -lt $start -or $range.Start -gt $end) {
            continue
        }
        $localStart = [math]::Max($start, $range.Start) - $range.Start + 1
        $localEnd = [math]::Min($end, $range.End) - $range.Start + 1
        "$($range.File):$localStart-$localEnd"
    }
    [pscustomobject]@{
        Chunk = $chunk
        GlobalStart = $start
        GlobalEnd = $end
        SourceSegments = $segments -join "; "
        Status = "pending_reaudit"
        Finding = ""
        Fix = ""
        Validation = ""
        Evidence = ""
    }
}

$resolvedOutput = Join-Path (Split-Path -Parent $PSScriptRoot) $OutputPath
$rows | Export-Csv -LiteralPath $resolvedOutput -NoTypeInformation -Encoding utf8
"base=$BaseCommit files=$($fileRanges.Count) lines=$totalLines chunks=$($rows.Count) output=$resolvedOutput"
