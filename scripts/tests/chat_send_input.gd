extends "res://scripts/tests/first_session_input.gd"

class CapturedOnline extends "res://scripts/online/online_runtime.gd":
	var submissions: Array[String] = []
	var simulate_lookup_failure := false
	var profile_fetches := 0
	func _leaderboard_firebase_enabled() -> bool:
		return simulate_lookup_failure
	func _leaderboard_write_ready() -> bool:
		return true
	func _leaderboard_ensure_auth() -> bool:
		return false
	func _chat_stream_connect(_force := false) -> void:
		pass
	func _start_chat_stream_poll_timer() -> void:
		pass
	func _fetch_profile_recovery_record() -> void:
		profile_fetches += 1
		profile_recovery_fetch_in_flight = true
	func send_chat(text: String) -> void:
		if simulate_lookup_failure:
			super.send_chat(text)
			return
		submissions.append(text)
		app._profile_chat_overlay_surface().clear_chat_draft_message()

func _run() -> void:
	create_timer(170).timeout.connect(func(): quit(1))
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "120")
	capture_dir = "res://.codex-tmp/chat-send-input"
	DirAccess.make_dir_recursive_absolute(capture_dir)
	root.size = Vector2i(1080, 1920)
	game = load("res://scenes/main.tscn").instantiate()
	var online := CapturedOnline.new()
	game.online_runtime = online
	game.add_child(online)
	online.setup(game)
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	for i in range(1600):
		await settle(0.02)
		if game.startup_initialized and not game._boot_warmup_runtime().active:
			break
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	await settle(1.0)
	var chat = game._profile_chat_overlay_surface()
	await click(chat.chat_strip.get_global_rect().get_center())
	check(chat.chat_overlay_visible(), "Chat opens through the real strip")
	await settle(0.4)
	var edit: LineEdit = chat.chat_message_edit
	edit.editable = true # Network is disabled; only capture UI submissions locally.
	var send: Button = edit.get_parent().get_child(edit.get_index() + 1)
	for mode in ["mouse", "touch", "enter"]:
		edit.text = "Chat input test " + mode
		chat.chat_draft_message = edit.text
		edit.grab_focus()
		await settle(0.2)
		if mode == "enter":
			for pressed in [true, false]:
				var key := InputEventKey.new()
				key.keycode = KEY_ENTER
				key.pressed = pressed
				root.push_input(key, true)
				await settle(0.1)
		else:
			await click(send.get_global_rect().get_center(), mode == "touch")
		await settle(0.4)
		print("CHAT_INPUT ", mode, " submissions=", online.submissions)
		check(online.submissions == ["Chat input test " + mode], mode + ": one submission reaches online runtime")
		online.submissions.clear()
	# First-time players can open chat before completing the tutorial.
	game._onboarding_runtime().tutorial_active = true
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	edit.release_focus()
	await click(edit.get_global_rect().get_center())
	check(edit.has_focus(), "Tutorial lets chat composer receive focus")
	for pressed in [true, false]:
		var key := InputEventKey.new()
		key.keycode = KEY_A
		key.unicode = 97
		key.pressed = pressed
		root.push_input(key, true)
		await settle(0.1)
	check(edit.text == "a", "Typing works while tutorial remains active")
	await click(send.get_global_rect().get_center())
	check(online.submissions == ["a"], "Tutorial allows chat Send")
	online.submissions.clear()
	var back: Button = edit.get_parent().get_child(edit.get_index() - 1)
	await click(back.get_global_rect().get_center())
	check(not chat.chat_overlay_visible(), "Tutorial allows chat Back")
	game._onboarding_runtime().tutorial_active = false
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	await click(chat.chat_strip.get_global_rect().get_center())
	await settle(0.4)
	edit = chat.chat_message_edit
	edit.editable = true
	send = edit.get_parent().get_child(edit.get_index() + 1)
	online.simulate_lookup_failure = true
	online.profile_recovery_lookup_gate = true
	for i in range(25):
		online._chat_upsert_row("fixture-message-%s" % i, {"sender_id": "fixture-player", "name": "Player", "text": "Chat history %s" % (i + 1), "created_at": 100000 + i, "avatar_index": 0})
	edit.text = "Hello"
	chat.chat_draft_message = edit.text
	await click(send.get_global_rect().get_center())
	check(online.profile_fetches == 1, "Send retries the username lookup through production code")
	online._on_profile_recovery_fetch_completed(HTTPRequest.RESULT_TIMEOUT, 0, PackedStringArray(), PackedByteArray())
	online.chat_status_message = "Global chat is live."
	chat._render_chat_if_visible()
	await settle(0.8)
	check(edit.text == "Hello", "A failed send preserves the draft")
	check(chat._chat_status_detail().contains("Press Send to retry"), "Send error survives a live stream update")
	check(chat.chat_overlay_notice.get_global_rect().end.y <= edit.get_global_rect().position.y, "Error stays visible above composer with full history")
	check(chat.chat_overlay_notice.get_global_rect().position.y > 132.0, "Error is inside the visible chat area")
	await capture("send-error")
	await click(send.get_global_rect().get_center())
	check(online.profile_fetches == 2, "Second click starts the lookup again")
	print("chat-send-input failures=", failures)
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
