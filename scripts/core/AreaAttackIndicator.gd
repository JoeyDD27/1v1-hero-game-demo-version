extends Node2D

var radius: float = 100.0
var lifetime: float = 0.3  # Show for 0.3 seconds
var indicator_color: Color = Color(1, 0, 0, 0.5)  # Red, semi-transparent

func _ready():
	# Create visual indicator (circle)
	_draw_area_indicator()

func _draw_area_indicator():
	"""Draw area attack indicator as a circle"""
	var points = PackedVector2Array()
	var point_count = 32
	
	# Create circle polygon
	for i in range(point_count):
		var angle = (i * 2.0 * PI) / point_count
		var point = Vector2(cos(angle) * radius, sin(angle) * radius)
		points.append(point)
	
	# Create Polygon2D for the circle
	var polygon = Polygon2D.new()
	polygon.polygon = points
	polygon.color = indicator_color
	polygon.name = "AreaIndicator"
	add_child(polygon)
	
	# Add outline for better visibility
	var outline_points = PackedVector2Array()
	for i in range(point_count):
		var angle = (i * 2.0 * PI) / point_count
		var point = Vector2(cos(angle) * (radius + 3), sin(angle) * (radius + 3))
		outline_points.append(point)
	
	var outline = Polygon2D.new()
	outline.polygon = outline_points
	outline.color = indicator_color.darkened(0.3)
	outline.name = "Outline"
	add_child(outline)

func setup(radius_val: float, color: Color = Color(1, 0, 0, 0.5)):
	"""Setup area indicator"""
	radius = radius_val
	indicator_color = color
	_draw_area_indicator()

func _process(delta):
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

