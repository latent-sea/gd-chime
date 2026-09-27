extends RefCounted

const Belfry := preload("belfry.gd")
const Reads := preload("reads.gd")
const Wires := preload("wires.gd")

## Who hears which bell.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A listener is connected to a bell by its ADDRESS, and hears it under the
## name in that address. The bell sends nothing; the name is tied to the
## listener's end of the wire when the connection is made, so the same bell
## reaches two listeners under whatever word each one listened with. Controllers are given addresses rather than bells:
## they never hold one, never see one, and ring one through here - so nothing
## above this file can keep hold of something it was supposed to have let go.
##
## A name means one thing per listener, ACROSS EVERY REGION. Listening twice
## to the same name is refused, whichever region each bell hangs in: heard()
## is handed the name alone, so two bells of one name could never be told
## apart once they arrived. A listener that needs both is two listeners.
##
## A listener is anything with heard(StringName). Nothing else about it is
## known here but its region, if it has one, and nothing here knows what a
## strike means. The wires themselves are kept next door (wires.gd), by
## listener and then by the key they were made under and the address they
## hang at - so what one listener hears is its own business, and what a piece
## of work read is compared with what is wired as one set against another.
## This decides what to wire and what to cut; that holds the record.
##
## A bell has to be hung before anything listens to it: listening at an
## address nobody has hung is refused out loud, where the mistake is, rather
## than connecting to nothing. Whoever strikes a bell hangs it as it is built,
## and whatever listens is built after.
##
## Dropping a region takes everything that belongs to it: the connections of
## its own listeners, the connections of anything listening into it, and its
## bells. A screen and all of its parts go quiet together, and nothing outside
## is left holding a bell the region forgot.
##
## Hanging a bell and striking one both go through here as well as listening,
## so a controller needs the chimes and nothing else to take part. This holds
## the belfry; nothing above it does.
##
## A LISTENER MAY ALSO FOLLOW WHAT A PIECE OF WORK READ (follow): the work
## runs, every bell what it read moves on is noted (reads.gd), and the
## listener is wired to exactly those, under a key of its own. WHAT IT READ
## IS ALMOST ALWAYS WHAT IT READ LAST TIME - every draw of every control
## comes through here - so the set read is compared against the addresses
## already wired, and an unchanged one is left exactly as it is: nothing
## cut, nothing made, no arrival built. Only a difference is wired or cut.
## A ring there arrives where the follower said, or runs the work again,
## which follows again; heard() is not told, so a followed bell takes no
## name from the listener and needs none.
##
## Nothing else in this folder connects anything but a part it builds itself.
## A text field hearing its own LineEdit is freed with it, so that connection
## can neither outlive an end nor cross a region, and nothing need hold it.

const GLOBAL := Belfry.GLOBAL

## The regions no place may be named after: the global one, hung for whatever
## outlives every screen.
const RESERVED: Array[StringName] = [GLOBAL]

## What the wires a listener merely listens with are kept under: a listen
## follows no work, so it has no key of its own.
const LISTENED := &""

var _belfry: Belfry
var _wires: Wires


func _init(belfry: Belfry) -> void:
	_belfry = belfry
	_wires = Wires.new(belfry)


## Hang a bell at an address. The belfry does it; this is the door.
func register(region: StringName, name: StringName) -> void:
	_belfry.register(region, name)


## Sound the bell at an address, counting what it rings for as moved, so
## whatever was kept with a read of it lets go (reads.gd). The belfry does
## the striking; this is the door.
func strike(region: StringName, name: StringName) -> void:
	Reads.moved(region, name)
	_belfry.strike(region, name)


## Whether a bell is sounding right now, so a listener is running. What may
## not be done from inside heard() asks this.
func is_striking() -> bool:
	return _belfry.is_striking()


## Connect a listener to the bell at an address, arriving under that name.
func listen(listener: Object, region: StringName, name: StringName) -> void:
	# every address this listener already listens at, looking for the name: heard() is handed the name alone, so a second of it could not be told apart
	for at: StringName in _wires.under(listener, LISTENED):
		var taken := _belfry.bell_at(at)
		if taken.name == name:
			push_error("already listening to something called %s, in %s; heard() gets the name alone, so a listener hearing both must be two listeners" % [name, taken.region])
			return
	if not _belfry.has(region, name):
		push_error("nothing is hung at %s/%s to listen to" % [region, name])
		return
	# the name is tied to the listener's end of the wire: the bell sends nothing, and bind() adds it on the way in
	_wires.make(listener, _belfry.at(region, name), listener.heard.bind(name), LISTENED)


