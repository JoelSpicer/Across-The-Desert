extends Control
class_name CombatPhase

# ------------------------------------------------------------------------
# SIGNALS
# ------------------------------------------------------------------------
# Emitted to tell Maingame.gd that the player survived and the narrative can resume
signal combat_won 

# ------------------------------------------------------------------------
# UI REFERENCES
# These grab the unique nodes set up in your CombatPhase.tscn scene
# ------------------------------------------------------------------------
@onready var combat_log_label = %CombatLogLabel
@onready var btn_shoot = %BtnShoot
@onready var btn_cover = %BtnCover
@onready var btn_advance = %BtnAdvance
@onready var btn_retreat = %BtnRetreat
@onready var btn_melee = %BtnMelee 

# ------------------------------------------------------------------------
# COMBAT VARIABLES
# ------------------------------------------------------------------------
# active_enemies is an Array of Dictionaries. Each dictionary tracks an individual
# enemy's name, type (melee/ranged), current distance from the player, and cover state.
var active_enemies: Array[Dictionary] = []

# Player's cover level: 0 = Exposed, 1 = Partial, 2 = Full Cover
var player_cover: int = 0 

# Acts as a lock to prevent the player from clicking buttons while the AI is taking its turn
var combat_active: bool = false

# ------------------------------------------------------------------------
# INITIALIZATION & PARSING
# Called by MainGame.gd when an event triggers a fight
# ------------------------------------------------------------------------
func start_combat(combat_string: String):
	# Clear the battlefield from any previous encounters
	active_enemies.clear()
	player_cover = 0
	combat_active = true
	
	# Parse the comma-separated string from the narrative event (e.g., "Hound:melee, Scavenger:ranged")
	var enemy_definitions = combat_string.split(",")
	for def in enemy_definitions:
		def = def.strip_edges()
		if def == "": continue # Skip empty strings just in case of formatting errors
		
		var is_melee = false
		var enemy_name = def
		
		# Check if a specific combat style was tagged using a colon
		if ":" in def:
			var parts = def.split(":")
			enemy_name = parts[0].strip_edges()
			# If tagged as melee, they will use charge/lunge logic instead of seeking cover
			if parts[1].strip_edges().to_lower() == "melee":
				is_melee = true
				
		# Construct the enemy profile and add it to the active battlefield array
		active_enemies.append({
			"name": enemy_name,
			"is_melee": is_melee,
			"distance": 3, # 3 = Far, 2 = Mid, 1 = Close, 0 = Melee range
			"cover": 0     # Enemies always start exposed
		})
	
	# Reveal the UI and announce the start of the fight
	show()
	_log_message("COMBAT STARTED! Threats detected: " + str(active_enemies.size()))
	_update_ui()

# ------------------------------------------------------------------------
# AUTO-WIRING SIGNALS
# Connects UI buttons to their respective code functions immediately upon loading
# ------------------------------------------------------------------------
func _ready():
	btn_shoot.pressed.connect(_on_btn_shoot_pressed)
	btn_cover.pressed.connect(_on_btn_cover_pressed)
	btn_advance.pressed.connect(_on_btn_advance_pressed)
	btn_retreat.pressed.connect(_on_btn_retreat_pressed)
	btn_melee.pressed.connect(_on_btn_melee_pressed) 

# ------------------------------------------------------------------------
# PLAYER ACTIONS
# ------------------------------------------------------------------------
func _on_btn_shoot_pressed():
	# Ignore clicks if the fight is over or the AI is taking its turn
	if not combat_active or active_enemies.is_empty(): return
	
	if GameState.ammo <= 0:
		_log_message("Click. Your gun is empty! Find cover, retreat, or get in close.")
		_enemy_phase()
		return
		
	# --- JAM MECHANIC ---
	# If gun condition drops below 60%, the gun starts failing
	var jam_chance = 0
	if GameState.gun_condition < 60:
		jam_chance = 60 - GameState.gun_condition
		
	# Roll a 100-sided die. If the roll is lower than the jam chance, the gun misfires.
	if randi() % 100 < jam_chance:
		_log_message("CLACK. Your poorly maintained weapon jams! You frantically clear the chamber.")
		# Fumbling with a jammed gun wastes the turn and slightly degrades the weapon more
		GameState.modify_gun_condition(-2) 
		_enemy_phase()
		return
		
	# Normal firing mechanics cost 1 ammo and standard wear-and-tear
	GameState.modify_ammo(-1)
	GameState.modify_gun_condition(-5)
	
	# Automatically target the enemy that is easiest to hit
	var target = _get_best_target()
	_log_message("You fire at the " + target.name + "...")
	
	# Base accuracy is 80%. Penalties apply for distance and enemy cover.
	var hit_chance = 80 - (target.distance * 15) - (target.cover * 30)
	
	# A heavily degraded gun (below 50%) loses 20% accuracy
	if GameState.gun_condition < 50: 
		hit_chance -= 20
		
	if randi() % 100 < hit_chance:
		_log_message("A direct hit! The " + target.name + " goes down.")
		active_enemies.erase(target) # Remove the dead enemy from the array
		
		# If the array is empty, all enemies are dead and the player wins
		if active_enemies.is_empty():
			_end_combat(true)
			return
	else:
		_log_message("Your shot misses, kicking up dust.")
		# Firing forces the player out of full cover (level 2) down to partial cover (level 1)
		if player_cover == 2:
			player_cover = 1
			_log_message("You leaned out of cover to shoot, exposing yourself.")
			
	_enemy_phase()

