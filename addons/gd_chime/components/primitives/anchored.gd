extends Container

## A piece attached to another control: drawn just above that control's
## rect, as wide as it, wherever it ends up, following it every frame.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A bubble beside a button, a glow around a card: the target is named in
## its description and found by the builder; this sits above everything in
## its layer and takes no press. It needs no room of its own.

var _target: Control


func _init(target: Control) -> void:
	_target = target
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 1
	set_process(true)


func _process(_delta: float) -> void:
	if not is_instance_valid(_target):
		return
	var rect := _target.get_global_rect()
	var tall := get_combined_minimum_size().y
	global_position = rect.position - Vector2(0.0, tall)
	size = Vector2(rect.size.x, tall)
	visible = _target.is_visible_in_tree()


func _get_minimum_size() -> Vector2:
	var least := Vector2.ZERO
	# as much room as any part of its content needs
	for child: Node in get_children():
		if child is Control:
			least = least.max((child as Control).get_combined_minimum_size())
	return least


static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"anchored").new(ui.node_named(desc.props["target"]))
	ui.attach(made, parent, desc.facts)
	return made