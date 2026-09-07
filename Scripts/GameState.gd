extends Node

# The Six Chambers
var gap_distance: int = 100
var max_grit: int = 100
var current_grit: int = 100
var water: int = 20
var ammo: int = 12
var gun_condition: int = 100
var food: int = 1

# State Flags
var loop_count: int = 0
var has_horn_of_eld: bool = false
var current_afflictions: Array[String] = []

const TIME_STATES = ["Morning", "High Noon", "Evening", "Midnight"]
var time_index: int = 0

var death_reason: String = "" # Stores the specific failure message
var is_dead: bool = false

var inventory: Array[String] = []

var current_biome: String = "ruins"

var available_biomes: Array[String] = ["dunes", "flats", "canyons", "ruins", "scrubland"]


signal stats_changed 
signal player_died
signal boss_encounter_triggered 

# Tells the engine to ignore the warning, since MainGame.gd emits this!
@warning_ignore("unused_signal")
signal game_won

func modify_water(amount: int):
	water += amount
	
	# If water drops below 0, the player is dehydrated
	if water < 0:
		# Calculate exactly how much water they were missing
		var deficit = abs(water)
		water = 0 # Clamp it safely back to 0
		
		# Define the punishment: How much Grit does 1 missing Water cost?
		var dehydration_damage = deficit * 5 
		
		# Apply the damage using your existing grit function
		modify_grit(-dehydration_damage)
		
	stats_changed.emit()
	_check_death_states()

func modify_grit(amount: int):
	current_grit += amount
	current_grit = clamp(current_grit, 0, max_grit)
	stats_changed.emit()
	_check_death_states()

func modify_ammo(amount: int):
	ammo += amount
	if ammo < 0: ammo = 0
	stats_changed.emit()

func modify_gun_condition(amount: int):
	gun_condition += amount
	gun_condition = clamp(gun_condition, 0, 100)
	stats_changed.emit()

# ------------------------------------------------------------------------
# MODIFY GAP DISTANCE
# Adjusts the distance between you and the Man in Black.
# ------------------------------------------------------------------------
func modify_gap(amount: int):
	gap_distance += amount
	
	# If the gap drops to 0 or below, the player has caught up to the target.
	# We cap it at 0 and trigger the final boss fight instead of a standard event.
	if gap_distance <= 0:
		gap_distance = 0
		boss_encounter_triggered.emit()
		
	# Emit a generic signal to update the HUD (if you have one), 
	# though your MainGame's clock tick usually handles this.
	print("DEBUG: Gap is now ", gap_distance)

func _check_death_states():
	# Failsafe: If the player is already flagged as dead, stop immediately.
	# This prevents multiple death signals from firing at the exact same time.
	if is_dead:
		return
		
	# Check for dehydration
	if water <= 0:
		is_dead = true
		death_reason = "Your canteen ran dry. You withered under the relentless desert sun."
		player_died.emit()
		
	# Check for exhaustion
	elif current_grit <= 0:
		is_dead = true
		death_reason = "Your spirit finally broke. You collapsed into the dust, unable to take another step."
		player_died.emit()
		
	# Note: We do not need to check for combat deaths here, because your 
	# CombatPhase.gd script already sets 'is_dead' and emits the signal directly!

func reset_run():
	is_dead = false
	# Increase the loop count for meta-progression tracking
	loop_count += 1
	
	# Reset core stats back to default
	gap_distance = 100
	current_grit = max_grit
	water = 20
	ammo = 12
	gun_condition = 100
	food = 0
	current_afflictions.clear()
	
	stats_changed.emit()

func advance_time():
	# 1. Rotate the clock forward (0 = Morning, 1 = High Noon, 2 = Evening, 3 = Midnight)
	time_index = (time_index + 1) % 4
	
	# 2. Establish the baseline cost for traveling between nodes
	var water_loss = 1
	var grit_loss = 1
	
	# 3. Apply Time-of-Day specific multipliers and status hazards
	match time_index:
		1: # HIGH NOON
			# Double the water loss due to extreme heat
			water_loss *= 2 
			
			# 30% chance to gain heat exhaustion during peak day hours
			if randi() % 100 < 30 and not current_afflictions.has("exhausted"):
				current_afflictions.append("exhausted")
				
		3: # MIDNIGHT
			# Double the grit loss due to freezing temperatures and paranoia
			grit_loss *= 2 
			
			# 20% chance to dirty your weapon while stumbling in the dark
			if randi() % 100 < 20 and not current_afflictions.has("dirty"):
				current_afflictions.append("dirty")
				
	# 4. Apply the final calculated losses to the global stats
	modify_water(water_loss)
	modify_grit(grit_loss)
	
	# 5. Trigger the standard affliction loop (if active)
	process_afflictions()
	
	# 6. Broadcast the changes to the UI to trigger the visual flash
	stats_changed.emit()
	
	# 7. Check if the time/travel hazards just triggered a Game Over state
	_check_death_states()

