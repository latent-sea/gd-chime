extends Container

const Going := preload("going.gd")
const Shift := preload("shift.gd")

## Pieces over one another, each across the whole of this, the last on top.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## It takes no press: what it holds does. It needs as much room as the
## largest piece, shown or not, so the frame around it never jumps as its
## pieces swap - a row sharing its room by grow gives each part its least
## first, and a stack of screens asking only for the one showing would move
## the frame on every tab - and gives every piece the whole of itself as it is placed,
## as its motion has left it (shift.gd) - words that wrap need the width they
## are given - but not a piece going, which stays where it stood.


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		# every piece fitted to the whole of this, unless it is on its way out
		for child: Node in get_children():
			if child is Control and not Going.is_going(child):
				Shift.fit(self, child, Rect2(Vector2.ZERO, size))


func _get_minimum_size() -> Vector2:
	var least := Vector2.ZERO
	# as much room as any piece needs, shown or not
	for child: Node in get_children():
		if child is Control and not Going.is_going(child):
			least = least.max((child as Control).get_combined_minimum_size())
	return least


static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"stack").new()
	ui.attach(made, parent, desc.facts)
	return made