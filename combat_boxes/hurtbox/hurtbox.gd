class_name Hurtbox extends Area2D


@export var damage: int = 1

var just_hit := false

@onready var collision_shape: CollisionShape2D = $CollisionShape
@onready var duration: Timer = $Duration


@warning_ignore("shadowed_variable")
func activate() -> void:
	just_hit = false
	collision_shape.set_deferred(&"disabled", false)
	duration.start()


func cancel_activation() -> void:
	duration.stop()
	_on_duration_timeout()


func _on_duration_timeout() -> void:
	collision_shape.set_deferred(&"disabled", true)


func _on_area_entered(hitbox: Hitbox) -> void:
	if just_hit:
		return
	just_hit = true
	cancel_activation()
	hitbox.take_damage(damage)
