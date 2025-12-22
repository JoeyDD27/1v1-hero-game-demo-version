extends Node2D

@onready var hero_scene = preload("res://scenes/Hero.tscn")

var spawn_points: Array[Marker2D] = []
var heroes: Dictionary = {}  # peer_id -> hero instance
var connected_peers: Array[int] = []

func _ready():
	# Wait for multiplayer to be ready
	if multiplayer.multiplayer_peer == null:
		return
	
	# Make sure camera is current
	var camera = get_node_or_null("Camera2D")
	if camera:
		camera.make_current()
	
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
		spawn_hero_for_peer(1)
		
		# Wait a moment for clients to connect, then spawn for them
		await get_tree().create_timer(0.5).timeout
		spawn_all_heroes()
	else:
		# Client waits a moment then requests spawn
		await get_tree().create_timer(0.2).timeout
		request_hero_spawn.rpc_id(1)

func _on_peer_connected(peer_id: int):
	"""Track connected peers"""
	if not connected_peers.has(peer_id):
		connected_peers.append(peer_id)
		print("Peer connected: ", peer_id)
		# Spawn hero for newly connected peer
		if multiplayer.is_server():
			spawn_hero_for_peer(peer_id)

func spawn_hero_for_peer(peer_id: int):
	"""Spawns a hero for a specific peer"""
	if heroes.has(peer_id):
		print("Hero already exists for peer ", peer_id)
		return  # Hero already spawned
	
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
	
	# Create hero instance
	var hero = hero_scene.instantiate()
	hero.position = spawn_point.position
	hero.name = "Hero_" + str(peer_id)
	
	# Set player ID BEFORE adding to scene tree
	hero.set_player_id(peer_id)
	
	# Set multiplayer authority BEFORE adding to scene tree (important for replication)
	hero.set_multiplayer_authority(peer_id)
	
	# Add to scene tree with force_readable_name for proper replication
	var heroes_node = get_node_or_null("Heroes")
	if heroes_node:
		heroes_node.add_child(hero, true)
	else:
		add_child(hero, true)
	
	# Wait for hero to be fully initialized and replicated in scene tree
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame  # Extra frame for replication
	
	heroes[peer_id] = hero
	
	# Notify ALL clients to spawn this hero (so RPC path resolution works)
	# This ensures all heroes exist on all clients for proper RPC path resolution
	if multiplayer.is_server():
		spawn_hero_on_client.rpc(peer_id, spawn_point.position)
	
	# Debug: Verify hero is visible
	print("Spawned hero for peer ", peer_id, " at ", spawn_point.position)
	print("Hero position: ", hero.position)
	print("Hero has visual: ", hero.has_node("Visual"))
	if hero.has_node("Visual"):
		var visual = hero.get_node("Visual")
		print("Visual color: ", visual.color if visual.has_method("get") else "N/A")

func spawn_all_heroes():
	"""Spawns heroes for all connected peers (server only)"""
	if not multiplayer.is_server():
		return
	
	# Spawn for server (peer 1)
	if not heroes.has(1):
		spawn_hero_for_peer(1)
	
	# Spawn for all tracked connected peers
	for peer_id in connected_peers:
		if not heroes.has(peer_id):
			spawn_hero_for_peer(peer_id)

@rpc("any_peer", "call_local", "reliable")
func request_hero_spawn():
	"""Client requests server to spawn their hero"""
	if multiplayer.is_server():
		# Get the requesting peer's ID
		var requesting_peer = multiplayer.get_remote_sender_id()
		if requesting_peer != 0 and not heroes.has(requesting_peer):
			connected_peers.append(requesting_peer)
			spawn_hero_for_peer(requesting_peer)

@rpc("authority", "reliable")
func spawn_hero_on_client(peer_id: int, spawn_pos: Vector2):
	"""Server tells client to spawn a hero locally"""
	# Only spawn if we don't already have this hero
	if heroes.has(peer_id):
		print("Hero already exists for peer ", peer_id, " on client")
		return
	
	# Don't spawn on server (server already spawned it)
	if multiplayer.is_server():
		return
	
	# Find spawn points if needed
	if spawn_points.is_empty():
		for child in get_children():
			if child is Marker2D:
				spawn_points.append(child)
	
	# Create hero instance locally
	var hero = hero_scene.instantiate()
	hero.position = spawn_pos
	hero.name = "Hero_" + str(peer_id)
	
	# Set player ID
	hero.set_player_id(peer_id)
	
	# Set multiplayer authority (only the actual peer has authority)
	hero.set_multiplayer_authority(peer_id)
	
	# Add to scene tree with force_readable_name for proper replication
	var heroes_node = get_node_or_null("Heroes")
	if heroes_node:
		heroes_node.add_child(hero, true)
	else:
		add_child(hero, true)
	
	# Wait for initialization and replication
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	heroes[peer_id] = hero
	print("Client spawned hero for peer ", peer_id, " at ", spawn_pos)
	print("Hero authority: ", hero.get_multiplayer_authority(), " (should be ", peer_id, ")")
