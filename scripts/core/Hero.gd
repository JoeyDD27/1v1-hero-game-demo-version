extends CharacterBody2D

@export var speed: float = 300.0
@export var player_id: int = 1
@export var hero_type: String = "Fighter"  # "Fighter", "Shooter", or "Mage"

const HERO_RADIUS = 30.0
const SCREEN_WIDTH = 1920.0
const SCREEN_HEIGHT = 1080.0

# Hero Stats
var max_health: float = 1000.0
var current_health: float = 1000.0
var attack_damage: float = 80.0
var attack_range: float = 120.0
var attack_speed: float = 1.0  # Attacks per second
var attack_cooldown: float = 0.0

# Ability cooldowns
var ability_q_cooldown: float = 0.0
var ability_e_cooldown: float = 0.0
var ability_q_max_cooldown: float = 8.0
var ability_e_max_cooldown: float = 12.0

# Combat state
var is_dead: bool = false
var spawn_protection: float = 0.0  # Spawn protection timer
var is_invincible: bool = false

var target_position: Vector2 = Vector2.ZERO
var has_target: bool = false
var is_moving: bool = false

# Network sync
var network_position: Vector2 = Vector2.ZERO
var network_update_rate: float = 0.05  # Update every 50ms
var network_update_timer: float = 0.0

signal hero_died
signal health_changed(new_health: float, max_health: float)

func _ready():
	# Initialize hero stats based on type
	_initialize_hero_stats()
	
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
		var color = _get_hero_color()
		visual.color = color
		
		# Create circle polygon with larger radius for better visibility
		var points = PackedVector2Array()
		var point_count = 32
		for i in range(point_count):
			var angle = (i * 2.0 * PI) / point_count
			points.append(Vector2(cos(angle) * HERO_RADIUS, sin(angle) * HERO_RADIUS))
		visual.polygon = points
		add_child(visual)
	
	# Initialize health
	current_health = max_health
	
	# Create health bar
	_create_health_bar()
	
	# Connect health changed signal
	health_changed.connect(_on_health_changed)
	
	# Initialize network position to current position
	network_position = position

func _create_health_bar():
	"""Create health bar for this hero"""
	# Wait a frame to ensure hero is in scene tree
	await get_tree().process_frame
	
	var health_bar_scene = preload("res://scenes/HealthBar.tscn")
	var health_bar = null
	
	if health_bar_scene:
		health_bar = health_bar_scene.instantiate()
	else:
		# Create dynamically if scene doesn't exist
		health_bar = preload("res://scripts/ui/HealthBar.gd").new()
	
	if health_bar:
		health_bar.setup(self, max_health)
		
		# Add to scene tree (add to battle scene or root)
		var battle_scene = get_tree().get_first_node_in_group("battle_manager")
		if battle_scene:
			battle_scene.add_child(health_bar)
		else:
			get_tree().root.add_child(health_bar)

func _on_health_changed(new_health: float, max_hp: float):
	"""Update health bar when health changes"""
	# Find health bar and update it
	var health_bars = get_tree().get_nodes_in_group("health_bars")
	for hb in health_bars:
		if hb.has_method("update_health") and hb.hero == self:
			hb.update_health(new_health, max_hp)
			break
	
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
				# Delay RPC call slightly to ensure node is fully replicated
				await get_tree().create_timer(0.1).timeout
				if is_inside_tree() and is_multiplayer_authority():
					sync_position.rpc(position)

func _initialize_hero_stats():
	"""Initialize hero stats based on hero_type"""
	match hero_type:
		"Fighter":
			max_health = 1000.0
			attack_damage = 80.0
			attack_range = 120.0
			attack_speed = 1.0
			ability_q_max_cooldown = 8.0
			ability_e_max_cooldown = 12.0
		"Shooter":
			max_health = 600.0
			attack_damage = 70.0
			attack_range = 600.0
			attack_speed = 1.2
			ability_q_max_cooldown = 15.0
			ability_e_max_cooldown = 10.0
		"Mage":
			max_health = 400.0
			attack_damage = 90.0
			attack_range = 500.0
			attack_speed = 1.0
			ability_q_max_cooldown = 6.0
			ability_e_max_cooldown = 10.0
	current_health = max_health

func _get_hero_color() -> Color:
	"""Get color based on hero type and player ID"""
	if player_id == 1:
		match hero_type:
			"Fighter":
				return Color.BLUE
			"Shooter":
				return Color.GREEN
			"Mage":
				return Color.CYAN
	else:
		match hero_type:
			"Fighter":
				return Color.RED
			"Shooter":
				return Color.ORANGE
			"Mage":
				return Color.MAGENTA
	return Color.WHITE

func _physics_process(delta):
	# Check if multiplayer is active before checking authority
	if multiplayer.multiplayer_peer == null:
		# No multiplayer, process normally (single player mode)
		_process_local_movement(delta)
		return
	
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
	
	# Process local movement (we have authority)
	_process_local_movement(delta)
	
