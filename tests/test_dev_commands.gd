extends SceneTree

## What must be true of the dev commands.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_dev_commands.gd
##
## Proved here: each word after a command's name becomes its parameter's type -
## a whole number, a decimal, true or false, or text, which a StringName or an
## untyped parameter takes too - and the answer comes back; optional parameters
## take their defaults when left off; a word that will not become its parameter's
## type runs nothing and says why, naming the parameter and the word; too few or
## too many words run nothing and answer with the command's usage; words in
## double quotes keep their spaces, a pair of empty quotes is a word, a quote
## left open runs to the end of the line, and extra spaces change nothing; a
## function that returns nothing answers done, a static one is read from its
## script, and a bound one takes words only for the parameters it was not bound;
## the line and its answer reach a real debug log; a name nobody registered runs
## nothing and answers with the names that are, and an empty line says nothing,
## not even to the log; a name registered twice, a parameter no word can become
## and an anonymous function are each refused out loud, and the first command
## stays; and the names are listed in the order registered, each with what it
## does and how it is typed.
##
## The commands here are the suite's own stand-ins, on a ledger that records
## every call on it with the arguments exactly as they arrived.

const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const DebugLog := preload("res://addons/gd_chime/debug_log.gd")
const Commands := preload("res://addons/gd_chime/commands.gd")
const DevCommands := preload("res://addons/gd_chime/dev_commands.gd")
const Verdict := preload("res://tests/verdict.gd")

const FOLDER := "user://test_dev_commands"
const GIVE_USAGE := "give <who: a whole number> <amount: a decimal> [note: text] [loud: true or false]"

var _verdict := Verdict.new()


## A stand-in for what commands reach into: it records every call on it, with
## the arguments exactly as they arrived.
class Ledger extends RefCounted:
	var calls: Array = []

	static func doubled(amount: int) -> int:
		return amount * 2

	func give(who: int, amount: float, note: String = "none", loud: bool = false) -> String:
		calls.append(["give", who, amount, note, loud])
		return "gave %d %s" % [who, amount]

	func tag(account: StringName, label) -> String:
		calls.append(["tag", account, label])
		return "tagged %s %s" % [account, label]

	func reset() -> void:
		calls.append(["reset"])

	func send(amount: int, to: String) -> String:
		calls.append(["send", amount, to])
		return "sent %d to %s" % [amount, to]

	func place(where: Vector2) -> String:
		return "placed at %s" % where


func _init() -> void:
	# the first frame's signal comes before any node has been processed; after it, one await is one processed frame
	await process_frame
	await _verdict.states(_each_word_becomes_its_parameters_type_and_the_answer_comes_back)
	await _verdict.states(_optional_parameters_take_their_defaults_when_left_off)
	await _verdict.states(_a_word_that_will_not_become_its_type_runs_nothing_and_says_why)
	await _verdict.states(_too_few_or_too_many_words_run_nothing_and_answer_with_the_usage)
	await _verdict.states(_quoted_words_keep_their_spaces_even_empty_or_left_open_and_extra_spaces_change_nothing)
	await _verdict.states(_nothing_returned_answers_done_a_static_is_read_from_its_script_a_bound_takes_the_rest)
	await _verdict.states(_the_line_and_its_answer_reach_the_debug_log)
	await _verdict.states(_a_line_dispatched_as_run_line_runs_and_answers_done)
	await _verdict.states(_an_unknown_name_answers_with_the_names_and_an_empty_line_says_nothing)
	await _verdict.states(_a_second_name_a_parameter_no_word_can_become_or_an_anonymous_function_is_refused_out_loud)
	await _verdict.states(_the_names_are_listed_in_order_each_with_what_it_does_and_how_it_is_typed)
	quit(_verdict.deliver(get_script()))


## Commands for give, reset and a send bound to the vault, over a fresh ledger,
## as [commands, ledger]. The ledger comes back too, so it stays alive: a
## command does not keep its object.
func _made() -> Array:
	var ledger := Ledger.new()
	var commands := DevCommands.new()
	commands.register(&"give", "gives someone an amount", ledger.give)
	commands.register(&"reset", "puts everything back", ledger.reset)
	commands.register(&"vault", "sends an amount to the vault", ledger.send.bind("vault"))
	return [commands, ledger]


## process_frame is emitted BEFORE nodes are processed, so the effect of a frame
## is only visible once the next one has come round.
func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## A real debug log in a folder of its own, emptied of what an earlier one left.
func _a_debug_log() -> DebugLog:
	DirAccess.make_dir_recursive_absolute(FOLDER)
	# every file an earlier log left in the folder
	for name: String in DirAccess.get_files_at(FOLDER):
		DirAccess.remove_absolute(FOLDER.path_join(name))
	return DebugLog.new(Chimes.new(Belfry.new()), FOLDER, 100000, 3, 50)


