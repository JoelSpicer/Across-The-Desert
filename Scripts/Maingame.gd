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

@onready var label_debug_keywords = %DebugKeywordsLabel
@onready var label_afflictions = %AfflictionsLabel
@onready var settlement_phase = %SettlementPhase

@onready var combat_phase = %CombatPhase
@onready var event_manager = $EventManager # Reference the new node

# --- NEW: STAT TRACKING VARIABLES ---
var prev_water: int = 0
var prev_grit: int = 0
var prev_gap: int = 0
var prev_gun: int = 0
var prev_ammo: int = 0
var prev_food: int = 0

# --- NEW: ARRAY TRACKING VARIABLES ---
var prev_inventory: Array[String] = []
var prev_afflictions: Array[String] = []

const CAMP_PHASE_SCENE = preload("res://Scene/CampPhase.tscn")

func _ready():
	GameState.stats_changed.connect(update_hud)
	GameState.player_died.connect(_on_player_died)
	if not combat_phase.combat_won.is_connected(_on_combat_won):
		combat_phase.combat_won.connect(_on_combat_won)
	settlement_phase.left_settlement.connect(_on_left_settlement)
	
	# NEW: Listen for the moment the player catches the Man in Black
	if not GameState.boss_encounter_triggered.is_connected(_on_boss_encounter_triggered):
		GameState.boss_encounter_triggered.connect(_on_boss_encounter_triggered)
	
	# Set the baseline before updating the HUD
	prev_water = GameState.water
	prev_grit = GameState.current_grit
	prev_gap = GameState.gap_distance
	prev_gun = GameState.gun_condition
	prev_ammo = GameState.ammo
	prev_food = GameState.food
	
	# Set the baseline for arrays using .duplicate()!
	prev_inventory = GameState.inventory.duplicate()
	prev_afflictions = GameState.current_afflictions.duplicate()
	
	update_hud()
	
	btn_choice_1.pressed.connect(_on_choice_1_pressed)
	btn_choice_2.pressed.connect(_on_choice_2_pressed)
	btn_make_camp.pressed.connect(_on_make_camp_pressed)
	
	if event_manager:
		event_manager.trigger_random_event()

func update_hud():
	# ------------------------------------------------------------------------
	# 1. TIME & LOCATION DISPLAY
	# Determine if it is Day or Night to show current survival penalties
	# ------------------------------------------------------------------------
	var time_string = "DAY (2x Water Loss)"
	if not GameState.is_day:
		time_string = "NIGHT (2x Grit Loss)"
		
	# Combine Biome and Time for a clean location header
	label_time.text = " | " + GameState.current_biome.to_upper() + " - " + time_string + " | "
	
	# ------------------------------------------------------------------------
	# 2. CORE STAT LABELS
	# Update numerical HUD values directly from the GameState singleton
	# ------------------------------------------------------------------------
	label_water.text = "Water: " + str(GameState.water) + " | "
	label_grit.text = "Grit: " + str(GameState.current_grit) + " | "
	label_gap.text = "Gap: " + str(GameState.gap_distance) + " | "
	label_gun.text = "Gun: " + str(GameState.gun_condition) + "%" + " | "
	label_ammo.text = "Ammo: " + str(GameState.ammo) + " | "
	
	# ------------------------------------------------------------------------
	# 3. INVENTORY & CAMP DISPLAY
	# ------------------------------------------------------------------------
	if GameState.inventory.is_empty():
		label_inventory_list.text = "[Empty]"
	else:
		# "\n" places a line break between each item in the array for clean sidebar listing
		label_inventory_list.text = "\n".join(GameState.inventory)
	
	# Enable or disable the Camp button based on available food supplies
	if GameState.food > 0:
		btn_make_camp.disabled = false
		btn_make_camp.text = "Make Camp (-1 Food | Stock: " + str(GameState.food) + ")"
	else:
		btn_make_camp.disabled = true
		btn_make_camp.text = "No Food to Camp"
		
	# ------------------------------------------------------------------------
	# 4. DEBUG TAGS & STATUS AFFLICTIONS
	# ------------------------------------------------------------------------
	var current_tags = GameState.get_current_keywords()
	if current_tags.is_empty():
		label_debug_keywords.text = "DEBUG TAGS:\n[None]"
	else:
		# Join active tags with commas for readable debugging outpu
		label_debug_keywords.text = "DEBUG TAGS:\n" + ", ".join(current_tags)
		
	# Update the Afflictions status container
	if GameState.current_afflictions.is_empty():
		label_afflictions.text = "Status: Healthy"
	else:
		label_afflictions.text = "AFFLICTIONS:\n" + "\n".join(GameState.current_afflictions).capitalize()
	
	# ------------------------------------------------------------------------
	# 5. NARRATIVE CHOICE BUTTONS & ITEM LOCKS
	# Update button text and check for required inventory items
	# ------------------------------------------------------------------------
	if event_manager.current_event != null:
		var current_event = event_manager.current_event
		
		# --- Choice 1 Setup ---
		btn_choice_1.text = current_event.choice_1_text
		# If a required item is specified and missing from inventory, lock the button
		if current_event.choice_1_required_item != "" and not GameState.inventory.has(current_event.choice_1_required_item):
			btn_choice_1.disabled = true
			btn_choice_1.text += "\n(Requires: " + current_event.choice_1_required_item + ")"
		else:
			btn_choice_1.disabled = false

		# --- Choice 2 Setup ---
		if current_event.choice_2_text != "":
			btn_choice_2.show()
			btn_choice_2.text = current_event.choice_2_text
			# If a required item is specified and missing from inventory, lock the button
			if current_event.choice_2_required_item != "" and not GameState.inventory.has(current_event.choice_2_required_item):
				btn_choice_2.disabled = true
				btn_choice_2.text += "\n(Requires: " + current_event.choice_2_required_item + ")"
			else:
				btn_choice_2.disabled = false
		else:
			btn_choice_2.hide()

	# ------------------------------------------------------------------------
	# 6. ANIMATE STAT CHANGES
	# Trigger flash/tween animations when current values diverge from previous snapshots
	# ------------------------------------------------------------------------
	# 1. Water
	if GameState.water != prev_water:
		animate_label(label_water, GameState.water > prev_water)
		prev_water = GameState.water
		
	# 2. Grit
	if GameState.current_grit != prev_grit:
		animate_label(label_grit, GameState.current_grit > prev_grit)
		prev_grit = GameState.current_grit
		
	# 3. Gap (Gap is positive when the number decreases, so the check is inverted)
	if GameState.gap_distance != prev_gap:
		animate_label(label_gap, GameState.gap_distance < prev_gap) 
		prev_gap = GameState.gap_distance
		
	# 4. Gun Condition
	if GameState.gun_condition != prev_gun:
		animate_label(label_gun, GameState.gun_condition > prev_gun)
		prev_gun = GameState.gun_condition
		
	# 5. Ammo
	if GameState.ammo != prev_ammo:
		animate_label(label_ammo, GameState.ammo > prev_ammo)
		prev_ammo = GameState.ammo
		
	# 6. Food (Animates the camp button where food inventory is shown)
	if GameState.food != prev_food:
		animate_label(btn_make_camp, GameState.food > prev_food)
		prev_food = GameState.food
	
	# 7. Inventory
	if GameState.inventory != prev_inventory:
		var gained_item = GameState.inventory.size() > prev_inventory.size()
		animate_label(label_inventory_list, gained_item)
		prev_inventory = GameState.inventory.duplicate()
		
	# 8. Afflictions (Gaining an affliction is harmful, so invert the boolean)
	if GameState.current_afflictions != prev_afflictions:
		var gained_affliction = GameState.current_afflictions.size() > prev_afflictions.size()
		animate_label(label_afflictions, not gained_affliction)
		prev_afflictions = GameState.current_afflictions.duplicate()

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

