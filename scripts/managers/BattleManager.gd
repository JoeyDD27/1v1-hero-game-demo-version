extends Node2D

@onready var hero_scene = preload("res://scenes/Hero.tscn")

var spawn_points: Array[Marker2D] = []
var heroes: Dictionary = {}  # peer_id -> hero instance

func _ready():
	# Wait for multiplayer to be ready
	if multiplayer.multiplayer_peer == null:
		return
	
	# Find spawn points
	for child in get_children():
		if child is Marker2D:
			spawn_points.append(child)
	
	# If no spawn points found, create default ones
	if spawn_points.is_empty():
		var spawn1 = Marker2D.new()
		spawn1.position = Vector2(200, 540)
		spawn1.name = "SpawnPoint1"
		add_child(spawn1)
		spawn_points.append(spawn1)
		
		var spawn2 = Marker2D.new()
		spawn2.position = Vector2(1720, 540)
		spawn2.name = "SpawnPoint2"
		add_child(spawn2)
		spawn_points.append(spawn2)
	
	# Spawn heroes for connected players
	if multiplayer.is_server():
		# Server spawns for itself (peer 1)
		spawn_hero_for_peer(1)
		
		# Wait a moment for clients to connect, then spawn for them
		await get_tree().create_timer(0.5).timeout
		spawn_all_heroes()
	else:
		# Client spawns their own hero
		var my_id = multiplayer.get_unique_id()
		spawn_hero_for_peer(my_id)
		# Request server to spawn all heroes
		request_hero_spawn.rpc_id(1)

func spawn_hero_for_peer(peer_id: int):
	"""Spawns a hero for a specific peer"""
	if heroes.has(peer_id):
		return  # Hero already spawned
	
	if spawn_points.is_empty():
		print("No spawn points available!")
		return
	
	# Determine spawn point
	var spawn_index = 0
	if peer_id == 1:
		spawn_index = 0
	else:
		spawn_index = min(1, spawn_points.size() - 1)
	
	var spawn_point = spawn_points[spawn_index]
	
	# Create hero instance
	var hero = hero_scene.instantiate()
	hero.position = spawn_point.position
	hero.set_player_id(peer_id)
	hero.set_multiplayer_authority(peer_id)
	hero.name = "Hero_" + str(peer_id)
	
	# Add to scene tree
	var heroes_node = get_node_or_null("Heroes")
	if heroes_node:
		heroes_node.add_child(hero, true)
	else:
		add_child(hero, true)
	
	heroes[peer_id] = hero
	
	print("Spawned hero for peer ", peer_id, " at ", spawn_point.position)

func spawn_all_heroes():
	"""Spawns heroes for all connected peers (server only)"""
	if not multiplayer.is_server():
		return
	
	# Spawn for server (peer 1)
	if not heroes.has(1):
		spawn_hero_for_peer(1)
	
	# Get connected peer IDs from multiplayer API
	# In Godot 4, we need to track connected peers differently
	# For now, spawn for common peer IDs (1 and 2)
	for peer_id in [1, 2]:
		if not heroes.has(peer_id):
			spawn_hero_for_peer(peer_id)

@rpc("any_peer", "call_local", "reliable")
func request_hero_spawn():
	"""Client requests server to spawn heroes"""
	if multiplayer.is_server():
		spawn_all_heroes()

