extends RefCounted


static func dispose(players) -> void:
	for raw_player in players:
		var player := raw_player as AudioStreamPlayer
		if player != null and is_instance_valid(player):
			player.stop()
			player.queue_free()
	players.clear()


static func append_path_players(players, paths: Array, make_player: Callable, volume_db: float) -> void:
	for raw_path in paths:
		var player := make_player.call(str(raw_path)) as AudioStreamPlayer
		if player == null:
			continue
		player.volume_db = volume_db
		players.append(player)


static func append_repeated_path_players(players, path: String, count: int, make_player: Callable, base_volume_db: float, volume_step_db := 0.0) -> void:
	for i in range(count):
		var player := make_player.call(path) as AudioStreamPlayer
		if player == null:
			continue
		player.volume_db = base_volume_db + float(i) * volume_step_db
		players.append(player)
