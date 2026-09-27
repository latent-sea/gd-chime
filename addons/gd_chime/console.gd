extends "place.gd"

const Controller := preload("controller.gd")
const Driver := preload("driver.gd")
const DebugLog := preload("debug_log.gd")
const DevCommands := preload("dev_commands.gd")
const Bound := preload("components/primitives/bound.gd")
const Ui := preload("components/primitives/ui.gd")
const Field := preload("components/primitives/field.gd")
const Pressables := preload("theme_pressables.gd")

## The developer's console: what the app and the engine have said with a line to
## type commands into, and the path the reader has walked.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## It is a place (place.gd) named CONSOLE, built beside the app under the
## window: THE PANEL, a region of its own that blocks nothing - raised, the
## app and the pop-ups beneath stay live, the guide and the reminders read
## the same top path, and Back and an arrival leave it alone. Whoever
## composes the application makes one only where the launch switch allows
## it, and it holds nothing until F10 is pressed: F10 dispatches GO or LOWER
## for it through the command door, and the driver fills it - its content
## built on the first raising, from a description like any other - or
## empties it, which keeps its content and its half-typed line for the next
## time.
##
## Two pages, chosen by two buttons this answers as a model of its own: THE
## STREAM is what has been said, with the line to type into under it, and
## THE PATH is what the reader has walked, oldest first, each path whole, its
## place names root down. Ctrl+Tab turns the page as a press does. Both
## pages are bound values: the stream reading the log, the path the
## driver, so a page re-reads as a line lands or the reader moves.
##
## A typed line goes through the door as RUN_LINE, and whatever is
## registered for it - the dev commands - PRINTS the line and its answer as
## it runs, so the log's catcher takes both and they arrive back here as
## ordinary entries: what was typed and what came back sit next to each
## other in one stream, with nothing to merge.
##
## Only a developer reads the console; its words are data, never translated.
## Its page buttons show the register's words as the
## Strings they are, never as phrases (phrase.gd), so they stay English in
## every language, and no catalogue or template holds a word of it.
##
## It paints its own ground and ink rather than asking the look, and the
## folder's colour rule is narrowed to allow it: a developer's surface that
## borrowed the game's theme would be unreadable exactly when the theme is
## what is wrong. Its look is a Theme of its own set on itself, which the
## engine carries to its content.
##
## It reads keys, which interaction.gd otherwise claims as the only place in
## this folder that reads an event. F10 has to arrive whatever has focus and
## while nothing of this is shown - both measured, along with a text field
## holding focus taking its letters and leaving F10 alone.
##
## Deliberately absent, each a pure addition: filtering what is shown;
## scrolling back; and recalling an earlier command.

const OPENS := KEY_F10
const TURNS := KEY_TAB
const CONSOLE := &"console"
const SHOWS_STREAM := &"shows_the_stream"
const SHOWS_PATH := &"shows_the_path"
## A line of the stream, as a share of the default words' size.
const LINE := 1.5

const GROUND := Color(0.04, 0.05, 0.07, 0.94)
const INK := Color(0.86, 0.89, 0.92)

var _ui: Ui
var _debug_log: DebugLog
var _pages: Pages
var _built: bool = false


## Which page shows: a model answering the two page commands, its page a value.
class Pages extends Controller:
	var page := value(SHOWS_STREAM)

	func _init(chimes: Chimes) -> void:
		super(chimes, [], CONSOLE)

	func told(action: StringName, _payload: Dictionary) -> Phrase:
		page.set_value(action)
		return null

	## The other page, for Ctrl+Tab.
	func other() -> StringName:
		return SHOWS_PATH if page.read() == SHOWS_STREAM else SHOWS_STREAM


func _init(ui: Ui, debug_log: DebugLog) -> void:
	super(ui.chimes, CONSOLE, ui.driver)
	blocks = false
	_ui = ui
	_debug_log = debug_log
	_pages = Pages.new(ui.chimes)
	ui.actions.declare_all({SHOWS_STREAM: ["console"], SHOWS_PATH: ["navigation"]})
	# the two pages, actions of this place answered by its pages
	for action: StringName in [SHOWS_STREAM, SHOWS_PATH]:
		performs[action] = &""
		ui.commands.register(CONSOLE, action, _pages)
	theme = _look()
	set_process_unhandled_key_input(true)
	# the page turning back to the stream puts the caret in the line
	_chimes.follow(self, &"page", _page_turned)


