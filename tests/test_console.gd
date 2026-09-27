extends SceneTree

## What must be true of the developer's console.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_console.gd
##
## The console is the first surface on this floor that is not built until it is
## wanted, so the first properties are about what a console nobody has opened
## costs: no parts, nothing shown, and no drawing however much is said or walked.
##
## Then the conversation it exists for: F10 brings it up and puts it away,
## opening it puts the caret in the line, what is typed runs, and the line and
## its answer come back through the log as entries like any other.
##
## Then the second page: the path walked, each view whole and oldest first,
## reached by Ctrl+Tab while a line is half typed or by a click on its tab, and
## following the path as it changes.
##
## Last, its words: only a developer reads it, so they stay English with
## French on, even where a catalogue holds them.
##
## Every key and click is pushed through the engine, since what reaches the
## console while its line holds focus is exactly what this depends on.

const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Commands := preload("res://addons/gd_chime/commands.gd")
const Console := preload("res://addons/gd_chime/console.gd")
const DebugLog := preload("res://addons/gd_chime/debug_log.gd")
const DevCommands := preload("res://addons/gd_chime/dev_commands.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Place := preload("res://addons/gd_chime/place.gd")
const Field := preload("res://addons/gd_chime/components/primitives/field.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Actions := preload("res://addons/gd_chime/actions.gd")
const Prompts := preload("res://addons/gd_chime/prompts.gd")
const Ui := preload("res://addons/gd_chime/components/primitives/ui.gd")
const Language := preload("res://addons/gd_chime/language.gd")
const Verdict := preload("res://tests/verdict.gd")

const REGION := &"a_console"
const ROOT := "user://test_console"

var _verdict := Verdict.new()


## Something for a command to do, so that a typed line has an answer.
class Ledger extends RefCounted:
	var given: int = 0

	func give(amount: int) -> String:
		given += amount
		return "%d given" % amount


func _init() -> void:
	await process_frame
	root.size = Vector2i(600, 400)
	# the pointer tests measure in the window's own pixels: the base-size stretch the project sets is off here
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_nothing_is_built_until_the_key_comes)
	await _verdict.states(_a_console_nobody_opened_draws_nothing_however_much_happens)
	await _verdict.states(_the_key_brings_it_up_and_puts_it_away)
	await _verdict.states(_opening_it_puts_the_caret_in_the_line)
	await _verdict.states(_what_is_typed_runs_and_comes_back_through_the_log)
	await _verdict.states(_the_key_works_while_a_line_is_half_typed_and_keeps_it)
	await _verdict.states(_it_shows_the_most_recent_entries_that_fit_newest_last)
	await _verdict.states(_the_navigation_page_shows_the_path_whole_and_oldest_first)
	await _verdict.states(_ctrl_tab_turns_the_page_and_turning_back_puts_the_caret_in_the_line)
	await _verdict.states(_a_click_on_a_tab_opens_its_page)
	await _verdict.states(_the_navigation_page_follows_the_path_as_it_changes)
	await _verdict.states(_a_tab_without_ctrl_does_not_turn_the_page)
	await _verdict.states(_it_comes_back_on_the_page_it_was_put_away_on)
	await _verdict.states(_a_tab_typed_into_the_line_leaves_the_caret_there)
	await _verdict.states(_its_words_stay_english_whatever_language_is_on)
	quit(_verdict.deliver(get_script()))


## A console over a log, a set of commands and a driver, as an application
## would build one where its launch switch allowed it, beside an app of four
## places on the driver. Nothing is opened. As [console, ledger, driver, log, commands,
## dev, layers, app].
func _made(folder_name: String) -> Array:
	var folder := ROOT.path_join(folder_name)
	DirAccess.make_dir_recursive_absolute(folder)
	# every file an earlier run left here
	for name: String in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(name))
	var chimes := Chimes.new(Belfry.new())
	var debug_log := DebugLog.new(chimes, folder, 100000, 2, 50)
	root.add_child(debug_log)
	var ledger := Ledger.new()
	var dev := DevCommands.new()
	dev.register(&"give", "gives an amount", ledger.give)
	var driver := Driver.new(chimes)
	var commands := Commands.new(chimes, driver)
	root.add_child(commands)
	# the dev commands answer a typed line from anywhere, as whatever composes an application registers them
	commands.register(Chimes.GLOBAL, DevCommands.RUN_LINE, dev)
	root.add_child(driver)
	# the app the console sits beside
	var app := Place.new(chimes, &"app", driver)
	driver.index.app = app
	root.add_child(app)
	# the places the paths walked here name: the list, the one with its about inside, and the detail
	for named: StringName in [&"list", &"one", &"detail"]:
		app.add_child(Place.new(chimes, named, driver))
	app.get_node("one").add_child(Place.new(chimes, &"about", driver))
	var actions := Actions.new()
	var prompts := Prompts.new(chimes, actions, [])
	root.add_child(prompts)
	var ui := Ui.new(root, chimes, commands, driver, prompts, actions)
	# the language changed through the door, as a settings screen changes it
	commands.register(Chimes.GLOBAL, Language.CHANGES_LANGUAGE, ui.language)
	var console := Console.new(ui, debug_log)
	ui.also(console)
	await _a_frame_passes()
	return [console, ledger, driver, debug_log, commands, dev, driver, app, prompts, ui.motion, ui.carried, ui.shape]