func _process_local_movement(delta):
	"""Process local movement and input (called when we have authority or no multiplayer)"""
	# Update cooldowns for UI feedback (guests update locally, server is source of truth)
	# Server will sync cooldowns back via RPC, but guests need local updates for responsive UI
	attack_cooldown = max(0.0, attack_cooldown - delta)
	ability_q_cooldown = max(0.0, ability_q_cooldown - delta)
	ability_e_cooldown = max(0.0, ability_e_cooldown - delta)
	
	# Only server/authority updates buffs and spawn protection
	if multiplayer.multiplayer_peer == null or is_multiplayer_authority():
		
		# Update rapid fire buff (server manages this)
		if rapid_fire_active:
			rapid_fire_timer -= delta
			if rapid_fire_timer <= 0.0:
				rapid_fire_active = false
				attack_speed /= 2.0  # Restore normal attack speed
				# Restore visual color
				var visual = get_node_or_null("Visual")
				if visual is Polygon2D:
					visual.color = _get_hero_color()
		
		# Update spawn protection (server manages this)
		if spawn_protection > 0.0:
			spawn_protection -= delta
			is_invincible = spawn_protection > 0.0
		else:
			is_invincible = false
	
	# Periodic cleanup of invalid projectiles from tracking (every 2 seconds)
	# All clients can do this for their local projectile tracking
	projectile_cleanup_timer += delta
	if projectile_cleanup_timer >= 2.0:
		_cleanup_invalid_projectiles()
		projectile_cleanup_timer = 0.0
	
	# Don't process if dead
	if is_dead:
		return
	
	# Handle movement - WASD takes priority
	var movement = Vector2.ZERO
	
	# WASD movement (priority)
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
	else:
		# Right-click movement (only if WASD not pressed)
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
	
	# Normalize movement if diagonal
	if movement.length() > 1.0:
		movement = movement.normalized()
	
	# Apply movement
	velocity = movement * speed
	move_and_slide()
	
	# Clamp position to screen bounds (with hero radius padding)
	position.x = clamp(position.x, HERO_RADIUS, SCREEN_WIDTH - HERO_RADIUS)
	position.y = clamp(position.y, HERO_RADIUS, SCREEN_HEIGHT - HERO_RADIUS)
	
	# Handle attack input
	# GUESTS: Send to server, server validates cooldown
	if Input.is_action_just_pressed("attack"):
		if multiplayer.multiplayer_peer == null or is_multiplayer_authority():
			# Server/authority: Check cooldown locally
			if attack_cooldown <= 0.0:
				attack_toward_mouse()
		else:
			# Guest: Send to server (server will validate cooldown)
			attack_toward_mouse()  # This will send RPC to server
	
	# Handle ability inputs
	# GUESTS: Send to server, server validates cooldown
	if Input.is_action_just_pressed("ability_q"):
		if multiplayer.multiplayer_peer == null or is_multiplayer_authority():
			# Server/authority: Check cooldown locally
			if ability_q_cooldown <= 0.0:
				use_ability_q()
		else:
			# Guest: Send to server (server will validate cooldown)
			use_ability_q()  # This will send RPC to server
	
	if Input.is_action_just_pressed("ability_e"):
		if multiplayer.multiplayer_peer == null or is_multiplayer_authority():
			# Server/authority: Check cooldown locally
			if ability_e_cooldown <= 0.0:
				use_ability_e()
		else:
			# Guest: Send to server (server will validate cooldown)
			use_ability_e()  # This will send RPC to server
	
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
	# Safety check: ensure multiplayer is active
	if multiplayer.multiplayer_peer == null:
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
	_update_visual_color()

func set_hero_type(type: String):
	"""Sets the hero type and updates stats"""
	hero_type = type
	_initialize_hero_stats()
	_update_visual_color()

func _update_visual_color():
	"""Updates visual color based on hero type and player ID"""
	var visual = get_node_or_null("Visual")
	if visual is Polygon2D:
		visual.color = _get_hero_color()

func take_damage(amount: float):
	"""Apply damage to hero - server-authoritative: only server processes damage"""
	# If multiplayer is active, route through RPC to server
	if multiplayer.multiplayer_peer != null:
		# Server processes damage directly
		if multiplayer.is_server():
			_apply_damage_internal(amount)
			return
		
		# Client: Send RPC to server
		# Ensure node is in tree and has a valid path before calling RPC
		if not is_inside_tree() or name == "":
			# Node not ready, can't apply damage
			return
		
		# Ensure parent is also in tree (required for path resolution)
		if get_parent() == null or not get_parent().is_inside_tree():
			# Parent not ready, can't resolve path for RPC
			return
		
		# Send to server (peer 1)
		apply_damage_rpc.rpc_id(1, amount)
		return
	
	# Single player - apply damage directly
	_apply_damage_internal(amount)

func _server_apply_damage(amount: float):
	"""Server-only function to apply damage directly (bypasses RPC)"""
	# Only server can call this
	if not multiplayer.is_server():
		return
	_apply_damage_internal(amount)

func _apply_damage_internal(amount: float):
	"""Internal function that actually applies damage - ONLY called on server"""
	# Only server processes damage
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		return
	
	if is_invincible or is_dead:
		return
	
	# Apply damage multiplier (for sudden death)
	var battle_manager = get_tree().get_first_node_in_group("battle_manager")
	if battle_manager:
		amount *= battle_manager.damage_multiplier
	
	current_health -= amount
	current_health = max(0.0, current_health)
	
	# Sync health to all clients (server calls this)
	if multiplayer.multiplayer_peer != null:
		# Ensure node is in tree and has valid path before calling RPC
		if is_inside_tree() and name != "" and get_parent() != null and get_parent().is_inside_tree():
			sync_health_rpc.rpc(current_health, max_health)
	
	# Update local health bar
	health_changed.emit(current_health, max_health)
	
	# Spawn damage number
	# Ensure node is in tree and has valid path before calling RPC
	if is_inside_tree() and name != "" and get_parent() != null and get_parent().is_inside_tree():
		spawn_damage_number.rpc(amount)
	
	# Check for death
	if current_health <= 0.0 and not is_dead:
		die()

@rpc("any_peer", "reliable")
func apply_damage_rpc(amount: float):
	"""RPC to apply damage - only server processes this"""
	# Only server processes damage
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		return
	
	# Apply damage (server validates invincibility/death internally)
	_apply_damage_internal(amount)

@rpc("any_peer", "reliable")
func sync_attack_cooldown(new_cooldown: float):
	"""Sync attack cooldown from server to clients"""
	attack_cooldown = new_cooldown

@rpc("any_peer", "reliable")
func sync_ability_cooldown(ability: String, new_cooldown: float):
	"""Sync ability cooldown from server to clients"""
	match ability:
		"q":
			ability_q_cooldown = new_cooldown
		"e":
			ability_e_cooldown = new_cooldown

@rpc("any_peer", "reliable")
func sync_health_rpc(new_health: float, max_hp: float):
	"""Sync health value to all clients - only server calls this"""
	# Update health on all clients (including server)
	current_health = new_health
	max_health = max_hp
	health_changed.emit(current_health, max_health)
	
	# Guests can detect death locally for UI feedback (server will also sync is_dead)
	# But we rely on server's is_dead flag for actual death state
	if current_health <= 0.0 and not is_dead:
		# Health is 0 but server hasn't synced death yet - wait for server
		# The server will call sync_death_state_rpc when die() is called
		pass

