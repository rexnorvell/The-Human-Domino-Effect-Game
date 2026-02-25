extends Control


var CMAX=10 # max checklist size
var CMIN=0  # min checklist size
var checklist = [] #array that stores checklist
var isRemoving = false #bool value for checking if item needs to be removed
var isNamed = false
var itemName = "New Checklist Item"
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	#
	$CanvasLayer/Polygon2D/add_item/Window.hide()
	if not $CanvasLayer/Polygon2D/add_item.is_connected("pressed", Callable(self, "_on_add_item_pressed")):
		$CanvasLayer/Polygon2D/add_item.connect("pressed", Callable(self, "_on_add_item_pressed"))
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
	

func _on_add_item_pressed():
	#create new check box
	$CanvasLayer/Polygon2D/add_item/Window.show()
	#sets item name to new text
	var t = Timer.new()
	t.set_wait_time(1)
	t.set_one_shot(true)
	self.add_child(t)
	while isNamed==false:
		t.start()
		await t.timeout
	t.queue_free()
	isNamed=false
	var new_item = create_checklist_item(itemName)
	# add checkbox to container
	var vbox=$CanvasLayer/Polygon2D/VBoxContainer
	if vbox && checklist.size()<CMAX:
		vbox.add_child(new_item)
		checklist.append(new_item)
func create_checklist_item(text):
	var item = CheckBox.new()
	item.text = text
	#item.connect("toggled", self, "_on_item_toggled", [item])
	item.connect("pressed", Callable(self, "_on_item_pressed").bind(item))
	return item

func _on_item_pressed(item):
	if  isRemoving && checklist.size()>CMIN:
		remove_item(item)
		
		
	#check button
func remove_item(item):
	if item in checklist:
		checklist.erase(item)
		var vbox = $CanvasLayer/Polygon2D/VBoxContainer
		if vbox:
			vbox.remove_child(item)
			item.queue_free()

func _on_remove_item_pressed():
	isRemoving = not isRemoving




func _on_Confirm_pressed():
	isNamed = true
	$CanvasLayer/Polygon2D/add_item/Window.hide()
	


func _on_LineEdit_text_changed(new_text):
	itemName = new_text
