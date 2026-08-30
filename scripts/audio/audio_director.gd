extends Node

const DEFAULT_BUTTON_SFX_DEBOUNCE_MSEC := 180
const DEFAULT_BUTTON_SFX_PATH := "res://assets/sfx/Sample_0029 bowling ui snap.wav"
const ACTIVITY_STREAK_BONUS_STEP := 5
const ACTIVITY_MEGA_CRIT_SFX_PITCH_START := 1.16
const ACTIVITY_MEGA_CRIT_SFX_PITCH_STEP := 0.08
const ACTIVITY_MEGA_CRIT_SFX_PITCH_MAX := 1.88
const ACTIVITY_CRIT_SFX_VOLUME_DB := -10.0
const INFO_CHIP_UPGRADE_SFX_PLAYER_COUNT := 5
const INFO_CHIP_UPGRADE_SFX_VOLUME_DB := -18.0
const INFO_CHIP_UPGRADE_SFX_PITCH_START := 1.18
const INFO_CHIP_UPGRADE_SFX_PITCH_STEP := 0.026
const INFO_CHIP_UPGRADE_SFX_PITCH_MAX := 1.32
const ACTIVITY_SUCCESS_SFX_PATHS := [
	"res://assets/sfx/action_success_glass_pip_1.wav",
	"res://assets/sfx/action_success_glass_pip_2.wav",
	"res://assets/sfx/action_success_glass_pip_3.wav",
	"res://assets/sfx/action_success_glass_pip_4.wav",
]
const ACTIVITY_CRIT_SFX_PATHS := [
	"res://assets/sfx/action_crit_blue_glass_fanfare_1.wav",
	"res://assets/sfx/action_crit_blue_glass_fanfare_2.wav",
	"res://assets/sfx/action_crit_blue_glass_fanfare_3.wav",
	"res://assets/sfx/action_crit_blue_glass_fanfare_4.wav",
	"res://assets/sfx/action_crit_blue_glass_fanfare_5.wav",
]
const CHAIN_MOVE_SFX_PATHS := [
	"res://assets/sfx/chain_move_soft_links.wav",
	"res://assets/sfx/chain_move_low_rattle.wav",
	"res://assets/sfx/chain_move_bright_safe.wav",
	"res://assets/sfx/chain_move_distant_chain.wav",
	"res://assets/sfx/chain_move_tight_ui.wav",
]
const CHAIN_MOVE_PLAYER_COPIES := 3
const CHAIN_DRAG_EXTRA_HIT_CHANCE := 0.32
const CHAIN_DRAG_JINGLE_CHANCE := 0.12
const CHAIN_CLICK_EXTRA_HIT_CHANCE := 0.72
const CHAIN_JINGLE_SFX_PATH := "res://assets/sfx/Jingle Chains.wav"
const CHAIN_JINGLE_MIX_LAYER_COUNT := 2
const CHAIN_JINGLE_TOTAL_SECONDS := 1.5
const CHAIN_JINGLE_FADE_SECONDS := 0.34
const CHAIN_CLICK_JINGLE_TOTAL_SECONDS := 0.48
const CHAIN_CLICK_JINGLE_FADE_SECONDS := 0.24
const CHAIN_OFFSCREEN_GAIN := 0.25
const CHAIN_SCROLL_TOWARD_GAIN := 0.74
const CHAIN_SCROLL_TOWARD_SECONDS := 0.62
const CHAIN_SCROLL_AUDITION_DISTANCE := 1.35
const PADLOCK_CLUSTER_SFX_PATH := "res://assets/sfx/padlock_cluster.wav"
const FISHING_FAILURE_SFX_PATH := "res://assets/sfx/water_whoosh_subtle.wav"
const FISHING_FAILURE_SFX_VOLUME_DB := -16.0
const CHICKEN_DEATH_SFX_PATH := "res://assets/sfx/fight_chicken_death_squeak.wav"
const CHICKEN_DEATH_SFX_VOLUME_DB := -18.0
const GOBLIN_SHIELD_DROP_SFX_PATH := "res://assets/sfx/fight_goblin_shield_drop.wav"
const GOBLIN_SHIELD_DROP_SFX_VOLUME_DB := -20.0
const FIGHT_PUNCH_SFX_PATHS := [
	"res://assets/sfx/fight_punch_soft_body_whump.wav",
	"res://assets/sfx/fight_punch_soft_body_thump_alt.wav",
	"res://assets/sfx/fight_punch_crisp_glove_pop.wav",
	"res://assets/sfx/fight_punch_feed_sack_crunch.wav",
	"res://assets/sfx/fight_punch_short_uppercut_pop.wav",
	"res://assets/sfx/fight_punch_rubber_bounce_hit.wav",
]
const FIGHT_PUNCH_SFX_VOLUME_DB := -17.0
const FIGHT_PUNCH_SFX_PITCH_MIN := 0.94
const FIGHT_PUNCH_SFX_PITCH_MAX := 1.08
const FIGHT_PUNCH_SFX_VOLUME_VARIANCE_DB := 1.8
const ACTION_OPPORTUNITY_SUCCESS_SFX_VOLUME_DB := -18.0
const ACTION_OPPORTUNITY_MISS_SFX_VOLUME_DB := -15.0
const MODULE_PIN_ENTRY_SFX_PATH := "res://assets/sfx/pin-candidates/pin_exit_pull_04_bright_tick.wav"
const MODULE_PIN_EXIT_SFX_PATH := "res://assets/sfx/pin-candidates/pin_entry_thwick_01_tight.wav"
const ACTIVITY_START_SFX_VOLUME_DB := -1.0
const ACTIVITY_SUCCESS_SFX_VOLUME_DB := -7.0
const ACTIVITY_SUCCESS_DUCKED_SFX_VOLUME_DB := -15.0
const DEFAULT_BUTTON_SFX_VOLUME_DB := -4.0
const MODULE_PIN_ENTRY_SFX_VOLUME_DB := -5.0
const MODULE_PIN_EXIT_SFX_VOLUME_DB := -7.0
const LEVEL_UP_SFX_VOLUME_DB := -9.0
const MEDAL_REWARD_SFX_VOLUME_DB := -16.0
const BONUS_JINGLE_SFX_VOLUME_DB := -17.0
const BONUS_JINGLE_ECHO_SFX_VOLUME_DB := -21.0
const REWARD_SFX_KEY_GAP_MSEC := 120
const REWARD_SFX_EXCLUSIVE_MSEC := 460
const REWARD_SFX_BONUS_EXCLUSIVE_MSEC := 300
const REWARD_SFX_PRIORITY_BONUS := 1
const REWARD_SFX_PRIORITY_MEDAL := 2
const REWARD_SFX_PRIORITY_CRIT := 3
const REWARD_SFX_PRIORITY_LEVEL := 4
const MUSIC_BUS_NAME := "Music"
const SFX_BUS_NAME := "SFX"
const MUSIC_SONG_SETS := [
	{"name": "original", "weight": 0.70, "tracks": [{"name": "base", "path": "res://assets/music/base_loop.ogg"}, {"name": "heavy", "path": "res://assets/music/heavy_loop.ogg"}, {"name": "ultimate", "path": "res://assets/music/ultimate_loop.ogg"}]},
	{"name": "guitar", "weight": 0.15, "tracks": [{"name": "base", "path": "res://assets/music/guitar_base_loop.ogg"}, {"name": "heavy", "path": "res://assets/music/guitar_heavy_loop.ogg"}]},
	{"name": "piano", "weight": 0.15, "tracks": [{"name": "base", "path": "res://assets/music/piano_base_loop.ogg"}, {"name": "heavy", "path": "res://assets/music/piano_heavy_loop.ogg"}, {"name": "ultimate", "path": "res://assets/music/piano_ultimate_loop.ogg"}]},
]
const MUSIC_SILENCE_DB := -80.0
const MUSIC_BASE_ACTION_THRESHOLD := 8
const MUSIC_LAUNCH_START_CHANCE := 0.25
const MUSIC_COMPLETION_START_CHANCE := 0.10
const MUSIC_QUIET_BREAK_CHANCE := 0.01
const MUSIC_QUIET_BREAK_STAMINA_CEILING := 5
const MUSIC_QUIET_BREAK_FADE_SECONDS := 8.0
const MUSIC_QUIET_BREAK_LOCKOUT_SECONDS := 30.0
const MUSIC_FLOW_IDLE_FADE_SECONDS := 26.0
const MUSIC_FLOW_DEAD_SECONDS := 54.0
const MUSIC_BASE_FADE_SECONDS := 1.6
const MUSIC_LAYER_FADE_SECONDS := 4.5
const MUSIC_ULTIMATE_FADE_SECONDS := 2.8
const MUSIC_START_FADE_SECONDS := 14.4
const MUSIC_BASE_ONLY_GUARD_SECONDS := 64.0
const MUSIC_LAYER_VOLUME_BOOST_DB := [1.5, -3.5, 2.2]
const MUSIC_OUTPUT_GAIN := 0.32
const MUSIC_ENABLED := true
const GAME_AUDIO_ENABLED := true
const DEFAULT_MUSIC_VOLUME := 0.55
const DEFAULT_SFX_VOLUME := 0.65
const AUDIO_SETTINGS_VERSION := 4
const ACTIVITY_UNLOCK_CHAIN_FALL_SECONDS := 1.15
const ACTIVITY_BONUS_JINGLE_DELAY := 0.08

