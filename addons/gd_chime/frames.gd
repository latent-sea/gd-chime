extends "controller.gd"

## The frames: a bell rung once every frame the engine runs, for a value
## that is read again every frame - the time, a count the engine keeps.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A value read every frame (ui.every_frame) notes this bell as it is read,
## so whatever shows it is drawn again each frame and nothing else is. What
## the value says is worked out by whoever reads it; nothing is held here,
## and the bell carries nothing, as every bell.
##
## Made with the builder and put under the root with the rest of the floor,
## it runs only from the first time such a value is asked for: an
## application that reads nothing every frame has nothing running every frame.

const FRAME_PASSED := &"frame_passed"

var _asked: bool = false  # whether a value read every frame has been asked for


func _init(chimes: Chimes) -> void:
	super(chimes, [], Chimes.GLOBAL)
	register_bell(FRAME_PASSED)


## A value read every frame was asked for: the bell rings from now on.
func run() -> void:
	_asked = true
	set_process(true)


## Entering the tree switches processing on for a script with _process, so
## whether it runs is said again here.
func _ready() -> void:
	set_process(_asked)


func _process(_delta: float) -> void:
	strike(region, FRAME_PASSED)
