class_name MusicSync extends Node2D


const MAX_HIT_WINDOW: float = Player.HitWindows.BAD / 1000.0
const BPM = 155 # FIXME

var approach_time: float = 1.0
var hit_keys: Dictionary[int, PackedStringArray] = {1: [], 2: []}

@onready var midi_player: MidiPlayer = $MidiPlayer
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var t:
	get:
		return midi_player.current_time


func _ready() -> void:
	midi_player.note.connect(_on_midi_player_note)
	midi_player.link_audio_stream_player([audio_stream_player])
	midi_player.play()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	const TOP_MARGIN: float = 32.0
	var screen_width: float = ProjectSettings.get_setting("display/window/size/viewport_width")
	var half_screen: float = screen_width / 2.0
	# TODO: Replace with draw_texture()
	draw_circle(Vector2(half_screen, TOP_MARGIN), 9.0, Color.GRAY)
	for e: Dictionary in midi_player.get_notes_around(t, 0, approach_time):
		if not e.get("active", false):
			continue
		#var velocity: int = e.get("data", 0)
		for id: int in hit_keys.keys():
			var key: String = _note_key(e)
			if not key in hit_keys[id]:
				var id_dirs: Dictionary[int, int] = {1: -1, 2: 1}
				var radius: float = 2.0 * e.get("data", 0)
				var pos := Vector2(
					lerpf(
						half_screen + id_dirs[id] * (half_screen + radius),
						half_screen,
						remap(e.get("time", 0.0), t - approach_time, t, 0.0, 1.0)
					),
						TOP_MARGIN
				)
				draw_circle(pos, radius, Color.RED if id == 1 else Color.BLUE)


func _note_key(e: Dictionary) -> String:
	return str(e.get("time", 0.0)) + ":" + str(e.get("note", 0))


## Returns null if no notes are within the max hit window.
func get_current_note(id: int) -> Dictionary:
	var current: Dictionary
	for event: Dictionary in midi_player.get_notes_around(midi_player.current_time,
			MAX_HIT_WINDOW, MAX_HIT_WINDOW):
		if not event.get("active", false):
			continue
		if _note_key(event) in hit_keys[id]:
			continue
		if current == {} or event.get("time", 0.0) > current.get("time", 0.0):
			current = event

	return current


func sort_notes(a: Dictionary, b: Dictionary) -> bool:
	return absf(get_offset_from_event(a)) < absf(get_offset_from_event(b))


func get_offset_from_event(event: Dictionary, latency: float = 0.0) -> float:
	if event == {}:
		return INF
	return t - event.get("time", 0.0) + latency


func get_offset(id: int, latency: float = 0.0) -> float:
	return get_offset_from_event(get_current_note(id), latency)


func hit_note(id: int) -> void:
	var key: String = _note_key(get_current_note(id))
	if not hit_keys[id].has(key):
		hit_keys[id].append(key)


func wait_beats(duration: float) -> void:
	var bpm: int = 200#midi_player.midi.tempo
	await get_tree().create_timer(60.0 / bpm * duration).timeout


func get_multi(id: int) -> int:
	return get_current_note(id).get("data", 0)


func _on_midi_player_note(event: Dictionary, _track: int) -> void:
	if event.get("active", false): # note on
		print("On")