var host: Node
var music_volume := DEFAULT_MUSIC_VOLUME
var sfx_volume := DEFAULT_SFX_VOLUME
var music_muted := false
var sfx_muted := false
var flow_actions_taken := 0
var flow_heat := 0.0
var flow_idle_seconds := MUSIC_FLOW_DEAD_SECONDS
var flow_active_action_seconds := 0.0
var flow_failure_drag := 0.0
var music_ultimate_boost_seconds := 0.0
var music_players: Array[AudioStreamPlayer] = []
var music_layer_gains := [0.0, 0.0, 0.0]
var music_layer_target_gains := [0.0, 0.0, 0.0]
var active_music_song_set := {}
var music_started := false
var music_cycle_active := false
var music_start_chance_unlocked := false
var music_lockout_seconds := 0.0
var music_start_fade_remaining := 0.0
var music_quiet_fade_remaining := 0.0
var music_quiet_fade_start_gains := [0.0, 0.0, 0.0]
var music_base_only_seconds := 0.0
var last_default_button_sfx_msec := -100000
var click_player: AudioStreamPlayer
var success_players: Array[AudioStreamPlayer] = []
var crit_success_players: Array[AudioStreamPlayer] = []
var failure_player: AudioStreamPlayer
var fishing_failure_player: AudioStreamPlayer
var chicken_death_player: AudioStreamPlayer
var goblin_shield_drop_player: AudioStreamPlayer
var fight_punch_players: Array[AudioStreamPlayer] = []
var fight_punch_player_index := 0
var opportunity_success_player: AudioStreamPlayer
var opportunity_miss_player: AudioStreamPlayer
var level_player: AudioStreamPlayer
var medal_player: AudioStreamPlayer
var bonus_jingle_player: AudioStreamPlayer
var bonus_jingle_echo_player: AudioStreamPlayer
var fish_eat_player: AudioStreamPlayer
var passive_log_land_players: Array[AudioStreamPlayer] = []
var chain_move_players: Array[AudioStreamPlayer] = []
var chain_jingle_players: Array[AudioStreamPlayer] = []
var padlock_cluster_player: AudioStreamPlayer
var info_chip_upgrade_players: Array[AudioStreamPlayer] = []
var module_pin_entry_player: AudioStreamPlayer
var module_pin_exit_player: AudioStreamPlayer
var audio_unlocked_by_input := false
var audio_unlock_ping_player: AudioStreamPlayer
var audio_unlock_ping_played := false
var reward_sfx_exclusive_until_msec := 0
var reward_sfx_exclusive_priority := 0
var reward_sfx_last_played_msec := {}
var passive_upgrade_player: AudioStreamPlayer
var audio_stream_cache := {}
var music_stream_cache := {}
var extended_audio_ready := false
var chain_move_audio_ready := false
var chain_audio_scroll_direction := 0
var chain_audio_scroll_focus_seconds := 0.0

func _focus_chain_scroll(direction: int) -> void:
	chain_audio_scroll_direction = 1 if direction > 0 else -1
	chain_audio_scroll_focus_seconds = CHAIN_SCROLL_TOWARD_SECONDS


func _process_chain_proximity_audio(delta: float) -> void:
	if chain_audio_scroll_focus_seconds <= 0.0:
		chain_audio_scroll_focus_seconds = 0.0
		chain_audio_scroll_direction = 0
		return
	chain_audio_scroll_focus_seconds = maxf(0.0, chain_audio_scroll_focus_seconds - delta)
	if chain_audio_scroll_focus_seconds <= 0.0:
		chain_audio_scroll_direction = 0


func setup(host_node: Node) -> void:
	host = host_node

func reset_runtime_caches() -> void:
	chain_move_audio_ready = false
	audio_stream_cache.clear()
	music_stream_cache.clear()
	extended_audio_ready = false


func _dispose_players(players) -> void:
	for raw_player in players:
		var player := raw_player as AudioStreamPlayer
		if player != null and is_instance_valid(player):
			player.stop()
			player.queue_free()
	players.clear()


func _append_path_players(players, paths: Array, make_player: Callable, volume_db: float) -> void:
	for raw_path in paths:
		var player := make_player.call(str(raw_path)) as AudioStreamPlayer
		if player == null:
			continue
		player.volume_db = volume_db
		players.append(player)


func _append_repeated_path_players(players, path: String, count: int, make_player: Callable, base_volume_db: float, volume_step_db := 0.0) -> void:
	for i in range(count):
		var player := make_player.call(path) as AudioStreamPlayer
		if player == null:
			continue
		player.volume_db = base_volume_db + float(i) * volume_step_db
		players.append(player)


func _ensure_path_player(player: AudioStreamPlayer, path: String, make_player: Callable, volume_db := 0.0) -> AudioStreamPlayer:
	if player != null and is_instance_valid(player):
		return player
	var next_player := make_player.call(path) as AudioStreamPlayer
	if next_player != null:
		next_player.volume_db = volume_db
	return next_player


func note_player_input(event: InputEvent) -> void:
	if audio_unlocked_by_input and audio_unlock_ping_played:
		return
	if event is InputEventMouseButton and event.pressed:
		_unlock_audio_for_gameplay()
	elif event is InputEventScreenTouch and event.pressed:
		_unlock_audio_for_gameplay()
	elif event is InputEventKey and event.pressed and not event.echo:
		_unlock_audio_for_gameplay()

static func saved_volume(data: Dictionary, key: String, fallback: float) -> float:
	if not data.has(key):
		return clampf(fallback, 0.0, 1.0)
	var raw_value: Variant = data.get(key, fallback)
	if typeof(raw_value) != TYPE_FLOAT and typeof(raw_value) != TYPE_INT:
		return clampf(fallback, 0.0, 1.0)
	return clampf(float(raw_value), 0.0, 1.0)


func apply_settings_from_save(data: Dictionary) -> void:
	music_volume = saved_volume(data, "music_volume", DEFAULT_MUSIC_VOLUME)
	sfx_volume = saved_volume(data, "sfx_volume", DEFAULT_SFX_VOLUME)

func restore_music_flow_state(data: Dictionary) -> void:
	flow_actions_taken = 0
	music_start_chance_unlocked = bool(data.get("music_start_chance_unlocked", false))
	flow_heat = clampf(float(data.get("flow_heat", flow_heat)), 0.0, 36.0)
	flow_active_action_seconds = maxf(0.0, float(data.get("flow_active_action_seconds", flow_active_action_seconds)))

func music_flow_save_state() -> Dictionary:
	return {
		"music_start_chance_unlocked": music_start_chance_unlocked,
		"flow_heat": clampf(flow_heat, 0.0, 36.0),
		"flow_active_action_seconds": maxf(0.0, flow_active_action_seconds),
	}

func audio_settings_save_state() -> Dictionary:
	return {
		"audio_settings_version": AUDIO_SETTINGS_VERSION,
		"music_volume": clampf(music_volume, 0.0, 1.0),
		"sfx_volume": clampf(sfx_volume, 0.0, 1.0),
		"music_muted": music_muted,
		"sfx_muted": sfx_muted,
	}

func _host_running_action_id() -> String:
	return str(host.get("running_action_id")) if host != null else ""

func _host_string(property_name: String) -> String:
	return str(host.get(property_name)) if host != null else ""

func _host_activity_streak_count() -> int:
	return int(host._action_runtime().activity_streak_count) if host != null else 0

