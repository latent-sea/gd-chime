extends RefCounted

## A bell: a thing that can be struck, and carries nothing.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Struck, it sounds to whoever is listening, and that is the whole of it. It
## holds no value. A bell says "something you care about is different - go and
## read it", never what is different or what it is now; whoever hears it reads
## the model that struck it. So there is no copy anywhere that can disagree
## with the one place a fact lives, and nothing has to be kept in step.
##
## It sounds with an ordinary engine signal, which the chimes connect on a
## listener's behalf. The engine drops a connection when either end is freed,
## so nothing has to unsubscribe and nothing here has to sweep.
##
## Only the belfry makes one, and only the chimes are handed one. Everything
## else has an address.
##
## IT KNOWS WHERE IT HANGS, and is told once, as it is hung. The one name of
## the two together is what a set of addresses is keyed by - what a piece of
## work read, the wires a listener holds - and making it as a bell is hung is
## what keeps it off the path of a read, where it would be made again for
## every value read on every draw.

signal changed

var region: StringName  # the region it hangs in
var name: StringName  # what it is called there
var at: StringName  # the one name for the two together


func _init(in_region: StringName, called: StringName, address: StringName) -> void:
	region = in_region
	name = called
	at = address


func strike() -> void:
	changed.emit()
