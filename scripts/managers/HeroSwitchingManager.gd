class_name HeroSwitchingManager
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
	
	# Ensure dead_heroes array exists and is properly typed
	if not dead_heroes.has(player_id):
		dead_heroes[player_id] = []
	
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
	
	# Ensure dead_heroes array exists and is properly typed
	if not dead_heroes.has(player_id):
		dead_heroes[player_id] = []
	
	var selection_ui = get_tree().get_first_node_in_group("hero_selection_ui")
	if selection_ui and selection_ui.has_method("show_selection"):
		# Create a properly typed copy to ensure type safety
		var dead_list: Array[String] = []
		for hero_type in dead_heroes[player_id]:
			dead_list.append(str(hero_type))
		selection_ui.show_selection(player_id, dead_list)

func select_next_hero(player_id: int, hero_type: String):
	"""Select next hero to switch to - call this when local player selects a hero"""
	# Only allow the player who owns these heroes to initiate the switch
	if multiplayer.multiplayer_peer != null:
		var local_id = multiplayer.get_unique_id()
		if player_id != local_id:
			# Not the authority, shouldn't happen but handle gracefully
			print("Warning: select_next_hero called for non-local player")
			return
	
	# Perform switch locally first
	_perform_hero_switch(player_id, hero_type)
	
	# Network sync to all clients (including ourselves via call_local)
	if multiplayer.multiplayer_peer != null:
		switch_hero.rpc(player_id, hero_type)
	else:
		# Single player, already processed
		pass

func _perform_hero_switch(player_id: int, hero_type: String):
	"""Internal function that actually performs the hero switch"""
	if not player_heroes.has(player_id):
		print("Hero switch failed: No heroes registered for player ", player_id)
		return
	
	# Check if hero type is already dead
	if not dead_heroes.has(player_id):
		dead_heroes[player_id] = []
	if dead_heroes[player_id].has(hero_type):
		print("Hero switch failed: Hero type ", hero_type, " is already dead for player ", player_id)
		return
	
	# Find hero of this type
	var heroes = player_heroes[player_id]
	var new_hero = null
	for hero in heroes:
		if hero and is_instance_valid(hero) and hero.is_inside_tree():
			if hero.hero_type == hero_type and not hero.is_dead:
				new_hero = hero
				break
	
	if not new_hero:
		print("Hero switch failed: Could not find valid hero of type ", hero_type, " for player ", player_id)
		return
	
	# Ensure node is in tree before accessing
	if not new_hero.is_inside_tree():
		print("Hero switch failed: Hero node not in tree for player ", player_id)
		return
	
	# Deactivate current hero
	if active_hero.has(player_id) and active_hero[player_id]:
		var old_hero = active_hero[player_id]
		if is_instance_valid(old_hero) and old_hero.is_inside_tree():
			old_hero.visible = false
			old_hero.set_process(false)
			old_hero.set_physics_process(false)
	
	# Activate new hero
	active_hero[player_id] = new_hero
	new_hero.visible = true
	new_hero.set_process(true)
	new_hero.set_physics_process(true)
	
	# Update BattleManager's active_heroes dictionary
	var battle_manager = get_tree().get_first_node_in_group("battle_manager")
	if battle_manager and battle_manager.has_method("set_active_hero"):
		battle_manager.set_active_hero(player_id, new_hero)
	elif battle_manager and "active_heroes" in battle_manager:
		battle_manager.active_heroes[player_id] = new_hero
	
	# Respawn at spawn position (only if we have authority - will sync via RPC)
	var has_authority = true
	if multiplayer.multiplayer_peer != null:
		has_authority = new_hero.is_multiplayer_authority()
	
	if has_authority:
		# We have authority, respawn will sync to others via RPC
		var spawn_pos = get_spawn_position(player_id)
		new_hero.respawn(spawn_pos)
	# If not authority, the respawn will be synced from authority via RPC
	
	# Hide selection UI (only for local player)
	if multiplayer.multiplayer_peer != null:
		var local_id = multiplayer.get_unique_id()
		if player_id == local_id:
			var selection_ui = get_tree().get_first_node_in_group("hero_selection_ui")
			if selection_ui:
				selection_ui.hide_selection()
	else:
		var selection_ui = get_tree().get_first_node_in_group("hero_selection_ui")
		if selection_ui:
			selection_ui.hide_selection()
	
	print("Switched to hero ", hero_type, " for player ", player_id)

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
	"""Network sync for hero switching - executes on all clients"""
	# Skip if we're the authority (already processed locally via select_next_hero)
	# call_local means this runs on sender too, but we already did _perform_hero_switch
	if multiplayer.multiplayer_peer != null:
		var local_id = multiplayer.get_unique_id()
		if player_id == local_id:
			# Check if we already have this hero active to prevent double processing
			if active_hero.has(player_id) and active_hero[player_id]:
				var current = active_hero[player_id]
				if is_instance_valid(current) and current.hero_type == hero_type:
					# Already switched, skip
					return
	
	# Process the switch on remote clients (or if somehow we didn't process locally)
	_perform_hero_switch(player_id, hero_type)

@rpc("any_peer", "call_local", "reliable")
func all_heroes_dead(player_id: int):
	"""Triggered when all heroes of a player are dead"""
	var battle_manager = get_tree().get_first_node_in_group("battle_manager")
	if battle_manager and battle_manager.has_method("on_player_defeated"):
		battle_manager.on_player_defeated(player_id)
