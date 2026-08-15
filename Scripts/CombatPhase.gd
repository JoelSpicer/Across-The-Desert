extends Control
class_name CombatPhase

signal combat_won

# ------------------------------------------------------------------------
# UI REFERENCES
# ------------------------------------------------------------------------
@onready var combat_log_label = %CombatLogLabel
@onready var btn_shoot = %BtnShoot
@onready var btn_cover = %BtnCover
@onready var btn_advance = %BtnAdvance
@onready var btn_retreat = %BtnRetreat

# ------------------------------------------------------------------------
# COMBAT VARIABLES
# active_enemies holds dictionaries tracking each individual threat's state
# ------------------------------------------------------------------------
var active_enemies: Array[Dictionary] = []
var player_cover: int = 0 # 0 = Exposed, 1 = Partial, 2 = Full
var combat_active: bool = false

# ------------------------------------------------------------------------
# INITIALIZATION & PARSING
# ------------------------------------------------------------------------

# ------------------------------------------------------------------------
# AUTO-WIRING SIGNALS
# ------------------------------------------------------------------------
func _ready():
	# Connect the buttons to their respective functions automatically
	btn_shoot.pressed.connect(_on_btn_shoot_pressed)
	btn_cover.pressed.connect(_on_btn_cover_pressed)
	btn_advance.pressed.connect(_on_btn_advance_pressed)
	btn_retreat.pressed.connect(_on_btn_retreat_pressed)

func start_combat(combat_string: String):
	active_enemies.clear()
	player_cover = 0
	combat_active = true
	
	# Parse the comma-separated string (e.g., "Hound:melee, Scavenger:ranged")
	var enemy_definitions = combat_string.split(",")
	for def in enemy_definitions:
		def = def.strip_edges()
		if def == "": continue
		
		var is_melee = false
		var enemy_name = def
		
		# Check if a weapon type was tagged using a colon
		if ":" in def:
			var parts = def.split(":")
			enemy_name = parts[0].strip_edges()
			if parts[1].strip_edges().to_lower() == "melee":
				is_melee = true
				
		# Add the newly built enemy to the battlefield
		active_enemies.append({
			"name": enemy_name,
			"is_melee": is_melee,
			"distance": 3, # Everyone starts at distance 3 (Far)
			"cover": 0
		})
	
	show()
	_log_message("COMBAT STARTED! Threats detected: " + str(active_enemies.size()))
	_update_ui()

# ------------------------------------------------------------------------
# PLAYER ACTIONS
# ------------------------------------------------------------------------
func _on_btn_shoot_pressed():
	if not combat_active or active_enemies.is_empty(): return
	
	if GameState.ammo <= 0:
		_log_message("Click. Your gun is empty! Find cover or retreat.")
		_enemy_phase()
		return
		
	GameState.modify_ammo(-1)
	GameState.modify_gun_condition(-5)
	
	# Auto-Targeting: Find the easiest enemy to hit
	var target = _get_best_target()
	
	_log_message("You fire at the " + target.name + "...")
	
	var hit_chance = 80 - (target.distance * 15) - (target.cover * 30)
	if GameState.gun_condition < 50: hit_chance -= 20
		
	if randi() % 100 < hit_chance:
		_log_message("A direct hit! The " + target.name + " goes down.")
		active_enemies.erase(target) # Remove them from the fight
		
		if active_enemies.is_empty():
			_end_combat(true)
			return
	else:
		_log_message("Your shot misses, kicking up dust.")
		if player_cover == 2:
			player_cover = 1
			_log_message("You leaned out of cover to shoot, exposing yourself.")
			
	_enemy_phase()

func _on_btn_cover_pressed():
	if not combat_active: return
	if player_cover < 2:
		player_cover += 1
		_log_message("You scramble behind better cover.")
	else:
		_log_message("You are already completely hidden.")
	_enemy_phase()

func _on_btn_advance_pressed():
	if not combat_active: return
	
	var closed_distance = false
	# Advancing reduces your distance to EVERY enemy on the field
	for enemy in active_enemies:
		if enemy.distance > 0:
			enemy.distance -= 1
			closed_distance = true
			
	player_cover = 0
	
	if closed_distance:
		_log_message("You break cover and sprint forward.")
	else:
		_log_message("You are already locked in melee with everything!")
		
	_enemy_phase()

