extends "res://addons/gd_chime/controller.gd"

const SimulatedSight := preload("res://addons/gd_chime/components/primitives/simulated_sight.gd")

## The sight the interface is dressed for: an ordinary setting, held as a
## model, read by name and moved by a command like any other.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A reader who cannot separate red from green is not choosing a look - they
## are still in whichever look they picked - so the sight is a SECOND setting
## beside it, and the theme is built from the pair. This holds the sight
## alone; looks.gd is what puts the two together and dresses the window.
##
## The names are the simulator's own (simulated_sight.gd), so the palette a
## look is turned into and the eye a developer checks it with are the same
## four words, and nothing has to be translated between them.

const PICKS := &"picks_a_sight"
## The one action this is told.
const COMMANDS: Array[StringName] = [PICKS]
## Every sight, in the order shown: plain first, then the three deficiencies.
const NAMES := SimulatedSight.SIGHTS

var _sight := value(SimulatedSight.PLAIN)


func _init(chimes: Chimes) -> void:
	super(chimes)


func get_sight() -> StringName:
	return _sight.read()


func would(_action: StringName, payload: Dictionary) -> Phrase:
	return Phrase.of("Already dressed for that sight") if payload["sight"] == _sight.read() else null


func told(_action: StringName, payload: Dictionary) -> Phrase:
	_sight.set_value(payload["sight"])
	return null


## Every action this model is told.
func answers() -> Array[StringName]:
	return COMMANDS