func _on_btn_melee_pressed():
	if not combat_active or active_enemies.is_empty(): return
	
	var target = _get_best_target()
	
	# Failsafe: Ensure the target is actually in melee or close range (distance 0 or 1)
	if target.distance > 1:
		_log_message("They are too far away to hit!")
		return
		
	_log_message("You lunge forward, using your weapon as a blunt instrument against the " + target.name + "!")
	
	# Smashing someone with a firearm severely degrades its mechanical condition
	GameState.modify_gun_condition(-15)
	
	# Base hit chance for melee is decent, but enemy cover makes it harder to land a clean blow
	var hit_chance = 75 - (target.cover * 20)
	
	if randi() % 100 < hit_chance:
		_log_message("A brutal strike! The " + target.name + " crumples to the dirt.")
		active_enemies.erase(target)
		
		if active_enemies.is_empty():
			_end_combat(true)
			return
	else:
		_log_message("Your swing goes wide, throwing you off balance.")
		# Missing a heavy melee swing always breaks your cover completely
		player_cover = 0 
		
	_enemy_phase()

func _on_btn_cover_pressed():
	if not combat_active: return
	
	# Max cover level is 2
	if player_cover < 2:
		player_cover += 1
		_log_message("You scramble behind better cover.")
	else:
		_log_message("You are already completely hidden.")
		
	_enemy_phase()

func _on_btn_advance_pressed():
	if not combat_active: return
	
	var closed_distance = false
	# Advancing reduces your distance to EVERY enemy on the field simultaneously
	for enemy in active_enemies:
		if enemy.distance > 0:
			enemy.distance -= 1
			closed_distance = true
			
	# Moving aggressively always breaks your cover completely
	player_cover = 0
	
	if closed_distance:
		_log_message("You break cover and sprint forward.")
	else:
		_log_message("You are already locked in melee with everything!")
		
	_enemy_phase()

func _on_btn_retreat_pressed():
	if not combat_active: return
	
	var can_escape = true
	# Retreating increases your distance from EVERY enemy simultaneously
	for enemy in active_enemies:
		enemy.distance += 1
		# If even ONE enemy is closer than distance 4, you can't escape yet
		if enemy.distance < 4:
			can_escape = false
			
	# Turning your back to run breaks your cover completely
	player_cover = 0 
	_log_message("You fall back, putting more space between you and the threats.")
	
	# If you managed to push every enemy to distance 4, you successfully flee
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
	
	# Briefly pause so the player can read their own action's result before the enemy acts
	await get_tree().create_timer(1.0).timeout
	
	# Loop through every alive enemy and give them a turn
	for enemy in active_enemies:
		if not combat_active: break # Stop immediately if the player died mid-loop
		
		if enemy.is_melee:
			# --- MELEE AI BEHAVIOR ---
			# Melee enemies ignore cover and relentlessly charge until distance is 0
			if enemy.distance > 0:
				enemy.distance -= 1
				enemy.cover = 0
				_log_message("The " + enemy.name + " charges forward!")
			else:
				_enemy_melee_attack(enemy)
		else:
			# --- RANGED AI BEHAVIOR ---
			# 1. Shoot if the player is exposed and close enough
			if player_cover == 0 and enemy.distance <= 2:
				_enemy_shoot_attack(enemy)
			# 2. Otherwise, prioritize finding cover if they have none
			elif enemy.cover == 0:
				enemy.cover += 1
				_log_message("The " + enemy.name + " ducks behind cover.")
			# 3. Otherwise, advance to get a better angle
			elif enemy.distance > 1:
				enemy.distance -= 1
				enemy.cover = 0
				_log_message("The " + enemy.name + " advances, breaking cover!")
			# 4. If none of the above, take a shot
			else:
				_enemy_shoot_attack(enemy)
				
		# Pause briefly between each enemy's action so the UI log updates smoothly
		await get_tree().create_timer(0.8).timeout
		
	# Update the UI state block after all enemies have acted
	_update_ui()