func _host_dict(property_name: String) -> Dictionary:
	var value = host.get(property_name) if host != null else {}
	return value as Dictionary if value is Dictionary else {}

func _host_control(property_name: String) -> Control:
	var value = host.get(property_name) if host != null else null
	return value as Control

func _host_valid_control_ref(value: Variant) -> Control:
	return host.call("_valid_control_ref", value) as Control if host != null else null

func _kill_meta_tween(node: Node, meta_name: String) -> void:
	if node == null or not is_instance_valid(node) or not node.has_meta(meta_name):
		return
	var tween = node.get_meta(meta_name)
	if tween is Tween and (tween as Tween).is_valid():
		(tween as Tween).kill()
	node.remove_meta(meta_name)
func _prepare_audio_buses() -> void:
	_ensure_audio_buses()
	_apply_audio_bus_volumes()


func _ensure_click_player() -> void:
	if click_player != null and is_instance_valid(click_player):
		return
	_ensure_audio_buses()
	click_player = _sfx(DEFAULT_BUTTON_SFX_PATH)
	click_player.volume_db = DEFAULT_BUTTON_SFX_VOLUME_DB


func _ensure_audio_unlock_ping_player() -> void:
	if audio_unlock_ping_player != null and is_instance_valid(audio_unlock_ping_player):
		return
	_ensure_audio_buses()
	audio_unlock_ping_player = _sfx("res://assets/sfx/click.wav")
	audio_unlock_ping_player.volume_db = -16.0


func _build_extended_audio() -> void:
	if extended_audio_ready:
		return
	_ensure_click_player()
	if success_players.is_empty():
		_append_path_players(success_players, ACTIVITY_SUCCESS_SFX_PATHS, Callable(self, "_sfx"), ACTIVITY_SUCCESS_SFX_VOLUME_DB)
	if crit_success_players.is_empty():
		_append_path_players(crit_success_players, ACTIVITY_CRIT_SFX_PATHS, Callable(self, "_sfx"), ACTIVITY_CRIT_SFX_VOLUME_DB)
	padlock_cluster_player = _ensure_path_player(padlock_cluster_player, PADLOCK_CLUSTER_SFX_PATH, Callable(self, "_sfx"))
	if info_chip_upgrade_players.is_empty():
		_append_repeated_path_players(info_chip_upgrade_players, "res://assets/sfx/xp_spark.wav", INFO_CHIP_UPGRADE_SFX_PLAYER_COUNT, Callable(self, "_sfx"), INFO_CHIP_UPGRADE_SFX_VOLUME_DB)
	failure_player = _ensure_path_player(failure_player, "res://assets/sfx/warm_reject.wav", Callable(self, "_sfx"))
	fishing_failure_player = _ensure_path_player(fishing_failure_player, FISHING_FAILURE_SFX_PATH, Callable(self, "_sfx"), FISHING_FAILURE_SFX_VOLUME_DB)
	chicken_death_player = _ensure_path_player(chicken_death_player, CHICKEN_DEATH_SFX_PATH, Callable(self, "_sfx"), CHICKEN_DEATH_SFX_VOLUME_DB)
	goblin_shield_drop_player = _ensure_path_player(goblin_shield_drop_player, GOBLIN_SHIELD_DROP_SFX_PATH, Callable(self, "_sfx"), GOBLIN_SHIELD_DROP_SFX_VOLUME_DB)
	if fight_punch_players.size() != FIGHT_PUNCH_SFX_PATHS.size():
		_dispose_players(fight_punch_players)
		_append_path_players(fight_punch_players, FIGHT_PUNCH_SFX_PATHS, Callable(self, "_sfx"), FIGHT_PUNCH_SFX_VOLUME_DB)
	opportunity_success_player = _ensure_path_player(opportunity_success_player, "res://assets/sfx/xp_spark.wav", Callable(self, "_sfx"), ACTION_OPPORTUNITY_SUCCESS_SFX_VOLUME_DB)
	opportunity_miss_player = _ensure_path_player(opportunity_miss_player, "res://assets/sfx/warm_reject.wav", Callable(self, "_sfx"), ACTION_OPPORTUNITY_MISS_SFX_VOLUME_DB)
	level_player = _ensure_path_player(level_player, "res://assets/sfx/level_up_jingle.wav", Callable(self, "_sfx"), LEVEL_UP_SFX_VOLUME_DB)
	medal_player = _ensure_path_player(medal_player, "res://assets/sfx/xp_spark.wav", Callable(self, "_sfx"), MEDAL_REWARD_SFX_VOLUME_DB)
	bonus_jingle_player = _ensure_path_player(bonus_jingle_player, "res://assets/sfx/xp_spark.wav", Callable(self, "_sfx"), BONUS_JINGLE_SFX_VOLUME_DB)
	bonus_jingle_echo_player = _ensure_path_player(bonus_jingle_echo_player, "res://assets/sfx/xp_spark.wav", Callable(self, "_sfx"), BONUS_JINGLE_ECHO_SFX_VOLUME_DB)
	fish_eat_player = _ensure_path_player(fish_eat_player, "res://assets/sfx/xp_spark.wav", Callable(self, "_sfx"), -16.0)
	if passive_log_land_players.is_empty():
		_append_repeated_path_players(passive_log_land_players, "res://assets/sfx/click.wav", 4, Callable(self, "_sfx"), -18.0, -1.5)
	passive_upgrade_player = _ensure_path_player(passive_upgrade_player, "res://assets/sfx/click.wav", Callable(self, "_sfx"), -15.0)
	module_pin_entry_player = _ensure_path_player(module_pin_entry_player, MODULE_PIN_ENTRY_SFX_PATH, Callable(self, "_sfx"), MODULE_PIN_ENTRY_SFX_VOLUME_DB)
	module_pin_exit_player = _ensure_path_player(module_pin_exit_player, MODULE_PIN_EXIT_SFX_PATH, Callable(self, "_sfx"), MODULE_PIN_EXIT_SFX_VOLUME_DB)
	extended_audio_ready = true


func _ensure_extended_audio() -> void:
	if extended_audio_ready:
		return
	_build_extended_audio()


func _ensure_music_players_ready() -> void:
	if not music_players.is_empty():
		return
	_build_music_players()


func _ensure_audio_buses() -> void:
	_ensure_audio_bus(MUSIC_BUS_NAME)
	_ensure_audio_bus(SFX_BUS_NAME)


func _ensure_audio_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		AudioServer.set_bus_send(AudioServer.get_bus_index(bus_name), "Master")
		return
	AudioServer.add_bus(AudioServer.bus_count)
	AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
	AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")


func _build_music_players() -> void:
	_dispose_music_players()
	music_players.clear()
	music_layer_gains = []
	music_layer_target_gains = []
	music_base_only_seconds = 0.0
	var song_set := active_music_song_set if not active_music_song_set.is_empty() else _default_music_song_set()
	active_music_song_set = song_set
	for track in _music_tracks_for_song_set(song_set):
		var stream := _load_music_stream(str(track["path"]))
		if stream == null:
			push_warning("Music loop missing: %s" % str(track["path"]))
			continue
		var player := AudioStreamPlayer.new()
		player.stream = stream
		player.bus = MUSIC_BUS_NAME
		player.volume_db = MUSIC_SILENCE_DB
		add_child(player)
		music_players.append(player)
		music_layer_gains.append(0.0)
		music_layer_target_gains.append(0.0)
	music_started = false


func _load_music_stream(path: String) -> AudioStream:
	if music_stream_cache.has(path):
		return music_stream_cache[path] as AudioStream
	var stream := load(path) as AudioStream
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	music_stream_cache[path] = stream
	return stream


func _dispose_music_players() -> void:
	for player in music_players:
		if player == null or not is_instance_valid(player):
			continue
		player.stream_paused = false
		player.stop()
		player.queue_free()


func _stop_music_players() -> void:
	for player in music_players:
		if player == null or not is_instance_valid(player):
			continue
		player.stream_paused = false
		player.stop()
	music_started = false


func _pause_music_for_app_suspend() -> void:
	for player in music_players:
		if player == null or not is_instance_valid(player):
			continue
		player.stream_paused = true


func _restart_music_after_app_resume() -> void:
	music_base_only_seconds = 0.0
	_stop_music_players()
	_ensure_music_playing()


func _default_music_song_set() -> Dictionary:
	return MUSIC_SONG_SETS[0] if MUSIC_SONG_SETS.size() > 0 else {}


