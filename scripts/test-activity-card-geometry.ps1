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
        if ($text -notmatch '(ERROR|SCRIPT ERROR|powershell\.exe : ERROR):') {
            continue
        }
        $knownShutdownNoise = (
            $text -match 'ERROR: \d+ RID allocations of type .+ were leaked at exit\.' -or
            $text -match 'ERROR: \d+ resources still in use at exit \(run with --verbose for details\)\.'
        )
        if (-not $knownShutdownNoise) {
            throw "Unexpected Godot error during ${Context}: $text"
        }
    }
}
Assert-True (Test-Path -LiteralPath $runner) "Missing run-godot-safe.ps1."

$baselineHeadlessProcessIds = @{}
foreach ($process in @(Get-HeadlessGodotProcesses)) {
    $baselineHeadlessProcessIds[[int]$process.ProcessId] = $true
}

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
	var page_switch_depth := MainScript.PageSwitchButtonFace.new()
	page_switch_depth.size = Vector2(420.0, 170.0)
	page_switch_depth.side = "right"
	page_switch_depth.depth_offset = Vector2(28.0, 34.0)
	page_switch_depth.set_face_offset(Vector2(999.0, 999.0))
	_expect(page_switch_depth.face_offset.is_equal_approx(Vector2(28.0, 34.0)), "Page-switch depth should clamp press offset to the configured slab offset.")
	page_switch_depth.set_face_offset(Vector2.ZERO)
	var page_switch_points: PackedVector2Array = page_switch_depth.call("_shape_points")
	var page_switch_top_right: Vector2 = page_switch_depth.call("_extreme_shape_point", page_switch_points, 1.0)
	var page_switch_bottom_left: Vector2 = page_switch_depth.call("_extreme_shape_point", page_switch_points, -1.0)
	_expect(page_switch_top_right.x > 350.0 and page_switch_top_right.y < 45.0, "Page-switch top-right connector should start on the rounded upper outside corner.")
	_expect(page_switch_bottom_left.x > 50.0 and page_switch_bottom_left.x < 85.0 and page_switch_bottom_left.y > 145.0, "Page-switch bottom-left connector should start on the lower arrow shoulder.")
	page_switch_depth.free()
	var connector := MainScript.PrismConnectorOverlay.new()
	connector.size = Vector2(420.0, 170.0)
	connector.side = "right"
	connector.depth_offset = Vector2(28.0, 34.0)
	connector.set_face_offset(Vector2(999.0, 999.0))
	_expect(connector.face_offset.is_equal_approx(Vector2(28.0, 34.0)), "Prism connector overlay should clamp press offset to the configured slab offset.")
	connector.set_face_offset(Vector2.ZERO)
	var overlay_points: PackedVector2Array = connector.call("_connector_points")
	_expect(overlay_points.size() == 2, "Prism connector overlay should expose two visible connector starts.")
	if overlay_points.size() == 2:
		_expect(overlay_points[0].x > 350.0 and overlay_points[0].y < 45.0, "Prism connector overlay top-right start should sit on the front silhouette.")
		_expect(overlay_points[1].x > 50.0 and overlay_points[1].x < 85.0 and overlay_points[1].y > 145.0, "Right page-switch connector lower start should sit on the lower arrow shoulder.")
	var left_connector := MainScript.PrismConnectorOverlay.new()
	left_connector.size = Vector2(420.0, 170.0)
	left_connector.side = "left"
	left_connector.depth_offset = Vector2(28.0, 34.0)
	left_connector.set_face_offset(Vector2.ZERO)
	var left_overlay_points: PackedVector2Array = left_connector.call("_connector_points")
	_expect(left_overlay_points.size() == 2, "Left prism connector overlay should expose two visible connector starts.")
	if left_overlay_points.size() == 2:
		_expect(left_overlay_points[0].x > 345.0 and left_overlay_points[0].x < 380.0 and left_overlay_points[0].y < 25.0, "Left page-switch connector upper start should sit on the upper arrow shoulder.")
		_expect(left_overlay_points[1].x < 45.0 and left_overlay_points[1].y > 125.0, "Left page-switch connector lower start should sit on the front lower outside corner.")
	left_connector.free()
	connector.free()
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
	var probe_module_key := "action:fight:shove-wobbly-hay-bale"
	var pin_zone := main_node.call("_module_action_zone", "pin", probe_module_key, true) as Control
	_expect(pin_zone != null, "Module pin action zone should be constructible.")
	if pin_zone != null:
		_expect(pin_zone.mouse_filter == Control.MOUSE_FILTER_PASS, "Module pin zone should pass non-accepted touches through to the card.")
		_expect(pin_zone.get_meta("module_action_kind") == "pin", "Module pin zone should identify its action kind.")
		_expect(bool(pin_zone.get_meta("module_action_circle_zone", false)), "Module pin zone should use circular hit testing.")
		_expect(pin_zone.offset_left == MainScript.MODULE_ACTION_ZONE_OUTER_OFFSET, "Module pin zone should sit at the top-left outer offset.")
		_expect(pin_zone.offset_top == MainScript.MODULE_ACTION_ZONE_TOP_OFFSET, "Module pin zone should use the shared top offset.")
		_expect(pin_zone.offset_right - pin_zone.offset_left == MainScript.MODULE_ACTION_ZONE_SIZE.x, "Module pin zone width should match the configured circular bounds.")
		_expect(pin_zone.offset_bottom - pin_zone.offset_top == MainScript.MODULE_ACTION_ZONE_SIZE.y, "Module pin zone height should match the configured circular bounds.")
	var collapse_zone := main_node.call("_module_action_zone", "collapse", probe_module_key, false) as Control
	_expect(collapse_zone != null, "Module collapse action zone should be constructible.")
	if collapse_zone != null:
		_expect(collapse_zone.mouse_filter == Control.MOUSE_FILTER_STOP, "Module collapse zone should claim top-right circle touches before the card.")
		_expect(collapse_zone.get_meta("module_action_kind") == "collapse", "Module collapse zone should identify its action kind.")
		_expect(bool(collapse_zone.get_meta("module_action_circle_zone", false)), "Module collapse zone should use circular hit testing.")
		_expect(collapse_zone.anchor_left == 1.0 and collapse_zone.anchor_right == 1.0, "Module collapse zone should anchor to the top-right.")
		_expect(collapse_zone.offset_left == -MainScript.MODULE_COLLAPSE_ACTION_ZONE_SIZE.x - MainScript.MODULE_COLLAPSE_ACTION_ZONE_OUTER_OFFSET, "Module collapse zone should sit at the top-right outer offset.")
		_expect(collapse_zone.offset_top == MainScript.MODULE_COLLAPSE_ACTION_ZONE_TOP_OFFSET, "Module collapse zone should use the collapse top offset.")
		_expect(collapse_zone.offset_right - collapse_zone.offset_left == MainScript.MODULE_COLLAPSE_ACTION_ZONE_SIZE.x, "Module collapse zone width should match the configured circular bounds.")
		_expect(collapse_zone.offset_bottom - collapse_zone.offset_top == MainScript.MODULE_COLLAPSE_ACTION_ZONE_SIZE.y, "Module collapse zone height should match the configured circular bounds.")
	if pin_zone != null and collapse_zone != null:
		var zone_host := Control.new()
		zone_host.position = Vector2(200.0, 200.0)
		zone_host.size = Vector2(900.0, 640.0)
		root.add_child(zone_host)
		zone_host.add_child(pin_zone)
		zone_host.add_child(collapse_zone)
		await process_frame
		var pin_rect := pin_zone.get_global_rect()
		var collapse_rect := collapse_zone.get_global_rect()
		var pin_near_edge_outside_circle := pin_rect.position + pin_rect.size * Vector2(0.96, 0.04)
		var collapse_near_edge_outside_circle := collapse_rect.position + collapse_rect.size * Vector2(0.04, 0.04)
		_expect(str(main_node.call("_module_action_zone_kind_at_position", zone_host, pin_rect.get_center())) == "pin", "Module pin zone center should hit the circular pin action.")
		_expect(str(main_node.call("_module_action_zone_kind_at_position", zone_host, pin_rect.position)) == "", "Module pin zone outer corner should not hit outside its circular bounds.")
		_expect(str(main_node.call("_module_action_zone_kind_at_position", zone_host, pin_near_edge_outside_circle)) == "", "Module pin zone rectangular edge should not steal taps outside its circle.")
		_expect(str(main_node.call("_module_action_zone_kind_at_position", zone_host, collapse_rect.get_center())) == "collapse", "Module collapse zone center should hit the circular collapse action.")
		_expect(str(main_node.call("_module_action_zone_kind_at_position", zone_host, collapse_rect.position)) == "", "Module collapse zone outer corner should not hit outside its circular bounds.")
		_expect(str(main_node.call("_module_action_zone_kind_at_position", zone_host, collapse_near_edge_outside_circle)) == "", "Module collapse zone rectangular edge should not steal taps outside its circle.")
		var badge := main_node.call("_ensure_module_pin_badge", zone_host, probe_module_key) as TextureButton
		_expect(badge != null, "Module pin badge should be constructible for badge hit geometry.")
		if badge != null:
			zone_host.set_meta("module_ui_key", probe_module_key)
			badge.visible = true
			badge.disabled = false
			badge.modulate.a = 1.0
			await process_frame
			var transparent_corner := badge.get_global_rect().position
			var visible_art_point := badge.get_global_transform() * Vector2(MainScript.MODULE_PIN_BADGE_SIZE.x * 0.36, MainScript.MODULE_PIN_BADGE_SIZE.y * 0.34)
			_expect(str(main_node.call("_module_action_badge_kind_at_position", zone_host, transparent_corner)) == "", "Oversized pin badge transparent corner should not count as a pin hit.")
			_expect(str(main_node.call("_module_action_badge_kind_at_position", zone_host, visible_art_point)) == "pin", "Oversized pin badge visible art should count as a pin hit even outside the old circular zone.")
			main_node.set("action_cards", {"probe": {"pop": zone_host}})
			var visible_art_action_hit := main_node.call("_module_action_circle_at_position", visible_art_point) as Dictionary
			_expect(str(visible_art_action_hit.get("kind", "")) == "pin", "Oversized pin badge visible art should route a module pin action.")
		zone_host.free()
	else:
		if pin_zone != null:
			pin_zone.free()
		if collapse_zone != null:
			collapse_zone.free()
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

    $newHeadless = @()
    for ($attempt = 1; $attempt -le 10; $attempt++) {
        $newHeadless = @(Get-HeadlessGodotProcesses | Where-Object { -not $baselineHeadlessProcessIds.ContainsKey([int]$_.ProcessId) })
        if ($newHeadless.Count -eq 0) {
            break
        }
        Start-Sleep -Milliseconds 500
    }
    if ($newHeadless.Count -gt 0) {
        $newHeadless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "A new headless Godot process is still running after the activity card geometry test."
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