func _enemy_melee_attack(enemy: Dictionary):
	_log_message("The " + enemy.name + " lunges at you in melee!")
	
	# Melee attacks ignore distance and are only slightly affected by player cover
	var hit_chance = 85 - (player_cover * 20) 
	
	if randi() % 100 < hit_chance:
		_log_message("You are torn apart. The desert claims you.")
		_end_combat(false, enemy.name)
	else:
		_log_message("You manage to dodge the " + enemy.name + "'s strike!")

func _enemy_shoot_attack(enemy: Dictionary):
	_log_message("The " + enemy.name + " fires at you!")
	
	# Enemy accuracy degrades over distance and is heavily penalized by player cover
	var hit_chance = 70 - (enemy.distance * 15) - (player_cover * 40)
	
	if randi() % 100 < hit_chance:
		_log_message("You are hit. The desert claims you.")
		_end_combat(false, enemy.name)
	else:
		_log_message("The shot misses you narrowly.")
		# Taking a shot forces the enemy out of full cover down to partial cover
		if enemy.cover == 2: enemy.cover = 1

# ------------------------------------------------------------------------
# UTILITY FUNCTIONS
# ------------------------------------------------------------------------
func _get_best_target() -> Dictionary:
	# Automatically scores enemies. Lower score means easier to hit.
	# Prioritizes closer enemies, then more exposed enemies.
	var best_target = active_enemies[0]
	var best_score = 999
	
	for enemy in active_enemies:
		var score = (enemy.distance * 10) + (enemy.cover * 10)
		if score < best_score:
			best_score = score
			best_target = enemy
			
	return best_target

func _log_message(msg: String):
	# Appends text to the RichTextLabel. scroll_following must be true in the inspector!
	combat_log_label.append_text("\n" + msg)

func _update_ui():
	# Human-readable translations for the integer states
	var dist_strings = ["Melee", "Close", "Mid", "Far"]
	var cover_strings = ["Exposed", "Partial Cover", "Full Cover"]
	
	# Build the visual state block
	var ui_text = "\n--- BATTLEFIELD STATE ---\n"
	ui_text += "You: " + cover_strings[player_cover] + "\n"
	ui_text += "- ENEMIES -\n"
	
	var closest_enemy_dist = 4
	
	# Print a dedicated UI row for every living enemy
	for enemy in active_enemies:
		var type_str = "(Melee)" if enemy.is_melee else "(Ranged)"
		# clamp() ensures distance doesn't crash the array index if it goes above 3 while escaping
		var dist_str = dist_strings[clamp(enemy.distance, 0, 3)] 
		ui_text += enemy.name + " " + type_str + " | Dist: " + dist_str + " | " + cover_strings[enemy.cover] + "\n"
		
		# Track the closest enemy to determine if the Pistol Whip button should be active
		if enemy.distance < closest_enemy_dist:
			closest_enemy_dist = enemy.distance
			
	ui_text += "-------------------------"
	
	# Toggle the Pistol Whip button dynamically based on proximity
	if closest_enemy_dist <= 1:
		btn_melee.disabled = false
		btn_melee.text = "Pistol Whip"
	else:
		btn_melee.disabled = true
		btn_melee.text = "Too Far to Melee"
		
	_log_message(ui_text)

func _end_combat(player_won: bool, killer_name: String = ""):
	combat_active = false
	
	# Wait a moment so the player can actually read the final fatal shot or victory message
	await get_tree().create_timer(2.0).timeout
	
	if player_won:
		hide()
		combat_log_label.text = "" # Clear the log for the next encounter
		combat_won.emit() # Tell MainGame.gd to resume the narrative clock
	else:
		# Trigger the exact same death logic the rest of the game uses
		GameState.is_dead = true
		GameState.death_reason = "You were killed by a " + killer_name + "."
		GameState.player_died.emit()
