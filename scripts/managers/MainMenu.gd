extends Control

@onready var host_button: Button = $VBoxContainer/HostButton
@onready var join_button: Button = $VBoxContainer/JoinButton
@onready var ip_label: Label = $VBoxContainer/IPLabel
@onready var ip_input: LineEdit = $VBoxContainer/IPInput
@onready var connect_button: Button = $VBoxContainer/ConnectButton
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var start_button: Button = $VBoxContainer/StartButton

var network_manager: Node
var is_hosting: bool = false
var is_connected: bool = false

func _ready():
	# NetworkManager is an autoload, access it directly
	network_manager = NetworkManager
	
	# Connect signals
	network_manager.connection_succeeded.connect(_on_connection_succeeded)
	network_manager.connection_failed.connect(_on_connection_failed)
	network_manager.peer_connected.connect(_on_peer_connected)
	network_manager.peer_disconnected.connect(_on_peer_disconnected)
	
	# Connect button signals
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	connect_button.pressed.connect(_on_connect_pressed)
	start_button.pressed.connect(_on_start_pressed)
	
	# Initially hide join-related UI
	ip_input.visible = false
	connect_button.visible = false
	start_button.visible = false
	ip_label.visible = false
	status_label.text = ""

func _on_host_pressed():
	"""Host a new game"""
	network_manager.host_game()
	is_hosting = true
	host_button.disabled = true
	join_button.disabled = true
	
	# Display WiFi IP address prominently
	var ip = network_manager.get_wifi_ip()
	ip_label.text = "Your WiFi IP: " + ip
	ip_label.add_theme_font_size_override("font_size", 64)
	ip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ip_label.visible = true
	
	status_label.text = "Waiting for player..."
	status_label.visible = true

func _on_join_pressed():
	"""Show join UI"""
	ip_input.visible = true
	connect_button.visible = true
	host_button.disabled = true
	join_button.disabled = true
	status_label.text = "Enter host IP address"
	status_label.visible = true

func _on_connect_pressed():
	"""Connect to host"""
	var ip = ip_input.text.strip_edges()
	if ip.is_empty():
		status_label.text = "Please enter an IP address"
		return
	
	status_label.text = "Connecting..."
	network_manager.join_game(ip)

func _on_start_pressed():
	"""Start the battle"""
	if is_connected:
		get_tree().change_scene_to_file("res://scenes/BattleScene.tscn")

func _on_connection_succeeded():
	"""Called when connection succeeds"""
	is_connected = true
	
	if is_hosting:
		# Host waits for client
		status_label.text = "Waiting for player..."
	else:
		# Client connected, wait for host to start
		status_label.text = "Connected! Waiting for host to start..."

func _on_connection_failed():
	"""Called when connection fails"""
	is_connected = false
	status_label.text = "Connection failed!"
	host_button.disabled = false
	join_button.disabled = false
	ip_input.visible = false
	connect_button.visible = false
	ip_label.visible = false
	start_button.visible = false

func _on_peer_connected(peer_id: int):
	"""Called when a peer connects"""
	if multiplayer.is_server():
		status_label.text = "Player connected! Ready to start."
		start_button.visible = true
		start_button.disabled = false

func _on_peer_disconnected(peer_id: int):
	"""Called when a peer disconnects"""
	is_connected = false
	status_label.text = "Player disconnected!"
	start_button.visible = false

