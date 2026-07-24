extends RefCounted

const ActionRuntime = preload("res://scripts/gameplay/action_runtime.gd")
const GameFormatting = preload("res://scripts/core/formatting.gd")
const SkillState = preload("res://scripts/progression/skill_state.gd")

const BLUE_GUY_HEALTH_MAX := 30
const BLUE_GUY_HEALTH_REGEN_SECONDS := 2.0
const FIGHT_PUNCH_STAMINA_COST_CHANCE := 0.05

var host
var completed_bosses := {}
var blue_guy_health := float(BLUE_GUY_HEALTH_MAX)
var blue_guy_health_bank := 0.0


func _init(host_node = null) -> void:
	host = host_node


func apply_blue_guy_health_regen_seconds(seconds: float) -> void:
	if seconds <= 0.0:
		return
	if blue_guy_health >= float(BLUE_GUY_HEALTH_MAX) - 0.0001:
		blue_guy_health = float(BLUE_GUY_HEALTH_MAX)
		blue_guy_health_bank = 0.0
		return
	var next_bank := clampf(blue_guy_health_bank, 0.0, BLUE_GUY_HEALTH_REGEN_SECONDS) + seconds
	var recovered_hp := int(floor(next_bank / BLUE_GUY_HEALTH_REGEN_SECONDS))
	if recovered_hp > 0:
		blue_guy_health = minf(float(BLUE_GUY_HEALTH_MAX), blue_guy_health + float(recovered_hp))
	blue_guy_health_bank = 0.0 if blue_guy_health >= float(BLUE_GUY_HEALTH_MAX) - 0.0001 else fmod(next_bank, BLUE_GUY_HEALTH_REGEN_SECONDS)


func blue_guy_health_value() -> float:
	return clampf(blue_guy_health, 0.0, float(BLUE_GUY_HEALTH_MAX))


func blue_guy_health_int() -> int:
	return clampi(int(floor(blue_guy_health_value())), 0, BLUE_GUY_HEALTH_MAX)


func blue_guy_health_regen_fraction() -> float:
	if blue_guy_health_value() >= float(BLUE_GUY_HEALTH_MAX) - 0.0001:
		return 1.0
	return clampf(blue_guy_health_bank / BLUE_GUY_HEALTH_REGEN_SECONDS, 0.0, 1.0)


func blue_guy_health_full() -> bool:
	return blue_guy_health_value() >= float(BLUE_GUY_HEALTH_MAX) - 0.0001


func blue_guy_health_bank_for_save() -> float:
	return 0.0 if blue_guy_health_full() else clampf(blue_guy_health_bank, 0.0, BLUE_GUY_HEALTH_REGEN_SECONDS)


func restore_blue_guy_health_from_save(data: Dictionary) -> void:
	blue_guy_health = clampf(float(data.get("blue_guy_health", BLUE_GUY_HEALTH_MAX)), 0.0, float(BLUE_GUY_HEALTH_MAX))
	blue_guy_health_bank = clampf(float(data.get("blue_guy_health_bank", 0.0)), 0.0, BLUE_GUY_HEALTH_REGEN_SECONDS)
	if blue_guy_health_full():
		blue_guy_health_bank = 0.0


func is_boss_fight_action(action: Dictionary) -> bool:
	return str(action.get("kind", "")) == "boss_fight" and typeof(action.get("boss", {})) == TYPE_DICTIONARY and not (action.get("boss", {}) as Dictionary).is_empty()


func boss_id(action: Dictionary) -> String:
	if not is_boss_fight_action(action):
		return ""
	return str((action.get("boss", {}) as Dictionary).get("id", "")).strip_edges()


func boss_name(action: Dictionary) -> String:
	if not is_boss_fight_action(action):
		return ""
	return str((action.get("boss", {}) as Dictionary).get("name", str(action.get("name", "Boss")))).strip_edges()


func boss_is_completed(action: Dictionary) -> bool:
	var id := boss_id(action)
	return not id.is_empty() and bool(completed_bosses.get(id, false))


func completed_bosses_for_save() -> Dictionary:
	var saved := {}
	for raw_id in completed_bosses.keys():
		var id := str(raw_id)
		if not id.is_empty() and bool(completed_bosses.get(raw_id, false)):
			saved[id] = true
	return saved


func restore_completed_bosses_from_save(value: Variant) -> void:
	completed_bosses.clear()
	if typeof(value) != TYPE_DICTIONARY:
		return
	for raw_id in (value as Dictionary).keys():
		var id := str(raw_id).strip_edges()
		if not id.is_empty() and bool((value as Dictionary).get(raw_id, false)):
			completed_bosses[id] = true


func action_boss_requirements_met(action: Dictionary) -> bool:
	return action_missing_boss_requirements(action).is_empty()


func action_missing_boss_requirements(action: Dictionary) -> Array:
	var missing := []
	var raw_requirements = action.get("requires_bosses", [])
	if typeof(raw_requirements) != TYPE_ARRAY:
		return missing
	for raw_id in raw_requirements as Array:
		var id := str(raw_id).strip_edges()
		if not id.is_empty() and not bool(completed_bosses.get(id, false)):
			missing.append(id)
	return missing


