@tool
extends Node2D

@export var ray_amount: int = 10
@export var ray_distance: float = 1000
@export var max_distance_for_weighting: float = 1000
@export var min_distance_for_weighting: float = 200
@export_range(0, 1) var max_weight: float = 1:
	set(value):
		max_weight = value
		if max_weight < min_weight:
			min_weight = value
@export_range(0, 1) var min_weight: float = 0:
	set(value):
		min_weight = value
		if min_weight > max_weight:
			max_weight = value

@export var ray_spread_width: float = 100

@export var rotate_rays: bool = false
@export_range(0, 180, 0.1, "radians_as_degrees") var cast_angle: float = PI/2

var avg_y: float = 0
var is_colliding: bool = false
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Create or remove children to match ray_amount
	var children: Array[Node] = get_children_array()
	var ray_count = children.size()
	var weight_matrix: Array[Array] = [] 

	avg_y = 0
	var total_y = 0
	var total_weight = 0
	is_colliding = false
	var w: float = cast_angle if rotate_rays else ray_spread_width
	var shift: float = w / (ray_count - 1)
	for i in range(ray_count):
		var child: RayCast2D = children[i]
		offset_ray(child, shift, i)
		get_ray_y(child, weight_matrix)

	for wy in weight_matrix:
		var y = wy[0]
		var weight = wy[1]
		total_y += y * weight
		total_weight += weight
	
	avg_y = total_y / total_weight

func offset_ray(ray: RayCast2D, shift: float, idx: int) -> void:
	if rotate_rays:
		ray.rotation = shift * idx - cast_angle / 2
	else:
		ray.position.x = shift * idx - ray_spread_width / 2

func get_ray_y(ray: RayCast2D, weight_matrix: Array[Array]) -> void:
	ray.target_position.y = ray_distance
	var x = ray.position.x
	ray.force_raycast_update()

	var y = 0
	if ray.is_colliding():
		is_colliding = true
		y = ray.get_collision_point().y
		add_to_weight_matrix(y, x, weight_matrix)
		return
	y = (ray.global_position + ray.target_position)\
		.rotated(ray.rotation).y
	add_to_weight_matrix(y, x, weight_matrix)

func add_to_weight_matrix(y: float, x: float, weight_matrix: Array[Array]) -> void:
	weight_matrix.append([y, get_weight(x)])

func get_weight(x: float) -> float:
	x = abs(x)
	if x > max_distance_for_weighting:
		return max_weight
	if x < max_distance_for_weighting:
		return min_weight
	var growth = max_weight - min_weight
	var offset = \
		max_distance_for_weighting * min_weight - min_distance_for_weighting
	var reducer = max_distance_for_weighting - min_distance_for_weighting

	return (growth * x + offset) / reducer

func get_children_array() -> Array[Node]:
	var children: Array[Node] = get_children()
	var ray_count: int = children.size()
	match_rays(children, ray_count)
	ray_count = ray_amount
	return children

#region Ray matching
func match_rays(child_arr: Array[Node], ray_count: int) -> void:
	if ray_count < ray_amount:
		for i in range(ray_amount - ray_count):
			create_ray(child_arr)
	if ray_count > ray_amount:
		for i in range(ray_count - ray_amount):
			remove_ray(child_arr)

func create_ray(child_arr: Array[Node]) -> void:
	var ray = RayCast2D.new()
	add_child(ray)
	child_arr.append(ray)

func remove_ray(child_arr: Array[Node]) -> void:
	var ray = child_arr.pop_front()
	ray.queue_free()
#endregion