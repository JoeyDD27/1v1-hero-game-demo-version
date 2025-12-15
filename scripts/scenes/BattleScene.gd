extends Node2D

## BattleScene - main battle arena scene

const Hero = preload("res://scripts/core/Hero.gd")
const PlayerController = preload("res://scripts/controllers/PlayerController.gd")
const BattleManager = preload("res://scripts/managers/BattleManager.gd")

@onready var battle_manager: BattleManager = $BattleManager
@onready var arena: ColorRect = $Arena

var hero_scene = preload("res://scenes/Hero.tscn")

func _ready():
	_setup_arena()
	_spawn_heroes()

func _setup_arena():
	"""Set up the battle arena"""
	if not arena:
		arena = ColorRect.new()
		arena.name = "Arena"
		add_child(arena)
	
	arena.color = Color(0.3, 0.3, 0.25)  # Gray/beige background
	arena.size = Vector2(1200, 600)
	arena.position = Vector2(40, 40)

func _spawn_heroes():
	"""Spawn heroes for both players"""
	# For demo: spawn 3 heroes per player
	# Player 1 (host/server) spawns on left
	# Player 2 (client) spawns on right
	
	var player1_id = 1
	var player2_id = 2
	
	var player1_heroes = []
	var player2_heroes = []
	
	# Spawn Player 1 heroes (left side)
	for i in range(3):
		var hero = _create_hero(Hero.HeroType.FIGHTER if i == 0 else Hero.HeroType.SHOOTER if i == 1 else Hero.HeroType.MAGE)
		hero.position = Vector2(200 + i * 50, 300)
		hero.name = "Player1_Hero" + str(i + 1)
		add_child(hero)
		player1_heroes.append(hero)
	
	# Spawn Player 2 heroes (right side)
	for i in range(3):
		var hero = _create_hero(Hero.HeroType.FIGHTER if i == 0 else Hero.HeroType.SHOOTER if i == 1 else Hero.HeroType.MAGE)
		hero.position = Vector2(1000 + i * 50, 300)
		hero.name = "Player2_Hero" + str(i + 1)
		add_child(hero)
		player2_heroes.append(hero)
	
	# Register heroes with battle manager
	battle_manager.register_player_heroes(player1_id, player1_heroes)
	battle_manager.register_player_heroes(player2_id, player2_heroes)
	
	# Set up PlayerController for local player
	# In Quick Start mode (no multiplayer), use player 1
	var local_player_id = 1
	if multiplayer.multiplayer_peer != null:
		local_player_id = 1 if multiplayer.is_server() else 2
	
	var heroes = player1_heroes if local_player_id == 1 else player2_heroes
	
	if heroes.size() > 0:
		var controller = PlayerController.new()
		controller.hero = heroes[0]
		add_child(controller)

func _create_hero(type: Hero.HeroType) -> Hero:
	"""Create a hero instance"""
	var hero = Hero.new()
	hero.hero_type = type
	
	# Set stats based on type
	match type:
		Hero.HeroType.FIGHTER:
			hero.max_health = 150
			hero.move_speed = 180.0
			hero.attack_range = 50.0
			hero.attack_damage = 15
		Hero.HeroType.SHOOTER:
			hero.max_health = 100
			hero.move_speed = 220.0
			hero.attack_range = 200.0
			hero.attack_damage = 12
		Hero.HeroType.MAGE:
			hero.max_health = 80
			hero.move_speed = 200.0
			hero.attack_range = 150.0
			hero.attack_damage = 10
	
	return hero

