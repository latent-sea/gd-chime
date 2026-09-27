extends RefCounted

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")
const Insurance := preload("res://demo/apps/form/insurance.gd")
const Hands := preload("res://tests/hands.gd")

## Application 3 walked and judged, run by it with --probe and by
## checks/stalls_probe.py: everything the brief asks of a multi-step form,
## done through the doors a reader's hands use, then every place looked at in
## three window shapes.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Walked: a name typed; a short choice picked in its overlay; a day typed
## wrong and its message shown once its step is left by Ctrl+Page Down; a
## sector picked and an activity found by typing, then the sector changed
## under it; a number stepped and a sum typed; the vehicle section shown,
## answered, hidden and shown again with its answer; a day picked from the
## calendar a month on; a file picked and one refused; sending with
## problems taking the focus to the first, a summary's link and a review's
## change each landing on their question; the draft saved by the pad, a
## change asked about on leaving and discarded; the draft read back by a
## fresh form; and the form sent. Judged: the start, a step with messages,
## the section, the review, the calendar, a choice and the leave question at
## 1920x1080, 1280x800 and 720x1280 (clipped_text.gd, drawn_over.gd).

const SHAPES: Array[Vector2i] = [Vector2i(1920, 1080), Vector2i(1280, 800), Vector2i(720, 1280)]
const ACCOUNTS := "user://form_probe_accounts.pdf"
const NOTES := "user://form_probe_notes.txt"

var _app: SceneTree
var _hands: Hands
var _said: Dictionary = {}


func _init(app: SceneTree) -> void:
	_app = app
	_hands = Hands.new(app)


func _do(action: StringName, payload: Dictionary = {}) -> GdChime.Phrase:
	return _app.commands.dispatch(GdChime.Chimes.GLOBAL, action, payload)


## The pop-up a choice question opens: where its step says its press goes.
func _choosing(key: StringName) -> StringName:
	return _app.driver.goes_to(_app.form.get_question(key)["step"], GdChime.FormActions.chooses(key))


func _question(key: StringName) -> Control:
	return _app.ui.node_named(GdChime.FormField.named(key))


## Whether a question stands on the screen: a section's are built only while it is shown.
func _shown(key: StringName) -> bool:
	return is_instance_valid(_question(key)) and _question(key).is_visible_in_tree()


func _held(key: StringName) -> Variant:
	return _app.form.get_answers().get(key)


func _top() -> Array:
	return _app.driver.get_top()


## The walk: every claim, then every shape; said, and the application quit on the answer.
func run() -> void:
	await _hands.frames(4)
	_app.root.size = SHAPES[0]
	await _hands.frames(4)
	_said["places"] = [_app.START, _app.APPLICATION, _app.SENT, _app.leaving.get_place(), _app.calendar_sheet.get_place(), _choosing(&"structure")].all(func(named: StringName) -> bool: return _hands.has_place(named))
	await _hands.press(_app.OPENS)
	await _hands.types_into(_question(&"legal_name"), "Crate & Barrel Fruit Ltd")
	_said["typed"] = _top().has(Insurance.COMPANY) and _held(&"legal_name") == "Crate & Barrel Fruit Ltd"
	await _hands.press(GdChime.FormActions.chooses(&"structure"))
	var raised: bool = _top() == [_choosing(&"structure")]
	await _hands.press(GdChime.FormActions.answering(&"structure"), {carrying = {"value": "limited"}})
	_said["combo"] = raised and not _app.driver.is_raised() and _held(&"structure") == "limited"
	await _hands.types_into(_question(&"founded"), "31/02/2020")
	var quiet: bool = _hands.words(_question(&"founded")).all(func(words: String) -> bool: return not words.contains("Type a date"))
	await _hands.key(KEY_PAGEDOWN, "", [&"ctrl"])
	# the step left is seen out, so its words are read within it
	_said["messages"] = quiet and _held(&"founded") == "31/02/2020" and _top().has(Insurance.ACTIVITIES) and _hands.words_within(_question(&"founded")).has("! Type a date as DD/MM/YYYY")
	await _dependent()
	await _numbers_and_section()
	await _calendar_and_files()
	await _sending()
	await _draft_and_leaving()
	await _whole()
	await _sent()
	var failed: Array = _said.keys().filter(func(claim: String) -> bool: return not _said[claim])
	print("PROBE %s" % [_said])
	print("PROBE " + ("OK" if failed.is_empty() else "FAILED %s" % [failed]))
	_app.quit(0 if failed.is_empty() else 1)


