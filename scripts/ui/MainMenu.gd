extends Control

## Main Menu UI - handles host/join game buttons

const GameManager = preload("res://scripts/managers/GameManager.gd")

@onready var host_button: Button = $VBoxContainer/HostButton
@onready var join_button: Button = $VBoxContainer/JoinButton
@onready var ip_input: LineEdit = $VBoxContainer/IPInput
@onready var ip_label: Label = $VBoxContainer/IPLabel
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var quick_start_button: Button = $VBoxContainer/QuickStartButton

var game_manager: GameManager

func _ready():
	game_manager = get_node_or_null("/root/GameManager")
	if not game_manager:
		game_manager = GameManager.new()
		game_manager.name = "GameManager"
		# Use call_deferred to avoid "Parent node is busy" error
		get_tree().root.add_child.call_deferred(game_manager)
	
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	quick_start_button.pressed.connect(_on_quick_start_pressed)
	
	# Wait for next frame to ensure GameManager is ready
	await get_tree().process_frame
	
	# Connect to network manager signals (ensure network_manager exists)
	if game_manager and game_manager.network_manager:
		game_manager.network_manager.connection_succeeded.connect(_on_connection_succeeded)
		game_manager.network_manager.connection_failed.connect(_on_connection_failed)
	
	# Initially hide IP label until hosting
	ip_label.text = ""
	ip_label.visible = false
	status_label.text = "Ready to connect"

func _on_host_pressed():
	"""Host a game"""
	game_manager.host_game()
	
	# Get and display IP address prominently
	var ip_address = game_manager.network_manager.get_local_ip()
	ip_label.text = "YOUR IP ADDRESS:\n" + ip_address + "\n\nShare this with the other player!"
	ip_label.visible = true
	status_label.text = "Hosting game... Waiting for player to connect..."
	
	# Disable host button after hosting
	host_button.disabled = true

func _on_join_pressed():
	"""Join a game"""
	var ip = ip_input.text.strip_edges()
	if ip.is_empty():
		status_label.text = "Please enter an IP address"
		return
	
	status_label.text = "Connecting to " + ip + "..."
	game_manager.join_game(ip)

func _on_quick_start_pressed():
	"""Quick start - single player test mode"""
	# Skip networking, go straight to battle for testing
	get_tree().change_scene_to_file("res://scenes/BattleScene.tscn")

func _on_connection_succeeded():
	status_label.text = "Connected! Starting game..."

func _on_connection_failed():
	status_label.text = "Connection failed. Check IP address and try again."
