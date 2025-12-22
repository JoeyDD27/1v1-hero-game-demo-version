extends Node2D

@onready var background_bar: ColorRect = $BackgroundBar
@onready var health_bar: ColorRect = $HealthBar

var hero: Node2D = null
var max_health: float = 100.0
var current_health: float = 100.0

const BAR_WIDTH = 60.0
const BAR_HEIGHT = 8.0
const OFFSET_Y = -50.0  # Position above hero

func _ready():
	add_to_group("health_bars")
	
	# Create background bar if not exists
	if not has_node("BackgroundBar"):
		background_bar = ColorRect.new()
		background_bar.name = "BackgroundBar"
		background_bar.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
		background_bar.position = Vector2(-BAR_WIDTH / 2, OFFSET_Y)
		background_bar.color = Color(0.2, 0, 0, 1)  # Dark red
		add_child(background_bar)
	
	# Create health bar if not exists
	if not has_node("HealthBar"):
		health_bar = ColorRect.new()
		health_bar.name = "HealthBar"
		health_bar.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
		health_bar.position = Vector2(-BAR_WIDTH / 2, OFFSET_Y)
		health_bar.color = Color(0, 1, 0, 1)  # Green
		add_child(health_bar)

func setup(hero_node: Node2D, max_hp: float):
	"""Setup health bar for a hero"""
	hero = hero_node
	max_health = max_hp
	current_health = max_hp
	update_health_bar()

func update_health(health: float, max_hp: float):
	"""Update health bar values"""
	current_health = health
	max_health = max_hp
	update_health_bar()

func update_health_bar():
	"""Update visual health bar"""
	if not health_bar:
		return
	
	var health_percentage = current_health / max_health if max_health > 0 else 0.0
	health_percentage = clamp(health_percentage, 0.0, 1.0)
	
	# Update health bar width
	health_bar.size.x = BAR_WIDTH * health_percentage
	
	# Change color based on health percentage
	if health_percentage > 0.6:
		health_bar.color = Color(0, 1, 0, 1)  # Green
	elif health_percentage > 0.3:
		health_bar.color = Color(1, 1, 0, 1)  # Yellow
	else:
		health_bar.color = Color(1, 0, 0, 1)  # Red

func _process(_delta):
	# Keep health bar positioned above hero
	if hero and is_instance_valid(hero):
		global_position = hero.global_position
	else:
		queue_free()

