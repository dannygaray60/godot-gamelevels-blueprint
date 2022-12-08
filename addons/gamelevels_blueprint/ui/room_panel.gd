tool

extends GraphNode

signal edit_request(room_panel_node)

## 2D : 0, 3D : 1
var scene_type : int = 0
var file_path : String
var description : String
var color_panel : Color

var icons : Dictionary

func _enter_tree() -> void:
	## conectar señales manualmente y evitar el error de is signal already connected
	if is_connected("raise_request", get_dock(), "_on_RoomPanel_raise_request") == false:
		connect("raise_request", get_dock(), "_on_RoomPanel_raise_request", [name])
	if is_connected("focus_entered", self, "_on_RoomPanel_focus_entered") == false:
		connect("focus_entered", self, "_on_RoomPanel_focus_entered")
	if is_connected("focus_exited", self, "_on_RoomPanel_focus_exited") == false:
		connect("focus_exited", self, "_on_RoomPanel_focus_exited")

	update_data()

## obtener el objeto Dock
func get_dock() -> Object:
	return get_parent().get_parent()

## obtener nombre del archivo y sin la extensión a partir del file_path asignado
func get_name() -> String:
	return file_path.get_file().replace(".tscn", "")

func get_center_offset() -> Vector2:
	return offset + (rect_size / 2)

func set_visible_action_buttons(val:bool) -> void:
	$VBoxContainer/HBoxContainer.visible = val

## establecer los valores de este panel
func update_data() -> void:
	
	var file := File.new()
	
	if file_path.empty():
		return
	
	## poner un tooltip al boton goto
	$VBoxContainer/HBoxContainer/BtnGoTo.hint_tooltip = "Go to: " + file_path
	
	## establecer el nombre que aparecerá en el panel
	$VBoxContainer/Label.text = get_name()
	
	## mostrar un aviso si el archivo no existe despues del nombre, tipo file name [not found]
	## anteponer un (!) y desactivar algunos botones
	if file.file_exists(file_path) == false:
		$VBoxContainer/Label.text = "(!) "+ $VBoxContainer/Label.text
		$VBoxContainer/HBoxContainer/BtnGoTo.disabled = true
		$VBoxContainer/HBoxContainer/BtnPlay.disabled = true
		$VBoxContainer/HBoxContainer/BtnCopyPath.disabled = true
	
	## el archivo existe
	else:
		$VBoxContainer/HBoxContainer/BtnGoTo.disabled = false
		$VBoxContainer/HBoxContainer/BtnPlay.disabled = false
		$VBoxContainer/HBoxContainer/BtnCopyPath.disabled = false
	
		## establecer el tipo de escenario, si es 2D o 3D
		var resource = ResourceLoader.load(file_path)
		if resource is PackedScene:
			var instance = resource.instance()
			if instance is Spatial:
					scene_type = 1

	_set_panel_color(color_panel)
	
	## actualizar hint con la descripcion
	hint_tooltip = description
	
	## ocultar iconos o mostrarlos segun configuracion
	var icons_keys : Array = icons.keys()
	var icons_visible_count : int = 0
	for icn_check in get_node("%HBxTopIcons").get_children():
		if icons_keys.has(icn_check.name):
			icn_check.visible = icons[icn_check.name]
			if icn_check.visible == true:
				icons_visible_count += 1
		else:
			icn_check.visible = false

	if icons_visible_count > 0 :
		get_node("%TopPanelIcons").visible = true
	else:
		get_node("%TopPanelIcons").visible = false

func _set_panel_color(clr:Color) -> void:
	var duplicate_style = get_stylebox("frame").duplicate()
	duplicate_style.bg_color = clr
	add_stylebox_override("frame", duplicate_style)
	## poner color tambien al frame selected
	duplicate_style = get_stylebox("selectedframe").duplicate()
	duplicate_style.bg_color = clr
	add_stylebox_override("selectedframe", duplicate_style)
	
	## Colocar color tambien al panel superior de iconos
	duplicate_style = get_node("%TopPanelIcons").get_stylebox("panel").duplicate()
	duplicate_style.bg_color = clr
	get_node("%TopPanelIcons").add_stylebox_override("panel", duplicate_style)

## abrir archivo de escenario en el editor a partir del filepath
## usar la funcion open_scene del dock (accediendo gracias a get_parent)
func _on_BtnGoTo_pressed() -> void:
	get_dock().open_scene(file_path, scene_type)

## reproducir escena sin necesidad de abrir archivo
func _on_BtnPlay_pressed() -> void:
	get_dock().play_scene(file_path)

## al entrar en focus, mandar al dock una notificacion mostrando la descripcion
func _on_RoomPanel_focus_entered() -> void:
	if description.empty() == false:
		get_dock().show_notif(description)

## ocultar la notificacion
func _on_RoomPanel_focus_exited() -> void:
	get_dock().hide_notif()
	

func _on_BtnCopyPath_pressed() -> void:
	OS.set_clipboard(file_path)
	#OS.alert("The path: %s was copied to clipboard!"%[file_path], "File path copied!")

func _on_BtnEdit_pressed() -> void:
	emit_signal("edit_request", self)
