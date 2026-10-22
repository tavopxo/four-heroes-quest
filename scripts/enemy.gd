extends CharacterBody2D
class_name Enemy

@export var patrol_distance: float = 80.0
@export var speed: float = 34.0
@export var max_health: int = 2

var health: int
var origin_x: float
var direction: float = -1.0
var game_manager: Node:
	get:
		if not is_inside_tree():
			return null
		return get_node_or_null("/root/GameManager")

func _ready() -> void:
	collision_layer = 16
	collision_mask = 3
	health = max_health
	origin_x = global_position.x
	$Body.body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if game_manager and game_manager.is_game_over:
		return
	velocity.x = direction * speed
	if global_position.x <= origin_x - patrol_distance:
		direction = 1.0
	elif global_position.x >= origin_x + patrol_distance:
		direction = -1.0
	velocity.y += 980.0 * delta
	move_and_slide()
	$Body.scale.x = direction

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		(body as Player).take_damage(1, Vector2(direction, -1.0).normalized())

func hit(damage: int = 1) -> void:
	health -= damage
	if game_manager and game_manager.audio_manager:
		game_manager.audio_manager.play_sfx("enemy_hit")
	if health <= 0:
		queue_free()
