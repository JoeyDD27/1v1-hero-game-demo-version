extends CharacterBody2D

@export var damage: float = 50.0
@export var speed: float = 800.0
@export var max_distance: float = 1000.0

var direction: Vector2 = Vector2.ZERO
var start_position: Vector2 = Vector2.ZERO
var owner_peer_id: int = 0
var owner_hero_name: String = ""  # Name/path of the hero that fired this projectile

const PROJECTILE_RADIUS = 10.0  # Increased size for better visibility

var rotation_speed: float = 10.0  # Rotation speed for animation
var pulse_scale: float = 1.0
var pulse_direction: float = 1.0

# Destruction flag - prevents processing after collision
var is_destroyed: bool = false

# Network sync
var network_position: Vector2 = Vector2.ZERO
var network_update_rate: float = 0.05  # Update every 50ms
var network_update_timer: float = 0.0

func _ready():
	start_position = position
	# Initialize network_position to current position to avoid teleporting from (0,0)
	network_position = position
	
	# Set up collision
	if not has_node("CollisionShape2D"):
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = PROJECTILE_RADIUS
		collision.shape = shape
		add_child(collision)
	
	# Set collision layers on the CharacterBody2D (Projectile) itself, not the CollisionShape2D
	collision_layer = 1  # Make sure collision layer is set
	collision_mask = 1   # Make sure collision mask is set
	
	# Set up visual - make it more visible
	if not has_node("Visual"):
		_create_visual()
	
	# Verify authority is set correctly
	if multiplayer.multiplayer_peer != null:
		var authority = get_multiplayer_authority()
		var is_server = multiplayer.is_server()
		var has_auth = is_multiplayer_authority()
		print("Projectile _ready - Owner: ", owner_peer_id, " Authority: ", authority, " IsServer: ", is_server, " HasAuth: ", has_auth, " Position: ", position)
		
		# If we're the server but don't have authority, that's a problem
		if is_server and not has_auth:
			print("ERROR: Server spawned projectile but doesn't have authority! Fixing...")
			set_multiplayer_authority(1)
	
	# If we're a client, ensure we start at the correct position
	# The position should already be set before _ready() is called
	if multiplayer.multiplayer_peer != null and not is_multiplayer_authority():
		# Use the current position as initial network position
		# This prevents the projectile from appearing at (0,0) or staying at spawn
		if position.distance_to(Vector2.ZERO) > 1.0:
			network_position = position
		# Wait a frame for any initial position sync from server
		await get_tree().process_frame

func _create_visual():
	"""Create visual representation of projectile"""
	var visual = Polygon2D.new()
	visual.name = "Visual"
	visual.color = Color.YELLOW
	var points = PackedVector2Array()
	var point_count = 32  # More points for smoother circle
	for i in range(point_count):
		var angle = (i * 2.0 * PI) / point_count
		points.append(Vector2(cos(angle) * PROJECTILE_RADIUS, sin(angle) * PROJECTILE_RADIUS))
	visual.polygon = points
	add_child(visual)
	
	# Add outline for better visibility
	var outline = Polygon2D.new()
	outline.name = "Outline"
	outline.color = Color(1, 0.8, 0, 1)  # Orange outline
	var outline_points = PackedVector2Array()
	var point_count_outline = 32
	for i in range(point_count_outline):
		var angle = (i * 2.0 * PI) / point_count_outline
		outline_points.append(Vector2(cos(angle) * (PROJECTILE_RADIUS + 3), sin(angle) * (PROJECTILE_RADIUS + 3)))
	outline.polygon = outline_points
	add_child(outline)
	
	# Add inner glow for better visibility
	var inner = Polygon2D.new()
	inner.name = "Inner"
	inner.color = Color(1, 1, 0.5, 0.8)  # Bright yellow inner
	var inner_points = PackedVector2Array()
	for i in range(point_count):
		var angle = (i * 2.0 * PI) / point_count
		inner_points.append(Vector2(cos(angle) * (PROJECTILE_RADIUS * 0.6), sin(angle) * (PROJECTILE_RADIUS * 0.6)))
	inner.polygon = inner_points
	add_child(inner)

