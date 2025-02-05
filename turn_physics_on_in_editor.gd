@tool
extends Node

@export var physics_active: bool = true

# Called when the node enters the scene tree for the first time.
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		PhysicsServer2D.set_active(physics_active)