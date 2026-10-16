extends Container

const Preferred := preload("preferred.gd")

## One piece while its least fits the room this is given, else another in
## its place: a list that scrolls itself while the room shows the rows it
## must, and the same list drawn whole on a page that scrolls where it
## cannot (page.gd).
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## IT CHOOSES BY ITS OWN SIZE, each way, and by nothing else: the first
## piece while its least size fits inside it, the second where it does not.
## Both are built once, as it is built, and the one not standing is hidden,
## so choosing again builds nothing.
##
## ITS LEAST IS THE SECOND PIECE'S: the second is the one that stands where
## the room is short, so it must be the one that asks for less. What this
## asks never depends on which stands, so the choice cannot move the room
## it was made from. What it would take given all the room it wants is the
## first piece's (preferred.gd).
##
## It takes no press and draws nothing; what it holds does both.


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## A piece put in: the first, then the second.
func place(piece: Control, _facts: Dictionary) -> void:
	add_child(piece)


## Whether the first piece is the one standing at this size: its least fits, each way.
func first_fits(room: Vector2) -> bool:
	var needs: Vector2 = get_child(0).get_combined_minimum_size()
	return needs.x <= room.x + 0.01 and needs.y <= room.y + 0.01


## The second piece's least, whichever stands.
func _get_minimum_size() -> Vector2:
	return get_child(1).get_combined_minimum_size() if get_child_count() == 2 else Vector2.ZERO


## What it would take given all the room it wants: the first piece's.
func preferred_size() -> Vector2:
	return Preferred.of(get_child(0)).max(get_combined_minimum_size())


## Laid out: the piece whose turn it is shown across the whole of it, the other hidden.
func _notification(what: int) -> void:
	if what != NOTIFICATION_SORT_CHILDREN:
		return
	var first := first_fits(size)
	var standing: Control = get_child(0 if first else 1)
	var resting: Control = get_child(1 if first else 0)
	# each touched only where it changes, since a change lays this out again
	if not standing.visible:
		standing.visible = true
	if resting.visible:
		resting.visible = false
	fit_child_in_rect(standing, Rect2(Vector2.ZERO, size))


## The builder's door: the first piece and the second built into it, in turn.
static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"while_fits").new()
	ui.attach(made, parent, desc.facts)
	return made
