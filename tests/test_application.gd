extends "res://addons/gd_chime/application.gd"

## What must be true of an application: the standard wiring done once, the
## application's answers taken.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_application.gd
##
## This test is an application: it answers the base's questions and, once
## the tree has entered, checks that the look is on the app's canvas, dressed for
## the script of the language on, the register
## has what it declared, the prompts have its sources and answer their own
## muting from anywhere, the driver, the door and the prompts are under the
## canvas, the app it described is the app and arrived at, the pop-up it
## described on a press is a place beside it, and reduced motion is
## answered from anywhere.
##
## AND THAT EVERY MODEL STANDS ITSELF UP: one handed to model() is beside
## the app and told what it answers from anywhere; one handed to a screen is
## told what it answers THERE and nowhere else, so a second screen's model
## of the same actions never takes its presses; and the frame budget and the
## job pool are the application's own, made once.

const Verdict := preload("res://tests/verdict.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Faint := preload("res://addons/gd_chime/faint_words.gd")

## What the two screens' models answer, each in its own place.
const COUNTS := &"counts_a_coin"
const JOTS := &"jots_a_note"


## A model that says what it answers and counts what it was told.
class Counter extends Controller:
	var told_of: Array[StringName] = []

	func answers() -> Array[StringName]:
		return [COUNTS]

	func told(action: StringName, _payload: Dictionary) -> Phrase:
		told_of.append(action)
		return null


var _verdict := Verdict.new()
var _look := Themes.new(Themes.NEUTRAL)
var _latin := SystemFont.new()
var _zoom: Desc  # the pop-up the app's press opens
var _of_the_app: Counter  # stood up with model(), answering from anywhere
var _here: Counter  # handed to the first screen, answering there
var _there: Counter  # handed to the second, answering there


## The look answered gives a font for Latin and for Japanese and wears
## neither yet: whoever puts it on dresses it for the language on.
func look() -> Theme:
	Look.fonts(_look, {Look.LATIN: _latin, "Jpan": SystemFont.new()})
	return _look


func sources() -> Array[StringName]:
	return [&"guide"]


func declare(register: Actions) -> void:
	register.declare_all({&"saves": ["save"], &"zooms": ["zoom"], COUNTS: ["count a coin"], JOTS: ["jot a note"]})


## The app, a pop-up described where it is used - on the press opening it -
## and three models: one of the application, and one on each of two screens.
func describe() -> Desc:
	_zoom = ui.pop_up(&"zoom", func(_which: Bound) -> Desc: return ui.column([ui.pressable(COUNTS), ui.pressable(ui.CLOSES, {}, [], &"Pressable").goes_to(Driver.BACK)]))
	_of_the_app = model(Counter.new(chimes)) as Counter
	_here = Counter.new(chimes)
	_there = Counter.new(chimes)
	var here := ui.screen(&"here", [ui.pressable(COUNTS), ui.pressable(JOTS)], _here)
	var there := ui.screen(&"there", [ui.pressable(COUNTS)], _there)
	return ui.app(&"app", [ui.pressable(&"saves").named(&"save"), ui.pressable(&"zooms").opens(_zoom), ui.stack([here, there])])


func _init() -> void:
	super()
	await process_frame
	await process_frame
	await process_frame
	await _verdict.states(_it_wires_the_standard_pieces_and_starts_what_the_application_described)
	await _verdict.states(_a_model_stands_itself_up_where_it_was_handed_in_and_nowhere_else)
	quit(_verdict.deliver(get_script()))


func _it_wires_the_standard_pieces_and_starts_what_the_application_described() -> void:
	_verdict.check(app.canvas.theme == _look and _look.default_font == _latin, "the look it answered is on the app's canvas, dressed for the language on - English, in the look's Latin font: %s" % [_look.default_font])
	_verdict.check(actions.has(&"saves") and actions.get_words(&"zooms") == "zoom" and actions.get_words(ui.CLOSES) == "Close", "the register holds what it declared, and every pop-up's way out, which the builder declares")
	var ground := _look.get_color(&"ground", Themes.LOOK)
	_verdict.check(app.canvas.get_drawn().size() == 1 and (app.canvas.get_drawn()[0] as StyleBoxFlat).bg_color == ground and RenderingServer.get_default_clear_color() != ground, "the app paints the look's ground on its own canvas and says so, and the window's clear colour is left the host's: %s" % [RenderingServer.get_default_clear_color()])
	_verdict.check(Faint.faint(app.canvas).is_empty(), "so words judged on the canvas stand on the look's ground, not the window's: %s" % [Faint.faint(app.canvas)])
	_verdict.check(prompts.get_parent() == app.canvas and driver.get_parent() == app.canvas and commands.get_parent() == app.canvas, "the prompts, the driver and the door are under the app's canvas")
	_verdict.check(commands.handles(Chimes.GLOBAL, Prompts.MUTES) and commands.handles(Chimes.GLOBAL, Prompts.UNMUTES), "the prompts answer their own muting from anywhere")
	_verdict.check(driver.index.app != null and driver.index.app.name == &"app" and driver.get_top() == [&"app", &"here"], "the app it described is the app, arrived at, on the first of its screens: %s" % [driver.get_top()])
	_verdict.check(driver.index.has_place(_zoom.get_place()) and driver.index.place_named(_zoom.get_place()).get_parent() == app.canvas and (ui.node_named(&"save") as Control).is_visible_in_tree(), "the pop-up described on its press is a place beside the app, and the app's content shows")
	var answer := commands.dispatch(&"app", Motion.REDUCES, {"on": true})
	_verdict.check(answer == null and ui.motion.get_reduced(), "the clock answers reduced motion from anywhere: dispatched in the app, it is on: %s" % [answer])


func _a_model_stands_itself_up_where_it_was_handed_in_and_nowhere_else() -> void:
	_verdict.check(_of_the_app.get_parent() == app.canvas and _here.get_parent() == app.canvas and _there.get_parent() == app.canvas, "every model is beside the app in the tree, the two a screen was handed as well as the application's own")
	_verdict.check(commands.handles(&"there", COUNTS) and commands.handles(&"here", COUNTS), "a model handed to a screen is told what it answers in that screen's region")
	commands.dispatch(&"here", COUNTS, {})
	_verdict.check(_here.told_of == [COUNTS] and _there.told_of.is_empty(), "and the press lands on that screen's model alone, not the other screen's of the same action: here %s, there %s" % [_here.told_of, _there.told_of])
	commands.dispatch(&"here", JOTS, {})
	_verdict.check(_here.told_of == [COUNTS, JOTS], "a screen of ONE model also tells it what the screen declares and nothing else answers: %s" % [_here.told_of])
	_verdict.check(commands.handles(&"zoom 1", COUNTS) and _of_the_app.told_of.is_empty(), "the application's own is reached from a place that has no model of its own: the pop-up")
	commands.dispatch(&"zoom 1", COUNTS, {})
	_verdict.check(_of_the_app.told_of == [COUNTS], "and it is the one told there: %s" % [_of_the_app.told_of])
	_verdict.check(budget.get_parent() == app.canvas and jobs.get_parent() == app.canvas and jobs.get_running() == 0, "the frame's budget and the job pool are the application's own, beside it and idle")
