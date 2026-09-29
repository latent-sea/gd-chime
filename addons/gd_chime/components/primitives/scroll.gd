extends ScrollContainer

const Bound := preload("bound.gd")
const Chimes := preload("../../chimes.gd")
const Driver := preload("../../driver.gd")
const ScrollKept := preload("scroll_kept.gd")
const Strip := preload("strip.gd")
const ScrollFinger := preload("scroll_finger.gd")
const ScrollEdge := preload("scroll_edge.gd")
const Touch := preload("../../touch.gd")
const Nearness := preload("nearness.gd")
const ScrollIndicator := preload("scroll_indicator.gd")
const ShownWhole := preload("shown_whole.gd")

## A window onto one piece taller or wider than the room: the engine's own
## scrolling, by wheel and drag; and, given a bound value naming a
## piece, scrolled to bring that piece into view whenever the name moves -
## the reader's own row on a board.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## For a list longer than a screen, a virtual list is the thing: this
## scrolls what is built, and builds nothing. Its one piece is given the
## whole window across and along, so tiles wrap at the window's width and
## rows run its width; only what is taller than the window scrolls.
##
## A CARRY NEAR AN EDGE DRAGS IT that way (scroll_edge.gd): while a drag is
## on, and only then, it looks at where the pointer is each frame.
##
## WHERE IT STANDS IS KEPT WITH THE VIEW, put back on coming back (scroll_kept.gd).
##
## THE CONTROL WITH THE FOCUS IS SHOWN WHOLE, as was ruled (2026-09-19): the
## pad or the keys moving it onto a row part out of sight bring that row
## wholly in - the least move that does, to the fraction (shown_whole.gd),
## so the pad moves a whole row at a time - and so does arriving back on a
## view: put back where the reader stood, then moved as far as makes the
## focused row whole, the kept offset giving way where the two differ. The
## reader scrolling by hand is left where they scroll, the focus or no,
## until the pad or the keys are used again. A strip keeps its own rule
## (strip.gd).
##
## WHAT LOADS AS THE READER NEARS IT is told each time this places what it
## holds - as it scrolls - and works out whether it is near (nearness.gd).
##
## ACROSS ALONE IT IS A STRIP (strip.gd): it rests on whole things only, a
## whole thing at a time, and covers an end with more beyond it.
##
## A FINGER PANS IT (scroll_finger.gd): a gesture along the way it runs
## that it can move for is its own (touch.gd), followed to the pixel and let
## go into a glide; that is scrolling by hand, as the wheel is.
##
## WHERE THE READER IS SHOWS OVER IT, down (scroll_indicator.gd), in the right
## of the padding its look's panel keeps inside it; the engine's bar never shows.

## Which ways it scrolls: either way, across alone - a strip wider than
## its room, as tall as what it holds, its bar kept out of the way - or
## down alone, as wide as what it holds, so a narrow room never cuts it,
## and no bar ever takes room from it: a list narrowed until it fits, and
## widened again, keeps the width its pieces were laid out at.
const EITHER_WAY := &"either_way"
const ACROSS := &"across"
const DOWN := &"down"

## How wide a carry's band is, and how fast it drags, until a look says otherwise (scroll_edge.gd).
const EDGE := ScrollEdge.EDGE
const BAND := ScrollEdge.BAND
const SPEED := ScrollEdge.SPEED

var _ui: RefCounted
var _reveal: Variant  # a Bound reading a name, or null
var _carrying: bool = false  # whether a drag is on anywhere in the window
var _kept: ScrollKept  # where it stands, kept with each view
var _strip: Strip = null  # across alone, how it rests on whole things
var _by_hand: bool = false  # whether the reader has scrolled by hand since the pad or the keys were last used
var _finger: ScrollFinger  # a finger panning it
var _indicator: ScrollIndicator = null  # where the reader is, down; none across alone


func _init(ui: RefCounted, reveal: Variant, along: StringName) -> void:
	_ui = ui
	_reveal = reveal
	_kept = ScrollKept.new(self, ui, ui.current_place())
	_finger = ScrollFinger.new(self, ui.motion)
	add_to_group(Touch.TAKES)
	# across alone, it is as tall as what it holds and shows no bar between that and what is below
	if along == ACROSS:
		vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		_strip = Strip.new(self)
	# down, where the reader is shows over what it holds, in the padding its look keeps inside it, and the engine's bar never shows; down alone, it is as wide as what it holds
	if along != ACROSS:
		vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED if along == DOWN else ScrollContainer.SCROLL_MODE_AUTO
		theme_type_variation = &"Scroll"
		_indicator = ScrollIndicator.new(ui.motion, get_v_scroll_bar(), self, &"panel")
		add_child(_indicator, false, Node.INTERNAL_MODE_BACK)
	set_process(false)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	follow_focus = true
	ui.chimes.listen(self, Chimes.GLOBAL, Driver.NAVIGATED)
	if reveal != null:
		ui.chimes.follow(self, &"reveal", _reveal_moved)


