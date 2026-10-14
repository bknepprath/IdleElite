$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\performance-resource-lifetime"
$testScript = Join-Path $testDir "performance_resource_lifetime_test.gd"

Assert-True (Test-Path -LiteralPath $runner) "Missing run-godot-safe.ps1."

if (Test-Path -LiteralPath $testDir) {
    Remove-Item -LiteralPath $testDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
$env:GODOT_RUN_TIMEOUT_SECONDS = "180"

try {
    @'
extends SceneTree

const BOOT_TIMEOUT_FRAMES := 720
const SETTLE_FRAMES := 18
const CYCLE_COUNT := 4
const REQUIRED_ROUTE_IDS := [
	"thieving",
	"build",
	"fight",
	"fishing",
	"woodcutting",
	"menu",
	"hub",
	"shop",
	"achievements",
	"settings",
	"queue",
	"pinned",
	"leaderboard",
	"profile",
	"chat",
	"offline-summary",
]

var failures: Array[String] = []
var cycle_reached_routes := {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("performance-resource-lifetime-start")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "14")
	OS.set_environment("IDLE_ELITE_HEADLESS_SIMPLE_ACTION_BG", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("main scene did not load")
		return
	var scene := packed.instantiate()
	_configure_offline_runtime(scene)
	root.add_child(scene)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	if not await _wait_for_boot_ready(scene):
		_fail("boot did not become ready")
		return
	scene.call("_test_state_runtime")._god_mode_unlock_onboarding_state()
	scene.call("_test_state_runtime")._god_mode_max_skills_state()
	scene.call("_test_state_runtime")._god_mode_unlock_actions_state()
	_configure_offline_runtime(scene)

	var snapshots: Array[Dictionary] = []
	for cycle_index in range(CYCLE_COUNT):
		await _run_navigation_cycle(scene, cycle_index)
		for _frame in range(SETTLE_FRAMES * 2):
			await process_frame
		var snapshot := _snapshot(scene, cycle_index)
		snapshots.append(snapshot)
		print("RESOURCE_LIFETIME cycle=%s objects=%s nodes=%s textures=%s atlases=%s children=%s" % [
			cycle_index + 1,
			snapshot["objects"],
			snapshot["nodes"],
			snapshot["textures"],
			snapshot["atlases"],
			snapshot["children"],
		])

	var settled := snapshots[1]
	var final := snapshots[-1]
	_expect(int(final["objects"]) <= int(settled["objects"]) + 120, "object count grew across repeated navigation")
	_expect(int(final["nodes"]) <= int(settled["nodes"]) + 30, "node count grew across repeated navigation")
	_expect(int(final["textures"]) <= int(settled["textures"]) + 8, "texture cache grew across repeated navigation")
	_expect(int(final["atlases"]) <= int(settled["atlases"]) + 4, "atlas cache grew across repeated navigation")

	if failures.is_empty():
		print("performance-resource-lifetime-ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _run_navigation_cycle(scene: Node, cycle_index: int) -> void:
	cycle_reached_routes.clear()
	await _render_screen(scene, "menu")
	_check_non_skill_cleanup(scene, "menu")
	await _render_skill(scene, "thieving")
	_check_skill_bounds(scene, "thieving")
	await _render_skill(scene, "build")
	_check_skill_bounds(scene, "build")
	await _render_skill(scene, "fight")
	_check_skill_bounds(scene, "fight")
	await _render_skill(scene, "fishing")
	_check_skill_bounds(scene, "fishing")
	await _render_skill(scene, "woodcutting")
	_check_skill_bounds(scene, "woodcutting")
	await _render_screen(scene, "hub")
	_check_non_skill_cleanup(scene, "hub")
	await _render_screen(scene, "shop")
	_check_non_skill_cleanup(scene, "shop")
	await _render_screen(scene, "achievements")
	_check_non_skill_cleanup(scene, "achievements")
	await _render_screen(scene, "settings")
	_check_non_skill_cleanup(scene, "settings")
	await _render_screen(scene, "queue")
	_check_non_skill_cleanup(scene, "queue")
	await _render_screen(scene, "pinned")
	_check_non_skill_cleanup(scene, "pinned")
	await _render_screen(scene, "leaderboard")
	_check_non_skill_cleanup(scene, "leaderboard")
	await _render_screen(scene, "menu")
	_check_non_skill_cleanup(scene, "menu")
	await _show_profile_overlay(scene)
	await _show_chat_overlay(scene)
	await _show_offline_summary_overlay(scene)
	for route_id in REQUIRED_ROUTE_IDS:
		_expect(
			cycle_reached_routes.has(route_id),
			"cycle %s did not reach required route: %s" % [cycle_index + 1, route_id]
		)


func _render_skill(scene: Node, skill_id: String) -> void:
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", skill_id)
	await _render_current_screen(scene)
	_reach_route(
		skill_id,
		str(scene.get("current_screen")) == "skill" and str(scene.get("selected_skill_id")) == skill_id,
		"failed to reach skill route: %s" % skill_id
	)


func _render_screen(scene: Node, screen_id: String) -> void:
	scene.set("current_screen", screen_id)
	await _render_current_screen(scene)
	_reach_route(
		screen_id,
		str(scene.get("current_screen")) == screen_id,
		"failed to reach top-level route: %s" % screen_id
	)


func _show_profile_overlay(scene: Node) -> void:
	var surface: Object = scene.call("_profile_chat_overlay_surface")
	surface.call("_ensure_profile_overlay")
	surface.set("profile_avatar_picker_open", false)
	surface.call("_rebuild_profile_overlay")
	var overlay := surface.get("profile_overlay") as Control
	if overlay != null and is_instance_valid(overlay):
		scene.call("_app_lifecycle_runtime").set_canvas_item_visible_if_changed(overlay, true)
	for _frame in range(SETTLE_FRAMES):
		await process_frame
	var visible := bool(surface.call("_profile_overlay_visible"))
	_reach_route("profile", visible, "profile overlay did not open")
	surface.call("_hide_profile_overlay")
	for _frame in range(2):
		await process_frame
	_expect(not bool(surface.call("_profile_overlay_visible")), "profile overlay did not close")


func _show_chat_overlay(scene: Node) -> void:
	var surface: Object = scene.call("_profile_chat_overlay_surface")
	var online: Object = scene.call("_online_runtime")
	online.set("chat_rows", [{
		"message_id": "resource-lifetime-chat-row",
		"sender_id": "resource-lifetime",
		"name": "guest0001",
		"total_level": 1,
		"avatar_index": 0,
		"created_at_unix": 1,
		"text": "Offline lifetime probe",
		"deleted": false,
	}])
	surface.call("_ensure_chat_overlay")
	var overlay := surface.get("chat_overlay") as Control
	if overlay != null and is_instance_valid(overlay):
		scene.call("_app_lifecycle_runtime").set_canvas_item_visible_if_changed(overlay, true)
		surface.call("_ensure_chat_overlay_shell")
		surface.call("_sync_chat_overlay_rows")
	for _frame in range(SETTLE_FRAMES):
		await process_frame
	var visible := bool(surface.call("chat_overlay_visible"))
	_reach_route("chat", visible, "chat overlay did not open")
	surface.call("_close_chat_overlay", false)
	for _frame in range(2):
		await process_frame
	_expect(not bool(surface.call("chat_overlay_visible")), "chat overlay did not close")


func _show_offline_summary_overlay(scene: Node) -> void:
	var surface: Object = scene.call("_achievement_overlay_surface")
	var action := scene.call("_action_data", "fight", "push-ups") as Dictionary
	_expect(not action.is_empty(), "offline summary fixture action was unavailable")
	var active_result := {
		"handled": true,
		"completions": 2,
		"successes": 2,
		"xp": 120,
		"skill_id": "fight",
		"skill_name": "Fight",
		"action_name": str(action.get("name", "Push-Ups")),
		"action_art": str(action.get("art", "")),
		"old_skill_level": 1,
		"new_skill_level": 2,
		"old_global_level": 4,
		"new_global_level": 5,
		"old_mastery_level": 0,
		"new_mastery_level": 1,
		"unlocked_actions": [],
		"achievements": [],
	}
	surface.call("_maybe_show_offline_summary", 90.0, active_result)
	for _frame in range(SETTLE_FRAMES):
		await process_frame
	var visible := bool(surface.call("offline_summary_visible"))
	_reach_route("offline-summary", visible, "offline summary overlay did not open")
	surface.call("hide_offline_summary_immediate")
	for _frame in range(2):
		await process_frame
	_expect(not bool(surface.call("offline_summary_visible")), "offline summary overlay did not close")


func _configure_offline_runtime(scene: Node) -> void:
	var online: Object = scene.call("_online_runtime")
	online.call("_chat_stream_disconnect", false)
	online.set("leaderboard_config_loaded", true)
	online.set("leaderboard_config_database_url", "offline://disabled")
	online.set("leaderboard_config_web_api_key", "offline")
	online.set("chat_stream_connected", false)
	online.set("chat_stream_connecting", false)
	online.set("chat_stream_request_sent", false)
	online.set("chat_status_message", "Offline lifetime probe")
	online.set("chat_rows", [])
	_expect(not bool(online.call("_leaderboard_firebase_enabled")), "offline lifetime probe unexpectedly enabled Firebase")


func _reach_route(route_id: String, reached: bool, failure_message: String) -> void:
	_expect(reached, failure_message)
	if reached:
		cycle_reached_routes[route_id] = true


func _render_current_screen(scene: Node) -> void:
	var result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if result != null:
		await result
	for _frame in range(SETTLE_FRAMES):
		await process_frame
	var content := scene.get("skills_content") as Control
	_expect(content != null and content.get_child_count() <= 6, "navigation left multiple dynamic page trees mounted")


func _check_skill_bounds(scene: Node, skill_id: String) -> void:
	var detail = scene.call("_skill_detail_surface")
	var swipe = scene.call("_skill_swipe_activity_surface")
	var cached_roots := int(detail.call("_detail_lazy_cached_root_count"))
	_expect(cached_roots <= int(detail.DETAIL_LAZY_CACHED_ROOT_LIMIT), "%s exceeded its bounded vertical prewarm cache" % skill_id)
	var caches := swipe.get("real_card_cache_by_skill") as Dictionary
	_expect(caches.size() <= 3, "%s retained more than current and adjacent skill caches" % skill_id)
	for raw_cache in caches.values():
		var cache := raw_cache as Dictionary
		_expect(cache.size() <= int(scene.SKILL_SWIPE_REAL_CARD_PREWARM_COUNT), "%s exceeded its per-skill swipe card cache" % skill_id)
	var plan := detail.get("detail_lazy_plan") as Array
	var mounted := 0
	for raw_entry in plan:
		if bool((raw_entry as Dictionary).get("mounted", false)):
			mounted += 1
	_expect(mounted <= 12, "%s left too many real modules mounted" % skill_id)


func _check_non_skill_cleanup(scene: Node, screen_id: String) -> void:
	var detail = scene.call("_skill_detail_surface")
	var swipe = scene.call("_skill_swipe_activity_surface")
	var caches := swipe.get("real_card_cache_by_skill") as Dictionary
	_expect(caches.is_empty(), "%s retained adjacent skill card caches" % screen_id)
	_expect(int(detail.call("_detail_lazy_cached_root_count")) == 0, "%s retained vertical skill card caches" % screen_id)
	var counts := scene.get("visual_texture_cache").runtime_cache_counts() as Dictionary
	_expect(int(counts.get("textures", 0)) <= 128, "%s retained an unbounded texture cache" % screen_id)
	_expect(int(counts.get("atlases", 0)) <= 64, "%s retained an unbounded atlas cache" % screen_id)


func _snapshot(scene: Node, cycle_index: int) -> Dictionary:
	var counts := scene.get("visual_texture_cache").runtime_cache_counts() as Dictionary
	var content := scene.get("skills_content") as Control
	return {
		"cycle": cycle_index,
		"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"textures": int(counts.get("textures", 0)),
		"atlases": int(counts.get("atlases", 0)),
		"children": content.get_child_count() if content != null else -1,
	}


func _wait_for_boot_ready(scene: Node) -> bool:
	for _frame in range(BOOT_TIMEOUT_FRAMES):
		await process_frame
		if not is_instance_valid(scene):
			return false
		var queue := scene.get("boot_detail_render_queue") as Array
		if (
			bool(scene.get("startup_initialized"))
			and not bool(scene.get("boot_detail_render_in_progress"))
			and not bool(scene.get("boot_detail_scroll_locked"))
			and (queue == null or queue.is_empty())
		):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _fail(message: String) -> void:
	push_error("performance-resource-lifetime-fail: %s" % message)
	quit(1)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $output = & $runner --headless --path $projectRoot --script $testScript 2>&1
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    Assert-True (($output -join "`n") -match "performance-resource-lifetime-ok") "Performance resource lifetime test did not report success."
    Assert-NoUnexpectedGodotErrors $output "performance resource lifetime test"

    $headless = @(Get-HeadlessGodotProcesses)
    if ($headless.Count -gt 0) {
        $headless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "A headless Godot process is still running after the performance resource lifetime test."
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
