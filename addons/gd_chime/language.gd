extends "controller.gd"

const Look := preload("look.gd")
const Reads := preload("reads.gd")

## The language words are said in: which one is on, the one bell a change of
## it rings, and the lookups a text makes as it draws.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A WORD'S KEY IS ITS ENGLISH. Every word the interface shows is written in
## English where it is described - ui.text("This group is empty"), the
## register's "Save" - and that English is what a catalogue translates. So a
## description reads as what it shows, English needs no catalogue - its words
## are their own keys - and a word no catalogue has yet is still shown, in
## English. What a model holds - a name, a figure - is data, and never a key.
##
## ONLY A TEXT TRANSLATES, AS IT DRAWS (text.gd). A description, a recipe, a
## model and the door all carry the English - a key, or a phrase of a pattern
## and its data (phrase.gd) - and the text says it in the language on at the
## moment it draws, and again whenever LANGUAGE_CHANGED rings. So a change of
## language reaches every word where it stands, nothing is built again, and
## nothing holds words finished in a language that is no longer on. The
## lookups below are the text's, and nothing else calls them.
##
## A CATALOGUE IS A FILE, one per language (words/fr.po), in the gettext form
## the engine reads itself: load() makes it a Translation, the plural rule
## taken from its own header, and it is registered with the engine's
## TranslationServer, so a tr() anywhere reads the same words. A file that
## cannot be read is said out loud, and nothing it held is offered.
##
## THE LANGUAGE IS THE ENGINE'S, and there is one: this sets the
## TranslationServer's locale and rings LANGUAGE_CHANGED, a global bell, and
## every lookup reads the engine's.
##
## A WORD THE CATALOGUE ON LACKS is said out loud in a developer's build,
## once, naming the word and the language, and the reader is shown the
## English: a reader part-way through French still understands English, and a
## key alone would say nothing to anyone. A shipped build shows the English
## and says nothing.
##
## A COUNT is the catalogue's plural of the English's two forms, chosen by the
## language's own rule, so French says 0 as it says 1, and English as it says
## 2 - unless none has words of its own, a key of its own the text says
## before any plural is chosen (phrase.gd). A NAME - a key's, a pad button's - is the catalogue's where the language
## names it otherwise, and else is written as it is: a letter is the same
## letter everywhere, so a name is never a missing word.
##
## HOW A LANGUAGE WRITES what is no word - the script it is written in, a
## number's marks, a date's order (formats.gd) - its catalogue says too, each
## an entry under a context, so a language is one file and nothing here knows
## one. A change into a language written in another script dresses the look
## on the window in the font the look gives that script (look.gd): fonts are
## the look's, and a language names only the script it is written in.
##
## THE PSEUDO-LOCALE is English put through the engine's pseudolocalization,
## longer and accented, so a layout is seen to survive words longer than the
## ones it was drawn with. The engine pseudolocalizes a word and not a count,
## so a count is put through it here; a way of writing never is, being
## written by rather than read.

## The bell a change of language rings, and where every reader hears it.
const LANGUAGE_CHANGED := &"language_changed"
const HEARD := [Chimes.GLOBAL, LANGUAGE_CHANGED]
## The command that changes the language, {"value": &"fr"}: the payload a
## choice carries (setting.gd), so a settings screen's choice of language presses it.
const CHANGES_LANGUAGE := &"changes_language"
## The language every word is written in, and the pseudo-locale: it, pseudolocalized.
const SOURCE := &"en"
const PSEUDO := &"pseudo"
## The folder the floor's own catalogues are in, beside this script.
const FLOOR_CATALOGUES := "words"
## What a catalogue gives its script under, by ISO 15924 code; English's is Latin.
const SCRIPT := "the script its words are written in"
## What a catalogue names a key or a pad button under, apart from its words.
const NAMES := "the name of a key or button"
## Where every word said to be missing is remembered, so each is said once:
## on the engine's TranslationServer, beside the catalogues that lack it -
## a script of static functions holding it would be kept past the end.
const MISSING := &"words_said_missing"

var _under: Node  # what this stands under, whose look is dressed for the script on


func _init(chimes: Chimes, under: Node) -> void:
	super(chimes, [], Chimes.GLOBAL)
	register_bell(LANGUAGE_CHANGED)
	_under = under
	TranslationServer.pseudolocalization_enabled = false
	TranslationServer.set_locale(SOURCE)
	TranslationServer.set_meta(MISSING, {})
	# the catalogues beside this script, wherever the addon was installed: nothing here knows where it sits
	read((get_script() as Script).resource_path.get_base_dir().path_join(FLOOR_CATALOGUES))


## Every catalogue in this folder read and registered with the engine: an
## application's own words, beside the floor's.
func read(folder: String) -> void:
	# every catalogue file in the folder
	for file: String in DirAccess.get_files_at(folder):
		if file.get_extension() != "po":
			continue
		var catalogue: Translation = load(folder.path_join(file)) if _reads_as_catalogue(folder.path_join(file)) else null
		if catalogue == null:
			push_error("the catalogue %s could not be read, and nothing in it is offered" % folder.path_join(file))
			continue
		TranslationServer.add_translation(catalogue)


