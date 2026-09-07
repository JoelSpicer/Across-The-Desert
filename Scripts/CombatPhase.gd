extends Control
class_name CombatPhase

# ------------------------------------------------------------------------
# SIGNALS
# ------------------------------------------------------------------------
signal combat_won 

# ------------------------------------------------------------------------
# UI REFERENCES
# ------------------------------------------------------------------------
@onready var combat_log_label = %CombatLogLabel
@onready var btn_shoot = %BtnShoot
@onready var btn_cover = %BtnCover
@onready var btn_advance = %BtnAdvance
@onready var btn_retreat = %BtnRetreat
@onready var btn_melee = %BtnMelee 

# ------------------------------------------------------------------------
# THE BESTIARY (CUSTOM STATBLOCKS)
# ------------------------------------------------------------------------
const ENEMY_DATABASE = {
	"Man in Black": {
		"hp": 6, 
		"is_melee": false, 
		"accuracy": 25, 
		"dodge": 20      
	},
	"Clockwork Hound": {
		"hp": 2, 
		"is_melee": true, 
		"accuracy": 15,
		"dodge": 20     
	},
	"Scarred Brawler": {
		"hp": 4, 
		"is_melee": true, 
		"accuracy": 5, 
		"dodge": -10    
	},
	"Wounded Scavenger": {
		"hp": 1, 
		"is_melee": false, 
		"accuracy": -20, 
		"dodge": -15     
	},
	"Rabid Coyote": {
		"hp": 1, 
		"is_melee": true, 
		"accuracy": 5, 
		"dodge": 15      
	},
	"Caravan Guard": {
		"hp": 2, 
		"is_melee": false, 
		"accuracy": 15,  
		"dodge": 10      
	},
	"Standard": {
		"hp": 1, 
		"is_melee": true, 
		"accuracy": 0, 
		"dodge": 0
	}
}

# ------------------------------------------------------------------------
# COMBAT VARIABLES
# ------------------------------------------------------------------------
var active_enemies: Array[Dictionary] = []
var player_cover: int = 0 
var combat_active: bool = false
var is_player_turn: bool = false # NEW: Strict lock against spam-clicking

# ------------------------------------------------------------------------
# INITIALIZATION & PARSING
# ------------------------------------------------------------------------
func start_combat(combat_string: String):
	active_enemies.clear()
	player_cover = 0
	combat_active = true
	is_player_turn = true
	
	var enemy_definitions = combat_string.split(",")
	for def in enemy_definitions:
		def = def.strip_edges()
		if def == "": continue 
		
		var enemy_name = def
		if ":" in def:
			var parts = def.split(":")
			enemy_name = parts[0].strip_edges()
			
		var stats = ENEMY_DATABASE.get(enemy_name, ENEMY_DATABASE["Standard"])
				
		active_enemies.append({
			"name": enemy_name,
			"is_melee": stats["is_melee"],
			"distance": 3, 
			"cover": 0,    
			"hp": stats["hp"],
			"accuracy": stats["accuracy"],
			"dodge": stats["dodge"]
		})
	
	show()
	_log_message("COMBAT STARTED! Threats detected: " + str(active_enemies.size()))
	_update_ui()

func _ready():
	btn_shoot.pressed.connect(_on_btn_shoot_pressed)
	btn_cover.pressed.connect(_on_btn_cover_pressed)
	btn_advance.pressed.connect(_on_btn_advance_pressed)
	btn_retreat.pressed.connect(_on_btn_retreat_pressed)
	btn_melee.pressed.connect(_on_btn_melee_pressed) 

# ------------------------------------------------------------------------
# UI LOCK MECHANIC
# Disables all buttons instantly to prevent signal spamming
# ------------------------------------------------------------------------
func _set_buttons_locked(locked: bool):
	is_player_turn = !locked
	btn_shoot.disabled = locked
	btn_cover.disabled = locked
	btn_advance.disabled = locked
	btn_retreat.disabled = locked
	if locked:
		btn_melee.disabled = true

