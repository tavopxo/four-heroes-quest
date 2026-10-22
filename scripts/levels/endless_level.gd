extends Node2D
class_name EndlessLevel

@onready var background_layer: CanvasLayer = $BackgroundLayer
@onready var bg_texture_rect: TextureRect = $BackgroundLayer/BackgroundTexture
@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var player: Player = $Player
@onready var camera: Camera2D = $Camera2D
@onready var abyss_zone: Area2D = $AbyssZone
@onready var spawned_container: Node2D = $SpawnedObjects

# HUD references
@onready var hud: CanvasLayer = $EndlessHUD
@onready var health_container: HBoxContainer = $EndlessHUD/MarginContainer/TopBar/HealthContainer
@onready var hero_label: Label = $EndlessHUD/MarginContainer/TopBar/HeroBadge/HeroLabel
@onready var distance_label: Label = $EndlessHUD/MarginContainer/TopBar/DistanceLabel
@onready var fruits_label: Label = $EndlessHUD/MarginContainer/TopBar/FruitContainer/FruitLabel
@onready var best_label: Label = $EndlessHUD/MarginContainer/TopBar/BestLabel
@onready var pause_button: Button = $EndlessHUD/MarginContainer/TopBar/PauseButton
@onready var pause_menu: PauseMenu = $EndlessHUD/PauseMenu
@onready var game_over_panel: Control = $EndlessHUD/EndlessGameOver
@onready var go_distance_lbl: Label = $EndlessHUD/EndlessGameOver/PanelContainer/VBoxContainer/StatsGrid/DistValue
@onready var go_fruits_lbl: Label = $EndlessHUD/EndlessGameOver/PanelContainer/VBoxContainer/StatsGrid/FruitsValue
@onready var go_score_lbl: Label = $EndlessHUD/EndlessGameOver/PanelContainer/VBoxContainer/StatsGrid/ScoreValue
@onready var go_record_banner: Label = $EndlessHUD/EndlessGameOver/PanelContainer/VBoxContainer/RecordBanner
@onready var go_retry_btn: Button = $EndlessHUD/EndlessGameOver/PanelContainer/VBoxContainer/ButtonsHBox/RetryBtn
@onready var go_hero_btn: Button = $EndlessHUD/EndlessGameOver/PanelContainer/VBoxContainer/ButtonsHBox/HeroBtn
@onready var go_menu_btn: Button = $EndlessHUD/EndlessGameOver/PanelContainer/VBoxContainer/ButtonsHBox/MenuBtn

# Preloaded traps and items
var fruit_scene: PackedScene = preload("res://scenes/items/fruit.tscn")
var box_scene: PackedScene = preload("res://scenes/items/box.tscn")
var checkpoint_scene: PackedScene = preload("res://scenes/items/checkpoint.tscn")
var spikes_scene: PackedScene = preload("res://scenes/traps/spikes.tscn")
var saw_scene: PackedScene = preload("res://scenes/traps/saw.tscn")
var trampoline_scene: PackedScene = preload("res://scenes/traps/trampoline.tscn")
var moving_platform_scene: PackedScene = preload("res://scenes/traps/moving_platform.tscn")
var falling_platform_scene: PackedScene = preload("res://scenes/traps/falling_platform.tscn")
var fan_scene: PackedScene = preload("res://scenes/traps/fan.tscn")
var fire_trap_scene: PackedScene = preload("res://scenes/traps/fire_trap.tscn")
var slammer_scene: PackedScene = preload("res://scenes/traps/slammer.tscn")
var pendulum_scene: PackedScene = preload("res://scenes/traps/spiked_ball.tscn")

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

# Generation parameters
const TILE_SIZE: int = 16
const BASE_Y: int = 15 # Tile Y for ground level (240px)
const GENERATE_AHEAD_PX: float = 850.0
const DESPAWN_BEHIND_PX: float = 650.0
const MAX_FRUITS_PER_CHUNK: int = 3

var start_x: float = 60.0
var next_chunk_tile_x: int = 0
var last_chunk_exit_y: int = BASE_Y
var current_distance: int = 0
var next_milestone_m: int = 100
var active_chunks: Array[Dictionary] = []
var chunk_counter: int = 0

