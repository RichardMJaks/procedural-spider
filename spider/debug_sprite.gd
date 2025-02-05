@tool
extends Sprite2D

func _process(delta: float) -> void:
	if Engine.is_editor_hint() or get_tree().debug_navigation_hint:
		visible = true
	else:
		visible = false
