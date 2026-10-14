extends RefCounted

signal changed(project_id: String)
signal availability_changed
signal resource_sent(source_key: String, resource: String, amount: int, project_id: String)

var host
var definitions: Dictionary = {}
var resource_sources: Dictionary = {}
var resource_targets: Dictionary = {}
var work: Dictionary = {}
var refresh_queued := false
var pending_barrier_refreshes := {}
var needed_resources := {}
var availability_refresh_queued := false

func _init(host_ref) -> void:
	host = host_ref

func configure() -> void:
	definitions.clear()
	resource_sources.clear()
	resource_targets.clear()
	for skill_id in host.actions_by_skill:
		for action in host.actions_by_skill[skill_id]:
			for drop in drops_for(action):
				if not resource_sources.has(str(drop.id)): resource_sources[str(drop.id)] = []
				resource_sources[str(drop.id)].append({"skill": str(skill_id), "action": action, "drop": drop})
			var project: Dictionary = action.get("unlock_project", {})
			if project.is_empty(): continue
			var id := str(project.id)
			definitions[id] = {"skill": str(skill_id), "action": action, "project": project}
			for step in project.steps:
				var resource := str(step.get("resource", ""))
				if not resource_targets.has(resource): resource_targets[resource] = []
				resource_targets[resource].append({"project": id, "step": step, "level": int(action.unlock)})
	for resource in resource_targets:
		resource_targets[resource].sort_custom(func(a, b): return int(a.level) < int(b.level))

func clear() -> void:
	work.clear()
	queue_availability_refresh()
	refresh_queued = false

func amount(id: String, step_id: String) -> int:
	return int((work.get(id, {}) as Dictionary).get(step_id, 0))

func complete(action: Dictionary) -> bool:
	var project: Dictionary = action.get("unlock_project", {})
	if project.is_empty(): return true
	for step in project.steps:
		if amount(str(project.id), str(step.id)) < int(step.target): return false
	return (project.get("cost", {}) as Dictionary).is_empty() or amount(str(project.id), "materials") == 1

func barrier_cleared(skill_id: String, action: Dictionary) -> bool:
	return complete(action) and preload("res://scripts/progression/wisdom_state.gd").requirement_met(host, skill_id, action)

func refresh_cleared_barrier(skill_id: String) -> void:
	if pending_barrier_refreshes.has(skill_id): return
	pending_barrier_refreshes[skill_id] = true
	await host.get_tree().create_timer(0.55).timeout
	pending_barrier_refreshes.erase(skill_id)
	if not is_instance_valid(host) or not host.is_inside_tree(): return
	await _refresh_project_list(skill_id)

func _refresh_project_list(skill_id: String) -> void:
	var detail = host._skill_detail_surface()
	if not host.desktop_layout.enabled() and host.current_screen == "skill" and host.selected_skill_id == skill_id:
		if detail._try_refresh_detail_module_order_in_place():
			return
	await detail._refresh_visible_skill_detail_action_list(-1, skill_id)

func fraction(action: Dictionary) -> float:
	var project: Dictionary = action.get("unlock_project", {})
	if project.is_empty(): return 1.0
	var total := 0.0
	var count: int = project.steps.size()
	for step in project.steps:
		total += clampf(float(amount(str(project.id), str(step.id))) / maxf(1.0, float(step.target)), 0.0, 1.0)
	if not (project.get("cost", {}) as Dictionary).is_empty():
		count += 1
		total += amount(str(project.id), "materials")
	return total / maxf(1.0, count)

func resource_info(resource: String) -> Dictionary:
	var sources: Array = resource_sources.get(resource, [])
	return sources[0].drop if not sources.is_empty() else {}

func best_source(resource: String) -> Dictionary:
	var best := {}
	var best_rate := -1.0
	for entry in resource_sources.get(resource, []):
		if not host._activity_unlock_runtime()._is_action_unlocked(str(entry.skill), entry.action): continue
		var seconds: float = host._action_runtime()._action_cycle_seconds(str(entry.skill), entry.action)
		var success: float = host._action_runtime()._success_chance(str(entry.skill), entry.action)
		var rate := float(entry.drop.amount) * success / maxf(0.1, seconds)
		if rate > best_rate or (is_equal_approx(rate, best_rate) and int(entry.action.unlock) > int(best.action.unlock)):
			best = entry
			best_rate = rate
	return best

func revealed_projects() -> Dictionary:
	# Progression visibility, independent of mounted cards, scrolling or selected skill.
	var revealed := {}
	for owner in host.actions_by_skill:
		for action in host._activity_unlock_runtime()._visible_actions_for_skill(str(owner)):
			var project: Dictionary = action.get("unlock_project", {})
			if not project.is_empty(): revealed[str(project.id)] = true
	return revealed

