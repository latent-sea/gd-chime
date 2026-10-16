extends Container

const Preferred := preload("preferred.gd")
const PageScroll := preload("page_scroll.gd")
const Shift := preload("shift.gd")

## One piece laid in the middle of the room it is given, on each axis at
## what it needs, up to a cap - the room less a margin either side, and a
## most - and never under its own least: a sheet growing to fit what it
## holds, up to a ceiling.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## ITS LOOK NAMES THE CAP: margin, either side on both axes, and most_wide
## and most_tall, in base pixels, read each time it lays its piece out, so
## a look worn later caps it again. A most of zero, or none, is no most.
##
## ON EACH AXIS IT LAYS ITS PIECE ONE OF THREE WAYS: at what the piece
## needs, up to the cap (NEEDS); at the cap, whatever the piece needs
## (SPANS); or across the whole room, uncapped (FILLS). Where the cap leaves
## less than the piece's least, the margin is dropped on that axis, so the
## piece meets the room's edges there before it is ever laid under its least.
##
## WHAT A PIECE NEEDS is what it would take given all the room it wants
## (preferred.gd), and down, every page inside it (page_scroll.gd) laid
## whole: a page asks for no height of its own, so a sheet holding one
## would otherwise be laid with none of its page showing.
##
## IT LOOKS AGAIN EACH FRAME IT IS SHOWN: what a page holds needing more
## moves nothing above the page, which asks for the same whatever it holds,
## so nothing would tell this to lay its piece out again.
##
## ITS LEAST IS ITS PIECE'S, with no margin, since the margin is the first
## thing to go. It takes no press: beside its piece, a press goes on to
## what lies beneath it - a shade.

## The kind it is built as (ui.gd).
const KIND := &"capped"
## How it lays its piece on an axis: at what it needs up to the cap, at the cap, or across the whole room.
const NEEDS := 0
const SPANS := 1
const FILLS := 2

var _look: StringName
var _ways: Vector2i  # how it lays its piece across and down: NEEDS, SPANS or FILLS
var _laid_need := Vector2(-1.0, -1.0)  # what its piece needed when it was last laid out; nothing yet


func _init(look: StringName, across: int, down: int) -> void:
	_look = look
	_ways = Vector2i(across, down)
	# beside its piece, a press goes on to what lies beneath, as a stack's does
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _get_minimum_size() -> Vector2:
	# asked as it is attached, before its piece is built into it: nothing, until then
	if get_child_count() == 0:
		return Vector2.ZERO
	return (get_child(0) as Control).get_combined_minimum_size()


## What its piece would take for nothing in it to scroll: what it would
## take given all the room it wants, and down, all that every page inside it holds.
func needs() -> Vector2:
	var piece: Control = get_child(0)
	var need := Preferred.of(piece)
	# every page inside the piece, whose least counts only its padding: what it holds, all of it, added down
	for page: Node in piece.find_children("*", "ScrollContainer", true, false):
		if page is PageScroll:
			need.y += (page.get_child(0) as Control).get_combined_minimum_size().y
	return need


func _notification(what: int) -> void:
	# looking each frame only while it is shown
	if what == NOTIFICATION_ENTER_TREE or what == NOTIFICATION_VISIBILITY_CHANGED:
		set_process(is_visible_in_tree())
	if what != NOTIFICATION_SORT_CHILDREN:
		return
	var piece: Control = get_child(0)
	var least := piece.get_combined_minimum_size()
	var margin := float(get_theme_constant(&"margin", _look))
	var most := Vector2(get_theme_constant(&"most_wide", _look), get_theme_constant(&"most_tall", _look))
	_laid_need = needs()
	var laid := Rect2(Vector2.ZERO, size)
	# across, then down: the piece's length on the axis, and where it starts
	for axis: int in 2:
		if _ways[axis] == FILLS:
			laid.size[axis] = maxf(size[axis], least[axis])
			continue
		var want: float = _laid_need[axis] if _ways[axis] == NEEDS else INF
		var ceiling: float = most[axis] if most[axis] > 0.0 else INF
		var length := minf(minf(want, ceiling), size[axis] - 2.0 * margin)
		# the cap leaves less than the piece's least: the margin dropped, the piece meeting the room's edges
		if length < least[axis]:
			length = maxf(least[axis], minf(minf(want, ceiling), size[axis]))
		laid.size[axis] = length
		laid.position[axis] = maxf((size[axis] - length) / 2.0, 0.0)
	Shift.fit(self, piece, laid)


func _process(_delta: float) -> void:
	# what it holds needs something else than when it was laid: laid out again
	if needs() != _laid_need:
		queue_sort()


static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(KIND).new(desc.props["look"], desc.props["across"], desc.props["down"])
	ui.attach(made, parent, desc.facts)
	return made
