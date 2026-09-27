class_name TweenParam extends Resource


@export var duration: float = 0.5
@export var transition_type := Tween.TransitionType.TRANS_SINE
@export var ease_type := Tween.EaseType.EASE_IN_OUT

var tween: Tween = null


func _init() -> void:
	resource_local_to_scene = true


func start(object: Object, property: NodePath, final_val: Variant) -> Tween:
	if tween:
		tween.kill()
	tween = object.create_tween()

	tween.set_ease(ease_type).set_trans(transition_type).tween_property(
			object, property, final_val, duration)
	return tween
