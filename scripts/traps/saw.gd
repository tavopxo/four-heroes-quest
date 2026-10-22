extends Area2D
class_name Saw

@export var patrol_offset: Vector2 = Vector2.ZERO
@export var speed: float = 80.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var origin_pos: Vector2
var target_pos: Vector2
var moving_to_target: bool = true

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	
	origin_pos = position
	target_pos = origin_pos + patrol_offset
	
	if animated_sprite and animated_sprite.sprite_frames.has_animation("on"):
		animated_sprite.play("on")

func _physics_process(delta: float) -> void:
	if patrol_offset != Vector2.ZERO:
		var dest = target_pos if moving_to_target else origin_pos
		position = position.move_toward(dest, speed * delta)
		if position.distance_to(dest) < 1.0:
			moving_to_target = not moving_to_target

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var knock_dir = (body.global_position - global_position).normalized()
		(body as Player).take_damage(1, knock_dir)
