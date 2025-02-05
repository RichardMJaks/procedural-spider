extends CharacterBody2D

@onready var anim: AnimationPlayer = $AnimationPlayer
@export var speed = 500
@export var jump_force: float = 200
@export var acceleration_multiplier = 4

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		$Body.rotation = 0
	else:
		$Body.rotation = 0 - get_floor_angle()

	var dir = Input.get_axis("m_left", "m_right")

	velocity.x = move_toward(velocity.x, dir * speed, speed * acceleration_multiplier * delta)
	if velocity.x > 0:
		anim.play("walk_left")
		anim.speed_scale= velocity.x / speed
	if velocity.x < 0:
		anim.play("walk_right")
		anim.speed_scale = velocity.x / speed
	if is_zero_approx(velocity.x):
		anim.play("RESET")
		anim.speed_scale = 1
	if Input.is_action_just_pressed("m_jump"):
		velocity.y -= jump_force

	move_and_slide()
