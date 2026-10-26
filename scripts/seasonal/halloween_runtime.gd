extends RefCounted

signal changed
const SkillState = preload("res://scripts/progression/skill_state.gd")
const EVENT_ID := "halloween-2026"
const MAX_CANDY := 1000000
var host
var enabled := false
var ends_at_unix := 0
var was_active := false
var launch_greeting_enabled := false
var launch_greeting_end_date := ""
var launch_greeting_art := ""
var launch_greeting_layer: CanvasLayer
# Session-only: reopening the game may show it again; saves never suppress it.
var launch_greeting_claimed := false
var candy := 0
var ever_earned := false
var auto_by_skill := {}
var random := RandomNumberGenerator.new()

func _init(host_ref) -> void:
	host = host_ref
	random.randomize()

func configure(events: Variant) -> void:
	var config: Dictionary = events.get(EVENT_ID, {}) if events is Dictionary else {}
	enabled = bool(config.get("enabled", false))
	ends_at_unix = maxi(0, int(config.get("ends_at_unix", 0)))
	was_active = active()
	var greeting: Dictionary = config.get("launch_greeting", {}) if config.get("launch_greeting", {}) is Dictionary else {}
	launch_greeting_enabled = greeting.get("enabled", false) == true
	launch_greeting_end_date = str(greeting.get("ends_before_local_date", ""))
	launch_greeting_art = str(greeting.get("art", ""))

func active() -> bool:
	return enabled and (ends_at_unix == 0 or host._unix_now() < ends_at_unix)

func launch_greeting_eligible(local_date: Dictionary = {}) -> bool:
	return host.loaded_save_this_boot and not host._onboarding_runtime().tutorial_active and not launch_greeting_claimed and launch_greeting_window_open(local_date)

func launch_greeting_window_open(local_date: Dictionary = {}) -> bool:
	if not launch_greeting_enabled or not active(): return false
	# Require the explicit cutoff; a missing/malformed date must never enable
	# an indefinitely repeating seasonal greeting.
	if launch_greeting_end_date.length() != 10:
		return false
	var cutoff := launch_greeting_end_date.split("-")
	if cutoff.size() != 3 or cutoff[0].length() != 4 or cutoff[1].length() != 2 or cutoff[2].length() != 2: return false
	for part in cutoff:
		if not part.is_valid_int(): return false
	var year := int(cutoff[0])
	var month := int(cutoff[1])
	var day := int(cutoff[2])
	if year < 2026 or month < 1 or month > 12 or day < 1 or day > 31: return false
	var date := Time.get_date_dict_from_system(false) if local_date.is_empty() else local_date
	if not date.has("year") or not date.has("month") or not date.has("day"): return false
	var today := int(date.year) * 10000 + int(date.month) * 100 + int(date.day)
	var exclusive_end := year * 10000 + month * 100 + day
	return int(date.year) == year and today < exclusive_end

func claim_launch_greeting(local_date: Dictionary = {}) -> bool:
	if not launch_greeting_eligible(local_date): return false
	launch_greeting_claimed = true
	return true

func greeting_visible() -> bool:
	return is_instance_valid(launch_greeting_layer) and not launch_greeting_layer.is_queued_for_deletion()

func process_launch_greeting() -> void:
	if greeting_visible():
		if not launch_greeting_window_open(): dismiss_launch_greeting()
		return
	if not host.loaded_save_this_boot or launch_greeting_claimed or DisplayServer.get_name() == "headless" or not launch_greeting_eligible(): return
	var boot = host._boot_warmup_runtime()
	if not host.startup_initialized or boot.active or is_instance_valid(boot.overlay): return
	var save = host._save_runtime()
	if save.pending_post_load_saved_at >= 0 or save.boot_post_load_simulation_scheduled: return
	if host._input_routing_shell()._any_modal_overlay_visible(): return
	if launch_greeting_art.is_empty() or not ResourceLoader.exists(launch_greeting_art): return
	var texture := load(launch_greeting_art) as Texture2D
	if texture == null or not claim_launch_greeting(): return
	host._clear_page_transient_input_state()
	launch_greeting_layer = preload("res://scripts/seasonal/halloween_greeting.gd").new()
	launch_greeting_layer.setup(host, texture)
	host.add_child(launch_greeting_layer)

func dismiss_launch_greeting() -> void:
	if is_instance_valid(launch_greeting_layer):
		launch_greeting_layer.queue_free()
	launch_greeting_layer = null
	host._input_routing_shell()._block_background_input_briefly(180)

func can_auto_eat(skill_id: String) -> bool:
	return candy > 0 and bool(auto_by_skill.get(skill_id, false)) and skill_id != "fishing"

# Trick or Treat gives Candy while the event runs.
func gives_candy(skill_id: String, action_id: String) -> bool:
	return skill_id == "thieving" and action_id == "trick-or-treat" and active()

