extends SceneTree

## What must be true of a row a finger swipes (swipe.gd): it follows the
## finger across and shows what letting go will do; past the look's share it
## does it, once, through the door, and short of it or refused it springs
## back; a tap presses it and a finger drawn down scrolls the list instead.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_swipe.gd
##
## The touches go in as a device's do, through Input.parse_input_event. The
## app is a list of thirty rows in a scroll, each opened by a tap, delivered
## drawn right and reported drawn left, each carrying its number.

const Fixture := preload("res://tests/fixture.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Swipe := preload("res://addons/gd_chime/components/primitives/swipe.gd")
const Verdict := preload("res://tests/verdict.gd")

const OPENS := &"opens"
const DELIVERS := &"delivers"
const REPORTS := &"reports"

var _verdict := Verdict.new()
var _made: Fixture
var _model: Seen
var _scroll: ScrollContainer


## A model that does what it is told, writes down with what, and refuses what it was set to.
class Seen extends Fixture.Model:
	var payloads: Array = []

	func told(action: StringName, payload: Dictionary) -> Phrase:
		payloads.append(payload)
		return super.told(action, payload)


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	await _verdict.states(_drawn_across_it_follows_the_finger_and_shows_what_letting_go_will_do)
	await _verdict.states(_let_go_past_the_share_it_does_it_once_and_slides_back)
	await _verdict.states(_let_go_short_it_does_nothing_and_springs_back)
	await _verdict.states(_refused_it_springs_back_saying_why)
	await _verdict.states(_a_way_with_no_action_is_not_taken)
	await _verdict.states(_a_tap_presses_it_and_a_finger_drawn_down_scrolls_the_list)
	await _verdict.states(_its_place_declares_every_action_it_does)
	quit(_verdict.deliver(get_script()))


## The app over these rows, each {side: action}, its model answering every action.
func _standing(count: int = 30, sides: Dictionary = {Swipe.RIGHT: DELIVERS, Swipe.LEFT: REPORTS}) -> void:
	var words := {OPENS: "open", DELIVERS: "delivered", REPORTS: "report"}
	var declared: Dictionary = {OPENS: words[OPENS]}
	# every side's action in the register, and only those: an action nobody performs is refused at the start
	for side: StringName in sides:
		declared[sides[side]] = words[sides[side]]
	_made = Fixture.new(root, declared)
	_model = Seen.new(_made.chimes)
	root.add_child(_model)
	# every action answered by the model from anywhere
	for action: StringName in declared:
		_made.commands.register(Chimes.GLOBAL, action, _model)
	var ui := _made.ui
	var reveals := {Swipe.RIGHT: ui.text("delivered", Themes.FACE), Swipe.LEFT: ui.text("report", Themes.FACE)}
	var row := func(at: int) -> RefCounted: return ui.swipe(OPENS, {"id": at}, ui.text("stop %d" % at), {sides = sides, reveals = reveals, style = &"SwipeRow"}).named(StringName("stop %d" % at))
	ui.start(ui.app(&"app", [ui.scroll(ui.column(range(count).map(row))).named(&"list")]))
	root.size = Vector2i(1920, 1080)
	# the frames the start and the first move take
	for frame: int in 6:
		await process_frame
	_scroll = ui.node_named(&"list")


func _done() -> void:
	_made.done()


func _row(at: int) -> Swipe:
	return _made.ui.node_named(StringName("stop %d" % at))


func _touch(at: Vector2, down: bool) -> void:
	var touched := InputEventScreenTouch.new()
	touched.position = root.get_final_transform() * at
	touched.pressed = down
	Input.parse_input_event(touched)
	await process_frame


## A finger down on a row's middle, drawn by these steps a frame each; lifted if asked.
func _drawn(row: Control, steps: Array, lifts: bool = true) -> void:
	var at := row.get_global_rect().get_center()
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


func _drawn_across_it_follows_the_finger_and_shows_what_letting_go_will_do() -> void:
	await _standing()
	var row := _row(2)
	var share := row.size.x * row.get_theme_constant(&"swipe_commit", &"Touch") / 1000.0
	await _drawn(row, [Vector2(30, 0), Vector2(30, 0)], false)
	var content: Control = row.get_child(0)
	var right: Control = row.get_child(1)
	var left: Control = row.get_child(2)
	_verdict.check(row.get_slid() == 60.0 and not row.is_armed(), "drawn 60 across, what it holds has slid with the finger, not yet armed: %s" % row.get_slid())
	_verdict.check(right.visible and not left.visible, "the side drawn from shows what letting go will do, the other side nothing")
	_verdict.check(row.clip_contents, "slid, it is clipped to its own rect, so what slid past its edge is not drawn over its neighbours")
	_verdict.check(right.get_global_rect().end.x <= content.get_global_rect().position.x, "and its words stand clear of what slid, never under it: %s against %s" % [right.get_global_rect(), content.get_global_rect()])
	# on, past the look's share
	var on := InputEventScreenDrag.new()
	on.position = root.get_final_transform() * (row.get_global_rect().get_center() + Vector2(60.0 + share, 0))
	on.relative = root.get_final_transform().basis_xform(Vector2(share, 0))
	Input.parse_input_event(on)
	await process_frame
	_verdict.check(row.is_armed() and _model.told_actions.is_empty(), "drawn past the look's share it is armed, and nothing is done until the finger lifts: %s" % row.get_slid())
	await _touch(row.get_global_rect().get_center(), false)
	_done()


func _let_go_past_the_share_it_does_it_once_and_slides_back() -> void:
	await _standing()
	var row := _row(3)
	var motion := _made.ui.motion
	motion.still = false
	motion.by_hand = true
	await _drawn(row, [Vector2(-200, 0), Vector2(-300, 0), Vector2(-300, 0)])
	_verdict.check(_model.told_actions == [REPORTS] and _model.payloads == [{"id": 3}], "let go past the share drawn left, the left side's action is done once, with the row's payload: %s %s" % [_model.told_actions, _model.payloads])
	motion.step(0.1)
	var out := row.get_slid()
	motion.step(2.0)
	motion.step(2.0)
	_verdict.check(out < -800.0 and row.get_slid() == 0.0, "it slides on out and, still standing, back in: %s then %s" % [out, row.get_slid()])
	_done()


func _let_go_short_it_does_nothing_and_springs_back() -> void:
	await _standing()
	var row := _row(4)
	var motion := _made.ui.motion
	motion.still = false
	motion.by_hand = true
	await _drawn(row, [Vector2(40, 0), Vector2(40, 0)])
	var let_go := row.get_slid()
	motion.step(2.0)
	_verdict.check(_model.told_actions.is_empty() and let_go == 80.0 and row.get_slid() == 0.0, "let go short of the share, nothing is done and it springs back: %s, %s then %s" % [_model.told_actions, let_go, row.get_slid()])
	_verdict.check(not row.clip_contents, "at rest again it cuts nothing, so the list holding it judges its words as any")
	_done()


func _refused_it_springs_back_saying_why() -> void:
	await _standing()
	_model.refuse(DELIVERS, Phrase.of("delivered already"))
	var row := _row(5)
	await _drawn(row, [Vector2(300, 0), Vector2(400, 0), Vector2(400, 0)])
	_verdict.check(_model.told_actions.is_empty() and row.get_slid() == 0.0, "refused, nothing is done and it springs back: %s" % row.get_slid())
	_verdict.check(str(row.get_refusal()) == "delivered already", "and its reason says why: %s" % row.get_refusal())
	_done()


func _a_way_with_no_action_is_not_taken() -> void:
	await _standing(3, {Swipe.RIGHT: DELIVERS})
	var row := _row(1)
	await _drawn(row, [Vector2(-300, 0), Vector2(-300, 0)], false)
	_verdict.check(row.get_slid() == 0.0 and _made.ui.touch.get_taken() == null, "drawn toward a side with no action, it does not move: %s" % row.get_slid())
	await _touch(row.get_global_rect().get_center() + Vector2(-600, 0), false)
	_verdict.check(_model.told_actions.is_empty(), "and nothing is done: %s" % [_model.told_actions])
	_done()


func _a_tap_presses_it_and_a_finger_drawn_down_scrolls_the_list() -> void:
	await _standing()
	var row := _row(6)
	await _touch(row.get_global_rect().get_center(), true)
	await _touch(row.get_global_rect().get_center(), false)
	_verdict.check(_model.told_actions == [OPENS] and _model.payloads == [{"id": 6}], "a tap presses its own action with its payload: %s %s" % [_model.told_actions, _model.payloads])
	await _drawn(row, [Vector2(0, -40), Vector2(0, -40)])
	_verdict.check(row.get_slid() == 0.0 and _scroll.scroll_vertical > 0 and _model.told_actions == [OPENS], "a finger drawn up it scrolls the list and moves the row not at all: %d" % _scroll.scroll_vertical)
	_done()


func _its_place_declares_every_action_it_does() -> void:
	await _standing()
	var performs: Dictionary = _made.driver.index.app.performs
	_verdict.check(performs.has(OPENS) and performs.has(DELIVERS) and performs.has(REPORTS), "the place it stands in declares its tap's action and both sides': %s" % [performs])
	_done()
