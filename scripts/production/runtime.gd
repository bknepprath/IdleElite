extends RefCounted

signal recipe_completed(action_id: String, outputs: Dictionary)

const QUEUE_RECIPE_IDS := ["melt-sand","shape-bottles","grind-lens","carve-spyglass-tube","make-candles","mix-fishing-bait"]

var host
var rules: Dictionary = {}
var state: Dictionary = {}
var offline_tracking := false
var offline_advanced := 0.0

func _init(owner) -> void:
	host = owner
	reset()

func configure(database: Dictionary) -> void:
	rules = database.get("global_rules", {}).get("production", {}).duplicate(true)
	host.material_runtime.configure_production(rules.get("materials", {}))

func reset() -> void:
	state = {"version":2,"bottling":false,"use_bottled_honey":false,"bottles_seen":false,"legacy_honey_bottles":0,"partial_honey":0,"activated_units":0,"escrow":{},"wheel_clearance":0,"wheel_progress":0,"wheel_built":false,"queue":[],"next_job":1,"bait_locations":{},"scout_index":0,"light_charges":0,"selective_net":false}

func recipe(action: Dictionary) -> Dictionary:
	return rules.get("recipes", {}).get(str(action.get("production", {}).get("recipe", "")), {})

func recipe_key(action: Dictionary) -> String:
	return str(action.get("id", ""))

func available_inputs(inputs: Dictionary) -> bool:
	for id in inputs:
		if host.material_runtime.amount(str(id)) + 0.0001 < float(inputs[id]): return false
	return true

func reserve(key: String, inputs: Dictionary) -> bool:
	if state.escrow.has(key): return true
	if not available_inputs(inputs): return false
	for id in inputs: host.material_runtime.spend_amount(str(id), float(inputs[id]))
	state.escrow[key] = inputs.duplicate()
	return true

func missing_inputs(action: Dictionary) -> Dictionary:
	var definition := recipe(action)
	var inputs: Dictionary = definition.get("inputs", {})
	if bool(action.get("production", {}).get("waterwheel", false)): inputs = rules.get("waterwheel", {}).get("cost", {})
	var missing := {}
	for id in inputs:
		var needed := maxf(0.0, float(inputs[id]) - host.material_runtime.amount(str(id)))
		if needed > 0.0001: missing[id] = needed
	return missing

func cycle_ready(action: Dictionary) -> bool:
	var production: Dictionary = action.get("production", {})
	if bool(production.get("waterwheel", false)):
		if state.wheel_built or int(state.wheel_clearance) < int(rules.get("waterwheel", {}).get("work", 8)): return false
		return reserve("waterwheel", rules.get("waterwheel", {}).get("cost", {}))
	var definition := recipe(action)
	if definition.is_empty(): return true
	if int(definition.get("limit", 0)) > 0:
		for id in definition.get("outputs", {}):
			if host.material_runtime.amount(str(id)) >= float(definition.limit): return false
	if bool(definition.get("light", false)) and int(state.light_charges) > 0: return true
	return reserve(recipe_key(action), definition.get("inputs", {}))

func award_outputs(outputs: Dictionary) -> void:
	for id in outputs: host.material_runtime.add_amount(str(id), float(outputs[id]))

func complete(action: Dictionary) -> void:
	var production: Dictionary = action.get("production", {})
	if bool(production.get("wheel_work", false)): state.wheel_clearance = mini(8, int(state.wheel_clearance) + 1)
	if bool(production.get("waterwheel", false)) and state.escrow.has("waterwheel"):
		state.wheel_progress = mini(8, int(state.wheel_progress) + 1)
		if int(state.wheel_progress) == 8:
			state.wheel_built = true
			state.escrow.erase("waterwheel")
	var definition := recipe(action)
	if definition.is_empty(): return
	var key := recipe_key(action)
	if bool(definition.get("light", false)):
		if int(state.light_charges) <= 0 and state.escrow.has(key):
			state.light_charges = 3 if host.material_runtime.amount("lantern") >= 1 else 1
		if int(state.light_charges) <= 0: return
		state.light_charges = int(state.light_charges) - 1
	elif not state.escrow.has(key): return
	state.escrow.erase(key)
	award_outputs(definition.get("outputs", {}))
	if not offline_tracking:
		recipe_completed.emit(str(action.get("id", "")), definition.get("outputs", {}))

