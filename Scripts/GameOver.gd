extends Control

@onready var death_message = $VBoxContainer/DeathMessage
@onready var restart_button = $VBoxContainer/RestartButton

func _ready():
	# Read the death reason stored in GameState
	death_message.text = GameState.death_reason
	
	# Connect the restart button
	restart_button.pressed.connect(_on_restart_pressed)

func _on_restart_pressed():
	# Tell GameState to reset stats, then reload the main game
	GameState.reset_run()
	get_tree().change_scene_to_file("res://Scene/MainGame.tscn")