var fruit_types = ["apple", "bananas", "cherries", "kiwi", "melon", "orange", "pineapple", "strawberry"]

func _ready() -> void:
	if game_manager:
		game_manager.health_changed.connect(_on_health_changed)
		game_manager.fruits_changed.connect(_on_fruits_changed)
		game_manager.player_died.connect(_on_player_died)
		game_manager.checkpoint_reached.connect(_on_checkpoint_reached)
		_on_health_changed(game_manager.current_health, game_manager.max_health)
		_on_fruits_changed(game_manager.fruits_collected, 0)
		
		var hero = game_manager.get_hero_data()
		if hero_label:
			hero_label.text = hero.get("name", "Hero")
		if best_label:
			best_label.text = "Best: %dm" % game_manager.endless_best_distance
			
	if pause_button:
		pause_button.pressed.connect(_on_pause_button_pressed)
	if go_retry_btn:
		go_retry_btn.pressed.connect(_on_retry_pressed)
	if go_hero_btn:
		go_hero_btn.pressed.connect(_on_hero_select_pressed)
	if go_menu_btn:
		go_menu_btn.pressed.connect(_on_main_menu_pressed)
		
	abyss_zone.body_entered.connect(_on_abyss_body_entered)
	
	if player:
		start_x = player.global_position.x
		if game_manager:
			game_manager.start_position = player.global_position
			
	_build_initial_chunks()

func _process(_delta: float) -> void:
	if not player or not is_inside_tree():
		return
		
	# Update camera to follow player smoothly
	camera.global_position.x = player.global_position.x + 80.0
	camera.global_position.y = clampf(player.global_position.y - 20.0, 100.0, 220.0)
	
	# Keep abyss aligned with player X
	abyss_zone.global_position.x = player.global_position.x
	
	# Parallax scroll background
	if bg_texture_rect:
		bg_texture_rect.position.x = -fmod(player.global_position.x * 0.25, 64.0)
		
	# Calculate distance
	if not (game_manager and game_manager.is_game_over):
		var dist = int(max(0.0, (player.global_position.x - start_x) / float(TILE_SIZE)))
		if dist > current_distance:
			current_distance = dist
			if game_manager:
				game_manager.endless_distance = current_distance
			if distance_label:
				distance_label.text = "🏃 %dm" % current_distance
				
			# Check milestone every 100m
			if current_distance >= next_milestone_m:
				_spawn_milestone(player.global_position.x + 400.0, next_milestone_m)
				next_milestone_m += 100
				
	# Generate ahead
	if player.global_position.x + GENERATE_AHEAD_PX > next_chunk_tile_x * TILE_SIZE:
		_generate_next_chunk()
		
	# Despawn behind
	_cleanup_old_chunks()

func _build_initial_chunks() -> void:
	# Starting chunk: flat and safe
	var chunk_w = 26
	var chunk_data = {
		"id": 0,
		"start_x": 0,
		"end_x": chunk_w * TILE_SIZE,
		"tiles": [],
		"nodes": []
	}
	
	for tx in range(0, chunk_w):
		_place_column(chunk_data, tx, BASE_Y, 4)
		
	# Place initial start checkpoint
	var cp = checkpoint_scene.instantiate()
	cp.position = Vector2(50, (BASE_Y - 1) * TILE_SIZE)
	cp.checkpoint_type = "start"
	spawned_container.add_child(cp)
	chunk_data["nodes"].append(cp)
	
	# Place a small, readable introductory collectible line.
	for i in range(2):
		_spawn_fruit(chunk_data, Vector2((12 + i * 2) * TILE_SIZE, (BASE_Y - 2) * TILE_SIZE))
		
	active_chunks.append(chunk_data)
	next_chunk_tile_x = chunk_w
	last_chunk_exit_y = BASE_Y
	chunk_counter = 1
	
	# Keep the opening view readable instead of filling it with collectibles.
	for i in range(1):
		_generate_next_chunk()

