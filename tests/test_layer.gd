extends SceneTree

## What must be true of the layer.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_layer.gd
##
## The layer serves from a thread of its own. Proved here is the contract a
## model relies on: an answer comes later and on the main thread, the main
## thread is never held while the layer holds a core, requests are answered in
## order, and stopping joins the thread without waiting out a held core. Every
## layer made here is stopped, because a thread left running is an error the
## engine reports at exit - which the harness reads.

const Layer := preload("res://demo/grid/layer.gd")
const Verdict := preload("res://tests/verdict.gd")

## The most frames to wait for an answer before a property gives up.
const PATIENCE := 20000

var _verdict := Verdict.new()


## Takes answers, and notes which thread each arrived on.
class Catcher extends RefCounted:
	var answers: Array[Dictionary] = []
	var on_main: Array[bool] = []

	func take(answer: Dictionary) -> void:
		answers.append(answer)
		on_main.append(OS.get_thread_caller_id() == OS.get_main_thread_id())


func _init() -> void:
	await _verdict.states(_an_answer_lands_later_and_on_the_main_thread)
	await _verdict.states(_the_main_thread_keeps_running_while_the_layer_holds_a_core)
	await _verdict.states(_requests_are_answered_in_the_order_they_were_made)
	await _verdict.states(_an_add_goes_to_the_front_and_a_page_reads_it_back)
	await _verdict.states(_stopping_does_not_wait_out_a_held_core)
	quit(_verdict.deliver(get_script()))


## Frames pass until this many answers are in, or patience runs out. Answers
## how many frames it took.
func _until_answered(catcher: Catcher, how_many: int) -> int:
	var frames := 0
	# a frame at a time, until that many answers are in or patience runs out
	while catcher.answers.size() < how_many and frames < PATIENCE:
		await process_frame
		frames += 1
	return frames


func _an_answer_lands_later_and_on_the_main_thread() -> void:
	var layer := Layer.new(0, 50, 8)
	var catcher := Catcher.new()

	layer.fetch_page(0, catcher.take)

	_verdict.check(catcher.answers.is_empty(), "nothing is answered within the call that asked")
	await _until_answered(catcher, 1)
	_verdict.check(catcher.answers.size() == 1, "and the answer came")
	_verdict.check(catcher.on_main[0], "on the main thread")
	_verdict.check(catcher.answers[0]["arrivals"] == [8, 7, 6, 5], "with the page asked for, newest first")
	_verdict.check(catcher.answers[0]["count"] == 8, "and the count of the whole")
	layer.stop()


## The whole reason for the thread. A core is held for a second; if the main
## thread were waiting on it, no frame would pass until it was let go.
func _the_main_thread_keeps_running_while_the_layer_holds_a_core() -> void:
	var layer := Layer.new(1000, 0, 0)
	var catcher := Catcher.new()

	layer.add(catcher.take)
	var frames := await _until_answered(catcher, 1)

	_verdict.check(catcher.answers.size() == 1, "the add was answered")
	_verdict.check(frames >= 10, "and %d frames passed on the main thread while the core was held" % frames)
	layer.stop()


func _requests_are_answered_in_the_order_they_were_made() -> void:
	var layer := Layer.new(20, 20, 0)
	var catcher := Catcher.new()

	layer.add(catcher.take)
	layer.add(catcher.take)
	layer.fetch_page(0, catcher.take)
	await _until_answered(catcher, 3)

	_verdict.check(catcher.answers[0]["arrival"] == 1 and catcher.answers[1]["arrival"] == 2, "the adds were answered first, in order")
	_verdict.check(catcher.answers[2]["arrivals"] == [2, 1], "and the page after them, seeing both")
	layer.stop()


func _an_add_goes_to_the_front_and_a_page_reads_it_back() -> void:
	var layer := Layer.new(10, 10, 3)
	var catcher := Catcher.new()

	layer.add(catcher.take)
	layer.fetch_page(0, catcher.take)
	await _until_answered(catcher, 2)

	_verdict.check(catcher.answers[0]["arrival"] == 4 and catcher.answers[0]["count"] == 4, "the new one is numbered after the three already there")
	_verdict.check(catcher.answers[1]["arrivals"] == [4, 3, 2, 1], "and a page reads it back at the front")
	layer.stop()


## A window closing must not wait five seconds for a core to be let go.
func _stopping_does_not_wait_out_a_held_core() -> void:
	var layer := Layer.new(5000, 0, 0)
	var catcher := Catcher.new()
	layer.add(catcher.take)
	await process_frame
	var began := Time.get_ticks_msec()

	layer.stop()

	_verdict.check(Time.get_ticks_msec() - began < 1000, "stopping returned without waiting out the hold")
	_verdict.check(not layer.is_serving(), "and the thread is joined")
