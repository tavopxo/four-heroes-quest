extends Area2D
class_name Checkpoint

@export_enum("start", "mid", "end") var checkpoint_type: String = "mid"

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var confetti_particles: CPUParticles2D = $ConfettiParticles

var game_manager: Node:
	get:
		if not is_inside_tree():
			return null
		return get_node_or_null("/root/GameManager")

var is_activated: bool = false

func _ready() -> void:
	collision_layer = 8 # Items
	collision_mask = 1 # Player
	body_entered.connect(_on_body_entered)
	
	match checkpoint_type:
		"start":
			animated_sprite.sprite_frames = load("res://resources/checkpoint_start_frames.tres")
			animated_sprite.play("idle")
			if game_manager:
				game_manager.start_position = global_position
		"mid":
			animated_sprite.sprite_frames = load("res://resources/checkpoint_mid_frames.tres")
			animated_sprite.play("no_flag")
		"end":
			animated_sprite.sprite_frames = load("res://resources/checkpoint_end_frames.tres")
			animated_sprite.play("idle")

func _on_body_entered(body: Node2D) -> void:
	if is_activated or not (body is Player):
		return
		
	match checkpoint_type:
		"start":
			is_activated = true
			animated_sprite.play("moving")
		"mid":
			is_activated = true
			if game_manager:
				game_manager.set_checkpoint(global_position)
			animated_sprite.play("flag_out")
			await animated_sprite.animation_finished
			animated_sprite.play("flag_idle")
		"end":
			is_activated = true
			collision_shape.set_deferred("disabled", true)
			animated_sprite.play("pressed")
			confetti_particles.restart()
			if game_manager:
				game_manager.complete_level()
