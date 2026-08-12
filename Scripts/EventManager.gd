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
	# Initialize variables to hold the stats before we modify them
	var water_cost = 0
	var gap_penalty = 0
	var grit_cost = 0
	var ammo_cost = 0
	var gun_cost = 0
	var food_cost = 0
	var item_reward = ""
	
	# New Affliction Variables
	var given_affliction = ""
	var cured_affliction = ""
	
	# 1. Grab the base costs from the resource
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

	# 2. Apply Day/Night Modifiers
	if GameState.is_day:
		# If the water cost is a penalty (negative), double the loss. 
		# If it is positive (finding water), leave it alone.
		if water_cost < 0:
			water_cost *= 2 
	else:
		# Night time: Negate water loss entirely, but allow water gain
		if water_cost < 0:
			water_cost = 0 
			
		# The dark plays tricks on the mind: Double any Grit damage taken
		if grit_cost < 0:
			grit_cost *= 2
			
		# Close the gap slightly faster at night
		gap_penalty -= 5 

	# 3. Apply the final modified values to GameState
	GameState.modify_water(water_cost)
	GameState.modify_grit(grit_cost)
	GameState.modify_ammo(ammo_cost)
	GameState.modify_gun_condition(gun_cost)
	GameState.modify_gap(gap_penalty)
	GameState.modify_food(food_cost)
	GameState.add_item(item_reward)
	GameState.add_affliction(given_affliction)
	GameState.remove_affliction(cured_affliction)
	
	# 4. Check for death before continuing
	if GameState.is_dead:
		return 

	# 5. Advance the clock and load the next event
	GameState.advance_time()
	trigger_random_event()
