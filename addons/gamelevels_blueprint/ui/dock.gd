tool
extends Control

var room_panel = load("res://addons/gamelevels_blueprint/ui/room_panel.tscn")
var room_connector = load("res://addons/gamelevels_blueprint/ui/room_connector.tscn")

var button_recent_file = preload("res://addons/gamelevels_blueprint/ui/button_recent_file.tscn")

## modo de edicion
## 0:normal, 1:conectar rooms
var _edit_mode : int = 0

## ruta del archivo abierto
var _opened_map : String = ""

## lista de nodos (solo el path) para conectar entre sí
var _rooms_to_connect : Array

var f := File.new()
var Conf := ConfigFile.new()

var _configfile_path : String = "res://addons/gamelevels_blueprint/conf.ini"

func _ready() -> void:
	Conf.load(_configfile_path)
	
	$PanelFileMapNameOpened.visible = false
	$PanelToolBar/MarginContainer/HBx/HBxActions/BtnCancelLink.visible = false

	_show_recent_list()

## abrir archivo de escenario en el editor a partir del filepath
func open_scene(file_path, scene_type) -> void:
	## obtener acceso al editor interface (definido en plugin.gd)
	var interface = get_tree().get_meta("editor_interface")
	## cambiar el modo de visualizacion en el editor
	if scene_type == 0:
		interface.set_main_screen_editor("2D")
	else:
		interface.set_main_screen_editor("3D")
	## abrir escenario
	interface.open_scene_from_path(file_path)

## ejecutar archivo de escenario
func play_scene(file_path) -> void:
	## obtener acceso al editor interface (definido en plugin.gd)
	var interface = get_tree().get_meta("editor_interface")
	## abrir escenario
	interface.play_custom_scene(file_path)

func show_notif(txt:String="Hello, this is a Notification!", hide_time:int=0) -> void:
	
	$PanelToolBar/MarginContainer/HBx/LabelMsgs.text = txt
	
	_tween_notif(Color("00ffffff"), Color("ffffff"))
	
	if hide_time == 0:
		$TimerHideNotif.stop()
	else:
		$TimerHideNotif.start(hide_time)

func hide_notif() -> void:
	if $PanelToolBar/MarginContainer/HBx/LabelMsgs.modulate.a > 0:
		_tween_notif(Color("ffffff"), Color("00ffffff"))

## limpiar graphedit
func clean_graph_edit() -> void:

	for gnode in $GraphEdit.get_children():
		## solo borrar graphnodes
		## ya que graphedit agrega otros nodos para su funcionamiento
		## y esos no deben ser eliminados
		if gnode is GraphNode:
			gnode.queue_free()

func save_map() -> void:
	var err : int
	var file := File.new()
	var data_to_save : Dictionary
	## hijos del graphedit
	var graph_edit_children : Array = $GraphEdit.get_children()
	## lista de room panels
	var room_panels : Array
	## conectores
	var room_connectors : Array
	## dict de la configuracion del graphedit
	var graph_edit_config : Dictionary
	
	## zoom, minimapenabled etc
	graph_edit_config = {
		"scroll_offset": $GraphEdit.scroll_offset,
		"snap_distance": $GraphEdit.snap_distance,
		"use_snap": $GraphEdit.use_snap,
		"zoom": $GraphEdit.zoom,
		"minimap_enabled": $GraphEdit.minimap_enabled,
		"minimap_size": $GraphEdit.minimap_size,
	}
	
	## obtener todos los panels y guardar sus datos dentro de la lista
	for rp in graph_edit_children:
		if rp is GraphNode and rp.is_in_group("room_panel"):
			room_panels.append(
				{
					"node_name": rp.name,
					"scene_type": rp.scene_type,
					"file_path": rp.file_path,
					"description": rp.description,
					"color_panel": rp.color_panel,
					"offset": rp.offset,
					"icons": rp.icons,
				}
			)
	## guardar solo los nombres de los path a que apuntan
	for rc in graph_edit_children:
		if (
			rc is GraphNode and rc.is_in_group("room_connector")
			and rc.node_a_path.is_empty() == false
			and rc.node_b_path.is_empty() == false
		):
			room_connectors.append(
				[
					rc.node_a.name,
					rc.node_b.name,
				]
			)
	
	## guardar las listas a al archivo de texto (_opened_map)
	
	data_to_save = {
		"graph_edit_config": graph_edit_config,
		"rooms": room_panels,
		"connectors": room_connectors
	}
	
	err = file.open(_opened_map, File.WRITE)
	
	if err != OK:
		print("Error Saving Map err #%d"%[err])
		return
	
	file.store_var(data_to_save)
	
	file.close()
	
	show_notif("Map Saved!", 2)