func die():
	"""Handle hero death - ONLY called on server"""
	# Only server processes death
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		return
	
	if is_dead:
		return
	
	is_dead = true
	
	# Sync death state to all clients (server calls this)
	if multiplayer.multiplayer_peer != null:
		# Ensure node is in tree and has valid path before calling RPC
		if is_inside_tree() and name != "" and get_parent() != null and get_parent().is_inside_tree():
			sync_death_state_rpc.rpc(is_dead)
	
	hero_died.emit()
	print("Hero ", hero_type, " died!")

@rpc("any_peer", "reliable")
func sync_death_state_rpc(dead: bool):
	"""Sync death state to all clients - only server calls this"""
	is_dead = dead
	if is_dead:
		hero_died.emit()

func respawn(spawn_pos: Vector2):
	"""Respawn hero at spawn position - ONLY called on server"""
	# Only server processes respawn
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		return
	
	is_dead = false
	current_health = max_health
	position = spawn_pos
	spawn_protection = 3.0  # 3 seconds of invincibility
	is_invincible = true
	
	# Sync respawn state to all clients (only if node is in tree and properly set up)
	if multiplayer.multiplayer_peer != null:
		# Ensure node is in tree and has valid name before calling RPCs
		if is_inside_tree() and name != "":
			# Ensure parent is also in tree (required for path resolution)
			if get_parent() != null and get_parent().is_inside_tree():
				sync_health_rpc.rpc(current_health, max_health)
				sync_death_state_rpc.rpc(is_dead)
			else:
				# Parent not in tree, wait a frame and try again
				await get_tree().process_frame
				if is_inside_tree() and name != "" and get_parent() != null and get_parent().is_inside_tree():
					sync_health_rpc.rpc(current_health, max_health)
					sync_death_state_rpc.rpc(is_dead)
		else:
			# Node not ready, wait and try again
			await get_tree().process_frame
			if is_inside_tree() and name != "":
				if get_parent() != null and get_parent().is_inside_tree():
					sync_health_rpc.rpc(current_health, max_health)
					sync_death_state_rpc.rpc(is_dead)
	
	health_changed.emit(current_health, max_health)
	print("Hero ", hero_type, " respawned at ", spawn_pos)

func attack_toward_mouse():
	"""Attack toward mouse cursor position"""
	if is_dead or attack_cooldown > 0.0:
		return
	
	var mouse_pos = get_global_mouse_position()
	var attack_dir = (mouse_pos - position).normalized()
	
	# GUESTS: Show animation immediately (client-side prediction), then send to server
	if multiplayer.multiplayer_peer != null and not is_multiplayer_authority():
		# Show visual effects immediately for instant feedback
		_show_attack_visuals(attack_dir)
		# Set local cooldown for UI feedback (server will validate and sync back if different)
		attack_cooldown = 1.0 / attack_speed
		# Send request to server for damage processing
		# Include hero position so server can calculate correct direction relative to server's position
		if is_inside_tree() and name != "" and get_parent() != null and get_parent().is_inside_tree():
			request_attack.rpc(attack_dir, position)  # Send direction and position to server
		return
	
	# SERVER/Authority: Process attack locally and sync to clients
	if multiplayer.multiplayer_peer != null:
		# Server processes attack
		perform_attack_local(attack_dir)
		# Sync to all clients (excluding server)
		if is_inside_tree() and name != "" and get_parent() != null and get_parent().is_inside_tree():
			var peers = multiplayer.get_peers()
			for peer_id in peers:
				perform_attack.rpc_id(peer_id, attack_dir)
			# Sync cooldown to all clients
			sync_attack_cooldown.rpc(attack_cooldown)
	else:
		# Single player - process locally
		perform_attack_local(attack_dir)

@rpc("any_peer", "reliable")
func request_attack(direction: Vector2, guest_hero_pos: Vector2 = Vector2.ZERO):
	"""Guest requests server to perform attack - only server processes this"""
	# Only server processes attack requests
	if not multiplayer.is_server():
		return
	
	# Ensure node is ready
	if not is_inside_tree() or name == "":
		print("Warning: request_attack called but node not ready")
		return
	
	# Server validates cooldown
	if attack_cooldown > 0.0:
		# Still on cooldown - sync cooldown back to guest so they know it was rejected
		if is_inside_tree() and name != "" and get_parent() != null and get_parent().is_inside_tree():
			sync_attack_cooldown.rpc(attack_cooldown)
		return  # Still on cooldown, ignore request
	
	# Adjust direction if guest's position differs from server's position
	# This ensures attack direction is correct relative to server's hero position
	var adjusted_direction = direction
	if guest_hero_pos != Vector2.ZERO and guest_hero_pos.distance_to(position) > 10.0:
		# Guest's position differs significantly - recalculate direction from server's position
		# But we don't have guest's mouse position, so we'll use the direction as-is
		# The direction vector should be fine since it's normalized
		pass
	
	# Server processes the attack
	perform_attack_local(adjusted_direction)
	# Sync result to all clients (excluding server - use rpc_id to send to each client)
	if is_inside_tree() and name != "" and get_parent() != null and get_parent().is_inside_tree():
		# Send to all connected peers except server (peer 1)
		var peers = multiplayer.get_peers()
		for peer_id in peers:
			perform_attack.rpc_id(peer_id, adjusted_direction)
		# Also sync cooldown to all clients
		sync_attack_cooldown.rpc(attack_cooldown)

func perform_attack_local(direction: Vector2):
	"""Perform attack locally - ONLY called on server/authority"""
	# Set attack cooldown (server manages this)
	attack_cooldown = 1.0 / attack_speed
	
	match hero_type:
		"Fighter":
			_melee_attack(direction)
		"Shooter", "Mage":
			_ranged_attack(direction)

