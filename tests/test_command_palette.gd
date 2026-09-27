extends SceneTree
const Actions := preload("res://addons/gd_chime/actions.gd")

## What must be true of the command palette: Ctrl+K opens it over the app
## with the line empty and the focus in it; it holds every command the
## screen could press by hand from where the reader is - not a row's press,
## not one in a tab they are not on, not the one that opens it - and every
## entry the application hands in; typing narrows them; a command the door
## would refuse says why on its entry; Enter picks the first match, the
## palette going down before the press is made where it would be made by
## hand; a picked dataset is its source's action carrying its value; and
## Escape closes it.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_command_palette.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Inputs := preload("res://addons/gd_chime/input_map.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Field := preload("res://addons/gd_chime/components/primitives/field.gd")
const CommandSearch := preload("res://addons/gd_chime/command_search.gd")
const CommandPalette := preload("res://addons/gd_chime/components/recipes/command_palette.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Verdict := preload("res://tests/verdict.gd")

const OPENS := &"opens_the_palette"
const TYPES := CommandSearch.TYPES
const WORDS := {OPENS: "search", TYPES: "search for", CommandSearch.PICKS: "pick", CommandSearch.RUNS_FIRST: "run the first", &"adds": "add a crate", &"removes": "remove a crate", &"picks_row": "pick the row", &"hides": "hidden away", &"shows_dataset": "show the dataset"}

var _verdict := Verdict.new()
var _palette: StringName  # the palette's pop-up, named by the builder



func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(900, 700)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_the_palette_opens_on_its_key_holds_the_screen_s_commands_and_the_datasets_and_picks_them)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


func _key(code: int, ctrl: bool = false) -> void:
	var key := InputEventKey.new()
	key.keycode = code
	key.ctrl_pressed = ctrl
	key.pressed = true
	root.push_input(key)
	await _a_frame_passes()


## Words typed a key at a time, as a keyboard types them into the focus.
func _type(words: String) -> void:
	# every letter, pressed as its key with the character it stands for
	for letter: String in words:
		var key := InputEventKey.new()
		key.keycode = OS.find_keycode_from_string(letter.to_upper()) if letter != "_" else KEY_UNDERSCORE
		key.unicode = letter.unicode_at(0)
		key.pressed = true
		root.push_input(key)
	await _a_frame_passes()