func open_map() -> void:
	
	clean_graph_edit()
	get_node("%RecenListControl").visible = false
	get_node("%BtnOpenRecentFiles").visible = false
	
	var file := File.new()
	var data_to_load : Dictionary
	
	file.open(_opened_map, File.READ)
	data_to_load = file.get_var()
	file.close()
	
	## cargar configuracion
	$GraphEdit.scroll_offset = data_to_load["graph_edit_config"]["scroll_offset"]
	$GraphEdit.snap_distance = data_to_load["graph_edit_config"]["snap_distance"]
	$GraphEdit.use_snap = data_to_load["graph_edit_config"]["use_snap"]
	$GraphEdit.zoom = data_to_load["graph_edit_config"]["zoom"]
	## minimap_enabled al cargarse siendo true, el mapa no se muestra (godot bug?)
	## no usarlo por el momento
	#$GraphEdit.minimap_enabled = data_to_load["graph_edit_config"]["minimap_enabled"]
	$GraphEdit.minimap_size = data_to_load["graph_edit_config"]["minimap_size"]

	## añadir toda la data al tree
	
	for roompanel in data_to_load["rooms"]:
		_add_room_panel(roompanel)
	
	for roomconnector in data_to_load["connectors"]:
		_add_room_connector(roomconnector)
	
	$PanelFileMapNameOpened/HBx/Lbl.text = _opened_map.get_file().replace(".lvlmap", "")
	$PanelFileMapNameOpened.visible = true
	
	## añadir a lista de archivos recientes
	var recent_list : Array = Conf.get_value("main", "recent_list", [])
	if recent_list.has(_opened_map):
		recent_list.erase(_opened_map)
	recent_list.push_front(_opened_map)
	## guardar
	Conf.set_value("main", "recent_list", recent_list)
	Conf.save(_configfile_path)


func _show_recent_list() -> void:
	
	## limpieza
	for n in get_node("%VBxRecentFiles").get_children():
		n.queue_free()
	
	var recent_file_count : int = 0
	## mostrar lista de recientes
	var recent_list : Array = Conf.get_value("main", "recent_list", [])
	if recent_list.empty() == false:
		for file in recent_list:
			if f.file_exists(file):
				var Btn = button_recent_file.instance()
				Btn.f_path = file
				get_node("%VBxRecentFiles").add_child(Btn)
				Btn.connect("open_item", self, "_on_RecentFile_opened")
				Btn.connect("delete_item", self, "_on_RecentFile_deleted", [Btn.get_path()])
				recent_file_count += 1
	
	if recent_file_count > 0:
		get_node("%RecenListControl").visible = true
	else:
		get_node("%RecenListControl").visible = false

## cargar un nuevo room panel al tree
func _add_room_panel(room_data:Dictionary) -> void:
	
	var room_data_keys = room_data.keys()
	
	var room_panel_instance = room_panel.instance()
	
	if room_data_keys.has("node_name"):
		room_panel_instance.name = room_data["node_name"]
	if room_data_keys.has("scene_type"):
		room_panel_instance.scene_type = room_data["scene_type"]
	if room_data_keys.has("file_path"):
		room_panel_instance.file_path = room_data["file_path"]
	if room_data_keys.has("description"):
		room_panel_instance.description = room_data["description"]
	if room_data_keys.has("color_panel"):
		room_panel_instance.color_panel = room_data["color_panel"]
	if room_data_keys.has("offset"):
		room_panel_instance.offset = room_data["offset"]
	if room_data_keys.has("icons"):
		room_panel_instance.icons = room_data["icons"]
	
	
	## conectar señales del panel
	room_panel_instance.connect("edit_request", self, "_on_RoomPanel_edit_request")
	
	$GraphEdit.add_child(room_panel_instance)

