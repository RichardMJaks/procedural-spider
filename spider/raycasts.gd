@tool
extends Node2D
class_name Raycasts

class Raycaster:
	var raycast: RayCast2D
	var position: Vector2
	var on_ground: bool = false

	@warning_ignore("shadowed_variable")
	func _init(raycast: RayCast2D, pos: Vector2) -> void:
		self.raycast = raycast
		self.position = pos

@onready var ll_raycast: Raycaster = Raycaster.new($LLRaycast, Vector2.ZERO)
@onready var ul_raycast: Raycaster = Raycaster.new($ULRaycast, Vector2.ZERO)
@onready var lr_raycast: Raycaster = Raycaster.new($LRRaycast, Vector2.ZERO)
@onready var ur_raycast: Raycaster = Raycaster.new($URRaycast, Vector2.ZERO)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var raycasts: Array[Raycaster] = [
		ll_raycast,
		ul_raycast,
		lr_raycast,
		ur_raycast
	]	
	for rc: Raycaster in raycasts:
		var raycast = rc.raycast
		raycast.force_raycast_update()
		if not raycast.is_colliding():
			rc.position = raycast.global_position + raycast.target_position
			rc.on_ground = false
			continue

		rc.on_ground = true
		
		rc.position = raycast.get_collision_point()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	

	var raycasts: Array[Raycaster] = [
		ll_raycast,
		ul_raycast,
		lr_raycast,
		ur_raycast
	]

	for rc: Raycaster in raycasts:
		var raycast = rc.raycast
		raycast.force_raycast_update()
		if not raycast.is_colliding():
			rc.position = raycast.global_position + raycast.target_position
			rc.on_ground = false
			continue

		rc.on_ground = true
		
		rc.position = raycast.get_collision_point()
		
