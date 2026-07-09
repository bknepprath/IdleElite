param(
    [switch]$Capture
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\pinned-pin-visual-smoke"
$testScript = Join-Path $testDir "pinned_pin_visual_smoke.gd"
$capturePath = Join-Path $projectRoot ".codex-tmp\pinned-pin-visual-smoke.png"

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

$mainScriptPath = Join-Path $projectRoot "scripts\main.gd"
$moduleUiRuntimePath = Join-Path $projectRoot "scripts\module_ui\runtime.gd"
$audioDirectorPath = Join-Path $projectRoot "scripts\audio\audio_director.gd"
$inputRoutingShellPath = Join-Path $projectRoot "scripts\ui\input_routing_shell.gd"
$navigationShellPath = Join-Path $projectRoot "scripts\ui\navigation_shell.gd"
$skillDetailSurfacePath = Join-Path $projectRoot "scripts\ui\skill_detail_surface.gd"
$mainScriptText = Get-Content -LiteralPath $mainScriptPath -Raw
$moduleUiRuntimeText = Get-Content -LiteralPath $moduleUiRuntimePath -Raw
$audioDirectorText = Get-Content -LiteralPath $audioDirectorPath -Raw
$inputRoutingShellText = Get-Content -LiteralPath $inputRoutingShellPath -Raw
$navigationShellText = Get-Content -LiteralPath $navigationShellPath -Raw
$skillDetailSurfaceText = Get-Content -LiteralPath $skillDetailSurfacePath -Raw
Assert-True ($skillDetailSurfaceText -match "func\s+_play_module_pin_confirm_animation") "Confirmed pin animation helper should exist."
Assert-True ($moduleUiRuntimeText -match "MODULE_PIN_CONFIRM_ANIMATION_SECONDS") "Confirmed pin animation duration constant should exist in ModuleUiRuntime."
Assert-True ($audioDirectorText -match 'const MODULE_PIN_ENTRY_SFX_PATH := "res://assets/sfx/pin-candidates/pin_exit_pull_04_bright_tick\.wav"') "Pin entry SFX should use the Exit 04 audition sound."
$confirmAnimationMatch = [regex]::Match($skillDetailSurfaceText, 'func\s+_play_module_pin_confirm_animation[\s\S]*?func\s+_finish_module_pin_confirm_animation')
Assert-True $confirmAnimationMatch.Success "Confirmed pin animation block should be inspectable."
$confirmAnimationText = $confirmAnimationMatch.Value
$pokeIndex = $confirmAnimationText.IndexOf('MODULE_PIN_CONFIRM_POKE_SECONDS')
$entrySfxIndex = $confirmAnimationText.IndexOf('_audio_director()._play_module_pin_entry_sfx')
Assert-True (($pokeIndex -ge 0) -and ($entrySfxIndex -gt $pokeIndex)) "Pin entry SFX should fire after the poke motion reaches the module."
$trackerPath = Join-Path $projectRoot "docs\ui-navigation-controls-plan.html"
$trackerText = Get-Content -LiteralPath $trackerPath -Raw
Assert-True ($trackerText -notmatch "pin-poke-in") "Tracker demo should not show confirmed pin animation while placement is paused."
$directRouteIndex = $inputRoutingShellText.IndexOf("if host._skill_detail_surface()._route_direct_module_action_zone_input(event):")
$bottomNavRouteIndex = $inputRoutingShellText.IndexOf("if host._navigation_shell()._route_bottom_nav_button_global_input(event):")
$utilityRouteIndex = $inputRoutingShellText.IndexOf("if host._navigation_shell()._route_module_utility_button_global_input(event):")
Assert-True ($directRouteIndex -ge 0) "Direct module action routing should exist."
Assert-True (($bottomNavRouteIndex -ge 0) -and ($directRouteIndex -lt $bottomNavRouteIndex)) "Direct module action routing should run before bottom nav global routing."
Assert-True (($utilityRouteIndex -ge 0) -and ($directRouteIndex -lt $utilityRouteIndex)) "Direct module action routing should run before module utility global routing."
$bottomNavHitMatch = [regex]::Match($navigationShellText, 'func\s+_bottom_nav_button_at_position[\s\S]*?func\s+_active_bottom_nav_button')
Assert-True $bottomNavHitMatch.Success "Bottom nav hit-test block should be inspectable."
Assert-True ($bottomNavHitMatch.Value -notmatch "_activity_input_position_candidates") "Bottom nav buttons should not accept scaled fallback coordinates."
$bottomNavContainmentMatch = [regex]::Match($navigationShellText, 'func\s+_event_points_inside_bottom_nav[\s\S]*?func\s+_build_nav_bar')
Assert-True $bottomNavContainmentMatch.Success "Bottom nav containment block should be inspectable."
Assert-True ($bottomNavContainmentMatch.Value -notmatch "_activity_input_position_candidates") "Bottom nav containment should not accept scaled fallback coordinates."
$utilityHitMatch = [regex]::Match($navigationShellText, 'func\s+_module_utility_button_at_position[\s\S]*?func\s+_active_module_utility_button')
Assert-True $utilityHitMatch.Success "Module utility hit-test block should be inspectable."
Assert-True ($utilityHitMatch.Value -notmatch "_activity_input_position_candidates") "Module utility buttons should not accept scaled fallback coordinates."
$actionHitMatch = [regex]::Match($skillDetailSurfaceText, 'func\s+_module_action_circle_at_position[\s\S]*?func\s+_module_action_circle_at_direct_position')
Assert-True $actionHitMatch.Success "Module action circle hit-test block should be inspectable."
$bottomGuardIndex = $actionHitMatch.Value.IndexOf("._position_inside_bottom_interactive_ui(event_position)")
$directHitIndex = $actionHitMatch.Value.IndexOf("_module_action_circle_at_direct_position(event_position)")
Assert-True (($bottomGuardIndex -ge 0) -and ($directHitIndex -gt $bottomGuardIndex)) "Module action hit testing should reject bottom chrome before checking direct card hits."

if (Test-Path -LiteralPath $testDir) {
    Remove-Item -LiteralPath $testDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testDir -Force | Out-Null
New-Item -ItemType Directory -Path (Split-Path -Parent $capturePath) -Force | Out-Null
Remove-Item -LiteralPath $capturePath -Force -ErrorAction SilentlyContinue

$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
$previousCapture = $env:IDLE_ELITE_PIN_VISUAL_SMOKE_PNG
$env:GODOT_RUN_TIMEOUT_SECONDS = "120"
if ($Capture) {
    $env:IDLE_ELITE_PIN_VISUAL_SMOKE_PNG = $capturePath
}
$baselineHeadlessProcessIds = @{}
foreach ($process in @(Get-HeadlessGodotProcesses)) {
    $baselineHeadlessProcessIds[[int]$process.ProcessId] = $true
}

try {
    @'
extends SceneTree

const BOOT_TIMEOUT_FRAMES := 720
const EXPECTED_PIN_TEXTURE := "res://assets/content/ui/navigation-controls/pin.png"
const EXPECTED_PIN_COLOR_TEXTURES := [
	"res://assets/content/ui/navigation-controls/pin-color/pin-color-blue.png",
	"res://assets/content/ui/navigation-controls/pin-color/pin-color-green.png",
	"res://assets/content/ui/navigation-controls/pin-color/pin-color-orange.png",
	"res://assets/content/ui/navigation-controls/pin-color/pin-color-pink.png",
	"res://assets/content/ui/navigation-controls/pin-color/pin-color-purple.png",
	"res://assets/content/ui/navigation-controls/pin-color/pin-color-red.png",
	"res://assets/content/ui/navigation-controls/pin-color/pin-color-teal.png",
	"res://assets/content/ui/navigation-controls/pin-color/pin-color-yellow.png",
]

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("pinned-pin-visual-smoke-start")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "14")
	root.size = Vector2i(900, 1800)
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("main scene did not load")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	if not await _wait_for_boot_ready(scene):
		_fail("boot did not become ready")
		return
	if not await _wait_for_boot_hidden(scene):
		_fail("boot overlay did not hide")
		return
	scene.call("_test_state_runtime")._god_mode_unlock_onboarding_state()
	scene.call("_test_state_runtime")._god_mode_max_skills_state()
	scene.call("_test_state_runtime")._god_mode_unlock_actions_state()
	await _check_pin_visuals(scene, "thieving")
	await _capture_viewport_if_possible()

	if failures.is_empty():
		print("pinned-pin-visual-smoke-ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _wait_for_boot_ready(scene: Node) -> bool:
	for _frame in range(BOOT_TIMEOUT_FRAMES):
		await process_frame
		if not is_instance_valid(scene):
			return false
		var queue := scene.get("boot_detail_render_queue") as Array
		if (
			scene.get("startup_initialized") == true
			and scene.get("boot_detail_render_in_progress") != true
			and scene.get("boot_detail_scroll_locked") != true
			and (queue == null or queue.is_empty())
		):
			return true
	return false


func _wait_for_boot_hidden(scene: Node) -> bool:
	for _frame in range(BOOT_TIMEOUT_FRAMES):
		await process_frame
		if not is_instance_valid(scene):
			return false
		var overlay := scene.get("boot_warmup_overlay") as Control
		if scene.get("boot_warmup_active") != true and (overlay == null or not overlay.visible or overlay.modulate.a <= 0.01):
			return true
	return false


func _check_pin_visuals(scene: Node, skill_id: String) -> void:
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", skill_id)
	var module_runtime := scene.get("module_ui_runtime") as Object
	module_runtime.set("sort_mode", "level")
	module_runtime.set("pinned_order", [])
	module_runtime.set("pin_color_paths", {})
	module_runtime.set("collapsed", {})
	scene.call("_test_state_runtime")._clear_running_activity_for_test_mode()
	var render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _i in range(14):
		await process_frame
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	var live_card := _live_action_card_at_index(scene, skill_id, 0)
	if live_card.is_empty():
		live_card = _first_live_action_card(scene, skill_id)
	var module_key := str(live_card.get("module_key", ""))
	var card := live_card.get("card", {}) as Dictionary
	if module_key.is_empty() or card.is_empty():
		_record("pin visual smoke could not find a live registered action card")
		return
	var parts := module_key.substr("action:".length()).split(":", false, 2)
	if parts.size() < 2:
		_record("pin visual smoke expected an action module key: %s" % module_key)
		return
	var action_id := str(parts[1])
	var pop := card.get("pop", null) as Control
	if pop == null or not is_instance_valid(pop) or not pop.is_inside_tree():
		_record("pin visual smoke card pop is not live")
		return
	var zones := card.get("module_action_zones", {}) as Dictionary
	var pin_zone := zones.get("pin", null) as Control
	if pin_zone == null or not is_instance_valid(pin_zone):
		_record("pin visual smoke could not find the pin zone")
		return
	var pin_center := pin_zone.get_global_rect().get_center()
	var drag_release := pin_center + Vector2(0, 150)
	scene.call("_input", _mouse_button_event(pin_center, true))
	scene.call("_input", _mouse_motion_event(drag_release, Vector2(0, 150)))
	scene.call("_input", _mouse_button_event(drag_release, false))
	for _i in range(4):
		await process_frame
	if (module_runtime.get("pinned_order") as Array).has(module_key):
		_record("pin drag should not pin the module")
	if int((module_runtime.get("pin_preview_tokens") as Dictionary).get(module_key, 0)) > 0:
		_record("pin drag should not arm the pin preview")
	scene.call("_input", _mouse_button_event(pin_center, true))
	scene.call("_input", _mouse_button_event(pin_center, false))
	for _i in range(3):
		await process_frame
	var badge := (scene.call("_skill_detail_surface") as Object).call("_module_pin_badge", pop) as TextureButton
	if badge == null or not is_instance_valid(badge):
		_record("pin visual smoke did not create the confirmed badge")
		return
	if not (module_runtime.get("pinned_order") as Array).has(module_key):
		_record("pin visual smoke first tap did not pin the module")
	if int((module_runtime.get("pin_preview_tokens") as Dictionary).get(module_key, 0)) > 0:
		_record("pin visual smoke first tap should commit immediately without arming a preview token")
	if not badge.has_meta("module_pin_tween"):
		_record("first pin tap should start the poke-in animation before the page refresh")
	if not badge.disabled:
		_record("first pin tap badge should be disabled while its poke-in animation plays")
	var entry_settled_position := Vector2(198, 128)
	if badge.position.is_equal_approx(entry_settled_position):
		_record("first pin tap badge should move through an in-between animation pose before settling. position=%s" % badge.position)
	for _i in range(2):
		await process_frame
	await _capture_viewport_if_possible("entry-appear")
	for _i in range(4):
		await process_frame
	await _capture_viewport_if_possible("entry-anticipation")
	for _i in range(3):
		await process_frame
	await _capture_viewport_if_possible("entry-turnaround")
	for _i in range(5):
		await process_frame
	await _capture_viewport_if_possible("entry-poke")
	for _i in range(7):
		await process_frame
	await _capture_viewport_if_possible("entry-sink")
	for _i in range(120):
		await process_frame
		if badge == null or not is_instance_valid(badge) or not badge.has_meta("module_pin_tween"):
			break
	if badge != null and is_instance_valid(badge) and badge.has_meta("module_pin_tween"):
		_record("confirmed pin entry animation did not finish within the smoke wait window")
	if not (module_runtime.get("pinned_order") as Array).has(module_key):
		_record("pin visual smoke first tap did not keep the module pinned")
	var settled_live_card := _live_action_card_for_action(scene, skill_id, action_id)
	var settled_card := settled_live_card.get("card", {}) as Dictionary
	var settled_pop := settled_card.get("pop", null) as Control
	if settled_pop == null or not is_instance_valid(settled_pop) or not settled_pop.is_inside_tree():
		_record("pin visual smoke could not reacquire the settled pinned card after refresh")
		return
	var settled_badge := (scene.call("_skill_detail_surface") as Object).call("_module_pin_badge", settled_pop) as TextureButton
	if settled_badge == null or not is_instance_valid(settled_badge):
		_record("pin visual smoke could not reacquire the settled pinned badge after refresh")
		return
	_check_badge_visual_state(scene, settled_pop, settled_badge, module_key, false)
	await _capture_viewport_if_possible("settled")
	var settled_zones := settled_card.get("module_action_zones", {}) as Dictionary
	var settled_pin_zone := settled_zones.get("pin", null) as Control
	if settled_pin_zone == null or not is_instance_valid(settled_pin_zone):
		_record("pin visual smoke could not find the settled pin zone for exit")
		return
	var exit_point := settled_pin_zone.get_global_rect().get_center()
	scene.call("_input", _mouse_button_event(exit_point, true))
	scene.call("_input", _mouse_button_event(exit_point, false))
	for _i in range(2):
		await process_frame
	if not settled_badge.has_meta("module_pin_tween"):
		_record("unpin should start the pull-out animation")
	if not settled_badge.visible or settled_badge.modulate.a < 0.8:
		_record("unpin should keep the pin visible while it first pulls free")
	for _i in range(10):
		await process_frame
	var pull_position := Vector2(236, 14)
	var exit_settled_position := Vector2(198, 128)
	if not (settled_badge.position.x > exit_settled_position.x and settled_badge.position.y < exit_settled_position.y):
		_record("unpin should pull the pin up/right from the settled spot. settled=%s actual=%s pull=%s" % [exit_settled_position, settled_badge.position, pull_position])
	await _capture_viewport_if_possible("exit")
	for _i in range(5):
		await process_frame
	if settled_badge.modulate.a >= 1.0:
		_record("unpin should begin fading while it pulls away")
	for _i in range(31):
		await process_frame
	if settled_badge.visible or settled_badge.modulate.a > 0.01:
		_record("unpin should hide the badge after the pull-away fade")
	if (module_runtime.get("pinned_order") as Array).has(module_key):
		_record("unpin visual smoke did not remove the module from pinned order")


func _check_badge_visual_state(scene: Node, pop: Control, badge: TextureButton, module_key: String, armed: bool) -> void:
	var expected_size := Vector2(320, 320)
	var armed_position := Vector2(224, 50)
	var settled_position := Vector2(198, 128)
	var spawn_position := armed_position
	var expected_position := armed_position if armed else settled_position
	if not badge.visible:
		_record("pin badge should be visible while %s" % ("armed" if armed else "pinned"))
	if badge.texture_normal == null:
		_record("pin badge texture is missing")
	else:
		var texture_path := str(badge.get_meta("module_pin_texture_path", ""))
		var expected_textures := [EXPECTED_PIN_TEXTURE]
		expected_textures.append_array(EXPECTED_PIN_COLOR_TEXTURES)
		if not expected_textures.has(texture_path):
			_record("pin badge texture should use a prepared pin texture, got %s" % texture_path)
		if not armed and not EXPECTED_PIN_COLOR_TEXTURES.has(texture_path):
			_record("settled pin badge should use a randomized color pin texture, got %s" % texture_path)
	if expected_size.x < 300.0 or expected_size.y < 300.0 or badge.size.x < 300.0 or badge.size.y < 300.0 or not badge.size.is_equal_approx(expected_size):
		_record("pin badge is not using the oversized placement size. expected=%s actual=%s" % [expected_size, badge.size])
	if badge.stretch_mode != TextureButton.STRETCH_KEEP_ASPECT:
		_record("pin badge art should scale to the oversized bounds")
	if badge.position.distance_to(expected_position) > 4.0:
		_record("pin badge position mismatch while %s. expected=%s actual=%s" % ["armed" if armed else "pinned", expected_position, badge.position])
	if armed and not (armed_position.x > settled_position.x and armed_position.y < settled_position.y):
		_record("armed pin should sit up and right of the settled pin")
	if armed and not (spawn_position.x > armed_position.x and spawn_position.y < armed_position.y):
		_record("pin preview spawn should begin up/right of the armed pose")
	if not armed and (absf(badge.rotation_degrees) > 0.01 or not badge.scale.is_equal_approx(Vector2.ONE)):
		_record("settled pinned badge should have no preview tilt or scale")
	var pop_rect := pop.get_global_rect()
	var badge_rect := badge.get_global_rect()
	if not badge_rect.intersects(pop_rect):
		_record("pin badge should visibly intersect the card face")
	if badge_rect.position.y >= pop_rect.position.y:
		_record("pin badge should overhang above the card while still poking into it")
	if not armed and badge_rect.position.x >= pop_rect.position.x:
		_record("settled pin badge should overhang the card top-left while still poking into it")
	var tip_point := badge.get_global_transform() * (expected_size * Vector2(0.235, 0.82))
	if armed:
		var clip_origin := Vector2(-220, -330)
		var settled_tip_point := pop.get_global_transform() * (clip_origin + settled_position + expected_size * Vector2(0.235, 0.82))
		if not (tip_point.x > settled_tip_point.x + 45.0 and tip_point.y < settled_tip_point.y - 45.0):
			_record("armed pin tip should sit clearly up/right from the settled target")
	else:
		var buried_area := Rect2(pop_rect.position + Vector2(-45, 20), Vector2(110, 92))
		if not buried_area.has_point(tip_point):
			_record("settled pin tip should be buried inside the top-left card face. tip=%s area=%s" % [tip_point, buried_area])
		var title_rect := _top_title_label_rect(pop)
		if title_rect.has_area():
			var pin_no_text_rect := Rect2(
				badge_rect.position + Vector2(badge_rect.size.x * 0.02, badge_rect.size.y * 0.05),
				Vector2(badge_rect.size.x * 0.42, badge_rect.size.y * 0.52)
			)
			if pin_no_text_rect.intersects(title_rect):
				_record("settled pin should sit left/up of the title text. pin=%s title=%s" % [pin_no_text_rect, title_rect])
	if _find_named_descendant(pop, "ModulePinBuryMask") != null:
		_record("pin should not create a visible bury-mask node")


func _find_named_descendant(root_node: Node, node_name: String) -> Node:
	if root_node == null:
		return null
	for child in root_node.get_children():
		if child.name == node_name:
			return child
		var found := _find_named_descendant(child, node_name)
		if found != null:
			return found
	return null


func _top_title_label_rect(root_node: Node) -> Rect2:
	var title := _top_title_label(root_node)
	if title == null:
		return Rect2()
	return title.get_global_rect()


func _top_title_label(root_node: Node) -> Label:
	if root_node == null:
		return null
	var result := _collect_top_title_label(root_node, {"label": null, "y": INF})
	return result.get("label", null) as Label


func _collect_top_title_label(root_node: Node, result: Dictionary) -> Dictionary:
	for child in root_node.get_children():
		var label := child as Label
		if label != null and label.is_visible_in_tree() and not label.text.strip_edges().is_empty():
			var rect := label.get_global_rect()
			if rect.size.x > 180.0 and rect.position.y < float(result.get("y", INF)):
				result["label"] = label
				result["y"] = rect.position.y
		_collect_top_title_label(child, result)
	return result


func _capture_viewport_if_possible(label := "") -> void:
	var capture_path := OS.get_environment("IDLE_ELITE_PIN_VISUAL_SMOKE_PNG")
	if capture_path.is_empty():
		return
	if DisplayServer.get_name() == "headless":
		print("pinned-pin-visual-smoke-capture skipped=headless")
		return
	for _i in range(3):
		await process_frame
	var texture := root.get_texture()
	if texture == null:
		print("pinned-pin-visual-smoke-capture skipped=no-texture")
		return
	var image := texture.get_image()
	if image == null or image.is_empty():
		print("pinned-pin-visual-smoke-capture skipped=empty-image")
		return
	var output_path := capture_path
	if not label.is_empty():
		var extension_index := capture_path.rfind(".")
		output_path = capture_path.substr(0, extension_index) + "-%s" % label + capture_path.substr(extension_index) if extension_index > 0 else "%s-%s.png" % [capture_path, label]
	var result := image.save_png(output_path)
	if result == OK:
		print("pinned-pin-visual-smoke-capture path=%s size=%sx%s" % [output_path, image.get_width(), image.get_height()])
	else:
		print("pinned-pin-visual-smoke-capture skipped=save-failed code=%s" % result)


func _first_live_action_card(scene: Node, skill_id: String) -> Dictionary:
	return _live_action_card_at_index(scene, skill_id, 0)


func _live_action_card_at_index(scene: Node, skill_id: String, target_index: int) -> Dictionary:
	var action_cards := scene.get("action_cards") as Dictionary
	var found_index := 0
	for raw_key in action_cards.keys():
		var card := action_cards.get(raw_key, {}) as Dictionary
		if card.is_empty():
			continue
		if str(card.get("skill_id", "")) != skill_id:
			continue
		var action_id := str(card.get("action_id", ""))
		if action_id.is_empty():
			continue
		var pop := card.get("pop", null) as Control
		if pop == null or not is_instance_valid(pop) or not pop.is_inside_tree():
			continue
		var zones := card.get("module_action_zones", {}) as Dictionary
		var pin_zone := zones.get("pin", null) as Control
		if pin_zone == null or not is_instance_valid(pin_zone):
			continue
		if found_index != target_index:
			found_index += 1
			continue
		return {
			"module_key": "action:%s:%s" % [skill_id, action_id],
			"card": card
		}
	return {}


func _live_action_card_for_action(scene: Node, skill_id: String, action_id: String) -> Dictionary:
	var action_cards := scene.get("action_cards") as Dictionary
	for raw_key in action_cards.keys():
		var card := action_cards.get(raw_key, {}) as Dictionary
		if card.is_empty():
			continue
		if str(card.get("skill_id", "")) != skill_id or str(card.get("action_id", "")) != action_id:
			continue
		var pop := card.get("pop", null) as Control
		if pop == null or not is_instance_valid(pop) or not pop.is_inside_tree():
			continue
		return {
			"module_key": "action:%s:%s" % [skill_id, action_id],
			"card": card
		}
	return {}


func _mouse_button_event(global_position: Vector2, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = global_position
	event.global_position = global_position
	return event


func _mouse_motion_event(global_position: Vector2, relative: Vector2) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.position = global_position
	event.global_position = global_position
	event.relative = relative
	return event


func _record(message: String) -> void:
	failures.append(message)


func _fail(message: String) -> void:
	push_error("pinned-pin-visual-smoke-fail: %s" % message)
	quit(1)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    if ($Capture) {
        $output = & $runner --visible-game --path $projectRoot --script $testScript 2>&1
    } else {
        $output = & $runner --headless --path $projectRoot --script $testScript 2>&1
    }
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    $reportedSuccess = ($output -join "`n") -match "pinned-pin-visual-smoke-ok"
    if (-not $Capture) {
        Assert-True $reportedSuccess "Pinned pin visual smoke did not report success."
    }
    Assert-NoUnexpectedGodotErrors $output "pinned pin visual smoke"
    if ($Capture) {
        Assert-True (Test-Path -LiteralPath $capturePath) "Pinned pin visual smoke capture was not created."
    }

    $newHeadless = @(Get-HeadlessGodotProcesses | Where-Object { -not $baselineHeadlessProcessIds.ContainsKey([int]$_.ProcessId) })
    if ($newHeadless.Count -gt 0) {
        $newHeadless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "A new headless Godot process is still running after pinned pin visual smoke."
    }
} finally {
    if ($null -eq $previousTimeout) {
        Remove-Item Env:\GODOT_RUN_TIMEOUT_SECONDS -ErrorAction SilentlyContinue
    } else {
        $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
    }
    if ($null -eq $previousCapture) {
        Remove-Item Env:\IDLE_ELITE_PIN_VISUAL_SMOKE_PNG -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_PIN_VISUAL_SMOKE_PNG = $previousCapture
    }
    if (Test-Path -LiteralPath $testDir) {
        Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
