extends RefCounted

const Phrase := preload("phrase.gd")
## The commands a developer can run while the app runs, and the running of a
## typed line.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A line reaches this through the door: whoever composes the application
## registers this for RUN_LINE, globally, and told(RUN_LINE, {line}) runs the
## line and answers done - what the line said is printed, not answered, so
## the log is where a developer reads it. run(line) is the same run, for a
## caller that holds this.
##
## A command is an ordinary named function, registered by name with a line
## saying what it does. It takes as many parameters as it needs, typed as it
## likes, the last ones optional with defaults. Registering reads the function's
## own parameter list - its names, types and defaults, measured to be there on
## 4.6.2, a static function's in its script - so nothing else is declared. A word
## can become a whole number, a decimal, true or false, or text. A bound function
## takes words only for the parameters it was not bound.
##
## Registering refuses three things out loud, and registers nothing for them: a
## name already registered, so the first stays; a parameter of a type no word can
## become, so the mistake shows at once rather than when someone types it; and an
## anonymous function, which reports how many parameters it has but not what they
## take. What they take cannot be guessed: handed a value a parameter cannot
## take, callv skips the call silently - measured - so a wrong guess would answer
## done having done nothing.
##
## Registering does not keep the function's object alive - measured - so
## whatever registers a command keeps that object.
##
## run(line) cuts a line into words at spaces, keeping anything between double
## quotes as one word, and runs the command the first word names. Each word after
## it is made into its parameter's type, and the function is called with them;
## what it returns is the answer, and a function that returns nothing answers
## done. When a word will not become its parameter's type, or there are too few
## words or too many, nothing runs, and the answer says why: the parameter and
## the word, or the command's usage. A name nobody registered answers with the
## names that are. The line and its answer are printed together, so the debug
## log records every command and what it said. An empty line runs and says
## nothing, and a quote left open runs to the end of the line.
##
## Main thread only: a command reaches into models, and models live there.
##
## Deliberately absent: a screen to type into, which comes later with the other
## screens; history and recall, which belong to that screen; a command that
## answers later; parameters of types a word cannot become.

## The command a typed line arrives as, carrying the line.
const RUN_LINE := &"run_line"

## What a word can become, said the way an answer says it.
const TYPE_SAID := {
	TYPE_INT: "a whole number",
	TYPE_FLOAT: "a decimal",
	TYPE_BOOL: "true or false",
	TYPE_STRING: "text",
	TYPE_STRING_NAME: "text",
	TYPE_NIL: "text",
}

var _commands: Dictionary = {}  # name -> its function, description, parameters and how many are required, in the order registered


## A command, under a name no other command has, made of a named function whose
## own parameters say which words it takes.
func register(name: StringName, description: String, function: Callable) -> void:
	if _commands.has(name):
		push_error("a command called %s is already registered" % name)
		return
	var object := function.get_object()
	# a static function's object is its script, whose own functions are listed apart from an object's
	var methods: Array[Dictionary] = (object as Script).get_script_method_list() if object is Script else object.get_method_list()
	var entry: Dictionary = {}
	# the function's own entry, naming and typing its parameters; an anonymous function has none
	for method: Dictionary in methods:
		if method["name"] == function.get_method():
			entry = method
			break
	if entry.is_empty():
		push_error("the command %s must be a named function: an anonymous one cannot say what its parameters take" % name)
		return
	var parameters: Array[Dictionary] = []
	# each parameter the typed words fill, which is every one not bound
	for index: int in range(function.get_argument_count()):
		parameters.append({"name": entry["args"][index]["name"], "type": entry["args"][index]["type"]})
	# every parameter must be something a typed word can become
	for parameter: Dictionary in parameters:
		if not TYPE_SAID.has(parameter["type"]):
			push_error("the command %s cannot take %s: no typed word becomes a %s" % [name, parameter["name"], type_string(parameter["type"])])
			return
	var bound: int = function.get_bound_arguments().size()
	# words may leave off the defaulted parameters the binding did not fill
	var required := parameters.size() - maxi(entry["default_args"].size() - bound, 0)
	_commands[name] = {"function": function, "description": description, "parameters": parameters, "required": required}