@rpc("any_peer", "reliable")
func perform_attack(direction: Vector2):
	"""Server syncs attack to all clients - all clients see visual effects"""
	# Skip if we're the server (server already processed and doesn't need visual sync)
	if multiplayer.is_server():
		return
	
	# This is called on clients to sync visual effects
	# Server already processed damage, clients show visuals
	match hero_type:
		"Fighter":
			_show_melee_indicator(direction)  # Show indicator on clients
		"Shooter", "Mage":
			pass  # Projectiles are spawned by server via spawn_projectile_rpc, clients see them

func _melee_attack(direction: Vector2):
	"""Melee attack - cone/line attack in direction - ONLY called on server"""
	# Only server processes damage
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		return
	
	# Don't show indicator here - it will be shown via perform_attack RPC to all clients
	# This prevents duplicate indicators on server
	
	# Find enemies in attack range and direction
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = attack_range
	query.shape = shape
	query.transform.origin = position
	
	var results = space_state.intersect_shape(query)
	
	for result in results:
		var body = result.collider
		if body.has_method("take_damage") and body != self:
			# Check if it's an enemy hero (different player_id)
			var body_player_id = body.get("player_id")
			if body_player_id == null or body_player_id == player_id:
				continue
			
			# Check if hero is dead
			var body_is_dead = body.get("is_dead")
			if body_is_dead != null and body_is_dead:
				continue
			
			# Check if hero is invincible
			var body_is_invincible = body.get("is_invincible")
			if body_is_invincible != null and body_is_invincible:
				continue
			
			# Check if enemy is in attack direction (cone check)
			var to_enemy = (body.global_position - position).normalized()
			var dot = direction.dot(to_enemy)
			
			# Cone check: enemy must be in front (dot > 0.5 for ~60 degree cone)
			if dot > 0.5:
				var distance = position.distance_to(body.global_position)
				if distance <= attack_range:
					# Server applies damage directly (bypasses RPC)
					if body.has_method("_server_apply_damage"):
						body._server_apply_damage(attack_damage)
					else:
						# Fallback to take_damage if _server_apply_damage doesn't exist
						body.take_damage(attack_damage)

func _show_attack_visuals(direction: Vector2):
	"""Show attack visuals without processing damage (for client-side prediction)"""
	match hero_type:
		"Fighter":
			_show_melee_indicator(direction)
		"Shooter", "Mage":
			# Spawn visual-only projectile (no damage, just visual)
			_spawn_projectile_visual_only(direction)

func _show_melee_indicator(direction: Vector2):
	"""Show visual indicator for melee attack"""
	var indicator_scene = preload("res://scenes/MeleeAttackIndicator.tscn")
	var indicator = null
	
	if indicator_scene:
		indicator = indicator_scene.instantiate()
	else:
		indicator = preload("res://scripts/core/MeleeAttackIndicator.gd").new()
	
	if indicator:
		indicator.setup(attack_range, direction)
		indicator.position = position
		
		# Add to scene tree
		var battle_scene = get_tree().get_first_node_in_group("battle_manager")
		if battle_scene:
			battle_scene.add_child(indicator)
		else:
			get_tree().root.add_child(indicator)

func _show_area_indicator(pos: Vector2, radius_val: float, color: Color = Color(1, 0, 0, 0.5)):
	"""Show visual indicator for area attack"""
	var indicator_scene = preload("res://scenes/AreaAttackIndicator.tscn")
	var indicator = null
	
	if indicator_scene:
		indicator = indicator_scene.instantiate()
	else:
		indicator = preload("res://scripts/core/AreaAttackIndicator.gd").new()
	
	if indicator:
		indicator.setup(radius_val, color)
		indicator.position = pos
		
		# Add to scene tree
		var battle_scene = get_tree().get_first_node_in_group("battle_manager")
		if battle_scene:
			battle_scene.add_child(indicator)
		else:
			get_tree().root.add_child(indicator)

func _ranged_attack(direction: Vector2):
	"""Ranged attack - spawn projectile - ONLY called on server"""
	# Only server spawns projectiles
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		return
	
	# Use a unique spawn ID to prevent duplicates
	var spawn_id = Time.get_ticks_msec()
	
	# Server spawns projectile and syncs to all clients
	if is_inside_tree() and name != "" and get_parent() != null and get_parent().is_inside_tree():
		# Server spawns locally and tells all clients to spawn it too
		var projectile_key = str(player_id) + "_" + str(spawn_id)
		_spawn_projectile_local(direction, position, attack_damage, player_id, _get_projectile_color(), projectile_key)
		# Sync to all clients
		spawn_projectile_rpc.rpc(direction, position, attack_damage, player_id, _get_projectile_color(), spawn_id)
	else:
		# Fallback: spawn locally only if node not ready
		var projectile_key = str(player_id) + "_" + str(spawn_id)
		_spawn_projectile_local(direction, position, attack_damage, player_id, _get_projectile_color(), projectile_key)

# Track spawned projectiles to prevent duplicates
var spawned_projectiles: Dictionary = {}  # owner_id + timestamp -> projectile
var projectile_cleanup_timer: float = 0.0  # Timer for periodic cleanup
var visual_only_projectiles: Dictionary = {}  # Track visual-only projectiles spawned by guests

