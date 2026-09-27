extends SceneTree

## What must be true of the commands.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_commands.gd
##
## Proved here: a command reaches the model registered for it, with its
## payload, and the model's answer comes back on the same call; a refusal comes
## back as the reason and a done command as nothing; the handler in the
## control's own region is told before the global one, and a region with none
## falls to the global one; an action nobody registered is refused out loud and
## the sentence comes back; a second handler for one address is refused out loud
## and the first keeps it; the last command that ran is read back whole and as
## a copy; COMMAND_RAN rings once per command that ran, in the global region,
## after the last command is kept, and never for one nobody handled; a command
## dispatched while any bell rings is refused out loud, its model never told,
## and the listeners after the one that tried still read the command that ran;
## a dropped region's handlers are forgotten while the global ones stand; and
## a command that moves the reader is put to the mover before its handler is
## told, a stop answering for it with nothing told.
##
## A refusal is heard through a logger that counts only what is pushed as an
## error, as test_actions.gd does.

const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Commands := preload("res://addons/gd_chime/commands.gd")
const Verdict := preload("res://tests/verdict.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")

const REGION := &"a_screen"
const TURN := &"turn_page"

var _verdict := Verdict.new()
var _hearing := Hearing.new()


## Counts what is pushed as an error, which is how the commands say no.
class Hearing extends Logger:
	var refusals: int = 0

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_ERROR:
			refusals += 1


## Stands in for a model: keeps what it was told, and answers as it was set to.
class Model extends RefCounted:
	var told_actions: Array[StringName] = []
	var told_payloads: Array[Dictionary] = []
	var refusal: Phrase = null

	func would(_action: StringName, _payload: Dictionary) -> Phrase:
		return null

	func told(action: StringName, payload: Dictionary) -> Phrase:
		told_actions.append(action)
		told_payloads.append(payload)
		return refusal


## Hears the bell, and reads the last command as it arrives.
class Ear extends RefCounted:
	var commands: Commands
	var heard_last: Array[Dictionary] = []

	func _init(given: Commands) -> void:
		commands = given

	func heard(_what: StringName) -> void:
		heard_last.append(commands.get_last())


## Hears the bell and dispatches another command from inside the ring, as a
## guided step moving on might; keeps the answer it got.
class Nester extends RefCounted:
	var commands: Commands
	var answer: Phrase = null

	func _init(given: Commands) -> void:
		commands = given

	func heard(_what: StringName) -> void:
		answer = commands.dispatch(REGION, &"next_step", {})


func _init() -> void:
	OS.add_logger(_hearing)
	await _verdict.states(_a_command_reaches_its_model_with_its_payload_and_the_answer_comes_back)
	await _verdict.states(_the_region_s_own_handler_is_told_before_the_global_one)
	await _verdict.states(_an_action_nobody_registered_is_refused_out_loud)
	await _verdict.states(_a_second_handler_for_one_address_is_refused_and_the_first_keeps_it)
	await _verdict.states(_the_last_command_is_read_back_whole_and_as_a_copy)
	await _verdict.states(_command_ran_rings_once_per_command_after_it_is_kept)
	await _verdict.states(_a_command_dispatched_while_the_bell_rings_is_refused_and_the_rest_still_read_the_first)
	await _verdict.states(_a_dropped_region_s_handlers_are_forgotten_and_the_global_ones_stand)
	await _verdict.states(_the_command_running_is_the_last_command_while_it_runs)
	await _verdict.states(_a_press_that_goes_somewhere_is_handed_to_the_mover_unless_its_handler_refused)
	await _verdict.states(_a_command_that_moves_the_reader_is_put_to_the_mover_before_its_handler_is_told_and_a_stop_answers_for_it)
	OS.remove_logger(_hearing)
	quit(_verdict.deliver(get_script()))


## Commands on chimes of their own, as [commands, chimes].
func _made() -> Array:
	var chimes := Chimes.new(Belfry.new())
	return [Commands.new(chimes), chimes]


