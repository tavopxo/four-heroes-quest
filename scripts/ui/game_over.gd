extends Control
class_name GameOverMenu

@onready var retry_btn: Button = $PanelContainer/VBoxContainer/RetryBtn
@onready var level_select_btn: Button = $PanelContainer/VBoxContainer/LevelSelectBtn
@onready var menu_btn: Button = $PanelContainer/VBoxContainer/MenuBtn

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

var _is_transitioning: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	if retry_btn:
		retry_btn.pressed.connect(_on_retry_pressed)
	if level_select_btn:
		level_select_btn.pressed.connect(_on_level_select_pressed)
	if menu_btn:
		menu_btn.pressed.connect(_on_menu_pressed)

func show_menu() -> void:
	_is_transitioning = false
	visible = true
	get_tree().paused = true
	if retry_btn:
		retry_btn.grab_focus()

func _on_retry_pressed() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	if audio_manager:
		audio_manager.play_sfx("click")
	visible = false
	get_tree().paused = false
	if game_manager:
		game_manager.start_level(game_manager.current_level_index)

func _on_level_select_pressed() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	if audio_manager:
		audio_manager.play_sfx("click")
	visible = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")

func _on_menu_pressed() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	if audio_manager:
		audio_manager.play_sfx("click")
	visible = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