## The reader moved: where this stood on the view it is on now put back.
func heard(_what: StringName) -> void:
	_kept.moved()


## The name read, so it is followed; moved once this is ready, the piece of
## that name brought into view once it has been laid out - a frame on, since
## the layouts place their parts at the end of the frame the change came in.
## A name that moves with the reader - the flap of the place they are on -
## is heard after where this stood is put back, the reader's bell reaching
## this first, so the move ends with it seen.
func _reveal_moved() -> void:
	_reveal.read()
	if is_node_ready():
		_reveal_laid_out()


func _ready() -> void:
	if _reveal != null:
		_reveal_laid_out()


func _reveal_laid_out() -> void:
	await get_tree().process_frame
	if is_inside_tree():
		reveal_now()


## The named piece brought into view now, if there is one.
func reveal_now() -> void:
	if _reveal == null:
		return
	var named: Variant = _reveal.read()
	if named == null:
		return
	var piece: Node = _ui.node_named(named)
	if not (piece is Control and is_ancestor_of(piece)):
		return
	if _strip != null:
		_strip.keep(piece)
		return
	ShownWhole.show(self, _kept.get_offset(), piece)


## What of it shows words whole, on the canvas: a strip's whole things, else all of it.
func get_shown() -> Rect2:
	return Rect2(global_position + _strip.shown.position, _strip.shown.size) if _strip != null else get_global_rect()


func _process(seconds: float) -> void:
	toward_the_edge(get_local_mouse_position(), seconds)


## A point within this window, looked at for this long: moved toward the
## edge it is near while a carry is on (scroll_edge.gd).
func toward_the_edge(at: Vector2, seconds: float) -> void:
	ScrollEdge.toward(self, _carrying, at, seconds)


## The reader scrolling by hand: an offset still waiting to be put back is
## given up to them, and the focus is not brought back into view under them.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventPanGesture or event is InputEventScreenDrag:
		_kept.given_up()
		_by_hand = true


## A finger along its way, where it can move for it: its own (touch.gd).
func takes_finger(axis: StringName, travel: Vector2) -> bool:
	return _finger.takes(axis, travel)


## The finger moving it: scrolled by hand.
func finger_moved(_travel: Vector2, relative: Vector2) -> void:
	_kept.given_up()
	_by_hand = true
	_finger.moved(relative)


func finger_ended(velocity: Vector2) -> void:
	_finger.ended(velocity)


## The pad or the keys used anywhere - which the engine hands to the focus
## alone, never to what holds it - and the focus is followed into view again.
func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventAction or event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_by_hand = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		# where the engine placed the content, before a strip rests or an offset is put back
		var offset := _kept.get_offset()
		if _strip != null:
			_strip.rest()
		# every piece: the engine placed it at the whole offset, out of reach of the last sliver of a fractional room, so it goes the rest of the way
		for child: Node in get_children():
			(child as Control).position -= offset - offset.floor()
		var put_back := _kept.placed()
		if put_back:
			_by_hand = false
		var focus := get_viewport().gui_get_focus_owner()
		# the focus showing on something in a scroll that runs down, and the reader not scrolling by hand: it is shown whole
		if _strip == null and not _by_hand and focus != null and is_ancestor_of(focus) and focus.has_focus(true):
			ShownWhole.show(self, _kept.get_offset(), focus)
		# moved while being placed, which the engine does not place again of itself: placed again once this is over
		if _kept.get_offset() != offset:
			queue_sort.call_deferred()
		# everything inside that loads as the reader nears it, told the room has moved
		get_tree().call_group(Nearness.group_of(self), &"near_moved")
		# placed again as it scrolls: where the reader is looked at, down
		if _indicator != null:
			_indicator.moved()
	# a carry begun or ended anywhere in the window: only while one is on does this look at the pointer
	if what == NOTIFICATION_DRAG_BEGIN or what == NOTIFICATION_DRAG_END:
		_carrying = what == NOTIFICATION_DRAG_BEGIN
		set_process(_carrying)
	if what == NOTIFICATION_PREDELETE and _ui != null:
		_ui.chimes.stop_all(self)
	if what == NOTIFICATION_CHILD_ORDER_CHANGED:
		# the engine's scroll sizes its piece to the window only when told the piece fills
		for child: Node in get_children():
			if child is Control:
				(child as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
				(child as Control).size_flags_vertical = Control.SIZE_EXPAND_FILL


static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"scroll").new(ui, desc.props["reveal"], desc.props["along"])
	ui.attach(made, parent, desc.facts)
	return made