func _a_command_reaches_its_model_with_its_payload_and_the_answer_comes_back() -> void:
	var made := _made()
	var commands: Commands = made[0]
	var model := Model.new()
	commands.register(REGION, TURN, model)

	var done := commands.dispatch(REGION, TURN, {"to": 4})
	_verdict.check(model.told_actions == [TURN] and model.told_payloads == [{"to": 4}], "the model was told the action with its payload: %s %s" % [model.told_actions, model.told_payloads])
	_verdict.check(done == null, "and a command it did comes back as nothing: '%s'" % done)

	model.refusal = Phrase.of("there is no page 9")
	var refused := commands.dispatch(REGION, TURN, {"to": 9})
	_verdict.check(str(refused) == "there is no page 9", "and one it refused comes back as the reason: '%s'" % refused)
	commands.free()


## A model built with a screen answers that screen's commands; a model of the
## application answers from any region that has none of its own.
func _the_region_s_own_handler_is_told_before_the_global_one() -> void:
	var made := _made()
	var commands: Commands = made[0]
	var own := Model.new()
	var global := Model.new()
	commands.register(Chimes.GLOBAL, TURN, global)
	commands.register(REGION, TURN, own)

	commands.dispatch(REGION, TURN, {})
	_verdict.check(own.told_actions == [TURN] and global.told_actions.is_empty(), "in a region with its own handler, that one is told")
	commands.dispatch(&"another_screen", TURN, {})
	_verdict.check(global.told_actions == [TURN] and own.told_actions == [TURN], "and in one with none, the global one is")
	_verdict.check(commands.handles(REGION, TURN) and commands.handles(&"another_screen", TURN) and not commands.handles(REGION, &"other"), "handles() says which addresses are answered")
	commands.free()


func _an_action_nobody_registered_is_refused_out_loud() -> void:
	var made := _made()
	var commands: Commands = made[0]
	var ear := Ear.new(commands)
	(made[1] as Chimes).listen(ear, Chimes.GLOBAL, Commands.COMMAND_RAN)
	var before := _hearing.refusals

	var answer := commands.dispatch(REGION, &"nothing_does_this", {})

	_verdict.check(_hearing.refusals == before + 1, "an action nobody registered is refused out loud")
	_verdict.check(answer != null and str(answer).contains("nothing_does_this"), "and the sentence comes back, naming the action: '%s'" % answer)
	_verdict.check(ear.heard_last.is_empty() and commands.get_last().is_empty(), "and nothing ran: no ring, no last command")
	commands.free()


func _a_second_handler_for_one_address_is_refused_and_the_first_keeps_it() -> void:
	var made := _made()
	var commands: Commands = made[0]
	var first := Model.new()
	var second := Model.new()
	commands.register(REGION, TURN, first)
	var before := _hearing.refusals

	commands.register(REGION, TURN, second)
	commands.dispatch(REGION, TURN, {})

	_verdict.check(_hearing.refusals == before + 1, "a second handler for the same address is refused out loud")
	_verdict.check(first.told_actions == [TURN] and second.told_actions.is_empty(), "and the first keeps the address")
	commands.free()


func _the_last_command_is_read_back_whole_and_as_a_copy() -> void:
	var made := _made()
	var commands: Commands = made[0]
	var model := Model.new()
	model.refusal = Phrase.of("no")
	commands.register(REGION, TURN, model)
	_verdict.check(commands.get_last().is_empty(), "before any command, the last is empty")

	commands.dispatch(REGION, TURN, {"to": 4})
	var last := commands.get_last()
	_verdict.check(last == {"region": REGION, "action": TURN, "payload": {"to": 4}, "answer": last["answer"], "paused": false} and str(last["answer"]) == "no", "the last command is read back whole: %s" % last)
	last["payload"]["to"] = 99
	last["answer"] = "changed"
	_verdict.check(commands.get_last()["payload"]["to"] == 4 and str(commands.get_last()["answer"]) == "no", "and changing what was handed back changes nothing held")
	commands.free()


