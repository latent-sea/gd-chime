extends SceneTree

## What must be true of loading: while what a place fills with is on its way
## (fetched.gd) the mark turns beside its words over the shapes standing in,
## and the place's actions are refused "still loading" on their faces;
## landed, the content takes their place and the actions go through; failed,
## the reason stands on the thing with a way to ask again and a notification
## says it too - and only an answer for the stay the reader is on counts.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_loading.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Motion := preload("res://addons/gd_chime/motion.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Surface := preload("res://addons/gd_chime/components/primitives/surface.gd")
const Keyframes := preload("res://addons/gd_chime/components/primitives/keyframes.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Loading := preload("res://addons/gd_chime/components/recipes/loading.gd")
const Fetched := preload("res://addons/gd_chime/fetched.gd")
const Notifications := preload("res://addons/gd_chime/notifications.gd")
const DrawnOver := preload("res://addons/gd_chime/drawn_over.gd")
const Token := preload("res://addons/gd_chime/token.gd")
const Verdict := preload("res://tests/verdict.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")

const SELLS := &"sells_a_crate"

var _verdict := Verdict.new()


## The stall's model: it sells a crate, but asks what the place fills with
## first, so nothing is sold while the stall's stock is on its way.
class Stall extends Fixture.Model:
	var stock: Fetched

	func would(action: StringName, payload: Dictionary) -> Phrase:
		var waiting := stock.would(action, payload)
		return waiting if waiting != null else super(action, payload)

func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(900, 700)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_until_landed_the_mark_and_shapes_show_and_the_actions_say_still_loading)
	await _verdict.states(_only_a_landing_for_the_stay_the_reader_is_on_counts)
	await _verdict.states(_the_mark_turns_and_rests_whole_while_motion_is_reduced_its_words_still_there)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## A stall screen filling from a source that answers when the test says -
## the stock, and a button to sell - beside a second screen to leave it for,
## as {made, stall, stock, answers}: every answer the source was handed.
func _stall() -> Dictionary:
	var made := Fixture.new(root, {SELLS: "sell a crate", Fetched.ASKS_AGAIN: "Ask again"})
	var ui := made.ui
	var answers: Array[Callable] = []
	var notices := Notifications.new(made.chimes, made.commands, root)
	root.add_child(notices)
	var stock: Fetched = ui.fetched(func(answer: Callable) -> void: answers.append(answer), notices, Phrase.of("The stock"))
	var stall := Stall.new(made.chimes, &"stall")
	stall.stock = stock
	stall.answering = [SELLS]
	var crates := ui.loading(stock, ui.text("forty crates of plums"), 2)
	ui.start(ui.app(&"app", [ui.screen(&"stall", [ui.column([crates, ui.button(SELLS)])], [stall, stock], {on_fill = stock.fill}), ui.screen(&"yard", [ui.text("the yard")])]))
	await _a_frame_passes()
	return {"made": made, "stall": stall, "stock": stock, "answers": answers, "notices": notices}


func _done(standing: Dictionary) -> void:
	(standing["stall"] as Stall).free()
	(standing["made"] as Fixture).done()


func _texts() -> Array[String]:
	var found: Array[String] = []
	# every text shown in the window, its words
	for part: Node in root.find_children("*", "Control", true, false):
		if part is Text and (part as Text).is_visible_in_tree():
			found.append((part as Text).get_text())
	return found


func _shown(kind: Script, style: StringName = &"") -> Array:
	return root.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return is_instance_of(part, kind) and (part as Control).is_visible_in_tree() and (style == &"" or (part as Surface).get_style() == style))


func _sell() -> Pressable:
	return root.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable and (part as Pressable).action == SELLS)[0]


## Waiting, the mark says "loading" over the shapes standing in and the
## button is refused "still loading" on its face, a press selling nothing;
## landed, the content stands where the shapes stood and the button sells.
func _until_landed_the_mark_and_shapes_show_and_the_actions_say_still_loading() -> void:
	var standing := await _stall()
	var stall: Stall = standing["stall"]
	var answers: Array[Callable] = standing["answers"]
	_verdict.check(_texts().has("Loading") and _shown(Surface, Themes.PLACEHOLDER).size() == 2 and _shown(Surface, Themes.LOADING).size() == 1, "waiting, the mark and its word show, over the two shapes asked for: %s" % [_texts()])
	_verdict.check(not _texts().has("forty crates of plums"), "and the content does not")
	var shape: Surface = _shown(Surface, Themes.PLACEHOLDER)[0]
	var looks := shape.get_theme_stylebox(&"panel").get_minimum_size()
	_verdict.check(shape.size.y == looks.y and shape.size.x >= looks.x and looks.y > 0.0, "a shape is the height its look gives a line, across at least the look's width: %s against %s" % [shape.size, looks])
	_verdict.check(not _sell().is_usable() and _texts().has("Still loading"), "the place's action is refused, and its button says it is still loading: %s" % [_texts()])
	_sell().grab_focus()
	await _a_frame_passes()
	# Enter pressed and let go on the button
	for down: bool in [true, false]:
		var key := InputEventKey.new()
		key.keycode = KEY_ENTER
		key.physical_keycode = KEY_ENTER
		key.pressed = down
		root.push_input(key)
	await _a_frame_passes()
	_verdict.check(stall.told_actions.is_empty(), "a press while it is loading sells nothing: %s" % [stall.told_actions])
	_verdict.check(DrawnOver.covered(root, Rect2(Vector2.ZERO, root.size)).is_empty(), "nothing is drawn over anything while it waits: %s" % [DrawnOver.covered(root, Rect2(Vector2.ZERO, root.size))])
	answers[-1].call("forty crates of plums", null)
	await _a_frame_passes()
	_verdict.check(_texts().has("forty crates of plums") and not _texts().has("Loading") and _shown(Surface, Themes.PLACEHOLDER).is_empty(), "landed, the content stands where the mark and the shapes stood: %s" % [_texts()])
	_verdict.check(_sell().is_usable() and not _texts().has("Still loading"), "and the button sells, with no reason on its face: %s" % [_texts()])
	_verdict.check(DrawnOver.covered(root, Rect2(Vector2.ZERO, root.size)).is_empty(), "nothing is drawn over anything once it has landed")
	_done(standing)