# ------------------------------------------------------------------------
# DEATH STATE TRANSITION
# Triggered automatically when GameState emits 'player_died'
# ------------------------------------------------------------------------
func _on_player_died():
	# Hide any active popups or UI elements so they don't visually glitch
	# while the engine is tearing down the current scene
	$MarginContainer.hide()
	
	# Pass control over to the Game Over scene.
	# Because GameState.is_dead is now true, GameOver.gd will automatically
	# realize this is a defeat rather than a victory.
	get_tree().change_scene_to_file("res://Scene/GameOver.tscn")
	
func _on_make_camp_pressed():
	# Double-check they have food, just to be safe
	if GameState.food > 0:
		# Deduct 1 food as the cost of setting up camp
		GameState.modify_food(-1) 
		
		# Instantiate the camp phase overlay
		var camp_instance = CAMP_PHASE_SCENE.instantiate()
		add_child(camp_instance)

func animate_label(ui_element: Control, is_good: bool):
	# Create a Godot 4 tween
	var tween = create_tween()
	
	# Determine the flash color (Green for good, Red for bad)
	var flash_color = Color.GREEN if is_good else Color.RED
	
	# Phase 1: Instantly snap the color to red or green
	tween.tween_property(ui_element, "modulate", flash_color, 0.1)
	
	# Phase 2: Smoothly fade back to default white over half a second
	tween.tween_property(ui_element, "modulate", Color.WHITE, 2.0)

# Called by the EventManager when a choice triggers a fight
func trigger_combat_encounter(enemy_name: String):
	combat_phase.start_combat(enemy_name)
	
# ------------------------------------------------------------------------
# THE FINAL CONFRONTATION
# Triggers instantly when the Gap reaches 0
# ------------------------------------------------------------------------
func _on_boss_encounter_triggered():
	# Hide the standard event UI so it doesn't overlap the combat screen
	#%EventUI.hide() 
	
	# Start the combat phase using the special ":boss" tag we are about to create.
	# The Man in Black comes with a mechanical hound to make it a 2v1 fight!
	combat_phase.start_combat("The Man in Black:boss, Clockwork Hound:melee")

# Called automatically when the player wins the fight
func _on_combat_won():
	# Check if the player has closed the distance entirely. 
	# If Gap is 0, the fight they just survived was the Final Confrontation!
	if GameState.gap_distance <= 0:
		# Trigger the victory state
		GameState.game_won.emit()
	else:
	# Resume the normal game loop now that the threat is dead
		GameState.advance_time()
		event_manager.trigger_random_event()

# --- NEW SETTLEMENT FLOW FUNCTIONS ---

# Called by the EventManager when a choice triggers a town
func open_settlement_encounter(settlement_name: String):
	settlement_phase.open_settlement(settlement_name)

# Called automatically when the player clicks "Leave"
func _on_left_settlement():
	GameState.advance_time()
	event_manager.trigger_random_event()