## process_frame is emitted BEFORE nodes are processed, so the effect of a
## frame is only visible once the next one has come round.
func _a_frame_passes() -> void:
	await process_frame
	await process_frame


func _key(code: Key, with_ctrl: bool = false) -> void:
	# the key going down, then up
	for down: bool in [true, false]:
		var key := InputEventKey.new()
		key.keycode = code
		key.physical_keycode = code
		key.ctrl_pressed = with_ctrl
		key.pressed = down
		root.push_input(key)
	await _a_frame_passes()


## The text typed, a character at a time, as a keyboard would send it.
func _type(text: String) -> void:
	# every character in the text
	for character: String in text:
		# its key going down, then up
		for down: bool in [true, false]:
			var key := InputEventKey.new()
			key.keycode = OS.find_keycode_from_string(character.to_upper())
			key.unicode = character.unicode_at(0)
			key.pressed = down
			root.push_input(key)
	await _a_frame_passes()


## A left click over the middle of one of the console's page buttons.
func _click_tab(console: Console, tab: int) -> void:
	var pages: Array = console.find_children("", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable)
	var middle: Vector2 = (pages[tab] as Control).get_global_rect().get_center()
	# the button going down, then up
	for down: bool in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.position = middle
		click.pressed = down
		root.push_input(click)
	await _a_frame_passes()


## The line the console types into.
func _typed_line(console: Console) -> String:
	# the parts it built, looking for the one that takes typing
	for part: Node in console.find_children("", "Control", true, false):
		if part is Field:
			return (part as Field).get_line()
	return "<no line>"


## Whether the line to type into is on screen.
func _line_showing(console: Console) -> bool:
	# the parts it built, looking for the one that takes typing
	for part: Node in console.find_children("", "Control", true, false):
		if part is Field:
			return (part as Field).is_visible_in_tree()
	return false


## Whether a label is a page button's words rather than a page's.
func _on_a_button(node: Node) -> bool:
	var above := node.get_parent()
	while above != null:
		if above is Pressable:
			return true
		above = above.get_parent()
	return false


## What the open page shows, as the reader would see it.
func _shown(console: Console) -> String:
	# the page texts it built, looking for the one on screen
	for part: Node in console.find_children("", "Label", true, false):
		if (part as Label).is_visible_in_tree() and not _on_a_button(part):
			return (part as Label).text
	return "<nothing shown>"


