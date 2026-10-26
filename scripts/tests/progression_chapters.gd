extends "res://scripts/dev/progression_playtest.gd"

func start() -> void:
	create_timer(140).timeout.connect(func(): quit(1))
	await super.start()
	var failures: Array[String] = []
	for entry in [[KEY_F3, 25], [KEY_F4, 70], [KEY_F1, 1], [KEY_F2, 6]]:
		var press := InputEventKey.new()
		press.keycode = int(entry[0])
		press.pressed = true
		root.push_input(press, true)
		for frame in range(2000):
			await create_timer(0.02).timeout
			if not changing: break
		await create_timer(1.2).timeout
		if changing or int(game.skills.build.level) != int(entry[1]): failures.append("Chapter " + str(entry))
		if root.get_child_count() != 2: failures.append("Chapter left stale game nodes")
	print("PROGRESSION_CHAPTERS failures=", JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
