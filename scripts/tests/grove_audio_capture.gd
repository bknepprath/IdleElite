extends "res://scripts/tests/action_art_oct22.gd"

func audit_action_art() -> void:
	var audio = game._audio_director()
	audio.music_muted = true
	audio.sfx_muted = false
	audio.sfx_volume = .65
	audio._apply_audio_bus_volumes()
	var runtime = game._grove_runtime()
	runtime.reset()
	runtime.upgrades.grip = 2
	await open_notes_skill("woodcutting")
	var card := await notes_card("grove-birch")
	if card.is_empty(): quit(1); return
	await align_notes_card(card)
	var stage: Control = card.grove_stage
	var state: Dictionary = runtime.state("grove-birch")
	state.trees[0].x = 450.0
	state.trees[0].y = .86
	state.trees[0].hp = 2
	state.trees[0].bountiful = true
	state.trees[1].phase = "stump"
	state.target = 0
	game.stamina.woodcutting = 100
	await settle(.6)
	var record := AudioEffectRecord.new()
	var sfx_bus := AudioServer.get_bus_index("SFX")
	var effect_index := AudioServer.get_bus_effect_count(sfx_bus)
	AudioServer.add_bus_effect(sfx_bus, record)
	record.set_recording_active(true)
	var before_hits: int = audio.grove_hit_index
	var before_felled: int = runtime.felled
	var hits: Array = []
	await capture("before-chopping")
	await click(stage.get_global_transform_with_canvas() * stage.world_point(450,.91), true)
	for frame in 1600:
		await process_frame
		if int(audio.grove_hit_index) > before_hits + hits.size():
			var player: AudioStreamPlayer = audio.grove_hit_player
			hits.append({"time_ms":Time.get_ticks_msec(),"phase":state.phase,"contact":state.contact,"hp":state.trees[0].hp,"volume_db":player.volume_db,"pitch":player.pitch_scale,"path":player.stream.resource_path})
			check(bool(state.contact), "Wood thud occurs on actual axe contact")
			check(player.volume_db < audio.DEFAULT_BUTTON_SFX_VOLUME_DB, "Wood thud stays below normal UI volume")
			if hits.size() == 1: await capture("axe-contact")
		if runtime.felled > before_felled: break
	check(runtime.felled == before_felled + 1, "Actual tree chopping awards one harvest")
	check(hits.size() == 2, "Two successful impacts produce exactly two wooden thuds")
	if hits.size() == 2: check(hits[0].path != hits[1].path, "Wood impact variants alternate")
	check(is_instance_valid(audio.grove_collect_player) and audio.grove_collect_player.playing, "Collection cue starts when logs are awarded")
	check(int(runtime.harvest_bursts.back().amount) >= 3, "Bountiful multi-log reward uses one collection player")
	check(audio.grove_collect_player.volume_db <= audio.GROVE_COLLECT_SFX_VOLUME_DB, "Collection sound remains quiet beside reward accents")
	await capture("logs-and-collection")
	game._action_runtime()._stop_running_action("woodcutting", "grove-birch")
	check(not runtime.harvest("grove-birch"), "Repeated harvest cannot replay rewards or collection cue")
	var stopped_hit_index: int = audio.grove_hit_index
	audio._play_grove_hit_sfx("grove-birch")
	check(audio.grove_hit_index == stopped_hit_index, "Inactive groves do not produce impact sounds")
	await settle(.6)
	record.set_recording_active(false)
	var recording := record.get_recording()
	check(recording != null and not recording.data.is_empty(), "Actual in-game SFX mix is captured")
	if recording != null:
		recording.save_to_wav(capture_dir + "/grove-sfx-mix.wav")
	AudioServer.remove_bus_effect(sfx_bus, effect_index)
	await capture("settled")
	print("GROVE_AUDIO failures=", JSON.stringify(failures))
	var result := FileAccess.open(capture_dir + "/result.json", FileAccess.WRITE)
	result.store_string(JSON.stringify({"failures":failures,"hits":hits}))
	result.close()
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	quit(0 if failures.is_empty() else 1)
