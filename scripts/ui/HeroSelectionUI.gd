extends Control

@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var timer_label: Label = $Panel/VBoxContainer/TimerLabel
@onready var options_container: HBoxContainer = $Panel/VBoxContainer/OptionsContainer

var selection_timer: float = 5.0
var player_id: int = 0
var dead_heroes: Array[String] = []

func _ready():
	visible = false
	add_to_group("hero_selection_ui")

func _process(delta):
	if visible:
		selection_timer -= delta
		if selection_timer <= 0.0:
			# Auto-select first available hero
			auto_select_hero()
		else:
			timer_label.text = "Time: %.1f" % selection_timer
		
		# Handle number key input
		if Input.is_action_just_pressed("select_hero_1"):
			select_hero("Fighter")
		elif Input.is_action_just_pressed("select_hero_2"):
			select_hero("Shooter")
		elif Input.is_action_just_pressed("select_hero_3"):
			select_hero("Mage")

func show_selection(p_id: int, dead: Array[String]):
	"""Show hero selection UI"""
	player_id = p_id
	dead_heroes = dead
	selection_timer = 5.0
	visible = true
	
	title_label.text = "Select Next Hero"
	
	# Update option buttons
	_update_options()

func _update_options():
	"""Update available hero options"""
	# Clear existing options
	for child in options_container.get_children():
		child.queue_free()
	
	# Create option buttons
	var hero_types = ["Fighter", "Shooter", "Mage"]
	for i in range(hero_types.size()):
		var hero_type = hero_types[i]
		var is_dead = dead_heroes.has(hero_type)
		
		var button = Button.new()
		button.text = str(i + 1) + " - " + hero_type
		button.disabled = is_dead
		if is_dead:
			button.text += " (DEAD)"
		button.pressed.connect(_on_option_selected.bind(hero_type))
		options_container.add_child(button)

func _on_option_selected(hero_type: String):
	"""Handle option button selection"""
	select_hero(hero_type)

func select_hero(hero_type: String):
	"""Select a hero"""
	if dead_heroes.has(hero_type):
		return
	
	var switching_manager = get_tree().get_first_node_in_group("hero_switching_manager")
	if switching_manager:
		switching_manager.select_next_hero(player_id, hero_type)
	
	hide_selection()

func auto_select_hero():
	"""Auto-select first available hero"""
	var hero_types = ["Fighter", "Shooter", "Mage"]
	for hero_type in hero_types:
		if not dead_heroes.has(hero_type):
			select_hero(hero_type)
			return

func hide_selection():
	"""Hide selection UI"""
	visible = false