func _music_tracks_for_song_set(song_set: Dictionary) -> Array:
	return song_set.get("tracks", []) as Array


func _music_song_set_name(song_set: Dictionary) -> String:
	return str(song_set.get("name", ""))


func _music_players_match_song_set(song_set: Dictionary) -> bool:
	var tracks := _music_tracks_for_song_set(song_set)
	if music_players.is_empty() or music_players.size() != tracks.size():
		return false
	if _music_song_set_name(active_music_song_set) != _music_song_set_name(song_set):
		return false
	var active_tracks := _music_tracks_for_song_set(active_music_song_set)
	if active_tracks.size() != tracks.size():
		return false
	for i in range(tracks.size()):
		var active_track := active_tracks[i] as Dictionary
		var next_track := tracks[i] as Dictionary
		var expected_path := str(next_track.get("path", ""))
		if str(active_track.get("path", "")) != expected_path:
			return false
		var player := music_players[i] as AudioStreamPlayer
		if player == null or not is_instance_valid(player) or player.stream != _load_music_stream(expected_path):
			return false
	return true


func _choose_music_song_set() -> Dictionary:
	var total_weight := 0.0
	for song_set in MUSIC_SONG_SETS:
		total_weight += maxf(0.0, float(song_set.get("weight", 0.0)))
	if total_weight <= 0.0:
		return _default_music_song_set()
	var roll := randf() * total_weight
	var cumulative := 0.0
	for song_set in MUSIC_SONG_SETS:
		cumulative += maxf(0.0, float(song_set.get("weight", 0.0)))
		if roll <= cumulative:
			return song_set
	return _default_music_song_set()


func _select_music_song_for_cycle() -> void:
	var next_song_set := _choose_music_song_set()
	if _music_players_match_song_set(next_song_set):
		music_base_only_seconds = 0.0
		for i in range(music_layer_gains.size()):
			music_layer_gains[i] = 0.0
		for i in range(music_layer_target_gains.size()):
			music_layer_target_gains[i] = 0.0
		return
	active_music_song_set = next_song_set
	_build_music_players()


func _apply_audio_bus_volumes() -> void:
	if not GAME_AUDIO_ENABLED:
		_set_audio_bus_volume(MUSIC_BUS_NAME, 0.0)
		_set_audio_bus_volume(SFX_BUS_NAME, 0.0)
		AudioServer.set_bus_mute(0, true)
		return
	_set_audio_bus_volume(MUSIC_BUS_NAME, 0.0 if music_muted else music_volume * MUSIC_OUTPUT_GAIN)
	_set_audio_bus_volume(SFX_BUS_NAME, 0.0 if sfx_muted else sfx_volume)
	AudioServer.set_bus_mute(0, false)


func _set_audio_bus_volume(bus_name: String, volume: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	var clamped := clampf(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(0.0001, clamped)) if clamped > 0.0 else MUSIC_SILENCE_DB)


