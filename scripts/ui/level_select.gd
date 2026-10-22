extends Control
class_name LevelSelect

@onready var levels_grid: HBoxContainer = $VBoxContainer/LevelsGrid
@onready var back_btn: Button = $VBoxContainer/BottomBar/BackBtn

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
	back_btn.pressed.connect(_on_back_pressed)
	_build_levels_grid()

func _build_levels_grid() -> void:
	if not game_manager:
		return
		
	for c in levels_grid.get_children():
		c.queue_free()
		
	var level_names = [
		"1. Emerald Meadows",
		"2. Clockwork Foundry",
		"3. Sunken Caverns",
		"4. Apex Gauntlet"
	]
	
	for i in range(1, 5):
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(130, 180)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 8)
		card.add_child(vbox)
		
		# Level icon
		var icon_rect = TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(38, 34)
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var icon_path = "res://Menu/Levels/%02d.png" % i
		if ResourceLoader.exists(icon_path):
			icon_rect.texture = load(icon_path)
		vbox.add_child(icon_rect)
		
		# Title
		var title_lbl = Label.new()
		title_lbl.text = level_names[i - 1]
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		title_lbl.add_theme_font_size_override("font_size", 10)
		vbox.add_child(title_lbl)
		
		# Stars & Best Time Record
		var record = game_manager.level_records.get(str(i), {})
		var stars_count = record.get("stars", 0)
		var best_time = record.get("best_time", 0.0)
		
		var stars_lbl = Label.new()
		var star_str = ""
		for s in range(3):
			star_str += "★ " if s < stars_count else "☆ "
		stars_lbl.text = star_str.strip_edges()
		stars_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stars_lbl.modulate = Color(1.0, 0.85, 0.2)
		vbox.add_child(stars_lbl)
		
		var time_lbl = Label.new()
		time_lbl.text = "Best: %.2fs" % best_time if best_time > 0 else "Best: --"
		time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		time_lbl.add_theme_font_size_override("font_size", 8)
		vbox.add_child(time_lbl)
		
		# Play button / Locked
		var is_unlocked = (i <= game_manager.max_unlocked_level)
		var play_btn = Button.new()
		play_btn.text = "PLAY" if is_unlocked else "LOCKED"
		play_btn.disabled = not is_unlocked
		var lvl_idx = i
		play_btn.pressed.connect(func(): _on_level_selected(lvl_idx))
		vbox.add_child(play_btn)
		
		if not is_unlocked:
			card.modulate = Color(0.5, 0.5, 0.5, 0.8)
			
		levels_grid.add_child(card)
		
	# Endless Mode Card
	var e_card = PanelContainer.new()
	e_card.custom_minimum_size = Vector2(130, 180)
	e_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var e_vbox = VBoxContainer.new()
	e_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	e_vbox.add_theme_constant_override("separation", 8)
	e_card.add_child(e_vbox)
	
	var e_icon = TextureRect.new()
	e_icon.custom_minimum_size = Vector2(38, 34)
	e_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var e_icon_path = "res://Menu/Levels/05.png"
	if ResourceLoader.exists(e_icon_path):
		e_icon.texture = load(e_icon_path)
	e_vbox.add_child(e_icon)
	
	var e_title = Label.new()
	e_title.text = "∞ Endless Gauntlet"
	e_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	e_title.autowrap_mode = TextServer.AUTOWRAP_WORD
	e_title.add_theme_font_size_override("font_size", 10)
	e_vbox.add_child(e_title)
	
	var e_sub = Label.new()
	e_sub.text = "Procedural Run"
	e_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	e_sub.modulate = Color(0.4, 1.0, 0.6)
	e_sub.add_theme_font_size_override("font_size", 8)
	e_vbox.add_child(e_sub)
	
	var e_dist = Label.new()
	var best_d = game_manager.endless_best_distance if game_manager else 0
	e_dist.text = "Best: %d m" % best_d if best_d > 0 else "Best: --"
	e_dist.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	e_dist.add_theme_font_size_override("font_size", 8)
	e_vbox.add_child(e_dist)
	
	var e_btn = Button.new()
	e_btn.text = "RUN"
	e_btn.pressed.connect(_on_endless_selected)
	e_vbox.add_child(e_btn)
	
	levels_grid.add_child(e_card)

func _on_level_selected(idx: int) -> void:
	if audio_manager:
		audio_manager.play_sfx("click")
	if game_manager:
		game_manager.start_level(idx)

func _on_endless_selected() -> void:
	if audio_manager:
		audio_manager.play_sfx("click")
	if game_manager:
		game_manager.start_endless_mode()

func _on_back_pressed() -> void:
	if audio_manager:
		audio_manager.play_sfx("click")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
