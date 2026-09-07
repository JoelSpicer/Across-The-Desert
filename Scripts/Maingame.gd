extends Control

# ------------------------------------------------------------------------
# UI NODE REFERENCES
# Updated to route through the newly added EventPanel container!
# ------------------------------------------------------------------------
@onready var main_text = %MainText
@onready var btn_choice_1 = %Choice1Button
@onready var btn_choice_2 = %Choice2Button
@onready var btn_make_camp = %MakeCampButton
@onready var btn_rest = %RestButton

@onready var label_time = %TimeLabel
@onready var label_water = %WaterLabel
@onready var label_grit = %GritLabel
@onready var label_gap = %GapLabel
@onready var label_gun = %GunConditionLabel
@onready var label_ammo = %AmmoLabel

@onready var label_inventory_list = %InventoryList
@onready var label_debug_keywords = %DebugKeywordsLabel
@onready var label_afflictions = %AfflictionsLabel
@onready var settlement_phase = %SettlementPhase
@onready var combat_phase = %CombatPhase

# System Managers
@onready var event_manager = $EventManager
@onready var ascii_background = $BackgroundLayer


# ------------------------------------------------------------------------
# STAT TRACKING VARIABLES (For Tweens)
# Used to determine if a value changed so we can flash the UI text
# ------------------------------------------------------------------------
var prev_water: int = 0
var prev_grit: int = 0
var prev_gap: int = 0
var prev_gun: int = 0
var prev_ammo: int = 0
var prev_food: int = 0

var prev_inventory: Array[String] = []
var prev_afflictions: Array[String] = []

const CAMP_PHASE_SCENE = preload("res://Scene/CampPhase.tscn")

# ------------------------------------------------------------------------
# INITIALIZATION
# ------------------------------------------------------------------------
func _ready():
	# Connect to global GameState signals
	GameState.stats_changed.connect(update_hud)
	GameState.player_died.connect(_on_player_died)
	
	# Connect to phase signals with failsafes against double-connections
	if not combat_phase.combat_won.is_connected(_on_combat_won):
		combat_phase.combat_won.connect(_on_combat_won)
	
	if not settlement_phase.left_settlement.is_connected(_on_left_settlement):
		settlement_phase.left_settlement.connect(_on_left_settlement)
	
	# Listen for the moment the player catches the Man in Black
	if not GameState.boss_encounter_triggered.is_connected(_on_boss_encounter_triggered):
		GameState.boss_encounter_triggered.connect(_on_boss_encounter_triggered)
	
	# Set the baseline before updating the HUD so it doesn't flash immediately on load
	prev_water = GameState.water
	prev_grit = GameState.current_grit
	prev_gap = GameState.gap_distance
	prev_gun = GameState.gun_condition
	prev_ammo = GameState.ammo
	prev_food = GameState.food
	
	# Set the baseline for arrays using .duplicate() to pass by value, not reference
	prev_inventory = GameState.inventory.duplicate()
	prev_afflictions = GameState.current_afflictions.duplicate()
	
	# Initialize the UI
	update_hud()
	
	# Wire up local buttons
	btn_choice_1.pressed.connect(_on_choice_1_pressed)
	btn_choice_2.pressed.connect(_on_choice_2_pressed)
	btn_make_camp.pressed.connect(_on_make_camp_pressed)
	btn_rest.pressed.connect(_on_rest_pressed)
	
	# Kick off the game loop by triggering the very first event
	if event_manager:
		event_manager.trigger_random_event()

