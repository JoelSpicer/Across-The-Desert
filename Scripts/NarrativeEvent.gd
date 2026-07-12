extends Resource
class_name NarrativeEvent

@export_multiline var event_text: String
@export var choice_1_text: String
@export var choice_2_text: String

@export_group("Choice 1 Effects")
@export var choice_1_water_cost: int = 0
@export var choice_1_ammo_cost: int = 0
@export var choice_1_food_cost: int = 0
@export var choice_1_gun_condition_cost: int = 0
@export var choice_1_grit_cost: int = 0
@export var choice_1_gap_penalty: int = 0
@export var choice_1_item_reward: String = "" # Type a string like "Rusty Key" to award an item
@export var choice_1_required_item: String = "" # If not blank, the player MUST have this item to pick this choice

@export_group("Choice 2 Effects")
# ... (Duplicate the exact same variables for Choice 2) ...
@export var choice_2_water_cost: int = 0
@export var choice_2_ammo_cost: int = 0
@export var choice_2_food_cost: int = 0
@export var choice_2_gun_condition_cost: int = 0
@export var choice_2_grit_cost: int = 0
@export var choice_2_gap_penalty: int = 0
@export var choice_2_item_reward: String = "" 
@export var choice_2_required_item: String = ""
