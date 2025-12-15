extends Node

## GameManager handles overall game state and flow

const NetworkManager = preload("res://scripts/managers/NetworkManager.gd")

signal game_started
signal game_ended(winner: int)

var network_manager: NetworkManager
var is_host: bool = false
var players_ready: int = 0

func _ready():
	# Get or create NetworkManager
	network_manager = get_node_or_null("/root/NetworkManager")
	if not network_manager:
		network_manager = NetworkManager.new()
		network_manager.name = "NetworkManager"
		# Use call_deferred to avoid "Parent node is busy" error
		get_tree().root.add_child.call_deferred(network_manager)
		# Wait a frame for NetworkManager to be added
		await get_tree().process_frame
	
	# Connect signals after NetworkManager is ready
	if network_manager:
		network_manager.connection_succeeded.connect(_on_connection_succeeded)
		network_manager.player_connected.connect(_on_player_connected)

func host_game():
	"""Start hosting a game"""
	network_manager.host_game()
	is_host = true

func join_game(ip_address: String):
	"""Join a hosted game"""
	network_manager.join_game(ip_address)
	is_host = false

func _on_connection_succeeded():
	print("Connection succeeded!")

func _on_player_connected(peer_id: int):
	print("Player connected: ", peer_id)
	players_ready += 1
	
	# If host and client connected, start game
	if is_host and players_ready >= 1:
		start_game.rpc()

@rpc("any_peer", "call_local", "reliable")
func start_game():
	"""Start the battle"""
	game_started.emit()
	get_tree().change_scene_to_file("res://scenes/BattleScene.tscn")

func end_game(winner_peer_id: int):
	"""End the game with a winner"""
	game_ended.emit(winner_peer_id)
	end_game_rpc.rpc(winner_peer_id)

@rpc("any_peer", "call_local", "reliable")
func end_game_rpc(winner_peer_id: int):
	game_ended.emit(winner_peer_id)

