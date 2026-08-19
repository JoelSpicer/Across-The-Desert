extends ColorRect

var max_hours: int = 8
var current_hours: int = 8
var hours_spent: int = 0

# ------------------------------------------------------------------------
# SCAVENGING LOOT TABLES
# Each biome has an array of possible drops.
# 'weight' determines how likely it is to roll (higher = more common).
# 'type' tells the script which GameState variable to modify.
# ------------------------------------------------------------------------
var biome_loot_tables = {
	"ruins": [
		{"type": "ammo", "amount": 2, "weight": 40, "name": "a handful of bullets"},
		{"type": "item", "amount": 1, "weight": 20, "name": "a sterile Bandage", "item_id": "Bandage"},
		{"type": "item", "amount": 1, "weight": 10, "name": "a tin of Gun Oil", "item_id": "Oil"},
		{"type": "nothing", "amount": 0, "weight": 30, "name": "nothing but rust and dust"}
	],
	"scrubland": [
		{"type": "water", "amount": 15, "weight": 50, "name": "some muddy but drinkable water"},
		{"type": "food", "amount": 1, "weight": 30, "name": "some edible root vegetables"},
		{"type": "item", "amount": 1, "weight": 10, "name": "some medicinal leaves", "item_id": "Bandage"},
		{"type": "nothing", "amount": 0, "weight": 10, "name": "only dried twigs"}
	],
	"canyons": [
		{"type": "water", "amount": 10, "weight": 30, "name": "rainwater pooled in the rocks"},
		{"type": "ammo", "amount": 1, "weight": 20, "name": "a dropped shell casing"},
		{"type": "item", "amount": 1, "weight": 20, "name": "an old scavenger's Map", "item_id": "Map"},
		{"type": "nothing", "amount": 0, "weight": 30, "name": "nothing but shadows"}
	],
	"flats": [
		{"type": "nothing", "amount": 0, "weight": 70, "name": "absolutely nothing in the salt"},
		{"type": "ammo", "amount": 1, "weight": 30, "name": "a bullet buried in the crust"}
	],
	"dunes": [
		{"type": "nothing", "amount": 0, "weight": 60, "name": "only endless, shifting sand"},
		{"type": "item", "amount": 1, "weight": 25, "name": "a half-buried Scrap piece", "item_id": "Scrap"},
		{"type": "water", "amount": 5, "weight": 15, "name": "condensation from a deep dig"}
	]
}

@onready var label_hours = $MarginContainer/VBoxContainer/HoursLabel
@onready var label_log = $MarginContainer/VBoxContainer/LogLabel

@onready var btn_sleep = $MarginContainer/VBoxContainer/HBoxContainer/BtnSleep
@onready var btn_maintain = $MarginContainer/VBoxContainer/HBoxContainer/BtnMaintain
@onready var btn_forage = $MarginContainer/VBoxContainer/HBoxContainer/BtnForage
@onready var btn_break_camp = $MarginContainer/VBoxContainer/BtnBreakCamp

func _ready():
	# Connect the buttons
	btn_sleep.pressed.connect(_on_sleep_pressed)
	btn_maintain.pressed.connect(_on_maintain_pressed)
	btn_forage.pressed.connect(_on_forage_pressed)
	btn_break_camp.pressed.connect(_on_break_camp_pressed)
	
	update_ui()

func update_ui():
	label_hours.text = "Time Remaining: " + str(current_hours) + " Hours"

func _on_sleep_pressed():
	if current_hours >= 4:
		current_hours -= 4
		hours_spent += 4
		GameState.modify_grit(40) # Sleeping heals 40 Grit
		# Wipe all positive and negative conditions when sleeping
		GameState.clear_all_afflictions()
		label_log.text = "You sleep fitfully. (+40 Grit)"
		update_ui()
	else:
		label_log.text = "Not enough time to sleep."

func _on_maintain_pressed():
	if current_hours >= 2:
		current_hours -= 2
		hours_spent += 2
		GameState.modify_gun_condition(30) # Cleaning restores 30%
		label_log.text = "You clean sand from the cylinder. (+30% Gun)"
		update_ui()
	else:
		label_log.text = "Not enough time to maintain your gun."

# ------------------------------------------------------------------------
# SCAVENGE / FORAGE LOGIC
# Allows the player to search the immediate area, drawing from biome-specific tables.
# ------------------------------------------------------------------------
func _on_forage_pressed():
	if current_hours >= 2:
		current_hours -= 2
		hours_spent += 2
		
		# Scavenging takes energy, costing the player some Grit. 
		# Note: You are also already losing Gap distance when you break camp based on hours_spent.
		GameState.modify_grit(-1)
		
		var current_biome = GameState.current_biome.to_lower()
		
		# Fallback just in case the biome string isn't perfectly matched
		if not biome_loot_tables.has(current_biome):
			current_biome = "flats" 
			
		var possible_loot = biome_loot_tables[current_biome]
		var total_weight = 0
		
		# 1. Calculate the total weight of the biome's loot pool
		for drop in possible_loot:
			total_weight += drop["weight"]
			
		# 2. Roll a random number within that total weight
		var roll = randi() % total_weight
		var current_weight = 0
		var won_drop = null
		
		# 3. Determine which item the roll landed on
		for drop in possible_loot:
			current_weight += drop["weight"]
			if roll < current_weight:
				won_drop = drop
				break
				
		# 4. Grant the reward based on the 'type' defined in the dictionary
		if won_drop != null:
			match won_drop["type"]:
				"water":
					GameState.modify_water(won_drop["amount"])
				"ammo":
					GameState.modify_ammo(won_drop["amount"])
				"food":
					GameState.modify_food(won_drop["amount"])
				"item":
					GameState.add_item(won_drop["item_id"])
				"nothing":
					pass # No stats to modify
					
			# Update the camp feedback label to tell the player what they found
			label_log.text = "You spend 2 hours scouring the area and find " + won_drop["name"] + "."
			
		# Update the UI to reflect the newly lost hours
		update_ui()
	else:
		label_log.text = "Not enough time to forage."

func _on_break_camp_pressed():
	# Calculate the Gap penalty. For example, 5 units of distance per hour spent.
	var distance_lost = hours_spent * 2
	GameState.modify_gap(distance_lost)
	
	# The player rested, so the Exhaustion/Camp cycle resets. 
	# Delete this Camp UI scene to reveal the Main Game again.
	queue_free()
