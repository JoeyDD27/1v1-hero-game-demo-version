extends Node2D

@onready var hero_scene = preload("res://scenes/Hero.tscn")
@onready var hero_selection_ui_scene = preload("res://scenes/ui/HeroSelectionUI.tscn")

var spawn_points: Array[Marker2D] = []
var heroes: Dictionary = {}  # peer_id -> Array of 3 heroes
var active_heroes: Dictionary = {}  # peer_id -> active hero instance
var connected_peers: Array[int] = []

var hero_switching_manager: Node = null

# Match timer
var match_timer: float = 600.0  # 10 minutes = 600 seconds
var sudden_death: bool = false
var damage_multiplier: float = 1.0

# Win condition
var defeated_players: Array[int] = []

func _ready():
	add_to_group("battle_manager")
	
	# Wait for multiplayer to be ready
	if multiplayer.multiplayer_peer == null:
		return
	
	# Make sure camera is current
	var camera = get_node_or_null("Camera2D")
	if camera:
		camera.make_current()
	
	# Create hero switching manager
	hero_switching_manager = preload("res://scripts/managers/HeroSwitchingManager.gd").new()
	hero_switching_manager.name = "HeroSwitchingManager"
	hero_switching_manager.add_to_group("hero_switching_manager")
	add_child(hero_switching_manager)
	
	# Create hero selection UI
	var selection_ui = hero_selection_ui_scene.instantiate()
	add_child(selection_ui)
	
	# Connect to multiplayer signals to track peers
	multiplayer.peer_connected.connect(_on_peer_connected)
	
	# Find spawn points
	for child in get_children():
		if child is Marker2D:
			spawn_points.append(child)
	
	# If no spawn points found, create default ones
	if spawn_points.is_empty():
		var spawn1 = Marker2D.new()
		spawn1.position = Vector2(300, 540)  # Left side, visible on screen
		spawn1.name = "SpawnPoint1"
		add_child(spawn1)
		spawn_points.append(spawn1)
		
		var spawn2 = Marker2D.new()
		spawn2.position = Vector2(1620, 540)  # Right side, visible on screen
		spawn2.name = "SpawnPoint2"
		add_child(spawn2)
		spawn_points.append(spawn2)
	
	# Add server to connected peers
	if multiplayer.is_server():
		connected_peers.append(1)
	
	# Spawn heroes for connected players
	if multiplayer.is_server():
		# Server spawns for itself (peer 1)
		spawn_all_heroes_for_peer(1)
		
		# Wait a moment for clients to connect, then spawn for them
		await get_tree().create_timer(0.5).timeout
		spawn_all_heroes()
	else:
		# Client waits a moment then requests spawn
		await get_tree().create_timer(0.2).timeout
		request_hero_spawn.rpc_id(1)

func _process(delta):
	# Update match timer
	if multiplayer.is_server():
		match_timer -= delta
		
		# Check for sudden death
		if match_timer <= 0.0 and not sudden_death:
			sudden_death = true
			damage_multiplier = 3.0
			enable_sudden_death.rpc()
		
		# Check win condition
		_check_win_condition()

@rpc("any_peer", "call_local", "reliable")
func enable_sudden_death():
	"""Enable sudden death mode"""
	sudden_death = true
	damage_multiplier = 3.0
	print("SUDDEN DEATH! All damage x3.0")

func get_spawn_position(player_id: int) -> Vector2:
	"""Get spawn position for player"""
	if spawn_points.is_empty():
		return Vector2(960, 540)
	
	if player_id == 1:
		return spawn_points[0].position
	else:
		return spawn_points[min(1, spawn_points.size() - 1)].position

func _on_peer_connected(peer_id: int):
	"""Track connected peers"""
	if not connected_peers.has(peer_id):
		connected_peers.append(peer_id)
		print("Peer connected: ", peer_id)
		# Spawn heroes for newly connected peer
		if multiplayer.is_server():
			spawn_all_heroes_for_peer(peer_id)

func spawn_all_heroes_for_peer(peer_id: int):
	"""Spawns all 3 heroes (Fighter, Shooter, Mage) for a peer"""
	if heroes.has(peer_id):
		print("Heroes already exist for peer ", peer_id)
		return
	
	if spawn_points.is_empty():
		print("No spawn points available!")
		return
	
	# Determine spawn point (server on left, clients on right)
	var spawn_index = 0
	if peer_id == 1:
		spawn_index = 0  # Server spawns on left
	else:
		spawn_index = min(1, spawn_points.size() - 1)  # Clients spawn on right
	
	var spawn_point = spawn_points[spawn_index]
	var hero_types = ["Fighter", "Shooter", "Mage"]
	var hero_array = []
	
	# Spawn all 3 heroes
	for i in range(hero_types.size()):
		var hero_type = hero_types[i]
		var hero = hero_scene.instantiate()
		hero.position = spawn_point.position + Vector2(i * 10, 0)  # Slight offset for visibility
		hero.name = "Hero_" + hero_type + "_" + str(peer_id)
		
		# Set player ID and hero type BEFORE adding to scene tree
		hero.set_player_id(peer_id)
		hero.set_hero_type(hero_type)
		
		# Set multiplayer authority BEFORE adding to scene tree
		hero.set_multiplayer_authority(peer_id)
		
		# Connect death signal
		hero.hero_died.connect(_on_hero_died.bind(peer_id, hero))
		
		# Add to scene tree
		var heroes_node = get_node_or_null("Heroes")
		if heroes_node:
			heroes_node.add_child(hero, true)
		else:
			add_child(hero, true)
		
		# Wait for initialization
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		
		hero_array.append(hero)
	
	heroes[peer_id] = hero_array
	
	# Set first hero as active
	if hero_array.size() > 0:
		active_heroes[peer_id] = hero_array[0]
		# Activate first hero, deactivate others
		for i in range(hero_array.size()):
			if i == 0:
				hero_array[i].visible = true
				hero_array[i].set_process(true)
				hero_array[i].set_physics_process(true)
			else:
				hero_array[i].visible = false
				hero_array[i].set_process(false)
				hero_array[i].set_physics_process(false)
	
	# Register with switching manager
	if hero_switching_manager:
		hero_switching_manager.register_player_heroes(peer_id, hero_array)
	
	# Notify ALL clients to spawn these heroes
	if multiplayer.is_server():
		spawn_heroes_on_client.rpc(peer_id, spawn_point.position)
	
	print("Spawned all heroes for peer ", peer_id)