# ------------------------------------------------------------------------
# HUD UPDATES & ANIMATIONS
# ------------------------------------------------------------------------
func update_hud():
	# 1. TIME & LOCATION DISPLAY
	var time_name = GameState.TIME_STATES[GameState.time_index].to_upper()
	var hazard_warning = ""
	
	# Append a mechanical warning to the UI based on the current time state
	match GameState.time_index:
		0: hazard_warning = " (Standard Travel)"
		1: hazard_warning = " (High Water Loss / Heat Risk)"
		2: hazard_warning = " (Standard Travel)"
		3: hazard_warning = " (High Grit Loss / Gear Risk)"
		
	label_time.text = " | " + GameState.current_biome.to_upper() + " - " + time_name + hazard_warning + " | "
		
	
	# 2. CORE STAT LABELS
	label_water.text = "Water: " + str(GameState.water) + " | "
	label_grit.text = "Grit: " + str(GameState.current_grit) + " | "
	label_gap.text = "Gap: " + str(GameState.gap_distance) + " | "
	label_gun.text = "Gun: " + str(GameState.gun_condition) + "%" + " | "
	label_ammo.text = "Ammo: " + str(GameState.ammo) + " | "
	
	# --------------------------------------------------------------------
	# 3. DYNAMIC INVENTORY UI GENERATION
	# --------------------------------------------------------------------
	# Clear out any existing labels or buttons from the previous UI state
	for child in label_inventory_list.get_children():
		child.queue_free()
		
	if GameState.inventory.is_empty():
		# If empty, just spawn a standard label to indicate nothing is there
		var empty_label = Label.new()
		empty_label.text = "[Empty]"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label_inventory_list.add_child(empty_label)
	else:
		# Iterate through the array and build UI elements for each item
		for item_id in GameState.inventory:
			var display_name = item_id
			var is_consumable = false
			
			# Fetch the metadata from the global database
			if GameState.ITEM_DATABASE.has(item_id):
				display_name = GameState.ITEM_DATABASE[item_id]["name"]
				is_consumable = GameState.ITEM_DATABASE[item_id]["consumable"]
				
			if is_consumable:
				# --- BUILD INTERACTIVE BUTTON ---
				var btn = Button.new()
				btn.text = "Use " + display_name
				
				# Copy the 1-bit retro styling from your existing choice buttons
				btn.add_theme_stylebox_override("normal", btn_choice_1.get_theme_stylebox("normal"))
				btn.add_theme_stylebox_override("hover", btn_choice_1.get_theme_stylebox("hover"))
				btn.add_theme_stylebox_override("pressed", btn_choice_1.get_theme_stylebox("pressed"))
				btn.add_theme_stylebox_override("focus", btn_choice_1.get_theme_stylebox("focus"))
				
				# Copy the hover/invert text colors
				btn.add_theme_color_override("font_color", Color.WHITE)
				btn.add_theme_color_override("font_hover_color", Color.BLACK)
				btn.add_theme_color_override("font_pressed_color", Color.BLACK)
				btn.add_theme_color_override("font_focus_color", Color.BLACK)
				btn.add_theme_font_size_override("font_size", 12)
				
				# Bind the button press directly to the global item consumption logic
				btn.pressed.connect(GameState.consume_item.bind(item_id))
				
				# Attach the fully built button to the UI tree
				label_inventory_list.add_child(btn)
			else:
				# --- BUILD STATIC LABEL (KEY ITEMS) ---
				var lbl = Label.new()
				# Adding a little dash makes it look like a clean list
				lbl.text = "- " + display_name 
				lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				lbl.add_theme_font_size_override("font_size", 12)
				
				label_inventory_list.add_child(lbl)
	
	# Enable or disable the Camp button based on available food supplies
	if GameState.food > 0:
		btn_make_camp.disabled = false
		btn_make_camp.text = "Make Camp (-1 Food | Stock: " + str(GameState.food) + ")"
	else:
		btn_make_camp.disabled = true
		btn_make_camp.text = "No Food to Camp"
		
	btn_rest.text = "Hunker Down (Skip Event | Gap +15)"
	
	# Optional: Disable the button if the boss is already breathing down their neck
	if GameState.gap_distance <= 15:
		btn_rest.disabled = true
		btn_rest.text = "He's too close to rest!"
	else:
		btn_rest.disabled = false
		
	# 4. DEBUG TAGS & STATUS AFFLICTIONS
	var current_tags = GameState.get_current_keywords()
	if current_tags.is_empty():
		label_debug_keywords.text = "DEBUG TAGS:\n[None]"
	else:
		label_debug_keywords.text = "DEBUG TAGS:\n" + ", ".join(current_tags)
		
	if GameState.current_afflictions.is_empty():
		label_afflictions.text = "Status: Healthy"
	else:
		label_afflictions.text = "AFFLICTIONS:\n" + "\n".join(GameState.current_afflictions).capitalize()
	
	# 5. NARRATIVE CHOICE BUTTONS & ITEM LOCKS
	if event_manager.current_event != null:
		var current_event = event_manager.current_event
		
		btn_choice_1.text = current_event.choice_1_text
		if current_event.choice_1_required_item != "" and not GameState.inventory.has(current_event.choice_1_required_item):
			btn_choice_1.disabled = true
			btn_choice_1.text += "\n(Requires: " + current_event.choice_1_required_item + ")"
		else:
			btn_choice_1.disabled = false

		if current_event.choice_2_text != "":
			btn_choice_2.show()
			btn_choice_2.text = current_event.choice_2_text
			if current_event.choice_2_required_item != "" and not GameState.inventory.has(current_event.choice_2_required_item):
				btn_choice_2.disabled = true
				btn_choice_2.text += "\n(Requires: " + current_event.choice_2_required_item + ")"
			else:
				btn_choice_2.disabled = false
		else:
			btn_choice_2.hide()

	# 6. ANIMATE STAT CHANGES
	if GameState.water != prev_water:
		animate_label(label_water, GameState.water > prev_water)
		prev_water = GameState.water
		
	if GameState.current_grit != prev_grit:
		animate_label(label_grit, GameState.current_grit > prev_grit)
		prev_grit = GameState.current_grit
		
	if GameState.gap_distance != prev_gap:
		animate_label(label_gap, GameState.gap_distance < prev_gap) 
		prev_gap = GameState.gap_distance
		
	if GameState.gun_condition != prev_gun:
		animate_label(label_gun, GameState.gun_condition > prev_gun)
		prev_gun = GameState.gun_condition
		
	if GameState.ammo != prev_ammo:
		animate_label(label_ammo, GameState.ammo > prev_ammo)
		prev_ammo = GameState.ammo
		
	if GameState.food != prev_food:
		animate_label(btn_make_camp, GameState.food > prev_food)
		prev_food = GameState.food
	
	if GameState.inventory != prev_inventory:
		var gained_item = GameState.inventory.size() > prev_inventory.size()
		animate_label(label_inventory_list, gained_item)
		prev_inventory = GameState.inventory.duplicate()
		
	if GameState.current_afflictions != prev_afflictions:
		var gained_affliction = GameState.current_afflictions.size() > prev_afflictions.size()
		animate_label(label_afflictions, not gained_affliction)
		prev_afflictions = GameState.current_afflictions.duplicate()