func _generate_next_chunk() -> void:
	chunk_counter += 1
	var chunk_type = _choose_chunk_type()
	
	var chunk_w = randi_range(18, 24)
	var start_px = next_chunk_tile_x * TILE_SIZE
	var end_px = (next_chunk_tile_x + chunk_w) * TILE_SIZE
	
	var chunk_data = {
		"id": chunk_counter,
		"start_x": start_px,
		"end_x": end_px,
		"tiles": [],
		"nodes": []
	}
	
	match chunk_type:
		0: _build_chunk_flat_sprint(chunk_data, chunk_w)
		1: _build_chunk_step_platforms(chunk_data, chunk_w)
		2: _build_chunk_trampoline_chasm(chunk_data, chunk_w)
		3: _build_chunk_moving_platform(chunk_data, chunk_w)
		4: _build_chunk_falling_bridge(chunk_data, chunk_w)
		5: _build_chunk_saw_run(chunk_data, chunk_w)
		6: _build_chunk_fire_run(chunk_data, chunk_w)
		7: _build_chunk_fan_updraft(chunk_data, chunk_w)
		8: _build_chunk_slammer_crates(chunk_data, chunk_w)
		9: _build_chunk_pendulum_pass(chunk_data, chunk_w)
		10: _build_chunk_staggered_gaps(chunk_data, chunk_w)
		11: _build_chunk_hazard_gauntlet(chunk_data, chunk_w)
		_: _build_chunk_flat_sprint(chunk_data, chunk_w)
		
	active_chunks.append(chunk_data)
	next_chunk_tile_x += chunk_w

func _choose_chunk_type() -> int:
	# Introduce demanding combinations gradually while retaining a safe route.
	if current_distance < 60:
		return [0, 1, 2, 5][randi() % 4]
	if current_distance < 150:
		return [0, 1, 2, 3, 5, 6, 10][randi() % 7]
	if current_distance < 300:
		return randi_range(0, 10)
	return randi_range(0, 11)

# --- CHUNK BUILDERS ---

func _build_chunk_flat_sprint(chunk: Dictionary, w: int) -> void:
	var entry_y = last_chunk_exit_y
	var pit_start = randi_range(7, 10)
	var pit_size = 2
	
	for x in range(w):
		var tx = next_chunk_tile_x + x
		if x >= pit_start and x < pit_start + pit_size:
			# Pit with spikes
			_spawn_spikes(chunk, Vector2(tx * TILE_SIZE + 8, (entry_y + 2) * TILE_SIZE))
			continue
		_place_column(chunk, tx, entry_y, 4)
		
	# Arc of fruits over the pit
	for i in range(3):
		_spawn_fruit(chunk, Vector2((next_chunk_tile_x + pit_start - 1 + i * 2) * TILE_SIZE, (entry_y - 2 - (1 if i == 1 else 0)) * TILE_SIZE))
		
	last_chunk_exit_y = entry_y

func _build_chunk_step_platforms(chunk: Dictionary, w: int) -> void:
	var entry_y = last_chunk_exit_y
	var mid_y = clamp(entry_y + (randi_range(-2, 2)), 13, 16)
	
	var seg1 = w / 3
	var seg2 = (w * 2) / 3
	
	for x in range(w):
		var tx = next_chunk_tile_x + x
		var cur_y = entry_y if x < seg1 else (mid_y if x < seg2 else entry_y)
		_place_column(chunk, tx, cur_y, 4)
		if x == seg1 + 1:
			_spawn_box(chunk, Vector2(tx * TILE_SIZE + 8, (mid_y - 1) * TILE_SIZE + 8))
		elif x % 3 == 0 and x > 2:
			_spawn_fruit(chunk, Vector2(tx * TILE_SIZE + 8, (cur_y - 2) * TILE_SIZE))
			
	last_chunk_exit_y = entry_y

