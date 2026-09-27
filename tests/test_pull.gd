extends SceneTree

## What must be true of pull to refresh (pull.gd): a list at its top drawn
## down opens what it says, armed once that stands whole; let go armed it
## refreshes, once, and stays open until the refresh lands; let go short it
## closes and does nothing; a list not at its top scrolls back instead; and
## a refresh begun any other way opens it too.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_pull.gd
##
## The touches go in as a device's do, through Input.parse_input_event; the
## refresh's far side is a stand-in answered by hand.

const Fixture := preload("res://tests/fixture.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Fetched := preload("res://addons/gd_chime/fetched.gd")
const Notifications := preload("res://addons/gd_chime/notifications.gd")
const Pull := preload("res://addons/gd_chime/components/primitives/pull.gd")
const Verdict := preload("res://tests/verdict.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")

var _verdict := Verdict.new()
var _made: Fixture
var _refresh: Fetched
var _pull: Pull
var _asked: Array = []  # every answer handed to the far side
var _stands: RefCounted  # the pull's phase, the Local handed to what says it


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	await _verdict.states(_drawn_down_at_the_top_it_opens_and_arms_once_whole)
	await _verdict.states(_let_go_armed_it_refreshes_once_and_stays_open_until_it_lands)
	await _verdict.states(_let_go_short_it_closes_and_does_nothing)
	await _verdict.states(_a_list_not_at_its_top_scrolls_back_instead)
	await _verdict.states(_a_refresh_begun_by_a_press_opens_it_too)
	quit(_verdict.deliver(get_script()))


func _standing() -> void:
	_made = Fixture.new(root, {Fetched.ASKS_AGAIN: "refresh"})
	_asked = []
	var notices := Notifications.new(_made.chimes, _made.commands, root)
	_refresh = Fetched.new(_made.chimes, func(answer: Callable) -> void: _asked.append(answer), notices, Phrase.of("The rows"))
	root.add_child(notices)
	root.add_child(_refresh)
	_made.commands.register(Chimes.GLOBAL, Fetched.ASKS_AGAIN, _refresh)
	var ui := _made.ui
	var says := func(phase: RefCounted) -> RefCounted:
		_stands = phase
		return ui.column([ui.text(phase.map(func(now: StringName) -> String: return String(now))), ui.text("the pull"), ui.text("says so")])
	var rows: Array = range(40).map(func(at: int) -> RefCounted: return ui.text("row %d" % at))
	ui.start(ui.app(&"app", [ui.pull(Fetched.ASKS_AGAIN, _refresh.loading, says, ui.column(rows)).named(&"pull")]))
	root.size = Vector2i(1920, 1080)
	# the frames the start and the first move take
	for frame: int in 6:
		await process_frame
	_pull = ui.node_named(&"pull")


func _done() -> void:
	_made.done()


func _tall() -> float:
	return (_pull.get_child(0) as Control).get_combined_minimum_size().y


func _scroll() -> ScrollContainer:
	return _pull.get_child(1)


## Where the pull stands: its phase, the model - read so wherever it is closed,
## since what says it is hidden then and draws as it is shown (presentation.gd).
func _phase() -> String:
	return String(_stands.read())


## What the indicator's words say the phase is, read while it is open and seen.
func _says() -> String:
	return (_pull.get_child(0).find_children("*", "Label", true, false)[0] as Label).text


func _touch(at: Vector2, down: bool) -> void:
	var touched := InputEventScreenTouch.new()
	touched.position = root.get_final_transform() * at
	touched.pressed = down
	Input.parse_input_event(touched)
	await process_frame


## A finger down in the list, drawn by these steps a frame each; lifted if asked.
func _drawn(steps: Array, lifts: bool) -> void:
	var at := Vector2(900, 300)
	await _touch(at, true)
	# every step, one drag a frame
	for step: Vector2 in steps:
		at += step
		var drag := InputEventScreenDrag.new()
		drag.position = root.get_final_transform() * at
		drag.relative = root.get_final_transform().basis_xform(step)
		Input.parse_input_event(drag)
		await process_frame
	if lifts:
		await _touch(at, false)


func _drawn_down_at_the_top_it_opens_and_arms_once_whole() -> void:
	await _standing()
	var tall := _tall()
	await _drawn([Vector2(0, 20), Vector2(0, 20)], false)
	await process_frame
	_verdict.check(_pull.get_open() == 20.0 and _pull.get_open() < tall and _phase() == "pulling" and _says() == "pulling", "drawn 40 down at the top, it opens by half of it, pulling, and says so: %s of %s, %s, %s" % [_pull.get_open(), tall, _phase(), _says()])
	_verdict.check((_pull.get_child(0) as Control).visible and _scroll().position.y == 20.0, "what it says shows, and the list stands below it: %s" % _scroll().position.y)
	var on := InputEventScreenDrag.new()
	on.position = root.get_final_transform() * Vector2(900, 340.0 + tall * 2.0)
	on.relative = root.get_final_transform().basis_xform(Vector2(0, tall * 2.0))
	Input.parse_input_event(on)
	await process_frame
	await process_frame
	_verdict.check(_pull.get_open() >= tall and _phase() == "armed" and _says() == "armed" and _asked.is_empty(), "drawn on until it stands whole, it is armed and says so, and nothing is asked yet: %s, %s, %s" % [_pull.get_open(), _phase(), _says()])
	await _touch(Vector2(900, 340.0 + tall * 2.0), false)
	_done()


func _let_go_armed_it_refreshes_once_and_stays_open_until_it_lands() -> void:
	await _standing()
	var tall := _tall()
	await _drawn([Vector2(0, 40), Vector2(0, tall * 3.0)], true)
	await process_frame
	_verdict.check(_asked.size() == 1 and _refresh.loading.read() and _phase() == "refreshing" and _says() == "refreshing" and _pull.get_open() == tall, "let go armed, the refresh is asked once and it stays open by what it says, refreshing: %d, %s, %s, %s" % [_asked.size(), _phase(), _says(), _pull.get_open()])
	_asked[0].call([], null)
	await process_frame
	await process_frame
	_verdict.check(_pull.get_open() == 0.0 and _phase() == "resting" and not (_pull.get_child(0) as Control).visible, "landed, it closes and rests: %s, %s" % [_pull.get_open(), _phase()])
	_done()


func _let_go_short_it_closes_and_does_nothing() -> void:
	await _standing()
	await _drawn([Vector2(0, 20), Vector2(0, 20)], true)
	await process_frame
	_verdict.check(_asked.is_empty() and _pull.get_open() == 0.0 and _phase() == "resting", "let go short, nothing is asked and it closes: %s, %s" % [_pull.get_open(), _phase()])
	_done()


func _a_list_not_at_its_top_scrolls_back_instead() -> void:
	await _standing()
	_scroll().scroll_vertical = 200
	await process_frame
	await _drawn([Vector2(0, 40), Vector2(0, 60)], true)
	await process_frame
	_verdict.check(_pull.get_open() == 0.0 and _scroll().scroll_vertical < 200 and _asked.is_empty(), "a list scrolled down is scrolled back by a finger drawn down, and nothing opens: %d" % _scroll().scroll_vertical)
	_done()


func _a_refresh_begun_by_a_press_opens_it_too() -> void:
	await _standing()
	_made.commands.dispatch(Chimes.GLOBAL, Fetched.ASKS_AGAIN, {})
	await process_frame
	await process_frame
	_verdict.check(_pull.get_open() == _tall() and _phase() == "refreshing" and _says() == "refreshing", "a refresh begun by a press opens it, refreshing, and says so as it is shown: %s, %s, %s" % [_pull.get_open(), _phase(), _says()])
	_done()
