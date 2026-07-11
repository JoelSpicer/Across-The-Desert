extends Node

# The Six Chambers
var gap_distance: int = 100 # Hits 200? Game Over. Hits 0? Boss Fight.
var max_grit: int = 100
var current_grit: int = 100
var water: int = 20
var ammo: int = 12
var gun_condition: int = 100
var food: int = 5

# State Flags for the Roguelike loop
var loop_count: int = 0
var has_horn_of_eld: bool = false
var current_afflictions: Array[String] = []

signal stats_changed # Tell the UI to update when things change

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

func _check_death_states():
	if current_grit <= 0:
		print("The desert claims you.")
		# Trigger Game Over sequence
	if gap_distance >= 200:
		print("The trail goes cold.")
		# Trigger Game Over sequence
