extends Control

@onready var main_text = $MarginContainer/VBoxContainer/EventDisplayArea/MainText
@onready var btn_choice_1 = $MarginContainer/VBoxContainer/ActionButtons/Choice1Button
@onready var btn_choice_2 = $MarginContainer/VBoxContainer/ActionButtons/Choice2Button
@onready var label_water = $MarginContainer/VBoxContainer/TopHUD/WaterLabel

var current_event: NarrativeEvent

func _ready():
	# Connect to the autoload signal
	GameState.stats_changed.connect(update_hud)
	update_hud()
	
	# Connect button clicks
	btn_choice_1.pressed.connect(_on_choice_1_pressed)
	btn_choice_2.pressed.connect(_on_choice_2_pressed)

func update_hud():
	label_water.text = "Water: " + str(GameState.water)
	# Update other labels...

func load_event(event_resource: NarrativeEvent):
	current_event = event_resource
	main_text.text = current_event.event_text
	btn_choice_1.text = current_event.choice_1_text
	btn_choice_2.text = current_event.choice_2_text

func _on_choice_1_pressed():
	# Apply the costs from the resource to the global state
	GameState.modify_water(current_event.choice_1_water_cost)
	GameState.gap_distance += current_event.choice_1_gap_penalty
	
	# In a real game, you would now load the next map node or event
	print("Choice 1 executed.")