func bottles_available() -> bool:
	if not state.bottles_seen and (host.material_runtime.amount("empty-bottle") >= 1 or host.material_runtime.amount("bottled-honey") >= 1):
		state.bottles_seen = true
		host._mark_save_dirty("bottles discovered")
	return bool(state.bottles_seen)

func honey_output_id() -> String:
	return "bottled-honey" if bool(state.bottling) and host.material_runtime.amount("empty-bottle") >= 1 else "honey"

func divert_honey(amount: float, feedback_key := "", harvest_count := 1) -> float:
	if not bool(state.bottling): return amount
	var bottles := mini(int(floor(maxf(0, amount))), int(floor(host.material_runtime.amount("empty-bottle"))))
	if bottles <= 0: return amount
	if not host.material_runtime.spend_amount("empty-bottle", bottles): return amount
	host.material_runtime.collect_amount("bottled-honey", bottles, feedback_key, harvest_count)
	bottles_available()
	return amount - bottles

func open_honey() -> bool:
	if not host.material_runtime.spend_amount("bottled-honey", 1): return false
	host.material_runtime.add_amount("empty-bottle", 1)
	var units := maxi(1, int(float(rules.get("honey_seconds_per_bottle", 10)) / 10.0))
	if int(state.legacy_honey_bottles) > 0:
		state.legacy_honey_bottles = int(state.legacy_honey_bottles) - 1
		units = 6
	state.activated_units = int(state.activated_units) + units
	host._mark_save_dirty("bottled honey opened")
	return true

func honey_available() -> bool:
	return int(state.activated_units) > 0 or host.material_runtime.amount("honey") >= 1 or enabled_bottled_seconds() > 0

func bottled_honey_enabled_for_task() -> bool:
	return bool(state.use_bottled_honey) and (not str(host.running_action_id).is_empty() or not str(host._temporary_event_runtime().event_running_action_id).is_empty())

func enabled_bottled_seconds() -> float:
	if not bottled_honey_enabled_for_task(): return 0
	var count := int(floor(host.material_runtime.amount("bottled-honey")))
	var legacy := mini(count, int(state.legacy_honey_bottles))
	return float(legacy * 60 + (count - legacy) * 10)

func spend_honey() -> bool:
	if int(state.activated_units) <= 0 and bottled_honey_enabled_for_task(): open_honey()
	if int(state.activated_units) > 0:
		state.activated_units = int(state.activated_units) - 1
		return true
	return host.material_runtime.spend_amount("honey", 1)

func activated_seconds() -> float:
	return int(state.activated_units) * 10.0

func spend_offline_units(units: int) -> int:
	var remaining := units
	while remaining > 0:
		if int(state.activated_units) <= 0 and (not bottled_honey_enabled_for_task() or not open_honey()): break
		var take := mini(remaining, int(state.activated_units))
		state.activated_units = int(state.activated_units) - take
		remaining -= take
	return remaining

func scouting_target(action_id: String) -> String:
	if host.material_runtime.amount("spyglass") < 1: return ""
	return str(rules.get("scouting", {}).get(action_id, ""))

func bait_active(action_id: String) -> bool:
	return not scouting_target(action_id).is_empty() and bool(state.bait_locations.get(action_id, false)) and host.material_runtime.amount("bait") >= 1

func fishing_food_multiplier(action_id: String) -> float:
	return 0.5 if bait_active(action_id) else 1.0

func fishing_success(action_id: String) -> void:
	if not bait_active(action_id) or not host.material_runtime.spend_amount("bait", 1): return
	var amount := 2 if bool(state.selective_net) and host.material_runtime.amount("precision-net") >= 1 and host.fishing_runtime.equipped_tool_id == "net" else 1
	host.material_runtime.add_amount(scouting_target(action_id), amount)
	host._action_runtime().invalidate_stat_cache()

