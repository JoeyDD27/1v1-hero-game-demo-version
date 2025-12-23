extends CharacterBody2D

@export var damage: float = 50.0
@export var speed: float = 800.0
@export var max_distance: float = 1000.0

var direction: Vector2 = Vector2.ZERO
var start_position: Vector2 = Vector2.ZERO
var owner_peer_id: int = 0

const PROJECTILE_RADIUS = 5.0

func _ready():
	start_position = position
	
	# Set up collision
	if not has_node("CollisionShape2D"):
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = PROJECTILE_RADIUS
		collision.shape = shape
		add_child(collision)
	
	# Set up visual - make it more visible
	if not has_node("Visual"):
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
		for i in range(point_count):
			var angle = (i * 2.0 * PI) / point_count
			outline_points.append(Vector2(cos(angle) * (PROJECTILE_RADIUS + 2), sin(angle) * (PROJECTILE_RADIUS + 2)))
		outline.polygon = outline_points
		add_child(outline)

func setup(dir: Vector2, dmg: float, owner_id: int, projectile_color: Color = Color.YELLOW):
	"""Setup projectile"""
	direction = dir.normalized()
	damage = dmg
	owner_peer_id = owner_id
	
	# Set visual color
	var visual = get_node_or_null("Visual")
	if visual is Polygon2D:
		visual.color = projectile_color
	
	# Update outline color to match
	var outline = get_node_or_null("Outline")
	if outline is Polygon2D:
		# Make outline slightly darker version of projectile color
		outline.color = projectile_color.darkened(0.3)

func _physics_process(delta):
	# Move projectile
	velocity = direction * speed
	move_and_slide()
	
	# Check if traveled too far
	if position.distance_to(start_position) > max_distance:
		queue_free()
		return
	
	# Check collision with enemies
	_check_collisions()

func _check_collisions():
	"""Check for collisions with enemies"""
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = PROJECTILE_RADIUS * 2
	query.shape = shape
	query.transform.origin = position
	
	var results = space_state.intersect_shape(query)
	
	for result in results:
		var body = result.collider
		if body.has_method("take_damage") and body != self:
			# Make sure it's an enemy hero
			# Check if body has player_id property (using get() instead of has())
			var body_player_id = body.get("player_id")
			if body_player_id != null and body_player_id != owner_peer_id:
				# Check if hero is dead before checking invincibility
				var is_dead = body.get("is_dead")
				if is_dead == null or not is_dead:
					# Check invincibility
					var is_invincible = body.get("is_invincible")
					if is_invincible == null or not is_invincible:
						body.take_damage(damage)
						queue_free()
						return
