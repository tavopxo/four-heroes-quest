extends Area2D
class_name Spikes

func _ready() -> void:
	collision_layer = 4 # Traps
	collision_mask = 1 # Player
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var knock_dir = (body.global_position - global_position).normalized()
		(body as Player).take_damage(1, knock_dir)
