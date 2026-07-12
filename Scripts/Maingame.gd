extends Control

@onready var main_text = $MarginContainer/HBoxContainer/VBoxContainer/EventDisplayArea/MainText
@onready var btn_choice_1 = $MarginContainer/HBoxContainer/VBoxContainer/ActionButtons/Choice1Button
@onready var btn_choice_2 = $MarginContainer/HBoxContainer/VBoxContainer/ActionButtons/Choice2Button
@onready var label_water = $MarginContainer/HBoxContainer/VBoxContainer/TopHUD/WaterLabel
@onready var label_grit = $MarginContainer/HBoxContainer/VBoxContainer/TopHUD/GritLabel
@onready var label_gap = $MarginContainer/HBoxContainer/VBoxContainer/TopHUD/GapLabel
@onready var label_gun = $MarginContainer/HBoxContainer/VBoxContainer/TopHUD/GunConditionLabel
@onready var label_ammo = $MarginContainer/HBoxContainer/VBoxContainer/TopHUD/AmmoLabel
@onready var btn_make_camp = $MarginContainer/HBoxContainer/VBoxContainer/ActionButtons/MakeCampButton
@onready var label_time = $MarginContainer/HBoxContainer/VBoxContainer/TopHUD/TimeLabel
@onready var label_inventory_list = %InventoryList

@onready var event_manager = $EventManager # Reference the new node

const CAMP_PHASE_SCENE = preload("res://Scene/CampPhase.tscn")

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
	
	if GameState.inventory.is_empty():
		label_inventory_list.text = "[Empty]"
	else:
		# The "\n" automatically puts a line break between each item in the array
		label_inventory_list.text = "\n".join(GameState.inventory)
	
	# Check food and update the Camp button
	if GameState.food > 0:
		btn_make_camp.disabled = false
		btn_make_camp.text = "Make Camp (-1 Food | Stock: " + str(GameState.food) + ")"
	else:
		btn_make_camp.disabled = true
		btn_make_camp.text = "No Food to Camp"
	

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
	# Double-check they have food, just to be safe
	if GameState.food > 0:
		# Deduct 1 food as the cost of setting up camp
		GameState.modify_food(-1) 
		
		# Instantiate the camp phase overlay
		var camp_instance = CAMP_PHASE_SCENE.instantiate()
		add_child(camp_instance)