func _spawn_projectile_local(dir: Vector2, pos: Vector2, dmg: float, owner_id: int, proj_color: Color, spawn_key: String = ""):
	"""Spawn projectile locally (called on all clients via RPC)"""
	# Generate unique identifier for this projectile spawn if not provided
	if spawn_key == "":
		var spawn_time = Time.get_ticks_msec()
		spawn_key = str(owner_id) + "_" + str(spawn_time)
	
	# Check if we already spawned this projectile (prevent duplicates from RPC call_local)
	# If spawn_key exists and has a valid projectile, prevent duplicate
	# If spawn_key exists but value is null, it means spawn_projectile_rpc set a placeholder
	# and we should continue spawning (this is the expected flow)
	if spawned_projectiles.has(spawn_key):
		var existing = spawned_projectiles[spawn_key]
		if existing != null and is_instance_valid(existing):
			print("Duplicate projectile spawn prevented: ", spawn_key)
			return
		# If null, this is expected - spawn_projectile_rpc set the placeholder, continue spawning
		# Don't return here - this is the normal flow
	
	var projectile_scene = preload("res://scenes/Projectile.tscn")
	var projectile = null
	
	if projectile_scene:
		projectile = projectile_scene.instantiate()
	else:
		# Create projectile dynamically if scene doesn't exist
		projectile = preload("res://scripts/core/Projectile.gd").new()
	
	if projectile:
		# Mark as spawned immediately to prevent duplicates
		# Replace the placeholder null with the actual projectile
		spawned_projectiles[spawn_key] = projectile
		
		# Clean up old entries (keep only last 20)
		if spawned_projectiles.size() > 20:
			var oldest_key = spawned_projectiles.keys()[0]
			spawned_projectiles.erase(oldest_key)
		
		# Set position BEFORE adding to scene tree and BEFORE setup
		# This ensures position is set before _ready() is called
		projectile.position = pos
		
		# Set multiplayer authority BEFORE adding to scene tree
		# CRITICAL: Only server should have authority over projectiles
		# This ensures only server controls movement, clients just interpolate
		if multiplayer.multiplayer_peer != null:
			if multiplayer.is_server():
				projectile.set_multiplayer_authority(1)  # Server has authority
			else:
				# Client: set authority to server, but this client won't control it
				# The server will control movement and sync position via RPC
				projectile.set_multiplayer_authority(1)  # Server has authority (even though we're client)
		
		# Add to scene tree FIRST (so _ready() is called with correct position)
		var battle_scene = get_tree().get_first_node_in_group("battle_manager")
		if battle_scene:
			# Check if Projectiles node exists
			var projectiles_node = battle_scene.get_node_or_null("Projectiles")
			if projectiles_node:
				projectiles_node.add_child(projectile, true)  # force_readable_name for network sync
			else:
				battle_scene.add_child(projectile, true)
		else:
			get_tree().root.add_child(projectile, true)
		
		# Wait a frame to ensure node is in tree
		await get_tree().process_frame
		
		# Verify projectile is still valid (not freed during async wait)
		if not is_instance_valid(projectile):
			# Projectile was freed, clean up tracking
			if spawned_projectiles.has(spawn_key):
				spawned_projectiles.erase(spawn_key)
			return
		
		# Now setup the projectile (position is already set)
		projectile.setup(dir, dmg, owner_id, proj_color)
		projectile.visible = true
		
		# Connect to projectile's tree_exited to clean up tracking when freed
		# Use a weak reference approach - check periodically instead of relying on signals
		# (Signals might not fire reliably when nodes are freed)
		
		# Immediately sync initial position to clients if we're the server
		if multiplayer.multiplayer_peer != null and multiplayer.is_server():
			# Wait another frame to ensure projectile is fully initialized
			await get_tree().process_frame
			if is_instance_valid(projectile) and projectile.is_inside_tree() and projectile.name != "":
				projectile.sync_projectile_position.rpc(projectile.position)
		
		# Debug: Verify projectile was created
		var is_server = multiplayer.is_server() if multiplayer.multiplayer_peer != null else false
		var has_authority = projectile.is_multiplayer_authority() if multiplayer.multiplayer_peer != null else true
		print("Projectile spawned: ", spawn_key, " at ", projectile.position, " is_server: ", is_server, " has_authority: ", has_authority, " owner: ", owner_id)
	else:
		# Failed to create projectile, clean up placeholder
		if spawned_projectiles.has(spawn_key):
			spawned_projectiles.erase(spawn_key)


func _spawn_projectile_visual_only(direction: Vector2):
	"""Spawn projectile for visual only (no damage, no server sync) - for client-side prediction"""
	# Generate unique key for visual-only projectile (prefixed with "visual_" to avoid conflicts)
	var spawn_time = Time.get_ticks_msec()
	var visual_key = "visual_" + str(player_id) + "_" + str(spawn_time)
	
	# Check if we already spawned this visual projectile
	if visual_only_projectiles.has(visual_key):
		var existing = visual_only_projectiles[visual_key]
		if existing != null and is_instance_valid(existing):
			return  # Already spawned
	
	# Mark as spawning
	visual_only_projectiles[visual_key] = null
	
	var projectile_scene = preload("res://scenes/Projectile.tscn")
	var projectile = null
	
	if projectile_scene:
		projectile = projectile_scene.instantiate()
	else:
		projectile = preload("res://scripts/core/Projectile.gd").new()
	
	if projectile:
		# Mark as spawned
		visual_only_projectiles[visual_key] = projectile
		
		# Clean up old entries
		if visual_only_projectiles.size() > 10:
			var oldest_key = visual_only_projectiles.keys()[0]
			visual_only_projectiles.erase(oldest_key)
		
		# Set position
		projectile.position = position
		
		# Set as visual-only (no authority, no damage)
		# Visual-only projectiles don't need authority - they're just for display
		projectile.set_multiplayer_authority(0)  # No authority - visual only
		
		# Add to scene tree
		var battle_scene = get_tree().get_first_node_in_group("battle_manager")
		if battle_scene:
			var projectiles_node = battle_scene.get_node_or_null("Projectiles")
			if projectiles_node:
				projectiles_node.add_child(projectile, true)
			else:
				battle_scene.add_child(projectile, true)
		else:
			get_tree().root.add_child(projectile, true)
		
		# Wait a frame
		await get_tree().process_frame
		
		# Verify still valid
		if not is_instance_valid(projectile):
			if visual_only_projectiles.has(visual_key):
				visual_only_projectiles.erase(visual_key)
			return
		
		# Setup projectile (visual only - damage is 0, owner is self for tracking)
		projectile.setup(direction, 0.0, player_id, _get_projectile_color())  # 0 damage - visual only
		projectile.visible = true
		
		# Visual-only projectiles move locally (no server sync needed)
		# They will be replaced by server's real projectile when it arrives
		
		# Clean up when projectile is removed
		if projectile.tree_exited.is_connected(_on_visual_projectile_removed.bind(visual_key)):
			pass  # Already connected
		else:
			projectile.tree_exited.connect(_on_visual_projectile_removed.bind(visual_key))
	else:
		# Failed to create
		if visual_only_projectiles.has(visual_key):
			visual_only_projectiles.erase(visual_key)

