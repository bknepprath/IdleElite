extends SceneTree

var failures: Array[String]=[]
var receipts: Array=[]
func _init() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	if not ok: failures.append(message);push_error(message)
func run() -> void:
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES","1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS","1")
	AudioServer.set_bus_mute(0,true)
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.activity_data_catalog.load_action_data(game)
	game._save_runtime()._init_state()
	var mats=game.material_runtime
	mats.item_collected.connect(func(key,id,amount,bursts): receipts.append({"key":key,"id":id,"amount":amount,"bursts":bursts}))
	var halloween=game._halloween_runtime()
	halloween.enabled=true
	halloween.ends_at_unix=0
	var holders:=0
	for skill in game.actions_by_skill:
		for action in game.actions_by_skill[skill]:
			if not game._material_collection_surface().has_item_boxes(skill,action): continue
			holders+=1
			var fixture: Dictionary=action.duplicate(true)
			var rewards: Array=game._action_runtime()._action_mat_reward_defs(action)
			for reward in rewards:
				reward.min=2;reward.max=2;reward.chance=1;reward.zero_chance=0
			fixture.mat_rewards=rewards
			receipts.clear()
			var awarded: Array=game._action_runtime()._award_action_mat_rewards(fixture,1.0,skill)
			check(receipts.size()==rewards.size(),"Every ordinary material credit emits one receipt: "+str(action.id))
			for index in receipts.size():
				check(receipts[index].key==game._action_key(skill,str(action.id)) and receipts[index].amount==awarded[index].amount,"Receipt matches the actual action and credited quantity")
			receipts.clear()
			game._action_runtime()._award_action_mat_rewards(fixture,1.0,skill,false)
			check(receipts.is_empty(),"Offline material rewards never replay collection animation")
	receipts.clear()
	var before: int=halloween.candy
	halloween.record_success("thieving","trick-or-treat")
	check(halloween.candy==before+1 and receipts.size()==1 and receipts[0].id=="candy","Candy-only success uses the same receipt without ordinary materials")
	receipts.clear()
	halloween.candy=halloween.MAX_CANDY
	halloween.record_success("thieving","trick-or-treat")
	check(receipts.is_empty(),"Capped candy emits no fake collection")
	halloween.candy=0
	halloween.record_success("thieving","trick-or-treat",false)
	check(halloween.candy==1 and receipts.is_empty(),"Offline candy still awards without replaying visuals")
	halloween.enabled=false
	halloween.record_success("thieving","trick-or-treat")
	check(halloween.candy==1 and receipts.is_empty(),"Ended event awards and animates nothing")
	mats.collect_amount("sand",0,"build:gather-sand")
	mats.collect_amount("sand",-1,"build:gather-sand")
	mats.collect_amount("invalid",3,"build:gather-sand")
	check(receipts.is_empty(),"Zero, failed and invalid grants emit no collection")
	mats.add_amount("sand",2)
	mats.set_amount("sand",12)
	mats.spend_amount("sand",1)
	check(receipts.is_empty(),"Balance restores, refunds and spending do not masquerade as collection")
	mats.material_defs["audit-ore"]={"name":"Ore","icon":mats.icon_path("sand"),"background":mats.background_path("sand"),"color":Color.WHITE}
	var future: Dictionary=game._action_data("build","gather-sand").duplicate(true)
	future.mat_rewards=[{"id":"audit-ore","amount":2}]
	check(game._material_collection_surface().has_item_boxes("build",future),"A new data-defined collectible gets a holder without an activity exception")
	receipts.clear()
	game._action_runtime()._award_action_mat_rewards(future,1.0,"build")
	check(receipts.size()==1 and receipts[0].id=="audit-ore","A new collectible automatically uses the shared reward notification")
	var collection=game._material_collection_surface()
	collection.collection_receipts.clear()
	halloween.enabled=true
	halloween.candy=0
	mats.collect_amount("sand",2,"thieving:trick-or-treat",2)
	halloween.record_success("thieving","trick-or-treat")
	var mixed: Array=collection.collection_receipts["thieving:trick-or-treat"]
	check(mixed.size()==2 and mixed[0].harvest_count==2 and mixed[1].harvest_count==1,"Mixed rewards retain per-item burst counts without duplicating candy")
	print("COLLECTION_REWARDS holders=",holders," failures=",JSON.stringify(failures))
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
