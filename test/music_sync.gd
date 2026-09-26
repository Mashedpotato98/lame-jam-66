extends Node2D

signal do_something_on_beat(beat:int);

var time_begin:float
var time_delay:float

@export var bpm:int = 146

@onready var secs_per_beat:float = 60.0 / bpm;

var last_beat:int
var move_tween:Tween
var in_beat:bool

func startMusic(player:AudioStreamPlayer2D, midi:MidiPlayer):
	pass
	#player.play()
	#midi.play();


func midiProcess():
	in_beat = false
	var song_position = ($AudioStreamPlayer2D.get_playback_position() + AudioServer.get_time_since_last_mix()) - AudioServer.get_output_latency() 
	var curr_beat = floor(song_position / secs_per_beat)


	if (curr_beat > last_beat):
		in_beat = true
		last_beat = curr_beat
		do_something_on_beat.emit(curr_beat)

	#if in_beat:
		#print("in beat ");

func _ready() -> void:
	#startMusic($AudioStreamPlayer2D, $MidiPlayer)\
	$AudioStreamPlayer2D.play()
	do_something_on_beat.connect(_do_something_on_beat)


func _process(delta: float) -> void:
	midiProcess()

#ignore. Was goofing around with the plugin
func _on_midi_player_midi_event(channel: Variant, event: Variant) -> void:
	pass
	#if Input.is_action_pressed("ui_right"): 
		#if channel.number == 1:
			#print("sucesss")
		#else:
			#print("die")

func _on_timer_timeout() -> void:
	$Sprite2D.global_position.x -= 10

func _do_something_on_beat(beat:int):
	pass
	#move_tween = get_tree().create_tween()
	#move_tween.tween_property($Sprite2D, "position", Vector2(0,0), 0.1)
