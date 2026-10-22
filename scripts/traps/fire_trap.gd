extends Area2D
class_name FireTrap

@export var off_time: float = 2.0
@export var on_time: float = 1.8
@export var start_active: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

enum State { OFF, WARNING, ON }
var current_state: State = State.OFF
var state_timer: float = 0.0

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	
	if start_active:
		set_state(State.ON)
	else:
		set_state(State.OFF)

func _physics_process(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0:
		match current_state:
			State.OFF:
				set_state(State.WARNING)
			State.WARNING:
				set_state(State.ON)
			State.ON:
				set_state(State.OFF)

func set_state(new_state: State) -> void:
	current_state = new_state
	match current_state:
		State.OFF:
			state_timer = off_time
			collision_shape.set_deferred("disabled", true)
			if animated_sprite:
				animated_sprite.play("off")
		State.WARNING:
			state_timer = 0.6
			collision_shape.set_deferred("disabled", true)
			if animated_sprite:
				animated_sprite.play("hit")
		State.ON:
			state_timer = on_time
			collision_shape.set_deferred("disabled", false)
			if animated_sprite:
				animated_sprite.play("on")
			# Check overlapping players immediately
			for body in get_overlapping_bodies():
				_on_body_entered(body)

func _on_body_entered(body: Node2D) -> void:
	if current_state == State.ON and body is Player:
		var knock_dir = (body.global_position - global_position).normalized()
		(body as Player).take_damage(1, knock_dir)
