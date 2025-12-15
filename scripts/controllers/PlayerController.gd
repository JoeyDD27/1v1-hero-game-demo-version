extends Node

## PlayerController handles player input and controls the hero
## Supports WASD movement and network synchronization

const Hero = preload("res://scripts/core/Hero.gd")

@export var hero: Hero
var move_direction: Vector2 = Vector2.ZERO
var is_local_player: bool = false

func _ready():
	if not hero:
		push_error("PlayerController: No hero assigned!")
		return
	
	# Set this as local player if we're the multiplayer authority
	# In Quick Start mode (no multiplayer), always local
	if multiplayer.multiplayer_peer == null:
		is_local_player = true
	else:
		is_local_player = multiplayer.is_server() or multiplayer.get_unique_id() == 1

func _process(delta):
	if not hero or hero.is_dead:
		return
	
	# Only process input for local player
	if not is_local_player:
		return
	
	_handle_movement_input()
	_handle_ability_input()
	_handle_support_input()
	_handle_big_spell_input()

func _handle_movement_input():
	"""Handle WASD movement input"""
	move_direction = Vector2.ZERO
	
	if Input.is_action_pressed("move_up"):
		move_direction.y -= 1
	if Input.is_action_pressed("move_down"):
		move_direction.y += 1
	if Input.is_action_pressed("move_left"):
		move_direction.x -= 1
	if Input.is_action_pressed("move_right"):
		move_direction.x += 1
	
	move_direction = move_direction.normalized()
	
	# Move hero
	if move_direction != Vector2.ZERO:
		hero.velocity = move_direction * hero.move_speed
		hero.move_and_slide()
		
		# Sync position over network (only if multiplayer is active)
		if multiplayer.multiplayer_peer != null:
			if multiplayer.is_server():
				update_hero_position.rpc(hero.position)
			else:
				update_hero_position.rpc_id(1, hero.position)

func _handle_ability_input():
	"""Handle Q and E ability inputs"""
	if Input.is_action_just_pressed("ability_1"):
		use_ability.rpc(1)
	if Input.is_action_just_pressed("ability_2"):
		use_ability.rpc(2)

func _handle_support_input():
	"""Handle support summoning (1, 2, 3 keys)"""
	if Input.is_action_just_pressed("summon_support_1"):
		summon_support.rpc(1)
	if Input.is_action_just_pressed("summon_support_2"):
		summon_support.rpc(2)
	if Input.is_action_just_pressed("summon_support_3"):
		summon_support.rpc(3)

func _handle_big_spell_input():
	"""Handle big spell activation (R key)"""
	if Input.is_action_just_pressed("big_spell"):
		cast_big_spell.rpc()

@rpc("any_peer", "call_local", "reliable")
func update_hero_position(pos: Vector2):
	"""Synchronize hero position across network"""
	if hero:
		hero.position = pos

@rpc("any_peer", "call_local", "reliable")
func use_ability(ability_number: int):
	"""Use hero ability (1 = Q, 2 = E)"""
	if hero and not hero.is_dead:
		# Ability logic will be implemented in Hero subclasses
		print("Using ability ", ability_number)

@rpc("any_peer", "call_local", "reliable")
func summon_support(support_number: int):
	"""Summon support (1, 2, or 3)"""
	# Support summoning will be implemented later
	print("Summoning support ", support_number)

@rpc("any_peer", "call_local", "reliable")
func cast_big_spell():
	"""Cast big spell"""
	# Big spell logic will be implemented later
	print("Casting big spell")

