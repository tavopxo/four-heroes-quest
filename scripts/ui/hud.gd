extends CanvasLayer
class_name HUD

@onready var health_container: HBoxContainer = $MarginContainer/TopBar/HealthContainer
@onready var fruit_label: Label = $MarginContainer/TopBar/FruitContainer/FruitLabel
@onready var timer_label: Label = $MarginContainer/TopBar/TimerLabel
@onready var hero_label: Label = $MarginContainer/TopBar/HeroBadge/HeroLabel
@onready var pause_button: Button = $MarginContainer/TopBar/PauseButton
@onready var pause_menu: Control = $PauseMenu
@onready var game_over_menu: Control = $GameOverMenu
@onready var level_complete_menu: Control = $LevelCompleteMenu

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

var _connected_gm: Node = null

func _ready() -> void:
	_connected_gm = game_manager
	if _connected_gm:
		_connected_gm.health_changed.connect(_on_health_changed)
		_connected_gm.fruits_changed.connect(_on_fruits_changed)
		_connected_gm.level_completed.connect(_on_level_completed)
		_connected_gm.player_died.connect(_on_player_died)
		
		# Initialize values
		_on_health_changed(_connected_gm.current_health, _connected_gm.max_health)
		_on_fruits_changed(_connected_gm.fruits_collected, _connected_gm.total_fruits_in_level)
		
		var hero = _connected_gm.get_hero_data()
		if hero_label:
			hero_label.text = hero.get("name", "Hero")
			
	if pause_button:
		pause_button.pressed.connect(_on_pause_button_pressed)

func _exit_tree() -> void:
	if is_instance_valid(_connected_gm):
		if _connected_gm.health_changed.is_connected(_on_health_changed):
			_connected_gm.health_changed.disconnect(_on_health_changed)
		if _connected_gm.fruits_changed.is_connected(_on_fruits_changed):
			_connected_gm.fruits_changed.disconnect(_on_fruits_changed)
		if _connected_gm.level_completed.is_connected(_on_level_completed):
			_connected_gm.level_completed.disconnect(_on_level_completed)
		if _connected_gm.player_died.is_connected(_on_player_died):
			_connected_gm.player_died.disconnect(_on_player_died)
	_connected_gm = null

func _process(_delta: float) -> void:
	if game_manager and game_manager.is_level_active and not game_manager.is_game_over:
		var t = game_manager.level_time
		var mins = int(t / 60.0)
		var secs = int(fmod(t, 60.0))
		var ms = int(fmod(t * 100.0, 100.0))
		if timer_label:
			timer_label.text = "%02d:%02d.%02d" % [mins, secs, ms]

func _on_health_changed(current: int, max_hp: int) -> void:
	if not health_container or not is_inside_tree():
		return
	for c in health_container.get_children():
		c.queue_free()
	
	for i in range(max_hp):
		var heart = Label.new()
		heart.custom_minimum_size = Vector2(18, 18)
		heart.text = "♥"
		heart.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		heart.add_theme_font_size_override("font_size", 16)
		heart.modulate = Color(1.0, 0.25, 0.35) if i < current else Color(0.3, 0.3, 0.3, 0.4)
		health_container.add_child(heart)

func _on_fruits_changed(collected: int, total: int) -> void:
	if fruit_label and is_inside_tree():
		fruit_label.text = "%d / %d" % [collected, total]

func _on_level_completed(stats: Dictionary) -> void:
	if level_complete_menu and is_inside_tree():
		level_complete_menu.show_stats(stats)

func _on_player_died() -> void:
	if game_manager and game_manager.current_health <= 0:
		if game_over_menu and is_inside_tree():
			game_over_menu.show_menu()

func _on_pause_button_pressed() -> void:
	if audio_manager:
		audio_manager.play_sfx("click")
	if pause_menu and is_inside_tree():
		pause_menu.show_menu()
