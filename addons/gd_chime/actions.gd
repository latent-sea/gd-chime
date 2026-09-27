extends RefCounted

const Saved := preload("saved_inputs.gd")

## The actions the interface has, each with the words that say what it does,
## said once.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## What an action does is one fact about it, read the same by everything that
## names it - a prompt, a reminder, a step - and several controls perform one
## action, so the words cannot live on a control. This is the one register
## outside the tree: an action is declared here once, with its words, and
## whatever raises, tracks or steps to an action asks here whether it is one
## and what it says.
##
## Which controls perform an action is the index's (index.gd), which every
## control performing one enters. Nothing here knows a control. An action declared twice,
## or with no words, is refused out loud; asking about one never declared is
## answered plainly, so a misspelt action is refused where it is used.
##
## EVERY ACTION IS DECLARED IN ONE TABLE, declare_all, and there is no other
## way: the action against its words and then the inputs that press it -
##
##     actions.declare_all({OPENS: ["Open the ledger", keys(KEY_L), pad(JOY_BUTTON_Y)]})
##
## - so an application says what it has once, in one shape, with nothing to
## map or unpack. An action with no input is its words alone.
##
## AN INPUT IS THE KEY OR THE PAD BUTTON IT IS ON before anyone changed
## anything, made by keys() - with its modifiers, KEY_MASK_CTRL and the rest,
## as the one number the engine writes for them - and pad(). They are the
## DEFAULTS and nothing more: what is bound now is the map's (input_map.gd),
## and the map reads these as it is built and whenever the defaults are
## restored. They are kept here because what presses an action is one fact
## about it, said once beside its words, and every action is declared here
## already.
##
## THE WORDS ARE KEYS: declared in English and handed out in English, so
## whatever shows them - a button, the prompts - hands a text a key it says
## in the language on as it draws (text.gd). The register holds no language.
##
## Deliberately absent: which actions are worth reminding of, which is
## taken.gd's; and any order among actions.

var _words: Dictionary = {}  # action -> the words saying what it does
var _inputs: Dictionary = {}  # action -> the inputs it is on before anything is rebound


## A key, held with its modifiers where it has them, as the one input the
## engine writes for them - so K and Ctrl+K press two actions.
static func keys(code: Key, modifiers: int = 0) -> Dictionary:
	return {Saved.KEY: code | modifiers}


static func pad(button: JoyButton) -> Dictionary:
	return {Saved.PAD: button}


## Every action of a table declared: the action against its words and then
## the inputs that press it to begin with.
func declare_all(table: Dictionary) -> void:
	# every action of the table: its words first, the inputs it is on after them
	for action: StringName in table:
		var said: Array = table[action]
		_declare(action, said[0], said.slice(1))


## One action with the words that say what it does, once, and the inputs that
## press it to begin with - or refused out loud, keeping what was declared.
func _declare(action: StringName, words: String, inputs: Array) -> void:
	if _words.has(action):
		push_error("%s is already declared, as \"%s\"" % [action, _words[action]])
		return
	if words == "":
		push_error("%s needs the words that say what it does" % action)
		return
	_words[action] = words
	_inputs[action] = inputs


## Whether this is an action.
func has(action: StringName) -> bool:
	return _words.has(action)


## The words saying what a declared action does, in English: a key.
func get_words(action: StringName) -> String:
	return _words[action]


## The inputs a declared action is on before anything is rebound; none unless
## it was declared with them.
func get_inputs(action: StringName) -> Array:
	return _inputs[action]


## Every action declared, in the order declared.
func get_all() -> Array[StringName]:
	var all: Array[StringName] = []
	all.assign(_words.keys())
	return all