## Data asked for under a stay the reader has since left lands on nothing,
## and so does data asked for under an earlier stay once a new one began.
func _only_a_landing_for_the_stay_the_reader_is_on_counts() -> void:
	var standing := await _stall()
	var made: Fixture = standing["made"]
	var stock: Fetched = standing["stock"]
	var answers: Array[Callable] = standing["answers"]
	var first := answers[-1]
	made.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": &"yard"})
	await _a_frame_passes()
	first.call("plums", null)
	_verdict.check(stock.data.read() == null, "an answer for a stay the reader has left changes nothing")
	made.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": &"stall"})
	await _a_frame_passes()
	_verdict.check(answers.size() == 2 and stock.data.read() == null and _texts().has("Loading"), "back again, it is waiting under a new stay: %s" % [_texts()])
	first.call("plums", null)
	_verdict.check(stock.data.read() == null, "and the old stay's answer still lands on nothing")
	answers[1].call("plums", null)
	_verdict.check(stock.data.read() == "plums" and not stock.loading.read() and stock.failure.read() == null, "the stay's own answer lands, with nothing on its way and nothing failed: %s" % [stock.data.read()])
	# the same stay asking again, under a token of its own
	made.commands.dispatch(&"stall", Fetched.ASKS_AGAIN, {})
	answers[1].call("pears", null)
	_verdict.check(answers.size() == 3 and stock.data.read() == "plums", "asked again within the stay, what the asking before it brings lands on nothing: %s" % [stock.data.read()])
	answers[-1].call("figs", null)
	_verdict.check(stock.data.read() == "figs", "while what the latest asking brings lands: %s" % [stock.data.read()])
	made.commands.dispatch(&"stall", Fetched.ASKS_AGAIN, {})
	answers[-1].call(null, Phrase.of("The cart is late"))
	_verdict.check(str(stock.failure.read()) == "The cart is late" and stock.data.read() == "figs" and not stock.loading.read(), "a failure says why and loses nothing: %s" % [stock.failure.read()])
	await _a_frame_passes()
	var notices: Notifications = standing["notices"]
	var standing_notices: Array = notices.get_standing().map(func(one: Dictionary) -> String: return str(one["words"]))
	_verdict.check(_texts().has("Could not be loaded: The cart is late") and _texts().has("Ask again") and _texts().has("forty crates of plums"), "and it is said on the thing itself, with a way to ask again, over what was already there: %s" % [_texts()])
	_verdict.check(standing_notices == ["The stock could not be loaded: The cart is late"], "and in a notification by the words it is known by: the one way a far-side failure is said: %s" % [standing_notices])
	_done(standing)


## The mark is a loop: it turns while motion runs, and rests on its resting
## frame, whole and square, while motion is reduced - turned on live - with
## "loading" still said beside it.
func _the_mark_turns_and_rests_whole_while_motion_is_reduced_its_words_still_there() -> void:
	var made := Fixture.new(root, {})
	var ui := made.ui
	ui.motion.by_hand = true
	ui.motion.still = false
	ui.start(ui.app(&"app", [Loading.mark(ui)]))
	await _a_frame_passes()
	var turning: Keyframes = _shown(Keyframes)[0]
	var turns: Array[float] = []
	# a few steps of the clock, where the mark stands after each
	for step: int in 4:
		ui.motion.step(0.1)
		turns.append(turning.rotation_degrees)
	_verdict.check(turns[0] > 0.0 and turns[1] > turns[0] and ui.motion.get_running() > 0, "while motion runs, the mark turns: %s" % [turns])
	ui.motion.told(Motion.REDUCES, {"on": true})
	await _a_frame_passes()
	ui.motion.step(0.1)
	_verdict.check(turning.rotation_degrees == 90.0 and turning.modulate.a == 1.0 and ui.motion.get_running() == 0, "reduced, it rests whole, a quarter turned - the square it was - with nothing running: %s %s" % [turning.rotation_degrees, turning.modulate.a])
	_verdict.check(_texts().has("Loading"), "and the word says what the motion no longer does: %s" % [_texts()])
	ui.motion.told(Motion.REDUCES, {"on": false})
	await _a_frame_passes()
	ui.motion.step(0.1)
	_verdict.check(ui.motion.get_running() > 0 and turning.rotation_degrees != 90.0, "turned back on, it turns again: %s" % turning.rotation_degrees)
	made.done()