func _the_palette_opens_on_its_key_holds_the_screen_s_commands_and_the_datasets_and_picks_them() -> void:
	var made := Fixture.new(root, {})
	var table: Dictionary = {}
	# every action the test declares, the palette's opening on Ctrl+K; its closing is every pop-up's, on Escape
	for action: StringName in WORDS:
		table[action] = [WORDS[action], Actions.keys(KEY_K, KEY_MASK_CTRL)] if action == OPENS else [WORDS[action]]
	made.actions.declare_all(table)
	made.inputs.restore_defaults()
	var model := Fixture.Model.new(made.chimes, Chimes.GLOBAL)
	model.refuse(&"removes", Phrase.of("not while the stall is shut"))
	for action: StringName in [&"adds", &"removes", &"picks_row", &"hides", &"shows_dataset"]:
		made.commands.register(Chimes.GLOBAL, action, model)
	var tables := Fixture.Model.new(made.chimes, &"tables")
	var datasets: Array = []
	# three thousand datasets, each its number and its name
	for at: int in 3000:
		datasets.append({"value": at, "words": "table_%04d" % at})
	tables.set_value(&"items", datasets)
	var search := CommandSearch.new(made.chimes, made.commands, made.driver, made.actions, [{"kind": Phrase.of("dataset"), "entries": tables.of(&"items"), "picks": &"shows_dataset"}])
	for node: Node in [model, tables, search]:
		root.add_child(node)
	var ui := made.ui
	var opened := CommandPalette.make(ui, search)
	_palette = opened.get_place()
	ui.start(ui.app(&"app", [ui.column([
		ui.pressable(OPENS, {}, [ui.text("search")], &"Pressable").opens(opened),
		ui.pressable(&"adds", {}, [ui.text("add")]),
		ui.pressable(&"removes", {}, [ui.text("remove")]),
		ui.pressable(&"picks_row", {"row": 1}, [ui.text("row one")]),
		ui.pressable(&"shows_dataset", {"value": 1}, [ui.text("table one")]),
		ui.tabs(&"pages", [ui.screen(&"first", [ui.text("first")]), ui.screen(&"second", [ui.pressable(&"hides", {}, [ui.text("hidden")])])]),
	])]))
	await _a_frame_passes()
	await _key(KEY_K, true)
	var focus := root.gui_get_focus_owner()
	_verdict.check(made.driver.get_top().has(_palette) and focus is LineEdit and (focus as LineEdit).text == "", "Ctrl+K opens the palette over the app, the focus in its empty line: %s %s" % [made.driver.get_top(), focus])
	var commands: Array = search.get_options().filter(func(entry: Dictionary) -> bool: return entry["payload"].is_empty()).map(func(entry: Dictionary) -> StringName: return entry["action"])
	_verdict.check(commands == [&"adds", &"removes"] and search.get_count() == 3002, "it holds the screen's two commands - no row's press, none in a tab not on, not its own opening - and all three thousand datasets: %s, %d" % [commands, search.get_count()])
	await _type("table_12")
	await _a_frame_passes()
	_verdict.check(search.get_count() == 100 and _entries(ui).size() == 12, "typing narrows them, every keystroke: %d matching, %d shown" % [search.get_count(), _entries(ui).size()])
	(focus as LineEdit).clear()
	await _type("crate")
	await _a_frame_passes()
	var removing: Pressable = _entries(ui)[1]
	_verdict.check(not removing.is_usable() and _texts(removing).has("not while the stall is shut") and _texts(removing).has("Command"), "a command the door would refuse says why on its entry, before it is picked: %s" % [_texts(removing)])
	await _key(KEY_ENTER)
	_verdict.check(model.told_actions == [&"adds"] and not made.driver.is_raised(), "Enter picks the first match: the palette goes down and the command is pressed: %s %s" % [model.told_actions, made.driver.get_top()])
	await _key(KEY_K, true)
	focus = root.gui_get_focus_owner()
	_verdict.check(focus is LineEdit and (focus as LineEdit).text == "" and search.get_count() == 3002, "opened again, its line is empty and everything is there to find: %s" % [search.get_count()])
	await _type("table_0017")
	await _a_frame_passes()
	(_entries(ui)[0] as Pressable).pressed()
	await _a_frame_passes()
	_verdict.check(model.told_actions == [&"adds", &"shows_dataset"] and made.commands.get_last()["action"] == CommandSearch.PICKS and not made.driver.is_raised(), "a dataset picked is its source's action, and the palette goes down: %s" % [model.told_actions])
	await _key(KEY_K, true)
	await _key(KEY_ESCAPE)
	_verdict.check(not made.driver.is_raised(), "Escape closes it: %s" % [made.driver.get_top()])
	await _a_frame_passes()
	var palette: Node = ui.driver.index.place_named(_palette)
	var drawn := func() -> int: return palette.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable and part.action == CommandSearch.PICKS).reduce(func(sum: int, part: Pressable) -> int: return sum + part.refresh_count, 0)
	var before: int = drawn.call()
	# five commands run while the palette is closed, as a grip dragged runs one a frame
	for step: int in 5:
		made.commands.dispatch(Chimes.GLOBAL, &"adds", {})
		await _a_frame_passes()
	_verdict.check(search.get_options().is_empty() and drawn.call() == before, "closed, it offers nothing, and commands running draw none of its entries again: %d draws" % (drawn.call() - before))
	for node: Node in [model, tables, search]:
		node.free()
	made.done()


## The entries shown in the palette now, in order.
func _entries(ui: RefCounted) -> Array:
	var palette: Node = ui.driver.index.place_named(_palette)
	return palette.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable and part.action == CommandSearch.PICKS and part.visible and not part.is_in_group(&"going"))


func _texts(node: Node) -> Array[String]:
	var found: Array[String] = []
	for child: Node in node.get_children():
		if child is Text and (child as Text).visible:
			found.append((child as Text).get_text())
		found.append_array(_texts(child))
	return found
