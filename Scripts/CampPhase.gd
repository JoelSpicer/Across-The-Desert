extends ColorRect

var max_hours: int = 8
var current_hours: int = 8
var hours_spent: int = 0

@onready var label_hours = $MarginContainer/VBoxContainer/HoursLabel
@onready var label_log = $MarginContainer/VBoxContainer/LogLabel

@onready var btn_sleep = $MarginContainer/VBoxContainer/HBoxContainer/BtnSleep
@onready var btn_maintain = $MarginContainer/VBoxContainer/HBoxContainer/BtnMaintain
@onready var btn_forage = $MarginContainer/VBoxContainer/HBoxContainer/BtnForage
@onready var btn_break_camp = $MarginContainer/VBoxContainer/BtnBreakCamp

func _ready():
	# Connect the buttons
	btn_sleep.pressed.connect(_on_sleep_pressed)
	btn_maintain.pressed.connect(_on_maintain_pressed)
	btn_forage.pressed.connect(_on_forage_pressed)
	btn_break_camp.pressed.connect(_on_break_camp_pressed)
	
	update_ui()

func update_ui():
	label_hours.text = "Time Remaining: " + str(current_hours) + " Hours"

func _on_sleep_pressed():
	if current_hours >= 4:
		current_hours -= 4
		hours_spent += 4
		GameState.modify_grit(40) # Sleeping heals 40 Grit
		label_log.text = "You sleep fitfully. (+40 Grit)"
		update_ui()
	else:
		label_log.text = "Not enough time to sleep."

func _on_maintain_pressed():
	if current_hours >= 2:
		current_hours -= 2
		hours_spent += 2
		GameState.modify_gun_condition(30) # Cleaning restores 30%
		label_log.text = "You clean sand from the cylinder. (+30% Gun)"
		update_ui()
	else:
		label_log.text = "Not enough time to maintain your gun."

func _on_forage_pressed():
	if current_hours >= 2:
		current_hours -= 2
		hours_spent += 2
		
		# Simple 50/50 probability check
		if randf() > 0.5:
			GameState.modify_water(2)
			label_log.text = "You found a damp root. (+2 Water)"
		else:
			label_log.text = "You found nothing but dust."
			
		update_ui()
	else:
		label_log.text = "Not enough time to forage."

func _on_break_camp_pressed():
	# Calculate the Gap penalty. For example, 5 units of distance per hour spent.
	var distance_lost = hours_spent * 5
	GameState.modify_gap(distance_lost)
	
	# The player rested, so the Exhaustion/Camp cycle resets. 
	# Delete this Camp UI scene to reveal the Main Game again.
	queue_free()
