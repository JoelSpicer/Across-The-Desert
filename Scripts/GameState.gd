extends Node

# The Six Chambers
var gap_distance: int = 100 
var max_grit: int = 100
var current_grit: int = 100
var water: int = 20
var ammo: int = 12
var gun_condition: int = 100
var food: int = 0

# State Flags
var loop_count: int = 0
var has_horn_of_eld: bool = false
var current_afflictions: Array[String] = []
var is_day: bool = true

var death_reason: String = "" # Stores the specific failure message
var is_dead: bool = false

var inventory: Array[String] = []

var current_biome: String = "dunes"

var available_biomes: Array[String] = ["dunes", "flats", "canyons", "ruins", "scrubland"]


signal stats_changed 
signal player_died # New signal to tell the UI to change scenes

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

func modify_gap(amount: int):
	gap_distance += amount
	if gap_distance < 0: gap_distance = 0
	stats_changed.emit()
	_check_death_states()

func _check_death_states():
	if is_dead:
		return
		
	if current_grit <= 0:
		is_dead = true 
		death_reason = "The desert claims you. Your grit has failed."
		player_died.emit()
	elif gap_distance >= 200:
		is_dead = true 
		death_reason = "The trail goes cold. He has escaped."
		player_died.emit()
	elif gap_distance <= 0:
		is_dead = true
		death_reason = "You closed the distance. The Man in Black has nowhere left to run."
		# We reuse the death signal here just to force the GameOver scene to load!
		player_died.emit()

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
	# Flip the boolean (if true, becomes false; if false, becomes true)
	is_day = !is_day
	stats_changed.emit()

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
	
	# 1. Add environmental tags
	if is_day:
		keywords.append("day")
	else:
		keywords.append("night")
		
	# 2. Add the current biome tag!
	keywords.append(current_biome)
		
	# 3. Add current afflictions
	for affliction in current_afflictions:
		keywords.append(affliction.to_lower())
		
	# 4. Add inventory items
	for item in inventory:
		keywords.append(item.to_lower())
		
	return keywords
