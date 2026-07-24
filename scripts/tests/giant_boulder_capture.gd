extends SceneTree

const FightStage := preload("res://scripts/ui/blue_guy_chicken_brawl_stage.gd")
const CAPTURE_PATH := "res://outputs/giant-boulder/giant-boulder-proof-1080x1920.png"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.content_scale_size = Vector2i(1080, 1920)
	root.size = Vector2i(1080, 1920)
	var background := ColorRect.new()
	background.color = Color("#f5eddd")
	background.size = Vector2(1080.0, 1920.0)
	root.add_child(background)

	var stage := FightStage.new()
	stage.set("arena_shape", "diamond")
	stage.set("enemy_id", "giants")
	stage.set("active", true)
	stage.position = Vector2(0.0, 600.0)
	stage.size = Vector2(1080.0, 620.0)
	root.add_child(stage)
	await process_frame
	stage.call("setup_action", {
		"name": "Fight Giants",
		"unlock": 74,
		"art": "assets/content/fight/enemies/giants/giants-states-source.png",
		"combat": {
			"enemy_id": "giants",
			"enemy_kind": "scaled_guy",
			"speed": 0.76,
			"health": 2123,
			"contact_damage": 105,
			"spawn_rhythm": 1.12,
			"population_curve": [1, 1.3, 1.6, 1.9, 2],
			"population_cap": 2,
			"final_population": 2,
		}
	})
	stage.call("setup_fighting_level", 99)
	stage.set_process(false)
	stage.set("hero_pos", Vector2(0.50, 0.55))
	stage.set("hero_attack_cd", 999.0)
	stage.call("_reset_giant_boulders")
	stage.call("_spawn_chicken", 0)
	var actors := stage.get("chickens") as Array
	if actors.is_empty():
		_fail("Giant did not spawn")
		return
	var giant := actors[0] as Dictionary
	giant["pos"] = Vector2(0.27, 0.55)
	giant["render_pos"] = giant["pos"]
	giant["face_right"] = true
	giant["attack_phase"] = "strike"
	giant["giant_attack_kind"] = "boulder"
	giant["giant_boulder_index"] = 0
	giant["signature_t"] = 0.38
	actors = [giant]
	stage.set("chickens", actors)
	var boulders := stage.get("giant_boulders") as Array
	if boulders.size() != 3:
		_fail("Expected three Giant boulders, got %d" % boulders.size())
		return
	var boulder := boulders[0] as Dictionary
	boulder["state"] = "held"
	boulder["owner_id"] = int(giant.get("id", -1))
	boulders[0] = boulder
	stage.set("giant_boulders", boulders)
	var hero_hp_before := float(stage.get("hero_hp"))
	stage.call("_throw_giant_boulder", giant)
	stage.call("_step_giant_boulders", 0.34)
	stage.queue_redraw()
	for _frame in range(3):
		await process_frame
	if DisplayServer.get_name() != "headless":
		var image := root.get_texture().get_image()
		if image == null or image.is_empty():
			_fail("Root viewport image was missing")
			return
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_PATH.get_base_dir()))
		if image.save_png(ProjectSettings.globalize_path(CAPTURE_PATH)) != OK:
			_fail("Could not save Giant boulder capture")
			return

	stage.set("hero_hurt_cooldown", 0.0)
	for _step in range(10):
		stage.call("_step_giant_boulders", 0.05)
	if float(stage.get("hero_hp")) >= hero_hp_before:
		_fail("Flying Giant boulder did not damage Blue Guy")
		return
	boulders = stage.get("giant_boulders") as Array
	boulder = boulders[0] as Dictionary
	if str(boulder.get("state", "")) != "ground" or int(boulder.get("owner_id", 0)) != -1:
		_fail("Giant boulder did not return to a reusable ground state")
		return
	giant["pos"] = (boulder.get("pos", Vector2.ZERO) as Vector2) + Vector2(0.01, 0.0)
	giant["giant_boulder_index"] = -1
	boulders = stage.get("giant_boulders") as Array
	for index in range(1, boulders.size()):
		var unavailable := boulders[index] as Dictionary
		unavailable["state"] = "reserved"
		unavailable["owner_id"] = 999
		boulders[index] = unavailable
	stage.set("giant_boulders", boulders)
	if int(stage.call("_reserve_nearest_giant_boulder", giant)) != 0:
		_fail("Landed Giant boulder could not be reserved again")
		return
	seed(4815)
	var seen_attacks := {}
	var last_attack := ""
	var saw_repeat := false
	for _sample in range(40):
		boulders = stage.get("giant_boulders") as Array
		for index in range(boulders.size()):
			var available := boulders[index] as Dictionary
			available["state"] = "ground"
			available["owner_id"] = -1
			boulders[index] = available
		stage.set("giant_boulders", boulders)
		giant["giant_boulder_index"] = -1
		giant["giant_planned_attack"] = ""
		stage.call("_plan_giant_attack", giant)
		var planned_attack := str(giant.get("giant_planned_attack", ""))
		seen_attacks[planned_attack] = true
		saw_repeat = saw_repeat or planned_attack == last_attack
		last_attack = planned_attack
	if seen_attacks.size() != 3 or not saw_repeat:
		_fail("Giant attack planning did not produce opportunistic RNG choices")
		return
	stage.call("_reset_giant_boulders")
	giant["pos"] = Vector2(0.32, 0.55)
	giant["render_pos"] = giant["pos"]
	giant["attack_phase"] = "windup"
	giant["signature_t"] = 0.52
	giant["giant_attack_kind"] = "boulder"
	giant["giant_boulder_index"] = 0
	giant["face_right"] = true
	stage.set("chickens", [giant])
	boulders = stage.get("giant_boulders") as Array
	boulder = boulders[0] as Dictionary
	boulder["state"] = "held"
	boulder["owner_id"] = int(giant.get("id", -1))
	boulders[0] = boulder
	stage.set("giant_boulders", boulders)
	var debris_before := (stage.get("feather_particles") as Array).size()
	var held_center := stage.call("_held_giant_boulder_center", boulder) as Vector2
	if not bool(stage.call("_try_shatter_held_boulder", held_center)):
		_fail("Held Giant boulder tap was not accepted")
		return
	boulders = stage.get("giant_boulders") as Array
	boulder = boulders[0] as Dictionary
	if str(boulder.get("state", "")) != "destroyed" or (stage.get("feather_particles") as Array).size() <= debris_before:
		_fail("Held Giant boulder did not burst into debris")
		return
	stage.call("_reset_giant_boulders")
	giant["attack_phase"] = "strike"
	giant["giant_attack_kind"] = "boulder"
	giant["giant_boulder_index"] = 0
	giant["interrupt_protected"] = true
	boulders = stage.get("giant_boulders") as Array
	boulder = boulders[0] as Dictionary
	boulder["state"] = "held"
	boulder["owner_id"] = int(giant.get("id", -1))
	boulders[0] = boulder
	stage.set("giant_boulders", boulders)
	stage.call("_stagger_enemy", giant, true)
	boulder = (stage.get("giant_boulders") as Array)[0] as Dictionary
	if str(boulder.get("state", "")) != "ground" or int(boulder.get("owner_id", 0)) != -1 or int(giant.get("giant_boulder_index", 0)) != -1 or str(giant.get("attack_phase", "")) != "stagger":
		_fail("Uppercut did not knock the held boulder loose")
		return
	giant["giant_attack_kind"] = "stomp"
	giant["attack_phase"] = "windup"
	if stage.call("_enemy_attack_texture", giant) != stage.get("idle_chicken"):
		_fail("Giant stomp windup did not use the raised-leg frame")
		return
	giant["attack_phase"] = "strike"
	var giant_attack_frames := (stage.get("enemy_attack_frames") as Dictionary).get("giants-attack", []) as Array
	if giant_attack_frames.is_empty() or stage.call("_enemy_attack_texture", giant) != giant_attack_frames[0]:
		_fail("Giant stomp impact did not use the planted stance")
		return
	giant["signature_t"] = 0.10
	giant["slam_impacted"] = false
	stage.call("_step_enemy_strike", giant, giant.get("pos", Vector2.ZERO) as Vector2, Vector2.RIGHT, 0.016)
	if not bool(giant.get("slam_impacted", false)):
		_fail("Giant stomp effect did not coincide with the planted stance")
		return
	print("giant-boulder-capture-ok capture=%s" % (ProjectSettings.globalize_path(CAPTURE_PATH) if DisplayServer.get_name() != "headless" else "headless-logic-only"))
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	print("giant-boulder-capture-failed reason=%s" % message)
	quit(1)
