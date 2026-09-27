extends SceneTree

## What must be true of the table model.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_table_model.gd
##
## A model over a layer on another thread. What matters is what it promises a
## screen: what has not landed it has not got and says so; a page is asked for
## once; an add moves everything known up one and is busy from the ask to the
## answer; a page asked for before an add is applied before it and moves with
## it, because the layer answers in the order asked; and the look is its own,
## moved by the scroll commands, never below zero, ringing when it moves and
## not for a move that goes nowhere. The real layer is used, with short holds.

const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Commands := preload("res://addons/gd_chime/commands.gd")
const Layer := preload("res://demo/grid/layer.gd")
const TableModel := preload("res://demo/grid/table_model.gd")
const Verdict := preload("res://tests/verdict.gd")
const Fixture := preload("res://tests/fixture.gd")

const PATIENCE := 20000
const REGION := &"a_screen"

var _verdict := Verdict.new()


func _init() -> void:
	await _verdict.states(_what_has_not_landed_it_has_not_got)
	await _verdict.states(_a_page_is_asked_for_once_however_often)
	await _verdict.states(_an_add_moves_everything_known_up_one)
	await _verdict.states(_it_is_busy_from_the_ask_to_the_answer_and_rings_at_both_ends)
	await _verdict.states(_a_page_asked_for_before_an_add_lands_before_it_and_moves_with_it)
	await _verdict.states(_the_look_is_its_own_moved_by_command_never_below_zero)
	quit(_verdict.deliver(get_script()))


## A model over a layer with these holds and this many already in, with a
## count of its values moving, as [model, layer, ear, chimes, commands].
func _made(add_ms: int, page_ms: int, already: int) -> Array:
	var belfry := Belfry.new()
	var chimes := Chimes.new(belfry)
	var commands := Commands.new(chimes)
	var layer := Layer.new(add_ms, page_ms, already)
	var model := TableModel.new(chimes, layer)
	commands.stand(REGION, model)
	var ear := Fixture.Heard.new(chimes, model.count)
	return [model, layer, ear, chimes, commands]


## Frames pass until the condition holds, or patience runs out.
func _until(condition: Callable) -> void:
	var frames := 0
	# a frame at a time, until the condition holds or patience runs out
	while not condition.call() and frames < PATIENCE:
		await process_frame
		frames += 1


## Frames pass until this much time has.
func _for_ms(ms: int) -> void:
	var until := Time.get_ticks_msec() + ms
	# a frame at a time, until that much time has passed
	while Time.get_ticks_msec() < until:
		await process_frame


func _done(made: Array) -> void:
	(made[1] as Layer).stop()
	(made[2] as Node).free()
	(made[0] as Node).free()
	(made[4] as Node).free()


func _add(made: Array) -> void:
	(made[4] as Commands).dispatch(REGION, TableModel.ADD_ARRIVAL, {})


func _what_has_not_landed_it_has_not_got() -> void:
	var made := _made(0, 10, 8)
	var model: TableModel = made[0]

	_verdict.check(model.count() == 0 and not model.has(0), "before anything lands it has nothing, and says so")
	await _until(func() -> bool: return model.has(0))
	_verdict.check(model.count() == 8, "the first page brought the count")
	_verdict.check(model.get_arrival(0) == 8 and model.get_arrival(3) == 5, "and the page's arrivals under their indices")
	_verdict.check(not model.has(4), "and nothing beyond it")
	model.fetch(6)
	await _until(func() -> bool: return model.has(6))
	_verdict.check(model.get_arrival(6) == 2 and model.has(4), "asked for, the page holding 6 lands whole")
	_done(made)


func _a_page_is_asked_for_once_however_often() -> void:
	var made := _made(0, 30, 8)
	var model: TableModel = made[0]
	var ear: Fixture.Heard = made[2]

	model.fetch(1)
	model.fetch(2)
	model.fetch(3)
	await _until(func() -> bool: return model.has(0))
	await _for_ms(100)

	_verdict.check(ear.rung == 1, "one page landed and rang once, however often it was asked for")
	_done(made)


func _an_add_moves_everything_known_up_one() -> void:
	var made := _made(10, 10, 8)
	var model: TableModel = made[0]
	await _until(func() -> bool: return model.has(0))

	_add(made)
	await _until(func() -> bool: return not model.is_busy())

	_verdict.check(model.count() == 9, "one more")
	_verdict.check(model.get_arrival(0) == 9, "at the front")
	_verdict.check(model.get_arrival(1) == 8 and model.get_arrival(4) == 5, "and everything known moved up one")
	_done(made)


func _it_is_busy_from_the_ask_to_the_answer_and_rings_at_both_ends() -> void:
	var made := _made(50, 10, 2)
	var model: TableModel = made[0]
	var ear: Fixture.Heard = made[2]
	await _until(func() -> bool: return model.has(0))
	await process_frame
	var rings_before := ear.rung

	_add(made)

	_verdict.check(model.is_busy(), "busy the moment the ask goes out")
	await process_frame
	_verdict.check(ear.rung == rings_before + 1, "and it rang to say so, at the frame's end")
	await _until(func() -> bool: return not model.is_busy())
	await process_frame
	_verdict.check(ear.rung == rings_before + 2, "and rang again when the answer landed")
	_done(made)


## The layer answers in the order asked, so a page asked for before an add
## lands before it, and the add then moves it up one with everything else.
func _a_page_asked_for_before_an_add_lands_before_it_and_moves_with_it() -> void:
	var made := _made(10, 150, 8)
	var model: TableModel = made[0]
	await _until(func() -> bool: return model.has(0))

	model.fetch(7)
	_add(made)
	await _until(func() -> bool: return not model.is_busy())

	_verdict.check(model.count() == 9, "the add landed")
	_verdict.check(model.get_arrival(4) == 5 and model.get_arrival(8) == 1, "after the page it was asked after, which moved up one with the rest")
	_done(made)


## Where the table looks is the model's, not the screen's: a scroll command
## moves it, it rings when it moves, and it never goes below zero.
func _the_look_is_its_own_moved_by_command_never_below_zero() -> void:
	var made := _made(0, 10, 8)
	var model: TableModel = made[0]
	var commands: Commands = made[4]
	# the first page landed first: the model rings for everything it holds, its look among it
	await _until(func() -> bool: return model.has(0))
	await process_frame
	var moves := Fixture.Heard.new(made[3], model.get_first)

	_verdict.check(model.get_first() == 0, "it starts at the top")
	var done := commands.dispatch(REGION, TableModel.SCROLL_TABLE_DOWN, {})
	await process_frame
	_verdict.check(done == null and model.get_first() == 1 and moves.rung == 1, "down: one row on, done, and rang once")
	commands.dispatch(REGION, TableModel.SCROLL_TABLE_UP, {})
	await process_frame
	_verdict.check(model.get_first() == 0 and moves.rung == 2, "up: back to the top, and rang")
	commands.dispatch(REGION, TableModel.SCROLL_TABLE_UP, {})
	await process_frame
	_verdict.check(model.get_first() == 0 and moves.rung == 2, "up at the top goes nowhere, and rings nothing")
	moves.free()
	_done(made)
