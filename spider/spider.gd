extends CharacterBody2D

@onready var raycast_handler: Node2D = $Raycasts
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var eye: Bone2D = %Eye
@onready var ik: Node2D = $IKTargets
@onready var ground_detection: RayCast2D = $Raycasts/BodyHeightRaycast
@onready var movement_target: Marker2D = %MovementTarget

var looking_at_player: bool = false
var player: Node2D = null

@export var speed = 400
@export var distance_from_ground: float = 100
@export_range(0, 1) var dampening_force: float = 0.05
@export var is_active: bool = false


func _physics_process(delta: float) -> void:
	velocity += _add_object_forces(get_last_slide_collision())

	if not is_active:
		move_and_slide()
		return
	
	if looking_at_player:
		eye.look_at(player.global_position)
		movement_target.global_position = player.global_position
	
	_calculate_vertical_forces(delta)

	var dir = movement_target.global_position.x - global_position.x
	if dir > 20:
		dir = 1
	elif dir < -20:
		dir = -1
	else:
		dir = 0
	
	if dir != 0 and dir * velocity.x < speed:
		velocity.x += dir * speed * delta
	if dir == 0:
		velocity.x *= 1 - clampf(dampening_force * delta * 4, 0, 1)
	raycast_handler.position.x = dir * speed / 3

	move_and_slide()

func _add_object_forces(collision: KinematicCollision2D) -> Vector2:
	if not collision:
		return Vector2.ZERO

	var normal: Vector2 = collision.get_normal()
	var v: float = collision.get_collider_velocity().length()
	return normal * v

func _calculate_vertical_forces(delta: float) -> void:
	var normalized_distance: float = _get_normalized_distance_from_ground()	
	var up_force: float = _calculate_upwards_force(normalized_distance)
	var gravity_force: float = get_gravity().y * clampf(normalized_distance, 0, 1)

	#print("Up force: " + str(up_force))
	#print("Gravity force: " + str(gravity_force))
	#print("Normalized_distance: " + str(normalized_distance))
	velocity.y += (-up_force + gravity_force) * delta
	velocity.y = clampf(velocity.y, -get_gravity().y, get_gravity().y)
	velocity.y *= 1 - dampening_force * delta
	

func _calculate_upwards_force(normalized_distance: float) -> float:
	if not is_active or not ground_detection.is_colliding():
		return 0
	var foot_multiplier = 0.5 * sqrt(ik.supporting_feet)
	#print("Foot multiplier: " + str(foot_multiplier))
	var up_force: float = get_gravity().y * foot_multiplier
	up_force = up_force * (2 - normalized_distance)
	return up_force

func _get_normalized_distance_from_ground() -> float:
	var ground_distance: float = distance_from_ground
	if ground_detection.is_colliding():
		ground_distance = ground_detection.get_collision_point().distance_to(ground_detection.global_position)
	var normalized_distance = ground_distance / distance_from_ground
	return normalized_distance

func _spotted_player(body: Node2D) -> void:
	if player:
		return
	
	is_active = true
	anim.play("eye_ready")
	player = body

func _look_at_player() -> void:
	var t = create_tween()
	t.tween_property(eye, "rotation", eye.global_position.angle_to(player.global_position), 0.05)
	t.tween_callback(func(): looking_at_player = true)