func complete_boss_if_needed(action: Dictionary) -> String:
	if not is_boss_fight_action(action):
		return ""
	var id := boss_id(action)
	if id.is_empty() or bool(completed_bosses.get(id, false)):
		return ""
	completed_bosses[id] = true
	return "%s cleared." % boss_name(action)


func action_uses_blue_guy_chicken_brawl_stage(action: Dictionary) -> bool:
	return ActionRuntime.uses_diamond_arena(action)


func action_uses_rooster_punch_out_stage(action: Dictionary) -> bool:
	return str(action.get("id", "")) == "face-the-rooster"


func action_uses_diamond_combat_arena(action: Dictionary) -> bool:
	return ActionRuntime.uses_diamond_arena(action)


func action_is_free_fighting_proto(skill_id: String, action_id: String) -> bool:
	if skill_id != "fight":
		return false
	match action_id:
		"fight-chickens", \
		"chicken-sparring-pit", \
		"fight-goblins", \
		"fight-r.o.u.s.es", \
		"fight-rouses", \
		"fight-guys", \
		"fight-werewolves", \
		"fight-cave-trolls", \
		"fight-giants", \
		"fight-vampires", \
		"fight-dragons":
			return true
	return false


func configure_blue_guy_chicken_brawl_stage(stage: Control) -> void:
	if stage == null or host == null:
		return
	if stage.has_method("setup_fighting_level"):
		stage.call("setup_fighting_level", SkillState.host_skill_level(host, "fight"))
	if stage.has_method("setup_blue_guy_health"):
		stage.call("setup_blue_guy_health", blue_guy_health_int(), BLUE_GUY_HEALTH_MAX, blue_guy_health_regen_fraction())
	if stage.has_method("set_active_fight"):
		stage.call("set_active_fight", action_is_free_fighting_proto(host.running_skill_id, host.running_action_id))
	if stage.has_signal("chicken_killed"):
		var callback := Callable(self, "on_blue_guy_chicken_brawl_chicken_killed").bind(stage)
		if not stage.is_connected("chicken_killed", callback):
			stage.connect("chicken_killed", callback)
	if stage.has_signal("punch_landed"):
		var punch_callback := Callable(self, "on_blue_guy_chicken_brawl_punch_landed")
		if not stage.is_connected("punch_landed", punch_callback):
			stage.connect("punch_landed", punch_callback)
	if stage.has_signal("knocked_out"):
		var ko_callback := Callable(self, "on_blue_guy_chicken_brawl_knocked_out")
		if not stage.is_connected("knocked_out", ko_callback):
			stage.connect("knocked_out", ko_callback)


func configure_rooster_punch_out_stage(stage: Control) -> void:
	if stage == null or host == null:
		return
	if stage.has_method("setup_player_stamina"):
		stage.call("setup_player_stamina", SkillState.host_stamina_value("fight", host))
	if stage.has_method("set_active_fight"):
		stage.call("set_active_fight", host.running_skill_id == "fight" and host.running_action_id == "face-the-rooster")
	if stage.has_signal("boss_defeated"):
		var defeated_callback := Callable(self, "on_rooster_punch_out_boss_defeated")
		if not stage.is_connected("boss_defeated", defeated_callback):
			stage.connect("boss_defeated", defeated_callback)
	if stage.has_signal("stamina_damage"):
		var callback := Callable(self, "on_rooster_punch_out_stamina_damage").bind(stage)
		if not stage.is_connected("stamina_damage", callback):
			stage.connect("stamina_damage", callback)


func on_rooster_punch_out_boss_defeated() -> void:
	if host == null or host.running_skill_id != "fight" or host.running_action_id != "face-the-rooster":
		return
	var action: Dictionary = host._action_data("fight", "face-the-rooster")
	if action.is_empty() or boss_is_completed(action):
		return
	var xp_reward_map: Dictionary = host._action_runtime()._completion_xp_reward_map(action, "fight", false, false, false, false)
	var old_reward_skill_levels: Dictionary = host._action_runtime()._skill_levels_for_reward_map("fight", xp_reward_map)
	var affected_reward_skill_ids: Array = host._action_runtime()._apply_xp_reward_map("fight", xp_reward_map)
	for raw_reward_skill_id in affected_reward_skill_ids:
		SkillState.recalculate_level(host, str(raw_reward_skill_id))
	var boss_clear_text := complete_boss_if_needed(action)
	host._activity_unlock_runtime()._queue_activity_unlock_readiness("fight", 0, SkillState.host_skill_level(host, "fight"), host._activity_unlock_runtime()._ready_lockpads_for_current_state())
	host.last_result = host._action_runtime()._xp_reward_result_sentence(xp_reward_map, "fight", str(action.get("name", "Rooster")))
	if not boss_clear_text.is_empty():
		host.last_result += " %s" % boss_clear_text
	host.running_skill_id = ""
	host.running_action_id = ""
	host.action_progress = 0.0
	host._reward_feedback_surface()._play_action_feedback(host._action_key("fight", "face-the-rooster"), true, host._action_runtime()._reward_map_total(xp_reward_map), 0.0, false, false, xp_reward_map)
	host._audio_director()._play_activity_success_sound(1, false, false, false, false, 0)
	host._audio_director()._record_music_flow_action(true, 1, false, false, host._action_runtime()._any_reward_skill_leveled_up(affected_reward_skill_ids, old_reward_skill_levels), 0.0)
	host._onboarding_runtime()._record_activity_completion_for_tips("fight", "face-the-rooster")
	host._update_ui(0.0, false)
	host.save_game()


