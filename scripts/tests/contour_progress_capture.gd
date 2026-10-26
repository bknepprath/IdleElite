extends "res://scripts/tests/action_art_oct22.gd"

func audit_action_art() -> void:
	game.material_runtime.set_amount("sand",1000)
	game.material_runtime.set_amount("scrapwood",1000)
	game.built_modules["build:melt-sand"] = true
	await open_notes_skill("build")
	var factory := await notes_card("melt-sand")
	await align_notes_card(factory)
	await capture("production-before")
	await click(factory.production_stage.output_hit.get_global_rect().get_center(),true)
	await settle(.3)
	if is_instance_valid(factory.production_stage.output_menu) and factory.production_stage.output_menu.visible: await click(factory.production_stage.menu_choice.get_global_rect().get_center(),true)
	await settle(.35)
	for target in [.44,.48,.50,.52,.56,.98]:
		await capture_progress(factory,"production",target)
	game._action_runtime()._stop_running_action("build","melt-sand")
	await settle(.5)
	await open_notes_skill("woodcutting")
	var rest := await notes_card("lean-on-the-axe")
	await align_notes_card(rest)
	await capture("rest-before")
	await click(rest.art_panel.get_global_rect().get_center(),true)
	check(game.running_action_id=="lean-on-the-axe","Actual rest activity starts by tapping its art")
	for target in [.36,.43,.50,.57,.64,.98]:
		await capture_progress(rest,"rest",target)
	game._action_runtime()._stop_running_action("woodcutting","lean-on-the-axe")
	print("CONTOUR_CAPTURE failures=",JSON.stringify(failures))
	var report := FileAccess.open(capture_dir+"/result.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"failures":failures}))
	report.close()
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	quit(0 if failures.is_empty() else 1)

func capture_progress(card: Dictionary, label: String, target: float) -> void:
	var rail: Control = card.progress
	for frame in range(5000):
		await process_frame
		if rail.value/100.0 >= target: break
	check(rail.value/100.0 >= target,label+" reaches "+str(target))
	await capture(label+"-"+str(int(target*100)))