func _build_chunk_trampoline_chasm(chunk: Dictionary, w: int) -> void:
	var entry_y = last_chunk_exit_y
	var chasm_start = 5
	var chasm_end = w - 5
	var tramp_x = (chasm_start + chasm_end) / 2
	
	for x in range(w):
		var tx = next_chunk_tile_x + x
		if x >= chasm_start and x <= chasm_end:
			if x == tramp_x:
				# Island for trampoline
				_place_column(chunk, tx, entry_y + 1, 3)
				_spawn_trampoline(chunk, Vector2(tx * TILE_SIZE + 8, (entry_y + 1) * TILE_SIZE))
			else:
				# Abyss with spikes
				_spawn_spikes(chunk, Vector2(tx * TILE_SIZE + 8, (entry_y + 3) * TILE_SIZE))
		else:
			_place_column(chunk, tx, entry_y, 4)
			
	# High fruit arc
	for i in range(4):
		_spawn_fruit(chunk, Vector2((next_chunk_tile_x + chasm_start + i * 2) * TILE_SIZE, (entry_y - 5 + abs(i - 1.5)) * TILE_SIZE))
		
	last_chunk_exit_y = entry_y

func _build_chunk_moving_platform(chunk: Dictionary, w: int) -> void:
	var entry_y = last_chunk_exit_y
	var chasm_start = 4
	var chasm_end = w - 4
	
	for x in range(w):
		var tx = next_chunk_tile_x + x
		if x < chasm_start or x > chasm_end:
			_place_column(chunk, tx, entry_y, 4)
			
	var plat_spawn_x = (next_chunk_tile_x + chasm_start + 1) * TILE_SIZE
	var plat_spawn_y = (entry_y) * TILE_SIZE
	var dist_px = (chasm_end - chasm_start - 3) * TILE_SIZE
	_spawn_moving_platform(chunk, Vector2(plat_spawn_x, plat_spawn_y), Vector2(dist_px, 0), 45.0)
	
	# Fruit on crossing
	_spawn_fruit(chunk, Vector2(plat_spawn_x + dist_px * 0.5, plat_spawn_y - 24))
	last_chunk_exit_y = entry_y

func _build_chunk_falling_bridge(chunk: Dictionary, w: int) -> void:
	var entry_y = last_chunk_exit_y
	var chasm_start = 4
	var chasm_end = w - 4
	
	for x in range(w):
		var tx = next_chunk_tile_x + x
		if x < chasm_start or x > chasm_end:
			_place_column(chunk, tx, entry_y, 4)
			
	var count = 3
	var step = (chasm_end - chasm_start) / (count + 1)
	for i in range(count):
		var fx = (next_chunk_tile_x + chasm_start + (i + 1) * step) * TILE_SIZE
		var fy = (entry_y) * TILE_SIZE
		_spawn_falling_platform(chunk, Vector2(fx, fy))
		_spawn_fruit(chunk, Vector2(fx, fy - 20))
		
	last_chunk_exit_y = entry_y

func _build_chunk_saw_run(chunk: Dictionary, w: int) -> void:
	var entry_y = last_chunk_exit_y
	for x in range(w):
		var tx = next_chunk_tile_x + x
		_place_column(chunk, tx, entry_y, 4)
		
	var saw_x = (next_chunk_tile_x + 6) * TILE_SIZE
	var saw_y = (entry_y - 1) * TILE_SIZE
	var patrol = Vector2((w - 12) * TILE_SIZE, 0)
	_spawn_saw(chunk, Vector2(saw_x, saw_y), patrol, 70.0)
	
	# High fruits to encourage jumping
	for i in range(3):
		_spawn_fruit(chunk, Vector2((next_chunk_tile_x + 7 + i * 3) * TILE_SIZE, (entry_y - 3) * TILE_SIZE))
		
	last_chunk_exit_y = entry_y

func _build_chunk_fire_run(chunk: Dictionary, w: int) -> void:
	var entry_y = last_chunk_exit_y
	for x in range(w):
		var tx = next_chunk_tile_x + x
		_place_column(chunk, tx, entry_y, 4)
		
	var fire1_x = (next_chunk_tile_x + 5) * TILE_SIZE + 8
	var fire2_x = (next_chunk_tile_x + 12) * TILE_SIZE + 8
	var fire_y = (entry_y - 1) * TILE_SIZE + 8
	
	_spawn_fire_trap(chunk, Vector2(fire1_x, fire_y), 1.8, 1.4, false)
	_spawn_fire_trap(chunk, Vector2(fire2_x, fire_y), 1.8, 1.4, true)
	
	_spawn_box(chunk, Vector2((next_chunk_tile_x + 8) * TILE_SIZE + 8, fire_y))
	_spawn_fruit(chunk, Vector2((next_chunk_tile_x + 9) * TILE_SIZE, (entry_y - 2) * TILE_SIZE))
	
	last_chunk_exit_y = entry_y

