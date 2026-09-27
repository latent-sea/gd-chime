extends SceneTree

## What must be true of both controller kinds.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_controller.gd
##
## Neither kind here ever holds a bell. Each is given addresses to listen to
## and models to read, and rings through the chimes by name. This file holds
## the belfry and builds the models, standing in for whatever composes an
## application.
##
## The two differ in one thing and it is checked hardest: a controller with no
## reader does its work at once, and one that draws waits for the frame.
##
## The request and the answer are proved here too, because they are what the
## two kinds are for: a screen hangs a return address, a model rings it later,
## and an answer to a screen that has closed lands nowhere.

const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Controller := preload("res://addons/gd_chime/controller.gd")
const Presentation := preload("res://addons/gd_chime/presentation.gd")
const Verdict := preload("res://tests/verdict.gd")

var _verdict := Verdict.new()
var _host: Control


## A model: two numbers, each with a bell it rings when that number changes.
## It is the one place the numbers live; nothing else holds a copy.
class Sums extends Controller:
	var _left := 0
	var _right := 0

	func _init(chimes: Chimes, in_region: StringName) -> void:
		super(chimes, [], in_region)
		register_bell(&"left_changed")
		register_bell(&"right_changed")

	func get_left() -> int:
		return _left

	func get_right() -> int:
		return _right

	func set_left(value: int) -> void:
		_left = value
		strike(region, &"left_changed")

	func set_right(value: int) -> void:
		_right = value
		strike(region, &"right_changed")


## No screen: it recomputes the instant it is rung, reading the model it was
## handed.
class Tally extends Controller:
	var total := 0
	var reads := 0
	var _sums: Sums

	func _init(chimes: Chimes, sums: Sums, listening: Array, in_region: StringName) -> void:
		super(chimes, listening, in_region)
		_sums = sums

	func heard(what: StringName) -> void:
		match what:
			&"left_changed", &"right_changed", &"late_changed":
				reads += 1
				total = _sums.get_left() + _sums.get_right()


## Rings a bell from inside a frame, the way anything driven by _process does.
## Ringing from this test's own coroutine instead would not do: that runs before
## nodes are processed, and the half-rate defect below only appears when the
## wake lands in the same frame as the draw.
class Waker extends Node:
	var chimes: Chimes
	var woke := 0

	func _process(_delta: float) -> void:
		woke += 1
		chimes.strike(Chimes.GLOBAL, &"price_changed")


## A screen: it draws, once a frame.
class Surface extends Presentation:
	var drawn := 0
	var noticed := 0

	func heard(what: StringName) -> void:
		match what:
			&"price_changed":
				needs_refresh()
			&"shown":
				# alters nothing on screen, so it asks for no draw
				noticed += 1

	func refresh() -> void:
		drawn += 1


## A screen that can be pressed and can hold focus.
class Pressable extends Presentation:
	var presses := 0
	var focus_told: Array[bool] = []

	func pressed() -> void:
		presses += 1

	func focused(has_it: bool) -> void:
		focus_told.append(has_it)


## A model that answers a request later. It is handed a return address and
## rings it when the answer is ready - here, deferred to the end of the frame,
## which is the earliest "later" there is.
class Answerer extends Controller:
	func ask(in_region: StringName, name: StringName) -> void:
		strike.call_deferred(in_region, name)


