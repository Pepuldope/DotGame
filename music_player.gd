class_name MusicPlayer
extends AudioStreamPlayer

## Background music playlist — add paths here to include more tracks.
const PLAYLIST : Array[String] = [
	"res://audio/Submorphics - Electric Winter Sky (SPOTISAVER).ogg",
	"res://audio/Submorphics - Starchilds Theme (SPOTISAVER).ogg",
]

var _index   : int  = -1
var _paused  : bool = false

func _ready() -> void:
	apply_volume()
	finished.connect(_on_finished)
	_shuffle_start()

func apply_volume() -> void:
	volume_db = GameSettings.volume_db()

func _shuffle_start() -> void:
	if PLAYLIST.is_empty():
		return
	_index = randi() % PLAYLIST.size()
	_play_current()

func _on_finished() -> void:
	if _paused:
		return
	_advance()

func _advance() -> void:
	if PLAYLIST.size() <= 1:
		_play_current()
		return
	var next := _index
	while next == _index:
		next = randi() % PLAYLIST.size()
	_index = next
	_play_current()

func _play_current() -> void:
	if _index < 0 or _index >= PLAYLIST.size():
		return
	var s := load(PLAYLIST[_index])
	if s:
		stream = s
		play()

## Call to temporarily silence bg music (e.g. easter egg).
func pause_music() -> void:
	_paused = true
	stop()

## Call to resume bg music after pause.
func resume_music() -> void:
	_paused = false
	_play_current()
