extends Node

var music_player: AudioStreamPlayer
const BACKGROUND_MUSIC_PATH = "res://assets/Musik/Background/game-background.wav"

func _ready():
	print("=== AudioManager: Initializing ===")
	_setup_music_player()
	play_music()
	print("=== AudioManager: Initialization complete ===")
	set_volume(0.5)

func _setup_music_player():
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.bus = "Master"
	music_player.autoplay = false # We'll manually call play() in _ready()
	
	var music_stream = load(BACKGROUND_MUSIC_PATH)
	if music_stream:
		print("AudioManager: Successfully loaded background music")
		music_player.stream = music_stream
		
		# Set loop mode based on stream type to ensure it loops
		if music_stream is AudioStreamWAV:
			music_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			print("AudioManager: Set WAV loop mode to LOOP_FORWARD")
		elif music_stream is AudioStreamOggVorbis:
			music_stream.loop = true
			print("AudioManager: Set OGG loop to true")
	else:
		push_error("Failed to load background music from: " + BACKGROUND_MUSIC_PATH)

func play_music():
	if music_player and not music_player.playing:
		music_player.play()
		print("AudioManager: Started playing background music")
	elif music_player and music_player.playing:
		print("AudioManager: Music is already playing")

func stop_music():
	if music_player:
		music_player.stop()

# Volume should be between 0.0 and 1.0
func set_volume(linear_volume: float):
	if music_player:
		# Convert linear energy to decibels
		music_player.volume_db = linear_to_db(linear_volume)
