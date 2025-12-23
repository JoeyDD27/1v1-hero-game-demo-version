extends Control

@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var message_label: Label = $Panel/VBoxContainer/MessageLabel
@onready var return_button: Button = $Panel/VBoxContainer/ReturnButton

var is_victory: bool = false

func _ready():
	visible = false
	add_to_group("victory_screen")
	return_button.pressed.connect(_on_return_button_pressed)

func show_victory(player_id: int, local_player_id: int):
	"""Show victory screen"""
	is_victory = (player_id == local_player_id)
	
	if is_victory:
		title_label.text = "VICTORY!"
		title_label.modulate = Color(1, 1, 0, 1)  # Gold
		message_label.text = "You have defeated your opponent!"
	else:
		title_label.text = "DEFEAT"
		title_label.modulate = Color(0.8, 0.2, 0.2, 1)  # Red
		message_label.text = "All your heroes have been defeated."
	
	visible = true
	get_tree().paused = true

func _on_return_button_pressed():
	"""Return to main menu"""
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

