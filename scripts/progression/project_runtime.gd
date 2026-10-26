extends RefCounted

signal changed(project_id: String)
signal availability_changed
signal resource_sent(source_key: String, resource: String, amount: int, project_id: String)

var host
var definitions: Dictionary = {}
var resource_sources: Dictionary = {}
var resource_targets: Dictionary = {}
# Resources that any activity of one skill gives: resource id -> skill id.
var skill_wide_resources: Dictionary = {}
# What a requirement for such a resource is multiplied by today: resource id ->
# multiplier. Saved beside the work, which is counted against it. See restore().
var target_multipliers: Dictionary = {}
var work: Dictionary = {}
var refresh_queued := false
var pending_barrier_refreshes := {}
var needed_resources := {}
var availability_refresh_queued := false
var availability_inputs := 0
var availability_work_hash := 0
var availability_valid := false
var reveal_cache := {}
var reveal_cache_inputs := 0
var reveal_cache_work_hash := 0
var reveal_cache_valid := false
# Project work exactly as the save file held it. See for_save().
var saved_work_floor: Dictionary = {}
# A tap on a requirement or a resource icon explains it. A second tap on the
# same one within this time goes where it leads. See second_tap().
const DOUBLE_TAP_MSEC := 500
const GO_THERE_HINT := "\nDouble tap to go there"
var last_tap_key := ""
var last_tap_msec := 0

func _init(host_ref) -> void:
	host = host_ref

func configure() -> void:
	definitions.clear()
	resource_sources.clear()
	resource_targets.clear()
	skill_wide_resources.clear()
	target_multipliers.clear()
	reveal_cache_valid = false
	availability_valid = false
	for skill_id in host.actions_by_skill:
		for action in host.actions_by_skill[skill_id]:
			for drop in drops_for(action):
				if not resource_sources.has(str(drop.id)): resource_sources[str(drop.id)] = []
				resource_sources[str(drop.id)].append({"skill": str(skill_id), "action": action, "drop": drop})
				if drop.has("any_activity_skill"): skill_wide_resources[str(drop.id)] = str(drop.any_activity_skill)
			var project: Dictionary = action.get("unlock_project", {})
			if project.is_empty(): continue
			var id := str(project.id)
			definitions[id] = {"skill": str(skill_id), "action": action, "project": project}
			for step in project.steps:
				var resource := str(step.get("resource", ""))
				if not resource_targets.has(resource): resource_targets[resource] = []
				resource_targets[resource].append({"project": id, "step": step, "level": int(action.unlock)})
				if step.has("target_multiplier"): target_multipliers[resource] = float(step.target_multiplier)
	for resource in resource_targets:
		resource_targets[resource].sort_custom(func(a, b): return int(a.level) < int(b.level))

func clear() -> void:
	work.clear()
	saved_work_floor.clear()
	reveal_cache_valid = false
	availability_valid = false
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

# What a requirement is called. One that any activity of a skill fills stands for
# work in that skill and goes by the skill's name; the rest are items.
func resource_title(resource: String) -> String:
	if skill_wide_resources.has(resource):
		return SkillState.skill_name(host.skill_defs, str(skill_wide_resources[resource]))
	return str(resource_info(resource).get("name", resource.capitalize()))

# True for the second of two taps on the same thing (key) in quick succession.
func second_tap(key: String) -> bool:
	var now := Time.get_ticks_msec()
	var second := key == last_tap_key and now - last_tap_msec <= DOUBLE_TAP_MSEC
	last_tap_key = "" if second else key
	last_tap_msec = now
	return second

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
	_sync_reveal_cache()
	var revealed := {}
	for owner in host.actions_by_skill:
		revealed.merge(_cached_revealed_projects_for_skill(str(owner)))
	return revealed

func _revealed_projects_for_skill(owner: String) -> Dictionary:
	var revealed := {}
	for action in host._activity_unlock_runtime()._visible_actions_for_skill(owner):
		var project: Dictionary = action.get("unlock_project", {})
		if not project.is_empty(): revealed[str(project.id)] = true
	return revealed

# Working out which projects a skill reveals walks every activity of that skill.
# Every completion asked for all five skills, twice. Keep the answer per skill and
# drop it only when something that decides visibility has changed.
func _sync_reveal_cache() -> void:
	var inputs := _reveal_inputs_stamp()
	var work_hash := hash(work)
	if reveal_cache_valid and inputs == reveal_cache_inputs and work_hash == reveal_cache_work_hash: return
	reveal_cache.clear()
	reveal_cache_inputs = inputs
	reveal_cache_work_hash = work_hash
	reveal_cache_valid = true

func _cached_revealed_projects_for_skill(owner: String) -> Dictionary:
	if not reveal_cache.has(owner): reveal_cache[owner] = _revealed_projects_for_skill(owner)
	return reveal_cache[owner]

