extends Node

@onready var _slide_player: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var _crunch_player: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var _chime_player: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var _music_player: AudioStreamPlayer = AudioStreamPlayer.new()

var _slide_stream: AudioStream
var _crunch_stream: AudioStream
var _chime_stream: AudioStream
var _music_stream: AudioStream


func _ready() -> void:
	_slide_player.name = "SlidePlayer"
	_crunch_player.name = "CrunchPlayer"
	_chime_player.name = "ChimePlayer"
	_music_player.name = "MusicPlayer"
	_music_player.bus = "Master"
	add_child(_slide_player)
	add_child(_crunch_player)
	add_child(_chime_player)
	add_child(_music_player)

	_slide_stream = _load_optional("res://assets/sfx/slide.wav")
	_crunch_stream = _load_optional("res://assets/sfx/crunch.wav")
	_chime_stream = _load_optional("res://assets/sfx/chime.wav")
	_music_stream = _load_optional("res://assets/music/cozy_loop.wav")

	if _slide_stream:
		_slide_player.stream = _slide_stream
	if _crunch_stream:
		_crunch_player.stream = _crunch_stream
	if _chime_stream:
		_chime_player.stream = _chime_stream
	if _music_stream:
		if _music_stream is AudioStreamWAV:
			(_music_stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
		_music_player.stream = _music_stream
		_music_player.volume_db = -12.0


func _load_optional(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
	return null


func play_slide() -> void:
	if _slide_player.stream:
		_slide_player.play()


func play_crunch() -> void:
	if _crunch_player.stream:
		_crunch_player.play()


func play_chime() -> void:
	if _chime_player.stream:
		_chime_player.play()


func start_music() -> void:
	if _music_player.stream and not _music_player.playing:
		_music_player.play()


func stop_music() -> void:
	if _music_player.playing:
		_music_player.stop()
