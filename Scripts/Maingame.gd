extends Control

@onready var main_text = $MarginContainer/VBoxContainer/EventDisplayArea/MainText
@onready var btn_choice_1 = $MarginContainer/VBoxContainer/ActionButtons/Choice1Button
@onready var btn_choice_2 = $MarginContainer/VBoxContainer/ActionButtons/Choice2Button
@onready var label_water = $MarginContainer/VBoxContainer/TopHUD/WaterLabel
@onready var label_grit = $MarginContainer/VBoxContainer/TopHUD/GritLabel
@onready var label_gap = $MarginContainer/VBoxContainer/TopHUD/GapLabel
@onready var label_gun = $MarginContainer/VBoxContainer/TopHUD/GunConditionLabel
@onready var label_ammo = $MarginContainer/VBoxContainer/TopHUD/AmmoLabel

@onready var event_manager = $EventManager # Reference the new node

func _ready():
	GameState.stats_changed.connect(update_hud)
	update_hud()
	
	btn_choice_1.pressed.connect(_on_choice_1_pressed)
	btn_choice_2.pressed.connect(_on_choice_2_pressed)
	
	if event_manager:
		event_manager.trigger_random_event()

func update_hud():
	label_water.text = "Water: " + str(GameState.water)
	label_grit.text = "Grit: " + str(GameState.current_grit)
	label_gap.text = "Gap: " + str(GameState.gap_distance)
	label_gun.text = "Gun: " + str(GameState.gun_condition) + "%"
	label_ammo.text = "Ammo: " + str(GameState.ammo)
	

func load_event(event_resource: NarrativeEvent):
	main_text.text = event_resource.event_text
	btn_choice_1.text = event_resource.choice_1_text
	btn_choice_2.text = event_resource.choice_2_text

func _on_choice_1_pressed():
	# Apply all costs/rewards to the global state
	GameState.modify_water(current_event.choice_1_water_cost)
	GameState.modify_ammo(current_event.choice_1_ammo_cost)
	GameState.modify_gun_condition(current_event.choice_1_gun_condition_cost)
	GameState.modify_gap(current_event.choice_1_gap_penalty)
	
	# Immediately load the next random event
	EventManager.trigger_random_event()

func _on_choice_2_pressed():
	# Apply all costs/rewards to the global state
	GameState.modify_water(current_event.choice_2_water_cost)
	GameState.modify_ammo(current_event.choice_2_ammo_cost)
	GameState.modify_gun_condition(current_event.choice_2_gun_condition_cost)
	GameState.modify_gap(current_event.choice_2_gap_penalty)
	
	# Immediately load the next random event
	EventManager.trigger_random_event()
