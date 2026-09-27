extends SceneTree

## What must be true of the register of actions.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_actions.gd
##
## An action declared with its words is one, and its words read back as
## declared, the same however many ask. Declared again it is refused and the
## first words kept; declared with no words it is refused. One never declared
## is not an action. And every action is listed in the order declared.
##
## A table says an action's words first and then the inputs it is on -
## keys(KEY_S, KEY_MASK_CTRL), pad(JOY_BUTTON_Y) - and every one of them
## reads back, in the order written, as the input the map takes; an action
## with words alone is on none.
##
## A refusal is heard through a logger that counts only what is pushed as an
## error. Nothing here is in the tree.

const Actions := preload("res://addons/gd_chime/actions.gd")
const Verdict := preload("res://tests/verdict.gd")

var _verdict := Verdict.new()
var _hearing := Hearing.new()


## Counts what is pushed as an error, which is how the register says no.
class Hearing extends Logger:
	var refusals: int = 0

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_ERROR:
			refusals += 1


func _init() -> void:
	OS.add_logger(_hearing)
	await _verdict.states(_an_action_declared_once_reads_back_its_words_and_a_repeat_or_no_words_is_refused)
	await _verdict.states(_one_never_declared_is_no_action_and_every_action_is_listed_in_order)
	await _verdict.states(_a_table_says_the_words_first_and_then_every_input_the_action_is_on)
	OS.remove_logger(_hearing)
	quit(_verdict.deliver(get_script()))


func _an_action_declared_once_reads_back_its_words_and_a_repeat_or_no_words_is_refused() -> void:
	var actions := Actions.new()
	var before := _hearing.refusals
	actions.declare_all({&"opens a record": ["open a record"]})

	_verdict.check(_hearing.refusals == before and actions.has(&"opens a record"), "declared with its words, it is an action, without a word")
	_verdict.check(actions.get_words(&"opens a record") == "open a record", "and its words read back as declared: %s" % actions.get_words(&"opens a record"))
	actions.declare_all({&"opens a record": ["open the record"]})
	_verdict.check(_hearing.refusals == before + 1 and actions.get_words(&"opens a record") == "open a record", "declared again it is refused out loud, and the first words are kept")
	actions.declare_all({&"starts a run": [""]})
	_verdict.check(_hearing.refusals == before + 2 and not actions.has(&"starts a run"), "declared with no words it is refused out loud, and is no action")


func _one_never_declared_is_no_action_and_every_action_is_listed_in_order() -> void:
	var actions := Actions.new()
	actions.declare_all({&"starts a run": ["start a run"]})
	actions.declare_all({&"opens a record": ["open a record"]})

	_verdict.check(not actions.has(&"opens two"), "one never declared is no action")
	_verdict.check(actions.get_all() == [&"starts a run", &"opens a record"], "every action, in the order declared: %s" % [actions.get_all()])


func _a_table_says_the_words_first_and_then_every_input_the_action_is_on() -> void:
	var actions := Actions.new()
	actions.declare_all({
		&"saves the day": ["Save the day", Actions.keys(KEY_S, KEY_MASK_CTRL), Actions.pad(JOY_BUTTON_Y)],
		&"opens a record": ["Open a record"],
	})

	_verdict.check(actions.get_words(&"saves the day") == "Save the day", "the first of a table's entry is the words: %s" % actions.get_words(&"saves the day"))
	_verdict.check(actions.get_inputs(&"saves the day") == [{"key": KEY_S | KEY_MASK_CTRL}, {"pad": JOY_BUTTON_Y}], "and the rest are the inputs it is on, in the order written, a chord one input: %s" % [actions.get_inputs(&"saves the day")])
	_verdict.check(actions.get_inputs(&"opens a record") == [], "an action of words alone is on no input: %s" % [actions.get_inputs(&"opens a record")])