## añadir conector, se usan los nombres de nodos para identificarlos
func _add_room_connector(rooms_nodename:Array, focusline:bool = false) -> void:
	var connector_instance = room_connector.instance()
	connector_instance.node_a_path = NodePath(str(get_path())+"/GraphEdit/"+rooms_nodename[0])
	connector_instance.node_b_path = NodePath(str(get_path())+"/GraphEdit/"+rooms_nodename[1])
	$GraphEdit.add_child(connector_instance)
	if focusline == true:
		connector_instance.focus_line()
	else:
		connector_instance.unfocus_line()
	## terminar el modo de linkear
	_on_BtnCancelLink_pressed()

## si ya existe una coneccion entre dos puntos
func _is_already_connected(nodepath_a:NodePath, nodepath_b:NodePath) -> bool:
	for n in get_tree().get_nodes_in_group("room_connector"):
		## si concuerdan los nodepaths (en cualquier orden)
		if (
			(n.node_a_path == nodepath_a and n.node_b_path == nodepath_b)
			or
			(n.node_b_path == nodepath_a and n.node_a_path == nodepath_b)
		):
			return true
	return false

func _tween_notif(from:Color, to:Color) -> void:
	$Tween.interpolate_property(
		$PanelToolBar/MarginContainer/HBx/LabelMsgs, "modulate",
		from, to, 0.5
	)
	$Tween.start()

## el graphedit ha recibido un archivo de escenario
func _on_GraphEdit_scene_dropped(filepath, node_position) -> void:
	
	get_node("%BtnOpenRecentFiles").visible = false
	
	var room_panel_instance = room_panel.instance()
	
	var room_panel_data : Dictionary = {
		"file_path": filepath,
		"offset": node_position
	}
	
	_add_room_panel(room_panel_data)

## se clickeo un boton de la lista de archivos recientes
func _on_RecentFile_opened(f_path:String) -> void:
	_opened_map = f_path
	open_map()

func _on_RecentFile_deleted(f_path:String, node_path:NodePath) -> void:
	## remover de lista de archivos recientes
	var recent_list : Array = Conf.get_value("main", "recent_list", [])
	if recent_list.has(f_path):
		recent_list.erase(f_path)
	## guardar
	Conf.set_value("main", "recent_list", recent_list)
	Conf.save(_configfile_path)
	## liberar nodo
	get_node(node_path).queue_free()

func _on_RoomPanel_edit_request(room: Object) -> void:
	$FormSceneData.set_data(room)
	$FormSceneData.show_form()

func _on_TimerHideNotif_timeout() -> void:
	hide_notif()


func _on_BtnSave_pressed() -> void:
	if _opened_map == "":
		## abrir dialogo para guardar la ruta
		$FileDialogSaveMap.current_file = "my_new_map.lvlmap"
		$FileDialogSaveMap.popup_centered()
	else:
		## llamar al savemap directamente
		save_map()

## se seleccionó un archivo para abrirlo
func _on_FileDialogOpenMap_file_selected(path: String) -> void:
	
	## evitar abrir el mismo mapa
	if _opened_map == path:
		print("GameLevels Blueprint: You can't open the same opened map")
		return
	
	_opened_map = path
	open_map()

## se seleccionó un archivo a guardar
func _on_FileDialogSaveMap_file_selected(path: String) -> void:
	if _opened_map.empty() == true:
		_opened_map = path
	save_map()
	$PanelFileMapNameOpened/HBx/Lbl.text = _opened_map.get_file().replace(".lvlmap", "")
	$PanelFileMapNameOpened.visible = true