func setup(dir: Vector2, dmg: float, owner_id: int, projectile_color: Color = Color.YELLOW, hero_name: String = ""):
	"""Setup projectile"""
	direction = dir.normalized()
	damage = dmg
	owner_peer_id = owner_id
	owner_hero_name = hero_name
	
	# Initialize network_position to current position (set before this function)
	network_position = position
	
	# Ensure visual is created if scene doesn't have it
	if not has_node("Visual"):
		_create_visual()
	
	# Set visual color
	var visual = get_node_or_null("Visual")
	if visual is Polygon2D:
		visual.color = projectile_color
		visual.visible = true
	
	# Update outline color to match
	var outline = get_node_or_null("Outline")
	if outline is Polygon2D:
		# Make outline slightly darker version of projectile color
		outline.color = projectile_color.darkened(0.3)
		outline.visible = true
	
	# Update inner glow color
	var inner = get_node_or_null("Inner")
	if inner is Polygon2D:
		inner.color = projectile_color.lightened(0.3)
		inner.visible = true
	
	# Rotate to face direction
	if direction.length() > 0:
		rotation = direction.angle() + PI / 2.0

func _physics_process(delta):
	# Don't process if destroyed
	if is_destroyed:
		return
	
	# Network sync handling
	if multiplayer.multiplayer_peer != null:
		# Check if we have authority (server should have authority for all projectiles)
		var has_authority = is_multiplayer_authority()
		
		if not has_authority:
			# Client: interpolate network position
			# Only interpolate if network_position is valid (not zero or very close to zero)
			if network_position.distance_to(Vector2.ZERO) > 1.0 or position.distance_to(Vector2.ZERO) < 1.0:
				# Smooth interpolation
				position = position.lerp(network_position, 0.5)
			else:
				# If we're at origin and network_position is also origin, snap to network_position
				# This handles the initial spawn case
				if network_position.distance_to(Vector2.ZERO) < 1.0:
					# Wait for first position update - but if we've been waiting too long, use initial position
					# This prevents projectiles from staying stuck at spawn
					if position.distance_to(start_position) < 10.0:
						# Still at spawn, wait for update
						pass
					else:
						# Moved away from spawn, use current position
						network_position = position
				else:
					position = network_position
			# Still animate visuals
			_animate_projectile(delta)
			return
		
		# We have authority (server) - process movement and collision
		# CRITICAL: Server must process ALL projectiles, regardless of who spawned them
		_process_authority_physics(delta)
	else:
		# Single player - process normally
		_process_authority_physics(delta)

func _process_authority_physics(delta):
	"""Process physics for authority (server or single player)"""
	# Don't process if destroyed
	if is_destroyed:
		return
	
	# Verify we actually have authority
	if multiplayer.multiplayer_peer != null:
		if not is_multiplayer_authority():
			print("ERROR: _process_authority_physics called but we don't have authority! Owner: ", owner_peer_id)
			return
	
	# Animate projectile (rotation and pulsing)
	_animate_projectile(delta)
	
	# Move projectile
	# CRITICAL: Only move if we have a valid direction
	if direction.length() > 0:
		velocity = direction * speed
		move_and_slide()
		
		# Rotate projectile in direction of movement
		rotation = direction.angle() + PI / 2.0  # Face direction of travel
	else:
		# No direction set - this shouldn't happen, but handle it gracefully
		print("Warning: Projectile has no direction, cannot move. Owner: ", owner_peer_id)
		return
	
	# Check collision with enemies (only on authority/server)
	# CRITICAL: This must run on server for ALL projectiles, including guest projectiles
	_check_collisions()
	
	# Don't sync position if destroyed (prevents sending position after collision)
	if is_destroyed:
		return
	
	# Sync position to clients
	if multiplayer.multiplayer_peer != null:
		network_update_timer += delta
		if network_update_timer >= network_update_rate:
			# Ensure node is in tree and has valid path before calling RPC
			if is_inside_tree() and name != "" and get_parent() != null and get_parent().is_inside_tree():
				sync_projectile_position.rpc(position)
			else:
				# Debug: Log when RPC can't be sent
				if network_update_timer == network_update_rate:  # Only log once per update cycle
					print("Warning: Cannot sync projectile position - node not ready. In tree: ", is_inside_tree(), " name: ", name)
			network_update_timer = 0.0
	
	# Check if traveled too far
	if position.distance_to(start_position) > max_distance:
		# Notify hero that projectile is being removed (for cleanup)
		_notify_projectile_removed()
		is_destroyed = true
		queue_free()
		return