func rest_in_place():
	# 1. Rotate the clock forward 
	time_index = (time_index + 1) % 4
	
	# 2. Minimal survival cost for sitting in the shade (no travel exhaustion)
	#modify_water(-2) 
	
	# 3. CRITICAL PENALTY: You stopped moving, but the Man in Black didn't.
	modify_gap(+15)
	
	# 4. Trigger afflictions and update UI
	process_afflictions()
	stats_changed.emit()
	_check_death_states()

func modify_food(amount: int):
	food += amount
	if food < 0: food = 0
	stats_changed.emit()
	
# --- NEW INVENTORY FUNCTIONS ---

func add_item(item_name: String):
	if item_name != "":
		inventory.append(item_name)
		stats_changed.emit()

func remove_item(item_name: String) -> bool:
	if inventory.has(item_name):
		inventory.erase(item_name)
		stats_changed.emit()
		return true
	return false

func has_item(item_name: String) -> bool:
	return inventory.has(item_name)

# --- AFFLICTION LOGIC ---

func add_affliction(affliction: String):
	# Using to_lower() sanitizes the input so "Bleeding" and "bleeding" are treated the same
	var clean_name = affliction.strip_edges().to_lower()
	if clean_name != "" and not current_afflictions.has(clean_name):
		current_afflictions.append(clean_name)
		stats_changed.emit()

func remove_affliction(affliction: String):
	var clean_name = affliction.strip_edges().to_lower()
	if clean_name != "" and current_afflictions.has(clean_name):
		current_afflictions.erase(clean_name)
		stats_changed.emit()

# --- NEW: THE STATUS SWITCHBOARD ---

# ------------------------------------------------------------------------
# AFFLICTION PROCESSING
# Called by EventManager every time the narrative clock advances
# ------------------------------------------------------------------------
func process_afflictions():
	# Loop through every active status effect currently on the player
	for affliction in current_afflictions:
		# Convert to lowercase so capitalization in the Inspector doesn't break the logic
		match affliction.to_lower():
			"bleeding", "injured":
				modify_grit(-1)
			"recovering":
				modify_grit(1)
			"slow":
				# Gap goes UP (The Man in Black gets further away)
				modify_gap(2) 
			"haste":
				# Gap goes DOWN (You gain ground on him)
				modify_gap(-2) 
			"dirty":
				# Gun degrades quickly while filled with sand
				modify_gun_condition(-2)
			"clumsy":
				# randi() % 2 generates either a 0 or a 1
				if randi() % 2 == 0:
					modify_water(-2) # Tripped and spilled water
				else:
					modify_ammo(-1)  # Dropped a bullet in the sand
			"lucky":
				if randi() % 2 == 0:
					modify_water(2)  # Found a clean cactus
				else:
					modify_ammo(1)   # Found a discarded shell

# ------------------------------------------------------------------------
# NEW: CLEAR ALL AFFLICTIONS
# Wipes the slate clean, removing both positive and negative status effects
# ------------------------------------------------------------------------
func clear_all_afflictions():
	# If the array is already empty, we don't need to do anything
	if current_afflictions.is_empty():
		return
		
	# Empty the array completely
	current_afflictions.clear()
	
	# Emit a generic signal if you have one set up for UI updates, 
	# though your update_hud() will naturally catch this change on the next tick!
	print("DEBUG: All afflictions cleared.")
# --- TAG GENERATOR ---

# --- NEW FUNCTION ---
func set_biome(new_biome: String):
	# Strip extra spaces and convert to lowercase so it perfectly matches our tags
	current_biome = new_biome.strip_edges().to_lower()
	# Tell the UI to update so the new biome name appears at the top of the screen
	stats_changed.emit()

# Function to randomly select a new biome from the list (for our current prototype)
func randomize_biome():
	# pick_random() is a built-in Godot function that grabs one random element from an array
	current_biome = available_biomes.pick_random()
	# We don't need to emit stats_changed here because advance_time() will handle it!

