extends Node

var loaded_data = false
#Path to save the save file at.
var SavePath = "user://Saves/Save1.json"
#Variable to contain save file while opening
var SaveFile
#Variable containing the save Data
var Save = {
		"0": {
			"PlayerName": "Player",
			"Players": {},
			"Points": {},
			"lydia_lion": {},
			"alloys": {},
			"footprint_tiles": {},
			"wellness_beads": {},
			"elcitraps": {},
			"hair": {},
			"body": {},
			"clothes": {},
			"player_icon": {},
			"Current_Level": -1,
			"Current_Round": -1
		}
	}

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
#Signal that sends what the level in the loaded data is.
signal load_save_scene(level)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

# Function to run after the Save Button is pressed to manage the Data
func save_game():
	print("Saving Game locally...")
	
	# Make sure directory exists
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("Saves"):
		dir.make_dir("Saves")
	
	Save["0"] = {
			"PlayerName": gamestate.player_name,
			"Players": gamestate.players,
			"Points": gamestate.total_points,
			"lydia_lion": gamestate.lydia_lion,
			"alloys": gamestate.alloys,
			"footprint_tiles": gamestate.footprint_tiles,
			"wellness_beads": gamestate.wellness_beads,
			"elcitraps": gamestate.elcitraps,
			"hair": gamestate.hair,
			"body": gamestate.body,
			"clothes": gamestate.clothes,
			"player_icon": gamestate.player_icon,
			"Current_Level": Save["0"].Current_Level,
			"Current_Round": Save["0"].Current_Round
		}
	
	SaveFile = FileAccess.open(SavePath, FileAccess.WRITE)
	if SaveFile == null:
		print("Failed to open save file: ", FileAccess.get_open_error())
		return
	
	SaveFile.store_string(JSON.stringify(Save, "\t"))
	SaveFile.close()

func load_game() -> bool:
	if not FileAccess.file_exists(SavePath):
		return false
		
	SaveFile = FileAccess.open(SavePath, FileAccess.READ)
	if SaveFile == null:
		return false
		
	loaded_data = true
	var test_json_conv = JSON.new()
	var error = test_json_conv.parse(SaveFile.get_as_text())
	if error != OK:
		return false

	Save = test_json_conv.get_data()
	
	# Migrate old save structures by filling missing dictionary keys
	var template = {
		"PlayerName": "Player",
		"Players": {},
		"Points": {},
		"lydia_lion": {},
		"alloys": {},
		"footprint_tiles": {},
		"wellness_beads": {},
		"elcitraps": {},
		"hair": {},
		"body": {},
		"clothes": {},
		"player_icon": {},
		"Current_Level": -1,
		"Current_Round": -1
	}
	if Save.has("0"):
		for key in template.keys():
			if not Save["0"].has(key):
				Save["0"][key] = template[key]
	
	if(str(Save["0"].Current_Level) == "World"):
		Save["0"].Current_Level = "DominoWorld"
	emit_signal("load_save_scene", Save["0"].Current_Level)
	return true
	
