tool

extends Popup

##TODO desactivar todo (menos el boton de eliminar) cuando el archivo no exista

var _room_panel_to_edit : Object

func show_form() -> void:
	popup_centered()

func hide_form() -> void:
	_room_panel_to_edit = null
	visible = false
	

func set_data(room_panel:Object) -> void:
	_room_panel_to_edit = room_panel
	$Panel/Margin/VBx/HBxFilePath/HBx/TxtFilePath.text = room_panel.file_path
	$Panel/Margin/VBx/HBxDescription/TextEdit.text = room_panel.description
	## seleccionar el color establecido
	_get_color_checkbox(room_panel.color_panel).pressed = true

## obtener el check que coincida con el color
func _get_color_checkbox(clr:Color) -> Object:
	for c in $Panel/Margin/VBx/HBxColors/Colors.get_children():
		if c.color == clr:
			return c
	return null

## obtener el checkbox presionado
func _get_pressed_color_checkbox() -> Object:
	for c in $Panel/Margin/VBx/HBxColors/Colors.get_children():
		if c.pressed == true:
			return c
	return null

func _on_FormSceneData_pressed() -> void:
	
	if $FileDialog.visible == true:
		return
	
	hide_form()


func _on_BtnExplore_pressed() -> void:
	if _room_panel_to_edit != null:
		$FileDialog.set_current_path(_room_panel_to_edit.file_path)
	$FileDialog.popup()


func _on_FileDialog_file_selected(path: String) -> void:
	$Panel/Margin/VBx/HBxFilePath/HBx/TxtFilePath.text = path


func _on_BtnClose_pressed() -> void:
	hide_form()


func _on_BtnDelete_pressed() -> void:
	if _room_panel_to_edit != null:
		_room_panel_to_edit.queue_free()
	hide_form()


func _on_BtnSave_pressed() -> void:
	if _room_panel_to_edit != null:
		
		_room_panel_to_edit.file_path = $Panel/Margin/VBx/HBxFilePath/HBx/TxtFilePath.text
		_room_panel_to_edit.color_panel = _get_pressed_color_checkbox().color
		_room_panel_to_edit.description = $Panel/Margin/VBx/HBxDescription/TextEdit.text
		_room_panel_to_edit.update_data()
	
	hide_form()
