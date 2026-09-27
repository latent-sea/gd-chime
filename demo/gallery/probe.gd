extends RefCounted

const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Models := preload("res://demo/gallery/gallery_models.gd")
const More := preload("res://demo/gallery/more_models.gd")
const Notes := preload("res://demo/gallery/drafts.gd")
const Hands := preload("res://tests/hands.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")

## The stall's functionality walked and reported, so that ten arrangements
## are proved to do the same things: run by a stall started with --probe,
## and by checks/stalls_probe.py over every one - the gallery in every
## look by checks/looks_probe.py.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Every place stands. A crate opened as 2, a note written and a flag
## ticked: a detour to the graph and Back finds them, and another crate is
## fresh. The act started and stepped three times presents its moment,
## the glow walking; started again and cancelled, a move after still lands
## - the guide's way to a step no longer there is given up, not searched
## for ever. Then the second family: a setting toggled, a pace
## chosen through its overlay, a key bound, the stall named and an empty
## a supplier selected and its wider family loaded into the graph;
## name refused, the day cleared only once confirmed, and of the days
## kept the one question opened as two different rows: cancelled it throws
## away neither, confirmed it throws away the row it was opened as; the ledger sorted and
## turned, the picker narrowed by typing and a crate picked; a tie decided
## and its winner moved on; a day added to the chart.
##
## Then every place is looked at in three window shapes, for words drawn
## off the window or cut by what holds them (clipped_text.gd): an
## arrangement that reads on a wide screen and loses its words on a smaller
## one is not the same arrangement, so it is claimed here with the rest.
##
## ALL THREE SHAPES ARE JUDGED ALIKE: the base the project is written at, a
## smaller one, and a window on its end. A count of words cut on a turned
## window would be a number nobody has to act on, so it is none: a turned
## window cutting words fails the claim like any other. The window on its
## end is 9:16 - the base turned exactly - so the canvas is 1080 across,
## the narrowest a window on its end gives; a wider one only has more room.
## At every shape, every place is seen, then every pop-up raised over it
## and the moment presented: words over the rest are words too. And at each,
## nothing the reader is meant to read or press may be drawn over by
## anything else (drawn_over.gd) - judged the same way, a claim of its own.

## The window shapes every place is looked at in and judged by: the base
## the project is written at, a smaller one - the Steam Deck's - and one on its end.
const SHAPES: Array[Vector2i] = [Vector2i(1920, 1080), Vector2i(1280, 800), Vector2i(720, 1280)]

var _stall: SceneTree
var _hands: Hands
var _said: Dictionary = {}


func _init(stall: SceneTree) -> void:
	_stall = stall
	_hands = Hands.new(stall)


func _do(action: StringName, payload: Dictionary = {}) -> Phrase:
	return _hands.does(_stall.STALL, action, payload)


func _go(place: StringName, parameter: Variant = null) -> void:
	_hands.does(Chimes.GLOBAL, Driver.GO, {"place": place, "parameter": parameter})


## The walk: every claim kept by name, all said, and the stall quit on the answer.
func run() -> void:
	for wait: int in 3:
		await _stall.process_frame
	var driver: Driver = _stall.driver
	var missing: Array = _stall.places().filter(func(named: StringName) -> bool: return not _hands.has_place(named))
	_said["places"] = missing.is_empty()
	_go(_stall.DETAIL, 2)
	await _stall.process_frame
	_do(Notes.Drafts.WRITES, {"line": "half a note"})
	_do(Notes.Drafts.TICKS, {"flag": "keep"})
	_do(_stall.SHOWS_GRAPH)
	await _stall.process_frame
	var away: Variant = _stall.drafts.get_draft()
	_do(_stall.GOES_BACK)
	await _stall.process_frame
	var back: Variant = _stall.drafts.get_draft()
	_said["kept"] = away == null and driver.get_parameter(_stall.DETAIL) == 2 and back != null and back.words == "half a note" and back.flags.has("keep")
	_go(_stall.DETAIL, 3)
	await _stall.process_frame
	_said["fresh"] = _stall.drafts.get_draft() != null and _stall.drafts.get_draft().words == ""
	_do(Models.Act.STARTS)
	_said["glows_step"] = _stall.prompts.get_glowing() == Models.Act.TAKES_A_STEP
	for step: int in 3:
		_do(Models.Act.TAKES_A_STEP)
	_said["acted"] = _stall.act.get_presented() and _stall.prompts.get_glowing() == &""
	_do(Models.Act.CARRIES_ON)
	_do(Models.Act.STARTS)
	_do(Models.Act.CANCELS)
	_go(_stall.READOUTS)
	await _stall.process_frame
	_said["cancelled"] = not _stall.act.get_presented() and driver.get_top().has(_stall.READOUTS)
	await _settings()
	ledger()
	_rest()
	_said.merge(await _stall.claims())
	await _whole()
	var failed: Array = _said.keys().filter(func(claim: String) -> bool: return not _said[claim])
	print("PROBE %s missing=%s" % [_said, missing])
	print("PROBE " + ("OK" if failed.is_empty() else "FAILED %s" % [failed]))
	_stall.quit(0 if failed.is_empty() else 1)


