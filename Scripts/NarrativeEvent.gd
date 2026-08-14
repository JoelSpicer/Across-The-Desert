extends Resource
class_name NarrativeEvent

# ------------------------------------------------------------------------
# ENCOUNTER CONDITIONS
# These variables determine when and how often this event can appear.
# ------------------------------------------------------------------------
@export_group("Encounter Conditions")
@export var event_weight: int = 10 # 10 is standard weight, lower for rarer events.
@export var required_keywords: Array[String] = [] # e.g., ["night", "bleeding"]
@export var forbidden_keywords: Array[String] = [] # e.g., ["day"]

# ------------------------------------------------------------------------
# NARRATIVE TEXT
# The story text and the text displayed on the two choice buttons.
# ------------------------------------------------------------------------
@export_multiline var event_text: String
@export var choice_1_text: String
@export var choice_2_text: String

# ------------------------------------------------------------------------
# CHOICE 1 EFFECTS
# All the mechanical consequences and rewards for picking the first button.
# ------------------------------------------------------------------------
@export_group("Choice 1 Effects")
@export var choice_1_water_cost: int = 0
@export var choice_1_ammo_cost: int = 0
@export var choice_1_food_cost: int = 0
@export var choice_1_gun_condition_cost: int = 0
@export var choice_1_grit_cost: int = 0
@export var choice_1_gap_penalty: int = 0
@export var choice_1_item_reward: String = "" 
@export var choice_1_required_item: String = "" 
@export var choice_1_gives_affliction: String = "" # E.g., "Bleeding"
@export var choice_1_cures_affliction: String = "" # E.g., "Exhausted"
@export var choice_1_biome_change: String = "" # NEW: Type "canyons", "flats", etc., to move the player

# ------------------------------------------------------------------------
# CHOICE 2 EFFECTS
# All the mechanical consequences and rewards for picking the second button.
# ------------------------------------------------------------------------
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
@export var choice_2_biome_change: String = "" # NEW: Type a biome tag here to move the player
