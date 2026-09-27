extends Node

const Chimes := preload("chimes.gd")
const Bound := preload("components/primitives/bound.gd")
const Value := preload("components/primitives/value.gd")
const OwnBell := preload("components/primitives/own_bell.gd")
const Phrase := preload("phrase.gd")

## A controller that faces no reader: it listens, and does its work at once.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## What it listens to arrives as ADDRESSES, never as bells:
##
##     var tally := Tally.new(chimes, sums, [[&"a_screen", &"left_changed"]], &"a_screen")
##
## It never holds a bell, never sees one, and rings one through the chimes by
## name. So nothing here can keep hold of something a region was supposed to
## have dropped, and a wake cannot reach it by any route but the one its
## address declared.
##
## What it depends on is a model - sums, above - handed to it by whoever builds
## it, as an argument of its own constructor, and it calls that model: it reads
## the getters and asks it to do things. A request can carry arguments and get
## an answer back, so a refusal comes back as an ordinary return value. A call
## only ever goes toward whoever holds the fact. The model never calls what
## depends on it: it strikes a bell, and the listener reads. A bell carries
## nothing, so it is for news travelling back the other way, and for a control
## that must not know who acts on it, such as a button striking an address -
## never for an action with arguments, or one that needs an answer.
##
## Every wake arrives at heard(), with the name from that address.
##
## It does NOT wait for a frame. What it produces can be read the instant an
## input changes, so deferring the work would hand a reader the old answer - a
## hazard drawing does not have, because nobody reads a screen synchronously.
## Where the work is genuinely expensive the answer is to put it in the
## background, not to make it one frame late as well as slow.
##
## A bell it hangs is hung in its own region, so it goes when the region does.
## A bell has to be hung before anything listens to it, so a model hangs its
## bells as it is built and whatever listens to it is built after.
##
## Freed, it stops listening: the chimes cut its wires as the engine tells it
## it is about to go, so nothing built per data row needs a call at the call
## site to clean up after it.

## The region its connections belong to, so a screen and everything under it
## can be dropped together. Given as this is built, because connections are
## made there: a region set afterwards would leave everything declared at
## construction in the wrong one, which is silent.
var region: StringName = Chimes.GLOBAL

static var _regions: int = 0  # how many regions of their own have been handed out

var _chimes: Chimes
var _values := OwnBell.new("values")  # the one bell every value of this model rings, made before the members that declare them


func _init(chimes: Chimes, listening: Array = [], in_region: StringName = Chimes.GLOBAL) -> void:
	_chimes = chimes
	region = in_region
	_values.hang(chimes)
	listen(listening)


## A region of its own, at an address nothing else has, for a model that
## hangs bells and may be made more than once - two long lists, two sets of
## image loads - so its bells never collide and nobody outside has to name
## one. Whatever listens reads the model's region.
static func own_region(kind: String) -> StringName:
	_regions += 1
	return StringName("%s_%d" % [kind, _regions])


## Hang a bell under this name in this controller's own region.
func register_bell(name: StringName) -> void:
	_chimes.register(region, name)


## Connect everything declared, dropping whatever this was listening to before.
## Called as this is built; called again only by something rebinding it to a
## different set, such as a pooled one pointed at different content.
func listen(listening: Array) -> void:
	_chimes.stop_listening(self)
	# each declared address, as a region and a name
	for entry: Array in listening:
		listen_to(entry[0], entry[1])


## Add one more after building, for something that gains a subject rather than
## being rebound to a different set.
func listen_to(from_region: StringName, name: StringName) -> void:
	_chimes.listen(self, from_region, name)


## Stop hearing everything that arrives under that name.
func stop_listening_to(name: StringName) -> void:
	_chimes.stop(self, name)


## Sound the bell at an address. Any address: nothing is gated on having
## listened to it, and nothing here ever holds the bell it strikes.
func strike(in_region: StringName, name: StringName) -> void:
	_chimes.strike(in_region, name)


## What reaches this, by name. Answered by the chimes rather than kept here.
func listening_to() -> Array[StringName]:
	return _chimes.heard_by(self)


## About to be freed: cut loose from the chimes.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_chimes.stop_all(self)


## Every action this model is told. Whoever stands the model up registers it
## for these and nothing else: the application, from anywhere
## (application.gd, model()), or the place it is handed to, which answers
## there (describe_places.gd). So a model says what it answers, once, beside
## the code that answers it, and no application writes a region. None unless
## the model says.
func answers() -> Array[StringName]:
	return []


## Whether a command would be refused now, without doing it: the one
## refusal, written once, which told() is only called past: a phrase, or
## nothing - null. The base refuses nothing; a model with a rule answers it
## here, and never reads navigation. A control drawing the action follows
## whatever values this read, so nothing is listed.
func would(_action: StringName, _payload: Dictionary) -> Phrase:
	return null


## A value this model holds, declared as a member - var count := value(0):
## read by whoever shows it, set by this model, ringing this model's one
## bell once a frame (value.gd).
##
## ON a bell of the model's own, declared as a member above the values that
## take it and hung as the model is built, those values move together and
## apart from the rest: a reader of them is not woken when anything else the
## model holds moves. For a model holding two facts that move at different
## moments and are read by different readers - a query being asked, and the
## answer that lands later (queried_rows.gd). Still nobody lists a bell: a
## reader reads a value, and follows whichever bell that value hangs on.
func value(initial: Variant, on: OwnBell = null) -> Value:
	return Value.new(_values if on == null else on, initial)


## Do this work now, and again whenever anything it read moves: it listens
## to exactly what the work read (chimes.gd, follow), under this key.
func follow(key: StringName, work: Callable) -> void:
	_chimes.follow(self, key, work)


## Every wake arrives here and nowhere else, with the name this was listening
## under. The bell sent nothing: the name was tied to this end of the wire when
## the connection was made. Overridden by a subclass, which decides in one place
## what each one means - including that some mean nothing.
##
##     func heard(what: StringName) -> void:
##         match what:
##             &"left_changed", &"right_changed": _total = _sums.get_left() + _sums.get_right()
func heard(_what: StringName) -> void:
	pass
