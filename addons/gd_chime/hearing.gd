extends "interaction.gd"

const Chimes := preload("chimes.gd")

## A control's part in the chimes: its region, the bells it hangs and
## strikes, and the bells it hears by address, each arriving at heard() under
## its name - the half of a screen under presentation.gd, which draws.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A FACT IS NOT HEARD HERE. What a screen shows it reads, as values, and
## presentation.gd follows what it read; nothing lists a bell for a fact.
## Listening by address is for a bell a part of the floor rings by hand -
## a command having run, a pointer's arrival - given as it is built:
##
##     var readout := Readout.new(chimes, [[Chimes.GLOBAL, Commands.COMMAND_RAN]], &"a_screen")
##
## The connecting is done by the chimes, which record it, so what reaches this
## is answerable from one place and a whole region of connections can be
## dropped at once. This never calls connect itself.
##
## It never decides what a wake means, and never draws: heard() is the
## screen's own, and what it read as it drew is followed by presentation.gd.

## The region its connections belong to, so a screen and everything under it
## can be dropped together. Given as this is built, because connections are
## made there: a region set afterwards would leave everything declared at
## construction in the wrong one, which is silent.
var region: StringName = Chimes.GLOBAL

var _chimes: Chimes


func _init(chimes: Chimes, listening: Array, in_region: StringName) -> void:
	_chimes = chimes
	region = in_region
	listen(listening)


## Hang a bell under this name in this screen's own region - the return address
## a request carries, which goes when the screen does.
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


## Every wake arrives here and nowhere else, with the name this was listening
## under. The bell sent nothing: the name was tied to this end of the wire when
## the connection was made. Overridden by a subclass, which decides in one place
## what each one means - including that some mean nothing.
##
##     func heard(what: StringName) -> void:
##         match what:
##             Commands.COMMAND_RAN: _note_it()
func heard(_what: StringName) -> void:
	pass