func record_success(skill_id: String, action_id: String, feedback := true) -> void:
	if not gives_candy(skill_id, action_id): return
	# A success, not a button press or a failed attempt, earns one piece.
	var before := candy
	candy = mini(MAX_CANDY, candy + 1)
	ever_earned = true
	host._mark_save_dirty("Halloween candy earned")
	changed.emit()
	if feedback:
		host.material_runtime.report_collected_item(host._action_key(skill_id,action_id),"candy",candy-before)

func eat(skill_id: String, feedback := true) -> int:
	if candy <= 0 or skill_id == "fishing" or not SkillState.has_skill_id(host.skill_defs, skill_id): return 0
	var maximum := float(SkillState.max_stamina(host, skill_id))
	var current := SkillState.host_stamina_value(skill_id, host)
	# Exactly full is allowed; any amount above full rejects a second piece.
	if current > maximum: return 0
	var restored := random.randi_range(10, 15)
	candy -= 1
	host.stamina[skill_id] = current + restored
	SkillState.host_sync_stamina_bank(skill_id, host)
	host._mark_save_dirty("Halloween candy eaten")
	changed.emit()
	if feedback:
		var gauge = host._reward_feedback_surface()._visible_stamina_gauge_for_skill(skill_id, null)
		if gauge != null:
			gauge.sync_for_skill(host, skill_id)
			gauge.play_pop()
	return restored

func auto_eat(skill_id: String, stamina_cost: float, feedback := true) -> void:
	if stamina_cost <= 0.0 or not can_auto_eat(skill_id): return
	# One piece per check, shared inventory, no simultaneous duplicate spend.
	eat(skill_id, feedback)

func set_auto(skill_id: String, value: bool) -> void:
	if not SkillState.has_skill_id(host.skill_defs, skill_id) or skill_id == "fishing": return
	if value: auto_by_skill[skill_id] = true
	else: auto_by_skill.erase(skill_id)
	changed.emit()
	if value: eat(skill_id)
	host.save_game()

func for_save() -> Dictionary:
	return {"candy": candy, "ever_earned": ever_earned, "auto_by_skill": auto_by_skill.duplicate()}

func restore(raw: Variant) -> void:
	var data: Dictionary = raw if raw is Dictionary else {}
	var value: Variant = data.get("candy", 0)
	candy = clampi(int(value), 0, MAX_CANDY) if (value is int or value is float) and is_finite(float(value)) else 0
	ever_earned = data.get("ever_earned", false) == true or candy > 0
	auto_by_skill.clear()
	var saved: Variant = data.get("auto_by_skill", {})
	if saved is Dictionary:
		for skill in saved:
			if saved[skill] == true and str(skill) != "fishing" and SkillState.has_skill_id(host.skill_defs, str(skill)):
				auto_by_skill[str(skill)] = true
	changed.emit()


var pressed_toggle: WeakRef
var press_origin := Vector2.ZERO
var press_pointer := -2

func route_input(event: InputEvent) -> bool:
	if not host.startup_initialized or host._input_routing_shell()._any_modal_overlay_visible():
		pressed_toggle = null
		return false
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		if pressed_toggle != null and event.position.distance_to(press_origin) > 18.0:
			pressed_toggle = null
		return false
	if not (event is InputEventMouseButton or event is InputEventScreenTouch): return false
	if event is InputEventMouseButton and event.button_index != MOUSE_BUTTON_LEFT: return false
	var pointer: int = event.index if event is InputEventScreenTouch else -1
	if event.pressed:
		pressed_toggle = null
		for button in host.get_tree().get_nodes_in_group("auto_eat_candy_toggle"):
			if button.disabled or not button.is_visible_in_tree(): continue
			if button.get_global_rect().has_point(event.position):
				pressed_toggle = weakref(button)
				press_origin = event.position
				press_pointer = pointer
				host._action_runtime()._cancel_pending_stamina_gauge_click()
				return true
	elif pressed_toggle != null and pointer == press_pointer:
		var button = pressed_toggle.get_ref()
		pressed_toggle = null
		if is_instance_valid(button) and button.is_visible_in_tree() and not button.disabled and button.get_global_rect().has_point(event.position):
			button.toggle_candy()
		return true
	return false


func sync_expiry() -> void:
	var is_active := active()
	if was_active == is_active: return
	was_active = is_active
	if not is_active:
		var action: Dictionary = host._action_data("thieving", "trick-or-treat")
		if host.running_action_id == "trick-or-treat":
			host._action_runtime()._stop_running_action("thieving", "trick-or-treat")
		host.actions_by_skill.get("thieving", []).erase(action)
		host.actions_by_key.erase("thieving:trick-or-treat")
		host._project_runtime().configure()
		host._project_runtime().queue_availability_refresh()
		if host.desktop_layout.enabled(): host.desktop_layout.queue_column_refresh("thieving")
		else: host._skill_detail_surface().call_deferred("_refresh_visible_skill_detail_action_list", -1, "thieving")
	changed.emit()