func toggle_bait(action_id: String) -> void:
	if scouting_target(action_id).is_empty(): return
	state.bait_locations[action_id] = not bool(state.bait_locations.get(action_id, false))
	host._action_runtime().invalidate_stat_cache()
	host._mark_save_dirty("fishing bait choice")

func supports_queue(action_id: String) -> bool:
	return action_id in QUEUE_RECIPE_IDS

func enqueue(action_id: String) -> bool:
	if not bool(state.wheel_built) or state.queue.size() >= int(rules.get("waterwheel", {}).get("queue_capacity", 12)): return false
	if not supports_queue(action_id): return false
	var action: Dictionary = host._action_data("build", action_id)
	if not host._activity_unlock_runtime()._is_action_unlocked("build", action): return false
	if not preload("res://scripts/gameplay/buildable_modules.gd").is_built(host.built_modules,"build",action,Callable(host,"_action_key")): return false
	var key := "queue:%s" % int(state.next_job)
	while state.escrow.has(key):
		state.next_job = int(state.next_job) + 1
		key = "queue:%s" % int(state.next_job)
	if not reserve(key, recipe(action).get("inputs", {})): return false
	state.next_job = int(state.next_job) + 1
	state.queue.append({"id":action_id,"key":key,"elapsed":0.0})
	host._mark_save_dirty("waterwheel queue")
	return true

func advance_queue(seconds: float) -> void:
	if offline_tracking: offline_advanced += maxf(0.0,seconds)
	if not bool(state.wheel_built) or seconds <= 0: return
	var remaining := seconds
	while remaining > 0 and not state.queue.is_empty():
		var job: Dictionary = state.queue[0]
		var action: Dictionary = host._action_data("build", str(job.id))
		var duration := maxf(1.0, float(action.get("seconds", 6)))
		var step := minf(remaining, maxf(0.0, duration - float(job.elapsed)))
		job.elapsed = float(job.elapsed) + step
		remaining -= step
		if float(job.elapsed) + 0.0001 < duration: break
		if state.escrow.has(str(job.key)):
			award_outputs(recipe(action).get("outputs", {}))
			state.escrow.erase(str(job.key))
		state.queue.pop_front()
		host._mark_save_dirty("waterwheel finished recipe")

func next_queue_seconds() -> float:
	if state.queue.is_empty(): return INF
	var job: Dictionary = state.queue[0]
	return maxf(0.001,float(host._action_data("build",str(job.id)).get("seconds",6)) - float(job.elapsed))

func finished(action: Dictionary) -> bool:
	if bool(action.get("production", {}).get("waterwheel",false)): return bool(state.wheel_built)
	var definition := recipe(action)
	if int(definition.get("limit",0)) > 0:
		for id in definition.get("outputs", {}):
			if host.material_runtime.amount(str(id)) >= float(definition.limit): return true
	return false

func for_save() -> Dictionary:
	return state.duplicate(true)

func navigate_to_action(skill: String, action_id: String) -> void:
	# Keep this continuation off the stage that navigation removes. Wait for
	# layout and scrolling to become ready, including Fishing location aliases.
	host._navigation_shell()._select_skill_with_initial_scroll(skill,false,0)
	for frame in 120:
		await host.get_tree().process_frame
		if host.current_screen!="skill" or host.selected_skill_id!=skill: return
		if host._navigation_shell().screen_render_in_progress or host.boot_detail_render_in_progress: continue
		var detail=host._skill_detail_surface()
		var entry: Dictionary=detail._detail_lazy_entry_for_track_id(action_id)
		var slot: Control=entry.get("stack_host")
		if not is_instance_valid(slot) or not is_instance_valid(detail.detail_actions_scroll): continue
		if detail.detail_actions_scroll.get_max_scroll_vertical()<=0: continue
		detail._scroll_to_list_entry(action_id,false)
		await host.get_tree().process_frame
		if host.current_screen!="skill" or host.selected_skill_id!=skill: return
		if is_instance_valid(slot) and detail.detail_actions_scroll.get_global_rect().has_point(slot.get_global_rect().get_center()): return

func bounded_int(value: Variant, maximum: int) -> int:
	if typeof(value) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value)): return 0
	return clampi(int(value),0,maximum)

