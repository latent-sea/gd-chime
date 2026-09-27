extends SceneTree

## What must be true of a finger on the glass (touch.gd): a gesture goes
## whole to the one nearest thing that takes it on its axis, and to nothing
## within the slop or begun on a thing that holds the finger itself.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_touch.gd
##
## The touches go in as the engine's own do, through Input.parse_input_event,
## so the emulated mouse comes first and moves the hovered control under the
## finger, as on a device. A row that takes across stands in a list that
## takes down; beside them, a thing that holds the finger.

const Themes := preload("res://addons/gd_chime/theme.gd")
const Touch := preload("res://addons/gd_chime/touch.gd")
const Verdict := preload("res://tests/verdict.gd")

var _verdict := Verdict.new()
var _touch: Touch
var _list: Taker
var _row: Taker
var _held: Control


## A thing that takes a gesture on one axis, and writes down what it was told.
class Taker extends Control:
	var axis: StringName
	var said: Array = []  # [what, the values], in the order told

	func _init(taking: StringName) -> void:
		axis = taking
		add_to_group(Touch.TAKES)

	func takes_finger(on: StringName, _travel: Vector2) -> bool:
		return on == axis

	func finger_moved(travel: Vector2, relative: Vector2) -> void:
		said.append([&"moved", travel, relative])

	func finger_ended(velocity: Vector2) -> void:
		said.append([&"ended", velocity])


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	# a window at the base size, so the canvas is the window's own pixels
	root.size = Vector2i(1920, 1080)
	_touch = Touch.new()
	root.add_child(_touch)
	_list = Taker.new(Touch.DOWN)
	_list.position = Vector2(0, 0)
	_list.size = Vector2(800, 800)
	_row = Taker.new(Touch.ACROSS)
	_row.position = Vector2(100, 100)
	_row.size = Vector2(600, 100)
	_list.add_child(_row)
	_held = Control.new()
	_held.position = Vector2(1000, 100)
	_held.size = Vector2(200, 200)
	_held.add_to_group(Touch.HOLDS)
	root.add_child(_list)
	root.add_child(_held)
	await process_frame
	await _verdict.states(_a_finger_within_the_slop_is_nobodys_gesture)
	await _verdict.states(_across_goes_whole_to_the_row_and_its_axis_holds)
	await _verdict.states(_down_goes_past_the_row_to_the_list)
	await _verdict.states(_begun_on_a_thing_holding_the_finger_it_is_nobody_elses)
	await _verdict.states(_a_finger_is_told_from_a_mouse)
	quit(_verdict.deliver(get_script()))


## A finger down at this point of the canvas, moved by these steps a frame each, and lifted.
func _gesture(at: Vector2, steps: Array) -> void:
	_row.said.clear()
	_list.said.clear()
	var down := InputEventScreenTouch.new()
	down.position = at
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	var now := at
	# every step, one drag a frame
	for step: Vector2 in steps:
		now += step
		var drag := InputEventScreenDrag.new()
		drag.position = now
		drag.relative = step
		Input.parse_input_event(drag)
		await process_frame
	var up := InputEventScreenTouch.new()
	up.position = now
	Input.parse_input_event(up)
	await process_frame


func _a_finger_within_the_slop_is_nobodys_gesture() -> void:
	await _gesture(Vector2(300, 150), [Vector2(4, 0), Vector2(4, 3)])
	_verdict.check(_row.said.is_empty() and _list.said.is_empty(), "a finger that stays within the slop is handed to nobody: %s %s" % [_row.said, _list.said])


func _across_goes_whole_to_the_row_and_its_axis_holds() -> void:
	await _gesture(Vector2(300, 150), [Vector2(12, 2), Vector2(12, 2), Vector2(2, 30), Vector2(12, 0)])
	var moves: Array = _row.said.filter(func(one: Array) -> bool: return one[0] == &"moved")
	_verdict.check(_list.said.is_empty(), "the list holding the row is told nothing of a gesture across: %s" % [_list.said])
	_verdict.check(moves.size() == 3 and moves[0][1] == Vector2(24, 4) and moves.back()[1] == Vector2(38, 34), "the row has every move from the one that passed the slop, the travel summed, the later move down still its own: %s" % [moves])
	_verdict.check(_row.said.back()[0] == &"ended" and _row.said.back()[1].x > 0.0, "and is told of the lift with a velocity the way it went: %s" % [_row.said.back()])


func _down_goes_past_the_row_to_the_list() -> void:
	await _gesture(Vector2(300, 150), [Vector2(1, 20), Vector2(0, 20)])
	_verdict.check(_row.said.is_empty(), "a row taking across is told nothing of a gesture down: %s" % [_row.said])
	_verdict.check(_list.said.size() == 3 and _list.said[1][1] == Vector2(1, 40) and _list.said[2][0] == &"ended", "the list holding it has it, move by move, then the lift: %s" % [_list.said])
	# the row taking down too: of two that take it, the nearest has it
	_row.axis = Touch.DOWN
	await _gesture(Vector2(300, 150), [Vector2(1, 20), Vector2(0, 20)])
	_row.axis = Touch.ACROSS
	_verdict.check(_row.said.size() == 3 and _list.said.is_empty(), "of two that take a gesture, the nearest has it all and the other nothing: %s %s" % [_row.said, _list.said])


func _begun_on_a_thing_holding_the_finger_it_is_nobody_elses() -> void:
	var holder := Taker.new(Touch.DOWN)
	holder.position = Vector2(900, 0)
	holder.size = Vector2(400, 400)
	root.remove_child(_held)
	_held.position = Vector2(100, 100)
	holder.add_child(_held)
	root.add_child(holder)
	await process_frame
	await _gesture(Vector2(1100, 200), [Vector2(0, 30), Vector2(0, 30)])
	_verdict.check(holder.said.is_empty() and _touch.get_taken() == null, "a gesture begun on a thing holding the finger is handed to nothing holding it: %s" % [holder.said])
	# the same gesture begun on the holder's own ground is its own
	holder.said.clear()
	await _gesture(Vector2(950, 350), [Vector2(0, 30), Vector2(0, 30)])
	_verdict.check(holder.said.size() == 3, "and one begun on the holder's own ground is the holder's: %s" % [holder.said])
	holder.free()


func _a_finger_is_told_from_a_mouse() -> void:
	var emulated := InputEventMouseButton.new()
	emulated.device = InputEvent.DEVICE_ID_EMULATION
	var mouse := InputEventMouseButton.new()
	_verdict.check(Touch.from_finger(emulated) and not Touch.from_finger(mouse) and not Touch.from_finger(InputEventKey.new()), "a press the engine made from a touch is a finger's; a mouse's and a key's are not")
