extends StaticBody2D
class_name FallingPlatform

@export var shake_duration: float = 0.5
@export var respawn_delay: float = 2.5

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var step_area: Area2D = $StepArea

var original_pos: Vector2
var is_triggered: bool = false
var is_falling: bool = false
var fall_velocity: float = 0.0

func _ready() -> void:
	collision_layer = 2 # Terrain
	collision_mask = 1 # Player
	original_pos = position
	
	if animated_sprite:
		animated_sprite.play("on")
		
	step_area.body_entered.connect(_on_step_area_body_entered)

func _physics_process(delta: float) -> void:
	if is_falling:
		fall_velocity += 600.0 * delta
		position.y += fall_velocity * delta

func _on_step_area_body_entered(body: Node2D) -> void:
	if is_triggered or not (body is Player):
		return
		
	var player = body as Player
	if player.global_position.y <= global_position.y:
		is_triggered = true
		_start_shake_and_fall()

func _start_shake_and_fall() -> void:
	# Shake tween
	var tween = create_tween().set_loops(int(shake_duration / 0.06))
	tween.tween_property(animated_sprite, "position:x", -2.0, 0.03)
	tween.tween_property(animated_sprite, "position:x", 2.0, 0.03)
	
	await get_tree().create_timer(shake_duration).timeout
	animated_sprite.position.x = 0
	is_falling = true
	fall_velocity = 80.0
	collision_shape.set_deferred("disabled", true)
	step_area.set_deferred("monitoring", false)
	
	await get_tree().create_timer(respawn_delay).timeout
	_respawn()

func _respawn() -> void:
	is_falling = false
	is_triggered = false
	fall_velocity = 0.0
	position = original_pos
	modulate.a = 0.0
	collision_shape.set_deferred("disabled", false)
	step_area.set_deferred("monitoring", true)
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
