extends StaticBody2D
class_name BreakableBox

@export_range(1, 3) var box_type: int = 1
@export var max_hits: int = 2
@export var contains_fruit: bool = true
@export_enum("apple", "bananas", "cherries", "kiwi", "melon", "orange", "pineapple", "strawberry") var contained_fruit_type: String = "cherries"

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hit_area: Area2D = $HitArea

var audio_manager: Node:
	get:
		if not is_inside_tree():
			return null
		return get_node_or_null("/root/AudioManager")

var current_hits: int = 0
var is_broken: bool = false

func _ready() -> void:
	collision_layer = 2 # Terrain / solid
	collision_mask = 1 # Player
	
	var frames_path = "res://resources/box" + str(box_type) + "_frames.tres"
	if ResourceLoader.exists(frames_path):
		animated_sprite.sprite_frames = load(frames_path)
	animated_sprite.play("idle")
	
	hit_area.body_entered.connect(_on_hit_area_body_entered)

func _on_hit_area_body_entered(body: Node2D) -> void:
	if is_broken or not (body is Player):
		return
		
	var player = body as Player
	var diff_y = player.global_position.y - global_position.y
	
	if diff_y < -4: # From above
		if player.is_ground_pounding:
			hit(max_hits, player)
			player.bounce(280.0)
		else:
			hit(1, player)
			player.bounce(220.0)
	elif diff_y > 4: # From below
		player.velocity.y = 80.0
		hit(1, player)

func hit(amount: int, player: Player = null) -> void:
	if is_broken:
		return
	current_hits += amount
	if audio_manager:
		audio_manager.play_sfx("box_break", randf_range(1.1, 1.3))
	
	var tween = create_tween()
	tween.tween_property(animated_sprite, "position:y", -3.0, 0.05)
	tween.tween_property(animated_sprite, "position:y", 0.0, 0.05)
	
	if current_hits >= max_hits:
		break_box()
	else:
		animated_sprite.play("hit")
		await animated_sprite.animation_finished
		if not is_broken:
			animated_sprite.play("idle")

func break_box() -> void:
	is_broken = true
	collision_shape.set_deferred("disabled", true)
	hit_area.set_deferred("monitoring", false)
	if audio_manager:
		audio_manager.play_sfx("box_break", 0.9)
	
	if contains_fruit:
		call_deferred("_spawn_fruit")
		
	animated_sprite.play("break")
	await animated_sprite.animation_finished
	queue_free()

func _spawn_fruit() -> void:
	var fruit_scene = load("res://scenes/items/fruit.tscn")
	if fruit_scene:
		var fruit = fruit_scene.instantiate()
		fruit.set("fruit_type", contained_fruit_type)
		fruit.global_position = global_position + Vector2(0, -14)
		get_parent().add_child(fruit)
