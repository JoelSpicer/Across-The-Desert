extends Resource
class_name NarrativeEvent

@export_multiline var event_text: String
@export var choice_1_text: String
@export var choice_2_text: String

# What happens when they click choice 1?
@export var choice_1_water_cost: int = 0
@export var choice_1_ammo_cost: int = 0
@export var choice_1_gap_penalty: int = 0

# What happens when they click choice 2?
@export var choice_2_water_cost: int = 0
@export var choice_2_ammo_cost: int = 0
@export var choice_2_gap_penalty: int = 0
