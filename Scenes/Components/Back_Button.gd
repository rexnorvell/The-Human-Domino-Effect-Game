extends Control

signal pressed

func _on_Back_Button_pressed() -> void:
	pressed.emit()
