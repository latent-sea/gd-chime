extends SceneTree

## What must be true of words' honest sizes: words that wrap are never
## narrower than their widest word nor in more lines than they have words,
## and built where they have no width yet need the height they take at
## that word's width, never a letter to a line; they would most like one
## line; a line starts them there and narrows them
## evenly, and places them again as they are said again; dressed in another
## look they need what its font needs; a reason is the same, and one built
## to hold its line keeps it while it is empty; and words fitted by their
## size step down to their floor kind as their room narrows, need what they
## need at the floor wherever they stand, and are never cut.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_text_least.gd
##
## Each statement is in the floor's look, whose plain words (Words) are 36
## pixels and whose reasons are 20, each piece built into a host of a width
## the statement sets. A width it expects is measured straight off the
## words' font, never by the piece that is being judged.

const Fixture := preload("res://tests/fixture.gd")
const Verdict := preload("res://tests/verdict.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const ClippedText := preload("res://addons/gd_chime/clipped_text.gd")
const OutsideSafe := preload("res://addons/gd_chime/outside_safe.gd")

## Words with one word far wider than the rest, which is the least they can be set at.
const SAID := "a few short words and one unbreakable"
const WIDEST := "unbreakable"
## The action a press here performs, refused with a reason to show.
const ADDS := &"adds_a_crate"

var _verdict := Verdict.new()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(1600, 400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_words_that_wrap_need_their_widest_word_across_and_would_take_one_line)
	await _verdict.states(_given_less_than_their_widest_word_they_stand_at_it_and_never_break_a_word)
	await _verdict.states(_built_with_no_width_yet_they_need_the_height_they_take_at_their_widest_word)
	await _verdict.states(_a_line_starts_words_that_wrap_on_one_line_and_narrows_them_evenly)
	await _verdict.states(_said_again_with_the_same_widest_word_they_are_placed_again_at_their_new_line)
	await _verdict.states(_dressed_in_another_look_they_need_what_its_font_needs)
	await _verdict.states(_a_reason_needs_its_widest_word_and_one_built_to_hold_its_line_keeps_it_while_empty)
	await _verdict.states(_fitted_words_step_down_to_their_floor_need_what_they_need_there_and_are_never_cut)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## A plain control of this size under the root, for a piece to be built into.
func _host(of: Vector2) -> Control:
	var host := Control.new()
	host.size = of
	root.add_child(host)
	return host


## How wide these words are on one line, in this label's font at this size, measured off the font.
func _wide(label: Label, words: String, size: int) -> float:
	return label.get_theme_font(&"font").get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


## Built into a host of no width, as a pop-up's words are before it is
## first laid out, then the host given exactly their least width: the
## height they need is the same before and after.
func _built_with_no_width_yet_they_need_the_height_they_take_at_their_widest_word() -> void:
	var made := Fixture.new(root)
	var host := _host(Vector2(0, 200))
	var words: Control = made.ui.build(made.ui.text(SAID, Themes.WORDS).wraps(), host)
	var unplaced := words.get_combined_minimum_size()
	host.size.x = unplaced.x
	await _a_frame_passes()
	var placed := words.get_combined_minimum_size()
	var line: float = (words.get_child(0) as Label).get_line_height()
	_verdict.check(is_equal_approx(unplaced.y, placed.y) and placed.y < 7.0 * line, "with no width yet they need %s down, what they need laid at their widest word's width, %s - a few lines of %s, not a letter to a line" % [unplaced.y, placed.y, line])
	made.done()


func _words_that_wrap_need_their_widest_word_across_and_would_take_one_line() -> void:
	var made := Fixture.new(root)
	var words: Control = made.ui.build(made.ui.text(SAID, Themes.WORDS).wraps(), _host(Vector2(800, 200)))
	await _a_frame_passes()
	var label: Label = words.get_child(0)
	var widest := _wide(label, WIDEST, 36)
	_verdict.check(is_equal_approx(words.get_combined_minimum_size().x, widest), "words that wrap need their widest word across, never a pixel: %s for '%s' at %s" % [words.get_combined_minimum_size().x, WIDEST, widest])
	_verdict.check(is_equal_approx(words.preferred_size().x, _wide(label, SAID, 36)), "and would most like all of them on one line: %s of %s" % [words.preferred_size().x, _wide(label, SAID, 36)])
	var plain: Control = made.ui.build(made.ui.text(SAID, Themes.WORDS), _host(Vector2(800, 200)))
	await _a_frame_passes()
	_verdict.check(plain.preferred_size() == plain.get_combined_minimum_size() and is_equal_approx(plain.get_combined_minimum_size().x, _wide(label, SAID, 36)), "words that do not wrap need and would take their one line: %s %s" % [plain.get_combined_minimum_size(), plain.preferred_size()])
	made.done()


func _given_less_than_their_widest_word_they_stand_at_it_and_never_break_a_word() -> void:
	var made := Fixture.new(root)
	var host := _host(Vector2(60, 300))
	made.ui.build(made.ui.row([made.ui.text(SAID, Themes.WORDS).wraps().named(&"words")]), host)
	await _a_frame_passes()
	var words: Control = made.ui.node_named(&"words")
	var label: Label = words.get_child(0)
	_verdict.check(label.size.x >= _wide(label, WIDEST, 36) - 0.5, "in a row 60 across the words stand at their widest word, the row past its room, never narrower: %s for %s" % [label.size.x, _wide(label, WIDEST, 36)])
	_verdict.check(label.get_line_count() <= SAID.split(" ").size(), "and take no more lines than they have words: %d lines for %d words" % [label.get_line_count(), SAID.split(" ").size()])
	_verdict.check(OutsideSafe.squeezed(host).is_empty(), "and nothing finds a word of them broken across lines: %s" % [OutsideSafe.squeezed(host)])
	host.free()
	made.done()


func _a_line_starts_words_that_wrap_on_one_line_and_narrows_them_evenly() -> void:
	var made := Fixture.new(root)
	var host := _host(Vector2(1500, 300))
	var first := "the first few words"
	var second := "a second and much longer run of words"
	made.ui.build(made.ui.row([made.ui.text(first, Themes.WORDS).wraps().named(&"first"), made.ui.text(second, Themes.WORDS).wraps().named(&"second")]), host)
	await _a_frame_passes()
	var one: Control = made.ui.node_named(&"first")
	var two: Control = made.ui.node_named(&"second")
	var label: Label = one.get_child(0)
	var lines := [_wide(label, first, 36), _wide(label, second, 36)]
	_verdict.check(is_equal_approx(one.size.x, lines[0]) and is_equal_approx(two.size.x, lines[1]), "with room for both on one line, each stands on its one line: %s %s of %s" % [one.size.x, two.size.x, lines])
	# room for two thirds of the two lines and the gap between them
	host.size.x = (lines[0] + lines[1]) * 2.0 / 3.0 + 12.0
	await _a_frame_passes()
	var given: float = one.size.x / lines[0]
	_verdict.check(is_equal_approx(given, two.size.x / lines[1]) and absf(given - 2.0 / 3.0) < 0.01, "with room for two thirds of them, each gives up the same share of its line: %s and %s" % [given, two.size.x / lines[1]])
	_verdict.check(one.size.x >= one.get_combined_minimum_size().x and two.size.x >= two.get_combined_minimum_size().x and (one.get_child(0) as Label).get_line_count() > 1, "and neither under its widest word, the first wrapped: %s %s" % [one.size.x, two.size.x])
	host.free()
	made.done()


func _said_again_with_the_same_widest_word_they_are_placed_again_at_their_new_line() -> void:
	var made := Fixture.new(root)
	var model := Fixture.Model.new(made.chimes)
	model.set_value(&"words", "alphabetical a b")
	var host := _host(Vector2(1500, 300))
	made.ui.build(made.ui.row([made.ui.text(model.of(&"words"), Themes.WORDS).wraps().named(&"words"), made.ui.text("beside")]), host)
	await _a_frame_passes()
	var words: Control = made.ui.node_named(&"words")
	var label: Label = words.get_child(0)
	var before := words.size.x
	model.set_value(&"words", "alphabetical a b c d e f g")
	await _a_frame_passes()
	await _a_frame_passes()
	_verdict.check(is_equal_approx(before, _wide(label, "alphabetical a b", 36)) and is_equal_approx(words.size.x, _wide(label, "alphabetical a b c d e f g", 36)), "said again at the same widest word, the row places them again on their new one line: %s then %s" % [before, words.size.x])
	host.free()
	model.free()
	made.done()


func _dressed_in_another_look_they_need_what_its_font_needs() -> void:
	var made := Fixture.new(root)
	var host := _host(Vector2(800, 300))
	var words: Control = made.ui.build(made.ui.text(SAID, Themes.WORDS).wraps(), host)
	await _a_frame_passes()
	var label: Label = words.get_child(0)
	var larger := Themes.new(Themes.NEUTRAL)
	larger.set_font_size(&"font_size", Themes.WORDS, 72)
	host.theme = larger
	await _a_frame_passes()
	_verdict.check(is_equal_approx(words.get_combined_minimum_size().x, _wide(label, WIDEST, 72)), "dressed in a look whose words are twice as large, they need the widest word at that size: %s of %s" % [words.get_combined_minimum_size().x, _wide(label, WIDEST, 72)])
	host.free()
	made.done()


func _a_reason_needs_its_widest_word_and_one_built_to_hold_its_line_keeps_it_while_empty() -> void:
	var made := Fixture.new(root, {ADDS: "Add a crate"})
	var model := made.answer([ADDS])
	model.refuse(ADDS, Phrase.of("Pick five more crates to go on"))
	var press := func(named: StringName, why: RefCounted) -> RefCounted: return made.ui.pressable(ADDS, {}, [made.ui.column([made.ui.text("ADD"), why.named(named)])])
	made.ui.start(made.ui.app(&"app", [made.ui.row([press.call(&"why", made.ui.reason(Themes.REASON)), press.call(&"held", made.ui.reason(Themes.REASON).holds_room())])]))
	await _a_frame_passes()
	var why: Control = made.ui.node_named(&"why")
	var held: Control = made.ui.node_named(&"held")
	var label: Label = why.get_child(0)
	_verdict.check(why.visible and is_equal_approx(why.get_combined_minimum_size().x, _wide(label, "crates", 20)) and label.get_line_count() <= 7, "a reason needs its widest word across, as any words that wrap: %s for 'crates' at %s, in %d lines" % [why.get_combined_minimum_size().x, _wide(label, "crates", 20), label.get_line_count()])
	var line: float = held.get_combined_minimum_size().y
	model.refuse_nothing()
	await _a_frame_passes()
	_verdict.check(not why.visible and held.visible and held.get_combined_minimum_size().y >= (held.get_child(0) as Label).get_line_height(), "with nothing to say a reason goes, and one built to hold its line keeps a line's height: %s, %s high (a line %s; refused, %s)" % [why.visible, held.get_combined_minimum_size().y, (held.get_child(0) as Label).get_line_height(), line])
	made.done()


func _fitted_words_step_down_to_their_floor_need_what_they_need_there_and_are_never_cut() -> void:
	var made := Fixture.new(root)
	var name := "a long name for a crate"
	var host := _host(Vector2(1500, 200))
	made.ui.build(made.ui.row([made.ui.text(name, Themes.WORDS).fits_by_size(Themes.REASON).named(&"fitted").grow()]), host)
	await _a_frame_passes()
	var fitted: Control = made.ui.node_named(&"fitted")
	var label: Label = fitted.get_child(0)
	var at_floor := _wide(label, name, 20)
	var leasts := [fitted.get_combined_minimum_size().x]
	_verdict.check(fitted.fitted_at == 36 and is_equal_approx(fitted.preferred_size().x, _wide(label, name, 36)), "with room for them in their own kind they are drawn at its size, and would take their one line there: %d, %s" % [fitted.fitted_at, fitted.preferred_size().x])
	# room for the words at the size halfway between their own kind's and the floor's
	host.size.x = _wide(label, name, 28)
	await _a_frame_passes()
	leasts.append(fitted.get_combined_minimum_size().x)
	var between: bool = fitted.fitted_at > 20 and fitted.fitted_at < 36 and label.get_line_count() == 1 and _wide(label, name, fitted.fitted_at) <= fitted.size.x + 0.5
	_verdict.check(between and _wide(label, name, fitted.fitted_at + 1) > fitted.size.x, "with room for less, they step down to the largest size that keeps them on one line in it: %d in %s" % [fitted.fitted_at, fitted.size.x])
	host.size.x = 10.0
	await _a_frame_passes()
	leasts.append(fitted.get_combined_minimum_size().x)
	_verdict.check(fitted.fitted_at == 20 and is_equal_approx(fitted.size.x, at_floor) and label.get_line_count() == 1, "with room for nothing they stand at the floor kind's size, as wide as they are there: %d, %s of %s" % [fitted.fitted_at, fitted.size.x, at_floor])
	_verdict.check(leasts.all(func(least: float) -> bool: return is_equal_approx(least, at_floor)), "what they need across is their one line at the floor's size, wherever they stand: %s of %s" % [leasts, at_floor])
	host.size.x = _wide(label, name, 28)
	await _a_frame_passes()
	_verdict.check(ClippedText.clipped(host, Rect2(Vector2.ZERO, Vector2(root.size))).is_empty(), "and stepped down they are never cut: %s" % [ClippedText.clipped(host, Rect2(Vector2.ZERO, Vector2(root.size)))])
	host.free()
	made.done()
