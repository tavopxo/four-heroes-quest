extends Area2D
class_name FanTrap

@export var updraft_force: float = 620.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var players_in_zone: Array[Player] = []

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if animated_sprite:
		animated_sprite.play("on")

func _physics_process(delta: float) -> void:
	for p in players_in_zone:
		if is_instance_valid(p) and not p.is_dead:
			p.velocity.y = move_toward(p.velocity.y, -updraft_force, 1800.0 * delta)

func _on_body_entered(body: Node2D) -> void:
	if body is Player and not players_in_zone.has(body):
		players_in_zone.append(body as Player)

func _on_body_exited(body: Node2D) -> void:
	if body is Player and players_in_zone.has(body):
		players_in_zone.erase(body as Player)