## A screen that asks a question as it is built and hangs the bell the answer
## will ring.
class Asker extends Presentation:
	var answered := 0

	func _init(chimes: Chimes, answerer: Answerer, in_region: StringName) -> void:
		super(chimes, [], in_region)
		register_bell(&"answered")
		listen_to(in_region, &"answered")
		answerer.ask(in_region, &"answered")

	func heard(_what: StringName) -> void:
		answered += 1


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	# a Control, not a Node: the engine carries a look down through Controls only
	_host = Control.new()
	root.add_child(_host)

	await _verdict.states(_a_controller_does_its_work_at_once)
	await _verdict.states(_its_connections_are_made_as_it_is_built)
	await _verdict.states(_listening_again_replaces_what_was_connected)
	await _verdict.states(_one_can_be_added_after_building)
	await _verdict.states(_one_can_be_dropped_by_name)
	await _verdict.states(_its_connections_at_construction_are_in_its_region)
	await _verdict.states(_a_bell_it_hangs_is_in_its_own_region)
	await _verdict.states(_a_freed_controller_leaves_no_connection)
	await _verdict.states(_a_screen_says_the_room_it_will_need_and_measuring_only_raises_it)
	await _verdict.states(_a_screen_draws_what_is_already_there)
	await _verdict.states(_a_screen_waits_for_the_frame)
	await _verdict.states(_many_wakes_are_one_draw)
	await _verdict.states(_a_handler_may_decide_not_to_draw)
	await _verdict.states(_a_new_look_on_the_root_redraws_a_screen_with_no_bell)
	await _verdict.states(_a_colour_the_look_does_not_have_is_refused_out_loud)
	await _verdict.states(_a_screen_woken_every_frame_draws_every_frame)
	await _verdict.states(_an_untouched_screen_draws_once_and_stops)
	await _verdict.states(_a_screen_outside_the_tree_does_not_draw)
	await _verdict.states(_a_press_reaches_the_control_it_landed_on)
	await _verdict.states(_focus_arriving_and_leaving_is_told)
	await _verdict.states(_a_request_is_answered_at_the_address_it_carried)
	await _verdict.states(_an_answer_to_a_closed_screen_lands_nowhere)
	quit(_verdict.deliver(get_script()))


## process_frame is emitted BEFORE nodes are processed, so the effect of a
## frame is only visible once the next one has come round.
func _a_frame_passes() -> void:
	await process_frame
	# the pointer tests measure in the window's own pixels: the base-size stretch the project sets is off here, after the first frame puts the window's settings back
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await process_frame


## A model with two numbers hung in a region, and the chimes over it, handed
## back as [chimes, sums, belfry]. This test builds it because it stands in for
## whatever composes the application; a controller never does.
func _sums(region: StringName = Chimes.GLOBAL) -> Array:
	var belfry := Belfry.new()
	var chimes := Chimes.new(belfry)
	return [chimes, Sums.new(chimes, region), belfry]


func _tally(chimes: Chimes, sums: Sums, region: StringName = Chimes.GLOBAL) -> Tally:
	return Tally.new(chimes, sums, [[region, &"left_changed"], [region, &"right_changed"]], region)


## The whole difference between the two kinds. Something can read what a
## controller produced the instant it changed an input, so it cannot wait.
func _a_controller_does_its_work_at_once() -> void:
	var made := _sums()
	var sums: Sums = made[1]
	var tally := _tally(made[0], sums)

	sums.set_left(3)
	sums.set_right(4)

	_verdict.check(tally.reads == 2, "both wakes arrived at the one entrypoint")
	_verdict.check(tally.total == 7, "and the answer is right immediately, with no frame")
	tally.free()
	sums.free()


## Nothing calls connect but the chimes, driven by what the controller declared.
func _its_connections_are_made_as_it_is_built() -> void:
	var made := _sums()
	var chimes: Chimes = made[0]
	var sums: Sums = made[1]
	var tally := _tally(chimes, sums)

	_verdict.check(chimes.count() == 2, "both addresses are connected")
	_verdict.check(tally.listening_to() == [&"left_changed", &"right_changed"], "and it can say what reaches it")
	tally.free()
	sums.free()


## The escape hatch, for something rebound to different subjects - a pooled
## screen pointed at other content. It must drop what it had, or the old ones
## go on waking it. Rebinding is by ADDRESS: the same two names in another
## region, which is why nothing about the controller itself changes.
func _listening_again_replaces_what_was_connected() -> void:
	var made := _sums()
	var chimes: Chimes = made[0]
	var sums: Sums = made[1]
	var tally := _tally(chimes, sums)
	chimes.register(&"elsewhere", &"left_changed")
	chimes.register(&"elsewhere", &"right_changed")

	tally.listen([[&"elsewhere", &"left_changed"], [&"elsewhere", &"right_changed"]])

	_verdict.check(chimes.count() == 2, "only what was newly declared is connected")
	chimes.strike(&"elsewhere", &"left_changed")
	_verdict.check(tally.reads == 1, "so the new address wakes it")
	sums.set_left(9)
	_verdict.check(tally.reads == 1, "and the old one no longer does")
	tally.free()
	sums.free()


## A controller that gains a subject rather than being rebound to a new set.
func _one_can_be_added_after_building() -> void:
	var made := _sums()
	var chimes: Chimes = made[0]
	var sums: Sums = made[1]
	var tally := _tally(chimes, sums)
	chimes.register(Chimes.GLOBAL, &"late_changed")

	tally.listen_to(Chimes.GLOBAL, &"late_changed")
	chimes.strike(Chimes.GLOBAL, &"late_changed")

	_verdict.check(tally.reads == 1, "one added after building wakes it")
	_verdict.check(chimes.count() == 3, "and is connected alongside the other two")
	tally.free()
	sums.free()


