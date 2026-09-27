extends Container

const Motion := preload("../../motion.gd")
const Touch := preload("../../touch.gd")
const Shift := preload("shift.gd")
const Reads := preload("../../reads.gd")

## Pull to refresh: a list drawn down past its top by a finger opens, above
## it, what says letting go will refresh it; let go far enough, the refresh
## is one command through the door, and it stays open on what says it is
## refreshing until the refresh has landed.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## IT HOLDS TWO THINGS, an INDICATOR and the SCROLL (scroll.gd), one over the
## other. At rest the indicator is hidden and the scroll fills it. A finger
## drawn DOWN while the scroll is at its top - which that scroll lets go past
## it (scroll_finger.gd) - is its own (touch.gd): the indicator opens above
## the scroll by half the finger's travel, a pull resisting the hand, no
## further than twice the indicator's height, and the scroll stands below
## it in the room left, so nothing is ever drawn over anything.
##
## WHERE IT STANDS IS A LOCAL, its PHASE, which the indicator's words read:
## RESTING, PULLING, ARMED - open as far as the indicator is tall, so it
## stands whole - and REFRESHING. Let go armed, the action is dispatched in
## its place's region: refused, it closes; taken, it stays open by the
## indicator's height, REFRESHING, until the bound value it was given - a
## fetch's "loading" (fetched.gd) - says it has landed, and then
## closes on the one clock. A refresh begun any other way - a press, a key -
## opens it the same, so the reader always sees one on its way.
##
## The keys, the pad and the pointer have their own way to the same action -
## the application's press of it - so a pull is never the only way.
##
## Deliberately absent: a pull on a list not at its top, and a refresh that
## shows how far along it is.

## Where a pull stands: at rest, drawn, drawn far enough, and refreshing.
const RESTING := &"resting"
const PULLING := &"pulling"
const ARMED := &"armed"
const REFRESHING := &"refreshing"
## How much of the finger's travel the pull follows.
const RESISTANCE := 0.5
## What of it the one clock drives.
const WHAT := &"pull"

## The one clock it opens and closes on, handed in by the builder.
var motion: Motion = null
var _ui: RefCounted
var _action: StringName
var _region: StringName
var _phase: RefCounted  # a Local: where it stands, which the indicator reads
var _refreshing: RefCounted  # a Bound: whether the refresh is on its way
var _open: float = 0.0  # how far it is pulled open, in its own pixels
var _running: Motion.Run = null  # an opening or a closing on its way, or none


func _init(ui: RefCounted, action: StringName, phase: RefCounted, refreshing: RefCounted) -> void:
	_ui = ui
	_action = action
	_region = ui.region()
	_phase = phase
	_refreshing = refreshing
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group(Touch.TAKES)
	# the refresh followed: it opens as one begins and closes as it lands
	ui.chimes.follow(self, &"refreshing", _refresh_moved)


## How far it is pulled open now.
func get_open() -> float:
	return _open


## A finger drawn down, and no refresh on its way: the scroll it holds is
## nearer the finger and takes one it can move for, so this is asked only at its top.
func takes_finger(axis: StringName, travel: Vector2) -> bool:
	return axis == Touch.DOWN and travel.y > 0.0 and _phase.read() != REFRESHING


## Open by half the finger's travel, armed once the indicator stands whole.
func finger_moved(travel: Vector2, _relative: Vector2) -> void:
	_stop()
	_opened(clampf(travel.y * RESISTANCE, 0.0, _tall() * 2.0))
	_phase.set_value(ARMED if _open >= _tall() else PULLING)


## Let go: armed, the refresh through the door - taken, it stays open until
## it lands; refused or short, it closes.
func finger_ended(_velocity: Vector2) -> void:
	if _phase.read() == ARMED and _ui.commands.dispatch(_region, _action, {}) == null:
		_refreshing_now()
		return
	_phase.set_value(RESTING)
	_drive(0.0)


## The refresh read, so it is followed; moved once this is ready - begun,
## it opens refreshing; landed, it closes - apart from what is followed,
## so the phase this sets is not among it (reads.gd).
func _refresh_moved() -> void:
	var refreshing: bool = _refreshing.read()
	if is_node_ready():
		Reads.apart(_opened_or_closed.bind(refreshing))


## Begun, open refreshing; landed while refreshing, closed.
func _opened_or_closed(refreshing: bool) -> void:
	if refreshing:
		_refreshing_now()
	elif _phase.read() == REFRESHING:
		_phase.set_value(RESTING)
		_drive(0.0)


## Open by the indicator's height, refreshing.
func _refreshing_now() -> void:
	_phase.set_value(REFRESHING)
	_drive(_tall())


## Open to here on the one clock - or at once, with none.
func _drive(to: float) -> void:
	_stop()
	if motion == null:
		_opened(to)
		return
	_running = motion.drive(self, WHAT, _open, to, Motion.MOVE, _opened)


func _stop() -> void:
	if _running != null:
		_running.stopped = true
		_running = null


## Open this far: the indicator and the scroll placed again.
func _opened(by: float) -> void:
	_open = by
	queue_sort()


## How tall the indicator stands.
func _tall() -> float:
	return (get_child(0) as Control).get_combined_minimum_size().y


## The indicator, shown only while it is open, in the room the pull opened,
## its foot on the scroll's top; the scroll in the room below.
func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		var indicator: Control = get_child(0)
		indicator.visible = _open > 0.0
		Shift.fit(self, indicator, Rect2(0.0, _open - _tall(), size.x, _tall()))
		Shift.fit(self, get_child(1), Rect2(0.0, _open, size.x, size.y - _open))
	if what == NOTIFICATION_PREDELETE:
		_ui.chimes.stop_all(self)


## As wide as either needs and as tall as the scroll needs: the indicator opens into the scroll's room.
func _get_minimum_size() -> Vector2:
	if get_child_count() < 2:
		return Vector2.ZERO
	var scroll := (get_child(1) as Control).get_combined_minimum_size()
	return Vector2(maxf(scroll.x, (get_child(0) as Control).get_combined_minimum_size().x), scroll.y)


## The builder's door: a pull of the place being built into, its indicator and its scroll built into it.
static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"pull").new(ui, desc.props["action"], desc.props["phase"], desc.props["refreshing"])
	ui.attach(made, parent, desc.facts)
	return made