func _on_visual_projectile_removed(visual_key: String):
	"""Callback when visual-only projectile is removed"""
	if visual_only_projectiles.has(visual_key):
		visual_only_projectiles.erase(visual_key)

func _cleanup_invalid_projectiles():
	"""Clean up invalid projectiles from tracking dictionary"""
	var keys_to_remove = []
	
	for key in spawned_projectiles.keys():
		var projectile = spawned_projectiles[key]
		# Remove if projectile is null (placeholder) or invalid (freed)
		if projectile == null or not is_instance_valid(projectile):
			keys_to_remove.append(key)
	
	for key in keys_to_remove:
		spawned_projectiles.erase(key)
	
	# Also clean up visual-only projectiles
	keys_to_remove.clear()
	for key in visual_only_projectiles.keys():
		var projectile = visual_only_projectiles[key]
		if projectile == null or not is_instance_valid(projectile):
			keys_to_remove.append(key)
	
	for key in keys_to_remove:
		visual_only_projectiles.erase(key)

func _cleanup_projectile_tracking(owner_id: int):
	"""Clean up old projectile tracking entries for a specific owner"""
	# Remove entries older than 5 seconds or invalid projectiles
	var current_time = Time.get_ticks_msec()
	var keys_to_remove = []
	
	for key in spawned_projectiles.keys():
		var projectile = spawned_projectiles[key]
		# Remove if projectile is invalid (freed)
		if projectile != null and not is_instance_valid(projectile):
			keys_to_remove.append(key)
			continue
		
		# Extract timestamp from key (format: "owner_id_timestamp")
		var parts = key.split("_")
		if parts.size() >= 2:
			var timestamp = int(parts[-1])
			if current_time - timestamp > 5000:  # 5 seconds old
				keys_to_remove.append(key)
	
	for key in keys_to_remove:
		spawned_projectiles.erase(key)

@rpc("any_peer", "reliable")
func spawn_projectile_rpc(direction: Vector2, spawn_pos: Vector2, dmg: float, owner_id: int, proj_color: Color, spawn_id: int = 0):
	"""Server tells clients to spawn projectile - all clients display it"""
	# Use spawn_id to create unique key for duplicate prevention
	var projectile_key = str(owner_id) + "_" + str(spawn_id)
	
	# Check if we already spawned this projectile (prevent duplicates)
	if spawned_projectiles.has(projectile_key):
		var existing = spawned_projectiles[projectile_key]
		if existing != null and is_instance_valid(existing):
			return  # Already spawned
		# If null, we're in the middle of spawning, also prevent duplicate
		return
	
	# Mark as spawning IMMEDIATELY to prevent race conditions
	spawned_projectiles[projectile_key] = null  # Placeholder
	
	# All clients spawn projectile for visual display
	# Server already spawned it with authority, clients just show it
	_spawn_projectile_local(direction, spawn_pos, dmg, owner_id, proj_color, projectile_key)

func _get_projectile_color() -> Color:
	"""Get projectile color based on hero type"""
	match hero_type:
		"Shooter":
			return Color.GREEN
		"Mage":
			return Color.RED
		_:
			return Color.YELLOW

func use_ability_q():
	"""Use Q ability"""
	if is_dead:
		return
	
	# GUESTS: Only send RPC to server, don't process locally
	if multiplayer.multiplayer_peer != null and not is_multiplayer_authority():
		# Guest: Send ability request to server with mouse position
		# Use rpc() instead of rpc_id() - Godot will route to server automatically
		if is_inside_tree() and name != "" and get_parent() != null and get_parent().is_inside_tree():
			var mouse_pos = get_global_mouse_position()
			request_ability.rpc("q", mouse_pos)  # Send ability name and mouse position
		return
	
	# SERVER/Authority: Check cooldown and process ability
	if ability_q_cooldown > 0.0:
		return  # Still on cooldown
	
	# Server processes ability
	if multiplayer.multiplayer_peer != null:
		_execute_ability_q()
		# Sync to all clients (excluding server)
		if is_inside_tree() and name != "" and get_parent() != null and get_parent().is_inside_tree():
			var peers = multiplayer.get_peers()
			for peer_id in peers:
				use_ability.rpc_id(peer_id, "q")
			# Sync cooldown
			sync_ability_cooldown.rpc("q", ability_q_cooldown)
	else:
		# Single player - process locally
		_execute_ability_q()

func _execute_ability_q():
	"""Execute Q ability - ONLY called on server/authority"""
	_execute_ability_q_with_mouse(get_global_mouse_position())

func _execute_ability_q_with_mouse(mouse_pos: Vector2):
	"""Execute Q ability with specific mouse position - ONLY called on server"""
	match hero_type:
		"Fighter":
			ability_dash_with_mouse(mouse_pos)
		"Shooter":
			ability_rapid_fire()
		"Mage":
			ability_fireball_with_mouse(mouse_pos)
	
	ability_q_cooldown = ability_q_max_cooldown

func use_ability_e():
	"""Use E ability"""
	if is_dead:
		return
	
	# GUESTS: Only send RPC to server, don't process locally
	if multiplayer.multiplayer_peer != null and not is_multiplayer_authority():
		# Guest: Send ability request to server with mouse position
		# Use rpc() instead of rpc_id() - Godot will route to server automatically
		if is_inside_tree() and name != "" and get_parent() != null and get_parent().is_inside_tree():
			var mouse_pos = get_global_mouse_position()
			request_ability.rpc("e", mouse_pos)  # Send ability name and mouse position
		return
	
	# SERVER/Authority: Check cooldown and process ability
	if ability_e_cooldown > 0.0:
		return  # Still on cooldown
	
	# Server processes ability
	if multiplayer.multiplayer_peer != null:
		_execute_ability_e()
		# Sync to all clients (excluding server)
		if is_inside_tree() and name != "" and get_parent() != null and get_parent().is_inside_tree():
			var peers = multiplayer.get_peers()
			for peer_id in peers:
				use_ability.rpc_id(peer_id, "e")
			# Sync cooldown
			sync_ability_cooldown.rpc("e", ability_e_cooldown)
	else:
		# Single player - process locally
		_execute_ability_e()

