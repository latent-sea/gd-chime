extends SceneTree

## What must be true of running words with links in them (paragraph.gd).
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_paragraph.gd
##
## A paragraph with two links in it wraps across lines, the links on lines
## of their own, each in room of exactly its size, nothing drawn over
## anything and no words cut, and as tall as its lines; each link opens its
## own entity through the door - by the mouse, the keyboard and the pad - as
## its place declares; the pad walks the links in reading order, from the end
## of one line to the start of the next, where the engine's geometry alone
## would walk out to the button beside, and back, and a walked-to link shows
## the face's focus; a language switch re-lays the paragraph in place - the
## very same nodes, the focus kept, the phrases said in French, a model's
## data as it is, and the links moved to where the French words leave room,
## and a paragraph with no link in it, which no link lays again, in French too;
## and a bound span moving is said again, with nothing built again.
##
## The paragraph stands in a row beside a button, in a window 520 wide, so
## that the first link ends the first line and the second begins the next.

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Navigation := preload("res://addons/gd_chime/theme_navigation.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Language := preload("res://addons/gd_chime/language.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Paragraph := preload("res://addons/gd_chime/components/primitives/paragraph.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const DrawnOver := preload("res://addons/gd_chime/drawn_over.gd")
const Clipped := preload("res://addons/gd_chime/clipped_text.gd")
const Verdict := preload("res://tests/verdict.gd")

const OPENS := &"opens_a_crate"
const STAYS := &"stays"
## The test's own words in French, as an application's catalogue holds them.
const OWN := {"a crate of pears was sold by ": "une caisse de poires a été vendue par ", " to ": " à ", "the plum stall": "l'étal des prunes", " this morning; it says ": " ce matin ; il dit ", "won": "vainqueur", "stay": "rester"}
const WINDOW := Vector2i(520, 400)

var _verdict := Verdict.new()
var _own := Translation.new()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = WINDOW
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	_own.locale = "fr"
	# the test's own words, as an application's catalogue gives them
	for english: String in OWN:
		_own.add_message(english, OWN[english])
	TranslationServer.add_translation(_own)
	await _verdict.states(_two_links_wrap_across_lines_each_in_room_of_its_own_nothing_drawn_over_and_no_words_cut)
	await _verdict.states(_each_link_opens_its_own_entity_by_the_mouse_the_keyboard_and_the_pad)
	await _verdict.states(_the_pad_walks_the_links_in_reading_order_and_a_walked_to_link_shows_the_focus)
	await _verdict.states(_a_language_switch_re_lays_the_paragraph_in_place)
	await _verdict.states(_a_bound_span_moving_is_said_again_with_nothing_built_again)
	TranslationServer.remove_translation(_own)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## The app: a paragraph naming two crates - ann by id, the second by a bound
## id - with a model's word in it, beside a button; and the crate's place.
func _built() -> Dictionary:
	var made := Fixture.new(root, {OPENS: "open a crate", STAYS: "stay"})
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes, &"app")
	model.set_value(&"items", 8)
	model.set_value(&"words", "won")
	made.commands.register(&"app", STAYS, model)
	var spans := [Phrase.of("a crate of pears was sold by "), ui.link(OPENS, 7, "ann").goes_to(&"crate").named(&"first"), Phrase.of(" to "), ui.link(OPENS, model.of(&"items"), Phrase.of("the plum stall")).goes_to(&"crate").named(&"second"), Phrase.of(" this morning; it says "), model.of(&"words")]
	var home := ui.row([ui.paragraph(spans).named(&"paragraph").grow(), ui.pressable(STAYS, {}, [ui.text(ui.words(STAYS))]).named(&"beside")])
	# under it, a paragraph with no link in it, whose words nothing else lays again
	var plain := ui.paragraph([Phrase.of("won")]).named(&"plain")
	ui.start(ui.app(&"app", [ui.stack([ui.screen(&"home", [ui.column([home, plain])]), ui.screen(&"crate", [])])]))
	await _a_frame_passes()
	return {"made": made, "model": model, "paragraph": ui.node_named(&"paragraph"), "plain": ui.node_named(&"plain"), "first": ui.node_named(&"first"), "second": ui.node_named(&"second"), "beside": ui.node_named(&"beside")}


func _done(built: Dictionary) -> void:
	(built["model"] as Node).free()
	(built["made"] as Fixture).done()


## Which laid line holds this link: the one its rect sits inside.
func _line_of(paragraph: Paragraph, link: Control) -> int:
	var lines := paragraph.get_lines()
	# every line, for the one that encloses the link where it was fitted
	for line: int in lines.size():
		if lines[line].grow(0.5).encloses(Rect2(link.position, link.size)):
			return line
	return -1


## What a link's own words say.
func _words(link: Control) -> String:
	return (link.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Text)[0] as Text).get_text()


func _click(at: Vector2) -> void:
	# the left button going down, then up, at this point of the window
	for down: bool in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = down
		click.position = at
		root.push_input(click)


