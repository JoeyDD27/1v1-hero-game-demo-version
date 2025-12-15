extends Node2D

## BattleManager handles battle logic, hero switching, and win conditions

const Hero = preload("res://scripts/core/Hero.gd")

signal hero_died(hero: Hero)
signal player_defeated(player_id: int)
signal game_won(winner_id: int)

var player_heroes: Dictionary = {}  # player_id -> array of heroes
var current_hero: Dictionary = {}  # player_id -> current hero
var heroes_per_player: int = 3

func _ready():
	# This will be set up when heroes are spawned
	pass

func register_player_heroes(player_id: int, heroes: Array):
	"""Register a player's heroes"""
	player_heroes[player_id] = heroes
	if heroes.size() > 0:
		current_hero[player_id] = heroes[0]
		_setup_hero_signals(heroes[0])

func _setup_hero_signals(hero: Hero):
	"""Connect hero signals"""
	if hero:
		hero.hero_died.connect(_on_hero_died.bind(hero))

func _on_hero_died(hero: Hero):
	"""Handle hero death"""
	hero_died.emit(hero)
	
	# Find which player owns this hero
	var player_id = -1
	for pid in player_heroes:
		if hero in player_heroes[pid]:
			player_id = pid
			break
	
	if player_id == -1:
		return
	
	# Check if player has remaining heroes
	var remaining_heroes = []
	for h in player_heroes[player_id]:
		if h != hero and not h.is_dead:
			remaining_heroes.append(h)
	
	if remaining_heroes.size() == 0:
		# Player is defeated
		player_defeated.emit(player_id)
		_check_win_condition()
	else:
		# Switch to next hero
		current_hero[player_id] = remaining_heroes[0]
		_setup_hero_signals(remaining_heroes[0])

func _check_win_condition():
	"""Check if game should end"""
	var alive_players = []
	
	for player_id in player_heroes:
		var has_alive_hero = false
		for hero in player_heroes[player_id]:
			if not hero.is_dead:
				has_alive_hero = true
				break
		
		if has_alive_hero:
			alive_players.append(player_id)
	
	# If only one player has alive heroes, they win
	if alive_players.size() == 1:
		game_won.emit(alive_players[0])
	elif alive_players.size() == 0:
		# Draw (shouldn't happen, but handle it)
		game_won.emit(-1)