func _sfx(path: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = _load_sfx_stream(path)
	player.bus = SFX_BUS_NAME
	add_child(player)
	return player


func _load_sfx_stream(path: String) -> AudioStream:
	if audio_stream_cache.has(path):
		return audio_stream_cache[path] as AudioStream
	var stream = load(path)
	audio_stream_cache[path] = stream
	return stream


func _play(player: AudioStreamPlayer) -> void:
	if player == null or not _can_play_audio():
		return
	if player == click_player:
		_ensure_click_player()
		player = click_player
	elif not extended_audio_ready:
		_ensure_extended_audio()
	if player == null or not player.is_inside_tree():
		return
	player.stop()
	player.pitch_scale = 1.0
	player.play()


func _play_with_pitch(player: AudioStreamPlayer, pitch: float) -> void:
	if player == null or not player.is_inside_tree() or not _can_play_audio():
		return
	if player != click_player:
		_ensure_extended_audio()
	player.stop()
	player.pitch_scale = pitch
	player.play()


func _reward_sfx_window_active() -> bool:
	if Time.get_ticks_msec() <= reward_sfx_exclusive_until_msec:
		return true
	reward_sfx_exclusive_priority = 0
	return false


func _reward_sfx_blocks(priority: int) -> bool:
	return _reward_sfx_window_active() and reward_sfx_exclusive_priority > priority


func _mark_reward_sfx_window(priority: int, duration_msec: int) -> void:
	var now_msec := Time.get_ticks_msec()
	if now_msec > reward_sfx_exclusive_until_msec or priority >= reward_sfx_exclusive_priority:
		reward_sfx_exclusive_priority = priority
		reward_sfx_exclusive_until_msec = now_msec + maxi(0, duration_msec)


func _reward_sfx_recently_played(key: String, now_msec: int) -> bool:
	var last_msec := int(reward_sfx_last_played_msec.get(key, -100000))
	if now_msec - last_msec < REWARD_SFX_KEY_GAP_MSEC:
		return true
	reward_sfx_last_played_msec[key] = now_msec
	return false


func _stop_lower_priority_reward_players(active_player: AudioStreamPlayer = null) -> void:
	var reward_players := []
	reward_players.append_array(success_players)
	reward_players.append_array(crit_success_players)
	reward_players.append_array([medal_player, bonus_jingle_player, bonus_jingle_echo_player])
	for player in reward_players:
		if player == null or player == active_player or not is_instance_valid(player):
			continue
		player.stop()


func _play_sfx_with_pitch_and_volume(player: AudioStreamPlayer, pitch: float, volume_db: float) -> void:
	if player == null or not player.is_inside_tree() or not _can_play_audio():
		return
	if player != click_player:
		_ensure_extended_audio()
	player.stop()
	player.pitch_scale = pitch
	player.volume_db = volume_db
	player.play()


func _play_reward_accent(player: AudioStreamPlayer, pitch: float, volume_db: float, priority: int, key: String, duration_msec := REWARD_SFX_EXCLUSIVE_MSEC) -> bool:
	if not _can_play_audio():
		return false
	_ensure_extended_audio()
	if player == null or not player.is_inside_tree():
		return false
	var now_msec := Time.get_ticks_msec()
	if _reward_sfx_blocks(priority) or _reward_sfx_recently_played(key, now_msec):
		return false
	if priority >= REWARD_SFX_PRIORITY_MEDAL:
		_stop_lower_priority_reward_players(player)
	_play_sfx_with_pitch_and_volume(player, pitch, volume_db)
	_mark_reward_sfx_window(priority, duration_msec)
	return true


func _play_level_up_sfx() -> void:
	_ensure_extended_audio()
	_play_reward_accent(level_player, 1.0, LEVEL_UP_SFX_VOLUME_DB, REWARD_SFX_PRIORITY_LEVEL, "level")


func _play_click_sfx() -> void:
	_ensure_click_player()
	_play(click_player)


func _play_failure_sfx() -> void:
	_ensure_extended_audio()
	_play(failure_player)


func _play_fishing_failure_sfx() -> void:
	_ensure_extended_audio()
	_play(fishing_failure_player)


func _play_fish_eat_blip() -> void:
	_ensure_extended_audio()
	_play_with_pitch(fish_eat_player, randf_range(1.12, 1.24))


func _play_medal_reward_sfx() -> void:
	_ensure_extended_audio()
	_play_reward_accent(medal_player, 1.0, MEDAL_REWARD_SFX_VOLUME_DB, REWARD_SFX_PRIORITY_MEDAL, "medal")


func _play_completion_pip_sfx(streak_step: int) -> void:
	_ensure_extended_audio()
	if success_players.is_empty() or not _can_play_audio():
		return
	var pitch_index := clampi(streak_step, 1, success_players.size()) - 1
	var player := success_players[pitch_index] as AudioStreamPlayer
	if player == null or not player.is_inside_tree():
		return
	var volume_db := ACTIVITY_SUCCESS_DUCKED_SFX_VOLUME_DB if _reward_sfx_window_active() else ACTIVITY_SUCCESS_SFX_VOLUME_DB
	_play_sfx_with_pitch_and_volume(player, 1.0, volume_db)


func _play_activity_tap_sfx() -> void:
	_ensure_click_player()
	if click_player == null or not click_player.is_inside_tree() or not _can_play_audio():
		return
	click_player.stop()
	click_player.pitch_scale = 1.0
	click_player.volume_db = ACTIVITY_START_SFX_VOLUME_DB
	click_player.play()


func _play_passive_log_land_sfx(index: int) -> void:
	_ensure_extended_audio()
	if passive_log_land_players.is_empty() or not _can_play_audio():
		return
	var player := passive_log_land_players[index % passive_log_land_players.size()]
	if player == null or not player.is_inside_tree():
		return
	player.stop()
	player.pitch_scale = 1.12 + float(index % 5) * 0.035
	player.volume_db = -18.0 - float(index % passive_log_land_players.size()) * 1.5
	player.play()


func _play_passive_upgrade_sfx() -> void:
	_ensure_extended_audio()
	if passive_upgrade_player == null or not passive_upgrade_player.is_inside_tree() or not _can_play_audio():
		return
	passive_upgrade_player.stop()
	passive_upgrade_player.pitch_scale = 1.28
	passive_upgrade_player.volume_db = -15.0
	passive_upgrade_player.play()


func _play_firepit_toggle_sfx(lit: bool) -> void:
	_ensure_extended_audio()
	if passive_upgrade_player == null or not passive_upgrade_player.is_inside_tree() or not _can_play_audio():
		return
	passive_upgrade_player.stop()
	passive_upgrade_player.pitch_scale = 0.82 if lit else 0.68
	passive_upgrade_player.volume_db = -20.0 if lit else -24.0
	passive_upgrade_player.play()


func _play_chicken_death_sfx() -> void:
	_ensure_extended_audio()
	if chicken_death_player == null or not chicken_death_player.is_inside_tree() or not _can_play_audio():
		return
	chicken_death_player.stop()
	chicken_death_player.pitch_scale = randf_range(0.96, 1.03)
	chicken_death_player.volume_db = CHICKEN_DEATH_SFX_VOLUME_DB
	chicken_death_player.play()


func _play_goblin_shield_drop_sfx() -> void:
	_ensure_extended_audio()
	_play_sfx_with_pitch_and_volume(goblin_shield_drop_player, randf_range(0.96, 1.04), GOBLIN_SHIELD_DROP_SFX_VOLUME_DB)


func _play_fight_punch_sfx() -> void:
	_ensure_extended_audio()
	if fight_punch_players.is_empty() or not _can_play_audio():
		return
	var player := _fight_punch_player_for_hit()
	if player == null or not player.is_inside_tree():
		return
	player.stop()
	player.pitch_scale = randf_range(FIGHT_PUNCH_SFX_PITCH_MIN, FIGHT_PUNCH_SFX_PITCH_MAX)
	player.volume_db = FIGHT_PUNCH_SFX_VOLUME_DB + randf_range(-FIGHT_PUNCH_SFX_VOLUME_VARIANCE_DB, FIGHT_PUNCH_SFX_VOLUME_VARIANCE_DB)
	player.play()


func _fight_punch_player_for_hit() -> AudioStreamPlayer:
	if fight_punch_players.is_empty():
		return null
	var count := fight_punch_players.size()
	for offset in range(count):
		var index := (fight_punch_player_index + offset) % count
		var candidate := fight_punch_players[index] as AudioStreamPlayer
		if candidate != null and is_instance_valid(candidate) and not candidate.playing:
			fight_punch_player_index = (index + 1) % count
			return candidate
	var fallback := fight_punch_players[fight_punch_player_index % count] as AudioStreamPlayer
	fight_punch_player_index = (fight_punch_player_index + 1) % count
	return fallback


func _play_action_opportunity_sfx(success: bool) -> void:
	_ensure_extended_audio()
	var player := opportunity_success_player if success else opportunity_miss_player
	if player == null or not player.is_inside_tree() or not _can_play_audio():
		return
	player.stop()
	player.pitch_scale = randf_range(1.12, 1.24) if success else randf_range(0.86, 0.94)
	player.volume_db = ACTION_OPPORTUNITY_SUCCESS_SFX_VOLUME_DB if success else ACTION_OPPORTUNITY_MISS_SFX_VOLUME_DB
	player.play()


func _play_info_chip_upgrade_sfx(sequence_index: int, delay := 0.0) -> void:
	_ensure_extended_audio()
	if info_chip_upgrade_players.is_empty() or not _can_play_audio():
		return
	if delay > 0.0:
		var delayed_tween := create_tween()
		delayed_tween.tween_interval(delay)
		delayed_tween.tween_callback(_play_info_chip_upgrade_sfx.bind(sequence_index, 0.0))
		return
	var player := info_chip_upgrade_players[sequence_index % info_chip_upgrade_players.size()] as AudioStreamPlayer
	if player == null or not player.is_inside_tree():
		return
	player.stop()
	player.volume_db = INFO_CHIP_UPGRADE_SFX_VOLUME_DB
	player.pitch_scale = minf(INFO_CHIP_UPGRADE_SFX_PITCH_MAX, INFO_CHIP_UPGRADE_SFX_PITCH_START + float(maxi(0, sequence_index)) * INFO_CHIP_UPGRADE_SFX_PITCH_STEP)
	player.play()


func _play_module_pin_entry_sfx() -> void:
	_ensure_extended_audio()
	if module_pin_entry_player == null or not module_pin_entry_player.is_inside_tree() or not _can_play_audio():
		return
	module_pin_entry_player.stop()
	module_pin_entry_player.pitch_scale = 1.0
	module_pin_entry_player.volume_db = MODULE_PIN_ENTRY_SFX_VOLUME_DB
	module_pin_entry_player.play()


func _play_module_pin_exit_sfx() -> void:
	_ensure_extended_audio()
	if module_pin_exit_player == null or not module_pin_exit_player.is_inside_tree() or not _can_play_audio():
		return
	module_pin_exit_player.stop()
	module_pin_exit_player.pitch_scale = 1.0
	module_pin_exit_player.volume_db = MODULE_PIN_EXIT_SFX_VOLUME_DB
	module_pin_exit_player.play()


func _chain_proximity_gain(source: Variant = null) -> float:
	if _host_string("current_screen") != "skill":
		return CHAIN_OFFSCREEN_GAIN
	var rig: Control = null
	if source is WeakRef:
		var referenced: Variant = (source as WeakRef).get_ref()
		if referenced is Control:
			rig = referenced as Control
	elif source is Control:
		rig = source as Control
	if rig == null or not is_instance_valid(rig) or not rig.is_visible_in_tree():
		rig = _nearest_activity_lock_rig()
	if rig == null or not is_instance_valid(rig) or not rig.is_visible_in_tree():
		return CHAIN_OFFSCREEN_GAIN
	var viewport_rect := _chain_audio_viewport_rect()
	var chain_rect := rig.get_global_rect()
	if viewport_rect.size.y <= 1.0 or chain_rect.size.y <= 1.0:
		return 1.0
	var visible_overlap := maxf(0.0, minf(chain_rect.end.y, viewport_rect.end.y) - maxf(chain_rect.position.y, viewport_rect.position.y))
	var visible_ratio := clampf(visible_overlap / minf(chain_rect.size.y, viewport_rect.size.y), 0.0, 1.0)
	var visible_gain := lerpf(CHAIN_OFFSCREEN_GAIN, 1.0, smoothstep(0.06, 0.62, visible_ratio))
	var direction_to_chain := 0
	var offscreen_distance := 0.0
	if chain_rect.end.y < viewport_rect.position.y:
		direction_to_chain = -1
		offscreen_distance = viewport_rect.position.y - chain_rect.end.y
	elif chain_rect.position.y > viewport_rect.end.y:
		direction_to_chain = 1
		offscreen_distance = chain_rect.position.y - viewport_rect.end.y
	var toward_gain := CHAIN_OFFSCREEN_GAIN
	if direction_to_chain != 0 and chain_audio_scroll_direction == direction_to_chain and chain_audio_scroll_focus_seconds > 0.0:
		var focus := clampf(chain_audio_scroll_focus_seconds / CHAIN_SCROLL_TOWARD_SECONDS, 0.0, 1.0)
		var distance := 1.0 - clampf(offscreen_distance / maxf(1.0, viewport_rect.size.y * CHAIN_SCROLL_AUDITION_DISTANCE), 0.0, 1.0)
		var approach := smoothstep(0.0, 1.0, focus) * smoothstep(0.0, 1.0, distance)
		toward_gain = lerpf(CHAIN_OFFSCREEN_GAIN, CHAIN_SCROLL_TOWARD_GAIN, approach)
	return clampf(maxf(visible_gain, toward_gain), CHAIN_OFFSCREEN_GAIN, 1.0)


func _nearest_activity_lock_rig() -> Control:
	if _host_dict("action_cards").is_empty():
		return null
	var viewport_rect := _chain_audio_viewport_rect()
	var viewport_center_y := viewport_rect.position.y + viewport_rect.size.y * 0.5
	var best_rig: Control = null
	var best_distance := INF
	for raw_card in _host_dict("action_cards").values():
		var card := raw_card as Dictionary
		var overlay := card.get("lock_overlay", {}) as Dictionary
		var overlay_root := _host_valid_control_ref(overlay.get("root"))
		var rig := _host_valid_control_ref(overlay.get("group"))
		if overlay_root == null or rig == null or not overlay_root.visible or not rig.is_visible_in_tree():
			continue
		var rect := rig.get_global_rect()
		var distance := 0.0
		if rect.end.y < viewport_rect.position.y:
			distance = viewport_rect.position.y - rect.end.y
		elif rect.position.y > viewport_rect.end.y:
			distance = rect.position.y - viewport_rect.end.y
		else:
			distance = absf((rect.position.y + rect.size.y * 0.5) - viewport_center_y) * 0.1
		if distance < best_distance:
			best_distance = distance
			best_rig = rig
	return best_rig


func _chain_audio_viewport_rect() -> Rect2:
	var detail_scroll := _host_control("detail_actions_scroll")
	if detail_scroll != null and is_instance_valid(detail_scroll) and detail_scroll.is_visible_in_tree():
		return detail_scroll.get_global_rect()
	var skills_page := _host_control("skills_page")
	if skills_page != null and is_instance_valid(skills_page):
		return skills_page.get_global_rect()
	return get_viewport().get_visible_rect()

func _play_random_chain_move_sfx(source: Variant = null) -> void:
	_play_chain_impact_cluster(1, 0.75, "fall", _chain_proximity_gain(source))


func _play_chain_move_jingle_mix(kind := "drag", intensity := 0.55, source: Variant = null) -> void:
	if not _can_play_audio():
		return
	var proximity_gain := _chain_proximity_gain(source)
	var hit_count := 1
	var impact_kind := str(kind)
	if impact_kind == "click":
		hit_count = 2 + (1 if randf() < CHAIN_CLICK_EXTRA_HIT_CHANCE else 0)
	elif impact_kind == "drag_start":
		hit_count = 2
	elif randf() < CHAIN_DRAG_EXTRA_HIT_CHANCE:
		hit_count = 2
	_play_chain_impact_cluster(hit_count, intensity, impact_kind, proximity_gain)
	if impact_kind == "click":
		_play_chain_jingle_mix(randi_range(0, 3), randf_range(0.78, 0.95) * proximity_gain, CHAIN_CLICK_JINGLE_TOTAL_SECONDS, CHAIN_CLICK_JINGLE_FADE_SECONDS)
	elif impact_kind == "drag_start" and randf() < CHAIN_DRAG_JINGLE_CHANCE * 1.8:
		_play_chain_jingle_mix(randi_range(0, 3), randf_range(0.42, 0.58) * proximity_gain)
	elif impact_kind == "drag" and randf() < CHAIN_DRAG_JINGLE_CHANCE:
		_play_chain_jingle_mix(randi_range(0, 3), randf_range(0.28, 0.46) * proximity_gain)


func _ensure_chain_move_audio() -> void:
	if chain_move_audio_ready:
		return
	_dispose_players(chain_move_players)
	_dispose_players(chain_jingle_players)
	chain_move_audio_ready = true
	for path in CHAIN_MOVE_SFX_PATHS:
		for i in range(CHAIN_MOVE_PLAYER_COPIES):
			chain_move_players.append(_sfx(path))
	for i in range(3):
		var player := _sfx(CHAIN_JINGLE_SFX_PATH)
		player.volume_db = -8.0 - float(i) * 3.0
		chain_jingle_players.append(player)


func _play_chain_impact_cluster(hit_count: int, intensity: float, kind := "drag", proximity_gain := 1.0) -> void:
	_ensure_chain_move_audio()
	if chain_move_players.is_empty() or not _can_play_audio():
		return
	var clamped_intensity := clampf(intensity, 0.15, 1.0)
	var clamped_proximity_gain := clampf(proximity_gain, CHAIN_OFFSCREEN_GAIN, 1.0)
	for i in range(maxi(1, hit_count)):
		var delay := randf_range(0.015, 0.075) * float(i)
		if delay <= 0.0:
			_play_chain_impact_hit(clamped_intensity, kind, i, clamped_proximity_gain)
		else:
			var tween := create_tween()
			tween.tween_interval(delay)
			tween.tween_callback(_play_chain_impact_hit.bind(clamped_intensity, kind, i, clamped_proximity_gain))


func _play_chain_impact_hit(intensity: float, kind: String, index: int, proximity_gain := 1.0) -> void:
	var player := _chain_move_player_for_hit()
	if player == null:
		return
	var loudness := lerpf(-12.0, -2.5, intensity)
	if kind == "click":
		loudness += 1.6
	elif kind == "drag":
		loudness -= 2.2
	loudness += linear_to_db(clampf(proximity_gain, CHAIN_OFFSCREEN_GAIN, 1.0))
	player.volume_db = loudness - float(index) * randf_range(1.2, 3.4) + randf_range(-1.5, 1.2)
	player.pitch_scale = randf_range(0.88, 1.14) + (intensity - 0.5) * 0.08
	var start_offset := 0.0 if kind == "click" else randf_range(0.0, 0.045)
	player.play(start_offset)


func _chain_move_player_for_hit() -> AudioStreamPlayer:
	var available := []
	for player in chain_move_players:
		if player != null and not player.playing:
			available.append(player)
	if not available.is_empty():
		return available.pick_random() as AudioStreamPlayer
	var fallback := chain_move_players.pick_random() as AudioStreamPlayer
	if fallback != null:
		fallback.stop()
	return fallback


func _play_padlock_cluster_sfx() -> void:
	_play(padlock_cluster_player)


func _play_chain_fall_sfx_sequence(source: Control = null) -> void:
	var proximity_gain: float = _chain_proximity_gain(source)
	var source_ref: WeakRef = weakref(source) if source != null else null
	_play_chain_jingle_mix(0, proximity_gain)
	var tween := create_tween()
	tween.tween_interval(ACTIVITY_UNLOCK_CHAIN_FALL_SECONDS * 0.28)
	tween.tween_callback(_play_random_chain_move_sfx.bind(source_ref))
	tween.tween_interval(ACTIVITY_UNLOCK_CHAIN_FALL_SECONDS * 0.26)
	tween.tween_callback(_play_chain_jingle_mix.bind(1, proximity_gain))
	tween.tween_interval(ACTIVITY_UNLOCK_CHAIN_FALL_SECONDS * 0.24)
	tween.tween_callback(_play_random_chain_move_sfx.bind(source_ref))


func _play_chain_jingle_mix(variant := 0, gain := 1.0, total_seconds := CHAIN_JINGLE_TOTAL_SECONDS, fade_seconds := CHAIN_JINGLE_FADE_SECONDS) -> void:
	_ensure_chain_move_audio()
	if chain_jingle_players.is_empty() or not _can_play_audio():
		return
	var pitches := [0.90, 0.98, 1.07]
	var player_count := mini(CHAIN_JINGLE_MIX_LAYER_COUNT, mini(chain_jingle_players.size(), pitches.size()))
	for i in range(player_count):
		var player := chain_jingle_players[i] as AudioStreamPlayer
		var volume_db := -10.0 - float(i) * 3.0 + linear_to_db(maxf(0.05, gain))
		var pitch := float(pitches[i]) + float(variant) * 0.025
		_play_capped_chain_jingle(player, pitch, volume_db, total_seconds, fade_seconds)


func _play_capped_chain_jingle(player: AudioStreamPlayer, pitch: float, volume_db: float, total_seconds := CHAIN_JINGLE_TOTAL_SECONDS, fade_seconds := CHAIN_JINGLE_FADE_SECONDS) -> void:
	if player == null or not _can_play_audio():
		return
	_kill_meta_tween(player, "chain_jingle_fade_tween")
	player.stop()
	player.pitch_scale = pitch
	player.volume_db = volume_db
	player.play()
	var fade_tween := create_tween()
	var player_id := player.get_instance_id()
	player.set_meta("chain_jingle_fade_tween", fade_tween)
	fade_tween.tween_interval(maxf(0.0, total_seconds - fade_seconds))
	fade_tween.tween_property(player, "volume_db", -48.0, fade_seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	fade_tween.tween_callback(_finish_capped_chain_jingle.bind(player_id, volume_db))


func _finish_capped_chain_jingle(player_id: int, volume_db: float) -> void:
	var player := instance_from_id(player_id) as AudioStreamPlayer
	if player == null or not is_instance_valid(player):
		return
	player.remove_meta("chain_jingle_fade_tween")
	player.stop()
	player.volume_db = volume_db


func _play_activity_success_sound(streak_step: int, medal_unlocked: bool, streak_bonus: bool, xp_crit := false, mega_crit := false, crit_chain_count := 0) -> void:
	if xp_crit:
		_play_activity_crit_sound(streak_step, mega_crit, crit_chain_count)
		return
	_play_completion_pip_sfx(streak_step)
	if streak_bonus:
		_play_bonus_jingle()
	elif medal_unlocked:
		_play_medal_reward_sfx()


func _play_activity_crit_sound(streak_step: int, mega_crit := false, crit_chain_count := 0) -> void:
	_ensure_extended_audio()
	if crit_success_players.is_empty():
		return
	var pitch_index := clampi(streak_step, 1, crit_success_players.size()) - 1
	if mega_crit:
		var pitch := minf(ACTIVITY_MEGA_CRIT_SFX_PITCH_MAX, ACTIVITY_MEGA_CRIT_SFX_PITCH_START + float(maxi(0, crit_chain_count - 2)) * ACTIVITY_MEGA_CRIT_SFX_PITCH_STEP)
		_play_reward_accent(crit_success_players[pitch_index], pitch, ACTIVITY_CRIT_SFX_VOLUME_DB, REWARD_SFX_PRIORITY_CRIT, "crit")
		return
	_play_reward_accent(crit_success_players[pitch_index], 1.0, ACTIVITY_CRIT_SFX_VOLUME_DB, REWARD_SFX_PRIORITY_CRIT, "crit")


func _play_bonus_jingle() -> void:
	if not _can_play_audio():
		return
	_ensure_extended_audio()
	if not _play_reward_accent(bonus_jingle_player, 1.18, BONUS_JINGLE_SFX_VOLUME_DB, REWARD_SFX_PRIORITY_BONUS, "bonus", REWARD_SFX_BONUS_EXCLUSIVE_MSEC):
		return
	var tween := create_tween()
	tween.tween_interval(ACTIVITY_BONUS_JINGLE_DELAY)
	tween.tween_callback(_play_bonus_jingle_echo_if_unblocked)


func _play_bonus_jingle_echo_if_unblocked() -> void:
	if not _reward_sfx_blocks(REWARD_SFX_PRIORITY_BONUS):
		_play_sfx_with_pitch_and_volume(bonus_jingle_echo_player, 1.42, BONUS_JINGLE_ECHO_SFX_VOLUME_DB)


func _process_music_flow(delta: float) -> void:
	if not MUSIC_ENABLED:
		music_cycle_active = false
		music_lockout_seconds = MUSIC_QUIET_BREAK_LOCKOUT_SECONDS
		music_start_fade_remaining = 0.0
		music_ultimate_boost_seconds = 0.0
		music_quiet_fade_remaining = 0.0
		music_layer_target_gains = _music_targets_for_intensity(0)
		for i in range(music_layer_gains.size()):
			music_layer_gains[i] = 0.0
		_stop_music_players()
		return
	if music_lockout_seconds > 0.0:
		music_lockout_seconds = maxf(0.0, music_lockout_seconds - delta)
	if music_start_fade_remaining > 0.0:
		music_start_fade_remaining = maxf(0.0, music_start_fade_remaining - delta)
	if music_ultimate_boost_seconds > 0.0:
		music_ultimate_boost_seconds = maxf(0.0, music_ultimate_boost_seconds - delta)
	if flow_failure_drag > 0.0:
		flow_failure_drag = maxf(0.0, flow_failure_drag - delta * 0.22)
	var action_running := not _host_running_action_id().is_empty()
	if (
		not music_cycle_active
		and not action_running
		and music_lockout_seconds <= 0.0
		and music_start_fade_remaining <= 0.0
		and music_ultimate_boost_seconds <= 0.0
		and flow_failure_drag <= 0.001
		and flow_heat <= 0.001
		and flow_idle_seconds >= MUSIC_FLOW_DEAD_SECONDS
		and _music_layers_are_silent()
	):
		music_layer_target_gains = _music_targets_for_intensity(0)
		return
	flow_idle_seconds = minf(MUSIC_FLOW_DEAD_SECONDS, flow_idle_seconds + delta)
	var heat_decay := 0.04 if action_running else 0.38
	flow_heat = maxf(0.0, flow_heat - delta * heat_decay)
	if action_running:
		flow_active_action_seconds += delta
	if music_cycle_active:
		_ensure_music_playing()
	var target_intensity := _music_flow_target_intensity()
	target_intensity = _process_music_base_loop_guard(delta, target_intensity)
	music_layer_target_gains = _music_targets_for_intensity(target_intensity)
	_apply_music_layer_fades(delta)
	if music_cycle_active and target_intensity == 0 and _music_layers_are_silent():
		music_cycle_active = false


func _ensure_music_playing() -> void:
	_ensure_music_players_ready()
	if not audio_unlocked_by_input or music_players.is_empty() or not is_inside_tree():
		return
	if music_started:
		return
	var started_count := 0
	for player in music_players:
		if player == null or not is_instance_valid(player) or not player.is_inside_tree():
			continue
		player.stream_paused = false
		player.volume_db = MUSIC_SILENCE_DB
		player.play(0.0)
		started_count += 1
	music_started = started_count > 0


func _record_music_flow_start() -> void:
	flow_idle_seconds = 0.0
	flow_active_action_seconds = maxf(flow_active_action_seconds, 1.0)
	flow_heat = clampf(flow_heat + 2.5, 0.0, 36.0)


func _record_music_flow_action(success: bool, streak_step: int, streak_bonus: bool, medal_unlocked: bool, skill_level_up: bool, stamina_cost: float) -> void:
	flow_actions_taken += 1
	if music_cycle_active:
		flow_idle_seconds = 0.0
	var heat_gain := 0.7
	if success:
		heat_gain += 0.55 + float(clampi(streak_step, 1, ACTIVITY_STREAK_BONUS_STEP)) * 0.22
	else:
		heat_gain = 0.28
		flow_failure_drag = minf(4.0, flow_failure_drag + 1.0)
	if streak_bonus:
		heat_gain += 2.25
		music_ultimate_boost_seconds = maxf(music_ultimate_boost_seconds, 7.0)
	if medal_unlocked:
		heat_gain += 1.35
		music_ultimate_boost_seconds = maxf(music_ultimate_boost_seconds, 4.5)
	if skill_level_up:
		heat_gain += 1.7
		music_ultimate_boost_seconds = maxf(music_ultimate_boost_seconds, 5.5)
	if success and flow_actions_taken >= MUSIC_BASE_ACTION_THRESHOLD and flow_heat >= 18.0 and randf() < 0.09:
		music_ultimate_boost_seconds = maxf(music_ultimate_boost_seconds, 3.8)
	flow_heat = clampf(flow_heat + heat_gain, 0.0, 36.0)
	if flow_actions_taken >= MUSIC_BASE_ACTION_THRESHOLD:
		music_start_chance_unlocked = true
	if _maybe_trigger_music_quiet_break(stamina_cost):
		return
	if music_start_chance_unlocked and not music_cycle_active and music_lockout_seconds <= 0.0 and randf() < MUSIC_COMPLETION_START_CHANCE:
		_start_music_cycle()


func _maybe_trigger_music_quiet_break(stamina_cost: float) -> bool:
	if stamina_cost >= MUSIC_QUIET_BREAK_STAMINA_CEILING or music_lockout_seconds > 0.0:
		return false
	if not music_cycle_active and _music_layers_are_silent():
		return false
	if randf() >= MUSIC_QUIET_BREAK_CHANCE:
		return false
	_trigger_music_quiet_break()
	return true


func _trigger_music_quiet_break() -> void:
	music_cycle_active = false
	music_lockout_seconds = MUSIC_QUIET_BREAK_LOCKOUT_SECONDS
	music_start_fade_remaining = 0.0
	music_base_only_seconds = 0.0
	music_quiet_fade_remaining = MUSIC_QUIET_BREAK_FADE_SECONDS
	music_quiet_fade_start_gains = music_layer_gains.duplicate()
	music_layer_target_gains = _music_targets_for_intensity(0)
	music_ultimate_boost_seconds = 0.0
	flow_idle_seconds = MUSIC_FLOW_DEAD_SECONDS


func _nudge_music_flow_down(amount: float) -> void:
	flow_failure_drag = minf(4.0, flow_failure_drag + amount)
	flow_heat = maxf(0.0, flow_heat - amount * 1.8)


func _start_music_cycle() -> void:
	if not MUSIC_ENABLED:
		return
	if music_lockout_seconds > 0.0:
		return
	_select_music_song_for_cycle()
	music_cycle_active = true
	music_start_fade_remaining = MUSIC_START_FADE_SECONDS
	music_base_only_seconds = 0.0
	flow_idle_seconds = 0.0
	flow_active_action_seconds = maxf(flow_active_action_seconds, 1.0)
	flow_heat = maxf(flow_heat, 6.0)
	_ensure_music_playing()


func _maybe_start_music_cycle_on_launch() -> void:
	if not MUSIC_ENABLED:
		return
	if not music_start_chance_unlocked or music_cycle_active or music_muted or music_lockout_seconds > 0.0:
		return
	if randf() >= MUSIC_LAUNCH_START_CHANCE:
		return
	audio_unlocked_by_input = true
	flow_actions_taken = maxi(flow_actions_taken, MUSIC_BASE_ACTION_THRESHOLD)
	_start_music_cycle()


func _saved_music_groove_floor() -> int:
	var estimated := 0
	for skill_id in _host_dict("skills").keys():
		var skill_state := _host_dict("skills").get(skill_id, {}) as Dictionary
		estimated += int(floor(float(skill_state.get("xp", 0)) / 4.0))
	for key in _host_dict("mastery").keys():
		var mastery_state := _host_dict("mastery").get(key, {}) as Dictionary
		estimated += int(floor(float(mastery_state.get("xp", 0)) / 3.0))
	return clampi(estimated, 0, MUSIC_BASE_ACTION_THRESHOLD)

func _music_flow_target_intensity() -> int:
	if not audio_unlocked_by_input or not music_cycle_active or music_lockout_seconds > 0.0:
		return 0
	var action_running := not _host_running_action_id().is_empty()
	if not action_running and flow_idle_seconds >= MUSIC_FLOW_DEAD_SECONDS:
		return 0
	var effective_heat := flow_heat + float(_host_activity_streak_count()) * 0.72 - flow_failure_drag
	var intensity := 1
	if effective_heat >= 15.0 or _host_activity_streak_count() >= ACTIVITY_STREAK_BONUS_STEP or (float(host._action_runtime()._active_action_stamina_cost()) if host != null else 0.0) >= 4:
		intensity = 2
	if music_ultimate_boost_seconds > 0.0 and effective_heat >= 11.0:
		intensity = 3
	if not action_running and flow_idle_seconds > MUSIC_FLOW_IDLE_FADE_SECONDS:
		intensity = mini(intensity, 1)
	if flow_failure_drag >= 2.7:
		intensity = maxi(0, intensity - 1)
	return intensity

func _music_targets_for_intensity(intensity: int) -> Array:
	match intensity:
		0:
			return [0.0, 0.0, 0.0]
		1:
			return [1.0, 0.0, 0.0]
		2:
			return [0.70, 1.0, 0.0]
		_:
			return [0.56, 0.82, 1.0]


func _process_music_base_loop_guard(delta: float, target_intensity: int) -> int:
	if not music_cycle_active or target_intensity != 1 or music_start_fade_remaining > 0.0:
		music_base_only_seconds = 0.0
		return target_intensity
	if _music_upper_layers_are_audible():
		music_base_only_seconds = 0.0
		return target_intensity
	music_base_only_seconds += delta
	if music_base_only_seconds < MUSIC_BASE_ONLY_GUARD_SECONDS:
		return target_intensity
	music_base_only_seconds = 0.0
	if _host_running_action_id().is_empty():
		_trigger_music_quiet_break()
		return 0
	flow_heat = maxf(flow_heat, 16.0)
	music_ultimate_boost_seconds = maxf(music_ultimate_boost_seconds, 3.8)
	return _music_flow_target_intensity()


func _music_upper_layers_are_audible() -> bool:
	for i in range(1, music_layer_gains.size()):
		if float(music_layer_gains[i]) > 0.035:
			return true
	return false


func _music_layers_are_silent() -> bool:
	for gain in music_layer_gains:
		if float(gain) > 0.01:
			return false
	return true


func _apply_music_layer_fades(delta: float) -> void:
	if music_players.is_empty():
		return
	if music_quiet_fade_remaining > 0.0:
		music_quiet_fade_remaining = maxf(0.0, music_quiet_fade_remaining - delta)
		var fade_ratio := music_quiet_fade_remaining / maxf(0.001, MUSIC_QUIET_BREAK_FADE_SECONDS)
		for i in range(music_players.size()):
			var player := music_players[i] as AudioStreamPlayer
			if player == null:
				continue
			var start_gain := float(music_quiet_fade_start_gains[i]) if i < music_quiet_fade_start_gains.size() else 0.0
			var next_gain := start_gain * fade_ratio
			if music_quiet_fade_remaining <= 0.0 or next_gain < 0.002:
				next_gain = 0.0
			music_layer_gains[i] = next_gain
			_apply_music_layer_gain(player, i, next_gain)
		return
	for i in range(music_players.size()):
		var player := music_players[i] as AudioStreamPlayer
		if player == null:
			continue
		var current := float(music_layer_gains[i]) if i < music_layer_gains.size() else 0.0
		var target := float(music_layer_target_gains[i]) if i < music_layer_target_gains.size() else 0.0
		var fade_seconds := MUSIC_BASE_FADE_SECONDS if i == 0 else MUSIC_LAYER_FADE_SECONDS
		if i == 2:
			fade_seconds = MUSIC_ULTIMATE_FADE_SECONDS
		if music_start_fade_remaining > 0.0 and target > current:
			fade_seconds = maxf(fade_seconds, MUSIC_START_FADE_SECONDS)
		elif target < current:
			fade_seconds += 1.8
		var blend := 1.0 if delta <= 0.0 else 1.0 - exp(-delta / maxf(0.001, fade_seconds))
		var next_gain := lerpf(current, target, blend)
		if absf(next_gain - target) < 0.002:
			next_gain = target
		music_layer_gains[i] = next_gain
		_apply_music_layer_gain(player, i, next_gain)


func _apply_music_layer_gain(player: AudioStreamPlayer, layer_index: int, gain: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	if not player.playing:
		player.stream_paused = false
		player.play(_music_sync_position_for_layer(layer_index))
	var layer_boost := float(MUSIC_LAYER_VOLUME_BOOST_DB[layer_index]) if layer_index < MUSIC_LAYER_VOLUME_BOOST_DB.size() else 0.0
	player.volume_db = linear_to_db(maxf(0.0001, gain)) + layer_boost if gain > 0.0 else MUSIC_SILENCE_DB


func _music_sync_position_for_layer(layer_index: int) -> float:
	if layer_index <= 0:
		return 0.0
	for i in range(music_players.size()):
		if i == layer_index:
			continue
		var player := music_players[i] as AudioStreamPlayer
		if player == null or not is_instance_valid(player) or not player.playing:
			continue
		var stream_length := 0.0
		if player.stream != null:
			stream_length = player.stream.get_length()
		var position := player.get_playback_position()
		return fmod(position, stream_length) if stream_length > 0.0 else position
	return 0.0


func _can_play_audio() -> bool:
	return GAME_AUDIO_ENABLED and audio_unlocked_by_input


func _play_audio_unlock_ping() -> void:
	if not GAME_AUDIO_ENABLED:
		return
	if audio_unlock_ping_played:
		return
	audio_unlock_ping_played = true
	_ensure_audio_unlock_ping_player()
	if audio_unlock_ping_player == null or not is_instance_valid(audio_unlock_ping_player):
		return
	if not audio_unlock_ping_player.is_inside_tree():
		return
	audio_unlock_ping_player.stop()
	audio_unlock_ping_player.pitch_scale = 1.0
	audio_unlock_ping_player.play()


func _unlock_audio_for_gameplay() -> void:
	if audio_unlocked_by_input and audio_unlock_ping_played:
		return
	audio_unlocked_by_input = true
	_prepare_audio_buses()
	_play_audio_unlock_ping()
	_ensure_music_playing()