func next_target(resource: String, revealed: Variant = null) -> Dictionary:
	if resource.begins_with("halloween-") and not host._halloween_runtime().active(): return {}
	var targets: Dictionary = revealed_projects() if revealed == null else revealed
	for entry in resource_targets.get(resource, []):
		if targets.has(str(entry.project)) and amount(str(entry.project), str(entry.step.id)) < int(entry.step.target): return entry
	return {}

func queue_availability_refresh() -> void:
	if availability_refresh_queued: return
	availability_refresh_queued = true
	call_deferred("refresh_availability")

func refresh_availability() -> void:
	availability_refresh_queued = false
	if not is_instance_valid(host) or not host.is_inside_tree(): return
	var revealed := revealed_projects()
	var needed := {}
	for resource in resource_targets:
		if not next_target(str(resource), revealed).is_empty(): needed[str(resource)] = true
	if needed == needed_resources: return
	needed_resources = needed
	availability_changed.emit()

# One resource award per successful completion, shared by active and offline play.
# Units go to one nearest pending blocker, spilling only the remainder forward.
func record_success(skill_id: String, action_id: String, count := 1) -> void:
	if count <= 0: return
	var source: Dictionary = host._action_data(skill_id, action_id)
	for drop in drops_for(source):
		_record_drop(skill_id, action_id, count, drop)

static func drops_for(action: Dictionary) -> Array:
	var drops := []
	for key in ["unlock_drop", "seasonal_unlock_drop"]:
		var drop: Dictionary = action.get(key, {})
		if not drop.is_empty(): drops.append(drop)
	return drops

func _record_drop(skill_id: String, action_id: String, count: int, drop: Dictionary) -> void:
	if str(drop.id).begins_with("halloween-") and not host._halloween_runtime().active(): return
	var units := mini(count, 1000000) * int(drop.amount)
	var revealed := revealed_projects()
	while units > 0:
		var entry := next_target(str(drop.id), revealed)
		if entry.is_empty(): break
		var id := str(entry.project)
		var step: Dictionary = entry.step
		var before := amount(id, str(step.id))
		var sent := mini(units, int(step.target) - before)
		if not work.has(id): work[id] = {}
		work[id][str(step.id)] = before + sent
		units -= sent
		host._mark_save_dirty("unlock resource")
		changed.emit(id)
		resource_sent.emit(host._action_key(skill_id, action_id), str(drop.id), sent, id)
		if complete(definitions[id].action): _queue_refresh()
	queue_availability_refresh()

func can_commit(action: Dictionary) -> bool:
	var project: Dictionary = action.get("unlock_project", {})
	if project.is_empty() or amount(str(project.id), "materials") == 1: return false
	var costs: Dictionary = project.get("cost", {})
	if costs.is_empty(): return false
	for material in costs:
		if host.material_runtime.amount(str(material)) < float(costs[material]): return false
	return true

func commit(action: Dictionary) -> bool:
	if not can_commit(action): return false
	var project: Dictionary = action.unlock_project
	# No yield between checking inventory, payment, permanent credit and the save.
	for material in project.cost:
		host.material_runtime.spend_amount(str(material), float(project.cost[material]))
	var id := str(project.id)
	if not work.has(id): work[id] = {}
	work[id]["materials"] = 1
	host._mark_save_dirty("project materials committed")
	host.save_game()
	changed.emit(id)
	_queue_refresh()
	return true

func _queue_refresh() -> void:
	if refresh_queued: return
	refresh_queued = true
	call_deferred("_refresh_ready_projects")

func _refresh_ready_projects() -> void:
	refresh_queued = false
	if not is_instance_valid(host) or not host.is_inside_tree(): return
	var ready := {}
	for entry in definitions.values():
		var skill := str(entry.skill)
		var action: Dictionary = entry.action
		if complete(action) and not host._activity_unlock_runtime()._is_action_unlocked(skill, action) and host._activity_unlock_runtime()._can_unlock_action(skill, action):
			if not ready.has(skill): ready[skill] = []
			ready[skill].append(str(action.id))
	if not ready.is_empty(): host._activity_unlock_runtime()._queue_activity_unlock_readiness("", 0, 0, ready)
	host._update_ui(0.0, true)

func refresh_unlocked_project(skill_id: String) -> void:
	# Preserve the existing list while replacing the completed barrier's contents.
	await host.get_tree().create_timer(0.22).timeout
	if not is_instance_valid(host) or not host.is_inside_tree(): return
	await _refresh_project_list(skill_id)

func for_save() -> Dictionary:
	return {"version": 2, "work": work.duplicate(true)}

func open_source(skill_id: String, action_id: String) -> void:
	var navigation = host._navigation_shell()
	navigation._select_skill(skill_id)
	for frame in range(300):
		await host.get_tree().process_frame
		if not navigation.screen_render_in_progress: break
	# Desktop settles all column contexts on the following deferred frame.
	await host.get_tree().process_frame
	if host.selected_skill_id == skill_id:
		host._skill_detail_surface()._scroll_to_activity_card(action_id, true, true)