func _done(made: Array) -> void:
	# the places before the driver they leave, then the log and the commands, so no catcher is left in the engine
	for node: Node in [made[0], made[7], made[6], made[3], made[4], made[8], made[9], made[10], made[11]]:
		node.queue_free()
	await _a_frame_passes()


## A console nobody has opened is one node and no more: no ground, no tabs, no
## entries, no line to type into, and nothing on screen.
func _nothing_is_built_until_the_key_comes() -> void:
	var made := await _made("unopened")
	var console: Console = made[0]

	_verdict.check(console.get_child_count() == 0, "it holds no parts: %d" % console.get_child_count())
	_verdict.check(not console.visible, "and nothing of it is shown")
	await _done(made)


## Everything said and walked while it is away is kept by the log and the
## history, and none of it costs a draw here - which is what makes a console
## that ships in every build free.
func _a_console_nobody_opened_draws_nothing_however_much_happens() -> void:
	var made := await _made("quiet")
	var console: Console = made[0]
	var commands: Commands = made[4]
	var drawn := console.refresh_count

	print("something happened")
	commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": [&"app", &"list"].back()})
	commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": [&"app", &"one"].back()})
	await _a_frame_passes()

	_verdict.check(console.refresh_count == drawn, "it drew nothing: %d" % (console.refresh_count - drawn))
	await _done(made)


## The key that brings it up is the key that puts it away, and what it built
## the first time is still there the second.
func _the_key_brings_it_up_and_puts_it_away() -> void:
	var made := await _made("toggling")
	var console: Console = made[0]

	await _key(KEY_F10)
	_verdict.check(console.visible, "the key brought it up")
	_verdict.check(console.get_child_count() > 0, "and its parts were built then: %d" % console.get_child_count())
	var parts := console.find_children("", "Control", true, false).size()

	await _key(KEY_F10)
	_verdict.check(not console.visible, "the key put it away again")

	await _key(KEY_F10)
	_verdict.check(console.visible and console.find_children("", "Control", true, false).size() == parts,
		"and brought back what it already had")
	await _done(made)


## It is a surface whose whole point is typing, so opening it means the next
## letter goes into the line without anything else being pressed first.
func _opening_it_puts_the_caret_in_the_line() -> void:
	var made := await _made("caret")
	var console: Console = made[0]

	await _key(KEY_F10)
	await _type("give 5")

	_verdict.check(_typed_line(console) == "give 5", "what was typed went into the line: '%s'" % _typed_line(console))
	await _done(made)


## The conversation the console exists for: a line is typed, the command runs,
## and BOTH the line and its answer come back as log entries - so the stream
## shows what was asked next to what came of it, with nothing merged.
func _what_is_typed_runs_and_comes_back_through_the_log() -> void:
	var made := await _made("running")
	var console: Console = made[0]
	var ledger: Ledger = made[1]

	await _key(KEY_F10)
	await _type("give 5")
	await _key(KEY_ENTER)

	_verdict.check(ledger.given == 5, "the command ran: %d" % ledger.given)
	var last: Dictionary = (made[4] as Commands).get_last()
	_verdict.check(last["action"] == DevCommands.RUN_LINE and last["payload"] == {"line": "give 5"} and last["answer"] == null, "through the door, as RUN_LINE carrying the line, done: %s" % [last])
	_verdict.check(_typed_line(console) == "", "the line was cleared for the next one: '%s'" % _typed_line(console))
	var shown := _shown(console)
	_verdict.check(shown.contains("> give 5"), "what was typed is in the stream: %s" % shown)
	_verdict.check(shown.contains("5 given"), "and so is what came back")
	await _done(made)


## F10 is not a letter, so it arrives while the line holds focus - and putting
## the console away does not throw away a line half typed.
func _the_key_works_while_a_line_is_half_typed_and_keeps_it() -> void:
	var made := await _made("half_typed")
	var console: Console = made[0]

	await _key(KEY_F10)
	await _type("give")
	await _key(KEY_F10)
	_verdict.check(not console.visible, "it went away with a line half typed")

	await _key(KEY_F10)
	_verdict.check(_typed_line(console) == "give", "and the half-typed line came back: '%s'" % _typed_line(console))
	await _done(made)


