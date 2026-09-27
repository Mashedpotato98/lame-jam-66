class_name Hitbox extends Area2D


signal damaged(damage: int)

@export var multi: int = 1
@onready var collision_shape: CollisionShape2D = $CollisionShape
@onready var disabled := false:
	set(value):
		disabled = value
		collision_shape.set_deferred(&"disabled", value)


func take_damage(damage: int) -> void:
	damaged.emit(damage * multi)
