extends Control
class_name CombatPhase

signal combat_won

# ------------------------------------------------------------------------
# UI REFERENCES
# Make sure to assign these in your scene with Unique Names (%Name)
# ------------------------------------------------------------------------
@onready var combat_log_label = %CombatLogLabel
@onready var btn_shoot = %BtnShoot
@onready var btn_cover = %BtnCover
@onready var btn_advance = %BtnAdvance
@onready var btn_retreat = %BtnRetreat

# ------------------------------------------------------------------------
# COMBAT VARIABLES
# These track the shifting state of the battlefield
# ------------------------------------------------------------------------
var enemy_name: String = ""
var distance: int = 3 # 3 = Far, 2 = Mid, 1 = Close, 0 = Melee
var player_cover: int = 0 # 0 = Exposed, 1 = Partial, 2 = Full
var enemy_cover: int = 0
var combat_active: bool = false


# ------------------------------------------------------------------------
# AUTO-WIRING SIGNALS
# This runs once when the scene is loaded, connecting all UI buttons 
# to their respective functions automatically so you don't have to use the editor.
# ------------------------------------------------------------------------
func _ready():
	# Connect the Shoot button to the _on_btn_shoot_pressed function
	btn_shoot.pressed.connect(_on_btn_shoot_pressed)
	
	# Connect the Cover button to the _on_btn_cover_pressed function
	btn_cover.pressed.connect(_on_btn_cover_pressed)
	
	# Connect the Advance button to the _on_btn_advance_pressed function
	btn_advance.pressed.connect(_on_btn_advance_pressed)
	
	# Connect the Retreat button to the _on_btn_retreat_pressed function
	btn_retreat.pressed.connect(_on_btn_retreat_pressed)

# ------------------------------------------------------------------------
# INITIALIZATION
# Called by the EventManager when a combat event is triggered
# ------------------------------------------------------------------------
func start_combat(new_enemy_name: String, starting_distance: int = 3):
	enemy_name = new_enemy_name
	distance = starting_distance
	
	# Reset battlefield states for a fresh fight
	player_cover = 0
	enemy_cover = 0
	combat_active = true
	
	# Reveal the combat UI overlay
	show()
	
	# Print the opening scenario to the player
	_log_message("COMBAT STARTED: " + enemy_name)
	_update_ui()

# ------------------------------------------------------------------------
# PLAYER ACTIONS
# Hook these functions up to your 4 UI buttons via the Godot signal menu
# ------------------------------------------------------------------------
func _on_btn_shoot_pressed():
	if not combat_active: return
	
	if GameState.ammo <= 0:
		_log_message("Click. Your gun is empty! You need to fall back or find cover.")
		_enemy_turn()
		return
		
	# Firing a shot costs ammo and slightly degrades the gun
	GameState.modify_ammo(-1)
	GameState.modify_gun_condition(-5)
	
	_log_message("You take aim and fire...")
	
	# Calculate hit chance. Starts at 80% if point blank and exposed.
	var hit_chance = 80 
	
	# Distance penalty (farther away = harder to hit)
	hit_chance -= (distance * 15) 
	
	# Enemy cover penalty
	hit_chance -= (enemy_cover * 30)
	
	# Gun condition penalty (a poorly maintained gun is inaccurate)
	if GameState.gun_condition < 50:
		hit_chance -= 20
		
	# Roll the dice (randi() % 100 generates a number from 0 to 99)
	var roll = randi() % 100
	
	if roll < hit_chance:
		_log_message("A direct hit. The " + enemy_name + " drops dead in the sand.")
		_end_combat(true) # True means the player won
	else:
		_log_message("Your shot misses, kicking up dust.")
		# Firing a gun forces you out of full cover
		if player_cover == 2:
			player_cover = 1
			_log_message("You lean out of cover to shoot, exposing yourself.")
		_enemy_turn()

func _on_btn_cover_pressed():
	if not combat_active: return
	if player_cover < 2:
		player_cover += 1
		_log_message("You scramble behind better cover.")
	else:
		_log_message("You are already completely hidden.")
	_enemy_turn()

func _on_btn_advance_pressed():
	if not combat_active: return
	if distance > 0:
		distance -= 1
		player_cover = 0 # Moving always breaks cover completely
		_log_message("You break cover and sprint forward, closing the distance.")
	else:
		_log_message("You are already right on top of them!")
	_enemy_turn()

func _on_btn_retreat_pressed():
	if not combat_active: return
	if distance < 4:
		distance += 1
		player_cover = 0 # Retreating breaks cover
		_log_message("You fall back, putting more space between you.")
		# If you get far enough away, you can escape combat entirely
		if distance >= 4:
			_log_message("You managed to slip away into the desert.")
			_end_combat(true) 
			return
	_enemy_turn()

# ------------------------------------------------------------------------
# ENEMY AI LOGIC
# A simple decision tree that reacts to the player's choices
# ------------------------------------------------------------------------
func _enemy_turn():
	if not combat_active: return
	
	# Wait a brief moment before the enemy acts so the player can read
	await get_tree().create_timer(1.0).timeout
	
	# If the player is totally exposed, the enemy will always try to shoot
	if player_cover == 0 and distance <= 2:
		_enemy_shoot()
	# If the enemy is exposed, they will prioritize finding cover
	elif enemy_cover == 0:
		enemy_cover += 1
		_log_message("The " + enemy_name + " ducks behind cover.")
	# Otherwise, they will advance to get a better shot
	elif distance > 1:
		distance -= 1
		enemy_cover = 0
		_log_message("The " + enemy_name + " rushes forward, breaking cover!")
	else:
		_enemy_shoot()
		
	_update_ui()

func _enemy_shoot():
	_log_message("The " + enemy_name + " attacks!")
	
	var hit_chance = 70
	hit_chance -= (distance * 15)
	hit_chance -= (player_cover * 40) # Player cover is very protective
	
	var roll = randi() % 100
	
	if roll < hit_chance:
		_log_message("You are hit. The desert claims you.")
		_end_combat(false) # False means the player died
	else:
		_log_message("The attack misses you narrowly.")
		if enemy_cover == 2:
			enemy_cover = 1

# ------------------------------------------------------------------------
# UTILITY FUNCTIONS
# ------------------------------------------------------------------------
func _log_message(msg: String):
	# Appends new text to the bottom of the combat log
	combat_log_label.text += "\n" + msg

func _update_ui():
	# Helper strings to translate numbers into readable UI text
	var dist_strings = ["Melee", "Close", "Mid", "Far"]
	var cover_strings = ["Exposed", "Partial Cover", "Full Cover"]
	
	var ui_text = "\n--- BATTLEFIELD STATE ---\n"
	ui_text += "Distance: " + dist_strings[distance] + "\n"
	ui_text += "Enemy: " + cover_strings[enemy_cover] + "\n"
	ui_text += "You: " + cover_strings[player_cover] + "\n"
	ui_text += "-------------------------"
	
	_log_message(ui_text)

func _end_combat(player_won: bool):
	combat_active = false
	# Wait a moment so the player can read the final fatal shot
	await get_tree().create_timer(2.0).timeout
	
	if player_won:
		hide()
		combat_log_label.text = "" # Clear the log for the next fight
		# --- NEW: Tell the main game we survived ---
		combat_won.emit()
	else:
		# Trigger the exact same death logic your existing game uses
		GameState.is_dead = true
		GameState.death_reason = "You were killed by a " + enemy_name + "."
		GameState.player_died.emit()
