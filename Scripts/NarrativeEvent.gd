extends Resource
class_name NarrativeEvent

@export_group("Encounter Conditions")
@export var event_weight: int = 10
@export var required_keywords: Array[String] = []
@export var forbidden_keywords: Array[String] = []

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
@export var choice_1_item_reward: String = "" 
@export var choice_1_required_item: String = "" 
@export var choice_1_gives_affliction: String = "" 
@export var choice_1_cures_affliction: String = "" 
@export var choice_1_biome_change: String = "" 
@export var choice_1_triggers_combat: String = "" # NEW: Type the enemy name here (e.g., "Desert Hound")

@export_group("Choice 2 Effects")
@export var choice_2_water_cost: int = 0
@export var choice_2_ammo_cost: int = 0
@export var choice_2_food_cost: int = 0
@export var choice_2_gun_condition_cost: int = 0
@export var choice_2_grit_cost: int = 0
@export var choice_2_gap_penalty: int = 0
@export var choice_2_item_reward: String = "" 
@export var choice_2_required_item: String = "" 
@export var choice_2_gives_affliction: String = ""
@export var choice_2_cures_affliction: String = ""
@export var choice_2_biome_change: String = "" 
@export var choice_2_triggers_combat: String = "" # NEW: Type the enemy name here
