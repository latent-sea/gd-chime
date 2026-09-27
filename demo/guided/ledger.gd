extends RefCounted

const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Controller := preload("res://addons/gd_chime/controller.gd")

## The guided demo's ledger: the models behind its two tabs, and the names
## of the actions and the places.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Every move is the driver's (driver.gd): a link carries where it goes, and
## the driver arrives, raises or goes back, refusing what would change
## nothing. So there are no doors here: the coins are the coins tab's own
## and the notes the notes tab's, each registered in its tab's region, and
## the names are what the demo and its declarations share.

const OPENS := &"opens_the_ledger"
const SHOWS_COINS := &"shows_the_coins"
const SHOWS_NOTES := &"shows_the_notes"
const COUNTS := &"counts_a_coin"
const JOTS := &"jots_a_note"
const ZOOMS := &"zooms_in_on_a_coin"
const GOES_BACK := &"goes_back"
const APP := &"app"
const CONTENT := &"content"
const HOME := &"home"
const LEDGER := &"ledger"
const COINS := &"coins"
const NOTES := &"notes"


## The coins tab's own model: counts the coins, a value.
class Coins extends Controller:
	var _coins := value(0)

	func _init(chimes: Chimes) -> void:
		super(chimes, [], COINS)

	func get_coins() -> int:
		return _coins.read()

	func told(_action: StringName, _payload: Dictionary) -> Phrase:
		_coins.set_value(_coins.read() + 1)
		return null

	## Every action this is told: counting a coin.
	func answers() -> Array[StringName]:
		return [COUNTS]


## The notes tab's own model: keeps how many notes were jotted, a value.
class Notes extends Controller:
	var _notes := value(0)

	func _init(chimes: Chimes) -> void:
		super(chimes, [], NOTES)

	func get_notes() -> int:
		return _notes.read()

	func told(_action: StringName, _payload: Dictionary) -> Phrase:
		_notes.set_value(_notes.read() + 1)
		return null

	## Every action this is told: jotting a note.
	func answers() -> Array[StringName]:
		return [JOTS]

