extends Node

var audio_manager: Node:
	get:
		if not is_inside_tree():
			return null
		return get_node_or_null("/root/AudioManager")

signal health_changed(current: int, max_hp: int)
signal fruits_changed(collected: int, total: int)
signal checkpoint_reached(pos: Vector2)
signal player_died
signal player_respawned
signal level_completed(stats: Dictionary)

const SAVE_FILE_PATH = "user://game_save.json"

var heroes_data: Dictionary = {
	"ninja_frog": {
		"id": "ninja_frog",
		"name": "Ninja Frog",
		"title": "The Shinobi Acrobat",
		"desc": "High mobility & sprint. Clings to walls and performs high, angled wall jumps.",
		"speed": 175.0,
		"jump_velocity": -360.0,
		"double_jump_velocity": -330.0,
		"max_health": 3,
		"wall_slide_speed": 40.0,
		"wall_jump_x": 240.0,
		"wall_jump_y": -360.0,
		"has_dash": false,
		"has_ground_pound": false,
		"glide_gravity_mult": 1.0,
		"trampoline_mult": 1.0,
		"sprite_frames": "res://resources/ninja_frog_frames.tres"
	},
	"pink_man": {
		"id": "pink_man",
		"name": "Pink Man",
		"title": "The Featherweight",
		"desc": "Floaty double jump and gliding descent when holding Jump. Soars past wide hazard chasms.",
		"speed": 160.0,
		"jump_velocity": -370.0,
		"double_jump_velocity": -380.0,
		"max_health": 3,
		"wall_slide_speed": 70.0,
		"wall_jump_x": 190.0,
		"wall_jump_y": -340.0,
		"has_dash": false,
		"has_ground_pound": false,
		"glide_gravity_mult": 0.45,
		"trampoline_mult": 1.1,
		"sprite_frames": "res://resources/pink_man_frames.tres"
	},
	"virtual_guy": {
		"id": "virtual_guy",
		"name": "Virtual Guy",
		"title": "The Cyber Sprinter",
		"desc": "Press Special (Shift / K) to execute Cyber Dash through gaps and across timed hazards.",
		"speed": 160.0,
		"jump_velocity": -350.0,
		"double_jump_velocity": -320.0,
		"max_health": 3,
		"wall_slide_speed": 65.0,
		"wall_jump_x": 190.0,
		"wall_jump_y": -340.0,
		"has_dash": true,
		"dash_speed": 420.0,
		"dash_duration": 0.18,
		"dash_cooldown": 0.75,
		"has_ground_pound": false,
		"glide_gravity_mult": 1.0,
		"trampoline_mult": 1.0,
		"sprite_frames": "res://resources/virtual_guy_frames.tres"
	},
	"mask_dude": {
		"id": "mask_dude",
		"name": "Mask Dude",
		"title": "The Heavyweight",
		"desc": "Sturdy constitution (4 Hearts). In air, press Down to Ground Pound crates and launch skyward on trampolines.",
		"speed": 150.0,
		"jump_velocity": -340.0,
		"double_jump_velocity": -300.0,
		"max_health": 4,
		"wall_slide_speed": 80.0,
		"wall_jump_x": 180.0,
		"wall_jump_y": -330.0,
		"has_dash": false,
		"has_ground_pound": true,
		"glide_gravity_mult": 1.0,
		"trampoline_mult": 1.4,
		"sprite_frames": "res://resources/mask_dude_frames.tres"
	}
}

var selected_hero_id: String = "ninja_frog"
var current_level_index: int = 1
var max_unlocked_level: int = 1

var current_health: int = 3
var max_health: int = 3
var fruits_collected: int = 0
var total_fruits_in_level: int = 0
var level_time: float = 0.0
var is_level_active: bool = false
var is_game_over: bool = false

var checkpoint_position: Vector2 = Vector2.ZERO
var has_checkpoint: bool = false
var start_position: Vector2 = Vector2.ZERO

var is_endless_mode: bool = false
var endless_distance: int = 0
var endless_best_distance: int = 0
var endless_best_fruits: int = 0

var level_records: Dictionary = {}

func _enter_tree() -> void:
	_setup_input_actions()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_progress()
	apply_selected_hero()

func _process(delta: float) -> void:
	if is_level_active and not is_game_over:
		level_time += delta

func _setup_input_actions() -> void:
	var actions = {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"jump": [KEY_SPACE, KEY_W, KEY_UP],
		"special_action": [KEY_SHIFT, KEY_K, KEY_J],
		"pause": [KEY_ESCAPE, KEY_P],
		"restart": [KEY_R]
	}
	for action_name in actions:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		for key in actions[action_name]:
			var ev = InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action_name, ev)

func get_hero_data(hero_id: String = "") -> Dictionary:
	var id = hero_id if hero_id != "" else selected_hero_id
	if heroes_data.has(id):
		return heroes_data[id]
	return heroes_data["ninja_frog"]

func select_hero(hero_id: String) -> void:
	if heroes_data.has(hero_id):
		selected_hero_id = hero_id
		apply_selected_hero()

