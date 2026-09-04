extends ColorRect
class_name AsciiBackground

# ------------------------------------------------------------------------
# UI REFERENCES & ANIMATION VARIABLES
# ------------------------------------------------------------------------
@onready var text_display: RichTextLabel = $AsciiDisplay
var animation_timer: Timer

# Variables to hold the raw text strings in memory so we aren't 
# constantly reading from the hard drive every fraction of a second.
var frame_1: String = ""
var frame_2: String = ""
var is_showing_frame_1: bool = true

# ------------------------------------------------------------------------
# INITIALIZATION
# ------------------------------------------------------------------------
func _ready():
	# Create a timer dynamically through code to keep the scene tree clean
	animation_timer = Timer.new()
	
	# Set the animation speed. 0.5 seconds creates a nice, chunky retro feel.
	# Lower it (e.g., 0.2) for a faster, glitchier flicker.
	animation_timer.wait_time = 1.0
	animation_timer.autostart = false
	
	# Connect the timer's timeout signal to our swapping function
	animation_timer.timeout.connect(_on_timer_timeout)
	
	# Add the timer to the scene tree so it can actually run
	add_child(animation_timer)

# ------------------------------------------------------------------------
# LOAD AND RENDER ASCII ART
# ------------------------------------------------------------------------
func update_background(biome_name: String):
	# Halt any existing animation from the previous biome
	animation_timer.stop()
	
	# Construct the base file path using Godot 4's string formatting
	# Example: "res://Resource/Art/biome_dunes"
	var base_path = "res://Resource/Art/biome_" + biome_name.to_lower()
	#var base_path = "res://Resource/Art/biome_ruins"
	
	var path_1 = base_path + "_1.txt"
	var path_2 = base_path + "_2.txt"
	
	# --- LOAD FRAME 1 ---
	var file_1 = FileAccess.open(path_1, FileAccess.READ)
	if file_1:
		# Cache the text in memory with the alignment tags included
		frame_1 = "[center]" + file_1.get_as_text() + "[/center]"
		file_1.close()
	else:
		print("WARNING: ASCII art Frame 1 not found at: ", path_1)
		frame_1 = "[center]...[/center]"
		
	# Display the first frame immediately to prevent blank screens
	text_display.text = frame_1
	is_showing_frame_1 = true
	
	# --- LOAD FRAME 2 ---
	var file_2 = FileAccess.open(path_2, FileAccess.READ)
	if file_2:
		# If the second frame exists, cache it and start the animation cycle!
		frame_2 = "[center]" + file_2.get_as_text() + "[/center]"
		file_2.close()
		animation_timer.start()
	else:
		# If there is no second frame, clear the cache and leave the timer stopped
		frame_2 = ""

# ------------------------------------------------------------------------
# ANIMATION LOOP
# Triggered automatically every time the Timer hits 0
# ------------------------------------------------------------------------
func _on_timer_timeout():
	# Ping-pong between the two text variables in memory
	if is_showing_frame_1:
		text_display.text = frame_2
		is_showing_frame_1 = false
	else:
		text_display.text = frame_1
		is_showing_frame_1 = true