func on_rooster_punch_out_stamina_damage(amount: int, stage: Control) -> void:
	if host == null:
		return
	var damage := maxi(0, amount)
	if damage <= 0:
		return
	if not SkillState.spend_action_stamina(host.stamina, host.stamina_bank, "fight", float(damage), Callable(SkillState, "host_max_stamina").bind(host)):
		host.stamina["fight"] = 0.0
		SkillState.host_sync_stamina_bank("fight", host)
	host._reward_feedback_surface()._set_result("Rooster hit you. -%s stamina." % GameFormatting.stamina_cost_detail(float(damage)))
	if stage != null and is_instance_valid(stage):
		if stage.has_method("setup_player_stamina"):
			stage.call("setup_player_stamina", SkillState.host_stamina_value("fight", host))
		if SkillState.host_stamina_value("fight", host) <= 0.0001 and stage.has_method("close_after_stamina_loss"):
			stage.call("close_after_stamina_loss")
	host._update_ui(0.0, false)
	host.save_game()


func on_blue_guy_chicken_brawl_punch_landed(shield_dropped: bool) -> void:
	if host == null:
		return
	host._audio_director()._play_fight_punch_sfx()
	if shield_dropped:
		host._audio_director()._play_goblin_shield_drop_sfx()
	if randf() <= FIGHT_PUNCH_STAMINA_COST_CHANCE:
		SkillState.spend_action_stamina(host.stamina, host.stamina_bank, "fight", 1.0, Callable(SkillState, "host_max_stamina").bind(host))
		host._update_ui(0.0, false)


func on_blue_guy_chicken_brawl_knocked_out() -> void:
	if host == null:
		return
	if not SkillState.spend_action_stamina(host.stamina, host.stamina_bank, "fight", 1.0, Callable(SkillState, "host_max_stamina").bind(host)):
		host.stamina["fight"] = 0.0
		SkillState.host_sync_stamina_bank("fight", host)
	host._reward_feedback_surface()._set_result("Blue Guy was knocked out. -1 stamina.")
	host._update_ui(0.0, false)
	host.save_game()


func on_blue_guy_chicken_brawl_chicken_killed(xp_amount: int, stage: Control) -> void:
	if host == null:
		return
	var amount := maxi(0, xp_amount)
	host._audio_director()._play_chicken_death_sfx()
	if amount <= 0:
		return
	_award_fighting_xp(amount, stage)


func _award_fighting_xp(amount: int, stage: Control) -> void:
	if not host.skills.has("fight"):
		host.skills["fight"] = {"xp": 0, "level": 1}
	host.skills["fight"]["xp"] = int(host.skills["fight"].get("xp", 0)) + amount
	SkillState.recalculate_level(host, "fight")
	if stage != null and is_instance_valid(stage) and stage.has_method("setup_fighting_level"):
		stage.call("setup_fighting_level", SkillState.host_skill_level(host, "fight"))
	host.save_game()


func sync_blue_guy_chicken_brawl_stage_active(card: Dictionary, skill_id: String, action_id: String, running: bool) -> void:
	if host == null:
		return
	var stage := card.get("blue_guy_chicken_stage") as Control
	if stage == null or not is_instance_valid(stage):
		return
	if stage.has_method("setup_fighting_level"):
		stage.call("setup_fighting_level", SkillState.host_skill_level(host, "fight"))
	if stage.has_method("setup_blue_guy_health"):
		stage.call("setup_blue_guy_health", blue_guy_health_int(), BLUE_GUY_HEALTH_MAX, blue_guy_health_regen_fraction())
	if stage.has_method("set_active_fight"):
		var globally_running := bool(host.running_skill_id == skill_id and host.running_action_id == action_id)
		stage.call("set_active_fight", (running or globally_running) and action_is_free_fighting_proto(skill_id, action_id))


func sync_rooster_punch_out_stage_active(card: Dictionary, skill_id: String, action_id: String, running: bool) -> void:
	if host == null:
		return
	var stage := card.get("rooster_boss_stage") as Control
	if stage == null or not is_instance_valid(stage):
		return
	if stage.has_method("setup_player_stamina"):
		stage.call("setup_player_stamina", SkillState.host_stamina_value("fight", host))
	if stage.has_method("set_active_fight"):
		var globally_running := bool(host.running_skill_id == skill_id and host.running_action_id == action_id)
		stage.call("set_active_fight", (running or globally_running) and action_id == "face-the-rooster")