func spawn_all_heroes():
	"""Spawns heroes for all connected peers (server only)"""
	if not multiplayer.is_server():
		return
	
	# Spawn for server (peer 1)
	if not heroes.has(1):
		spawn_all_heroes_for_peer(1)
	
	# Spawn for all tracked connected peers
	for peer_id in connected_peers:
		if not heroes.has(peer_id):
			spawn_all_heroes_for_peer(peer_id)

func _on_hero_died(peer_id: int, hero_node):
	"""Handle hero death"""
	if hero_switching_manager:
		hero_switching_manager.on_hero_died(peer_id, hero_node)

func on_player_defeated(player_id: int):
	"""Called when all heroes of a player are dead"""
	if defeated_players.has(player_id):
		return
	
	defeated_players.append(player_id)
	show_victory_screen.rpc(player_id)

@rpc("any_peer", "call_local", "reliable")
func show_victory_screen(defeated_player_id: int):
	"""Show victory/defeat screen"""
	var winner_id = 1 if defeated_player_id == 2 else 2
	var local_id = multiplayer.get_unique_id() if multiplayer.multiplayer_peer != null else 1
	var is_winner = local_id == winner_id
	
	print("Player ", winner_id, " wins! Player ", defeated_player_id, " defeated.")
	if is_winner:
		print("VICTORY!")
	else:
		print("DEFEAT!")
	# TODO: Create victory/defeat UI

func _check_win_condition():
	"""Check if any player has won"""
	if defeated_players.size() > 0:
		return  # Already have a winner

@rpc("any_peer", "call_local", "reliable")
func request_hero_spawn():
	"""Client requests server to spawn their heroes"""
	if multiplayer.is_server():
		# Get the requesting peer's ID
		var requesting_peer = multiplayer.get_remote_sender_id()
		if requesting_peer != 0 and not heroes.has(requesting_peer):
			connected_peers.append(requesting_peer)
			spawn_all_heroes_for_peer(requesting_peer)

@rpc("authority", "reliable")
func spawn_heroes_on_client(peer_id: int, spawn_pos: Vector2):
	"""Server tells client to spawn heroes locally"""
	# Only spawn if we don't already have these heroes
	if heroes.has(peer_id):
		print("Heroes already exist for peer ", peer_id, " on client")
		return
	
	# Don't spawn on server (server already spawned them)
	if multiplayer.is_server():
		return
	
	# Find spawn points if needed
	if spawn_points.is_empty():
		for child in get_children():
			if child is Marker2D:
				spawn_points.append(child)
	
	var hero_types = ["Fighter", "Shooter", "Mage"]
	var hero_array = []
	
	# Spawn all 3 heroes locally
	for i in range(hero_types.size()):
		var hero_type = hero_types[i]
		var hero = hero_scene.instantiate()
		hero.position = spawn_pos + Vector2(i * 10, 0)
		hero.name = "Hero_" + hero_type + "_" + str(peer_id)
		
		# Set player ID and hero type
		hero.set_player_id(peer_id)
		hero.set_hero_type(hero_type)
		
		# Set multiplayer authority
		hero.set_multiplayer_authority(peer_id)
		
		# Connect death signal
		hero.hero_died.connect(_on_hero_died.bind(peer_id, hero))
		
		# Add to scene tree
		var heroes_node = get_node_or_null("Heroes")
		if heroes_node:
			heroes_node.add_child(hero, true)
		else:
			add_child(hero, true)
		
		# Wait for initialization
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		
		hero_array.append(hero)
	
	heroes[peer_id] = hero_array
	
	# Set first hero as active
	if hero_array.size() > 0:
		active_heroes[peer_id] = hero_array[0]
		# Activate first hero, deactivate others
		for i in range(hero_array.size()):
			if i == 0:
				hero_array[i].visible = true
				hero_array[i].set_process(true)
				hero_array[i].set_physics_process(true)
			else:
				hero_array[i].visible = false
				hero_array[i].set_process(false)
				hero_array[i].set_physics_process(false)
	
	# Register with switching manager
	if hero_switching_manager:
		hero_switching_manager.register_player_heroes(peer_id, hero_array)
	
	print("Client spawned all heroes for peer ", peer_id)