func _notify_projectile_removed():
	"""Notify hero system that projectile is being removed"""
	# Find the hero that spawned this projectile and clean up tracking
	var battle_manager = get_tree().get_first_node_in_group("battle_manager")
	if battle_manager:
		var heroes_node = battle_manager.get_node_or_null("Heroes")
		if heroes_node:
			for hero in heroes_node.get_children():
				if hero.has_method("_cleanup_projectile_tracking") and hero.player_id == owner_peer_id:
					hero._cleanup_projectile_tracking(owner_peer_id)
					break

@rpc("authority", "call_local", "unreliable")
func sync_projectile_position(pos: Vector2):
	"""Sync projectile position to all clients - only called by server (authority)"""
	# Don't update if destroyed
	if is_destroyed:
		return
	
	# This RPC is called by the server (authority) to sync position to clients
	# The call_local flag means it also executes on the server, but we ignore that
	# because the server already has the correct position
	
	# Only update if we're NOT the authority (i.e., we're a client)
	if not is_multiplayer_authority():
		# Update network position
		var old_network_pos = network_position
		network_position = pos
		
		# If this is the first position update (network_position was at origin), snap immediately
		# This prevents the teleport-from-origin bug
		if old_network_pos.distance_to(Vector2.ZERO) < 1.0 and network_position.distance_to(Vector2.ZERO) > 1.0:
			position = network_position
		# If position is way off (more than 100 pixels), snap immediately (initial sync)
		elif position.distance_to(network_position) > 100.0:
			position = network_position
		# If this is the first position update and we're at origin, snap immediately
		if position.distance_to(Vector2.ZERO) < 1.0 and network_position.distance_to(Vector2.ZERO) > 1.0:
			position = network_position

func _animate_projectile(delta):
	"""Animate projectile with pulsing and rotation"""
	# Pulsing animation
	pulse_scale += pulse_direction * delta * 3.0
	if pulse_scale > 1.2:
		pulse_scale = 1.2
		pulse_direction = -1.0
	elif pulse_scale < 0.9:
		pulse_scale = 0.9
		pulse_direction = 1.0
	
	# Apply pulsing scale to visual elements
	var visual = get_node_or_null("Visual")
	if visual:
		visual.scale = Vector2(pulse_scale, pulse_scale)
	
	var outline = get_node_or_null("Outline")
	if outline:
		outline.scale = Vector2(pulse_scale, pulse_scale)
	
	var inner = get_node_or_null("Inner")
	if inner:
		inner.scale = Vector2(pulse_scale, pulse_scale)
		# Rotate inner for spinning effect
		inner.rotation += rotation_speed * delta