func _pad(button: JoyButton) -> void:
	# the pad's button going down, then up
	for down: bool in [true, false]:
		var press := InputEventJoypadButton.new()
		press.button_index = button
		press.pressed = down
		root.push_input(press)


func _key(code: Key, shift: bool = false) -> void:
	# the key going down, then up
	for down: bool in [true, false]:
		var key := InputEventKey.new()
		key.keycode = code
		key.physical_keycode = code
		key.shift_pressed = shift
		key.pressed = down
		root.push_input(key)


## Where the reader is, when on the crate: which crate.
func _crate(made: Fixture) -> Variant:
	return made.driver.get_parameter(&"crate") if made.driver.get_top().has(&"crate") else null


## Back on home, with nothing focused.
func _home(made: Fixture) -> void:
	made.commands.dispatch(Chimes.GLOBAL, made.driver.GO, {"place": &"home"})
	root.gui_release_focus()
	await _a_frame_passes()


func _two_links_wrap_across_lines_each_in_room_of_its_own_nothing_drawn_over_and_no_words_cut() -> void:
	var built := await _built()
	var paragraph: Paragraph = built["paragraph"]
	var first: Pressable = built["first"]
	var second: Pressable = built["second"]
	var lines := paragraph.get_lines()
	_verdict.check(lines.size() >= 2 and _line_of(paragraph, first) == 0 and _line_of(paragraph, second) == 1, "a paragraph of two links wraps across lines, the first link on the first line and the second on the next: %d lines, the links on %d and %d" % [lines.size(), _line_of(paragraph, first), _line_of(paragraph, second)])
	_verdict.check(paragraph.get_text() == "a crate of pears was sold by  to  this morning; it says won" and _words(first) == "ann" and _words(second) == "the plum stall", "its own words are its phrases and the model's word, said in turn, and each link says its own: %s | %s | %s" % [paragraph.get_text(), _words(first), _words(second)])
	var fitted: Array = [first, second].filter(func(link: Control) -> bool: return link.size == link.get_combined_minimum_size())
	_verdict.check(fitted.size() == 2 and not Rect2(first.position, first.size).intersects(Rect2(second.position, second.size)), "each link is fitted to room of exactly the size it needs, the two apart: %s %s" % [Rect2(first.position, first.size), Rect2(second.position, second.size)])
	var needs := 0.0
	# every line's height, for the room the words need
	for line: Rect2 in lines:
		needs += line.size.y
	_verdict.check(paragraph.size.y >= needs and paragraph.get_combined_minimum_size().y == needs, "it needs the height of its lines, and has it: %s for %s" % [paragraph.size, needs])
	var box: StyleBoxFlat = first.get_drawn()[0]
	var ink: Color = (first.find_children("*", "Label", true, false)[0] as Label).get_theme_color(&"font_color")
	_verdict.check(box == root.theme.get_stylebox(&"normal", Navigation.LINK) and not box.draw_center and box.border_width_bottom == root.theme.get_constant(&"rule", Themes.DIVIDER) and ink == Themes.NEUTRAL[&"accent"], "a link is drawn as words in the look's Link: no ground, a rule under them, in the accent: %s %s" % [box.border_width_bottom, ink])
	var window := Rect2(Vector2.ZERO, Vector2(WINDOW))
	_verdict.check(DrawnOver.covered(root, window).is_empty(), "nothing is drawn over anything: %s" % [DrawnOver.covered(root, window)])
	_verdict.check(Clipped.clipped(root, window).is_empty(), "and no words are cut: %s" % [Clipped.clipped(root, window)])
	_done(built)


func _each_link_opens_its_own_entity_by_the_mouse_the_keyboard_and_the_pad() -> void:
	var built := await _built()
	var made: Fixture = built["made"]
	var first: Pressable = built["first"]
	var second: Pressable = built["second"]
	_verdict.check(first.get_goes_to() == &"crate" and second.get_goes_to() == &"crate" and first.payload() == {"parameter": 7} and second.payload() == {"parameter": 8}, "its place declares where the links go, and each carries its own entity's id - the second read through its bound value: %s %s" % [first.payload(), second.payload()])
	_click(first.get_global_rect().get_center())
	await _a_frame_passes()
	var clicked: Variant = _crate(made)
	await _home(made)
	second.grab_focus()
	_key(KEY_ENTER)
	await _a_frame_passes()
	var keyed: Variant = _crate(made)
	await _home(made)
	first.grab_focus()
	_pad(JOY_BUTTON_A)
	await _a_frame_passes()
	var padded: Variant = _crate(made)
	_verdict.check([clicked, keyed, padded] == [7, 8, 7], "each opens its own crate through the door: clicked, the first; Enter on the second, the second; the pad's A on the first, the first: %s" % [[clicked, keyed, padded]])
	_done(built)


