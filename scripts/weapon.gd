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
	# Readable side-view pistol silhouette: receiver, barrel, trigger guard,
	# and an angled grip rather than a single sword-like line.
	draw_rect(Rect2(-2, -5, 12, 10), Color("#303746"))
	draw_rect(Rect2(8, -3, 13, 6), Color("#8b95a5"))
	draw_rect(Rect2(18, -2, 5, 4), Color("#d8e0e8"))
	draw_polygon(
		PackedVector2Array([Vector2(1, 4), Vector2(8, 4), Vector2(5, 17), Vector2(-2, 14)]),
		PackedColorArray([Color("#6b4937")])
	)
	draw_arc(Vector2(3, 7), 5, 0.1, 2.5, 8, Color("#1f2630"), 2.0)
	draw_circle(Vector2(21, 0), 2, Color("#ffe38a"))
