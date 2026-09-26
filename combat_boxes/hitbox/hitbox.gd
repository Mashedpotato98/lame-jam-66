class_name Hitbox extends Area2D


signal damaged(damage: int)

@export var multi: int = 1


func take_damage(damage: int) -> void:
	damaged.emit(damage * multi)
