extends SceneTree

## What must be true of the one import: every name it promises resolves, and
## loading it compiles only the names it holds as constants.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_gd_chime.gd
##
## The facade names the whole framework. Held as constants, those names compiled
## the framework at every application's start; held lazily, they cost nothing
## until read. Both halves of that are properties: a name must still resolve to
## the script it promises, and a name in a lazy list must NOT have been compiled
## when the facade loaded.
##
## IT MUST NOT PRELOAD THE FACADE, and it must run in a process of its own.
## Whether a script has been compiled is asked of the engine's cache, which is
## the whole process's; a preload here, or a test beside it in the same process,
## would have compiled the framework before the first property looked. It
## preloads the verdict and nothing else, and its properties run in the order
## written, since reading every name compiles everything.

const Verdict := preload("res://tests/verdict.gd")

## The facade's three files: the one name, and the two lists it extends.
const FACADE := "res://addons/gd_chime/gd_chime.gd"
const LISTS: Array[String] = ["res://addons/gd_chime/gd_chime.gd", "res://addons/gd_chime/gd_chime_floor.gd", "res://addons/gd_chime/gd_chime_recipes.gd"]
## Names held lazily that no application of the demos needs at start, so nothing else can have compiled them.
const LAZY: Array[String] = ["res://addons/gd_chime/components/recipes/card.gd", "res://addons/gd_chime/components/recipes/region_map.gd", "res://addons/gd_chime/components/recipes/wall.gd"]
## A name held as a constant, which loading the facade must compile.
const EAGER := "res://addons/gd_chime/phrase.gd"

var _verdict := Verdict.new()


func _init() -> void:
	await _verdict.states(_loading_it_compiles_the_names_it_holds_as_constants_and_no_other)
	await _verdict.states(_a_lazy_name_gives_the_script_at_its_path_and_the_same_one_after)
	await _verdict.states(_a_name_it_does_not_hold_is_nothing)
	await _verdict.states(_every_name_its_three_files_promise_resolves_to_a_script)
	await _verdict.states(_its_index_lists_exactly_the_names_it_exports)
	quit(_verdict.deliver(get_script()))


func _loading_it_compiles_the_names_it_holds_as_constants_and_no_other() -> void:
	# before anything: the cache has to be innocent of both, or neither half of this says anything
	for path: String in LAZY + [EAGER]:
		_verdict.check(not ResourceLoader.has_cached(path), "%s is not compiled before the facade loads" % path)
	var facade: GDScript = load(FACADE)
	_verdict.check(facade != null and ResourceLoader.has_cached(EAGER), "loading the facade compiles what it holds as a constant")
	# every lazy name checked: the facade must have compiled none of them
	for path: String in LAZY:
		_verdict.check(not ResourceLoader.has_cached(path), "loading the facade does not compile %s, which it holds lazily" % path)


func _a_lazy_name_gives_the_script_at_its_path_and_the_same_one_after() -> void:
	var facade: GDScript = load(FACADE)
	var card: Variant = facade.get("Card")
	_verdict.check(card is GDScript and card.resource_path == LAZY[0], "a lazy name gives the script at its path: %s" % card)
	_verdict.check(ResourceLoader.has_cached(LAZY[0]), "reading the name is what compiles it")
	_verdict.check(facade.get("Card") == card, "read again, it is the same script and not another copy")


func _a_name_it_does_not_hold_is_nothing() -> void:
	var facade: GDScript = load(FACADE)
	_verdict.check(facade.get("Nonsense") == null, "a name the facade does not hold answers nothing, so resolving one proves something")


func _every_name_its_three_files_promise_resolves_to_a_script() -> void:
	var facade: GDScript = load(FACADE)
	var constants: Dictionary = facade.get_script_constant_map()
	var promised: Array[String] = []
	# the three files read as text, so a name cannot be promised in one and missed here
	for path: String in LISTS:
		var finder := RegEx.create_from_string("(?m)^(?:const|static var) ([A-Z]\\w*)")
		for hit: RegExMatch in finder.search_all(FileAccess.get_file_as_string(path)):
			promised.append(hit.get_string(1))
	_verdict.check(promised.size() > 150, "the facade promises the framework, not a handful: %d names" % promised.size())
	var lost: Array[String] = []
	# every promised name, resolved as an application would read it
	for name: String in promised:
		var held: Variant = constants.get(name, facade.get(name))
		if not (held is GDScript):
			lost.append(name)
	_verdict.check(lost.is_empty(), "every name the facade promises resolves to a script; these do not: %s" % ", ".join(lost))


func _its_index_lists_exactly_the_names_it_exports() -> void:
	var facade: GDScript = load(FACADE)
	var constants: Dictionary = facade.get_script_constant_map()
	var whole := FileAccess.get_file_as_string(FACADE)
	var index := whole.substr(whole.find("## THE INDEX"), whole.find("## IT IS A LIST") - whole.find("## THE INDEX"))
	# a capitalised name in the index, less the words of its prose and ChimeApp, the one global name beside it
	var prose: Array[String] = ["THE", "INDEX", "The", "Theme", "ChimeApp"]
	var listed: Array[String] = []
	var finder := RegEx.create_from_string("\\b([A-Z]\\w*)\\b")
	# every capitalised word of the index, as a reader of it would take it
	for hit: RegExMatch in finder.search_all(index):
		if not prose.has(hit.get_string(1)):
			listed.append(hit.get_string(1))
	var unexported: Array[String] = []
	# every listed name, read as an application would read it
	for name: String in listed:
		if not (constants.get(name, facade.get(name)) is GDScript):
			unexported.append(name)
	_verdict.check(listed.size() > 150, "the index lists the framework, not a handful: %d names" % listed.size())
	_verdict.check(unexported.is_empty(), "every name the index lists, the facade exports; these it does not: %s" % ", ".join(unexported))
	var unlisted: Array[String] = []
	# every name of the three files, looked for in the index
	for path: String in LISTS:
		var declared := RegEx.create_from_string("(?m)^(?:const|static var) ([A-Z]\\w*)")
		for hit: RegExMatch in declared.search_all(FileAccess.get_file_as_string(path)):
			if not listed.has(hit.get_string(1)):
				unlisted.append(hit.get_string(1))
	_verdict.check(unlisted.is_empty(), "every name the facade exports, its index lists; these it does not: %s" % ", ".join(unlisted))
