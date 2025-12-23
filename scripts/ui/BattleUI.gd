extends Control

@onready var ability_q_label: Label = $HBoxContainer/AbilityQ/CooldownLabel
@onready var ability_e_label: Label = $HBoxContainer/AbilityE/CooldownLabel
@onready var player_hp_label: Label = $TopLeft/PlayerHP
@onready var enemy_hp_label: Label = $TopRight/EnemyHP
@onready var effects_container: VBoxContainer = $BottomLeft/EffectsContainer
@onready var effects_label: Label = $BottomLeft/EffectsLabel
@onready var match_timer_label: Label = $TopCenter/MatchTimer

var local_player_id: int = 1
var local_hero: Node = null
var enemy_hero: Node = null

func _ready():
	add_to_group("battle_ui")
	visible = true

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
	_update_hp_display()
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
