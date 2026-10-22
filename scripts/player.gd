extends CharacterBody2D
class_name Player

@export var hero_id: String = ""

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var dust_particles: CPUParticles2D = $DustParticles
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_buffer_timer: Timer = $JumpBufferTimer
@onready var invulnerable_timer: Timer = $InvulnerableTimer
@onready var dash_timer: Timer = $DashTimer
@onready var dash_cooldown_timer: Timer = $DashCooldownTimer
@onready var weapon: Node2D = $Weapon

var game_manager: Node:
	get:
		if not is_inside_tree():
			return null
		return get_node_or_null("/root/GameManager")

var audio_manager: Node:
	get:
		if not is_inside_tree():
			return null
		return get_node_or_null("/root/AudioManager")

var hero_data: Dictionary = {}
var speed: float = 160.0
var jump_velocity: float = -350.0
var double_jump_velocity: float = -320.0
var wall_slide_speed: float = 60.0
var wall_jump_x: float = 200.0
var wall_jump_y: float = -340.0
var glide_gravity_mult: float = 1.0
var has_dash: bool = false
var dash_speed: float = 400.0
var has_ground_pound: bool = false
var trampoline_mult: float = 1.0

var gravity: float = 980.0
var can_double_jump: bool = false
var was_on_floor: bool = false
var is_wall_sliding: bool = false
var is_dashing: bool = false
var can_dash: bool = true
var is_ground_pounding: bool = false
var is_invulnerable: bool = false
var is_dead: bool = false
var facing_direction: int = 1 # 1: right, -1: left
var bullet_scene: PackedScene = preload("res://scenes/items/bullet.tscn")
var shoot_cooldown: float = 0.0
var speed_powerup_timer: float = 0.0
var star_powerup_timer: float = 0.0
var base_speed: float = 160.0

func _ready() -> void:
	if hero_id == "" and game_manager:
		hero_id = game_manager.selected_hero_id
	load_hero_stats(hero_id)
	
	if game_manager:
		game_manager.player_died.connect(_on_player_died)
	invulnerable_timer.timeout.connect(_on_invulnerable_timeout)
	dash_timer.timeout.connect(_on_dash_ended)
	dash_cooldown_timer.timeout.connect(_on_dash_cooldown_timeout)
	
	play_spawn_animation()

func load_hero_stats(id: String) -> void:
	if game_manager:
		hero_data = game_manager.get_hero_data(id)
	else:
		hero_data = {
			"speed": 175.0, "jump_velocity": -360.0, "double_jump_velocity": -330.0,
			"wall_slide_speed": 40.0, "wall_jump_x": 240.0, "wall_jump_y": -360.0,
			"glide_gravity_mult": 1.0, "has_dash": false, "dash_speed": 400.0,
			"has_ground_pound": false, "trampoline_mult": 1.0,
			"sprite_frames": "res://resources/ninja_frog_frames.tres"
		}
	speed = hero_data.get("speed", 160.0)
	base_speed = speed
	jump_velocity = hero_data.get("jump_velocity", -350.0)
	double_jump_velocity = hero_data.get("double_jump_velocity", -320.0)
	wall_slide_speed = hero_data.get("wall_slide_speed", 60.0)
	wall_jump_x = hero_data.get("wall_jump_x", 200.0)
	wall_jump_y = hero_data.get("wall_jump_y", -340.0)
	glide_gravity_mult = hero_data.get("glide_gravity_mult", 1.0)
	has_dash = hero_data.get("has_dash", false)
	dash_speed = hero_data.get("dash_speed", 400.0)
	has_ground_pound = hero_data.get("has_ground_pound", false)
	trampoline_mult = hero_data.get("trampoline_mult", 1.0)
	
	var frames_path = hero_data.get("sprite_frames", "")
	if ResourceLoader.exists(frames_path):
		animated_sprite.sprite_frames = load(frames_path)