# ------------------------------------------------------------------------
# SHOOT LOGIC
# ------------------------------------------------------------------------
func _on_btn_shoot_pressed():
	if not combat_active or not is_player_turn or active_enemies.is_empty(): return
	_set_buttons_locked(true) # Lock immediately
	
	if GameState.ammo <= 0:
		_log_message("Click. Your gun is empty! Find cover, retreat, or get in close.")
		_enemy_phase()
		return
		
	var jam_chance = 0
	if GameState.gun_condition < 60:
		jam_chance = 60 - GameState.gun_condition
		
	if GameState.current_afflictions.has("dirty"):
		jam_chance += 20 
		
	if randi() % 100 < jam_chance:
		_log_message("CLACK. Your poorly maintained weapon jams! You frantically clear the chamber.")
		GameState.modify_gun_condition(-2) 
		_enemy_phase()
		return
		
	GameState.modify_ammo(-1)
	GameState.modify_gun_condition(-5)
	
	if GameState.current_afflictions.has("clumsy"):
		if randi() % 100 < 30: 
			GameState.modify_ammo(-1)
			_log_message("Your clumsy hands fumble the weapon, and you drop a bullet into the sand!")
	
	var target = _get_best_target()
	_log_message("You fire at the " + target.name + "...")
	
	var hit_chance = 80 - (target.distance * 15) - (target.cover * 30)
	hit_chance -= target.dodge
	
	if GameState.gun_condition < 50: hit_chance -= 20
	if GameState.current_afflictions.has("injured"): hit_chance -= 15
	if GameState.current_afflictions.has("haste"): hit_chance += 10
		
	if randi() % 100 < hit_chance:
		target.hp -= 1
		
		if GameState.current_afflictions.has("pumped"):
			target.hp -= 1
			_log_message("Your shot hits with brutal, focused kinetic energy!")
		
		if target.hp <= 0:
			_log_message("A fatal hit! The " + target.name + " goes down.")
			active_enemies.erase(target)
			if active_enemies.is_empty():
				_end_combat(true)
				return
		else:
			_log_message("A direct hit! But the " + target.name + " absorbs the impact and keeps coming! (HP: " + str(target.hp) + ")")
	else:
		_log_message("Your shot misses, kicking up dust.")
		if player_cover == 2:
			player_cover = 1
			_log_message("You leaned out of cover to shoot, exposing yourself.")
			
	_enemy_phase()

# ------------------------------------------------------------------------
# MELEE LOGIC
# ------------------------------------------------------------------------
func _on_btn_melee_pressed():
	if not combat_active or not is_player_turn or active_enemies.is_empty(): return
	
	var target = _get_best_target()
	if target.distance > 1: return # Ignore bad clicks safely
		
	_set_buttons_locked(true) # Lock immediately
	
	_log_message("You lunge forward, using your weapon as a blunt instrument against the " + target.name + "!")
	GameState.modify_gun_condition(-15)
	
	var hit_chance = 75 - (target.cover * 20)
	hit_chance -= target.dodge
	
	if GameState.current_afflictions.has("injured"): hit_chance -= 25 
	if GameState.current_afflictions.has("haste"): hit_chance += 20
		
	if randi() % 100 < hit_chance:
		target.hp -= 1
		
		if GameState.current_afflictions.has("pumped"):
			target.hp -= 1
			_log_message("Fueled by adrenaline, your strike lands with crushing force!")
			
		if target.hp <= 0:
			_log_message("A brutal strike! The " + target.name + " crumples to the dirt.")
			active_enemies.erase(target)
			if active_enemies.is_empty():
				_end_combat(true)
				return
		else:
			_log_message("You crack the " + target.name + " hard, but they stay on their feet! (HP: " + str(target.hp) + ")")
	else:
		_log_message("Your swing goes wide, throwing you off balance.")
		player_cover = 0 
		
	_enemy_phase()

