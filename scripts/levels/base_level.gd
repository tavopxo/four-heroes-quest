extends Node2D
class_name BaseLevel

@export var level_index: int = 1
@export var level_title: String = "Emerald Meadows"
@export var bg_texture: Texture2D

@onready var player: Player = $Player
@onready var camera: Camera2D = $Camera2D
@onready var hud: CanvasLayer = $HUD
@onready var abyss_zone: Area2D = $AbyssZone

var game_manager: Node:
	get:
		if not is_inside_tree():
			return null
		return get_node_or_null("/root/GameManager")

func _ready() -> void:
	if game_manager:
		game_manager.current_level_index = level_index
		game_manager.is_level_active = true
		game_manager.is_game_over = false
		game_manager.fruits_collected = 0
		game_manager.level_time = 0.0
		if game_manager.audio_manager:
			game_manager.audio_manager.play_level_music(level_index)
		
	if abyss_zone:
		abyss_zone.body_entered.connect(_on_abyss_zone_entered)
		
	# Ensure camera follows player
	if camera and player:
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 8.0
	_trim_collectibles_for_grounded_layout()
	_spawn_level_content()

func _trim_collectibles_for_grounded_layout() -> void:
	if not game_manager:
		return
	for child in get_children():
		if child is Fruit and child.global_position.y <= 110.0:
			child.queue_free()
			game_manager.total_fruits_in_level = maxi(0, game_manager.total_fruits_in_level - 1)

func _spawn_level_content() -> void:
	var enemy_scene = preload("res://scenes/characters/enemy.tscn")
	var powerup_scene = preload("res://scenes/items/powerup.tscn")
	var offsets = [Vector2(260, 0), Vector2(520, -48), Vector2(820, 0)]
	for offset in offsets:
		var enemy = enemy_scene.instantiate()
		enemy.position = player.position + offset
		add_child(enemy)
	for i in range(2):
		var powerup = powerup_scene.instantiate()
		powerup.powerup_type = "speed" if i == 0 else "star"
		powerup.position = player.position + Vector2(380 + i * 360, -64)
		add_child(powerup)

func _physics_process(_delta: float) -> void:
	if camera and player and is_instance_valid(player):
		camera.global_position = player.global_position

func _on_abyss_zone_entered(body: Node2D) -> void:
	if body is Player:
		(body as Player).take_damage(99) # instant death in abyss