func play_spawn_animation() -> void:
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("appearing"):
		animated_sprite.play("appearing")
		await animated_sprite.animation_finished
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	shoot_cooldown = maxf(0.0, shoot_cooldown - delta)
	speed_powerup_timer = maxf(0.0, speed_powerup_timer - delta)
	star_powerup_timer = maxf(0.0, star_powerup_timer - delta)
	speed = base_speed * (1.45 if speed_powerup_timer > 0.0 else 1.0)
		
	var on_floor = is_on_floor()
	var on_wall = is_on_wall() and not on_floor
	
	# Ground pound impact check
	if is_ground_pounding and on_floor:
		is_ground_pounding = false
		dust_particles.restart()
		if audio_manager:
			audio_manager.play_sfx("stomp", 1.2)
		
	# Dashing logic
	if is_dashing:
		velocity.y = 0
		move_and_slide()
		return
		
	# Coyote time logic
	if on_floor:
		can_double_jump = true
		coyote_timer.stop()
		was_on_floor = true
	else:
		if was_on_floor and not is_wall_sliding and velocity.y >= 0:
			coyote_timer.start(0.12)
		was_on_floor = false
			
	# Jump input buffering
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer.start(0.12)
		
	# Wall sliding logic
	var wall_normal = get_wall_normal()
	var input_x = Input.get_axis("move_left", "move_right")
	
	is_wall_sliding = false
	if on_wall and velocity.y > 0:
		if (wall_normal.x < 0 and input_x > 0) or (wall_normal.x > 0 and input_x < 0):
			is_wall_sliding = true
			velocity.y = min(velocity.y, wall_slide_speed)
			can_double_jump = true
			was_on_floor = false
			coyote_timer.stop()
			
	# Apply Gravity
	if not on_floor:
		var current_grav = gravity
		if velocity.y < 0 and not Input.is_action_pressed("jump"):
			current_grav *= 2.2
		elif velocity.y > 0 and Input.is_action_pressed("jump") and glide_gravity_mult < 1.0:
			current_grav *= glide_gravity_mult
			
		if is_ground_pounding:
			current_grav *= 2.5
			
		velocity.y += current_grav * delta
		velocity.y = min(velocity.y, 650.0)
		
	# Ground Pound input
	if has_ground_pound and not on_floor and Input.is_action_just_pressed("move_down") and not is_ground_pounding:
		is_ground_pounding = true
		velocity.y = 520.0
		if audio_manager:
			audio_manager.play_sfx("stomp", 0.9)
		
	# Cyber Dash input
	if has_dash and can_dash and Input.is_action_just_pressed("special_action"):
		perform_dash()
		return
		
	# Handle Jump
	if not jump_buffer_timer.is_stopped():
		if on_floor or not coyote_timer.is_stopped():
			perform_jump()
			jump_buffer_timer.stop()
			coyote_timer.stop()
		elif is_wall_sliding:
			perform_wall_jump(wall_normal)
			jump_buffer_timer.stop()
		elif can_double_jump:
			perform_double_jump()
			jump_buffer_timer.stop()
			
	# Horizontal movement
	if input_x != 0:
		facing_direction = 1 if input_x > 0 else -1
		animated_sprite.flip_h = (facing_direction == -1)
		var accel = 1400.0 if on_floor else 900.0
		velocity.x = move_toward(velocity.x, input_x * speed, accel * delta)
	else:
		var friction = 1200.0 if on_floor else 500.0
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		
	move_and_slide()
	update_animation(on_floor, input_x)

func perform_jump() -> void:
	velocity.y = jump_velocity
	was_on_floor = false
	coyote_timer.stop()
	dust_particles.restart()
	if audio_manager:
		audio_manager.play_sfx("jump", randf_range(0.95, 1.05))

func perform_wall_jump(wall_norm: Vector2) -> void:
	velocity.x = wall_norm.x * wall_jump_x
	velocity.y = wall_jump_y
	facing_direction = 1 if wall_norm.x > 0 else -1
	animated_sprite.flip_h = (facing_direction == -1)
	was_on_floor = false
	coyote_timer.stop()
	can_double_jump = true
	dust_particles.restart()
	if audio_manager:
		audio_manager.play_sfx("jump", 1.15)

func perform_double_jump() -> void:
	can_double_jump = false
	was_on_floor = false
	coyote_timer.stop()
	velocity.y = double_jump_velocity
	dust_particles.restart()
	animated_sprite.play("double_jump")
	if audio_manager:
		audio_manager.play_sfx("double_jump", randf_range(0.95, 1.05))

