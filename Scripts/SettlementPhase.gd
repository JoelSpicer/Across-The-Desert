extends Control
class_name SettlementPhase

signal left_settlement

# ------------------------------------------------------------------------
# UI REFERENCES
# ------------------------------------------------------------------------
@onready var label_title = %LabelTitle
@onready var label_feedback = %LabelFeedback

@onready var btn_buy_water = %BtnBuyWater
@onready var btn_buy_food = %BtnBuyFood
@onready var btn_doctor = %BtnDoctor
@onready var btn_special = %BtnSpecial # NEW: Button for unique items
@onready var btn_leave = %BtnLeave

# ------------------------------------------------------------------------
# SETTLEMENT DATABASE
# This dictionary stores the unique rules, prices, and stock for every 
# settlement in the game. You can easily add more here later!
# ------------------------------------------------------------------------
var settlement_db = {
	"Scrap Town": {
		"desc": "A rare safe haven. Your ammo is as good as gold here.",
		"water_price": 2, "food_price": 3, "doc_price": 3,
		"has_water": true, "has_food": true, "has_doc": true,
		"special_item": "", "special_price": 0
	},
	"Oasis Traders": {
		"desc": "A lush watering hole. Water is plentiful and cheap, but they lack medical supplies.",
		"water_price": 1, "food_price": 2, "doc_price": 0,
		"has_water": true, "has_food": true, "has_doc": false,
		"special_item": "", "special_price": 0
	},
	"Hermit's Shack": {
		"desc": "A crazy old doctor lives here in solitude. He has no food or water to spare.",
		"water_price": 0, "food_price": 0, "doc_price": 1, # Doctor is cheaper here!
		"has_water": false, "has_food": false, "has_doc": true,
		"special_item": "Map", "special_price": 4 # Sells a unique item
	}
}

# This tracks the data for whatever settlement the player is currently inside
var current_data = {}

# ------------------------------------------------------------------------
# INITIALIZATION
# ------------------------------------------------------------------------
func _ready():
	# Auto-wire the buttons
	btn_buy_water.pressed.connect(_on_btn_buy_water_pressed)
	btn_buy_food.pressed.connect(_on_btn_buy_food_pressed)
	btn_doctor.pressed.connect(_on_btn_doctor_pressed)
	btn_special.pressed.connect(_on_btn_special_pressed)
	btn_leave.pressed.connect(_on_btn_leave_pressed)

func open_settlement(settlement_name: String):
	# Fallback to Scrap Town if the name isn't found in the database
	if not settlement_db.has(settlement_name):
		settlement_name = "Scrap Town"
		
	current_data = settlement_db[settlement_name]
	
	# Update the UI headers
	label_title.text = "--- " + settlement_name.to_upper() + " ---"
	label_feedback.text = current_data["desc"]
	
	# Configure the Water Button
	if current_data["has_water"]:
		btn_buy_water.text = "Buy Water (" + str(current_data["water_price"]) + " Ammo)"
		btn_buy_water.show()
	else:
		btn_buy_water.hide()
		
	# Configure the Food Button
	if current_data["has_food"]:
		btn_buy_food.text = "Buy Food (" + str(current_data["food_price"]) + " Ammo)"
		btn_buy_food.show()
	else:
		btn_buy_food.hide()
		
	# Configure the Doctor Button
	if current_data["has_doc"]:
		btn_doctor.text = "See Doctor (" + str(current_data["doc_price"]) + " Ammo)"
		btn_doctor.show()
	else:
		btn_doctor.hide()
		
	# Configure the Special Item Button
	if current_data["special_item"] != "":
		var item_name = current_data["special_item"]
		var item_price = str(current_data["special_price"])
		btn_special.text = "Buy " + item_name + " (" + item_price + " Ammo)"
		
		# Hide the button if the player already owns this unique item
		if GameState.inventory.has(item_name):
			btn_special.hide()
		else:
			btn_special.show()
	else:
		btn_special.hide()
	
	show()

# ------------------------------------------------------------------------
# BUTTON LOGIC
# ------------------------------------------------------------------------
func _on_btn_buy_water_pressed():
	var price = current_data["water_price"]
	if GameState.ammo >= price:
		GameState.modify_ammo(-price)
		GameState.modify_water(15)
		label_feedback.text = "Traded " + str(price) + " Ammo for a canteen of water."
	else:
		label_feedback.text = "You don't have enough Ammo to trade for water."

func _on_btn_buy_food_pressed():
	var price = current_data["food_price"]
	if GameState.ammo >= price:
		GameState.modify_ammo(-price)
		GameState.modify_food(1)
		label_feedback.text = "Traded " + str(price) + " Ammo for some dried meat."
	else:
		label_feedback.text = "You don't have enough Ammo to trade for food."

# ------------------------------------------------------------------------
# DOCTOR LOGIC (Updated to clear all conditions)
# ------------------------------------------------------------------------
func _on_btn_doctor_pressed():
	# If the player has absolutely no statuses, the doctor refuses service
	if GameState.current_afflictions.is_empty():
		label_feedback.text = "The doctor looks you over. 'You're fine, save your bullets.'"
		return
		
	var price = current_data["doc_price"]
	
	# Check if the player can afford the treatment
	if GameState.ammo >= price:
		GameState.modify_ammo(-price)
		
		# Wipe every single buff and debuff from the player
		GameState.clear_all_afflictions()
		
		# Provide narrative feedback that the slate has been wiped clean
		label_feedback.text = "Traded " + str(price) + " Ammo. The doctor patched you up and purged your system. You feel completely reset."
	else:
		label_feedback.text = "You need " + str(price) + " Ammo for medical attention."

func _on_btn_special_pressed():
	var price = current_data["special_price"]
	var item = current_data["special_item"]
	
	if GameState.ammo >= price:
		GameState.modify_ammo(-price)
		GameState.add_item(item)
		label_feedback.text = "Traded " + str(price) + " Ammo for the " + item + "."
		btn_special.hide() # Remove the button so they can't buy it twice
	else:
		label_feedback.text = "You need " + str(price) + " Ammo for the " + item + "."

func _on_btn_leave_pressed():
	hide()
	left_settlement.emit()