func _each_word_becomes_its_parameters_type_and_the_answer_comes_back() -> void:
	var made := _made()
	var commands: DevCommands = made[0]
	var ledger: Ledger = made[1]
	commands.register(&"tag", "tags an account with a label", ledger.tag)

	var answers := [commands.run("give 3 12.5 thanks true"), commands.run("tag savings rainy")]

	_verdict.check(ledger.calls == [["give", 3, 12.5, "thanks", true], ["tag", &"savings", "rainy"]], "give took 3, 12.5, thanks and true, and tag took savings for a StringName and rainy untyped: %s" % [ledger.calls])
	_verdict.check(ledger.calls.size() == 2 and typeof(ledger.calls[0][1]) == TYPE_INT and typeof(ledger.calls[0][2]) == TYPE_FLOAT and typeof(ledger.calls[0][4]) == TYPE_BOOL, "each as its parameter's type, not as text")
	_verdict.check(answers == ["gave 3 12.5", "tagged savings rainy"], "and their answers came back: %s" % [answers])


func _optional_parameters_take_their_defaults_when_left_off() -> void:
	var made := _made()
	var commands: DevCommands = made[0]
	var ledger: Ledger = made[1]

	commands.run("give 3 12.5")
	commands.run("give 4 1 thanks")

	_verdict.check(ledger.calls == [["give", 3, 12.5, "none", false], ["give", 4, 1.0, "thanks", false]], "left off, note and loud took their defaults; given, the note took its word: %s" % [ledger.calls])


func _a_word_that_will_not_become_its_type_runs_nothing_and_says_why() -> void:
	var made := _made()
	var commands: DevCommands = made[0]
	var ledger: Ledger = made[1]

	var answers := [commands.run("give three 12.5"), commands.run("give 3 lots"), commands.run("give 3 1 thanks maybe")]

	_verdict.check(ledger.calls.is_empty(), "nothing ran")
	_verdict.check(answers == ["who needs a whole number, got 'three'", "amount needs a decimal, got 'lots'", "loud needs true or false, got 'maybe'"], "each answer names the parameter and the word: %s" % [answers])


func _too_few_or_too_many_words_run_nothing_and_answer_with_the_usage() -> void:
	var made := _made()
	var commands: DevCommands = made[0]
	var ledger: Ledger = made[1]

	var too_few := commands.run("give 3")
	var too_many := commands.run("give 3 1 thanks true again")

	_verdict.check(ledger.calls.is_empty(), "nothing ran")
	_verdict.check(too_few.contains(GIVE_USAGE) and too_many.contains(GIVE_USAGE), "both answers give the usage: '%s'" % too_few)


func _quoted_words_keep_their_spaces_even_empty_or_left_open_and_extra_spaces_change_nothing() -> void:
	var made := _made()
	var commands: DevCommands = made[0]
	var ledger: Ledger = made[1]

	commands.run("give 3 1 \"for the long haul\"")
	commands.run("   give    4  2   ")
	commands.run("give 5 3 \"\" true")
	commands.run("give 6 4 \"to the end of the line")

	_verdict.check(ledger.calls.slice(0, 2) == [["give", 3, 1.0, "for the long haul", false], ["give", 4, 2.0, "none", false]], "the quoted note kept its spaces, and the spaced-out line read as two words: %s" % [ledger.calls])
	_verdict.check(ledger.calls.slice(2, 3) == [["give", 5, 3.0, "", true]], "a pair of empty quotes was a word, the empty note")
	_verdict.check(ledger.calls.slice(3) == [["give", 6, 4.0, "to the end of the line", false]], "and a quote left open ran to the end of the line")


func _nothing_returned_answers_done_a_static_is_read_from_its_script_a_bound_takes_the_rest() -> void:
	var made := _made()
	var commands: DevCommands = made[0]
	var ledger: Ledger = made[1]
	commands.register(&"double", "doubles an amount", Ledger.doubled)

	var answers := [commands.run("reset"), commands.run("double 21"), commands.run("vault 50")]

	_verdict.check(answers[0] == "done" and ledger.calls.size() > 0 and ledger.calls[0] == ["reset"], "reset, which returns nothing, ran and answered done")
	_verdict.check(answers[1] == "42", "double, a static function, was read from its script and took 21 as a whole number: '%s'" % answers[1])
	_verdict.check(ledger.calls.size() == 2 and ledger.calls[1] == ["send", 50, "vault"] and answers[2] == "sent 50 to vault", "and vault, bound to the vault, took a word only for the amount")
	_verdict.check(commands.get_usage(&"vault") == "vault <amount: a whole number>", "and its usage names only the amount: '%s'" % commands.get_usage(&"vault"))