## uno de los room panel se ha seleccionado
func _on_RoomPanel_raise_request(room_panel_name: String) -> void:
	
	## solo disponible en el modo de conectar rooms (1)
	if _edit_mode != 1:
		return
	
	## evitar agregar a lista un nodopath ya agregado
	## maximo de dos nodos para la lista
	if (
		_rooms_to_connect.has(room_panel_name) == false
		and _rooms_to_connect.size() < 2
	):
		## agregar a lista
		_rooms_to_connect.append(room_panel_name)
		
		var size_rooms_list : int = _rooms_to_connect.size()
	
		match size_rooms_list:
			
			## primer nodo agregado
			1:
				$LabelTooltipLinkMode.nodename = get_node(str(get_path())+"/GraphEdit/"+room_panel_name).get_name()
				$LabelTooltipLinkMode.set_mode(2)
			
			## si hay dos rooms seleccionadas
			2:
				var nodepath_a := NodePath(str(get_path())+"/GraphEdit/"+_rooms_to_connect[0])
				var nodepath_b := NodePath(str(get_path())+"/GraphEdit/"+_rooms_to_connect[1])
				if (
					_is_already_connected(nodepath_a, nodepath_b) == false
				):
					_add_room_connector(_rooms_to_connect, true)
				else:
					_on_BtnCancelLink_pressed()
				
				$LabelTooltipLinkMode.set_mode(0)

## cerrar el mapa abierto
func _on_BtnClose_pressed() -> void:
	$PanelFileMapNameOpened.visible = false
	_opened_map = ""
	clean_graph_edit()
	get_node("%BtnOpenRecentFiles").visible = true

func _on_BtnOpen_pressed() -> void:
	$FileDialogOpenMap.popup_centered()


func _on_BtnLink_pressed() -> void:
	_edit_mode = 1
	_rooms_to_connect = []
	$PanelToolBar/MarginContainer/HBx/HBxMapFile.visible = false
	$PanelToolBar/MarginContainer/HBx/HBxActions/BtnLink.visible = false
	$PanelToolBar/MarginContainer/HBx/HBxActions/BtnCancelLink.visible = true
	get_tree().call_group("room_panel", "set_visible_action_buttons", false)
	get_tree().call_group("room_connector", "set_visible", false)
	$LabelTooltipLinkMode.set_mode(1)

func _on_BtnCancelLink_pressed() -> void:
	_edit_mode = 0
	_rooms_to_connect = []
	$PanelToolBar/MarginContainer/HBx/HBxMapFile.visible = true
	$PanelToolBar/MarginContainer/HBx/HBxActions/BtnLink.visible = true
	$PanelToolBar/MarginContainer/HBx/HBxActions/BtnCancelLink.visible = false
	get_tree().call_group("room_panel", "set_visible_action_buttons", true)
	get_tree().call_group("room_connector", "set_visible", true)
	$LabelTooltipLinkMode.set_mode(0)


func _on_BtnAbout_pressed() -> void:
	$PopupAbout.popup()

## al terminar tween de ocultar notif, resetear texto
func _on_Tween_tween_completed(_object: Object, key: NodePath) -> void:
	if (
		key == ":modulate" 
		and 
		$PanelToolBar/MarginContainer/HBx/LabelMsgs.modulate.a == 0
		and $Tween.is_active() == false
	):
		$PanelToolBar/MarginContainer/HBx/LabelMsgs.text = ""


func _on_BtnCloseAbout_pressed() -> void:
	$PopupAbout.hide()


func _on_BtnWebsite_pressed() -> void:
	OS.shell_open("https://dannygaray60.github.io/")


func _on_BtnDonation_pressed() -> void:
	OS.shell_open("https://ko-fi.com/dannygaray60")


func _on_BtnHowToUse_pressed() -> void:
	OS.shell_open("https://github.com/dannygaray60/godot-gamelevels-blueprint#how-to-use")


func _on_BtnGithubRepo_pressed() -> void:
	OS.shell_open("https://github.com/dannygaray60/godot-gamelevels-blueprint")


func _on_BtnCloseRecenList_pressed() -> void:
	get_node("%RecenListControl").visible = false


func _on_BtnOpenRecentFiles_pressed() -> void:
	_show_recent_list()
