extends Node2D
class_name SpikedBallPendulum

@export var chain_length: int = 4
@export var swing_speed: float = 2.2
@export var max_angle_deg: float = 65.0

@onready var pivot: Node2D = $Pivot
@onready var hit_area: Area2D = $Pivot/HitArea

var time: float = 0.0

func _ready() -> void:
	hit_area.collision_layer = 4
	hit_area.collision_mask = 1
	hit_area.body_entered.connect(_on_body_entered)
	
	# Position hit area based on chain length (each link is 8px)
	var ball_y = chain_length * 8 + 8
	hit_area.position = Vector2(0, ball_y)
	queue_redraw()

func _physics_process(delta: float) -> void:
	time += delta * swing_speed
	var angle_rad = deg_to_rad(sin(time) * max_angle_deg)
	pivot.rotation = angle_rad

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var knock_dir = (body.global_position - hit_area.global_position).normalized()
		(body as Player).take_damage(1, knock_dir)
