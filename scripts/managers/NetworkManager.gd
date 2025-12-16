extends Node

signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)
signal connection_failed()
signal connection_succeeded()

const PORT = 7777
const MAX_PEERS = 2

var wifi_ip: String = ""

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func get_wifi_ip() -> String:
	"""Gets the local WiFi IP address (192.168.x.x or 10.x.x.x)"""
	var interfaces = IP.get_local_addresses()
	
	# Filter for local network IPs
	for ip in interfaces:
		if ip.begins_with("192.168.") or ip.begins_with("10."):
			# Skip loopback and link-local addresses
			if not ip.begins_with("127.") and not ip.begins_with("169.254."):
				return ip
	
	# Fallback to localhost if no WiFi IP found
	return "127.0.0.1"

func host_game():
	"""Creates a server and displays WiFi IP address"""
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_PEERS)
	
	if error != OK:
		print("Failed to create server: ", error)
		connection_failed.emit()
		return
	
	multiplayer.multiplayer_peer = peer
	wifi_ip = get_wifi_ip()
	
	print("Server started on port ", PORT)
	print("WiFi IP: ", wifi_ip)
	
	# Emit signal to display IP address
	connection_succeeded.emit()

func join_game(ip: String):
	"""Connects to a host server"""
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, PORT)
	
	if error != OK:
		print("Failed to create client: ", error)
		connection_failed.emit()
		return
	
	multiplayer.multiplayer_peer = peer
	print("Connecting to ", ip, ":", PORT)

func _on_peer_connected(peer_id: int):
	"""Called when a peer connects"""
	print("Peer connected: ", peer_id)
	peer_connected.emit(peer_id)

func _on_peer_disconnected(peer_id: int):
	"""Called when a peer disconnects"""
	print("Peer disconnected: ", peer_id)
	peer_disconnected.emit(peer_id)

func _on_connected_to_server():
	"""Called when client successfully connects to server"""
	print("Connected to server!")
	connection_succeeded.emit()

func _on_connection_failed():
	"""Called when connection fails"""
	print("Connection failed!")
	connection_failed.emit()

func _on_server_disconnected():
	"""Called when server disconnects"""
	print("Server disconnected!")
	connection_failed.emit()

func get_peer_count() -> int:
	"""Returns the number of connected peers"""
	if multiplayer.multiplayer_peer == null:
		return 0
	# In Godot 4, we track peers differently
	# For now, return 1 if server (host) or 2 if client connected
	if multiplayer.is_server():
		return 1  # Server counts as 1, will be 2 when client connects
	return 0

@rpc("any_peer", "call_local", "reliable")
func change_to_battle_scene():
	"""Changes scene to battle for all players"""
	get_tree().change_scene_to_file("res://scenes/BattleScene.tscn")