func _build_chunk_fan_updraft(chunk: Dictionary, w: int) -> void:
	var entry_y = last_chunk_exit_y
	var drop_y = min(entry_y + 2, 17)
	var rise_y = max(entry_y - 2, 12)
	
	for x in range(w):
		var tx = next_chunk_tile_x + x
		if x < 4:
			_place_column(chunk, tx, entry_y, 4)
		elif x < 12:
			_place_column(chunk, tx, drop_y, 3)
		else:
			_place_column(chunk, tx, rise_y, 5)
			
	# Place wind fan on the drop floor
	var fan_pos = Vector2((next_chunk_tile_x + 7) * TILE_SIZE + 8, (drop_y - 1) * TILE_SIZE + 8)
	_spawn_fan(chunk, fan_pos)
	
	# Trail of fruits blowing upwards
	for i in range(3):
		_spawn_fruit(chunk, Vector2(fan_pos.x, fan_pos.y - 30 - i * 22))
		
	last_chunk_exit_y = rise_y

func _build_chunk_slammer_crates(chunk: Dictionary, w: int) -> void:
	var entry_y = last_chunk_exit_y
	var ceiling_y = entry_y - 6
	
	for x in range(w):
		var tx = next_chunk_tile_x + x
		_place_column(chunk, tx, entry_y, 4)
		# Ceiling blocks
		if x >= 4 and x <= w - 4:
			tile_map.set_cell(Vector2i(tx, ceiling_y), 0, Vector2i(1, 1))
			chunk["tiles"].append(Vector2i(tx, ceiling_y))
			
	var slammer_x = (next_chunk_tile_x + w / 2) * TILE_SIZE + 8
	var slammer_y = (ceiling_y + 1) * TILE_SIZE + 8
	_spawn_slammer(chunk, Vector2(slammer_x, slammer_y))
	
	_spawn_box(chunk, Vector2(slammer_x - 30, (entry_y - 1) * TILE_SIZE + 8))
	_spawn_box(chunk, Vector2(slammer_x + 30, (entry_y - 1) * TILE_SIZE + 8))
	
	last_chunk_exit_y = entry_y

func _build_chunk_pendulum_pass(chunk: Dictionary, w: int) -> void:
	var entry_y = last_chunk_exit_y
	for x in range(w):
		var tx = next_chunk_tile_x + x
		_place_column(chunk, tx, entry_y, 4)
		
	var pend_x = (next_chunk_tile_x + w / 2) * TILE_SIZE
	var pend_y = (entry_y - 5) * TILE_SIZE
	_spawn_pendulum(chunk, Vector2(pend_x, pend_y), 4, 2.0)
	
	_spawn_fruit(chunk, Vector2(pend_x - 24, (entry_y - 2) * TILE_SIZE))
	_spawn_fruit(chunk, Vector2(pend_x + 24, (entry_y - 2) * TILE_SIZE))
	
	last_chunk_exit_y = entry_y

func _build_chunk_staggered_gaps(chunk: Dictionary, w: int) -> void:
	var entry_y = last_chunk_exit_y
	var raised_y = max(entry_y - 2, 11)
	var gap_start = 4

	for x in range(w):
		var tx = next_chunk_tile_x + x
		var in_gap = x >= gap_start and x < w - 3 and (x - gap_start) % 4 >= 2
		if in_gap:
			_spawn_spikes(chunk, Vector2(tx * TILE_SIZE + 8, (entry_y + 2) * TILE_SIZE))
		else:
			var segment = int((x - gap_start) / 4)
			var top_y = raised_y if segment % 2 == 0 and x >= gap_start else entry_y
			_place_column(chunk, tx, top_y, 4)
			if x > gap_start and x % 4 == 0:
				_spawn_fruit(chunk, Vector2(tx * TILE_SIZE + 8, (top_y - 2) * TILE_SIZE))

	_spawn_trampoline(chunk, Vector2((next_chunk_tile_x + w - 3) * TILE_SIZE + 8, (entry_y - 1) * TILE_SIZE))
	last_chunk_exit_y = entry_y

