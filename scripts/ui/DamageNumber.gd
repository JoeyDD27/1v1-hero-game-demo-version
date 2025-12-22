extends Label

var lifetime: float = 1.0
var fade_time: float = 0.8
var move_speed: float = 50.0

func _ready():
	add_theme_font_size_override("font_size", 24)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	modulate = Color(1, 1, 1, 1)

func setup(damage: float, position: Vector2):
	"""Setup damage number"""
	text = str(int(damage))
	global_position = position
	lifetime = 1.0

func _process(delta):
	lifetime -= delta
	
	if lifetime <= 0:
		queue_free()
		return
	
	# Move upward
	position.y -= move_speed * delta
	
	# Fade out
	if lifetime < fade_time:
		var alpha = lifetime / fade_time
		modulate.a = alpha
