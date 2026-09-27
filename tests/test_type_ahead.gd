extends SceneTree

## What must be true of the type-ahead picker and the narrowing behind it:
## typing narrows the options and the count, the options come from the
## bound source and follow it when it changes, a press picks the option's
## value, and the whole picker is walked from the line down with the keys.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_type_ahead.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Each := preload("res://addons/gd_chime/components/primitives/each.gd")
const Narrowing := preload("res://addons/gd_chime/narrowing.gd")
const TypeAhead := preload("res://addons/gd_chime/components/recipes/type_ahead.gd")
const Verdict := preload("res://tests/verdict.gd")

const WORDS := ["pear", "apple", "fig", "date", "plum", "lime", "kiwi", "yuzu", "grape", "melon"]

var _verdict := Verdict.new()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(400, 400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_typing_narrows_the_options_and_the_count_to_what_the_source_holds)
	await _verdict.states(_a_press_picks_the_option_s_value_and_the_picker_is_walked_by_key)
	await _verdict.states(_the_source_is_read_once_per_move_and_the_matching_once_per_keystroke)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


func _texts(node: Node) -> Array[String]:
	var found: Array[String] = []
	for child: Node in node.get_children():
		if child is Text:
			found.append((child as Text).get_text())
		found.append_array(_texts(child))
	return found


func _options(node: Node) -> Array[String]:
	var found: Array[String] = []
	for part: Node in _pressables(node):
		found.append_array(_texts(part))
	return found


func _pressables(node: Node) -> Array:
	return node.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable)


func _entries(words: Array) -> Array:
	var made: Array = []
	# an option is what it picks and what it reads as
	for word: String in words:
		made.append({"value": word.to_upper(), "words": word})
	return made


## Typed as a person types: the caret in the line, and the key pressed.
func _types(node: Node, letters: String) -> void:
	var line: LineEdit = node.find_children("*", "LineEdit", true, false)[0]
	line.grab_focus()
	for letter: String in letters:
		for down: bool in [true, false]:
			var key := InputEventKey.new()
			key.keycode = letter.to_upper().unicode_at(0)
			key.unicode = letter.unicode_at(0)
			key.pressed = down
			root.push_input(key)


func _typing_narrows_the_options_and_the_count_to_what_the_source_holds() -> void:
	var made := Fixture.new(root, {&"types": "type", &"picks": "pick"})
	var ui := made.ui
	var source := Fixture.Model.new(made.chimes, &"app")
	source.set_value(&"items", _entries(WORDS))
	var narrowing := Narrowing.new(made.chimes, source.of(&"items"), 3)
	made.commands.register(&"app", &"types", narrowing)
	made.commands.register(&"app", &"picks", source)
	ui.start(ui.app(&"app", [TypeAhead.make(ui, narrowing, &"types", &"picks").named(&"picker")]))
	await _a_frame_passes()
	var picker: Node = ui.node_named(&"picker")
	_verdict.check(_options(picker) == ["pear", "apple", "fig"] and _texts(picker).has("10 matches"), "nothing typed: the source's own first entries, and how many there are in all: %s" % [_texts(picker)])
	_types(picker, "P")
	await _a_frame_passes()
	_verdict.check(_options(picker) == ["pear", "apple", "plum"] and _texts(picker).has("4 matches"), "typed: only the matching options, ignoring case, no more than the limit, and the count says there is a fourth: %s" % [_texts(picker)])
	source.set_value(&"items", _entries(["pepper", "salt"]))
	await _a_frame_passes()
	_verdict.check(_options(picker) == ["pepper"] and _texts(picker).has("1 match"), "the source changed under it: the options are the new source's, narrowed by what is still typed: %s" % [_texts(picker)])
	_verdict.check(narrowing.get_typed() == "P", "and what was typed is still typed")
	narrowing.free()
	source.free()
	made.done()


func _a_press_picks_the_option_s_value_and_the_picker_is_walked_by_key() -> void:
	var made := Fixture.new(root, {&"types": "type", &"picks": "pick"})
	var ui := made.ui
	var source := Fixture.Model.new(made.chimes, &"app")
	source.set_value(&"items", _entries(["plum", "lime", "kiwi"]))
	var narrowing := Narrowing.new(made.chimes, source.of(&"items"), 8)
	var caller := Fixture.Model.new(made.chimes, &"app")
	made.commands.register(&"app", &"types", narrowing)
	made.commands.register(&"app", &"picks", caller)
	ui.start(ui.app(&"app", [TypeAhead.make(ui, narrowing, &"types", &"picks").named(&"picker")]))
	await _a_frame_passes()
	var picker: Node = ui.node_named(&"picker")
	var options := _pressables(picker)
	(options[1] as Pressable).pressed()
	_verdict.check(caller.told_actions == [&"picks"] and made.commands.get_last()["payload"] == {"value": "LIME"}, "a press picks that option's value, and the narrowing was told nothing: %s" % [made.commands.get_last()["payload"]])
	_verdict.check(narrowing.get_typed() == "", "picking is the caller's, not the narrowing's")
	var focusable := options.all(func(part: Node) -> bool: return (part as Control).focus_mode == Control.FOCUS_ALL)
	_verdict.check(options.size() == 3 and focusable and _options(picker) == ["plum", "lime", "kiwi"], "the options are focusable pressables, in the source's order")
	_verdict.check((options[0] as Control).find_next_valid_focus() == options[1], "the keys and a pad walk from one option to the next, the engine doing the moving")
	var line: LineEdit = picker.find_children("*", "LineEdit", true, false)[0]
	_verdict.check(line.find_next_valid_focus() == options[0], "and down out of the line into the first option")
	narrowing.free()
	caller.free()
	source.free()
	made.done()


## A source counting how often it is read: the options and the count read
## over and over read it once, typing reads it not at all, and it is read
## again only once it moves.
func _the_source_is_read_once_per_move_and_the_matching_once_per_keystroke() -> void:
	var made := Fixture.new(root, {})
	var source := Fixture.Model.new(made.chimes, &"app")
	source.set_value(&"items", _entries(WORDS))
	var reads := [0]
	var counted := Bound.new(func() -> Variant: reads[0] += 1; return source.get_items())
	var narrowing := Narrowing.new(made.chimes, counted, 20)
	root.add_child(narrowing)
	# every option and the count read three times over
	for again: int in 3:
		narrowing.get_options()
		narrowing.get_count()
	_verdict.check(reads[0] == 1 and narrowing.get_count() == 10, "read over and over, the source is read once: %d" % reads[0])
	narrowing.told(&"types", {"line": "P"})
	var typed: Array = narrowing.get_options().map(func(option: Dictionary) -> String: return option["words"])
	_verdict.check(reads[0] == 1 and typed == ["pear", "apple", "plum", "grape"] and narrowing.get_count() == 4, "typing narrows without reading the source again, ignoring case: %s after %d reads" % [typed, reads[0]])
	source.set_value(&"items", _entries(["papaya", "kiwi"]))
	await process_frame
	_verdict.check(narrowing.get_options().map(func(option: Dictionary) -> String: return option["words"]) == ["papaya"] and reads[0] == 2, "the source moving, it is read again, once, and narrowed by what is typed: %d" % reads[0])
	narrowing.free()
	source.free()
	made.done()
