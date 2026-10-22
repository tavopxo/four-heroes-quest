extends Control
class_name CharacterSelect

@onready var hero_cards_container: HBoxContainer = $VBoxContainer/HeroCardsContainer
@onready var back_btn: Button = $VBoxContainer/BottomBar/BackBtn
@onready var play_btn: Button = $VBoxContainer/BottomBar/PlayBtn

var game_manager: Node:
	get:
		return get_node_or_null("/root/GameManager")

var audio_manager: Node:
	get:
		return get_node_or_null("/root/AudioManager")

var select_buttons: Dictionary = {}

func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	play_btn.pressed.connect(_on_play_pressed)
	_build_hero_cards()
	_update_selection_visuals()

func _build_hero_cards() -> void:
	if not game_manager:
		return
		
	for c in hero_cards_container.get_children():
		c.queue_free()
		
	var hero_keys = ["ninja_frog", "pink_man", "virtual_guy", "mask_dude"]
	for h_id in hero_keys:
		var data = game_manager.get_hero_data(h_id)
		
		var card = PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size = Vector2(130, 220)
		
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 6)
		card.add_child(vbox)
		
		# Name Label
		var name_lbl = Label.new()
		name_lbl.text = data.get("name", "")
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 14)
		vbox.add_child(name_lbl)
		
		# Subtitle / Perk
		var title_lbl = Label.new()
		title_lbl.text = data.get("title", "")
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		title_lbl.add_theme_font_size_override("font_size", 9)
		title_lbl.modulate = Color(0.8, 0.8, 0.5)
		vbox.add_child(title_lbl)
		
		# Animated Sprite Preview Container
		var spr_container = Control.new()
		spr_container.custom_minimum_size = Vector2(64, 48)
		var anim = AnimatedSprite2D.new()
		var frames_path = data.get("sprite_frames", "")
		if ResourceLoader.exists(frames_path):
			anim.sprite_frames = load(frames_path)
			anim.animation = "idle"
			anim.play()
		anim.position = Vector2(65, 24)
		anim.scale = Vector2(1.5, 1.5)
		spr_container.add_child(anim)
		vbox.add_child(spr_container)
		
		# Description / Stat summary
		var desc_lbl = Label.new()
		desc_lbl.text = data.get("desc", "")
		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_lbl.add_theme_font_size_override("font_size", 8)
		desc_lbl.custom_minimum_size = Vector2(110, 40)
		vbox.add_child(desc_lbl)
		
		# Select Button
		var sel_btn = Button.new()
		sel_btn.text = "SELECT"
		sel_btn.pressed.connect(func(): _on_hero_selected(h_id))
		vbox.add_child(sel_btn)
		
		select_buttons[h_id] = { "button": sel_btn, "card": card }
		hero_cards_container.add_child(card)

func _on_hero_selected(hero_id: String) -> void:
	if audio_manager:
		audio_manager.play_sfx("click")
	if game_manager:
		game_manager.select_hero(hero_id)
	_update_selection_visuals()

func _update_selection_visuals() -> void:
	if not game_manager:
		return
	var cur = game_manager.selected_hero_id
	for h_id in select_buttons:
		var btn = select_buttons[h_id]["button"] as Button
		var card = select_buttons[h_id]["card"] as PanelContainer
		if h_id == cur:
			btn.text = "ACTIVE"
			btn.disabled = true
			card.modulate = Color(1.1, 1.1, 0.9)
		else:
			btn.text = "SELECT"
			btn.disabled = false
			card.modulate = Color(0.85, 0.85, 0.85)

func _on_back_pressed() -> void:
	if audio_manager:
		audio_manager.play_sfx("click")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_play_pressed() -> void:
	if audio_manager:
		audio_manager.play_sfx("click")
	if game_manager:
		game_manager.start_level(game_manager.current_level_index)