func _build_chunk_hazard_gauntlet(chunk: Dictionary, w: int) -> void:
	var entry_y = last_chunk_exit_y
	for x in range(w):
		var tx = next_chunk_tile_x + x
		_place_column(chunk, tx, entry_y, 4)

	var hazard_y = (entry_y - 1) * TILE_SIZE + 8
	_spawn_fire_trap(chunk, Vector2((next_chunk_tile_x + 4) * TILE_SIZE + 8, hazard_y), 1.2, 1.2, false)
	_spawn_saw(chunk, Vector2((next_chunk_tile_x + 10) * TILE_SIZE + 8, hazard_y - 12), Vector2(48, 0), 85.0)
	_spawn_fire_trap(chunk, Vector2((next_chunk_tile_x + 16) * TILE_SIZE + 8, hazard_y), 0.8, 1.5, true)
	_spawn_box(chunk, Vector2((next_chunk_tile_x + 7) * TILE_SIZE + 8, hazard_y))
	_spawn_box(chunk, Vector2((next_chunk_tile_x + 13) * TILE_SIZE + 8, hazard_y))
	_spawn_fruit(chunk, Vector2((next_chunk_tile_x + 8) * TILE_SIZE + 8, (entry_y - 3) * TILE_SIZE))
	_spawn_fruit(chunk, Vector2((next_chunk_tile_x + 14) * TILE_SIZE + 8, (entry_y - 3) * TILE_SIZE))
	last_chunk_exit_y = entry_y

# --- TILE & OBJECT HELPERS ---

func _place_column(chunk: Dictionary, tx: int, top_y: int, depth: int) -> void:
	for d in range(depth):
		var ty = top_y + d
		var atlas = Vector2i(1, 0) if d == 0 else Vector2i(1, 1)
		tile_map.set_cell(Vector2i(tx, ty), 0, atlas)
		chunk["tiles"].append(Vector2i(tx, ty))

func _spawn_fruit(chunk: Dictionary, pos: Vector2) -> void:
	var fruit_count: int = chunk.get("fruit_count", 0)
	if fruit_count >= MAX_FRUITS_PER_CHUNK:
		return
	var f = fruit_scene.instantiate()
	f.position = pos
	var rtype = fruit_types[randi() % fruit_types.size()]
	f.fruit_type = rtype
	spawned_container.add_child(f)
	chunk["nodes"].append(f)
	chunk["fruit_count"] = fruit_count + 1

func _spawn_box(chunk: Dictionary, pos: Vector2) -> void:
	var b = box_scene.instantiate()
	b.position = pos
	spawned_container.add_child(b)
	chunk["nodes"].append(b)

func _spawn_spikes(chunk: Dictionary, pos: Vector2) -> void:
	var sp = spikes_scene.instantiate()
	sp.position = pos
	spawned_container.add_child(sp)
	chunk["nodes"].append(sp)

func _spawn_trampoline(chunk: Dictionary, pos: Vector2) -> void:
	var tr = trampoline_scene.instantiate()
	tr.position = pos
	spawned_container.add_child(tr)
	chunk["nodes"].append(tr)

func _spawn_saw(chunk: Dictionary, pos: Vector2, patrol: Vector2, spd: float) -> void:
	var s = saw_scene.instantiate()
	s.position = pos
	s.patrol_offset = patrol
	s.speed = spd
	spawned_container.add_child(s)
	chunk["nodes"].append(s)

func _spawn_moving_platform(chunk: Dictionary, pos: Vector2, offset: Vector2, spd: float) -> void:
	var mp = moving_platform_scene.instantiate()
	mp.position = pos
	mp.move_offset = offset
	mp.speed = spd
	spawned_container.add_child(mp)
	chunk["nodes"].append(mp)

func _spawn_falling_platform(chunk: Dictionary, pos: Vector2) -> void:
	var fp = falling_platform_scene.instantiate()
	fp.position = pos
	spawned_container.add_child(fp)
	chunk["nodes"].append(fp)

