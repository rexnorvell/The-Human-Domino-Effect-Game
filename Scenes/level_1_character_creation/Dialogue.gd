extends MarginContainer

signal animation_done()

@export var dialogue_text: String

@onready var dialogue_label: RichTextLabel = $Panel/MarginContainer/RichTextLabel
@onready var timer: Timer = $Timer
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func set_dialogue_text(text: String) -> void:
	dialogue_label.set_visible_characters(0)
	dialogue_label.text = text
	timer.start()


func reveal_text() -> void:
	dialogue_label.set_visible_characters(dialogue_label.get_total_character_count())


func is_text_fully_visible() -> bool:
	return dialogue_label.get_visible_characters() >= dialogue_label.get_total_character_count()


func play_animation(anim_name: String, signal_when_done: bool) -> void:
	if !visible:
		show()
	animation_player.play(anim_name)
	if signal_when_done:
		await animation_player.animation_finished
		animation_done.emit()


func _on_timer_timeout() -> void:
	dialogue_label.set_visible_characters(dialogue_label.get_visible_characters() + 1)
	if dialogue_label.get_visible_characters() >= dialogue_label.get_total_character_count():
		timer.stop()


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Out":
		hide()
