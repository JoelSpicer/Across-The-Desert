extends ColorRect

var max_hours: int = 8
var current_hours: int = 8
var hours_spent: int = 0

# ------------------------------------------------------------------------
# SCAVENGING LOOT TABLES
# Expanded to include all utility, medical, and combat consumables!
# ------------------------------------------------------------------------
var biome_loot_tables = {
	"ruins": [
		{"type": "ammo", "amount": 2, "weight": 35, "name": "a handful of bullets"},
		{"type": "item", "amount": 1, "weight": 15, "name": "a sterile Bandage", "item_id": "Bandage"},
		{"type": "item", "amount": 1, "weight": 15, "name": "a tin of Gun Oil", "item_id": "Oil"},
		{"type": "item", "amount": 1, "weight": 10, "name": "a Stamina Ampoule", "item_id": "Stamina"},
		{"type": "nothing", "amount": 0, "weight": 25, "name": "nothing but rust and dust"}
	],
	"scrubland": [
		{"type": "water", "amount": 15, "weight": 40, "name": "some muddy but drinkable water"},
		{"type": "food", "amount": 1, "weight": 20, "name": "some edible root vegetables"},
		{"type": "item", "amount": 1, "weight": 15, "name": "a sealed Canteen Ration", "item_id": "Canteen"},
		{"type": "item", "amount": 1, "weight": 10, "name": "some medicinal leaves", "item_id": "Bandage"},
		{"type": "item", "amount": 1, "weight": 5, "name": "a pungent bottle of Smelling Salts", "item_id": "Salts"},
		{"type": "nothing", "amount": 0, "weight": 10, "name": "only dried twigs"}
	],
	"canyons": [
		{"type": "water", "amount": 10, "weight": 30, "name": "rainwater pooled in the rocks"},
		{"type": "ammo", "amount": 1, "weight": 20, "name": "a dropped shell casing"},
		{"type": "item", "amount": 1, "weight": 15, "name": "an old scavenger's Map", "item_id": "Map"},
		{"type": "item", "amount": 1, "weight": 10, "name": "a questionable bottle of Snake Oil", "item_id": "SnakeOil"},
		{"type": "nothing", "amount": 0, "weight": 25, "name": "nothing but shadows"}
	],
	"flats": [
		{"type": "nothing", "amount": 0, "weight": 60, "name": "absolutely nothing in the salt"},
		{"type": "ammo", "amount": 1, "weight": 20, "name": "a bullet buried in the crust"},
		{"type": "item", "amount": 1, "weight": 20, "name": "a salvaged tub of Creatine Powder", "item_id": "Creatine"}
	],
	"dunes": [
		{"type": "nothing", "amount": 0, "weight": 50, "name": "only endless, shifting sand"},
		{"type": "item", "amount": 1, "weight": 20, "name": "a half-buried Scrap piece", "item_id": "Scrap"},
		{"type": "item", "amount": 1, "weight": 15, "name": "a salvaged tub of Creatine Powder", "item_id": "Creatine"},
		{"type": "water", "amount": 5, "weight": 15, "name": "condensation from a deep dig"}
	]
}

@onready var label_hours = $MarginContainer/PanelContainer/VBoxContainer/HoursLabel
@onready var label_log = $MarginContainer/PanelContainer/VBoxContainer/LogLabel

@onready var btn_sleep = %BtnSleep
@onready var btn_maintain = %BtnMaintain
@onready var btn_forage = %BtnForage
@onready var btn_break_camp = %BtnBreakCamp

func _ready():
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
		GameState.modify_grit(40) 
		GameState.clear_all_afflictions()
		label_log.text = "You sleep fitfully. (+40 Grit)"
		update_ui()
	else:
		label_log.text = "Not enough time to sleep."

func _on_maintain_pressed():
	if current_hours >= 2:
		current_hours -= 2
		hours_spent += 2
		GameState.modify_gun_condition(30) 
		label_log.text = "You clean sand from the cylinder. (+30% Gun)"
		update_ui()
	else:
		label_log.text = "Not enough time to maintain your gun."

func _on_forage_pressed():
	if current_hours >= 2:
		current_hours -= 2
		hours_spent += 2
		
		GameState.modify_grit(-1)
		
		var current_biome = GameState.current_biome.to_lower()
		
		if not biome_loot_tables.has(current_biome):
			current_biome = "flats" 
			
		var possible_loot = biome_loot_tables[current_biome]
		var total_weight = 0
		
		for drop in possible_loot:
			total_weight += drop["weight"]
			
		var roll = randi() % total_weight
		var current_weight = 0
		var won_drop = null
		
		for drop in possible_loot:
			current_weight += drop["weight"]
			if roll < current_weight:
				won_drop = drop
				break
				
		if won_drop != null:
			match won_drop["type"]:
				"water":
					GameState.modify_water(won_drop["amount"])
				"ammo":
					GameState.modify_ammo(won_drop["amount"])
				"food":
					GameState.modify_food(won_drop["amount"])
				"item":
					GameState.add_item(won_drop["item_id"])
				"nothing":
					pass 
					
			label_log.text = "You spend 2 hours scouring the area and find " + won_drop["name"] + "."
			
		update_ui()
	else:
		label_log.text = "Not enough time to forage."

func _on_break_camp_pressed():
	var distance_lost = hours_spent * 2
	GameState.modify_gap(distance_lost)
	queue_free()
