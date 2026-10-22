extends Node

var sfx_streams: Dictionary = {}
var sfx_players: Array[AudioStreamPlayer] = []
var next_sfx_player_index: int = 0
var bgm_player: AudioStreamPlayer

var sfx_volume: float = 1.0
var music_volume: float = 0.8

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Load SFX
	var sfx_names = [
		"jump", "double_jump", "fruit", "trampoline", "hurt",
		"box_break", "checkpoint", "dash", "stomp", "win", "click"
	]
	for s_name in sfx_names:
		var path = "res://audio/" + s_name + ".wav"
		if ResourceLoader.exists(path):
			sfx_streams[s_name] = load(path)
			
	# Create SFX player pool
	for i in range(10):
		var asp = AudioStreamPlayer.new()
		asp.bus = "Master"
		add_child(asp)
		sfx_players.append(asp)
		
	# Create BGM player
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Master"
	var bgm_path = "res://audio/bgm.wav"
	if ResourceLoader.exists(bgm_path):
		var bgm_stream = load(bgm_path)
		bgm_player.stream = bgm_stream
	add_child(bgm_player)
	bgm_player.finished.connect(_on_bgm_finished)
	
	play_bgm()

func play_sfx(sound_name: String, pitch_scale: float = 1.0, volume_offset_db: float = 0.0) -> void:
	if not sfx_streams.has(sound_name) or sfx_volume <= 0.001:
		return
	var stream: AudioStream = sfx_streams[sound_name]
	var player: AudioStreamPlayer = sfx_players[next_sfx_player_index]
	next_sfx_player_index = (next_sfx_player_index + 1) % sfx_players.size()
	
	player.stream = stream
	player.pitch_scale = pitch_scale
	player.volume_db = linear_to_db(sfx_volume) + volume_offset_db
	player.play()

func play_bgm() -> void:
	if bgm_player and bgm_player.stream and music_volume > 0.001:
		bgm_player.volume_db = linear_to_db(music_volume)
		if not bgm_player.playing:
			bgm_player.play()

func stop_bgm() -> void:
	if bgm_player:
		bgm_player.stop()

func _on_bgm_finished() -> void:
	if music_volume > 0.001 and bgm_player:
		bgm_player.play()

func set_sfx_volume(val: float) -> void:
	sfx_volume = clampf(val, 0.0, 1.0)

func set_music_volume(val: float) -> void:
	music_volume = clampf(val, 0.0, 1.0)
	if bgm_player:
		if music_volume <= 0.001:
			bgm_player.volume_db = -80.0
		else:
			bgm_player.volume_db = linear_to_db(music_volume)
			if not bgm_player.playing:
				bgm_player.play()
