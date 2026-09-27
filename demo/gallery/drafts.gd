extends RefCounted

const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Models := preload("res://demo/gallery/gallery_models.gd")

## The gallery's note drafts: state kept with the history entry, shown on
## the detail screen - a detour and Back find the note as it was left.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.


## A note being written about one thing: the words typed so far and the
## flags ticked. Kept with the history entry of the detail it belongs to,
## so a detour and Back find it, and another thing's detail starts fresh.
class Draft extends RefCounted:
	var words: String = ""
	var flags: Dictionary = {}  # flag -> true while ticked


## The drafts: answers the typing and the ticking for whichever draft is
## kept with the view the reader is on, and reads it - or none - for the
## detail screen, re-read as its facts move and on every move.
class Drafts extends Models.Shown:
	const WRITES := &"writes_a_note"
	const TICKS := &"ticks_a_flag"
	## Every action this is told.
	const COMMANDS: Array[StringName] = [WRITES, TICKS]
	const FLAG_WORDS := {"watch": "Watch", "keep": "Keep", "sell": "Sell"}
	var _driver: Driver

	func _init(chimes: Chimes, driver: Driver) -> void:
		super(chimes, {&"draft": null})
		_driver = driver

	## The draft kept with the view, or none off a detail - read with this
	## model's facts, so a note typed or a flag ticked moves its reader too.
	func get_draft() -> Variant:
		_facts.read()
		return _driver.kept(&"draft")

	## The detail filled: a draft kept with its entry, unless one is there already.
	func begun(_token: Variant) -> void:
		if _driver.kept(&"draft") == null:
			_driver.keep(&"draft", Draft.new())

	func told(action: StringName, payload: Dictionary) -> Phrase:
		var draft: Draft = _driver.kept(&"draft")
		match action:
			WRITES: draft.words = payload["line"]
			TICKS:
				if draft.flags.has(payload["flag"]):
					draft.flags.erase(payload["flag"])
				else:
					draft.flags[payload["flag"]] = true
		moved()
		return null

	## Every action this model is told.
	func answers() -> Array[StringName]:
		return COMMANDS
