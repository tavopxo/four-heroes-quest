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
		
	if abyss_zone:
		abyss_zone.body_entered.connect(_on_abyss_zone_entered)
		
	# Ensure camera follows player
	if camera and player:
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 8.0

func _physics_process(_delta: float) -> void:
	if camera and player and is_instance_valid(player):
		camera.global_position = player.global_position

func _on_abyss_zone_entered(body: Node2D) -> void:
	if body is Player:
		(body as Player).take_damage(99) # instant death in abyss