func apply_selected_hero() -> void:
	var data = get_hero_data()
	max_health = data.get("max_health", 3)
	current_health = max_health
	health_changed.emit(current_health, max_health)

func start_level(level_idx: int) -> void:
	is_endless_mode = false
	current_level_index = level_idx
	fruits_collected = 0
	total_fruits_in_level = 0
	level_time = 0.0
	is_level_active = true
	is_game_over = false
	has_checkpoint = false
	apply_selected_hero()
	
	var scene_path = "res://scenes/levels/level_" + str(level_idx) + ".tscn"
	if ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
	else:
		push_error("Level scene does not exist: " + scene_path)

func start_endless_mode() -> void:
	is_endless_mode = true
	current_level_index = 5
	fruits_collected = 0
	total_fruits_in_level = 0
	level_time = 0.0
	endless_distance = 0
	is_level_active = true
	is_game_over = false
	has_checkpoint = false
	apply_selected_hero()
	
	var scene_path = "res://scenes/levels/level_endless.tscn"
	if ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
	else:
		push_error("Endless level scene does not exist: " + scene_path)

func update_endless_records(distance: int, fruits: int) -> bool:
	var is_new_best = false
	if distance > endless_best_distance:
		endless_best_distance = distance
		is_new_best = true
	if fruits > endless_best_fruits:
		endless_best_fruits = fruits
	save_progress()
	return is_new_best

func set_checkpoint(pos: Vector2) -> void:
	checkpoint_position = pos
	has_checkpoint = true
	if audio_manager:
		audio_manager.play_sfx("checkpoint", 1.0)
	checkpoint_reached.emit(pos)

func damage_player(amount: int = 1) -> bool:
	if is_game_over:
		return false
	current_health = max(0, current_health - amount)
	if audio_manager:
		audio_manager.play_sfx("hurt", randf_range(0.9, 1.1))
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		is_game_over = true
		player_died.emit()
		return true
	return false

func heal_player(amount: int = 1) -> void:
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)

func collect_fruit() -> void:
	fruits_collected += 1
	var pitch = 1.0 + minf(0.8, fruits_collected * 0.03)
	if audio_manager:
		audio_manager.play_sfx("fruit", pitch)
	fruits_changed.emit(fruits_collected, total_fruits_in_level)

func respawn_player() -> Vector2:
	is_game_over = false
	current_health = max_health
	health_changed.emit(current_health, max_health)
	player_respawned.emit()
	if has_checkpoint:
		return checkpoint_position
	return start_position

func complete_level() -> Dictionary:
	is_level_active = false
	if audio_manager:
		audio_manager.play_sfx("win")
	
	var par_times = { 1: 30.0, 2: 45.0, 3: 60.0, 4: 75.0 }
	var par_time = par_times.get(current_level_index, 45.0)
	
	var stars = 1 # Completed
	if fruits_collected >= total_fruits_in_level and total_fruits_in_level > 0:
		stars += 1 # All fruits
	if level_time <= par_time:
		stars += 1 # Beat par time
		
	var stats = {
		"level": current_level_index,
		"time": level_time,
		"par_time": par_time,
		"fruits": fruits_collected,
		"total_fruits": total_fruits_in_level,
		"stars": stars
	}
	
	# Update record
	var key = str(current_level_index)
	var prev_record = level_records.get(key, {})
	var prev_stars = prev_record.get("stars", 0)
	var prev_time = prev_record.get("best_time", 99999.0)
	
	level_records[key] = {
		"completed": true,
		"stars": max(stars, prev_stars),
		"best_time": min(level_time, prev_time),
		"fruits": max(fruits_collected, prev_record.get("fruits", 0)),
		"total_fruits": total_fruits_in_level
	}
	
	if current_level_index >= max_unlocked_level and max_unlocked_level < 4:
		max_unlocked_level = current_level_index + 1
		
	save_progress()
	level_completed.emit(stats)
	return stats

const FALLBACK_SAVE_PATH = "res://game_save.json"

func save_progress() -> void:
	var save_dict = {
		"max_unlocked_level": max_unlocked_level,
		"selected_hero_id": selected_hero_id,
		"records": level_records,
		"endless_best_distance": endless_best_distance,
		"endless_best_fruits": endless_best_fruits
	}
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if not file:
		file = FileAccess.open(FALLBACK_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_dict, "\t"))
		file.close()

func load_progress() -> void:
	var path_to_use = SAVE_FILE_PATH
	if not FileAccess.file_exists(path_to_use):
		path_to_use = FALLBACK_SAVE_PATH
	if not FileAccess.file_exists(path_to_use):
		return
	var file = FileAccess.open(path_to_use, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		var json = JSON.new()
		var res = json.parse(content)
		if res == OK and json.data is Dictionary:
			var d = json.data
			max_unlocked_level = d.get("max_unlocked_level", 1)
			selected_hero_id = d.get("selected_hero_id", "ninja_frog")
			level_records = d.get("records", {})
			endless_best_distance = d.get("endless_best_distance", 0)
			endless_best_fruits = d.get("endless_best_fruits", 0)