func restored_inputs(key: String, saved: Variant) -> Variant:
	# Preserve already paid prototype work without charging the new recipe again.
	var previous := {
		"melt-sand":{"sand":2,"scrapwood":1},
		"assemble-spyglass":{"lens":2,"spyglass-tube":1},
		"assemble-lantern":{"glass":3,"hardwood":2},
		"weave-selective-net":{"pearl-scale":12,"softwood":6},
		"waterwheel":{"softwood":30,"glass":4}
	}
	if previous.has(key) and matching_inputs(saved,previous[key]):
		if key == "waterwheel": return rules.get("waterwheel",{}).get("cost",{}).duplicate()
		return rules.get("recipes",{}).get(key,{}).get("inputs",{}).duplicate()
	return saved

func matching_inputs(saved: Variant, expected: Dictionary) -> bool:
	if not saved is Dictionary or saved.size() != expected.size(): return false
	for key in expected:
		var amount: Variant=saved.get(key)
		if typeof(amount) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(amount)): return false
		if float(amount) != float(expected[key]): return false
	return true

func restore(value: Variant) -> void:
	reset()
	if not value is Dictionary: return
	for key in ["bottling","use_bottled_honey","bottles_seen","wheel_built","selective_net"]: state[key] = value.get(key, false) == true
	state.legacy_honey_bottles = mini(int(host.material_runtime.amount("bottled-honey")), bounded_int(value.get("legacy_honey_bottles", 0), 10000000))
	if int(value.get("version", 1)) < 2:
		state.legacy_honey_bottles = int(host.material_runtime.amount("bottled-honey"))
	for key in ["partial_honey","activated_units","wheel_clearance","wheel_progress","scout_index","light_charges","next_job"]:
		state[key] = bounded_int(value.get(key,0), {"partial_honey":5,"activated_units":10000000,"wheel_clearance":8,"wheel_progress":8,"light_charges":3,"next_job":1000000000}.get(key,100))
	state.next_job = maxi(1, int(state.next_job))
	if int(state.partial_honey) > 0:
		# Old partial jars had already paid one empty bottle. Return that bottle
		# and its honey without manufacturing a complete 60-second jar.
		host.material_runtime.add_amount("empty-bottle", 1)
		host.material_runtime.add_amount("honey", int(state.partial_honey))
		state.partial_honey = 0
	var saved_bait: Variant=value.get("bait_locations",{})
	var saved_escrow: Variant=value.get("escrow",{})
	var saved_queue: Variant=value.get("queue",[])
	if saved_bait is Dictionary:
		for id in rules.get("scouting", {}): state.bait_locations[id] = saved_bait.get(id,false) == true
	if saved_escrow is Dictionary:
		for key in saved_escrow:
			var inputs: Dictionary = {}
			if str(key) == "waterwheel": inputs = rules.get("waterwheel", {}).get("cost", {})
			elif rules.get("recipes", {}).has(str(key)): inputs = rules.recipes[key].get("inputs", {})
			if not inputs.is_empty() and matching_inputs(restored_inputs(str(key),saved_escrow[key]),inputs): state.escrow[key] = inputs.duplicate()
	if saved_queue is Array and saved_escrow is Dictionary:
		for raw in saved_queue:
			if state.queue.size() >= 12: break
			if not raw is Dictionary or str(raw.get("id","")) not in ["melt-sand","shape-bottles","grind-lens","carve-spyglass-tube","make-candles","mix-fishing-bait"]: continue
			var key := str(raw.get("key", ""))
			if not key.begins_with("queue:") or state.escrow.has(key): continue
			var inputs: Dictionary = rules.get("recipes", {}).get(str(raw.id), {}).get("inputs", {})
			if not matching_inputs(restored_inputs(str(raw.id),saved_escrow.get(key, {})),inputs): continue
			var elapsed := float(raw.get("elapsed",0)) if typeof(raw.get("elapsed",0)) in [TYPE_INT,TYPE_FLOAT] else 0.0
			if not is_finite(elapsed): elapsed = 0.0
			state.escrow[key] = inputs.duplicate()
			state.queue.append({"id":str(raw.id),"key":key,"elapsed":clampf(elapsed,0.0,60.0)})
