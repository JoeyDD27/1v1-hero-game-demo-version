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
	
	# Set up visual
	if not has_node("Visual"):
		var visual = Polygon2D.new()
		visual.name = "Visual"
		visual.color = Color.YELLOW
		var points = PackedVector2Array()
		var point_count = 16
		for i in range(point_count):
			var angle = (i * 2.0 * PI) / point_count
			points.append(Vector2(cos(angle) * PROJECTILE_RADIUS, sin(angle) * PROJECTILE_RADIUS))
		visual.polygon = points
		add_child(visual)

func setup(dir: Vector2, dmg: float, owner_id: int, projectile_color: Color = Color.YELLOW):
	"""Setup projectile"""
	direction = dir.normalized()
	damage = dmg
	owner_peer_id = owner_id
	
	# Set visual color
	var visual = get_node_or_null("Visual")
	if visual is Polygon2D:
		visual.color = projectile_color

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
			if body.has("player_id") and body.player_id != owner_peer_id:
				if not body.has("is_invincible") or not body.is_invincible:
					body.take_damage(damage)
					queue_free()
					return