# --- UPDATE EXISTING FUNCTION ---
func get_current_keywords() -> Array[String]:
	var keywords: Array[String] = []
	
	# 1. Add broad environmental tags for legacy events
	if time_index == 0 or time_index == 1:
		keywords.append("day")
	else:
		keywords.append("night")
		
	# 1b. Add highly specific time tags for granular event control
	match time_index:
		0: keywords.append("morning")
		1: keywords.append("noon")
		2: keywords.append("evening")
		3: keywords.append("midnight")
		
	# 2. Add the current biome tag!
	keywords.append(current_biome)
		
	# 3. Add current afflictions
	for affliction in current_afflictions:
		keywords.append(affliction.to_lower())
		
	# 4. Add inventory items
	for item in inventory:
		keywords.append(item.to_lower())
		
	return keywords

# ------------------------------------------------------------------------
# ITEM DATABASE
# Upgraded to a dictionary of dictionaries. 
# 'consumable: true' means it generates a "Use" button in the UI.
# 'consumable: false' means it sits passively as a Key Item.
# ------------------------------------------------------------------------
const ITEM_DATABASE = {
	"Bandage": {"name": "Sterile Bandage", "consumable": true},
	"Oil": {"name": "Tin of Gun Oil", "consumable": true},
	"Canteen": {"name": "Canteen Ration", "consumable": true},
	"Scrap": {"name": "Scrap Metal", "consumable": true},
	"Map": {"name": "Scavenger's Map", "consumable": true},
	"Stamina": {"name": "Stamina Ampoule", "consumable": true},
	"Creatine": {"name": "Creatine Powder", "consumable": true},
	"SnakeOil": {"name": "Snake Oil", "consumable": true},
	"Salts": {"name": "Smelling Salts", "consumable": true},
	
	# --- NEW KEY ITEMS ---
	"OldKey": {"name": "Rusted Old Key", "consumable": false},
	"BunkerCode": {"name": "Bunker Passcode", "consumable": false}
}


# ------------------------------------------------------------------------
# INVENTORY CONSUMPTION LOGIC
# Triggered dynamically by the buttons generated in the Main Game HUD
# ------------------------------------------------------------------------
func consume_item(item_id: String):
	# 1. Verify the item actually exists in the player's inventory
	if not inventory.has(item_id):
		return
		
	# 2. Remove the item from the array (this only removes the first instance found)
	inventory.erase(item_id)
	
	# 3. Apply the specific mechanical effect based on the item's ID
	match item_id:
		"Bandage":
			# Bandages cure physical ailments and provide a slight comfort bonus
			current_afflictions.erase("bleeding")
			current_afflictions.erase("injured")
			modify_grit(10) 
			
		"Oil":
			# Instantly repairs weapon condition on the road
			modify_gun_condition(30)
			current_afflictions.erase("dirty")
			
		"Canteen":
			# Emergency hydration burst (Replaces the old 'Water' item)
			modify_water(25)
			
		"Scrap":
			# Risky improvised repair on the road
			modify_gun_condition(15)
			# 50% chance to make the gun dirty due to poor materials
			if randi() % 100 < 50 and not current_afflictions.has("dirty"):
				current_afflictions.append("dirty")
				
		"Map":
			# Gives you a tactical shortcut, reducing the distance to the target
			modify_gap(-10)
			
		# --- NEW SCAVENGED ITEMS ---
		
		"Stamina":
			# A massive, pure energy boost. Cures exhaustion immediately.
			modify_grit(35)
			current_afflictions.erase("slow")
			
		"Salts":
			# A harsh shock to the system: wakes you up, but dehydrates you slightly.
			modify_grit(15)
			modify_water(-5)
			current_afflictions.erase("clumsy")
			
		"SnakeOil":
			# A true desert gamble. 50% chance to be a miracle cure, 50% chance to poison you.
			if randi() % 100 < 50:
				modify_grit(20)
				current_afflictions.erase("slow")
				current_afflictions.erase("injured")
			else:
				modify_grit(-15)
				if not current_afflictions.has("slow"):
					current_afflictions.append("slow")
				if not current_afflictions.has("injured"):
					current_afflictions.append("injured")
					
		"Creatine":
			# Excellent for maintaining your resistance training program and arm development 
			# even out in the wastes. Costs water to mix, but grants a physical buff for brawling!
			modify_water(-10)
			modify_grit(10)
			if not current_afflictions.has("haste"):
				current_afflictions.append("haste")
			
	# 4. Trigger the global UI refresh so the button disappears and stats update
	stats_changed.emit()
	
	# 5. Failsafe: Check if a negative consumable effect (like Snake Oil) just killed the player
	_check_death_states()