func _spawn_fan(chunk: Dictionary, pos: Vector2) -> void:
	var fan = fan_scene.instantiate()
	fan.position = pos
	spawned_container.add_child(fan)
	chunk["nodes"].append(fan)

func _spawn_fire_trap(chunk: Dictionary, pos: Vector2, off_t: float, on_t: float, start_on: bool) -> void:
	var ft = fire_trap_scene.instantiate()
	ft.position = pos
	ft.off_time = off_t
	ft.on_time = on_t
	ft.start_active = start_on
	spawned_container.add_child(ft)
	chunk["nodes"].append(ft)

func _spawn_slammer(chunk: Dictionary, pos: Vector2) -> void:
	var sl = slammer_scene.instantiate()
	sl.position = pos
	spawned_container.add_child(sl)
	chunk["nodes"].append(sl)

func _spawn_pendulum(chunk: Dictionary, pos: Vector2, len_links: int, spd: float) -> void:
	var pend = pendulum_scene.instantiate()
	pend.position = pos
	pend.chain_length = len_links
	pend.swing_speed = spd
	spawned_container.add_child(pend)
	chunk["nodes"].append(pend)

func _spawn_milestone(px: float, milestone_m: int) -> void:
	var cp = checkpoint_scene.instantiate()
	cp.position = Vector2(px, (BASE_Y - 1) * TILE_SIZE)
	cp.checkpoint_type = "mid"
	spawned_container.add_child(cp)
	if active_chunks.size() > 0:
		active_chunks.back()["nodes"].append(cp)

func _cleanup_old_chunks() -> void:
	if not player:
		return
	var despawn_thresh = player.global_position.x - DESPAWN_BEHIND_PX
	while active_chunks.size() > 2 and active_chunks[0]["end_x"] < despawn_thresh:
		var old = active_chunks.pop_front()
		# Clear tiles
		for c in old["tiles"]:
			tile_map.set_cell(c, -1)
		# Clear nodes
		for n in old["nodes"]:
			if is_instance_valid(n):
				n.queue_free()

# --- EVENT HANDLERS ---

func _on_abyss_body_entered(body: Node2D) -> void:
	if body is Player:
		(body as Player).take_damage(99, Vector2.ZERO, true)

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

func _on_fruits_changed(collected: int, _total: int) -> void:
	if fruits_label and is_inside_tree():
		fruits_label.text = "%d" % collected

func _on_checkpoint_reached(pos: Vector2) -> void:
	# Heal 1 heart on milestone!
	if game_manager:
		game_manager.heal_player(1)

func _on_player_died() -> void:
	if game_manager and game_manager.current_health <= 0:
		_show_game_over()

func _show_game_over() -> void:
	var fruits_got = game_manager.fruits_collected if game_manager else 0
	var total_score = current_distance * 10 + fruits_got * 50
	var is_new_record = false
	if game_manager:
		is_new_record = game_manager.update_endless_records(current_distance, fruits_got)
		
	if go_distance_lbl:
		go_distance_lbl.text = "%d m" % current_distance
	if go_fruits_lbl:
		go_fruits_lbl.text = "%d" % fruits_got
	if go_score_lbl:
		go_score_lbl.text = "%d pts" % total_score
	if go_record_banner:
		go_record_banner.visible = is_new_record
		
	if audio_manager:
		audio_manager.play_sfx("game_over" if not is_new_record else "win")
		
	if game_over_panel:
		game_over_panel.visible = true
	get_tree().paused = true
	if go_retry_btn:
		go_retry_btn.grab_focus()

func _on_pause_button_pressed() -> void:
	if audio_manager:
		audio_manager.play_sfx("click")
	if pause_menu:
		pause_menu.show_menu()

func _on_retry_pressed() -> void:
	if audio_manager:
		audio_manager.play_sfx("click")
	get_tree().paused = false
	if game_manager:
		game_manager.start_endless_mode()

func _on_hero_select_pressed() -> void:
	if audio_manager:
		audio_manager.play_sfx("click")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")

func _on_main_menu_pressed() -> void:
	if audio_manager:
		audio_manager.play_sfx("click")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
