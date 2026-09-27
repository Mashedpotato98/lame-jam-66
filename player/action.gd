class_name Action extends Node
## DEPRECATED.
## The name of the node will be the input event it listens to.


enum HIT_WINDOWS {
	BAD = 1,
	GOOD = 2,
	PERFECT = 3,
}

signal activated(action: Action)

## Measured in music time.
@export var cooldown: float = 0.0:
	get:
		const MEH_HIT_WINDOW: int = 100
		return cooldown - (MEH_HIT_WINDOW / 1000.0)

var hit_note_and_get_offset: Callable
var id: int

@onready var event: StringName:
	get:
		return name + "_" + str(id)


func _unhandled_input(event: InputEvent) -> void:
	pass