## Whatever hears the bell reads the command that just ran, not the one
## before it, so the last is kept before the ring.
func _command_ran_rings_once_per_command_after_it_is_kept() -> void:
	var made := _made()
	var commands: Commands = made[0]
	var chimes: Chimes = made[1]
	var ear := Ear.new(commands)
	chimes.listen(ear, Chimes.GLOBAL, Commands.COMMAND_RAN)
	var model := Model.new()
	commands.register(REGION, TURN, model)
	commands.register(REGION, &"ask_again", model)

	commands.dispatch(REGION, TURN, {"to": 4})
	_verdict.check(ear.heard_last.size() == 1 and ear.heard_last[0]["action"] == TURN and ear.heard_last[0]["payload"] == {"to": 4}, "one ring, and the command heard is the one that ran: %s" % [ear.heard_last])
	model.refusal = Phrase.of("not now")
	commands.dispatch(REGION, &"ask_again", {})
	_verdict.check(ear.heard_last.size() == 2 and ear.heard_last[1]["action"] == &"ask_again" and str(ear.heard_last[1]["answer"]) == "not now", "a refused command ran too, and rings with its answer: %s" % [ear.heard_last])
	_verdict.check(commands.region == Chimes.GLOBAL, "and the bell is in the global region: %s" % commands.region)
	commands.free()


## Ian's reproduction: dispatch a, have the first listener dispatch b, and the
## second listener read b twice and never see a. Refusing the nested dispatch
## is what keeps a in front of every listener of a's ring.
func _a_command_dispatched_while_the_bell_rings_is_refused_and_the_rest_still_read_the_first() -> void:
	var made := _made()
	var commands: Commands = made[0]
	var chimes: Chimes = made[1]
	var nester := Nester.new(commands)
	var after := Ear.new(commands)
	chimes.listen(nester, Chimes.GLOBAL, Commands.COMMAND_RAN)
	chimes.listen(after, Chimes.GLOBAL, Commands.COMMAND_RAN)
	var model := Model.new()
	var next := Model.new()
	commands.register(REGION, TURN, model)
	commands.register(REGION, &"next_step", next)
	var before := _hearing.refusals

	commands.dispatch(REGION, TURN, {"to": 4})

	_verdict.check(_hearing.refusals == before + 1 and str(nester.answer).contains("next_step"), "the dispatch from inside the ring is refused out loud, and told so: '%s'" % nester.answer)
	_verdict.check(next.told_actions.is_empty(), "and its model is never told")
	_verdict.check(after.heard_last.size() == 1 and after.heard_last[0]["action"] == TURN, "the listener after it still reads the command that ran: %s" % [after.heard_last])
	_verdict.check(commands.dispatch(REGION, &"next_step", {}) == null and next.told_actions == [&"next_step"], "and once the ring is over, the same command is taken")

	chimes.register(REGION, &"phase_ended")
	chimes.listen(nester, REGION, &"phase_ended")
	# the refusals so far, the one the taken command's own ring drew from the nester included
	var again := _hearing.refusals
	chimes.strike(REGION, &"phase_ended")
	_verdict.check(_hearing.refusals == again + 1 and next.told_actions == [&"next_step"], "and a dispatch from inside any other bell's ring is refused the same way: '%s'" % nester.answer)
	commands.free()


func _a_dropped_region_s_handlers_are_forgotten_and_the_global_ones_stand() -> void:
	var made := _made()
	var commands: Commands = made[0]
	var own := Model.new()
	var global := Model.new()
	commands.register(REGION, TURN, own)
	commands.register(Chimes.GLOBAL, &"open_settings", global)
	var before := _hearing.refusals

	commands.drop_region(REGION)

	commands.dispatch(REGION, TURN, {})
	_verdict.check(own.told_actions.is_empty() and _hearing.refusals == before + 1, "the dropped region's handler is gone, so its action is refused out loud")
	commands.dispatch(REGION, &"open_settings", {})
	_verdict.check(global.told_actions == [&"open_settings"], "while the global one still answers")
	commands.register(REGION, TURN, own)
	_verdict.check(_hearing.refusals == before + 1, "and the region made again registers without a word")
	commands.free()


