tool

extends HBoxContainer

signal open_item(file_path)
signal delete_item(file_path)

var f_path : String

func _ready() -> void:
	$LinkButton.text = f_path.get_file()
	$LinkButton.hint_tooltip = f_path

func _on_Button_pressed() -> void:
	emit_signal("delete_item", f_path)


func _on_LinkButton_pressed() -> void:
	emit_signal("open_item", f_path)
