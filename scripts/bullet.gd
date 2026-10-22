extends Area2D
class_name Bullet

@export var speed: float = 520.0
@export var damage: int = 1
var direction := Vector2.RIGHT
var lifetime := 1.2

func _ready() -> void:
	collision_layer = 32
	collision_mask = 16
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is Enemy:
		(body as Enemy).hit(damage)
		queue_free()