## Run the work, and wire the listener to exactly what it read, under this
## key: a ring there calls moved - or, given none, runs the work again, which
## follows again. Having read what it read last time, it is left alone. An
## address whose region has gone is read from nothing that can ring, and is
## passed over.
func follow(listener: Object, key: StringName, work: Callable, moved: Callable = Callable()) -> void:
	var read: Dictionary = Reads.tracked(work)
	var standing: Dictionary = _wires.under(listener, key)
	var wired: bool = read.size() == standing.size()
	# every address read, against what is wired under this key: one that is not there and the two sets differ
	for at: StringName in read:
		if not standing.has(at):
			wired = false
			break
	# it read what it read last time, which is almost every draw: nothing cut, nothing made, no arrival built
	if wired:
		return
	# a function of its own for each follow, never follow.bind(): the engine counts two binds of one method equal whatever they carry - measured - so a second follower's would not connect
	var arrival: Callable = func() -> void: follow(listener, key, work)
	if moved.is_valid():
		arrival = func() -> void: moved.call()
	# every address read and not wired already, wired, unless nothing is hung there
	for at: StringName in read:
		var bell := _belfry.bell_at(at)
		if not standing.has(at) and bell != null:
			_wires.make(listener, bell, arrival, key)
	# every address wired under this key and no longer read, cut; the addresses are taken first, because cutting erases them
	for at: StringName in standing.keys():
		if not read.has(at):
			_wires.cut(listener, key, at)


## Stop one listener hearing what arrives under that name.
func stop(listener: Object, name: StringName) -> void:
	# every address this listener listens at, cut if the bell hung there is the one called that
	for at: StringName in _wires.under(listener, LISTENED).keys():
		if _belfry.bell_at(at).name == name:
			_wires.cut(listener, LISTENED, at)


## Stop one listener following what it followed under this key.
func unfollow(listener: Object, key: StringName) -> void:
	_wires.cut_key(listener, key)


## Stop one listener hearing every bell it listened to, and leave what it
## follows standing: a listener rebound to other bells still reads what it read.
func stop_listening(listener: Object) -> void:
	_wires.cut_key(listener, LISTENED)


## Stop one listener hearing anything at all: its wires cut and its key gone.
## A listener that is a node calls this as it is freed, so a row rebuilt from
## data cleans up after itself with no call at the call site.
func stop_all(listener: Object) -> void:
	_wires.cut_all(listener)


## Take out a whole region in one call: every connection of a listener that
## belongs to it or listens into it, and every bell hung there.
func drop_region(region: StringName) -> void:
	_wires.cut_region(region)
	_belfry.drop_region(region)
	Reads.forget(region)


## What reaches this listener, as the names it was given. The question a
## surface has to answer about itself, and the one to ask when a wake turns up
## somewhere surprising.
func heard_by(listener: Object) -> Array[StringName]:
	var names: Array[StringName] = []
	# every address this listener listens at, under the name the bell there is called
	for at: StringName in _wires.under(listener, LISTENED):
		names.append(_belfry.bell_at(at).name)
	return names


## The addresses a listener follows under this key: what its work last read.
func followed_by(listener: Object, key: StringName) -> Array:
	var addresses: Array = []
	# every address wired under that key, as the region and the name it hangs at
	for at: StringName in _wires.under(listener, key):
		var bell := _belfry.bell_at(at)
		addresses.append([bell.region, bell.name])
	return addresses


## Which listeners the bell at that address reaches. Asked of an address
## nothing is hung at - a place that has closed - it answers nobody, rather
## than reaching for a bell that has gone.
func listeners_of(region: StringName, name: StringName) -> Array:
	return _wires.listeners_of(Reads.hung(region, name))


## How many connections are held, so that growth is something a test can read.
func count() -> int:
	return _wires.count()


## How many listeners hold any connection, so a test can read the structure.
func count_listeners() -> int:
	return _wires.count_listeners()