func _settings() -> void:
	var prefs: More.Prefs = _stall.prefs
	var driver: Driver = _stall.driver
	_do(More.Prefs.TURNS_SOUND, {"on": false})
	_said["toggled"] = prefs.get_sound() == false
	_go(_stall.SETTINGS)
	await _stall.process_frame
	_go(_stall.pop_ups()[0][0])
	await _stall.process_frame
	var raised: bool = driver.get_top() == [_stall.pop_ups()[0][0]]
	_hands.does(_stall.pop_ups()[0][0], More.Prefs.PICKS_PACE, {"value": &"brisk"})
	await _stall.process_frame
	_said["chosen"] = raised and prefs.get_pace() == &"brisk" and not driver.is_raised()
	_do(More.Prefs.BINDS_CALL, {"words": "J"})
	_said["bound"] = prefs.get_call_key() == "J"
	_do(More.Prefs.NAMES_STALL, {"line": "the north stall"})
	_do(More.Prefs.NAMES_STALL, {"line": "  "})
	_said["named"] = prefs.get_title() == "the north stall" and prefs.get_refusal() != null
	_go(_stall.more.clearing.get_place())
	await _stall.process_frame
	var asked: bool = driver.get_top() == [_stall.more.clearing.get_place()] and prefs.get_day() != null
	_hands.does(_stall.more.clearing.get_place(), More.Prefs.CLEARS_DAY, {})
	await _stall.process_frame
	_said["confirmed"] = asked and prefs.get_day() == null and not driver.is_raised()
	var kept: More.Kept = _stall.kept
	_go(_stall.more.dropping.get_place(), 3)
	await _stall.process_frame
	var as_three: bool = driver.get_parameter(_stall.more.dropping.get_place()) == 3
	_hands.does(Chimes.GLOBAL, Driver.GOES_BACK, {})
	await _stall.process_frame
	var spared: bool = kept.get_days().size() == 3
	_go(_stall.more.dropping.get_place(), 2)
	await _stall.process_frame
	_hands.does(_stall.more.dropping.get_place(), More.Kept.DROPS, {"id": driver.get_parameter(_stall.more.dropping.get_place())})
	_said["row_confirmed"] = as_three and spared and kept.get_days().map(func(day: Dictionary) -> int: return day["id"]) == [1, 3]


func ledger() -> void:
	var ledger: More.Ledger = _stall.ledger
	_do(More.Ledger.SORTS, {"column": "won"})
	var up: Array = ledger.get_rows()
	_do(More.Ledger.SORTS, {"column": "won"})
	var down: Array = ledger.get_rows()
	_said["sorted"] = up.front()["won"] < up.back()["won"] and down.front()["won"] > down.back()["won"] and ledger.get_sort() == {"column": "won", "ascending": false}
	var all: int = ledger.narrowing.get_count()
	_do(More.Ledger.NARROWS_CRATES, {"line": "pl"})
	var few: Array = ledger.narrowing.get_options()
	_said["narrowed"] = few.size() < all and few.all(func(option: Dictionary) -> bool: return String(option["words"]).contains("pl"))
	_do(More.Ledger.PICKS_CRATE, {"value": few.front()["value"]})
	_said["picked"] = str(ledger.get_picked()).contains(str(few.front()["value"]))
	_said["grouped"] = ledger.get_sections().size() == 3


func _rest() -> void:
	var knockout: More.Knockout = _stall.knockout
	_do(More.Knockout.DECIDES)
	var rounds: Array = knockout.get_rounds()
	_said["decided"] = rounds[0]["ties"][0]["winner"] == 1 and rounds[1]["ties"][0]["a"] != null
	var takings: More.Takings = _stall.takings
	var before: int = takings.get_chart()["series"][0]["points"].size()
	_do(More.Takings.ADDS_DAY)
	_said["extended"] = takings.get_chart()["series"][0]["points"].size() == before + 1
	var family: Models.Family = _stall.family
	var known: int = family.get_picture()["nodes"].size()
	_hands.does(Chimes.GLOBAL, Models.Family.PICKS, {"picked": 2})
	_hands.does(Chimes.GLOBAL, Models.Family.EXPANDS, {"id": family.get_selected()["id"]})
	_said["expanded"] = family.get_selected()["name"] == "bo" and family.get_picture()["nodes"].size() == known + 1


## Every place at every shape, judged for words cut off and for anything
## drawn over anything else. The clock is held still and then run out, so
## that everything already on its way is at its end and nothing is judged
## where it was only passing through; and each shape is laid out over three
## frames before it is read, since the window resize reaches the layouts
## through their rects and the shape turns the base under them.
func _whole() -> void:
	var cut: Array[String] = []
	var over: Array[String] = []
	_stall.ui.motion.still = true
	_stall.ui.motion.step(10.0)
	# every shape, each judged alike
	for shape: Vector2i in SHAPES:
		_stall.root.size = shape
		# every place the stall has, seen at this shape
		for place: StringName in _stall.places():
			_go(place)
			await _hands.judged(place, shape, cut, over)
		# every pop-up raised over the last place, each as the row it was opened for where it asks about one
		for overlay: Array in _stall.pop_ups():
			_go(overlay[0], overlay[1])
			await _hands.judged(overlay[0], shape, cut, over)
			_hands.does(Chimes.GLOBAL, Driver.GOES_BACK, {})
		# the moment presented over it all: the act run to its end
		_do(Models.Act.STARTS)
		for step: int in 3:
			_do(Models.Act.TAKES_A_STEP)
		await _hands.judged(&"the moment", shape, cut, over)
		_do(Models.Act.CARRIES_ON)
	_said["no_clipped_text"] = cut.is_empty()
	_said["nothing_drawn_over"] = over.is_empty()
	_said["words_stand_out"] = _hands.get_faint().is_empty()
	_hands.say_every(cut, over)
