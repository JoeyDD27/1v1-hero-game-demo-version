extends Node2D

var attack_range: float = 120.0
var attack_direction: Vector2 = Vector2.RIGHT
var lifetime: float = 0.2  # Show for 0.2 seconds

func _ready():
	# Create visual indicator (cone/arc)
	_draw_attack_indicator()

func _draw_attack_indicator():
	"""Draw melee attack indicator as a cone"""
	var points = PackedVector2Array()
	var angle_span = PI / 3.0  # 60 degree cone
	var point_count = 16
	
	# Add center point
	points.append(Vector2.ZERO)
	
	# Add arc points
	for i in range(point_count + 1):
		var angle = -angle_span / 2.0 + (i * angle_span / point_count)
		var dir = Vector2(cos(angle), sin(angle))
		var point = dir * attack_range
		points.append(point)
	
	# Create Polygon2D for the cone
	var polygon = Polygon2D.new()
	polygon.polygon = points
	polygon.color = Color(1, 0.5, 0, 0.5)  # Orange, semi-transparent
	polygon.name = "AttackIndicator"
	add_child(polygon)
	
	# Rotate to face attack direction
	var angle = attack_direction.angle()
	rotation = angle

func setup(range_val: float, direction: Vector2):
	"""Setup attack indicator"""
	attack_range = range_val
	attack_direction = direction.normalized()
	_draw_attack_indicator()

func _process(delta):
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

