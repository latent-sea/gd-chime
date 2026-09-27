extends RefCounted

const Chimes := preload("chimes.gd")
const Commands := preload("commands.gd")
const Index := preload("index.gd")

## Closing a place: its subtree going away, and everything that belonged to
## it, and to every place inside it, let go in one call.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A place's name is its region, and the region holds its bells, the
## connections of its listeners, and the handlers of the models built with
## it - the first two in the chimes, the last in the commands. Two places,
## and nothing keeps them in step but this: close() drops the region from
## both, and does the same for every place beneath it in the tree, at any
## depth, so a tab left standing cannot refuse its bells when its screen is
## built again. Then the subtree leaves the tree - so every place in it
## takes itself out of the index at once, and a screen built again
## under the name is found afresh - and is freed at the end of the frame,
## since a node is closed from inside a command it is answering.
##
## It is a function over what it is handed and holds nothing. Where the
## reader is is not this file's: a place on the path is left before it is
## closed, by an arrival or a Back, and closing a pop-up is lowering it
## (driver.gd) and then this.
##
## Deliberately absent: building a place again, which is whoever built it.

## Drop the place's region and every region beneath it from the chimes and
## the commands, and take the subtree out of the tree, freed at frame end.
static func close(chimes: Chimes, commands: Commands, index: Index, place: Node) -> void:
	var waiting: Array[Node] = [place]
	# every node beneath the place, the place first, for the places and their regions
	while not waiting.is_empty():
		var node: Node = waiting.pop_front()
		waiting.append_array(node.get_children())
		if index.is_place(node):
			chimes.drop_region(node.name)
			commands.drop_region(node.name)
	place.get_parent().remove_child(place)
	place.queue_free()
