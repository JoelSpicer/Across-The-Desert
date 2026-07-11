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
	# Pick a random event from the pool
	var random_index = randi() % event_pool.size()
	current_event = event_pool[random_index]
	
	# Send it to the UI
	main_game_ui.load_event(current_event)

func process_choice(choice_num: int):
	# Initialize variables to hold the stats before we modify them
	var water_cost = 0
	var gap_penalty = 0
	var grit_cost = 0
	var ammo_cost = 0
	var gun_cost = 0
	
	# 1. Grab the base costs from the resource
	if choice_num == 1:
		water_cost = current_event.choice_1_water_cost
		gap_penalty = current_event.choice_1_gap_penalty
		grit_cost = current_event.choice_1_grit_cost 
		ammo_cost = current_event.choice_1_ammo_cost
		gun_cost = current_event.choice_1_gun_condition_cost
	elif choice_num == 2:
		water_cost = current_event.choice_2_water_cost
		gap_penalty = current_event.choice_2_gap_penalty
		grit_cost = current_event.choice_2_grit_cost
		ammo_cost = current_event.choice_2_ammo_cost
		gun_cost = current_event.choice_2_gun_condition_cost

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

	# 4. Check for death before continuing
	if GameState.is_dead:
		return 

	# 5. Advance the clock and load the next event
	GameState.advance_time()
	trigger_random_event()

	# 3. Apply the final modified values to GameState
	GameState.modify_water(water_cost)
	GameState.modify_gap(gap_penalty)

	# 4. Check for death before continuing
	if GameState.is_dead:
		return 

	# 5. Advance the clock and load the next event
	GameState.advance_time()
	trigger_random_event()
