extends Area2D
class_name SlammerTrap

@export var is_rock_head: bool = false
@export var slam_distance: float = 128.0
@export var slam_direction: Vector2 = Vector2.DOWN
@export var slam_speed: float = 400.0
@export var return_speed: float = 60.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ray_cast: RayCast2D = $RayCast2D

var audio_manager: Node:
	get:
		if not is_inside_tree():
			return null
		return get_node_or_null("/root/AudioManager")

enum State { IDLE, SLAMMING, IMPACT, RETURNING }
var state: State = State.IDLE
var origin_pos: Vector2
var target_pos: Vector2
var state_timer: float = 0.0
var blink_timer: float = 2.0

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	
	origin_pos = position
	target_pos = origin_pos + slam_direction.normalized() * slam_distance
	
	ray_cast.target_position = slam_direction.normalized() * slam_distance
	ray_cast.collision_mask = 1 # Player
	
	if animated_sprite:
		var frames_path = "res://resources/rock_head_frames.tres" if is_rock_head else "res://resources/spike_head_frames.tres"
		if ResourceLoader.exists(frames_path):
			animated_sprite.sprite_frames = load(frames_path)
		animated_sprite.play("idle")

func _physics_process(delta: float) -> void:
	match state:
		State.IDLE:
			blink_timer -= delta
			if blink_timer <= 0:
				blink_timer = randf_range(2.5, 5.0)
				if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("blink"):
					animated_sprite.play("blink")
					await animated_sprite.animation_finished
					if state == State.IDLE and animated_sprite:
						animated_sprite.play("idle")
						
			if ray_cast.is_colliding():
				var collider = ray_cast.get_collider()
				if collider is Player:
					state = State.SLAMMING
					
		State.SLAMMING:
			position = position.move_toward(target_pos, slam_speed * delta)
			if position.distance_to(target_pos) < 2.0:
				state = State.IMPACT
				state_timer = 0.6
				if audio_manager:
					audio_manager.play_sfx("stomp", 1.1)
				_play_hit_anim()
				
		State.IMPACT:
			state_timer -= delta
			if state_timer <= 0:
				state = State.RETURNING
				if animated_sprite:
					animated_sprite.play("idle")
				
		State.RETURNING:
			position = position.move_toward(origin_pos, return_speed * delta)
			if position.distance_to(origin_pos) < 1.0:
				state = State.IDLE
				if animated_sprite:
					animated_sprite.play("idle")

func _play_hit_anim() -> void:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	var anim_name = "bottom_hit"
	if slam_direction == Vector2.UP:
		anim_name = "top_hit"
	elif slam_direction == Vector2.LEFT:
		anim_name = "left_hit"
	elif slam_direction == Vector2.RIGHT:
		anim_name = "right_hit"
	if animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var knock_dir = (body.global_position - global_position).normalized()
		(body as Player).take_damage(1, knock_dir)
