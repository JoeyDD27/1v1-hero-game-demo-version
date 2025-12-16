extends CharacterBody2D

@export var speed: float = 300.0
@export var player_id: int = 1

var target_position: Vector2 = Vector2.ZERO
var has_target: bool = false
var is_moving: bool = false

# Network sync
var network_position: Vector2 = Vector2.ZERO
var network_update_rate: float = 0.05  # Update every 50ms
var network_update_timer: float = 0.0

func _ready():
	# Set up collision shape if not already set
	if not has_node("CollisionShape2D"):
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 20.0
		collision.shape = shape
		add_child(collision)
	
	# Set up visual representation (colored circle)
	if not has_node("Visual"):
		# Use Polygon2D to draw a circle
		var visual = Polygon2D.new()
		visual.name = "Visual"
		var color = Color.BLUE if player_id == 1 else Color.RED
		visual.color = color
		
		# Create circle polygon (approximation with many points)
		var points = PackedVector2Array()
		var radius = 20.0
		var point_count = 32
		for i in range(point_count):
			var angle = (i * 2.0 * PI) / point_count
			points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
		visual.polygon = points
		add_child(visual)
	
	# Initialize network position to current position
	network_position = position
	
	# Sync initial position to all peers after a short delay
	if is_multiplayer_authority() and multiplayer.multiplayer_peer != null:
		await get_tree().create_timer(0.1).timeout
		sync_position.rpc(position)

func _physics_process(delta):
	# Only process movement if this is the local player's hero
	if not is_multiplayer_authority():
		# Interpolate network position smoothly
		# Only interpolate if we have a valid network position
		if network_position.distance_to(Vector2.ZERO) > 1.0 or position.distance_to(Vector2.ZERO) < 1.0:
			position = position.lerp(network_position, 0.5)
		return
	
	# Handle movement
	var movement = Vector2.ZERO
	
	# Right-click movement (MOBA style) - takes priority
	if Input.is_action_just_pressed("right_click"):
		var mouse_pos = get_global_mouse_position()
		target_position = mouse_pos
		has_target = true
	
	# Move toward target if set (right-click movement)
	if has_target:
		var direction = (target_position - position).normalized()
		var distance = position.distance_to(target_position)
		
		if distance > 5.0:  # Stop when close enough
			movement = direction
		else:
			has_target = false
			movement = Vector2.ZERO
	else:
		# WASD movement (only if no right-click target)
		if Input.is_action_pressed("move_up"):
			movement.y -= 1
		if Input.is_action_pressed("move_down"):
			movement.y += 1
		if Input.is_action_pressed("move_left"):
			movement.x -= 1
		if Input.is_action_pressed("move_right"):
			movement.x += 1
		
		# Cancel right-click target if WASD is pressed
		if movement.length() > 0:
			has_target = false
	
	# Normalize movement if diagonal
	if movement.length() > 1.0:
		movement = movement.normalized()
	
	# Apply movement
	velocity = movement * speed
	move_and_slide()
	
	# Sync position over network
	network_update_timer += delta
	if network_update_timer >= network_update_rate:
		sync_position.rpc(position)
		network_update_timer = 0.0

@rpc("any_peer", "call_local", "unreliable")
func sync_position(pos: Vector2):
	"""Syncs position across network"""
	if not is_multiplayer_authority():
		network_position = pos
		# Immediately snap to position if it's way off (initial sync or teleport)
		if position.distance_to(pos) > 200:
			position = pos

func set_player_id(id: int):
	"""Sets the player ID and updates visual"""
	player_id = id
	if has_node("Visual"):
		var visual = get_node("Visual")
		if visual is Polygon2D:
			visual.color = Color.BLUE if player_id == 1 else Color.RED

