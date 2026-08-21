extends ColorRect
class_name AsciiBackground

# ------------------------------------------------------------------------
# UI REFERENCES
# ------------------------------------------------------------------------
@onready var text_display: RichTextLabel = $AsciiDisplay

# ------------------------------------------------------------------------
# LOAD AND RENDER ASCII ART
# ------------------------------------------------------------------------
func update_background(biome_name: String):
	# Construct the exact file path based on the current biome
	# e.g., "res://Resource/Art/biome_dunes.txt"
	#var file_name = "biome_" + biome_name.to_lower() + ".txt"
	var file_name = "biome_dunes.txt"
	var full_path = "res://Resource/Art/" + file_name
	
	# Open the text file in READ mode using Godot 4's FileAccess
	var file = FileAccess.open(full_path, FileAccess.READ)
	
	# Check if the file successfully opened
	if file:
		# Read the entire text file into a single string
		var raw_ascii = file.get_as_text()
		file.close()
		
		# Wrap the ASCII art in BBCode center tags to keep it aligned in the middle of the screen
		text_display.text = "[center]" + raw_ascii + "[/center]"
	else:
		# Fallback if the specific biome art hasn't been drawn yet
		print("WARNING: ASCII art not found at path: ", full_path)
		text_display.text = "[center]...[/center]"
