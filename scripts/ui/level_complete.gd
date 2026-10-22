extends Control
class_name LevelCompleteMenu

@onready var title_label: Label = $PanelContainer/VBoxContainer/TitleLabel
@onready var time_label: Label = $PanelContainer/VBoxContainer/StatsGrid/TimeLabel
@onready var fruits_label: Label = $PanelContainer/VBoxContainer/StatsGrid/FruitsLabel
@onready var stars_label: Label = $PanelContainer/VBoxContainer/StarsLabel
@onready var next_btn: Button = $PanelContainer/VBoxContainer/ButtonsHBox/NextBtn
@onready var retry_btn: Button = $PanelContainer/VBoxContainer/ButtonsHBox/RetryBtn
@onready var menu_btn: Button = $PanelContainer/VBoxContainer/ButtonsHBox/MenuBtn

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
	
	if next_btn:
		next_btn.pressed.connect(_on_next_pressed)
	if retry_btn:
		retry_btn.pressed.connect(_on_retry_pressed)
	if menu_btn:
		menu_btn.pressed.connect(_on_menu_pressed)

func show_stats(stats: Dictionary) -> void:
	_is_transitioning = false
	_enable_buttons()
	
	visible = true
	get_tree().paused = true
	
	var time_val = stats.get("time", 0.0)
	var par_val = stats.get("par_time", 45.0)
	var fruits_val = stats.get("fruits", 0)
	var total_fruits_val = stats.get("total_fruits", 0)
	var stars_count = stats.get("stars", 1)
	
	if time_label:
		time_label.text = "%.2fs (Par: %.0fs)" % [time_val, par_val]
	if fruits_label:
		fruits_label.text = "%d / %d" % [fruits_val, total_fruits_val]
	
	var star_str = ""
	for i in range(3):
		if i < stars_count:
			star_str += "★ "
		else:
			star_str += "☆ "
	if stars_label:
		stars_label.text = star_str.strip_edges()
	
	if next_btn:
		next_btn.grab_focus()

func _disable_buttons() -> void:
	if next_btn:
		next_btn.disabled = true
	if retry_btn:
		retry_btn.disabled = true
	if menu_btn:
		menu_btn.disabled = true

func _enable_buttons() -> void:
	if next_btn:
		next_btn.disabled = false
	if retry_btn:
		retry_btn.disabled = false
	if menu_btn:
		menu_btn.disabled = false

func _on_next_pressed() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_disable_buttons()
	
	if audio_manager:
		audio_manager.play_sfx("click")
	get_tree().paused = false
	if game_manager:
		var nxt = game_manager.current_level_index + 1
		if nxt <= 4:
			game_manager.start_level(nxt)
		else:
			get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")

func _on_retry_pressed() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_disable_buttons()
	
	if audio_manager:
		audio_manager.play_sfx("click")
	get_tree().paused = false
	if game_manager:
		game_manager.start_level(game_manager.current_level_index)

func _on_menu_pressed() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_disable_buttons()
	
	if audio_manager:
		audio_manager.play_sfx("click")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")
