tool

extends GraphEdit

##FIX ocurre bug despues de haber seleccionado varios room panel al mismo tiempo

signal scene_dropped(filepath, node_position)

## snap vector to grid
func snap(pos:Vector2):

	if use_snap:

		pos = pos / snap_distance
		pos = pos.floor() * snap_distance
		
	return pos

## solo aceptar un archivo y que este sea un escenario (tscn)
func can_drop_data(position, data):
	
	if data["files"].size() > 1 or data["files"][0].get_extension() != "tscn":
		return false
	
	return true

## emitir señal con solo el filepath como string y la posicion del drop
func drop_data(position, data):
	var filepath = data["files"][0]
	## guardar posicion del drop y el offset del scroll del graphedit
	## dividir entre el zoom para que posicione bien sin importar lo alejado que se esté
	var offset = (scroll_offset + position) / Vector2(zoom, zoom)
	
	if use_snap == true:
		offset = snap(offset)
	
	emit_signal("scene_dropped", filepath, offset)

#func remove_node() -> void:
#	remove_from_group("graph_edit")
#	queue_free()
