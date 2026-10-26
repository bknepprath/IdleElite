extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func run() -> void:
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES","1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS","1")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.activity_data_catalog.load_action_data(game)
	game._save_runtime()._init_state()
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	for skill in game.skills:
		game.skills[skill].xp = preload("res://scripts/progression/skill_state.gd").xp_for_level(99)
		game.skills[skill].level = 99
	var production = game._production_runtime()
	var mats = game.material_runtime
	check(mats.has_definition("sand") and mats.has_definition("bottled-honey"),"Production materials load from database")
	var melt: Dictionary = game._action_data("build","melt-sand")
	mats.set_amount("sand",4)
	mats.set_amount("scrapwood",0)
	check(production.cycle_ready(melt),"Recipe starts with its inputs")
	check(mats.amount("sand")==2 and mats.amount("scrapwood")==0,"Only Sand is required and reserved once before work")
	check(production.cycle_ready(melt) and mats.amount("sand")==2,"Repeated readiness does not spend twice")
	production.complete(melt)
	production.complete(melt)
	check(mats.amount("glass")==1,"Output cannot be duplicated without a new reservation")
	check(production.cycle_ready(melt),"Next cycle reserves the next batch")
	var saved: Dictionary = production.for_save()
	production.restore(saved)
	production.complete(melt)
	check(mats.amount("glass")==2 and not production.cycle_ready(melt),"Reserved work survives reload and stops at exhaustion")
	production.restore({"escrow":{"melt-sand":{"sand":2,"scrapwood":1}}})
	check(production.matching_inputs(production.state.escrow.get("melt-sand",{}),{"sand":2}),"Legacy paid Sand and wood batch migrates without a second payment")
	production.complete(melt)
	check(mats.amount("glass")==3 and mats.amount("sand")==0 and mats.amount("scrapwood")==0,"Legacy paid active batch completes once with no new input charge")
	production.restore({"wheel_built":true,"escrow":{"queue:71":{"sand":2,"scrapwood":1}},"queue":[{"id":"melt-sand","key":"queue:71","elapsed":2}]})
	check(production.state.queue.size()==1 and production.state.queue[0].elapsed==2,"Legacy queued Glass keeps its paid progress")
	production.advance_queue(20)
	check(mats.amount("glass")==4 and production.state.queue.is_empty(),"Legacy paid queued Glass completes once without spending Sand or wood again")
	production.restore({"escrow":{"melt-sand":{"sand":1,"scrapwood":1},"queue:72":{"sand":2,"scrapwood":9}},"queue":[{"id":"melt-sand","key":"queue:72","elapsed":2}]})
	check(production.state.escrow.is_empty() and production.state.queue.is_empty(),"Only exact previously paid recipes migrate")
	production.state.bottling = true
	mats.set_amount("empty-bottle",2)
	check(production.divert_honey(1)==0 and mats.amount("bottled-honey")==1,"One honey hand fills one bottle")
	production.restore(production.for_save())
	check(production.divert_honey(1)==0 and mats.amount("bottled-honey")==2 and mats.amount("empty-bottle")==0,"Bottling preference survives reload and consumes exactly one empty bottle per hand")
	check(production.divert_honey(1)==1,"Missing bottle leaves normal honey available")
	check(production.open_honey() and mats.amount("empty-bottle")==1 and production.activated_seconds()==10,"Opening returns a bottle and banks ten seconds")
	production.restore(production.for_save())
	check(production.activated_seconds()==10,"Banked effect survives reload")
	check(production.spend_honey() and production.activated_seconds()==0,"Activated honey feeds one existing dose")
	check(production.spend_offline_units(7)==7 and production.activated_seconds()==0,"Disabled bottles remain stored during offline debit")
	production.state.wheel_clearance = 8
	mats.set_amount("softwood",22)
	mats.set_amount("wooden-parts",4)
	mats.set_amount("glass",4)
	var wheel: Dictionary = game._action_data("build","repair-waterwheel")
	for i in 8:
		check(production.cycle_ready(wheel),"Waterwheel retains its reserved construction inputs")
		production.complete(wheel)
	check(production.state.wheel_built and mats.amount("glass")==0 and mats.amount("softwood")==0 and mats.amount("wooden-parts")==0,"Eight real work cycles finish one waterwheel with shared parts")
	game._activity_unlock_runtime()._mark_action_manually_unlocked("build","shape-bottles")
	mats.set_amount("glass",2)
	check(production.enqueue("shape-bottles") and production.enqueue("shape-bottles") and not production.enqueue("shape-bottles"),"Finite queue reserves exactly the available inputs")
	production.advance_queue(1)
	production.restore(production.for_save())
	production.advance_queue(1000)
	check(production.state.queue.is_empty() and mats.amount("empty-bottle")==3,"Queued work survives reload and completes once while away")
	production.advance_queue(1000)
	check(mats.amount("empty-bottle")==3,"An empty queue produces nothing")
	mats.set_amount("spyglass",1)
	mats.set_amount("bait",1)
	production.toggle_bait("river-bend")
	check(production.fishing_food_multiplier("river-bend")==0.5,"Targeted bait trades half the ordinary food")
	production.fishing_success("river-bend")
	check(mats.amount("pearl-scale")==1 and mats.amount("bait")==0 and production.fishing_food_multiplier("river-bend")==1,"Targeted catch consumes once and exhaustion restores ordinary food")
	mats.set_amount("precision-net",1)
	mats.set_amount("bait",1)
	production.state.selective_net=true
	game.fishing_runtime.equipped_tool_id="net"
	production.fishing_success("river-bend")
	check(mats.amount("pearl-scale")==3 and mats.amount("bait")==0,"Owned selective net doubles targeted material, consuming only one bait")
	var explore: Dictionary = game._action_data("thieving","explore-dark-passage")
	mats.set_amount("lantern",1)
	mats.set_amount("candle",1)
	for i in 3:
		check(production.cycle_ready(explore),"Lantern covers three exploration attempts")
		production.complete(explore)
	check(not production.cycle_ready(explore) and mats.amount("candle")==0,"Lantern charges stop without another candle")
	var payload: Dictionary = game._save_runtime()._save_payload(game._unix_now())
	check(payload.production == production.for_save(),"Production state uses the actual save serializer")
	production.reset()
	game._save_runtime()._load_game_core(payload)
	check(production.state.wheel_built and mats.amount("spyglass")==1,"Production facilities and items restore through the actual loader")
	var normalizers=preload("res://scripts/save_state/normalizers.gd")
	var older: Dictionary=payload.duplicate(true)
	older.mats["spyglass"]=0
	check(normalizers.payload_regresses_game_progress(payload,older,game.skill_defs),"Cloud protection refuses to lose permanent production equipment")
	mats.set_amount("spyglass",0)
	mats.set_amount("wooden-parts",0)
	mats.set_amount("softwood",4)
	mats.set_amount("lens",2)
	var assemble: Dictionary=game._action_data("build","assemble-spyglass")
	var carve_tube: Dictionary=game._action_data("build","carve-spyglass-tube")
	check(not production.cycle_ready(assemble) and mats.amount("softwood")==4,"A spyglass cannot be assembled from raw timber or a fence frame")
	check(production.cycle_ready(carve_tube),"Timber can be shaped into shared wooden parts")
	production.complete(carve_tube)
	check(mats.amount("wooden-parts")==2 and mats.amount("softwood")==0,"Four Softwood produce two shared parts")
	check(production.cycle_ready(assemble),"Two polished lenses and two shared parts can be assembled")
	production.complete(assemble)
	check(mats.amount("spyglass")==1 and mats.amount("lens")==0 and mats.amount("wooden-parts")==0,"Spyglass assembly consumes two lenses and two shared parts once")
	for recipe_id in ["assemble-spyglass","assemble-lantern","weave-selective-net"]:
		check(production.rules.recipes[recipe_id].inputs.has("wooden-parts"),"Shared parts supply "+recipe_id)
	check(production.rules.waterwheel.cost.has("wooden-parts"),"Shared parts supply the waterwheel")
	mats.restore_wallet({"mats":{"wooden-parts":3,"spyglass-tube":2,"spyglass":1}})
	check(mats.amount("wooden-parts")==7 and mats.amount("spyglass")==1,"Prototype tubes migrate into shared parts without losing existing parts or equipment")
	check(not mats.save_wallet().has("spyglass-tube"),"Retired tubes do not remain in saved inventory")
	var old_reservations := {"assemble-spyglass":{"lens":2,"spyglass-tube":1},"assemble-lantern":{"glass":3,"hardwood":2},"weave-selective-net":{"pearl-scale":12,"softwood":6},"waterwheel":{"softwood":30,"glass":4}}
	production.restore({"escrow":old_reservations})
	for key in old_reservations:
		check(production.state.escrow.has(key) and production.state.escrow[key].has("wooden-parts"),"Previously paid construction migrates without a second charge: "+key)
	mats.set_amount("softwood",4)
	production.restore({"escrow":{"queue:23":{"softwood":4}},"queue":[{"id":"carve-spyglass-tube","key":"queue:23","elapsed":0}]})
	var parts_before: float=mats.amount("wooden-parts")
	production.state.wheel_built=true
	production.advance_queue(1000)
	check(mats.amount("wooden-parts")==parts_before+2 and mats.amount("softwood")==4,"Prototype queued shaping retains its stable action ID and does not charge again")
	production.restore({"partial_honey":99,"activated_units":-10,"queue":[{"id":"shape-bottles","key":"queue:1","elapsed":0}],"escrow":{}})
	check(int(production.state.partial_honey)==0 and production.activated_seconds()==0 and production.state.queue.is_empty(),"Legacy partial honey is recovered and malformed data cannot create unpaid jobs")
	production.restore({})
	check(not production.state.wheel_built and production.state.queue.is_empty(),"Old saves with no production section initialize normally")
	production.reset()
	production.state.wheel_built=true
	game.built_modules["build:melt-sand"]=true
	for item in ["sand","scrapwood","glass","empty-bottle"]: mats.set_amount(item,0)
	mats.set_amount("sand",2)
	mats.set_amount("scrapwood",1)
	game._activity_unlock_runtime()._mark_action_manually_unlocked("build","melt-sand")
	check(production.enqueue("melt-sand"),"Built kiln accepts a reserved background job")
	var bottle: Dictionary=game._action_data("build","shape-bottles")
	var simulation: Dictionary=game._action_runtime()._play_offline_active_action("build","shape-bottles",bottle,30,false)
	check(int(simulation.completions)==1 and mats.amount("empty-bottle")==1 and mats.amount("glass")==0,"Offline processing waits for queued glass before making exactly one bottle")
	var xp_before: int=game.skills.build.xp
	game._action_runtime()._play_offline_active_action("build","shape-bottles",bottle,30,false)
	check(game.skills.build.xp==xp_before and mats.amount("empty-bottle")==1,"Exhausted recipes cannot earn offline XP or duplicate outputs")
	production.reset()
	production.state.wheel_built=true
	mats.set_amount("sand",2)
	mats.set_amount("scrapwood",1)
	game.built_modules.erase("build:melt-sand")
	check(not production.enqueue("melt-sand") and mats.amount("sand")==2,"Queue cannot bypass construction of the kiln")
	var order_report := {}
	for skill in game.actions_by_skill:
		for action in game.actions_by_skill[skill]: game._activity_unlock_runtime()._mark_action_manually_unlocked(str(skill),str(action.id))
		var run_length := 0
		var longest := 0
		for entry in game._skill_detail_surface()._visible_action_entries_for_skill(str(skill)):
			var action: Dictionary=entry.action
			if not action.get("presentation",{}).is_empty():
				check(not action.get("production",{}).is_empty() or bool(action.get("production_tier_perks_exempt",false)),"Special presentation serves a gameplay system: "+str(action.id))
			var special: bool = not action.get("presentation",{}).is_empty() or not action.get("combat",{}).is_empty() or not action.get("recovery",{}).is_empty() or str(skill)=="fishing" or game._passive_modules_runtime().is_passive_action(action)
			run_length=0 if special else run_length+1
			longest=maxi(longest,run_length)
		order_report[skill]=longest
	print("PRODUCTION_LIST_ORDER ",JSON.stringify(order_report))
	print("PRODUCTION_PATHS failures=",JSON.stringify(failures))
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