func _the_line_and_its_answer_reach_the_debug_log() -> void:
	var debug_log := _a_debug_log()
	var made := _made()
	var commands: DevCommands = made[0]

	commands.run("give 3 12.5")
	await _a_frame_passes()

	var last := "" if debug_log.count() == 0 else str(debug_log.get_entry(debug_log.count() - 1)["text"])
	_verdict.check(last.contains("> give 3 12.5") and last.contains("gave 3 12.5"), "the log's newest entry holds the line and its answer: '%s'" % last)
	debug_log.free()


## The console holds no dev commands: a typed line is dispatched, and whatever
## the line said is printed rather than answered, so the door answers done.
func _a_line_dispatched_as_run_line_runs_and_answers_done() -> void:
	var made := _made()
	var commands: DevCommands = made[0]
	var ledger: Ledger = made[1]
	var chimes := Chimes.new(Belfry.new())
	var door := Commands.new(chimes)
	door.register(Chimes.GLOBAL, DevCommands.RUN_LINE, commands)

	var answer := door.dispatch(&"a_screen", DevCommands.RUN_LINE, {"line": "give 3 12.5"})

	_verdict.check(ledger.calls == [["give", 3, 12.5, "none", false]], "the line ran: %s" % [ledger.calls])
	_verdict.check(answer == null, "and the door answers done, what the line said being printed: '%s'" % answer)
	_verdict.check(door.dispatch(&"a_screen", DevCommands.RUN_LINE, {"line": "take 3"}) == null, "an unknown name is printed too, and still done")
	door.free()


func _an_unknown_name_answers_with_the_names_and_an_empty_line_says_nothing() -> void:
	var made := _made()
	var commands: DevCommands = made[0]
	var ledger: Ledger = made[1]

	var unknown := commands.run("take 3 1")
	var debug_log := _a_debug_log()
	var empty := [commands.run(""), commands.run("     ")]
	await _a_frame_passes()
	var logged := debug_log.count()
	debug_log.free()

	_verdict.check(ledger.calls.is_empty(), "nothing ran")
	_verdict.check(unknown == "no command called take; the commands are give, reset, vault", "the unknown name is answered with the names there are: '%s'" % unknown)
	_verdict.check(empty == ["", ""] and logged == 0, "and an empty line says nothing, not even to the log: %d entries" % logged)


func _a_second_name_a_parameter_no_word_can_become_or_an_anonymous_function_is_refused_out_loud() -> void:
	var made := _made()
	var commands: DevCommands = made[0]
	var ledger: Ledger = made[1]
	var echo := func(word: String) -> String: return word
	var debug_log := _a_debug_log()

	commands.register(&"give", "a second give", ledger.reset)
	commands.register(&"place", "puts something somewhere", ledger.place)
	commands.register(&"echo", "says its word back", echo)
	await _a_frame_passes()
	var errors: Array = []
	# the errors among what the log caught, oldest first
	for index: int in range(debug_log.count()):
		if debug_log.get_entry(index)["kind"] == DebugLog.ERROR:
			errors.append(debug_log.get_entry(index)["text"])
	debug_log.free()

	_verdict.check(commands.run("give 3 12.5") == "gave 3 12.5" and commands.get_description(&"give") == "gives someone an amount", "give is still the first command")
	_verdict.check(commands.get_names() == [&"give", &"reset", &"vault"], "and neither place, whose parameter no word can become, nor echo, an anonymous function, was registered")
	_verdict.check(errors.size() == 3 and errors[0].contains("give") and errors[1].contains("place") and errors[2].contains("echo"), "each refusal was said out loud as an error, naming its command: %s" % [errors])


func _the_names_are_listed_in_order_each_with_what_it_does_and_how_it_is_typed() -> void:
	var commands := DevCommands.new()
	var ledger := Ledger.new()
	commands.register(&"zero", "puts nothing back", ledger.reset)
	commands.register(&"give", "gives someone an amount", ledger.give)

	_verdict.check(commands.get_names() == [&"zero", &"give"], "in the order registered, not alphabetically")
	_verdict.check(commands.get_description(&"give") == "gives someone an amount", "each with what it does")
	_verdict.check(commands.get_usage(&"give") == GIVE_USAGE and commands.get_usage(&"zero") == "zero", "and how it is typed, the optional parameters in brackets")
