class_name Main extends Node2D


@onready var player: Player = $Player
@onready var music_sync: MusicSync = $MusicSync


func _ready() -> void:
	player.hit_note = music_sync.hit_note
	player.get_offset = music_sync.get_offset
	player.wait_beats = music_sync.wait_beats
	player.get_multi = music_sync.get_multi