## Reads the last command back from inside its own run.
class Peeking extends RefCounted:
	var commands: Commands
	var saw: Dictionary = {}

	func would(_action: StringName, _payload: Dictionary) -> Phrase:
		return null

	func _init(given: Commands) -> void:
		commands = given

	func told(_action: StringName, _payload: Dictionary) -> Phrase:
		saw = commands.get_last()
		return Phrase.of("no")


func _the_command_running_is_the_last_command_while_it_runs() -> void:
	var chimes := Chimes.new(Belfry.new())
	var commands := Commands.new(chimes)
	var peeking := Peeking.new(commands)
	commands.register(&"a_screen", &"peeks", peeking)
	commands.dispatch(&"a_screen", &"peeks", {"at": 1})
	_verdict.check(peeking.saw["action"] == &"peeks" and peeking.saw["payload"] == {"at": 1} and peeking.saw["answer"] == null, "while it runs, the last command is this one, its answer still empty: %s" % [peeking.saw])
	_verdict.check(str(commands.get_last()["answer"]) == "no", "and after, the answer is filled in: %s" % [commands.get_last()])
	commands.free()


## Stands in for the driver: notes where it was told to go, with a command of its own,
## and stops to ask about the actions it was set to, noting every command put to it.
class Mover extends RefCounted:
	const COMMANDS: Array[StringName] = [&"arrive_at"]
	var moved: Array = []
	var door: Object = null
	var declared: Dictionary = {}  # region -> {action -> where it goes}
	var stopping: Dictionary = {}  # action -> the words it stops that command to ask
	var asked: Array = []  # every command put to it before its handler was told, as [region, action]

	func goes_to(in_region: StringName, action: StringName) -> StringName:
		return (declared.get(in_region, {}) as Dictionary).get(action, &"")

	func would_move(goes_to: StringName, _parameter: Variant = null) -> Phrase:
		return null if goes_to != &"nowhere" else Phrase.of("nowhere is no place to go to")

	func stops_to_ask(in_region: StringName, action: StringName, _payload: Dictionary) -> Phrase:
		asked.append([in_region, action])
		return stopping.get(action)

	func would(_action: StringName, _payload: Dictionary) -> Phrase:
		return null

	func told(_action: StringName, _payload: Dictionary) -> Phrase:
		moved.append(&"by command")
		return null

	func move(goes_to: StringName, _parameter: Variant = null) -> Phrase:
		moved.append(goes_to)
		return null

	## Nothing presented to bring in line: the door's last step, a no-op here.
	func settle() -> void:
		pass


## Would refuse every command asked of it, and counts the times it is told.
class Refusing extends RefCounted:
	var told_count: int = 0

	func would(_action: StringName, _payload: Dictionary) -> Phrase:
		return Phrase.of("not now")

	func told(_action: StringName, _payload: Dictionary) -> Phrase:
		told_count += 1
		return null


func _a_press_that_goes_somewhere_is_handed_to_the_mover_unless_its_handler_refused() -> void:
	var chimes := Chimes.new(Belfry.new())
	var mover := Mover.new()
	var commands := Commands.new(chimes, mover)
	_verdict.check(commands.dispatch(&"a_screen", &"arrive_at", {}) == null and mover.moved == [&"by command"], "built with the mover, the door registered it for its own commands")
	mover.moved.clear()
	var before := _hearing.refusals
	mover.declared[&"a_screen"] = {&"opens": &"ledger", &"leaves": &"home", &"stays": &"nowhere"}
	_verdict.check(commands.dispatch(&"a_screen", &"opens", {}) == null and mover.moved == [&"ledger"], "a press that goes somewhere by its region's declaration, with no handler, is handed to the mover, with no word: %s" % [mover.moved])
	_verdict.check(commands.get_last()["action"] == &"opens" and _hearing.refusals == before, "and recorded under its action")
	_verdict.check(commands.dispatch(&"a_screen", &"opens", {"goes_to": &"nowhere"}) == null and mover.moved == [&"ledger", &"ledger"], "a payload saying where to go is game data, not navigation: the declaration decides")
	mover.declared[&"a_screen"][&"opens"] = &"nowhere"
	_verdict.check(str(commands.dispatch(&"a_screen", &"opens", {})) == "nowhere is no place to go to" and mover.moved == [&"ledger", &"ledger"], "a move the mover would refuse stops the press, its refusal the answer, and nothing moved")
	var refusing := Refusing.new()
	commands.register(&"a_screen", &"leaves", refusing)
	_verdict.check(str(commands.dispatch(&"a_screen", &"leaves", {})) == "not now" and mover.moved == [&"ledger", &"ledger"] and refusing.told_count == 0, "a handler that would refuse stops the press: it is not told, and the mover is not moved")
	var counted := Model.new()
	commands.register(&"a_screen", &"stays", counted)
	_verdict.check(str(commands.dispatch(&"a_screen", &"stays", {})) == "nowhere is no place to go to" and counted.told_actions.is_empty(), "and a move refused stops the press before its handler is told")
	_verdict.check(str(commands.refusal(&"a_screen", &"leaves", {})) == "not now" and str(commands.refusal(&"a_screen", &"stays", {})) == "nowhere is no place to go to" and commands.game_refusal(&"a_screen", &"stays", {}) == null, "asked without pressing: the handler's refusal, the move's, and the game's alone which reads no navigation")
	_verdict.check(commands.dispatch(&"a_screen", &"waves", {}) != null and _hearing.refusals == before + 1, "and a press going nowhere with no handler is refused out loud as ever")
	commands.free()