## A sector picked in its overlay; an activity found by typing a few letters
## of it and picked; the sector changed, and the activity asked for again.
func _dependent() -> void:
	await _hands.press(GdChime.FormActions.chooses(&"sector"))
	await _hands.press(GdChime.FormActions.answering(&"sector"), {carrying = {"value": "construction"}})
	await _hands.press(GdChime.FormActions.chooses(&"activity"))
	await _hands.types_into(_hands.place(_choosing(&"activity")), "roo")
	var found: Array = _app.form.narrowing(&"activity").get_options()
	await _hands.press(GdChime.FormActions.answering(&"activity"), {carrying = {"value": "roofer"}})
	var picked: bool = found.size() == 1 and _held(&"activity") == "roofer" and not _app.driver.is_raised()
	_do(GdChime.FormActions.answering(&"sector"), {"value": "retail"})
	var again: bool = _app.form.get_errors().any(func(error: Dictionary) -> bool: return error["value"] == &"activity" and str(error["says"]).begins_with("Choose again"))
	_do(GdChime.FormActions.answering(&"sector"), {"value": "construction"})
	_said["dependent_autocomplete"] = picked and again and _held(&"activity") == "roofer"


## A number stepped up twice and a sum typed; the vehicle section shown by a
## yes, answered, hidden by a no with its answer kept, and shown again.
func _numbers_and_section() -> void:
	await _hands.press(GdChime.FormActions.SHOWS_STEP, {carrying = {"value": Insurance.EMPLOYEES}})
	await _hands.press(GdChime.FormActions.answering(&"staff"), {carrying = {"value": 1.0}})
	await _hands.press(GdChime.FormActions.answering(&"staff"), {carrying = {"value": 2.0}})
	await _hands.press(GdChime.FormActions.SHOWS_STEP, {carrying = {"value": Insurance.ACTIVITIES}})
	await _hands.types_into(_question(&"turnover"), "12,500")
	_said["numbers"] = _held(&"staff") == 2.0 and _held(&"turnover") == "12,500" and _app.form.value_of(&"turnover") == 12500.0
	await _hands.press(GdChime.FormActions.SHOWS_STEP, {carrying = {"value": Insurance.ASSETS}})
	var hidden: bool = not _shown(&"vehicle_count")
	await _hands.press(GdChime.FormActions.answering(&"vehicles"), {carrying = {"value": true}})
	var shown: bool = _shown(&"vehicle_count")
	await _hands.press(GdChime.FormActions.answering(&"vehicle_count"), {carrying = {"value": 2.0}})
	await _hands.press(GdChime.FormActions.answering(&"vehicles"), {carrying = {"value": false}})
	var kept: bool = not _shown(&"vehicle_count") and _held(&"vehicle_count") == 2.0
	await _hands.press(GdChime.FormActions.answering(&"vehicles"), {carrying = {"value": true}})
	_said["conditional_section"] = hidden and shown and kept and _shown(&"vehicle_count") and _hands.focus_under(_app.root)


