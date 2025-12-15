extends Node

## NetworkManager handles local WiFi multiplayer connection
## One player hosts, other connects via WiFi IP address

signal connection_succeeded
signal connection_failed
signal player_connected(peer_id)
signal player_disconnected(peer_id)

const PORT = 7777
var peer: ENetMultiplayerPeer

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func host_game():
	"""Host creates a server and waits for client to connect"""
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT)
	
	if error != OK:
		print("Failed to create server: ", error)
		connection_failed.emit()
		return
	
	multiplayer.multiplayer_peer = peer
	print("Server started on port ", PORT)
	print("IP Address: ", _get_local_ip())
	connection_succeeded.emit()

func join_game(ip_address: String):
	"""Client connects to host's IP address"""
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip_address, PORT)
	
	if error != OK:
		print("Failed to create client: ", error)
		connection_failed.emit()
		return
	
	multiplayer.multiplayer_peer = peer
	print("Connecting to ", ip_address, ":", PORT)
	connection_succeeded.emit()

func _get_local_ip() -> String:
	"""Get local WiFi IP address"""
	var ip_addresses = IP.get_local_addresses()
	for ip in ip_addresses:
		# Filter for local network IPs (192.168.x.x or 10.x.x.x)
		if ip.begins_with("192.168.") or ip.begins_with("10."):
			return ip
	# Fallback to first available IP
	if ip_addresses.size() > 0:
		return ip_addresses[0]
	return "127.0.0.1"

func get_local_ip() -> String:
	"""Public function to get local IP address"""
	return _get_local_ip()

func _on_peer_connected(peer_id: int):
	print("Peer connected: ", peer_id)
	player_connected.emit(peer_id)

func _on_peer_disconnected(peer_id: int):
	print("Peer disconnected: ", peer_id)
	player_disconnected.emit(peer_id)

func _on_connected_to_server():
	print("Successfully connected to server")
	connection_succeeded.emit()

func _on_connection_failed():
	print("Connection failed")
	connection_failed.emit()

func _on_server_disconnected():
	print("Server disconnected")
	connection_failed.emit()

func is_host() -> bool:
	return multiplayer.is_server()

func disconnect_from_game():
	if peer:
		peer.close()
		multiplayer.multiplayer_peer = null

