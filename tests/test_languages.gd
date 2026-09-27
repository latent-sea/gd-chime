extends SceneTree
const Actions := preload("res://addons/gd_chime/actions.gd")

## What must be true of the language words are said in: only a text
## translates, and only as it draws - so a button's words and a word written
## for a recipe follow every change of language, a screen built in French
## reads English when changed back, and nothing is built again; data - a
## model's, or a string written in a description - is shown as it is, even
## where it matches a catalogue word; a reason is words, its pattern
## translated and a name in it kept as it is; a refusal with a number in it
## leaves nothing behind that grows; two patterns that read the same in
## English stay apart in every language; a change moves the language on,
## a value, once, whoever made it - the locale is the game's, read and never
## set; a text follows it as it follows any value, listening to no bell; a count
## of none says its own words where it has them, and one and many are the
## catalogue's plural, in each language by its own rule; a number, money and
## a date are written as the language writes them; a word the catalogue lacks is said out loud once and
## shown in English; the pseudo-locale makes every word longer and accented;
## the look's font follows the script the language is written in; and a
## catalogue that cannot be read is said out loud.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_languages.gd
##
## The floor's French is words/fr.po. The test's own words - the register's,
## a setting's - are a catalogue of its own, made here as an application
## reads its own beside the floor's, so a word said to be missing is the
## floor's. What is said out loud is heard through a logger.

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Field := preload("res://addons/gd_chime/components/primitives/field.gd")
const Inputs := preload("res://addons/gd_chime/input_map.gd")
const Language := preload("res://addons/gd_chime/language.gd")
const Catalogues := preload("res://addons/gd_chime/catalogues.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Formats := preload("res://addons/gd_chime/formats.gd")
const Look := preload("res://addons/gd_chime/look.gd")
const Narrowing := preload("res://addons/gd_chime/narrowing.gd")
const NavControl := preload("res://addons/gd_chime/components/recipes/nav_control.gd")
const Hint := preload("res://addons/gd_chime/components/recipes/hint.gd")
const Card := preload("res://addons/gd_chime/components/recipes/card.gd")
const Sections := preload("res://addons/gd_chime/components/recipes/sections.gd")
const Setting := preload("res://addons/gd_chime/components/recipes/setting.gd")
const CellReadout := preload("res://addons/gd_chime/components/recipes/cell_readout.gd")
const TypeAhead := preload("res://addons/gd_chime/components/recipes/type_ahead.gd")
const Bracket := preload("res://addons/gd_chime/components/recipes/bracket.gd")
const Disposition := preload("res://addons/gd_chime/components/recipes/disposition.gd")
const Countdown := preload("res://addons/gd_chime/components/recipes/countdown.gd")
const LineChart := preload("res://addons/gd_chime/components/recipes/line_chart.gd")
const Table := preload("res://addons/gd_chime/components/recipes/table.gd")
const TextField := preload("res://addons/gd_chime/components/recipes/text_field.gd")
const InstructionBar := preload("res://addons/gd_chime/components/recipes/instruction_bar.gd")
const FilterSet := preload("res://addons/gd_chime/components/recipes/filter_set.gd")
const DataGrid := preload("res://addons/gd_chime/components/recipes/data_grid.gd")
const PromptBar := preload("res://addons/gd_chime/components/recipes/prompt_bar.gd")
const Attention := preload("res://addons/gd_chime/components/recipes/attention.gd")
const Verdict := preload("res://tests/verdict.gd")

## The test's own words in French, as an application's catalogue holds them.
const OWN := {"save": "enregistrer", "leave": "partir", "turn": "tourner", "lift": "lever", "go back": "revenir", "enter": "entrer", "name": "nom", "closeness": "proximité", "a crate's name": "le nom d'une caisse", "type one and press Enter": "tapez-en un et appuyez sur Entrée", "mute": "couper", "only %d left": "plus que %d", "%s left": "%s est parti", "the stall left": "l'étal restant"}
## A no-break space, which French puts between thousands and before a mark.
const GAP := "\u00a0"
## Midnight on 18 September and on 1 October 2026, in seconds since the start of 1970.
const EIGHTEENTH := 1789689600
const FIRST_OF_OCTOBER := 1790812800

var _verdict := Verdict.new()
var _hearing := Hearing.new()
var _own := Translation.new()


## Hears every sentence said out loud as an error, in order.
class Hearing extends Logger:
	var said: Array[String] = []

	func _log_error(_function: String, _file: String, _line: int, code: String, _rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_ERROR:
			said.append(code)

	## Every word said to be missing from a catalogue.
	func missing() -> Array:
		return said.filter(func(one: String) -> bool: return one.contains("catalogue has no"))


## A model with every read these properties show.
class Shown extends Fixture.Model:
	func get_sections() -> Variant: return of(&"sections").read()
	func get_takings() -> Variant: return of(&"takings").read()
	func get_when() -> Variant: return of(&"when").read()
	func get_rounds() -> Variant: return of(&"rounds").read()
	func get_reserved() -> Variant: return of(&"reserved").read()
	func get_chosen() -> Variant: return of(&"chosen").read()
	func get_satisfied() -> Variant: return of(&"satisfied").read()
	func get_remaining() -> Variant: return of(&"remaining").read()
	func get_strength() -> Variant: return of(&"strength").read()
	func get_marks() -> Variant: return of(&"marks").read()
	func get_chart() -> Variant: return of(&"chart").read()
	func get_rows() -> Variant: return of(&"rows").read()
	func get_sort() -> Variant: return of(&"sort").read()
	func get_holds() -> Variant: return of(&"holds").read()
	func get_asking() -> Variant: return of(&"asking").read()
	func get_progress() -> Variant: return of(&"progress").read()


func _init() -> void:
	OS.add_logger(_hearing)
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(1200, 900)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	_own.locale = "fr"
	# the test's own words, as an application's catalogue gives them
	for english: String in OWN:
		_own.add_message(english, OWN[english])
	TranslationServer.add_translation(_own)
	await _verdict.states(_a_button_s_words_and_a_word_written_for_a_recipe_follow_every_change_of_language_with_nothing_built_again)
	await _verdict.states(_a_change_of_language_reads_every_word_on_the_screen_again_in_place)
	await _verdict.states(_a_screen_built_in_french_reads_english_when_changed_back)
	await _verdict.states(_data_is_shown_as_it_is_even_where_it_matches_a_catalogue_word)
	await _verdict.states(_a_reason_is_words_its_pattern_translated_and_a_name_in_it_kept_as_it_is)
	await _verdict.states(_a_refusal_with_a_number_in_it_leaves_nothing_behind_that_grows)
	await _verdict.states(_two_patterns_that_read_the_same_in_english_stay_apart_in_every_language)
	await _verdict.states(_every_word_the_floor_s_recipes_show_is_in_its_french_catalogue)
	await _verdict.states(_the_grid_s_and_the_shell_s_words_are_in_the_french_catalogue_too)
	await _verdict.states(_a_change_moves_the_language_on_once_and_only_when_it_moves)
	await _verdict.states(_the_language_is_the_game_s_locale_read_never_set_and_followed_whoever_sets_it)
	await _verdict.states(_a_count_of_none_says_its_own_words_and_one_and_many_are_the_catalogue_s_plural_in_each_language)
	await _verdict.states(_numbers_money_and_dates_are_written_as_the_language_writes_them)
	await _verdict.states(_a_word_the_catalogue_lacks_is_said_out_loud_once_and_shown_in_english)
	await _verdict.states(_the_pseudo_locale_makes_every_word_longer_and_accented)
	await _verdict.states(_the_look_s_font_follows_the_script_the_language_is_written_in)
	await _verdict.states(_a_catalogue_that_cannot_be_read_is_said_out_loud_and_offers_nothing)
	TranslationServer.remove_translation(_own)
	OS.remove_logger(_hearing)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## The language changed through the door, as a settings screen changes it,
## and a frame let pass; the door's answer, a phrase or nothing.
## The data grid's and the application shell's words - every action a grid
## declares, its bars and its line of how the view stands, the palette's,
## a menu's, the documents' and the panels' refusals - said in French, and
## not one of them missing from the catalogue.
func _the_grid_s_and_the_shell_s_words_are_in_the_french_catalogue_too() -> void:
	var made := Fixture.new(root)
	var before := _hearing.missing().size()
	await _change(made, &"fr")
	var phrases: Array = DataGrid.WORDS.values().map(func(words: String) -> Phrase: return Phrase.of(words))
	# every other word of the grid and the shell, each as its file says it
	for words: String in ["No groups", "Group the rows by", "Working out the view", "Filter the rows", "The columns shown", "That is no longer there to pick", "Nothing matches", "Command", "Nothing here has a menu", "Nothing is open", "No other document is open"]:
		phrases.append(Phrase.of(words))
	phrases.append_array([Phrase.with("%s picked   %s of %s rows shown   %s", [3, 9, 12, Phrase.with("The view took %s ms", [40])]), Phrase.with("There is no %s to open", ["a.sql"]), Phrase.with("%s is not open", ["a.sql"]), Phrase.with("There is no split called %s", ["outer"])])
	var said: Array = phrases.map(func(phrase: Phrase) -> String: return Text.said(phrase))
	var expected := ["Ajouter un filtre", "Sans groupes", "3 choisies   9 lignes affichées sur 12   La vue a pris 40 ms", "Il n'y a pas de séparation appelée outer", "Aucun autre document n'est ouvert", "Rien ici n'a de menu"]
	_verdict.check(expected.all(func(one: String) -> bool: return said.has(one)), "in French, the grid's and the shell's words are French's - missing: %s" % [expected.filter(func(one: String) -> bool: return not said.has(one))])
	_verdict.check(_hearing.missing().size() == before, "and not one of them is missing from the French catalogue: %s" % [_hearing.missing().slice(before)])
	await _change(made, Language.SOURCE)
	made.done()


func _change(made: Fixture, language: StringName) -> Phrase:
	var refused := made.commands.dispatch(Chimes.GLOBAL, Language.CHANGES_LANGUAGE, {"value": language})
	await _a_frame_passes()
	return refused


## Every text under a node, in order.
func _texts_under(node: Node) -> Array:
	return node.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Text)


## What every text under a node says, in order.
func _said(node: Node) -> Array:
	return _texts_under(node).map(func(text: Text) -> String: return text.get_text())


## The first words a named piece says: its own, if it is words.
func _first_words(node: Node) -> String:
	return (node as Text).get_text() if node is Text else _said(node)[0]


## Whether words carry a letter English writes without: any beyond plain ASCII.
func _accented(words: String) -> bool:
	return Array(words.to_utf8_buffer()).any(func(byte: int) -> bool: return byte > 127)


## A screen of every kind of word: a word written in the description, the
## register's words on a button, a hint, a recipe's words and a count, a
## model's heading, money.
func _built(made: Fixture, model: Shown) -> void:
	var ui := made.ui
	made.actions.declare_all({&"leaves": ["leave", Actions.keys(KEY_ESCAPE)]})
	made.inputs.restore_defaults()
	model.set_value(&"sections", [{"id": "a", "heading": "pears", "items": []}])
	model.set_value(&"flag", false)
	model.set_value(&"takings", 18400)
	var nothing := func(_item: Bound) -> Desc: return ui.text("")
	var by_id := func(item: Variant) -> Variant: return item
	made.answer([&"saves", &"leaves", &"turns"])
	ui.start(ui.app(&"app", [ui.column([
		ui.text(Phrase.of("This group is empty")).named(&"word"),
		ui.button(&"saves").named(&"button"),
		ui.pressable(&"leaves", {}, [Hint.make(ui, &"leaves").named(&"hint")]),
		Setting.toggle(ui, &"turns", model.of(&"flag")).named(&"toggle"),
		Card.more(ui, ui.text("")).named(&"more"),
		Sections.make(ui, Bound.new(model.get_sections), nothing, {key = by_id}).named(&"sections"),
		CellReadout.quantity(ui, Bound.new(model.get_takings), "c").named(&"money"),
	])]))


func _a_button_s_words_and_a_word_written_for_a_recipe_follow_every_change_of_language_with_nothing_built_again() -> void:
	var made := Fixture.new(root, {&"saves": "save", &"names": "name"})
	var model := Shown.new(made.chimes)
	model.set_value(&"holds", "the stall")
	made.answer([&"saves", &"names"])
	made.ui.start(made.ui.app(&"app", [made.ui.column([made.ui.button(&"saves").named(&"button"), TextField.make(made.ui, &"names", Phrase.of("a crate's name"), {holds = Bound.new(model.get_holds)}).named(&"field")])]))
	await _a_frame_passes()
	var app: Node = made.driver.index.app
	var parts := app.find_children("*", "Node", true, false)
	var words: Text = _texts_under(made.ui.node_named(&"button"))[0]
	var label: Text = _texts_under(made.ui.node_named(&"field"))[0]
	var said := [words.get_text()]
	var labelled := [label.get_text()]
	# every language in turn, the two texts read after each change
	for language: StringName in [&"fr", Language.PSEUDO, Language.SOURCE]:
		await _change(made, language)
		said.append(words.get_text())
		labelled.append(label.get_text())
	_verdict.check(said[0] == "save" and said[1] == "enregistrer" and said[3] == "save", "built in English, the button's words are the register's in each language it is changed into, and English again: %s" % [said])
	_verdict.check(labelled[0] == "a crate's name" and labelled[1] == "le nom d'une caisse" and labelled[3] == "a crate's name", "and so are the words a description wrote for a recipe - a field's label: %s" % [labelled])
	_verdict.check(said[2].length() > "save".length() and _accented(said[2]) and _accented(labelled[2]), "both pseudolocalized in the pseudo-locale: %s | %s" % [said[2], labelled[2]])
	_verdict.check(app.find_children("*", "Node", true, false) == parts, "and nothing was built again: the very same %d nodes" % parts.size())
	model.free()
	made.done()


func _a_change_of_language_reads_every_word_on_the_screen_again_in_place() -> void:
	var made := Fixture.new(root, {&"saves": "save", &"turns": "turn"})
	var model := Shown.new(made.chimes)
	_built(made, model)
	await _a_frame_passes()
	var ui := made.ui
	var app: Node = made.driver.index.app
	var texts := _texts_under(app)
	var parts := app.find_children("*", "Node", true, false)
	var english := _said(app)
	_verdict.check(english == ["This group is empty", "save", "", "Escape", "Off", "More", "-", "pears", "No items", "This group is empty", "c18,400"], "in English, every word as the description writes it: %s" % [english])
	var missing_before := _hearing.missing().size()
	var refused := await _change(made, &"fr")
	var french := _said(app)
	_verdict.check(refused == null and french == ["Ce groupe est vide", "enregistrer", "", "Échap", "Désactivé", "Plus", "-", "pears", "Aucun élément", "Ce groupe est vide", "18" + GAP + "400" + GAP + "c"], "in French, every word reads again - the description's words, the register's on its button, the hint's key, the toggle's, the count by French's rule, and money as French writes it - while the mark and the model's heading are as they were: %s" % [french])
	_verdict.check(app.find_children("*", "Node", true, false) == parts and _texts_under(ui.node_named(&"button")) == texts.slice(1, 3), "and in place: the very same %d nodes, the button's own words among them, and nothing built again" % parts.size())
	_verdict.check(_hearing.missing().size() == missing_before, "every word the floor showed was in its French catalogue: %s" % [_hearing.missing().slice(missing_before)])
	await _change(made, Language.SOURCE)
	_verdict.check(_said(app) == english and _texts_under(app) == texts, "back in English, the same texts say what they said: %s" % [_said(app)])
	model.free()
	made.done()


func _a_screen_built_in_french_reads_english_when_changed_back() -> void:
	var made := Fixture.new(root, {&"saves": "save", &"turns": "turn"})
	await _change(made, &"fr")
	var model := Shown.new(made.chimes)
	_built(made, model)
	await _a_frame_passes()
	var app: Node = made.driver.index.app
	var french := _said(app)
	await _change(made, Language.SOURCE)
	var english := _said(app)
	_verdict.check(french[1] == "enregistrer" and french[4] == "Désactivé" and french[5] == "Plus", "built while French is on, the words are French's: %s" % [french])
	_verdict.check(english == ["This group is empty", "save", "", "Escape", "Off", "More", "-", "pears", "No items", "This group is empty", "c18,400"], "and changed back, every one is English: nothing was built holding French: %s" % [english])
	model.free()
	made.done()


func _data_is_shown_as_it_is_even_where_it_matches_a_catalogue_word() -> void:
	var made := Fixture.new(root)
	var model := Fixture.Model.new(made.chimes)
	model.set_value(&"words", "Won")
	made.ui.start(made.ui.app(&"app", [made.ui.column([made.ui.text(model.of(&"words")).named(&"data"), made.ui.text("Won").named(&"string"), made.ui.text(Phrase.of("Won")).named(&"word")])]))
	await _a_frame_passes()
	await _change(made, &"fr")
	var data: Text = made.ui.node_named(&"data")
	var drawn := (data.get_child(0) as Label).get_total_character_count()
	_verdict.check(data.get_text() == "Won" and drawn == 3, "in French, a model's \"Won\" is shown and drawn as the model holds it, though the catalogue translates the word: %s, %d characters drawn" % [data.get_text(), drawn])
	_verdict.check((made.ui.node_named(&"string") as Text).get_text() == "Won", "and so is a string written in a description: data too, however like a word it looks: %s" % (made.ui.node_named(&"string") as Text).get_text())
	_verdict.check((made.ui.node_named(&"word") as Text).get_text() == "Vainqueur", "while the same word written as a phrase is words, and translated: %s" % (made.ui.node_named(&"word") as Text).get_text())
	await _change(made, Language.SOURCE)
	model.free()
	made.done()


func _a_reason_is_words_its_pattern_translated_and_a_name_in_it_kept_as_it_is() -> void:
	var made := Fixture.new(root, {&"goes_back": "go back", &"lifts": "lift"})
	var model := Fixture.Model.new(made.chimes, &"app")
	made.commands.register(&"app", &"lifts", model)
	# a place named with a word the catalogue translates, so a name translated shows
	model.refuse(&"lifts", Phrase.with("%s is not on top", ["More"]))
	made.ui.start(made.ui.app(&"app", [made.ui.column([NavControl.back(made.ui, &"goes_back").named(&"back"), made.ui.button(&"lifts").named(&"lift")])]))
	await _a_frame_passes()
	var back: Text = _texts_under(made.ui.node_named(&"back"))[1]
	var lift: Text = _texts_under(made.ui.node_named(&"lift"))[1]
	var answered := made.commands.refusal(&"app", &"lifts", {})
	_verdict.check(str(answered) == "More is not on top" and back.get_text() == "There is nothing to go back to" and lift.get_text() == "More is not on top", "the door answers in English, as every caller reads it, and in English the reasons say so: %s | %s" % [back.get_text(), lift.get_text()])
	await _change(made, &"fr")
	_verdict.check(back.get_text() == "Il n'y a rien à quoi revenir", "in French, a plain refusal is a key, translated where it stands: %s" % back.get_text())
	_verdict.check(lift.get_text() == "More n'est pas au premier plan", "and a refusal with a place in it has its pattern translated and the place's name put back as it is: %s" % lift.get_text())
	await _change(made, Language.PSEUDO)
	_verdict.check(lift.get_text().contains("More") and _accented(lift.get_text()), "in the pseudo-locale, the pattern is pseudolocalized and the name is not: %s" % lift.get_text())
	await _change(made, Language.SOURCE)
	model.free()
	made.done()


func _every_word_the_floor_s_recipes_show_is_in_its_french_catalogue() -> void:
	var made := Fixture.new(root, {&"opens": "open", &"enters": "enter", &"compares": "compare", &"sorts": "sort", &"names": "name", &"binds": "bind", &"cancels": "cancel", &"saves": "save", &"mutes": "mute"})
	var ui := made.ui
	var model := Shown.new(made.chimes)
	model.set_value(&"rounds", [{"id": 1, "name": "final", "ties": [{"id": 1, "a": {"id": 1, "name": "ann"}, "b": null, "winner": 1}]}])
	model.set_value(&"reserved", "a fig")
	model.set_value(&"chosen", null)
	model.set_value(&"satisfied", false)
	model.set_value(&"remaining", 0)
	model.set_value(&"strength", 0.42)
	model.set_value(&"marks", 1234)
	model.set_value(&"chart", {"series": [{"name": "alpha", "points": [Vector2(0, 1), Vector2(1, 2)]}, {"name": "beta", "points": [Vector2(0, 2), Vector2(1, 1)]}], "x_words": "day", "y_words": "sold"})
	model.set_value(&"rows", [{"id": 1, "name": "pear"}])
	model.set_value(&"sort", {"column": "name", "ascending": true})
	model.set_value(&"holds", "the stall")
	model.set_value(&"words", "")
	model.set_value(&"asking", false)
	model.set_value(&"progress", {"count": 1, "ceiling": 3})
	var by_id := func(item: Dictionary) -> Variant: return item["id"]
	made.answer([&"enters", &"compares", &"sorts", &"names", &"binds", &"cancels", &"saves", &"mutes"])
	ui.start(ui.app(&"app", [ui.column([
		Bracket.make(ui, Bound.new(model.get_rounds), &"opens", {goes_to = &"entrant"}),
		Card.empty(ui, [ui.text("")], Bound.new(model.get_reserved)),
		Disposition.make(ui, model, {&"enters": null}),
		Countdown.make(ui, Bound.new(model.get_remaining)),
		CellReadout.relative(ui, &"compares", Bound.new(model.get_strength), Phrase.of("closeness")),
		CellReadout.mark(ui, Bound.new(model.get_marks)),
		LineChart.make(ui, Bound.new(model.get_chart)),
		Table.make(ui, Bound.new(model.get_rows), [{"name": "name", "words": Phrase.of("name"), "share": 1.0}], {key = by_id, sorts = &"sorts", sort = Bound.new(model.get_sort)}),
		TextField.make(ui, &"names", Phrase.of("a crate's name"), {"holds": Bound.new(model.get_holds), "says": Phrase.of("type one and press Enter")}),
		InstructionBar.make(ui, model, &"cancels"),
		Setting.binding(ui, &"binds", Bound.new(model.get_holds)).named(&"binding"),
		ui.pressable(&"saves").named(&"saving"),
		PromptBar.make(ui, made.prompts).named(&"prompt_bar"),
		Attention.bubble(ui, &"saving", &"saves").named(&"bubble"),
		ui.screen(&"entrant", []),
	])]))
	await _a_frame_passes()
	made.prompts.raise(&"guide", &"saves")
	var before := _hearing.missing().size()
	await _change(made, &"fr")
	var binding: Pressable = ui.node_named(&"binding")
	binding.pressed()
	await _a_frame_passes()
	var said := _said(made.driver.index.app)
	said.append(binding._words.text)
	# every comparison a filter is built with, said as a text says it
	for type: StringName in FilterSet.COMPARISON_WORDS_WITHIN:
		for comparison: String in FilterSet.COMPARISON_WORDS_WITHIN[type]:
			said.append(Text.said(Phrase.within(comparison)))
	var expected := ["Vainqueur", "À déterminer", "En attente de a fig", "Le choix n'est pas terminé", "Maintenant", "proximité 42" + GAP + "%", "1" + GAP + "234", "Cercle", "Carré", "nom ^", "le nom d'une caisse", "tapez-en un et appuyez sur Entrée", "enregistrer", "1 sur 3", "Appuyez sur une touche ou un bouton...", "est supérieur à", "ne contient pas", "est faux"]
	_verdict.check(expected.all(func(one: String) -> bool: return said.has(one)), "in French, each recipe's own words are French's: the winner's mark, an empty slot, a reservation, an unfinished choice, a countdown run out, a strength, a count, the legend's markers, a sorted heading, a field, the prompts' words, progress, a binding listening, the comparisons - missing: %s" % [expected.filter(func(one: String) -> bool: return not said.has(one))])
	_verdict.check(_said(ui.node_named(&"prompt_bar")).has("enregistrer") and _said(ui.node_named(&"bubble")).has("enregistrer"), "the prompt bar and the bubble say the prompts' words in French: %s %s" % [_said(ui.node_named(&"prompt_bar")), _said(ui.node_named(&"bubble"))])
	_verdict.check(_hearing.missing().size() == before, "and not one word the floor's recipes showed was missing from its French catalogue: %s" % [_hearing.missing().slice(before)])
	await _change(made, Language.SOURCE)
	model.free()
	made.done()


## A model refuses a lift with how many are left, a new number each time, and
## a button's reason says it in French: the first refusal and the last leave
## as many objects alive and as many words said missing - nothing is kept
## by what a refusal said.
func _a_refusal_with_a_number_in_it_leaves_nothing_behind_that_grows() -> void:
	var made := Fixture.new(root, {&"lifts": "lift"})
	var model := Fixture.Model.new(made.chimes, &"app")
	made.commands.register(&"app", &"lifts", model)
	made.ui.start(made.ui.app(&"app", [made.ui.button(&"lifts").named(&"lift")]))
	await _change(made, &"fr")
	var reason: Text = _texts_under(made.ui.node_named(&"lift"))[1]
	var counts: Array = []
	# a refusal with a new number each time, shown and then counted after the first ten and after them all
	for left: int in 200:
		model.refuse(&"lifts", Phrase.with("only %d left", [left]))
		await process_frame
		if left == 9 or left == 199:
			await _a_frame_passes()
			counts.append([Performance.get_monitor(Performance.OBJECT_COUNT), Language._said_missing.size()])
	_verdict.check(reason.get_text() == "plus que 199", "in French, the reason says the last refusal, its pattern translated and its number put in: %s" % reason.get_text())
	_verdict.check(counts[1] == counts[0], "and after 190 more refusals, each with its own number, as many objects are alive and as many words said missing as after the first ten - [objects, missing]: %s" % [counts])
	await _change(made, Language.SOURCE)
	model.free()
	made.done()


## "%s left" with "the stall" in it and "the stall left" read the same in
## English; in French one is who left and the other what is left.
func _two_patterns_that_read_the_same_in_english_stay_apart_in_every_language() -> void:
	var made := Fixture.new(root)
	var gone := Phrase.with("%s left", ["the stall"])
	var remaining := Phrase.of("the stall left")
	made.ui.start(made.ui.app(&"app", [made.ui.column([made.ui.text(gone).named(&"gone"), made.ui.text(remaining).named(&"remaining")])]))
	await _a_frame_passes()
	var english := [(made.ui.node_named(&"gone") as Text).get_text(), (made.ui.node_named(&"remaining") as Text).get_text()]
	await _change(made, &"fr")
	var french := [(made.ui.node_named(&"gone") as Text).get_text(), (made.ui.node_named(&"remaining") as Text).get_text()]
	_verdict.check(english == ["the stall left", "the stall left"] and str(gone) == str(remaining), "in English the two read the same: %s" % [english])
	_verdict.check(french == ["the stall est parti", "l'étal restant"], "in French each is its own pattern's: the name put into one, the other a key of its own: %s" % [french])
	await _change(made, Language.SOURCE)
	made.done()


func _a_change_moves_the_language_on_once_and_only_when_it_moves() -> void:
	var made := Fixture.new(root)
	var ears := Fixture.Heard.new(made.chimes, made.ui.language.get_language)
	await _change(made, &"fr")
	_verdict.check(ears.rung == 1 and Language.current() == &"fr" and made.ui.language.get_language() == &"fr", "changed into French, the language on moved once, and is French: %d" % ears.rung)
	await _change(made, &"fr")
	_verdict.check(ears.rung == 1, "changed into the language already on, nothing moved: %d" % ears.rung)
	var refused := await _change(made, &"de")
	_verdict.check(str(refused) == "There are no words in de" and ears.rung == 1 and Language.current() == &"fr", "a language there are no words for is refused, in English as the door carries it, and nothing moved: %s" % refused)
	await _change(made, Language.SOURCE)
	_verdict.check(ears.rung == 2 and Language.current() == Language.SOURCE, "changed back, it moved once more: %d" % ears.rung)
	ears.free()
	made.done()


## The locale is the game's: made and started in the game's own form of
## French, the language sets nothing and speaks French; the game setting the
## locale itself is heard as a change like any other; and a choice through
## the pseudo-locale, two settings of the engine's, is heard once.
func _the_language_is_the_game_s_locale_read_never_set_and_followed_whoever_sets_it() -> void:
	TranslationServer.set_locale("fr_FR")
	var made := Fixture.new(root)
	var ears := Fixture.Heard.new(made.chimes, made.ui.language.get_language)
	made.ui.start(made.ui.app(&"app", [made.ui.text(Phrase.of("save")).named(&"word")]))
	await _a_frame_passes()
	var word: Text = made.ui.node_named(&"word")
	_verdict.check(TranslationServer.get_locale() == "fr_FR" and made.ui.language.get_language() == &"fr" and word.get_text() == "enregistrer", "made and started under the game's fr_FR, the language set nothing, is French, and says it: %s %s %s" % [TranslationServer.get_locale(), made.ui.language.get_language(), word.get_text()])
	TranslationServer.set_locale("en_GB")
	_verdict.check(word.get_text() == "enregistrer" and word.listening_to().is_empty(), "the text listens to no bell, and has not moved the instant the locale did: the language on is a value, heard at the frame's end: %s %s" % [word.get_text(), word.listening_to()])
	await _a_frame_passes()
	_verdict.check(ears.rung == 1 and made.ui.language.get_language() == Language.SOURCE and word.get_text() == "save", "the game setting its locale itself, the language on moved once, is English, and the words followed: %d %s %s" % [ears.rung, made.ui.language.get_language(), word.get_text()])
	await _change(made, Language.PSEUDO)
	await _change(made, &"fr")
	_verdict.check(ears.rung == 3 and TranslationServer.get_locale() == "fr" and not TranslationServer.pseudolocalization_enabled, "a choice into the pseudo-locale and out of it into French - two settings of the engine's each - moved it once each: %d" % ears.rung)
	await _change(made, Language.SOURCE)
	ears.free()
	made.done()


func _a_count_of_none_says_its_own_words_and_one_and_many_are_the_catalogue_s_plural_in_each_language() -> void:
	var made := Fixture.new(root, {&"types": "type", &"picks": "pick"})
	var ui := made.ui
	var source := Fixture.Model.new(made.chimes, &"app")
	source.set_value(&"items", [])
	var narrowing := Narrowing.new(made.chimes, source.of(&"items"), 3)
	made.commands.register(&"app", &"types", narrowing)
	made.commands.register(&"app", &"picks", source)
	ui.start(ui.app(&"app", [TypeAhead.make(ui, narrowing, &"types", &"picks").named(&"picker")]))
	await _a_frame_passes()
	# the picker's first words that are not the reason standing under its line
	var count: Text = _texts_under(ui.node_named(&"picker")).filter(func(text: Text) -> bool: return not text.get_parent() is Field)[0]
	var said := {}
	# each language, and in each the count read for none, one and many, by the one text
	for language: StringName in [Language.SOURCE, &"fr"]:
		await _change(made, language)
		for many: int in [0, 1, 12]:
			var options: Array = []
			for index: int in many:
				options.append({"value": index, "words": "pear %d" % index})
			source.set_value(&"items", options)
			await _a_frame_passes()
			said["%s %d" % [language, many]] = count.get_text()
	_verdict.check([said["en 0"], said["en 1"], said["en 12"]] == ["No matches", "1 match", "12 matches"], "in English, none says its own words, and one and many are the plural's: %s" % [said])
	_verdict.check([said["fr 0"], said["fr 1"], said["fr 12"]] == ["Aucun résultat", "1 résultat", "12 résultats"], "in French, none says its own words though French's rule would count it as one, and one and many are the plural's: %s" % [said])
	var bare := [Text.said(Phrase.counted("%d crate", "%d crates", 0)), str(Phrase.counted("%d match", "%d matches", 0, "no matches"))]
	_verdict.check(bare == ["0 crates", "no matches"], "a count with no words for none counts it by the plural, and a phrase printed says none's own words as its English: %s" % [bare])
	await _change(made, Language.SOURCE)
	narrowing.free()
	source.free()
	made.done()


func _numbers_money_and_dates_are_written_as_the_language_writes_them() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var model := Shown.new(made.chimes)
	model.set_value(&"when", EIGHTEENTH)
	ui.start(ui.app(&"app", [ui.text(Formats.date(Bound.new(model.get_when))).named(&"date")]))
	await _a_frame_passes()
	var english := [Formats.written_money(1234567.5, "c", 2), Formats.written_number(-1234.0), Formats.written_number(-0.4), Formats.written_date(EIGHTEENTH), Formats.written_date(FIRST_OF_OCTOBER)]
	_verdict.check(english == ["c1,234,567.50", "-1,234", "0", "18 September 2026", "1 October 2026"], "in English: the mark before the money, commas between thousands, a point before the fraction, no minus on nothing, and the day before the month: %s" % [english])
	var date: Text = ui.node_named(&"date")
	_verdict.check(date.get_text() == "18 September 2026", "a date bound to a text reads so: %s" % date.get_text())
	var both := [Text.said(Phrase.of("Recovering")), Text.said(Phrase.within("Recovering")), Text.said(Phrase.with("Now %s", [Phrase.within("Recovering")])), str(Phrase.within("Recovering"))]
	_verdict.check(both == ["Recovering", "recovering", "Now recovering", "recovering"], "one English serves both places: said on its own it is in sentence case, and said within another phrase its first letter is lowered, in the words and in the English: %s" % [both])
	var stretches := [Formats.written_elapsed(65.0), Formats.written_elapsed(5.0), Formats.written_elapsed(3725.0, Formats.HOURS), Formats.written_elapsed(724.34, Formats.HOURS, 1), Formats.written_elapsed(59.96, Formats.MINUTES, 1)]
	_verdict.check(stretches == ["1:05", "0:05", "1:02:05", "0:12:04.3", "1:00.0"], "a stretch of time is a clock face: the first part plain, every one after it to two digits, the seconds to the places asked for, a second rounding up carrying into the minute: %s" % [stretches])
	await _change(made, &"fr")
	var french := [Formats.written_money(1234567.5, "c", 2), Formats.written_number(-1234.0), Formats.written_date(EIGHTEENTH), Formats.written_date(FIRST_OF_OCTOBER)]
	_verdict.check(french == ["1" + GAP + "234" + GAP + "567,50" + GAP + "c", "-1" + GAP + "234", "18 septembre 2026", "1er octobre 2026"], "in French: the mark after the money, a space between thousands, a comma before the fraction, the months French's and the first of one written as French writes it: %s" % [french])
	_verdict.check(ui.node_named(&"date") == date and date.get_text() == "18 septembre 2026", "and the same text writes the date again as French writes it: %s" % date.get_text())
	await _change(made, Language.SOURCE)
	model.free()
	made.done()


func _a_word_the_catalogue_lacks_is_said_out_loud_once_and_shown_in_english() -> void:
	var made := Fixture.new(root)
	made.ui.start(made.ui.app(&"app", [made.ui.column([made.ui.text(Phrase.of("a word no catalogue holds")).named(&"word"), made.ui.text(Phrase.counted("%d crate", "%d crates", 0)).named(&"count")])]))
	await _a_frame_passes()
	var before := _hearing.missing().size()
	var word: Text = made.ui.node_named(&"word")
	var count: Text = made.ui.node_named(&"count")
	_verdict.check(word.get_text() == "a word no catalogue holds" and _hearing.missing().size() == before, "in English, a word is its own key: nothing is missing")
	await _change(made, &"fr")
	await _change(made, Language.SOURCE)
	await _change(made, &"fr")
	var said: Array = _hearing.missing().slice(before)
	_verdict.check(word.get_text() == "a word no catalogue holds" and count.get_text() == "0 crates", "in French, a word the catalogue lacks is shown in English, a count by English's rule: %s, %s" % [word.get_text(), count.get_text()])
	_verdict.check(said.size() == 2 and said[0].contains("French") and said.any(func(one: String) -> bool: return one.contains("\"a word no catalogue holds\"")), "and each is said out loud once, naming the word and the language, however often it is drawn: %s" % [said])
	await _change(made, Language.SOURCE)
	made.done()


func _the_pseudo_locale_makes_every_word_longer_and_accented() -> void:
	var made := Fixture.new(root, {&"saves": "save", &"turns": "turn"})
	var model := Shown.new(made.chimes)
	_built(made, model)
	await _a_frame_passes()
	var app: Node = made.driver.index.app
	var named := [&"word", &"button", &"hint", &"toggle", &"more"]
	var english: Array = named.map(func(one: StringName) -> String: return _first_words(made.ui.node_named(one)))
	var count: Text = _texts_under(made.ui.node_named(&"sections"))[2]
	english.append(count.get_text())
	await _change(made, Language.PSEUDO)
	var pseudo: Array = named.map(func(one: StringName) -> String: return _first_words(made.ui.node_named(one)))
	pseudo.append(count.get_text())
	var wrong: Array = []
	# every word shown, against its English: longer, and carrying a letter English writes without
	for index: int in english.size():
		if pseudo[index].length() <= english[index].length() or not _accented(pseudo[index]):
			wrong.append("%s as %s" % [english[index], pseudo[index]])
	_verdict.check(wrong.is_empty() and Language.current() == Language.PSEUDO, "in the pseudo-locale every word is longer and accented - a key's name and a count as well: %s" % [pseudo if wrong.is_empty() else wrong])
	_verdict.check(_said(app).has("c18,400") and _said(app).has("pears"), "while money, written by and not read, and the model's own heading are as they were: %s" % [_said(app)])
	await _change(made, Language.SOURCE)
	model.free()
	made.done()


func _the_look_s_font_follows_the_script_the_language_is_written_in() -> void:
	var latin := SystemFont.new()
	latin.font_names = PackedStringArray(["Arial"])
	var japanese := SystemFont.new()
	japanese.font_names = PackedStringArray(["Yu Gothic"])
	var look := Themes.new(Themes.NEUTRAL)
	Look.fonts(look, {"Latn": latin, "Jpan": japanese})
	look.default_font = latin
	var worn: Theme = root.theme
	root.theme = look
	var before := _hearing.said.size()
	Look.fonts(Theme.new(), {"Jpan": japanese})
	_verdict.check(_hearing.said.size() == before + 1 and _hearing.said[before].contains("Latn"), "a look giving fonts by script but none for Latin is said out loud: %s" % [_hearing.said.slice(before)])
	var ja := Translation.new()
	ja.locale = "ja"
	ja.add_message("Latn", "Jpan", Language.SCRIPT)
	ja.add_message("this group is empty", "このグループは空です")
	TranslationServer.add_translation(ja)
	var made := Fixture.new(root)
	made.ui.start(made.ui.app(&"app", [made.ui.text(Phrase.of("this group is empty")).named(&"word")]))
	await _a_frame_passes()
	var label: Label = (made.ui.node_named(&"word") as Text).get_child(0)
	_verdict.check(label.get_theme_font(&"font") == latin, "in English, written in Latin, the words are in the look's Latin font: %s" % [label.get_theme_font(&"font")])
	await _change(made, &"ja")
	_verdict.check(label.get_theme_font(&"font") == japanese and (made.ui.node_named(&"word") as Text).get_text() == "このグループは空です", "in Japanese, the same words are in the look's font for Japanese: %s" % [label.get_theme_font(&"font").get_font_name()])
	await _change(made, &"fr")
	_verdict.check(label.get_theme_font(&"font") == latin, "in French, written in Latin again, the Latin font is back: %s" % [label.get_theme_font(&"font").get_font_name()])
	await _change(made, Language.SOURCE)
	made.done()
	TranslationServer.remove_translation(ja)
	root.theme = worn


func _a_catalogue_that_cannot_be_read_is_said_out_loud_and_offers_nothing() -> void:
	var made := Fixture.new(root)
	DirAccess.make_dir_recursive_absolute("user://unreadable")
	var file := FileAccess.open("user://unreadable/de.po", FileAccess.WRITE)
	file.store_string("msgid \"\"\nmsgstr \"\"\n\"Language: de\\n\"\n\nmsgid \"won\nmsgstr gewonnen\n")
	file.close()
	var before := _hearing.said.size()
	Catalogues.read("user://unreadable")
	var said: Array = _hearing.said.slice(before).filter(func(one: String) -> bool: return one.contains("could not be read"))
	_verdict.check(said.size() == 1 and said[0].contains("user://unreadable/de.po"), "a catalogue that cannot be read is said out loud, by its file: %s" % [said])
	_verdict.check(not made.ui.language.get_languages().has(&"de"), "and nothing in it is offered: %s" % [made.ui.language.get_languages()])
	DirAccess.remove_absolute("user://unreadable/de.po")
	DirAccess.remove_absolute("user://unreadable")
	made.done()