# Everything except project work that decides whether an activity is visible.
func _reveal_inputs_stamp() -> int:
	var levels := PackedInt32Array()
	for skill_id in host.skills:
		levels.append(SkillState.host_skill_level(host, str(skill_id)))
	var unlocks = host._activity_unlock_runtime()
	var onboarding = host._onboarding_runtime()
	return hash([
		levels,
		unlocks.manual_activity_unlocks,
		# Asking settles the cached verdict, as the first unlock check would.
		unlocks._manual_activity_unlocks_are_trusted(),
		host.material_runtime.wisdom_by_skill,
		host._fighting_runtime().completed_bosses,
		host._temporary_event_runtime().temporary_event_active,
		onboarding.tutorial_active,
		onboarding.tutorial_gate_latch_only_until_swipe,
	])

func next_target(resource: String, revealed: Variant = null) -> Dictionary:
	if resource.begins_with("halloween-") and not host._halloween_runtime().active(): return {}
	var targets: Dictionary = revealed_projects() if revealed == null else revealed
	for entry in resource_targets.get(resource, []):
		if targets.has(str(entry.project)) and amount(str(entry.project), str(entry.step.id)) < int(entry.step.target): return entry
	return {}

# next_target() for the completion path: only the owner skills of projects that
# still need this resource are asked. Call _sync_reveal_cache() first.
func _next_revealed_target(resource: String) -> Dictionary:
	for entry in resource_targets.get(resource, []):
		var id := str(entry.project)
		if amount(id, str(entry.step.id)) >= int(entry.step.target): continue
		if _cached_revealed_projects_for_skill(str(definitions[id].skill)).has(id): return entry
	return {}

func queue_availability_refresh() -> void:
	if availability_refresh_queued: return
	availability_refresh_queued = true
	call_deferred("refresh_availability")

func refresh_availability() -> void:
	availability_refresh_queued = false
	if not is_instance_valid(host) or not host.is_inside_tree(): return
	# Queued after every completion and every card mount. The answer can only change
	# when visibility does or a step opens or closes, so skip the work until then.
	var inputs := hash([_reveal_inputs_stamp(), host._halloween_runtime().active()])
	var work_hash := hash(work)
	if availability_valid and inputs == availability_inputs and work_hash == availability_work_hash: return
	availability_inputs = inputs
	availability_work_hash = work_hash
	availability_valid = true
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
	# unlock_drop is the activity's own item. skill_unlock_drop is the one resource
	# every activity of its skill gives (the catalog adds it), for unlock projects
	# that ask for work in the skill rather than for one activity's item.
	for key in ["unlock_drop", "skill_unlock_drop", "seasonal_unlock_drop"]:
		var drop: Dictionary = action.get(key, {})
		if not drop.is_empty(): drops.append(drop)
	return drops

func _record_drop(skill_id: String, action_id: String, count: int, drop: Dictionary) -> void:
	if str(drop.id).begins_with("halloween-") and not host._halloween_runtime().active(): return
	var units := mini(count, 1000000) * int(drop.amount)
	_sync_reveal_cache()
	var work_hash_before := reveal_cache_work_hash
	var sent_any := false
	var step_closed := false
	while units > 0:
		var entry := _next_revealed_target(str(drop.id))
		if entry.is_empty(): break
		var id := str(entry.project)
		var step: Dictionary = entry.step
		var before := amount(id, str(step.id))
		var sent := mini(units, int(step.target) - before)
		if not work.has(id): work[id] = {}
		work[id][str(step.id)] = before + sent
		units -= sent
		sent_any = true
		host._mark_save_dirty("unlock resource")
		changed.emit(id)
		resource_sent.emit(host._action_key(skill_id, action_id), str(drop.id), sent, id)
		if complete(definitions[id].action): _queue_refresh()
		if before + sent >= int(step.target):
			# A finished step can reveal the next blocker. Look again, so the rest of
			# a large award (time away arrives as one) goes on to it.
			step_closed = true
			reveal_cache_valid = false
			_sync_reveal_cache()
	if sent_any:
		# Part-filling a step changes neither what is visible nor what is still
		# needed, so the remembered answers stay good for the new work state.
		var work_hash := hash(work)
		reveal_cache_work_hash = work_hash
		if not step_closed and availability_valid and availability_work_hash == work_hash_before: availability_work_hash = work_hash
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

func for_save() -> Dictionary:
	# restore() drops steps that no longer exist and caps the rest at today's
	# targets. Writing that back after a content edit (a lowered target, a renamed
	# step) would read as lost progress, and the save guard would then refuse every
	# later save. So never write less than the file already held.
	var saved := work.duplicate(true)
	for id in saved_work_floor:
		if not saved.has(id) or not saved[id] is Dictionary: saved[id] = {}
		for step in saved_work_floor[id]:
			saved[id][step] = maxi(_bounded_number(saved[id].get(step, 0), 1000000), int(saved_work_floor[id][step]))
	return {"version": 2, "work": saved, "target_multipliers": target_multipliers.duplicate()}

