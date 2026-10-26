extends SceneTree

var failures: Array = []
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error(message)

func _init() -> void: call_deferred("run")

func run() -> void:
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.activity_data_catalog.load_action_data(game)
	game._save_runtime()._init_state()
	var p = game._production_runtime()
	var m = game.material_runtime
	for id in ["empty-bottle","bottled-honey","honey"]: m.set_amount(id,0)
	p.reset()
	check(not p.bottles_available() and p.honey_output_id()=="honey", "New players see only ordinary honey")
	m.set_amount("empty-bottle",2)
	check(p.bottles_available(), "Acquiring bottles reveals bottling")
	check(p.divert_honey(1)==1 and m.amount("empty-bottle")==2, "Bottling off preserves bottles")
	p.state.bottling=true
	check(p.honey_output_id()=="bottled-honey", "Enabled available bottles select bottled output")
	check(p.divert_honey(3)==1 and m.amount("bottled-honey")==2 and m.amount("empty-bottle")==0, "Limited bottles produce two sealed honey and one raw hand")
	check(p.honey_output_id()=="honey", "Empty supply selects raw hand immediately")
	check(p.bottles_available(), "Controls remain after supply runs out")
	game.running_skill_id="build"
	game.running_action_id="stack-bricks"
	check(not p.honey_available(), "Stored bottles do not activate with Use off")
	p.state.use_bottled_honey=true
	check(p.honey_available() and p.spend_honey(), "Use on consumes a bottle for another skill")
	check(m.amount("bottled-honey")==1 and m.amount("empty-bottle")==1 and p.activated_seconds()==0, "One bottle pays one ten-second dose and returns one empty")
	game.running_action_id=""
	check(not p.honey_available(), "Use toggle does not eat bottles with no task")
	var saved: Dictionary=p.for_save()
	p.restore(saved)
	check(p.state.bottling and p.state.use_bottled_honey and p.state.bottles_seen, "Both preferences and discovery survive reload")
	game.running_action_id="stack-bricks"
	check(p.spend_offline_units(1)==0 and m.amount("bottled-honey")==0, "Enabled bottles cover offline work once")
	m.set_amount("bottled-honey",2)
	m.set_amount("empty-bottle",0)
	m.set_amount("honey",0)
	p.restore({"version":1,"partial_honey":4,"activated_units":3})
	check(m.amount("honey")==4 and m.amount("empty-bottle")==1 and p.state.partial_honey==0, "Old partial jar returns its paid bottle and stored hands")
	check(p.activated_seconds()==30 and p.state.legacy_honey_bottles==2, "Legacy active and sealed effects retain their value")
	p.restore(p.for_save())
	check(m.amount("honey")==4 and m.amount("empty-bottle")==1, "Migration cannot duplicate refunded ingredients")
	check(p.open_honey() and p.activated_seconds()==90 and p.state.legacy_honey_bottles==1, "A legacy bottle still adds sixty seconds")
	print("HONEY_BOTTLING failures=",JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	quit(0 if failures.is_empty() else 1)