# ------------------------------------------------------------------------
# 1-BIT UI FLICKER
# Replaces the smooth red/green fade with a harsh, retro visual glitch
# ------------------------------------------------------------------------
func animate_label(ui_element: Control, is_good: bool):
	var tween = create_tween()
	
	# Step 1: Snap to black (Invisible against your retro panels)
	tween.tween_property(ui_element, "modulate", Color.BLACK, 0.0)
	tween.tween_interval(0.1) # Wait a fraction of a second
	
	# Step 2: Snap back to white
	tween.tween_property(ui_element, "modulate", Color.WHITE, 0.0)
	tween.tween_interval(0.1)
	
	# Step 3: Snap to black again
	tween.tween_property(ui_element, "modulate", Color.BLACK, 0.0)
	tween.tween_interval(0.1)
	
	# Step 4: Final snap back to pure white
	tween.tween_property(ui_element, "modulate", Color.WHITE, 0.0)

# ------------------------------------------------------------------------
# EVENT & PHASE TRIGGERS
# ------------------------------------------------------------------------
func load_event(event_resource: NarrativeEvent):
	# 1. Push the main narrative text block into the UI reading panel
	main_text.text = event_resource.event_text
	
	# 2. Update the background layer to visually reflect the new environment
	ascii_background.update_background(GameState.current_biome)
	
	# 3. Force a complete HUD recalculation.
	# We no longer set button text manually in this function. Instead, calling
	# update_hud() guarantees that the game evaluates the brand-new event's 
	# resource costs against the player's current inventory, properly resetting 
	# the text, visibility, and disabled/greyed-out states of the choice buttons.
	update_hud()

func _on_choice_1_pressed():
	# Tell the Event Manager that choice 1 was picked
	event_manager.process_choice(1)

func _on_choice_2_pressed():
	# Tell the Event Manager that choice 2 was picked
	event_manager.process_choice(2)

func _on_make_camp_pressed():
	# Double-check they have food, just to be safe
	if GameState.food > 0:
		# Deduct 1 food as the cost of setting up camp
		GameState.modify_food(-1) 
		
		# Instantiate the camp phase overlay and attach it to the screen
		var camp_instance = CAMP_PHASE_SCENE.instantiate()
		add_child(camp_instance)
		
func _on_rest_pressed():
	# 1. Let time pass safely without travel penalties
	GameState.rest_in_place()
	
	# 2. Draw a new event (effectively letting you skip the current encounter)
	event_manager.trigger_random_event()

# ------------------------------------------------------------------------
# DEATH & BOSS STATES
# ------------------------------------------------------------------------
func _on_player_died():
	# Hide the entire root Control node so neither the main HUD 
	# nor any active Combat/Camp overlays remain visible during the tear-down
	hide()
	
	# Transition cleanly to the Game Over screen
	get_tree().call_deferred("change_scene_to_file", "res://Scene/GameOver.tscn")
	
func _on_boss_encounter_triggered():
	# Hide the standard event UI so it doesn't overlap the combat screen
	$MarginContainer.hide() 
	
	# Start the combat phase using the special ":boss" tag we are about to create.
	# The Man in Black comes with a mechanical hound to make it a 2v1 fight!
	combat_phase.start_combat("Man in Black:boss, Clockwork Hound:melee")

# ------------------------------------------------------------------------
# COMBAT & SETTLEMENT FLOW
# ------------------------------------------------------------------------
# Called by the EventManager when a choice triggers a fight
func trigger_combat_encounter(enemy_name: String):
	combat_phase.start_combat(enemy_name)
	
func _on_combat_won():
	# Check if this was the Final Confrontation by looking at the Gap
	if GameState.gap_distance <= 0:
		# We beat the boss! 
		# call_deferred queues the scene change safely at the end of the frame,
		# preventing Godot from silently crashing the transition.
		get_tree().call_deferred("change_scene_to_file", "res://Scene/GameOver.tscn")
	else:
		# It was just a standard desert ambush. 
		# If we hid the UI for a boss fight, bring it back
		$MarginContainer.show() 
		
		# Resume the journey by drawing the next random event.
		event_manager.trigger_random_event()

# Called by the EventManager when a choice triggers a town
func open_settlement_encounter(settlement_name: String):
	settlement_phase.open_settlement(settlement_name)

# Called automatically when the player clicks "Leave" in a settlement
func _on_left_settlement():
	# Move the clock forward and draw the next event in the journey
	GameState.advance_time()
	event_manager.trigger_random_event()
