extends Control
class_name SettingsMenu

@onready var sfx_slider: HSlider = $VBoxContainer/AudioPanel/VBoxContainer/SFXRow/SFXSlider
@onready var music_slider: HSlider = $VBoxContainer/AudioPanel/VBoxContainer/MusicRow/MusicSlider
@onready var back_btn: Button = $VBoxContainer/BottomBar/BackBtn

var audio_manager: Node:
	get:
		return get_node_or_null("/root/AudioManager")

func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	
	if audio_manager:
		sfx_slider.value = audio_manager.sfx_volume * 100.0
		music_slider.value = audio_manager.music_volume * 100.0
		
	sfx_slider.value_changed.connect(_on_sfx_changed)
	music_slider.value_changed.connect(_on_music_changed)

func _on_sfx_changed(val: float) -> void:
	if audio_manager:
		audio_manager.set_sfx_volume(val / 100.0)

func _on_music_changed(val: float) -> void:
	if audio_manager:
		audio_manager.set_music_volume(val / 100.0)

func _on_back_pressed() -> void:
	if audio_manager:
		audio_manager.play_sfx("click")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
