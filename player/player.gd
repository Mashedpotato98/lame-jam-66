class_name Player extends Node2D


# TODO: Move the hit windows to the proper script.
# NOTE: The hit windows must be ordered from greatest offset to least.
# BUG: If hitwindows overlap, 2 notes can be consumed at once.
enum HitWindows {
	BAD = 200,
	GOOD = 100,
	PERFECT = 50,
}

signal health_set(health: int)
signal died(player: Player)

const FALL_SCAN_LENGTH: float = 512.0
const BASE_JUMP_HEIGHT: float = 4.0
const BASE_STEP_SIZE: float = 6.0
const JUMP_DURATION: float = 1.0
const DUCK_DURATION: float = 1.0

@export var id: int = 1
@export var movement_tween: TweenParam
@export var direction: int = 1:
	set(value):
		if value == 0:
			return
		direction = clampi(value, -1, 1)
		if not is_node_ready():
			await ready

		combat_boxes.transform.x.x = direction
		sprite.flip_h = direction < 0

var get_offset: Callable = func(_id: int, _latency: float) -> float: return 0
var hit_note: Callable = func(_id: int) -> void: print("Consumed note.")
var wait_beats: Callable = func(duration: float) -> void:
		await get_tree().create_timer(duration, false).timeout
var get_multi: Callable = func(_id: int) -> int: return randi_range(1, 3)
var dead := false

@onready var sprite: Sprite2D = $Sprite
@onready var collision_detector: ShapeCast2D = $CollisionDetector
@onready var combat_boxes: Node2D = %CombatBoxes
@onready var hitboxes: Node2D = %Hitboxes
@onready var prone_hitbox: Hitbox = %ProneHitbox
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var low_kick: Hurtbox = %LowKick
@onready var sword_slash: Hurtbox = %SwordSlash
@onready var high_kick: Hurtbox = %HighKick
@onready var ground_n_pound: Hurtbox = %GroundNPound
@onready var floor_detector: Area2D = $FloorDetector
@onready var is_on_floor: bool:
	get:
		return floor_detector.get_overlapping_bodies().size() > 0
@onready var health: int = 100:
	set(value):
		if dead:
			return
		health = value
		health_set.emit(health)
		$TestHealthBar.value = health
		if health <= 0:
			dead = true
			play(&"death")
			set_physics_process(false)
			set_process_input(false)
			set_process(false)
			died.emit(self)
@onready var hit_sound: AudioStreamPlayer2D = $HitSound
@onready var prone := false:
	set(value):
		prone = value
		for hitbox: Hitbox in hitboxes.get_children():
			hitbox.disabled = (hitbox != prone_hitbox) == prone
@onready var stunned := false:
	set(value):
		stunned = value


func _ready() -> void:
	sprite.top_level = true
	sprite.position = global_position
	for hitbox: Hitbox in hitboxes.get_children():
		hitbox.damaged.connect(_on_hitbox_damaged)


func _input(event: InputEvent) -> void:
	if stunned:
		return

	var latency: float = 0#AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
	var offset: float = get_offset.call(id, latency)
	print(offset)
	offset = absf(offset)
	if offset == INF:
		return
	var multi: int = -1
	for i: int in range(1, HitWindows.size() + 1):
		if offset <= HitWindows.values()[i - 1] / 1000.0:
			multi = i
	if multi == -1:
		return
	var acc: int = multi
	get_tree().create_timer(0.2).timeout.connect(func(): $Label.text = "")
	multi *= get_multi.call(id)

	# FIXME: Clean up this monster somehow. Maybe by using a node-based or signal-based system.
	if is_pressed(event, "left"):
		direction = -1
		move(Vector2.LEFT * BASE_STEP_SIZE * multi)
		play(&"run")
	elif is_pressed(event, "right"):
		direction = 1
		move(Vector2.RIGHT * BASE_STEP_SIZE * multi)
		play(&"run")
	elif is_pressed(event, "duck"):
		#move(Vector2.DOWN * FALL_SCAN_LENGTH)
		prone = true
		play(&"dodge")
		# ALERT: await shouldn't be called here because the note is only hit after all this.
		await wait_beats.call(DUCK_DURATION / multi)
		prone = false
		_on_animation_player_animation_finished(&"dodge")
	elif is_pressed(event, "low_kick"):
		low_kick.activate()
		play(&"atk2")
	elif not prone:
		if is_pressed(event, "jump"):
			move(Vector2.UP * BASE_JUMP_HEIGHT * multi)
			play(&"jump_up")
			#await wait_beats.call(JUMP_DURATION)
			#move(Vector2.DOWN * FALL_SCAN_LENGTH)
		elif is_pressed(event, "slash"):
			sword_slash.activate()
			play(&"atk3")
		elif is_pressed(event, "high_kick"):
			high_kick.activate()
			play(&"atk1")
		elif is_pressed(event, "dash"):
			pass
		else:
			return
	else:
		return

	hit_note.call(id)
	hit_sound.play()
	match acc:
		1:
			$Label.text = "Meh"
		2:
			$Label.text = "OK"
		3:
			$Label.text = "Great!"


func play(anim: StringName) -> void:
	animation_player.play(anim, -1, 2.0)


func is_pressed(event: InputEvent, action: StringName) -> bool:
	return event.is_action_pressed(action + "_" + str(id))


func move(velocity: Vector2) -> void:
	collision_detector.target_position = velocity
	collision_detector.force_shapecast_update()
	var interp: float = collision_detector.get_closest_collision_safe_fraction()
	global_position = global_position.lerp(global_position + velocity, interp)
	movement_tween.start(sprite, ^"position", global_position)


func get_polygon_from_rect_collider(collider: CollisionShape2D) -> PackedVector2Array:
	assert(collider.shape is RectangleShape2D)
	var size: Vector2 = collider.shape.size
	var result := PackedVector2Array()
	var loop := [-1, 1]
	for y: int in loop:
		for x: int in loop:
			result.append(Vector2(size.x * x, size.y * y) * collider.global_transform)
	return result


func stun(duration: float) -> void:
	if stunned:
		return

	prone = true
	stunned = true
	await wait_beats.call(duration)
	prone = false
	stunned = false


func _on_hitbox_damaged(damage: int) -> void:
	health -= damage


func _on_floor_detector_body_exited(_body: Node2D) -> void:
	await wait_beats.call(JUMP_DURATION)
	move(Vector2.DOWN * FALL_SCAN_LENGTH)
	play(&"jump_down")


func _on_legs_damaged(_damage: int) -> void:
	pass#stun(1.0)


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name != "death":
		play(&"idle" if is_on_floor else &"jump_up")
