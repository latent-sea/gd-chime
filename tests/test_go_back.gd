extends SceneTree

## What must be true of Back (go_back.gd): the system's go-back goes back a
## screen, and at the app's root runs the app's at_root and nothing else;
## with two apps in one window only the one whose easel held the focus last
## answers it; the cancel key lowers the pop-up on top once, never that and
## a screen too, and goes back a screen with none up; and a pop-up a model
## presents (describe_places.gd) is taken down by its model's own way out
## from every road Back comes by - the system's go-back, its shade, the
## cancel key - while a way out refused leaves it up, and a pop-up over it
## is lowered first, the one beneath going only once it is on top; and an
## app hidden by its host answers neither the go-back nor the cancel key,
## at its root or away from it, the key going on untaken to the host.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_go_back.gd
##
## The app has two screens, home and away, a pressable on each, a plain
## pop-up whose way out is its close, and a question its model presents
## while it is asking, whose way out is the model's CANCELS. The system's
## go-back is the window's notification, told to every node in it as the
## engine tells it; the cancel key is Escape pressed on the window.

const ChimeApp := preload("res://addons/gd_chime/chime_app.gd")
const Verdict := preload("res://tests/verdict.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Actions := preload("res://addons/gd_chime/actions.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Sheet := preload("res://addons/gd_chime/components/recipes/sheet.gd")

const GOES_AWAY := &"goes_away"
const GOES_HOME := &"goes_home"
const PRESENTS := &"presents_the_question"
const CANCELS := &"cancels_the_question"
const HOME := [&"app", &"home"]
const AWAY := [&"app", &"away"]
## The two pop-ups by the names the builder gives them: the first of each kind.
const PLAIN := &"plain 1"
const ASKED := &"asked 1"


## The question's model: asking while it presents the question, told CANCELS to stop, refusing while it says so.
class Questions extends "res://addons/gd_chime/controller.gd":
	var told_actions: Array[StringName] = []
	var refusing: Phrase = null
	var asking := value(false)

	func answers() -> Array[StringName]:
		return [PRESENTS, CANCELS]

	func would(_action: StringName, _payload: Dictionary) -> Phrase:
		return refusing

	func told(action: StringName, _payload: Dictionary) -> Phrase:
		told_actions.append(action)
		asking.set_value(action == PRESENTS)
		return null


## The app: home and away, the plain pop-up, and the question; counting what its at_root was asked.
class Backing extends ChimeApp:
	var questions: Questions
	var at_roots: int = 0

	func _init() -> void:
		super()
		at_root = func() -> void: at_roots += 1

	func declare(register: Actions) -> void:
		register.declare_all({GOES_AWAY: ["away"], GOES_HOME: ["home"], PRESENTS: ["ask"], CANCELS: ["cancel"]})

	func describe() -> Desc:
		questions = model(Questions.new(chimes))
		var plain := ui.pop_up(&"plain", func(_which: Bound) -> Desc: return Sheet.over(ui, [Sheet.close(ui)], &"Confirm"))
		var asked := ui.pop_up(&"asked", func(_which: Bound) -> Desc: return Sheet.over(ui, [ui.button(CANCELS)], &"Confirm"), null, CANCELS)
		asked.props["presented"] = questions.asking
		var home := ui.screen(&"home", [ui.button(GOES_AWAY, {goes_to = &"away"}).named(&"to_away"), ui.button(PRESENTS), plain, asked])
		return ui.app(&"app", [home, ui.screen(&"away", [ui.button(GOES_HOME, {goes_to = &"home"}).named(&"to_home")])])


## A node of the host's beside the app, counting the cancel keys that reach it untaken.
class Host extends Node:
	var cancels: int = 0

	func _unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed(&"ui_cancel"):
			cancels += 1


var _verdict := Verdict.new()


func _init() -> void:
	await process_frame
	# a desk's window, set once the window stands: set before its first frame, a headless window keeps its own size (measured on 4.6.2)
	root.size = Vector2i(1920, 1080)
	await process_frame
	await _verdict.states(_the_system_go_back_goes_back_a_screen_and_at_the_root_runs_at_root_alone)
	await _verdict.states(_only_the_app_whose_easel_held_the_focus_last_answers_the_system_go_back)
	await _verdict.states(_the_cancel_key_lowers_the_pop_up_on_top_once_else_goes_back_a_screen)
	await _verdict.states(_back_over_a_pop_up_a_model_presents_is_its_way_out_by_every_road)
	await _verdict.states(_a_pop_up_under_another_is_lowered_only_once_it_is_on_top)
	await _verdict.states(_a_hidden_app_answers_neither_the_system_go_back_nor_the_cancel_key)
	quit(_verdict.deliver(get_script()))


## A frame for the app to settle: what a presented fact raised or lowered, drawn.
func _settled() -> void:
	# a few frames, since a settling is done in the driver's step of the next one
	for frame: int in 3:
		await process_frame


## An app standing across this share of the window, from this edge.
func _standing(from: float = 0.0, to: float = 1.0) -> Backing:
	var app := Backing.new()
	app.set_anchors_preset(Control.PRESET_FULL_RECT)
	app.anchor_left = from
	app.anchor_right = to
	# a screen of 72 dots to the inch whatever this machine's is, so the canvas is fitted and never held to the look's least size
	app.reads_dpi = func() -> int: return 72
	root.add_child(app)
	await _settled()
	return app


## The reader taken to a place of this app through its door.
func _go(app: Backing, place: StringName) -> void:
	app.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": place})
	await _settled()


## The system's go-back, told to every node in the window as the engine tells it.
func _system_go_back() -> void:
	root.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await _settled()


## Escape pressed and let go on the window.
func _escape() -> void:
	# the key down, then up
	for down: bool in [true, false]:
		var key := InputEventKey.new()
		key.keycode = KEY_ESCAPE
		key.physical_keycode = KEY_ESCAPE
		key.pressed = down
		root.push_input(key)
		await _settled()


func _the_system_go_back_goes_back_a_screen_and_at_the_root_runs_at_root_alone() -> void:
	var app := await _standing()
	await _go(app, &"away")
	_verdict.check(app.driver.get_top() == AWAY, "the reader is away: %s" % [app.driver.get_top()])
	await _system_go_back()
	_verdict.check(app.driver.get_top() == HOME and app.at_roots == 0, "the system's go-back goes back a screen, home: %s" % [app.driver.get_top()])
	await _system_go_back()
	_verdict.check(app.driver.get_top() == HOME and app.at_roots == 1, "at the root, with nothing to go back to, it runs the app's at_root once and moves nothing: %d" % app.at_roots)
	_verdict.check(is_instance_valid(app) and app.is_inside_tree(), "and the app still stands")
	app.free()


func _only_the_app_whose_easel_held_the_focus_last_answers_the_system_go_back() -> void:
	var left := await _standing(0.0, 0.5)
	var right := await _standing(0.5, 1.0)
	await _go(left, &"away")
	await _go(right, &"away")
	(right.ui.node_named(&"to_home") as Control).grab_focus()
	await _system_go_back()
	_verdict.check(right.driver.get_top() == HOME and left.driver.get_top() == AWAY, "the focus in the right app, only it goes back: %s %s" % [left.driver.get_top(), right.driver.get_top()])
	(left.ui.node_named(&"to_home") as Control).grab_focus()
	await _system_go_back()
	_verdict.check(left.driver.get_top() == HOME and right.at_roots == 0, "the focus moved to the left app, only it goes back, and the right, at its root, is asked nothing: %s %d" % [left.driver.get_top(), right.at_roots])
	left.viewport.gui_release_focus()
	await _system_go_back()
	_verdict.check(left.at_roots == 1 and right.at_roots == 0, "with nothing in the window holding the focus, the app that held it last answers, and only it: %d %d" % [left.at_roots, right.at_roots])
	left.free()
	right.free()


func _the_cancel_key_lowers_the_pop_up_on_top_once_else_goes_back_a_screen() -> void:
	var app := await _standing()
	await _go(app, &"away")
	await _go(app, PLAIN)
	_verdict.check(app.driver.get_top() == [PLAIN], "the plain pop-up is up over away: %s" % [app.driver.get_top()])
	await _escape()
	_verdict.check(app.driver.get_top() == AWAY, "Escape lowers it, and the reader is still away - lowered once, never gone back a screen as well: %s" % [app.driver.get_top()])
	await _escape()
	_verdict.check(app.driver.get_top() == HOME, "with nothing up, Escape goes back a screen: %s" % [app.driver.get_top()])
	await _escape()
	_verdict.check(app.driver.get_top() == HOME and app.at_roots == 1, "and at the root it runs the app's at_root: %d" % app.at_roots)
	app.free()


func _back_over_a_pop_up_a_model_presents_is_its_way_out_by_every_road() -> void:
	var app := await _standing()
	var questions := app.questions
	_verdict.check(app.driver.ways_out == {ASKED: CANCELS}, "the question's way out is its model's own, and the plain pop-up names none: %s" % [app.driver.ways_out])
	await _go(app, &"away")
	app.commands.dispatch(Chimes.GLOBAL, PRESENTS, {})
	await _settled()
	_verdict.check(app.driver.get_top() == [ASKED], "the model asking, the question is up: %s" % [app.driver.get_top()])
	await _system_go_back()
	_verdict.check(questions.told_actions == [PRESENTS, CANCELS] and app.driver.get_top() == AWAY, "the system's go-back tells the model CANCELS, which takes the question down, the reader still away: %s %s" % [questions.told_actions, app.driver.get_top()])
	app.commands.dispatch(Chimes.GLOBAL, PRESENTS, {})
	await _settled()
	var shade: Control = app.driver.index.drawn_by(app.driver.index.place_named(ASKED), app.ui.CLOSES)
	shade.pressed()
	await _settled()
	_verdict.check(questions.told_actions.back() == CANCELS and questions.told_actions.size() == 4 and app.driver.get_top() == AWAY, "a press on its shade, going back, tells the model CANCELS: %s %s" % [questions.told_actions, app.driver.get_top()])
	app.commands.dispatch(Chimes.GLOBAL, PRESENTS, {})
	await _settled()
	await _escape()
	_verdict.check(questions.told_actions.back() == CANCELS and questions.told_actions.size() == 6 and app.driver.get_top() == AWAY, "and so does Escape: %s %s" % [questions.told_actions, app.driver.get_top()])
	app.commands.dispatch(Chimes.GLOBAL, PRESENTS, {})
	await _settled()
	questions.refusing = Phrase.of("Answer it first")
	await _system_go_back()
	_verdict.check(questions.told_actions.size() == 7 and app.driver.get_top() == [ASKED], "a way out the model refuses leaves the question up, and goes back nowhere: %s" % [app.driver.get_top()])
	app.free()


func _a_pop_up_under_another_is_lowered_only_once_it_is_on_top() -> void:
	var app := await _standing()
	var questions := app.questions
	await _go(app, &"away")
	app.commands.dispatch(Chimes.GLOBAL, PRESENTS, {})
	await _settled()
	await _go(app, PLAIN)
	_verdict.check(app.driver.get_state()["overlays"].map(func(up: Array) -> StringName: return up[0]) == [ASKED, PLAIN], "the plain pop-up stands over the question: %s" % [app.driver.get_state()["overlays"]])
	await _system_go_back()
	_verdict.check(app.driver.get_top() == [ASKED] and questions.told_actions == [PRESENTS], "the system's go-back lowers the plain one on top by its close, and the question's model is told nothing: %s %s" % [app.driver.get_top(), questions.told_actions])
	await _go(app, PLAIN)
	app.commands.dispatch(Chimes.GLOBAL, CANCELS, {})
	await _settled()
	_verdict.check(app.driver.get_top() == [PLAIN] and app.driver.get_state()["overlays"].size() == 2, "the question's model stopping while the plain pop-up is over it lowers nothing beneath: %s" % [app.driver.get_state()["overlays"]])
	await _system_go_back()
	_verdict.check(app.driver.get_top() == AWAY and questions.told_actions == [PRESENTS, CANCELS], "once the plain one is lowered, the question goes too, and the reader is still away: %s %s" % [app.driver.get_top(), questions.told_actions])
	app.free()


## The app hidden as a host hides it to show something else in its place -
## a scene of its own over the window - with a press of it holding the
## window's focus.
func _a_hidden_app_answers_neither_the_system_go_back_nor_the_cancel_key() -> void:
	var app := await _standing()
	var host := Host.new()
	root.add_child(host)
	(app.ui.node_named(&"to_away") as Control).grab_focus()
	app.visible = false
	await _system_go_back()
	await _escape()
	_verdict.check(app.driver.get_top() == HOME and app.at_roots == 0 and host.cancels == 1, "hidden at its root, its at_root is asked nothing by the system's go-back or Escape, and Escape goes on untaken to the host: %d %d" % [app.at_roots, host.cancels])
	app.visible = true
	await _go(app, &"away")
	(app.ui.node_named(&"to_home") as Control).grab_focus()
	app.visible = false
	await _system_go_back()
	await _escape()
	_verdict.check(app.driver.get_top() == AWAY and host.cancels == 2, "hidden away from its root, it is moved back by neither, and Escape goes on to the host again: %s %d" % [app.driver.get_top(), host.cancels])
	app.visible = true
	await _system_go_back()
	_verdict.check(app.driver.get_top() == HOME, "shown again, the system's go-back goes back a screen: %s" % [app.driver.get_top()])
	host.free()
	app.free()
