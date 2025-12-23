extends Control

@onready var ability_q_label: Label = $HBoxContainer/AbilityQ/CooldownLabel
@onready var ability_e_label: Label = $HBoxContainer/AbilityE/CooldownLabel
@onready var ability_q_name: Label = $HBoxContainer/AbilityQ/AbilityName
@onready var ability_e_name: Label = $HBoxContainer/AbilityE/AbilityName
@onready var player_hp_label: Label = $TopLeft/PlayerHP
@onready var player_hero_type_label: Label = $TopLeft/PlayerHeroType
@onready var player_attack_cooldown_label: Label = $TopLeft/AttackCooldown
@onready var enemy_hp_label: Label = $TopRight/EnemyHP
@onready var enemy_hero_type_label: Label = $TopRight/EnemyHeroType
@onready var effects_container: VBoxContainer = $BottomLeft/EffectsContainer
@onready var effects_label: Label = $BottomLeft/EffectsLabel
@onready var match_timer_label: Label = $TopCenter/MatchTimer
@onready var player_info_label: Label = $TopLeft/PlayerInfo
@onready var enemy_info_label: Label = $TopRight/EnemyInfo

var local_player_id: int = 1
var local_hero: Node = null
var enemy_hero: Node = null

func _ready():
	add_to_group("battle_ui")
	visible = true
	
	# Ensure all UI elements are properly initialized
	# Wait a frame for @onready nodes to be ready
	await get_tree().process_frame
	
	# Verify all UI elements exist
	if not ability_q_label:
		ability_q_label = get_node_or_null("HBoxContainer/AbilityQ/CooldownLabel")
	if not ability_e_label:
		ability_e_label = get_node_or_null("HBoxContainer/AbilityE/CooldownLabel")
	if not ability_q_name:
		ability_q_name = get_node_or_null("HBoxContainer/AbilityQ/AbilityName")
	if not ability_e_name:
		ability_e_name = get_node_or_null("HBoxContainer/AbilityE/AbilityName")
	if not player_hp_label:
		player_hp_label = get_node_or_null("TopLeft/PlayerHP")
	if not player_hero_type_label:
		player_hero_type_label = get_node_or_null("TopLeft/PlayerHeroType")
	if not player_attack_cooldown_label:
		player_attack_cooldown_label = get_node_or_null("TopLeft/AttackCooldown")
	if not player_info_label:
		player_info_label = get_node_or_null("TopLeft/PlayerInfo")
	if not enemy_hp_label:
		enemy_hp_label = get_node_or_null("TopRight/EnemyHP")
	if not enemy_hero_type_label:
		enemy_hero_type_label = get_node_or_null("TopRight/EnemyHeroType")
	if not enemy_info_label:
		enemy_info_label = get_node_or_null("TopRight/EnemyInfo")
	if not effects_container:
		effects_container = get_node_or_null("BottomLeft/EffectsContainer")
	if not effects_label:
		effects_label = get_node_or_null("BottomLeft/EffectsLabel")
	if not match_timer_label:
		match_timer_label = get_node_or_null("TopCenter/MatchTimer")
	
	# Make sure UI is visible
	visible = true
	modulate = Color(1, 1, 1, 1)  # Ensure full opacity
	
	# Debug: Print UI element status
	print("BattleUI initialized:")
	print("  ability_q_label: ", ability_q_label != null)
	print("  ability_e_label: ", ability_e_label != null)
	print("  player_hp_label: ", player_hp_label != null)
	print("  enemy_hp_label: ", enemy_hp_label != null)
	print("  effects_container: ", effects_container != null)
	print("  match_timer_label: ", match_timer_label != null)
	
	# Set initial text to ensure visibility
	if ability_q_label:
		ability_q_label.text = "Q: Ready"
		ability_q_label.visible = true
	if ability_e_label:
		ability_e_label.text = "E: Ready"
		ability_e_label.visible = true
	if ability_q_name:
		ability_q_name.text = "Ability Name"
		ability_q_name.visible = true
	if ability_e_name:
		ability_e_name.text = "Ability Name"
		ability_e_name.visible = true
	if player_hp_label:
		player_hp_label.text = "Player HP: --"
		player_hp_label.visible = true
	if player_hero_type_label:
		player_hero_type_label.text = "Hero: --"
		player_hero_type_label.visible = true
	if player_attack_cooldown_label:
		player_attack_cooldown_label.text = "Attack: Ready"
		player_attack_cooldown_label.visible = true
	if player_info_label:
		player_info_label.text = "Player " + str(local_player_id)
		player_info_label.visible = true
	if enemy_hp_label:
		enemy_hp_label.text = "Enemy HP: --"
		enemy_hp_label.visible = true
	if enemy_hero_type_label:
		enemy_hero_type_label.text = "Hero: --"
		enemy_hero_type_label.visible = true
	if enemy_info_label:
		var enemy_id = 1 if local_player_id == 2 else 2
		enemy_info_label.text = "Player " + str(enemy_id)
		enemy_info_label.visible = true
	if match_timer_label:
		match_timer_label.text = "10:00"
		match_timer_label.visible = true