func _on_btn_retreat_pressed():
	if not combat_active: return
	
	var can_escape = true
	# Retreating increases your distance from EVERY enemy
	for enemy in active_enemies:
		enemy.distance += 1
		# If even ONE enemy is closer than distance 4, you can't escape yet
		if enemy.distance < 4:
			can_escape = false
			
	player_cover = 0 
	_log_message("You fall back, putting more space between you and the threats.")
	
	if can_escape:
		_log_message("You managed to slip away into the desert.")
		_end_combat(true) 
		return
		
	_enemy_phase()

# ------------------------------------------------------------------------
# ENEMY AI LOGIC
# ------------------------------------------------------------------------
func _enemy_phase():
	if not combat_active: return
	
	await get_tree().create_timer(1.0).timeout
	
	# Loop through every alive enemy and give them a turn
	for enemy in active_enemies:
		if not combat_active: break # Stop if the player died mid-loop
		
		if enemy.is_melee:
			# Melee AI: Always charge. If distance is 0, attack.
			if enemy.distance > 0:
				enemy.distance -= 1
				enemy.cover = 0
				_log_message("The " + enemy.name + " charges forward!")
			else:
				_enemy_melee_attack(enemy)
		else:
			# Ranged AI: Shoot if exposed, otherwise seek cover or advance
			if player_cover == 0 and enemy.distance <= 2:
				_enemy_shoot_attack(enemy)
			elif enemy.cover == 0:
				enemy.cover += 1
				_log_message("The " + enemy.name + " ducks behind cover.")
			elif enemy.distance > 1:
				enemy.distance -= 1
				enemy.cover = 0
				_log_message("The " + enemy.name + " advances, breaking cover!")
			else:
				_enemy_shoot_attack(enemy)
				
		# Pause briefly between each enemy's action so the UI updates smoothly
		await get_tree().create_timer(0.8).timeout
		
	_update_ui()

func _enemy_melee_attack(enemy: Dictionary):
	_log_message("The " + enemy.name + " lunges at you in melee!")
	# Melee ignores distance and is slightly less affected by cover
	var hit_chance = 85 - (player_cover * 20) 
	if randi() % 100 < hit_chance:
		_log_message("You are torn apart. The desert claims you.")
		_end_combat(false, enemy.name)
	else:
		_log_message("You manage to dodge the " + enemy.name + "'s strike!")

func _enemy_shoot_attack(enemy: Dictionary):
	_log_message("The " + enemy.name + " fires at you!")
	var hit_chance = 70 - (enemy.distance * 15) - (player_cover * 40)
	if randi() % 100 < hit_chance:
		_log_message("You are hit. The desert claims you.")
		_end_combat(false, enemy.name)
	else:
		_log_message("The shot misses you narrowly.")
		if enemy.cover == 2: enemy.cover = 1

# ------------------------------------------------------------------------
# UTILITY FUNCTIONS
# ------------------------------------------------------------------------
func _get_best_target() -> Dictionary:
	# Automatically finds the enemy that is closest and most exposed
	var best_target = active_enemies[0]
	var best_score = 999
	
	for enemy in active_enemies:
		var score = (enemy.distance * 10) + (enemy.cover * 10)
		if score < best_score:
			best_score = score
			best_target = enemy
			
	return best_target

func _log_message(msg: String):
	combat_log_label.append_text("\n" + msg)

func _update_ui():
	var dist_strings = ["Melee", "Close", "Mid", "Far"]
	var cover_strings = ["Exposed", "Partial Cover", "Full Cover"]
	
	var ui_text = "\n--- BATTLEFIELD STATE ---\n"
	ui_text += "You: " + cover_strings[player_cover] + "\n"
	ui_text += "- ENEMIES -\n"
	
	# Print a UI row for every living enemy
	for enemy in active_enemies:
		var type_str = "(Melee)" if enemy.is_melee else "(Ranged)"
		# clamp() ensures distance doesn't crash the array if it goes above 3 while escaping
		var dist_str = dist_strings[clamp(enemy.distance, 0, 3)] 
		ui_text += enemy.name + " " + type_str + " | Dist: " + dist_str + " | " + cover_strings[enemy.cover] + "\n"
		
	ui_text += "-------------------------"
	_log_message(ui_text)

func _end_combat(player_won: bool, killer_name: String = ""):
	combat_active = false
	await get_tree().create_timer(2.0).timeout
	
	if player_won:
		hide()
		combat_log_label.text = "" 
		combat_won.emit()
	else:
		GameState.is_dead = true
		GameState.death_reason = "You were killed by a " + killer_name + "."
		GameState.player_died.emit()
