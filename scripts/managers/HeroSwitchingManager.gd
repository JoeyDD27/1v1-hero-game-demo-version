extends Node

signal hero_selected(hero_type: String)

var player_heroes: Dictionary = {}  # player_id -> Array of hero nodes
var active_hero: Dictionary = {}  # player_id -> active hero node
var dead_heroes: Dictionary = {}  # player_id -> Array of dead hero types
var respawn_timers: Dictionary = {}  # player_id -> respawn timer

const RESPAWN_DELAY = 5.0  # 5 seconds to select next hero
const SPAWN_PROTECTION_TIME = 3.0  # 3 seconds invincibility

func register_player_heroes(player_id: int, heroes_array: Array):
	"""Register all 3 heroes for a player"""
	player_heroes[player_id] = heroes_array
	
	# Set first hero as active
	if heroes_array.size() > 0:
		active_hero[player_id] = heroes_array[0]
		# Activate first hero, deactivate others
		for i in range(heroes_array.size()):
			if i == 0:
				heroes_array[i].visible = true
				heroes_array[i].set_process(true)
				heroes_array[i].set_physics_process(true)
			else:
				heroes_array[i].visible = false
				heroes_array[i].set_process(false)
				heroes_array[i].set_physics_process(false)
	
	dead_heroes[player_id] = []

func on_hero_died(player_id: int, hero_node):
	"""Handle hero death"""
	if not player_heroes.has(player_id):
		return
	
	# Add to dead heroes
	var hero_type = hero_node.hero_type
	if not dead_heroes[player_id].has(hero_type):
		dead_heroes[player_id].append(hero_type)
	
	# Check if all heroes are dead
	if dead_heroes[player_id].size() >= 3:
		# All heroes dead - trigger win condition
		all_heroes_dead.rpc(player_id)
		return
	
	# Start respawn timer
	respawn_timers[player_id] = RESPAWN_DELAY
	
	# Show selection UI
	if multiplayer.multiplayer_peer != null and player_id == multiplayer.get_unique_id():
		show_selection_ui(player_id)

func show_selection_ui(player_id: int):
	"""Show hero selection UI"""
	# Only show UI for the local player
	var local_id = multiplayer.get_unique_id() if multiplayer.multiplayer_peer != null else 1
	if player_id != local_id:
		return
	
	var selection_ui = get_tree().get_first_node_in_group("hero_selection_ui")
	if selection_ui and selection_ui.has_method("show_selection"):
		selection_ui.show_selection(player_id, dead_heroes[player_id])

func select_next_hero(player_id: int, hero_type: String):
	"""Select next hero to switch to"""
	if not player_heroes.has(player_id):
		return
	
	# Check if hero type is already dead
	if dead_heroes[player_id].has(hero_type):
		return
	
	# Find hero of this type
	var heroes = player_heroes[player_id]
	var new_hero = null
	for hero in heroes:
		if hero.hero_type == hero_type and not hero.is_dead:
			new_hero = hero
			break
	
	if not new_hero:
		return
	
	# Deactivate current hero
	if active_hero.has(player_id) and active_hero[player_id]:
		var old_hero = active_hero[player_id]
		if is_instance_valid(old_hero):
			old_hero.visible = false
			old_hero.set_process(false)
			old_hero.set_physics_process(false)
	
	# Activate new hero
	active_hero[player_id] = new_hero
	new_hero.visible = true
	new_hero.set_process(true)
	new_hero.set_physics_process(true)
	
	# Respawn at spawn position
	var spawn_pos = get_spawn_position(player_id)
	new_hero.respawn(spawn_pos)
	
	# Hide selection UI
	var selection_ui = get_tree().get_first_node_in_group("hero_selection_ui")
	if selection_ui:
		selection_ui.hide_selection()
	
	# Network sync
	switch_hero.rpc(player_id, hero_type)

func get_spawn_position(player_id: int) -> Vector2:
	"""Get spawn position for player"""
	var battle_manager = get_tree().get_first_node_in_group("battle_manager")
	if battle_manager:
		return battle_manager.get_spawn_position(player_id)
	
	# Default spawn positions
	if player_id == 1:
		return Vector2(300, 540)
	else:
		return Vector2(1620, 540)

@rpc("any_peer", "call_local", "reliable")
func switch_hero(player_id: int, hero_type: String):
	"""Network sync for hero switching"""
	# This is handled locally, but we sync to ensure all clients see the switch
	pass

@rpc("any_peer", "call_local", "reliable")
func all_heroes_dead(player_id: int):
	"""Triggered when all heroes of a player are dead"""
	var battle_manager = get_tree().get_first_node_in_group("battle_manager")
	if battle_manager and battle_manager.has_method("on_player_defeated"):
		battle_manager.on_player_defeated(player_id)

