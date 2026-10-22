extends Control
class_name PauseMenu

@onready var resume_btn: Button = $PanelContainer/VBoxContainer/ResumeBtn
@onready var restart_btn: Button = $PanelContainer/VBoxContainer/RestartBtn
@onready var select_hero_btn: Button = $PanelContainer/VBoxContainer/SelectHeroBtn
@onready var level_select_btn: Button = $PanelContainer/VBoxContainer/LevelSelectBtn
@onready var main_menu_btn: Button = $PanelContainer/VBoxContainer/MainMenuBtn

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
	
	if resume_btn:
		resume_btn.pressed.connect(_on_resume_pressed)
	if restart_btn:
		restart_btn.pressed.connect(_on_restart_pressed)
	if select_hero_btn:
		select_hero_btn.pressed.connect(_on_select_hero_pressed)
	if level_select_btn:
		level_select_btn.pressed.connect(_on_level_select_pressed)
	if main_menu_btn:
		main_menu_btn.pressed.connect(_on_main_menu_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo():
		if visible:
			hide_menu()
		else:
			show_menu()
		get_viewport().set_input_as_handled()

func show_menu() -> void:
	_is_transitioning = false
	visible = true
	get_tree().paused = true
	if resume_btn:
		resume_btn.grab_focus()

func hide_menu() -> void:
	visible = false
	get_tree().paused = false

func _on_resume_pressed() -> void:
	if audio_manager:
		audio_manager.play_sfx("click")
	hide_menu()

func _on_restart_pressed() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	if audio_manager:
		audio_manager.play_sfx("click")
	hide_menu()
	if game_manager:
		game_manager.start_level(game_manager.current_level_index)

func _on_select_hero_pressed() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	if audio_manager:
		audio_manager.play_sfx("click")
	hide_menu()
	get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")

func _on_level_select_pressed() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	if audio_manager:
		audio_manager.play_sfx("click")
	hide_menu()
	get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")

func _on_main_menu_pressed() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	if audio_manager:
		audio_manager.play_sfx("click")
	hide_menu()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
