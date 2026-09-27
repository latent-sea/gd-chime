extends SceneTree

## What must be true of a control that performs an action.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_action_control.gd
##
## Proved here: a usable press dispatches its action once, in its own region,
## with what its press carries, and the model registered there is told; handed
## nothing to listen to, it listens to nothing, follows what its handler's
## refusal reads as it draws, and can be used while the door would not refuse; while the model would refuse a press dispatches nothing
## and it says why, saying nothing while it can; whether it can be used is
## asked of the door as the press lands; the model's refusal
## is kept for the face until a press is done or what it was built listening to
## rings, and stands through the prompts moving;
## what a press carries is the subclass's; it glows while the prompts name its
## action - as it arrives, not once the prompt moves, again when given that
## action while showing, every control performing the action alike, not once
## withdrawn - and one with no action does not glow while nothing is raised;
## given the prompts while showing it draws again, and rebound it still hears
## them; a press of a control is its action taken by the record when the
## model did it, and not when it refused; it reads where it goes from its
## place's declaration, live; and it glows only while the door would not
## refuse it.
##
## Presses are pushed through the engine onto a bare control that draws nothing
## and counts its draws, since what it does is asserted here and how a button
## looks is asserted in test_bell_button.gd.

const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Commands := preload("res://addons/gd_chime/commands.gd")
const ActionControl := preload("res://addons/gd_chime/action_control.gd")
const Actions := preload("res://addons/gd_chime/actions.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Index := preload("res://addons/gd_chime/index.gd")
const Place := preload("res://addons/gd_chime/place.gd")
const Taken := preload("res://addons/gd_chime/taken.gd")
const Prompts := preload("res://addons/gd_chime/prompts.gd")
const Verdict := preload("res://tests/verdict.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Reads := preload("res://addons/gd_chime/reads.gd")

const REGION := &"home"
const CENTRE := Vector2(80, 40)

var _verdict := Verdict.new()
var _hearing := Hearing.new()


## Counts the refusals pushed as errors.
class Hearing extends Logger:
	var refusals: int = 0

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array) -> void:
		if error_type == ERROR_TYPE_ERROR:
			refusals += 1


## Stands in for a model: keeps what it was told, answers as it was set to,
## and would refuse every press while set to.
class Model extends RefCounted:
	var told_actions: Array[StringName] = []
	var told_payloads: Array[Dictionary] = []
	var refusal: Phrase = null
	var refused: Phrase = null
	var reads: Array = []  # the bells its refusal reads, noted as it is asked

	func would(_action: StringName, _payload: Dictionary) -> Phrase:
		# every bell the refusal reads, noted for whatever is following the read
		for at: Array in reads:
			Reads.note(at[0], at[1])
		return refused

	func told(action: StringName, payload: Dictionary) -> Phrase:
		told_actions.append(action)
		told_payloads.append(payload)
		return refusal


## The smallest control that performs an action: it draws nothing and counts
## its draws.
class Bare extends ActionControl:
	var drawn := 0

	func refresh() -> void:
		drawn += 1


## A control whose press says which entry it shows.
class Row extends Bare:
	var entry := 3

	func payload() -> Dictionary:
		return {"entry": entry}


func _init() -> void:
	# the first frame's signal comes before any node has been processed; after it, one await is one processed frame
	await process_frame
	# the headless window is 64 by 64 and puts back a size set before the first frame, so it is sized now
	root.size = Vector2i(400, 400)
	# the pointer tests measure in the window's own pixels: the base-size stretch the project sets is off here
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	OS.add_logger(_hearing)
	await _verdict.states(_a_usable_press_dispatches_its_action_once_in_its_region)
	await _verdict.states(_it_follows_what_its_handler_s_refusal_reads_and_hears_the_driver_when_it_goes_somewhere)
	await _verdict.states(_while_the_model_would_refuse_a_press_dispatches_nothing_and_it_says_why)
	await _verdict.states(_whether_it_can_be_used_is_asked_of_the_door_as_the_press_lands)
	await _verdict.states(_a_refusal_is_kept_until_a_press_is_done)
	await _verdict.states(_what_a_press_carries_is_the_subclass_s_and_a_link_s_carries_where_it_goes)
	await _verdict.states(_it_glows_while_the_prompts_name_its_action)
	await _verdict.states(_given_the_prompts_while_showing_it_draws_and_rebound_it_still_hears_them)
	await _verdict.states(_a_press_of_a_part_in_the_map_is_its_action_taken_when_done)
	await _verdict.states(_it_reads_where_it_goes_from_its_place_live)
	await _verdict.states(_it_glows_only_while_the_door_would_not_refuse_it)
	OS.remove_logger(_hearing)
	quit(_verdict.deliver(get_script()))


## Chimes, commands on them, a model registered for this action in REGION,
## and the place REGION declaring it, as {chimes, commands, model, driver, place}.
func _wired(action: StringName) -> Dictionary:
	var chimes := Chimes.new(Belfry.new())
	var driver := Driver.new(chimes)
	var commands := Commands.new(chimes, driver)
	var model := Model.new()
	commands.register(REGION, action, model)
	# a driver and a place the reader is at, so a control in it can be reached
	root.add_child(driver)
	var place := Place.new(chimes, REGION, driver)
	place.performs[action] = &""
	driver.index.app = place
	root.add_child(place)
	# a place fits what it holds to itself; these controls are set where they stand by hand, on a holder that places nothing
	var holder := Control.new()
	place.add_child(holder)
	return {"chimes": chimes, "commands": commands, "model": model, "driver": driver, "place": place, "holder": holder}


## A bare control of the place for this action, which the place declares
## if it did not, parented at the top left, a hundred and sixty by eighty -
## or, at, lower down.
func _made(wired: Dictionary, identity: StringName, at: Vector2 = Vector2.ZERO) -> Bare:
	if identity != &"" and not (wired["place"] as Place).performs.has(identity):
		(wired["place"] as Place).performs[identity] = &""
	var bare := Bare.new(wired["chimes"], wired["commands"], wired["place"], identity)
	bare.position = at
	bare.size = Vector2(160, 80)
	(wired["holder"] as Node).add_child(bare)
	# the reader arrives once the first control is in, so the place fills with something drawing what it declares
	if (wired["driver"] as Driver).get_top().is_empty():
		(wired["commands"] as Commands).dispatch(Chimes.GLOBAL, Driver.GO, {"place": REGION})
	return bare


## Prompts with one source over a register of two actions, the prompt raised
## at the first, on the wiring given, as {actions, prompts}.
func _prompted(wired: Dictionary) -> Dictionary:
	var actions := Actions.new()
	actions.declare_all({&"add_one": ["adds one"]})
	actions.declare_all({&"elsewhere": ["goes elsewhere"]})
	var prompts := Prompts.new(wired["chimes"], actions, [&"guide"])
	prompts.raise(&"guide", &"add_one")
	return {"actions": actions, "prompts": prompts}


## process_frame is emitted BEFORE nodes are processed, so the effect of a
## frame is only visible once the next one has come round.
func _a_frame_passes() -> void:
	await process_frame
	await process_frame


func _click(at: Vector2) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = at
	root.push_input(click)


func _done(wired: Dictionary, controls: Array) -> void:
	# every control made, freed, then the place, the driver and the commands
	for control: Node in controls:
		control.free()
	(wired["place"] as Node).free()
	(wired["driver"] as Node).free()
	(wired["commands"] as Node).free()


## Nothing hands it an address: it dispatches what it is, where it is, and the
## model registered there is told, with a payload that carries nothing.
func _a_usable_press_dispatches_its_action_once_in_its_region() -> void:
	var wired := _wired(&"add_one")
	var model: Model = wired["model"]
	var bare := _made(wired, &"add_one")
	await _a_frame_passes()

	_click(CENTRE)
	await _a_frame_passes()
	_verdict.check(model.told_actions == [&"add_one"] and model.told_payloads == [{}], "a press tells the model its action, once, carrying nothing: %s %s" % [model.told_actions, model.told_payloads])
	_verdict.check(bare.get_refusal() == null, "and a press the model did leaves no refusal")
	_done(wired, [bare])


func _it_follows_what_its_handler_s_refusal_reads_and_hears_the_driver_when_it_goes_somewhere() -> void:
	var wired := _wired(&"add_one")
	var bare := _made(wired, &"add_one")
	var chimes: Chimes = wired["chimes"]

	_verdict.check(bare.listening_to().is_empty() and chimes.followed_by(bare, ActionControl.DRAWN).is_empty() and bare.region == REGION, "its handler's refusal reading nothing, it listens to nothing and follows nothing, in its place's region")
	chimes.register(REGION, &"phase_ended")
	(wired["model"] as Model).reads = [[REGION, &"phase_ended"]]
	var hearing := _made(wired, &"add_one", Vector2(0, 300))
	Reads.begin()
	hearing.get_reason()
	var read: Array = Reads.end().keys()
	_verdict.check(read == [Reads.hung(REGION, &"phase_ended")], "its handler's refusal reading a bell, asking whether it can be used reads that, for whatever draws it to follow: %s" % [read])
	(wired["place"] as Place).performs[&"goes_home"] = REGION
	var link := _made(wired, &"goes_home", Vector2(0, 100))
	_verdict.check(link.listening_to() == [Driver.NAVIGATED], "but one whose action goes somewhere hears the driver by itself, so its look follows every move: %s" % [link.listening_to()])
	link.listen([])
	_verdict.check(link.listening_to() == [Driver.NAVIGATED], "and rebound, still: %s" % [link.listening_to()])
	var before := _hearing.refusals
	var stray := Bare.new(wired["chimes"], wired["commands"], wired["place"], &"undeclared")
	_verdict.check(_hearing.refusals == before + 1, "a control for an action its place does not declare is reported as it is built: %d" % (_hearing.refusals - before))
	_verdict.check(bare.is_usable() and bare.get_reason() == null, "and can be used, with no reason not to")
	_done(wired, [bare, hearing, link, stray])


func _while_the_model_would_refuse_a_press_dispatches_nothing_and_it_says_why() -> void:
	var wired := _wired(&"add_one")
	var model: Model = wired["model"]
	model.refused = Phrase.of("not in this phase")
	var bare := _made(wired, &"add_one")
	await _a_frame_passes()

	_click(CENTRE)
	await _a_frame_passes()
	_verdict.check(model.told_actions.is_empty(), "a press the model would refuse tells the model nothing")
	_verdict.check(not bare.is_usable() and str(bare.get_reason()) == "not in this phase", "and it says why, in the model's words")
	model.refused = null
	_verdict.check(bare.is_usable() and bare.get_reason() == null, "the model allowing again, it can be used and says nothing")
	_done(wired, [bare])


## The draw shows the answer as it was last frame; the press must not trust it.
func _whether_it_can_be_used_is_asked_of_the_door_as_the_press_lands() -> void:
	var wired := _wired(&"add_one")
	var model: Model = wired["model"]
	var bare := _made(wired, &"add_one")
	await _a_frame_passes()

	model.refused = Phrase.of("closed since")
	_click(CENTRE)
	await _a_frame_passes()
	_verdict.check(model.told_actions.is_empty(), "an answer that changed after the last draw still stops the press")
	_done(wired, [bare])


## A refusal is the model's answer, kept for the face to show where the press
## happened, and it draws once for it.
func _a_refusal_is_kept_until_a_press_is_done() -> void:
	var wired := _wired(&"add_one")
	var model: Model = wired["model"]
	var bare := _made(wired, &"add_one")
	await _a_frame_passes()
	var before := bare.drawn

	model.refusal = Phrase.of("there is no page 9")
	_click(CENTRE)
	await _a_frame_passes()
	_verdict.check(str(bare.get_refusal()) == "there is no page 9", "a press the model refused keeps the reason: '%s'" % bare.get_refusal())
	_verdict.check(bare.drawn == before + 1, "and draws once for it")
	_verdict.check(bare.is_usable(), "while it can still be used: a refusal is not inertness")
	model.refusal = null
	_click(CENTRE)
	await _a_frame_passes()
	_verdict.check(bare.get_refusal() == null, "and the next press done clears it")

	model.refusal = Phrase.of("not enough credits")
	_click(CENTRE)
	await _a_frame_passes()
	(wired["chimes"] as Chimes).register(REGION, &"credits_arrived")
	bare.listen_to(REGION, &"credits_arrived")
	var drawn := bare.drawn
	(wired["chimes"] as Chimes).strike(REGION, &"credits_arrived")
	await _a_frame_passes()
	_verdict.check(bare.get_refusal() == null and bare.drawn == drawn + 1, "and so does what it listens to ringing, with a draw: '%s'" % bare.get_refusal())

	(wired["chimes"] as Chimes).register(REGION, &"wallet_moved")
	model.reads = [[REGION, &"wallet_moved"]]
	model.refusal = Phrase.of("not enough credits")
	_click(CENTRE)
	await _a_frame_passes()
	var standing := bare.get_refusal()
	(wired["chimes"] as Chimes).strike(REGION, &"wallet_moved")
	await _a_frame_passes()
	_verdict.check(str(standing) == "not enough credits" and bare.get_refusal() == null, "and so does what the model's refusal reads moving, though it listens to none of it: '%s' then '%s'" % [standing, bare.get_refusal()])
	model.reads = []

	var prompted := _prompted(wired)
	var prompts: Prompts = prompted["prompts"]
	bare.prompts = prompts
	model.refusal = Phrase.of("not enough credits")
	_click(CENTRE)
	await _a_frame_passes()
	prompts.raise(&"guide", &"elsewhere")
	await _a_frame_passes()
	_verdict.check(str(bare.get_refusal()) == "not enough credits", "while the prompts moving, which says nothing about the credits, leaves it standing: '%s'" % bare.get_refusal())
	prompts.free()
	_done(wired, [bare])


func _what_a_press_carries_is_the_subclass_s_and_a_link_s_carries_where_it_goes() -> void:
	var wired := _wired(&"opens_entry")
	var model: Model = wired["model"]
	var row := Row.new(wired["chimes"], wired["commands"], wired["place"], &"opens_entry")
	row.size = Vector2(160, 80)
	root.add_child(row)
	await _a_frame_passes()

	_click(CENTRE)
	await _a_frame_passes()
	_verdict.check(model.told_payloads == [{"entry": 3}], "a row's press carries which entry it shows: %s" % [model.told_payloads])
	_done(wired, [row])

	var linked := _wired(&"opens_entry")
	var ledger := Place.new(linked["chimes"], &"ledger", linked["driver"])
	root.add_child(ledger)
	(linked["place"] as Place).performs[&"opens_entry"] = &"ledger"
	var link := _made(linked, &"opens_entry")
	link.pressed()
	_verdict.check((linked["model"] as Model).told_payloads == [{}] and (linked["driver"] as Driver).get_top() == [&"ledger"], "and a link's press carries nothing of navigation: the door read where its place says it goes, and moved: %s" % [(linked["driver"] as Driver).get_top()])
	ledger.free()
	_done(linked, [link])


## Whatever action the prompts name when it arrives, wherever the prompt moves
## after, and an action given while it shows - a reused row - all come out the
## same; a second control performing the named action glows too; and a control
## with no action never matches nothing raised.
func _it_glows_while_the_prompts_name_its_action() -> void:
	var wired := _wired(&"add_one")
	var prompted := _prompted(wired)
	var prompts: Prompts = prompted["prompts"]
	var named := _made(wired, &"add_one")
	named.prompts = prompts
	var twin := _made(wired, &"add_one_too", Vector2(0, 200))
	twin.action = &"add_one"
	twin.prompts = prompts
	var nameless := _made(wired, &"", Vector2(0, 100))
	nameless.prompts = prompts
	await _a_frame_passes()
	_verdict.check(named.is_glowing() and twin.is_glowing(), "raised before they arrived, both controls performing the action glow")

	prompts.raise(&"guide", &"elsewhere")
	_verdict.check(not named.is_glowing(), "the prompt moved to another action, it does not")
	named.action = &"elsewhere"
	_verdict.check(named.is_glowing(), "given that action while showing, it glows")
	named.action = &"add_one"
	prompts.withdraw(&"guide")
	_verdict.check(not named.is_glowing() and not nameless.is_glowing(), "withdrawn, neither glows, the one with no action included")
	twin.free()
	prompts.free()
	_done(wired, [named, nameless])


## A reused control may be given its prompts while showing, and is rebound to
## listen to something else; it draws for the one and still hears them after the
## other.
func _given_the_prompts_while_showing_it_draws_and_rebound_it_still_hears_them() -> void:
	var wired := _wired(&"add_one")
	var prompted := _prompted(wired)
	var bare := _made(wired, &"add_one")
	await _a_frame_passes()
	var before := bare.drawn

	bare.prompts = prompted["prompts"]
	await _a_frame_passes()
	_verdict.check(bare.drawn == before + 1 and bare.listening_to() == [Prompts.PROMPT_MOVED], "given the prompts while showing, it draws once and hears them: %s" % [bare.listening_to()])
	bare.listen([])
	_verdict.check(bare.listening_to() == [Prompts.PROMPT_MOVED], "rebound to listen to nothing else, it still hears the prompts: %s" % [bare.listening_to()])
	(prompted["prompts"] as Prompts).free()
	_done(wired, [bare])


## The record hears the commands, so pressing the control is the action taken
## when the model did it, and nothing tells the record; a refused press took
## nothing.
func _a_press_of_a_part_in_the_map_is_its_action_taken_when_done() -> void:
	var wired := _wired(&"add_one")
	var model: Model = wired["model"]
	var prompted := _prompted(wired)
	var taken := Taken.new(wired["chimes"], prompted["actions"], wired["commands"])
	var bare := _made(wired, &"add_one")
	await _a_frame_passes()

	model.refusal = Phrase.of("not now")
	_click(CENTRE)
	await _a_frame_passes()
	_verdict.check(taken.get_taken().is_empty(), "a press the model refused is not the action taken: %s" % [taken.get_taken()])
	model.refusal = null
	_click(CENTRE)
	await _a_frame_passes()
	_verdict.check(taken.get_taken() == [&"add_one"], "a press the model did is its action taken: %s" % [taken.get_taken()])
	(prompted["prompts"] as Prompts).free()
	_done(wired, [bare, taken])


## Where a press goes is read from the place's declaration as it is asked,
## through a box in between, and nothing is copied onto the control.
func _it_reads_where_it_goes_from_its_place_live() -> void:
	var wired := _wired(&"add_one")
	var place: Place = wired["place"]
	var bare := Bare.new(wired["chimes"], wired["commands"], wired["place"], &"add_one")
	var box := Control.new()
	place.add_child(box)
	box.add_child(bare)
	_verdict.check(bare.get_goes_to() == &"" and bare.payload() == {}, "declared going nowhere, its press carries nothing")
	place.performs[&"add_one"] = &"elsewhere"
	_verdict.check(bare.get_goes_to() == &"elsewhere" and bare.payload() == {}, "the place declaring it goes elsewhere, it reads that, and its press still carries only game data: %s" % [bare.payload()])
	_done(wired, [bare])


## The prompts naming its action is not enough: the door must not refuse it -
## the model, or the move - and its place must be on the screen.
func _it_glows_only_while_the_door_would_not_refuse_it() -> void:
	var wired := _wired(&"add_one")
	var model: Model = wired["model"]
	var prompted := _prompted(wired)
	var bare := _made(wired, &"add_one")
	bare.prompts = prompted["prompts"]
	_verdict.check(bare.is_glowing(), "named by the prompts, in the place the reader is at, allowed: it glows")
	model.refused = Phrase.of("not yet")
	_verdict.check(not bare.is_glowing(), "the model refusing, it does not")
	model.refused = null
	(wired["place"] as Place).performs[&"add_one"] = REGION
	_verdict.check(not bare.is_glowing() and str(bare.get_reason()) == "Already at home", "the move refused - it goes where the reader already is - it does not: %s" % bare.get_reason())
	(prompted["prompts"] as Prompts).free()
	_done(wired, [bare])
