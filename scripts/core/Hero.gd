extends CharacterBody2D

## Base Hero class - all heroes inherit from this
## Handles movement, health, and basic combat

signal health_changed(current_health: int, max_health: int)
signal hero_died

enum HeroType {
	FIGHTER,
	SHOOTER,
	MAGE
}

@export var hero_type: HeroType = HeroType.FIGHTER
@export var max_health: int = 100
@export var move_speed: float = 200.0
@export var attack_range: float = 100.0
@export var attack_damage: int = 10
@export var attack_cooldown: float = 1.0

var current_health: int
var attack_timer: float = 0.0
var is_dead: bool = false

# Visual
@onready var sprite: ColorRect = $Sprite
@onready var health_bar: Control = $HealthBar

func _ready():
	current_health = max_health
	_setup_visuals()
	_setup_health_bar()

func _setup_visuals():
	"""Set up hero visual based on type"""
	if not sprite:
		sprite = ColorRect.new()
		sprite.name = "Sprite"
		add_child(sprite)
	
	match hero_type:
		HeroType.FIGHTER:
			sprite.color = Color.BLUE
			sprite.size = Vector2(40, 40)  # Larger
		HeroType.SHOOTER:
			sprite.color = Color.GREEN
			sprite.size = Vector2(30, 30)  # Medium
		HeroType.MAGE:
			sprite.color = Color.RED
			sprite.size = Vector2(25, 25)  # Smaller
	
	sprite.position = -sprite.size / 2  # Center the sprite

func _setup_health_bar():
	"""Create health bar above hero"""
	if not health_bar:
		health_bar = Control.new()
		health_bar.name = "HealthBar"
		add_child(health_bar)
	
	var bar_bg = ColorRect.new()
	bar_bg.name = "Background"
	bar_bg.color = Color(0.2, 0.2, 0.2)
	bar_bg.size = Vector2(50, 6)
	bar_bg.position = Vector2(-25, -30)
	health_bar.add_child(bar_bg)
	
	var bar_fill = ColorRect.new()
	bar_fill.name = "Fill"
	bar_fill.color = Color.GREEN
	bar_fill.size = Vector2(50, 6)
	bar_fill.position = Vector2(-25, -30)
	health_bar.add_child(bar_fill)
	
	_update_health_bar()

func _update_health_bar():
	"""Update health bar visual"""
	if not health_bar:
		return
	
	var fill = health_bar.get_node("Fill")
	if fill:
		var health_percent = float(current_health) / float(max_health)
		fill.size.x = 50 * health_percent
		
		# Change color based on health
		if health_percent > 0.6:
			fill.color = Color.GREEN
		elif health_percent > 0.3:
			fill.color = Color.YELLOW
		else:
			fill.color = Color.RED

func take_damage(amount: int):
	"""Take damage and check for death"""
	if is_dead:
		return
	
	current_health -= amount
	current_health = max(0, current_health)
	
	health_changed.emit(current_health, max_health)
	_update_health_bar()
	
	if current_health <= 0:
		die()

func die():
	"""Handle hero death"""
	if is_dead:
		return
	
	is_dead = true
	hero_died.emit()
	visible = false
	collision_layer = 0  # Disable collisions

func heal(amount: int):
	"""Heal the hero"""
	if is_dead:
		return
	
	current_health += amount
	current_health = min(current_health, max_health)
	health_changed.emit(current_health, max_health)
	_update_health_bar()

func _process(delta):
	if attack_timer > 0:
		attack_timer -= delta

func can_attack() -> bool:
	return attack_timer <= 0.0 and not is_dead

func start_attack_cooldown():
	attack_timer = attack_cooldown

