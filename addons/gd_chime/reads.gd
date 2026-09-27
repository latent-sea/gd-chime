extends RefCounted

## What a piece of work read: the address of every bell that what it read
## moves on, noted as it is read, so whoever did the work listens to
## exactly those.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A value, read, notes the bell its model rings (value.gd); so does a read
## of anything else that moves on a bell of its own - where the reader is,
## which the driver rings for. Whoever is about to work begins, works, and
## ends with the addresses read in between, each once, in the order first
## read; the chimes wire the worker to exactly those (chimes.gd, follow)
## and the next piece of work replaces them. Nobody lists what to listen to,
## so nothing listed can be forgotten, and a read the work stopped making is
## no longer heard.
##
## AN ADDRESS IS ONE StringName, MADE AS THE BELL IS HUNG (hung) and kept
## here under the region and the name it was made from. A read finds it
## rather than making it, and what a work read is collected into a Dictionary
## used as a SET, keyed by that one name: noting a read is two lookups and no
## allocation, and what was read can be compared with what is already wired
## as one set against another. This is the hottest path in the folder - every
## value read on every draw of every control comes through note - and it was
## an Array searched with has([region, name]), which allocated a pair per read
## and compared it against every pair already there.
##
## Work nests - a control built while another draws, a model worked out as
## a control reads it - so what is being noted is a stack, and a read lands
## in the innermost work alone: the outer work did not read it. A read made
## while no work is being noted is noted nowhere.
##
## Static, because a read cannot say who is reading: a getter is called from
## anywhere with nothing naming its reader. THE MAIN THREAD ONLY, SAID OUT
## LOUD AND NOTED NOWHERE: a job in the background reads nothing bound, and
## a read from one would land in whatever the main thread happens to be
## working out at that moment, wiring that listener to this bell.
##
## HOW OFTEN WHAT A BELL RINGS FOR HAS MOVED IS COUNTED PER ADDRESS (moved),
## which is how work kept with what it read lets itself go: the count is
## taken as the work is done and compared as it is next read, so a reading is
## worked out afresh the moment anything it read moves. Nobody empties it,
## so no writer can forget to - and the count is taken as a value is SET,
## ahead of the ring its bell defers to the end of the frame, because what a
## reading came to is read the instant it is asked for and a frame late would
## be wrong.

## The thread every bound read must come from, asked for once: note() is the
## hottest call in the folder.
static var _main_thread: int = OS.get_main_thread_id()

static var _open: Array = []  # the set of addresses read so far by each piece of work begun, innermost last
static var _addresses: Dictionary = {}  # region -> name -> the one StringName that address is known by
static var _moves: Dictionary = {}  # address -> how often what the bell there rings for has moved


## Work is beginning: what it reads is noted for it.
static func begin() -> void:
	_open.append({})


## Work done with what it read noted, handing back the set of addresses: one
## reach into this script on the hot path rather than the two that begin, work
## and end would take, and a draw is the caller.
static func tracked(work: Callable) -> Dictionary:
	_open.append({})
	work.call()
	return _open.pop_back()


## The one name the address of a bell hung at this region and name is known
## by, made now if it has never been made. Called as the bell is hung, so a
## read finds it; called again by a read of an address nothing is hung at,
## which is a real case - a region dropped while something still reads into it.
static func hung(region: StringName, bell: StringName) -> StringName:
	var named: Variant = _addresses.get(region)
	if named == null:
		named = {}
		_addresses[region] = named
	var at: Variant = named.get(bell)
	if at == null:
		at = StringName("%s/%s" % [region, bell])
		named[bell] = at
	return at


## A read of something that moves on the bell known by this one name: what a
## value's own bell notes, and the hottest call in the folder. It carries the
## whole of the guard rather than standing on note(): a call into another
## script is the dearest thing on this path - measured, and dearer than the
## work it would save - so the two doors each say the same three lines.
static func note_at(at: StringName) -> void:
	if OS.get_thread_caller_id() != _main_thread:
		push_error("%s was read off the main thread: a job in the background reads nothing bound, and this read would be noted for whatever the main thread is working out" % at)
		return
	if _open.is_empty():
		return
	_open[-1][at] = true


## A read of something that moves on the bell at this address, named as the
## region and the name: for a reader that has no address of its own to hold.
static func note(region: StringName, bell: StringName) -> void:
	if OS.get_thread_caller_id() != _main_thread:
		push_error("%s/%s was read off the main thread: a job in the background reads nothing bound, and this read would be noted for whatever the main thread is working out" % [region, bell])
		return
	if _open.is_empty():
		return
	_open[-1][hung(region, bell)] = true


## The work is done: the set of addresses it read, each once, in the order
## first read.
static func end() -> Dictionary:
	return _open.pop_back()


## What the bell at this address rings for has moved: whatever was kept with
## a read of it is worked out afresh as it is next read.
static func moved(region: StringName, bell: StringName) -> void:
	var at := hung(region, bell)
	_moves[at] = _moves.get(at, 0) + 1


## The region is gone, and its bells with it: what moved in it is forgotten,
## and so are the addresses it was made of, which is what keeps this from
## growing for ever as models come and go.
static func forget(region: StringName) -> void:
	# every address made in that region, its count of moves dropped with it
	for at: StringName in _addresses.get(region, {}).values():
		_moves.erase(at)
	_addresses.erase(region)


## Work done apart from the work around it: what it reads is noted for
## nothing. For what a follower DOES once it has read what it follows -
## sets values, asks for rows - so its own doing is never among what it
## follows, which would have it answer itself for ever.
static func apart(work: Callable) -> void:
	tracked(work)


## Work done apart from the work around it, and what it came to noted at
## this one address in its place: a handle's read - an item found by reading
## the list holding it, which is not what a piece of that list follows. One
## reach into this script where begin, work, end and note were three, on
## the path of every read of every handle, which a row's every cell makes.
static func apart_at(work: Callable, at: StringName) -> Variant:
	_open.append({})
	var answer: Variant = work.call()
	_open.pop_back()
	note_at(at)
	return answer


## Work done once and kept with what it read, for a reading worked out once
## per change however often it is read: held is empty until it is worked out,
## then [what it came to, each address it read beside the count its moves
## stood at], and either way those addresses are noted again, so whoever
## reads it follows what the work read as though it had done the work itself.
## Anything it read having moved since, what it came to is let go here, where
## what it read is known - never by hand in whoever writes.
static func worked(held: Array, work: Callable) -> Variant:
	if not held.is_empty():
		# every address the work read, against what its moves stand at now: one of them moved, what it came to is gone
		for kept: Array in held[1]:
			if kept[1] != _moves.get(kept[0], 0):
				held.clear()
				break
	if held.is_empty():
		begin()
		held.append(work.call())
		var read: Dictionary = end()
		held.append([])
		# every address the work read, kept beside how often what it rings for has moved so far
		for at: StringName in read:
			held[1].append([at, _moves.get(at, 0)])
	if _open.is_empty():
		return held[0]
	# every address the work read, noted as though the reader had read it
	for kept: Array in held[1]:
		_open[-1][kept[0]] = true
	return held[0]
