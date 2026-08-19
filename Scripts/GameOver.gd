extends Control
class_name GameOver

# ------------------------------------------------------------------------
# UI REFERENCES
# Make sure these match the Unique Names (%) in your GameOver.tscn scene tree!
# ------------------------------------------------------------------------
@onready var label_title = %LabelTitle
@onready var label_reason = %DeathMessage
@onready var btn_restart = %RestartButton

# ------------------------------------------------------------------------
# INITIALIZATION
# ------------------------------------------------------------------------
func _ready():
	# DO NOT use hide() here, otherwise the scene loads completely invisible!
	
	# Determine if the player won or lost by checking the Gap Distance.
	# If it's 0 or less, they survived the final encounter.
	if GameState.gap_distance <= 0:
		label_title.text = "VENGEANCE AT LAST"
		label_reason.text = "The Man in Black lies dead in the sand. Your grueling journey across the wastes is finally over."
	else:
		# Otherwise, it's a standard death. Pull the exact death reason from the GameState.
		label_title.text = "THE DESERT CLAIMS ANOTHER"
		label_reason.text = GameState.death_reason
		
	# Wire up the restart button
	btn_restart.pressed.connect(_on_btn_restart_pressed)

# ------------------------------------------------------------------------
# RESTART LOGIC
# ------------------------------------------------------------------------
func _on_btn_restart_pressed():
	# Reset all global stats back to their default values for a new run
	GameState.water = 100
	GameState.current_grit = 100
	GameState.gap_distance = 100
	GameState.ammo = 10
	GameState.gun_condition = 100
	GameState.food = 3
	GameState.inventory.clear()
	GameState.current_afflictions.clear()
	GameState.is_dead = false
	
	# Because GameOver is its own scene, we must explicitly load the Main Game scene
	# to restart, rather than reloading the current scene!
	get_tree().change_scene_to_file("res://Scene/MainGame.tscn")