func perform_dash() -> void:
	is_dashing = true
	can_dash = false
	dash_timer.start(0.18)
	dash_cooldown_timer.start(0.75)
	var dash_dir = facing_direction
	var input_x = Input.get_axis("move_left", "move_right")
	if input_x != 0:
		dash_dir = 1 if input_x > 0 else -1
	velocity = Vector2(dash_dir * dash_speed, 0)
	dust_particles.restart()
	if audio_manager:
		audio_manager.play_sfx("dash", 1.0)

func _on_dash_ended() -> void:
	is_dashing = false
	velocity.x = facing_direction * speed

func _on_dash_cooldown_timeout() -> void:
	can_dash = true

func bounce(launch_force: float) -> void:
	var final_force = launch_force * trampoline_mult
	velocity.y = -final_force
	can_double_jump = true
	was_on_floor = false
	coyote_timer.stop()
	is_ground_pounding = false

func take_damage(amount: int = 1, knockback_dir: Vector2 = Vector2.ZERO, bypass_invulnerability: bool = false) -> void:
	if star_powerup_timer > 0.0 or (is_invulnerable and not bypass_invulnerability) or is_dead:
		return
		
	var died = false
	if game_manager:
		died = game_manager.damage_player(amount)
	if died:
		return
		
	is_invulnerable = true
	invulnerable_timer.start(1.5)
	
	if knockback_dir != Vector2.ZERO:
		velocity = knockback_dir * 220.0 + Vector2(0, -180.0)
	else:
		velocity = Vector2(-facing_direction * 160.0, -200.0)
		
	animated_sprite.play("hit")
	_flash_invulnerability()

func fire_bullet(direction: Vector2, origin: Vector2) -> void:
	if shoot_cooldown > 0.0 or is_dead:
		return
	shoot_cooldown = 0.18
	var bullet = bullet_scene.instantiate()
	bullet.global_position = origin + direction * 14.0
	bullet.direction = direction
	get_tree().current_scene.add_child(bullet)
	if audio_manager:
		audio_manager.play_sfx("pistol")

func apply_powerup(powerup_type: String) -> void:
	match powerup_type:
		"health":
			if game_manager:
				game_manager.heal_player(1)
		"speed":
			speed_powerup_timer = 8.0
		"star":
			star_powerup_timer = 8.0
			is_invulnerable = true
	if audio_manager:
		audio_manager.play_sfx("powerup")

func _flash_invulnerability() -> void:
	var tween = create_tween().set_loops(6)
	tween.tween_property(animated_sprite, "modulate:a", 0.25, 0.12)
	tween.tween_property(animated_sprite, "modulate:a", 1.0, 0.12)

func _on_invulnerable_timeout() -> void:
	is_invulnerable = false
	animated_sprite.modulate.a = 1.0

func _on_player_died() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	if animated_sprite.sprite_frames.has_animation("desappearing"):
		animated_sprite.play("desappearing")

	if game_manager and game_manager.is_endless_mode:
		return
	
	await get_tree().create_timer(0.6).timeout
	var respawn_pt = Vector2.ZERO
	if game_manager:
		respawn_pt = game_manager.respawn_player()
	global_position = respawn_pt
	is_dead = false
	is_invulnerable = true
	invulnerable_timer.start(1.5)
	_flash_invulnerability()
	play_spawn_animation()

func update_animation(on_floor: bool, input_x: float) -> void:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	if animated_sprite.animation == "hit" and animated_sprite.is_playing():
		return
	if animated_sprite.animation == "double_jump" and animated_sprite.is_playing() and not on_floor:
		return
	if animated_sprite.animation == "appearing" and animated_sprite.is_playing():
		return
		
	if is_wall_sliding:
		if animated_sprite.animation != "wall_jump" and animated_sprite.sprite_frames.has_animation("wall_jump"):
			animated_sprite.play("wall_jump")
		return
		
	if on_floor:
		if abs(velocity.x) > 10.0:
			if animated_sprite.animation != "run" and animated_sprite.sprite_frames.has_animation("run"):
				animated_sprite.play("run")
		else:
			if animated_sprite.animation != "idle" and animated_sprite.sprite_frames.has_animation("idle"):
				animated_sprite.play("idle")
	else:
		if velocity.y < 0:
			if animated_sprite.animation != "jump" and animated_sprite.sprite_frames.has_animation("jump"):
				animated_sprite.play("jump")
		else:
			if animated_sprite.animation != "fall" and animated_sprite.sprite_frames.has_animation("fall"):
				animated_sprite.play("fall")