func _one_can_be_dropped_by_name() -> void:
	var made := _sums()
	var chimes: Chimes = made[0]
	var sums: Sums = made[1]
	var tally := _tally(chimes, sums)

	tally.stop_listening_to(&"left_changed")

	sums.set_left(9)
	_verdict.check(tally.reads == 0, "the dropped name no longer reaches it")
	_verdict.check(chimes.count() == 1, "and only the other is still connected")
	tally.free()
	sums.free()


## The region has to arrive with the connections, not after them: a region set
## afterwards would leave everything declared at construction in the wrong one.
func _its_connections_at_construction_are_in_its_region() -> void:
	var made := _sums(&"a_screen")
	var chimes: Chimes = made[0]
	var sums: Sums = made[1]
	var tally := _tally(chimes, sums, &"a_screen")
	_verdict.check(tally.region == &"a_screen", "it is in the region it was given")

	chimes.drop_region(&"a_screen")

	sums.set_left(1)
	_verdict.check(tally.reads == 0, "and dropping that region takes what it declared")
	_verdict.check(chimes.count() == 0, "leaving nothing connected")
	tally.free()
	sums.free()


## A bell a controller hangs - a model's own, or a screen's return address -
## lives in that controller's region, so it goes when the screen does.
func _a_bell_it_hangs_is_in_its_own_region() -> void:
	var made := _sums(&"a_screen")
	var chimes: Chimes = made[0]
	var sums: Sums = made[1]
	var belfry: Belfry = made[2]
	var tally := _tally(chimes, sums, &"a_screen")

	tally.register_bell(&"mine_rang")

	_verdict.check(belfry.has(&"a_screen", &"mine_rang"), "it is hung in the controller's region")
	chimes.drop_region(&"a_screen")
	_verdict.check(not belfry.has(&"a_screen", &"mine_rang"), "and goes when the region does")
	tally.free()
	sums.free()


## Nobody disconnects. A freed controller leaves nothing behind.
func _a_freed_controller_leaves_no_connection() -> void:
	var made := _sums()
	var sums: Sums = made[1]
	var belfry: Belfry = made[2]
	var doomed := _tally(made[0], sums)
	_verdict.check(belfry.at(Chimes.GLOBAL, &"left_changed").changed.get_connections().size() == 1, "a live controller is connected")

	doomed.free()

	_verdict.check(belfry.at(Chimes.GLOBAL, &"left_changed").changed.get_connections().is_empty(), "a freed one leaves no connection")
	sums.set_left(1)
	_verdict.check(sums.get_left() == 1, "and the model still works afterwards")
	sums.free()


## A screen and everything it listens to, handed back as [surface, chimes].
func _screen(parented: bool = true) -> Array:
	var belfry := Belfry.new()
	var chimes := Chimes.new(belfry)
	chimes.register(Chimes.GLOBAL, &"price_changed")
	chimes.register(Chimes.GLOBAL, &"shown")
	var surface := Surface.new(chimes, [[Chimes.GLOBAL, &"price_changed"], [Chimes.GLOBAL, &"shown"]])
	if parented:
		_host.add_child(surface)
	return [surface, chimes]


## Everything a screen shows may already be there before it is built. One that
## waited for a wake would sit blank until something moved, which for anything
## settled is forever.
func _a_screen_draws_what_is_already_there() -> void:
	var made := _screen()
	var surface: Surface = made[0]

	await _a_frame_passes()

	_verdict.check(surface.drawn == 1, "a screen draws without waiting to be woken")
	surface.queue_free()


func _a_screen_waits_for_the_frame() -> void:
	var made := _screen()
	var surface: Surface = made[0]
	var chimes: Chimes = made[1]
	await _a_frame_passes()
	var drawn_by_now := surface.drawn

	chimes.strike(Chimes.GLOBAL, &"price_changed")
	_verdict.check(surface.drawn == drawn_by_now, "nothing more is drawn within the frame")
	await _a_frame_passes()
	_verdict.check(surface.drawn == drawn_by_now + 1, "and the frame draws it once")
	surface.queue_free()


