extends RefCounted

## Going: the mark on a thing that is on its way out, and what it means.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A thing going is still drawn, where it stood, until its exit has run -
## and that is ALL it still is. IT NEVER LEAVES THE TREE to be kept so: a
## node taken out and put back runs every enter and exit beneath it again,
## so a place inside would be emptied and filled once more and its name
## fought over in the index. It stays where it is, marked, and everything
## that would treat it as there reads the mark: EVERY layout that arranges
## or measures its children - a line, a grid, a stack, an inset - neither
## places it nor measures it, so what is left closes up as if it had gone; it is
## moved last among its holder's children, so the places of the rest are
## theirs again and it is drawn over them; its whole subtree takes no
## press and no focus; and everything beneath it that answers going() is
## told - a place gives up its name and its stay at that moment, not when
## the node is at last freed, so whatever arrives in its stead may have them.
##
## The mark is a group, the engine's own: nothing to hold, gone with the node.

const GROUP := &"going"


static func is_going(node: Node) -> bool:
	return node.is_in_group(GROUP)


## This thing set going: marked, last among its holder's children, out of reach, and everything beneath it told.
static func mark(node: Control) -> void:
	node.add_to_group(GROUP)
	node.get_parent().move_child(node, -1)
	node.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	node.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	node.propagate_call(&"going")
