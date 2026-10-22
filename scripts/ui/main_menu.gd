extends Control
class_name MainMenu

@onready var play_btn: Button = $VBoxContainer/ButtonsVBox/PlayBtn
@onready var endless_btn: Button = $VBoxContainer/ButtonsVBox/EndlessBtn
@onready var heroes_btn: Button = $VBoxContainer/ButtonsVBox/HeroesBtn
@onready var levels_btn: Button = $VBoxContainer/ButtonsVBox/LevelsBtn
@onready var settings_btn: Button = $VBoxContainer/ButtonsVBox/SettingsBtn
@onready var quit_btn: Button = $VBoxContainer/ButtonsVBox/QuitBtn
@onready var hero_preview: AnimatedSprite2D = $VBoxContainer/HeroPreviewContainer/HeroPreview
@onready var hero_name_lbl: Label = $VBoxContainer/HeroPreviewContainer/HeroNameLabel

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

func _ready() -> void:
	play_btn.pressed.connect(_on_play_pressed)
	if endless_btn:
		endless_btn.pressed.connect(_on_endless_pressed)
	heroes_btn.pressed.connect(_on_heroes_pressed)
	levels_btn.pressed.connect(_on_levels_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	
	_update_hero_preview()
	play_btn.grab_focus()

func _update_hero_preview() -> void:
	if not game_manager:
		return
	var hero = game_manager.get_hero_data()
	if hero_preview:
		var frames_path = hero.get("sprite_frames", "")
		if ResourceLoader.exists(frames_path):
			hero_preview.sprite_frames = load(frames_path)
			hero_preview.play("idle")
	if hero_name_lbl:
		hero_name_lbl.text = hero.get("name", "") + " - " + hero.get("title", "")

func _on_play_pressed() -> void:
	if audio_manager:
		audio_manager.play_sfx("click")
	if game_manager:
		game_manager.start_level(game_manager.current_level_index)

func _on_endless_pressed() -> void:
	if audio_manager:
		audio_manager.play_sfx("click")
	if game_manager:
		game_manager.start_endless_mode()

func _on_heroes_pressed() -> void:
	if audio_manager:
		audio_manager.play_sfx("click")
	get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")

func _on_levels_pressed() -> void:
	if audio_manager:
		audio_manager.play_sfx("click")
	get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")

func _on_settings_pressed() -> void:
	if audio_manager:
		audio_manager.play_sfx("click")
	get_tree().change_scene_to_file("res://scenes/ui/settings_menu.tscn")

func _on_quit_pressed() -> void:
	if audio_manager:
		audio_manager.play_sfx("click")
	get_tree().quit()
