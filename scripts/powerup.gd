extends Area2D
class_name Powerup

@export_enum("health", "speed", "star") var powerup_type: String = "health"

func _ready() -> void:
	collision_layer = 8
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	_update_visual()

func _update_visual() -> void:
	var colors = {
		"health": Color("#e94b6b"),
		"speed": Color("#48c7ff"),
		"star": Color("#ffd447")
	}
	$Icon.modulate = colors.get(powerup_type, Color.WHITE)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		(body as Player).apply_powerup(powerup_type)
		queue_free()