func _many_wakes_are_one_draw() -> void:
	var made := _screen()
	var surface: Surface = made[0]
	var chimes: Chimes = made[1]
	await _a_frame_passes()
	var drawn_by_now := surface.drawn

	chimes.strike(Chimes.GLOBAL, &"price_changed")
	chimes.strike(Chimes.GLOBAL, &"price_changed")
	chimes.strike(Chimes.GLOBAL, &"price_changed")
	await _a_frame_passes()

	_verdict.check(surface.drawn == drawn_by_now + 1, "three wakes, one draw")
	surface.queue_free()


## The reason the handler decides rather than the entrypoint: some wakes alter
## nothing about what is shown.
func _a_handler_may_decide_not_to_draw() -> void:
	var made := _screen()
	var surface: Surface = made[0]
	var chimes: Chimes = made[1]
	await _a_frame_passes()
	var drawn_by_now := surface.drawn

	chimes.strike(Chimes.GLOBAL, &"shown")
	await _a_frame_passes()

	_verdict.check(surface.noticed == 1, "the entrypoint heard it")
	_verdict.check(surface.drawn == drawn_by_now, "and nothing more was drawn, because it asked for nothing")
	surface.queue_free()


## The look is the engine's: a new Theme on the root reaches every screen under
## it the way a resize does, with nothing hung, listened to or struck.
func _a_new_look_on_the_root_redraws_a_screen_with_no_bell() -> void:
	var made := _screen()
	var surface: Surface = made[0]
	var chimes: Chimes = made[1]
	await _a_frame_passes()
	var drawn_by_now := surface.drawn

	root.theme = Themes.new(Themes.NEUTRAL)
	await _a_frame_passes()

	_verdict.check(surface.drawn == drawn_by_now + 1, "a new look on the root redraws the screen")
	_verdict.check(chimes.count() == 2, "and nothing was listened to for it")
	_verdict.check(surface.get_colour(&"ink") == Themes.NEUTRAL[&"ink"], "and the colour it paints with is the look's")
	surface.queue_free()


## The engine answers an unknown colour with a quiet default. A screen asking
## for one is told out loud and painted in a colour nobody would choose, so the
## mistake is on the screen rather than hidden in it.
func _a_colour_the_look_does_not_have_is_refused_out_loud() -> void:
	var made := _screen()
	var surface: Surface = made[0]

	_verdict.check(surface.get_colour(&"nope") == Color.MAGENTA, "a colour the look does not have is painted loud")
	_verdict.check(surface.get_colour(&"ink") == Themes.NEUTRAL[&"ink"], "and one it does have is painted right")
	surface.queue_free()


## The engine applies a change to its process list at the frame boundary and
## the last write in the frame wins, so a screen that gave up processing while
## drawing would draw every OTHER frame once something woke it earlier in the
## same one - a half rate that depends on tree order.
func _a_screen_woken_every_frame_draws_every_frame() -> void:
	var made := _screen(false)
	var surface: Surface = made[0]
	var waker := Waker.new()
	waker.chimes = made[1]
	# parented first, so its wake lands earlier in the frame than the screen's draw
	_host.add_child(waker)
	_host.add_child(surface)

	var frames := 0
	# ten frames, for the waker to wake the screen on each
	while frames < 10:
		await process_frame
		frames += 1

	_verdict.check(waker.woke >= 8, "the waker ran on nearly every frame")
	_verdict.check(surface.drawn >= waker.woke - 1, "and the screen it woke drew on every one of them")
	waker.queue_free()
	surface.queue_free()


func _an_untouched_screen_draws_once_and_stops() -> void:
	var made := _screen()
	var surface: Surface = made[0]

	await _a_frame_passes()
	var drawn_on_arrival := surface.drawn
	await _a_frame_passes()
	await _a_frame_passes()

	_verdict.check(drawn_on_arrival == 1, "a screen nothing has touched draws exactly once")
	_verdict.check(surface.drawn == 1, "and never again while nothing changes")
	_verdict.check(not surface.is_processing(), "and is not on the engine's list")
	surface.queue_free()


## Frames only reach what is in the tree, so being parented is a requirement
## rather than a convenience.
func _a_screen_outside_the_tree_does_not_draw() -> void:
	var made := _screen(false)
	var loose: Surface = made[0]
	var chimes: Chimes = made[1]

	chimes.strike(Chimes.GLOBAL, &"price_changed")
	await _a_frame_passes()
	_verdict.check(loose.drawn == 0, "one outside the tree does not draw")

	_host.add_child(loose)
	await _a_frame_passes()
	_verdict.check(loose.drawn == 1, "and draws once it is parented")
	loose.queue_free()