func restore(data: Dictionary) -> void:
	work.clear()
	queue_availability_refresh()
	var raw: Variant = data.get("activity_projects", {})
	var source: Dictionary = raw.get("work", {}) if raw is Dictionary and raw.get("work", {}) is Dictionary else {}
	# Preserve event construction credit after content is switched off.
	for old_id in source:
		if str(old_id).begins_with("halloween-") and source[old_id] is Dictionary:
			work[old_id] = {}
			for step in source[old_id]: work[old_id][step] = _bounded_number(source[old_id][step], 1000000)
	for id in definitions:
		var project: Dictionary = definitions[id].project
		var row: Variant = source.get(id, {})
		if not row is Dictionary: continue
		var normalized := {}
		for step in project.steps:
			normalized[str(step.id)] = _bounded_number(row.get(str(step.id), 0), int(step.target))
		# Retain old paid-material credit for monotonic cloud comparisons. New
		# blockers never consume inventory and no longer require this flag.
		if row.has("materials"): normalized["materials"] = _bounded_number(row.get("materials", 0), 1)
		work[id] = normalized
	if not data.has("activity_projects"):
		# Old access wins. Also grandfather projects within one owner level: their
		# specific local work did not exist in the old save and cannot be reconstructed.
		for id in definitions:
			if str(id).begins_with("halloween-"): continue
			var entry: Dictionary = definitions[id]
			var skill := str(entry.skill)
			var action: Dictionary = entry.action
			var key: String = host._action_key(skill, str(action.id))
			var old_mastery: Dictionary = host.mastery.get(key, {})
			var trusted: bool = host._activity_unlock_runtime()._manual_activity_unlock_flag_is_trusted(skill, str(action.id))
			var established := int((host.skills.get(skill, {}) as Dictionary).get("xp", 0)) > 0
			var near_unlock := established and int(host.skills[skill].get("level", 1)) >= int(action.unlock) - 1
			if trusted or bool(host.built_modules.get(key, false)) or float(old_mastery.get("xp", 0)) > 0 or near_unlock:
				if not work.has(id): work[id] = {}
				for step in entry.project.steps: work[id][str(step.id)] = int(step.target)
				if entry.project.has("cost"): work[id]["materials"] = 1

static func _bounded_number(value: Variant, maximum: int) -> int:
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)): return 0
	return int(clampf(float(value), 0.0, maximum))

static func regresses(before: Variant, after: Variant) -> bool:
	if not before is Dictionary: return false
	var prior: Variant = before.get("work", {})
	var next: Variant = after.get("work", {}) if after is Dictionary else {}
	if not prior is Dictionary: return false
	if not next is Dictionary: next = {}
	for id in prior:
		if not prior[id] is Dictionary: continue
		var row: Variant = next.get(id, {})
		if not row is Dictionary: row = {}
		for step in prior[id]:
			if _bounded_number(prior[id][step], 1000000) > _bounded_number(row.get(step, 0), 1000000): return true
	return false

func decorate_plan(plan: Array, skill_id: String, separation: float) -> Array:
	queue_availability_refresh()
	var result: Array = []
	var included := {}
	# Use progression order, so reversing the visible sort does not change the goal.
	var next_locked := ""
	for candidate in host.actions_by_skill.get(skill_id, []):
		if not host._activity_unlock_runtime()._is_action_unlocked(skill_id, candidate):
			next_locked = str(candidate.id)
			break
	for entry in plan:
		var candidates: Array = []
		var action: Dictionary = (entry.get("entry", {}) as Dictionary).get("action", {})
		if not action.is_empty(): candidates.append(action)
		if str(entry.get("kind", "")) == "fishing_area":
			for method_id in entry.get("method_ids", []): candidates.append(host._action_data(skill_id, str(method_id)))
		for candidate in candidates:
			var project: Dictionary = candidate.get("unlock_project", {})
			if project.is_empty() or included.has(str(project.id)) or host._activity_unlock_runtime()._is_action_unlocked(skill_id, candidate) or barrier_cleared(skill_id, candidate): continue
			included[str(project.id)] = true
			result.append({"kind": "project", "entry": {"action": candidate, "next_unlock": str(candidate.id) == next_locked}, "track_id": "project:" + str(project.id), "height": preload("res://scripts/ui/project_panel.gd").height_for(candidate, str(candidate.id) == next_locked), "mounted": false, "stack_host": null, "placeholder": null, "direct_stack_child": false})
		# Work and resources clear the barrier first. The ordinary activity card
		# then supplies its existing level padlock and unlock ceremony.
		if not action.is_empty() and action.has("unlock_project") and not host._activity_unlock_runtime()._is_action_unlocked(skill_id, action) and not barrier_cleared(skill_id, action):
			continue
		result.append(entry)
	var y := 0.0
	for entry in result:
		entry["y"] = y
		y += float(entry.height) + separation
	return result