func _process(_delta):
	# Continuously try to find heroes if not found yet
	if not local_hero or not is_instance_valid(local_hero) or not enemy_hero or not is_instance_valid(enemy_hero):
		_find_heroes()
	
	_update_ui()

func setup(player_id: int):
	"""Setup UI for local player"""
	local_player_id = player_id
	_find_heroes()

func _find_heroes():
	"""Find local and enemy heroes"""
	# Ensure node is in tree before accessing scene tree
	if not is_inside_tree():
		return
	
	var battle_manager = get_tree().get_first_node_in_group("battle_manager")
	if not battle_manager:
		return
	
	# Find local hero
	if battle_manager.active_heroes.has(local_player_id):
		local_hero = battle_manager.active_heroes[local_player_id]
	
	# Find enemy hero (other player)
	for peer_id in battle_manager.active_heroes:
		if peer_id != local_player_id:
			enemy_hero = battle_manager.active_heroes[peer_id]
			break
	
	# If heroes not found, try to find them in scene tree
	if not local_hero or not is_instance_valid(local_hero):
		var heroes_node = get_tree().get_first_node_in_group("battle_manager")
		if heroes_node:
			var heroes = heroes_node.get_node_or_null("Heroes")
			if heroes:
				for hero in heroes.get_children():
					if "player_id" in hero and hero.player_id == local_player_id and "is_dead" in hero and not hero.is_dead:
						local_hero = hero
						break
	
	if not enemy_hero or not is_instance_valid(enemy_hero):
		var heroes_node = get_tree().get_first_node_in_group("battle_manager")
		if heroes_node:
			var heroes = heroes_node.get_node_or_null("Heroes")
			if heroes:
				for hero in heroes.get_children():
					if "player_id" in hero and hero.player_id != local_player_id and "is_dead" in hero and not hero.is_dead:
						enemy_hero = hero
						break

func _update_ui():
	"""Update all UI elements"""
	_update_ability_cooldowns()
	_update_ability_names()
	_update_hp_display()
	_update_hero_types()
	_update_attack_cooldown()
	_update_player_info()
	_update_effects()
	_update_match_timer()

func _update_ability_cooldowns():
	"""Update ability cooldown displays"""
	if not ability_q_label or not ability_e_label:
		return
	
	if not local_hero or not is_instance_valid(local_hero):
		ability_q_label.text = "Q: --"
		ability_e_label.text = "E: --"
		return
	
	var q_cd = local_hero.ability_q_cooldown if "ability_q_cooldown" in local_hero else 0.0
	var e_cd = local_hero.ability_e_cooldown if "ability_e_cooldown" in local_hero else 0.0
	
	if q_cd > 0.0:
		ability_q_label.text = "Q: %.1f" % q_cd
		ability_q_label.modulate = Color(0.5, 0.5, 0.5, 1)
	else:
		ability_q_label.text = "Q: Ready"
		ability_q_label.modulate = Color(1, 1, 1, 1)
	
	if e_cd > 0.0:
		ability_e_label.text = "E: %.1f" % e_cd
		ability_e_label.modulate = Color(0.5, 0.5, 0.5, 1)
	else:
		ability_e_label.text = "E: Ready"
		ability_e_label.modulate = Color(1, 1, 1, 1)