func _check_collisions():
	"""Check for collisions with enemies - only on server/authority"""
	# Only check collisions on server/authority to avoid duplicate damage
	if multiplayer.multiplayer_peer != null and not is_multiplayer_authority():
		return
	
	# Ensure we have a valid direction and position
	if direction.length() == 0:
		return
	
	# Method 1: Direct hero checking (more reliable than physics queries)
	var battle_manager = get_tree().get_first_node_in_group("battle_manager")
	if battle_manager:
		var heroes_node = battle_manager.get_node_or_null("Heroes")
		if heroes_node:
			for hero in heroes_node.get_children():
				if not is_instance_valid(hero):
					continue
				
				# Check if it's a hero that can take damage
				if not hero.has_method("take_damage"):
					continue
				
				# Make sure it's an enemy hero (different player_id)
				var hero_player_id = hero.get("player_id")
				if hero_player_id == null:
					continue
				
				# Must be different player
				if hero_player_id == owner_peer_id:
					continue
				
				# Check if this is the specific hero that fired the projectile
				# Compare by name or path to avoid hitting the sender
				if owner_hero_name != "":
					var hero_name = hero.name if hero.name != "" else str(hero.get_path())
					if hero_name == owner_hero_name:
						continue  # Don't hit the hero that fired this projectile
				
				# Check if hero is dead
				var is_dead = hero.get("is_dead")
				if is_dead != null and is_dead:
					continue
				
				# Check invincibility
				var is_invincible = hero.get("is_invincible")
				if is_invincible != null and is_invincible:
					continue
				
				# Check distance to ensure we're actually colliding
				var distance = position.distance_to(hero.global_position)
				var collision_radius = PROJECTILE_RADIUS + 30.0  # Projectile radius + hero radius
				if distance <= collision_radius:
					# Hit! Apply damage
					print("Projectile hit! Owner: ", owner_peer_id, " Target: ", hero_player_id, " Damage: ", damage, " Distance: ", distance)
					
					# Mark as destroyed IMMEDIATELY to prevent further processing/syncing
					is_destroyed = true
					
					hero.take_damage(damage)
					
					# Sync destruction to all clients
					if multiplayer.multiplayer_peer != null:
						# Ensure node is in tree and has valid path before calling RPC
						if is_inside_tree() and name != "" and get_parent() != null and get_parent().is_inside_tree():
							destroy_projectile.rpc()
					
					queue_free()
					return
	
	# Method 2: Fallback to physics query (in case direct checking fails)
	var space_state = get_world_2d().direct_space_state
	if space_state == null:
		return
	
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = PROJECTILE_RADIUS + 30.0  # Projectile radius + hero radius
	query.shape = shape
	query.transform.origin = position
	query.collision_mask = 1  # Make sure we're checking the right collision layer
	
	var results = space_state.intersect_shape(query)
	
	for result in results:
		var body = result.collider
		if body == null or body == self:
			continue
		
		# Check if it's a hero that can take damage
		if not body.has_method("take_damage"):
			continue
		
		# Make sure it's an enemy hero (different player_id)
		var body_player_id = body.get("player_id")
		if body_player_id == null:
			continue
		
		# Must be different player
		if body_player_id == owner_peer_id:
			continue
		
		# Check if this is the specific hero that fired the projectile
		# Compare by name or path to avoid hitting the sender
		if owner_hero_name != "":
			var body_name = body.name if body.name != "" else str(body.get_path())
			if body_name == owner_hero_name:
				continue  # Don't hit the hero that fired this projectile
		
		# Check if hero is dead
		var is_dead = body.get("is_dead")
		if is_dead != null and is_dead:
			continue
		
		# Check invincibility
		var is_invincible = body.get("is_invincible")
		if is_invincible != null and is_invincible:
			continue
		
		# Check distance to ensure we're actually colliding
		var distance = position.distance_to(body.global_position)
		if distance > PROJECTILE_RADIUS + 30.0:  # Projectile radius + hero radius
			continue
		
		# Hit! Apply damage
		print("Projectile hit (physics query)! Owner: ", owner_peer_id, " Target: ", body_player_id, " Damage: ", damage)
		
		# Mark as destroyed IMMEDIATELY to prevent further processing/syncing
		is_destroyed = true
		
		body.take_damage(damage)
		
		# Sync destruction to all clients
		if multiplayer.multiplayer_peer != null:
			# Ensure node is in tree and has valid path before calling RPC
			if is_inside_tree() and name != "" and get_parent() != null and get_parent().is_inside_tree():
				destroy_projectile.rpc()
		
		queue_free()
		return

@rpc("authority", "call_local", "reliable")
func destroy_projectile():
	"""Sync projectile destruction to all clients"""
	# Mark as destroyed immediately to prevent further processing
	is_destroyed = true
	queue_free()