## A control that can be pressed, at a known place on screen.
func _pressable() -> Pressable:
	var belfry := Belfry.new()
	var chimes := Chimes.new(belfry)
	var target := Pressable.new(chimes, [], Chimes.GLOBAL)
	target.position = Vector2(10, 10)
	target.size = Vector2(100, 40)
	target.focus_mode = Control.FOCUS_ALL
	_host.add_child(target)
	return target


## The engine decides which control a click was for; nothing here hit-tests.
func _a_press_reaches_the_control_it_landed_on() -> void:
	var target := _pressable()
	var elsewhere := _pressable()
	elsewhere.position = Vector2(400, 400)
	await _a_frame_passes()

	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(50, 25)
	root.push_input(click)
	await _a_frame_passes()

	_verdict.check(target.presses == 1, "a press reaches the control it landed on")
	_verdict.check(elsewhere.presses == 0, "and no other")
	target.queue_free()
	elsewhere.queue_free()


func _focus_arriving_and_leaving_is_told() -> void:
	var target := _pressable()
	await _a_frame_passes()

	target.grab_focus()
	target.release_focus()

	_verdict.check(target.focus_told == [true, false], "focus arriving and leaving are both told")
	target.queue_free()


## A screen that has asked a model a question, as [asker, answerer, chimes, belfry].
func _asked() -> Array:
	var belfry := Belfry.new()
	var chimes := Chimes.new(belfry)
	var answerer := Answerer.new(chimes)
	var asker := Asker.new(chimes, answerer, &"a_screen")
	_host.add_child(asker)
	return [asker, answerer, chimes, belfry]


## The request: a screen hands a model its own address and is rung there when
## the answer is ready. The model never learns who asked; the screen never
## learns when the answer will come.
func _a_request_is_answered_at_the_address_it_carried() -> void:
	var made := _asked()
	var asker: Asker = made[0]

	_verdict.check(asker.answered == 0, "nothing has been answered within the call that asked")
	await _a_frame_passes()

	_verdict.check(asker.answered == 1, "the answer rang the address the request carried")
	asker.queue_free()
	(made[1] as Node).free()


## The screen that asked has closed - its region dropped, the return address
## with it - before the answer comes. The answer lands nowhere, and nothing
## complains: quiet is carried by the harness, which fails a suite on any
## engine complaint that is not a push_error.
func _an_answer_to_a_closed_screen_lands_nowhere() -> void:
	var made := _asked()
	var asker: Asker = made[0]
	var chimes: Chimes = made[2]
	var belfry: Belfry = made[3]

	chimes.drop_region(&"a_screen")
	await _a_frame_passes()

	_verdict.check(asker.answered == 0, "a closed screen is not answered")
	_verdict.check(not belfry.has(&"a_screen", &"answered"), "and the return address is gone with its region")
	asker.queue_free()
	(made[1] as Node).free()


## A screen that measures what it holds, so what it was GIVEN and what it
## MEASURES can be told apart.
class Measuring extends Presentation:
	var measures := Vector2.ZERO

	func _get_minimum_size() -> Vector2:
		return measures


## A screen still waiting for its content measures at nothing, so whoever builds
## it says the room it will need when it is full - or a layout would size itself
## to an empty screen and move everything when the content landed. A screen that
## can measure raises that and never drops below it, each axis on its own.
func _a_screen_says_the_room_it_will_need_and_measuring_only_raises_it() -> void:
	var chimes := Chimes.new(Belfry.new())
	var screen := Measuring.new(chimes)
	_host.add_child(screen)
	screen.custom_minimum_size = Vector2(200, 60)
	await _a_frame_passes()

	_verdict.check(screen.get_combined_minimum_size() == Vector2(200, 60),
		"waiting for its content, it holds the room it will need: %s" % screen.get_combined_minimum_size())

	screen.measures = Vector2(300, 20)
	screen.update_minimum_size()
	await _a_frame_passes()

	_verdict.check(screen.get_combined_minimum_size() == Vector2(300, 60),
		"content wider than projected raises it; shallower leaves the projection standing: %s" % screen.get_combined_minimum_size())
	screen.queue_free()
	await _a_frame_passes()