# Shows a skill page for a jump to one place on it. The page is opened without
# its usual landing on the latest activity: that landing arrives a frame after
# the page and, when it wins, takes the card the jump wanted off the list.
func _open_page_for_jump(skill_id: String) -> bool:
	var navigation = host._navigation_shell()
	# The message that offered the jump would stay up over the place it lands on.
	navigation._clear_nav_locked_message()
	if host.current_screen != "skill" or host.selected_skill_id != skill_id:
		navigation._select_skill_with_initial_scroll(skill_id, false, -1)
		for frame in range(300):
			await host.get_tree().process_frame
			if not navigation.screen_render_in_progress: break
		# Desktop settles all column contexts on the following deferred frame.
		await host.get_tree().process_frame
	return host.current_screen == "skill" and host.selected_skill_id == skill_id

func open_source(skill_id: String, action_id: String) -> void:
	if await _open_page_for_jump(skill_id):
		host._skill_detail_surface()._scroll_to_list_entry(action_id)

# The reverse of open_source(): from the badge on a source activity to the
# locked activity its resource is filling. A tap says what that is; with go set
# (the second tap of two) it goes there.
func open_target(resource: String, anchor: Control = null, go := true) -> void:
	var entry := next_target(resource)
	if entry.is_empty(): return
	var id := str(entry.project)
	var owner := str(definitions[id].skill)
	if not go:
		host._navigation_shell()._float_nav_locked_message(anchor, "%s %d / %d\nfor %s%s" % [resource_title(resource), amount(id, str(entry.step.id)), int(entry.step.target), str(definitions[id].action.name), GO_THERE_HINT])
		return
	open_project(owner, id)

# Goes to the frame of a locked activity on its skill's page.
func open_project(owner: String, id: String) -> void:
	if await _open_page_for_jump(owner):
		host._skill_detail_surface()._scroll_to_project_panel(id)

# The activity a tap on a required resource can go to: the best unlocked one that
# gives it. Empty when none is unlocked yet, and always for a requirement that
# any activity of a skill fills, which has no one place to go.
func source_to_open(resource: String) -> Dictionary:
	return {} if skill_wide_resources.has(resource) else best_source(resource)

# What a required resource is and where it comes from, for a tap on it. best is
# source_to_open(resource).
func resource_explanation(resource: String, best: Dictionary) -> String:
	var title := resource_title(resource)
	if skill_wide_resources.has(resource):
		return "%s\nAny %s activity counts" % [title, title]
	if not best.is_empty():
		return "%s\nFrom %s" % [title, str(best.action.name)]
	var first := {}
	for entry in resource_sources.get(resource, []):
		if first.is_empty() or int(entry.action.unlock) < int(first.action.unlock): first = entry
	if first.is_empty(): return title
	return "%s\nFrom %s, %s Lv %d" % [title, str(first.action.name), SkillState.skill_name(host.skill_defs, str(first.skill)), int(first.action.unlock)]

func restore(data: Dictionary) -> void:
	work.clear()
	reveal_cache_valid = false
	availability_valid = false
	queue_availability_refresh()
	var raw: Variant = data.get("activity_projects", {})
	var source: Dictionary = raw.get("work", {}) if raw is Dictionary and raw.get("work", {}) is Dictionary else {}
	var saved_multipliers: Dictionary = raw.get("target_multipliers", {}) if raw is Dictionary and raw.get("target_multipliers", {}) is Dictionary else {}
	saved_work_floor = {}
	for loaded_id in source:
		if not source[loaded_id] is Dictionary: continue
		var floor_row := {}
		for loaded_step in source[loaded_id]: floor_row[str(loaded_step)] = _bounded_number(source[loaded_id][loaded_step], 1000000)
		saved_work_floor[str(loaded_id)] = floor_row
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
			normalized[str(step.id)] = _bounded_number(_amount_at_todays_target(row.get(str(step.id), 0), step, saved_multipliers), int(step.target))
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

# A requirement for a resource that any activity of a skill gives asks for
# target_multiplier times its listed amount (the catalog keeps both on the step).
# A save written when that number was lower, or before there was one, counted
# against the lower target. Its amount is brought up to today's: what was
# finished stays finished, and what was part done keeps its share. Without this
# a raised multiplier would lock activities the player had already unlocked.
static func _amount_at_todays_target(value: Variant, step: Dictionary, saved_multipliers: Dictionary) -> Variant:
	var multiplier := float(step.get("target_multiplier", 1.0))
	var saved: Variant = saved_multipliers.get(str(step.get("resource", "")), 1.0)
	var saved_multiplier := maxf(1.0, float(saved)) if typeof(saved) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(saved)) else 1.0
	if multiplier <= saved_multiplier or typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)):
		return value
	var saved_target := maxi(1, roundi(float(step.get("listed_target", step.target)) * saved_multiplier))
	if float(value) >= saved_target:
		return int(step.target)
	return roundi(maxf(0.0, float(value)) * float(step.target) / saved_target)

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
