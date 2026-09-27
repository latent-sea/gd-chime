extends "stack.gd"

## A subtree wearing a look of its own: the Theme it is given is set on
## this, and the engine carries it down to everything built inside, so one
## part of a screen is drawn in another design language while the rest keeps
## the root's.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## IT IS A STACK WITH A THEME AND NOTHING ELSE: what it holds is placed
## across the whole of it and it needs as much room as the largest piece,
## which is what a piece standing in for its parent must do. A look put on
## the root while this shows re-dresses everything OUTSIDE it and nothing
## in: the engine stops at the first node holding a theme of its own, which
## is the point of it.
##
## It must never merge the root's look into what it is given: a look that
## sets nothing is already the floor's (theme.gd), and a caller wanting the
## root's defaults under its own passes a Theme built that way. Merging here
## would make the look on the root part of what this draws, and a look
## picked afterwards would change it.


func _init(look: Theme) -> void:
	super()
	theme = look


static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"themed").new(desc.props["theme"])
	ui.attach(made, parent, desc.facts)
	return made