## The newest line sits nearest the line being typed, and only what fits is
## shown - a console that tried to show everything would show the oldest.
func _it_shows_the_most_recent_entries_that_fit_newest_last() -> void:
	var made := await _made("recent")
	var console: Console = made[0]

	await _key(KEY_F10)
	# more entries than any window of this size can hold
	for number: int in 40:
		print("entry number %d" % number)
	await _a_frame_passes()

	var shown := _shown(console)
	_verdict.check(shown.contains("entry number 39"), "the newest is there: %s" % shown.right(60))
	_verdict.check(not shown.contains("entry number 0"), "the oldest has gone by")
	_verdict.check(shown.find("entry number 39") > shown.find("entry number 38"), "and the newest is last")
	await _done(made)


## The second page is the path the reader has walked: every view shown WHOLE,
## not just the name of its screen, and the oldest first.
func _the_navigation_page_shows_the_path_whole_and_oldest_first() -> void:
	var made := await _made("navigation")
	var console: Console = made[0]
	var commands: Commands = made[4]
	commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": [&"app", &"list"].back()})
	commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": [&"app", &"one", &"about"].back()})

	await _key(KEY_F10)
	await _key(KEY_TAB, true)

	var shown := _shown(console)
	_verdict.check(shown.contains("list") and shown.contains("one"), "both paths are listed: %s" % shown)
	_verdict.check(shown.contains("about"), "each whole, every place name on it and not just the last")
	_verdict.check(shown.find("list") < shown.find("one"), "and the older first")
	await _done(made)


## Ctrl+Tab turns the page while a command is half typed, types nothing into it,
## and turning back puts the caret in the line where it was left.
func _ctrl_tab_turns_the_page_and_turning_back_puts_the_caret_in_the_line() -> void:
	var made := await _made("turning")
	var console: Console = made[0]

	await _key(KEY_F10)
	await _type("give")
	await _key(KEY_TAB, true)
	_verdict.check(_shown(console) == "the path is empty", "the page turned to the path: %s" % _shown(console))
	_verdict.check(not _line_showing(console), "and the line to type into went with the console page")

	await _key(KEY_TAB, true)
	await _type(" 5")
	_verdict.check(_typed_line(console) == "give 5", "turning back put the caret in the half-typed line: '%s'" % _typed_line(console))
	await _done(made)


## A click on a tab opens its page as the key does, and a click back on the
## console's tab puts the caret in the line.
func _a_click_on_a_tab_opens_its_page() -> void:
	var made := await _made("clicking")
	var console: Console = made[0]

	await _key(KEY_F10)
	await _click_tab(console, 1)
	_verdict.check(_shown(console) == "the path is empty", "a click on the navigation tab turned to it: %s" % _shown(console))

	await _click_tab(console, 0)
	await _type("give")
	_verdict.check(_typed_line(console) == "give", "and a click back put the caret in the line: '%s'" % _typed_line(console))
	await _done(made)


## The console is the panel, beside the reader's layers: an arrival leaves it
## up, and the path page follows the paths as they change - arrivals appear on
## it, and forgetting the way back takes the older ones off it.
func _the_navigation_page_follows_the_path_as_it_changes() -> void:
	var made := await _made("following")
	var console: Console = made[0]
	var commands: Commands = made[4]

	await _key(KEY_F10)
	await _key(KEY_TAB, true)
	commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": [&"app", &"list"].back()})
	commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": [&"app", &"one"].back()})
	commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": [&"app", &"detail"].back()})
	await _a_frame_passes()
	_verdict.check(console.visible and _shown(console).contains("list") and _shown(console).contains("detail"), "the console stays up and the arrivals are on it: %s" % _shown(console))

	commands.dispatch(Chimes.GLOBAL, Driver.FORGETS, {})
	await _a_frame_passes()
	_verdict.check(_shown(console).contains("detail") and not _shown(console).contains("list"),
		"and forgetting took the way back off it: %s" % _shown(console))
	await _done(made)


