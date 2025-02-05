@tool
extends Marker2D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		position = Vector2.ZERO
	else:
		var pos = global_position
		top_level = true
		position = pos
