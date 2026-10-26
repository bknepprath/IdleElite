extends "res://scripts/tests/action_art_oct22.gd"

func audit_action_art() -> void:
	game.material_runtime.set_amount("sand",100)
	game.material_runtime.set_amount("glass",15)
	game.built_modules["build:melt-sand"]=true
	await open_notes_skill("build")
	var factory:=await notes_card("melt-sand")
	await align_notes_card(factory)
	await click(factory.production_stage.output_hit.get_global_rect().get_center(),true)
	if is_instance_valid(factory.production_stage.output_menu) and factory.production_stage.output_menu.visible: await click(factory.production_stage.menu_choice.get_global_rect().get_center(),true)
	await align_notes_card(factory)
	check(game.running_action_id=="melt-sand","Real production and the Glass inventory are visible")
	await capture("glass-production-inventory")
	game._action_runtime()._stop_running_action("build","melt-sand")
	await settle(.5)
	var bottles:=await notes_card("shape-bottles")
	await align_notes_card(bottles)
	await capture("glass-recipe-input")
	print("GLASS_ICON_CAPTURE failures=",JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	quit(0 if failures.is_empty() else 1)
