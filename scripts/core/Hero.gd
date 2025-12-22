extends CharacterBody2D

@export var speed: float = 300.0
@export var player_id: int = 1

const HERO_RADIUS = 30.0
const SCREEN_WIDTH = 1920.0
const SCREEN_HEIGHT = 1080.0

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
		# Use Polygon2D to draw a large, visible circle
		var visual = Polygon2D.new()
		visual.name = "Visual"
		var color = Color.BLUE if player_id == 1 else Color.RED
		visual.color = color
		
		# Create circle polygon with larger radius for better visibility
		var points = PackedVector2Array()
		var point_count = 32
		for i in range(point_count):
			var angle = (i * 2.0 * PI) / point_count
			points.append(Vector2(cos(angle) * HERO_RADIUS, sin(angle) * HERO_RADIUS))
		visual.polygon = points
		add_child(visual)
	
	# Initialize network position to current position
	network_position = position
	
	# Sync initial position after node is ready and multiplayer is set up
	if is_multiplayer_authority() and multiplayer.multiplayer_peer != null:
		# Wait a couple frames to ensure node is fully in scene tree and replicated
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame  # Extra frame for multiplayer replication
		# Only sync if we have a valid position and node is in tree
		# Verify parent chain exists to prevent path resolution errors
		if position != Vector2.ZERO and is_inside_tree() and name != "" and get_parent() != null:
			# Ensure parent is also in tree (required for full path resolution)
			if get_parent().is_inside_tree():
				sync_position.rpc(position)

func _physics_process(delta):
	# Only process movement if this is the local player's hero
	if not is_multiplayer_authority():
		# Interpolate network position smoothly
		# Only interpolate if we have a valid network position
		var hero_radius = HERO_RADIUS  # Use local variable to avoid warning
		if network_position.distance_to(Vector2.ZERO) > 1.0 or position.distance_to(Vector2.ZERO) < 1.0:
			position = position.lerp(network_position, 0.5)
			# Clamp network-synced position to bounds too
			position.x = clamp(position.x, hero_radius, SCREEN_WIDTH - hero_radius)
			position.y = clamp(position.y, hero_radius, SCREEN_HEIGHT - hero_radius)
		return
	
	# Handle movement
	var movement = Vector2.ZERO
	
	# Right-click movement (MOBA style) - takes priority
	if Input.is_action_just_pressed("right_click"):
		var mouse_pos = get_global_mouse_position()
		# Clamp target to screen bounds
		target_position = Vector2(
			clamp(mouse_pos.x, HERO_RADIUS, SCREEN_WIDTH - HERO_RADIUS),
			clamp(mouse_pos.y, HERO_RADIUS, SCREEN_HEIGHT - HERO_RADIUS)
		)
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
	
	# Clamp position to screen bounds (with hero radius padding)
	position.x = clamp(position.x, HERO_RADIUS, SCREEN_WIDTH - HERO_RADIUS)
	position.y = clamp(position.y, HERO_RADIUS, SCREEN_HEIGHT - HERO_RADIUS)
	
	# Sync position over network
	network_update_timer += delta
	if network_update_timer >= network_update_rate:
		# Only sync if multiplayer is ready and we're the authority
		# Also check that we have a valid name (ensures node is properly replicated)
		# Verify parent chain exists to prevent path resolution errors
		if multiplayer.multiplayer_peer != null and is_multiplayer_authority() and is_inside_tree() and name != "":
			# Ensure parent is also in tree (required for full path resolution like "BattleScene/Heroes/Hero_1")
			if get_parent() != null and get_parent().is_inside_tree():
				# Node is in tree and has authority, safe to call RPC
				sync_position.rpc(position)
		network_update_timer = 0.0

@rpc("any_peer", "call_local", "unreliable")
func sync_position(pos: Vector2):
	"""Syncs position across network"""
	# Safety check: ensure node exists and is in tree
	if not is_inside_tree():
		return
	# Only process if we're not the authority (we receive other players' positions)
	if not is_multiplayer_authority():
		network_position = pos
		# Immediately snap to position if it's way off (initial sync or teleport)
		if position.distance_to(pos) > 200:
			position = pos

func set_player_id(id: int):
	"""Sets the player ID and updates visual"""
	player_id = id
	var color = Color.BLUE if player_id == 1 else Color.RED
	
	var visual = get_node_or_null("Visual")
	if visual is Polygon2D:
		visual.color = color