func _update_ability_names():
	"""Update ability names based on hero type"""
	if not ability_q_name or not ability_e_name:
		return
	
	if not local_hero or not is_instance_valid(local_hero):
		ability_q_name.text = "Q: --"
		ability_e_name.text = "E: --"
		return
	
	var hero_type = local_hero.hero_type if "hero_type" in local_hero else "Unknown"
	
	match hero_type:
		"Fighter":
			ability_q_name.text = "Dash"
			ability_e_name.text = "Shield Bash"
		"Shooter":
			ability_q_name.text = "Rapid Fire"
			ability_e_name.text = "Pushback"
		"Mage":
			ability_q_name.text = "Fireball"
			ability_e_name.text = "Teleport"
		_:
			ability_q_name.text = "Q Ability"
			ability_e_name.text = "E Ability"

func _update_hp_display():
	"""Update player and enemy HP displays"""
	if not player_hp_label or not enemy_hp_label:
		return
	
	# Player HP
	if local_hero and is_instance_valid(local_hero) and "current_health" in local_hero and "max_health" in local_hero:
		var hp_percent = (local_hero.current_health / local_hero.max_health) * 100.0
		player_hp_label.text = "Player HP: %d/%d (%.0f%%)" % [int(local_hero.current_health), int(local_hero.max_health), hp_percent]
	else:
		player_hp_label.text = "Player HP: --"
	
	# Enemy HP
	if enemy_hero and is_instance_valid(enemy_hero) and "current_health" in enemy_hero and "max_health" in enemy_hero:
		var hp_percent = (enemy_hero.current_health / enemy_hero.max_health) * 100.0
		enemy_hp_label.text = "Enemy HP: %d/%d (%.0f%%)" % [int(enemy_hero.current_health), int(enemy_hero.max_health), hp_percent]
	else:
		enemy_hp_label.text = "Enemy HP: --"

func _update_effects():
	"""Update active effects display"""
	if not effects_container:
		return
	
	# Clear existing effect labels (keep the header)
	var children = effects_container.get_children()
	for child in children:
		if child != effects_label:
			child.queue_free()
	
	if not local_hero or not is_instance_valid(local_hero):
		return
	
	# Check for Rapid Fire (Shooter Q)
	if "rapid_fire_active" in local_hero and local_hero.rapid_fire_active:
		var effect_label = Label.new()
		var time_left = local_hero.rapid_fire_timer if "rapid_fire_timer" in local_hero else 0.0
		effect_label.text = "Rapid Fire: %.1fs" % time_left
		effect_label.modulate = Color(0, 1, 0, 1)  # Green
		effects_container.add_child(effect_label)
	
	# Check for spawn protection
	if "spawn_protection" in local_hero and local_hero.spawn_protection > 0.0:
		var effect_label = Label.new()
		effect_label.text = "Spawn Protection: %.1fs" % local_hero.spawn_protection
		effect_label.modulate = Color(0, 1, 1, 1)  # Cyan
		effects_container.add_child(effect_label)

func _update_match_timer():
	"""Update match timer display"""
	if not match_timer_label:
		return
	
	var battle_manager = get_tree().get_first_node_in_group("battle_manager")
	if not battle_manager:
		match_timer_label.text = "--:--"
		return
	
	var timer = battle_manager.match_timer if "match_timer" in battle_manager else 600.0
	var minutes = int(timer / 60.0)
	var seconds = int(timer) % 60
	
	var timer_text = "%02d:%02d" % [minutes, seconds]
	if "sudden_death" in battle_manager and battle_manager.sudden_death:
		timer_text += " (SUDDEN DEATH!)"
		match_timer_label.modulate = Color(1, 0, 0, 1)  # Red
	else:
		match_timer_label.modulate = Color(1, 1, 1, 1)  # White
	
	match_timer_label.text = timer_text
