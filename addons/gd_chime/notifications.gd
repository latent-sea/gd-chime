extends "controller.gd"

const Commands := preload("commands.gd")
const Motion := preload("motion.gd")
const ActionControl := preload("action_control.gd")
const Feedback := preload("theme_feedback.gd")
const Look := preload("look.gd")

## The application's notifications: short messages that arrive, stay for a
## time the look gives, and leave, one showing at a time and the rest
## waiting their turn in the order they came.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A NOTIFICATION IS DATA the application owns, never a place and never a
## moment: notify(words, offer, payload) and it stands - its words a
## phrase, and at most one offer, an action of the register with the
## payload its press carries ("view the day's sales"). A screen draws them
## where its layout leaves room (notification_tray.gd), so one arriving
## takes the focus from nothing and nothing is drawn over it or by it. A
## moment interrupts; a notification does not. ONE MADE WITH NO TRAY
## STANDING is reported out loud by its words as it is made, since it would
## be shown nowhere. A tray says it stands by its mark (tray_stand.gd), as
## it enters the tree and leaves it; something else reading them - a count -
## is no tray, and a place showing none is fine while the app's frame holds one.
## ONE WHOSE WORDS RUN PAST THE LINES the look allows a notification is
## reported out loud too, asked of every tray standing (tray_stand.gd's
## fits): the tray's room never grows, so such words scroll within it, and
## writing them is the application's fault.
##
## ONE SHOWS AT A TIME, as was ruled (2026-09-19): the oldest standing is
## the one a tray shows, and the next shows only once it is cleared - so
## only the oldest's time passes, and one waiting has its whole stay still
## to come when its turn comes. IT STAYS for the look's STAYS, a Motion
## token in milliseconds read from the window's look as it arrives - never
## seconds in code - and then it leaves. The time is this model's own,
## counted frame by frame; a test turns by_hand on and calls step(seconds).
## While the focus is on a press of a notification - its offer or its
## dismissal, walked to by the keys or the pad - its time does not pass, so
## what a reader has come to read does not leave under them. It LEAVES
## EARLY by the reader: DISMISSES, {"notice": its id}, a command of this
## model's own from anywhere; or by its offer being done - a command of
## the offer's action with its payload that ran and was not refused, heard
## on the door's own bell, so the offer's handler knows nothing of this.
##
## ARRIVED rings as one arrives, and nothing else: the sound of the look
## for it is sounds.gd's, which listens there. The notifications standing
## are a value (value.gd), set as they change, arriving or leaving.
##
## Deliberately absent: a notification that stays until dismissed, more
## than one offer, and a limit on how many may wait - each waiting is
## shown in its turn, and a burst is the application's to fold
## (paced_notices.gd).

const ARRIVED := &"notice_arrived"
## The command that sends one away, {"notice": its id}.
const DISMISSES := &"dismisses_notice"

## Stepped by a test instead of by the engine's frames.
var by_hand: bool = false

var _commands: Commands
var _under: Node  # what this stands under, whose look says how long one stays
var _standing := value([])  # each {id, words, offer, payload, left - the seconds it has still to stay}, oldest first
var _last_id: int = 0
var _trays: Array[Node] = []  # every tray standing in the tree, each put here by its mark (tray_stand.gd)


func _init(chimes: Chimes, commands: Commands, under: Node) -> void:
	super(chimes, [[Chimes.GLOBAL, Commands.COMMAND_RAN]], Chimes.GLOBAL)
	_commands = commands
	_under = under
	register_bell(ARRIVED)


## One arriving: these words, and at most one offer - an action and the
## payload its press carries. Its id, which a dismissal names.
func notify(words: Phrase, offer: StringName = &"", payload: Dictionary = {}) -> int:
	if _trays.is_empty():
		push_error("\"%s\" is notified and no tray stands to show it: the app's frame holds a notification tray (notification_tray.gd)" % str(words))
	# every tray standing, asked whether the words fit the lines a notification may run to
	for tray: Node in _trays:
		if not tray.fits(str(words)):
			push_error("\"%s\" is too long for the tray: a notification runs to the look's lines, and these scroll within their room" % str(words))
	_last_id += 1
	_standing.set_value(_standing.read() + [{"id": _last_id, "words": words, "offer": offer, "payload": payload, "left": Look.wearer(_under).get_theme_constant(Feedback.STAYS, Motion.TYPE) / 1000.0}])
	strike(region, ARRIVED)
	return _last_id


## A tray standing, as it enters the tree.
func add_tray(tray: Node) -> void:
	_trays.append(tray)


## A tray gone, as it leaves the tree.
func remove_tray(tray: Node) -> void:
	_trays.erase(tray)


## The notifications standing, oldest first: each {id, words, offer, payload}.
func get_standing() -> Array:
	return _standing.read().map(func(one: Dictionary) -> Dictionary: return {"id": one["id"], "words": one["words"], "offer": one["offer"], "payload": one["payload"]})


## A dismissal of one that has already left - its piece on its way out - is refused.
func would(_action: StringName, payload: Dictionary) -> Phrase:
	return null if _standing.read().any(func(one: Dictionary) -> bool: return one["id"] == payload["notice"]) else Phrase.of("Already gone")


func told(_action: StringName, payload: Dictionary) -> Phrase:
	_leave(func(one: Dictionary) -> bool: return one["id"] == payload["notice"])
	return null


## A command ran: every notification whose offer it was - the same action
## and payload, done, not refused and not paused - has been answered, and leaves.
func heard(_what: StringName) -> void:
	var ran := _commands.get_last()
	if ran["answer"] != null or ran["paused"]:
		return
	_leave(func(one: Dictionary) -> bool: return one["offer"] == ran["action"] and one["payload"] == ran["payload"])


func _process(delta: float) -> void:
	if not by_hand:
		step(delta)


## This much time passed: the stay of the one showing - the oldest -
## shorter by it, and gone once it is over, unless the focus is on its
## press; the ones waiting keep their whole stay for their turn.
func step(seconds: float) -> void:
	var standing: Array = _standing.read()
	if standing.is_empty() or _read_now():
		return
	# the time it has left, which nothing reads, counted down in place
	standing[0]["left"] -= seconds
	if standing[0]["left"] <= 0.0:
		_leave(func(one: Dictionary) -> bool: return one["id"] == standing[0]["id"])


## Whether the focus is on a press of a notification standing - its
## dismissal, or its offer with its payload.
func _read_now() -> bool:
	var on := get_viewport().gui_get_focus_owner()
	if not on is ActionControl:
		return false
	var press := on as ActionControl
	return press.action == DISMISSES or _standing.read().any(func(one: Dictionary) -> bool: return one["offer"] == press.action and one["payload"] == press.payload())


## Every notification this says leaves, gone, and those standing set if any went.
func _leave(goes: Callable) -> void:
	var kept: Array = _standing.read().filter(func(one: Dictionary) -> bool: return not goes.call(one))
	if kept.size() != _standing.read().size():
		_standing.set_value(kept)
