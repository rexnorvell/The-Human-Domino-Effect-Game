extends Node

var loaded_data = false
#Path to save the save file at.
var SavePath = "res://Saves/Save1.json"
#Variable to contain save file while opening
var SaveFile
#Variable containing the save Data
var Save = {
		"0": {
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
func save_button_pressed():
	print("Save Button Pressed!")
	SFXController.playSFX(ReferenceManager.get_reference("next.wav"))
	Save["0"] = {
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
			"Current_Level": Save["0"].Current_Level,
			"Current_Round": Save["0"].Current_Round
		}
	SaveFile = File.new()
	SaveFile.open(SavePath, File.WRITE)
	SaveFile.store_string(JSON.stringify(Save, "\t"))
	SaveFile.close()

func load_button_pressed():
	print("Load Button Pressed")
	loaded_data = true
	SaveFile = File.new()
	SaveFile.open(SavePath, File.READ)
	var test_json_conv = JSON.new()
	test_json_conv.parse(SaveFile.get_as_text())
	Save = test_json_conv.get_data()
	if(Save["0"].Current_Level == "World"):
		Save["0"].Current_Level = "DominoWorld"
	emit_signal("load_save_scene", Save["0"].Current_Level)