## The calendar opened from the cover's start, a month turned by its key, the
## first of that month picked; a PDF picked, and a text file refused on its press.
func _calendar_and_files() -> void:
	await _hands.press(GdChime.FormActions.SHOWS_STEP, {carrying = {"value": Insurance.COVERAGE}})
	_hands.press_of(GdChime.Calendar.OPENS).grab_focus()
	await _hands.press(GdChime.Calendar.OPENS)
	var on_day: bool = _app.ui.root.get_viewport().gui_get_focus_owner() == _hands.press_of(GdChime.Calendar.PICKS, {carrying = {"value": _app.calendar.get_focused()}})
	await _hands.key(KEY_PAGEDOWN)
	var first: int = _app.calendar.get_focused()
	await _hands.press(GdChime.Calendar.PICKS, {carrying = {"value": first}})
	_said["calendar"] = on_day and GdChime.Dates.parts_of(first)["month"] != GdChime.Dates.parts_of(GdChime.Dates.today())["month"] and _held(&"cover_start") == GdChime.Dates.typed(first) and not _app.driver.is_raised()
	await _hands.press(GdChime.FormActions.SHOWS_STEP, {carrying = {"value": Insurance.DOCUMENTS}})
	# two files on the disk: a PDF of 2,000 bytes and a text file
	for path: String in [ACCOUNTS, NOTES]:
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string("x".repeat(2000))
		file.close()
	_hands.press_of(GdChime.FormActions.answering(&"accounts")).picked(ProjectSettings.globalize_path(ACCOUNTS))
	var certificate := _hands.press_of(GdChime.FormActions.answering(&"certificate"))
	certificate.picked(ProjectSettings.globalize_path(NOTES))
	await _hands.frames()
	_said["file_upload"] = _held(&"accounts") == {"name": "form_probe_accounts.pdf", "size": 2000, "kind": "pdf"} and _held(&"certificate") == null and str(certificate.get_refusal()) == "Only pdf, png, jpg files are taken" and _hands.words(certificate).has("Only pdf, png, jpg files are taken")


## Send with problems: the focus on the first one's question; a summary's
## link and a review's change each landing on their question.
func _sending() -> void:
	await _hands.press(GdChime.FormActions.SHOWS_STEP, {carrying = {"value": Insurance.REVIEW}})
	await _hands.press(GdChime.FormActions.SENDS)
	var first: Dictionary = _app.form.get_errors()[0]
	var landed: bool = _top().has(first["step"]) and _hands.focus_under(_question(first["value"]))
	_said["send_takes_the_reader_to_the_first_error"] = landed and str(_app.commands.get_last()["answer"]).ends_with("need attention") and not _app.form.get_sent()
	await _hands.press(GdChime.FormActions.SHOWS_STEP, {carrying = {"value": Insurance.REVIEW}})
	await _hands.press(GdChime.FormActions.SHOWS_QUESTION, {carrying = {"value": &"email"}})
	var linked: bool = _top().has(Insurance.COMPANY) and _hands.focus_under(_question(&"email"))
	await _hands.press(GdChime.FormActions.SHOWS_STEP, {carrying = {"value": Insurance.REVIEW}})
	await _hands.press(GdChime.FormActions.SHOWS_QUESTION, {carrying = {"value": &"turnover"}})
	_said["summary_and_review_links"] = linked and _top().has(Insurance.ACTIVITIES) and _hands.focus_under(_question(&"turnover"))


## The draft saved by the pad's Y; a change, and closing asks; staying keeps
## it; closing again and leaving without saving puts the draft back; a fresh
## form reads the draft back from the file.
func _draft_and_leaving() -> void:
	await _hands.pad(JOY_BUTTON_Y)
	var saved: bool = not _app.form.get_dirty() and _app.notifications.get_standing().size() >= 1
	await _hands.types_into(_question(&"turnover"), "99")
	await _hands.press(GdChime.FormActions.CLOSES)
	var asked: bool = _top() == [_app.leaving.get_place()]
	await _hands.press(_app.ui.CLOSES)
	var stayed: bool = _top().has(Insurance.ACTIVITIES) and _held(&"turnover") == "99"
	await _hands.press(GdChime.FormActions.CLOSES)
	await _hands.press(GdChime.FormActions.LEAVES_WITHOUT_SAVING)
	_said["leave_guard_and_dirty"] = saved and asked and stayed and _top().has(_app.START) and _held(&"turnover") == "12,500" and not _app.form.get_dirty()
	_app.settings.write()
	var bells: GdChime.Chimes = GdChime.Chimes.new(GdChime.Belfry.new())
	# the one bell of the driver's the form hears, hung where a fresh form can hear it
	bells.register(GdChime.Chimes.GLOBAL, GdChime.Driver.NAVIGATED)
	var fresh := GdChime.Form.new(bells, _app.commands, Insurance.questions(), Insurance.steps(), _app.SENT)
	var file := GdChime.SettingsFile.new(bells, _app.settings.get_file_path())
	file.keep("draft", fresh)
	# the two compared as the reader reads them: a number read back off the disk is a float where a pick made it a whole number
	_said["draft_restored"] = fresh.get_answers().size() == _app.form.get_answers().size() and str(fresh.get_review()) == str(_app.form.get_review()) and fresh.get_drafted()
	file.free()
	fresh.free()