func _execute_ability_e():
	"""Execute E ability - ONLY called on server/authority"""
	_execute_ability_e_with_mouse(get_global_mouse_position())

func _execute_ability_e_with_mouse(mouse_pos: Vector2):
	"""Execute E ability with specific mouse position - ONLY called on server"""
	match hero_type:
		"Fighter":
			ability_shield_bash()
		"Shooter":
			ability_pushback()
		"Mage":
			ability_teleport_with_mouse(mouse_pos)
	
	ability_e_cooldown = ability_e_max_cooldown

@rpc("any_peer", "reliable")
func request_ability(ability: String, mouse_position: Vector2 = Vector2.ZERO):
	"""Guest requests server to use ability - only server processes this"""
	# Only server processes ability requests
	if not multiplayer.is_server():
		return
	
	# Ensure node is ready
	if not is_inside_tree() or name == "":
		print("Warning: request_ability called but node not ready")
		return
	
	# Store guest's mouse position for abilities that need it
	var stored_mouse_pos = mouse_position if mouse_position != Vector2.ZERO else get_global_mouse_position()
	
	# Server validates cooldown
	match ability:
		"q":
			if ability_q_cooldown > 0.0:
				# Still on cooldown - sync cooldown back
				if is_inside_tree() and name != "" and get_parent() != null and get_parent().is_inside_tree():
					sync_ability_cooldown.rpc("q", ability_q_cooldown)
				return  # Still on cooldown, ignore request
			_execute_ability_q_with_mouse(stored_mouse_pos)
		"e":
			if ability_e_cooldown > 0.0:
				# Still on cooldown - sync cooldown back
				if is_inside_tree() and name != "" and get_parent() != null and get_parent().is_inside_tree():
					sync_ability_cooldown.rpc("e", ability_e_cooldown)
				return  # Still on cooldown, ignore request
			_execute_ability_e_with_mouse(stored_mouse_pos)
	
	# Sync result to all clients
	if is_inside_tree() and name != "" and get_parent() != null and get_parent().is_inside_tree():
		# Send to all connected peers except server
		var peers = multiplayer.get_peers()
		for peer_id in peers:
			use_ability.rpc_id(peer_id, ability)
		# Sync cooldowns to all clients
		match ability:
			"q":
				sync_ability_cooldown.rpc("q", ability_q_cooldown)
			"e":
				sync_ability_cooldown.rpc("e", ability_e_cooldown)

@rpc("any_peer", "reliable")
func use_ability(ability: String):
	"""Server syncs ability to all clients - all clients show visual effects"""
	# Skip if we're the server (server already processed and doesn't need visual sync)
	if multiplayer.is_server():
		return
	
	# This is called on clients to sync visual effects
	# Server already processed damage/movement, clients show visuals
	match ability:
		"q":
			match hero_type:
				"Fighter":
					# Dash visual - position change is synced via network_position
					pass  # Position sync happens automatically
				"Shooter":
					# Rapid fire visual effect - show green outline
					var visual = get_node_or_null("Visual")
					if visual is Polygon2D:
						visual.color = Color.GREEN
				"Mage":
					# Fireball visual handled by server spawning projectile
					pass
		"e":
			match hero_type:
				"Fighter":
					# Show shield bash indicator (visual only)
					_show_area_indicator(position, 150.0, Color(1, 0.5, 0, 0.5))
				"Shooter":
					# Pushback visual - position change is synced via network_position
					pass  # Position sync happens automatically
				"Mage":
					# Teleport visual - position change is synced via network_position
					pass  # Position sync happens automatically

# Fighter Abilities
func ability_dash():
	"""Fighter Q: Dash to mouse position - ONLY called on server"""
	ability_dash_with_mouse(get_global_mouse_position())

func ability_dash_with_mouse(mouse_pos: Vector2):
	"""Fighter Q: Dash to specified mouse position - ONLY called on server"""
	# Only server processes movement
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		return
	
	var dash_distance = 300.0
	var dash_dir = (mouse_pos - position).normalized()
	var dash_target = position + dash_dir * dash_distance
	
	# Clamp to screen bounds
	dash_target.x = clamp(dash_target.x, HERO_RADIUS, SCREEN_WIDTH - HERO_RADIUS)
	dash_target.y = clamp(dash_target.y, HERO_RADIUS, SCREEN_HEIGHT - HERO_RADIUS)
	
	position = dash_target
	network_position = dash_target  # Update network position for sync
	
	# Explicitly sync position to all clients
	if multiplayer.multiplayer_peer != null:
		if is_inside_tree() and name != "" and get_parent() != null and get_parent().is_inside_tree():
			sync_position.rpc(dash_target)

func ability_shield_bash():
	"""Fighter E: Area damage around hero - ONLY called on server"""
	# Only server processes damage
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		return
	
	var bash_radius = 150.0
	var bash_damage = attack_damage * 1.5
	
	# Show area indicator (visual - clients see this via use_ability RPC)
	_show_area_indicator(position, bash_radius, Color(1, 0.5, 0, 0.5))  # Orange
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = bash_radius
	query.shape = shape
	query.transform.origin = position
	
	var results = space_state.intersect_shape(query)
	
	for result in results:
		var body = result.collider
		if body.has_method("take_damage") and body != self:
			# Check if it's an enemy hero (different player_id)
			var body_player_id = body.get("player_id")
			if body_player_id == null or body_player_id == player_id:
				continue
			
			# Check if hero is dead
			var body_is_dead = body.get("is_dead")
			if body_is_dead != null and body_is_dead:
				continue
			
			# Check if hero is invincible
			var body_is_invincible = body.get("is_invincible")
			if body_is_invincible != null and body_is_invincible:
				continue
			
			var distance = position.distance_to(body.global_position)
			if distance <= bash_radius:
				# Server applies damage directly (bypasses RPC)
				if body.has_method("_server_apply_damage"):
					body._server_apply_damage(bash_damage)
				else:
					# Fallback to take_damage if _server_apply_damage doesn't exist
					body.take_damage(bash_damage)

