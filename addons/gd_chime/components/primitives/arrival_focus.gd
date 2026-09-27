extends "../../presentation.gd"

const Bound := preload("bound.gd")
const Going := preload("going.gd")
const Shift := preload("shift.gd")
const Driver := preload("../../driver.gd")
const Applier := preload("../../applier.gd")
const Kept := preload("../../kept.gd")
const KeptFocus := preload("../../kept_focus.gd")

## Where the focus lands as a place is arrived at: what this holds takes it,
## while a bound value holds - a question of a form entered as its key, the
## day a calendar opens on.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## AN ARRIVAL is a move that puts the reader somewhere new on the screen this
## stands on: its place was not on the screen before and is now - a pop-up
## raised - or it is and the history entry the reader is on is another - a
## screen entered afresh, or entered again as another of its kind, or Back.
## A pop-up lowered over it, or raised elsewhere, is no arrival: the reader
## is where they stood, and the focus given back to them stays.
##
## The value is read as the move lands, so what holds is where the move
## meant to go: a place's parameter - the driver's - naming this piece, or a
## model's fact. What takes the focus is the first control under this that
## is shown and can take it, the floor's one default (kept_focus.gd), and it
## takes it once the move is drawn - after the driver has given the focus
## back or to the place's default, so a move sending the reader to a piece
## wins over where the place would have put them. A scroll holding this
## follows the focus there by itself (scroll.gd).
##
## It lays what it holds across the whole of itself and needs the room that
## does; it takes no press.
##
## Deliberately absent: taking the focus on anything but an arrival - a
## piece that grabs whenever a value moves would pull the reader away from
## what they are doing.

var _holds: Bound
var _driver: Driver
var _place: Node  # the place this stands in, whose arrival counts
var _on_screen: bool = false  # whether the place was on the screen as last moved
var _entry: String = ""  # the history entry the reader was on as last moved
var _owed: bool = false  # whether the focus is owed to what this holds at the next draw


func _init(chimes: Chimes, driver: Driver, place: Node, holds: Bound, in_region: StringName) -> void:
	super(chimes, [[Chimes.GLOBAL, Driver.NAVIGATED]], in_region)
	_driver = driver
	_place = place
	_holds = holds
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# where the reader stands as this is built: built on a screen already shown is no arrival
	_on_screen = Applier.active_in(driver.get_state()).has(place.name)
	_entry = Kept.entry_of(driver.get_state())


## Whether the focus is owed here at the next draw: arrived at while the value held.
func is_owed() -> bool:
	return _owed


## Moved: an arrival while the value holds owes the focus to what this holds.
func heard(_what: StringName) -> void:
	var state := _driver.get_state()
	var on_screen := Applier.active_in(state).has(_place.name)
	var entry := Kept.entry_of(state)
	if on_screen and (not _on_screen or entry != _entry) and _holds.read() == true:
		_owed = true
		needs_refresh()
	_on_screen = on_screen
	_entry = entry


## The focus given to the first control under this that can take it, once, where it is owed.
func refresh() -> void:
	if not _owed:
		return
	_owed = false
	var to := KeptFocus.default_focus(self)
	if to != null:
		to.grab_focus()


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		# every piece fitted to the whole of this, unless it is on its way out
		for child: Node in get_children():
			if child is Control and not Going.is_going(child):
				Shift.fit(self, child, Rect2(Vector2.ZERO, size))


func _get_minimum_size() -> Vector2:
	var least := Vector2.ZERO
	# as much room as any piece needs
	for child: Node in get_children():
		if child is Control and not Going.is_going(child):
			least = least.max((child as Control).get_combined_minimum_size())
	return least


static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"arrival_focus").new(ui.chimes, ui.driver, ui.current_place(), desc.props["holds"], ui.region())
	ui.attach(made, parent, desc.facts)
	return made