func _the_pad_walks_the_links_in_reading_order_and_a_walked_to_link_shows_the_focus() -> void:
	var built := await _built()
	var first: Pressable = built["first"]
	var second: Pressable = built["second"]
	var beside: Control = built["beside"]
	_verdict.check(second.get_global_rect().end.x <= first.get_global_rect().end.x and beside.get_global_rect().position.x >= first.get_global_rect().end.x, "the second link starts the next line, not to the right of the first, and the button stands to the right of both - so the engine's geometry alone walks right to the button: %s %s %s" % [first.get_global_rect(), second.get_global_rect(), beside.get_global_rect()])
	first.grab_focus()
	await _a_frame_passes()
	var walked: Array = []
	# right, left, the next and the previous: the pad's d-pad and the keyboard's Tab, each read after its step
	for step: Callable in [func() -> void: _pad(JOY_BUTTON_DPAD_RIGHT), func() -> void: _pad(JOY_BUTTON_DPAD_LEFT), func() -> void: _key(KEY_TAB), func() -> void: _key(KEY_TAB, true)]:
		step.call()
		await _a_frame_passes()
		var on := root.gui_get_focus_owner()
		walked.append(&"first" if on == first else &"second" if on == second else &"beside" if on == beside else &"elsewhere")
	_verdict.check(walked == [&"second", &"first", &"second", &"first"], "the pad walks right from the end of the first line to the second link and left back to the first, and Tab and Shift-Tab do the same: %s" % [walked])
	_pad(JOY_BUTTON_DPAD_RIGHT)
	await _a_frame_passes()
	_verdict.check(second.get_drawn().size() == 2 and second.get_drawn()[1] == second.get_theme_stylebox(&"focus") and first.get_drawn().size() == 1, "walked to, a link shows the face's focus over its look, and the one left does not")
	_done(built)


func _a_language_switch_re_lays_the_paragraph_in_place() -> void:
	var built := await _built()
	var made: Fixture = built["made"]
	var paragraph: Paragraph = built["paragraph"]
	var second: Pressable = built["second"]
	second.grab_focus()
	await _a_frame_passes()
	var parts := paragraph.find_children("*", "Node", true, false)
	var before := Rect2(second.position, second.size)
	made.commands.dispatch(Chimes.GLOBAL, Language.CHANGES_LANGUAGE, {"value": &"fr"})
	await _a_frame_passes()
	var after := Rect2(second.position, second.size)
	_verdict.check(paragraph.get_text() == "une caisse de poires a été vendue par  à  ce matin ; il dit won" and _words(second) == "l'étal des prunes", "in French, the phrases and the link's words are French's, and the model's word is as the model holds it, though the catalogue translates it: %s | %s" % [paragraph.get_text(), _words(second)])
	_verdict.check((built["plain"] as Paragraph).get_text() == "vainqueur", "and a paragraph with no link in it, which no link lays again, says its phrase in French too: %s" % (built["plain"] as Paragraph).get_text())
	_verdict.check(paragraph.find_children("*", "Node", true, false) == parts and root.gui_get_focus_owner() == second, "in place: the very same nodes, and the focused link still focused")
	_verdict.check(after != before and after.size == second.get_combined_minimum_size() and _line_of(paragraph, second) >= 0, "and the link moved to where the French words left room for it, fitted to its French words: %s to %s" % [before, after])
	var window := Rect2(Vector2.ZERO, Vector2(WINDOW))
	_verdict.check(DrawnOver.covered(root, window).is_empty() and Clipped.clipped(root, window).is_empty(), "with nothing drawn over and no words cut: %s %s" % [DrawnOver.covered(root, window), Clipped.clipped(root, window)])
	made.commands.dispatch(Chimes.GLOBAL, Language.CHANGES_LANGUAGE, {"value": Language.SOURCE})
	await _a_frame_passes()
	_verdict.check(paragraph.get_text() == "a crate of pears was sold by  to  this morning; it says won" and Rect2(second.position, second.size) == before, "and back in English it reads and lies as it did: %s" % paragraph.get_text())
	_done(built)


func _a_bound_span_moving_is_said_again_with_nothing_built_again() -> void:
	var built := await _built()
	var paragraph: Paragraph = built["paragraph"]
	var model: Fixture.Model = built["model"]
	var parts := paragraph.find_children("*", "Node", true, false)
	var lines := paragraph.get_lines().size()
	model.set_value(&"words", "a great deal more than it did before, over several lines")
	await _a_frame_passes()
	_verdict.check(paragraph.get_text().ends_with("it says a great deal more than it did before, over several lines") and paragraph.get_lines().size() > lines, "the model's words moving, it says them, over more lines: %d then %d" % [lines, paragraph.get_lines().size()])
	_verdict.check(paragraph.find_children("*", "Node", true, false) == parts and Clipped.clipped(root, Rect2(Vector2.ZERO, Vector2(WINDOW))).is_empty(), "the same nodes, and its words all within its box")
	_done(built)
