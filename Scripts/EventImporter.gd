@tool
extends EditorScript

func _run():
	var file_path = "res://bulk_events.json"
	
	# 1. Verify the JSON file exists
	if not FileAccess.file_exists(file_path):
		print("ERROR: Please create a bulk_events.json file in your res:// folder.")
		return
		
	# 2. Read and parse the JSON
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json = JSON.parse_string(file.get_as_text())
	
	if typeof(json) != TYPE_ARRAY:
		print("ERROR: JSON must be formatted as an array of objects: [...]")
		return
		
	var count = 0
	
	# 3. Loop through every event in the JSON and generate a .tres file
	for event_dict in json:
		var event = NarrativeEvent.new()
		
		# Grab the filename from the JSON, or assign a random one as a fallback
		var filename = event_dict.get("filename", "unnamed_event_" + str(randi() % 1000))
		
		# Dynamically map all properties from the JSON to the NarrativeEvent resource
		for key in event_dict.keys():
			if key == "filename":
				continue
				
			# Godot requires strictly typed arrays for exported custom resources
			if key == "required_keywords" or key == "forbidden_keywords":
				var arr: Array[String] = []
				for item in event_dict[key]:
					arr.append(str(item))
				event.set(key, arr)
			else:
				# Map strings, ints, and bools directly
				event.set(key, event_dict[key])
				
		# 4. Save the generated resource directly into your Event folder
		var save_path = "res://Resource/Event/" + filename + ".tres"
		ResourceSaver.save(event, save_path)
		count += 1
		
	print("SUCCESS! Generated " + str(count) + " events in res://Resource/Event/")
