tool

extends CheckBox

export var color : Color setget set_color

func get_color_rect() -> Color:
	return color

func set_color(clr:Color) -> void:
	color = clr
	$CurrentColor.color = color
