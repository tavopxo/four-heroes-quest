extends Node2D

@onready var player: Player = get_parent()
var aim_direction := Vector2.RIGHT

func _process(_delta: float) -> void:
	if not player or not player.is_inside_tree():
		return
	var mouse_position = get_global_mouse_position()
	aim_direction = (mouse_position - global_position).normalized()
	rotation = aim_direction.angle()
	scale.y = -1.0 if aim_direction.x < 0.0 else 1.0
	queue_redraw()
	if Input.is_action_pressed("fire"):
		player.fire_bullet(aim_direction, global_position)

func _draw() -> void:
	draw_rect(Rect2(0, -3, 15, 6), Color("#6b4937"))
	draw_rect(Rect2(10, -2, 9, 4), Color("#d6dce4"))
	draw_circle(Vector2(2, 0), 4, Color("#293241"))
