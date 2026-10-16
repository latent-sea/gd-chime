extends "scroll.gd"

const Preferred := preload("preferred.gd")

## A page that scrolls down and asks for no room across: what it holds is
## laid at its width inside its padding, or at its own least where that is
## wider - the engine lays nothing narrower than it needs - so a piece too
## wide for it is cut inside it and said out loud, never passed up to widen
## the page, the app or the window.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## EVERYTHING ELSE IS A SCROLL'S (scroll.gd): the indicator, the finger, the
## offset kept with the view, the focus shown whole, a piece revealed or
## nudged into view. A scroll running down is as wide as what it holds, which
## is right for a list standing in a page and wrong for the page itself: this
## is the one a screen stands in.
##
## ITS LEAST IS ITS OWN PADDING, either way: nothing it holds reaches it.
## What it would take given all the room it wants is what it holds would
## take across, with its padding (preferred.gd).
## Across it never moves - what it holds stands at its left edge whatever a
## wheel, a pad or the focus asks, and what reaches past its right edge is
## cut off there.
##
## THE FOCUS IS SHOWN WHOLE DOWN ONLY: the scroll's own following of it is
## held off while this is laid out, and this follows it instead, on the same
## terms - the pad or the keys used last, or an offset just put back - then
## puts across back at the start. Followed across, a piece past the right
## edge would ask for a move this undoes, and each laying out would ask
## again, without end.
##
## IT SAYS WHAT IS WRONG INSIDE IT, in a debug build, once for each piece:
## the piece too wide for it - the deepest that needs more than its width,
## so the sentence names what to fix rather than everything holding it; and
## a scroll inside it that runs down and grows to fill its line, which shows
## nothing once the page holds more than its height, since the page gives
## what it holds the height it needs and such a scroll needs none. It looks
## only when its width or what it holds needs has moved since it last looked,
## and only while it is shown and has a width: it is laid out on every frame
## it scrolls, and what is wrong inside it moves only with what it is built of.

var _said: Dictionary = {}  # instance id -> true, for each piece already said to be wrong inside it
var _followed := false  # whether the focus was being followed as this laying out began
var _looked_wide := -1.0  # its width when it last looked inside itself for what is wrong; none yet
var _looked_need := Vector2.ZERO  # and what it holds needed then
## How many times it has looked inside itself for what is wrong, so that it
## looking only when its room or what it holds has moved is something a test
## can read rather than something it argues.
var look_count: int = 0


func _init(ui: RefCounted, reveal: Variant, nudged: Variant, style: StringName) -> void:
	super(ui, reveal, DOWN, nudged, style)
	# across, the engine asks nothing of what it holds and shows no bar; it would move, so it is held at the start as it is laid
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER


func _notification(what: int) -> void:
	# laying out begins: the scroll's own following of the focus is held off for it, since it would follow across too
	if what == NOTIFICATION_PRE_SORT_CHILDREN:
		_followed = not _by_hand
		_by_hand = true
	if what != NOTIFICATION_SORT_CHILDREN:
		return
	var held: Control = get_child(0)
	# the scroll's laying out has run, and an offset it put back there follows the focus as the pad does (scroll.gd)
	_by_hand = _by_hand and not _followed
	var down := _kept.get_offset().y
	var focus := get_viewport().gui_get_focus_owner()
	# the focus on something it holds, followed: shown whole, of which only the move down stands
	if not _by_hand and focus != null and is_ancestor_of(focus) and focus.has_focus(true):
		ShownWhole.show(self, _kept.get_offset(), focus)
	# moved across by a wheel, a pad or the focus: put back at the start here, since a sort asked for while sorting is dropped
	if scroll_horizontal != 0:
		scroll_horizontal = 0
		held.position.x = get_theme_stylebox(&"panel").get_offset().x
	# moved down while being laid out, which the engine does not lay out again of itself
	if _kept.get_offset().y != down:
		queue_sort.call_deferred()
	var need := held.get_combined_minimum_size()
	# looked inside already at this width and need, or hidden, or not yet given a width: nothing new inside it to say
	if not OS.is_debug_build() or (size.x == _looked_wide and need == _looked_need) or not is_visible_in_tree() or size.x == 0.0:
		return
	_looked_wide = size.x
	_looked_need = need
	look_count += 1
	var room: float = size.x - get_theme_stylebox(&"panel").get_minimum_size().x
	var piece := held
	# down from what it holds, through a part that needs more than the room, to one none of whose parts does
	while piece.get_combined_minimum_size().x > room:
		var wider: Array = piece.get_children().filter(func(part: Node) -> bool: return part is Control and (part as Control).get_combined_minimum_size().x > room)
		if wider.is_empty():
			_say(piece, "%s needs %.0f across and the page it stands in has %.0f, so it is cut at the page's edge: it is the piece that asks for more room than the page gives" % [piece.get_path(), piece.get_combined_minimum_size().x, room])
			break
		piece = wider[0]
	# every scroll inside, wherever it was built in the page since it was last laid out
	for inside: Node in find_children("*", "ScrollContainer", true, false):
		var holder := inside.get_parent()
		# it scrolls down, and the line holding it gives it a share of what is left
		if (inside as ScrollContainer).vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED and holder.has_method(&"get_facts") and holder.get_facts(inside).get("grow", 0.0) > 0.0:
			_say(inside, "%s scrolls down and grows to fill its line inside the page %s, so it shows nothing once the page holds more than its height: inside a page, a list is drawn whole" % [inside.get_path(), get_path()])


## What it would take given all the room it wants (preferred.gd): across,
## what it holds would take, with its padding; down, its least.
func preferred_size() -> Vector2:
	return Vector2(Preferred.of(get_child(0)).x + get_theme_stylebox(&"panel").get_minimum_size().x, get_combined_minimum_size().y)


## A sentence about a piece, said out loud the first time and never again.
func _say(piece: Node, sentence: String) -> void:
	if _said.has(piece.get_instance_id()):
		return
	_said[piece.get_instance_id()] = true
	push_error(sentence)


static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"page_scroll").new(ui, desc.props["reveal"], desc.props["nudged"], desc.props["style"])
	ui.attach(made, parent, desc.facts)
	return made
