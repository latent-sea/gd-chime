extends Node

const Chimes := preload("chimes.gd")
const Bound := preload("components/primitives/bound.gd")
const Value := preload("components/primitives/value.gd")
const OwnBell := preload("components/primitives/own_bell.gd")
const Phrase := preload("phrase.gd")

## A model: the facts an application is made of, held as values, and the
## commands that move them. It faces no reader.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A FACT IS A VALUE, declared as a member and set wherever it moves - by a
## command told through the door, the game's own tick, a job landing:
##
##     class Crates extends Controller:
##         var counted := value(0)
##         func told(_action: StringName, _payload: Dictionary) -> Phrase:
##             counted.set_value(counted.read() + 1)
##             return null
##
## Whoever shows it reads it - `crates.counted`, handed to a text or mapped
## into words - and the read is tracked: the reader follows exactly what it
## read, and draws again when any of it moves. Nobody names a bell and nobody
## writes a list of what changed; a value cannot tell who set it, so a fact
## moved from outside a press is followed the same way (value.gd, reads.gd).
##
## What a model depends on is another model, handed to it by whoever builds
## it, as an argument of its own constructor, and it calls that model: it
## reads its values and asks it to do things. A request can carry arguments
## and get an answer back, so a refusal comes back as an ordinary return
## value. A call only ever goes toward whoever holds the fact; the model
## never calls what depends on it. What it works out from another model's
## values it works out as it is read (ui.bound), or keeps with a follow
## (follow(), below), which runs the work again whenever what it read moves.
##
## Listening by address - listen(), heard() - is for a bell a part of the
## floor rings by hand, never for a fact: a fact is a value.
##
## WHAT IT FOLLOWS REACHES IT AT THE END OF THE FRAME, never the instant: a
## value's bell rings once the frame's work is done (own_bell.gd), and a
## model's followed work runs in that ring. So a model that keeps
## its own copy of another's value holds the old one until then. What must
## be current the instant an input changes is not copied but WORKED OUT AS
## IT IS READ - a function over the values (ui.bound), or one kept with what
## it read (reads.gd, worked), which lets itself go the moment a value it read
## is set - so a reader asking straight after a set gets the new answer.
## Ringing at once would undo the once-a-frame ring every draw relies on;
## where the work is genuinely expensive the answer is to put it in the
## background, not to ring sooner.
##
## Its values ring one bell of its own, hung as it is built, in its region, so
## it goes when the region does.
##
## Freed, it stops listening: the chimes cut its wires as the engine tells it
## it is about to go - and a region of its own goes too (own_region) - so
## nothing built per data row needs a call at the call site to clean up
## after it.

## The region its connections belong to, so a screen and everything under it
## can be dropped together. Given as this is built, because connections are
## made there: a region set afterwards would leave everything declared at
## construction in the wrong one, which is silent.
var region: StringName = Chimes.GLOBAL

static var _regions: int = 0  # how many regions of their own have been handed out
static var _owned: Dictionary = {}  # the regions of their own handed out whose model stands, used as a set

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
## one. Whatever listens reads the model's region. Freed, the model takes the
## region down with it, so a list made and freed a thousand times holds none.
static func own_region(kind: String) -> StringName:
	_regions += 1
	var own := StringName("%s_%d" % [kind, _regions])
	_owned[own] = true
	return own


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


## About to be freed: cut loose from the chimes, and a region of its own
## taken down with every bell hung there.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_chimes.stop_all(self)
		if _owned.has(region):
			_owned.erase(region)
			_chimes.drop_region(region)


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


## Every wake of a bell listened to by address arrives here and nowhere else,
## with the name this was listening under - a bell the floor rings by hand,
## never a fact, which is a value followed (follow()). The bell sent nothing:
## the name was tied to this end of the wire when the connection was made.
## Overridden by a subclass, which decides in one place what each one means.
##
##     func heard(what: StringName) -> void:
##         match what:
##             Commands.COMMAND_RAN: _ran += 1
func heard(_what: StringName) -> void:
	pass
