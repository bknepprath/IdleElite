$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\activity-card-geometry"
$testScript = Join-Path $testDir "activity_card_geometry_probe.gd"

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Get-HeadlessGodotProcesses {
    $processes = @(Get-CimInstance Win32_Process -Filter "name like 'Godot%'" -ErrorAction SilentlyContinue)
    @($processes | Where-Object { $_.CommandLine -match '--headless' })
}

function Assert-NoUnexpectedGodotErrors {
    param(
        [Parameter(Mandatory = $true)][AllowNull()]$Output,
        [Parameter(Mandatory = $true)][string]$Context
    )

    if ($null -eq $Output) {
        return
    }

    foreach ($line in @($Output)) {
        $text = [string]$line
        if ($text -notmatch '^(ERROR|SCRIPT ERROR):') {
            continue
        }
        $knownShutdownNoise = (
            $text -match '^ERROR: \d+ RID allocations of type .+ were leaked at exit\.$' -or
            $text -match '^ERROR: \d+ resources still in use at exit \(run with --verbose for details\)\.$'
        )
        if (-not $knownShutdownNoise) {
            throw "Unexpected Godot error during ${Context}: $text"
        }
    }
}

Assert-True (Test-Path -LiteralPath $runner) "Missing run-godot-safe.ps1."

