extends SubViewportContainer

## A sub-viewport: a world of its own drawn inside the interface, holding
## whatever it was described with.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## What it holds is a scene rendered apart - a live 3D window, say - not a
## control in the tree above; the engine draws the viewport's texture here,
## sized to this. The content goes inside the viewport.

var viewport := SubViewport.new()


func _init() -> void:
	stretch = true
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(viewport)


static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"view").new()
	ui.attach(made, parent, desc.facts)
	return made