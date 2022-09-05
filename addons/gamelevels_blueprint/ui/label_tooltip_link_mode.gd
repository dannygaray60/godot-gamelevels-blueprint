tool

extends Label

## modo
## 0:inactivo
## 1:seleccionar primer panel
## 2:selec segundo panel
var mode : int = 0

var nodename : String

func _ready() -> void:
	set_mode(0)

func _process(_delta: float) -> void:
	if mode > 0:
		rect_global_position = get_global_mouse_position() + Vector2(-20,-70)

func set_mode(mod:int) -> void:
	mode = mod
	
	if mode == 0:
		visible = false
		return
	
	visible = true
	
	match mode:
		1:
			text = "Select the first Room to connect"
		2:
			text = "-> %s <- Connected with..." % [nodename]
