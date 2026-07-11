extends Control

@onready var main_text = $MarginContainer/VBoxContainer/EventDisplayArea/MainText
@onready var btn_choice_1 = $MarginContainer/VBoxContainer/ActionButtons/Choice1Button
@onready var btn_choice_2 = $MarginContainer/VBoxContainer/ActionButtons/Choice2Button
@onready var label_water = $MarginContainer/VBoxContainer/TopHUD/WaterLabel
@onready var label_grit = $MarginContainer/VBoxContainer/TopHUD/GritLabel
@onready var label_gap = $MarginContainer/VBoxContainer/TopHUD/GapLabel
@onready var label_gun = $MarginContainer/VBoxContainer/TopHUD/GunConditionLabel
@onready var label_ammo = $MarginContainer/VBoxContainer/TopHUD/AmmoLabel
@onready var btn_make_camp = $MarginContainer/VBoxContainer/ActionButtons/MakeCampButton
@onready var label_time = $MarginContainer/VBoxContainer/TopHUD/TimeLabel

@onready var event_manager = $EventManager # Reference the new node

func _ready():
	GameState.stats_changed.connect(update_hud)
	GameState.player_died.connect(_on_player_died)
	update_hud()
	
	btn_choice_1.pressed.connect(_on_choice_1_pressed)
	btn_choice_2.pressed.connect(_on_choice_2_pressed)
	btn_make_camp.pressed.connect(_on_make_camp_pressed)
	
	if event_manager:
		event_manager.trigger_random_event()

func update_hud():
	# Determine if it is Day or Night
	var time_string = "DAY (2x Water Loss)"
	if not GameState.is_day:
		time_string = "NIGHT (2x Grit Loss)"
		
	# Apply it to the new label
	label_time.text = " | " + time_string + " | "
	
	# Keep your existing label updates
	label_water.text = "Water: " + str(GameState.water) + " | "
	label_grit.text = "Grit: " + str(GameState.current_grit) + " | "
	label_gap.text = "Gap: " + str(GameState.gap_distance) + " | "
	label_gun.text = "Gun: " + str(GameState.gun_condition) + "%" + " | "
	label_ammo.text = "Ammo: " + str(GameState.ammo) + " | "
	

func load_event(event_resource: NarrativeEvent):
	main_text.text = event_resource.event_text
	btn_choice_1.text = event_resource.choice_1_text
	btn_choice_2.text = event_resource.choice_2_text

func _on_choice_1_pressed():
	# Simply tell the Event Manager that choice 1 was picked
	event_manager.process_choice(1)

func _on_choice_2_pressed():
	# Simply tell the Event Manager that choice 2 was picked
	event_manager.process_choice(2)

func _on_player_died():
	# Pause the game slightly before cutting to black for dramatic effect
	await get_tree().create_timer(1.0).timeout 
	get_tree().change_scene_to_file("res://Scene/GameOver.tscn")
	
func _on_make_camp_pressed():
	# For now, just print to the console so we know it works. 
	# Later, this will load the CampPhase.tscn overlay!
	print("Opening Camp Phase...")
