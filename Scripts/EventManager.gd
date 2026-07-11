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
	# Apply all costs directly using GameState's modifier functions
	if choice_num == 1:
		GameState.modify_water(current_event.choice_1_water_cost)
		GameState.modify_grit(current_event.choice_1_grit_cost) 
		GameState.modify_ammo(current_event.choice_1_ammo_cost)
		GameState.modify_gun_condition(current_event.choice_1_gun_condition_cost)
		GameState.modify_gap(current_event.choice_1_gap_penalty)
	elif choice_num == 2:
		GameState.modify_water(current_event.choice_2_water_cost)
		GameState.modify_grit(current_event.choice_2_grit_cost)
		GameState.modify_ammo(current_event.choice_2_ammo_cost)
		GameState.modify_gun_condition(current_event.choice_2_gun_condition_cost)
		GameState.modify_gap(current_event.choice_2_gap_penalty)

	# Check for death before continuing
	if GameState.current_grit <= 0 or GameState.gap_distance >= 200:
		return # Game Over handled by GameState

	# Trigger the next event (simulating travel)
	trigger_random_event()