## A move that would leave a place asking first is the mover's to stop: the
## door puts every command that moves the reader to it past the refusal and
## before any handler is told, so a stopped press has changed nothing; the
## refusal a button draws by never asks it, so the button stays pressable.
func _a_command_that_moves_the_reader_is_put_to_the_mover_before_its_handler_is_told_and_a_stop_answers_for_it() -> void:
	var chimes := Chimes.new(Belfry.new())
	var mover := Mover.new()
	var commands := Commands.new(chimes, mover)
	var model := Model.new()
	mover.declared[&"a_screen"] = {&"files_and_goes": &"home", &"writes": &""}
	commands.register(&"a_screen", &"files_and_goes", model)
	commands.register(&"a_screen", &"writes", model)
	mover.stopping[&"files_and_goes"] = Phrase.of("leave without saving?")
	var answer := commands.dispatch(&"a_screen", &"files_and_goes", {"line": "half"})
	_verdict.check(str(answer) == "leave without saving?" and model.told_actions.is_empty() and mover.moved.is_empty(), "a press stopped by the mover is answered with its words, its handler never told and nothing moved: %s %s" % [answer, model.told_actions])
	_verdict.check(commands.get_last()["action"] == &"files_and_goes" and commands.get_last()["answer"] == answer and commands.get_last()["paused"], "and it is in the record not done, with that answer, and paused - refused by nobody: %s" % [commands.get_last()])
	_verdict.check(commands.refusal(&"a_screen", &"files_and_goes", {}) == null and mover.asked == [[&"a_screen", &"files_and_goes"]], "the refusal a button draws by never puts it to the mover: the button stays pressable: %s" % [mover.asked])
	commands.dispatch(&"a_screen", &"writes", {})
	_verdict.check(mover.asked.size() == 1 and model.told_actions == [&"writes"], "a command that moves no one is never put to it: %s" % [mover.asked])
	commands.dispatch(&"a_screen", &"arrive_at", {})
	_verdict.check(mover.asked.back() == [&"a_screen", &"arrive_at"] and mover.moved == [&"by command"], "one of the mover's own is put to it too, and not stopped is told: %s" % [mover.asked])
	mover.stopping.clear()
	_verdict.check(commands.dispatch(&"a_screen", &"files_and_goes", {}) == null and model.told_actions == [&"writes", &"files_and_goes"] and mover.moved == [&"by command", &"home"], "not stopped, the handler is told, then the reader moved: %s" % [mover.moved])
	model.refusal = Phrase.of("the drawer is stuck")
	_verdict.check(str(commands.dispatch(&"a_screen", &"files_and_goes", {})) == "the drawer is stuck" and not commands.get_last()["paused"], "and a command its handler refuses is refused, never paused: %s" % [commands.get_last()])
	commands.free()
