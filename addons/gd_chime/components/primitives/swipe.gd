extends "pressable.gd"

const Going := preload("going.gd")
const Shift := preload("shift.gd")

## A row a finger swipes: drawn across, what it holds slides with the finger
## and uncovers, on the side it leaves, what letting go there will do - in
## words and a mark, never a hue alone; let go past the look's share of its
## width, that is done, one command through the door; short of it, the row
## springs back. Tapped, it is pressed like any pressable.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A GESTURE ACROSS IS ITS OWN, one down is the scroll's (touch.gd): it takes
## a finger across toward a side it has an action for, and the row follows
## it to the pixel. Its SIDES are {RIGHT: an action, LEFT: an action} - the
## finger drawn right uncovers the left edge, where the RIGHT side's reveal
## stands - each dispatched with the payload its press carries. What it
## holds is its first part; each side's REVEAL, the caller's description,
## follows in the order the sides were given, placed against the edge of
## what slid, so it comes into view with it and is never drawn over it.
##
## PAST THE LOOK'S SHARE IT IS ARMED (Touch's swipe_commit, in thousandths
## of its width): the uncovered ground is drawn in the side's armed box
## rather than its reveal box. Let go armed, the side's action is asked of
## the door: done, the row slides the rest of the way out and, if it is
## still there - a model that kept the thing in place - slides back in;
## refused, it springs back and the refusal is its reason, as a press's is.
## Let go short of it, it springs back. Every slide is the one clock's.
##
## THE KEYS AND THE PAD NEVER SWIPE: a swipe is never the only way. The
## recipe over it (swipe_row.gd) offers the same actions in its menu, and
## the application where else it likes.
##
## Its box, its focus and what it holds are drawn where the finger has taken
## them, clipped to its own rect; the ground uncovered is its style's
## reveal_right, armed_right, reveal_left and armed_left.
##
## Deliberately absent: a fling that commits a short swipe, and a mouse
## that swipes - the pointer has the menu and the press.

## The two sides: the finger drawn to the right, and to the left.
const RIGHT := &"right"
const LEFT := &"left"
## What of it the one clock drives.
const WHAT := &"swipe"

var _sides: Dictionary  # side -> the action letting go there dispatches
var _offset: float = 0.0  # how far what it holds has slid, rightward positive
var _sliding: Motion.Run = null  # the slide on its way on the one clock, or none


func _init(chimes: Chimes, commands: Commands, place: Node, does: StringName, payload: Variant, sides: Dictionary, style: Variant) -> void:
	super(chimes, commands, place, does, payload, style)
	_sides = sides
	add_to_group(Touch.TAKES)


## How far what it holds has slid now, rightward positive.
func get_slid() -> float:
	return _offset


## Whether it would do its side's action if let go now.
func is_armed() -> bool:
	return absf(_offset) >= size.x * get_theme_constant(&"swipe_commit", Touch.TYPE) / 1000.0


## A gesture across toward a side it has an action for is its own.
func takes_finger(axis: StringName, travel: Vector2) -> bool:
	return axis == Touch.ACROSS and _sides.has(RIGHT if travel.x > 0.0 else LEFT) and is_usable()


## What it holds follows the finger, only toward a side it has, and no further than its width.
func finger_moved(travel: Vector2, _relative: Vector2) -> void:
	# a slide on its way is the finger's now
	if _sliding != null:
		_sliding.stopped = true
		_sliding = null
	var towards := RIGHT if travel.x > 0.0 else LEFT
	_slid(clampf(travel.x, -size.x, size.x) if _sides.has(towards) else 0.0)


## Let go: armed, its side's action is asked of the door; otherwise, or refused, it springs back.
func finger_ended(_velocity: Vector2) -> void:
	if not is_armed():
		_drive(0.0, Callable())
		return
	var side := RIGHT if _offset > 0.0 else LEFT
	var answer := _commands.dispatch(region, _sides[side], payload())
	_keep_refusal(null if _commands.get_last()["paused"] else answer)
	needs_refresh()
	if answer != null:
		_drive(0.0, Callable())
		return
	# done: out the rest of the way, and back in if the thing stayed where it was
	_drive(signf(_offset) * size.x, _back_if_standing)


## Out and done: back in only if it is still standing - one on its way out stays out.
func _back_if_standing() -> void:
	if not Going.is_going(self):
		_drive(0.0, Callable())


## Slid to here on the one clock - or at once, with none.
func _drive(to: float, done: Callable) -> void:
	if motion == null:
		_slid(to)
		if done.is_valid():
			done.call()
		return
	_sliding = motion.drive(self, WHAT, _offset, to, Motion.MOVE, _slid, false, done)


## What it holds slid this far: placed again and drawn again, and clipped to
## its rect only while slid - at rest it cuts nothing, so a list holding it
## judges its words as it judges any.
func _slid(to: float) -> void:
	_offset = to
	clip_contents = to != 0.0
	queue_sort()
	queue_redraw()


## After the pressable has placed its parts inside its box - the engine
## tells every level, the face's first - what it holds is slid, and each
## side's reveal stands against the edge that slid away from it, shown only
## while that side is uncovered.
func _notification(what: int) -> void:
	if what != NOTIFICATION_SORT_CHILDREN or get_child_count() == 0:
		return
	var box := _settled_box()
	var gap := box.get_margin(SIDE_LEFT)
	(get_child(0) as Control).position.x += _offset
	var at := 1
	# every side it has, in the order given, its reveal the next part
	for side: StringName in _sides:
		var reveal: Control = get_child(at)
		var wide := reveal.get_combined_minimum_size().x
		reveal.visible = (side == RIGHT and _offset > 0.0) or (side == LEFT and _offset < 0.0)
		var left := _offset - wide - gap if side == RIGHT else size.x + _offset + gap
		Shift.fit(self, reveal, Rect2(left, box.get_margin(SIDE_TOP), wide, size.y - box.get_margin(SIDE_TOP) - box.get_margin(SIDE_BOTTOM)))
		at += 1


## The ground it uncovered in its side's box, armed or not; then its own
## boxes where what it holds has slid to.
func _draw() -> void:
	if _offset != 0.0:
		var side := RIGHT if _offset > 0.0 else LEFT
		var uncovered := Rect2(0.0, 0.0, _offset, size.y) if _offset > 0.0 else Rect2(size.x + _offset, 0.0, -_offset, size.y)
		draw_style_box(get_theme_stylebox(StringName(("armed_" if is_armed() else "reveal_") + side)), uncovered)
	# every box its state draws, where the finger has taken it
	for box: StyleBox in get_drawn():
		draw_style_box(box, Rect2(Vector2(_offset, 0.0), size))


## The builder's door: a swipe of the place being built into, what it holds
## then each side's reveal built into it.
static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"swipe").new(ui.chimes, ui.commands, ui.current_place(), desc.props["action"], desc.props["payload"], desc.props["sides"], desc.props["style"])
	made.prompts = ui.prompts
	ui.attach(made, parent, desc.facts)
	return made
