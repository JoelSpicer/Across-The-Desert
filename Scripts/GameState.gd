extends Node

# The Six Chambers
var gap_distance: int = 100 
var max_grit: int = 100
var current_grit: int = 100
var water: int = 20
var ammo: int = 12
var gun_condition: int = 100
var food: int = 5

# State Flags
var loop_count: int = 0
var has_horn_of_eld: bool = false
var current_afflictions: Array[String] = []

signal stats_changed 

func modify_water(amount: int):
	water += amount
	if water < 0: water = 0
	stats_changed.emit()
	_check_death_states()

func modify_grit(amount: int):
	current_grit += amount
	current_grit = clamp(current_grit, 0, max_grit)
	stats_changed.emit()
	_check_death_states()

# --- NEW FUNCTIONS START HERE ---

func modify_ammo(amount: int):
	ammo += amount
	if ammo < 0: ammo = 0
	stats_changed.emit()

func modify_gun_condition(amount: int):
	gun_condition += amount
	gun_condition = clamp(gun_condition, 0, 100)
	stats_changed.emit()

func modify_gap(amount: int):
	gap_distance += amount
	if gap_distance < 0: gap_distance = 0
	stats_changed.emit()
	_check_death_states()

# --- NEW FUNCTIONS END HERE ---

func _check_death_states():
	if current_grit <= 0:
		print("The desert claims you.")
	if gap_distance >= 200:
		print("The trail goes cold.")