## Every problem answered, and sending takes the reader to the sent page, the draft let go.
func _sent() -> void:
	var day: String = GdChime.Dates.typed(GdChime.Dates.today() + 3)
	# every answer the form still needs, as its controls would carry them
	for answer: Array in [[&"company_number", "AB123456"], [&"founded", "01/02/2020"], [&"email", "orders@crateandbarrel.example"], [&"sells_online", true], [&"hazardous", false], [&"heights", false], [&"premises", "leased"], [&"contents", "40,000"], [&"vehicle_kind", "vans"], [&"vehicle_value", "60,000"], [&"young_drivers", false], [&"claimed", false], [&"cover_start", day], [&"liability", "2m"], [&"employers", true], [&"excess", "500"], [&"payroll", "58,000"]]:
		_do(GdChime.FormActions.answering(answer[0]), {"value": answer[1]} if not answer[1] is String else {"line": answer[1]})
	await _hands.press(GdChime.FormActions.SHOWS_STEP, {carrying = {"value": Insurance.REVIEW}})
	var errors: Array = _app.form.get_errors()
	await _hands.press(GdChime.FormActions.SENDS)
	_said["sent"] = errors.is_empty() and _app.form.get_sent() and _top().has(_app.SENT) and _app.form.saved() == {"answers": {}}
	if not errors.is_empty():
		print("PROBE STILL WRONG %s" % [errors])


## Every shape: each place worth seeing, judged for words cut and things drawn over.
func _whole() -> void:
	var cut: Array = []
	var over: Array = []
	# every shape, each judged alike
	for shape: Vector2i in SHAPES:
		_app.root.size = shape
		_do(GdChime.Driver.GO, {"place": _app.START})
		await _hands.judged("the start", shape, cut, over)
		_do(GdChime.Driver.GO, {"place": Insurance.COMPANY})
		await _hands.judged("the company step with its messages", shape, cut, over)
		_do(GdChime.Driver.GO, {"place": Insurance.ASSETS})
		await _hands.judged("the assets step with its section", shape, cut, over)
		_do(GdChime.Driver.GO, {"place": Insurance.REVIEW})
		await _hands.judged("the review", shape, cut, over)
		_do(GdChime.Driver.GO, {"place": _app.calendar_sheet.get_place(), "parameter": {"action": GdChime.FormActions.answering(&"founded"), "day": null}})
		await _hands.judged("the calendar", shape, cut, over)
		_do(GdChime.Driver.GOES_BACK)
		_do(GdChime.Driver.GO, {"place": _choosing(&"premises")})
		await _hands.judged("a choice", shape, cut, over)
		_do(GdChime.Driver.GOES_BACK)
		# a change unsaved, so there is a question to ask, let go once it is seen
		_do(GdChime.FormActions.answering(&"turnover"), {"line": "13,000"})
		_do(GdChime.Driver.GO, {"place": _app.leaving.get_place(), "parameter": {"region": GdChime.Chimes.GLOBAL, "action": GdChime.FormActions.CLOSES, "payload": {}, "asks": _app.form.would(GdChime.Driver.LEAVES, {})}})
		await _hands.judged("the leave question", shape, cut, over)
		_do(GdChime.Driver.GOES_BACK)
		_do(GdChime.FormActions.LEAVES_WITHOUT_SAVING)
	_said["no_clipped_text"] = cut.is_empty()
	_said["nothing_drawn_over"] = over.is_empty()
	_said["words_stand_out"] = _hands.get_faint().is_empty()
	_hands.say_every(cut, over)