## The keys arrive here rather than at a control with focus, so they work while a
## command is half typed, and F10 works while nothing of this is shown.
func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.is_pressed() or key.is_echo():
		return
	if key.keycode == OPENS:
		get_viewport().set_input_as_handled()
		_ui.commands.dispatch(Chimes.GLOBAL, Driver.LOWERS if _is_up() else Driver.GO, {"place": name})
	elif key.keycode == TURNS and key.ctrl_pressed and _is_up():
		get_viewport().set_input_as_handled()
		_ui.commands.dispatch(CONSOLE, _pages.other(), {})


## The page read, so it is followed: turned back to the stream, the caret
## goes in the line - once the page has been shown, at the end of the frame.
func _page_turned() -> void:
	if _pages.page.read() != SHOWS_STREAM:
		return
	# every part of the console, for its line
	for part: Node in find_children("", "Control", true, false):
		if part is Field:
			(part as Field).start_typing.call_deferred()


## Freed, its pages go with it: a model of its own, in no tree.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and is_instance_valid(_pages):
		_pages.free()


## Whether the driver has this up: the panel's path names it.
func _is_up() -> bool:
	return not driver.path_of(self).is_empty()


## Raised: its content built the first time, from its description.
func fill() -> void:
	if not _built:
		_built = true
		_ui.build(_describe(), self)


## The description: a ground, the two page buttons across the top, and the
## page chosen - the stream with the line under it, or the path.
func _describe() -> RefCounted:
	var stream := _ui.column([_ui.text(_ui.bound(_stream), &"ConsoleText").grow(), _ui.field(DevCommands.RUN_LINE).takes_focus()])
	var path := _ui.text(_ui.bound(_path), &"ConsoleText").grow()
	var showing_stream: Bound = _pages.page.map(func(page: StringName) -> bool: return page == SHOWS_STREAM)
	# each page's button, its words the register's as data: English, whatever language is on
	var buttons: Array = [SHOWS_STREAM, SHOWS_PATH].map(func(page: StringName) -> RefCounted: return _ui.pressable(page, {}, [_ui.text(_ui.actions.get_words(page), Themes.FACE)], Pressables.BUTTON).no_focus())
	var pages := _ui.column([_ui.row(buttons).basis(0.12), _ui.when(showing_stream, stream, path).keeps().grow()])
	return _ui.stack([_ui.surface(&"ConsoleGround"), pages])


## The most recent entries that fit, in the order they were said.
func _stream() -> String:
	var fitting := maxi(1, floori(size.y * 0.7 / (get_theme_default_font_size() * LINE)))
	var said := PackedStringArray()
	for index: int in range(maxi(0, _debug_log.count() - fitting), _debug_log.count()):
		var entry := _debug_log.get_entry(index)
		said.append("%s  %s" % [entry["kind"], entry["text"]])
	return "\n".join(said)


## The history, each path whole, numbered in the order walked.
func _path() -> String:
	var paths: Array = (driver as Driver).get_state()["history"]
	var walked := PackedStringArray()
	for index: int in paths.size():
		walked.append("%d  %s" % [index + 1, " / ".join(PackedStringArray(paths[index]))])
	return "\n".join(walked) if not walked.is_empty() else "the path is empty"


## The console's own look, proof against a theme that is what is wrong.
func _look() -> Theme:
	var look := Theme.new()
	look.set_type_variation(&"ConsoleText", &"Label")
	look.set_color(&"font_color", &"ConsoleText", INK)
	look.set_type_variation(&"ConsoleGround", &"Control")
	var ground := StyleBoxFlat.new()
	ground.bg_color = GROUND
	look.set_stylebox(&"panel", &"ConsoleGround", ground)
	return look