## Whether a file off disk reads as a catalogue before the engine is asked:
## every line blank, a comment, or a keyword or more words, each in closed
## quotes. A file that is not one is then said here, in these words, and
## never in the engine's own complaints.
static func _reads_as_catalogue(path: String) -> bool:
	var line_of := RegEx.create_from_string("^(msgctxt|msgid|msgid_plural|msgstr(\\[\\d+\\])?)?\\s*\"([^\"\\\\]|\\\\.)*\"$")
	# every line of the file, for one that is none of those
	for line: String in FileAccess.get_file_as_string(path).split("\n"):
		var bare := line.strip_edges()
		if bare != "" and not bare.begins_with("#") and line_of.search(bare) == null:
			return false
	return true


## The language on: English, a catalogue's, or the pseudo-locale - read, so
## the change of language is noted for whoever is reading.
func get_language() -> StringName:
	return on().read()


## Every language there are words for: English, each catalogue's, and the pseudo-locale.
func get_languages() -> Array[StringName]:
	var all: Array[StringName] = [SOURCE]
	# every language the engine holds a catalogue for
	for locale: String in TranslationServer.get_loaded_locales():
		if not all.has(StringName(locale)):
			all.append(StringName(locale))
	all.append(PSEUDO)
	return all


## A language there are no words for is refused, the name it was given kept as it is.
func would(_action: StringName, payload: Dictionary) -> Phrase:
	if not get_languages().has(payload["value"]):
		return Phrase.with("There are no words in %s", [payload["value"]])
	return null


## Another language on: the engine's locale and pseudolocalization set, the
## look dressed for its script, and the bell rung - unless it was on already.
func told(_action: StringName, payload: Dictionary) -> Phrase:
	var language: StringName = payload["value"]
	if language == current():
		return null
	TranslationServer.pseudolocalization_enabled = language == PSEUDO
	TranslationServer.set_locale(SOURCE if language == PSEUDO else language)
	var look := Look.worn_by(_under)
	# nothing wearing a look of its own has no fonts to change
	if look != null:
		Look.dress(look, written_in())
	strike(region, LANGUAGE_CHANGED)
	return null


## --- the text's lookups ---

## The language on, as the engine holds it.
static func current() -> StringName:
	return PSEUDO if TranslationServer.pseudolocalization_enabled else StringName(TranslationServer.get_locale())


## The language on as a bound value, read again whenever it changes: for what
## draws its own words - a painter - to add to its sources (Bound.all).
static func on() -> Bound:
	return Bound.new(func() -> StringName:
		Reads.note(HEARD[0], HEARD[1])
		return current())


## A word by its key in the language on - the catalogue's, else the English -
## under a context where one English word says two things.
static func word(key: String, context: String = "") -> String:
	return "" if key == "" else _shown(_found(key, context))


## How many, in words: the catalogue's form of the English's two for this
## count, the count written into it.
static func counted(one: String, many: String, count: int) -> String:
	return _shown(_found(one, "", many, count)) % count


## A name in the language on - a key's, a pad button's: the catalogue's where
## it names it otherwise, else as it is written, and never said to be missing.
static func named(name: String) -> String:
	var said := _in_catalogues(name, NAMES)
	return _shown(name if said == "" else said)


## How the language on writes what is no word, by the English way and the
## context it is kept under: never pseudolocalized, since it is written by.
static func written(key: String, context: String) -> String:
	return _found(key, context)


## The script the language on is written in, by ISO 15924 code: Latin for English.
static func written_in() -> String:
	return written(Look.LATIN, SCRIPT)


## --- the catalogues ---

## The catalogues the engine holds for the language on: none for English,
## whose words are their keys, and none for the pseudo-locale, which is English.
static func _catalogues() -> Array[Translation]:
	return TranslationServer.find_translations(TranslationServer.get_locale(), true)


## A key in the catalogues of the language on - for a count, its form for
## this many - or nothing, where none of them has it.
static func _in_catalogues(key: String, context: String, many: String = "", count: int = 1) -> String:
	# every catalogue of the language on, for the first that has the key
	for catalogue: Translation in _catalogues():
		var said: StringName = catalogue.get_message(key, context) if many == "" else catalogue.get_plural_message(key, many, count, context)
		if said != &"":
			return said
	return ""


## A key in the catalogues on, or the English - the key, or a count's own
## form - with a catalogue that lacks it said out loud, once.
static func _found(key: String, context: String, many: String = "", count: int = 1) -> String:
	var said := _in_catalogues(key, context, many, count)
	if said != "":
		return said
	# a developer's build alone, where it can be mended, and only where there is a catalogue to lack it
	if OS.is_debug_build() and not _catalogues().is_empty():
		var missing: Dictionary = TranslationServer.get_meta(MISSING)
		var which := "%s | %s | %s" % [TranslationServer.get_locale(), context, key]
		if not missing.has(which):
			missing[which] = true
			push_error("the %s catalogue has no \"%s\"%s, so the English is shown" % [TranslationServer.get_language_name(TranslationServer.get_locale()), key, "" if context == "" else " under \"%s\"" % context])
	# English's rule: the first form for one, the other for any other count
	return key if many == "" or count == 1 else many


## Words as the language on shows them: pseudolocalized in the pseudo-locale.
static func _shown(said: String) -> String:
	return TranslationServer.pseudolocalize(said) if TranslationServer.pseudolocalization_enabled else said
