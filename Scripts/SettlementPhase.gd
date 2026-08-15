extends Control
class_name SettlementPhase

signal left_settlement

@onready var label_title = %LabelTitle
@onready var label_feedback = %LabelFeedback

# Shop Buttons
@onready var btn_buy_water = %BtnBuyWater
@onready var btn_buy_food = %BtnBuyFood
@onready var btn_doctor = %BtnDoctor
@onready var btn_leave = %BtnLeave

func _ready():
	# Auto-wire the buttons
	btn_buy_water.pressed.connect(_on_btn_buy_water_pressed)
	btn_buy_food.pressed.connect(_on_btn_buy_food_pressed)
	btn_doctor.pressed.connect(_on_btn_doctor_pressed)
	btn_leave.pressed.connect(_on_btn_leave_pressed)

func open_settlement(settlement_name: String):
	label_title.text = "--- " + settlement_name.to_upper() + " ---"
	label_feedback.text = "A rare safe haven. Your ammo is as good as gold here."
	show()

func _on_btn_buy_water_pressed():
	if GameState.ammo >= 2:
		GameState.modify_ammo(-2)
		GameState.modify_water(15) # Heals 15 water
		label_feedback.text = "Traded 2 Ammo for a canteen of dirty water."
	else:
		label_feedback.text = "You don't have enough Ammo to trade for water."

func _on_btn_buy_food_pressed():
	if GameState.ammo >= 3:
		GameState.modify_ammo(-3)
		GameState.modify_food(1)
		label_feedback.text = "Traded 3 Ammo for some dried meat."
	else:
		label_feedback.text = "You don't have enough Ammo to trade for food."

func _on_btn_doctor_pressed():
	if GameState.current_afflictions.is_empty():
		label_feedback.text = "The doctor looks you over. 'You're fine, save your bullets.'"
		return
		
	if GameState.ammo >= 5:
		GameState.modify_ammo(-5)
		# Clear the first affliction in the array
		var cured = GameState.current_afflictions[0]
		GameState.remove_affliction(cured)
		label_feedback.text = "Traded 5 Ammo. The doctor patched your " + cured + "."
	else:
		label_feedback.text = "You need 5 Ammo for medical attention."

func _on_btn_leave_pressed():
	hide()
	left_settlement.emit()
