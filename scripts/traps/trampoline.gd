extends Area2D
class_name Trampoline

@export var bounce_force: float = 460.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var audio_manager: Node:
	get:
		if not is_inside_tree():
			return null
		return get_node_or_null("/root/AudioManager")

var can_bounce: bool = true

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	if animated_sprite:
		animated_sprite.play("idle")

func _on_body_entered(body: Node2D) -> void:
	if not can_bounce or not (body is Player):
		return
		
	var player = body as Player
	if player.global_position.y <= global_position.y + 4.0:
		can_bounce = false
		player.bounce(bounce_force)
		if audio_manager:
			audio_manager.play_sfx("trampoline", 1.0)
		
		if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("jump"):
			animated_sprite.play("jump")
			await animated_sprite.animation_finished
			animated_sprite.play("idle")
			
		can_bounce = true
