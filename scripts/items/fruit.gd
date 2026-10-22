extends Area2D
class_name Fruit

@export_enum("apple", "bananas", "cherries", "kiwi", "melon", "orange", "pineapple", "strawberry") var fruit_type: String = "apple"

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var game_manager: Node:
	get:
		if not is_inside_tree():
			return null
		return get_node_or_null("/root/GameManager")

var is_collected: bool = false

func _ready() -> void:
	collision_layer = 8
	collision_mask = 1 # Player
	body_entered.connect(_on_body_entered)
	
	if game_manager:
		game_manager.total_fruits_in_level += 1
	
	var path = "res://resources/fruit_" + fruit_type + "_frames.tres"
	if ResourceLoader.exists(path):
		animated_sprite.sprite_frames = load(path)
	animated_sprite.play("idle")

func _on_body_entered(body: Node2D) -> void:
	if is_collected or not (body is Player):
		return
		
	is_collected = true
	collision_shape.set_deferred("disabled", true)
	if game_manager:
		game_manager.collect_fruit()
	
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("collected"):
		animated_sprite.play("collected")
		var tween = create_tween()
		tween.tween_property(self, "position:y", position.y - 12.0, 0.3)
		await animated_sprite.animation_finished
	
	queue_free()