if (Test-Path -LiteralPath $testDir) {
    Remove-Item -LiteralPath $testDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
$env:GODOT_RUN_TIMEOUT_SECONDS = "60"

try {
    @'
extends SceneTree

const MainScript := preload("res://scripts/main.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var rail := MainScript.ActivityProgressRail.new()
	rail.bottom_radius = 66.0
	var rail_rect := Rect2(Vector2.ZERO, Vector2(1156.0, 88.0))
	var row_count := int(rail.call("_rounded_fill_row_count", rail_rect))
	_expect(row_count == 18, "Activity progress rail should cap rounded fill at 18 rows.")
	var row_height := rail_rect.size.y / float(row_count)
	var top_y := rail_rect.position.y + row_height * 0.5
	var bottom_y := rail_rect.position.y + (float(row_count) - 0.5) * row_height
	var top_clip: Vector2 = rail.call("_bottom_round_row_clip", rail_rect, top_y)
	var bottom_clip: Vector2 = rail.call("_bottom_round_row_clip", rail_rect, bottom_y)
	_expect(_near(top_clip.x, rail_rect.position.x), "Top rail row should span to the left edge.")
	_expect(_near(top_clip.y, rail_rect.end.x), "Top rail row should span to the right edge.")
	_expect(bottom_clip.x > rail_rect.position.x + 1.0, "Bottom rail row should clip inside the left rounded corner.")
	_expect(bottom_clip.y < rail_rect.end.x - 1.0, "Bottom rail row should clip inside the right rounded corner.")
	_expect(bottom_clip.x > rail_rect.position.x + 36.0, "Bottom rail row should follow the full card radius instead of the rail's local height.")
	_expect(bottom_clip.y < rail_rect.end.x - 36.0, "Bottom rail row should follow the full card radius on the right corner.")
	_expect(bottom_clip.y - bottom_clip.x < rail_rect.size.x - 2.0, "Bottom full-fill row should be narrower than the raw rail width.")

	for i in range(row_count):
		var y := rail_rect.position.y + (float(i) + 0.5) * row_height
		var clip: Vector2 = rail.call("_bottom_round_row_clip", rail_rect, y)
		var full_left := maxf(clip.x, rail_rect.position.x)
		var full_right := minf(clip.y, rail_rect.end.x)
		_expect(full_left >= clip.x - 0.01, "Full rail fill should not bleed left of its rounded row clip.")
		_expect(full_right <= clip.y + 0.01, "Full rail fill should not bleed right of its rounded row clip.")
		var marker_left := maxf(clip.x, rail_rect.position.x + rail_rect.size.x * 0.78)
		var marker_right := minf(clip.y, rail_rect.position.x + rail_rect.size.x * 0.88)
		_expect(marker_left >= clip.x - 0.01, "Opportunity marker should not bleed left of its rounded row clip.")
		_expect(marker_right <= clip.y + 0.01, "Opportunity marker should not bleed right of its rounded row clip.")

	rail.set_opportunity_windows([Vector2(0.78, 0.88)], true, true, false)
	var overlay := rail.get_child(0) as MainScript.ActivityProgressOpportunityOverlay
	_expect(overlay != null, "Activity progress rail should create a separate opportunity-window overlay.")
	if overlay != null:
		_expect(overlay.z_index == MainScript.ACTION_OPPORTUNITY_WINDOW_OVERLAY_Z, "Opportunity-window overlay should draw above the activity-card face border.")
		_expect(_near(overlay.offset_top, -MainScript.ACTION_OPPORTUNITY_WINDOW_VERTICAL_OUTSET), "Opportunity-window overlay should extend above the rail.")
		_expect(_near(overlay.offset_bottom, MainScript.ACTION_OPPORTUNITY_WINDOW_VERTICAL_OUTSET), "Opportunity-window overlay should extend below the rail.")

	var depth := MainScript.ActivityCardDepth.new()
	_expect(MainScript.ACTION_CARD_3D_PRESS_OFFSET.is_equal_approx(MainScript.ACTION_CARD_3D_DEPTH_OFFSET), "Activity-card press offset should fully seat the face onto the back slab.")
	var face_rect := Rect2(Vector2(28.0, 34.0), Vector2(1156.0, 720.0))
	var normal_radius := float(depth.call("_fast_round_rect_radius", face_rect, 66.0))
	_expect(_near(normal_radius, 66.0), "Fast activity-card back plate should preserve the intended rounded corner radius.")
	var tiny_radius := float(depth.call("_fast_round_rect_radius", Rect2(Vector2.ZERO, Vector2(80.0, 40.0)), 66.0))
	_expect(_near(tiny_radius, 20.0), "Fast activity-card back plate radius should clamp to half the short side.")
	var connector_points: PackedVector2Array = depth.call("_depth_corner_connector_points", Vector2(1156.0, 720.0), Vector2.ZERO, Vector2(28.0, 34.0), 7.0)
	_expect(connector_points.size() == 4, "Activity-card depth should expose two slab connector stroke segments.")
	if connector_points.size() == 4:
		_expect(connector_points[1].is_equal_approx(connector_points[0] + Vector2(28.0, 34.0)), "Top-right connector should extend to the same back-plate corner.")
		_expect(connector_points[3].is_equal_approx(connector_points[2] + Vector2(28.0, 34.0)), "Bottom-left connector should extend to the same back-plate corner.")
		_expect(connector_points[0].x > 1100.0 and connector_points[0].y < 55.0, "Top-right connector should start on the front top-right rounded corner.")
		_expect(connector_points[2].x < 55.0 and connector_points[2].y > 665.0, "Bottom-left connector should start on the front bottom-left rounded corner.")
	depth.depth_offset = Vector2(28.0, 34.0)
	depth.set_face_offset(Vector2(999.0, 999.0))
	_expect(depth.face_offset.is_equal_approx(Vector2(28.0, 34.0)), "Activity-card press depth should clamp to the configured depth offset.")
	var main_node := MainScript.new()
	var bg := main_node.call("_action_card_background", "building", {"id": "probe", "bg": ""}) as Control
	_expect(bg is MainScript.RoundedTextureRect, "Activity-card background should use the rounded masked renderer.")
	if bg is MainScript.RoundedTextureRect:
		var rounded_bg := bg as MainScript.RoundedTextureRect
		_expect(_near(rounded_bg.radius, 66.0), "Activity-card background radius should match the front border radius.")
		_expect(_near(rounded_bg.mask_inset, 0.0), "Activity-card background mask should not shrink inside the border.")
		_expect(rounded_bg.corner_mask_mode == 1, "Activity-card background mask should align the full-radius corner curve.")
	if bg != null:
		bg.free()
	main_node.free()
	_finish()


func _near(a: float, b: float, epsilon := 0.01) -> bool:
	return absf(a - b) <= epsilon


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("activity-card-geometry-ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $output = & $runner --headless --path $projectRoot --script $testScript 2>&1
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    Assert-True (($output -join "`n") -match "activity-card-geometry-ok") "Activity card geometry test did not report success."
    Assert-NoUnexpectedGodotErrors $output "activity card geometry validation"

    $headless = @(Get-HeadlessGodotProcesses)
    if ($headless.Count -gt 0) {
        $headless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "A headless Godot process is still running after the activity card geometry test."
    }
} finally {
    if ($null -eq $previousTimeout) {
        Remove-Item Env:\GODOT_RUN_TIMEOUT_SECONDS -ErrorAction SilentlyContinue
    } else {
        $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
    }
    if (Test-Path -LiteralPath $testDir) {
        Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
