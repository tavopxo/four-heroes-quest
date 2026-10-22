extends AnimatableBody2D
class_name MovingPlatform

@export var move_offset: Vector2 = Vector2(80, 0)
@export var speed: float = 50.0
@export var use_grey_skin: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var origin_pos: Vector2
var target_pos: Vector2
var moving_to_target: bool = true

func _ready() -> void:
	collision_layer = 2 # Terrain
	collision_mask = 1 # Player
	sync_to_physics = true
	origin_pos = position
	target_pos = origin_pos + move_offset
	
	if animated_sprite:
		var anim = "grey_on" if use_grey_skin else "brown_on"
		animated_sprite.play(anim)

func _physics_process(delta: float) -> void:
	if move_offset == Vector2.ZERO:
		return
	var dest = target_pos if moving_to_target else origin_pos
	position = position.move_toward(dest, speed * delta)
	if position.distance_to(dest) < 1.0:
		moving_to_target = not moving_to_target
