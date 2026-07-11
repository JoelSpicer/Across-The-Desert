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

var death_reason: String = "" # Stores the specific failure message
var is_dead: bool = false

signal stats_changed 
signal player_died # New signal to tell the UI to change scenes

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

func _check_death_states():
	if is_dead:
		return
		
	if current_grit <= 0:
		is_dead = true # Add this line!
		death_reason = "The desert claims you. Your grit has failed."
		player_died.emit()
	elif gap_distance >= 200:
		is_dead = true # Add this line!
		death_reason = "The trail goes cold. He has escaped."
		player_died.emit()

func reset_run():
	is_dead = false
	# Increase the loop count for meta-progression tracking
	loop_count += 1
	
	# Reset core stats back to default
	gap_distance = 100
	current_grit = max_grit
	water = 20
	ammo = 12
	gun_condition = 100
	food = 5
	current_afflictions.clear()
	
	stats_changed.emit()