## Ctrl is what makes Tab turn the page. A Tab on its own belongs to the engine,
## and a console that took it would turn the page under someone reaching for
## anything else. It is pressed first on the path page, where nothing holds
## focus - a line holding focus hands a Tab to the engine before this could see it.
func _a_tab_without_ctrl_does_not_turn_the_page() -> void:
	var made := await _made("plain_tab")
	var console: Console = made[0]

	await _key(KEY_F10)
	await _key(KEY_TAB, true)
	await _key(KEY_TAB)
	_verdict.check(_shown(console) == "the path is empty", "a Tab alone left the path page open: %s" % _shown(console))

	await _key(KEY_TAB, true)
	await _key(KEY_TAB)
	_verdict.check(_shown(console) != "the path is empty", "and a Tab alone left the console page open: %s" % _shown(console))
	await _done(made)


## Put away on the path page, it comes back on the path page: someone who put it
## away while reading where they had been has not asked to start again.
func _it_comes_back_on_the_page_it_was_put_away_on() -> void:
	var made := await _made("reopening")
	var console: Console = made[0]

	await _key(KEY_F10)
	await _key(KEY_TAB, true)
	await _key(KEY_F10)
	await _key(KEY_F10)

	_verdict.check(_shown(console) == "the path is empty", "it came back on the path page: %s" % _shown(console))
	await _done(made)


## A Tab typed into the line stays with the line. If the tab bar could take
## focus, the Tab would hand focus to it: typing would then go nowhere and
## Ctrl+Tab would stop reaching the console - both measured before the tab bar
## was kept from focus.
func _a_tab_typed_into_the_line_leaves_the_caret_there() -> void:
	var made := await _made("tab_in_line")
	var console: Console = made[0]

	await _key(KEY_F10)
	await _type("give")
	await _key(KEY_TAB)
	await _type(" 5")
	_verdict.check(_typed_line(console) == "give 5", "typing carried on after the Tab: '%s'" % _typed_line(console))

	await _key(KEY_TAB, true)
	_verdict.check(_shown(console) == "the path is empty", "and Ctrl+Tab still turned the page: %s" % _shown(console))
	await _done(made)


## Only a developer reads the console, so with French on
## its page buttons and its pages say what they said in English - even where
## a catalogue translates the very words.
func _its_words_stay_english_whatever_language_is_on() -> void:
	var made := await _made("french")
	var console: Console = made[0]
	var commands: Commands = made[4]
	var catalogue := Translation.new()
	catalogue.locale = "fr"
	# the console's words, as a French catalogue could hold them
	for english: String in ["console", "navigation", "the path is empty"]:
		catalogue.add_message(english, "le mot français pour " + english)
	TranslationServer.add_translation(catalogue)
	await _key(KEY_F10)
	commands.dispatch(Chimes.GLOBAL, Language.CHANGES_LANGUAGE, {"value": &"fr"})
	await _a_frame_passes()
	await _key(KEY_TAB, true)
	var buttons: Array = console.find_children("", "Label", true, false).filter(func(part: Node) -> bool: return _on_a_button(part)).map(func(part: Node) -> String: return (part as Label).text)
	_verdict.check(Language.current() == &"fr" and buttons == ["console", "navigation"], "with French on, the page buttons say the register's English: %s" % [buttons])
	_verdict.check(_shown(console) == "the path is empty", "and so does the page: %s" % _shown(console))
	commands.dispatch(Chimes.GLOBAL, Language.CHANGES_LANGUAGE, {"value": Language.SOURCE})
	TranslationServer.remove_translation(catalogue)
	await _done(made)
