extends Node

@export var event_pool: Array[NarrativeEvent] = []
var current_event: NarrativeEvent

# Reference to the main UI to pass the event data
@onready var main_game_ui = get_parent()

func _ready():
	# Make sure you have added your .tres files to the event_pool array in the Inspector!
	if event_pool.is_empty():
		push_error("Event pool is empty! Add NarrativeEvent resources in the inspector.")
		return

func trigger_random_event():
	var valid_events: Array[NarrativeEvent] = []
	var total_weight: int = 0
	var current_tags = GameState.get_current_keywords()
	
	# 1. Filter the event pool based on conditions
	for event in event_pool: # Assuming your loaded array is called 'events'
		var is_valid = true
		
		# Check required keywords
		for req in event.required_keywords:
			if not current_tags.has(req.to_lower()):
				is_valid = false
				break
				
		# Check forbidden keywords
		if is_valid:
			for forb in event.forbidden_keywords:
				if current_tags.has(forb.to_lower()):
					is_valid = false
					break
		
		# If it passes, add to the valid pool and calculate total weight
		if is_valid:
			valid_events.append(event)
			total_weight += event.event_weight
			
	# 2. Fallback to prevent crashes if the table is empty
	if valid_events.is_empty():
		print("ERROR: No valid events found for current tags!")
		return
		
	# 3. Roll the weighted dice
	var roll = randi() % total_weight
	var current_weight = 0
	
	for event in valid_events:
		current_weight += event.event_weight
		if roll < current_weight:
			current_event = event
			break
			
	# 4. Send the chosen event to the UI
	get_parent().load_event(current_event)

func process_choice(choice_num: int):
	# Initialize all base numerical cost variables to 0
	var water_cost = 0
	var gap_penalty = 0
	var grit_cost = 0
	var ammo_cost = 0
	var gun_cost = 0
	var food_cost = 0
	
	# Initialize variables to hold strings (items, statuses, and our new biomes)
	var item_reward = ""
	var given_affliction = ""
	var cured_affliction = ""
	var biome_change = "" # NEW: Holds the biome transition string
	
	# 1. Grab the exact costs and strings from the currently loaded event resource
	if choice_num == 1:
		water_cost = current_event.choice_1_water_cost
		gap_penalty = current_event.choice_1_gap_penalty
		grit_cost = current_event.choice_1_grit_cost 
		ammo_cost = current_event.choice_1_ammo_cost
		gun_cost = current_event.choice_1_gun_condition_cost
		food_cost = current_event.choice_1_food_cost
		item_reward = current_event.choice_1_item_reward
		given_affliction = current_event.choice_1_gives_affliction
		cured_affliction = current_event.choice_1_cures_affliction
		biome_change = current_event.choice_1_biome_change # NEW: Read the Choice 1 biome transition
	elif choice_num == 2:
		water_cost = current_event.choice_2_water_cost
		gap_penalty = current_event.choice_2_gap_penalty
		grit_cost = current_event.choice_2_grit_cost
		ammo_cost = current_event.choice_2_ammo_cost
		gun_cost = current_event.choice_2_gun_condition_cost
		food_cost = current_event.choice_2_food_cost
		item_reward = current_event.choice_2_item_reward
		given_affliction = current_event.choice_2_gives_affliction
		cured_affliction = current_event.choice_2_cures_affliction
		biome_change = current_event.choice_2_biome_change # NEW: Read the Choice 2 biome transition

	# 2. Apply Day/Night Modifiers to the base costs
	if GameState.is_day:
		# Double water loss during the hot day (only multiplies negative numbers)
		if water_cost < 0: 
			water_cost *= 2 
	else:
		# Negate water loss at night
		if water_cost < 0: 
			water_cost = 0 
		# Double grit loss due to the horrors of the dark
		if grit_cost < 0: 
			grit_cost *= 2
		# Player can move faster/stealthier at night, reducing the gap penalty by 5
		gap_penalty -= 5 

	# 3. Apply all the final mathematically modified values to the GameState
	GameState.modify_water(water_cost)
	GameState.modify_grit(grit_cost)
	GameState.modify_ammo(ammo_cost)
	GameState.modify_gun_condition(gun_cost)
	GameState.modify_gap(gap_penalty)
	GameState.modify_food(food_cost)
	
	# 4. Process Inventory, Afflictions, and Biome Changes
	GameState.add_item(item_reward)
	GameState.add_affliction(given_affliction)
	GameState.remove_affliction(cured_affliction)
	
	# NEW: If the event choice included a biome string, update the global game state
	if biome_change != "":
		GameState.set_biome(biome_change)

	# 5. Apply ongoing status effects (like bleeding draining grit every turn)
	GameState.process_afflictions()

	# 6. Check for death before continuing to the next event
	if GameState.is_dead:
		return 

	# 7. Advance the clock and pull the next event
	GameState.advance_time()
	
	# NOTE: We have removed GameState.randomize_biome() so the player actually 
	# stays in the biome they chose until they hit another crossroads event!
	trigger_random_event()