## The names registered, in the order they were registered.
func get_names() -> Array[StringName]:
	var names: Array[StringName] = []
	# every registered name, in the order registered
	for name: StringName in _commands:
		names.append(name)
	return names


## What a registered command does, as it was registered.
func get_description(name: StringName) -> String:
	return _commands[name]["description"]


## How a command is typed: its name, then each parameter and what it takes, the
## optional ones in brackets.
func get_usage(name: StringName) -> String:
	var command: Dictionary = _commands[name]
	var parts := PackedStringArray([name])
	# every parameter, in the order the function lists them
	for index: int in range(command["parameters"].size()):
		var parameter: Dictionary = command["parameters"][index]
		var part := "%s: %s" % [parameter["name"], TYPE_SAID[parameter["type"]]]
		parts.append("<%s>" % part if index < command["required"] else "[%s]" % part)
	return " ".join(parts)


## A typed line run: its words made into the command's parameters and the
## function called, or the reason it was not; the answer printed with the line
## and returned.
func run(line: String) -> String:
	var words := _words(line)
	if words.is_empty():
		return ""
	var name := StringName(words[0])
	if not _commands.has(name):
		return _said(line, "no command called %s; the commands are %s" % [name, ", ".join(PackedStringArray(get_names()))])
	var command: Dictionary = _commands[name]
	var parameters: Array[Dictionary] = command["parameters"]
	var given := words.slice(1)
	if given.size() < command["required"] or given.size() > parameters.size():
		return _said(line, "%s takes %s" % [name, get_usage(name)])
	var arguments: Array = []
	# each word made into its parameter's type; the first that will not go ends the run
	for index: int in range(given.size()):
		var word: String = given[index]
		var parameter: Dictionary = parameters[index]
		var refused := "%s needs %s, got '%s'" % [parameter["name"], TYPE_SAID[parameter["type"]], word]
		match parameter["type"]:
			TYPE_INT:
				if not word.is_valid_int():
					return _said(line, refused)
				arguments.append(word.to_int())
			TYPE_FLOAT:
				if not word.is_valid_float():
					return _said(line, refused)
				arguments.append(word.to_float())
			TYPE_BOOL:
				if word != "true" and word != "false":
					return _said(line, refused)
				arguments.append(word == "true")
			# text as typed; for a StringName parameter the engine makes it one as it calls - measured
			_:
				arguments.append(word)
	var result: Variant = command["function"].callv(arguments)
	return _said(line, "done" if result == null else str(result))


## A line is never refused before it runs: what it says is printed.
func would(_action: StringName, _payload: Dictionary) -> Phrase:
	return null


## A line was dispatched: run it, and answer done - the line and what it said
## are printed as they run, never answered.
func told(_action: StringName, payload: Dictionary) -> Phrase:
	run(payload["line"])
	return null


## The line and its answer printed together, for the debug log to record, and
## the answer handed back.
func _said(line: String, answer: String) -> String:
	print("> %s\n%s" % [line.strip_edges(), answer])
	return answer


## A line cut into words at spaces, anything between double quotes kept as one
## word with its spaces; a quote left open runs to the end of the line.
func _words(line: String) -> PackedStringArray:
	var words := PackedStringArray()
	var word := ""
	var quoted := false
	var started := false  # a word has begun, so a pair of empty quotes still counts as one
	# every character, added to the word it belongs to or ending it
	for character: String in line:
		if character == "\"":
			quoted = not quoted
			started = true
		elif character == " " and not quoted:
			if started:
				words.append(word)
			word = ""
			started = false
		else:
			word += character
			started = true
	if started:
		words.append(word)
	return words