# Shooter Abilities
var rapid_fire_active: bool = false
var rapid_fire_timer: float = 0.0

func ability_rapid_fire():
	"""Shooter Q: Temporary attack speed buff - ONLY called on server"""
	# Only server processes buffs
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		return
	
	rapid_fire_active = true
	rapid_fire_timer = 5.0
	attack_speed *= 2.0  # Double attack speed
	
	# Visual indicator (green outline) - sync to clients via use_ability RPC
	var visual = get_node_or_null("Visual")
	if visual is Polygon2D:
		visual.color = Color.GREEN

func ability_pushback():
	"""Shooter E: Push nearest enemy away - ONLY called on server"""
	# Only server processes movement
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		return
	
	var push_radius = 400.0
	var push_force = 200.0
	
	# Find nearest enemy
	var nearest_enemy = null
	var nearest_distance = INF
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = push_radius
	query.shape = shape
	query.transform.origin = position
	
	var results = space_state.intersect_shape(query)
	
	for result in results:
		var body = result.collider
		if body.has_method("take_damage") and body != self:
			# Check if it's an enemy hero (different player_id)
			var body_player_id = body.get("player_id")
			if body_player_id == null or body_player_id == player_id:
				continue
			
			var distance = position.distance_to(body.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_enemy = body
	
	if nearest_enemy:
		# Push enemy away
		var push_dir = (nearest_enemy.global_position - position).normalized()
		var push_target = nearest_enemy.global_position + push_dir * push_force
		
		# Clamp to screen bounds
		push_target.x = clamp(push_target.x, HERO_RADIUS, SCREEN_WIDTH - HERO_RADIUS)
		push_target.y = clamp(push_target.y, HERO_RADIUS, SCREEN_HEIGHT - HERO_RADIUS)
		
		nearest_enemy.position = push_target
		nearest_enemy.network_position = push_target  # Update network position for sync
		
		# Explicitly sync position to all clients if enemy is a hero
		if nearest_enemy.has_method("sync_position") and multiplayer.multiplayer_peer != null:
			if nearest_enemy.is_inside_tree() and nearest_enemy.name != "" and nearest_enemy.get_parent() != null and nearest_enemy.get_parent().is_inside_tree():
				nearest_enemy.sync_position.rpc(push_target)

# Mage Abilities
func ability_fireball():
	"""Mage Q: Area damage at target location - ONLY called on server"""
	ability_fireball_with_mouse(get_global_mouse_position())

func ability_fireball_with_mouse(mouse_pos: Vector2):
	"""Mage Q: Area damage at specified mouse position - ONLY called on server"""
	# Only server processes damage
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		return
	
	var fireball_radius = 100.0
	var fireball_damage = attack_damage * 2.0
	
	# Show area indicator at target location (visual - clients see this via use_ability RPC)
	_show_area_indicator(mouse_pos, fireball_radius, Color(1, 0, 0, 0.5))  # Red
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = fireball_radius
	query.shape = shape
	query.transform.origin = mouse_pos
	
	var results = space_state.intersect_shape(query)
	
	for result in results:
		var body = result.collider
		if body.has_method("take_damage") and body != self:
			# Check if it's an enemy hero (different player_id)
			var body_player_id = body.get("player_id")
			if body_player_id == null or body_player_id == player_id:
				continue
			
			# Check if hero is dead
			var body_is_dead = body.get("is_dead")
			if body_is_dead != null and body_is_dead:
				continue
			
			# Check if hero is invincible
			var body_is_invincible = body.get("is_invincible")
			if body_is_invincible != null and body_is_invincible:
				continue
			
			var distance = mouse_pos.distance_to(body.global_position)
			if distance <= fireball_radius:
				# Server applies damage directly (bypasses RPC)
				if body.has_method("_server_apply_damage"):
					body._server_apply_damage(fireball_damage)
				else:
					# Fallback to take_damage if _server_apply_damage doesn't exist
					body.take_damage(fireball_damage)

func ability_teleport():
	"""Mage E: Instant movement to nearby location - ONLY called on server"""
	ability_teleport_with_mouse(get_global_mouse_position())

func ability_teleport_with_mouse(mouse_pos: Vector2):
	"""Mage E: Instant movement to specified mouse position - ONLY called on server"""
	# Only server processes movement
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		return
	
	var teleport_distance = 300.0
	var teleport_dir = (mouse_pos - position).normalized()
	var teleport_target = position + teleport_dir * teleport_distance
	
	# Clamp to screen bounds
	teleport_target.x = clamp(teleport_target.x, HERO_RADIUS, SCREEN_WIDTH - HERO_RADIUS)
	teleport_target.y = clamp(teleport_target.y, HERO_RADIUS, SCREEN_HEIGHT - HERO_RADIUS)
	
	position = teleport_target
	network_position = teleport_target  # Update network position for sync
	
	# Explicitly sync position to all clients
	if multiplayer.multiplayer_peer != null:
		if is_inside_tree() and name != "" and get_parent() != null and get_parent().is_inside_tree():
			sync_position.rpc(teleport_target)

@rpc("any_peer", "call_local", "reliable")
func spawn_damage_number(amount: float):
	"""Spawn damage number (called when damage is taken)"""
	if not is_inside_tree():
		return
	
	var damage_number_scene = preload("res://scenes/DamageNumber.tscn")
	var damage_num = null
	
	if damage_number_scene:
		damage_num = damage_number_scene.instantiate()
	else:
		# Create dynamically if scene doesn't exist
		damage_num = preload("res://scripts/ui/DamageNumber.gd").new()
	
	if damage_num:
		damage_num.setup(amount, global_position + Vector2(0, -40))
		
		# Add to scene tree
		var battle_scene = get_tree().get_first_node_in_group("battle_manager")
		if battle_scene:
			battle_scene.add_child(damage_num)
		else:
			get_tree().root.add_child(damage_num)
