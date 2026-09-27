extends SceneTree

## What must be true of motion: the one clock, the look's tokens, reduced
## motion, and the frame budget.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_motion.gd
##
## Stepped by hand, a run reaches its end exactly when the look's duration
## is up, by the look's curve and no other; a new target mid-flight goes on
## from the value reached; reduced, a move snaps and a fade is a short
## straight one; over budget, new motion snaps and what was running runs
## on; a run whose node is gone is dropped; a Theme with no tokens moves
## nothing.

const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Commands := preload("res://addons/gd_chime/commands.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const FrameBudget := preload("res://addons/gd_chime/frame_budget.gd")
const Motion := preload("res://addons/gd_chime/motion.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Verdict := preload("res://tests/verdict.gd")
const Reads := preload("res://addons/gd_chime/reads.gd")

var _verdict := Verdict.new()
var _seen: Array = []


## A budget that is over when told to be.
class Spent extends FrameBudget:
	var over: bool = false

	func is_over() -> bool:
		return over


func _init() -> void:
	await process_frame
	await _verdict.states(_a_run_reaches_its_end_when_the_look_s_duration_is_up_by_the_look_s_curve)
	await _verdict.states(_a_new_target_mid_flight_goes_on_from_the_value_reached)
	await _verdict.states(_one_run_writes_one_property_of_one_node_and_takes_over_from_where_the_last_had_got)
	await _verdict.states(_reduced_a_move_snaps_and_a_fade_is_short_and_straight)
	await _verdict.states(_over_budget_new_motion_snaps_and_what_was_running_runs_on)
	await _verdict.states(_a_run_whose_node_is_gone_is_dropped_and_no_tokens_move_nothing)
	quit(_verdict.deliver(get_script()))


## A clock stepped by hand under the floor's own look: enter is 180ms eased out, exit 90ms.
func _clock(chimes: Chimes) -> Motion:
	root.theme = Themes.new(Themes.NEUTRAL)
	var motion := Motion.new(chimes, root)
	motion.by_hand = true
	root.add_child(motion)
	_seen = []
	return motion


func _note(value: Variant) -> void:
	_seen.append(value)


func _a_run_reaches_its_end_when_the_look_s_duration_is_up_by_the_look_s_curve() -> void:
	var motion := _clock(Chimes.new(Belfry.new()))
	var arrived: Array = []
	var run := motion.run(0.0, 100.0, Motion.ENTER, _note, false, func() -> void: arrived.append(true))
	_verdict.check(is_equal_approx(motion.lasts(Motion.ENTER), 0.18) and is_equal_approx(motion.lasts(Motion.EXIT), 0.09) and is_equal_approx(motion.stagger(), 0.04), "an easing lasts what the look says: %s %s" % [motion.lasts(Motion.ENTER), motion.lasts(Motion.EXIT)])
	motion.step(0.09)
	var half: float = Tween.interpolate_value(0.0, 100.0, 0.09, 0.18, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	_verdict.check(_seen.size() == 1 and is_equal_approx(_seen[0], half) and half > 50.0 and arrived.is_empty(), "halfway through its time it is where the look's curve puts it - eased out, past the middle: %s" % [_seen])
	motion.step(0.09)
	_verdict.check(_seen.back() == 100.0 and run.is_over() and arrived == [true] and motion.get_running() == 0, "its time up, it is exactly at its end, says so once, and is let go: %s" % [_seen.back()])
	motion.step(0.09)
	_verdict.check(_seen.size() == 2, "and is stepped no more")
	var colour := motion.run(Color.BLACK, Color.WHITE, Motion.ENTER, _note)
	var place := motion.run(Vector2.ZERO, Vector2(10, 20), Motion.ENTER, _note)
	motion.step(1.0)
	_verdict.check(colour.value == Color.WHITE and place.value == Vector2(10, 20), "a colour and a vector go as a number does")
	motion.free()
	root.theme = null


func _a_new_target_mid_flight_goes_on_from_the_value_reached() -> void:
	var motion := _clock(Chimes.new(Belfry.new()))
	var run := motion.run(0.0, 100.0, Motion.ENTER, _note)
	motion.step(0.09)
	var reached: float = run.value
	motion.retarget(run, 0.0)
	motion.step(0.001)
	_verdict.check(absf(_seen.back() - reached) < 2.0 and _seen.back() < reached, "sent back mid-flight, the next value is just short of the one reached - no jump: %s then %s" % [reached, _seen.back()])
	motion.step(0.18)
	_verdict.check(run.value == 0.0 and motion.get_running() == 0, "and it arrives at the new target: %s" % [run.value])
	motion.retarget(run, 40.0)
	motion.step(0.18)
	_verdict.check(run.value == 40.0, "one that had arrived, sent on, goes again: %s" % [run.value])
	motion.free()
	root.theme = null


func _one_run_writes_one_property_of_one_node_and_takes_over_from_where_the_last_had_got() -> void:
	var motion := _clock(Chimes.new(Belfry.new()))
	var label := Label.new()
	root.add_child(label)
	var ended: Array = []
	var first := motion.drive(label, &"turn", 0.0, 100.0, Motion.ENTER, label.set_rotation, false, func() -> void: ended.append("first"))
	motion.step(0.09)
	var reached: float = label.rotation
	var second := motion.drive(label, &"turn", 0.0, -50.0, Motion.ENTER, label.set_rotation)
	_verdict.check(first.is_over() and motion.get_running() == 1, "driven again, the first run is over and one run is left writing it: %d" % motion.get_running())
	motion.step(0.001)
	_verdict.check(reached > 0.0 and absf(label.rotation - reached) < 5.0 and label.rotation < reached, "the second went on from where the first had got, whatever start it was given: %s then %s" % [reached, label.rotation])
	var other := motion.drive(label, &"size", 0.0, 10.0, Motion.ENTER, label.set_custom_minimum_size.bind())
	_verdict.check(motion.get_running() == 2 and not second.is_over(), "another property of the same node is another run's")
	other.stopped = true
	motion.step(0.5)
	_verdict.check(label.rotation == -50.0 and ended.is_empty(), "it arrives where the second was sent; the run taken over never said it arrived: %s" % [ended])
	var third := motion.drive(label, &"turn", 7.0, 9.0, Motion.ENTER, label.set_rotation)
	motion.step(0.001)
	_verdict.check(label.rotation >= 7.0 and label.rotation < 9.0 and not third.is_over(), "with nothing driving it any more, a run starts from the start it is given: %s" % label.rotation)
	label.free()
	motion.free()
	root.theme = null


func _reduced_a_move_snaps_and_a_fade_is_short_and_straight() -> void:
	var chimes := Chimes.new(Belfry.new())
	var driver := Driver.new(chimes)
	var commands := Commands.new(chimes, driver)
	var motion := _clock(chimes)
	commands.register(Chimes.GLOBAL, Motion.REDUCES, motion)
	commands.dispatch(Chimes.GLOBAL, Motion.REDUCES, {"on": true})
	Reads.begin()
	var reduced := motion.get_reduced()
	var read: Array = Reads.end().keys()
	_verdict.check(reduced and read == [Reads.hung(motion._values.get_address(), motion._values.get_address())], "reduced motion is a command and a read, a value of the motion's own: %s" % [read])
	var slid := motion.run(0.0, 100.0, Motion.EMPHASIS, _note)
	_verdict.check(slid.value == 100.0 and _seen == [100.0] and motion.get_running() == 0, "reduced, a move is at its end at once, with nothing between: %s" % [_seen])
	var faded := motion.run(0.0, 1.0, Motion.EMPHASIS, _note, true)
	motion.step(0.045)
	_verdict.check(is_equal_approx(faded.value, 0.5), "a fade is a straight line over the quick duration, whatever was asked: %s" % [faded.value])
	motion.step(0.045)
	_verdict.check(faded.value == 1.0 and faded.is_over(), "and is done in it")
	commands.dispatch(Chimes.GLOBAL, Motion.REDUCES, {"on": false})
	var again := motion.run(0.0, 100.0, Motion.EMPHASIS, _note)
	motion.step(0.09)
	_verdict.check(again.value > 0.0 and again.value != 100.0 and not again.is_over(), "restored, a move moves again: %s" % [again.value])
	for node: Node in [motion, commands, driver]:
		node.free()
	root.theme = null


func _over_budget_new_motion_snaps_and_what_was_running_runs_on() -> void:
	var chimes := Chimes.new(Belfry.new())
	var motion := _clock(chimes)
	var budget := Spent.new(chimes, 16.0, 0.5, 3)
	motion.budget = budget
	var before := motion.run(0.0, 100.0, Motion.ENTER, _note)
	motion.step(0.09)
	budget.over = true
	var during := motion.run(0.0, 100.0, Motion.ENTER, _note)
	_verdict.check(during.value == 100.0 and during.is_over(), "over budget, new motion is at its end at once: %s" % [during.value])
	_verdict.check(not before.is_over() and before.value < 100.0, "what was already running runs on: %s" % [before.value])
	motion.step(0.09)
	_verdict.check(before.value == 100.0, "to its end")
	budget.over = false
	var after := motion.run(0.0, 100.0, Motion.ENTER, _note)
	_verdict.check(after.value == 0.0 and not after.is_over(), "recovered, motion moves again")
	budget.free()
	motion.free()
	root.theme = null


func _a_run_whose_node_is_gone_is_dropped_and_no_tokens_move_nothing() -> void:
	var motion := _clock(Chimes.new(Belfry.new()))
	var label := Label.new()
	var held := motion.run(0.0, 1.0, Motion.ENTER, label.set_rotation)
	label.free()
	motion.step(0.09)
	_verdict.check(motion.get_running() == 0 and held.value == 0.0, "a run handing its value to a freed node's method is dropped, unstepped: %d" % motion.get_running())
	root.theme = null
	var bare := motion.run(0.0, 100.0, Motion.ENTER, _note)
	_verdict.check(bare.value == 100.0 and bare.is_over(), "under a Theme that says nothing of motion, nothing moves: it is at its end at once")
	motion.free()
