extends RefCounted

const Bell := preload("bell.gd")
const Reads := preload("reads.gd")

## The belfry: every bell there is, each hung at an address.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## An address is a REGION and a NAME together. A region groups what belongs
## together - a screen, the things it shows and the controllers under it share
## one - so closing that screen forgets all of it in a single call. A name
## means one thing within its region, which is what lets every screen call its
## own subject the same word.
##
## A bell carries nothing, so nothing here holds a value and nothing here knows
## what a strike means. Whoever hears one reads the model that rang it.
##
## Striking an address nobody has hung is QUIET, by design: a model answering a
## request rings the address it was handed, and the screen that asked may have
## closed - its region dropped and the bell with it - before the answer came.
## An answer to a question nobody is waiting for lands nowhere. The record
## still shows it, so a misspelt address is visible on the run where somebody
## is looking.
##
## Every strike goes through strike(), so this is the one place that sees them
## all. Ask it to record and it writes each one to a file as it happens, with
## the line that struck it. A file rather than the console: a strike a frame
## fills a terminal in seconds, and what you want afterwards is to search it.
##
## Nobody supplies who they are. The engine already knows - get_stack() is what
## a debugger reads - so a striker carries no argument and cannot forget one.
## It is a debug build's answer: a release build has no stack to give, which is
## the right trade for a facility that is off by default.
##
## at() hands back the bell itself, which is what the chimes connect to. It is
## the only way out, and it is why nothing above the chimes is ever given one:
## something holding it could keep what a region was told to drop. A bell has
## to be hung before anything reaches for it: whoever strikes it hangs it, and
## whatever listens is built after.
##
## THE ONE NAME OF AN ADDRESS IS MADE HERE, AS THE BELL IS HUNG (reads.gd,
## hung), and the bell is told it and can be found by it. That name is what a
## set of addresses is keyed by wherever one is held - what a work read, the
## wires a listener holds - so neither a read nor a draw ever makes one.

const GLOBAL := &"global"

var _held: Dictionary = {}  # region -> { name -> the bell }
var _at: Dictionary = {}  # the one name of an address -> the bell hung there
var _striking: int = 0  # how many strikes are sounding right now, one inside another
var _record: FileAccess = null


## Hang a bell at an address. Hanging over an address already taken is refused
## rather than silently replacing what is there, because anything already
## listening would go on hearing the old one.
func register(region: StringName, name: StringName) -> void:
	if has(region, name):
		push_error("%s/%s is already hung" % [region, name])
		return
	if not _held.has(region):
		_held[region] = {}
	var bell := Bell.new(region, name, Reads.hung(region, name))
	_held[region][name] = bell
	_at[bell.at] = bell


## Whether anything is hung at that address.
func has(region: StringName, name: StringName) -> bool:
	return _held.has(region) and _held[region].has(name)


## Sound the bell at an address, if one is hung there. While it sounds, every
## listener runs in turn, and is_striking() says so.
func strike(region: StringName, name: StringName) -> void:
	var hung := has(region, name)
	if _record != null:
		_record.store_line("%s/%s%s   %s" % [region, name, "" if hung else "   (nothing hung there)", _struck_by()])
		_record.flush()
	if hung:
		_striking += 1
		_held[region][name].strike()
		_striking -= 1


## Whether a bell is sounding right now - a listener is running - counted,
## since a listener may strike another.
func is_striking() -> bool:
	return _striking > 0


## Write every strike from here on to this file. For finding out what is
## ringing something, and off until someone asks for it. Flushed line by line,
## because the run this is wanted for is usually the one that does not end well.
func record_to(path: String) -> void:
	_record = FileAccess.open(path, FileAccess.WRITE)
	if _record == null:
		push_error("cannot record strikes to %s: %s" % [path, error_string(FileAccess.get_open_error())])


## The first frame outside this folder's own plumbing - whoever actually struck
## it, rather than the doors it came through. Empty in a release build, where
## there is no stack to ask for.
func _struck_by() -> String:
	# every frame from here outwards, taking the first that is not one of ours
	for frame: Dictionary in get_stack():
		var source: String = frame["source"]
		if not source.ends_with("/belfry.gd") and not source.ends_with("/chimes.gd") \
				and not source.ends_with("/controller.gd") and not source.ends_with("/presentation.gd"):
			return "(struck at %s:%d, in %s)" % [source.get_file(), frame["line"], frame["function"]]
	return "(struck from inside the chimes)"


## The bell hung at an address, for the chimes to connect a listener to.
func at(region: StringName, name: StringName) -> Bell:
	return _held[region][name]


## The bell known by the one name of its address, or nothing: what a work
## read is a set of those names, and most of them are hung.
func bell_at(address: StringName) -> Bell:
	return _at.get(address)


## Forget a whole region: every bell hung in it.
func drop_region(region: StringName) -> void:
	# every bell of the region, no longer findable by its address either
	for bell: Bell in _held.get(region, {}).values():
		_at.erase(bell.at)
	_held.erase(region)
