@tool
extends Node2D

@export var step_time: float = 0.1
@export var step_height: float = 30
@export var step_distance_delta: float = 30

@onready var raycast_handler = $"../Raycasts"

@onready var raycasts = [
	[raycast_handler.ul_raycast, $ULIKTarget],
    [raycast_handler.ul_raycast, $LLIKTarget],
    [raycast_handler.ur_raycast, $URIKTarget],
    [raycast_handler.ur_raycast, $LRIKTarget]
]

var supporting_feet: int = 0

#region Movement matrix
# This determines stepping
# Changing order of these will change order of stepping
#
########################
# Arguments (in order) #
########################
# 0. Raycaster & IK Target
# 1. Can move
# 2. Wants to move
# 3. Lerping important start_position
# 4. Lerping important end_position
# 4. Lerp weight

@onready var step_matrix: Array[Array] = [
	# Lower-left leg 	(0)
	[raycasts[0], 	true, 	false,	Vector2.ZERO, 	Vector2.ZERO,	0],
	# Upper-right leg 	(1)
	[raycasts[3], 	false, 	false,	Vector2.ZERO, 	Vector2.ZERO,	0],
	# Upper-left leg	(2)
	[raycasts[1], 	false, 	false,	Vector2.ZERO,	Vector2.ZERO,	0],
	# Lower-right  leg	(3)
	[raycasts[2], 	false, 	false,	Vector2.ZERO, 	Vector2.ZERO,	0]
]
var current_leg = 0
#endregion

func _ready() -> void:
	for i in range(step_matrix.size()):
		step_matrix[i][0][1].global_position = step_matrix[i][0][0].position
		step_matrix[i][3] = step_matrix[i][0][1].global_position

func _process(_delta: float) -> void:
	for child: Marker2D in get_children():
		child.gizmo_extents = step_distance_delta

func _physics_process(delta: float) -> void:
	supporting_feet = 0
	for i in range(step_matrix.size()):
		# Dont check if already wants to move
		if not step_matrix[i][2]:
			step_matrix[i][2] = get_wants(step_matrix[i][0])
		
		# Support the body if still don't want to move
		if not step_matrix[i][2] and step_matrix[i][0][0].on_ground:
			supporting_feet += 1
		
		# Give up the right to move if don't want to move yet
		if (step_matrix[i][1] and not step_matrix[i][2]) or not step_matrix[i][0][0].on_ground:
			_handle_queuing_next_leg(i)
			continue

		if not step_matrix[i][1] or not step_matrix[i][2]:
			continue
		
		# Set starting values in haven't lerped yet
		if step_matrix[i][5] == 0:
			step_matrix[i][3] = step_matrix[i][0][1].global_position
			step_matrix[i][4] = step_matrix[i][0][0].position

		# Increase the weight	
		step_matrix[i][5] = clamp(
			step_matrix[i][5] + (1 / step_time) * delta,
			0, 1
		)

		step_matrix[i][0][1].global_position = _handle_lerping(
			step_matrix[i][3],
			step_matrix[i][4],
			step_matrix[i][5]
		)

		if step_matrix[i][5] >= 1:
			_handle_queuing_next_leg(i)
	
	
# Gets if leg wants to step	
func get_wants(rc_ik: Array) -> bool:
		var rc: Raycasts.Raycaster = rc_ik[0]
		var ik: Marker2D = rc_ik[1]

		var d = rc.position.distance_to(ik.global_position)
		return d > step_distance_delta

func _handle_lerping(start_pos: Vector2, end_pos: Vector2, weight) -> Vector2:
	var pos = start_pos.lerp(end_pos, weight)
	pos.y -= sin(weight * PI) * step_height
	return pos

func _handle_queuing_next_leg(idx: int) -> void:
	# Reset current leg values
	step_matrix[idx][1] = false
	step_matrix[idx][2] = false
	step_matrix[idx][5] = 0

	# Enable next leg to be ready (and make sure weight is reset)
	@warning_ignore("integer_division")
	idx = (idx + 1) - step_matrix.size() * ((idx + 1) / step_matrix.size())	
	step_matrix[idx][1] = true
	step_matrix[idx][5] = 0