func _on_btn_cover_pressed():
	if not combat_active or not is_player_turn: return
	_set_buttons_locked(true)
	
	if player_cover < 2:
		player_cover += 1
		_log_message("You scramble behind better cover.")
	else:
		_log_message("You are already completely hidden.")
	_enemy_phase()

func _on_btn_advance_pressed():
	if not combat_active or not is_player_turn: return
	_set_buttons_locked(true)
	
	var closed_distance = false
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
	if not combat_active or not is_player_turn: return
	_set_buttons_locked(true)
	
	var can_escape = true
	for enemy in active_enemies:
		enemy.distance += 1
		var escape_threshold = 4
		if GameState.current_afflictions.has("slow"):
			escape_threshold = 5 
			
		if enemy.distance < escape_threshold:
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
	
	for enemy in active_enemies:
		if not combat_active: break 
		
		if enemy.is_melee:
			if enemy.distance > 0:
				enemy.distance -= 1
				enemy.cover = 0
				_log_message("The " + enemy.name + " charges forward!")
			else:
				_enemy_melee_attack(enemy)
		else:
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
				
		await get_tree().create_timer(0.8).timeout
		
	_update_ui()

func _enemy_melee_attack(enemy: Dictionary):
	_log_message("The " + enemy.name + " lunges at you in melee!")
	
	var hit_chance = 85 - (player_cover * 20) 
	hit_chance += enemy.accuracy
	
	if GameState.current_afflictions.has("haste"): hit_chance -= 20
	
	if randi() % 100 < hit_chance:
		_log_message("The " + enemy.name + " tears into you, dealing a brutal blow!")
		GameState.modify_grit(-35) 
		
		if not GameState.current_afflictions.has("injured"):
			GameState.current_afflictions.append("injured")
	else:
		_log_message("You manage to dodge the " + enemy.name + "'s strike!")

func _enemy_shoot_attack(enemy: Dictionary):
	_log_message("The " + enemy.name + " fires at you!")
	
	var hit_chance = 70 - (enemy.distance * 15) - (player_cover * 40)
	hit_chance += enemy.accuracy
	
	if GameState.current_afflictions.has("haste"): hit_chance -= 15
		
	if randi() % 100 < hit_chance:
		_log_message("A bullet strikes home, tearing through your gear and flesh!")
		GameState.modify_grit(-25) 
		
		if not GameState.current_afflictions.has("injured"):
			GameState.current_afflictions.append("injured")
	else:
		_log_message("The shot misses you narrowly.")
		if enemy.cover == 2: enemy.cover = 1

# ------------------------------------------------------------------------
# UTILITY FUNCTIONS
# ------------------------------------------------------------------------
func _get_best_target() -> Dictionary:
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
	
	var closest_enemy_dist = 4
	
	for enemy in active_enemies:
		var type_str = "(Melee)" if enemy.is_melee else "(Ranged)"
		var dist_str = dist_strings[clamp(enemy.distance, 0, 3)] 
		ui_text += enemy.name + " " + type_str + " | Dist: " + dist_str + " | " + cover_strings[enemy.cover] + "\n"
		
		if enemy.distance < closest_enemy_dist:
			closest_enemy_dist = enemy.distance
			
	ui_text += "-------------------------"
	_log_message(ui_text)
	
	# Unlock the UI since the enemy phase is over
	if combat_active:
		_set_buttons_locked(false)
		
		if closest_enemy_dist <= 1:
			btn_melee.disabled = false
			btn_melee.text = "Pistol Whip"
		else:
			btn_melee.disabled = true
			btn_melee.text = "Too Far to Melee"

func _end_combat(player_won: bool, killer_name: String = ""):
	combat_active = false
	_set_buttons_locked(true) # Ensure buttons stay locked during the transition
	
	await get_tree().create_timer(2.0).timeout
	
	if player_won:
		hide()
		combat_log_label.text = "" 
		combat_won.emit() 
	else:
		GameState.is_dead = true
		GameState.death_reason = "You were killed by a " + killer_name + "."
		GameState.player_died.emit()
