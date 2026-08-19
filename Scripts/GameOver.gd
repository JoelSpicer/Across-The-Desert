extends Control
class_name GameOver

# ------------------------------------------------------------------------
# UI REFERENCES
# Adjust these paths if your labels or buttons have different names in the scene tree
# ------------------------------------------------------------------------
@onready var label_title = $VBoxContainer/LabelTitle
@onready var label_reason = $VBoxContainer/DeathMessage
@onready var btn_restart = $VBoxContainer/RestartButton

# ------------------------------------------------------------------------
# INITIALIZATION
# ------------------------------------------------------------------------
func _ready():
	# Keep this overlay completely hidden during normal gameplay
	hide()
	
	# Listen for both end-state signals from the global GameState singleton
	GameState.player_died.connect(_on_player_died)
	GameState.game_won.connect(_on_game_won)
	
	# Auto-wire the restart button
	btn_restart.pressed.connect(_on_btn_restart_pressed)

# ------------------------------------------------------------------------
# DEFEAT STATE
# ------------------------------------------------------------------------
func _on_player_died():
	label_title.text = "THE DESERT CLAIMS ANOTHER"
	
	# Pull the exact string of text describing how they died from GameState
	label_reason.text = GameState.death_reason
	
	# Reveal the Game Over UI overlay
	show()

# ------------------------------------------------------------------------
# VICTORY STATE
# ------------------------------------------------------------------------
func _on_game_won():
	# Overwrite the standard failure text with the victory narrative
	label_title.text = "VENGEANCE AT LAST"
	label_reason.text = "The Man in Black lies dead in the sand. Your grueling journey across the wastes is finally over."
	
	# Reveal the exact same UI overlay, but now functioning as a Win Screen
	show()

# ------------------------------------------------------------------------
# RESTART LOGIC
# ------------------------------------------------------------------------
func _on_btn_restart_pressed():
	# Reloads the entire active scene tree from scratch.
	# Note: Because GameState is an Autoload (Singleton), it will NOT reset itself automatically.
	# You must manually reset your global variables here before reloading the scene!
	
	GameState.water = 100
	GameState.current_grit = 100
	GameState.gap_distance = 100
	GameState.ammo = 10
	GameState.gun_condition = 100
	GameState.food = 3
	GameState.inventory.clear()
	GameState.current_afflictions.clear()
	GameState.is_dead = false
	
	# Once the global stats are back to their defaults, restart the engine
	get_tree().reload_current_scene()
